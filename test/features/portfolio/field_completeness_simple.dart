import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// 简化的API字段完整性检查
/// 专门用于诊断字段null问题
void main() {
  group('API字段完整性简化诊断', () {
    const baseUrl = 'http://154.44.25.92:8080/api/public';

    test('快速诊断：字段完整性检查', () async {
      print('🔍 快速诊断：字段完整性检查...');

      // 测试单位净值走势接口
      final testUrl =
          '$baseUrl/fund_open_fund_info_em?symbol=110022&indicator=单位净值走势';

      print('   📡 测试URL: $testUrl');

      try {
        final response = await http.get(Uri.parse(testUrl));

        print('   📊 响应状态码: ${response.statusCode}');
        print('   📊 响应长度: ${response.body.length}');

        if (response.statusCode == 200) {
          // 检查编码问题
          final hasChinese = response.body.contains(RegExp(r'[\u4e00-\u9fff]'));
          final hasGarbled = response.body.contains(RegExp(r'[åæçè]'));

          print('   📊 包含中文: $hasChinese');
          print('   📊 包含乱码: $hasGarbled');

          String correctResponse;
          if (hasChinese) {
            correctResponse = response.body;
            print('   ✅ 响应已包含正确中文');
          } else if (hasGarbled) {
            // 手动UTF-8解码
            final bytes = response.bodyBytes;
            correctResponse = utf8.decode(bytes);
            print('   🔧 应用UTF-8解码修复');
          } else {
            correctResponse = response.body;
            print('   ⚠️ 响应中未检测到中文字符');
          }

          try {
            final data = jsonDecode(correctResponse);

            if (data is List && data.isNotEmpty) {
              print('   ✅ JSON解析成功');
              print('   📊 数据点数: ${data.length}');

              final firstItem = data[0];
              if (firstItem is Map) {
                print('   📊 首个数据项分析:');

                // 统计字段
                final keys = firstItem.keys.toList();
                int nullCount = 0;
                int nonNullCount = 0;
                int stringCount = 0;
                int numberCount = 0;

                print('\n   📋 完整字段列表:');
                for (int i = 0; i < keys.length; i++) {
                  final key = keys[i];
                  final value = firstItem[key];

                  final isChinese = key.contains(RegExp(r'[\u4e00-\u9fff]'));
                  final marker = isChinese ? '🇨🇳' : '  ';

                  if (value == null) {
                    nullCount++;
                  } else {
                    nonNullCount++;
                    if (value is String) stringCount++;
                    if (value is num) numberCount++;
                  }

                  print(
                      '   ${marker} ${i + 1}. $key = $value (${value.runtimeType})');
                }

                print('\n   📊 字段统计:');
                print('     总字段数: ${keys.length}');
                print('     非空字段: $nonNullCount');
                print('     空值字段: $nullCount');
                print('     字符串字段: $stringCount');
                print('     数值字段: $numberCount');

                // 检查关键字段
                print('\n   🔍 关键字段检查:');
                final keyFields = [
                  '净值日期',
                  '单位净值',
                  '累计净值',
                  '日增长率',
                  '基金代码',
                  '基金简称'
                ];

                for (final field in keyFields) {
                  if (firstItem.containsKey(field)) {
                    final value = firstItem[field];
                    print('     ✅ $field: $value');
                  } else {
                    print('     ❌ $field: 缺失');
                  }
                }

                // 问题诊断
                print('\n   📊 问题诊断:');
                if (nullCount == keys.length) {
                  print('     ❌ 严重问题：所有字段都是null！');
                  print('     💡 可能原因：');
                  print('       1. API接口配置错误');
                  print('       2. 服务器数据源问题');
                  print('       3. URL参数错误');
                  print('       4. JSON结构变化');
                } else if (nullCount > keys.length * 0.5) {
                  print('     ⚠️ 警告：超过一半字段为null');
                } else {
                  print('     ✅ 数据完整性良好');
                }

                // 建议修复方案
                if (nullCount > 0) {
                  print('\n   💡 建议修复方案:');

                  // 检查URL编码
                  print('     1. 检查URL中的中文字符编码');
                  print('       当前URL: $testUrl');
                  print('       应编码为: ${Uri.encodeComponent('单位净值走势')}');

                  // 检查API参数
                  print('     2. 验证API参数是否正确');
                  print('       - indicator参数: 单位净值走势');
                  print('       - symbol参数: 110022');

                  // 检查API文档
                  print('     3. 参考净值参数.txt文档中的正确参数格式');
                  print('       - 确认接口名称和参数名称');
                  print('       - 检查参数是否需要编码');
                }
              } else {
                print('   ❌ 首个数据项不是Map类型');
              }
            } else {
              print('   ❌ 数据不是List类型');
            }
          } catch (e) {
            print('   ❌ JSON解析失败: $e');
            print('   💡 可能的问题：');
            print('       - JSON格式错误');
            print('       - 编码问题未完全解决');
            print('       - 服务器返回错误数据');
          }
        } else {
          print('   ❌ HTTP请求失败，状态码: ${response.statusCode}');
        }
      } catch (e) {
        print('   ❌ 请求异常: $e');
      }
    });

    test('对比测试：不同indicator参数', () async {
      print('\n🔍 对比测试：不同indicator参数...');

      final indicators = ['单位净值走势', '累计净值走势', '累计收益率走势', '净值增长率走势'];

      for (final indicator in indicators) {
        print('\n   📡 测试indicator: $indicator');
        final testUrl =
            '$baseUrl/fund_open_fund_info_em?symbol=110022&indicator=$indicator';

        try {
          final response = await http.get(Uri.parse(testUrl));

          if (response.statusCode == 200) {
            String correctResponse;
            final hasChinese =
                response.body.contains(RegExp(r'[\u4e00-\u9fff]'));

            if (hasChinese) {
              correctResponse = response.body;
            } else {
              final bytes = response.bodyBytes;
              correctResponse = utf8.decode(bytes);
            }

            final data = jsonDecode(correctResponse);

            if (data is List && data.isNotEmpty) {
              final firstItem = data[0];
              if (firstItem is Map) {
                final keys = firstItem.keys.toList();
                final chineseFields = keys
                    .where((key) => key.contains(RegExp(r'[\u4e00-\u9fff]')))
                    .length;
                final nullFields =
                    firstItem.values.where((v) => v == null).length;

                print(
                    '     ✅ 字段数: ${keys.length}, 中文: $chineseFields, 空值: $nullFields');

                // 显示前2个字段作为示例
                final sampleFields = keys.take(2).toList();
                sampleFields.forEach((field) {
                  print('       示例: $field = ${firstItem[field]}');
                });
              }
            }
          } else {
            print('     ❌ HTTP失败: ${response.statusCode}');
          }
        } catch (e) {
          print('     ❌ 异常: $e');
        }
      }
    });

    test('原始数据分析', () async {
      print('\n🔍 原始数据分析...');

      const testUrl =
          '$baseUrl/fund_open_fund_info_em?symbol=110022&indicator=单位净值走势';

      try {
        final response = await http.get(Uri.parse(testUrl));

        if (response.statusCode == 200) {
          print('   📊 响应头: ${response.headers}');
          print('   📊 响应长度: ${response.body.length}');

          // 显示原始响应前100个字符
          final preview = response.body.length > 100
              ? '${response.body.substring(0, 100)}...'
              : response.body;
          print('   📊 原始响应预览:');
          print('     $preview');

          // 尝试不同的解码方式
          print('\n   🔧 解码方式对比:');

          // 方式1：直接解码
          try {
            final data1 = jsonDecode(response.body);
            if (data1 is List && data1.isNotEmpty) {
              final firstItem = data1[0];
              if (firstItem is Map) {
                final sampleField = firstItem.keys.first;
                print('     直接解码: $sampleField = ${firstItem[sampleField]}');
              }
            }
          } catch (e) {
            print('     直接解码: 失败 - $e');
          }

          // 方式2：UTF-8手动解码
          try {
            final bytes = response.bodyBytes;
            final decoded = utf8.decode(bytes);
            final data2 = jsonDecode(decoded);
            if (data2 is List && data2.isNotEmpty) {
              final firstItem = data2[0];
              if (firstItem is Map) {
                final sampleField = firstItem.keys.first;
                print(
                    '     UTF-8手动解码: $sampleField = ${firstItem[sampleField]}');
              }
            }
          } catch (e) {
            print('     UTF-8手动解码: 失败 - $e');
          }
        }
      } catch (e) {
        print('   ❌ 原始数据分析失败: $e');
      }
    });
  });
}
