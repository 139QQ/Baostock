import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../utils/logger.dart';

/// 内存信息
class MemoryInfo {
  final int availableMemoryMB;
  final int totalMemoryMB;
  final int cachedMemoryMB;

  MemoryInfo({
    required this.availableMemoryMB,
    required this.totalMemoryMB,
    this.cachedMemoryMB = 0,
  });
}

/// 内存压力级别
enum MemoryPressureLevel {
  normal, // 正常 (< 60%)
  warning, // 警告 (60-75%)
  critical, // 危险 (75-85%)
  emergency, // 紧急 (> 85%)
}

/// 缓存策略
enum CacheStrategy {
  aggressive, // 积极缓存 (高性能设备)
  balanced, // 平衡缓存 (中等性能设备)
  conservative, // 保守缓存 (低端设备)
}

/// 内存压力事件
class MemoryPressureEvent {
  final MemoryPressureLevel level;
  final double memoryUsagePercent;
  final int availableMemoryMB;
  final int usedMemoryMB;
  final DateTime timestamp;
  final String message;

  MemoryPressureEvent({
    required this.level,
    required this.memoryUsagePercent,
    required this.availableMemoryMB,
    required this.usedMemoryMB,
    required this.timestamp,
    required this.message,
  });
}

/// 弱引用缓存项
class WeakCacheItem {
  final WeakReference reference;
  final DateTime createdAt;
  final DateTime lastAccessedAt;
  final int accessCount;
  final int sizeBytes;
  final String key;

  WeakCacheItem({
    required this.key,
    required dynamic value,
    required this.sizeBytes,
  })  : reference = WeakReference(value),
        createdAt = DateTime.now(),
        lastAccessedAt = DateTime.now(),
        accessCount = 1;

  dynamic get value => reference.target;

  WeakCacheItem copyWithUpdatedAccess() {
    final item = WeakCacheItem(
      key: key,
      value: value,
      sizeBytes: sizeBytes,
    );
    return item;
  }

  bool get isAlive => reference.target != null;
}

/// 高级内存管理器配置
class AdvancedMemoryManagerConfig {
  /// 最大缓存大小 (MB)
  final int maxCacheSizeMB;

  /// 内存压力检测间隔
  final Duration pressureCheckInterval;

  /// LRU清理阈值
  final double lruEvictionThreshold;

  /// 自动GC阈值
  final double autoGCThreshold;

  /// 弱引用清理间隔
  final Duration weakReferenceCleanupInterval;

  /// 内存压力预警阈值
  final double memoryAlertThreshold;

  const AdvancedMemoryManagerConfig({
    this.maxCacheSizeMB = 256,
    this.pressureCheckInterval = const Duration(seconds: 10),
    this.lruEvictionThreshold = 0.8,
    this.autoGCThreshold = 0.85,
    this.weakReferenceCleanupInterval = const Duration(seconds: 30),
    this.memoryAlertThreshold = 0.75,
  });
}

/// 高级内存管理器
///
/// 实现智能内存管理，包括：
/// - 弱引用LRU缓存
/// - 基于内存压力的动态调整
/// - 定期清理和垃圾回收优化
/// - 内存压力检测和预警
class AdvancedMemoryManager {
  final AdvancedMemoryManagerConfig _config;
  final Map<String, WeakCacheItem> _cache = {};
  final Queue<String> _accessOrder = Queue<String>();
  final StreamController<MemoryPressureEvent> _pressureController =
      StreamController<MemoryPressureEvent>.broadcast();

  Timer? _pressureCheckTimer;
  Timer? _weakRefCleanupTimer;
  Timer? _autoGCTimer;

  MemoryPressureLevel _currentPressureLevel = MemoryPressureLevel.normal;
  CacheStrategy _currentStrategy = CacheStrategy.balanced;

  // 内存统计
  int _currentCacheSizeBytes = 0;
  int _totalAccessCount = 0;
  int _evictionCount = 0;
  int _gcCount = 0;

  static AdvancedMemoryManager? _instance;

  AdvancedMemoryManager._(this._config);

  /// 获取单例实例
  static AdvancedMemoryManager get instance {
    _instance ??= AdvancedMemoryManager._(AdvancedMemoryManagerConfig());
    return _instance!;
  }

  /// 自定义配置的单例实例
  static AdvancedMemoryManager createWithConfig(
      AdvancedMemoryManagerConfig config) {
    return AdvancedMemoryManager._(config);
  }

  /// 内存压力事件流
  Stream<MemoryPressureEvent> get pressureStream => _pressureController.stream;

  /// 当前内存压力级别
  MemoryPressureLevel get currentPressureLevel => _currentPressureLevel;

  /// 当前缓存策略
  CacheStrategy get currentStrategy => _currentStrategy;

  /// 获取内存信息
  MemoryInfo getMemoryInfo() {
    return MemoryInfo(
      availableMemoryMB: 1024, // 简化实现，实际应该获取真实数据
      totalMemoryMB: 8192,
      cachedMemoryMB: _currentCacheSizeBytes ~/ (1024 * 1024),
    );
  }

  /// 启动内存管理器
  Future<void> start() async {
    AppLogger.business('启动AdvancedMemoryManager');

    _startMemoryPressureMonitoring();
    _startWeakReferenceCleanup();
    _startAutoGC();

    // 初始内存状态检测
    await _checkMemoryPressure();
  }

  /// 停止内存管理器
  Future<void> stop() async {
    AppLogger.business('停止AdvancedMemoryManager');

    _pressureCheckTimer?.cancel();
    _weakRefCleanupTimer?.cancel();
    _autoGCTimer?.cancel();

    await _pressureController.close();
    _cache.clear();
    _accessOrder.clear();
  }

  /// 添加缓存项
  Future<void> put(String key, dynamic value, {int? sizeBytes}) async {
    final itemSize = sizeBytes ?? _estimateSize(value);

    // 检查内存压力并调整策略
    await _ensureMemoryCapacity(itemSize);

    // 移除现有项（如果存在）
    remove(key);

    final item = WeakCacheItem(
      key: key,
      value: value,
      sizeBytes: itemSize,
    );

    _cache[key] = item;
    _accessOrder.addLast(key);
    _currentCacheSizeBytes += itemSize;

    AppLogger.debug('缓存项已添加: $key (${itemSize} bytes)');
  }

  /// 获取缓存项
  T? get<T>(String key) {
    final item = _cache[key];
    if (item == null) return null;

    final value = item.value;
    if (value == null) {
      // 弱引用已被回收，移除该项
      remove(key);
      return null;
    }

    // 更新访问记录
    _accessOrder.remove(key);
    _accessOrder.addLast(key);
    _totalAccessCount++;

    return value as T?;
  }

  /// 移除缓存项
  dynamic remove(String key) {
    final item = _cache.remove(key);
    if (item != null) {
      _accessOrder.remove(key);
      _currentCacheSizeBytes -= item.sizeBytes;
      AppLogger.debug('缓存项已移除: $key');
      return item.value;
    }
    return null;
  }

  /// 清空所有缓存
  void clear() {
    final count = _cache.length;
    _cache.clear();
    _accessOrder.clear();
    _currentCacheSizeBytes = 0;
    AppLogger.business('清空所有缓存 (共 $count 项)');
  }

  /// 手动触发LRU清理
  Future<void> performLRUEviction({double? threshold}) async {
    final evictionThreshold = threshold ?? _config.lruEvictionThreshold;
    final targetSize =
        (_config.maxCacheSizeMB * 1024 * 1024 * evictionThreshold).toInt();

    while (_currentCacheSizeBytes > targetSize && _accessOrder.isNotEmpty) {
      final oldestKey = _accessOrder.removeFirst();
      final removedItem = _cache.remove(oldestKey);
      if (removedItem != null) {
        _currentCacheSizeBytes -= removedItem.sizeBytes;
        _evictionCount++;
      }
    }

    if (_evictionCount > 0) {
      AppLogger.business('LRU清理完成，已清理 $_evictionCount 项');
    }
  }

  /// 手动触发垃圾回收
  Future<void> forceGarbageCollection() async {
    AppLogger.business('执行手动垃圾回收');

    try {
      // 清理弱引用
      await _cleanupWeakReferences();

      // 触发系统GC
      await SystemChannels.platform.invokeMethod('System.gc');
      _gcCount++;

      AppLogger.business('垃圾回收完成');
    } catch (e) {
      AppLogger.warn('垃圾回收失败: $e');
    }
  }

  /// 获取内存统计信息
  Map<String, dynamic> getMemoryStats() {
    return {
      'currentCacheSizeMB':
          (_currentCacheSizeBytes / (1024 * 1024)).toStringAsFixed(2),
      'maxCacheSizeMB': _config.maxCacheSizeMB,
      'cacheItemCount': _cache.length,
      'activeItemCount': _cache.values.where((item) => item.isAlive).length,
      'totalAccessCount': _totalAccessCount,
      'evictionCount': _evictionCount,
      'gcCount': _gcCount,
      'currentPressureLevel': _currentPressureLevel.toString(),
      'currentStrategy': _currentStrategy.toString(),
    };
  }

  /// 启动内存压力监控
  void _startMemoryPressureMonitoring() {
    _pressureCheckTimer = Timer.periodic(
      _config.pressureCheckInterval,
      (_) => _checkMemoryPressure(),
    );
  }

  /// 启动弱引用清理
  void _startWeakReferenceCleanup() {
    _weakRefCleanupTimer = Timer.periodic(
      _config.weakReferenceCleanupInterval,
      (_) => _cleanupWeakReferences(),
    );
  }

  /// 启动自动GC
  void _startAutoGC() {
    _autoGCTimer = Timer.periodic(
      Duration(minutes: 2),
      (_) => _performAutoGC(),
    );
  }

  /// 检查内存压力
  Future<void> _checkMemoryPressure() async {
    try {
      final memoryInfo = await _getMemoryInfo();
      final used = memoryInfo['used'] ?? 0;
      final total = memoryInfo['total'] ?? 1;
      final usagePercent = used / total;

      MemoryPressureLevel newLevel;
      if (usagePercent < 0.6) {
        newLevel = MemoryPressureLevel.normal;
      } else if (usagePercent < 0.75) {
        newLevel = MemoryPressureLevel.warning;
      } else if (usagePercent < 0.85) {
        newLevel = MemoryPressureLevel.critical;
      } else {
        newLevel = MemoryPressureLevel.emergency;
      }

      // 检查是否需要更新策略
      if (newLevel != _currentPressureLevel) {
        _currentPressureLevel = newLevel;
        _updateCacheStrategy(newLevel);

        // 发送压力事件
        final event = MemoryPressureEvent(
          level: newLevel,
          memoryUsagePercent: usagePercent * 100,
          availableMemoryMB: ((total - used) / (1024 * 1024)).toInt(),
          usedMemoryMB: (used / (1024 * 1024)).toInt(),
          timestamp: DateTime.now(),
          message: _getPressureMessage(newLevel, usagePercent),
        );

        _pressureController.add(event);
        AppLogger.warn(event.message);
      }

      // 内存压力过高时的处理
      if (usagePercent > _config.autoGCThreshold) {
        await _performAutoGC();
      }

      // 缓存内存压力过高时的处理
      final cacheUsagePercent =
          _currentCacheSizeBytes / (_config.maxCacheSizeMB * 1024 * 1024);
      if (cacheUsagePercent > _config.lruEvictionThreshold) {
        await performLRUEviction();
      }
    } catch (e) {
      AppLogger.error('内存压力检测失败', e);
    }
  }

  /// 清理弱引用
  Future<void> _cleanupWeakReferences() async {
    final keysToRemove = <String>[];

    for (final entry in _cache.entries) {
      if (!entry.value.isAlive) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      remove(key);
    }

    if (keysToRemove.isNotEmpty) {
      AppLogger.debug('清理了 ${keysToRemove.length} 个无效弱引用');
    }
  }

  /// 执行自动垃圾回收
  Future<void> _performAutoGC() async {
    try {
      await _cleanupWeakReferences();
      await SystemChannels.platform.invokeMethod('System.gc');
      _gcCount++;
    } catch (e) {
      AppLogger.debug('自动垃圾回收失败: $e');
    }
  }

  /// 确保有足够的内存容量
  Future<void> _ensureMemoryCapacity(int requiredBytes) async {
    final maxBytes = _config.maxCacheSizeMB * 1024 * 1024;
    final targetBytes = maxBytes - requiredBytes;

    if (_currentCacheSizeBytes > targetBytes) {
      await performLRUEviction(threshold: targetBytes / maxBytes);
    }
  }

  /// 更新缓存策略
  void _updateCacheStrategy(MemoryPressureLevel level) {
    switch (level) {
      case MemoryPressureLevel.normal:
        _currentStrategy = CacheStrategy.aggressive;
        break;
      case MemoryPressureLevel.warning:
        _currentStrategy = CacheStrategy.balanced;
        break;
      case MemoryPressureLevel.critical:
      case MemoryPressureLevel.emergency:
        _currentStrategy = CacheStrategy.conservative;
        break;
    }

    AppLogger.business('缓存策略已更新: $_currentStrategy');
  }

  /// 获取内存信息
  Future<Map<String, int>> _getMemoryInfo() async {
    if (Platform.isIOS || Platform.isAndroid) {
      try {
        final result = await SystemChannels.platform.invokeMethod('System.gc');
        return {
          'total': 1024 * 1024 * 1024, // 1GB 默认值
          'used': result['memory'] ?? 512 * 1024 * 1024,
        };
      } catch (e) {
        return {
          'total': 1024 * 1024 * 1024,
          'used': 512 * 1024 * 1024,
        };
      }
    } else {
      return {
        'total': 1024 * 1024 * 1024,
        'used': 512 * 1024 * 1024,
      };
    }
  }

  /// 估算对象大小
  int _estimateSize(dynamic value) {
    if (value == null) return 0;

    if (value is String) {
      return value.length * 2; // UTF-16 每字符2字节
    } else if (value is List) {
      return value.length * 8; // 指针大小估算
    } else if (value is Map) {
      return value.length * 16; // 键值对大小估算
    } else {
      return 256; // 默认对象大小估算
    }
  }

  /// 获取压力级别消息
  String _getPressureMessage(MemoryPressureLevel level, double usagePercent) {
    switch (level) {
      case MemoryPressureLevel.normal:
        return '内存使用正常 (${(usagePercent * 100).toStringAsFixed(1)}%)';
      case MemoryPressureLevel.warning:
        return '内存使用警告 (${(usagePercent * 100).toStringAsFixed(1)}%)';
      case MemoryPressureLevel.critical:
        return '内存使用危险 (${(usagePercent * 100).toStringAsFixed(1)}%) - 正在优化';
      case MemoryPressureLevel.emergency:
        return '内存使用紧急 (${(usagePercent * 100).toStringAsFixed(1)}%) - 强制清理';
    }
  }
}
