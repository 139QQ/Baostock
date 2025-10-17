import 'dart:async';
import '../../features/auth/domain/entities/user.dart';
import '../../features/auth/domain/entities/user_session.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import 'secure_storage_service.dart';

/// 认证服务
///
/// 提供全局的认证状态管理和认证相关服务
class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();

  AuthService._();

  AuthRepository? _repository;
  AuthBloc? _authBloc;
  StreamSubscription<AuthState>? _authSubscription;

  /// 当前用户
  User? get currentUser => _authBloc?.state is AuthAuthenticated
      ? (_authBloc!.state as AuthAuthenticated).user
      : null;

  /// 当前会话
  UserSession? get currentSession => _authBloc?.state is AuthAuthenticated
      ? (_authBloc!.state as AuthAuthenticated).session
      : null;

  /// 是否已登录
  bool get isLoggedIn => _authBloc?.state is AuthAuthenticated;

  /// 是否正在加载
  bool get isLoading => _authBloc?.state is AuthLoading;

  /// 最后的错误
  String? get lastError => _authBloc?.state is AuthFailure
      ? (_authBloc!.state as AuthFailure).userMessage
      : null;

  /// 初始化认证服务
  Future<void> initialize({
    required AuthRepository repository,
    AuthBloc? authBloc,
  }) async {
    _repository = repository;
    _authBloc = authBloc;

    // 监听认证状态变化
    if (_authBloc != null) {
      _authSubscription = _authBloc!.stream.listen((state) {
        _onAuthStateChanged(state);
      });
    }

    // 检查自动登录
    await _checkAutoLogin();
  }

  /// 销毁认证服务
  Future<void> dispose() async {
    await _authSubscription?.cancel();
    _authSubscription = null;
    _authBloc = null;
    _repository = null;
  }

  /// 检查自动登录
  Future<void> _checkAutoLogin() async {
    if (_authBloc != null && _repository != null) {
      // 添加小延迟确保UI已经准备好
      Future.delayed(const Duration(milliseconds: 100), () {
        _authBloc!.add(const CheckAuthStatus());
      });
    }
  }

  /// 监听认证状态变化
  void _onAuthStateChanged(AuthState state) {
    // 可以在这里处理全局的认证状态变化
    // 例如：发送分析事件、更新全局状态等
  }

  /// 手机号登录
  Future<bool> loginWithPhone({
    required String phoneNumber,
    required String verificationCode,
  }) async {
    if (_authBloc == null) return false;

    try {
      _authBloc!.add(LoginWithPhoneRequested(
        phoneNumber: phoneNumber,
        verificationCode: verificationCode,
      ));

      // 等待登录结果
      return await _waitForAuthResult();
    } catch (e) {
      return false;
    }
  }

  /// 邮箱登录
  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    if (_authBloc == null) return false;

    try {
      _authBloc!.add(LoginWithEmailRequested(
        email: email,
        password: password,
      ));

      // 等待登录结果
      return await _waitForAuthResult();
    } catch (e) {
      return false;
    }
  }

  /// 发送手机验证码
  Future<bool> sendPhoneVerificationCode({
    required String phoneNumber,
  }) async {
    if (_authBloc == null) return false;

    try {
      _authBloc!.add(SendPhoneVerificationCodeRequested(
        phoneNumber: phoneNumber,
      ));

      // 等待发送结果
      return await _waitForVerificationResult();
    } catch (e) {
      return false;
    }
  }

  /// 发送邮箱验证码
  Future<bool> sendEmailVerificationCode({
    required String email,
  }) async {
    if (_authBloc == null) return false;

    try {
      _authBloc!.add(SendEmailVerificationCodeRequested(
        email: email,
      ));

      // 等待发送结果
      return await _waitForVerificationResult();
    } catch (e) {
      return false;
    }
  }

  /// 登出
  Future<void> logout() async {
    if (_authBloc != null) {
      _authBloc!.add(const Logout());
    }
  }

  /// 刷新令牌
  Future<bool> refreshToken() async {
    if (_authBloc == null || currentSession == null) return false;

    try {
      _authBloc!.add(RefreshTokenRequested(
        refreshToken: currentSession!.refreshToken,
      ));

      // 等待刷新结果
      return await _waitForAuthResult();
    } catch (e) {
      return false;
    }
  }

  /// 更新用户信息
  Future<bool> updateUserInfo({
    required String userId,
    String? displayName,
    String? avatarUrl,
  }) async {
    if (_authBloc == null) return false;

    try {
      _authBloc!.add(UpdateUserInfoRequested(
        userId: userId,
        displayName: displayName,
        avatarUrl: avatarUrl,
      ));

      // 等待更新结果
      return await _waitForUpdateResult();
    } catch (e) {
      return false;
    }
  }

  /// 修改密码
  Future<bool> changePassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    if (_authBloc == null) return false;

    try {
      _authBloc!.add(ChangePasswordRequested(
        userId: userId,
        oldPassword: oldPassword,
        newPassword: newPassword,
      ));

      // 等待修改结果
      return await _waitForChangePasswordResult();
    } catch (e) {
      return false;
    }
  }

  /// 重置密码
  Future<bool> resetPassword({
    required String email,
    required String resetCode,
    required String newPassword,
  }) async {
    if (_authBloc == null) return false;

    try {
      _authBloc!.add(ResetPasswordRequested(
        email: email,
        resetCode: resetCode,
        newPassword: newPassword,
      ));

      // 等待重置结果
      return await _waitForResetPasswordResult();
    } catch (e) {
      return false;
    }
  }

  /// 发送密码重置邮件
  Future<bool> sendPasswordResetEmail({
    required String email,
  }) async {
    if (_authBloc == null) return false;

    try {
      _authBloc!.add(SendPasswordResetEmailRequested(
        email: email,
      ));

      // 等待发送结果
      return await _waitForPasswordResetEmailResult();
    } catch (e) {
      return false;
    }
  }

  /// 验证邮箱
  Future<bool> verifyEmail({
    required String verificationToken,
  }) async {
    if (_authBloc == null) return false;

    try {
      _authBloc!.add(VerifyEmailRequested(
        verificationToken: verificationToken,
      ));

      // 等待验证结果
      return await _waitForVerifyEmailResult();
    } catch (e) {
      return false;
    }
  }

  /// 验证手机号
  Future<bool> verifyPhone({
    required String phoneNumber,
    required String verificationCode,
  }) async {
    if (_authBloc == null) return false;

    try {
      _authBloc!.add(VerifyPhoneRequested(
        phoneNumber: phoneNumber,
        verificationCode: verificationCode,
      ));

      // 等待验证结果
      return await _waitForVerifyPhoneResult();
    } catch (e) {
      return false;
    }
  }

  /// 清除错误
  void clearError() {
    if (_authBloc != null) {
      _authBloc!.add(const ClearAuthError());
    }
  }

  /// 重置认证状态
  void resetAuth() {
    if (_authBloc != null) {
      _authBloc!.add(const AuthReset());
    }
  }

  /// 等待认证结果
  Future<bool> _waitForAuthResult() async {
    if (_authBloc == null) return false;

    final completer = Completer<bool>();
    late StreamSubscription subscription;

    subscription = _authBloc!.stream.listen((state) {
      if (state is AuthAuthenticated) {
        subscription.cancel();
        if (!completer.isCompleted) completer.complete(true);
      } else if (state is AuthFailure) {
        subscription.cancel();
        if (!completer.isCompleted) completer.complete(false);
      } else if (state is AuthUnauthenticated) {
        subscription.cancel();
        if (!completer.isCompleted) completer.complete(false);
      }
    });

    // 设置超时
    Timer(const Duration(seconds: 30), () {
      subscription.cancel();
      if (!completer.isCompleted) completer.complete(false);
    });

    return completer.future;
  }

  /// 等待验证码发送结果
  Future<bool> _waitForVerificationResult() async {
    if (_authBloc == null) return false;

    final completer = Completer<bool>();
    late StreamSubscription subscription;

    subscription = _authBloc!.stream.listen((state) {
      if (state is VerificationCodeSent) {
        subscription.cancel();
        if (!completer.isCompleted) completer.complete(true);
      } else if (state is AuthFailure) {
        subscription.cancel();
        if (!completer.isCompleted) completer.complete(false);
      }
    });

    // 设置超时
    Timer(const Duration(seconds: 30), () {
      subscription.cancel();
      if (!completer.isCompleted) completer.complete(false);
    });

    return completer.future;
  }

  /// 等待用户信息更新结果
  Future<bool> _waitForUpdateResult() async {
    if (_authBloc == null) return false;

    final completer = Completer<bool>();
    late StreamSubscription subscription;

    subscription = _authBloc!.stream.listen((state) {
      if (state is UserInfoUpdated) {
        subscription.cancel();
        if (!completer.isCompleted) completer.complete(true);
      } else if (state is AuthFailure) {
        subscription.cancel();
        if (!completer.isCompleted) completer.complete(false);
      }
    });

    // 设置超时
    Timer(const Duration(seconds: 30), () {
      subscription.cancel();
      if (!completer.isCompleted) completer.complete(false);
    });

    return completer.future;
  }

  /// 等待修改密码结果
  Future<bool> _waitForChangePasswordResult() async {
    if (_authBloc == null) return false;

    final completer = Completer<bool>();
    late StreamSubscription subscription;

    subscription = _authBloc!.stream.listen((state) {
      if (state is AuthAuthenticated) {
        // 密码修改成功后仍然是认证状态
        subscription.cancel();
        if (!completer.isCompleted) completer.complete(true);
      } else if (state is AuthFailure) {
        subscription.cancel();
        if (!completer.isCompleted) completer.complete(false);
      }
    });

    // 设置超时
    Timer(const Duration(seconds: 30), () {
      subscription.cancel();
      if (!completer.isCompleted) completer.complete(false);
    });

    return completer.future;
  }

  /// 等待重置密码结果
  Future<bool> _waitForResetPasswordResult() async {
    if (_authBloc == null) return false;

    final completer = Completer<bool>();
    late StreamSubscription subscription;

    subscription = _authBloc!.stream.listen((state) {
      if (state is AuthUnauthenticated) {
        // 重置密码成功后应该是未认证状态
        subscription.cancel();
        if (!completer.isCompleted) completer.complete(true);
      } else if (state is AuthFailure) {
        subscription.cancel();
        if (!completer.isCompleted) completer.complete(false);
      }
    });

    // 设置超时
    Timer(const Duration(seconds: 30), () {
      subscription.cancel();
      if (!completer.isCompleted) completer.complete(false);
    });

    return completer.future;
  }

  /// 等待发送密码重置邮件结果
  Future<bool> _waitForPasswordResetEmailResult() async {
    if (_authBloc == null) return false;

    final completer = Completer<bool>();
    late StreamSubscription subscription;

    subscription = _authBloc!.stream.listen((state) {
      if (state is VerificationCodeSent) {
        subscription.cancel();
        if (!completer.isCompleted) completer.complete(true);
      } else if (state is AuthFailure) {
        subscription.cancel();
        if (!completer.isCompleted) completer.complete(false);
      }
    });

    // 设置超时
    Timer(const Duration(seconds: 30), () {
      subscription.cancel();
      if (!completer.isCompleted) completer.complete(false);
    });

    return completer.future;
  }

  /// 等待邮箱验证结果
  Future<bool> _waitForVerifyEmailResult() async {
    if (_authBloc == null) return false;

    final completer = Completer<bool>();
    late StreamSubscription subscription;

    subscription = _authBloc!.stream.listen((state) {
      if (state is UserInfoUpdated || state is AuthAuthenticated) {
        subscription.cancel();
        if (!completer.isCompleted) completer.complete(true);
      } else if (state is AuthFailure) {
        subscription.cancel();
        if (!completer.isCompleted) completer.complete(false);
      }
    });

    // 设置超时
    Timer(const Duration(seconds: 30), () {
      subscription.cancel();
      if (!completer.isCompleted) completer.complete(false);
    });

    return completer.future;
  }

  /// 等待手机号验证结果
  Future<bool> _waitForVerifyPhoneResult() async {
    if (_authBloc == null) return false;

    final completer = Completer<bool>();
    late StreamSubscription subscription;

    subscription = _authBloc!.stream.listen((state) {
      if (state is UserInfoUpdated || state is AuthAuthenticated) {
        subscription.cancel();
        if (!completer.isCompleted) completer.complete(true);
      } else if (state is AuthFailure) {
        subscription.cancel();
        if (!completer.isCompleted) completer.complete(false);
      }
    });

    // 设置超时
    Timer(const Duration(seconds: 30), () {
      subscription.cancel();
      if (!completer.isCompleted) completer.complete(false);
    });

    return completer.future;
  }

  /// 获取认证统计信息
  Future<Map<String, dynamic>> getAuthStats() async {
    try {
      final storageStats = await SecureStorageService.getStorageStats();
      final session = currentSession;

      return {
        'isLoggedIn': isLoggedIn,
        'userId': currentUser?.id,
        'displayName': currentUser?.displayName,
        'sessionExpiresAt': session?.expiresAt.toIso8601String(),
        'sessionRemainingSeconds': session?.remainingSeconds,
        'isSessionValid': session?.isValid,
        'isSessionExpired': session?.isExpired,
        'storageStats': storageStats,
        'lastChecked': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'isLoggedIn': false,
        'lastChecked': DateTime.now().toIso8601String(),
      };
    }
  }

  /// 检查会话有效性
  Future<bool> isSessionValid() async {
    try {
      final session = currentSession;
      if (session == null) return false;

      return session.isValid && !session.isExpired;
    } catch (e) {
      return false;
    }
  }

  /// 强制刷新会话
  Future<void> refreshSession() async {
    if (await isSessionValid()) {
      await refreshToken();
    } else {
      // 如果会话无效，清除认证状态
      await logout();
    }
  }
}
