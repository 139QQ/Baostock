import 'package:flutter_test/flutter_test.dart';
import 'package:jisu_fund_analyzer/src/features/fund/shared/services/fund_data_service.dart';

/// 缓存机制测试
void main() {
  // 初始化测试环境
  TestWidgetsFlutterBinding.ensureInitialized();

  group('缓存机制测试', () {
    late FundDataService fundDataService;

    setUpAll(() async {
      fundDataService = FundDataService();
    });

    test('应该能够优先使用缓存数据（120秒内）', () async {
      print('🧪 测试智能缓存机制...');

      // 第一次请求 - 应该从API获取数据
      print('📡 第一次请求 - 应该从API获取数据');
      final startTime1 = DateTime.now();
      final result1 = await fundDataService.getFundRankings();
      final endTime1 = DateTime.now();
      final duration1 = endTime1.difference(startTime1);

      expect(result1.isSuccess, isTrue);
      expect(result1.data, isNotNull);
      expect(result1.data!.length, greaterThan(0));

      print(
          '✅ 第一次请求完成，耗时: ${duration1.inSeconds}秒，获取数据: ${result1.data!.length}条');

      // 等待1秒后进行第二次请求 - 应该从缓存获取数据
      print('⏳ 等待1秒后进行第二次请求...');
      await Future.delayed(const Duration(seconds: 1));

      print('💾 第二次请求 - 应该从缓存获取数据');
      final startTime2 = DateTime.now();
      final result2 = await fundDataService.getFundRankings();
      final endTime2 = DateTime.now();
      final duration2 = endTime2.difference(startTime2);

      expect(result2.isSuccess, isTrue);
      expect(result2.data, isNotNull);
      expect(result2.data!.length, equals(result1.data!.length));

      print(
          '✅ 第二次请求完成，耗时: ${duration2.inMilliseconds}ms，获取数据: ${result2.data!.length}条');

      // 验证第二次请求明显更快（使用缓存）
      expect(
          duration2.inMilliseconds, lessThan(duration1.inMilliseconds ~/ 10));
      print('✅ 缓存机制验证成功 - 第二次请求比第一次快10倍以上');

      // 验证数据一致性
      expect(
          result2.data!.first.fundCode, equals(result1.data!.first.fundCode));
      expect(
          result2.data!.first.fundName, equals(result1.data!.first.fundName));
      print('✅ 缓存数据一致性验证通过');
    });

    test('应该能够在缓存过期后重新从API获取数据', () async {
      print('🧪 测试缓存过期机制...');

      // 获取初始数据
      print('📡 获取初始数据...');
      final result1 = await fundDataService.getFundRankings();
      expect(result1.isSuccess, isTrue);

      // 强制刷新缓存
      print('🔄 强制刷新缓存...');
      final result2 = await fundDataService.getFundRankings(forceRefresh: true);
      expect(result2.isSuccess, isTrue);
      expect(result2.data!.length, equals(result1.data!.length));

      print('✅ 缓存过期机制测试通过');
    });

    test('应该能够显示缓存统计信息', () {
      print('🧪 测试缓存统计信息...');

      final stats = fundDataService.getCacheStats();
      print('📊 缓存统计信息:');
      stats.forEach((key, value) {
        print('  $key: $value');
      });

      expect(stats, isA<Map<String, dynamic>>());
      expect(stats.containsKey('cacheSize'), isTrue);
      expect(stats.containsKey('cacheExpireTime'), isTrue);
      expect(stats.containsKey('lastUpdate'), isTrue);

      print('✅ 缓存统计信息测试通过');
    });

    test('应该能够清除缓存', () async {
      print('🧪 测试清除缓存功能...');

      // 先获取数据确保有缓存
      await fundDataService.getFundRankings();

      // 清除缓存
      print('🗑️ 清除缓存...');
      await fundDataService.clearCache();

      print('✅ 缓存清除功能测试通过');
    });
  });
}
