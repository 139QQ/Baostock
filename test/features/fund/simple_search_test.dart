import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:jisu_fund_analyzer/src/features/fund/domain/entities/fund_search_criteria.dart';
import 'package:jisu_fund_analyzer/src/features/fund/domain/usecases/fund_search_usecase.dart';
import 'package:jisu_fund_analyzer/src/features/fund/domain/repositories/fund_repository.dart';

void main() {
  group('基金搜索基本功能测试', () {
    test('FundSearchCriteria应该正确创建', () {
      // Act
      const criteria = FundSearchCriteria.keyword('华夏基金');

      // Assert
      expect(criteria.keyword, equals('华夏基金'));
      expect(criteria.isValid, isTrue);
      expect(criteria.searchType, equals(SearchType.mixed));
    });

    test('FundSearchCriteria应该正确生成缓存键', () {
      // Act
      const criteria = FundSearchCriteria.keyword('test');
      final cacheKey = criteria.cacheKey;

      // Assert
      expect(cacheKey, contains('test'));
      expect(cacheKey, contains('mixed'));
    });

    test('SearchResult应该正确创建空结果', () {
      // Arrange
      const criteria = FundSearchCriteria.keyword('nonexistent');

      // Act
      final result = SearchResult.empty(criteria: criteria);

      // Assert
      expect(result.funds, isEmpty);
      expect(result.totalCount, equals(0));
      expect(result.isEmpty, isTrue);
      expect(result.hasMore, isFalse);
    });

    test('FundSearchUseCase依赖注入应该正确配置', () {
      // Arrange
      final mockRepository = MockFundRepository();
      final useCase = FundSearchUseCase(mockRepository);

      // Assert
      expect(useCase, isNotNull);
      expect(useCase.getPerformanceStats(), isA<Map<String, dynamic>>());
    });

    testWidgets('Provider应该正确提供FundSearchUseCase', (WidgetTester tester) async {
      // Arrange
      final mockRepository = MockFundRepository();
      final useCase = FundSearchUseCase(mockRepository);

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Provider<FundSearchUseCase>(
          create: (_) => useCase,
          child: Builder(
            builder: (context) {
              final providedUseCase = context.read<FundSearchUseCase>();
              return ElevatedButton(
                onPressed: () {},
                child: Text('UseCase已提供: ${providedUseCase.runtimeType}'),
              );
            },
          ),
        ),
      ));

      // Assert
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.textContaining('UseCase已提供:'), findsOneWidget);
    });
  });
}

// 简单的Mock实现
class MockFundRepository implements FundRepository {
  @override
  Future<List<Fund>> getFundList() async {
    return [];
  }

  @override
  Future<Fund?> getFundByCode(String code) async {
    return null;
  }

  @override
  Future<List<Fund>> getFundRankings({
    String sortBy = 'return1Y',
    int limit = 20,
    String fundType = '',
  }) async {
    return [];
  }

  @override
  Future<List<Fund>> searchFunds({
    required String keyword,
    String type = '',
    String company = '',
  }) async {
    return [];
  }

  @override
  Future<Map<String, dynamic>> getMarketStatistics() async {
    return {};
  }

  @override
  Future<List<String>> getFundCompanies() async {
    return [];
  }

  @override
  Future<List<String>> getFundTypes() async {
    return [];
  }
}
