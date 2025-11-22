import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

import 'package:jisu_fund_analyzer/src/core/services/performance/unified_performance_service.dart';

void main() {
  group('UnifiedPerformanceService - Simple Tests', () {
    late UnifiedPerformanceService service;

    setUp(() {
      service = UnifiedPerformanceService();
    });

    tearDown(() async {
      await service.dispose();
    });

    test('should have correct service metadata', () {
      expect(service.serviceName, equals('UnifiedPerformanceService'));
      expect(service.version, equals('1.0.0'));
      expect(service.dependencies, isEmpty);
    });

    test('should handle service lifecycle correctly', () async {
      // Initial state
      expect(service.lifecycleState.name, equals('uninitialized'));

      // Note: Full initialization test would require ServiceContainer mock
      // For now, just test that the service can be created and disposed
      expect(service, isNotNull);
    });

    test('should provide performance status extensions', () {
      expect(PerformanceStatus.optimal.name, equals('optimal'));
      expect(PerformanceStatus.good.name, equals('good'));
      expect(PerformanceStatus.warning.name, equals('warning'));
      expect(PerformanceStatus.critical.name, equals('critical'));
    });

    test('should provide memory pressure level extensions', () {
      expect(MemoryPressureLevel.low.name, equals('low'));
      expect(MemoryPressureLevel.medium.name, equals('medium'));
      expect(MemoryPressureLevel.high.name, equals('high'));
      expect(MemoryPressureLevel.critical.name, equals('critical'));
    });

    test('should provide alert type extensions', () {
      expect(AlertType.highCpuUsage.name, equals('highCpuUsage'));
      expect(AlertType.highMemoryUsage.name, equals('highMemoryUsage'));
      expect(AlertType.queueBacklog.name, equals('queueBacklog'));
      expect(AlertType.memoryPressure.name, equals('memoryPressure'));
      expect(AlertType.networkLatency.name, equals('networkLatency'));
      expect(AlertType.diskIoWarning.name, equals('diskIoWarning'));
    });

    test('should provide alert severity extensions', () {
      expect(AlertSeverity.low.name, equals('low'));
      expect(AlertSeverity.medium.name, equals('medium'));
      expect(AlertSeverity.high.name, equals('high'));
      expect(AlertSeverity.critical.name, equals('critical'));
    });

    test('should create PerformanceMetrics correctly', () {
      const metrics = PerformanceMetrics(
        timestamp: null, // Would use real timestamp in production
        cpuUsage: 75.5,
        memoryUsage: 60.2,
        activeLoadingTasks: 5,
        queuedLoadingTasks: 2,
        cachedItems: 100,
        status: PerformanceStatus.good,
        additionalMetrics: {'custom': 'value'},
      );

      expect(metrics.cpuUsage, equals(75.5));
      expect(metrics.memoryUsage, equals(60.2));
      expect(metrics.status, equals(PerformanceStatus.good));
      expect(metrics.additionalMetrics['custom'], equals('value'));
    });

    test('should serialize PerformanceMetrics to JSON', () {
      const metrics = PerformanceMetrics(
        timestamp: null,
        cpuUsage: 75.5,
        memoryUsage: 60.2,
        activeLoadingTasks: 5,
        queuedLoadingTasks: 2,
        cachedItems: 100,
        status: PerformanceStatus.good,
        additionalMetrics: {'custom': 'value'},
      );

      final json = metrics.toJson();

      expect(json['cpuUsage'], equals(75.5));
      expect(json['memoryUsage'], equals(60.2));
      expect(json['status'], equals('good'));
      expect(json['custom'], equals('value'));
    });

    test('should create MemoryPressureEvent correctly', () {
      final event = MemoryPressureEvent(
        timestamp: DateTime.now(),
        pressureLevel: MemoryPressureLevel.high,
        message: 'High memory pressure detected',
      );

      expect(event.pressureLevel, equals(MemoryPressureLevel.high));
      expect(event.message, equals('High memory pressure detected'));
      expect(event.timestamp, isA<DateTime>());
    });

    test('should create PerformanceAlert correctly', () {
      final alert = PerformanceAlert(
        timestamp: DateTime.now(),
        type: AlertType.highCpuUsage,
        severity: AlertSeverity.high,
        message: 'High CPU usage detected',
      );

      expect(alert.type, equals(AlertType.highCpuUsage));
      expect(alert.severity, equals(AlertSeverity.high));
      expect(alert.message, equals('High CPU usage detected'));
      expect(alert.timestamp, isA<DateTime>());
    });
  });
}
