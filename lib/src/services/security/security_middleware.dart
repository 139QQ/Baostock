import 'package:dio/dio.dart';

import '../../core/utils/logger.dart';
import 'security_utils.dart';

/// 安全验证结果
class SecurityValidationResult {
  final bool isValid;
  final String? errorMessage;
  final Map<String, dynamic>? details;

  const SecurityValidationResult._({
    required this.isValid,
    this.errorMessage,
    this.details,
  });

  factory SecurityValidationResult.success({Map<String, dynamic>? details}) {
    return SecurityValidationResult._(
      isValid: true,
      details: details,
    );
  }

  factory SecurityValidationResult.failure(String errorMessage,
      {Map<String, dynamic>? details}) {
    return SecurityValidationResult._(
      isValid: false,
      errorMessage: errorMessage,
      details: details,
    );
  }

  bool get isFailure => !isValid;

  @override
  String toString() {
    if (isValid) {
      return 'SecurityValidationResult.success';
    } else {
      return 'SecurityValidationResult.failure: $errorMessage';
    }
  }
}

/// 安全中间件 - 简化版本
///
/// 提供请求签名验证、输入验证、频率限制等安全功能
class SecurityMiddleware {
  static const String _xRequestIdHeader = 'X-Request-ID';
  static const String _xTimestampHeader = 'X-Timestamp';
  static const String _xSignatureHeader = 'X-Signature';

  final Map<String, int> _requestCounts = {};

  // 频率限制配置
  static const int _maxRequestsPerMinute = 60;
  static const int _maxRequestsPerHour = 1000;

  /// 创建拦截器
  static Interceptor createInterceptor({
    bool enableSignatureVerification = true,
    bool enableRateLimiting = true,
    bool enableInputValidation = true,
  }) {
    return SecurityInterceptor(
      enableSignatureVerification: enableSignatureVerification,
      enableRateLimiting: enableRateLimiting,
      enableInputValidation: enableInputValidation,
    );
  }

  /// 生成安全请求头
  static Map<String, String> generateSecurityHeaders({
    required String method,
    required String path,
    Map<String, dynamic>? params,
  }) {
    final timestamp = SecurityUtils.generateTimestamp();
    final requestId = SecurityUtils.generateRequestId();

    Map<String, String> headers = {
      _xRequestIdHeader: requestId,
      _xTimestampHeader: timestamp,
      'Content-Type': 'application/json',
      'User-Agent': 'UnifiedApiService/1.0.0',
    };

    // 添加签名
    if (params != null) {
      final signature = SecurityUtils.generateSignature(
        method: method,
        path: path,
        params: params,
        timestamp: timestamp,
        requestId: requestId,
      );
      headers[_xSignatureHeader] = signature;
    }

    return headers;
  }

  /// 验证请求签名
  static bool verifyRequestSignature({
    required Map<String, String> headers,
    required String method,
    required String path,
    Map<String, dynamic>? params,
  }) {
    try {
      final requestId = headers[_xRequestIdHeader];
      final timestamp = headers[_xTimestampHeader];
      final receivedSignature = headers[_xSignatureHeader];

      if (requestId == null || timestamp == null || receivedSignature == null) {
        return false;
      }

      return SecurityUtils.verifySignature(
        method: method,
        path: path,
        params: params ?? {},
        timestamp: timestamp,
        requestId: requestId,
        receivedSignature: receivedSignature,
      );
    } catch (e) {
      AppLogger.error('签名验证失败', e);
      return false;
    }
  }

  /// 验证路径
  static SecurityValidationResult isValidPath(String path) {
    // 检查路径是否包含危险字符
    if (SecurityUtils.containsDangerousCharacters(path)) {
      return SecurityValidationResult.failure('路径包含危险字符');
    }

    // 检查路径长度
    if (path.length > 500) {
      return SecurityValidationResult.failure('路径长度超过限制');
    }

    return SecurityValidationResult.success();
  }

  /// 验证输入数据
  static SecurityValidationResult validateInput(dynamic input) {
    if (input == null) {
      return SecurityValidationResult.success();
    }

    String inputStr;
    if (input is String) {
      inputStr = input;
    } else {
      inputStr = input.toString();
    }

    // 检查SQL注入
    if (SecurityUtils.containsSqlInjection(inputStr)) {
      return SecurityValidationResult.failure('输入包含潜在的SQL注入');
    }

    // 检查XSS
    if (SecurityUtils.containsXss(inputStr)) {
      return SecurityValidationResult.failure('输入包含潜在的XSS攻击');
    }

    // 检查输入长度
    if (inputStr.length > 10000) {
      return SecurityValidationResult.failure('输入长度超过限制');
    }

    return SecurityValidationResult.success();
  }

  /// 验证用户ID
  static SecurityValidationResult isValidUserId(String? userId) {
    if (userId == null || userId.isEmpty) {
      return SecurityValidationResult.failure('用户ID不能为空');
    }

    // 简单验证：只允许字母数字和下划线
    final validPattern = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!validPattern.hasMatch(userId)) {
      return SecurityValidationResult.failure('用户ID格式无效');
    }

    if (userId.length > 50) {
      return SecurityValidationResult.failure('用户ID长度超过限制');
    }

    return SecurityValidationResult.success();
  }

  /// 验证金额
  static SecurityValidationResult isValidAmount(dynamic amount) {
    if (amount == null) {
      return SecurityValidationResult.failure('金额不能为空');
    }

    double value;
    try {
      if (amount is String) {
        value = double.parse(amount);
      } else if (amount is num) {
        value = amount.toDouble();
      } else {
        return SecurityValidationResult.failure('金额格式无效');
      }
    } catch (e) {
      return SecurityValidationResult.failure('金额格式无效');
    }

    if (value < 0) {
      return SecurityValidationResult.failure('金额不能为负数');
    }

    if (value > 999999999.99) {
      return SecurityValidationResult.failure('金额超过限制');
    }

    return SecurityValidationResult.success();
  }

  /// 验证分页参数
  static SecurityValidationResult isValidPagination(int? page, int? size) {
    if (page != null && page < 0) {
      return SecurityValidationResult.failure('页码不能为负数');
    }

    if (size != null && size < 0) {
      return SecurityValidationResult.failure('页面大小不能为负数');
    }

    if (size != null && size > 1000) {
      return SecurityValidationResult.failure('页面大小超过限制');
    }

    return SecurityValidationResult.success();
  }
}

/// 安全拦截器
class SecurityInterceptor extends Interceptor {
  final bool enableSignatureVerification;
  final bool enableRateLimiting;
  final bool enableInputValidation;

  final Map<String, List<DateTime>> _requestHistory = {};

  SecurityInterceptor({
    required this.enableSignatureVerification,
    required this.enableRateLimiting,
    required this.enableInputValidation,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    try {
      // 输入验证
      if (enableInputValidation && options.data != null) {
        final validation = SecurityMiddleware.validateInput(options.data);
        if (validation.isFailure) {
          handler.reject(
            DioException(
              requestOptions: options,
              error: validation.errorMessage,
              type: DioExceptionType.unknown,
            ),
          );
          return;
        }
      }

      // 签名验证
      if (enableSignatureVerification) {
        if (!SecurityMiddleware.verifyRequestSignature(
          headers: options.headers
              .map((key, value) => MapEntry(key, value.toString())),
          method: options.method,
          path: options.path,
          params: options.queryParameters,
        )) {
          handler.reject(
            DioException(
              requestOptions: options,
              error: '签名验证失败',
              type: DioExceptionType.unknown,
            ),
          );
          return;
        }
      }

      // 频率限制
      if (enableRateLimiting && _isRateLimited()) {
        handler.reject(
          DioException(
            requestOptions: options,
            error: '请求频率过高',
            type: DioExceptionType.unknown,
          ),
        );
        return;
      }

      AppLogger.debug('安全验证通过: ${options.method} ${options.path}');
      handler.next(options);
    } catch (e) {
      AppLogger.error('安全拦截器错误', e);
      handler.next(options);
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 记录安全相关的错误
    if (err.type == DioExceptionType.unknown) {
      AppLogger.warn('安全错误: ${err.error}');
    }

    handler.next(err);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // 可以在这里过滤敏感数据
    handler.next(response);
  }

  /// 检查是否超过频率限制
  bool _isRateLimited() {
    const clientIp = 'default'; // 简化实现
    final now = DateTime.now();
    final oneMinuteAgo = now.subtract(const Duration(minutes: 1));
    final oneHourAgo = now.subtract(const Duration(hours: 1));

    // 获取历史记录
    final history = _requestHistory[clientIp] ?? [];

    // 清理过期记录
    history.removeWhere((time) => time.isBefore(oneHourAgo));

    // 检查每分钟限制
    final minuteCount =
        history.where((time) => time.isAfter(oneMinuteAgo)).length;
    if (minuteCount >= 60) {
      return true;
    }

    // 检查每小时限制
    if (history.length >= 1000) {
      return true;
    }

    // 记录当前请求
    history.add(now);
    _requestHistory[clientIp] = history;

    return false;
  }

  /// 过滤敏感数据
  static Map<String, dynamic> filterSensitiveData(Map<String, dynamic> data) {
    final filtered = Map<String, dynamic>.from(data);

    // 过滤常见的敏感字段
    final sensitiveFields = [
      'password',
      'token',
      'secret',
      'key',
      'auth',
      'session',
      'cookie',
      'credential',
      'private',
    ];

    for (final field in sensitiveFields) {
      if (filtered.containsKey(field)) {
        filtered[field] = '***FILTERED***';
      }
    }

    return filtered;
  }

  /// 清理敏感日志
  static String filterSensitiveLog(String log) {
    return log.replaceAll(
        RegExp(r'(password|token|secret|key|auth)[=:\s]+[^\s&]+',
            caseSensitive: false),
        r'$1=***FILTERED***');
  }
}
