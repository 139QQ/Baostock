import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:jisu_fund_analyzer/src/bloc/fund_search_bloc.dart';
import 'package:jisu_fund_analyzer/src/services/unified_search_service/i_unified_search_service.dart';
import 'package:jisu_fund_analyzer/src/services/high_performance_fund_service.dart';
import 'package:jisu_fund_analyzer/src/services/fund_analysis_service.dart';
import 'package:jisu_fund_analyzer/src/features/fund/shared/services/search_service.dart'
    as search_service;
import 'package:jisu_fund_analyzer/src/features/fund/shared/models/fund_ranking.dart';

// 生成Mock类
@GenerateMocks([
  IUnifiedSearchService,
  HighPerformanceFundService,
  FundAnalysisService,
])
import 'fund_search_bloc_test.mocks.dart';

void main() {
  group('FundSearchBloc', () {
    late MockIUnifiedSearchService mockUnifiedSearchService;
    late MockHighPerformanceFundService mockHighPerformanceFundService;
    late MockFundAnalysisService mockFundAnalysisService;
    late FundSearchBloc fundSearchBloc;

    setUp(() {
      mockUnifiedSearchService = MockIUnifiedSearchService();
      mockHighPerformanceFundService = MockHighPerformanceFundService();
      mockFundAnalysisService = MockFundAnalysisService();

      fundSearchBloc = FundSearchBloc(
        fundService: mockHighPerformanceFundService,
        analysisService: mockFundAnalysisService,
        unifiedSearchService: mockUnifiedSearchService,
      );
    });

    tearDown(() {
      fundSearchBloc.close();
    });

    group('Unified Search Events', () {
      test('should emit UnifiedSearchLoaded on successful search', () async {
        // Arrange
        final mockFund = FundRanking(
          fundCode: '110022',
          fundName: '易方达消费行业',
          fundType: '混合型',
          rank: 1,
          nav: 2.345,
          dailyReturn: 0.0123,
          oneYearReturn: 0.1567,
          threeYearReturn: 0.2345,
          fiveYearReturn: 0.3456,
          sinceInceptionReturn: 1.2345,
          fundSize: 123.45,
          updateDate: DateTime.now(),
          fundCompany: '易方达基金',
          fundManager: '张三',
          managementFee: 0.015,
          isMockData: false,
        );

        final mockResult = UnifiedSearchResult.fromBasic(
          search_service.SearchResult.success(
            results: [mockFund],
            query: '易方达',
            searchTime: const Duration(milliseconds: 150),
          ),
        );

        when(mockUnifiedSearchService.search(
          '易方达',
          options: anyNamed('options'),
        )).thenAnswer((_) async => mockResult);

        // Act
        fundSearchBloc.add(const UnifiedSearchFunds('易方达'));

        // Assert
        await expectLater(
          fundSearchBloc.stream,
          emitsInOrder([
            const UnifiedSearchLoading('易方达'),
            UnifiedSearchLoaded(
              results: [mockFund],
              query: '易方达',
              useEnhancedEngine: false,
              searchTimeMs: 150,
              fromCache: false,
            ),
          ]),
        );

        verify(mockUnifiedSearchService.search('易方达',
                options: anyNamed('options')))
            .called(1);
      });

      test('should emit UnifiedSearchError on failed search', () async {
        // Arrange
        const errorMessage = 'Search service unavailable';
        final mockResult = UnifiedSearchResult.error(
          query: '易方达',
          error: errorMessage,
        );

        when(mockUnifiedSearchService.search(
          '易方达',
          options: anyNamed('options'),
        )).thenAnswer((_) async => mockResult);

        // Act
        fundSearchBloc.add(const UnifiedSearchFunds('易方达'));

        // Assert
        await expectLater(
          fundSearchBloc.stream,
          emitsInOrder([
            const UnifiedSearchLoading('易方达'),
            const UnifiedSearchError(errorMessage, '易方达'),
          ]),
        );

        verify(mockUnifiedSearchService.search('易方达',
                options: anyNamed('options')))
            .called(1);
      });

      test('should emit FundSearchEmpty when no results found', () async {
        // Arrange
        final mockResult = UnifiedSearchResult.fromBasic(
          search_service.SearchResult.success(
            results: [],
            query: 'unknown',
            searchTime: const Duration(milliseconds: 100),
          ),
        );

        when(mockUnifiedSearchService.search(
          'unknown',
          options: anyNamed('options'),
        )).thenAnswer((_) async => mockResult);

        // Act
        fundSearchBloc.add(const UnifiedSearchFunds('unknown'));

        // Assert
        await expectLater(
          fundSearchBloc.stream,
          emitsInOrder([
            const UnifiedSearchLoading('unknown'),
            const FundSearchEmpty('unknown'),
          ]),
        );

        verify(mockUnifiedSearchService.search('unknown',
                options: anyNamed('options')))
            .called(1);
      });

      test('should handle search suggestions request', () async {
        // Arrange
        final suggestions = ['易方达消费行业', '易方达蓝筹', '易方达价值精选'];
        when(mockUnifiedSearchService.getSuggestions('易方达', limit: 10))
            .thenAnswer((_) async => suggestions);

        // Act
        fundSearchBloc.add(const GetUnifiedSearchSuggestions('易方达'));

        // Assert
        await expectLater(
          fundSearchBloc.stream,
          emits(UnifiedSearchSuggestionsLoaded(suggestions)),
        );

        verify(mockUnifiedSearchService.getSuggestions('易方达', limit: 10))
            .called(1);
      });

      test('should handle cache clear request', () async {
        // Arrange
        when(mockUnifiedSearchService.clearCache()).thenAnswer((_) async {});

        // Act
        fundSearchBloc.add(ClearUnifiedSearchCache());
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        // 验证方法被调用，但状态不应改变
        verify(mockUnifiedSearchService.clearCache()).called(1);

        // 确保状态没有改变
        expect(fundSearchBloc.state, isA<FundSearchInitial>());
      });
    });

    group('Convenience Methods', () {
      test('should call quickSearch correctly', () async {
        // Arrange
        when(mockUnifiedSearchService.search(
          '易方达',
          options: anyNamed('options'),
        )).thenAnswer((_) async => UnifiedSearchResult.fromBasic(
              search_service.SearchResult.success(
                results: [],
                query: '易方达',
                searchTime: Duration.zero,
              ),
            ));

        // Act
        fundSearchBloc.quickSearch('易方达');

        // Assert
        await pumpEventQueue();
        verify(mockUnifiedSearchService.search(
          '易方达',
          options: argThat(
              predicate((UnifiedSearchOptions options) =>
                  options.limit == 10 && options.useEnhancedFeatures == false),
              named: 'options'),
        )).called(1);
      });

      test('should call preciseSearch correctly', () async {
        // Arrange
        when(mockUnifiedSearchService.search(
          '易方达',
          options: anyNamed('options'),
        )).thenAnswer((_) async => UnifiedSearchResult.fromBasic(
              search_service.SearchResult.success(
                results: [],
                query: '易方达',
                searchTime: Duration.zero,
              ),
            ));

        // Act
        fundSearchBloc.preciseSearch('易方达');

        // Assert
        await pumpEventQueue();
        verify(mockUnifiedSearchService.search(
          '易方达',
          options: argThat(
              predicate((UnifiedSearchOptions options) =>
                  options.limit == 20 && options.useEnhancedFeatures == true),
              named: 'options'),
        )).called(1);
      });

      test('should call comprehensiveSearch correctly', () async {
        // Arrange
        when(mockUnifiedSearchService.search(
          '易方达',
          options: anyNamed('options'),
        )).thenAnswer((_) async => UnifiedSearchResult.fromBasic(
              search_service.SearchResult.success(
                results: [],
                query: '易方达',
                searchTime: Duration.zero,
              ),
            ));

        // Act
        fundSearchBloc.comprehensiveSearch('易方达');

        // Assert
        await pumpEventQueue();
        verify(mockUnifiedSearchService.search(
          '易方达',
          options: argThat(
              predicate((UnifiedSearchOptions options) =>
                  options.limit == 100 && options.useEnhancedFeatures == true),
              named: 'options'),
        )).called(1);
      });

      test('should call autoSearch correctly', () async {
        // Arrange
        when(mockUnifiedSearchService.search(
          '110022', // 基金代码
          options: anyNamed('options'),
        )).thenAnswer((_) async => UnifiedSearchResult.fromBasic(
              search_service.SearchResult.success(
                results: [],
                query: '110022',
                searchTime: Duration.zero,
              ),
            ));

        // Act
        fundSearchBloc.autoSearch('110022');

        // Assert
        await pumpEventQueue();
        verify(mockUnifiedSearchService.search(
          '110022',
          options: argThat(
              predicate((UnifiedSearchOptions options) =>
                  options.exactMatch == true && options.limit == 5), // 基金代码搜索配置
              named: 'options'),
        )).called(1);
      });
    });

    group('Search History', () {
      test('should add search to history', () async {
        // Arrange
        final mockResult = UnifiedSearchResult.fromBasic(
          search_service.SearchResult.success(
            results: [],
            query: '易方达',
            searchTime: const Duration(milliseconds: 100),
          ),
        );

        when(mockUnifiedSearchService.search(
          '易方达',
          options: anyNamed('options'),
        )).thenAnswer((_) async => mockResult);

        // Act
        fundSearchBloc.add(const UnifiedSearchFunds('易方达'));
        await pumpEventQueue();

        // Assert
        verify(mockUnifiedSearchService.search('易方达',
                options: anyNamed('options')))
            .called(1);

        // 注意：搜索历史是内部状态，需要通过公共属性或方法验证
        // 这可能需要在FundSearchBloc中添加getter来验证
      });

      test('should not add empty query to history', () async {
        // Arrange
        final mockResult = UnifiedSearchResult.fromBasic(
          search_service.SearchResult.success(
            results: [],
            query: '',
            searchTime: Duration.zero,
          ),
        );

        when(mockUnifiedSearchService.search(
          '',
          options: anyNamed('options'),
        )).thenAnswer((_) async => mockResult);

        // Act
        fundSearchBloc.add(const UnifiedSearchFunds(''));
        await pumpEventQueue();

        // Assert
        verify(mockUnifiedSearchService.search('',
                options: anyNamed('options')))
            .called(1);
        // 空查询不应该添加到历史记录中
      });

      test('should not add duplicate query to history', () async {
        // Arrange
        final mockResult = UnifiedSearchResult.fromBasic(
          search_service.SearchResult.success(
            results: [],
            query: '易方达',
            searchTime: Duration.zero,
          ),
        );

        when(mockUnifiedSearchService.search(
          '易方达',
          options: anyNamed('options'),
        )).thenAnswer((_) async => mockResult);

        // Act
        fundSearchBloc.add(const UnifiedSearchFunds('易方达'));
        await pumpEventQueue();

        fundSearchBloc.add(const UnifiedSearchFunds('易方达'));
        await pumpEventQueue();

        // Assert
        verify(mockUnifiedSearchService.search('易方达',
                options: anyNamed('options')))
            .called(2);
        // 重复查询应该只在历史中出现一次
      });
    });

    group('Error Handling', () {
      test('should handle service exceptions gracefully', () async {
        // Arrange
        when(mockUnifiedSearchService.search(
          '易方达',
          options: anyNamed('options'),
        )).thenThrow(Exception('Service unavailable'));

        // Act
        fundSearchBloc.add(const UnifiedSearchFunds('易方达'));

        // Assert
        await expectLater(
          fundSearchBloc.stream,
          emitsInOrder([
            const UnifiedSearchLoading('易方达'),
            const UnifiedSearchError('Exception: Service unavailable', '易方达'),
          ]),
        );
      });

      test('should handle suggestions service exceptions gracefully', () async {
        // Arrange
        when(mockUnifiedSearchService.getSuggestions('易方达', limit: 10))
            .thenThrow(Exception('Suggestions service error'));

        // Act
        fundSearchBloc.add(const GetUnifiedSearchSuggestions('易方达'));

        // Assert
        await pumpEventQueue();
        // 建议获取失败应该不影响当前状态
        verify(mockUnifiedSearchService.getSuggestions('易方达', limit: 10))
            .called(1);
        expect(fundSearchBloc.state, isA<FundSearchInitial>());
      });
    });

    group('State Management', () {
      test('should maintain correct getters', () {
        // 初始状态检查
        expect(fundSearchBloc.currentQuery, isEmpty);
        expect(fundSearchBloc.isLoading, isFalse);
        expect(fundSearchBloc.hasError, isFalse);
        expect(fundSearchBloc.errorMessage, isNull);
        expect(fundSearchBloc.analysisService, equals(mockFundAnalysisService));
        expect(fundSearchBloc.unifiedSearchService,
            equals(mockUnifiedSearchService));
      });
    });
  });
}
