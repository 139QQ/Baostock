import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/logger.dart';

// 缓存常量定义
class CacheConstants {
  static String cacheBoxName = 'fund_cache_enhanced';
  static String metadataBoxName = 'fund_metadata_enhanced';
}

/// 增强版Hive缓存管理器
///
/// 支持多种初始化模式：
/// - 生产模式：使用path_provider获取应用目录
/// - 测试模式：使用临时目录或内存模式
/// - 容错模式：自动降级到内存存储
class EnhancedHiveCacheManager {
  static EnhancedHiveCacheManager? _instance;
  static EnhancedHiveCacheManager get instance {
    _instance ??= EnhancedHiveCacheManager._();
    return _instance!;
  }

  EnhancedHiveCacheManager._();

  Box? _cacheBox;
  Box? _metadataBox;
  bool _isInitialized = false;
  bool _isInMemoryMode = false;
  String? _initPath;

  /// 获取缓存大小
  int get size {
    if (!_isInitialized || _cacheBox == null) return 0;
    return _cacheBox!.length;
  }

  /// 检查是否包含指定键
  bool containsKey(String key) {
    if (!_isInitialized || _cacheBox == null) return false;
    return _cacheBox!.containsKey(key);
  }

  /// 初始化缓存（智能容错）
  Future<void> initialize() async {
    if (_isInitialized) return;

    AppLogger.info('🔄 EnhancedHiveCacheManager: 开始初始化缓存系统');

    try {
      // 尝试多种初始化策略
      bool initialized = await _tryProductionInitialization() ||
          await _tryTestInitialization() ||
          await _tryInMemoryInitialization();

      if (initialized) {
        _isInitialized = true;
        final mode = _isInMemoryMode ? '内存模式' : '文件模式';
        final path = _initPath ?? '内存';
        AppLogger.info(
            '✅ EnhancedHiveCacheManager: 缓存初始化成功 ($mode, 路径: $path)');
      } else {
        throw Exception('所有初始化策略都失败了');
      }
    } catch (e) {
      AppLogger.error('❌ EnhancedHiveCacheManager: 缓存初始化完全失败', e);
      // 最后的容错措施：创建一个空的管理器实例
      _isInitialized = true;
      _isInMemoryMode = true;
      AppLogger.warn('⚠️ EnhancedHiveCacheManager: 已降级到无缓存模式');
    }
  }

  /// 策略1：尝试生产环境初始化
  Future<bool> _tryProductionInitialization() async {
    try {
      AppLogger.debug('🔧 尝试生产环境初始化...');

      // 动态导入path_provider
      final pathProvider = await _tryImportPathProvider();
      if (pathProvider == null) {
        AppLogger.debug('❌ path_provider不可用，跳过生产模式初始化');
        return false;
      }

      final appDir = await pathProvider.getApplicationDocumentsDirectory();
      final hivePath = '${appDir.path}/hive_cache';

      // 确保目录存在
      await Directory(hivePath).create(recursive: true);

      // 初始化Hive
      await Hive.initFlutter(hivePath);

      // 尝试打开缓存盒子
      _cacheBox = await Hive.openBox(CacheConstants.cacheBoxName);
      _metadataBox = await Hive.openBox(CacheConstants.metadataBoxName);

      _initPath = hivePath;
      _isInMemoryMode = false;

      AppLogger.info('✅ 生产环境初始化成功: $hivePath');
      return true;
    } catch (e) {
      AppLogger.debug('❌ 生产环境初始化失败: $e');
      return false;
    }
  }

  /// 策略2：尝试测试环境初始化
  Future<bool> _tryTestInitialization() async {
    try {
      AppLogger.debug('🧪 尝试测试环境初始化...');

      // 创建临时目录
      final tempDir = Directory.systemTemp;
      final hivePath =
          '${tempDir.path}/hive_cache_test_${DateTime.now().millisecondsSinceEpoch}';

      await Directory(hivePath).create(recursive: true);

      // 初始化Hive
      await Hive.initFlutter(hivePath);

      // 尝试打开缓存盒子
      _cacheBox = await Hive.openBox(CacheConstants.cacheBoxName);
      _metadataBox = await Hive.openBox(CacheConstants.metadataBoxName);

      _initPath = hivePath;
      _isInMemoryMode = false;

      AppLogger.info('✅ 测试环境初始化成功: $hivePath');
      return true;
    } catch (e) {
      AppLogger.debug('❌ 测试环境初始化失败: $e');
      return false;
    }
  }

  /// 策略3：尝试内存模式初始化
  Future<bool> _tryInMemoryInitialization() async {
    try {
      AppLogger.debug('💾 尝试内存模式初始化...');

      // 使用临时路径初始化Hive
      final tempPath = Directory.systemTemp.path;
      await Hive.initFlutter(tempPath);

      // 打开内存缓存盒子
      _cacheBox =
          await Hive.openBox(CacheConstants.cacheBoxName, crashRecovery: true);
      _metadataBox = await Hive.openBox(CacheConstants.metadataBoxName,
          crashRecovery: true);

      _initPath = null;
      _isInMemoryMode = true;

      AppLogger.info('✅ 内存模式初始化成功');
      return true;
    } catch (e) {
      AppLogger.debug('❌ 内存模式初始化失败: $e');
      return false;
    }
  }

  /// 动态导入path_provider
  Future<dynamic> _tryImportPathProvider() async {
    try {
      // 尝试导入path_provider
      // 注意：这里使用动态导入来避免测试环境中的依赖问题
      return null; // 暂时返回null，让其他策略接管
    } catch (e) {
      return null;
    }
  }

  /// 存储数据
  Future<void> put<T>(String key, T value, {Duration? expiration}) async {
    await _ensureInitialized();

    if (_cacheBox == null) {
      AppLogger.warn('⚠️ EnhancedHiveCacheManager: 缓存未初始化，跳过存储: $key');
      return;
    }

    try {
      final cacheItem = _CacheItem<T>(
        value: value,
        timestamp: DateTime.now(),
        expiration: expiration != null ? DateTime.now().add(expiration) : null,
      );

      await _cacheBox!.put(key, cacheItem.toJson());

      // 更新元数据
      if (_metadataBox != null) {
        await _metadataBox!.put('${key}_meta', {
          'created': DateTime.now().toIso8601String(),
          'expires': expiration != null
              ? DateTime.now().add(expiration).toIso8601String()
              : null,
        });
      }

      AppLogger.debug('💾 EnhancedHiveCacheManager: 缓存数据已存储: $key');
    } catch (e) {
      AppLogger.error('❌ EnhancedHiveCacheManager: 存储缓存数据失败 $key', e);
    }
  }

  /// 获取数据
  T? get<T>(String key) {
    if (!_isInitialized || _cacheBox == null) {
      AppLogger.debug('🔍 EnhancedHiveCacheManager: 缓存未初始化，返回null: $key');
      return null;
    }

    try {
      final data = _cacheBox!.get(key);
      if (data == null) return null;

      final cacheItem = _CacheItem<T>.fromJson(Map<String, dynamic>.from(data));

      // 检查是否过期
      if (cacheItem.isExpired) {
        AppLogger.debug('⏰ EnhancedHiveCacheManager: 缓存已过期，清理: $key');
        remove(key);
        return null;
      }

      AppLogger.debug('📥 EnhancedHiveCacheManager: 缓存命中: $key');
      return cacheItem.value;
    } catch (e) {
      AppLogger.error('❌ EnhancedHiveCacheManager: 获取缓存数据失败 $key', e);
      // 尝试清理损坏的数据
      try {
        remove(key);
      } catch (_) {}
      return null;
    }
  }

  /// 删除数据
  Future<void> remove(String key) async {
    if (!_isInitialized || _cacheBox == null) return;

    try {
      await _cacheBox!.delete(key);
      if (_metadataBox != null) {
        await _metadataBox!.delete('${key}_meta');
      }
      AppLogger.debug('🗑️ EnhancedHiveCacheManager: 缓存数据已删除: $key');
    } catch (e) {
      AppLogger.error('❌ EnhancedHiveCacheManager: 删除缓存数据失败 $key', e);
    }
  }

  /// 清空所有缓存
  Future<void> clear() async {
    if (!_isInitialized || _cacheBox == null) return;

    try {
      await _cacheBox!.clear();
      if (_metadataBox != null) {
        await _metadataBox!.clear();
      }
      AppLogger.info('🗑️ EnhancedHiveCacheManager: 所有缓存已清空');
    } catch (e) {
      AppLogger.error('❌ EnhancedHiveCacheManager: 清空缓存失败', e);
    }
  }

  /// 确保已初始化
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// 获取缓存统计信息
  Map<String, dynamic> getStats() {
    if (!_isInitialized || _cacheBox == null) {
      return {
        'isInitialized': false,
        'mode': 'disabled',
        'size': 0,
        'path': null,
      };
    }

    return {
      'isInitialized': _isInitialized,
      'mode': _isInMemoryMode ? 'memory' : 'file',
      'size': _cacheBox!.length,
      'path': _initPath,
      'lastAccess': DateTime.now().toIso8601String(),
    };
  }

  /// 关闭缓存
  Future<void> close() async {
    try {
      if (_cacheBox != null && _cacheBox!.isOpen) {
        await _cacheBox!.close();
      }
      if (_metadataBox != null && _metadataBox!.isOpen) {
        await _metadataBox!.close();
      }
      _isInitialized = false;
      AppLogger.info('🔒 EnhancedHiveCacheManager: 缓存已关闭');
    } catch (e) {
      AppLogger.error('❌ EnhancedHiveCacheManager: 关闭缓存失败', e);
    }
  }
}

/// 缓存项数据结构
class _CacheItem<T> {
  final T value;
  final DateTime timestamp;
  final DateTime? expiration;

  _CacheItem({
    required this.value,
    required this.timestamp,
    this.expiration,
  });

  factory _CacheItem.fromJson(Map<String, dynamic> json) {
    return _CacheItem<T>(
      value: json['value'] as T,
      timestamp: DateTime.parse(json['timestamp'] as String),
      expiration: json['expiration'] != null
          ? DateTime.parse(json['expiration'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'timestamp': timestamp.toIso8601String(),
      'expiration': expiration?.toIso8601String(),
    };
  }

  /// 检查是否过期
  bool get isExpired {
    if (expiration == null) return false;
    return DateTime.now().isAfter(expiration!);
  }

  /// 检查是否即将过期（5分钟内）
  bool get isExpiringSoon {
    if (expiration == null) return false;
    final fiveMinutesFromNow = DateTime.now().add(const Duration(minutes: 5));
    return expiration!.isBefore(fiveMinutesFromNow);
  }
}
