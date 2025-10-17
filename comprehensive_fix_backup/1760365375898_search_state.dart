import '../../domain/entities/fund_search_criteria.dart';

/// 搜索状态基类
abstract class SearchState {
  const SearchState();

  @override
  List<Object> get props => [];
}

/// 搜索初始状态
class SearchInitial extends SearchState {
  const SearchInitial();
}

/// 搜索加载中状态
class SearchLoadInProgress extends SearchState {
  final FundSearchCriteria? criteria;

  const SearchLoadInProgress({this.criteria});

  @override
  List<Object> get props => [criteria ?? ''];
}

/// 搜索加载成功状态
class SearchLoadSuccess extends SearchState {
  final SearchResult searchResult;
  final List<String> searchHistory;
  final List<String> suggestions;
  final Map<String, dynamic> statistics;

  const SearchLoadSuccess({
    required this.searchResult,
    required this.searchHistory,
    required this.suggestions,
    required this.statistics,
  });

  @override
  List<Object> get props => [
        searchResult,
        searchHistory,
        suggestions,
        statistics,
      ];

  /// 是否有搜索结果
  bool get hasResults => searchResult.funds.isNotEmpty;

  /// 是否为空搜索
  bool get isEmptySearch => searchResult.criteria.isEmpty;

  /// 是否有更多结果
  bool get hasMoreResults => searchResult.hasMore;

  /// 获取结果总数
  int get totalCount => searchResult.totalCount;

  /// 获取当前结果数量
  int get currentResultCount => searchResult.funds.length;

  /// 获取搜索耗时
  int get searchTimeMs => searchResult.searchTimeMs;

  /// 复制状态并更新搜索结果
  SearchLoadSuccess copyWithSearchResult(SearchResult newSearchResult) {
    return SearchLoadSuccess(
      searchResult: newSearchResult,
      searchHistory: searchHistory,
      suggestions: suggestions,
      statistics: statistics,
    );
  }

  /// 复制状态并更新搜索历史
  SearchLoadSuccess copyWithSearchHistory(List<String> newSearchHistory) {
    return SearchLoadSuccess(
      searchResult: searchResult,
      searchHistory: newSearchHistory,
      suggestions: suggestions,
      statistics: statistics,
    );
  }

  /// 复制状态并更新建议
  SearchLoadSuccess copyWithSuggestions(List<String> newSuggestions) {
    return SearchLoadSuccess(
      searchResult: searchResult,
      searchHistory: searchHistory,
      suggestions: newSuggestions,
      statistics: statistics,
    );
  }

  /// 复制状态并更新统计信息
  SearchLoadSuccess copyWithStatistics(Map<String, dynamic> newStatistics) {
    return SearchLoadSuccess(
      searchResult: searchResult,
      searchHistory: searchHistory,
      suggestions: suggestions,
      statistics: newStatistics,
    );
  }

  /// 获取搜索性能摘要
  String get performanceSummary {
    final avgTime = statistics['averageSearchTime'] ?? 0;
    final cacheSize = statistics['cacheSize'] ?? 0;

    return '平均搜索时间: ${avgTime}ms, 缓存: ${cacheSize}条';
  }
}

/// 搜索加载失败状态
class SearchLoadFailure extends SearchState {
  final String errorMessage;
  final FundSearchCriteria? criteria;
  final SearchErrorType errorType;

  const SearchLoadFailure({
    required this.errorMessage,
    this.criteria,
    this.errorType = SearchErrorType.unknown,
  });

  @override
  List<Object> get props => [errorMessage, criteria ?? '', errorType];

  /// 是否为网络错误
  bool get isNetworkError => errorType == SearchErrorType.network;

  /// 是否为超时错误
  bool get isTimeoutError => errorType == SearchErrorType.timeout;

  /// 是否为数据错误
  bool get isDataError => errorType == SearchErrorType.data;

  /// 是否可以重试
  bool get canRetry => isNetworkError || isTimeoutError;
}

/// 搜索历史加载状态
class SearchHistoryLoadInProgress extends SearchState {
  const SearchHistoryLoadInProgress();
}

/// 搜索历史加载成功状态
class SearchHistoryLoadSuccess extends SearchState {
  final List<String> history;

  const SearchHistoryLoadSuccess({required this.history});

  @override
  List<Object> get props => [history];

  /// 是否为空历史
  bool get isEmpty => history.isEmpty;

  /// 获取历史记录数量
  int get historyCount => history.length;
}

/// 搜索建议加载状态
class SearchSuggestionsLoadInProgress extends SearchState {
  final String keyword;

  const SearchSuggestionsLoadInProgress({required this.keyword});

  @override
  List<Object> get props => [keyword];
}

/// 搜索建议加载成功状态
class SearchSuggestionsLoadSuccess extends SearchState {
  final String keyword;
  final List<String> suggestions;

  const SearchSuggestionsLoadSuccess({
    required this.keyword,
    required this.suggestions,
  });

  @override
  List<Object> get props => [keyword, suggestions];

  /// 是否为空建议
  bool get isEmpty => suggestions.isEmpty;

  /// 获取建议数量
  int get suggestionCount => suggestions.length;
}

/// 搜索统计信息状态
class SearchStatisticsLoaded extends SearchState {
  final Map<String, dynamic> statistics;

  const SearchStatisticsLoaded({required this.statistics});

  @override
  List<Object> get props => [statistics];

  /// 获取平均搜索时间
  int get averageSearchTime => statistics['averageSearchTime'] ?? 0;

  /// 获取最大搜索时间
  int get maxSearchTime => statistics['maxSearchTime'] ?? 0;

  /// 获取最小搜索时间
  int get minSearchTime => statistics['minSearchTime'] ?? 0;

  /// 获取总搜索次数
  int get totalSearches => statistics['totalSearches'] ?? 0;

  /// 获取缓存大小
  int get cacheSize => statistics['cacheSize'] ?? 0;
}

/// 搜索缓存清理状态
class SearchCacheCleared extends SearchState {
  const SearchCacheCleared();
}

/// 搜索缓存预热状态
class SearchCacheWarmedUp extends SearchState {
  final bool success;
  final String? message;

  const SearchCacheWarmedUp({
    required this.success,
    this.message,
  });

  @override
  List<Object> get props => [success, message ?? ''];
}

/// 搜索选项更新状态
class SearchOptionsUpdated extends SearchState {
  final FundSearchCriteria updatedCriteria;

  const SearchOptionsUpdated({required this.updatedCriteria});

  @override
  List<Object> get props => [updatedCriteria];

  /// 检查是否启用了高级搜索
  bool get hasAdvancedSearch => updatedCriteria.hasAdvancedSearch;

  /// 获取搜索选项摘要
  String get optionsSummary {
    final options = <String>[];

    if (updatedCriteria.caseSensitive) options.add('区分大小写');
    if (updatedCriteria.fuzzySearch) options.add('模糊搜索');
    if (updatedCriteria.enablePinyinSearch) options.add('拼音搜索');
    if (updatedCriteria.includeInactive) options.add('包含停运基金');

    return options.isEmpty ? '基础搜索' : options.join(', ');
  }
}

/// 搜索字段限制更新状态
class SearchFieldsUpdated extends SearchState {
  final List<SearchField> searchFields;

  const SearchFieldsUpdated({required this.searchFields});

  @override
  List<Object> get props => [searchFields];

  /// 是否搜索所有字段
  bool get isAllFields =>
      searchFields.isEmpty || searchFields.contains(SearchField.all);

  /// 获取搜索字段描述
  String get fieldsDescription {
    if (isAllFields) return '全部字段';
    return searchFields.map((f) => f.displayName).join(', ');
  }
}

/// 搜索排序更新状态
class SearchSortUpdated extends SearchState {
  final SearchSortType sortBy;

  const SearchSortUpdated({required this.sortBy});

  @override
  List<Object> get props => [sortBy];
}

/// 搜索历史删除状态
class SearchHistoryDeleted extends SearchState {
  final String deletedKeyword;

  const SearchHistoryDeleted({required this.deletedKeyword});

  @override
  List<Object> get props => [deletedKeyword];
}

/// 搜索历史清空状态
class SearchHistoryCleared extends SearchState {
  const SearchHistoryCleared();
}

/// 搜索超时状态
class SearchTimeout extends SearchState {
  final FundSearchCriteria criteria;
  final int timeoutMs;

  const SearchTimeout({
    required this.criteria,
    required this.timeoutMs,
  });

  @override
  List<Object> get props => [criteria, timeoutMs];

  /// 获取超时消息
  String get timeoutMessage => '搜索超时（${timeoutMs}ms），请重试';
}

/// 搜索重试状态
class SearchRetry extends SearchState {
  final FundSearchCriteria criteria;
  final int attemptCount;

  const SearchRetry({
    required this.criteria,
    required this.attemptCount,
  });

  @override
  List<Object> get props => [criteria, attemptCount];

  /// 获取重试消息
  String get retryMessage => '正在重试搜索（第${attemptCount}次）...';
}

/// 搜索性能警告状态
class SearchPerformanceWarning extends SearchState {
  final int searchTimeMs;
  final String warning;

  const SearchPerformanceWarning({
    required this.searchTimeMs,
    required this.warning,
  });

  @override
  List<Object> get props => [searchTimeMs, warning];
}

/// 搜索错误类型枚举
enum SearchErrorType {
  /// 未知错误
  unknown('未知错误'),

  /// 网络错误
  network('网络连接错误'),

  /// 超时错误
  timeout('搜索超时'),

  /// 数据错误
  data('数据错误'),

  /// 参数错误
  parameters('搜索参数错误'),

  /// 权限错误
  permission('权限不足'),

  /// 服务器错误
  server('服务器错误');

  const SearchErrorType(this.displayName);

  final String displayName;

  @override
  String toString() => displayName;
}

/// 搜索状态扩展方法
extension SearchStateExtension on SearchState {
  /// 是否为加载状态
  bool get isLoading =>
      this is SearchLoadInProgress ||
      this is SearchHistoryLoadInProgress ||
      this is SearchSuggestionsLoadInProgress;

  /// 是否为成功状态
  bool get isSuccess =>
      this is SearchLoadSuccess ||
      this is SearchHistoryLoadSuccess ||
      this is SearchSuggestionsLoadSuccess ||
      this is SearchStatisticsLoaded;

  /// 是否为错误状态
  bool get isError =>
      this is SearchLoadFailure ||
      this is SearchTimeout ||
      this is SearchPerformanceWarning;

  /// 是否为搜索相关状态
  bool get isSearchRelated =>
      this is SearchLoadInProgress ||
      this is SearchLoadSuccess ||
      this is SearchLoadFailure ||
      this is SearchTimeout ||
      this is SearchRetry;

  /// 获取错误消息（如果是错误状态）
  String? get errorMessage {
    if (this is SearchLoadFailure) {
      return (this as SearchLoadFailure).errorMessage;
    } else if (this is SearchTimeout) {
      return (this as SearchTimeout).timeoutMessage;
    } else if (this is SearchPerformanceWarning) {
      return (this as SearchPerformanceWarning).warning;
    }
    return null;
  }

  /// 获取搜索结果（如果是成功状态）
  SearchResult? get searchResult {
    if (this is SearchLoadSuccess) {
      return (this as SearchLoadSuccess).searchResult;
    }
    return null;
  }

  /// 获取搜索历史（如果是成功状态）
  List<String>? get searchHistory {
    if (this is SearchLoadSuccess) {
      return (this as SearchLoadSuccess).searchHistory;
    } else if (this is SearchHistoryLoadSuccess) {
      return (this as SearchHistoryLoadSuccess).history;
    }
    return null;
  }

  /// 获取搜索建议（如果是成功状态）
  List<String>? get suggestions {
    if (this is SearchLoadSuccess) {
      return (this as SearchLoadSuccess).suggestions;
    } else if (this is SearchSuggestionsLoadSuccess) {
      return (this as SearchSuggestionsLoadSuccess).suggestions;
    }
    return null;
  }
}
