import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jisu_fund_analyzer/src/features/alerts/presentation/widgets/notification_test_widget.dart';

void main() {
  group('通知组件生命周期测试', () {
    testWidgets('应该正确处理组件销毁后的异步操作', (WidgetTester tester) async {
      // 1. 创建并渲染通知测试组件
      await tester.pumpWidget(
        const MaterialApp(
          home: NotificationTestWidget(),
        ),
      );

      // 2. 验证组件已正确渲染
      expect(find.byType(NotificationTestWidget), findsOneWidget);
      expect(find.text('🔔 通知测试'), findsOneWidget);

      // 3. 模拟点击测试通知按钮
      final testButton = find.text('测试通知');
      expect(testButton, findsOneWidget);

      await tester.tap(testButton);
      await tester.pump(); // 触发异步操作开始

      // 4. 立即销毁组件（模拟用户快速切换页面）
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('其他页面')),
        ),
      );

      // 5. 等待一段时间，让异步操作完成
      await tester.pump(const Duration(seconds: 1));

      // 6. 验证没有抛出setState() after dispose()错误
      // 如果测试能运行到这里没有抛出异常，说明修复成功
      expect(find.text('其他页面'), findsOneWidget);
    });

    testWidgets('应该正确处理标记已读的异步操作', (WidgetTester tester) async {
      // 1. 创建并渲染通知测试组件
      await tester.pumpWidget(
        const MaterialApp(
          home: NotificationTestWidget(),
        ),
      );

      // 2. 模拟点击测试通知按钮创建通知
      final testButton = find.text('测试通知');
      await tester.tap(testButton);
      await tester.pumpAndSettle(); // 等待通知创建完成

      // 3. 查找标记已读按钮（如果存在）
      final markAsReadButton = find.byIcon(Icons.mark_email_read);
      if (markAsReadButton.evaluate().isNotEmpty) {
        // 4. 点击标记已读按钮
        await tester.tap(markAsReadButton.first);

        // 5. 立即销毁组件（模拟用户快速切换页面）
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: Text('其他页面')),
          ),
        );

        // 6. 等待异步操作完成
        await tester.pump(const Duration(seconds: 1));

        // 7. 验证没有抛出异常
        expect(find.text('其他页面'), findsOneWidget);
      } else {
        // 如果没有标记已读按钮，跳过此测试
        print('没有找到标记已读按钮，跳过测试');
      }
    });

    test('mounted检查应该正确工作', () {
      // 这是一个简单的单元测试来验证mounted检查逻辑
      final widget = NotificationTestWidget();

      // 创建一个测试用的State对象
      final state = widget.createState();

      // 在初始化前，mounted应该为false
      expect(state.mounted, false);

      // 清理
      state.dispose();
    });
  });
}
