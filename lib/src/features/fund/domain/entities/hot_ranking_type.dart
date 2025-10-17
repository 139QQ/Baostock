import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'fund_ranking.dart';

part 'hot_ranking_type.g.dart';

/// 热门排行榜类型实体
@JsonSerializable()
class HotRankingType extends Equatable {
  /// 排行榜类型
  final RankingType type;

  /// 时间段
  final RankingPeriod period;

  /// 排行榜名称
  final String name;

  /// 排行榜描述
  final String description;

  /// 热度指数（0-100）
  final int popularity;

  /// 排行榜图标
  final String? icon;

  /// 排行榜颜色
  final String? color;

  /// 是否推荐
  final bool isRecommended;

  /// 排行榜标签
  final List<String> tags;

  const HotRankingType({
    required this.type,
    required this.period,
    required this.name,
    required this.description,
    required this.popularity,
    this.icon,
    this.color,
    this.isRecommended = false,
    this.tags = const [],
  });

  /// 从JSON创建HotRankingType实例
  factory HotRankingType.fromJson(Map<String, dynamic> json) =>
      _$HotRankingTypeFromJson(json);

  /// 转换为JSON
  Map<String, dynamic> toJson() => _$HotRankingTypeToJson(this);

  /// 创建副本并更新指定字段
  HotRankingType copyWith({
    RankingType? type,
    RankingPeriod? period,
    String? name,
    String? description,
    int? popularity,
    String? icon,
    String? color,
    bool? isRecommended,
    List<String>? tags,
  }) {
    return HotRankingType(
      type: type ?? this.type,
      period: period ?? this.period,
      name: name ?? this.name,
      description: description ?? this.description,
      popularity: popularity ?? this.popularity,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isRecommended: isRecommended ?? this.isRecommended,
      tags: tags ?? this.tags,
    );
  }

  @override
  List<Object?> get props => [
        type,
        period,
        name,
        description,
        popularity,
        icon,
        color,
        isRecommended,
        tags,
      ];

  @override
  String toString() {
    return 'HotRankingType{'
        'type: $type, '
        'period: $period, '
        'name: $name, '
        'popularity: $popularity'
        '}';
  }

  /// 获取热度等级
  String get popularityLevel {
    if (popularity >= 90) return '超热门';
    if (popularity >= 70) return '热门';
    if (popularity >= 50) return '流行';
    return '一般';
  }

  /// 获取热度颜色
  String get popularityColor {
    if (popularity >= 90) return '#FF4444'; // 红色
    if (popularity >= 70) return '#FF8800'; // 橙色
    if (popularity >= 50) return '#FFBB33'; // 黄色
    return '#888888'; // 灰色
  }

  /// 是否为超高热度
  bool get isSuperHot => popularity >= 90;

  /// 是否为热门
  bool get isHot => popularity >= 70;
}
