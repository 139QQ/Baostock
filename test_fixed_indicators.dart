import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  await testFixedIndicators();
}

Future<void> testFixedIndicators() async {
  const String apiUrl =
      'http://154.44.25.92:8080/api/public/fund_open_fund_info_em';
  const String fundCode = '009209';

  final List<String> testIndicators = [
    '累计净值走势', // 应该现在正常工作
    '同类排名百分比', // 应该现在正常工作
    '分红送配详情', // 可能为空，但测试处理逻辑
    '拆分详情', // 可能为空，但测试处理逻辑
  ];

  print('🔧 修复后的指标测试');
  print('=' * 60);
  print('基金代码: $fundCode');

  for (final indicator in testIndicators) {
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
          final decodedFirst = _decodeFieldNames(firstItem);
          print('解码字段: ${decodedFirst.keys.toList()}');

          // 使用修复后的逻辑测试解析
          final result = _parseIndicatorData(indicator, decodedFirst);
          if (result != null) {
            print('✅ 解析成功:');
            print('  日期: ${result['date']}');
            print('  数值: ${result['value']}');
            print('  标签: ${result['label']}');
          } else {
            print('❌ 解析失败');
          }
        } else {
          print('⚠️ 返回数据为空 - 这是正常的（该基金可能没有${indicator}记录）');
          // 对于空数据，我们仍然应该测试降级处理
          print('💡 将使用模拟数据或适当的空数据展示');
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
      final bytes = entry.key.codeUnits;
      final decodedKey = utf8.decode(bytes);
      decodedMap[decodedKey] = entry.value;
    } catch (e) {
      decodedMap[entry.key] = entry.value;
    }
  }

  return decodedMap;
}

/// 解析double值
double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    final cleanValue = value.toString().replaceAll('%', '').replaceAll(',', '');
    return double.tryParse(cleanValue);
  }
  return null;
}

/// 使用修复后的逻辑解析指标数据
Map<String, String>? _parseIndicatorData(
    String indicator, Map<String, dynamic> decodedItem) {
  String navDate = '';
  double navValue = 0.0;

  try {
    if (indicator == '单位净值走势') {
      navDate = decodedItem['净值日期']?.toString() ?? '';
      navValue = _parseDouble(decodedItem['单位净值']) ?? 0.0;
    } else if (indicator == '累计净值走势') {
      navDate = decodedItem['净值日期']?.toString() ?? '';
      navValue = _parseDouble(decodedItem['累计净值']) ?? 0.0;
    } else if (indicator.contains('收益率')) {
      navDate = decodedItem['净值日期']?.toString() ?? '';
      navValue = _parseDouble(decodedItem['日增长率']) ?? 0.0;
    } else if (indicator.contains('排名')) {
      navDate = decodedItem['报告日期']?.toString() ?? '';
      // 修复后的字段名
      navValue = _parseDouble(decodedItem['同类型排名-每日近3月收益排名百分比']) ?? 0.0;
    } else if (indicator.contains('分红') || indicator.contains('送配')) {
      // 修复后的分红送配处理
      navDate = decodedItem['权益登记日']?.toString() ??
          decodedItem['除权除息日']?.toString() ??
          decodedItem['净值日期']?.toString() ??
          '';
      navValue = _parseDouble(decodedItem['每份分红']) ??
          _parseDouble(decodedItem['分红金额']) ??
          _parseDouble(decodedItem.values.first) ??
          0.0;
    } else if (indicator.contains('拆分')) {
      // 修复后的拆分处理
      navDate = decodedItem['拆分基准日']?.toString() ??
          decodedItem['除权日']?.toString() ??
          decodedItem['净值日期']?.toString() ??
          '';
      navValue = _parseDouble(decodedItem['拆分比例']) ??
          _parseDouble(decodedItem['拆分倍数']) ??
          _parseDouble(decodedItem.values.first) ??
          0.0;
    } else {
      // 默认使用单位净值
      navDate = decodedItem['净值日期']?.toString() ?? '';
      navValue = _parseDouble(decodedItem['单位净值']) ?? 0.0;
    }

    // 解析日期，只保留日期部分
    String displayDate = navDate;
    if (navDate.contains('T')) {
      displayDate = navDate.split('T')[0];
    }

    return {
      'date': displayDate,
      'value': navValue.toString(),
      'label': '$displayDate\n$indicator: ${navValue.toStringAsFixed(4)}',
    };
  } catch (e) {
    print('⚠️ 解析数据失败: $e');
    return null;
  }
}
