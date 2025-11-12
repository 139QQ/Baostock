import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import '../models/market_change_event.dart';
import '../models/change_category.dart';
import '../models/change_severity.dart';
import '../models/push_priority.dart';
import '../models/user_preferences.dart';

/// 推送优先级管理器
///
/// 负责智能计算推送优先级和过滤推送事件
class PushPriorityManager {
  /// 优先级计算参数
  final PriorityCalculationParameters _parameters;

  /// 用户推送历史记录 (用于频率控制)
  final Map<String, Queue<DateTime>> _pushHistory = {};

  /// 用户偏好缓存
  UserPreferences? _cachedUserPreferences;

  /// 上次偏好更新时间
  DateTime? _lastPreferencesUpdate;

  /// 构造函数
  PushPriorityManager({
    PriorityCalculationParameters? parameters,
  }) : _parameters = parameters ?? PriorityCalculationParameters();

  /// 计算推送优先级
  Future<PushPriority> calculatePriority(
    MarketChangeEvent event, {
    UserPreferences? userPreferences,
    String? userId,
  }) async {
    // 更新用户偏好缓存
    await _updateUserPreferencesCache(userPreferences);

    // 计算基础优先级分数
    var baseScore = _calculateBasePriorityScore(event);

    // 根据用户偏好调整
    if (_cachedUserPreferences != null) {
      baseScore = _adjustScoreByUserPreferences(baseScore, event);
    }

    // 根据时间因素调整
    baseScore = _adjustScoreByTimeFactors(baseScore, event);

    // 根据频率控制调整
    if (userId != null) {
      baseScore = _adjustScoreByFrequencyControl(baseScore, event, userId);
    }

    // 确定最终优先级
    final priority = _determinePriorityFromScore(baseScore);

    return PushPriority(
      eventId: event.id,
      priority: priority,
      score: baseScore,
      reason: _generatePriorityReason(event, priority, baseScore),
      calculatedAt: DateTime.now(),
      factors: _calculatePriorityFactors(event),
    );
  }

  /// 判断是否应该推送
  Future<bool> shouldPush(
    MarketChangeEvent event,
    UserPreferences userPreferences, {
    String? userId,
  }) async {
    // 计算优先级
    final priority = await calculatePriority(
      event,
      userPreferences: userPreferences,
      userId: userId,
    );

    // 检查优先级阈值
    if (priority.score < _parameters.minimumPushScore) {
      return false;
    }

    // 检查用户静默时段
    if (_isInSilentHours(userPreferences)) {
      return _shouldPushDuringSilentHours(event, userPreferences);
    }

    // 检查频率限制
    if (userId != null && _isFrequencyLimited(userId, event)) {
      return false;
    }

    // 检查推送内容过滤
    if (!_passesContentFilters(event, userPreferences)) {
      return false;
    }

    return true;
  }

  /// 更新频率控制
  Future<void> updateFrequencyControl(
    String userId,
    PushFrequency frequency,
  ) async {
    // 这里可以实现更复杂的频率控制逻辑
    // 暂时只是清理过期的历史记录
    _cleanupExpiredHistory(userId);
  }

  /// 计算基础优先级分数
  double _calculateBasePriorityScore(MarketChangeEvent event) {
    var score = 0.0;

    // 基于变化严重程度
    switch (event.severity) {
      case ChangeSeverity.high:
        score += _parameters.highSeverityWeight;
        break;
      case ChangeSeverity.medium:
        score += _parameters.mediumSeverityWeight;
        break;
      case ChangeSeverity.low:
        score += _parameters.lowSeverityWeight;
        break;
    }

    // 基于变化类别
    switch (event.category) {
      case ChangeCategory.abnormalEvent:
        score += _parameters.abnormalEventWeight;
        break;
      case ChangeCategory.trendChange:
        score += _parameters.trendChangeWeight;
        break;
      case ChangeCategory.priceChange:
        score += _parameters.priceChangeWeight;
        break;
    }

    // 基于变化幅度
    final magnitudeScore = math.min(
      _parameters.maxMagnitudeScore,
      event.changeRate.abs() * _parameters.magnitudeMultiplier,
    );
    score += magnitudeScore;

    // 基于事件重要性
    score += event.importance * _parameters.importanceWeight;

    return score;
  }

  /// 根据用户偏好调整分数
  double _adjustScoreByUserPreferences(
    double score,
    MarketChangeEvent event,
  ) {
    if (_cachedUserPreferences == null) return score;

    final preferences = _cachedUserPreferences!;

    // 根据关注基金调整
    if (preferences.watchedFunds.contains(event.entityId)) {
      score *= _parameters.watchedFundMultiplier;
    }

    // 根据兴趣类型调整
    if (preferences.interestTypes.contains(event.type.name)) {
      score *= _parameters.interestTypeMultiplier;
    }

    // 根据风险偏好调整
    switch (preferences.riskTolerance) {
      case RiskTolerance.conservative:
        if (event.severity == ChangeSeverity.high) {
          score *= _parameters.conservativeHighSeverityMultiplier;
        }
        break;
      case RiskTolerance.moderate:
        // 保持基础分数
        break;
      case RiskTolerance.aggressive:
        if (event.severity == ChangeSeverity.high) {
          score *= _parameters.aggressiveHighSeverityMultiplier;
        }
        break;
    }

    return score;
  }

  /// 根据时间因素调整分数
  double _adjustScoreByTimeFactors(double score, MarketChangeEvent event) {
    final now = DateTime.now();
    final hour = now.hour;

    // 交易时间权重更高
    if (_isTradingHours(now)) {
      score *= _parameters.tradingHoursMultiplier;
    }

    // 盘前盘后时间权重较低
    else if (_isPreMarketHours(now) || _isAfterMarketHours(now)) {
      score *= _parameters.nonTradingHoursMultiplier;
    }

    // 深夜时间权重最低
    else if (hour >= 23 || hour <= 6) {
      score *= _parameters.deepNightMultiplier;
    }

    return score;
  }

  /// 根据频率控制调整分数
  double _adjustScoreByFrequencyControl(
    double score,
    MarketChangeEvent event,
    String userId,
  ) {
    final userHistory = _pushHistory[userId];
    if (userHistory == null || userHistory.isEmpty) return score;

    // 计算最近推送频率
    final recentPushes = userHistory.where((time) {
      final difference = DateTime.now().difference(time);
      return difference.inMinutes <= _parameters.frequencyControlWindowMinutes;
    }).length;

    // 根据推送频率调整分数
    if (recentPushes >= _parameters.maxPushesPerWindow) {
      score *= _parameters.frequencyLimitPenalty;
    } else if (recentPushes >= _parameters.maxPushesPerWindow * 0.8) {
      score *= _parameters.frequencyNearLimitPenalty;
    }

    return score;
  }

  /// 根据分数确定优先级
  PushPriorityLevel _determinePriorityFromScore(double score) {
    if (score >= _parameters.criticalPriorityThreshold) {
      return PushPriorityLevel.critical;
    } else if (score >= _parameters.highPriorityThreshold) {
      return PushPriorityLevel.high;
    } else if (score >= _parameters.mediumPriorityThreshold) {
      return PushPriorityLevel.medium;
    } else {
      return PushPriorityLevel.low;
    }
  }

  /// 生成优先级原因
  String _generatePriorityReason(
    MarketChangeEvent event,
    PushPriorityLevel priority,
    double score,
  ) {
    final buffer = StringBuffer();

    buffer.write('${event.entityName} ${event.categoryDescription}，');

    switch (priority) {
      case PushPriorityLevel.critical:
        buffer.write('重大变化，建议立即关注');
        break;
      case PushPriorityLevel.high:
        buffer.write('重要变化，建议优先处理');
        break;
      case PushPriorityLevel.medium:
        buffer.write('一般变化，建议适当关注');
        break;
      case PushPriorityLevel.low:
        buffer.write('轻微变化，可在空闲时查看');
        break;
    }

    if (score >= _parameters.urgentNotificationThreshold) {
      buffer.write('（紧急）');
    }

    return buffer.toString();
  }

  /// 计算优先级影响因素
  Map<String, double> _calculatePriorityFactors(MarketChangeEvent event) {
    return {
      'severity': _getSeverityFactor(event.severity),
      'category': _getCategoryFactor(event.category),
      'magnitude': event.changeRate.abs().clamp(0.0, 10.0),
      'importance': event.importance / 10.0,
    };
  }

  /// 更新用户偏好缓存
  Future<void> _updateUserPreferencesCache(UserPreferences? preferences) async {
    if (preferences == null) return;

    // 检查是否需要更新缓存
    if (_cachedUserPreferences == null ||
        _lastPreferencesUpdate == null ||
        DateTime.now().difference(_lastPreferencesUpdate!).inMinutes > 5) {
      _cachedUserPreferences = preferences;
      _lastPreferencesUpdate = DateTime.now();
    }
  }

  /// 检查是否在静默时段
  bool _isInSilentHours(UserPreferences preferences) {
    final now = DateTime.now();
    final currentTime = Duration(hours: now.hour, minutes: now.minute);

    return preferences.silentHours.any((range) {
      final startTime =
          Duration(hours: range.start.hour, minutes: range.start.minute);
      final endTime =
          Duration(hours: range.end.hour, minutes: range.end.minute);

      if (startTime <= endTime) {
        return currentTime >= startTime && currentTime <= endTime;
      } else {
        // 跨天的静默时段
        return currentTime >= startTime || currentTime <= endTime;
      }
    });
  }

  /// 静默时段是否应该推送
  bool _shouldPushDuringSilentHours(
    MarketChangeEvent event,
    UserPreferences preferences,
  ) {
    // 只有高优先级事件才能在静默时段推送
    return event.severity == ChangeSeverity.high &&
        preferences.allowUrgentPushesDuringSilentHours;
  }

  /// 检查是否被频率限制
  bool _isFrequencyLimited(String userId, MarketChangeEvent event) {
    final userHistory = _pushHistory[userId];
    if (userHistory == null) return false;

    // 计算指定时间窗口内的推送次数
    final windowStart = DateTime.now().subtract(
      Duration(minutes: _parameters.frequencyControlWindowMinutes),
    );

    final recentPushes =
        userHistory.where((time) => time.isAfter(windowStart)).length;

    return recentPushes >= _parameters.maxPushesPerWindow;
  }

  /// 检查是否通过内容过滤
  bool _passesContentFilters(
      MarketChangeEvent event, UserPreferences preferences) {
    // 检查最小变化率阈值
    if (event.changeRate.abs() < preferences.minChangeRateThreshold) {
      return false;
    }

    // 检查排除的基金
    if (preferences.excludedFunds.contains(event.entityId)) {
      return false;
    }

    // 检查排除的变化类别
    if (preferences.excludedCategories.contains(event.category)) {
      return false;
    }

    return true;
  }

  /// 清理过期历史记录
  void _cleanupExpiredHistory(String userId) {
    final userHistory = _pushHistory[userId];
    if (userHistory == null) return;

    final cutoffTime = DateTime.now().subtract(
      Duration(hours: _parameters.historyRetentionHours),
    );

    while (userHistory.isNotEmpty && userHistory.last.isBefore(cutoffTime)) {
      userHistory.removeLast();
    }
  }

  /// 记录推送事件
  void recordPush(String userId, String eventId) {
    final userHistory =
        _pushHistory.putIfAbsent(userId, () => Queue<DateTime>());
    userHistory.addFirst(DateTime.now());

    // 保持历史记录大小
    while (userHistory.length > _parameters.maxHistorySize) {
      userHistory.removeLast();
    }
  }

  // 辅助方法
  bool _isTradingHours(DateTime dateTime) {
    final hour = dateTime.hour;
    final weekday = dateTime.weekday;

    // 工作日 9:30-15:00 为交易时间
    return weekday >= DateTime.monday &&
        weekday <= DateTime.friday &&
        hour >= 9 &&
        hour < 15;
  }

  bool _isPreMarketHours(DateTime dateTime) {
    final hour = dateTime.hour;
    final weekday = dateTime.weekday;

    return weekday >= DateTime.monday &&
        weekday <= DateTime.friday &&
        hour >= 7 &&
        hour < 9;
  }

  bool _isAfterMarketHours(DateTime dateTime) {
    final hour = dateTime.hour;
    final weekday = dateTime.weekday;

    return weekday >= DateTime.monday &&
        weekday <= DateTime.friday &&
        hour >= 15 &&
        hour < 19;
  }

  double _getSeverityFactor(ChangeSeverity severity) {
    switch (severity) {
      case ChangeSeverity.high:
        return 3.0;
      case ChangeSeverity.medium:
        return 2.0;
      case ChangeSeverity.low:
        return 1.0;
    }
  }

  double _getCategoryFactor(ChangeCategory category) {
    switch (category) {
      case ChangeCategory.abnormalEvent:
        return 3.0;
      case ChangeCategory.trendChange:
        return 2.0;
      case ChangeCategory.priceChange:
        return 1.0;
    }
  }

  /// 清理缓存
  void clearCache() {
    _pushHistory.clear();
    _cachedUserPreferences = null;
    _lastPreferencesUpdate = null;
  }
}

/// 优先级计算参数
class PriorityCalculationParameters {
  /// 严重程度权重
  final double highSeverityWeight;
  final double mediumSeverityWeight;
  final double lowSeverityWeight;

  /// 变化类别权重
  final double abnormalEventWeight;
  final double trendChangeWeight;
  final double priceChangeWeight;

  /// 变化幅度相关
  final double maxMagnitudeScore;
  final double magnitudeMultiplier;

  /// 重要性权重
  final double importanceWeight;

  /// 时间相关乘数
  final double tradingHoursMultiplier;
  final double nonTradingHoursMultiplier;
  final double deepNightMultiplier;

  /// 用户偏好相关乘数
  final double watchedFundMultiplier;
  final double interestTypeMultiplier;
  final double conservativeHighSeverityMultiplier;
  final double aggressiveHighSeverityMultiplier;

  /// 频率控制参数
  final int frequencyControlWindowMinutes;
  final int maxPushesPerWindow;
  final double frequencyLimitPenalty;
  final double frequencyNearLimitPenalty;
  final int maxHistorySize;
  final int historyRetentionHours;

  /// 优先级阈值
  final double criticalPriorityThreshold;
  final double highPriorityThreshold;
  final double mediumPriorityThreshold;
  final double minimumPushScore;
  final double urgentNotificationThreshold;

  const PriorityCalculationParameters({
    this.highSeverityWeight = 30.0,
    this.mediumSeverityWeight = 20.0,
    this.lowSeverityWeight = 10.0,
    this.abnormalEventWeight = 25.0,
    this.trendChangeWeight = 15.0,
    this.priceChangeWeight = 10.0,
    this.maxMagnitudeScore = 20.0,
    this.magnitudeMultiplier = 2.0,
    this.importanceWeight = 0.5,
    this.tradingHoursMultiplier = 1.2,
    this.nonTradingHoursMultiplier = 0.8,
    this.deepNightMultiplier = 0.5,
    this.watchedFundMultiplier = 1.5,
    this.interestTypeMultiplier = 1.3,
    this.conservativeHighSeverityMultiplier = 1.3,
    this.aggressiveHighSeverityMultiplier = 1.5,
    this.frequencyControlWindowMinutes = 60,
    this.maxPushesPerWindow = 10,
    this.frequencyLimitPenalty = 0.3,
    this.frequencyNearLimitPenalty = 0.7,
    this.maxHistorySize = 100,
    this.historyRetentionHours = 24,
    this.criticalPriorityThreshold = 80.0,
    this.highPriorityThreshold = 60.0,
    this.mediumPriorityThreshold = 40.0,
    this.minimumPushScore = 30.0,
    this.urgentNotificationThreshold = 75.0,
  });
}
