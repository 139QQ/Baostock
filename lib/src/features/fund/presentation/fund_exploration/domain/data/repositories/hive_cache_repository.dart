import 'package:flutter/foundation.dart';
import 'package:jisu_fund_analyzer/src/core/cache/hive_cache_manager.dart';

import '../../models/fund.dart';
import '../../models/fund_filter.dart';
import '../../repositories/cache_repository.dart';

/// Hive缓存仓库实现
///
/// 使用Hive作为持久化缓存，支持：
/// - 基金数据缓存
/// - 排行榜数据缓存
/// - 搜索结果缓存
/// - 基金详情缓存
class HiveCacheRepository implements CacheRepository {
  final HiveCacheManager _cacheManager;

  HiveCacheRepository({
    HiveCacheManager? cacheManager,
  }) : _cacheManager = cacheManager ?? HiveCacheManager.instance;

  @override
  Future<List<Fund>?> getCachedFunds(String cacheKey) async {
    try {
      final cachedData = _cacheManager.get<List<dynamic>>(cacheKey);
      if (cachedData == null) return null;

      // 将缓存数据转换为Fund列表
      return cachedData.map((data) => Fund.fromJson(data)).toList();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheFunds(String cacheKey, List<Fund> funds,
      {Duration? ttl}) async {
    try {
      // 将Fund列表转换为可缓存的JSON数据
      final fundsData = funds.map((fund) => fund.toJson()).toList();
      await _cacheManager.put(cacheKey, fundsData, expiration: ttl);
    } catch (e) {
      // 缓存失败时不抛出异常，保持服务可用
    }
  }

  @override
  Future<Fund?> getCachedFundDetail(String fundCode) async {
    try {
      final cacheKey = 'fund_detail_$fundCode';
      final cachedData = _cacheManager.get<Map<String, dynamic>>(cacheKey);
      if (cachedData == null) return null;

      return Fund.fromJson(cachedData);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheFundDetail(String fundCode, Fund fund,
      {Duration? ttl}) async {
    try {
      final cacheKey = 'fund_detail_$fundCode';
      await _cacheManager.put(cacheKey, fund.toJson(), expiration: ttl);
    } catch (e) {
      // 缓存失败时不抛出异常，保持服务可用
    }
  }

  @override
  Future<List<Fund>?> getCachedSearchResults(String query) async {
    try {
      final cacheKey = 'search_results_$query';
      final cachedData = _cacheManager.get<List<dynamic>>(cacheKey);
      if (cachedData == null) return null;

      return cachedData.map((data) => Fund.fromJson(data)).toList();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheSearchResults(String query, List<Fund> results,
      {Duration? ttl}) async {
    try {
      final cacheKey = 'search_results_$query';
      final resultsData = results.map((fund) => fund.toJson()).toList();
      await _cacheManager.put(cacheKey, resultsData, expiration: ttl);
    } catch (e) {
      // 缓存失败时不抛出异常，保持服务可用
    }
  }

  @override
  Future<List<Fund>?> getCachedFilteredResults(FundFilter filter) async {
    try {
      final cacheKey = CacheKeys.filteredResultsKey(filter);
      final cachedData = _cacheManager.get<List<dynamic>>(cacheKey);
      if (cachedData == null) return null;

      return cachedData.map((data) => Fund.fromJson(data)).toList();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheFilteredResults(FundFilter filter, List<Fund> results,
      {Duration? ttl}) async {
    try {
      final cacheKey = CacheKeys.filteredResultsKey(filter);
      final resultsData = results.map((fund) => fund.toJson()).toList();
      await _cacheManager.put(cacheKey, resultsData, expiration: ttl);
    } catch (e) {
      // 缓存失败时不抛出异常，保持服务可用
    }
  }

  @override
  Future<void> clearCache(String cacheKey) async {
    try {
      await _cacheManager.remove(cacheKey);
    } catch (e) {
      // 清理失败时不抛出异常
    }
  }

  @override
  Future<void> clearAllCache() async {
    try {
      await _cacheManager.clear();
    } catch (e) {
      // 清理失败时不抛出异常
    }
  }

  @override
  Future<bool> isCacheExpired(String cacheKey) async {
    try {
      // 检查缓存是否存在
      return !_cacheManager.containsKey(cacheKey);
    } catch (e) {
      return true; // 数据损坏或不存在，认为已过期
    }
  }

  @override
  Future<Duration?> getCacheAge(String cacheKey) async {
    try {
      // HiveCacheManager 不直接提供时间戳信息
      // 返回 null 表示无法获取缓存年龄
      return null;
    } catch (e) {
      debugPrint('获取缓存年龄失败: $e');
      return null;
    }
  }

  @override
  Future<List<Map<String, dynamic>>?> getCachedFundRankings(
      String period) async {
    try {
      final cacheKey = '${CacheKeys.fundRankings}_$period';
      final cachedData = _cacheManager.get<List<dynamic>>(cacheKey);
      if (cachedData == null) return null;

      return cachedData.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('❌ 获取基金排行缓存失败: $e');
      return null;
    }
  }

  @override
  Future<void> cacheFundRankings(
      String period, List<Map<String, dynamic>> rankings,
      {Duration? ttl}) async {
    try {
      final cacheKey = '${CacheKeys.fundRankings}_$period';

      await _cacheManager.put(cacheKey, rankings, expiration: ttl);
      debugPrint('✅ 基金排行缓存成功: $period, 共 ${rankings.length} 条');
    } catch (e) {
      debugPrint('❌ 基金排行缓存失败: $e');
      // 缓存失败时不抛出异常，保持服务可用
    }
  }

  @override
  Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final stats = _cacheManager.getStats();

      return {
        'cacheStats': stats,
        'cacheStatus': 'healthy',
        'lastCleanup': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'cacheStats': {},
        'cacheStatus': 'error',
        'error': e.toString(),
      };
    }
  }

  @override
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final stats = _cacheManager.getStats();

      return {
        'cacheStats': stats,
        'cacheStatus': 'healthy',
        'lastCleanup': DateTime.now().toIso8601String(),
        'cacheType': 'Hive',
        'persistentStorage': true,
      };
    } catch (e) {
      return {
        'cacheStats': {},
        'cacheStatus': 'error',
        'error': e.toString(),
        'cacheType': 'Hive',
        'persistentStorage': true,
      };
    }
  }

  @override
  Future<void> clearExpiredCache() async {
    try {
      // HiveCacheManager 目前没有 clearExpiredCache 方法，使用 clear() 作为替代
      // TODO: 如果需要过期缓存管理，需要在 HiveCacheManager 中实现相应功能
      await _cacheManager.clear();
      debugPrint('Hive过期缓存清理完成（使用clear()方法替代）');
    } catch (e) {
      debugPrint('Hive过期缓存清理失败: $e');
    }
  }

  /// 获取Hive缓存管理器实例（用于高级操作）
  HiveCacheManager get cacheManager => _cacheManager;

  /// 获取缓存数据（通用）
  @override
  Future<dynamic> getCachedData(String cacheKey) async {
    try {
      final cachedData = _cacheManager.get<dynamic>(cacheKey);
      if (cachedData == null) return null;
      return cachedData;
    } catch (e) {
      debugPrint('❌ 获取缓存数据失败: $e');
      return null;
    }
  }

  /// 缓存数据（通用）
  @override
  Future<void> cacheData(String cacheKey, dynamic data,
      {required Duration ttl}) async {
    try {
      await _cacheManager.put(cacheKey, data, expiration: ttl);
      debugPrint('✅ 数据缓存成功: $cacheKey');
    } catch (e) {
      debugPrint('❌ 数据缓存失败: $e');
      // 缓存失败时不抛出异常，保持服务可用
    }
  }

  /// 关闭缓存（应用退出时调用）
  Future<void> dispose() async {
    await _cacheManager.close();
  }
}
