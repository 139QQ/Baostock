import '../cache/interfaces/cache_service.dart';
import '../cache/unified_hive_cache_manager.dart';
import '../cache/adapters/unified_cache_adapter.dart';
import 'package:get_it/get_it.dart';

/// 缓存系统配置
///
/// 管理统一缓存系统的配置
/// 仅使用 UnifiedHiveCacheManager 缓存系统
class CacheSystemConfig {
  static const String _tag = 'CacheSystemConfig';

  // 配置状态跟踪
  static bool _useUnifiedCache = true;

  /// 获取缓存服务实例
  ///
  /// 返回统一缓存系统的缓存服务适配器
  /// [sl] 依赖注入容器实例
  ///
  /// 返回实现了 CacheService 接口的缓存服务实例
  static CacheService getCacheService({GetIt? sl}) {
    sl ??= GetIt.instance;

    try {
      // 使用统一缓存系统
      final unifiedManager = sl.get<UnifiedHiveCacheManager>();
      return UnifiedCacheAdapter(unifiedManager) as CacheService;
    } catch (e) {
      // 如果获取缓存服务失败，抛出异常
      throw Exception('Failed to get unified cache service. Error: $e');
    }
  }

  /// 获取当前缓存系统配置信息
  ///
  /// 返回当前缓存系统的配置状态
  static Map<String, dynamic> getCurrentConfig() {
    return {
      'cacheSystem': 'UnifiedHiveCacheManager',
      'adapter': 'UnifiedCacheAdapter',
      'useUnifiedCache': _useUnifiedCache, // 使用当前配置状态
      'cacheType': getCurrentCacheType(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// 验证缓存系统配置
  ///
  /// 检查当前缓存系统配置是否有效
  /// [sl] 依赖注入容器实例
  ///
  /// 返回验证结果，包含是否有效和相关错误信息
  static Future<Map<String, dynamic>> validateCacheConfig({GetIt? sl}) async {
    sl ??= GetIt.instance;

    final result = <String, dynamic>{
      'isValid': false,
      'errors': <String>[],
      'warnings': <String>[],
      'config': getCurrentConfig(),
    };

    try {
      // 检查依赖注入容器中是否注册了统一缓存管理器
      if (!sl.isRegistered<UnifiedHiveCacheManager>()) {
        result['errors'].add(
            'UnifiedHiveCacheManager not registered in dependency injection');
      }

      // 尝试获取缓存服务实例
      final cacheService = getCacheService(sl: sl);

      // 执行基本的缓存操作测试
      await cacheService.put('__test_key__', 'test_value');
      final testValue = await cacheService.get('__test_key__');
      await cacheService.remove('__test_key__');

      if (testValue != 'test_value') {
        result['errors'].add('Cache service basic operations test failed');
      }

      result['isValid'] = result['errors'].isEmpty;
    } catch (e) {
      result['errors'].add('Cache system validation failed: $e');
    }

    return result;
  }

  /// 重置为默认配置
  ///
  /// 恢复到推荐配置（使用统一缓存系统）
  static void resetToDefault() {
    _logConfigChange('Cache config reset to default (Unified Cache)');
    // 已经是统一缓存系统，无需更改
  }

  /// 记录配置变更日志
  ///
  /// [message] 配置变更描述
  static void _logConfigChange(String message) {
    print(
        '[CacheSystemConfig] $message at ${DateTime.now().toIso8601String()}');
    // TODO: 集成到项目日志系统
    // AppLogger.info(_tag, message);
  }

  /// 获取缓存系统迁移建议
  ///
  /// 根据当前状态提供缓存系统优化建议
  static Map<String, dynamic> getMigrationRecommendations() {
    final recommendations = <String>[];
    final warnings = <String>[];

    // 当前使用统一缓存系统，无需迁移建议
    recommendations.add('定期执行缓存系统验证：CacheSystemConfig.validateCacheConfig()');
    recommendations.add('监控缓存性能和使用情况');

    return {
      'recommendations': recommendations,
      'warnings': warnings,
      'currentConfig': getCurrentConfig(),
    };
  }

  /// 启用统一缓存系统
  ///
  /// 配置系统使用统一缓存管理器
  static void enableUnifiedCache() {
    _useUnifiedCache = true;
    _logConfigChange('Unified cache system enabled');
  }

  /// 启用传统缓存系统
  ///
  /// 配置系统使用传统缓存管理器（仅用于测试和兼容性）
  static void enableLegacyCache() {
    _useUnifiedCache = false;
    _logConfigChange('Legacy cache system enabled (for testing only)');
  }

  /// 获取当前缓存系统类型
  ///
  /// 返回当前使用的缓存系统类型
  static String getCurrentCacheType() {
    return 'unified'; // 当前只支持统一缓存系统
  }
}
