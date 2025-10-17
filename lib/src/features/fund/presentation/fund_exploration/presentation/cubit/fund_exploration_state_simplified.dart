part of 'fund_exploration_cubit_simplified.dart';

/// 基金探索页面状态（简化版）
///
/// 只包含UI状态，不包含数据操作逻辑
class FundExplorationStateSimplified extends Equatable {
  final FundExplorationStatus status;
  final String? errorMessage;
  final bool isRefreshing;
  final bool isLoading;

  // 视图状态
  final FundExplorationView activeView;
  final int selectedTab;

  // 数据状态（从FundRankingBloc同步）
  final List fundRankings;
  final bool isRealData;

  // 搜索状态
  final String searchQuery;

  // 筛选状态
  final String? activeFilter;
  final String? activeSortBy;

  // UI交互状态
  final Set<String> expandedFunds;
  final double scrollPosition;

  const FundExplorationStateSimplified({
    this.status = FundExplorationStatus.initial,
    this.errorMessage,
    this.isRefreshing = false,
    this.isLoading = false,
    this.activeView = FundExplorationView.ranking,
    this.selectedTab = 0,
    this.fundRankings = const [],
    this.isRealData = true,
    this.searchQuery = '',
    this.activeFilter,
    this.activeSortBy = 'return1Y',
    this.expandedFunds = const {},
    this.scrollPosition = 0.0,
  });

  FundExplorationStateSimplified copyWith({
    FundExplorationStatus? status,
    String? errorMessage,
    bool? isRefreshing,
    bool? isLoading,
    FundExplorationView? activeView,
    int? selectedTab,
    List? fundRankings,
    bool? isRealData,
    String? searchQuery,
    String? activeFilter,
    String? activeSortBy,
    Set<String>? expandedFunds,
    double? scrollPosition,
    bool clearError = false,
  }) {
    return FundExplorationStateSimplified(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoading: isLoading ?? this.isLoading,
      activeView: activeView ?? this.activeView,
      selectedTab: selectedTab ?? this.selectedTab,
      fundRankings: fundRankings ?? this.fundRankings,
      isRealData: isRealData ?? this.isRealData,
      searchQuery: searchQuery ?? this.searchQuery,
      activeFilter: activeFilter ?? this.activeFilter,
      activeSortBy: activeSortBy ?? this.activeSortBy,
      expandedFunds: expandedFunds ?? this.expandedFunds,
      scrollPosition: scrollPosition ?? this.scrollPosition,
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        isRefreshing,
        isLoading,
        activeView,
        selectedTab,
        fundRankings,
        isRealData,
        searchQuery,
        activeFilter,
        activeSortBy,
        expandedFunds,
        scrollPosition,
      ];

  @override
  String toString() {
    return 'FundExplorationStateSimplified('
        'status: $status, '
        'errorMessage: $errorMessage, '
        'isRefreshing: $isRefreshing, '
        'isLoading: $isLoading, '
        'activeView: $activeView, '
        'selectedTab: $selectedTab, '
        'fundRankingsCount: ${fundRankings.length}, '
        'isRealData: $isRealData, '
        'searchQuery: "$searchQuery", '
        'activeFilter: $activeFilter, '
        'activeSortBy: $activeSortBy, '
        'expandedFundsCount: ${expandedFunds.length}, '
        'scrollPosition: $scrollPosition'
        ')';
  }
}