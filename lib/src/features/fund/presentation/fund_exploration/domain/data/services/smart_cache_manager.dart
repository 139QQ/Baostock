import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../models/fund.dart';
import 'cache_models.dart';

/// 智能缓存管理器
///
/// 核心特性：
/// - 多层缓存策略（内存 + 持久化）
/// - 智能缓存失效和更新
/// - 缓存预热和预加载
/// - 缓存统计和监控
/// - 自适应缓存大小管理
class SmartCacheManager {
  static String cacheBoxName = 'smart_fund_cache';
  int _maxMemoryCacheSize = 100; // 最大内存缓存条目数
  // static Duration defaultTtl = Duration(hours: 1); // 默认缓存时间（暂未使用）
  static Duration extendedTtl = const Duration(hours: 6); // 扩展缓存时间

  late Box _cacheBox;
  final Map<String, CacheEntry> _memoryCache = {};
  final Map<String, DateTime> _accessTimes = {}; // 记录访问时间用于LRU
  Timer? _cleanupTimer;

  // 缓存统计
  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _cacheEvictions = 0;

  /// 初始化缓存管理器
  Future<void> initialize() async {
    try {
      // 尝试打开Hive缓存盒
      try {
        if (!Hive.isAdapterRegistered(0)) {
          Hive.registerAdapter(CacheEntryAdapter());
        }

        _cacheBox = await Hive.openBox(cacheBoxName);
      } catch (e) {
        debugPrint('⚠️ Hive初始化失败，降级到内存缓存: $e');
        _cacheBox = _createInMemoryBox();
      }

      // 启动定时清理任务（每5分钟清理一次过期缓存）
      _cleanupTimer = Timer.periodic(
          const Duration(minutes: 5), (_) => _cleanupExpiredCache());

      debugPrint('✅ 智能缓存管理器初始化完成');
    } catch (e) {
      debugPrint('❌ 智能缓存管理器初始化失败: $e');
      // 降级到纯内存缓存
      _cacheBox = _createInMemoryBox();
    }
  }

  /// 创建内存盒子（降级方案）
  dynamic _createInMemoryBox() {
    // 简单的内存盒子实现
    return _InMemoryBox();
  }

  /// 存储数据（智能缓存）
  Future<void> put<T>(
    String key,
    T data, {
    Duration? ttl,
    String dataType = 'unknown',
    bool persistent = true,
  }) async {
    try {
      if (key.isEmpty) {
        debugPrint('⚠️ 缓存键为空，跳过存储');
        return;
      }

      if (data == null) {
        debugPrint('⚠️ 缓存数据为空，跳过存储: $key');
        return;
      }

      final entry = CacheEntry(
        data: data,
        dataType: dataType,
        expiresAt: ttl != null ? DateTime.now().add(ttl) : null,
      );

      // 1. 存储到内存缓存
      _memoryCache[key] = entry;
      _accessTimes[key] = DateTime.now();

      // 2. 检查内存缓存大小，执行LRU淘汰
      if (_memoryCache.length > _maxMemoryCacheSize) {
        _evictLRU();
      }

      // 3. 可选：持久化到Hive
      if (persistent) {
        await _persistToHive(key, entry);
      }

      debugPrint(
          '💾 缓存已存储: $key (类型: $dataType, TTL: ${ttl?.inMinutes ?? 60}分钟)');
    } catch (e) {
      debugPrint('❌ 缓存存储失败: $key, 错误: $e');
    }
  }

  /// 获取数据（智能缓存）
  T? get<T>(String key, {bool refreshOnAccess = false}) {
    try {
      if (key.isEmpty) {
        debugPrint('⚠️ 缓存键为空，返回null');
        return null;
      }

      // 1. 先从内存缓存获取
      CacheEntry? entry = _memoryCache[key];

      if (entry != null) {
        if (entry.isExpired) {
          // 过期了，移除并尝试从持久化缓存获取
          _memoryCache.remove(key);
          _accessTimes.remove(key);
          entry = _getFromHive<T>(key);
        }

        if (entry != null && !entry.isExpired) {
          _cacheHits++;
          _accessTimes[key] = DateTime.now(); // 更新访问时间

          // 刷新访问次数
          _memoryCache[key] = CacheEntry(
            data: entry.data,
            dataType: entry.dataType,
            expiresAt: entry.expiresAt,
            accessCount: entry.accessCount + 1,
          );

          debugPrint('🎯 内存缓存命中: $key (访问次数: ${entry.accessCount + 1})');
          return entry.data as T?;
        }
      }

      // 2. 内存缓存未命中，尝试从Hive获取
      entry = _getFromHive<T>(key);
      if (entry != null) {
        _memoryCache[key] = entry;
        _accessTimes[key] = DateTime.now();
        debugPrint('💾 持久化缓存命中: $key');
        return entry.data as T?;
      }

      _cacheMisses++;
      debugPrint('❌ 缓存未命中: $key');
      return null;
    } catch (e) {
      debugPrint('❌ 缓存获取失败: $key, 错误: $e');
      return null;
    }
  }

  /// 从Hive获取缓存
  CacheEntry? _getFromHive<T>(String key) {
    try {
      if (_cacheBox is _InMemoryBox) {
        return (_cacheBox as _InMemoryBox).get(key);
      }

      dynamic data;
      try {
        data = _cacheBox.get(key);
      } catch (e) {
        debugPrint('⚠️ _cacheBox.get 调用失败: $e');
        return null;
      }

      if (data == null) return null;

      // 反序列化数据
      CacheEntry entry;
      if (data is String) {
        // JSON字符串格式
        final json = jsonDecode(data);
        entry = CacheEntry(
          data: json['data'],
          dataType: json['dataType'] ?? 'unknown',
          expiresAt: json['expiresAt'] != null
              ? DateTime.parse(json['expiresAt'])
              : null,
          accessCount: json['accessCount'] ?? 0,
        );
      } else {
        // 直接对象格式
        entry = data as CacheEntry;
      }

      return entry.isExpired ? null : entry;
    } catch (e) {
      debugPrint('❌ Hive缓存获取失败: $key, 错误: $e');
      return null;
    }
  }

  /// 持久化到Hive
  Future<void> _persistToHive(String key, CacheEntry entry) async {
    try {
      if (key.isEmpty) {
        debugPrint('⚠️ 缓存键为空，跳过持久化');
        return;
      }

      if (_cacheBox is _InMemoryBox) {
        await (_cacheBox as _InMemoryBox).put(key, entry);
        return;
      }

      final jsonData = {
        'data': entry.data,
        'dataType': entry.dataType,
        'expiresAt': entry.expiresAt?.toIso8601String(),
        'accessCount': entry.accessCount,
        'createdAt': entry.createdAt.toIso8601String(),
      };

      try {
        await _cacheBox.put(key, jsonData);
      } catch (e) {
        debugPrint('⚠️ _cacheBox.put 调用失败: $e');
      }
    } catch (e) {
      debugPrint('❌ Hive持久化失败: $key, 错误: $e');
    }
  }

  /// LRU淘汰算法
  void _evictLRU() {
    if (_accessTimes.isEmpty) return;

    // 找到最久未访问的键
    final sortedEntries = _accessTimes.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final lruKey = sortedEntries.first.key;
    _memoryCache.remove(lruKey);
    _accessTimes.remove(lruKey);
    _cacheEvictions++;

    debugPrint('🗑️ LRU淘汰缓存: $lruKey');
  }

  /// 清理过期缓存
  void _cleanupExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    // 清理内存缓存中的过期条目
    for (final entry in _memoryCache.entries) {
      if (entry.value.isExpired ||
          now.difference(entry.value.createdAt) > extendedTtl) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _memoryCache.remove(key);
      _accessTimes.remove(key);
    }

    // 清理Hive中的过期条目
    List<String> keysToDelete = [];
    if (_cacheBox is! _InMemoryBox) {
      try {
        for (final key in _cacheBox.keys) {
          final entry = _getFromHive(key);
          if (entry == null ||
              entry.isExpired ||
              now.difference(entry.createdAt) > extendedTtl) {
            keysToDelete.add(key);
          }
        }

        for (final key in keysToDelete) {
          try {
            _cacheBox.delete(key);
          } catch (e) {
            debugPrint('⚠️ 删除缓存条目失败: $key, 错误: $e');
          }
        }
      } catch (e) {
        debugPrint('⚠️ 清理Hive缓存失败: $e');
      }
    }

    if (expiredKeys.isNotEmpty || keysToDelete.isNotEmpty) {
      debugPrint(
          '🧹 清理过期缓存: 内存${expiredKeys.length}个, 持久化${keysToDelete.length}个');
    }
  }

  /// 智能预热缓存
  Future<void> warmupCache() async {
    debugPrint('🔥 开始智能缓存预热...');

    try {
      // 预加载常用数据
      final warmupTasks = [
        _warmupPopularFunds(),
        _warmupPopularRankings(),
      ];

      await Future.wait(warmupTasks);
      debugPrint('✅ 智能缓存预热完成');
    } catch (e) {
      debugPrint('⚠️ 智能缓存预热失败: $e');
    }
  }

  /// 预加载热门基金
  Future<void> _warmupPopularFunds() async {
    // 模拟预加载热门基金数据
    final popularFunds = _generateMockFunds(50);
    await put('popular_funds', popularFunds,
        ttl: const Duration(hours: 2), dataType: 'fund');
  }

  /// 预加载热门排行
  Future<void> _warmupPopularRankings() async {
    // 模拟预加载热门排行数据
    final popularRankings = _generateMockRankings('全部', 30);
    await put('popular_rankings_all', popularRankings,
        ttl: const Duration(minutes: 30), dataType: 'ranking');
  }

  /// 自适应缓存大小管理
  void optimizeCacheSize() {
    final stats = getCacheStats();
    final hitRate = stats['hitRate'] as double;

    // 根据命中率调整缓存大小
    if (hitRate > 0.8 && _maxMemoryCacheSize < 200) {
      // 命中率高，增加缓存大小
      _maxMemoryCacheSize = (_maxMemoryCacheSize * 1.2).round();
      debugPrint('📈 增加缓存大小至: $_maxMemoryCacheSize');
    } else if (hitRate < 0.5 && _maxMemoryCacheSize > 50) {
      // 命中率低，减少缓存大小
      _maxMemoryCacheSize = (_maxMemoryCacheSize * 0.8).round();
      _evictLRU(); // 立即淘汰一些条目
      debugPrint('📉 减少缓存大小至: $_maxMemoryCacheSize');
    }
  }

  /// 获取缓存统计
  Map<String, dynamic> getCacheStats() {
    final totalRequests = _cacheHits + _cacheMisses;
    final hitRate = totalRequests > 0 ? _cacheHits / totalRequests : 0.0;

    return {
      'memoryCacheSize': _memoryCache.length,
      'maxMemoryCacheSize': _maxMemoryCacheSize,
      'cacheHits': _cacheHits,
      'cacheMisses': _cacheMisses,
      'cacheEvictions': _cacheEvictions,
      'hitRate': hitRate,
      'totalRequests': totalRequests,
      'isOptimized': hitRate > 0.7,
    };
  }

  /// 清空所有缓存
  Future<void> clearAll() async {
    _memoryCache.clear();
    _accessTimes.clear();

    if (_cacheBox is! _InMemoryBox) {
      await _cacheBox.clear();
    }

    _cacheHits = 0;
    _cacheMisses = 0;
    _cacheEvictions = 0;

    debugPrint('🧹 所有缓存已清空');
  }

  /// 释放资源
  Future<void> dispose() async {
    try {
      _cleanupTimer?.cancel();

      if (_cacheBox is! _InMemoryBox) {
        try {
          await _cacheBox.close();
        } catch (e) {
          debugPrint('⚠️ 关闭缓存盒失败: $e');
        }
      }

      _memoryCache.clear();
      _accessTimes.clear();
      debugPrint('🔒 智能缓存管理器已释放');
    } catch (e) {
      debugPrint('❌ 释放缓存管理器失败: $e');
    }
  }

  /// 生成模拟基金数据
  List<Fund> _generateMockFunds(int count) {
    final random = math.Random();
    final fundTypes = ['股票型', '混合型', '债券型', '指数型', 'QDII'];
    final companies = ['易方达', '华夏', '南方', '嘉实', '博时'];

    return List.generate(count, (index) {
      return Fund(
        code: '${100000 + index}',
        name:
            '${companies[index % companies.length]}${fundTypes[index % fundTypes.length]}基金${String.fromCharCode(65 + index % 26)}',
        type: fundTypes[index % fundTypes.length],
        company: companies[index % companies.length],
        manager: '基金经理${index % 10 + 1}',
        return1W: random.nextDouble() * 2 - 1,
        return1M: random.nextDouble() * 5 - 2.5,
        return3M: random.nextDouble() * 10 - 5,
        return6M: random.nextDouble() * 20 - 10,
        return1Y: random.nextDouble() * 30 - 15,
        return3Y: random.nextDouble() * 50 - 25,
        scale: random.nextDouble() * 100,
        riskLevel: 'R${(index % 5) + 1}',
        status: 'active',
        isFavorite: random.nextBool(),
      );
    });
  }

  /// 生成模拟排行数据
  List<Map<String, dynamic>> _generateMockRankings(String symbol, int count) {
    final random = math.Random();
    final now = DateTime.now();

    return List.generate(count, (index) {
      final baseReturn = symbol == '股票型'
          ? 12.0
          : symbol == '债券型'
              ? 4.0
              : symbol == '混合型'
                  ? 8.0
                  : 6.0;

      return {
        '基金代码': '${100000 + index}',
        '基金简称': '$symbol基金${String.fromCharCode(65 + index % 26)}',
        '基金类型': symbol,
        '公司名称': '测试基金公司${index % 5 + 1}',
        '序号': index + 1,
        '总数': count,
        '单位净值': 1.0 + random.nextDouble() * 2.0,
        '累计净值': 1.2 + random.nextDouble() * 3.0,
        '日增长率': baseReturn * 0.001 + (random.nextDouble() - 0.5) * 0.01,
        '近1周': baseReturn * 0.01 + (random.nextDouble() - 0.5) * 0.02,
        '近1月': baseReturn * 0.05 + (random.nextDouble() - 0.5) * 0.1,
        '近3月': baseReturn * 0.15 + (random.nextDouble() - 0.5) * 0.2,
        '近6月': baseReturn * 0.3 + (random.nextDouble() - 0.5) * 0.3,
        '近1年': baseReturn + (random.nextDouble() - 0.5) * 5.0,
        '近2年': baseReturn * 1.8 + (random.nextDouble() - 0.5) * 4.0,
        '近3年': baseReturn * 2.5 + (random.nextDouble() - 0.5) * 6.0,
        '今年来': baseReturn * 0.6 + (random.nextDouble() - 0.5) * 2.0,
        '成立来': baseReturn * 3.0 + random.nextDouble() * 5.0,
        '日期': now.toIso8601String(),
        '手续费': 0.5 + random.nextDouble() * 1.0,
      };
    });
  }
}

/// 内存盒子实现（降级方案）
class _InMemoryBox {
  final Map<String, dynamic> _data = {};

  dynamic get(String key) => _data[key];

  Future<void> put(String key, dynamic value) async {
    _data[key] = value;
  }

  Future<void> delete(String key) async {
    _data.remove(key);
  }

  Future<void> clear() async {
    _data.clear();
  }

  Iterable get keys => _data.keys;

  Future<void> close() async {
    _data.clear();
  }
}

/// Hive适配器（如果需要的话）
class CacheEntryAdapter extends TypeAdapter<CacheEntry> {
  @override
  final typeId = 20;

  @override
  CacheEntry read(BinaryReader reader) {
    // 实现序列化逻辑
    final data = reader.read();
    final dataType = reader.readString();
    final expiresAt = reader.read()
        ? DateTime.fromMillisecondsSinceEpoch(reader.readInt())
        : null;
    final accessCount = reader.readInt();
    final createdAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());

    return CacheEntry(
      data: data,
      dataType: dataType,
      expiresAt: expiresAt,
      accessCount: accessCount,
      createdAt: createdAt,
    );
  }

  @override
  void write(BinaryWriter writer, CacheEntry obj) {
    writer.write(obj.data);
    writer.writeString(obj.dataType);
    writer.write(obj.expiresAt != null);
    if (obj.expiresAt != null) {
      writer.writeInt(obj.expiresAt!.millisecondsSinceEpoch);
    }
    writer.writeInt(obj.accessCount);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
  }
}
