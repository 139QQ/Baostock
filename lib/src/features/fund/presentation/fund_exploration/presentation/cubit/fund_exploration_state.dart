part of 'fund_exploration_cubit.dart';

/// 基金探索视图枚举
enum FundExplorationView {
  /// 搜索视图
  search,

  /// 筛选视图
  filtered,

  /// 对比视图
  comparison,

  /// 全部视图
  all,

  /// 热门视图
  hot,

  /// 排行视图
  ranking,

  /// 货币基金视图
  moneyFunds,
}

/// 基金探索状态枚举
enum FundExplorationStatus {
  /// 初始状态
  initial,

  /// 加载中
  loading,

  /// 加载完成
  loaded,

  /// 搜索中
  searching,

  /// 搜索完成
  searched,

  /// 筛选中
  filtering,

  /// 筛选完成
  filtered,

  /// 错误状态
  error,
}

/// 基金探索状态类
///
/// 统一的基金探索页面状态，包含所有需要的状态信息
/// 使用Equatable确保状态比较的效率
class FundExplorationState extends Equatable {
  /// 当前状态
  final FundExplorationStatus status;

  /// 基金排行数据（原始数据）
  final List<FundRanking> fundRankings;

  /// 搜索结果数据
  final List<FundRanking> searchResults;

  /// 筛选后的结果数据
  final List<FundRanking> filteredRankings;

  /// 搜索查询字符串
  final String searchQuery;

  /// 错误信息
  final String? errorMessage;

  /// 是否正在加载
  final bool isLoading;

  /// 是否正在加载更多数据
  final bool isLoadingMore;

  /// 是否有更多数据可加载
  final bool hasMoreData;

  /// 最后更新时间
  final DateTime? lastUpdateTime;

  /// 数据总数
  final int totalCount;

  /// 是否为真实数据（相对于模拟数据）
  final bool isRealData;

  /// 当前激活的筛选条件
  final String activeFilter;

  /// 当前激活的排序字段
  final String activeSortBy;

  /// 当前激活的排序顺序
  final String activeSortOrder;

  /// 展开的基金代码集合
  final Set<String> expandedFunds;

  /// 加载进度（0.0-1.0）
  final double loadProgress;

  /// 搜索历史记录
  final List<String> searchHistory;

  /// 对比基金列表
  final List<FundRanking> comparisonFunds;

  /// 是否处于对比模式
  final bool isComparing;

  /// 货币基金数据
  final List<MoneyFund> moneyFunds;

  /// 货币基金搜索结果
  final List<MoneyFund> moneyFundSearchResults;

  /// 货币基金是否正在加载
  final bool isMoneyFundsLoading;

  /// 货币基金加载错误信息
  final String? moneyFundsError;

  /// 当前活跃视图
  final FundExplorationView activeView;

  /// 排序字段
  final String sortBy;

  /// 收藏基金集合
  final Set<String> favoriteFunds;

  /// 对比基金集合
  final Set<String> comparingFunds;

  /// 创建基金探索状态
  const FundExplorationState({
    this.status = FundExplorationStatus.initial,
    this.fundRankings = const [],
    this.searchResults = const [],
    this.filteredRankings = const [],
    this.searchQuery = '',
    this.errorMessage,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMoreData = false,
    this.lastUpdateTime,
    this.totalCount = 0,
    this.isRealData = false,
    this.activeFilter = '',
    this.activeSortBy = 'return1Y',
    this.activeSortOrder = 'desc',
    this.expandedFunds = const {},
    this.loadProgress = 0.0,
    this.searchHistory = const [],
    this.comparisonFunds = const [],
    this.isComparing = false,
    this.moneyFunds = const [],
    this.moneyFundSearchResults = const [],
    this.isMoneyFundsLoading = false,
    this.moneyFundsError,
    this.activeView = FundExplorationView.ranking,
    this.sortBy = 'return1Y',
    this.favoriteFunds = const {},
    this.comparingFunds = const {},
  });

  /// 初始状态构造函数
  const FundExplorationState.initial()
      : this(
          status: FundExplorationStatus.initial,
          fundRankings: const [],
          searchResults: const [],
          filteredRankings: const [],
          searchQuery: '',
          errorMessage: null,
          isLoading: false,
          isLoadingMore: false,
          hasMoreData: false,
          lastUpdateTime: null,
          totalCount: 0,
          isRealData: false,
          activeFilter: '',
          activeSortBy: 'return1Y',
          activeSortOrder: 'desc',
          expandedFunds: const {},
          loadProgress: 0.0,
          searchHistory: const [],
          comparisonFunds: const [],
          isComparing: false,
          moneyFunds: const [],
          moneyFundSearchResults: const [],
          isMoneyFundsLoading: false,
          moneyFundsError: null,
          activeView: FundExplorationView.ranking,
          sortBy: 'return1Y',
        );

  /// 加载状态构造函数
  const FundExplorationState.loading({
    this.fundRankings = const [],
    this.searchResults = const [],
    this.filteredRankings = const [],
    this.searchQuery = '',
    this.errorMessage,
    this.lastUpdateTime,
    this.totalCount = 0,
    this.isRealData = false,
    this.activeFilter = '',
    this.activeSortBy = 'return1Y',
    this.activeSortOrder = 'desc',
    this.expandedFunds = const {},
    this.loadProgress = 0.0,
    this.searchHistory = const [],
    this.comparisonFunds = const [],
    this.isComparing = false,
    this.moneyFunds = const [],
    this.moneyFundSearchResults = const [],
    this.isMoneyFundsLoading = false,
    this.moneyFundsError,
    this.activeView = FundExplorationView.ranking,
    this.sortBy = 'return1Y',
    this.favoriteFunds = const {},
    this.comparingFunds = const {},
  })  : status = FundExplorationStatus.loading,
        isLoading = true,
        isLoadingMore = false,
        hasMoreData = false;

  /// 错误状态构造函数
  const FundExplorationState.error({
    required this.errorMessage,
    this.fundRankings = const [],
    this.searchResults = const [],
    this.filteredRankings = const [],
    this.searchQuery = '',
    this.lastUpdateTime,
    this.totalCount = 0,
    this.isRealData = false,
    this.activeFilter = '',
    this.activeSortBy = 'return1Y',
    this.activeSortOrder = 'desc',
    this.expandedFunds = const {},
    this.loadProgress = 0.0,
    this.searchHistory = const [],
    this.comparisonFunds = const [],
    this.isComparing = false,
    this.moneyFunds = const [],
    this.moneyFundSearchResults = const [],
    this.isMoneyFundsLoading = false,
    this.moneyFundsError,
    this.activeView = FundExplorationView.ranking,
    this.sortBy = 'return1Y',
    this.favoriteFunds = const {},
    this.comparingFunds = const {},
  })  : status = FundExplorationStatus.error,
        isLoading = false,
        isLoadingMore = false,
        hasMoreData = false;

  /// 复制并修改部分属性
  FundExplorationState copyWith({
    FundExplorationStatus? status,
    List<FundRanking>? fundRankings,
    List<FundRanking>? searchResults,
    List<FundRanking>? filteredRankings,
    String? searchQuery,
    String? errorMessage,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMoreData,
    DateTime? lastUpdateTime,
    int? totalCount,
    bool? isRealData,
    String? activeFilter,
    String? activeSortBy,
    String? activeSortOrder,
    Set<String>? expandedFunds,
    double? loadProgress,
    List<String>? searchHistory,
    List<FundRanking>? comparisonFunds,
    bool? isComparing,
    List<MoneyFund>? moneyFunds,
    List<MoneyFund>? moneyFundSearchResults,
    bool? isMoneyFundsLoading,
    String? moneyFundsError,
    FundExplorationView? activeView,
    String? sortBy,
    Set<String>? favoriteFunds,
    Set<String>? comparingFunds,
    bool clearErrorMessage = false,
  }) {
    return FundExplorationState(
      status: status ?? this.status,
      fundRankings: fundRankings ?? this.fundRankings,
      searchResults: searchResults ?? this.searchResults,
      filteredRankings: filteredRankings ?? this.filteredRankings,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMoreData: hasMoreData ?? this.hasMoreData,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      totalCount: totalCount ?? this.totalCount,
      isRealData: isRealData ?? this.isRealData,
      activeFilter: activeFilter ?? this.activeFilter,
      activeSortBy: activeSortBy ?? this.activeSortBy,
      activeSortOrder: activeSortOrder ?? this.activeSortOrder,
      expandedFunds: expandedFunds ?? this.expandedFunds,
      loadProgress: loadProgress ?? this.loadProgress,
      searchHistory: searchHistory ?? this.searchHistory,
      comparisonFunds: comparisonFunds ?? this.comparisonFunds,
      isComparing: isComparing ?? this.isComparing,
      moneyFunds: moneyFunds ?? this.moneyFunds,
      moneyFundSearchResults:
          moneyFundSearchResults ?? this.moneyFundSearchResults,
      isMoneyFundsLoading: isMoneyFundsLoading ?? this.isMoneyFundsLoading,
      moneyFundsError: moneyFundsError ?? this.moneyFundsError,
      activeView: activeView ?? this.activeView,
      sortBy: sortBy ?? this.sortBy,
      favoriteFunds: favoriteFunds ?? this.favoriteFunds,
      comparingFunds: comparingFunds ?? this.comparingFunds,
    );
  }

  /// 获取基金数据（别名，为了兼容性）
  List<FundRanking> get funds {
    final data = currentData;
    return data.whereType<FundRanking>().toList();
  }

  /// 获取筛选后的基金数据
  List<FundRanking> get filteredFunds {
    if (filteredRankings.isNotEmpty) return filteredRankings;
    final data = currentData;
    return data.whereType<FundRanking>().toList();
  }

  /// 获取当前显示的数据
  List<dynamic> get currentData {
    switch (activeView) {
      case FundExplorationView.moneyFunds:
        return isMoneyFundsSearching ? moneyFundSearchResults : moneyFunds;
      case FundExplorationView.search:
      case FundExplorationView.filtered:
      case FundExplorationView.comparison:
      case FundExplorationView.all:
      case FundExplorationView.hot:
      case FundExplorationView.ranking:
        switch (status) {
          case FundExplorationStatus.searching:
          case FundExplorationStatus.searched:
            return searchResults;
          case FundExplorationStatus.filtered:
            return filteredRankings.isNotEmpty
                ? filteredRankings
                : searchResults;
          case FundExplorationStatus.initial:
          case FundExplorationStatus.loading:
          case FundExplorationStatus.loaded:
          case FundExplorationStatus.filtering:
          case FundExplorationStatus.error:
            return fundRankings;
        }
    }
  }

  /// 是否正在搜索货币基金
  bool get isMoneyFundsSearching =>
      activeView == FundExplorationView.moneyFunds && searchQuery.isNotEmpty;

  /// 获取货币基金数据
  List<MoneyFund> get currentMoneyFunds {
    if (activeView == FundExplorationView.moneyFunds) {
      return isMoneyFundsSearching ? moneyFundSearchResults : moneyFunds;
    }
    return [];
  }

  /// 是否有数据
  bool get hasData => currentData.isNotEmpty;

  /// 是否为空状态
  bool get isEmpty => !hasData && !isLoading;

  /// 是否显示加载指示器
  bool get showLoadingIndicator => isLoading || isLoadingMore;

  /// 是否显示错误视图
  bool get showErrorView =>
      status == FundExplorationStatus.error && errorMessage != null;

  /// 是否显示数据视图
  bool get showDataView => hasData && !showErrorView;

  /// 是否有搜索查询
  bool get hasSearchQuery => searchQuery.isNotEmpty;

  /// 是否有筛选条件
  bool get hasActiveFilter => activeFilter.isNotEmpty;

  /// 获取数据状态描述
  String get statusDescription {
    switch (status) {
      case FundExplorationStatus.initial:
        return '准备加载数据';
      case FundExplorationStatus.loading:
        return isLoadingMore ? '加载更多数据...' : '加载数据中...';
      case FundExplorationStatus.loaded:
        return isRealData ? '数据加载完成' : '使用模拟数据';
      case FundExplorationStatus.searching:
        return '搜索中...';
      case FundExplorationStatus.searched:
        return hasSearchQuery ? '搜索完成' : '显示全部数据';
      case FundExplorationStatus.filtering:
        return '筛选中...';
      case FundExplorationStatus.filtered:
        return '筛选完成';
      case FundExplorationStatus.error:
        return '加载失败';
    }
  }

  /// 获取数据统计信息
  String get dataStatistics {
    final currentCount = currentData.length;
    final totalCountText = totalCount > 0 ? ' / $totalCount' : '';
    final searchInfo = hasSearchQuery ? ' (搜索: "$searchQuery")' : '';
    final filterInfo = hasActiveFilter ? ' (筛选: $activeFilter)' : '';

    return '显示 $currentCount$totalCountText 条数据$searchInfo$filterInfo';
  }

  @override
  List<Object?> get props => [
        status,
        fundRankings,
        searchResults,
        filteredRankings,
        searchQuery,
        errorMessage,
        isLoading,
        isLoadingMore,
        hasMoreData,
        lastUpdateTime,
        totalCount,
        isRealData,
        activeFilter,
        activeSortBy,
        activeSortOrder,
        expandedFunds,
        loadProgress,
        searchHistory,
        comparisonFunds,
        isComparing,
        moneyFunds,
        moneyFundSearchResults,
        isMoneyFundsLoading,
        moneyFundsError,
        activeView,
        sortBy,
      ];

  @override
  String toString() {
    return 'FundExplorationState('
        'status: $status, '
        'fundRankings: ${fundRankings.length}, '
        'searchResults: ${searchResults.length}, '
        'filteredRankings: ${filteredRankings.length}, '
        'searchQuery: "$searchQuery", '
        'isLoading: $isLoading, '
        'errorMessage: $errorMessage, '
        'totalCount: $totalCount, '
        'isRealData: $isRealData, '
        'moneyFunds: ${moneyFunds.length}, '
        'moneyFundSearchResults: ${moneyFundSearchResults.length}, '
        'isMoneyFundsLoading: $isMoneyFundsLoading, '
        'moneyFundsError: $moneyFundsError'
        ')';
  }
}
