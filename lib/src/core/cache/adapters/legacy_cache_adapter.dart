import '../interfaces/i_unified_cache_service.dart';
import '../interfaces/cache_service.dart';
import '../hive_cache_manager.dart';
import '../../../core/utils/logger.dart';

/// 兼容性缓存适配器
///
/// 将原有的 HiveCacheManager 适配为 IUnifiedCacheService 接口
/// 用于向后兼容，确保现有代码能够平滑迁移到统一缓存系统
class LegacyCacheAdapter implements IUnifiedCacheService {
  final HiveCacheManager _manager;
  static const String _tag = 'LegacyCacheAdapter';

  /// 构造函数
  LegacyCacheAdapter(this._manager);

  @override
  Future<T?> get<T>(String key, {Type? type}) async {
    try {
      // HiveCacheManager 使用 cacheBox 获取数据
      final value = await _manager.get(key);
      return value as T?;
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
      // HiveCacheManager 使用 cacheBox 存储数据
      await _manager.put(key, data, expiration: config?.ttl);
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to put cache value for key: $key - $_tag', e, stackTrace);
      throw CacheServiceException('Failed to put cache value',
          key: key, originalError: e);
    }
  }

  @override
  Future<bool> exists(String key) async {
    try {
      // HiveCacheManager 没有直接的 exists 方法，通过获取值来判断
      final value = await _manager.get(key);
      return value != null;
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to check if key exists: $key - $_tag', e, stackTrace);
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
          'Failed to remove cache value for key: $key - $_tag', e, stackTrace);
      throw CacheServiceException('Failed to remove cache value',
          key: key, originalError: e);
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
  Future<Map<String, T?>> getAll<T>(List<String> keys, {Type? type}) async {
    try {
      final result = <String, T?>{};
      for (final key in keys) {
        result[key] = await get<T>(key, type: type);
      }
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to get multiple cache values - $_tag', e, stackTrace);
      throw CacheServiceException('Failed to get multiple cache values',
          originalError: e);
    }
  }

  @override
  Future<void> putAll<T>(Map<String, T> entries, {CacheConfig? config}) async {
    try {
      for (final entry in entries.entries) {
        await put<T>(entry.key, entry.value, config: config);
      }
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to put multiple cache values - $_tag', e, stackTrace);
      throw CacheServiceException('Failed to put multiple cache values',
          originalError: e);
    }
  }

  @override
  Future<int> removeAll(Iterable<String> keys) async {
    try {
      int count = 0;
      for (final key in keys) {
        await remove(key);
        count++;
      }
      return count;
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to remove multiple cache values - $_tag', e, stackTrace);
      throw CacheServiceException('Failed to remove multiple cache values',
          originalError: e);
    }
  }

  @override
  Future<int> removeByPattern(String pattern) async {
    try {
      // HiveCacheManager 不支持模式删除和获取所有键
      // 这里返回 0，表示无法执行模式删除
      AppLogger.debug(
          'HiveCacheManager does not support removeByPattern - $_tag');
      return 0;
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to remove by pattern: $pattern - $_tag', e, stackTrace);
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
      AppLogger.error('Failed to preload cache values - $_tag', e, stackTrace);
      throw CacheServiceException('Failed to preload cache values',
          originalError: e);
    }
  }

  @override
  Future<void> optimize() async {
    try {
      // HiveCacheManager 可能不支持优化，这里为空实现
      AppLogger.debug('HiveCacheManager does not support optimize - $_tag');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to optimize cache - $_tag', e, stackTrace);
      throw CacheServiceException('Failed to optimize cache', originalError: e);
    }
  }

  @override
  Future<CacheStatistics> getStatistics() async {
    try {
      // HiveCacheManager 可能没有完整的统计信息，返回基本统计
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
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get cache statistics - $_tag', e, stackTrace);
      throw CacheServiceException('Failed to get cache statistics',
          originalError: e);
    }
  }

  @override
  Future<CacheConfig?> getConfig(String key) async {
    try {
      // HiveCacheManager 不支持配置管理，返回默认配置
      return CacheConfig.defaultConfig();
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to get cache config for key: $key - $_tag', e, stackTrace);
      throw CacheServiceException('Failed to get cache config',
          key: key, originalError: e);
    }
  }

  @override
  Future<bool> updateConfig(String key, CacheConfig config) async {
    try {
      // HiveCacheManager 不支持配置更新，返回 false
      return false;
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to update cache config for key: $key - $_tag', e, stackTrace);
      throw CacheServiceException('Failed to update cache config',
          key: key, originalError: e);
    }
  }

  @override
  CacheAccessStats getAccessStats() {
    try {
      // HiveCacheManager 不支持访问统计，返回空统计
      return CacheAccessStats();
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to get cache access stats - $_tag', e, stackTrace);
      throw CacheServiceException('Failed to get cache access stats',
          originalError: e);
    }
  }

  @override
  void resetAccessStats() {
    try {
      // HiveCacheManager 不支持访问统计重置，空实现
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to reset cache access stats - $_tag', e, stackTrace);
      throw CacheServiceException('Failed to reset cache access stats',
          originalError: e);
    }
  }

  @override
  Future<int> clearExpired() async {
    try {
      // HiveCacheManager 不支持过期清理，返回 0
      return 0;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clear expired cache - $_tag', e, stackTrace);
      throw CacheServiceException('Failed to clear expired cache',
          originalError: e);
    }
  }

  @override
  Future<bool> isExpired(String key) async {
    try {
      // HiveCacheManager 不支持过期检查，返回 false
      return false;
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to check if key is expired: $key - $_tag', e, stackTrace);
      throw CacheServiceException('Failed to check if key is expired',
          key: key, originalError: e);
    }
  }

  @override
  void setMonitoringEnabled(bool enabled) {
    try {
      // HiveCacheManager 不支持监控启用/禁用，空实现
      AppLogger.debug('HiveCacheManager does not support monitoring - $_tag');
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to set monitoring enabled: $enabled - $_tag', e, stackTrace);
      throw CacheServiceException('Failed to set monitoring enabled',
          originalError: e);
    }
  }
}
