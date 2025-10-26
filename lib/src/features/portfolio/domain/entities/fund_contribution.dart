import 'package:equatable/equatable.dart';

/// 基金贡献度实体
///
/// 表示单个基金对组合收益和风险的贡献度分析数据
class FundContribution extends Equatable {
  /// 基金代码
  final String fundCode;

  /// 基金名称
  final String fundName;

  /// 基金类型
  final String fundType;

  /// 持仓金额
  final double holdingAmount;

  /// 持仓数量（份）
  final double holdingShares;

  /// 持仓占比
  final double portfolioPercentage;

  /// 收益金额
  final double profitAmount;

  /// 收益率
  final double profitRate;

  /// 累计收益
  final double cumulativeProfit;

  /// 贡献度百分比
  final double contributionPercentage;

  /// 风险贡献度
  final double riskContribution;

  /// 最大回撤
  final double maxDrawdown;

  /// 波动率
  final double volatility;

  /// 夏普比率
  final double sharpeRatio;

  /// Beta值
  final double betaValue;

  /// 风险等级
  final String riskLevel;

  /// 综合评分
  final double overallScore;

  /// 综合排名
  final String overallRanking;

  /// 分析时间周期
  final String analysisPeriod;

  /// 基准对比
  final double benchmarkComparison;

  /// 同类排名
  final int? peerRanking;

  /// 是否为主要贡献基金
  final bool isKeyContributor;

  /// 贡献度趋势（正增长/负增长/稳定）
  final String contributionTrend;

  /// 最后更新时间
  final DateTime lastUpdated;

  const FundContribution({
    required this.fundCode,
    required this.fundName,
    required this.fundType,
    required this.holdingAmount,
    required this.holdingShares,
    required this.portfolioPercentage,
    required this.profitAmount,
    required this.profitRate,
    required this.cumulativeProfit,
    required this.contributionPercentage,
    required this.riskContribution,
    required this.maxDrawdown,
    required this.volatility,
    required this.sharpeRatio,
    required this.betaValue,
    required this.riskLevel,
    required this.overallScore,
    required this.overallRanking,
    required this.analysisPeriod,
    required this.benchmarkComparison,
    this.peerRanking,
    this.isKeyContributor = false,
    this.contributionTrend = 'stable',
    required this.lastUpdated,
  });

  /// 创建副本
  FundContribution copyWith({
    String? fundCode,
    String? fundName,
    String? fundType,
    double? holdingAmount,
    double? holdingShares,
    double? portfolioPercentage,
    double? profitAmount,
    double? profitRate,
    double? cumulativeProfit,
    double? contributionPercentage,
    double? riskContribution,
    double? maxDrawdown,
    double? volatility,
    double? sharpeRatio,
    double? betaValue,
    String? riskLevel,
    double? overallScore,
    String? overallRanking,
    String? analysisPeriod,
    double? benchmarkComparison,
    int? peerRanking,
    bool? isKeyContributor,
    String? contributionTrend,
    DateTime? lastUpdated,
  }) {
    return FundContribution(
      fundCode: fundCode ?? this.fundCode,
      fundName: fundName ?? this.fundName,
      fundType: fundType ?? this.fundType,
      holdingAmount: holdingAmount ?? this.holdingAmount,
      holdingShares: holdingShares ?? this.holdingShares,
      portfolioPercentage: portfolioPercentage ?? this.portfolioPercentage,
      profitAmount: profitAmount ?? this.profitAmount,
      profitRate: profitRate ?? this.profitRate,
      cumulativeProfit: cumulativeProfit ?? this.cumulativeProfit,
      contributionPercentage:
          contributionPercentage ?? this.contributionPercentage,
      riskContribution: riskContribution ?? this.riskContribution,
      maxDrawdown: maxDrawdown ?? this.maxDrawdown,
      volatility: volatility ?? this.volatility,
      sharpeRatio: sharpeRatio ?? this.sharpeRatio,
      betaValue: betaValue ?? this.betaValue,
      riskLevel: riskLevel ?? this.riskLevel,
      overallScore: overallScore ?? this.overallScore,
      overallRanking: overallRanking ?? this.overallRanking,
      analysisPeriod: analysisPeriod ?? this.analysisPeriod,
      benchmarkComparison: benchmarkComparison ?? this.benchmarkComparison,
      peerRanking: peerRanking ?? this.peerRanking,
      isKeyContributor: isKeyContributor ?? this.isKeyContributor,
      contributionTrend: contributionTrend ?? this.contributionTrend,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// 从基金持有数据创建贡献度分析
  factory FundContribution.fromHolding({
    required String fundCode,
    required String fundName,
    required String fundType,
    required double holdingAmount,
    required double holdingShares,
    required double portfolioPercentage,
    required double currentNav,
    required double purchaseNav,
    required double currentProfitRate,
    required double maxDrawdown,
    required double volatility,
    required double sharpeRatio,
    required double betaValue,
    String analysisPeriod = '1年',
    double benchmarkComparison = 0.0,
    int? peerRanking,
  }) {
    final profitAmount = holdingAmount * currentProfitRate;
    final cumulativeProfit = holdingAmount * (currentNav / purchaseNav - 1);
    final profitRate = currentProfitRate;

    return FundContribution(
      fundCode: fundCode,
      fundName: fundName,
      fundType: fundType,
      holdingAmount: holdingAmount,
      holdingShares: holdingShares,
      portfolioPercentage: portfolioPercentage,
      profitAmount: profitAmount,
      profitRate: profitRate,
      cumulativeProfit: cumulativeProfit,
      contributionPercentage: portfolioPercentage * profitRate,
      riskContribution: portfolioPercentage * maxDrawdown.abs(),
      maxDrawdown: maxDrawdown,
      volatility: volatility,
      sharpeRatio: sharpeRatio,
      betaValue: betaValue,
      riskLevel: _calculateRiskLevel(maxDrawdown, volatility),
      overallScore:
          _calculateOverallScore(profitRate, sharpeRatio, maxDrawdown),
      overallRanking: _calculateOverallRanking(sharpeRatio, profitRate),
      analysisPeriod: analysisPeriod,
      benchmarkComparison: benchmarkComparison,
      peerRanking: peerRanking,
      isKeyContributor: portfolioPercentage > 10.0,
      contributionTrend: _calculateContributionTrend(profitRate),
      lastUpdated: DateTime.now(),
    );
  }

  /// 计算风险等级
  static String _calculateRiskLevel(double maxDrawdown, double volatility) {
    final riskScore = (maxDrawdown.abs() * 0.6 + volatility * 0.4);
    if (riskScore <= 5) return '低风险';
    if (riskScore <= 15) return '中风险';
    if (riskScore <= 25) return '高风险';
    return '极高风险';
  }

  /// 计算综合评分
  static double _calculateOverallScore(
      double profitRate, double sharpeRatio, double maxDrawdown) {
    // 收益得分 (40%)
    final profitScore = (profitRate * 100).clamp(0, 100).toDouble();

    // 夏普比率得分 (30%)
    final sharpeScore = (sharpeRatio * 25).clamp(0, 100).toDouble();

    // 风险控制得分 (30%)
    final riskScore = ((1 - maxDrawdown.abs()) * 100).clamp(0, 100).toDouble();

    return (profitScore * 0.4 + sharpeScore * 0.3 + riskScore * 0.3);
  }

  /// 计算综合排名
  static String _calculateOverallRanking(
      double sharpeRatio, double profitRate) {
    if (sharpeRatio >= 2.0 && profitRate > 0) return '优秀';
    if (sharpeRatio >= 1.5 && profitRate > 0) return '良好';
    if (sharpeRatio >= 1.0 || profitRate > 0) return '中等';
    if (sharpeRatio >= 0.5) return '一般';
    return '较差';
  }

  /// 计算贡献度趋势
  static String _calculateContributionTrend(double profitRate) {
    if (profitRate > 0.15) return '快速增长';
    if (profitRate > 0.05) return '稳定增长';
    if (profitRate > -0.05) return '基本稳定';
    return '下滑趋势';
  }

  /// 是否为正向贡献
  bool get isPositiveContribution => profitAmount > 0;

  /// 是否为高风险基金
  bool get isHighRisk => riskLevel == '高风险' || riskLevel == '极高风险';

  /// 贡献度等级
  String get contributionLevel {
    if (contributionPercentage >= 5.0) return '高贡献';
    if (contributionPercentage >= 1.0) return '中贡献';
    if (contributionPercentage >= 0.1) return '低贡献';
    return '微小贡献';
  }

  /// 风险调整收益评分
  double get riskAdjustedReturn {
    if (volatility == 0) return 0.0;
    return profitRate / volatility;
  }

  /// 信息比率
  double get informationRatio {
    if (volatility == 0) return 0.0;
    return (profitRate - benchmarkComparison) / volatility;
  }

  @override
  List<Object?> get props => [
        fundCode,
        fundName,
        fundType,
        holdingAmount,
        holdingShares,
        portfolioPercentage,
        profitAmount,
        profitRate,
        cumulativeProfit,
        contributionPercentage,
        riskContribution,
        maxDrawdown,
        volatility,
        sharpeRatio,
        betaValue,
        riskLevel,
        overallScore,
        overallRanking,
        analysisPeriod,
        benchmarkComparison,
        peerRanking,
        isKeyContributor,
        contributionTrend,
        lastUpdated,
      ];

  @override
  String toString() {
    return 'FundContribution(fundCode: $fundCode, fundName: $fundName, contributionPercentage: ${contributionPercentage.toStringAsFixed(2)}%)';
  }
}

/// 基金贡献度分析工具类
class FundContributionAnalyzer {
  /// 计算基金对组合的贡献度
  static List<FundContribution> calculateContributions(
    List<Map<String, dynamic>> holdings,
    double totalPortfolioValue,
  ) {
    final contributions = <FundContribution>[];

    for (final holding in holdings) {
      final contribution = FundContribution.fromHolding(
        fundCode: holding['fundCode'] ?? '',
        fundName: holding['fundName'] ?? '',
        fundType: holding['fundType'] ?? '股票型',
        holdingAmount: holding['holdingAmount']?.toDouble() ?? 0.0,
        holdingShares: holding['holdingShares']?.toDouble() ?? 0.0,
        portfolioPercentage: (holding['holdingAmount']?.toDouble() ?? 0.0) /
            totalPortfolioValue *
            100,
        currentNav: holding['currentNav']?.toDouble() ?? 1.0,
        purchaseNav: holding['purchaseNav']?.toDouble() ?? 1.0,
        currentProfitRate: holding['currentProfitRate']?.toDouble() ?? 0.0,
        maxDrawdown: holding['maxDrawdown']?.toDouble() ?? 0.0,
        volatility: holding['volatility']?.toDouble() ?? 0.0,
        sharpeRatio: holding['sharpeRatio']?.toDouble() ?? 0.0,
        betaValue: holding['betaValue']?.toDouble() ?? 1.0,
        analysisPeriod: holding['analysisPeriod'] ?? '1年',
        benchmarkComparison: holding['benchmarkComparison']?.toDouble() ?? 0.0,
        peerRanking: holding['peerRanking']?.toInt(),
      );

      contributions.add(contribution);
    }

    // 按贡献度排序
    contributions.sort(
        (a, b) => b.contributionPercentage.compareTo(a.contributionPercentage));

    return contributions;
  }

  /// 分析贡献度分布
  static Map<String, dynamic> analyzeContributionDistribution(
      List<FundContribution> contributions) {
    if (contributions.isEmpty) {
      return {
        'totalContribution': 0.0,
        'positiveContributionCount': 0,
        'negativeContributionCount': 0,
        'topContributor': null,
        'averageContribution': 0.0,
        'concentrationRatio': 0.0,
      };
    }

    final totalContribution = contributions.fold<double>(
      0.0,
      (sum, contribution) => sum + contribution.contributionPercentage,
    );

    final positiveContributions =
        contributions.where((c) => c.isPositiveContribution).toList();
    final negativeContributions =
        contributions.where((c) => !c.isPositiveContribution).toList();

    final topContributor =
        contributions.isNotEmpty ? contributions.first : null;
    final averageContribution = totalContribution / contributions.length;

    // 计算集中度比率（前三大基金贡献度占比）
    final top3Contributions = contributions.take(3).toList();
    final concentrationRatio = top3Contributions.fold<double>(
          0.0,
          (sum, contribution) =>
              sum + contribution.contributionPercentage.abs(),
        ) /
        totalContribution.abs() *
        100;

    return {
      'totalContribution': totalContribution,
      'positiveContributionCount': positiveContributions.length,
      'negativeContributionCount': negativeContributions.length,
      'topContributor': topContributor,
      'averageContribution': averageContribution,
      'concentrationRatio': concentrationRatio,
    };
  }
}
