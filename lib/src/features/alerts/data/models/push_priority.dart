import 'package:equatable/equatable.dart';

/// 推送优先级
class PushPriority extends Equatable {
  /// 事件ID
  final String eventId;

  /// 优先级级别
  final PushPriorityLevel priority;

  /// 优先级分数 (0-100)
  final double score;

  /// 优先级原因
  final String reason;

  /// 计算时间
  final DateTime calculatedAt;

  /// 影响因素
  final Map<String, double> factors;

  const PushPriority({
    required this.eventId,
    required this.priority,
    required this.score,
    required this.reason,
    required this.calculatedAt,
    required this.factors,
  });

  /// 是否为紧急推送
  bool get isUrgent => priority == PushPriorityLevel.critical;

  /// 获取优先级描述
  String get priorityDescription {
    switch (priority) {
      case PushPriorityLevel.critical:
        return '紧急';
      case PushPriorityLevel.high:
        return '高';
      case PushPriorityLevel.medium:
        return '中';
      case PushPriorityLevel.low:
        return '低';
    }
  }

  /// 获取优先级颜色代码
  String get priorityColorCode {
    switch (priority) {
      case PushPriorityLevel.critical:
        return 'red';
      case PushPriorityLevel.high:
        return 'orange';
      case PushPriorityLevel.medium:
        return 'yellow';
      case PushPriorityLevel.low:
        return 'gray';
    }
  }

  @override
  List<Object?> get props => [
        eventId,
        priority,
        score,
        reason,
        calculatedAt,
        factors,
      ];

  @override
  String toString() {
    return 'PushPriority(eventId: $eventId, priority: $priority, score: $score)';
  }
}

/// 推送优先级级别
enum PushPriorityLevel {
  /// 低优先级
  low,

  /// 中等优先级
  medium,

  /// 高优先级
  high,

  /// 紧急优先级
  critical,
}

/// 推送频率
enum PushFrequency {
  /// 实时推送
  realTime,

  /// 高频推送（15分钟）
  high,

  /// 中频推送（1小时）
  medium,

  /// 低频推送（4小时）
  low,

  /// 每日汇总
  daily,
}
