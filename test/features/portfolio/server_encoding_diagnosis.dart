import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

/// 服务器编码诊断测试
///
/// 关键前提：确认服务器实际返回的编码格式
void main() {
  group('服务器编码诊断', () {
    const testUrl =
        'http://154.44.25.92:8080/api/public/fund_open_fund_info_em?symbol=110022&indicator=%E5%8D%95%E4%BD%8D%E5%87%80%E5%80%BC%E8%B5%B0%E5%8A%BF';

    test('步骤1：检查HTTP响应头和Content-Type', () async {
      print('🔍 步骤1：详细分析HTTP响应头...');
      print('   📡 测试URL: $testUrl');

      try {
        final response = await http.get(Uri.parse(testUrl));

        print('\n   📊 HTTP响应基本信息:');
        print('     状态码: ${response.statusCode}');
        print('     响应长度: ${response.body.length} 字节');
        print('     响应头Content-Type: ${response.headers['content-type']}');

        print('\n   📋 完整响应头:');
        response.headers.forEach((key, value) {
          print('     $key: $value');
        });

        print('\n   🔍 字符编码分析:');

        // 检查Content-Type中的charset
        final contentType = response.headers['content-type'] ?? '';
        if (contentType.contains('charset=')) {
          final charset = contentType.split('charset=')[1].split(';')[0].trim();
          print('     服务器声明编码: $charset');

          if (charset.toUpperCase() == 'GBK' ||
              charset.toUpperCase() == 'GB2312') {
            print('     ✅ 发现：服务器使用GBK编码！');
            print('     💡 解决方案：需要使用GBK解码');
          } else if (charset.toUpperCase() == 'UTF-8') {
            print('     ✅ 发现：服务器声明使用UTF-8编码');
            print('     ⚠️ 但如果仍有乱码，可能是实际编码与声明不符');
          } else {
            print('     ⚠️ 未知编码格式: $charset');
          }
        } else {
          print('     ⚠️ Content-Type未指定charset');
          print('     💡 需要通过字节分析推断实际编码');
        }

        print('\n   🔍 响应体字节序列分析:');
        final bytes = response.bodyBytes;
        print('     前64字节:');
        for (int i = 0; i < 64 && i < bytes.length; i++) {
          final byte = bytes[i];
          final hex = byte.toRadixString(16).padLeft(2, '0').toUpperCase();
          final char =
              byte >= 32 && byte <= 126 ? String.fromCharCode(byte) : '.';
          print('       ${i.toString().padLeft(2)}: 0x$hex ($char)');
        }

        print('\n   🔍 编码模式检测:');

        // 检测UTF-8 BOM
        if (bytes.length >= 3 &&
            bytes[0] == 0xEF &&
            bytes[1] == 0xBB &&
            bytes[2] == 0xBF) {
          print('     ✅ 检测到UTF-8 BOM');
        }

        // 检测中文字符的UTF-8编码模式
        int utf8ChineseCount = 0;
        int gbkChineseCount = 0;

        for (int i = 0; i < bytes.length - 2; i++) {
          // UTF-8中文字符模式：E4-E9 开头的三字节序列
          if (bytes[i] >= 0xE4 &&
              bytes[i] <= 0xE9 &&
              bytes[i + 1] >= 0x80 &&
              bytes[i + 1] <= 0xBF &&
              bytes[i + 2] >= 0x80 &&
              bytes[i + 2] <= 0xBF) {
            utf8ChineseCount++;
          }

          // GBK中文字符模式：第一个字节 > 0x80
          if (bytes[i] > 0x80 && i < bytes.length - 1) {
            gbkChineseCount++;
          }
        }

        print('     UTF-8中文字符模式计数: $utf8ChineseCount');
        print('     GBK中文字符模式计数: $gbkChineseCount');

        if (utf8ChineseCount > gbkChineseCount * 2) {
          print('     💡 推测：响应很可能是UTF-8编码');
        } else if (gbkChineseCount > utf8ChineseCount) {
          print('     💡 推测：响应很可能是GBK编码');
        } else {
          print('     ⚠️ 编码模式不明确，需要进一步分析');
        }
      } catch (e) {
        print('   ❌ HTTP请求失败: $e');
      }
    });

    test('步骤2：对比不同解码方法的效果', () async {
      print('\n🔍 步骤2：测试不同解码方法...');

      try {
        final response = await http.get(Uri.parse(testUrl));
        if (response.statusCode != 200) {
          print('   ❌ API返回错误状态码: ${response.statusCode}');
          return;
        }

        final bytes = response.bodyBytes;
        print('   📊 原始字节长度: ${bytes.length}');

        // 方法1：UTF-8解码
        print('\n   📋 方法1：UTF-8解码');
        try {
          final utf8Decoded = utf8.decode(bytes, allowMalformed: true);
          final hasChinese = utf8Decoded.contains(RegExp(r'[\u4e00-\u9fff]'));
          final hasGarbled = utf8Decoded.contains(RegExp(r'[åæçè]'));

          print('     包含中文字符: $hasChinese');
          print('     包含乱码字符: $hasGarbled');

          if (hasChinese && !hasGarbled) {
            print('     ✅ UTF-8解码成功！');

            // 显示正确的中文
            final data = jsonDecode(utf8Decoded);
            if (data is List && data.isNotEmpty) {
              final firstItem = data[0];
              if (firstItem is Map) {
                print('     📋 正确的中文字段:');
                firstItem.keys
                    .where((key) => key.contains('净值'))
                    .take(3)
                    .forEach((key) {
                  print('       $key → ${firstItem[key]}');
                });
              }
            }
          } else if (!hasChinese && hasGarbled) {
            print('     ❌ UTF-8解码产生乱码');
          } else {
            print('     ⚠️ UTF-8解码结果不明确');
          }
        } catch (e) {
          print('     ❌ UTF-8解码失败: $e');
        }

        // 方法2：GBK解码（如果需要）
        print('\n   📋 方法2：GBK解码');
        try {
          final gbkDecoded = gbk.decode(bytes);
          final hasChinese = gbkDecoded.contains(RegExp(r'[\u4e00-\u9fff]'));
          final hasGarbled = gbkDecoded.contains(RegExp(r'[åæçè]'));

          print('     包含中文字符: $hasChinese');
          print('     包含乱码字符: $hasGarbled');

          if (hasChinese && !hasGarbled) {
            print('     ✅ GBK解码成功！');
            print('     💡 服务器实际使用GBK编码！');

            // 显示正确的中文
            try {
              final data = jsonDecode(gbkDecoded);
              if (data is List && data.isNotEmpty) {
                final firstItem = data[0];
                if (firstItem is Map) {
                  print('     📋 正确的中文字段:');
                  firstItem.keys
                      .where((key) => key.contains('净值'))
                      .take(3)
                      .forEach((key) {
                    print('       $key → ${firstItem[key]}');
                  });
                }
              }
            } catch (e) {
              print('     ⚠️ GBK解码成功但JSON解析失败: $e');
            }
          } else {
            print('     ❌ GBK解码未产生正确中文');
          }
        } catch (e) {
          print('     ❌ GBK解码失败: $e');
        }

        // 方法3：Latin-1 + UTF-8修复（针对编码声明错误的情况）
        print('\n   📋 方法3：Latin-1解码 + UTF-8修复');
        try {
          final latin1Decoded = latin1.decode(bytes);
          final fixed = latin1.encode(latin1Decoded);
          final utf8Fixed = utf8.decode(fixed, allowMalformed: true);

          final hasChinese = utf8Fixed.contains(RegExp(r'[\u4e00-\u9fff]'));
          final hasGarbled = utf8Fixed.contains(RegExp(r'[åæçè]'));

          print('     包含中文字符: $hasChinese');
          print('     包含乱码字符: $hasGarbled');

          if (hasChinese && !hasGarbled) {
            print('     ✅ Latin-1+UTF-8修复成功！');
            print('     💡 服务器声明UTF-8但实际按Latin-1发送！');

            // 显示正确的中文
            try {
              final data = jsonDecode(utf8Fixed);
              if (data is List && data.isNotEmpty) {
                final firstItem = data[0];
                if (firstItem is Map) {
                  print('     📋 修复后的中文字段:');
                  firstItem.keys
                      .where((key) => key.contains('净值'))
                      .take(3)
                      .forEach((key) {
                    print('       $key → ${firstItem[key]}');
                  });
                }
              }
            } catch (e) {
              print('     ⚠️ 修复成功但JSON解析失败: $e');
            }
          } else {
            print('     ❌ Latin-1+UTF-8修复未产生正确中文');
          }
        } catch (e) {
          print('     ❌ Latin-1+UTF-8修复失败: $e');
        }
      } catch (e) {
        print('   ❌ 解码方法测试失败: $e');
      }
    });

    test('步骤3：URL编码问题检查', () {
      print('\n🔍 步骤3：URL编码问题分析...');

      const originalParam = '单位净值走势';
      final urlEncoded = Uri.encodeComponent(originalParam);

      print('   📋 原始参数: $originalParam');
      print('   📋 URL编码后: $urlEncoded');
      print(
          '   📋 测试URL中使用的编码: %E5%8D%95%E4%BD%8D%E5%87%80%E5%80%BC%E8%B5%B0%E5%8A%BF');

      if (urlEncoded ==
          '%E5%8D%95%E4%BD%8D%E5%87%80%E5%80%BC%E8%B5%B0%E5%8A%BF') {
        print('   ✅ URL编码正确，参数编码无误');
      } else {
        print('   ⚠️ URL编码可能有问题');
      }

      // 解码验证
      final decoded = Uri.decodeComponent(
          '%E5%8D%95%E4%BD%8D%E5%87%80%E5%80%BC%E8%B5%B0%E5%8A%BF');
      print('   📋 URL解码验证: $decoded');

      if (decoded == originalParam) {
        print('   ✅ URL编码解码验证通过');
      } else {
        print('   ❌ URL编码解码验证失败');
      }
    });
  });
}

// GBK编码解码器（简化版）
class GbkCodec extends Codec<String, List<int>> {
  const GbkCodec();

  @override
  Converter<List<int>, String> get decoder => const GbkDecoder();

  @override
  Converter<String, List<int>> get encoder => const GbkEncoder();
}

class GbkDecoder extends Converter<List<int>, String> {
  const GbkDecoder();

  @override
  String convert(List<int> input) {
    // 简化的GBK解码实现
    // 注意：这是一个简化版本，实际生产环境应使用完整的GBK库
    try {
      // 尝试按GBK模式解码
      final result = StringBuffer();

      for (int i = 0; i < input.length; i++) {
        final byte = input[i];

        if (byte <= 0x7F) {
          // ASCII字符
          result.writeCharCode(byte);
        } else if (byte >= 0x81 && byte <= 0xFE && i + 1 < input.length) {
          // GBK双字节字符
          final byte2 = input[i + 1];
          if (byte2 >= 0x40 && byte2 <= 0xFE) {
            // 简化处理：将GBK字节映射为Unicode（这里只是示例）
            // 实际需要完整的GBK到Unicode映射表
            result.write('?'); // 占位符
            i++; // 跳过第二个字节
          } else {
            result.writeCharCode(0xFFFD); // 替换字符
          }
        } else {
          result.writeCharCode(0xFFFD); // 替换字符
        }
      }

      return result.toString();
    } catch (e) {
      // 解码失败，返回原字符串的Latin-1解码
      return latin1.decode(input);
    }
  }
}

class GbkEncoder extends Converter<String, List<int>> {
  const GbkEncoder();

  @override
  List<int> convert(String input) {
    // 简化的GBK编码实现
    final result = <int>[];

    for (int i = 0; i < input.length; i++) {
      final char = input.codeUnitAt(i);

      if (char <= 0x7F) {
        // ASCII字符
        result.add(char);
      } else if (char >= 0x4E00 && char <= 0x9FFF) {
        // 中文字符（简化处理）
        result.add(0x3F); // 占位符
      } else {
        result.add(0x3F); // 占位符
      }
    }

    return result;
  }
}

const gbk = GbkCodec();
