import 'dart:convert';
import '../../domain/entities/portfolio_holding.dart';
import '../../domain/entities/fund_corporate_action.dart';
import '../../domain/entities/fund_split_detail.dart';
import '../../domain/entities/portfolio_profit_metrics.dart';
import '../../../../core/cache/interfaces/cache_service.dart';
import '../../../../core/utils/logger.dart';

// 占位符类型定义（待实现）
class BenchmarkIndex {
  final String code;
  final String name;

  BenchmarkIndex({required this.code, required this.name});
}

class DataQualityReport {
  final Map<String, dynamic> metrics;
  final DateTime timestamp;

  DataQualityReport({required this.metrics, required this.timestamp});
}

/// 组合收益缓存服务
///
/// 提供高性能的数据缓存功能，支持多层缓存策略
/// 已重构为使用统一缓存服务接口
class PortfolioProfitCacheService {
  // 缓存键前缀
  static const String _holdingsPrefix = 'portfolio_holdings:';
  static const String _navHistoryPrefix = 'nav_history:';
  static const String _benchmarkHistoryPrefix = 'benchmark_history:';
  static const String _dividendHistoryPrefix = 'dividend_history:';
  static const String _splitHistoryPrefix = 'split_history:';
  static const String _profitMetricsPrefix = 'profit_metrics:';
  static const String _portfolioSummaryPrefix = 'portfolio_summary:';
  static const String _benchmarkIndicesPrefix = 'benchmark_indices:';
  static const String _dataQualityReportPrefix = 'data_quality_report:';

  // 缓存服务
  final CacheService _cacheService;

  /// 构造函数
  PortfolioProfitCacheService({
    required CacheService cacheService,
  }) : _cacheService = cacheService;

  /// 默认构造函数（用于测试）
  PortfolioProfitCacheService.defaultService()
      : _cacheService = _createDefaultCacheService();

  /// 创建默认缓存服务
  static CacheService _createDefaultCacheService() {
    // 这里需要创建一个简单的内存缓存服务作为默认实现
    // 为了测试目的，我们创建一个基本的内存缓存
    return _TestCacheService();
  }

  /// 初始化缓存服务
  Future<void> initialize() async {
    try {
      // 验证统一缓存服务是否可用
      await _cacheService.get('__portfolio_cache_init_test__');
      AppLogger.info(
          'Portfolio profit cache service initialized with unified cache system');
    } catch (e) {
      AppLogger.warn(
          'Portfolio profit cache service initialization warning: $e');
      // 初始化失败不影响服务使用，只是每次都要从API获取
    }
  }

  /// 缓存用户持仓数据
  Future<void> cacheHoldings(String cacheKey, List<PortfolioHolding> holdings,
      Duration expiryDuration) async {
    try {
      final unifiedKey = '$_holdingsPrefix$cacheKey';
      final cacheItem = CacheItem<List<PortfolioHolding>>(
        data: holdings,
        timestamp: DateTime.now(),
        expiryDate: DateTime.now().add(expiryDuration),
      );

      await _cacheService.put(
        unifiedKey,
        jsonEncode(cacheItem.toJson()),
        expiration: expiryDuration,
      );
      AppLogger.debug(
          'Cached ${holdings.length} holdings to unified cache with key: $cacheKey');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to cache holdings', e, stackTrace);
    }
  }

  /// 获取缓存的用户持仓数据
  Future<List<PortfolioHolding>?> getCachedHoldings(String cacheKey) async {
    try {
      final unifiedKey = '$_holdingsPrefix$cacheKey';
      final cachedData = await _cacheService.get<String>(unifiedKey);

      if (cachedData == null) {
        return null;
      }

      // 解析JSON数据
      final jsonData = jsonDecode(cachedData) as Map<String, dynamic>;

      // 使用专门的方法处理 PortfolioHolding 列表转换
      final cacheItem = jsonData['data'] != null
          ? CacheItem<List<PortfolioHolding>>.fromJson(jsonData)
          : CacheItem.fromHoldingJson(jsonData);

      // 检查是否过期
      if (DateTime.now().isAfter(cacheItem.expiryDate)) {
        await _cacheService.remove(unifiedKey);
        AppLogger.debug('Cache expired for holdings with key: $cacheKey');
        return null;
      }

      AppLogger.debug(
          'Retrieved ${cacheItem.data.length} holdings from unified cache');
      return cacheItem.data;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get cached holdings', e, stackTrace);
      return null;
    }
  }

  /// 缓存净值历史数据
  Future<void> cacheNavHistory(String cacheKey,
      Map<DateTime, double> navHistory, Duration expiryDuration) async {
    try {
      final unifiedKey = '$_navHistoryPrefix$cacheKey';
      final cacheItem = CacheItem<Map<String, double>>(
        data: navHistory
            .map((key, value) => MapEntry(key.toIso8601String(), value)),
        timestamp: DateTime.now(),
        expiryDate: DateTime.now().add(expiryDuration),
      );

      await _cacheService.put(
        unifiedKey,
        jsonEncode(cacheItem.toJson()),
        expiration: expiryDuration,
      );
      AppLogger.debug(
          'Cached ${navHistory.length} NAV data points with key: $cacheKey');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to cache NAV history', e, stackTrace);
    }
  }

  /// 获取缓存的净值历史数据
  Future<Map<DateTime, double>?> getCachedNavHistory(String cacheKey) async {
    try {
      final unifiedKey = '$_navHistoryPrefix$cacheKey';
      final cachedData = await _cacheService.get<String>(unifiedKey);

      if (cachedData == null) {
        return null;
      }

      final jsonData = jsonDecode(cachedData) as Map<String, dynamic>;
      final cacheItem = CacheItem<Map<String, double>>.fromJson(jsonData);

      // 检查是否过期
      if (DateTime.now().isAfter(cacheItem.expiryDate)) {
        await _cacheService.remove(unifiedKey);
        AppLogger.debug('Cache expired for NAV history with key: $cacheKey');
        return null;
      }

      final navHistory = cacheItem.data
          .map((key, value) => MapEntry(DateTime.parse(key), value));
      AppLogger.debug(
          'Retrieved ${navHistory.length} NAV data points from cache');
      return navHistory;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get cached NAV history', e, stackTrace);
      return null;
    }
  }

  /// 缓存基准指数历史数据
  Future<void> cacheBenchmarkHistory(String cacheKey,
      Map<DateTime, double> benchmarkHistory, Duration expiryDuration) async {
    try {
      final unifiedKey = '$_benchmarkHistoryPrefix$cacheKey';
      final cacheItem = CacheItem<Map<String, double>>(
        data: benchmarkHistory
            .map((key, value) => MapEntry(key.toIso8601String(), value)),
        timestamp: DateTime.now(),
        expiryDate: DateTime.now().add(expiryDuration),
      );

      await _cacheService.put(
        unifiedKey,
        jsonEncode(cacheItem.toJson()),
        expiration: expiryDuration,
      );
      AppLogger.debug(
          'Cached ${benchmarkHistory.length} benchmark data points with key: $cacheKey');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to cache benchmark history', e, stackTrace);
    }
  }

  /// 获取缓存的基准指数历史数据
  Future<Map<DateTime, double>?> getCachedBenchmarkHistory(
      String cacheKey) async {
    try {
      final unifiedKey = '$_benchmarkHistoryPrefix$cacheKey';
      final cachedData = await _cacheService.get<String>(unifiedKey);

      if (cachedData == null) {
        return null;
      }

      final jsonData = jsonDecode(cachedData) as Map<String, dynamic>;
      final cacheItem = CacheItem<Map<String, double>>.fromJson(jsonData);

      // 检查是否过期
      if (DateTime.now().isAfter(cacheItem.expiryDate)) {
        await _cacheService.remove(unifiedKey);
        AppLogger.debug(
            'Cache expired for benchmark history with key: $cacheKey');
        return null;
      }

      final benchmarkHistory = cacheItem.data
          .map((key, value) => MapEntry(DateTime.parse(key), value));
      AppLogger.debug(
          'Retrieved ${benchmarkHistory.length} benchmark data points from cache');
      return benchmarkHistory;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get cached benchmark history', e, stackTrace);
      return null;
    }
  }

  /// 缓存分红历史数据
  Future<void> cacheDividendHistory(
      String cacheKey,
      List<FundCorporateAction> dividendHistory,
      Duration expiryDuration) async {
    try {
      final unifiedKey = '$_dividendHistoryPrefix$cacheKey';
      final cacheItem = CacheItem<List<Map<String, dynamic>>>(
        data: dividendHistory.map((action) => action.toJson()).toList(),
        timestamp: DateTime.now(),
        expiryDate: DateTime.now().add(expiryDuration),
      );

      await _cacheService.put(
        unifiedKey,
        jsonEncode(cacheItem.toJson()),
        expiration: expiryDuration,
      );
      AppLogger.debug(
          'Cached ${dividendHistory.length} dividend records with key: $cacheKey');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to cache dividend history', e, stackTrace);
    }
  }

  /// 获取缓存的分红历史数据
  Future<List<FundCorporateAction>?> getCachedDividendHistory(
      String cacheKey) async {
    try {
      final unifiedKey = '$_dividendHistoryPrefix$cacheKey';
      final cachedData = await _cacheService.get<String>(unifiedKey);

      if (cachedData == null) {
        return null;
      }

      final jsonData = jsonDecode(cachedData) as Map<String, dynamic>;
      final cacheItem =
          CacheItem<List<Map<String, dynamic>>>.fromJson(jsonData);

      // 检查是否过期
      if (DateTime.now().isAfter(cacheItem.expiryDate)) {
        await _cacheService.remove(unifiedKey);
        AppLogger.debug(
            'Cache expired for dividend history with key: $cacheKey');
        return null;
      }

      final dividendHistory = cacheItem.data
          .map((json) => FundCorporateAction.fromJson(json))
          .toList();
      AppLogger.debug(
          'Retrieved ${dividendHistory.length} dividend records from cache');
      return dividendHistory;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get cached dividend history', e, stackTrace);
      return null;
    }
  }

  /// 缓存拆分历史数据
  Future<void> cacheSplitHistory(String cacheKey,
      List<FundSplitDetail> splitHistory, Duration expiryDuration) async {
    try {
      final unifiedKey = '$_splitHistoryPrefix$cacheKey';
      final cacheItem = CacheItem<List<Map<String, dynamic>>>(
        data: splitHistory.map((split) => split.toJson()).toList(),
        timestamp: DateTime.now(),
        expiryDate: DateTime.now().add(expiryDuration),
      );

      await _cacheService.put(
        unifiedKey,
        jsonEncode(cacheItem.toJson()),
        expiration: expiryDuration,
      );
      AppLogger.debug(
          'Cached ${splitHistory.length} split records with key: $cacheKey');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to cache split history', e, stackTrace);
    }
  }

  /// 获取缓存的拆分历史数据
  Future<List<FundSplitDetail>?> getCachedSplitHistory(String cacheKey) async {
    try {
      final unifiedKey = '$_splitHistoryPrefix$cacheKey';
      final cachedData = await _cacheService.get<String>(unifiedKey);

      if (cachedData == null) {
        return null;
      }

      final jsonData = jsonDecode(cachedData) as Map<String, dynamic>;
      final cacheItem =
          CacheItem<List<Map<String, dynamic>>>.fromJson(jsonData);

      // 检查是否过期
      if (DateTime.now().isAfter(cacheItem.expiryDate)) {
        await _cacheService.remove(unifiedKey);
        AppLogger.debug('Cache expired for split history with key: $cacheKey');
        return null;
      }

      final splitHistory =
          cacheItem.data.map((json) => FundSplitDetail.fromJson(json)).toList();
      AppLogger.debug(
          'Retrieved ${splitHistory.length} split records from cache');
      return splitHistory;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get cached split history', e, stackTrace);
      return null;
    }
  }

  /// 缓存收益指标数据
  Future<void> cacheProfitMetrics({
    required String cacheKey,
    required PortfolioProfitMetrics metrics,
    required Duration expiryDuration,
  }) async {
    try {
      final unifiedKey = '$_profitMetricsPrefix$cacheKey';
      final cacheItem = CacheItem<Map<String, dynamic>>(
        data: metrics.toJson(),
        timestamp: DateTime.now(),
        expiryDate: DateTime.now().add(expiryDuration),
      );

      await _cacheService.put(
        unifiedKey,
        jsonEncode(cacheItem.toJson()),
        expiration: expiryDuration,
      );
      AppLogger.debug('Cached profit metrics with key: $cacheKey');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to cache profit metrics', e, stackTrace);
    }
  }

  /// 获取缓存的收益指标数据
  Future<PortfolioProfitMetrics?> getCachedProfitMetrics(
      String cacheKey) async {
    try {
      final unifiedKey = '$_profitMetricsPrefix$cacheKey';
      final cachedData = await _cacheService.get<String>(unifiedKey);

      if (cachedData == null) {
        return null;
      }

      final jsonData = jsonDecode(cachedData) as Map<String, dynamic>;
      final cacheItem = CacheItem<Map<String, dynamic>>.fromJson(jsonData);

      // 检查是否过期
      if (DateTime.now().isAfter(cacheItem.expiryDate)) {
        await _cacheService.remove(unifiedKey);
        AppLogger.debug('Cache expired for profit metrics with key: $cacheKey');
        return null;
      }

      AppLogger.debug('Retrieved profit metrics from cache');
      return PortfolioProfitMetrics.fromJson(cacheItem.data);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get cached profit metrics', e, stackTrace);
      return null;
    }
  }

  /// 清除过期缓存
  Future<void> clearExpiredCache() async {
    try {
      AppLogger.info('Clearing expired cache entries');
      final allKeys = await _cacheService.getAllKeys();
      final now = DateTime.now();
      int totalCleared = 0;

      for (final key in allKeys) {
        try {
          final cachedData = await _cacheService.get<String>(key);
          if (cachedData != null) {
            final jsonData = jsonDecode(cachedData) as Map<String, dynamic>;
            if (jsonData.containsKey('expiryDate')) {
              final expiryDate =
                  DateTime.parse(jsonData['expiryDate'] as String);
              if (now.isAfter(expiryDate)) {
                await _cacheService.remove(key);
                totalCleared++;
              }
            }
          }
        } catch (e) {
          // 如果解析失败，也删除这个缓存项
          await _cacheService.remove(key);
          totalCleared++;
        }
      }

      AppLogger.info('Cleared $totalCleared expired cache entries');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clear expired cache', e, stackTrace);
    }
  }

  /// 缓存基准指数列表
  Future<void> cacheBenchmarkIndices(
      String cacheKey, List<BenchmarkIndex> indices) async {
    try {
      final unifiedKey = '$_benchmarkIndicesPrefix$cacheKey';
      final cacheItem = CacheItem<List<Map<String, dynamic>>>(
        data: indices
            .map((index) => {
                  'code': index.code,
                  'name': index.name,
                })
            .toList(),
        timestamp: DateTime.now(),
        expiryDate: DateTime.now().add(const Duration(days: 7)),
      );

      await _cacheService.put(
        unifiedKey,
        jsonEncode(cacheItem.toJson()),
        expiration: const Duration(days: 7),
      );
      AppLogger.debug(
          'Cached ${indices.length} benchmark indices with key: $cacheKey');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to cache benchmark indices', e, stackTrace);
    }
  }

  /// 获取缓存的基准指数列表
  Future<List<BenchmarkIndex>?> getCachedBenchmarkIndices(
      String cacheKey) async {
    try {
      final unifiedKey = '$_benchmarkIndicesPrefix$cacheKey';
      final cachedData = await _cacheService.get<String>(unifiedKey);

      if (cachedData == null) {
        return null;
      }

      final jsonData = jsonDecode(cachedData) as Map<String, dynamic>;
      final cacheItem =
          CacheItem<List<Map<String, dynamic>>>.fromJson(jsonData);

      // 检查是否过期
      if (DateTime.now().isAfter(cacheItem.expiryDate)) {
        await _cacheService.remove(unifiedKey);
        AppLogger.debug(
            'Cache expired for benchmark indices with key: $cacheKey');
        return null;
      }

      final indices = cacheItem.data
          .map((json) => BenchmarkIndex(
                code: json['code'] as String,
                name: json['name'] as String,
              ))
          .toList();
      AppLogger.debug(
          'Retrieved ${indices.length} benchmark indices from cache');
      return indices;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get cached benchmark indices', e, stackTrace);
      return null;
    }
  }

  /// 缓存数据质量报告
  Future<void> cacheDataQualityReport(
      String cacheKey, DataQualityReport report) async {
    try {
      final unifiedKey = '$_dataQualityReportPrefix$cacheKey';
      final cacheItem = CacheItem<Map<String, dynamic>>(
        data: {
          'metrics': report.metrics,
          'timestamp': report.timestamp.toIso8601String(),
        },
        timestamp: DateTime.now(),
        expiryDate: DateTime.now().add(const Duration(hours: 6)),
      );

      await _cacheService.put(
        unifiedKey,
        jsonEncode(cacheItem.toJson()),
        expiration: const Duration(hours: 6),
      );
      AppLogger.debug('Cached data quality report with key: $cacheKey');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to cache data quality report', e, stackTrace);
    }
  }

  /// 获取缓存的数据质量报告
  Future<DataQualityReport?> getCachedDataQualityReport(String cacheKey) async {
    try {
      final unifiedKey = '$_dataQualityReportPrefix$cacheKey';
      final cachedData = await _cacheService.get<String>(unifiedKey);

      if (cachedData == null) {
        return null;
      }

      final jsonData = jsonDecode(cachedData) as Map<String, dynamic>;
      final cacheItem = CacheItem<Map<String, dynamic>>.fromJson(jsonData);

      // 检查是否过期
      if (DateTime.now().isAfter(cacheItem.expiryDate)) {
        await _cacheService.remove(unifiedKey);
        AppLogger.debug(
            'Cache expired for data quality report with key: $cacheKey');
        return null;
      }

      final reportData = cacheItem.data;
      final report = DataQualityReport(
        metrics: Map<String, dynamic>.from(reportData['metrics']),
        timestamp: DateTime.parse(reportData['timestamp']),
      );
      AppLogger.debug('Retrieved data quality report from cache');
      return report;
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to get cached data quality report', e, stackTrace);
      return null;
    }
  }

  /// 清理统一缓存中的组合相关数据
  Future<void> clearPortfolioCache() async {
    try {
      // 获取所有与组合相关的缓存键
      final allKeys = await _cacheService.getAllKeys();
      final portfolioKeys = allKeys
          .where((key) =>
              key.startsWith(_holdingsPrefix) ||
              key.startsWith(_navHistoryPrefix) ||
              key.startsWith(_benchmarkHistoryPrefix) ||
              key.startsWith(_dividendHistoryPrefix) ||
              key.startsWith(_splitHistoryPrefix) ||
              key.startsWith(_profitMetricsPrefix) ||
              key.startsWith(_portfolioSummaryPrefix) ||
              key.startsWith(_benchmarkIndicesPrefix) ||
              key.startsWith(_dataQualityReportPrefix))
          .toList();

      // 批量删除组合相关的缓存
      if (portfolioKeys.isNotEmpty) {
        await _cacheService.removeAll(portfolioKeys);
        AppLogger.info('已清理 ${portfolioKeys.length} 个组合相关缓存项');
      }
    } catch (e) {
      AppLogger.warn('清理组合缓存失败: $e');
    }
  }

  /// 释放资源
  Future<void> dispose() async {
    try {
      // 清理所有缓存数据
      await clearPortfolioCache();
      AppLogger.info('PortfolioProfitCacheService disposed successfully');
    } catch (e) {
      AppLogger.error('Error during PortfolioProfitCacheService disposal', e);
    }
  }
}

/// 缓存项通用类
class CacheItem<T> {
  final T data;
  final DateTime timestamp;
  final DateTime expiryDate;

  CacheItem({
    required this.data,
    required this.timestamp,
    required this.expiryDate,
  });

  factory CacheItem.fromJson(Map<String, dynamic> json) {
    return CacheItem<T>(
      data: json['data'] as T,
      timestamp: DateTime.parse(json['timestamp'] as String),
      expiryDate: DateTime.parse(json['expiryDate'] as String),
    );
  }

  /// 专门用于 PortfolioHolding 列表的转换
  static CacheItem<List<PortfolioHolding>> fromHoldingJson(
      Map<dynamic, dynamic> json) {
    final stringJson = <String, dynamic>{};
    json.forEach((key, value) {
      if (key is String) {
        stringJson[key] = value;
      }
    });

    final dataValue = json['data'];
    List<PortfolioHolding> holdings;

    if (dataValue is List) {
      holdings = dataValue.map((item) {
        if (item is PortfolioHolding) {
          return item;
        } else if (item is Map<String, dynamic>) {
          return PortfolioHolding.fromJson(item);
        } else {
          // 尝试将 Map<dynamic, dynamic> 转换为 Map<String, dynamic>
          final itemStringMap = <String, dynamic>{};
          if (item is Map) {
            item.forEach((key, value) {
              if (key is String) {
                itemStringMap[key] = value;
              }
            });
          }
          return PortfolioHolding.fromJson(itemStringMap);
        }
      }).toList();
    } else {
      holdings = [];
    }

    return CacheItem<List<PortfolioHolding>>(
      data: holdings,
      timestamp: DateTime.parse(json['timestamp'] as String),
      expiryDate: DateTime.parse(json['expiryDate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
    };
  }
}

/// 测试用简单内存缓存服务实现
class _TestCacheService implements CacheService {
  final Map<String, dynamic> _cache = {};

  @override
  Future<T?> get<T>(String key) async {
    return _cache[key] as T?;
  }

  @override
  Future<void> put<T>(String key, T value, {Duration? expiration}) async {
    _cache[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _cache.remove(key);
  }

  @override
  Future<void> clear() async {
    _cache.clear();
  }

  @override
  Future<bool> containsKey(String key) async {
    return _cache.containsKey(key);
  }

  @override
  Future<List<String>> getAllKeys() async {
    return _cache.keys.toList();
  }

  @override
  Future<Map<String, dynamic>> getStats() async {
    return {
      'totalItems': _cache.length,
      'totalSize': _cache.toString().length,
      'hitRate': 0.0,
    };
  }

  @override
  Future<Map<String, dynamic?>> getAll(List<String> keys) async {
    final result = <String, dynamic?>{};
    for (final key in keys) {
      result[key] = _cache[key];
    }
    return result;
  }

  @override
  Future<void> putAll(Map<String, dynamic> keyValuePairs,
      {Duration? expiration}) async {
    _cache.addAll(keyValuePairs);
  }

  @override
  Future<void> removeAll(List<String> keys) async {
    for (final key in keys) {
      _cache.remove(key);
    }
  }

  @override
  Future<void> setExpiration(String key, Duration expiration) async {
    // 简单实现，不处理过期
  }

  @override
  Future<Duration?> getExpiration(String key) async {
    // 简单实现，不过期处理
    return null;
  }
}
