import 'dart:async';
import 'dart:math';

import '../models/market_change_event.dart';
import '../models/push_preferences.dart';
import '../models/change_severity.dart';
import '../services/change_correlation_service.dart';

/// 内容个性化引擎
/// 基于用户偏好、历史行为和市场数据生成个性化推送内容
class ContentPersonalizationEngine {
  final ChangeCorrelationService? _correlationService;
  final Map<String, UserProfile> _userProfiles = {};

  ContentPersonalizationEngine([this._correlationService]);

  /// 生成个性化推送内容
  Future<PersonalizedContent> generatePersonalizedContent(
    String userId,
    MarketChangeEvent event,
    UserPreferences preferences,
  ) async {
    final userProfile = await _getUserProfile(userId);

    final title = _generateTitle(event, preferences, userProfile);
    final body = _generateBody(event, preferences, userProfile);
    final actionText = _generateActionText(preferences);

    return PersonalizedContent(
      title: title,
      body: body,
      actionText: actionText,
      priority: _calculatePriority(event, preferences),
      channels: _selectChannels(preferences),
      customData: _generateCustomData(event, userProfile),
    );
  }

  /// 分析用户画像
  Future<UserProfile> _getUserProfile(String userId) async {
    if (_userProfiles.containsKey(userId)) {
      return _userProfiles[userId]!;
    }

    // 创建默认用户画像
    final profile = UserProfile.defaultProfile(userId);
    _userProfiles[userId] = profile;
    return profile;
  }

  /// 生成标题
  String _generateTitle(
    MarketChangeEvent event,
    UserPreferences preferences,
    UserProfile profile,
  ) {
    final entityName = event.entityName;
    final changeDesc = event.changeDescription;

    switch (preferences.titleStyle) {
      case TitleStyle.technical:
        return '$entityName $changeDesc';
      case TitleStyle.concise:
        return '$entityName 变化提醒';
      case TitleStyle.detailed:
        return '${event.severityDescription}：$entityName 发生$changeDesc';
      case TitleStyle.friendly:
        return '您的关注基金 $entityName 有新变化';
    }
  }

  /// 生成内容正文
  String _generateBody(
    MarketChangeEvent event,
    UserPreferences preferences,
    UserProfile profile,
  ) {
    final buffer = StringBuffer();

    // 基础变化信息
    buffer.writeln(
        '${event.entityName} ${event.trend}${event.changeDescription}');

    // 当前值信息
    if (event.currentValue.isNotEmpty) {
      buffer.writeln('当前净值：${event.currentValue}');
    }

    // 相关性分析
    if (preferences.includeImpactAnalysis && event.relatedFunds.isNotEmpty) {
      buffer.writeln('\n可能影响的基金：');
      for (final fund in event.relatedFunds.take(3)) {
        buffer.writeln('• $fund');
      }
    }

    // 个性化建议
    if (preferences.includeRecommendations) {
      buffer.writeln('\n${_generateRecommendation(event, profile)}');
    }

    return buffer.toString().trim();
  }

  /// 生成操作按钮文本
  String _generateActionText(UserPreferences preferences) {
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

  /// 计算推送优先级
  PushPriority _calculatePriority(
    MarketChangeEvent event,
    UserPreferences preferences,
  ) {
    if (!preferences.enableHighPriorityPushes) {
      return PushPriority.low;
    }

    switch (event.severity) {
      case ChangeSeverity.high:
        return PushPriority.high;
      case ChangeSeverity.medium:
        return PushPriority.medium;
      case ChangeSeverity.low:
        return PushPriority.low;
    }
  }

  /// 选择推送渠道
  List<String> _selectChannels(UserPreferences preferences) {
    final channels = <String>[];

    if (preferences.enableInAppNotification) {
      channels.add('in_app');
    }

    if (preferences.enableSystemNotification) {
      channels.add('system');
    }

    return channels;
  }

  /// 生成自定义数据
  Map<String, dynamic> _generateCustomData(
    MarketChangeEvent event,
    UserProfile profile,
  ) {
    return {
      'event_id': event.id,
      'event_type': event.type.name,
      'entity_id': event.entityId,
      'entity_name': event.entityName,
      'change_rate': event.changeRate,
      'severity': event.severity.name,
      'user_profile_id': profile.userId,
      'generated_at': DateTime.now().toIso8601String(),
    };
  }

  /// 生成个性化建议
  String _generateRecommendation(MarketChangeEvent event, UserProfile profile) {
    switch (profile.investmentStyle) {
      case InvestmentStyle.conservative:
        return '建议关注此变化的风险影响，谨慎决策。';
      case InvestmentStyle.balanced:
        return '建议评估此变化对投资组合的影响。';
      case InvestmentStyle.aggressive:
        return '可考虑此变化带来的投资机会。';
      case InvestmentStyle.speculative:
        return '值得关注的市场变化，可能存在机会。';
    }
  }

  /// 记录用户反馈
  void recordUserFeedback(
    String userId,
    String contentId,
    UserFeedback feedback,
  ) {
    final profile = _userProfiles[userId];
    if (profile != null) {
      profile.recordFeedback(contentId, feedback);
    }
  }

  /// 更新用户偏好
  Future<void> updateUserPreferences(
    String userId,
    UserPreferences preferences,
  ) async {
    // TODO: 持久化用户偏好
  }

  /// 清理缓存
  void clearCache() {
    _userProfiles.clear();
  }
}

/// 个性化内容
class PersonalizedContent {
  final String title;
  final String body;
  final String actionText;
  final PushPriority priority;
  final List<String> channels;
  final Map<String, dynamic> customData;

  const PersonalizedContent({
    required this.title,
    required this.body,
    required this.actionText,
    required this.priority,
    required this.channels,
    required this.customData,
  });

  @override
  String toString() {
    return 'PersonalizedContent(title: $title, priority: $priority)';
  }
}

/// 用户画像
class UserProfile {
  final String userId;
  final InvestmentStyle investmentStyle;
  final List<ContentPreference> contentPreferences;
  final Map<String, UserFeedback> feedbackHistory;
  final DateTime createdAt;
  DateTime lastUpdated;

  UserProfile({
    required this.userId,
    required this.investmentStyle,
    required this.contentPreferences,
    required this.feedbackHistory,
    required this.createdAt,
    required this.lastUpdated,
  });

  factory UserProfile.defaultProfile(String userId) {
    return UserProfile(
      userId: userId,
      investmentStyle: InvestmentStyle.balanced,
      contentPreferences: [
        ContentPreference(
          contentType: PushContentType.price_change,
          preferenceScore: 0.8,
        ),
      ],
      feedbackHistory: {},
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
    );
  }

  void recordFeedback(String contentId, UserFeedback feedback) {
    feedbackHistory[contentId] = feedback;
    lastUpdated = DateTime.now();
  }
}

/// 内容偏好
class ContentPreference {
  final PushContentType contentType;
  final double preferenceScore;

  const ContentPreference({
    required this.contentType,
    required this.preferenceScore,
  });
}

/// 用户反馈
class UserFeedback {
  final String contentId;
  final FeedbackType type;
  final DateTime timestamp;
  final String? comment;

  const UserFeedback({
    required this.contentId,
    required this.type,
    required this.timestamp,
    this.comment,
  });
}

/// 反馈类型
enum FeedbackType {
  positive,
  negative,
  neutral,
}
