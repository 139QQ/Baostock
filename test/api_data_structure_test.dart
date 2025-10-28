import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  group('API数据结构诊断测试', () {
    void analyzeFundData(dynamic data, String fundType) {
      if (data is List && data.isNotEmpty) {
        print('📊 $fundType 数据条数: ${data.length}');

        final firstFund = data[0];
        print('📋 第一个${fundType}的数据结构:');
        print('   数据类型: ${firstFund.runtimeType}');

        if (firstFund is Map) {
          print('   字段列表: ${firstFund.keys.toList()}');

          // 分析常见的基金字段
          final commonFields = [
            'fcode',
            'fname',
            'NAV',
            'RZDF',
            'fsdm',
            'jjjc',
            'wfjx',
            '7nsyl'
          ];
          for (final field in commonFields) {
            final value = firstFund[field];
            final status = value != null ? '✅' : '❌';
            print('   $status $field: $value (${value?.runtimeType})');
          }

          // 特别检查空值问题
          _checkNullValues(firstFund, fundType);
        } else {
          print('⚠️ 第一个数据项不是Map格式');
        }
      } else {
        print('⚠️ $fundType 数据为空或格式不正确');
      }
    }

    test('诊断货币基金API返回的数据结构', () async {
      print('🧪 诊断货币基金API返回的数据结构...');

      try {
        final url =
            'http://154.44.25.92:8080/api/public/fund_money_fund_daily_em';
        final response = await http.get(Uri.parse(url));
        print('✅ API调用成功，状态码: ${response.statusCode}');

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          print('📊 响应类型: ${responseData.runtimeType}');

          // 检查响应结构
          if (responseData is List) {
            print('✅ 响应直接是List格式');
            analyzeFundData(responseData, '货币基金');
          } else if (responseData is Map) {
            print('📊 响应是Map格式，包含字段: ${responseData.keys.toList()}');
            if (responseData.containsKey('data')) {
              print('✅ 包含data字段');
              analyzeFundData(responseData['data'], '货币基金');
            } else {
              print('⚠️ Map格式但不包含data字段');
            }
          } else {
            print('❌ 未知响应格式: ${responseData.runtimeType}');
          }
        } else {
          print('❌ HTTP请求失败，状态码: ${response.statusCode}');
        }
      } catch (e) {
        print('❌ 请求异常: $e');
      }
    });

    test('诊断开放式基金API返回的数据结构', () async {
      print('🧪 诊断开放式基金API返回的数据结构...');

      try {
        final url =
            'http://154.44.25.92:8080/api/public/fund_open_fund_daily_em';
        final response = await http.get(Uri.parse(url));
        print('✅ API调用成功，状态码: ${response.statusCode}');

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          print('📊 响应类型: ${responseData.runtimeType}');

          // 检查响应结构
          if (responseData is List) {
            print('✅ 响应直接是List格式');
            analyzeFundData(responseData, '开放式基金');
          } else if (responseData is Map) {
            print('📊 响应是Map格式，包含字段: ${responseData.keys.toList()}');
            if (responseData.containsKey('data')) {
              print('✅ 包含data字段');
              analyzeFundData(responseData['data'], '开放式基金');
            } else {
              print('⚠️ Map格式但不包含data字段');
            }
          } else {
            print('❌ 未知响应格式: ${responseData.runtimeType}');
          }
        } else {
          print('❌ HTTP请求失败，状态码: ${response.statusCode}');
        }
      } catch (e) {
        print('❌ 请求异常: $e');
      }
    });
  });

  void _analyzeFundData(dynamic data, String fundType) {
    if (data is List && data.isNotEmpty) {
      print('📊 $fundType 数据条数: ${data.length}');

      final firstFund = data[0];
      print('📋 第一个${fundType}的数据结构:');
      print('   数据类型: ${firstFund.runtimeType}');

      if (firstFund is Map) {
        print('   字段列表: ${firstFund.keys.toList()}');

        // 分析常见的基金字段
        final commonFields = [
          'fcode',
          'fname',
          'NAV',
          'RZDF',
          'fsdm',
          'jjjc',
          'wfjx',
          '7nsyl'
        ];
        for (final field in commonFields) {
          final value = firstFund[field];
          final status = value != null ? '✅' : '❌';
          print('   $status $field: $value (${value?.runtimeType})');
        }

        // 特别检查空值问题
        _checkNullValues(firstFund, fundType);
      } else {
        print('⚠️ 第一个数据项不是Map格式');
      }
    } else {
      print('⚠️ $fundType 数据为空或格式不正确');
    }
  }

  void _checkNullValues(Map<String, dynamic> fundData, String fundType) {
    print('\n🔍 $fundType 空值检查:');

    final importantFields = {
      '基金代码': ['fcode', 'fsdm'],
      '基金名称': ['fname', 'jjjc'],
      '净值相关': ['NAV', 'wfjx'],
      '收益相关': ['RZDF', '7nsyl'],
    };

    for (final entry in importantFields.entries) {
      final category = entry.key;
      final fields = entry.value;

      bool hasValidValue = false;
      for (final field in fields) {
        if (fundData.containsKey(field) && fundData[field] != null) {
          hasValidValue = true;
          break;
        }
      }

      final status = hasValidValue ? '✅' : '❌';
      print('   $status $category: ${hasValidValue ? "有有效数据" : "全部为空或缺失"}');
    }
  }
}
