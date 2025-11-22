import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:jisu_fund_analyzer/src/core/data/coordinators/data_layer_coordinator.dart';
import 'package:jisu_fund_analyzer/src/core/cache/unified_cache_manager.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/fund_exploration/domain/data/services/data_sync_manager.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/fund_exploration/domain/data/services/smart_cache_manager.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/fund_exploration/domain/data/services/optimized_fund_service.dart';
import 'package:jisu_fund_analyzer/src/features/fund/data/services/intelligent_preload_service.dart';
import 'package:jisu_fund_analyzer/src/features/fund/domain/entities/fund.dart';

// 导入缺失的类型
import 'package:jisu_fund_analyzer/src/core/cache/interfaces/i_unified_cache_service.dart';
import 'package:jisu_fund_analyzer/src/core/network/intelligent_data_source_switcher.dart'
    as network;
import 'package:jisu_fund_analyzer/src/core/network/multi_source_api_config.dart';

@GenerateMocks([
  UnifiedCacheManager,
  network.IntelligentDataSourceSwitcher,
  DataSyncManager,
  SmartCacheManager,
  OptimizedFundService,
  IntelligentPreloadService,
])
import 'data_layer_coordinator_test.mocks.dart';

void main() {
  group('Data Layer Coordinator Core Tests', () {
    late DataLayerCoordinator coordinator;
    late MockUnifiedCacheManager mockCacheManager;
    late MockIntelligentDataSourceSwitcher mockDataSourceSwitcher;
    late MockDataSyncManager mockSyncManager;
    late MockSmartCacheManager mockSmartCacheManager;
    late MockOptimizedFundService mockFundService;
    late MockIntelligentPreloadService mockPreloadService;

    setUp(() async {
      // 创建Mock对象
      mockCacheManager = MockUnifiedCacheManager();
      mockDataSourceSwitcher = MockIntelligentDataSourceSwitcher();
      mockSyncManager = MockDataSyncManager();
      mockSmartCacheManager = MockSmartCacheManager();
      mockFundService = MockOptimizedFundService();
      mockPreloadService = MockIntelligentPreloadService();

      // 配置Mock对象的基本行为
      _setupMockBehaviors(mockCacheManager, mockDataSourceSwitcher,
          mockSyncManager, mockSmartCacheManager, mockPreloadService);

      // 创建协调器
      coordinator = DataLayerCoordinator.withDependencies(
        cacheManager: mockCacheManager,
        dataSourceSwitcher: mockDataSourceSwitcher,
        syncManager: mockSyncManager,
        smartCacheManager: mockSmartCacheManager,
        fundService: mockFundService,
        preloadService: mockPreloadService,
        config: DataLayerConfig.development(),
      );

      await coordinator.initialize();
    });

    tearDown(() async {
      await coordinator.dispose();
    });

    group('Initialization', () {
      test('should initialize successfully with valid dependencies', () async {
        expect(coordinator, isNotNull);
        expect(coordinator.isInitialized, isTrue);
      });

      test('should dispose properly', () async {
        await coordinator.dispose();
        // 验证dispose被调用
        verify(mockCacheManager.close()).called(1);
      });
    });

    group('Data Access Operations', () {
      test('should get funds successfully', () async {
        final testFunds = _createTestFunds(5);

        when(mockCacheManager.get<List<Fund>>(any))
            .thenAnswer((_) async => testFunds);

        final result = await coordinator.getFunds();

        expect(result, equals(testFunds));
        expect(result.length, equals(5));
      });

      test('should handle cache miss gracefully', () async {
        final testFunds = _createTestFunds(3);

        when(mockCacheManager.get<List<Fund>>(any))
            .thenAnswer((_) async => null);
        when(mockDataSourceSwitcher.executeRequest(any,
                operationName: anyNamed('operationName')))
            .thenAnswer((_) async => testFunds);
        when(mockCacheManager.put(any, any)).thenAnswer((_) async {});

        final result = await coordinator.getFunds();

        expect(result, equals(testFunds));
        expect(result.length, equals(3));
      });

      test('should handle cache errors', () async {
        when(mockCacheManager.get<List<Fund>>(any))
            .thenThrow(Exception('缓存读取失败'));

        expect(
          () => coordinator.getFunds(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Cache Management', () {
      test('should clear all cache successfully', () async {
        when(mockCacheManager.clear()).thenAnswer((_) async {});

        await coordinator.clearAllCache();

        verify(mockCacheManager.clear()).called(1);
      });

      test('should handle cache clear errors gracefully', () async {
        when(mockCacheManager.clear()).thenThrow(Exception('缓存清理失败'));

        expect(
          () => coordinator.clearAllCache(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Health Monitoring', () {
      test('should return health report', () async {
        when(mockCacheManager.getStatistics())
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

        final report = await coordinator.getHealthReport();

        expect(report, isNotNull);
        expect(report.isHealthy, isTrue);
        expect(report.timestamp, isNotNull);
      });

      test('should return performance metrics', () async {
        when(mockCacheManager.getStatistics())
            .thenAnswer((_) async => const CacheStatistics(
                  totalCount: 50,
                  validCount: 48,
                  expiredCount: 2,
                  totalSize: 512 * 1024,
                  compressedSavings: 128 * 1024,
                  tagCounts: {'fund': 25},
                  priorityCounts: {5: 50},
                  hitRate: 0.90,
                  missRate: 0.10,
                  averageResponseTime: 35.0,
                ));

        final metrics = await coordinator.getPerformanceMetrics();

        expect(metrics, isNotNull);
        expect(metrics.cacheHitRate, greaterThanOrEqualTo(0.0));
        expect(metrics.averageResponseTime, greaterThan(0.0));
      });
    });

    group('Error Handling', () {
      test('should handle network errors gracefully', () async {
        when(mockDataSourceSwitcher.executeRequest(any,
                operationName: anyNamed('operationName')))
            .thenThrow(Exception('网络连接失败'));

        when(mockCacheManager.get<List<Fund>>(any))
            .thenAnswer((_) async => null);

        expect(
          () => coordinator.getFunds(),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle timeout errors', () async {
        when(mockDataSourceSwitcher.executeRequest(any,
                operationName: anyNamed('operationName')))
            .thenThrow(TimeoutException('请求超时', const Duration(seconds: 30)));

        when(mockCacheManager.get<List<Fund>>(any))
            .thenAnswer((_) async => null);

        expect(
          () => coordinator.getFunds(),
          throwsA(isA<TimeoutException>()),
        );
      });
    });

    group('Performance Monitoring', () {
      test('should track operation metrics', () async {
        final startTime = DateTime.now();

        when(mockCacheManager.get<List<Fund>>(any)).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return _createTestFunds(1);
        });

        final result = await coordinator.getFunds();
        final endTime = DateTime.now();

        expect(result, isNotEmpty);
        expect(endTime.difference(startTime).inMilliseconds, greaterThan(50));
      });

      test('should monitor cache hit rates', () async {
        final testFunds = _createTestFunds(10);

        when(mockCacheManager.get<List<Fund>>(any))
            .thenAnswer((_) async => testFunds);

        // 多次调用相同请求
        for (int i = 0; i < 5; i++) {
          final result = await coordinator.getFunds();
          expect(result, equals(testFunds));
        }

        verify(mockCacheManager.get<List<Fund>>(any)).called(5);
      });
    });
  });
}

/// 配置Mock对象的基本行为
void _setupMockBehaviors(
    MockUnifiedCacheManager mockCacheManager,
    MockIntelligentDataSourceSwitcher mockDataSourceSwitcher,
    MockDataSyncManager mockSyncManager,
    MockSmartCacheManager mockSmartCacheManager,
    MockIntelligentPreloadService mockPreloadService) {
  // UnifiedCacheManager
  when(mockCacheManager.isInitialized).thenReturn(true);
  when(mockCacheManager.getStatistics())
      .thenAnswer((_) async => const CacheStatistics(
            totalCount: 100,
            validCount: 95,
            expiredCount: 5,
            totalSize: 1024 * 1024,
            compressedSavings: 0,
            tagCounts: {},
            priorityCounts: {5: 100},
            hitRate: 0.8,
            missRate: 0.2,
            averageResponseTime: 50.0,
          ));
  when(mockCacheManager.close()).thenAnswer((_) async {});

  // IntelligentDataSourceSwitcher
  when(mockDataSourceSwitcher.events).thenAnswer((_) => const Stream.empty());
  when(mockDataSourceSwitcher.getStatusReport())
      .thenReturn(network.DataSourceStatusReport(
    currentSource: ApiSource(
      name: 'test',
      baseUrl: 'https://test.com',
      priority: 1,
      healthCheckEndpoint: '/health',
      rateLimit: RateLimitConfig(
        maxRequests: 100,
        timeWindow: const Duration(minutes: 1),
      ),
      timeout: const Duration(seconds: 30),
    ),
    availableSources: [],
    mockSource: ApiSource(
      name: 'mock',
      baseUrl: 'https://mock.com',
      priority: 999,
      healthCheckEndpoint: '/health',
      rateLimit: RateLimitConfig(
        maxRequests: 1000,
        timeWindow: const Duration(minutes: 1),
      ),
      timeout: const Duration(seconds: 60),
    ),
    lastSwitchTime: {},
    timestamp: DateTime.now(),
  ));
  when(mockDataSourceSwitcher.dispose()).thenAnswer((_) async {});

  // DataSyncManager
  when(mockSyncManager.getSyncStats()).thenReturn({
    'totalDataTypes': 2,
    'activeSyncs': 0,
    'failedSyncs': 0,
    'pausedSyncs': 0,
  });
  when(mockSyncManager.forceSyncAll())
      .thenAnswer((_) async => {'funds': true, 'rankings': true});
  when(mockSyncManager.dispose()).thenAnswer((_) async {});

  // SmartCacheManager
  when(mockSmartCacheManager.getCacheStats()).thenReturn({
    'memoryCacheSize': 50,
    'hitRate': 0.85,
  });
  when(mockSmartCacheManager.clearAll()).thenAnswer((_) async {});
  when(mockSmartCacheManager.warmupCache()).thenAnswer((_) async {});
  when(mockSmartCacheManager.dispose()).thenAnswer((_) async {});

  // OptimizedFundService
  // (无需特别配置，根据测试需要设置)

  // IntelligentPreloadService
  when(mockPreloadService.start()).thenAnswer((_) async {});
  when(mockPreloadService.recordFilterUsage(any)).thenAnswer((_) async {});
  when(mockPreloadService.preloadCommonData()).thenAnswer((_) async {});
  when(mockPreloadService.stop()).thenAnswer((_) async {});
}

/// 创建测试基金数据
List<Fund> _createTestFunds(int count) {
  return List.generate(
      count,
      (index) => _createTestFund(
            '${100000 + index}',
            '测试基金${String.fromCharCode(65 + index)}',
            index,
          ));
}

/// 创建单个测试基金
Fund _createTestFund(String code, String name, int index) {
  return Fund(
    code: code,
    name: name,
    type: '股票型',
    company: '测试公司',
    manager: '测试经理',
    lastUpdate: DateTime.now(),
    return1Y: (index * 2.5).toDouble(),
    scale: 1000000.0,
    riskLevel: 'R3',
    status: 'active',
  );
}
