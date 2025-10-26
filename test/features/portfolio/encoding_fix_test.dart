import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

/// 中文编码问题诊断和修复测试
///
/// 问题分析：
/// - 现象：åä½åå¼ → 单位净值
/// - 原因：UTF-8字节被错误地用Latin-1解码
/// - 解决：重新编码为字节，然后用UTF-8解码
void main() {
  group('HTTP中文编码问题诊断与修复', () {
    const baseUrl = 'http://154.44.25.92:8080/api/public';

    test('诊断现有API响应的编码问题', () async {
      print('🔍 开始诊断HTTP响应编码问题...');

      final apiUrl =
          '$baseUrl/fund_open_fund_info_em?symbol=110022&indicator=单位净值走势';

      try {
        // 方法1：标准HTTP请求
        print('\n📋 方法1：标准HTTP请求');
        final response1 = await http.get(Uri.parse(apiUrl));

        print('   📊 响应状态码: ${response1.statusCode}');
        print('   📊 Content-Type: ${response1.headers['content-type']}');
        print('   📊 Content-Length: ${response1.headers['content-length']}');
        print('   📊 响应字节长度: ${response1.bodyBytes.length}');
        print('   📊 响应字符串长度: ${response1.body.length}');

        if (response1.statusCode == 200) {
          final data1 = jsonDecode(response1.body);
          if (data1 is List && data1.isNotEmpty) {
            final firstItem = data1[0];
            if (firstItem is Map) {
              print('   🔍 原始字段名示例:');
              firstItem.keys
                  .where((key) => key.contains('å'))
                  .take(3)
                  .forEach((key) {
                print('     $key → ${firstItem[key]}');
              });
            }
          }
        }

        // 方法2：尝试手动编码修复
        print('\n📋 方法2：手动编码修复测试');
        if (response1.statusCode == 200) {
          // 将乱码字符串重新编码为字节，然后用UTF-8解码
          final repairedResponse = _repairEncoding(response1.body);
          print('   🔧 修复后的响应长度: ${repairedResponse.length}');

          try {
            final data2 = jsonDecode(repairedResponse);
            if (data2 is List && data2.isNotEmpty) {
              final firstItem = data2[0];
              if (firstItem is Map) {
                print('   ✅ 修复后的字段名示例:');
                firstItem.keys
                    .where((key) => key.contains('净值'))
                    .take(3)
                    .forEach((key) {
                  print('     $key → ${firstItem[key]}');
                });
              }
            }
          } catch (e) {
            print('   ❌ JSON解析失败: $e');
          }
        }

        // 方法3：使用dart:io的HttpClient（更可控的编码处理）
        print('\n📋 方法3：使用dart:io HttpClient');
        final client = HttpClient();
        try {
          final request = await client.getUrl(Uri.parse(apiUrl));
          final response2 = await request.close();

          final responseData = await response2.transform(utf8.decoder).join();
          print('   📊 响应状态码: ${response2.statusCode}');
          print('   📊 Content-Type: ${response2.headers.contentType}');
          print('   📊 响应长度: ${responseData.length}');

          if (response2.statusCode == 200) {
            try {
              final data3 = jsonDecode(responseData);
              if (data3 is List && data3.isNotEmpty) {
                final firstItem = data3[0];
                if (firstItem is Map) {
                  print('   ✅ HttpClient字段名示例:');
                  firstItem.keys
                      .where((key) => key.contains('净值'))
                      .take(3)
                      .forEach((key) {
                    print('     $key → ${firstItem[key]}');
                  });
                }
              }
            } catch (e) {
              print('   ❌ JSON解析失败: $e');
            }
          }
        } finally {
          client.close();
        }

        // 方法4：直接处理字节流
        print('\n📋 方法4：直接字节流处理');
        final response3 = await http.get(Uri.parse(apiUrl));

        if (response3.statusCode == 200) {
          print('   🔍 检查字节序列:');
          final bytes = response3.bodyBytes;

          // 查找可能的UTF-8中文字符序列
          print('   📊 前100字节:');
          for (int i = 0; i < 100 && i < bytes.length; i++) {
            final byte = bytes[i];
            final char = String.fromCharCode(byte);
            print(
                '     $i: 0x${byte.toRadixString(16).padLeft(2, '0')} → $char');
          }

          // 尝试不同的编码方式
          print('\n   🔧 测试不同编码方式:');
          final encodings = [
            ('UTF-8', utf8),
            ('Latin-1', latin1),
            ('Windows-1252', Encoding.getByName('windows-1252')),
          ];

          for (final (name, encoding) in encodings) {
            try {
              if (encoding == null) {
                print('   ❌ $name 编码不可用');
                continue;
              }
              final decoded = encoding.decode(bytes);
              print('   📋 $name 解码结果:');

              // 检查是否包含中文字符
              final hasChinese = decoded.contains(RegExp(r'[\u4e00-\u9fff]'));
              print('     包含中文: $hasChinese');

              if (hasChinese) {
                // 尝试解析JSON
                try {
                  final jsonData = jsonDecode(decoded);
                  if (jsonData is List && jsonData.isNotEmpty) {
                    final firstItem = jsonData[0];
                    if (firstItem is Map) {
                      print('     ✅ $name 字段名示例:');
                      firstItem.keys
                          .where((key) => key.contains('净值'))
                          .take(2)
                          .forEach((key) {
                        print('       $key → ${firstItem[key]}');
                      });
                    }
                  }
                } catch (e) {
                  print('     ❌ $name JSON解析失败: $e');
                }
              }
            } catch (e) {
              print('     ❌ $name 解码失败: $e');
            }
          }
        }
      } catch (e) {
        print('❌ 诊断失败: $e');
      }
    });

    test('编码修复函数验证', () {
      print('\n🔧 测试编码修复函数...');

      // 测试已知的乱码问题
      final testCases = [
        ('åä½åå¼', '单位净值'),
        ('ç´¯è®¡åå¼', '累计净值'),
        ('åå¼æ¥æ', '净值日期'),
        ('åå¼åå', '净值类型'),
        ('ç³»ç»', '系统'),
      ];

      for (final (garbled, expected) in testCases) {
        final repaired = _repairEncoding(garbled);
        final success = repaired == expected;
        print('   ${success ? "✅" : "❌"} $garbled → $repaired (期望: $expected)');
      }
    });

    test('实现健壮的API客户端', () async {
      print('\n🚀 实现健壮的API客户端...');

      final client = _RobustApiClient();
      try {
        final result = await client.getJson(
            '$baseUrl/fund_open_fund_info_em?symbol=110022&indicator=单位净值走势');

        if (result != null && result is List && result.isNotEmpty) {
          final firstItem = result[0];
          if (firstItem is Map) {
            print('   ✅ 成功获取正确编码的数据:');
            firstItem.keys
                .where((key) => key.contains('净值'))
                .take(3)
                .forEach((key) {
              print('     $key → ${firstItem[key]}');
            });

            // 验证具体的数据
            final navValue = firstItem['单位净值'];
            final navDate = firstItem['净值日期'];
            print('   💰 单位净值: $navValue');
            print('   📅 净值日期: $navDate');

            expect(navValue, isNotNull);
            expect(navDate, isNotNull);
          }
        } else {
          print('   ⚠️ 未获取到有效数据');
        }
      } catch (e) {
        print('   ❌ API客户端调用失败: $e');
      }
    });
  });
}

/// 编码修复函数
/// 将被错误解码的字符串重新编码为字节，然后用UTF-8解码
String _repairEncoding(String garbled) {
  try {
    // 将乱码字符串编码为Latin-1字节（这是错误的解码方式）
    final bytes = latin1.encode(garbled);
    // 然后用UTF-8正确解码
    return utf8.decode(bytes, allowMalformed: true);
  } catch (e) {
    print('⚠️ 编码修复失败: $e');
    return garbled;
  }
}

/// 健壮的API客户端
/// 处理各种编码情况的HTTP客户端
class _RobustApiClient {
  Future<dynamic> getJson(String url, {int maxRetries = 3}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('   📡 尝试 $attempt/$maxRetries: $url');

        // 方法1：标准HTTP请求 + 编码修复
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          try {
            // 直接解析
            return jsonDecode(response.body);
          } catch (e) {
            try {
              // 尝试编码修复后解析
              final repaired = _repairEncoding(response.body);
              return jsonDecode(repaired);
            } catch (e2) {
              print('   ⚠️ 编码修复也失败，尝试其他方法');
            }
          }
        }

        // 方法2：使用dart:io HttpClient
        final client = HttpClient();
        try {
          final request = await client.getUrl(Uri.parse(url));
          final response = await request.close();
          final responseData = await response.transform(utf8.decoder).join();

          if (response.statusCode == 200) {
            return jsonDecode(responseData);
          }
        } finally {
          client.close();
        }

        print('   ⚠️ 尝试 $attempt 失败');

        // 等待后重试
        if (attempt < maxRetries) {
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        }
      } catch (e) {
        print('   ❌ 尝试 $attempt 异常: $e');
        if (attempt < maxRetries) {
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        }
      }
    }

    throw Exception('所有重试均失败');
  }
}
