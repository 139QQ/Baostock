import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  await testProblemIndicators();
}

Future<void> testProblemIndicators() async {
  const String apiUrl =
      'http://154.44.25.92:8080/api/public/fund_open_fund_info_em';
  const String fundCode = '009209';

  final List<String> problemIndicators = [
    '累计净值走势',
    '同类排名百分比',
    '分红送配详情',
    '拆分详情',
  ];

  print('🔍 问题指标专项测试');
  print('=' * 60);
  print('基金代码: $fundCode');

  for (final indicator in problemIndicators) {
    print('\n📊 测试指标: $indicator');
    print('-' * 40);

    try {
      final String encodedIndicator = Uri.encodeComponent(indicator);
      final response = await http
          .get(
            Uri.parse('$apiUrl?symbol=$fundCode&indicator=$encodedIndicator'),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        print('✅ API连接成功，数据条数: ${data.length}');

        if (data.isNotEmpty) {
          final firstItem = data.first as Map<String, dynamic>;
          print('原始字段: ${firstItem.keys.toList()}');

          // 解码字段名
          final decodedFirst = _decodeFieldNames(firstItem);
          print('解码字段: ${decodedFirst.keys.toList()}');

          // 尝试匹配关键字段
          print('字段值检查:');
          decodedFirst.forEach((key, value) {
            print('  $key: $value');
          });

          // 分析可能的数据字段
          _analyzeIndicatorFields(indicator, decodedFirst);
        } else {
          print('⚠️ 返回数据为空');
        }
      } else {
        print('❌ API请求失败: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 测试失败: $e');
    }
  }
}

/// 解码UTF-8编码的字段名
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

/// 分析不同指标的可能字段
void _analyzeIndicatorFields(
    String indicator, Map<String, dynamic> decodedFields) {
  print('\n字段分析:');

  switch (indicator) {
    case '累计净值走势':
      final possibleDateFields = ['净值日期', '日期', 'DATE'];
      final possibleValueFields = ['累计净值', '累计单位净值', 'NAV', '单位净值'];

      for (final field in possibleDateFields) {
        if (decodedFields.containsKey(field)) {
          print('  ✅ 找到日期字段: $field = ${decodedFields[field]}');
        }
      }

      for (final field in possibleValueFields) {
        if (decodedFields.containsKey(field)) {
          print('  ✅ 找到数值字段: $field = ${decodedFields[field]}');
        }
      }
      break;

    case '同类排名百分比':
      final possibleDateFields = ['净值日期', '日期', '报告日期'];
      final possibleValueFields = ['同类排名百分比', '排名百分比', '百分比排名', '相对排名'];

      for (final field in possibleDateFields) {
        if (decodedFields.containsKey(field)) {
          print('  ✅ 找到日期字段: $field = ${decodedFields[field]}');
        }
      }

      for (final field in possibleValueFields) {
        if (decodedFields.containsKey(field)) {
          print('  ✅ 找到数值字段: $field = ${decodedFields[field]}');
        }
      }
      break;

    case '分红送配详情':
    case '拆分详情':
      // 这两个可能是表格形式的数据，字段可能不同
      print('  📋 可能的特殊字段:');
      decodedFields.forEach((key, value) {
        if (key.contains('分红') ||
            key.contains('送股') ||
            key.contains('配股') ||
            key.contains('拆分') ||
            key.contains('除权') ||
            key.contains('登记')) {
          print('    📌 $key: $value');
        }
      });
      break;
  }
}
