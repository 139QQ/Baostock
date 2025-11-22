import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:jisu_fund_analyzer/src/core/performance/processors/smart_batch_processor.dart';
import 'package:jisu_fund_analyzer/src/core/performance/monitors/device_performance_detector.dart';
import 'package:jisu_fund_analyzer/src/core/performance/managers/advanced_memory_manager.dart';
import 'package:jisu_fund_analyzer/src/core/performance/processors/backpressure_controller.dart';
import 'package:jisu_fund_analyzer/src/core/utils/logger.dart';
import '../performance_test_base.dart';

/// 智能批次处理器测试
@GenerateMocks(
    [DeviceCapabilityDetector, AdvancedMemoryManager, BackpressureController])
void main() {
  group('SmartBatchProcessor Tests', () {
    late SmartBatchProcessor<String> batchProcessor;
    late MockDeviceCapabilityDetector mockDeviceDetector;
    late MockAdvancedMemoryManager mockMemoryManager;
    late MockBackpressureController mockBackpressureController;
    late PerformanceTestBase testBase;

    setUp(() async {
      testBase = PerformanceTestBase();
      await testBase.setUp();

      mockDeviceDetector =
          testBase.mockDeviceDetector as MockDeviceCapabilityDetector;
      mockMemoryManager =
          testBase.mockMemoryManager as MockAdvancedMemoryManager;
      mockBackpressureController = testBase.backpressureController;

      batchProcessor = SmartBatchProcessor<String>(
        deviceDetector: mockDeviceDetector,
        memoryManager: mockMemoryManager,
        backpressureController: mockBackpressureController,
      );

      await batchProcessor.initialize();
    });

    tearDown(() async {
      await batchProcessor.dispose();
      await testBase.tearDown();
    });

    group('Initialization Tests', () {
      test('should initialize successfully', () async {
        expect(batchProcessor.isInitialized, isTrue);
        expect(batchProcessor.currentBatchSize, greaterThan(0));
      });

      test('should configure batch size based on device capability', () async {
        // 模拟高性能设备
        when(mockDeviceDetector.getDeviceInfo()).thenReturn(
          DeviceInfo(
            performanceScore: 90,
            memoryInfo: MemoryInfo(
              totalMemoryMB: 16384,
              availableMemoryMB: 12288,
              cachedMemoryMB: 2048,
              pressureScore: 0.2,
              timestamp: DateTime.now(),
            ),
          ),
        );

        final highPerformanceProcessor = SmartBatchProcessor<String>(
          deviceDetector: mockDeviceDetector,
          memoryManager: mockMemoryManager,
        );

        await highPerformanceProcessor.initialize();
        expect(highPerformanceProcessor.currentBatchSize, greaterThan(100));

        await highPerformanceProcessor.dispose();
      });

      test('should handle memory pressure and adjust batch size', () async {
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

        final memoryConstrainedProcessor = SmartBatchProcessor<String>(
          deviceDetector: mockDeviceDetector,
          memoryManager: mockMemoryManager,
        );

        await memoryConstrainedProcessor.initialize();
        expect(memoryConstrainedProcessor.currentBatchSize, lessThan(100));

        await memoryConstrainedProcessor.dispose();
      });
    });

    group('Batch Processing Tests', () {
      test('should process items in batches correctly', () async {
        final items = testBase.generateTestBatchData(50);
        final processedItems = <String>[];
        int batchCount = 0;

        await batchProcessor.processBatches(
          items,
          (batch) async {
            processedItems.addAll(batch);
            batchCount++;
          },
        );

        expect(processedItems.length, equals(items.length));
        expect(processedItems, unorderedEquals(items));
        expect(batchCount, greaterThan(1)); // 应该分成多个批次
      });

      test('should handle empty input gracefully', () async {
        final processedItems = <String>[];

        await batchProcessor.processBatches<String>(
          [],
          (batch) async {
            processedItems.addAll(batch);
          },
        );

        expect(processedItems.isEmpty, isTrue);
      });

      test('should handle single batch processing', () async {
        final items = testBase.generateTestBatchData(10);
        final processedItems = <String>[];
        int batchCount = 0;

        await batchProcessor.processBatches(
          items,
          (batch) async {
            processedItems.addAll(batch);
            batchCount++;
          },
        );

        expect(processedItems.length, equals(items.length));
        expect(processedItems, unorderedEquals(items));
        expect(batchCount, equals(1)); // 应该只有一个批次
      });

      test('should adapt batch size during processing', () async {
        final items = testBase.generateTestBatchData(100);
        final batchSizes = <int>[];
        var currentBatchIndex = 0;

        // 模拟内存压力变化
        when(mockMemoryManager.getMemoryInfo()).thenAnswer((_) {
          if (currentBatchIndex < 3) {
            return MemoryInfo(
              totalMemoryMB: 8192,
              availableMemoryMB: 4096,
              cachedMemoryMB: 2048,
              pressureScore: 0.3,
              timestamp: DateTime.now(),
            );
          } else {
            // 后续批次模拟内存压力增加
            return MemoryInfo(
              totalMemoryMB: 8192,
              availableMemoryMB: 2048,
              cachedMemoryMB: 4096,
              pressureScore: 0.7,
              timestamp: DateTime.now(),
            );
          }
        });

        await batchProcessor.processBatches(
          items,
          (batch) async {
            batchSizes.add(batch.length);
            currentBatchIndex++;
          },
        );

        // 后续批次应该变小（由于内存压力增加）
        expect(batchSizes.length, greaterThan(1));
        if (batchSizes.length > 3) {
          expect(batchSizes[3], lessThanOrEqualTo(batchSizes[0]));
        }
      });

      test('should handle batch processing errors gracefully', () async {
        final items = testBase.generateTestBatchData(30);
        final processedItems = <String>[];
        var errorCount = 0;

        await batchProcessor.processBatches(
          items,
          (batch) async {
            if (batch.contains('test_5')) {
              errorCount++;
              throw Exception('模拟处理错误');
            }
            processedItems.addAll(batch);
          },
        );

        expect(processedItems.length, lessThan(items.length));
        expect(errorCount, greaterThan(0));
      });

      test('should retry failed batches when configured', () async {
        final items = testBase.generateTestBatchData(20);
        final processedItems = <String>[];
        var retryCount = 0;

        final retryConfig = BatchProcessingConfig(
          maxRetries: 3,
          retryDelay: Duration(milliseconds: 10),
          enableRetry: true,
        );

        await batchProcessor.processBatches(
          items,
          (batch) async {
            if (batch.contains('test_5') && retryCount < 2) {
              retryCount++;
              throw Exception('可重试错误');
            }
            processedItems.addAll(batch);
          },
          config: retryConfig,
        );

        expect(processedItems.length, equals(items.length));
        expect(retryCount, greaterThan(0));
      });
    });

    group('Performance Optimization Tests', () {
      test('should optimize batch size based on throughput', () async {
        final items = testBase.generateTestBatchData(200);
        var totalProcessingTime = 0;

        // 第一次处理
        final stopwatch1 = Stopwatch()..start();
        await batchProcessor.processBatches(
          items,
          (batch) async {
            // 模拟处理时间
            await Future.delayed(Duration(milliseconds: batch.length ~/ 10));
          },
        );
        stopwatch1.stop();
        totalProcessingTime = stopwatch1.elapsedMilliseconds;

        // 获取推荐的批次大小
        final recommendedSize = batchProcessor.getRecommendedBatchSize();
        expect(recommendedSize, greaterThan(0));

        // 使用推荐大小再次处理
        final optimizedProcessor = SmartBatchProcessor<String>(
          deviceDetector: mockDeviceDetector,
          memoryManager: mockMemoryManager,
          initialBatchSize: recommendedSize,
        );

        await optimizedProcessor.initialize();

        final stopwatch2 = Stopwatch()..start();
        await optimizedProcessor.processBatches(
          items,
          (batch) async {
            await Future.delayed(Duration(milliseconds: batch.length ~/ 10));
          },
        );
        stopwatch2.stop();

        // 优化后的处理应该更快或相似
        expect(stopwatch2.elapsedMilliseconds,
            lessThanOrEqualTo(totalProcessingTime + 100));

        await optimizedProcessor.dispose();
      });

      test('should handle high-frequency processing efficiently', () async {
        final iterations = 50;
        final itemsPerIteration = 10;
        var totalItems = 0;

        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < iterations; i++) {
          final items = testBase.generateTestBatchData(itemsPerIteration,
              prefix: 'hf_$i');

          await batchProcessor.processBatches(
            items,
            (batch) async {
              totalItems += batch.length;
              // 模拟快速处理
              await Future.delayed(Duration(microseconds: 100));
            },
          );
        }

        stopwatch.stop();

        expect(totalItems, equals(iterations * itemsPerIteration));
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // 应该在5秒内完成

        // 平均每次处理时间应该很短
        final avgTimePerIteration = stopwatch.elapsedMicroseconds / iterations;
        expect(avgTimePerIteration, lessThan(100000)); // 小于100毫秒
      });

      test('should adapt to different item processing complexities', () async {
        final simpleItems =
            testBase.generateTestBatchData(50, prefix: 'simple');
        final complexItems =
            testBase.generateTestBatchData(50, prefix: 'complex');

        // 简单处理
        final simpleStopwatch = Stopwatch()..start();
        await batchProcessor.processBatches(
          simpleItems,
          (batch) async {
            await Future.delayed(Duration(microseconds: 50)); // 很短的处理时间
          },
        );
        simpleStopwatch.stop();

        // 复杂处理
        final complexStopwatch = Stopwatch()..start();
        await batchProcessor.processBatches(
          complexItems,
          (batch) async {
            await Future.delayed(Duration(milliseconds: 10)); // 较长的处理时间
          },
        );
        complexStopwatch.stop();

        // 复杂处理应该耗时更长
        expect(complexStopwatch.elapsedMilliseconds,
            greaterThan(simpleStopwatch.elapsedMilliseconds));

        // 批次大小应该根据处理复杂度调整
        final metrics = batchProcessor.getPerformanceMetrics();
        expect(metrics.averageProcessingTime, greaterThan(0));
      });
    });

    group('Memory and Backpressure Tests', () {
      test('should respect backpressure signals', () async {
        final items = testBase.generateTestBatchData(100);
        final processedItems = <String>[];
        var pauseCount = 0;

        // 模拟背压控制器信号
        when(mockBackpressureController.shouldPause()).thenAnswer((_) {
          pauseCount++;
          return pauseCount <= 2; // 前几次暂停
        });

        when(mockBackpressureController.canProceed()).thenAnswer((_) {
          return pauseCount > 2; // 后续允许继续
        });

        await batchProcessor.processBatches(
          items,
          (batch) async {
            processedItems.addAll(batch);
          },
        );

        expect(processedItems.length, equals(items.length));
        expect(pauseCount, greaterThan(0));
      });

      test('should handle memory pressure by adjusting batch size', () async {
        final items = testBase.generateTestBatchData(80);
        var adjustmentCount = 0;

        // 模拟内存压力增加
        when(mockMemoryManager.getMemoryInfo()).thenAnswer((_) {
          adjustmentCount++;
          return MemoryInfo(
            totalMemoryMB: 8192,
            availableMemoryMB: math.max(512, 4096 - (adjustmentCount * 500)),
            cachedMemoryMB: 3000 + (adjustmentCount * 200),
            pressureScore: math.min(0.95, 0.3 + (adjustmentCount * 0.1)),
            timestamp: DateTime.now(),
          );
        });

        var batchSizeHistory = <int>[];
        await batchProcessor.processBatches(
          items,
          (batch) async {
            batchSizeHistory.add(batch.length);
          },
        );

        // 后续批次应该变小
        if (batchSizeHistory.length > 2) {
          expect(
              batchSizeHistory.last, lessThanOrEqualTo(batchSizeHistory.first));
        }
      });

      test('should maintain memory efficiency during large processing',
          () async {
        final largeItems = testBase.generateTestBatchData(1000);
        var maxMemoryUsage = 0.0;

        // 监控内存使用
        final memoryMonitor = Timer.periodic(Duration(milliseconds: 100), (_) {
          final memoryInfo = mockMemoryManager.getMemoryInfo();
          maxMemoryUsage = math.max(maxMemoryUsage, memoryInfo.pressureScore);
        });

        await batchProcessor.processBatches(
          largeItems,
          (batch) async {
            // 模拟内存密集型处理
            final tempData =
                List.generate(batch.length * 10, (_) => 'temp_data');
            await Future.delayed(Duration(microseconds: 100));
          },
        );

        memoryMonitor.cancel();

        // 内存压力应该保持在合理范围内
        expect(maxMemoryUsage, lessThan(0.9));
      });
    });

    group('Concurrent Processing Tests', () {
      test('should handle concurrent batch processing', () async {
        final concurrentTasks = 5;
        final itemsPerTask = 20;
        final futures = <Future<void>>[];
        var totalProcessedItems = 0;

        for (int i = 0; i < concurrentTasks; i++) {
          final items = testBase.generateTestBatchData(itemsPerTask,
              prefix: 'concurrent_$i');

          futures.add(
            batchProcessor.processBatches(
              items,
              (batch) async {
                totalProcessedItems += batch.length;
                await Future.delayed(Duration(milliseconds: batch.length));
              },
            ),
          );
        }

        await Future.wait(futures);

        expect(totalProcessedItems, equals(concurrentTasks * itemsPerTask));
      });

      test('should isolate batch processing contexts', () async {
        final processor1 = SmartBatchProcessor<String>(
          deviceDetector: mockDeviceDetector,
          memoryManager: mockMemoryManager,
        );

        final processor2 = SmartBatchProcessor<String>(
          deviceDetector: mockDeviceDetector,
          memoryManager: mockMemoryManager,
        );

        await Future.wait([
          processor1.initialize(),
          processor2.initialize(),
        ]);

        final items1 = testBase.generateTestBatchData(30, prefix: 'p1');
        final items2 = testBase.generateTestBatchData(40, prefix: 'p2');

        final results = await testBase.measureConcurrentPerformance(
          operations: [
            () => processor1.processBatches(items1, (batch) async {
                  await Future.delayed(Duration(milliseconds: 10));
                }),
            () => processor2.processBatches(items2, (batch) async {
                  await Future.delayed(Duration(milliseconds: 10));
                }),
          ],
        );

        expect(results.length, equals(2));

        await Future.wait([
          processor1.dispose(),
          processor2.dispose(),
        ]);
      });
    });

    group('Metrics and Monitoring Tests', () {
      test('should provide comprehensive performance metrics', () async {
        final items = testBase.generateTestBatchData(100);
        var expectedTotalBatches = 0;

        await batchProcessor.processBatches(
          items,
          (batch) async {
            expectedTotalBatches++;
            await Future.delayed(Duration(milliseconds: batch.length ~/ 10));
          },
        );

        final metrics = batchProcessor.getPerformanceMetrics();

        expect(metrics.totalBatches, equals(expectedTotalBatches));
        expect(metrics.totalItemsProcessed, equals(items.length));
        expect(metrics.averageProcessingTime, greaterThan(0));
        expect(metrics.averageBatchSize, greaterThan(0));
        expect(metrics.memoryEfficiency, greaterThan(0));
        expect(metrics.throughput, greaterThan(0));
      });

      test('should track processing trends over time', () async {
        final processingRounds = 5;
        final itemsPerRound = 20;

        for (int round = 0; round < processingRounds; round++) {
          final items = testBase.generateTestBatchData(itemsPerRound,
              prefix: 'round_$round');

          await batchProcessor.processBatches(
            items,
            (batch) async {
              await Future.delayed(Duration(milliseconds: 5));
            },
          );
        }

        final trends = batchProcessor.getProcessingTrends();

        expect(trends.length, greaterThan(0));
        expect(
            trends.every((trend) => trend.timestamp.isBefore(DateTime.now())),
            isTrue);
        expect(trends.every((trend) => trend.batchSize > 0), isTrue);
      });

      test('should provide optimization recommendations', () async {
        final items = testBase.generateTestBatchData(200);

        await batchProcessor.processBatches(
          items,
          (batch) async {
            await Future.delayed(Duration(milliseconds: batch.length ~/ 20));
          },
        );

        final recommendations = batchProcessor.getOptimizationRecommendations();

        expect(recommendations.length, greaterThan(0));
        expect(recommendations.every((rec) => rec.type.isNotEmpty), isTrue);
        expect(recommendations.every((rec) => rec.priority > 0), isTrue);
      });
    });

    group('Error Handling and Recovery Tests', () {
      test('should handle device detector errors gracefully', () async {
        when(mockDeviceDetector.getDeviceInfo()).thenThrow(
          Exception('Device detector error'),
        );

        final items = testBase.generateTestBatchData(30);
        final processedItems = <String>[];

        // 应该使用默认配置继续处理
        await batchProcessor.processBatches(
          items,
          (batch) async {
            processedItems.addAll(batch);
          },
        );

        expect(processedItems.length, equals(items.length));
      });

      test('should handle memory manager errors gracefully', () async {
        when(mockMemoryManager.getMemoryInfo()).thenThrow(
          Exception('Memory manager error'),
        );

        final items = testBase.generateTestBatchData(30);

        // 应该使用默认内存配置继续处理
        expect(
            () async => await batchProcessor.processBatches(
                  items,
                  (batch) async {
                    await Future.delayed(Duration(microseconds: 100));
                  },
                ),
            returnsNormally);
      });

      test('should handle backpressure controller errors gracefully', () async {
        when(mockBackpressureController.shouldPause()).thenThrow(
          Exception('Backpressure controller error'),
        );

        final items = testBase.generateTestBatchData(30);

        // 应该忽略错误的背压信号继续处理
        expect(
            () async => await batchProcessor.processBatches(
                  items,
                  (batch) async {
                    await Future.delayed(Duration(microseconds: 100));
                  },
                ),
            returnsNormally);
      });

      test('should handle batch processing timeouts', () async {
        final timeoutConfig = BatchProcessingConfig(
          batchTimeout: Duration(milliseconds: 10),
          enableTimeout: true,
        );

        final items = testBase.generateTestBatchData(20);
        final processedItems = <String>[];
        var timeoutCount = 0;

        await batchProcessor.processBatches(
          items,
          (batch) async {
            try {
              if (batch.contains('test_10')) {
                await Future.delayed(Duration(milliseconds: 50)); // 超时的处理
              }
              processedItems.addAll(batch);
            } catch (e) {
              if (e.toString().contains('timeout')) {
                timeoutCount++;
              }
              rethrow;
            }
          },
          config: timeoutConfig,
        );

        expect(timeoutCount, greaterThan(0));
      });
    });

    group('Configuration and Customization Tests', () {
      test('should respect custom configuration', () async {
        final customConfig = BatchProcessingConfig(
          initialBatchSize: 50,
          minBatchSize: 5,
          maxBatchSize: 200,
          adjustmentStep: 5,
          enableAdaptiveSizing: true,
          enableMemoryOptimization: true,
          enableThroughputOptimization: true,
          enableBackpressureAware: true,
          adjustmentInterval: Duration(seconds: 1),
          performanceWindow: Duration(minutes: 5),
        );

        final customProcessor = SmartBatchProcessor<String>(
          deviceDetector: mockDeviceDetector,
          memoryManager: mockMemoryManager,
          config: customConfig,
        );

        await customProcessor.initialize();

        expect(customProcessor.currentBatchSize, equals(50));

        final items = testBase.generateTestBatchData(100);
        await customProcessor.processBatches(
          items,
          (batch) async {
            await Future.delayed(Duration(microseconds: 50));
          },
        );

        await customProcessor.dispose();
      });

      test('should support custom processing strategies', () async {
        final strategy = CustomProcessingStrategy<String>(
          shouldIncreaseBatchSize: (metrics) =>
              metrics.averageProcessingTime < 50,
          shouldDecreaseBatchSize: (metrics) =>
              metrics.averageProcessingTime > 200,
          calculateOptimalSize: (metrics) => math.min(
              200, math.max(10, 100 - metrics.averageProcessingTime ~/ 2)),
        );

        final customProcessor = SmartBatchProcessor<String>(
          deviceDetector: mockDeviceDetector,
          memoryManager: mockMemoryManager,
          customStrategy: strategy,
        );

        await customProcessor.initialize();

        final items = testBase.generateTestBatchData(80);
        await customProcessor.processBatches(
          items,
          (batch) async {
            await Future.delayed(Duration(milliseconds: 25));
          },
        );

        await customProcessor.dispose();
      });
    });
  });
}

/// 自定义处理策略
class CustomProcessingStrategy<T> {
  final bool Function(BatchProcessingMetrics) shouldIncreaseBatchSize;
  final bool Function(BatchProcessingMetrics) shouldDecreaseBatchSize;
  final int Function(BatchProcessingMetrics) calculateOptimalSize;

  const CustomProcessingStrategy({
    required this.shouldIncreaseBatchSize,
    required this.shouldDecreaseBatchSize,
    required this.calculateOptimalSize,
  });
}
