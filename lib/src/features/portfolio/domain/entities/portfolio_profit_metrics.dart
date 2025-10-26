import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'portfolio_profit_metrics.g.dart';

/// 组合收益指标实体
///
/// 包含组合在各种时间维度下的详细收益分析数据
@JsonSerializable()
class PortfolioProfitMetrics extends Equatable {
  /// 基金代码
  final String fundCode;

  /// 分析日期
  final DateTime analysisDate;

  /// 基准指数代码
  final String? benchmarkCode;

  /// 基准指数名称
  final String? benchmarkName;

  // ===== 基础收益指标 =====

  /// 累计收益金额
  final double totalReturnAmount;

  /// 累计收益率
  final double totalReturnRate;

  /// 年化收益率
  final double annualizedReturn;

  /// 日收益率
  final double dailyReturn;

  /// 周收益率
  final double weeklyReturn;

  /// 月收益率
  final double monthlyReturn;

  /// 季度收益率
  final double quarterlyReturn;

  // ===== 多时间段收益率 =====

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

  /// 近3年收益率
  final double return3Years;

  /// 今年来收益率
  final double returnYTD;

  /// 成立来收益率
  final double returnSinceInception;

  // ===== 基准比较指标 =====

  /// 基准收益率
  final double? benchmarkReturn;

  /// 超额收益金额
  final double? excessReturnAmount;

  /// 超额收益率
  final double? excessReturnRate;

  /// 相对基准的表现
  @JsonKey(includeIfNull: false, defaultValue: null)
  final PerformanceRelativeBenchmark? relativePerformance;

  // ===== 风险收益指标 =====

  /// 夏普比率（风险调整后收益）
  final double? sharpeRatio;

  /// 索提诺比率（下行风险调整收益）
  final double? sortinoRatio;

  /// 特雷纳比率
  final double? treynorRatio;

  /// 詹森阿尔法
  final double? jensenAlpha;

  /// 信息比率
  final double? informationRatio;

  // ===== 风险指标 =====

  /// 波动率（年化标准差）
  final double? volatility;

  /// 最大回撤
  final double? maxDrawdown;

  /// 最大回撤持续期（天数）
  final int? maxDrawdownDuration;

  /// 下行波动率
  final double? downsideVolatility;

  /// VaR（风险价值，95%置信度）
  final double? var95;

  /// Beta值（系统性风险）
  final double? beta;

  // ===== 统计指标 =====

  /// 胜率（盈利天数占比）
  final double? winRate;

  /// 盈亏比
  final double? profitLossRatio;

  /// 最大连续盈利天数
  final int? maxConsecutiveWinDays;

  /// 最大连续亏损天数
  final int? maxConsecutiveLossDays;

  /// 正收益天数
  final int? positiveReturnDays;

  /// 负收益天数
  final int? negativeReturnDays;

  /// 总交易日数
  final int? totalTradingDays;

  // ===== 排名指标 =====

  /// 同类排名
  final int? fundRanking;

  /// 同类总数
  final int? totalFundsInCategory;

  /// 排名百分比
  final double? rankingPercentile;

  /// 评级（如：五星、四星）
  final String? rating;

  // ===== 分红相关指标 =====

  /// 累计分红金额
  final double totalDividends;

  /// 分红再投资收益
  final double dividendReinvestmentReturn;

  /// 股息率
  final double dividendYield;

  // ===== 分析元数据 =====

  /// 数据开始日期
  final DateTime dataStartDate;

  /// 数据结束日期
  final DateTime dataEndDate;

  /// 分析时间段（天数）
  final int analysisPeriodDays;

  /// 数据质量评级
  final DataQuality dataQuality;

  /// 最后更新时间
  final DateTime lastUpdated;

  const PortfolioProfitMetrics({
    required this.fundCode,
    required this.analysisDate,
    this.benchmarkCode,
    this.benchmarkName,
    required this.totalReturnAmount,
    required this.totalReturnRate,
    required this.annualizedReturn,
    required this.dailyReturn,
    required this.weeklyReturn,
    required this.monthlyReturn,
    required this.quarterlyReturn,
    required this.return1Week,
    required this.return1Month,
    required this.return3Months,
    required this.return6Months,
    required this.return1Year,
    required this.return3Years,
    required this.returnYTD,
    required this.returnSinceInception,
    this.benchmarkReturn,
    this.excessReturnAmount,
    this.excessReturnRate,
    this.relativePerformance,
    this.sharpeRatio,
    this.sortinoRatio,
    this.treynorRatio,
    this.jensenAlpha,
    this.informationRatio,
    this.volatility,
    this.maxDrawdown,
    this.maxDrawdownDuration,
    this.downsideVolatility,
    this.var95,
    this.beta,
    this.winRate,
    this.profitLossRatio,
    this.maxConsecutiveWinDays,
    this.maxConsecutiveLossDays,
    this.positiveReturnDays,
    this.negativeReturnDays,
    this.totalTradingDays,
    this.fundRanking,
    this.totalFundsInCategory,
    this.rankingPercentile,
    this.rating,
    this.totalDividends = 0.0,
    this.dividendReinvestmentReturn = 0.0,
    this.dividendYield = 0.0,
    required this.dataStartDate,
    required this.dataEndDate,
    required this.analysisPeriodDays,
    this.dataQuality = DataQuality.good,
    required this.lastUpdated,
  });

  /// 从JSON创建PortfolioProfitMetrics实例
  factory PortfolioProfitMetrics.fromJson(Map<String, dynamic> json) =>
      _$PortfolioProfitMetricsFromJson(json);

  /// 转换为JSON
  Map<String, dynamic> toJson() => _$PortfolioProfitMetricsToJson(this);

  /// 创建副本并更新指定字段
  PortfolioProfitMetrics copyWith({
    String? fundCode,
    DateTime? analysisDate,
    String? benchmarkCode,
    String? benchmarkName,
    double? totalReturnAmount,
    double? totalReturnRate,
    double? annualizedReturn,
    double? dailyReturn,
    double? weeklyReturn,
    double? monthlyReturn,
    double? quarterlyReturn,
    double? return1Week,
    double? return1Month,
    double? return3Months,
    double? return6Months,
    double? return1Year,
    double? return3Years,
    double? returnYTD,
    double? returnSinceInception,
    double? benchmarkReturn,
    double? excessReturnAmount,
    double? excessReturnRate,
    PerformanceRelativeBenchmark? relativePerformance,
    double? sharpeRatio,
    double? sortinoRatio,
    double? treynorRatio,
    double? jensenAlpha,
    double? informationRatio,
    double? volatility,
    double? maxDrawdown,
    int? maxDrawdownDuration,
    double? downsideVolatility,
    double? var95,
    double? beta,
    double? winRate,
    double? profitLossRatio,
    int? maxConsecutiveWinDays,
    int? maxConsecutiveLossDays,
    int? positiveReturnDays,
    int? negativeReturnDays,
    int? totalTradingDays,
    int? fundRanking,
    int? totalFundsInCategory,
    double? rankingPercentile,
    String? rating,
    double? totalDividends,
    double? dividendReinvestmentReturn,
    double? dividendYield,
    DateTime? dataStartDate,
    DateTime? dataEndDate,
    int? analysisPeriodDays,
    DataQuality? dataQuality,
    DateTime? lastUpdated,
  }) {
    return PortfolioProfitMetrics(
      fundCode: fundCode ?? this.fundCode,
      analysisDate: analysisDate ?? this.analysisDate,
      benchmarkCode: benchmarkCode ?? this.benchmarkCode,
      benchmarkName: benchmarkName ?? this.benchmarkName,
      totalReturnAmount: totalReturnAmount ?? this.totalReturnAmount,
      totalReturnRate: totalReturnRate ?? this.totalReturnRate,
      annualizedReturn: annualizedReturn ?? this.annualizedReturn,
      dailyReturn: dailyReturn ?? this.dailyReturn,
      weeklyReturn: weeklyReturn ?? this.weeklyReturn,
      monthlyReturn: monthlyReturn ?? this.monthlyReturn,
      quarterlyReturn: quarterlyReturn ?? this.quarterlyReturn,
      return1Week: return1Week ?? this.return1Week,
      return1Month: return1Month ?? this.return1Month,
      return3Months: return3Months ?? this.return3Months,
      return6Months: return6Months ?? this.return6Months,
      return1Year: return1Year ?? this.return1Year,
      return3Years: return3Years ?? this.return3Years,
      returnYTD: returnYTD ?? this.returnYTD,
      returnSinceInception: returnSinceInception ?? this.returnSinceInception,
      benchmarkReturn: benchmarkReturn ?? this.benchmarkReturn,
      excessReturnAmount: excessReturnAmount ?? this.excessReturnAmount,
      excessReturnRate: excessReturnRate ?? this.excessReturnRate,
      relativePerformance: relativePerformance ?? this.relativePerformance,
      sharpeRatio: sharpeRatio ?? this.sharpeRatio,
      sortinoRatio: sortinoRatio ?? this.sortinoRatio,
      treynorRatio: treynorRatio ?? this.treynorRatio,
      jensenAlpha: jensenAlpha ?? this.jensenAlpha,
      informationRatio: informationRatio ?? this.informationRatio,
      volatility: volatility ?? this.volatility,
      maxDrawdown: maxDrawdown ?? this.maxDrawdown,
      maxDrawdownDuration: maxDrawdownDuration ?? this.maxDrawdownDuration,
      downsideVolatility: downsideVolatility ?? this.downsideVolatility,
      var95: var95 ?? this.var95,
      beta: beta ?? this.beta,
      winRate: winRate ?? this.winRate,
      profitLossRatio: profitLossRatio ?? this.profitLossRatio,
      maxConsecutiveWinDays:
          maxConsecutiveWinDays ?? this.maxConsecutiveWinDays,
      maxConsecutiveLossDays:
          maxConsecutiveLossDays ?? this.maxConsecutiveLossDays,
      positiveReturnDays: positiveReturnDays ?? this.positiveReturnDays,
      negativeReturnDays: negativeReturnDays ?? this.negativeReturnDays,
      totalTradingDays: totalTradingDays ?? this.totalTradingDays,
      fundRanking: fundRanking ?? this.fundRanking,
      totalFundsInCategory: totalFundsInCategory ?? this.totalFundsInCategory,
      rankingPercentile: rankingPercentile ?? this.rankingPercentile,
      rating: rating ?? this.rating,
      totalDividends: totalDividends ?? this.totalDividends,
      dividendReinvestmentReturn:
          dividendReinvestmentReturn ?? this.dividendReinvestmentReturn,
      dividendYield: dividendYield ?? this.dividendYield,
      dataStartDate: dataStartDate ?? this.dataStartDate,
      dataEndDate: dataEndDate ?? this.dataEndDate,
      analysisPeriodDays: analysisPeriodDays ?? this.analysisPeriodDays,
      dataQuality: dataQuality ?? this.dataQuality,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // ===== 便捷访问属性 =====

  /// 获取累计收益率百分比
  double get totalReturnPercentage => totalReturnRate * 100;

  /// 获取年化收益率百分比
  double get annualizedReturnPercentage => annualizedReturn * 100;

  /// 获取最大回撤百分比
  double get maxDrawdownPercentage => (maxDrawdown ?? 0.0) * 100;

  /// 获取波动率百分比
  double get volatilityPercentage => (volatility ?? 0.0) * 100;

  /// 获取胜率百分比
  double get winRatePercentage => (winRate ?? 0.0) * 100;

  /// 获取超额收益率百分比
  double get excessReturnPercentage => (excessReturnRate ?? 0.0) * 100;

  /// 是否为正收益
  bool get isPositiveReturn => totalReturnAmount > 0;

  /// 是否跑赢基准
  bool get outperformsBenchmark => (excessReturnRate ?? 0.0) > 0;

  /// 是否为高风险（波动率>20%）
  bool get isHighRisk => (volatility ?? 0.0) > 0.20;

  /// 是否为优秀夏普比率（>1.5）
  bool get hasExcellentSharpeRatio => (sharpeRatio ?? 0.0) > 1.5;

  /// 获取风险等级
  RiskLevel get riskLevel {
    final vol = volatility ?? 0.0;
    if (vol < 0.10) return RiskLevel.low;
    if (vol < 0.15) return RiskLevel.medium;
    if (vol < 0.20) return RiskLevel.high;
    return RiskLevel.veryHigh;
  }

  /// 获取表现评级
  PerformanceRating get performanceRating {
    final returnRate = totalReturnRate;
    final sharpe = sharpeRatio ?? 0.0;
    final maxDD = maxDrawdown ?? 0.0;

    if (returnRate > 0.15 && sharpe > 1.5 && maxDD < 0.10) {
      return PerformanceRating.excellent;
    } else if (returnRate > 0.10 && sharpe > 1.0 && maxDD < 0.15) {
      return PerformanceRating.good;
    } else if (returnRate > 0.05 && sharpe > 0.5 && maxDD < 0.20) {
      return PerformanceRating.average;
    } else if (returnRate > 0 && sharpe > 0) {
      return PerformanceRating.poor;
    } else {
      return PerformanceRating.veryPoor;
    }
  }

  /// 验证数据完整性
  bool isComplete() {
    return totalReturnAmount.isFinite &&
        totalReturnRate.isFinite &&
        annualizedReturn.isFinite &&
        return1Year.isFinite &&
        dataQuality != DataQuality.poor;
  }

  @override
  List<Object?> get props => [
        fundCode,
        analysisDate,
        benchmarkCode,
        benchmarkName,
        totalReturnAmount,
        totalReturnRate,
        annualizedReturn,
        dailyReturn,
        weeklyReturn,
        monthlyReturn,
        quarterlyReturn,
        return1Week,
        return1Month,
        return3Months,
        return6Months,
        return1Year,
        return3Years,
        returnYTD,
        returnSinceInception,
        benchmarkReturn,
        excessReturnAmount,
        excessReturnRate,
        relativePerformance,
        sharpeRatio,
        sortinoRatio,
        treynorRatio,
        jensenAlpha,
        informationRatio,
        volatility,
        maxDrawdown,
        maxDrawdownDuration,
        downsideVolatility,
        var95,
        beta,
        winRate,
        profitLossRatio,
        maxConsecutiveWinDays,
        maxConsecutiveLossDays,
        positiveReturnDays,
        negativeReturnDays,
        totalTradingDays,
        fundRanking,
        totalFundsInCategory,
        rankingPercentile,
        rating,
        totalDividends,
        dividendReinvestmentReturn,
        dividendYield,
        dataStartDate,
        dataEndDate,
        analysisPeriodDays,
        dataQuality,
        lastUpdated,
      ];

  @override
  String toString() {
    return 'PortfolioProfitMetrics{'
        'fundCode: $fundCode, '
        'totalReturn: ${totalReturnPercentage.toStringAsFixed(2)}%, '
        'annualized: ${annualizedReturnPercentage.toStringAsFixed(2)}%, '
        'sharpe: ${sharpeRatio?.toStringAsFixed(2) ?? 'N/A'}, '
        'maxDD: ${maxDrawdownPercentage.toStringAsFixed(2)}%, '
        'rating: $performanceRating'
        '}';
  }

  /// 创建一个空的PortfolioProfitMetrics实例
  static PortfolioProfitMetrics empty({String fundCode = ''}) {
    final now = DateTime.now();
    return PortfolioProfitMetrics(
      fundCode: fundCode,
      analysisDate: now,
      totalReturnAmount: 0.0,
      totalReturnRate: 0.0,
      annualizedReturn: 0.0,
      dailyReturn: 0.0,
      weeklyReturn: 0.0,
      monthlyReturn: 0.0,
      quarterlyReturn: 0.0,
      return1Week: 0.0,
      return1Month: 0.0,
      return3Months: 0.0,
      return6Months: 0.0,
      return1Year: 0.0,
      return3Years: 0.0,
      returnYTD: 0.0,
      returnSinceInception: 0.0,
      dataStartDate: now,
      dataEndDate: now,
      analysisPeriodDays: 0,
      lastUpdated: now,
    );
  }
}

/// 相对基准表现
@JsonSerializable()
@immutable
class PerformanceRelativeBenchmark extends Equatable {
  /// 跑赢基准的天数
  final int outperformDays;

  /// 跑输基准的天数
  final int underperformDays;

  /// 持平天数
  final int neutralDays;

  /// 最大超额收益
  final double maxExcessReturn;

  /// 最大超额亏损
  final double maxExcessLoss;

  /// 平均每日超额收益
  final double avgDailyExcessReturn;

  const PerformanceRelativeBenchmark({
    required this.outperformDays,
    required this.underperformDays,
    required this.neutralDays,
    required this.maxExcessReturn,
    required this.maxExcessLoss,
    required this.avgDailyExcessReturn,
  });

  /// 从JSON创建PerformanceRelativeBenchmark实例
  factory PerformanceRelativeBenchmark.fromJson(Map<String, dynamic> json) =>
      _$PerformanceRelativeBenchmarkFromJson(json);

  /// 转换为JSON
  Map<String, dynamic> toJson() => _$PerformanceRelativeBenchmarkToJson(this);

  /// 跑赢基准的比例
  double get outperformRatio {
    final total = outperformDays + underperformDays + neutralDays;
    return total == 0 ? 0.0 : outperformDays / total;
  }

  /// 跑赢基准的百分比
  double get outperformPercentage => outperformRatio * 100;

  /// 创建一个空的PerformanceRelativeBenchmark实例
  static PerformanceRelativeBenchmark empty() {
    return PerformanceRelativeBenchmark(
      outperformDays: 0,
      underperformDays: 0,
      neutralDays: 0,
      maxExcessReturn: 0.0,
      maxExcessLoss: 0.0,
      avgDailyExcessReturn: 0.0,
    );
  }

  @override
  List<Object?> get props => [
        outperformDays,
        underperformDays,
        neutralDays,
        maxExcessReturn,
        maxExcessLoss,
        avgDailyExcessReturn,
      ];
}

/// 数据质量枚举
enum DataQuality {
  @JsonValue('excellent')
  excellent, // 优秀：数据完整，无缺失
  @JsonValue('good')
  good, // 良好：少量缺失，不影响分析
  @JsonValue('fair')
  fair, // 一般：部分缺失，需要谨慎解读
  @JsonValue('poor')
  poor, // 差：大量缺失，结果仅供参考
}

/// 风险等级枚举
enum RiskLevel {
  low, // 低风险
  medium, // 中等风险
  high, // 高风险
  veryHigh, // 极高风险
}

/// 表现评级枚举
enum PerformanceRating {
  excellent, // 优秀
  good, // 良好
  average, // 一般
  poor, // 较差
  veryPoor, // 很差
}
