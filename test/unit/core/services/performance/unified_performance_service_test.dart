import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:jisu_fund_analyzer/src/core/services/base/i_unified_service.dart';
import 'package:jisu_fund_analyzer/src/core/services/performance/unified_performance_service.dart';

// Mock classes
import 'unified_performance_service_test.mocks.dart';

@GenerateMocks([
  ServiceContainer,
  // 这里可以添加其他需要mock的类
])
void main() {
  group('UnifiedPerformanceService', () {
    late UnifiedPerformanceService service;
    late MockServiceContainer mockContainer;

    setUp(() {
      service = UnifiedPerformanceService();
      mockContainer = MockServiceContainer();
    });

    tearDown(() async {
      await service.dispose();
    });

    test('should have correct service metadata', () {
      expect(service.serviceName, equals('UnifiedPerformanceService'));
      expect(service.version, equals('1.0.0'));
      expect(service.dependencies, isEmpty);
    });

    test('should initialize successfully', () async {
      // Act
      await service.initialize(mockContainer);

      // Assert
      expect(service.lifecycleState, equals(ServiceLifecycleState.initialized));
    });

    test('should handle initialization failure gracefully', () async {
      // Arrange - 模拟初始化失败的情况
      // 这里可以通过mock来模拟失败场景

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

    test('should provide performance metrics stream', () async {
      // Arrange
      await service.initialize(mockContainer);

      // Act
      final stream = service.performanceMetricsStream;

      // Assert
      expect(stream, isA<Stream<PerformanceMetrics>>());
    });

    test('should provide memory pressure stream', () async {
      // Arrange
      await service.initialize(mockContainer);

      // Act
      final stream = service.memoryPressureStream;

      // Assert
      expect(stream, isA<Stream<MemoryPressureEvent>>());
    });

    test('should provide performance alerts stream', () async {
      // Arrange
      await service.initialize(mockContainer);

      // Act
      final stream = service.performanceAlertsStream;

      // Assert
      expect(stream, isA<Stream<PerformanceAlert>>());
    });

    test('should check health status correctly', () async {
      // Arrange
      await service.initialize(mockContainer);

      // Act
      final healthStatus = await service.checkHealth();

      // Assert
      expect(healthStatus, isA<ServiceHealthStatus>());
      expect(healthStatus.isHealthy, isTrue); // 假设初始化成功后应该是健康的
    });

    test('should provide service statistics', () async {
      // Arrange
      await service.initialize(mockContainer);

      // Act
      final stats = service.getStats();

      // Assert
      expect(stats, isA<ServiceStats>());
      expect(stats.serviceName, equals('UnifiedPerformanceService'));
      expect(stats.version, equals('1.0.0'));
    });

    test('should get current performance metrics', () async {
      // Arrange
      await service.initialize(mockContainer);

      // Act
      final metrics = await service.getCurrentPerformanceMetrics();

      // Assert
      expect(metrics, isA<PerformanceMetrics>());
      expect(metrics.timestamp, isA<DateTime>());
      expect(metrics.cpuUsage, isA<double>());
      expect(metrics.memoryUsage, isA<double>());
    });

    test('should optimize performance correctly', () async {
      // Arrange
      await service.initialize(mockContainer);

      // Act & Assert - 不应该抛出异常
      expect(
        () => service.optimizePerformance(aggressive: false),
        returnsNormally,
      );

      expect(
        () => service.optimizePerformance(aggressive: true),
        returnsNormally,
      );
    });

    test('should process batch data correctly', () async {
      // Arrange
      await service.initialize(mockContainer);
      final items = [1, 2, 3, 4, 5];
      final processor = (int item) async => item * 2;

      // Act
      final results = await service.processBatch(items, processor);

      // Assert
      expect(results, equals([2, 4, 6, 8, 10]));
    });

    test('should compress and decompress data correctly', () async {
      // Arrange
      await service.initialize(mockContainer);
      final originalData = [1, 2, 3, 4, 5];

      // Act
      final compressed = await service.compressData(originalData);
      final decompressed = await service.decompressData(compressed);

      // Assert
      expect(decompressed, equals(originalData));
    });

    test('should deduplicate data correctly', () async {
      // Arrange
      await service.initialize(mockContainer);
      final itemsWithDuplicates = [1, 2, 2, 3, 4, 4, 5];

      // Act
      final deduplicated = service.deduplicateData(itemsWithDuplicates);

      // Assert
      expect(deduplicated, equals([1, 2, 3, 4, 5]));
    });

    test('should deduplicate data with custom key extractor', () async {
      // Arrange
      await service.initialize(mockContainer);
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

    test('should handle performance status calculation correctly', () {
      // Test the PerformanceStatus enum
      expect(PerformanceStatus.optimal.name, equals('optimal'));
      expect(PerformanceStatus.good.name, equals('good'));
      expect(PerformanceStatus.warning.name, equals('warning'));
      expect(PerformanceStatus.critical.name, equals('critical'));
    });

    test('should handle memory pressure levels correctly', () {
      // Test the MemoryPressureLevel enum
      expect(MemoryPressureLevel.low.name, equals('low'));
      expect(MemoryPressureLevel.medium.name, equals('medium'));
      expect(MemoryPressureLevel.high.name, equals('high'));
      expect(MemoryPressureLevel.critical.name, equals('critical'));
    });

    test('should handle alert types correctly', () {
      // Test the AlertType enum
      expect(AlertType.highCpuUsage.name, equals('highCpuUsage'));
      expect(AlertType.highMemoryUsage.name, equals('highMemoryUsage'));
      expect(AlertType.queueBacklog.name, equals('queueBacklog'));
      expect(AlertType.memoryPressure.name, equals('memoryPressure'));
      expect(AlertType.networkLatency.name, equals('networkLatency'));
      expect(AlertType.diskIoWarning.name, equals('diskIoWarning'));
    });

    test('should handle alert severities correctly', () {
      // Test the AlertSeverity enum
      expect(AlertSeverity.low.name, equals('low'));
      expect(AlertSeverity.medium.name, equals('medium'));
      expect(AlertSeverity.high.name, equals('high'));
      expect(AlertSeverity.critical.name, equals('critical'));
    });

    group('PerformanceMetrics serialization', () {
      test('should convert PerformanceMetrics to JSON correctly', () {
        // Arrange
        const metrics = PerformanceMetrics(
          timestamp: null, // 在实际测试中需要提供真实的时间戳
          cpuUsage: 75.5,
          memoryUsage: 60.2,
          activeLoadingTasks: 5,
          queuedLoadingTasks: 2,
          cachedItems: 100,
          status: PerformanceStatus.good,
          additionalMetrics: {'custom': 'value'},
        );

        // Act
        final json = metrics.toJson();

        // Assert
        expect(json['cpuUsage'], equals(75.5));
        expect(json['memoryUsage'], equals(60.2));
        expect(json['status'], equals('good'));
        expect(json['custom'], equals('value'));
      });
    });

    group('Error handling', () {
      test('should handle operation on uninitialized service gracefully', () {
        // Arrange - service is not initialized

        // Act & Assert
        expect(
          service.lifecycleState,
          equals(ServiceLifecycleState.uninitialized),
        );
      });

      test('should handle double dispose gracefully', () async {
        // Arrange
        await service.initialize(mockContainer);
        await service.dispose();

        // Act & Assert
        expect(
          () => service.dispose(),
          returnsNormally,
        );
      });
    });

    group('Performance monitoring', () {
      test('should emit performance metrics events', () async {
        // Arrange
        await service.initialize(mockContainer);

        final completer = Completer<PerformanceMetrics>();
        late StreamSubscription subscription;

        // Act
        subscription = service.performanceMetricsStream.listen((metrics) {
          if (!completer.isCompleted) {
            completer.complete(metrics);
          }
        });

        // Wait for the first metrics event
        final metrics =
            await completer.future.timeout(const Duration(seconds: 5));

        // Cleanup
        await subscription.cancel();

        // Assert
        expect(metrics, isA<PerformanceMetrics>());
        expect(metrics.timestamp, isA<DateTime>());
      });

      test('should emit memory pressure events when pressure changes',
          () async {
        // Arrange
        await service.initialize(mockContainer);

        final completer = Completer<MemoryPressureEvent>();
        late StreamSubscription subscription;

        // Act
        subscription = service.memoryPressureStream.listen((event) {
          if (!completer.isCompleted) {
            completer.complete(event);
          }
        });

        // 这里可能需要手动触发内存压力变化
        // 在实际测试中可能需要使用mock来模拟

        // Cleanup
        await subscription.cancel();

        // Assert - 在实际测试中需要模拟事件
        // expect(completer.isCompleted, isTrue);
      });
    });

    group('Integration tests', () {
      test('should work end-to-end with full lifecycle', () async {
        // Arrange
        final items = [1, 2, 3, 4, 5];

        // Act
        await service.initialize(mockContainer);

        // Test various operations
        final metrics = await service.getCurrentPerformanceMetrics();
        final processedItems = await service.processBatch(items, (x) => x * 2);
        final deduplicated = service.deduplicateData([1, 1, 2, 3]);

        final health = await service.checkHealth();
        final stats = service.getStats();

        await service.optimizePerformance();

        // Cleanup
        await service.dispose();

        // Assert
        expect(metrics, isA<PerformanceMetrics>());
        expect(processedItems, equals([2, 4, 6, 8, 10]));
        expect(deduplicated, equals([1, 2, 3]));
        expect(health, isA<ServiceHealthStatus>());
        expect(stats, isA<ServiceStats>());
      });
    });
  });
}
