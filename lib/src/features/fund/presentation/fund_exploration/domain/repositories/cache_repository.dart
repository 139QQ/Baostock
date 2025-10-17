import '../models/fund.dart';
import '../models/fund_filter.dart';

/// 缓存仓库接口
///
/// 定义数据缓存的基本操作，包括：
/// - 基金列表缓存
/// - 基金详情缓存
/// - 搜索结果缓存
/// - 筛选条件缓存
abstract class CacheRepository {
  /// 获取缓存的基金列表
  Future<List<Fund>?> getCachedFunds(String cacheKey);

  /// 缓存基金列表
  Future<void> cacheFunds(String cacheKey, List<Fund> funds, {Duration? ttl});

  /// 获取缓存的基金详情
  Future<Fund?> getCachedFundDetail(String fundCode);

  /// 缓存基金详情
  Future<void> cacheFundDetail(String fundCode, Fund fund, {Duration? ttl});

  /// 获取缓存的搜索结果
  Future<List<Fund>?> getCachedSearchResults(String query);

  /// 缓存搜索结果
  Future<void> cacheSearchResults(String query, List<Fund> results,
      {Duration? ttl});

  /// 获取缓存的筛选结果
  Future<List<Fund>?> getCachedFilteredResults(FundFilter filter);

  /// 缓存筛选结果
  Future<void> cacheFilteredResults(FundFilter filter, List<Fund> results,
      {Duration? ttl});

  /// 清除指定缓存
  Future<void> clearCache(String cacheKey);

  /// 清除所有缓存
  Future<void> clearAllCache();

  /// 检查缓存是否过期
  Future<bool> isCacheExpired(String cacheKey);

  /// 获取缓存年龄
  Future<Duration?> getCacheAge(String cacheKey);

  /// 获取缓存的基金排行数据
  Future<List<Map<String, dynamic>>?> getCachedFundRankings(String period);

  /// 缓存基金排行数据
  Future<void> cacheFundRankings(
      String period, List<Map<String, dynamic>> rankings,
      {Duration? ttl});

  /// 获取缓存大小信息
  Future<Map<String, dynamic>> getCacheInfo();

  /// 获取缓存统计信息
  Future<Map<String, dynamic>> getCacheStats();

  /// 清理过期缓存
  Future<void> clearExpiredCache();

  /// 获取缓存数据（通用）
  Future<dynamic> getCachedData(String cacheKey);

  /// 缓存数据（通用）
  Future<void> cacheData(String cacheKey, dynamic data,
      {required Duration ttl});
}

/// 缓存键常量
class CacheKeys {
  static String hotFunds = 'hot_funds';
  static String allFunds = 'all_funds';
  static String fundDetail = 'fund_detail_';
  static String searchResults = 'search_results_';
  static String filteredResults = 'filtered_results_';
  static String fundRankings = 'fund_rankings';
  static String marketDynamics = 'market_dynamics';
  static String lastUpdate = 'last_update_';

  /// 生成基金详情的缓存键
  static String fundDetailKey(String fundCode) => '$fundDetail$fundCode';

  /// 生成搜索结果的缓存键
  static String searchResultsKey(String query) =>
      '$searchResults${query.toLowerCase()}';

  /// 生成筛选结果的缓存键
  static String filteredResultsKey(FundFilter filter) {
    final buffer = StringBuffer();
    buffer.write(filteredResults);
    buffer.write(
        '_types:${filter.fundTypes.join(',')}_risks:${filter.riskLevels.join(',')}_companies:${filter.companies?.join(',') ?? 'all'}_scale:${filter.minScale}-${filter.maxScale}_return1y:${filter.minReturn1Y}-${filter.maxReturn1Y}_sort:${filter.sortBy}_asc:${filter.sortAscending}');
    return buffer.toString();
  }

  /// 生成最后更新时间的缓存键
  static String lastUpdateKey(String cacheKey) => '$lastUpdate$cacheKey';
}

/// 缓存配置
class CacheConfig {
  static Duration defaultTTL = const Duration(minutes: 30);
  static Duration fundListTTL = const Duration(minutes: 15);
  static Duration fundDetailTTL = const Duration(hours: 1);
  static Duration searchResultsTTL = const Duration(minutes: 10);
  static Duration marketDataTTL = const Duration(minutes: 5);
  static int maxCacheSize = 100 * 1024 * 1024; // 100MB
  static int maxCacheEntries = 1000;
}
