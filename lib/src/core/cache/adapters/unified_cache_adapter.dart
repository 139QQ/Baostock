import '../interfaces/i_unified_cache_service.dart';
import '../interfaces/cache_service.dart';
import '../unified_hive_cache_manager.dart';
import '../l1_memory_cache.dart';
import '../../../core/utils/logger.dart';

/// 统一缓存服务适配器
///
/// 将 UnifiedHiveCacheManager 适配为 IUnifiedCacheService 接口
/// 提供标准的缓存操作接口，确保向后兼容性
class UnifiedCacheAdapter implements IUnifiedCacheService {
  final UnifiedHiveCacheManager _manager;
  static const String tag = 'UnifiedCacheAdapter';
  bool _isInitialized = false;

  /// 构造函数
  UnifiedCacheAdapter(this._manager);

  @override
  Future<T?> get<T>(String key, {Type? type}) async {
    try {
      return _manager.get<T>(key);
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to get cache value for key: $key - $tag', e, stackTrace);
      throw CacheServiceException('Failed to get cache value',
          key: key, originalError: e);
    }
  }

  @override
  Future<void> put<T>(
    String key,
    T data, {
    CacheConfig? config,
    CacheMetadata? metadata,
  }) async {
    try {
      await _manager.put(
        key,
        data,
        expiration: config?.ttl,
        priority: _convertPriorityToEnum(config?.priority ?? 5),
      );
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to put cache value for key: $key - $tag', e, stackTrace);
      throw CacheServiceException('Failed to put cache value',
          key: key, originalError: e);
    }
  }

  @override
  Future<bool> exists(String key) async {
    try {
      return _manager.containsKey(key);
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to check if key exists: $key - $tag', e, stackTrace);
      throw CacheServiceException('Failed to check if key exists',
          key: key, originalError: e);
    }
  }

  @override
  Future<bool> remove(String key) async {
    try {
      await _manager.remove(key);
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to remove cache value for key: $key - $tag', e, stackTrace);
      throw CacheServiceException('Failed to remove cache value',
          key: key, originalError: e);
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _manager.clear();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clear cache - $tag', e, stackTrace);
      throw CacheServiceException('Failed to clear cache', originalError: e);
    }
  }

  @override
  Future<Map<String, T?>> getAll<T>(List<String> keys, {Type? type}) async {
    try {
      return _manager.getAll<T>(keys);
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to get multiple cache values - $tag', e, stackTrace);
      throw CacheServiceException('Failed to get multiple cache values',
          originalError: e);
    }
  }

  @override
  Future<void> putAll<T>(Map<String, T> entries, {CacheConfig? config}) async {
    try {
      await _manager.putAll<T>(entries);
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to put multiple cache values - $tag', e, stackTrace);
      throw CacheServiceException('Failed to put multiple cache values',
          originalError: e);
    }
  }

  @override
  Future<int> removeAll(Iterable<String> keys) async {
    try {
      int count = 0;
      for (final key in keys) {
        await _manager.remove(key);
        count++;
      }
      return count;
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to remove multiple cache values - $tag', e, stackTrace);
      throw CacheServiceException('Failed to remove multiple cache values',
          originalError: e);
    }
  }

  @override
  Future<int> removeByPattern(String pattern) async {
    try {
      // 简化实现：获取所有键，过滤匹配模式的键
      final allKeys = await _manager.getAllKeys();
      final matchingKeys =
          allKeys.where((key) => _matchesPattern(key, pattern)).toList();

      int count = 0;
      for (final key in matchingKeys) {
        await _manager.remove(key);
        count++;
      }
      return count;
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to remove by pattern: $pattern - $tag', e, stackTrace);
      throw CacheServiceException('Failed to remove by pattern',
          originalError: e);
    }
  }

  @override
  Future<void> preload<T>(
    List<String> keys,
    Future<T> Function(String key) loader,
  ) async {
    try {
      for (final key in keys) {
        if (!await exists(key)) {
          final value = await loader(key);
          await put<T>(key, value);
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to preload cache values - $tag', e, stackTrace);
      throw CacheServiceException('Failed to preload cache values',
          originalError: e);
    }
  }

  @override
  Future<void> optimize() async {
    try {
      // 简化实现：如果管理器支持优化，则调用它
      // 这里可以添加具体的优化逻辑
    } catch (e, stackTrace) {
      AppLogger.error('Failed to optimize cache - $tag', e, stackTrace);
      throw CacheServiceException('Failed to optimize cache', originalError: e);
    }
  }

  @override
  Future<CacheStatistics> getStatistics() async {
    try {
      final stats = await _manager.getStats();
      return CacheStatistics(
        totalCount: stats['totalItems'] ?? 0,
        validCount: stats['totalItems'] ?? 0,
        expiredCount: 0,
        totalSize: stats['totalSize'] ?? 0,
        compressedSavings: 0,
        tagCounts: {},
        priorityCounts: {5: (stats['totalItems'] ?? 0) as int},
        hitRate: stats['hitRate'] ?? 0.0,
        missRate: 1.0 - ((stats['hitRate'] ?? 0.0) as double),
        averageResponseTime: 50.0,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get cache stats - $tag', e, stackTrace);
      throw CacheServiceException('Failed to get cache stats',
          originalError: e);
    }
  }

  @override
  Future<CacheConfig?> getConfig(String key) async {
    try {
      // 简化实现：返回默认配置
      return CacheConfig.defaultConfig();
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to get cache config for key: $key - $tag', e, stackTrace);
      throw CacheServiceException('Failed to get cache config',
          key: key, originalError: e);
    }
  }

  @override
  Future<bool> updateConfig(String key, CacheConfig config) async {
    try {
      // 简化实现：返回false表示不支持更新
      return false;
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to update cache config for key: $key - $tag', e, stackTrace);
      throw CacheServiceException('Failed to update cache config',
          key: key, originalError: e);
    }
  }

  @override
  CacheAccessStats getAccessStats() {
    try {
      // 简化实现：返回空的访问统计
      return CacheAccessStats();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get cache access stats - $tag', e, stackTrace);
      throw CacheServiceException('Failed to get cache access stats',
          originalError: e);
    }
  }

  @override
  void resetAccessStats() {
    try {
      // 简化实现：不做任何操作
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to reset cache access stats - $tag', e, stackTrace);
      throw CacheServiceException('Failed to reset cache access stats',
          originalError: e);
    }
  }

  @override
  Future<int> clearExpired() async {
    try {
      // 简化实现：返回0表示没有清理任何过期项
      return 0;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clear expired cache - $tag', e, stackTrace);
      throw CacheServiceException('Failed to clear expired cache',
          originalError: e);
    }
  }

  @override
  Future<bool> isExpired(String key) async {
    try {
      // 简化实现：返回false表示不过期
      return false;
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to check if key is expired: $key - $tag', e, stackTrace);
      throw CacheServiceException('Failed to check if key is expired',
          key: key, originalError: e);
    }
  }

  @override
  void setMonitoringEnabled(bool enabled) {
    try {
      // 简化实现：不做任何操作
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to set monitoring enabled: $enabled - $tag', e, stackTrace);
      throw CacheServiceException('Failed to set monitoring enabled',
          originalError: e);
    }
  }

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // UnifiedHiveCacheManager 可能需要初始化
      _isInitialized = true;
      AppLogger.info('UnifiedCacheAdapter initialized - $tag');
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to initialize UnifiedCacheAdapter - $tag', e, stackTrace);
      rethrow;
    }
  }

  // ============================================================================
  // 私有方法
  // ============================================================================

  /// 简单的模式匹配
  bool _matchesPattern(String key, String pattern) {
    if (pattern.contains('*')) {
      final regex = RegExp(pattern.replaceAll('*', '.*'));
      return regex.hasMatch(key);
    }
    return key == pattern;
  }

  /// 转换优先级为枚举
  CachePriority _convertPriorityToEnum(int priority) {
    if (priority <= 3) return CachePriority.low;
    if (priority >= 8) return CachePriority.high;
    return CachePriority.normal;
  }
}
