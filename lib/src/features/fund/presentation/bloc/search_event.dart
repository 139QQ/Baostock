import '../../domain/entities/fund_search_criteria.dart';

/// 搜索事件基类
abstract class SearchEvent {
  SearchEvent();

  List<Object> get props => [];
}

/// 初始化搜索事件
class InitializeSearch extends SearchEvent {
  InitializeSearch();
}

/// 执行搜索事件
class PerformSearch extends SearchEvent {
  final FundSearchCriteria criteria;

  PerformSearch({required this.criteria});

  @override
  List<Object> get props => [criteria];
}

/// 更新搜索关键词事件
class UpdateSearchKeyword extends SearchEvent {
  final String keyword;

  UpdateSearchKeyword({required this.keyword});

  @override
  List<Object> get props => [keyword];
}

/// 更改搜索类型事件
class ChangeSearchType extends SearchEvent {
  final SearchType searchType;

  ChangeSearchType({required this.searchType});

  @override
  List<Object> get props => [searchType];
}

/// 切换搜索选项事件
class ToggleSearchOption extends SearchEvent {
  final SearchOption option;
  final bool value;

  ToggleSearchOption({
    required this.option,
    required this.value,
  });

  @override
  List<Object> get props => [option, value];
}

/// 清空搜索事件
class ClearSearch extends SearchEvent {
  ClearSearch();
}

/// 加载更多搜索结果事件
class LoadMoreSearchResults extends SearchEvent {
  LoadMoreSearchResults();
}

/// 重新搜索事件（刷新当前搜索）
class RefreshSearch extends SearchEvent {
  RefreshSearch();
}

/// 保存搜索历史事件
class SaveSearchHistory extends SearchEvent {
  final String keyword;

  SaveSearchHistory({required this.keyword});

  @override
  List<Object> get props => [keyword];
}

/// 加载搜索历史事件
class LoadSearchHistory extends SearchEvent {
  LoadSearchHistory();
}

/// 删除搜索历史事件
class DeleteSearchHistory extends SearchEvent {
  final String keyword;

  DeleteSearchHistory({required this.keyword});

  @override
  List<Object> get props => [keyword];
}

/// 清空搜索历史事件
class ClearSearchHistory extends SearchEvent {
  ClearSearchHistory();
}

/// 获取搜索建议事件
class GetSearchSuggestions extends SearchEvent {
  final String keyword;

  GetSearchSuggestions({required this.keyword});

  @override
  List<Object> get props => [keyword];
}

/// 选择搜索建议事件
class SelectSearchSuggestion extends SearchEvent {
  final String suggestion;

  SelectSearchSuggestion({required this.suggestion});

  @override
  List<Object> get props => [suggestion];
}

/// 更改搜索排序事件
class ChangeSearchSort extends SearchEvent {
  final SearchSortType sortBy;

  ChangeSearchSort({required this.sortBy});

  @override
  List<Object> get props => [sortBy];
}

/// 设置搜索字段限制事件
class SetSearchFields extends SearchEvent {
  final List<SearchField> searchFields;

  SetSearchFields({required this.searchFields});

  @override
  List<Object> get props => [searchFields];
}

/// 设置搜索限制事件
class SetSearchLimit extends SearchEvent {
  final int limit;

  SetSearchLimit({required this.limit});

  @override
  List<Object> get props => [limit];
}

/// 启用/禁用高级搜索事件
class ToggleAdvancedSearch extends SearchEvent {
  final bool enabled;

  ToggleAdvancedSearch({required this.enabled});

  @override
  List<Object> get props => [enabled];
}

/// 应用快速搜索事件
class QuickSearch extends SearchEvent {
  final String keyword;
  final SearchType searchType;

  QuickSearch({
    required this.keyword,
    this.searchType = SearchType.mixed,
  });

  @override
  List<Object> get props => [keyword, searchType];
}

/// 搜索性能统计事件
class GetSearchStatistics extends SearchEvent {
  GetSearchStatistics();
}

/// 清空搜索缓存事件
class ClearSearchCache extends SearchEvent {
  ClearSearchCache();
}

/// 预热搜索缓存事件
class WarmupSearchCache extends SearchEvent {
  WarmupSearchCache();
}

/// 搜索超时事件
class SearchTimeoutEvent extends SearchEvent {
  final FundSearchCriteria criteria;
  final int timeoutMs;

  SearchTimeoutEvent({
    required this.criteria,
    required this.timeoutMs,
  });

  @override
  List<Object> get props => [criteria, timeoutMs];
}

/// 搜索错误重试事件
class RetrySearch extends SearchEvent {
  final FundSearchCriteria criteria;
  final int attemptCount;

  RetrySearch({
    required this.criteria,
    required this.attemptCount,
  });

  @override
  List<Object> get props => [criteria, attemptCount];
}

/// 搜索选项枚举
enum SearchOption {
  caseSensitive('区分大小写'),
  fuzzySearch('模糊搜索'),
  enablePinyinSearch('拼音搜索'),
  includeInactive('包含停运基金');

  const SearchOption(this.displayName);

  final String displayName;

  @override
  String toString() => displayName;
}
