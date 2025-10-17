import 'package:bloc/bloc.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/user_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_with_phone.dart';
import '../../domain/usecases/login_with_email.dart';
import '../../domain/usecases/send_verification_code.dart'
    hide VerificationCodeType;
import 'auth_event.dart';
import 'auth_state.dart';

/// 认证BLoC
///
/// 处理用户认证相关的状态管理
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;
  final LoginWithPhone _loginWithPhone;
  final LoginWithEmail _loginWithEmail;
  final SendVerificationCode _sendVerificationCode;

  AuthBloc({
    required AuthRepository repository,
    required LoginWithPhone loginWithPhone,
    required LoginWithEmail loginWithEmail,
    required SendVerificationCode sendVerificationCode,
  })  : _repository = repository,
        _loginWithPhone = loginWithPhone,
        _loginWithEmail = loginWithEmail,
        _sendVerificationCode = sendVerificationCode,
        super(const AuthInitial()) {
    // 初始化事件处理
    on<CheckAuthStatus>(_onCheckAuthStatus);

    // 登录事件处理
    on<LoginWithPhoneRequested>(_onLoginWithPhone);
    on<LoginWithEmailRequested>(_onLoginWithEmail);

    // 验证码事件处理
    on<SendPhoneVerificationCodeRequested>(_onSendPhoneVerificationCode);
    on<SendEmailVerificationCodeRequested>(_onSendEmailVerificationCode);

    // 注册事件处理
    on<RegisterWithPhoneRequested>(_onRegisterWithPhone);
    on<RegisterWithEmailRequested>(_onRegisterWithEmail);

    // 令牌管理事件处理
    on<RefreshTokenRequested>(_onRefreshToken);

    // 用户信息管理事件处理
    on<UpdateUserInfoRequested>(_onUpdateUserInfo);
    on<ChangePasswordRequested>(_onChangePassword);
    on<ResetPasswordRequested>(_onResetPassword);
    on<SendPasswordResetEmailRequested>(_onSendPasswordResetEmail);

    // 验证事件处理
    on<VerifyEmailRequested>(_onVerifyEmail);
    on<VerifyPhoneRequested>(_onVerifyPhone);

    // 状态管理事件处理
    on<Logout>(_onLogout);
    on<ClearAuthError>(_onClearAuthError);
    on<AuthReset>(_onAuthReset);
  }

  /// 检查认证状态
  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: '检查登录状态...'));

    try {
      final session = await _repository.getCurrentSession();

      if (session != null && session.isValid && !session.isExpired) {
        // 会话有效，获取用户信息
        final userResult =
            await _repository.getUserInfo(userId: session.userId);

        await userResult.fold(
          (error) async {
            // 获取用户信息失败，清除会话
            await _repository.logout();
            emit(AuthUnauthenticated(message: error.result.message));
          },
          (user) async {
            // 认证成功
            emit(AuthAuthenticated(user: user, session: session));
          },
        );
      } else {
        // 会话无效或不存在
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthFailure.unknown(details: '检查认证状态时发生错误: $e'));
    }
  }

  /// 手机号登录
  Future<void> _onLoginWithPhone(
    LoginWithPhoneRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: '正在登录...'));

    try {
      final result = await _loginWithPhone(
        phoneNumber: event.phoneNumber,
        verificationCode: event.verificationCode,
      );

      await result.fold(
        (error) async {
          emit(AuthFailure(
            error: error.result,
            details: error.details,
          ));
        },
        (session) async {
          // 登录成功，获取用户信息
          final userResult =
              await _repository.getUserInfo(userId: session.userId);

          await userResult.fold(
            (userError) async {
              // 获取用户信息失败，但登录成功
              emit(AuthAuthenticated(
                user: User.testUser(id: session.userId),
                session: session,
              ));
            },
            (user) async {
              emit(AuthAuthenticated(user: user, session: session));
            },
          );
        },
      );
    } catch (e) {
      emit(AuthFailure.unknown(details: '登录过程中发生错误: $e'));
    }
  }

  /// 邮箱登录
  Future<void> _onLoginWithEmail(
    LoginWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: '正在登录...'));

    try {
      final result = await _loginWithEmail(
        email: event.email,
        password: event.password,
      );

      await result.fold(
        (error) async {
          emit(AuthFailure(
            error: error.result,
            details: error.details,
          ));
        },
        (session) async {
          // 登录成功，获取用户信息
          final userResult =
              await _repository.getUserInfo(userId: session.userId);

          await userResult.fold(
            (userError) async {
              // 获取用户信息失败，但登录成功
              emit(AuthAuthenticated(
                user: User.testUser(id: session.userId),
                session: session,
              ));
            },
            (user) async {
              emit(AuthAuthenticated(user: user, session: session));
            },
          );
        },
      );
    } catch (e) {
      emit(AuthFailure.unknown(details: '登录过程中发生错误: $e'));
    }
  }

  /// 发送手机验证码
  Future<void> _onSendPhoneVerificationCode(
    SendPhoneVerificationCodeRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: '正在发送验证码...'));

    try {
      final result = await _sendVerificationCode.sendPhoneCode(
        phoneNumber: event.phoneNumber,
      );

      result.fold(
        (error) {
          emit(AuthFailure(
            error: error.result,
            details: error.details,
          ));
        },
        (_) {
          emit(VerificationCodeSent(
            recipient: event.phoneNumber,
            type: VerificationCodeType.phone,
            cooldownSeconds: 60, // 默认60秒冷却时间
          ));
        },
      );
    } catch (e) {
      emit(AuthFailure.unknown(details: '发送验证码时发生错误: $e'));
    }
  }

  /// 发送邮箱验证码
  Future<void> _onSendEmailVerificationCode(
    SendEmailVerificationCodeRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: '正在发送验证码...'));

    try {
      final result = await _sendVerificationCode.sendEmailCode(
        email: event.email,
      );

      result.fold(
        (error) {
          emit(AuthFailure(
            error: error.result,
            details: error.details,
          ));
        },
        (_) {
          emit(VerificationCodeSent(
            recipient: event.email,
            type: VerificationCodeType.email,
            cooldownSeconds: 60, // 默认60秒冷却时间
          ));
        },
      );
    } catch (e) {
      emit(AuthFailure.unknown(details: '发送验证码时发生错误: $e'));
    }
  }

  /// 手机号注册
  Future<void> _onRegisterWithPhone(
    RegisterWithPhoneRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: '正在注册...'));

    try {
      final result = await _repository.registerWithPhone(
        phoneNumber: event.phoneNumber,
        verificationCode: event.verificationCode,
        password: event.password,
        displayName: event.displayName,
      );

      result.fold(
        (error) {
          emit(AuthFailure(
            error: error.result,
            details: error.details,
          ));
        },
        (user) {
          // 注册成功，创建测试会话
          final session = UserSession.testSession(userId: user.id);
          emit(AuthAuthenticated(user: user, session: session));
        },
      );
    } catch (e) {
      emit(AuthFailure.unknown(details: '注册过程中发生错误: $e'));
    }
  }

  /// 邮箱注册
  Future<void> _onRegisterWithEmail(
    RegisterWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: '正在注册...'));

    try {
      final result = await _repository.registerWithEmail(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
      );

      result.fold(
        (error) {
          emit(AuthFailure(
            error: error.result,
            details: error.details,
          ));
        },
        (user) {
          // 注册成功，创建测试会话
          final session = UserSession.testSession(userId: user.id);
          emit(AuthAuthenticated(user: user, session: session));
        },
      );
    } catch (e) {
      emit(AuthFailure.unknown(details: '注册过程中发生错误: $e'));
    }
  }

  /// 刷新令牌
  Future<void> _onRefreshToken(
    RefreshTokenRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: '正在刷新登录状态...'));

    try {
      final result = await _repository.refreshToken(
        refreshToken: event.refreshToken,
      );

      result.fold(
        (error) {
          emit(AuthFailure(
            error: error.result,
            details: error.details,
          ));
        },
        (session) async {
          // 刷新成功，获取用户信息
          final userResult =
              await _repository.getUserInfo(userId: session.userId);

          await userResult.fold(
            (userError) async {
              emit(const AuthUnauthenticated(message: '用户信息获取失败'));
            },
            (user) async {
              emit(AuthAuthenticated(user: user, session: session));
            },
          );
        },
      );
    } catch (e) {
      emit(AuthFailure.unknown(details: '刷新令牌时发生错误: $e'));
    }
  }

  /// 更新用户信息
  Future<void> _onUpdateUserInfo(
    UpdateUserInfoRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is! AuthAuthenticated) {
      emit(AuthFailure(
        error: AuthResult.tokenInvalid,
        details: '请先登录',
      ));
      return;
    }

    try {
      final result = await _repository.updateUserInfo(
        userId: event.userId,
        displayName: event.displayName,
        avatarUrl: event.avatarUrl,
      );

      result.fold(
        (error) {
          emit(AuthFailure(
            error: error.result,
            details: error.details,
          ));
        },
        (updatedUser) {
          // 保持当前会话，更新用户信息
          final currentSession = (state as AuthAuthenticated).session;
          emit(UserInfoUpdated(updatedUser: updatedUser));
          emit(AuthAuthenticated(user: updatedUser, session: currentSession));
        },
      );
    } catch (e) {
      emit(AuthFailure.unknown(details: '更新用户信息时发生错误: $e'));
    }
  }

  /// 修改密码
  Future<void> _onChangePassword(
    ChangePasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is! AuthAuthenticated) {
      emit(AuthFailure(
        error: AuthResult.tokenInvalid,
        details: '请先登录',
      ));
      return;
    }

    emit(const AuthLoading(message: '正在修改密码...'));

    try {
      final result = await _repository.changePassword(
        userId: event.userId,
        oldPassword: event.oldPassword,
        newPassword: event.newPassword,
      );

      result.fold(
        (error) {
          emit(AuthFailure(
            error: error.result,
            details: error.details,
          ));
        },
        (_) {
          // 密码修改成功，保持当前状态
          final currentState = state as AuthAuthenticated;
          emit(AuthAuthenticated(
              user: currentState.user, session: currentState.session));
        },
      );
    } catch (e) {
      emit(AuthFailure.unknown(details: '修改密码时发生错误: $e'));
    }
  }

  /// 重置密码
  Future<void> _onResetPassword(
    ResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: '正在重置密码...'));

    try {
      final result = await _repository.resetPassword(
        email: event.email,
        resetCode: event.resetCode,
        newPassword: event.newPassword,
      );

      result.fold(
        (error) {
          emit(AuthFailure(
            error: error.result,
            details: error.details,
          ));
        },
        (_) {
          emit(const AuthUnauthenticated(message: '密码重置成功，请重新登录'));
        },
      );
    } catch (e) {
      emit(AuthFailure.unknown(details: '重置密码时发生错误: $e'));
    }
  }

  /// 发送密码重置邮件
  Future<void> _onSendPasswordResetEmail(
    SendPasswordResetEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: '正在发送重置邮件...'));

    try {
      final result = await _repository.sendPasswordResetEmail(
        email: event.email,
      );

      result.fold(
        (error) {
          emit(AuthFailure(
            error: error.result,
            details: error.details,
          ));
        },
        (_) {
          emit(VerificationCodeSent(
            recipient: event.email,
            type: VerificationCodeType.email,
          ));
        },
      );
    } catch (e) {
      emit(AuthFailure.unknown(details: '发送重置邮件时发生错误: $e'));
    }
  }

  /// 验证邮箱
  Future<void> _onVerifyEmail(
    VerifyEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: '正在验证邮箱...'));

    try {
      final result = await _repository.verifyEmail(
        verificationToken: event.verificationToken,
      );

      result.fold(
        (error) {
          emit(AuthFailure(
            error: error.result,
            details: error.details,
          ));
        },
        (_) {
          // 邮箱验证成功，如果是已登录用户，更新用户信息
          if (state is AuthAuthenticated) {
            final currentUser = (state as AuthAuthenticated).user;
            final updatedUser = currentUser.copyWith(isEmailVerified: true);
            final currentSession = (state as AuthAuthenticated).session;
            emit(UserInfoUpdated(updatedUser: updatedUser));
            emit(AuthAuthenticated(user: updatedUser, session: currentSession));
          } else {
            emit(const AuthUnauthenticated(message: '邮箱验证成功，请登录'));
          }
        },
      );
    } catch (e) {
      emit(AuthFailure.unknown(details: '验证邮箱时发生错误: $e'));
    }
  }

  /// 验证手机号
  Future<void> _onVerifyPhone(
    VerifyPhoneRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: '正在验证手机号...'));

    try {
      final result = await _repository.verifyPhone(
        phoneNumber: event.phoneNumber,
        verificationCode: event.verificationCode,
      );

      result.fold(
        (error) {
          emit(AuthFailure(
            error: error.result,
            details: error.details,
          ));
        },
        (_) {
          // 手机号验证成功，如果是已登录用户，更新用户信息
          if (state is AuthAuthenticated) {
            final currentUser = (state as AuthAuthenticated).user;
            final updatedUser = currentUser.copyWith(isPhoneVerified: true);
            final currentSession = (state as AuthAuthenticated).session;
            emit(UserInfoUpdated(updatedUser: updatedUser));
            emit(AuthAuthenticated(user: updatedUser, session: currentSession));
          } else {
            emit(const AuthUnauthenticated(message: '手机号验证成功，请登录'));
          }
        },
      );
    } catch (e) {
      emit(AuthFailure.unknown(details: '验证手机号时发生错误: $e'));
    }
  }

  /// 登出
  Future<void> _onLogout(
    Logout event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _repository.logout();
      emit(const AuthUnauthenticated());
    } catch (e) {
      // 即使登出失败，也清除本地状态
      emit(const AuthUnauthenticated());
    }
  }

  /// 清除认证错误
  void _onClearAuthError(
    ClearAuthError event,
    Emitter<AuthState> emit,
  ) {
    if (state is AuthFailure) {
      emit(const AuthUnauthenticated());
    }
  }

  /// 重置认证状态
  void _onAuthReset(
    AuthReset event,
    Emitter<AuthState> emit,
  ) {
    emit(const AuthInitial());
  }
}
