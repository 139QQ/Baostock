import 'package:dartz/dartz.dart';
import '../entities/auth_result.dart';
import '../entities/user_session.dart';
import '../repositories/auth_repository.dart';

/// 手机号登录用例
///
/// 处理手机号验证码登录的业务逻辑
class LoginWithPhone {
  final AuthRepository _repository;

  LoginWithPhone(this._repository);

  /// 执行手机号登录
  ///
  /// [phoneNumber] 手机号码，必须是有效的中国手机号
  /// [verificationCode] 验证码，通常是6位数字
  ///
  /// 返回 [UserSession] 登录成功或 [AuthException] 登录失败
  Future<Either<AuthException, UserSession>> call({
    required String phoneNumber,
    required String verificationCode,
  }) async {
    // 输入验证
    final validationError = _validateInputs(phoneNumber, verificationCode);
    if (validationError != null) {
      return Left(validationError);
    }

    try {
      // 调用仓库进行登录
      final result = await _repository.loginWithPhone(
        phoneNumber: phoneNumber,
        verificationCode: verificationCode,
      );

      return result;
    } catch (e) {
      // 处理未预期的异常
      return Left(AuthException(
        AuthResult.unknownError,
        details: '登录过程中发生未知错误: $e',
      ));
    }
  }

  /// 验证输入参数
  AuthException? _validateInputs(String phoneNumber, String verificationCode) {
    // 验证手机号格式
    if (!_isValidPhoneNumber(phoneNumber)) {
      return AuthException(
        AuthResult.invalidInput,
        details: '手机号格式不正确',
      );
    }

    // 验证验证码格式
    if (!_isValidVerificationCode(verificationCode)) {
      return AuthException(
        AuthResult.invalidInput,
        details: '验证码格式不正确',
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

  /// 验证验证码格式
  bool _isValidVerificationCode(String verificationCode) {
    // 移除所有非数字字符
    final cleanCode = verificationCode.replaceAll(RegExp(r'[^\d]'), '');

    // 检查是否为4-6位数字
    return RegExp(r'^\d{4,6}$').hasMatch(cleanCode);
  }
}

/// 手机号登录参数
class LoginWithPhoneParams {
  final String phoneNumber;
  final String verificationCode;

  LoginWithPhoneParams({
    required this.phoneNumber,
    required this.verificationCode,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LoginWithPhoneParams &&
        other.phoneNumber == phoneNumber &&
        other.verificationCode == verificationCode;
  }

  @override
  int get hashCode => phoneNumber.hashCode ^ verificationCode.hashCode;

  @override
  String toString() {
    return 'LoginWithPhoneParams(phoneNumber: $phoneNumber, verificationCode: ****)';
  }

  /// 创建测试参数
  static LoginWithPhoneParams test({
    String phoneNumber = '13812345678',
    String verificationCode = '123456',
  }) {
    return LoginWithPhoneParams(
      phoneNumber: phoneNumber,
      verificationCode: verificationCode,
    );
  }
}
