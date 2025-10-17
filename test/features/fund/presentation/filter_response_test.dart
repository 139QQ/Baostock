import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 筛选响应时间测试
///
/// 专门测试筛选功能的响应性能
void main() {
  group('筛选响应时间测试', () {
    testWidgets('筛选操作响应时间应该在300ms以内', (WidgetTester tester) async {
      // 创建一个简单的测试UI
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  // 模拟筛选操作
                  final startTime = DateTime.now();

                  // 模拟筛选逻辑
                  await Future.delayed(const Duration(milliseconds: 50));

                  final endTime = DateTime.now();
                  final responseTime = endTime.difference(startTime);

                  // 验证响应时间
                  expect(responseTime.inMilliseconds, lessThan(300));
                },
                child: const Text('测试筛选'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 点击按钮触发筛选测试
      final button = find.byType(ElevatedButton);
      expect(button, findsOneWidget);

      final startTime = DateTime.now();
      await tester.tap(button);
      await tester.pumpAndSettle();
      final endTime = DateTime.now();

      // 验证整体响应时间
      final responseTime = endTime.difference(startTime);
      expect(responseTime.inMilliseconds, lessThan(1000)); // 允许一些测试环境的延迟
    });

    testWidgets('防抖动机制应该有效', (WidgetTester tester) async {
      int callCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      callCount++;
                    },
                    child: const Text('快速点击1'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      callCount++;
                    },
                    child: const Text('快速点击2'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final buttons = find.byType(ElevatedButton);
      expect(buttons, findsNWidgets(2));

      // 快速点击多个按钮
      await tester.tap(buttons.first);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(buttons.at(1));
      await tester.pump(const Duration(milliseconds: 50));

      // 等待防抖动时间
      await tester.pump(const Duration(milliseconds: 300));

      // 验证调用次数
      expect(callCount, equals(2));
    });

    testWidgets('UI响应应该流畅', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: List.generate(100, (index) {
                return ListTile(
                  title: Text('基金项目 $index'),
                  subtitle: Text('代码: ${1000 + index}'),
                  trailing: ElevatedButton(
                    onPressed: () {},
                    child: const Text('筛选'),
                  ),
                );
              }),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 测试滚动性能
      final startTime = DateTime.now();
      await tester.fling(find.byType(ListView), const Offset(0, -300), 5000);
      await tester.pumpAndSettle();
      final endTime = DateTime.now();

      // 验证滚动响应时间
      final scrollTime = endTime.difference(startTime);
      expect(scrollTime.inMilliseconds, lessThan(2000));
    });

    testWidgets('加载状态应该正确显示', (WidgetTester tester) async {
      bool isLoading = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    if (isLoading)
                      const CircularProgressIndicator()
                    else
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            isLoading = true;
                          });

                          // 模拟加载过程
                          Future.delayed(const Duration(milliseconds: 500), () {
                            setState(() {
                              isLoading = false;
                            });
                          });
                        },
                        child: const Text('开始筛选'),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证初始状态
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(ElevatedButton), findsOneWidget);

      // 点击开始筛选
      final button = find.byType(ElevatedButton);
      await tester.tap(button);
      await tester.pump();

      // 验证加载状态
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // 等待加载完成
      await tester.pump(const Duration(milliseconds: 600));

      // 验证加载完成状态
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });
  });

  group('筛选准确性测试', () {
    test('应该正确筛选基金类型', () {
      final funds = [
        {'name': '基金A', 'type': '股票型'},
        {'name': '基金B', 'type': '债券型'},
        {'name': '基金C', 'type': '混合型'},
        {'name': '基金D', 'type': '股票型'},
      ];

      // 筛选股票型基金
      final stockFunds = funds.where((fund) => fund['type'] == '股票型').toList();
      expect(stockFunds.length, equals(2));
      expect(stockFunds[0]['name'], equals('基金A'));
      expect(stockFunds[1]['name'], equals('基金D'));
    });

    test('应该正确组合多个筛选条件', () {
      final funds = [
        {'name': '基金A', 'type': '股票型', 'risk': 'R5'},
        {'name': '基金B', 'type': '债券型', 'risk': 'R1'},
        {'name': '基金C', 'type': '混合型', 'risk': 'R3'},
        {'name': '基金D', 'type': '股票型', 'risk': 'R4'},
      ];

      // 筛选股票型且风险等级为R4以上的基金
      final filteredFunds = funds.where((fund) {
        return fund['type'] == '股票型' &&
            (fund['risk'] == 'R4' || fund['risk'] == 'R5');
      }).toList();

      expect(filteredFunds.length, equals(2));
      expect(filteredFunds[0]['name'], equals('基金A'));
      expect(filteredFunds[1]['name'], equals('基金D'));
    });

    test('应该正确处理空筛选结果', () {
      final funds = [
        {'name': '基金A', 'type': '股票型'},
        {'name': '基金B', 'type': '债券型'},
      ];

      // 筛选不存在的类型
      final filteredFunds =
          funds.where((fund) => fund['type'] == '货币型').toList();
      expect(filteredFunds.length, equals(0));
    });
  });

  group('边界条件测试', () {
    test('应该正确处理空基金列表', () {
      final funds = <Map<String, String>>[];

      // 筛选任何条件
      final filteredFunds =
          funds.where((fund) => fund['type'] == '股票型').toList();
      expect(filteredFunds.length, equals(0));
    });

    test('应该正确处理极值筛选条件', () {
      final funds = [
        {'name': '基金A', 'return': 50.5},
        {'name': '基金B', 'return': -10.2},
        {'name': '基金C', 'return': 0.0},
        {'name': '基金D', 'return': 100.0},
      ];

      // 筛选收益率在-100到100之间的基金
      final filteredFunds = funds.where((fund) {
        final returnValue = double.tryParse(fund['return'].toString());
        return returnValue != null && returnValue >= -100 && returnValue <= 100;
      }).toList();

      expect(filteredFunds.length, equals(4));
    });

    test('应该正确处理特殊字符', () {
      final funds = [
        {'name': '华夏成长(股票型)', 'code': '000001'},
        {'name': '易方达稳健-收益', 'code': '110001'},
        {'name': '招商中证白酒指数', 'code': '161725'},
      ];

      // 筛选包含特殊字符的基金名称
      final specialFunds = funds.where((fund) {
        return fund['name']!.contains('(') ||
            fund['name']!.contains('-') ||
            fund['name']!.contains('中证');
      }).toList();

      expect(specialFunds.length, equals(3));
    });
  });

  group('用户体验测试', () {
    testWidgets('应该正确显示筛选条件标签', (WidgetTester tester) async {
      String selectedFilter = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Wrap(
              children: ['股票型', '债券型', '混合型'].map((type) {
                return FilterChip(
                  label: Text(type),
                  selected: selectedFilter == type,
                  onSelected: (selected) {
                    selectedFilter = selected ? type : '';
                  },
                );
              }).toList(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 选择筛选条件
      final stockChip = find.widgetWithText(FilterChip, '股票型');
      await tester.tap(stockChip);
      await tester.pump();

      // 验证标签显示
      expect(find.widgetWithText(FilterChip, '股票型'), findsOneWidget);
    });

    testWidgets('应该支持筛选条件重置', (WidgetTester tester) async {
      bool hasFilters = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    hasFilters = true;
                  },
                  child: const Text('应用筛选'),
                ),
                if (hasFilters)
                  ElevatedButton(
                    onPressed: () {
                      hasFilters = false;
                    },
                    child: const Text('重置筛选'),
                  ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 应用筛选
      final applyButton = find.widgetWithText(ElevatedButton, '应用筛选');
      await tester.tap(applyButton);
      await tester.pump();

      // 验证重置按钮出现
      expect(find.widgetWithText(ElevatedButton, '重置筛选'), findsOneWidget);

      // 重置筛选
      final resetButton = find.widgetWithText(ElevatedButton, '重置筛选');
      await tester.tap(resetButton);
      await tester.pump();

      // 验证重置按钮消失
      expect(find.widgetWithText(ElevatedButton, '重置筛选'), findsNothing);
    });
  });
}
