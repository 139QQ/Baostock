import '../../domain/entities/multi_dimensional_comparison_criteria.dart';
import '../../domain/entities/comparison_result.dart';
import '../../domain/entities/fund_ranking.dart';
import '../../domain/repositories/fund_comparison_repository.dart';
import '../../domain/repositories/fund_repository.dart';
import '../services/fund_comparison_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/cache/interfaces/cache_service.dart';

/// 基金对比Repository实现类
class FundComparisonRepositoryImpl implements FundComparisonRepository {
  static const String _tag = 'FundComparisonRepositoryImpl';
  static const String _cachePrefix = 'fund_comparison_';
  static const Duration _cacheExpiration = Duration(hours: 1);

  final FundRepository _fundRepository;
  final FundComparisonService _comparisonService;
  final CacheService _cacheService;

  FundComparisonRepositoryImpl({
    required FundRepository fundRepository,
    required FundComparisonService comparisonService,
    CacheService? cacheService,
  })  : _fundRepository = fundRepository,
        _comparisonService = comparisonService,
        _cacheService = cacheService ??
            (throw ArgumentError(
                'CacheService is required for FundComparisonRepositoryImpl'));

  @override
  Future<ComparisonResult> getMultiDimensionalComparison(
    MultiDimensionalComparisonCriteria criteria, {
    bool forceRefresh = false,
  }) async {
    try {
      AppLogger.info(_tag, '获取多维度对比结果: ${criteria.fundCodes}');

      // 检查缓存
      if (!forceRefresh) {
        final cachedResult = await getCachedComparisonResult(criteria);
        if (cachedResult != null) {
          AppLogger.info(_tag, '从缓存获取对比结果');
          return cachedResult;
        }
      }

      // 尝试获取实时数据
      ComparisonResult result;
      try {
        AppLogger.info(_tag, '尝试获取实时对比数据');
        result = await _comparisonService.getRealtimeComparisonData(criteria);
      } catch (e) {
        AppLogger.warn(_tag, '获取实时数据失败，使用本地数据: $e');

        // 如果实时数据获取失败，回退到本地数据
        final fundRankings = await _fundRepository.getFundsForComparison(
          criteria.fundCodes,
          criteria.periods,
        );

        if (fundRankings.isEmpty) {
          throw Exception('未找到基金数据');
        }

        // 计算对比结果
        result = await _comparisonService.calculateComparison(
          fundRankings,
          criteria,
        );
      }

      // 缓存结果
      await cacheComparisonResult(result);

      AppLogger.info(_tag, '对比计算完成');
      return result;
    } catch (e) {
      AppLogger.error(_tag, '获取对比结果失败: $e');
      return ComparisonResult(
        criteria: criteria,
        fundData: const [],
        statistics: ComparisonStatistics(
          averageReturn: 0.0,
          maxReturn: 0.0,
          minReturn: 0.0,
          returnStdDev: 0.0,
          averageVolatility: 0.0,
          maxVolatility: 0.0,
          minVolatility: 0.0,
          averageSharpeRatio: 0.0,
          correlationMatrix: const {},
          updatedAt: DateTime.now(),
        ),
        calculatedAt: DateTime.now(),
        hasError: true,
        errorMessage: e.toString(),
      );
    }
  }

  @override
  Future<Map<RankingPeriod, double>> getFundHistoricalReturns(
    String fundCode,
    List<RankingPeriod> periods,
  ) async {
    try {
      AppLogger.info(_tag, '获取基金历史收益率: $fundCode');

      final cacheKey =
          '${_cachePrefix}returns_${fundCode}_${periods.map((p) => p.name).join('_')}';

      // 检查缓存
      final cachedData = await _cacheService.get(cacheKey);
      if (cachedData != null) {
        final Map<String, dynamic> cachedMap =
            Map<String, dynamic>.from(cachedData);
        return cachedMap.map((key, value) => MapEntry(
              RankingPeriod.values.firstWhere((p) => p.name == key),
              (value as num).toDouble(),
            ));
      }

      // 从API获取数据
      final fundRankings =
          await _fundRepository.getFundsForComparison([fundCode], periods);
      final returns = <RankingPeriod, double>{};

      for (final ranking in fundRankings) {
        if (ranking.fundCode == fundCode) {
          returns[ranking.rankingPeriod] =
              _getReturnForPeriod(ranking, ranking.rankingPeriod);
        }
      }

      // 缓存结果
      await _cacheService.put(
          cacheKey, returns.map((key, value) => MapEntry(key.name, value)),
          expiration: _cacheExpiration);

      return returns;
    } catch (e) {
      AppLogger.error(_tag, '获取基金历史收益率失败: $e');
      return {};
    }
  }

  @override
  Future<Map<String, Map<String, double>>> calculateCorrelationMatrix(
    List<String> fundCodes,
    RankingPeriod period,
  ) async {
    try {
      AppLogger.info(_tag, '计算相关性矩阵: ${fundCodes.length}只基金');

      final cacheKey =
          '${_cachePrefix}correlation_${fundCodes.join('_')}_${period.name}';

      // 检查缓存
      final cachedData = await _cacheService.get(cacheKey);
      if (cachedData != null) {
        return Map<String, Map<String, double>>.from(cachedData);
      }

      // 获取基金数据
      final fundRankings =
          await _fundRepository.getFundsForComparison(fundCodes, [period]);

      // 构建收益率矩阵
      final returnsMatrix = <String, List<double>>{};
      for (final fundCode in fundCodes) {
        returnsMatrix[fundCode] = [];
        final fundData =
            fundRankings.where((r) => r.fundCode == fundCode).toList();
        if (fundData.isNotEmpty) {
          returnsMatrix[fundCode]!
              .add(_getReturnForPeriod(fundData.first, period));
        }
      }

      // 计算相关性矩阵
      final correlationMatrix = <String, Map<String, double>>{};
      for (final fund1 in fundCodes) {
        correlationMatrix[fund1] = {};
        for (final fund2 in fundCodes) {
          if (fund1 == fund2) {
            correlationMatrix[fund1]![fund2] = 1.0;
          } else {
            correlationMatrix[fund1]![fund2] = _calculateCorrelation(
              returnsMatrix[fund1] ?? [],
              returnsMatrix[fund2] ?? [],
            );
          }
        }
      }

      // 缓存结果
      await _cacheService.put(cacheKey, correlationMatrix,
          expiration: _cacheExpiration);

      return correlationMatrix;
    } catch (e) {
      AppLogger.error(_tag, '计算相关性矩阵失败: $e');
      return {};
    }
  }

  @override
  Future<double> getCategoryAverageReturn(
    String fundType,
    RankingPeriod period,
  ) async {
    try {
      AppLogger.info(_tag, '获取同类平均收益率: $fundType');

      final cacheKey = '${_cachePrefix}category_avg_${fundType}_${period.name}';

      // 检查缓存
      final cachedData = await _cacheService.get(cacheKey);
      if (cachedData != null) {
        return (cachedData as num).toDouble();
      }

      // 这里应该调用实际的API获取同类平均数据
      // 暂时使用模拟数据
      final averageReturn = await _getCategoryAverageFromAPI(fundType, period);

      // 缓存结果
      await _cacheService.put(cacheKey, averageReturn,
          expiration: _cacheExpiration);

      return averageReturn;
    } catch (e) {
      AppLogger.error(_tag, '获取同类平均收益率失败: $e');
      return 0.0;
    }
  }

  @override
  Future<double> getBenchmarkReturn(
    String benchmarkCode,
    RankingPeriod period,
  ) async {
    try {
      AppLogger.info(_tag, '获取基准收益率: $benchmarkCode');

      final cacheKey =
          '${_cachePrefix}benchmark_${benchmarkCode}_${period.name}';

      // 检查缓存
      final cachedData = await _cacheService.get(cacheKey);
      if (cachedData != null) {
        return (cachedData as num).toDouble();
      }

      // 这里应该调用实际的API获取基准数据
      // 暂时使用模拟数据
      final benchmarkReturn =
          await _getBenchmarkReturnFromAPI(benchmarkCode, period);

      // 缓存结果
      await _cacheService.put(cacheKey, benchmarkReturn,
          expiration: _cacheExpiration);

      return benchmarkReturn;
    } catch (e) {
      AppLogger.error(_tag, '获取基准收益率失败: $e');
      return 0.0;
    }
  }

  @override
  Future<bool> saveComparisonConfiguration(
    MultiDimensionalComparisonCriteria criteria,
    String name,
  ) async {
    try {
      AppLogger.info(_tag, '保存对比配置: $name');

      final cacheKey =
          '${_cachePrefix}config_${DateTime.now().millisecondsSinceEpoch}';
      final configData = {
        'name': name,
        'criteria': criteria.toJson(),
        'createdAt': DateTime.now().toIso8601String(),
        'lastUsed': DateTime.now().toIso8601String(),
      };

      await _cacheService.put(cacheKey, configData,
          expiration: _cacheExpiration);

      AppLogger.info(_tag, '对比配置保存成功');
      return true;
    } catch (e) {
      AppLogger.error(_tag, '保存对比配置失败: $e');
      return false;
    }
  }

  @override
  Future<List<SavedComparisonConfiguration>> getSavedConfigurations() async {
    try {
      AppLogger.info(_tag, '获取保存的对比配置列表');

      // 这里应该从实际的存储中获取配置列表
      // 暂时返回空列表
      AppLogger.info(_tag, '暂无保存的配置');
      return [];
    } catch (e) {
      AppLogger.error(_tag, '获取保存的配置列表失败: $e');
      return [];
    }
  }

  @override
  Future<bool> deleteConfiguration(String configurationId) async {
    try {
      AppLogger.info(_tag, '删除对比配置: $configurationId');

      final cacheKey = '${_cachePrefix}config_$configurationId';
      await _cacheService.remove(cacheKey);

      AppLogger.info(_tag, '对比配置删除成功');
      return true;
    } catch (e) {
      AppLogger.error(_tag, '删除对比配置失败: $e');
      return false;
    }
  }

  @override
  Future<void> cacheComparisonResult(ComparisonResult result) async {
    try {
      final cacheKey = _generateCacheKey(result.criteria);
      await _cacheService.put(cacheKey, result.toJson(),
          expiration: _cacheExpiration);
      AppLogger.debug(_tag, '对比结果已缓存');
    } catch (e) {
      AppLogger.error(_tag, '缓存对比结果失败: $e');
    }
  }

  @override
  Future<ComparisonResult?> getCachedComparisonResult(
    MultiDimensionalComparisonCriteria criteria,
  ) async {
    try {
      final cacheKey = _generateCacheKey(criteria);
      final cachedData = await _cacheService.get(cacheKey);

      if (cachedData != null) {
        return ComparisonResult.fromJson(Map<String, dynamic>.from(cachedData));
      }

      return null;
    } catch (e) {
      AppLogger.error(_tag, '获取缓存对比结果失败: $e');
      return null;
    }
  }

  @override
  Future<void> clearExpiredCache() async {
    try {
      // CacheService接口没有cleanupExpired方法，使用clear清理所有缓存
      // 在实际应用中，可以考虑添加更精确的过期清理逻辑
      await _cacheService.clear();
      AppLogger.info(_tag, '缓存清理完成');
    } catch (e) {
      AppLogger.error(_tag, '清理缓存失败: $e');
    }
  }

  /// 生成缓存键
  String _generateCacheKey(MultiDimensionalComparisonCriteria criteria) {
    final fundCodesHash = criteria.fundCodes.join(',').hashCode;
    final periodsHash = criteria.periods.map((p) => p.name).join(',').hashCode;
    return '${_cachePrefix}result_${fundCodesHash}_$periodsHash';
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
        return fundRanking.return1M;
    }
  }

  /// 计算相关性
  double _calculateCorrelation(List<double> series1, List<double> series2) {
    if (series1.isEmpty ||
        series2.isEmpty ||
        series1.length != series2.length) {
      return 0.0;
    }

    final avg1 = series1.reduce((a, b) => a + b) / series1.length;
    final avg2 = series2.reduce((a, b) => a + b) / series2.length;

    double numerator = 0.0;
    double variance1 = 0.0;
    double variance2 = 0.0;

    for (int i = 0; i < series1.length; i++) {
      final diff1 = series1[i] - avg1;
      final diff2 = series2[i] - avg2;

      numerator += diff1 * diff2;
      variance1 += diff1 * diff1;
      variance2 += diff2 * diff2;
    }

    if (variance1 == 0 || variance2 == 0) return 0.0;

    return numerator / (variance1 * variance2);
  }

  /// 从API获取同类平均收益率（模拟实现）
  Future<double> _getCategoryAverageFromAPI(
      String fundType, RankingPeriod period) async {
    // 这里应该调用实际的API
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

  /// 从API获取基准收益率（模拟实现）
  Future<double> _getBenchmarkReturnFromAPI(
      String benchmarkCode, RankingPeriod period) async {
    // 这里应该调用实际的API
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
}
