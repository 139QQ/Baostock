import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

import 'package:jisu_fund_analyzer/src/core/services/data/unified_data_service.dart';

void main() {
  group('UnifiedDataService - Simple Tests', () {
    late UnifiedDataService service;

    setUp(() {
      service = UnifiedDataService();
    });

    tearDown(() async {
      await service.dispose();
    });

    test('should have correct service metadata', () {
      expect(service.serviceName, equals('UnifiedDataService'));
      expect(service.version, equals('1.0.0'));
      expect(service.dependencies, contains('UnifiedPerformanceService'));
    });

    test('should handle service lifecycle correctly', () {
      // Initial state
      expect(service.lifecycleState.name, equals('uninitialized'));

      // Note: Full initialization test would require ServiceContainer mock
      // For now, just test that the service can be created and disposed
      expect(service, isNotNull);
    });

    test('should return correct sync status', () {
      final status = service.syncStatus;
      expect(status, isA<DataSyncStatus>());
      expect(status, equals(DataSyncStatus.idle));
    });

    test('should provide data operation type extensions', () {
      expect(DataOperationType.read.name, equals('read'));
      expect(DataOperationType.write.name, equals('write'));
      expect(DataOperationType.delete.name, equals('delete'));
      expect(DataOperationType.clear.name, equals('clear'));
      expect(DataOperationType.batchRead.name, equals('batchRead'));
      expect(DataOperationType.batchWrite.name, equals('batchWrite'));
      expect(DataOperationType.preload.name, equals('preload'));
      expect(DataOperationType.optimize.name, equals('optimize'));
    });

    test('should provide data sync type extensions', () {
      expect(DataSyncType.preload.name, equals('preload'));
      expect(DataSyncType.incremental.name, equals('incremental'));
      expect(DataSyncType.full.name, equals('full'));
    });

    test('should provide data sync status extensions', () {
      expect(DataSyncStatus.idle.name, equals('idle'));
      expect(DataSyncStatus.preloading.name, equals('preloading'));
      expect(DataSyncStatus.syncing.name, equals('syncing'));
      expect(DataSyncStatus.error.name, equals('error'));
    });

    test('should provide sync status extensions', () {
      expect(SyncStatus.started.name, equals('started'));
      expect(SyncStatus.inProgress.name, equals('inProgress'));
      expect(SyncStatus.success.name, equals('success'));
      expect(SyncStatus.failed.name, equals('failed'));
    });

    test('should create DataOperationEvent correctly', () {
      final event = DataOperationEvent(
        timestamp: DateTime.now(),
        operationType: DataOperationType.read,
        dataType: 'cache',
        key: 'test_key',
        success: true,
        metadata: {'size': 1024},
      );

      expect(event.operationType, equals(DataOperationType.read));
      expect(event.dataType, equals('cache'));
      expect(event.key, equals('test_key'));
      expect(event.success, isTrue);
      expect(event.metadata['size'], equals(1024));
      expect(event.timestamp, isA<DateTime>());
    });

    test('should create CacheMetricsEvent correctly', () {
      final event = CacheMetricsEvent(
        timestamp: DateTime.now(),
        hitRate: 85.5,
        totalSize: 1000,
        memoryUsage: 2048,
      );

      expect(event.hitRate, equals(85.5));
      expect(event.totalSize, equals(1000));
      expect(event.memoryUsage, equals(2048));
      expect(event.timestamp, isA<DateTime>());
    });

    test('should create DataSyncEvent correctly', () {
      final event = DataSyncEvent(
        timestamp: DateTime.now(),
        syncType: DataSyncType.full,
        status: SyncStatus.success,
        itemCount: 100,
      );

      expect(event.syncType, equals(DataSyncType.full));
      expect(event.status, equals(SyncStatus.success));
      expect(event.itemCount, equals(100));
      expect(event.timestamp, isA<DateTime>());
    });

    test('should create CacheStatistics correctly', () {
      const hiveStats = CacheStats(
        size: 50,
        memoryUsage: 1024,
        hitRate: 85.0,
        requestCount: 500,
        lastAccess: null, // Would use real timestamp in production
      );

      const intelligentStats = CacheStats(
        size: 30,
        memoryUsage: 512,
        hitRate: 90.0,
        requestCount: 300,
        lastAccess: null,
      );

      const optimizedStats = CacheStats(
        size: 20,
        memoryUsage: 256,
        hitRate: 80.0,
        requestCount: 200,
        lastAccess: null,
      );

      const statistics = CacheStatistics(
        hiveCache: hiveStats,
        intelligentCache: intelligentStats,
        optimizedCache: optimizedStats,
        totalSize: 100,
        totalMemoryUsage: 1792,
        averageHitRate: 85.0,
      );

      expect(statistics.hiveCache.size, equals(50));
      expect(statistics.intelligentCache.size, equals(30));
      expect(statistics.optimizedCache.size, equals(20));
      expect(statistics.totalSize, equals(100));
      expect(statistics.totalMemoryUsage, equals(1792));
      expect(statistics.averageHitRate, equals(85.0));
    });

    test('should serialize CacheStatistics correctly', () {
      const hiveStats = CacheStats(
        size: 50,
        memoryUsage: 1024,
        hitRate: 85.0,
        requestCount: 500,
        lastAccess: null,
      );

      const statistics = CacheStatistics(
        hiveCache: hiveStats,
        intelligentCache: hiveStats,
        optimizedCache: hiveStats,
        totalSize: 150,
        totalMemoryUsage: 3072,
        averageHitRate: 85.0,
      );

      final json = statistics.toJson();

      expect(json['totalSize'], equals(150));
      expect(json['totalMemoryUsage'], equals(3072));
      expect(json['averageHitRate'], equals(85.0));
      expect(json.containsKey('hiveCache'), isTrue);
    });

    test('should serialize CacheStats correctly', () {
      const cacheStats = CacheStats(
        size: 100,
        memoryUsage: 2048,
        hitRate: 90.5,
        requestCount: 1000,
        lastAccess: null,
      );

      final json = cacheStats.toJson();

      expect(json['size'], equals(100));
      expect(json['memoryUsage'], equals(2048));
      expect(json['hitRate'], equals(90.5));
      expect(json['requestCount'], equals(1000));
    });

    test('should handle empty cache statistics', () {
      const emptyStats = CacheStats(
        size: 0,
        memoryUsage: 0,
        hitRate: 0.0,
        requestCount: 0,
        lastAccess: null,
      );

      expect(emptyStats.size, equals(0));
      expect(emptyStats.memoryUsage, equals(0));
      expect(emptyStats.hitRate, equals(0.0));
      expect(emptyStats.requestCount, equals(0));
    });
  });
}
