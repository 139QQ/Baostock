import 'package:dartz/dartz.dart';
import '../../domain/entities/portfolio_holding.dart';
import '../../domain/entities/portfolio_profit_metrics.dart';
import '../../domain/entities/portfolio_summary.dart';
import '../../domain/entities/portfolio_profit_calculation_criteria.dart';
import '../../domain/entities/fund_corporate_action.dart';
import '../../domain/entities/fund_split_detail.dart';
import '../../domain/repositories/portfolio_profit_repository.dart';
import '../../domain/services/portfolio_profit_calculation_engine.dart';
import '../services/portfolio_profit_api_service.dart';
import '../services/portfolio_profit_cache_service.dart';
import '../../../../core/utils/logger.dart';

/// 组合收益数据仓库实现
///
/// 实现组合收益计算相关的数据访问方法
class PortfolioProfitRepositoryImpl implements PortfolioProfitRepository {
  final PortfolioProfitApiService _apiService;
  final PortfolioProfitCacheService _cacheService;
  final PortfolioProfitCalculationEngine _calculationEngine;

  /// 构造函数
  ///
  /// [_apiService] - API服务实例
  /// [_cacheService] - 缓存服务实例
  /// [_calculationEngine] - 计算引擎实例
  PortfolioProfitRepositoryImpl({
    required PortfolioProfitApiService apiService,
    required PortfolioProfitCacheService cacheService,
    required PortfolioProfitCalculationEngine calculationEngine,
  })  : _apiService = apiService,
        _cacheService = cacheService,
        _calculationEngine = calculationEngine;

  @override
  Future<Either<Failure, List<PortfolioHolding>>> getUserHoldings(
      String userId) async {
    try {
      AppLogger.debug('获取用户持仓列表: $userId');

      // 首先尝试从缓存获取
      final cacheKey = 'user_holdings_$userId';
      final cachedResult = await _cacheService.getCachedHoldings(cacheKey);

      if (cachedResult != null) {
        AppLogger.debug('从缓存获取到持仓数据');
        return Right(cachedResult);
      }

      // 从API获取数据
      final result = await _apiService.getUserHoldings(userId);

      return await result.fold(
        (failure) async => Left(failure),
        (holdings) async {
          // 缓存结果
          await _cacheService.cacheHoldings(
              cacheKey, holdings, const Duration(hours: 1));
          return Right(holdings);
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error('获取用户持仓失败', e, stackTrace);
      return Left(UnknownFailure('获取用户持仓失败: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<DateTime, double>>> getFundNavHistory({
    required String fundCode,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      AppLogger.debug(
          '获取基金净值历史: $fundCode, ${startDate.toIso8601String()} ~ ${endDate.toIso8601String()}');

      // 生成缓存键
      final cacheKey =
          'fund_nav_${fundCode}_${startDate.millisecondsSinceEpoch}_${endDate.millisecondsSinceEpoch}';

      // 尝试从缓存获取
      final cachedResult = await _cacheService.getCachedNavHistory(cacheKey);
      if (cachedResult != null) {
        AppLogger.debug('从缓存获取净值历史数据');
        return Right(cachedResult);
      }

      // 从API获取数据
      final result = await _apiService.getFundNavHistory(
        fundCode: fundCode,
        startDate: startDate,
        endDate: endDate,
      );

      return await result.fold(
        (failure) async => Left(failure),
        (navHistory) async {
          // 缓存结果
          await _cacheService.cacheNavHistory(
              cacheKey, navHistory, const Duration(hours: 2));
          return Right(navHistory);
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error('获取基金净值历史失败', e, stackTrace);
      return Left(NetworkFailure('获取基金净值历史失败: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<DateTime, double>>> getBenchmarkHistory({
    required String benchmarkCode,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      AppLogger.debug(
          '获取基准指数历史: $benchmarkCode, ${startDate.toIso8601String()} ~ ${endDate.toIso8601String()}');

      // 生成缓存键
      final cacheKey =
          'benchmark_${benchmarkCode}_${startDate.millisecondsSinceEpoch}_${endDate.millisecondsSinceEpoch}';

      // 尝试从缓存获取
      final cachedResult =
          await _cacheService.getCachedBenchmarkHistory(cacheKey);
      if (cachedResult != null) {
        AppLogger.debug('从缓存获取基准指数历史数据');
        return Right(cachedResult);
      }

      // 从API获取数据
      final result = await _apiService.getBenchmarkHistory(
        benchmarkCode: benchmarkCode,
        startDate: startDate,
        endDate: endDate,
      );

      return await result.fold(
        (failure) async => Left(failure),
        (benchmarkHistory) async {
          // 缓存结果
          await _cacheService.cacheBenchmarkHistory(
              cacheKey, benchmarkHistory, const Duration(hours: 2));
          return Right(benchmarkHistory);
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error('获取基准指数历史失败', e, stackTrace);
      return Left(NetworkFailure('获取基准指数历史失败: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<FundCorporateAction>>> getFundDividendHistory({
    required String fundCode,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      AppLogger.debug(
          '获取基金分红历史: $fundCode, ${startDate.toIso8601String()} ~ ${endDate.toIso8601String()}');

      // 生成缓存键
      final cacheKey =
          'dividend_${fundCode}_${startDate.millisecondsSinceEpoch}_${endDate.millisecondsSinceEpoch}';

      // 尝试从缓存获取
      final cachedResult =
          await _cacheService.getCachedDividendHistory(cacheKey);
      if (cachedResult != null) {
        AppLogger.debug('从缓存获取分红历史数据');
        return Right(cachedResult);
      }

      // 从API获取数据
      final result = await _apiService.getFundDividendHistory(
        fundCode: fundCode,
        startDate: startDate,
        endDate: endDate,
      );

      return await result.fold(
        (failure) async => Left(failure),
        (dividendHistory) async {
          // 缓存结果
          await _cacheService.cacheDividendHistory(
              cacheKey, dividendHistory, const Duration(hours: 24));
          return Right(dividendHistory);
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error('获取基金分红历史失败', e, stackTrace);
      return Left(NetworkFailure('获取基金分红历史失败: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<FundSplitDetail>>> getFundSplitHistory({
    required String fundCode,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      AppLogger.debug(
          '获取基金拆分历史: $fundCode, ${startDate.toIso8601String()} ~ ${endDate.toIso8601String()}');

      // 生成缓存键
      final cacheKey =
          'split_${fundCode}_${startDate.millisecondsSinceEpoch}_${endDate.millisecondsSinceEpoch}';

      // 尝试从缓存获取
      final cachedResult = await _cacheService.getCachedSplitHistory(cacheKey);
      if (cachedResult != null) {
        AppLogger.debug('从缓存获取拆分历史数据');
        return Right(cachedResult);
      }

      // 从API获取数据
      final result = await _apiService.getFundSplitHistory(
        fundCode: fundCode,
        startDate: startDate,
        endDate: endDate,
      );

      return await result.fold(
        (failure) async => Left(failure),
        (splitHistory) async {
          // 缓存结果
          await _cacheService.cacheSplitHistory(
              cacheKey, splitHistory, const Duration(hours: 24));
          return Right(splitHistory);
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error('获取基金拆分历史失败', e, stackTrace);
      return Left(NetworkFailure('获取基金拆分历史失败: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, PortfolioProfitMetrics>> calculateFundProfitMetrics({
    required PortfolioHolding holding,
    required PortfolioProfitCalculationCriteria criteria,
  }) async {
    try {
      AppLogger.debug('计算基金收益指标: ${holding.fundCode}');

      // 生成缓存键
      final cacheKey = _calculationEngine.generateCacheKey(holding, criteria);

      // 尝试从缓存获取计算结果
      final cachedResult = await getCachedProfitMetrics(cacheKey);
      if (cachedResult.isRight()) {
        final cachedMetrics = cachedResult.getOrElse(() => null);
        if (cachedMetrics != null) {
          AppLogger.debug('从缓存获取收益指标');
          return Right(cachedMetrics);
        }
      }

      // 获取必要的数据
      final navHistoryResult = await getFundNavHistory(
        fundCode: holding.fundCode,
        startDate: criteria.startDate,
        endDate: criteria.endDate,
      );

      if (navHistoryResult.isLeft()) {
        return Left(navHistoryResult
            .swap()
            .getOrElse(() => const NetworkFailure('获取净值历史失败')));
      }

      final navHistory = navHistoryResult.getOrElse(() => {});

      // 获取基准数据（如果需要）
      Map<DateTime, double>? benchmarkHistory;
      if (criteria.benchmarkCode != null) {
        final benchmarkResult = await getBenchmarkHistory(
          benchmarkCode: criteria.benchmarkCode!,
          startDate: criteria.startDate,
          endDate: criteria.endDate,
        );

        if (benchmarkResult.isRight()) {
          benchmarkHistory = benchmarkResult.getOrElse(() => {});
        }
      }

      // 获取分红数据（如果需要）
      List<FundCorporateAction>? dividendHistory;
      if (criteria.includeDividendReinvestment) {
        final dividendResult = await getFundDividendHistory(
          fundCode: holding.fundCode,
          startDate: criteria.startDate,
          endDate: criteria.endDate,
        );

        if (dividendResult.isRight()) {
          dividendHistory = dividendResult.getOrElse(() => []);
        }
      }

      // 使用计算引擎计算收益指标
      final metricsResult = await _calculationEngine.calculateFundMetrics(
        holding: holding,
        navHistory: navHistory,
        benchmarkHistory: benchmarkHistory,
        dividendHistory: dividendHistory,
        criteria: criteria,
      );

      return metricsResult.fold(
        (failure) => Left(failure),
        (metrics) async {
          // 缓存计算结果
          final cacheResult = await cacheProfitMetrics(
            cacheKey: cacheKey,
            metrics: metrics,
            expiryDuration: const Duration(hours: 1),
          );

          // 如果缓存失败，记录警告但不影响主流程
          if (cacheResult.isLeft()) {
            final failure = cacheResult
                .swap()
                .getOrElse(() => const CacheFailure('未知缓存错误'));
            AppLogger.warn('缓存收益指标失败: $failure');
          }

          return Right(metrics);
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error('计算基金收益指标失败', e, stackTrace);
      return Left(CalculationFailure('计算基金收益指标失败: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, PortfolioSummary>> calculatePortfolioSummary({
    required List<PortfolioHolding> holdings,
    required PortfolioProfitCalculationCriteria criteria,
  }) async {
    try {
      AppLogger.debug('计算组合汇总收益: ${holdings.length} 只基金');

      if (holdings.isEmpty) {
        return Left(const ValidationFailure('持仓列表不能为空'));
      }

      // 计算各个基金的收益指标
      final metricsResult = await calculateBatchProfitMetrics(
        holdings: holdings,
        criteria: criteria,
      );

      if (metricsResult.isLeft()) {
        return Left(metricsResult
            .swap()
            .getOrElse(() => const CalculationFailure('计算各基金收益指标失败')));
      }

      final metricsMap = metricsResult.getOrElse(() => {});

      // 使用计算引擎汇总组合收益
      final summaryResult = await _calculationEngine.calculatePortfolioSummary(
        holdings: holdings,
        allMetrics: metricsMap,
        criteria: criteria,
      );

      return Right(summaryResult);
    } catch (e, stackTrace) {
      AppLogger.error('计算组合汇总收益失败', e, stackTrace);
      return Left(CalculationFailure('计算组合汇总收益失败: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, PortfolioProfitMetrics>>>
      calculateBatchProfitMetrics({
    required List<PortfolioHolding> holdings,
    required PortfolioProfitCalculationCriteria criteria,
  }) async {
    try {
      AppLogger.debug('批量计算基金收益指标: ${holdings.length} 只基金');

      if (holdings.isEmpty) {
        return const Right({});
      }

      final Map<String, PortfolioProfitMetrics> metricsMap = {};
      final List<Future<void>> calculations = [];

      // 并行计算各基金的收益指标
      for (final holding in holdings) {
        final future = calculateFundProfitMetrics(
          holding: holding,
          criteria: criteria,
        ).then((result) {
          result.fold(
            (failure) =>
                AppLogger.warn('计算基金 ${holding.fundCode} 收益失败: $failure'),
            (metrics) => metricsMap[holding.fundCode] = metrics,
          );
        });

        calculations.add(future);
      }

      // 等待所有计算完成
      await Future.wait(calculations);

      return Right(metricsMap);
    } catch (e, stackTrace) {
      AppLogger.error('批量计算基金收益指标失败', e, stackTrace);
      return Left(CalculationFailure('批量计算基金收益指标失败: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, PortfolioProfitMetrics>>>
      calculateMultiDimensionalComparison({
    required List<PortfolioHolding> holdings,
    required List<CalculationFrequency> frequencies,
    PortfolioProfitCalculationCriteria? baseCriteria,
  }) async {
    try {
      AppLogger.debug(
          '计算多维度收益对比: ${holdings.length} 只基金, ${frequencies.length} 种频率');

      baseCriteria ??= PortfolioProfitCalculationCriteria.basic();

      final Map<String, PortfolioProfitMetrics> comparisonResults = {};

      for (final frequency in frequencies) {
        // 为每个频率创建计算标准
        final criteria = baseCriteria.copyWith(
          calculationId: '${baseCriteria.calculationId}_${frequency.name}',
          frequency: frequency,
        );

        // 批量计算该频率下的收益指标
        final result = await calculateBatchProfitMetrics(
          holdings: holdings,
          criteria: criteria,
        );

        if (result.isRight()) {
          final metrics = result.getOrElse(() => {});

          // 将结果添加到对比结果中
          for (final entry in metrics.entries) {
            final key = '${entry.key}_${frequency.name}';
            comparisonResults[key] = entry.value;
          }
        } else {
          AppLogger.warn('计算频率 $frequency 下的收益指标失败');
        }
      }

      return Right(comparisonResults);
    } catch (e, stackTrace) {
      AppLogger.error('计算多维度收益对比失败', e, stackTrace);
      return Left(CalculationFailure('计算多维度收益对比失败: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, PortfolioProfitMetrics?>> getCachedProfitMetrics(
      String cacheKey) async {
    try {
      final metrics = await _cacheService.getCachedProfitMetrics(cacheKey);
      return Right(metrics);
    } catch (e, stackTrace) {
      AppLogger.error('获取缓存的收益指标失败', e, stackTrace);
      return Left(CacheFailure('获取缓存的收益指标失败: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> cacheProfitMetrics({
    required String cacheKey,
    required PortfolioProfitMetrics metrics,
    required Duration expiryDuration,
  }) async {
    try {
      await _cacheService.cacheProfitMetrics(
        cacheKey: cacheKey,
        metrics: metrics,
        expiryDuration: expiryDuration,
      );
      return const Right(null);
    } catch (e, stackTrace) {
      AppLogger.error('缓存收益指标失败', e, stackTrace);
      return Left(CacheFailure('缓存收益指标失败: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> clearExpiredCache() async {
    try {
      await _cacheService.clearExpiredCache();
      return const Right(null);
    } catch (e, stackTrace) {
      AppLogger.error('清除过期缓存失败', e, stackTrace);
      return Left(CacheFailure('清除过期缓存失败: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> validateCalculationCriteria(
      PortfolioProfitCalculationCriteria criteria) async {
    try {
      final isValid = criteria.isValid() &&
          await _calculationEngine.validateCriteria(criteria);
      return Right(isValid);
    } catch (e, stackTrace) {
      AppLogger.error('验证计算标准失败', e, stackTrace);
      return Left(ValidationFailure('验证计算标准失败: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<BenchmarkIndex>>>
      getSupportedBenchmarkIndices() async {
    try {
      AppLogger.debug('获取支持的基准指数列表');

      // 尝试从缓存获取
      const cacheKey = 'supported_benchmarks';
      final cachedResult =
          await _cacheService.getCachedBenchmarkIndices(cacheKey);
      if (cachedResult != null) {
        AppLogger.debug('从缓存获取基准指数列表');
        return Right(cachedResult);
      }

      // 从API获取数据
      final result = await _apiService.getSupportedBenchmarkIndices();

      return result.fold(
        (failure) => Left(failure),
        (benchmarks) async {
          // 缓存结果
          await _cacheService.cacheBenchmarkIndices(cacheKey, benchmarks);
          return Right(benchmarks);
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error('获取支持的基准指数列表失败', e, stackTrace);
      return Left(NetworkFailure('获取支持的基准指数列表失败: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, DataQualityReport>> getDataQualityReport({
    required String fundCode,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      AppLogger.debug('获取数据质量报告: $fundCode');

      // 生成缓存键
      final cacheKey =
          'data_quality_${fundCode}_${startDate.millisecondsSinceEpoch}_${endDate.millisecondsSinceEpoch}';

      // 尝试从缓存获取
      final cachedResult =
          await _cacheService.getCachedDataQualityReport(cacheKey);
      if (cachedResult != null) {
        AppLogger.debug('从缓存获取数据质量报告');
        return Right(cachedResult);
      }

      // 获取净值数据进行质量分析
      final navHistoryResult = await getFundNavHistory(
        fundCode: fundCode,
        startDate: startDate,
        endDate: endDate,
      );

      if (navHistoryResult.isLeft()) {
        return Left(navHistoryResult
            .swap()
            .getOrElse(() => const NetworkFailure('获取净值历史数据失败')));
      }

      final navHistory = navHistoryResult.getOrElse(() => {});

      // 使用计算引擎分析数据质量
      final qualityReportResult = await _calculationEngine.analyzeDataQuality(
        fundCode: fundCode,
        navHistory: navHistory,
        startDate: startDate,
        endDate: endDate,
      );

      return qualityReportResult.fold(
        (failure) => Left(failure),
        (report) async {
          // 缓存报告
          await _cacheService.cacheDataQualityReport(cacheKey, report);
          return Right(report);
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error('获取数据质量报告失败', e, stackTrace);
      return Left(DataQualityFailure('获取数据质量报告失败: ${e.toString()}'));
    }
  }
}
