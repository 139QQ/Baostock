import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;

/// API端点检查工具
void main() async {
  print('🔍 检查基金API端点...\n');

  const String baseUrl = 'http://154.44.25.92:8080';

  // 所有可用的API端点
  final endpoints = [
    '/api/public/fund_name_em', // 基金名称
    '/api/public/fund_open_fund_rank_em', // 基金排行
    '/api/public/fund_open_fund_daily_em', // 基金实时行情
    '/api/public/fund_etf_spot_em', // ETF实时行情
    '/api/public/fund_purchase_em', // 基金申购状态
    '/api/public/fund_manager_em', // 基金经理信息
  ];

  final Map<String, dynamic> results = {};

  for (final endpoint in endpoints) {
    print('📍 检查端点: $endpoint');

    try {
      final startTime = DateTime.now();

      // 不带参数的请求
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'API-Checker/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      final duration = DateTime.now().difference(startTime);

      print('  ✅ 状态码: ${response.statusCode}');
      print('  ⏱️ 响应时间: ${duration.inMilliseconds}ms');
      print('  📄 内容长度: ${response.body.length} 字符');

      // 尝试解析响应内容
      if (response.body.isNotEmpty) {
        try {
          final jsonData = json.decode(response.body);
          print('  📊 数据类型: ${jsonData.runtimeType}');
          if (jsonData is List) {
            print('  📋 数组长度: ${jsonData.length}');
            if (jsonData.isNotEmpty && jsonData[0] is Map) {
              final firstItem = jsonData[0] as Map;
              print('  🔍 示例字段: ${firstItem.keys.take(5).join(', ')}');
            }
          } else if (jsonData is Map) {
            print('  🔍 对象字段: ${jsonData.keys.take(5).join(', ')}');
          }
        } catch (e) {
          print('  ⚠️ JSON解析失败: ${e.runtimeType}');
          print(
              '  📄 原始内容预览: ${response.body.substring(0, math.min(100, response.body.length))}...');
        }
      }

      results[endpoint] = {
        'status': response.statusCode,
        'success': response.statusCode == 200,
        'duration': duration.inMilliseconds,
        'contentLength': response.body.length,
        'canParse': response.body.isNotEmpty && _isValidJson(response.body),
      };
    } catch (e) {
      print('  ❌ 错误: ${e.runtimeType}');
      print('  📝 详情: $e');

      results[endpoint] = {
        'status': 'ERROR',
        'success': false,
        'error': e.toString(),
      };
    }

    print('');
  }

  // 生成端点使用建议
  print('📋 端点状态总结:');
  print('=' * 50);

  int workingEndpoints = 0;
  for (final entry in results.entries) {
    final endpoint = entry.key;
    final result = entry.value;

    if (result['success'] == true) {
      workingEndpoints++;
      print('✅ $endpoint - 可用');
    } else {
      print('❌ $endpoint - 不可用');
    }
  }

  print('\n🎯 可用端点数: $workingEndpoints/${endpoints.length}');

  // 推荐使用可用的端点
  final availableEndpoints = results.entries
      .where((e) => e.value['success'] == true)
      .map((e) => e.key)
      .toList();

  if (availableEndpoints.isNotEmpty) {
    print('\n💡 推荐使用的端点:');
    for (final endpoint in availableEndpoints) {
      print('   • $endpoint');
    }
  } else {
    print('\n⚠️ 所有端点都不可用，请检查:');
    print('   • 服务器地址是否正确: $baseUrl');
    print('   • 网络连接是否正常');
    print('   • API服务是否正在运行');
  }

  // 检查特定端点的参数支持
  if (results.containsKey('/api/public/fund_open_fund_rank_em') &&
      results['/api/public/fund_open_fund_rank_em']['success'] == true) {
    print('\n🔧 测试基金排行端点参数:');

    final testParams = [
      '全部',
      '股票型',
      '混合型',
      '债券型',
      'equity', // 英文参数测试
      'mixed',
    ];

    for (final param in testParams) {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/api/public/fund_open_fund_rank_em')
              .replace(queryParameters: {'symbol': param}),
          headers: {'Accept': 'application/json'},
        ).timeout(const Duration(seconds: 10));

        final status = response.statusCode == 200 ? '✅' : '❌';
        print('   $status symbol=$param -> ${response.statusCode}');
      } catch (e) {
        print('   ❌ symbol=$param -> 错误: ${e.runtimeType}');
      }
    }
  }
}

/// 检查是否为有效JSON
bool _isValidJson(String str) {
  try {
    json.decode(str);
    return true;
  } catch (e) {
    return false;
  }
}
