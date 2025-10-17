import 'package:dartz/dartz.dart';
import '../entities/auth_result.dart';
import '../repositories/auth_repository.dart';

/// 验证码类型
enum VerificationCodeType {
  /// 手机验证码
  phone,

  /// 邮箱验证码
  email,
}

/// 发送验证码用例
///
/// 处理手机号和邮箱验证码发送的业务逻辑
class SendVerificationCode {
  final AuthRepository _repository;

  SendVerificationCode(this._repository);

  /// 发送手机验证码
  ///
  /// [phoneNumber] 手机号码，必须是有效的中国手机号
  ///
  /// 返回发送成功或 [AuthException] 发送失败
  Future<Either<AuthException, void>> sendPhoneCode({
    required String phoneNumber,
  }) async {
    // 验证手机号格式
    final validationError = _validatePhoneNumber(phoneNumber);
    if (validationError != null) {
      return Left(validationError);
    }

    try {
      // 调用仓库发送验证码
      return await _repository.sendPhoneVerificationCode(
        phoneNumber: phoneNumber,
      );
    } catch (e) {
      return Left(AuthException(
        AuthResult.unknownError,
        details: '发送验证码时发生未知错误: $e',
      ));
    }
  }

  /// 发送邮箱验证码
  ///
  /// [email] 邮箱地址，必须是有效的邮箱格式
  ///
  /// 返回发送成功或 [AuthException] 发送失败
  Future<Either<AuthException, void>> sendEmailCode({
    required String email,
  }) async {
    // 验证邮箱格式
    final validationError = _validateEmail(email);
    if (validationError != null) {
      return Left(validationError);
    }

    try {
      // 调用仓库发送验证码
      return await _repository.sendEmailVerificationCode(
        email: email,
      );
    } catch (e) {
      return Left(AuthException(
        AuthResult.unknownError,
        details: '发送验证码时发生未知错误: $e',
      ));
    }
  }

  /// 统一发送验证码方法
  ///
  /// [recipient] 接收者（手机号或邮箱）
  /// [type] 验证码类型
  ///
  /// 返回发送成功或 [AuthException] 发送失败
  Future<Either<AuthException, void>> call({
    required String recipient,
    required VerificationCodeType type,
  }) async {
    switch (type) {
      case VerificationCodeType.phone:
        return await sendPhoneCode(phoneNumber: recipient);
      case VerificationCodeType.email:
        return await sendEmailCode(email: recipient);
    }
  }

  /// 验证手机号格式
  AuthException? _validatePhoneNumber(String phoneNumber) {
    if (!_isValidPhoneNumber(phoneNumber)) {
      return AuthException(
        AuthResult.invalidInput,
        details: '手机号格式不正确',
      );
    }
    return null;
  }

  /// 验证邮箱格式
  AuthException? _validateEmail(String email) {
    if (!_isValidEmail(email)) {
      return AuthException(
        AuthResult.invalidInput,
        details: '邮箱格式不正确',
      );
    }
    return null;
  }

  /// 验证手机号格式（中国大陆手机号）
  bool _isValidPhoneNumber(String phoneNumber) {
    // 移除所有非数字字符
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // 检查是否为11位数字且以1开头
    return RegExp(r'^1[3-9]\d{9}$').hasMatch(cleanNumber);
  }

  /// 验证邮箱格式
  bool _isValidEmail(String email) {
    // 基本邮箱格式验证
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(email)) {
      return false;
    }

    // 邮箱长度检查
    if (email.length > 254) {
      return false;
    }

    // 本地部分长度检查（@符号前的部分）
    final atIndex = email.lastIndexOf('@');
    if (atIndex > 64) {
      return false;
    }

    // 域名部分检查
    final domain = email.substring(atIndex + 1);
    if (domain.length > 253) {
      return false;
    }

    return true;
  }
}

/// 发送验证码参数
class SendVerificationCodeParams {
  final String recipient;
  final VerificationCodeType type;

  SendVerificationCodeParams({
    required this.recipient,
    required this.type,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SendVerificationCodeParams &&
        other.recipient == recipient &&
        other.type == type;
  }

  @override
  int get hashCode => recipient.hashCode ^ type.hashCode;

  @override
  String toString() {
    return 'SendVerificationCodeParams(recipient: $recipient, type: $type)';
  }

  /// 创建手机验证码参数
  factory SendVerificationCodeParams.phone({
    required String phoneNumber,
  }) {
    return SendVerificationCodeParams(
      recipient: phoneNumber,
      type: VerificationCodeType.phone,
    );
  }

  /// 创建邮箱验证码参数
  factory SendVerificationCodeParams.email({
    required String email,
  }) {
    return SendVerificationCodeParams(
      recipient: email,
      type: VerificationCodeType.email,
    );
  }

  /// 创建测试参数
  static SendVerificationCodeParams test({
    String recipient = '13812345678',
    VerificationCodeType type = VerificationCodeType.phone,
  }) {
    return SendVerificationCodeParams(
      recipient: recipient,
      type: type,
    );
  }
}

/// 验证码发送结果
class VerificationCodeResult {
  final bool success;
  final String? messageId;
  final String? error;
  final int? cooldownSeconds;

  VerificationCodeResult({
    required this.success,
    this.messageId,
    this.error,
    this.cooldownSeconds,
  });

  factory VerificationCodeResult.success({
    String? messageId,
    int? cooldownSeconds,
  }) {
    return VerificationCodeResult(
      success: true,
      messageId: messageId,
      cooldownSeconds: cooldownSeconds,
    );
  }

  factory VerificationCodeResult.failure({
    required String error,
    int? cooldownSeconds,
  }) {
    return VerificationCodeResult(
      success: false,
      error: error,
      cooldownSeconds: cooldownSeconds,
    );
  }

  @override
  String toString() {
    return 'VerificationCodeResult(success: $success, error: $error)';
  }
}
