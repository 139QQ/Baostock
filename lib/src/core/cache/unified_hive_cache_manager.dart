import 'dart:async';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/logger.dart';
import 'l1_memory_cache.dart';

/// 缓存策略枚举
enum CacheStrategy {
  /// 内存优先 - 最快访问，应用重启后丢失
  memoryFirst,

  /// 磁盘优先 - 持久化存储，启动时加载
  diskFirst,

  /// 混合模式 - 内存缓存 + 磁盘持久化（推荐）
  hybrid,
}

/// 统一Hive缓存管理器
///
/// 这是项目唯一的缓存管理器实现，整合了：
/// - L1内存缓存（高性能访问）
/// - L2 Hive磁盘缓存（持久化存储）
/// - 智能缓存策略
/// - 统一的依赖注入接口
/// - 完整的错误处理和降级机制
class UnifiedHiveCacheManager {
  static UnifiedHiveCacheManager? _instance;
  static UnifiedHiveCacheManager get instance {
    _instance ??= UnifiedHiveCacheManager._();
    return _instance!;
  }

  UnifiedHiveCacheManager._();

  // 核心缓存组件
  Box? _cacheBox; // 主缓存盒子
  Box? _metadataBox; // 元数据盒子
  Box? _indexBox; // 搜索索引盒子

  // L1 内存缓存层
  late L1MemoryCache _l1Cache;

  // 状态管理
  bool _isInitialized = false;
  bool _isInMemoryMode = false;
  CacheStrategy _strategy = CacheStrategy.hybrid;

  // 性能监控
  final _PerformanceStats _stats = _PerformanceStats();
  Timer? _cleanupTimer;
  Timer? _preloadTimer;

  // 配置常量
  static const String _cacheBoxName = 'unified_fund_cache';
  static const String _metadataBoxName = 'unified_fund_metadata';
  static const String _indexBoxName = 'unified_fund_index';
  static const int _maxMemorySize = 500;
  static const int _maxMemoryBytes = 100 * 1024 * 1024; // 100MB

  /// 获取缓存大小
  int get size {
    if (!_isInitialized || _cacheBox == null) return 0;
    return _cacheBox!.length;
  }

  /// 检查是否包含指定键
  bool containsKey(String key) {
    if (!_isInitialized) return false;

    // 优先检查L1缓存
    if (_strategy != CacheStrategy.diskFirst) {
      return _l1Cache.get(key) != null;
    }

    // 检查L2缓存
    return _cacheBox?.containsKey(key) ?? false;
  }

  /// 初始化缓存系统（智能容错）
  Future<void> initialize({
    CacheStrategy strategy = CacheStrategy.hybrid,
    Duration? timeout,
  }) async {
    if (_isInitialized) return;

    final effectiveTimeout = timeout ?? const Duration(seconds: 30);
    AppLogger.info('🚀 UnifiedHiveCacheManager: 开始初始化 (策略: $strategy)');

    try {
      // 初始化L1内存缓存
      _l1Cache = L1MemoryCache(
        maxMemorySize: _maxMemorySize,
        maxMemoryBytes: _maxMemoryBytes,
      );

      // 异步初始化，使用超时保护
      await _initializeAsync(effectiveTimeout, strategy);

      _isInitialized = true;
      _strategy = strategy;

      // 启动后台任务
      _startBackgroundTasks();

      AppLogger.info('✅ UnifiedHiveCacheManager: 初始化成功');
    } catch (e) {
      AppLogger.error('❌ UnifiedHiveCacheManager: 初始化失败', e);
      // 降级到内存模式
      await _fallbackToMemoryMode();
    }
  }

  /// 异步初始化实现
  Future<void> _initializeAsync(
      Duration timeoutDuration, CacheStrategy strategy) async {
    try {
      // 1. 尝试文件系统初始化
      if (strategy != CacheStrategy.memoryFirst) {
        final success = await _tryFileSystemInitialization();
        if (success) {
          await _buildIndexes(); // 构建搜索索引
          return;
        }
      }

      // 2. 降级到内存模式
      await _fallbackToMemoryMode();
    } catch (e) {
      AppLogger.error('❌ 初始化过程中发生错误', e);
    }
  }

  /// 文件系统初始化
  Future<bool> _tryFileSystemInitialization() async {
    try {
      AppLogger.debug('🔧 尝试文件系统初始化...');

      // 使用系统临时目录
      final tempDir = Directory.systemTemp;
      final hivePath =
          '${tempDir.path}/unified_hive_cache_${DateTime.now().millisecondsSinceEpoch}';

      await Directory(hivePath).create(recursive: true);
      await Hive.initFlutter(hivePath);

      // 并行打开所有盒子
      final futures = <Future<Box>>[];
      futures.add(Hive.openBox(_cacheBoxName, crashRecovery: true));
      futures.add(Hive.openBox(_metadataBoxName, crashRecovery: true));
      futures.add(Hive.openBox(_indexBoxName, crashRecovery: true));

      final boxes = await Future.wait(futures);
      _cacheBox = boxes[0];
      _metadataBox = boxes[1];
      _indexBox = boxes[2];

      _isInMemoryMode = false;

      AppLogger.info('✅ 文件系统初始化成功: $hivePath');
      return true;
    } catch (e) {
      AppLogger.debug('❌ 文件系统初始化失败: $e');
      return false;
    }
  }

  /// 降级到内存模式
  Future<void> _fallbackToMemoryMode() async {
    AppLogger.debug('💾 降级到内存模式...');

    try {
      await Hive.initFlutter(Directory.systemTemp.path);
      _cacheBox = await Hive.openBox(_cacheBoxName, crashRecovery: true);
      _metadataBox = await Hive.openBox(_metadataBoxName, crashRecovery: true);
      _indexBox = await Hive.openBox(_indexBoxName, crashRecovery: true);
    } catch (e) {
      AppLogger.warn('⚠️ 内存模式Hive初始化失败，使用纯内存缓存: $e');
    }

    _isInMemoryMode = true;

    AppLogger.info('✅ 内存模式初始化成功');
  }

  /// 构建搜索索引（异步批量操作）
  Future<void> _buildIndexes() async {
    if (_cacheBox == null || _indexBox == null) return;

    try {
      AppLogger.debug('🔍 构建搜索索引...');
      final startTime = DateTime.now();

      // 批量读取所有缓存键
      final keys = _cacheBox!.keys.cast<String>();
      final indexData = <String, List<String>>{};

      // 并行处理索引构建
      final futures = keys.map((key) => _buildIndexForItem(key, indexData));
      await Future.wait(futures);

      // 批量写入索引
      if (_indexBox!.isOpen) {
        await _indexBox!.putAll(indexData);
      }

      final duration = DateTime.now().difference(startTime);
      AppLogger.info('✅ 搜索索引构建完成，耗时: ${duration.inMilliseconds}ms');
    } catch (e) {
      AppLogger.error('❌ 构建搜索索引失败', e);
    }
  }

  /// 为单个项目构建索引
  Future<void> _buildIndexForItem(
      String key, Map<String, List<String>> indexData) async {
    try {
      final data = _cacheBox!.get(key);
      if (data == null) return;

      // 解析数据并提取搜索关键词
      final keywords = _extractKeywords(data);
      for (final keyword in keywords) {
        indexData.putIfAbsent(keyword, () => []).add(key);
      }
    } catch (e) {
      AppLogger.debug('构建索引失败 $key: $e');
    }
  }

  /// 提取搜索关键词
  List<String> _extractKeywords(dynamic data) {
    final keywords = <String>[];

    try {
      // 如果是Map，提取常见的搜索字段
      if (data is Map) {
        final fields = ['基金简称', '基金代码', '基金公司', 'name', 'code', 'company'];
        for (final field in fields) {
          final value = data[field]?.toString();
          if (value != null && value.isNotEmpty) {
            keywords.add(value.toLowerCase());
            // 添加拼音搜索支持（简化版）
            keywords.addAll(_getPinyinKeywords(value));
          }
        }
      }
    } catch (e) {
      AppLogger.debug('提取关键词失败: $e');
    }

    return keywords;
  }

  /// 获取拼音关键词（简化实现）
  List<String> _getPinyinKeywords(String text) {
    // 这里可以集成真正的拼音库，目前返回字符级别的前缀
    final keywords = <String>[];
    for (int i = 0; i < text.length; i++) {
      if (i > 0) {
        keywords.add(text.substring(0, i).toLowerCase());
      }
    }
    return keywords;
  }

  /// 存储数据
  Future<void> put<T>(
    String key,
    T value, {
    Duration? expiration,
    CachePriority priority = CachePriority.normal,
    bool enableIndexing = true,
  }) async {
    await _ensureInitialized();

    final startTime = DateTime.now();

    try {
      final cacheItem = _CacheItem<T>(
        value: value,
        timestamp: DateTime.now(),
        expiration: expiration != null ? DateTime.now().add(expiration) : null,
        priority: priority,
      );

      // 1. L1内存缓存存储
      if (_strategy != CacheStrategy.diskFirst) {
        await _l1Cache.put(key, value,
            priority: priority, expiration: expiration);
      }

      // 2. L2持久化存储（如果不是纯内存模式）
      if (_strategy != CacheStrategy.memoryFirst && _cacheBox != null) {
        await _cacheBox!.put(key, cacheItem.toJson());

        // 异步更新元数据
        if (_metadataBox != null) {
          unawaited(_metadataBox!.put('${key}_meta', {
            'created': DateTime.now().toIso8601String(),
            'expires': cacheItem.expiration?.toIso8601String(),
            'priority': priority.value,
            'access_count': 0,
          }));
        }

        // 异步更新搜索索引
        if (enableIndexing) {
          unawaited(_updateSearchIndex(key, value));
        }
      }

      // 3. 更新统计
      _stats.recordWrite(key, DateTime.now().difference(startTime));

      AppLogger.debug('💾 缓存存储成功: $key (策略: $_strategy)');
    } catch (e) {
      _stats.recordError();
      AppLogger.error('❌ 缓存存储失败: $key', e);
    }
  }

  /// 批量存储数据
  Future<void> putAll<T>(
    Map<String, T> items, {
    Duration? expiration,
    CachePriority priority = CachePriority.normal,
  }) async {
    await _ensureInitialized();

    if (items.isEmpty) return;

    final startTime = DateTime.now();

    try {
      AppLogger.debug('📦 开始批量存储 ${items.length} 项...');

      // 1. 批量L1缓存
      if (_strategy != CacheStrategy.diskFirst) {
        await _l1Cache.putAll(items,
            priority: priority, expiration: expiration);
      }

      // 2. 批量L2持久化存储
      if (_strategy != CacheStrategy.memoryFirst && _cacheBox != null) {
        final batchData = <String, dynamic>{};
        final metadataBatch = <String, dynamic>{};

        for (final entry in items.entries) {
          final cacheItem = _CacheItem<T>(
            value: entry.value,
            timestamp: DateTime.now(),
            expiration:
                expiration != null ? DateTime.now().add(expiration) : null,
            priority: priority,
          );

          batchData[entry.key] = cacheItem.toJson();
          metadataBatch['${entry.key}_meta'] = {
            'created': DateTime.now().toIso8601String(),
            'expires': expiration != null
                ? DateTime.now().add(expiration).toIso8601String()
                : null,
            'priority': priority.value,
            'access_count': 0,
          };
        }

        // 并行批量写入
        final futures = <Future>[];
        futures.add(_cacheBox!.putAll(batchData));
        if (_metadataBox != null) {
          futures.add(_metadataBox!.putAll(metadataBatch));
        }

        await Future.wait(futures);
      }

      // 3. 更新统计
      final duration = DateTime.now().difference(startTime);
      _stats.recordBatchWrite(items.length, duration);

      AppLogger.info(
          '✅ 批量存储完成: ${items.length}项，耗时: ${duration.inMilliseconds}ms');
    } catch (e) {
      _stats.recordError();
      AppLogger.error('❌ 批量存储失败', e);
    }
  }

  /// 获取数据
  T? get<T>(String key, {bool updateStats = true}) {
    if (!_isInitialized) {
      AppLogger.debug('🔍 缓存未初始化: $key');
      return null;
    }

    try {
      // 1. L1内存缓存优先
      if (_strategy != CacheStrategy.diskFirst) {
        final value = _l1Cache.get<T>(key);
        if (value != null) {
          if (updateStats) {
            _stats.recordRead('memory');
          }
          AppLogger.debug('📥 L1内存缓存命中: $key');
          return value;
        }
      }

      // 2. L2磁盘缓存回退
      if (_strategy != CacheStrategy.memoryFirst && _cacheBox != null) {
        final data = _cacheBox!.get(key);
        if (data != null) {
          final cacheItem =
              _CacheItem<T>.fromJson(Map<String, dynamic>.from(data));

          if (!cacheItem.isExpired) {
            // 提升到L1缓存
            if (_strategy != CacheStrategy.diskFirst) {
              unawaited(_l1Cache.put(
                key,
                cacheItem.value,
                priority: cacheItem.priority,
                expiration: cacheItem.expiration != null
                    ? cacheItem.expiration!.difference(DateTime.now())
                    : null,
              ));
            }

            if (updateStats) {
              _stats.recordRead('disk');
            }

            AppLogger.debug('📥 L2磁盘缓存命中: $key');
            return cacheItem.value;
          } else {
            // 异步清理过期项
            unawaited(remove(key));
          }
        }
      }

      if (updateStats) {
        _stats.recordRead('miss');
      }

      return null;
    } catch (e) {
      _stats.recordError();
      AppLogger.error('❌ 读取缓存失败: $key', e);
      return null;
    }
  }

  /// 批量获取数据
  Map<String, T?> getAll<T>(List<String> keys) {
    final results = <String, T?>{};

    for (final key in keys) {
      results[key] = get<T>(key, updateStats: false);
    }

    _stats.recordBatchRead(keys.length);
    return results;
  }

  /// 智能搜索
  List<String> search(String query, {int limit = 20}) {
    if (!_isInitialized || query.trim().isEmpty) {
      return [];
    }

    final normalizedQuery = query.toLowerCase().trim();
    final results = <String>[];

    try {
      // 1. 精确匹配
      if (_indexBox != null && _indexBox!.containsKey(normalizedQuery)) {
        final exactMatches =
            (_indexBox!.get(normalizedQuery) as List<dynamic>).cast<String>();
        results.addAll(exactMatches);
      }

      // 2. 前缀匹配
      if (_indexBox != null) {
        for (final key in _indexBox!.keys) {
          if (key.toString().startsWith(normalizedQuery) &&
              key != normalizedQuery) {
            final prefixMatches =
                (_indexBox!.get(key) as List<dynamic>).cast<String>();
            results.addAll(prefixMatches);
          }
        }
      }

      // 3. 去重并限制结果数量
      final uniqueResults = results.toSet().take(limit).toList();
      AppLogger.debug('🔍 搜索 "$query": 找到 ${uniqueResults.length} 个结果');

      return uniqueResults;
    } catch (e) {
      AppLogger.error('❌ 搜索失败: $query', e);
      return [];
    }
  }

  /// 更新搜索索引
  Future<void> _updateSearchIndex<T>(String key, T value) async {
    if (_indexBox == null) return;

    try {
      final keywords = _extractKeywords(value);
      for (final keyword in keywords) {
        // 获取现有索引
        final currentList =
            _indexBox!.get(keyword)?.cast<String>() ?? <String>[];
        if (!currentList.contains(key)) {
          currentList.add(key);
          await _indexBox!.put(keyword, currentList);
        }
      }
    } catch (e) {
      AppLogger.debug('更新搜索索引失败 $key: $e');
    }
  }

  /// 删除数据
  Future<void> remove(String key) async {
    try {
      // 从L1缓存删除
      _l1Cache.remove(key);

      // 从L2缓存删除
      if (_cacheBox != null) {
        await _cacheBox!.delete(key);
        if (_metadataBox != null) {
          await _metadataBox!.delete('${key}_meta');
        }
      }

      AppLogger.debug('🗑️ 缓存删除成功: $key');
    } catch (e) {
      AppLogger.error('❌ 缓存删除失败: $key', e);
    }
  }

  /// 清空所有缓存
  Future<void> clear() async {
    try {
      // 清空L1缓存
      _l1Cache.clear();

      // 清空L2缓存
      if (_cacheBox != null && _cacheBox!.isOpen) {
        await _cacheBox!.clear();
      }
      if (_metadataBox != null && _metadataBox!.isOpen) {
        await _metadataBox!.clear();
      }
      if (_indexBox != null && _indexBox!.isOpen) {
        await _indexBox!.clear();
      }

      AppLogger.info('🗑️ 所有缓存已清空');
    } catch (e) {
      AppLogger.error('❌ 清空缓存失败', e);
    }
  }

  /// 获取所有缓存键
  Future<List<String>> getAllKeys() async {
    try {
      final keys = <String>[];

      // 获取L1缓存键
      keys.addAll(_l1Cache.getAllKeys());

      // 获取L2缓存键
      if (_cacheBox != null && _cacheBox!.isOpen) {
        final l2Keys = _cacheBox!.keys.cast<String>();
        // 去重合并
        for (final key in l2Keys) {
          if (!keys.contains(key)) {
            keys.add(key);
          }
        }
      }

      return keys;
    } catch (e) {
      AppLogger.error('❌ 获取所有缓存键失败', e);
      return <String>[];
    }
  }

  /// 获取缓存统计信息
  Future<Map<String, dynamic>> getStats() async {
    try {
      final l1Stats = _l1Cache.getStats();
      final allKeys = await getAllKeys();

      // 计算L2缓存统计
      int l2Count = 0;
      int l2ExpiredCount = 0;

      if (_cacheBox != null &&
          _cacheBox!.isOpen &&
          _metadataBox != null &&
          _metadataBox!.isOpen) {
        for (final key in _cacheBox!.keys) {
          if (key is String) {
            l2Count++;
            try {
              final metadata = _metadataBox!.get('${key}_meta');
              if (metadata != null && metadata['expires'] != null) {
                final expires = DateTime.parse(metadata['expires']);
                if (DateTime.now().isAfter(expires)) {
                  l2ExpiredCount++;
                }
              }
            } catch (e) {
              // 忽略元数据解析错误
            }
          }
        }
      }

      return {
        'total_keys': allKeys.length,
        'l1_cache': {
          'count': l1Stats['total_items'] ?? 0,
          'hit_rate': l1Stats['hit_rate'] ?? 0.0,
        },
        'l2_cache': {
          'count': l2Count,
          'expired_count': l2ExpiredCount,
        },
        'strategy': _strategy.toString(),
        'memory_mode': _isInMemoryMode,
        'performance': {
          'read_count': _stats.readCount,
          'write_count': _stats.writeCount,
          'error_count': _stats.errorCount,
        },
      };
    } catch (e) {
      AppLogger.error('❌ 获取缓存统计失败', e);
      return {
        'error': e.toString(),
        'total_keys': 0,
      };
    }
  }

  /// 设置缓存项过期时间
  Future<void> setExpiration(String key, Duration expiration) async {
    try {
      await _ensureInitialized();

      // 更新L1缓存项过期时间
      final l1Item = _l1Cache.get(key);
      if (l1Item != null) {
        final newItem = L1CacheItem(
          value: l1Item.value,
          timestamp: l1Item.timestamp,
          expiration: DateTime.now().add(expiration),
          priority: l1Item.priority,
          accessCount: l1Item.accessCount,
        );
        _l1Cache.put(key, newItem);
      }

      // 更新L2缓存元数据
      if (_cacheBox != null && _metadataBox != null) {
        final metadata = _metadataBox!.get('${key}_meta');
        if (metadata != null) {
          metadata['expires'] =
              DateTime.now().add(expiration).toIso8601String();
          await _metadataBox!.put('${key}_meta', metadata);
        }
      }
    } catch (e) {
      AppLogger.error('❌ 设置缓存过期时间失败: $key', e);
      rethrow;
    }
  }

  /// 获取缓存项过期时间
  Future<Duration?> getExpiration(String key) async {
    try {
      await _ensureInitialized();

      // 检查L1缓存
      final l1Item = _l1Cache.get(key);
      if (l1Item != null && l1Item.expiration != null) {
        return DateTime.now().difference(l1Item.expiration!);
      }

      // 检查L2缓存元数据
      if (_cacheBox != null && _metadataBox != null) {
        final metadata = _metadataBox!.get('${key}_meta');
        if (metadata != null && metadata['expires'] != null) {
          final expires = DateTime.parse(metadata['expires']);
          return expires.difference(DateTime.now());
        }
      }

      return null;
    } catch (e) {
      AppLogger.error('❌ 获取缓存过期时间失败: $key', e);
      rethrow;
    }
  }

  /// 启动后台任务
  void _startBackgroundTasks() {
    // 清理定时器 - 每5分钟清理一次过期数据
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _cleanupExpiredData();
    });
  }

  /// 清理过期数据
  Future<void> _cleanupExpiredData() async {
    try {
      AppLogger.debug('🧹 开始清理过期数据...');

      final now = DateTime.now();
      int cleanedCount = 0;

      // 清理L2缓存过期数据
      if (_cacheBox != null && _metadataBox != null) {
        final metadata = _metadataBox!.toMap();
        for (final entry in metadata.entries) {
          if (entry.key.toString().endsWith('_meta')) {
            final data = entry.value as Map;
            final expires = data['expires'] as String?;
            if (expires != null) {
              final expiration = DateTime.parse(expires);
              if (now.isAfter(expiration)) {
                final cacheKey = entry.key.toString().replaceFirst('_meta', '');
                await _cacheBox!.delete(cacheKey);
                await _metadataBox!.delete(entry.key.toString());
                cleanedCount++;
              }
            }
          }
        }
      }

      if (cleanedCount > 0) {
        AppLogger.info('🧹 清理完成: $cleanedCount 项过期数据');
      }
    } catch (e) {
      AppLogger.error('❌ 清理过期数据失败', e);
    }
  }

  /// 确保已初始化
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// 关闭缓存管理器
  Future<void> dispose() async {
    try {
      _cleanupTimer?.cancel();
      _preloadTimer?.cancel();

      if (_cacheBox != null && _cacheBox!.isOpen) {
        await _cacheBox!.close();
      }
      if (_metadataBox != null && _metadataBox!.isOpen) {
        await _metadataBox!.close();
      }
      if (_indexBox != null && _indexBox!.isOpen) {
        await _indexBox!.close();
      }

      _l1Cache.clear();
      _isInitialized = false;

      AppLogger.info('🔌 UnifiedHiveCacheManager 已关闭');
    } catch (e) {
      AppLogger.error('❌ 关闭缓存管理器失败', e);
    }
  }
}

/// 缓存项数据结构
class _CacheItem<T> {
  final T value;
  final DateTime timestamp;
  final DateTime? expiration;
  final CachePriority priority;

  _CacheItem({
    required this.value,
    required this.timestamp,
    this.expiration,
    required this.priority,
  });

  bool get isExpired {
    if (expiration == null) return false;
    return DateTime.now().isAfter(expiration!);
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'timestamp': timestamp.toIso8601String(),
      'expiration': expiration?.toIso8601String(),
      'priority': priority.value,
    };
  }

  factory _CacheItem.fromJson(Map<String, dynamic> json) {
    return _CacheItem<T>(
      value: json['value'] as T,
      timestamp: DateTime.parse(json['timestamp']),
      expiration: json['expiration'] != null
          ? DateTime.parse(json['expiration'])
          : null,
      priority: CachePriority.values.firstWhere(
        (p) => p.value == json['priority'],
        orElse: () => CachePriority.normal,
      ),
    );
  }
}

/// 性能统计类
class _PerformanceStats {
  int readCount = 0;
  int writeCount = 0;
  int batchReadCount = 0;
  int batchWriteCount = 0;
  int errorCount = 0;
  final List<Duration> writeTimes = [];
  final Map<String, int> readTypes = {'memory': 0, 'disk': 0, 'miss': 0};

  void recordRead(String type) {
    readCount++;
    readTypes[type] = (readTypes[type] ?? 0) + 1;
  }

  void recordWrite(String key, Duration duration) {
    writeCount++;
    writeTimes.add(duration);
  }

  void recordBatchRead(int count) {
    readCount += count;
    batchReadCount++;
  }

  void recordBatchWrite(int count, Duration duration) {
    writeCount += count;
    batchWriteCount++;
    writeTimes.add(duration);
  }

  void recordError() {
    errorCount++;
  }

  Map<String, dynamic> getStats() {
    final avgWriteTime = writeTimes.isEmpty
        ? 0.0
        : writeTimes.fold<int>(0, (sum, d) => sum + d.inMilliseconds) /
            writeTimes.length;

    return {
      'readCount': readCount,
      'writeCount': writeCount,
      'batchReadCount': batchReadCount,
      'batchWriteCount': batchWriteCount,
      'errorCount': errorCount,
      'averageWriteTime': '${avgWriteTime.toStringAsFixed(2)}ms',
      'readTypes': readTypes,
      'cacheHitRate': readCount > 0
          ? '${((readTypes['memory']! + readTypes['disk']!) / readCount * 100).toStringAsFixed(1)}%'
          : '0%',
    };
  }
}

/// 异步操作辅助函数
void unawaited(Future<void> future) {
  // 故意不等待Future完成
}
