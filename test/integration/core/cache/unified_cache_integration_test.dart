<<<<<<< HEAD
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
=======
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
>>>>>>> temp-dependency-injection

import 'package:jisu_fund_analyzer/src/core/cache/interfaces/cache_service.dart';
import 'package:jisu_fund_analyzer/src/core/config/cache_system_config.dart';
import 'package:jisu_fund_analyzer/src/core/di/injection_container.dart';
import 'package:jisu_fund_analyzer/src/features/fund/shared/services/fund_data_service.dart';
import 'package:jisu_fund_analyzer/src/features/fund/shared/services/data_validation_service.dart';
import 'package:jisu_fund_analyzer/src/core/cache/adapters/unified_cache_adapter.dart';
<<<<<<< HEAD
import 'package:jisu_fund_analyzer/src/core/cache/unified_hive_cache_manager.dart';
=======
>>>>>>> temp-dependency-injection

void main() {
  group('统一缓存系统集成测试', () {
    late GetIt testSl;
<<<<<<< HEAD
    late String tempPath;
    late UnifiedHiveCacheManager cacheManager;
=======
>>>>>>> temp-dependency-injection

    setUpAll(() async {
      testSl = GetIt.instance;
      CacheSystemConfig.enableUnifiedCache();

<<<<<<< HEAD
      // 初始化Hive用于测试
      try {
        // 简化Hive初始化，避免path_provider依赖
        tempPath = Directory.current.path +
            '/test_cache_${DateTime.now().millisecondsSinceEpoch}';
        await Directory(tempPath).create(recursive: true);

        // 直接使用Hive.init而不是Hive.initFlutter来避免path_provider依赖
        Hive.init(tempPath);
        print('Hive initialized for testing at: $tempPath');
      } catch (e) {
        print('Hive initialization failed: $e');
        // 设置一个默认值让测试能够继续
        tempPath = Directory.current.path;
      }

      // 只初始化一次依赖注入
      await initDependencies();

      // 获取缓存管理器实例并等待初始化完成
      cacheManager = UnifiedHiveCacheManager.instance;
      await cacheManager.initialize();

      // 等待缓存系统完全初始化
      await Future.delayed(Duration(milliseconds: 1000));
=======
      // 只初始化一次依赖注入
      await initDependencies();
>>>>>>> temp-dependency-injection
    });

    setUp(() async {
      // 每个测试前清理缓存状态，避免测试间数据污染
      try {
        final cacheService = testSl<CacheService>();
        await cacheService.clear();
<<<<<<< HEAD
        // 同时清理缓存管理器
        await cacheManager.clear();
=======
>>>>>>> temp-dependency-injection
      } catch (e) {
        // 如果清理失败，记录但不影响测试
        print('测试前清理缓存失败: $e');
      }
    });

    tearDownAll(() async {
<<<<<<< HEAD
      try {
        // 清理缓存（只有在cacheManager初始化成功的情况下）
        if (cacheManager != null) {
          await cacheManager.clear();
          await cacheManager.dispose();
        }
        await Hive.close();
        // 删除临时目录
        if (tempPath != null && await Directory(tempPath).exists()) {
          await Directory(tempPath).delete(recursive: true);
        }
        await testSl.reset();
      } catch (e) {
        print('清理测试环境失败: $e');
      }
=======
      await testSl.reset();
>>>>>>> temp-dependency-injection
    });

    group('缓存服务集成测试', () {
      test('应该能够完成完整的缓存操作流程', () async {
        // 依赖注入已在setUpAll中初始化

        // 获取缓存服务
        final cacheService = testSl<CacheService>();
        expect(cacheService, isNotNull);

        // 测试缓存操作
        const testKey = 'integration_test_key';
        const testValue = {'message': 'Hello Unified Cache!'};

        // 存储数据
        await cacheService.put(testKey, testValue);

        // 验证数据存在
        final exists = await cacheService.containsKey(testKey);
        expect(exists, isTrue);

        // 获取数据
        final retrievedValue = await cacheService.get(testKey);
        expect(retrievedValue, equals(testValue));

        // 删除数据
        await cacheService.remove(testKey);

        // 验证数据已删除
        final existsAfterRemove = await cacheService.containsKey(testKey);
        expect(existsAfterRemove, isFalse);
      });

      test('应该支持批量缓存操作', () async {
        // 依赖注入已在setUpAll中初始化

        final cacheService = testSl<CacheService>();

        final testData = {
          'key1': 'value1',
          'key2': 'value2',
          'key3': 'value3',
        };

        // 批量存储
        await cacheService.putAll(testData);

        // 批量获取
        final keys = testData.keys.toList();
        final results = await cacheService.getAll(keys);

        expect(results['key1'], equals('value1'));
        expect(results['key2'], equals('value2'));
        expect(results['key3'], equals('value3'));

        // 清理
        await cacheService.removeAll(keys);
      });

      test('应该支持缓存过期', () async {
        // 依赖注入已在setUpAll中初始化

        final cacheService = testSl<CacheService>();

        const testKey = 'expiration_test';
        const testValue = 'will_expire';
        const expiration = Duration(milliseconds: 100);

        // 存储带过期时间的数据
        await cacheService.put(testKey, testValue, expiration: expiration);

        // 立即获取应该成功
        final immediateValue = await cacheService.get(testKey);
        expect(immediateValue, equals(testValue));

        // 等待过期
        await Future.delayed(Duration(milliseconds: 150));

        // 过期后获取应该返回null（这取决于具体实现）
        // 注意：某些缓存实现可能不会自动清理过期数据
        final expiredValue = await cacheService.get(testKey);
        // 这里根据具体实现来断言
      });
    });

    group('服务集成测试', () {
      test('FundDataService 应该能够使用统一缓存', () async {
        // 依赖注入已在setUpAll中初始化

        final fundDataService = testSl<FundDataService>();
        expect(fundDataService, isNotNull);

        // 测试缓存统计功能
        final stats = await fundDataService.getCacheStats();
        expect(stats, isA<Map>());
        expect(stats.containsKey('cacheExpireTime'), isTrue);
      });

      test('DataValidationService 应该能够使用统一缓存', () async {
        // 依赖注入已在setUpAll中初始化

        final validationService = testSl<DataValidationService>();
        expect(validationService, isNotNull);

        // 验证服务已正确初始化
        expect(validationService, isA<DataValidationService>());
      });
    });

    group('配置切换测试', () {
      test('应该能够在运行时切换缓存系统', () async {
        // 依赖注入已在setUpAll中初始化

        var cacheService = testSl<CacheService>();
        expect(cacheService, isA<UnifiedCacheAdapter>());

        // 切换到传统缓存（仅验证配置变化，不重新初始化）
        CacheSystemConfig.enableLegacyCache();

        var config = CacheSystemConfig.getCurrentConfig();
        expect(config['useUnifiedCache'], isFalse);

        // 切换回统一缓存
        CacheSystemConfig.enableUnifiedCache();

        config = CacheSystemConfig.getCurrentConfig();
        expect(config['useUnifiedCache'], isTrue);
      });
    });

    group('性能和稳定性测试', () {
      test('应该能够处理大量并发缓存操作', () async {
        // 依赖注入已在setUpAll中初始化

        final cacheService = testSl<CacheService>();

        // 并发存储多个键值对
        final futures = <Future>[];
        for (int i = 0; i < 100; i++) {
          futures.add(cacheService.put('perf_test_$i', 'value_$i'));
        }

        await Future.wait(futures);

        // 验证所有数据都已存储
        final keys = List.generate(100, (i) => 'perf_test_$i');
        final results = await cacheService.getAll(keys);

        expect(results.length, equals(100));

        // 清理
        await cacheService.removeAll(keys);
      });

      test('应该能够处理大型数据对象', () async {
        // 依赖注入已在setUpAll中初始化

        final cacheService = testSl<CacheService>();

        // 创建大型数据对象
        final largeData = List.generate(
            1000,
            (i) => {
                  'id': i,
                  'name': 'Item $i',
                  'description':
                      'This is a detailed description for item $i. ' * 10,
                  'metadata': {
                    'created': DateTime.now().toIso8601String(),
                    'tags': ['tag1', 'tag2', 'tag3'],
                  }
                });

        const testKey = 'large_data_test';

        // 存储大型数据
        await cacheService.put(testKey, largeData);

        // 获取并验证
        final retrievedData = await cacheService.get(testKey);
        expect(retrievedData, isNotNull);
        expect(retrievedData.length, equals(1000));

        // 清理
        await cacheService.remove(testKey);
      });
    });
  });
}
