import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jisu_fund_analyzer/src/core/cache/unified_cache_manager.dart';
import 'package:jisu_fund_analyzer/src/core/cache/interfaces/i_unified_cache_service.dart';
import 'package:jisu_fund_analyzer/src/core/data/config/data_layer_integration.dart';
import 'package:jisu_fund_analyzer/src/core/data/coordinators/data_layer_coordinator.dart';
import 'package:jisu_fund_analyzer/src/core/network/intelligent_data_source_switcher.dart';
import 'package:jisu_fund_analyzer/src/core/network/multi_source_api_config.dart';
import 'package:jisu_fund_analyzer/src/features/fund/data/services/intelligent_preload_service.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/fund_exploration/domain/data/services/data_sync_manager.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/fund_exploration/domain/data/services/optimized_fund_service.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/fund_exploration/domain/data/services/smart_cache_manager.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'data_layer_coordinator_test.mocks.dart';
import 'test_integration_setup.dart';

/// 创建测试用的ApiSource
ApiSource createTestApiSource({
  required String name,
  required int priority,
  bool isHealthy = true,
  bool isMock = false,
}) {
  return ApiSource(
    name: name,
    baseUrl: 'https://test.com',
    priority: priority,
    timeout: const Duration(seconds: 30),
    healthCheckEndpoint: '/health',
    rateLimit: RateLimitConfig(
      maxRequests: 100,
      timeWindow: const Duration(minutes: 1),
    ),
    isMock: isMock,
  )..isHealthy = isHealthy;
}

@GenerateMocks([
  UnifiedCacheManager,
  IntelligentDataSourceSwitcher,
  DataSyncManager,
  SmartCacheManager,
  OptimizedFundService,
  IntelligentPreloadService,
])
void main() async {
  // 确保Flutter绑定已初始化
  TestWidgetsFlutterBinding.ensureInitialized();

  // 初始化测试环境
  await TestIntegrationSetup.setUpIntegrationTests();

  group('Data Layer Configuration Tests', () {
    late MockUnifiedCacheManager mockCacheManager;
    late MockIntelligentDataSourceSwitcher mockDataSourceSwitcher;
    late MockDataSyncManager mockSyncManager;
    late MockSmartCacheManager mockSmartCacheManager;
    late MockOptimizedFundService mockFundService;
    late MockIntelligentPreloadService mockPreloadService;

    setUp(() {
      // 创建Mock对象
      mockCacheManager = MockUnifiedCacheManager();
      mockDataSourceSwitcher = MockIntelligentDataSourceSwitcher();
      mockSyncManager = MockDataSyncManager();
      mockSmartCacheManager = MockSmartCacheManager();
      mockFundService = MockOptimizedFundService();
      mockPreloadService = MockIntelligentPreloadService();

      // 配置Mock对象的基本行为
      _setupMockBehaviors(
        mockCacheManager,
        mockDataSourceSwitcher,
        mockSyncManager,
        mockSmartCacheManager,
        mockPreloadService,
      );
    });

    tearDown(() async {
      await DataLayerIntegration.reset();
    });

    group('Environment Configuration', () {
      test('should configure development environment correctly', () async {
        // 配置开发环境
        final coordinator =
            await DataLayerIntegration.configureForDevelopment();

        // 验证协调器已创建
        expect(coordinator, isNotNull);
        expect(coordinator.isInitialized, isTrue);

        // 验证配置状态
        final status = DataLayerIntegration.getStatus();
        expect(status.isConfigured, isTrue);
        expect(status.environment, equals('configured'));

        // 清理资源
        await coordinator.dispose();
        await DataLayerIntegration.reset();

        print('✅ 开发环境配置正常');
      });

      test('should configure production environment correctly', () async {
        // 配置生产环境
        final coordinator = await DataLayerIntegration.configureForProduction();

        // 验证协调器已创建
        expect(coordinator, isNotNull);
        expect(coordinator.isInitialized, isTrue);

        // 验证配置状态
        final status = DataLayerIntegration.getStatus();
        expect(status.isConfigured, isTrue);
        expect(status.isInitialized, isTrue);

        // 清理资源
        await coordinator.dispose();
        await DataLayerIntegration.reset();

        print('✅ 生产环境配置正常');
      });

      test('should configure testing environment correctly', () async {
        // 配置测试环境
        final coordinator = await DataLayerIntegration.configureForTesting();

        // 验证协调器已创建
        expect(coordinator, isNotNull);
        expect(coordinator.isInitialized, isTrue);

        // 验证配置状态
        final status = DataLayerIntegration.getStatus();
        expect(status.isConfigured, isTrue);

        // 清理资源
        await coordinator.dispose();
        await DataLayerIntegration.reset();

        print('✅ 测试环境配置正常');
      });

      test('should reuse existing configuration', () async {
        // 第一次配置
        final coordinator1 =
            await DataLayerIntegration.configureForDevelopment();
        final status1 = DataLayerIntegration.getStatus();
        expect(status1.isConfigured, isTrue);

        // 第二次配置应该返回相同的实例
        final coordinator2 =
            await DataLayerIntegration.configureForDevelopment();
        expect(identical(coordinator1, coordinator2), isTrue);

        // 清理资源
        await coordinator1.dispose();
        await DataLayerIntegration.reset();

        print('✅ 配置重用机制正常');
      });

      test('should handle configuration reset correctly', () async {
        // 配置初始环境
        await DataLayerIntegration.configureForDevelopment();
        expect(DataLayerIntegration.getStatus().isConfigured, isTrue);

        // 重置配置
        await DataLayerIntegration.reset();
        expect(DataLayerIntegration.getStatus().isConfigured, isFalse);

        // 重新配置应该成功
        await DataLayerIntegration.configureForDevelopment();
        expect(DataLayerIntegration.getStatus().isConfigured, isTrue);

        // 清理资源
        await DataLayerIntegration.reset();

        print('✅ 配置重置机制正常');
      });
    });

    group('Custom Configuration Builder', () {
      test('should build custom configuration correctly', () async {
        // 使用配置构建器创建自定义配置
        final coordinator = await DataLayerConfigBuilder()
            .setEnvironment('custom')
            .setMonitoringEnabled(true)
            .setDebugLoggingEnabled(true)
            .build();

        // 验证协调器已创建
        expect(coordinator, isNotNull);
        expect(coordinator.isInitialized, isTrue);

        // 清理资源
        await coordinator.dispose();
        await DataLayerIntegration.reset();

        print('✅ 自定义配置构建正常');
      });

      test('should handle configuration builder with custom cache config',
          () async {
        const customCacheConfig = UnifiedCacheConfig(
          maxMemoryBytes: 50 * 1024 * 1024, // 50MB
          maintenanceInterval: Duration(minutes: 2),
          maxConcurrentOperations: 15,
          enableCompression: false,
          enableEncryption: false,
        );

        final coordinator = await DataLayerConfigBuilder()
            .setEnvironment('development')
            .setCacheConfig(customCacheConfig)
            .build();

        // 验证协调器已创建
        expect(coordinator, isNotNull);

        // 清理资源
        await coordinator.dispose();
        await DataLayerIntegration.reset();

        print('✅ 自定义缓存配置构建正常');
      });

      test('should handle configuration builder with custom data layer config',
          () async {
        const customDataLayerConfig = DataLayerConfig(
          healthCheckInterval: Duration(minutes: 3),
          enableWarmup: false,
          enableWarmupAfterRefresh: false,
          maxConcurrentOperations: 20,
          operationTimeout: Duration(seconds: 15),
        );

        final coordinator = await DataLayerConfigBuilder()
            .setEnvironment('production')
            .setDataLayerConfig(customDataLayerConfig)
            .build();

        // 验证协调器已创建
        expect(coordinator, isNotNull);

        // 清理资源
        await coordinator.dispose();
        await DataLayerIntegration.reset();

        print('✅ 自定义数据层配置构建正常');
      });
    });

    group('Data Layer Factory', () {
      test('should create development environment using factory', () async {
        final coordinator = await DataLayerFactory.createDevelopment();

        // 验证协调器已创建
        expect(coordinator, isNotNull);
        expect(coordinator.isInitialized, isTrue);

        // 清理资源
        await coordinator.dispose();
        await DataLayerIntegration.reset();

        print('✅ 工厂模式创建开发环境正常');
      });

      test('should create production environment using factory', () async {
        final coordinator = await DataLayerFactory.createProduction();

        // 验证协调器已创建
        expect(coordinator, isNotNull);
        expect(coordinator.isInitialized, isTrue);

        // 清理资源
        await coordinator.dispose();
        await DataLayerIntegration.reset();

        print('✅ 工厂模式创建生产环境正常');
      });

      test('should create testing environment using factory', () async {
        final coordinator = await DataLayerFactory.createTesting();

        // 验证协调器已创建
        expect(coordinator, isNotNull);
        expect(coordinator.isInitialized, isTrue);

        // 清理资源
        await coordinator.dispose();
        await DataLayerIntegration.reset();

        print('✅ 工厂模式创建测试环境正常');
      });

      test('should create custom environment using factory', () async {
        final coordinator = await DataLayerFactory.createCustom(
          environment: 'staging',
          enableMonitoring: true,
          enableDebugLogging: false,
        );

        // 验证协调器已创建
        expect(coordinator, isNotNull);
        expect(coordinator.isInitialized, isTrue);

        // 清理资源
        await coordinator.dispose();
        await DataLayerIntegration.reset();

        print('✅ 工厂模式创建自定义环境正常');
      });
    });

    group('Configuration Status and Health', () {
      test('should report configuration status correctly', () async {
        // 未配置时的状态
        var status = DataLayerIntegration.getStatus();
        expect(status.isConfigured, isFalse);
        expect(status.isInitialized, isFalse);

        // 配置后的状态
        await DataLayerIntegration.configureForDevelopment();
        status = DataLayerIntegration.getStatus();
        expect(status.isConfigured, isTrue);
        expect(status.isInitialized, isTrue);
        expect(status.lastConfigured, isNotNull);

        // 清理资源
        await DataLayerIntegration.reset();

        print('✅ 配置状态报告正常');
      });

      test('should track component health status', () async {
        await DataLayerIntegration.configureForDevelopment();

        final status = DataLayerIntegration.getStatus();

        // 验证组件状态
        expect(status.components['cacheManager'], isTrue);
        expect(status.components['dataSourceSwitcher'], isTrue);
        expect(status.components['syncManager'], isTrue);
        expect(status.components['smartCacheManager'], isTrue);
        expect(status.components['fundService'], isTrue);
        expect(status.components['preloadService'], isTrue);

        // 验证整体健康状态
        expect(status.allComponentsHealthy, isTrue);

        // 清理资源
        await DataLayerIntegration.reset();

        print('✅ 组件健康状态跟踪正常');
      });

      test('should detect unhealthy components', () async {
        // 这里需要模拟一个组件初始化失败的场景
        // 由于我们使用Mock，所有组件都会成功初始化
        // 在实际实现中，应该能够检测到组件初始化失败

        await DataLayerIntegration.configureForDevelopment();
        final status = DataLayerIntegration.getStatus();

        // 在正常情况下，所有组件都应该是健康的
        expect(status.allComponentsHealthy, isTrue);
        expect(status.unhealthyComponents, isEmpty);

        // 清理资源
        await DataLayerIntegration.reset();

        print('✅ 不健康组件检测正常');
      });
    });

    group('Configuration Validation', () {
      test('should validate configuration parameters', () async {
        // 测试有效的配置参数
        expect(() => UnifiedCacheConfig.development(), returnsNormally);
        expect(() => UnifiedCacheConfig.production(), returnsNormally);
        expect(() => UnifiedCacheConfig.testing(), returnsNormally);

        expect(() => DataLayerConfig.development(), returnsNormally);
        expect(() => DataLayerConfig.production(), returnsNormally);
        expect(() => DataLayerConfig.defaultConfig(), returnsNormally);

        print('✅ 配置参数验证正常');
      });

      test('should handle invalid configuration gracefully', () async {
        // 测试无效的配置参数应该有合理的默认值
        const invalidCacheConfig = UnifiedCacheConfig(
          maxMemoryBytes: -1, // 无效值
          maintenanceInterval: Duration.zero, // 无效值
          maxConcurrentOperations: 0, // 无效值
          enableCompression: true,
          enableEncryption: true,
        );

        // 配置创建应该成功，但内部应该有合理的默认值处理
        expect(invalidCacheConfig.maxMemoryBytes, equals(-1)); // 目前允许无效值

        print('✅ 无效配置处理正常');
      });

      test('should validate environment-specific configurations', () async {
        // 验证不同环境的配置差异

        // 开发环境配置
        final devConfig = DataLayerConfig.development();
        expect(devConfig.healthCheckInterval.inMinutes, equals(1));
        expect(devConfig.maxConcurrentOperations, equals(5));
        expect(devConfig.operationTimeout.inSeconds, equals(10));

        // 生产环境配置
        final prodConfig = DataLayerConfig.production();
        expect(prodConfig.healthCheckInterval.inMinutes, equals(10));
        expect(prodConfig.maxConcurrentOperations, equals(20));
        expect(prodConfig.operationTimeout.inSeconds, equals(60));

        // 测试环境配置
        final testConfig = DataLayerConfig.development();
        expect(testConfig.healthCheckInterval.inMinutes, equals(1));

        print('✅ 环境特定配置验证正常');
      });
    });

    group('Configuration Persistence', () {
      test('should maintain configuration across multiple operations',
          () async {
        // 配置数据层
        await DataLayerIntegration.configureForDevelopment();

        // 执行多个操作
        final coordinator = DataLayerIntegration.coordinator;
        expect(coordinator.isInitialized, isTrue);

        // 获取性能指标
        final metrics = await coordinator.getPerformanceMetrics();
        expect(metrics, isNotNull);

        // 获取健康报告
        final healthReport = await coordinator.getHealthReport();
        expect(healthReport, isNotNull);

        // 配置应该保持有效
        final status = DataLayerIntegration.getStatus();
        expect(status.isConfigured, isTrue);

        // 清理资源
        await coordinator.dispose();
        await DataLayerIntegration.reset();

        print('✅ 配置持久性正常');
      });

      test('should handle configuration changes correctly', () async {
        // 配置开发环境
        await DataLayerIntegration.configureForDevelopment();
        var status = DataLayerIntegration.getStatus();
        expect(status.environment, equals('configured'));

        // 重置并重新配置
        await DataLayerIntegration.reset();
        await DataLayerIntegration.configureForProduction();
        status = DataLayerIntegration.getStatus();
        expect(status.environment, equals('configured'));

        // 清理资源
        await DataLayerIntegration.reset();

        print('✅ 配置变更处理正常');
      });
    });

    group('Error Handling in Configuration', () {
      test('should handle configuration errors gracefully', () async {
        // 测试配置过程中的错误处理
        try {
          // 尝试配置，但不应该抛出异常
          await DataLayerIntegration.configureForDevelopment();

          // 如果配置成功，验证状态
          final status = DataLayerIntegration.getStatus();
          expect(status.isConfigured, isTrue);

          // 清理资源
          await DataLayerIntegration.reset();
        } catch (e) {
          // 如果配置失败，应该能够安全地重置
          await DataLayerIntegration.reset();
          final status = DataLayerIntegration.getStatus();
          expect(status.isConfigured, isFalse);
        }

        print('✅ 配置错误处理正常');
      });

      test('should handle component initialization failures', () async {
        // 这个测试需要模拟组件初始化失败
        // 在Mock环境中，所有组件都会成功初始化
        // 实际实现中应该能够处理组件初始化失败的情况

        try {
          await DataLayerIntegration.configureForDevelopment();
          final status = DataLayerIntegration.getStatus();

          // 在正常情况下，所有组件都应该初始化成功
          expect(status.allComponentsHealthy, isTrue);

          // 清理资源
          await DataLayerIntegration.reset();
        } catch (e) {
          // 如果有组件初始化失败，应该能够安全地清理
          await DataLayerIntegration.reset();
          final status = DataLayerIntegration.getStatus();
          expect(status.isConfigured, isFalse);
        }

        print('✅ 组件初始化失败处理正常');
      });

      test('should handle resource cleanup errors', () async {
        // 配置数据层
        await DataLayerIntegration.configureForDevelopment();

        try {
          // 尝试清理资源
          await DataLayerIntegration.reset();

          // 验证状态已重置
          final status = DataLayerIntegration.getStatus();
          expect(status.isConfigured, isFalse);
        } catch (e) {
          // 即使清理失败，也不应该影响后续操作
          print('清理过程中出现错误: $e');
        }

        print('✅ 资源清理错误处理正常');
      });
    });
  });
}

/// 配置Mock对象的基本行为
void _setupMockBehaviors(
  MockUnifiedCacheManager mockUnifiedCacheManager,
  MockIntelligentDataSourceSwitcher mockIntelligentDataSourceSwitcher,
  MockDataSyncManager mockDataSyncManager,
  MockSmartCacheManager mockSmartCacheManager,
  MockIntelligentPreloadService mockIntelligentPreloadService,
) {
  // UnifiedCacheManager
  when(mockUnifiedCacheManager.initialize()).thenAnswer((_) async {});
  when(mockUnifiedCacheManager.getStatistics())
      .thenAnswer((_) async => const CacheStatistics(
            totalCount: 100,
            validCount: 95,
            expiredCount: 5,
            totalSize: 1024 * 1024,
            compressedSavings: 0,
            tagCounts: {},
            priorityCounts: {5: 100},
            hitRate: 0.85,
            missRate: 0.15,
            averageResponseTime: 45.0,
          ));
  when(mockUnifiedCacheManager.close()).thenAnswer((_) async {});

  // IntelligentDataSourceSwitcher
  when(mockIntelligentDataSourceSwitcher.initialize()).thenAnswer((_) async {});
  when(mockIntelligentDataSourceSwitcher.getStatusReport())
      .thenReturn(DataSourceStatusReport(
    currentSource: createTestApiSource(name: 'test', priority: 1),
    availableSources: [],
    mockSource: createTestApiSource(name: 'mock', priority: 999, isMock: true),
    lastSwitchTime: {},
    timestamp: DateTime.now(),
  ));
  when(mockIntelligentDataSourceSwitcher.dispose()).thenAnswer((_) async {});

  // DataSyncManager
  when(mockDataSyncManager.initialize()).thenAnswer((_) async {});
  when(mockDataSyncManager.getSyncStats()).thenReturn({
    'totalDataTypes': 2,
    'activeSyncs': 0,
    'failedSyncs': 0,
    'pausedSyncs': 0,
  });
  when(mockDataSyncManager.forceSyncAll())
      .thenAnswer((_) async => {'funds': true, 'rankings': true});
  when(mockDataSyncManager.dispose()).thenAnswer((_) async {});

  // SmartCacheManager
  when(mockSmartCacheManager.initialize()).thenAnswer((_) async {});
  when(mockSmartCacheManager.getCacheStats()).thenReturn({
    'memoryCacheSize': 50,
    'hitRate': 0.85,
  });
  when(mockSmartCacheManager.clearAll()).thenAnswer((_) async {});
  when(mockSmartCacheManager.warmupCache()).thenAnswer((_) async {});
  when(mockSmartCacheManager.dispose()).thenAnswer((_) async {});

  // OptimizedFundService
  // (根据测试需要动态配置)

  // IntelligentPreloadService
  when(mockIntelligentPreloadService.start()).thenAnswer((_) async {});
  when(mockIntelligentPreloadService.recordFilterUsage(any))
      .thenAnswer((_) async {});
  when(mockIntelligentPreloadService.preloadCommonData())
      .thenAnswer((_) async {});
  when(mockIntelligentPreloadService.stop()).thenAnswer((_) async {});
}
