/// 认证结果枚举
///
/// 定义了认证过程中可能出现的各种结果状态
enum AuthResult {
  /// 认证成功
  success,

  /// 无效的凭据（用户名或密码错误、验证码错误等）
  invalidCredentials,

  /// 用户不存在
  userNotFound,

  /// 账户被锁定
  accountLocked,

  /// 网络错误
  networkError,

  /// 验证码已过期
  verificationCodeExpired,

  /// 验证码错误次数过多
  verificationCodeExceeded,

  /// 邮箱未验证
  emailNotVerified,

  /// 手机号未验证
  phoneNotVerified,

  /// 令牌已过期
  tokenExpired,

  /// 令牌无效
  tokenInvalid,

  /// 服务器内部错误
  serverError,

  /// 请求频率过高
  rateLimitExceeded,

  /// 未知错误
  unknownError,

  /// 用户取消操作
  cancelled,

  /// 输入格式错误
  invalidInput,

  /// 账户已存在（注册时冲突）
  accountExists,
}

/// 认证结果扩展方法
extension AuthResultExtension on AuthResult {
  /// 获取用户友好的错误消息
  String get message {
    switch (this) {
      case AuthResult.success:
        return '认证成功';
      case AuthResult.invalidCredentials:
        return '用户名或密码错误，请重试';
      case AuthResult.userNotFound:
        return '用户不存在，请检查输入信息';
      case AuthResult.accountLocked:
        return '账户已被锁定，请联系客服';
      case AuthResult.networkError:
        return '网络连接失败，请检查网络设置';
      case AuthResult.verificationCodeExpired:
        return '验证码已过期，请重新获取';
      case AuthResult.verificationCodeExceeded:
        return '验证码错误次数过多，请稍后重试';
      case AuthResult.emailNotVerified:
        return '邮箱尚未验证，请检查邮箱';
      case AuthResult.phoneNotVerified:
        return '手机号尚未验证，请完成验证';
      case AuthResult.tokenExpired:
        return '登录已过期，请重新登录';
      case AuthResult.tokenInvalid:
        return '登录状态无效，请重新登录';
      case AuthResult.serverError:
        return '服务器错误，请稍后重试';
      case AuthResult.rateLimitExceeded:
        return '操作过于频繁，请稍后重试';
      case AuthResult.cancelled:
        return '操作已取消';
      case AuthResult.invalidInput:
        return '输入格式不正确，请检查';
      case AuthResult.accountExists:
        return '账户已存在，请直接登录';
      case AuthResult.unknownError:
        return '发生未知错误，请重试';
    }
  }

  /// 获取技术错误码
  String get code {
    switch (this) {
      case AuthResult.success:
        return 'AUTH_SUCCESS';
      case AuthResult.invalidCredentials:
        return 'AUTH_INVALID_CREDENTIALS';
      case AuthResult.userNotFound:
        return 'AUTH_USER_NOT_FOUND';
      case AuthResult.accountLocked:
        return 'AUTH_ACCOUNT_LOCKED';
      case AuthResult.networkError:
        return 'AUTH_NETWORK_ERROR';
      case AuthResult.verificationCodeExpired:
        return 'AUTH_VERIFICATION_CODE_EXPIRED';
      case AuthResult.verificationCodeExceeded:
        return 'AUTH_VERIFICATION_CODE_EXCEEDED';
      case AuthResult.emailNotVerified:
        return 'AUTH_EMAIL_NOT_VERIFIED';
      case AuthResult.phoneNotVerified:
        return 'AUTH_PHONE_NOT_VERIFIED';
      case AuthResult.tokenExpired:
        return 'AUTH_TOKEN_EXPIRED';
      case AuthResult.tokenInvalid:
        return 'AUTH_TOKEN_INVALID';
      case AuthResult.serverError:
        return 'AUTH_SERVER_ERROR';
      case AuthResult.rateLimitExceeded:
        return 'AUTH_RATE_LIMIT_EXCEEDED';
      case AuthResult.cancelled:
        return 'AUTH_CANCELLED';
      case AuthResult.invalidInput:
        return 'AUTH_INVALID_INPUT';
      case AuthResult.accountExists:
        return 'AUTH_ACCOUNT_EXISTS';
      case AuthResult.unknownError:
        return 'AUTH_UNKNOWN_ERROR';
    }
  }

  /// 是否为成功状态
  bool get isSuccess => this == AuthResult.success;

  /// 是否为网络相关错误
  bool get isNetworkError =>
      this == AuthResult.networkError || this == AuthResult.serverError;

  /// 是否为用户输入错误
  bool get isInputError =>
      this == AuthResult.invalidCredentials ||
      this == AuthResult.invalidInput ||
      this == AuthResult.userNotFound;

  /// 是否为账户状态问题
  bool get isAccountIssue =>
      this == AuthResult.accountLocked ||
      this == AuthResult.emailNotVerified ||
      this == AuthResult.phoneNotVerified ||
      this == AuthResult.accountExists;

  /// 是否为令牌问题
  bool get isTokenIssue =>
      this == AuthResult.tokenExpired || this == AuthResult.tokenInvalid;

  /// 是否为验证码问题
  bool get isVerificationIssue =>
      this == AuthResult.verificationCodeExpired ||
      this == AuthResult.verificationCodeExceeded;

  /// 是否需要重新输入凭据
  bool get requiresReauth => isInputError || isAccountIssue || isTokenIssue;

  /// 是否可以重试
  bool get isRetryable =>
      isNetworkError ||
      this == AuthResult.rateLimitExceeded ||
      this == AuthResult.serverError ||
      this == AuthResult.unknownError;
}

/// 认证错误类
class AuthException implements Exception {
  final AuthResult result;
  final String? details;
  final String? stackTrace;

  AuthException(
    this.result, {
    this.details,
    this.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer('AuthException: ${result.message}');
    if (details != null) {
      buffer.write(' - $details');
    }
    return buffer.toString();
  }

  /// 创建网络错误异常
  factory AuthException.networkError(String? details) {
    return AuthException(
      AuthResult.networkError,
      details: details,
    );
  }

  /// 创建服务器错误异常
  factory AuthException.serverError(String? details) {
    return AuthException(
      AuthResult.serverError,
      details: details,
    );
  }

  /// 创建无效凭据异常
  factory AuthException.invalidCredentials(String? details) {
    return AuthException(
      AuthResult.invalidCredentials,
      details: details,
    );
  }

  /// 创建用户不存在异常
  factory AuthException.userNotFound(String? details) {
    return AuthException(
      AuthResult.userNotFound,
      details: details,
    );
  }
}
