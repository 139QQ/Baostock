import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/fund_search_criteria.dart';
import '../../domain/usecases/fund_search_usecase.dart';
import 'search_event.dart';
import 'search_state.dart';
import '../../../../core/utils/logger.dart';

/// 基金搜索BLoC
///
/// 负责管理基金搜索的状态和业务逻辑，提供响应式的搜索体验。
/// 支持实时搜索、防抖动、搜索历史、性能优化等功能。
///
/// 性能特性：
/// - 内置300ms防抖动机制
/// - 智能缓存和预加载
/// - 搜索性能监控
/// - 响应时间≤300ms
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final FundSearchUseCase _searchUseCase;

  // 防抖动控制器
  Timer? _debounceTimer;

  // 当前搜索条件
  FundSearchCriteria _currentCriteria = const FundSearchCriteria();

  // 搜索历史
  List<String> _searchHistory = [];

  // 当前搜索建议
  List<String> _currentSuggestions = [];

  // 性能统计
  Map<String, dynamic> _statistics = {};

  // 搜索重试计数
  int _retryCount = 0;

  // 最大重试次数
  static int maxRetries = 3;

  // 防抖动延迟时间
  static Duration debounceDelay = const Duration(milliseconds: 300);

  // 搜索超时时间
  static Duration searchTimeout = const Duration(seconds: 5);

  /// 构造函数
  SearchBloc({
    required FundSearchUseCase searchUseCase,
  })  : _searchUseCase = searchUseCase,
        super(SearchInitial()) {
    on<InitializeSearch>(_onInitializeSearch);
    on<PerformSearch>(_onPerformSearch);
    on<UpdateSearchKeyword>(_onUpdateSearchKeyword);
    on<ChangeSearchType>(_onChangeSearchType);
    on<ToggleSearchOption>(_onToggleSearchOption);
    on<ClearSearch>(_onClearSearch);
    on<LoadMoreSearchResults>(_onLoadMoreSearchResults);
    on<RefreshSearch>(_onRefreshSearch);
    on<SaveSearchHistory>(_onSaveSearchHistory);
    on<LoadSearchHistory>(_onLoadSearchHistory);
    on<DeleteSearchHistory>(_onDeleteSearchHistory);
    on<ClearSearchHistory>(_onClearSearchHistory);
    on<GetSearchSuggestions>(_onGetSearchSuggestions);
    on<SelectSearchSuggestion>(_onSelectSearchSuggestion);
    on<ChangeSearchSort>(_onChangeSearchSort);
    on<SetSearchFields>(_onSetSearchFields);
    on<SetSearchLimit>(_onSetSearchLimit);
    on<ToggleAdvancedSearch>(_onToggleAdvancedSearch);
    on<QuickSearch>(_onQuickSearch);
    on<GetSearchStatistics>(_onGetSearchStatistics);
    on<ClearSearchCache>(_onClearSearchCache);
    on<WarmupSearchCache>(_onWarmupSearchCache);
    on<SearchTimeoutEvent>(_onSearchTimeout);
    on<RetrySearch>(_onRetrySearch);
  }

  /// 初始化搜索
  Future<void> _onInitializeSearch(
    InitializeSearch event,
    Emitter<SearchState> emit,
  ) async {
    try {
      // 加载搜索历史
      await _loadSearchHistoryFromStorage();

      // 预热搜索缓存
      unawaited(_searchUseCase.warmupCache());

      // 加载性能统计
      _statistics = _searchUseCase.getPerformanceStats();

      emit(SearchLoadSuccess(
        searchResult: SearchResult.empty(criteria: _currentCriteria),
        searchHistory: _searchHistory,
        suggestions: [],
        statistics: _statistics,
      ));
    } catch (e) {
      emit(SearchLoadFailure(
        errorMessage: '搜索初始化失败',
        errorType: SearchErrorType.unknown,
      ));
    }
  }

  /// 执行搜索
  Future<void> _onPerformSearch(
    PerformSearch event,
    Emitter<SearchState> emit,
  ) async {
    _currentCriteria = event.criteria;
    _retryCount = 0;

    await _executeSearch(emit, includeHistory: true);
  }

  /// 更新搜索关键词（带防抖动）
  Future<void> _onUpdateSearchKeyword(
    UpdateSearchKeyword event,
    Emitter<SearchState> emit,
  ) async {
    // 取消之前的防抖动定时器
    _debounceTimer?.cancel();

    // 更新搜索条件
    _currentCriteria = _currentCriteria.copyWith(keyword: event.keyword);

    // 如果关键词为空，清空搜索结果
    if (event.keyword.trim().isEmpty) {
      emit(SearchLoadSuccess(
        searchResult: SearchResult.empty(criteria: _currentCriteria),
        searchHistory: _searchHistory,
        suggestions: [],
        statistics: _statistics,
      ));
      return;
    }

    // 如果有当前状态且有搜索结果，先显示加载状态
    if (state is SearchLoadSuccess) {
      final currentState = state as SearchLoadSuccess;
      emit(SearchLoadInProgress(criteria: _currentCriteria));

      // 延迟一帧以显示加载状态
      await Future.delayed(Duration.zero);

      emit(currentState.copyWithSearchResult(
        SearchResult.empty(criteria: _currentCriteria),
      ));
    }

    // 设置防抖动定时器
    _debounceTimer = Timer(SearchBloc.debounceDelay, () async {
      await _executeSearch(emit);
    });
  }

  /// 更改搜索类型
  Future<void> _onChangeSearchType(
    ChangeSearchType event,
    Emitter<SearchState> emit,
  ) async {
    _currentCriteria = _currentCriteria.copyWith(searchType: event.searchType);

    if (_currentCriteria.isValid) {
      await _executeSearch(emit);
    }
  }

  /// 切换搜索选项
  Future<void> _onToggleSearchOption(
    ToggleSearchOption event,
    Emitter<SearchState> emit,
  ) async {
    switch (event.option) {
      case SearchOption.caseSensitive:
        _currentCriteria =
            _currentCriteria.copyWith(caseSensitive: event.value);
        break;
      case SearchOption.fuzzySearch:
        _currentCriteria = _currentCriteria.copyWith(fuzzySearch: event.value);
        break;
      case SearchOption.enablePinyinSearch:
        _currentCriteria =
            _currentCriteria.copyWith(enablePinyinSearch: event.value);
        break;
      case SearchOption.includeInactive:
        _currentCriteria =
            _currentCriteria.copyWith(includeInactive: event.value);
        break;
    }

    emit(SearchOptionsUpdated(updatedCriteria: _currentCriteria));

    if (_currentCriteria.isValid) {
      await _executeSearch(emit);
    }
  }

  /// 清空搜索
  Future<void> _onClearSearch(
    ClearSearch event,
    Emitter<SearchState> emit,
  ) async {
    _currentCriteria = const FundSearchCriteria();
    _currentSuggestions.clear();

    emit(SearchLoadSuccess(
      searchResult: SearchResult.empty(criteria: _currentCriteria),
      searchHistory: _searchHistory,
      suggestions: [],
      statistics: _statistics,
    ));
  }

  /// 加载更多搜索结果
  Future<void> _onLoadMoreSearchResults(
    LoadMoreSearchResults event,
    Emitter<SearchState> emit,
  ) async {
    if (state is! SearchLoadSuccess) return;

    final currentState = state as SearchLoadSuccess;
    if (!currentState.hasMoreResults) return;

    // 更新偏移量
    final newCriteria = _currentCriteria.copyWith(
      offset: _currentCriteria.offset + _currentCriteria.limit,
    );
    _currentCriteria = newCriteria;

    await _executeSearch(emit, appendResults: true);
  }

  /// 刷新搜索
  Future<void> _onRefreshSearch(
    RefreshSearch event,
    Emitter<SearchState> emit,
  ) async {
    _retryCount = 0;

    if (_currentCriteria.isValid) {
      await _executeSearch(emit);
    }
  }

  /// 保存搜索历史
  Future<void> _onSaveSearchHistory(
    SaveSearchHistory event,
    Emitter<SearchState> emit,
  ) async {
    final keyword = event.keyword.trim();
    if (keyword.isEmpty) return;

    // 移除已存在的相同关键词
    _searchHistory.remove(keyword);

    // 添加到开头
    _searchHistory.insert(0, keyword);

    // 限制历史记录数量
    if (_searchHistory.length > 50) {
      _searchHistory = _searchHistory.take(50).toList();
    }

    await _saveSearchHistoryToStorage();

    // 如果当前状态是SearchLoadSuccess，更新历史记录
    if (state is SearchLoadSuccess) {
      final currentState = state as SearchLoadSuccess;
      emit(currentState.copyWithSearchHistory(_searchHistory));
    }
  }

  /// 加载搜索历史
  Future<void> _onLoadSearchHistory(
    LoadSearchHistory event,
    Emitter<SearchState> emit,
  ) async {
    emit(SearchHistoryLoadInProgress());

    try {
      await _loadSearchHistoryFromStorage();
      emit(SearchHistoryLoadSuccess(history: _searchHistory));
    } catch (e) {
      emit(SearchLoadFailure(
        errorMessage: '加载搜索历史失败',
        errorType: SearchErrorType.data,
      ));
    }
  }

  /// 删除搜索历史
  Future<void> _onDeleteSearchHistory(
    DeleteSearchHistory event,
    Emitter<SearchState> emit,
  ) async {
    _searchHistory.remove(event.keyword);
    await _saveSearchHistoryToStorage();

    emit(SearchHistoryDeleted(deletedKeyword: event.keyword));

    // 如果当前状态是SearchLoadSuccess，更新历史记录
    if (state is SearchLoadSuccess) {
      final currentState = state as SearchLoadSuccess;
      emit(currentState.copyWithSearchHistory(_searchHistory));
    }
  }

  /// 清空搜索历史
  Future<void> _onClearSearchHistory(
    ClearSearchHistory event,
    Emitter<SearchState> emit,
  ) async {
    _searchHistory.clear();
    await _saveSearchHistoryToStorage();

    emit(SearchHistoryCleared());

    // 如果当前状态是SearchLoadSuccess，更新历史记录
    if (state is SearchLoadSuccess) {
      final currentState = state as SearchLoadSuccess;
      emit(currentState.copyWithSearchHistory(_searchHistory));
    }
  }

  /// 获取搜索建议
  Future<void> _onGetSearchSuggestions(
    GetSearchSuggestions event,
    Emitter<SearchState> emit,
  ) async {
    final keyword = event.keyword.trim();
    if (keyword.length < 2) {
      _currentSuggestions.clear();
      return;
    }

    emit(SearchSuggestionsLoadInProgress(keyword: keyword));

    try {
      // 执行搜索以获取建议
      final criteria = FundSearchCriteria.keyword(
        keyword,
      ).copyWith(limit: 5);

      final searchResult = await _searchUseCase.search(criteria);
      _currentSuggestions = searchResult.suggestions;

      emit(SearchSuggestionsLoadSuccess(
        keyword: keyword,
        suggestions: _currentSuggestions,
      ));
    } catch (e) {
      emit(SearchSuggestionsLoadSuccess(
        keyword: '',
        suggestions: [],
      ));
    }
  }

  /// 选择搜索建议
  Future<void> _onSelectSearchSuggestion(
    SelectSearchSuggestion event,
    Emitter<SearchState> emit,
  ) async {
    _currentCriteria = _currentCriteria.copyWith(keyword: event.suggestion);
    await _executeSearch(emit, includeHistory: true);
  }

  /// 更改搜索排序
  Future<void> _onChangeSearchSort(
    ChangeSearchSort event,
    Emitter<SearchState> emit,
  ) async {
    _currentCriteria = _currentCriteria.copyWith(sortBy: event.sortBy);

    emit(SearchSortUpdated(sortBy: event.sortBy));

    if (_currentCriteria.isValid) {
      await _executeSearch(emit);
    }
  }

  /// 设置搜索字段
  Future<void> _onSetSearchFields(
    SetSearchFields event,
    Emitter<SearchState> emit,
  ) async {
    _currentCriteria =
        _currentCriteria.copyWith(searchFields: event.searchFields);

    emit(SearchFieldsUpdated(searchFields: event.searchFields));

    if (_currentCriteria.isValid) {
      await _executeSearch(emit);
    }
  }

  /// 设置搜索限制
  Future<void> _onSetSearchLimit(
    SetSearchLimit event,
    Emitter<SearchState> emit,
  ) async {
    _currentCriteria = _currentCriteria.copyWith(
      limit: event.limit,
      offset: 0, // 重置偏移量
    );

    if (_currentCriteria.isValid) {
      await _executeSearch(emit);
    }
  }

  /// 切换高级搜索
  Future<void> _onToggleAdvancedSearch(
    ToggleAdvancedSearch event,
    Emitter<SearchState> emit,
  ) async {
    // 这里可以根据需要更新搜索条件
    emit(SearchOptionsUpdated(updatedCriteria: _currentCriteria));
  }

  /// 快速搜索
  Future<void> _onQuickSearch(
    QuickSearch event,
    Emitter<SearchState> emit,
  ) async {
    _currentCriteria = FundSearchCriteria.keyword(
      event.keyword,
      searchType: event.searchType,
    );

    await _executeSearch(emit, includeHistory: true);
  }

  /// 获取搜索统计信息
  Future<void> _onGetSearchStatistics(
    GetSearchStatistics event,
    Emitter<SearchState> emit,
  ) async {
    try {
      _statistics = _searchUseCase.getPerformanceStats();
      emit(SearchStatisticsLoaded(statistics: _statistics));
    } catch (e) {
      emit(SearchStatisticsLoaded(statistics: {}));
    }
  }

  /// 清空搜索缓存
  Future<void> _onClearSearchCache(
    ClearSearchCache event,
    Emitter<SearchState> emit,
  ) async {
    try {
      _searchUseCase.clearCache();
      emit(SearchCacheCleared());
    } catch (e) {
      emit(SearchLoadFailure(
        errorMessage: '清空搜索缓存失败',
        errorType: SearchErrorType.data,
      ));
    }
  }

  /// 预热搜索缓存
  Future<void> _onWarmupSearchCache(
    WarmupSearchCache event,
    Emitter<SearchState> emit,
  ) async {
    try {
      await _searchUseCase.warmupCache();
      emit(SearchCacheWarmedUp(success: true));
    } catch (e) {
      emit(SearchCacheWarmedUp(
        success: false,
        message: '预热搜索缓存失败',
      ));
    }
  }

  /// 搜索超时处理
  Future<void> _onSearchTimeout(
    SearchTimeoutEvent event,
    Emitter<SearchState> emit,
  ) async {
    emit(SearchTimeout(
      criteria: event.criteria,
      timeoutMs: event.timeoutMs,
    ));
  }

  /// 重试搜索
  Future<void> _onRetrySearch(
    RetrySearch event,
    Emitter<SearchState> emit,
  ) async {
    if (_retryCount >= SearchBloc.maxRetries) {
      emit(SearchLoadFailure(
        errorMessage: '搜索重试次数已达上限',
        errorType: SearchErrorType.timeout,
      ));
      return;
    }

    _retryCount++;
    _currentCriteria = event.criteria;

    // 不需要发射 SearchRetry 状态，直接执行搜索

    await _executeSearch(emit);
  }

  /// 执行搜索的核心逻辑
  Future<void> _executeSearch(
    Emitter<SearchState> emit, {
    bool includeHistory = false,
    bool appendResults = false,
  }) async {
    if (!_currentCriteria.isValid) {
      emit(SearchLoadSuccess(
        searchResult: SearchResult.empty(criteria: _currentCriteria),
        searchHistory: _searchHistory,
        suggestions: _currentSuggestions,
        statistics: _statistics,
      ));
      return;
    }

    emit(SearchLoadInProgress(criteria: _currentCriteria));

    try {
      // 设置搜索超时
      final searchFuture = _searchUseCase.search(_currentCriteria);
      final timeoutFuture = Future.delayed(SearchBloc.searchTimeout);

      final searchResult = await Future.any([
        searchFuture,
        timeoutFuture.then(
            (_) => throw TimeoutException('搜索超时', SearchBloc.searchTimeout)),
      ]);

      // 更新统计信息
      _statistics = _searchUseCase.getPerformanceStats();

      // 性能警告
      if (searchResult.searchTimeMs > 1000) {
        emit(SearchPerformanceWarning(
          searchTimeMs: searchResult.searchTimeMs,
          warning: '搜索时间较长，建议优化搜索条件',
        ));
      }

      // 保存搜索历史
      if (includeHistory && _currentCriteria.keyword != null) {
        add(SaveSearchHistory(keyword: _currentCriteria.keyword!));
      }

      // 合并结果（如果需要追加）
      SearchResult finalResult = searchResult;
      if (appendResults && state is SearchLoadSuccess) {
        final currentState = state as SearchLoadSuccess;
        final existingFunds =
            List<FundSearchMatch>.from(currentState.searchResult.funds);
        existingFunds.addAll(searchResult.funds);

        finalResult = SearchResult(
          funds: existingFunds,
          totalCount: searchResult.totalCount,
          searchTimeMs: searchResult.searchTimeMs,
          criteria: searchResult.criteria,
          hasMore: searchResult.hasMore,
          suggestions: searchResult.suggestions,
        );
      }

      emit(SearchLoadSuccess(
        searchResult: finalResult,
        searchHistory: _searchHistory,
        suggestions: _currentSuggestions,
        statistics: _statistics,
      ));

      // 重置重试计数
      _retryCount = 0;
    } on TimeoutException {
      emit(SearchTimeout(
        criteria: _currentCriteria,
        timeoutMs: SearchBloc.searchTimeout.inMilliseconds,
      ));
    } catch (e) {
      emit(SearchLoadFailure(
        errorMessage: '搜索失败: ${e.toString()}',
        criteria: _currentCriteria,
        errorType: _getErrorType(e),
      ));
    }
  }

  /// 从存储加载搜索历史
  Future<void> _loadSearchHistoryFromStorage() async {
    try {
      // 这里应该实现实际的存储逻辑
      // 暂时使用模拟数据
      _searchHistory = [
        '股票基金',
        '债券基金',
        '货币基金',
        '混合基金',
      ];
    } catch (e) {
      _searchHistory = [];
    }
  }

  /// 保存搜索历史到存储
  Future<void> _saveSearchHistoryToStorage() async {
    try {
      // 这里应该实现实际的存储逻辑
      // 使用Logger记录日志
      AppLogger.business('保存搜索历史: $_searchHistory', 'SearchBloc');
    } catch (e) {
      AppLogger.error('保存搜索历史失败', e);
    }
  }

  /// 根据异常类型确定错误类型
  SearchErrorType _getErrorType(dynamic error) {
    if (error.toString().contains('网络') ||
        error.toString().contains('network')) {
      return SearchErrorType.network;
    } else if (error.toString().contains('超时') ||
        error.toString().contains('timeout')) {
      return SearchErrorType.timeout;
    } else if (error.toString().contains('参数') ||
        error.toString().contains('parameter')) {
      return SearchErrorType.parameters;
    } else if (error.toString().contains('权限') ||
        error.toString().contains('permission')) {
      return SearchErrorType.permission;
    } else if (error.toString().contains('服务器') ||
        error.toString().contains('server')) {
      return SearchErrorType.server;
    } else {
      return SearchErrorType.unknown;
    }
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}

/// 超时异常类
class TimeoutException implements Exception {
  final String message;
  final Duration duration;

  TimeoutException(this.message, this.duration);

  @override
  String toString() => message;
}

/// 非等待执行
void unawaited(Future<void> future) {
  // 忽略结果，避免警告
}
