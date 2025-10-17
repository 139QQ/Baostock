import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/user_session.dart';
import '../../domain/entities/auth_result.dart';

/// 认证状态抽象基类
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// 初始认证状态
class AuthInitial extends AuthState {
  const AuthInitial();

  @override
  String toString() => 'AuthInitial()';
}

/// 认证加载中状态
class AuthLoading extends AuthState {
  final String? message;

  const AuthLoading({this.message});

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'AuthLoading(message: $message)';
}

/// 认证成功状态
class AuthAuthenticated extends AuthState {
  final User user;
  final UserSession session;

  const AuthAuthenticated({
    required this.user,
    required this.session,
  });

  @override
  List<Object?> get props => [user, session];

  @override
  String toString() => 'AuthAuthenticated(user: ${user.displayName})';

  /// 创建测试状态
  static AuthAuthenticated test({
    User? user,
    UserSession? session,
  }) {
    return AuthAuthenticated(
      user: user ?? User.testUser(),
      session: session ?? UserSession.testSession(),
    );
  }
}

/// 未认证状态
class AuthUnauthenticated extends AuthState {
  final String? message;

  const AuthUnauthenticated({this.message});

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'AuthUnauthenticated(message: $message)';
}

/// 认证失败状态
class AuthFailure extends AuthState {
  final AuthResult error;
  final String? details;
  final DateTime timestamp;

  AuthFailure({
    required this.error,
    this.details,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  List<Object?> get props => [error, details, timestamp];

  @override
  String toString() => 'AuthFailure(error: ${error.message})';

  /// 创建网络错误状态
  factory AuthFailure.network({String? details}) {
    return AuthFailure(
      error: AuthResult.networkError,
      details: details,
    );
  }

  /// 创建服务器错误状态
  factory AuthFailure.server({String? details}) {
    return AuthFailure(
      error: AuthResult.serverError,
      details: details,
    );
  }

  /// 创建无效凭据错误状态
  factory AuthFailure.invalidCredentials({String? details}) {
    return AuthFailure(
      error: AuthResult.invalidCredentials,
      details: details,
    );
  }

  /// 创建用户不存在错误状态
  factory AuthFailure.userNotFound({String? details}) {
    return AuthFailure(
      error: AuthResult.userNotFound,
      details: details,
    );
  }

  /// 创建账户锁定错误状态
  factory AuthFailure.accountLocked({String? details}) {
    return AuthFailure(
      error: AuthResult.accountLocked,
      details: details,
    );
  }

  /// 创建验证码错误状态
  factory AuthFailure.verificationCodeError({String? details}) {
    return AuthFailure(
      error: AuthResult.verificationCodeExpired,
      details: details,
    );
  }

  /// 创建未知错误状态
  factory AuthFailure.unknown({String? details}) {
    return AuthFailure(
      error: AuthResult.unknownError,
      details: details,
    );
  }

  /// 检查是否为网络相关错误
  bool get isNetworkError => error.isNetworkError;

  /// 检查是否为用户输入错误
  bool get isInputError => error.isInputError;

  /// 检查是否为账户状态问题
  bool get isAccountIssue => error.isAccountIssue;

  /// 检查是否为令牌问题
  bool get isTokenIssue => error.isTokenIssue;

  /// 检查是否为验证码问题
  bool get isVerificationIssue => error.isVerificationIssue;

  /// 是否需要重新输入凭据
  bool get requiresReauth => error.requiresReauth;

  /// 是否可以重试
  bool get isRetryable => error.isRetryable;

  /// 获取用户友好的错误消息
  String get userMessage => error.message;

  /// 获取技术错误码
  String get errorCode => error.code;
}

/// 验证码发送状态
class VerificationCodeSent extends AuthState {
  final String recipient;
  final VerificationCodeType type;
  final String? messageId;
  final int? cooldownSeconds;

  const VerificationCodeSent({
    required this.recipient,
    required this.type,
    this.messageId,
    this.cooldownSeconds,
  });

  @override
  List<Object?> get props => [recipient, type, messageId, cooldownSeconds];

  @override
  String toString() {
    return 'VerificationCodeSent(recipient: $recipient, type: $type)';
  }

  /// 获取发送成功的提示消息
  String get successMessage {
    switch (type) {
      case VerificationCodeType.phone:
        return '验证码已发送至手机 $recipient';
      case VerificationCodeType.email:
        return '验证码已发送至邮箱 $recipient';
    }
  }
}

/// 密码强度枚举
enum PasswordStrength {
  weak('弱', '#FF6B6B', false),
  medium('中等', '#FFB347', false),
  strong('强', '#4ECDC4', true),
  veryStrong('很强', '#51CF66', true);

  const PasswordStrength(this.description, this.color, this.isSecure);

  final String description;
  final String color;
  final bool isSecure;
}

/// 密码强度检查状态
class PasswordStrengthChecked extends AuthState {
  final PasswordStrength strength;
  final String password;

  const PasswordStrengthChecked({
    required this.strength,
    required this.password,
  });

  @override
  List<Object?> get props => [strength, password];

  @override
  String toString() {
    return 'PasswordStrengthChecked(strength: $strength)';
  }

  /// 获取强度描述
  String get strengthDescription => strength.description;

  /// 获取强度颜色
  String get strengthColor => strength.color;

  /// 是否为安全密码
  bool get isSecure => strength.isSecure;
}

/// 用户信息更新状态
class UserInfoUpdated extends AuthState {
  final User updatedUser;

  const UserInfoUpdated({
    required this.updatedUser,
  });

  @override
  List<Object?> get props => [updatedUser];

  @override
  String toString() {
    return 'UserInfoUpdated(user: ${updatedUser.displayName})';
  }
}

/// 验证码类型枚举
enum VerificationCodeType {
  phone,
  email,
}
