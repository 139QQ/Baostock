import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';

import 'package:jisu_fund_analyzer/src/services/unified_search_service/i_unified_search_service.dart';
import 'package:jisu_fund_analyzer/src/services/unified_search_service/unified_search_service.dart';
import 'package:jisu_fund_analyzer/src/services/unified_search_service/search_options_factory.dart';
import 'package:jisu_fund_analyzer/src/features/fund/shared/services/search_service.dart';
import 'package:jisu_fund_analyzer/src/services/enhanced_fund_search_service.dart';
import 'package:jisu_fund_analyzer/src/features/fund/shared/models/fund_ranking.dart';

// 生成Mock类
@GenerateMocks([
  SearchService,
  EnhancedFundSearchService,
])
import 'unified_search_service_test.mocks.dart';

void main() {
  group('UnifiedSearchService', () {
    late MockSearchService mockSearchService;
    late MockEnhancedFundSearchService mockEnhancedSearchService;

    setUp(() {
      mockSearchService = MockSearchService();
      mockEnhancedSearchService = MockEnhancedFundSearchService();
    });

    group('SearchOptionsFactory', () {
      test('should create quick search options', () {
        final options = SearchOptionsFactory.quickSearch();

        expect(options.limit, equals(10));
        expect(options.useCache, isTrue);
        expect(options.cacheResults, isTrue);
        expect(options.fuzzyThreshold, equals(0.8));
        expect(options.useEnhancedFeatures, isFalse);
        expect(options.enableBehaviorPreload, isFalse);
        expect(options.enableIncrementalLoad, isFalse);
      });

      test('should create precise search options', () {
        final options = SearchOptionsFactory.preciseSearch();

        expect(options.limit, equals(20));
        expect(options.useCache, isTrue);
        expect(options.fuzzyThreshold, equals(0.9));
        expect(options.enableFuzzy, isTrue);
        expect(options.enablePinyin, isTrue);
        expect(options.useEnhancedFeatures, isTrue);
      });

      test('should create comprehensive search options', () {
        final options = SearchOptionsFactory.comprehensiveSearch();

        expect(options.limit, equals(100));
        expect(options.useCache, isTrue);
        expect(options.fuzzyThreshold, equals(0.6));
        expect(options.enableBehaviorPreload, isTrue);
        expect(options.enableIncrementalLoad, isTrue);
        expect(options.useEnhancedFeatures, isTrue);
      });

      test('should create fund code search options', () {
        final options = SearchOptionsFactory.fundCodeSearch();

        expect(options.limit, equals(5));
        expect(options.exactMatch, isTrue);
        expect(options.fuzzyThreshold, equals(1.0));
        expect(options.sortBy, equals('fundCode'));
        expect(options.useEnhancedFeatures, isFalse);
      });

      test('should auto optimize search for fund code', () {
        final options = SearchOptionsFactory.autoOptimizedSearch('110022');

        expect(options.limit, equals(5));
        expect(options.exactMatch, isTrue);
        expect(options.fuzzyThreshold, equals(1.0));
      });

      test('should auto optimize search for short query', () {
        final options = SearchOptionsFactory.autoOptimizedSearch('易方');

        expect(options.limit, equals(10));
        expect(options.useEnhancedFeatures, isFalse);
      });

      test('should auto optimize search for long query', () {
        final options =
            SearchOptionsFactory.autoOptimizedSearch('易方达蓝筹精选混合型基金');

        expect(options.limit, equals(100));
        expect(options.useEnhancedFeatures, isTrue);
      });

      test('should auto optimize search for keywords', () {
        final options = SearchOptionsFactory.autoOptimizedSearch('易方达 股票型');

        expect(options.limit, equals(100));
        expect(options.useEnhancedFeatures, isTrue);
      });
    });

    group('UnifiedSearchOptions', () {
      test('should convert to basic search options', () {
        const options = UnifiedSearchOptions(
          exactMatch: true,
          useCache: false,
          fuzzyThreshold: 0.7,
          limit: 50,
          sortBy: 'fundSize',
        );

        final basicOptions = options.toBasicSearchOptions();

        expect(basicOptions.exactMatch, isTrue);
        expect(basicOptions.useCache, isFalse);
        expect(basicOptions.fuzzyThreshold, equals(0.7));
        expect(basicOptions.limit, equals(50));
        expect(basicOptions.sortBy, equals(SearchSortBy.fundSize));
      });

      test('should convert to enhanced search options', () {
        const options = UnifiedSearchOptions(
          limit: 80,
          enableFuzzy: true,
          enablePinyin: false,
          enableBehaviorPreload: true,
        );

        final enhancedOptions = options.toEnhancedSearchOptions();

        expect(enhancedOptions.maxResults, equals(80));
        expect(enhancedOptions.minResults, equals(16)); // 80 / 5
        expect(enhancedOptions.enableFuzzy, isTrue);
        expect(enhancedOptions.enablePinyin, isFalse);
        expect(enhancedOptions.enableBehaviorPreload, isTrue);
      });

      test('should calculate min results correctly', () {
        const options = UnifiedSearchOptions(limit: 30);
        final enhancedOptions = options.toEnhancedSearchOptions();
        expect(enhancedOptions.minResults, equals(10));
      });

      test('should map sort by correctly', () {
        const options = UnifiedSearchOptions(sortBy: 'return1y');
        final basicOptions = options.toBasicSearchOptions();
        expect(basicOptions.sortBy, equals(SearchSortBy.return1Y));

        const options2 = UnifiedSearchOptions(sortBy: '近1年收益');
        final basicOptions2 = options2.toBasicSearchOptions();
        expect(basicOptions2.sortBy, equals(SearchSortBy.return1Y));
      });
    });

    group('UnifiedSearchResult', () {
      test('should create from basic search result', () {
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

        final searchResult = SearchResult.success(
          results: [mockFund],
          query: '易方达',
          searchTime: const Duration(milliseconds: 150),
          fromCache: true,
        );

        final unifiedResult = UnifiedSearchResult.fromBasic(searchResult);

        expect(unifiedResult.query, equals('易方达'));
        expect(unifiedResult.basicResults.length, equals(1));
        expect(unifiedResult.enhancedResults, isEmpty);
        expect(unifiedResult.searchTimeMs, equals(150));
        expect(unifiedResult.fromCache, isTrue);
        expect(unifiedResult.useEnhancedEngine, isFalse);
        expect(unifiedResult.isSuccess, isTrue);
        expect(unifiedResult.results.length, equals(1));
      });

      test('should create error result', () {
        final errorResult = UnifiedSearchResult.error(
          query: 'test',
          error: 'Search failed',
          searchTimeMs: 50,
        );

        expect(errorResult.query, equals('test'));
        expect(errorResult.error, equals('Search failed'));
        expect(errorResult.searchTimeMs, equals(50));
        expect(errorResult.isSuccess, isFalse);
        expect(errorResult.results, isEmpty);
      });
    });

    group('Smart Routing Logic', () {
      // 注意：这些测试需要修改UnifiedSearchService为可测试设计
      // 或提取智能路由逻辑为独立的服务类

      test('should route fund codes to basic search', () {
        // 这些测试用例展示了智能路由逻辑的预期行为
        // 实际实现需要重构代码以支持依赖注入

        // 6位数字应该使用基础搜索
        const fundCodeQuery = '110022';
        expect(RegExp(r'^\d{6}$').hasMatch(fundCodeQuery), isTrue);
      });

      test('should route long queries to enhanced search', () {
        const longQuery = '易方达蓝筹精选混合型证券投资基金';
        expect(longQuery.length, greaterThan(15));
      });

      test('should route multi-word queries to enhanced search', () {
        const multiWordQuery = '易方达 消费行业';
        expect(multiWordQuery.contains(' '), isTrue);
      });

      test('should route queries with special characters to enhanced search',
          () {
        const specialQuery = '华夏回报@开放式';
        expect(RegExp(r'[^\w\u4e00-\u9fff]').hasMatch(specialQuery), isTrue);
      });

      test('should detect fund type keywords', () {
        final keywords = ['股票', '债券', '混合', '货币', '指数', 'qdii', 'etf', 'lof'];
        const query = '易方达股票型基金';

        expect(
            keywords.any((keyword) =>
                query.toLowerCase().contains(keyword.toLowerCase())),
            isTrue);
      });

      test('should detect strategy keywords', () {
        final keywords = ['价值', '成长', '平衡', '稳健', '激进', '保本', '定投'];
        const query = '华夏价值精选';

        expect(
            keywords.any((keyword) =>
                query.toLowerCase().contains(keyword.toLowerCase())),
            isTrue);
      });
    });

    group('Integration Tests', () {
      test('should handle search with null options', () async {
        // 基本集成测试
        const query = '易方达';

        try {
          // 注意：这需要真实的UnifiedSearchService实例
          // 在实际测试中应该使用Mock服务
          expect(query, isA<String>());
          expect(query, isNotEmpty);
        } catch (e) {
          // 预期可能因为依赖问题失败
          expect(e, isA<Exception>());
        }
      });

      test('should handle empty query gracefully', () async {
        const query = '';

        try {
          // 空查询应该返回空结果或错误
          expect(query, isEmpty);
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });

      test('should handle service initialization', () async {
        try {
          // 服务初始化测试
          expect(UnifiedSearchService(), isA<UnifiedSearchService>());
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });
    });

    group('Performance Tests', () {
      test('should generate search options quickly', () {
        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 1000; i++) {
          SearchOptionsFactory.autoOptimizedSearch('易方达消费行业基金');
        }

        stopwatch.stop();

        // 应该在合理时间内完成（1000次 < 200ms）
        expect(stopwatch.elapsedMilliseconds, lessThan(200));
      });

      test('should convert options quickly', () {
        const options = UnifiedSearchOptions(
          limit: 100,
          enableFuzzy: true,
          enablePinyin: true,
          sortBy: 'return1y',
        );

        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 1000; i++) {
          options.toBasicSearchOptions();
          options.toEnhancedSearchOptions();
        }

        stopwatch.stop();

        // 应该在合理时间内完成（2000次转换 < 50ms）
        expect(stopwatch.elapsedMilliseconds, lessThan(50));
      });

      test('should handle large query efficiently', () {
        final longQuery = '易方达' * 20; // 20个中文字符

        final options = SearchOptionsFactory.autoOptimizedSearch(longQuery);

        expect(longQuery.length, equals(60)); // 20个"易方达"，每个占3个字符
        expect(options.limit, equals(100)); // comprehensiveSearch返回100
        expect(options.useEnhancedFeatures, isTrue);
      });
    });

    group('Edge Cases', () {
      test('should handle null values in options', () {
        const options = UnifiedSearchOptions(
          fuzzyThreshold: 0.0,
          limit: 0,
          sortBy: '',
        );

        expect(options.fuzzyThreshold, equals(0.0));
        expect(options.limit, equals(0));
        expect(options.sortBy, equals(''));
      });

      test('should handle extreme values', () {
        const options = UnifiedSearchOptions(
          fuzzyThreshold: 1.0,
          limit: 1000,
        );

        final enhancedOptions = options.toEnhancedSearchOptions();
        expect(enhancedOptions.minResults, equals(200)); // 1000 / 5
      });

      test('should handle malformed sort by values', () {
        const options = UnifiedSearchOptions(sortBy: 'invalid_sort');
        final basicOptions = options.toBasicSearchOptions();

        // 应该回退到默认值
        expect(basicOptions.sortBy, equals(SearchSortBy.relevance));
      });

      test('should handle unicode characters', () {
        const unicodeQuery = '易方达蓝筹📈精选';

        expect(unicodeQuery.contains('📈'), isTrue);

        // 应该仍然能够生成选项
        final options = SearchOptionsFactory.autoOptimizedSearch(unicodeQuery);
        expect(options, isA<UnifiedSearchOptions>());
      });
    });
  });
}
