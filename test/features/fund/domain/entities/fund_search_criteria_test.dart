import 'package:flutter_test/flutter_test.dart';
import 'package:equatable/equatable.dart';

import 'package:jisu_fund_analyzer/src/features/fund/domain/entities/fund_search_criteria.dart';

void main() {
  group('FundSearchCriteria', () {
    test('应该正确创建空的搜索条件', () {
      // Arrange & Act
      final criteria = FundSearchCriteria.empty();

      // Assert
      expect(criteria.keyword, null);
      expect(criteria.searchType, SearchType.mixed);
      expect(criteria.caseSensitive, false);
      expect(criteria.fuzzySearch, true);
      expect(criteria.fuzzyThreshold, 0.6);
      expect(criteria.enablePinyinSearch, true);
      expect(criteria.searchFields, []);
      expect(criteria.sortBy, SearchSortType.relevance);
      expect(criteria.limit, 20);
      expect(criteria.offset, 0);
      expect(criteria.includeInactive, false);
      expect(criteria.extendedFilters, {});
    });

    test('应该正确创建关键词搜索条件', () {
      // Arrange & Act
      final criteria = FundSearchCriteria.keyword(
        '易方达',
        searchType: SearchType.name,
        caseSensitive: true,
        fuzzySearch: false,
        searchFields: [SearchField.name, SearchField.company],
      );

      // Assert
      expect(criteria.keyword, '易方达');
      expect(criteria.searchType, SearchType.name);
      expect(criteria.caseSensitive, true);
      expect(criteria.fuzzySearch, false);
      expect(criteria.searchFields, [SearchField.name, SearchField.company]);
    });

    test('应该正确判断搜索条件是否为空', () {
      // Arrange & Act & Assert
      final emptyCriteria1 = FundSearchCriteria.empty();
      expect(emptyCriteria1.isEmpty, true);
      expect(emptyCriteria1.isValid, false);

      const emptyCriteria2 = FundSearchCriteria(keyword: '');
      expect(emptyCriteria2.isEmpty, true);
      expect(emptyCriteria2.isValid, false);

      const emptyCriteria3 = FundSearchCriteria(keyword: '   ');
      expect(emptyCriteria3.isEmpty, true);
      expect(emptyCriteria3.isValid, false);

      const validCriteria = FundSearchCriteria(keyword: '易方达');
      expect(validCriteria.isEmpty, false);
      expect(validCriteria.isValid, true);
    });

    test('应该正确判断是否启用高级搜索', () {
      // Arrange & Act & Assert
      const basicCriteria = FundSearchCriteria(keyword: 'test');
      expect(basicCriteria.hasAdvancedSearch, false);

      const fuzzyCriteria = FundSearchCriteria(
        keyword: 'test',
        fuzzySearch: false,
      );
      expect(fuzzyCriteria.hasAdvancedSearch, false);

      const advancedCriteria1 = FundSearchCriteria(
        keyword: 'test',
        fuzzySearch: true,
        fuzzyThreshold: 0.8,
      );
      expect(advancedCriteria1.hasAdvancedSearch, true);

      const advancedCriteria2 = FundSearchCriteria(
        keyword: 'test',
        searchFields: [SearchField.name],
      );
      expect(advancedCriteria2.hasAdvancedSearch, true);

      const advancedCriteria3 = FundSearchCriteria(
        keyword: 'test',
        sortBy: SearchSortType.name,
      );
      expect(advancedCriteria3.hasAdvancedSearch, true);

      const advancedCriteria4 = FundSearchCriteria(
        keyword: 'test',
        extendedFilters: {
          'fundTypes': ['股票型']
        },
      );
      expect(advancedCriteria4.hasAdvancedSearch, true);
    });

    test('应该正确生成缓存键', () {
      // Arrange
      final criteria1 = FundSearchCriteria.keyword('test');
      final criteria2 = FundSearchCriteria.keyword('test');
      final criteria3 = FundSearchCriteria.keyword('TEST');

      // Act & Assert
      expect(criteria1.cacheKey, criteria2.cacheKey);
      expect(criteria1.cacheKey, isNot(equals(criteria3.cacheKey)));

      const expectedKey =
          'test|mixed|false|true|true|true||relevance|20|0|false|{}';
      expect(criteria1.cacheKey, expectedKey);
    });

    test('应该正确复制和更新搜索条件', () {
      // Arrange
      const originalCriteria = FundSearchCriteria(
        keyword: 'test',
        searchType: SearchType.name,
        caseSensitive: false,
        fuzzySearch: true,
        fuzzyThreshold: 0.6,
        enablePinyinSearch: true,
        searchFields: [SearchField.name],
        sortBy: SearchSortType.relevance,
        limit: 10,
        offset: 0,
        includeInactive: false,
        extendedFilters: {
          'fundTypes': ['股票型']
        },
      );

      // Act
      final updatedCriteria = originalCriteria.copyWith(
        keyword: 'newKeyword',
        caseSensitive: true,
        limit: 20,
        extendedFilters: {
          'companies': ['易方达']
        },
      );

      // Assert
      expect(updatedCriteria.keyword, 'newKeyword');
      expect(updatedCriteria.caseSensitive, true);
      expect(updatedCriteria.limit, 20);
      expect(updatedCriteria.extendedFilters, {
        'companies': ['易方达']
      });

      // 原始条件不应被修改
      expect(originalCriteria.keyword, 'test');
      expect(originalCriteria.caseSensitive, false);
      expect(originalCriteria.limit, 10);
      expect(originalCriteria.extendedFilters, {
        'fundTypes': ['股票型']
      });
    });

    test('应该正确清除搜索条件字段', () {
      // Arrange
      const originalCriteria = FundSearchCriteria(
        keyword: 'test',
        searchFields: [SearchField.name, SearchField.company],
        extendedFilters: {
          'fundTypes': ['股票型']
        },
      );

      // Act
      final clearedCriteria = originalCriteria.copyWith(
        clearKeyword: true,
        clearSearchFields: true,
        clearExtendedFilters: true,
      );

      // Assert
      expect(clearedCriteria.keyword, null);
      expect(clearedCriteria.searchFields, []);
      expect(clearedCriteria.extendedFilters, {});
    });

    test('应该正确序列化为JSON', () {
      // Arrange
      const criteria = FundSearchCriteria(
        keyword: '易方达',
        searchType: SearchType.name,
        caseSensitive: true,
        fuzzySearch: false,
        fuzzyThreshold: 0.8,
        enablePinyinSearch: false,
        searchFields: [SearchField.name, SearchField.company],
        sortBy: SearchSortType.name,
        limit: 50,
        offset: 10,
        includeInactive: true,
        extendedFilters: {
          'fundTypes': ['股票型'],
          'companies': ['易方达']
        },
      );

      // Act
      final json = criteria.toJson();

      // Assert
      expect(json['keyword'], '易方达');
      expect(json['searchType'], 'name');
      expect(json['caseSensitive'], true);
      expect(json['fuzzySearch'], false);
      expect(json['fuzzyThreshold'], 0.8);
      expect(json['enablePinyinSearch'], false);
      expect(json['searchFields'], ['name', 'company']);
      expect(json['sortBy'], 'name');
      expect(json['limit'], 50);
      expect(json['offset'], 10);
      expect(json['includeInactive'], true);
      expect(json['extendedFilters'], {
        'fundTypes': ['股票型'],
        'companies': ['易方达']
      });
    });

    test('应该正确从JSON创建搜索条件', () {
      // Arrange
      final json = {
        'keyword': '易方达',
        'searchType': 'name',
        'caseSensitive': true,
        'fuzzySearch': false,
        'fuzzyThreshold': 0.8,
        'enablePinyinSearch': false,
        'searchFields': ['name', 'company'],
        'sortBy': 'name',
        'limit': 50,
        'offset': 10,
        'includeInactive': true,
        'extendedFilters': {
          'fundTypes': ['股票型'],
          'companies': ['易方达']
        },
      };

      // Act
      final criteria = FundSearchCriteria.fromJson(json);

      // Assert
      expect(criteria.keyword, '易方达');
      expect(criteria.searchType, SearchType.name);
      expect(criteria.caseSensitive, true);
      expect(criteria.fuzzySearch, false);
      expect(criteria.fuzzyThreshold, 0.8);
      expect(criteria.enablePinyinSearch, false);
      expect(criteria.searchFields, [SearchField.name, SearchField.company]);
      expect(criteria.sortBy, SearchSortType.name);
      expect(criteria.limit, 50);
      expect(criteria.offset, 10);
      expect(criteria.includeInactive, true);
      expect(criteria.extendedFilters, {
        'fundTypes': ['股票型'],
        'companies': ['易方达']
      });
    });

    test('应该正确处理不完整的JSON', () {
      // Arrange
      final json = {
        'keyword': 'test',
        'searchType': 'invalidType', // 无效的搜索类型
        'fuzzyThreshold': 1.5, // 超出范围的阈值
      };

      // Act
      final criteria = FundSearchCriteria.fromJson(json);

      // Assert
      expect(criteria.keyword, 'test');
      expect(criteria.searchType, SearchType.mixed); // 默认值
      expect(criteria.fuzzyThreshold, 1.5); // 保留原值，构造函数会验证
      expect(criteria.caseSensitive, false); // 默认值
    });

    test('应该正确比较两个搜索条件是否相等', () {
      // Arrange
      const criteria1 = FundSearchCriteria(
        keyword: 'test',
        searchType: SearchType.name,
        extendedFilters: {
          'fundTypes': ['股票型']
        },
      );

      const criteria2 = FundSearchCriteria(
        keyword: 'test',
        searchType: SearchType.name,
        extendedFilters: {
          'fundTypes': ['股票型']
        },
      );

      const criteria3 = FundSearchCriteria(
        keyword: 'test',
        searchType: SearchType.code, // 不同的搜索类型
        extendedFilters: {
          'fundTypes': ['股票型']
        },
      );

      const criteria4 = FundSearchCriteria(
        keyword: 'test',
        searchType: SearchType.name,
        extendedFilters: {
          'fundTypes': ['债券型']
        }, // 不同的筛选条件
      );

      // Act & Assert
      expect(criteria1, equals(criteria2));
      expect(criteria1, isNot(equals(criteria3)));
      expect(criteria1, isNot(equals(criteria4)));
    });

    test('应该正确生成字符串表示', () {
      // Arrange
      final emptyCriteria = FundSearchCriteria.empty();
      final simpleCriteria = FundSearchCriteria.keyword('test');
      const advancedCriteria = FundSearchCriteria(
        keyword: '易方达',
        searchType: SearchType.name,
        caseSensitive: true,
        fuzzySearch: true,
        fuzzyThreshold: 0.8,
        enablePinyinSearch: true,
        searchFields: [SearchField.name, SearchField.company],
        sortBy: SearchSortType.scale,
        limit: 50,
        offset: 10,
        includeInactive: true,
      );

      // Act & Assert
      expect(emptyCriteria.toString(), '无搜索条件');
      expect(simpleCriteria.toString(), contains('关键词: "test"'));
      expect(simpleCriteria.toString(), contains('类型: 混合搜索'));
      expect(advancedCriteria.toString(), contains('关键词: "易方达"'));
      expect(advancedCriteria.toString(), contains('类型: 基金名称'));
      expect(advancedCriteria.toString(), contains('区分大小写'));
      expect(advancedCriteria.toString(), contains('模糊搜索(80%)'));
      expect(advancedCriteria.toString(), contains('拼音搜索'));
      expect(advancedCriteria.toString(), contains('字段: 基金名称, 管理公司'));
      expect(advancedCriteria.toString(), contains('排序: 基金规模'));
      expect(advancedCriteria.toString(), contains('限制: 50条'));
      expect(advancedCriteria.toString(), contains('偏移: 10'));
      expect(advancedCriteria.toString(), contains('包含停运基金'));
    });
  });

  group('SearchType', () {
    test('应该具有正确的显示名称', () {
      expect(SearchType.exact.displayName, '精确匹配');
      expect(SearchType.code.displayName, '基金代码');
      expect(SearchType.name.displayName, '基金名称');
      expect(SearchType.mixed.displayName, '混合搜索');
      expect(SearchType.fullText.displayName, '全文搜索');
    });

    test('toString应该返回显示名称', () {
      expect(SearchType.exact.toString(), '精确匹配');
      expect(SearchType.code.toString(), '基金代码');
      expect(SearchType.name.toString(), '基金名称');
      expect(SearchType.mixed.toString(), '混合搜索');
      expect(SearchType.fullText.toString(), '全文搜索');
    });
  });

  group('SearchField', () {
    test('应该具有正确的显示名称', () {
      expect(SearchField.all.displayName, '全部');
      expect(SearchField.code.displayName, '基金代码');
      expect(SearchField.name.displayName, '基金名称');
      expect(SearchField.type.displayName, '基金类型');
      expect(SearchField.company.displayName, '管理公司');
      expect(SearchField.manager.displayName, '基金经理');
      expect(SearchField.strategy.displayName, '投资策略');
    });

    test('toString应该返回显示名称', () {
      expect(SearchField.all.toString(), '全部');
      expect(SearchField.code.toString(), '基金代码');
      expect(SearchField.name.toString(), '基金名称');
      expect(SearchField.type.toString(), '基金类型');
      expect(SearchField.company.toString(), '管理公司');
      expect(SearchField.manager.toString(), '基金经理');
      expect(SearchField.strategy.toString(), '投资策略');
    });
  });

  group('SearchSortType', () {
    test('应该具有正确的显示名称', () {
      expect(SearchSortType.relevance.displayName, '相关性');
      expect(SearchSortType.code.displayName, '基金代码');
      expect(SearchSortType.name.displayName, '基金名称');
      expect(SearchSortType.returnRate.displayName, '收益率');
      expect(SearchSortType.scale.displayName, '基金规模');
      expect(SearchSortType.establishmentDate.displayName, '成立时间');
    });

    test('toString应该返回显示名称', () {
      expect(SearchSortType.relevance.toString(), '相关性');
      expect(SearchSortType.code.toString(), '基金代码');
      expect(SearchSortType.name.toString(), '基金名称');
      expect(SearchSortType.returnRate.toString(), '收益率');
      expect(SearchSortType.scale.toString(), '基金规模');
      expect(SearchSortType.establishmentDate.toString(), '成立时间');
    });
  });

  group('SearchResult', () {
    test('应该正确创建搜索结果', () {
      // Arrange
      final criteria = FundSearchCriteria.keyword('test');
      const match1 = FundSearchMatch(
        fundCode: '000001',
        fundName: '华夏成长混合',
        score: 0.95,
        matchedFields: [SearchField.name],
        highlights: {
          'name': ['华夏']
        },
      );
      const match2 = FundSearchMatch(
        fundCode: '000002',
        fundName: '华夏回报混合',
        score: 0.85,
        matchedFields: [SearchField.name],
        highlights: {
          'name': ['华夏']
        },
      );

      // Act
      final result = SearchResult(
        funds: [match1, match2],
        totalCount: 2,
        searchTimeMs: 150,
        criteria: criteria,
        hasMore: false,
        suggestions: ['华夏基金', '成长基金'],
      );

      // Assert
      expect(result.funds.length, 2);
      expect(result.totalCount, 2);
      expect(result.searchTimeMs, 150);
      expect(result.criteria, criteria);
      expect(result.hasMore, false);
      expect(result.suggestions, ['华夏基金', '成长基金']);
      expect(result.isNotEmpty, true);
      expect(result.isEmpty, false);
    });

    test('应该正确创建空搜索结果', () {
      // Arrange
      final criteria = FundSearchCriteria.keyword('nonexistent');

      // Act
      final result = SearchResult.empty(criteria: criteria);

      // Assert
      expect(result.funds.isEmpty, true);
      expect(result.totalCount, 0);
      expect(result.searchTimeMs, 0);
      expect(result.criteria, criteria);
      expect(result.hasMore, false);
      expect(result.suggestions.isEmpty, true);
      expect(result.isEmpty, true);
      expect(result.isNotEmpty, false);
    });

    test('应该正确比较两个搜索结果是否相等', () {
      // Arrange
      final criteria = FundSearchCriteria.keyword('test');
      const match = FundSearchMatch(
        fundCode: '000001',
        fundName: 'Test Fund',
        score: 1.0,
        matchedFields: [SearchField.name],
        highlights: {},
      );

      final result1 = SearchResult(
        funds: [match],
        totalCount: 1,
        searchTimeMs: 100,
        criteria: criteria,
        hasMore: false,
      );

      final result2 = SearchResult(
        funds: [match],
        totalCount: 1,
        searchTimeMs: 100,
        criteria: criteria,
        hasMore: false,
      );

      final result3 = SearchResult(
        funds: [match],
        totalCount: 1,
        searchTimeMs: 200, // 不同的搜索时间
        criteria: criteria,
        hasMore: false,
      );

      // Act & Assert
      expect(result1, equals(result2));
      expect(result1, isNot(equals(result3)));
    });
  });

  group('FundSearchMatch', () {
    test('应该正确创建搜索匹配结果', () {
      // Arrange & Act
      const match = FundSearchMatch(
        fundCode: '000001',
        fundName: '华夏成长混合',
        score: 0.95,
        matchedFields: [SearchField.name, SearchField.company],
        highlights: {
          'name': ['华夏'],
          'company': ['华夏基金'],
        },
      );

      // Assert
      expect(match.fundCode, '000001');
      expect(match.fundName, '华夏成长混合');
      expect(match.score, 0.95);
      expect(match.matchedFields, [SearchField.name, SearchField.company]);
      expect(match.highlights, {
        'name': ['华夏'],
        'company': ['华夏基金'],
      });
    });

    test('应该正确比较两个搜索匹配结果是否相等', () {
      // Arrange
      const match1 = FundSearchMatch(
        fundCode: '000001',
        fundName: 'Test Fund',
        score: 0.9,
        matchedFields: [SearchField.name],
        highlights: {
          'name': ['Test']
        },
      );

      const match2 = FundSearchMatch(
        fundCode: '000001',
        fundName: 'Test Fund',
        score: 0.9,
        matchedFields: [SearchField.name],
        highlights: {
          'name': ['Test']
        },
      );

      const match3 = FundSearchMatch(
        fundCode: '000001',
        fundName: 'Test Fund',
        score: 0.8, // 不同的分数
        matchedFields: [SearchField.name],
        highlights: {
          'name': ['Test']
        },
      );

      // Act & Assert
      expect(match1, equals(match2));
      expect(match1, isNot(equals(match3)));
    });

    test('应该正确生成字符串表示', () {
      // Arrange
      const match = FundSearchMatch(
        fundCode: '000001',
        fundName: 'Test Fund',
        score: 0.856,
        matchedFields: [SearchField.name],
        highlights: {},
      );

      // Act & Assert
      expect(match.toString(),
          'FundSearchMatch(code: 000001, name: Test Fund, score: 85%)');
    });
  });
}
