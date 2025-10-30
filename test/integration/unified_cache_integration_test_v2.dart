import 'package:flutter_test/flutter_test.dart';
import 'package:jisu_fund_analyzer/src/core/cache/interfaces/i_unified_cache_service.dart';
import 'package:jisu_fund_analyzer/src/core/cache/unified_cache_manager.dart';
import 'package:jisu_fund_analyzer/src/core/cache/storage/cache_storage.dart';
import 'package:jisu_fund_analyzer/src/core/cache/strategies/cache_strategies.dart';
import 'package:jisu_fund_analyzer/src/core/cache/config/cache_config_manager.dart';

void main() {
  group('统一缓存系统集成测试', () {
    late IUnifiedCacheService cacheService;

    setUpAll(() async {
      // 创建测试用的缓存服务
      final storage = CacheStorageFactory.createMemoryStorage();
      await storage.initialize();

      final strategy = CacheStrategyFactory.getStrategy('lru');
      final configManager = CacheConfigManager();

      cacheService = UnifiedCacheManager(
        storage: storage,
        strategy: strategy,
        configManager: configManager,
        config: UnifiedCacheConfig.testing(),
      );
    });

    tearDownAll(() async {
      await cacheService.clear();
    });

    group('基础功能测试', () {
      test('应该能够存储和检索数据', () async {
        // Arrange
        const key = 'test_key';
        const data = 'test_data';

        // Act
        await cacheService.put(key, data);
        final result = await cacheService.get<String>(key);

        // Assert
        expect(result, equals(data));
        expect(await cacheService.exists(key), isTrue);
      });

      test('应该能够处理复杂数据类型', () async {
        // Arrange
        const key = 'complex_data';
        final complexData = {
          'string_field': 'test_string',
          'number_field': 42,
          'boolean_field': true,
          'list_field': ['item1', 'item2'],
          'nested_object': {
            'nested_string': 'nested_value',
            'nested_number': 3.14,
          },
        };

        // Act
        await cacheService.put(key, complexData);
        final result = await cacheService.get<Map<String, dynamic>>(key);

        // Assert
        expect(result, isNotNull);
        expect(result!['string_field'], equals('test_string'));
        expect(result['number_field'], equals(42));
        expect(result['boolean_field'], isTrue);
        expect(result['list_field'], contains('item1'));
        expect(
            result['nested_object']['nested_string'], equals('nested_value'));
      });

      test('应该正确处理TTL过期', () async {
        // Arrange
        const key = 'ttl_test';
        const data = 'ttl_data';
        final config = CacheConfig(ttl: Duration(milliseconds: 100));

        // Act
        await cacheService.put(key, data, config: config);
        expect(await cacheService.exists(key), isTrue);

        // Wait for expiration
        await Future.delayed(Duration(milliseconds: 150));

        // Assert
        expect(await cacheService.exists(key), isFalse);
        expect(await cacheService.get<String>(key), isNull);
      });
    });

    group('批量操作测试', () {
      test('应该能够处理批量存储和获取', () async {
        // Arrange
        final entries = <String, String>{
          'key1': 'value1',
          'key2': 'value2',
          'key3': 'value3',
          'key4': 'value4',
          'key5': 'value5',
        };

        // Act
        await cacheService.putAll(entries);
        final results =
            await cacheService.getAll<String>(entries.keys.toList());

        // Assert
        expect(results.length, equals(entries.length));
        for (final entry in entries.entries) {
          expect(results[entry.key], equals(entry.value));
        }
      });

      test('应该能够处理部分缺失的批量获取', () async {
        // Arrange
        await cacheService.put('existing1', 'value1');
        await cacheService.put('existing2', 'value2');

        final keys = [
          'existing1',
          'non_existing1',
          'existing2',
          'non_existing2',
        ];

        // Act
        final results = await cacheService.getAll<String>(keys);

        // Assert
        expect(results.length, equals(4));
        expect(results['existing1'], equals('value1'));
        expect(results['non_existing1'], isNull);
        expect(results['existing2'], equals('value2'));
        expect(results['non_existing2'], isNull);
      });
    });

    group('缓存管理测试', () {
      test('应该能够正确删除缓存项', () async {
        // Arrange
        const key = 'delete_test';
        const data = 'delete_data';
        await cacheService.put(key, data);
        expect(await cacheService.exists(key), isTrue);

        // Act
        final removed = await cacheService.remove(key);

        // Assert
        expect(removed, isTrue);
        expect(await cacheService.exists(key), isFalse);
        expect(await cacheService.get<String>(key), isNull);
      });

      test('应该能够批量删除缓存项', () async {
        // Arrange
        final keys = ['remove1', 'remove2', 'remove3'];
        for (final key in keys) {
          await cacheService.put(key, 'data_$key');
        }

        // Act
        final removedCount = await cacheService
            .removeAll(['remove1', 'remove3', 'non_existing']);

        // Assert
        expect(removedCount, equals(2));
        expect(await cacheService.exists('remove1'), isFalse);
        expect(await cacheService.exists('remove2'), isTrue);
        expect(await cacheService.exists('remove3'), isFalse);
      });

      test('应该能够按模式删除缓存项', () async {
        // Arrange
        final testKeys = [
          'pattern_test_1',
          'pattern_test_2',
          'pattern_other_1',
          'different_key_1',
        ];

        for (final key in testKeys) {
          await cacheService.put(key, 'data_for_$key');
        }

        // Act
        final removedCount =
            await cacheService.removeByPattern('pattern_test_*');

        // Assert
        expect(removedCount, equals(2));
        expect(await cacheService.exists('pattern_test_1'), isFalse);
        expect(await cacheService.exists('pattern_test_2'), isFalse);
        expect(await cacheService.exists('pattern_other_1'), isTrue);
        expect(await cacheService.exists('different_key_1'), isTrue);
      });

      test('应该能够清空所有缓存', () async {
        // Arrange
        for (int i = 0; i < 10; i++) {
          await cacheService.put('clear_test_$i', 'data_$i');
        }

        final statsBefore = await cacheService.getStatistics();
        expect(statsBefore.totalCount, equals(10));

        // Act
        await cacheService.clear();

        // Assert
        final statsAfter = await cacheService.getStatistics();
        expect(statsAfter.totalCount, equals(0));
      });
    });

    group('配置管理测试', () {
      test('应该能够使用自定义配置', () async {
        // Arrange
        const key = 'config_test';
        const data = 'config_data';
        final customConfig = CacheConfig(
          ttl: Duration(minutes: 30),
          priority: 8,
          compressible: true,
          tags: {'test', 'config'},
        );

        // Act
        await cacheService.put(key, data, config: customConfig);
        final retrievedConfig = await cacheService.getConfig(key);

        // Assert
        expect(retrievedConfig, isNotNull);
        expect(retrievedConfig!.priority, equals(8));
        expect(retrievedConfig.compressible, isTrue);
        expect(retrievedConfig.tags, contains('test'));
        expect(retrievedConfig.tags, contains('config'));
      });

      test('应该能够更新配置', () async {
        // Arrange
        const key = 'config_update';
        const data = 'config_update_data';
        final initialConfig = CacheConfig(priority: 5);
        final updatedConfig = CacheConfig(priority: 9);

        await cacheService.put(key, data, config: initialConfig);

        // Act
        final updateSuccess =
            await cacheService.updateConfig(key, updatedConfig);
        final retrievedConfig = await cacheService.getConfig(key);

        // Assert
        expect(updateSuccess, isTrue);
        expect(retrievedConfig!.priority, equals(9));
      });
    });

    group('统计和监控测试', () {
      test('应该能够跟踪访问统计', () async {
        // Arrange
        const key = 'stats_test';
        const data = 'stats_data';
        await cacheService.put(key, data);

        // Act
        await cacheService.get<String>(key); // Hit
        await cacheService.get<String>('non_existing'); // Miss
        await cacheService.get<String>(key); // Hit

        // Assert
        final stats = cacheService.getAccessStats();
        expect(stats.totalAccesses, equals(3));
        expect(stats.hits, equals(2));
        expect(stats.misses, equals(1));
        expect(stats.hitRate, equals(2.0 / 3.0));
      });

      test('应该能够提供缓存统计信息', () async {
        // Arrange
        final entries = [
          'stat_test_1',
          'stat_test_2',
          'stat_test_3',
          'stat_test_4',
          'stat_test_5',
        ];

        for (final entry in entries) {
          await cacheService.put(entry, 'data_$entry');
        }

        // Act
        final stats = await cacheService.getStatistics();

        // Assert
        expect(stats.totalCount, equals(5));
        expect(stats.validCount, equals(5));
        expect(stats.expiredCount, equals(0));
        expect(stats.totalSize, greaterThan(0));
      });
    });

    group('性能和负载测试', () {
      test('应该能够处理合理负载', () async {
        // Arrange
        const operationCount = 100;

        // Act
        final stopwatch = Stopwatch()..start();

        // 写入操作
        for (int i = 0; i < operationCount; i++) {
          await cacheService.put('load_test_$i', 'data_$i');
        }

        // 读取操作
        int hits = 0;
        for (int i = 0; i < operationCount; i++) {
          final result = await cacheService.get<String>('load_test_$i');
          if (result != null) hits++;
        }

        stopwatch.stop();

        // Assert
        expect(hits, equals(operationCount));
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // 5秒内完成

        final avgTime = stopwatch.elapsedMilliseconds / (operationCount * 2);
        print('平均操作时间: ${avgTime.toStringAsFixed(2)}ms');
      });

      test('应该能够处理大数据量', () async {
        // Arrange
        const dataSize = 1000; // 1KB数据
        final largeData = _generateTestData(dataSize);

        // Act
        final stopwatch = Stopwatch()..start();
        await cacheService.put('large_data_test', largeData);
        final retrieved =
            await cacheService.get<Map<String, dynamic>>('large_data_test');
        stopwatch.stop();

        // Assert
        expect(retrieved, isNotNull);
        expect(retrieved!.length, greaterThan(900)); // 数据完整性检查
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // 1秒内完成

        print('大数据操作时间: ${stopwatch.elapsedMilliseconds}ms');
      });
    });

    group('错误处理测试', () {
      test('应该能够优雅处理无效操作', () async {
        // Act & Assert - 获取不存在的键应该返回null
        final result =
            await cacheService.get<String>('definitely_not_existing');
        expect(result, isNull);

        // Act & Assert - 删除不存在的键应该返回false
        final removed = await cacheService.remove('definitely_not_existing');
        expect(removed, isFalse);
      });

      test('应该能够处理配置验证', () async {
        // Act & Assert - 无效配置应该抛出异常
        expect(
          () => cacheService.put('test', 'data',
              config: CacheConfig(priority: -1)),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('预加载功能测试', () {
      test('应该能够预加载数据', () async {
        // Arrange
        final keys = ['preload_1', 'preload_2', 'preload_3'];
        final loader = (String key) async {
          await Future.delayed(Duration(milliseconds: 10)); // 模拟异步操作
          return 'preloaded_data_for_$key';
        };

        // Act
        await cacheService.preload(keys, loader);

        // Assert
        for (final key in keys) {
          final retrieved = await cacheService.get<String>(key);
          expect(retrieved, equals('preloaded_data_for_$key'));
        }
      });

      test('应该能够处理预加载错误', () async {
        // Arrange
        final keys = ['preload_error_1', 'preload_error_2'];
        final loader = (String key) async {
          if (key.contains('error_1')) {
            throw Exception('Simulated load error');
          }
          return 'success_data_for_$key';
        };

        // Act - 应该不抛出异常，即使部分加载失败
        await cacheService.preload(keys, loader);

        // Assert
        expect(await cacheService.get<String>('preload_error_1'), isNull);
        expect(await cacheService.get<String>('preload_error_2'),
            equals('success_data_for_preload_error_2'));
      });
    });

    group('优化功能测试', () {
      test('应该能够执行优化操作', () async {
        // Arrange
        final entries = List.generate(50, (i) => 'opt_test_$i');
        for (final entry in entries) {
          await cacheService.put(entry, 'data_$entry');
        }

        final beforeStats = await cacheService.getStatistics();

        // Act
        await cacheService.optimize();

        // Assert
        final afterStats = await cacheService.getStatistics();
        expect(afterStats.totalCount, equals(beforeStats.totalCount));
        print('优化完成，缓存大小: ${afterStats.totalSize} bytes');
      });
    });
  });
}

/// 生成测试数据
Map<String, dynamic> _generateTestData(int targetSizeBytes) {
  final data = <String, dynamic>{};
  int currentSize = 0;
  int fieldIndex = 0;

  while (currentSize < targetSizeBytes) {
    final fieldValue = 'x' * 100; // 每个字段100字节
    data['field_$fieldIndex'] = fieldValue;

    currentSize += fieldValue.length + 20; // +20 for field name and overhead
    fieldIndex++;
  }

  return data;
}
