import 'package:jisu_fund_analyzer/src/core/cache/interfaces/i_unified_cache_service.dart';
import 'package:jisu_fund_analyzer/src/core/cache/unified_cache_manager.dart';
import 'package:jisu_fund_analyzer/src/core/cache/storage/cache_storage.dart';
import 'package:jisu_fund_analyzer/src/core/cache/strategies/cache_strategies.dart';
import 'package:jisu_fund_analyzer/src/core/cache/config/cache_config_manager.dart';

/// 测试缓存服务工厂
class TestCacheServiceFactory {
  /// 创建性能测试用的缓存服务
  static Future<IUnifiedCacheService>
      createPerformanceTestCacheService() async {
    final storage = CacheStorageFactory.createMemoryStorage();
    await storage.initialize(); // 初始化存储层
    final strategy = CacheStrategyFactory.getStrategy('lru');
    final configManager = CacheConfigManager();

    final manager = UnifiedCacheManager(
      storage: storage,
      strategy: strategy,
      configManager: configManager,
      config: UnifiedCacheConfig.testing(),
    );
    return manager;
  }
}
