import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:jisu_fund_analyzer/src/features/portfolio/presentation/pages/portfolio_analysis_page.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/presentation/cubit/portfolio_analysis_cubit.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/presentation/cubit/portfolio_analysis_state.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/presentation/cubit/fund_favorite_cubit.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/entities/portfolio_holding.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/entities/portfolio_profit_calculation_criteria.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/fund_favorite/src/entities/fund_favorite.dart';
import 'package:jisu_fund_analyzer/src/core/di/injection_container.dart';

import 'portfolio_analysis_page_test.mocks.dart';

// 简单的模拟对话框类，用于测试
class _ImportFromFavoritesDialog extends StatelessWidget {
  final Function(List<Map<String, dynamic>>) onImport;

  const _ImportFromFavoritesDialog({
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('导入自选基金'),
      content: const Text('模拟导入对话框'),
      actions: [
        TextButton(
          onPressed: () {
            onImport([]);
            Navigator.of(context).pop();
          },
          child: const Text('导入'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('取消'),
        ),
      ],
    );
  }
}

@GenerateMocks([PortfolioAnalysisCubit, FundFavoriteCubit])
void main() {
  group('PortfolioAnalysisPage Tests', () {
    late MockPortfolioAnalysisCubit mockCubit;
    late MockFundFavoriteCubit mockFavoriteCubit;

    setUp(() {
      mockCubit = MockPortfolioAnalysisCubit();
      mockFavoriteCubit = MockFundFavoriteCubit();

      // Mock the service locator
      sl.reset();
      sl.registerSingleton<FundFavoriteCubit>(mockFavoriteCubit);
    });

    tearDown(() {
      sl.reset();
    });

    Widget createWidgetUnderTest() {
      return MaterialApp(
        home: BlocProvider<PortfolioAnalysisCubit>(
          create: (_) => mockCubit,
          child: const PortfolioAnalysisPage(),
        ),
      );
    }

    testWidgets('should display loading state initially',
        (WidgetTester tester) async {
      // Arrange
      final loadingState = PortfolioAnalysisState.loading();
      when(mockCubit.state).thenReturn(loadingState);
      when(mockCubit.stream).thenAnswer((_) => Stream.value(loadingState));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('加载中...'), findsOneWidget);
      expect(find.text('持仓分析'), findsOneWidget);
    });

    testWidgets('should display no data view when no holdings',
        (WidgetTester tester) async {
      // Arrange
      final emptyState = PortfolioAnalysisState.noData();
      when(mockCubit.state).thenReturn(emptyState);
      when(mockCubit.stream).thenAnswer((_) => Stream.value(emptyState));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('暂无持仓数据'), findsOneWidget);
      expect(find.text('请先添加持仓后再查看收益分析'), findsOneWidget);
      expect(find.text('添加持仓'), findsOneWidget);
      expect(find.byIcon(Icons.analytics_outlined), findsOneWidget);
    });

    testWidgets('should display loaded view with holdings data',
        (WidgetTester tester) async {
      // Arrange
      final testHoldings = [
        createTestPortfolioHolding('000001', '华夏成长混合', 1000.0, 1.2, 1.5),
        createTestPortfolioHolding('110022', '易方达消费行业', 500.0, 2.1, 2.3),
      ];

      final loadedState = PortfolioAnalysisState.loaded(
        holdings: testHoldings,
        currentCriteria: PortfolioProfitCalculationCriteria.basic(),
      );
      when(mockCubit.state).thenReturn(loadedState);
      when(mockCubit.stream).thenAnswer((_) => Stream.value(loadedState));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('持仓分析'), findsOneWidget);
      expect(find.text('深度分析您的投资组合表现'), findsOneWidget);
      expect(find.text('持仓概览'), findsOneWidget);
      expect(find.text('总资产'), findsOneWidget);
      expect(find.text('今日收益'), findsOneWidget);
      expect(find.text('累计收益'), findsOneWidget);
    });

    testWidgets('should display error view when error occurs',
        (WidgetTester tester) async {
      // Arrange
      final errorState = PortfolioAnalysisState.error('网络连接失败');
      when(mockCubit.state).thenReturn(errorState);
      when(mockCubit.stream).thenAnswer((_) => Stream.value(errorState));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('加载失败'), findsOneWidget);
      expect(find.text('网络连接失败'), findsOneWidget);
      expect(find.text('重试'), findsOneWidget);
      expect(find.text('添加持仓'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('should show portfolio manager when edit button is tapped',
        (WidgetTester tester) async {
      // Arrange
      final loadedState = PortfolioAnalysisState.loaded(
        holdings: [
          createTestPortfolioHolding('000001', '华夏成长', 1000, 1.2, 1.5)
        ],
        currentCriteria: PortfolioProfitCalculationCriteria.basic(),
      );
      when(mockCubit.state).thenReturn(loadedState);
      when(mockCubit.stream).thenAnswer((_) => Stream.value(loadedState));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('管理持仓'), findsOneWidget);
    });

    testWidgets('should show import dialog when download button is tapped',
        (WidgetTester tester) async {
      // Arrange
      final loadedState = PortfolioAnalysisState.loaded(
        holdings: [],
        currentCriteria: PortfolioProfitCalculationCriteria.basic(),
      );
      when(mockCubit.state).thenReturn(loadedState);
      when(mockCubit.stream).thenAnswer((_) => Stream.value(loadedState));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.download));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('从自选基金导入'), findsOneWidget);
      expect(find.text('导入设置'), findsOneWidget);
      expect(find.text('默认持有份额'), findsOneWidget);
    });

    testWidgets('should trigger refresh when refresh button is tapped',
        (WidgetTester tester) async {
      // Arrange
      final loadedState = PortfolioAnalysisState.loaded(
        holdings: [],
        currentCriteria: PortfolioProfitCalculationCriteria.basic(),
      );
      when(mockCubit.state).thenReturn(loadedState);
      when(mockCubit.stream).thenAnswer((_) => Stream.value(loadedState));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      // Assert
      verify(mockCubit.refreshData()).called(1);
    });

    testWidgets('should display asset distribution section',
        (WidgetTester tester) async {
      // Arrange
      final loadedState = PortfolioAnalysisState(
        isLoading: false,
        holdings: [
          createTestPortfolioHolding('000001', '华夏成长混合', 1000, 1.2, 1.5),
        ],
        error: null,
        currentCriteria: PortfolioProfitCalculationCriteria.basic(),
        lastUpdated: DateTime.now(),
      );
      when(mockCubit.state).thenReturn(loadedState);
      when(mockCubit.stream).thenAnswer((_) => Stream.value(loadedState));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('资产分布'), findsOneWidget);
      expect(find.text('资产分布图'), findsOneWidget);
      expect(find.text('股票基金'), findsOneWidget);
      expect(find.text('债券基金'), findsOneWidget);
      expect(find.text('货币基金'), findsOneWidget);
      expect(find.text('混合基金'), findsOneWidget);
    });

    testWidgets('should display risk assessment section',
        (WidgetTester tester) async {
      // Arrange
      final loadedState = PortfolioAnalysisState(
        isLoading: false,
        holdings: [
          createTestPortfolioHolding('000001', '华夏成长混合', 1000, 1.2, 1.5),
        ],
        error: null,
        currentCriteria: PortfolioProfitCalculationCriteria.basic(),
        lastUpdated: DateTime.now(),
      );
      when(mockCubit.state).thenReturn(loadedState);
      when(mockCubit.stream).thenAnswer((_) => Stream.value(loadedState));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('风险评估'), findsOneWidget);
      expect(find.text('中等风险'), findsOneWidget);
      expect(find.text('建议适度调整股票仓位'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber), findsOneWidget);
    });

    testWidgets('should handle retry functionality',
        (WidgetTester tester) async {
      // Arrange
      final errorState = PortfolioAnalysisState.error('网络连接失败');
      when(mockCubit.state).thenReturn(errorState);
      when(mockCubit.stream).thenAnswer((_) => Stream.value(errorState));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('重试'));
      await tester.pump();

      // Assert
      verify(mockCubit.initializeAnalysis()).called(1);
    });

    testWidgets(
        'should trigger navigation to portfolio manager from no data view',
        (WidgetTester tester) async {
      // Arrange
      final emptyState = PortfolioAnalysisState.noData();
      when(mockCubit.state).thenReturn(emptyState);
      when(mockCubit.stream).thenAnswer((_) => Stream.value(emptyState));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('添加持仓'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('管理持仓'), findsOneWidget);
    });

    testWidgets('should handle pull to refresh', (WidgetTester tester) async {
      // Arrange
      final loadedState = PortfolioAnalysisState.loaded(
        holdings: [
          createTestPortfolioHolding('000001', '华夏成长', 1000, 1.2, 1.5)
        ],
        currentCriteria: PortfolioProfitCalculationCriteria.basic(),
      );
      when(mockCubit.state).thenReturn(loadedState);
      when(mockCubit.stream).thenAnswer((_) => Stream.value(loadedState));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // 执行下拉刷新
      await tester.fling(
        find.byType(RefreshIndicator),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();

      // Assert
      verify(mockCubit.refreshData()).called(1);
    });
  });

  group('ImportFromFavoritesDialog Tests', () {
    late MockPortfolioAnalysisCubit mockCubit;
    late MockFundFavoriteCubit mockFavoriteCubit;

    setUp(() {
      mockCubit = MockPortfolioAnalysisCubit();
      mockFavoriteCubit = MockFundFavoriteCubit();
      sl.reset();
      sl.registerSingleton<FundFavoriteCubit>(mockFavoriteCubit);
    });

    tearDown(() {
      sl.reset();
    });

    Widget createWidgetWithDialog() {
      return MaterialApp(
        home: BlocProvider<PortfolioAnalysisCubit>(
          create: (_) => mockCubit,
          child: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => _ImportFromFavoritesDialog(
                    onImport: (holdings) {
                      // Mock import action
                    },
                  ),
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('should display import dialog with settings',
        (WidgetTester tester) async {
      // Arrange
      final testFavorites = [
        createTestFundFavorite('000001', '华夏成长混合', '混合型'),
        createTestFundFavorite('110022', '易方达消费行业', '股票型'),
      ];

      when(mockFavoriteCubit.loadAllFavorites()).thenAnswer((_) async {});
      when(mockFavoriteCubit.state).thenReturn(FundFavoriteLoaded(
        favorites: testFavorites,
        searchResults: testFavorites,
        favoriteStatusCache: const {'000001': true, '110022': true},
      ));
      when(mockFavoriteCubit.stream)
          .thenAnswer((_) => Stream.value(FundFavoriteLoaded(
                favorites: testFavorites,
                searchResults: testFavorites,
                favoriteStatusCache: const {'000001': true, '110022': true},
              )));

      // Act
      await tester.pumpWidget(createWidgetWithDialog());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('从自选基金导入'), findsOneWidget);
      expect(find.text('导入设置'), findsOneWidget);
      expect(find.text('默认持有份额'), findsOneWidget);
      expect(find.text('使用当前净值作为成本'), findsOneWidget);
    });

    testWidgets('should display favorites list in import dialog',
        (WidgetTester tester) async {
      // Arrange
      final testFavorites = [
        createTestFundFavorite('000001', '华夏成长混合', '混合型'),
        createTestFundFavorite('110022', '易方达消费行业', '股票型'),
      ];

      when(mockFavoriteCubit.loadAllFavorites()).thenAnswer((_) async {});
      when(mockFavoriteCubit.state).thenReturn(FundFavoriteLoaded(
        favorites: testFavorites,
        searchResults: testFavorites,
        favoriteStatusCache: const {'000001': true, '110022': true},
      ));
      when(mockFavoriteCubit.stream)
          .thenAnswer((_) => Stream.value(FundFavoriteLoaded(
                favorites: testFavorites,
                searchResults: testFavorites,
                favoriteStatusCache: const {'000001': true, '110022': true},
              )));

      // Act
      await tester.pumpWidget(createWidgetWithDialog());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('000001 - 华夏成长混合'), findsOneWidget);
      expect(find.text('110022 - 易方达消费行业'), findsOneWidget);
      expect(find.text('混合型'), findsOneWidget);
      expect(find.text('股票型'), findsOneWidget);
    });

    testWidgets('should handle select all functionality',
        (WidgetTester tester) async {
      // Arrange
      final testFavorites = [
        createTestFundFavorite('000001', '华夏成长混合', '混合型'),
        createTestFundFavorite('110022', '易方达消费行业', '股票型'),
      ];

      when(mockFavoriteCubit.loadAllFavorites()).thenAnswer((_) async {});
      when(mockFavoriteCubit.state).thenReturn(FundFavoriteLoaded(
        favorites: testFavorites,
        searchResults: testFavorites,
        favoriteStatusCache: const {'000001': true, '110022': true},
      ));
      when(mockFavoriteCubit.stream)
          .thenAnswer((_) => Stream.value(FundFavoriteLoaded(
                favorites: testFavorites,
                searchResults: testFavorites,
                favoriteStatusCache: const {'000001': true, '110022': true},
              )));

      // Act
      await tester.pumpWidget(createWidgetWithDialog());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // 测试全选
      await tester.tap(find.text('全选'));
      await tester.pump();

      // Assert
      expect(find.text('已选择 2/2 只'), findsOneWidget);

      // 测试取消全选
      await tester.tap(find.text('取消全选'));
      await tester.pump();

      // Assert
      expect(find.text('已选择 0/2 只'), findsOneWidget);
    });

    testWidgets('should validate import selection',
        (WidgetTester tester) async {
      // Arrange
      when(mockFavoriteCubit.loadAllFavorites()).thenAnswer((_) async {});
      when(mockFavoriteCubit.state).thenReturn(const FundFavoriteLoaded(
        favorites: [],
        searchResults: [],
        favoriteStatusCache: {},
      ));
      when(mockFavoriteCubit.stream)
          .thenAnswer((_) => Stream.value(const FundFavoriteLoaded(
                favorites: [],
                searchResults: [],
                favoriteStatusCache: {},
              )));

      // Act
      await tester.pumpWidget(createWidgetWithDialog());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // 不选择任何基金尝试导入
      await tester.tap(find.text('导入 0 只基金'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('请选择要导入的基金'), findsOneWidget);
    });

    testWidgets('should update default amount input',
        (WidgetTester tester) async {
      // Arrange
      when(mockFavoriteCubit.loadAllFavorites()).thenAnswer((_) async {});
      when(mockFavoriteCubit.state).thenReturn(FundFavoriteLoaded(
        favorites: [createTestFundFavorite('000001', '华夏成长', '混合型')],
        searchResults: [createTestFundFavorite('000001', '华夏成长', '混合型')],
        favoriteStatusCache: const {'000001': true},
      ));
      when(mockFavoriteCubit.stream)
          .thenAnswer((_) => Stream.value(FundFavoriteLoaded(
                favorites: [createTestFundFavorite('000001', '华夏成长', '混合型')],
                searchResults: [
                  createTestFundFavorite('000001', '华夏成长', '混合型')
                ],
                favoriteStatusCache: const {'000001': true},
              )));

      // Act
      await tester.pumpWidget(createWidgetWithDialog());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // 修改默认份额
      await tester.enterText(find.byType(TextField).first, '2000');
      await tester.pump();

      // Assert
      expect(find.text('2000'), findsOneWidget);
    });
  });
}

// 测试辅助函数
PortfolioHolding createTestPortfolioHolding(
  String code,
  String name,
  double amount,
  double costNav,
  double currentNav,
) {
  return PortfolioHolding(
    fundCode: code,
    fundName: name,
    fundType: '混合型',
    holdingAmount: amount,
    costNav: costNav,
    costValue: amount * costNav,
    marketValue: amount * currentNav,
    currentNav: currentNav,
    accumulatedNav: currentNav,
    holdingStartDate: DateTime.now().subtract(const Duration(days: 30)),
    lastUpdatedDate: DateTime.now(),
    status: HoldingStatus.active,
  );
}

FundFavorite createTestFundFavorite(
  String code,
  String name,
  String type, {
  double? currentNav,
}) {
  return FundFavorite(
    fundCode: code,
    fundName: name,
    fundType: type,
    fundManager: '测试基金公司',
    addedAt: DateTime.now().subtract(const Duration(days: 1)),
    updatedAt: DateTime.now(),
    currentNav: currentNav ?? 1.2345,
    dailyChange: 1.23,
    notes: '测试备注',
  );
}
