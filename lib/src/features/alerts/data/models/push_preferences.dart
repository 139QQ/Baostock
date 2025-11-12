import 'package:flutter/material.dart';

/// 用户推送偏好设置
class UserPreferences {
  final String userId;
  final String version;
  final bool enablePushNotifications;
  final bool enableInAppNotification;
  final bool enableSystemNotification;
  final bool enableEmailNotification;
  final bool enableSmsNotification;
  final bool enableUrgentPushes;
  final bool enableHighPriorityPushes;
  final bool includeImpactAnalysis;
  final bool includeRecommendations;
  final List<PushContentType> contentTypes;
  final List<String> markets;
  final List<String> watchedFunds;
  final List<String> interestThemes;
  final List<QuietHours> quietHours;
  final List<PushFrequencyRule> frequencyRules;
  final PushFrequency defaultFrequency;
  final double minChangeThreshold;
  final String? primaryWatchFund;
  final TitleStyle titleStyle;
  final CallToActionStyle callToActionStyle;
  final InvestmentStyle? investmentStyle;
  final PushTheme theme;
  final Map<String, dynamic> customSettings;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserPreferences({
    required this.userId,
    this.version = '1.0.0',
    this.enablePushNotifications = true,
    this.enableInAppNotification = true,
    this.enableSystemNotification = true,
    this.enableEmailNotification = false,
    this.enableSmsNotification = false,
    this.enableUrgentPushes = true,
    this.enableHighPriorityPushes = true,
    this.includeImpactAnalysis = true,
    this.includeRecommendations = true,
    this.contentTypes = const [
      PushContentType.price_change,
      PushContentType.trend_analysis,
      PushContentType.market_news,
    ],
    this.markets = const ['A股', '港股', '美股'],
    this.watchedFunds = const [],
    this.interestThemes = const [],
    this.quietHours = const [],
    this.frequencyRules = const [],
    this.defaultFrequency = PushFrequency.normal,
    this.minChangeThreshold = 2.0,
    this.primaryWatchFund,
    this.titleStyle = TitleStyle.concise,
    this.callToActionStyle = CallToActionStyle.view_details,
    this.investmentStyle,
    this.theme = PushTheme.system,
    this.customSettings = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserPreferences.defaultPreferences([String? userId]) {
    final now = DateTime.now();
    return UserPreferences(
      userId: userId ?? 'default_user',
      createdAt: now,
      updatedAt: now,
      quietHours: [
        QuietHours(
          start: const TimeOfDay(hour: 22, minute: 0),
          end: const TimeOfDay(hour: 7, minute: 0),
          enabled: true,
        ),
      ],
    );
  }

  UserPreferences copyWith({
    String? userId,
    String? version,
    bool? enablePushNotifications,
    bool? enableInAppNotification,
    bool? enableSystemNotification,
    bool? enableEmailNotification,
    bool? enableSmsNotification,
    bool? enableUrgentPushes,
    bool? enableHighPriorityPushes,
    bool? includeImpactAnalysis,
    bool? includeRecommendations,
    List<PushContentType>? contentTypes,
    List<String>? markets,
    List<String>? watchedFunds,
    List<String>? interestThemes,
    List<QuietHours>? quietHours,
    List<PushFrequencyRule>? frequencyRules,
    PushFrequency? defaultFrequency,
    double? minChangeThreshold,
    String? primaryWatchFund,
    TitleStyle? titleStyle,
    CallToActionStyle? callToActionStyle,
    InvestmentStyle? investmentStyle,
    PushTheme? theme,
    Map<String, dynamic>? customSettings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserPreferences(
      userId: userId ?? this.userId,
      version: version ?? this.version,
      enablePushNotifications:
          enablePushNotifications ?? this.enablePushNotifications,
      enableInAppNotification:
          enableInAppNotification ?? this.enableInAppNotification,
      enableSystemNotification:
          enableSystemNotification ?? this.enableSystemNotification,
      enableEmailNotification:
          enableEmailNotification ?? this.enableEmailNotification,
      enableSmsNotification:
          enableSmsNotification ?? this.enableSmsNotification,
      enableUrgentPushes: enableUrgentPushes ?? this.enableUrgentPushes,
      enableHighPriorityPushes:
          enableHighPriorityPushes ?? this.enableHighPriorityPushes,
      includeImpactAnalysis:
          includeImpactAnalysis ?? this.includeImpactAnalysis,
      includeRecommendations:
          includeRecommendations ?? this.includeRecommendations,
      contentTypes: contentTypes ?? this.contentTypes,
      markets: markets ?? this.markets,
      watchedFunds: watchedFunds ?? this.watchedFunds,
      interestThemes: interestThemes ?? this.interestThemes,
      quietHours: quietHours ?? this.quietHours,
      frequencyRules: frequencyRules ?? this.frequencyRules,
      defaultFrequency: defaultFrequency ?? this.defaultFrequency,
      minChangeThreshold: minChangeThreshold ?? this.minChangeThreshold,
      primaryWatchFund: primaryWatchFund ?? this.primaryWatchFund,
      titleStyle: titleStyle ?? this.titleStyle,
      callToActionStyle: callToActionStyle ?? this.callToActionStyle,
      investmentStyle: investmentStyle ?? this.investmentStyle,
      theme: theme ?? this.theme,
      customSettings: customSettings ?? this.customSettings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'version': version,
      'enable_push_notifications': enablePushNotifications,
      'enable_in_app_notification': enableInAppNotification,
      'enable_system_notification': enableSystemNotification,
      'enable_email_notification': enableEmailNotification,
      'enable_sms_notification': enableSmsNotification,
      'enable_urgent_pushes': enableUrgentPushes,
      'enable_high_priority_pushes': enableHighPriorityPushes,
      'include_impact_analysis': includeImpactAnalysis,
      'include_recommendations': includeRecommendations,
      'content_types': contentTypes.map((e) => e.name).toList(),
      'markets': markets,
      'watched_funds': watchedFunds,
      'interest_themes': interestThemes,
      'quiet_hours': quietHours.map((e) => e.toJson()).toList(),
      'frequency_rules': frequencyRules.map((e) => e.toJson()).toList(),
      'default_frequency': defaultFrequency.name,
      'min_change_threshold': minChangeThreshold,
      'primary_watch_fund': primaryWatchFund,
      'title_style': titleStyle.name,
      'call_to_action_style': callToActionStyle.name,
      'investment_style': investmentStyle?.name,
      'theme': theme.name,
      'custom_settings': customSettings,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      userId: json['user_id'] as String,
      version: json['version'] as String? ?? '1.0.0',
      enablePushNotifications:
          json['enable_push_notifications'] as bool? ?? true,
      enableInAppNotification:
          json['enable_in_app_notification'] as bool? ?? true,
      enableSystemNotification:
          json['enable_system_notification'] as bool? ?? true,
      enableEmailNotification:
          json['enable_email_notification'] as bool? ?? false,
      enableSmsNotification: json['enable_sms_notification'] as bool? ?? false,
      enableUrgentPushes: json['enable_urgent_pushes'] as bool? ?? true,
      enableHighPriorityPushes:
          json['enable_high_priority_pushes'] as bool? ?? true,
      includeImpactAnalysis: json['include_impact_analysis'] as bool? ?? true,
      includeRecommendations: json['include_recommendations'] as bool? ?? true,
      contentTypes: (json['content_types'] as List<dynamic>?)
              ?.map(
                  (e) => PushContentType.values.firstWhere((v) => v.name == e))
              .toList() ??
          [PushContentType.price_change],
      markets:
          List<String>.from(json['markets'] as List? ?? ['A股', '港股', '美股']),
      watchedFunds: List<String>.from(json['watched_funds'] as List? ?? []),
      interestThemes: List<String>.from(json['interest_themes'] as List? ?? []),
      quietHours: (json['quiet_hours'] as List<dynamic>?)
              ?.map((e) => QuietHours.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      frequencyRules: (json['frequency_rules'] as List<dynamic>?)
              ?.map(
                  (e) => PushFrequencyRule.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      defaultFrequency: PushFrequency.values.firstWhere(
        (v) => v.name == json['default_frequency'],
        orElse: () => PushFrequency.normal,
      ),
      minChangeThreshold:
          (json['min_change_threshold'] as num?)?.toDouble() ?? 2.0,
      primaryWatchFund: json['primary_watch_fund'] as String?,
      titleStyle: TitleStyle.values.firstWhere(
        (v) => v.name == json['title_style'],
        orElse: () => TitleStyle.concise,
      ),
      callToActionStyle: CallToActionStyle.values.firstWhere(
        (v) => v.name == json['call_to_action_style'],
        orElse: () => CallToActionStyle.view_details,
      ),
      investmentStyle: json['investment_style'] != null
          ? InvestmentStyle.values
              .firstWhere((v) => v.name == json['investment_style'])
          : null,
      theme: PushTheme.values.firstWhere(
        (v) => v.name == json['theme'],
        orElse: () => PushTheme.system,
      ),
      customSettings:
          Map<String, dynamic>.from(json['custom_settings'] as Map? ?? {}),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserPreferences && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() {
    return 'UserPreferences(userId: $userId, enablePushNotifications: $enablePushNotifications)';
  }
}

/// 静默时段设置
class QuietHours {
  final TimeOfDay start;
  final TimeOfDay end;
  final bool enabled;
  final List<int> weekdays; // 1=周一, 7=周日
  final String? description;

  const QuietHours({
    required this.start,
    required this.end,
    this.enabled = true,
    this.weekdays = const [1, 2, 3, 4, 5, 6, 7],
    this.description,
  });

  bool isActiveAt(DateTime dateTime) {
    if (!enabled) return false;
    if (!weekdays.contains(dateTime.weekday)) return false;

    final time = TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
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

  Map<String, dynamic> toJson() {
    return {
      'start_hour': start.hour,
      'start_minute': start.minute,
      'end_hour': end.hour,
      'end_minute': end.minute,
      'enabled': enabled,
      'weekdays': weekdays,
      'description': description,
    };
  }

  factory QuietHours.fromJson(Map<String, dynamic> json) {
    return QuietHours(
      start: TimeOfDay(
        hour: json['start_hour'] as int,
        minute: json['start_minute'] as int,
      ),
      end: TimeOfDay(
        hour: json['end_hour'] as int,
        minute: json['end_minute'] as int,
      ),
      enabled: json['enabled'] as bool? ?? true,
      weekdays:
          List<int>.from(json['weekdays'] as List? ?? [1, 2, 3, 4, 5, 6, 7]),
      description: json['description'] as String?,
    );
  }

  @override
  String toString() {
    return 'QuietHours(${start.hour}:${start.minute.toString().padLeft(2, '0')} - ${end.hour}:${end.minute.toString().padLeft(2, '0')}, enabled: $enabled)';
  }
}

/// 推送频率规则
class PushFrequencyRule {
  final String id;
  final String name;
  final String description;
  final PushContentType contentType;
  final PushPriority maxPriority;
  final int maxPushesPerHour;
  final int maxPushesPerDay;
  final int minIntervalMinutes;
  final bool enabled;
  final List<String> conditions;

  const PushFrequencyRule({
    required this.id,
    required this.name,
    required this.description,
    required this.contentType,
    this.maxPriority = PushPriority.medium,
    this.maxPushesPerHour = 3,
    this.maxPushesPerDay = 20,
    this.minIntervalMinutes = 10,
    this.enabled = true,
    this.conditions = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'content_type': contentType.name,
      'max_priority': maxPriority.name,
      'max_pushes_per_hour': maxPushesPerHour,
      'max_pushes_per_day': maxPushesPerDay,
      'min_interval_minutes': minIntervalMinutes,
      'enabled': enabled,
      'conditions': conditions,
    };
  }

  factory PushFrequencyRule.fromJson(Map<String, dynamic> json) {
    return PushFrequencyRule(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      contentType: PushContentType.values
          .firstWhere((v) => v.name == json['content_type']),
      maxPriority: PushPriority.values.firstWhere(
          (v) => v.name == json['max_priority'],
          orElse: () => PushPriority.medium),
      maxPushesPerHour: json['max_pushes_per_hour'] as int? ?? 3,
      maxPushesPerDay: json['max_pushes_per_day'] as int? ?? 20,
      minIntervalMinutes: json['min_interval_minutes'] as int? ?? 10,
      enabled: json['enabled'] as bool? ?? true,
      conditions: List<String>.from(json['conditions'] as List? ?? []),
    );
  }

  @override
  String toString() {
    return 'PushFrequencyRule(id: $id, name: $name, enabled: $enabled)';
  }
}

/// 推送频率枚举
enum PushFrequency {
  immediate, // 立即推送
  frequent, // 频繁
  normal, // 正常
  limited, // 限制
  minimal, // 最少
  digest, // 摘要
}

/// 推送主题枚举
enum PushTheme {
  system, // 系统默认
  light, // 浅色主题
  dark, // 深色主题
  professional, // 专业主题
  minimal, // 极简主题
}

/// 从现有文件导入相关枚举
// 这些枚举应该从 market_change_event.dart 中导入
// 为了完整性，这里重新声明，实际使用时应该删除重复声明

enum PushPriority {
  critical,
  high,
  medium,
  low,
  informational,
}

enum PushContentType {
  price_change,
  trend_analysis,
  volume_alert,
  market_news,
  anomaly_detection,
  general,
}

enum TitleStyle {
  technical,
  concise,
  detailed,
  friendly,
}

enum CallToActionStyle {
  view_details,
  analyze,
  trade,
  none,
}

enum InvestmentStyle {
  conservative,
  balanced,
  aggressive,
  speculative,
}
