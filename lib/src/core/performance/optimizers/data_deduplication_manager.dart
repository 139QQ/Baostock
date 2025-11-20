// ignore_for_file: public_member_api_docs, sort_constructors_first, directives_ordering

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:collection';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../../utils/logger.dart';

/// 数据差异类型
enum DataDiffType {
  identical, // 完全相同
  incremental, // 增量差异
  full, // 完整数据
  conflict, // 冲突（需要处理）
}

/// 数据块信息
class DataChunk {
  final String id;
  final String hash;
  final Uint8List data;
  final DateTime createdAt;
  final int accessCount;
  final DateTime lastAccessedAt;
  final int sizeBytes;

  const DataChunk({
    required this.id,
    required this.hash,
    required this.data,
    required this.createdAt,
    required this.accessCount,
    required this.lastAccessedAt,
    required this.sizeBytes,
  });

  /// 创建数据块
  factory DataChunk.create(String id, Uint8List data) {
    final hash = _calculateHash(data);
    return DataChunk(
      id: id,
      hash: hash,
      data: data,
      createdAt: DateTime.now(),
      accessCount: 1,
      lastAccessedAt: DateTime.now(),
      sizeBytes: data.length,
    );
  }

  /// 访问数据块
  DataChunk access() {
    return DataChunk(
      id: id,
      hash: hash,
      data: data,
      createdAt: createdAt,
      accessCount: accessCount + 1,
      lastAccessedAt: DateTime.now(),
      sizeBytes: sizeBytes,
    );
  }

  /// 计算数据哈希
  static String _calculateHash(Uint8List data) {
    final bytes = sha256.convert(data);
    return bytes.toString();
  }
}

/// 数据差异结果
class DataDiff {
  final DataDiffType type;
  final String originalHash;
  final String newHash;
  final List<int> changedIndices;
  final List<dynamic> changedValues;
  final List<int> addedIndices;
  final List<dynamic> addedValues;
  final List<int> removedIndices;
  final int diffSize;

  const DataDiff({
    required this.type,
    required this.originalHash,
    required this.newHash,
    required this.changedIndices,
    required this.changedValues,
    required this.addedIndices,
    required this.addedValues,
    required this.removedIndices,
    required this.diffSize,
  });

  /// 创建完整数据差异
  factory DataDiff.full(String originalHash, String newHash, int size) {
    return DataDiff(
      type: DataDiffType.full,
      originalHash: originalHash,
      newHash: newHash,
      changedIndices: [],
      changedValues: [],
      addedIndices: [],
      addedValues: [],
      removedIndices: [],
      diffSize: size,
    );
  }

  /// 创建增量差异
  factory DataDiff.incremental({
    required String originalHash,
    required String newHash,
    required List<int> changedIndices,
    required List<dynamic> changedValues,
    required List<int> addedIndices,
    required List<dynamic> addedValues,
    required List<int> removedIndices,
    required int diffSize,
  }) {
    return DataDiff(
      type: DataDiffType.incremental,
      originalHash: originalHash,
      newHash: newHash,
      changedIndices: changedIndices,
      changedValues: changedValues,
      addedIndices: addedIndices,
      addedValues: addedValues,
      removedIndices: removedIndices,
      diffSize: diffSize,
    );
  }

  /// 创建相同数据差异
  factory DataDiff.identical(String hash) {
    return DataDiff(
      type: DataDiffType.identical,
      originalHash: hash,
      newHash: hash,
      changedIndices: [],
      changedValues: [],
      addedIndices: [],
      addedValues: [],
      removedIndices: [],
      diffSize: 0,
    );
  }
}

/// 数据去重管理器配置
class DataDeduplicationConfig {
  /// 最大缓存大小（字节）
  final int maxCacheSizeBytes;

  /// 最大缓存项数
  final int maxCacheItems;

  /// LRU清理阈值
  final double lruEvictionThreshold;

  /// 启用增量差异
  final bool enableIncrementalDiff;

  /// 启用数据压缩
  final bool enableCompression;

  /// 增量差异阈值
  final int incrementalDiffThreshold;

  /// 清理间隔
  final Duration cleanupInterval;

  /// 数据最大保存时间
  final Duration maxAge;

  const DataDeduplicationConfig({
    this.maxCacheSizeBytes = 100 * 1024 * 1024, // 100MB
    this.maxCacheItems = 10000,
    this.lruEvictionThreshold = 0.8,
    this.enableIncrementalDiff = true,
    this.enableCompression = true,
    this.incrementalDiffThreshold = 1024, // 1KB
    this.cleanupInterval = const Duration(minutes: 5),
    this.maxAge = const Duration(hours: 24),
  });
}

/// 数据去重管理器统计信息
class DeduplicationStats {
  final int totalDataProcessed;
  final int duplicatesDetected;
  final int incrementalDiffs;
  final int cacheHits;
  final int cacheMisses;
  final double compressionRatio;
  final int memorySavedBytes;
  final int cacheSize;
  final int activeConnections;

  const DeduplicationStats({
    required this.totalDataProcessed,
    required this.duplicatesDetected,
    required this.incrementalDiffs,
    required this.cacheHits,
    required this.cacheMisses,
    required this.compressionRatio,
    required this.memorySavedBytes,
    required this.cacheSize,
    required this.activeConnections,
  });

  /// 缓存命中率
  double get cacheHitRate {
    final total = cacheHits + cacheMisses;
    return total > 0 ? cacheHits / total : 0.0;
  }

  /// 去重率
  double get deduplicationRate {
    return totalDataProcessed > 0
        ? duplicatesDetected / totalDataProcessed
        : 0.0;
  }
}

/// 数据去重管理器
///
/// 实现数据去重和增量更新机制
class DataDeduplicationManager {
  final DataDeduplicationConfig _config;

  final Map<String, DataChunk> _dataCache = {};
  final Map<String, dynamic> _lastDataVersions = {};
  final Queue<String> _lruQueue = Queue<String>();

  int _currentCacheSize = 0;
  int _totalDataProcessed = 0;
  int _duplicatesDetected = 0;
  int _incrementalDiffs = 0;
  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _memorySavedBytes = 0;

  Timer? _cleanupTimer;

  DataDeduplicationManager({DataDeduplicationConfig? config})
      : _config = config ?? const DataDeduplicationConfig();

  /// 初始化去重管理器
  Future<void> initialize() async {
    AppLogger.business('初始化DataDeduplicationManager');

    // 启动清理定时器
    _cleanupTimer = Timer.periodic(_config.cleanupInterval, (_) {
      _performCleanup();
    });

    AppLogger.business('数据去重管理器初始化完成');
  }

  /// 存储数据并返回哈希
  Future<String> storeData(String key, dynamic data) async {
    final bytes = _convertToBytes(data);
    _totalDataProcessed += bytes.length;

    final hash = DataChunk._calculateHash(bytes);
    final existingChunk = _dataCache[hash];

    if (existingChunk != null) {
      // 数据已存在，返回现有哈希
      _duplicatesDetected++;
      _cacheHits++;
      AppLogger.debug('数据重复检测', 'Key: $key, Hash: $hash');
      return hash;
    }

    // 新数据，需要存储
    _cacheMisses++;
    await _ensureCacheSpace(bytes.length);

    final chunk = DataChunk.create(key, bytes);
    _dataCache[hash] = chunk;
    _lruQueue.addLast(hash);
    _currentCacheSize += bytes.length;

    // 记录数据版本
    _lastDataVersions[key] = {
      'hash': hash,
      'timestamp': DateTime.now().toIso8601String(),
      'size': bytes.length,
    };

    AppLogger.debug('新数据已存储', 'Key: $key, Hash: $hash, Size: ${bytes.length}B');
    return hash;
  }

  /// 获取数据
  dynamic getData(String hash) {
    final chunk = _dataCache[hash];
    if (chunk != null) {
      // 更新访问记录
      _dataCache[hash] = chunk.access();

      // 移动到LRU队列末尾
      _lruQueue.remove(hash);
      _lruQueue.addLast(hash);

      return _deserializeData(chunk.data);
    }

    return null;
  }

  /// 计算数据差异
  Future<DataDiff> calculateDiff(String key, dynamic newData) async {
    final lastVersion = _lastDataVersions[key];
    if (lastVersion == null) {
      // 没有历史数据，返回完整数据
      final bytes = _convertToBytes(newData);
      final hash = DataChunk._calculateHash(bytes);
      return DataDiff.full('', hash, bytes.length);
    }

    final lastHash = lastVersion['hash'] as String;
    final lastChunk = _dataCache[lastHash];

    if (lastChunk == null) {
      // 历始数据已不在缓存中，返回完整数据
      final bytes = _convertToBytes(newData);
      final hash = DataChunk._calculateHash(bytes);
      return DataDiff.full(lastHash, hash, bytes.length);
    }

    final newBytes = _convertToBytes(newData);
    final newHash = DataChunk._calculateHash(newBytes);

    if (lastHash == newHash) {
      // 数据完全相同
      return DataDiff.identical(newHash);
    }

    // 检查是否可以使用增量差异
    if (_config.enableIncrementalDiff &&
        lastChunk.sizeBytes <= _config.incrementalDiffThreshold &&
        newBytes.length <= _config.incrementalDiffThreshold) {
      final diff = await _calculateIncrementalDiff(
        lastChunk.data,
        newBytes,
        lastHash,
        newHash,
      );

      if (diff.diffSize < newBytes.length * 0.5) {
        _incrementalDiffs++;
        _memorySavedBytes += newBytes.length - diff.diffSize;
        return diff;
      }
    }

    // 返回完整数据
    _memorySavedBytes += 0; // 没有节省内存
    return DataDiff.full(lastHash, newHash, newBytes.length);
  }

  /// 应用数据差异
  Future<dynamic> applyDiff(DataDiff diff) async {
    switch (diff.type) {
      case DataDiffType.identical:
        // 数据相同，返回缓存中的数据
        return getData(diff.newHash);

      case DataDiffType.full:
        // 完整数据，需要存储并返回
        final chunk = _dataCache[diff.newHash];
        return chunk != null ? _deserializeData(chunk.data) : null;

      case DataDiffType.incremental:
        // 增量数据，需要基于原始数据构建
        return _applyIncrementalDiff(diff);

      case DataDiffType.conflict:
        // 冲突，返回完整数据
        final chunk = _dataCache[diff.newHash];
        return chunk != null ? _deserializeData(chunk.data) : null;
    }
  }

  /// 预加载常用数据
  Future<void> preloadData(Map<String, dynamic> data) async {
    for (final entry in data.entries) {
      try {
        await storeData(entry.key, entry.value);
      } catch (e) {
        AppLogger.debug('预加载数据失败', 'Key: ${entry.key}, Error: $e');
      }
    }
  }

  /// 获取统计信息
  DeduplicationStats getStats() {
    return DeduplicationStats(
      totalDataProcessed: _totalDataProcessed,
      duplicatesDetected: _duplicatesDetected,
      incrementalDiffs: _incrementalDiffs,
      cacheHits: _cacheHits,
      cacheMisses: _cacheMisses,
      compressionRatio:
          _currentCacheSize > 0 ? _memorySavedBytes / _currentCacheSize : 0.0,
      memorySavedBytes: _memorySavedBytes,
      cacheSize: _currentCacheSize,
      activeConnections: _dataCache.length,
    );
  }

  /// 处理数据
  Future<void> processData(dynamic data) async {
    try {
      // 生成数据唯一标识
      final dataKey = _generateDataKey(data);

      // 存储数据（自动去重）
      await storeData(dataKey, data);

      // 更新统计
      _totalDataProcessed++;
    } catch (e) {
      AppLogger.error('数据处理失败', e);
    }
  }

  /// 优化存储
  Future<void> optimizeStorage() async {
    try {
      AppLogger.business('开始优化存储空间');

      // 1. 清理过期数据
      await _cleanupExpiredData();

      // 2. 清理低频访问数据
      await _cleanupLowFrequencyData();

      // 3. 压缩重复数据
      await _compressDuplicateData();

      // 4. 重建LRU队列
      await _rebuildLRUQueue();

      AppLogger.business(
          '存储优化完成',
          '清理后缓存项: $_dataCache.length, '
              '节省空间: $_memorySavedBytes bytes');
    } catch (e) {
      AppLogger.error('存储优化失败', e);
    }
  }

  /// 生成数据键
  String _generateDataKey(dynamic data) {
    try {
      final bytes = _convertToBytes(data);
      final hash = sha256.convert(bytes);
      return base64Encode(hash.bytes);
    } catch (e) {
      // 如果生成哈希失败，使用时间戳
      return 'data_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// 清理过期数据
  Future<void> _cleanupExpiredData() async {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _dataCache.entries) {
      final chunk = entry.value;
      if (now.difference(chunk.createdAt) > _config.maxAge) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _removeFromCache(key);
    }

    if (expiredKeys.isNotEmpty) {
      AppLogger.debug('清理过期数据', '清理项: ${expiredKeys.length}');
    }
  }

  /// 清理低频访问数据
  Future<void> _cleanupLowFrequencyData() async {
    final now = DateTime.now();
    final lowFrequencyKeys = <String>[];

    for (final entry in _dataCache.entries) {
      final chunk = entry.value;
      final daysSinceLastAccess = now.difference(chunk.lastAccessedAt).inDays;

      // 清理超过7天未访问且访问次数少于3次的数据
      if (daysSinceLastAccess > 7 && chunk.accessCount < 3) {
        lowFrequencyKeys.add(entry.key);
      }
    }

    for (final key in lowFrequencyKeys) {
      _removeFromCache(key);
    }

    if (lowFrequencyKeys.isNotEmpty) {
      AppLogger.debug('清理低频访问数据', '清理项: ${lowFrequencyKeys.length}');
    }
  }

  /// 压缩重复数据
  Future<void> _compressDuplicateData() async {
    final hashGroups = <String, List<String>>{};

    // 按哈希值分组
    for (final entry in _dataCache.entries) {
      final hash = entry.value.hash;
      hashGroups.putIfAbsent(hash, () => []).add(entry.key);
    }

    // 处理重复数据
    int compressedCount = 0;
    for (final entry in hashGroups.entries) {
      if (entry.value.length > 1) {
        // 保留最新的，删除其他的
        final keys = entry.value
          ..sort((a, b) {
            final chunkA = _dataCache[a]!;
            final chunkB = _dataCache[b]!;
            return chunkB.createdAt.compareTo(chunkA.createdAt);
          });

        // 删除除了最新的所有重复项
        for (int i = 1; i < keys.length; i++) {
          _removeFromCache(keys[i]);
          compressedCount++;
        }
      }
    }

    if (compressedCount > 0) {
      AppLogger.debug('压缩重复数据', '压缩项: $compressedCount');
    }
  }

  /// 重建LRU队列
  Future<void> _rebuildLRUQueue() async {
    _lruQueue.clear();

    // 按最后访问时间排序
    final sortedEntries = _dataCache.entries.toList()
      ..sort(
          (a, b) => a.value.lastAccessedAt.compareTo(b.value.lastAccessedAt));

    // 重建队列
    for (final entry in sortedEntries) {
      _lruQueue.addLast(entry.key);
    }

    AppLogger.debug('重建LRU队列', '队列项: ${_lruQueue.length}');
  }

  /// 从缓存中移除数据
  void _removeFromCache(String key) {
    final chunk = _dataCache.remove(key);
    if (chunk != null) {
      _currentCacheSize -= chunk.sizeBytes;
      _memorySavedBytes += chunk.sizeBytes;
      _lruQueue.remove(key);
    }
  }

  /// 清理资源
  Future<void> dispose() async {
    AppLogger.business('清理DataDeduplicationManager资源');

    _cleanupTimer?.cancel();
    _dataCache.clear();
    _lastDataVersions.clear();
    _lruQueue.clear();
    _currentCacheSize = 0;

    AppLogger.business('数据去重管理器已关闭');
  }

  /// 确保缓存空间
  Future<void> _ensureCacheSpace(int requiredSize) async {
    // 检查是否超过最大缓存项数
    while (_dataCache.length >= _config.maxCacheItems) {
      _evictLRU();
    }

    // 检查是否超过最大缓存大小
    while (_currentCacheSize + requiredSize > _config.maxCacheSizeBytes) {
      _evictLRU();
    }

    // 检查是否超过LRU阈值
    if (_currentCacheSize >
        _config.maxCacheSizeBytes * _config.lruEvictionThreshold) {
      _evictLRU();
    }
  }

  /// 驱逐LRU项目
  void _evictLRU() {
    if (_lruQueue.isEmpty) return;

    final oldestHash = _lruQueue.removeFirst();
    final chunk = _dataCache.remove(oldestHash);

    if (chunk != null) {
      _currentCacheSize -= chunk.sizeBytes;
      AppLogger.debug('LRU驱逐', 'Hash: $oldestHash, Size: ${chunk.sizeBytes}B');
    }
  }

  /// 计算增量差异
  Future<DataDiff> _calculateIncrementalDiff(
    Uint8List oldData,
    Uint8List newData,
    String oldHash,
    String newHash,
  ) async {
    final oldList = _deserializeToSequence(oldData);
    final newList = _deserializeToSequence(newData);

    final changedIndices = <int>[];
    final changedValues = <dynamic>[];
    final addedIndices = <int>[];
    final addedValues = <dynamic>[];
    final removedIndices = <int>[];

    // 找出变化的索引
    final maxLength = math.max(oldList.length, newList.length);

    for (int i = 0; i < maxLength; i++) {
      final oldValue = i < oldList.length ? oldList[i] : null;
      final newValue = i < newList.length ? newList[i] : null;

      if (oldValue == null && newValue != null) {
        addedIndices.add(i);
        addedValues.add(newValue);
      } else if (oldValue != null && newValue == null) {
        removedIndices.add(i);
      } else if (oldValue != newValue) {
        changedIndices.add(i);
        changedValues.add(newValue);
      }
    }

    final diffSize = _calculateDiffSize(
      changedIndices.length,
      addedIndices.length,
      removedIndices.length,
      oldData.length,
      newData.length,
    );

    return DataDiff.incremental(
      originalHash: oldHash,
      newHash: newHash,
      changedIndices: changedIndices,
      changedValues: changedValues,
      addedIndices: addedIndices,
      addedValues: addedValues,
      removedIndices: removedIndices,
      diffSize: diffSize,
    );
  }

  /// 应用增量差异
  Future<dynamic> _applyIncrementalDiff(DataDiff diff) async {
    final originalChunk = _dataCache[diff.originalHash];
    if (originalChunk == null) {
      return null;
    }

    final originalData = _deserializeToSequence(originalChunk.data);
    final result = List<dynamic>.from(originalData);

    // 应用移除操作
    for (int i = diff.removedIndices.length - 1; i >= 0; i--) {
      final index = diff.removedIndices[i];
      if (index < result.length) {
        result.removeAt(index);
      }
    }

    // 应用添加操作
    for (int i = 0; i < diff.addedIndices.length; i++) {
      final index = diff.addedIndices[i];
      final value = diff.addedValues[i];

      if (index <= result.length) {
        result.insert(index, value);
      } else {
        result.add(value);
      }
    }

    // 应用修改操作
    for (int i = 0; i < diff.changedIndices.length; i++) {
      final index = diff.changedIndices[i];
      final value = diff.changedValues[i];

      if (index < result.length) {
        result[index] = value;
      }
    }

    return _serializeSequence(result);
  }

  /// 计算差异大小
  int _calculateDiffSize(
    int changedCount,
    int addedCount,
    int removedCount,
    int oldSize,
    int newSize,
  ) {
    // 简化的大小估算
    return (changedCount + addedCount + removedCount) * 8 + // 索引和数据
        64; // 元数据开销
  }

  /// 执行清理
  Future<void> _performCleanup() async {
    final now = DateTime.now();
    final keysToRemove = <String>[];

    // 清理过期的数据版本记录
    for (final entry in _lastDataVersions.entries) {
      final timestamp = DateTime.parse(entry.value['timestamp'] as String);
      if (now.difference(timestamp).inHours > 24) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      _lastDataVersions.remove(key);
    }

    AppLogger.debug('清理完成', '移除了 ${keysToRemove.length} 个过期记录');
  }

  /// 将数据转换为字节
  Uint8List _convertToBytes(dynamic data) {
    if (data is Uint8List) {
      return data;
    } else if (data is String) {
      return Uint8List.fromList(utf8.encode(data));
    } else if (data is List) {
      final jsonString = json.encode(data);
      return Uint8List.fromList(utf8.encode(jsonString));
    } else if (data is Map) {
      final jsonString = json.encode(data);
      return Uint8List.fromList(utf8.encode(jsonString));
    } else {
      final jsonString = data.toString();
      return Uint8List.fromList(utf8.encode(jsonString));
    }
  }

  /// 反序列化数据
  dynamic _deserializeData(Uint8List bytes) {
    try {
      final jsonString = String.fromCharCodes(bytes);

      // 尝试解析为JSON
      return json.decode(jsonString);
    } catch (e) {
      // 如果不是JSON，返回字符串
      return String.fromCharCodes(bytes);
    }
  }

  /// 反序列化为序列
  List<dynamic> _deserializeToSequence(Uint8List bytes) {
    final data = _deserializeData(bytes);
    if (data is List) {
      return data;
    } else {
      return [data];
    }
  }

  /// 序列化序列
  Uint8List _serializeSequence(List<dynamic> sequence) {
    final jsonString = json.encode(sequence);
    return Uint8List.fromList(utf8.encode(jsonString));
  }
}
