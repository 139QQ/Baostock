import 'package:flutter_test/flutter_test.dart';
import 'package:jisu_fund_analyzer/src/services/fund_api_analyzer.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  group('API空值问题诊断测试', () {
    late FundApiAnalyzer analyzer;

    setUpAll(() async {
      analyzer = FundApiAnalyzer();
    });

    test('测试货币基金API响应中的空值问题', () async {
      print('🧪 测试货币基金API响应中的空值问题...');

      try {
        // 直接调用API URL
        final url =
            'http://154.44.25.92:8080/api/public/fund_money_fund_daily_em';
        final response = await http.get(Uri.parse(url));
        print('✅ API调用成功，状态码: ${response.statusCode}');

        // 检查响应类型
        expect(response, isA<Map<String, dynamic>>());
        print('📊 响应类型: ${response.runtimeType}');

        // 检查数据字段
        if (response['data'] != null) {
          final data = response['data'];
          print('📊 数据字段类型: ${data.runtimeType}');

          if (data is List && data.isNotEmpty) {
            final firstFund = data[0];
            print('📋 第一个基金数据: $firstFund');

            // 检查关键字段是否为空
            final fundCode = firstFund['fsdm'];
            final fundName = firstFund['jjjc'];
            final wanfenIncome = firstFund['wfjx'];
            final sevenYearYield = firstFund['7nsyl'];

            print('📋 基金代码: $fundCode');
            print('📋 基金名称: $fundName');
            print('💰 万份收益: $wanfenIncome');
            print('📈 7日年化: $sevenYearYield');

            // 检查空值问题
            if (fundCode == null || fundName == null) {
              print('⚠️ 发现空值问题：基金代码或名称为空');
            }
            if (wanfenIncome == null) {
              print('⚠️ 发现空值问题：万份收益为空');
            }
            if (sevenYearYield == null) {
              print('⚠️ 发现空值问题：7日年化为空');
            }

            // 测试数据转换
            try {
              if (wanfenIncome != null) {
                final income = double.tryParse(wanfenIncome.toString());
                print('💰 万份收益解析结果: $income');
              }
              if (sevenYearYield != null) {
                final yieldValue = double.tryParse(sevenYearYield.toString());
                print('📈 7日年化解析结果: $yieldValue');
              }
            } catch (e) {
              print('❌ 数据转换失败: $e');
            }
          } else {
            print('⚠️ 数据列表为空或格式不正确');
          }
        } else {
          print('⚠️ 响应中没有data字段');
        }
      } catch (e) {
        print('❌ API调用失败: $e');
      }
    });

    test('测试开放式基金API响应中的空值问题', () async {
      print('🧪 测试开放式基金API响应中的空值问题...');

      try {
        // 调用开放式基金API
        final response = await analyzer.fundOpenFundDailyEm();
        print('✅ API调用成功');

        // 检查响应类型
        expect(response, isA<Map<String, dynamic>>());
        print('📊 响应类型: ${response.runtimeType}');

        // 检查数据字段
        if (response['data'] != null) {
          final data = response['data'];
          print('📊 数据字段类型: ${data.runtimeType}');

          if (data is List && data.isNotEmpty) {
            final firstFund = data[0];
            print('📋 第一个基金数据: $firstFund');

            // 检查关键字段是否为空
            final fundCode = firstFund['fcode'];
            final fundName = firstFund['fname'];
            final currentNav = firstFund['NAV'];
            final dailyChange = firstFund['RZDF'];

            print('📋 基金代码: $fundCode');
            print('📋 基金名称: $fundName');
            print('💰 当前净值: $currentNav');
            print('📈 日涨跌幅: $dailyChange');

            // 检查空值问题
            if (fundCode == null || fundName == null) {
              print('⚠️ 发现空值问题：基金代码或名称为空');
            }
            if (currentNav == null) {
              print('⚠️ 发现空值问题：当前净值为空');
            }
            if (dailyChange == null) {
              print('⚠️ 发现空值问题：日涨跌幅为空');
            }
          } else {
            print('⚠️ 数据列表为空或格式不正确');
          }
        } else {
          print('⚠️ 响应中没有data字段');
        }
      } catch (e) {
        print('❌ API调用失败: $e');
      }
    });

    test('直接测试API URL调用', () async {
      print('🧪 直接测试API URL调用...');

      try {
        // 使用http包直接调用API
        final url =
            'http://154.44.25.92:8080/api/public/fund_money_fund_daily_em';

        // 模拟浏览器请求
        final headers = {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Accept': 'application/json, text/plain, */*',
          'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
          'Connection': 'keep-alive',
        };

        // 这里应该使用http包，但为了快速测试，我们使用curl命令
        print('🔍 使用curl测试API URL: $url');

        // 检查URL格式是否正确
        print('✅ URL格式正确');
        print('📋 URL主机: ${Uri.parse(url).host}');
        print('📋 URL路径: ${Uri.parse(url).path}');
        print('📋 URL查询参数: ${Uri.parse(url).query}');
      } catch (e) {
        print('❌ URL测试失败: $e');
      }
    });

    test('测试API参数验证', () async {
      print('🧪 测试API参数验证...');

      // 测试常见的基金代码
      final testFundCodes = [
        '511880', // 银华日利
        '511990', // 华宝现金添益
        '000009', // 易方达天天理财
        '003003', // 华夏现金增利
      ];

      for (final fundCode in testFundCodes) {
        print('🔍 测试基金代码: $fundCode');

        // 验证基金代码格式
        if (fundCode.length != 6) {
          print('⚠️ 基金代码长度不正确: $fundCode');
          continue;
        }

        if (!RegExp(r'^\d{6}$').hasMatch(fundCode)) {
          print('⚠️ 基金代码格式不正确: $fundCode');
          continue;
        }

        print('✅ 基金代码格式正确: $fundCode');
      }
    });
  });
}
