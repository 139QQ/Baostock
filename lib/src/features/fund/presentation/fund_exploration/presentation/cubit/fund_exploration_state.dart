part of 'fund_exploration_cubit.dart';

enum FundExplorationStatus {
  initial,
  loading,
  searching,
  filtering,
  loaded,
  error,
}

enum FundExplorationView {
  all, // 全部基金
  hot, // 热门基金
  ranking, // 基金排行
  filtered, // 筛选结果
  search, // 搜索结果
  comparison, // 对比模式
}

class FundExplorationState extends Equatable {
  final FundExplorationStatus status;
  final FundExplorationView activeView;
  final List<Fund> funds;
  final List<Fund> hotFunds;
  final List<FundRanking> fundRankings;
  final List<Fund> searchResults;
  final List<Fund> filteredFunds;
  final List<Fund> comparisonFunds;
  final FundFilter currentFilter;
  final String searchQuery;
  final String sortBy;
  final String? errorMessage;
  final bool isRefreshing;
  final int fundRankingsPage; // 基金排行当前页码
  final int fundRankingsPageSize; // 基金排行每页大小
  final bool hasMoreFundRankings; // 是否还有更多基金排行数据
  final bool isFundRankingsRealData; // 基金排行是否为真实数据（而非模拟数据）
  final int selectedTab; // 当前选中的标签页
  final Set<String> expandedFunds; // 展开的基金列表
  final String activeFilter; // 当前激活的筛选条件
  final String activeSortBy; // 当前激活的排序条件
  final double scrollPosition; // 滚动位置
  final bool isRealData; // 是否为真实数据

  FundExplorationState({
    this.status = FundExplorationStatus.initial,
    this.activeView = FundExplorationView.hot,
    this.funds = const [],
    this.hotFunds = const [],
    this.fundRankings = const [],
    this.searchResults = const [],
    this.filteredFunds = const [],
    this.comparisonFunds = const [],
    FundFilter? currentFilter,
    this.searchQuery = '',
    this.sortBy = 'return1Y',
    this.errorMessage,
    this.isRefreshing = false,
    this.fundRankingsPage = 1,
    this.fundRankingsPageSize = 1000, // 每页1000条，平衡性能和体验
    this.hasMoreFundRankings = true,
    this.isFundRankingsRealData = false, // 默认为false，表示初始为无数据状态
    this.selectedTab = 0,
    this.expandedFunds = const {},
    this.activeFilter = '',
    this.activeSortBy = '',
    this.scrollPosition = 0.0,
    this.isRealData = false,
  }) : currentFilter = currentFilter ?? FundFilter();

  /// 获取当前显示的数据列表
  List<dynamic> get displayData {
    switch (activeView) {
      case FundExplorationView.all:
        return funds;
      case FundExplorationView.hot:
        return hotFunds;
      case FundExplorationView.ranking:
        return fundRankings;
      case FundExplorationView.filtered:
        return filteredFunds;
      case FundExplorationView.search:
        return searchResults;
      case FundExplorationView.comparison:
        return comparisonFunds;
    }
  }

  /// 获取当前显示的基金列表
  List<Fund> get displayFunds {
    switch (activeView) {
      case FundExplorationView.all:
        return funds;
      case FundExplorationView.hot:
        return hotFunds;
      case FundExplorationView.filtered:
        return filteredFunds;
      case FundExplorationView.search:
        return searchResults;
      case FundExplorationView.comparison:
        return comparisonFunds;
      case FundExplorationView.ranking:
        return [];
    }
  }

  /// 是否正在加载数据
  bool get isLoading =>
      status == FundExplorationStatus.loading ||
      status == FundExplorationStatus.searching ||
      status == FundExplorationStatus.filtering;

  /// 是否可以加载更多
  bool get canLoadMore {
    if (isLoading) return false;

    switch (activeView) {
      case FundExplorationView.all:
      case FundExplorationView.filtered:
      case FundExplorationView.search:
        return displayFunds.length >= (currentFilter.pageSize ?? 20);
      case FundExplorationView.ranking:
        return fundRankings.length >= 20;
      default:
        return false;
    }
  }

  /// 是否显示空状态
  bool get isEmpty {
    if (isLoading) return false;

    switch (activeView) {
      case FundExplorationView.all:
        return funds.isEmpty;
      case FundExplorationView.hot:
        return hotFunds.isEmpty;
      case FundExplorationView.ranking:
        return fundRankings.isEmpty;
      case FundExplorationView.filtered:
        return filteredFunds.isEmpty;
      case FundExplorationView.search:
        return searchResults.isEmpty;
      case FundExplorationView.comparison:
        return comparisonFunds.isEmpty;
    }
  }

  FundExplorationState copyWith({
    FundExplorationStatus? status,
    FundExplorationView? activeView,
    List<Fund>? funds,
    List<Fund>? hotFunds,
    List<FundRanking>? fundRankings,
    List<Fund>? searchResults,
    List<Fund>? filteredFunds,
    List<Fund>? comparisonFunds,
    FundFilter? currentFilter,
    String? searchQuery,
    String? sortBy,
    String? errorMessage,
    bool? isRefreshing,
    int? fundRankingsPage,
    int? fundRankingsPageSize,
    bool? hasMoreFundRankings,
    bool? isFundRankingsRealData,
    int? selectedTab,
    Set<String>? expandedFunds,
    String? activeFilter,
    String? activeSortBy,
    double? scrollPosition,
    bool? isRealData,
  }) {
    return FundExplorationState(
      status: status ?? this.status,
      activeView: activeView ?? this.activeView,
      funds: funds ?? this.funds,
      hotFunds: hotFunds ?? this.hotFunds,
      fundRankings: fundRankings ?? this.fundRankings,
      searchResults: searchResults ?? this.searchResults,
      filteredFunds: filteredFunds ?? this.filteredFunds,
      comparisonFunds: comparisonFunds ?? this.comparisonFunds,
      currentFilter: currentFilter ?? this.currentFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      errorMessage: errorMessage ?? this.errorMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      fundRankingsPage: fundRankingsPage ?? this.fundRankingsPage,
      fundRankingsPageSize: fundRankingsPageSize ?? this.fundRankingsPageSize,
      hasMoreFundRankings: hasMoreFundRankings ?? this.hasMoreFundRankings,
      isFundRankingsRealData:
          isFundRankingsRealData ?? this.isFundRankingsRealData,
      selectedTab: selectedTab ?? this.selectedTab,
      expandedFunds: expandedFunds ?? this.expandedFunds,
      activeFilter: activeFilter ?? this.activeFilter,
      activeSortBy: activeSortBy ?? this.activeSortBy,
      scrollPosition: scrollPosition ?? this.scrollPosition,
      isRealData: isRealData ?? this.isRealData,
    );
  }

  @override
  List<Object?> get props => [
        status,
        activeView,
        funds,
        hotFunds,
        fundRankings,
        searchResults,
        filteredFunds,
        comparisonFunds,
        currentFilter,
        searchQuery,
        sortBy,
        errorMessage,
        isRefreshing,
        fundRankingsPage,
        fundRankingsPageSize,
        hasMoreFundRankings,
        isFundRankingsRealData,
        selectedTab,
        expandedFunds,
        activeFilter,
        activeSortBy,
        scrollPosition,
        isRealData,
      ];
}
