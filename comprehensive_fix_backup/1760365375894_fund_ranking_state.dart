part of 'fund_ranking_bloc.dart';

/// 基金排行榜状态基类（用于状态模式）
abstract class FundRankingStateBase extends Equatable {
  const FundRankingStateBase();

  @override
  List<Object?> get props => [];
}

/// 初始状态
class FundRankingInitial extends FundRankingStateBase {
  const FundRankingInitial();

  @override
  String toString() => 'FundRankingInitial';
}

/// 加载中状态
class FundRankingLoadInProgress extends FundRankingStateBase {
  /// 当前查询条件
  final RankingCriteria? criteria;

  /// 是否为刷新操作
  final bool isRefreshing;

  /// 是否为加载更多操作
  final bool isLoadingMore;

  const FundRankingLoadInProgress({
    this.criteria,
    this.isRefreshing = false,
    this.isLoadingMore = false,
  });

  @override
  List<Object?> get props => [criteria, isRefreshing, isLoadingMore];

  @override
  String toString() =>
      'FundRankingLoadInProgress{criteria: $criteria, isRefreshing: $isRefreshing, isLoadingMore: $isLoadingMore}';
}

/// 加载成功状态
class FundRankingLoadSuccess extends FundRankingStateBase {
  /// 排行榜数据
  final List<FundRanking> rankings;

  /// 当前查询条件
  final RankingCriteria criteria;

  /// 是否有更多数据
  final bool hasMoreData;

  /// 总数据量
  final int totalCount;

  /// 统计信息
  final RankingStatistics? statistics;

  /// 搜索结果
  final String? searchQuery;

  /// 是否为热门排行榜
  final bool isHotRanking;

  /// 热门排行榜类型
  final HotRankingType? hotRankingType;

  /// 收藏的基金列表
  final Set<String> favoriteFunds;

  /// 视图模式
  final RankingViewMode viewMode;

  /// 最后更新时间
  final DateTime lastUpdateTime;

  const FundRankingLoadSuccess({
    required this.rankings,
    required this.criteria,
    this.hasMoreData = false,
    required this.totalCount,
    this.statistics,
    this.searchQuery,
    this.isHotRanking = false,
    this.hotRankingType,
    this.favoriteFunds = const {},
    this.viewMode = RankingViewMode.card,
    required this.lastUpdateTime,
  });

  /// 创建副本
  FundRankingLoadSuccess copyWith({
    List<FundRanking>? rankings,
    RankingCriteria? criteria,
    bool? hasMoreData,
    int? totalCount,
    RankingStatistics? statistics,
    String? searchQuery,
    bool? isHotRanking,
    HotRankingType? hotRankingType,
    Set<String>? favoriteFunds,
    RankingViewMode? viewMode,
    DateTime? lastUpdateTime,
  }) {
    return FundRankingLoadSuccess(
      rankings: rankings ?? this.rankings,
      criteria: criteria ?? this.criteria,
      hasMoreData: hasMoreData ?? this.hasMoreData,
      totalCount: totalCount ?? this.totalCount,
      statistics: statistics ?? this.statistics,
      searchQuery: searchQuery ?? this.searchQuery,
      isHotRanking: isHotRanking ?? this.isHotRanking,
      hotRankingType: hotRankingType ?? this.hotRankingType,
      favoriteFunds: favoriteFunds ?? this.favoriteFunds,
      viewMode: viewMode ?? this.viewMode,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
    );
  }

  /// 获取当前页
  int get currentPage => criteria.page;

  /// 获取总页数
  int get totalPages => (totalCount / criteria.pageSize).ceil();

  /// 是否有上一页
  bool get hasPreviousPage => currentPage > 1;

  /// 是否为空状态
  bool get isEmpty => rankings.isEmpty;

  /// 是否为搜索状态
  bool get isSearch => searchQuery != null && searchQuery!.isNotEmpty;

  @override
  List<Object?> get props => [
        rankings,
        criteria,
        hasMoreData,
        totalCount,
        statistics,
        searchQuery,
        isHotRanking,
        hotRankingType,
        favoriteFunds,
        viewMode,
        lastUpdateTime,
      ];

  @override
  String toString() {
    return 'FundRankingLoadSuccess{'
        'rankings: ${rankings.length}, '
        'criteria: $criteria, '
        'hasMoreData: $hasMoreData, '
        'totalCount: $totalCount, '
        'isSearch: $isSearch, '
        'isHotRanking: $isHotRanking, '
        'viewMode: $viewMode'
        '}';
  }
}

/// 加载失败状态
class FundRankingLoadFailure extends FundRankingStateBase {
  /// 错误信息
  final String error;

  /// 当前查询条件
  final RankingCriteria? criteria;

  /// 是否为网络错误
  final bool isNetworkError;

  /// 是否为数据解析错误
  final bool isDataError;

  /// 重试次数
  final int retryCount;

  const FundRankingLoadFailure({
    required this.error,
    this.criteria,
    this.isNetworkError = false,
    this.isDataError = false,
    this.retryCount = 0,
  });

  /// 创建副本
  FundRankingLoadFailure copyWith({
    String? error,
    RankingCriteria? criteria,
    bool? isNetworkError,
    bool? isDataError,
    int? retryCount,
  }) {
    return FundRankingLoadFailure(
      error: error ?? this.error,
      criteria: criteria ?? this.criteria,
      isNetworkError: isNetworkError ?? this.isNetworkError,
      isDataError: isDataError ?? this.isDataError,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  @override
  List<Object?> get props => [
        error,
        criteria,
        isNetworkError,
        isDataError,
        retryCount,
      ];

  @override
  String toString() {
    return 'FundRankingLoadFailure{'
        'error: $error, '
        'isNetworkError: $isNetworkError, '
        'isDataError: $isDataError, '
        'retryCount: $retryCount'
        '}';
  }
}

/// 基金排名历史加载状态
class FundRankingHistoryState extends Equatable {
  /// 基金代码
  final String fundCode;

  /// 时间段
  final RankingPeriod period;

  /// 历史数据
  final List<FundRanking> history;

  /// 是否正在加载
  final bool isLoading;

  /// 错误信息
  final String? error;

  const FundRankingHistoryState({
    required this.fundCode,
    required this.period,
    this.history = const [],
    this.isLoading = false,
    this.error,
  });

  /// 创建副本
  FundRankingHistoryState copyWith({
    String? fundCode,
    RankingPeriod? period,
    List<FundRanking>? history,
    bool? isLoading,
    String? error,
  }) {
    return FundRankingHistoryState(
      fundCode: fundCode ?? this.fundCode,
      period: period ?? this.period,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  /// 是否为空状态
  bool get isEmpty => history.isEmpty && !isLoading && error == null;

  @override
  List<Object?> get props => [fundCode, period, history, isLoading, error];

  @override
  String toString() {
    return 'FundRankingHistoryState{'
        'fundCode: $fundCode, '
        'period: $period, '
        'history: ${history.length}, '
        'isLoading: $isLoading, '
        'error: $error'
        '}';
  }
}

/// 排行榜视图模式枚举
enum RankingViewMode {
  card, // 卡片视图
  table, // 表格视图
}

/// 排行榜综合状态（包含多个子状态）
class FundRankingState extends Equatable {
  /// 主要排行榜状态
  final FundRankingStateBase rankingState;

  /// 基金排名历史状态
  final Map<String, FundRankingHistoryState> historyStates;

  /// 当前选中的基金
  final String? selectedFundCode;

  /// 收藏的基金列表
  final Set<String> favoriteFunds;

  const FundRankingState({
    required this.rankingState,
    this.historyStates = const {},
    this.selectedFundCode,
    this.favoriteFunds = const {},
  });

  /// 初始状态
  factory FundRankingState.initial() {
    return const FundRankingState(
      rankingState: FundRankingInitial(),
      historyStates: {},
      selectedFundCode: null,
      favoriteFunds: {},
    );
  }

  /// 是否为加载中状态
  bool get isLoading => rankingState is FundRankingLoadInProgress;

  /// 是否为成功状态
  bool get isSuccess => rankingState is FundRankingLoadSuccess;

  /// 是否为失败状态
  bool get isFailure => rankingState is FundRankingLoadFailure;

  /// 是否为初始状态
  bool get isInitial => rankingState is FundRankingInitial;

  /// 获取成功状态数据
  FundRankingLoadSuccess? get successData =>
      rankingState is FundRankingLoadSuccess
          ? rankingState as FundRankingLoadSuccess
          : null;

  /// 获取失败状态数据
  FundRankingLoadFailure? get failureData =>
      rankingState is FundRankingLoadFailure
          ? rankingState as FundRankingLoadFailure
          : null;

  /// 获取排行榜数据
  List<FundRanking> get rankings => successData?.rankings ?? const [];

  /// 获取当前查询条件
  RankingCriteria? get criteria => successData?.criteria;

  /// 是否为空状态
  bool get isEmpty => rankings.isEmpty && !isLoading;

  /// 获取指定基金的历史状态
  FundRankingHistoryState? getHistoryState(
      String fundCode, RankingPeriod period) {
    final key = '${fundCode}_${period.name}';
    return historyStates[key];
  }

  /// 创建副本
  FundRankingState copyWith({
    FundRankingStateBase? rankingState,
    Map<String, FundRankingHistoryState>? historyStates,
    String? selectedFundCode,
    Set<String>? favoriteFunds,
  }) {
    return FundRankingState(
      rankingState: rankingState ?? this.rankingState,
      historyStates: historyStates ?? this.historyStates,
      selectedFundCode: selectedFundCode ?? this.selectedFundCode,
      favoriteFunds: favoriteFunds ?? this.favoriteFunds,
    );
  }

  @override
  List<Object?> get props => [
        rankingState,
        historyStates,
        selectedFundCode,
        favoriteFunds,
      ];

  @override
  String toString() {
    return 'FundRankingState{'
        'rankingState: $rankingState, '
        'historyStates: ${historyStates.length}, '
        'selectedFundCode: $selectedFundCode, '
        'favoriteFunds: ${favoriteFunds.length}'
        '}';
  }
}
