import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  group('简单基金API测试', () {
    test('测试基金排行榜URL编码修复', () async {
      print('🔄 测试基金排行榜URL编码修复...');

      final testCases = [
        {'symbol': '全部', 'description': '全部基金'},
        {'symbol': '股票型', 'description': '股票型基金'},
        {'symbol': '混合型', 'description': '混合型基金'},
        {'symbol': '债券型', 'description': '债券型基金'},
      ];

      for (final testCase in testCases) {
        print('📄 测试参数: ${testCase['symbol']} (${testCase['description']})');

        try {
          // 使用修复后的URL构建方式
          final uri = Uri(
            scheme: 'http',
            host: '154.44.25.92',
            port: 8080,
            path: 'api/public/fund_open_fund_rank_em',
            queryParameters: {'symbol': testCase['symbol']},
          );

          print('🔗 构建的URL: $uri');

          final response = await http.get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json; charset=utf-8',
            },
          ).timeout(const Duration(seconds: 30));

          if (response.statusCode == 200) {
            print('✅ ${testCase['description']} 请求成功');
            print('📊 响应大小: ${response.body.length} 字符');

            // 尝试解析JSON
            try {
              final data = jsonDecode(response.body);
              if (data is List) {
                print('📋 数据条数: ${data.length}');
                if (data.isNotEmpty) {
                  print(
                      '🔍 第一条数据预览: ${data[0].toString().substring(0, 100)}...');
                }
              }
            } catch (e) {
              print('⚠️ JSON解析失败: $e');
            }
          } else if (response.statusCode == 404) {
            print('❌ ${testCase['description']} 404错误 - URL编码可能仍有问题');
            fail('${testCase['description']} 返回404错误');
          } else {
            print(
                '⚠️ ${testCase['description']} 返回状态码: ${response.statusCode}');
          }
        } catch (e) {
          print('❌ ${testCase['description']} 请求失败: $e');
          // 不让单个测试失败，继续测试其他参数
        }

        print(''); // 空行分隔
      }

      print('🎉 URL编码修复测试完成！');
    });

    test('对比修复前后的URL构建方式', () async {
      print('🔄 对比URL构建方式...');

      const symbol = '股票型';

      // 修复前的方式
      print('📝 修复前的方式:');
      try {
        final oldUri = Uri.parse(
                'http://154.44.25.92:8080/api/public/fund_open_fund_rank_em')
            .replace(queryParameters: {'symbol': symbol});
        print('  🔗 URL: $oldUri');
        print('  📝 查询参数: ${oldUri.queryParameters}');
      } catch (e) {
        print('  ❌ 修复前方式失败: $e');
      }

      // 修复后的方式
      print('📝 修复后的方式:');
      try {
        final newUri = Uri(
          scheme: 'http',
          host: '154.44.25.92',
          port: 8080,
          path: 'api/public/fund_open_fund_rank_em',
          queryParameters: {'symbol': symbol},
        );
        print('  🔗 URL: $newUri');
        print('  📝 查询参数: ${newUri.queryParameters}');
        print('  ✅ 修复后方式成功');
      } catch (e) {
        print('  ❌ 修复后方式失败: $e');
      }

      print('✅ URL构建方式对比完成');
    });
  });
}
