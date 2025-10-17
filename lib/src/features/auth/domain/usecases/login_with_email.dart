import 'package:dartz/dartz.dart';
import '../entities/auth_result.dart';
import '../entities/user_session.dart';
import '../repositories/auth_repository.dart';

/// 邮箱登录用例
///
/// 处理邮箱密码登录的业务逻辑
class LoginWithEmail {
  final AuthRepository _repository;

  LoginWithEmail(this._repository);

  /// 执行邮箱登录
  ///
  /// [email] 邮箱地址，必须是有效的邮箱格式
  /// [password] 密码，最少6位字符
  ///
  /// 返回 [UserSession] 登录成功或 [AuthException] 登录失败
  Future<Either<AuthException, UserSession>> call({
    required String email,
    required String password,
  }) async {
    // 输入验证
    final validationError = _validateInputs(email, password);
    if (validationError != null) {
      return Left(validationError);
    }

    try {
      // 调用仓库进行登录
      final result = await _repository.loginWithEmail(
        email: email,
        password: password,
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
  AuthException? _validateInputs(String email, String password) {
    // 验证邮箱格式
    if (!_isValidEmail(email)) {
      return AuthException(
        AuthResult.invalidInput,
        details: '邮箱格式不正确',
      );
    }

    // 验证密码强度
    if (!_isValidPassword(password)) {
      return AuthException(
        AuthResult.invalidInput,
        details: '密码格式不正确，至少需要6个字符',
      );
    }

    return null;
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

  /// 验证密码强度
  bool _isValidPassword(String password) {
    // 基本长度检查
    if (password.length < 6 || password.length > 128) {
      return false;
    }

    // 密码不能只包含空格
    if (password.trim().isEmpty) {
      return false;
    }

    // 密码强度评分（可选实现）
    int strengthScore = 0;

    // 包含小写字母
    if (password.contains(RegExp(r'[a-z]'))) {
      strengthScore++;
    }

    // 包含大写字母
    if (password.contains(RegExp(r'[A-Z]'))) {
      strengthScore++;
    }

    // 包含数字
    if (password.contains(RegExp(r'[0-9]'))) {
      strengthScore++;
    }

    // 包含特殊字符
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      strengthScore++;
    }

    // 长度加分
    if (password.length >= 8) {
      strengthScore++;
    }

    return strengthScore >= 2; // 至少满足2个条件
  }

  /// 检查密码强度等级
  PasswordStrength checkPasswordStrength(String password) {
    if (!_isValidPassword(password)) {
      return PasswordStrength.weak;
    }

    int score = 0;

    // 长度评分
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;

    // 字符类型评分
    if (password.contains(RegExp(r'[a-z]'))) score++; // 小写字母
    if (password.contains(RegExp(r'[A-Z]'))) score++; // 大写字母
    if (password.contains(RegExp(r'[0-9]'))) score++; // 数字
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++; // 特殊字符

    if (score >= 5) return PasswordStrength.veryStrong;
    if (score >= 4) return PasswordStrength.strong;
    if (score >= 3) return PasswordStrength.medium;
    if (score >= 2) return PasswordStrength.fair;
    return PasswordStrength.weak;
  }
}

/// 密码强度枚举
enum PasswordStrength {
  /// 弱密码
  weak,

  /// 一般密码
  fair,

  /// 中等密码
  medium,

  /// 强密码
  strong,

  /// 非常强密码
  veryStrong,
}

/// 密码强度扩展方法
extension PasswordStrengthExtension on PasswordStrength {
  /// 获取强度描述
  String get description {
    switch (this) {
      case PasswordStrength.weak:
        return '弱';
      case PasswordStrength.fair:
        return '一般';
      case PasswordStrength.medium:
        return '中等';
      case PasswordStrength.strong:
        return '强';
      case PasswordStrength.veryStrong:
        return '非常强';
    }
  }

  /// 获取强度颜色
  String get color {
    switch (this) {
      case PasswordStrength.weak:
        return '#FF4444'; // 红色
      case PasswordStrength.fair:
        return '#FF8800'; // 橙色
      case PasswordStrength.medium:
        return '#FFBB33'; // 黄色
      case PasswordStrength.strong:
        return '#00C851'; // 绿色
      case PasswordStrength.veryStrong:
        return '#00897B'; // 深绿色
    }
  }

  /// 是否为安全密码
  bool get isSecure =>
      this == PasswordStrength.strong || this == PasswordStrength.veryStrong;
}

/// 邮箱登录参数
class LoginWithEmailParams {
  final String email;
  final String password;

  LoginWithEmailParams({
    required this.email,
    required this.password,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LoginWithEmailParams &&
        other.email == email &&
        other.password == password;
  }

  @override
  int get hashCode => email.hashCode ^ password.hashCode;

  @override
  String toString() {
    return 'LoginWithEmailParams(email: $email, password: ****)';
  }

  /// 创建测试参数
  static LoginWithEmailParams test({
    String email = 'test@example.com',
    String password = 'password123',
  }) {
    return LoginWithEmailParams(
      email: email,
      password: password,
    );
  }
}
