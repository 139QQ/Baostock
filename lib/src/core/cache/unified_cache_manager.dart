/// 统一缓存管理器
///
/// 提供统一、高效的缓存管理服务，支持：
/// - 多种缓存策略
/// - 智能配置管理
/// - 性能监控和统计
/// - 并发安全和优化
/// - 自动清理和维护
library unified_cache_manager;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:meta/meta.dart';

import 'interfaces/i_unified_cache_service.dart';
import 'strategies/cache_strategies.dart';
import 'config/cache_config_manager.dart';
import 'storage/cache_storage.dart';
import 'management/cache_management.dart';

// ============================================================================
// 统一缓存管理器
// ============================================================================

/// 统一缓存管理器
///
/// 核心缓存服务实现，提供完整的缓存管理功能
class UnifiedCacheManager implements IUnifiedCacheService {
  // 核心组件
  final ICacheStorage _storage;
  final ICacheStrategy _strategy;
  final CacheConfigManager _configManager;

  // 性能监控
  final CacheAccessStats _accessStats = CacheAccessStats();
  final CachePerformanceTracker _performanceTracker = CachePerformanceTracker();

  // 内存管理
  final MemoryManager _memoryManager;
  final CacheMaintenanceScheduler _maintenanceScheduler;

  // 并发控制
  final CacheConcurrencyController _concurrencyController;

  // 状态管理
  bool _isInitialized = false;
  bool _isMonitoringEnabled = true;

  /// 获取初始化状态
  bool get isInitialized => _isInitialized;
  final Map<String, CacheEntry> _memoryCache = {};
  final Map<String, Timer> _expiryTimers = {};

  // 配置
  final UnifiedCacheConfig _config;

  UnifiedCacheManager({
    required ICacheStorage storage,
    required ICacheStrategy strategy,
    required CacheConfigManager configManager,
    UnifiedCacheConfig? config,
  })  : _storage = storage,
        _strategy = strategy,
        _configManager = configManager,
        _config = config ?? UnifiedCacheConfig.defaultConfig(),
        _memoryManager = MemoryManager(),
        _maintenanceScheduler = CacheMaintenanceScheduler(),
        _concurrencyController = CacheConcurrencyController() {
    _initialize();
  }

  // ============================================================================
  // 初始化和配置
  // ============================================================================

  /// 初始化缓存管理器
  Future<void> initialize() async {
    await _initialize();
  }

  /// 私有初始化方法
  Future<void> _initialize() async {
    if (_isInitialized) return;

    try {
      // 初始化存储（如果支持的话）
      if (_storage is HiveCacheStorage) {
        await (_storage as HiveCacheStorage).initialize();
      }

      // 启动维护调度器
      _maintenanceScheduler.start(_performMaintenance);

      // 预热策略
      CacheStrategyFactory.warmupStrategies();

      // 启动内存管理
      _memoryManager.start(_handleMemoryPressure);

      _isInitialized = true;
      _performanceTracker.recordEvent('cache_manager_initialized');
    } catch (e) {
      _performanceTracker.recordError('initialization', e);
      rethrow;
    }
  }

  /// 确保已初始化
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
          'Cache manager not initialized. Call initialize() first.');
    }
  }

  // ============================================================================
  // IUnifiedCacheService 接口实现
  // ============================================================================

  @override
  Future<T?> get<T>(String key, {Type? type}) async {
    _ensureInitialized();
    return await _concurrencyController.execute<T?>(
      () => _performGet<T>(key, type: type),
      operationType: CacheOperationType.get,
      key: key,
    );
  }

  /// 执行获取操作
  Future<T?> _performGet<T>(String key, {Type? type}) async {
    final stopwatch = Stopwatch()..start();
    bool success = false;
    dynamic error;

    try {
      // 1. 检查内存缓存
      var entry = _memoryCache[key];
      if (entry != null && entry.isValid) {
        _updateAccessStatistics(key, true, stopwatch.elapsedMicroseconds);
        _performanceTracker.recordHit(key);
        return _deserializeData<T>(entry.data, type);
      }

      // 2. 从存储获取
      entry = await _storage.retrieve(key);
      if (entry != null && entry.isValid) {
        // 3. 更新内存缓存
        _memoryCache[key] = entry.updateAccess();

        // 4. 设置过期定时器
        _scheduleExpiryTimer(key, entry);

        _updateAccessStatistics(key, true, stopwatch.elapsedMicroseconds);
        _performanceTracker.recordHit(key);
        return _deserializeData<T>(entry.data, type);
      }

      // 5. 缓存未命中
      _updateAccessStatistics(key, false, stopwatch.elapsedMicroseconds);
      _performanceTracker.recordMiss(key);
      return null;
    } catch (e) {
      error = e;
      _performanceTracker.recordError('get', e);
      rethrow;
    } finally {
      stopwatch.stop();
      _performanceTracker.recordOperation(
        'get',
        stopwatch.elapsedMicroseconds,
        success: success,
        error: error,
      );
    }
  }

  @override
  Future<void> put<T>(
    String key,
    T data, {
    CacheConfig? config,
    CacheMetadata? metadata,
  }) async {
    _ensureInitialized();
    await _concurrencyController.execute(
      () => _performPut<T>(key, data, config: config, metadata: metadata),
      operationType: CacheOperationType.put,
      key: key,
    );
  }

  /// 执行存储操作
  Future<void> _performPut<T>(
    String key,
    T data, {
    CacheConfig? config,
    CacheMetadata? metadata,
  }) async {
    final stopwatch = Stopwatch()..start();
    bool success = false;
    dynamic error;

    try {
      // 1. 获取配置
      final finalConfig = config ?? _configManager.getConfig(key);

      // 2. 序列化数据
      final serializedData = _serializeData(data);

      // 3. 创建元数据
      final finalMetadata = metadata ??
          CacheMetadata.create(
            size: _calculateDataSize(serializedData),
            tags: _extractTags(key, data),
          );

      // 4. 创建缓存条目
      final entry = CacheEntry.create(
        key: key,
        data: serializedData,
        config: finalConfig,
        metadata: finalMetadata,
      );

      // 5. 检查内存限制
      await _checkMemoryLimits(entry);

      // 6. 存储到持久层
      await _storage.store(key, entry);

      // 7. 更新内存缓存
      _memoryCache[key] = entry;

      // 8. 设置过期定时器
      _scheduleExpiryTimer(key, entry);

      // 9. 触发内存管理检查
      _memoryManager.recordStorage(entry.metadata.size);

      success = true;
      _performanceTracker.recordPut(key, entry.metadata.size);
    } catch (e) {
      error = e;
      _performanceTracker.recordError('put', e);
      rethrow;
    } finally {
      stopwatch.stop();
      _performanceTracker.recordOperation(
        'put',
        stopwatch.elapsedMicroseconds,
        success: success,
        error: error,
      );
    }
  }

  @override
  Future<Map<String, T?>> getAll<T>(List<String> keys, {Type? type}) async {
    _ensureInitialized();
    return await _concurrencyController.execute(
      () => _performGetAll<T>(keys, type: type),
      operationType: CacheOperationType.batchGet,
      keys: keys,
    );
  }

  /// 执行批量获取操作
  Future<Map<String, T?>> _performGetAll<T>(List<String> keys,
      {Type? type}) async {
    final stopwatch = Stopwatch()..start();
    final results = <String, T?>{};

    try {
      // 1. 并行获取所有键
      final futures = keys.map((key) async {
        final value = await _performGet<T>(key, type: type);
        return MapEntry(key, value);
      }).toList();

      final entries = await Future.wait(futures);

      // 2. 构建结果映射
      for (final entry in entries) {
        results[entry.key] = entry.value;
      }

      _performanceTracker.recordBatchOperation(
          'getAll', keys.length, stopwatch.elapsedMicroseconds);
      return results;
    } catch (e) {
      _performanceTracker.recordError('getAll', e);
      rethrow;
    }
  }

  @override
  Future<void> putAll<T>(
    Map<String, T> entries, {
    CacheConfig? config,
  }) async {
    _ensureInitialized();
    await _concurrencyController.execute(
      () => _performPutAll<T>(entries, config: config),
      operationType: CacheOperationType.batchPut,
      keys: entries.keys.toList(),
    );
  }

  /// 执行批量存储操作
  Future<void> _performPutAll<T>(
    Map<String, T> entries, {
    CacheConfig? config,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      // 1. 并行存储所有条目
      final futures = entries.entries.map((entry) async {
        await _performPut<T>(entry.key, entry.value, config: config);
      }).toList();

      await Future.wait(futures);

      _performanceTracker.recordBatchOperation(
          'putAll', entries.length, stopwatch.elapsedMicroseconds);
    } catch (e) {
      _performanceTracker.recordError('putAll', e);
      rethrow;
    }
  }

  @override
  Future<bool> exists(String key) async {
    _ensureInitialized();
    return await _concurrencyController.execute(
      () => _performExists(key),
      operationType: CacheOperationType.exists,
      key: key,
    );
  }

  /// 执行存在性检查
  Future<bool> _performExists(String key) async {
    try {
      // 1. 检查内存缓存
      final memoryEntry = _memoryCache[key];
      if (memoryEntry != null) {
        return memoryEntry.isValid;
      }

      // 2. 检查持久存储
      final storageEntry = await _storage.retrieve(key);
      return storageEntry?.isValid ?? false;
    } catch (e) {
      _performanceTracker.recordError('exists', e);
      return false;
    }
  }

  @override
  Future<bool> isExpired(String key) async {
    _ensureInitialized();
    return await _concurrencyController.execute(
      () => _performIsExpired(key),
      operationType: CacheOperationType.exists,
      key: key,
    );
  }

  /// 执行过期检查
  Future<bool> _performIsExpired(String key) async {
    try {
      final entry = _memoryCache[key] ?? await _storage.retrieve(key);
      return entry?.isExpired ?? true;
    } catch (e) {
      _performanceTracker.recordError('isExpired', e);
      return true;
    }
  }

  @override
  Future<bool> remove(String key) async {
    _ensureInitialized();
    return await _concurrencyController.execute(
      () => _performRemove(key),
      operationType: CacheOperationType.remove,
      key: key,
    );
  }

  /// 执行删除操作
  Future<bool> _performRemove(String key) async {
    try {
      // 1. 从内存缓存删除
      _memoryCache.remove(key);

      // 2. 取消过期定时器
      _expiryTimers[key]?.cancel();
      _expiryTimers.remove(key);

      // 3. 从持久存储删除
      final result = await _storage.delete(key);

      if (result) {
        _performanceTracker.recordEviction(key);
      }

      return result;
    } catch (e) {
      _performanceTracker.recordError('remove', e);
      return false;
    }
  }

  @override
  Future<int> removeAll(Iterable<String> keys) async {
    _ensureInitialized();
    return await _concurrencyController.execute(
      () => _performRemoveAll(keys),
      operationType: CacheOperationType.batchRemove,
      keys: keys.toList(),
    );
  }

  /// 执行批量删除操作
  Future<int> _performRemoveAll(Iterable<String> keys) async {
    int successCount = 0;

    try {
      for (final key in keys) {
        if (await _performRemove(key)) {
          successCount++;
        }
      }

      _performanceTracker.recordBatchEviction(keys.length, successCount);
      return successCount;
    } catch (e) {
      _performanceTracker.recordError('removeAll', e);
      rethrow;
    }
  }

  @override
  Future<int> removeByPattern(String pattern) async {
    _ensureInitialized();
    return await _concurrencyController.execute(
      () => _performRemoveByPattern(pattern),
      operationType: CacheOperationType.patternRemove,
    );
  }

  /// 执行模式删除操作
  Future<int> _performRemoveByPattern(String pattern) async {
    try {
      // 1. 获取所有匹配的键
      final allKeys = await _storage.getAllKeys();
      final matchingKeys = _filterKeysByPattern(allKeys, pattern);

      // 2. 批量删除
      return await _performRemoveAll(matchingKeys);
    } catch (e) {
      _performanceTracker.recordError('removeByPattern', e);
      rethrow;
    }
  }

  @override
  Future<void> clear() async {
    _ensureInitialized();
    await _concurrencyController.execute(
      () => _performClear(),
      operationType: CacheOperationType.clear,
    );
  }

  /// 执行清空操作
  Future<void> _performClear() async {
    try {
      // 1. 清空内存缓存
      _memoryCache.clear();

      // 2. 取消所有过期定时器
      for (final timer in _expiryTimers.values) {
        timer.cancel();
      }
      _expiryTimers.clear();

      // 3. 清空持久存储
      await _storage.clear();

      // 4. 重置统计信息
      _accessStats.reset();
      _memoryManager.reset();

      _performanceTracker.recordEvent('cache_cleared');
    } catch (e) {
      _performanceTracker.recordError('clear', e);
      rethrow;
    }
  }

  @override
  Future<int> clearExpired() async {
    _ensureInitialized();
    return await _concurrencyController.execute(
      () => _performClearExpired(),
      operationType: CacheOperationType.clearExpired,
    );
  }

  /// 执行过期清理操作
  Future<int> _performClearExpired() async {
    int clearedCount = 0;

    try {
      // 1. 检查内存缓存中的过期项
      final expiredMemoryKeys = <String>[];
      for (final entry in _memoryCache.entries) {
        if (entry.value.isExpired) {
          expiredMemoryKeys.add(entry.key);
        }
      }

      // 2. 清理过期的内存缓存项
      for (final key in expiredMemoryKeys) {
        await _performRemove(key);
        clearedCount++;
      }

      // 3. 触发存储层清理（如果支持）
      if (_storage is HiveCacheStorage) {
        final storageCleared =
            await (_storage as HiveCacheStorage).clearExpired();
        clearedCount += storageCleared as int;
      }

      _performanceTracker.recordEvent('expired_cleaned', data: clearedCount);
      return clearedCount;
    } catch (e) {
      _performanceTracker.recordError('clearExpired', e);
      rethrow;
    }
  }

  @override
  Future<CacheStatistics> getStatistics() async {
    _ensureInitialized();

    try {
      // 1. 获取存储统计
      final storageStats = await _storage.getStorageStatistics();

      // 2. 获取内存统计
      final memoryStats = _calculateMemoryStatistics();

      // 3. 合并统计信息
      return CacheStatistics(
        totalCount: _memoryCache.length,
        validCount: _getValidCacheCount(),
        expiredCount: _getExpiredCacheCount(),
        totalSize: memoryStats.totalSize + storageStats.totalSize,
        compressedSavings: 0, // 暂时设为0，因为StorageStatistics没有这个属性
        tagCounts: _calculateTagCounts(),
        priorityCounts: _calculatePriorityCounts(),
        hitRate: _accessStats.hitRate,
        missRate: _accessStats.missRate,
        averageResponseTime: _accessStats.averageResponseTimeMs,
      );
    } catch (e) {
      _performanceTracker.recordError('getStatistics', e);
      rethrow;
    }
  }

  @override
  Future<CacheConfig?> getConfig(String key) async {
    _ensureInitialized();

    try {
      final entry = _memoryCache[key] ?? await _storage.retrieve(key);
      return entry?.config;
    } catch (e) {
      _performanceTracker.recordError('getConfig', e);
      return null;
    }
  }

  @override
  Future<bool> updateConfig(String key, CacheConfig config) async {
    _ensureInitialized();
    return await _concurrencyController.execute(
      () => _performUpdateConfig(key, config),
      operationType: CacheOperationType.updateConfig,
      key: key,
    );
  }

  /// 执行配置更新操作
  Future<bool> _performUpdateConfig(String key, CacheConfig config) async {
    try {
      final entry = _memoryCache[key] ?? await _storage.retrieve(key);
      if (entry == null) return false;

      // 创建更新后的条目
      final updatedEntry = CacheEntry(
        key: key,
        data: entry.data,
        config: config,
        metadata: entry.metadata,
        expiresAt: _strategy.calculateExpiry(key, entry.data, config),
      );

      // 更新内存缓存
      _memoryCache[key] = updatedEntry;

      // 更新持久存储
      await _storage.store(key, updatedEntry);

      // 重新设置过期定时器
      _scheduleExpiryTimer(key, updatedEntry);

      return true;
    } catch (e) {
      _performanceTracker.recordError('updateConfig', e);
      return false;
    }
  }

  @override
  Future<void> preload<T>(
    List<String> keys,
    Future<T> Function(String key) loader,
  ) async {
    _ensureInitialized();

    try {
      // 1. 过滤已存在的键
      final keysToLoad = <String>[];
      for (final key in keys) {
        if (!await _performExists(key)) {
          keysToLoad.add(key);
        }
      }

      if (keysToLoad.isEmpty) return;

      // 2. 并行预加载
      final futures = keysToLoad.map((key) async {
        try {
          final data = await loader(key);
          if (data != null) {
            await _performPut<T>(key, data);
          }
        } catch (e) {
          _performanceTracker.recordError('preload_$key', e);
        }
      }).toList();

      await Future.wait(futures);

      _performanceTracker.recordEvent('preload_completed',
          data: keysToLoad.length);
    } catch (e) {
      _performanceTracker.recordError('preload', e);
      rethrow;
    }
  }

  @override
  CacheAccessStats getAccessStats() {
    return _accessStats;
  }

  @override
  void resetAccessStats() {
    _accessStats.reset();
    _performanceTracker.reset();
  }

  @override
  void setMonitoringEnabled(bool enabled) {
    _isMonitoringEnabled = enabled;
    _concurrencyController.setMonitoringEnabled(enabled);
  }

  @override
  Future<void> optimize() async {
    _ensureInitialized();

    try {
      // 1. 清理过期缓存
      await _performClearExpired();

      // 2. 内存优化
      await _memoryManager.optimize();

      // 3. 存储优化（如果支持）
      if (_storage is HiveCacheStorage) {
        await (_storage as HiveCacheStorage).optimize();
      }

      // 4. 重新计算缓存优先级
      await _recalculatePriorities();

      _performanceTracker.recordEvent('optimization_completed');
    } catch (e) {
      _performanceTracker.recordError('optimize', e);
      rethrow;
    }
  }

  // ============================================================================
  // 内部辅助方法
  // ============================================================================

  /// 更新访问统计
  void _updateAccessStatistics(String key, bool hit, int responseTimeMicros) {
    if (!_isMonitoringEnabled) return;

    _accessStats.recordAccess(key, hit, responseTimeMicros);
  }

  /// 安排过期定时器
  void _scheduleExpiryTimer(String key, CacheEntry entry) {
    // 取消现有定时器
    _expiryTimers[key]?.cancel();
    _expiryTimers.remove(key);

    // 如果有过期时间，设置新的定时器
    if (entry.expiresAt != null) {
      final delay = entry.expiresAt!.difference(DateTime.now());
      if (delay.inMilliseconds > 0) {
        _expiryTimers[key] = Timer(delay, () {
          _performRemove(key).catchError((e) {
            _performanceTracker.recordError('expiry_timer', e);
          });
        });
      } else {
        // 已经过期，立即删除
        _performRemove(key).catchError((e) {
          _performanceTracker.recordError('immediate_expiry', e);
        });
      }
    }
  }

  /// 检查内存限制
  Future<void> _checkMemoryLimits(CacheEntry newEntry) async {
    final currentSize = _memoryManager.getCurrentMemoryUsage();
    final newSize = currentSize + newEntry.metadata.size;

    if (newSize > _config.maxMemoryBytes) {
      // 触发内存清理
      await _memoryManager.triggerCleanup(newEntry.metadata.size);
    }
  }

  /// 序列化数据
  dynamic _serializeData(dynamic data) {
    if (data is String || data is num || data is bool) {
      return data;
    } else if (data is Map || data is List) {
      return jsonEncode(data);
    } else {
      // 对于复杂对象，使用 toJson() 方法（如果存在）
      if (data is dynamic && data.toJson is Function) {
        return jsonEncode(data.toJson());
      }
      return data.toString();
    }
  }

  /// 计算数据大小
  int _calculateDataSize(dynamic data) {
    if (data == null) return 0;
    if (data is String) return data.length;
    if (data is num || data is bool) return data.toString().length;
    if (data is Map || data is List) return jsonEncode(data).length;
    return data.toString().length;
  }

  /// 反序列化数据
  T? _deserializeData<T>(dynamic data, Type? type) {
    if (data == null) return null;

    try {
      // 如果没有指定类型，直接返回
      if (type == null) {
        return data as T?;
      }

      // 对于Map类型，处理泛型
      if (type == Map || type.toString().startsWith('Map<')) {
        if (data is String) {
          // 如果是JSON字符串，尝试解析
          try {
            final decoded = jsonDecode(data);
            if (decoded is Map) {
              return decoded as T?;
            }
          } catch (e) {
            // 如果解析失败，返回原字符串
            print(
                'Warning: Failed to parse JSON string in _deserializeData: $e');
          }
        }
        // 如果数据已经是Map类型，直接返回
        if (data is Map) {
          return data as T?;
        }
        // 最后尝试强制转换
        return data as T?;
      }

      // 对于List类型，处理泛型
      if (type == List || type.toString().startsWith('List<')) {
        if (data is String) {
          final decoded = jsonDecode(data);
          return decoded as T?;
        }
        // 如果数据已经是List类型，直接返回
        if (data is List) {
          return data as T?;
        }
        return data as T?;
      }

      // 基本类型处理
      if (type == String) {
        return data.toString() as T?;
      } else if (type == int) {
        return int.parse(data.toString()) as T?;
      } else if (type == double) {
        return double.parse(data.toString()) as T?;
      } else if (type == bool) {
        return (data.toString().toLowerCase() == 'true')
            ? true as T?
            : false as T?;
      }

      // 默认情况
      return data as T?;
    } catch (e) {
      _performanceTracker.recordError('deserialize', e);
      // 如果反序列化失败，尝试原样返回
      try {
        return data as T?;
      } catch (_) {
        return null;
      }
    }
  }

  /// 提取标签
  Set<String> _extractTags(String key, dynamic data) {
    final tags = <String>{};

    // 基于键的标签
    if (key.startsWith('search_')) tags.add('search');
    if (key.startsWith('filter_')) tags.add('filter');
    if (key.startsWith('user_')) tags.add('user');
    if (key.startsWith('fund_')) tags.add('fund');

    // 基于数据类型的标签
    if (data is List) tags.add('list');
    if (data is Map) tags.add('map');
    if (data is String) tags.add('string');

    return tags;
  }

  /// 根据模式过滤键
  List<String> _filterKeysByPattern(List<String> keys, String pattern) {
    final regex = _convertPatternToRegex(pattern);
    return keys.where((key) => regex.hasMatch(key)).toList();
  }

  /// 将模式转换为正则表达式
  RegExp _convertPatternToRegex(String pattern) {
    // 简单的模式匹配实现
    String regexPattern = pattern.replaceAll('*', '.*').replaceAll('?', '.');

    return RegExp('^$regexPattern\$');
  }

  /// 计算内存统计
  MemoryStatistics _calculateMemoryStatistics() {
    int totalSize = 0;
    int compressedSavings = 0;

    for (final entry in _memoryCache.values) {
      totalSize += entry.metadata.size;
      if (entry.metadata.compressed && entry.metadata.originalSize != null) {
        compressedSavings += entry.metadata.originalSize! - entry.metadata.size;
      }
    }

    return MemoryStatistics(
      totalSize: totalSize,
      compressedSavings: compressedSavings,
    );
  }

  /// 获取有效缓存数量
  int _getValidCacheCount() {
    return _memoryCache.values.where((entry) => entry.isValid).length;
  }

  /// 获取过期缓存数量
  int _getExpiredCacheCount() {
    return _memoryCache.values.where((entry) => entry.isExpired).length;
  }

  /// 计算标签统计
  Map<String, int> _calculateTagCounts() {
    final tagCounts = <String, int>{};

    for (final entry in _memoryCache.values) {
      for (final tag in entry.metadata.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }

    return tagCounts;
  }

  /// 计算优先级统计
  Map<int, int> _calculatePriorityCounts() {
    final priorityCounts = <int, int>{};

    for (final entry in _memoryCache.values) {
      final priority = entry.config.priority;
      priorityCounts[priority] = (priorityCounts[priority] ?? 0) + 1;
    }

    return priorityCounts;
  }

  /// 重新计算缓存优先级
  Future<void> _recalculatePriorities() async {
    for (final entry in _memoryCache.entries) {
      final newPriority = _strategy.calculatePriority(
        entry.key,
        entry.value.data,
        entry.value.metadata,
        entry.value.metadata.accessCount,
        entry.value.metadata.lastAccessedAt,
      );

      // 如果优先级变化，更新配置
      if (newPriority != entry.value.config.priority) {
        // 确保优先级在有效范围内
        final safePriority = newPriority.round().clamp(0, 10);
        final newConfig = entry.value.config.copyWith(priority: safePriority);
        await _performUpdateConfig(entry.key, newConfig);
      }
    }
  }

  /// 执行维护任务
  Future<void> _performMaintenance() async {
    try {
      // 1. 清理过期缓存
      await _performClearExpired();

      // 2. 检查内存压力
      await _memoryManager.checkMemoryPressure();

      // 3. 优化缓存策略
      await _recalculatePriorities();

      _performanceTracker.recordEvent('maintenance_completed');
    } catch (e) {
      _performanceTracker.recordError('maintenance', e);
    }
  }

  /// 处理内存压力
  Future<void> _handleMemoryPressure(double pressure) async {
    if (pressure > 0.9) {
      // 高内存压力：激进的清理策略
      await _performAggressiveCleanup();
    } else if (pressure > 0.7) {
      // 中等内存压力：标准清理策略
      await _performClearExpired();
    }
  }

  /// 激进清理策略
  Future<void> _performAggressiveCleanup() async {
    // 1. 清理过期缓存
    await _performClearExpired();

    // 2. 清理低优先级缓存
    final lowPriorityEntries = _memoryCache.entries
        .where((entry) => entry.value.config.priority < 3)
        .toList();

    // 按优先级和访问时间排序
    lowPriorityEntries.sort((a, b) {
      final priorityDiff = a.value.config.priority - b.value.config.priority;
      if (priorityDiff != 0) return priorityDiff;

      final timeDiff = a.value.metadata.lastAccessedAt
          .compareTo(b.value.metadata.lastAccessedAt);
      return timeDiff;
    });

    // 删除部分低优先级缓存
    final toRemove = lowPriorityEntries.take(lowPriorityEntries.length ~/ 2);
    for (final entry in toRemove) {
      await _performRemove(entry.key);
    }
  }

  /// 关闭缓存管理器
  Future<void> close() async {
    try {
      // 1. 停止维护调度器
      _maintenanceScheduler.stop();

      // 2. 取消所有定时器
      for (final timer in _expiryTimers.values) {
        timer.cancel();
      }
      _expiryTimers.clear();

      // 3. 停止内存管理器
      _memoryManager.stop();

      // 4. 关闭存储
      await _storage.close();

      // 5. 清理内存缓存
      _memoryCache.clear();

      _isInitialized = false;
      _performanceTracker.recordEvent('cache_manager_closed');
    } catch (e) {
      _performanceTracker.recordError('close', e);
      rethrow;
    }
  }
}

// ============================================================================
// 配置类
// ============================================================================

/// 统一缓存配置
class UnifiedCacheConfig {
  final int maxMemoryBytes;
  final Duration maintenanceInterval;
  final int maxConcurrentOperations;
  final bool enableCompression;
  final bool enableEncryption;

  const UnifiedCacheConfig({
    this.maxMemoryBytes = 100 * 1024 * 1024, // 100MB
    required this.maintenanceInterval,
    this.maxConcurrentOperations = 100,
    this.enableCompression = true,
    this.enableEncryption = false,
  });

  /// 默认配置
  factory UnifiedCacheConfig.defaultConfig() => const UnifiedCacheConfig(
        maintenanceInterval: Duration(minutes: 5),
      );

  /// 开发环境配置
  factory UnifiedCacheConfig.development() => UnifiedCacheConfig(
        maxMemoryBytes: 50 * 1024 * 1024, // 50MB
        maintenanceInterval: Duration(minutes: 1),
        maxConcurrentOperations: 10,
        enableCompression: false,
        enableEncryption: false,
      );

  /// 生产环境配置
  factory UnifiedCacheConfig.production() => UnifiedCacheConfig(
        maxMemoryBytes: 200 * 1024 * 1024, // 200MB
        maintenanceInterval: Duration(minutes: 10),
        maxConcurrentOperations: 200,
        enableCompression: true,
        enableEncryption: true,
      );

  /// 测试环境配置
  factory UnifiedCacheConfig.testing() => UnifiedCacheConfig(
        maxMemoryBytes: 10 * 1024 * 1024, // 10MB
        maintenanceInterval: Duration(minutes: 2),
        maxConcurrentOperations: 5,
        enableCompression: false,
        enableEncryption: false,
      );
}

/// 内存统计
class MemoryStatistics {
  final int totalSize;
  final int compressedSavings;

  const MemoryStatistics({
    required this.totalSize,
    required this.compressedSavings,
  });
}

/// 缓存性能跟踪器
class CachePerformanceTracker {
  final List<PerformanceEvent> _events = [];
  final Map<String, OperationStats> _operationStats = {};

  void recordOperation(
    String operation,
    int durationMicros, {
    bool success = true,
    dynamic error,
  }) {
    final stats = _operationStats.putIfAbsent(
      operation,
      () => OperationStats(),
    );

    stats.addSample(durationMicros, success: success);

    if (!success) {
      stats.recordError(error);
    }

    _addEvent(PerformanceEvent.operation(
      operation: operation,
      duration: durationMicros,
      success: success,
      error: error,
    ));
  }

  void recordHit(String key) {
    _addEvent(PerformanceEvent.hit(key: key));
  }

  void recordMiss(String key) {
    _addEvent(PerformanceEvent.miss(key: key));
  }

  void recordPut(String key, int size) {
    _addEvent(PerformanceEvent.put(key: key, size: size));
  }

  void recordEviction(String key) {
    _addEvent(PerformanceEvent.eviction(key: key));
  }

  void recordBatchEviction(int total, int success) {
    _addEvent(PerformanceEvent.batchEviction(
      total: total,
      success: success,
    ));
  }

  void recordBatchOperation(String operation, int count, int durationMicros) {
    _addEvent(PerformanceEvent.batchOperation(
      operation: operation,
      count: count,
      duration: durationMicros,
    ));
  }

  void recordEvent(String type, {dynamic data}) {
    _addEvent(PerformanceEvent.custom(type: type, data: data));
  }

  void recordError(String context, dynamic error) {
    _addEvent(PerformanceEvent.error(context: context, error: error));
  }

  void _addEvent(PerformanceEvent event) {
    _events.add(event);
    _maintainEventLimit();
  }

  void _maintainEventLimit() {
    if (_events.length > 10000) {
      _events.removeRange(0, _events.length - 10000);
    }
  }

  void reset() {
    _events.clear();
    _operationStats.clear();
  }

  OperationStats? getOperationStats(String operation) {
    return _operationStats[operation];
  }

  Map<String, OperationStats> getAllOperationStats() {
    return Map.unmodifiable(_operationStats);
  }

  List<PerformanceEvent> getRecentEvents({int limit = 100}) {
    return _events.length > limit
        ? _events.sublist(_events.length - limit)
        : List.unmodifiable(_events);
  }
}

/// 性能事件
class PerformanceEvent {
  final DateTime timestamp;
  final PerformanceEventType type;
  final String? operation;
  final String? key;
  final int? duration;
  final int? size;
  final bool? success;
  final dynamic error;
  final dynamic data;

  const PerformanceEvent._({
    required this.timestamp,
    required this.type,
    this.operation,
    this.key,
    this.duration,
    this.size,
    this.success,
    this.error,
    this.data,
  });

  factory PerformanceEvent.operation({
    required String operation,
    required int duration,
    bool success = true,
    dynamic error,
  }) {
    return PerformanceEvent._(
      timestamp: DateTime.now(),
      type: PerformanceEventType.operation,
      operation: operation,
      duration: duration,
      success: success,
      error: error,
    );
  }

  factory PerformanceEvent.hit({required String key}) {
    return PerformanceEvent._(
      timestamp: DateTime.now(),
      type: PerformanceEventType.hit,
      key: key,
    );
  }

  factory PerformanceEvent.miss({required String key}) {
    return PerformanceEvent._(
      timestamp: DateTime.now(),
      type: PerformanceEventType.miss,
      key: key,
    );
  }

  factory PerformanceEvent.put({
    required String key,
    required int size,
  }) {
    return PerformanceEvent._(
      timestamp: DateTime.now(),
      type: PerformanceEventType.put,
      key: key,
      size: size,
    );
  }

  factory PerformanceEvent.eviction({required String key}) {
    return PerformanceEvent._(
      timestamp: DateTime.now(),
      type: PerformanceEventType.eviction,
      key: key,
    );
  }

  factory PerformanceEvent.batchEviction({
    required int total,
    required int success,
  }) {
    return PerformanceEvent._(
      timestamp: DateTime.now(),
      type: PerformanceEventType.batchEviction,
      data: {'total': total, 'success': success},
    );
  }

  factory PerformanceEvent.batchOperation({
    required String operation,
    required int count,
    required int duration,
  }) {
    return PerformanceEvent._(
      timestamp: DateTime.now(),
      type: PerformanceEventType.batchOperation,
      operation: operation,
      duration: duration,
      data: {'count': count},
    );
  }

  factory PerformanceEvent.custom({
    required String type,
    dynamic data,
  }) {
    return PerformanceEvent._(
      timestamp: DateTime.now(),
      type: PerformanceEventType.custom,
      data: data,
    );
  }

  factory PerformanceEvent.error({
    required String context,
    required dynamic error,
  }) {
    return PerformanceEvent._(
      timestamp: DateTime.now(),
      type: PerformanceEventType.error,
      operation: context,
      error: error,
    );
  }
}

/// 性能事件类型
enum PerformanceEventType {
  operation,
  hit,
  miss,
  put,
  eviction,
  batchEviction,
  batchOperation,
  custom,
  error,
}

/// 操作统计
class OperationStats {
  int sampleCount = 0;
  int totalDuration = 0;
  int successCount = 0;
  int errorCount = 0;
  final List<dynamic> errors = [];

  int get averageDuration => sampleCount > 0 ? totalDuration ~/ sampleCount : 0;

  double get successRate => sampleCount > 0 ? successCount / sampleCount : 0.0;

  void addSample(int duration, {bool success = true}) {
    sampleCount++;
    totalDuration += duration;
    if (success) {
      successCount++;
    } else {
      errorCount++;
    }
  }

  void recordError(dynamic error) {
    errors.add(error);
    if (errors.length > 100) {
      errors.removeAt(0);
    }
  }
}
