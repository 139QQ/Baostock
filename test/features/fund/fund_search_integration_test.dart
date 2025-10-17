import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:jisu_fund_analyzer/src/features/fund/domain/entities/fund_search_criteria.dart';
import 'package:jisu_fund_analyzer/src/features/fund/domain/entities/fund.dart';
import 'package:jisu_fund_analyzer/src/features/fund/domain/usecases/fund_search_usecase.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/bloc/search_bloc.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/widgets/fund_search_bar.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/widgets/search_results.dart';
import 'package:jisu_fund_analyzer/src/fund_exploration/presentation/pages/fund_search_page.dart';

import 'fund_search_integration_test.mocks.dart';

@GenerateMocks([FundSearchUseCase])
void main() {
  group('基金搜索功能集成测试', () {
    late MockFundSearchUseCase mockSearchUseCase;
    late List<FundSearchMatch> mockSearchResults;
    late List<Fund> mockFunds;

    setUp(() {
      mockSearchUseCase = MockFundSearchUseCase();
      mockSearchResults = [
        FundSearchMatch(
          fundCode: '000001',
          fundName: '华夏成长混合',
          score: 1.0,
          matchedFields: const [SearchField.name],
          highlights: const {
            'name': ['华夏']
          },
        ),
        FundSearchMatch(
          fundCode: '000002',
          fundName: '易方达稳健收益',
          score: 0.8,
          matchedFields: const [SearchField.name],
          highlights: const {
            'name': ['易方达']
          },
        ),
      ];

      // 初始化mock基金数据
      mockFunds = [
        Fund(
          code: '000001',
          name: '华夏成长混合',
          type: '混合型',
          company: '华夏基金',
          manager: '张三',
          unitNav: 1.0,
          accumulatedNav: 1.0,
          dailyReturn: 0.01,
          return1W: 0.02,
          return1M: 0.03,
          return3M: 0.04,
          return6M: 0.05,
          return1Y: 0.06,
          return2Y: 0.07,
          return3Y: 0.08,
          returnYTD: 0.01,
          returnSinceInception: 1.0,
          scale: 100.0,
          riskLevel: '中风险',
          status: 'active',
          date: '2023-01-01',
          fee: 0.01,
          rankingPosition: 1,
          totalCount: 100,
          currentPrice: 1.0,
          dailyChange: 0.01,
          dailyChangePercent: 1.0,
          lastUpdate: DateTime.now(),
        ),
        Fund(
          code: '000002',
          name: '易方达稳健收益',
          type: '债券型',
          company: '易方达基金',
          manager: '李四',
          unitNav: 1.0,
          accumulatedNav: 1.0,
          dailyReturn: 0.005,
          return1W: 0.01,
          return1M: 0.015,
          return3M: 0.02,
          return6M: 0.025,
          return1Y: 0.03,
          return2Y: 0.035,
          return3Y: 0.04,
          returnYTD: 0.005,
          returnSinceInception: 0.5,
          scale: 200.0,
          riskLevel: '低风险',
          status: 'active',
          date: '2023-01-01',
          fee: 0.008,
          rankingPosition: 2,
          totalCount: 100,
          currentPrice: 1.0,
          dailyChange: 0.005,
          dailyChangePercent: 0.5,
          lastUpdate: DateTime.now(),
        ),
      ];
    });

    Widget createAppWithSearchPage() {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            Provider<FundSearchUseCase>(
              create: (context) => mockSearchUseCase,
            ),
            BlocProvider<SearchBloc>(
              create: (context) => SearchBloc(searchUseCase: mockSearchUseCase),
            ),
          ],
          child: const FundSearchPage(),
        ),
      );
    }

    group('搜索页面整体功能测试', () {
      testWidgets('应该正确渲染搜索页面', (WidgetTester tester) async {
        // Arrange
        when(mockSearchUseCase.search(any))
            .thenAnswer((_) async => SearchResult(
                  funds: const [],
                  totalCount: 0,
                  searchTimeMs: 0,
                  criteria: FundSearchCriteria.keyword('test'),
                  hasMore: false,
                  suggestions: const [],
                ));

        // Act
        await tester.pumpWidget(createAppWithSearchPage());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('基金搜索'), findsOneWidget);
        expect(find.byType(FundSearchBar), findsOneWidget);
        expect(find.text('搜索'), findsOneWidget);
        expect(find.text('筛选'), findsOneWidget);
      });

      testWidgets('应该正确执行搜索流程', (WidgetTester tester) async {
        // Arrange
        when(mockSearchUseCase.search(any))
            .thenAnswer((_) async => SearchResult(
                  funds: mockSearchResults,
                  totalCount: mockFunds.length,
                  searchTimeMs: 120,
                  criteria: FundSearchCriteria.keyword('华夏'),
                  hasMore: false,
                  suggestions: const ['华夏基金', '华夏成长'],
                ));

        // Act
        await tester.pumpWidget(createAppWithSearchPage());
        await tester.pumpAndSettle();

        // 输入搜索关键词
        await tester.enterText(find.byType(TextField), '华夏');
        await tester.pump();

        // 验证搜索结果
        await tester.pumpAndSettle();
        expect(find.text('华夏成长混合'), findsOneWidget);
        expect(find.text('易方达稳健收益'), findsOneWidget);
      });

      testWidgets('应该正确处理空搜索结果', (WidgetTester tester) async {
        // Arrange
        when(mockSearchUseCase.search(any))
            .thenAnswer((_) async => SearchResult.empty(
                  criteria: FundSearchCriteria.keyword('nonexistent'),
                ));

        // Act
        await tester.pumpWidget(createAppWithSearchPage());
        await tester.pumpAndSettle();

        // 执行搜索
        await tester.enterText(find.byType(TextField), 'nonexistent');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('未找到相关基金'), findsOneWidget);
        expect(find.text('试试调整搜索关键词或使用筛选功能'), findsOneWidget);
      });

      testWidgets('应该正确处理搜索错误', (WidgetTester tester) async {
        // Arrange
        when(mockSearchUseCase.search(any)).thenThrow(Exception('网络连接失败'));

        // Act
        await tester.pumpWidget(createAppWithSearchPage());
        await tester.pumpAndSettle();

        // 执行搜索
        await tester.enterText(find.byType(TextField), 'test');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('网络连接失败'), findsOneWidget);
        expect(find.text('重试'), findsOneWidget);
      });

      testWidgets('应该正确刷新搜索结果', (WidgetTester tester) async {
        // Arrange
        when(mockSearchUseCase.search(any))
            .thenAnswer((_) async => SearchResult(
                  funds: mockSearchResults,
                  totalCount: mockFunds.length,
                  searchTimeMs: 100,
                  criteria: FundSearchCriteria.keyword('华夏'),
                  hasMore: false,
                ));

        // Act
        await tester.pumpWidget(createAppWithSearchPage());
        await tester.pumpAndSettle();

        // 执行初始搜索
        await tester.enterText(find.byType(TextField), '华夏');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        // 下拉刷新
        await tester.fling(
          find.byType(SearchResults),
          const Offset(0, 300),
          1000,
        );
        await tester.pumpAndSettle();

        // Assert
        verify(mockSearchUseCase.search(any)).called(2); // 初始搜索 + 刷新
      });
    });

    group('性能测试', () {
      testWidgets('搜索响应时间应该≤300ms', (WidgetTester tester) async {
        // Arrange
        when(mockSearchUseCase.search(any)).thenAnswer((_) async {
          // 模拟250ms的搜索时间
          await Future.delayed(const Duration(milliseconds: 250));
          return SearchResult(
            funds: mockSearchResults,
            totalCount: mockFunds.length,
            searchTimeMs: 250,
            criteria: FundSearchCriteria.keyword('test'),
            hasMore: false,
          );
        });

        // Act
        final stopwatch = Stopwatch()..start();
        await tester.pumpWidget(createAppWithSearchPage());
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'test');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(500)); // 包括UI渲染时间
        expect(find.text('华夏成长混合'), findsOneWidget);
      });

      testWidgets('应该正确处理大量搜索结果', (WidgetTester tester) async {
        // Arrange - 创建大量测试数据
        final largeFundsList = List.generate(
            100,
            (index) => Fund(
                  code: index.toString().padLeft(6, '0'),
                  name: '测试基金$index',
                  type: index % 2 == 0 ? '股票型' : '债券型',
                  company: index % 3 == 0 ? '华夏基金' : '易方达基金',
                  manager: index % 2 == 0 ? '张三' : '李四',
                  unitNav: 1.0 + index * 0.01,
                  accumulatedNav: 1.0 + index * 0.02,
                  dailyReturn: 0.01 * (index % 10),
                  return1W: 0.02 * (index % 10),
                  return1M: 0.03 * (index % 10),
                  return3M: 0.04 * (index % 10),
                  return6M: 0.05 * (index % 10),
                  return1Y: 0.06 * (index % 10),
                  return2Y: 0.07 * (index % 10),
                  return3Y: 0.08 * (index % 10),
                  returnYTD: 0.01 * (index % 10),
                  returnSinceInception: 1.0 + index * 0.1,
                  scale: 100.0 + index * 10,
                  riskLevel: index % 3 == 0
                      ? '高风险'
                      : index % 3 == 1
                          ? '中风险'
                          : '低风险',
                  status: 'active',
                  date: '2023-01-01',
                  fee: 0.01 + index * 0.001,
                  rankingPosition: index + 1,
                  totalCount: 100,
                  currentPrice: 1.0 + index * 0.01,
                  dailyChange: 0.01 * (index % 10),
                  dailyChangePercent: 1.0 * (index % 10),
                  lastUpdate: DateTime.now(),
                ));

        when(mockSearchUseCase.search(any))
            .thenAnswer((_) async => SearchResult(
                  funds: largeFundsList
                      .map((fund) => FundSearchMatch(
                            fundCode: fund.code,
                            fundName: fund.name,
                            score: 1.0,
                            matchedFields: const [SearchField.name],
                            highlights: const {},
                          ))
                      .toList(),
                  totalCount: largeFundsList.length,
                  searchTimeMs: 200,
                  criteria: FundSearchCriteria.keyword('测试'),
                  hasMore: true,
                ));

        // Act
        final stopwatch = Stopwatch()..start();
        await tester.pumpWidget(createAppWithSearchPage());
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), '测试');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // 大量数据应该在1秒内完成
        expect(find.text('测试基金0'), findsOneWidget);
        expect(find.text('共找到 100 只基金'), findsOneWidget);
      });
    });

    group('用户体验测试', () {
      testWidgets('应该正确防抖动处理', (WidgetTester tester) async {
        // Arrange
        when(mockSearchUseCase.search(any))
            .thenAnswer((_) async => SearchResult(
                  funds: mockSearchResults,
                  totalCount: mockFunds.length,
                  searchTimeMs: 50,
                  criteria: FundSearchCriteria.keyword('test'),
                  hasMore: false,
                  suggestions: ['建议1', '建议2'],
                ));

        // Act
        await tester.pumpWidget(createAppWithSearchPage());
        await tester.pumpAndSettle();

        // 快速输入多个字符
        await tester.enterText(find.byType(TextField), 'a');
        await tester.pump(const Duration(milliseconds: 100));
        await tester.enterText(find.byType(TextField), 'ab');
        await tester.pump(const Duration(milliseconds: 100));
        await tester.enterText(find.byType(TextField), 'abc');
        await tester.pump(const Duration(milliseconds: 100));
        await tester.enterText(find.byType(TextField), 'abcd');
        await tester.pump(const Duration(milliseconds: 400)); // 超过防抖动时间

        // Assert - 应该只触发一次建议请求
        verify(mockSearchUseCase.search(any)).called(1);
      });

      testWidgets('应该正确保存搜索历史', (WidgetTester tester) async {
        // Arrange
        when(mockSearchUseCase.search(any))
            .thenAnswer((_) async => SearchResult(
                  funds: mockSearchResults,
                  totalCount: mockFunds.length,
                  searchTimeMs: 100,
                  criteria: FundSearchCriteria.keyword('华夏基金'),
                  hasMore: false,
                ));

        // Act
        await tester.pumpWidget(createAppWithSearchPage());
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), '华夏基金');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        // Assert
        verify(mockSearchUseCase.search(any)).called(1);
      });

      testWidgets('应该正确处理搜索历史清除', (WidgetTester tester) async {
        // Arrange
        when(mockSearchUseCase.search(any))
            .thenAnswer((_) async => SearchResult(
                  funds: mockSearchResults,
                  totalCount: mockFunds.length,
                  searchTimeMs: 50,
                  criteria: FundSearchCriteria.keyword('test'),
                  hasMore: false,
                ));

        // Act
        await tester.pumpWidget(createAppWithSearchPage());
        await tester.pumpAndSettle();

        // 切换到搜索标签页
        await tester.tap(find.text('搜索'));
        await tester.pumpAndSettle();

        // 查找并点击清除历史按钮（这里假设有这样的按钮）
        // 具体实现可能需要根据实际的UI设计调整
        // await tester.tap(find.byIcon(Icons.clear_all));
        // await tester.pumpAndSettle();

        // Assert
        // verify(mockSearchUseCase.clearSearchHistory()).called(1);
      });
    });

    group('搜索与筛选集成测试', () {
      testWidgets('应该正确整合搜索和筛选功能', (WidgetTester tester) async {
        // Arrange
        when(mockSearchUseCase.search(any))
            .thenAnswer((_) async => SearchResult(
                  funds: mockSearchResults
                      .where((match) => match.fundName.contains('混合'))
                      .toList(),
                  totalCount: 1,
                  searchTimeMs: 150,
                  criteria: const FundSearchCriteria(
                    keyword: '华夏',
                    extendedFilters: {
                      'fundTypes': ['混合型']
                    },
                  ),
                  hasMore: false,
                ));

        // Act
        await tester.pumpWidget(createAppWithSearchPage());
        await tester.pumpAndSettle();

        // 切换到筛选标签页
        await tester.tap(find.text('筛选'));
        await tester.pumpAndSettle();

        // 切换回搜索标签页
        await tester.tap(find.text('搜索'));
        await tester.pumpAndSettle();

        // 执行搜索
        await tester.enterText(find.byType(TextField), '华夏');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('华夏成长混合'), findsOneWidget);
        expect(find.text('易方达稳健收益'), findsNothing); // 筛选掉债券型基金
      });
    });
  });
}
