import 'dart:async';

import 'package:flutter/material.dart';

import '../models/market_change_event.dart';
import '../models/push_preferences.dart';
import '../models/change_severity.dart';

/// 推送个性化引擎
/// 负责管理用户偏好设置，实现个性化推送策略
class PushPersonalizationEngine {
  final Map<String, UserPreferences> _userPreferencesCache = {};

  /// 个性化权重配置
  static const double _relevanceWeight = 0.4; // 相关性权重
  static const double _urgencyWeight = 0.3; // 紧急性权重
  static const double _userInterestWeight = 0.2; // 用户兴趣权重
  static const double _timingWeight = 0.1; // 时间权重

  PushPersonalizationEngine();

  /// 获取用户偏好设置
  Future<UserPreferences> getUserPreferences(String userId) async {
    if (_userPreferencesCache.containsKey(userId)) {
      return _userPreferencesCache[userId]!;
    }

    // TODO: 从缓存或数据库加载用户偏好
    // 暂时返回默认偏好
    final defaultPreferences = UserPreferences.defaultPreferences(userId);
    _userPreferencesCache[userId] = defaultPreferences;
    return defaultPreferences;
  }

  /// 更新用户偏好设置
  Future<void> updateUserPreferences(
      String userId, UserPreferences preferences) async {
    _userPreferencesCache[userId] = preferences;
    // TODO: 持久化到数据库
  }

  /// 分析用户活跃时段
  Future<UserActivityProfile> analyzeUserActivity(String userId) async {
    // TODO: 分析用户历史活跃数据
    // 暂时返回默认活跃时段
    return UserActivityProfile.defaultProfile(userId);
  }

  /// 生成推送时间推荐
  Future<List<PushTimeRecommendation>> generateTimeRecommendations(
    String userId,
    MarketChangeEvent event,
    UserPreferences preferences,
  ) async {
    final recommendations = <PushTimeRecommendation>[];
    final now = DateTime.now();

    // 立即推送推荐
    recommendations.add(PushTimeRecommendation(
      time: now,
      confidence: 0.8,
      reason: '即时推送',
    ));

    return recommendations;
  }

  /// 学习用户反馈
  Future<void> learnFromFeedback(
    String userId,
    String pushId,
    UserPushFeedback feedback,
  ) async {
    final preferences = await getUserPreferences(userId);

    // 更新用户兴趣模型
    _updateInterestModel(userId, feedback, preferences);

    // 调整推送策略
    _adjustPushStrategy(userId, feedback, preferences);

    // 更新偏好设置
    await updateUserPreferences(userId, preferences);
  }

  /// 获取用户推送洞察
  Future<UserPushInsights> getUserPushInsights(String userId) async {
    // TODO: 从数据库获取历史推送数据和分析结果
    // 暂时返回模拟数据
    return UserPushInsights(
      totalPushes: 0,
      averageOpenRate: 0.0,
      averageResponseTime: Duration.zero,
      mostActiveHours: [9, 14, 20],
      preferredContentTypes: [
        PushContentType.price_change,
        PushContentType.trend_analysis
      ],
      effectivenessScore: 0.0,
    );
  }

  /// 个性化评分
  Future<PushPersonalizationScore> calculatePersonalizationScore(
    String userId,
    MarketChangeEvent event,
    UserPreferences preferences,
  ) async {
    final activityProfile = await analyzeUserActivity(userId);
    final now = DateTime.now();

    // 相关性评分
    final relevanceScore = _calculateRelevanceScore(event, preferences);

    // 紧急性评分
    final urgencyScore = _calculateUrgencyScore(event, preferences);

    // 用户兴趣评分
    final interestScore = _calculateInterestScore(event, preferences);

    // 时间评分
    final timingScore =
        _calculateTimingScore(now, activityProfile, preferences);

    // 计算总分
    final totalScore = (relevanceScore * _relevanceWeight) +
        (urgencyScore * _urgencyWeight) +
        (interestScore * _userInterestWeight) +
        (timingScore * _timingWeight);

    // 生成建议
    final recommendations = <String>[];
    if (relevanceScore < 0.3) {
      recommendations.add('与用户关注点相关性较低');
    }
    if (urgencyScore < 0.5) {
      recommendations.add('紧急程度一般，可考虑延迟推送');
    }
    if (activityProfile.isCurrentlyActive()) {
      recommendations.add('用户当前活跃，适合立即推送');
    } else {
      recommendations.add('建议在下一个活跃时段推送');
    }

    return PushPersonalizationScore(
      totalScore: totalScore,
      relevanceScore: relevanceScore,
      urgencyScore: urgencyScore,
      interestScore: interestScore,
      timingScore: timingScore,
      recommendations: recommendations,
    );
  }

  /// 计算相关性评分
  double _calculateRelevanceScore(
      MarketChangeEvent event, UserPreferences preferences) {
    double score = 0.0;

    // 检查是否在用户关注的基金列表中
    if (event.relatedFunds
        .any((fund) => preferences.watchedFunds.contains(fund))) {
      score += 0.8;
    }

    // 检查是否匹配用户关注的市场
    if (preferences.markets.contains('A股') ||
        preferences.markets.contains('全部')) {
      score += 0.2;
    }

    return score.clamp(0.0, 1.0);
  }

  /// 计算紧急性评分
  double _calculateUrgencyScore(
      MarketChangeEvent event, UserPreferences preferences) {
    switch (event.severity) {
      case ChangeSeverity.high:
        return 0.9;
      case ChangeSeverity.medium:
        return 0.6;
      case ChangeSeverity.low:
        return 0.3;
    }
  }

  /// 计算用户兴趣评分
  double _calculateInterestScore(
      MarketChangeEvent event, UserPreferences preferences) {
    // 基于用户历史行为和偏好计算兴趣评分
    // TODO: 实现基于机器学习的兴趣评分算法
    return 0.7; // 暂时返回默认值
  }

  /// 计算时间评分
  double _calculateTimingScore(
      DateTime now, UserActivityProfile profile, UserPreferences preferences) {
    // 检查是否在静默时段内
    for (final quietHours in preferences.quietHours) {
      if (quietHours.enabled) {
        // TODO: 实现静默时段检查逻辑
      }
    }

    // 检查用户是否活跃
    if (profile.isCurrentlyActive()) {
      return 0.8;
    } else {
      return 0.4;
    }
  }

  /// 生成个性化标题
  String _generatePersonalizedTitle(
      MarketChangeEvent event, UserPreferences preferences) {
    final entityName = event.entityName;

    switch (preferences.titleStyle) {
      case TitleStyle.technical:
        return '$entityName ${event.changeDescription}';
      case TitleStyle.concise:
        return '$entityName 变化提醒';
      case TitleStyle.detailed:
        return '${event.severityDescription}：$entityName 发生${event.changeDescription}';
      case TitleStyle.friendly:
        return '您的关注基金 $entityName 有新变化';
    }
  }

  /// 生成个性化内容
  String _generatePersonalizedBody(
    MarketChangeEvent event,
    List<RelatedFundInfo>? correlation,
    UserPreferences preferences,
  ) {
    final buffer = StringBuffer();

    // 基础变化信息
    buffer.writeln(
        '${event.entityName} ${event.trend}${event.changeDescription}');

    // 当前值信息
    if (event.currentValue.isNotEmpty) {
      buffer.writeln('当前净值：${event.currentValue}');
    }

    // 相关影响分析 - 简化实现
    if (preferences.includeImpactAnalysis) {
      buffer.writeln('\n影响分析:');
      buffer.writeln('• 相关市场可能受到影响');
    }

    // 个人化建议
    if (preferences.includeRecommendations) {
      buffer.writeln(
          '\n${_generatePersonalizedRecommendation(event, preferences)}');
    }

    return buffer.toString().trim();
  }

  /// 生成个性化建议
  String _generatePersonalizedRecommendation(
      MarketChangeEvent event, UserPreferences preferences) {
    switch (preferences.investmentStyle) {
      case InvestmentStyle.conservative:
        return '建议关注此变化的风险影响，谨慎决策。';
      case InvestmentStyle.balanced:
        return '建议评估此变化对投资组合的影响。';
      case InvestmentStyle.aggressive:
        return '可考虑此变化带来的投资机会。';
      case InvestmentStyle.speculative:
        return '值得关注的市场变化，可能存在机会。';
      case null:
        return '建议关注此变化的影响。';
    }
  }

  /// 生成操作按钮文本
  String _generateActionText(
      MarketChangeEvent event, UserPreferences preferences) {
    switch (preferences.callToActionStyle) {
      case CallToActionStyle.view_details:
        return '查看详情';
      case CallToActionStyle.analyze:
        return '立即分析';
      case CallToActionStyle.trade:
        return '交易操作';
      case CallToActionStyle.none:
        return '';
    }
  }

  /// 确定个性化优先级
  PushPriority _determinePersonalizedPriority(
      MarketChangeEvent event, UserPreferences preferences) {
    // 基于用户偏好调整优先级
    if (!preferences.enableHighPriorityPushes) {
      return PushPriority.low;
    }

    // 基于事件原始严重性
    switch (event.severity) {
      case ChangeSeverity.high:
        return PushPriority.high;
      case ChangeSeverity.medium:
        return PushPriority.medium;
      case ChangeSeverity.low:
        return PushPriority.low;
    }
  }

  /// 更新兴趣模型
  void _updateInterestModel(
      String userId, UserPushFeedback feedback, UserPreferences preferences) {
    // TODO: 实现机器学习模型更新
    // 基于用户反馈调整兴趣权重
  }

  /// 调整推送策略
  void _adjustPushStrategy(
      String userId, UserPushFeedback feedback, UserPreferences preferences) {
    switch (feedback.action) {
      case UserPushAction.opened:
        // 用户打开推送，增强相关类型的推送频率
        break;
      case UserPushAction.dismissed:
        // 用户忽略推送，降低相关类型的推送频率
        break;
      case UserPushAction.muted:
        // 用户静音推送，大幅降低推送频率
        break;
      case UserPushAction.blocked:
        // 用户屏蔽推送，停止推送
        break;
    }
  }

  /// 清理缓存
  void clearCache() {
    _userPreferencesCache.clear();
  }
}

/// 用户活跃时段画像
class UserActivityProfile {
  final String userId;
  final List<ActivePeriod> activePeriods;
  final List<QuietPeriod> quietPeriods;
  final Map<int, double> hourlyActivityScore;
  final Map<int, double> dailyActivityScore;

  const UserActivityProfile({
    required this.userId,
    required this.activePeriods,
    required this.quietPeriods,
    required this.hourlyActivityScore,
    required this.dailyActivityScore,
  });

  factory UserActivityProfile.defaultProfile(String userId) {
    return UserActivityProfile(
      userId: userId,
      activePeriods: [
        const ActivePeriod(
            start: TimeOfDay(hour: 9, minute: 0),
            end: TimeOfDay(hour: 11, minute: 30)),
        const ActivePeriod(
            start: TimeOfDay(hour: 14, minute: 0),
            end: TimeOfDay(hour: 17, minute: 30)),
        const ActivePeriod(
            start: TimeOfDay(hour: 19, minute: 0),
            end: TimeOfDay(hour: 21, minute: 0)),
      ],
      quietPeriods: [
        const QuietPeriod(
            start: TimeOfDay(hour: 22, minute: 0),
            end: TimeOfDay(hour: 7, minute: 0)),
      ],
      hourlyActivityScore: {},
      dailyActivityScore: {},
    );
  }

  bool isCurrentlyActive() {
    final now =
        TimeOfDay(hour: DateTime.now().hour, minute: DateTime.now().minute);
    return activePeriods.any((period) => period.isActiveAt(now));
  }
}

/// 活跃时段
class ActivePeriod {
  final TimeOfDay start;
  final TimeOfDay end;

  const ActivePeriod({required this.start, required this.end});

  bool isActiveAt(TimeOfDay time) {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    final currentMinutes = time.hour * 60 + time.minute;

    if (startMinutes <= endMinutes) {
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } else {
      // 跨午夜的情况
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
  }
}

/// 静默时段
class QuietPeriod {
  final TimeOfDay start;
  final TimeOfDay end;

  const QuietPeriod({required this.start, required this.end});

  bool isActiveAt(TimeOfDay time) {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    final currentMinutes = time.hour * 60 + time.minute;

    if (startMinutes <= endMinutes) {
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } else {
      // 跨午夜的情况
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
  }
}

/// 用户推送洞察
class UserPushInsights {
  final int totalPushes;
  final double averageOpenRate;
  final Duration averageResponseTime;
  final List<int> mostActiveHours;
  final List<PushContentType> preferredContentTypes;
  final double effectivenessScore;

  const UserPushInsights({
    required this.totalPushes,
    required this.averageOpenRate,
    required this.averageResponseTime,
    required this.mostActiveHours,
    required this.preferredContentTypes,
    required this.effectivenessScore,
  });
}

/// 用户推送反馈动作
enum UserPushAction {
  opened,
  dismissed,
  muted,
  blocked,
}

/// 用户推送反馈
class UserPushFeedback {
  final String pushId;
  final UserPushAction action;
  final DateTime timestamp;
  final Duration? responseTime;
  final String? feedbackText;

  const UserPushFeedback({
    required this.pushId,
    required this.action,
    required this.timestamp,
    this.responseTime,
    this.feedbackText,
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

/// 推送个性化评分
class PushPersonalizationScore {
  final double totalScore;
  final double relevanceScore;
  final double urgencyScore;
  final double interestScore;
  final double timingScore;
  final List<String> recommendations;

  const PushPersonalizationScore({
    required this.totalScore,
    required this.relevanceScore,
    required this.urgencyScore,
    required this.interestScore,
    required this.timingScore,
    required this.recommendations,
  });

  bool get shouldPush => totalScore >= 0.5;

  @override
  String toString() {
    return 'PushPersonalizationScore(total: $totalScore, relevance: $relevanceScore, urgency: $urgencyScore, interest: $interestScore, timing: $timingScore)';
  }
}

/// 相关基金信息
class RelatedFundInfo {
  final String fundCode;
  final String fundName;
  final String correlationReason;
  final double correlationScore;

  const RelatedFundInfo({
    required this.fundCode,
    required this.fundName,
    required this.correlationReason,
    required this.correlationScore,
  });
}
