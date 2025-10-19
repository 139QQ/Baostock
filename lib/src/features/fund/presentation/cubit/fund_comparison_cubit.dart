import 'dart:math';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/multi_dimensional_comparison_criteria.dart';
import '../../domain/entities/comparison_result.dart';
import '../../domain/entities/fund_ranking.dart';
import '../../domain/repositories/fund_comparison_repository.dart';
import '../../../../core/utils/logger.dart';

/// 基金对比状态
enum FundComparisonStatus {
  initial,
  loading,
  loaded,
  error,
}

/// 基金对比状态类
class FundComparisonState extends Equatable {
  const FundComparisonState({
    this.status = FundComparisonStatus.initial,
    this.result,
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  final FundComparisonStatus status;
  final ComparisonResult? result;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  FundComparisonState copyWith({
    FundComparisonStatus? status,
    ComparisonResult? result,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return FundComparisonState(
      status: status ?? this.status,
      result: result ?? this.result,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
        status,
        result,
        isLoading,
        error,
        lastUpdated,
      ];
}

/// 基金对比Cubit
class FundComparisonCubit extends Cubit<FundComparisonState> {
  static const String _tag = 'FundComparisonCubit';

  final FundComparisonRepository _repository;

  FundComparisonCubit({
    required FundComparisonRepository repository,
  })  : _repository = repository,
        super(const FundComparisonState()) {
    AppLogger.info(_tag, 'FundComparisonCubit initialized');
  }

  /// 加载对比数据
  Future<void> loadComparison(
    MultiDimensionalComparisonCriteria criteria, {
    bool forceRefresh = false,
  }) async {
    try {
      AppLogger.info(_tag, 'Loading comparison data: ${criteria.fundCodes}');

      emit(state.copyWith(
        status: FundComparisonStatus.loading,
        isLoading: true,
        error: null,
      ));

      final result = await _repository.getMultiDimensionalComparison(
        criteria,
        forceRefresh: forceRefresh,
      );

      if (result.hasError) {
        emit(state.copyWith(
          status: FundComparisonStatus.error,
          error: result.errorMessage,
          isLoading: false,
          lastUpdated: DateTime.now(),
        ));
        AppLogger.error(_tag, 'Comparison load failed: ${result.errorMessage}');
      } else {
        emit(state.copyWith(
          status: FundComparisonStatus.loaded,
          result: result,
          isLoading: false,
          error: null,
          lastUpdated: DateTime.now(),
        ));
        AppLogger.info(_tag, 'Comparison loaded successfully');
      }
    } catch (e) {
      emit(state.copyWith(
        status: FundComparisonStatus.error,
        error: e.toString(),
        isLoading: false,
        lastUpdated: DateTime.now(),
      ));
      AppLogger.error(_tag, 'Failed to load comparison: $e');
    }
  }

  /// 重新加载当前对比
  Future<void> refreshComparison() async {
    if (state.result != null) {
      await loadComparison(
        state.result!.criteria,
        forceRefresh: true,
      );
    }
  }

  /// 清理状态
  void clear() {
    emit(const FundComparisonState());
    AppLogger.info(_tag, 'Comparison state cleared');
  }

  /// 更新对比条件
  void updateCriteria(MultiDimensionalComparisonCriteria criteria) {
    if (state.result != null && criteria != state.result!.criteria) {
      loadComparison(criteria);
    }
  }

  /// 获取最佳表现基金
  FundComparisonData? getBestPerformingFund({
    ComparisonMetric metric = ComparisonMetric.totalReturn,
  }) {
    return state.result?.getBestPerformingFund(metric: metric);
  }

  /// 获取最差表现基金
  FundComparisonData? getWorstPerformingFund({
    ComparisonMetric metric = ComparisonMetric.totalReturn,
  }) {
    return state.result?.getWorstPerformingFund(metric: metric);
  }

  /// 获取指定基金的对比数据
  List<FundComparisonData> getFundData(String fundCode) {
    if (state.result == null) return [];
    return state.result!.fundData
        .where((data) => data.fundCode == fundCode)
        .toList();
  }

  /// 获取指定时间段的对比数据
  List<FundComparisonData> getPeriodData(RankingPeriod period) {
    if (state.result == null) return [];
    return state.result!.getPeriodData(period);
  }

  /// 检查是否有数据
  bool get hasData => state.result != null && !state.result!.fundData.isEmpty;

  /// 检查是否有错误
  bool get hasError => state.status == FundComparisonStatus.error;

  /// 检查是否正在加载
  bool get isLoading => state.isLoading;

  /// 获取统计信息
  ComparisonStatistics? get statistics => state.result?.statistics;

  /// 获取对比条件
  MultiDimensionalComparisonCriteria? get criteria => state.result?.criteria;

  /// 获取最后更新时间
  DateTime? get lastUpdated => state.lastUpdated;

  /// 计算收益排名
  List<FundComparisonData> getRankedFunds({
    ComparisonMetric metric = ComparisonMetric.totalReturn,
    bool ascending = false,
  }) {
    if (state.result == null) return [];

    final data = List<FundComparisonData>.from(state.result!.fundData);

    switch (metric) {
      case ComparisonMetric.totalReturn:
        data.sort((a, b) => ascending
            ? a.totalReturn.compareTo(b.totalReturn)
            : b.totalReturn.compareTo(a.totalReturn));
        break;
      case ComparisonMetric.annualizedReturn:
        data.sort((a, b) => ascending
            ? a.annualizedReturn.compareTo(b.annualizedReturn)
            : b.annualizedReturn.compareTo(a.annualizedReturn));
        break;
      case ComparisonMetric.volatility:
        data.sort((a, b) => ascending
            ? a.volatility.compareTo(b.volatility)
            : b.volatility.compareTo(a.volatility));
        break;
      case ComparisonMetric.sharpeRatio:
        data.sort((a, b) => ascending
            ? a.sharpeRatio.compareTo(b.sharpeRatio)
            : b.sharpeRatio.compareTo(a.sharpeRatio));
        break;
      case ComparisonMetric.maxDrawdown:
        data.sort((a, b) => ascending
            ? a.maxDrawdown.compareTo(b.maxDrawdown)
            : b.maxDrawdown.compareTo(a.maxDrawdown));
        break;
    }

    return data;
  }

  /// 计算收益分析
  Map<String, dynamic> calculateReturnAnalysis() {
    if (state.result == null) return {};

    final data = state.result!.fundData;
    if (data.isEmpty) return {};

    final returns = data.map((d) => d.totalReturn).toList();
    final positiveReturns = data.where((d) => d.totalReturn > 0).length;
    final negativeReturns = data.where((d) => d.totalReturn < 0).length;

    return {
      'totalFunds': data.length,
      'positiveReturns': positiveReturns,
      'negativeReturns': negativeReturns,
      'winRate': positiveReturns / data.length * 100,
      'averageReturn': returns.reduce((a, b) => a + b) / returns.length,
      'bestPerforming': data.isNotEmpty
          ? data.reduce((a, b) => a.totalReturn > b.totalReturn ? a : b)
          : null,
      'worstPerforming': data.isNotEmpty
          ? data.reduce((a, b) => a.totalReturn < b.totalReturn ? a : b)
          : null,
      'volatility': _calculateVolatility(returns),
    };
  }

  /// 计算风险分析
  Map<String, dynamic> calculateRiskAnalysis() {
    if (state.result == null) return {};

    final stats = state.result!.statistics;
    final data = state.result!.fundData;
    if (data.isEmpty) return {};

    return {
      'averageVolatility': stats.averageVolatility,
      'maxVolatility': stats.maxVolatility,
      'minVolatility': stats.minVolatility,
      'volatilityRatio': stats.averageVolatility > 0
          ? stats.maxVolatility / stats.averageVolatility
          : 0,
      'averageDrawdown':
          data.map((d) => d.maxDrawdown.abs()).reduce((a, b) => a + b) /
              data.length,
      'maxDrawdown':
          data.map((d) => d.maxDrawdown.abs()).reduce((a, b) => a > b ? a : b),
      'riskLevel': _assessRiskLevel(stats.averageVolatility),
      'riskDistribution': _calculateRiskDistribution(data),
    };
  }

  /// 计算相关性分析
  Map<String, dynamic> calculateCorrelationAnalysis() {
    if (state.result == null) return {};

    final stats = state.result!.statistics;
    final criteria = state.result!.criteria;

    // 计算平均相关性
    double totalCorrelation = 0.0;
    int correlationCount = 0;

    for (final fund1 in criteria.fundCodes) {
      for (final fund2 in criteria.fundCodes) {
        if (fund1 != fund2) {
          totalCorrelation += stats.correlationMatrix[fund1]?[fund2] ?? 0.0;
          correlationCount++;
        }
      }
    }

    final averageCorrelation =
        correlationCount > 0 ? totalCorrelation / correlationCount : 0.0;

    return {
      'averageCorrelation': averageCorrelation,
      'correlationMatrix': stats.correlationMatrix,
      'diversificationLevel': _assessDiversificationLevel(averageCorrelation),
      'highlyCorrelatedPairs':
          _countHighlyCorrelatedPairs(stats.correlationMatrix, 0.7),
    };
  }

  double _calculateVolatility(List<double> returns) {
    if (returns.isEmpty) return 0.0;

    final mean = returns.reduce((a, b) => a + b) / returns.length;
    final variance =
        returns.map((r) => (r - mean) * (r - mean)).reduce((a, b) => a + b) /
            returns.length;
    return sqrt(variance);
  }

  String _assessRiskLevel(double volatility) {
    if (volatility < 0.10) return '低风险';
    if (volatility < 0.20) return '中等风险';
    return '高风险';
  }

  Map<String, int> _calculateRiskDistribution(List<FundComparisonData> data) {
    final distribution = <String, int>{
      '低风险': 0,
      '中等风险': 0,
      '高风险': 0,
    };

    for (final item in data) {
      final risk = _assessRiskLevel(item.volatility);
      distribution[risk] = (distribution[risk] ?? 0) + 1;
    }

    return distribution;
  }

  String _assessDiversificationLevel(double correlation) {
    if (correlation < 0.3) return '高度分散化';
    if (correlation < 0.6) return '中度分散化';
    return '集中投资';
  }

  int _countHighlyCorrelatedPairs(
    Map<String, Map<String, double>> correlationMatrix,
    double threshold,
  ) {
    int count = 0;
    final processed = <String>{};

    for (final entry in correlationMatrix.entries) {
      final fund1 = entry.key;
      for (final subEntry in entry.value.entries) {
        final fund2 = subEntry.key;
        if (fund1 != fund2 && !processed.contains('$fund1-$fund2')) {
          if (subEntry.value >= threshold) {
            count++;
          }
          processed.add('$fund1-$fund2');
          processed.add('$fund2-$fund1');
        }
      }
    }

    return count;
  }

  @override
  Future<void> close() {
    AppLogger.info(_tag, 'FundComparisonCubit disposed');
    return super.close();
  }
}
