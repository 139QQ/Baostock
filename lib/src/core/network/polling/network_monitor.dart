import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

import '../utils/logger.dart';

/// 网络状态检测结果
class NetworkStatusResult {
  /// 网络连接类型
  final List<ConnectivityResult> connectivityResults;

  /// 是否有网络连接
  final bool isConnected;

  /// 连接质量评估 (0.0-1.0)
  final double quality;

  /// 网络延迟（毫秒）
  final int? latency;

  /// 是否可以访问互联网
  final bool hasInternetAccess;

  /// 检测时间戳
  final DateTime timestamp;

  /// 额外的网络信息
  final Map<String, dynamic> metadata;

  const NetworkStatusResult({
    required this.connectivityResults,
    required this.isConnected,
    required this.quality,
    this.latency,
    required this.hasInternetAccess,
    required this.timestamp,
    this.metadata = const {},
  });

  /// 创建离线状态结果
  factory NetworkStatusResult.offline() {
    return NetworkStatusResult(
      connectivityResults: [ConnectivityResult.none],
      isConnected: false,
      quality: 0.0,
      hasInternetAccess: false,
      timestamp: DateTime.now(),
    );
  }

  /// 创建在线状态结果
  factory NetworkStatusResult.online({
    required List<ConnectivityResult> connectivityResults,
    required double quality,
    int? latency,
    required bool hasInternetAccess,
    Map<String, dynamic>? metadata,
  }) {
    return NetworkStatusResult(
      connectivityResults: connectivityResults,
      isConnected: true,
      quality: quality,
      latency: latency,
      hasInternetAccess: hasInternetAccess,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    );
  }

  /// 获取主要连接类型
  ConnectivityResult get primaryConnection {
    if (connectivityResults.isEmpty) return ConnectivityResult.none;

    // 优先级：以太网 > WiFi > 移动网络 > 其他
    for (final result in [
      ConnectivityResult.ethernet,
      ConnectivityResult.wifi,
      ConnectivityResult.mobile,
      ConnectivityResult.other
    ]) {
      if (connectivityResults.contains(result)) {
        return result;
      }
    }
    return ConnectivityResult.none;
  }

  /// 是否为高质量连接
  bool get isHighQuality => quality >= 0.7;

  /// 是否为稳定连接（适合实时数据）
  bool get isStable =>
      isConnected && isHighQuality && (latency != null && latency! < 1000);

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'connectivityResults': connectivityResults.map((e) => e.name).toList(),
      'isConnected': isConnected,
      'quality': quality,
      'latency': latency,
      'hasInternetAccess': hasInternetAccess,
      'timestamp': timestamp.toIso8601String(),
      'primaryConnection': primaryConnection.name,
      'isHighQuality': isHighQuality,
      'isStable': isStable,
      'metadata': metadata,
    };
  }

  @override
  String toString() {
    return 'NetworkStatusResult('
        'connected: $isConnected, '
        'quality: ${(quality * 100).toStringAsFixed(1)}%, '
        'latency: ${latency ?? 'N/A'}ms, '
        'type: ${primaryConnection.name}'
        ')';
  }
}

/// 数据源可用性评估结果
class DataSourceAvailability {
  /// 数据源标识符
  final String sourceId;

  /// 数据源名称
  final String sourceName;

  /// 是否可用
  final bool isAvailable;

  /// 响应时间（毫秒）
  final int? responseTime;

  /// 可靠性评分 (0.0-1.0)
  final double reliability;

  /// 最后成功时间
  final DateTime? lastSuccessTime;

  /// 连续失败次数
  final int consecutiveFailures;

  /// 总体健康状态
  final DataSourceHealth health;

  /// 额外的源信息
  final Map<String, dynamic> metadata;

  const DataSourceAvailability({
    required this.sourceId,
    required this.sourceName,
    required this.isAvailable,
    this.responseTime,
    required this.reliability,
    this.lastSuccessTime,
    this.consecutiveFailures = 0,
    this.health = DataSourceHealth.unknown,
    this.metadata = const {},
  });

  /// 创建不可用状态
  factory DataSourceAvailability.unavailable(
    String sourceId,
    String sourceName, {
    int consecutiveFailures = 0,
    Map<String, dynamic>? metadata,
  }) {
    return DataSourceAvailability(
      sourceId: sourceId,
      sourceName: sourceName,
      isAvailable: false,
      reliability: 0.0,
      consecutiveFailures: consecutiveFailures,
      health: DataSourceHealth.down,
      metadata: metadata ?? {},
    );
  }

  /// 创建可用状态
  factory DataSourceAvailability.available(
    String sourceId,
    String sourceName, {
    required int responseTime,
    required double reliability,
    DateTime? lastSuccessTime,
    Map<String, dynamic>? metadata,
  }) {
    // 根据响应时间和可靠性确定健康状态
    DataSourceHealth health;
    if (responseTime < 500 && reliability > 0.9) {
      health = DataSourceHealth.excellent;
    } else if (responseTime < 1000 && reliability > 0.8) {
      health = DataSourceHealth.good;
    } else if (responseTime < 2000 && reliability > 0.6) {
      health = DataSourceHealth.fair;
    } else {
      health = DataSourceHealth.poor;
    }

    return DataSourceAvailability(
      sourceId: sourceId,
      sourceName: sourceName,
      isAvailable: true,
      responseTime: responseTime,
      reliability: reliability,
      lastSuccessTime: lastSuccessTime ?? DateTime.now(),
      health: health,
      metadata: metadata ?? {},
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'sourceId': sourceId,
      'sourceName': sourceName,
      'isAvailable': isAvailable,
      'responseTime': responseTime,
      'reliability': reliability,
      'lastSuccessTime': lastSuccessTime?.toIso8601String(),
      'consecutiveFailures': consecutiveFailures,
      'health': health.name,
      'metadata': metadata,
    };
  }

  @override
  String toString() {
    return 'DataSourceAvailability('
        'id: $sourceId, '
        'available: $isAvailable, '
        'health: ${health.name}, '
        'responseTime: ${responseTime ?? 'N/A'}ms, '
        'reliability: ${(reliability * 100).toStringAsFixed(1)}%'
        ')';
  }
}

/// 数据源健康状态
enum DataSourceHealth {
  /// 优秀 - 响应快，可靠性高
  excellent,

  /// 良好 - 响应和可靠性都较好
  good,

  /// 一般 - 可用但性能一般
  fair,

  /// 较差 - 可用但性能差
  poor,

  /// 不可用 - 无法访问
  down,

  /// 未知 - 未检测
  unknown,
}

/// 网络监控器配置
class NetworkMonitorConfig {
  /// 连接检测间隔
  final Duration checkInterval;

  /// 网络延迟测试URL列表
  final List<String> latencyTestUrls;

  /// 超时时间
  final Duration timeout;

  /// 是否启用详细日志
  final bool enableDetailedLogging;

  /// 数据源检测配置
  final Map<String, DataSourceCheckConfig> dataSourceConfigs;

  const NetworkMonitorConfig({
    this.checkInterval = const Duration(seconds: 30),
    this.latencyTestUrls = const [
      'https://www.baidu.com',
      'https://www.tencent.com',
      'https://httpbin.org/get',
    ],
    this.timeout = const Duration(seconds: 10),
    this.enableDetailedLogging = false,
    this.dataSourceConfigs = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'checkInterval': checkInterval.inMilliseconds,
      'latencyTestUrls': latencyTestUrls,
      'timeout': timeout.inMilliseconds,
      'enableDetailedLogging': enableDetailedLogging,
      'dataSourceConfigs': dataSourceConfigs.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    };
  }
}

/// 数据源检测配置
class DataSourceCheckConfig {
  /// 检测端点URL
  final String checkUrl;

  /// 检测方法
  final String method;

  /// 请求头
  final Map<String, String>? headers;

  /// 预期状态码
  final int expectedStatusCode;

  /// 最大响应时间（毫秒）
  final int maxResponseTime;

  const DataSourceCheckConfig({
    required this.checkUrl,
    this.method = 'GET',
    this.headers,
    this.expectedStatusCode = 200,
    this.maxResponseTime = 5000,
  });

  Map<String, dynamic> toJson() {
    return {
      'checkUrl': checkUrl,
      'method': method,
      'headers': headers,
      'expectedStatusCode': expectedStatusCode,
      'maxResponseTime': maxResponseTime,
    };
  }
}

/// 网络监控器
///
/// 提供网络状态检测和数据源可用性评估功能
/// 支持实时监控、健康检查和智能降级建议
class NetworkMonitor {
  /// 配置
  final NetworkMonitorConfig config;

  /// Connectivity插件实例
  final Connectivity _connectivity = Connectivity();

  /// Dio客户端用于网络测试
  late final Dio _dio;

  /// 网络状态流控制器
  final StreamController<NetworkStatusResult> _networkStatusController =
      StreamController<NetworkStatusResult>.broadcast();

  /// 数据源可用性流控制器
  final StreamController<Map<String, DataSourceAvailability>>
      _dataSourcesController =
      StreamController<Map<String, DataSourceAvailability>>.broadcast();

  /// 监控定时器
  Timer? _monitorTimer;

  /// 当前网络状态
  NetworkStatusResult? _currentNetworkStatus;

  /// 数据源可用性缓存
  final Map<String, DataSourceAvailability> _dataSourceAvailability = {};

  /// 连接状态订阅
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  /// 是否正在监控
  bool _isMonitoring = false;

  NetworkMonitor({
    required this.config,
  }) {
    _initializeDio();
  }

  /// 初始化Dio客户端
  void _initializeDio() {
    _dio = Dio(BaseOptions(
      connectTimeout: config.timeout,
      receiveTimeout: config.timeout,
      headers: {
        'User-Agent': 'Baostock-NetworkMonitor/1.0',
      },
    ));

    if (config.enableDetailedLogging) {
      _dio.interceptors.add(
        LogInterceptor(
          logPrint: (obj) => AppLogger.debug('NetworkMonitor', obj.toString()),
        ),
      );
    }
  }

  /// 获取网络状态流
  Stream<NetworkStatusResult> get networkStatusStream =>
      _networkStatusController.stream;

  /// 获取数据源可用性流
  Stream<Map<String, DataSourceAvailability>> get dataSourcesStream =>
      _dataSourcesController.stream;

  /// 当前网络状态
  NetworkStatusResult? get currentNetworkStatus => _currentNetworkStatus;

  /// 数据源可用性状态
  Map<String, DataSourceAvailability> get dataSourceAvailability =>
      Map.unmodifiable(_dataSourceAvailability);

  /// 是否正在监控
  bool get isMonitoring => _isMonitoring;

  /// 开始监控
  Future<void> startMonitoring() async {
    if (_isMonitoring) {
      AppLogger.warn('网络监控已在运行中');
      return;
    }

    _isMonitoring = true;
    AppLogger.info('启动网络监控', '检测间隔: ${config.checkInterval}');

    // 订阅连接状态变化
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (result) => _onConnectivityChanged([result]),
    );

    // 立即执行一次检测
    await _performNetworkCheck();
    await _performDataSourceCheck();

    // 启动定时监控
    _monitorTimer = Timer.periodic(config.checkInterval, (_) async {
      await _performNetworkCheck();
      await _performDataSourceCheck();
    });

    AppLogger.info('网络监控已启动');
  }

  /// 停止监控
  Future<void> stopMonitoring() async {
    if (!_isMonitoring) return;

    _isMonitoring = false;

    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;

    _monitorTimer?.cancel();
    _monitorTimer = null;

    AppLogger.info('网络监控已停止');
  }

  /// 处理连接状态变化
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    AppLogger.info('网络连接状态变化', '新状态: ${results.map((e) => e.name).join(', ')}');

    // 立即执行网络检测
    _performNetworkCheck();
  }

  /// 执行网络检测
  Future<NetworkStatusResult> _performNetworkCheck() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      final connectivityResults = [connectivityResult];
      final isConnected = connectivityResult != ConnectivityResult.none;

      if (!isConnected) {
        final result = NetworkStatusResult.offline();
        _updateNetworkStatus(result);
        return result;
      }

      // 测试网络延迟和质量
      final latencyResult = await _testNetworkLatency();
      final hasInternetAccess = latencyResult != null;

      // 计算网络质量评分
      double quality = 0.0;
      if (hasInternetAccess && latencyResult != null) {
        quality = _calculateNetworkQuality(connectivityResults, latencyResult);
      }

      final result = NetworkStatusResult.online(
        connectivityResults: connectivityResults,
        quality: quality,
        latency: latencyResult,
        hasInternetAccess: hasInternetAccess,
        metadata: {
          'testUrls': config.latencyTestUrls,
          'testCount': config.latencyTestUrls.length,
        },
      );

      _updateNetworkStatus(result);
      return result;
    } catch (e) {
      AppLogger.error('网络检测失败', e);
      final result = NetworkStatusResult.offline();
      _updateNetworkStatus(result);
      return result;
    }
  }

  /// 测试网络延迟
  Future<int?> _testNetworkLatency() async {
    final List<int> latencies = [];

    for (final url in config.latencyTestUrls) {
      try {
        final stopwatch = Stopwatch()..start();
        final response = await _dio
            .head(
              url,
              options: Options(
                receiveTimeout: const Duration(seconds: 5),
              ),
            )
            .timeout(const Duration(seconds: 5));
        stopwatch.stop();

        if (response.statusCode == 200) {
          latencies.add(stopwatch.elapsedMilliseconds);
          if (config.enableDetailedLogging) {
            AppLogger.debug('延迟测试', '$url: ${stopwatch.elapsedMilliseconds}ms');
          }
        }
      } catch (e) {
        if (config.enableDetailedLogging) {
          AppLogger.debug('延迟测试失败', '$url: $e');
        }
      }
    }

    if (latencies.isEmpty) return null;

    // 返回中位数延迟
    latencies.sort();
    final median = latencies[latencies.length ~/ 2];

    return median;
  }

  /// 计算网络质量评分
  double _calculateNetworkQuality(
      List<ConnectivityResult> connectivityResults, int latency) {
    double score = 0.0;

    // 连接类型评分
    for (final result in connectivityResults) {
      switch (result) {
        case ConnectivityResult.ethernet:
          score += 0.4; // 以太网最佳
          break;
        case ConnectivityResult.wifi:
          score += 0.3; // WiFi良好
          break;
        case ConnectivityResult.mobile:
          score += 0.2; // 移动网络一般
          break;
        case ConnectivityResult.bluetooth:
          score += 0.1; // 蓝牙连接
          break;
        case ConnectivityResult.vpn:
          score += 0.3; // VPN连接，类似WiFi
          break;
        case ConnectivityResult.other:
          score += 0.1; // 其他连接
          break;
        case ConnectivityResult.none:
          score += 0.0;
          break;
      }
    }

    // 延迟评分 (0-1000ms = 1.0-0.0)
    final latencyScore = (1000 - latency.clamp(0, 1000)) / 1000.0;
    score += latencyScore * 0.6;

    return score.clamp(0.0, 1.0);
  }

  /// 执行数据源检测
  Future<void> _performDataSourceCheck() async {
    if (config.dataSourceConfigs.isEmpty) return;

    AppLogger.debug('开始数据源检测', '检测 ${config.dataSourceConfigs.length} 个数据源');

    final Map<String, DataSourceAvailability> results = {};

    for (final entry in config.dataSourceConfigs.entries) {
      final sourceId = entry.key;
      final checkConfig = entry.value;

      try {
        final availability =
            await _checkDataSourceAvailability(sourceId, checkConfig);
        results[sourceId] = availability;
      } catch (e) {
        AppLogger.error('数据源检测失败', '源: $sourceId, 错误: $e');

        // 获取之前的失败次数
        final previousFailures =
            _dataSourceAvailability[sourceId]?.consecutiveFailures ?? 0;

        results[sourceId] = DataSourceAvailability.unavailable(
          sourceId,
          checkConfig.checkUrl,
          consecutiveFailures: previousFailures + 1,
        );
      }
    }

    _updateDataSourceAvailability(results);
  }

  /// 检查单个数据源可用性
  Future<DataSourceAvailability> _checkDataSourceAvailability(
    String sourceId,
    DataSourceCheckConfig config,
  ) async {
    final stopwatch = Stopwatch()..start();

    try {
      final response = await _dio
          .request(
            config.checkUrl,
            options: Options(
              method: config.method,
              headers: config.headers,
            ),
          )
          .timeout(this.config.timeout);

      stopwatch.stop();
      final responseTime = stopwatch.elapsedMilliseconds;

      if (response.statusCode == config.expectedStatusCode) {
        // 计算可靠性评分
        final previousAvailability = _dataSourceAvailability[sourceId];
        double reliability = 1.0;

        if (previousAvailability != null && previousAvailability.isAvailable) {
          // 使用指数移动平均来平滑可靠性评分
          reliability = previousAvailability.reliability * 0.8 + 1.0 * 0.2;
        } else if (previousAvailability != null) {
          // 从不可用状态恢复，重置可靠性
          reliability = 0.6;
        }

        return DataSourceAvailability.available(
          sourceId,
          config.checkUrl,
          responseTime: responseTime,
          reliability: reliability,
          lastSuccessTime: DateTime.now(),
          metadata: {
            'statusCode': response.statusCode,
            'config': config.toJson(),
          },
        );
      } else {
        throw Exception(
            '状态码不匹配: 期望 ${config.expectedStatusCode}, 实际 ${response.statusCode}');
      }
    } catch (e) {
      stopwatch.stop();

      // 获取之前的失败次数和可靠性
      final previousAvailability = _dataSourceAvailability[sourceId];
      final previousFailures = previousAvailability?.consecutiveFailures ?? 0;

      // 降低可靠性评分
      double reliability = previousAvailability?.reliability ?? 0.0;
      reliability *= 0.9;

      return DataSourceAvailability.unavailable(
        sourceId,
        config.checkUrl,
        consecutiveFailures: previousFailures + 1,
        metadata: {
          'error': e.toString(),
          'responseTime': stopwatch.elapsedMilliseconds,
          'config': config.toJson(),
        },
      );
    }
  }

  /// 更新网络状态
  void _updateNetworkStatus(NetworkStatusResult result) {
    _currentNetworkStatus = result;

    if (!_networkStatusController.isClosed) {
      _networkStatusController.add(result);
    }

    if (config.enableDetailedLogging) {
      AppLogger.debug('网络状态更新', result.toString());
    }
  }

  /// 更新数据源可用性
  void _updateDataSourceAvailability(
      Map<String, DataSourceAvailability> results) {
    _dataSourceAvailability.clear();
    _dataSourceAvailability.addAll(results);

    if (!_dataSourcesController.isClosed) {
      _dataSourcesController.add(Map.unmodifiable(_dataSourceAvailability));
    }

    if (config.enableDetailedLogging) {
      AppLogger.debug('数据源可用性更新',
          '可用: ${results.values.where((r) => r.isAvailable).length}/${results.length}');
    }
  }

  /// 手动触发网络检测
  Future<NetworkStatusResult> checkNetworkStatus() async {
    return await _performNetworkCheck();
  }

  /// 手动触发数据源检测
  Future<Map<String, DataSourceAvailability>> checkDataSources() async {
    await _performDataSourceCheck();
    return Map.unmodifiable(_dataSourceAvailability);
  }

  /// 检查特定数据源是否可用
  DataSourceAvailability? getDataSourceAvailability(String sourceId) {
    return _dataSourceAvailability[sourceId];
  }

  /// 获取最佳可用数据源
  String? getBestAvailableDataSource() {
    final availableSources = _dataSourceAvailability.entries
        .where((entry) => entry.value.isAvailable)
        .toList();

    if (availableSources.isEmpty) return null;

    // 按健康状态和可靠性排序
    availableSources.sort((a, b) {
      // 首先按健康状态排序
      final healthCompare =
          a.value.health.index.compareTo(b.value.health.index);
      if (healthCompare != 0) return healthCompare;

      // 然后按可靠性排序
      return b.value.reliability.compareTo(a.value.reliability);
    });

    return availableSources.first.key;
  }

  /// 获取监控统计信息
  Map<String, dynamic> getMonitoringStats() {
    return {
      'isMonitoring': _isMonitoring,
      'config': config.toJson(),
      'currentNetworkStatus': _currentNetworkStatus?.toJson(),
      'dataSourceCount': _dataSourceAvailability.length,
      'availableDataSources': _dataSourceAvailability.values
          .where((source) => source.isAvailable)
          .length,
      'bestDataSource': getBestAvailableDataSource(),
      'dataSourceAvailability': _dataSourceAvailability.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    };
  }

  /// 销毁监控器
  Future<void> dispose() async {
    await stopMonitoring();

    await _networkStatusController.close();
    await _dataSourcesController.close();

    AppLogger.info('网络监控器已销毁');
  }
}
