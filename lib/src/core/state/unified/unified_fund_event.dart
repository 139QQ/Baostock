part of 'unified_fund_cubit.dart';

/// 统一基金事件基类
abstract class UnifiedFundEvent extends Equatable {
  const UnifiedFundEvent();

  @override
  List<Object?> get props => [];
}

/// 加载基金列表事件
class LoadFundList extends UnifiedFundEvent {
  final bool loadRankings;

  const LoadFundList({this.loadRankings = false});

  @override
  List<Object?> get props => [loadRankings];
}

/// 加载基金排名事件
class LoadFundRankings extends UnifiedFundEvent {
  final String? symbol;

  const LoadFundRankings({this.symbol});

  @override
  List<Object?> get props => [symbol];
}

/// 智能加载基金排名事件
class LoadFundRankingsSmart extends UnifiedFundEvent {
  const LoadFundRankingsSmart();
}

/// 刷新基金排名缓存事件
class RefreshFundRankingsCache extends UnifiedFundEvent {
  const RefreshFundRankingsCache();
}

/// 更新基金净值数据事件
class UpdateFundNavData extends UnifiedFundEvent {
  final String fundCode;
  final FundNavData navData;

  const UpdateFundNavData({
    required this.fundCode,
    required this.navData,
  });

  @override
  List<Object?> get props => [fundCode, navData];
}

/// 加载基金净值数据事件
class LoadFundNavData extends UnifiedFundEvent {
  final List<String> fundCodes;

  const LoadFundNavData(this.fundCodes);

  @override
  List<Object?> get props => [fundCodes];
}

/// 开始实时监控事件
class StartRealtimeMonitoring extends UnifiedFundEvent {
  const StartRealtimeMonitoring();
}

/// 停止实时监控事件
class StopRealtimeMonitoring extends UnifiedFundEvent {
  const StopRealtimeMonitoring();
}

/// 更新用户偏好事件
class UpdateUserPreferences extends UnifiedFundEvent {
  final Map<String, dynamic> preferences;

  const UpdateUserPreferences(this.preferences);

  @override
  List<Object?> get props => [preferences];
}
