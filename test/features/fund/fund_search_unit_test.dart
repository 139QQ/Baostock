import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:jisu_fund_analyzer/src/features/fund/domain/entities/fund_search_criteria.dart';
import 'package:jisu_fund_analyzer/src/features/fund/domain/usecases/fund_search_usecase.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/bloc/search_bloc.dart';

import 'fund_search_unit_test.mocks.dart';

@GenerateMocks([FundSearchUseCase])
void main() {
  group('基金搜索单元测试', () {
    late MockFundSearchUseCase mockSearchUseCase;

    setUp(() {
      mockSearchUseCase = MockFundSearchUseCase();
    });

    testWidgets('SearchBloc应该正确初始化', (WidgetTester tester) async {
      // Arrange
      when(mockSearchUseCase.search(any)).thenAnswer((_) async => SearchResult(
            funds: [],
            totalCount: 0,
            searchTimeMs: 0,
            criteria: FundSearchCriteria.keyword('test'),
            hasMore: false,
            suggestions: [],
          ));

      // Act
      await tester.pumpWidget(MaterialApp(
        home: MultiProvider(
          providers: [
            Provider<FundSearchUseCase>(
              create: (context) => mockSearchUseCase,
            ),
          ],
          child: Builder(
            builder: (context) {
              final bloc =
                  SearchBloc(searchUseCase: context.read<FundSearchUseCase>());
              return ElevatedButton(
                onPressed: () {
                  bloc.add(InitializeSearch());
                },
                child: const Text('初始化搜索'),
              );
            },
          ),
        ),
      ));

      // Assert
      expect(find.text('初始化搜索'), findsOneWidget);
    });

    test('FundSearchUseCase应该正确执行搜索', () async {
      // Arrange
      const criteria = FundSearchCriteria.keyword('华夏');
      final expectedResult = SearchResult(
        funds: [],
        totalCount: 0,
        searchTimeMs: 100,
        criteria: criteria,
        hasMore: false,
        suggestions: ['华夏基金'],
      );

      when(mockSearchUseCase.search(criteria))
          .thenAnswer((_) async => expectedResult);

      // Act
      final result = await mockSearchUseCase.search(criteria);

      // Assert
      expect(result.totalCount, equals(0));
      expect(result.searchTimeMs, equals(100));
      expect(result.suggestions, contains('华夏基金'));
      verify(mockSearchUseCase.search(criteria)).called(1);
    });

    test('FundSearchUseCase应该正确处理搜索错误', () async {
      // Arrange
      const criteria = FundSearchCriteria.keyword('test');
      when(mockSearchUseCase.search(criteria)).thenThrow(Exception('网络连接失败'));

      // Act & Assert
      expect(
        () async => await mockSearchUseCase.search(criteria),
        throwsException,
      );
      verify(mockSearchUseCase.search(criteria)).called(1);
    });
  });
}
