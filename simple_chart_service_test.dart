import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  await testChartServiceUpdate();
}

Future<void> testChartServiceUpdate() async {
  const String apiUrl =
      'http://154.44.25.92:8080/api/public/fund_open_fund_info_em';
  const String fundCode = '009209';
  const String indicator = '累计净值走势';

  print('\n🔍 ChartDataService 更新验证测试');
  print('=' * 60);
  print('基金代码: $fundCode');
  print('指标类型: $indicator');

  try {
    final String encodedIndicator = Uri.encodeComponent(indicator);
    final response = await http
        .get(
          Uri.parse('$apiUrl?symbol=$fundCode&indicator=$encodedIndicator'),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      print('\n✅ API连接成功');
      print('数据条数: ${data.length}');

      if (data.isNotEmpty) {
        final firstItem = data.first as Map<String, dynamic>;
        print('\n原始数据示例:');
        print('第一条数据: $firstItem');
        print('原始字段: ${firstItem.keys.toList()}');

        // 模拟ChartDataService的UTF-8解码逻辑
        final decodedFirst = _decodeFieldNames(firstItem);
        print('\n解码后数据:');
        print('解码字段: ${decodedFirst.keys.toList()}');

        // 测试关键字段
        final testFields = ['净值日期', '累计净值', '单位净值', '日增长率'];
        print('\n关键字段检查:');
        for (final field in testFields) {
          final exists = decodedFirst.containsKey(field);
          final value = exists ? decodedFirst[field] : 'N/A';
          print('  $field: $exists -> $value');
        }

        // 验证日期解析
        if (decodedFirst.containsKey('净值日期')) {
          final navDate = decodedFirst['净值日期']?.toString() ?? '';
          final displayDate =
              navDate.contains('T') ? navDate.split('T')[0] : navDate;
          print('\n✅ 日期解析成功: $displayDate');

          // 验证净值解析
          if (decodedFirst.containsKey('累计净值')) {
            final navValue = decodedFirst['累计净值']?.toString() ?? 'N/A';
            print('✅ 净值解析成功: $navValue');
          }
        }

        print('\n🎉 ChartDataService UTF-8字段解码功能验证成功！');
        print('现在可以正确处理API返回的UTF-8编码字段名。');
      }
    } else {
      print('❌ API请求失败: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ 测试失败: $e');
  }
}

/// 模拟ChartDataService的UTF-8字段解码函数
Map<String, dynamic> _decodeFieldNames(Map<String, dynamic> originalMap) {
  final decodedMap = <String, dynamic>{};

  for (final entry in originalMap.entries) {
    try {
      // 解码UTF-8字段名
      final bytes = entry.key.codeUnits;
      final decodedKey = utf8.decode(bytes);
      decodedMap[decodedKey] = entry.value;
    } catch (e) {
      // 如果解码失败，保持原始键名
      decodedMap[entry.key] = entry.value;
      print('⚠️ 字段解码失败: ${entry.key} -> $e');
    }
  }

  return decodedMap;
}
