import 'package:flutter_test/flutter_test.dart';
import 'package:jisu_fund_analyzer/src/features/auth/domain/entities/user.dart';

void main() {
  group('User实体测试', () {
    test('应该正确创建User实例', () {
      // Arrange
      final user = User(
        id: 'test_user_001',
        phoneNumber: '13812345678',
        email: 'test@example.com',
        displayName: '测试用户',
        avatarUrl: 'https://example.com/avatar.jpg',
        createdAt: DateTime(2025, 1, 1),
        lastLoginAt: DateTime(2025, 1, 15, 10, 30),
        isEmailVerified: true,
        isPhoneVerified: true,
      );

      // Assert
      expect(user.id, 'test_user_001');
      expect(user.phoneNumber, '13812345678');
      expect(user.email, 'test@example.com');
      expect(user.displayName, '测试用户');
      expect(user.avatarUrl, 'https://example.com/avatar.jpg');
      expect(user.isEmailVerified, true);
      expect(user.isPhoneVerified, true);
    });

    test('应该正确验证手机号格式', () {
      // Arrange
      final validUser = User(
        id: 'test_user_001',
        phoneNumber: '13812345678',
        displayName: '测试用户',
        createdAt: DateTime(2025, 1, 1),
        lastLoginAt: DateTime(2025, 1, 15, 10, 30),
        isEmailVerified: false,
        isPhoneVerified: true,
      );

      final invalidUser = User(
        id: 'test_user_002',
        phoneNumber: '12345678901',
        displayName: '测试用户2',
        createdAt: DateTime(2025, 1, 1),
        lastLoginAt: DateTime(2025, 1, 15, 10, 30),
        isEmailVerified: false,
        isPhoneVerified: false,
      );

      // Assert
      expect(validUser.isPhoneNumberValid, true);
      expect(invalidUser.isPhoneNumberValid, false);
    });

    test('应该正确验证邮箱格式', () {
      // Arrange
      final validUser = User(
        id: 'test_user_001',
        phoneNumber: '13812345678',
        email: 'test@example.com',
        displayName: '测试用户',
        createdAt: DateTime(2025, 1, 1),
        lastLoginAt: DateTime(2025, 1, 15, 10, 30),
        isEmailVerified: true,
        isPhoneVerified: false,
      );

      final invalidUser = User(
        id: 'test_user_002',
        phoneNumber: '13812345679',
        email: 'invalid-email',
        displayName: '测试用户2',
        createdAt: DateTime(2025, 1, 1),
        lastLoginAt: DateTime(2025, 1, 15, 10, 30),
        isEmailVerified: false,
        isPhoneVerified: false,
      );

      final noEmailUser = User(
        id: 'test_user_003',
        phoneNumber: '13812345680',
        displayName: '测试用户3',
        createdAt: DateTime(2025, 1, 1),
        lastLoginAt: DateTime(2025, 1, 15, 10, 30),
        isEmailVerified: false,
        isPhoneVerified: false,
      );

      // Assert
      expect(validUser.isEmailValid, true);
      expect(invalidUser.isEmailValid, false);
      expect(noEmailUser.isEmailValid, false);
    });

    test('应该正确获取显示文本', () {
      // Arrange
      final userWithDisplayName = User(
        id: 'test_user_001',
        phoneNumber: '13812345678',
        displayName: '测试用户',
        createdAt: DateTime(2025, 1, 1),
        lastLoginAt: DateTime(2025, 1, 15, 10, 30),
        isEmailVerified: false,
        isPhoneVerified: true,
      );

      final userWithoutDisplayName = User(
        id: 'test_user_002',
        phoneNumber: '13987654321',
        displayName: '',
        createdAt: DateTime(2025, 1, 1),
        lastLoginAt: DateTime(2025, 1, 15, 10, 30),
        isEmailVerified: false,
        isPhoneVerified: true,
      );

      // Assert
      expect(userWithDisplayName.displayText, '测试用户');
      expect(userWithoutDisplayName.displayText, '139****4321');
    });

    test('应该正确创建User副本', () {
      // Arrange
      final originalUser = User(
        id: 'test_user_001',
        phoneNumber: '13812345678',
        email: 'test@example.com',
        displayName: '测试用户',
        createdAt: DateTime(2025, 1, 1),
        lastLoginAt: DateTime(2025, 1, 15, 10, 30),
        isEmailVerified: true,
        isPhoneVerified: true,
      );

      // Act
      final updatedUser = originalUser.copyWith(
        displayName: '更新后的用户名',
        isEmailVerified: false,
      );

      // Assert
      expect(updatedUser.id, originalUser.id);
      expect(updatedUser.phoneNumber, originalUser.phoneNumber);
      expect(updatedUser.displayName, '更新后的用户名');
      expect(updatedUser.email, originalUser.email);
      expect(updatedUser.isEmailVerified, false);
      expect(updatedUser.isPhoneVerified, originalUser.isPhoneVerified);
    });

    test('应该正确实现相等性比较', () {
      // Arrange
      final user1 = User(
        id: 'test_user_001',
        phoneNumber: '13812345678',
        displayName: '测试用户',
        createdAt: DateTime(2025, 1, 1),
        lastLoginAt: DateTime(2025, 1, 15, 10, 30),
        isEmailVerified: false,
        isPhoneVerified: true,
      );

      final user2 = User(
        id: 'test_user_001',
        phoneNumber: '13812345678',
        displayName: '测试用户',
        createdAt: DateTime(2025, 1, 1),
        lastLoginAt: DateTime(2025, 1, 15, 10, 30),
        isEmailVerified: false,
        isPhoneVerified: true,
      );

      final user3 = User(
        id: 'test_user_002',
        phoneNumber: '13812345678',
        displayName: '测试用户',
        createdAt: DateTime(2025, 1, 1),
        lastLoginAt: DateTime(2025, 1, 15, 10, 30),
        isEmailVerified: false,
        isPhoneVerified: true,
      );

      // Assert
      expect(user1, equals(user2));
      expect(user1, isNot(equals(user3)));
    });

    test('应该正确转换为字符串', () {
      // Arrange
      final user = User(
        id: 'test_user_001',
        phoneNumber: '13812345678',
        email: 'test@example.com',
        displayName: '测试用户',
        createdAt: DateTime(2025, 1, 1),
        lastLoginAt: DateTime(2025, 1, 15, 10, 30),
        isEmailVerified: true,
        isPhoneVerified: true,
      );

      // Act
      final userString = user.toString();

      // Assert
      expect(userString, contains('test_user_001'));
      expect(userString, contains('测试用户'));
      expect(userString, contains('13812345678'));
      expect(userString, contains('test@example.com'));
    });

    test('应该正确创建测试用户', () {
      // Act
      final testUser = User.testUser();

      // Assert
      expect(testUser.id, 'test_user_001');
      expect(testUser.phoneNumber, '13812345678');
      expect(testUser.email, 'test@example.com');
      expect(testUser.displayName, '测试用户');
      expect(testUser.isEmailVerified, true);
      expect(testUser.isPhoneVerified, true);
    });

    test('应该正确处理自定义测试用户', () {
      // Act
      final customTestUser = User.testUser(
        id: 'custom_user_001',
        phoneNumber: '15912345678',
        email: 'custom@test.com',
        displayName: '自定义用户',
      );

      // Assert
      expect(customTestUser.id, 'custom_user_001');
      expect(customTestUser.phoneNumber, '15912345678');
      expect(customTestUser.email, 'custom@test.com');
      expect(customTestUser.displayName, '自定义用户');
    });
  });

  group('User边界条件测试', () {
    test('应该正确处理空显示名称', () {
      // Arrange
      final user = User(
        id: 'test_user_001',
        phoneNumber: '13812345678',
        displayName: '',
        createdAt: DateTime(2025, 1, 1),
        lastLoginAt: DateTime(2025, 1, 15, 10, 30),
        isEmailVerified: false,
        isPhoneVerified: true,
      );

      // Assert
      expect(user.displayText, '138****5678');
    });

    test('应该正确处理短手机号', () {
      // Arrange
      final user = User(
        id: 'test_user_001',
        phoneNumber: '138',
        displayName: '',
        createdAt: DateTime(2025, 1, 1),
        lastLoginAt: DateTime(2025, 1, 15, 10, 30),
        isEmailVerified: false,
        isPhoneVerified: false,
      );

      // Assert
      expect(user.displayText, '138');
    });

    test('应该正确验证各种手机号格式', () {
      final testCases = {
        '13812345678': true, // 正常手机号
        '15912345678': true, // 正常手机号
        '18812345678': true, // 正常手机号
        '12345678901': false, // 无效开头
        '1381234567': false, // 位数不够
        '138123456789': false, // 位数过多
        'abc12345678': false, // 包含字母
      };

      for (final entry in testCases.entries) {
        // Arrange
        final user = User(
          id: 'test_user',
          phoneNumber: entry.key,
          displayName: '测试',
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          isEmailVerified: false,
          isPhoneVerified: false,
        );

        // Assert
        expect(user.isPhoneNumberValid, entry.value,
            reason: '手机号 ${entry.key} 应该${entry.value ? "有效" : "无效"}');
      }
    });

    test('应该正确验证各种邮箱格式', () {
      final testCases = {
        'test@example.com': true,
        'user.name@domain.co.uk': true,
        'user+tag@example.org': false, // 当前正则不支持+号
        'user123@test-domain.com': true,
        'invalid-email': false,
        '@example.com': false,
        'user@': false,
        'user..name@example.com': true, // 当前正则允许连续的点
        'user@.example.com': false,
      };

      for (final entry in testCases.entries) {
        // Arrange
        final user = User(
          id: 'test_user',
          phoneNumber: '13812345678',
          email: entry.key,
          displayName: '测试',
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          isEmailVerified: false,
          isPhoneVerified: false,
        );

        // Assert
        expect(user.isEmailValid, entry.value,
            reason: '邮箱 ${entry.key} 应该${entry.value ? "有效" : "无效"}');
      }
    });
  });
}
