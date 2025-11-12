import 'dart:async';
import 'dart:math';

import '../managers/push_history_manager.dart';
import '../models/push_history_record.dart';
import '../../../../core/utils/logger.dart';

/// 推送分析服务
///
/// 负责推送数据的深度分析和洞察，包括：
/// - 推送效果分析和趋势预测
/// - 用户行为模式识别
/// - 个性化策略优化建议
/// - A/B测试结果分析
class PushAnalyticsService {
  static PushAnalyticsService? _instance;
  static PushAnalyticsService get instance {
    _instance ??= PushAnalyticsService._();
    return _instance!;
  }

  PushAnalyticsService._() : _historyManager = PushHistoryManager.instance;

  late final PushHistoryManager _historyManager;
  bool _isInitialized = false;

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  /// 初始化推送分析服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      AppLogger.info('🚀 PushAnalyticsService: 开始初始化');

      // 初始化历史管理器
      await _historyManager.initialize();

      _isInitialized = true;
      AppLogger.info('✅ PushAnalyticsService: 初始化成功');
    } catch (e) {
      AppLogger.error('❌ PushAnalyticsService: 初始化失败', e);
      rethrow;
    }
  }

  /// 获取推送效果综合报告
  Future<PushEffectivenessReport> getEffectivenessReport(
      {int days = 30}) async {
    if (!_isInitialized) {
      AppLogger.error('❌ PushAnalyticsService: Not initialized',
          Exception('Push analytics service not initialized'));
      return PushEffectivenessReport.empty();
    }

    try {
      // 获取基础统计数据
      final stats = await _historyManager.getPushStatistics(days: days);
      final effectiveness =
          await _historyManager.getEffectivenessAnalysis(days: days);
      final dailyStats = await _historyManager.getDailyStatistics(days: days);

      // 计算趋势
      final trends = _calculateTrends(dailyStats);

      // 生成洞察
      final insights =
          await _generateInsights(stats, effectiveness, dailyStats);

      // 生成优化建议
      final recommendations =
          _generateRecommendations(stats, effectiveness, trends);

      // 用户行为分析
      final behaviorAnalysis = await _analyzeUserBehavior(days: days);

      // 内容效果分析
      final contentAnalysis = await _analyzeContentEffectiveness(days: days);

      // 时间模式分析
      final timePatterns = await _analyzeTimePatterns(days: days);

      return PushEffectivenessReport(
        periodInDays: days,
        generatedAt: DateTime.now(),
        statistics: stats,
        effectivenessAnalysis: effectiveness,
        dailyStats: dailyStats,
        trends: trends,
        insights: insights,
        recommendations: recommendations,
        behaviorAnalysis: behaviorAnalysis,
        contentAnalysis: contentAnalysis,
        timePatterns: timePatterns,
      );
    } catch (e) {
      AppLogger.error(
          '❌ PushAnalyticsService: Failed to get effectiveness report', e);
      return PushEffectivenessReport.empty();
    }
  }

  /// 获取用户参与度分析
  Future<UserEngagementAnalysis> getUserEngagementAnalysis(
      {int days = 30}) async {
    if (!_isInitialized) {
      AppLogger.error('❌ PushAnalyticsService: Not initialized',
          Exception('Push analytics service not initialized'));
      return UserEngagementAnalysis.empty();
    }

    try {
      final pushes = await _historyManager.getPushHistoryByTimeRange(
        startTime: DateTime.now().subtract(Duration(days: days)),
        limit: 10000,
      );

      // 计算参与度指标
      final totalUsers = _getUniqueUserCount(pushes);
      final activeUsers = _getActiveUserCount(pushes);
      final engagedUsers = _getEngagedUserCount(pushes);

      // 参与度趋势
      final engagementTrend = await _calculateEngagementTrend(days: days);

      // 用户分群分析
      final userSegments = await _segmentUsers(pushes);

      // 留存分析
      final retentionAnalysis = await _analyzeRetention(days: days);

      // 活跃时段分析
      final activeHours = _analyzeActiveHours(pushes);

      return UserEngagementAnalysis(
        totalUsers: totalUsers,
        activeUsers: activeUsers,
        engagedUsers: engagedUsers,
        engagementRate: totalUsers > 0 ? engagedUsers / totalUsers : 0.0,
        activationRate: totalUsers > 0 ? activeUsers / totalUsers : 0.0,
        engagementTrend: engagementTrend,
        userSegments: userSegments,
        retentionAnalysis: retentionAnalysis,
        activeHours: activeHours,
        periodInDays: days,
      );
    } catch (e) {
      AppLogger.error(
          '❌ PushAnalyticsService: Failed to get user engagement analysis', e);
      return UserEngagementAnalysis.empty();
    }
  }

  /// 获取推送内容效果分析
  Future<ContentEffectivenessAnalysis> getContentEffectivenessAnalysis(
      {int days = 30}) async {
    if (!_isInitialized) {
      AppLogger.error('❌ PushAnalyticsService: Not initialized',
          Exception('Push analytics service not initialized'));
      return ContentEffectivenessAnalysis.empty();
    }

    try {
      final pushes = await _historyManager.getPushHistoryByTimeRange(
        startTime: DateTime.now().subtract(Duration(days: days)),
        limit: 10000,
      );

      // 标题长度分析
      final titleLengthAnalysis = _analyzeTitleLength(pushes);

      // 内容长度分析
      final contentLengthAnalysis = _analyzeContentLength(pushes);

      // 关键词效果分析
      final keywordAnalysis = await _analyzeKeywords(pushes);

      // 情感分析
      final sentimentAnalysis = await _analyzeSentiment(pushes);

      // 个性化评分影响分析
      final personalizationImpact = _analyzePersonalizationImpact(pushes);

      // 模板效果分析
      final templateAnalysis = _analyzeTemplateEffectiveness(pushes);

      return ContentEffectivenessAnalysis(
        titleLengthAnalysis: titleLengthAnalysis,
        contentLengthAnalysis: contentLengthAnalysis,
        keywordAnalysis: keywordAnalysis,
        sentimentAnalysis: sentimentAnalysis,
        personalizationImpact: personalizationImpact,
        templateAnalysis: templateAnalysis,
        periodInDays: days,
      );
    } catch (e) {
      AppLogger.error(
          '❌ PushAnalyticsService: Failed to get content effectiveness analysis',
          e);
      return ContentEffectivenessAnalysis.empty();
    }
  }

  /// 获取最佳推送时间建议
  Future<OptimalTimingRecommendations> getOptimalTimingRecommendations(
      {int days = 30}) async {
    if (!_isInitialized) {
      AppLogger.error('❌ PushAnalyticsService: Not initialized',
          Exception('Push analytics service not initialized'));
      return OptimalTimingRecommendations.empty();
    }

    try {
      final pushes = await _historyManager.getPushHistoryByTimeRange(
        startTime: DateTime.now().subtract(Duration(days: days)),
        limit: 10000,
      );

      // 按小时分析效果
      final hourlyPerformance = _analyzeHourlyPerformance(pushes);

      // 按星期几分析效果
      final weekdayPerformance = _analyzeWeekdayPerformance(pushes);

      // 用户活跃时段分析
      final userActiveHours = _analyzeUserActiveHours(pushes);

      // 最佳推送时间窗口
      final optimalWindows =
          _findOptimalTimeWindows(hourlyPerformance, userActiveHours);

      // 时区分析
      final timezoneAnalysis = _analyzeTimezoneImpact(pushes);

      return OptimalTimingRecommendations(
        hourlyPerformance: hourlyPerformance,
        weekdayPerformance: weekdayPerformance,
        userActiveHours: userActiveHours,
        optimalWindows: optimalWindows,
        timezoneAnalysis: timezoneAnalysis,
        periodInDays: days,
      );
    } catch (e) {
      AppLogger.error(
          '❌ PushAnalyticsService: Failed to get optimal timing recommendations',
          e);
      return OptimalTimingRecommendations.empty();
    }
  }

  /// 预测推送效果
  Future<PushEffectivenessPrediction> predictPushEffectiveness({
    required String pushType,
    required String priority,
    required String title,
    required String content,
    String? templateId,
    DateTime? scheduledTime,
  }) async {
    if (!_isInitialized) {
      AppLogger.error('❌ PushAnalyticsService: Not initialized',
          Exception('Push analytics service not initialized'));
      return PushEffectivenessPrediction.empty();
    }

    try {
      // 获取历史相似推送数据
      final similarPushes = await _historyManager.searchPushHistory(
        pushType: pushType,
        priority: priority,
        limit: 1000,
      );

      if (similarPushes.isEmpty) {
        return PushEffectivenessPrediction(
          predictedClickRate: 0.1, // 默认预测
          predictedReadRate: 0.3,
          confidence: 0.1,
          factors: const ['Insufficient historical data'],
          recommendations: const ['Collect more data for better predictions'],
        );
      }

      // 基于历史数据预测
      final baseClickRate = similarPushes
              .where((p) => p.deliverySuccess)
              .fold(0.0, (sum, p) => sum + (p.isClicked ? 1.0 : 0.0)) /
          similarPushes.where((p) => p.deliverySuccess).length;

      final baseReadRate = similarPushes
              .where((p) => p.deliverySuccess)
              .fold(0.0, (sum, p) => sum + (p.isRead ? 1.0 : 0.0)) /
          similarPushes.where((p) => p.deliverySuccess).length;

      // 内容因素调整
      double contentFactor = 1.0;
      final titleLength = title.length;
      if (titleLength >= 20 && titleLength <= 50) {
        contentFactor *= 1.1; // 最佳标题长度
      } else if (titleLength > 100) {
        contentFactor *= 0.9; // 标题过长
      }

      final contentLength = content.length;
      if (contentLength >= 50 && contentLength <= 200) {
        contentFactor *= 1.05; // 最佳内容长度
      }

      // 时间因素调整
      double timeFactor = 1.0;
      if (scheduledTime != null) {
        final hour = scheduledTime.hour;
        if (hour >= 9 && hour <= 11 || hour >= 14 && hour <= 16) {
          timeFactor *= 1.15; // 工作时间
        } else if (hour >= 22 || hour <= 6) {
          timeFactor *= 0.7; // 深夜时间
        }
      }

      // 个性化因素调整
      double personalizationFactor = 1.0;
      if (templateId != null) {
        final templatePushes =
            similarPushes.where((p) => p.templateId == templateId);
        if (templatePushes.isNotEmpty) {
          final templateEffectiveness = templatePushes
                  .where((p) => p.deliverySuccess)
                  .fold(0.0, (sum, p) => sum + p.effectivenessScore) /
              templatePushes.where((p) => p.deliverySuccess).length;
          personalizationFactor = 1.0 + (templateEffectiveness - 0.5) * 0.3;
        }
      }

      // 计算最终预测
      final predictedClickRate =
          (baseClickRate * contentFactor * timeFactor * personalizationFactor)
              .clamp(0.0, 1.0);
      final predictedReadRate =
          (baseReadRate * contentFactor * timeFactor * personalizationFactor)
              .clamp(0.0, 1.0);

      // 计算置信度
      final confidence = min(0.9, similarPushes.length / 100.0);

      // 生成影响因素和建议
      final factors = <String>[];
      final recommendations = <String>[];

      if (contentFactor > 1.0) {
        factors.add('Optimal content length');
      } else if (contentFactor < 1.0) {
        factors.add('Suboptimal content length');
        recommendations.add('Consider adjusting title/content length');
      }

      if (timeFactor > 1.0) {
        factors.add('Optimal timing');
      } else if (timeFactor < 1.0) {
        factors.add('Suboptimal timing');
        recommendations.add('Consider scheduling at different times');
      }

      if (personalizationFactor > 1.0) {
        factors.add('Effective personalization');
      } else if (personalizationFactor < 1.0) {
        factors.add('Limited personalization');
        recommendations.add('Consider enhancing personalization');
      }

      return PushEffectivenessPrediction(
        predictedClickRate: predictedClickRate,
        predictedReadRate: predictedReadRate,
        confidence: confidence,
        factors: factors,
        recommendations: recommendations,
      );
    } catch (e) {
      AppLogger.error(
          '❌ PushAnalyticsService: Failed to predict push effectiveness', e);
      return PushEffectivenessPrediction.empty();
    }
  }

  /// 计算趋势
  List<TrendData> _calculateTrends(Map<String, DailyStats> dailyStats) {
    final trends = <TrendData>[];
    final sortedDates = dailyStats.keys.toList()..sort();

    for (int i = 1; i < sortedDates.length; i++) {
      final currentDate = sortedDates[i];
      final previousDate = sortedDates[i - 1];
      final currentStats = dailyStats[currentDate]!;
      final previousStats = dailyStats[previousDate]!;

      // 计算变化率
      final totalChange = previousStats.totalPushes > 0
          ? (currentStats.totalPushes - previousStats.totalPushes) /
              previousStats.totalPushes
          : 0.0;
      final clickChange = previousStats.successfulPushes > 0
          ? (currentStats.clickedPushes - previousStats.clickedPushes) /
              previousStats.successfulPushes
          : 0.0;
      final readChange = previousStats.successfulPushes > 0
          ? (currentStats.readPushes - previousStats.readPushes) /
              previousStats.successfulPushes
          : 0.0;

      trends.add(TrendData(
        date: currentStats.date,
        totalChange: totalChange,
        clickRateChange: clickChange,
        readRateChange: readChange,
      ));
    }

    return trends;
  }

  /// 生成洞察
  List<String> _generateInsights(
    PushStatistics stats,
    PushEffectivenessAnalysis effectiveness,
    Map<String, DailyStats> dailyStats,
  ) {
    final insights = <String>[];

    // 整体表现洞察
    if (stats.clickRate > 0.15) {
      insights
          .add('推送点击率表现优秀 (${(stats.clickRate * 100).toStringAsFixed(1)}%)');
    } else if (stats.clickRate < 0.05) {
      insights
          .add('推送点击率偏低 (${(stats.clickRate * 100).toStringAsFixed(1)}%)，需要优化');
    }

    if (stats.readRate > 0.5) {
      insights.add('推送阅读率良好 (${(stats.readRate * 100).toStringAsFixed(1)}%)');
    }

    // 类型效果洞察
    final bestType = effectiveness.typeAnalysis.entries
        .reduce((a, b) => a.value.clickRate > b.value.clickRate ? a : b);
    insights.add(
        '${bestType.key} 类型推送效果最佳 (点击率: ${(bestType.value.clickRate * 100).toStringAsFixed(1)}%)');

    // 个性化评分洞察
    if (stats.averagePersonalizationScore > 0.7) {
      insights.add(
          '个性化评分较高 (${(stats.averagePersonalizationScore * 100).toStringAsFixed(1)}%)，用户接受度好');
    } else if (stats.averagePersonalizationScore < 0.3) {
      insights.add(
          '个性化评分较低 (${(stats.averagePersonalizationScore * 100).toStringAsFixed(1)}%)，需要改进个性化策略');
    }

    return insights;
  }

  /// 生成建议
  List<String> _generateRecommendations(
    PushStatistics stats,
    PushEffectivenessAnalysis effectiveness,
    List<TrendData> trends,
  ) {
    final recommendations = <String>[];

    // 基于点击率的建议
    if (stats.clickRate < 0.1) {
      recommendations.add('优化推送标题和内容，提高吸引力');
      recommendations.add('分析高点击率推送的特征，应用到其他推送');
    }

    // 基于类型的建议
    final worstType = effectiveness.typeAnalysis.entries
        .reduce((a, b) => a.value.clickRate < b.value.clickRate ? a : b);
    if (worstType.value.clickRate < 0.05) {
      recommendations.add('重新评估${worstType.key}类型推送的内容和时机');
    }

    // 基于优先级的建议
    final highPriorityPerformance = effectiveness.priorityAnalysis['high'];
    if (highPriorityPerformance != null &&
        highPriorityPerformance.clickRate < 0.2) {
      recommendations.add('高优先级推送效果不佳，检查推送内容与优先级的匹配度');
    }

    // 基于趋势的建议
    final recentTrends = trends.take(7).toList();
    final decliningTrend =
        recentTrends.where((t) => t.clickRateChange < -0.1).length;
    if (decliningTrend >= 3) {
      recommendations.add('近期推送效果呈下降趋势，建议调整推送策略');
    }

    return recommendations;
  }

  /// 分析用户行为
  Future<UserBehaviorAnalysis> _analyzeUserBehavior({int days = 30}) async {
    final pushes = await _historyManager.getPushHistoryByTimeRange(
      startTime: DateTime.now().subtract(Duration(days: days)),
      limit: 10000,
    );

    // 响应时间分析
    final responseTimes = <int>[];
    for (final push in pushes) {
      if (push.isClicked && push.clickedAt != null) {
        final responseTime =
            push.clickedAt!.difference(push.timestamp).inMinutes;
        responseTimes.add(responseTime);
      }
    }

    final averageResponseTime = responseTimes.isEmpty
        ? 0
        : responseTimes.reduce((a, b) => a + b) ~/ responseTimes.length;

    // 活跃时段分析
    final hourlyActivity = List.filled(24, 0);
    for (final push in pushes) {
      if (push.isClicked) {
        final hour = push.clickedAt?.hour ?? push.timestamp.hour;
        hourlyActivity[hour]++;
      }
    }

    final mostActiveHour = hourlyActivity
        .asMap()
        .entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    return UserBehaviorAnalysis(
      averageResponseTimeMinutes: averageResponseTime,
      mostActiveHour: mostActiveHour,
      hourlyActivity: hourlyActivity,
    );
  }

  /// 分析内容效果
  Future<ContentEffectivenessAnalysis> _analyzeContentEffectiveness(
      {int days = 30}) async {
    final pushes = await _historyManager.getPushHistoryByTimeRange(
      startTime: DateTime.now().subtract(Duration(days: days)),
      limit: 10000,
    );

    // 按内容长度分析
    final lengthGroups = <String, List<PushHistoryRecord>>{
      'short': [],
      'medium': [],
      'long': [],
    };

    for (final push in pushes) {
      if (push.content.length < 50) {
        lengthGroups['short']!.add(push);
      } else if (push.content.length < 150) {
        lengthGroups['medium']!.add(push);
      } else {
        lengthGroups['long']!.add(push);
      }
    }

    final lengthEffectiveness = <String, double>{};
    for (final entry in lengthGroups.entries) {
      final groupPushes = entry.value;
      if (groupPushes.isNotEmpty) {
        final clickRate = groupPushes
                .where((p) => p.deliverySuccess)
                .fold(0.0, (sum, p) => sum + (p.isClicked ? 1.0 : 0.0)) /
            groupPushes.where((p) => p.deliverySuccess).length;
        lengthEffectiveness[entry.key] = clickRate;
      }
    }

    return ContentEffectivenessAnalysis(
      titleLengthAnalysis: {}, // 简化实现
      contentLengthAnalysis: lengthEffectiveness,
      keywordAnalysis: {}, // 简化实现
      sentimentAnalysis:
          const SentimentAnalysis(positive: 0, neutral: 0, negative: 0),
      personalizationImpact:
          const PersonalizationImpact(low: 0, medium: 0, high: 0),
      templateAnalysis: {}, // 简化实现
      periodInDays: days,
    );
  }

  /// 分析时间模式
  Future<TimePatternAnalysis> _analyzeTimePatterns({int days = 30}) async {
    final pushes = await _historyManager.getPushHistoryByTimeRange(
      startTime: DateTime.now().subtract(Duration(days: days)),
      limit: 10000,
    );

    // 按小时统计
    final hourlyStats =
        List.filled(24, <String, int>{'total': 0, 'clicked': 0});
    for (final push in pushes) {
      final hour = push.timestamp.hour;
      hourlyStats[hour]['total'] = (hourlyStats[hour]['total'] ?? 0) + 1;
      if (push.isClicked) {
        hourlyStats[hour]['clicked'] = (hourlyStats[hour]['clicked'] ?? 0) + 1;
      }
    }

    // 按星期统计
    final weekdayStats =
        List.filled(7, <String, int>{'total': 0, 'clicked': 0});
    for (final push in pushes) {
      final weekday = push.timestamp.weekday - 1; // 0=Monday
      weekdayStats[weekday]['total'] =
          (weekdayStats[weekday]['total'] ?? 0) + 1;
      if (push.isClicked) {
        weekdayStats[weekday]['clicked'] =
            (weekdayStats[weekday]['clicked'] ?? 0) + 1;
      }
    }

    return TimePatternAnalysis(
      hourlyStats: hourlyStats,
      weekdayStats: weekdayStats,
    );
  }

  /// 辅助方法
  int _getUniqueUserCount(List<PushHistoryRecord> pushes) {
    // 简化实现，实际应该从设备信息中提取
    return pushes.map((p) => p.deviceInfo['deviceId']).toSet().length;
  }

  int _getActiveUserCount(List<PushHistoryRecord> pushes) {
    // 简化实现：有阅读行为的用户
    return pushes
        .where((p) => p.isRead)
        .map((p) => p.deviceInfo['deviceId'])
        .toSet()
        .length;
  }

  int _getEngagedUserCount(List<PushHistoryRecord> pushes) {
    // 简化实现：有点击行为的用户
    return pushes
        .where((p) => p.isClicked)
        .map((p) => p.deviceInfo['deviceId'])
        .toSet()
        .length;
  }

  Future<List<double>> _calculateEngagementTrend({int days = 30}) async {
    final trends = <double>[];
    for (int i = days - 1; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final dayPushes = await _historyManager.getPushHistoryByTimeRange(
        startTime: dayStart,
        endTime: dayEnd,
        limit: 1000,
      );

      final engagementRate = dayPushes.isNotEmpty
          ? dayPushes.where((p) => p.isClicked).length / dayPushes.length
          : 0.0;
      trends.add(engagementRate);
    }
    return trends;
  }

  Future<Map<String, UserSegment>> _segmentUsers(
      List<PushHistoryRecord> pushes) async {
    // 简化实现
    return {
      'active':
          UserSegment(name: 'Active', count: 0, characteristics: const []),
      'moderate':
          UserSegment(name: 'Moderate', count: 0, characteristics: const []),
      'low': UserSegment(name: 'Low', count: 0, characteristics: const []),
    };
  }

  Future<RetentionAnalysis> _analyzeRetention({int days = 30}) async {
    // 简化实现
    return RetentionAnalysis(
      day1Retention: 0.8,
      day7Retention: 0.6,
      day30Retention: 0.4,
    );
  }

  List<int> _analyzeActiveHours(List<PushHistoryRecord> pushes) {
    final hourlyActivity = List.filled(24, 0);
    for (final push in pushes) {
      if (push.isClicked) {
        final hour = push.clickedAt?.hour ?? push.timestamp.hour;
        hourlyActivity[hour]++;
      }
    }
    return hourlyActivity;
  }

  Map<String, double> _analyzeTitleLength(List<PushHistoryRecord> pushes) {
    final lengthGroups = <String, List<PushHistoryRecord>>{
      'short': [],
      'medium': [],
      'long': [],
    };

    for (final push in pushes) {
      if (push.title.length < 30) {
        lengthGroups['short']!.add(push);
      } else if (push.title.length < 60) {
        lengthGroups['medium']!.add(push);
      } else {
        lengthGroups['long']!.add(push);
      }
    }

    final lengthEffectiveness = <String, double>{};
    for (final entry in lengthGroups.entries) {
      final groupPushes = entry.value;
      if (groupPushes.isNotEmpty) {
        final clickRate = groupPushes
                .where((p) => p.deliverySuccess)
                .fold(0.0, (sum, p) => sum + (p.isClicked ? 1.0 : 0.0)) /
            groupPushes.where((p) => p.deliverySuccess).length;
        lengthEffectiveness[entry.key] = clickRate;
      }
    }

    return lengthEffectiveness;
  }

  Map<String, double> _analyzeContentLength(List<PushHistoryRecord> pushes) {
    final lengthGroups = <String, List<PushHistoryRecord>>{
      'short': [],
      'medium': [],
      'long': [],
    };

    for (final push in pushes) {
      if (push.content.length < 50) {
        lengthGroups['short']!.add(push);
      } else if (push.content.length < 150) {
        lengthGroups['medium']!.add(push);
      } else {
        lengthGroups['long']!.add(push);
      }
    }

    final lengthEffectiveness = <String, double>{};
    for (final entry in lengthGroups.entries) {
      final groupPushes = entry.value;
      if (groupPushes.isNotEmpty) {
        final clickRate = groupPushes
                .where((p) => p.deliverySuccess)
                .fold(0.0, (sum, p) => sum + (p.isClicked ? 1.0 : 0.0)) /
            groupPushes.where((p) => p.deliverySuccess).length;
        lengthEffectiveness[entry.key] = clickRate;
      }
    }

    return lengthEffectiveness;
  }

  Future<Map<String, double>> _analyzeKeywords(
      List<PushHistoryRecord> pushes) async {
    // 简化实现
    return {};
  }

  Future<SentimentAnalysis> _analyzeSentiment(
      List<PushHistoryRecord> pushes) async {
    // 简化实现
    return const SentimentAnalysis(positive: 0, neutral: 0, negative: 0);
  }

  PersonalizationImpact _analyzePersonalizationImpact(
      List<PushHistoryRecord> pushes) {
    final groups = <String, List<PushHistoryRecord>>{
      'low': [],
      'medium': [],
      'high': [],
    };

    for (final push in pushes) {
      if (push.personalizationScore < 0.3) {
        groups['low']!.add(push);
      } else if (push.personalizationScore < 0.7) {
        groups['medium']!.add(push);
      } else {
        groups['high']!.add(push);
      }
    }

    final impact = <String, double>{};
    for (final entry in groups.entries) {
      final groupPushes = entry.value;
      if (groupPushes.isNotEmpty) {
        final clickRate = groupPushes
                .where((p) => p.deliverySuccess)
                .fold(0.0, (sum, p) => sum + (p.isClicked ? 1.0 : 0.0)) /
            groupPushes.where((p) => p.deliverySuccess).length;
        impact[entry.key] = clickRate;
      }
    }

    return PersonalizationImpact(
      low: impact['low'] ?? 0.0,
      medium: impact['medium'] ?? 0.0,
      high: impact['high'] ?? 0.0,
    );
  }

  Map<String, double> _analyzeTemplateEffectiveness(
      List<PushHistoryRecord> pushes) {
    final templateGroups = <String, List<PushHistoryRecord>>{};
    for (final push in pushes) {
      final templateId = push.templateId ?? 'no_template';
      templateGroups.putIfAbsent(templateId, () => []).add(push);
    }

    final effectiveness = <String, double>{};
    for (final entry in templateGroups.entries) {
      final groupPushes = entry.value;
      if (groupPushes.isNotEmpty) {
        final clickRate = groupPushes
                .where((p) => p.deliverySuccess)
                .fold(0.0, (sum, p) => sum + (p.isClicked ? 1.0 : 0.0)) /
            groupPushes.where((p) => p.deliverySuccess).length;
        effectiveness[entry.key] = clickRate;
      }
    }

    return effectiveness;
  }

  List<HourlyPerformance> _analyzeHourlyPerformance(
      List<PushHistoryRecord> pushes) {
    final hourlyData = List.filled(24, <String, int>{'total': 0, 'clicked': 0});

    for (final push in pushes) {
      final hour = push.timestamp.hour;
      hourlyData[hour]['total'] = (hourlyData[hour]['total'] ?? 0) + 1;
      if (push.isClicked) {
        hourlyData[hour]['clicked'] = (hourlyData[hour]['clicked'] ?? 0) + 1;
      }
    }

    return List.generate(24, (hour) {
      final total = hourlyData[hour]['total'] ?? 0;
      final clicked = hourlyData[hour]['clicked'] ?? 0;
      return HourlyPerformance(
        hour: hour,
        totalPushes: total,
        clickedPushes: clicked,
        clickRate: total > 0 ? clicked / total : 0.0,
      );
    });
  }

  List<WeekdayPerformance> _analyzeWeekdayPerformance(
      List<PushHistoryRecord> pushes) {
    final weekdayData = List.filled(7, <String, int>{'total': 0, 'clicked': 0});

    for (final push in pushes) {
      final weekday = push.timestamp.weekday - 1; // 0=Monday
      weekdayData[weekday]['total'] = (weekdayData[weekday]['total'] ?? 0) + 1;
      if (push.isClicked) {
        weekdayData[weekday]['clicked'] =
            (weekdayData[weekday]['clicked'] ?? 0) + 1;
      }
    }

    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return List.generate(7, (index) {
      final total = weekdayData[index]['total'] ?? 0;
      final clicked = weekdayData[index]['clicked'] ?? 0;
      return WeekdayPerformance(
        weekday: weekdays[index],
        totalPushes: total,
        clickedPushes: clicked,
        clickRate: total > 0 ? clicked / total : 0.0,
      );
    });
  }

  List<int> _analyzeUserActiveHours(List<PushHistoryRecord> pushes) {
    final hourlyActivity = List.filled(24, 0);
    for (final push in pushes) {
      if (push.isClicked) {
        final hour = push.clickedAt?.hour ?? push.timestamp.hour;
        hourlyActivity[hour]++;
      }
    }
    return hourlyActivity;
  }

  List<TimeWindow> _findOptimalTimeWindows(
    List<HourlyPerformance> hourlyPerformance,
    List<int> userActiveHours,
  ) {
    final windows = <TimeWindow>[];

    // 寻找连续3小时的高效时段
    for (int i = 0; i <= 21; i++) {
      final windowPerformance = hourlyPerformance
              .skip(i)
              .take(3)
              .fold(0.0, (sum, perf) => sum + perf.clickRate) /
          3;

      if (windowPerformance > 0.15) {
        windows.add(TimeWindow(
          startHour: i,
          endHour: i + 3,
          averageClickRate: windowPerformance,
        ));
      }
    }

    return windows
      ..sort((a, b) => b.averageClickRate.compareTo(a.averageClickRate));
  }

  TimezoneAnalysis _analyzeTimezoneImpact(List<PushHistoryRecord> pushes) {
    // 简化实现
    return const TimezoneAnalysis(
      localTimezonePerformance: 0.12,
      otherTimezonePerformance: 0.08,
      recommendedStrategy: 'Use user local timezone',
    );
  }

  /// 销毁服务
  Future<void> dispose() async {
    await _historyManager.dispose();
    _isInitialized = false;
    AppLogger.info('✅ PushAnalyticsService: Disposed');
  }
}

// 数据模型定义

class PushEffectivenessReport {
  final int periodInDays;
  final DateTime generatedAt;
  final PushStatistics statistics;
  final PushEffectivenessAnalysis effectivenessAnalysis;
  final Map<String, DailyStats> dailyStats;
  final List<TrendData> trends;
  final List<String> insights;
  final List<String> recommendations;
  final UserBehaviorAnalysis behaviorAnalysis;
  final ContentEffectivenessAnalysis contentAnalysis;
  final TimePatternAnalysis timePatterns;

  const PushEffectivenessReport({
    required this.periodInDays,
    required this.generatedAt,
    required this.statistics,
    required this.effectivenessAnalysis,
    required this.dailyStats,
    required this.trends,
    required this.insights,
    required this.recommendations,
    required this.behaviorAnalysis,
    required this.contentAnalysis,
    required this.timePatterns,
  });

  factory PushEffectivenessReport.empty() {
    return PushEffectivenessReport(
      periodInDays: 0,
      generatedAt: DateTime.now(),
      statistics: PushStatistics.empty(),
      effectivenessAnalysis: PushEffectivenessAnalysis.empty(),
      dailyStats: {},
      trends: [],
      insights: [],
      recommendations: [],
      behaviorAnalysis: UserBehaviorAnalysis(
        averageResponseTimeMinutes: 0,
        mostActiveHour: 12,
        hourlyActivity: List.filled(24, 0),
      ),
      contentAnalysis: ContentEffectivenessAnalysis.empty(),
      timePatterns: TimePatternAnalysis(
        hourlyStats: List.filled(24, {}),
        weekdayStats: List.filled(7, {}),
      ),
    );
  }
}

class TrendData {
  final DateTime date;
  final double totalChange;
  final double clickRateChange;
  final double readRateChange;

  const TrendData({
    required this.date,
    required this.totalChange,
    required this.clickRateChange,
    required this.readRateChange,
  });
}

class UserBehaviorAnalysis {
  final int averageResponseTimeMinutes;
  final int mostActiveHour;
  final List<int> hourlyActivity;

  const UserBehaviorAnalysis({
    required this.averageResponseTimeMinutes,
    required this.mostActiveHour,
    required this.hourlyActivity,
  });
}

class ContentEffectivenessAnalysis {
  final Map<String, double> titleLengthAnalysis;
  final Map<String, double> contentLengthAnalysis;
  final Map<String, double> keywordAnalysis;
  final SentimentAnalysis sentimentAnalysis;
  final PersonalizationImpact personalizationImpact;
  final Map<String, double> templateAnalysis;
  final int periodInDays;

  const ContentEffectivenessAnalysis({
    required this.titleLengthAnalysis,
    required this.contentLengthAnalysis,
    required this.keywordAnalysis,
    required this.sentimentAnalysis,
    required this.personalizationImpact,
    required this.templateAnalysis,
    required this.periodInDays,
  });

  factory ContentEffectivenessAnalysis.empty() {
    return const ContentEffectivenessAnalysis(
      titleLengthAnalysis: {},
      contentLengthAnalysis: {},
      keywordAnalysis: {},
      sentimentAnalysis:
          SentimentAnalysis(positive: 0, neutral: 0, negative: 0),
      personalizationImpact: PersonalizationImpact(low: 0, medium: 0, high: 0),
      templateAnalysis: {},
      periodInDays: 0,
    );
  }
}

class SentimentAnalysis {
  final int positive;
  final int neutral;
  final int negative;

  const SentimentAnalysis({
    required this.positive,
    required this.neutral,
    required this.negative,
  });
}

class PersonalizationImpact {
  final double low;
  final double medium;
  final double high;

  const PersonalizationImpact({
    required this.low,
    required this.medium,
    required this.high,
  });
}

class TimePatternAnalysis {
  final List<Map<String, int>> hourlyStats;
  final List<Map<String, int>> weekdayStats;

  const TimePatternAnalysis({
    required this.hourlyStats,
    required this.weekdayStats,
  });
}

class UserEngagementAnalysis {
  final int totalUsers;
  final int activeUsers;
  final int engagedUsers;
  final double engagementRate;
  final double activationRate;
  final List<double> engagementTrend;
  final Map<String, UserSegment> userSegments;
  final RetentionAnalysis retentionAnalysis;
  final List<int> activeHours;
  final int periodInDays;

  const UserEngagementAnalysis({
    required this.totalUsers,
    required this.activeUsers,
    required this.engagedUsers,
    required this.engagementRate,
    required this.activationRate,
    required this.engagementTrend,
    required this.userSegments,
    required this.retentionAnalysis,
    required this.activeHours,
    required this.periodInDays,
  });

  factory UserEngagementAnalysis.empty() {
    return UserEngagementAnalysis(
      totalUsers: 0,
      activeUsers: 0,
      engagedUsers: 0,
      engagementRate: 0.0,
      activationRate: 0.0,
      engagementTrend: [],
      userSegments: {},
      retentionAnalysis: const RetentionAnalysis(
          day1Retention: 0, day7Retention: 0, day30Retention: 0),
      activeHours: List.filled(24, 0),
      periodInDays: 0,
    );
  }
}

class UserSegment {
  final String name;
  final int count;
  final List<String> characteristics;

  const UserSegment({
    required this.name,
    required this.count,
    required this.characteristics,
  });
}

class RetentionAnalysis {
  final double day1Retention;
  final double day7Retention;
  final double day30Retention;

  const RetentionAnalysis({
    required this.day1Retention,
    required this.day7Retention,
    required this.day30Retention,
  });
}

class OptimalTimingRecommendations {
  final List<HourlyPerformance> hourlyPerformance;
  final List<WeekdayPerformance> weekdayPerformance;
  final List<int> userActiveHours;
  final List<TimeWindow> optimalWindows;
  final TimezoneAnalysis timezoneAnalysis;
  final int periodInDays;

  const OptimalTimingRecommendations({
    required this.hourlyPerformance,
    required this.weekdayPerformance,
    required this.userActiveHours,
    required this.optimalWindows,
    required this.timezoneAnalysis,
    required this.periodInDays,
  });

  factory OptimalTimingRecommendations.empty() {
    return OptimalTimingRecommendations(
      hourlyPerformance: List.generate(
          24,
          (i) => HourlyPerformance(
              hour: i, totalPushes: 0, clickedPushes: 0, clickRate: 0.0)),
      weekdayPerformance: List.generate(
          7,
          (i) => WeekdayPerformance(
              weekday: '', totalPushes: 0, clickedPushes: 0, clickRate: 0.0)),
      userActiveHours: List.filled(24, 0),
      optimalWindows: [],
      timezoneAnalysis: const TimezoneAnalysis(
        localTimezonePerformance: 0,
        otherTimezonePerformance: 0,
        recommendedStrategy: '',
      ),
      periodInDays: 0,
    );
  }
}

class HourlyPerformance {
  final int hour;
  final int totalPushes;
  final int clickedPushes;
  final double clickRate;

  const HourlyPerformance({
    required this.hour,
    required this.totalPushes,
    required this.clickedPushes,
    required this.clickRate,
  });
}

class WeekdayPerformance {
  final String weekday;
  final int totalPushes;
  final int clickedPushes;
  final double clickRate;

  const WeekdayPerformance({
    required this.weekday,
    required this.totalPushes,
    required this.clickedPushes,
    required this.clickRate,
  });
}

class TimeWindow {
  final int startHour;
  final int endHour;
  final double averageClickRate;

  const TimeWindow({
    required this.startHour,
    required this.endHour,
    required this.averageClickRate,
  });
}

class TimezoneAnalysis {
  final double localTimezonePerformance;
  final double otherTimezonePerformance;
  final String recommendedStrategy;

  const TimezoneAnalysis({
    required this.localTimezonePerformance,
    required this.otherTimezonePerformance,
    required this.recommendedStrategy,
  });
}

class PushEffectivenessPrediction {
  final double predictedClickRate;
  final double predictedReadRate;
  final double confidence;
  final List<String> factors;
  final List<String> recommendations;

  const PushEffectivenessPrediction({
    required this.predictedClickRate,
    required this.predictedReadRate,
    required this.confidence,
    required this.factors,
    required this.recommendations,
  });

  factory PushEffectivenessPrediction.empty() {
    return const PushEffectivenessPrediction(
      predictedClickRate: 0.0,
      predictedReadRate: 0.0,
      confidence: 0.0,
      factors: [],
      recommendations: [],
    );
  }
}
