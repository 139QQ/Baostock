part of 'fund_bloc.dart';

abstract class FundEvent {
  FundEvent();

  List<Object> get props => [];
}

/// 加载基金列表事件
class LoadFundList extends FundEvent {
  /// 可选参数：是否强制刷新（忽略缓存）
  final bool forceRefresh;

  LoadFundList({this.forceRefresh = false});

  @override
  List<Object> get props => [forceRefresh];
}

/// 加载基金排名事件
class LoadFundRankings extends FundEvent {
  /// 基金类型
  final String symbol;

  /// 验证symbol有效性的静态方法
  static bool isValidSymbol(String symbol) {
    final allowedSymbols = {"全部", "股票型", "混合型", "债券型", "指数型", "QDII", "FOF"};
    return allowedSymbols.contains(symbol);
  }

  /// 工厂构造函数，包含验证逻辑
  factory LoadFundRankings({required String symbol}) {
    if (!isValidSymbol(symbol)) {
      throw ArgumentError('无效的基金类型，请使用允许的值：全部、股票型、混合型、债券型、指数型、QDII、FOF');
    }
    return LoadFundRankings._(symbol: symbol);
  }

  /// 私有构造函数
  LoadFundRankings._({
    required this.symbol,
  });

  @override
  List<Object> get props => [symbol];
}

/// 智能按需加载基金排名事件
class LoadFundRankingsSmart extends FundEvent {
  /// 基金类型
  final String symbol;

  /// 是否使用缓存优先策略
  final bool cacheFirst;

  /// 是否后台静默更新
  final bool backgroundRefresh;

  /// 工厂构造函数，包含验证逻辑
  factory LoadFundRankingsSmart({
    required String symbol,
    bool cacheFirst = true,
    bool backgroundRefresh = true,
  }) {
    if (!LoadFundRankings.isValidSymbol(symbol)) {
      throw ArgumentError('无效的基金类型');
    }
    return LoadFundRankingsSmart._(
      symbol: symbol,
      cacheFirst: cacheFirst,
      backgroundRefresh: backgroundRefresh,
    );
  }

  /// 私有构造函数
  LoadFundRankingsSmart._({
    required this.symbol,
    required this.cacheFirst,
    required this.backgroundRefresh,
  });

  @override
  List<Object> get props => [symbol, cacheFirst, backgroundRefresh];
}

/// 刷新基金排名缓存事件
class RefreshFundRankingsCache extends FundEvent {
  /// 基金类型
  final String symbol;

  /// 是否静默刷新（不显示加载状态）
  final bool silentRefresh;

  /// 工厂构造函数，包含验证逻辑
  factory RefreshFundRankingsCache({
    required String symbol,
    bool silentRefresh = true,
  }) {
    if (!LoadFundRankings.isValidSymbol(symbol)) {
      throw ArgumentError('无效的基金类型');
    }
    return RefreshFundRankingsCache._(
      symbol: symbol,
      silentRefresh: silentRefresh,
    );
  }

  /// 私有构造函数
  RefreshFundRankingsCache._({
    required this.symbol,
    required this.silentRefresh,
  });

  @override
  List<Object> get props => [symbol, silentRefresh];
}
