import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jisu_fund_analyzer/src/features/fund/domain/entities/comparison_result.dart';
import 'package:jisu_fund_analyzer/src/features/fund/domain/entities/fund_ranking.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/widgets/comparison_card.dart';

void main() {
  group('ComparisonCard Tests', () {
    late FundComparisonData testFundData;
    late Widget testWidget;

    setUp(() {
      testFundData = const FundComparisonData(
        fundCode: '000001',
        fundName: '华夏成长混合',
        fundType: '混合型',
        period: RankingPeriod.oneYear,
        totalReturn: 0.1523,
        annualizedReturn: 0.1456,
        volatility: 0.1823,
        sharpeRatio: 0.8234,
        maxDrawdown: -0.1234,
        ranking: 5,
        categoryAverage: 0.1234,
        beatCategoryPercent: 23.45,
        benchmarkReturn: 0.1345,
        beatBenchmarkPercent: 13.21,
      );

      testWidget = MaterialApp(
        home: Scaffold(
          body: ComparisonCard(
            comparisonData: testFundData,
            ranking: 5,
            totalFunds: 10,
            onTap: () {},
            onDetail: () {},
            onFavorite: () {},
            onCompare: () {},
          ),
        ),
      );
    });

    testWidgets('应该正确渲染基金对比卡片', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // 验证基金名称显示
      expect(find.text('华夏成长混合'), findsOneWidget);

      // 验证基金代码和类型显示
      expect(find.text('000001 • 混合型'), findsOneWidget);

      // 验证排名显示
      expect(find.text('#5'), findsOneWidget);

      // 验证收益率显示
      expect(find.text('15.23%'), findsOneWidget);

      // 验证按钮存在
      expect(find.text('详情'), findsOneWidget);
      expect(find.text('对比'), findsOneWidget);
    });

    testWidgets('应该正确显示正收益', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // 验证上升趋势图标和正收益显示
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
      expect(find.text('15.23%'), findsOneWidget);
    });

    testWidgets('应该正确显示负收益', (WidgetTester tester) async {
      const negativeFundData = FundComparisonData(
        fundCode: '000002',
        fundName: '测试基金',
        fundType: '股票型',
        period: RankingPeriod.oneYear,
        totalReturn: -0.1234,
        annualizedReturn: -0.1234,
        volatility: 0.2,
        sharpeRatio: -0.5,
        maxDrawdown: -0.2,
        ranking: 8,
        categoryAverage: 0.1,
        beatCategoryPercent: -15.0,
        benchmarkReturn: 0.1,
        beatBenchmarkPercent: -20.0,
      );

      final testWidgetWithNegativeReturn = MaterialApp(
        home: Scaffold(
          body: ComparisonCard(
            comparisonData: negativeFundData,
            ranking: 8,
            totalFunds: 10,
            onTap: () {},
            onDetail: () {},
            onFavorite: () {},
            onCompare: () {},
          ),
        ),
      );

      await tester.pumpWidget(testWidgetWithNegativeReturn);
      await tester.pumpAndSettle();

      // 验证下降趋势图标和负收益显示
      expect(find.byIcon(Icons.trending_down), findsOneWidget);
      expect(find.text('-12.34%'), findsOneWidget);
    });

    testWidgets('应该正确处理点击事件', (WidgetTester tester) async {
      bool onTapCalled = false;
      bool onDetailCalled = false;
      bool onFavoriteCalled = false;
      bool onCompareCalled = false;

      final testWidgetWithCallbacks = MaterialApp(
        home: Scaffold(
          body: ComparisonCard(
            comparisonData: testFundData,
            ranking: 5,
            totalFunds: 10,
            onTap: () => onTapCalled = true,
            onDetail: () => onDetailCalled = true,
            onFavorite: () => onFavoriteCalled = true,
            onCompare: () => onCompareCalled = true,
          ),
        ),
      );

      await tester.pumpWidget(testWidgetWithCallbacks);
      await tester.pumpAndSettle();

      // 测试卡片点击
      await tester.tap(find.byType(ComparisonCard));
      expect(onTapCalled, true);

      // 测试详情按钮点击
      await tester.tap(find.text('详情'));
      expect(onDetailCalled, true);

      // 测试对比按钮点击
      await tester.tap(find.text('对比'));
      expect(onCompareCalled, true);

      // 测试收藏按钮点击
      await tester.tap(find.byIcon(Icons.favorite_border));
      expect(onFavoriteCalled, true);
    });

    testWidgets('应该正确显示收藏状态', (WidgetTester tester) async {
      final testWidgetWithFavorite = MaterialApp(
        home: Scaffold(
          body: ComparisonCard(
            comparisonData: testFundData,
            ranking: 5,
            totalFunds: 10,
            isFavorite: true,
            onTap: () {},
            onDetail: () {},
            onFavorite: () {},
            onCompare: () {},
          ),
        ),
      );

      await tester.pumpWidget(testWidgetWithFavorite);
      await tester.pumpAndSettle();

      // 验证收藏状态图标显示
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsNothing);
    });

    testWidgets('应该正确显示排名样式', (WidgetTester tester) async {
      // 测试前三名样式
      final topRankWidget = MaterialApp(
        home: Scaffold(
          body: ComparisonCard(
            comparisonData: testFundData,
            ranking: 1,
            totalFunds: 10,
            onTap: () {},
            onDetail: () {},
            onFavorite: () {},
            onCompare: () {},
          ),
        ),
      );

      await tester.pumpWidget(topRankWidget);
      await tester.pumpAndSettle();

      // 验证第一名显示样式
      expect(find.byIcon(Icons.looks_one), findsOneWidget);
      expect(find.text('#1'), findsOneWidget);
    });

    testWidgets('应该正确显示风险等级', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // 验证风险等级显示
      expect(find.text('风险等级'), findsOneWidget);
      expect(find.text('中风险'), findsOneWidget); // 基于volatility 0.1823
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('应该正确显示夏普比率', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // 验证夏普比率显示
      expect(find.text('夏普比率'), findsOneWidget);
      expect(find.text('0.82'), findsOneWidget);
      expect(find.byIcon(Icons.pie_chart), findsOneWidget);
    });

    testWidgets('应该正确显示最大回撤', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // 验证最大回撤显示
      expect(find.text('最大回撤'), findsOneWidget);
      expect(find.text('-12.34%'), findsOneWidget);
      expect(find.byIcon(Icons.account_balance), findsOneWidget);
    });
  });
}
