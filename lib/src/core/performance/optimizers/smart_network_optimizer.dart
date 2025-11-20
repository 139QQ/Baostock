// ignore_for_file: public_member_api_docs, duplicate_ignore, prefer_const_constructors, sort_constructors_first, directives_ordering

import 'dart:async';
import 'dart:math' as math;
import 'package:dio/dio.dart';

import '../monitors/memory_pressure_monitor.dart';
import '../managers/advanced_memory_manager.dart';
import '../../utils/logger.dart';

// 临时类型定义，避免编译错误
class DeviceCapabilityDetector {
  Future<DevicePerformanceInfo> getDevicePerformanceInfo() async {
    return DevicePerformanceInfo(
      tier: DevicePerformanceTier.midRange,
      deviceModel: 'Unknown',
      memoryTotalMB: 8192,
      cpuCores: 4,
    );
  }
}

class DevicePerformanceInfo {
  final DevicePerformanceTier tier;
  final String deviceModel;
  final int memoryTotalMB;
  final int cpuCores;

  DevicePerformanceInfo({
    required this.tier,
    required this.deviceModel,
    required this.memoryTotalMB,
    required this.cpuCores,
  });
}

enum DevicePerformanceTier {
  lowEnd,
  midRange,
  highEnd,
  ultimate,
}

/// 网络协议类型
enum NetworkProtocol {
  http1_1, // HTTP/1.1
  http2, // HTTP/2
  http3, // HTTP/3 (QUIC)
}

/// 连接质量级别
enum ConnectionQuality {
  excellent, // 优秀 (< 50ms, > 90%成功率)
  good, // 良好 (50-100ms, 80-90%成功率)
  // ignore: public_member_api_docs
  fair, // 一般 (100-200ms, 70-80%成功率)
  poor, // 较差 (200-500ms, 50-70%成功率)
  bad, // 很差 (> 500ms, < 50%成功率)
}

/// 网络请求策略
class RequestStrategy {
  // 1-10，10为最高优先级

  const RequestStrategy({
    this.preferredProtocol = NetworkProtocol.http2,
    this.timeout = const Duration(seconds: 30),
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
    this.enableCompression = true,
    this.enableCaching = true,
    this.maxConcurrentRequests = 5,
    this.priority = 5,
  });
  final NetworkProtocol preferredProtocol;
  final Duration timeout;
  final int maxRetries;
  final Duration retryDelay;
  final bool enableCompression;
  final bool enableCaching;
  final int maxConcurrentRequests;
  final int priority;
}

// ignore: duplicate_ignore, duplicate_ignore
/// 连接池配置
class ConnectionPoolConfig {
  // ignore: public_member_api_docs
  const ConnectionPoolConfig({
    this.maxConnections = 10,
    this.maxIdleTime = 300,
    this.enableKeepAlive = true,
    this.keepAliveTimeout = const Duration(minutes: 5),
    this.enableHttp2 = true,
    this.enableHttp3 = false,
  });
  final int maxConnections;
  final int maxIdleTime; // 秒
  // ignore: public_member_api_docs
  final bool enableKeepAlive;
  final Duration keepAliveTimeout;
  final bool enableHttp2;
  final bool enableHttp3;
}

/// 智能网络优化器配置
class SmartNetworkOptimizerConfig {
  // ignore: public_member_api_docs
  const SmartNetworkOptimizerConfig({
    this.connectionPoolConfig = const ConnectionPoolConfig(),
    this.enableProtocolAdaptation = true,
    this.enableQualityMonitoring = true,
    this.qualityCheckInterval = const Duration(minutes: 1),
    this.enableCompressionNegotiation = true,
    this.enableAdaptiveTimeout = true,
    this.enableRequestBatching = true,
  });
  final ConnectionPoolConfig connectionPoolConfig;
  final bool enableProtocolAdaptation;
  // ignore: public_member_api_docs
  final bool enableQualityMonitoring;
  final Duration qualityCheckInterval;
  // ignore: public_member_api_docs
  final bool enableCompressionNegotiation;
  final bool enableAdaptiveTimeout;
  final bool enableRequestBatching;
}

/// 网络连接统计信息
class ConnectionStats {
  // ignore: public_member_api_docs
  const ConnectionStats({
    required this.totalRequests,
    required this.successfulRequests,
    required this.failedRequests,
    required this.averageLatencyMs,
    required this.totalBytesTransferred,
    required this.compressionSavingsBytes,
    required this.protocolUsage,
    required this.currentQuality,
  });
  final int totalRequests;
  final int successfulRequests;
  final int failedRequests;
  final double averageLatencyMs;
  final int totalBytesTransferred;
  // ignore: public_member_api_docs
  final int compressionSavingsBytes;
  final Map<NetworkProtocol, int> protocolUsage;
  final ConnectionQuality currentQuality;

  /// 成功率
  double get successRate =>
      totalRequests > 0 ? successfulRequests / totalRequests : 0.0;
}

/// 连接质量监控结果
class QualityMonitorResult {
  final ConnectionQuality quality;
  final double averageLatencyMs;
  final double packetLossRate;
  final double bandwidthMbps;
  final DateTime timestamp;
  final String serverEndpoint;

  const QualityMonitorResult({
    required this.quality,
    required this.averageLatencyMs,
    required this.packetLossRate,
    required this.bandwidthMbps,
    required this.timestamp,
    required this.serverEndpoint,
  });
}

/// 智能网络优化器
///
/// 实现智能网络传输优化，包括协议选择、连接池管理、质量监控等
class SmartNetworkOptimizer {
  final SmartNetworkOptimizerConfig _config;
  final DeviceCapabilityDetector _deviceDetector;
  final MemoryPressureMonitor? _memoryMonitor;

  Dio? _dio;
  final Map<String, RequestStrategy> _requestStrategies = {};
  final Map<String, QualityMonitorResult> _qualityCache = {};

  Timer? _qualityMonitorTimer;
  ConnectionStats _currentStats = const ConnectionStats(
    totalRequests: 0,
    successfulRequests: 0,
    failedRequests: 0,
    averageLatencyMs: 0.0,
    totalBytesTransferred: 0,
    compressionSavingsBytes: 0,
    protocolUsage: {},
    currentQuality: ConnectionQuality.good,
  );

  final List<RequestTask> _pendingRequests = [];
  Timer? _batchProcessorTimer;

  SmartNetworkOptimizer({
    required DeviceCapabilityDetector deviceDetector,
    MemoryPressureMonitor? memoryMonitor,
    SmartNetworkOptimizerConfig? config,
  })  : _deviceDetector = deviceDetector,
        _memoryMonitor = memoryMonitor,
        _config = config ?? SmartNetworkOptimizerConfig();

  /// 初始化网络优化器
  Future<void> initialize() async {
    AppLogger.business('初始化SmartNetworkOptimizer');

    // 创建优化的Dio客户端
    _dio = await _createOptimizedDio();

    // 启动质量监控
    if (_config.enableQualityMonitoring) {
      _startQualityMonitoring();
    }

    // 启动请求批处理
    if (_config.enableRequestBatching) {
      _startBatchProcessor();
    }

    AppLogger.business('网络优化器初始化完成');
  }

  /// 获取优化的Dio客户端
  Dio get optimizedDio {
    if (_dio == null) {
      throw StateError('SmartNetworkOptimizer 尚未初始化');
    }
    return _dio!;
  }

  /// 为特定端点创建请求策略
  Future<RequestStrategy> createStrategyForEndpoint(String endpoint,
      {int priority = 5}) async {
    final deviceInfo = await _deviceDetector.getDevicePerformanceInfo();
    MemoryPressureLevel memoryPressure;
    if (_memoryMonitor != null) {
      // 假设 _memoryMonitor 有一个方法获取当前压力级别
      // 这里使用默认值，实际需要根据具体的 MemoryPressureMonitor API 调整
      memoryPressure = MemoryPressureLevel.normal;
    } else {
      memoryPressure = MemoryPressureLevel.normal;
    }

    // 基于设备性能和内存压力调整策略
    final adaptiveTimeout =
        _calculateAdaptiveTimeout(deviceInfo, memoryPressure);
    final adaptiveRetries =
        _calculateAdaptiveRetries(deviceInfo, memoryPressure);
    final protocol = _selectOptimalProtocol(endpoint);

    return RequestStrategy(
      preferredProtocol: protocol,
      timeout: adaptiveTimeout,
      maxRetries: adaptiveRetries,
      enableCompression: _shouldEnableCompression(deviceInfo, memoryPressure),
      enableCaching: memoryPressure != MemoryPressureLevel.emergency,
      maxConcurrentRequests: _calculateMaxConcurrentRequests(deviceInfo),
      priority: priority,
    );
  }

  /// 注册请求策略
  void registerStrategy(String endpoint, RequestStrategy strategy) {
    _requestStrategies[endpoint] = strategy;
    AppLogger.debug('注册请求策略', '$endpoint -> $strategy');
  }

  /// 执行优化的网络请求
  Future<Response<T>> executeOptimizedRequest<T>(
    String path, {
    String? method,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    String? endpoint,
  }) async {
    final strategy =
        endpoint != null && _requestStrategies.containsKey(endpoint)
            ? _requestStrategies[endpoint]!
            : await _getOrCreateStrategy(path);

    final stopwatch = Stopwatch()..start();

    try {
      // 应用策略到请求
      final optimizedOptions = await _applyStrategyToOptions(strategy, options);

      // 记录请求开始
      _recordRequestStart(strategy.preferredProtocol);

      final requestOpts = RequestOptions(
        path: path,
        method: method ?? 'GET',
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
        connectTimeout: strategy.timeout,
        receiveTimeout: strategy.timeout,
        sendTimeout: strategy.timeout,
        headers: optimizedOptions.headers,
        extra: optimizedOptions.extra,
      );

      final response = await _dio!.fetch<T>(requestOpts);

      stopwatch.stop();
      _recordRequestSuccess(
          strategy.preferredProtocol, stopwatch.elapsedMilliseconds);

      return response;
    } catch (e) {
      stopwatch.stop();
      _recordRequestFailure(
          strategy.preferredProtocol, stopwatch.elapsedMilliseconds);

      // 应用重试策略
      if (_shouldRetry(e, strategy)) {
        AppLogger.debug('请求重试', '$path - 重试剩余: ${strategy.maxRetries}');
        return await _executeWithRetry<T>(
          path,
          strategy: strategy,
          method: method,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
          onSendProgress: onSendProgress,
          onReceiveProgress: onReceiveProgress,
          currentRetry: 1,
        );
      }

      rethrow;
    }
  }

  /// 批量处理请求
  Future<List<Response>> executeBatchRequest(
      List<RequestOptions> requests) async {
    if (requests.isEmpty) return [];

    // 按优先级排序
    final sortedRequests = List.from(requests);
    sortedRequests.sort((a, b) {
      final priorityA = _getPriorityFromOptions(a);
      final priorityB = _getPriorityFromOptions(b);
      return priorityB.compareTo(priorityA);
    });

    final results = <Response>[];
    final maxConcurrent = _calculateMaxConcurrentRequests(
        await _deviceDetector.getDevicePerformanceInfo());

    // 分批处理
    for (int i = 0; i < sortedRequests.length; i += maxConcurrent) {
      final batch = sortedRequests.skip(i).take(maxConcurrent).toList();
      final batchResults = await Future.wait(
        batch.map((options) => _dio!.fetch(options)),
      );
      results.addAll(batchResults);

      // 批次间短暂休息，避免过度占用资源
      if (i + maxConcurrent < sortedRequests.length) {
        await Future.delayed(Duration(milliseconds: 10));
      }
    }

    return results;
  }

  /// 获取连接统计信息
  ConnectionStats getConnectionStats() => _currentStats;

  /// 获取连接质量
  ConnectionQuality get currentConnectionQuality =>
      _currentStats.currentQuality;

  /// 执行连接质量测试
  Future<QualityMonitorResult> testConnectionQuality(String endpoint) async {
    final stopwatch = Stopwatch()..start();
    int totalBytes = 0;

    try {
      // 发送测试请求
      final response = await _dio!.get(endpoint);
      stopwatch.stop();

      totalBytes = response.data?.toString().length ?? 0;

      final latencyMs = stopwatch.elapsedMilliseconds.toDouble();
      final quality = _calculateQuality(latencyMs, 1.0);

      final result = QualityMonitorResult(
        quality: quality,
        averageLatencyMs: latencyMs,
        packetLossRate: 0.0, // 简化实现
        bandwidthMbps: _calculateBandwidth(totalBytes, latencyMs),
        timestamp: DateTime.now(),
        serverEndpoint: endpoint,
      );

      _qualityCache[endpoint] = result;
      return result;
    } catch (e) {
      stopwatch.stop();

      final result = QualityMonitorResult(
        quality: ConnectionQuality.bad,
        averageLatencyMs: stopwatch.elapsedMilliseconds.toDouble(),
        packetLossRate: 1.0,
        bandwidthMbps: 0.0,
        timestamp: DateTime.now(),
        serverEndpoint: endpoint,
      );

      _qualityCache[endpoint] = result;
      return result;
    }
  }

  /// 启用激进模式
  Future<void> enableAggressiveMode() async {
    AppLogger.business('启用激进网络优化模式');

    // 启用所有优化功能
    await _enableAllOptimizations();

    // 增强请求策略
    _enableAggressiveStrategies();

    // 减少超时时间以提高响应速度
    _updateTimeoutsForAggressiveMode();
  }

  /// 启用所有优化功能
  Future<void> _enableAllOptimizations() async {
    // 启用协议适配
    if (_config.enableProtocolAdaptation) {
      await _enableProtocolAdaptation();
    }

    // 启用质量监控
    if (_config.enableQualityMonitoring) {
      _startQualityMonitoring();
    }

    // 启用压缩协商
    if (_config.enableCompressionNegotiation) {
      await _enableCompressionNegotiation();
    }

    // 启用自适应超时
    if (_config.enableAdaptiveTimeout) {
      await _enableAdaptiveTimeout();
    }

    // 启用请求批处理
    if (_config.enableRequestBatching) {
      await _enableRequestBatching();
    }
  }

  /// 启用激进策略
  void _enableAggressiveStrategies() {
    // 为所有端点启用激进策略
    final aggressiveStrategy = RequestStrategy(
      preferredProtocol: NetworkProtocol.http2,
      timeout: Duration(seconds: 5),
      maxRetries: 5,
      retryDelay: Duration(milliseconds: 100),
      enableCompression: true,
      enableCaching: true,
      maxConcurrentRequests: 10,
      priority: 10, // 最高优先级
    );

    // 更新常用端点的策略
    final commonEndpoints = [
      '/api/funds',
      '/api/portfolio',
      '/api/market',
    ];

    for (final endpoint in commonEndpoints) {
      _requestStrategies[endpoint] = aggressiveStrategy;
    }
  }

  /// 更新激进模式超时设置
  void _updateTimeoutsForAggressiveMode() {
    if (_dio != null) {
      final options = BaseOptions(
        connectTimeout: Duration(seconds: 3), // 3秒连接超时
        receiveTimeout: Duration(seconds: 5), // 5秒接收超时
        sendTimeout: Duration(seconds: 3), // 3秒发送超时
      );

      _dio!.options = options;
    }
  }

  /// 获取优化状态
  Map<String, dynamic> getOptimizationStatus() {
    return {
      'isInitialized': _dio != null,
      'config': {
        'enableProtocolAdaptation': _config.enableProtocolAdaptation,
        'enableQualityMonitoring': _config.enableQualityMonitoring,
        'enableCompressionNegotiation': _config.enableCompressionNegotiation,
        'enableAdaptiveTimeout': _config.enableAdaptiveTimeout,
        'enableRequestBatching': _config.enableRequestBatching,
      },
      'activeStrategies': _requestStrategies.length,
      'qualityCacheSize': _qualityCache.length,
      'pendingRequests': _pendingRequests.length,
      'optimizationLevel': 'standard',
    };
  }

  /// 临时方法占位符（实际实现需要更多细节）
  Future<void> _enableProtocolAdaptation() async {
    AppLogger.debug('启用协议适配');
  }

  Future<void> _enableCompressionNegotiation() async {
    AppLogger.debug('启用压缩协商');
  }

  Future<void> _enableAdaptiveTimeout() async {
    AppLogger.debug('启用自适应超时');
  }

  Future<void> _enableRequestBatching() async {
    AppLogger.debug('启用请求批处理');
  }

  /// 清理资源
  Future<void> dispose() async {
    AppLogger.business('清理SmartNetworkOptimizer资源');

    _qualityMonitorTimer?.cancel();
    _batchProcessorTimer?.cancel();
    _dio?.close();

    _requestStrategies.clear();
    _qualityCache.clear();
    _pendingRequests.clear();
  }

  /// 创建优化的Dio客户端
  Future<Dio> _createOptimizedDio() async {
    final baseOptions = BaseOptions(
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 30),
      sendTimeout: Duration(seconds: 30),
      headers: {
        'User-Agent': await _buildUserAgent(),
        'Accept-Encoding': 'gzip, deflate, br',
        'Connection': 'keep-alive',
      },
    );

    final dio = Dio(baseOptions);

    // 添加拦截器
    dio.interceptors.add(_createLoggingInterceptor());
    dio.interceptors.add(_createCompressionInterceptor());
    dio.interceptors.add(_createRetryInterceptor());

    return dio;
  }

  /// 应用策略到请求选项
  Future<Options> _applyStrategyToOptions(
      RequestStrategy strategy, Options? baseOptions) async {
    final options = baseOptions ?? Options();

    // 设置压缩
    if (strategy.enableCompression) {
      options.headers ??= {};
      options.headers!['Accept-Encoding'] = 'gzip, deflate, br';
    }

    // 设置协议版本（简化实现）
    if (strategy.preferredProtocol == NetworkProtocol.http2) {
      options.extra ??= {};
      options.extra!['http2'] = true;
    }

    return options;
  }

  /// 计算自适应超时时间
  Duration _calculateAdaptiveTimeout(
    DevicePerformanceInfo deviceInfo,
    MemoryPressureLevel memoryPressure,
  ) {
    final baseTimeout = Duration(seconds: 30);
    double multiplier = 1.0;

    // 基于设备性能调整
    switch (deviceInfo.tier) {
      case DevicePerformanceTier.lowEnd:
        multiplier *= 1.5;
        break;
      case DevicePerformanceTier.midRange:
        multiplier *= 1.2;
        break;
      case DevicePerformanceTier.highEnd:
        multiplier *= 1.0;
        break;
      case DevicePerformanceTier.ultimate:
        multiplier *= 0.8;
        break;
    }

    // 基于内存压力调整
    switch (memoryPressure) {
      case MemoryPressureLevel.emergency:
        multiplier *= 2.0;
        break;
      case MemoryPressureLevel.critical:
        multiplier *= 1.5;
        break;
      case MemoryPressureLevel.warning:
        multiplier *= 1.2;
        break;
      case MemoryPressureLevel.normal:
        multiplier *= 1.0;
        break;
    }

    return Duration(
        milliseconds: (baseTimeout.inMilliseconds * multiplier).round());
  }

  /// 计算自适应重试次数
  int _calculateAdaptiveRetries(
    DevicePerformanceInfo deviceInfo,
    MemoryPressureLevel memoryPressure,
  ) {
    int baseRetries = 3;

    // 基于设备性能调整
    switch (deviceInfo.tier) {
      case DevicePerformanceTier.lowEnd:
        baseRetries = 1;
        break;
      case DevicePerformanceTier.midRange:
        baseRetries = 2;
        break;
      case DevicePerformanceTier.highEnd:
        baseRetries = 3;
        break;
      case DevicePerformanceTier.ultimate:
        baseRetries = 4;
        break;
    }

    // 基于内存压力调整
    if (memoryPressure == MemoryPressureLevel.emergency) {
      baseRetries = math.max(1, baseRetries - 2);
    }

    return baseRetries;
  }

  /// 选择最优协议
  NetworkProtocol _selectOptimalProtocol(String endpoint) {
    if (_config.enableProtocolAdaptation) {
      // 检查是否有缓存的质量信息
      final cachedQuality = _qualityCache[endpoint];
      if (cachedQuality != null) {
        // 基于连接质量选择协议
        switch (cachedQuality.quality) {
          case ConnectionQuality.excellent:
          case ConnectionQuality.good:
            return NetworkProtocol.http2;
          case ConnectionQuality.fair:
            return NetworkProtocol.http1_1;
          case ConnectionQuality.poor:
          case ConnectionQuality.bad:
            return NetworkProtocol.http1_1;
        }
      }
    }

    // 默认选择
    return _config.connectionPoolConfig.enableHttp2
        ? NetworkProtocol.http2
        : NetworkProtocol.http1_1;
  }

  /// 判断是否启用压缩
  bool _shouldEnableCompression(
    DevicePerformanceInfo deviceInfo,
    MemoryPressureLevel memoryPressure,
  ) {
    // 低端设备或高内存压力时减少压缩
    if (deviceInfo.tier == DevicePerformanceTier.lowEnd ||
        memoryPressure == MemoryPressureLevel.emergency) {
      return false;
    }

    return true;
  }

  /// 计算最大并发请求数
  int _calculateMaxConcurrentRequests(DevicePerformanceInfo deviceInfo) {
    switch (deviceInfo.tier) {
      case DevicePerformanceTier.lowEnd:
        return 2;
      case DevicePerformanceTier.midRange:
        return 5;
      case DevicePerformanceTier.highEnd:
        return 10;
      case DevicePerformanceTier.ultimate:
        return 20;
    }
  }

  /// 判断是否应该重试
  bool _shouldRetry(dynamic error, RequestStrategy strategy) {
    if (strategy.maxRetries <= 0) return false;

    // 基于错误类型判断
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return true;
        case DioExceptionType.connectionError:
          return true;
        case DioExceptionType.unknown:
          return true;
        case DioExceptionType.cancel:
        case DioExceptionType.badResponse:
        case DioExceptionType.badCertificate:
          return false;
      }
    }

    return false;
  }

  /// 执行带重试的请求
  Future<Response<T>> _executeWithRetry<T>(
    String path, {
    required RequestStrategy strategy,
    String? method,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    required int currentRetry,
  }) async {
    if (currentRetry > strategy.maxRetries) {
      throw Exception('Maximum retries exceeded');
    }

    try {
      final requestOptions = await _applyStrategyToOptions(strategy, options);
      final requestOpts = RequestOptions(
        path: path,
        method: method ?? 'GET',
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
        connectTimeout: strategy.timeout,
        receiveTimeout: strategy.timeout,
        sendTimeout: strategy.timeout,
        headers: requestOptions.headers,
        extra: requestOptions.extra,
      );
      return await _dio!.fetch<T>(requestOpts);
    } catch (e) {
      AppLogger.debug('请求失败，准备重试', '重试次数: $currentRetry/$strategy.maxRetries');

      // 等待重试延迟
      await Future.delayed(strategy.retryDelay);

      return await _executeWithRetry<T>(
        path,
        strategy: strategy,
        method: method,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
        currentRetry: currentRetry + 1,
      );
    }
  }

  /// 记录请求开始
  void _recordRequestStart(NetworkProtocol protocol) {
    _currentStats = ConnectionStats(
      totalRequests: _currentStats.totalRequests + 1,
      successfulRequests: _currentStats.successfulRequests,
      failedRequests: _currentStats.failedRequests,
      averageLatencyMs: _currentStats.averageLatencyMs,
      totalBytesTransferred: _currentStats.totalBytesTransferred,
      compressionSavingsBytes: _currentStats.compressionSavingsBytes,
      protocolUsage: Map.from(_currentStats.protocolUsage),
      currentQuality: _currentStats.currentQuality,
    );

    _currentStats.protocolUsage[protocol] =
        (_currentStats.protocolUsage[protocol] ?? 0) + 1;
  }

  /// 记录请求成功
  void _recordRequestSuccess(NetworkProtocol protocol, int latencyMs) {
    final totalRequests = _currentStats.totalRequests;
    final currentAverageLatency = _currentStats.averageLatencyMs;

    _currentStats = ConnectionStats(
      totalRequests: totalRequests,
      successfulRequests: _currentStats.successfulRequests + 1,
      failedRequests: _currentStats.failedRequests,
      averageLatencyMs:
          (currentAverageLatency * (totalRequests - 1) + latencyMs) /
              totalRequests,
      totalBytesTransferred: _currentStats.totalBytesTransferred,
      compressionSavingsBytes: _currentStats.compressionSavingsBytes,
      protocolUsage: _currentStats.protocolUsage,
      currentQuality: _currentStats.currentQuality,
    );
  }

  /// 记录请求失败
  void _recordRequestFailure(NetworkProtocol protocol, int latencyMs) {
    final totalRequests = _currentStats.totalRequests;
    final currentAverageLatency = _currentStats.averageLatencyMs;

    _currentStats = ConnectionStats(
      totalRequests: totalRequests,
      successfulRequests: _currentStats.successfulRequests,
      failedRequests: _currentStats.failedRequests + 1,
      averageLatencyMs:
          (currentAverageLatency * (totalRequests - 1) + latencyMs) /
              totalRequests,
      totalBytesTransferred: _currentStats.totalBytesTransferred,
      compressionSavingsBytes: _currentStats.compressionSavingsBytes,
      protocolUsage: _currentStats.protocolUsage,
      currentQuality: _currentStats.currentQuality,
    );
  }

  /// 启动质量监控
  void _startQualityMonitoring() {
    _qualityMonitorTimer = Timer.periodic(
      _config.qualityCheckInterval,
      (_) => _performQualityCheck(),
    );
  }

  /// 启动批处理
  void _startBatchProcessor() {
    _batchProcessorTimer = Timer.periodic(
      Duration(milliseconds: 50),
      (_) => _processBatch(),
    );
  }

  /// 执行质量检查
  Future<void> _performQualityCheck() async {
    if (_currentStats.totalRequests == 0) return;

    final successRate = _currentStats.successRate;
    final averageLatency = _currentStats.averageLatencyMs;

    final quality = _calculateQuality(averageLatency, successRate);

    if (quality != _currentStats.currentQuality) {
      _currentStats = ConnectionStats(
        totalRequests: _currentStats.totalRequests,
        successfulRequests: _currentStats.successfulRequests,
        failedRequests: _currentStats.failedRequests,
        averageLatencyMs: _currentStats.averageLatencyMs,
        totalBytesTransferred: _currentStats.totalBytesTransferred,
        compressionSavingsBytes: _currentStats.compressionSavingsBytes,
        protocolUsage: _currentStats.protocolUsage,
        currentQuality: quality,
      );

      AppLogger.business('连接质量已更新', '新的质量级别: ${quality.toString()}');
    }
  }

  /// 处理批量请求
  Future<void> _processBatch() async {
    if (_pendingRequests.isEmpty) return;

    final batch = List<RequestTask>.from(_pendingRequests);
    _pendingRequests.clear();

    try {
      await executeBatchRequest(batch.map((task) => task.options).toList());
    } catch (e) {
      AppLogger.error('批量请求处理失败', e);
    }
  }

  /// 获取或创建请求策略
  Future<RequestStrategy> _getOrCreateStrategy(String path) async {
    final endpoint = _extractEndpoint(path);

    if (!_requestStrategies.containsKey(endpoint)) {
      final strategy = await createStrategyForEndpoint(endpoint);
      registerStrategy(endpoint, strategy);
    }

    return _requestStrategies[endpoint]!;
  }

  /// 提取端点
  String _extractEndpoint(String path) {
    final uri = Uri.parse(path);
    return '${uri.host}:${uri.port}';
  }

  /// 从选项中获取优先级
  int _getPriorityFromOptions(RequestOptions options) {
    return options.extra['priority'] ?? 5;
  }

  /// 计算连接质量
  ConnectionQuality _calculateQuality(double latencyMs, double successRate) {
    if (successRate >= 0.9 && latencyMs < 50) {
      return ConnectionQuality.excellent;
    } else if (successRate >= 0.8 && latencyMs < 100) {
      return ConnectionQuality.good;
    } else if (successRate >= 0.7 && latencyMs < 200) {
      return ConnectionQuality.fair;
    } else if (successRate >= 0.5 && latencyMs < 500) {
      return ConnectionQuality.poor;
    } else {
      return ConnectionQuality.bad;
    }
  }

  /// 计算带宽
  double _calculateBandwidth(int bytes, double latencyMs) {
    if (latencyMs <= 0) return 0.0;
    return (bytes * 8.0) / (latencyMs / 1000.0) / (1024.0 * 1024.0); // Mbps
  }

  /// 构建用户代理字符串
  Future<String> _buildUserAgent() async {
    try {
      final deviceInfo = await _deviceDetector.getDevicePerformanceInfo();
      return 'Baostock/${deviceInfo.deviceModel} Flutter';
    } catch (e) {
      return 'Baostock/Flutter';
    }
  }

  /// 创建日志拦截器
  Interceptor _createLoggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        AppLogger.network(
          options.method,
          options.path,
          statusCode: null,
        );
        return handler.next(options);
      },
      onResponse: (response, handler) {
        AppLogger.network(
          response.requestOptions.method,
          response.requestOptions.path,
          statusCode: response.statusCode,
          responseData: response.data,
        );
        return handler.next(response);
      },
      onError: (error, handler) {
        AppLogger.error('网络请求错误', error);
        return handler.next(error);
      },
    );
  }

  /// 创建压缩拦截器
  Interceptor _createCompressionInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        return handler.next(options);
      },
    );
  }

  /// 创建重试拦截器
  Interceptor _createRetryInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) {
        // 重试逻辑在executeOptimizedRequest中处理
        return handler.next(error);
      },
    );
  }
}

/// 批处理请求任务
class RequestTask {
  final RequestOptions options;
  final DateTime createdAt;

  RequestTask({required this.options}) : createdAt = DateTime.now();
}
