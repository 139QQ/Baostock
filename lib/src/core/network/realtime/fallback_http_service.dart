import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../fund_api_client.dart';
import '../utils/logger.dart';

// ignore_for_file: sort_constructors_first, public_member_api_docs
/// HTTP轮询降级服务
///
/// 当WebSocket连接不可用时，提供HTTP轮询机制作为降级方案
/// 支持智能轮询频率调整和断线期间数据缓存
class FallbackHttpService {
  /// 轮询配置
  final FallbackHttpConfig config;

  /// Dio客户端
  late final Dio _dio;

  /// 轮询定时器
  Timer? _pollingTimer;

  /// 当前轮询状态
  bool _isPolling = false;

  /// 数据缓存（用于断线期间的数据暂存）
  final List<CachedDataItem> _dataCache = [];

  /// 最后一次轮询时间
  DateTime? _lastPollTime;

  /// 轮询次数计数器
  int _pollCount = 0;

  /// 连续失败次数
  int _consecutiveFailures = 0;

  /// 数据流控制器
  final StreamController<FallbackDataMessage> _dataController =
      StreamController<FallbackDataMessage>.broadcast();

  /// 状态流控制器
  final StreamController<FallbackServiceState> _stateController =
      StreamController<FallbackServiceState>.broadcast();

  /// 构造函数
  FallbackHttpService({
    required this.config,
  }) {
    _initializeDio();
  }

  /// 初始化Dio客户端
  void _initializeDio() {
    _dio = Dio(BaseOptions(
      baseUrl: FundApiClient.baseUrl,
      connectTimeout: config.connectTimeout,
      receiveTimeout: config.receiveTimeout,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        ...?config.headers,
      },
    ));

    // 添加拦截器
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          AppLogger.debug('HTTP轮询请求', '${options.method} ${options.uri}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          AppLogger.debug('HTTP轮询响应', '状态码: ${response.statusCode}');
          handler.next(response);
        },
        onError: (error, handler) {
          AppLogger.error('HTTP轮询错误', error);
          handler.next(error);
        },
      ),
    );
  }

  /// 获取数据流
  Stream<FallbackDataMessage> get dataStream => _dataController.stream;

  /// 获取状态流
  Stream<FallbackServiceState> get stateStream => _stateController.stream;

  /// 获取当前状态
  bool get isPolling => _isPolling;

  /// 获取轮询统计信息
  Map<String, dynamic> get pollingStats => {
        'isPolling': _isPolling,
        'lastPollTime': _lastPollTime?.toIso8601String(),
        'pollCount': _pollCount,
        'consecutiveFailures': _consecutiveFailures,
        'cacheSize': _dataCache.length,
        'currentInterval': _currentPollInterval.inMilliseconds,
      };

  /// 获取当前轮询间隔
  Duration get _currentPollInterval {
    // 根据连续失败次数调整轮询间隔
    if (_consecutiveFailures >= config.maxFailureCount) {
      return config.maxPollInterval;
    } else if (_consecutiveFailures > 0) {
      // 指数退避
      final multiplier = (1 << _consecutiveFailures).clamp(1, 16);
      final interval = config.basePollInterval * multiplier;
      final minMs = config.basePollInterval.inMilliseconds;
      final maxMs = config.maxPollInterval.inMilliseconds;
      final resultMs = interval.inMilliseconds.clamp(minMs, maxMs);
      return Duration(milliseconds: resultMs);
    }
    return config.basePollInterval;
  }

  /// 开始轮询
  Future<void> startPolling() async {
    if (_isPolling) {
      AppLogger.warn('HTTP轮询已在运行中');
      return;
    }

    _isPolling = true;
    _consecutiveFailures = 0;
    _updateState(FallbackServiceState.polling);

    AppLogger.info('HTTP轮询服务已启动', '间隔: ${config.basePollInterval}');

    // 立即执行一次轮询
    await _performPoll();

    // 启动定时轮询
    _scheduleNextPoll();
  }

  /// 停止轮询
  Future<void> stopPolling() async {
    if (!_isPolling) {
      return;
    }

    _isPolling = false;
    _pollingTimer?.cancel();
    _updateState(FallbackServiceState.stopped);

    AppLogger.info('HTTP轮询服务已停止');
  }

  /// 安排下一次轮询
  void _scheduleNextPoll() {
    if (!_isPolling) return;

    _pollingTimer?.cancel();
    final interval = _currentPollInterval;

    _pollingTimer = Timer(interval, () async {
      await _performPoll();
      _scheduleNextPoll();
    });

    AppLogger.debug('安排下一次轮询', '间隔: ${interval.inSeconds}秒');
  }

  /// 执行单次轮询
  Future<void> _performPoll() async {
    if (!_isPolling) return;

    try {
      _lastPollTime = DateTime.now();
      _pollCount++;

      AppLogger.debug('执行HTTP轮询', '第$_pollCount次');

      // 并行请求所有配置的端点
      final results = await Future.wait(
        config.endpoints.map((endpoint) => _fetchEndpoint(endpoint)),
      );

      // 处理响应数据
      final combinedData = _combineResults(results);

      // 缓存数据
      _cacheData(combinedData);

      // 发送数据到流
      if (!_dataController.isClosed) {
        final message = FallbackDataMessage(
          data: combinedData,
          timestamp: DateTime.now(),
          source: 'http_polling',
          pollCount: _pollCount,
          interval: _currentPollInterval,
        );

        _dataController.add(message);
      }

      // 重置失败计数
      _consecutiveFailures = 0;
      _updateState(FallbackServiceState.polling);

      AppLogger.debug('HTTP轮询完成',
          '端点数: ${results.length}, 数据键: ${combinedData.keys.length}');
    } catch (e) {
      _consecutiveFailures++;
      AppLogger.error('HTTP轮询失败', '第$_consecutiveFailures次连续失败: $e');

      // 发送错误消息
      if (!_dataController.isClosed) {
        final errorMessage = FallbackDataMessage.error(
          e.toString(),
          timestamp: DateTime.now(),
          source: 'http_polling',
          pollCount: _pollCount,
          consecutiveFailures: _consecutiveFailures,
        );

        _dataController.add(errorMessage);
      }

      // 检查是否达到最大失败次数
      if (_consecutiveFailures >= config.maxFailureCount) {
        _updateState(FallbackServiceState.error);
        AppLogger.error('HTTP轮询连续失败次数过多', '暂停轮询: ${config.maxPollInterval}');

        // 等待较长时间后重试
        Future.delayed(config.maxPollInterval, () {
          if (_isPolling) {
            _consecutiveFailures = 0;
            _scheduleNextPoll();
          }
        });
      } else {
        _updateState(FallbackServiceState.polling);
      }
    }
  }

  /// 获取单个端点数据
  Future<Map<String, dynamic>> _fetchEndpoint(FallbackEndpoint endpoint) async {
    try {
      Response response;

      switch (endpoint.method.toUpperCase()) {
        case 'GET':
          response = await _dio.get(endpoint.path);
          break;
        case 'POST':
          response = await _dio.post(endpoint.path, data: endpoint.data);
          break;
        default:
          throw UnsupportedError('不支持的HTTP方法: ${endpoint.method}');
      }

      if (response.statusCode == 200) {
        final data =
            response.data is String ? jsonDecode(response.data) : response.data;
        return {
          'endpoint': endpoint.path,
          'data': data,
          'timestamp': DateTime.now().toIso8601String(),
          'success': true,
        };
      } else {
        throw Exception('HTTP错误: ${response.statusCode}');
      }
    } catch (e) {
      return {
        'endpoint': endpoint.path,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
        'success': false,
      };
    }
  }

  /// 合并多个端点的结果
  Map<String, dynamic> _combineResults(List<Map<String, dynamic>> results) {
    final combined = <String, dynamic>{};

    for (final result in results) {
      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>;
        combined.addAll(data);
      }
    }

    // 添加元数据
    combined['_pollingMetadata'] = {
      'timestamp': DateTime.now().toIso8601String(),
      'pollCount': _pollCount,
      'successfulEndpoints': results.where((r) => r['success'] == true).length,
      'totalEndpoints': results.length,
      'interval': _currentPollInterval.inMilliseconds,
    };

    return combined;
  }

  /// 缓存数据
  void _cacheData(Map<String, dynamic> data) {
    final cacheItem = CachedDataItem(
      data: data,
      timestamp: DateTime.now(),
      pollCount: _pollCount,
    );

    _dataCache.add(cacheItem);

    // 保持缓存大小在限制范围内
    if (_dataCache.length > config.maxCacheSize) {
      _dataCache.removeRange(0, _dataCache.length - config.maxCacheSize);
    }

    AppLogger.debug('数据已缓存', '缓存大小: ${_dataCache.length}');
  }

  /// 获取缓存数据
  List<CachedDataItem> getCachedData({DateTime? since}) {
    if (since == null) {
      return List.unmodifiable(_dataCache);
    }

    return _dataCache.where((item) => item.timestamp.isAfter(since)).toList();
  }

  /// 清理过期的缓存数据
  void cleanupCache() {
    final cutoff = DateTime.now().subtract(config.cacheRetentionPeriod);
    final originalSize = _dataCache.length;

    _dataCache.removeWhere((item) => item.timestamp.isBefore(cutoff));

    final removedCount = originalSize - _dataCache.length;
    if (removedCount > 0) {
      AppLogger.info('清理过期缓存数据', '移除 $removedCount 项');
    }
  }

  /// 更新服务状态
  void _updateState(FallbackServiceState newState) {
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }

  /// 手动触发轮询
  Future<void> pollNow() async {
    if (!_isPolling) {
      AppLogger.warn('HTTP轮询服务未启动');
      return;
    }

    // 取消当前定时器
    _pollingTimer?.cancel();

    // 立即执行轮询
    await _performPoll();

    // 重新安排下一次轮询
    _scheduleNextPoll();
  }

  /// 更新配置
  void updateConfig(FallbackHttpConfig newConfig) {
    // TODO: 实现配置更新逻辑
    AppLogger.info('HTTP轮询配置已更新');
  }

  /// 获取服务统计信息
  Map<String, dynamic> getServiceStats() {
    return {
      'config': config.toJson(),
      'isPolling': _isPolling,
      'lastPollTime': _lastPollTime?.toIso8601String(),
      'pollCount': _pollCount,
      'consecutiveFailures': _consecutiveFailures,
      'cacheSize': _dataCache.length,
      'currentInterval': _currentPollInterval.inMilliseconds,
      'cache': _dataCache.map((item) => item.toJson()).toList(),
    };
  }

  /// 销毁服务
  Future<void> dispose() async {
    await stopPolling();

    await _dataController.close();
    await _stateController.close();

    _dataCache.clear();

    AppLogger.info('HTTP轮询服务已销毁');
  }
}

/// HTTP轮询配置
class FallbackHttpConfig {
  /// 基础轮询间隔
  final Duration basePollInterval;

  /// 最大轮询间隔
  final Duration maxPollInterval;

  /// 最大连续失败次数
  final int maxFailureCount;

  /// 连接超时时间
  final Duration connectTimeout;

  /// 接收超时时间
  final Duration receiveTimeout;

  /// 最大缓存大小
  final int maxCacheSize;

  /// 缓存保留时间
  final Duration cacheRetentionPeriod;

  /// 轮询端点配置
  final List<FallbackEndpoint> endpoints;

  /// 请求头
  final Map<String, String>? headers;

  const FallbackHttpConfig({
    this.basePollInterval = const Duration(seconds: 5),
    this.maxPollInterval = const Duration(minutes: 2),
    this.maxFailureCount = 5,
    this.connectTimeout = const Duration(seconds: 10),
    this.receiveTimeout = const Duration(seconds: 30),
    this.maxCacheSize = 100,
    this.cacheRetentionPeriod = const Duration(hours: 1),
    this.endpoints = const [],
    this.headers,
  });

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'basePollInterval': basePollInterval.inMilliseconds,
      'maxPollInterval': maxPollInterval.inMilliseconds,
      'maxFailureCount': maxFailureCount,
      'connectTimeout': connectTimeout.inMilliseconds,
      'receiveTimeout': receiveTimeout.inMilliseconds,
      'maxCacheSize': maxCacheSize,
      'cacheRetentionPeriod': cacheRetentionPeriod.inMilliseconds,
      'endpoints': endpoints.map((e) => e.toJson()).toList(),
      'headers': headers,
    };
  }
}

/// 轮询端点配置
class FallbackEndpoint {
  /// 端点路径
  final String path;

  /// HTTP方法
  final String method;

  /// 请求数据（POST请求使用）
  final Map<String, dynamic>? data;

  const FallbackEndpoint({
    required this.path,
    this.method = 'GET',
    this.data,
  });

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'method': method,
      'data': data,
    };
  }
}

/// 缓存数据项
class CachedDataItem {
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int pollCount;

  const CachedDataItem({
    required this.data,
    required this.timestamp,
    required this.pollCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'pollCount': pollCount,
    };
  }
}

/// HTTP轮询降级服务状态
enum FallbackServiceState {
  /// 未启动
  idle,

  /// 轮询中
  polling,

  /// 已停止
  stopped,

  /// 错误状态
  error,
}

/// HTTP轮询数据消息
class FallbackDataMessage {
  /// 消息数据
  final Map<String, dynamic>? data;

  /// 错误信息
  final String? error;

  /// 时间戳
  final DateTime timestamp;

  /// 数据来源
  final String source;

  /// 轮询次数
  final int pollCount;

  /// 轮询间隔
  final Duration interval;

  /// 连续失败次数
  final int consecutiveFailures;

  const FallbackDataMessage({
    this.data,
    this.error,
    required this.timestamp,
    required this.source,
    required this.pollCount,
    required this.interval,
    this.consecutiveFailures = 0,
  });

  /// 创建错误消息
  factory FallbackDataMessage.error(
    String error, {
    required DateTime timestamp,
    required String source,
    required int pollCount,
    int consecutiveFailures = 0,
  }) {
    return FallbackDataMessage(
      error: error,
      timestamp: timestamp,
      source: source,
      pollCount: pollCount,
      interval: Duration.zero,
      consecutiveFailures: consecutiveFailures,
    );
  }

  /// 是否为错误消息
  bool get isError => error != null;

  /// 是否为成功消息
  bool get isSuccess => error == null && data != null;

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'error': error,
      'timestamp': timestamp.toIso8601String(),
      'source': source,
      'pollCount': pollCount,
      'interval': interval.inMilliseconds,
      'consecutiveFailures': consecutiveFailures,
    };
  }

  @override
  String toString() {
    return 'FallbackDataMessage('
        'source: $source, '
        'pollCount: $pollCount, '
        'timestamp: $timestamp, '
        'isError: $isError, '
        'error: $error'
        ')';
  }
}
