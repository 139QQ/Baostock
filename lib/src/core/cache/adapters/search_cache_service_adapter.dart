import '../../../features/fund/data/services/search_cache_service.dart';
import '../../../features/fund/domain/entities/fund_search_criteria.dart';
import '../interfaces/i_unified_cache_service.dart';
import '../../../core/utils/logger.dart';

/// 搜索缓存服务适配器
///
/// 将 SearchCacheService 适配为 IUnifiedCacheService 接口
/// 提供统一的缓存操作接口，同时保持搜索缓存的特定功能
class SearchCacheServiceAdapter implements IUnifiedCacheService {
  final SearchCacheService _searchCacheService;
  static const String _tag = 'SearchCacheServiceAdapter';
  bool _isInitialized = false;

  /// 构造函数
  SearchCacheServiceAdapter(this._searchCacheService);

  @override
  Future<T?> get<T>(String key, {Type? type}) async {
    try {
      // 根据键的格式确定调用哪个方法
      if (key.startsWith('search_results:')) {
        final criteria = _createFundSearchCriteriaFromKey(key);
        final results =
            await _searchCacheService.getCachedSearchResults(criteria);
        return results as T?;
      } else if (key.startsWith('search_history:')) {
        final history = await _searchCacheService.getSearchHistory();
        return history as T?;
      } else if (key.startsWith('search_suggestions:')) {
        final query = key.split('search_suggestions:')[1];
        final suggestions =
            await _searchCacheService.getCachedSearchSuggestions(query);
        return suggestions as T?;
      } else if (key == 'popular_searches') {
        final popular = await _searchCacheService.getPopularSearches();
        return popular as T?;
      } else if (key == 'search_stats') {
        final stats = await _searchCacheService.getSearchStatistics();
        return stats as T?;
      }

      // 默认返回 null
      return null;
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to get cache value for key: $key - $_tag', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> put<T>(
    String key,
    T value, {
    CacheConfig? config,
    CacheMetadata? metadata,
  }) async {
    try {
      // 根据键的格式和值的类型确定调用哪个方法
      if (key.startsWith('search_results:') && value is List) {
        final criteria = _createFundSearchCriteriaFromKey(key);
        await _searchCacheService.cacheSearchResults(criteria, value.cast());
      } else if (key.startsWith('search_history:') && value is String) {
        await _searchCacheService.saveSearchHistory(value);
      } else if (key.startsWith('search_suggestions:') && value is List) {
        final query = key.split('search_suggestions:')[1];
        await _searchCacheService.cacheSearchSuggestions(
            query, value.cast<String>());
      } else if (key == 'popular_searches' && value is List) {
        await _searchCacheService.cachePopularSearches(value.cast<String>());
      } else if (key == 'search_stats' && value is Map) {
        await _searchCacheService
            .saveSearchStatistics(value.cast<String, dynamic>());
      }
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to put cache value for key: $key - $_tag', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<bool> exists(String key) async {
    try {
      final value = await get(key);
      return value != null;
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to check if key exists: $key - $_tag', e, stackTrace);
      return false;
    }
  }

  @override
  Future<bool> remove(String key) async {
    try {
      if (key.startsWith('search_results:')) {
        // SearchCacheService 没有单独清除搜索结果的方法，这里忽略
        return true;
      } else if (key == 'search_history') {
        await _searchCacheService.clearSearchHistory();
        return true;
      } else if (key.startsWith('search_suggestions:')) {
        // SearchCacheService 没有单独清除搜索建议的方法，这里忽略
        return true;
      } else if (key == 'popular_searches') {
        // SearchCacheService 没有单独清除热门搜索的方法，这里忽略
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to remove cache value for key: $key - $_tag', e, stackTrace);
      return false;
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _searchCacheService.clearSearchCache();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clear all caches - $_tag', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<Map<String, T?>> getAll<T>(List<String> keys, {Type? type}) async {
    final result = <String, T?>{};
    for (final key in keys) {
      final value = await get<T>(key);
      if (value != null) {
        result[key] = value;
      }
    }
    return result;
  }

  @override
  Future<void> putAll<T>(Map<String, T> entries, {CacheConfig? config}) async {
    for (final entry in entries.entries) {
      await put(entry.key, entry.value, config: config);
    }
  }

  @override
  Future<int> removeAll(Iterable<String> keys) async {
    int removedCount = 0;
    for (final key in keys) {
      if (await remove(key)) {
        removedCount++;
      }
    }
    return removedCount;
  }

  @override
  Future<int> removeByPattern(String pattern) async {
    // 这里简化实现，清除所有缓存
    await clear();
    return 1; // 返回清除的组数
  }

  @override
  Future<void> preload<T>(
    List<String> keys,
    Future<T> Function(String key) loader,
  ) async {
    for (final key in keys) {
      try {
        final data = await loader(key);
        await put(key, data);
      } catch (e) {
        AppLogger.warn('Failed to preload key: $key - $_tag', e);
      }
    }
  }

  @override
  Future<void> optimize() async {
    // 搜索缓存服务的优化操作
    try {
      await _searchCacheService.clearSearchCache();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to optimize cache - $_tag', e, stackTrace);
    }
  }

  @override
  Future<CacheStatistics> getStatistics() async {
    try {
      final stats = await _searchCacheService.getSearchStatistics();
      return CacheStatistics(
        totalCount: (stats['total_searches'] ?? 0) as int,
        validCount: (stats['cache_hits'] ?? 0) as int,
        expiredCount: 0,
        totalSize: 1024 * (stats['total_searches'] ?? 0) as int, // 估算大小
        compressedSavings: 512 * (stats['cache_hits'] ?? 0) as int, // 估算压缩节省
        tagCounts: {'search': (stats['total_searches'] ?? 0) as int},
        priorityCounts: {5: 1, 6: 1, 7: 1},
        hitRate: (stats['cache_hit_rate'] ?? 0.0).toDouble(),
        missRate: 1.0 - ((stats['cache_hit_rate'] ?? 0.0).toDouble()),
        averageResponseTime: (stats['average_response_time'] ?? 150).toDouble(),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get cache statistics - $_tag', e, stackTrace);
      return const CacheStatistics(
        totalCount: 0,
        validCount: 0,
        expiredCount: 0,
        totalSize: 0,
        compressedSavings: 0,
        tagCounts: {},
        priorityCounts: {},
        hitRate: 0.0,
        missRate: 0.0,
        averageResponseTime: 0.0,
      );
    }
  }

  @override
  Future<CacheConfig?> getConfig(String key) async {
    // 返回默认配置
    if (key.startsWith('search_results:')) {
      return const CacheConfig(
        ttl: Duration(minutes: 15),
        priority: 7,
        compressible: true,
      );
    } else if (key.startsWith('search_suggestions:')) {
      return const CacheConfig(
        ttl: Duration(minutes: 30),
        priority: 5,
        compressible: true,
      );
    } else if (key == 'popular_searches') {
      return const CacheConfig(
        ttl: Duration(hours: 24),
        priority: 6,
        compressible: true,
      );
    }
    return null;
  }

  @override
  Future<bool> updateConfig(String key, CacheConfig config) async {
    // 搜索缓存服务的配置更新
    // 这里可以实现配置更新逻辑
    return true;
  }

  @override
  CacheAccessStats getAccessStats() {
    return CacheAccessStats();
  }

  @override
  void resetAccessStats() {
    // 重置访问统计
  }

  @override
  Future<int> clearExpired() async {
    // SearchCacheService 没有公共的清理过期缓存方法，通过清理所有缓存来间接清理
    try {
      await _searchCacheService.clearSearchCache();
      return 1; // 返回清理的缓存组数
    } catch (e) {
      AppLogger.warn('Failed to clear expired cache - $_tag', e);
      return 0;
    }
  }

  @override
  Future<bool> isExpired(String key) async {
    // 搜索缓存有内置的过期机制，这里总是返回false
    return false;
  }

  @override
  void setMonitoringEnabled(bool enabled) {
    // SearchCacheService 不支持监控，忽略
  }

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // SearchCacheService 可能需要初始化
      _isInitialized = true;
      AppLogger.info('SearchCacheServiceAdapter initialized - $_tag');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize SearchCacheServiceAdapter - $_tag',
          e, stackTrace);
      rethrow;
    }
  }

  // ============================================================================
  // 私有辅助方法
  // ============================================================================

  /// 从键创建基金搜索条件
  FundSearchCriteria _createFundSearchCriteriaFromKey(String key) {
    // 简化实现：从键中解析搜索条件
    final criteriaPart = key.split('search_results:')[1];
    return FundSearchCriteria.keyword(criteriaPart);
  }
}

/// 搜索条件提取器
///
/// 用于将搜索条件转换为键，以及从键中提取搜索条件
class SearchCriteriaMapper {
  /// 将搜索条件转换为键
  static String criteriaToKey(Map<String, dynamic> criteria) {
    final query = criteria['query'] ?? '';
    final filters = criteria['filters'] ?? {};
    return 'search_results:${query}_${filters.hashCode}';
  }

  /// 从键中提取搜索条件
  static Map<String, dynamic> keyToCriteria(String key) {
    if (!key.startsWith('search_results:')) {
      return {};
    }

    final criteriaPart = key.split('search_results:')[1];
    // 这里应该实现更复杂的解析逻辑
    return {'query': criteriaPart};
  }
}
