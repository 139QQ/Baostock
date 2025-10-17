import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc/fund_ranking_bloc.dart';
import '../../../../domain/entities/fund.dart';
import '../../../../domain/entities/fund_ranking.dart';
import '../../../../domain/usecases/get_fund_rankings.dart';
import '../../../domain/models/fund_filter.dart';

part 'fund_exploration_state.dart';

/// 基金探索页面状态管理（简化版）
///
/// 职责：
/// - 纯UI状态管理
/// - 页面导航状态
/// - 临时状态（表单输入、滚动位置等）
/// - 数据操作委托给FundRankingBloc
class FundExplorationCubit extends Cubit<FundExplorationState> {
  final FundRankingBloc _fundRankingBloc;
  StreamSubscription<FundRankingState>? _rankingBlocSubscription;

  FundExplorationCubit({
    required FundRankingBloc fundRankingBloc,
  })  : _fundRankingBloc = fundRankingBloc,
        super(FundExplorationState()) {
    _listenToRankingBloc();
  }

  /// 监听FundRankingBloc状态变化
  void _listenToRankingBloc() {
    _rankingBlocSubscription = _fundRankingBloc.stream.listen((rankingState) {
      if (isClosed) return;

      // 将FundRankingBloc的状态映射到UI状态
      final uiStatus = _mapRankingStateToUiStatus(rankingState);
      final errorMessage = rankingState.failureData?.error;

      emit(state.copyWith(
        status: uiStatus,
        errorMessage: errorMessage,
        // 同步排行榜数据
        fundRankings: rankingState.rankings,
        // 同步是否为真实数据
        isRealData: _checkIfRealData(rankingState),
      ));
    });
  }

  /// 将FundRankingBloc状态映射到UI状态
  FundExplorationStatus _mapRankingStateToUiStatus(
      FundRankingState rankingState) {
    if (rankingState.isInitial) {
      return FundExplorationStatus.initial;
    } else if (rankingState.isLoading) {
      return FundExplorationStatus.loading;
    } else if (rankingState.isSuccess) {
      final successData = rankingState.successData;
      if (successData?.isSearch == true) {
        return FundExplorationStatus.searching;
      } else {
        return FundExplorationStatus.loaded;
      }
    } else if (rankingState.isFailure) {
      return FundExplorationStatus.error;
    }
    return FundExplorationStatus.initial;
  }

  /// 初始化页面
  Future<void> initialize() async {
    emit(state.copyWith(status: FundExplorationStatus.loading));

    // 委托数据加载给FundRankingBloc
    _fundRankingBloc.add(LoadFundRankings(
      criteria: const RankingCriteria(
        rankingType: RankingType.overall,
        rankingPeriod: RankingPeriod.oneYear,
        sortBy: RankingSortBy.returnRate,
        page: 1,
        pageSize: 20,
      ),
    ));
  }

  /// 刷新数据
  Future<void> refreshData() async {
    emit(state.copyWith(isRefreshing: true));

    // 委托刷新操作给FundRankingBloc
    _fundRankingBloc.add(const RefreshFundRankings());

    // 稍后重置刷新状态
    Future.delayed(const Duration(seconds: 1), () {
      if (!isClosed) {
        emit(state.copyWith(isRefreshing: false));
      }
    });
  }

  /// 加载更多数据
  void loadMoreData() {
    // 委托加载更多操作给FundRankingBloc
    _fundRankingBloc.add(const LoadMoreRankings());
  }

  /// 切换当前选中的标签页
  void setSelectedTab(int tabIndex) {
    emit(state.copyWith(selectedTab: tabIndex));
  }

  /// 切换当前视图
  void setActiveView(FundExplorationView view) {
    emit(state.copyWith(activeView: view));
  }

  /// 更新搜索查询
  void updateSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));

    // 委托搜索操作给FundRankingBloc
    if (query.isNotEmpty) {
      _fundRankingBloc.add(SearchRankings(
        query: query,
        baseCriteria: const RankingCriteria(
          rankingType: RankingType.overall,
          rankingPeriod: RankingPeriod.oneYear,
          sortBy: RankingSortBy.returnRate,
          page: 1,
          pageSize: 20,
        ),
      ));
    } else {
      _fundRankingBloc.add(const ClearSearchRankings());
    }
  }

  /// 搜索基金
  void searchFunds(String query) {
    updateSearchQuery(query);
  }

  /// 应用筛选条件
  void applyFilter({
    String? fundType,
    String? sortBy,
    String? sortOrder,
    double? minReturn,
    double? maxReturn,
  }) {
    // 委托筛选操作给FundRankingBloc
    if (fundType != null) {
      _fundRankingBloc.add(ChangeFundTypeFilter(fundType));
    }

    if (sortBy != null) {
      final rankingSortBy = _mapStringToRankingSortBy(sortBy);
      _fundRankingBloc.add(ChangeSortBy(rankingSortBy));
    }

    emit(state.copyWith(
      activeFilter: fundType,
      activeSortBy: sortBy ?? 'return1Y',
    ));
  }

  /// 更新排序方式
  void updateSortBy(String sortBy) {
    applyFilter(sortBy: sortBy);
  }

  /// 应用筛选条件（别名，与applyFilter相同）
  void applyFilters({
    String? fundType,
    String? sortBy,
    String? sortOrder,
    double? minReturn,
    double? maxReturn,
  }) {
    applyFilter(
      fundType: fundType,
      sortBy: sortBy,
      sortOrder: sortOrder,
      minReturn: minReturn,
      maxReturn: maxReturn,
    );
  }

  /// 加载热门基金
  void loadHotFunds() {
    _fundRankingBloc.add(LoadHotRankings(
      type: HotRankingType.topGainers,
      pageSize: 50,
    ));
  }

  /// 切换收藏状态
  void toggleFavorite(String fundCode) {
    // 检查当前是否已收藏
    if (state.expandedFunds.contains(fundCode)) {
      // 移除收藏
      _fundRankingBloc.add(RemoveFavoriteFund(fundCode));
    } else {
      // 添加收藏
      _fundRankingBloc.add(AddFavoriteFund(fundCode));
    }
  }

  /// 切换基金的显示状态（展开/折叠）
  void toggleFundExpanded(String fundCode) {
    final expandedFunds = Set<String>.from(state.expandedFunds);

    if (expandedFunds.contains(fundCode)) {
      expandedFunds.remove(fundCode);
    } else {
      expandedFunds.add(fundCode);
    }

    emit(state.copyWith(expandedFunds: expandedFunds));
  }

  /// 更新滚动位置
  void updateScrollPosition(double position) {
    emit(state.copyWith(scrollPosition: position));
  }

  /// 清除错误信息
  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }

  /// 重置所有状态
  void reset() {
    emit(FundExplorationState());
  }

  /// 获取当前筛选摘要
  String getFilterSummary() {
    final parts = <String>[];

    if (state.activeFilter != null) {
      parts.add('类型: ${state.activeFilter}');
    }

    if (state.activeSortBy != null) {
      final sortText = _getSortText(state.activeSortBy!);
      parts.add('排序: $sortText');
    }

    if (state.searchQuery.isNotEmpty) {
      parts.add('搜索: ${state.searchQuery}');
    }

    return parts.isEmpty ? '全部' : parts.join(' | ');
  }

  /// 获取排序文本
  String _getSortText(String sortBy) {
    switch (sortBy) {
      case 'return1D':
        return '日收益率';
      case 'return1W':
        return '近1周';
      case 'return1M':
        return '近1月';
      case 'return3M':
        return '近3月';
      case 'return6M':
        return '近6月';
      case 'return1Y':
        return '近1年';
      case 'return3Y':
        return '近3年';
      case 'returnYTD':
        return '今年来';
      case 'returnSinceInception':
        return '成立来';
      case 'fundName':
        return '基金名称';
      case 'fundCode':
        return '基金代码';
      default:
        return sortBy;
    }
  }

  /// 映射字符串到RankingSortBy枚举
  RankingSortBy _mapStringToRankingSortBy(String sortBy) {
    switch (sortBy) {
      case 'return1D':
        return RankingSortBy.dailyReturn;
      case 'return1Y':
        return RankingSortBy.returnRate;
      case 'fundName':
        return RankingSortBy.returnRate; // 使用默认值
      case 'fundCode':
        return RankingSortBy.returnRate; // 使用默认值
      default:
        return RankingSortBy.returnRate;
    }
  }

  /// 检查是否为真实数据
  bool _checkIfRealData(FundRankingState rankingState) {
    final rankings = rankingState.rankings;

    // 如果没有数据，默认认为是真实数据
    if (rankings.isEmpty) {
      return true;
    }

    // 检测模拟数据的模式：基金代码以1000开头且按11递增
    final isMockData = rankings.every((r) => r.fundCode.startsWith('1000')) &&
        rankings
            .map((r) => int.tryParse(r.fundCode) ?? 0)
            .every((code) => code >= 100000 && (code - 100000) % 11 == 0);

    return !isMockData;
  }

  /// 清除对比列表
  void clearComparison() {
    emit(state.copyWith(comparisonFunds: const []));
  }

  /// 添加基金到对比列表
  void addToComparison(Fund fund) {
    final currentList = List<Fund>.from(state.comparisonFunds);
    if (!currentList.any((f) => f.code == fund.code) &&
        currentList.length < 5) {
      currentList.add(fund);
      emit(state.copyWith(comparisonFunds: currentList));
    }
  }

  /// 从对比列表中移除基金
  void removeFromComparison(String fundCode) {
    final currentList = List<Fund>.from(state.comparisonFunds);
    currentList.removeWhere((f) => f.code == fundCode);
    emit(state.copyWith(comparisonFunds: currentList));
  }

  /// 检查基金是否在对比列表中
  bool isInComparison(String fundCode) {
    return state.comparisonFunds.any((f) => f.code == fundCode);
  }

  /// 获取页面统计信息
  Map<String, dynamic> getPageStats() {
    return {
      'totalFunds': state.fundRankings.length,
      'currentView': state.activeView.name,
      'selectedTab': state.selectedTab,
      'hasError': state.errorMessage != null,
      'isLoading': state.isLoading,
      'isRealData': state.isRealData,
      'searchQuery': state.searchQuery,
      'activeFilter': state.activeFilter,
      'activeSortBy': state.activeSortBy,
      'expandedFunds': state.expandedFunds.length,
      'scrollPosition': state.scrollPosition,
    };
  }

  @override
  Future<void> close() {
    _rankingBlocSubscription?.cancel();
    return super.close();
  }
}
