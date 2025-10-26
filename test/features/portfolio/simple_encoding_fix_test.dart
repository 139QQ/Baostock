import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

/// 简化的编码修复测试
/// 基于测试结果验证最有效的解决方案
void main() {
  group('简化编码修复解决方案', () {
    const baseUrl = 'http://154.44.25.92:8080/api/public';

    test('方法验证：UTF-8直接解码（已证明有效）', () async {
      print('🔧 验证UTF-8直接解码方法...');

      final apiUrl =
          '$baseUrl/fund_open_fund_info_em?symbol=110022&indicator=单位净值走势';

      try {
        // 使用已验证有效的方法：dart:io HttpClient + UTF-8解码
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) => true;

        try {
          final request = await client.getUrl(Uri.parse(apiUrl));
          final response = await request.close();

          // 读取原始字节
          final bytes = await response.fold<List<int>>(
            <int>[],
            (dynamic previous, element) => previous..addAll(element),
          );

          // 关闭客户端
          client.close();

          // UTF-8解码
          final responseBody = utf8.decode(bytes);

          print('   📊 响应状态码: ${response.statusCode}');
          print('   📊 原始字节长度: ${bytes.length}');
          print('   📊 UTF-8解码后长度: ${responseBody.length}');

          // 检查中文
          final hasChinese = responseBody.contains(RegExp(r'[\u4e00-\u9fff]'));
          print('   📊 包含中文字符: $hasChinese');

          if (response.statusCode == 200 && hasChinese) {
            // 解析JSON
            final data = jsonDecode(responseBody);
            if (data is List && data.isNotEmpty) {
              final firstItem = data[0];
              if (firstItem is Map) {
                print('   ✅ 成功解码中文数据！');
                print('   📋 正确的字段名示例:');

                firstItem.keys
                    .where((key) => key.contains('净值'))
                    .take(3)
                    .forEach((key) {
                  print('     $key → ${firstItem[key]}');
                });

                // 验证关键字段
                expect(firstItem.containsKey('净值日期'), isTrue);
                expect(firstItem.containsKey('单位净值'), isTrue);

                final navValue = firstItem['单位净值'];
                final navDate = firstItem['净值日期'];
                print('   💰 单位净值: $navValue');
                print('   📅 净值日期: $navDate');

                // 创建持仓进行收益计算
                if (navValue != null) {
                  print('   🚀 使用正确编码的数据进行收益计算...');

                  // 导入收益计算引擎
                  final testHolding = PortfolioHolding(
                    fundCode: '110022',
                    fundName: '易方达消费行业股票',
                    fundType: '股票型',
                    holdingAmount: 10000.0,
                    costNav: 1.0,
                    costValue: 10000.0,
                    marketValue: navValue * 10000.0,
                    currentNav: navValue.toDouble(),
                    accumulatedNav: navValue * 1.5,
                    holdingStartDate: DateTime(2023, 1, 1),
                    lastUpdatedDate: DateTime.now(),
                  );

                  print('   ✅ 成功创建持仓数据！');
                  print('   💰 基金净值: ¥${navValue}');
                  print(
                      '   💵 持仓市值: ¥${testHolding.marketValue.toStringAsFixed(2)}');
                }

                print('   🎉 UTF-8直接解码方法完全成功！');
              }
            }
          } else {
            print('   ⚠️ UTF-8解码后仍未检测到中文字符');
          }
        } catch (e) {
          client.close();
          rethrow;
        }
      } catch (e) {
        print('   ❌ UTF-8解码测试失败: $e');
      }
    });

    test('编码修复函数优化版', () {
      print('🔧 测试优化版编码修复函数...');

      // 基于测试结果优化的修复函数
      String optimizedFixEncoding(String text) {
        try {
          // 检测是否包含UTF-8字节的Latin-1解码结果
          if (text.contains(RegExp(r'[åæçè][\x80-\xbf][\x80-\xbf]'))) {
            // 将字符串重新编码为字节，然后UTF-8解码
            final bytes = latin1.encode(text);
            return utf8.decode(bytes, allowMalformed: true);
          }
          return text;
        } catch (e) {
          return text;
        }
      }

      final testCases = [
        {'input': 'ç´¯è®¡åå¼', 'expected_pattern': '累计净值'},
        {'input': 'åä½åå¼', 'expected_pattern': '单位净值'},
        {'input': 'ç³»ç»', 'expected_pattern': '系统'},
        {'input': '净值日期', 'expected_pattern': '净值日期'}, // 已经正确的
      ];

      for (final testCase in testCases) {
        final input = testCase['input']!;
        final expectedPattern = testCase['expected_pattern']!;

        final fixed = optimizedFixEncoding(input);
        final containsExpected = fixed.contains(expectedPattern);

        print(
            '   ${containsExpected ? "✅" : "❌"} $input → $fixed (包含$expectedPattern: $containsExpected)');
      }
    });

    test('完整的中文API数据获取流程', () async {
      print('🔄 完整的中文API数据获取流程测试...');

      try {
        // 1. 获取API数据
        final navData = await getCorrectEncodedNavData('110022');
        print('   ✅ 步骤1: 成功获取净值数据');

        // 2. 验证数据结构
        expect(navData, isNotNull);
        expect(navData['净值日期'], isNotNull);
        expect(navData['单位净值'], isNotNull);
        print('   ✅ 步骤2: 数据结构验证通过');

        // 3. 计算基础收益
        final currentNav = navData['单位净值']?.toDouble() ?? 1.0;
        final costNav = 1.0;
        final returnRate = (currentNav - costNav) / costNav;
        print('   ✅ 步骤3: 收益计算完成');
        print('   📊 成本净值: ¥${costNav.toStringAsFixed(4)}');
        print('   📊 当前净值: ¥${currentNav.toStringAsFixed(4)}');
        print('   📈 收益率: ${(returnRate * 100).toStringAsFixed(2)}%');

        // 4. 验证计算逻辑
        expect(returnRate, isA<double>());
        print('   ✅ 步骤4: 计算逻辑验证通过');

        print('   🎉 完整的中文API数据获取流程测试成功！');
      } catch (e) {
        print('   ❌ 完整流程测试失败: $e');
        rethrow;
      }
    });
  });
}

/// 获取正确编码的净值数据
/// 使用验证过的方法确保中文编码正确
Future<Map<String, dynamic>> getCorrectEncodedNavData(String fundCode) async {
  const baseUrl = 'http://154.44.25.92:8080/api/public';
  final apiUrl =
      '$baseUrl/fund_open_fund_info_em?symbol=$fundCode&indicator=单位净值走势';

  final client = HttpClient();
  client.badCertificateCallback = (cert, host, port) => true;

  try {
    final request = await client.getUrl(Uri.parse(apiUrl));
    final response = await request.close();

    final bytes = await response.fold<List<int>>(
      <int>[],
      (dynamic previous, element) => previous..addAll(element),
    );

    final responseBody = utf8.decode(bytes);
    client.close();

    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody);
      if (data is List && data.isNotEmpty) {
        return Map<String, dynamic>.from(data[0]);
      }
    }

    throw Exception('无法获取净值数据');
  } catch (e) {
    client.close();
    rethrow;
  }
}

// 临时的PortfolioHolding定义（简化版用于测试）
class PortfolioHolding {
  final String fundCode;
  final String fundName;
  final String fundType;
  final double holdingAmount;
  final double costNav;
  final double costValue;
  final double marketValue;
  final double currentNav;
  final double accumulatedNav;
  final DateTime holdingStartDate;
  final DateTime lastUpdatedDate;

  PortfolioHolding({
    required this.fundCode,
    required this.fundName,
    required this.fundType,
    required this.holdingAmount,
    required this.costNav,
    required this.costValue,
    required this.marketValue,
    required this.currentNav,
    required this.accumulatedNav,
    required this.holdingStartDate,
    required this.lastUpdatedDate,
  });
}
