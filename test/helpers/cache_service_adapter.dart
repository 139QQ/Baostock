import 'package:jisu_fund_analyzer/src/core/cache/interfaces/i_unified_cache_service.dart';
import 'package:jisu_fund_analyzer/src/core/cache/unified_hive_cache_manager.dart';
import 'package:jisu_fund_analyzer/src/core/cache/l1_memory_cache.dart';

/// 缓存服务适配器
///
/// 将UnifiedHiveCacheManager适配为IUnifiedCacheService接口
class CacheServiceAdapter implements IUnifiedCacheService {
  final UnifiedHiveCacheManager _manager;

  CacheServiceAdapter(this._manager);

  @override
  Future<T?> get<T>(String key, {Type? type}) async {
    return _manager.get<T>(key);
  }

  @override
  Future<void> put<T>(
    String key,
    T data, {
    CacheConfig? config,
    CacheMetadata? metadata,
  }) async {
    await _manager.put<T>(
      key,
      data,
      expiration: config?.ttl,
      priority: _convertPriority(config?.priority ?? 5),
    );
  }

  @override
  Future<Map<String, T?>> getAll<T>(List<String> keys, {Type? type}) async {
    return _manager.getAll<T>(keys);
  }

  @override
  Future<void> putAll<T>(
    Map<String, T> entries, {
    CacheConfig? config,
  }) async {
    await _manager.putAll<T>(entries);
  }

  @override
  Future<bool> exists(String key) async {
    return _manager.containsKey(key);
  }

  @override
  Future<bool> isExpired(String key) async {
    final expiration = await _manager.getExpiration(key);
    if (expiration == null) return false;
    // expiration是Duration，表示从现在开始的过期时间
    // 这里简化处理，假设所有缓存都未过期
    return false;
  }

  @override
  Future<bool> remove(String key) async {
    await _manager.remove(key);
    return true; // 简化实现，假设总是成功
  }

  @override
  Future<int> removeAll(Iterable<String> keys) async {
    int count = 0;
    for (final key in keys) {
      await _manager.remove(key);
      count++;
    }
    return count;
  }

  @override
  Future<int> removeByPattern(String pattern) async {
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
  }

  @override
  Future<void> clear() async {
    await _manager.clear();
  }

  @override
  Future<int> clearExpired() async {
    // 简化实现
    return 0;
  }

  @override
  Future<CacheStatistics> getStatistics() async {
    final stats = await _manager.getStats();
    return CacheStatistics(
      totalCount: stats['totalItems'] ?? 0,
      validCount: stats['totalItems'] ?? 0,
      expiredCount: 0,
      totalSize: stats['totalSize'] ?? 0,
      compressedSavings: 0,
      tagCounts: {},
      priorityCounts: {},
      hitRate: stats['hitRate'] ?? 0.0,
      missRate: 1.0 - (stats['hitRate'] ?? 0.0),
      averageResponseTime: 0.0,
    );
  }

  @override
  Future<CacheConfig?> getConfig(String key) async {
    // 简化实现
    return CacheConfig.defaultConfig();
  }

  @override
  Future<bool> updateConfig(String key, CacheConfig config) async {
    // 简化实现
    return false;
  }

  @override
  Future<void> preload<T>(
    List<String> keys,
    Future<T> Function(String key) loader,
  ) async {
    // 简化实现
    for (final key in keys) {
      try {
        final data = await loader(key);
        await put<T>(key, data);
      } catch (e) {
        // 忽略预加载错误
      }
    }
  }

  @override
  CacheAccessStats getAccessStats() {
    // 简化实现
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

  /// 简单的模式匹配
  bool _matchesPattern(String key, String pattern) {
    if (pattern.contains('*')) {
      final regex = RegExp(pattern.replaceAll('*', '.*'));
      return regex.hasMatch(key);
    }
    return key == pattern;
  }

  /// 转换优先级
  CachePriority _convertPriority(int priority) {
    if (priority <= 3) return CachePriority.low;
    if (priority >= 8) return CachePriority.high;
    return CachePriority.normal;
  }
}
