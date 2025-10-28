import '../interfaces/cache_service.dart';
import '../unified_hive_cache_manager.dart';
import '../../../core/utils/logger.dart';

/// 统一缓存服务适配器
///
/// 将 UnifiedHiveCacheManager 适配为 CacheService 接口
/// 提供标准的缓存操作接口，确保向后兼容性
class UnifiedCacheAdapter implements CacheService {
  final UnifiedHiveCacheManager _manager;
  static const String _tag = 'UnifiedCacheAdapter';

  /// 构造函数
  UnifiedCacheAdapter(this._manager);

  @override
  Future<T?> get<T>(String key) async {
    try {
      return await _manager.get<T>(key);
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to get cache value for key: $key - $_tag', e, stackTrace);
      throw CacheServiceException('Failed to get cache value',
          key: key, originalError: e);
    }
  }

  @override
  Future<void> put<T>(String key, T value, {Duration? expiration}) async {
    try {
      await _manager.put(key, value, expiration: expiration);
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to put cache value for key: $key - $_tag', e, stackTrace);
      throw CacheServiceException('Failed to put cache value',
          key: key, originalError: e);
    }
  }

  @override
  Future<void> remove(String key) async {
    try {
      await _manager.remove(key);
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
  Future<bool> containsKey(String key) async {
    try {
      return await _manager.containsKey(key);
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to check if key exists: $key - $_tag', e, stackTrace);
      throw CacheServiceException('Failed to check if key exists',
          key: key, originalError: e);
    }
  }

  @override
  Future<List<String>> getAllKeys() async {
    try {
      return await _manager.getAllKeys();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get all keys - $_tag', e, stackTrace);
      throw CacheServiceException('Failed to get all keys', originalError: e);
    }
  }

  @override
  Future<Map<String, dynamic>> getStats() async {
    try {
      return await _manager.getStats();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get cache stats - $_tag', e, stackTrace);
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
      await _manager.putAll(keyValuePairs, expiration: expiration);
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
      await _manager.setExpiration(key, expiration);
    } catch (e) {
      AppLogger.error('Failed to set expiration for key: $key - $_tag', e);
      throw CacheServiceException('Failed to set expiration',
          key: key, originalError: e);
    }
  }

  @override
  Future<Duration?> getExpiration(String key) async {
    try {
      return await _manager.getExpiration(key);
    } catch (e) {
      AppLogger.error('Failed to get expiration for key: $key - $_tag', e);
      throw CacheServiceException('Failed to get expiration',
          key: key, originalError: e);
    }
  }
}
