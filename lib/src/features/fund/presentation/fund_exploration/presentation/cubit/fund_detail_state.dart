part of 'fund_detail_cubit.dart';

/// 基金详情状态
class FundDetailState extends Equatable {
  final bool isLoading;
  final String? error;
  final Fund? fund;
  final List<FundNav> navHistory;
  final FundRanking? fundRanking;
  final FundManager? fundManager;
  final List<FundHolding> fundHoldings;
  final FundEstimate? fundEstimate;
  final Map<String, dynamic> riskMetrics;

  const FundDetailState({
    this.isLoading = false,
    this.error,
    this.fund,
    this.navHistory = const [],
    this.fundRanking,
    this.fundManager,
    this.fundHoldings = const [],
    this.fundEstimate,
    this.riskMetrics = const {},
  });

  FundDetailState copyWith({
    bool? isLoading,
    String? error,
    Fund? fund,
    List<FundNav>? navHistory,
    FundRanking? fundRanking,
    FundManager? fundManager,
    List<FundHolding>? fundHoldings,
    FundEstimate? fundEstimate,
    Map<String, dynamic>? riskMetrics,
  }) {
    return FundDetailState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      fund: fund ?? this.fund,
      navHistory: navHistory ?? this.navHistory,
      fundRanking: fundRanking ?? this.fundRanking,
      fundManager: fundManager ?? this.fundManager,
      fundHoldings: fundHoldings ?? this.fundHoldings,
      fundEstimate: fundEstimate ?? this.fundEstimate,
      riskMetrics: riskMetrics ?? this.riskMetrics,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        error,
        fund,
        navHistory,
        fundRanking,
        fundManager,
        fundHoldings,
        fundEstimate,
        riskMetrics,
      ];
}

/// 基金净值数据
class FundNav extends Equatable {
  final String fundCode;
  final String navDate;
  final double unitNav;
  final double? accumulatedNav;
  final double? dailyReturn;
  final double? totalNetAssets;
  final String? subscriptionStatus;
  final String? redemptionStatus;

  const FundNav({
    required this.fundCode,
    required this.navDate,
    required this.unitNav,
    this.accumulatedNav,
    this.dailyReturn,
    this.totalNetAssets,
    this.subscriptionStatus,
    this.redemptionStatus,
  });

  @override
  List<Object?> get props => [
        fundCode,
        navDate,
        unitNav,
        accumulatedNav,
        dailyReturn,
        totalNetAssets,
        subscriptionStatus,
        redemptionStatus,
      ];
}

/// 基金估值数据
class FundEstimate extends Equatable {
  final String fundCode;
  final double? estimateValue;
  final double? estimateReturn;
  final String? estimateTime;
  final double? previousNav;
  final String? previousNavDate;

  const FundEstimate({
    required this.fundCode,
    this.estimateValue,
    this.estimateReturn,
    this.estimateTime,
    this.previousNav,
    this.previousNavDate,
  });

  @override
  List<Object?> get props => [
        fundCode,
        estimateValue,
        estimateReturn,
        estimateTime,
        previousNav,
        previousNavDate,
      ];
}
