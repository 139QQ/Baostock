/// 统一缓存服务接口
///
/// 为整个应用提供统一、高效的缓存管理能力，支持：
/// - 多种数据类型的缓存
/// - 灵活的缓存策略配置
/// - 智能过期和清理机制
/// - 性能监控和统计
/// - 并发安全和优化
///
/// 设计原则：
/// - 简单性：API简洁易用
/// - 性能：高效的存储和检索
/// - 灵活性：支持多种缓存策略
/// - 可观测性：完整的监控和统计
library i_unified_cache_service;

import 'dart:async';

// ============================================================================
// 核心接口定义
// ============================================================================

/// 统一缓存服务接口
///
/// 提供所有缓存操作的标准接口，支持泛型类型安全和异步操作
abstract class IUnifiedCacheService {
  /// 获取缓存数据
  ///
  /// [key] 缓存键
  /// [type] 期望的数据类型，用于类型安全检查
  /// 返回缓存的数据，如果不存在或已过期则返回null
  Future<T?> get<T>(String key, {Type? type});

  /// 存储缓存数据
  ///
  /// [key] 缓存键
  /// [data] 要缓存的数据
  /// [config] 可选的缓存配置，如果不指定则使用默认配置
  /// [metadata] 可选的元数据，用于扩展功能
  Future<void> put<T>(
    String key,
    T data, {
    CacheConfig? config,
    CacheMetadata? metadata,
  });

  /// 批量获取缓存数据
  ///
  /// [keys] 缓存键列表
  /// [type] 期望的数据类型
  /// 返回键值对映射，不存在的键不会出现在结果中
  Future<Map<String, T?>> getAll<T>(List<String> keys, {Type? type});

  /// 批量存储缓存数据
  ///
  /// [entries] 键值对数据
  /// [config] 可选的统一缓存配置
  Future<void> putAll<T>(
    Map<String, T> entries, {
    CacheConfig? config,
  });

  /// 检查缓存是否存在且有效
  ///
  /// [key] 缓存键
  /// 返回true如果缓存存在且未过期
  Future<bool> exists(String key);

  /// 检查缓存是否已过期
  ///
  /// [key] 缓存键
  /// 返回true如果缓存已过期或不存在
  Future<bool> isExpired(String key);

  /// 删除指定缓存
  ///
  /// [key] 缓存键
  /// 返回true如果成功删除
  Future<bool> remove(String key);

  /// 批量删除缓存
  ///
  /// [keys] 缓存键列表
  /// 返回成功删除的键数量
  Future<int> removeAll(Iterable<String> keys);

  /// 根据模式删除缓存
  ///
  /// [pattern] 支持通配符的模式，如 "search_*", "user:*:data"
  /// 返回删除的键数量
  Future<int> removeByPattern(String pattern);

  /// 清空所有缓存数据
  Future<void> clear();

  /// 清空过期缓存数据
  ///
  /// 返回清理的缓存项数量
  Future<int> clearExpired();

  /// 获取缓存大小信息
  ///
  /// 返回缓存统计信息，包括项数、大小等
  Future<CacheStatistics> getStatistics();

  /// 检查服务是否已初始化
  bool get isInitialized;

  /// 初始化缓存服务
  Future<void> initialize();

  /// 获取缓存配置信息
  ///
  /// [key] 缓存键
  /// 返回该缓存项的配置信息
  Future<CacheConfig?> getConfig(String key);

  /// 更新缓存配置
  ///
  /// [key] 缓存键
  /// [config] 新的缓存配置
  /// 返回true如果更新成功
  Future<bool> updateConfig(String key, CacheConfig config);

  /// 预热缓存
  ///
  /// [keys] 需要预热的缓存键列表
  /// [loader] 数据加载函数
  Future<void> preload<T>(
    List<String> keys,
    Future<T> Function(String key) loader,
  );

  /// 获取缓存访问统计
  ///
  /// 返回缓存使用情况的统计信息
  CacheAccessStats getAccessStats();

  /// 重置访问统计
  void resetAccessStats();

  /// 启动/停止缓存监控
  ///
  /// [enabled] 是否启用监控
  void setMonitoringEnabled(bool enabled);

  /// 手动触发缓存优化
  ///
  /// 执行缓存清理、压缩等优化操作
  Future<void> optimize();
}

/// 缓存策略接口
///
/// 定义缓存的行为策略，包括过期、清理、优先级等
abstract class ICacheStrategy {
  /// 计算缓存过期时间
  ///
  /// [key] 缓存键
  /// [data] 缓存数据
  /// [config] 基础配置
  /// 返回过期时间戳
  DateTime calculateExpiry(
    String key,
    dynamic data,
    CacheConfig config,
  );

  /// 计算缓存优先级
  ///
  /// [key] 缓存键
  /// [data] 缓存数据
  /// [metadata] 缓存元数据
  /// [accessCount] 访问次数
  /// [lastAccess] 最后访问时间
  /// 返回优先级值（数值越大优先级越高）
  double calculatePriority(
    String key,
    dynamic data,
    CacheMetadata? metadata,
    int accessCount,
    DateTime lastAccess,
  );

  /// 判断是否应该清理缓存
  ///
  /// [key] 缓存键
  /// [data] 缓存数据
  /// [config] 缓存配置
  /// [memoryPressure] 内存压力（0-1）
  /// 返回true如果应该清理该缓存项
  bool shouldEvict(
    String key,
    dynamic data,
    CacheConfig config,
    double memoryPressure,
  );

  /// 获取策略名称
  String get strategyName;
}

/// 缓存存储接口
///
/// 定义底层数据存储的抽象接口
abstract class ICacheStorage {
  /// 存储数据
  Future<void> store(String key, CacheEntry entry);

  /// 检索数据
  Future<CacheEntry?> retrieve(String key);

  /// 删除数据
  Future<bool> delete(String key);

  /// 批量删除数据
  Future<int> deleteBatch(Iterable<String> keys);

  /// 按模式删除数据
  Future<int> deleteByPattern(String pattern);

  /// 清空所有数据
  Future<void> clear();

  /// 获取所有键
  Future<List<String>> getAllKeys();

  /// 获取存储大小信息
  Future<StorageStatistics> getStorageStatistics();

  /// 关闭存储
  Future<void> close();
}

// ============================================================================
// 数据模型定义
// ============================================================================

/// 缓存配置
///
/// 定义缓存项的行为配置
class CacheConfig {
  /// 过期时间，null表示永不过期
  final Duration? ttl;

  /// 最大空闲时间，null表示不限制空闲时间
  final Duration? maxIdleTime;

  /// 缓存大小限制（字节）
  final int? maxSize;

  /// 缓存优先级（0-10，数值越大优先级越高）
  final int priority;

  /// 是否允许压缩
  final bool compressible;

  /// 是否持久化存储
  final bool persistent;

  /// 缓存标签，用于分类管理
  final Set<String> tags;

  /// 自定义策略名称
  final String? strategyName;

  /// 扩展属性
  final Map<String, dynamic> extensions;

  const CacheConfig({
    this.ttl,
    this.maxIdleTime,
    this.maxSize,
    this.priority = 5,
    this.compressible = true,
    this.persistent = true,
    this.tags = const {},
    this.strategyName,
    this.extensions = const {},
  }) : assert(priority >= 0 && priority <= 10,
            'Priority must be between 0 and 10');

  /// 创建默认配置
  factory CacheConfig.defaultConfig() => const CacheConfig();

  /// 创建短期缓存配置（15分钟）
  factory CacheConfig.shortTerm() => const CacheConfig(
        ttl: Duration(minutes: 15),
        priority: 3,
      );

  /// 创建中期缓存配置（2小时）
  factory CacheConfig.mediumTerm() => const CacheConfig(
        ttl: Duration(hours: 2),
        priority: 5,
      );

  /// 创建长期缓存配置（24小时）
  factory CacheConfig.longTerm() => const CacheConfig(
        ttl: Duration(hours: 24),
        priority: 7,
      );

  /// 创建永久缓存配置
  factory CacheConfig.permanent() => const CacheConfig(
        priority: 9,
      );

  /// 创建内存缓存配置（不持久化）
  factory CacheConfig.memoryOnly({Duration? ttl}) => CacheConfig(
        ttl: ttl,
        persistent: false,
        priority: 8,
      );

  /// 复制配置并修改部分属性
  CacheConfig copyWith({
    Duration? ttl,
    Duration? maxIdleTime,
    int? maxSize,
    int? priority,
    bool? compressible,
    bool? persistent,
    Set<String>? tags,
    String? strategyName,
    Map<String, dynamic>? extensions,
  }) {
    return CacheConfig(
      ttl: ttl ?? this.ttl,
      maxIdleTime: maxIdleTime ?? this.maxIdleTime,
      maxSize: maxSize ?? this.maxSize,
      priority: priority ?? this.priority,
      compressible: compressible ?? this.compressible,
      persistent: persistent ?? this.persistent,
      tags: tags ?? this.tags,
      strategyName: strategyName ?? this.strategyName,
      extensions: extensions ?? this.extensions,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'ttl': ttl?.inMilliseconds,
      'maxIdleTime': maxIdleTime?.inMilliseconds,
      'maxSize': maxSize,
      'priority': priority,
      'compressible': compressible,
      'persistent': persistent,
      'tags': tags.toList(),
      'strategyName': strategyName,
      'extensions': extensions,
    };
  }

  /// 从JSON创建配置
  factory CacheConfig.fromJson(Map<String, dynamic> json) {
    return CacheConfig(
      ttl: json['ttl'] != null ? Duration(milliseconds: json['ttl']) : null,
      maxIdleTime: json['maxIdleTime'] != null
          ? Duration(milliseconds: json['maxIdleTime'])
          : null,
      maxSize: json['maxSize'],
      priority: json['priority'] ?? 5,
      compressible: json['compressible'] ?? true,
      persistent: json['persistent'] ?? true,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>().toSet() ?? {},
      strategyName: json['strategyName'],
      extensions: Map<String, dynamic>.from(json['extensions'] ?? {}),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CacheConfig &&
        other.ttl == ttl &&
        other.maxIdleTime == maxIdleTime &&
        other.maxSize == maxSize &&
        other.priority == priority &&
        other.compressible == compressible &&
        other.persistent == persistent &&
        other.tags == tags &&
        other.strategyName == strategyName;
  }

  @override
  int get hashCode {
    return ttl.hashCode ^
        maxIdleTime.hashCode ^
        maxSize.hashCode ^
        priority.hashCode ^
        compressible.hashCode ^
        persistent.hashCode ^
        tags.hashCode ^
        strategyName.hashCode;
  }

  @override
  String toString() {
    return 'CacheConfig(ttl: $ttl, priority: $priority, persistent: $persistent)';
  }
}

/// 缓存元数据
///
/// 存储缓存项的附加信息
class CacheMetadata {
  /// 创建时间
  final DateTime createdAt;

  /// 最后访问时间
  final DateTime lastAccessedAt;

  /// 访问次数
  final int accessCount;

  /// 数据大小（字节）
  final int size;

  /// 是否被压缩
  final bool compressed;

  /// 压缩前的大小
  final int? originalSize;

  /// 缓存标签
  final Set<String> tags;

  /// 扩展属性
  final Map<String, dynamic> extensions;

  const CacheMetadata({
    required this.createdAt,
    required this.lastAccessedAt,
    this.accessCount = 0,
    required this.size,
    this.compressed = false,
    this.originalSize,
    this.tags = const {},
    this.extensions = const {},
  });

  /// 创建新元数据
  factory CacheMetadata.create({
    required int size,
    Set<String>? tags,
    Map<String, dynamic>? extensions,
  }) {
    final now = DateTime.now();
    return CacheMetadata(
      createdAt: now,
      lastAccessedAt: now,
      size: size,
      tags: tags ?? {},
      extensions: extensions ?? {},
    );
  }

  /// 更新访问信息
  CacheMetadata updateAccess() {
    return CacheMetadata(
      createdAt: createdAt,
      lastAccessedAt: DateTime.now(),
      accessCount: accessCount + 1,
      size: size,
      compressed: compressed,
      originalSize: originalSize,
      tags: tags,
      extensions: extensions,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastAccessedAt': lastAccessedAt.millisecondsSinceEpoch,
      'accessCount': accessCount,
      'size': size,
      'compressed': compressed,
      'originalSize': originalSize,
      'tags': tags.toList(),
      'extensions': extensions,
    };
  }

  /// 从JSON创建元数据
  factory CacheMetadata.fromJson(Map<String, dynamic> json) {
    return CacheMetadata(
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      lastAccessedAt:
          DateTime.fromMillisecondsSinceEpoch(json['lastAccessedAt']),
      accessCount: json['accessCount'] ?? 0,
      size: json['size'],
      compressed: json['compressed'] ?? false,
      originalSize: json['originalSize'],
      tags: (json['tags'] as List<dynamic>?)?.cast<String>().toSet() ?? {},
      extensions: Map<String, dynamic>.from(json['extensions'] ?? {}),
    );
  }

  @override
  String toString() {
    return 'CacheMetadata(size: $size, accessCount: $accessCount, lastAccess: $lastAccessedAt)';
  }
}

/// 缓存条目
///
/// 表示一个完整的缓存项，包含数据、配置和元数据
class CacheEntry {
  /// 缓存键
  final String key;

  /// 缓存数据
  final dynamic data;

  /// 缓存配置
  final CacheConfig config;

  /// 缓存元数据
  final CacheMetadata metadata;

  /// 过期时间
  final DateTime? expiresAt;

  const CacheEntry({
    required this.key,
    required this.data,
    required this.config,
    required this.metadata,
    this.expiresAt,
  });

  /// 创建新缓存条目
  factory CacheEntry.create({
    required String key,
    required dynamic data,
    required CacheConfig config,
    required CacheMetadata metadata,
  }) {
    final expiresAt =
        config.ttl != null ? DateTime.now().add(config.ttl!) : null;

    return CacheEntry(
      key: key,
      data: data,
      config: config,
      metadata: metadata,
      expiresAt: expiresAt,
    );
  }

  /// 检查是否已过期
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// 检查是否因空闲时间过期
  bool get isIdleExpired {
    if (config.maxIdleTime == null) return false;
    final idleTime = DateTime.now().difference(metadata.lastAccessedAt);
    return idleTime > config.maxIdleTime!;
  }

  /// 检查是否有效（未过期且未空闲过期）
  bool get isValid => !isExpired && !isIdleExpired;

  /// 更新访问信息
  CacheEntry updateAccess() {
    return CacheEntry(
      key: key,
      data: data,
      config: config,
      metadata: metadata.updateAccess(),
      expiresAt: expiresAt,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'data': data,
      'config': config.toJson(),
      'metadata': metadata.toJson(),
      'expiresAt': expiresAt?.millisecondsSinceEpoch,
    };
  }

  /// 从JSON创建缓存条目
  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    return CacheEntry(
      key: json['key'],
      data: json['data'],
      config: CacheConfig.fromJson(json['config']),
      metadata: CacheMetadata.fromJson(json['metadata']),
      expiresAt: json['expiresAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['expiresAt'])
          : null,
    );
  }

  @override
  String toString() {
    return 'CacheEntry(key: $key, valid: $isValid, size: ${metadata.size})';
  }
}

// ============================================================================
// 统计信息定义
// ============================================================================

/// 缓存统计信息
class CacheStatistics {
  /// 缓存项总数
  final int totalCount;

  /// 有效缓存项数量
  final int validCount;

  /// 过期缓存项数量
  final int expiredCount;

  /// 总存储大小（字节）
  final int totalSize;

  /// 压缩节省的大小（字节）
  final int compressedSavings;

  /// 按标签分组的统计
  final Map<String, int> tagCounts;

  /// 按优先级分组的统计
  final Map<int, int> priorityCounts;

  /// 命中率
  final double hitRate;

  /// 未命中率
  final double missRate;

  /// 平均响应时间（毫秒）
  final double averageResponseTime;

  const CacheStatistics({
    required this.totalCount,
    required this.validCount,
    required this.expiredCount,
    required this.totalSize,
    required this.compressedSavings,
    required this.tagCounts,
    required this.priorityCounts,
    required this.hitRate,
    required this.missRate,
    required this.averageResponseTime,
  });

  @override
  String toString() {
    return 'CacheStatistics(total: $totalCount, valid: $validCount, hitRate: ${(hitRate * 100).toStringAsFixed(1)}%)';
  }
}

/// 缓存访问统计
class CacheAccessStats {
  /// 总访问次数
  int totalAccesses = 0;

  /// 命中次数
  int hits = 0;

  /// 未命中次数
  int misses = 0;

  /// 总响应时间（微秒）
  int totalResponseTime = 0;

  /// 访问历史（最近1000次）
  final List<AccessRecord> recentAccesses = [];

  /// 记录访问
  void recordAccess(String key, bool hit, int responseTimeMicros) {
    totalAccesses++;
    if (hit) {
      hits++;
    } else {
      misses++;
    }
    totalResponseTime += responseTimeMicros;

    // 维护访问历史
    recentAccesses.add(AccessRecord(
      key: key,
      timestamp: DateTime.now(),
      hit: hit,
      responseTimeMicros: responseTimeMicros,
    ));

    // 限制历史记录数量
    if (recentAccesses.length > 1000) {
      recentAccesses.removeRange(0, recentAccesses.length - 1000);
    }
  }

  /// 获取命中率
  double get hitRate => totalAccesses > 0 ? hits / totalAccesses : 0.0;

  /// 获取未命中率
  double get missRate => totalAccesses > 0 ? misses / totalAccesses : 0.0;

  /// 获取平均响应时间（毫秒）
  double get averageResponseTimeMs =>
      totalAccesses > 0 ? totalResponseTime / totalAccesses / 1000.0 : 0.0;

  /// 重置统计
  void reset() {
    totalAccesses = 0;
    hits = 0;
    misses = 0;
    totalResponseTime = 0;
    recentAccesses.clear();
  }

  /// 获取最近N分钟的统计
  AccessStats getRecentStats(Duration duration) {
    final cutoff = DateTime.now().subtract(duration);
    final recentAccessesFiltered = recentAccesses
        .where((record) => record.timestamp.isAfter(cutoff))
        .toList();

    if (recentAccessesFiltered.isEmpty) {
      return const AccessStats(
        totalAccesses: 0,
        hits: 0,
        misses: 0,
        averageResponseTimeMs: 0.0,
      );
    }

    final recentHits = recentAccessesFiltered.where((r) => r.hit).length;
    final recentMisses = recentAccessesFiltered.length - recentHits;
    final recentTotalTime = recentAccessesFiltered
        .map((r) => r.responseTimeMicros)
        .reduce((a, b) => a + b);

    return AccessStats(
      totalAccesses: recentAccessesFiltered.length,
      hits: recentHits,
      misses: recentMisses,
      averageResponseTimeMs:
          recentTotalTime / recentAccessesFiltered.length / 1000.0,
    );
  }

  @override
  String toString() {
    return 'CacheAccessStats(total: $totalAccesses, hitRate: ${(hitRate * 100).toStringAsFixed(1)}%, avgResponse: ${averageResponseTimeMs.toStringAsFixed(1)}ms)';
  }
}

/// 访问记录
class AccessRecord {
  final String key;
  final DateTime timestamp;
  final bool hit;
  final int responseTimeMicros;

  const AccessRecord({
    required this.key,
    required this.timestamp,
    required this.hit,
    required this.responseTimeMicros,
  });
}

/// 访问统计快照
class AccessStats {
  final int totalAccesses;
  final int hits;
  final int misses;
  final double averageResponseTimeMs;

  const AccessStats({
    required this.totalAccesses,
    required this.hits,
    required this.misses,
    required this.averageResponseTimeMs,
  });

  double get hitRate => totalAccesses > 0 ? hits / totalAccesses : 0.0;

  @override
  String toString() {
    return 'AccessStats(total: $totalAccesses, hitRate: ${(hitRate * 100).toStringAsFixed(1)}%, avgResponse: ${averageResponseTimeMs.toStringAsFixed(1)}ms)';
  }
}

/// 存储统计信息
class StorageStatistics {
  /// 总键数量
  final int totalKeys;

  /// 总存储大小（字节）
  final int totalSize;

  /// 可用空间（字节）
  final int availableSpace;

  /// 存储使用率（0-1）
  final double usageRatio;

  /// 分片信息（如果适用）
  final Map<String, ShardStatistics>? shardStatistics;

  const StorageStatistics({
    required this.totalKeys,
    required this.totalSize,
    required this.availableSpace,
    required this.usageRatio,
    this.shardStatistics,
  });

  @override
  String toString() {
    return 'StorageStatistics(keys: $totalKeys, size: ${totalSize}B, usage: ${(usageRatio * 100).toStringAsFixed(1)}%)';
  }
}

/// 分片统计信息
class ShardStatistics {
  final String shardName;
  final int keyCount;
  final int size;
  final double usageRatio;

  const ShardStatistics({
    required this.shardName,
    required this.keyCount,
    required this.size,
    required this.usageRatio,
  });

  @override
  String toString() {
    return 'ShardStatistics($shardName: $keyCount keys, ${size}B)';
  }
}

// ============================================================================
// 异常定义
// ============================================================================

/// 缓存异常基类
abstract class CacheException implements Exception {
  final String message;
  final String? key;
  final dynamic originalError;

  const CacheException(
    this.message, {
    this.key,
    this.originalError,
  });

  @override
  String toString() =>
      'CacheException: $message${key != null ? ' (key: $key)' : ''}';
}

/// 缓存键异常
class CacheKeyException extends CacheException {
  const CacheKeyException(super.message, {super.key});
}

/// 缓存序列化异常
class CacheSerializationException extends CacheException {
  const CacheSerializationException(super.message,
      {super.key, super.originalError});
}

/// 缓存存储异常
class CacheStorageException extends CacheException {
  const CacheStorageException(super.message, {super.key, super.originalError});
}

/// 缓存容量异常
class CacheCapacityException extends CacheException {
  final int requiredSize;
  final int availableSize;

  const CacheCapacityException(
    super.message, {
    super.key,
    required this.requiredSize,
    required this.availableSize,
  });

  @override
  String toString() =>
      'CacheCapacityException: $message (required: ${requiredSize}B, available: ${availableSize}B)';
}

/// 缓存策略异常
class CacheStrategyException extends CacheException {
  const CacheStrategyException(super.message, {String? strategyName})
      : super(key: strategyName);
}
