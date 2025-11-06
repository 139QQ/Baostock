import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  const baseUrl = 'http://154.44.25.92:8080';

  print('🧪 测试网络请求...');

  try {
    // 测试简单的GET请求
    print('\n1. 测试基础连通性:');
    final url = Uri.parse('$baseUrl/api/public/fund_open_fund_rank_em');
    print('URL: $url');

    // 使用curl风格的请求
    final request = http.Request('GET', url);
    request.headers.addAll({
      'User-Agent': 'TestApp/1.0',
      'Accept': 'application/json',
      'Connection': 'close',
    });

    print('发送请求...');
    final stopwatch = Stopwatch()..start();

    final streamedResponse =
        await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamedResponse)
        .timeout(const Duration(seconds: 30));

    stopwatch.stop();

    print('✅ 请求完成 (耗时: ${stopwatch.elapsedMilliseconds}ms)');
    print('状态码: ${response.statusCode}');
    print('响应大小: ${response.body.length} 字节');

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        print('✅ JSON解析成功，数据类型: ${data.runtimeType}');

        if (data is List && data.isNotEmpty) {
          final firstItem = data[0];
          print('✅ 数据验证成功');
          print('示例数据键: ${(firstItem as Map).keys.join(', ')}');

          // 检查必需字段
          final requiredFields = ['基金代码', '基金简称', '单位净值'];
          final missingFields = requiredFields
              .where((field) => !(firstItem).containsKey(field));

          if (missingFields.isEmpty) {
            print('✅ 必需字段验证通过');
            print('基金代码示例: ${firstItem['基金代码']}');
            print('基金简称示例: ${firstItem['基金简称']}');
          } else {
            print('⚠️ 缺少必需字段: ${missingFields.join(', ')}');
          }
        }
      } catch (e) {
        print('❌ JSON解析失败: $e');
        print(
            '原始数据前100字符: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}');
      }
    } else {
      print('❌ HTTP错误: ${response.statusCode}');
      print('响应头: ${response.headers}');
    }
  } catch (e) {
    print('❌ 请求异常: $e');
    print('异常类型: ${e.runtimeType}');

    if (e is SocketException) {
      print('💡 SocketException通常表示网络连接问题');
    } else if (e.toString().contains('TimeoutException')) {
      print('💡 TimeoutException表示请求超时');
    } else if (e is HttpException) {
      print('💡 HttpException表示HTTP协议错误');
    }
  }

  print('\n🏁 测试完成');
}
