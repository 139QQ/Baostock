/// 基础异常类
abstract class AppException implements Exception {
  final String message;
  final dynamic details;

  const AppException(this.message, {this.details});

  @override
  String toString() => 'AppException: $message';
}

/// 缓存异常
class CacheException extends AppException {
  const CacheException(String message, {dynamic details})
      : super(message, details: details);
}

/// 网络异常
class NetworkException extends AppException {
  const NetworkException(String message, {dynamic details})
      : super(message, details: details);
}

/// 认证异常
class AuthException extends AppException {
  const AuthException(String message, {dynamic details})
      : super(message, details: details);
}

/// 数据解析异常
class ParseException extends AppException {
  const ParseException(String message, {dynamic details})
      : super(message, details: details);
}

/// 服务器异常
class ServerException extends AppException {
  final int? statusCode;

  const ServerException(String message, {this.statusCode, dynamic details})
      : super(message, details: details);
}

/// 验证异常
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException(String message, {this.fieldErrors, dynamic details})
      : super(message, details: details);
}

/// 权限异常
class PermissionException extends AppException {
  const PermissionException(String message, {dynamic details})
      : super(message, details: details);
}

/// 业务逻辑异常
class BusinessException extends AppException {
  const BusinessException(String message, {dynamic details})
      : super(message, details: details);
}

/// 未找到异常
class NotFoundException extends AppException {
  const NotFoundException(String message, {dynamic details})
      : super(message, details: details);
}

/// 超时异常
class TimeoutException extends AppException {
  final Duration? timeout;

  const TimeoutException(String message, {this.timeout, dynamic details})
      : super(message, details: details);
}
