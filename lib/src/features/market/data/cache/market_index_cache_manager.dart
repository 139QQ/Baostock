import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import '../../../../core/utils/logger.dart';
import '../../models/market_index_data.dart';

/// 市场指数缓存管理器
///
/// 负责市场指数数据的L1(内存)和L2(Hive)缓存管理
class MarketIndexCacheManager {
  /// 缓存配置
  final MarketIndexCacheConfig _config;

  /// L1内存缓存 (使用LinkedHashMap实现高效LRU)
  final LinkedHashMap<String, CachedIndexData> _memoryCache =
      LinkedHashMap<String, CachedIndexData>();

  /// 缓存统计信息
  CacheStatistics _statistics = CacheStatistics();

  /// 定时清理定时器
  Timer? _cleanupTimer;

  /// 简化的读写锁 (用于并发安全)
  bool _isLocked = false;

  /// 预取定时器
  Timer? _prefetchTimer;

  /// 预取队列
  final Queue<String> _prefetchQueue = Queue<String>();

  /// 访问模式跟踪
  final Map<String, CacheAccessPattern> _accessPatterns = {};

  /// 构造函数
  MarketIndexCacheManager({
    MarketIndexCacheConfig? config,
  }) : _config = config ?? const MarketIndexCacheConfig() {
    _startCleanupTimer();
    _startPrefetchTimer();
  }

  /// 获取锁
  Future<void> _acquireLock() async {
    while (_isLocked) {
      await Future.delayed(Duration(milliseconds: 1));
    }
    _isLocked = true;
  }

  /// 释放锁
  void _releaseLock() {
    _isLocked = false;
  }

  /// 缓存指数数据 (优化版)
  Future<void> cacheIndexData(MarketIndexData data) async {
    await _acquireLock();
    try {
      final indexCode = data.code;
      final now = DateTime.now();

      // 1. 缓存到L1内存 (优化的LRU实现)
      _cacheToMemoryOptimized(data, now);

      // 2. 更新访问模式
      _updateAccessPattern(indexCode, now);

      // 3. 更新统计信息
      _statistics.recordCacheOperation(CacheOperation.write);

      AppLogger.debug('Cached index data for $indexCode');
    } finally {
      _releaseLock();
    }
  }

  /// 优化的内存缓存 (高效的LRU实现)
  void _cacheToMemoryOptimized(MarketIndexData data, DateTime timestamp) {
    // 如果数据已存在，先删除再添加 (LRU更新)
    if (_memoryCache.containsKey(data.code)) {
      _memoryCache.remove(data.code);
    }

    final cachedData = CachedIndexData(
      data: data,
      timestamp: timestamp,
      accessCount: _memoryCache[data.code]?.accessCount ?? 0,
      lastAccessTime: timestamp,
    );

    _memoryCache[data.code] = cachedData;

    // 检查内存缓存大小限制
    _enforceMemoryCacheLimitOptimized();
  }

  /// 检查并强制执行内存缓存限制
  void _enforceMemoryCacheLimitOptimized() {
    while (_memoryCache.length > _config.maxMemoryCacheSize) {
      final oldestKey = _memoryCache.keys.first;
      _memoryCache.remove(oldestKey);
    }
  }

  /// 获取缓存的指数数据 (优化版)
  Future<MarketIndexData?> getCachedIndexData(String indexCode) async {
    await _acquireLock();
    try {
      final now = DateTime.now();

      // 1. 首先检查L1内存缓存 (优化的LRU访问)
      final memoryData = _getFromMemoryOptimized(indexCode);
      if (memoryData != null) {
        // 更新访问模式
        _updateAccessPattern(indexCode, now);
        _statistics.recordCacheOperation(CacheOperation.readMemory);
        return memoryData;
      }

      // 2. 缓存未命中 - 加入预取队列
      _addToPrefetchQueue(indexCode);
      _statistics.recordCacheOperation(CacheOperation.miss);
      return null;
    } finally {
      _releaseLock();
    }
  }

  /// 优化的从内存获取数据 (O(1) LRU更新)
  MarketIndexData? _getFromMemoryOptimized(String indexCode) {
    final cachedData = _memoryCache.remove(indexCode);
    if (cachedData == null) return null;

    // 检查是否过期
    if (_isExpired(cachedData.timestamp, _config.memoryCacheExpiration)) {
      return null;
    }

    // 更新访问统计并重新添加到末尾 (LRU更新)
    final updatedData = cachedData.copyWith(
      accessCount: cachedData.accessCount + 1,
      lastAccessTime: DateTime.now(),
    );
    _memoryCache[indexCode] = updatedData;

    return cachedData.data;
  }

  /// 检查数据是否过期
  bool _isExpired(DateTime timestamp, Duration expiration) {
    return DateTime.now().difference(timestamp) > expiration;
  }

  /// 批量获取缓存的指数数据
  Future<Map<String, MarketIndexData>> getBatchCachedIndexData(
      List<String> indexCodes) async {
    final results = <String, MarketIndexData>{};

    for (final code in indexCodes) {
      final data = await getCachedIndexData(code);
      if (data != null) {
        results[code] = data;
      }
    }

    return results;
  }

  /// 更新访问模式
  void _updateAccessPattern(String indexCode, DateTime accessTime) {
    final pattern = _accessPatterns.putIfAbsent(
        indexCode, () => CacheAccessPattern(indexCode));
    pattern.recordAccess(accessTime);
  }

  /// 添加到预取队列
  void _addToPrefetchQueue(String indexCode) {
    if (!_prefetchQueue.contains(indexCode) && _prefetchQueue.length < 10) {
      _prefetchQueue.add(indexCode);
    }
  }

  /// 启动清理定时器
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(_config.cleanupInterval, (_) {
      _performCleanup();
    });
  }

  /// 启动预取定时器
  void _startPrefetchTimer() {
    _prefetchTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _performPrefetching();
    });
  }

  /// 执行清理操作
  void _performCleanup() {
    _acquireLock().then((_) {
      try {
        final now = DateTime.now();
        final expiredKeys = <String>[];

        _memoryCache.forEach((key, value) {
          if (_isExpired(value.timestamp, _config.memoryCacheExpiration)) {
            expiredKeys.add(key);
          }
        });

        for (final key in expiredKeys) {
          _memoryCache.remove(key);
        }

        _statistics.lastCleanupTime = now;
        AppLogger.debug(
            'Cleaned up ${expiredKeys.length} expired cache entries');
      } finally {
        _releaseLock();
      }
    });
  }

  /// 执行预取操作
  void _performPrefetching() {
    if (_prefetchQueue.isEmpty) return;

    _acquireLock().then((_) async {
      try {
        final maxBatchSize = math.min(5, _prefetchQueue.length);
        final prefetchBatch = <String>[];

        for (int i = 0; i < maxBatchSize && _prefetchQueue.isNotEmpty; i++) {
          prefetchBatch.add(_prefetchQueue.removeFirst());
        }

        // 预取逻辑（这里简化处理）
        for (final indexCode in prefetchBatch) {
          final pattern = _accessPatterns[indexCode];
          if (pattern != null &&
              pattern.isHot &&
              !_memoryCache.containsKey(indexCode)) {
            // 对于热门数据，可以从外部数据源预取（这里简化）
            AppLogger.debug('Prefetching hot index: $indexCode');
          }
        }
      } finally {
        _releaseLock();
      }
    });
  }

  /// 获取缓存统计信息
  CacheStatistics getStatistics() {
    _statistics.memoryCacheSize = _memoryCache.length;
    return _statistics;
  }

  /// 获取预取统计
  PrefetchStatistics getPrefetchStatistics() {
    return PrefetchStatistics(
      queueSize: _prefetchQueue.length,
      accessPatternsCount: _accessPatterns.length,
      hotIndicesCount: _accessPatterns.values.where((p) => p.isHot).length,
      coldIndicesCount: _accessPatterns.values.where((p) => p.isCold).length,
    );
  }

  /// 清空预取队列和访问模式
  void clearPrefetchData() {
    _prefetchQueue.clear();
    _accessPatterns.clear();
    AppLogger.debug('Cleared prefetch data and access patterns');
  }

  /// 销毁缓存管理器
  Future<void> dispose() async {
    _cleanupTimer?.cancel();
    _prefetchTimer?.cancel();
    _memoryCache.clear();
    _prefetchQueue.clear();
    _accessPatterns.clear();
    AppLogger.debug('MarketIndexCacheManager disposed');
  }
}

/// 缓存数据包装类
class CachedIndexData {
  final MarketIndexData data;
  final DateTime timestamp;
  final int accessCount;
  final DateTime lastAccessTime;

  const CachedIndexData({
    required this.data,
    required this.timestamp,
    required this.accessCount,
    required this.lastAccessTime,
  });

  /// 复制并修改部分属性
  CachedIndexData copyWith({
    MarketIndexData? data,
    DateTime? timestamp,
    int? accessCount,
    DateTime? lastAccessTime,
  }) {
    return CachedIndexData(
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      accessCount: accessCount ?? this.accessCount,
      lastAccessTime: lastAccessTime ?? this.lastAccessTime,
    );
  }
}

/// 访问模式跟踪
class CacheAccessPattern {
  final String indexCode;
  final List<DateTime> accessHistory = [];
  DateTime lastAccess = DateTime.now();
  int accessCount = 0;

  CacheAccessPattern(this.indexCode);

  void recordAccess(DateTime accessTime) {
    accessHistory.add(accessTime);
    lastAccess = accessTime;
    accessCount++;

    // 保持历史记录在合理范围内
    if (accessHistory.length > 100) {
      accessHistory.removeRange(0, accessHistory.length - 100);
    }
  }

  /// 获取访问频率 (每小时访问次数)
  double getAccessFrequency() {
    if (accessHistory.isEmpty) return 0.0;

    final now = DateTime.now();
    final oneHourAgo = now.subtract(Duration(hours: 1));
    final recentAccesses =
        accessHistory.where((time) => time.isAfter(oneHourAgo));

    return recentAccesses.length.toDouble();
  }

  /// 是否为热门数据
  bool get isHot => getAccessFrequency() > 5.0; // 每小时超过5次访问

  /// 是否为冷数据
  bool get isCold =>
      getAccessFrequency() < 0.5 &&
      DateTime.now().difference(lastAccess).inHours > 24;
}

/// 预取统计信息
class PrefetchStatistics {
  final int queueSize;
  final int accessPatternsCount;
  final int hotIndicesCount;
  final int coldIndicesCount;

  const PrefetchStatistics({
    required this.queueSize,
    required this.accessPatternsCount,
    required this.hotIndicesCount,
    required this.coldIndicesCount,
  });

  @override
  String toString() {
    return 'PrefetchStats(queue: $queueSize, patterns: $accessPatternsCount, hot: $hotIndicesCount, cold: $coldIndicesCount)';
  }
}

/// 缓存统计信息
class CacheStatistics {
  int memoryHits = 0;
  int hiveHits = 0;
  int misses = 0;
  int writes = 0;
  int deletes = 0;
  int errors = 0;
  int memoryCacheSize = 0;
  DateTime lastCleanupTime = DateTime.now();

  /// 记录缓存操作
  void recordCacheOperation(CacheOperation operation) {
    switch (operation) {
      case CacheOperation.readMemory:
        memoryHits++;
        break;
      case CacheOperation.readHive:
        hiveHits++;
        break;
      case CacheOperation.miss:
        misses++;
        break;
      case CacheOperation.write:
        writes++;
        break;
      case CacheOperation.delete:
        deletes++;
        break;
      case CacheOperation.error:
        errors++;
        break;
    }
  }

  /// 总操作数
  int get totalOperations =>
      memoryHits + hiveHits + misses + writes + deletes + errors;

  /// 内存命中率
  double get memoryHitRate {
    final totalReads = memoryHits + hiveHits + misses;
    return totalReads > 0 ? memoryHits / totalReads : 0.0;
  }

  /// 总体命中率
  double get overallHitRate {
    final totalReads = memoryHits + hiveHits + misses;
    final hits = memoryHits + hiveHits;
    return totalReads > 0 ? hits / totalReads : 0.0;
  }
}

/// 缓存操作类型
enum CacheOperation {
  readMemory,
  readHive,
  miss,
  write,
  delete,
  error,
}

/// 市场指数缓存配置
class MarketIndexCacheConfig {
  /// 最大内存缓存条目数
  final int maxMemoryCacheSize;

  /// 内存缓存过期时间
  final Duration memoryCacheExpiration;

  /// Hive缓存过期时间
  final Duration hiveCacheExpiration;

  /// 清理间隔
  final Duration cleanupInterval;

  const MarketIndexCacheConfig({
    this.maxMemoryCacheSize = 100,
    this.memoryCacheExpiration = const Duration(minutes: 5),
    this.hiveCacheExpiration = const Duration(hours: 24),
    this.cleanupInterval = const Duration(minutes: 1),
  });
}
