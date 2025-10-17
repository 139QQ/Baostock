import 'package:dartz/dartz.dart';
import '../entities/user.dart';
import '../entities/user_session.dart';
import '../entities/auth_result.dart';

/// 认证仓库接口
///
/// 定义了用户认证相关的所有业务操作
abstract class AuthRepository {
  /// 检查当前用户认证状态
  ///
  /// 返回 [UserSession] 如果用户已登录，否则返回 null
  Future<UserSession?> getCurrentSession();

  /// 使用手机号和验证码登录
  ///
  /// [phoneNumber] 手机号码
  /// [verificationCode] 验证码
  ///
  /// 返回 [UserSession] 登录成功或 [AuthException] 登录失败
  Future<Either<AuthException, UserSession>> loginWithPhone({
    required String phoneNumber,
    required String verificationCode,
  });

  /// 使用邮箱和密码登录
  ///
  /// [email] 邮箱地址
  /// [password] 密码
  ///
  /// 返回 [UserSession] 登录成功或 [AuthException] 登录失败
  Future<Either<AuthException, UserSession>> loginWithEmail({
    required String email,
    required String password,
  });

  /// 发送手机验证码
  ///
  /// [phoneNumber] 手机号码
  ///
  /// 返回发送成功或 [AuthException] 发送失败
  Future<Either<AuthException, void>> sendPhoneVerificationCode({
    required String phoneNumber,
  });

  /// 发送邮箱验证码
  ///
  /// [email] 邮箱地址
  ///
  /// 返回发送成功或 [AuthException] 发送失败
  Future<Either<AuthException, void>> sendEmailVerificationCode({
    required String email,
  });

  /// 用户注册（手机号）
  ///
  /// [phoneNumber] 手机号码
  /// [verificationCode] 验证码
  /// [password] 密码
  /// [displayName] 显示名称
  ///
  /// 返回 [User] 注册成功或 [AuthException] 注册失败
  Future<Either<AuthException, User>> registerWithPhone({
    required String phoneNumber,
    required String verificationCode,
    required String password,
    required String displayName,
  });

  /// 用户注册（邮箱）
  ///
  /// [email] 邮箱地址
  /// [password] 密码
  /// [displayName] 显示名称
  ///
  /// 返回 [User] 注册成功或 [AuthException] 注册失败
  Future<Either<AuthException, User>> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  });

  /// 刷新访问令牌
  ///
  /// [refreshToken] 刷新令牌
  ///
  /// 返回新的 [UserSession] 或 [AuthException] 刷新失败
  Future<Either<AuthException, UserSession>> refreshToken({
    required String refreshToken,
  });

  /// 用户登出
  ///
  /// 清除本地存储的认证信息
  Future<void> logout();

  /// 自动登录
  ///
  /// 使用本地存储的认证信息尝试自动登录
  ///
  /// 返回 [UserSession] 自动登录成功或 [AuthException] 登录失败
  Future<Either<AuthException, UserSession>> autoLogin();

  /// 获取用户信息
  ///
  /// [userId] 用户ID
  ///
  /// 返回 [User] 用户信息或 [AuthException] 获取失败
  Future<Either<AuthException, User>> getUserInfo({
    required String userId,
  });

  /// 更新用户信息
  ///
  /// [userId] 用户ID
  /// [displayName] 显示名称（可选）
  /// [avatarUrl] 头像URL（可选）
  ///
  /// 返回更新后的 [User] 或 [AuthException] 更新失败
  Future<Either<AuthException, User>> updateUserInfo({
    required String userId,
    String? displayName,
    String? avatarUrl,
  });

  /// 修改密码
  ///
  /// [userId] 用户ID
  /// [oldPassword] 旧密码
  /// [newPassword] 新密码
  ///
  /// 返回修改成功或 [AuthException] 修改失败
  Future<Either<AuthException, void>> changePassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
  });

  /// 重置密码
  ///
  /// [email] 邮箱地址
  /// [resetCode] 重置码
  /// [newPassword] 新密码
  ///
  /// 返回重置成功或 [AuthException] 重置失败
  Future<Either<AuthException, void>> resetPassword({
    required String email,
    required String resetCode,
    required String newPassword,
  });

  /// 发送密码重置邮件
  ///
  /// [email] 邮箱地址
  ///
  /// 返回发送成功或 [AuthException] 发送失败
  Future<Either<AuthException, void>> sendPasswordResetEmail({
    required String email,
  });

  /// 验证邮箱
  ///
  /// [verificationToken] 验证令牌
  ///
  /// 返回验证成功或 [AuthException] 验证失败
  Future<Either<AuthException, void>> verifyEmail({
    required String verificationToken,
  });

  /// 验证手机号
  ///
  /// [phoneNumber] 手机号码
  /// [verificationCode] 验证码
  ///
  /// 返回验证成功或 [AuthException] 验证失败
  Future<Either<AuthException, void>> verifyPhone({
    required String phoneNumber,
    required String verificationCode,
  });

  /// 检查用户名是否可用
  ///
  /// [username] 用户名
  ///
  /// 返回是否可用或 [AuthException] 检查失败
  Future<Either<AuthException, bool>> checkUsernameAvailability({
    required String username,
  });

  /// 检查邮箱是否可用
  ///
  /// [email] 邮箱地址
  ///
  /// 返回是否可用或 [AuthException] 检查失败
  Future<Either<AuthException, bool>> checkEmailAvailability({
    required String email,
  });

  /// 检查手机号是否可用
  ///
  /// [phoneNumber] 手机号码
  ///
  /// 返回是否可用或 [AuthException] 检查失败
  Future<Either<AuthException, bool>> checkPhoneAvailability({
    required String phoneNumber,
  });
}
