import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import '../../lib/src/core/services/performance/unified_performance_service.dart';
import '../../lib/src/core/services/data/unified_data_service.dart';
import '../../lib/src/core/services/base/simple_service_container.dart';
import '../../lib/src/core/services/base/i_unified_service.dart';
import '../../lib/src/core/utils/logger.dart';

// R.3 统一服务集成测试
void main() {
  // 修复：确保Flutter绑定已初始化
  TestWidgetsFlutterBinding.ensureInitialized();

  group('R.3 统一服务集成测试', () {
    late UnifiedPerformanceService performanceService;
    late UnifiedDataService dataService;
    late SimpleServiceContainer container;

    setUpAll(() async {
      // 初始化R.3统一服务
      container = SimpleServiceContainer();
      performanceService = UnifiedPerformanceService();
      dataService = UnifiedDataService();

      await performanceService.initialize(container);
      await container.registerService(performanceService);
      await dataService.initialize(container);
      await container.registerService(dataService);
    });

    tearDownAll(() async {
      // 清理资源
      await performanceService.dispose();
      await dataService.dispose();
      await container.disposeAll();
    });

    group('统一性能服务测试', () {
      test('应该能够获取当前性能指标', () async {
        final metrics = await performanceService.getCurrentPerformanceMetrics();
        expect(metrics, isNotNull);
        expect(metrics.timestamp, isNotNull);
        expect(metrics.cpuUsage, greaterThanOrEqualTo(0.0));
        expect(metrics.memoryUsage, greaterThanOrEqualTo(0.0));
      });

      test('应该能够执行性能优化', () async {
        await performanceService.optimizePerformance(aggressive: false);
        // 如果没有抛出异常，则测试通过
        expect(true, isTrue);
      });

      test('应该能够执行批处理', () async {
        final testData = [1, 2, 3, 4, 5];
        final results = await performanceService.processBatch<int>(
          testData,
          (item) async => item * 2,
        );

        expect(results, isNotNull);
        expect(results.length, equals(testData.length));
        expect(results, equals([2, 4, 6, 8, 10]));
      });

      test('应该能够压缩和解压数据', () async {
        final originalData = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

        final compressedData =
            await performanceService.compressData(originalData);
        expect(compressedData, isNotNull);

        final decompressedData =
            await performanceService.decompressData(compressedData);
        expect(decompressedData, equals(originalData));
      });

      test('应该能够检查服务健康状态', () async {
        final healthStatus = await performanceService.checkHealth();
        expect(healthStatus, isNotNull);
        expect(healthStatus.isHealthy, isTrue);
      });
    });

    group('统一数据服务测试', () {
      test('应该能够存储和获取数据', () async {
        const testKey = 'test_key';
        const testValue = 'test_value';

        await dataService.set(testKey, testValue);
        final retrievedValue = await dataService.get<String>(testKey);

        expect(retrievedValue, equals(testValue));
      });

      test('应该能够处理复杂数据对象', () async {
        const testKey = 'complex_data';
        final testValue = {
          'name': 'Test Fund',
          'code': '000001',
          'value': 1234.56,
          'timestamp': DateTime.now().toIso8601String(),
        };

        await dataService.set(testKey, testValue);
        final retrievedValue =
            await dataService.get<Map<String, dynamic>>(testKey);

        expect(retrievedValue, isNotNull);
        expect(retrievedValue!['name'], equals('Test Fund'));
        expect(retrievedValue['code'], equals('000001'));
      });

      test('应该能够懒加载数据', () async {
        const testKey = 'lazy_data';

        final loadedValue = await dataService.lazyLoad<String>(
          testKey,
          () async => 'lazy_loaded_value',
        );

        expect(loadedValue, equals('lazy_loaded_value'));

        // 第二次调用应该从缓存获取
        final cachedValue = await dataService.lazyLoad<String>(
          testKey,
          () async => 'should_not_be_called',
        );
        expect(cachedValue, equals('lazy_loaded_value'));
      });

      test('应该能够获取缓存统计信息', () async {
        final stats = await dataService.getStatistics();
        expect(stats, isNotNull);
        expect(stats.totalRequests, greaterThanOrEqualTo(0));
        expect(stats.hitRate, greaterThanOrEqualTo(0.0));
      });

      test('应该能够清理缓存', () async {
        // 先添加一些数据
        await dataService.set('temp_key1', 'temp_value1');
        await dataService.set('temp_key2', 'temp_value2');

        // 清理缓存
        await dataService.cleanup();

        // 验证清理后仍然可以正常使用
        await dataService.set('new_key', 'new_value');
        final newValue = await dataService.get<String>('new_key');
        expect(newValue, equals('new_value'));
      });
    });

    group('服务协同测试', () {
      test('应该能够协同优化性能和数据服务', () async {
        // 先获取性能基线
        final baselineMetrics =
            await performanceService.getCurrentPerformanceMetrics();

        // 批量处理数据操作
        for (int i = 0; i < 10; i++) {
          await dataService.set('batch_key_$i', 'batch_value_$i');
        }

        // 执行性能优化
        await performanceService.optimizePerformance();

        // 验证操作完成
        for (int i = 0; i < 10; i++) {
          final value = await dataService.get<String>('batch_key_$i');
          expect(value, equals('batch_value_$i'));
        }

        // 验证性能指标更新
        final optimizedMetrics =
            await performanceService.getCurrentPerformanceMetrics();
        expect(optimizedMetrics.timestamp, isNotNull);
      });

      test('应该能够处理高负载场景', () async {
        const batchSize = 50;
        final testData = List.generate(batchSize, (index) => 'item_$index');

        // 批量处理测试
        final results = await performanceService.processBatch<String>(
          testData,
          (item) async {
            await dataService.set(item, 'processed_$item');
            return 'processed_$item';
          },
        );

        expect(results.length, equals(batchSize));

        // 验证数据正确存储
        for (final item in testData.take(5)) {
          // 只验证前5个，避免测试时间过长
          final value = await dataService.get<String>(item);
          expect(value, equals('processed_$item'));
        }
      });

      test('应该能够优雅处理错误', () async {
        try {
          // 尝试访问不存在的数据
          final nonExistentValue =
              await dataService.get<String>('non_existent_key');
          expect(nonExistentValue, isNull);

          // 尝试处理空批次
          final emptyResults = await performanceService.processBatch<String>(
            [],
            (item) async => item,
          );
          expect(emptyResults, isEmpty);

          expect(true, isTrue); // 所有错误处理测试通过
        } catch (e) {
          fail('不应该抛出异常: $e');
        }
      });
    });

    group('内存和资源管理测试', () {
      test('应该能够管理内存使用', () async {
        // 获取初始内存指标
        final initialMetrics =
            await performanceService.getCurrentPerformanceMetrics();
        expect(initialMetrics.memoryUsage, greaterThanOrEqualTo(0.0));

        // 执行大量内存操作
        for (int i = 0; i < 100; i++) {
          await dataService.set('memory_test_$i', {
            'data': List.generate(100, (index) => 'item_$index'),
            'index': i,
          });
        }

        // 执行内存优化
        await performanceService.optimizePerformance(aggressive: true);

        // 验证内存管理有效
        final finalMetrics =
            await performanceService.getCurrentPerformanceMetrics();
        expect(finalMetrics.memoryUsage, greaterThanOrEqualTo(0.0));
      });

      test('应该能够释放资源', () async {
        // 创建临时服务
        final tempPerformanceService = UnifiedPerformanceService();
        final tempDataService = UnifiedDataService();

        // 初始化并使用
        await tempPerformanceService.initialize(container);
        await tempDataService.initialize(container);

        await tempDataService.set('temp_key', 'temp_value');
        final metrics =
            await tempPerformanceService.getCurrentPerformanceMetrics();
        expect(metrics, isNotNull);

        // 释放资源
        await tempPerformanceService.dispose();
        await tempDataService.dispose();

        expect(tempPerformanceService.lifecycleState,
            ServiceLifecycleState.disposed);
        expect(tempDataService.lifecycleState, ServiceLifecycleState.disposed);
      });
    });
  });
}
