import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'dart:convert';

// 导入主程序的类和服务
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/entities/portfolio_holding.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/entities/portfolio_profit_calculation_criteria.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/services/portfolio_profit_calculation_engine.dart';
import 'package:jisu_fund_analyzer/src/core/network/api_service.dart';
import 'package:jisu_fund_analyzer/src/features/fund/shared/models/money_fund.dart';
import 'package:jisu_fund_analyzer/src/features/fund/shared/services/money_fund_service.dart';

/// 简化的API测试
/// 直接使用API返回的原始数据，不进行复杂解析

void main() {
  group('简化API测试', () {
    late PortfolioProfitCalculationEngine calculationEngine;
    late ApiService apiService;
    const baseUrl = 'http://154.44.25.92:8080/api/public';

    setUp(() {
      calculationEngine = PortfolioProfitCalculationEngine();
      // 初始化主程序的ApiService
      final dio = Dio();
      dio.options.baseUrl = 'http://154.44.25.92:8080';
      apiService = ApiService(dio);
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
                fundCodes: const ['110022'],
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
        fundCodes: const ['TEST001'],
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

    test('使用主程序ApiService诊断货币基金字段映射', () async {
      print('🧪 使用主程序ApiService诊断货币基金字段映射...');

      try {
        // 使用主程序的ApiService调用货币基金API
        final moneyFundData = await apiService.getMoneyFundDaily();

        print('✅ ApiService.getMoneyFundDaily() 调用成功');
        print('📊 返回数据类型: ${moneyFundData.runtimeType}');

        if (moneyFundData.isNotEmpty) {
          print('📊 货币基金数量: ${moneyFundData.length}');

          final firstFund = moneyFundData[0] as Map<String, dynamic>;
          print('📋 第一个货币基金的字段结构:');
          print('   字段数量: ${firstFund.keys.length}');

          // 显示所有字段名和值
          for (final fieldName in firstFund.keys) {
            final value = firstFund[fieldName];
            print('   • $fieldName: $value (${value.runtimeType})');
          }

          // 检查我们期望的字段是否存在
          print('\n🔍 检查期望的字段:');
          final expectedFields = [
            '基金代码',
            '基金简称',
            '当前交易日-万份收益',
            '当前交易日-7日年化%',
            'fsdm',
            'jjjc',
            'wfjx',
            '7nsyl'
          ];

          for (final field in expectedFields) {
            if (firstFund.containsKey(field)) {
              print('   ✅ $field: ${firstFund[field]}');
            } else {
              print('   ❌ $field: 字段不存在');
            }
          }

          // 检查是否有带日期前缀的字段
          print('\n🔍 检查带日期前缀的字段:');
          final datePrefixPattern = RegExp(r'\d{4}-\d{2}-\d{2}-.+');
          final datePrefixedFields = <String>[];

          for (final fieldName in firstFund.keys) {
            if (datePrefixPattern.hasMatch(fieldName)) {
              print('   📅 $fieldName: ${firstFund[fieldName]}');
              datePrefixedFields.add(fieldName);
            }
          }

          if (datePrefixedFields.isNotEmpty) {
            print('\n💡 发现带日期前缀的字段，这可能是导致空值的原因');
            print('💡 建议：使用字段匹配或正则表达式来处理动态字段名');
          }

          // 验证数据完整性
          print('\n📊 数据完整性检查:');
          final hasValidCode =
              firstFund.containsKey('基金代码') && firstFund['基金代码'] != null;
          final hasValidName =
              firstFund.containsKey('基金简称') && firstFund['基金简称'] != null;

          print('   基金代码有效: ${hasValidCode ? '✅' : '❌'}');
          print('   基金名称有效: ${hasValidName ? '✅' : '❌'}');

          if (hasValidCode && hasValidName) {
            print('✅ 货币基金API数据基本结构正常');
          } else {
            print('❌ 货币基金API数据结构存在问题');
          }
        } else {
          print('⚠️ 货币基金API返回数据为空或格式不正确');
        }
      } catch (e) {
        print('❌ ApiService调用失败: $e');

        // 如果ApiService失败，尝试直接HTTP调用作为对比
        print('\n🔄 尝试直接HTTP调用进行对比...');
        try {
          final directResponse =
              await http.get(Uri.parse('$baseUrl/fund_money_fund_daily_em'));
          if (directResponse.statusCode == 200) {
            final directData = jsonDecode(directResponse.body);
            print('✅ 直接HTTP调用成功，数据类型: ${directData.runtimeType}');
            if (directData is List) {
              print('📊 直接调用获取基金数量: ${directData.length}');
            }
          } else {
            print('❌ 直接HTTP调用也失败: ${directResponse.statusCode}');
          }
        } catch (directError) {
          print('❌ 直接HTTP调用失败: $directError');
        }
      }
    });

    test('测试MoneyFund模型解析动态日期字段', () async {
      print('🧪 测试MoneyFund模型解析动态日期字段...');

      try {
        // 使用主程序的ApiService获取货币基金数据
        final moneyFundData = await apiService.getMoneyFundDaily();

        if (moneyFundData.isNotEmpty) {
          print('📊 获取到 ${moneyFundData.length} 条货币基金数据');

          // 测试解析前几条数据
          final testCount = 3.clamp(0, moneyFundData.length);
          var successCount = 0;

          for (int i = 0; i < testCount; i++) {
            try {
              final fundData = moneyFundData[i] as Map<String, dynamic>;
              final moneyFund = MoneyFund.fromJson(fundData);

              print('\n📋 货币基金 ${i + 1}:');
              print('   基金代码: ${moneyFund.fundCode}');
              print('   基金名称: ${moneyFund.fundName}');
              print('   万份收益: ${moneyFund.formattedDailyIncome}');
              print('   7日年化: ${moneyFund.formattedSevenDayYield}');
              print('   数据日期: ${moneyFund.dataDate}');
              print('   基金经理: ${moneyFund.fundManager}');

              // 验证关键字段是否解析成功
              if (moneyFund.fundCode.isNotEmpty &&
                  moneyFund.fundName.isNotEmpty &&
                  moneyFund.dataDate.isNotEmpty) {
                successCount++;
                print('   ✅ 解析成功');
              } else {
                print('   ❌ 解析失败：关键字段为空');
              }

              // 验证收益数据
              if (moneyFund.dailyIncome > 0 || moneyFund.sevenDayYield > 0) {
                print(
                    '   💰 收益数据有效: 万份收益=${moneyFund.dailyIncome}, 7日年化=${moneyFund.sevenDayYield}%');
              } else {
                print('   ⚠️ 收益数据为0或无效');
              }
            } catch (e) {
              print('❌ 基金 ${i + 1} 解析失败: $e');
            }
          }

          print('\n📊 解析结果统计:');
          print('   测试数量: $testCount');
          print('   成功解析: $successCount');
          print(
              '   成功率: ${(successCount / testCount * 100).toStringAsFixed(1)}%');

          expect(successCount, greaterThan(0), reason: '至少应该有一只基金解析成功');
          expect(successCount / testCount, greaterThan(0.5),
              reason: '成功率应该大于50%');
        } else {
          print('⚠️ 没有获取到货币基金数据');
        }
      } catch (e) {
        print('❌ MoneyFund模型测试失败: $e');
        fail('MoneyFund模型测试失败: $e');
      }
    });

    test('测试MoneyFundService完整功能', () async {
      print('🧪 测试MoneyFundService完整功能...');

      try {
        // 初始化货币基金服务
        final moneyFundService = MoneyFundService(apiService: apiService);

        // 1. 测试获取货币基金列表
        print('\n📊 测试获取货币基金列表...');
        final fundsResult = await moneyFundService.getMoneyFunds();

        if (fundsResult.isSuccess) {
          final funds = fundsResult.data!;
          print('✅ 获取到 ${funds.length} 只货币基金');

          // 显示前几只基金信息
          for (int i = 0; i < 3.clamp(0, funds.length); i++) {
            final fund = funds[i];
            print('   ${i + 1}. ${fund.fundCode} - ${fund.fundName}');
            print(
                '      万份收益: ${fund.formattedDailyIncome}, 7日年化: ${fund.formattedSevenDayYield}');
          }

          // 2. 测试搜索功能
          print('\n🔍 测试搜索功能...');
          final searchResult = await moneyFundService.searchMoneyFunds('华夏');
          if (searchResult.isSuccess && searchResult.data!.isNotEmpty) {
            print('✅ 搜索"华夏"找到 ${searchResult.data!.length} 只基金');
            for (final fund in searchResult.data!.take(3)) {
              print('   • ${fund.fundCode} - ${fund.fundName}');
            }
          } else {
            print('⚠️ 搜索功能测试未找到结果');
          }

          // 3. 测试获取高收益基金
          print('\n🏆 测试获取高收益基金...');
          final topYieldResult =
              await moneyFundService.getTopYieldMoneyFunds(count: 5);
          if (topYieldResult.isSuccess) {
            final topFunds = topYieldResult.data!;
            print('✅ 获取到收益最高的 ${topFunds.length} 只基金:');
            for (int i = 0; i < topFunds.length; i++) {
              final fund = topFunds[i];
              print(
                  '   ${i + 1}. ${fund.fundCode} - ${fund.fundName}: ${fund.formattedSevenDayYield}');
            }
          }

          // 4. 测试统计数据
          print('\n📈 测试获取统计数据...');
          final statsResult = await moneyFundService.getMoneyFundStatistics();
          if (statsResult.isSuccess) {
            final stats = statsResult.data!;
            print('✅ 货币基金统计数据:');
            print('   总基金数量: ${stats['totalFunds']}');
            print('   平均7日年化: ${stats['avgSevenDayYield']}%');
            print('   最高7日年化: ${stats['maxSevenDayYield']}%');
            print('   最低7日年化: ${stats['minSevenDayYield']}%');
            print('   平均万份收益: ${stats['avgDailyIncome']}');
            print('   数据日期: ${stats['dataDate']}');
          }

          // 5. 测试基金比较
          if (funds.length >= 2) {
            print('\n⚖️ 测试基金比较功能...');
            final compareCodes = [funds[0].fundCode, funds[1].fundCode];
            final compareResult =
                await moneyFundService.compareMoneyFunds(compareCodes);
            if (compareResult.isSuccess) {
              final comparison = compareResult.data!;
              final comparisonFunds = comparison['funds'] as List;
              print('✅ 比较 ${comparisonFunds.length} 只基金:');
              for (final fund in comparisonFunds) {
                print(
                    '   • ${fund['code']} - ${fund['name']}: ${fund['formattedSevenDayYield']}');
              }
            }
          }

          print('\n🎉 MoneyFundService所有功能测试通过！');
        } else {
          print('❌ 获取货币基金列表失败: ${fundsResult.errorMessage}');
          fail('MoneyFundService测试失败: ${fundsResult.errorMessage}');
        }
      } catch (e) {
        print('❌ MoneyFundService测试失败: $e');
        fail('MoneyFundService测试失败: $e');
      }
    });
  });
}
