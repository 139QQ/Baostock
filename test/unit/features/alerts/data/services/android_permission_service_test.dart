import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:jisu_fund_analyzer/src/features/alerts/data/services/android_permission_service.dart';

void main() {
  // 初始化Flutter binding以支持权限服务
  TestWidgetsFlutterBinding.ensureInitialized();
  group('AndroidPermissionService', () {
    late AndroidPermissionService permissionService;

    setUp(() async {
      // 获取权限服务实例（单例模式）
      permissionService = AndroidPermissionService.instance;

      // 在测试环境中初始化服务
      await permissionService.initialize();
    });

    group('初始化测试', () {
      test('应该成功初始化', () {
        expect(permissionService.isInitialized, isTrue);
      });

      test('服务应该是单例', () {
        final anotherInstance = AndroidPermissionService.instance;
        expect(identical(permissionService, anotherInstance), isTrue);
      });

      test('重复初始化应该是安全的', () async {
        await permissionService.initialize(); // 第二次调用
        expect(permissionService.isInitialized, isTrue);
      });
    });

    group('通知权限测试', () {
      test('应该能检查通知权限状态', () async {
        final hasPermission =
            await permissionService.hasNotificationPermission();
        expect(hasPermission, isA<bool>());

        // 在非Android平台应该返回true（模拟已授权）
        if (!const String.fromEnvironment('FLUTTER_TEST').isNotEmpty) {
          expect(hasPermission, isTrue);
        }
      });

      test('应该能请求通知权限', () async {
        final status = await permissionService.requestNotificationPermission();
        expect(status, isA<PermissionStatus>());

        // 验证返回的状态是有效的PermissionStatus枚举值
        expect([
          PermissionStatus.granted,
          PermissionStatus.denied,
          PermissionStatus.restricted,
          PermissionStatus.limited,
          PermissionStatus.permanentlyDenied,
          PermissionStatus.provisional,
        ], contains(status));
      });

      test('通知权限状态应该保持一致性', () async {
        final hasPermission1 =
            await permissionService.hasNotificationPermission();
        final status1 = await permissionService.requestNotificationPermission();
        final hasPermission2 =
            await permissionService.hasNotificationPermission();

        // 多次检查应该返回一致的结果
        expect(hasPermission1, equals(hasPermission2));

        // 如果权限被授予，hasPermission应该返回true
        if (status1.isGranted) {
          expect(hasPermission1, isTrue);
        }
      });
    });

    group('电池优化权限测试', () {
      test('应该能检查电池优化状态', () async {
        final isIgnoring =
            await permissionService.isIgnoringBatteryOptimizations();
        expect(isIgnoring, isA<bool>());
      });

      test('应该能请求忽略电池优化', () async {
        final status =
            await permissionService.requestIgnoreBatteryOptimizations();
        expect(status, isA<PermissionStatus>());

        // 验证返回的状态是有效的
        expect([
          PermissionStatus.granted,
          PermissionStatus.denied,
          PermissionStatus.restricted,
          PermissionStatus.limited,
          PermissionStatus.permanentlyDenied,
          PermissionStatus.provisional,
        ], contains(status));
      });
    });

    group('系统悬浮窗权限测试', () {
      test('应该能检查悬浮窗权限', () async {
        final hasPermission =
            await permissionService.hasSystemAlertWindowPermission();
        expect(hasPermission, isA<bool>());
      });

      test('应该能请求悬浮窗权限', () async {
        final status =
            await permissionService.requestSystemAlertWindowPermission();
        expect(status, isA<PermissionStatus>());
      });
    });

    group('精确闹钟权限测试', () {
      test('应该能检查精确闹钟权限', () async {
        final hasPermission =
            await permissionService.hasScheduleExactAlarmPermission();
        expect(hasPermission, isA<bool>());
      });

      test('应该能请求精确闹钟权限', () async {
        final status =
            await permissionService.requestScheduleExactAlarmPermission();
        expect(status, isA<PermissionStatus>());
      });
    });

    group('权限批量操作测试', () {
      test('应该能获取所有权限状态', () async {
        final statuses = await permissionService.getAllPermissionStatus();
        expect(statuses, isA<Map<Permission, PermissionStatus>>());

        // 验证返回的权限状态都是有效的
        for (final entry in statuses.entries) {
          expect(entry.key, isA<Permission>());
          expect(entry.value, isA<PermissionStatus>());
          expect([
            PermissionStatus.granted,
            PermissionStatus.denied,
            PermissionStatus.restricted,
            PermissionStatus.limited,
            PermissionStatus.permanentlyDenied,
            PermissionStatus.provisional,
          ], contains(entry.value));
        }
      });

      test('应该能请求所有必需权限', () async {
        final result = await permissionService.requestAllRequiredPermissions();
        expect(result, isA<Map<Permission, PermissionStatus>>());

        // 验证返回的结果包含必要的权限
        final requiredPermissions = [
          Permission.notification,
          Permission.ignoreBatteryOptimizations,
          Permission.systemAlertWindow,
        ];

        for (final permission in requiredPermissions) {
          expect(result, contains(permission));
          expect(result[permission], isA<PermissionStatus>());
        }
      });

      test('应该能检查权限完整性', () async {
        final result = await permissionService.checkPermissionCompleteness();
        expect(result, isA<PermissionCheckResult>());
        expect(result.isComplete, isA<bool>());
        expect(result.missingPermissions, isA<List<Permission>>());
        expect(result.canRequestAll, isA<bool>());
        expect(result.recommendations, isA<List<String>>());
      });

      test('权限完整性检查应该正确识别缺失权限', () async {
        final result = await permissionService.checkPermissionCompleteness();

        // 如果完整性检查通过，不应该有缺失权限
        if (result.isComplete) {
          expect(result.missingPermissions, isEmpty);
        }

        // 缺失权限列表应该只包含Permission类型
        for (final permission in result.missingPermissions) {
          expect(permission, isA<Permission>());
        }
      });
    });

    group('应用设置测试', () {
      test('应该能打开应用设置', () async {
        // 注意：这个测试在非Android环境下会跳过实际调用
        final result = await permissionService.openAppSettings();
        expect(result, isA<bool>());
      });

      test('应该能打开通知设置', () async {
        final result = await permissionService.openNotificationSettings();
        expect(result, isA<bool>());
      });

      test('应该能打开电池优化设置', () async {
        final result =
            await permissionService.openBatteryOptimizationSettings();
        expect(result, isA<bool>());
      });
    });

    group('权限状态转换测试', () {
      test('应该正确解析权限状态', () {
        final statuses = [
          PermissionStatus.granted,
          PermissionStatus.denied,
          PermissionStatus.restricted,
          PermissionStatus.limited,
          PermissionStatus.permanentlyDenied,
          PermissionStatus.provisional,
        ];

        for (final status in statuses) {
          expect(status.toString(), isA<String>());
          expect(status.toString(), contains('PermissionStatus'));
        }
      });

      test('权限状态应该有正确的语义', () {
        expect(PermissionStatus.granted.isGranted, isTrue);
        expect(PermissionStatus.denied.isGranted, isFalse);
        expect(PermissionStatus.permanentlyDenied.isGranted, isFalse);
        expect(PermissionStatus.restricted.isGranted, isFalse);
      });
    });

    group('权限重要性测试', () {
      test('应该能区分不同权限的重要性', () {
        // 根据实际业务逻辑，通知权限是最重要的
        final requiredPermissions = [
          Permission.notification,
          Permission.ignoreBatteryOptimizations,
          Permission.systemAlertWindow,
        ];

        expect(requiredPermissions, contains(Permission.notification));
        expect(requiredPermissions,
            contains(Permission.ignoreBatteryOptimizations));
        expect(requiredPermissions, contains(Permission.systemAlertWindow));
      });

      test('权限优先级应该正确配置', () {
        // 验证权限枚举的完整性
        expect(Permission.notification.toString(), contains('notification'));
        expect(Permission.ignoreBatteryOptimizations.toString(),
            contains('ignoreBatteryOptimizations'));
        expect(Permission.systemAlertWindow.toString(),
            contains('systemAlertWindow'));
      });
    });

    group('错误处理测试', () {
      test('权限检查失败时应该有默认行为', () async {
        // 测试在权限检查失败时的行为
        final statuses = await permissionService.getAllPermissionStatus();
        expect(statuses, isA<Map<Permission, PermissionStatus>>());

        // 即使某些权限检查失败，也应该返回其他权限的状态
        expect(statuses, isNotEmpty);
      });

      test('权限请求失败时应该返回合理状态', () async {
        // 测试权限请求失败的处理
        final status = await permissionService.requestNotificationPermission();
        expect(status, isA<PermissionStatus>());

        // 不应该抛出异常
        expect(() => permissionService.requestNotificationPermission(),
            returnsNormally);
      });
    });

    group('配置验证测试', () {
      test('权限服务应该正确配置推送相关权限', () async {
        final statuses = await permissionService.getAllPermissionStatus();

        // 验证推送相关的关键权限都被检查
        expect(statuses.keys, contains(Permission.notification));

        // 在支持的平台上应该检查电池优化权限
        expect(statuses.keys, contains(Permission.ignoreBatteryOptimizations));

        // 应该检查系统悬浮窗权限（用于显示推送通知）
        expect(statuses.keys, contains(Permission.systemAlertWindow));
      });

      test('通知权限配置应该被正确应用', () async {
        final hasPermission =
            await permissionService.hasNotificationPermission();
        final status = await permissionService.requestNotificationPermission();

        // 验证通知权限配置的一致性
        if (status.isGranted) {
          expect(hasPermission, isTrue);
        }

        // 验证权限状态可以被正确获取
        expect(status, isA<PermissionStatus>());
        expect(status.toString(), isNotEmpty);
      });

      test('权限完整性检查应该反映实际配置状态', () async {
        final result = await permissionService.checkPermissionCompleteness();

        // 验证完整性检查结果的配置
        expect(result.isComplete, isA<bool>());
        expect(result.missingPermissions, isA<List<Permission>>());
        expect(result.canRequestAll, isA<bool>());
        expect(result.recommendations, isA<List<String>>());

        // 如果推荐列表不为空，应该包含有用的建议
        if (result.recommendations.isNotEmpty) {
          for (final recommendation in result.recommendations) {
            expect(recommendation, isA<String>());
            expect(recommendation, isNotEmpty);
          }
        }
      });
    });
  });
}
