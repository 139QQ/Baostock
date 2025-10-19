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
  FundRankingBloc? _fundRankingBloc;
  bool _isInitialized = false;

  FundRankingCubit() : super(FundRankingState.initial()) {
    // 延迟初始化，避免在构造函数中直接调用依赖注入
    _initializeDelayed();
  }

  /// 延迟初始化，确保依赖注入容器已准备好
  Future<void> _initializeDelayed() async {
    try {
      // 等待更长时间，确保依赖注入容器已初始化
      await Future.delayed(const Duration(milliseconds: 100));

      // 检查Cubit是否已关闭
      if (isClosed) {
        return;
      }

      if (di.sl.isRegistered<FundRankingBloc>()) {
        _fundRankingBloc = di.sl<FundRankingBloc>();

        // 监听Bloc状态变化
        _fundRankingBloc!.stream.listen((newState) {
          if (!isClosed) {
            emit(newState);
          }
        });

        _isInitialized = true;

        // 初始化数据
        if (!isClosed && _fundRankingBloc != null) {
          _fundRankingBloc!.add(LoadFundRankings(
            criteria: RankingCriteria(
              rankingType: RankingType.overall,
              rankingPeriod: RankingPeriod.oneYear,
              sortBy: RankingSortBy.returnRate,
            ),
          ));
        }
      } else {
        // 如果依赖注入还未准备好，发出初始状态而不是错误状态
        if (!isClosed) {
          emit(FundRankingState(
            rankingState: const FundRankingInitial(),
          ));
        }
      }
    } catch (e) {
      // 发出错误状态前检查Cubit是否已关闭
      if (!isClosed) {
        emit(FundRankingState(
          rankingState: FundRankingLoadFailure(
            error: '初始化失败: $e',
          ),
        ));
      }
    }
  }

  /// 加载基金排行数据
  void loadRankings({
    RankingSortBy? sortBy,
    RankingType? rankingType,
    RankingPeriod? rankingPeriod,
    String? fundType,
    String? company,
  }) {
    if (_fundRankingBloc == null || !_isInitialized) {
      emit(FundRankingState(
        rankingState: const FundRankingLoadFailure(
          error: '组件未初始化',
        ),
      ));
      return;
    }

    final criteria = RankingCriteria(
      rankingType: rankingType ?? RankingType.overall,
      rankingPeriod: rankingPeriod ?? RankingPeriod.oneYear,
      sortBy: sortBy ?? RankingSortBy.returnRate,
      fundType: fundType,
      company: company,
    );

    _fundRankingBloc!.add(LoadFundRankings(criteria: criteria));
  }

  /// 初始化数据
  Future<void> initialize() async {
    if (!_isInitialized) {
      await _initializeDelayed();
    }

    if (_fundRankingBloc != null && _isInitialized) {
      _fundRankingBloc!.add(LoadFundRankings(
        criteria: RankingCriteria(
          rankingType: RankingType.overall,
          rankingPeriod: RankingPeriod.oneYear,
          sortBy: RankingSortBy.returnRate,
        ),
      ));
    }
  }

  /// 刷新数据
  void refreshRankings() {
    // 检查Cubit是否已关闭
    if (isClosed) {
      return;
    }

    if (_fundRankingBloc != null && _isInitialized) {
      _fundRankingBloc!.add(const RefreshFundRankings());
    } else {
      // 尝试重新初始化
      _initializeDelayed().then((_) {
        if (!isClosed && _fundRankingBloc != null && _isInitialized) {
          _fundRankingBloc!.add(const RefreshFundRankings());
        }
      });
    }
  }

  /// 搜索基金
  void searchFunds(String query) {
    if (_fundRankingBloc != null && _isInitialized) {
      if (query.isNotEmpty) {
        _fundRankingBloc!.add(SearchRankings(query: query));
      } else {
        _fundRankingBloc!.add(const ClearSearchRankings());
      }
    }
  }

  /// 加载更多数据
  void loadMoreRankings() {
    if (_fundRankingBloc != null && _isInitialized) {
      _fundRankingBloc!.add(const LoadMoreRankings());
    }
  }

  /// 添加收藏基金
  void addFavorite(String fundCode) {
    if (_fundRankingBloc != null && _isInitialized) {
      _fundRankingBloc!.add(AddFavoriteFund(fundCode));
    }
  }

  /// 移除收藏基金
  void removeFavorite(String fundCode) {
    if (_fundRankingBloc != null && _isInitialized) {
      _fundRankingBloc!.add(RemoveFavoriteFund(fundCode));
    }
  }

  /// 应用筛选条件
  void applyFilters({
    String? fundType,
    String? company,
    RankingSortBy? sortBy,
    RankingType? rankingType,
    RankingPeriod? rankingPeriod,
  }) {
    if (_fundRankingBloc != null && _isInitialized) {
      if (fundType != null) {
        _fundRankingBloc!.add(ChangeFundTypeFilter(fundType));
      }

      if (company != null) {
        _fundRankingBloc!.add(ChangeFundCompanyFilter(company));
      }

      if (sortBy != null) {
        _fundRankingBloc!.add(ChangeSortBy(sortBy));
      }
    }
  }

  /// 清除错误
  void clearError() {
    if (_fundRankingBloc != null && _isInitialized) {
      _fundRankingBloc!.add(const ResetRankingState());
    }
  }

  /// 强制重新加载数据
  void forceReload() {
    // 检查Cubit是否已关闭
    if (isClosed) {
      return;
    }

    if (_fundRankingBloc != null && _isInitialized) {
      _fundRankingBloc!.add(const RefreshFundRankings());
    } else {
      // 尝试重新初始化并强制刷新
      _isInitialized = false;
      _initializeDelayed().then((_) {
        if (!isClosed && _fundRankingBloc != null && _isInitialized) {
          _fundRankingBloc!.add(const RefreshFundRankings());
        }
      });
    }
  }

  /// 检查是否已关闭
  bool get isClosed => _fundRankingBloc?.isClosed ?? true;

  @override
  Future<void> close() async {
    _fundRankingBloc?.close();
    return super.close();
  }
}
