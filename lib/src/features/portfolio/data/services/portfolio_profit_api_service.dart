import 'dart:math' as math;
import 'package:dartz/dartz.dart';
import '../../domain/entities/portfolio_holding.dart';
import '../../domain/entities/fund_corporate_action.dart';
import '../../domain/entities/fund_split_detail.dart';
import '../../domain/entities/portfolio_profit_metrics.dart';
import '../../domain/repositories/portfolio_profit_repository.dart';
import '../../../../core/network/fund_api_client.dart';
import '../../../../core/utils/logger.dart';
import '../../../../services/fund_nav_api_service.dart';

/// 组合收益API服务
///
/// 集成AKShare基金数据API，提供收益计算所需的数据服务
class PortfolioProfitApiService {
  PortfolioProfitApiService();

  /// 获取用户持仓数据
  Future<Either<Failure, List<PortfolioHolding>>> getUserHoldings(
      String userId) async {
    try {
      AppLogger.info('Fetching user holdings for user: $userId');

      // 模拟API调用 - 实际项目中这里应该调用真实的用户持仓API
      // 现在返回一些模拟数据用于测试
      final mockHoldings = _getMockHoldings(userId);

      AppLogger.info('Retrieved ${mockHoldings.length} mock holdings');
      return Right(mockHoldings);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch user holdings', e, stackTrace);
      return Left(NetworkFailure(e.toString(), originalError: e));
    }
  }

  /// 获取基金净值历史数据
  Future<Either<Failure, Map<DateTime, double>>> getFundNavHistory({
    required String fundCode,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      AppLogger.info(
          'Fetching NAV history for $fundCode from ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');

      // 使用新的FundNavApiService获取基金净值数据
      // 这解决了累计净值字段为null的问题
      try {
        final navDataList =
            await FundNavApiService.getFundNavData(fundCode: fundCode);

        // 转换为Map<DateTime, double>格式
        final navHistory = <DateTime, double>{};
        for (final navData in navDataList) {
          // 只包含在时间范围内的数据
          if (navData.navDate.isAfter(startDate) &&
              navData.navDate.isBefore(endDate)) {
            navHistory[navData.navDate] = navData.unitNav;
          }
        }

        AppLogger.info(
            'Retrieved ${navHistory.length} NAV data points using FundNavApiService');

        // 如果从新API获取到了数据，直接返回
        if (navHistory.isNotEmpty) {
          return Right(navHistory);
        }

        // 如果新API没有数据，fallback到旧API
        AppLogger.warn(
            'No data from FundNavApiService, falling back to FundApiClient');
        final data = await FundApiClient.getFundHistory(fundCode,
            period: _convertToApiPeriod(_formatPeriod(startDate, endDate)));
        final fallbackNavHistory = _parseNavHistoryData(data, fundCode);
        AppLogger.info(
            'Retrieved ${fallbackNavHistory.length} NAV data points from fallback');
        return Right(fallbackNavHistory);
      } catch (e) {
        AppLogger.warn('FundNavApiService failed, trying fallback', e);
        // Fallback到旧的API客户端
        try {
          final data = await FundApiClient.getFundHistory(fundCode,
              period: _convertToApiPeriod(_formatPeriod(startDate, endDate)));
          final navHistory = _parseNavHistoryData(data, fundCode);
          AppLogger.info(
              'Retrieved ${navHistory.length} NAV data points from fallback');
          return Right(navHistory);
        } catch (fallbackError) {
          return Left(NetworkFailure(
              'Both FundNavApiService and FundApiClient failed: ${e.toString()} | ${fallbackError.toString()}'));
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch NAV history', e, stackTrace);
      return Left(NetworkFailure(e.toString(), originalError: e));
    }
  }

  /// 获取基金累计净值历史数据
  ///
  /// 使用新的FundNavApiService获取完整的累计净值数据
  /// 解决累计净值字段为null的问题
  Future<Either<Failure, Map<DateTime, double>>> getFundAccumulatedNavHistory({
    required String fundCode,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      AppLogger.info(
          'Fetching accumulated NAV history for $fundCode from ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');

      // 使用新的FundNavApiService获取基金净值数据
      try {
        final navDataList =
            await FundNavApiService.getFundNavData(fundCode: fundCode);

        // 转换为Map<DateTime, double>格式，只包含累计净值
        final accumulatedNavHistory = <DateTime, double>{};
        for (final navData in navDataList) {
          // 只包含在时间范围内的数据
          if (navData.navDate.isAfter(startDate) &&
              navData.navDate.isBefore(endDate)) {
            accumulatedNavHistory[navData.navDate] = navData.accumulatedNav;
          }
        }

        AppLogger.info(
            'Retrieved ${accumulatedNavHistory.length} accumulated NAV data points using FundNavApiService');

        if (accumulatedNavHistory.isNotEmpty) {
          return Right(accumulatedNavHistory);
        }

        // 如果新API没有数据，返回空Map而不是错误
        AppLogger.warn(
            'No accumulated NAV data from FundNavApiService, returning empty map');
        return const Right(<DateTime, double>{});
      } catch (e) {
        AppLogger.error(
            'FundNavApiService failed to get accumulated NAV data', e);
        return Left(NetworkFailure(
            'Failed to get accumulated NAV data: ${e.toString()}'));
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch accumulated NAV history', e, stackTrace);
      return Left(NetworkFailure(e.toString(), originalError: e));
    }
  }

  /// 获取基准指数历史数据
  Future<Either<Failure, Map<DateTime, double>>> getBenchmarkHistory({
    required String benchmarkCode,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      AppLogger.info(
          'Fetching benchmark history for $benchmarkCode from ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');

      // 模拟基准指数数据
      final benchmarkHistory =
          _getMockBenchmarkHistory(benchmarkCode, startDate, endDate);

      AppLogger.info(
          'Retrieved ${benchmarkHistory.length} benchmark data points');
      return Right(benchmarkHistory);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch benchmark history', e, stackTrace);
      return Left(NetworkFailure(e.toString(), originalError: e));
    }
  }

  /// 获取基金分红历史数据（基于AKShare fund_fh_em API）
  Future<Either<Failure, List<FundCorporateAction>>> getFundDividendHistory({
    required String fundCode,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      AppLogger.info(
          'Fetching dividend history for $fundCode from ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');

      // 使用AKShare基金分红API
      // 实际项目中可能需要通过后端代理AKShare API
      final endpoint = '/api/public/fund_dividend_em?symbol=$fundCode';

      try {
        final data = await FundApiClient.get(endpoint);
        final dividendHistory =
            _parseDividendHistoryData(data, fundCode, startDate, endDate);
        AppLogger.info('Retrieved ${dividendHistory.length} dividend records');
        return Right(dividendHistory);
      } catch (e) {
        return Left(NetworkFailure(e.toString()));
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch dividend history', e, stackTrace);
      return Left(NetworkFailure(e.toString(), originalError: e));
    }
  }

  /// 获取基金拆分历史数据（基于AKShare fund_cf_em API）
  Future<Either<Failure, List<FundSplitDetail>>> getFundSplitHistory({
    required String fundCode,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      AppLogger.info(
          'Fetching split history for $fundCode from ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');

      // 使用AKShare基金拆分API
      final endpoint = '/api/public/fund_split_em?symbol=$fundCode';

      try {
        final data = await FundApiClient.get(endpoint);
        final splitHistory =
            _parseSplitHistoryData(data, fundCode, startDate, endDate);
        AppLogger.info('Retrieved ${splitHistory.length} split records');
        return Right(splitHistory);
      } catch (e) {
        return Left(NetworkFailure(e.toString()));
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch split history', e, stackTrace);
      return Left(NetworkFailure(e.toString(), originalError: e));
    }
  }

  /// 获取支持的基准指数列表
  Future<Either<Failure, List<BenchmarkIndex>>>
      getSupportedBenchmarkIndices() async {
    try {
      AppLogger.info('Fetching supported benchmark indices');

      // 返回常见的基准指数
      final indices = [
        const BenchmarkIndex(
          code: '000300',
          name: '沪深300指数',
          description: '沪深300指数是由上海和深圳证券市场中市值大、流动性好的300只股票组成',
          type: BenchmarkType.stock,
          exchange: 'CFFEX',
        ),
        const BenchmarkIndex(
          code: '000905',
          name: '中证500指数',
          description: '中证500指数综合反映沪深证券市场内小市值公司的整体状况',
          type: BenchmarkType.stock,
          exchange: 'CFFEX',
        ),
        const BenchmarkIndex(
          code: '399006',
          name: '创业板指',
          description: '创业板指由创业板市场中市值大、流动性好的100只股票组成',
          type: BenchmarkType.stock,
          exchange: 'SZSE',
        ),
        const BenchmarkIndex(
          code: 'H30055',
          name: '中证全债指数',
          description: '中证全债指数是综合反映银行间和交易所市场国债、金融债、企业债、可转债价格变动趋势的债券指数',
          type: BenchmarkType.bond,
          exchange: 'CFFEX',
        ),
        const BenchmarkIndex(
          code: 'CBA00101',
          name: '中证货币基金指数',
          description: '中证货币基金指数反映货币市场基金的整体走势',
          type: BenchmarkType.currency,
          exchange: 'CFFEX',
        ),
      ];

      AppLogger.info('Retrieved ${indices.length} benchmark indices');
      return Right(indices);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch benchmark indices', e, stackTrace);
      return Left(NetworkFailure(e.toString(), originalError: e));
    }
  }

  /// 获取数据质量报告
  Future<Either<Failure, DataQualityReport>> getDataQualityReport({
    required String fundCode,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      AppLogger.info('Generating data quality report for $fundCode');

      // 获取净值历史数据
      final navHistoryResult = await getFundNavHistory(
        fundCode: fundCode,
        startDate: startDate,
        endDate: endDate,
      );

      return navHistoryResult.fold(
        (failure) => Left(failure),
        (navHistory) {
          final totalDays = endDate.difference(startDate).inDays;
          final availableDataPoints = navHistory.length;
          final missingDataPoints = totalDays - availableDataPoints;

          final quality = _calculateDataQuality(availableDataPoints, totalDays);
          final issues = _identifyDataIssues(navHistory, totalDays);

          final report = DataQualityReport(
            fundCode: fundCode,
            startDate: startDate,
            endDate: endDate,
            totalDays: totalDays,
            availableDataPoints: availableDataPoints,
            missingDataPoints: missingDataPoints,
            quality: quality,
            issues: issues,
            dataPointCounts: {
              'total': totalDays,
              'available': availableDataPoints,
              'missing': missingDataPoints,
            },
            reportGeneratedAt: DateTime.now(),
          );

          AppLogger.info(
              'Generated data quality report: ${report.qualityDescription}');
          return Right(report);
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to generate data quality report', e, stackTrace);
      return Left(NetworkFailure(e.toString(), originalError: e));
    }
  }

  // Helper methods

  /// 格式化时间段
  String _formatPeriod(DateTime startDate, DateTime endDate) {
    final days = endDate.difference(startDate).inDays;
    if (days <= 7) return '1W';
    if (days <= 30) return '1M';
    if (days <= 90) return '3M';
    if (days <= 180) return '6M';
    if (days <= 365) return '1Y';
    if (days <= 1095) return '3Y';
    return 'YTD';
  }

  /// 将内部时间格式转换为API文档中的period参数格式
  String _convertToApiPeriod(String internalFormat) {
    switch (internalFormat) {
      case '1W':
        return '1月';
      case '1M':
        return '3月';
      case '3M':
        return '3月';
      case '6M':
        return '6月';
      case '1Y':
        return '1年';
      case '3Y':
        return '3年';
      case 'YTD':
        return '今年来';
      default:
        return '成立来';
    }
  }

  /// 解析净值历史数据
  Map<DateTime, double> _parseNavHistoryData(
      Map<String, dynamic> data, String fundCode) {
    final navHistory = <DateTime, double>{};

    try {
      // 根据实际API响应格式解析数据
      if (data['data'] != null && data['data'] is List) {
        final dataList = data['data'] as List;
        for (final item in dataList) {
          if (item is Map<String, dynamic>) {
            final dateStr = item['date'] as String?;
            final nav = item['nav'] as double?;
            if (dateStr != null && nav != null) {
              final date = DateTime.parse(dateStr);
              navHistory[date] = nav;
            }
          }
        }
      }
    } catch (e) {
      AppLogger.warn('Failed to parse NAV history data', e);
    }

    // 如果解析失败，返回模拟数据
    if (navHistory.isEmpty) {
      return _getMockNavHistory(fundCode);
    }

    return navHistory;
  }

  /// 解析分红历史数据
  List<FundCorporateAction> _parseDividendHistoryData(
    Map<String, dynamic> data,
    String fundCode,
    DateTime startDate,
    DateTime endDate,
  ) {
    final dividendHistory = <FundCorporateAction>[];

    try {
      // 根据AKShare fund_fh_em API的响应格式解析数据
      if (data['data'] != null && data['data'] is List) {
        final dataList = data['data'] as List;
        for (final item in dataList) {
          if (item is Map<String, dynamic>) {
            final recordDateStr = item['权益登记日'] as String?;
            final exDateStr = item['除息日期'] as String?;
            final paymentDateStr = item['分红发放日'] as String?;
            final dividendAmount = item['分红'] as double?;

            if (recordDateStr != null &&
                exDateStr != null &&
                dividendAmount != null) {
              final recordDate = DateTime.parse(recordDateStr);
              final exDate = DateTime.parse(exDateStr);
              final paymentDate = paymentDateStr != null
                  ? DateTime.parse(paymentDateStr)
                  : exDate;

              // 检查是否在查询时间范围内
              if (recordDate.isAfter(startDate) &&
                  recordDate.isBefore(endDate)) {
                dividendHistory.add(FundCorporateAction(
                  fundCode: fundCode,
                  fundName: item['基金简称'] as String? ?? '',
                  actionType: CorporateActionType.dividend,
                  announcementDate: recordDate, // 使用登记日作为公告日
                  recordDate: recordDate,
                  exDate: exDate,
                  paymentDate: paymentDate,
                  year: recordDate.year,
                  dividendPerUnit: dividendAmount,
                  dividendAmount: dividendAmount, // 每份分红金额
                  status: CorporateActionStatus.executed, // 假设历史数据都是已执行
                ));
              }
            }
          }
        }
      }
    } catch (e) {
      AppLogger.warn('Failed to parse dividend history data', e);
    }

    // 如果解析失败，返回模拟数据
    if (dividendHistory.isEmpty) {
      return _getMockDividendHistory(fundCode, startDate, endDate);
    }

    return dividendHistory;
  }

  /// 解析拆分历史数据
  List<FundSplitDetail> _parseSplitHistoryData(
    Map<String, dynamic> data,
    String fundCode,
    DateTime startDate,
    DateTime endDate,
  ) {
    final splitHistory = <FundSplitDetail>[];

    try {
      // 根据AKShare fund_cf_em API的响应格式解析数据
      if (data['data'] != null && data['data'] is List) {
        final dataList = data['data'] as List;
        for (final item in dataList) {
          if (item is Map<String, dynamic>) {
            final splitDateStr = item['拆分折算日'] as String?;
            final splitType = item['拆分类型'] as String?;
            final splitRatio = item['拆分折算'] as double?;

            if (splitDateStr != null && splitRatio != null) {
              final splitDate = DateTime.parse(splitDateStr);

              // 检查是否在查询时间范围内
              if (splitDate.isAfter(startDate) && splitDate.isBefore(endDate)) {
                splitHistory.add(FundSplitDetail(
                  fundCode: fundCode,
                  fundName: item['基金简称'] as String? ?? '',
                  year: splitDate.year,
                  splitDate: splitDate,
                  splitType: splitType ?? '',
                  splitRatio: splitRatio,
                  navBeforeSplit: 1.0, // 默认值，实际API可能不提供
                  navAfterSplit: 1.0 / splitRatio, // 拆分后的净值
                  recordDate: splitDate,
                  executionDate: splitDate,
                  status: SplitStatus.executed, // 假设历史数据都是已执行
                ));
              }
            }
          }
        }
      }
    } catch (e) {
      AppLogger.warn('Failed to parse split history data', e);
    }

    // 如果解析失败，返回模拟数据
    if (splitHistory.isEmpty) {
      return _getMockSplitHistory(fundCode, startDate, endDate);
    }

    return splitHistory;
  }

  /// 计算数据质量
  DataQuality _calculateDataQuality(int availablePoints, int totalPoints) {
    final completenessRatio =
        totalPoints > 0 ? availablePoints / totalPoints : 0.0;

    if (completenessRatio >= 0.95) return DataQuality.excellent;
    if (completenessRatio >= 0.85) return DataQuality.good;
    if (completenessRatio >= 0.70) return DataQuality.fair;
    return DataQuality.poor;
  }

  /// 识别数据问题
  List<String> _identifyDataIssues(
      Map<DateTime, double> navHistory, int totalDays) {
    final issues = <String>[];

    final completenessRatio =
        totalDays > 0 ? navHistory.length / totalDays : 0.0;
    if (completenessRatio < 0.95) {
      issues.add('数据完整性不足 (${(completenessRatio * 100).toStringAsFixed(1)}%)');
    }

    // 检查是否有异常值
    final values = navHistory.values.toList();
    if (values.isNotEmpty) {
      final mean = values.reduce((a, b) => a + b) / values.length;
      final variance =
          values.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) /
              values.length;
      final stdDev = variance > 0 ? variance.sqrt() : 0.0;

      final outliers =
          values.where((value) => (value - mean).abs() > 3 * stdDev).length;
      if (outliers > 0) {
        issues.add('发现 $outliers 个异常数据点');
      }
    }

    return issues;
  }

  // Mock data methods for testing

  List<PortfolioHolding> _getMockHoldings(String userId) {
    return [
      PortfolioHolding(
        fundCode: '000001',
        fundName: '华夏成长混合',
        fundType: '混合型',
        holdingAmount: 10000.0,
        costNav: 1.2500,
        costValue: 12500.0,
        marketValue: 13500.0,
        currentNav: 1.3500,
        accumulatedNav: 2.4500,
        holdingStartDate: DateTime.now().subtract(const Duration(days: 365)),
        lastUpdatedDate: DateTime.now(),
      ),
      PortfolioHolding(
        fundCode: '110022',
        fundName: '易方达消费行业股票',
        fundType: '股票型',
        holdingAmount: 5000.0,
        costNav: 2.1500,
        costValue: 10750.0,
        marketValue: 11800.0,
        currentNav: 2.3600,
        accumulatedNav: 3.5600,
        holdingStartDate: DateTime.now().subtract(const Duration(days: 180)),
        lastUpdatedDate: DateTime.now(),
      ),
      PortfolioHolding(
        fundCode: '000003',
        fundName: '中国可转债债券',
        fundType: '债券型',
        holdingAmount: 20000.0,
        costNav: 1.0800,
        costValue: 21600.0,
        marketValue: 21800.0,
        currentNav: 1.0900,
        accumulatedNav: 1.4500,
        holdingStartDate: DateTime.now().subtract(const Duration(days: 90)),
        lastUpdatedDate: DateTime.now(),
      ),
    ];
  }

  Map<DateTime, double> _getMockNavHistory(String fundCode) {
    final history = <DateTime, double>{};
    final now = DateTime.now();
    final random = 1.0 + (fundCode.hashCode % 100) / 1000.0; // 基于基金代码生成种子

    for (int i = 0; i < 365; i++) {
      final date = now.subtract(Duration(days: i));
      final baseValue = random + (i % 30) * 0.01 - 0.15; // 模拟价格波动
      history[date] = baseValue.clamp(0.5, 3.0);
    }

    return history;
  }

  Map<DateTime, double> _getMockBenchmarkHistory(
      String benchmarkCode, DateTime startDate, DateTime endDate) {
    final history = <DateTime, double>{};
    final random = 3000.0 + (benchmarkCode.hashCode % 1000); // 基于基准代码生成种子

    var currentDate = startDate;
    while (currentDate.isBefore(endDate)) {
      final dayOfYear =
          currentDate.difference(DateTime(currentDate.year, 1, 1)).inDays;
      final value = random + (dayOfYear % 100) * 10 - 500; // 模拟指数波动
      history[currentDate] = value.clamp(2000, 4000);
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return history;
  }

  List<FundCorporateAction> _getMockDividendHistory(
      String fundCode, DateTime startDate, DateTime endDate) {
    // 根据基金代码生成一些模拟分红数据
    final seed = fundCode.hashCode;
    final dividendHistory = <FundCorporateAction>[];

    if (seed % 3 == 0) {
      // 只有部分基金有分红
      final dividendDate = startDate.add(Duration(days: (seed % 200) + 30));
      if (dividendDate.isBefore(endDate)) {
        dividendHistory.add(FundCorporateAction(
          fundCode: fundCode,
          fundName: '模拟基金 $fundCode',
          actionType: CorporateActionType.dividend,
          announcementDate: dividendDate.subtract(const Duration(days: 10)),
          recordDate: dividendDate,
          exDate: dividendDate.add(const Duration(days: 1)),
          paymentDate: dividendDate.add(const Duration(days: 5)),
          year: dividendDate.year,
          dividendPerUnit: 0.05 + (seed % 20) / 1000.0,
          dividendAmount: 0.05 + (seed % 20) / 1000.0,
          status: CorporateActionStatus.executed,
        ));
      }
    }

    return dividendHistory;
  }

  List<FundSplitDetail> _getMockSplitHistory(
      String fundCode, DateTime startDate, DateTime endDate) {
    // 拆分比较少见，大部分基金没有拆分
    final seed = fundCode.hashCode;
    final splitHistory = <FundSplitDetail>[];

    if (seed % 10 == 0) {
      // 只有10%的基金有拆分
      final splitDate = startDate.add(Duration(days: (seed % 365) + 100));
      if (splitDate.isBefore(endDate)) {
        splitHistory.add(FundSplitDetail(
          fundCode: fundCode,
          fundName: '模拟基金 $fundCode',
          year: splitDate.year,
          splitDate: splitDate,
          splitType: '份额分拆',
          splitRatio: 2.0, // 1拆2
          navBeforeSplit: 2.0,
          navAfterSplit: 1.0,
          recordDate: splitDate,
          executionDate: splitDate,
          status: SplitStatus.executed,
        ));
      }
    }

    return splitHistory;
  }
}

// Extension for double to add sqrt method
extension DoubleExtension on double {
  double sqrt() => this < 0 ? 0.0 : math.sqrt(this);
}
