import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:jisu_fund_analyzer/src/features/auth/domain/entities/user.dart';
import 'package:jisu_fund_analyzer/src/features/auth/domain/entities/user_session.dart';
import 'package:jisu_fund_analyzer/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:jisu_fund_analyzer/src/features/auth/domain/usecases/login_with_phone.dart';
import 'package:jisu_fund_analyzer/src/features/auth/domain/usecases/login_with_email.dart';
import 'package:jisu_fund_analyzer/src/features/auth/domain/usecases/send_verification_code.dart';
import 'package:jisu_fund_analyzer/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:jisu_fund_analyzer/src/features/auth/presentation/bloc/auth_event.dart';
import 'package:jisu_fund_analyzer/src/features/auth/presentation/bloc/auth_state.dart';

// 生成Mock类
@GenerateMocks([
  AuthRepository,
  LoginWithPhone,
  LoginWithEmail,
  SendVerificationCode,
])
import 'auth_test.mocks.dart';

void main() {
  group('AuthBloc Tests', () {
    late MockAuthRepository mockAuthRepository;
    late MockLoginWithPhone mockLoginWithPhone;
    late MockLoginWithEmail mockLoginWithEmail;
    late MockSendVerificationCode mockSendVerificationCode;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      mockLoginWithPhone = MockLoginWithPhone();
      mockLoginWithEmail = MockLoginWithEmail();
      mockSendVerificationCode = MockSendVerificationCode();
    });

    test('初始状态应该是 AuthInitial', () {
      // Arrange
      final authBloc = AuthBloc(
        repository: mockAuthRepository,
        loginWithPhone: mockLoginWithPhone,
        loginWithEmail: mockLoginWithEmail,
        sendVerificationCode: mockSendVerificationCode,
      );

      // Assert
      expect(authBloc.state, isA<AuthInitial>());

      // Cleanup
      authBloc.close();
    });

    blocTest<AuthBloc, AuthState>(
      '发送验证码成功时应该发出 VerificationCodeSent 状态',
      build: () {
        when(mockSendVerificationCode.sendPhoneCode(
                phoneNumber: anyNamed('phoneNumber')))
            .thenAnswer((_) async => const Right(null));

        return AuthBloc(
          repository: mockAuthRepository,
          loginWithPhone: mockLoginWithPhone,
          loginWithEmail: mockLoginWithEmail,
          sendVerificationCode: mockSendVerificationCode,
        );
      },
      act: (bloc) => bloc.add(
        const SendPhoneVerificationCodeRequested(phoneNumber: '13800138000'),
      ),
      expect: () => [
        const AuthLoading(message: '正在发送验证码...'),
        const VerificationCodeSent(
          recipient: '13800138000',
          type: VerificationCodeType.phone,
          cooldownSeconds: 60,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      '手机号登录成功时应该发出 AuthAuthenticated 状态',
      build: () {
        final testSession = UserSession.testSession();
        final testUser = User.testUser();

        when(mockLoginWithPhone(
          phoneNumber: anyNamed('phoneNumber'),
          verificationCode: anyNamed('verificationCode'),
        )).thenAnswer((_) async => Right(testSession));

        when(mockAuthRepository.getUserInfo(userId: anyNamed('userId')))
            .thenAnswer((_) async => Right(testUser));

        return AuthBloc(
          repository: mockAuthRepository,
          loginWithPhone: mockLoginWithPhone,
          loginWithEmail: mockLoginWithEmail,
          sendVerificationCode: mockSendVerificationCode,
        );
      },
      act: (bloc) => bloc.add(
        const LoginWithPhoneRequested(
          phoneNumber: '13800138000',
          verificationCode: '123456',
        ),
      ),
      expect: () => [
        const AuthLoading(message: '正在登录...'),
        isA<AuthAuthenticated>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      '邮箱登录成功时应该发出 AuthAuthenticated 状态',
      build: () {
        final testSession = UserSession.testSession();
        final testUser = User.testUser();

        when(mockLoginWithEmail(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenAnswer((_) async => Right(testSession));

        when(mockAuthRepository.getUserInfo(userId: anyNamed('userId')))
            .thenAnswer((_) async => Right(testUser));

        return AuthBloc(
          repository: mockAuthRepository,
          loginWithPhone: mockLoginWithPhone,
          loginWithEmail: mockLoginWithEmail,
          sendVerificationCode: mockSendVerificationCode,
        );
      },
      act: (bloc) => bloc.add(
        const LoginWithEmailRequested(
          email: 'test@example.com',
          password: 'password123',
        ),
      ),
      expect: () => [
        const AuthLoading(message: '正在登录...'),
        isA<AuthAuthenticated>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      '登录失败时应该发出 AuthFailure 状态',
      build: () {
        when(mockLoginWithPhone(
          phoneNumber: anyNamed('phoneNumber'),
          verificationCode: anyNamed('verificationCode'),
        )).thenAnswer((_) async => Left(AuthError.networkError()));

        return AuthBloc(
          repository: mockAuthRepository,
          loginWithPhone: mockLoginWithPhone,
          loginWithEmail: mockLoginWithEmail,
          sendVerificationCode: mockSendVerificationCode,
        );
      },
      act: (bloc) => bloc.add(
        const LoginWithPhoneRequested(
          phoneNumber: '13800138000',
          verificationCode: '123456',
        ),
      ),
      expect: () => [
        const AuthLoading(message: '正在登录...'),
        isA<AuthFailure>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      '登出时应该发出 AuthUnauthenticated 状态',
      build: () {
        when(mockAuthRepository.logout()).thenAnswer((_) async {});

        return AuthBloc(
          repository: mockAuthRepository,
          loginWithPhone: mockLoginWithPhone,
          loginWithEmail: mockLoginWithEmail,
          sendVerificationCode: mockSendVerificationCode,
        );
      },
      act: (bloc) => bloc.add(const Logout()),
      expect: () => [
        const AuthUnauthenticated(),
      ],
    );
  });

  group('User Entity Tests', () {
    test('创建测试用户应该正确', () {
      // Act
      const user = User.testUser(
        id: 'test_001',
        phoneNumber: '13912345678',
        email: 'test@example.com',
        displayName: '测试用户',
      );

      // Assert
      expect(user.id, 'test_001');
      expect(user.phoneNumber, '13912345678');
      expect(user.email, 'test@example.com');
      expect(user.displayName, '测试用户');
      expect(user.isPhoneVerified, true);
      expect(user.isEmailVerified, true);
    });

    test('手机号验证应该正确', () {
      // Arrange
      const validUser = User.testUser(phoneNumber: '13800138000');
      const invalidUser = User.testUser(phoneNumber: '12345678901');

      // Assert
      expect(validUser.isPhoneNumberValid, true);
      expect(invalidUser.isPhoneNumberValid, false);
    });

    test('显示文本应该正确', () {
      // Arrange
      const userWithDisplayName = User.testUser(displayName: '张三');
      const userWithoutDisplayName = User.testUser(phoneNumber: '13800138000');

      // Assert
      expect(userWithDisplayName.displayText, '张三');
      expect(userWithoutDisplayName.displayText, '138****8000');
    });
  });

  group('UserSession Entity Tests', () {
    test('创建测试会话应该正确', () {
      // Act
      final session = UserSession.testSession(
        userId: 'test_001',
        expiresIn: const Duration(hours: 2),
      );

      // Assert
      expect(session.userId, 'test_001');
      expect(session.isValid, true);
      expect(session.isExpired, false);
      expect(session.tokenType, 'Bearer');
    });

    test('令牌过期检查应该正确', () {
      // Act
      final expiredSession = UserSession.testSession(
        userId: 'test_001',
        expiresIn: const Duration(seconds: -1), // 已过期
      );
      final validSession = UserSession.testSession(
        userId: 'test_001',
        expiresIn: const Duration(hours: 1), // 有效
      );

      // Assert
      expect(expiredSession.isExpired, true);
      expect(validSession.isExpired, false);
    });

    test('授权头格式应该正确', () {
      // Act
      final session = UserSession.testSession();

      // Assert
      expect(session.authorizationHeader, startsWith('Bearer '));
    });
  });
}

/// 模拟认证错误类
class AuthError {
  final String message;
  final AuthResult result;

  AuthError({required this.message, required this.result});

  factory AuthError.networkError() => AuthError(
        message: '网络连接失败',
        result: AuthResult.networkError,
      );

  factory AuthError.invalidCredentials() => AuthError(
        message: '用户名或密码错误',
        result: AuthResult.invalidCredentials,
      );
}

/// 模拟认证结果类
class AuthResult {
  final String message;

  const AuthResult._(this.message);

  static const AuthResult networkError = AuthResult._('网络错误');
  static const AuthResult invalidCredentials = AuthResult._('凭据无效');
  static const AuthResult tokenInvalid = AuthResult._('令牌无效');
}

/// 模拟验证码类型枚举
enum VerificationCodeType {
  phone,
  email,
}

/// 扩展方法用于处理Either类型（简化版本）
extension EitherExtension<L, R> on Future<Either<L, R>> {
  Future<void> then(void Function(R) callback) async {
    final either = await this;
    either.fold((l) {}, callback);
  }
}

/// 简化的Either类
class Either<L, R> {
  final L? left;
  final R? right;

  Either({this.left, this.right}) : assert(left == null || right == null);

  bool get isLeft => left != null;
  bool get isRight => right != null;

  T fold<T>(T Function(L) ifLeft, T Function(R) ifRight) {
    if (isLeft) return ifLeft(left as L);
    return ifRight(right as R);
  }
}

/// Right构造函数
Either<L, R> Right<L, R>(R value) => Either(right: value);

/// Left构造函数
Either<L, R> Left<L, R>(L value) => Either(left: value);
