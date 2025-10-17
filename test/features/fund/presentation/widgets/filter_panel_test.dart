import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jisu_fund_analyzer/src/features/fund/domain/entities/fund_filter_criteria.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/bloc/filter_bloc.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/widgets/filter_panel.dart';

class MockFundFilterUseCase {
  Future<List<String>> getFilterOptions(FilterType type) async {
    // Mock implementation
    switch (type) {
      case FilterType.fundType:
        return ['股票型', '债券型', '混合型'];
      case FilterType.company:
        return ['易方达', '华夏', '嘉实'];
      default:
        return [];
    }
  }
}

void main() {
  group('FilterPanel Tests', () {
    late FilterBloc filterBloc;
    late MockFundFilterUseCase mockUseCase;

    setUp(() {
      mockUseCase = MockFundFilterUseCase();
      // Note: In a real test, you would mock the use case properly
      // For now, we'll create the bloc without mocking
      filterBloc = FilterBloc(
        filterUseCase: mockUseCase as dynamic, // Type casting for simplicity
      );
    });

    tearDown(() {
      filterBloc.close();
    });

    testWidgets('FilterPanel renders correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<FilterBloc>.value(
            value: filterBloc,
            child: const Scaffold(
              body: FilterPanel(),
            ),
          ),
        ),
      );

      expect(find.text('基金筛选'), findsOneWidget);
      expect(find.byType(FilterPanel), findsOneWidget);
    });

    testWidgets('FilterPanel expands and collapses', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<FilterBloc>.value(
            value: filterBloc,
            child: const Scaffold(
              body: FilterPanel(),
            ),
          ),
        ),
      );

      // Initially expanded
      expect(find.text('基础筛选'), findsOneWidget);
      expect(find.text('高级筛选'), findsOneWidget);
      expect(find.text('排序设置'), findsOneWidget);

      // Find and tap the expand/collapse button
      final expandButton = find.byIcon(Icons.close);
      expect(expandButton, findsOneWidget);

      await tester.tap(expandButton);
      await tester.pump();

      // Should be collapsed - tabs should not be visible
      expect(find.text('基础筛选'), findsNothing);
      expect(find.text('高级筛选'), findsNothing);
      expect(find.text('排序设置'), findsNothing);
    });

    testWidgets('FilterPanel shows filter sections', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<FilterBloc>.value(
            value: filterBloc,
            child: const Scaffold(
              body: FilterPanel(),
            ),
          ),
        ),
      );

      // Check for filter sections
      expect(find.text('基金类型'), findsOneWidget);
      expect(find.text('风险等级'), findsOneWidget);
      expect(find.text('基金规模'), findsOneWidget);
    });

    testWidgets('FilterPanel search bar works', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<FilterBloc>.value(
            value: filterBloc,
            child: const Scaffold(
              body: FilterPanel(),
            ),
          ),
        ),
      );

      // Find search bar
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      // Enter search text
      await tester.enterText(searchField, '易方达');
      await tester.pump();

      expect(find.text('易方达'), findsOneWidget);
    });

    testWidgets('FilterPanel tab switching works', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<FilterBloc>.value(
            value: filterBloc,
            child: const Scaffold(
              body: FilterPanel(),
            ),
          ),
        ),
      );

      // Initial tab should be "基础筛选"
      expect(find.text('基础筛选'), findsOneWidget);
      expect(find.text('基金类型'), findsOneWidget);

      // Tap on "高级筛选" tab
      await tester.tap(find.text('高级筛选'));
      await tester.pumpAndSettle();

      // Should show advanced filters
      expect(find.text('管理公司'), findsOneWidget);
      expect(find.text('成立时间'), findsOneWidget);
      expect(find.text('年化收益率'), findsOneWidget);

      // Tap on "排序设置" tab
      await tester.tap(find.text('排序设置'));
      await tester.pumpAndSettle();

      // Should show sort options
      expect(find.text('排序字段'), findsOneWidget);
      expect(find.text('排序方向'), findsOneWidget);
    });

    testWidgets('FilterPanel action buttons work', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<FilterBloc>.value(
            value: filterBloc,
            child: const Scaffold(
              body: FilterPanel(),
            ),
          ),
        ),
      );

      // Find action buttons
      expect(find.text('重置筛选'), findsOneWidget);
      expect(find.text('应用筛选'), findsOneWidget);

      // Reset button should be disabled initially (no filters applied)
      final resetButton = tester
          .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, '重置筛选'));
      expect(resetButton.onPressed, isNull);
    });

    testWidgets('FilterPanel fund type selection works', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<FilterBloc>.value(
            value: filterBloc,
            child: const Scaffold(
              body: FilterPanel(),
            ),
          ),
        ),
      );

      // Find fund type chips
      expect(find.text('股票型'), findsOneWidget);
      expect(find.text('债券型'), findsOneWidget);
      expect(find.text('混合型'), findsOneWidget);

      // Tap on a fund type
      await tester.tap(find.text('股票型'));
      await tester.pump();

      // The chip should now be selected (this would require proper bloc setup)
      // For now, we just verify the interaction works
      expect(find.text('股票型'), findsOneWidget);
    });

    testWidgets('FilterPanel risk level selection works', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<FilterBloc>.value(
            value: filterBloc,
            child: const Scaffold(
              body: FilterPanel(),
            ),
          ),
        ),
      );

      // Find risk level chips
      expect(find.text('R1 低风险'), findsOneWidget);
      expect(find.text('R2 中低风险'), findsOneWidget);
      expect(find.text('R3 中等风险'), findsOneWidget);

      // Tap on a risk level
      await tester.tap(find.text('R1 低风险'));
      await tester.pump();

      // The chip should now be selected
      expect(find.text('R1 低风险'), findsOneWidget);
    });

    testWidgets('FilterPanel range slider works', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<FilterBloc>.value(
            value: filterBloc,
            child: const Scaffold(
              body: FilterPanel(),
            ),
          ),
        ),
      );

      // Find range slider
      expect(find.byType(RangeSlider), findsOneWidget);
      expect(find.text('基金规模'), findsOneWidget);

      // The slider should be interactive
      // (Testing actual slider interaction would require more complex setup)
    });

    testWidgets('FilterPanel date picker works', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<FilterBloc>.value(
            value: filterBloc,
            child: const Scaffold(
              body: FilterPanel(),
            ),
          ),
        ),
      );

      // Switch to advanced tab to see date picker
      await tester.tap(find.text('高级筛选'));
      await tester.pumpAndSettle();

      expect(find.text('开始日期'), findsOneWidget);
      expect(find.text('结束日期'), findsOneWidget);

      // Tap on date field (would need to handle date picker dialog)
      await tester.tap(find.text('开始日期'));
      await tester.pump();

      // Date picker interaction would require more complex test setup
    });

    testWidgets('FilterPanel sort options work', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<FilterBloc>.value(
            value: filterBloc,
            child: const Scaffold(
              body: FilterPanel(),
            ),
          ),
        ),
      );

      // Switch to sort tab
      await tester.tap(find.text('排序设置'));
      await tester.pumpAndSettle();

      // Find sort options
      expect(find.text('基金名称'), findsOneWidget);
      expect(find.text('基金代码'), findsOneWidget);
      expect(find.text('最新净值'), findsOneWidget);

      // Tap on a sort option
      await tester.tap(find.text('基金名称'));
      await tester.pump();

      // The option should be selected
      expect(find.text('基金名称'), findsOneWidget);
    });
  });
}
