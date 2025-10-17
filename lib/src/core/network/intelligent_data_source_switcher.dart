import 'dart:async';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import 'multi_source_api_config.dart';

/// 智能数据源切换管理器
class IntelligentDataSourceSwitcher {
  static final Logger _logger = Logger();

  final List<ApiSource> _availableSources;
  final ApiSource _mockSource;
  ApiSource? _currentSource;
  Timer? _healthCheckTimer;
  final StreamController<DataSourceEvent> _eventController =
      StreamController.broadcast();
  final Map<String, DateTime> _lastSwitchTime = {};

  /// 切换冷却时间（避免频繁切换）
  static Duration switchCooldown = const Duration(minutes: 5);

  /// 健康检查间隔
  static Duration healthCheckInterval = const Duration(minutes: 2);

  IntelligentDataSourceSwitcher({
    List<ApiSource>? customSources,
  })  : _availableSources = customSources ?? MultiSourceApiConfig.backupSources,
        _mockSource = MultiSourceApiConfig.mockSource;

  /// 初始化数据源切换器
  Future<void> initialize() async {
    _logger.i('初始化智能数据源切换器');

    // 按优先级排序
    _availableSources.sort((a, b) => a.priority.compareTo(b.priority));

    // 启动健康检查
    await _performInitialHealthCheck();

    // 启动定时健康检查
    _startHealthCheckTimer();

    _logger.i('数据源切换器初始化完成，当前源: $_currentSource');
  }

  /// 执行初始健康检查
  Future<void> _performInitialHealthCheck() async {
    _logger.i('执行初始健康检查');

    for (final source in _availableSources) {
      try {
        final isHealthy = await _checkSourceHealth(source);
        source.updateHealthStatus(isHealthy);

        if (isHealthy && _currentSource == null) {
          _currentSource = source;
          _eventController.add(DataSourceSwitchedEvent(
            from: null,
            to: source,
            reason: '初始健康检查通过',
            timestamp: DateTime.now(),
          ));
        }
      } catch (e) {
        _logger.w('健康检查失败 - ${source.name}: $e');
        source.updateHealthStatus(false);
      }
    }

    // 如果所有源都不可用，使用模拟数据源
    if (_currentSource == null) {
      _currentSource = _mockSource;
      _eventController.add(DataSourceSwitchedEvent(
        from: null,
        to: _mockSource,
        reason: '所有API源不可用，启用模拟数据',
        timestamp: DateTime.now(),
        isEmergency: true,
      ));
    }
  }

  /// 启动健康检查定时器
  void _startHealthCheckTimer() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(healthCheckInterval, (_) {
      _performHealthCheck();
    });
  }

  /// 执行健康检查
  Future<void> _performHealthCheck() async {
    _logger.d('执行定时健康检查');

    final healthCheckFutures = _availableSources.map((source) async {
      try {
        final isHealthy = await _checkSourceHealth(source);
        source.updateHealthStatus(isHealthy);
        return MapEntry(source, isHealthy);
      } catch (e) {
        source.updateHealthStatus(false);
        return MapEntry(source, false);
      }
    });

    final results = await Future.wait(healthCheckFutures);

    // 检查当前源是否仍然健康
    if (_currentSource != null &&
        !results.any((r) => r.key == _currentSource && r.value)) {
      _logger.w('当前数据源 ${_currentSource!.name} 不健康，需要切换');
      await _switchToBestAvailableSource('健康检查失败');
    }
  }

  /// 检查数据源健康状态
  Future<bool> _checkSourceHealth(ApiSource source) async {
    if (source.isMock) return true;

    try {
      final dio = source.createDio();
      final stopwatch = Stopwatch()..start();

      // 使用健康检查端点进行测试
      final response = await dio.get(source.healthCheckEndpoint);
      stopwatch.stop();

      final responseTime = stopwatch.elapsedMilliseconds;
      final isHealthy = response.statusCode == 200 && responseTime < 5000;

      _logger.d('健康检查 - ${source.name}: ${isHealthy ? '健康' : '不健康'}, '
          '响应时间: ${responseTime}ms, 状态码: ${response.statusCode}');

      return isHealthy;
    } catch (e) {
      _logger.w('健康检查异常 - ${source.name}: $e');
      return false;
    }
  }

  /// 获取当前数据源
  ApiSource get currentSource => _currentSource ?? _mockSource;

  /// 执行API请求，自动处理数据源切换
  Future<T> executeRequest<T>(
    Future<T> Function(Dio dio) request, {
    String? operationName,
    Duration? timeout,
    bool forceRefresh = false,
  }) async {
    final effectiveTimeout = timeout ?? const Duration(seconds: 30);

    // 如果需要强制刷新，先尝试切换到最佳数据源
    if (forceRefresh) {
      await _switchToBestAvailableSource('强制刷新请求');
    }

    // 尝试当前数据源
    try {
      final dio = _currentSource!.createDio();
      final result = await request(dio).timeout(effectiveTimeout);

      // 重置失败计数
      _currentSource!.consecutiveFailures = 0;

      _logger.d('API请求成功 - ${operationName ?? '未知操作'} - '
          '使用数据源: ${_currentSource!.name}');

      return result;
    } catch (e) {
      _logger.w('API请求失败 - ${operationName ?? '未知操作'} - '
          '使用数据源: ${_currentSource!.name}, 错误: $e');

      // 增加失败计数
      _currentSource!.consecutiveFailures++;

      // 尝试切换到其他数据源
      await _switchToBestAvailableSource('请求失败: $e');

      // 重试请求
      try {
        final dio = _currentSource!.createDio();
        final result = await request(dio).timeout(effectiveTimeout);

        _logger.i('重试请求成功 - ${operationName ?? '未知操作'} - '
            '使用新数据源: ${_currentSource!.name}');

        return result;
      } catch (retryError) {
        _logger.e('重试请求失败 - ${operationName ?? '未知操作'} - '
            '使用数据源: ${_currentSource!.name}, 错误: $retryError');

        // 如果仍然失败，使用模拟数据
        return await _executeMockRequest(request, operationName);
      }
    }
  }

  /// 执行模拟数据请求
  Future<T> _executeMockRequest<T>(
    Future<T> Function(Dio dio) request,
    String? operationName,
  ) async {
    try {
      final mockDio = _createMockDio();
      final result = await request(mockDio);

      _logger.i('使用模拟数据成功 - ${operationName ?? '未知操作'}');

      return result;
    } catch (mockError) {
      _logger.e('模拟数据请求失败 - ${operationName ?? '未知操作'}: $mockError');
      throw DataSourceException(
        '所有数据源（包括模拟数据）都失败',
        originalError: mockError,
      );
    }
  }

  /// 创建模拟Dio实例
  Dio _createMockDio() {
    final dio = Dio(BaseOptions(
      baseUrl: 'mock://localhost/',
      connectTimeout: const Duration(seconds: 2),
      receiveTimeout: const Duration(seconds: 2),
    ));

    // 添加模拟数据拦截器
    dio.interceptors.add(MockDataInterceptor());

    return dio;
  }

  /// 切换到最佳可用数据源
  Future<void> _switchToBestAvailableSource(String reason) async {
    final now = DateTime.now();
    final lastSwitch = _lastSwitchTime[_currentSource?.name ?? ''];

    // 检查切换冷却时间
    if (lastSwitch != null && now.difference(lastSwitch) < switchCooldown) {
      _logger.i('跳过数据源切换（冷却时间）: ${now.difference(lastSwitch)}');
      return;
    }

    // 寻找最佳可用数据源
    final bestSource = await _findBestAvailableSource();

    if (bestSource != null && bestSource != _currentSource) {
      final fromSource = _currentSource;
      _currentSource = bestSource;
      _lastSwitchTime[bestSource.name] = now;

      _logger
          .i('数据源切换: ${fromSource?.name} -> ${bestSource.name}, 原因: $reason');

      _eventController.add(DataSourceSwitchedEvent(
        from: fromSource,
        to: bestSource,
        reason: reason,
        timestamp: now,
      ));
    } else if (bestSource == null) {
      // 如果没有可用数据源，使用模拟数据
      _logger.w('没有可用数据源，切换到模拟数据');

      final fromSource = _currentSource;
      _currentSource = _mockSource;
      _lastSwitchTime['mock'] = now;

      _eventController.add(DataSourceSwitchedEvent(
        from: fromSource,
        to: _mockSource,
        reason: '无可用API源，启用模拟数据',
        timestamp: now,
        isEmergency: true,
      ));
    }
  }

  /// 寻找最佳可用数据源
  Future<ApiSource?> _findBestAvailableSource() async {
    // 获取所有健康的数据源
    final healthySources = _availableSources.where((source) {
      return source.isHealthy && !source.shouldSkip();
    }).toList();

    if (healthySources.isEmpty) {
      return null;
    }

    // 按优先级排序
    healthySources.sort((a, b) => a.priority.compareTo(b.priority));

    // 返回优先级最高的健康数据源
    return healthySources.first;
  }

  /// 获取数据源状态报告
  DataSourceStatusReport getStatusReport() {
    return DataSourceStatusReport(
      currentSource: _currentSource!,
      availableSources: List.from(_availableSources),
      mockSource: _mockSource,
      lastSwitchTime: Map.from(_lastSwitchTime),
      timestamp: DateTime.now(),
    );
  }

  /// 监听数据源切换事件
  Stream<DataSourceEvent> get events => _eventController.stream;

  /// 销毁资源
  void dispose() {
    _healthCheckTimer?.cancel();
    _eventController.close();
  }
}

/// 数据源事件基类
abstract class DataSourceEvent {
  final DateTime timestamp;

  DataSourceEvent({required this.timestamp});
}

/// 数据源切换事件
class DataSourceSwitchedEvent extends DataSourceEvent {
  final ApiSource? from;
  final ApiSource to;
  final String reason;
  final bool isEmergency;

  DataSourceSwitchedEvent({
    required this.from,
    required this.to,
    required this.reason,
    required super.timestamp,
    this.isEmergency = false,
  });

  @override
  String toString() =>
      'DataSourceSwitchedEvent: ${from?.name} -> ${to.name}, reason: $reason, emergency: $isEmergency';
}

/// 数据源状态报告
class DataSourceStatusReport {
  final ApiSource currentSource;
  final List<ApiSource> availableSources;
  final ApiSource mockSource;
  final Map<String, DateTime> lastSwitchTime;
  final DateTime timestamp;

  DataSourceStatusReport({
    required this.currentSource,
    required this.availableSources,
    required this.mockSource,
    required this.lastSwitchTime,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'currentSource': {
        'name': currentSource.name,
        'priority': currentSource.priority,
        'isHealthy': currentSource.isHealthy,
        'consecutiveFailures': currentSource.consecutiveFailures,
      },
      'availableSources': availableSources
          .map((s) => {
                'name': s.name,
                'priority': s.priority,
                'isHealthy': s.isHealthy,
                'consecutiveFailures': s.consecutiveFailures,
              })
          .toList(),
      'lastSwitchTime':
          lastSwitchTime.map((k, v) => MapEntry(k, v.toIso8601String())),
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// 数据源异常
class DataSourceException implements Exception {
  final String message;
  final dynamic originalError;

  DataSourceException(this.message, {this.originalError});

  @override
  String toString() =>
      'DataSourceException: $message${originalError != null ? ', Original error: $originalError' : ''}';
}

/// 模拟数据拦截器
class MockDataInterceptor extends Interceptor {
  final _logger = Logger();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.i('使用模拟数据: ${options.path}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // 为响应添加模拟数据标识
    response.data = _wrapWithMockMetadata(response.data);
    handler.next(response);
  }

  dynamic _wrapWithMockMetadata(dynamic data) {
    if (data is Map) {
      return {
        ...data,
        '_mock': true,
        '_mock_timestamp': DateTime.now().toIso8601String(),
        '_mock_warning': '当前使用模拟数据，数据仅供演示使用',
      };
    }
    return data;
  }
}
