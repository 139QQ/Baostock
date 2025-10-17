import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/logger.dart';

// 缓存常量定义
class CacheConstants {
  static String cacheBoxName = 'fund_cache';
  static String metadataBoxName = 'fund_metadata';
}

/// Hive缓存管理器
/// 提供高性能的本地缓存解决方案
class HiveCacheManager {
  static HiveCacheManager? _instance;
  static HiveCacheManager get instance {
    _instance ??= HiveCacheManager._();
    return _instance!;
  }

  HiveCacheManager._();

  late Box _cacheBox;
  late Box _metadataBox;
  bool _isInitialized = false;

  /// 初始化缓存
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(appDir.path);

      // 注册适配器
      if (!Hive.isAdapterRegistered(0)) {
        // TODO: 注册必要的适配器
      }

      // 打开缓存盒子
      _cacheBox = await Hive.openBox(CacheConstants.cacheBoxName);
      _metadataBox = await Hive.openBox(CacheConstants.metadataBoxName);

      _isInitialized = true;
      AppLogger.info('Hive缓存初始化成功');
    } catch (e) {
      AppLogger.error('Hive缓存初始化失败', e);
      rethrow;
    }
  }

  /// 存储数据
  Future<void> put<T>(String key, T value, {Duration? expiration}) async {
    await _ensureInitialized();

    try {
      final cacheItem = _CacheItem<T>(
        value: value,
        timestamp: DateTime.now(),
        expiration: expiration != null ? DateTime.now().add(expiration) : null,
      );

      await _cacheBox.put(key, cacheItem.toJson());

      // 更新元数据
      await _metadataBox.put('${key}_meta', {
        'created': DateTime.now().toIso8601String(),
        'expires': expiration != null
            ? DateTime.now().add(expiration).toIso8601String()
            : null,
      });

      AppLogger.debug('缓存数据已存储: $key');
    } catch (e) {
      AppLogger.error('存储缓存数据失败 $key', e);
    }
  }

  /// 获取数据
  T? get<T>(String key) {
    if (!_isInitialized) {
      AppLogger.warn('缓存未初始化，无法获取数据: $key');
      return null;
    }

    try {
      final data = _cacheBox.get(key);
      if (data == null) return null;

      final cacheItem = _CacheItem<T>.fromJson(Map<String, dynamic>.from(data));

      // 检查是否过期
      if (cacheItem.isExpired) {
        remove(key);
        return null;
      }

      AppLogger.debug('缓存数据命中: $key');
      return cacheItem.value;
    } catch (e) {
      AppLogger.error('获取缓存数据失败 $key', e);
      return null;
    }
  }

  /// 移除数据
  Future<void> remove(String key) async {
    await _ensureInitialized();

    try {
      await _cacheBox.delete(key);
      await _metadataBox.delete('${key}_meta');
      AppLogger.debug('缓存数据已移除: $key');
    } catch (e) {
      AppLogger.error('移除缓存数据失败 $key', e);
    }
  }

  /// 清空所有缓存
  Future<void> clear() async {
    await _ensureInitialized();

    try {
      await _cacheBox.clear();
      await _metadataBox.clear();
      AppLogger.info('所有缓存已清空');
    } catch (e) {
      AppLogger.error('清空缓存失败', e);
    }
  }

  /// 检查键是否存在
  bool containsKey(String key) {
    if (!_isInitialized) return false;
    return _cacheBox.containsKey(key);
  }

  /// 获取缓存大小
  int get size {
    if (!_isInitialized) return 0;
    return _cacheBox.length;
  }

  /// 获取缓存盒子（用于依赖注入）
  Box get cacheBox {
    if (!_isInitialized) throw StateError('Hive缓存未初始化');
    return _cacheBox;
  }

  /// 清理过期缓存
  Future<void> clearExpiredCache() async {
    await _ensureInitialized();

    try {
      final keys = _cacheBox.keys.toList();
      int removedCount = 0;

      for (final key in keys) {
        final data = _cacheBox.get(key);
        if (data != null) {
          try {
            final cacheItem =
                _CacheItem<dynamic>.fromJson(Map<String, dynamic>.from(data));
            if (cacheItem.isExpired) {
              await remove(key.toString());
              removedCount++;
            }
          } catch (e) {
            // 如果解析失败，直接删除损坏的数据
            await remove(key.toString());
            removedCount++;
          }
        }
      }

      AppLogger.info('清理过期缓存完成，删除 $removedCount 项');
    } catch (e) {
      AppLogger.error('清理过期缓存失败', e);
    }
  }

  /// 获取缓存统计信息
  Map<String, dynamic> getStats() {
    if (!_isInitialized) {
      return {
        'initialized': false,
        'size': 0,
      };
    }

    return {
      'initialized': true,
      'size': size,
      'cacheBoxSize': _cacheBox.length,
      'metadataBoxSize': _metadataBox.length,
    };
  }

  /// 确保已初始化
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// 关闭缓存
  Future<void> close() async {
    if (_isInitialized) {
      await _cacheBox.close();
      await _metadataBox.close();
      _isInitialized = false;
      AppLogger.info('Hive缓存已关闭');
    }
  }
}

/// 缓存项
class _CacheItem<T> {
  final T value;
  final DateTime timestamp;
  final DateTime? expiration;

  _CacheItem({
    required this.value,
    required this.timestamp,
    this.expiration,
  });

  /// 是否过期
  bool get isExpired {
    if (expiration == null) return false;
    return DateTime.now().isAfter(expiration!);
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'timestamp': timestamp.toIso8601String(),
      'expiration': expiration?.toIso8601String(),
    };
  }

  /// 从JSON创建
  factory _CacheItem.fromJson(Map<String, dynamic> json) {
    return _CacheItem<T>(
      value: json['value'] as T,
      timestamp: DateTime.parse(json['timestamp']),
      expiration: json['expiration'] != null
          ? DateTime.parse(json['expiration'])
          : null,
    );
  }
}
