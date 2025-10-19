import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/fund_ranking_bloc.dart';
import '../../../../domain/entities/fund_ranking.dart';
import '../../../../../../core/di/injection_container.dart' as di;

/// 基金排行Cubit适配器
///
/// 作为Bloc模式的适配器，提供简化的Cubit接口
/// 主要用于向后兼容和简化状态管理
class FundRankingCubit extends Cubit<FundRankingState> {
  late final FundRankingBloc _fundRankingBloc;
  FundRankingCubit() : super(FundRankingState.initial()) {
    // 使用依赖注入容器获取FundRankingBloc实例
    _fundRankingBloc = di.sl<FundRankingBloc>();

    // 监听Bloc状态变化
    _fundRankingBloc.stream.listen((newState) {
      if (!isClosed) {
        emit(newState);
      }
    });

    // 初始化数据
    _fundRankingBloc.add(LoadFundRankings(
      criteria: RankingCriteria(
        rankingType: RankingType.overall,
        rankingPeriod: RankingPeriod.oneYear,
        sortBy: RankingSortBy.returnRate,
      ),
    ));
  }

  /// 加载基金排行数据
  void loadRankings({
    RankingSortBy? sortBy,
    RankingType? rankingType,
    RankingPeriod? rankingPeriod,
    String? fundType,
    String? company,
  }) {
    final criteria = RankingCriteria(
      rankingType: rankingType ?? RankingType.overall,
      rankingPeriod: rankingPeriod ?? RankingPeriod.oneYear,
      sortBy: sortBy ?? RankingSortBy.returnRate,
      fundType: fundType,
      company: company,
    );

    _fundRankingBloc.add(LoadFundRankings(criteria: criteria));
  }

  /// 初始化数据
  Future<void> initialize() async {
    // 初始化数据加载
    _fundRankingBloc.add(LoadFundRankings(
      criteria: RankingCriteria(
        rankingType: RankingType.overall,
        rankingPeriod: RankingPeriod.oneYear,
        sortBy: RankingSortBy.returnRate,
      ),
    ));
  }

  /// 刷新数据
  void refreshRankings() {
    _fundRankingBloc.add(const RefreshFundRankings());
  }

  /// 搜索基金
  void searchFunds(String query) {
    if (query.isNotEmpty) {
      _fundRankingBloc.add(SearchRankings(query: query));
    } else {
      _fundRankingBloc.add(const ClearSearchRankings());
    }
  }

  /// 加载更多数据
  void loadMoreRankings() {
    _fundRankingBloc.add(const LoadMoreRankings());
  }

  /// 添加收藏基金
  void addFavorite(String fundCode) {
    _fundRankingBloc.add(AddFavoriteFund(fundCode));
  }

  /// 移除收藏基金
  void removeFavorite(String fundCode) {
    _fundRankingBloc.add(RemoveFavoriteFund(fundCode));
  }

  /// 应用筛选条件
  void applyFilters({
    String? fundType,
    String? company,
    RankingSortBy? sortBy,
    RankingType? rankingType,
    RankingPeriod? rankingPeriod,
  }) {
    if (fundType != null) {
      _fundRankingBloc.add(ChangeFundTypeFilter(fundType));
    }

    if (company != null) {
      _fundRankingBloc.add(ChangeFundCompanyFilter(company));
    }

    if (sortBy != null) {
      _fundRankingBloc.add(ChangeSortBy(sortBy));
    }
  }

  /// 清除错误
  void clearError() {
    _fundRankingBloc.add(const ResetRankingState());
  }

  /// 强制重新加载数据
  void forceReload() {
    _fundRankingBloc.add(const RefreshFundRankings());
  }

  /// 检查是否已关闭
  bool get isClosed => _fundRankingBloc.isClosed;

  @override
  Future<void> close() async {
    _fundRankingBloc.close();
    return super.close();
  }
}
