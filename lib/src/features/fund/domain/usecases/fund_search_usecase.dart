import 'dart:async';

import '../entities/fund.dart';
import '../entities/fund_search_criteria.dart';
import '../repositories/fund_repository.dart';

/// 基金搜索用例类
///
/// 负责执行基金搜索的核心业务逻辑，支持多种搜索算法和优化策略。
/// 遵循单一职责原则，专门处理搜索相关的业务逻辑。
///
/// 性能特性：
/// - 支持模糊搜索和精确搜索
/// - 内置拼音搜索支持
/// - 智能排序和分页
/// - 响应时间≤300ms
///
/// 时间复杂度：
/// - 精确匹配: O(n) 其中n为基金数量
/// - 模糊搜索: O(n*m) 其中m为关键词长度
/// - 拼音搜索: O(n*k) 其中k为拼音转换长度
class FundSearchUseCase {
  final FundRepository _repository;

  /// 搜索缓存，提升重复搜索性能
  final Map<String, SearchResult> _searchCache = {};

  /// 搜索性能统计
  final List<int> _searchTimes = [];

  /// 最大缓存条目数
  static int maxCacheSize = 100;

  /// 拼音映射表（简化版）
  static const Map<String, String> _pinyinMap = {
    '基': 'ji',
    '金': 'jin',
    '股': 'gu',
    '票': 'piao',
    '债': 'zhai',
    '券': 'quan',
    '货': 'huo',
    '币': 'bi',
    '混': 'hun',
    '合': 'he',
    '成': 'cheng',
    '长': 'chang',
    '增': 'zeng',
    '价': 'jia',
    '值': 'zhi',
    '收': 'shou',
    '益': 'yi',
    '率': 'lv',
    '风': 'feng',
    '险': 'xian',
    '等': 'deng',
    '级': 'ji',
  };

  /// 构造函数
  FundSearchUseCase(this._repository);

  /// 执行基金搜索
  ///
  /// [criteria] 搜索条件
  /// 返回搜索结果
  Future<SearchResult> search(FundSearchCriteria criteria) async {
    final stopwatch = Stopwatch()..start();

    try {
      // 检查缓存
      final cacheKey = criteria.cacheKey;
      if (_searchCache.containsKey(cacheKey)) {
        final cachedResult = _searchCache[cacheKey]!;
        stopwatch.stop();
        _recordSearchTime(stopwatch.elapsedMilliseconds);

        return SearchResult(
          funds: cachedResult.funds,
          totalCount: cachedResult.totalCount,
          searchTimeMs: stopwatch.elapsedMilliseconds,
          criteria: criteria,
          hasMore: cachedResult.hasMore,
          suggestions: cachedResult.suggestions,
        );
      }

      // 获取基金数据
      List<Fund> funds;
      try {
        funds = await _repository.getFundList();
      } catch (e) {
        // 如果获取数据失败，返回空结果
        stopwatch.stop();
        _recordSearchTime(stopwatch.elapsedMilliseconds);

        return SearchResult(
          funds: const [],
          totalCount: 0,
          searchTimeMs: stopwatch.elapsedMilliseconds,
          criteria: criteria,
          hasMore: false,
          suggestions: const [],
        );
      }

      // 执行搜索算法
      final searchResults = _performSearch(criteria, funds);

      // 计算总数和分页
      final totalCount = searchResults.length;
      final paginatedResults = _applyPagination(searchResults, criteria);

      // 生成搜索建议
      final suggestions = _generateSuggestions(criteria, funds);

      // 创建搜索结果
      final result = SearchResult(
        funds: paginatedResults,
        totalCount: totalCount,
        searchTimeMs: stopwatch.elapsedMilliseconds,
        criteria: criteria,
        hasMore: (criteria.offset + criteria.limit) < totalCount,
        suggestions: suggestions,
      );

      // 缓存结果
      _cacheResult(cacheKey, result);

      stopwatch.stop();
      _recordSearchTime(stopwatch.elapsedMilliseconds);

      return result;
    } catch (e) {
      stopwatch.stop();
      _recordSearchTime(stopwatch.elapsedMilliseconds);

      // 返回错误结果
      return SearchResult(
        funds: const [],
        totalCount: 0,
        searchTimeMs: stopwatch.elapsedMilliseconds,
        criteria: criteria,
        hasMore: false,
        suggestions: const [],
      );
    }
  }

  /// 执行实际的搜索算法
  List<FundSearchMatch> _performSearch(
    FundSearchCriteria criteria,
    List<Fund> funds,
  ) {
    if (!criteria.isValid) {
      // 如果没有搜索条件，返回所有基金
      return funds
          .where((fund) => criteria.includeInactive || fund.status == 'active')
          .map((fund) => FundSearchMatch(
                fundCode: fund.code,
                fundName: fund.name,
                score: 1.0,
                matchedFields: const [SearchField.all],
                highlights: const {},
              ))
          .toList();
    }

    final keyword = criteria.keyword!.trim();
    final results = <FundSearchMatch>[];

    for (final fund in funds) {
      // 跳过非活跃基金（如果设置了）
      if (!criteria.includeInactive && fund.status != 'active') {
        continue;
      }

      final matchResult = _calculateMatchScore(criteria, fund, keyword);
      if (matchResult.score >= criteria.fuzzyThreshold) {
        results.add(matchResult);
      }
    }

    // 排序结果
    return _sortResults(results, criteria.sortBy);
  }

  /// 计算基金与搜索关键词的匹配分数
  FundSearchMatch _calculateMatchScore(
    FundSearchCriteria criteria,
    Fund fund,
    String keyword,
  ) {
    final searchFields = criteria.searchFields.isEmpty
        ? [
            SearchField.code,
            SearchField.name,
            SearchField.company,
            SearchField.type
          ]
        : criteria.searchFields;

    double maxScore = 0.0;
    final matchedFields = <SearchField>[];
    final highlights = <String, List<String>>{};

    // 根据搜索类型执行不同的匹配算法
    switch (criteria.searchType) {
      case SearchType.exact:
        maxScore =
            _exactMatch(keyword, fund, searchFields, matchedFields, highlights);
        break;
      case SearchType.code:
        maxScore = _codeMatch(
            keyword, fund, criteria.caseSensitive, matchedFields, highlights);
        break;
      case SearchType.name:
        maxScore = _nameMatch(
            keyword, fund, criteria.caseSensitive, matchedFields, highlights);
        break;
      case SearchType.mixed:
        maxScore = _mixedMatch(
            keyword, fund, criteria.caseSensitive, matchedFields, highlights);
        break;
      case SearchType.fullText:
        maxScore = _fullTextMatch(keyword, fund, searchFields,
            criteria.caseSensitive, matchedFields, highlights);
        break;
    }

    // 拼音搜索加分
    if (criteria.enablePinyinSearch) {
      final pinyinScore = _pinyinMatch(keyword, fund, searchFields);
      if (pinyinScore > maxScore) {
        maxScore = pinyinScore;
        matchedFields.add(SearchField.name);
      }
    }

    return FundSearchMatch(
      fundCode: fund.code,
      fundName: fund.name,
      score: maxScore,
      matchedFields: matchedFields,
      highlights: highlights,
    );
  }

  /// 精确匹配算法
  double _exactMatch(
    String keyword,
    Fund fund,
    List<SearchField> searchFields,
    List<SearchField> matchedFields,
    Map<String, List<String>> highlights,
  ) {
    double maxScore = 0.0;

    for (final field in searchFields) {
      final fieldValue = _getFieldValue(fund, field);
      if (fieldValue.isEmpty) continue;

      double score = 0.0;
      if (fieldValue == keyword) {
        // 完全匹配，最高分
        score = 1.0;
        _addHighlight(highlights, field as String, fieldValue);
      } else if (fieldValue.contains(keyword)) {
        // 部分匹配，中等分数
        score = 0.8;
        _addHighlight(
            highlights, field as String, _highlightText(fieldValue, keyword));
      }

      if (score > maxScore) {
        maxScore = score;
        matchedFields.clear();
        matchedFields.add(field);
      } else if (score == maxScore && score > 0) {
        matchedFields.add(field);
      }
    }

    return maxScore;
  }

  /// 基金代码匹配算法
  double _codeMatch(
    String keyword,
    Fund fund,
    bool caseSensitive,
    List<SearchField> matchedFields,
    Map<String, List<String>> highlights,
  ) {
    final code = caseSensitive ? fund.code : fund.code.toLowerCase();
    final searchKeyword = caseSensitive ? keyword : keyword.toLowerCase();

    if (code == searchKeyword) {
      matchedFields.add(SearchField.code);
      _addHighlight(highlights, 'code', fund.code);
      return 1.0;
    } else if (code.contains(searchKeyword)) {
      matchedFields.add(SearchField.code);
      _addHighlight(highlights, 'code', _highlightText(fund.code, keyword));
      return 0.9;
    }

    return 0.0;
  }

  /// 基金名称匹配算法
  double _nameMatch(
    String keyword,
    Fund fund,
    bool caseSensitive,
    List<SearchField> matchedFields,
    Map<String, List<String>> highlights,
  ) {
    final name = caseSensitive ? fund.name : fund.name.toLowerCase();
    final searchKeyword = caseSensitive ? keyword : keyword.toLowerCase();

    if (name == searchKeyword) {
      matchedFields.add(SearchField.name);
      _addHighlight(highlights, 'name', fund.name);
      return 1.0;
    } else if (name.contains(searchKeyword)) {
      matchedFields.add(SearchField.name);
      _addHighlight(highlights, 'name', _highlightText(fund.name, keyword));
      return 0.8;
    }

    return 0.0;
  }

  /// 混合匹配算法（代码+名称）
  double _mixedMatch(
    String keyword,
    Fund fund,
    bool caseSensitive,
    List<SearchField> matchedFields,
    Map<String, List<String>> highlights,
  ) {
    final codeScore =
        _codeMatch(keyword, fund, caseSensitive, matchedFields, highlights);
    final nameScore =
        _nameMatch(keyword, fund, caseSensitive, matchedFields, highlights);

    if (codeScore > 0 && nameScore > 0) {
      // 代码和名称都匹配，最高分
      return 1.0;
    } else if (codeScore > 0) {
      return codeScore * 0.9; // 代码匹配权重稍高
    } else if (nameScore > 0) {
      return nameScore * 0.8;
    }

    return 0.0;
  }

  /// 全文搜索匹配算法
  double _fullTextMatch(
    String keyword,
    Fund fund,
    List<SearchField> searchFields,
    bool caseSensitive,
    List<SearchField> matchedFields,
    Map<String, List<String>> highlights,
  ) {
    double totalScore = 0.0;
    int matchCount = 0;

    for (final field in searchFields) {
      final fieldValue = _getFieldValue(fund, field);
      if (fieldValue.isEmpty) continue;

      final searchValue = caseSensitive ? fieldValue : fieldValue.toLowerCase();
      final searchKeyword = caseSensitive ? keyword : keyword.toLowerCase();

      if (searchValue.contains(searchKeyword)) {
        totalScore += 0.7;
        matchCount++;
        matchedFields.add(field);
        _addHighlight(
            highlights, field.name, _highlightText(fieldValue, keyword));
      }
    }

    return matchCount > 0 ? totalScore / matchCount : 0.0;
  }

  /// 拼音匹配算法
  double _pinyinMatch(
      String keyword, Fund fund, List<SearchField> searchFields) {
    double maxScore = 0.0;

    for (final field in searchFields) {
      if (field != SearchField.name) continue; // 只对名称进行拼音匹配

      final fieldValue = fund.name;
      final pinyinValue = _convertToPinyin(fieldValue);
      final pinyinKeyword = _convertToPinyin(keyword);

      if (pinyinValue.contains(pinyinKeyword)) {
        maxScore = 0.6; // 拼音匹配给予中等分数
      }
    }

    return maxScore;
  }

  /// 简化的拼音转换（仅支持常用字符）
  String _convertToPinyin(String text) {
    final result = StringBuffer();
    for (final char in text.split('')) {
      result.write(_pinyinMap[char] ?? char);
    }
    return result.toString();
  }

  /// 获取基金指定字段的值
  String _getFieldValue(Fund fund, SearchField field) {
    switch (field) {
      case SearchField.code:
        return fund.code;
      case SearchField.name:
        return fund.name;
      case SearchField.type:
        return fund.type;
      case SearchField.company:
        return fund.company;
      case SearchField.manager:
        return fund.manager;
      case SearchField.strategy:
        return ''; // Fund实体中没有strategy字段
      case SearchField.all:
        return '${fund.code} ${fund.name} ${fund.type} ${fund.company} ${fund.manager}';
    }
  }

  /// 添加高亮信息
  void _addHighlight(
      Map<String, List<String>> highlights, String field, String text) {
    if (!highlights.containsKey(field)) {
      highlights[field] = [];
    }
    highlights[field]!.add(text);
  }

  /// 高亮文本中的关键词
  String _highlightText(String text, String keyword) {
    final index = text.indexOf(keyword);
    if (index == -1) return text;

    return '${text.substring(0, index)}**$keyword**${text.substring(index + keyword.length)}';
  }

  /// 排序搜索结果
  List<FundSearchMatch> _sortResults(
    List<FundSearchMatch> results,
    SearchSortType sortBy,
  ) {
    switch (sortBy) {
      case SearchSortType.relevance:
        results.sort((a, b) => b.score.compareTo(a.score));
        break;
      case SearchSortType.code:
        results.sort((a, b) => a.fundCode.compareTo(b.fundCode));
        break;
      case SearchSortType.name:
        results.sort((a, b) => a.fundName.compareTo(b.fundName));
        break;
      // 其他排序方式需要访问原始Fund数据，这里简化处理
      default:
        results.sort((a, b) => b.score.compareTo(a.score));
        break;
    }
    return results;
  }

  /// 应用分页
  List<FundSearchMatch> _applyPagination(
    List<FundSearchMatch> results,
    FundSearchCriteria criteria,
  ) {
    final start = criteria.offset;
    final end = (start + criteria.limit).clamp(0, results.length);

    if (start >= results.length) {
      return [];
    }

    return results.sublist(start, end);
  }

  /// 生成搜索建议
  List<String> _generateSuggestions(
    FundSearchCriteria criteria,
    List<Fund> funds,
  ) {
    final suggestions = <String>[];

    if (!criteria.isValid || criteria.keyword!.length < 2) {
      return suggestions;
    }

    final keyword = criteria.keyword!.toLowerCase();
    final usedSuggestions = <String>{};

    // 基于基金名称生成建议
    for (final fund in funds) {
      if (fund.name.toLowerCase().startsWith(keyword) &&
          !usedSuggestions.contains(fund.name)) {
        suggestions.add(fund.name);
        usedSuggestions.add(fund.name);
        if (suggestions.length >= 5) break;
      }
    }

    // 基于基金代码生成建议
    if (suggestions.length < 5) {
      for (final fund in funds) {
        if (fund.code.toLowerCase().startsWith(keyword) &&
            !usedSuggestions.contains(fund.code)) {
          suggestions.add(fund.code);
          usedSuggestions.add(fund.code);
          if (suggestions.length >= 5) break;
        }
      }
    }

    return suggestions;
  }

  /// 缓存搜索结果
  void _cacheResult(String cacheKey, SearchResult result) {
    // 如果缓存已满，移除最旧的条目
    if (_searchCache.length >= maxCacheSize) {
      final oldestKey = _searchCache.keys.first;
      _searchCache.remove(oldestKey);
    }

    _searchCache[cacheKey] = result;
  }

  /// 记录搜索时间
  void _recordSearchTime(int timeMs) {
    _searchTimes.add(timeMs);

    // 只保留最近100次的搜索时间记录
    if (_searchTimes.length > 100) {
      _searchTimes.removeAt(0);
    }
  }

  /// 获取搜索性能统计
  Map<String, dynamic> getPerformanceStats() {
    if (_searchTimes.isEmpty) {
      return {
        'averageSearchTime': 0,
        'maxSearchTime': 0,
        'minSearchTime': 0,
        'totalSearches': 0,
        'cacheSize': _searchCache.length,
      };
    }

    final averageTime =
        _searchTimes.reduce((a, b) => a + b) / _searchTimes.length;
    final maxTime = _searchTimes.reduce((a, b) => a > b ? a : b);
    final minTime = _searchTimes.reduce((a, b) => a < b ? a : b);

    return {
      'averageSearchTime': averageTime.round(),
      'maxSearchTime': maxTime,
      'minSearchTime': minTime,
      'totalSearches': _searchTimes.length,
      'cacheSize': _searchCache.length,
    };
  }

  /// 清空搜索缓存
  void clearCache() {
    _searchCache.clear();
  }

  /// 预热搜索缓存
  Future<void> warmupCache() async {
    try {
      // 预加载一些常见的搜索结果
      final commonSearches = [
        FundSearchCriteria.keyword('基金'),
        FundSearchCriteria.keyword('股票'),
        FundSearchCriteria.keyword('债券'),
        FundSearchCriteria.keyword('货币'),
      ];

      for (final criteria in commonSearches) {
        await search(criteria);
      }
    } catch (e) {
      // 预热失败不影响主要功能
    }
  }
}
