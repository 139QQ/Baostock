import 'dart:async';
import 'dart:math';

import '../../../../core/utils/logger.dart';
import '../models/fund_ranking.dart';

/// 搜索服务
///
/// 职责：
/// - 提供高性能的基金搜索功能
/// - 搜索历史管理
/// - 搜索建议生成
/// - 模糊搜索算法
class SearchService {
  // 搜索配置
  static const int _maxHistoryItems = 50;
  static const int _maxSuggestions = 10;
  static const Duration _searchDebounce = Duration(milliseconds: 300);

  // 搜索缓存
  final Map<String, List<FundRanking>> _searchCache = {};
  final Map<String, DateTime> _searchTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 10);

  // 搜索历史
  final List<String> _searchHistory = [];

  // 索引结构
  final Map<String, Set<int>> _nameIndex = {};
  final Map<String, Set<int>> _codeIndex = {};
  final Map<String, Set<int>> _typeIndex = {};
  List<FundRanking> _indexedFunds = [];

  Timer? _debounceTimer;

  /// 构建搜索索引
  void buildIndex(List<FundRanking> funds) {
    AppLogger.debug('🔍 SearchService: 构建搜索索引 (${funds.length}条数据)');

    _indexedFunds = funds;
    _nameIndex.clear();
    _codeIndex.clear();
    _typeIndex.clear();

    final stopwatch = Stopwatch()..start();

    for (int i = 0; i < funds.length; i++) {
      final fund = funds[i];

      // 构建名称索引（支持分词）
      _buildNameIndex(fund.fundName, i);
      _buildNameIndex(fund.shortName, i);

      // 构建代码索引
      _addToIndex(_codeIndex, fund.fundCode, i);
      _addToIndex(_codeIndex, fund.fundCode.toLowerCase(), i);

      // 构建类型索引
      _addToIndex(_typeIndex, fund.fundType, i);
      _addToIndex(_typeIndex, fund.shortType, i);
    }

    stopwatch.stop();
    AppLogger.debug(
        '✅ SearchService: 索引构建完成，耗时: ${stopwatch.elapsedMilliseconds}ms');
  }

  /// 构建名称索引（支持分词）
  void _buildNameIndex(String name, int index) {
    // 完整名称
    _addToIndex(_nameIndex, name.toLowerCase(), index);
    _addToIndex(_nameIndex, name, index);

    // 分词索引
    final words = _segmentName(name);
    for (final word in words) {
      if (word.length >= 2) {
        // 只索引长度>=2的词
        _addToIndex(_nameIndex, word, index);
      }
    }
  }

  /// 分词处理
  List<String> _segmentName(String name) {
    final words = <String>[];
    final buffer = StringBuffer();

    for (int i = 0; i < name.length; i++) {
      final char = name[i];

      if (_isChinese(char) || _isEnglish(char)) {
        buffer.write(char);
      } else {
        if (buffer.isNotEmpty) {
          words.add(buffer.toString());
          buffer.clear();
        }
      }
    }

    if (buffer.isNotEmpty) {
      words.add(buffer.toString());
    }

    // 添加所有可能的连续组合
    final combinations = <String>[];
    for (int i = 0; i < words.length; i++) {
      for (int j = i + 1; j <= min(i + 4, words.length); j++) {
        combinations.add(words.sublist(i, j).join());
      }
    }

    return [...words, ...combinations];
  }

  /// 判断是否为中文字符
  bool _isChinese(String char) {
    final code = char.codeUnitAt(0);
    return code >= 0x4E00 && code <= 0x9FFF;
  }

  /// 判断是否为英文字符
  bool _isEnglish(String char) {
    final code = char.codeUnitAt(0);
    return (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
  }

  /// 添加到索引
  void _addToIndex(Map<String, Set<int>> index, String key, int value) {
    final normalizedKey = key.toLowerCase().trim();
    if (normalizedKey.isEmpty) return;

    index.putIfAbsent(normalizedKey, () => <int>{}).add(value);
  }

  /// 执行搜索
  Future<SearchResult> search(String query, {SearchOptions? options}) async {
    final opts = options ?? const SearchOptions();

    AppLogger.debug('🔍 SearchService: 搜索基金 (query: "$query", options: $opts)');

    if (query.isEmpty) {
      return SearchResult.success(
        results: [],
        query: query,
        searchTime: Duration.zero,
      );
    }

    final stopwatch = Stopwatch()..start();

    try {
      // 检查缓存
      final cacheKey = _generateCacheKey(query, opts);
      if (opts.useCache && _isSearchCacheValid(cacheKey)) {
        final cachedResults = _searchCache[cacheKey]!;
        stopwatch.stop();

        AppLogger.debug('✅ SearchService: 使用缓存结果 (${cachedResults.length}条)');
        return SearchResult.success(
          results: cachedResults,
          query: query,
          searchTime: stopwatch.elapsed,
          fromCache: true,
        );
      }

      // 执行搜索
      final results = _performSearch(query, opts);

      // 更新缓存
      if (opts.cacheResults) {
        _searchCache[cacheKey] = results;
        _searchTimestamps[cacheKey] = DateTime.now();
      }

      // 添加到搜索历史
      _addToSearchHistory(query);

      stopwatch.stop();

      AppLogger.debug(
          '✅ SearchService: 搜索完成 (${results.length}条结果), 耗时: ${stopwatch.elapsedMilliseconds}ms');

      return SearchResult.success(
        results: results,
        query: query,
        searchTime: stopwatch.elapsed,
      );
    } catch (e) {
      AppLogger.debug('❌ SearchService: 搜索失败: $e');
      return SearchResult.failure(
        errorMessage: '搜索失败: $e',
        query: query,
        searchTime: stopwatch.elapsed,
      );
    }
  }

  /// 执行实际搜索
  List<FundRanking> _performSearch(String query, SearchOptions options) {
    final normalizedQuery = query.toLowerCase().trim();
    final resultIndices = <int>{};

    // 1. 精确匹配（优先级最高）
    if (options.exactMatch) {
      _addExactMatches(normalizedQuery, resultIndices);
    }

    // 2. 模糊匹配
    _addFuzzyMatches(normalizedQuery, resultIndices, options.fuzzyThreshold);

    // 3. 前缀匹配
    _addPrefixMatches(normalizedQuery, resultIndices);

    // 转换为基金对象
    var results = resultIndices
        .map((index) => _indexedFunds[index])
        .where((fund) => fund != null)
        .cast<FundRanking>()
        .toList();

    // 4. 应用过滤器
    if (options.filters != null) {
      results = _applyFilters(results, options.filters!);
    }

    // 5. 排序
    results = _sortResults(results, normalizedQuery, options.sortBy);

    // 6. 限制结果数量
    if (options.limit > 0) {
      results = results.take(options.limit).toList();
    }

    return results;
  }

  /// 添加精确匹配结果
  void _addExactMatches(String query, Set<int> resultIndices) {
    // 检查代码精确匹配
    if (_codeIndex.containsKey(query)) {
      resultIndices.addAll(_codeIndex[query]!);
    }

    // 检查名称精确匹配
    if (_nameIndex.containsKey(query)) {
      resultIndices.addAll(_nameIndex[query]!);
    }
  }

  /// 添加模糊匹配结果
  void _addFuzzyMatches(
      String query, Set<int> resultIndices, double threshold) {
    for (final entry in _nameIndex.entries) {
      final key = entry.key;
      final similarity = _calculateSimilarity(query, key);

      if (similarity >= threshold) {
        resultIndices.addAll(entry.value);
      }
    }
  }

  /// 添加前缀匹配结果
  void _addPrefixMatches(String query, Set<int> resultIndices) {
    for (final entry in _nameIndex.entries) {
      if (entry.key.startsWith(query)) {
        resultIndices.addAll(entry.value);
      }
    }

    for (final entry in _codeIndex.entries) {
      if (entry.key.startsWith(query)) {
        resultIndices.addAll(entry.value);
      }
    }
  }

  /// 应用过滤器
  List<FundRanking> _applyFilters(
      List<FundRanking> results, List<SearchFilter> filters) {
    return results.where((fund) {
      return filters.every((filter) => _matchesFilter(fund, filter));
    }).toList();
  }

  /// 检查是否匹配过滤器
  bool _matchesFilter(FundRanking fund, SearchFilter filter) {
    switch (filter.type) {
      case FilterType.fundType:
        return fund.fundType.contains(filter.value);
      case FilterType.returnRange:
        final range = filter.value.split('-');
        if (range.length == 2) {
          final minReturn =
              double.tryParse(range[0]) ?? double.negativeInfinity;
          final maxReturn = double.tryParse(range[1]) ?? double.infinity;
          return fund.oneYearReturn >= minReturn &&
              fund.oneYearReturn <= maxReturn;
        }
        return false;
      case FilterType.riskLevel:
        return fund.getRiskLevel().displayName == filter.value;
      case FilterType.minFundSize:
        final minSize = double.tryParse(filter.value) ?? 0.0;
        return fund.fundSize >= minSize;
      case FilterType.exclude:
        return !fund.fundName.contains(filter.value);
    }
  }

  /// 排序结果
  List<FundRanking> _sortResults(
      List<FundRanking> results, String query, SearchSortBy sortBy) {
    switch (sortBy) {
      case SearchSortBy.relevance:
        final scoredResults = results.map((fund) {
          final score = _calculateRelevanceScore(fund, query);
          return MapEntry(fund, score);
        }).toList();
        scoredResults.sort((a, b) => b.value.compareTo(a.value));
        return scoredResults.map((entry) => entry.key).toList();

      case SearchSortBy.return1Y:
        return results
          ..sort((a, b) => b.oneYearReturn.compareTo(a.oneYearReturn));

      case SearchSortBy.return3Y:
        return results
          ..sort((a, b) => b.threeYearReturn.compareTo(a.threeYearReturn));

      case SearchSortBy.fundSize:
        return results..sort((a, b) => b.fundSize.compareTo(a.fundSize));

      case SearchSortBy.fundName:
        return results..sort((a, b) => a.fundName.compareTo(b.fundName));

      case SearchSortBy.fundCode:
        return results..sort((a, b) => a.fundCode.compareTo(b.fundCode));
    }
  }

  /// 计算相关性评分
  double _calculateRelevanceScore(FundRanking fund, String query) {
    double score = 0;

    // 代码完全匹配（最高分）
    if (fund.fundCode.toLowerCase() == query) {
      score += 100;
    } else if (fund.fundCode.toLowerCase().startsWith(query)) {
      score += 80;
    } else if (fund.fundCode.toLowerCase().contains(query)) {
      score += 60;
    }

    // 名称匹配
    final nameLower = fund.fundName.toLowerCase();
    if (nameLower == query) {
      score += 90;
    } else if (nameLower.startsWith(query)) {
      score += 70;
    } else if (nameLower.contains(query)) {
      score += 50;
    }

    // 分词匹配
    final words = _segmentName(fund.fundName);
    for (final word in words) {
      if (word.toLowerCase() == query) {
        score += 40;
      } else if (word.toLowerCase().startsWith(query)) {
        score += 30;
      }
    }

    // 收益率加分
    if (fund.oneYearReturn > 0) {
      score += min(fund.oneYearReturn, 20); // 最多加20分
    }

    return score;
  }

  /// 计算字符串相似度（使用编辑距离）
  double _calculateSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;

    final maxLength = max(s1.length, s2.length);
    if (maxLength == 0) return 1.0;

    final distance = _levenshteinDistance(s1, s2);
    return 1.0 - (distance / maxLength);
  }

  /// 计算编辑距离
  int _levenshteinDistance(String s1, String s2) {
    final matrix = List.generate(
      s1.length + 1,
      (i) => List.generate(s2.length + 1, (j) => 0),
    );

    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = min(
          matrix[i - 1][j] + 1, // deletion
          min(
            matrix[i][j - 1] + 1, // insertion
            matrix[i - 1][j - 1] + cost, // substitution
          ),
        );
      }
    }

    return matrix[s1.length][s2.length];
  }

  /// 获取最近搜索
  List<String> _getRecentSearches(int limit) {
    return <String>[]; // TODO: 实现搜索历史功能
  }

  /// 获取搜索建议
  List<String> getSearchSuggestions(String query, {int limit = 10}) {
    if (query.isEmpty) {
      return _getRecentSearches(limit);
    }

    final suggestions = <String>[];
    final normalizedQuery = query.toLowerCase();

    // 从基金名称中提取建议
    for (final fund in _indexedFunds) {
      if (fund.fundName.toLowerCase().startsWith(normalizedQuery)) {
        suggestions.add(fund.fundName);
        if (suggestions.length >= limit) break;
      }
    }

    // 从基金代码中提取建议
    if (suggestions.length < limit) {
      for (final fund in _indexedFunds) {
        if (fund.fundCode.toLowerCase().startsWith(normalizedQuery)) {
          suggestions.add(fund.fundCode);
          if (suggestions.length >= limit) break;
        }
      }
    }

    return suggestions;
  }

  /// 获取最近搜索
  List<String> getRecentSearches([int limit = 10]) {
    return _searchHistory.reversed.take(limit).toList();
  }

  /// 清除搜索历史
  void clearSearchHistory() {
    _searchHistory.clear();
    AppLogger.debug('🗑️ SearchService: 已清除搜索历史');
  }

  /// 添加到搜索历史
  void _addToSearchHistory(String query) {
    if (query.trim().isEmpty) return;

    // 移除重复项
    _searchHistory.remove(query);

    // 添加到开头
    _searchHistory.insert(0, query);

    // 限制历史记录数量
    if (_searchHistory.length > _maxHistoryItems) {
      _searchHistory.removeRange(_maxHistoryItems, _searchHistory.length);
    }
  }

  /// 生成缓存键
  String _generateCacheKey(String query, SearchOptions options) {
    return '${query}_${options.hashCode}';
  }

  /// 检查搜索缓存是否有效
  bool _isSearchCacheValid(String cacheKey) {
    final timestamp = _searchTimestamps[cacheKey];
    if (timestamp == null) return false;

    return DateTime.now().difference(timestamp) < _cacheExpiry;
  }

  /// 清除缓存
  void clearCache() {
    _searchCache.clear();
    _searchTimestamps.clear();
    AppLogger.debug('🗑️ SearchService: 已清除搜索缓存');
  }

  /// 获取搜索统计信息
  SearchStatistics getStatistics() {
    return SearchStatistics(
      indexedFunds: _indexedFunds.length,
      nameIndexSize: _nameIndex.length,
      codeIndexSize: _codeIndex.length,
      typeIndexSize: _typeIndex.length,
      cacheSize: _searchCache.length,
      historySize: _searchHistory.length,
    );
  }
}

/// 搜索选项
class SearchOptions {
  final bool exactMatch;
  final bool useCache;
  final bool cacheResults;
  final double fuzzyThreshold;
  final int limit;
  final SearchSortBy sortBy;
  final List<SearchFilter>? filters;

  const SearchOptions({
    this.exactMatch = false,
    this.useCache = true,
    this.cacheResults = true,
    this.fuzzyThreshold = 0.6,
    this.limit = 100,
    this.sortBy = SearchSortBy.relevance,
    this.filters,
  });

  @override
  String toString() {
    return 'SearchOptions(exactMatch: $exactMatch, useCache: $useCache, fuzzyThreshold: $fuzzyThreshold, limit: $limit, sortBy: $sortBy)';
  }
}

/// 搜索过滤器
class SearchFilter {
  final FilterType type;
  final String value;

  const SearchFilter({
    required this.type,
    required this.value,
  });

  @override
  String toString() {
    return 'SearchFilter(type: $type, value: $value)';
  }
}

/// 过滤器类型
enum FilterType {
  fundType, // 基金类型
  returnRange, // 收益率范围
  riskLevel, // 风险等级
  minFundSize, // 最小规模
  exclude, // 排除
}

/// 搜索排序方式
enum SearchSortBy {
  relevance, // 相关性
  return1Y, // 近1年收益
  return3Y, // 近3年收益
  fundSize, // 基金规模
  fundName, // 基金名称
  fundCode, // 基金代码
}

/// 搜索结果
class SearchResult {
  final List<FundRanking> results;
  final String query;
  final Duration searchTime;
  final String? errorMessage;
  final bool isSuccess;
  final bool fromCache;

  const SearchResult._({
    required this.results,
    required this.query,
    required this.searchTime,
    this.errorMessage,
    required this.isSuccess,
    this.fromCache = false,
  });

  factory SearchResult.success({
    required List<FundRanking> results,
    required String query,
    required Duration searchTime,
    bool fromCache = false,
  }) {
    return SearchResult._(
      results: results,
      query: query,
      searchTime: searchTime,
      isSuccess: true,
      fromCache: fromCache,
    );
  }

  factory SearchResult.failure({
    required String errorMessage,
    required String query,
    required Duration searchTime,
  }) {
    return SearchResult._(
      results: const [],
      query: query,
      searchTime: searchTime,
      errorMessage: errorMessage,
      isSuccess: false,
    );
  }

  bool get isFailure => !isSuccess;
}

/// 搜索统计信息
class SearchStatistics {
  final int indexedFunds;
  final int nameIndexSize;
  final int codeIndexSize;
  final int typeIndexSize;
  final int cacheSize;
  final int historySize;

  const SearchStatistics({
    required this.indexedFunds,
    required this.nameIndexSize,
    required this.codeIndexSize,
    required this.typeIndexSize,
    required this.cacheSize,
    required this.historySize,
  });

  @override
  String toString() {
    return 'SearchStatistics(indexedFunds: $indexedFunds, nameIndexSize: $nameIndexSize, codeIndexSize: $codeIndexSize, typeIndexSize: $typeIndexSize, cacheSize: $cacheSize, historySize: $historySize)';
  }
}
