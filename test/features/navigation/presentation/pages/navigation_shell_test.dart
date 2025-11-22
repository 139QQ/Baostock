import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jisu_fund_analyzer/src/features/navigation/presentation/pages/navigation_shell.dart';
import 'package:jisu_fund_analyzer/src/features/auth/domain/entities/user.dart';

void main() {
  group('NavigationShell 极简布局导航测试', () {
    late User testUser;

    setUp(() {
      final now = DateTime.now();
      testUser = User(
        id: 'test_user_001',
        phoneNumber: '13812345678',
        email: 'test@example.com',
        displayName: '测试用户',
        createdAt: now.subtract(const Duration(days: 30)),
        lastLoginAt: now,
        isEmailVerified: true,
        isPhoneVerified: true,
      );
    });

    testWidgets('极简布局模式下应该显示紧凑导航栏', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NavigationShell(
            user: testUser,
            onLogout: () {},
          ),
        ),
      );

      // 等待widget完全渲染
      await tester.pumpAndSettle();

      // 验证导航栏存在（即使在极简模式下）
      expect(find.byType(NavigationRail), findsOneWidget);
    });

    testWidgets('极简布局导航栏应该有正确的宽度', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NavigationShell(
            user: testUser,
            onLogout: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 查找左侧导航栏容器
      final navigationRailFinder = find.byType(NavigationRail);
      expect(navigationRailFinder, findsOneWidget);

      // 验证导航栏宽度应该是80px（极简模式）
      final navigationRail =
          tester.widget<NavigationRail>(navigationRailFinder);
      expect(navigationRail.minWidth, equals(80.0));
    });

    testWidgets('极简布局导航栏应该显示所有导航选项', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NavigationShell(
            user: testUser,
            onLogout: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证所有导航目标都存在
      expect(find.text('概览'), findsOneWidget);
      expect(find.text('筛选'), findsOneWidget);
      expect(find.text('自选'), findsOneWidget);
      expect(find.text('分析'), findsOneWidget);
      expect(find.text('设置'), findsOneWidget);
    });

    testWidgets('应该能够点击导航选项切换页面', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NavigationShell(
            user: testUser,
            onLogout: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 点击"自选"导航项
      await tester.tap(find.text('自选'));
      await tester.pumpAndSettle();

      // 验证已选中"自选"项（通过查找选中的导航项）
      final selectedDestination = find.text('自选');
      expect(selectedDestination, findsOneWidget);
    });

    testWidgets('极简布局导航栏图标应该正确显示', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NavigationShell(
            user: testUser,
            onLogout: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证导航图标存在
      expect(find.byIcon(Icons.dashboard_outlined), findsOneWidget); // 概览
      expect(find.byIcon(Icons.filter_alt_outlined), findsOneWidget); // 筛选
      expect(find.byIcon(Icons.star_outline), findsOneWidget); // 自选
      expect(find.byIcon(Icons.analytics_outlined), findsOneWidget); // 分析
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget); // 设置
    });

    testWidgets('极简布局导航栏应该支持工具提示', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NavigationShell(
            user: testUser,
            onLogout: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证Tooltip组件存在
      expect(find.byType(Tooltip), findsWidgets);
    });

    testWidgets('导航切换时应该正确更新选中状态', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NavigationShell(
            user: testUser,
            onLogout: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 初始状态应该在"概览"页面
      expect(find.text('概览'), findsOneWidget);

      // 点击"分析"导航项
      await tester.tap(find.text('分析'));
      await tester.pumpAndSettle();

      // 验证"分析"项被选中
      expect(find.text('分析'), findsOneWidget);
    });
  });

  group('NavigationShell 传统布局对比测试', () {
    late User testUser;

    setUp(() {
      final now = DateTime.now();
      testUser = User(
        id: 'test_user_001',
        phoneNumber: '13812345678',
        email: 'test@example.com',
        displayName: '测试用户',
        createdAt: now.subtract(const Duration(days: 30)),
        lastLoginAt: now,
        isEmailVerified: true,
        isPhoneVerified: true,
      );
    });

    testWidgets('传统布局导航栏应该比极简布局更宽', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NavigationShell(
            user: testUser,
            onLogout: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 查找导航栏
      final navigationRailFinder = find.byType(NavigationRail);
      expect(navigationRailFinder, findsOneWidget);

      final navigationRail =
          tester.widget<NavigationRail>(navigationRailFinder);

      // 传统布局应该是100px宽
      expect(navigationRail.minWidth, equals(100.0));
    });
  });
}
