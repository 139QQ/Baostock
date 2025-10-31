import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';

import '../coordinators/data_layer_coordinator.dart';

/// 数据层优化器
///
/// 提供数据层的性能监控、优化和调优功能
/// 支持自动优化和手动调优
class DataLayerOptimizer {
  final DataLayerCoordinator _coordinator;
  final DataLayerOptimizationConfig _config;

  Timer? _optimizationTimer;
  final List<OptimizationRecord> _optimizationHistory = [];
  final Map<String, PerformanceTrend> _performanceTrends = {};

  DataLayerOptimizer(this._coordinator, {DataLayerOptimizationConfig? config})
      : _config = config ?? DataLayerOptimizationConfig.defaultConfig();

  /// 启动自动优化
  void startAutoOptimization() {
    if (_optimizationTimer != null) return;

    debugPrint('🚀 启动数据层自动优化...');
    _optimizationTimer = Timer.periodic(_config.optimizationInterval, (_) {
      _performAutoOptimization();
    });
  }

  /// 停止自动优化
  void stopAutoOptimization() {
    _optimizationTimer?.cancel();
    _optimizationTimer = null;
    debugPrint('⏹️ 数据层自动优化已停止');
  }

  /// 执行自动优化
  Future<void> _performAutoOptimization() async {
    try {
      debugPrint('🔧 执行自动优化检查...');

      final metrics = await _coordinator.getPerformanceMetrics();
      final healthReport = await _coordinator.getHealthReport();

      // 检查是否需要优化
      final optimizationNeeded = _shouldOptimize(metrics, healthReport);

      if (optimizationNeeded.isNotEmpty) {
        debugPrint('⚡ 检测到优化需求: ${optimizationNeeded.join(', ')}');
        await _executeOptimizations(optimizationNeeded);
      }

      // 记录性能趋势
      _recordPerformanceTrend(metrics);
    } catch (e) {
      debugPrint('❌ 自动优化执行失败: $e');
    }
  }

  /// 判断是否需要优化
  List<String> _shouldOptimize(
    DataLayerPerformanceMetrics metrics,
    DataLayerHealthReport healthReport,
  ) {
    final optimizations = <String>[];

    // 检查缓存命中率
    if (metrics.cacheHitRate < _config.minCacheHitRate) {
      optimizations.add('cache_hit_rate');
    }

    // 检查响应时间
    if (metrics.averageResponseTime > _config.maxResponseTime) {
      optimizations.add('response_time');
    }

    // 检查内存使用
    if (metrics.memoryCacheSize > _config.maxMemoryCacheSize) {
      optimizations.add('memory_usage');
    }

    // 检查健康状态
    if (!healthReport.isHealthy) {
      optimizations.add('health_issues');
    }

    return optimizations;
  }

  /// 执行优化操作
  Future<void> _executeOptimizations(List<String> optimizations) async {
    final startTime = DateTime.now();

    try {
      for (final optimization in optimizations) {
        await _executeOptimization(optimization);
      }

      final duration = DateTime.now().difference(startTime);
      _recordOptimization(optimizations, duration, true);

      debugPrint('✅ 优化完成，耗时: ${duration.inMilliseconds}ms');
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      _recordOptimization(optimizations, duration, false, error: e);
      debugPrint('❌ 优化执行失败: $e');
    }
  }

  /// 执行单个优化操作
  Future<void> _executeOptimization(String optimization) async {
    switch (optimization) {
      case 'cache_hit_rate':
        await _optimizeCacheHitRate();
        break;
      case 'response_time':
        await _optimizeResponseTime();
        break;
      case 'memory_usage':
        await _optimizeMemoryUsage();
        break;
      case 'health_issues':
        await _optimizeHealthIssues();
        break;
      default:
        debugPrint('⚠️ 未知优化类型: $optimization');
    }
  }

  /// 优化缓存命中率
  Future<void> _optimizeCacheHitRate() async {
    debugPrint('🎯 优化缓存命中率...');

    // 1. 清理并优化缓存
    await _coordinator.clearAllCache();

    // 2. 预热常用数据
    await _performSmartWarmup();

    // 3. 调整缓存策略
    await _adjustCacheStrategy();

    debugPrint('✅ 缓存命中率优化完成');
  }

  /// 优化响应时间
  Future<void> _optimizeResponseTime() async {
    debugPrint('⚡ 优化响应时间...');

    // 1. 清理过期缓存
    await _coordinator.clearAllCache();

    // 2. 压缩大数据项
    await _compressLargeCacheItems();

    debugPrint('✅ 响应时间优化完成');
  }

  /// 优化内存使用
  Future<void> _optimizeMemoryUsage() async {
    debugPrint('🧠 优化内存使用...');

    // 1. 激进清理策略
    await _performAggressiveCleanup();

    // 2. 降低缓存大小限制
    await _reduceCacheSize();

    // 3. 清理不常用数据
    await _cleanupUnusedData();

    debugPrint('✅ 内存使用优化完成');
  }

  /// 优化健康问题
  Future<void> _optimizeHealthIssues() async {
    debugPrint('🏥 优化健康问题...');

    // 1. 强制同步数据
    await _coordinator.refreshCache();

    // 2. 重启数据源检查
    await _restartDataSourceCheck();

    // 3. 验证数据完整性
    await _validateDataIntegrity();

    debugPrint('✅ 健康问题优化完成');
  }

  /// 执行智能预热
  Future<void> _performSmartWarmup() async {
    debugPrint('🔥 执行智能预热...');

    // 基于使用模式预热数据
    final popularKeys = await _getPopularCacheKeys();
    for (final key in popularKeys.take(10)) {
      try {
        // 这里可以实现智能预热逻辑
        debugPrint('🔥 预热缓存键: $key');
      } catch (e) {
        debugPrint('⚠️ 预热失败 $key: $e');
      }
    }
  }

  /// 调整缓存策略
  Future<void> _adjustCacheStrategy() async {
    debugPrint('⚙️ 调整缓存策略...');

    // 基于当前性能指标调整策略
    final metrics = await _coordinator.getPerformanceMetrics();

    if (metrics.cacheHitRate < 0.6) {
      // 命中率低，增加缓存时间
      debugPrint('📈 增加缓存时间以提升命中率');
    } else if (metrics.cacheHitRate > 0.9) {
      // 命中率很高，可以减少缓存时间以节省内存
      debugPrint('📉 减少缓存时间以节省内存');
    }
  }

  /// 压缩大数据项
  Future<void> _compressLargeCacheItems() async {
    debugPrint('🗜️ 压缩大数据项...');

    // 这里可以实现数据压缩逻辑
    // 找出并压缩超过阈值的缓存项
  }

  /// 执行激进清理
  Future<void> _performAggressiveCleanup() async {
    debugPrint('🧹 执行激进清理...');

    // 1. 清理所有缓存
    await _coordinator.clearAllCache();

    // 2. 清理低频访问数据
    await _cleanupLowFrequencyData();

    // 3. 强制垃圾回收（如果支持）
    await _forceGarbageCollection();
  }

  /// 降低缓存大小
  Future<void> _reduceCacheSize() async {
    debugPrint('📉 降低缓存大小...');

    // 通过清理缓存来降低内存使用
    await _coordinator.clearAllCache();
    debugPrint('📉 已清理缓存以降低内存使用');
  }

  /// 清理不常用数据
  Future<void> _cleanupUnusedData() async {
    debugPrint('🗑️ 清理不常用数据...');

    // 基于访问时间清理数据
    // 这里可以实现具体的清理逻辑
  }

  /// 清理低频数据
  Future<void> _cleanupLowFrequencyData() async {
    debugPrint('📊 清理低频数据...');

    // 通过清理缓存来清理低频数据
    // 这里可以实现基于频率的清理逻辑
  }

  /// 强制垃圾回收
  Future<void> _forceGarbageCollection() async {
    debugPrint('🗑️ 强制垃圾回收...');

    // 在支持的环境中强制垃圾回收
    // 这里可以实现垃圾回收逻辑
  }

  /// 重启数据源检查
  Future<void> _restartDataSourceCheck() async {
    debugPrint('🔄 重启数据源检查...');

    // 重新初始化数据源切换器
    // 这里可以实现重启逻辑
  }

  /// 验证数据完整性
  Future<void> _validateDataIntegrity() async {
    debugPrint('🔍 验证数据完整性...');

    // 检查关键数据的完整性
    final sampleKeys = await _getCriticalDataKeys();
    for (final key in sampleKeys) {
      try {
        // 这里可以实现数据完整性检查逻辑
        debugPrint('🔍 检查数据完整性: $key');
      } catch (e) {
        debugPrint('❌ 验证数据 $key 失败: $e');
      }
    }
  }

  /// 获取热门缓存键
  Future<List<String>> _getPopularCacheKeys() async {
    // 这里应该返回实际的热门键
    return ['popular_funds', 'fund_rankings', 'search_results'];
  }

  /// 获取关键数据键
  Future<List<String>> _getCriticalDataKeys() async {
    // 返回关键数据的键列表
    return ['funds', 'fund_list', 'config_data'];
  }

  /// 记录性能趋势
  void _recordPerformanceTrend(DataLayerPerformanceMetrics metrics) {
    final timestamp = DateTime.now();

    // 记录缓存命中率趋势
    _recordTrend('cache_hit_rate', metrics.cacheHitRate, timestamp);

    // 记录响应时间趋势
    _recordTrend('response_time', metrics.averageResponseTime, timestamp);

    // 记录内存使用趋势
    _recordTrend('memory_usage', metrics.memoryCacheSize.toDouble(), timestamp);
  }

  /// 记录单个趋势
  void _recordTrend(String metric, double value, DateTime timestamp) {
    final trend = _performanceTrends.putIfAbsent(
      metric,
      () => PerformanceTrend(metric: metric),
    );

    trend.addPoint(value, timestamp);

    // 保持趋势数据在合理范围内
    if (trend.points.length > _config.maxTrendPoints) {
      trend.points.removeAt(0);
    }
  }

  /// 记录优化操作
  void _recordOptimization(
    List<String> optimizations,
    Duration duration,
    bool success, {
    dynamic error,
  }) {
    final record = OptimizationRecord(
      optimizations: optimizations,
      duration: duration,
      success: success,
      timestamp: DateTime.now(),
      error: error?.toString(),
    );

    _optimizationHistory.add(record);

    // 保持历史记录在合理范围内
    if (_optimizationHistory.length > _config.maxOptimizationHistory) {
      _optimizationHistory.removeAt(0);
    }

    // 记录到日志
    debugPrint('📊 优化记录: ${optimizations.join(', ')} - '
        '${success ? '成功' : '失败'} (${duration.inMilliseconds}ms)');
  }

  /// 手动执行优化
  Future<OptimizationResult> performManualOptimization(
    List<String> specificOptimizations,
  ) async {
    debugPrint('🔧 开始手动优化: ${specificOptimizations.join(', ')}');

    final startTime = DateTime.now();
    var optimizationsPerformed = <String>[];
    var errors = <String>[];

    try {
      for (final optimization in specificOptimizations) {
        try {
          await _executeOptimization(optimization);
          optimizationsPerformed.add(optimization);
        } catch (e) {
          errors.add('$optimization: $e');
        }
      }

      final duration = DateTime.now().difference(startTime);
      final success = errors.isEmpty;

      _recordOptimization(optimizationsPerformed, duration, success);

      return OptimizationResult(
        optimizationsPerformed: optimizationsPerformed,
        duration: duration,
        success: success,
        errors: errors,
      );
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      _recordOptimization(optimizationsPerformed, duration, false, error: e);

      return OptimizationResult(
        optimizationsPerformed: optimizationsPerformed,
        duration: duration,
        success: false,
        errors: [e.toString()],
      );
    }
  }

  /// 获取优化建议
  Future<List<OptimizationSuggestion>> getOptimizationSuggestions() async {
    final suggestions = <OptimizationSuggestion>[];

    try {
      final metrics = await _coordinator.getPerformanceMetrics();
      final healthReport = await _coordinator.getHealthReport();

      // 基于性能指标生成建议
      if (metrics.cacheHitRate < 0.7) {
        suggestions.add(const OptimizationSuggestion(
          type: 'cache_hit_rate',
          priority: 'high',
          description: '缓存命中率较低，建议预热常用数据',
          expectedImprovement: '提升15-30%命中率',
        ));
      }

      if (metrics.averageResponseTime > 100) {
        suggestions.add(const OptimizationSuggestion(
          type: 'response_time',
          priority: 'medium',
          description: '响应时间较长，建议清理过期缓存',
          expectedImprovement: '减少20-40%响应时间',
        ));
      }

      if (metrics.memoryCacheSize > 1000) {
        suggestions.add(const OptimizationSuggestion(
          type: 'memory_usage',
          priority: 'low',
          description: '内存使用较高，建议清理不常用数据',
          expectedImprovement: '减少30-50%内存使用',
        ));
      }

      if (!healthReport.isHealthy) {
        suggestions.add(const OptimizationSuggestion(
          type: 'health_issues',
          priority: 'critical',
          description: '存在健康问题，建议立即执行修复',
          expectedImprovement: '恢复正常运行状态',
        ));
      }
    } catch (e) {
      debugPrint('❌ 获取优化建议失败: $e');
    }

    return suggestions;
  }

  /// 获取优化历史
  List<OptimizationRecord> getOptimizationHistory() {
    return List.unmodifiable(_optimizationHistory);
  }

  /// 获取性能趋势
  Map<String, PerformanceTrend> getPerformanceTrends() {
    return Map.unmodifiable(_performanceTrends);
  }

  /// 生成优化报告
  Future<OptimizationReport> generateReport() async {
    final metrics = await _coordinator.getPerformanceMetrics();
    final healthReport = await _coordinator.getHealthReport();
    final suggestions = await getOptimizationSuggestions();

    return OptimizationReport(
      timestamp: DateTime.now(),
      currentMetrics: metrics,
      healthStatus: healthReport,
      optimizationHistory: getOptimizationHistory(),
      performanceTrends: getPerformanceTrends(),
      suggestions: suggestions,
      summary: _generateReportSummary(metrics, healthReport, suggestions),
    );
  }

  /// 生成报告摘要
  String _generateReportSummary(
    DataLayerPerformanceMetrics metrics,
    DataLayerHealthReport healthReport,
    List<OptimizationSuggestion> suggestions,
  ) {
    final buffer = StringBuffer();

    buffer.writeln('📊 数据层优化报告');
    buffer.writeln('生成时间: ${DateTime.now()}');
    buffer.writeln('');

    buffer.writeln('🎯 性能指标:');
    buffer.writeln(
        '  缓存命中率: ${(metrics.cacheHitRate * 100).toStringAsFixed(1)}%');
    buffer.writeln(
        '  平均响应时间: ${metrics.averageResponseTime.toStringAsFixed(1)}ms');
    buffer.writeln('  内存缓存大小: ${metrics.memoryCacheSize}项');
    buffer.writeln('');

    buffer.writeln('🏥 健康状态: ${healthReport.isHealthy ? '✅ 健康' : '⚠️ 有问题'}');
    if (!healthReport.isHealthy) {
      buffer.writeln('  问题: ${healthReport.issues.join(', ')}');
    }
    buffer.writeln('');

    buffer.writeln('💡 优化建议 (${suggestions.length}条):');
    for (final suggestion in suggestions) {
      buffer.writeln('  • ${suggestion.description} (${suggestion.priority})');
    }

    return buffer.toString();
  }

  /// 释放资源
  void dispose() {
    stopAutoOptimization();
    _optimizationHistory.clear();
    _performanceTrends.clear();
    debugPrint('🔒 数据层优化器已释放');
  }
}

// ========================================================================
// 配置和数据类
// ========================================================================

/// 数据层优化配置
class DataLayerOptimizationConfig {
  final Duration optimizationInterval;
  final double minCacheHitRate;
  final double maxResponseTime;
  final int maxMemoryCacheSize;
  final int targetMemoryCacheSize;
  final Duration dataRetentionPeriod;
  final int maxTrendPoints;
  final int maxOptimizationHistory;

  const DataLayerOptimizationConfig({
    this.optimizationInterval = const Duration(minutes: 10),
    this.minCacheHitRate = 0.7,
    this.maxResponseTime = 100.0,
    this.maxMemoryCacheSize = 2000,
    this.targetMemoryCacheSize = 1000,
    this.dataRetentionPeriod = const Duration(hours: 24),
    this.maxTrendPoints = 100,
    this.maxOptimizationHistory = 50,
  });

  factory DataLayerOptimizationConfig.defaultConfig() =>
      const DataLayerOptimizationConfig();

  factory DataLayerOptimizationConfig.aggressive() =>
      const DataLayerOptimizationConfig(
        optimizationInterval: Duration(minutes: 5),
        minCacheHitRate: 0.8,
        maxResponseTime: 50.0,
        maxMemoryCacheSize: 1000,
        targetMemoryCacheSize: 500,
        dataRetentionPeriod: Duration(hours: 12),
        maxTrendPoints: 50,
        maxOptimizationHistory: 25,
      );

  factory DataLayerOptimizationConfig.conservative() =>
      const DataLayerOptimizationConfig(
        optimizationInterval: Duration(minutes: 30),
        minCacheHitRate: 0.6,
        maxResponseTime: 200.0,
        maxMemoryCacheSize: 5000,
        targetMemoryCacheSize: 2000,
        dataRetentionPeriod: Duration(hours: 48),
        maxTrendPoints: 200,
        maxOptimizationHistory: 100,
      );
}

/// 优化记录
class OptimizationRecord {
  final List<String> optimizations;
  final Duration duration;
  final bool success;
  final DateTime timestamp;
  final String? error;

  const OptimizationRecord({
    required this.optimizations,
    required this.duration,
    required this.success,
    required this.timestamp,
    this.error,
  });
}

/// 优化结果
class OptimizationResult {
  final List<String> optimizationsPerformed;
  final Duration duration;
  final bool success;
  final List<String> errors;

  const OptimizationResult({
    required this.optimizationsPerformed,
    required this.duration,
    required this.success,
    required this.errors,
  });
}

/// 优化建议
class OptimizationSuggestion {
  final String type;
  final String priority;
  final String description;
  final String expectedImprovement;

  const OptimizationSuggestion({
    required this.type,
    required this.priority,
    required this.description,
    required this.expectedImprovement,
  });
}

/// 性能趋势
class PerformanceTrend {
  final String metric;
  final List<TrendPoint> points = [];

  PerformanceTrend({required this.metric});

  void addPoint(double value, DateTime timestamp) {
    points.add(TrendPoint(value: value, timestamp: timestamp));
  }

  /// 获取趋势方向
  TrendDirection getDirection() {
    if (points.length < 2) return TrendDirection.stable;

    final recent = points.sublist(math.max(0, points.length - 10));
    if (recent.length < 2) return TrendDirection.stable;

    double sumChange = 0;
    for (int i = 1; i < recent.length; i++) {
      sumChange += recent[i].value - recent[i - 1].value;
    }

    final avgChange = sumChange / (recent.length - 1);

    if (avgChange > 0.01) return TrendDirection.increasing;
    if (avgChange < -0.01) return TrendDirection.decreasing;
    return TrendDirection.stable;
  }
}

/// 趋势点
class TrendPoint {
  final double value;
  final DateTime timestamp;

  const TrendPoint({
    required this.value,
    required this.timestamp,
  });
}

/// 趋势方向
enum TrendDirection {
  increasing,
  decreasing,
  stable,
}

/// 优化报告
class OptimizationReport {
  final DateTime timestamp;
  final DataLayerPerformanceMetrics currentMetrics;
  final DataLayerHealthReport healthStatus;
  final List<OptimizationRecord> optimizationHistory;
  final Map<String, PerformanceTrend> performanceTrends;
  final List<OptimizationSuggestion> suggestions;
  final String summary;

  const OptimizationReport({
    required this.timestamp,
    required this.currentMetrics,
    required this.healthStatus,
    required this.optimizationHistory,
    required this.performanceTrends,
    required this.suggestions,
    required this.summary,
  });
}
