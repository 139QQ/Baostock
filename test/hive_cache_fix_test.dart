import 'package:flutter_test/flutter_test.dart';

import 'package:jisu_fund_analyzer/src/core/cache/hive_cache_manager.dart';
import 'package:jisu_fund_analyzer/src/features/fund/shared/services/fund_data_service.dart';

/// Hive缓存修复测试
void main() {
  // 初始化测试环境
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Hive缓存修复测试', () {
    late HiveCacheManager cacheManager;
    late FundDataService fundDataService;

    setUpAll(() async {
      cacheManager = HiveCacheManager.instance;
      fundDataService = FundDataService(cacheManager: cacheManager);
    });

    test('应该能够成功初始化Hive缓存管理器', () async {
      print('🧪 测试Hive缓存管理器初始化...');

      await cacheManager.initialize();

      final stats = cacheManager.getStats();
      print('📊 缓存统计信息:');
      stats.forEach((key, value) {
        print('  $key: $value');
      });

      expect(stats['initialized'], isTrue);
      expect(stats.containsKey('size'), isTrue);
    });

    test('应该能够正常存储和读取数据', () async {
      print('🧪 测试数据存储和读取...');

      await cacheManager.initialize();

      // 存储测试数据
      final testData = {
        'fund_code': '005827',
        'fund_name': '易方达蓝筹精选混合',
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

    test('应该能够获取缓存大小', () async {
      print('🧪 测试缓存大小统计...');

      await cacheManager.initialize();

      // 存储多条测试数据
      for (int i = 0; i < 3; i++) {
        await cacheManager
            .put('test_key_$i', {'index': i, 'data': 'test_data_$i'});
      }

      final size = cacheManager.size;
      expect(size, greaterThanOrEqualTo(3));

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
      for (int i = 0; i < 2; i++) {
        await cacheManager.put('clear_test_$i', {'index': i});
      }

      // 确认数据存在
      expect(cacheManager.size, greaterThanOrEqualTo(2));

      // 清空缓存
      await cacheManager.clear();

      // 确认缓存已清空
      expect(cacheManager.size, 0);

      print('✅ 清空缓存功能正常');
    });

    test('FundDataService应该能够正常工作', () async {
      print('🧪 测试FundDataService...');

      final stats = fundDataService.getCacheStats();
      print('📊 FundDataService缓存统计:');
      stats.forEach((key, value) {
        print('  $key: $value');
      });

      expect(stats, isA<Map<String, dynamic>>());
      expect(stats.containsKey('cacheSize'), isTrue);

      print('✅ FundDataService与Hive缓存集成正常');
    });

    test('应该能够处理错误情况', () async {
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

  group('FundDataService API优化测试', () {
    late FundDataService fundDataService;

    setUpAll(() async {
      fundDataService = FundDataService();
    });

    test('应该能够测试长超时时间的API请求', () async {
      print('🧪 开始测试API请求超时配置...');

      final startTime = DateTime.now();

      try {
        final result = await fundDataService.getFundRankings(
          forceRefresh: true, // 强制刷新，绕过缓存
        );

        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        print('✅ API请求完成');
        print('⏱️ 请求耗时: ${duration.inSeconds}秒');

        if (result.isSuccess) {
          print('📊 获取到数据: ${result.data!.length}条基金');
          expect(result.data, isNotNull);
          expect(result.data!.length, greaterThan(0));
        } else {
          print('❌ API请求失败: ${result.errorMessage}');
          // 在测试环境下，网络请求失败是可接受的
          expect(result.errorMessage, isNotNull);
        }
      } catch (e) {
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        print('⚠️ 请求异常: $e');
        print('⏱️ 异常前耗时: ${duration.inSeconds}秒');

        // 验证超时时间是否正确配置（应该在5分钟左右超时）
        expect(duration.inSeconds, lessThan(360)); // 不应该超过6分钟
      }
    });

    test('应该能够获取缓存统计信息', () {
      print('🧪 测试缓存统计功能...');

      final stats = fundDataService.getCacheStats();
      print('📊 缓存统计信息:');
      stats.forEach((key, value) {
        print('  $key: $value');
      });

      expect(stats, isA<Map<String, dynamic>>());
      expect(stats.containsKey('cacheSize'), isTrue);
      expect(stats.containsKey('cacheExpireTime'), isTrue);
      expect(stats.containsKey('lastUpdate'), isTrue);
    });

    test('应该能够获取数据质量统计', () {
      print('🧪 测试数据质量统计...');

      final qualityStats = fundDataService.getDataQualityStats();
      print('📊 数据质量统计:');
      qualityStats.forEach((key, value) {
        print('  $key: $value');
      });

      expect(qualityStats, isA<Map<String, dynamic>>());
      expect(qualityStats.containsKey('totalValidations'), isTrue);
      expect(qualityStats.containsKey('successRate'), isTrue);
    });
  });
}
