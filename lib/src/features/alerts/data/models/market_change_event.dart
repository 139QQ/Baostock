import 'package:equatable/equatable.dart';

import 'change_category.dart';
import 'change_severity.dart';

/// 市场变化事件
class MarketChangeEvent extends Equatable {
  /// 事件唯一标识
  final String id;

  /// 变化类型
  final MarketChangeType type;

  /// 变化实体ID (基金代码或指数代码)
  final String entityId;

  /// 变化实体名称
  final String entityName;

  /// 变化类别
  final ChangeCategory category;

  /// 变化严重程度
  final ChangeSeverity severity;

  /// 变化重要性分数 (0-100)
  final double importance;

  /// 变化率 (百分比)
  final double changeRate;

  /// 当前值
  final String currentValue;

  /// 前一个值
  final String previousValue;

  /// 变化时间戳
  final DateTime timestamp;

  /// 事件元数据
  final Map<String, dynamic> metadata;

  /// 相关基金列表 (如果是市场指数变化)
  final List<String> relatedFunds;

  /// 是否已推送
  final bool isPushed;

  /// 推送时间
  final DateTime? pushedAt;

  /// 构造函数
  const MarketChangeEvent({
    required this.id,
    required this.type,
    required this.entityId,
    required this.entityName,
    required this.category,
    required this.severity,
    required this.importance,
    required this.changeRate,
    required this.currentValue,
    required this.previousValue,
    required this.timestamp,
    required this.metadata,
    this.relatedFunds = const [],
    this.isPushed = false,
    this.pushedAt,
  });

  /// 复制并修改部分属性
  MarketChangeEvent copyWith({
    String? id,
    MarketChangeType? type,
    String? entityId,
    String? entityName,
    ChangeCategory? category,
    ChangeSeverity? severity,
    double? importance,
    double? changeRate,
    String? currentValue,
    String? previousValue,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
    List<String>? relatedFunds,
    bool? isPushed,
    DateTime? pushedAt,
  }) {
    // 如果isPushed被设置为true，但pushedAt没有被提供，则自动设置为当前时间
    final finalIsPushed = isPushed ?? this.isPushed;
    DateTime? finalPushedAt = pushedAt;

    if ((isPushed == true && !this.isPushed) && pushedAt == null) {
      finalPushedAt = DateTime.now();
    } else if (pushedAt == null) {
      finalPushedAt = this.pushedAt;
    }

    return MarketChangeEvent(
      id: id ?? this.id,
      type: type ?? this.type,
      entityId: entityId ?? this.entityId,
      entityName: entityName ?? this.entityName,
      category: category ?? this.category,
      severity: severity ?? this.severity,
      importance: importance ?? this.importance,
      changeRate: changeRate ?? this.changeRate,
      currentValue: currentValue ?? this.currentValue,
      previousValue: previousValue ?? this.previousValue,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
      relatedFunds: relatedFunds ?? this.relatedFunds,
      isPushed: finalIsPushed,
      pushedAt: finalPushedAt,
    );
  }

  /// 标记为已推送
  MarketChangeEvent markAsPushed() {
    return copyWith(
      isPushed: true,
      pushedAt: DateTime.now(),
    );
  }

  /// 获取变化描述
  String get changeDescription {
    final sign = changeRate >= 0 ? '+' : '';
    return '$sign${changeRate.toStringAsFixed(2)}%';
  }

  /// 获取变化趋势
  String get trend {
    if (changeRate > 0) return '上涨';
    if (changeRate < 0) return '下跌';
    return '持平';
  }

  /// 获取实体类型描述
  String get entityTypeDescription {
    switch (type) {
      case MarketChangeType.fundNav:
        return '基金净值';
      case MarketChangeType.marketIndex:
        return '市场指数';
    }
  }

  /// 获取变化类别描述
  String get categoryDescription {
    switch (category) {
      case ChangeCategory.priceChange:
        return '价格变化';
      case ChangeCategory.trendChange:
        return '趋势变化';
      case ChangeCategory.abnormalEvent:
        return '异常事件';
    }
  }

  /// 获取严重程度描述
  String get severityDescription {
    switch (severity) {
      case ChangeSeverity.high:
        return '高';
      case ChangeSeverity.medium:
        return '中';
      case ChangeSeverity.low:
        return '低';
    }
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'entityId': entityId,
      'entityName': entityName,
      'category': category.name,
      'severity': severity.name,
      'importance': importance,
      'changeRate': changeRate,
      'currentValue': currentValue,
      'previousValue': previousValue,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
      'relatedFunds': relatedFunds,
      'isPushed': isPushed,
      'pushedAt': pushedAt?.toIso8601String(),
    };
  }

  /// 从JSON创建
  factory MarketChangeEvent.fromJson(Map<String, dynamic> json) {
    return MarketChangeEvent(
      id: json['id'] as String,
      type: MarketChangeType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MarketChangeType.fundNav,
      ),
      entityId: json['entityId'] as String,
      entityName: json['entityName'] as String,
      category: ChangeCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ChangeCategory.priceChange,
      ),
      severity: ChangeSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => ChangeSeverity.low,
      ),
      importance: (json['importance'] as num).toDouble(),
      changeRate: (json['changeRate'] as num).toDouble(),
      currentValue: json['currentValue'] as String,
      previousValue: json['previousValue'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map),
      relatedFunds: List<String>.from(json['relatedFunds'] as List? ?? []),
      isPushed: json['isPushed'] as bool? ?? false,
      pushedAt: json['pushedAt'] != null
          ? DateTime.parse(json['pushedAt'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        entityId,
        entityName,
        category,
        severity,
        importance,
        changeRate,
        currentValue,
        previousValue,
        timestamp,
        metadata,
        relatedFunds,
        isPushed,
        pushedAt,
      ];

  @override
  String toString() {
    return 'MarketChangeEvent(id: $id, type: $type, entity: $entityName, change: $changeDescription, severity: $severity)';
  }
}

/// 市场变化类型
enum MarketChangeType {
  fundNav,
  marketIndex,
}
