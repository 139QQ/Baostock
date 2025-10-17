import 'package:dartz/dartz.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/user_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_api.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/utils/logger.dart';

/// 认证仓库实现
///
/// 实现认证相关的业务逻辑
class AuthRepositoryImpl implements AuthRepository {
  final AuthApi _api;

  AuthRepositoryImpl({
    required AuthApi api,
    required SecureStorageService storage,
  }) : _api = api;

  @override
  Future<UserSession?> getCurrentSession() async {
    try {
      // 优先从会话存储获取
      final session = await SecureStorageService.getUserSession();
      if (session != null && session.isValid && !session.isExpired) {
        return session;
      }

      // 如果会话不存在或已过期，尝试从令牌重建
      final accessToken = await SecureStorageService.getAccessToken();
      final refreshToken = await SecureStorageService.getRefreshToken();

      if (accessToken != null && refreshToken != null) {
        // 尝试刷新令牌
        final refreshResult =
            await this.refreshToken(refreshToken: refreshToken);

        return refreshResult.fold(
          (error) {
            // 刷新失败，清除本地数据
            _clearLocalData();
            return null;
          },
          (newSession) => newSession,
        );
      }

      return null;
    } catch (e) {
      AppLogger.error('获取当前会话失败', e.toString());
      return null;
    }
  }

  @override
  Future<Either<AuthException, UserSession>> loginWithPhone({
    required String phoneNumber,
    required String verificationCode,
  }) async {
    try {
      AppLogger.info('开始手机号登录: ${_maskPhoneNumber(phoneNumber)}');

      final response = await _api.loginWithPhone(
        phoneNumber: phoneNumber,
        verificationCode: verificationCode,
      );

      if (!response.success) {
        return Left(AuthException(
          _mapApiErrorToAuthResult(response.message),
          details: response.message,
        ));
      }

      if (response.accessToken == null || response.refreshToken == null) {
        return Left(AuthException(
          AuthResult.serverError,
          details: '登录响应中缺少令牌信息',
        ));
      }

      // 创建用户会话
      final session = UserSession(
        userId: response.user?.id ?? '',
        accessToken: response.accessToken!,
        refreshToken: response.refreshToken!,
        expiresAt: DateTime.now().add(
          Duration(seconds: response.expiresIn ?? 3600),
        ),
        isValid: true,
        createdAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
      );

      // 保存会话数据
      await _saveSessionData(session, response.user);

      AppLogger.info('手机号登录成功: ${session.userId}');
      return Right(session);
    } on ApiException catch (e) {
      AppLogger.error('手机号登录API错误', e.toString());
      return Left(AuthException(
        _mapApiErrorToAuthResult(e.message),
        details: e.message,
      ));
    } catch (e) {
      AppLogger.error('手机号登录失败', e.toString());
      return Left(AuthException(
        AuthResult.unknownError,
        details: '登录过程中发生未知错误: $e',
      ));
    }
  }

  @override
  Future<Either<AuthException, UserSession>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.info('开始邮箱登录: ${_maskEmail(email)}');

      final response = await _api.loginWithEmail(
        email: email,
        password: password,
      );

      if (!response.success) {
        return Left(AuthException(
          _mapApiErrorToAuthResult(response.message),
          details: response.message,
        ));
      }

      if (response.accessToken == null || response.refreshToken == null) {
        return Left(AuthException(
          AuthResult.serverError,
          details: '登录响应中缺少令牌信息',
        ));
      }

      // 创建用户会话
      final session = UserSession(
        userId: response.user?.id ?? '',
        accessToken: response.accessToken!,
        refreshToken: response.refreshToken!,
        expiresAt: DateTime.now().add(
          Duration(seconds: response.expiresIn ?? 3600),
        ),
        isValid: true,
        createdAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
      );

      // 保存会话数据
      await _saveSessionData(session, response.user);

      AppLogger.info('邮箱登录成功: ${session.userId}');
      return Right(session);
    } on ApiException catch (e) {
      AppLogger.error('邮箱登录API错误', e.toString());
      return Left(AuthException(
        _mapApiErrorToAuthResult(e.message),
        details: e.message,
      ));
    } catch (e) {
      AppLogger.error('邮箱登录失败', e.toString());
      return Left(AuthException(
        AuthResult.unknownError,
        details: '登录过程中发生未知错误: $e',
      ));
    }
  }

  @override
  Future<Either<AuthException, void>> sendPhoneVerificationCode({
    required String phoneNumber,
  }) async {
    try {
      AppLogger.info('发送手机验证码: ${_maskPhoneNumber(phoneNumber)}');

      final response = await _api.sendPhoneVerificationCode(
        phoneNumber: phoneNumber,
      );

      if (!response.success) {
        return Left(AuthException(
          _mapApiErrorToAuthResult(response.message),
          details: response.message,
        ));
      }

      AppLogger.info('手机验证码发送成功');
      return const Right(null);
    } on ApiException catch (e) {
      AppLogger.error('发送手机验证码API错误', e.toString());
      return Left(AuthException(
        _mapApiErrorToAuthResult(e.message),
        details: e.message,
      ));
    } catch (e) {
      AppLogger.error('发送手机验证码失败', e.toString());
      return Left(AuthException(
        AuthResult.unknownError,
        details: '发送验证码时发生未知错误: $e',
      ));
    }
  }

  @override
  Future<Either<AuthException, void>> sendEmailVerificationCode({
    required String email,
  }) async {
    try {
      AppLogger.info('发送邮箱验证码: ${_maskEmail(email)}');

      final response = await _api.sendEmailVerificationCode(
        email: email,
      );

      if (!response.success) {
        return Left(AuthException(
          _mapApiErrorToAuthResult(response.message),
          details: response.message,
        ));
      }

      AppLogger.info('邮箱验证码发送成功');
      return const Right(null);
    } on ApiException catch (e) {
      AppLogger.error('发送邮箱验证码API错误', e.toString());
      return Left(AuthException(
        _mapApiErrorToAuthResult(e.message),
        details: e.message,
      ));
    } catch (e) {
      AppLogger.error('发送邮箱验证码失败', e.toString());
      return Left(AuthException(
        AuthResult.unknownError,
        details: '发送验证码时发生未知错误: $e',
      ));
    }
  }

  @override
  Future<Either<AuthException, User>> registerWithPhone({
    required String phoneNumber,
    required String verificationCode,
    required String password,
    required String displayName,
  }) async {
    try {
      AppLogger.info('开始手机号注册: ${_maskPhoneNumber(phoneNumber)}');

      final response = await _api.registerWithPhone(
        phoneNumber: phoneNumber,
        verificationCode: verificationCode,
        password: password,
        displayName: displayName,
      );

      if (!response.success || response.user == null) {
        return Left(AuthException(
          _mapApiErrorToAuthResult(response.message),
          details: response.message,
        ));
      }

      final user = _mapUserInfoResponseToUser(response.user!);

      AppLogger.info('手机号注册成功: ${user.id}');
      return Right(user);
    } on ApiException catch (e) {
      AppLogger.error('手机号注册API错误', e.toString());
      return Left(AuthException(
        _mapApiErrorToAuthResult(e.message),
        details: e.message,
      ));
    } catch (e) {
      AppLogger.error('手机号注册失败', e.toString());
      return Left(AuthException(
        AuthResult.unknownError,
        details: '注册过程中发生未知错误: $e',
      ));
    }
  }

  @override
  Future<Either<AuthException, User>> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      AppLogger.info('开始邮箱注册: ${_maskEmail(email)}');

      final response = await _api.registerWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );

      if (!response.success || response.user == null) {
        return Left(AuthException(
          _mapApiErrorToAuthResult(response.message),
          details: response.message,
        ));
      }

      final user = _mapUserInfoResponseToUser(response.user!);

      AppLogger.info('邮箱注册成功: ${user.id}');
      return Right(user);
    } on ApiException catch (e) {
      AppLogger.error('邮箱注册API错误', e.toString());
      return Left(AuthException(
        _mapApiErrorToAuthResult(e.message),
        details: e.message,
      ));
    } catch (e) {
      AppLogger.error('邮箱注册失败', e.toString());
      return Left(AuthException(
        AuthResult.unknownError,
        details: '注册过程中发生未知错误: $e',
      ));
    }
  }

  @override
  Future<Either<AuthException, UserSession>> refreshToken({
    required String refreshToken,
  }) async {
    try {
      AppLogger.info('开始刷新令牌');

      final response = await _api.refreshToken(refreshToken: refreshToken);

      if (!response.success) {
        return Left(AuthException(
          _mapApiErrorToAuthResult(response.message),
          details: response.message,
        ));
      }

      if (response.accessToken == null) {
        return Left(AuthException(
          AuthResult.serverError,
          details: '刷新响应中缺少访问令牌',
        ));
      }

      // 创建新会话
      final session = UserSession(
        userId: response.user?.id ?? '',
        accessToken: response.accessToken!,
        refreshToken: refreshToken, // 保持原有的刷新令牌
        expiresAt: DateTime.now().add(
          Duration(seconds: response.expiresIn ?? 3600),
        ),
        isValid: true,
        createdAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
      );

      // 保存新会话
      await _saveSessionData(session, response.user);

      AppLogger.info('令牌刷新成功: ${session.userId}');
      return Right(session);
    } on ApiException catch (e) {
      AppLogger.error('刷新令牌API错误', e.toString());
      return Left(AuthException(
        _mapApiErrorToAuthResult(e.message),
        details: e.message,
      ));
    } catch (e) {
      AppLogger.error('刷新令牌失败', e.toString());
      return Left(AuthException(
        AuthResult.unknownError,
        details: '刷新令牌时发生未知错误: $e',
      ));
    }
  }

  @override
  Future<void> logout() async {
    try {
      AppLogger.info('用户登出');
      await _clearLocalData();
    } catch (e) {
      AppLogger.error('登出失败', e.toString());
      // 即使登出失败也要清除本地数据
      await _clearLocalData();
    }
  }

  @override
  Future<Either<AuthException, UserSession>> autoLogin() async {
    try {
      AppLogger.info('开始自动登录');

      final session = await getCurrentSession();
      if (session != null) {
        AppLogger.info('自动登录成功: ${session.userId}');
        return Right(session);
      }

      return Left(AuthException(
        AuthResult.tokenExpired,
        details: '没有有效的登录信息',
      ));
    } catch (e) {
      AppLogger.error('自动登录失败', e.toString());
      return Left(AuthException(
        AuthResult.unknownError,
        details: '自动登录时发生错误: $e',
      ));
    }
  }

  @override
  Future<Either<AuthException, User>> getUserInfo({
    required String userId,
  }) async {
    try {
      final session = await getCurrentSession();
      if (session == null) {
        return Left(AuthException(
          AuthResult.tokenInvalid,
          details: '用户未登录',
        ));
      }

      final response = await _api.getUserInfo(
        userId: userId,
        accessToken: session.accessToken,
      );

      final user = _mapUserInfoResponseToUser(response);
      return Right(user);
    } on ApiException catch (e) {
      return Left(AuthException(
        _mapApiErrorToAuthResult(e.message),
        details: e.message,
      ));
    } catch (e) {
      return Left(AuthException(
        AuthResult.unknownError,
        details: '获取用户信息时发生错误: $e',
      ));
    }
  }

  @override
  Future<Either<AuthException, User>> updateUserInfo({
    required String userId,
    String? displayName,
    String? avatarUrl,
  }) async {
    // TODO: 实现更新用户信息API
    return Left(AuthException(
      AuthResult.serverError,
      details: '功能暂未实现',
    ));
  }

  @override
  Future<Either<AuthException, void>> changePassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    // TODO: 实现修改密码API
    return Left(AuthException(
      AuthResult.serverError,
      details: '功能暂未实现',
    ));
  }

  @override
  Future<Either<AuthException, void>> resetPassword({
    required String email,
    required String resetCode,
    required String newPassword,
  }) async {
    // TODO: 实现重置密码API
    return Left(AuthException(
      AuthResult.serverError,
      details: '功能暂未实现',
    ));
  }

  @override
  Future<Either<AuthException, void>> sendPasswordResetEmail({
    required String email,
  }) async {
    // TODO: 实现发送密码重置邮件API
    return Left(AuthException(
      AuthResult.serverError,
      details: '功能暂未实现',
    ));
  }

  @override
  Future<Either<AuthException, void>> verifyEmail({
    required String verificationToken,
  }) async {
    // TODO: 实现邮箱验证API
    return Left(AuthException(
      AuthResult.serverError,
      details: '功能暂未实现',
    ));
  }

  @override
  Future<Either<AuthException, void>> verifyPhone({
    required String phoneNumber,
    required String verificationCode,
  }) async {
    // TODO: 实现手机号验证API
    return Left(AuthException(
      AuthResult.serverError,
      details: '功能暂未实现',
    ));
  }

  @override
  Future<Either<AuthException, bool>> checkUsernameAvailability({
    required String username,
  }) async {
    // TODO: 实现检查用户名可用性API
    return Left(AuthException(
      AuthResult.serverError,
      details: '功能暂未实现',
    ));
  }

  @override
  Future<Either<AuthException, bool>> checkEmailAvailability({
    required String email,
  }) async {
    // TODO: 实现检查邮箱可用性API
    return Left(AuthException(
      AuthResult.serverError,
      details: '功能暂未实现',
    ));
  }

  @override
  Future<Either<AuthException, bool>> checkPhoneAvailability({
    required String phoneNumber,
  }) async {
    // TODO: 实现检查手机号可用性API
    return Left(AuthException(
      AuthResult.serverError,
      details: '功能暂未实现',
    ));
  }

  /// 保存会话数据
  Future<void> _saveSessionData(
      UserSession session, UserInfoResponse? user) async {
    await Future.wait([
      SecureStorageService.saveAccessToken(session.accessToken),
      SecureStorageService.saveRefreshToken(session.refreshToken),
      SecureStorageService.saveUserSession(session),
      if (user != null) SecureStorageService.saveUserData(user.toJson()),
    ]);
  }

  /// 清除本地数据
  Future<void> _clearLocalData() async {
    try {
      await SecureStorageService.clearAuthData();
    } catch (e) {
      AppLogger.error('清除本地数据失败', e.toString());
    }
  }

  /// 将API错误映射到AuthResult
  AuthResult _mapApiErrorToAuthResult(String? errorMessage) {
    if (errorMessage == null) return AuthResult.unknownError;

    final message = errorMessage.toLowerCase();

    if (message.contains('密码') || message.contains('password')) {
      if (message.contains('错误') ||
          message.contains('incorrect') ||
          message.contains('wrong')) {
        return AuthResult.invalidCredentials;
      }
    }

    if (message.contains('用户') || message.contains('user')) {
      if (message.contains('不存在') || message.contains('not found')) {
        return AuthResult.userNotFound;
      }
      if (message.contains('锁定') || message.contains('locked')) {
        return AuthResult.accountLocked;
      }
      if (message.contains('已存在') || message.contains('already exists')) {
        return AuthResult.accountExists;
      }
    }

    if (message.contains('验证码') ||
        message.contains('verification') ||
        message.contains('code')) {
      if (message.contains('过期') || message.contains('expired')) {
        return AuthResult.verificationCodeExpired;
      }
      if (message.contains('错误') ||
          message.contains('incorrect') ||
          message.contains('wrong')) {
        return AuthResult.invalidCredentials;
      }
      if (message.contains('频繁') ||
          message.contains('frequent') ||
          message.contains('rate')) {
        return AuthResult.verificationCodeExceeded;
      }
    }

    if (message.contains('网络') ||
        message.contains('network') ||
        message.contains('connection')) {
      return AuthResult.networkError;
    }

    if (message.contains('服务器') ||
        message.contains('server') ||
        message.contains('internal')) {
      return AuthResult.serverError;
    }

    if (message.contains('令牌') || message.contains('token')) {
      if (message.contains('过期') || message.contains('expired')) {
        return AuthResult.tokenExpired;
      }
      if (message.contains('无效') || message.contains('invalid')) {
        return AuthResult.tokenInvalid;
      }
    }

    return AuthResult.unknownError;
  }

  /// 将UserInfoResponse映射到User实体
  User _mapUserInfoResponseToUser(UserInfoResponse response) {
    return User(
      id: response.id,
      phoneNumber: response.phoneNumber,
      email: response.email,
      displayName: response.displayName,
      avatarUrl: response.avatarUrl,
      createdAt: response.createdAt,
      lastLoginAt: response.lastLoginAt,
      isEmailVerified: response.isEmailVerified,
      isPhoneVerified: response.isPhoneVerified,
    );
  }

  /// 掩码手机号
  String _maskPhoneNumber(String phoneNumber) {
    if (phoneNumber.length >= 11) {
      return '${phoneNumber.substring(0, 3)}****${phoneNumber.substring(7)}';
    }
    return '****';
  }

  /// 掩码邮箱
  String _maskEmail(String email) {
    final atIndex = email.indexOf('@');
    if (atIndex > 2) {
      final username = email.substring(0, atIndex);
      final domain = email.substring(atIndex);
      final maskedUsername = '${username.substring(0, 2)}****';
      return '$maskedUsername$domain';
    }
    return '****@****.com';
  }
}
