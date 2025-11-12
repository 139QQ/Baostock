import 'package:equatable/equatable.dart';

/// 推送历史记录模型
///
/// 记录每次推送通知的详细信息，包括：
/// - 推送内容和时间
/// - 用户行为和反馈
/// - 推送效果统计
/// - 关联的市场变化事件
class PushHistoryRecord extends Equatable {
  /// 推送记录唯一标识
  final String id;

  /// 推送类型（market_change, fund_update, alert, etc.）
  final String pushType;

  /// 推送优先级
  final String priority;

  /// 推送标题
  final String title;

  /// 推送内容
  final String content;

  /// 推送时间戳
  final DateTime timestamp;

  /// 用户是否已读
  final bool isRead;

  /// 阅读时间（如果已读）
  final DateTime? readAt;

  /// 用户是否点击了推送
  final bool isClicked;

  /// 点击时间（如果点击了）
  final DateTime? clickedAt;

  /// 用户反馈（like, dislike, neutral）
  final String? userFeedback;

  /// 反馈时间
  final DateTime? feedbackAt;

  /// 推送是否成功送达
  final bool deliverySuccess;

  /// 送达失败原因（如果有）
  final String? deliveryFailureReason;

  /// 关联的市场变化事件ID列表
  final List<String> relatedEventIds;

  /// 关联的基金代码列表
  final List<String> relatedFundCodes;

  /// 关联的市场指数代码列表
  final List<String> relatedIndexCodes;

  /// 推送渠道（notification, in_app, email, etc.）
  final String channel;

  /// 推送模板ID
  final String? templateId;

  /// 个性化评分（0.0-1.0）
  final double personalizationScore;

  /// 推送效果评分（0.0-1.0）
  final double effectivenessScore;

  /// 推送耗时（毫秒）
  final int processingTimeMs;

  /// 推送时网络状态
  final String networkStatus;

  /// 用户当时活跃状态
  final String userActivityState;

  /// 推送设备信息
  final Map<String, dynamic> deviceInfo;

  /// 额外的元数据
  final Map<String, dynamic> metadata;

  const PushHistoryRecord({
    required this.id,
    required this.pushType,
    required this.priority,
    required this.title,
    required this.content,
    required this.timestamp,
    required this.isRead,
    this.readAt,
    required this.isClicked,
    this.clickedAt,
    this.userFeedback,
    this.feedbackAt,
    required this.deliverySuccess,
    this.deliveryFailureReason,
    required this.relatedEventIds,
    required this.relatedFundCodes,
    required this.relatedIndexCodes,
    required this.channel,
    this.templateId,
    required this.personalizationScore,
    required this.effectivenessScore,
    required this.processingTimeMs,
    required this.networkStatus,
    required this.userActivityState,
    required this.deviceInfo,
    required this.metadata,
  });

  /// 从JSON创建实例
  factory PushHistoryRecord.fromJson(Map<String, dynamic> json) {
    return PushHistoryRecord(
      id: json['id'] as String,
      pushType: json['pushType'] as String,
      priority: json['priority'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'] as String)
          : null,
      isClicked: json['isClicked'] as bool? ?? false,
      clickedAt: json['clickedAt'] != null
          ? DateTime.parse(json['clickedAt'] as String)
          : null,
      userFeedback: json['userFeedback'] as String?,
      feedbackAt: json['feedbackAt'] != null
          ? DateTime.parse(json['feedbackAt'] as String)
          : null,
      deliverySuccess: json['deliverySuccess'] as bool? ?? true,
      deliveryFailureReason: json['deliveryFailureReason'] as String?,
      relatedEventIds:
          List<String>.from(json['relatedEventIds'] as List? ?? []),
      relatedFundCodes:
          List<String>.from(json['relatedFundCodes'] as List? ?? []),
      relatedIndexCodes:
          List<String>.from(json['relatedIndexCodes'] as List? ?? []),
      channel: json['channel'] as String? ?? 'notification',
      templateId: json['templateId'] as String?,
      personalizationScore:
          (json['personalizationScore'] as num?)?.toDouble() ?? 0.0,
      effectivenessScore:
          (json['effectivenessScore'] as num?)?.toDouble() ?? 0.0,
      processingTimeMs: json['processingTimeMs'] as int? ?? 0,
      networkStatus: json['networkStatus'] as String? ?? 'unknown',
      userActivityState: json['userActivityState'] as String? ?? 'unknown',
      deviceInfo: Map<String, dynamic>.from(json['deviceInfo'] as Map? ?? {}),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pushType': pushType,
      'priority': priority,
      'title': title,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
      'isClicked': isClicked,
      'clickedAt': clickedAt?.toIso8601String(),
      'userFeedback': userFeedback,
      'feedbackAt': feedbackAt?.toIso8601String(),
      'deliverySuccess': deliverySuccess,
      'deliveryFailureReason': deliveryFailureReason,
      'relatedEventIds': relatedEventIds,
      'relatedFundCodes': relatedFundCodes,
      'relatedIndexCodes': relatedIndexCodes,
      'channel': channel,
      'templateId': templateId,
      'personalizationScore': personalizationScore,
      'effectivenessScore': effectivenessScore,
      'processingTimeMs': processingTimeMs,
      'networkStatus': networkStatus,
      'userActivityState': userActivityState,
      'deviceInfo': deviceInfo,
      'metadata': metadata,
    };
  }

  /// 创建副本
  PushHistoryRecord copyWith({
    String? id,
    String? pushType,
    String? priority,
    String? title,
    String? content,
    DateTime? timestamp,
    bool? isRead,
    DateTime? readAt,
    bool? isClicked,
    DateTime? clickedAt,
    String? userFeedback,
    DateTime? feedbackAt,
    bool? deliverySuccess,
    String? deliveryFailureReason,
    List<String>? relatedEventIds,
    List<String>? relatedFundCodes,
    List<String>? relatedIndexCodes,
    String? channel,
    String? templateId,
    double? personalizationScore,
    double? effectivenessScore,
    int? processingTimeMs,
    String? networkStatus,
    String? userActivityState,
    Map<String, dynamic>? deviceInfo,
    Map<String, dynamic>? metadata,
  }) {
    return PushHistoryRecord(
      id: id ?? this.id,
      pushType: pushType ?? this.pushType,
      priority: priority ?? this.priority,
      title: title ?? this.title,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      isClicked: isClicked ?? this.isClicked,
      clickedAt: clickedAt ?? this.clickedAt,
      userFeedback: userFeedback ?? this.userFeedback,
      feedbackAt: feedbackAt ?? this.feedbackAt,
      deliverySuccess: deliverySuccess ?? this.deliverySuccess,
      deliveryFailureReason:
          deliveryFailureReason ?? this.deliveryFailureReason,
      relatedEventIds: relatedEventIds ?? this.relatedEventIds,
      relatedFundCodes: relatedFundCodes ?? this.relatedFundCodes,
      relatedIndexCodes: relatedIndexCodes ?? this.relatedIndexCodes,
      channel: channel ?? this.channel,
      templateId: templateId ?? this.templateId,
      personalizationScore: personalizationScore ?? this.personalizationScore,
      effectivenessScore: effectivenessScore ?? this.effectivenessScore,
      processingTimeMs: processingTimeMs ?? this.processingTimeMs,
      networkStatus: networkStatus ?? this.networkStatus,
      userActivityState: userActivityState ?? this.userActivityState,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      metadata: metadata ?? this.metadata,
    );
  }

  /// 标记为已读
  PushHistoryRecord markAsRead() {
    return copyWith(
      isRead: true,
      readAt: DateTime.now(),
    );
  }

  /// 标记为已点击
  PushHistoryRecord markAsClicked() {
    return copyWith(
      isClicked: true,
      clickedAt: DateTime.now(),
    );
  }

  /// 设置用户反馈
  PushHistoryRecord withUserFeedback(String feedback) {
    return copyWith(
      userFeedback: feedback,
      feedbackAt: DateTime.now(),
    );
  }

  /// 更新效果评分
  PushHistoryRecord withEffectivenessScore(double score) {
    return copyWith(effectivenessScore: score);
  }

  /// 获取推送年龄（分钟）
  int get ageInMinutes {
    return DateTime.now().difference(timestamp).inMinutes;
  }

  /// 获取推送年龄（小时）
  int get ageInHours {
    return DateTime.now().difference(timestamp).inHours;
  }

  /// 获取推送年龄（天）
  int get ageInDays {
    return DateTime.now().difference(timestamp).inDays;
  }

  /// 是否为最近的推送（24小时内）
  bool get isRecent {
    return ageInHours < 24;
  }

  /// 是否为高优先级推送
  bool get isHighPriority {
    return priority.toLowerCase() == 'high';
  }

  /// 获取推送状态描述
  String get statusDescription {
    if (!deliverySuccess) {
      return '发送失败';
    }
    if (isClicked) {
      return '已点击';
    }
    if (isRead) {
      return '已读';
    }
    return '未读';
  }

  /// 获取推送年龄描述
  String get ageDescription {
    if (ageInMinutes < 1) {
      return '刚刚';
    } else if (ageInMinutes < 60) {
      return '${ageInMinutes}分钟前';
    } else if (ageInHours < 24) {
      return '${ageInHours}小时前';
    } else if (ageInDays < 30) {
      return '${ageInDays}天前';
    } else {
      return '${(ageInDays / 30).floor()}个月前';
    }
  }

  @override
  List<Object?> get props => [
        id,
        pushType,
        priority,
        title,
        content,
        timestamp,
        isRead,
        readAt,
        isClicked,
        clickedAt,
        userFeedback,
        feedbackAt,
        deliverySuccess,
        deliveryFailureReason,
        relatedEventIds,
        relatedFundCodes,
        relatedIndexCodes,
        channel,
        templateId,
        personalizationScore,
        effectivenessScore,
        processingTimeMs,
        networkStatus,
        userActivityState,
        deviceInfo,
        metadata,
      ];

  @override
  String toString() {
    return 'PushHistoryRecord('
        'id: $id, '
        'pushType: $pushType, '
        'priority: $priority, '
        'title: $title, '
        'timestamp: $timestamp, '
        'isRead: $isRead, '
        'isClicked: $isClicked, '
        'deliverySuccess: $deliverySuccess'
        ')';
  }
}
