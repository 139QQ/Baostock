import 'dart:collection';
import 'dart:math';
import '../utils/logger.dart';
import '../hybrid/data_type.dart';

/// 活跃度记录
class ActivityRecord {
  /// 时间戳
  final DateTime timestamp;

  /// 是否成功
  final bool success;

  /// 延迟
  final Duration latency;

  /// 数据变化检测
  final bool hasDataChange;

  const ActivityRecord({
    required this.timestamp,
    required this.success,
    required this.latency,
    this.hasDataChange = false,
  });

  /// 计算年龄 (秒)
  int get ageInSeconds => DateTime.now().difference(timestamp).inSeconds;
}

/// 数据类型活跃度统计
class DataTypeActivityStats {
  /// 活跃度记录列表
  final Queue<ActivityRecord> records = Queue<ActivityRecord>();

  /// 最大记录数量
  static const int _maxRecords = 100;

  /// 添加活跃度记录
  void addRecord(ActivityRecord record) {
    records.add(record);

    // 限制记录数量
    while (records.length > _maxRecords) {
      records.removeFirst();
    }
  }

  /// 获取成功率 (最近N次记录)
  double getSuccessRate({int count = 20}) {
    if (records.isEmpty) return 0.0;

    final recentRecords = records.takeLast(count).toList();
    if (recentRecords.isEmpty) return 0.0;

    final successCount = recentRecords.where((r) => r.success).length;
    return successCount / recentRecords.length;
  }

  /// 获取平均延迟
  Duration getAverageLatency({int count = 20}) {
    if (records.isEmpty) return Duration.zero;

    final recentRecords = records.takeLast(count).toList();
    if (recentRecords.isEmpty) return Duration.zero;

    final totalMs = recentRecords
        .map((r) => r.latency.inMilliseconds)
        .reduce((a, b) => a + b);

    return Duration(milliseconds: totalMs ~/ recentRecords.length);
  }

  /// 获取数据变化频率
  double getDataChangeFrequency({int count = 20}) {
    if (records.isEmpty) return 0.0;

    final recentRecords = records.takeLast(count).toList();
    if (recentRecords.isEmpty) return 0.0;

    final changeCount = recentRecords.where((r) => r.hasDataChange).length;
    return changeCount / recentRecords.length;
  }

  /// 获取活跃度评分 (0-100)
  double getActivityScore() {
    if (records.isEmpty) return 0.0;

    // 综合成功率、延迟和数据变化频率
    final successRate = getSuccessRate();
    final avgLatencyMs = getAverageLatency().inMilliseconds;
    final changeFrequency = getDataChangeFrequency();

    // 成功率权重 40%
    final successScore = successRate * 40;

    // 延迟权重 30% (延迟越低得分越高)
    double latencyScore = 30.0;
    if (avgLatencyMs > 0) {
      latencyScore = max(0.0, 30.0 - (avgLatencyMs / 100.0) * 30.0);
    }

    // 数据变化频率权重 30%
    final changeScore = changeFrequency * 30.0;

    return (successScore + latencyScore + changeScore).clamp(0.0, 100.0);
  }

  /// 获取最近活跃度趋势
  ActivityTrend getTrend({int windowSize = 10}) {
    if (records.length < windowSize * 2) return ActivityTrend.stable;

    final recentRecords = records.takeLast(windowSize).toList();
    final previousRecords =
        records.skip(records.length - windowSize * 2).take(windowSize).toList();

    final recentSuccessRate =
        recentRecords.where((r) => r.success).length / recentRecords.length;
    final previousSuccessRate =
        previousRecords.where((r) => r.success).length / previousRecords.length;

    final difference = recentSuccessRate - previousSuccessRate;

    if (difference > 0.1) {
      return ActivityTrend.improving;
    } else if (difference < -0.1) {
      return ActivityTrend.degrading;
    } else {
      return ActivityTrend.stable;
    }
  }

  /// 清理过期记录
  void cleanup({int maxAgeMinutes = 60}) {
    final cutoffTime =
        DateTime.now().subtract(Duration(minutes: maxAgeMinutes));
    while (records.isNotEmpty && records.first.timestamp.isBefore(cutoffTime)) {
      records.removeFirst();
    }
  }
}

/// 活跃度趋势
enum ActivityTrend {
  improving('改善'),
  stable('稳定'),
  degrading('下降');

  const ActivityTrend(this.description);
  final String description;
}

/// 活跃度跟踪器
///
/// 跟踪各种数据类型的活跃度，包括成功率、延迟、数据变化等指标
/// 为智能频率调整提供数据支持
class ActivityTracker {
  /// 各数据类型的活跃度统计
  final Map<DataType, DataTypeActivityStats> _activityStats = {};

  /// 全局活跃度记录
  final Queue<ActivityRecord> _globalRecords = Queue<ActivityRecord>();

  /// 统计开始时间
  final DateTime _startTime = DateTime.now();

  /// 记录活跃度
  void recordActivity(DataType dataType, bool success, Duration latency,
      {bool hasDataChange = false}) {
    final record = ActivityRecord(
      timestamp: DateTime.now(),
      success: success,
      latency: latency,
      hasDataChange: hasDataChange,
    );

    // 添加到全局记录
    _globalRecords.add(record);
    if (_globalRecords.length > 1000) {
      _globalRecords.removeFirst();
    }

    // 添加到数据类型统计
    final stats =
        _activityStats.putIfAbsent(dataType, () => DataTypeActivityStats());
    stats.addRecord(record);

    AppLogger.debug(
        'Recorded activity for ${dataType.code}: success=$success, latency=${latency.inMilliseconds}ms');
  }

  /// 获取数据类型的活跃度统计
  DataTypeActivityStats? getStats(DataType dataType) {
    return _activityStats[dataType];
  }

  /// 获取所有数据类型的活跃度评分
  Map<DataType, double> getAllActivityScores() {
    return _activityStats
        .map((key, stats) => MapEntry(key, stats.getActivityScore()));
  }

  /// 获取最活跃的数据类型
  List<DataType> getMostActiveDataTypes({int limit = 5}) {
    final scores = getAllActivityScores();
    final sortedEntries = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.take(limit).map((entry) => entry.key).toList();
  }

  /// 获取最不活跃的数据类型
  List<DataType> getLeastActiveDataTypes({int limit = 5}) {
    final scores = getAllActivityScores();
    final sortedEntries = scores.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return sortedEntries.take(limit).map((entry) => entry.key).toList();
  }

  /// 获取全局统计信息
  Map<String, dynamic> getGlobalStats() {
    if (_globalRecords.isEmpty) {
      return {
        'totalRecords': 0,
        'successRate': 0.0,
        'averageLatency': 0,
        'uptime': DateTime.now().difference(_startTime).inSeconds,
      };
    }

    final successCount = _globalRecords.where((r) => r.success).length;
    final successRate = successCount / _globalRecords.length;

    final totalLatencyMs = _globalRecords
        .map((r) => r.latency.inMilliseconds)
        .reduce((a, b) => a + b);
    final averageLatencyMs = totalLatencyMs ~/ _globalRecords.length;

    return {
      'totalRecords': _globalRecords.length,
      'successRate': successRate,
      'averageLatency': averageLatencyMs,
      'uptime': DateTime.now().difference(_startTime).inSeconds,
      'startTime': _startTime.toIso8601String(),
    };
  }

  /// 获取活跃度报告
  Map<String, dynamic> getReport() {
    final report = <String, dynamic>{
      'global': getGlobalStats(),
      'dataTypes': <String, dynamic>{},
      'summary': <String, dynamic>{},
    };

    // 各数据类型统计
    for (final entry in _activityStats.entries) {
      final stats = entry.value;
      report['dataTypes'][entry.key.code] = {
        'successRate': stats.getSuccessRate(),
        'averageLatency': stats.getAverageLatency().inMilliseconds,
        'dataChangeFrequency': stats.getDataChangeFrequency(),
        'activityScore': stats.getActivityScore(),
        'trend': stats.getTrend().name,
        'recordCount': stats.records.length,
      };
    }

    // 摘要信息
    final allScores = getAllActivityScores();
    if (allScores.isNotEmpty) {
      final avgScore =
          allScores.values.reduce((a, b) => a + b) / allScores.length;
      final maxScore = allScores.values.reduce(max);
      final minScore = allScores.values.reduce(min);

      report['summary'] = {
        'averageActivityScore': avgScore,
        'maxActivityScore': maxScore,
        'minActivityScore': minScore,
        'totalDataTypes': allScores.length,
        'mostActive':
            getMostActiveDataTypes(limit: 3).map((t) => t.code).toList(),
        'leastActive':
            getLeastActiveDataTypes(limit: 3).map((t) => t.code).toList(),
      };
    }

    return report;
  }

  /// 检查数据类型是否需要频率调整
  bool needsFrequencyAdjustment(DataType dataType) {
    final stats = _activityStats[dataType];
    if (stats == null) return false;

    final score = stats.getActivityScore();
    final trend = stats.getTrend();

    // 如果活跃度评分过低或趋势下降，建议调整频率
    return score < 50.0 || trend == ActivityTrend.degrading;
  }

  /// 获取建议的频率调整方向
  FrequencyAdjustment getSuggestedAdjustment(DataType dataType) {
    final stats = _activityStats[dataType];
    if (stats == null) return FrequencyAdjustment.none;

    final score = stats.getActivityScore();
    final successRate = stats.getSuccessRate();
    final avgLatency = stats.getAverageLatency();
    final changeFreq = stats.getDataChangeFrequency();
    final trend = stats.getTrend();

    // 如果成功率低，建议降低频率
    if (successRate < 0.7) {
      return FrequencyAdjustment.decrease;
    }

    // 如果延迟高，建议降低频率
    if (avgLatency.inMilliseconds > 5000) {
      return FrequencyAdjustment.decrease;
    }

    // 如果数据变化频率低，建议降低频率
    if (changeFreq < 0.1) {
      return FrequencyAdjustment.decrease;
    }

    // 如果活跃度评分高且趋势改善，建议增加频率
    if (score > 80.0 && trend == ActivityTrend.improving) {
      return FrequencyAdjustment.increase;
    }

    // 如果活跃度评分中等且趋势稳定，保持当前频率
    if (score >= 50.0 && score <= 80.0) {
      return FrequencyAdjustment.none;
    }

    // 默认不建议调整
    return FrequencyAdjustment.none;
  }

  /// 清理过期数据
  void cleanup() {
    // 清理全局记录
    final cutoffTime = DateTime.now().subtract(const Duration(hours: 24));
    while (_globalRecords.isNotEmpty &&
        _globalRecords.first.timestamp.isBefore(cutoffTime)) {
      _globalRecords.removeFirst();
    }

    // 清理各数据类型的记录
    for (final stats in _activityStats.values) {
      stats.cleanup();
    }

    AppLogger.debug('ActivityTracker cleanup completed');
  }

  /// 重置所有统计数据
  void reset() {
    _globalRecords.clear();
    _activityStats.clear();
    AppLogger.info('ActivityTracker reset completed');
  }
}

/// 频率调整建议
enum FrequencyAdjustment {
  increase('增加频率'),
  decrease('降低频率'),
  none('保持频率');

  const FrequencyAdjustment(this.description);
  final String description;
}

/// 扩展 Queue，添加 takeLast 方法
extension QueueExtensions<T> on Queue<T> {
  Iterable<T> takeLast(int count) {
    if (count >= length) {
      return this;
    }
    return skip(length - count);
  }
}
