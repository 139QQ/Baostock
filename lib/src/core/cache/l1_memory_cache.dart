import 'dart:async';
import 'dart:convert';
import '../utils/logger.dart';

/// 缓存优先级
enum CachePriority {
  low(1),
  normal(2),
  high(3),
  critical(4);

  const CachePriority(this.value);
  final int value;
}

/// L1 内存缓存项
class L1CacheItem<T> {
  final T value;
  final DateTime timestamp;
  final DateTime? expiration;
  final CachePriority priority;
  int accessCount;
  DateTime lastAccessTime;

  L1CacheItem({
    required this.value,
    required this.timestamp,
    this.expiration,
    required this.priority,
    this.accessCount = 0,
  }) : lastAccessTime = timestamp;

  /// 是否过期
  bool get isExpired {
    if (expiration == null) return false;
    return DateTime.now().isAfter(expiration!);
  }

  /// 获取优先级权重（用于排序）
  double get priorityWeight {
    final ageScore = DateTime.now().difference(lastAccessTime).inSeconds;
    final accessScore = accessCount * 10.0;
    return priority.value * 100 + accessScore - ageScore;
  }

  /// 更新访问信息
  void updateAccess() {
    accessCount++;
    lastAccessTime = DateTime.now();
  }

  /// 序列化为JSON
  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'timestamp': timestamp.toIso8601String(),
      'expiration': expiration?.toIso8601String(),
      'priority': priority.value,
      'accessCount': accessCount,
      'lastAccessTime': lastAccessTime.toIso8601String(),
    };
  }

  factory L1CacheItem.fromJson(
      Map<String, dynamic> json, T Function(dynamic) fromJson) {
    return L1CacheItem<T>(
      value: fromJson(json['value']),
      timestamp: DateTime.parse(json['timestamp']),
      expiration: json['expiration'] != null
          ? DateTime.parse(json['expiration'])
          : null,
      priority: CachePriority.values.firstWhere(
        (p) => p.value == json['priority'],
        orElse: () => CachePriority.normal,
      ),
      accessCount: json['accessCount'] ?? 0,
    );
  }
}

/// 自定义LRU节点
class _LRUNode<T> {
  final String key;
  L1CacheItem<T> item;
  _LRUNode<T>? prev;
  _LRUNode<T>? next;

  _LRUNode(this.key, this.item);
}

/// L1 内存缓存实现
///
/// 特性：
/// - 自定义LRU算法 + 优先级队列
/// - O(1)时间复杂度读写
/// - 智能淘汰策略
/// - 内存使用监控
class L1MemoryCache {
  final int maxMemorySize; // 最大内存条目数
  final int maxMemoryBytes; // 最大内存字节数

  // 核心数据结构
  final Map<String, _LRUNode<dynamic>> _cache = {};
  final Map<String, L1CacheItem<dynamic>> _priorityQueue = {};

  // LRU双向链表
  _LRUNode<dynamic>? _head;
  _LRUNode<dynamic>? _tail;

  // 优先级队列（按优先级和访问时间排序）
  final List<String> _priorityList = [];

  // 统计信息
  int _currentMemoryBytes = 0;
  int _hitCount = 0;
  int _missCount = 0;
  int _evictionCount = 0;

  L1MemoryCache({
    this.maxMemorySize = 500,
    this.maxMemoryBytes = 100 * 1024 * 1024, // 100MB
  });

  /// 获取缓存项
  T? get<T>(String key) {
    final node = _cache[key];
    if (node == null) {
      _missCount++;
      return null;
    }

    final item = node.item;
    if (item.isExpired) {
      _removeNode(node);
      _cache.remove(key);
      _priorityQueue.remove(key);
      _priorityList.remove(key);
      _missCount++;
      return null;
    }

    // 更新访问信息
    item.updateAccess();

    // 移动到链表头部
    _moveToHead(node);

    // 更新优先级队列
    _updatePriorityQueue(key, item);

    _hitCount++;
    AppLogger.debug('L1缓存命中: $key (优先级: ${item.priority.name})');

    return item.value as T?;
  }

  /// 存储缓存项
  Future<void> put<T>(
    String key,
    T value, {
    CachePriority priority = CachePriority.normal,
    Duration? expiration,
  }) async {
    final now = DateTime.now();
    final item = L1CacheItem<T>(
      value: value,
      timestamp: now,
      expiration: expiration != null ? now.add(expiration) : null,
      priority: priority,
    );

    final node = _cache[key];
    if (node != null) {
      // 更新现有项
      _updateExistingItem(key, node, item);
    } else {
      // 添加新项
      await _addNewItem(key, item);
    }
  }

  /// 批量存储
  Future<void> putAll<T>(
    Map<String, T> items, {
    CachePriority priority = CachePriority.normal,
    Duration? expiration,
  }) async {
    final now = DateTime.now();

    for (final entry in items.entries) {
      final item = L1CacheItem<T>(
        value: entry.value,
        timestamp: now,
        expiration: expiration != null ? now.add(expiration) : null,
        priority: priority,
      );

      final node = _cache[entry.key];
      if (node != null) {
        _updateExistingItem(entry.key, node, item);
      } else {
        await _addNewItem(entry.key, item);
      }
    }

    AppLogger.debug('L1批量存储完成: ${items.length}项');
  }

  /// 删除缓存项
  void remove(String key) {
    final node = _cache.remove(key);
    if (node != null) {
      _removeNode(node);
      _priorityQueue.remove(key);
      _priorityList.remove(key);
      _updateMemoryUsage(-_estimateItemSize(node.item.value));
    }
  }

  /// 清空所有缓存
  void clear() {
    _cache.clear();
    _priorityQueue.clear();
    _priorityList.clear();
    _head = null;
    _tail = null;
    _currentMemoryBytes = 0;
    AppLogger.debug('L1缓存已清空');
  }

<<<<<<< HEAD
  /// 清理过期的缓存项
  int clearExpired() {
    int clearedCount = 0;
    final now = DateTime.now();
    final expiredKeys = <String>[];

    // 找出所有过期的键
    for (final entry in _cache.entries) {
      final item = entry.value.item;
      if (item.isExpired) {
        expiredKeys.add(entry.key);
      }
    }

    // 批量删除过期项
    for (final key in expiredKeys) {
      remove(key);
      clearedCount++;
    }

    if (clearedCount > 0) {
      AppLogger.debug('L1缓存清理了 $clearedCount 个过期项');
    }

    return clearedCount;
  }

=======
>>>>>>> temp-dependency-injection
  /// 获取所有缓存键
  List<String> getAllKeys() {
    return _cache.keys.toList();
  }

  /// 获取缓存统计信息
  Map<String, dynamic> getStats() {
    final totalRequests = _hitCount + _missCount;
    final hitRate = totalRequests > 0 ? (_hitCount / totalRequests * 100) : 0.0;

    return {
      'total_items': _cache.length,
      'maxSize': maxMemorySize,
      'memoryBytes': _currentMemoryBytes,
      'maxMemoryBytes': maxMemoryBytes,
      'hitCount': _hitCount,
      'missCount': _missCount,
      'hitRate': hitRate,
      'evictionCount': _evictionCount,
      'priorityDistribution': _getPriorityDistribution(),
    };
  }

  /// 更新现有项
  void _updateExistingItem<T>(
      String key, _LRUNode<dynamic> node, L1CacheItem<T> newItem) {
    final oldItem = node.item;

    // 更新内存使用量
    _updateMemoryUsage(
        _estimateItemSize(newItem.value) - _estimateItemSize(oldItem.value));

<<<<<<< HEAD
    // 更新节点数据 - 使用类型转换确保兼容性
    node.item = newItem as dynamic;
=======
    // 更新节点数据
    node.item = newItem;
>>>>>>> temp-dependency-injection

    // 移动到链表头部
    _moveToHead(node);

    // 更新优先级队列
<<<<<<< HEAD
    _updatePriorityQueue<T>(key, newItem);
=======
    _updatePriorityQueue(key, newItem);
>>>>>>> temp-dependency-injection
  }

  /// 添加新项
  Future<void> _addNewItem<T>(String key, L1CacheItem<T> item) async {
    final estimatedSize = _estimateItemSize(item.value);

    // 检查是否需要淘汰
    while ((_cache.length >= maxMemorySize ||
            _currentMemoryBytes + estimatedSize > maxMemoryBytes) &&
        _cache.isNotEmpty) {
      await _evictLRU();
    }

    // 创建新节点
    final node = _LRUNode(key, item);

<<<<<<< HEAD
    // 添加到缓存 - 使用dynamic类型确保兼容性
    _cache[key] = node as _LRUNode<dynamic>;
    _priorityQueue[key] = item as dynamic;
=======
    // 添加到缓存
    _cache[key] = node;
    _priorityQueue[key] = item;
>>>>>>> temp-dependency-injection

    // 添加到链表头部
    _addToHead(node);

    // 添加到优先级队列
<<<<<<< HEAD
    _addToPriorityQueue<T>(key, item);
=======
    _addToPriorityQueue(key, item);
>>>>>>> temp-dependency-injection

    // 更新内存使用量
    _updateMemoryUsage(estimatedSize);
  }

  /// 淘汰LRU项
  Future<void> _evictLRU() async {
    if (_tail == null) return;

    final tailKey = _tail!.key;
    final tailItem = _tail!.item;

    // 移除尾部节点
    _removeNode(_tail!);
    _cache.remove(tailKey);
    _priorityQueue.remove(tailKey);
    _priorityList.remove(tailKey);

    // 更新内存使用量
    _updateMemoryUsage(-_estimateItemSize(tailItem.value));

    _evictionCount++;
    AppLogger.debug('L1淘汰: $tailKey (优先级: ${tailItem.priority.name})');
  }

  /// 移动节点到头部
  void _moveToHead(_LRUNode<dynamic> node) {
    _removeNode(node);
    _addToHead(node);
  }

  /// 添加节点到头部
  void _addToHead(_LRUNode<dynamic> node) {
    node.prev = null;
    node.next = _head;

    if (_head != null) {
      _head!.prev = node;
    }

    _head = node;

    _tail ??= node;
  }

  /// 移除节点
  void _removeNode(_LRUNode<dynamic> node) {
    if (node.prev != null) {
      node.prev!.next = node.next;
    } else {
      _head = node.next;
    }

    if (node.next != null) {
      node.next!.prev = node.prev;
    } else {
      _tail = node.prev;
    }
  }

  /// 添加到优先级队列
  void _addToPriorityQueue<T>(String key, L1CacheItem<T> item) {
    _priorityList.add(key);
    _priorityList.sort((a, b) {
      final itemA = _priorityQueue[a]!;
      final itemB = _priorityQueue[b]!;
      return itemB.priorityWeight.compareTo(itemA.priorityWeight);
    });
  }

  /// 更新优先级队列
  void _updatePriorityQueue<T>(String key, L1CacheItem<T> item) {
    _priorityQueue[key] = item;
    // 重新排序
    _priorityList.sort((a, b) {
      final itemA = _priorityQueue[a]!;
      final itemB = _priorityQueue[b]!;
      return itemB.priorityWeight.compareTo(itemA.priorityWeight);
    });
  }

  /// 估算对象内存大小
  int _estimateItemSize(dynamic value) {
    try {
      if (value == null) return 0;

      if (value is String) {
        return value.length * 2; // UTF-16
      } else if (value is num) {
        return 8; // 64位数字
      } else if (value is bool) {
        return 1;
      } else if (value is List) {
        return value.fold(0, (sum, item) => sum + _estimateItemSize(item));
      } else if (value is Map) {
        return value.entries.fold(
            0,
            (sum, entry) =>
                sum +
                _estimateItemSize(entry.key) +
                _estimateItemSize(entry.value));
      } else {
        // 序列化为JSON估算大小
        final json = jsonEncode(value);
        return json.length * 2;
      }
    } catch (e) {
      // 默认估算为1KB
      return 1024;
    }
  }

  /// 更新内存使用量
  void _updateMemoryUsage(int delta) {
    _currentMemoryBytes += delta;
    if (_currentMemoryBytes < 0) {
      _currentMemoryBytes = 0;
    }
  }

  /// 获取优先级分布
  Map<String, int> _getPriorityDistribution() {
    final distribution = <String, int>{};

    for (final item in _priorityQueue.values) {
      final priorityName = item.priority.name;
      distribution[priorityName] = (distribution[priorityName] ?? 0) + 1;
    }

    return distribution;
  }

  /// 预热缓存（加载热门数据）
  Future<void> warmup(
      List<String> keys, Future<dynamic> Function(String) loader) async {
    AppLogger.debug('L1缓存预热开始: ${keys.length}项');

    final futures = keys.map((key) async {
      try {
        final value = await loader(key);
        if (value != null) {
          await put(key, value, priority: CachePriority.high);
        }
      } catch (e) {
        AppLogger.debug('预热失败 $key: $e');
      }
    });

    await Future.wait(futures);
    AppLogger.debug('L1缓存预热完成');
  }
}
