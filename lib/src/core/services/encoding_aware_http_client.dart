import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// 支持正确中文编码的HTTP客户端
///
/// 解决问题：
/// - 标准http包在某些情况下会错误解码UTF-8中文字符
/// - 使用dart:io HttpClient确保正确的UTF-8解码
/// - 提供备用编码修复机制
class EncodingAwareHttpClient {
  static final EncodingAwareHttpClient _instance =
      EncodingAwareHttpClient._internal();
  factory EncodingAwareHttpClient() => _instance;
  EncodingAwareHttpClient._internal();

  /// 执行GET请求并确保正确的中文编码
  ///
  /// 优先级：
  /// 1. dart:io HttpClient (最可靠)
  /// 2. 标准http包 + UTF-8修复
  /// 3. 标准http包 (备用)
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    debugPrint('📡 EncodingAwareHttpClient: ${url.toString()}');

    // 方法1：使用dart:io HttpClient (首选)
    try {
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) => true; // 临时处理SSL证书

      final request = await client.getUrl(url);

      // 设置请求头
      if (headers != null) {
        headers.forEach((key, value) {
          request.headers.set(key, value);
        });
      }

      request.headers.set('Accept', 'application/json');
      request.headers.set('Accept-Charset', 'utf-8');
      request.headers.set('User-Agent', 'Dart-Client/EncodingAware');

      final response = await request.close();

      // 读取字节并确保UTF-8解码
      final responseBody = await response.transform(utf8.decoder).join();
      final responseBytes = await response.fold<List<int>>(
        <int>[],
        (dynamic previous, element) => previous..addAll(element),
      );

      client.close();

      // 构造标准http.Response对象
      final responseHeaders = <String, String>{};
      response.headers.forEach((name, values) {
        responseHeaders[name] = values.join(', ');
      });

      final httpResponse = http.Response.bytes(
        responseBytes,
        response.statusCode,
        headers: responseHeaders,
      );

      // 验证是否包含中文
      final hasChinese = responseBody.contains(RegExp(r'[\u4e00-\u9fff]'));
      debugPrint(
          '   ✅ HttpClient结果: 状态码=${response.statusCode}, 包含中文=$hasChinese');

      return httpResponse;
    } catch (e) {
      debugPrint('   ⚠️ HttpClient失败，尝试备用方案: $e');

      // 方法2：标准http包 + 编码修复
      try {
        final response = await http.get(url, headers: headers);

        if (response.statusCode == 200) {
          // 检查是否需要编码修复
          final hasChinese = response.body.contains(RegExp(r'[\u4e00-\u9fff]'));

          if (!hasChinese && response.body.contains(RegExp(r'[åæçè]'))) {
            // 包含乱码字符，尝试修复
            debugPrint('   🔧 检测到乱码，尝试编码修复...');
            final fixedBody = _fixEncoding(response.body);
            return http.Response(
              fixedBody,
              response.statusCode,
              headers: response.headers,
            );
          }
        }

        return response;
      } catch (e2) {
        debugPrint('   ❌ 所有方法均失败: $e2');
        rethrow;
      }
    }
  }

  /// 执行POST请求并确保正确的中文编码
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    debugPrint('📡 EncodingAwareHttpClient POST: ${url.toString()}');

    try {
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) => true;

      final request = await client.postUrl(url);

      // 设置请求头
      if (headers != null) {
        headers.forEach((key, value) {
          request.headers.set(key, value);
        });
      }
      request.headers.set('Content-Type', 'application/json; charset=utf-8');
      request.headers.set('Accept', 'application/json');
      request.headers.set('Accept-Charset', 'utf-8');
      request.headers.set('User-Agent', 'Dart-Client/EncodingAware');

      // 设置请求体
      if (body != null) {
        if (body is String) {
          request.add(utf8.encode(body));
        } else if (body is List<int>) {
          request.add(body);
        }
      }

      final response = await request.close();
      final responseBytes = await response.fold<List<int>>(
        <int>[],
        (dynamic previous, element) => previous..addAll(element),
      );

      client.close();

      final responseHeaders = <String, String>{};
      response.headers.forEach((name, values) {
        responseHeaders[name] = values.join(', ');
      });

      return http.Response.bytes(
        responseBytes,
        response.statusCode,
        headers: responseHeaders,
      );
    } catch (e) {
      debugPrint('   ⚠️ HttpClient POST失败，使用标准方法: $e');
      return await http.post(url,
          headers: headers, body: body, encoding: encoding);
    }
  }

  /// 修复编码问题的核心方法
  ///
  /// 原理：
  /// 1. UTF-8的中文字符被错误地用Latin-1解码
  /// 2. 例如："净"(UTF-8: e5 87 80) → Latin-1解码 → "å87"
  /// 3. 修复：重新编码为Latin-1字节，然后用UTF-8解码
  String _fixEncoding(String garbled) {
    try {
      // 将乱码字符串重新编码为Latin-1字节
      final bytes = latin1.encode(garbled);
      // 然后用UTF-8正确解码
      return utf8.decode(bytes, allowMalformed: true);
    } catch (e) {
      debugPrint('⚠️ 编码修复失败: $e');
      return garbled;
    }
  }

  /// 检查字符串是否包含中文乱码
  bool hasChineseGarbled(String text) {
    // 检查是否包含常见的乱码模式
    final garbledPatterns = [
      RegExp(r'å[æçè][\x80-\xbf]'), // å开头的三字符模式
      RegExp(r'[æçè][\x80-\xbf][\x80-\xbf]'), // æ/ç/è开头的三字符模式
      RegExp(r'Ã[â-û][\x80-\xbf]'), // Ã开头的模式
    ];

    return garbledPatterns.any((pattern) => pattern.hasMatch(text));
  }

  /// 批量修复JSON响应中的编码问题
  String fixJsonEncoding(String jsonString) {
    if (!hasChineseGarbled(jsonString)) {
      return jsonString; // 无需修复
    }

    debugPrint('🔧 修复JSON编码问题...');

    try {
      // 方法1：整体修复
      final fixed = _fixEncoding(jsonString);

      // 验证修复结果
      try {
        jsonDecode(fixed); // 尝试解析JSON
        debugPrint('   ✅ JSON编码修复成功');
        return fixed;
      } catch (e) {
        debugPrint('   ⚠️ 整体修复失败，尝试局部修复...');
      }

      // 方法2：局部修复（只修复字符串值）
      return _fixJsonPartial(jsonString);
    } catch (e) {
      debugPrint('   ❌ JSON编码修复失败: $e');
      return jsonString;
    }
  }

  /// 局部修复JSON字符串中的编码问题
  String _fixJsonPartial(String jsonString) {
    // 这里可以实现更复杂的局部修复逻辑
    // 暂时返回原始字符串
    return jsonString;
  }
}
