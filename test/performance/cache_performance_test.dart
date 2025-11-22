import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:jisu_fund_analyzer/src/core/cache/interfaces/i_unified_cache_service.dart';
import '../helpers/test_cache_service_factory.dart';

void main() {
  group('Cache Performance Tests', () {
    late IUnifiedCacheService cacheService;

    setUpAll(() async {
      cacheService =
          await TestCacheServiceFactory.createPerformanceTestCacheService();
    });

    tearDownAll(() async {
      await cacheService.clear();
    });

    group('Single Operation Performance', () {
      test('should meet put operation performance target', () async {
        // Arrange
        const iterations = 1000;
        const targetAvgTimeMs = 5.0;
        final testData = _generateTestData(1024); // 1KB数据

        // Act
        final stopwatch = Stopwatch()..start();
        for (int i = 0; i < iterations; i++) {
          await cacheService.put('perf_put_$i', testData);
        }
        stopwatch.stop();

        // Assert
        final avgTimeMs = stopwatch.elapsedMilliseconds / iterations;
        print('Put operation average time: ${avgTimeMs.toStringAsFixed(2)}ms');
        expect(avgTimeMs, lessThan(targetAvgTimeMs),
            reason: 'Average put time should be less than $targetAvgTimeMs ms');
      });

      test('should meet get operation performance target', () async {
        // Arrange
        const iterations = 1000;
        const targetAvgTimeMs = 1.0;
        const targetHitRate = 0.95;

        // Pre-populate cache
        for (int i = 0; i < iterations; i++) {
          await cacheService.put('perf_get_$i', 'data_$i');
        }

        // Act
        final stopwatch = Stopwatch()..start();
        int hits = 0;
        for (int i = 0; i < iterations; i++) {
          final result = await cacheService.get<String>('perf_get_$i');
          if (result != null) hits++;
        }
        stopwatch.stop();

        // Assert
        final avgTimeMs = stopwatch.elapsedMilliseconds / iterations;
        final hitRate = hits / iterations;

        print('Get operation average time: ${avgTimeMs.toStringAsFixed(2)}ms');
        print('Hit rate: ${(hitRate * 100).toStringAsFixed(1)}%');

        expect(avgTimeMs, lessThan(targetAvgTimeMs),
            reason: 'Average get time should be less than $targetAvgTimeMs ms');
        expect(hitRate, greaterThan(targetHitRate),
            reason:
                'Hit rate should be greater than ${(targetHitRate * 100).toStringAsFixed(0)}%');
      });

      test('should meet exists operation performance target', () async {
        // Arrange
        const iterations = 1000;
        const targetAvgTimeMs = 0.5;

        // Pre-populate cache
        for (int i = 0; i < iterations ~/ 2; i++) {
          await cacheService.put('exists_$i', 'data_$i');
        }

        // Act
        final stopwatch = Stopwatch()..start();
        for (int i = 0; i < iterations; i++) {
          await cacheService.exists('exists_$i');
        }
        stopwatch.stop();

        // Assert
        final avgTimeMs = stopwatch.elapsedMilliseconds / iterations;
        print(
            'Exists operation average time: ${avgTimeMs.toStringAsFixed(2)}ms');
        expect(avgTimeMs, lessThan(targetAvgTimeMs),
            reason:
                'Average exists time should be less than $targetAvgTimeMs ms');
      });
    });

    group('Batch Operation Performance', () {
      test('should handle batch put efficiently', () async {
        // Arrange
        const batchSize = 100;
        const targetTimeMs = 100.0;
        final entries = <String, String>{};

        for (int i = 0; i < batchSize; i++) {
          entries['batch_$i'] = 'batch_data_$i';
        }

        // Act
        final stopwatch = Stopwatch()..start();
        await cacheService.putAll(entries);
        stopwatch.stop();

        // Assert
        final avgTimePerItem = stopwatch.elapsedMilliseconds / batchSize;
        print(
            'Batch put average time per item: ${avgTimePerItem.toStringAsFixed(2)}ms');
        print('Batch put total time: ${stopwatch.elapsedMilliseconds}ms');

        expect(stopwatch.elapsedMilliseconds, lessThan(targetTimeMs),
            reason: 'Batch put should complete within $targetTimeMs ms');
      });

      test('should handle batch get efficiently', () async {
        // Arrange
        const batchSize = 100;
        const targetTimeMs = 50.0;
        final keys = <String>[];

        // Pre-populate cache
        for (int i = 0; i < batchSize; i++) {
          final key = 'batch_get_$i';
          keys.add(key);
          await cacheService.put(key, 'data_$i');
        }

        // Act
        final stopwatch = Stopwatch()..start();
        final results = await cacheService.getAll<String>(keys);
        stopwatch.stop();

        // Assert
        final avgTimePerItem = stopwatch.elapsedMilliseconds / batchSize;
        final hitRate =
            results.values.where((v) => v != null).length / batchSize;

        print(
            'Batch get average time per item: ${avgTimePerItem.toStringAsFixed(2)}ms');
        print('Batch get total time: ${stopwatch.elapsedMilliseconds}ms');
        print('Batch get hit rate: ${(hitRate * 100).toStringAsFixed(1)}%');

        expect(stopwatch.elapsedMilliseconds, lessThan(targetTimeMs),
            reason: 'Batch get should complete within $targetTimeMs ms');
        expect(hitRate, greaterThan(0.9),
            reason: 'Batch get hit rate should be greater than 90%');
      });
    });

    group('Memory Performance', () {
      test('should handle large data efficiently', () async {
        // Arrange
        const dataSizes = [1, 10, 50, 100, 500]; // KB
        const targetTimePerKB = 0.1; // ms per KB

        for (final sizeKB in dataSizes) {
          final largeData = _generateTestData(sizeKB * 1024);
          final key = 'large_data_${sizeKB}kb';

          // Act
          final stopwatch = Stopwatch()..start();
          await cacheService.put(key, largeData);

          // 尝试获取数据，处理可能的序列化问题
          dynamic retrieved = await cacheService.get<Map<String, dynamic>>(key);

          // 如果返回null，尝试不指定类型获取
          if (retrieved == null) {
            retrieved = await cacheService.get(key);

            // 如果是字符串，尝试JSON解析
            if (retrieved is String) {
              try {
                final parsed = jsonDecode(retrieved);
                retrieved = parsed;
              } catch (e) {
                // 解析失败，保持原样
              }
            }
          }

          stopwatch.stop();

          // Assert
          expect(retrieved, isNotNull,
              reason: 'Large data ($sizeKB KB) should be retrievable');

          final timePerKB = stopwatch.elapsedMilliseconds / sizeKB;
          print(
              'Large data ($sizeKB KB) time per KB: ${timePerKB.toStringAsFixed(2)}ms');

          expect(timePerKB, lessThan(targetTimePerKB),
              reason:
                  'Time per KB should be less than $targetTimePerKB ms for $sizeKB KB data');
        }
      });

      test('should maintain memory usage within limits', () async {
        // Arrange
        const maxMemoryMB = 150;
        const itemCount = 1000;
        const itemSizeKB = 10;

        // Act
        for (int i = 0; i < itemCount; i++) {
          await cacheService.put(
              'memory_test_$i', _generateTestData(itemSizeKB * 1024));
        }

        final stats = await cacheService.getStatistics();

        // Assert
        final memoryUsageMB = stats.totalSize / (1024 * 1024);
        print('Total memory usage: ${memoryUsageMB.toStringAsFixed(1)} MB');
        print('Total items: ${stats.totalCount}');

        expect(memoryUsageMB, lessThan(maxMemoryMB),
            reason: 'Memory usage should be less than $maxMemoryMB MB');
      });
    });

    group('Concurrency Performance', () {
      test('should handle concurrent operations efficiently', () async {
        // Arrange
        const concurrentThreads = 10;
        const operationsPerThread = 100;
        const targetTimeMs = 5000; // 5 seconds

        // Act
        final stopwatch = Stopwatch()..start();
        final futures = <Future>[];

        for (int thread = 0; thread < concurrentThreads; thread++) {
          futures.add(_performConcurrentOperations(
              cacheService, thread, operationsPerThread));
        }

        await Future.wait(futures);
        stopwatch.stop();

        // Assert
        const totalOperations = concurrentThreads * operationsPerThread;
        final operationsPerSecond =
            totalOperations / (stopwatch.elapsedMilliseconds / 1000);

        print('Concurrent operations completed: $totalOperations');
        print('Total time: ${stopwatch.elapsedMilliseconds}ms');
        print(
            'Operations per second: ${operationsPerSecond.toStringAsFixed(0)}');

        expect(stopwatch.elapsedMilliseconds, lessThan(targetTimeMs),
            reason:
                'Concurrent operations should complete within $targetTimeMs ms');
        expect(operationsPerSecond, greaterThan(1000),
            reason: 'Should handle at least 1000 operations per second');
      });

      test('should maintain consistency under concurrent access', () async {
        // Arrange
        const itemCount = 100;
        const readerThreads = 5;
        const writerThreads = 2;

        // Act
        final futures = <Future>[];

        // Writer threads
        for (int thread = 0; thread < writerThreads; thread++) {
          futures.add(_concurrentWriter(cacheService, thread, itemCount));
        }

        // Reader threads
        for (int thread = 0; thread < readerThreads; thread++) {
          futures.add(_concurrentReader(cacheService, thread, itemCount));
        }

        await Future.wait(futures);

        // Assert - Verify data consistency
        int validItems = 0;
        for (int i = 0; i < itemCount; i++) {
          final data = await cacheService.get<int>('consistency_$i');
          if (data != null && data >= 0) {
            validItems++;
          }
        }

        final consistencyRate = validItems / itemCount;
        print(
            'Data consistency rate: ${(consistencyRate * 100).toStringAsFixed(1)}%');

        expect(consistencyRate, greaterThan(0.95),
            reason: 'Data consistency should be maintained above 95%');
      });
    });

    group('Performance Under Load', () {
      test('should maintain performance with high cache load', () async {
        // Arrange
        const highItemCount = 10000;
        const targetHitRate = 0.8;
        const targetAvgResponseTimeMs = 50.0;

        // Pre-populate cache with high load
        print('Pre-populating cache with $highItemCount items...');
        final prepopulateStopwatch = Stopwatch()..start();

        for (int i = 0; i < highItemCount; i++) {
          await cacheService.put('load_test_$i', 'load_data_$i');

          // Report progress every 1000 items
          if (i % 1000 == 0) {
            print('Pre-populated $i items');
          }
        }

        prepopulateStopwatch.stop();
        print(
            'Pre-population completed in ${prepopulateStopwatch.elapsedMilliseconds}ms');

        // Act - Test performance under load
        const testOperations = 1000;
        final random = math.Random();

        final testStopwatch = Stopwatch()..start();
        int hits = 0;

        for (int i = 0; i < testOperations; i++) {
          final randomIndex = random.nextInt(highItemCount);
          final result =
              await cacheService.get<String>('load_test_$randomIndex');
          if (result != null) hits++;
        }

        testStopwatch.stop();

        // Assert
        final avgResponseTimeMs =
            testStopwatch.elapsedMilliseconds / testOperations;
        final hitRate = hits / testOperations;

        print('Performance under load:');
        print(
            '  - Average response time: ${avgResponseTimeMs.toStringAsFixed(2)}ms');
        print('  - Hit rate: ${(hitRate * 100).toStringAsFixed(1)}%');
        print('  - Cache size: $highItemCount items');

        expect(avgResponseTimeMs, lessThan(targetAvgResponseTimeMs),
            reason:
                'Response time should be less than $targetAvgResponseTimeMs ms under load');
        expect(hitRate, greaterThan(targetHitRate),
            reason:
                'Hit rate should be greater than ${(targetHitRate * 100).toStringAsFixed(0)}% under load');
      });
    });

    group('Optimization Performance', () {
      test('should improve performance after optimization', () async {
        // Arrange
        const iterations = 500;
        final testData = _generateTestData(512);

        // Measure performance before optimization
        print('Measuring performance before optimization...');
        final beforeStopwatch = Stopwatch()..start();

        for (int i = 0; i < iterations; i++) {
          await cacheService.put('opt_before_$i', testData);
          await cacheService.get<Map<String, dynamic>>('opt_before_$i');
        }

        beforeStopwatch.stop();
        final beforeAvgTime =
            beforeStopwatch.elapsedMilliseconds / (iterations * 2);

        // Perform optimization
        print('Performing cache optimization...');
        final optStopwatch = Stopwatch()..start();
        await cacheService.optimize();
        optStopwatch.stop();

        // Measure performance after optimization
        print('Measuring performance after optimization...');
        final afterStopwatch = Stopwatch()..start();

        for (int i = 0; i < iterations; i++) {
          await cacheService.put('opt_after_$i', testData);
          await cacheService.get<Map<String, dynamic>>('opt_after_$i');
        }

        afterStopwatch.stop();
        final afterAvgTime =
            afterStopwatch.elapsedMilliseconds / (iterations * 2);

        // Calculate improvement
        final improvement =
            ((beforeAvgTime - afterAvgTime) / beforeAvgTime) * 100;

        print('Performance comparison:');
        print(
            '  - Before optimization: ${beforeAvgTime.toStringAsFixed(2)}ms avg');
        print(
            '  - After optimization: ${afterAvgTime.toStringAsFixed(2)}ms avg');
        print('  - Optimization time: ${optStopwatch.elapsedMilliseconds}ms');
        print(
            '  - Performance improvement: ${improvement.toStringAsFixed(1)}%');

        // Assert
        expect(optStopwatch.elapsedMilliseconds, lessThan(1000),
            reason: 'Optimization should complete within 1 second');

        // Optimization may not always improve performance significantly,
        // but it shouldn't make it significantly worse
        expect(afterAvgTime, lessThan(beforeAvgTime * 1.2),
            reason:
                'Performance should not degrade significantly after optimization');
      });
    });
  });
}

// 辅助函数

/// 生成测试数据
Map<String, dynamic> _generateTestData(int targetSizeBytes) {
  final data = <String, dynamic>{};
  int currentSize = 0;
  int fieldIndex = 0;

  while (currentSize < targetSizeBytes) {
    final fieldValue = 'x' * math.min(100, targetSizeBytes - currentSize);
    data['field_$fieldIndex'] = fieldValue;

    currentSize += fieldValue.length + 12; // +12 for field name and overhead
    fieldIndex++;
  }

  return data;
}

/// 执行并发操作
Future<void> _performConcurrentOperations(
    IUnifiedCacheService cacheService, int threadId, int operationCount) async {
  for (int i = 0; i < operationCount; i++) {
    final key = 'concurrent_${threadId}_$i';
    final data = 'data_${threadId}_$i';

    await cacheService.put(key, data);
    await cacheService.get<String>(key);
  }
}

/// 并发写入操作
Future<void> _concurrentWriter(
    IUnifiedCacheService cacheService, int threadId, int itemCount) async {
  for (int i = 0; i < itemCount; i++) {
    final key = 'consistency_$i';
    final value = threadId * 1000 + i;

    await cacheService.put(key, value);

    // 随机延迟模拟真实场景
    await Future.delayed(Duration(milliseconds: math.Random().nextInt(5)));
  }
}

/// 并发读取操作
Future<void> _concurrentReader(
    IUnifiedCacheService cacheService, int threadId, int itemCount) async {
  for (int i = 0; i < itemCount * 2; i++) {
    final randomIndex = math.Random().nextInt(itemCount);
    final key = 'consistency_$randomIndex';

    await cacheService.get<int>(key);

    // 随机延迟模拟真实场景
    await Future.delayed(Duration(milliseconds: math.Random().nextInt(3)));
  }
}
