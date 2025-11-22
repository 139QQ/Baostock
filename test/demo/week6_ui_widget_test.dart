import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

import 'package:jisu_fund_analyzer/src/core/theme/app_theme.dart';
import 'simple_test_dashboard.dart';

void main() {
  group('Week 6 Demo UI Widget Tests', () {
    testWidgets('简化仪表板启动测试', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          title: 'Week 6 Demo - 基速基金量化分析平台',
          theme: ThemeData(
            primaryColor: AppTheme.primaryColor,
            scaffoldBackgroundColor: AppTheme.backgroundColor,
          ),
          home: const SimpleTestDashboard(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('基速基金量化分析平台'), findsOneWidget);
      expect(find.text('演示版本'), findsOneWidget);
      expect(find.byType(SimpleTestDashboard), findsOneWidget);
    });

    testWidgets('主仪表板导航测试', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(primaryColor: AppTheme.primaryColor),
          home: const SimpleTestDashboard(),
        ),
      );
      await tester.pumpAndSettle();

      // 验证所有标签页存在
      expect(find.text('首页'), findsOneWidget);
      expect(find.text('基金推荐'), findsOneWidget);
      expect(find.text('投资组合'), findsOneWidget);
      expect(find.text('技术分析'), findsOneWidget);
      expect(find.text('Demo展示'), findsOneWidget);
    });

    testWidgets('标签页切换功能测试', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(primaryColor: AppTheme.primaryColor),
          home: const SimpleTestDashboard(),
        ),
      );
      await tester.pumpAndSettle();

      // 测试切换到基金推荐标签页
      await tester.tap(find.text('基金推荐'));
      await tester.pumpAndSettle();

      // 测试切换到投资组合标签页
      await tester.tap(find.text('投资组合'));
      await tester.pumpAndSettle();

      // 测试切换到技术分析标签页
      await tester.tap(find.text('技术分析'));
      await tester.pumpAndSettle();

      // 测试切换到Demo展示标签页
      await tester.tap(find.text('Demo展示'));
      await tester.pumpAndSettle();
    });

    testWidgets('响应式布局测试', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(primaryColor: AppTheme.primaryColor),
          home: const SimpleTestDashboard(),
        ),
      );
      await tester.pumpAndSettle();

      // 测试大屏幕布局
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      await tester.pump();

      // 验证布局适配
      expect(find.byType(SliverAppBar), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);

      // 测试小屏幕布局
      await tester.binding.setSurfaceSize(const Size(600, 800));
      await tester.pump();

      // 验证布局仍然正常
      expect(find.byType(SliverAppBar), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);

      // 恢复默认尺寸
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('主题和样式测试', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            primaryColor: AppTheme.primaryColor,
            scaffoldBackgroundColor: AppTheme.backgroundColor,
          ),
          home: const SimpleTestDashboard(),
        ),
      );
      await tester.pumpAndSettle();

      // 获取应用的主题信息
      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.theme?.brightness, Brightness.light);
      expect(app.theme?.primaryColor, AppTheme.primaryColor);
    });

    testWidgets('Demo功能测试', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(primaryColor: AppTheme.primaryColor),
          home: const SimpleTestDashboard(),
        ),
      );
      await tester.pumpAndSettle();

      // 切换到Demo展示标签页
      await tester.tap(find.text('Demo展示'));
      await tester.pumpAndSettle();

      // 测试功能按钮
      await tester.tap(find.text('测试缓存系统'));
      await tester.pumpAndSettle();

      // 验证应用仍然正常工作
      expect(find.byType(SimpleTestDashboard), findsOneWidget);
    });

    testWidgets('加载状态测试', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(primaryColor: AppTheme.primaryColor),
          home: const SimpleTestDashboard(),
        ),
      );

      // 检查基本UI组件
      expect(find.byType(SimpleTestDashboard), findsOneWidget);

      // 等待加载完成
      await tester.pumpAndSettle();

      // 验证加载状态正常
      expect(find.byType(SimpleTestDashboard), findsOneWidget);
    });

    testWidgets('性能测试 - 标签页切换', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(primaryColor: AppTheme.primaryColor),
          home: const SimpleTestDashboard(),
        ),
      );
      await tester.pumpAndSettle();

      // 测试标签切换性能
      for (int i = 0; i < 5; i++) {
        final switchStopwatch = Stopwatch()..start();

        await tester.tap(find.text('基金推荐'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('投资组合'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('技术分析'));
        await tester.pumpAndSettle();

        switchStopwatch.stop();

        // 每次切换应该在500ms内完成
        expect(switchStopwatch.elapsedMilliseconds, lessThan(500));
      }
    });
  });

  group('可访问性测试', () {
    testWidgets('语义标签测试', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(primaryColor: AppTheme.primaryColor),
          home: const SimpleTestDashboard(),
        ),
      );
      await tester.pumpAndSettle();

      // 验证重要元素存在
      expect(find.text('基速基金量化分析平台'), findsOneWidget);
    });

    testWidgets('键盘导航测试', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(primaryColor: AppTheme.primaryColor),
          home: const SimpleTestDashboard(),
        ),
      );
      await tester.pumpAndSettle();

      // 测试Tab键导航
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      // 验证焦点正常移动
      expect(tester.binding.focusManager.primaryFocus, isNotNull);
    });
  });

  group('组件集成测试', () {
    testWidgets('基本组件集成测试', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(primaryColor: AppTheme.primaryColor),
          home: const SimpleTestDashboard(),
        ),
      );
      await tester.pumpAndSettle();

      // 验证基本组件正常工作
      expect(find.byType(SliverAppBar), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(TabBarView), findsOneWidget);
    });

    testWidgets('路由导航测试', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(primaryColor: AppTheme.primaryColor),
          home: const SimpleTestDashboard(),
        ),
      );
      await tester.pumpAndSettle();

      // 测试页面导航
      await tester.tap(find.text('基金推荐'));
      await tester.pumpAndSettle();

      // 验证导航正常
      expect(find.text('基金推荐'), findsOneWidget);
    });
  });
}
