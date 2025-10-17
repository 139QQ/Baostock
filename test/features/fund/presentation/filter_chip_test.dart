import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 筛选芯片组件单元测试
void main() {
  group('FilterChip 组件测试', () {
    testWidgets('应该正确显示筛选芯片', (WidgetTester tester) async {
      bool isSelected = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterChip(
              label: const Text('股票型'),
              selected: isSelected,
              onSelected: (selected) {
                isSelected = selected;
              },
            ),
          ),
        ),
      );

      // 验证芯片显示
      expect(find.text('股票型'), findsOneWidget);
      expect(find.byType(FilterChip), findsOneWidget);

      // 初始状态应该是未选中
      final filterChip = tester.widget<FilterChip>(find.byType(FilterChip));
      expect(filterChip.selected, isFalse);
    });

    testWidgets('应该正确响应选择事件', (WidgetTester tester) async {
      bool isSelected = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterChip(
              label: const Text('债券型'),
              selected: isSelected,
              onSelected: (selected) {
                isSelected = selected;
              },
            ),
          ),
        ),
      );

      // 点击芯片
      await tester.tap(find.byType(FilterChip));
      await tester.pump();

      // 验证选中状态
      expect(isSelected, isTrue);
    });

    testWidgets('应该正确显示选中状态', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterChip(
              label: const Text('混合型'),
              selected: true,
              onSelected: (_) {},
            ),
          ),
        ),
      );

      // 验证选中状态
      final filterChip = tester.widget<FilterChip>(find.byType(FilterChip));
      expect(filterChip.selected, isTrue);
    });

    testWidgets('应该正确处理颜色变化', (WidgetTester tester) async {
      const selectedColor = Colors.blue;
      const unselectedColor = Colors.grey;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterChip(
              label: const Text('指数型'),
              selected: false,
              onSelected: (_) {},
              backgroundColor: unselectedColor,
              selectedColor: selectedColor,
            ),
          ),
        ),
      );

      // 验证颜色设置
      final filterChip = tester.widget<FilterChip>(find.byType(FilterChip));
      expect(filterChip.backgroundColor, equals(unselectedColor));
      expect(filterChip.selectedColor, equals(selectedColor));
    });

    testWidgets('应该正确处理删除按钮', (WidgetTester tester) async {
      bool deleted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InputChip(
              label: const Text('FOF'),
              deleteIcon: const Icon(Icons.close),
              onDeleted: () {
                deleted = true;
              },
            ),
          ),
        ),
      );

      // 点击删除按钮
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      // 验证删除事件
      expect(deleted, isTrue);
    });
  });
}
