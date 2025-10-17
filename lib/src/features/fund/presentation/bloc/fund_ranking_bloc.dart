import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/fund_ranking.dart';
import '../../domain/entities/ranking_statistics.dart';
import '../../domain/usecases/get_fund_rankings.dart';
import '../../domain/repositories/fund_repository.dart';

part 'fund_ranking_event.dart';
part 'fund_ranking_state.dart';

/// 基金排行榜BLoC
///
/// 负责管理基金排行榜的状态，包括：
/// - 排行榜数据加载和缓存
/// - 排行榜筛选和排序
/// - 分页和刷新功能
/// - 搜索和历史记录
/// - 收藏管理
@immutable
class FundRankingBloc extends Bloc<FundRankingEvent, FundRankingState> {
  final GetFundRankings _getFundRankings;
  final FundRepository _repository;

  // 当前查询条件缓存
  RankingCriteria? _currentCriteria;

  // 定时刷新控制器
  Timer? _refreshTimer;

  FundRankingBloc({
    required GetFundRankings getFundRankings,
    required FundRepository repository,
  })  : _getFundRankings = getFundRankings,
        _repository = repository,
        super(FundRankingState.initial()) {
    // 注册事件处理器
    on<LoadFundRankings>(_onLoadFundRankings);
    on<RefreshFundRankings>(_onRefreshFundRankings);
    on<ChangeRankingType>(_onChangeRankingType);
    on<ChangeRankingPeriod>(_onChangeRankingPeriod);
    on<ChangeFundTypeFilter>(_onChangeFundTypeFilter);
    on<ChangeFundCompanyFilter>(_onChangeFundCompanyFilter);
    on<ChangeSortBy>(_onChangeSortBy);
    on<LoadMoreRankings>(_onLoadMoreRankings);
    on<SearchRankings>(_onSearchRankings);
    on<ClearSearchRankings>(_onClearSearchRankings);
    on<LoadHotRankings>(_onLoadHotRankings);
    on<LoadRankingStatistics>(_onLoadRankingStatistics);
    on<LoadFundRankingHistory>(_onLoadFundRankingHistory);
    on<ResetRankingState>(_onResetRankingState);
    on<ToggleRankingViewMode>(_onToggleRankingViewMode);
    on<AddFavoriteFund>(_onAddFavoriteFund);
    on<RemoveFavoriteFund>(_onRemoveFavoriteFund);
    on<LoadFavoriteRankings>(_onLoadFavoriteRankings);

    // 启动定时刷新
    _startPeriodicRefresh();
  }

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    return super.close();
  }

  /// 启动定时刷新（每15分钟）
  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      if (_currentCriteria != null) {
        add(RefreshFundRankings(_currentCriteria));
      }
    });
  }

  /// 处理加载排行榜事件
  Future<void> _onLoadFundRankings(
    LoadFundRankings event,
    Emitter<FundRankingState> emit,
  ) async {
    try {
      // 缓存当前查询条件
      _currentCriteria = event.criteria;

      // 发出加载中状态
      emit(state.copyWith(
        rankingState: FundRankingLoadInProgress(
          criteria: event.criteria,
        ),
      ));

      // 获取排行榜数据
      final result = await _getFundRankings(
        event.criteria,
        forceRefresh: event.forceRefresh,
      );

      // 获取统计信息（异步，不阻塞UI）
      _loadStatisticsInBackground(event.criteria);

      // 发出成功状态
      emit(state.copyWith(
        rankingState: FundRankingLoadSuccess(
          rankings: result.rankings,
          criteria: event.criteria,
          hasMoreData: result.hasNextPage,
          totalCount: result.totalCount,
          lastUpdateTime: DateTime.now(),
          favoriteFunds: state.favoriteFunds,
        ),
      ));
    } catch (e) {
      // 判断错误类型
      final isNetworkError = _isNetworkError(e);
      final isDataError = _isDataError(e);

      emit(state.copyWith(
        rankingState: FundRankingLoadFailure(
          error: e.toString(),
          criteria: event.criteria,
          isNetworkError: isNetworkError,
          isDataError: isDataError,
        ),
      ));
    }
  }

  /// 处理刷新排行榜事件
  Future<void> _onRefreshFundRankings(
    RefreshFundRankings event,
    Emitter<FundRankingState> emit,
  ) async {
    final criteria = event.currentCriteria ?? _currentCriteria;

    if (criteria == null) {
      // 如果没有当前条件，加载默认排行榜
      add(const LoadFundRankings(
        criteria: RankingCriteria(
          rankingType: RankingType.overall,
          rankingPeriod: RankingPeriod.oneYear,
          sortBy: RankingSortBy.returnRate,
          page: 1,
          pageSize: 20,
        ),
        forceRefresh: true,
      ));
    } else {
      // 强制刷新当前排行榜
      add(LoadFundRankings(
        criteria: criteria,
        forceRefresh: true,
      ));
    }
  }

  /// 处理更改排行榜类型事件
  Future<void> _onChangeRankingType(
    ChangeRankingType event,
    Emitter<FundRankingState> emit,
  ) async {
    final currentCriteria = state.criteria;

    if (currentCriteria != null) {
      final newCriteria = currentCriteria.copyWith(
        rankingType: event.rankingType,
        page: 1, // 重置页码
      );

      add(LoadFundRankings(criteria: newCriteria));
    }
  }

  /// 处理更改排行榜时间段事件
  Future<void> _onChangeRankingPeriod(
    ChangeRankingPeriod event,
    Emitter<FundRankingState> emit,
  ) async {
    final currentCriteria = state.criteria;

    if (currentCriteria != null) {
      final newCriteria = currentCriteria.copyWith(
        rankingPeriod: event.rankingPeriod,
        page: 1, // 重置页码
      );

      add(LoadFundRankings(criteria: newCriteria));
    }
  }

  /// 处理更改基金类型筛选事件
  Future<void> _onChangeFundTypeFilter(
    ChangeFundTypeFilter event,
    Emitter<FundRankingState> emit,
  ) async {
    final currentCriteria = state.criteria;

    if (currentCriteria != null) {
      final newCriteria = currentCriteria.copyWith(
        fundType: event.fundType,
        page: 1, // 重置页码
      );

      add(LoadFundRankings(criteria: newCriteria));
    }
  }

  /// 处理更改基金公司筛选事件
  Future<void> _onChangeFundCompanyFilter(
    ChangeFundCompanyFilter event,
    Emitter<FundRankingState> emit,
  ) async {
    final currentCriteria = state.criteria;

    if (currentCriteria != null) {
      final newCriteria = currentCriteria.copyWith(
        company: event.company,
        page: 1, // 重置页码
      );

      add(LoadFundRankings(criteria: newCriteria));
    }
  }

  /// 处理更改排序方式事件
  Future<void> _onChangeSortBy(
    ChangeSortBy event,
    Emitter<FundRankingState> emit,
  ) async {
    final currentCriteria = state.criteria;

    if (currentCriteria != null) {
      final newCriteria = currentCriteria.copyWith(
        sortBy: event.sortBy,
        page: 1, // 重置页码
      );

      add(LoadFundRankings(criteria: newCriteria));
    }
  }

  /// 处理加载更多事件
  Future<void> _onLoadMoreRankings(
    LoadMoreRankings event,
    Emitter<FundRankingState> emit,
  ) async {
    final currentSuccess = state.successData;

    if (currentSuccess == null || !currentSuccess.hasMoreData) {
      return; // 没有更多数据或不在成功状态
    }

    try {
      // 发出加载更多状态
      emit(state.copyWith(
        rankingState: FundRankingLoadInProgress(
          criteria: currentSuccess.criteria,
          isLoadingMore: true,
        ),
      ));

      // 构建下一页查询条件
      final nextPageCriteria = currentSuccess.criteria.copyWith(
        page: currentSuccess.currentPage + 1,
      );

      // 获取下一页数据
      final result = await _getFundRankings(nextPageCriteria);

      // 合并数据
      final allRankings = [...currentSuccess.rankings, ...result.rankings];

      // 发出成功状态
      emit(state.copyWith(
        rankingState: currentSuccess.copyWith(
          rankings: allRankings,
          hasMoreData: result.hasNextPage,
          totalCount: result.totalCount,
        ),
      ));
    } catch (e) {
      // 加载更多失败，回到之前的状态
      emit(state.copyWith(
        rankingState: currentSuccess,
      ));

      // 可以显示错误提示
      _showErrorSnackBar('加载更多失败: ${e.toString()}');
    }
  }

  /// 处理搜索排行榜事件
  Future<void> _onSearchRankings(
    SearchRankings event,
    Emitter<FundRankingState> emit,
  ) async {
    try {
      // 使用基础查询条件或默认条件
      final baseCriteria = event.baseCriteria ??
          const RankingCriteria(
            rankingType: RankingType.overall,
            rankingPeriod: RankingPeriod.oneYear,
            sortBy: RankingSortBy.returnRate,
            page: 1,
            pageSize: 20,
          );

      // 执行搜索
      final result = await _getFundRankings.searchRankings(
        event.query,
        baseCriteria,
      );

      // 发出搜索结果状态
      emit(state.copyWith(
        rankingState: FundRankingLoadSuccess(
          rankings: result.rankings,
          criteria: baseCriteria,
          hasMoreData: result.hasNextPage,
          totalCount: result.totalCount,
          searchQuery: event.query,
          lastUpdateTime: DateTime.now(),
          favoriteFunds: state.favoriteFunds,
        ),
      ));
    } catch (e) {
      emit(state.copyWith(
        rankingState: FundRankingLoadFailure(
          error: '搜索失败: ${e.toString()}',
          criteria: event.baseCriteria,
        ),
      ));
    }
  }

  /// 处理清除搜索事件
  Future<void> _onClearSearchRankings(
    ClearSearchRankings event,
    Emitter<FundRankingState> emit,
  ) async {
    if (_currentCriteria != null) {
      add(LoadFundRankings(criteria: _currentCriteria!));
    }
  }

  /// 处理加载热门排行榜事件
  Future<void> _onLoadHotRankings(
    LoadHotRankings event,
    Emitter<FundRankingState> emit,
  ) async {
    try {
      // 发出加载中状态
      emit(state.copyWith(
        rankingState: const FundRankingLoadInProgress(),
      ));

      // 获取热门排行榜
      final result = await _getFundRankings.getHotRankings(
        event.type,
        pageSize: event.pageSize ?? 10,
      );

      // 发出热门排行榜状态
      emit(state.copyWith(
        rankingState: FundRankingLoadSuccess(
          rankings: result.rankings,
          criteria: const RankingCriteria(
            rankingType: RankingType.overall,
            rankingPeriod: RankingPeriod.oneYear,
            sortBy: RankingSortBy.returnRate,
            page: 1,
            pageSize: 10,
          ),
          hasMoreData: false, // 热门排行榜不分页
          totalCount: result.rankings.length,
          isHotRanking: true,
          hotRankingType: event.type,
          lastUpdateTime: DateTime.now(),
          favoriteFunds: state.favoriteFunds,
        ),
      ));
    } catch (e) {
      emit(state.copyWith(
        rankingState: FundRankingLoadFailure(
          error: '加载热门排行榜失败: ${e.toString()}',
        ),
      ));
    }
  }

  /// 处理加载统计信息事件
  Future<void> _onLoadRankingStatistics(
    LoadRankingStatistics event,
    Emitter<FundRankingState> emit,
  ) async {
    try {
      final statistics =
          await _getFundRankings.getRankingStatistics(event.criteria);

      final currentSuccess = state.successData;
      if (currentSuccess != null) {
        emit(state.copyWith(
          rankingState: currentSuccess.copyWith(statistics: statistics),
        ));
      }
    } catch (e) {
      // 统计信息加载失败不影响主要功能
      _showErrorSnackBar('加载统计信息失败: ${e.toString()}');
    }
  }

  /// 处理加载基金排名历史事件
  Future<void> _onLoadFundRankingHistory(
    LoadFundRankingHistory event,
    Emitter<FundRankingState> emit,
  ) async {
    final key = '${event.fundCode}_${event.period.name}';

    // 发出历史加载中状态
    final updatedHistoryStates =
        Map<String, FundRankingHistoryState>.from(state.historyStates)
          ..[key] = FundRankingHistoryState(
            fundCode: event.fundCode,
            period: event.period,
            isLoading: true,
          );

    emit(state.copyWith(historyStates: updatedHistoryStates));

    try {
      final history = await _getFundRankings.getFundRankingHistory(
        event.fundCode,
        event.period,
        days: event.days,
      );

      // 发出历史加载成功状态
      final successHistoryStates =
          Map<String, FundRankingHistoryState>.from(state.historyStates)
            ..[key] = FundRankingHistoryState(
              fundCode: event.fundCode,
              period: event.period,
              history: history,
              isLoading: false,
            );

      emit(state.copyWith(historyStates: successHistoryStates));
    } catch (e) {
      // 发出历史加载失败状态
      final errorHistoryStates =
          Map<String, FundRankingHistoryState>.from(state.historyStates)
            ..[key] = FundRankingHistoryState(
              fundCode: event.fundCode,
              period: event.period,
              isLoading: false,
              error: e.toString(),
            );

      emit(state.copyWith(historyStates: errorHistoryStates));
    }
  }

  /// 处理重置状态事件
  Future<void> _onResetRankingState(
    ResetRankingState event,
    Emitter<FundRankingState> emit,
  ) async {
    _currentCriteria = null;
    emit(FundRankingState.initial());
  }

  /// 处理切换视图模式事件
  Future<void> _onToggleRankingViewMode(
    ToggleRankingViewMode event,
    Emitter<FundRankingState> emit,
  ) async {
    final currentSuccess = state.successData;
    if (currentSuccess != null) {
      final newViewMode = currentSuccess.viewMode == RankingViewMode.card
          ? RankingViewMode.table
          : RankingViewMode.card;

      emit(state.copyWith(
        rankingState: currentSuccess.copyWith(viewMode: newViewMode),
      ));
    }
  }

  /// 处理添加收藏基金事件
  Future<void> _onAddFavoriteFund(
    AddFavoriteFund event,
    Emitter<FundRankingState> emit,
  ) async {
    final updatedFavorites = Set<String>.from(state.favoriteFunds)
      ..add(event.fundCode);

    emit(state.copyWith(favoriteFunds: updatedFavorites));

    // 可以在这里保存到本地存储
    try {
      await _repository.saveFavoriteFunds(updatedFavorites);
    } catch (e) {
      // 保存失败，回滚状态
      emit(state.copyWith(favoriteFunds: state.favoriteFunds));
      _showErrorSnackBar('收藏失败: ${e.toString()}');
    }
  }

  /// 处理移除收藏基金事件
  Future<void> _onRemoveFavoriteFund(
    RemoveFavoriteFund event,
    Emitter<FundRankingState> emit,
  ) async {
    final updatedFavorites = Set<String>.from(state.favoriteFunds)
      ..remove(event.fundCode);

    emit(state.copyWith(favoriteFunds: updatedFavorites));

    // 可以在这里保存到本地存储
    try {
      await _repository.saveFavoriteFunds(updatedFavorites);
    } catch (e) {
      // 保存失败，回滚状态
      emit(state.copyWith(favoriteFunds: state.favoriteFunds));
      _showErrorSnackBar('取消收藏失败: ${e.toString()}');
    }
  }

  /// 处理加载收藏基金排行榜事件
  Future<void> _onLoadFavoriteRankings(
    LoadFavoriteRankings event,
    Emitter<FundRankingState> emit,
  ) async {
    if (state.favoriteFunds.isEmpty) {
      emit(state.copyWith(
        rankingState: FundRankingLoadSuccess(
          rankings: const [],
          criteria: const RankingCriteria(
            rankingType: RankingType.overall,
            rankingPeriod: RankingPeriod.oneYear,
            sortBy: RankingSortBy.returnRate,
            page: 1,
            pageSize: 20,
          ),
          hasMoreData: false,
          totalCount: 0,
          lastUpdateTime: DateTime.now(),
          favoriteFunds: state.favoriteFunds,
        ),
      ));
      return;
    }

    try {
      // 发出加载中状态
      emit(state.copyWith(
        rankingState: const FundRankingLoadInProgress(),
      ));

      // 获取收藏基金的排行榜
      final result = await _repository.getFavoriteFundsRankings(
        state.favoriteFunds.toList(),
        const RankingCriteria(
          rankingType: RankingType.overall,
          rankingPeriod: RankingPeriod.oneYear,
          sortBy: RankingSortBy.returnRate,
          page: 1,
          pageSize: 20,
        ),
      );

      // 发出收藏排行榜状态
      emit(state.copyWith(
        rankingState: FundRankingLoadSuccess(
          rankings: result.rankings,
          criteria: const RankingCriteria(
            rankingType: RankingType.overall,
            rankingPeriod: RankingPeriod.oneYear,
            sortBy: RankingSortBy.returnRate,
            page: 1,
            pageSize: 20,
          ),
          hasMoreData: result.hasNextPage,
          totalCount: result.totalCount,
          lastUpdateTime: DateTime.now(),
          favoriteFunds: state.favoriteFunds,
        ),
      ));
    } catch (e) {
      emit(state.copyWith(
        rankingState: FundRankingLoadFailure(
          error: '加载收藏排行榜失败: ${e.toString()}',
        ),
      ));
    }
  }

  /// 在后台加载统计信息
  Future<void> _loadStatisticsInBackground(RankingCriteria criteria) async {
    try {
      await _getFundRankings.getRankingStatistics(criteria);
    } catch (e) {
      // 静默失败，不影响主要功能
    }
  }

  /// 判断是否为网络错误
  bool _isNetworkError(dynamic error) {
    final errorMessage = error.toString().toLowerCase();
    return errorMessage.contains('network') ||
        errorMessage.contains('connection') ||
        errorMessage.contains('timeout') ||
        errorMessage.contains('internet');
  }

  /// 判断是否为数据解析错误
  bool _isDataError(dynamic error) {
    final errorMessage = error.toString().toLowerCase();
    return errorMessage.contains('parse') ||
        errorMessage.contains('format') ||
        errorMessage.contains('json') ||
        errorMessage.contains('data');
  }

  /// 显示错误提示（通过状态管理或其他方式）
  void _showErrorSnackBar(String message) {
    // 这里可以通过回调或其他方式显示错误提示
    // 由于BLoC不应该直接依赖UI，这里只是示例
    debugPrint('Error: $message');
  }
}
