import 'package:equatable/equatable.dart';

import 'change_category.dart';
import 'push_priority.dart';
import 'market_change_event.dart';

/// 用户推送偏好设置
class UserPreferences extends Equatable {
  /// 是否启用推送通知
  final bool pushEnabled;

  /// 关注的基金列表
  final List<String> watchedFunds;

  /// 排除的基金列表
  final List<String> excludedFunds;

  /// 兴趣类型列表
  final List<String> interestTypes;

  /// 排除的变化类别
  final List<ChangeCategory> excludedCategories;

  /// 风险偏好
  final RiskTolerance riskTolerance;

  /// 最小变化率阈值
  final double minChangeRateThreshold;

  /// 静默时段
  final List<SilentHourRange> silentHours;

  /// 是否允许静默时段的紧急推送
  final bool allowUrgentPushesDuringSilentHours;

  /// 推送频率设置
  final Map<PushPriorityLevel, PushFrequency> priorityFrequencySettings;

  /// 推送时间偏好
  final PushTimePreferences pushTimePreferences;

  /// 推送内容偏好
  final PushContentPreferences pushContentPreferences;

  const UserPreferences({
    this.pushEnabled = true,
    this.watchedFunds = const [],
    this.excludedFunds = const [],
    this.interestTypes = const [],
    this.excludedCategories = const [],
    this.riskTolerance = RiskTolerance.moderate,
    this.minChangeRateThreshold = 0.5,
    this.silentHours = const [],
    this.allowUrgentPushesDuringSilentHours = true,
    this.priorityFrequencySettings = const {},
    this.pushTimePreferences = const PushTimePreferences(),
    this.pushContentPreferences = const PushContentPreferences(),
  });

  /// 复制并修改部分属性
  UserPreferences copyWith({
    bool? pushEnabled,
    List<String>? watchedFunds,
    List<String>? excludedFunds,
    List<String>? interestTypes,
    List<ChangeCategory>? excludedCategories,
    RiskTolerance? riskTolerance,
    double? minChangeRateThreshold,
    List<SilentHourRange>? silentHours,
    bool? allowUrgentPushesDuringSilentHours,
    Map<PushPriorityLevel, PushFrequency>? priorityFrequencySettings,
    PushTimePreferences? pushTimePreferences,
    PushContentPreferences? pushContentPreferences,
  }) {
    return UserPreferences(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      watchedFunds: watchedFunds ?? this.watchedFunds,
      excludedFunds: excludedFunds ?? this.excludedFunds,
      interestTypes: interestTypes ?? this.interestTypes,
      excludedCategories: excludedCategories ?? this.excludedCategories,
      riskTolerance: riskTolerance ?? this.riskTolerance,
      minChangeRateThreshold:
          minChangeRateThreshold ?? this.minChangeRateThreshold,
      silentHours: silentHours ?? this.silentHours,
      allowUrgentPushesDuringSilentHours: allowUrgentPushesDuringSilentHours ??
          this.allowUrgentPushesDuringSilentHours,
      priorityFrequencySettings:
          priorityFrequencySettings ?? this.priorityFrequencySettings,
      pushTimePreferences: pushTimePreferences ?? this.pushTimePreferences,
      pushContentPreferences:
          pushContentPreferences ?? this.pushContentPreferences,
    );
  }

  @override
  List<Object?> get props => [
        pushEnabled,
        watchedFunds,
        excludedFunds,
        interestTypes,
        excludedCategories,
        riskTolerance,
        minChangeRateThreshold,
        silentHours,
        allowUrgentPushesDuringSilentHours,
        priorityFrequencySettings,
        pushTimePreferences,
        pushContentPreferences,
      ];
}

/// 风险偏好
enum RiskTolerance {
  /// 保守型
  conservative,

  /// 稳健型
  moderate,

  /// 激进型
  aggressive,
}

/// 静默时段范围
class SilentHourRange extends Equatable {
  /// 开始时间
  final TimeOfDay start;

  /// 结束时间
  final TimeOfDay end;

  const SilentHourRange({
    required this.start,
    required this.end,
  });

  @override
  List<Object?> get props => [start, end];
}

/// 时间
class TimeOfDay extends Equatable {
  /// 小时 (0-23)
  final int hour;

  /// 分钟 (0-59)
  final int minute;

  const TimeOfDay({
    required this.hour,
    required this.minute,
  });

  @override
  List<Object?> get props => [hour, minute];
}

/// 推送时间偏好
class PushTimePreferences extends Equatable {
  /// 是否在交易日推送
  final bool pushOnTradingDays;

  /// 是否在非交易日推送
  final bool pushOnNonTradingDays;

  /// 推送时段限制
  final List<TimeRange> allowedTimeRanges;

  /// 最小推送间隔（分钟）
  final int minPushIntervalMinutes;

  /// 最大每日推送数量
  final int maxDailyPushes;

  const PushTimePreferences({
    this.pushOnTradingDays = true,
    this.pushOnNonTradingDays = false,
    this.allowedTimeRanges = const [],
    this.minPushIntervalMinutes = 5,
    this.maxDailyPushes = 50,
  });

  @override
  List<Object?> get props => [
        pushOnTradingDays,
        pushOnNonTradingDays,
        allowedTimeRanges,
        minPushIntervalMinutes,
        maxDailyPushes,
      ];
}

/// 时间范围
class TimeRange extends Equatable {
  /// 开始时间
  final TimeOfDay start;

  /// 结束时间
  final TimeOfDay end;

  const TimeRange({
    required this.start,
    required this.end,
  });

  @override
  List<Object?> get props => [start, end];
}

/// 推送内容偏好
class PushContentPreferences extends Equatable {
  /// 是否包含变化分析
  final bool includeChangeAnalysis;

  /// 是否包含影响评估
  final bool includeImpactAssessment;

  /// 是否包含相关基金信息
  final bool includeRelatedFunds;

  /// 是否包含投资建议
  final bool includeInvestmentSuggestions;

  /// 推送内容详细程度
  final ContentDetailLevel contentDetailLevel;

  /// 推送语言偏好
  final PushLanguage language;

  const PushContentPreferences({
    this.includeChangeAnalysis = true,
    this.includeImpactAssessment = true,
    this.includeRelatedFunds = true,
    this.includeInvestmentSuggestions = false,
    this.contentDetailLevel = ContentDetailLevel.medium,
    this.language = PushLanguage.chinese,
  });

  @override
  List<Object?> get props => [
        includeChangeAnalysis,
        includeImpactAssessment,
        includeRelatedFunds,
        includeInvestmentSuggestions,
        contentDetailLevel,
        language,
      ];
}

/// 内容详细程度
enum ContentDetailLevel {
  /// 简要
  brief,

  /// 中等
  medium,

  /// 详细
  detailed,
}

/// 推送语言
enum PushLanguage {
  /// 中文
  chinese,

  /// 英文
  english,
}
