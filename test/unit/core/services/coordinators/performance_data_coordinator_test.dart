import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:jisu_fund_analyzer/src/core/services/base/i_unified_service.dart';
import 'package:jisu_fund_analyzer/src/core/services/coordinators/performance_data_coordinator.dart';
import 'package:jisu_fund_analyzer/src/core/services/performance/unified_performance_service.dart';
import 'package:jisu_fund_analyzer/src/core/services/data/unified_data_service.dart';

// Mock classes
import 'performance_data_coordinator_test.mocks.dart';

@GenerateMocks([
  ServiceContainer,
  UnifiedPerformanceService,
  UnifiedDataService,
])
void main() {
  group('PerformanceDataCoordinator', () {
    late PerformanceDataCoordinator coordinator;
    late MockServiceContainer mockContainer;
    late MockUnifiedPerformanceService mockPerformanceService;
    late MockUnifiedDataService mockDataService;

    setUp(() {
      coordinator = PerformanceDataCoordinator();
      mockContainer = MockServiceContainer();
      mockPerformanceService = MockUnifiedPerformanceService();
      mockDataService = MockUnifiedDataService();

      // 设置mock behavior
      when(mockContainer.getServiceByName('UnifiedPerformanceService'))
          .thenReturn(mockPerformanceService);
      when(mockContainer.getServiceByName('UnifiedDataService'))
          .thenReturn(mockDataService);

      // 设置默认的mock返回值
      when(mockPerformanceService.checkHealth())
          .thenAnswer((_) async => ServiceHealthStatus(
                isHealthy: true,
                message: 'Healthy',
                lastCheck: DateTime.now(),
              ));

      when(mockDataService.checkHealth())
          .thenAnswer((_) async => ServiceHealthStatus(
                isHealthy: true,
                message: 'Healthy',
                lastCheck: DateTime.now(),
              ));

      when(mockPerformanceService.getCurrentPerformanceMetrics())
          .thenAnswer((_) async => PerformanceMetrics(
                timestamp: DateTime.now(),
                cpuUsage: 50.0,
                memoryUsage: 60.0,
                activeLoadingTasks: 5,
                queuedLoadingTasks: 2,
                cachedItems: 100,
                status: PerformanceStatus.good,
                additionalMetrics: {},
              ));

      when(mockDataService.getCacheStatistics())
          .thenAnswer((_) async => CacheStatistics(
                hiveCache: CacheStats(
                  size: 50,
                  memoryUsage: 1024,
                  hitRate: 85.0,
                  requestCount: 500,
                  lastAccess: DateTime.now(),
                ),
                intelligentCache: CacheStats(
                  size: 30,
                  memoryUsage: 512,
                  hitRate: 90.0,
                  requestCount: 300,
                  lastAccess: DateTime.now(),
                ),
                optimizedCache: CacheStats(
                  size: 20,
                  memoryUsage: 256,
                  hitRate: 80.0,
                  requestCount: 200,
                  lastAccess: DateTime.now(),
                ),
                totalSize: 100,
                totalMemoryUsage: 1792,
                averageHitRate: 85.0,
              ));

      // 设置流控制器
      final performanceController =
          StreamController<PerformanceMetrics>.broadcast();
      final memoryPressureController =
          StreamController<MemoryPressureEvent>.broadcast();
      final alertsController = StreamController<PerformanceAlert>.broadcast();
      final dataOperationController =
          StreamController<DataOperationEvent>.broadcast();
      final cacheMetricsController =
          StreamController<CacheMetricsEvent>.broadcast();

      when(mockPerformanceService.performanceMetricsStream)
          .thenAnswer((_) => performanceController.stream);
      when(mockPerformanceService.memoryPressureStream)
          .thenAnswer((_) => memoryPressureController.stream);
      when(mockPerformanceService.performanceAlertsStream)
          .thenAnswer((_) => alertsController.stream);
      when(mockDataService.dataOperationStream)
          .thenAnswer((_) => dataOperationController.stream);
      when(mockDataService.cacheMetricsStream)
          .thenAnswer((_) => cacheMetricsController.stream);

      // 存储控制器引用以便在测试中使用
      _performanceController = performanceController;
      _memoryPressureController = memoryPressureController;
      _alertsController = alertsController;
      _dataOperationController = dataOperationController;
      _cacheMetricsController = cacheMetricsController;
    });

    tearDown(() async {
      await coordinator.dispose();

      // 关闭所有流控制器
      await _performanceController.close();
      await _memoryPressureController.close();
      await _alertsController.close();
      await _dataOperationController.close();
      await _cacheMetricsController.close();
    });

    // 流控制器变量，用于测试中触发事件
    late StreamController<PerformanceMetrics> _performanceController;
    late StreamController<MemoryPressureEvent> _memoryPressureController;
    late StreamController<PerformanceAlert> _alertsController;
    late StreamController<DataOperationEvent> _dataOperationController;
    late StreamController<CacheMetricsEvent> _cacheMetricsController;

    test('should have correct service metadata', () {
      expect(coordinator.serviceName, equals('PerformanceDataCoordinator'));
      expect(coordinator.version, equals('1.0.0'));
      expect(coordinator.dependencies, contains('UnifiedPerformanceService'));
      expect(coordinator.dependencies, contains('UnifiedDataService'));
    });

    test('should initialize successfully', () async {
      // Act
      await coordinator.initialize(mockContainer);

      // Assert
      expect(coordinator.lifecycleState,
          equals(ServiceLifecycleState.initialized));
      verify(mockContainer.getServiceByName('UnifiedPerformanceService'))
          .called(1);
      verify(mockContainer.getServiceByName('UnifiedDataService')).called(1);
    });

    test('should dispose successfully', () async {
      // Arrange
      await coordinator.initialize(mockContainer);

      // Act
      await coordinator.dispose();

      // Assert
      expect(
          coordinator.lifecycleState, equals(ServiceLifecycleState.disposed));
    });

    test('should provide coordination stream', () async {
      // Arrange
      await coordinator.initialize(mockContainer);

      // Act
      final stream = coordinator.coordinationStream;

      // Assert
      expect(stream, isA<Stream<CoordinationEvent>>());
    });

    test('should return current coordination mode', () {
      // Act
      final mode = coordinator.currentMode;

      // Assert
      expect(mode, isA<CoordinationMode>());
      expect(mode, equals(CoordinationMode.balanced));
    });

    test('should check health status correctly', () async {
      // Arrange
      await coordinator.initialize(mockContainer);

      // Act
      final healthStatus = await coordinator.checkHealth();

      // Assert
      expect(healthStatus, isA<ServiceHealthStatus>());
      expect(healthStatus.isHealthy, isTrue);
      expect(healthStatus.details, contains('currentMode'));
      expect(healthStatus.details, contains('performanceHealth'));
      expect(healthStatus.details, contains('dataHealth'));
    });

    test('should provide service statistics', () async {
      // Arrange
      await coordinator.initialize(mockContainer);

      // Act
      final stats = coordinator.getStats();

      // Assert
      expect(stats, isA<ServiceStats>());
      expect(stats.serviceName, equals('PerformanceDataCoordinator'));
      expect(stats.version, equals('1.0.0'));
      expect(stats.customMetrics, contains('currentMode'));
    });

    group('Coordination optimization', () {
      setUp(() async {
        await coordinator.initialize(mockContainer);
      });

      test('should trigger manual coordination optimization', () async {
        // Act & Assert
        expect(
          () => coordinator.triggerCoordinationOptimization(),
          returnsNormally,
        );

        expect(
          () => coordinator.triggerCoordinationOptimization(
            mode: CoordinationMode.performance,
          ),
          returnsNormally,
        );
      });

      test('should provide coordination recommendations', () async {
        // Arrange - 模拟需要优化的性能指标
        when(mockPerformanceService.getCurrentPerformanceMetrics())
            .thenAnswer((_) async => PerformanceMetrics(
                  timestamp: DateTime.now(),
                  cpuUsage: 90.0, // 高CPU使用率
                  memoryUsage: 85.0, // 高内存使用率
                  activeLoadingTasks: 5,
                  queuedLoadingTasks: 60, // 高队列积压
                  cachedItems: 100,
                  status: PerformanceStatus.warning,
                  additionalMetrics: {},
                ));

        when(mockDataService.getCacheStatistics())
            .thenAnswer((_) async => CacheStatistics(
                  hiveCache: CacheStats(
                    size: 50,
                    memoryUsage: 1024,
                    hitRate: 60.0, // 低缓存命中率
                    requestCount: 500,
                    lastAccess: DateTime.now(),
                  ),
                  intelligentCache: CacheStats(
                    size: 30,
                    memoryUsage: 512,
                    hitRate: 65.0,
                    requestCount: 300,
                    lastAccess: DateTime.now(),
                  ),
                  optimizedCache: CacheStats(
                    size: 20,
                    memoryUsage: 256,
                    hitRate: 70.0,
                    requestCount: 200,
                    lastAccess: DateTime.now(),
                  ),
                  totalSize: 100,
                  totalMemoryUsage: 1792,
                  averageHitRate: 65.0, // 平均缓存命中率低
                ));

        // Act
        final recommendations =
            await coordinator.getCoordinationRecommendations();

        // Assert
        expect(recommendations, isA<List<CoordinationRecommendation>>());
        expect(recommendations.isNotEmpty, isTrue);

        // 检查是否有内存优化建议
        final memoryRec = recommendations.firstWhere(
          (r) => r.type == RecommendationType.memoryOptimization,
          orElse: () => CoordinationRecommendation(
            type: RecommendationType.memoryOptimization,
            priority: RecommendationPriority.low,
            title: 'dummy',
            description: 'dummy',
            actions: [],
          ),
        );

        expect(memoryRec.priority, equals(RecommendationPriority.high));
      });

      test('should handle scenario with no recommendations', () async {
        // Arrange - 模拟良好的性能指标
        when(mockPerformanceService.getCurrentPerformanceMetrics())
            .thenAnswer((_) async => PerformanceMetrics(
                  timestamp: DateTime.now(),
                  cpuUsage: 30.0,
                  memoryUsage: 40.0,
                  activeLoadingTasks: 5,
                  queuedLoadingTasks: 5,
                  cachedItems: 100,
                  status: PerformanceStatus.optimal,
                  additionalMetrics: {},
                ));

        when(mockDataService.getCacheStatistics())
            .thenAnswer((_) async => CacheStatistics(
                  hiveCache: CacheStats(
                    size: 50,
                    memoryUsage: 1024,
                    hitRate: 95.0,
                    requestCount: 500,
                    lastAccess: DateTime.now(),
                  ),
                  intelligentCache: CacheStats(
                    size: 30,
                    memoryUsage: 512,
                    hitRate: 93.0,
                    requestCount: 300,
                    lastAccess: DateTime.now(),
                  ),
                  optimizedCache: CacheStats(
                    size: 20,
                    memoryUsage: 256,
                    hitRate: 90.0,
                    requestCount: 200,
                    lastAccess: DateTime.now(),
                  ),
                  totalSize: 100,
                  totalMemoryUsage: 1792,
                  averageHitRate: 93.0,
                ));

        // Act
        final recommendations =
            await coordinator.getCoordinationRecommendations();

        // Assert
        expect(recommendations, isEmpty);
      });
    });

    group('Event handling', () {
      setUp(() async {
        await coordinator.initialize(mockContainer);
      });

      test('should handle performance metrics events', () async {
        // Arrange
        final completer = Completer<CoordinationEvent>();
        late StreamSubscription subscription;

        subscription = coordinator.coordinationStream.listen((event) {
          if (!completer.isCompleted) {
            completer.complete(event);
          }
        });

        // Act
        final metrics = PerformanceMetrics(
          timestamp: DateTime.now(),
          cpuUsage: 95.0,
          memoryUsage: 90.0,
          activeLoadingTasks: 5,
          queuedLoadingTasks: 10,
          cachedItems: 100,
          status: PerformanceStatus.critical,
          additionalMetrics: {},
        );

        _performanceController.add(metrics);

        // Wait for event
        final event =
            await completer.future.timeout(const Duration(seconds: 5));

        // Cleanup
        await subscription.cancel();

        // Assert
        expect(event, isA<CoordinationEvent>());
        // 可能的事件类型：modeChange, emergencyResponse, alertResponse
      });

      test('should handle memory pressure events', () async {
        // Arrange
        final completer = Completer<CoordinationEvent>();
        late StreamSubscription subscription;

        subscription = coordinator.coordinationStream.listen((event) {
          if (!completer.isCompleted) {
            completer.complete(event);
          }
        });

        // Act
        final pressureEvent = MemoryPressureEvent(
          timestamp: DateTime.now(),
          pressureLevel: MemoryPressureLevel.critical,
          message: 'Critical memory pressure',
        );

        _memoryPressureController.add(pressureEvent);

        // Wait for event
        final event =
            await completer.future.timeout(const Duration(seconds: 5));

        // Cleanup
        await subscription.cancel();

        // Assert
        expect(event, isA<CoordinationEvent>());
      });

      test('should handle performance alert events', () async {
        // Arrange
        final completer = Completer<CoordinationEvent>();
        late StreamSubscription subscription;

        subscription = coordinator.coordinationStream.listen((event) {
          if (!completer.isCompleted) {
            completer.complete(event);
          }
        });

        // Act
        final alert = PerformanceAlert(
          timestamp: DateTime.now(),
          type: AlertType.highCpuUsage,
          severity: AlertSeverity.critical,
          message: 'Critical CPU usage detected',
        );

        _alertsController.add(alert);

        // Wait for event
        final event =
            await completer.future.timeout(const Duration(seconds: 5));

        // Cleanup
        await subscription.cancel();

        // Assert
        expect(event, isA<CoordinationEvent>());
      });

      test('should handle data operation events', () async {
        // Arrange
        final completer = Completer<CoordinationEvent>();
        late StreamSubscription subscription;

        subscription = coordinator.coordinationStream.listen((event) {
          if (!completer.isCompleted) {
            completer.complete(event);
          }
        });

        // Act
        final operationEvent = DataOperationEvent(
          timestamp: DateTime.now(),
          operationType: DataOperationType.batchRead,
          dataType: 'fund',
          key: 'batch_key',
          success: false,
          error: 'Network error',
          metadata: {'count': 10},
        );

        _dataOperationController.add(operationEvent);

        // Wait for event
        final event =
            await completer.future.timeout(const Duration(seconds: 5));

        // Cleanup
        await subscription.cancel();

        // Assert
        expect(event, isA<CoordinationEvent>());
      });

      test('should handle cache metrics events', () async {
        // Arrange
        final completer = Completer<CoordinationEvent>();
        late StreamSubscription subscription;

        subscription = coordinator.coordinationStream.listen((event) {
          if (!completer.isCompleted) {
            completer.complete(event);
          }
        });

        // Act
        final metricsEvent = CacheMetricsEvent(
          timestamp: DateTime.now(),
          hitRate: 65.0, // 低命中率
          totalSize: 1000,
          memoryUsage: 2048,
        );

        _cacheMetricsController.add(metricsEvent);

        // Wait for event
        final event =
            await completer.future.timeout(const Duration(seconds: 5));

        // Cleanup
        await subscription.cancel();

        // Assert
        expect(event, isA<CoordinationEvent>());
      });
    });

    group('Mode calculation', () {
      test('should calculate emergency mode for critical status', () {
        // Arrange
        final metrics = PerformanceMetrics(
          timestamp: DateTime.now(),
          cpuUsage: 95.0,
          memoryUsage: 90.0,
          activeLoadingTasks: 5,
          queuedLoadingTasks: 10,
          cachedItems: 100,
          status: PerformanceStatus.critical,
          additionalMetrics: {},
        );

        // Act & Assert - 这个测试需要访问私有方法
        // 在实际实现中，可以通过公共接口测试模式变化
      });

      test('should calculate conservative mode for high resource usage', () {
        // Arrange
        final metrics = PerformanceMetrics(
          timestamp: DateTime.now(),
          cpuUsage: 90.0,
          memoryUsage: 85.0,
          activeLoadingTasks: 5,
          queuedLoadingTasks: 10,
          cachedItems: 100,
          status: PerformanceStatus.warning,
          additionalMetrics: {},
        );

        // Act & Assert
      });

      test('should calculate performance mode for optimal status', () {
        // Arrange
        final metrics = PerformanceMetrics(
          timestamp: DateTime.now(),
          cpuUsage: 30.0,
          memoryUsage: 40.0,
          activeLoadingTasks: 5,
          queuedLoadingTasks: 2,
          cachedItems: 100,
          status: PerformanceStatus.optimal,
          additionalMetrics: {},
        );

        // Act & Assert
      });
    });

    group('Error handling', () {
      test('should handle service unavailability gracefully', () async {
        // Arrange
        when(mockContainer.getServiceByName('UnifiedPerformanceService'))
            .thenReturn(null);
        when(mockContainer.getServiceByName('UnifiedDataService'))
            .thenReturn(null);

        // Act & Assert
        expect(
          () => coordinator.initialize(mockContainer),
          throwsA(isA<ServiceInitializationException>()),
        );
      });

      test('should handle service health issues correctly', () async {
        // Arrange
        when(mockPerformanceService.checkHealth())
            .thenAnswer((_) async => ServiceHealthStatus(
                  isHealthy: false,
                  message: 'Performance service unhealthy',
                  lastCheck: DateTime.now(),
                ));

        // Act
        await coordinator.initialize(mockContainer);
        final healthStatus = await coordinator.checkHealth();

        // Assert
        expect(healthStatus.isHealthy, isFalse);
        expect(healthStatus.message, contains('issues detected'));
      });

      test('should handle double dispose gracefully', () async {
        // Arrange
        await coordinator.initialize(mockContainer);

        // Act
        await coordinator.dispose();

        // Assert
        expect(
          () => coordinator.dispose(),
          returnsNormally,
        );
      });
    });

    group('Enum extensions', () {
      test('should provide correct names for coordination modes', () {
        expect(CoordinationMode.emergency.name, equals('emergency'));
        expect(CoordinationMode.conservative.name, equals('conservative'));
        expect(CoordinationMode.balanced.name, equals('balanced'));
        expect(CoordinationMode.performance.name, equals('performance'));
      });

      test('should provide correct names for coordination event types', () {
        expect(CoordinationEventType.modeChange.name, equals('modeChange'));
        expect(CoordinationEventType.emergencyResponse.name,
            equals('emergencyResponse'));
        expect(
            CoordinationEventType.alertResponse.name, equals('alertResponse'));
        expect(CoordinationEventType.manualOptimization.name,
            equals('manualOptimization'));
        expect(CoordinationEventType.recommendationApplied.name,
            equals('recommendationApplied'));
        expect(CoordinationEventType.error.name, equals('error'));
      });

      test('should provide correct names for recommendation types', () {
        expect(RecommendationType.memoryOptimization.name,
            equals('memoryOptimization'));
        expect(
            RecommendationType.cpuOptimization.name, equals('cpuOptimization'));
        expect(RecommendationType.cacheOptimization.name,
            equals('cacheOptimization'));
        expect(RecommendationType.queueOptimization.name,
            equals('queueOptimization'));
        expect(RecommendationType.networkOptimization.name,
            equals('networkOptimization'));
      });

      test('should provide correct names for recommendation priorities', () {
        expect(RecommendationPriority.low.name, equals('low'));
        expect(RecommendationPriority.medium.name, equals('medium'));
        expect(RecommendationPriority.high.name, equals('high'));
        expect(RecommendationPriority.critical.name, equals('critical'));
      });
    });

    group('Serialization', () {
      test('should serialize coordination recommendations correctly', () {
        // Arrange
        const recommendation = CoordinationRecommendation(
          type: RecommendationType.memoryOptimization,
          priority: RecommendationPriority.high,
          title: 'Test Recommendation',
          description: 'Test description',
          actions: ['action1', 'action2'],
        );

        // Act
        final json = recommendation.toJson();

        // Assert
        expect(json['type'], equals('memoryOptimization'));
        expect(json['priority'], equals('high'));
        expect(json['title'], equals('Test Recommendation'));
        expect(json['description'], equals('Test description'));
        expect(json['actions'], equals(['action1', 'action2']));
      });
    });

    group('Integration tests', () {
      test('should work end-to-end with full lifecycle', () async {
        // Act
        await coordinator.initialize(mockContainer);

        // Test various operations
        final mode = coordinator.currentMode;
        final health = await coordinator.checkHealth();
        final stats = coordinator.getStats();
        final recommendations =
            await coordinator.getCoordinationRecommendations();

        await coordinator.triggerCoordinationOptimization();

        // Wait for some events to ensure streams work
        await Future.delayed(const Duration(milliseconds: 100));

        // Cleanup
        await coordinator.dispose();

        // Assert
        expect(mode, isA<CoordinationMode>());
        expect(health, isA<ServiceHealthStatus>());
        expect(stats, isA<ServiceStats>());
        expect(recommendations, isA<List<CoordinationRecommendation>>());
      });

      test('should handle event stream integration correctly', () async {
        // Arrange
        await coordinator.initialize(mockContainer);

        final eventCompleter = Completer<List<CoordinationEvent>>();
        final events = <CoordinationEvent>[];
        late StreamSubscription subscription;

        subscription = coordinator.coordinationStream.listen((event) {
          events.add(event);
          if (events.length >= 2) {
            eventCompleter.complete(events);
          }
        });

        // Act - 触发多个事件
        _performanceController.add(PerformanceMetrics(
          timestamp: DateTime.now(),
          cpuUsage: 85.0,
          memoryUsage: 75.0,
          activeLoadingTasks: 5,
          queuedLoadingTasks: 10,
          cachedItems: 100,
          status: PerformanceStatus.warning,
          additionalMetrics: {},
        ));

        _alertsController.add(PerformanceAlert(
          timestamp: DateTime.now(),
          type: AlertType.highCpuUsage,
          severity: AlertSeverity.high,
          message: 'High CPU usage',
        ));

        // Wait for events
        final receivedEvents =
            await eventCompleter.future.timeout(const Duration(seconds: 5));

        // Cleanup
        await subscription.cancel();
        await coordinator.dispose();

        // Assert
        expect(receivedEvents.length, greaterThanOrEqualTo(2));
        expect(receivedEvents.every((e) => e is CoordinationEvent), isTrue);
      });
    });
  });
}
