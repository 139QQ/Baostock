import '../interfaces/cache_service.dart';
import '../interfaces/i_unified_cache_service.dart';
import '../../utils/logger.dart';

/// 缓存服务适配器
///
/// 将 IUnifiedCacheService 适配为 CacheService 接口
/// 提供向后兼容性，确保现有代码能够平滑迁移到统一缓存系统
class CacheServiceAdapter extends CacheService {
  final IUnifiedCacheService _unifiedService;
  static const String _tag = 'CacheServiceAdapter';

  /// 构造函数
  CacheServiceAdapter(this._unifiedService);

  @override
  Future<T?> get<T>(String key) async {
    try {
      return await _unifiedService.get<T>(key);
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
      final config = expiration != null
          ? CacheConfig(ttl: expiration)
          : CacheConfig.defaultConfig();
      await _unifiedService.put(key, value, config: config);
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
      await _unifiedService.remove(key);
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
      await _unifiedService.clear();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clear cache - $_tag', e, stackTrace);
      throw CacheServiceException('Failed to clear cache', originalError: e);
    }
  }

  @override
  Future<bool> containsKey(String key) async {
    try {
      return await _unifiedService.exists(key);
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
      // IUnifiedCacheService 没有直接的 getAllKeys 方法
      // 这里返回空列表，子类可以重写此方法提供更好的实现
      AppLogger.warn(
          'getAllKeys not fully supported in CacheServiceAdapter - $_tag');
      return [];
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get all keys - $_tag', e, stackTrace);
      throw CacheServiceException('Failed to get all keys', originalError: e);
    }
  }

  @override
  Future<Map<String, dynamic>> getStats() async {
    try {
      final statistics = await _unifiedService.getStatistics();
      return {
        'totalItems': statistics.totalCount,
        'hitRate': statistics.hitRate,
        'missRate': statistics.missRate,
        'totalSize': statistics.totalSize,
        'averageResponseTime': statistics.averageResponseTime,
      };
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get cache stats - $_tag', e, stackTrace);
      throw CacheServiceException('Failed to get cache stats',
          originalError: e);
    }
  }

  @override
  Future<Map<String, dynamic>> getAll(List<String> keys) async {
    try {
      final result = <String, dynamic>{};
      final values = await _unifiedService.getAll(keys);
      result.addAll(values);
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to get multiple cache values - $_tag', e, stackTrace);
      throw CacheServiceException('Failed to get multiple cache values',
          originalError: e);
    }
  }

  @override
  Future<void> putAll(Map<String, dynamic> keyValuePairs,
      {Duration? expiration}) async {
    try {
      final config = expiration != null
          ? CacheConfig(ttl: expiration)
          : CacheConfig.defaultConfig();
      await _unifiedService.putAll(keyValuePairs, config: config);
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to put multiple cache values - $_tag', e, stackTrace);
      throw CacheServiceException('Failed to put multiple cache values',
          originalError: e);
    }
  }

  @override
  Future<void> removeAll(List<String> keys) async {
    try {
      await _unifiedService.removeAll(keys);
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to remove multiple cache values - $_tag', e, stackTrace);
      throw CacheServiceException('Failed to remove multiple cache values',
          originalError: e);
    }
  }

  @override
  Future<void> setExpiration(String key, Duration expiration) async {
    try {
      final config = CacheConfig(ttl: expiration);
      await _unifiedService.updateConfig(key, config);
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to set expiration for key: $key - $_tag', e, stackTrace);
      throw CacheServiceException('Failed to set expiration',
          key: key, originalError: e);
    }
  }

  @override
  Future<Duration?> getExpiration(String key) async {
    try {
      final config = await _unifiedService.getConfig(key);
      return config?.ttl;
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to get expiration for key: $key - $_tag', e, stackTrace);
      throw CacheServiceException('Failed to get expiration',
          key: key, originalError: e);
    }
  }
}
