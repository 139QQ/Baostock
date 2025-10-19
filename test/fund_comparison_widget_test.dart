import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../lib/src/features/fund/domain/entities/multi_dimensional_comparison_criteria.dart';
import '../lib/src/features/fund/presentation/widgets/comparison_selector.dart';
import '../lib/src/features/fund/presentation/widgets/comparison_table.dart';
import '../lib/src/features/fund/presentation/widgets/comparison_statistics.dart';
import '../lib/src/features/fund/presentation/cubit/fund_comparison_cubit.dart';
import '../lib/src/features/fund/domain/entities/fund_ranking.dart';
import '../lib/src/features/fund/domain/entities/comparison_result.dart';

/// 基金对比UI组件测试
///
/// 验证表格渲染和交互功能
void main() {
  group('基金对比UI组件测试', () {
    late List<FundRanking> testFunds;
    late ComparisonResult testResult;

    setUp(() {
      testFunds = _createTestFunds();
      testResult = _createTestResult();
    });

    testWidgets('ComparisonSelector组件渲染测试', (WidgetTester tester) async {
      // Given
      const criteria = MultiDimensionalComparisonCriteria(
        fundCodes: ['000001', '000002'],
        periods: [RankingPeriod.oneYear],
        metric: ComparisonMetric.totalReturn,
      );

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComparisonSelector(
              availableFunds: testFunds,
              initialCriteria: criteria,
              onCriteriaChanged: (newCriteria) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Then
      expect(find.text('基金对比'), findsOneWidget);
      expect(find.text('已选择: 2只基金'), findsOneWidget);
      expect(find.byType(FilterChip), findsWidgets);
    });

    testWidgets('ComparisonTable组件渲染测试', (WidgetTester tester) async {
      // Given
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComparisonTable(
              result: testResult,
              sortBy: ComparisonSortBy.totalReturn,
              onSortChanged: (sortBy) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Then
      expect(find.text('基金代码'), findsOneWidget);
      expect(find.text('基金名称'), findsOneWidget);
      expect(find.text('累计收益率'), findsOneWidget);
      expect(find.text('华夏成长混合'), findsOneWidget);
      expect(find.text('易方达蓝筹'), findsOneWidget);
      expect(find.byType(DataRow), findsNWidgets(2)); // 2行数据
    });

    testWidgets('ComparisonTable排序功能测试', (WidgetTester tester) async {
      // Given
      ComparisonSortBy? currentSortBy;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComparisonTable(
              result: testResult,
              sortBy: ComparisonSortBy.totalReturn,
              onSortChanged: (sortBy) {
                currentSortBy = sortBy;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When - 点击收益率排序
      await tester.tap(find.text('累计收益率'));
      await tester.pumpAndSettle();

      // Then
      expect(currentSortBy, equals(ComparisonSortBy.totalReturn));
    });

    testWidgets('ComparisonStatistics组件渲染测试', (WidgetTester tester) async {
      // Given
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComparisonStatistics(
              statistics: testResult.statistics,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Then
      expect(find.text('统计信息'), findsOneWidget);
      expect(find.text('平均收益率'), findsOneWidget);
      expect(find.text('最高收益率'), findsOneWidget);
      expect(find.text('最低收益率'), findsOneWidget);
      expect(find.text('20.0%'), findsOneWidget); // 平均收益率
      expect(find.text('25.0%'), findsOneWidget); // 最高收益率
      expect(find.text('15.0%'), findsOneWidget); // 最低收益率
    });

    testWidgets('空状态处理测试', (WidgetTester tester) async {
      // Given - 空结果
      final emptyResult = ComparisonResult(
        criteria: const MultiDimensionalComparisonCriteria(
          fundCodes: ['000001'],
          periods: [RankingPeriod.oneYear],
        ),
        fundData: [],
        statistics: ComparisonStatistics(
          averageReturn: 0.0,
          maxReturn: 0.0,
          minReturn: 0.0,
          returnStdDev: 0.0,
          averageVolatility: 0.0,
          maxVolatility: 0.0,
          minVolatility: 0.0,
          averageSharpeRatio: 0.0,
          correlationMatrix: {},
          updatedAt: DateTime.now(),
        ),
        calculatedAt: DateTime.now(),
      );

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComparisonTable(
              result: emptyResult,
              sortBy: ComparisonSortBy.totalReturn,
              onSortChanged: (sortBy) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Then
      expect(find.text('暂无对比数据'), findsOneWidget);
    });

    testWidgets('错误状态处理测试', (WidgetTester tester) async {
      // Given - 错误结果
      final errorResult = ComparisonResult(
        criteria: const MultiDimensionalComparisonCriteria(
          fundCodes: ['000001', '000002'],
          periods: [RankingPeriod.oneYear],
        ),
        fundData: [],
        statistics: ComparisonStatistics(
          averageReturn: 0.0,
          maxReturn: 0.0,
          minReturn: 0.0,
          returnStdDev: 0.0,
          averageVolatility: 0.0,
          maxVolatility: 0.0,
          minVolatility: 0.0,
          averageSharpeRatio: 0.0,
          correlationMatrix: {},
          updatedAt: DateTime.now(),
        ),
        calculatedAt: DateTime.now(),
        hasError: true,
        errorMessage: '网络连接失败',
      );

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComparisonTable(
              result: errorResult,
              sortBy: ComparisonSortBy.totalReturn,
              onSortChanged: (sortBy) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Then
      expect(find.text('加载失败'), findsOneWidget);
      expect(find.text('网络连接失败'), findsOneWidget);
    });

    testWidgets('响应式布局测试', (WidgetTester tester) async {
      // Given - 测试不同屏幕尺寸
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComparisonTable(
              result: testResult,
              sortBy: ComparisonSortBy.totalReturn,
              onSortChanged: (sortBy) {},
            ),
          ),
        ),
      );

      // When - 设置小屏幕尺寸
      await tester.binding.setSurfaceSize(const Size(300, 600));
      await tester.pumpAndSettle();

      // Then - 应该正常渲染
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.byType(DataRow), findsNWidgets(2));
    });
  });
}

/// 创建测试基金数据
List<FundRanking> _createTestFunds() {
  return [
    FundRanking(
      fundCode: '000001',
      fundName: '华夏成长混合',
      fundType: '混合型',
      company: '华夏基金',
      rankingPosition: 1,
      totalCount: 100,
      unitNav: 2.5,
      accumulatedNav: 3.0,
      dailyReturn: 0.01,
      return1W: 0.02,
      return1M: 0.05,
      return3M: 0.12,
      return6M: 0.18,
      return1Y: 0.25,
      return2Y: 0.40,
      return3Y: 0.60,
      returnYTD: 0.08,
      returnSinceInception: 2.0,
      rankingDate: DateTime.now(),
      rankingType: RankingType.overall,
      rankingPeriod: RankingPeriod.oneYear,
    ),
    FundRanking(
      fundCode: '000002',
      fundName: '易方达蓝筹',
      fundType: '股票型',
      company: '易方达基金',
      rankingPosition: 2,
      totalCount: 100,
      unitNav: 1.8,
      accumulatedNav: 2.2,
      dailyReturn: 0.005,
      return1W: 0.01,
      return1M: 0.03,
      return3M: 0.08,
      return6M: 0.14,
      return1Y: 0.15,
      return2Y: 0.35,
      return3Y: 0.50,
      returnYTD: 0.06,
      returnSinceInception: 1.2,
      rankingDate: DateTime.now(),
      rankingType: RankingType.overall,
      rankingPeriod: RankingPeriod.oneYear,
    ),
  ];
}

/// 创建测试对比结果
ComparisonResult _createTestResult() {
  const criteria = MultiDimensionalComparisonCriteria(
    fundCodes: ['000001', '000002'],
    periods: [RankingPeriod.oneYear],
    metric: ComparisonMetric.totalReturn,
  );

  final fundData = [
    FundComparisonData(
      fundCode: '000001',
      fundName: '华夏成长混合',
      fundType: '混合型',
      period: RankingPeriod.oneYear,
      totalReturn: 0.25,
      annualizedReturn: 0.25,
      volatility: 0.20,
      sharpeRatio: 1.25,
      maxDrawdown: -0.15,
      ranking: 1,
      categoryAverage: 0.15,
      beatCategoryPercent: 66.7,
      benchmarkReturn: 0.12,
      beatBenchmarkPercent: 108.3,
    ),
    FundComparisonData(
      fundCode: '000002',
      fundName: '易方达蓝筹',
      fundType: '股票型',
      period: RankingPeriod.oneYear,
      totalReturn: 0.15,
      annualizedReturn: 0.15,
      volatility: 0.22,
      sharpeRatio: 0.68,
      maxDrawdown: -0.18,
      ranking: 2,
      categoryAverage: 0.18,
      beatCategoryPercent: -16.7,
      benchmarkReturn: 0.12,
      beatBenchmarkPercent: 25.0,
    ),
  ];

  final statistics = ComparisonStatistics(
    averageReturn: 0.20,
    maxReturn: 0.25,
    minReturn: 0.15,
    returnStdDev: 0.05,
    averageVolatility: 0.21,
    maxVolatility: 0.22,
    minVolatility: 0.20,
    averageSharpeRatio: 0.965,
    correlationMatrix: {
      '000001': {'000001': 1.0, '000002': 0.65},
      '000002': {'000001': 0.65, '000002': 1.0},
    },
    updatedAt: DateTime.now(),
  );

  return ComparisonResult(
    criteria: criteria,
    fundData: fundData,
    statistics: statistics,
    calculatedAt: DateTime.now(),
  );
}
