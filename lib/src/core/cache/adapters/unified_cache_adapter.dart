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
  static const String _tag = 'UnifiedCacheAdapter';

  /// 构造函数
  UnifiedCacheAdapter(this._manager);

  @override
  Future<T?> get<T>(String key, {Type? type}) async {
    try {
      return _manager.get<T>(key);
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to get cache value for key: $key - $_tag', e, stackTrace);
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
          'Failed to put cache value for key: $key - $_tag', e, stackTrace);
      throw CacheServiceException('Failed to put cache value',
          key: key, originalError: e);
    }
  }

  @override
  Future<bool> isExpired(String key) async {
    try {
      // UnifiedHiveCacheManager 没有过期检查，返回false
      return false;
    } catch (e) {
      AppLogger.error('Failed to check if key is expired: $key - $_tag', e);
      throw CacheServiceException('Failed to check if key is expired',
          key: key, originalError: e);
    }
  }

  @override
  Future<Map<String, T?>> getAll<T>(List<String> keys, {Type? type}) async {
    try {
      return _manager.getAll<T>(keys);
    } catch (e) {
      AppLogger.error('Failed to get multiple cache values - $_tag', e);
      throw CacheServiceException('Failed to get multiple cache values',
          originalError: e);
    }
  }

  @override
  Future<void> putAll<T>(Map<String, T> entries, {CacheConfig? config}) async {
    try {
      await _manager.putAll<T>(entries);
    } catch (e) {
      AppLogger.error('Failed to put multiple cache values - $_tag', e);
      throw CacheServiceException('Failed to put multiple cache values',
          originalError: e);
    }
  }

  @override
  Future<bool> exists(String key) async {
    try {
      return _manager.containsKey(key);
    } catch (e) {
      AppLogger.error('Failed to check if key exists: $key - $_tag', e);
      throw CacheServiceException('Failed to check if key exists',
          key: key, originalError: e);
    }
  }

  @override
  Future<bool> remove(String key) async {
    try {
      await _manager.remove(key);
      return true;
    } catch (e) {
      AppLogger.error('Failed to remove cache value for key: $key - $_tag', e);
      throw CacheServiceException('Failed to remove cache value',
          key: key, originalError: e);
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
    } catch (e) {
      AppLogger.error('Failed to remove multiple cache values - $_tag', e);
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
    } catch (e) {
      AppLogger.error('Failed to remove by pattern: $pattern - $_tag', e);
      throw CacheServiceException('Failed to remove by pattern',
          originalError: e);
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _manager.clear();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clear cache - $_tag', e, stackTrace);
      throw CacheServiceException('Failed to clear cache', originalError: e);
    }
  }

  @override
  Future<int> clearExpired() async {
    // 简化实现
    return 0;
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
    } catch (e) {
      AppLogger.error('Failed to get cache stats - $_tag', e);
      throw CacheServiceException('Failed to get cache stats',
          originalError: e);
    }
  }

  @override
  Future<CacheConfig?> getConfig(String key) async {
    return CacheConfig.defaultConfig();
  }

  @override
  Future<bool> updateConfig(String key, CacheConfig config) async {
    return false;
  }

  @override
  Future<void> preload<T>(
    List<String> keys,
    Future<T> Function(String key) loader,
  ) async {
    // 简化实现
  }

  @override
  CacheAccessStats getAccessStats() {
    return CacheAccessStats();
  }

  @override
  void resetAccessStats() {
    // 简化实现
  }

  @override
  void setMonitoringEnabled(bool enabled) {
    // 简化实现
  }

  @override
  Future<void> optimize() async {
    // 简化实现
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
