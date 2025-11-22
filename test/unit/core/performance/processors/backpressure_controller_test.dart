import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import '../../../../../lib/src/core/performance/processors/backpressure_controller.dart';
import '../../../../../lib/src/core/performance/managers/advanced_memory_manager.dart';
import '../../../../../lib/src/core/performance/monitors/memory_pressure_monitor.dart';
import '../../../../../lib/src/core/performance/monitors/device_performance_detector.dart';
import '../../../../../lib/src/core/utils/logger.dart';
import '../performance_test_base.dart';

/// 背压控制器测试
@GenerateMocks(
    [AdvancedMemoryManager, MemoryPressureMonitor, DeviceCapabilityDetector])
void main() {
  group('BackpressureController Tests', () {
    late BackpressureController backpressureController;
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

      backpressureController = BackpressureController(
        memoryManager: mockMemoryManager,
        memoryMonitor: mockMemoryMonitor,
        deviceDetector: mockDeviceDetector,
      );

      await backpressureController.initialize();
    });

    tearDown(() async {
      await backpressureController.dispose();
      await testBase.tearDown();
    });

    group('Initialization Tests', () {
      test('should initialize successfully', () async {
        expect(backpressureController.isInitialized, isTrue);
        expect(backpressureController.currentStrategy, isNotNull);
      });

      test('should load default configuration', () async {
        final config = backpressureController.configuration;
        expect(config.memoryThreshold, greaterThan(0));
        expect(config.cpuThreshold, greaterThan(0));
        expect(config.enableAdaptiveStrategy, isTrue);
      });

      test('should handle initialization errors gracefully', () async {
        when(mockMemoryManager.getMemoryInfo()).thenThrow(
          Exception('Memory manager initialization failed'),
        );

        // 应该使用默认配置继续初始化
        final faultyController = BackpressureController(
          memoryManager: mockMemoryManager,
        );

        expect(
            () async => await faultyController.initialize(), returnsNormally);

        await faultyController.dispose();
      });
    });

    group('Backpressure Detection Tests', () {
      test('should detect memory pressure correctly', () async {
        // 模拟内存压力
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

        final pressure = await backpressureController.detectPressure();

        expect(pressure.memoryPressure, greaterThan(0.7));
        expect(pressure.overallPressure, greaterThan(0.7));
        expect(pressure.shouldApplyBackpressure, isTrue);
        expect(pressure.recommendedAction, isNotNull);
      });

      test('should detect CPU pressure correctly', () async {
        // 模拟CPU压力
        when(mockDeviceDetector.getDeviceInfo()).thenReturn(
          DeviceInfo(
            performanceScore: 30,
            memoryInfo: MemoryInfo(
              totalMemoryMB: 8192,
              availableMemoryMB: 4096,
              cachedMemoryMB: 2048,
              pressureScore: 0.3,
              timestamp: DateTime.now(),
            ),
          ),
        );

        final pressure = await backpressureController.detectPressure();

        expect(pressure.cpuPressure, greaterThan(0.6));
        expect(pressure.overallPressure, greaterThan(0.3));
      });

      test('should handle normal system conditions', () async {
        // 模拟正常系统条件
        when(mockMemoryManager.getMemoryInfo()).thenReturn(
          MemoryInfo(
            totalMemoryMB: 16384,
            availableMemoryMB: 12288,
            cachedMemoryMB: 2048,
            pressureScore: 0.2,
            timestamp: DateTime.now(),
          ),
        );

        when(mockMemoryMonitor.currentPressureLevel).thenReturn(
          MemoryPressureLevel.normal,
        );

        final pressure = await backpressureController.detectPressure();

        expect(pressure.memoryPressure, lessThan(0.5));
        expect(pressure.overallPressure, lessThan(0.5));
        expect(pressure.shouldApplyBackpressure, isFalse);
      });

      test('should detect combined system pressure', () async {
        // 模拟多种压力源
        when(mockMemoryManager.getMemoryInfo()).thenReturn(
          MemoryInfo(
            totalMemoryMB: 8192,
            availableMemoryMB: 2048,
            cachedMemoryMB: 4096,
            pressureScore: 0.7,
            timestamp: DateTime.now(),
          ),
        );

        when(mockMemoryMonitor.currentPressureLevel).thenReturn(
          MemoryPressureLevel.warning,
        );

        when(mockDeviceDetector.getDeviceInfo()).thenReturn(
          DeviceInfo(
            performanceScore: 40,
            memoryInfo: MemoryInfo(
              totalMemoryMB: 8192,
              availableMemoryMB: 4096,
              cachedMemoryMB: 2048,
              pressureScore: 0.5,
              timestamp: DateTime.now(),
            ),
          ),
        );

        final pressure = await backpressureController.detectPressure();

        expect(pressure.memoryPressure, greaterThan(0.5));
        expect(pressure.cpuPressure, greaterThan(0.5));
        expect(pressure.overallPressure, greaterThan(0.6));
        expect(pressure.shouldApplyBackpressure, isTrue);
      });
    });

    group('Backpressure Strategy Tests', () {
      test('should select appropriate strategy based on pressure', () async {
        // 模拟高内存压力
        when(mockMemoryManager.getMemoryInfo()).thenReturn(
          MemoryInfo(
            totalMemoryMB: 8192,
            availableMemoryMB: 1024,
            cachedMemoryMB: 6000,
            pressureScore: 0.9,
            timestamp: DateTime.now(),
          ),
        );

        final pressure = SystemPressure(
          memoryPressure: 0.9,
          cpuPressure: 0.3,
          ioPressure: 0.2,
          overallPressure: 0.8,
          shouldApplyBackpressure: true,
          recommendedAction: BackpressureAction.throttle,
        );

        final strategy = await backpressureController.selectStrategy(pressure);

        expect(strategy.type, equals(BackpressureStrategyType.aggressive));
        expect(strategy.throttleRate, lessThan(1.0));
        expect(strategy.maxQueueSize, lessThan(1000));
      });

      test('should apply conservative strategy for moderate pressure',
          () async {
        final pressure = SystemPressure(
          memoryPressure: 0.6,
          cpuPressure: 0.5,
          ioPressure: 0.3,
          overallPressure: 0.5,
          shouldApplyBackpressure: true,
          recommendedAction: BackpressureAction.reduce_batch_size,
        );

        final strategy = await backpressureController.selectStrategy(pressure);

        expect(strategy.type, equals(BackpressureStrategyType.conservative));
        expect(strategy.throttleRate, greaterThan(0.5));
      });

      test('should disable backpressure for low pressure', () async {
        final pressure = SystemPressure(
          memoryPressure: 0.2,
          cpuPressure: 0.3,
          ioPressure: 0.1,
          overallPressure: 0.2,
          shouldApplyBackpressure: false,
          recommendedAction: BackpressureAction.none,
        );

        final strategy = await backpressureController.selectStrategy(pressure);

        expect(strategy.type, equals(BackpressureStrategyType.disabled));
        expect(strategy.throttleRate, equals(1.0));
      });

      test('should adapt strategy based on historical performance', () async {
        // 模拟历史性能数据
        final history = [
          StrategyPerformance(
            strategyType: BackpressureStrategyType.conservative,
            appliedAt: DateTime.now().subtract(Duration(minutes: 10)),
            duration: Duration(seconds: 30),
            effectiveness: 0.8,
            systemImpact: 0.3,
          ),
          StrategyPerformance(
            strategyType: BackpressureStrategyType.aggressive,
            appliedAt: DateTime.now().subtract(Duration(minutes: 5)),
            duration: Duration(seconds: 45),
            effectiveness: 0.6,
            systemImpact: 0.7,
          ),
        ];

        await backpressureController.updateStrategyHistory(history);

        final pressure = SystemPressure(
          memoryPressure: 0.7,
          cpuPressure: 0.5,
          ioPressure: 0.3,
          overallPressure: 0.6,
          shouldApplyBackpressure: true,
          recommendedAction: BackpressureAction.throttle,
        );

        final strategy = await backpressureController.selectStrategy(pressure);

        // 应该优先选择历史上更有效的策略
        expect(
            strategy.type,
            anyOf([
              equals(BackpressureStrategyType.conservative),
              equals(BackpressureStrategyType.adaptive),
            ]));
      });
    });

    group('Throttling and Control Tests', () {
      test('should throttle processing correctly', () async {
        await backpressureController.applyStrategy(BackpressureStrategy(
          type: BackpressureStrategyType.throttling,
          throttleRate: 0.5,
          maxQueueSize: 100,
          priorityLevels: 3,
        ));

        final processedItems = <String>[];
        final startTime = DateTime.now();

        for (int i = 0; i < 10; i++) {
          final result = await backpressureController.shouldProceed();
          if (result.shouldProceed) {
            processedItems.add('item_$i');
            await Future.delayed(Duration(milliseconds: 10));
          } else {
            if (result.delay != null) {
              await Future.delayed(result.delay!);
            }
          }
        }

        final processingTime = DateTime.now().difference(startTime);

        // 由于节流率是0.5，处理时间应该比正常情况更长
        expect(processingTime.inMilliseconds, greaterThan(100));
        expect(processedItems.length, greaterThan(0));
      });

      test('should respect priority levels', () async {
        await backpressureController.applyStrategy(BackpressureStrategy(
          type: BackpressureStrategyType.priority_based,
          throttleRate: 0.7,
          maxQueueSize: 50,
          priorityLevels: 5,
        ));

        final highPriorityResults = <bool>[];
        final lowPriorityResults = <bool>[];

        for (int i = 0; i < 10; i++) {
          // 高优先级任务
          final highResult =
              await backpressureController.shouldProceed(priority: 5);
          highPriorityResults.add(highResult.shouldProceed);

          // 低优先级任务
          final lowResult =
              await backpressureController.shouldProceed(priority: 1);
          lowPriorityResults.add(lowResult.shouldProceed);
        }

        // 高优先级任务应该有更高的通过率
        final highPassRate = highPriorityResults.where((r) => r).length /
            highPriorityResults.length;
        final lowPassRate = lowPriorityResults.where((r) => r).length /
            lowPriorityResults.length;

        expect(highPassRate, greaterThanOrEqualTo(lowPassRate));
      });

      test('should handle queue overflow gracefully', () async {
        await backpressureController.applyStrategy(BackpressureStrategy(
          type: BackpressureStrategyType.queue_based,
          throttleRate: 0.3,
          maxQueueSize: 5, // 很小的队列
          priorityLevels: 3,
        ));

        var rejectedCount = 0;
        var acceptedCount = 0;

        for (int i = 0; i < 20; i++) {
          final result = await backpressureController.shouldProceed();
          if (result.shouldProceed) {
            acceptedCount++;
          } else {
            if (result.rejected) {
              rejectedCount++;
            }
          }
        }

        expect(rejectedCount, greaterThan(0));
        expect(acceptedCount, greaterThan(0));
      });
    });

    group('Adaptive Control Tests', () {
      test('should adapt strategy based on real-time metrics', () async {
        var iteration = 0;

        await backpressureController.startAdaptiveControl();

        // 模拟变化的系统条件
        Timer.periodic(Duration(milliseconds: 100), (_) {
          iteration++;
          final memoryPressure = 0.3 + (iteration % 10) * 0.05;

          when(mockMemoryManager.getMemoryInfo()).thenReturn(
            MemoryInfo(
              totalMemoryMB: 8192,
              availableMemoryMB: (8192 * (1 - memoryPressure)).round(),
              cachedMemoryMB: 2048,
              pressureScore: memoryPressure,
              timestamp: DateTime.now(),
            ),
          );
        });

        await Future.delayed(Duration(milliseconds: 1000));

        final finalStrategy = backpressureController.currentStrategy;
        expect(finalStrategy, isNotNull);

        await backpressureController.stopAdaptiveControl();
      });

      test('should learn from strategy effectiveness', () async {
        final effectivenessHistory = <StrategyPerformance>[];

        // 模拟策略效果反馈
        for (int i = 0; i < 5; i++) {
          final strategy = BackpressureStrategy(
            type: BackpressureStrategyType
                .values[i % BackpressureStrategyType.values.length],
            throttleRate: 0.5 + (i * 0.1),
            maxQueueSize: 100 + (i * 20),
            priorityLevels: 3,
          );

          await backpressureController.applyStrategy(strategy);

          // 模拟策略执行效果
          await Future.delayed(Duration(milliseconds: 100));

          final effectiveness = 0.5 + (math.Random().nextDouble() * 0.4);
          final impact = 0.2 + (math.Random().nextDouble() * 0.3);

          effectivenessHistory.add(StrategyPerformance(
            strategyType: strategy.type,
            appliedAt: DateTime.now().subtract(Duration(milliseconds: 100)),
            duration: Duration(milliseconds: 100),
            effectiveness: effectiveness,
            systemImpact: impact,
          ));
        }

        await backpressureController
            .updateStrategyHistory(effectivenessHistory);

        final recommendations =
            backpressureController.getStrategyRecommendations();
        expect(recommendations.length, greaterThan(0));
      });

      test('should handle strategy transitions smoothly', () async {
        final strategies = [
          BackpressureStrategy(
            type: BackpressureStrategyType.disabled,
            throttleRate: 1.0,
            maxQueueSize: 1000,
            priorityLevels: 5,
          ),
          BackpressureStrategy(
            type: BackpressureStrategyType.conservative,
            throttleRate: 0.7,
            maxQueueSize: 500,
            priorityLevels: 4,
          ),
          BackpressureStrategy(
            type: BackpressureStrategyType.aggressive,
            throttleRate: 0.3,
            maxQueueSize: 100,
            priorityLevels: 2,
          ),
        ];

        var transitionCount = 0;

        for (final strategy in strategies) {
          await backpressureController.applyStrategy(strategy);

          // 验证策略应用
          final currentStrategy = backpressureController.currentStrategy;
          expect(currentStrategy.type, equals(strategy.type));

          transitionCount++;
          await Future.delayed(Duration(milliseconds: 50));
        }

        expect(transitionCount, equals(3));
      });
    });

    group('Monitoring and Metrics Tests', () {
      test('should provide comprehensive backpressure metrics', () async {
        await backpressureController.applyStrategy(BackpressureStrategy(
          type: BackpressureStrategyType.throttling,
          throttleRate: 0.6,
          maxQueueSize: 200,
          priorityLevels: 3,
        ));

        // 生成一些背压控制活动
        for (int i = 0; i < 50; i++) {
          await backpressureController.shouldProceed();
          await Future.delayed(Duration(microseconds: 100));
        }

        final metrics = backpressureController.getMetrics();

        expect(metrics.totalRequests, greaterThan(0));
        expect(metrics.acceptedRequests, greaterThan(0));
        expect(metrics.rejectedRequests, greaterThanOrEqualTo(0));
        expect(metrics.averageQueueSize, greaterThanOrEqualTo(0));
        expect(metrics.throttlingRate, lessThanOrEqualTo(1.0));
        expect(metrics.strategyTransitions, greaterThanOrEqualTo(0));
      });

      test('should track strategy performance over time', () async {
        final startTime = DateTime.now();

        for (int i = 0; i < 3; i++) {
          final strategy = BackpressureStrategy(
            type: BackpressureStrategyType.values[i % 3],
            throttleRate: 0.5 + (i * 0.2),
            maxQueueSize: 100 + (i * 50),
            priorityLevels: 3,
          );

          await backpressureController.applyStrategy(strategy);
          await Future.delayed(Duration(milliseconds: 200));
        }

        final performanceHistory =
            backpressureController.getPerformanceHistory();

        expect(performanceHistory.length, greaterThan(0));
        expect(performanceHistory.every((p) => p.appliedAt.isAfter(startTime)),
            isTrue);
        expect(performanceHistory.every((p) => p.effectiveness >= 0), isTrue);
        expect(performanceHistory.every((p) => p.systemImpact >= 0), isTrue);
      });

      test('should detect abnormal backpressure patterns', () async {
        // 模拟频繁的策略切换
        for (int i = 0; i < 20; i++) {
          final strategy = BackpressureStrategy(
            type: BackpressureStrategyType
                .values[i % BackpressureStrategyType.values.length],
            throttleRate: math.Random().nextDouble(),
            maxQueueSize: 100 + math.Random().nextInt(400),
            priorityLevels: 3,
          );

          await backpressureController.applyStrategy(strategy);
          await Future.delayed(Duration(milliseconds: 10));
        }

        final abnormalities = backpressureController.detectAbnormalPatterns();

        expect(abnormalities.length, greaterThan(0));
        expect(
            abnormalities.any((abnormal) =>
                abnormal.type.contains('frequent_switching') ||
                abnormal.type.contains('instability')),
            isTrue);
      });
    });

    group('Integration Tests', () {
      test('should integrate with memory manager correctly', () async {
        when(mockMemoryManager.getMemoryInfo()).thenReturn(
          MemoryInfo(
            totalMemoryMB: 8192,
            availableMemoryMB: 1024,
            cachedMemoryMB: 6000,
            pressureScore: 0.85,
            timestamp: DateTime.now(),
          ),
        );

        await backpressureController.startAdaptiveControl();

        var pauseCount = 0;
        final startTime = DateTime.now();

        for (int i = 0; i < 20; i++) {
          final result = await backpressureController.shouldProceed();
          if (!result.shouldProceed) {
            pauseCount++;
          }
          await Future.delayed(Duration(milliseconds: 10));
        }

        final totalTime = DateTime.now().difference(startTime);

        expect(pauseCount, greaterThan(0));
        expect(totalTime.inMilliseconds, greaterThan(200)); // 由于背压控制，时间应该更长

        await backpressureController.stopAdaptiveControl();
      });

      test('should integrate with memory pressure monitor', () async {
        when(mockMemoryMonitor.currentPressureLevel).thenReturn(
          MemoryPressureLevel.critical,
        );

        await backpressureController.startAdaptiveControl();

        final results = <bool>[];
        for (int i = 0; i < 10; i++) {
          final result = await backpressureController.shouldProceed();
          results.add(result.shouldProceed);
        }

        // 在临界压力下，应该有更多的拒绝
        final rejectRate =
            1 - (results.where((r) => r).length / results.length);
        expect(rejectRate, greaterThan(0.3));

        await backpressureController.stopAdaptiveControl();
      });

      test('should integrate with device performance detector', () async {
        when(mockDeviceDetector.getDeviceInfo()).thenReturn(
          DeviceInfo(
            performanceScore: 20, // 低性能设备
            memoryInfo: MemoryInfo(
              totalMemoryMB: 4096,
              availableMemoryMB: 512,
              cachedMemoryMB: 3000,
              pressureScore: 0.9,
              timestamp: DateTime.now(),
            ),
          ),
        );

        await backpressureController.startAdaptiveControl();

        final strategy = backpressureController.currentStrategy;
        expect(
            strategy.type,
            anyOf([
              equals(BackpressureStrategyType.aggressive),
              equals(BackpressureStrategyType.conservative),
            ]));

        await backpressureController.stopAdaptiveControl();
      });
    });

    group('Error Handling and Recovery Tests', () {
      test('should handle memory manager errors gracefully', () async {
        when(mockMemoryManager.getMemoryInfo()).thenThrow(
          Exception('Memory manager error'),
        );

        // 应该使用默认行为继续工作
        final result = await backpressureController.shouldProceed();
        expect(result.shouldProceed, isTrue);
      });

      test('should handle monitor errors gracefully', () async {
        when(mockMemoryMonitor.currentPressureLevel).thenThrow(
          Exception('Memory monitor error'),
        );

        await backpressureController.startAdaptiveControl();

        final result = await backpressureController.shouldProceed();
        expect(result.shouldProceed, isTrue); // 默认允许继续

        await backpressureController.stopAdaptiveControl();
      });

      test('should handle device detector errors gracefully', () async {
        when(mockDeviceDetector.getDeviceInfo()).thenThrow(
          Exception('Device detector error'),
        );

        final pressure = await backpressureController.detectPressure();
        expect(pressure.cpuPressure, greaterThan(0)); // 使用默认值
      });

      test('should recover from strategy application failures', () async {
        // 尝试应用无效的策略配置
        final invalidStrategy = BackpressureStrategy(
          type: BackpressureStrategyType.throttling,
          throttleRate: -0.1, // 无效值
          maxQueueSize: 0, // 无效值
          priorityLevels: 0, // 无效值
        );

        await backpressureController.applyStrategy(invalidStrategy);

        final currentStrategy = backpressureController.currentStrategy;
        expect(currentStrategy.throttleRate, greaterThanOrEqualTo(0));
        expect(currentStrategy.maxQueueSize, greaterThan(0));
        expect(currentStrategy.priorityLevels, greaterThan(0));
      });
    });

    group('Configuration and Customization Tests', () {
      test('should respect custom configuration', () async {
        final customConfig = BackpressureControllerConfig(
          memoryThreshold: 0.8,
          cpuThreshold: 0.7,
          ioThreshold: 0.6,
          adaptiveWindowSize: Duration(minutes: 10),
          strategyEvaluationInterval: Duration(seconds: 5),
          enableAdaptiveStrategy: true,
          enableLearningMode: true,
          maxHistorySize: 100,
        );

        final customController = BackpressureController(
          memoryManager: mockMemoryManager,
          memoryMonitor: mockMemoryMonitor,
          deviceDetector: mockDeviceDetector,
          config: customConfig,
        );

        await customController.initialize();

        expect(customController.configuration.memoryThreshold, equals(0.8));
        expect(customController.configuration.cpuThreshold, equals(0.7));

        await customController.dispose();
      });

      test('should support custom strategy selection logic', () async {
        final customSelector = (SystemPressure pressure) {
          if (pressure.memoryPressure > 0.8) {
            return BackpressureStrategyType.aggressive;
          } else if (pressure.overallPressure > 0.5) {
            return BackpressureStrategyType.conservative;
          }
          return BackpressureStrategyType.disabled;
        };

        final customController = BackpressureController(
          memoryManager: mockMemoryManager,
          strategySelector: customSelector,
        );

        await customController.initialize();

        when(mockMemoryManager.getMemoryInfo()).thenReturn(
          MemoryInfo(
            totalMemoryMB: 8192,
            availableMemoryMB: 512,
            cachedMemoryMB: 7000,
            pressureScore: 0.9,
            timestamp: DateTime.now(),
          ),
        );

        final pressure = await customController.detectPressure();
        final strategy = await customController.selectStrategy(pressure);

        expect(strategy.type, equals(BackpressureStrategyType.aggressive));

        await customController.dispose();
      });
    });
  });
}
