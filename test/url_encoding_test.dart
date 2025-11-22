import 'package:flutter_test/flutter_test.dart';

/// URL编码测试
void main() {
  group('URL编码测试', () {
    test('应该能够正确编码中文参数', () {
      const baseUrl = 'http://154.44.25.92:8080';
      const symbol = '全部';

      // 测试URL编码逻辑
      final encodedSymbol = Uri.encodeComponent(symbol);
      final finalUrl =
          '$baseUrl/api/public/fund_open_fund_rank_em?symbol=$encodedSymbol';

      print('🔗 原始参数: $symbol');
      print('📝 编码后参数: $encodedSymbol');
      print('🌐 最终URL: $finalUrl');

      // 验证编码结果
      expect(encodedSymbol, equals('%E5%85%A8%E9%83%A8'));
      expect(finalUrl, contains('symbol=%E5%85%A8%E9%83%A8'));

      print('✅ URL编码测试通过');
    });

    test('应该能够正确处理其他中文字符', () {
      const testCases = ['混合型', '债券型', '股票型', '货币型'];

      for (final testCase in testCases) {
        final encoded = Uri.encodeComponent(testCase);
        final decoded = Uri.decodeComponent(encoded);

        print('🔤 测试字符: $testCase');
        print('📝 编码结果: $encoded');
        print('🔓 解码结果: $decoded');

        expect(decoded, equals(testCase));
        expect(encoded, contains('%'));
      }

      print('✅ 多种中文字符编码测试通过');
    });

    test('应该能够构建完整的API URL', () {
      const baseUrl = 'http://154.44.25.92:8080';
      const symbol = '全部';

      // 使用与FundDataService相同的逻辑
      final encodedSymbol = Uri.encodeComponent(symbol);
      final uri = Uri.parse(
          '$baseUrl/api/public/fund_open_fund_rank_em?symbol=$encodedSymbol');

      print('🌐 完整URI: $uri');
      print('🔗 路径: ${uri.path}');
      print('❓ 查询参数: ${uri.queryParameters}');
      print('📍 完整URL: ${uri.toString()}');

      expect(uri.toString(), startsWith(baseUrl));
      expect(uri.queryParameters['symbol'], equals(encodedSymbol));

      print('✅ 完整API URL构建测试通过');
    });
  });
}
