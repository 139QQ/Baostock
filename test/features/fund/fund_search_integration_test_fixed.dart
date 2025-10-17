import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:jisu_fund_analyzer/src/features/fund/domain/entities/fund_search_criteria.dart';
import 'package:jisu_fund_analyzer/src/features/fund/domain/usecases/fund_search_usecase.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/bloc/search_bloc.dart';
import 'package:jisu_fund_analyzer/src/fund_exploration/presentation/pages/fund_search_page.dart';

import 'fund_search_integration_test.mocks.dart';

@GenerateMocks([FundSearchUseCase])
void main() {
  group('基金搜索功能基本测试', () {
    late MockFundSearchUseCase mockSearchUseCase;

    setUp(() {
      mockSearchUseCase = MockFundSearchUseCase();
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

    testWidgets('应该正确渲染搜索页面', (WidgetTester tester) async {
      // Arrange
      when(mockSearchUseCase.search(any)).thenAnswer((_) async => SearchResult(
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
      expect(find.text('搜索'), findsOneWidget);
      expect(find.text('筛选'), findsOneWidget);
    });

    testWidgets('应该正确执行搜索功能', (WidgetTester tester) async {
      // Arrange
      when(mockSearchUseCase.search(any)).thenAnswer((_) async => SearchResult(
            funds: const [],
            totalCount: 0,
            searchTimeMs: 120,
            criteria: FundSearchCriteria.keyword('华夏'),
            hasMore: false,
            suggestions: const ['华夏基金'],
          ));

      // Act
      await tester.pumpWidget(createAppWithSearchPage());
      await tester.pumpAndSettle();

      // 查找搜索输入框
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      // 输入搜索关键词
      await tester.enterText(searchField, '华夏');
      await tester.pump();

      // 模拟按下回车键
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Assert
      verify(mockSearchUseCase.search(any)).called(greaterThanOrEqualTo(1));
    });

    testWidgets('应该正确处理搜索错误', (WidgetTester tester) async {
      // Arrange
      when(mockSearchUseCase.search(any)).thenThrow(Exception('网络连接失败'));

      // Act
      await tester.pumpWidget(createAppWithSearchPage());
      await tester.pumpAndSettle();

      // 查找搜索输入框
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      // 输入搜索关键词
      await tester.enterText(searchField, 'test');
      await tester.pump();

      // 模拟按下回车键
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Assert
      verify(mockSearchUseCase.search(any)).called(greaterThanOrEqualTo(1));
    });
  });
}
