import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../services/high_performance_fund_service.dart';
import '../services/fund_analysis_service.dart';
import '../services/unified_search_service/i_unified_search_service.dart';
import '../services/unified_search_service/unified_search_service.dart';
import '../services/unified_search_service/search_options_factory.dart';
import '../models/fund_info.dart';
import '../features/fund/domain/entities/fund_ranking.dart';

// ========================================
// Events
// ========================================

abstract class FundSearchEvent extends Equatable {
  const FundSearchEvent();

  @override
  List<Object> get props => [];
}

class SearchFunds extends FundSearchEvent {
  final String query;
  final int limit;

  const SearchFunds(this.query, {this.limit = 20});

  @override
  List<Object> get props => [query, limit];
}

class LoadSearchHistory extends FundSearchEvent {}

class ClearSearchHistory extends FundSearchEvent {}

class AddToSearchHistory extends FundSearchEvent {
  final String query;

  const AddToSearchHistory(this.query);

  @override
  List<Object> get props => [query];
}

class LoadRecommendedFunds extends FundSearchEvent {
  final String fundType;
  final int limit;

  const LoadRecommendedFunds({this.fundType = '全部', this.limit = 10});

  @override
  List<Object> get props => [fundType, limit];
}

class LoadPopularSearches extends FundSearchEvent {}

class FilterFunds extends FundSearchEvent {
  final String fundType;
  final String riskLevel;
  final String sortBy;

  const FilterFunds({
    this.fundType = '全部',
    this.riskLevel = '全部',
    this.sortBy = 'default',
  });

  @override
  List<Object> get props => [fundType, riskLevel, sortBy];
}

class ClearSearch extends FundSearchEvent {}

// ========================================
// 统一搜索事件
// ========================================

class UnifiedSearchFunds extends FundSearchEvent {
  final String query;
  final UnifiedSearchOptions options;

  const UnifiedSearchFunds(this.query,
      {this.options = const UnifiedSearchOptions()});

  @override
  List<Object> get props => [query, options];
}

class GetUnifiedSearchSuggestions extends FundSearchEvent {
  final String prefix;
  final int limit;

  const GetUnifiedSearchSuggestions(this.prefix, {this.limit = 10});

  @override
  List<Object> get props => [prefix, limit];
}

class ClearUnifiedSearchCache extends FundSearchEvent {}

// ========================================
// States
// ========================================

abstract class FundSearchState extends Equatable {
  const FundSearchState();

  @override
  List<Object> get props => [];
}

class FundSearchInitial extends FundSearchState {}

class FundSearchLoading extends FundSearchState {
  final String query;

  const FundSearchLoading(this.query);

  @override
  List<Object> get props => [query];
}

class FundSearchLoaded extends FundSearchState {
  final List<FundInfo> funds;
  final String query;
  final bool hasMore;
  final List<String> searchHistory;
  final List<String> popularSearches;
  final List<FundInfo> recommendedFunds;

  const FundSearchLoaded({
    required this.funds,
    required this.query,
    this.hasMore = false,
    this.searchHistory = const [],
    this.popularSearches = const [],
    this.recommendedFunds = const [],
  });

  @override
  List<Object> get props => [
        funds,
        query,
        hasMore,
        searchHistory,
        popularSearches,
        recommendedFunds,
      ];

  FundSearchLoaded copyWith({
    List<FundInfo>? funds,
    String? query,
    bool? hasMore,
    List<String>? searchHistory,
    List<String>? popularSearches,
    List<FundInfo>? recommendedFunds,
  }) {
    return FundSearchLoaded(
      funds: funds ?? this.funds,
      query: query ?? this.query,
      hasMore: hasMore ?? this.hasMore,
      searchHistory: searchHistory ?? this.searchHistory,
      popularSearches: popularSearches ?? this.popularSearches,
      recommendedFunds: recommendedFunds ?? this.recommendedFunds,
    );
  }
}

class FundSearchError extends FundSearchState {
  final String message;
  final String query;

  const FundSearchError(this.message, this.query);

  @override
  List<Object> get props => [message, query];
}

class FundSearchEmpty extends FundSearchState {
  final String query;

  const FundSearchEmpty(this.query);

  @override
  List<Object> get props => [query];
}

// ========================================
// 统一搜索状态
// ========================================

class UnifiedSearchLoading extends FundSearchState {
  final String query;

  const UnifiedSearchLoading(this.query);

  @override
  List<Object> get props => [query];
}

class UnifiedSearchLoaded extends FundSearchState {
  final List<dynamic> results; // 可以是FundRanking或FundInfo
  final String query;
  final bool useEnhancedEngine;
  final int searchTimeMs;
  final bool fromCache;

  const UnifiedSearchLoaded({
    required this.results,
    required this.query,
    required this.useEnhancedEngine,
    required this.searchTimeMs,
    this.fromCache = false,
  });

  @override
  List<Object> get props => [
        results,
        query,
        useEnhancedEngine,
        searchTimeMs,
        fromCache,
      ];
}

class UnifiedSearchSuggestionsLoaded extends FundSearchState {
  final List<String> suggestions;

  const UnifiedSearchSuggestionsLoaded(this.suggestions);

  @override
  List<Object> get props => [suggestions];
}

class UnifiedSearchError extends FundSearchState {
  final String message;
  final String query;

  const UnifiedSearchError(this.message, this.query);

  @override
  List<Object> get props => [message, query];
}

// ========================================
// BLoC
// ========================================

class FundSearchBloc extends Bloc<FundSearchEvent, FundSearchState> {
  final HighPerformanceFundService _fundService;
  final FundAnalysisService _analysisService;
  final IUnifiedSearchService _unifiedSearchService;

  List<String> _searchHistory = [];
  final List<String> _popularSearches = [
    '易方达',
    '华夏',
    '南方',
    '嘉实',
    '广发',
    '汇添富',
    '富国',
    '招商',
    '股票型',
    '混合型',
    '债券型',
  ];

  FundSearchBloc({
    required HighPerformanceFundService fundService,
    required FundAnalysisService analysisService,
    IUnifiedSearchService? unifiedSearchService,
  })  : _fundService = fundService,
        _analysisService = analysisService,
        _unifiedSearchService = unifiedSearchService ?? UnifiedSearchService(),
        super(FundSearchInitial()) {
    on<SearchFunds>(_onSearchFunds);
    on<LoadSearchHistory>(_onLoadSearchHistory);
    on<ClearSearchHistory>(_onClearSearchHistory);
    on<AddToSearchHistory>(_onAddToSearchHistory);
    on<LoadRecommendedFunds>(_onLoadRecommendedFunds);
    on<LoadPopularSearches>(_onLoadPopularSearches);
    on<FilterFunds>(_onFilterFunds);
    on<ClearSearch>(_onClearSearch);

    // 统一搜索事件处理器
    on<UnifiedSearchFunds>(_onUnifiedSearchFunds);
    on<GetUnifiedSearchSuggestions>(_onGetUnifiedSearchSuggestions);
    on<ClearUnifiedSearchCache>(_onClearUnifiedSearchCache);
  }

  Future<void> _onSearchFunds(
    SearchFunds event,
    Emitter<FundSearchState> emit,
  ) async {
    try {
      emit(FundSearchLoading(event.query));

      // 执行搜索
      final funds = _fundService.searchFunds(event.query, limit: event.limit);

      if (funds.isEmpty) {
        emit(FundSearchEmpty(event.query));
      } else {
        // 添加到搜索历史
        if (event.query.isNotEmpty) {
          _addToHistory(event.query);
        }

        emit(FundSearchLoaded(
          funds: funds,
          query: event.query,
          hasMore: funds.length >= event.limit,
          searchHistory: _searchHistory,
          popularSearches: _popularSearches,
        ));
      }
    } catch (e) {
      emit(FundSearchError('搜索失败：${e.toString()}', event.query));
    }
  }

  Future<void> _onLoadSearchHistory(
    LoadSearchHistory event,
    Emitter<FundSearchState> emit,
  ) async {
    if (state is FundSearchLoaded) {
      emit((state as FundSearchLoaded).copyWith(
        searchHistory: _searchHistory,
      ));
    }
  }

  Future<void> _onClearSearchHistory(
    ClearSearchHistory event,
    Emitter<FundSearchState> emit,
  ) async {
    _searchHistory.clear();

    if (state is FundSearchLoaded) {
      emit((state as FundSearchLoaded).copyWith(
        searchHistory: [],
      ));
    }
  }

  Future<void> _onAddToSearchHistory(
    AddToSearchHistory event,
    Emitter<FundSearchState> emit,
  ) async {
    _addToHistory(event.query);

    if (state is FundSearchLoaded) {
      emit((state as FundSearchLoaded).copyWith(
        searchHistory: _searchHistory,
      ));
    }
  }

  Future<void> _onLoadRecommendedFunds(
    LoadRecommendedFunds event,
    Emitter<FundSearchState> emit,
  ) async {
    try {
      final recommendedFunds = await _analysisService.getRecommendedFunds(
        fundType: event.fundType,
        limit: event.limit,
      );

      if (state is FundSearchLoaded) {
        emit((state as FundSearchLoaded).copyWith(
          recommendedFunds: recommendedFunds
              .map((score) => FundInfo(
                    code: score.fundCode,
                    name: score.fundName,
                    type: score.fundType,
                    pinyinAbbr: '', // 搜索时不需要拼音
                    pinyinFull: '',
                  ))
              .toList(),
        ));
      }
    } catch (e) {
      // 推荐基金加载失败不影响主要功能
      if (state is FundSearchLoaded) {
        emit((state as FundSearchLoaded).copyWith(
          recommendedFunds: [],
        ));
      }
    }
  }

  Future<void> _onLoadPopularSearches(
    LoadPopularSearches event,
    Emitter<FundSearchState> emit,
  ) async {
    if (state is FundSearchLoaded) {
      emit((state as FundSearchLoaded).copyWith(
        popularSearches: _popularSearches,
      ));
    }
  }

  Future<void> _onFilterFunds(
    FilterFunds event,
    Emitter<FundSearchState> emit,
  ) async {
    try {
      emit(const FundSearchLoading(''));

      // 获取所有基金
      List<FundInfo> funds;
      if (event.fundType == '全部') {
        funds = _fundService.searchFunds('', limit: 100);
      } else {
        funds = _fundService.searchFunds(event.fundType, limit: 100);
      }

      // 应用风险等级过滤 (简化实现)
      if (event.riskLevel != '全部') {
        // 这里可以根据基金类型或其他属性过滤
        // 暂时跳过，因为FundInfo模型没有风险等级字段
      }

      // 应用排序
      switch (event.sortBy) {
        case 'name':
          funds.sort((a, b) => a.name.compareTo(b.name));
          break;
        case 'code':
          funds.sort((a, b) => a.code.compareTo(b.code));
          break;
        case 'type':
          funds.sort((a, b) => a.type.compareTo(b.type));
          break;
        default:
          // 默认排序
          break;
      }

      if (funds.isEmpty) {
        emit(const FundSearchEmpty(''));
      } else {
        emit(FundSearchLoaded(
          funds: funds,
          query: '',
          searchHistory: _searchHistory,
          popularSearches: _popularSearches,
        ));
      }
    } catch (e) {
      emit(FundSearchError('过滤失败：${e.toString()}', ''));
    }
  }

  Future<void> _onClearSearch(
    ClearSearch event,
    Emitter<FundSearchState> emit,
  ) async {
    emit(FundSearchLoaded(
      funds: const [],
      query: '',
      searchHistory: _searchHistory,
      popularSearches: _popularSearches,
    ));
  }

  void _addToHistory(String query) {
    if (query.trim().isEmpty) return;

    // 移除已存在的相同查询
    _searchHistory.remove(query);

    // 添加到开头
    _searchHistory.insert(0, query);

    // 限制历史记录数量
    if (_searchHistory.length > 20) {
      _searchHistory = _searchHistory.take(20).toList();
    }
  }

  // 获取搜索建议
  List<String> getSearchSuggestions(String prefix) {
    if (prefix.trim().isEmpty) {
      return _popularSearches.take(5).toList();
    }

    final suggestions = <String>[];
    final lowerPrefix = prefix.toLowerCase();

    // 从搜索历史中查找匹配
    for (final history in _searchHistory) {
      if (history.toLowerCase().startsWith(lowerPrefix)) {
        suggestions.add(history);
        if (suggestions.length >= 5) break;
      }
    }

    // 从热门搜索中查找匹配
    if (suggestions.length < 5) {
      for (final popular in _popularSearches) {
        if (popular.toLowerCase().startsWith(lowerPrefix) &&
            !suggestions.contains(popular)) {
          suggestions.add(popular);
          if (suggestions.length >= 5) break;
        }
      }
    }

    return suggestions;
  }

  // 获取当前状态
  List<FundInfo> get currentFunds {
    if (state is FundSearchLoaded) {
      return (state as FundSearchLoaded).funds;
    }
    return [];
  }

  String get currentQuery {
    if (state is FundSearchLoaded) {
      return (state as FundSearchLoaded).query;
    } else if (state is FundSearchLoading) {
      return (state as FundSearchLoading).query;
    } else if (state is FundSearchError) {
      return (state as FundSearchError).query;
    } else if (state is FundSearchEmpty) {
      return (state as FundSearchEmpty).query;
    }
    return '';
  }

  bool get isLoading => state is FundSearchLoading;

  bool get hasError => state is FundSearchError;

  String? get errorMessage {
    if (state is FundSearchError) {
      return (state as FundSearchError).message;
    }
    return null;
  }

  /// 提供对基金分析服务的访问
  FundAnalysisService get analysisService => _analysisService;

  // ========================================
  // 统一搜索事件处理器
  // ========================================

  Future<void> _onUnifiedSearchFunds(
    UnifiedSearchFunds event,
    Emitter<FundSearchState> emit,
  ) async {
    try {
      emit(UnifiedSearchLoading(event.query));

      // 执行统一搜索
      final result = await _unifiedSearchService.search(
        event.query,
        options: event.options,
      );

      if (!result.isSuccess) {
        emit(UnifiedSearchError(result.error ?? '搜索失败', event.query));
        return;
      }

      if (result.results.isEmpty) {
        // 转换为空搜索状态以保持兼容性
        emit(FundSearchEmpty(event.query));
      } else {
        // 添加到搜索历史
        if (event.query.isNotEmpty && !_searchHistory.contains(event.query)) {
          _searchHistory.insert(0, event.query);
          if (_searchHistory.length > 20) {
            _searchHistory.removeLast();
          }
        }

        emit(UnifiedSearchLoaded(
          results: result.results,
          query: result.query,
          useEnhancedEngine: result.useEnhancedEngine,
          searchTimeMs: result.searchTimeMs,
          fromCache: result.fromCache,
        ));
      }
    } catch (e) {
      emit(UnifiedSearchError(e.toString(), event.query));
    }
  }

  Future<void> _onGetUnifiedSearchSuggestions(
    GetUnifiedSearchSuggestions event,
    Emitter<FundSearchState> emit,
  ) async {
    try {
      final suggestions = await _unifiedSearchService.getSuggestions(
        event.prefix,
        limit: event.limit,
      );

      emit(UnifiedSearchSuggestionsLoaded(suggestions));
    } catch (e) {
      // 建议获取失败时不影响主要搜索功能，只记录日志
      print('获取搜索建议失败: $e');
      // 保持当前状态不变
    }
  }

  Future<void> _onClearUnifiedSearchCache(
    ClearUnifiedSearchCache event,
    Emitter<FundSearchState> emit,
  ) async {
    try {
      await _unifiedSearchService.clearCache();
      // 保持当前状态不变，这是一个后台操作
    } catch (e) {
      print('清除搜索缓存失败: $e');
    }
  }

  // ========================================
  // 统一搜索便利方法
  // ========================================

  /// 执行快速搜索
  void quickSearch(String query) {
    add(UnifiedSearchFunds(
      query,
      options: SearchOptionsFactory.quickSearch(),
    ));
  }

  /// 执行精确搜索
  void preciseSearch(String query) {
    add(UnifiedSearchFunds(
      query,
      options: SearchOptionsFactory.preciseSearch(),
    ));
  }

  /// 执行全面搜索
  void comprehensiveSearch(String query) {
    add(UnifiedSearchFunds(
      query,
      options: SearchOptionsFactory.comprehensiveSearch(),
    ));
  }

  /// 自动优化搜索
  void autoSearch(String query) {
    add(UnifiedSearchFunds(
      query,
      options: SearchOptionsFactory.autoOptimizedSearch(query),
    ));
  }

  /// 获取搜索建议
  void getSuggestions(String prefix) {
    add(GetUnifiedSearchSuggestions(prefix));
  }

  /// 提供对统一搜索服务的访问
  IUnifiedSearchService get unifiedSearchService => _unifiedSearchService;
}
