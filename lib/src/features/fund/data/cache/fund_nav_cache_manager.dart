import 'dart:async';
import 'dart:math' as math;

import 'package:hive_flutter/hive_flutter.dart';

import '../../models/fund_nav_data.dart';
import '../../../../core/utils/logger.dart';

/// 基金净值缓存管理器
///
/// 专门为基金净值数据设计的L1/L2缓存系统
/// 支持离线查看、智能缓存策略和性能优化
class FundNavCacheManager {
  /// 缓存配置
  late final NavCacheConfig _config;

  /// 单例实例
  static final FundNavCacheManager _instance = FundNavCacheManager._internal();

  /// 工厂构造函数，返回单例实例
  factory FundNavCacheManager() => _instance;

  /// 初始化构造函数
  FundNavCacheManager._internal() {
    _config = NavCacheConfig();
    _initialize();
  }

  /// L1内存缓存 (快速访问)
  final Map<String, CachedNavData> _l1Cache = {};

  /// L1缓存大小限制
  static const int _maxL1CacheSize = 100;

  /// Hive缓存盒 (L2持久化缓存)
  late Box<Map<dynamic, dynamic>> _navCacheBox;

  /// 缓存统计
  final NavCacheStatistics _statistics = NavCacheStatistics();

  /// 清理定时器
  Timer? _cleanupTimer;

  /// 初始化管理器
  Future<void> _initialize() async {
    try {
      // 打开Hive缓存盒
      _navCacheBox =
          await Hive.openBox<Map<dynamic, dynamic>>('fund_nav_cache');

      // 启动清理定时器
      _startCleanupTimer();

      // 初始化时从Hive加载热点数据到L1缓存
      await _preloadHotData();

      AppLogger.info('FundNavCacheManager initialized successfully');
    } catch (e) {
      AppLogger.error(
          'Failed to initialize FundNavCacheManager', e, StackTrace.current);
      rethrow;
    }
  }

  /// 存储净值数据
  ///
  /// [navData] 要存储的净值数据
  /// 返回存储是否成功
  Future<bool> storeNavData(FundNavData navData) async {
    try {
      final stopwatch = Stopwatch()..start();

      // 1. 存储到L1缓存
      _storeToL1Cache(navData);

      // 2. 异步存储到L2缓存 (Hive)
      final l2Success = await _storeToL2Cache(navData);

      // 3. 更新统计信息
      _statistics.recordStore(stopwatch.elapsed, true);

      stopwatch.stop();
      AppLogger.debug(
          'Stored NAV data for fund ${navData.fundCode} in ${stopwatch.elapsedMilliseconds}ms');

      return l2Success;
    } catch (e) {
      _statistics.recordStore(Duration.zero, false);
      AppLogger.error('Failed to store NAV data for fund ${navData.fundCode}',
          e, StackTrace.current);
      return false;
    }
  }

  /// 获取净值数据
  ///
  /// [fundCode] 基金代码
  /// 返回净值数据，如果缓存中不存在则返回null
  Future<FundNavData?> getNavData(String fundCode) async {
    try {
      final stopwatch = Stopwatch()..start();

      // 1. 首先从L1缓存获取
      final l1Data = _getFromL1Cache(fundCode);
      if (l1Data != null) {
        _statistics.recordHit(stopwatch.elapsed, CacheLevel.l1);
        AppLogger.debug('L1 cache hit for fund $fundCode');
        return l1Data.navData;
      }

      // 2. 从L2缓存获取
      final l2Data = await _getFromL2Cache(fundCode);
      if (l2Data != null) {
        _statistics.recordHit(stopwatch.elapsed, CacheLevel.l2);

        // 将L2数据加载到L1缓存
        _storeToL1Cache(l2Data);

        AppLogger.debug('L2 cache hit for fund $fundCode');
        return l2Data;
      }

      // 3. 缓存未命中
      _statistics.recordMiss(stopwatch.elapsed);
      AppLogger.debug('Cache miss for fund $fundCode');
      return null;
    } catch (e) {
      AppLogger.error(
          'Failed to get NAV data for fund $fundCode', e, StackTrace.current);
      return null;
    }
  }

  /// 批量获取净值数据
  Future<Map<String, FundNavData>> getBatchNavData(
      List<String> fundCodes) async {
    final stopwatch = Stopwatch()..start();
    final results = <String, FundNavData>{};
    final l1Hits = <String>[];
    final l2Hits = <String>[];
    final misses = <String>[];

    try {
      for (final fundCode in fundCodes) {
        // 1. 尝试L1缓存
        final l1Data = _getFromL1Cache(fundCode);
        if (l1Data != null) {
          results[fundCode] = l1Data.navData;
          l1Hits.add(fundCode);
          continue;
        }

        // 2. 尝试L2缓存
        final l2Data = await _getFromL2Cache(fundCode);
        if (l2Data != null) {
          results[fundCode] = l2Data;
          _storeToL1Cache(l2Data); // 提升到L1缓存
          l2Hits.add(fundCode);
        } else {
          misses.add(fundCode);
        }
      }

      // 更新统计信息
      _statistics.recordBatchHit(
          stopwatch.elapsed, l1Hits.length, l2Hits.length, misses.length);

      AppLogger.debug(
          'Batch cache retrieval: ${l1Hits.length} L1 hits, ${l2Hits.length} L2 hits, ${misses.length} misses');

      return results;
    } catch (e) {
      AppLogger.error('Failed to get batch NAV data', e, StackTrace.current);
      return {};
    }
  }

  /// 获取历史净值数据
  Future<List<FundNavData>> getHistoricalNavData(
    String fundCode, {
    int limit = 30,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final historicalKey = _buildHistoricalKey(fundCode);
      final historicalData = _navCacheBox.get(historicalKey);

      if (historicalData == null) {
        return [];
      }

      final navDataList = <FundNavData>[];
      final records = historicalData['records'] as List<dynamic>? ?? [];

      for (final record in records) {
        if (record is Map<String, dynamic>) {
          final navData = FundNavData.fromJson(record);

          // 日期过滤
          if (startDate != null && navData.navDate.isBefore(startDate))
            continue;
          if (endDate != null && navData.navDate.isAfter(endDate)) continue;

          navDataList.add(navData);
        }
      }

      // 按日期降序排序并限制数量
      navDataList.sort((a, b) => b.navDate.compareTo(a.navDate));
      return navDataList.take(limit).toList();
    } catch (e) {
      AppLogger.error('Failed to get historical NAV data for fund $fundCode', e,
          StackTrace.current);
      return [];
    }
  }

  /// 存储历史净值数据
  Future<bool> storeHistoricalNavData(
      String fundCode, List<FundNavData> navDataList) async {
    try {
      final historicalKey = _buildHistoricalKey(fundCode);
      final existingData =
          _navCacheBox.get(historicalKey) ?? <String, dynamic>{};

      // 合并现有数据
      final existingRecords = existingData['records'] as List<dynamic>? ?? [];
      final newRecords = navDataList.map((data) => data.toJson()).toList();

      // 去重并合并
      final allRecords = <Map<String, dynamic>>[];
      final seenDates = <String>{};

      // 添加现有记录
      for (final record in existingRecords) {
        if (record is Map<String, dynamic>) {
          final dateStr = record['navDate'] as String?;
          if (dateStr != null && !seenDates.contains(dateStr)) {
            allRecords.add(record);
            seenDates.add(dateStr);
          }
        }
      }

      // 添加新记录
      for (final record in newRecords) {
        final dateStr = record['navDate'] as String?;
        if (dateStr != null && !seenDates.contains(dateStr)) {
          allRecords.add(record);
          seenDates.add(dateStr);
        }
      }

      // 按日期排序
      allRecords.sort(
          (a, b) => (b['navDate'] as String).compareTo(a['navDate'] as String));

      // 限制历史记录数量
      final maxHistoricalRecords = _config.maxHistoricalRecords;
      if (allRecords.length > maxHistoricalRecords) {
        allRecords.removeRange(maxHistoricalRecords, allRecords.length);
      }

      final historicalData = {
        'fundCode': fundCode,
        'records': allRecords,
        'lastUpdated': DateTime.now().toIso8601String(),
        'recordCount': allRecords.length,
      };

      await _navCacheBox.put(historicalKey, historicalData);
      AppLogger.debug(
          'Stored ${allRecords.length} historical records for fund $fundCode');

      return true;
    } catch (e) {
      AppLogger.error('Failed to store historical NAV data for fund $fundCode',
          e, StackTrace.current);
      return false;
    }
  }

  /// 存储到L1缓存
  void _storeToL1Cache(FundNavData navData) {
    final cacheKey = navData.fundCode;
    final cachedData = CachedNavData(
      navData: navData,
      cachedAt: DateTime.now(),
      accessCount: 0,
      lastAccessed: DateTime.now(),
    );

    _l1Cache[cacheKey] = cachedData;

    // 如果缓存已满，执行LRU清理
    if (_l1Cache.length > _maxL1CacheSize) {
      _evictLeastRecentlyUsed();
    }
  }

  /// 从L1缓存获取
  CachedNavData? _getFromL1Cache(String fundCode) {
    final cachedData = _l1Cache[fundCode];
    if (cachedData == null) {
      return null;
    }

    // 检查是否过期
    if (DateTime.now().difference(cachedData.cachedAt) > _config.l1Expiration) {
      _l1Cache.remove(fundCode);
      return null;
    }

    // 更新访问信息
    cachedData.accessCount++;
    cachedData.lastAccessed = DateTime.now();

    return cachedData;
  }

  /// 存储到L2缓存
  Future<bool> _storeToL2Cache(FundNavData navData) async {
    try {
      final cacheKey = _buildCacheKey(navData.fundCode);
      final cacheData = {
        'navData': navData.toJson(),
        'cachedAt': DateTime.now().toIso8601String(),
        'accessCount': 0,
        'lastAccessed': DateTime.now().toIso8601String(),
      };

      await _navCacheBox.put(cacheKey, cacheData);
      return true;
    } catch (e) {
      AppLogger.error('Failed to store to L2 cache', e, StackTrace.current);
      return false;
    }
  }

  /// 从L2缓存获取
  Future<FundNavData?> _getFromL2Cache(String fundCode) async {
    try {
      final cacheKey = _buildCacheKey(fundCode);
      final cacheData = _navCacheBox.get(cacheKey);

      if (cacheData == null) {
        return null;
      }

      final cachedAt = DateTime.parse(cacheData['cachedAt'] as String);

      // 检查是否过期
      if (DateTime.now().difference(cachedAt) > _config.l2Expiration) {
        await _navCacheBox.delete(cacheKey);
        return null;
      }

      // 更新访问信息
      cacheData['accessCount'] = (cacheData['accessCount'] as int? ?? 0) + 1;
      cacheData['lastAccessed'] = DateTime.now().toIso8601String();
      await _navCacheBox.put(cacheKey, cacheData);

      return FundNavData.fromJson(cacheData['navData'] as Map<String, dynamic>);
    } catch (e) {
      AppLogger.error('Failed to get from L2 cache', e, StackTrace.current);
      return null;
    }
  }

  /// LRU清理：移除最少使用的缓存项
  void _evictLeastRecentlyUsed() {
    if (_l1Cache.isEmpty) return;

    // 找到最少使用的项
    String? lruKey;
    DateTime? oldestAccess;

    for (final entry in _l1Cache.entries) {
      if (oldestAccess == null ||
          entry.value.lastAccessed.isBefore(oldestAccess)) {
        oldestAccess = entry.value.lastAccessed;
        lruKey = entry.key;
      }
    }

    if (lruKey != null) {
      _l1Cache.remove(lruKey);
      AppLogger.debug('Evicted LRU cache item: $lruKey');
    }
  }

  /// 预加载热点数据
  Future<void> _preloadHotData() async {
    try {
      // 基于访问频率预加载热点数据
      final keys = _navCacheBox.keys.whereType<String>().toList();

      // 获取最近访问的数据
      final recentData = <Map<String, dynamic>>[];
      for (final key in keys) {
        if (key.startsWith('nav_')) {
          final data = _navCacheBox.get(key);
          if (data != null) {
            recentData.add(data as Map<String, dynamic>);
          }
        }
      }

      // 按访问次数排序
      recentData.sort((a, b) {
        final aCount = a['accessCount'] as int? ?? 0;
        final bCount = b['accessCount'] as int? ?? 0;
        return bCount.compareTo(aCount);
      });

      // 预加载热点数据到L1缓存
      final preloadCount = math.min(_config.preloadCount, recentData.length);
      for (int i = 0; i < preloadCount; i++) {
        try {
          final data = recentData[i];
          final navData =
              FundNavData.fromJson(data['navData'] as Map<String, dynamic>);

          final cachedData = CachedNavData(
            navData: navData,
            cachedAt: DateTime.parse(data['cachedAt'] as String),
            accessCount: data['accessCount'] as int? ?? 0,
            lastAccessed: DateTime.parse(data['lastAccessed'] as String),
          );

          _l1Cache[navData.fundCode] = cachedData;
        } catch (e) {
          AppLogger.warn('Failed to preload NAV data: $e');
        }
      }

      AppLogger.info(
          'Preloaded ${_l1Cache.length} hot NAV data items to L1 cache');
    } catch (e) {
      AppLogger.error('Failed to preload hot NAV data', e, StackTrace.current);
    }
  }

  /// 构建缓存键
  String _buildCacheKey(String fundCode) => 'nav_$fundCode';

  /// 构建历史数据键
  String _buildHistoricalKey(String fundCode) => 'nav_history_$fundCode';

  /// 启动清理定时器
  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      _cleanupExpiredCache();
    });
  }

  /// 清理过期缓存
  Future<void> _cleanupExpiredCache() async {
    try {
      final now = DateTime.now();
      int cleanedCount = 0;

      // 清理L1缓存
      final expiredL1Keys = <String>[];
      for (final entry in _l1Cache.entries) {
        if (now.difference(entry.value.cachedAt) > _config.l1Expiration) {
          expiredL1Keys.add(entry.key);
        }
      }

      for (final key in expiredL1Keys) {
        _l1Cache.remove(key);
        cleanedCount++;
      }

      // 清理L2缓存
      final keys = _navCacheBox.keys.whereType<String>().toList();
      for (final key in keys) {
        if (key.startsWith('nav_')) {
          final data = _navCacheBox.get(key);
          if (data != null) {
            final cachedAt = DateTime.parse(data['cachedAt'] as String);
            if (now.difference(cachedAt) > _config.l2Expiration) {
              await _navCacheBox.delete(key);
              cleanedCount++;
            }
          }
        }
      }

      if (cleanedCount > 0) {
        AppLogger.debug('Cleaned up $cleanedCount expired NAV cache items');
      }
    } catch (e) {
      AppLogger.error(
          'Failed to cleanup expired NAV cache', e, StackTrace.current);
    }
  }

  /// 清理指定基金的缓存
  Future<void> clearCacheForFund(String fundCode) async {
    try {
      // 清理L1缓存
      _l1Cache.remove(fundCode);

      // 清理L2缓存
      final cacheKey = _buildCacheKey(fundCode);
      await _navCacheBox.delete(cacheKey);

      // 清理历史缓存
      final historicalKey = _buildHistoricalKey(fundCode);
      await _navCacheBox.delete(historicalKey);

      AppLogger.info('Cleared cache for fund $fundCode');
    } catch (e) {
      AppLogger.error(
          'Failed to clear cache for fund $fundCode', e, StackTrace.current);
    }
  }

  /// 清理所有缓存
  Future<void> clearAllCache() async {
    try {
      // 清理L1缓存
      _l1Cache.clear();

      // 清理L2缓存
      await _navCacheBox.clear();

      AppLogger.info('Cleared all NAV cache');
    } catch (e) {
      AppLogger.error('Failed to clear all NAV cache', e, StackTrace.current);
    }
  }

  /// 获取缓存统计信息
  NavCacheStatistics get statistics => _statistics;

  /// 获取缓存健康状态
  Map<String, dynamic> getCacheHealthStatus() {
    return {
      'l1Cache': {
        'size': _l1Cache.length,
        'maxSize': _maxL1CacheSize,
        'usage':
            '${(_l1Cache.length / _maxL1CacheSize * 100).toStringAsFixed(1)}%',
      },
      'l2Cache': {
        'size': _navCacheBox.length,
        'isHealthy': _navCacheBox.isOpen,
      },
      'statistics': _statistics.toJson(),
      'config': _config.toJson(),
    };
  }

  /// 更新缓存配置
  void updateConfig(NavCacheConfig config) {
    _config.updateFrom(config);
    AppLogger.info('Updated NAV cache configuration');
  }

  /// 释放资源
  Future<void> dispose() async {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;

    await _navCacheBox.close();
    _l1Cache.clear();

    AppLogger.info('FundNavCacheManager disposed');
  }
}

/// 缓存的净值数据
class CachedNavData {
  /// 基金净值数据
  final FundNavData navData;

  /// 缓存时间
  final DateTime cachedAt;

  /// 访问次数
  int accessCount;

  /// 最后访问时间
  DateTime lastAccessed;

  /// 创建缓存数据
  CachedNavData({
    required this.navData,
    required this.cachedAt,
    required this.accessCount,
    required this.lastAccessed,
  });
}

/// 缓存级别
enum CacheLevel {
  /// L1内存缓存级别
  l1,

  /// L2磁盘缓存级别
  l2,
}

/// 缓存配置
class NavCacheConfig {
  /// L1缓存过期时间
  Duration l1Expiration;

  /// L2缓存过期时间
  Duration l2Expiration;

  /// 最大历史记录数量
  int maxHistoricalRecords;

  /// 预加载数量
  int preloadCount;

  /// 是否启用压缩
  bool enableCompression;

  /// 创建缓存配置
  NavCacheConfig({
    this.l1Expiration = const Duration(minutes: 5),
    this.l2Expiration = const Duration(hours: 24),
    this.maxHistoricalRecords = 365, // 一年的历史数据
    this.preloadCount = 20,
    this.enableCompression = true,
  });

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'l1ExpirationMinutes': l1Expiration.inMinutes,
      'l2ExpirationHours': l2Expiration.inHours,
      'maxHistoricalRecords': maxHistoricalRecords,
      'preloadCount': preloadCount,
      'enableCompression': enableCompression,
    };
  }

  /// 从其他配置更新当前配置
  void updateFrom(NavCacheConfig other) {
    l1Expiration = other.l1Expiration;
    l2Expiration = other.l2Expiration;
    maxHistoricalRecords = other.maxHistoricalRecords;
    preloadCount = other.preloadCount;
    enableCompression = other.enableCompression;
  }
}

/// 缓存统计信息
class NavCacheStatistics {
  /// 总请求数
  int totalRequests = 0;

  /// L1缓存命中次数
  int l1Hits = 0;

  /// L2缓存命中次数
  int l2Hits = 0;

  /// 缓存未命中次数
  int misses = 0;

  /// 总存储次数
  int totalStores = 0;

  /// 成功存储次数
  int successfulStores = 0;

  /// 总存储时间（毫秒）
  int totalStoreTime = 0;

  /// 总访问时间（毫秒）
  int totalAccessTime = 0;

  /// 记录缓存命中
  void recordHit(Duration accessTime, CacheLevel level) {
    totalRequests++;
    totalAccessTime += accessTime.inMilliseconds;

    if (level == CacheLevel.l1) {
      l1Hits++;
    } else {
      l2Hits++;
    }
  }

  /// 记录批量缓存命中
  void recordBatchHit(
      Duration accessTime, int l1HitCount, int l2HitCount, int missCount) {
    totalRequests += l1HitCount + l2HitCount + missCount;
    totalAccessTime += accessTime.inMilliseconds;
    l1Hits += l1HitCount;
    l2Hits += l2HitCount;
    misses += missCount;
  }

  /// 记录缓存未命中
  void recordMiss(Duration accessTime) {
    totalRequests++;
    misses++;
    totalAccessTime += accessTime.inMilliseconds;
  }

  /// 记录存储操作
  void recordStore(Duration storeTime, bool success) {
    totalStores++;
    totalStoreTime += storeTime.inMilliseconds;

    if (success) {
      successfulStores++;
    }
  }

  /// 缓存命中率
  double get hitRate {
    if (totalRequests == 0) return 0.0;
    return (l1Hits + l2Hits) / totalRequests;
  }

  /// L1缓存命中率
  double get l1HitRate {
    if (totalRequests == 0) return 0.0;
    return l1Hits / totalRequests;
  }

  /// L2缓存命中率
  double get l2HitRate {
    if (totalRequests == 0) return 0.0;
    return l2Hits / totalRequests;
  }

  /// 平均访问时间
  double get averageAccessTime {
    if (totalRequests == 0) return 0.0;
    return totalAccessTime / totalRequests;
  }

  /// 平均存储时间
  double get averageStoreTime {
    if (totalStores == 0) return 0.0;
    return totalStoreTime / totalStores;
  }

  /// 存储成功率
  double get storeSuccessRate {
    if (totalStores == 0) return 0.0;
    return successfulStores / totalStores;
  }

  /// 重置统计信息
  void reset() {
    totalRequests = 0;
    l1Hits = 0;
    l2Hits = 0;
    misses = 0;
    totalStores = 0;
    successfulStores = 0;
    totalStoreTime = 0;
    totalAccessTime = 0;
  }

  /// 转换为JSON格式
  Map<String, dynamic> toJson() {
    return {
      'totalRequests': totalRequests,
      'l1Hits': l1Hits,
      'l2Hits': l2Hits,
      'misses': misses,
      'hitRate': hitRate,
      'l1HitRate': l1HitRate,
      'l2HitRate': l2HitRate,
      'averageAccessTime': averageAccessTime.round(),
      'totalStores': totalStores,
      'successfulStores': successfulStores,
      'storeSuccessRate': storeSuccessRate,
      'averageStoreTime': averageStoreTime.round(),
    };
  }

  /// 转换为字符串格式
  @override
  String toString() {
    return 'NavCacheStatistics(hitRate: ${(hitRate * 100).toStringAsFixed(1)}%, avgAccessTime: ${averageAccessTime.round()}ms, stores: $successfulStores/$totalStores)';
  }
}
