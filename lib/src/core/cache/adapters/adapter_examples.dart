/// 缓存适配器使用示例
///
/// 展示如何正确使用各种缓存适配器
// ignore_for_file: non_constant_identifier_names, avoid_print, unused_local_variable, duplicate_ignore

library adapter_examples;

import 'cache_adapter_factory.dart';
import '../unified_hive_cache_manager.dart';

/// 适配器使用示例
class AdapterUsageExamples {
  /// 示例1：创建统一缓存适配器
  static Future<void> example1_UnifiedCacheAdapter() async {
    print('=== 示例1：创建统一缓存适配器 ===');

    // 创建统一Hive缓存管理器
    final cacheManager = UnifiedHiveCacheManager.instance;
    await cacheManager.initialize();

    // 创建适配器
    final adapter = CacheAdapterFactory.createUnifiedCacheAdapter(cacheManager);

    // 使用适配器
    await adapter.put('test_key', 'test_value');
    final value = await adapter.get<String>('test_key');
    print('获取的值: $value');

    // 获取统计信息
    final stats = await adapter.getStatistics();
    print('缓存统计: ${stats.totalCount} 个条目');
  }

  /// 示例2：批量缓存操作
  static Future<void> example2_BatchCacheOperations() async {
    print('=== 示例2：批量缓存操作 ===');

    // 创建缓存适配器
    final adapter = CacheAdapterFactory.createUnifiedCacheAdapter(
      UnifiedHiveCacheManager.instance,
    );

    // 批量存储数据
    final batchData = {
      'fund_001': {'name': '易方达蓝筹精选', 'code': '110022'},
      'fund_002': {'name': '华夏大盘精选', 'code': '000001'},
      'fund_003': {'name': '嘉实沪深300', 'code': '160716'},
    };

    await adapter.putAll(batchData);
    print('批量存储了 ${batchData.length} 个基金数据');

    // 批量获取数据
    final keys = batchData.keys.toList();
    final results = await adapter.getAll<Map<String, dynamic>>(keys);

    print('批量获取的数据:');
    for (final entry in results.entries) {
      print('  ${entry.key}: ${entry.value}');
    }
  }

  // ignore: non_constant_identifier_names
  /// 示例3：创建分层缓存适配器
  static Future<void> example3_LayeredCacheAdapter() async {
    print('=== 示例3：创建分层缓存适配器 ===');

    // 使用现有的缓存管理器创建分层缓存
    final cacheManager1 = UnifiedHiveCacheManager.instance;
    await cacheManager1.initialize();

    // 创建第二个缓存管理器实例用于分层
    final cacheManager2 = UnifiedHiveCacheManager.instance;

    // 创建适配器
    final adapter1 =
        CacheAdapterFactory.createUnifiedCacheAdapter(cacheManager1);
    final adapter2 =
        CacheAdapterFactory.createUnifiedCacheAdapter(cacheManager2);

    // 创建分层缓存配置
    final layerConfigs = [
      CacheLayerConfig(
        service: cacheManager1,
        type: CacheAdapterType.unifiedHive,
        strategy: CacheLayerStrategy.cacheAside,
      ),
      CacheLayerConfig(
        service: cacheManager2,
        type: CacheAdapterType.unifiedHive,
      ),
    ];

    // 创建分层缓存适配器
    final layeredAdapter = CacheAdapterFactory.createAdapterChain(layerConfigs);

    // 使用分层缓存
    await layeredAdapter.put('user_data', {'name': '张三', 'age': 30});
    final userData =
        await layeredAdapter.get<Map<String, dynamic>>('user_data');
    print('用户数据: $userData');

    // 获取分层统计信息
    final stats = await layeredAdapter.getStatistics();
    print(
        '分层缓存统计: ${stats.totalCount} 个条目，命中率: ${(stats.hitRate * 100).toStringAsFixed(1)}%');
  }

  /// 示例4：自动适配器类型推断
  static Future<void> example4_AutoAdapterInference() async {
    print('=== 示例4：自动适配器类型推断 ===');

    // 创建不同的缓存服务
    final services = [
      UnifiedHiveCacheManager.instance,
    ];

    // 自动创建适配器
    for (final service in services) {
      try {
        final adapter = CacheAdapterFactory.createAdapter(service);
        print('为 ${service.runtimeType} 创建了适配器: ${adapter.runtimeType}');
      } catch (e) {
        print('为 ${service.runtimeType} 创建适配器失败: $e');
      }
    }
  }

  /// 示例5：适配器工厂统计和管理
  static Future<void> example5_AdapterFactoryManagement() async {
    print('=== 示例5：适配器工厂统计和管理 ===');

    // 创建多个适配器
    final cacheManager = UnifiedHiveCacheManager.instance;

    final adapter1 = CacheAdapterFactory.createAdapter(cacheManager);
    final adapter2 =
        CacheAdapterFactory.createUnifiedCacheAdapter(cacheManager);

    // 获取适配器统计信息
    final stats = CacheAdapterFactory.getAdapterStatistics();
    print('适配器统计:');
    print('  总数: ${stats['totalAdapters']}');
    print('  类型分布: ${stats['adapterTypes']}');

    // 获取所有适配器
    final allAdapters = CacheAdapterFactory.getAllAdapters();
    print('所有适配器数量: ${allAdapters.length}');

    // 清理适配器缓存
    CacheAdapterFactory.clearAdapterCache();
    print('已清理适配器缓存');
  }

  /// 运行所有示例
  static Future<void> runAllExamples() async {
    print('🚀 开始运行缓存适配器示例...\n');

    try {
      await example1_UnifiedCacheAdapter();
      print('');

      await example2_BatchCacheOperations();
      print('');

      await example3_LayeredCacheAdapter();
      print('');

      await example4_AutoAdapterInference();
      print('');

      await example5_AdapterFactoryManagement();
      print('');

      print('✅ 所有适配器示例运行完成！');
    } catch (e, stackTrace) {
      print('❌ 运行示例时出错: $e');
      print('堆栈跟踪: $stackTrace');
    }
  }
}

/// 推荐的适配器配置
class RecommendedAdapterConfigurations {
  /// 推荐的生产环境配置
  static List<CacheLayerConfig> productionConfig() {
    return [
      // L1: 统一Hive缓存（快速访问）
      CacheLayerConfig(
        service: UnifiedHiveCacheManager.instance,
        type: CacheAdapterType.unifiedHive,
        strategy: CacheLayerStrategy.cacheAside,
      ),
      // L2: 第二个缓存实例（持久存储）
      CacheLayerConfig(
        service: UnifiedHiveCacheManager.instance,
        type: CacheAdapterType.unifiedHive,
      ),
    ];
  }

  /// 推荐的开发环境配置
  static List<CacheLayerConfig> developmentConfig() {
    return [
      CacheLayerConfig(
        service: UnifiedHiveCacheManager.instance,
        type: CacheAdapterType.unifiedHive,
      ),
    ];
  }

  /// 推荐的测试环境配置
  static List<CacheLayerConfig> testingConfig() {
    return [
      CacheLayerConfig(
        service: UnifiedHiveCacheManager.instance,
        type: CacheAdapterType.unifiedHive,
      ),
    ];
  }
}

/// 适配器最佳实践指南
class AdapterBestPractices {
  /// 最佳实践1：选择合适的适配器类型
  static void chooseRightAdapter() {
    print('🎯 最佳实践1：选择合适的适配器类型');
    print('- 新项目：使用 UnifiedCacheManager');
    print('- 现有项目：使用相应的适配器（SearchCacheAdapter, FilterCacheAdapter等）');
    print('- 高性能需求：使用分层缓存适配器');
    print('- 简单场景：使用单一适配器');
  }

  /// 最佳实践2：配置合适的缓存策略
  static void configureCacheStrategy() {
    print('🎯 最佳实践2：配置合适的缓存策略');
    print('- 读多写少：使用 LRU 策略');
    print('- 频繁访问：使用 LFU 策略');
    print('- 时间敏感：使用 TTL 策略');
    print('- 复杂场景：使用 Adaptive 策略');
    print('- 平衡需求：使用 Hybrid 策略');
  }

  /// 最佳实践3：设置合理的过期时间
  static void setExpirationTimes() {
    print('🎯 最佳实践3：设置合理的过期时间');
    print('- 用户数据：30分钟 - 2小时');
    print('- 搜索结果：15分钟 - 1小时');
    print('- 配置数据：24小时 - 7天');
    print('- 静态数据：1周 - 1个月');
    print('- 临时数据：5分钟 - 30分钟');
  }

  /// 最佳实践4：监控缓存性能
  static void monitorPerformance() {
    print('🎯 最佳实践4：监控缓存性能');
    print('- 定期检查命中率（目标：>80%）');
    print('- 监控内存使用情况');
    print('- 跟踪响应时间');
    print('- 分析缓存模式');
    print('- 优化缓存配置');
  }

  /// 最佳实践5：处理缓存失效
  static void handleCacheInvalidation() {
    print('🎯 最佳实践5：处理缓存失效');
    print('- 实现主动失效机制');
    print('- 使用版本号控制');
    print('- 设置合理的TTL');
    print('- 监听数据变化事件');
    print('- 提供手动清理接口');
  }

  /// 显示所有最佳实践
  static void showAllBestPractices() {
    print('📚 缓存适配器最佳实践指南\n');
    chooseRightAdapter();
    print('');
    configureCacheStrategy();
    print('');
    setExpirationTimes();
    print('');
    monitorPerformance();
    print('');
    handleCacheInvalidation();
  }
}
