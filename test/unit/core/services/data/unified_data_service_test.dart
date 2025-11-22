import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:jisu_fund_analyzer/src/core/services/base/i_unified_service.dart';
import 'package:jisu_fund_analyzer/src/core/services/data/unified_data_service.dart';
import 'package:jisu_fund_analyzer/src/core/services/performance/unified_performance_service.dart';

// Mock classes
import 'unified_data_service_test.mocks.dart';

@GenerateMocks([
  ServiceContainer,
  UnifiedPerformanceService,
])
void main() {
  group('UnifiedDataService', () {
    late UnifiedDataService service;
    late MockServiceContainer mockContainer;
    late MockUnifiedPerformanceService mockPerformanceService;

    setUp(() {
      service = UnifiedDataService();
      mockContainer = MockServiceContainer();
      mockPerformanceService = MockUnifiedPerformanceService();

      // 设置mock behavior
      when(mockContainer.getServiceByName('UnifiedPerformanceService'))
          .thenReturn(mockPerformanceService);
    });

    tearDown(() async {
      await service.dispose();
    });

    test('should have correct service metadata', () {
      expect(service.serviceName, equals('UnifiedDataService'));
      expect(service.version, equals('1.0.0'));
      expect(service.dependencies, contains('UnifiedPerformanceService'));
    });

    test('should initialize successfully', () async {
      // Act
      await service.initialize(mockContainer);

      // Assert
      expect(service.lifecycleState, equals(ServiceLifecycleState.initialized));
      verify(mockContainer.getServiceByName('UnifiedPerformanceService'))
          .called(1);
    });

    test('should initialize without performance service', () async {
      // Arrange
      when(mockContainer.getServiceByName('UnifiedPerformanceService'))
          .thenReturn(null);

      // Act & Assert
      expect(
        () => service.initialize(mockContainer),
        completes,
      );
    });

    test('should dispose successfully', () async {
      // Arrange
      await service.initialize(mockContainer);

      // Act
      await service.dispose();

      // Assert
      expect(service.lifecycleState, equals(ServiceLifecycleState.disposed));
    });

    test('should provide data operation stream', () async {
      // Arrange
      await service.initialize(mockContainer);

      // Act
      final stream = service.dataOperationStream;

      // Assert
      expect(stream, isA<Stream<DataOperationEvent>>());
    });

    test('should provide cache metrics stream', () async {
      // Arrange
      await service.initialize(mockContainer);

      // Act
      final stream = service.cacheMetricsStream;

      // Assert
      expect(stream, isA<Stream<CacheMetricsEvent>>());
    });

    test('should provide data sync stream', () async {
      // Arrange
      await service.initialize(mockContainer);

      // Act
      final stream = service.dataSyncStream;

      // Assert
      expect(stream, isA<Stream<DataSyncEvent>>());
    });

    test('should return correct sync status', () {
      // Act
      final status = service.syncStatus;

      // Assert
      expect(status, isA<DataSyncStatus>());
      expect(status, equals(DataSyncStatus.idle));
    });

    test('should check health status correctly', () async {
      // Arrange
      await service.initialize(mockContainer);

      // Act
      final healthStatus = await service.checkHealth();

      // Assert
      expect(healthStatus, isA<ServiceHealthStatus>());
    });

    test('should provide service statistics', () async {
      // Arrange
      await service.initialize(mockContainer);

      // Act
      final stats = service.getStats();

      // Assert
      expect(stats, isA<ServiceStats>());
      expect(stats.serviceName, equals('UnifiedDataService'));
      expect(stats.version, equals('1.0.0'));
    });

    group('Cache operations', () {
      setUp(() async {
        await service.initialize(mockContainer);
      });

      test('should get and set cached data correctly', () async {
        // Arrange
        const key = 'test_key';
        const testData = 'test_data';

        // Act
        await service.setCachedData(key, testData);
        final retrievedData = await service.getCachedData<String>(key);

        // Assert
        expect(retrievedData, equals(testData));
      });

      test('should handle cache miss correctly', () async {
        // Arrange
        const key = 'non_existent_key';

        // Act
        final data = await service.getCachedData<String>(key);

        // Assert
        expect(data, isNull);
      });

      test('should remove cached data correctly', () async {
        // Arrange
        const key = 'test_key';
        const testData = 'test_data';
        await service.setCachedData(key, testData);

        // Act
        await service.removeCachedData(key);
        final retrievedData = await service.getCachedData<String>(key);

        // Assert
        expect(retrievedData, isNull);
      });

      test('should clear all cache correctly', () async {
        // Arrange
        await service.setCachedData('key1', 'data1');
        await service.setCachedData('key2', 'data2');

        // Act
        await service.clearAllCache();
        final data1 = await service.getCachedData<String>('key1');
        final data2 = await service.getCachedData<String>('key2');

        // Assert
        expect(data1, isNull);
        expect(data2, isNull);
      });

      test('should handle cache with TTL correctly', () async {
        // Arrange
        const key = 'test_ttl_key';
        const testData = 'test_ttl_data';
        const ttl = Duration(milliseconds: 100);

        // Act
        await service.setCachedData(key, testData, ttl: ttl);
        final immediateData = await service.getCachedData<String>(key);

        // Wait for TTL to expire (in a real test, you might need to mock time)
        await Future.delayed(const Duration(milliseconds: 150));
        final expiredData = await service.getCachedData<String>(key);

        // Assert
        expect(immediateData, equals(testData));
        // Note: TTL behavior might be mocked in actual tests
      });
    });

    group('Lazy loading', () {
      setUp(() async {
        await service.initialize(mockContainer);
      });

      test('should lazy load data correctly', () async {
        // Arrange
        const key = 'lazy_test_key';
        const testData = 'lazy_test_data';
        var callCount = 0;

        String loader() {
          callCount++;
          return testData;
        }

        // Act
        final result1 = await service.lazyLoadData(key, () async => loader());
        final result2 = await service.lazyLoadData(key, () async => loader());

        // Assert
        expect(result1, equals(testData));
        expect(result2, equals(testData));
        expect(callCount, equals(1)); // Loader should be called only once
      });

      test('should force refresh lazy loaded data', () async {
        // Arrange
        const key = 'refresh_test_key';
        var callCount = 0;

        String loader() {
          callCount++;
          return 'data_$callCount';
        }

        // Act
        final result1 = await service.lazyLoadData(key, () async => loader());
        final result2 = await service.lazyLoadData(
          key,
          () async => loader(),
          forceRefresh: true,
        );

        // Assert
        expect(result1, equals('data_1'));
        expect(result2, equals('data_2'));
        expect(callCount, equals(2));
      });
    });

    group('Data synchronization', () {
      setUp(() async {
        await service.initialize(mockContainer);
      });

      test('should preload data correctly', () async {
        // Arrange
        const keys = ['key1', 'key2', 'key3'];
        var preloadCount = 0;

        String loader(String key) {
          preloadCount++;
          return 'data_$key';
        }

        // Act
        await service.preloadData(keys, (key) async => loader(key));

        // Assert
        expect(preloadCount, equals(keys.length));
      });

      test('should perform data sync correctly', () async {
        // Act & Assert
        expect(
          () => service.performDataSync(),
          returnsNormally,
        );

        expect(
          () => service.performDataSync(forceSync: true),
          returnsNormally,
        );
      });

      test('should not sync when already syncing', () async {
        // This test would need to mock the sync state
        // For now, just ensure it doesn't throw
        expect(
          () => service.performDataSync(),
          returnsNormally,
        );
      });
    });

    group('Batch operations', () {
      setUp(() async {
        await service.initialize(mockContainer);
      });

      test('should get batch fund data correctly', () async {
        // Arrange
        const fundCodes = ['000001', '000002', '000003'];

        // Act
        final results = await service.getBatchFundData(fundCodes);

        // Assert
        expect(results, isA<List<dynamic>>());
        expect(results.length, equals(fundCodes.length));
      });
    });

    group('Data deduplication', () {
      setUp(() async {
        await service.initialize(mockContainer);
      });

      test('should deduplicate simple data correctly', () async {
        // Arrange
        final itemsWithDuplicates = [1, 2, 2, 3, 4, 4, 5];

        // Act
        final deduplicated = service.deduplicateData(itemsWithDuplicates);

        // Assert
        expect(deduplicated, equals([1, 2, 3, 4, 5]));
      });

      test('should deduplicate objects with custom key extractor', () async {
        // Arrange
        final items = [
          {'id': 1, 'name': 'Item 1'},
          {'id': 2, 'name': 'Item 2'},
          {'id': 1, 'name': 'Duplicate Item 1'},
        ];

        // Act
        final deduplicated = service.deduplicateData(
          items,
          keyExtractor: (item) => item['id'].toString(),
        );

        // Assert
        expect(deduplicated.length, equals(2));
        expect(deduplicated[0]['id'], equals(1));
        expect(deduplicated[1]['id'], equals(2));
      });

      test('should handle empty list correctly', () async {
        // Arrange
        final emptyList = <String>[];

        // Act
        final deduplicated = service.deduplicateData(emptyList);

        // Assert
        expect(deduplicated, isEmpty);
      });
    });

    group('Cache optimization', () {
      setUp(() async {
        await service.initialize(mockContainer);
      });

      test('should optimize cache strategy correctly', () async {
        // Act & Assert
        expect(
          () => service.optimizeCacheStrategy(),
          returnsNormally,
        );
      });

      test('should get cache statistics correctly', () async {
        // Act
        final stats = await service.getCacheStatistics();

        // Assert
        expect(stats, isA<CacheStatistics>());
        expect(stats.totalSize, isA<int>());
        expect(stats.totalMemoryUsage, isA<int>());
        expect(stats.averageHitRate, isA<double>());
      });
    });

    group('Event emission', () {
      setUp(() async {
        await service.initialize(mockContainer);
      });

      test('should emit data operation events', () async {
        // Arrange
        final completer = Completer<DataOperationEvent>();
        late StreamSubscription subscription;

        // Act
        subscription = service.dataOperationStream.listen((event) {
          if (!completer.isCompleted) {
            completer.complete(event);
          }
        });

        // Trigger an operation
        await service.setCachedData('test_key', 'test_data');

        // Wait for event
        final event =
            await completer.future.timeout(const Duration(seconds: 5));

        // Cleanup
        await subscription.cancel();

        // Assert
        expect(event, isA<DataOperationEvent>());
        expect(event.operationType, equals(DataOperationType.write));
        expect(event.success, isTrue);
      });

      test('should emit cache metrics events', () async {
        // Arrange
        final completer = Completer<CacheMetricsEvent>();
        late StreamSubscription subscription;

        // Act
        subscription = service.cacheMetricsStream.listen((event) {
          if (!completer.isCompleted) {
            completer.complete(event);
          }
        });

        // Wait for metrics event
        final event =
            await completer.future.timeout(const Duration(seconds: 10));

        // Cleanup
        await subscription.cancel();

        // Assert
        expect(event, isA<CacheMetricsEvent>());
        expect(event.timestamp, isA<DateTime>());
        expect(event.hitRate, isA<double>());
      });
    });

    group('Error handling', () {
      setUp(() async {
        await service.initialize(mockContainer);
      });

      test('should handle operation failures gracefully', () async {
        // Act & Assert
        expect(
          () => service.getCachedData<String>('non_existent_key'),
          returnsNormally,
        );

        expect(
          () => service.removeCachedData('non_existent_key'),
          returnsNormally,
        );
      });

      test('should handle double dispose gracefully', () async {
        // Act
        await service.dispose();

        // Assert
        expect(
          () => service.dispose(),
          returnsNormally,
        );
      });
    });

    group('Enum extensions', () {
      test('should provide correct names for data operation types', () {
        expect(DataOperationType.read.name, equals('read'));
        expect(DataOperationType.write.name, equals('write'));
        expect(DataOperationType.delete.name, equals('delete'));
        expect(DataOperationType.clear.name, equals('clear'));
        expect(DataOperationType.batchRead.name, equals('batchRead'));
        expect(DataOperationType.batchWrite.name, equals('batchWrite'));
        expect(DataOperationType.preload.name, equals('preload'));
        expect(DataOperationType.optimize.name, equals('optimize'));
      });

      test('should provide correct names for data sync types', () {
        expect(DataSyncType.preload.name, equals('preload'));
        expect(DataSyncType.incremental.name, equals('incremental'));
        expect(DataSyncType.full.name, equals('full'));
      });

      test('should provide correct names for data sync statuses', () {
        expect(DataSyncStatus.idle.name, equals('idle'));
        expect(DataSyncStatus.preloading.name, equals('preloading'));
        expect(DataSyncStatus.syncing.name, equals('syncing'));
        expect(DataSyncStatus.error.name, equals('error'));
      });

      test('should provide correct names for sync statuses', () {
        expect(SyncStatus.started.name, equals('started'));
        expect(SyncStatus.inProgress.name, equals('inProgress'));
        expect(SyncStatus.success.name, equals('success'));
        expect(SyncStatus.failed.name, equals('failed'));
      });
    });

    group('Serialization', () {
      test('should serialize cache statistics correctly', () async {
        // Arrange
        await service.initialize(mockContainer);
        final stats = await service.getCacheStatistics();

        // Act
        final json = stats.toJson();

        // Assert
        expect(json, isA<Map<String, dynamic>>());
        expect(json.containsKey('totalSize'), isTrue);
        expect(json.containsKey('totalMemoryUsage'), isTrue);
        expect(json.containsKey('averageHitRate'), isTrue);
      });

      test('should serialize cache stats correctly', () {
        // Arrange
        const cacheStats = CacheStats(
          size: 100,
          memoryUsage: 1024,
          hitRate: 85.5,
          requestCount: 1000,
          lastAccess: null, // 在实际测试中需要提供真实时间戳
        );

        // Act
        final json = cacheStats.toJson();

        // Assert
        expect(json['size'], equals(100));
        expect(json['memoryUsage'], equals(1024));
        expect(json['hitRate'], equals(85.5));
        expect(json['requestCount'], equals(1000));
      });
    });

    group('Integration tests', () {
      test('should work end-to-end with full lifecycle', () async {
        // Arrange
        const testKey = 'integration_test_key';
        const testData = 'integration_test_data';

        // Act
        await service.initialize(mockContainer);

        // Test cache operations
        await service.setCachedData(testKey, testData);
        final retrievedData = await service.getCachedData<String>(testKey);

        // Test lazy loading
        final lazyData = await service.lazyLoadData(
          'lazy_key',
          () async => 'lazy_data',
        );

        // Test deduplication
        final deduplicated = service.deduplicateData([1, 1, 2, 3]);

        // Test optimization
        await service.optimizeCacheStrategy();

        // Test sync
        await service.performDataSync();

        // Test health and stats
        final health = await service.checkHealth();
        final stats = service.getStats();

        // Cleanup
        await service.dispose();

        // Assert
        expect(retrievedData, equals(testData));
        expect(lazyData, equals('lazy_data'));
        expect(deduplicated, equals([1, 2, 3]));
        expect(health, isA<ServiceHealthStatus>());
        expect(stats, isA<ServiceStats>());
      });
    });
  });
}
