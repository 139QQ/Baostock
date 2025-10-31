import 'package:equatable/equatable.dart';

/// 基金搜索条件实体类
///
/// 用于存储和管理基金搜索的各种条件，支持多种搜索类型和组合搜索。
/// 设计遵循单一职责原则，专门处理搜索相关的逻辑和数据。
///
/// 时间复杂度: O(1) 对于条件设置和查询
/// 空间复杂度: O(n) 其中n是搜索条件数量
class FundSearchCriteria extends Equatable {
  /// 搜索关键词
  final String? keyword;

  /// 搜索类型
  final SearchType searchType;

  /// 是否区分大小写
  final bool caseSensitive;

  /// 是否启用模糊搜索
  final bool fuzzySearch;

  /// 模糊搜索的匹配度阈值（0.0-1.0）
  final double fuzzyThreshold;

  /// 是否启用拼音搜索
  final bool enablePinyinSearch;

  /// 搜索字段限制（为空表示搜索所有字段）
  final List<SearchField> searchFields;

  /// 搜索结果排序方式
  final SearchSortType sortBy;

  /// 搜索结果数量限制
  final int limit;

  /// 搜索结果偏移量
  final int offset;

  /// 是否包含已停运基金
  final bool includeInactive;

  /// 扩展筛选参数（用于与筛选功能整合）
  final Map<String, dynamic> extendedFilters;

  // 高级筛选字段
  /// 基金类型筛选
  final String fundType;

  /// 基金类型列表筛选（兼容性字段）
  final List<String>? fundTypes;

  /// 基金公司筛选
  final String fundCompany;

  /// 基金公司列表筛选（兼容性字段）
  final List<String>? companies;

  /// 收益率范围筛选
  final String returnRange;

  /// 净值范围筛选
  final String navRange;

  /// 最小净值
  final double? minNav;

  /// 最大净值
  final double? maxNav;

  /// 最小收益率
  final double? minReturn;

  /// 最大收益率
  final double? maxReturn;

  /// 最短成立年限
  final int? minYears;

  /// 创建基金搜索条件
  ///
  /// [keyword] 搜索关键词，为空时返回所有基金
  /// [searchType] 搜索类型，默认为混合搜索
  /// [caseSensitive] 是否区分大小写，默认为false
  /// [fuzzySearch] 是否启用模糊搜索，默认为true
  /// [fuzzyThreshold] 模糊搜索匹配度阈值，默认0.6
  /// [enablePinyinSearch] 是否启用拼音搜索，默认为true
  /// [searchFields] 搜索字段限制，为空表示搜索所有字段
  /// [sortBy] 搜索结果排序方式，默认按相关性排序
  /// [limit] 搜索结果数量限制，默认20条
  /// [offset] 搜索结果偏移量，默认0
  /// [includeInactive] 是否包含已停运基金，默认false
  /// [extendedFilters] 扩展筛选参数，默认为空Map
  /// [fundType] 基金类型筛选，默认为空
  /// [fundTypes] 基金类型列表筛选，默认为null
  /// [fundCompany] 基金公司筛选，默认为空
  /// [companies] 基金公司列表筛选，默认为null
  /// [returnRange] 收益率范围筛选，默认为空
  /// [navRange] 净值范围筛选，默认为空
  /// [minNav] 最小净值，默认为null
  /// [maxNav] 最大净值，默认为null
  /// [minReturn] 最小收益率，默认为null
  /// [maxReturn] 最大收益率，默认为null
  /// [minYears] 最短成立年限，默认为null
  const FundSearchCriteria({
    this.keyword,
    this.searchType = SearchType.mixed,
    this.caseSensitive = false,
    this.fuzzySearch = true,
    this.fuzzyThreshold = 0.6,
    this.enablePinyinSearch = true,
    this.searchFields = const [],
    this.sortBy = SearchSortType.relevance,
    this.limit = 20,
    this.offset = 0,
    this.includeInactive = false,
    this.extendedFilters = const {},
    this.fundType = '',
    this.fundTypes,
    this.fundCompany = '',
    this.companies,
    this.returnRange = '',
    this.navRange = '',
    this.minNav,
    this.maxNav,
    this.minReturn,
    this.maxReturn,
    this.minYears,
  })  : assert(
          fuzzyThreshold >= 0.0 && fuzzyThreshold <= 1.0,
          '模糊搜索阈值必须在0.0-1.0之间',
        ),
        assert(limit > 0, '搜索结果限制必须大于0'),
        assert(offset >= 0, '搜索结果偏移量不能为负数');

  /// 创建空的搜索条件（返回所有基金）
  factory FundSearchCriteria.empty() {
    return const FundSearchCriteria();
  }

  /// 创建关键词搜索条件
  factory FundSearchCriteria.keyword(
    String keyword, {
    SearchType searchType = SearchType.mixed,
    bool caseSensitive = false,
    bool fuzzySearch = true,
    List<SearchField> searchFields = const [],
  }) {
    return FundSearchCriteria(
      keyword: keyword,
      searchType: searchType,
      caseSensitive: caseSensitive,
      fuzzySearch: fuzzySearch,
      searchFields: searchFields,
    );
  }

  /// 复制当前搜索条件并更新指定字段
  FundSearchCriteria copyWith({
    String? keyword,
    SearchType? searchType,
    bool? caseSensitive,
    bool? fuzzySearch,
    double? fuzzyThreshold,
    bool? enablePinyinSearch,
    List<SearchField>? searchFields,
    SearchSortType? sortBy,
    int? limit,
    int? offset,
    bool? includeInactive,
    Map<String, dynamic>? extendedFilters,
    String? fundType,
    List<String>? fundTypes,
    String? fundCompany,
    List<String>? companies,
    String? returnRange,
    String? navRange,
    double? minNav,
    double? maxNav,
    double? minReturn,
    double? maxReturn,
    int? minYears,
    bool clearKeyword = false,
    bool clearSearchFields = false,
    bool clearExtendedFilters = false,
  }) {
    return FundSearchCriteria(
      keyword: clearKeyword ? null : (keyword ?? this.keyword),
      searchType: searchType ?? this.searchType,
      caseSensitive: caseSensitive ?? this.caseSensitive,
      fuzzySearch: fuzzySearch ?? this.fuzzySearch,
      fuzzyThreshold: fuzzyThreshold ?? this.fuzzyThreshold,
      enablePinyinSearch: enablePinyinSearch ?? this.enablePinyinSearch,
      searchFields:
          clearSearchFields ? [] : (searchFields ?? this.searchFields),
      sortBy: sortBy ?? this.sortBy,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
      includeInactive: includeInactive ?? this.includeInactive,
      extendedFilters:
          clearExtendedFilters ? {} : (extendedFilters ?? this.extendedFilters),
      fundType: fundType ?? this.fundType,
      fundTypes: fundTypes ?? this.fundTypes,
      fundCompany: fundCompany ?? this.fundCompany,
      companies: companies ?? this.companies,
      returnRange: returnRange ?? this.returnRange,
      navRange: navRange ?? this.navRange,
      minNav: minNav ?? this.minNav,
      maxNav: maxNav ?? this.maxNav,
      minReturn: minReturn ?? this.minReturn,
      maxReturn: maxReturn ?? this.maxReturn,
      minYears: minYears ?? this.minYears,
    );
  }

  /// 检查是否为空搜索条件
  bool get isEmpty => keyword == null || keyword!.trim().isEmpty;

  /// 检查是否为有效搜索条件
  bool get isValid => !isEmpty;

  /// 检查是否启用了高级搜索功能
  bool get hasAdvancedSearch =>
      fuzzySearch ||
      enablePinyinSearch ||
      searchFields.isNotEmpty ||
      sortBy != SearchSortType.relevance ||
      extendedFilters.isNotEmpty;

  /// 生成搜索条件的哈希值（用于缓存）
  String get cacheKey {
    final parts = [
      keyword?.toLowerCase() ?? '',
      searchType.name,
      caseSensitive.toString(),
      fuzzySearch.toString(),
      fuzzyThreshold.toString(),
      enablePinyinSearch.toString(),
      searchFields.map((f) => f.name).join(','),
      sortBy.name,
      limit.toString(),
      offset.toString(),
      includeInactive.toString(),
      extendedFilters.toString(),
    ];
    return parts.join('|');
  }

  /// 序列化为JSON格式
  Map<String, dynamic> toJson() {
    return {
      'keyword': keyword,
      'searchType': searchType.name,
      'caseSensitive': caseSensitive,
      'fuzzySearch': fuzzySearch,
      'fuzzyThreshold': fuzzyThreshold,
      'enablePinyinSearch': enablePinyinSearch,
      'searchFields': searchFields.map((f) => f.name).toList(),
      'sortBy': sortBy.name,
      'limit': limit,
      'offset': offset,
      'includeInactive': includeInactive,
      'extendedFilters': extendedFilters,
    };
  }

  /// 从JSON格式创建搜索条件
  factory FundSearchCriteria.fromJson(Map<String, dynamic> json) {
    return FundSearchCriteria(
      keyword: json['keyword'] as String?,
      searchType: SearchType.values.firstWhere(
        (e) => e.name == json['searchType'],
        orElse: () => SearchType.mixed,
      ),
      caseSensitive: json['caseSensitive'] as bool? ?? false,
      fuzzySearch: json['fuzzySearch'] as bool? ?? true,
      fuzzyThreshold: (json['fuzzyThreshold'] as num?)?.toDouble() ?? 0.6,
      enablePinyinSearch: json['enablePinyinSearch'] as bool? ?? true,
      searchFields: (json['searchFields'] as List<dynamic>?)
              ?.map((f) => SearchField.values.firstWhere(
                    (e) => e.name == f,
                    orElse: () => SearchField.all,
                  ))
              .toList() ??
          [],
      sortBy: SearchSortType.values.firstWhere(
        (e) => e.name == json['sortBy'],
        orElse: () => SearchSortType.relevance,
      ),
      limit: json['limit'] as int? ?? 20,
      offset: json['offset'] as int? ?? 0,
      includeInactive: json['includeInactive'] as bool? ?? false,
      extendedFilters: json['extendedFilters'] as Map<String, dynamic>? ?? {},
    );
  }

  @override
  List<Object?> get props => [
        keyword,
        searchType,
        caseSensitive,
        fuzzySearch,
        fuzzyThreshold,
        enablePinyinSearch,
        searchFields,
        sortBy,
        limit,
        offset,
        includeInactive,
        extendedFilters,
      ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FundSearchCriteria &&
          runtimeType == other.runtimeType &&
          keyword == other.keyword &&
          searchType == other.searchType &&
          caseSensitive == other.caseSensitive &&
          fuzzySearch == other.fuzzySearch &&
          fuzzyThreshold == other.fuzzyThreshold &&
          enablePinyinSearch == other.enablePinyinSearch &&
          _listEquals(searchFields, other.searchFields) &&
          sortBy == other.sortBy &&
          limit == other.limit &&
          offset == other.offset &&
          includeInactive == other.includeInactive &&
          _mapEquals(extendedFilters, other.extendedFilters);

  @override
  int get hashCode => Object.hashAll([
        keyword,
        searchType,
        caseSensitive,
        fuzzySearch,
        fuzzyThreshold,
        enablePinyinSearch,
        _listHash(searchFields),
        sortBy,
        limit,
        offset,
        includeInactive,
        _mapHash(extendedFilters),
      ]);

  /// 辅助方法：比较两个列表是否相等
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// 辅助方法：计算列表的哈希值
  int _listHash<T>(List<T> list) {
    int hash = 0;
    for (final item in list) {
      hash = hash * 31 + item.hashCode;
    }
    return hash;
  }

  /// 辅助方法：比较两个Map是否相等
  bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }

  /// 辅助方法：计算Map的哈希值
  int _mapHash<K, V>(Map<K, V> map) {
    int hash = 0;
    for (final entry in map.entries) {
      hash = hash * 31 + entry.key.hashCode;
      hash = hash * 31 + entry.value.hashCode;
    }
    return hash;
  }

  @override
  String toString() {
    if (isEmpty) return '无搜索条件';

    final parts = <String>[];
    parts.add('关键词: "$keyword"');
    parts.add('类型: ${searchType.displayName}');

    if (caseSensitive) parts.add('区分大小写');
    if (fuzzySearch) parts.add('模糊搜索(${(fuzzyThreshold * 100).toInt()}%)');
    if (enablePinyinSearch) parts.add('拼音搜索');

    if (searchFields.isNotEmpty) {
      parts.add('字段: ${searchFields.map((f) => f.displayName).join(', ')}');
    }

    parts.add('排序: ${sortBy.displayName}');
    parts.add('限制: $limit条');

    if (offset > 0) parts.add('偏移: $offset');
    if (includeInactive) parts.add('包含停运基金');

    return parts.join(' | ');
  }
}

/// 搜索类型枚举
enum SearchType {
  /// 精确匹配
  exact('精确匹配'),

  /// 基金代码搜索
  code('基金代码'),

  /// 基金名称搜索
  name('基金名称'),

  /// 混合搜索（代码+名称）
  mixed('混合搜索'),

  /// 全文搜索
  fullText('全文搜索');

  const SearchType(this.displayName);

  final String displayName;

  @override
  String toString() => displayName;
}

/// 搜索字段枚举
enum SearchField {
  /// 所有字段
  all('全部'),

  /// 基金代码
  code('基金代码'),

  /// 基金名称
  name('基金名称'),

  /// 基金类型
  type('基金类型'),

  /// 管理公司
  company('管理公司'),

  /// 基金经理
  manager('基金经理'),

  /// 投资策略
  strategy('投资策略');

  const SearchField(this.displayName);

  final String displayName;

  @override
  String toString() => displayName;
}

/// 搜索结果排序类型枚举
enum SearchSortType {
  /// 按相关性排序
  relevance('相关性'),

  /// 按基金代码排序
  code('基金代码'),

  /// 按基金名称排序
  name('基金名称'),

  /// 按收益率排序
  returnRate('收益率'),

  /// 按基金规模排序
  scale('基金规模'),

  /// 按成立时间排序
  establishmentDate('成立时间');

  const SearchSortType(this.displayName);

  final String displayName;

  @override
  String toString() => displayName;
}

/// 搜索结果实体类
class SearchResult extends Equatable {
  /// 匹配的基金列表
  final List<FundSearchMatch> funds;

  /// 总结果数量
  final int totalCount;

  /// 搜索耗时（毫秒）
  final int searchTimeMs;

  /// 搜索条件
  final FundSearchCriteria criteria;

  /// 是否有更多结果
  final bool hasMore;

  /// 搜索建议
  final List<String> suggestions;

  const SearchResult({
    required this.funds,
    required this.totalCount,
    required this.searchTimeMs,
    required this.criteria,
    required this.hasMore,
    this.suggestions = const [],
  });

  /// 创建空搜索结果
  factory SearchResult.empty({
    required FundSearchCriteria criteria,
    String message = '无搜索结果',
  }) {
    return SearchResult(
      funds: const [],
      totalCount: 0,
      searchTimeMs: 0,
      criteria: criteria,
      hasMore: false,
      suggestions: const [],
    );
  }

  /// 是否为空结果
  bool get isEmpty => funds.isEmpty;

  /// 是否有结果
  bool get isNotEmpty => funds.isNotEmpty;

  @override
  List<Object?> get props => [
        funds,
        totalCount,
        searchTimeMs,
        criteria,
        hasMore,
        suggestions,
      ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchResult &&
          runtimeType == other.runtimeType &&
          _listEquals(funds, other.funds) &&
          totalCount == other.totalCount &&
          searchTimeMs == other.searchTimeMs &&
          criteria == other.criteria &&
          hasMore == other.hasMore &&
          _listEquals(suggestions, other.suggestions);

  @override
  int get hashCode => Object.hashAll([
        _listHash(funds),
        totalCount,
        searchTimeMs,
        criteria,
        hasMore,
        _listHash(suggestions),
      ]);

  /// 辅助方法：比较两个列表是否相等
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// 辅助方法：计算列表的哈希值
  int _listHash<T>(List<T> list) {
    int hash = 0;
    for (final item in list) {
      hash = hash * 31 + item.hashCode;
    }
    return hash;
  }

  @override
  String toString() {
    return 'SearchResult(totalCount: $totalCount, searchTime: ${searchTimeMs}ms, funds: ${funds.length})';
  }
}

/// 基金搜索匹配结果
class FundSearchMatch extends Equatable {
  /// 基金代码
  final String fundCode;

  /// 基金名称
  final String fundName;

  /// 匹配度分数（0.0-1.0）
  final double score;

  /// 匹配的字段
  final List<SearchField> matchedFields;

  /// 高亮信息
  final Map<String, List<String>> highlights;

  const FundSearchMatch({
    required this.fundCode,
    required this.fundName,
    required this.score,
    required this.matchedFields,
    required this.highlights,
  });

  @override
  List<Object?> get props => [
        fundCode,
        fundName,
        score,
        matchedFields,
        highlights,
      ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FundSearchMatch &&
          runtimeType == other.runtimeType &&
          fundCode == other.fundCode &&
          fundName == other.fundName &&
          score == other.score &&
          _listEquals(matchedFields, other.matchedFields) &&
          _mapEquals(highlights, other.highlights);

  @override
  int get hashCode => Object.hashAll([
        fundCode,
        fundName,
        score,
        _listHash(matchedFields),
        _mapHash(highlights),
      ]);

  /// 辅助方法：比较两个列表是否相等
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// 辅助方法：比较两个Map是否相等
  bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }

  /// 辅助方法：计算列表的哈希值
  int _listHash<T>(List<T> list) {
    int hash = 0;
    for (final item in list) {
      hash = hash * 31 + item.hashCode;
    }
    return hash;
  }

  /// 辅助方法：计算Map的哈希值
  int _mapHash<K, V>(Map<K, V> map) {
    int hash = 0;
    for (final entry in map.entries) {
      hash = hash * 31 + entry.key.hashCode;
      hash = hash * 31 + entry.value.hashCode;
    }
    return hash;
  }

  @override
  String toString() {
    return 'FundSearchMatch(code: $fundCode, name: $fundName, score: ${(score * 100).toInt()}%)';
  }
}
