import 'dart:async';
import 'dart:collection';

import '../utils/logger.dart';
import 'unified_hive_cache_manager.dart';

/// 缓存性能指标
class CachePerformanceMetrics {
  /// 缓存命中率
  final double hitRate;

  /// 平均响应时间（毫秒）
  final double averageResponseTime;

  /// 每秒请求数
  final double requestsPerSecond;

  /// 缓存大小
  final int cacheSize;

  /// 内存使用量（字节）
  final int memoryUsage;

  /// 错误率
  final double errorRate;

  /// 时间窗口内总请求数
  final int totalRequests;

  /// 时间窗口内命中数
  final int totalHits;

  /// 时间窗口内未命中数
  final int totalMisses;

  /// 时间窗口内错误数
  final int totalErrors;

  const CachePerformanceMetrics({
    required this.hitRate,
    required this.averageResponseTime,
    required this.requestsPerSecond,
    required this.cacheSize,
    required this.memoryUsage,
    required this.errorRate,
    required this.totalRequests,
    required this.totalHits,
    required this.totalMisses,
    required this.totalErrors,
  });

  @override
  String toString() {
    return 'CachePerformanceMetrics('
        'hitRate: ${(hitRate * 100).toStringAsFixed(1)}%, '
        'avgResponseTime: ${averageResponseTime.toStringAsFixed(2)}ms, '
        'rps: ${requestsPerSecond.toStringAsFixed(1)}, '
        'cacheSize: $cacheSize, '
        'memoryUsage: ${(memoryUsage / 1024 / 1024).toStringAsFixed(1)}MB, '
        'errorRate: ${(errorRate * 100).toStringAsFixed(1)}%'
        ')';
  }
}

/// 缓存操作类型
enum CacheOperationType {
  read,
  write,
  delete,
  clear,
  search,
}

/// 缓存操作记录
class CacheOperationRecord {
  /// 操作类型
  final CacheOperationType operationType;

  /// 缓存键
  final String key;

  /// 操作开始时间
  final DateTime startTime;

  /// 操作结束时间
  final DateTime endTime;

  /// 操作是否成功
  final bool success;

  /// 操作结果大小（字节）
  final int? resultSize;

  /// 错误信息（如果失败）
  final String? errorMessage;

  /// 缓存层（L1/L2）
  final String? cacheLayer;

  /// 附加元数据
  final Map<String, dynamic>? metadata;

  const CacheOperationRecord({
    required this.operationType,
    required this.key,
    required this.startTime,
    required this.endTime,
    required this.success,
    this.resultSize,
    this.errorMessage,
    this.cacheLayer,
    this.metadata,
  });

  /// 获取操作耗时
  Duration get duration => endTime.difference(startTime);

  /// 获取操作耗时（毫秒）
  double get durationMs => duration.inMilliseconds.toDouble();

  @override
  String toString() {
    return 'CacheOperationRecord('
        'operation: $operationType, '
        'key: $key, '
        'duration: ${durationMs.toStringAsFixed(2)}ms, '
        'success: $success, '
        'layer: $cacheLayer'
        ')';
  }
}

/// 缓存性能监控器
///
/// 提供全面的缓存性能监控功能：
/// - 实时性能指标收集
/// - 操作历史记录
/// - 性能趋势分析
/// - 异常检测和告警
/// - 性能报告生成
/// - 自定义指标收集
class CachePerformanceMonitor {
  static CachePerformanceMonitor? _instance;
  static CachePerformanceMonitor get instance {
    _instance ??= CachePerformanceMonitor._();
    return _instance!;
  }

  CachePerformanceMonitor._() {
    _initialize();
  }

  // 核心组件（延迟初始化避免循环依赖）
  UnifiedHiveCacheManager? _cacheManager;

  // 操作记录存储
  final List<CacheOperationRecord> _operationHistory = [];
  final Queue<CacheOperationRecord> _recentOperations = Queue();

  // 统计数据
  final Map<CacheOperationType, int> _operationCounts = {};
  final Map<CacheOperationType, int> _operationSuccessCounts = {};
  final Map<CacheOperationType, double> _operationTotalTimes = {};
  final Map<String, int> _cacheKeyAccessCounts = {};

  // 性能告警配置
  double _hitRateWarningThreshold = 0.7; // 70%
  double _responseTimeWarningThreshold = 100.0; // 100ms
  double _errorRateWarningThreshold = 0.05; // 5%
  int _maxHistorySize = 10000;
  final int _maxRecentSize = 1000;

  // 定时器和调度
  Timer? _reportingTimer;
  Timer? _cleanupTimer;

  // 监控状态
  bool _isMonitoring = false;
  DateTime _lastReportTime = DateTime.now();

  // 监听器
  final List<Function(CachePerformanceMetrics)> _performanceListeners = [];

  /// 初始化监控器
  Future<void> initialize({
    Duration? reportingInterval,
    Duration? cleanupInterval,
    double? hitRateWarningThreshold,
    double? responseTimeWarningThreshold,
    double? errorRateWarningThreshold,
    int? maxHistorySize,
  }) async {
    if (_isMonitoring) return;

    _hitRateWarningThreshold =
        hitRateWarningThreshold ?? _hitRateWarningThreshold;
    _responseTimeWarningThreshold =
        responseTimeWarningThreshold ?? _responseTimeWarningThreshold;
    _errorRateWarningThreshold =
        errorRateWarningThreshold ?? _errorRateWarningThreshold;
    _maxHistorySize = maxHistorySize ?? _maxHistorySize;

    // 启动定时器
    _startReportingTimer(reportingInterval ?? const Duration(minutes: 1));
    _startCleanupTimer(cleanupInterval ?? const Duration(minutes: 10));

    _isMonitoring = true;
    AppLogger.info('📊 CachePerformanceMonitor 已启动');
  }

  /// 记录缓存操作
  void recordOperation(CacheOperationRecord record) {
    if (!_isMonitoring) return;

    // 添加到历史记录
    _operationHistory.add(record);
    _recentOperations.add(record);

    // 更新统计数据
    _updateStatistics(record);

    // 检查大小限制
    _enforceSizeLimits();

    // 记录访问次数
    _cacheKeyAccessCounts[record.key] =
        (_cacheKeyAccessCounts[record.key] ?? 0) + 1;

    // 检查性能告警
    _checkPerformanceAlerts(record);

    AppLogger.debug(
        '📊 记录缓存操作: ${record.operationType} ${record.key} (${record.durationMs.toStringAsFixed(2)}ms)');
  }

  /// 开始记录缓存操作
  CacheOperationTimer startOperation(
    CacheOperationType operationType,
    String key, {
    String? cacheLayer,
    Map<String, dynamic>? metadata,
  }) {
    return CacheOperationTimer(
      operationType: operationType,
      key: key,
      cacheLayer: cacheLayer,
      metadata: metadata,
      onComplete: (record) => recordOperation(record),
    );
  }

  /// 获取当前性能指标
  CachePerformanceMetrics getCurrentMetrics() {
    if (_recentOperations.isEmpty) {
      return const CachePerformanceMetrics(
        hitRate: 0.0,
        averageResponseTime: 0.0,
        requestsPerSecond: 0.0,
        cacheSize: 0,
        memoryUsage: 0,
        errorRate: 0.0,
        totalRequests: 0,
        totalHits: 0,
        totalMisses: 0,
        totalErrors: 0,
      );
    }

    final now = DateTime.now();
    final oneMinuteAgo = now.subtract(const Duration(minutes: 1));
    final recentOperations = _recentOperations
        .where((op) => op.startTime.isAfter(oneMinuteAgo))
        .toList();

    if (recentOperations.isEmpty) {
      return const CachePerformanceMetrics(
        hitRate: 0.0,
        averageResponseTime: 0.0,
        requestsPerSecond: 0.0,
        cacheSize: 0,
        memoryUsage: 0,
        errorRate: 0.0,
        totalRequests: 0,
        totalHits: 0,
        totalMisses: 0,
        totalErrors: 0,
      );
    }

    // 计算基础指标
    final totalRequests = recentOperations.length;
    final successfulRequests =
        recentOperations.where((op) => op.success).length;
    final failedRequests = totalRequests - successfulRequests;

    // 计算缓存命中情况
    final readOperations = recentOperations
        .where((op) => op.operationType == CacheOperationType.read)
        .toList();
    final hits = readOperations.where((op) => op.cacheLayer != null).length;
    final misses = readOperations.length - hits;

    // 计算平均响应时间
    final totalTime =
        recentOperations.fold<double>(0.0, (sum, op) => sum + op.durationMs);
    final averageResponseTime =
        totalRequests > 0 ? totalTime / totalRequests : 0.0;

    // 计算每秒请求数
    final timeSpan = recentOperations.last.startTime
        .difference(recentOperations.first.startTime)
        .inSeconds;
    final requestsPerSecond = timeSpan > 0 ? totalRequests / timeSpan : 0.0;

    // 获取缓存统计信息
    _cacheManager ??= UnifiedHiveCacheManager.instance;
    final cacheStats = _cacheManager?.getStatsSync() ?? {'total_items': 0};
    final cacheSize = cacheStats['total_items'] ?? 0;

    // 估算内存使用量（简化计算）
    final memoryUsage = _estimateMemoryUsage();

    return CachePerformanceMetrics(
      hitRate: readOperations.isNotEmpty ? hits / readOperations.length : 0.0,
      averageResponseTime: averageResponseTime,
      requestsPerSecond: requestsPerSecond,
      cacheSize: cacheSize,
      memoryUsage: memoryUsage,
      errorRate: totalRequests > 0 ? failedRequests / totalRequests : 0.0,
      totalRequests: totalRequests,
      totalHits: hits,
      totalMisses: misses,
      totalErrors: failedRequests,
    );
  }

  /// 获取热门缓存键
  List<MapEntry<String, int>> getHotCacheKeys({int limit = 10}) {
    final sortedEntries = _cacheKeyAccessCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedEntries.take(limit).toList();
  }

  /// 获取慢操作记录
  List<CacheOperationRecord> getSlowOperations(
      {Duration threshold = const Duration(milliseconds: 100),
      int limit = 10}) {
    final slowOperations = _operationHistory
        .where((op) => op.duration > threshold)
        .toList()
      ..sort((a, b) => b.duration.compareTo(a.duration));
    return slowOperations.take(limit).toList();
  }

  /// 获取失败操作记录
  List<CacheOperationRecord> getFailedOperations({int limit = 10}) {
    final failedOperations = _operationHistory
        .where((op) => !op.success)
        .toList()
      ..sort((a, b) => b.endTime.compareTo(a.endTime));
    return failedOperations.take(limit).toList();
  }

  /// 生成性能报告
  Map<String, dynamic> generatePerformanceReport() {
    final currentMetrics = getCurrentMetrics();
    final hotKeys = getHotCacheKeys();
    final slowOps = getSlowOperations();
    final failedOps = getFailedOperations();

    // 计算操作分布
    final operationDistribution = <String, int>{};
    for (final entry in _operationCounts.entries) {
      operationDistribution[entry.key.toString()] = entry.value;
    }

    // 计算成功率
    int totalOps = _operationCounts.values.fold(0, (sum, count) => sum + count);
    int successfulOps =
        _operationSuccessCounts.values.fold(0, (sum, count) => sum + count);
    double overallSuccessRate = totalOps > 0 ? successfulOps / totalOps : 0.0;

    return {
      'report_time': DateTime.now().toIso8601String(),
      'current_metrics': {
        'hit_rate': currentMetrics.hitRate,
        'average_response_time': currentMetrics.averageResponseTime,
        'requests_per_second': currentMetrics.requestsPerSecond,
        'cache_size': currentMetrics.cacheSize,
        'memory_usage_mb':
            (currentMetrics.memoryUsage / 1024 / 1024).toStringAsFixed(2),
        'error_rate': currentMetrics.errorRate,
        'total_requests': currentMetrics.totalRequests,
      },
      'performance_health': {
        'hit_rate_status':
            _getHealthStatus(currentMetrics.hitRate, _hitRateWarningThreshold),
        'response_time_status': _getHealthStatus(
            -currentMetrics.averageResponseTime,
            -_responseTimeWarningThreshold),
        'error_rate_status': _getHealthStatus(
            -currentMetrics.errorRate, -_errorRateWarningThreshold),
        'overall_success_rate': overallSuccessRate,
      },
      'operation_distribution': operationDistribution,
      'hot_cache_keys':
          hotKeys.map((e) => {'key': e.key, 'access_count': e.value}).toList(),
      'slow_operations':
          slowOps.map((op) => _operationRecordToJson(op)).take(5).toList(),
      'failed_operations':
          failedOps.map((op) => _operationRecordToJson(op)).take(5).toList(),
      'monitoring_info': {
        'is_monitoring': _isMonitoring,
        'total_records': _operationHistory.length,
        'recent_records': _recentOperations.length,
        'last_report_time': _lastReportTime.toIso8601String(),
      },
    };
  }

  /// 添加性能监听器
  void addPerformanceListener(Function(CachePerformanceMetrics) listener) {
    _performanceListeners.add(listener);
  }

  /// 移除性能监听器
  void removePerformanceListener(Function(CachePerformanceMetrics) listener) {
    _performanceListeners.remove(listener);
  }

  /// 重置统计信息
  void resetStatistics() {
    _operationHistory.clear();
    _recentOperations.clear();
    _operationCounts.clear();
    _operationSuccessCounts.clear();
    _operationTotalTimes.clear();
    _cacheKeyAccessCounts.clear();
    _lastReportTime = DateTime.now();

    AppLogger.info('📊 缓存性能统计信息已重置');
  }

  /// 停止监控
  Future<void> stop() async {
    _reportingTimer?.cancel();
    _cleanupTimer?.cancel();
    _isMonitoring = false;

    AppLogger.info('📊 CachePerformanceMonitor 已停止');
  }

  /// 销毁监控器
  Future<void> dispose() async {
    await stop();
    _performanceListeners.clear();
    _operationHistory.clear();
    _recentOperations.clear();

    AppLogger.info('📊 CachePerformanceMonitor 已销毁');
  }

  // 私有方法

  void _initialize() {
    AppLogger.debug('📊 初始化 CachePerformanceMonitor');
  }

  void _updateStatistics(CacheOperationRecord record) {
    final operationType = record.operationType;

    // 更新操作计数
    _operationCounts[operationType] =
        (_operationCounts[operationType] ?? 0) + 1;

    // 更新成功计数
    if (record.success) {
      _operationSuccessCounts[operationType] =
          (_operationSuccessCounts[operationType] ?? 0) + 1;
    }

    // 更新总耗时
    _operationTotalTimes[operationType] =
        (_operationTotalTimes[operationType] ?? 0.0) + record.durationMs;
  }

  void _enforceSizeLimits() {
    // 限制历史记录大小
    if (_operationHistory.length > _maxHistorySize) {
      final excess = _operationHistory.length - _maxHistorySize;
      _operationHistory.removeRange(0, excess);
    }

    // 限制最近记录大小
    if (_recentOperations.length > _maxRecentSize) {
      while (_recentOperations.length > _maxRecentSize) {
        _recentOperations.removeFirst();
      }
    }
  }

  void _checkPerformanceAlerts(CacheOperationRecord record) {
    // 检查响应时间告警
    if (record.durationMs > _responseTimeWarningThreshold) {
      AppLogger.warn(
          '⚠️ 缓存操作响应时间过慢: ${record.key} (${record.durationMs.toStringAsFixed(2)}ms)');
    }

    // 检查错误告警
    if (!record.success) {
      AppLogger.warn('⚠️ 缓存操作失败: ${record.key} - ${record.errorMessage}');
    }
  }

  void _startReportingTimer(Duration interval) {
    _reportingTimer = Timer.periodic(interval, (_) {
      try {
        final metrics = getCurrentMetrics();
        _notifyPerformanceListeners(metrics);
        _lastReportTime = DateTime.now();
      } catch (e) {
        AppLogger.error('❌ 生成性能报告失败', e);
      }
    });
  }

  void _startCleanupTimer(Duration interval) {
    _cleanupTimer = Timer.periodic(interval, (_) {
      try {
        _cleanupOldRecords();
        AppLogger.debug('🧹 缓存性能监控清理完成');
      } catch (e) {
        AppLogger.error('❌ 清理缓存性能记录失败', e);
      }
    });
  }

  void _cleanupOldRecords() {
    final cutoffTime = DateTime.now().subtract(const Duration(hours: 1));
    _operationHistory
        .removeWhere((record) => record.startTime.isBefore(cutoffTime));
  }

  void _notifyPerformanceListeners(CachePerformanceMetrics metrics) {
    for (final listener in _performanceListeners) {
      try {
        listener(metrics);
      } catch (e) {
        AppLogger.debug('性能监听器回调失败: $e');
      }
    }
  }

  int _estimateMemoryUsage() {
    // 简化的内存使用估算
    // 实际应用中可以使用更精确的内存监控方法
    return _operationHistory.length * 200 +
        _recentOperations.length * 200; // 每条记录约200字节
  }

  String _getHealthStatus(double value, double threshold) {
    if (value >= threshold) {
      return 'good';
    } else if (value >= threshold * 0.8) {
      return 'warning';
    } else {
      return 'poor';
    }
  }

  Map<String, dynamic> _operationRecordToJson(CacheOperationRecord record) {
    return {
      'operation_type': record.operationType.toString(),
      'key': record.key,
      'start_time': record.startTime.toIso8601String(),
      'duration_ms': record.durationMs,
      'success': record.success,
      'cache_layer': record.cacheLayer,
      'error_message': record.errorMessage,
    };
  }
}

/// 缓存操作计时器
class CacheOperationTimer {
  final CacheOperationType operationType;
  final String key;
  final String? cacheLayer;
  final Map<String, dynamic>? metadata;
  final Function(CacheOperationRecord) onComplete;

  final Stopwatch _stopwatch = Stopwatch();
  bool _completed = false;

  CacheOperationTimer({
    required this.operationType,
    required this.key,
    this.cacheLayer,
    this.metadata,
    required this.onComplete,
  });

  /// 开始计时
  void start() {
    if (!_completed) {
      _stopwatch.start();
    }
  }

  /// 完成操作并记录
  void complete({
    bool success = true,
    String? errorMessage,
    int? resultSize,
    Map<String, dynamic>? additionalMetadata,
  }) {
    if (_completed) return;

    _stopwatch.stop();
    _completed = true;

    final record = CacheOperationRecord(
      operationType: operationType,
      key: key,
      startTime: DateTime.now().subtract(_stopwatch.elapsed),
      endTime: DateTime.now(),
      success: success,
      resultSize: resultSize,
      errorMessage: errorMessage,
      cacheLayer: cacheLayer,
      metadata: {
        ...?metadata,
        ...?additionalMetadata,
      },
    );

    onComplete(record);
  }

  /// 获取已过时间
  Duration get elapsed => _stopwatch.elapsed;
}

/// 缓存性能监控辅助类
class CachePerformanceHelper {
  static final CachePerformanceMonitor _monitor =
      CachePerformanceMonitor.instance;

  /// 执行缓存操作并自动记录性能
  static T executeWithMonitoring<T>(
    CacheOperationType operationType,
    String key,
    T Function() operation, {
    String? cacheLayer,
    Map<String, dynamic>? metadata,
  }) {
    final timer = _monitor.startOperation(operationType, key,
        cacheLayer: cacheLayer, metadata: metadata);
    timer.start();

    try {
      final result = operation();
      timer.complete(success: true);
      return result;
    } catch (e, stackTrace) {
      timer.complete(
        success: false,
        errorMessage: e.toString(),
        additionalMetadata: {'stack_trace': stackTrace.toString()},
      );
      rethrow;
    }
  }

  /// 异步执行缓存操作并自动记录性能
  static Future<T> executeWithMonitoringAsync<T>(
    CacheOperationType operationType,
    String key,
    Future<T> Function() operation, {
    String? cacheLayer,
    Map<String, dynamic>? metadata,
  }) async {
    final timer = _monitor.startOperation(operationType, key,
        cacheLayer: cacheLayer, metadata: metadata);
    timer.start();

    try {
      final result = await operation();
      timer.complete(success: true);
      return result;
    } catch (e, stackTrace) {
      timer.complete(
        success: false,
        errorMessage: e.toString(),
        additionalMetadata: {'stack_trace': stackTrace.toString()},
      );
      rethrow;
    }
  }
}
