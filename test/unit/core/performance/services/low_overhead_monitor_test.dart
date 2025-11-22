import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:jisu_fund_analyzer/src/core/performance/services/low_overhead_monitor.dart';
import 'package:jisu_fund_analyzer/src/core/performance/managers/advanced_memory_manager.dart';
import 'package:jisu_fund_analyzer/src/core/performance/monitors/memory_pressure_monitor.dart';
import 'package:jisu_fund_analyzer/src/core/performance/monitors/device_performance_detector.dart';
import 'package:jisu_fund_analyzer/src/core/utils/logger.dart';
import '../performance_test_base.dart';

/// 低开销性能监控器测试
@GenerateMocks(
    [AdvancedMemoryManager, MemoryPressureMonitor, DeviceCapabilityDetector])
void main() {
  group('LowOverheadMonitor Tests', () {
    late LowOverheadMonitor lowOverheadMonitor;
    late MockAdvancedMemoryManager mockMemoryManager;
    late MockMemoryPressureMonitor mockMemoryMonitor;
    late MockDeviceCapabilityDetector mockDeviceDetector;
    late PerformanceTestBase testBase;

    setUp(() async {
      testBase = PerformanceTestBase();
      await testBase.setUp();

      mockMemoryManager =
          testBase.mockMemoryManager as MockAdvancedMemoryManager;
      mockMemoryMonitor =
          testBase.mockMemoryMonitor as MockMemoryPressureMonitor;
      mockDeviceDetector =
          testBase.mockDeviceDetector as MockDeviceCapabilityDetector;

      lowOverheadMonitor = LowOverheadMonitor(
        memoryManager: mockMemoryManager,
        memoryMonitor: mockMemoryMonitor,
        deviceDetector: mockDeviceDetector,
      );

      await lowOverheadMonitor.initialize();
    });

    tearDown(() async {
      await lowOverheadMonitor.dispose();
      await testBase.tearDown();
    });

    group('Initialization Tests', () {
      test('should initialize successfully', () async {
        expect(lowOverheadMonitor.isInitialized, isTrue);
        expect(lowOverheadMonitor.isMonitoring, isFalse);
        expect(lowOverheadMonitor.configuration, isNotNull);
      });

      test('should load default configuration', () async {
        final config = lowOverheadMonitor.configuration;
        expect(config.samplingInterval.inMilliseconds, greaterThan(0));
        expect(config.maxOverheadPercent, greaterThan(0));
        expect(config.enableIntelligentSampling, isTrue);
        expect(config.enableAdaptiveInterval, isTrue);
        expect(config.metricsRetentionDuration.inMinutes, greaterThan(0));
      });

      test('should use custom configuration', () async {
        final customConfig = LowOverheadMonitorConfig(
          samplingInterval: Duration(milliseconds: 500),
          maxOverheadPercent: 1.0,
          enableIntelligentSampling: true,
          enableAdaptiveInterval: true,
          adaptiveIntervalRange: IntervalRange(
              min: Duration(milliseconds: 100), max: Duration(seconds: 2)),
          metricsRetentionDuration: Duration(hours: 2),
          alertThresholds: AlertThresholds(
            memoryUsageThreshold: 0.85,
            cpuUsageThreshold: 0.90,
            responseTimeThreshold: Duration(milliseconds: 500),
          ),
        );

        final customMonitor = LowOverheadMonitor(
          memoryManager: mockMemoryManager,
          memoryMonitor: mockMemoryMonitor,
          deviceDetector: mockDeviceDetector,
          config: customConfig,
        );

        await customMonitor.initialize();

        final loadedConfig = customMonitor.configuration;
        expect(loadedConfig.samplingInterval.inMilliseconds, equals(500));
        expect(loadedConfig.maxOverheadPercent, equals(1.0));

        await customMonitor.dispose();
      });

      test('should handle initialization errors gracefully', () async {
        when(mockMemoryManager.getMemoryInfo()).thenThrow(
          Exception('Memory manager initialization failed'),
        );

        final faultyMonitor = LowOverheadMonitor(
          memoryManager: mockMemoryManager,
        );

        expect(() async => await faultyMonitor.initialize(), returnsNormally);

        await faultyMonitor.dispose();
      });
    });

    group('Monitoring Control Tests', () {
      test('should start and stop monitoring correctly', () async {
        await lowOverheadMonitor.startMonitoring();
        expect(lowOverheadMonitor.isMonitoring, isTrue);

        await lowOverheadMonitor.stopMonitoring();
        expect(lowOverheadMonitor.isMonitoring, isFalse);
      });

      test('should handle multiple start/stop calls gracefully', () async {
        await lowOverheadMonitor.startMonitoring();
        await lowOverheadMonitor.startMonitoring(); // 重复调用
        expect(lowOverheadMonitor.isMonitoring, isTrue);

        await lowOverheadMonitor.stopMonitoring();
        await lowOverheadMonitor.stopMonitoring(); // 重复调用
        expect(lowOverheadMonitor.isMonitoring, isFalse);
      });

      test('should pause and resume monitoring correctly', () async {
        await lowOverheadMonitor.startMonitoring();

        await lowOverheadMonitor.pauseMonitoring();
        expect(lowOverheadMonitor.isMonitoring, isFalse);
        expect(lowOverheadMonitor.isPaused, isTrue);

        await lowOverheadMonitor.resumeMonitoring();
        expect(lowOverheadMonitor.isMonitoring, isTrue);
        expect(lowOverheadMonitor.isPaused, isFalse);
      });

      test('should handle pause without starting gracefully', () async {
        expect(() async => await lowOverheadMonitor.pauseMonitoring(),
            returnsNormally);
        expect(lowOverheadMonitor.isPaused, isFalse);
      });
    });

    group('Intelligent Sampling Tests', () {
      test('should adjust sampling interval based on system load', () async {
        when(mockMemoryManager.getMemoryInfo()).thenReturn(
          MemoryInfo(
            totalMemoryMB: 8192,
            availableMemoryMB: 1024,
            cachedMemoryMB: 6000,
            pressureScore: 0.85,
            timestamp: DateTime.now(),
          ),
        );

        when(mockMemoryMonitor.currentPressureLevel).thenReturn(
          MemoryPressureLevel.critical,
        );

        await lowOverheadMonitor.startMonitoring();

        // 在高负载下，采样间隔应该增加
        await Future.delayed(Duration(milliseconds: 200));

        final metrics = lowOverheadMonitor.getCurrentMetrics();
        expect(
            metrics.samplingInterval, greaterThan(Duration(milliseconds: 100)));

        await lowOverheadMonitor.stopMonitoring();
      });

      test('should reduce sampling frequency during high activity', () async {
        // 模拟高系统活动
        when(mockDeviceDetector.getDeviceInfo()).thenReturn(
          DeviceInfo(
            performanceScore: 30,
            cpuUsage: 0.85,
            memoryInfo: MemoryInfo(
              totalMemoryMB: 8192,
              availableMemoryMB: 2048,
              cachedMemoryMB: 4096,
              pressureScore: 0.75,
              timestamp: DateTime.now(),
            ),
          ),
        );

        await lowOverheadMonitor.startMonitoring();

        final initialMetrics = lowOverheadMonitor.getCurrentMetrics();
        final initialInterval = initialMetrics.samplingInterval;

        // 等待自适应调整
        await Future.delayed(Duration(milliseconds: 300));

        final adjustedMetrics = lowOverheadMonitor.getCurrentMetrics();
        final adjustedInterval = adjustedMetrics.samplingInterval;

        // 在高活动期间，间隔应该增加
        expect(adjustedInterval.inMilliseconds,
            greaterThanOrEqualTo(initialInterval.inMilliseconds));

        await lowOverheadMonitor.stopMonitoring();
      });

      test('should increase sampling frequency during low activity', () async {
        // 模拟低系统活动
        when(mockDeviceDetector.getDeviceInfo()).thenReturn(
          DeviceInfo(
            performanceScore: 95,
            cpuUsage: 0.15,
            memoryInfo: MemoryInfo(
              totalMemoryMB: 16384,
              availableMemoryMB: 12288,
              cachedMemoryMB: 1024,
              pressureScore: 0.2,
              timestamp: DateTime.now(),
            ),
          ),
        );

        when(mockMemoryMonitor.currentPressureLevel).thenReturn(
          MemoryPressureLevel.normal,
        );

        await lowOverheadMonitor.startMonitoring();

        await Future.delayed(Duration(milliseconds: 200));

        final metrics = lowOverheadMonitor.getCurrentMetrics();
        expect(metrics.samplingInterval.inMilliseconds,
            lessThan(Duration(seconds: 1).inMilliseconds));

        await lowOverheadMonitor.stopMonitoring();
      });

      test('should maintain overhead within configured limits', () async {
        final customConfig = LowOverheadMonitorConfig(
          samplingInterval: Duration(milliseconds: 100),
          maxOverheadPercent: 0.5, // 0.5% 最大开销
          enableIntelligentSampling: true,
        );

        final overheadMonitor = LowOverheadMonitor(
          memoryManager: mockMemoryManager,
          config: customConfig,
        );

        await overheadMonitor.initialize();
        await overheadMonitor.startMonitoring();

        // 运行一段时间以测量开销
        await Future.delayed(Duration(milliseconds: 1000));

        final overhead = overheadMonitor.getCurrentOverhead();
        expect(overhead.percent, lessThanOrEqualTo(0.5));

        await overheadMonitor.stopMonitoring();
        await overheadMonitor.dispose();
      });
    });

    group('Metrics Collection Tests', () {
      test('should collect comprehensive performance metrics', () async {
        when(mockMemoryManager.getMemoryInfo()).thenReturn(
          MemoryInfo(
            totalMemoryMB: 8192,
            availableMemoryMB: 4096,
            cachedMemoryMB: 2048,
            pressureScore: 0.5,
            timestamp: DateTime.now(),
          ),
        );

        when(mockMemoryMonitor.currentPressureLevel).thenReturn(
          MemoryPressureLevel.warning,
        );

        await lowOverheadMonitor.startMonitoring();

        // 等待一些数据收集
        await Future.delayed(Duration(milliseconds: 300));

        final metrics = lowOverheadMonitor.getCurrentMetrics();

        expect(metrics.timestamp, isNotNull);
        expect(metrics.memoryMetrics, isNotNull);
        expect(metrics.cpuMetrics, isNotNull);
        expect(metrics.overheadMetrics, isNotNull);
        expect(metrics.samplingInterval, isNotNull);
        expect(metrics.samplesCollected, greaterThan(0));

        await lowOverheadMonitor.stopMonitoring();
      });

      test('should track memory-related metrics', () async {
        final memoryInfos = [
          MemoryInfo(
            totalMemoryMB: 8192,
            availableMemoryMB: 4096,
            cachedMemoryMB: 2048,
            pressureScore: 0.5,
            timestamp: DateTime.now(),
          ),
          MemoryInfo(
            totalMemoryMB: 8192,
            availableMemoryMB: 3072,
            cachedMemoryMB: 3072,
            pressureScore: 0.62,
            timestamp: DateTime.now(),
          ),
        ];

        when(mockMemoryManager.getMemoryInfo()).thenAnswer((_) {
          return memoryInfos[math.Random().nextInt(memoryInfos.length)];
        });

        await lowOverheadMonitor.startMonitoring();

        await Future.delayed(Duration(milliseconds: 400));

        final metrics = lowOverheadMonitor.getCurrentMetrics();
        expect(metrics.memoryMetrics.totalMemoryMB, equals(8192));
        expect(metrics.memoryMetrics.currentUsage, greaterThan(0));
        expect(metrics.memoryMetrics.pressureScore, greaterThan(0));

        await lowOverheadMonitor.stopMonitoring();
      });

      test('should track CPU-related metrics', () async {
        when(mockDeviceDetector.getDeviceInfo()).thenReturn(
          DeviceInfo(
            performanceScore: 75,
            cpuUsage: 0.45,
            cpuFrequencyGHz: 2.4,
            cpuCores: 8,
            memoryInfo: testBase.createMockMemoryInfo(),
          ),
        );

        await lowOverheadMonitor.startMonitoring();

        await Future.delayed(Duration(milliseconds: 300));

        final metrics = lowOverheadMonitor.getCurrentMetrics();
        expect(metrics.cpuMetrics.usage, equals(0.45));
        expect(metrics.cpuMetrics.frequencyGHz, equals(2.4));
        expect(metrics.cpuMetrics.cores, equals(8));

        await lowOverheadMonitor.stopMonitoring();
      });

      test('should track overhead metrics', () async {
        await lowOverheadMonitor.startMonitoring();

        await Future.delayed(Duration(milliseconds: 500));

        final overhead = lowOverheadMonitor.getCurrentOverhead();
        expect(overhead.percent, greaterThanOrEqualTo(0));
        expect(overhead.samplingTime.inMicroseconds, greaterThan(0));
        expect(overhead.processingTime.inMicroseconds, greaterThan(0));
        expect(overhead.totalTime.inMicroseconds, greaterThan(0));

        await lowOverheadMonitor.stopMonitoring();
      });
    });

    group('Alerting Tests', () {
      test('should generate memory usage alerts', () async {
        final alertConfig = AlertThresholds(
          memoryUsageThreshold: 0.7, // 较低阈值以触发警告
          cpuUsageThreshold: 0.8,
          responseTimeThreshold: Duration(milliseconds: 200),
        );

        final alertMonitor = LowOverheadMonitor(
          memoryManager: mockMemoryManager,
          memoryMonitor: mockMemoryMonitor,
          deviceDetector: mockDeviceDetector,
          alertConfig: alertConfig,
        );

        when(mockMemoryManager.getMemoryInfo()).thenReturn(
          MemoryInfo(
            totalMemoryMB: 8192,
            availableMemoryMB: 1638, // 80% 使用率
            cachedMemoryMB: 4096,
            pressureScore: 0.8,
            timestamp: DateTime.now(),
          ),
        );

        final receivedAlerts = <PerformanceAlert>[];
        alertMonitor.onAlert.listen((alert) => receivedAlerts.add(alert));

        await alertMonitor.initialize();
        await alertMonitor.startMonitoring();

        await Future.delayed(Duration(milliseconds: 400));

        expect(receivedAlerts.length, greaterThan(0));
        expect(
            receivedAlerts.any((alert) => alert.type == AlertType.memoryUsage),
            isTrue);

        await alertMonitor.stopMonitoring();
        await alertMonitor.dispose();
      });

      test('should generate CPU usage alerts', () async {
        final alertConfig = AlertThresholds(
          memoryUsageThreshold: 0.9,
          cpuUsageThreshold: 0.6, // 较低阈值以触发警告
          responseTimeThreshold: Duration(milliseconds: 200),
        );

        final alertMonitor = LowOverheadMonitor(
          memoryManager: mockMemoryManager,
          memoryMonitor: mockMemoryMonitor,
          deviceDetector: mockDeviceDetector,
          alertConfig: alertConfig,
        );

        when(mockDeviceDetector.getDeviceInfo()).thenReturn(
          DeviceInfo(
            performanceScore: 30,
            cpuUsage: 0.75, // 高CPU使用率
            memoryInfo: testBase.createMockMemoryInfo(),
          ),
        );

        final receivedAlerts = <PerformanceAlert>[];
        alertMonitor.onAlert.listen((alert) => receivedAlerts.add(alert));

        await alertMonitor.initialize();
        await alertMonitor.startMonitoring();

        await Future.delayed(Duration(milliseconds: 400));

        expect(receivedAlerts.length, greaterThan(0));
        expect(receivedAlerts.any((alert) => alert.type == AlertType.cpuUsage),
            isTrue);

        await alertMonitor.stopMonitoring();
        await alertMonitor.dispose();
      });

      test('should generate overhead alerts', () async {
        final alertConfig = AlertThresholds(
          memoryUsageThreshold: 0.9,
          cpuUsageThreshold: 0.9,
          overheadThreshold: 0.3, // 较低阈值以触发警告
          responseTimeThreshold: Duration(milliseconds: 200),
        );

        final alertMonitor = LowOverheadMonitor(
          memoryManager: mockMemoryManager,
          config: LowOverheadMonitorConfig(
            samplingInterval: Duration(milliseconds: 10), // 高频采样以增加开销
            maxOverheadPercent: 0.2,
          ),
          alertConfig: alertConfig,
        );

        final receivedAlerts = <PerformanceAlert>[];
        alertMonitor.onAlert.listen((alert) => receivedAlerts.add(alert));

        await alertMonitor.initialize();
        await alertMonitor.startMonitoring();

        await Future.delayed(Duration(milliseconds: 200));

        expect(receivedAlerts.length, greaterThan(0));
        expect(receivedAlerts.any((alert) => alert.type == AlertType.overhead),
            isTrue);

        await alertMonitor.stopMonitoring();
        await alertMonitor.dispose();
      });

      test('should not generate alerts when thresholds are not exceeded',
          () async {
        when(mockMemoryManager.getMemoryInfo()).thenReturn(
          MemoryInfo(
            totalMemoryMB: 16384,
            availableMemoryMB: 12288, // 25% 使用率
            cachedMemoryMB: 2048,
            pressureScore: 0.25,
            timestamp: DateTime.now(),
          ),
        );

        when(mockDeviceDetector.getDeviceInfo()).thenReturn(
          DeviceInfo(
            performanceScore: 90,
            cpuUsage: 0.2, // 低CPU使用率
            memoryInfo: testBase.createMockMemoryInfo(),
          ),
        );

        final receivedAlerts = <PerformanceAlert>[];
        lowOverheadMonitor.onAlert.listen((alert) => receivedAlerts.add(alert));

        await lowOverheadMonitor.startMonitoring();

        await Future.delayed(Duration(milliseconds: 400));

        expect(receivedAlerts.isEmpty, isTrue);

        await lowOverheadMonitor.stopMonitoring();
      });
    });

    group('History and Analytics Tests', () {
      test('should maintain metrics history', () async {
        await lowOverheadMonitor.startMonitoring();

        await Future.delayed(Duration(milliseconds: 500));

        final history = lowOverheadMonitor.getMetricsHistory();
        expect(history.length, greaterThan(0));

        // 检查历史记录的时间顺序
        for (int i = 1; i < history.length; i++) {
          expect(
              history[i].timestamp.isAfter(history[i - 1].timestamp), isTrue);
        }

        await lowOverheadMonitor.stopMonitoring();
      });

      test('should provide performance trends', () async {
        when(mockMemoryManager.getMemoryInfo()).thenAnswer((_) {
          // 模拟逐渐增加的内存压力
          final pressure = 0.3 + (math.Random().nextDouble() * 0.1);
          return MemoryInfo(
            totalMemoryMB: 8192,
            availableMemoryMB: (8192 * (1 - pressure)).round(),
            cachedMemoryMB: 2048,
            pressureScore: pressure,
            timestamp: DateTime.now(),
          );
        });

        await lowOverheadMonitor.startMonitoring();

        await Future.delayed(Duration(milliseconds: 800));

        final trends = lowOverheadMonitor.getPerformanceTrends();
        expect(trends.memoryTrend, isNotNull);
        expect(trends.cpuTrend, isNotNull);
        expect(trends.overheadTrend, isNotNull);
        expect(trends.overallTrend, isNotNull);

        await lowOverheadMonitor.stopMonitoring();
      });

      test('should provide performance summary', () async {
        await lowOverheadMonitor.startMonitoring();

        await Future.delayed(Duration(milliseconds: 600));

        final summary = lowOverheadMonitor.getPerformanceSummary();
        expect(summary.monitoringDuration.inMilliseconds, greaterThan(0));
        expect(summary.totalSamples, greaterThan(0));
        expect(summary.averageOverheadPercent, greaterThanOrEqualTo(0));
        expect(summary.alertsGenerated, greaterThanOrEqualTo(0));
        expect(summary.metricsCollected, isNotNull);

        await lowOverheadMonitor.stopMonitoring();
      });

      test('should clean up old metrics based on retention policy', () async {
        final shortRetentionConfig = LowOverheadMonitorConfig(
          metricsRetentionDuration: Duration(milliseconds: 300), // 短保留期
        );

        final shortRetentionMonitor = LowOverheadMonitor(
          memoryManager: mockMemoryManager,
          config: shortRetentionConfig,
        );

        await shortRetentionMonitor.initialize();
        await shortRetentionMonitor.startMonitoring();

        await Future.delayed(Duration(milliseconds: 200));

        var history = shortRetentionMonitor.getMetricsHistory();
        expect(history.length, greaterThan(0));

        // 等待超过保留期
        await Future.delayed(Duration(milliseconds: 200));

        history = shortRetentionMonitor.getMetricsHistory();
        // 旧数据应该被清理
        expect(
            history.every((record) => record.timestamp.isAfter(DateTime.now()
                .subtract(shortRetentionConfig.metricsRetentionDuration))),
            isTrue);

        await shortRetentionMonitor.stopMonitoring();
        await shortRetentionMonitor.dispose();
      });
    });

    group('Adaptive Behavior Tests', () {
      test('should adapt sampling interval based on performance feedback',
          () async {
        await lowOverheadMonitor.startMonitoring();

        final initialMetrics = lowOverheadMonitor.getCurrentMetrics();
        final initialInterval = initialMetrics.samplingInterval;

        // 模拟高开销情况
        when(mockDeviceDetector.getDeviceInfo()).thenReturn(
          DeviceInfo(
            performanceScore: 25,
            cpuUsage: 0.9,
            memoryInfo: MemoryInfo(
              totalMemoryMB: 8192,
              availableMemoryMB: 512,
              cachedMemoryMB: 6000,
              pressureScore: 0.9,
              timestamp: DateTime.now(),
            ),
          ),
        );

        // 等待自适应调整
        await Future.delayed(Duration(milliseconds: 600));

        final adaptedMetrics = lowOverheadMonitor.getCurrentMetrics();
        final adaptedInterval = adaptedMetrics.samplingInterval;

        // 采样间隔应该增加以减少开销
        expect(adaptedInterval.inMilliseconds,
            greaterThanOrEqualTo(initialInterval.inMilliseconds));

        await lowOverheadMonitor.stopMonitoring();
      });

      test('should balance monitoring overhead with accuracy', () async {
        await lowOverheadMonitor.startMonitoring();

        var totalOverhead = 0.0;
        var samplesCollected = 0;

        for (int i = 0; i < 5; i++) {
          await Future.delayed(Duration(milliseconds: 100));

          final overhead = lowOverheadMonitor.getCurrentOverhead();
          final metrics = lowOverheadMonitor.getCurrentMetrics();

          totalOverhead += overhead.percent;
          samplesCollected = metrics.samplesCollected;
        }

        final averageOverhead = totalOverhead / 5;

        // 平均开销应该在配置的限制内
        expect(
            averageOverhead,
            lessThanOrEqualTo(
                lowOverheadMonitor.configuration.maxOverheadPercent));

        // 同时应该收集到足够的数据
        expect(samplesCollected, greaterThan(0));

        await lowOverheadMonitor.stopMonitoring();
      });

      test('should handle rapidly changing system conditions', () async {
        var conditionIndex = 0;

        when(mockMemoryManager.getMemoryInfo()).thenAnswer((_) {
          conditionIndex++;
          return MemoryInfo(
            totalMemoryMB: 8192,
            availableMemoryMB: 4096 - (conditionIndex % 1000), // 快速变化
            cachedMemoryMB: 2048 + (conditionIndex % 1000),
            pressureScore: 0.3 + (conditionIndex % 200) / 200.0,
            timestamp: DateTime.now(),
          );
        });

        await lowOverheadMonitor.startMonitoring();

        await Future.delayed(Duration(milliseconds: 1000));

        final history = lowOverheadMonitor.getMetricsHistory();
        expect(history.length, greaterThan(5));

        // 应该检测到变化的趋势
        final trends = lowOverheadMonitor.getPerformanceTrends();
        expect(trends.memoryTrend, isNotNull);

        await lowOverheadMonitor.stopMonitoring();
      });
    });

    group('Integration Tests', () {
      test('should integrate with memory manager', () async {
        when(mockMemoryManager.getMemoryInfo()).thenReturn(
          MemoryInfo(
            totalMemoryMB: 12288,
            availableMemoryMB: 6144,
            cachedMemoryMB: 4096,
            pressureScore: 0.5,
            timestamp: DateTime.now(),
          ),
        );

        await lowOverheadMonitor.startMonitoring();

        await Future.delayed(Duration(milliseconds: 300));

        final metrics = lowOverheadMonitor.getCurrentMetrics();
        expect(metrics.memoryMetrics.totalMemoryMB, equals(12288));
        expect(metrics.memoryMetrics.availableMemoryMB, equals(6144));

        await lowOverheadMonitor.stopMonitoring();
      });

      test('should integrate with memory pressure monitor', () async {
        when(mockMemoryMonitor.currentPressureLevel).thenReturn(
          MemoryPressureLevel.warning,
        );

        await lowOverheadMonitor.startMonitoring();

        await Future.delayed(Duration(milliseconds: 300));

        final metrics = lowOverheadMonitor.getCurrentMetrics();
        expect(metrics.memoryMetrics.pressureLevel,
            equals(MemoryPressureLevel.warning));

        await lowOverheadMonitor.stopMonitoring();
      });

      test('should integrate with device performance detector', () async {
        when(mockDeviceDetector.getDeviceInfo()).thenReturn(
          DeviceInfo(
            performanceScore: 80,
            cpuUsage: 0.4,
            cpuFrequencyGHz: 3.2,
            cpuCores: 6,
            memoryInfo: testBase.createMockMemoryInfo(),
          ),
        );

        await lowOverheadMonitor.startMonitoring();

        await Future.delayed(Duration(milliseconds: 300));

        final metrics = lowOverheadMonitor.getCurrentMetrics();
        expect(metrics.cpuMetrics.usage, equals(0.4));
        expect(metrics.cpuMetrics.frequencyGHz, equals(3.2));
        expect(metrics.cpuMetrics.cores, equals(6));

        await lowOverheadMonitor.stopMonitoring();
      });
    });

    group('Error Handling and Recovery Tests', () {
      test('should handle memory manager errors gracefully', () async {
        when(mockMemoryManager.getMemoryInfo()).thenThrow(
          Exception('Memory manager error'),
        );

        await lowOverheadMonitor.startMonitoring();

        // 监控应该继续工作
        await Future.delayed(Duration(milliseconds: 300));

        final metrics = lowOverheadMonitor.getCurrentMetrics();
        expect(metrics.timestamp, isNotNull);
        expect(metrics.samplesCollected, greaterThanOrEqualTo(0));

        await lowOverheadMonitor.stopMonitoring();
      });

      test('should handle device detector errors gracefully', () async {
        when(mockDeviceDetector.getDeviceInfo()).thenThrow(
          Exception('Device detector error'),
        );

        await lowOverheadMonitor.startMonitoring();

        await Future.delayed(Duration(milliseconds: 300));

        final metrics = lowOverheadMonitor.getCurrentMetrics();
        expect(metrics.timestamp, isNotNull);
        // CPU指标应该使用默认值
        expect(metrics.cpuMetrics.usage, greaterThanOrEqualTo(0));

        await lowOverheadMonitor.stopMonitoring();
      });

      test('should handle memory monitor errors gracefully', () async {
        when(mockMemoryMonitor.currentPressureLevel).thenThrow(
          Exception('Memory monitor error'),
        );

        await lowOverheadMonitor.startMonitoring();

        await Future.delayed(Duration(milliseconds: 300));

        final metrics = lowOverheadMonitor.getCurrentMetrics();
        expect(metrics.timestamp, isNotNull);
        // 压力级别应该使用默认值
        expect(metrics.memoryMetrics.pressureLevel, isNotNull);

        await lowOverheadMonitor.stopMonitoring();
      });

      test('should handle monitoring interruption gracefully', () async {
        await lowOverheadMonitor.startMonitoring();

        await Future.delayed(Duration(milliseconds: 200));

        // 模拟监控中断
        await lowOverheadMonitor.pauseMonitoring();

        // 应该能够恢复
        await lowOverheadMonitor.resumeMonitoring();

        await Future.delayed(Duration(milliseconds: 200));

        final metrics = lowOverheadMonitor.getCurrentMetrics();
        expect(metrics.timestamp, isNotNull);
        expect(lowOverheadMonitor.isMonitoring, isTrue);

        await lowOverheadMonitor.stopMonitoring();
      });

      test('should handle concurrent operations safely', () async {
        final futures = <Future<void>>[];

        // 并发启动/停止监控
        for (int i = 0; i < 5; i++) {
          futures.add(Future(() async {
            await lowOverheadMonitor.startMonitoring();
            await Future.delayed(Duration(milliseconds: 50));
            await lowOverheadMonitor.stopMonitoring();
          }));
        }

        // 并发获取指标
        for (int i = 0; i < 5; i++) {
          futures.add(Future(() async {
            await Future.delayed(Duration(milliseconds: 25));
            lowOverheadMonitor.getCurrentMetrics();
            lowOverheadMonitor.getCurrentOverhead();
          }));
        }

        await Future.wait(futures);

        // 系统应该处于一致状态
        expect(lowOverheadMonitor.isMonitoring, isFalse);
      });
    });

    group('Performance and Scalability Tests', () {
      test('should maintain low overhead during extended monitoring', () async {
        await lowOverheadMonitor.startMonitoring();

        final startTime = DateTime.now();
        var totalOverhead = 0.0;
        var measurements = 0;

        for (int i = 0; i < 20; i++) {
          await Future.delayed(Duration(milliseconds: 50));

          final overhead = lowOverheadMonitor.getCurrentOverhead();
          totalOverhead += overhead.percent;
          measurements++;
        }

        final totalTime = DateTime.now().difference(startTime);
        final averageOverhead = totalOverhead / measurements;

        expect(
            averageOverhead,
            lessThanOrEqualTo(
                lowOverheadMonitor.configuration.maxOverheadPercent));
        expect(totalTime.inMilliseconds, lessThan(2000)); // 不应该显著增加执行时间

        await lowOverheadMonitor.stopMonitoring();
      });

      test('should handle high-frequency monitoring efficiently', () async {
        final highFreqConfig = LowOverheadMonitorConfig(
          samplingInterval: Duration(milliseconds: 50),
          maxOverheadPercent: 1.0,
        );

        final highFreqMonitor = LowOverheadMonitor(
          memoryManager: mockMemoryManager,
          config: highFreqConfig,
        );

        await highFreqMonitor.initialize();
        await highFreqMonitor.startMonitoring();

        final stopwatch = Stopwatch()..start();
        await Future.delayed(Duration(milliseconds: 1000));
        stopwatch.stop();

        final metrics = highFreqMonitor.getCurrentMetrics();
        expect(metrics.samplesCollected, greaterThan(10)); // 应该收集到足够的样本

        final overhead = highFreqMonitor.getCurrentOverhead();
        expect(overhead.percent, lessThanOrEqualTo(1.0));

        await highFreqMonitor.stopMonitoring();
        await highFreqMonitor.dispose();
      });
    });
  });
}
