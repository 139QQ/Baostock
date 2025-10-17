import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'fund_ranking.dart';

part 'ranking_statistics.g.dart';

/// 排行榜统计信息实体
@JsonSerializable()
class RankingStatistics extends Equatable {
  /// 基金总数
  final int totalFunds;

  /// 平均收益率
  final double averageReturn;

  /// 表现最好的基金
  final FundRanking? topPerformer;

  /// 表现最差的基金
  final FundRanking? worstPerformer;

  /// 波动率指数
  final double volatilityIndex;

  /// 夏普比率
  final double sharpeRatio;

  /// 最大回撤
  final double maxDrawdown;

  /// 正收益率基金比例
  final double positiveReturnRate;

  /// 平均风险等级
  final double averageRiskLevel;

  /// 更新时间
  final DateTime updateTime;

  const RankingStatistics({
    required this.totalFunds,
    required this.averageReturn,
    this.topPerformer,
    this.worstPerformer,
    required this.volatilityIndex,
    required this.sharpeRatio,
    required this.maxDrawdown,
    required this.positiveReturnRate,
    required this.averageRiskLevel,
    required this.updateTime,
  });

  /// 从JSON创建RankingStatistics实例
  factory RankingStatistics.fromJson(Map<String, dynamic> json) =>
      _$RankingStatisticsFromJson(json);

  /// 转换为JSON
  Map<String, dynamic> toJson() => _$RankingStatisticsToJson(this);

  /// 创建副本并更新指定字段
  RankingStatistics copyWith({
    int? totalFunds,
    double? averageReturn,
    FundRanking? topPerformer,
    FundRanking? worstPerformer,
    double? volatilityIndex,
    double? sharpeRatio,
    double? maxDrawdown,
    double? positiveReturnRate,
    double? averageRiskLevel,
    DateTime? updateTime,
  }) {
    return RankingStatistics(
      totalFunds: totalFunds ?? this.totalFunds,
      averageReturn: averageReturn ?? this.averageReturn,
      topPerformer: topPerformer ?? this.topPerformer,
      worstPerformer: worstPerformer ?? this.worstPerformer,
      volatilityIndex: volatilityIndex ?? this.volatilityIndex,
      sharpeRatio: sharpeRatio ?? this.sharpeRatio,
      maxDrawdown: maxDrawdown ?? this.maxDrawdown,
      positiveReturnRate: positiveReturnRate ?? this.positiveReturnRate,
      averageRiskLevel: averageRiskLevel ?? this.averageRiskLevel,
      updateTime: updateTime ?? this.updateTime,
    );
  }

  @override
  List<Object?> get props => [
        totalFunds,
        averageReturn,
        topPerformer,
        worstPerformer,
        volatilityIndex,
        sharpeRatio,
        maxDrawdown,
        positiveReturnRate,
        averageRiskLevel,
        updateTime,
      ];

  @override
  String toString() {
    return 'RankingStatistics{'
        'totalFunds: $totalFunds, '
        'averageReturn: ${averageReturn.toStringAsFixed(2)}%, '
        'volatilityIndex: ${volatilityIndex.toStringAsFixed(2)}, '
        'sharpeRatio: ${sharpeRatio.toStringAsFixed(2)}, '
        'maxDrawdown: ${maxDrawdown.toStringAsFixed(2)}%, '
        'positiveReturnRate: ${(positiveReturnRate * 100).toStringAsFixed(1)}%'
        '}';
  }

  /// 获取风险等级描述
  String get riskLevelDescription {
    if (averageRiskLevel <= 1.5) return '低风险';
    if (averageRiskLevel <= 2.5) return '中低风险';
    if (averageRiskLevel <= 3.5) return '中高风险';
    return '高风险';
  }

  /// 获取表现评价
  String get performanceEvaluation {
    if (averageReturn > 15) return '优秀';
    if (averageReturn > 10) return '良好';
    if (averageReturn > 5) return '一般';
    if (averageReturn > 0) return '较差';
    return '很差';
  }

  /// 获取波动率评价
  String get volatilityEvaluation {
    if (volatilityIndex < 10) return '低波动';
    if (volatilityIndex < 20) return '中等波动';
    return '高波动';
  }
}
