import 'package:flutter_test/flutter_test.dart';
import 'dart:async';

import 'package:jisu_fund_analyzer/src/core/cache/enhanced_hive_cache_manager.dart';
import 'package:jisu_fund_analyzer/src/features/fund/shared/services/fund_data_service.dart';

/// 增强版Hive缓存测试
void main() {
  // 初始化测试环境
  TestWidgetsFlutterBinding.ensureInitialized();

  group('增强版Hive缓存管理器测试', () {
    late EnhancedHiveCacheManager cacheManager;
    late FundDataService fundDataService;

    setUpAll(() async {
      cacheManager = EnhancedHiveCacheManager.instance;
      fundDataService = FundDataService(); // 使用默认缓存管理器
    });

    tearDownAll(() async {
      await cacheManager.close();
    });

    test('应该能够成功初始化增强版缓存管理器', () async {
      print('🧪 测试增强版缓存管理器初始化...');

      await cacheManager.initialize();

      final stats = cacheManager.getStats();
      print('📊 缓存统计信息:');
      stats.forEach((key, value) {
        print('  $key: $value');
      });

      expect(stats['isInitialized'], isTrue);
      expect(stats['mode'], isIn(['memory', 'file']));
    });

    test('应该能够正常存储和读取数据', () async {
      print('🧪 测试数据存储和读取...');

      await cacheManager.initialize();

      // 存储测试数据
      final testData = {
        'fund_code': '005827',
        'fund_name': '易方达蓝筹精选混合',
        'fund_type': '混合型',
        'nav': 1.525,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await cacheManager.put('test_fund_005827', testData);

      // 读取数据
      final retrievedData =
          cacheManager.get<Map<String, dynamic>>('test_fund_005827');

      expect(retrievedData, isNotNull);
      expect(retrievedData!['fund_code'], '005827');
      expect(retrievedData['fund_name'], '易方达蓝筹精选混合');

      print('✅ 数据存储和读取成功');
    });

    test('应该能够处理缓存过期', () async {
      print('🧪 测试缓存过期处理...');

      await cacheManager.initialize();

      // 存储短期缓存数据（1秒过期）
      final shortTermData = {'message': '这个数据会很快过期'};
      await cacheManager.put('short_term_data', shortTermData,
          expiration: const Duration(seconds: 1));

      // 立即读取应该成功
      final immediateData =
          cacheManager.get<Map<String, dynamic>>('short_term_data');
      expect(immediateData, isNotNull);
      expect(immediateData!['message'], '这个数据会很快过期');

      print('✅ 短期数据存储成功');

      // 等待过期后读取应该返回null
      await Future.delayed(const Duration(seconds: 2));
      final expiredData =
          cacheManager.get<Map<String, dynamic>>('short_term_data');
      expect(expiredData, isNull);

      print('✅ 缓存过期处理正常');
    });

    test('应该能够获取缓存大小统计', () async {
      print('🧪 测试缓存大小统计...');

      await cacheManager.initialize();

      // 存储多条测试数据
      for (int i = 0; i < 5; i++) {
        await cacheManager
            .put('test_key_$i', {'index': i, 'data': 'test_data_$i'});
      }

      final size = cacheManager.size;
      expect(size, greaterThanOrEqualTo(5));

      print('✅ 缓存大小统计正常: $size 条记录');
    });

    test('应该能够检查键是否存在', () async {
      print('🧪 测试键存在性检查...');

      await cacheManager.initialize();

      // 存储测试数据
      await cacheManager.put('existence_test', {'exists': true});

      // 检查存在的键
      expect(cacheManager.containsKey('existence_test'), isTrue);

      // 检查不存在的键
      expect(cacheManager.containsKey('non_existent_key'), isFalse);

      print('✅ 键存在性检查正常');
    });

    test('应该能够删除特定键的数据', () async {
      print('🧪 测试数据删除...');

      await cacheManager.initialize();

      // 存储测试数据
      await cacheManager.put('delete_test', {'will_be_deleted': true});

      // 确认数据存在
      expect(cacheManager.containsKey('delete_test'), isTrue);

      // 删除数据
      await cacheManager.remove('delete_test');

      // 确认数据已删除
      expect(cacheManager.containsKey('delete_test'), isFalse);

      print('✅ 数据删除功能正常');
    });

    test('应该能够清空所有缓存', () async {
      print('🧪 测试清空缓存...');

      await cacheManager.initialize();

      // 存储多条测试数据
      for (int i = 0; i < 3; i++) {
        await cacheManager.put('clear_test_$i', {'index': i});
      }

      // 确认数据存在
      expect(cacheManager.size, greaterThanOrEqualTo(3));

      // 清空缓存
      await cacheManager.clear();

      // 确认缓存已清空
      expect(cacheManager.size, 0);

      print('✅ 清空缓存功能正常');
    });

    test('FundDataService应该能够使用增强版缓存', () async {
      print('🧪 测试FundDataService与增强版缓存集成...');

      final stats = fundDataService.getCacheStats();
      print('📊 FundDataService缓存统计:');
      stats.forEach((key, value) {
        print('  $key: $value');
      });

      expect(stats, isA<Map<String, dynamic>>());
      expect(stats.containsKey('cacheSize'), isTrue);

      print('✅ FundDataService与增强版缓存集成正常');
    });

    test('应该能够处理并发访问', () async {
      print('🧪 测试并发访问...');

      await cacheManager.initialize();

      // 并发存储多条数据
      final futures = <Future>[];
      for (int i = 0; i < 10; i++) {
        futures.add(cacheManager.put('concurrent_$i', {'index': i}));
      }

      await Future.wait(futures);

      // 验证所有数据都已存储
      int foundCount = 0;
      for (int i = 0; i < 10; i++) {
        if (cacheManager.containsKey('concurrent_$i')) {
          foundCount++;
        }
      }

      expect(foundCount, 10);

      print('✅ 并发访问处理正常');
    });

    test('应该能够优雅处理错误情况', () async {
      print('🧪 测试错误处理...');

      await cacheManager.initialize();

      // 尝试获取不存在的键
      final nullData = cacheManager.get<String>('non_existent_key');
      expect(nullData, isNull);

      // 尝试删除不存在的键（不应该抛出异常）
      await cacheManager.remove('non_existent_key');

      // 尝试读取已删除的键
      await cacheManager.put('temp_key', 'temp_value');
      await cacheManager.remove('temp_key');
      final deletedData = cacheManager.get<String>('temp_key');
      expect(deletedData, isNull);

      print('✅ 错误处理正常');
    });
  });

  group('缓存性能测试', () {
    late EnhancedHiveCacheManager cacheManager;

    setUpAll(() async {
      cacheManager = EnhancedHiveCacheManager.instance;
      await cacheManager.initialize();
    });

    tearDownAll(() async {
      await cacheManager.close();
    });

    test('批量存储性能测试', () async {
      print('🧪 测试批量存储性能...');

      final stopwatch = Stopwatch()..start();

      // 批量存储100条记录
      for (int i = 0; i < 100; i++) {
        await cacheManager.put('perf_test_$i', {
          'index': i,
          'name': '基金$i',
          'value': 100.0 + i,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }

      stopwatch.stop();

      print('⏱️ 批量存储100条记录耗时: ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // 期望在5秒内完成

      // 验证存储结果
      expect(cacheManager.size, greaterThanOrEqualTo(100));

      print('✅ 批量存储性能测试通过');
    });

    test('批量读取性能测试', () async {
      print('🧪 测试批量读取性能...');

      // 确保有测试数据
      for (int i = 0; i < 50; i++) {
        await cacheManager
            .put('read_perf_$i', {'index': i, 'data': 'test_data_$i'});
      }

      final stopwatch = Stopwatch()..start();

      // 批量读取
      int foundCount = 0;
      for (int i = 0; i < 50; i++) {
        final data = cacheManager.get<Map<String, dynamic>>('read_perf_$i');
        if (data != null && data['index'] == i) {
          foundCount++;
        }
      }

      stopwatch.stop();

      print('⏱️ 批量读取50条记录耗时: ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // 期望在1秒内完成
      expect(foundCount, 50);

      print('✅ 批量读取性能测试通过');
    });
  });
}
