import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'fund_ranking.dart';
import 'multi_dimensional_comparison_criteria.dart';

part 'comparison_result.g.dart';

/// 基金对比结果实体类
///
/// 包含多维度对比的所有计算结果和统计信息
@JsonSerializable()
class ComparisonResult extends Equatable {
  /// 对比条件
  final MultiDimensionalComparisonCriteria criteria;

  /// 对比的基金数据
  final List<FundComparisonData> fundData;

  /// 统计信息
  final ComparisonStatistics statistics;

  /// 计算时间
  final DateTime calculatedAt;

  /// 数据来源
  final String dataSource;

  /// 是否有错误
  final bool hasError;

  /// 错误信息
  final String? errorMessage;

  const ComparisonResult({
    required this.criteria,
    required this.fundData,
    required this.statistics,
    required this.calculatedAt,
    this.dataSource = 'API',
    this.hasError = false,
    this.errorMessage,
  });

  /// 从JSON创建实例
  factory ComparisonResult.fromJson(Map<String, dynamic> json) =>
      _$ComparisonResultFromJson(json);

  /// 转换为JSON
  Map<String, dynamic> toJson() => _$ComparisonResultToJson(this);

  /// 获取指定基金的数据
  FundComparisonData? getFundData(String fundCode) {
    try {
      return fundData.firstWhere((data) => data.fundCode == fundCode);
    } catch (e) {
      return null;
    }
  }

  /// 获取指定时间段的对比数据
  List<FundComparisonData> getPeriodData(RankingPeriod period) {
    return fundData.where((data) => data.period == period).toList();
  }

  /// 获取最佳表现基金（按指定指标）
  FundComparisonData? getBestPerformingFund(
      {ComparisonMetric metric = ComparisonMetric.totalReturn}) {
    if (fundData.isEmpty) return null;

    switch (metric) {
      case ComparisonMetric.totalReturn:
        return fundData.reduce((a, b) => a.totalReturn > b.totalReturn ? a : b);
      case ComparisonMetric.annualizedReturn:
        return fundData
            .reduce((a, b) => a.annualizedReturn > b.annualizedReturn ? a : b);
      case ComparisonMetric.volatility:
        return fundData.reduce((a, b) => a.volatility < b.volatility ? a : b);
      case ComparisonMetric.sharpeRatio:
        return fundData.reduce((a, b) => a.sharpeRatio > b.sharpeRatio ? a : b);
      case ComparisonMetric.maxDrawdown:
        return fundData.reduce((a, b) => a.maxDrawdown < b.maxDrawdown ? a : b);
    }
  }

  /// 获取最差表现基金（按指定指标）
  FundComparisonData? getWorstPerformingFund(
      {ComparisonMetric metric = ComparisonMetric.totalReturn}) {
    if (fundData.isEmpty) return null;

    switch (metric) {
      case ComparisonMetric.totalReturn:
        return fundData.reduce((a, b) => a.totalReturn < b.totalReturn ? a : b);
      case ComparisonMetric.annualizedReturn:
        return fundData
            .reduce((a, b) => a.annualizedReturn < b.annualizedReturn ? a : b);
      case ComparisonMetric.volatility:
        return fundData.reduce((a, b) => a.volatility > b.volatility ? a : b);
      case ComparisonMetric.sharpeRatio:
        return fundData.reduce((a, b) => a.sharpeRatio < b.sharpeRatio ? a : b);
      case ComparisonMetric.maxDrawdown:
        return fundData.reduce((a, b) => a.maxDrawdown > b.maxDrawdown ? a : b);
    }
  }

  @override
  List<Object?> get props => [
        criteria,
        fundData,
        statistics,
        calculatedAt,
        dataSource,
        hasError,
        errorMessage,
      ];

  @override
  String toString() {
    return 'ComparisonResult('
        'funds: ${fundData.length}, '
        'periods: ${criteria.periods.length}, '
        'calculatedAt: $calculatedAt)';
  }
}

/// 基金对比数据实体类
@JsonSerializable()
class FundComparisonData extends Equatable {
  /// 基金代码
  final String fundCode;

  /// 基金名称
  final String fundName;

  /// 基金类型
  final String fundType;

  /// 时间段
  final RankingPeriod period;

  /// 累计收益率
  final double totalReturn;

  /// 年化收益率
  final double annualizedReturn;

  /// 波动率
  final double volatility;

  /// 夏普比率
  final double sharpeRatio;

  /// 最大回撤
  final double maxDrawdown;

  /// 排名
  final int ranking;

  /// 同类平均收益率
  final double categoryAverage;

  /// 超越同类百分比
  final double beatCategoryPercent;

  /// 基准收益率
  final double benchmarkReturn;

  /// 超越基准百分比
  final double beatBenchmarkPercent;

  const FundComparisonData({
    required this.fundCode,
    required this.fundName,
    required this.fundType,
    required this.period,
    required this.totalReturn,
    required this.annualizedReturn,
    required this.volatility,
    required this.sharpeRatio,
    required this.maxDrawdown,
    required this.ranking,
    required this.categoryAverage,
    required this.beatCategoryPercent,
    required this.benchmarkReturn,
    required this.beatBenchmarkPercent,
  });

  /// 从JSON创建实例
  factory FundComparisonData.fromJson(Map<String, dynamic> json) =>
      _$FundComparisonDataFromJson(json);

  /// 转换为JSON
  Map<String, dynamic> toJson() => _$FundComparisonDataToJson(this);

  /// 是否为正收益
  bool get isPositiveReturn => totalReturn > 0;

  /// 收益率等级
  PerformanceGrade get performanceGrade {
    if (totalReturn >= 0.20) return PerformanceGrade.excellent;
    if (totalReturn >= 0.10) return PerformanceGrade.good;
    if (totalReturn >= 0) return PerformanceGrade.average;
    if (totalReturn >= -0.10) return PerformanceGrade.poor;
    return PerformanceGrade.terrible;
  }

  @override
  List<Object?> get props => [
        fundCode,
        fundName,
        fundType,
        period,
        totalReturn,
        annualizedReturn,
        volatility,
        sharpeRatio,
        maxDrawdown,
        ranking,
        categoryAverage,
        beatCategoryPercent,
        benchmarkReturn,
        beatBenchmarkPercent,
      ];
}

/// 对比统计信息实体类
@JsonSerializable()
class ComparisonStatistics extends Equatable {
  /// 平均收益率
  final double averageReturn;

  /// 最高收益率
  final double maxReturn;

  /// 最低收益率
  final double minReturn;

  /// 收益率标准差
  final double returnStdDev;

  /// 平均波动率
  final double averageVolatility;

  /// 最高波动率
  final double maxVolatility;

  /// 最低波动率
  final double minVolatility;

  /// 平均夏普比率
  final double averageSharpeRatio;

  /// 相关性矩阵
  final Map<String, Map<String, double>> correlationMatrix;

  /// 数据更新时间
  final DateTime updatedAt;

  const ComparisonStatistics({
    required this.averageReturn,
    required this.maxReturn,
    required this.minReturn,
    required this.returnStdDev,
    required this.averageVolatility,
    required this.maxVolatility,
    required this.minVolatility,
    required this.averageSharpeRatio,
    required this.correlationMatrix,
    required this.updatedAt,
  });

  /// 从JSON创建实例
  factory ComparisonStatistics.fromJson(Map<String, dynamic> json) =>
      _$ComparisonStatisticsFromJson(json);

  /// 转换为JSON
  Map<String, dynamic> toJson() => _$ComparisonStatisticsToJson(this);

  @override
  List<Object?> get props => [
        averageReturn,
        maxReturn,
        minReturn,
        returnStdDev,
        averageVolatility,
        maxVolatility,
        minVolatility,
        averageSharpeRatio,
        correlationMatrix,
        updatedAt,
      ];
}

/// 表现等级枚举
enum PerformanceGrade {
  excellent, // 优秀
  good, // 良好
  average, // 一般
  poor, // 较差
  terrible, // 很差
}
