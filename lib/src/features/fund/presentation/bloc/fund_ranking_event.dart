part of 'fund_ranking_bloc.dart';

/// 基金排行榜事件基类
abstract class FundRankingEvent extends Equatable {
  const FundRankingEvent();

  @override
  List<Object?> get props => [];
}

/// 加载基金排行榜事件
class LoadFundRankings extends FundRankingEvent {
  /// 排行榜查询条件
  final RankingCriteria criteria;

  /// 是否强制刷新缓存
  final bool forceRefresh;

  const LoadFundRankings({
    required this.criteria,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [criteria, forceRefresh];

  @override
  String toString() =>
      'LoadFundRankings{criteria: $criteria, forceRefresh: $forceRefresh}';
}

/// 刷新基金排行榜事件
class RefreshFundRankings extends FundRankingEvent {
  /// 当前查询条件
  final RankingCriteria? currentCriteria;

  const RefreshFundRankings([this.currentCriteria]);

  @override
  List<Object?> get props => [currentCriteria];

  @override
  String toString() => 'RefreshFundRankings{currentCriteria: $currentCriteria}';
}

/// 更改排行榜类型事件
class ChangeRankingType extends FundRankingEvent {
  /// 新的排行榜类型
  final RankingType rankingType;

  /// 保持当前时间段
  final RankingPeriod? currentPeriod;

  const ChangeRankingType({
    required this.rankingType,
    this.currentPeriod,
  });

  @override
  List<Object?> get props => [rankingType, currentPeriod];

  @override
  String toString() =>
      'ChangeRankingType{rankingType: $rankingType, currentPeriod: $currentPeriod}';
}

/// 更改排行榜时间段事件
class ChangeRankingPeriod extends FundRankingEvent {
  /// 新的时间段
  final RankingPeriod rankingPeriod;

  /// 保持当前排行榜类型
  final RankingType? currentType;

  const ChangeRankingPeriod({
    required this.rankingPeriod,
    this.currentType,
  });

  @override
  List<Object?> get props => [rankingPeriod, currentType];

  @override
  String toString() =>
      'ChangeRankingPeriod{rankingPeriod: $rankingPeriod, currentType: $currentType}';
}

/// 更改基金类型筛选事件
class ChangeFundTypeFilter extends FundRankingEvent {
  /// 基金类型
  final String? fundType;

  const ChangeFundTypeFilter(this.fundType);

  @override
  List<Object?> get props => [fundType];

  @override
  String toString() => 'ChangeFundTypeFilter{fundType: $fundType}';
}

/// 更改基金公司筛选事件
class ChangeFundCompanyFilter extends FundRankingEvent {
  /// 基金公司
  final String? company;

  const ChangeFundCompanyFilter(this.company);

  @override
  List<Object?> get props => [company];

  @override
  String toString() => 'ChangeFundCompanyFilter{company: $company}';
}

/// 更改排序方式事件
class ChangeSortBy extends FundRankingEvent {
  /// 排序方式
  final RankingSortBy sortBy;

  const ChangeSortBy(this.sortBy);

  @override
  List<Object?> get props => [sortBy];

  @override
  String toString() => 'ChangeSortBy{sortBy: $sortBy}';
}

/// 加载更多排行榜数据事件
class LoadMoreRankings extends FundRankingEvent {
  const LoadMoreRankings();

  @override
  String toString() => 'LoadMoreRankings';
}

/// 搜索排行榜事件
class SearchRankings extends FundRankingEvent {
  /// 搜索关键词
  final String query;

  /// 基础查询条件
  final RankingCriteria? baseCriteria;

  const SearchRankings({
    required this.query,
    this.baseCriteria,
  });

  @override
  List<Object?> get props => [query, baseCriteria];

  @override
  String toString() =>
      'SearchRankings{query: $query, baseCriteria: $baseCriteria}';
}

/// 清除搜索事件
class ClearSearchRankings extends FundRankingEvent {
  const ClearSearchRankings();

  @override
  String toString() => 'ClearSearchRankings';
}

/// 加载热门排行榜事件
class LoadHotRankings extends FundRankingEvent {
  /// 热门排行榜类型
  final HotRankingType type;

  /// 自定义页面大小
  final int? pageSize;

  const LoadHotRankings({
    required this.type,
    this.pageSize,
  });

  @override
  List<Object?> get props => [type, pageSize];

  @override
  String toString() => 'LoadHotRankings{type: $type, pageSize: $pageSize}';
}

/// 获取排行榜统计信息事件
class LoadRankingStatistics extends FundRankingEvent {
  /// 查询条件
  final RankingCriteria criteria;

  const LoadRankingStatistics(this.criteria);

  @override
  List<Object?> get props => [criteria];

  @override
  String toString() => 'LoadRankingStatistics{criteria: $criteria}';
}

/// 获取基金排名历史事件
class LoadFundRankingHistory extends FundRankingEvent {
  /// 基金代码
  final String fundCode;

  /// 时间段
  final RankingPeriod period;

  /// 获取天数
  final int days;

  const LoadFundRankingHistory({
    required this.fundCode,
    required this.period,
    this.days = 30,
  });

  @override
  List<Object?> get props => [fundCode, period, days];

  @override
  String toString() =>
      'LoadFundRankingHistory{fundCode: $fundCode, period: $period, days: $days}';
}

/// 重置排行榜状态事件
class ResetRankingState extends FundRankingEvent {
  const ResetRankingState();

  @override
  String toString() => 'ResetRankingState';
}

/// 切换排行榜视图模式事件
class ToggleRankingViewMode extends FundRankingEvent {
  const ToggleRankingViewMode();

  @override
  String toString() => 'ToggleRankingViewMode';
}

/// 添加收藏基金事件
class AddFavoriteFund extends FundRankingEvent {
  /// 基金代码
  final String fundCode;

  const AddFavoriteFund(this.fundCode);

  @override
  List<Object?> get props => [fundCode];

  @override
  String toString() => 'AddFavoriteFund{fundCode: $fundCode}';
}

/// 移除收藏基金事件
class RemoveFavoriteFund extends FundRankingEvent {
  /// 基金代码
  final String fundCode;

  const RemoveFavoriteFund(this.fundCode);

  @override
  List<Object?> get props => [fundCode];

  @override
  String toString() => 'RemoveFavoriteFund{fundCode: $fundCode}';
}

/// 加载收藏基金排行榜事件
class LoadFavoriteRankings extends FundRankingEvent {
  const LoadFavoriteRankings();

  @override
  String toString() => 'LoadFavoriteRankings';
}
