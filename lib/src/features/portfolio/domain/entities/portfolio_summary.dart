import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'portfolio_holding.dart';
import 'portfolio_profit_metrics.dart';

part 'portfolio_summary.g.dart';

/// 组合汇总数据实体
///
/// 表示整个投资组合的汇总信息和表现
@JsonSerializable()
class PortfolioSummary extends Equatable {
  /// 组合ID
  final String portfolioId;

  /// 组合名称
  final String portfolioName;

  /// 分析日期
  final DateTime analysisDate;

  /// 基准指数代码
  final String? benchmarkCode;

  /// 基准指数名称
  final String? benchmarkName;

  // ===== 资产配置信息 =====

  /// 总资产金额
  final double totalAssets;

  /// 总市值
  final double totalMarketValue;

  /// 总成本
  final double totalCost;

  /// 现金及现金等价物
  final double cashAndEquivalents;

  /// 持仓基金数量
  final int numberOfHoldings;

  /// 持仓基金列表
  final List<PortfolioHolding> holdings;

  // ===== 收益汇总 =====

  /// 总收益金额
  final double totalReturnAmount;

  /// 总收益率
  final double totalReturnRate;

  /// 今日收益金额
  final double dailyReturnAmount;

  /// 今日收益率
  final double dailyReturnRate;

  /// 年化收益率
  final double annualizedReturn;

  /// 累计分红金额
  final double totalDividends;

  // ===== 风险指标 =====

  /// 组合波动率
  final double? portfolioVolatility;

  /// 最大回撤
  final double? maxDrawdown;

  /// 夏普比率
  final double? sharpeRatio;

  /// Beta值
  final double? beta;

  // ===== 资产配置分布 =====

  /// 股票型基金占比
  final double equityFundRatio;

  /// 债券型基金占比
  final double bondFundRatio;

  /// 混合型基金占比
  final double hybridFundRatio;

  /// 货币型基金占比
  final double moneyMarketFundRatio;

  /// 其他类型基金占比
  final double otherFundRatio;

  // ===== 表现排名 =====

  /// 组合评级
  final PortfolioRating portfolioRating;

  /// 风险等级
  final RiskLevel riskLevel;

  /// 同类排名
  final int? categoryRanking;

  /// 同类总数
  final int? categoryTotal;

  // ===== 时间维度表现 =====

  /// 近1周收益率
  final double return1Week;

  /// 近1月收益率
  final double return1Month;

  /// 近3月收益率
  final double return3Months;

  /// 近6月收益率
  final double return6Months;

  /// 近1年收益率
  final double return1Year;

  /// 今年来收益率
  final double returnYTD;

  // ===== 分散化指标 =====

  /// 最大单一持仓占比
  final double maxHoldingRatio;

  /// 前5大持仓占比
  final double top5HoldingsRatio;

  /// 前10大持仓占比
  final double top10HoldingsRatio;

  /// 行业集中度
  final double? industryConcentration;

  // ===== 交易活动 =====

  /// 交易频率（次/月）
  final double? tradingFrequency;

  /// 平均持仓天数
  final double? averageHoldingDays;

  /// 换手率
  final double? turnoverRate;

  // ===== 分析元数据 =====

  /// 数据开始日期
  final DateTime dataStartDate;

  /// 数据质量评级
  final DataQuality dataQuality;

  /// 最后更新时间
  final DateTime lastUpdated;

  /// 备注
  final String? notes;

  const PortfolioSummary({
    required this.portfolioId,
    required this.portfolioName,
    required this.analysisDate,
    this.benchmarkCode,
    this.benchmarkName,
    required this.totalAssets,
    required this.totalMarketValue,
    required this.totalCost,
    required this.cashAndEquivalents,
    required this.numberOfHoldings,
    required this.holdings,
    required this.totalReturnAmount,
    required this.totalReturnRate,
    required this.dailyReturnAmount,
    required this.dailyReturnRate,
    required this.annualizedReturn,
    this.totalDividends = 0.0,
    this.portfolioVolatility,
    this.maxDrawdown,
    this.sharpeRatio,
    this.beta,
    this.equityFundRatio = 0.0,
    this.bondFundRatio = 0.0,
    this.hybridFundRatio = 0.0,
    this.moneyMarketFundRatio = 0.0,
    this.otherFundRatio = 0.0,
    this.portfolioRating = PortfolioRating.neutral,
    this.riskLevel = RiskLevel.medium,
    this.categoryRanking,
    this.categoryTotal,
    required this.return1Week,
    required this.return1Month,
    required this.return3Months,
    required this.return6Months,
    required this.return1Year,
    required this.returnYTD,
    required this.maxHoldingRatio,
    required this.top5HoldingsRatio,
    required this.top10HoldingsRatio,
    this.industryConcentration,
    this.tradingFrequency,
    this.averageHoldingDays,
    this.turnoverRate,
    required this.dataStartDate,
    this.dataQuality = DataQuality.good,
    required this.lastUpdated,
    this.notes,
  });

  /// 从JSON创建PortfolioSummary实例
  factory PortfolioSummary.fromJson(Map<String, dynamic> json) =>
      _$PortfolioSummaryFromJson(json);

  /// 转换为JSON
  Map<String, dynamic> toJson() => _$PortfolioSummaryToJson(this);

  /// 创建副本并更新指定字段
  PortfolioSummary copyWith({
    String? portfolioId,
    String? portfolioName,
    DateTime? analysisDate,
    String? benchmarkCode,
    String? benchmarkName,
    double? totalAssets,
    double? totalMarketValue,
    double? totalCost,
    double? cashAndEquivalents,
    int? numberOfHoldings,
    List<PortfolioHolding>? holdings,
    double? totalReturnAmount,
    double? totalReturnRate,
    double? dailyReturnAmount,
    double? dailyReturnRate,
    double? annualizedReturn,
    double? totalDividends,
    double? portfolioVolatility,
    double? maxDrawdown,
    double? sharpeRatio,
    double? beta,
    double? equityFundRatio,
    double? bondFundRatio,
    double? hybridFundRatio,
    double? moneyMarketFundRatio,
    double? otherFundRatio,
    PortfolioRating? portfolioRating,
    RiskLevel? riskLevel,
    int? categoryRanking,
    int? categoryTotal,
    double? return1Week,
    double? return1Month,
    double? return3Months,
    double? return6Months,
    double? return1Year,
    double? returnYTD,
    double? maxHoldingRatio,
    double? top5HoldingsRatio,
    double? top10HoldingsRatio,
    double? industryConcentration,
    double? tradingFrequency,
    double? averageHoldingDays,
    double? turnoverRate,
    DateTime? dataStartDate,
    DataQuality? dataQuality,
    DateTime? lastUpdated,
    String? notes,
  }) {
    return PortfolioSummary(
      portfolioId: portfolioId ?? this.portfolioId,
      portfolioName: portfolioName ?? this.portfolioName,
      analysisDate: analysisDate ?? this.analysisDate,
      benchmarkCode: benchmarkCode ?? this.benchmarkCode,
      benchmarkName: benchmarkName ?? this.benchmarkName,
      totalAssets: totalAssets ?? this.totalAssets,
      totalMarketValue: totalMarketValue ?? this.totalMarketValue,
      totalCost: totalCost ?? this.totalCost,
      cashAndEquivalents: cashAndEquivalents ?? this.cashAndEquivalents,
      numberOfHoldings: numberOfHoldings ?? this.numberOfHoldings,
      holdings: holdings ?? this.holdings,
      totalReturnAmount: totalReturnAmount ?? this.totalReturnAmount,
      totalReturnRate: totalReturnRate ?? this.totalReturnRate,
      dailyReturnAmount: dailyReturnAmount ?? this.dailyReturnAmount,
      dailyReturnRate: dailyReturnRate ?? this.dailyReturnRate,
      annualizedReturn: annualizedReturn ?? this.annualizedReturn,
      totalDividends: totalDividends ?? this.totalDividends,
      portfolioVolatility: portfolioVolatility ?? this.portfolioVolatility,
      maxDrawdown: maxDrawdown ?? this.maxDrawdown,
      sharpeRatio: sharpeRatio ?? this.sharpeRatio,
      beta: beta ?? this.beta,
      equityFundRatio: equityFundRatio ?? this.equityFundRatio,
      bondFundRatio: bondFundRatio ?? this.bondFundRatio,
      hybridFundRatio: hybridFundRatio ?? this.hybridFundRatio,
      moneyMarketFundRatio: moneyMarketFundRatio ?? this.moneyMarketFundRatio,
      otherFundRatio: otherFundRatio ?? this.otherFundRatio,
      portfolioRating: portfolioRating ?? this.portfolioRating,
      riskLevel: riskLevel ?? this.riskLevel,
      categoryRanking: categoryRanking ?? this.categoryRanking,
      categoryTotal: categoryTotal ?? this.categoryTotal,
      return1Week: return1Week ?? this.return1Week,
      return1Month: return1Month ?? this.return1Month,
      return3Months: return3Months ?? this.return3Months,
      return6Months: return6Months ?? this.return6Months,
      return1Year: return1Year ?? this.return1Year,
      returnYTD: returnYTD ?? this.returnYTD,
      maxHoldingRatio: maxHoldingRatio ?? this.maxHoldingRatio,
      top5HoldingsRatio: top5HoldingsRatio ?? this.top5HoldingsRatio,
      top10HoldingsRatio: top10HoldingsRatio ?? this.top10HoldingsRatio,
      industryConcentration:
          industryConcentration ?? this.industryConcentration,
      tradingFrequency: tradingFrequency ?? this.tradingFrequency,
      averageHoldingDays: averageHoldingDays ?? this.averageHoldingDays,
      turnoverRate: turnoverRate ?? this.turnoverRate,
      dataStartDate: dataStartDate ?? this.dataStartDate,
      dataQuality: dataQuality ?? this.dataQuality,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      notes: notes ?? this.notes,
    );
  }

  // ===== 便捷访问属性 =====

  /// 获取总收益率百分比
  double get totalReturnPercentage => totalReturnRate * 100;

  /// 获取今日收益率百分比
  double get dailyReturnPercentage => dailyReturnRate * 100;

  /// 获取年化收益率百分比
  double get annualizedReturnPercentage => annualizedReturn * 100;

  /// 获取最大回撤百分比
  double get maxDrawdownPercentage => (maxDrawdown ?? 0.0) * 100;

  /// 获取波动率百分比
  double get portfolioVolatilityPercentage =>
      (portfolioVolatility ?? 0.0) * 100;

  /// 是否为盈利组合
  bool get isProfitable => totalReturnAmount > 0;

  /// 今日是否盈利
  bool get isDailyProfit => dailyReturnAmount > 0;

  /// 是否为分散化组合（最大持仓<20%）
  bool get isDiversified => maxHoldingRatio < 0.20;

  /// 是否为集中持仓（最大持仓>50%）
  bool get isConcentrated => maxHoldingRatio > 0.50;

  /// 获取现金比例
  double get cashRatio =>
      totalMarketValue == 0 ? 0.0 : cashAndEquivalents / totalMarketValue;

  /// 获取投资比例
  double get investmentRatio => 1.0 - cashRatio;

  /// 获取股票投资比例
  double get equityInvestmentRatio => investmentRatio * equityFundRatio;

  /// 获取债券投资比例
  double get bondInvestmentRatio => investmentRatio * bondFundRatio;

  /// 获取混合投资比例
  double get hybridInvestmentRatio => investmentRatio * hybridFundRatio;

  /// 获取货币投资比例
  double get moneyMarketInvestmentRatio =>
      investmentRatio * moneyMarketFundRatio;

  /// 计算赫芬达尔指数（衡量集中度）
  double get herfindahlIndex {
    if (holdings.isEmpty) return 0.0;

    double sum = 0.0;
    for (final holding in holdings) {
      final weight = holding.calculateWeight(totalMarketValue);
      sum += weight * weight;
    }
    return sum;
  }

  /// 获取集中度评级
  ConcentrationLevel get concentrationLevel {
    if (maxHoldingRatio < 0.10) return ConcentrationLevel.veryLow;
    if (maxHoldingRatio < 0.20) return ConcentrationLevel.low;
    if (maxHoldingRatio < 0.30) return ConcentrationLevel.medium;
    if (maxHoldingRatio < 0.50) return ConcentrationLevel.high;
    return ConcentrationLevel.veryHigh;
  }

  /// 获取排名描述
  String get rankingDescription {
    if (categoryRanking == null || categoryTotal == null) return 'N/A';
    return '$categoryRanking/$categoryTotal';
  }

  /// 获取排名百分比
  double get rankingPercentile {
    if (categoryRanking == null ||
        categoryTotal == null ||
        categoryTotal == 0) {
      return 0.0;
    }
    return (categoryRanking! - 1) / categoryTotal!;
  }

  /// 获取排名百分比描述
  String get rankingPercentileDescription {
    final percentile = rankingPercentile * 100;
    return '前${percentile.toStringAsFixed(1)}%';
  }

  /// 验证数据完整性
  bool isComplete() {
    return totalMarketValue > 0 &&
        holdings.isNotEmpty &&
        dataQuality != DataQuality.poor;
  }

  /// 计算组合的整体表现评分（0-100分）
  double calculatePerformanceScore() {
    double score = 50.0; // 基础分

    // 收益表现（40分）
    final annualReturnScore = (annualizedReturn.clamp(-0.5, 0.5) + 0.5) * 40;
    score += annualReturnScore;

    // 风险调整收益（20分）
    final sharpeScore = ((sharpeRatio ?? 0.0).clamp(-2.0, 3.0) + 2.0) * 4;
    score += sharpeScore;

    // 风险控制（20分）
    final maxDDScore = (1.0 - (maxDrawdown ?? 0.0).clamp(0.0, 1.0)) * 20;
    score += maxDDScore;

    // 分散化（20分）
    final diversificationScore =
        isDiversified ? 20 : (maxHoldingRatio < 0.4 ? 10 : 0);
    score += diversificationScore;

    return score.clamp(0.0, 100.0);
  }

  /// 获取表现评级描述
  String get performanceGrade {
    final score = calculatePerformanceScore();
    if (score >= 90) return 'A+';
    if (score >= 85) return 'A';
    if (score >= 80) return 'A-';
    if (score >= 75) return 'B+';
    if (score >= 70) return 'B';
    if (score >= 65) return 'B-';
    if (score >= 60) return 'C+';
    if (score >= 55) return 'C';
    if (score >= 50) return 'C-';
    return 'D';
  }

  @override
  List<Object?> get props => [
        portfolioId,
        portfolioName,
        analysisDate,
        benchmarkCode,
        benchmarkName,
        totalAssets,
        totalMarketValue,
        totalCost,
        cashAndEquivalents,
        numberOfHoldings,
        holdings,
        totalReturnAmount,
        totalReturnRate,
        dailyReturnAmount,
        dailyReturnRate,
        annualizedReturn,
        totalDividends,
        portfolioVolatility,
        maxDrawdown,
        sharpeRatio,
        beta,
        equityFundRatio,
        bondFundRatio,
        hybridFundRatio,
        moneyMarketFundRatio,
        otherFundRatio,
        portfolioRating,
        riskLevel,
        categoryRanking,
        categoryTotal,
        return1Week,
        return1Month,
        return3Months,
        return6Months,
        return1Year,
        returnYTD,
        maxHoldingRatio,
        top5HoldingsRatio,
        top10HoldingsRatio,
        industryConcentration,
        tradingFrequency,
        averageHoldingDays,
        turnoverRate,
        dataStartDate,
        dataQuality,
        lastUpdated,
        notes,
      ];

  @override
  String toString() {
    return 'PortfolioSummary{'
        'portfolioName: $portfolioName, '
        'totalReturn: ${totalReturnPercentage.toStringAsFixed(2)}%, '
        'dailyReturn: ${dailyReturnPercentage.toStringAsFixed(2)}%, '
        'annualized: ${annualizedReturnPercentage.toStringAsFixed(2)}%, '
        'sharpe: ${sharpeRatio?.toStringAsFixed(2) ?? 'N/A'}, '
        'holdings: $numberOfHoldings, '
        'grade: $performanceGrade'
        '}';
  }

  /// 创建一个空的PortfolioSummary实例
  static PortfolioSummary empty() {
    return PortfolioSummary(
      portfolioId: '',
      portfolioName: '',
      analysisDate: DateTime.now(),
      benchmarkCode: null,
      benchmarkName: null,
      totalAssets: 0.0,
      totalMarketValue: 0.0,
      totalCost: 0.0,
      cashAndEquivalents: 0.0,
      numberOfHoldings: 0,
      holdings: const [],
      totalReturnAmount: 0.0,
      totalReturnRate: 0.0,
      dailyReturnAmount: 0.0,
      dailyReturnRate: 0.0,
      annualizedReturn: 0.0,
      totalDividends: 0.0,
      portfolioVolatility: 0.0,
      maxDrawdown: 0.0,
      sharpeRatio: 0.0,
      beta: 0.0,
      equityFundRatio: 0.0,
      bondFundRatio: 0.0,
      hybridFundRatio: 0.0,
      moneyMarketFundRatio: 0.0,
      otherFundRatio: 0.0,
      portfolioRating: PortfolioRating.neutral,
      riskLevel: RiskLevel.medium,
      categoryRanking: null,
      categoryTotal: null,
      return1Week: 0.0,
      return1Month: 0.0,
      return3Months: 0.0,
      return6Months: 0.0,
      return1Year: 0.0,
      returnYTD: 0.0,
      maxHoldingRatio: 0.0,
      top5HoldingsRatio: 0.0,
      top10HoldingsRatio: 0.0,
      industryConcentration: 0.0,
      tradingFrequency: 0.0,
      averageHoldingDays: 0,
      turnoverRate: 0.0,
      dataStartDate: DateTime.now(),
      dataQuality: DataQuality.poor,
      lastUpdated: DateTime.now(),
      notes: '',
    );
  }
}

/// 组合评级枚举
enum PortfolioRating {
  @JsonValue('excellent')
  excellent, // 优秀
  @JsonValue('good')
  good, // 良好
  @JsonValue('neutral')
  neutral, // 中性
  @JsonValue('poor')
  poor, // 较差
  @JsonValue('very_poor')
  veryPoor, // 很差
}

/// 集中度等级枚举
enum ConcentrationLevel {
  veryLow, // 极低分散
  low, // 低分散
  medium, // 中等分散
  high, // 高集中
  veryHigh, // 极高集中
}
