import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import '../../../../core/utils/logger.dart';

/// NAV数据延迟监控和性能指标收集器
///
/// 监控NAV数据处理的各个阶段的延迟和性能指标
/// 提供详细的性能分析和优化建议
class NavLatencyMonitor {
  /// 单例实例
  static final NavLatencyMonitor _instance = NavLatencyMonitor._internal();

  factory NavLatencyMonitor() => _instance;

  NavLatencyMonitor._internal() {
    _initialize();
  }

  /// 延迟阈值配置
  final LatencyThresholds _thresholds = LatencyThresholds();

  /// 性能数据收集器
  final PerformanceDataCollector _collector = PerformanceDataCollector();

  /// 延迟事件队列
  final Queue<LatencyEvent> _latencyEvents = Queue<LatencyEvent>();

  /// 性能指标缓存
  final Map<String, Map<String, dynamic>> _metricsCache = {};

  /// 实时监控状态
  bool _isMonitoring = false;

  /// 监控定时器
  Timer? _monitoringTimer;

  /// 报告定时器
  Timer? _reportTimer;

  /// 异常检测器
  final AnomalyDetector _anomalyDetector = AnomalyDetector();

  /// 初始化监控器
  Future<void> _initialize() async {
    try {
      // 启动监控定时器
      _startMonitoring();

      // 启动报告定时器
      _startReporting();

      AppLogger.info('NavLatencyMonitor initialized successfully');
    } catch (e) {
      AppLogger.error(
          'Failed to initialize NavLatencyMonitor', e, StackTrace.current);
    }
  }

  /// 开始监控操作
  String startOperation(String operationType, Map<String, dynamic>? context) {
    final operationId = _generateOperationId();
    final event = LatencyEvent(
      operationId: operationId,
      operationType: operationType,
      startTime: DateTime.now(),
      context: context ?? {},
    );

    _latencyEvents.add(event);

    AppLogger.debug('开始监控操作: $operationType ($operationId)');
    return operationId;
  }

  /// 结束监控操作
  void endOperation(String operationId,
      {Map<String, dynamic>? result, bool success = true}) {
    try {
      final event = _latencyEvents.cast<LatencyEvent?>().firstWhere(
            (e) => e?.operationId == operationId,
            orElse: () => null,
          );

      if (event == null) {
        AppLogger.warn('未找到操作事件: $operationId');
        return;
      }

      event.endTime = DateTime.now();
      event.result = result;
      event.success = success;

      final latency = event.endTime!.difference(event.startTime);

      // 收集性能数据
      _collector.recordLatency(event);

      // 检查延迟异常
      _anomalyDetector.checkLatencyAnomaly(event);

      AppLogger.debug(
          '操作完成: ${event.operationType} ($operationId) - ${latency.inMilliseconds}ms');

      // 如果延迟过高，记录警告
      if (latency > _thresholds.getThreshold(event.operationType)) {
        AppLogger.warn(
            '高延迟检测: ${event.operationType} - ${latency.inMilliseconds}ms (阈值: ${_thresholds.getThreshold(event.operationType).inMilliseconds}ms)');
      }
    } catch (e) {
      AppLogger.error('结束监控操作失败: $operationId', e, StackTrace.current);
    }
  }

  /// 记录自定义性能指标
  void recordMetric(String metricName, dynamic value,
      {Map<String, dynamic>? tags}) {
    _collector.recordCustomMetric(metricName, value, tags: tags);
  }

  /// 记录错误事件
  void recordError(String operationType, String error,
      {Map<String, dynamic>? context}) {
    final errorEvent = ErrorEvent(
      operationType: operationType,
      error: error,
      timestamp: DateTime.now(),
      context: context ?? {},
    );

    _collector.recordError(errorEvent);
    AppLogger.error(
        '性能监控错误记录: $operationType', Exception(error), StackTrace.current);
  }

  /// 记录缓存命中
  void recordCacheHit(String cacheType, String key, Duration accessTime) {
    _collector.recordCacheHit(cacheType, key, accessTime);
  }

  /// 记录缓存未命中
  void recordCacheMiss(String cacheType, String key, Duration accessTime) {
    _collector.recordCacheMiss(cacheType, key, accessTime);
  }

  /// 记录网络请求
  void recordNetworkRequest(String url, Duration duration, int responseSize,
      {int statusCode = 200}) {
    _collector.recordNetworkRequest(url, duration, responseSize,
        statusCode: statusCode);
  }

  /// 获取实时性能指标
  Map<String, dynamic> getRealTimeMetrics() {
    return {
      'operations': _collector.getOperationMetrics(),
      'cache': _collector.getCacheMetrics(),
      'network': _collector.getNetworkMetrics(),
      'errors': _collector.getErrorMetrics(),
      'anomalies': _anomalyDetector.getAnomalySummary(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// 获取性能报告
  PerformanceReport getPerformanceReport({Duration? timeRange}) {
    final effectiveTimeRange = timeRange ?? const Duration(hours: 1);

    return PerformanceReport(
      timeRange: effectiveTimeRange,
      operationMetrics:
          _collector.getOperationMetrics(timeRange: effectiveTimeRange),
      cacheMetrics: _collector.getCacheMetrics(timeRange: effectiveTimeRange),
      networkMetrics:
          _collector.getNetworkMetrics(timeRange: effectiveTimeRange),
      errorMetrics: _collector.getErrorMetrics(timeRange: effectiveTimeRange),
      anomalies: _anomalyDetector.getAnomalies(timeRange: effectiveTimeRange),
      recommendations: _generateRecommendations(),
      generatedAt: DateTime.now(),
    );
  }

  /// 获取延迟分布统计
  LatencyDistribution getLatencyDistribution(String operationType,
      {Duration? timeRange}) {
    final effectiveTimeRange = timeRange ?? const Duration(hours: 1);

    final events = _latencyEvents.where((event) {
      if (event.operationType != operationType) return false;
      if (event.endTime == null) return false;

      final eventAge = DateTime.now().difference(event.startTime);
      return eventAge <= effectiveTimeRange;
    }).toList();

    if (events.isEmpty) {
      return LatencyDistribution(operationType: operationType);
    }

    final latencies =
        events.map((e) => e.endTime!.difference(e.startTime)).toList();
    latencies.sort();

    return LatencyDistribution.fromLatencies(operationType, latencies);
  }

  /// 开始持续监控
  void startContinuousMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;
    AppLogger.info('开始持续性能监控');
  }

  /// 停止持续监控
  void stopContinuousMonitoring() {
    _isMonitoring = false;
    AppLogger.info('停止持续性能监控');
  }

  /// 清理历史数据
  void cleanupOldData({Duration? maxAge}) {
    final effectiveMaxAge = maxAge ?? const Duration(days: 7);
    final cutoffTime = DateTime.now().subtract(effectiveMaxAge);

    // 清理延迟事件
    _latencyEvents.removeWhere((event) => event.startTime.isBefore(cutoffTime));

    // 清理性能数据
    _collector.cleanupOldData(maxAge: effectiveMaxAge);

    // 清理异常数据
    _anomalyDetector.cleanupOldData(maxAge: effectiveMaxAge);

    AppLogger.debug('清理了${effectiveMaxAge.inDays}天前的性能监控数据');
  }

  /// 导出性能数据
  Map<String, dynamic> exportData({Duration? timeRange}) {
    return {
      'metadata': {
        'exportTime': DateTime.now().toIso8601String(),
        'timeRange': timeRange?.inHours ?? 24,
        'version': '1.0.0',
      },
      'latencyEvents': _latencyEvents
          .where((e) =>
              timeRange == null ||
              DateTime.now().difference(e.startTime) <= timeRange)
          .map((e) => e.toJson())
          .toList(),
      'performanceData': _collector.exportData(timeRange: timeRange),
      'anomalies': _anomalyDetector.exportData(timeRange: timeRange),
    };
  }

  /// 启动监控定时器
  void _startMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isMonitoring) {
        _performHealthCheck();
      }
    });
  }

  /// 启动报告定时器
  void _startReporting() {
    _reportTimer?.cancel();
    _reportTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_isMonitoring) {
        _generatePeriodicReport();
      }
    });
  }

  /// 执行健康检查
  void _performHealthCheck() {
    try {
      final metrics = getRealTimeMetrics();

      // 检查各项指标是否在健康范围内
      final healthIssues = <String>[];

      // 检查操作延迟
      final operationMetrics = metrics['operations'] as Map<String, dynamic>;
      for (final entry in operationMetrics.entries) {
        if (entry.value is Map<String, dynamic>) {
          final opMetrics = entry.value as Map<String, dynamic>;
          final avgLatency = opMetrics['averageLatency'] as double? ?? 0.0;
          final threshold = _thresholds.getThreshold(entry.key);

          if (avgLatency > threshold.inMilliseconds) {
            healthIssues
                .add('${entry.key}平均延迟过高: ${avgLatency.toStringAsFixed(1)}ms');
          }
        }
      }

      // 检查错误率
      final errorMetrics = metrics['errors'] as Map<String, dynamic>;
      final totalErrors = errorMetrics['totalErrors'] as int? ?? 0;
      final totalOperations = errorMetrics['totalOperations'] as int? ?? 1;
      final errorRate = totalErrors / totalOperations;

      if (errorRate > 0.05) {
        // 5%错误率阈值
        healthIssues.add('错误率过高: ${(errorRate * 100).toStringAsFixed(1)}%');
      }

      // 检查缓存命中率
      final cacheMetrics = metrics['cache'] as Map<String, dynamic>;
      final overallHitRate = cacheMetrics['overallHitRate'] as double? ?? 0.0;

      if (overallHitRate < 0.8) {
        // 80%命中率阈值
        healthIssues
            .add('缓存命中率过低: ${(overallHitRate * 100).toStringAsFixed(1)}%');
      }

      if (healthIssues.isNotEmpty) {
        AppLogger.warn('性能健康检查发现问题: ${healthIssues.join(', ')}');
      }
    } catch (e) {
      AppLogger.error('性能健康检查失败', e, StackTrace.current);
    }
  }

  /// 生成定期报告
  void _generatePeriodicReport() {
    try {
      final report =
          getPerformanceReport(timeRange: const Duration(minutes: 5));

      // 记录关键指标
      AppLogger.info('性能监控报告 (5分钟):');
      AppLogger.info('  总操作数: ${report.operationMetrics['totalOperations']}');
      AppLogger.info(
          '  平均延迟: ${report.operationMetrics['overallAverageLatency']?.toStringAsFixed(1)}ms');
      AppLogger.info(
          '  缓存命中率: ${(report.cacheMetrics['overallHitRate'] * 100).toStringAsFixed(1)}%');
      AppLogger.info('  错误数: ${report.errorMetrics['totalErrors']}');

      // 检查异常
      if (report.anomalies.isNotEmpty) {
        AppLogger.warn('检测到${report.anomalies.length}个性能异常');
      }
    } catch (e) {
      AppLogger.error('生成定期性能报告失败', e, StackTrace.current);
    }
  }

  /// 生成优化建议
  List<String> _generateRecommendations() {
    final recommendations = <String>[];
    final metrics = getRealTimeMetrics();

    // 基于缓存指标的建议
    final cacheMetrics = metrics['cache'] as Map<String, dynamic>;
    final hitRate = cacheMetrics['overallHitRate'] as double? ?? 0.0;

    if (hitRate < 0.8) {
      recommendations.add(
          '缓存命中率较低(${(hitRate * 100).toStringAsFixed(1)}%)，建议增加缓存大小或优化缓存策略');
    }

    // 基于网络指标的建议
    final networkMetrics = metrics['network'] as Map<String, dynamic>;
    final avgResponseTime =
        networkMetrics['averageResponseTime'] as double? ?? 0.0;

    if (avgResponseTime > 1000) {
      // 1秒
      recommendations.add(
          '网络响应时间较慢(${avgResponseTime.toStringAsFixed(1)}ms)，建议优化网络配置或使用CDN');
    }

    // 基于错误指标的建议
    final errorMetrics = metrics['errors'] as Map<String, dynamic>;
    final errorRate = (errorMetrics['totalErrors'] as int? ?? 0) /
        (errorMetrics['totalOperations'] as int? ?? 1);

    if (errorRate > 0.05) {
      recommendations
          .add('错误率较高(${(errorRate * 100).toStringAsFixed(1)}%)，建议检查系统稳定性');
    }

    return recommendations;
  }

  /// 生成操作ID
  String _generateOperationId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = math.Random().nextInt(9999);
    return 'op_${timestamp}_$random';
  }

  /// 释放资源
  Future<void> dispose() async {
    _monitoringTimer?.cancel();
    _reportTimer?.cancel();

    _latencyEvents.clear();
    _metricsCache.clear();

    AppLogger.info('NavLatencyMonitor disposed');
  }
}

/// 延迟事件
class LatencyEvent {
  final String operationId;
  final String operationType;
  final DateTime startTime;
  DateTime? endTime;
  Map<String, dynamic>? result;
  bool success = true;
  final Map<String, dynamic> context;

  LatencyEvent({
    required this.operationId,
    required this.operationType,
    required this.startTime,
    this.endTime,
    this.result,
    this.success = true,
    required this.context,
  });

  Duration? get latency =>
      endTime != null ? endTime!.difference(startTime) : null;

  Map<String, dynamic> toJson() {
    return {
      'operationId': operationId,
      'operationType': operationType,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'latencyMs': latency?.inMilliseconds,
      'success': success,
      'context': context,
    };
  }
}

/// 错误事件
class ErrorEvent {
  ErrorEvent({
    required this.operationType,
    required this.error,
    required this.timestamp,
    required this.context,
  });
  final String operationType;
  final String error;
  final DateTime timestamp;
  final Map<String, dynamic> context;

  Map<String, dynamic> toJson() {
    return {
      'operationType': operationType,
      'error': error,
      'timestamp': timestamp.toIso8601String(),
      'context': context,
    };
  }
}

/// 延迟阈值配置
class LatencyThresholds {
  static const Map<String, Duration> _defaultThresholds = {
    'api_request': Duration(seconds: 5),
    'cache_get': Duration(milliseconds: 100),
    'cache_put': Duration(milliseconds: 200),
    'data_processing': Duration(seconds: 1),
    'batch_processing': Duration(seconds: 10),
    'compression': Duration(seconds: 2),
    'decompression': Duration(seconds: 1),
    'validation': Duration(milliseconds: 500),
  };

  final Map<String, Duration> _customThresholds = {};

  Duration getThreshold(String operationType) {
    return _customThresholds[operationType] ??
        _defaultThresholds[operationType] ??
        const Duration(seconds: 1);
  }

  void setThreshold(String operationType, Duration threshold) {
    _customThresholds[operationType] = threshold;
  }
}

/// 性能数据收集器
class PerformanceDataCollector {
  final List<LatencyEvent> _latencyEvents = [];
  final List<ErrorEvent> _errorEvents = [];
  final Map<String, List<double>> _customMetrics = {};
  final List<CacheAccessEvent> _cacheEvents = [];
  final List<NetworkRequestEvent> _networkEvents = [];

  void recordLatency(LatencyEvent event) {
    _latencyEvents.add(event);
  }

  void recordError(ErrorEvent event) {
    _errorEvents.add(event);
  }

  void recordCustomMetric(String metricName, dynamic value,
      {Map<String, dynamic>? tags}) {
    _customMetrics.putIfAbsent(metricName, () => []).add(value.toDouble());
  }

  void recordCacheHit(String cacheType, String key, Duration accessTime) {
    _cacheEvents.add(CacheAccessEvent(
      cacheType: cacheType,
      key: key,
      accessTime: accessTime,
      hit: true,
      timestamp: DateTime.now(),
    ));
  }

  void recordCacheMiss(String cacheType, String key, Duration accessTime) {
    _cacheEvents.add(CacheAccessEvent(
      cacheType: cacheType,
      key: key,
      accessTime: accessTime,
      hit: false,
      timestamp: DateTime.now(),
    ));
  }

  void recordNetworkRequest(String url, Duration duration, int responseSize,
      {int statusCode = 200}) {
    _networkEvents.add(NetworkRequestEvent(
      url: url,
      duration: duration,
      responseSize: responseSize,
      statusCode: statusCode,
      timestamp: DateTime.now(),
    ));
  }

  Map<String, dynamic> getOperationMetrics({Duration? timeRange}) {
    final events = _filterEventsByTime(_latencyEvents, timeRange);

    if (events.isEmpty) {
      return {'totalOperations': 0};
    }

    final operationGroups = <String, List<LatencyEvent>>{};
    for (final event in events) {
      operationGroups.putIfAbsent(event.operationType, () => []).add(event);
    }

    final metrics = <String, dynamic>{};
    int totalOperations = 0;
    double totalLatency = 0.0;
    int successCount = 0;

    for (final entry in operationGroups.entries) {
      final operationEvents = entry.value;
      final latencies = operationEvents
          .where((e) => e.latency != null)
          .map((e) => e.latency!.inMilliseconds.toDouble())
          .toList();

      if (latencies.isEmpty) continue;

      totalOperations += operationEvents.length;
      totalLatency += latencies.reduce((a, b) => a + b);
      successCount += operationEvents.where((e) => e.success).length;

      latencies.sort();
      final avgLatency = latencies.reduce((a, b) => a + b) / latencies.length;
      final p50Latency = _getPercentile(latencies, 0.5);
      final p95Latency = _getPercentile(latencies, 0.95);
      final p99Latency = _getPercentile(latencies, 0.99);

      metrics[entry.key] = {
        'count': operationEvents.length,
        'successCount': successCount,
        'successRate': successCount / operationEvents.length,
        'averageLatency': avgLatency,
        'p50Latency': p50Latency,
        'p95Latency': p95Latency,
        'p99Latency': p99Latency,
        'minLatency': latencies.first,
        'maxLatency': latencies.last,
      };
    }

    metrics['totalOperations'] = totalOperations;
    metrics['overallAverageLatency'] =
        totalOperations > 0 ? totalLatency / totalOperations : 0.0;
    metrics['overallSuccessRate'] =
        totalOperations > 0 ? successCount / totalOperations : 0.0;

    return metrics;
  }

  Map<String, dynamic> getCacheMetrics({Duration? timeRange}) {
    final events = _filterEventsByTime(_cacheEvents, timeRange);

    if (events.isEmpty) {
      return {
        'totalAccesses': 0,
        'overallHitRate': 0.0,
      };
    }

    final totalAccesses = events.length;
    final hits = events.where((e) => e.hit).length;
    final overallHitRate = totalAccesses > 0 ? hits / totalAccesses : 0.0;

    final cacheGroups = <String, List<CacheAccessEvent>>{};
    for (final event in events) {
      cacheGroups.putIfAbsent(event.cacheType, () => []).add(event);
    }

    final metrics = <String, dynamic>{
      'totalAccesses': totalAccesses,
      'totalHits': hits,
      'totalMisses': totalAccesses - hits,
      'overallHitRate': overallHitRate,
    };

    for (final entry in cacheGroups.entries) {
      final cacheEvents = entry.value;
      final cacheHits = cacheEvents.where((e) => e.hit).length;
      final cacheHitRate =
          cacheEvents.isNotEmpty ? cacheHits / cacheEvents.length : 0.0;
      final avgAccessTime = cacheEvents
              .map((e) => e.accessTime.inMilliseconds.toDouble())
              .reduce((a, b) => a + b) /
          cacheEvents.length;

      metrics[entry.key] = {
        'accesses': cacheEvents.length,
        'hits': cacheHits,
        'misses': cacheEvents.length - cacheHits,
        'hitRate': cacheHitRate,
        'averageAccessTime': avgAccessTime,
      };
    }

    return metrics;
  }

  Map<String, dynamic> getNetworkMetrics({Duration? timeRange}) {
    final events = _filterEventsByTime(_networkEvents, timeRange);

    if (events.isEmpty) {
      return {
        'totalRequests': 0,
        'averageResponseTime': 0.0,
      };
    }

    final totalRequests = events.length;
    final responseTimes =
        events.map((e) => e.duration.inMilliseconds.toDouble()).toList();
    final totalResponseSize =
        events.fold<int>(0, (sum, e) => sum + e.responseSize);
    final successRequests =
        events.where((e) => e.statusCode >= 200 && e.statusCode < 300).length;

    responseTimes.sort();

    return {
      'totalRequests': totalRequests,
      'successRequests': successRequests,
      'successRate': totalRequests > 0 ? successRequests / totalRequests : 0.0,
      'averageResponseTime':
          responseTimes.reduce((a, b) => a + b) / responseTimes.length,
      'p50ResponseTime': _getPercentile(responseTimes, 0.5),
      'p95ResponseTime': _getPercentile(responseTimes, 0.95),
      'p99ResponseTime': _getPercentile(responseTimes, 0.99),
      'totalDataTransferred': totalResponseSize,
      'averageDataSize':
          totalRequests > 0 ? totalResponseSize / totalRequests : 0.0,
    };
  }

  Map<String, dynamic> getErrorMetrics({Duration? timeRange}) {
    final events = _filterEventsByTime(_errorEvents, timeRange);

    if (events.isEmpty) {
      return {
        'totalErrors': 0,
        'totalOperations': 0,
        'errorRate': 0.0,
      };
    }

    final errorGroups = <String, List<ErrorEvent>>{};
    for (final event in events) {
      errorGroups.putIfAbsent(event.operationType, () => []).add(event);
    }

    final metrics = <String, dynamic>{
      'totalErrors': events.length,
      'totalOperations': events.length, // 这里简化处理，实际应该与总操作数比较
      'errorRate': 0.0, // 需要外部提供总操作数
    };

    for (final entry in errorGroups.entries) {
      metrics[entry.key] = {
        'count': entry.value.length,
        'errors': entry.value.map((e) => e.error).toList(),
      };
    }

    return metrics;
  }

  void cleanupOldData({Duration? maxAge}) {
    final effectiveMaxAge = maxAge ?? const Duration(days: 7);
    final cutoffTime = DateTime.now().subtract(effectiveMaxAge);

    _latencyEvents.removeWhere((event) => event.startTime.isBefore(cutoffTime));
    _errorEvents.removeWhere((event) => event.timestamp.isBefore(cutoffTime));
    _cacheEvents.removeWhere((event) => event.timestamp.isBefore(cutoffTime));
    _networkEvents.removeWhere((event) => event.timestamp.isBefore(cutoffTime));
  }

  Map<String, dynamic> exportData({Duration? timeRange}) {
    return {
      'latencyEvents': _filterEventsByTime(_latencyEvents, timeRange)
          .map((e) => e.toJson())
          .toList(),
      'errorEvents': _filterEventsByTime(_errorEvents, timeRange)
          .map((e) => e.toJson())
          .toList(),
      'customMetrics': _customMetrics,
    };
  }

  List<T> _filterEventsByTime<T>(List<T> events, Duration? timeRange) {
    if (timeRange == null) return events;

    final cutoffTime = DateTime.now().subtract(timeRange);
    return events
        .where((event) {
          if (event is LatencyEvent) {
            return event.startTime.isAfter(cutoffTime);
          } else if (event is ErrorEvent) {
            return event.timestamp.isAfter(cutoffTime);
          } else if (event is CacheAccessEvent) {
            return event.timestamp.isAfter(cutoffTime);
          } else if (event is NetworkRequestEvent) {
            return event.timestamp.isAfter(cutoffTime);
          }
          return true;
        })
        .cast<T>()
        .toList();
  }

  double _getPercentile(List<double> sortedValues, double percentile) {
    if (sortedValues.isEmpty) return 0.0;

    final index = (sortedValues.length - 1) * percentile;
    final lower = index.floor();
    final upper = index.ceil();

    if (lower == upper) {
      return sortedValues[lower];
    }

    final weight = index - lower;
    return sortedValues[lower] * (1 - weight) + sortedValues[upper] * weight;
  }
}

/// 缓存访问事件
class CacheAccessEvent {
  final String cacheType;
  final String key;
  final Duration accessTime;
  final bool hit;
  final DateTime timestamp;

  CacheAccessEvent({
    required this.cacheType,
    required this.key,
    required this.accessTime,
    required this.hit,
    required this.timestamp,
  });
}

/// 网络请求事件
class NetworkRequestEvent {
  final String url;
  final Duration duration;
  final int responseSize;
  final int statusCode;
  final DateTime timestamp;

  NetworkRequestEvent({
    required this.url,
    required this.duration,
    required this.responseSize,
    required this.statusCode,
    required this.timestamp,
  });
}

/// 异常检测器
class AnomalyDetector {
  final List<PerformanceAnomaly> _anomalies = [];

  void checkLatencyAnomaly(LatencyEvent event) {
    if (event.latency == null) return;

    final latency = event.latency!.inMilliseconds;

    // 简单的异常检测：如果延迟超过平均值的3倍
    // 这里可以实现更复杂的算法

    if (latency > 10000) {
      // 10秒阈值
      _anomalies.add(PerformanceAnomaly(
        type: AnomalyType.highLatency,
        operationType: event.operationType,
        value: latency.toDouble(),
        threshold: 10000.0,
        timestamp: DateTime.now(),
        description: '操作延迟异常: ${event.operationType} - ${latency}ms',
      ));
    }
  }

  List<PerformanceAnomaly> getAnomalies({Duration? timeRange}) {
    if (timeRange == null) return List.from(_anomalies);

    final cutoffTime = DateTime.now().subtract(timeRange);
    return _anomalies.where((a) => a.timestamp.isAfter(cutoffTime)).toList();
  }

  // ignore: public_member_api_docs
  Map<String, dynamic> getAnomalySummary() {
    final recentAnomalies = getAnomalies(timeRange: const Duration(days: 1));

    return {
      'totalAnomalies': _anomalies.length,
      'recentAnomalies': recentAnomalies.length,
      'byType': _groupAnomaliesByType(recentAnomalies),
      'byOperation': _groupAnomaliesByOperation(recentAnomalies),
    };
  }

  // ignore: public_member_api_docs
  void cleanupOldData({Duration? maxAge}) {
    final effectiveMaxAge = maxAge ?? const Duration(days: 7);
    final cutoffTime = DateTime.now().subtract(effectiveMaxAge);

    _anomalies.removeWhere((anomaly) => anomaly.timestamp.isBefore(cutoffTime));
  }

  Map<String, dynamic> exportData({Duration? timeRange}) {
    return {
      'anomalies':
          getAnomalies(timeRange: timeRange).map((a) => a.toJson()).toList(),
    };
  }

  Map<String, int> _groupAnomaliesByType(List<PerformanceAnomaly> anomalies) {
    final groups = <String, int>{};
    for (final anomaly in anomalies) {
      groups[anomaly.type.name] = (groups[anomaly.type.name] ?? 0) + 1;
    }
    return groups;
  }

  Map<String, int> _groupAnomaliesByOperation(
      List<PerformanceAnomaly> anomalies) {
    final groups = <String, int>{};
    for (final anomaly in anomalies) {
      groups[anomaly.operationType] = (groups[anomaly.operationType] ?? 0) + 1;
    }
    return groups;
  }
}

/// 性能异常
class PerformanceAnomaly {
  final AnomalyType type;
  final String operationType;
  final double value;
  final double threshold;
  final DateTime timestamp;
  final String description;

  PerformanceAnomaly({
    required this.type,
    required this.operationType,
    required this.value,
    required this.threshold,
    required this.timestamp,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'operationType': operationType,
      'value': value,
      'threshold': threshold,
      'timestamp': timestamp.toIso8601String(),
      'description': description,
    };
  }
}

/// 异常类型
enum AnomalyType {
  highLatency,
  errorRate,
  lowCacheHitRate,
  networkIssue,
}

/// 延迟分布统计
class LatencyDistribution {
  final String operationType;
  final int sampleCount;
  final double minLatency;
  final double maxLatency;
  final double meanLatency;
  final double medianLatency;
  final double p95Latency;
  final double p99Latency;
  final double standardDeviation;

  LatencyDistribution({
    required this.operationType,
    this.sampleCount = 0,
    this.minLatency = 0.0,
    this.maxLatency = 0.0,
    this.meanLatency = 0.0,
    this.medianLatency = 0.0,
    this.p95Latency = 0.0,
    this.p99Latency = 0.0,
    this.standardDeviation = 0.0,
  });

  factory LatencyDistribution.fromLatencies(
      String operationType, List<Duration> latencies) {
    if (latencies.isEmpty) {
      return LatencyDistribution(operationType: operationType);
    }

    final values = latencies.map((d) => d.inMilliseconds.toDouble()).toList();
    values.sort();

    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance =
        values.map((v) => math.pow(v - mean, 2)).reduce((a, b) => a + b) /
            values.length;
    final stdDev = math.sqrt(variance);

    return LatencyDistribution(
      operationType: operationType,
      sampleCount: values.length,
      minLatency: values.first,
      maxLatency: values.last,
      meanLatency: mean,
      medianLatency: _getPercentile(values, 0.5),
      p95Latency: _getPercentile(values, 0.95),
      p99Latency: _getPercentile(values, 0.99),
      standardDeviation: stdDev,
    );
  }

  static double _getPercentile(List<double> sortedValues, double percentile) {
    if (sortedValues.isEmpty) return 0.0;

    final index = (sortedValues.length - 1) * percentile;
    final lower = index.floor();
    final upper = index.ceil();

    if (lower == upper) {
      return sortedValues[lower];
    }

    final weight = index - lower;
    return sortedValues[lower] * (1 - weight) + sortedValues[upper] * weight;
  }

  Map<String, dynamic> toJson() {
    return {
      'operationType': operationType,
      'sampleCount': sampleCount,
      'minLatency': minLatency,
      'maxLatency': maxLatency,
      'meanLatency': meanLatency,
      'medianLatency': medianLatency,
      'p95Latency': p95Latency,
      'p99Latency': p99Latency,
      'standardDeviation': standardDeviation,
    };
  }
}

/// 性能报告
class PerformanceReport {
  final Duration timeRange;
  final Map<String, dynamic> operationMetrics;
  final Map<String, dynamic> cacheMetrics;
  final Map<String, dynamic> networkMetrics;
  final Map<String, dynamic> errorMetrics;
  final List<PerformanceAnomaly> anomalies;
  final List<String> recommendations;
  final DateTime generatedAt;

  PerformanceReport({
    required this.timeRange,
    required this.operationMetrics,
    required this.cacheMetrics,
    required this.networkMetrics,
    required this.errorMetrics,
    required this.anomalies,
    required this.recommendations,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'timeRangeHours': timeRange.inHours,
      'operationMetrics': operationMetrics,
      'cacheMetrics': cacheMetrics,
      'networkMetrics': networkMetrics,
      'errorMetrics': errorMetrics,
      'anomalies': anomalies.map((a) => a.toJson()).toList(),
      'recommendations': recommendations,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }
}
