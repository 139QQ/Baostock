import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../models/fund.dart';
import '../../models/fund_filter.dart';
import '../../repositories/cache_repository.dart';

/// 内存缓存实现
///
/// 基于内存的轻量级缓存，特点：
/// - 读写速度快
/// - 无需持久化存储
/// - 适合临时数据缓存
/// - 应用重启后数据丢失
class MemoryCacheRepository implements CacheRepository {
  // 缓存数据存储
  final Map<String, List<Fund>> _fundsCache = {};
  final Map<String, Fund> _fundDetailCache = {};
  final Map<String, List<Map<String, dynamic>>> _fundRankingsCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  // LRU缓存队列，用于控制缓存大小
  final Queue<String> _lruQueue = Queue<String>();
  static int maxCacheEntries = 500;

  @override
  Future<List<Fund>?> getCachedFunds(String cacheKey) async {
    try {
      if (!_fundsCache.containsKey(cacheKey)) {
        debugPrint('内存缓存未命中: $cacheKey');
        return null;
      }

      // 检查缓存是否过期
      if (await isCacheExpired(cacheKey)) {
        debugPrint('内存缓存已过期: $cacheKey');
        await clearCache(cacheKey);
        return null;
      }

      debugPrint('内存缓存命中: $cacheKey');
      _updateLRU(cacheKey);
      return _fundsCache[cacheKey];
    } catch (e) {
      debugPrint('获取内存缓存失败: $e');
      return null;
    }
  }

  @override
  Future<void> cacheFunds(String cacheKey, List<Fund> funds,
      {Duration? ttl}) async {
    try {
      // 控制缓存大小
      await _ensureCacheSize();

      _fundsCache[cacheKey] = List.from(funds); // 创建副本避免外部修改
      _cacheTimestamps[CacheKeys.lastUpdateKey(cacheKey)] = DateTime.now();
      _updateLRU(cacheKey);

      debugPrint('内存缓存已保存: $cacheKey (${funds.length}条数据)');
    } catch (e) {
      debugPrint('保存内存缓存失败: $e');
    }
  }

  @override
  Future<Fund?> getCachedFundDetail(String fundCode) async {
    try {
      final cacheKey = CacheKeys.fundDetailKey(fundCode);
      if (!_fundDetailCache.containsKey(cacheKey)) {
        debugPrint('内存缓存未命中(基金详情): $cacheKey');
        return null;
      }

      // 检查缓存是否过期
      if (await isCacheExpired(cacheKey)) {
        debugPrint('内存缓存已过期(基金详情): $cacheKey');
        await clearCache(cacheKey);
        return null;
      }

      debugPrint('内存缓存命中(基金详情): $cacheKey');
      _updateLRU(cacheKey);
      return _fundDetailCache[cacheKey];
    } catch (e) {
      debugPrint('获取内存缓存失败(基金详情): $e');
      return null;
    }
  }

  @override
  Future<void> cacheFundDetail(String fundCode, Fund fund,
      {Duration? ttl}) async {
    try {
      final cacheKey = CacheKeys.fundDetailKey(fundCode);

      // 控制缓存大小
      await _ensureCacheSize();

      _fundDetailCache[cacheKey] = fund;
      _cacheTimestamps[CacheKeys.lastUpdateKey(cacheKey)] = DateTime.now();
      _updateLRU(cacheKey);

      debugPrint('内存缓存已保存(基金详情): $cacheKey');
    } catch (e) {
      debugPrint('保存内存缓存失败(基金详情): $e');
    }
  }

  @override
  Future<List<Fund>?> getCachedSearchResults(String query) async {
    final cacheKey = CacheKeys.searchResultsKey(query);
    return await getCachedFunds(cacheKey);
  }

  @override
  Future<void> cacheSearchResults(String query, List<Fund> results,
      {Duration? ttl}) async {
    final cacheKey = CacheKeys.searchResultsKey(query);
    await cacheFunds(cacheKey, results,
        ttl: ttl ?? CacheConfig.searchResultsTTL);
  }

  @override
  Future<List<Fund>?> getCachedFilteredResults(FundFilter filter) async {
    final cacheKey = CacheKeys.filteredResultsKey(filter);
    return await getCachedFunds(cacheKey);
  }

  @override
  Future<void> cacheFilteredResults(FundFilter filter, List<Fund> results,
      {Duration? ttl}) async {
    final cacheKey = CacheKeys.filteredResultsKey(filter);
    await cacheFunds(cacheKey, results, ttl: ttl ?? CacheConfig.defaultTTL);
  }

  @override
  Future<void> clearCache(String cacheKey) async {
    try {
      _fundsCache.remove(cacheKey);
      _fundDetailCache.remove(cacheKey);
      _cacheTimestamps.remove(CacheKeys.lastUpdateKey(cacheKey));
      _lruQueue.remove(cacheKey);

      debugPrint('内存缓存已清除: $cacheKey');
    } catch (e) {
      debugPrint('清除内存缓存失败: $e');
    }
  }

  @override
  Future<void> clearAllCache() async {
    try {
      _fundsCache.clear();
      _fundDetailCache.clear();
      _cacheTimestamps.clear();
      _lruQueue.clear();

      debugPrint('所有内存缓存已清除');
    } catch (e) {
      debugPrint('清除所有内存缓存失败: $e');
    }
  }

  @override
  Future<bool> isCacheExpired(String cacheKey) async {
    try {
      final timestampKey = CacheKeys.lastUpdateKey(cacheKey);
      if (!_cacheTimestamps.containsKey(timestampKey)) {
        return true;
      }

      final lastUpdate = _cacheTimestamps[timestampKey]!;
      final now = DateTime.now();

      // 根据缓存键类型确定TTL
      Duration ttl = _getTTLForCacheKey(cacheKey);

      return now.difference(lastUpdate) > ttl;
    } catch (e) {
      debugPrint('检查缓存过期失败: $e');
      return true; // 出错时认为缓存已过期
    }
  }

  @override
  Future<Duration?> getCacheAge(String cacheKey) async {
    try {
      final timestampKey = CacheKeys.lastUpdateKey(cacheKey);
      if (!_cacheTimestamps.containsKey(timestampKey)) {
        return null;
      }

      final lastUpdate = _cacheTimestamps[timestampKey]!;
      final now = DateTime.now();

      return now.difference(lastUpdate);
    } catch (e) {
      debugPrint('获取缓存年龄失败: $e');
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>> getCacheInfo() async {
    return {
      'totalEntries': _fundsCache.length + _fundDetailCache.length,
      'fundListEntries': _fundsCache.length,
      'fundDetailEntries': _fundDetailCache.length,
      'totalMemorySize': _estimateMemorySize(),
      'oldestEntry': _getOldestEntryTime(),
      'newestEntry': _getNewestEntryTime(),
    };
  }

  @override
  Future<Map<String, dynamic>> getCacheStats() async {
    return {
      'totalEntries': _fundsCache.length + _fundDetailCache.length,
      'fundListEntries': _fundsCache.length,
      'fundDetailEntries': _fundDetailCache.length,
      'fundRankingsEntries': _fundRankingsCache.length,
      'totalMemorySize': _estimateMemorySize(),
      'oldestEntry': _getOldestEntryTime(),
      'newestEntry': _getNewestEntryTime(),
      'lruQueueSize': _lruQueue.length,
      'maxCacheEntries': CacheConfig.maxCacheEntries,
      'cacheHitRate': 0.0, // 可以在后续实现中添加命中率统计
    };
  }

  @override
  Future<void> clearExpiredCache() async {
    try {
      final expiredKeys = <String>[];

      // 检查所有缓存键是否过期
      final allKeys = <String>{
        ..._fundsCache.keys,
        ..._fundDetailCache.keys,
        ..._fundRankingsCache.keys,
      };

      for (final key in allKeys) {
        if (await isCacheExpired(key)) {
          expiredKeys.add(key);
        }
      }

      // 清理过期缓存
      for (final key in expiredKeys) {
        await clearCache(key);
      }

      debugPrint('清理过期缓存完成: ${expiredKeys.length}个条目');
    } catch (e) {
      debugPrint('清理过期缓存失败: $e');
    }
  }

  /// 获取缓存键对应的TTL
  Duration _getTTLForCacheKey(String cacheKey) {
    if (cacheKey.contains(CacheKeys.fundDetail)) {
      return CacheConfig.fundDetailTTL;
    } else if (cacheKey.contains(CacheKeys.searchResults)) {
      return CacheConfig.searchResultsTTL;
    } else if (cacheKey.contains(CacheKeys.marketDynamics)) {
      return CacheConfig.marketDataTTL;
    } else {
      return CacheConfig.fundListTTL;
    }
  }

  /// 更新LRU队列
  void _updateLRU(String cacheKey) {
    _lruQueue.remove(cacheKey);
    _lruQueue.addLast(cacheKey);
  }

  /// 确保缓存大小不超过限制
  Future<void> _ensureCacheSize() async {
    while (_lruQueue.length >= CacheConfig.maxCacheEntries) {
      final oldestKey = _lruQueue.removeFirst();
      await clearCache(oldestKey);
    }
  }

  /// 估算内存使用量（字节）
  int _estimateMemorySize() {
    int size = 0;

    // 估算基金列表缓存大小
    for (final entry in _fundsCache.entries) {
      size += entry.key.length * 2; // 字符串内存
      size += entry.value.length * 200; // 粗略估算每个基金对象大小
    }

    // 估算基金详情缓存大小
    for (final entry in _fundDetailCache.entries) {
      size += entry.key.length * 2;
      size += 200; // 粗略估算每个基金对象大小
    }

    // 时间戳缓存
    size += _cacheTimestamps.length * 50;

    return size;
  }

  /// 获取最旧的缓存项时间
  DateTime? _getOldestEntryTime() {
    if (_cacheTimestamps.isEmpty) return null;

    return _cacheTimestamps.values.reduce((a, b) => a.isBefore(b) ? a : b);
  }

  /// 获取最新的缓存项时间
  DateTime? _getNewestEntryTime() {
    if (_cacheTimestamps.isEmpty) return null;

    return _cacheTimestamps.values.reduce((a, b) => a.isAfter(b) ? a : b);
  }

  @override
  Future<List<Map<String, dynamic>>?> getCachedFundRankings(
      String period) async {
    try {
      final cacheKey = '${CacheKeys.fundRankings}_$period';
      if (!_fundRankingsCache.containsKey(cacheKey)) {
        debugPrint('内存基金排行缓存未命中: $cacheKey');
        return null;
      }

      // 检查缓存是否过期
      if (await isCacheExpired(cacheKey)) {
        debugPrint('内存基金排行缓存已过期: $cacheKey');
        await clearCache(cacheKey);
        return null;
      }

      debugPrint('内存基金排行缓存命中: $cacheKey');
      _updateLRU(cacheKey);
      return _fundRankingsCache[cacheKey];
    } catch (e) {
      debugPrint('获取内存基金排行缓存失败: $e');
      return null;
    }
  }

  @override
  Future<void> cacheFundRankings(
      String period, List<Map<String, dynamic>> rankings,
      {Duration? ttl}) async {
    try {
      final cacheKey = '${CacheKeys.fundRankings}_$period';

      // 确保缓存大小不超过限制
      await _ensureCacheSize();

      // 存储数据和时间戳
      _fundRankingsCache[cacheKey] = rankings;
      _cacheTimestamps[cacheKey] = DateTime.now();

      // 更新LRU队列
      _updateLRU(cacheKey);

      debugPrint('内存基金排行缓存成功: $cacheKey, 共 ${rankings.length} 条');
    } catch (e) {
      debugPrint('内存基金排行缓存失败: $e');
      // 缓存失败时不抛出异常，保持服务可用
    }
  }

  @override
  Future<dynamic> getCachedData(String cacheKey) async {
    try {
      // 检查缓存是否过期
      if (await isCacheExpired(cacheKey)) {
        debugPrint('内存缓存已过期(通用数据): $cacheKey');
        await clearCache(cacheKey);
        return null;
      }

      // 尝试从不同的缓存中获取数据
      if (_fundsCache.containsKey(cacheKey)) {
        _updateLRU(cacheKey);
        return _fundsCache[cacheKey];
      }

      if (_fundDetailCache.containsKey(cacheKey)) {
        _updateLRU(cacheKey);
        return _fundDetailCache[cacheKey];
      }

      if (_fundRankingsCache.containsKey(cacheKey)) {
        _updateLRU(cacheKey);
        return _fundRankingsCache[cacheKey];
      }

      debugPrint('内存缓存未命中(通用数据): $cacheKey');
      return null;
    } catch (e) {
      debugPrint('获取内存缓存失败(通用数据): $e');
      return null;
    }
  }

  @override
  Future<void> cacheData(String cacheKey, dynamic data,
      {required Duration ttl}) async {
    try {
      // 确保缓存大小不超过限制
      await _ensureCacheSize();

      // 根据数据类型存储到不同的缓存中
      if (data is List<Fund>) {
        _fundsCache[cacheKey] = data;
      } else if (data is Fund) {
        _fundDetailCache[cacheKey] = data;
      } else if (data is List<Map<String, dynamic>>) {
        _fundRankingsCache[cacheKey] = data;
      } else {
        // 对于其他类型数据，存储到通用缓存中（需要添加新的缓存字段）
        debugPrint('不支持的数据类型缓存: ${data.runtimeType}');
        return;
      }

      // 更新时间戳和LRU队列
      _cacheTimestamps[cacheKey] = DateTime.now();
      _updateLRU(cacheKey);

      debugPrint('内存缓存已保存(通用数据): $cacheKey');
    } catch (e) {
      debugPrint('保存内存缓存失败(通用数据): $e');
    }
  }
}
