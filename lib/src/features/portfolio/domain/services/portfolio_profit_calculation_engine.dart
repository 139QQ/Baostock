import 'dart:math';
import 'package:dartz/dartz.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import '../entities/portfolio_holding.dart';
import '../entities/portfolio_profit_metrics.dart';
import '../entities/portfolio_summary.dart';
import '../entities/portfolio_profit_calculation_criteria.dart';
import '../entities/fund_corporate_action.dart';
import '../entities/fund_split_detail.dart';
import '../repositories/portfolio_profit_repository.dart';
import 'corporate_action_adjustment_service.dart';

/// 组合收益计算引擎
///
/// 提供高精度的基金收益计算服务，支持分红再投资、拆分调整等公司行为处理
class PortfolioProfitCalculationEngine {
  final CorporateActionAdjustmentService _corporateActionService;
  final CalculationLogger _logger;

  PortfolioProfitCalculationEngine({
    CorporateActionAdjustmentService? corporateActionService,
    CalculationLogger? logger,
  })  : _corporateActionService =
            corporateActionService ?? CorporateActionAdjustmentService(),
        _logger = logger ?? CalculationLogger();

  /// 计算单个基金的收益指标
  Future<PortfolioProfitMetrics> calculateFundProfitMetrics({
    required PortfolioHolding holding,
    required PortfolioProfitCalculationCriteria criteria,
    Map<DateTime, double>? navHistory,
    Map<DateTime, double>? benchmarkHistory,
    List<FundCorporateAction>? corporateActions,
    List<FundSplitDetail>? splitDetails,
  }) async {
    _logger.logStart('calculateFundProfitMetrics', {
      'fundCode': holding.fundCode,
      'period': '${criteria.calculationDays}days',
      'includeDividend': criteria.includeDividendReinvestment,
    });

    try {
      // 1. 基础收益计算
      final basicMetrics = await _calculateBasicMetrics(
        holding: holding,
        criteria: criteria,
        navHistory: navHistory,
        benchmarkHistory: benchmarkHistory,
      );

      // 2. 风险指标计算
      final riskMetrics = await _calculateRiskMetrics(
        holding: holding,
        criteria: criteria,
        navHistory: navHistory,
        basicMetrics: basicMetrics,
      );

      // 3. 公司行为处理
      CorporateActionResult? corporateActionResult;
      if (criteria.considerCorporateActions &&
          corporateActions != null &&
          navHistory != null) {
        corporateActionResult = _corporateActionService.processCorporateActions(
          navHistory: navHistory,
          corporateActions: corporateActions,
        );
      }

      // 4. 合并所有指标
      final metrics = _mergeAllMetrics(
        holding: holding,
        basicMetrics: basicMetrics,
        riskMetrics: riskMetrics,
        corporateActionResult: corporateActionResult,
        criteria: criteria,
      );

      _logger.logSuccess('calculateFundProfitMetrics', metrics.toString());
      return metrics;
    } catch (e, stack) {
      _logger.logError('calculateFundProfitMetrics', e, stack);
      rethrow;
    }
  }

  /// 计算组合汇总收益
  Future<PortfolioSummary> calculatePortfolioSummary({
    required List<PortfolioHolding> holdings,
    required PortfolioProfitCalculationCriteria criteria,
    Map<String, Map<DateTime, double>>? allNavHistory,
    Map<String, PortfolioProfitMetrics>? allMetrics,
    Map<String, List<FundCorporateAction>>? allCorporateActions,
    Map<String, List<FundSplitDetail>>? allSplitDetails,
  }) async {
    _logger.logStart('calculatePortfolioSummary', {
      'holdingsCount': holdings.length,
      'period': '${criteria.calculationDays}days',
    });

    try {
      // 1. 计算单个基金收益
      final individualMetrics = <String, PortfolioProfitMetrics>{};
      for (final holding in holdings) {
        final metrics = await calculateFundProfitMetrics(
          holding: holding,
          criteria: criteria,
          navHistory: allNavHistory?[holding.fundCode],
          corporateActions: allCorporateActions?[holding.fundCode],
          splitDetails: allSplitDetails?[holding.fundCode],
        );
        individualMetrics[holding.fundCode] = metrics;
      }

      // 2. 计算组合汇总指标
      final summary = _calculatePortfolioAggregatedMetrics(
        holdings: holdings,
        individualMetrics: individualMetrics,
        criteria: criteria,
      );

      _logger.logSuccess('calculatePortfolioSummary', summary.toString());
      return summary;
    } catch (e, stack) {
      _logger.logError('calculatePortfolioSummary', e, stack);
      rethrow;
    }
  }

  /// 计算多维度收益对比
  Future<Map<String, PortfolioProfitMetrics>>
      calculateMultiDimensionalComparison({
    required List<PortfolioHolding> holdings,
    required List<CalculationFrequency> frequencies,
    PortfolioProfitCalculationCriteria? baseCriteria,
  }) async {
    _logger.logStart('calculateMultiDimensionalComparison', {
      'holdingsCount': holdings.length,
      'frequencies': frequencies.map((f) => f.toString()).join(','),
    });

    try {
      final results = <String, PortfolioProfitMetrics>{};

      for (final frequency in frequencies) {
        final criteria = (baseCriteria ??
                PortfolioProfitCalculationCriteria(
                  calculationId:
                      'multi_dim_${DateTime.now().millisecondsSinceEpoch}',
                  fundCodes: holdings.map((h) => h.fundCode).toList(),
                  startDate:
                      DateTime.now().subtract(_getFrequencyDuration(frequency)),
                  endDate: DateTime.now(),
                  createdAt: DateTime.now(),
                ))
            .copyWith(frequency: frequency);

        for (final holding in holdings) {
          final key = '${holding.fundCode}_${frequency.toString()}';
          results[key] = await calculateFundProfitMetrics(
            holding: holding,
            criteria: criteria,
          );
        }
      }

      _logger.logSuccess('calculateMultiDimensionalComparison',
          'Calculated ${results.length} metrics combinations');
      return results;
    } catch (e, stack) {
      _logger.logError('calculateMultiDimensionalComparison', e, stack);
      rethrow;
    }
  }

  /// 计算基础收益指标
  Future<BasicProfitMetrics> _calculateBasicMetrics({
    required PortfolioHolding holding,
    required PortfolioProfitCalculationCriteria criteria,
    Map<DateTime, double>? navHistory,
    Map<DateTime, double>? benchmarkHistory,
  }) async {
    // 使用高精度计算
    final costDecimal = Decimal.parse(holding.costNav.toString());
    final currentNavDecimal = Decimal.parse(holding.currentNav.toString());
    final accumulatedNavDecimal =
        Decimal.parse(holding.accumulatedNav.toString());

    // 基础收益率计算
    final currentReturnRate = (currentNavDecimal - costDecimal) / costDecimal;
    final accumulatedReturnRate =
        (accumulatedNavDecimal - costDecimal) / costDecimal;

    // 收益金额计算
    final currentReturnAmount =
        holding.holdingAmount * currentReturnRate.toDouble();
    final accumulatedReturnAmount =
        holding.holdingAmount * accumulatedReturnRate.toDouble();

    // 时间维度收益率计算
    final timeSeriesReturns = _calculateTimeSeriesReturns(
      holding: holding,
      navHistory: navHistory,
      criteria: criteria,
    );

    return BasicProfitMetrics(
      currentReturnRate: currentReturnRate.toDouble(),
      currentReturnAmount: currentReturnAmount,
      accumulatedReturnRate: accumulatedReturnRate.toDouble(),
      accumulatedReturnAmount: accumulatedReturnAmount,
      timeSeriesReturns: timeSeriesReturns,
    );
  }

  /// 计算风险收益指标
  Future<RiskMetrics> _calculateRiskMetrics({
    required PortfolioHolding holding,
    required PortfolioProfitCalculationCriteria criteria,
    Map<DateTime, double>? navHistory,
    required BasicProfitMetrics basicMetrics,
  }) async {
    if (navHistory == null || navHistory.isEmpty) {
      return RiskMetrics.empty();
    }

    final navReturns = _calculateDailyReturns(navHistory);

    if (navReturns.isEmpty) {
      return RiskMetrics.empty();
    }

    // 波动率计算
    final volatility =
        _calculateVolatility(navReturns, criteria.volatilityMethod);

    // 最大回撤计算
    final maxDrawdown = _calculateMaxDrawdown(navHistory);

    // 夏普比率计算（假设无风险利率为3%）
    const riskFreeRate = 0.03;
    final sharpeRatio = volatility > 0
        ? (basicMetrics.accumulatedReturnRate - riskFreeRate) / volatility
        : 0.0;

    // 索提诺比率计算（只考虑下行风险）
    final downsideReturns = navReturns.where((r) => r < 0).toList();
    final downsideVolatility = downsideReturns.isNotEmpty
        ? _calculateStandardDeviation(downsideReturns)
        : 0.0;
    final sortinoRatio = downsideVolatility > 0
        ? (basicMetrics.accumulatedReturnRate - riskFreeRate) /
            downsideVolatility
        : 0.0;

    // 统计指标计算
    final stats = _calculateStatistics(navReturns);

    return RiskMetrics(
      volatility: volatility,
      maxDrawdown: maxDrawdown,
      sharpeRatio: sharpeRatio,
      sortinoRatio: sortinoRatio,
      downsideVolatility: downsideVolatility,
      winRate: stats.winRate,
      profitLossRatio: stats.profitLossRatio,
      maxConsecutiveWins: stats.maxConsecutiveWins,
      maxConsecutiveLosses: stats.maxConsecutiveLosses,
      positiveDays: stats.positiveDays,
      negativeDays: stats.negativeDays,
      totalDays: stats.totalDays,
    );
  }

  /// 计算时间序列收益率
  Map<CalculationFrequency, double> _calculateTimeSeriesReturns({
    required PortfolioHolding holding,
    required Map<DateTime, double>? navHistory,
    required PortfolioProfitCalculationCriteria criteria,
  }) {
    if (navHistory == null || navHistory.isEmpty) {
      return {};
    }

    final sortedDates = navHistory.keys.toList()..sort();
    final returns = <CalculationFrequency, double>{};

    for (final frequency in [
      CalculationFrequency.daily,
      CalculationFrequency.weekly,
      CalculationFrequency.monthly,
      CalculationFrequency.quarterly,
      CalculationFrequency.annually,
    ]) {
      final periodReturns = _calculateReturnsForPeriod(
        holding: holding,
        navHistory: navHistory,
        sortedDates: sortedDates,
        frequency: frequency,
        criteria: criteria,
      );

      if (periodReturns.isNotEmpty) {
        // 计算时间加权平均收益率
        returns[frequency] = _calculateTimeWeightedReturn(periodReturns);
      }
    }

    return returns;
  }

  /// 计算特定期间的收益率
  List<PeriodReturn> _calculateReturnsForPeriod({
    required PortfolioHolding holding,
    required Map<DateTime, double> navHistory,
    required List<DateTime> sortedDates,
    required CalculationFrequency frequency,
    required PortfolioProfitCalculationCriteria criteria,
  }) {
    final periodReturns = <PeriodReturn>[];
    final interval = _getFrequencyInterval(frequency);

    for (int i = 0; i < sortedDates.length - interval; i += interval) {
      final startDate = sortedDates[i];
      final endDate = sortedDates[min(i + interval, sortedDates.length - 1)];

      final startNav = navHistory[startDate]!;
      final endNav = navHistory[endDate]!;

      final periodReturn = (endNav - startNav) / startNav;
      final days = endDate.difference(startDate).inDays;

      periodReturns.add(PeriodReturn(
        startDate: startDate,
        endDate: endDate,
        returnRate: periodReturn,
        days: days,
      ));
    }

    return periodReturns;
  }

  /// 计算时间加权收益率
  double _calculateTimeWeightedReturn(List<PeriodReturn> periodReturns) {
    if (periodReturns.isEmpty) return 0.0;

    // 使用修正的Dietz方法计算时间加权收益率
    double weightedReturn = 0.0;
    double totalWeight = 0.0;

    for (final period in periodReturns) {
      final weight = period.days / 365.0; // 年化权重
      weightedReturn += period.returnRate * weight;
      totalWeight += weight;
    }

    return totalWeight > 0 ? weightedReturn / totalWeight : 0.0;
  }

  /// 计算日收益率序列
  List<double> _calculateDailyReturns(Map<DateTime, double> navHistory) {
    final sortedDates = navHistory.keys.toList()..sort();
    final returns = <double>[];

    for (int i = 1; i < sortedDates.length; i++) {
      final prevNav = navHistory[sortedDates[i - 1]]!;
      final currNav = navHistory[sortedDates[i]]!;

      if (prevNav > 0) {
        returns.add((currNav - prevNav) / prevNav);
      }
    }

    return returns;
  }

  /// 计算标准差
  double _calculateStandardDeviation(List<double> values) {
    if (values.isEmpty) return 0.0;

    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance =
        values.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) /
            values.length;

    return sqrt(variance);
  }

  /// 计算波动率
  double _calculateVolatility(
    List<double> returns,
    VolatilityCalculationMethod method,
  ) {
    switch (method) {
      case VolatilityCalculationMethod.standard:
        return _calculateStandardDeviation(returns);
      case VolatilityCalculationMethod.exponential:
        return _calculateExponentialVolatility(returns);
      case VolatilityCalculationMethod.parkinson:
        return _calculateParkinsonVolatility(returns);
      case VolatilityCalculationMethod.garmanKlass:
        return _calculateGarmanKlassVolatility(returns);
    }
  }

  /// 计算指数加权波动率
  double _calculateExponentialVolatility(List<double> returns) {
    if (returns.isEmpty) return 0.0;

    const alpha = 2.0 / (252 + 1); // 252个交易日
    double ema = 0.0;
    double variance = 0.0;

    for (int i = 0; i < returns.length; i++) {
      if (i == 0) {
        ema = returns[i];
      } else {
        ema = alpha * returns[i] + (1 - alpha) * ema;
      }
      final deviation = returns[i] - ema;
      variance = alpha * pow(deviation, 2) + (1 - alpha) * variance;
    }

    return sqrt(variance * 252); // 年化
  }

  /// 计算Parkinson波动率
  double _calculateParkinsonVolatility(List<double> returns) {
    // Parkinson方法使用最高价和最低价，这里简化处理
    return _calculateStandardDeviation(returns) * sqrt(252 / returns.length);
  }

  /// 计算Garman-Klass波动率
  double _calculateGarmanKlassVolatility(List<double> returns) {
    // Garman-Klass方法也是使用OHLC数据，这里简化处理
    return _calculateStandardDeviation(returns) * sqrt(252 / returns.length);
  }

  /// 计算最大回撤
  double _calculateMaxDrawdown(Map<DateTime, double> navHistory) {
    if (navHistory.isEmpty) return 0.0;

    final sortedDates = navHistory.keys.toList()..sort();
    double peak = navHistory[sortedDates.first]!;
    double maxDrawdown = 0.0;

    for (final date in sortedDates) {
      final nav = navHistory[date]!;
      if (nav > peak) {
        peak = nav;
      } else {
        final drawdown = (peak - nav) / peak;
        maxDrawdown = max(maxDrawdown, drawdown);
      }
    }

    return maxDrawdown;
  }

  /// 计算统计指标
  StatisticsData _calculateStatistics(List<double> returns) {
    if (returns.isEmpty) {
      return StatisticsData.empty();
    }

    final positiveReturns = returns.where((r) => r > 0).toList();
    final negativeReturns = returns.where((r) => r < 0).toList();

    final winRate =
        returns.isNotEmpty ? positiveReturns.length / returns.length : 0.0;

    final avgPositiveGain = positiveReturns.isNotEmpty
        ? positiveReturns.reduce((a, b) => a + b) / positiveReturns.length
        : 0.0;

    final avgNegativeLoss = negativeReturns.isNotEmpty
        ? negativeReturns.reduce((a, b) => a + b) / negativeReturns.length
        : 0.0;

    final profitLossRatio =
        avgNegativeLoss != 0 ? avgPositiveGain / avgNegativeLoss.abs() : 0.0;

    // 计算连续收益/亏损
    var currentWins = 0;
    var currentLosses = 0;
    var maxConsecutiveWins = 0;
    var maxConsecutiveLosses = 0;

    for (final ret in returns) {
      if (ret > 0) {
        currentWins++;
        currentLosses = 0;
        maxConsecutiveWins = max(maxConsecutiveWins, currentWins);
      } else if (ret < 0) {
        currentLosses++;
        currentWins = 0;
        maxConsecutiveLosses = max(maxConsecutiveLosses, currentLosses);
      }
    }

    return StatisticsData(
      winRate: winRate,
      profitLossRatio: profitLossRatio,
      maxConsecutiveWins: maxConsecutiveWins,
      maxConsecutiveLosses: maxConsecutiveLosses,
      positiveDays: positiveReturns.length,
      negativeDays: negativeReturns.length,
      totalDays: returns.length,
    );
  }

  /// 合并所有指标
  PortfolioProfitMetrics _mergeAllMetrics({
    required PortfolioHolding holding,
    required BasicProfitMetrics basicMetrics,
    required RiskMetrics riskMetrics,
    CorporateActionResult? corporateActionResult,
    required PortfolioProfitCalculationCriteria criteria,
  }) {
    return PortfolioProfitMetrics(
      fundCode: holding.fundCode,
      analysisDate: DateTime.now(),
      totalReturnAmount: basicMetrics.accumulatedReturnAmount,
      totalReturnRate: basicMetrics.accumulatedReturnRate,
      annualizedReturn: _annualizeReturn(
          basicMetrics.accumulatedReturnRate, criteria.calculationDays),
      dailyReturn: basicMetrics.currentReturnRate,
      weeklyReturn:
          basicMetrics.timeSeriesReturns[CalculationFrequency.weekly] ?? 0.0,
      monthlyReturn:
          basicMetrics.timeSeriesReturns[CalculationFrequency.monthly] ?? 0.0,
      quarterlyReturn:
          basicMetrics.timeSeriesReturns[CalculationFrequency.quarterly] ?? 0.0,
      return1Week:
          basicMetrics.timeSeriesReturns[CalculationFrequency.weekly] ?? 0.0,
      return1Month:
          basicMetrics.timeSeriesReturns[CalculationFrequency.monthly] ?? 0.0,
      return3Months:
          basicMetrics.timeSeriesReturns[CalculationFrequency.quarterly] ?? 0.0,
      return6Months: _estimateReturnForPeriod(basicMetrics, 180),
      return1Year: _estimateReturnForPeriod(basicMetrics, 365),
      return3Years: _estimateReturnForPeriod(basicMetrics, 1095),
      returnYTD: _calculateYearToDateReturn(basicMetrics),
      returnSinceInception: holding.holdingDays > 0
          ? basicMetrics.accumulatedReturnRate * (365 / holding.holdingDays)
          : 0.0,
      volatility: riskMetrics.volatility,
      maxDrawdown: riskMetrics.maxDrawdown,
      sharpeRatio: riskMetrics.sharpeRatio,
      sortinoRatio: riskMetrics.sortinoRatio,
      downsideVolatility: riskMetrics.downsideVolatility,
      winRate: riskMetrics.winRate,
      profitLossRatio: riskMetrics.profitLossRatio,
      maxConsecutiveWinDays: riskMetrics.maxConsecutiveWins,
      maxConsecutiveLossDays: riskMetrics.maxConsecutiveLosses,
      positiveReturnDays: riskMetrics.positiveDays,
      negativeReturnDays: riskMetrics.negativeDays,
      totalTradingDays: riskMetrics.totalDays,
      dataStartDate: criteria.startDate,
      dataEndDate: criteria.endDate,
      analysisPeriodDays: criteria.calculationDays,
      lastUpdated: DateTime.now(),
    );
  }

  /// 计算组合汇总指标
  PortfolioSummary _calculatePortfolioAggregatedMetrics({
    required List<PortfolioHolding> holdings,
    required Map<String, PortfolioProfitMetrics> individualMetrics,
    required PortfolioProfitCalculationCriteria criteria,
  }) {
    if (holdings.isEmpty) {
      return PortfolioSummary.empty();
    }

    // 计算总市值和总成本
    final totalMarketValue =
        holdings.fold(0.0, (sum, h) => sum + h.marketValue);
    final totalCost = holdings.fold(0.0, (sum, h) => sum + h.costValue);

    // 计算加权平均收益
    double weightedReturnRate = 0.0;
    double weightedAnnualizedReturn = 0.0;
    double weightedVolatility = 0.0;

    for (final holding in holdings) {
      final metrics = individualMetrics[holding.fundCode]!;
      final weight = holding.marketValue / totalMarketValue;

      weightedReturnRate += metrics.totalReturnRate * weight;
      weightedAnnualizedReturn += metrics.annualizedReturn * weight;
      weightedVolatility += (metrics.volatility ?? 0.0) * weight;
    }

    // 计算总收益
    final totalReturnAmount = holdings.fold(0.0, (sum, h) {
      final metrics = individualMetrics[h.fundCode]!;
      return sum +
          (metrics.totalReturnAmount * (h.marketValue / totalMarketValue));
    });

    // 计算资产配置
    final allocation = _calculateAssetAllocation(holdings, totalMarketValue);

    return PortfolioSummary(
      portfolioId: 'portfolio_${DateTime.now().millisecondsSinceEpoch}',
      portfolioName: '我的投资组合',
      analysisDate: DateTime.now(),
      totalAssets: totalMarketValue,
      totalMarketValue: totalMarketValue,
      totalCost: totalCost,
      cashAndEquivalents: 0.0,
      numberOfHoldings: holdings.length,
      holdings: holdings,
      totalReturnAmount: totalReturnAmount,
      totalReturnRate: weightedReturnRate,
      dailyReturnAmount: 0.0,
      dailyReturnRate: 0.0,
      annualizedReturn: weightedAnnualizedReturn,
      portfolioVolatility: weightedVolatility,
      equityFundRatio: allocation.equity,
      bondFundRatio: allocation.bond,
      hybridFundRatio: allocation.hybrid,
      moneyMarketFundRatio: allocation.moneyMarket,
      otherFundRatio: allocation.other,
      return1Week: 0.0,
      return1Month: 0.0,
      return3Months: 0.0,
      return6Months: 0.0,
      return1Year: 0.0,
      returnYTD: weightedReturnRate,
      maxHoldingRatio: _calculateMaxHoldingRatio(holdings, totalMarketValue),
      top5HoldingsRatio:
          _calculateTopNHoldingsRatio(holdings, totalMarketValue, 5),
      top10HoldingsRatio:
          _calculateTopNHoldingsRatio(holdings, totalMarketValue, 10),
      dataStartDate: criteria.startDate,
      dataQuality: DataQuality.good,
      lastUpdated: DateTime.now(),
    );
  }

  // Helper methods
  double _annualizeReturn(double returnRate, int days) {
    if (days <= 0) return 0.0;
    return pow(1 + returnRate, 365 / days) - 1;
  }

  double _estimateReturnForPeriod(BasicProfitMetrics metrics, int days) {
    final dailyReturn = metrics.currentReturnRate;
    return pow(1 + dailyReturn, days) - 1;
  }

  double _calculateYearToDateReturn(BasicProfitMetrics metrics) {
    final now = DateTime.now();
    final yearStart = DateTime(now.year, 1, 1);
    final days = now.difference(yearStart).inDays;
    return _estimateReturnForPeriod(metrics, days);
  }

  Duration _getFrequencyDuration(CalculationFrequency frequency) {
    switch (frequency) {
      case CalculationFrequency.daily:
        return const Duration(days: 1);
      case CalculationFrequency.weekly:
        return const Duration(days: 7);
      case CalculationFrequency.monthly:
        return const Duration(days: 30);
      case CalculationFrequency.quarterly:
        return const Duration(days: 90);
      case CalculationFrequency.annually:
        return const Duration(days: 365);
    }
  }

  int _getFrequencyInterval(CalculationFrequency frequency) {
    switch (frequency) {
      case CalculationFrequency.daily:
        return 1;
      case CalculationFrequency.weekly:
        return 7;
      case CalculationFrequency.monthly:
        return 30;
      case CalculationFrequency.quarterly:
        return 90;
      case CalculationFrequency.annually:
        return 365;
    }
  }

  AssetAllocation _calculateAssetAllocation(
      List<PortfolioHolding> holdings, double totalMarketValue) {
    if (totalMarketValue == 0) {
      return AssetAllocation.zero();
    }

    double equity = 0.0,
        bond = 0.0,
        hybrid = 0.0,
        moneyMarket = 0.0,
        other = 0.0;

    for (final holding in holdings) {
      final weight = holding.marketValue / totalMarketValue;

      if (holding.fundType.contains('股票') ||
          holding.fundType.contains('指数') ||
          holding.fundType.contains('QDII')) {
        equity += weight;
      } else if (holding.fundType.contains('债券') ||
          holding.fundType.contains('纯债') ||
          holding.fundType.contains('可转债')) {
        bond += weight;
      } else if (holding.fundType.contains('混合') ||
          holding.fundType.contains('配置') ||
          holding.fundType.contains('灵活')) {
        hybrid += weight;
      } else if (holding.fundType.contains('货币') ||
          holding.fundType.contains('理财') ||
          holding.fundType.contains('同业')) {
        moneyMarket += weight;
      } else {
        other += weight;
      }
    }

    return AssetAllocation(
      equity: equity,
      bond: bond,
      hybrid: hybrid,
      moneyMarket: moneyMarket,
      other: other,
    );
  }

  double _calculateMaxHoldingRatio(
      List<PortfolioHolding> holdings, double totalMarketValue) {
    if (holdings.isEmpty || totalMarketValue == 0) return 0.0;

    final maxHoldingValue = holdings.map((h) => h.marketValue).reduce(max);
    return maxHoldingValue / totalMarketValue;
  }

  double _calculateTopNHoldingsRatio(
      List<PortfolioHolding> holdings, double totalMarketValue, int n) {
    if (holdings.isEmpty || totalMarketValue == 0) return 0.0;

    final sortedHoldings = List<PortfolioHolding>.from(holdings)
      ..sort((a, b) => b.marketValue.compareTo(a.marketValue));

    final topNHoldings = sortedHoldings.take(n).toList();
    final topNValue = topNHoldings.fold(0.0, (sum, h) => sum + h.marketValue);

    return topNValue / totalMarketValue;
  }

  /// 生成缓存键
  String generateCacheKey(
      PortfolioHolding holding, PortfolioProfitCalculationCriteria criteria) {
    final buffer = StringBuffer();
    buffer.write('fund_${holding.fundCode}');
    buffer.write('_${holding.holdingAmount.toStringAsFixed(4)}');
    buffer.write('_${criteria.startDate.millisecondsSinceEpoch}');
    buffer.write('_${criteria.endDate.millisecondsSinceEpoch}');
    buffer.write('_${criteria.frequency.name}');
    buffer.write('_${criteria.returnType.name}');
    buffer.write('_${criteria.includeDividendReinvestment ? 1 : 0}');
    buffer.write('_${criteria.considerCorporateActions ? 1 : 0}');
    buffer.write('_${criteria.benchmarkCode ?? "null"}');
    return buffer.toString();
  }

  /// 计算基金指标（返回Either类型）
  Future<Either<Failure, PortfolioProfitMetrics>> calculateFundMetrics({
    required PortfolioHolding holding,
    required PortfolioProfitCalculationCriteria criteria,
    Map<DateTime, double>? navHistory,
    Map<DateTime, double>? benchmarkHistory,
    List<FundCorporateAction>? dividendHistory,
    List<FundSplitDetail>? splitHistory,
  }) async {
    try {
      final metrics = await calculateFundProfitMetrics(
        holding: holding,
        criteria: criteria,
        navHistory: navHistory,
        benchmarkHistory: benchmarkHistory,
        corporateActions: dividendHistory,
        splitDetails: splitHistory,
      );
      return Right(metrics);
    } catch (e) {
      return Left(CalculationFailure('计算基金指标失败: $e'));
    }
  }

  /// 验证计算标准
  Future<bool> validateCriteria(
      PortfolioProfitCalculationCriteria criteria) async {
    // 基本验证
    if (!criteria.isValid()) {
      return false;
    }

    final days = criteria.calculationDays;

    // 检查时间范围是否合理
    if (days > 3650) {
      // 超过10年
      return false;
    }

    if (days < 7) {
      // 少于7天
      return false;
    }

    // 检查频率和期间的匹配
    if (criteria.frequency == CalculationFrequency.daily && days < 30) {
      return false; // 日频率需要至少30天数据
    }

    return true;
  }

  /// 分析数据质量
  Future<Either<Failure, DataQualityReport>> analyzeDataQuality({
    required String fundCode,
    required Map<DateTime, double> navHistory,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final totalDays = endDate.difference(startDate).inDays;
      final availableDataPoints = navHistory.length;
      final missingDataPoints = totalDays - availableDataPoints;
      final completenessRatio =
          totalDays > 0 ? availableDataPoints / totalDays : 0.0;

      DataQuality quality;
      final List<String> issues = [];

      if (completenessRatio >= 0.95) {
        quality = DataQuality.excellent;
      } else if (completenessRatio >= 0.85) {
        quality = DataQuality.good;
      } else if (completenessRatio >= 0.70) {
        quality = DataQuality.fair;
      } else {
        quality = DataQuality.poor;
      }

      if (missingDataPoints > 0) {
        issues.add('缺失 $missingDataPoints 个数据点');
      }

      if (availableDataPoints < 30) {
        issues.add('数据点过少，可能影响计算准确性');
      }

      final report = DataQualityReport(
        fundCode: fundCode,
        startDate: startDate,
        endDate: endDate,
        totalDays: totalDays,
        availableDataPoints: availableDataPoints,
        missingDataPoints: missingDataPoints,
        quality: quality,
        issues: issues,
        dataPointCounts: {'total': availableDataPoints},
        reportGeneratedAt: DateTime.now(),
      );

      return Right(report);
    } catch (e) {
      return Left(DataQualityFailure('分析数据质量失败: $e'));
    }
  }
}

// Supporting classes
class BasicProfitMetrics {
  final double currentReturnRate;
  final double currentReturnAmount;
  final double accumulatedReturnRate;
  final double accumulatedReturnAmount;
  final Map<CalculationFrequency, double> timeSeriesReturns;

  BasicProfitMetrics({
    required this.currentReturnRate,
    required this.currentReturnAmount,
    required this.accumulatedReturnRate,
    required this.accumulatedReturnAmount,
    required this.timeSeriesReturns,
  });
}

class RiskMetrics {
  final double volatility;
  final double maxDrawdown;
  final double sharpeRatio;
  final double sortinoRatio;
  final double downsideVolatility;
  final double winRate;
  final double profitLossRatio;
  final int maxConsecutiveWins;
  final int maxConsecutiveLosses;
  final int positiveDays;
  final int negativeDays;
  final int totalDays;

  RiskMetrics({
    required this.volatility,
    required this.maxDrawdown,
    required this.sharpeRatio,
    required this.sortinoRatio,
    required this.downsideVolatility,
    required this.winRate,
    required this.profitLossRatio,
    required this.maxConsecutiveWins,
    required this.maxConsecutiveLosses,
    required this.positiveDays,
    required this.negativeDays,
    required this.totalDays,
  });

  factory RiskMetrics.empty() {
    return RiskMetrics(
      volatility: 0.0,
      maxDrawdown: 0.0,
      sharpeRatio: 0.0,
      sortinoRatio: 0.0,
      downsideVolatility: 0.0,
      winRate: 0.0,
      profitLossRatio: 0.0,
      maxConsecutiveWins: 0,
      maxConsecutiveLosses: 0,
      positiveDays: 0,
      negativeDays: 0,
      totalDays: 0,
    );
  }
}

class StatisticsData {
  final double winRate;
  final double profitLossRatio;
  final int maxConsecutiveWins;
  final int maxConsecutiveLosses;
  final int positiveDays;
  final int negativeDays;
  final int totalDays;

  StatisticsData({
    required this.winRate,
    required this.profitLossRatio,
    required this.maxConsecutiveWins,
    required this.maxConsecutiveLosses,
    required this.positiveDays,
    required this.negativeDays,
    required this.totalDays,
  });

  factory StatisticsData.empty() {
    return StatisticsData(
      winRate: 0.0,
      profitLossRatio: 0.0,
      maxConsecutiveWins: 0,
      maxConsecutiveLosses: 0,
      positiveDays: 0,
      negativeDays: 0,
      totalDays: 0,
    );
  }
}

class PeriodReturn {
  final DateTime startDate;
  final DateTime endDate;
  final double returnRate;
  final int days;

  PeriodReturn({
    required this.startDate,
    required this.endDate,
    required this.returnRate,
    required this.days,
  });
}

class AssetAllocation {
  final double equity;
  final double bond;
  final double hybrid;
  final double moneyMarket;
  final double other;

  AssetAllocation({
    required this.equity,
    required this.bond,
    required this.hybrid,
    required this.moneyMarket,
    required this.other,
  });

  factory AssetAllocation.zero() {
    return AssetAllocation(
      equity: 0.0,
      bond: 0.0,
      hybrid: 0.0,
      moneyMarket: 0.0,
      other: 0.0,
    );
  }
}

/// 计算日志记录服务
class CalculationLogger {
  void logStart(String method, Map<String, dynamic> params) {
    // 在生产环境中应该使用适当的日志框架
    debugPrint('🚀 Starting $method with params: $params');
  }

  void logSuccess(String method, String result) {
    debugPrint('✅ Completed $method successfully');
  }

  void logError(String method, dynamic error, StackTrace? stack) {
    debugPrint('❌ Error in $method: $error');
    if (stack != null) {
      debugPrint('Stack trace: $stack');
    }
  }

  void logWarning(String method, String warning) {
    debugPrint('⚠️ Warning in $method: $warning');
  }
}

/// 公司行为处理结果
class CorporateActionResult {
  final Map<DateTime, double> adjustedNavHistory;
  final List<FundCorporateAction> processedActions;
  final double adjustmentFactor;
  final String description;

  CorporateActionResult({
    required this.adjustedNavHistory,
    required this.processedActions,
    required this.adjustmentFactor,
    required this.description,
  });
}
