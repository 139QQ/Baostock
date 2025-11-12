import 'dart:async';
import 'dart:math';

import '../models/market_change_event.dart';

/// 推送时间优化服务
/// 基于用户活跃时段、事件紧急程度和智能算法优化推送时机
class PushTimeOptimizationService {
  final Map<String, UserTimePattern> _userTimePatterns = {};
  final Map<String, List<HistoricalPushData>> _pushHistory = {};

  PushTimeOptimizationService();

  /// 分析用户时间模式
  Future<UserTimePattern> analyzeUserTimePattern(String userId) async {
    if (_userTimePatterns.containsKey(userId)) {
      return _userTimePatterns[userId]!;
    }

    // 获取历史推送数据
    final history = _pushHistory[userId] ?? [];
    if (history.length < 10) {
      // 数据不足时返回默认模式
      final defaultPattern = UserTimePattern.defaultPattern(userId);
      _userTimePatterns[userId] = defaultPattern;
      return defaultPattern;
    }

    // 分析用户活跃时段
    final activeHours = _analyzeActiveHours(history);
    final peakEngagementHours = _analyzePeakEngagementHours(history);
    final preferredPushTimes =
        _calculatePreferredPushTimes(activeHours, peakEngagementHours);

    final pattern = UserTimePattern(
      userId: userId,
      activeHours: activeHours,
      peakEngagementHours: peakEngagementHours,
      preferredPushTimes: preferredPushTimes,
      weekdayPatterns: {},
      seasonalPatterns: {},
      lastAnalyzed: DateTime.now(),
    );

    _userTimePatterns[userId] = pattern;
    return pattern;
  }

  /// 获取最优推送时间
  Future<DateTime> getOptimalPushTime(
    String userId,
    MarketChangeEvent event,
  ) async {
    final userPattern = await analyzeUserTimePattern(userId);
    final now = DateTime.now();

    // 紧急事件立即推送
    if (event.severity.name == 'high') {
      return now;
    }

    // 查找下一个最优推送时间
    for (int i = 0; i < 24; i++) {
      final candidate = now.add(Duration(hours: i));
      final hour = candidate.hour;

      if (userPattern.preferredPushTimes.contains(hour)) {
        return candidate;
      }
    }

    // 如果没有找到最优时间，返回下一个活跃时段
    return now;
  }

  /// 计算推送时间质量分数
  double calculateTimeQualityScore(
    DateTime pushTime,
    UserTimePattern userPattern,
    MarketChangeEvent event,
  ) {
    final hour = pushTime.hour;
    double score = 0.0;

    // 基于用户偏好时间
    if (userPattern.preferredPushTimes.contains(hour)) {
      score += 0.5;
    }

    // 基于活跃时段
    if (userPattern.activeHours.contains(hour)) {
      score += 0.3;
    }

    // 基于峰值参与时段
    if (userPattern.peakEngagementHours.contains(hour)) {
      score += 0.2;
    }

    return score.clamp(0.0, 1.0);
  }

  /// 分析活跃小时
  List<int> _analyzeActiveHours(List<HistoricalPushData> history) {
    final hourCounts = <int, int>{};

    for (final data in history) {
      final hour = data.timestamp.hour;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
    }

    // 返回活跃度超过平均值的时段
    final average = history.length / 24;
    return hourCounts.entries
        .where((entry) => entry.value > average)
        .map((entry) => entry.key)
        .toList();
  }

  /// 分析峰值参与小时
  List<int> _analyzePeakEngagementHours(List<HistoricalPushData> history) {
    final hourEngagement = <int, double>{};

    for (final data in history) {
      final hour = data.timestamp.hour;
      final currentEngagement = hourEngagement[hour] ?? 0.0;
      hourEngagement[hour] = currentEngagement + data.engagementScore;
    }

    // 返回参与度最高的3个时段
    final sortedHours = hourEngagement.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedHours.take(3).map((entry) => entry.key).toList();
  }

  /// 计算首选推送时间
  List<int> _calculatePreferredPushTimes(
    List<int> activeHours,
    List<int> peakEngagementHours,
  ) {
    final preferredTimes = <int>{};

    // 添加峰值参与时段
    preferredTimes.addAll(peakEngagementHours);

    // 添加其他活跃时段
    for (final hour in activeHours) {
      if (!peakEngagementHours.contains(hour)) {
        preferredTimes.add(hour);
      }
    }

    return preferredTimes.toList();
  }

  /// 记录推送数据
  void recordPushData(String userId, HistoricalPushData pushData) {
    if (!_pushHistory.containsKey(userId)) {
      _pushHistory[userId] = [];
    }

    _pushHistory[userId]!.add(pushData);

    // 限制历史数据数量
    if (_pushHistory[userId]!.length > 1000) {
      _pushHistory[userId] = _pushHistory[userId]!.take(1000).toList();
    }
  }

  /// 清理缓存
  void clearCache() {
    _userTimePatterns.clear();
    _pushHistory.clear();
  }
}

/// 用户时间模式
class UserTimePattern {
  final String userId;
  final List<int> activeHours;
  final List<int> peakEngagementHours;
  final List<int> preferredPushTimes;
  final Map<int, double> weekdayPatterns;
  final Map<String, double> seasonalPatterns;
  final DateTime lastAnalyzed;

  const UserTimePattern({
    required this.userId,
    required this.activeHours,
    required this.peakEngagementHours,
    required this.preferredPushTimes,
    required this.weekdayPatterns,
    required this.seasonalPatterns,
    required this.lastAnalyzed,
  });

  factory UserTimePattern.defaultPattern(String userId) {
    return UserTimePattern(
      userId: userId,
      activeHours: [9, 10, 11, 14, 15, 16, 19, 20],
      peakEngagementHours: [9, 14, 20],
      preferredPushTimes: [9, 12, 15, 20],
      weekdayPatterns: {},
      seasonalPatterns: {},
      lastAnalyzed: DateTime.now(),
    );
  }
}

/// 历史推送数据
class HistoricalPushData {
  final DateTime timestamp;
  final double engagementScore;
  final String eventType;
  final Duration? responseTime;

  const HistoricalPushData({
    required this.timestamp,
    required this.engagementScore,
    required this.eventType,
    this.responseTime,
  });
}

/// 推送时间推荐
class PushTimeRecommendation {
  final DateTime time;
  final double confidence;
  final String reason;

  const PushTimeRecommendation({
    required this.time,
    required this.confidence,
    required this.reason,
  });
}
