import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;

/// API字段检查程序
void main() async {
  print('🔍 开始检查API字段结构...\n');

  try {
    const baseUrl = 'http://154.44.25.92:8080';
    const symbol = '全部';

    final uri = Uri.parse('$baseUrl/api/public/fund_open_fund_rank_em')
        .replace(queryParameters: {'symbol': symbol});

    print('📡 请求URL: $uri\n');

    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json; charset=utf-8',
        'Accept-Charset': 'utf-8',
        'User-Agent': 'APIFieldChecker/1.0.0',
      },
    ).timeout(const Duration(seconds: 90));

    print('📊 响应状态: ${response.statusCode}');
    print('📊 响应大小: ${response.body.length} 字符\n');

    if (response.statusCode == 200) {
      // 修复UTF-8编码问题
      String responseData;
      try {
        responseData =
            utf8.decode(response.body.codeUnits, allowMalformed: true);
      } catch (e) {
        print('❌ UTF-8解码失败，使用原始数据: $e');
        responseData = response.body;
      }

      final data = json.decode(responseData);

      print('✅ API调用成功: ${data.length}条记录\n');

      if (data.isNotEmpty) {
        print('📋 第一条记录的所有字段:');
        final firstItem = data[0];
        firstItem.forEach((key, value) {
          print('  - $key: "$value"');
        });

        print('\n📋 第二条记录的所有字段:');
        if (data.length > 1) {
          final secondItem = data[1];
          secondItem.forEach((key, value) {
            print('  - $key: "$value"');
          });
        }

        print('\n🔍 字段分析:');
        final allKeys = <String>{};
        for (var item in data) {
          allKeys.addAll(item.keys.cast<String>());
        }

        print('  所有字段名: ${allKeys.toList()}');

        // 检查我们代码中使用的字段
        final expectedFields = [
          '基金代码',
          '基金简称',
          '基金类型',
          '单位净值',
          '日增长率',
          '近1年',
          '近3年'
        ];
        print('\n📝 代码中期望的字段:');
        for (var field in expectedFields) {
          final exists = allKeys.contains(field);
          print('  - $field: ${exists ? "✅ 存在" : "❌ 缺失"}');
          if (!exists) {
            // 查找可能的相似字段
            final similar = allKeys
                .where((key) => key.contains(field.substring(0, 2)))
                .toList();
            if (similar.isNotEmpty) {
              print('    💡 可能的相似字段: ${similar.join(", ")}');
            }
          }
        }

        print('\n🎯 具体数据示例:');
        for (int i = 0; i < math.min(3, data.length); i++) {
          final item = data[i];
          print('  记录 ${i + 1}:');
          print('    基金代码: ${item['基金代码']}');
          print('    基金简称: ${item['基金简称']}');
          print('    基金类型: ${item['基金类型']}');
          print('    单位净值: ${item['单位净值']}');
          print('    日增长率: ${item['日增长率']}');
          print('    近1年: ${item['近1年']}');
          print('    近3年: ${item['近3年']}');
          print('');
        }
      }
    } else {
      print('❌ API错误: ${response.statusCode} ${response.reasonPhrase}');
      print('❌ 响应内容: ${response.body}');
    }
  } catch (e) {
    print('❌ 请求失败: $e');
  }
}
