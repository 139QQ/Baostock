import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import '../../../../core/utils/logger.dart';

/// 指数延迟监控器
///
/// 监控市场指数数据获取的延迟情况，提供性能分析和预警功能
class IndexLatencyMonitor {
  /// 延迟记录 (按指数代码分组)
  final Map<String, Queue<LatencyRecord>> _latencyRecords = {};

  /// 监控配置
  final LatencyMonitorConfig _config;

  /// 统计信息
  final Map<String, LatencyStatistics> _statistics = {};

  /// 预警阈值状态
  final Map<String, AlertLevel> _alertLevels = {};

  /// 性能趋势分析
  final Map<String, PerformanceTrend> _performanceTrends = {};

  /// 延迟预警流控制器
  final StreamController<LatencyAlert> _alertController =
      StreamController<LatencyAlert>.broadcast();

  /// 定时分析定时器
  Timer? _analysisTimer;

  /// 构造函数
  IndexLatencyMonitor({
    LatencyMonitorConfig? config,
  }) : _config = config ?? const LatencyMonitorConfig() {
    _startPeriodicAnalysis();
  }

  /// 延迟预警流
  Stream<LatencyAlert> get alertStream => _alertController.stream;

  /// 记录延迟数据
  void recordLatency(
    Duration latency, {
    required String indexCode,
    String operation = 'fetch',
    bool success = true,
    String? errorMessage,
  }) {
    final record = LatencyRecord(
      indexCode: indexCode,
      latency: latency,
      operation: operation,
      success: success,
      timestamp: DateTime.now(),
      errorMessage: errorMessage,
    );

    // 添加到延迟记录
    _addLatencyRecord(record);

    // 更新统计信息
    _updateStatistics(indexCode);

    // 检查预警条件
    _checkAlertConditions(indexCode, record);

    AppLogger.debug(
        'Recorded latency for $indexCode: ${latency.inMilliseconds}ms');
  }

  /// 添加延迟记录
  void _addLatencyRecord(LatencyRecord record) {
    final indexCode = record.indexCode;
    if (!_latencyRecords.containsKey(indexCode)) {
      _latencyRecords[indexCode] = Queue<LatencyRecord>();
    }

    final queue = _latencyRecords[indexCode]!;
    queue.add(record);

    // 保持记录数量在限制范围内
    while (queue.length > _config.maxRecordsPerIndex) {
      queue.removeFirst();
    }
  }

  /// 更新统计信息
  void _updateStatistics(String indexCode) {
    final records = _latencyRecords[indexCode];
    if (records == null || records.isEmpty) return;

    final latencies = records.map((r) => r.latency).toList();
    final successRecords = records.where((r) => r.success).toList();

    if (successRecords.isEmpty) return;

    // 计算基本统计
    final totalLatency = successRecords.fold<Duration>(
      Duration.zero,
      (sum, record) => sum + record.latency,
    );

    final averageLatency = Duration(
      milliseconds: totalLatency.inMilliseconds ~/ successRecords.length,
    );

    // 计算百分位数
    final sortedLatencies =
        successRecords.map((r) => r.latency.inMilliseconds).toList()..sort();

    final p50 = _calculatePercentile(sortedLatencies, 50);
    final p95 = _calculatePercentile(sortedLatencies, 95);
    final p99 = _calculatePercentile(sortedLatencies, 99);

    // 计算成功率
    final successRate = successRecords.length / records.length;

    _statistics[indexCode] = LatencyStatistics(
      indexCode: indexCode,
      totalRequests: records.length,
      successfulRequests: successRecords.length,
      averageLatency: averageLatency,
      p50Latency: Duration(milliseconds: p50),
      p95Latency: Duration(milliseconds: p95),
      p99Latency: Duration(milliseconds: p99),
      minLatency: Duration(milliseconds: sortedLatencies.first),
      maxLatency: Duration(milliseconds: sortedLatencies.last),
      successRate: successRate,
      lastUpdateTime: DateTime.now(),
    );
  }

  /// 计算百分位数
  int _calculatePercentile(List<int> sortedValues, int percentile) {
    if (sortedValues.isEmpty) return 0;

    final index = ((sortedValues.length - 1) * percentile / 100).round();
    return sortedValues[math.min(index, sortedValues.length - 1)];
  }

  /// 检查预警条件
  void _checkAlertConditions(String indexCode, LatencyRecord record) {
    final stats = _statistics[indexCode];
    if (stats == null) return;

    // 检查单次延迟预警
    AlertLevel? newAlertLevel;
    String? alertMessage;

    if (record.latency > _config.criticalLatencyThreshold) {
      newAlertLevel = AlertLevel.critical;
      alertMessage = '严重延迟: ${record.latency.inMilliseconds}ms';
    } else if (record.latency > _config.warningLatencyThreshold) {
      newAlertLevel = AlertLevel.warning;
      alertMessage = '延迟警告: ${record.latency.inMilliseconds}ms';
    } else if (record.latency > _config.infoLatencyThreshold) {
      newAlertLevel = AlertLevel.info;
      alertMessage = '延迟提示: ${record.latency.inMilliseconds}ms';
    }

    // 检查平均延迟预警
    if (stats.averageLatency > _config.criticalLatencyThreshold) {
      newAlertLevel = AlertLevel.critical;
      alertMessage = '平均延迟严重: ${stats.averageLatency.inMilliseconds}ms';
    }

    // 检查成功率预警
    if (stats.successRate < _config.minSuccessRate) {
      newAlertLevel = AlertLevel.critical;
      alertMessage = '成功率过低: ${(stats.successRate * 100).toStringAsFixed(1)}%';
    }

    // 检查预警等级变化
    final currentLevel = _alertLevels[indexCode];
    if (newAlertLevel != null && newAlertLevel != currentLevel) {
      _alertLevels[indexCode] = newAlertLevel;

      final alert = LatencyAlert(
        indexCode: indexCode,
        level: newAlertLevel,
        message: alertMessage!,
        latency: record.latency,
        statistics: stats,
        timestamp: DateTime.now(),
      );

      _alertController.add(alert);
      AppLogger.warn('Latency alert for $indexCode: ${alert.message}');
    }
  }

  /// 获取平均延迟
  Duration? get averageLatency {
    if (_statistics.isEmpty) return null;

    final totalLatency = _statistics.values.fold<Duration>(
        Duration.zero, (sum, stats) => sum + stats.averageLatency);

    return Duration(
      milliseconds: totalLatency.inMilliseconds ~/ _statistics.length,
    );
  }

  /// 获取指定指数的统计信息
  LatencyStatistics? getStatistics(String indexCode) {
    return _statistics[indexCode];
  }

  /// 获取所有指数的统计信息
  Map<String, LatencyStatistics> getAllStatistics() {
    return Map.unmodifiable(_statistics);
  }

  /// 获取指定指数的延迟记录
  List<LatencyRecord> getLatencyRecords(String indexCode) {
    final records = _latencyRecords[indexCode];
    return records?.toList() ?? [];
  }

  /// 获取性能趋势
  PerformanceTrend? getPerformanceTrend(String indexCode) {
    return _performanceTrends[indexCode];
  }

  /// 分析性能趋势
  void _analyzePerformanceTrends() {
    for (final entry in _statistics.entries) {
      final indexCode = entry.key;
      final stats = entry.value;
      final records = _latencyRecords[indexCode];

      if (records == null || records.length < _config.minRecordsForTrend) {
        continue;
      }

      // 获取最近的记录用于趋势分析
      final recentRecords = records.take(_config.trendAnalysisPeriod).toList();
      if (recentRecords.length < 10) continue;

      final trend = _calculateTrend(recentRecords);
      _performanceTrends[indexCode] = trend;

      // 检查趋势预警
      _checkTrendAlerts(indexCode, trend, stats);
    }
  }

  /// 计算性能趋势
  PerformanceTrend _calculateTrend(List<LatencyRecord> records) {
    final latencies = records
        .where((r) => r.success)
        .map((r) => r.latency.inMilliseconds.toDouble())
        .toList();

    if (latencies.length < 2) {
      return const PerformanceTrend(
        direction: TrendDirection.stable,
        slope: 0.0,
        confidence: 0.0,
        description: '数据不足',
        intercept: 0.0,
      );
    }

    // 简单线性回归计算趋势
    final n = latencies.length.toDouble();
    final sumX = (n * (n - 1) / 2); // 0 + 1 + 2 + ... + (n-1)
    final sumY = latencies.reduce((a, b) => a + b);
    final sumXY = latencies
        .asMap()
        .entries
        .map((e) => e.key.toDouble() * e.value)
        .reduce((a, b) => a + b);
    final sumX2 =
        (n * (n - 1) * (2 * n - 1) / 6); // 0^2 + 1^2 + 2^2 + ... + (n-1)^2

    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    final intercept = (sumY - slope * sumX) / n;

    // 计算相关系数作为置信度
    final meanX = sumX / n;
    final meanY = sumY / n;
    final numerator = latencies.asMap().entries.map((e) {
      final x = e.key.toDouble() - meanX;
      final y = e.value - meanY;
      return x * y;
    }).reduce((a, b) => a + b);

    final denominatorX = latencies.asMap().entries.map((e) {
      final x = e.key.toDouble() - meanX;
      return x * x;
    }).reduce((a, b) => a + b);

    final denominatorY = latencies.map((y) {
      final diff = y - meanY;
      return diff * diff;
    }).reduce((a, b) => a + b);

    final correlation = numerator / math.sqrt(denominatorX * denominatorY);
    final confidence = correlation.abs();

    // 确定趋势方向
    TrendDirection direction;
    if (slope.abs() < _config.trendStabilityThreshold) {
      direction = TrendDirection.stable;
    } else if (slope > 0) {
      direction = TrendDirection.degrading;
    } else {
      direction = TrendDirection.improving;
    }

    String description;
    if (direction == TrendDirection.stable) {
      description = '性能稳定';
    } else if (direction == TrendDirection.improving) {
      description = '性能改善中';
    } else {
      description = '性能下降中';
    }

    return PerformanceTrend(
      direction: direction,
      slope: slope,
      confidence: confidence,
      description: description,
      intercept: intercept,
    );
  }

  /// 检查趋势预警
  void _checkTrendAlerts(
      String indexCode, PerformanceTrend trend, LatencyStatistics stats) {
    if (trend.confidence < _config.trendConfidenceThreshold) return;

    if (trend.direction == TrendDirection.degrading &&
        trend.slope > _config.degradingTrendThreshold) {
      final alert = LatencyAlert(
        indexCode: indexCode,
        level: AlertLevel.warning,
        message: '性能持续下降趋势',
        latency: stats.averageLatency,
        statistics: stats,
        timestamp: DateTime.now(),
        trend: trend,
      );

      _alertController.add(alert);
      AppLogger.warn(
          'Performance trend alert for $indexCode: ${trend.description}');
    }
  }

  /// 启动定期分析
  void _startPeriodicAnalysis() {
    _analysisTimer = Timer.periodic(_config.analysisInterval, (_) {
      _analyzePerformanceTrends();
    });
  }

  /// 获取整体性能报告
  LatencyPerformanceReport generatePerformanceReport() {
    final allStats = _statistics.values.toList();

    if (allStats.isEmpty) {
      return LatencyPerformanceReport(
        timestamp: DateTime.now(),
        totalIndices: 0,
        averageLatency: Duration.zero,
        overallSuccessRate: 0.0,
        alertDistribution: {},
        topSlowIndices: [],
        recommendations: ['暂无数据'],
      );
    }

    // 计算整体指标
    final totalLatency = allStats.fold<Duration>(
      Duration.zero,
      (sum, stats) => sum + stats.averageLatency,
    );

    final averageLatency = Duration(
      milliseconds: totalLatency.inMilliseconds ~/ allStats.length,
    );

    final overallSuccessRate =
        allStats.map((s) => s.successRate).reduce((a, b) => a + b) /
            allStats.length;

    // 统计预警分布
    final alertDistribution = <AlertLevel, int>{};
    for (final level in _alertLevels.values) {
      alertDistribution[level] = (alertDistribution[level] ?? 0) + 1;
    }

    // 找出最慢的指数
    final sortedByLatency = allStats.toList()
      ..sort((a, b) => b.averageLatency.compareTo(a.averageLatency));

    final topSlowIndices = sortedByLatency
        .take(5)
        .map((s) => SlowIndexInfo(
              indexCode: s.indexCode,
              averageLatency: s.averageLatency,
              successRate: s.successRate,
              alertLevel: _alertLevels[s.indexCode] ?? AlertLevel.normal,
            ))
        .toList();

    // 生成建议
    final recommendations =
        _generateRecommendations(allStats, alertDistribution);

    return LatencyPerformanceReport(
      timestamp: DateTime.now(),
      totalIndices: allStats.length,
      averageLatency: averageLatency,
      overallSuccessRate: overallSuccessRate,
      alertDistribution: alertDistribution,
      topSlowIndices: topSlowIndices,
      recommendations: recommendations,
    );
  }

  /// 生成性能建议
  List<String> _generateRecommendations(
    List<LatencyStatistics> stats,
    Map<AlertLevel, int> alertDistribution,
  ) {
    final recommendations = <String>[];

    // 基于预警分布的建议
    final criticalCount = alertDistribution[AlertLevel.critical] ?? 0;
    final warningCount = alertDistribution[AlertLevel.warning] ?? 0;

    if (criticalCount > 0) {
      recommendations.add('有$criticalCount个指数出现严重延迟，需要立即优化');
    }

    if (warningCount > stats.length * 0.3) {
      recommendations.add('超过30%的指数出现延迟警告，建议检查网络连接');
    }

    // 基于平均延迟的建议
    final avgLatency = stats
            .fold<Duration>(
              Duration.zero,
              (sum, s) => sum + s.averageLatency,
            )
            .inMilliseconds /
        stats.length;

    if (avgLatency > 10000) {
      // 10秒
      recommendations.add('整体延迟较高，建议优化API调用策略');
    }

    // 基于成功率的建议
    final avgSuccessRate =
        stats.map((s) => s.successRate).reduce((a, b) => a + b) / stats.length;
    if (avgSuccessRate < 0.95) {
      recommendations.add('请求成功率偏低，建议增强错误处理和重试机制');
    }

    if (recommendations.isEmpty) {
      recommendations.add('系统性能良好，继续保持监控');
    }

    return recommendations;
  }

  /// 重置监控数据
  void reset() {
    _latencyRecords.clear();
    _statistics.clear();
    _alertLevels.clear();
    _performanceTrends.clear();
    AppLogger.info('Latency monitor reset');
  }

  /// 重置指定指数的监控数据
  void resetIndex(String indexCode) {
    _latencyRecords.remove(indexCode);
    _statistics.remove(indexCode);
    _alertLevels.remove(indexCode);
    _performanceTrends.remove(indexCode);
    AppLogger.info('Latency monitor reset for index: $indexCode');
  }

  /// 销毁监控器
  void dispose() {
    _analysisTimer?.cancel();
    _alertController.close();
    AppLogger.info('IndexLatencyMonitor disposed');
  }
}

/// 延迟记录
class LatencyRecord {
  final String indexCode;
  final Duration latency;
  final String operation;
  final bool success;
  final DateTime timestamp;
  final String? errorMessage;

  const LatencyRecord({
    required this.indexCode,
    required this.latency,
    required this.operation,
    required this.success,
    required this.timestamp,
    this.errorMessage,
  });

  @override
  String toString() {
    return 'LatencyRecord(index: $indexCode, latency: ${latency.inMilliseconds}ms, success: $success)';
  }
}

/// 延迟统计信息
class LatencyStatistics {
  final String indexCode;
  final int totalRequests;
  final int successfulRequests;
  final Duration averageLatency;
  final Duration p50Latency;
  final Duration p95Latency;
  final Duration p99Latency;
  final Duration minLatency;
  final Duration maxLatency;
  final double successRate;
  final DateTime lastUpdateTime;

  const LatencyStatistics({
    required this.indexCode,
    required this.totalRequests,
    required this.successfulRequests,
    required this.averageLatency,
    required this.p50Latency,
    required this.p95Latency,
    required this.p99Latency,
    required this.minLatency,
    required this.maxLatency,
    required this.successRate,
    required this.lastUpdateTime,
  });

  @override
  String toString() {
    return 'LatencyStatistics(index: $indexCode, avg: ${averageLatency.inMilliseconds}ms, success: ${(successRate * 100).toStringAsFixed(1)}%)';
  }
}

/// 延迟预警
class LatencyAlert {
  final String indexCode;
  final AlertLevel level;
  final String message;
  final Duration latency;
  final LatencyStatistics statistics;
  final DateTime timestamp;
  final PerformanceTrend? trend;

  const LatencyAlert({
    required this.indexCode,
    required this.level,
    required this.message,
    required this.latency,
    required this.statistics,
    required this.timestamp,
    this.trend,
  });

  @override
  String toString() {
    return 'LatencyAlert(index: $indexCode, level: $level, message: $message)';
  }
}

/// 预警等级
enum AlertLevel {
  normal,
  info,
  warning,
  critical;

  String get description {
    switch (this) {
      case AlertLevel.normal:
        return '正常';
      case AlertLevel.info:
        return '信息';
      case AlertLevel.warning:
        return '警告';
      case AlertLevel.critical:
        return '严重';
    }
  }
}

/// 性能趋势
class PerformanceTrend {
  final TrendDirection direction;
  final double slope;
  final double confidence;
  final String description;
  final double intercept;

  const PerformanceTrend({
    required this.direction,
    required this.slope,
    required this.confidence,
    required this.description,
    required this.intercept,
  });

  @override
  String toString() {
    return 'PerformanceTrend(direction: $direction, confidence: ${(confidence * 100).toStringAsFixed(1)}%)';
  }
}

/// 趋势方向
enum TrendDirection {
  improving,
  degrading,
  stable;

  String get description {
    switch (this) {
      case TrendDirection.improving:
        return '改善';
      case TrendDirection.degrading:
        return '下降';
      case TrendDirection.stable:
        return '稳定';
    }
  }
}

/// 性能报告
class LatencyPerformanceReport {
  final DateTime timestamp;
  final int totalIndices;
  final Duration averageLatency;
  final double overallSuccessRate;
  final Map<AlertLevel, int> alertDistribution;
  final List<SlowIndexInfo> topSlowIndices;
  final List<String> recommendations;

  const LatencyPerformanceReport({
    required this.timestamp,
    required this.totalIndices,
    required this.averageLatency,
    required this.overallSuccessRate,
    required this.alertDistribution,
    required this.topSlowIndices,
    required this.recommendations,
  });

  @override
  String toString() {
    return 'LatencyPerformanceReport(indices: $totalIndices, avgLatency: ${averageLatency.inMilliseconds}ms, successRate: ${(overallSuccessRate * 100).toStringAsFixed(1)}%)';
  }
}

/// 慢指数信息
class SlowIndexInfo {
  final String indexCode;
  final Duration averageLatency;
  final double successRate;
  final AlertLevel alertLevel;

  const SlowIndexInfo({
    required this.indexCode,
    required this.averageLatency,
    required this.successRate,
    required this.alertLevel,
  });

  @override
  String toString() {
    return 'SlowIndexInfo(index: $indexCode, latency: ${averageLatency.inMilliseconds}ms, alert: $alertLevel)';
  }
}

/// 监控配置
class LatencyMonitorConfig {
  /// 信息延迟阈值
  final Duration infoLatencyThreshold;

  /// 警告延迟阈值
  final Duration warningLatencyThreshold;

  /// 严重延迟阈值
  final Duration criticalLatencyThreshold;

  /// 最小成功率
  final double minSuccessRate;

  /// 每个指数最大记录数
  final int maxRecordsPerIndex;

  /// 趋势分析周期
  final int trendAnalysisPeriod;

  /// 趋势分析最小记录数
  final int minRecordsForTrend;

  /// 趋势稳定性阈值
  final double trendStabilityThreshold;

  /// 趋势置信度阈值
  final double trendConfidenceThreshold;

  /// 性能下降趋势阈值
  final double degradingTrendThreshold;

  /// 分析间隔
  final Duration analysisInterval;

  const LatencyMonitorConfig({
    this.infoLatencyThreshold = const Duration(seconds: 5),
    this.warningLatencyThreshold = const Duration(seconds: 15),
    this.criticalLatencyThreshold = const Duration(seconds: 30),
    this.minSuccessRate = 0.95,
    this.maxRecordsPerIndex = 100,
    this.trendAnalysisPeriod = 20,
    this.minRecordsForTrend = 10,
    this.trendStabilityThreshold = 0.1,
    this.trendConfidenceThreshold = 0.7,
    this.degradingTrendThreshold = 10.0,
    this.analysisInterval = const Duration(minutes: 5),
  });
}
