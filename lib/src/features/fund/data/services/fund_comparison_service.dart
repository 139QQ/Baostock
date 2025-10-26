import 'dart:math';
import '../../domain/entities/multi_dimensional_comparison_criteria.dart';
import '../../domain/entities/comparison_result.dart';
import '../../domain/entities/fund_ranking.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/network/fund_api_client.dart';

/// 基金对比服务
///
/// 提供基金对比相关的计算逻辑和数据处理
class FundComparisonService {
  static const String _tag = 'FundComparisonService';

  /// 计算多维度对比结果
  ///
  /// [fundRankings] 基金排行榜数据
  /// [criteria] 对比条件
  /// 返回对比结果
  Future<ComparisonResult> calculateComparison(
    List<FundRanking> fundRankings,
    MultiDimensionalComparisonCriteria criteria,
  ) async {
    try {
      AppLogger.info(_tag, '开始计算多维度对比结果');

      final stopwatch = Stopwatch()..start();

      // 验证输入参数
      final validationError = criteria.getValidationError();
      if (validationError != null) {
        throw ArgumentError(validationError);
      }

      // 过滤和分组基金数据
      final groupedData = _groupFundDataByPeriod(fundRankings, criteria);

      // 计算每个基金的对比数据
      final fundComparisonData = <FundComparisonData>[];

      for (final fundCode in criteria.fundCodes) {
        for (final period in criteria.periods) {
          final data = groupedData[fundCode]?[period];
          if (data != null) {
            final comparisonData = await _calculateFundComparisonData(
              data,
              fundCode,
              period,
              criteria,
            );
            fundComparisonData.add(comparisonData);
          }
        }
      }

      // 计算统计信息
      final statistics = await _calculateStatistics(
        fundComparisonData,
        criteria.fundCodes,
        criteria.periods,
      );

      // 创建对比结果
      final result = ComparisonResult(
        criteria: criteria,
        fundData: fundComparisonData,
        statistics: statistics,
        calculatedAt: DateTime.now(),
        dataSource: 'Calculated',
      );

      stopwatch.stop();
      AppLogger.info(_tag, '对比计算完成，耗时: ${stopwatch.elapsedMilliseconds}ms');

      return result;
    } catch (e) {
      AppLogger.error(_tag, '计算对比结果失败: $e');
      return ComparisonResult(
        criteria: criteria,
        fundData: [],
        statistics: ComparisonStatistics(
          averageReturn: 0.0,
          maxReturn: 0.0,
          minReturn: 0.0,
          returnStdDev: 0.0,
          averageVolatility: 0.0,
          maxVolatility: 0.0,
          minVolatility: 0.0,
          averageSharpeRatio: 0.0,
          correlationMatrix: {},
          updatedAt: DateTime.now(),
        ),
        calculatedAt: DateTime.now(),
        hasError: true,
        errorMessage: e.toString(),
      );
    }
  }

  /// 按基金和时间段分组数据
  Map<String, Map<RankingPeriod, FundRanking>> _groupFundDataByPeriod(
    List<FundRanking> fundRankings,
    MultiDimensionalComparisonCriteria criteria,
  ) {
    final groupedData = <String, Map<RankingPeriod, FundRanking>>{};

    for (final ranking in fundRankings) {
      if (criteria.fundCodes.contains(ranking.fundCode)) {
        groupedData.putIfAbsent(ranking.fundCode, () => {});
        groupedData[ranking.fundCode]![ranking.rankingPeriod] = ranking;
      }
    }

    return groupedData;
  }

  /// 计算单个基金的对比数据
  Future<FundComparisonData> _calculateFundComparisonData(
    FundRanking fundRanking,
    String fundCode,
    RankingPeriod period,
    MultiDimensionalComparisonCriteria criteria,
  ) async {
    // 获取收益率数据
    final totalReturn = _getReturnForPeriod(fundRanking, period);
    final annualizedReturn = _calculateAnnualizedReturn(totalReturn, period);

    // 计算风险指标（简化实现）
    final volatility = _estimateVolatility(fundRanking, period);
    final sharpeRatio = _calculateSharpeRatio(annualizedReturn, volatility);
    final maxDrawdown = _estimateMaxDrawdown(fundRanking, period);

    // 计算排名和超越百分比
    final ranking = fundRanking.rankingPosition;
    final totalCount = fundRanking.totalCount;
    final beatCategoryPercent = ((totalCount - ranking) / totalCount) * 100;

    // 获取基准和同类数据（这里使用模拟数据）
    final categoryAverage =
        await _getCategoryAverage(fundRanking.fundType, period);
    final benchmarkReturn =
        await _getBenchmarkReturn('000300', period); // 沪深300作为基准

    final beatBenchmarkPercent =
        ((totalReturn - benchmarkReturn) / benchmarkReturn.abs()) * 100;

    return FundComparisonData(
      fundCode: fundCode,
      fundName: fundRanking.fundName,
      fundType: fundRanking.fundType,
      period: period,
      totalReturn: totalReturn,
      annualizedReturn: annualizedReturn,
      volatility: volatility,
      sharpeRatio: sharpeRatio,
      maxDrawdown: maxDrawdown,
      ranking: ranking,
      categoryAverage: categoryAverage,
      beatCategoryPercent: beatCategoryPercent,
      benchmarkReturn: benchmarkReturn,
      beatBenchmarkPercent: beatBenchmarkPercent,
    );
  }

  /// 获取指定时间段的收益率
  double _getReturnForPeriod(FundRanking fundRanking, RankingPeriod period) {
    switch (period) {
      case RankingPeriod.daily:
        return fundRanking.dailyReturn;
      case RankingPeriod.oneWeek:
        return fundRanking.return1W;
      case RankingPeriod.oneMonth:
        return fundRanking.return1M;
      case RankingPeriod.threeMonths:
        return fundRanking.return3M;
      case RankingPeriod.sixMonths:
        return fundRanking.return6M;
      case RankingPeriod.oneYear:
        return fundRanking.return1Y;
      case RankingPeriod.twoYears:
        return fundRanking.return2Y;
      case RankingPeriod.threeYears:
        return fundRanking.return3Y;
      default:
        return fundRanking.return1M; // 默认返回1月收益率
    }
  }

  /// 计算年化收益率
  double _calculateAnnualizedReturn(double totalReturn, RankingPeriod period) {
    double years;

    switch (period) {
      case RankingPeriod.daily:
        years = 1 / 365;
        break;
      case RankingPeriod.oneWeek:
        years = 1 / 52;
        break;
      case RankingPeriod.oneMonth:
        years = 1 / 12;
        break;
      case RankingPeriod.threeMonths:
        years = 0.25;
        break;
      case RankingPeriod.sixMonths:
        years = 0.5;
        break;
      case RankingPeriod.oneYear:
        years = 1.0;
        break;
      case RankingPeriod.twoYears:
        years = 2.0;
        break;
      case RankingPeriod.threeYears:
        years = 3.0;
        break;
      default:
        years = 1.0;
    }

    if (years <= 0) return 0.0;

    return pow(1 + totalReturn, 1 / years) - 1;
  }

  /// 估算波动率（简化实现）
  double _estimateVolatility(FundRanking fundRanking, RankingPeriod period) {
    // 基于基金类型和历史数据估算波动率
    final baseVolatility = _getBaseVolatilityByType(fundRanking.fundType);
    final periodMultiplier = _getVolatilityPeriodMultiplier(period);

    return baseVolatility * periodMultiplier;
  }

  /// 根据基金类型获取基础波动率
  double _getBaseVolatilityByType(String fundType) {
    if (fundType.contains('股票')) return 0.20; // 股票型基金波动率约20%
    if (fundType.contains('债券')) return 0.05; // 债券型基金波动率约5%
    if (fundType.contains('混合')) return 0.15; // 混合型基金波动率约15%
    if (fundType.contains('指数')) return 0.18; // 指数型基金波动率约18%
    if (fundType.contains('货币')) return 0.02; // 货币型基金波动率约2%

    return 0.15; // 默认波动率
  }

  /// 获取波动率时间段乘数
  double _getVolatilityPeriodMultiplier(RankingPeriod period) {
    switch (period) {
      case RankingPeriod.daily:
      case RankingPeriod.oneWeek:
        return 1.2; // 短期波动率通常更高
      case RankingPeriod.oneMonth:
      case RankingPeriod.threeMonths:
        return 1.0;
      case RankingPeriod.sixMonths:
      case RankingPeriod.oneYear:
        return 0.9; // 长期波动率趋于稳定
      case RankingPeriod.twoYears:
      case RankingPeriod.threeYears:
        return 0.8;
      default:
        return 1.0;
    }
  }

  /// 计算夏普比率
  double _calculateSharpeRatio(double annualizedReturn, double volatility) {
    const riskFreeRate = 0.03; // 假设无风险利率为3%

    if (volatility == 0) return 0.0;

    return (annualizedReturn - riskFreeRate) / volatility;
  }

  /// 估算最大回撤（简化实现）
  double _estimateMaxDrawdown(FundRanking fundRanking, RankingPeriod period) {
    // 基于收益率和基金类型估算最大回撤
    final totalReturn = _getReturnForPeriod(fundRanking, period);
    final baseDrawdown = _getBaseDrawdownByType(fundRanking.fundType);

    // 简化计算：基于收益率调整最大回撤
    return max(baseDrawdown, -totalReturn * 0.5);
  }

  /// 根据基金类型获取基础最大回撤
  double _getBaseDrawdownByType(String fundType) {
    if (fundType.contains('股票')) return -0.30; // 股票型基金最大回撤约30%
    if (fundType.contains('债券')) return -0.05; // 债券型基金最大回撤约5%
    if (fundType.contains('混合')) return -0.20; // 混合型基金最大回撤约20%
    if (fundType.contains('指数')) return -0.25; // 指数型基金最大回撤约25%
    if (fundType.contains('货币')) return -0.01; // 货币型基金最大回撤约1%

    return -0.20; // 默认最大回撤
  }

  /// 获取同类平均收益率（模拟实现）
  Future<double> _getCategoryAverage(
      String fundType, RankingPeriod period) async {
    // 这里应该调用实际的API获取同类平均数据
    // 暂时返回模拟数据
    switch (period) {
      case RankingPeriod.oneMonth:
        return fundType.contains('股票') ? 0.02 : 0.005;
      case RankingPeriod.threeMonths:
        return fundType.contains('股票') ? 0.06 : 0.015;
      case RankingPeriod.sixMonths:
        return fundType.contains('股票') ? 0.12 : 0.03;
      case RankingPeriod.oneYear:
        return fundType.contains('股票') ? 0.15 : 0.04;
      default:
        return 0.05;
    }
  }

  /// 获取基准收益率（模拟实现）
  Future<double> _getBenchmarkReturn(
      String benchmarkCode, RankingPeriod period) async {
    // 这里应该调用实际的API获取基准数据
    // 暂时返回沪深300的模拟数据
    switch (period) {
      case RankingPeriod.oneMonth:
        return 0.01;
      case RankingPeriod.threeMonths:
        return 0.03;
      case RankingPeriod.sixMonths:
        return 0.06;
      case RankingPeriod.oneYear:
        return 0.10;
      default:
        return 0.05;
    }
  }

  /// 计算统计信息
  Future<ComparisonStatistics> _calculateStatistics(
    List<FundComparisonData> fundData,
    List<String> fundCodes,
    List<RankingPeriod> periods,
  ) async {
    if (fundData.isEmpty) {
      return ComparisonStatistics(
        averageReturn: 0.0,
        maxReturn: 0.0,
        minReturn: 0.0,
        returnStdDev: 0.0,
        averageVolatility: 0.0,
        maxVolatility: 0.0,
        minVolatility: 0.0,
        averageSharpeRatio: 0.0,
        correlationMatrix: {},
        updatedAt: DateTime.now(),
      );
    }

    // 计算收益率统计
    final returns = fundData.map((data) => data.totalReturn).toList();
    final averageReturn = returns.reduce((a, b) => a + b) / returns.length;
    final maxReturn = returns.reduce(max);
    final minReturn = returns.reduce(min);

    // 计算标准差
    final variance =
        returns.map((r) => pow(r - averageReturn, 2)).reduce((a, b) => a + b) /
            returns.length;
    final returnStdDev = sqrt(variance);

    // 计算波动率统计
    final volatilities = fundData.map((data) => data.volatility).toList();
    final averageVolatility =
        volatilities.reduce((a, b) => a + b) / volatilities.length;
    final maxVolatility = volatilities.reduce(max);
    final minVolatility = volatilities.reduce(min);

    // 计算夏普比率统计
    final sharpeRatios = fundData.map((data) => data.sharpeRatio).toList();
    final averageSharpeRatio =
        sharpeRatios.reduce((a, b) => a + b) / sharpeRatios.length;

    // 计算相关性矩阵（简化实现）
    final correlationMatrix = <String, Map<String, double>>{};
    for (final fund1 in fundCodes) {
      correlationMatrix[fund1] = {};
      for (final fund2 in fundCodes) {
        if (fund1 == fund2) {
          correlationMatrix[fund1]![fund2] = 1.0;
        } else {
          // 简化的相关性计算
          correlationMatrix[fund1]![fund2] = _calculateSimpleCorrelation(
            fundData,
            fund1,
            fund2,
          );
        }
      }
    }

    return ComparisonStatistics(
      averageReturn: averageReturn,
      maxReturn: maxReturn,
      minReturn: minReturn,
      returnStdDev: returnStdDev,
      averageVolatility: averageVolatility,
      maxVolatility: maxVolatility,
      minVolatility: minVolatility,
      averageSharpeRatio: averageSharpeRatio,
      correlationMatrix: correlationMatrix,
      updatedAt: DateTime.now(),
    );
  }

  /// 计算简单相关性（简化实现）
  double _calculateSimpleCorrelation(
    List<FundComparisonData> fundData,
    String fund1,
    String fund2,
  ) {
    // 获取两个基金的收益率数据
    final returns1 = fundData
        .where((data) => data.fundCode == fund1)
        .map((data) => data.totalReturn)
        .toList();

    final returns2 = fundData
        .where((data) => data.fundCode == fund2)
        .map((data) => data.totalReturn)
        .toList();

    if (returns1.length != returns2.length || returns1.isEmpty) {
      return 0.5; // 默认中等相关性
    }

    // 简化的相关性计算
    final avg1 = returns1.reduce((a, b) => a + b) / returns1.length;
    final avg2 = returns2.reduce((a, b) => a + b) / returns2.length;

    double numerator = 0.0;
    double variance1 = 0.0;
    double variance2 = 0.0;

    for (int i = 0; i < returns1.length; i++) {
      final diff1 = returns1[i] - avg1;
      final diff2 = returns2[i] - avg2;

      numerator += diff1 * diff2;
      variance1 += diff1 * diff1;
      variance2 += diff2 * diff2;
    }

    if (variance1 == 0 || variance2 == 0) return 0.0;

    return numerator / (sqrt(variance1) * sqrt(variance2));
  }

  /// 从API获取实时基金对比数据
  Future<ComparisonResult> getRealtimeComparisonData(
    MultiDimensionalComparisonCriteria criteria,
  ) async {
    try {
      AppLogger.info(_tag, '开始获取实时对比数据: ${criteria.fundCodes}');

      final stopwatch = Stopwatch()..start();

      // 并行获取所有基金的数据
      final futures = criteria.fundCodes
          .map((fundCode) =>
              _fetchFundDataForComparison(fundCode, criteria.periods))
          .toList();

      final results = await Future.wait(futures);

      // 转换为FundRanking对象
      final fundRankings = <FundRanking>[];
      for (int i = 0; i < criteria.fundCodes.length; i++) {
        final fundCode = criteria.fundCodes[i];
        final fundData = results[i];

        if (fundData != null) {
          // 为每个时间段创建FundRanking对象
          for (final period in criteria.periods) {
            final periodData = fundData[period.name];
            if (periodData != null) {
              fundRankings.add(FundRanking(
                fundCode: fundCode,
                fundName: periodData['fund_name'] ?? '未知基金',
                fundType: periodData['fund_type'] ?? '未知类型',
                company: periodData['company'] ?? '未知公司',
                rankingPosition: _parseInt(periodData['ranking']) ?? 0,
                totalCount: _parseInt(periodData['total_count']) ?? 100,
                unitNav: _parseDouble(periodData['unit_nav']),
                accumulatedNav: _parseDouble(periodData['accumulated_nav']),
                dailyReturn: _parsePercentage(periodData['daily_return']),
                return1W: _parsePercentage(periodData['return_1w']),
                return1M: _parsePercentage(periodData['return_1m']),
                return3M: _parsePercentage(periodData['return_3m']),
                return6M: _parsePercentage(periodData['return_6m']),
                return1Y: _parsePercentage(periodData['return_1y']),
                return2Y: _parsePercentage(periodData['return_2y']),
                return3Y: _parsePercentage(periodData['return_3y']),
                returnYTD: _parsePercentage(periodData['return_ytd']),
                returnSinceInception:
                    _parsePercentage(periodData['return_since_inception']),
                rankingDate: _parseDateTime(periodData['ranking_date']) ??
                    DateTime.now(),
                rankingType: RankingType.overall,
                rankingPeriod: period,
              ));
            }
          }
        }
      }

      if (fundRankings.isEmpty) {
        throw Exception('未获取到有效的基金数据');
      }

      // 使用获取的数据计算对比结果
      final result = await calculateComparison(fundRankings, criteria);

      stopwatch.stop();
      AppLogger.info(_tag, '实时对比数据获取完成，耗时: ${stopwatch.elapsedMilliseconds}ms');

      return result;
    } catch (e) {
      AppLogger.error(_tag, '获取实时对比数据失败: $e');
      throw Exception('获取实时对比数据失败: $e');
    }
  }

  /// 获取单个基金的数据
  Future<Map<String, dynamic>?> _fetchFundDataForComparison(
    String fundCode,
    List<RankingPeriod> periods,
  ) async {
    try {
      final Map<String, dynamic> fundData = {};

      // 获取基金基本信息
      final basicInfo = await FundApiClient.getFundsForComparison([fundCode]);
      fundData['basic_info'] = basicInfo;

      // 为每个时间段获取历史数据
      for (final period in periods) {
        try {
          final periodStr = _periodToString(period);
          final historicalData =
              await FundApiClient.getFundHistoricalData(fundCode, periodStr);

          // 处理历史数据，提取关键指标
          fundData[period.name] =
              _processHistoricalData(historicalData, period);
        } catch (e) {
          AppLogger.warn(_tag, '获取基金 $fundCode 的 $period 数据失败: $e');
          // 使用默认数据，避免整个对比失败
          fundData[period.name] = _getDefaultFundData(fundCode, period);
        }
      }

      return fundData;
    } catch (e) {
      AppLogger.error(_tag, '获取基金 $fundCode 数据失败: $e');
      return null;
    }
  }

  /// 处理历史数据，提取关键指标
  Map<String, dynamic> _processHistoricalData(
    Map<String, dynamic> historicalData,
    RankingPeriod period,
  ) {
    try {
      final data = historicalData['data'] ?? [];

      if (data.isEmpty) {
        return _getDefaultFundData('unknown', period);
      }

      // 从历史数据计算各种指标
      final returns = <double>[];
      double previousValue = 0.0;

      for (final item in data) {
        final currentValue = _parseDouble(item['nav']);
        if (previousValue > 0) {
          final returnValue = (currentValue - previousValue) / previousValue;
          returns.add(returnValue);
        }
        previousValue = currentValue;
      }

      if (returns.isEmpty) {
        return _getDefaultFundData('unknown', period);
      }

      // 计算统计指标
      final totalReturn = returns.fold(0.0, (a, b) => a + b);
      final averageReturn = totalReturn / returns.length;
      final volatility = _calculateVolatility(returns);
      final annualizedReturn = _annualizeReturn(averageReturn, period);
      final maxDrawdown = _calculateMaxDrawdown(returns);
      final sharpeRatio = volatility > 0 ? annualizedReturn / volatility : 0.0;

      return {
        'fund_name': historicalData['fund_name'] ?? '未知基金',
        'fund_type': historicalData['fund_type'] ?? '未知类型',
        'total_return': totalReturn.toString(),
        'annualized_return': annualizedReturn.toString(),
        'volatility': volatility.toString(),
        'sharpe_ratio': sharpeRatio.toString(),
        'max_drawdown': maxDrawdown.toString(),
        'ranking': 1, // 需要实际计算排名
        'update_date': DateTime.now().toString().substring(0, 10),
        'benchmark': '沪深300',
        'beat_benchmark_percent': '0.0',
        'beat_category_percent': '0.0',
        'category': '未知分类',
        'category_ranking': 1,
        'total_category_count': 100,
      };
    } catch (e) {
      AppLogger.error(_tag, '处理历史数据失败: $e');
      return _getDefaultFundData('unknown', period);
    }
  }

  /// 获取默认基金数据
  Map<String, dynamic> _getDefaultFundData(
      String fundCode, RankingPeriod period) {
    return {
      'fund_name': '基金$fundCode',
      'fund_type': '未知类型',
      'total_return': '0.0',
      'annualized_return': '0.0',
      'volatility': '0.15',
      'sharpe_ratio': '0.0',
      'max_drawdown': '-0.1',
      'ranking': 999,
      'update_date': DateTime.now().toString().substring(0, 10),
      'benchmark': '沪深300',
      'beat_benchmark_percent': '0.0',
      'beat_category_percent': '0.0',
      'category': '未知分类',
      'category_ranking': 999,
      'total_category_count': 100,
    };
  }

  /// 将时间段转换为字符串
  String _periodToString(RankingPeriod period) {
    switch (period) {
      case RankingPeriod.oneMonth:
        return '1';
      case RankingPeriod.threeMonths:
        return '3';
      case RankingPeriod.sixMonths:
        return '6';
      case RankingPeriod.oneYear:
        return '12';
      case RankingPeriod.threeYears:
        return '36';
      default:
        return '12';
    }
  }

  /// 年化收益率计算
  double _annualizeReturn(double totalReturn, RankingPeriod period) {
    int months;
    switch (period) {
      case RankingPeriod.daily:
        months = 0; // 日收益率无需年化
        break;
      case RankingPeriod.oneWeek:
        months = 0; // 周收益率无需年化
        break;
      case RankingPeriod.oneMonth:
        months = 1;
        break;
      case RankingPeriod.threeMonths:
        months = 3;
        break;
      case RankingPeriod.sixMonths:
        months = 6;
        break;
      case RankingPeriod.oneYear:
        months = 12;
        break;
      case RankingPeriod.twoYears:
        months = 24;
        break;
      case RankingPeriod.threeYears:
        months = 36;
        break;
      case RankingPeriod.ytd:
        months = DateTime.now().month; // 今年来的月数
        break;
      case RankingPeriod.sinceInception:
        months = 0; // 成立来无需年化
        break;
    }

    if (months == 0) return totalReturn; // 日收益率无需年化
    return pow(1 + totalReturn, 12 / months) - 1;
  }

  /// 计算最大回撤
  double _calculateMaxDrawdown(List<double> returns) {
    if (returns.isEmpty) return 0.0;

    double peak = returns.first;
    double maxDrawdown = 0.0;
    double currentValue = returns.first;

    for (final returnValue in returns) {
      currentValue += returnValue;
      if (currentValue > peak) {
        peak = currentValue;
      }
      final drawdown = (peak - currentValue) / peak;
      if (drawdown > maxDrawdown) {
        maxDrawdown = drawdown;
      }
    }

    return -maxDrawdown;
  }

  /// 解析百分比字符串
  double _parsePercentage(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final cleanValue = value.replaceAll('%', '').trim();
      return double.tryParse(cleanValue) ?? 0.0;
    }
    return 0.0;
  }

  /// 解析数字
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// 解析整数
  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// 解析日期时间
  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// 计算波动率
  double _calculateVolatility(List<double> returns) {
    if (returns.length < 2) return 0.0;

    final mean = returns.reduce((a, b) => a + b) / returns.length;
    final variance =
        returns.map((r) => (r - mean) * (r - mean)).reduce((a, b) => a + b) /
            (returns.length - 1);

    return variance > 0 ? variance : 0.0;
  }
}
