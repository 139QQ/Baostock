import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

/// API调试测试（优化版）
///
/// 优化内容：
/// 1. 集成中文编码修复解决方案
/// 2. 增强数据结构分析功能
/// 3. 添加编码问题自动检测和修复
/// 4. 提供更详细的诊断信息

void main() {
  group('API数据结构调试（编码优化版）', () {
    const baseUrl = 'http://154.44.25.92:8080/api/public';

    /// 编码感知的HTTP请求方法
    Future<Map<String, dynamic>> makeEncodedRequest(String url) async {
      try {
        // 方法1：尝试标准HTTP请求
        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          // 检查是否包含中文
          final hasChinese = response.body.contains(RegExp(r'[\u4e00-\u9fff]'));

          if (hasChinese) {
            // 已经包含中文，直接解析
            return {
              'success': true,
              'data': jsonDecode(response.body),
              'method': 'standard_http',
              'encoding': 'utf8_native',
            };
          } else if (response.body.contains(RegExp(r'[åæçè]'))) {
            // 包含乱码，尝试编码修复
            print('   🔧 检测到乱码，尝试编码修复...');
            try {
              final bytes = response.bodyBytes;
              final fixedResponse = utf8.decode(bytes);
              final data = jsonDecode(fixedResponse);
              return {
                'success': true,
                'data': data,
                'method': 'standard_http_fixed',
                'encoding': 'utf8_fixed',
              };
            } catch (e) {
              print('   ⚠️ 编码修复失败，尝试HttpClient...');
            }
          }
        }

        // 方法2：使用HttpClient确保正确编码
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) => true;

        try {
          final request = await client.getUrl(Uri.parse(url));
          final response = await request.close();

          final bytes = await response.fold<List<int>>(
            <int>[],
            (dynamic previous, element) => previous..addAll(element),
          );

          client.close();

          final responseBody = utf8.decode(bytes);
          final data = jsonDecode(responseBody);

          return {
            'success': true,
            'data': data,
            'method': 'httpclient_utf8',
            'encoding': 'utf8_manual',
            'bytes_length': bytes.length,
          };
        } catch (e) {
          client.close();
          rethrow;
        }
      } catch (e) {
        return {
          'success': false,
          'error': e.toString(),
          'method': 'failed',
        };
      }
    }

    test('调试开放式基金实时数据接口（编码优化）', () async {
      final apiUrl = '$baseUrl/fund_open_fund_daily_em';

      print('🔍 API调试 - 开放式基金实时数据（编码优化版）');
      print('   📡 URL: $apiUrl');

      final result = await makeEncodedRequest(apiUrl);

      if (result['success'] == true) {
        final data = result['data'];
        final method = result['method'];
        final encoding = result['encoding'];

        print('   ✅ 请求成功');
        print('   📊 使用方法: $method');
        print('   📊 编码方式: $encoding');
        print('   📊 数据类型: ${data.runtimeType}');
        print('   📊 数据长度: ${data is List ? data.length : "N/A"}');

        if (data is List && data.isNotEmpty) {
          final firstItem = data[0];
          print('   📋 首个元素类型: ${firstItem.runtimeType}');

          // 检查中文字段
          if (firstItem is Map) {
            final chineseFields = firstItem.keys
                .where((key) => key.contains(RegExp(r'[\u4e00-\u9fff]')))
                .toList();

            print('   📊 中文字段数量: ${chineseFields.length}');
            if (chineseFields.isNotEmpty) {
              print('   ✅ 成功解析中文字段:');
              chineseFields.take(5).forEach((field) {
                print('     $field → ${firstItem[field]}');
              });
            }

            print('\n   📊 完整字段列表:');
            final keys = firstItem.keys.toList();
            for (int i = 0; i < keys.length; i++) {
              final key = keys[i];
              final value = firstItem[key];
              final isChinese = key.contains(RegExp(r'[\u4e00-\u9fff]'));
              final marker = isChinese ? '🇨🇳' : '  ';
              print(
                  '   ${marker} ${i + 1}. $key (${value.runtimeType}): $value');
            }

            // 数据质量分析
            print('\n   📊 数据质量分析:');
            int nullCount = 0;
            int stringCount = 0;
            int numberCount = 0;

            firstItem.values.forEach((value) {
              if (value == null)
                nullCount++;
              else if (value is String)
                stringCount++;
              else if (value is num) numberCount++;
            });

            print('     非空字段: ${keys.length - nullCount}/${keys.length}');
            print('     字符串字段: $stringCount');
            print('     数值字段: $numberCount');
            print('     空值字段: $nullCount');
          }
        }
      } else {
        print('   ❌ API调用失败: ${result['error']}');
      }
    });

    test('调试开放式基金历史数据接口（编码优化）', () async {
      final apiUrl =
          '$baseUrl/fund_open_fund_info_em?symbol=110022&indicator=单位净值走势';

      print('\n🔍 API调试 - 开放式基金历史数据（编码优化版）');
      print('   📡 URL: $apiUrl');

      final result = await makeEncodedRequest(apiUrl);

      if (result['success'] == true) {
        final data = result['data'];
        final method = result['method'];
        final encoding = result['encoding'];

        print('   ✅ 请求成功');
        print('   📊 使用方法: $method');
        print('   📊 编码方式: $encoding');
        print('   📊 数据类型: ${data.runtimeType}');
        print('   📊 数据长度: ${data is List ? data.length : "N/A"}');

        if (data is List && data.isNotEmpty) {
          final firstItem = data[0];
          final lastItem = data[data.length - 1];

          print('   📋 首个数据类型: ${firstItem.runtimeType}');
          print('   📋 最后数据类型: ${lastItem.runtimeType}');

          if (firstItem is Map && lastItem is Map) {
            // 关键中文字段验证
            final keyFields = ['净值日期', '单位净值', '累计净值'];
            print('\n   📊 关键字段验证:');

            for (final field in keyFields) {
              final hasFirst = firstItem.containsKey(field);
              final hasLast = lastItem.containsKey(field);
              final firstValue = firstItem[field];
              final lastValue = lastItem[field];

              print(
                  '     $field: ${hasFirst ? "✅" : "❌"} 首项=$firstValue, 末项=$lastValue');
            }

            // 完整字段结构分析
            print('\n   📊 完整字段结构:');
            final keys = firstItem.keys.toList();
            for (int i = 0; i < keys.length; i++) {
              final key = keys[i];
              final value = firstItem[key];
              final lastValue = lastItem[key];
              final isChinese = key.contains(RegExp(r'[\u4e00-\u9fff]'));
              final marker = isChinese ? '🇨🇳' : '  ';

              print('   ${marker} ${i + 1}. $key');
              print('       首项: $value (${value.runtimeType})');
              print('       末项: $lastValue (${lastValue.runtimeType})');

              if (value != lastValue) {
                print('       🔄 数值变化');
              }
              print('');
            }

            // 数据连续性检查
            print('   📊 数据连续性分析:');
            if (keys.contains('净值日期')) {
              final firstDate = firstItem['净值日期'];
              final lastDate = lastItem['净值日期'];

              print('     时间跨度: $firstDate → $lastDate');
              print('     数据点数: ${data.length}');

              if (data.length > 1) {
                final timeSpan = DateTime.parse(lastDate.toString())
                    .difference(DateTime.parse(firstDate.toString()));
                print('     跨越天数: ${timeSpan.inDays}');
                print(
                    '     平均密度: ${(timeSpan.inDays / data.length).toStringAsFixed(2)}天/点');
              }
            }
          }
        }
      } else {
        print('   ❌ API调用失败: ${result['error']}');
      }
    });

    test('多种接口编码效果对比测试', () async {
      print('\n🔍 多种接口编码效果对比测试');

      final testUrls = [
        {
          'name': '开放式基金实时数据',
          'url': '$baseUrl/fund_open_fund_daily_em',
          'expected_fields': ['基金代码', '基金简称', '单位净值'],
        },
        {
          'name': '货币型基金实时数据',
          'url': '$baseUrl/fund_money_fund_daily_em',
          'expected_fields': ['基金代码', '万份收益', '7日年化'],
        },
        {
          'name': 'ETF基金实时数据',
          'url': '$baseUrl/fund_etf_fund_daily_em',
          'expected_fields': ['基金代码', '基金简称', '单位净值'],
        },
      ];

      for (final testConfig in testUrls) {
        print('\n   📡 测试: ${testConfig['name']}');
        print('      URL: ${testConfig['url']}');

        final result = await makeEncodedRequest(testConfig['url']! as String);

        if (result['success'] == true) {
          final data = result['data'];
          final method = result['method'];
          final encoding = result['encoding'];
          final expectedFields = testConfig['expected_fields'] as List<String>;

          print('      ✅ 成功 (方法: $method, 编码: $encoding)');

          if (data is List && data.isNotEmpty) {
            final firstItem = data[0];
            if (firstItem is Map) {
              // 检查期望字段
              int foundFields = 0;
              for (final expectedField in expectedFields) {
                if (firstItem.containsKey(expectedField)) {
                  foundFields++;
                }
              }

              // 统计中文字段
              final chineseFields = firstItem.keys
                  .where((key) => key.contains(RegExp(r'[\u4e00-\u9fff]')))
                  .length;

              print('      📊 期望字段: $foundFields/${expectedFields.length}');
              print('      📊 中文字段: $chineseFields');
              print('      📊 总字段数: ${firstItem.keys.length}');
            }
          }
        } else {
          print('      ❌ 失败: ${result['error']}');
        }
      }
    });

    test('编码问题自动检测和修复演示', () async {
      print('\n🔧 编码问题自动检测和修复演示');

      // 使用已知会产生编码问题的接口
      final apiUrl =
          '$baseUrl/fund_open_fund_info_em?symbol=110022&indicator=单位净值走势';

      print('   📡 测试URL: $apiUrl');

      // 1. 显示原始HTTP响应
      print('\n   📋 步骤1: 标准HTTP请求');
      try {
        final response = await http.get(Uri.parse(apiUrl));

        if (response.statusCode == 200) {
          print('      📊 响应长度: ${response.body.length}');

          final hasChinese = response.body.contains(RegExp(r'[\u4e00-\u9fff]'));
          final hasGarbled = response.body.contains(RegExp(r'[åæçè]'));

          print('      📊 包含中文: $hasChinese');
          print('      📊 包含乱码: $hasGarbled');

          if (hasGarbled) {
            print('      🔧 检测到乱码，演示修复过程...');

            // 显示修复前后的对比
            try {
              final bytes = response.bodyBytes;
              final fixedResponse = utf8.decode(bytes);

              print('      📊 修复前示例: ${response.body.substring(0, 100)}...');
              print('      📊 修复后示例: ${fixedResponse.substring(0, 100)}...');

              final fixedData = jsonDecode(fixedResponse);
              if (fixedData is List && fixedData.isNotEmpty) {
                final firstItem = fixedData[0];
                if (firstItem is Map) {
                  final chineseFields = firstItem.keys
                      .where((key) => key.contains(RegExp(r'[\u4e00-\u9fff]')))
                      .toList();

                  print('      ✅ 修复成功，中文字段: ${chineseFields.length}个');
                  chineseFields.take(3).forEach((field) {
                    print('        $field → ${firstItem[field]}');
                  });
                }
              }
            } catch (e) {
              print('      ❌ 修复失败: $e');
            }
          }
        }
      } catch (e) {
        print('      ❌ HTTP请求失败: $e');
      }

      // 2. 使用编码感知方法
      print('\n   📋 步骤2: 编码感知HTTP请求');
      final result = await makeEncodedRequest(apiUrl);

      if (result['success'] == true) {
        print('      ✅ 编码感知方法成功');
        print('      📊 使用方法: ${result['method']}');
        print('      📊 编码方式: ${result['encoding']}');

        final data = result['data'];
        if (data is List && data.isNotEmpty) {
          final firstItem = data[0];
          if (firstItem is Map) {
            final chineseFields = firstItem.keys
                .where((key) => key.contains(RegExp(r'[\u4e00-\u9fff]')))
                .toList();

            print('      📊 解析中文字段: ${chineseFields.length}个');
            print('      🎉 自动编码检测和修复演示完成！');
          }
        }
      } else {
        print('      ❌ 编码感知方法失败: ${result['error']}');
      }
    });
  });
}
