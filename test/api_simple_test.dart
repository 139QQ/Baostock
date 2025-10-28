import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  group('API空值问题诊断测试', () {
    test('测试货币基金API响应', () async {
      print('🧪 测试货币基金API响应...');

      try {
        final url =
            'http://154.44.25.92:8080/api/public/fund_money_fund_daily_em';
        final response = await http.get(Uri.parse(url));
        print('✅ API调用成功，状态码: ${response.statusCode}');

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          print('📊 响应结构: ${responseData.keys}');

          if (responseData['data'] != null && responseData['data'] is List) {
            final data = responseData['data'] as List;
            print('📊 数据条数: ${data.length}');

            if (data.isNotEmpty) {
              final firstFund = data[0];
              print('📋 第一个基金数据:');
              print('   基金代码: ${firstFund['fsdm']}');
              print('   基金名称: ${firstFund['jjjc']}');
              print('   万份收益: ${firstFund['wfjx']}');
              print('   7日年化: ${firstFund['7nsyl']}');

              // 检查空值
              if (firstFund['fsdm'] == null || firstFund['jjjc'] == null) {
                print('⚠️ 基金代码或名称为空');
              }
              if (firstFund['wfjx'] == null) {
                print('⚠️ 万份收益为空');
              }
              if (firstFund['7nsyl'] == null) {
                print('⚠️ 7日年化为空');
              }
            }
          }
        }
      } catch (e) {
        print('❌ API调用失败: $e');
      }
    });

    test('测试开放式基金API响应', () async {
      print('🧪 测试开放式基金API响应...');

      try {
        final url =
            'http://154.44.25.92:8080/api/public/fund_open_fund_daily_em';
        final response = await http.get(Uri.parse(url));
        print('✅ API调用成功，状态码: ${response.statusCode}');

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          print('📊 响应结构: ${responseData.keys}');

          if (responseData['data'] != null && responseData['data'] is List) {
            final data = responseData['data'] as List;
            print('📊 数据条数: ${data.length}');

            if (data.isNotEmpty) {
              final firstFund = data[0];
              print('📋 第一个基金数据:');
              print('   基金代码: ${firstFund['fcode']}');
              print('   基金名称: ${firstFund['fname']}');
              print('   当前净值: ${firstFund['NAV']}');
              print('   日涨跌幅: ${firstFund['RZDF']}');

              // 检查空值
              if (firstFund['fcode'] == null || firstFund['fname'] == null) {
                print('⚠️ 基金代码或名称为空');
              }
              if (firstFund['NAV'] == null) {
                print('⚠️ 当前净值为空');
              }
              if (firstFund['RZDF'] == null) {
                print('⚠️ 日涨跌幅为空');
              }
            }
          }
        }
      } catch (e) {
        print('❌ API调用失败: $e');
      }
    });

    test('测试URL格式和参数', () async {
      print('🧪 测试URL格式和参数...');

      final urls = [
        'http://154.44.25.92:8080/api/public/fund_money_fund_daily_em',
        'http://154.44.25.92:8080/api/public/fund_open_fund_daily_em',
        'http://154.44.25.92:8080/api/public/fund_open_fund_info_em',
      ];

      for (final url in urls) {
        try {
          final uri = Uri.parse(url);
          print('✅ URL格式正确: ${uri.host}:${uri.port}${uri.path}');
          print('📋 查询参数: ${uri.query}');
        } catch (e) {
          print('❌ URL格式错误: $url - $e');
        }
      }
    });
  });
}
