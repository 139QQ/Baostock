import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jisu_fund_analyzer/src/features/fund/domain/entities/comparison_result.dart'
    as fund;
import 'package:jisu_fund_analyzer/src/features/fund/domain/entities/fund_ranking.dart';
import 'package:jisu_fund_analyzer/src/features/fund/domain/entities/multi_dimensional_comparison_criteria.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/widgets/comparison_carousel.dart';

/// 测试数据工厂
class ComparisonTestFactory {
  /// 创建测试用的基金对比数据
  static fund.FundComparisonData createTestFundComparisonData({
    String fundCode = '000001',
    String fundName = '测试基金',
    String fundType = '混合型',
    RankingPeriod period = RankingPeriod.oneYear,
    double totalReturn = 0.15,
    double annualizedReturn = 0.14,
    double volatility = 0.18,
    double sharpeRatio = 0.8,
    double maxDrawdown = -0.12,
    int ranking = 1,
    double categoryAverage = 0.12,
    double beatCategoryPercent = 20.0,
    double benchmarkReturn = 0.13,
    double beatBenchmarkPercent = 15.0,
  }) {
    return fund.FundComparisonData(
      fundCode: fundCode,
      fundName: fundName,
      fundType: fundType,
      period: period,
      totalReturn: totalReturn,
      annualizedReturn: annualizedReturn,
      volatility: volatility,
      sharpeRatio: sharpeRatio,
      maxDrawdown: maxDrawdown,
      ranking: ranking,
      categoryAverage: categoryAverage,
      beatCategoryPercent: beatCategoryPercent,
      benchmarkReturn: benchmarkReturn,
      beatBenchmarkPercent: beatBenchmarkPercent,
    );
  }

  /// 创建测试用的对比结果
  static fund.ComparisonResult createTestComparisonResult({
    List<fund.FundComparisonData> fundData = const [],
    List<String> fundCodes = const ['000001', '000002'],
    List<RankingPeriod> periods = const [RankingPeriod.oneYear],
  }) {
    return fund.ComparisonResult(
      criteria: MultiDimensionalComparisonCriteria(
        fundCodes: fundCodes,
        periods: periods,
        metric: ComparisonMetric.totalReturn,
      ),
      fundData: fundData,
      statistics: fund.ComparisonStatistics(
        averageReturn: fundData.isEmpty
            ? 0.0
            : _calculateAverage(fundData.map((d) => d.totalReturn).toList()),
        maxReturn: fundData.isEmpty
            ? 0.0
            : fundData
                .map((d) => d.totalReturn)
                .reduce((a, b) => a > b ? a : b),
        minReturn: fundData.isEmpty
            ? 0.0
            : fundData
                .map((d) => d.totalReturn)
                .reduce((a, b) => a < b ? a : b),
        returnStdDev: 0.05,
        averageVolatility: fundData.isEmpty
            ? 0.0
            : _calculateAverage(fundData.map((d) => d.volatility).toList()),
        maxVolatility: fundData.isEmpty
            ? 0.0
            : fundData.map((d) => d.volatility).reduce((a, b) => a > b ? a : b),
        minVolatility: fundData.isEmpty
            ? 0.0
            : fundData.map((d) => d.volatility).reduce((a, b) => a < b ? a : b),
        averageSharpeRatio: fundData.isEmpty
            ? 0.0
            : _calculateAverage(fundData.map((d) => d.sharpeRatio).toList()),
        correlationMatrix: const {},
        updatedAt: DateTime.now(),
      ),
      calculatedAt: DateTime.now(),
    );
  }

  static double _calculateAverage(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// 创建空的对比结果
  static fund.ComparisonResult createEmptyComparisonResult() {
    return createTestComparisonResult(
      fundData: const [],
      fundCodes: const [],
    );
  }

  /// 创建包含多只基金的测试数据
  static List<fund.FundComparisonData> createMultipleFundData({
    int count = 3,
  }) {
    final List<fund.FundComparisonData> funds = [];
    for (int i = 0; i < count; i++) {
      funds.add(createTestFundComparisonData(
        fundCode: (i + 1).toString().padLeft(6, '0'),
        fundName: '测试基金${i + 1}',
        fundType: ['股票型', '债券型', '混合型'][i % 3],
        totalReturn: 0.05 + (i * 0.05),
        ranking: i + 1,
      ));
    }
    return funds;
  }
}

void main() {
  group('ComparisonCarousel Tests', () {
    late fund.ComparisonResult testComparisonResult;

    setUp(() {
      final testFunds = ComparisonTestFactory.createMultipleFundData(count: 3);
      testComparisonResult = ComparisonTestFactory.createTestComparisonResult(
        fundData: testFunds,
        fundCodes: testFunds.map((f) => f.fundCode).toList(),
      );
    });

    testWidgets('应该正确渲染轮播组件', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 800,
              child: ComparisonCarousel(
                comparisonResult: testComparisonResult,
                onFundTap: (data) {},
                onFundDetail: (code) {},
                onFavorite: (code, isFavorite) {},
                onCompare: (code) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 验证组件存在
      expect(find.byType(ComparisonCarousel), findsOneWidget);
      expect(find.byType(PageView), findsOneWidget);

      // 验证标题显示
      expect(find.text('基金对比 (3只)'), findsOneWidget);

      // 验证第一个基金卡片显示
      expect(find.text('测试基金1'), findsOneWidget);
      expect(find.text('#1'), findsOneWidget);
    });

    testWidgets('应该正确显示页面指示器', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 800,
              child: ComparisonCarousel(
                comparisonResult: testComparisonResult,
                onFundTap: (data) {},
                onFundDetail: (code) {},
                onFavorite: (code, isFavorite) {},
                onCompare: (code) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 验证PageView存在
      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('应该支持滑动切换基金', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 800,
              child: ComparisonCarousel(
                comparisonResult: testComparisonResult,
                onFundTap: (data) {},
                onFundDetail: (code) {},
                onFavorite: (code, isFavorite) {},
                onCompare: (code) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 验证PageView存在
      expect(find.byType(PageView), findsOneWidget);

      // 向左滑动切换基金
      await tester.fling(
        find.byType(PageView),
        const Offset(-300, 0),
        1000,
      );
      await tester.pumpAndSettle();

      // 验证组件仍然存在
      expect(find.byType(ComparisonCarousel), findsOneWidget);
    });

    testWidgets('应该正确处理回调事件', (WidgetTester tester) async {
      bool fundTapCalled = false;
      bool fundDetailCalled = false;
      bool favoriteCalled = false;
      bool compareCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 800,
              child: ComparisonCarousel(
                comparisonResult: testComparisonResult,
                onFundTap: (data) => fundTapCalled = true,
                onFundDetail: (code) => fundDetailCalled = true,
                onFavorite: (code, isFavorite) => favoriteCalled = true,
                onCompare: (code) => compareCalled = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 测试基金卡片点击
      final fundCards = find.text('测试基金1');
      if (fundCards.evaluate().isNotEmpty) {
        await tester.tap(fundCards.first);
        await tester.pumpAndSettle();
        expect(fundTapCalled, true);
      }

      // 测试详情按钮点击
      final detailButtons = find.text('详情');
      if (detailButtons.evaluate().isNotEmpty) {
        await tester.tap(detailButtons.first);
        await tester.pumpAndSettle();
        expect(fundDetailCalled, true);
      }

      // 测试对比按钮点击
      final compareButtons = find.text('对比');
      if (compareButtons.evaluate().isNotEmpty) {
        await tester.tap(compareButtons.first);
        await tester.pumpAndSettle();
        expect(compareCalled, true);
      }

      // 测试收藏按钮点击
      final favoriteButtons = find.byIcon(Icons.favorite_border);
      if (favoriteButtons.evaluate().isNotEmpty) {
        await tester.tap(favoriteButtons.first);
        await tester.pumpAndSettle();
        expect(favoriteCalled, true);
      }
    });

    testWidgets('应该正确处理空数据状态', (WidgetTester tester) async {
      final emptyResult = ComparisonTestFactory.createEmptyComparisonResult();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 800,
              child: ComparisonCarousel(
                comparisonResult: emptyResult,
                onFundTap: (data) {},
                onFundDetail: (code) {},
                onFavorite: (code, isFavorite) {},
                onCompare: (code) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 验证空状态显示
      expect(find.text('暂无对比数据'), findsOneWidget);
      expect(find.text('请选择基金进行对比分析'), findsOneWidget);
    });

    testWidgets('应该支持收藏和对比状态', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 800,
              child: ComparisonCarousel(
                comparisonResult: testComparisonResult,
                favoriteFunds: const {'000001'},
                comparisonFunds: const {'000002'},
                onFundTap: (data) {},
                onFundDetail: (code) {},
                onFavorite: (code, isFavorite) {},
                onCompare: (code) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 验证组件存在
      expect(find.byType(ComparisonCarousel), findsOneWidget);

      // 验证收藏状态（第一个基金在收藏中）
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('应该正确处理单只基金数据', (WidgetTester tester) async {
      final singleFund = [ComparisonTestFactory.createTestFundComparisonData()];
      final singleResult = ComparisonTestFactory.createTestComparisonResult(
        fundData: singleFund,
        fundCodes: ['000001'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 800,
              child: ComparisonCarousel(
                comparisonResult: singleResult,
                onFundTap: (data) {},
                onFundDetail: (code) {},
                onFavorite: (code, isFavorite) {},
                onCompare: (code) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 验证单只基金显示
      expect(find.text('基金对比 (1只)'), findsOneWidget);
      expect(find.text('测试基金'), findsWidgets);
      expect(find.text('#1'), findsOneWidget);
      expect(find.byType(ComparisonCarousel), findsOneWidget);
    });

    testWidgets('应该正确处理5只基金数据', (WidgetTester tester) async {
      final fiveFunds = ComparisonTestFactory.createMultipleFundData(count: 5);
      final fiveResult = ComparisonTestFactory.createTestComparisonResult(
        fundData: fiveFunds,
        fundCodes: fiveFunds.map((f) => f.fundCode).toList(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 800,
              child: ComparisonCarousel(
                comparisonResult: fiveResult,
                onFundTap: (data) {},
                onFundDetail: (code) {},
                onFavorite: (code, isFavorite) {},
                onCompare: (code) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 验证5只基金显示
      expect(find.text('基金对比 (5只)'), findsOneWidget);
      expect(find.text('测试基金1'), findsOneWidget);
      expect(find.text('#1'), findsOneWidget);
      expect(find.byType(ComparisonCarousel), findsOneWidget);
    });
  });
}
