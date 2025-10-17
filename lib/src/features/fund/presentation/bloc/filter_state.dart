import 'package:equatable/equatable.dart';
import 'package:jisu_fund_analyzer/src/features/fund/domain/usecases/fund_filter_usecase.dart';
import '../../domain/entities/fund_filter_criteria.dart';

/// 筛选状态枚举
enum FilterStatus {
  /// 初始状态
  initial,

  /// 加载中
  loading,

  /// 加载更多数据中
  loadingMore,

  /// 加载成功
  success,

  /// 加载失败
  failure,

  /// 选项加载中
  optionsLoading,

  /// 选项加载成功
  optionsSuccess,

  /// 选项加载失败
  optionsFailure,
}

/// 筛选状态
class FilterState extends Equatable {
  /// 筛选条件
  final FundFilterCriteria criteria;

  /// 筛选结果
  final FundFilterResult? result;

  /// 筛选状态
  final FilterStatus status;

  /// 筛选选项
  final Map<FilterType, List<String>> options;

  /// 选项加载状态
  final FilterStatus optionsStatus;

  /// 错误信息
  final String? error;

  /// 选项加载错误信息
  final String? optionsError;

  /// 统计信息
  final FilterStatistics? statistics;

  /// 统计信息错误
  final String? statisticsError;

  /// 是否来自缓存
  final bool isFromCache;

  /// 自定义预设筛选条件
  final Map<String, FundFilterCriteria> customPresets;

  /// 筛选历史记录
  final List<FundFilterCriteria> filterHistory;

  /// 初始状态
  FilterState.initial()
      : criteria = FundFilterCriteria.empty(),
        result = null,
        status = FilterStatus.initial,
        options = const {},
        optionsStatus = FilterStatus.initial,
        error = null,
        optionsError = null,
        statistics = null,
        statisticsError = null,
        isFromCache = false,
        customPresets = const {},
        filterHistory = const [];

  /// 构造函数
  const FilterState({
    required this.criteria,
    this.result,
    required this.status,
    required this.options,
    required this.optionsStatus,
    this.error,
    this.optionsError,
    this.statistics,
    this.statisticsError,
    this.isFromCache = false,
    this.customPresets = const {},
    this.filterHistory = const [],
  });

  /// 复制并更新状态
  FilterState copyWith({
    FundFilterCriteria? criteria,
    FundFilterResult? result,
    FilterStatus? status,
    Map<FilterType, List<String>>? options,
    FilterStatus? optionsStatus,
    String? error,
    String? optionsError,
    FilterStatistics? statistics,
    String? statisticsError,
    bool? isFromCache,
    Map<String, FundFilterCriteria>? customPresets,
    List<FundFilterCriteria>? filterHistory,
  }) {
    return FilterState(
      criteria: criteria ?? this.criteria,
      result: result ?? this.result,
      status: status ?? this.status,
      options: options ?? this.options,
      optionsStatus: optionsStatus ?? this.optionsStatus,
      error: error ?? this.error,
      optionsError: optionsError ?? this.optionsError,
      statistics: statistics ?? this.statistics,
      statisticsError: statisticsError ?? this.statisticsError,
      isFromCache: isFromCache ?? this.isFromCache,
      customPresets: customPresets ?? this.customPresets,
      filterHistory: filterHistory ?? this.filterHistory,
    );
  }

  /// 是否为加载状态
  bool get isLoading =>
      status == FilterStatus.loading || status == FilterStatus.loadingMore;

  /// 是否为成功状态
  bool get isSuccess => status == FilterStatus.success;

  /// 是否为失败状态
  bool get isFailure => status == FilterStatus.failure;

  /// 是否有错误
  bool get hasError => error != null;

  /// 是否有结果
  bool get hasResult => result != null;

  /// 结果是否为空
  bool get isEmpty => result?.funds.isEmpty ?? true;

  /// 是否还有更多数据
  bool get hasMore => result?.hasMore ?? false;

  /// 当前结果数量
  int get currentResultCount => result?.funds.length ?? 0;

  /// 总结果数量
  int get totalResultCount => result?.totalCount ?? 0;

  /// 是否有活跃的筛选条件
  bool get hasActiveFilters => criteria.hasAnyFilter;

  /// 活跃筛选条件数量
  int get activeFiltersCount {
    int count = 0;
    if (criteria.fundTypes?.isNotEmpty == true) count++;
    if (criteria.companies?.isNotEmpty == true) count++;
    if (criteria.scaleRange != null) count++;
    if (criteria.establishmentDateRange != null) count++;
    if (criteria.riskLevels?.isNotEmpty == true) count++;
    if (criteria.returnRange != null) count++;
    if (criteria.statuses?.isNotEmpty == true) count++;
    return count;
  }

  /// 筛选条件描述
  String get filterDescription => criteria.toString();

  /// 获取特定类型的选项
  List<String> getOptionsForType(FilterType type) {
    return options[type] ?? [];
  }

  /// 检查特定类型是否有选项
  bool hasOptionsForType(FilterType type) {
    return options.containsKey(type) && options[type]!.isNotEmpty;
  }

  /// 获取当前页码
  int get currentPage => criteria.page;

  /// 获取每页数量
  int get pageSize => criteria.pageSize;

  /// 获取排序字段
  String? get sortBy => criteria.sortBy;

  /// 获取排序方向
  SortDirection? get sortDirection => criteria.sortDirection;

  /// 是否正在加载选项
  bool get isLoadingOptions => optionsStatus == FilterStatus.optionsLoading;

  /// 是否选项加载成功
  bool get isOptionsSuccess => optionsStatus == FilterStatus.optionsSuccess;

  /// 是否选项加载失败
  bool get isOptionsFailure => optionsStatus == FilterStatus.optionsFailure;

  /// 是否有选项错误
  bool get hasOptionsError => optionsError != null;

  /// 是否来自缓存
  bool get fromCache => isFromCache;

  /// 是否有统计信息
  bool get hasStatistics => statistics != null;

  /// 筛选比例（百分比）
  double get filterPercentage => (statistics?.filterRatio ?? 0.0) * 100;

  @override
  List<Object?> get props => [
        criteria,
        result,
        status,
        options,
        optionsStatus,
        error,
        optionsError,
        statistics,
        statisticsError,
        isFromCache,
        customPresets,
        filterHistory,
      ];

  @override
  String toString() {
    return 'FilterState('
        'status: $status, '
        'criteria: $criteria, '
        'resultCount: ${result?.funds.length ?? 0}, '
        'totalCount: ${result?.totalCount ?? 0}, '
        'hasError: ${error != null}, '
        'isFromCache: $isFromCache'
        ')';
  }
}
