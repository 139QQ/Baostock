import 'package:flutter_test/flutter_test.dart';
import 'package:jisu_fund_analyzer/src/features/auth/domain/entities/user.dart';
import 'package:jisu_fund_analyzer/src/features/auth/domain/entities/user_session.dart';

void main() {
  group('User Entity Tests', () {
    test('创建测试用户应该正确', () {
      // Act
      final user = User.testUser(
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
      final validUser = User.testUser(phoneNumber: '13800138000');
      final invalidUser = User.testUser(phoneNumber: '12345678901');

      // Assert
      expect(validUser.isPhoneNumberValid, true);
      expect(invalidUser.isPhoneNumberValid, false);
    });

    test('邮箱验证应该正确', () {
      // Arrange
      final validUser = User.testUser(email: 'test@example.com');
      final invalidUser = User.testUser(email: 'invalid-email');

      // Assert
      expect(validUser.isEmailValid, true);
      expect(invalidUser.isEmailValid, false);
    });

    test('显示文本应该正确', () {
      // Arrange
      final userWithDisplayName = User.testUser(displayName: '张三');
      final userWithoutDisplayName = User.testUser(
        phoneNumber: '13800138000',
        displayName: '', // 空的显示名称
      );

      // Assert
      expect(userWithDisplayName.displayText, '张三');
      expect(userWithoutDisplayName.displayText, '138****8000');
    });

    test('用户信息复制应该正确', () {
      // Arrange
      final originalUser = User.testUser(displayName: '原名称');

      // Act
      final updatedUser = originalUser.copyWith(displayName: '新名称');

      // Assert
      expect(updatedUser.displayName, '新名称');
      expect(updatedUser.id, originalUser.id);
      expect(updatedUser.phoneNumber, originalUser.phoneNumber);
    });
  });

  group('UserSession Entity Tests', () {
    test('创建会话应该正确', () {
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

    test('令牌即将过期检查应该正确', () {
      // Act
      final expiringSoonSession = UserSession.testSession(
        userId: 'test_001',
        expiresIn: const Duration(minutes: 3), // 3分钟后过期
      );
      final notExpiringSoonSession = UserSession.testSession(
        userId: 'test_001',
        expiresIn: const Duration(minutes: 10), // 10分钟后过期
      );

      // Assert
      expect(expiringSoonSession.isExpiringSoon, true);
      expect(notExpiringSoonSession.isExpiringSoon, false);
    });

    test('授权头格式应该正确', () {
      // Act
      final session = UserSession.testSession();

      // Assert
      expect(session.authorizationHeader, startsWith('Bearer '));
      expect(session.authorizationHeader, contains(' '));
    });

    test('会话复制应该正确', () {
      // Arrange
      final originalSession = UserSession.testSession();

      // Act
      final updatedSession = originalSession.copyWith(isValid: false);

      // Assert
      expect(updatedSession.isValid, false);
      expect(updatedSession.userId, originalSession.userId);
      expect(updatedSession.accessToken, originalSession.accessToken);
    });

    test('会话延长应该正确', () {
      // Arrange
      final originalSession = UserSession.testSession(
        userId: 'test_001',
        expiresIn: const Duration(hours: 1),
      );
      final originalExpiry = originalSession.expiresAt;

      // Act
      final extendedSession = originalSession.extend(const Duration(hours: 1));

      // Assert
      expect(extendedSession.expiresAt.isAfter(originalExpiry), true);
      expect(extendedSession.userId, originalSession.userId);
    });

    test('更新最后活跃时间应该正确', () {
      // Arrange
      final originalSession = UserSession.testSession();
      final originalLastActive = originalSession.lastActiveAt;

      // Act
      // 等待一小段时间确保时间不同
      Future.delayed(const Duration(milliseconds: 10)).then((_) {
        final updatedSession = originalSession.updateLastActive();

        // Assert
        expect(updatedSession.lastActiveAt.isAfter(originalLastActive), true);
        expect(updatedSession.userId, originalSession.userId);
      });
    });

    test('会话失效应该正确', () {
      // Arrange
      final originalSession = UserSession.testSession();

      // Act
      final invalidatedSession = originalSession.invalidate();

      // Assert
      expect(invalidatedSession.isValid, false);
      expect(invalidatedSession.userId, originalSession.userId);
    });
  });

  group('用户会话集成测试', () {
    test('用户和会话应该可以正常配合使用', () {
      // Arrange
      final user = User.testUser(
        id: 'user_001',
        displayName: '测试用户',
      );
      final session = UserSession.testSession(
        userId: user.id,
        expiresIn: const Duration(hours: 1),
      );

      // Assert
      expect(session.userId, user.id);
      expect(user.isValidSession(session), true); // 假设有这个方法
      expect(session.isExpired, false);
      expect(user.displayText, '测试用户');
    });
  });
}

/// 扩展User类以支持会话验证
extension UserValidation on User {
  /// 验证会话是否属于当前用户且有效
  bool isValidSession(UserSession session) {
    return session.userId == id && session.isValid && !session.isExpired;
  }
}
