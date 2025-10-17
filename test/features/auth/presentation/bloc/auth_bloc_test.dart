import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';

import 'package:jisu_fund_analyzer/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:jisu_fund_analyzer/src/features/auth/presentation/bloc/auth_event.dart';
import 'package:jisu_fund_analyzer/src/features/auth/presentation/bloc/auth_state.dart';
import 'package:jisu_fund_analyzer/src/features/auth/domain/entities/auth_result.dart';
import 'package:jisu_fund_analyzer/src/features/auth/domain/entities/user.dart';
import 'package:jisu_fund_analyzer/src/features/auth/domain/entities/user_session.dart';
import 'package:jisu_fund_analyzer/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:jisu_fund_analyzer/src/features/auth/domain/usecases/login_with_phone.dart';
import 'package:jisu_fund_analyzer/src/features/auth/domain/usecases/login_with_email.dart';
import 'package:jisu_fund_analyzer/src/features/auth/domain/usecases/send_verification_code.dart';

import 'auth_bloc_test.mocks.dart';

@GenerateMocks([
  AuthRepository,
  LoginWithPhone,
  LoginWithEmail,
  SendVerificationCode,
])
void main() {
  group('AuthBloc测试', () {
    late MockAuthRepository mockRepository;
    late MockLoginWithPhone mockLoginWithPhone;
    late MockLoginWithEmail mockLoginWithEmail;
    late MockSendVerificationCode mockSendVerificationCode;

    setUp(() {
      mockRepository = MockAuthRepository();
      mockLoginWithPhone = MockLoginWithPhone();
      mockLoginWithEmail = MockLoginWithEmail();
      mockSendVerificationCode = MockSendVerificationCode();
    });

    test('初始状态应该是AuthInitial', () {
      // Act
      final authBloc = AuthBloc(
        repository: mockRepository,
        loginWithPhone: mockLoginWithPhone,
        loginWithEmail: mockLoginWithEmail,
        sendVerificationCode: mockSendVerificationCode,
      );

      // Assert
      expect(authBloc.state, equals(const AuthInitial()));
      authBloc.close();
    });

    group('CheckAuthStatus事件测试', () {
      blocTest<AuthBloc, AuthState>(
        '当有有效会话时应该发射AuthAuthenticated状态',
        build: () {
          final validSession = UserSession.testSession();
          final validUser = User.testUser();

          when(mockRepository.getCurrentSession())
              .thenAnswer((_) async => validSession);
          when(mockRepository.getUserInfo(userId: anyNamed('userId')))
              .thenAnswer((_) async => Right(validUser));

          return AuthBloc(
            repository: mockRepository,
            loginWithPhone: mockLoginWithPhone,
            loginWithEmail: mockLoginWithEmail,
            sendVerificationCode: mockSendVerificationCode,
          );
        },
        act: (bloc) => bloc.add(const CheckAuthStatus()),
        expect: () => [
          const AuthLoading(message: '检查登录状态...'),
          isA<AuthAuthenticated>(),
        ],
        verify: (bloc) {
          verify(mockRepository.getCurrentSession()).called(1);
          verify(mockRepository.getUserInfo(userId: anyNamed('userId')))
              .called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        '当没有会话时应该发射AuthUnauthenticated状态',
        build: () {
          when(mockRepository.getCurrentSession())
              .thenAnswer((_) async => null);

          return AuthBloc(
            repository: mockRepository,
            loginWithPhone: mockLoginWithPhone,
            loginWithEmail: mockLoginWithEmail,
            sendVerificationCode: mockSendVerificationCode,
          );
        },
        act: (bloc) => bloc.add(const CheckAuthStatus()),
        expect: () => [
          const AuthLoading(message: '检查登录状态...'),
          const AuthUnauthenticated(),
        ],
        verify: (bloc) {
          verify(mockRepository.getCurrentSession()).called(1);
          verifyNever(mockRepository.getUserInfo(userId: anyNamed('userId')));
        },
      );
    });

    group('LoginWithPhoneRequested事件测试', () {
      blocTest<AuthBloc, AuthState>(
        '手机号登录成功时应该发射AuthAuthenticated状态',
        build: () {
          final session = UserSession.testSession();
          final user = User.testUser();

          when(mockLoginWithPhone(
            phoneNumber: anyNamed('phoneNumber'),
            verificationCode: anyNamed('verificationCode'),
          )).thenAnswer((_) async => Right(session));

          when(mockRepository.getUserInfo(userId: anyNamed('userId')))
              .thenAnswer((_) async => Right(user));

          return AuthBloc(
            repository: mockRepository,
            loginWithPhone: mockLoginWithPhone,
            loginWithEmail: mockLoginWithEmail,
            sendVerificationCode: mockSendVerificationCode,
          );
        },
        act: (bloc) => bloc.add(const LoginWithPhoneRequested(
          phoneNumber: '13812345678',
          verificationCode: '123456',
        )),
        expect: () => [
          const AuthLoading(message: '正在登录...'),
          isA<AuthAuthenticated>(),
        ],
        verify: (bloc) {
          verify(mockLoginWithPhone(
            phoneNumber: '13812345678',
            verificationCode: '123456',
          )).called(1);
          verify(mockRepository.getUserInfo(userId: anyNamed('userId')))
              .called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        '手机号登录失败时应该发射AuthFailure状态',
        build: () {
          when(mockLoginWithPhone(
            phoneNumber: anyNamed('phoneNumber'),
            verificationCode: anyNamed('verificationCode'),
          )).thenAnswer((_) async => Left(AuthException(
                AuthResult.invalidCredentials,
                details: '验证码错误',
              )));

          return AuthBloc(
            repository: mockRepository,
            loginWithPhone: mockLoginWithPhone,
            loginWithEmail: mockLoginWithEmail,
            sendVerificationCode: mockSendVerificationCode,
          );
        },
        act: (bloc) => bloc.add(const LoginWithPhoneRequested(
          phoneNumber: '13812345678',
          verificationCode: '123456',
        )),
        expect: () => [
          const AuthLoading(message: '正在登录...'),
          isA<AuthFailure>(),
        ],
        verify: (bloc) {
          verify(mockLoginWithPhone(
            phoneNumber: '13812345678',
            verificationCode: '123456',
          )).called(1);
          verifyNever(mockRepository.getUserInfo(userId: anyNamed('userId')));
        },
      );
    });

    group('LoginWithEmailRequested事件测试', () {
      blocTest<AuthBloc, AuthState>(
        '邮箱登录成功时应该发射AuthAuthenticated状态',
        build: () {
          final session = UserSession.testSession();
          final user = User.testUser();

          when(mockLoginWithEmail(
            email: anyNamed('email'),
            password: anyNamed('password'),
          )).thenAnswer((_) async => Right(session));

          when(mockRepository.getUserInfo(userId: anyNamed('userId')))
              .thenAnswer((_) async => Right(user));

          return AuthBloc(
            repository: mockRepository,
            loginWithPhone: mockLoginWithPhone,
            loginWithEmail: mockLoginWithEmail,
            sendVerificationCode: mockSendVerificationCode,
          );
        },
        act: (bloc) => bloc.add(const LoginWithEmailRequested(
          email: 'test@example.com',
          password: 'password123',
        )),
        expect: () => [
          const AuthLoading(message: '正在登录...'),
          isA<AuthAuthenticated>(),
        ],
        verify: (bloc) {
          verify(mockLoginWithEmail(
            email: 'test@example.com',
            password: 'password123',
          )).called(1);
          verify(mockRepository.getUserInfo(userId: anyNamed('userId')))
              .called(1);
        },
      );
    });

    group('SendPhoneVerificationCodeRequested事件测试', () {
      blocTest<AuthBloc, AuthState>(
        '发送手机验证码成功时应该发射VerificationCodeSent状态',
        build: () {
          when(mockSendVerificationCode.sendPhoneCode(
            phoneNumber: anyNamed('phoneNumber'),
          )).thenAnswer((_) async => const Right(null));

          return AuthBloc(
            repository: mockRepository,
            loginWithPhone: mockLoginWithPhone,
            loginWithEmail: mockLoginWithEmail,
            sendVerificationCode: mockSendVerificationCode,
          );
        },
        act: (bloc) => bloc.add(const SendPhoneVerificationCodeRequested(
          phoneNumber: '13812345678',
        )),
        expect: () => [
          const AuthLoading(message: '正在发送验证码...'),
          isA<VerificationCodeSent>(),
        ],
        verify: (bloc) {
          verify(mockSendVerificationCode.sendPhoneCode(
            phoneNumber: '13812345678',
          )).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        '发送手机验证码失败时应该发射AuthFailure状态',
        build: () {
          when(mockSendVerificationCode.sendPhoneCode(
            phoneNumber: anyNamed('phoneNumber'),
          )).thenAnswer((_) async => Left(AuthException(
                AuthResult.rateLimitExceeded,
                details: '发送过于频繁',
              )));

          return AuthBloc(
            repository: mockRepository,
            loginWithPhone: mockLoginWithPhone,
            loginWithEmail: mockLoginWithEmail,
            sendVerificationCode: mockSendVerificationCode,
          );
        },
        act: (bloc) => bloc.add(const SendPhoneVerificationCodeRequested(
          phoneNumber: '13812345678',
        )),
        expect: () => [
          const AuthLoading(message: '正在发送验证码...'),
          isA<AuthFailure>(),
        ],
        verify: (bloc) {
          verify(mockSendVerificationCode.sendPhoneCode(
            phoneNumber: '13812345678',
          )).called(1);
        },
      );
    });

    group('Logout事件测试', () {
      blocTest<AuthBloc, AuthState>(
        '登出时应该清除本地数据并发射AuthUnauthenticated状态',
        build: () {
          when(mockRepository.logout()).thenAnswer((_) async {});

          return AuthBloc(
            repository: mockRepository,
            loginWithPhone: mockLoginWithPhone,
            loginWithEmail: mockLoginWithEmail,
            sendVerificationCode: mockSendVerificationCode,
          );
        },
        act: (bloc) => bloc.add(const Logout()),
        expect: () => [
          const AuthUnauthenticated(),
        ],
        verify: (bloc) {
          verify(mockRepository.logout()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        '登出失败时也应该发射AuthUnauthenticated状态',
        build: () {
          when(mockRepository.logout()).thenThrow(Exception('登出失败'));

          return AuthBloc(
            repository: mockRepository,
            loginWithPhone: mockLoginWithPhone,
            loginWithEmail: mockLoginWithEmail,
            sendVerificationCode: mockSendVerificationCode,
          );
        },
        act: (bloc) => bloc.add(const Logout()),
        expect: () => [
          const AuthUnauthenticated(),
        ],
        verify: (bloc) {
          verify(mockRepository.logout()).called(1);
        },
      );
    });

    group('ClearAuthError事件测试', () {
      blocTest<AuthBloc, AuthState>(
        '清除错误时应该从AuthFailure状态转换到AuthUnauthenticated状态',
        build: () {
          return AuthBloc(
            repository: mockRepository,
            loginWithPhone: mockLoginWithPhone,
            loginWithEmail: mockLoginWithEmail,
            sendVerificationCode: mockSendVerificationCode,
          );
        },
        seed: () => AuthFailure(
          error: AuthResult.networkError,
          details: '网络连接失败',
        ),
        act: (bloc) => bloc.add(const ClearAuthError()),
        expect: () => [
          const AuthUnauthenticated(),
        ],
      );
    });

    group('AuthReset事件测试', () {
      blocTest<AuthBloc, AuthState>(
        '重置认证状态时应该发射AuthInitial状态',
        build: () {
          return AuthBloc(
            repository: mockRepository,
            loginWithPhone: mockLoginWithPhone,
            loginWithEmail: mockLoginWithEmail,
            sendVerificationCode: mockSendVerificationCode,
          );
        },
        seed: () => AuthFailure(
          error: AuthResult.networkError,
          details: '网络连接失败',
        ),
        act: (bloc) => bloc.add(const AuthReset()),
        expect: () => [
          const AuthInitial(),
        ],
      );
    });

    group('错误处理测试', () {
      blocTest<AuthBloc, AuthState>(
        '当获取用户信息失败时应该发射AuthUnauthenticated状态',
        build: () {
          final session = UserSession.testSession();

          when(mockRepository.getCurrentSession())
              .thenAnswer((_) async => session);
          when(mockRepository.getUserInfo(userId: anyNamed('userId')))
              .thenAnswer((_) async => Left(AuthException(
                    AuthResult.serverError,
                    details: '获取用户信息失败',
                  )));

          return AuthBloc(
            repository: mockRepository,
            loginWithPhone: mockLoginWithPhone,
            loginWithEmail: mockLoginWithEmail,
            sendVerificationCode: mockSendVerificationCode,
          );
        },
        act: (bloc) => bloc.add(const CheckAuthStatus()),
        expect: () => [
          const AuthLoading(message: '检查登录状态...'),
          const AuthUnauthenticated(message: '用户信息获取失败'),
        ],
        verify: (bloc) {
          verify(mockRepository.getCurrentSession()).called(1);
          verify(mockRepository.getUserInfo(userId: anyNamed('userId')))
              .called(1);
          verify(mockRepository.logout()).called(1);
        },
      );
    });
  });
}
