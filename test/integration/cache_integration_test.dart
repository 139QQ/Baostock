import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:jisu_fund_analyzer/src/core/cache/interfaces/i_unified_cache_service.dart';
import '../helpers/unified_cache_test_helper.dart';

void main() {
  group('Unified Cache Integration Tests', () {
    late IUnifiedCacheService cacheService;

    setUpAll(() async {
      // 创建测试缓存服务
      cacheService = await UnifiedCacheTestHelper.createTestCacheService(
        strategyType: CacheStrategyType.hybrid,
        useMemoryStorage: true,
      );
    });

    tearDownAll(() async {
      // 清理测试环境
      await UnifiedCacheTestHelper.cleanupTestEnvironment();
    });

    tearDown(() async {
      // 每个测试后清理缓存
      await cacheService.clear();
    });

    group('Basic Cache Operations', () {
      test('should store and retrieve data correctly', () async {
        // Arrange
        const key = 'integration_test_key';
        const data = 'integration_test_data';

        // Act
        await cacheService.put(key, data);
        final retrieved = await cacheService.get<String>(key);

        // Assert
        expect(retrieved, equals(data));
        expect(await cacheService.exists(key), isTrue);
      });

      test('should handle complex data types correctly', () async {
        // Arrange
        const key = 'complex_data_key';
        final complexData = {
          'string_field': 'test_string',
          'number_field': 42,
          'boolean_field': true,
          'list_field': ['item1', 'item2', 'item3'],
          'nested_object': {
            'nested_string': 'nested_value',
            'nested_number': 3.14,
          },
        };

        // Act
        await cacheService.put(key, complexData);
        final retrieved = await cacheService.get(key);

        // Assert
        expect(retrieved, isNotNull);

        // 处理可能的序列化数据
        Map<String, dynamic> data;
        if (retrieved is String) {
          // 如果是字符串，尝试反序列化
          data = Map<String, dynamic>.from(jsonDecode(retrieved));
        } else {
          data = retrieved as Map<String, dynamic>;
        }

        expect(data['string_field'], equals('test_string'));
        expect(data['number_field'], equals(42));
        expect(data['boolean_field'], isTrue);
        expect(data['list_field'], contains('item1'));
        expect(data['nested_object']['nested_string'], equals('nested_value'));
      });

      test('should handle TTL expiration correctly', () async {
        // Arrange
        const key = 'ttl_test_key';
        const data = 'ttl_test_data';
        final config = CacheConfig(ttl: Duration(milliseconds: 200));

        // Act
        await cacheService.put(key, data, config: config);
        expect(await cacheService.exists(key), isTrue);

        // Wait for expiration
        await Future.delayed(Duration(milliseconds: 250));

        // Assert
        expect(await cacheService.exists(key), isFalse);
        expect(await cacheService.get<String>(key), isNull);
      });

      test('should handle cache updates correctly', () async {
        // Arrange
        const key = 'update_test_key';
        const initialData = 'initial_data';
        const updatedData = 'updated_data';

        // Act
        await cacheService.put(key, initialData);
        var retrieved = await cacheService.get<String>(key);
        expect(retrieved, equals(initialData));

        await cacheService.put(key, updatedData);
        retrieved = await cacheService.get<String>(key);

        // Assert
        expect(retrieved, equals(updatedData));
      });
    });

    group('Batch Operations', () {
      test('should handle batch put and get operations', () async {
        // Arrange
        final entries = <String, String>{
          'batch_key_1': 'batch_value_1',
          'batch_key_2': 'batch_value_2',
          'batch_key_3': 'batch_value_3',
          'batch_key_4': 'batch_value_4',
          'batch_key_5': 'batch_value_5',
        };

        // Act
        await cacheService.putAll(entries);
        final retrieved =
            await cacheService.getAll<String>(entries.keys.toList());

        // Assert
        expect(retrieved.length, equals(entries.length));
        for (final entry in entries.entries) {
          expect(retrieved[entry.key], equals(entry.value));
        }
      });

      test('should handle partial batch get correctly', () async {
        // Arrange
        await cacheService.put('existing_1', 'value_1');
        await cacheService.put('existing_2', 'value_2');

        final keys = [
          'existing_1',
          'non_existing_1',
          'existing_2',
          'non_existing_2'
        ];

        // Act
        final retrieved = await cacheService.getAll<String>(keys);

        // Assert
        expect(retrieved.length, equals(4));
        expect(retrieved['existing_1'], equals('value_1'));
        expect(retrieved['non_existing_1'], isNull);
        expect(retrieved['existing_2'], equals('value_2'));
        expect(retrieved['non_existing_2'], isNull);
      });
    });

    group('Cache Management', () {
      test('should handle remove operations correctly', () async {
        // Arrange
        const key = 'remove_test_key';
        const data = 'remove_test_data';
        await cacheService.put(key, data);
        expect(await cacheService.exists(key), isTrue);

        // Act
        final removed = await cacheService.remove(key);

        // Assert
        expect(removed, isTrue);
        expect(await cacheService.exists(key), isFalse);
        expect(await cacheService.get<String>(key), isNull);
      });

      test('should handle batch remove operations correctly', () async {
        // Arrange
        final keys = ['remove_1', 'remove_2', 'remove_3', 'remove_4'];
        for (final key in keys) {
          await cacheService.put(key, 'data_for_$key');
        }

        // Act
        final removedCount = await cacheService
            .removeAll(['remove_1', 'remove_3', 'non_existing']);

        // Assert
        expect(removedCount, equals(2));
        expect(await cacheService.exists('remove_1'), isFalse);
        expect(await cacheService.exists('remove_2'), isTrue);
        expect(await cacheService.exists('remove_3'), isFalse);
        expect(await cacheService.exists('remove_4'), isTrue);
      });

      test('should handle individual removal correctly', () async {
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

        // Act - Remove specific keys
        final removed1 = await cacheService.remove('pattern_test_1');
        final removed2 = await cacheService.remove('pattern_test_2');

        // Assert
        expect(removed1, isTrue);
        expect(removed2, isTrue);
        expect(await cacheService.exists('pattern_test_1'), isFalse);
        expect(await cacheService.exists('pattern_test_2'), isFalse);
        expect(await cacheService.exists('pattern_other_1'), isTrue);
        expect(await cacheService.exists('different_key_1'), isTrue);
      });

      test('should handle clear operation correctly', () async {
        // Arrange
        for (int i = 0; i < 10; i++) {
          await cacheService.put('clear_test_$i', 'data_$i');
        }

        expect(await cacheService.getStatistics().then((s) => s.totalCount),
            equals(10));

        // Act
        await cacheService.clear();

        // Assert
        final stats = await cacheService.getStatistics();
        expect(stats.totalCount, equals(0));
      });
    });

    group('Configuration Management', () {
      test('should use custom configuration correctly', () async {
        // Arrange
        const key = 'config_test_key';
        const data = 'config_test_data';
        final customConfig = CacheConfig(
          ttl: Duration(minutes: 1),
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

      test('should update configuration correctly', () async {
        // Arrange
        const key = 'config_update_key';
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

    group('Statistics and Monitoring', () {
      test('should track access statistics correctly', () async {
        // Arrange
        const key = 'stats_test_key';
        const data = 'stats_test_data';
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

      test('should provide cache statistics correctly', () async {
        // Arrange
        final entries = UnifiedCacheTestHelper.generateTestEntries(50);
        for (final entry in entries) {
          await cacheService.put(entry.key, entry.data);
        }

        // Act
        final stats = await cacheService.getStatistics();

        // Assert
        expect(stats.totalCount, equals(50));
        expect(stats.validCount, equals(50));
        expect(stats.expiredCount, equals(0));
        expect(stats.totalSize, greaterThan(0));
      });
    });

    group('Performance and Stress', () {
      test('should handle reasonable load efficiently', () async {
        // Arrange
        const operationCount = 100;
        final entries =
            UnifiedCacheTestHelper.generateTestEntries(operationCount);

        // Act
        final stopwatch = Stopwatch()..start();

        // Write operations
        for (final entry in entries) {
          await cacheService.put(entry.key, entry.data);
        }

        // Read operations
        int hits = 0;
        for (final entry in entries) {
          final retrieved = await cacheService.get(entry.key);
          if (retrieved != null) hits++;
        }

        stopwatch.stop();

        // Assert
        expect(hits, equals(operationCount));
        expect(stopwatch.elapsedMilliseconds,
            lessThan(5000)); // Should complete within 5 seconds

        final avgTime = stopwatch.elapsedMilliseconds / (operationCount * 2);
        print('Average operation time: ${avgTime.toStringAsFixed(2)}ms');
      });

      test('should maintain consistency under load', () async {
        // Arrange
        const entryCount = 200;
        final entries = UnifiedCacheTestHelper.generateTestEntries(entryCount);

        // Act - Store all entries
        for (final entry in entries) {
          await cacheService.put(entry.key, entry.data);
        }

        // Verify consistency
        final consistencyReport =
            await UnifiedCacheTestHelper.verifyCacheConsistency(
          cacheService,
          entries,
        );

        // Assert
        expect(consistencyReport.isConsistent, isTrue,
            reason: 'Cache consistency check failed: ${consistencyReport}');
        expect(consistencyReport.consistencyRate, greaterThan(0.95));
      });
    });

    group('Error Handling', () {
      test('should handle invalid operations gracefully', () async {
        // Act & Assert - Getting non-existent key should return null
        final result =
            await cacheService.get<String>('definitely_not_existing_key');
        expect(result, isNull);

        // Act & Assert - Removing non-existent key should return false
        final removed =
            await cacheService.remove('definitely_not_existing_key');
        expect(removed, isFalse);
      });

      test('should handle configuration validation', () async {
        // Act & Assert - Invalid configuration should throw exception
        expect(
          () => cacheService.put('test', 'data',
              config: CacheConfig(priority: -1)),
          throwsA(anything),
        );
      });
    });

    group('Preload Functionality', () {
      test('should preload data correctly', () async {
        // Arrange
        final keys = ['preload_1', 'preload_2', 'preload_3'];
        final loader = (String key) async {
          await Future.delayed(
              Duration(milliseconds: 10)); // Simulate async operation
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

      test('should handle preload errors gracefully', () async {
        // Arrange
        final keys = ['preload_error_1', 'preload_error_2'];
        final loader = (String key) async {
          if (key.contains('error_1')) {
            throw Exception('Simulated load error');
          }
          return 'success_data_for_$key';
        };

        // Act - Should not throw even if some loads fail
        await cacheService.preload(keys, loader);

        // Assert
        expect(await cacheService.get<String>('preload_error_1'), isNull);
        expect(await cacheService.get<String>('preload_error_2'),
            equals('success_data_for_preload_error_2'));
      });
    });

    group('Optimization Features', () {
      test('should perform optimization without errors', () async {
        // Arrange
        final entries = UnifiedCacheTestHelper.generateTestEntries(100);
        for (final entry in entries) {
          await cacheService.put(entry.key, entry.data);
        }

        final beforeStats = await cacheService.getStatistics();

        // Act
        await cacheService.optimize();

        // Assert
        final afterStats = await cacheService.getStatistics();
        expect(afterStats.totalCount, equals(beforeStats.totalCount));
        print(
            'Optimization completed. Cache size: ${afterStats.totalSize} bytes');
      });
    });
  });
}
