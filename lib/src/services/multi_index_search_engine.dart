import 'dart:collection';
import 'package:logger/logger.dart';
import '../models/fund_info.dart';

/// 多索引组合搜索引擎
///
/// 针对万级基金数据的多场景高效检索，采用"主索引+辅助索引"组合架构：
/// 1. 哈希表：O(1)精确匹配（基金代码、全称）
/// 2. 前缀树：O(k)模糊/前缀匹配（k为关键词长度）
/// 3. 倒排索引：O(m+n)多维筛选（m为条件数，n为结果数）
///
/// 性能目标：
/// - 精确匹配：<1ms
/// - 前缀匹配：<5ms
/// - 多维筛选：<10ms
/// - 内存占用：<50MB
class MultiIndexSearchEngine {
  static final MultiIndexSearchEngine _instance =
      MultiIndexSearchEngine._internal();
  factory MultiIndexSearchEngine() => _instance;
  MultiIndexSearchEngine._internal();

  final Logger _logger = Logger();

  // ========== 核心索引结构 ==========

  /// 1. 哈希表索引 - 精确匹配 O(1)
  final Map<String, FundInfo> _codeHashTable = {}; // 基金代码 → 基金信息
  final Map<String, FundInfo> _nameHashTable = {}; // 基金全称 → 基金信息

  /// 2. 前缀树索引 - 模糊/前缀匹配 O(k)
  final PrefixTree _codePrefixTree = PrefixTree(); // 基金代码前缀树
  final PrefixTree _namePrefixTree = PrefixTree(); // 基金名称前缀树
  final PrefixTree _pinyinPrefixTree = PrefixTree(); // 拼音前缀树

  /// 3. 倒排索引 - 多维筛选 O(m+n)
  final InvertedIndex _invertedIndex = InvertedIndex();

  /// 4. 辅助数据结构
  List<FundInfo> _masterFundList = []; // 主基金列表（用于排序和分页）
  bool _isBuilt = false; // 索引构建标志

  // ========== 公共接口 ==========

  /// 构建所有索引 - 优化版本，避免UI阻塞
  Future<void> buildIndexes(List<FundInfo> funds) async {
    if (funds.isEmpty) {
      _logger.w('⚠️ 基金数据为空，跳过索引构建');
      return;
    }

    final stopwatch = Stopwatch()..start();
    _logger.i('🚀 开始构建多级索引，基金数量: ${funds.length}');

    // 清空现有索引
    _clearIndexes();

    // 保存主列表引用
    _masterFundList = List.from(funds);

    // 🔥 优化：直接在主线程中分批构建，避免isolate序列化开销
    try {
      // 分批构建索引，避免阻塞UI
      await _buildHashIndexes(funds);
      await _buildPrefixIndexes(funds);
      await _buildInvertedIndex(funds);
    } catch (e) {
      _logger.e('❌ 索引构建失败: $e');
      rethrow;
    }

    _isBuilt = true;
    stopwatch.stop();

    _logger.i('✅ 多级索引构建完成');
    _logger.i('⏱️ 构建耗时: ${stopwatch.elapsedMilliseconds}ms');
    _logIndexStats();
  }

  /// 智能搜索 - 根据查询类型自动选择最优索引
  SearchResult search(String query,
      {SearchOptions options = const SearchOptions()}) {
    // 输入验证
    if (query.trim().isEmpty) {
      return SearchResult.empty(error: '搜索查询不能为空');
    }

    if (!_isBuilt) {
      _logger.w('⚠️ 索引未构建，返回空结果');
      return SearchResult.empty(error: '搜索索引未构建完成');
    }

    final stopwatch = Stopwatch()..start();
    final searchContext = SearchContext(query: query.trim(), options: options);

    List<FundInfo> results = [];

    try {
      // 1. 精确匹配 - 哈希表 O(1)
      if (searchContext.isExactMatch) {
        results = _exactSearch(searchContext);
      }
      // 2. 前缀匹配 - 前缀树 O(k)
      else if (searchContext.isPrefixMatch) {
        results = _prefixSearch(searchContext);
      }
      // 3. 模糊匹配 - 组合索引
      else if (searchContext.isFuzzyMatch) {
        results = _fuzzySearch(searchContext);
      }
      // 4. 多维筛选 - 倒排索引
      else if (searchContext.hasFilters) {
        results = _filterSearch(searchContext);
      }
      // 5. 通用搜索 - 回退方案
      else {
        results = _generalSearch(searchContext);
      }

      // 后处理：排序、分页等
      results = _postProcessResults(results, searchContext);

      stopwatch.stop();

      _logger.d(
          '🔍 搜索完成: "$query" → ${results.length} 结果, 耗时: ${stopwatch.elapsedMilliseconds}ms');

      return SearchResult(
        query: query,
        funds: results,
        searchTimeMs: stopwatch.elapsedMilliseconds,
        totalFound: results.length,
        indexUsed: _getIndexUsed(searchContext),
      );
    } catch (e, stackTrace) {
      _logger.e('❌ 搜索失败: $e', error: e, stackTrace: stackTrace);
      return SearchResult.empty(error: '搜索过程中发生错误: ${e.toString()}');
    }
  }

  /// 多条件搜索
  SearchResult multiCriteriaSearch(MultiCriteriaCriteria criteria) {
    if (!_isBuilt) {
      return SearchResult.empty();
    }

    final stopwatch = Stopwatch()..start();

    // 使用倒排索引进行多条件筛选
    Set<int> candidateIndices = _invertedIndex.multiCriteriaSearch(criteria);

    // 转换为基金列表
    List<FundInfo> results =
        candidateIndices.map((index) => _masterFundList[index]).toList();

    // 应用排序和分页
    results = _applySorting(results, criteria.sortBy, criteria.sortOrder);
    if (criteria.limit != null && criteria.limit! > 0) {
      results = results.take(criteria.limit!).toList();
    }

    stopwatch.stop();

    return SearchResult(
      query: criteria.toString(),
      funds: results,
      searchTimeMs: stopwatch.elapsedMilliseconds,
      totalFound: candidateIndices.length,
      indexUsed: 'inverted_index',
    );
  }

  /// 获取搜索建议
  List<String> getSuggestions(String prefix, {int maxSuggestions = 10}) {
    if (!_isBuilt || prefix.length < 2) return [];

    final suggestions = <String>[];

    // 从多个前缀树获取建议
    suggestions
        .addAll(_codePrefixTree.getSuggestions(prefix, maxSuggestions ~/ 3));
    suggestions
        .addAll(_namePrefixTree.getSuggestions(prefix, maxSuggestions ~/ 3));
    suggestions
        .addAll(_pinyinPrefixTree.getSuggestions(prefix, maxSuggestions ~/ 3));

    // 去重并限制数量
    final uniqueSuggestions = LinkedHashSet<String>.from(suggestions).toList();
    return uniqueSuggestions.take(maxSuggestions).toList();
  }

  /// 获取索引统计信息
  IndexStats getIndexStats() {
    if (!_isBuilt) {
      return IndexStats.empty();
    }

    return IndexStats(
      totalFunds: _masterFundList.length,
      hashTableSize: _codeHashTable.length + _nameHashTable.length,
      prefixTreeNodes: _codePrefixTree.nodeCount +
          _namePrefixTree.nodeCount +
          _pinyinPrefixTree.nodeCount,
      invertedIndexEntries: _invertedIndex.entryCount,
      memoryEstimateMB: _estimateMemoryUsage(),
      isBuilt: _isBuilt,
    );
  }

  // ========== 私有方法 - 索引构建 ==========

  /// 构建哈希表索引 - 优化版本
  Future<void> _buildHashIndexes(List<FundInfo> funds) async {
    await _processBatch<FundInfo>(funds, (fund) async {
      _codeHashTable[fund.code] = fund;
      _nameHashTable[fund.name.toLowerCase()] = fund;
    });
    _logger.d(
        '✅ 哈希表索引构建完成: ${_codeHashTable.length} 代码 + ${_nameHashTable.length} 名称');
  }

  /// 构建前缀树索引 - 优化版本
  Future<void> _buildPrefixIndexes(List<FundInfo> funds) async {
    await _processBatch<FundInfo>(funds, (fund) async {
      // 基金代码前缀树
      _codePrefixTree.insert(fund.code, fund.code);

      // 基金名称前缀树（分词）
      final nameWords = _tokenizeChinese(fund.name);
      for (final word in nameWords) {
        _namePrefixTree.insert(word, fund.code);
      }

      // 拼音前缀树
      if (fund.pinyinAbbr.isNotEmpty) {
        _pinyinPrefixTree.insert(fund.pinyinAbbr.toLowerCase(), fund.code);
      }
      if (fund.pinyinFull.isNotEmpty) {
        _pinyinPrefixTree.insert(fund.pinyinFull.toLowerCase(), fund.code);
      }
    });
    _logger.d(
        '✅ 前缀树索引构建完成: 代码${_codePrefixTree.nodeCount} + 名称${_namePrefixTree.nodeCount} + 拼音${_pinyinPrefixTree.nodeCount} 节点');
  }

  /// 构建倒排索引
  Future<void> _buildInvertedIndex(List<FundInfo> funds) async {
    for (int i = 0; i < funds.length; i++) {
      final fund = funds[i];

      // 基金类型索引
      if (fund.type.isNotEmpty) {
        _invertedIndex.addIndex('type', fund.simplifiedType, i);
      }

      // 基金公司索引（从名称中提取）
      final company = _extractCompany(fund.name);
      if (company.isNotEmpty) {
        _invertedIndex.addIndex('company', company, i);
      }

      // 风险等级索引（基于类型推断）
      final riskLevel = _inferRiskLevel(fund.type);
      _invertedIndex.addIndex('risk', riskLevel, i);

      // 业绩标签索引（可扩展）
      _invertedIndex.addIndex('all', fund.code, i); // 通用索引
    }
    _logger.d('✅ 倒排索引构建完成: ${_invertedIndex.entryCount} 个条目');
  }

  // ========== 私有方法 - 搜索实现 ==========

  /// 精确搜索 - 使用哈希表 O(1)
  List<FundInfo> _exactSearch(SearchContext context) {
    final results = <FundInfo>[];
    final query = context.query;

    // 优先代码匹配
    final fundByCode = _codeHashTable[query];
    if (fundByCode != null) {
      results.add(fundByCode);
    }

    // 其次名称匹配
    final fundByName = _nameHashTable[query.toLowerCase()];
    if (fundByName != null && !results.any((f) => f.code == fundByName.code)) {
      results.add(fundByName);
    }

    return results;
  }

  /// 前缀搜索 - 使用前缀树 O(k)
  List<FundInfo> _prefixSearch(SearchContext context) {
    final codeResults = _codePrefixTree.search(context.query);
    final nameResults = _namePrefixTree.search(context.query);
    final pinyinResults = _pinyinPrefixTree.search(context.query.toLowerCase());

    // 合并结果并去重
    final allCodes = <String>{}
      ..addAll(codeResults)
      ..addAll(nameResults)
      ..addAll(pinyinResults);

    return allCodes
        .map((code) => _codeHashTable[code])
        .where((fund) => fund != null)
        .cast<FundInfo>()
        .toList();
  }

  /// 模糊搜索 - 组合索引策略
  List<FundInfo> _fuzzySearch(SearchContext context) {
    final results = <FundInfo>[];

    // 1. 尝试前缀匹配
    results.addAll(_prefixSearch(context));

    // 2. 如果结果不足，尝试包含匹配
    if (results.length < context.options.minResults) {
      for (final fund in _masterFundList) {
        if (results.length >= context.options.maxResults) break;

        if (_containsMatch(fund, context.query) &&
            !results.any((f) => f.code == fund.code)) {
          results.add(fund);
        }
      }
    }

    return results;
  }

  /// 筛选搜索 - 使用倒排索引
  List<FundInfo> _filterSearch(SearchContext context) {
    if (!context.hasFilters) return [];

    // 构建多条件查询
    final criteria = MultiCriteriaCriteria.fromSearchContext(context);
    return multiCriteriaSearch(criteria).funds;
  }

  /// 通用搜索 - 回退方案
  List<FundInfo> _generalSearch(SearchContext context) {
    final query = context.query.toLowerCase();
    final results = <FundInfo>[];

    for (final fund in _masterFundList) {
      if (results.length >= context.options.maxResults) break;

      if (_containsMatch(fund, query)) {
        results.add(fund);
      }
    }

    return results;
  }

  // ========== 私有方法 - 辅助功能 ==========

  /// 清空所有索引
  void _clearIndexes() {
    _codeHashTable.clear();
    _nameHashTable.clear();
    _codePrefixTree.clear();
    _namePrefixTree.clear();
    _pinyinPrefixTree.clear();
    _invertedIndex.clear();
    _masterFundList.clear();
    _isBuilt = false;
  }

  /// 中文分词（简单实现）
  List<String> _tokenizeChinese(String text) {
    // 简单分词：按字符和常见词汇分割
    final tokens = <String>[];
    final words = text.replaceAll(RegExp(r'[，。、\s]+'), ' ').split(' ');

    for (final word in words) {
      if (word.isNotEmpty) {
        tokens.add(word);
        // 添加单字作为后备
        for (int i = 0; i < word.length; i++) {
          tokens.add(word[i]);
        }
      }
    }

    return tokens.toSet().toList(); // 去重
  }

  /// 从基金名称提取公司名称
  String _extractCompany(String fundName) {
    // 简单实现：提取名称前几个字作为公司名
    final patterns = [
      RegExp(r'^(华夏|易方达|嘉实|南方|博时|广发|汇添富|富国|招商|工银瑞信)'),
      RegExp(r'^([^基投]+)'), // 提取"基"或"投"之前的内容
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(fundName);
      if (match != null) {
        return match.group(1)!;
      }
    }

    return '';
  }

  /// 推断风险等级
  String _inferRiskLevel(String fundType) {
    final type = fundType.toLowerCase();
    if (type.contains('货币') || type.contains('理财')) return 'R1';
    if (type.contains('债券')) return 'R2';
    if (type.contains('混合')) return 'R3';
    if (type.contains('股票') || type.contains('指数')) return 'R4';
    return 'R3'; // 默认中风险
  }

  /// 检查是否包含匹配
  bool _containsMatch(FundInfo fund, String query) {
    return fund.code.toLowerCase().contains(query) ||
        fund.name.toLowerCase().contains(query) ||
        fund.pinyinAbbr.toLowerCase().contains(query) ||
        fund.type.toLowerCase().contains(query);
  }

  /// 结果后处理
  List<FundInfo> _postProcessResults(
      List<FundInfo> results, SearchContext context) {
    if (results.isEmpty) return results;

    // 排序
    results = _applySorting(
        results, context.options.sortBy, context.options.sortOrder);

    // 限制结果数量
    if (context.options.maxResults > 0) {
      results = results.take(context.options.maxResults).toList();
    }

    return results;
  }

  /// 应用排序
  List<FundInfo> _applySorting(
      List<FundInfo> funds, String sortBy, String sortOrder) {
    final ascending = sortOrder.toLowerCase() == 'asc';

    switch (sortBy.toLowerCase()) {
      case 'code':
        funds.sort((a, b) =>
            ascending ? a.code.compareTo(b.code) : b.code.compareTo(a.code));
        break;
      case 'name':
        funds.sort((a, b) =>
            ascending ? a.name.compareTo(b.name) : b.name.compareTo(a.name));
        break;
      case 'type':
        funds.sort((a, b) =>
            ascending ? a.type.compareTo(b.type) : b.type.compareTo(a.type));
        break;
      default:
        // 默认按代码排序
        funds.sort((a, b) =>
            ascending ? a.code.compareTo(b.code) : b.code.compareTo(a.code));
    }

    return funds;
  }

  /// 获取使用的索引类型
  String _getIndexUsed(SearchContext context) {
    if (context.isExactMatch) return 'hash_table';
    if (context.isPrefixMatch) return 'prefix_tree';
    if (context.hasFilters) return 'inverted_index';
    return 'general_search';
  }

  /// 估算内存使用量
  double _estimateMemoryUsage() {
    // 粗略估算，实际值需要通过内存分析工具获取
    int totalSize = 0;

    // 基金数据大小
    totalSize += _masterFundList.length * 200; // 每个基金约200字节

    // 哈希表大小
    totalSize += (_codeHashTable.length + _nameHashTable.length) * 64;

    // 前缀树大小
    totalSize += (_codePrefixTree.nodeCount +
            _namePrefixTree.nodeCount +
            _pinyinPrefixTree.nodeCount) *
        32;

    // 倒排索引大小
    totalSize += _invertedIndex.entryCount * 16;

    return totalSize / (1024 * 1024); // 转换为MB
  }

  /// 记录索引统计信息
  void _logIndexStats() {
    _logger.i('📊 索引统计信息:');
    _logger.i('  总基金数量: ${_masterFundList.length}');
    _logger.i('  哈希表条目: ${_codeHashTable.length + _nameHashTable.length}');
    _logger.i(
        '  前缀树节点: ${_codePrefixTree.nodeCount + _namePrefixTree.nodeCount + _pinyinPrefixTree.nodeCount}');
    _logger.i('  倒排索引条目: ${_invertedIndex.entryCount}');
    _logger.i('  估算内存使用: ${_estimateMemoryUsage().toStringAsFixed(2)}MB');
  }
}

// ========== 辅助类定义 ==========

/// 搜索选项
class SearchOptions {
  final int maxResults;
  final int minResults;
  final String sortBy;
  final String sortOrder;
  final bool enableFuzzy;
  final bool enablePinyin;
  final Set<String>? fundTypes;
  final Set<String>? companies;
  final Set<String>? riskLevels;
  final int? offset;

  const SearchOptions({
    this.maxResults = 20,
    this.minResults = 5,
    this.sortBy = 'relevance',
    this.sortOrder = 'desc',
    this.enableFuzzy = true,
    this.enablePinyin = true,
    this.fundTypes,
    this.companies,
    this.riskLevels,
    this.offset,
  });
}

/// 搜索上下文
class SearchContext {
  final String query;
  final SearchOptions options;

  SearchContext({required this.query, required this.options});

  bool get isExactMatch => RegExp(r'^[0-9A-Za-z]{6}$').hasMatch(query);
  bool get isPrefixMatch => query.length >= 2 && query.length <= 5;
  bool get isFuzzyMatch => query.length >= 2;
  bool get hasFilters => options.maxResults > 0;
}

/// 搜索结果
class SearchResult {
  final String query;
  final List<FundInfo> funds;
  final int searchTimeMs;
  final int totalFound;
  final String indexUsed;
  final String? error;

  SearchResult({
    required this.query,
    required this.funds,
    required this.searchTimeMs,
    required this.totalFound,
    required this.indexUsed,
    this.error,
  });

  SearchResult.empty({String? error})
      : query = '',
        funds = [],
        searchTimeMs = 0,
        totalFound = 0,
        indexUsed = 'none',
        error = error;
}

/// 多条件搜索条件
class MultiCriteriaCriteria {
  final Set<String> fundTypes;
  final Set<String> companies;
  final Set<String> riskLevels;
  final String sortBy;
  final String sortOrder;
  final int? limit; // 改为可空类型，支持无限制
  final int offset;

  MultiCriteriaCriteria({
    required this.fundTypes,
    required this.companies,
    required this.riskLevels,
    required this.sortBy,
    required this.sortOrder,
    this.limit, // 默认null表示无限制
    required this.offset,
  });

  factory MultiCriteriaCriteria.fromSearchContext(SearchContext context) {
    return MultiCriteriaCriteria(
      fundTypes: context.options.fundTypes ?? const {},
      companies: context.options.companies ?? const {},
      riskLevels: context.options.riskLevels ?? const {},
      sortBy: context.options.sortBy,
      sortOrder: context.options.sortOrder,
      limit: context.options.maxResults,
      offset: context.options.offset ?? 0,
    );
  }

  @override
  String toString() {
    return 'MultiCriteriaCriteria(types: $fundTypes, companies: $companies, risks: $riskLevels)';
  }
}

/// 索引统计信息
class IndexStats {
  final int totalFunds;
  final int hashTableSize;
  final int prefixTreeNodes;
  final int invertedIndexEntries;
  final double memoryEstimateMB;
  final bool isBuilt;

  IndexStats({
    required this.totalFunds,
    required this.hashTableSize,
    required this.prefixTreeNodes,
    required this.invertedIndexEntries,
    required this.memoryEstimateMB,
    required this.isBuilt,
  });

  IndexStats.empty()
      : totalFunds = 0,
        hashTableSize = 0,
        prefixTreeNodes = 0,
        invertedIndexEntries = 0,
        memoryEstimateMB = 0.0,
        isBuilt = false;
}

/// 前缀树实现
class PrefixTree {
  final PrefixTreeNode _root = PrefixTreeNode();
  int nodeCount = 0;

  void insert(String word, String value) {
    var node = _root;
    for (final char in word.toLowerCase().split('')) {
      node = node.children.putIfAbsent(char, () => PrefixTreeNode());
    }
    if (!node.values.contains(value)) {
      node.values.add(value);
    }
    nodeCount = _countNodes(_root);
  }

  List<String> search(String prefix) {
    var node = _root;
    for (final char in prefix.toLowerCase().split('')) {
      node = node.children[char] ?? _root;
      if (node == _root && char.isNotEmpty) return [];
    }

    final results = <String>[];
    _collectAllValues(node, results);
    return results;
  }

  List<String> getSuggestions(String prefix, int maxSuggestions) {
    final matches = search(prefix);
    return matches.take(maxSuggestions).toList();
  }

  void clear() {
    _root.children.clear();
    nodeCount = 0;
  }

  void _collectAllValues(PrefixTreeNode node, List<String> results) {
    results.addAll(node.values);
    for (final child in node.children.values) {
      _collectAllValues(child, results);
    }
  }

  int _countNodes(PrefixTreeNode node) {
    int count = 1;
    for (final child in node.children.values) {
      count += _countNodes(child);
    }
    return count;
  }
}

/// 前缀树节点
class PrefixTreeNode {
  final Map<String, PrefixTreeNode> children = {};
  final List<String> values = [];
}

/// 倒排索引实现
class InvertedIndex {
  final Map<String, Map<String, Set<int>>> _index = {};
  int entryCount = 0;

  void addIndex(String category, String key, int fundIndex) {
    final categoryIndex = _index.putIfAbsent(category, () => {});
    final keyIndex = categoryIndex.putIfAbsent(key.toLowerCase(), () => {});
    keyIndex.add(fundIndex);
    entryCount++;
  }

  Set<int> multiCriteriaSearch(MultiCriteriaCriteria criteria) {
    Set<int> result = {};
    bool firstQuery = true;

    // 基金类型筛选
    if (criteria.fundTypes.isNotEmpty) {
      Set<int> typeResults = {};
      for (final type in criteria.fundTypes) {
        final results = _index['type']?[type.toLowerCase()] ?? <int>{};
        typeResults.addAll(results);
      }

      result = firstQuery ? typeResults : result.intersection(typeResults);
      if (firstQuery) firstQuery = false;
    }

    // 公司筛选
    if (criteria.companies.isNotEmpty) {
      Set<int> companyResults = {};
      for (final company in criteria.companies) {
        final results = _index['company']?[company.toLowerCase()] ?? <int>{};
        companyResults.addAll(results);
      }

      result =
          firstQuery ? companyResults : result.intersection(companyResults);
      if (firstQuery) firstQuery = false;
    }

    // 风险等级筛选
    if (criteria.riskLevels.isNotEmpty) {
      Set<int> riskResults = {};
      for (final risk in criteria.riskLevels) {
        final results = _index['risk']?[risk.toLowerCase()] ?? <int>{};
        riskResults.addAll(results);
      }

      result = firstQuery ? riskResults : result.intersection(riskResults);
      if (firstQuery) firstQuery = false;
    }

    // 如果没有任何筛选条件，返回所有基金索引
    if (firstQuery) {
      final allValues = _index['all']?.values ?? <Set<int>>[];
      result = {};
      for (final valueSet in allValues) {
        result.addAll(valueSet);
      }
    }

    return result;
  }

  /// 批量添加索引数据
  void addAll(Map<String, Map<String, Set<int>>> data) {
    for (final category in data.keys) {
      final categoryData = data[category] ?? {};
      final categoryIndex = _index.putIfAbsent(category, () => {});

      for (final key in categoryData.keys) {
        final keyIndex = categoryIndex.putIfAbsent(key.toLowerCase(), () => {});
        final values = categoryData[key] ?? <int>{};
        keyIndex.addAll(values);
      }
    }
    entryCount +=
        data.values.fold(0, (sum, categoryData) => sum + categoryData.length);
  }

  void clear() {
    _index.clear();
    entryCount = 0;
  }
}

// ========== 性能优化辅助方法 ==========

/// 批量处理基金数据，避免UI阻塞
Future<void> _processBatch<T>(
  List<T> items,
  Future<void> Function(T) processor, {
  int batchSize = 100,
}) async {
  for (int i = 0; i < items.length; i += batchSize) {
    final end = (i + batchSize).clamp(0, items.length);
    final batch = items.sublist(i, end);

    for (final item in batch) {
      await processor(item);
    }

    // 让出控制权，避免阻塞UI
    if (i % (batchSize * 10) == 0) {
      await Future.delayed(Duration.zero);
    }
  }
}
