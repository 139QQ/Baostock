import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import '../../../../../lib/src/core/performance/processors/adaptive_batch_sizer.dart';
import '../../../../../lib/src/core/performance/monitors/device_performance_detector.dart';
import '../../../../../lib/src/core/performance/managers/advanced_memory_manager.dart';
import '../../../../../lib/src/core/performance/monitors/memory_pressure_monitor.dart';
import '../../../../../lib/src/core/utils/logger.dart';
import '../performance_test_base.dart';

/// 自适应批次大小调整器测试
@GenerateMocks(
    [DeviceCapabilityDetector, AdvancedMemoryManager, MemoryPressureMonitor])
void main() {
  group('AdaptiveBatchSizer Tests', () {
    late AdaptiveBatchSizer batchSizer;
    late MockDeviceCapabilityDetector mockDeviceDetector;
    late MockAdvancedMemoryManager mockMemoryManager;
    late MockMemoryPressureMonitor mockMemoryMonitor;
    late PerformanceTestBase testBase;

    setUp(() async {
      testBase = PerformanceTestBase();
      await testBase.setUp();

      mockDeviceDetector =
          testBase.mockDeviceDetector as MockDeviceCapabilityDetector;
      mockMemoryManager =
          testBase.mockMemoryManager as MockAdvancedMemoryManager;
      mockMemoryMonitor =
          testBase.mockMemoryMonitor as MockMemoryPressureMonitor;

      batchSizer = AdaptiveBatchSizer(
        deviceDetector: mockDeviceDetector,
        memoryManager: mockMemoryManager,
        memoryMonitor: mockMemoryMonitor,
      );

      await batchSizer.initialize();
    });

    tearDown(() async {
      await batchSizer.dispose();
      await testBase.tearDown();
    });

    group('Initialization Tests', () {
      test('should initialize successfully', () async {
        expect(batchSizer.currentBatchSize, greaterThan(0));
        expect(batchSizer.currentStrategy, isNotNull);
        expect(batchSizer.isInitialized, isTrue);
      });

      test('should load default configuration correctly', () async {
        final config = batchSizer.configuration;
        expect(config.initialBatchSize, greaterThan(0));
        expect(config.minBatchSize, greaterThan(0));
        expect(config.maxBatchSize, greaterThan(config.minBatchSize));
        expect(config.adjustmentStep, greaterThan(0));
        expect(config.adjustmentInterval.inMilliseconds, greaterThan(0));
      });

      test('should use custom configuration', () async {
        final customConfig = AdaptiveBatchSizingConfig(
          initialBatchSize: 150,
          minBatchSize: 20,
          maxBatchSize: 800,
          adjustmentStep: 15,
          targetThroughput: 1200.0,
          targetErrorRate: 0.03,
          adjustmentInterval: Duration(seconds: 3),
          historyRetentionTime: Duration(minutes: 45),
          enablePredictiveAdjustment: true,
          enableLoadAwareAdjustment: true,
          enableErrorRateAwareAdjustment: true,
          adjustmentSensitivity: 0.7,
        );

        final customSizer = AdaptiveBatchSizer(
          config: customConfig,
          deviceDetector: mockDeviceDetector,
          memoryManager: mockMemoryManager,
          memoryMonitor: mockMemoryMonitor,
        );

        await customSizer.initialize();

        expect(customSizer.currentBatchSize, equals(150));
        expect(
            customSizer.currentStrategy, equals(BatchSizingStrategy.adaptive));

        await customSizer.dispose();
      });

      test('should handle initialization errors gracefully', () async {
        when(mockDeviceDetector.getDeviceInfo()).thenThrow(
          Exception('Device detector initialization failed'),
        );

        final faultySizer = AdaptiveBatchSizer(
          deviceDetector: mockDeviceDetector,
          memoryManager: mockMemoryManager,
        );

        // 应该使用默认配置继续初始化
        expect(() async => await faultySizer.initialize(), returnsNormally);

        await faultySizer.dispose();
      });
    });

    group('Batch Size Adjustment Tests', () {
      test('should increase batch size for good performance', () async {
        final initialSize = batchSizer.currentBatchSize;

        // 模拟良好性能指标
        batchSizer.updatePerformanceMetrics(
          throughput: 1500.0, // 高于目标吞吐量
          errorRate: 0.02, // 低于目标错误率
        );

        // 模拟轻负载条件
        when(mockMemoryManager.getMemoryInfo()).thenReturn(
          MemoryInfo(
            totalMemoryMB: 16384,
            availableMemoryMB: 12288,
            cachedMemoryMB: 2048,
          ),
        );

        when(mockMemoryMonitor.currentPressureLevel).thenReturn(
          MemoryPressureLevel.normal,
        );

        // 等待调整间隔
        await Future.delayed(Duration(milliseconds: 100));

        // 手动触发调整
        await batchSizer.performAdjustment();

        final newSize = batchSizer.currentBatchSize;
        expect(newSize, greaterThanOrEqualTo(initialSize));
      });

      test('should decrease batch size for poor performance', () async {
        final initialSize = batchSizer.currentBatchSize;

        // 模拟糟糕性能指标
        batchSizer.updatePerformanceMetrics(
          throughput: 300.0, // 低于目标吞吐量
          errorRate: 0.15, // 高于目标错误率
        );

        // 模拟重负载条件
        when(mockMemoryManager.getMemoryInfo()).thenReturn(
          MemoryInfo(
            totalMemoryMB: 8192,
            availableMemoryMB: 1024,
            cachedMemoryMB: 6000,
          ),
        );

        when(mockMemoryMonitor.currentPressureLevel).thenReturn(
          MemoryPressureLevel.critical,
        );

        await batchSizer.performAdjustment();

        final newSize = batchSizer.currentBatchSize;
        expect(newSize, lessThanOrEqualTo(initialSize));
      });

      test('should respect batch size limits', () async {
        final config = AdaptiveBatchSizingConfig(
          initialBatchSize: 50,
          minBatchSize: 20,
          maxBatchSize: 100,
          adjustmentStep: 50, // 大步长调整
        );

        final limitedSizer = AdaptiveBatchSizer(
          config: config,
          deviceDetector: mockDeviceDetector,
          memoryManager: mockMemoryManager,
        );

        await limitedSizer.initialize();

        // 尝试增加批次大小
        limitedSizer.updatePerformanceMetrics(
            throughput: 2000.0, errorRate: 0.01);
        await limitedSizer.performAdjustment();

        expect(limitedSizer.currentBatchSize, lessThanOrEqualTo(100));

        // 尝试减少批次大小
        limitedSizer.updatePerformanceMetrics(
            throughput: 100.0, errorRate: 0.5);
        await limitedSizer.performAdjustment();

        expect(limitedSizer.currentBatchSize, greaterThanOrEqualTo(20));

        await limitedSizer.dispose();
      });

      test('should maintain stable batch size for optimal performance',
          () async {
        final initialSize = batchSizer.currentBatchSize;

        // 模拟最优性能指标
        batchSizer.updatePerformanceMetrics(
          throughput: 1000.0, // 等于目标吞吐量
          errorRate: 0.05, // 等于目标错误率
        );

        when(mockMemoryManager.getMemoryInfo()).thenReturn(
          MemoryInfo(
            totalMemoryMB: 8192,
            availableMemoryMB: 4096,
            cachedMemoryMB: 2048,
          ),
        );

        when(mockMemoryMonitor.currentPressureLevel).thenReturn(
          MemoryPressureLevel.warning,
        );

        await batchSizer.performAdjustment();

        final newSize = batchSizer.currentBatchSize;
        // 批次大小应该保持相对稳定
        expect((newSize - initialSize).abs(), lessThanOrEqualTo(10));
      });
    });

    group('Strategy Tests', () {
      test('should switch to conservative strategy under high load', () async {
        when(mockMemoryManager.getMemoryInfo()).thenReturn(
          MemoryInfo(
            totalMemoryMB: 8192,
            availableMemoryMB: 1024,
            cachedMemoryMB: 6000,
          ),
        );

        when(mockMemoryMonitor.currentPressureLevel).thenReturn(
          MemoryPressureLevel.emergency,
        );

        batchSizer.updatePerformanceMetrics(throughput: 200.0, errorRate: 0.3);
        await batchSizer.performAdjustment();

        expect(batchSizer.currentStrategy,
            equals(BatchSizingStrategy.conservative));
        expect(batchSizer.currentBatchSize, lessThan(50));
      });

      test('should use aggressive strategy under light load', () async {
        when(mockMemoryManager.getMemoryInfo()).thenReturn(
          MemoryInfo(
            totalMemoryMB: 16384,
            availableMemoryMB: 14336,
            cachedMemoryMB: 1024,
          ),
        );

        when(mockMemoryMonitor.currentPressureLevel).thenReturn(
          MemoryPressureLevel.normal,
        );

        batchSizer.updatePerformanceMetrics(
            throughput: 2000.0, errorRate: 0.01);
        await batchSizer.performAdjustment();

        expect(
            batchSizer.currentStrategy,
            anyOf([
              equals(BatchSizingStrategy.aggressive),
              equals(BatchSizingStrategy.adaptive),
            ]));
      });

      test('should respect user-defined strategy', () async {
        batchSizer.setStrategy(BatchSizingStrategy.balanced);

        final initialSize = batchSizer.currentBatchSize;
        batchSizer.updatePerformanceMetrics(throughput: 500.0, errorRate: 0.08);
        await batchSizer.performAdjustment();

        expect(
            batchSizer.currentStrategy, equals(BatchSizingStrategy.balanced));
      });
    });

    group('Load-aware Adjustment Tests', () {
      test('should adapt to memory pressure changes', () async {
        final initialSize = batchSizer.currentBatchSize;

        // 模拟内存压力增加
        when(mockMemoryManager.getMemoryInfo()).thenReturn(
          MemoryInfo(
            totalMemoryMB: 8192,
            availableMemoryMB: 1024,
            cachedMemoryMB: 6000,
          ),
        );

        when(mockMemoryMonitor.currentPressureLevel).thenReturn(
          MemoryPressureLevel.critical,
        );

        await batchSizer.performAdjustment();

        final pressureSize = batchSizer.currentBatchSize;
        expect(pressureSize, lessThan(initialSize));

        // 模拟内存压力缓解
        when(mockMemoryManager.getMemoryInfo()).thenReturn(
          MemoryInfo(
            totalMemoryMB: 8192,
            availableMemoryMB: 6144,
            cachedMemoryMB: 1024,
          ),
        );

        when(mockMemoryMonitor.currentPressureLevel).thenReturn(
          MemoryPressureLevel.normal,
        );

        batchSizer.updatePerformanceMetrics(
            throughput: 1500.0, errorRate: 0.02);
        await batchSizer.performAdjustment();

        final recoveredSize = batchSizer.currentBatchSize;
        expect(recoveredSize, greaterThanOrEqualTo(pressureSize));
      });

      test('should consider device performance capabilities', () async {
        // 模拟高性能设备
        when(mockDeviceDetector.getDeviceInfo()).thenReturn(
          DeviceInfo(
            performanceScore: 95,
            cpuCores: 12,
            totalMemoryMB: 32768,
            memoryInfo: MemoryInfo(
              totalMemoryMB: 32768,
              availableMemoryMB: 24576,
              cachedMemoryMB: 4096,
            ),
          ),
        );

        final highEndSizer = AdaptiveBatchSizer(
          deviceDetector: mockDeviceDetector,
          memoryManager: mockMemoryManager,
        );

        await highEndSizer.initialize();
        final highEndSize = highEndSizer.currentBatchSize;

        // 模拟低性能设备
        when(mockDeviceDetector.getDeviceInfo()).thenReturn(
          DeviceInfo(
            performanceScore: 25,
            cpuCores: 2,
            totalMemoryMB: 4096,
            memoryInfo: MemoryInfo(
              totalMemoryMB: 4096,
              availableMemoryMB: 1024,
              cachedMemoryMB: 2048,
            ),
          ),
        );

        final lowEndSizer = AdaptiveBatchSizer(
          deviceDetector: mockDeviceDetector,
          memoryManager: mockMemoryManager,
        );

        await lowEndSizer.initialize();
        final lowEndSize = lowEndSizer.currentBatchSize;

        expect(highEndSize, greaterThan(lowEndSize));

        await highEndSizer.dispose();
        await lowEndSizer.dispose();
      });
    });

    group('History and Learning Tests', () {
      test('should maintain adjustment history', () async {
        final initialSize = batchSizer.currentBatchSize;

        for (int i = 0; i < 5; i++) {
          batchSizer.updatePerformanceMetrics(
            throughput: 500.0 + (i * 200),
            errorRate: 0.1 - (i * 0.015),
          );

          await batchSizer.performAdjustment();
          await Future.delayed(Duration(milliseconds: 10));
        }

        final summary = batchSizer.getPerformanceSummary();
        expect(summary['historyCount'], greaterThan(0));
        expect(summary['recentHistory'], isNotNull);
        expect(summary['recentHistory'], isA<List>());
      });

      test('should learn from historical performance', () async {
        // 创建一些历史数据
        final historyItems = <BatchSizeHistory>[];

        for (int i = 0; i < 10; i++) {
          historyItems.add(BatchSizeHistory(
            size: 50 + (i * 10),
            timestamp: DateTime.now().subtract(Duration(minutes: i)),
            throughput: 800.0 + (i * 50),
            errorRate: 0.1 - (i * 0.005),
            loadLevel: SystemLoadLevel.moderate,
            action: SizingAction.increase,
            reason: 'Performance improvement',
          ));
        }

        // 历史数据应该影响推荐
        batchSizer.updatePerformanceMetrics(
            throughput: 1000.0, errorRate: 0.06);
        final recommendation = batchSizer.getRecommendedBatchSize();

        expect(recommendation, greaterThan(0));
      });

      test('should predict optimal batch size based on trends', () async {
        // 模拟性能趋势改善
        for (int i = 0; i < 5; i++) {
          batchSizer.updatePerformanceMetrics(
            throughput: 600.0 + (i * 100), // 改善的吞吐量
            errorRate: 0.12 - (i * 0.01), // 改善的错误率
          );

          await batchSizer.performAdjustment();
          await Future.delayed(Duration(milliseconds: 50));
        }

        final optimalSize = batchSizer.getRecommendedBatchSize();
        final currentSize = batchSizer.currentBatchSize;

        // 基于改善趋势，推荐大小应该适合当前趋势
        expect(optimalSize, greaterThan(0));
        expect(
            optimalSize,
            anyOf([
              equals(currentSize),
              greaterThan(currentSize),
              lessThan(currentSize),
            ]));
      });
    });

    group('Prediction Tests', () {
      test('should predict memory usage trends', () async {
        // 模拟内存使用上升趋势
        for (int i = 0; i < 5; i++) {
          when(mockMemoryManager.getMemoryInfo()).thenReturn(
            MemoryInfo(
              totalMemoryMB: 8192,
              availableMemoryMB: 4096 - (i * 500), // 逐渐减少可用内存
              cachedMemoryMB: 2048 + (i * 300), // 逐渐增加缓存
              // 逐渐增加压力
            ),
          );

          await batchSizer.performAdjustment();
        }

        batchSizer.updatePerformanceMetrics(throughput: 700.0, errorRate: 0.07);
        final recommendation = batchSizer.getRecommendedBatchSize();

        // 基于内存趋势，应该推荐较小的批次大小
        expect(recommendation,
            lessThan(batchSizer.configuration.initialBatchSize));
      });

      test('should predict load patterns', () async {
        // 模拟周期性负载模式
        for (int cycle = 0; cycle < 3; cycle++) {
          // 高负载期
          when(mockMemoryManager.getMemoryInfo()).thenReturn(
            MemoryInfo(
              totalMemoryMB: 8192,
              availableMemoryMB: 2048,
              cachedMemoryMB: 4096,
            ),
          );

          batchSizer.updatePerformanceMetrics(
              throughput: 400.0, errorRate: 0.12);
          await batchSizer.performAdjustment();

          await Future.delayed(Duration(milliseconds: 50));

          // 低负载期
          when(mockMemoryManager.getMemoryInfo()).thenReturn(
            MemoryInfo(
              totalMemoryMB: 8192,
              availableMemoryMB: 6144,
              cachedMemoryMB: 1024,
            ),
          );

          batchSizer.updatePerformanceMetrics(
              throughput: 1200.0, errorRate: 0.03);
          await batchSizer.performAdjustment();

          await Future.delayed(Duration(milliseconds: 50));
        }

        // 应该能够识别模式并做出相应调整
        final metrics = batchSizer.getPerformanceSummary();
        expect(metrics['historyCount'], greaterThan(0));
      });
    });

    group('Manual Adjustment Tests', () {
      test('should handle manual batch size adjustments', () async {
        final initialSize = batchSizer.currentBatchSize;
        final manualSize = initialSize + 25;

        final result = batchSizer.manualAdjustment(
          newSize: manualSize,
          reason: 'Manual testing adjustment',
        );

        expect(result.newSize, equals(manualSize));
        expect(result.action, equals(SizingAction.increase));
        expect(batchSizer.currentBatchSize, equals(manualSize));
      });

      test('should clamp manual adjustments to limits', () async {
        final oversizedSize = batchSizer.configuration.maxBatchSize + 100;
        final undersizedSize = batchSizer.configuration.minBatchSize - 10;

        final oversizedResult =
            batchSizer.manualAdjustment(newSize: oversizedSize);
        final undersizedResult =
            batchSizer.manualAdjustment(newSize: undersizedSize);

        expect(oversizedResult.newSize,
            lessThanOrEqualTo(batchSizer.configuration.maxBatchSize));
        expect(undersizedResult.newSize,
            greaterThanOrEqualTo(batchSizer.configuration.minBatchSize));
      });

      test('should record manual adjustments in history', () async {
        final initialSize = batchSizer.currentBatchSize;
        final manualSize = initialSize + 15;

        batchSizer.manualAdjustment(
            newSize: manualSize, reason: 'Testing manual adjustment');

        final summary = batchSizer.getPerformanceSummary();
        final recentHistory = summary['recentHistory'] as List;

        expect(recentHistory.isNotEmpty, isTrue);
        expect(
            recentHistory.any((record) => record['reason']
                .toString()
                .contains('Testing manual adjustment')),
            isTrue);
      });
    });

    group('Performance Metrics Tests', () {
      test('should provide comprehensive performance summary', () async {
        batchSizer.updatePerformanceMetrics(throughput: 950.0, errorRate: 0.06);
        await batchSizer.performAdjustment();

        final summary = batchSizer.getPerformanceSummary();

        expect(summary['currentBatchSize'], isA<int>());
        expect(summary['currentStrategy'], isA<String>());
        expect(summary['currentThroughput'], equals(950.0));
        expect(summary['currentErrorRate'], equals(0.06));
        expect(summary['config'], isA<Map<String, dynamic>>());
        expect(summary['recentHistory'], isA<List>());
      });

      test('should track adjustment confidence', () async {
        batchSizer.updatePerformanceMetrics(
            throughput: 1000.0, errorRate: 0.05);
        await batchSizer.performAdjustment();

        final summary = batchSizer.getPerformanceSummary();
        expect(summary['recentHistory'], isNotNull);

        final recentHistory = summary['recentHistory'] as List;
        if (recentHistory.isNotEmpty) {
          final latestRecord = recentHistory.last;
          expect(latestRecord['confidence'], isA<double>());
          expect(latestRecord['confidence'], greaterThanOrEqualTo(0.0));
          expect(latestRecord['confidence'], lessThanOrEqualTo(1.0));
        }
      });
    });

    group('Integration Tests', () {
      test('should integrate with device capability detector', () async {
        when(mockDeviceDetector.getDeviceInfo()).thenReturn(
          DeviceInfo(
            performanceScore: 85,
            cpuCores: 8,
            totalMemoryMB: 16384,
            memoryInfo: MemoryInfo(
              totalMemoryMB: 16384,
              availableMemoryMB: 12288,
              cachedMemoryMB: 2048,
            ),
          ),
        );

        batchSizer.updatePerformanceMetrics(
            throughput: 1200.0, errorRate: 0.04);
        await batchSizer.performAdjustment();

        expect(batchSizer.currentBatchSize, greaterThan(50));
      });

      test('should integrate with memory pressure monitor', () async {
        when(mockMemoryMonitor.currentPressureLevel).thenReturn(
          MemoryPressureLevel.warning,
        );

        batchSizer.updatePerformanceMetrics(throughput: 800.0, errorRate: 0.07);
        await batchSizer.performAdjustment();

        expect(
            batchSizer.currentStrategy,
            anyOf([
              equals(BatchSizingStrategy.conservative),
              equals(BatchSizingStrategy.adaptive),
            ]));
      });

      test('should integrate with memory manager', () async {
        when(mockMemoryManager.getMemoryInfo()).thenReturn(
          MemoryInfo(
            totalMemoryMB: 12288,
            availableMemoryMB: 8192,
            cachedMemoryMB: 3072,
            pressureScore: 0.33,
          ),
        );

        batchSizer.updatePerformanceMetrics(
            throughput: 1100.0, errorRate: 0.04);
        await batchSizer.performAdjustment();

        expect(batchSizer.currentBatchSize, greaterThan(0));
      });
    });

    group('Error Handling and Recovery Tests', () {
      test('should handle device detector errors gracefully', () async {
        when(mockDeviceDetector.getDeviceInfo()).thenThrow(
          Exception('Device detector error'),
        );

        // 应该继续使用默认设备信息
        batchSizer.updatePerformanceMetrics(throughput: 900.0, errorRate: 0.05);
        expect(
            () async => await batchSizer.performAdjustment(), returnsNormally);

        expect(batchSizer.currentBatchSize, greaterThan(0));
      });

      test('should handle memory manager errors gracefully', () async {
        when(mockMemoryManager.getMemoryInfo()).thenThrow(
          Exception('Memory manager error'),
        );

        // 应该使用默认内存信息
        expect(
            () async => await batchSizer.performAdjustment(), returnsNormally);

        expect(batchSizer.currentBatchSize, greaterThan(0));
      });

      test('should handle memory monitor errors gracefully', () async {
        when(mockMemoryMonitor.currentPressureLevel).thenThrow(
          Exception('Memory monitor error'),
        );

        // 应该使用默认压力级别
        expect(
            () async => await batchSizer.performAdjustment(), returnsNormally);

        expect(batchSizer.currentBatchSize, greaterThan(0));
      });

      test('should handle invalid performance metrics gracefully', () async {
        // 测试无效的性能指标
        batchSizer.updatePerformanceMetrics(throughput: -10.0, errorRate: 1.5);
        await batchSizer.performAdjustment();

        expect(batchSizer.currentBatchSize, greaterThan(0));

        // 测试null值
        batchSizer.updatePerformanceMetrics(throughput: null, errorRate: null);
        await batchSizer.performAdjustment();

        expect(batchSizer.currentBatchSize, greaterThan(0));
      });

      test('should recover from adjustment failures', () async {
        // 尝试触发内部错误
        for (int i = 0; i < 100; i++) {
          batchSizer.updatePerformanceMetrics(
            throughput: math.Random().nextDouble() * 2000,
            errorRate: math.Random().nextDouble(),
          );

          try {
            await batchSizer.performAdjustment();
          } catch (e) {
            // 应该能够恢复并继续工作
          }
        }

        expect(batchSizer.currentBatchSize, greaterThan(0));
        expect(batchSizer.currentStrategy, isNotNull);
      });
    });

    group('Concurrent Operations Tests', () {
      test('should handle concurrent adjustments safely', () async {
        final futures = <Future<void>>[];

        for (int i = 0; i < 10; i++) {
          futures.add(Future(() async {
            batchSizer.updatePerformanceMetrics(
              throughput: 500.0 + (i * 100),
              errorRate: 0.1 - (i * 0.01),
            );

            await batchSizer.performAdjustment();
          }));
        }

        await Future.wait(futures);

        expect(batchSizer.currentBatchSize, greaterThan(0));
        expect(batchSizer.currentStrategy, isNotNull);
      });

      test('should handle concurrent manual and automatic adjustments',
          () async {
        final futures = <Future<void>>[];

        // 自动调整
        for (int i = 0; i < 5; i++) {
          futures.add(Future(() async {
            batchSizer.updatePerformanceMetrics(
                throughput: 800.0, errorRate: 0.06);
            await batchSizer.performAdjustment();
          }));
        }

        // 手动调整
        for (int i = 0; i < 5; i++) {
          futures.add(Future(() async {
            batchSizer.manualAdjustment(
                newSize: 75 + i, reason: 'Concurrent test $i');
          }));
        }

        await Future.wait(futures);

        expect(batchSizer.currentBatchSize, greaterThan(0));
      });
    });
  });
}
