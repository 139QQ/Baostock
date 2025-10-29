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
  const CacheException(super.message, {super.details});
}

/// 网络异常
class NetworkException extends AppException {
  const NetworkException(super.message, {super.details});
}

/// 认证异常
class AuthException extends AppException {
  const AuthException(super.message, {super.details});
}

/// 数据解析异常
class ParseException extends AppException {
  const ParseException(super.message, {super.details});
}

/// 服务器异常
class ServerException extends AppException {
  final int? statusCode;

  const ServerException(super.message, {this.statusCode, super.details});
}

/// 验证异常
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException(super.message, {this.fieldErrors, super.details});
}

/// 权限异常
class PermissionException extends AppException {
  const PermissionException(super.message, {super.details});
}

/// 业务逻辑异常
class BusinessException extends AppException {
  const BusinessException(super.message, {super.details});
}

/// 未找到异常
class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.details});
}

/// 超时异常
class TimeoutException extends AppException {
  final Duration? timeout;

  const TimeoutException(super.message, {this.timeout, super.details});
}
