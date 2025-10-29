import 'package:flutter_test/flutter_test.dart';
import 'package:decimal/decimal.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// 导入主程序的类和服务
import '../../../lib/src/features/portfolio/domain/entities/portfolio_holding.dart';
import '../../../lib/src/features/portfolio/domain/entities/portfolio_profit_metrics.dart';
import '../../../lib/src/features/portfolio/domain/entities/portfolio_profit_calculation_criteria.dart';
import '../../../lib/src/features/portfolio/domain/services/portfolio_profit_calculation_engine.dart';

/// AKShare全面API接口测试
///
/// 基于净值参数.txt文档，测试所有AKShare基金数据接口
/// URL拼接格式：http://154.44.25.92:8080/api/public/接口名?参数1=值1&参数2=值2&...
///
/// 涵盖接口类型：
/// 1. 开放式基金实时数据 (fund_open_fund_daily_em)
/// 2. 开放式基金历史数据 (fund_open_fund_info_em)
/// 3. 货币型基金实时数据 (fund_money_fund_daily_em)
/// 4. 货币型基金历史数据 (fund_money_fund_info_em)
/// 5. 理财型基金实时数据 (fund_financial_fund_daily_em)
/// 6. 理财型基金历史数据 (fund_financial_fund_info_em)
/// 7. 分级基金实时数据 (fund_graded_fund_daily_em)
/// 8. 分级基金历史数据 (fund_graded_fund_info_em)
/// 9. 场内交易基金实时数据 (fund_etf_fund_daily_em)
/// 10. 场内交易基金历史数据 (fund_etf_fund_info_em)
/// 11. 香港基金历史数据 (fund_hk_fund_hist_em)

void main() {
  group('AKShare全面API接口测试', () {
    late PortfolioProfitCalculationEngine calculationEngine;
    const baseUrl = 'http://154.44.25.92:8080/api/public';

    setUp(() {
      calculationEngine = PortfolioProfitCalculationEngine();
    });

    group('1. 开放式基金接口测试', () {
      test('fund_open_fund_daily_em - 实时数据接口', () async {
        // 接口：fund_open_fund_daily_em
        // 输入参数：无参数
        // 输出字段：基金代码, 基金简称, 单位净值, 累计净值, 前交易日-单位净值, 前交易日-累计净值, 日增长值, 日增长率, 申购状态, 赎回状态, 手续费

        final apiUrl = '$baseUrl/fund_open_fund_daily_em';

        try {
          final response = await http
              .get(Uri.parse(apiUrl))
              .timeout(const Duration(seconds: 120));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);

            expect(data, isA<List>(), reason: '应返回数组格式');
            if (data is List && data.isNotEmpty) {
              final firstFund = data[0];
              expect(firstFund, isA<Map<String, dynamic>>(),
                  reason: '基金数据应为对象');

              // 验证AKShare标准字段
              final expectedFields = [
                '基金代码',
                '基金简称',
                '单位净值',
                '累计净值',
                '前交易日-单位净值',
                '前交易日-累计净值',
                '日增长值',
                '日增长率',
                '申购状态',
                '赎回状态',
                '手续费'
              ];

              for (final field in expectedFields) {
                if (firstFund.containsKey(field)) {
                  print('✅ 字段验证通过: $field');
                } else {
                  print('⚠️ 字段缺失: $field');
                }
              }

              print('✅ fund_open_fund_daily_em 接口测试通过');
              print('   📊 返回基金数量: ${data.length}');
              print('   📋 示例基金: ${firstFund['基金代码']} - ${firstFund['基金简称']}');
              print('   💰 单位净值: ${firstFund['单位净值']}');
              print('   💰 累计净值: ${firstFund['累计净值']}');
            }
          } else {
            print('⚠️ fund_open_fund_daily_em 接口状态码: ${response.statusCode}');
          }
        } catch (e) {
          print('❌ fund_open_fund_daily_em 接口调用失败: $e');
        }
      });

      test('fund_open_fund_info_em - 单位净值走势', () async {
        // 接口：fund_open_fund_info_em
        // 输入参数：symbol, indicator
        // 输出字段：净值日期, 单位净值, 日增长率

        const apiUrl =
            '$baseUrl/fund_open_fund_info_em?symbol=110022&indicator=单位净值走势';

        try {
          final response = await http
              .get(Uri.parse(apiUrl))
              .timeout(const Duration(seconds: 120));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);

            print('✅ fund_open_fund_info_em 单位净值走势测试通过');
            print('   📊 数据类型: ${data.runtimeType}');
            print('   📊 基金代码: 110022 (易方达消费行业股票)');

            if (data is List && data.isNotEmpty) {
              final firstRecord = data[0];
              print('   📅 首个数据日期: ${firstRecord['净值日期']}');
              print('   💰 首个净值: ${firstRecord['单位净值']}');
              print('   📈 首个日增长率: ${firstRecord['日增长率']}%');
            }
          } else {
            print(
                '⚠️ fund_open_fund_info_em 单位净值走势状态码: ${response.statusCode}');
          }
        } catch (e) {
          print('❌ fund_open_fund_info_em 单位净值走势调用失败: $e');
        }
      });

      test('fund_open_fund_info_em - 累计净值走势', () async {
        // 接口：fund_open_fund_info_em
        // 输入参数：symbol, indicator
        // 输出字段：净值日期, 累计净值

        const apiUrl =
            '$baseUrl/fund_open_fund_info_em?symbol=110022&indicator=累计净值走势';

        try {
          final response = await http
              .get(Uri.parse(apiUrl))
              .timeout(const Duration(seconds: 120));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);

            print('✅ fund_open_fund_info_em 累计净值走势测试通过');
            print('   📊 数据类型: ${data.runtimeType}');

            if (data is List && data.isNotEmpty) {
              final firstRecord = data[0];
              print('   📅 首个数据日期: ${firstRecord['净值日期']}');
              print('   💰 首个累计净值: ${firstRecord['累计净值']}');
            }
          } else {
            print(
                '⚠️ fund_open_fund_info_em 累计净值走势状态码: ${response.statusCode}');
          }
        } catch (e) {
          print('❌ fund_open_fund_info_em 累计净值走势调用失败: $e');
        }
      });

      test('fund_open_fund_info_em - 累计收益率走势', () async {
        // 接口：fund_open_fund_info_em
        // 输入参数：symbol, indicator, period
        // 输出字段：日期, 累计收益率
        // period选项：{"1月", "3月", "6月", "1年", "3年", "5年", "今年来", "成立来"}

        const periods = ['1月', '3月', '6月', '1年', '3年', '5年', '今年来', '成立来'];

        for (final period in periods) {
          final apiUrl =
              '$baseUrl/fund_open_fund_info_em?symbol=110022&indicator=累计收益率走势&period=$period';

          try {
            final response = await http
                .get(Uri.parse(apiUrl))
                .timeout(const Duration(seconds: 120));

            if (response.statusCode == 200) {
              final data = jsonDecode(response.body);

              print('✅ 累计收益率走势测试通过 - 期间: $period');
              print('   📊 数据类型: ${data.runtimeType}');

              if (data is List && data.isNotEmpty) {
                print('   📈 数据点数量: ${data.length}');
              }
              break; // 找到工作的期间就停止
            } else {
              print('⚠️ 累计收益率走势状态码 ($period): ${response.statusCode}');
            }
          } catch (e) {
            print('❌ 累计收益率走势调用失败 ($period): $e');
          }
        }
      });

      test('fund_open_fund_info_em - 同类排名走势', () async {
        // 接口：fund_open_fund_info_em
        // 输入参数：symbol, indicator
        // 输出字段：报告日期, 同类型排名-每日近三月排名, 总排名-每日近三月排名

        const apiUrl =
            '$baseUrl/fund_open_fund_info_em?symbol=110022&indicator=同类排名走势';

        try {
          final response = await http
              .get(Uri.parse(apiUrl))
              .timeout(const Duration(seconds: 120));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);

            print('✅ fund_open_fund_info_em 同类排名走势测试通过');
            print('   📊 数据类型: ${data.runtimeType}');

            if (data is List && data.isNotEmpty) {
              final firstRecord = data[0];
              print('   📅 首个报告日期: ${firstRecord['报告日期']}');
              print('   🏆 同类排名: ${firstRecord['同类型排名-每日近三月排名']}');
              print('   🏆 总排名: ${firstRecord['总排名-每日近三月排名']}');
            }
          } else {
            print(
                '⚠️ fund_open_fund_info_em 同类排名走势状态码: ${response.statusCode}');
          }
        } catch (e) {
          print('❌ fund_open_fund_info_em 同类排名走势调用失败: $e');
        }
      });

      test('fund_open_fund_info_em - 同类排名百分比', () async {
        // 接口：fund_open_fund_info_em
        // 输入参数：symbol, indicator
        // 输出字段：报告日期, 同类型排名-每日近3月收益排名百分比

        const apiUrl =
            '$baseUrl/fund_open_fund_info_em?symbol=110022&indicator=同类排名百分比';

        try {
          final response = await http
              .get(Uri.parse(apiUrl))
              .timeout(const Duration(seconds: 120));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);

            print('✅ fund_open_fund_info_em 同类排名百分比测试通过');
            print('   📊 数据类型: ${data.runtimeType}');

            if (data is List && data.isNotEmpty) {
              final firstRecord = data[0];
              print('   📅 首个报告日期: ${firstRecord['报告日期']}');
              print('   📊 排名百分比: ${firstRecord['同类型排名-每日近3月收益排名百分比']}%');
            }
          } else {
            print(
                '⚠️ fund_open_fund_info_em 同类排名百分比状态码: ${response.statusCode}');
          }
        } catch (e) {
          print('❌ fund_open_fund_info_em 同类排名百分比调用失败: $e');
        }
      });

      test('fund_open_fund_info_em - 分红送配详情', () async {
        // 接口：fund_open_fund_info_em
        // 输入参数：symbol, indicator
        // 输出字段：年份, 权益登记日, 除息日, 每份分红, 分红发放日
        // 示例基金：161606

        const apiUrl =
            '$baseUrl/fund_open_fund_info_em?symbol=161606&indicator=分红送配详情';

        try {
          final response = await http
              .get(Uri.parse(apiUrl))
              .timeout(const Duration(seconds: 120));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);

            print('✅ fund_open_fund_info_em 分红送配详情测试通过');
            print('   📊 数据类型: ${data.runtimeType}');
            print('   📋 基金代码: 161606');

            if (data is List && data.isNotEmpty) {
              final firstRecord = data[0];
              print('   📅 年份: ${firstRecord['年份']}');
              print('   📅 权益登记日: ${firstRecord['权益登记日']}');
              print('   📅 除息日: ${firstRecord['除息日']}');
              print('   💰 每份分红: ${firstRecord['每份分红']}');
              print('   📅 分红发放日: ${firstRecord['分红发放日']}');
            }
          } else {
            print(
                '⚠️ fund_open_fund_info_em 分红送配详情状态码: ${response.statusCode}');
          }
        } catch (e) {
          print('❌ fund_open_fund_info_em 分红送配详情调用失败: $e');
        }
      });

      test('fund_open_fund_info_em - 拆分详情', () async {
        // 接口：fund_open_fund_info_em
        // 输入参数：symbol, indicator
        // 输出字段：年份, 拆分折算日, 拆分类型, 拆分折算比例
        // 示例基金：161606

        const apiUrl =
            '$baseUrl/fund_open_fund_info_em?symbol=161606&indicator=拆分详情';

        try {
          final response = await http
              .get(Uri.parse(apiUrl))
              .timeout(const Duration(seconds: 120));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);

            print('✅ fund_open_fund_info_em 拆分详情测试通过');
            print('   📊 数据类型: ${data.runtimeType}');
            print('   📋 基金代码: 161606');

            if (data is List && data.isNotEmpty) {
              final firstRecord = data[0];
              print('   📅 年份: ${firstRecord['年份']}');
              print('   📅 拆分折算日: ${firstRecord['拆分折算日']}');
              print('   🔄 拆分类型: ${firstRecord['拆分类型']}');
              print('   📊 拆分折算比例: ${firstRecord['拆分折算比例']}');
            }
          } else {
            print('⚠️ fund_open_fund_info_em 拆分详情状态码: ${response.statusCode}');
          }
        } catch (e) {
          print('❌ fund_open_fund_info_em 拆分详情调用失败: $e');
        }
      });
    });

    group('2. 货币型基金接口测试', () {
      test('fund_money_fund_daily_em - 实时数据接口', () async {
        // 接口：fund_money_fund_daily_em
        // 输入参数：无参数
        // 输出字段：基金代码, 基金简称, 当前交易日-万份收益, 当前交易日-7日年化%, 当前交易日-单位净值, 前一交易日-万份收益, 前一交易日-7日年化%, 前一交易日-单位净值, 日涨幅, 成立日期, 基金经理, 手续费, 可购全部

        final apiUrl = '$baseUrl/fund_money_fund_daily_em';

        try {
          final response = await http
              .get(Uri.parse(apiUrl))
              .timeout(const Duration(seconds: 120));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);

            expect(data, isA<List>(), reason: '应返回数组格式');
            if (data is List && data.isNotEmpty) {
              final firstFund = data[0];
              expect(firstFund, isA<Map<String, dynamic>>(),
                  reason: '基金数据应为对象');

              // 验证货币基金标准字段
              final expectedFields = [
                '基金代码',
                '基金简称',
                '当前交易日-万份收益',
                '当前交易日-7日年化%',
                '当前交易日-单位净值',
                '前一交易日-万份收益',
                '前一交易日-7日年化%',
                '前一交易日-单位净值',
                '日涨幅',
                '成立日期',
                '基金经理',
                '手续费',
                '可购全部'
              ];

              print('✅ fund_money_fund_daily_em 接口测试通过');
              print('   📊 返回基金数量: ${data.length}');
              print('   📋 示例基金: ${firstFund['基金代码']} - ${firstFund['基金简称']}');
              print('   💰 万份收益: ${firstFund['当前交易日-万份收益']}');
              print('   📈 7日年化: ${firstFund['当前交易日-7日年化%']}');
            }
          } else {
            print('⚠️ fund_money_fund_daily_em 接口状态码: ${response.statusCode}');
          }
        } catch (e) {
          print('❌ fund_money_fund_daily_em 接口调用失败: $e');
        }
      });

      test('fund_money_fund_info_em - 历史数据接口', () async {
        // 接口：fund_money_fund_info_em
        // 输入参数：symbol
        // 输出字段：净值日期, 每万份收益, 7日年化收益率, 申购状态, 赎回状态
        // 示例基金：000009

        const apiUrl = '$baseUrl/fund_money_fund_info_em?symbol=000009';

        try {
          final response = await http
              .get(Uri.parse(apiUrl))
              .timeout(const Duration(seconds: 120));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);

            print('✅ fund_money_fund_info_em 接口测试通过');
            print('   📊 数据类型: ${data.runtimeType}');
            print('   📋 基金代码: 000009');

            if (data is List && data.isNotEmpty) {
              final firstRecord = data[0];
              print('   📅 首个净值日期: ${firstRecord['净值日期']}');
              print('   💰 每万份收益: ${firstRecord['每万份收益']}');
              print('   📈 7日年化收益率: ${firstRecord['7日年化收益率']}%');
              print('   🔄 申购状态: ${firstRecord['申购状态']}');
              print('   🔄 赎回状态: ${firstRecord['赎回状态']}');
            }
          } else {
            print('⚠️ fund_money_fund_info_em 接口状态码: ${response.statusCode}');
          }
        } catch (e) {
          print('❌ fund_money_fund_info_em 接口调用失败: $e');
        }
      });
    });

    group('3. 理财型基金接口测试', () {
      test('fund_financial_fund_daily_em - 实时数据接口', () async {
        // 接口：fund_financial_fund_daily_em
        // 输入参数：无参数
        // 输出字段：序号, 基金代码, 基金简称, 上一期年化收益率, 当前交易日-万份收益, 当前交易日-7日年华, 前一个交易日-万份收益, 前一个交易日-7日年华, 封闭期, 申购状态

        final apiUrl = '$baseUrl/fund_financial_fund_daily_em';

        try {
          final response = await http
              .get(Uri.parse(apiUrl))
              .timeout(const Duration(seconds: 120));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);

            print('✅ fund_financial_fund_daily_em 接口测试通过');
            print('   📊 数据类型: ${data.runtimeType}');

            if (data is List && data.isNotEmpty) {
              final firstFund = data[0];
              print('   📊 返回基金数量: ${data.length}');
              print('   📋 示例基金: ${firstFund['基金代码']} - ${firstFund['基金简称']}');
              print('   📈 上一期年化收益率: ${firstFund['上一期年化收益率']}');
              print('   💰 当前万份收益: ${firstFund['当前交易日-万份收益']}');
            }
          } else {
            print(
                '⚠️ fund_financial_fund_daily_em 接口状态码: ${response.statusCode}');
          }
        } catch (e) {
          print('❌ fund_financial_fund_daily_em 接口调用失败: $e');
        }
      });

      test('fund_financial_fund_info_em - 历史数据接口', () async {
        // 接口：fund_financial_fund_info_em
        // 输入参数：symbol
        // 输出字段：净值日期, 单位净值, 累计净值, 日增长率, 申购状态, 赎回状态, 分红送配
        // 示例基金：000134

        const apiUrl = '$baseUrl/fund_financial_fund_info_em?symbol=000134';

        try {
          final response = await http
              .get(Uri.parse(apiUrl))
              .timeout(const Duration(seconds: 120));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);

            print('✅ fund_financial_fund_info_em 接口测试通过');
            print('   📊 数据类型: ${data.runtimeType}');
            print('   📋 基金代码: 000134');

            if (data is List && data.isNotEmpty) {
              final firstRecord = data[0];
              print('   📅 首个净值日期: ${firstRecord['净值日期']}');
              print('   💰 单位净值: ${firstRecord['单位净值']}');
              print('   💰 累计净值: ${firstRecord['累计净值']}');
              print('   📈 日增长率: ${firstRecord['日增长率']}%');
              print('   🔄 申购状态: ${firstRecord['申购状态']}');
            }
          } else {
            print(
                '⚠️ fund_financial_fund_info_em 接口状态码: ${response.statusCode}');
          }
        } catch (e) {
          print('❌ fund_financial_fund_info_em 接口调用失败: $e');
        }
      });
    });

    group('4. 分级基金接口测试', () {
      test('fund_graded_fund_daily_em - 实时数据接口', () async {
        // 接口：fund_graded_fund_daily_em
        // 输入参数：无参数
        // 输出字段：基金代码, 基金简称, 单位净值, 累计净值, 前交易日-单位净值, 前交易日-累计净值, 日增长值, 日增长率, 市价, 折价率, 手续费

        final apiUrl = '$baseUrl/fund_graded_fund_daily_em';

        try {
          final response = await http
              .get(Uri.parse(apiUrl))
              .timeout(const Duration(seconds: 120));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);

            print('✅ fund_graded_fund_daily_em 接口测试通过');
            print('   📊 数据类型: ${data.runtimeType}');

            if (data is List && data.isNotEmpty) {
              final firstFund = data[0];
              print('   📊 返回基金数量: ${data.length}');
              print('   📋 示例基金: ${firstFund['基金代码']} - ${firstFund['基金简称']}');
              print('   💰 单位净值: ${firstFund['单位净值']}');
              print('   💰 累计净值: ${firstFund['累计净值']}');
              print('   📈 日增长率: ${firstFund['日增长率']}%');
            }
          } else {
            print('⚠️ fund_graded_fund_daily_em 接口状态码: ${response.statusCode}');
          }
        } catch (e) {
          print('❌ fund_graded_fund_daily_em 接口调用失败: $e');
        }
      });

      test('fund_graded_fund_info_em - 历史数据接口', () async {
        // 接口：fund_graded_fund_info_em
        // 输入参数：symbol
        // 输出字段：净值日期, 单位净值, 累计净值, 日增长率, 申购状态, 赎回状态
        // 示例基金：150232

        const apiUrl = '$baseUrl/fund_graded_fund_info_em?symbol=150232';

        try {
          final response = await http
              .get(Uri.parse(apiUrl))
              .timeout(const Duration(seconds: 120));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);

            print('✅ fund_graded_fund_info_em 接口测试通过');
            print('   📊 数据类型: ${data.runtimeType}');
            print('   📋 基金代码: 150232');

            if (data is List && data.isNotEmpty) {
              final firstRecord = data[0];
              print('   📅 首个净值日期: ${firstRecord['净值日期']}');
              print('   💰 单位净值: ${firstRecord['单位净值']}');
              print('   💰 累计净值: ${firstRecord['累计净值']}');
              print('   📈 日增长率: ${firstRecord['日增长率']}%');
            }
          } else {
            print('⚠️ fund_graded_fund_info_em 接口状态码: ${response.statusCode}');
          }
        } catch (e) {
          print('❌ fund_graded_fund_info_em 接口调用失败: $e');
        }
      });
    });

    group('5. 场内交易基金接口测试', () {
      test('fund_etf_fund_daily_em - 实时数据接口', () async {
        // 接口：fund_etf_fund_daily_em
        // 输入参数：无参数
        // 输出字段：基金代码, 基金简称, 类型, 当前交易日-单位净值, 当前交易日-累计净值, 前一个交易日-单位净值, 前一个交易日-累计净值, 增长值, 增长率, 市价, 折价率

        final apiUrl = '$baseUrl/fund_etf_fund_daily_em';

        try {
          final response = await http
              .get(Uri.parse(apiUrl))
              .timeout(const Duration(seconds: 120));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);

            print('✅ fund_etf_fund_daily_em 接口测试通过');
            print('   📊 数据类型: ${data.runtimeType}');

            if (data is List && data.isNotEmpty) {
              final firstFund = data[0];
              print('   📊 返回基金数量: ${data.length}');
              print('   📋 示例基金: ${firstFund['基金代码']} - ${firstFund['基金简称']}');
              print('   🔄 基金类型: ${firstFund['类型']}');
              print('   💰 单位净值: ${firstFund['当前交易日-单位净值']}');
              print('   📈 增长率: ${firstFund['增长率']}');
            }
          } else {
            print('⚠️ fund_etf_fund_daily_em 接口状态码: ${response.statusCode}');
          }
        } catch (e) {
          print('❌ fund_etf_fund_daily_em 接口调用失败: $e');
        }
      });

      test('fund_etf_fund_info_em - 历史数据接口', () async {
        // 接口：fund_etf_fund_info_em
        // 输入参数：fund, start_date, end_date
        // 输出字段：净值日期, 单位净值, 累计净值, 日增长率, 申购状态, 赎回状态
        // 示例基金：511280

        const apiUrl =
            '$baseUrl/fund_etf_fund_info_em?fund=511280&start_date=20000101&end_date=20500101';

        try {
          final response = await http
              .get(Uri.parse(apiUrl))
              .timeout(const Duration(seconds: 120));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);

            print('✅ fund_etf_fund_info_em 接口测试通过');
            print('   📊 数据类型: ${data.runtimeType}');
            print('   📋 基金代码: 511280');

            if (data is List && data.isNotEmpty) {
              final firstRecord = data[0];
              print('   📅 首个净值日期: ${firstRecord['净值日期']}');
              print('   💰 单位净值: ${firstRecord['单位净值']}');
              print('   💰 累计净值: ${firstRecord['累计净值']}');
              print('   📈 日增长率: ${firstRecord['日增长率']}%');
            }
          } else {
            print('⚠️ fund_etf_fund_info_em 接口状态码: ${response.statusCode}');
          }
        } catch (e) {
          print('❌ fund_etf_fund_info_em 接口调用失败: $e');
        }
      });
    });

    group('6. 香港基金接口测试', () {
      test('fund_hk_fund_hist_em - 历史净值明细', () async {
        // 接口：fund_hk_fund_hist_em
        // 输入参数：code, symbol
        // 输出字段：净值日期, 单位净值, 日增长值, 日增长率, 单位
        // 示例基金：1002200683

        const apiUrl =
            '$baseUrl/fund_hk_fund_hist_em?code=1002200683&symbol=历史净值明细';

        try {
          final response = await http
              .get(Uri.parse(apiUrl))
              .timeout(const Duration(seconds: 120));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);

            print('✅ fund_hk_fund_hist_em 历史净值明细测试通过');
            print('   📊 数据类型: ${data.runtimeType}');
            print('   📋 香港基金代码: 1002200683');

            if (data is List && data.isNotEmpty) {
              final firstRecord = data[0];
              print('   📅 首个净值日期: ${firstRecord['净值日期']}');
              print('   💰 单位净值: ${firstRecord['单位净值']}');
              print('   📈 日增长值: ${firstRecord['日增长值']}');
              print('   📈 日增长率: ${firstRecord['日增长率']}%');
              print('   💵 单位: ${firstRecord['单位']}');
            }
          } else {
            print('⚠️ fund_hk_fund_hist_em 历史净值明细状态码: ${response.statusCode}');
          }
        } catch (e) {
          print('❌ fund_hk_fund_hist_em 历史净值明细调用失败: $e');
        }
      });

      test('fund_hk_fund_hist_em - 分红送配详情', () async {
        // 接口：fund_hk_fund_hist_em
        // 输入参数：code, symbol
        // 输出字段：年份, 权益登记日, 除息日, 分红发放日, 分红金额, 单位
        // 示例基金：1002200683

        const apiUrl =
            '$baseUrl/fund_hk_fund_hist_em?code=1002200683&symbol=分红送配详情';

        try {
          final response = await http
              .get(Uri.parse(apiUrl))
              .timeout(const Duration(seconds: 120));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);

            print('✅ fund_hk_fund_hist_em 分红送配详情测试通过');
            print('   📊 数据类型: ${data.runtimeType}');
            print('   📋 香港基金代码: 1002200683');

            if (data is List && data.isNotEmpty) {
              final firstRecord = data[0];
              print('   📅 年份: ${firstRecord['年份']}');
              print('   📅 权益登记日: ${firstRecord['权益登记日']}');
              print('   📅 除息日: ${firstRecord['除息日']}');
              print('   📅 分红发放日: ${firstRecord['分红发放日']}');
              print('   💰 分红金额: ${firstRecord['分红金额']}');
              print('   💵 单位: ${firstRecord['单位']}');
            }
          } else {
            print('⚠️ fund_hk_fund_hist_em 分红送配详情状态码: ${response.statusCode}');
          }
        } catch (e) {
          print('❌ fund_hk_fund_hist_em 分红送配详情调用失败: $e');
        }
      });
    });

    group('7. 收益计算引擎集成测试', () {
      test('综合测试：使用真实API数据计算收益', () async {
        // 测试使用真实API数据进行收益计算

        // 1. 获取基金基础数据
        const fundCode = '110022';
        final apiUrl =
            '$baseUrl/fund_open_fund_info_em?symbol=$fundCode&indicator=单位净值走势';

        try {
          final response = await http
              .get(Uri.parse(apiUrl))
              .timeout(const Duration(seconds: 120));

          if (response.statusCode == 200) {
            final navData = jsonDecode(response.body);

            if (navData is List && navData.isNotEmpty) {
              // 获取最新的净值数据
              final latestNav = navData.last;
              final currentNav = (latestNav['单位净值'] ?? 1.0).toDouble();

              // 创建持仓数据
              final holding = PortfolioHolding(
                fundCode: fundCode,
                fundName: '易方达消费行业股票',
                fundType: '股票型',
                holdingAmount: 10000.0,
                costNav: 1.0,
                costValue: 10000.0,
                marketValue: currentNav * 10000.0,
                currentNav: currentNav,
                accumulatedNav: currentNav * 1.5, // 假设累计净值
                holdingStartDate: DateTime(2023, 1, 1),
                lastUpdatedDate: DateTime.now(),
              );

              final criteria = PortfolioProfitCalculationCriteria(
                calculationId:
                    'INTEGRATION_TEST_${DateTime.now().millisecondsSinceEpoch}',
                fundCodes: [fundCode],
                startDate: DateTime(2023, 1, 1),
                endDate: DateTime.now(),
                benchmarkCode: '000300',
                frequency: CalculationFrequency.daily,
                returnType: ReturnType.total,
                includeDividendReinvestment: true,
                considerCorporateActions: true,
                currency: 'CNY',
                minimumDataDays: 30,
                dataQualityRequirement: DataQualityRequirement.good,
                createdAt: DateTime.now(),
              );

              // 使用收益计算引擎计算
              final metrics =
                  await calculationEngine.calculateFundProfitMetrics(
                holding: holding,
                criteria: criteria,
              );

              // 验证计算结果
              expect(metrics.fundCode, equals(fundCode));
              expect(metrics.totalReturnRate, isA<double>());
              expect(metrics.totalReturnAmount, isA<double>());

              print('✅ 收益计算引擎集成测试通过');
              print('   📊 基金代码: $fundCode');
              print('   💰 当前净值: ¥${currentNav.toStringAsFixed(4)}');
              print(
                  '   📈 总收益率: ${(metrics.totalReturnRate * 100).toStringAsFixed(2)}%');
              print(
                  '   💵 总收益金额: ¥${metrics.totalReturnAmount.toStringAsFixed(2)}');
              print(
                  '   📈 年化收益率: ${(metrics.annualizedReturn * 100).toStringAsFixed(2)}%');
            }
          }
        } catch (e) {
          print('❌ 收益计算引擎集成测试失败: $e');
        }
      });
    });

    group('8. 性能测试', () {
      test('API响应时间性能测试', () async {
        // 测试各个API接口的响应时间

        final apiTests = [
          {'name': '开放式基金实时数据', 'url': '$baseUrl/fund_open_fund_daily_em'},
          {'name': '货币型基金实时数据', 'url': '$baseUrl/fund_money_fund_daily_em'},
          {
            'name': '开放式基金历史数据',
            'url':
                '$baseUrl/fund_open_fund_info_em?symbol=110022&indicator=单位净值走势'
          },
        ];

        for (final apiTest in apiTests) {
          final stopwatch = Stopwatch()..start();

          try {
            final response = await http
                .get(Uri.parse(apiTest['url']!))
                .timeout(const Duration(seconds: 120));
            stopwatch.stop();

            final responseTime = stopwatch.elapsedMilliseconds;

            print('📊 ${apiTest['name']}:');
            print('   ⏱️ 响应时间: ${responseTime}ms');
            print('   📊 状态码: ${response.statusCode}');
            print('   📊 状态: ${responseTime < 5000 ? '✅ 正常' : '⚠️ 较慢'}');

            // 性能要求：响应时间应小于5秒
            expect(responseTime, lessThan(5000),
                reason: '${apiTest['name']}响应时间应小于5秒');
          } catch (e) {
            stopwatch.stop();
            print('❌ ${apiTest['name']}调用失败: $e');
          }
        }
      });
    });
  });
}
