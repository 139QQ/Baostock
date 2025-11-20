import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// 安全工具类 - 简化版本
///
/// 提供API签名、加密、输入验证等安全功能
class SecurityUtils {
  static const String _apiSecret = 'JISU_FUND_SECRET_KEY_2025_SECURE';
  static const Duration _timestampTolerance = Duration(minutes: 5);

  /// 生成请求签名
  static String generateSignature({
    required String method,
    required String path,
    required Map<String, dynamic> params,
    required String timestamp,
    required String requestId,
  }) {
    // 按照规范构建签名字符串
    final signatureData = [
      method.toUpperCase(),
      path,
      _sortedParamsToString(params),
      timestamp,
      requestId,
      _apiSecret,
    ].join('|');

    final bytes = utf8.encode(signatureData);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 验证请求签名
  static bool verifySignature({
    required String method,
    required String path,
    required Map<String, dynamic> params,
    required String timestamp,
    required String requestId,
    required String receivedSignature,
  }) {
    try {
      // 检查时间戳有效性
      final requestTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(requestTime);

      if (difference > _timestampTolerance) {
        return false;
      }

      // 生成期望的签名
      final expectedSignature = generateSignature(
        method: method,
        path: path,
        params: params,
        timestamp: timestamp,
        requestId: requestId,
      );

      return expectedSignature == receivedSignature;
    } catch (e) {
      return false;
    }
  }

  /// 将参数转换为排序后的字符串
  static String _sortedParamsToString(Map<String, dynamic> params) {
    final sortedKeys = params.keys.toList()..sort();
    final keyValues = sortedKeys.map((key) => '$key=${params[key]}');
    return keyValues.join('&');
  }

  /// 生成随机字符串
  static String generateRandomString(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(
          length, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  /// 生成时间戳
  static String generateTimestamp() {
    return DateTime.now().toIso8601String();
  }

  /// 生成请求ID
  static String generateRequestId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${generateRandomString(8)}';
  }

  /// 输入验证 - 检查是否包含危险字符
  static bool containsDangerousCharacters(String input) {
    if (input.isEmpty) return false;

    final dangerousPatterns = [
      r'<[^>]*>', // HTML标签
      r'javascript:', // JavaScript协议
      r'on\w+\s*=', // 事件处理器
      r'(union|select|insert|update|delete|drop)', // SQL关键词
    ];

    return dangerousPatterns.any(
        (pattern) => RegExp(pattern, caseSensitive: false).hasMatch(input));
  }

  /// SQL注入检测
  static bool containsSqlInjection(String input) {
    if (input.isEmpty) return false;

    final sqlPatterns = [
      r'(?i)(union|select|insert|update|delete|drop|create|alter|exec|execute)',
      r'(?i)(--|#|/\*|\*/)',
      r'(?i)(or|and)\s+\d+\s*=\s*\d+',
      r"(?i)(or|and)\s+'\w*'\s*=\s*'\w*'",
    ];

    return sqlPatterns.any((pattern) => RegExp(pattern).hasMatch(input));
  }

  /// XSS检测
  static bool containsXss(String input) {
    if (input.isEmpty) return false;

    final xssPatterns = [
      r'<script[^>]*>.*?</script>',
      r'<iframe[^>]*>.*?</iframe>',
      r'javascript:',
      r'on\w+\s*=',
      r'<[^>]*on\w+\s*=',
    ];

    return xssPatterns.any(
        (pattern) => RegExp(pattern, caseSensitive: false).hasMatch(input));
  }

  /// 验证邮箱格式
  static bool isValidEmail(String email) {
    final emailPattern =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailPattern.hasMatch(email);
  }

  /// 验证手机号格式（中国）
  static bool isValidPhoneNumber(String phone) {
    final phonePattern = RegExp(r'^1[3-9]\d{9}$');
    return phonePattern.hasMatch(phone);
  }

  /// 验证基金代码格式
  static bool isValidFundCode(String code) {
    // 基金代码通常是6位数字
    final fundCodePattern = RegExp(r'^\d{6}$');
    return fundCodePattern.hasMatch(code);
  }

  /// 清理和验证输入
  static String sanitizeInput(String input) {
    if (input.isEmpty) return '';

    // 移除HTML标签
    String sanitized = input.replaceAll(RegExp(r'<[^>]*>'), '');

    // 移除JavaScript事件处理器
    sanitized =
        sanitized.replaceAll(RegExp(r'on\w+\s*=', caseSensitive: false), '');

    // 移除JavaScript协议
    sanitized =
        sanitized.replaceAll(RegExp(r'javascript:', caseSensitive: false), '');

    // 限制长度
    if (sanitized.length > 1000) {
      sanitized = sanitized.substring(0, 1000);
    }

    return sanitized.trim();
  }

  /// 生成HMAC签名
  static String generateHmac(String data, String secret) {
    final key = utf8.encode(secret);
    final bytes = utf8.encode(data);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    return digest.toString();
  }

  /// 验证HMAC签名
  static bool verifyHmac(String data, String signature, String secret) {
    final expectedSignature = generateHmac(data, secret);
    return expectedSignature == signature;
  }
}

/// 安全监控器
class SecurityMonitor {
  final List<Map<String, dynamic>> _securityEvents = [];
  static const int _maxEvents = 1000;

  /// 记录安全事件
  void recordSecurityEvent({
    required String type,
    required String description,
    String? clientIp,
    Map<String, dynamic>? details,
  }) {
    final event = {
      'type': type,
      'description': description,
      'clientIp': clientIp ?? 'unknown',
      'details': details ?? {},
      'timestamp': DateTime.now().toIso8601String(),
    };

    _securityEvents.add(event);

    // 保持事件列表在合理大小
    if (_securityEvents.length > _maxEvents) {
      _securityEvents.removeAt(0);
    }
  }

  /// 获取安全统计
  Map<String, dynamic> getSecurityStats() {
    final stats = <String, int>{};

    for (final event in _securityEvents) {
      final type = event['type'] as String;
      stats[type] = (stats[type] ?? 0) + 1;
    }

    return {
      'totalEvents': _securityEvents.length,
      'eventTypes': stats,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// 清理过期事件
  void cleanupExpiredEvents() {
    // 简单实现：如果事件过多，删除最旧的事件
    if (_securityEvents.length > _maxEvents) {
      _securityEvents.removeRange(0, _securityEvents.length - _maxEvents);
    }
  }

  /// 获取最近的安全事件
  List<Map<String, dynamic>> getRecentEvents({int limit = 10}) {
    final start =
        _securityEvents.length > limit ? _securityEvents.length - limit : 0;
    return _securityEvents.sublist(start);
  }
}
