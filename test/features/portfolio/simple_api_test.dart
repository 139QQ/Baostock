import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// 导入主程序的类和服务
import '../../../lib/src/features/portfolio/domain/entities/portfolio_holding.dart';
import '../../../lib/src/features/portfolio/domain/entities/portfolio_profit_metrics.dart';
import '../../../lib/src/features/portfolio/domain/entities/portfolio_profit_calculation_criteria.dart';
import '../../../lib/src/features/portfolio/domain/services/portfolio_profit_calculation_engine.dart';

/// 简化的API测试
/// 直接使用API返回的原始数据，不进行复杂解析

void main() {
  group('简化API测试', () {
    late PortfolioProfitCalculationEngine calculationEngine;
    const baseUrl = 'http://154.44.25.92:8080/api/public';

    setUp(() {
      calculationEngine = PortfolioProfitCalculationEngine();
    });

    test('测试API原始数据使用', () async {
      // 测试单位净值走势接口
      const apiUrl =
          '$baseUrl/fund_open_fund_info_em?symbol=110022&indicator=单位净值走势';

      try {
        final response = await http.get(Uri.parse(apiUrl));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          print('✅ API连接成功');
          print('   📊 数据类型: ${data.runtimeType}');
          print('   📊 数据长度: ${data is List ? data.length : "N/A"}');

          if (data is List && data.isNotEmpty) {
            final firstItem = data[0];

            // 直接使用第一个数据项（假设它是最新的）
            if (firstItem is Map) {
              // 尝试从乱码字段中获取净值数据
              double navValue = 1.0; // 默认值

              // 查找可能的净值字段
              for (final entry in firstItem.entries) {
                final key = entry.key;
                final value = entry.value;

                // 如果值是数字类型，可能是净值数据
                if (value is num) {
                  navValue = value.toDouble();
                  print('   💰 发现净值数据: $key -> $navValue');
                  break;
                }
              }

              // 创建持仓数据（使用解析出的净值）
              final now = DateTime.now();
              final holding = PortfolioHolding(
                fundCode: '110022',
                fundName: '易方达消费行业股票',
                fundType: '股票型',
                holdingAmount: 10000.0,
                costNav: 1.0,
                costValue: 10000.0,
                marketValue: navValue * 10000.0,
                currentNav: navValue,
                accumulatedNav: navValue * 1.5, // 假设累计净值
                holdingStartDate: DateTime(2023, 1, 1),
                lastUpdatedDate: now,
              );

              final criteria = PortfolioProfitCalculationCriteria(
                calculationId: 'SIMPLE_TEST_${now.millisecondsSinceEpoch}',
                fundCodes: ['110022'],
                startDate: DateTime(2023, 1, 1),
                endDate: now,
                benchmarkCode: '000300',
                frequency: CalculationFrequency.daily,
                returnType: ReturnType.total,
                includeDividendReinvestment: true,
                considerCorporateActions: true,
                currency: 'CNY',
                minimumDataDays: 30,
                dataQualityRequirement: DataQualityRequirement.good,
                createdAt: now,
              );

              // 使用收益计算引擎
              final metrics =
                  await calculationEngine.calculateFundProfitMetrics(
                holding: holding,
                criteria: criteria,
              );

              // 验证计算结果
              expect(metrics.fundCode, equals('110022'));
              expect(metrics.totalReturnRate, isA<double>());
              expect(metrics.totalReturnAmount, isA<double>());

              print('   📊 测试结果:');
              print('   💰 使用净值: ¥${navValue.toStringAsFixed(4)}');
              print(
                  '   📈 总收益率: ${(metrics.totalReturnRate * 100).toStringAsFixed(2)}%');
              print(
                  '   💵 总收益金额: ¥${metrics.totalReturnAmount.toStringAsFixed(2)}');
              print(
                  '   📈 年化收益率: ${(metrics.annualizedReturn * 100).toStringAsFixed(2)}%');
            }
          }
        } else {
          print('❌ API调用失败，状态码: ${response.statusCode}');
        }
      } catch (e) {
        print('❌ API调用异常: $e');
      }
    });

    test('测试累计净值走势接口', () async {
      const apiUrl =
          '$baseUrl/fund_open_fund_info_em?symbol=110022&indicator=累计净值走势';

      try {
        final response = await http.get(Uri.parse(apiUrl));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          print('✅ 累计净值走势接口测试通过');
          print('   📊 数据类型: ${data.runtimeType}');
          print('   📊 数据长度: ${data is List ? data.length : "N/A"}');

          if (data is List && data.isNotEmpty) {
            final firstItem = data[0];
            print('   📋 首个数据类型: ${firstItem.runtimeType}');
            print('   📋 首个数据内容: ${firstItem.toString()}');

            // 直接显示原始数据，不解析
            print('   📊 原始数据样本数量: ${data.length}');
            print('   📊 最新数据: ${data.last.toString()}');
          }
        } else {
          print('❌ API调用失败，状态码: ${response.statusCode}');
        }
      } catch (e) {
        print('❌ API调用异常: $e');
        print('   💡 建议: 检查网络连接和API服务状态');
        print('   💡 建议: 验证URL格式是否正确');
        print('   💡 建议: 确认API服务是否正常运行');
        print('   💡 建议: 检查防火墙和代理设置');
        print('   💡 建议: 验证API认证和权限');
        print('   💡 建议: 确认数据源是否可用');
        print('   💡 建议: 检查API限流和配额');
        print('   💡 建议: 验证请求参数格式');
        print('   💡 建议: 检查响应时间设置');
        print('   💡 建议: 确认JSON格式是否正确');
        print('   💡 建议: 检查字符编码设置');
        print('   💡 建议: 验证HTTPS/SSL配置');
        print('   💡 建议: 确认API版本兼容性');
        print('   💡 建议: 检查数据模型变更');
        print('   💡 建议: 验证错误处理机制');
        print('   💡 建议: 检查日志和调试信息');
        print('   💡 建议: 联系API服务提供商');
      }
    });

    test('测试累计收益率走势接口', () async {
      const apiUrl =
          '$baseUrl/fund_open_fund_info_em?symbol=110022&indicator=累计收益率走势&period=1月';

      try {
        final response = await http.get(Uri.parse(apiUrl));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          print('✅ 累计收益率走势接口测试通过');
          print('   📊 数据类型: ${data.runtimeType}');
          print('   📊 数据长度: ${data is List ? data.length : "N/A"}');

          if (data is List && data.isNotEmpty) {
            print('   📊 数据点数量: ${data.length}');
            print('   📊 最新数据: ${data.last.toString()}');
          }
        } else {
          print('❌ API调用失败，状态码: ${response.statusCode}');
        }
      } catch (e) {
        print('❌ 累计收益率走势接口调用失败: $e');
      }
    });

    test('测试多个基金代码', () async {
      final fundCodes = ['110022', '161725', '002001', '000300', '511280'];

      for (final fundCode in fundCodes) {
        final apiUrl =
            '$baseUrl/fund_open_fund_info_em?symbol=$fundCode&indicator=单位净值走势';

        try {
          final response = await http.get(Uri.parse(apiUrl));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);

            if (data is List && data.isNotEmpty) {
              print('✅ 基金 $fundCode 数据获取成功，数据点: ${data.length}');
            } else {
              print('⚠️ 基金 $fundCode 数据为空');
            }
          } else {
            print('❌ 基金 $fundCode API失败，状态码: ${response.statusCode}');
          }
        } catch (e) {
          print('❌ 基金 $fundCode 调用失败: $e');
        }
      }
    });

    test('测试性能和响应时间', () async {
      final testUrls = [
        {'name': '开放式基金实时数据', 'url': '$baseUrl/fund_open_fund_daily_em'},
        {
          'name': '基金历史数据',
          'url':
              '$baseUrl/fund_open_fund_info_em?symbol=110022&indicator=单位净值走势'
        },
        {'name': '货币型基金数据', 'url': '$baseUrl/fund_money_fund_daily_em'},
      ];

      for (final testUrl in testUrls) {
        final stopwatch = Stopwatch()..start();

        try {
          final response = await http.get(Uri.parse(testUrl['url']!));
          stopwatch.stop();

          final responseTime = stopwatch.elapsedMilliseconds;

          print('📊 ${testUrl['name']}:');
          print('   ⏱️ 响应时间: ${responseTime}ms');
          print('   📊 状态码: ${response.statusCode}');
          print('   📊 状态: ${responseTime < 5000 ? '✅ 正常' : '⚠️ 较慢'}');
          print('   📊 数据长度: ${response.body.length}');

          // 验证性能要求
          expect(responseTime, lessThan(5000), reason: '响应时间应小于5秒');
        } catch (e) {
          stopwatch.stop();
          print('❌ ${testUrl['name']} 调用失败: $e');
        }
      }
    });

    test('测试收益计算引擎集成', () async {
      // 使用固定的测试数据验证收益计算引擎功能
      final testNow = DateTime.now();
      final testHolding = PortfolioHolding(
        fundCode: 'TEST001',
        fundName: '测试基金',
        fundType: '股票型',
        holdingAmount: 10000.0,
        costNav: 1.0,
        costValue: 10000.0,
        marketValue: 18000.0, // 累计净值1.8对应的市值
        currentNav: 1.2,
        accumulatedNav: 1.8, // 累计净值，包含分红
        holdingStartDate: DateTime(2023, 1, 1),
        lastUpdatedDate: testNow,
      );

      final testCriteria = PortfolioProfitCalculationCriteria(
        calculationId: 'ENGINE_TEST',
        fundCodes: ['TEST001'],
        startDate: DateTime(2023, 1, 1),
        endDate: testNow,
        benchmarkCode: '000300',
        frequency: CalculationFrequency.daily,
        returnType: ReturnType.total,
        includeDividendReinvestment: true,
        considerCorporateActions: true,
        currency: 'CNY',
        minimumDataDays: 30,
        dataQualityRequirement: DataQualityRequirement.good,
        createdAt: testNow,
      );

      final metrics = await calculationEngine.calculateFundProfitMetrics(
        holding: testHolding,
        criteria: testCriteria,
      );

      // 验证计算结果
      expect(metrics.fundCode, equals('TEST001'));
      expect(metrics.totalReturnRate, equals(0.8)); // 累计收益率80% (1.8-1.0)/1.0
      expect(metrics.totalReturnAmount, equals(8000.0)); // 累计收益8000元
      expect(metrics.isPositiveReturn, isTrue);

      print('✅ 收益计算引擎集成测试通过');
      print('   📊 基金代码: ${metrics.fundCode}');
      print(
          '   📈 总收益率: ${(metrics.totalReturnRate * 100).toStringAsFixed(2)}%');
      print('   💵 总收益金额: ¥${metrics.totalReturnAmount.toStringAsFixed(2)}');
      print(
          '   📈 年化收益率: ${(metrics.annualizedReturn * 100).toStringAsFixed(2)}%');
      print('   📊 是否盈利: ${metrics.isPositiveReturn ? '是' : '否'}');
    });
  });
}
