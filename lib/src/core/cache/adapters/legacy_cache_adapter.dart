import '../interfaces/cache_service.dart';
<<<<<<< HEAD
import '../unified_hive_cache_manager.dart';
=======
import '../hive_cache_manager.dart';
>>>>>>> temp-dependency-injection
import '../../../core/utils/logger.dart';

/// 兼容性缓存适配器
///
/// 将原有的 HiveCacheManager 适配为 CacheService 接口
/// 用于向后兼容，确保现有代码能够平滑迁移到统一缓存系统
class LegacyCacheAdapter implements CacheService {
<<<<<<< HEAD
  final UnifiedHiveCacheManager _manager;
=======
  final HiveCacheManager _manager;
>>>>>>> temp-dependency-injection
  static const String _tag = 'LegacyCacheAdapter';

  /// 构造函数
  LegacyCacheAdapter(this._manager);

  @override
  Future<T?> get<T>(String key) async {
    try {
      // HiveCacheManager 使用 cacheBox 获取数据
      final value = await _manager.get(key);
      return value as T?;
    } catch (e) {
      AppLogger.error('Failed to get cache value for key: $key - $_tag', e);
      throw CacheServiceException('Failed to get cache value',
          key: key, originalError: e);
    }
  }

  @override
  Future<void> put<T>(String key, T value, {Duration? expiration}) async {
    try {
      // HiveCacheManager 使用 cacheBox 存储数据
      await _manager.put(key, value, expiration: expiration);
    } catch (e) {
      AppLogger.error('Failed to put cache value for key: $key - $_tag', e);
      throw CacheServiceException('Failed to put cache value',
          key: key, originalError: e);
    }
  }

  @override
  Future<void> remove(String key) async {
    try {
      await _manager.remove(key);
    } catch (e) {
      AppLogger.error('Failed to remove cache value for key: $key - $_tag', e);
      throw CacheServiceException('Failed to remove cache value',
          key: key, originalError: e);
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _manager.clear();
    } catch (e) {
      AppLogger.error('Failed to clear cache - $_tag', e);
      throw CacheServiceException('Failed to clear cache', originalError: e);
    }
  }

  @override
  Future<bool> containsKey(String key) async {
    try {
      // HiveCacheManager 没有直接的 containsKey 方法，通过获取值来判断
      final value = await _manager.get(key);
      return value != null;
    } catch (e) {
      AppLogger.error('Failed to check if key exists: $key - $_tag', e);
      throw CacheServiceException('Failed to check if key exists',
          key: key, originalError: e);
    }
  }

  @override
  Future<List<String>> getAllKeys() async {
    try {
      // HiveCacheManager 可能没有 getAllKeys 方法，返回空列表作为降级处理
      AppLogger.debug(
          'HiveCacheManager does not support getAllKeys, returning empty list - $_tag');
      return [];
    } catch (e) {
      AppLogger.error('Failed to get all keys - $_tag', e);
      throw CacheServiceException('Failed to get all keys', originalError: e);
    }
  }

  @override
  Future<Map<String, dynamic>> getStats() async {
    try {
      // HiveCacheManager 可能没有 getStats 方法，返回基本信息
      return {
        'adapter_type': 'legacy',
        'manager_type': 'HiveCacheManager',
        'supported_operations': ['get', 'put', 'remove', 'clear'],
      };
    } catch (e) {
      AppLogger.error('Failed to get cache stats - $_tag', e);
      throw CacheServiceException('Failed to get cache stats',
          originalError: e);
    }
  }

  @override
  Future<Map<String, dynamic?>> getAll(List<String> keys) async {
    try {
      final result = <String, dynamic?>{};
      for (final key in keys) {
        result[key] = await get(key);
      }
      return result;
    } catch (e) {
      AppLogger.error('Failed to get multiple cache values - $_tag', e);
      throw CacheServiceException('Failed to get multiple cache values',
          originalError: e);
    }
  }

  @override
  Future<void> putAll(Map<String, dynamic> keyValuePairs,
      {Duration? expiration}) async {
    try {
      for (final entry in keyValuePairs.entries) {
        await put(entry.key, entry.value, expiration: expiration);
      }
    } catch (e) {
      AppLogger.error('Failed to put multiple cache values - $_tag', e);
      throw CacheServiceException('Failed to put multiple cache values',
          originalError: e);
    }
  }

  @override
  Future<void> removeAll(List<String> keys) async {
    try {
      for (final key in keys) {
        await remove(key);
      }
    } catch (e) {
      AppLogger.error('Failed to remove multiple cache values - $_tag', e);
      throw CacheServiceException('Failed to remove multiple cache values',
          originalError: e);
    }
  }

  @override
  Future<void> setExpiration(String key, Duration expiration) async {
    try {
      // HiveCacheManager 的 put 方法支持 expireTime 参数
      // 但没有单独的 setExpiration 方法，这里通过重新设置值来实现
      final value = await _manager.get(key);
      if (value != null) {
        await _manager.put(key, value, expiration: expiration);
      } else {
        AppLogger.warn(
            'Cannot set expiration for non-existent key: $key - $_tag');
      }
    } catch (e) {
      AppLogger.error('Failed to set expiration for key: $key - $_tag', e);
      throw CacheServiceException('Failed to set expiration',
          key: key, originalError: e);
    }
  }

  @override
  Future<Duration?> getExpiration(String key) async {
    try {
      // HiveCacheManager 没有获取过期时间的方法，返回null
      AppLogger.warn(
          'HiveCacheManager does not support getExpiration, returning null - $_tag');
      return null;
    } catch (e) {
      AppLogger.error('Failed to get expiration for key: $key - $_tag', e);
      throw CacheServiceException('Failed to get expiration',
          key: key, originalError: e);
    }
  }
}
