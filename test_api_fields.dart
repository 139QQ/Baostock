import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  await testFundAPI();
}

Future<void> testFundAPI() async {
  const String apiUrl =
      'http://154.44.25.92:8080/api/public/fund_open_fund_info_em';

  // 测试不同的指标
  final indicators = ['累计净值走势', '单位净值走势', '累计收益率', '同类排名走势'];

  final fundCode = '009209';

  for (final indicator in indicators) {
    print('\n🔍 测试指标: $indicator');
    print('=' * 50);

    try {
      final String encodedIndicator = Uri.encodeComponent(indicator);
      final response = await http
          .get(
            Uri.parse('$apiUrl?symbol=$fundCode&indicator=$encodedIndicator'),
          )
          .timeout(const Duration(seconds: 15));

      print('状态码: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        print('数据条数: ${data.length}');

        if (data.isNotEmpty) {
          final firstItem = data.first as Map<String, dynamic>;
          print('所有字段: ${firstItem.keys.toList()}');
          print('第一条数据: $firstItem');

          // 检查关键字段
          final fieldsToCheck = [
            '净值日期',
            '单位净值',
            '累计净值',
            '累计收益率',
            '日增长率',
            '排名',
            '排名百分比'
          ];

          print('\n字段存在性检查:');
          for (final field in fieldsToCheck) {
            final exists = firstItem.containsKey(field);
            final value = exists ? firstItem[field] : 'N/A';
            print('  $field: $exists -> $value');
          }
        }
      } else {
        print('请求失败: ${response.body}');
      }
    } catch (e) {
      print('异常: $e');
    }
  }
}
