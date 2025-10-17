import 'package:http/http.dart' as http;

/// 测试基金API响应，调试编码问题
Future<void> testFundApiEncoding() async {
  try {
    print('🔍 开始测试基金API编码问题...\n');

    // 测试基金排行API
    const url = 'http://154.44.25.92:8080/api/public/fund_open_fund_rank_em';
    print('🌐 请求URL: $url');

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json; charset=utf-8',
        'Content-Type': 'application/json; charset=utf-8',
      },
    ).timeout(const Duration(seconds: 30));

    print('\n📊 响应状态码: ${response.statusCode}');
    print('📄 响应头: ${response.headers}');

    if (response.statusCode == 200) {
      // 获取原始字节
      final bytes = response.bodyBytes;
      print('📦 原始字节数: ${bytes.length}');

      // 尝试不同的编码方式解码
      print('\n🔧 测试不同编码方式...');

      // 1. 默认UTF-8解码
      try {
        final utf8Data = utf8.decode(bytes);
        print('✅ UTF-8解码成功，长度: ${utf8Data.length}');
        print(
            '🔍 UTF-8前100字符: ${utf8Data.length > 100 ? utf8Data.substring(0, 100) : utf8Data}');

        // 解析JSON并检查第一条记录
        final jsonData = json.decode(utf8Data);
        if (jsonData is List && jsonData.isNotEmpty) {
          final firstItem = jsonData.first;
          print('\n📋 第一条记录字段:');
          firstItem.forEach((key, value) {
            print('  $key: $value');
          });
        }
      } catch (e) {
        print('❌ UTF-8解码失败: $e');
      }

      // 2. Latin-1解码然后UTF-8重新解码（处理错误编码）
      try {
        final latin1Data = latin1.decode(bytes);
        final latin1Bytes = latin1.encode(latin1Data);
        final fixedData = utf8.decode(latin1Bytes);
        print('\n✅ Latin-1转UTF-8解码成功，长度: ${fixedData.length}');
        print(
            '🔍 修复后前100字符: ${fixedData.length > 100 ? fixedData.substring(0, 100) : fixedData}');

        // 解析JSON并检查第一条记录
        final jsonData = json.decode(fixedData);
        if (jsonData is List && jsonData.isNotEmpty) {
          final firstItem = jsonData.first;
          print('\n📋 修复后第一条记录字段:');
          firstItem.forEach((key, value) {
            print('  $key: $value');
          });
        }
      } catch (e) {
        print('❌ Latin-1转UTF-8解码失败: $e');
      }
    } else {
      print('❌ API请求失败: ${response.statusCode}');
      print('📄 响应内容: ${response.body}');
    }
  } catch (e) {
    print('❌ 测试失败: $e');
  }
}

void main() {
  testFundApiEncoding();
}
