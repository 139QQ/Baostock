import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  await testFixedIndicatorsQuick();
}

Future<void> testFixedIndicatorsQuick() async {
  const String apiUrl =
      'http://154.44.25.92:8080/api/public/fund_open_fund_info_em';
  const String fundCode = '009209';

  print('🔧 快速验证修复效果');
  print('=' * 50);

  // 测试累计净值走势
  await testIndicator('累计净值走势', fundCode, apiUrl);

  // 测试同类排名百分比
  await testIndicator('同类排名百分比', fundCode, apiUrl);
}

Future<void> testIndicator(
    String indicator, String fundCode, String apiUrl) async {
  print('\n📊 测试: $indicator');
  print('-' * 30);

  try {
    final String encodedIndicator = Uri.encodeComponent(indicator);
    final response = await http
        .get(
          Uri.parse('$apiUrl?symbol=$fundCode&indicator=$encodedIndicator'),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;

      if (data.isNotEmpty) {
        final firstItem = data.first as Map<String, dynamic>;
        final decodedFirst = _decodeFieldNames(firstItem);

        String dateField = '';
        String valueField = '';
        String dateValue = '';
        String valueValue = '';

        if (indicator == '累计净值走势') {
          dateField = '净值日期';
          valueField = '累计净值';
          dateValue = decodedFirst['净值日期']?.toString()?.split('T')[0] ?? 'N/A';
          valueValue = decodedFirst['累计净值']?.toString() ?? 'N/A';
        } else if (indicator == '同类排名百分比') {
          dateField = '报告日期';
          valueField = '同类型排名-每日近3月收益排名百分比';
          dateValue = decodedFirst['报告日期']?.toString()?.split('T')[0] ?? 'N/A';
          valueValue = decodedFirst['同类型排名-每日近3月收益排名百分比']?.toString() ?? 'N/A';
        }

        print('✅ 数据点数: ${data.length}');
        print('📅 日期字段($dateField): $dateValue');
        print('📊 数值字段($valueField): $valueValue');

        if (dateValue != 'N/A' && valueValue != 'N/A') {
          print('🎉 修复成功！指标不再显示 N/A');
        } else {
          print('❌ 仍有问题：数据解析失败');
        }
      } else {
        print('⚠️ 数据为空（可能该基金没有此类记录）');
      }
    } else {
      print('❌ API请求失败: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ 测试失败: $e');
  }
}

Map<String, dynamic> _decodeFieldNames(Map<String, dynamic> originalMap) {
  final decodedMap = <String, dynamic>{};

  for (final entry in originalMap.entries) {
    try {
      final bytes = entry.key.codeUnits;
      final decodedKey = utf8.decode(bytes);
      decodedMap[decodedKey] = entry.value;
    } catch (e) {
      decodedMap[entry.key] = entry.value;
    }
  }

  return decodedMap;
}
