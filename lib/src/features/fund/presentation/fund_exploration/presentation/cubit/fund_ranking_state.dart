part of 'fund_ranking_cubit.dart';

/// 基金排行状态
enum FundRankingStatus {
  /// 初始状态
  initial,

  /// 加载中
  loading,

  /// 加载完成
  loaded,

  /// 加载失败
  error,
}

/// 基金排行数据状态
class FundRankingState extends Equatable {
  /// 当前状态
  final FundRankingStatus status;

  /// 基金排行数据列表
  final List<FundRanking> rankings;

  /// 选中的时间段
  final String selectedPeriod;

  /// 排序方式
  final String sortBy;

  /// 错误信息
  final String? errorMessage;

  /// 是否存在数据质量问题
  final bool hasDataQualityIssues;

  /// 最后更新时间
  final DateTime? lastUpdated;

  FundRankingState({
    this.status = FundRankingStatus.initial,
    this.rankings = const [],
    this.selectedPeriod = '近1年',
    this.sortBy = '收益率',
    this.errorMessage,
    this.hasDataQualityIssues = false,
    this.lastUpdated,
  });

  /// 创建状态副本
  FundRankingState copyWith({
    FundRankingStatus? status,
    List<FundRanking>? rankings,
    String? selectedPeriod,
    String? sortBy,
    String? errorMessage,
    bool? hasDataQualityIssues,
    DateTime? lastUpdated,
  }) {
    return FundRankingState(
      status: status ?? this.status,
      rankings: rankings ?? this.rankings,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      sortBy: sortBy ?? this.sortBy,
      errorMessage: errorMessage ?? this.errorMessage,
      hasDataQualityIssues: hasDataQualityIssues ?? this.hasDataQualityIssues,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  /// 是否为加载状态
  bool get isLoading => status == FundRankingStatus.loading;

  /// 是否为加载完成状态
  bool get isLoaded => status == FundRankingStatus.loaded;

  /// 是否为错误状态
  bool get hasError => status == FundRankingStatus.error;

  /// 是否有数据
  bool get hasData => rankings.isNotEmpty;

  /// 是否为空状态
  bool get isEmpty => rankings.isEmpty && isLoaded;

  @override
  List<Object?> get props => [
        status,
        rankings,
        selectedPeriod,
        sortBy,
        errorMessage,
        hasDataQualityIssues,
        lastUpdated,
      ];

  @override
  String toString() {
    return 'FundRankingState('
        'status: $status, '
        'rankingsCount: ${rankings.length}, '
        'selectedPeriod: $selectedPeriod, '
        'sortBy: $sortBy, '
        'errorMessage: $errorMessage, '
        'hasDataQualityIssues: $hasDataQualityIssues, '
        'lastUpdated: $lastUpdated'
        ')';
  }
}
