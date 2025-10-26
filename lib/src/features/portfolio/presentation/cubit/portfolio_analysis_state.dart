import '../../domain/entities/portfolio_holding.dart';
import '../../domain/entities/portfolio_profit_metrics.dart';
import '../../domain/entities/portfolio_summary.dart';
import '../../domain/entities/portfolio_profit_calculation_criteria.dart';

/// 组合分析状态
class PortfolioAnalysisState {
  final List<PortfolioHolding> holdings;
  final PortfolioSummary? portfolioSummary;
  final Map<String, PortfolioProfitMetrics> fundMetrics;
  final PortfolioProfitCalculationCriteria currentCriteria;
  final bool isCalculating;
  final double calculationProgress;
  final DateTime lastUpdated;
  final String? error;
  final bool isLoading;
  final bool hasBeenInitialized;

  const PortfolioAnalysisState({
    this.holdings = const [],
    this.portfolioSummary,
    this.fundMetrics = const {},
    required this.currentCriteria,
    this.isCalculating = false,
    this.calculationProgress = 0.0,
    required this.lastUpdated,
    this.error,
    this.isLoading = false,
    this.hasBeenInitialized = false,
  });

  /// 初始状态
  factory PortfolioAnalysisState.initial() {
    final now = DateTime.now();
    return PortfolioAnalysisState(
      currentCriteria: PortfolioProfitCalculationCriteria.basic(),
      lastUpdated: now,
      hasBeenInitialized: false,
    );
  }

  /// 加载状态
  factory PortfolioAnalysisState.loading() {
    final now = DateTime.now();
    return PortfolioAnalysisState(
      currentCriteria: PortfolioProfitCalculationCriteria.basic(),
      lastUpdated: now,
      isLoading: true,
      hasBeenInitialized: false,
    );
  }

  /// 已加载状态
  factory PortfolioAnalysisState.loaded({
    required List<PortfolioHolding> holdings,
    PortfolioSummary? portfolioSummary,
    Map<String, PortfolioProfitMetrics> fundMetrics = const {},
    required PortfolioProfitCalculationCriteria currentCriteria,
    bool isCalculating = false,
  }) {
    final now = DateTime.now();
    return PortfolioAnalysisState(
      holdings: holdings,
      portfolioSummary: portfolioSummary,
      fundMetrics: fundMetrics,
      currentCriteria: currentCriteria,
      isCalculating: isCalculating,
      calculationProgress: isCalculating ? 0.0 : 1.0,
      lastUpdated: now,
      isLoading: false,
      hasBeenInitialized: true,
    );
  }

  /// 错误状态
  factory PortfolioAnalysisState.error(String error) {
    final now = DateTime.now();
    return PortfolioAnalysisState(
      currentCriteria: PortfolioProfitCalculationCriteria.basic(),
      lastUpdated: now,
      error: error,
      isLoading: false,
      hasBeenInitialized: true,
    );
  }

  /// 无数据状态
  factory PortfolioAnalysisState.noData() {
    final now = DateTime.now();
    return PortfolioAnalysisState(
      currentCriteria: PortfolioProfitCalculationCriteria.basic(),
      lastUpdated: now,
      holdings: [],
      fundMetrics: {},
      isLoading: false,
      hasBeenInitialized: true,
    );
  }

  /// 复制并更新状态
  PortfolioAnalysisState copyWith({
    List<PortfolioHolding>? holdings,
    PortfolioSummary? portfolioSummary,
    Map<String, PortfolioProfitMetrics>? fundMetrics,
    PortfolioProfitCalculationCriteria? currentCriteria,
    bool? isCalculating,
    double? calculationProgress,
    DateTime? lastUpdated,
    String? error,
    bool? isLoading,
    bool? hasBeenInitialized,
  }) {
    return PortfolioAnalysisState(
      holdings: holdings ?? this.holdings,
      portfolioSummary: portfolioSummary ?? this.portfolioSummary,
      fundMetrics: fundMetrics ?? this.fundMetrics,
      currentCriteria: currentCriteria ?? this.currentCriteria,
      isCalculating: isCalculating ?? this.isCalculating,
      calculationProgress: calculationProgress ?? this.calculationProgress,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      error: error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
      hasBeenInitialized: hasBeenInitialized ?? this.hasBeenInitialized,
    );
  }

  /// 检查是否为初始状态
  bool get isInitial =>
      !hasBeenInitialized &&
      holdings.isEmpty &&
      portfolioSummary == null &&
      !isLoading;

  /// 检查是否有数据
  bool get hasData => holdings.isNotEmpty || portfolioSummary != null;

  /// 检查是否为错误状态
  bool get hasError => error != null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PortfolioAnalysisState &&
        other.holdings == holdings &&
        other.portfolioSummary == portfolioSummary &&
        other.fundMetrics == fundMetrics &&
        other.currentCriteria == currentCriteria &&
        other.isCalculating == isCalculating &&
        other.calculationProgress == calculationProgress &&
        other.lastUpdated == lastUpdated &&
        other.error == error &&
        other.isLoading == isLoading;
  }

  @override
  int get hashCode {
    return holdings.hashCode ^
        portfolioSummary.hashCode ^
        fundMetrics.hashCode ^
        currentCriteria.hashCode ^
        isCalculating.hashCode ^
        calculationProgress.hashCode ^
        lastUpdated.hashCode ^
        error.hashCode ^
        isLoading.hashCode;
  }

  /// 优化的可能性映射方法 - 提高状态判断效率
  T maybeMap<T>({
    required T Function() orElse,
    T Function(PortfolioAnalysisState state)? initial,
    T Function(PortfolioAnalysisState state)? loading,
    T Function(PortfolioAnalysisState state)? loaded,
    T Function(PortfolioAnalysisState state)? error,
    T Function(PortfolioAnalysisState state)? noData,
  }) {
    // 优化：使用更高效的状态判断顺序
    if (hasError && error != null) {
      return error(this);
    } else if (isLoading && loading != null) {
      return loading(this);
    } else if (isInitial && initial != null) {
      return initial(this);
    } else if (hasData && loaded != null) {
      return loaded(this);
    } else if (!hasData && !isLoading && noData != null) {
      return noData(this);
    } else {
      return orElse();
    }
  }

  /// 条件映射方法 - 必须处理所有状态情况
  T when<T>({
    required T Function(PortfolioAnalysisState state) initial,
    required T Function(PortfolioAnalysisState state) loading,
    required T Function(PortfolioAnalysisState state) loaded,
    required T Function(PortfolioAnalysisState state) error,
    required T Function(PortfolioAnalysisState state) noData,
  }) {
    if (isInitial) {
      return initial(this);
    } else if (hasError) {
      // 错误状态优先级高于加载状态
      return error(this);
    } else if (isLoading) {
      return loading(this);
    } else if (hasData) {
      return loaded(this);
    } else {
      return noData(this);
    }
  }

  @override
  String toString() {
    return 'PortfolioAnalysisState('
        'holdings: ${holdings.length}, '
        'portfolioSummary: $portfolioSummary, '
        'fundMetrics: ${fundMetrics.length}, '
        'isCalculating: $isCalculating, '
        'error: $error, '
        'isLoading: $isLoading'
        ')';
  }
}
