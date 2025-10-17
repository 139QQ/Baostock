import 'package:equatable/equatable.dart';
import '../../domain/usecases/login_with_phone.dart';
import '../../domain/usecases/login_with_email.dart';
import '../../domain/usecases/send_verification_code.dart'
    hide VerificationCodeType;

/// 认证事件的抽象基类
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// 检查认证状态事件
class CheckAuthStatus extends AuthEvent {
  const CheckAuthStatus();

  @override
  String toString() => 'CheckAuthStatus()';
}

/// 手机号登录请求事件
class LoginWithPhoneRequested extends AuthEvent {
  final String phoneNumber;
  final String verificationCode;

  const LoginWithPhoneRequested({
    required this.phoneNumber,
    required this.verificationCode,
  });

  @override
  List<Object?> get props => [phoneNumber, verificationCode];

  @override
  String toString() {
    return 'LoginWithPhoneRequested(phoneNumber: $phoneNumber, verificationCode: ****)';
  }

  /// 转换为参数对象
  LoginWithPhoneParams toParams() {
    return LoginWithPhoneParams(
      phoneNumber: phoneNumber,
      verificationCode: verificationCode,
    );
  }
}

/// 邮箱登录请求事件
class LoginWithEmailRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginWithEmailRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];

  @override
  String toString() {
    return 'LoginWithEmailRequested(email: $email, password: ****)';
  }

  /// 转换为参数对象
  LoginWithEmailParams toParams() {
    return LoginWithEmailParams(
      email: email,
      password: password,
    );
  }
}

/// 发送手机验证码请求事件
class SendPhoneVerificationCodeRequested extends AuthEvent {
  final String phoneNumber;

  const SendPhoneVerificationCodeRequested({
    required this.phoneNumber,
  });

  @override
  List<Object?> get props => [phoneNumber];

  @override
  String toString() =>
      'SendPhoneVerificationCodeRequested(phoneNumber: $phoneNumber)';

  /// 转换为参数对象
  SendVerificationCodeParams toParams() {
    return SendVerificationCodeParams.phone(phoneNumber: phoneNumber);
  }
}

/// 发送邮箱验证码请求事件
class SendEmailVerificationCodeRequested extends AuthEvent {
  final String email;

  const SendEmailVerificationCodeRequested({
    required this.email,
  });

  @override
  List<Object?> get props => [email];

  @override
  String toString() => 'SendEmailVerificationCodeRequested(email: $email)';

  /// 转换为参数对象
  SendVerificationCodeParams toParams() {
    return SendVerificationCodeParams.email(email: email);
  }
}

/// 用户注册请求事件（手机号）
class RegisterWithPhoneRequested extends AuthEvent {
  final String phoneNumber;
  final String verificationCode;
  final String password;
  final String displayName;

  const RegisterWithPhoneRequested({
    required this.phoneNumber,
    required this.verificationCode,
    required this.password,
    required this.displayName,
  });

  @override
  List<Object?> get props => [
        phoneNumber,
        verificationCode,
        password,
        displayName,
      ];

  @override
  String toString() {
    return 'RegisterWithPhoneRequested(phoneNumber: $phoneNumber, displayName: $displayName)';
  }
}

/// 用户注册请求事件（邮箱）
class RegisterWithEmailRequested extends AuthEvent {
  final String email;
  final String password;
  final String displayName;

  const RegisterWithEmailRequested({
    required this.email,
    required this.password,
    required this.displayName,
  });

  @override
  List<Object?> get props => [email, password, displayName];

  @override
  String toString() {
    return 'RegisterWithEmailRequested(email: $email, displayName: $displayName)';
  }
}

/// 登出事件
class Logout extends AuthEvent {
  const Logout();

  @override
  String toString() => 'Logout()';
}

/// 刷新令牌事件
class RefreshTokenRequested extends AuthEvent {
  final String refreshToken;

  const RefreshTokenRequested({
    required this.refreshToken,
  });

  @override
  List<Object?> get props => [refreshToken];

  @override
  String toString() => 'RefreshTokenRequested(refreshToken: ****)';
}

/// 更新用户信息事件
class UpdateUserInfoRequested extends AuthEvent {
  final String userId;
  final String? displayName;
  final String? avatarUrl;

  const UpdateUserInfoRequested({
    required this.userId,
    this.displayName,
    this.avatarUrl,
  });

  @override
  List<Object?> get props => [userId, displayName, avatarUrl];

  @override
  String toString() {
    return 'UpdateUserInfoRequested(userId: $userId, displayName: $displayName)';
  }
}

/// 修改密码事件
class ChangePasswordRequested extends AuthEvent {
  final String userId;
  final String oldPassword;
  final String newPassword;

  const ChangePasswordRequested({
    required this.userId,
    required this.oldPassword,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [userId, oldPassword, newPassword];

  @override
  String toString() {
    return 'ChangePasswordRequested(userId: $userId)';
  }
}

/// 重置密码事件
class ResetPasswordRequested extends AuthEvent {
  final String email;
  final String resetCode;
  final String newPassword;

  const ResetPasswordRequested({
    required this.email,
    required this.resetCode,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [email, resetCode, newPassword];

  @override
  String toString() {
    return 'ResetPasswordRequested(email: $email)';
  }
}

/// 发送密码重置邮件事件
class SendPasswordResetEmailRequested extends AuthEvent {
  final String email;

  const SendPasswordResetEmailRequested({
    required this.email,
  });

  @override
  List<Object?> get props => [email];

  @override
  String toString() => 'SendPasswordResetEmailRequested(email: $email)';
}

/// 验证邮箱事件
class VerifyEmailRequested extends AuthEvent {
  final String verificationToken;

  const VerifyEmailRequested({
    required this.verificationToken,
  });

  @override
  List<Object?> get props => [verificationToken];

  @override
  String toString() => 'VerifyEmailRequested(verificationToken: ****)';
}

/// 验证手机号事件
class VerifyPhoneRequested extends AuthEvent {
  final String phoneNumber;
  final String verificationCode;

  const VerifyPhoneRequested({
    required this.phoneNumber,
    required this.verificationCode,
  });

  @override
  List<Object?> get props => [phoneNumber, verificationCode];

  @override
  String toString() {
    return 'VerifyPhoneRequested(phoneNumber: $phoneNumber)';
  }
}

/// 清除认证错误事件
class ClearAuthError extends AuthEvent {
  const ClearAuthError();

  @override
  String toString() => 'ClearAuthError()';
}

/// 认证状态重置事件
class AuthReset extends AuthEvent {
  const AuthReset();

  @override
  String toString() => 'AuthReset()';
}
