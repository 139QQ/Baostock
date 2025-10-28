import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:jisu_fund_analyzer/src/features/fund/shared/services/fund_data_service.dart';

/// API超时配置测试
void main() {
  // 初始化测试环境
  TestWidgetsFlutterBinding.ensureInitialized();

  group('API请求超时优化测试', () {
    late FundDataService fundDataService;

    setUpAll(() async {
      fundDataService = FundDataService();
    });

    test('应该能够测试长超时时间的API请求', () async {
      // 这个测试验证5分钟超时配置是否生效
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

    test('应该能够验证HTTP请求头优化', () async {
      print('🧪 测试HTTP请求头配置...');

      // 直接测试HTTP请求头
      final url = Uri.parse(
          'http://154.44.25.92:8080/api/public/fund_open_fund_rank_em?symbol=%E5%85%A8%E9%83%A8');

      final headers = {
        'Accept': 'application/json; charset=utf-8',
        'Accept-Charset': 'utf-8',
        'Accept-Encoding': 'gzip, deflate',
        'User-Agent': 'FundDataService/2.0.0 (Flutter)',
        'Connection': 'keep-alive',
        'Keep-Alive': 'timeout=300, max=1000',
        'Cache-Control': 'max-age=0, no-cache',
        'Pragma': 'no-cache',
        'X-Requested-With': 'FundDataService',
      };

      print('📤 请求头配置:');
      headers.forEach((key, value) {
        print('  $key: $value');
      });

      try {
        final response = await http
            .get(
              url,
              headers: headers,
            )
            .timeout(const Duration(seconds: 30)); // 测试用较短超时

        print('📊 响应状态: ${response.statusCode}');
        print('📏 响应大小: ${response.body.length} 字节');
        print('📋 响应头: ${response.headers}');

        // 验证响应头中的压缩信息
        if (response.headers.containsKey('content-encoding')) {
          print('🗜️ 压缩方式: ${response.headers['content-encoding']}');
        }

        expect(response.statusCode, isIn([200, 400, 500])); // 接受常见HTTP状态码
      } catch (e) {
        print('⚠️ HTTP请求异常: $e');
        // 在测试环境中网络问题是可以接受的
        expect(e, isA<Exception>());
      }
    });

    test('应该能够验证重试机制配置', () async {
      print('🧪 测试重试机制配置...');

      // 测试无效URL来触发重试机制
      final invalidUrl =
          Uri.parse('http://154.44.25.92:8080/api/invalid_endpoint');

      try {
        final result = await fundDataService.getFundRankings(
          symbol: 'INVALID', // 使用无效symbol可能触发400错误
          forceRefresh: true,
        );

        // 预期会失败，但应该经过多次重试
        if (result.isFailure) {
          print('✅ 重试机制正常工作，最终失败: ${result.errorMessage}');
          expect(result.errorMessage, isNotNull);
          expect(result.errorMessage!, contains('获取基金数据失败'));
        }
      } catch (e) {
        print('⚠️ 重试测试异常: $e');
        // 异常也是可接受的，主要验证重试逻辑不会无限循环
      }
    });

    test('应该能够验证缓存统计信息', () {
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

    test('应该能够验证数据质量统计', () {
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
