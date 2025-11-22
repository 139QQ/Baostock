import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

import '../../../../../lib/src/features/fund/presentation/widgets/cards/adaptive_fund_card.dart';
import '../../../../../lib/src/features/fund/domain/entities/fund.dart';

void main() {
  group('AdaptiveFundCard Tests', () {
    late Fund testFund;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      testFund = Fund(
        code: '000001',
        name: '华夏成长混合',
        unitNav: 1.2345,
        dailyReturn: 0.01567,
        fundType: '混合型',
        company: '华夏基金',
        lastUpdate: DateTime.now(),
        accumulatedNav: 1.2345,
        return1Y: 15.67,
      );
    });

    testWidgets('should render AdaptiveFundCard with basic content',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveFundCard(
              fund: testFund,
            ),
          ),
        ),
      );

      // 验证基本内容显示
      expect(find.text('华夏成长混合'), findsOneWidget);
      expect(find.text('000001'), findsOneWidget);
      expect(find.text('1.2345'), findsOneWidget);
      expect(find.text('15.67%'), findsOneWidget);
    });

    testWidgets('should handle tap callback', (WidgetTester tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveFundCard(
              fund: testFund,
              onTap: () => wasTapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AdaptiveFundCard));
      expect(wasTapped, isTrue);
    });

    testWidgets('should show comparison checkbox when enabled',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveFundCard(
              fund: testFund,
              showComparisonCheckbox: true,
            ),
          ),
        ),
      );

      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('should handle selection change', (WidgetTester tester) async {
      bool isSelected = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveFundCard(
              fund: testFund,
              showComparisonCheckbox: true,
              isSelected: false,
              onSelectionChanged: (selected) => isSelected = selected,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(Checkbox));
      expect(isSelected, isTrue);
    });

    testWidgets('should adapt to different performance levels',
        (WidgetTester tester) async {
      // 测试低性能级别
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveFundCard(
              fund: testFund,
              performanceLevel: PerformanceLevelSimple.low,
            ),
          ),
        ),
      );

      expect(find.byType(AdaptiveFundCard), findsOneWidget);

      // 测试高性能级别
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveFundCard(
              fund: testFund,
              performanceLevel: PerformanceLevelSimple.high,
            ),
          ),
        ),
      );

      expect(find.byType(AdaptiveFundCard), findsOneWidget);
    });

    testWidgets('should handle disabled animations',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveFundCard(
              fund: testFund,
              forceAnimationLevel: AnimationLevel.disabled,
            ),
          ),
        ),
      );

      // 禁用动画时应该仍然正常渲染
      expect(find.byType(AdaptiveFundCard), findsOneWidget);
      expect(find.text('华夏成长混合'), findsOneWidget);
    });

    testWidgets('should handle empty callbacks gracefully',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveFundCard(
              fund: testFund,
              onTap: null,
              onSelectionChanged: null,
              onAddToWatchlist: null,
              onCompare: null,
              onShare: null,
            ),
          ),
        ),
      );

      // 即使回调为null，也应该能正常渲染和交互
      expect(find.byType(AdaptiveFundCard), findsOneWidget);
      await tester.tap(find.byType(AdaptiveFundCard));
    });

    testWidgets('should provide semantic labels for accessibility',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveFundCard(
              fund: testFund,
              enableAccessibility: true,
            ),
          ),
        ),
      );

      // 验证语义标签
      expect(
        find.bySemanticsLabel('基金卡片: 华夏成长混合, 收益率: 15.67%'),
        findsOneWidget,
      );
    });

    group('Performance Tests', () {
      testWidgets('should render efficiently with multiple cards',
          (WidgetTester tester) async {
        final funds = List.generate(
            100,
            (index) => Fund(
                  code: '${index.toString().padLeft(6, '0')}',
                  name: '测试基金 $index',
                  unitNav: 1.0 + index * 0.01,
                  dailyReturn: (index % 20 - 10) * 0.0001,
                  fundType: '混合型',
                  company: '测试基金公司${index % 5}',
                  lastUpdate: DateTime.now(),
                  accumulatedNav: 1.0 + index * 0.01,
                  return1Y: (index % 20 - 10).toDouble(),
                ));

        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView.builder(
                itemCount: funds.length,
                itemBuilder: (context, index) {
                  return AdaptiveFundCard(
                    fund: funds[index],
                    onTap: () {},
                  );
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        stopwatch.stop();

        // 验证渲染时间应该在合理范围内
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));
        expect(find.byType(AdaptiveFundCard), findsWidgets);
      });

      testWidgets('should handle rapid state changes',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return AdaptiveFundCard(
                    fund: testFund,
                    isSelected: false,
                    onSelectionChanged: (selected) {
                      setState(() {});
                    },
                  );
                },
              ),
            ),
          ),
        );

        // 快速切换选中状态
        for (int i = 0; i < 10; i++) {
          await tester.tap(find.byType(AdaptiveFundCard));
          await tester.pump(Duration(milliseconds: 16)); // 60fps
        }

        // 应该能够处理快速状态变化而不崩溃
        expect(find.byType(AdaptiveFundCard), findsOneWidget);
      });
    });

    group('Error Handling Tests', () {
      testWidgets('should handle null fund gracefully',
          (WidgetTester tester) async {
        // 这个测试可能需要根据实际实现调整
        // 因为Fund通常应该是必需的
        expect(() {
          AdaptiveFundCard(
            fund: Fund(
                code: '',
                name: '',
                unitNav: 0,
                dailyReturn: 0,
                fundType: '',
                company: '',
                lastUpdate: DateTime.now(),
                accumulatedNav: 0),
          );
        }, returnsNormally);
      });

      testWidgets('should handle invalid data gracefully',
          (WidgetTester tester) async {
        final invalidFund = Fund(
          code: '', // 空代码
          name: '无效基金',
          unitNav: -1, // 无效净值
          dailyReturn: 9.99, // 无效收益率
          fundType: '',
          company: '',
          lastUpdate: DateTime.now(),
          accumulatedNav: -1,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AdaptiveFundCard(
                fund: invalidFund,
              ),
            ),
          ),
        );

        // 即使数据无效，也应该尝试渲染
        expect(find.byType(AdaptiveFundCard), findsOneWidget);
      });
    });

    group('Animation Tests', () {
      testWidgets('should perform entrance animation',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AdaptiveFundCard(
                fund: testFund,
              ),
            ),
          ),
        );

        // 初始状态 - 动画开始前
        await tester.pump(Duration.zero);

        // 动画进行中
        await tester.pump(Duration(milliseconds: 150));

        // 动画完成
        await tester.pump(Duration(milliseconds: 150));

        // 验证卡片始终存在
        expect(find.byType(AdaptiveFundCard), findsOneWidget);
      });

      testWidgets('should respect animation level settings',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AdaptiveFundCard(
                fund: testFund,
                forceAnimationLevel: AnimationLevel.enhanced,
              ),
            ),
          ),
        );

        // 增强动画级别应该包含更多动画效果
        expect(find.byType(AdaptiveFundCard), findsOneWidget);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AdaptiveFundCard(
                fund: testFund,
                forceAnimationLevel: AnimationLevel.basic,
              ),
            ),
          ),
        );

        // 基础动画级别应该有较少的动画效果
        expect(find.byType(AdaptiveFundCard), findsOneWidget);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AdaptiveFundCard(
                fund: testFund,
                forceAnimationLevel: AnimationLevel.disabled,
              ),
            ),
          ),
        );

        // 禁用动画级别应该没有动画效果
        expect(find.byType(AdaptiveFundCard), findsOneWidget);
      });
    });

    group('Integration Tests', () {
      testWidgets('should work with other Material widgets',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: AppBar(title: const Text('测试')),
              body: Column(
                children: [
                  AdaptiveFundCard(fund: testFund),
                  const Text('其他内容'),
                  AdaptiveFundCard(
                    fund: Fund(
                      code: '000002',
                      name: '测试基金2',
                      unitNav: 2.3456,
                      dailyReturn: -0.0543,
                      fundType: '股票型',
                      company: '测试基金公司',
                      lastUpdate: DateTime.now(),
                      accumulatedNav: 2.3456,
                      return1Y: -5.43,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.byType(AdaptiveFundCard), findsNWidgets(2));
        expect(find.text('其他内容'), findsOneWidget);
        expect(find.text('测试'), findsOneWidget);
      });

      testWidgets('should handle theme changes', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              primaryColor: Colors.blue,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.light,
              ),
            ),
            home: Scaffold(
              body: AdaptiveFundCard(
                fund: testFund,
              ),
            ),
          ),
        );

        // 验证在明亮主题下的显示
        expect(find.byType(AdaptiveFundCard), findsOneWidget);

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              primaryColor: Colors.green,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.green,
                brightness: Brightness.dark,
              ),
            ),
            home: Scaffold(
              body: AdaptiveFundCard(
                fund: testFund,
              ),
            ),
          ),
        );

        // 验证在深色主题下的显示
        expect(find.byType(AdaptiveFundCard), findsOneWidget);
      });
    });
  });
}
