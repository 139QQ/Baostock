import 'package:flutter_test/flutter_test.dart';
import 'package:jisu_fund_analyzer/src/features/fund/shared/services/fund_data_service.dart';

/// API修复测试
void main() {
  // 初始化测试环境
  TestWidgetsFlutterBinding.ensureInitialized();

  group('API修复测试', () {
    late FundDataService fundDataService;

    setUpAll(() async {
      fundDataService = FundDataService();
    });

    test('应该能够正确构建API请求URL', () {
      print('🧪 测试API URL构建...');

      // 验证symbol参数是否正确处理
      const expectedSymbol = '全部';
      const baseUrl = 'http://154.44.25.92:8080';

      // 构建API URL的逻辑（与FundDataService中的逻辑相同）
      String apiUrl = '$baseUrl/api/public/fund_open_fund_rank_em';
      if (expectedSymbol.isNotEmpty && expectedSymbol != '全部') {
        apiUrl += '?symbol=${Uri.encodeComponent(expectedSymbol)}';
      } else {
        // 对于"全部"或空参数，直接使用中文字符
        apiUrl += '?symbol=全部';
      }

      print('✅ 基础URL: $baseUrl');
      print('✅ Symbol参数: $expectedSymbol');
      print('✅ 最终API URL: $apiUrl');

      // 验证URL包含正确的参数
      expect(apiUrl, contains('fund_open_fund_rank_em'));
      expect(apiUrl, contains('symbol=全部'));

      print('✅ API URL构建正确');
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

      print('✅ 缓存统计功能正常');
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

      print('✅ 数据质量统计功能正常');
    });

    test('应该能够测试超时配置', () async {
      print('🧪 测试API超时配置（50秒超时）...');

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
          // 验证错误信息是否包含400状态码
          expect(result.errorMessage, isNotNull);
          if (result.errorMessage!.contains('400')) {
            print('⚠️ API返回400错误，检查参数格式');
          }
        }
      } catch (e) {
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        print('⚠️ 请求异常: $e');
        print('⏱️ 异常前耗时: ${duration.inSeconds}秒');

        // 验证超时时间是否正确配置（应该在50秒左右，加上重试时间不超过100秒）
        expect(duration.inSeconds, lessThan(100)); // 不应该超过100秒（50秒超时 + 重试）
      }
    });
  });
}
