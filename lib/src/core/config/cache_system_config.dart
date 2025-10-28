import '../cache/interfaces/cache_service.dart';
import '../cache/unified_hive_cache_manager.dart';
import '../cache/adapters/unified_cache_adapter.dart';
import '../cache/adapters/legacy_cache_adapter.dart';
import '../cache/hive_cache_manager.dart';
import 'package:get_it/get_it.dart';

/// 缓存系统配置
///
/// 管理缓存系统的配置和切换
/// 支持新旧缓存系统的快速切换，确保向后兼容性
class CacheSystemConfig {
  static const String _tag = 'CacheSystemConfig';

  /// 是否使用统一缓存系统
  ///
  /// true: 使用 UnifiedHiveCacheManager + UnifiedCacheAdapter
  /// false: 使用原有的 HiveCacheManager + LegacyCacheAdapter (回滚模式)
  static bool useUnifiedCache = true;

  /// 获取缓存服务实例
  ///
  /// 根据配置返回相应的缓存服务适配器
  /// [sl] 依赖注入容器实例
  ///
  /// 返回实现了 CacheService 接口的缓存服务实例
  static CacheService getCacheService({GetIt? sl}) {
    sl ??= GetIt.instance;

    try {
      if (useUnifiedCache) {
        // 使用统一缓存系统
        final unifiedManager = sl.get<UnifiedHiveCacheManager>();
        return UnifiedCacheAdapter(unifiedManager);
      } else {
        // 使用传统缓存系统 (回滚模式)
        final legacyManager = sl.get<HiveCacheManager>();
        return LegacyCacheAdapter(legacyManager);
      }
    } catch (e) {
      // 如果获取缓存服务失败，抛出异常
      throw Exception(
          'Failed to get cache service. useUnifiedCache: $useUnifiedCache, Error: $e');
    }
  }

  /// 切换到统一缓存系统
  ///
  /// 启用新的 UnifiedHiveCacheManager 缓存系统
  static void enableUnifiedCache() {
    _logConfigChange('Unified Cache System ENABLED');
    useUnifiedCache = true;
  }

  /// 切换到传统缓存系统
  ///
  /// 回滚到原有的 HiveCacheManager 缓存系统
  /// 用于紧急回滚或兼容性处理
  static void enableLegacyCache() {
    _logConfigChange('Legacy Cache System ENABLED (Rollback mode)');
    useUnifiedCache = false;
  }

  /// 获取当前缓存系统配置信息
  ///
  /// 返回当前缓存系统的配置状态
  static Map<String, dynamic> getCurrentConfig() {
    return {
      'useUnifiedCache': useUnifiedCache,
      'cacheSystem':
          useUnifiedCache ? 'UnifiedHiveCacheManager' : 'HiveCacheManager',
      'adapter': useUnifiedCache ? 'UnifiedCacheAdapter' : 'LegacyCacheAdapter',
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
      // 检查依赖注入容器中是否注册了必要的缓存管理器
      if (useUnifiedCache) {
        if (!sl.isRegistered<UnifiedHiveCacheManager>()) {
          result['errors'].add(
              'UnifiedHiveCacheManager not registered in dependency injection');
        }
      } else {
        if (!sl.isRegistered<HiveCacheManager>()) {
          result['errors']
              .add('HiveCacheManager not registered in dependency injection');
        }
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
    useUnifiedCache = true;
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

    if (!useUnifiedCache) {
      recommendations.add('建议启用统一缓存系统以获得更好的性能和功能');
      recommendations.add('可以调用 CacheSystemConfig.enableUnifiedCache() 来切换');
    }

    recommendations.add('定期执行缓存系统验证：CacheSystemConfig.validateCacheConfig()');
    recommendations.add('监控缓存性能和使用情况');

    return {
      'recommendations': recommendations,
      'warnings': warnings,
      'currentConfig': getCurrentConfig(),
    };
  }
}
