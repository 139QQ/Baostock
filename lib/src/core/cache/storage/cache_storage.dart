/// 缓存存储实现
///
/// 提供多种存储后端的实现，包括：
/// - 内存存储（用于开发和测试）
/// - Hive 存储文件存储（生产环境）
/// - 混合存储（内存 + 文件）
library cache_storage;

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../interfaces/i_unified_cache_service.dart';

part 'cache_storage.g.dart';

// ============================================================================
// 缓存环境枚举
// ============================================================================

/// 缓存环境
enum CacheEnvironment {
  development,
  testing,
  staging,
  production,
}

// ============================================================================
// Hive 缓存存储实现
// ============================================================================

/// Hive 缓存存储
///
/// 基于 Hive 的本地文件存储实现
class HiveCacheStorage implements ICacheStorage {
  final String _boxName;
  final bool _testMode;
  late LazyBox<BoxCacheEntry> _box;
  bool _isInitialized = false;

  HiveCacheStorage({
    String boxName = 'unified_cache',
    bool testMode = false,
  })  : _boxName = boxName,
        _testMode = testMode;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (_testMode || kDebugMode) {
        // 测试模式或调试模式：使用本地目录
        final testDir = Directory('./temp_hive');
        if (!await testDir.exists()) {
          await testDir.create(recursive: true);
        }

        // 尝试初始化Hive
        try {
          Hive.init(testDir.path);
        } catch (e) {
          // 如果Hive已经初始化，忽略错误
          if (!e.toString().contains('already initialized')) {
            rethrow;
          }
        }
      } else {
        // 生产模式：初始化文件系统 Hive
        try {
          final appDocumentDir = await getApplicationDocumentsDirectory();
          try {
            Hive.init(appDocumentDir.path);
          } catch (e) {
            // 如果Hive已经初始化，忽略错误
            if (!e.toString().contains('already initialized')) {
              rethrow;
            }
          }
        } catch (e) {
          // 如果path_provider失败，fallback到本地目录
          final fallbackDir = Directory('./fallback_hive');
          if (!await fallbackDir.exists()) {
            await fallbackDir.create(recursive: true);
          }
          try {
            Hive.init(fallbackDir.path);
          } catch (e2) {
            // 如果Hive已经初始化，忽略错误
            if (!e2.toString().contains('already initialized')) {
              rethrow;
            }
          }
          print('⚠️ path_provider失败，使用fallback目录: $e');
        }
      }

      // 注册适配器
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(BoxCacheEntryAdapter());
      }

      // 打开缓存盒子
      _box = await Hive.openLazyBox<BoxCacheEntry>(_boxName);

      _isInitialized = true;
    } catch (e) {
      throw CacheStorageException('Failed to initialize Hive storage: $e');
    }
  }

  @override
  Future<void> store(String key, CacheEntry entry) async {
    _ensureInitialized();

    try {
      final boxEntry = BoxCacheEntry.fromCacheEntry(entry);
      await _box.put(key, boxEntry);
    } catch (e) {
      throw CacheStorageException('Failed to store entry for key $key: $e');
    }
  }

  @override
  Future<CacheEntry?> retrieve(String key) async {
    _ensureInitialized();

    try {
      final boxEntry = await _box.get(key);
      return boxEntry?.toCacheEntry();
    } catch (e) {
      throw CacheStorageException('Failed to retrieve entry for key $key: $e');
    }
  }

  @override
  Future<bool> delete(String key) async {
    _ensureInitialized();

    try {
      await _box.delete(key);
      return true;
    } catch (e) {
      throw CacheStorageException('Failed to delete entry for key $key: $e');
    }
  }

  @override
  Future<int> deleteBatch(Iterable<String> keys) async {
    _ensureInitialized();

    try {
      int deletedCount = 0;
      for (final key in keys) {
        if (_box.containsKey(key)) {
          await _box.delete(key);
          deletedCount++;
        }
      }
      return deletedCount;
    } catch (e) {
      throw CacheStorageException('Failed to delete batch: $e');
    }
  }

  @override
  Future<int> deleteByPattern(String pattern) async {
    _ensureInitialized();

    try {
      final allKeys = _box.keys.cast<String>();
      final matchingKeys = _filterKeysByPattern(allKeys, pattern);
      return await deleteBatch(matchingKeys);
    } catch (e) {
      throw CacheStorageException('Failed to delete by pattern: $e');
    }
  }

  @override
  Future<void> clear() async {
    _ensureInitialized();

    try {
      await _box.clear();
    } catch (e) {
      throw CacheStorageException('Failed to clear storage: $e');
    }
  }

  @override
  Future<List<String>> getAllKeys() async {
    _ensureInitialized();

    try {
      return _box.keys.cast<String>().toList();
    } catch (e) {
      throw CacheStorageException('Failed to get all keys: $e');
    }
  }

  @override
  Future<StorageStatistics> getStorageStatistics() async {
    _ensureInitialized();

    try {
      final keys = _box.keys.cast<String>();
      int totalSize = 0;
      int compressedSavings = 0;
      final Map<String, int> fileSizes = {};

      for (final key in keys) {
        try {
          final entry = await _box.get(key);
          if (entry != null) {
            final metadata = CacheMetadata.fromJson(entry.metadataJson);
            final size = metadata.size;
            totalSize += size;

            if (metadata.compressed && metadata.originalSize != null) {
              compressedSavings += metadata.originalSize! - size;
            }

            fileSizes[key] = size;
          }
        } catch (e) {
          // 跳过损坏的条目
          continue;
        }
      }

      // 计算 Hive 文件大小（近似）
      final fileSize = await _calculateHiveFileSize();

      return StorageStatistics(
        totalKeys: keys.length,
        totalSize: totalSize,
        availableSpace: await _getAvailableSpace(),
        usageRatio: fileSize > 0 ? totalSize / fileSize : 0.0,
        shardStatistics: {
          'main': ShardStatistics(
            shardName: _boxName,
            keyCount: keys.length,
            size: totalSize,
            usageRatio: fileSize > 0 ? totalSize / fileSize : 0.0,
          ),
        },
      );
    } catch (e) {
      throw CacheStorageException('Failed to get storage statistics: $e');
    }
  }

  @override
  Future<void> close() async {
    _ensureInitialized();

    try {
      await _box.close();
      _isInitialized = false;
    } catch (e) {
      throw CacheStorageException('Failed to close storage: $e');
    }
  }

  /// Hive 特有方法：清理过期数据
  Future<int> clearExpired() async {
    _ensureInitialized();

    try {
      final now = DateTime.now();
      final expiredKeys = <String>[];
      final keys = _box.keys.cast<String>();

      for (final key in keys) {
        try {
          final entry = await _box.get(key);
          if (entry != null &&
              entry.expiresAtMillis != null &&
              now.isAfter(DateTime.fromMillisecondsSinceEpoch(
                  entry.expiresAtMillis!))) {
            expiredKeys.add(key);
          }
        } catch (e) {
          // 跳过损坏的条目
          expiredKeys.add(key);
        }
      }

      // 批量删除过期条目
      for (final key in expiredKeys) {
        await _box.delete(key);
      }

      return expiredKeys.length;
    } catch (e) {
      throw CacheStorageException('Failed to clear expired entries: $e');
    }
  }

  /// Hive 特有方法：压缩存储
  Future<void> compact() async {
    _ensureInitialized();

    try {
      await _box.compact();
    } catch (e) {
      throw CacheStorageException('Failed to compact storage: $e');
    }
  }

  /// Hive 特有方法：优化存储
  Future<void> optimize() async {
    _ensureInitialized();

    try {
      // 1. 清理过期数据
      await clearExpired();

      // 2. 压缩存储
      await compact();

      // 3. 清理损坏的条目
      await _cleanupCorruptedEntries();
    } catch (e) {
      throw CacheStorageException('Failed to optimize storage: $e');
    }
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
          'Hive storage not initialized. Call initialize() first.');
    }
  }

  List<String> _filterKeysByPattern(Iterable<String> keys, String pattern) {
    final regex = RegExp(pattern.replaceAll('*', '.*').replaceAll('?', '.'));
    return keys.where((key) => regex.hasMatch(key)).toList();
  }

  Future<int> _calculateHiveFileSize() async {
    try {
      if (_testMode) {
        // 测试模式下返回估算值
        return 1024 * 1024; // 1MB
      }

      final appDir = await getApplicationDocumentsDirectory();
      final hiveDir = Directory('${appDir.path}/hive_cache');
      if (!await hiveDir.exists()) return 0;

      final hiveFile = File('${hiveDir.path}/$_boxName.hive');
      if (await hiveFile.exists()) {
        return await hiveFile.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getAvailableSpace() async {
    try {
      if (_testMode) {
        return 1024 * 1024 * 1024; // 1GB in test mode
      }

      final appDocumentDir = await getApplicationDocumentsDirectory();
      try {
        // 尝试获取可用空间，如果失败则返回默认值
        return 1024 * 1024 * 1024; // 返回1GB作为默认值
      } catch (e) {
        return 1024 * 1024 * 1024; // 返回1GB作为默认值
      }
    } catch (e) {
      return 1024 * 1024 * 1024; // 1GB default
    }
  }

  Future<void> _cleanupCorruptedEntries() async {
    try {
      final keys = _box.keys.cast<String>();
      final corruptedKeys = <String>[];

      for (final key in keys) {
        try {
          await _box.get(key);
        } catch (e) {
          corruptedKeys.add(key);
        }
      }

      for (final key in corruptedKeys) {
        try {
          await _box.delete(key);
        } catch (e) {
          // 忽略删除失败
        }
      }
    } catch (e) {
      // 忽略清理错误
    }
  }
}

// ============================================================================
// 内存缓存存储实现
// ============================================================================

/// 内存缓存存储
///
/// 纯内存存储实现，用于测试和开发
class MemoryCacheStorage implements ICacheStorage {
  final Map<String, CacheEntry> _storage = {};
  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    _isInitialized = true;
  }

  @override
  Future<void> store(String key, CacheEntry entry) async {
    _ensureInitialized();
    _storage[key] = entry;
  }

  @override
  Future<CacheEntry?> retrieve(String key) async {
    _ensureInitialized();
    return _storage[key];
  }

  @override
  Future<bool> delete(String key) async {
    _ensureInitialized();
    return _storage.remove(key) != null;
  }

  @override
  Future<int> deleteBatch(Iterable<String> keys) async {
    _ensureInitialized();
    int count = 0;
    for (final key in keys) {
      if (_storage.remove(key) != null) {
        count++;
      }
    }
    return count;
  }

  @override
  Future<int> deleteByPattern(String pattern) async {
    _ensureInitialized();
    final matchingKeys = _filterKeysByPattern(_storage.keys, pattern);
    return await deleteBatch(matchingKeys);
  }

  @override
  Future<void> clear() async {
    _ensureInitialized();
    _storage.clear();
  }

  @override
  Future<List<String>> getAllKeys() async {
    _ensureInitialized();
    return _storage.keys.toList();
  }

  @override
  Future<StorageStatistics> getStorageStatistics() async {
    _ensureInitialized();

    int totalSize = 0;
    int compressedSavings = 0;

    for (final entry in _storage.values) {
      final metadata = entry.metadata;
      totalSize += metadata.size;
      if (metadata.compressed && metadata.originalSize != null) {
        compressedSavings += metadata.originalSize! - metadata.size;
      }
    }

    return StorageStatistics(
      totalKeys: _storage.length,
      totalSize: totalSize,
      availableSpace: 1024 * 1024 * 1024, // 1GB available in memory
      usageRatio: 0.1, // 10% usage assumption
    );
  }

  @override
  Future<void> close() async {
    _ensureInitialized();
    _storage.clear();
    _isInitialized = false;
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
          'Memory storage not initialized. Call initialize() first.');
    }
  }

  List<String> _filterKeysByPattern(Iterable<String> keys, String pattern) {
    final regex = RegExp(pattern.replaceAll('*', '.*').replaceAll('?', '.'));
    return keys.where((key) => regex.hasMatch(key)).toList();
  }
}

// ============================================================================
// 混合缓存存储实现
// ============================================================================

/// 混合缓存存储
///
/// 内存 + 文件的混合存储实现
class HybridCacheStorage implements ICacheStorage {
  final MemoryCacheStorage _memoryStorage;
  final HiveCacheStorage _persistentStorage;
  final int _maxMemoryEntries;

  HybridCacheStorage({
    MemoryCacheStorage? memoryStorage,
    HiveCacheStorage? persistentStorage,
    int maxMemoryEntries = 1000,
  })  : _memoryStorage = memoryStorage ?? MemoryCacheStorage(),
        _persistentStorage = persistentStorage ?? HiveCacheStorage(),
        _maxMemoryEntries = maxMemoryEntries;

  @override
  Future<void> initialize() async {
    await _memoryStorage.initialize();
    await _persistentStorage.initialize();
  }

  @override
  Future<void> store(String key, CacheEntry entry) async {
    // 1. 存储到持久层
    await _persistentStorage.store(key, entry);

    // 2. 存储到内存层
    await _memoryStorage.store(key, entry);

    // 3. 检查内存限制
    await _enforceMemoryLimit();
  }

  @override
  Future<CacheEntry?> retrieve(String key) async {
    // 1. 先从内存层获取
    var entry = await _memoryStorage.retrieve(key);
    if (entry != null && entry.isValid) {
      return entry;
    }

    // 2. 从持久层获取
    entry = await _persistentStorage.retrieve(key);
    if (entry != null && entry.isValid) {
      // 将其加入内存缓存
      await _memoryStorage.store(key, entry);
      await _enforceMemoryLimit();
      return entry;
    }

    return null;
  }

  @override
  Future<bool> delete(String key) async {
    // 从两层存储中删除
    final memoryResult = await _memoryStorage.delete(key);
    final persistentResult = await _persistentStorage.delete(key);
    return memoryResult || persistentResult;
  }

  @override
  Future<int> deleteBatch(Iterable<String> keys) async {
    final memoryCount = await _memoryStorage.deleteBatch(keys);
    final persistentCount = await _persistentStorage.deleteBatch(keys);
    return math.max(memoryCount, persistentCount);
  }

  @override
  Future<int> deleteByPattern(String pattern) async {
    final memoryCount = await _memoryStorage.deleteByPattern(pattern);
    final persistentCount = await _persistentStorage.deleteByPattern(pattern);
    return math.max(memoryCount, persistentCount);
  }

  @override
  Future<void> clear() async {
    await _memoryStorage.clear();
    await _persistentStorage.clear();
  }

  @override
  Future<List<String>> getAllKeys() async {
    final memoryKeys = await _memoryStorage.getAllKeys();
    final persistentKeys = await _persistentStorage.getAllKeys();

    // 合并并去重
    final allKeys = <String>{...memoryKeys, ...persistentKeys};
    return allKeys.toList();
  }

  @override
  Future<StorageStatistics> getStorageStatistics() async {
    final memoryStats = await _memoryStorage.getStorageStatistics();
    final persistentStats = await _persistentStorage.getStorageStatistics();

    return StorageStatistics(
      totalKeys: memoryStats.totalKeys + persistentStats.totalKeys,
      totalSize: memoryStats.totalSize + persistentStats.totalSize,
      availableSpace: persistentStats.availableSpace,
      usageRatio: persistentStats.usageRatio,
      shardStatistics: {
        'memory': ShardStatistics(
          shardName: 'memory',
          keyCount: memoryStats.totalKeys,
          size: memoryStats.totalSize,
          usageRatio: 0.05, // 假设内存使用5%
        ),
        'persistent': ShardStatistics(
          shardName: 'persistent',
          keyCount: persistentStats.totalKeys,
          size: persistentStats.totalSize,
          usageRatio: persistentStats.usageRatio,
        ),
      },
    );
  }

  @override
  Future<void> close() async {
    await _memoryStorage.close();
    await _persistentStorage.close();
  }

  /// 强制执行内存限制
  Future<void> _enforceMemoryLimit() async {
    final memoryKeys = await _memoryStorage.getAllKeys();
    if (memoryKeys.length <= _maxMemoryEntries) {
      return;
    }

    // 获取所有内存条目并按优先级和访问时间排序
    final entries = <String, CacheEntry>{};
    for (final key in memoryKeys) {
      final entry = await _memoryStorage.retrieve(key);
      if (entry != null) {
        entries[key] = entry;
      }
    }

    // 按优先级和访问时间排序
    final sortedEntries = entries.entries.toList()
      ..sort((a, b) {
        // 先按优先级排序（高优先级在前）
        final priorityDiff = b.value.config.priority - a.value.config.priority;
        if (priorityDiff != 0) return priorityDiff;

        // 再按最后访问时间排序（最近访问的在前）
        final timeDiff = b.value.metadata.lastAccessedAt
            .compareTo(a.value.metadata.lastAccessedAt);
        return timeDiff;
      });

    // 保留高优先级的条目
    final toKeep = sortedEntries.take(_maxMemoryEntries);
    final toRemove = sortedEntries.skip(_maxMemoryEntries);

    // 从内存中移除低优先级条目
    for (final entry in toRemove) {
      await _memoryStorage.delete(entry.key);
    }
  }
}

// ============================================================================
// Hive 数据模型
// ============================================================================

/// Hive 存储的缓存条目
@HiveType(typeId: 0)
class BoxCacheEntry {
  @HiveField(0)
  final String key;

  @HiveField(1)
  final dynamic data;

  @HiveField(2)
  final Map<String, dynamic> configJson;

  @HiveField(3)
  final Map<String, dynamic> metadataJson;

  @HiveField(4)
  final int? expiresAtMillis;

  const BoxCacheEntry({
    required this.key,
    required this.data,
    required this.configJson,
    required this.metadataJson,
    this.expiresAtMillis,
  });

  /// 从 CacheEntry 转换
  factory BoxCacheEntry.fromCacheEntry(CacheEntry entry) {
    return BoxCacheEntry(
      key: entry.key,
      data: entry.data,
      configJson: entry.config.toJson(),
      metadataJson: entry.metadata.toJson(),
      expiresAtMillis: entry.expiresAt?.millisecondsSinceEpoch,
    );
  }

  /// 转换为 CacheEntry
  CacheEntry toCacheEntry() {
    final config = CacheConfig.fromJson(configJson);
    final metadata = CacheMetadata.fromJson(metadataJson);

    DateTime? expiresAt;
    if (expiresAtMillis != null) {
      expiresAt = DateTime.fromMillisecondsSinceEpoch(expiresAtMillis!);
    }

    return CacheEntry(
      key: key,
      data: data,
      config: config,
      metadata: metadata,
      expiresAt: expiresAt,
    );
  }
}

// ============================================================================
// 存储工厂
// ============================================================================

/// 缓存存储工厂
class CacheStorageFactory {
  /// 创建内存存储
  static MemoryCacheStorage createMemoryStorage() {
    return MemoryCacheStorage();
  }

  /// 创建 Hive 存储
  static HiveCacheStorage createHiveStorage({
    String boxName = 'unified_cache',
    bool testMode = false,
  }) {
    return HiveCacheStorage(boxName: boxName, testMode: testMode);
  }

  /// 创建混合存储
  static HybridCacheStorage createHybridStorage({
    int maxMemoryEntries = 1000,
    String boxName = 'unified_cache',
    bool testMode = false,
  }) {
    return HybridCacheStorage(
      memoryStorage: MemoryCacheStorage(),
      persistentStorage: HiveCacheStorage(boxName: boxName, testMode: testMode),
      maxMemoryEntries: maxMemoryEntries,
    );
  }

  /// 根据环境创建合适的存储
  static ICacheStorage createStorageForEnvironment({
    required CacheEnvironment environment,
    String boxName = 'unified_cache',
    bool testMode = false,
  }) {
    switch (environment) {
      case CacheEnvironment.development:
      case CacheEnvironment.testing:
        return createMemoryStorage();
      case CacheEnvironment.staging:
      case CacheEnvironment.production:
        return createHybridStorage(
          boxName: boxName,
          maxMemoryEntries: 1000,
          testMode: testMode,
        );
    }
  }
}
