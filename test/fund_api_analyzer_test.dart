import 'package:flutter_test/flutter_test.dart';
import 'package:jisu_fund_analyzer/src/services/fund_api_analyzer.dart';

void main() {
  group('FundApiAnalyzer Tests', () {
    late FundApiAnalyzer analyzer;

    setUp(() {
      analyzer = FundApiAnalyzer();
    });

    test('测试获取基金基本信息 - 有效的基金代码', () async {
      // 测试一个常见的基金代码
      final fundInfo = await analyzer.getFundBasicInfo('005827');

      expect(fundInfo, isNotNull);
      expect(fundInfo!['fund_code'], equals('005827'));
      expect(fundInfo['fund_name'], isNotEmpty);
      expect(fundInfo['fund_type'], isNotEmpty);

      print('基金信息: ${fundInfo['fund_name']} (${fundInfo['fund_code']})');
      print('基金类型: ${fundInfo['fund_type']}');
      print('基金经理: ${fundInfo['fund_manager']}');
    });

    test('测试获取基金基本信息 - 无效的基金代码', () async {
      // 测试一个无效的基金代码
      final fundInfo = await analyzer.getFundBasicInfo('999999');

      expect(fundInfo, isNull);
    });

    test('测试批量获取基金基本信息', () async {
      final fundCodes = ['005827', '110022', '161725'];
      final results = await analyzer.getBatchFundBasicInfo(fundCodes);

      expect(results, isNotEmpty);
      expect(results.length, greaterThan(0));

      results.forEach((code, info) {
        print('基金 $code: ${info['fund_name']}');
      });
    });

    test('测试搜索基金功能', () async {
      // 测试按基金代码搜索
      final codeResults = await analyzer.searchFunds('005', limit: 5);
      expect(codeResults, isNotEmpty);
      print('搜索 "005" 找到 ${codeResults.length} 个基金');

      // 测试按基金名称搜索
      final nameResults = await analyzer.searchFunds('易方达', limit: 5);
      expect(nameResults, isNotEmpty);
      print('搜索 "易方达" 找到 ${nameResults.length} 个基金');
    });

    test('测试API连通性', () async {
      final isConnected = await analyzer.validateApiConnection();
      expect(isConnected, isTrue);
      print('API连通性: ${isConnected ? "正常" : "异常"}');
    });

    test('测试API健康状态', () async {
      final healthStatus = await analyzer.getApiHealthStatus();

      expect(healthStatus, isNotEmpty);
      expect(healthStatus['status'], isNotEmpty);
      expect(healthStatus['lastChecked'], isNotEmpty);

      print('API状态: ${healthStatus['status']}');
      print('检查时间: ${healthStatus['lastChecked']}');

      if (healthStatus['status'] == 'healthy') {
        print('总基金数量: ${healthStatus['totalFunds']}');
        print('连接时间: ${healthStatus['connectionTime']}ms');
      }
    });

    test('测试API统计信息', () async {
      final statistics = await analyzer.getApiStatistics();

      if (statistics['status'] == 'success') {
        expect(statistics['totalFunds'], isA<int>());
        expect(statistics['responseTime'], isA<int>());
        expect(statistics['dataSize'], isA<int>());

        print('📊 API统计信息:');
        print('- 总基金数量: ${statistics['totalFunds']}');
        print('- 响应时间: ${statistics['responseTime']}ms');
        print('- 数据大小: ${statistics['dataSize']} bytes');

        if (statistics.containsKey('fundTypeDistribution')) {
          print('- 基金类型分布:');
          final distribution =
              statistics['fundTypeDistribution'] as Map<String, int>;
          distribution.forEach((type, count) {
            print('  • $type: $count 只');
          });
        }
      }
    });

    test('测试格式化统计信息', () async {
      final statistics = await analyzer.getApiStatistics();
      final formattedInfo = analyzer.formatStatisticsForDisplay(statistics);

      expect(formattedInfo, isNotEmpty);
      expect(formattedInfo, contains('基金API统计信息'));

      print('\n' + formattedInfo);
    });
  });
}
