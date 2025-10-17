import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/fund_filter_criteria.dart';
import '../../domain/usecases/fund_filter_usecase.dart';
import 'filter_event.dart';
import 'filter_state.dart';

/// 基金筛选状态管理BLoC
///
/// 负责管理基金筛选的状态，包括：
/// - 筛选条件状态
/// - 筛选结果状态
/// - 加载状态
/// - 错误状态
///
/// 性能优化特性：
/// - 防抖动处理
/// - 结果缓存
/// - 分页加载
/// - 状态持久化
class FilterBloc extends Bloc<FilterEvent, FilterState> {
  final FundFilterUseCase _filterUseCase;

  // 缓存筛选结果
  final Map<String, FundFilterResult> _resultCache = {};

  // 防抖动计时器
  DateTime? _lastFilterTime;
  static Duration debounceTime = const Duration(milliseconds: 300);

  FilterBloc({
    required FundFilterUseCase filterUseCase,
  })  : _filterUseCase = filterUseCase,
        super(FilterState.initial()) {
    on<LoadFilterOptions>(_onLoadFilterOptions);
    on<UpdateFilterCriteria>(_onUpdateFilterCriteria);
    on<ApplyFilter>(_onApplyFilter);
    on<ResetFilter>(_onResetFilter);
    on<ResetFilterType>(_onResetFilterType);
    on<LoadMoreResults>(_onLoadMoreResults);
    on<ChangeSortOption>(_onChangeSortOption);
    on<ApplyPresetFilter>(_onApplyPresetFilter);
    on<SaveFilterPreset>(_onSaveFilterPreset);
    on<LoadFilterStatistics>(_onLoadFilterStatistics);
  }

  /// 加载筛选选项
  Future<void> _onLoadFilterOptions(
    LoadFilterOptions event,
    Emitter<FilterState> emit,
  ) async {
    emit(state.copyWith(
      optionsStatus: FilterStatus.loading,
    ));

    try {
      final options = <FilterType, List<String>>{};

      for (final type in FilterType.values) {
        final typeOptions = await _filterUseCase.getFilterOptions(type);
        options[type] = typeOptions;
      }

      emit(state.copyWith(
        options: options,
        optionsStatus: FilterStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        optionsStatus: FilterStatus.failure,
        optionsError: e.toString(),
      ));
    }
  }

  /// 更新筛选条件
  Future<void> _onUpdateFilterCriteria(
    UpdateFilterCriteria event,
    Emitter<FilterState> emit,
  ) async {
    final updatedCriteria = state.criteria.copyWith(
      fundTypes: event.fundTypes,
      companies: event.companies,
      scaleRange: event.scaleRange,
      establishmentDateRange: event.establishmentDateRange,
      riskLevels: event.riskLevels,
      returnRange: event.returnRange,
      statuses: event.statuses,
      page: 1, // 重置到第一页
    );

    emit(state.copyWith(
      criteria: updatedCriteria,
      status: FilterStatus.initial,
    ));

    // 防抖动处理
    _debounceFilter(() {
      add(ApplyFilter(criteria: updatedCriteria));
    });
  }

  /// 应用筛选
  Future<void> _onApplyFilter(
    ApplyFilter event,
    Emitter<FilterState> emit,
  ) async {
    // 检查缓存
    final cacheKey = _generateCacheKey(event.criteria);
    if (_resultCache.containsKey(cacheKey)) {
      final cachedResult = _resultCache[cacheKey]!;
      emit(state.copyWith(
        result: cachedResult,
        status: FilterStatus.success,
        isFromCache: true,
      ));
      return;
    }

    emit(state.copyWith(
      status: FilterStatus.loading,
      isFromCache: false,
    ));

    try {
      final result = await _filterUseCase.execute(event.criteria);

      // 转换结果类型
      final localResult = FundFilterResult(
        funds: result.funds,
        totalCount: result.totalCount,
        hasMore: result.hasMore,
        criteria: result.criteria,
      );

      // 缓存结果
      _resultCache[cacheKey] = localResult;

      emit(state.copyWith(
        result: localResult,
        status: FilterStatus.success,
        statistics: FilterStatistics(
          totalFunds: result.totalCount,
          filteredFunds: result.funds.length,
          filterRatio: result.totalCount > 0
              ? result.funds.length / result.totalCount
              : 0.0,
          averageReturn: 0.0,
          averageScale: 0.0,
          criteria: result.criteria,
        ),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FilterStatus.failure,
        error: e.toString(),
      ));
    }
  }

  /// 重置所有筛选条件
  Future<void> _onResetFilter(
    ResetFilter event,
    Emitter<FilterState> emit,
  ) async {
    final emptyCriteria = FundFilterCriteria.empty();

    emit(state.copyWith(
      criteria: emptyCriteria,
      status: FilterStatus.initial,
      result: null,
      statistics: null,
    ));

    add(ApplyFilter(criteria: emptyCriteria));
  }

  /// 重置特定类型的筛选条件
  Future<void> _onResetFilterType(
    ResetFilterType event,
    Emitter<FilterState> emit,
  ) async {
    final updatedCriteria = state.criteria.resetFilterType(event.type);

    emit(state.copyWith(
      criteria: updatedCriteria,
      status: FilterStatus.initial,
    ));

    add(ApplyFilter(criteria: updatedCriteria));
  }

  /// 加载更多结果
  Future<void> _onLoadMoreResults(
    LoadMoreResults event,
    Emitter<FilterState> emit,
  ) async {
    if (state.result?.hasMore != true || state.status == FilterStatus.loading) {
      return;
    }

    final currentCriteria = state.criteria;
    final nextPageCriteria = currentCriteria.copyWith(
      page: currentCriteria.page + 1,
    );

    emit(state.copyWith(
      criteria: nextPageCriteria,
      status: FilterStatus.loadingMore,
    ));

    try {
      final nextPageResult = await _filterUseCase.execute(nextPageCriteria);

      // 合并结果
      final currentFunds = state.result?.funds ?? [];
      final allFunds = [...currentFunds, ...nextPageResult.funds];

      final combinedResult = FundFilterResult(
        funds: allFunds,
        totalCount: nextPageResult.totalCount,
        hasMore: nextPageResult.hasMore,
        criteria: nextPageCriteria,
      );

      // 更新缓存
      final cacheKey = _generateCacheKey(nextPageCriteria);
      _resultCache[cacheKey] = combinedResult;

      emit(state.copyWith(
        result: combinedResult,
        status: FilterStatus.success,
      ));
    } catch (e) {
      // 恢复原始页码
      emit(state.copyWith(
        criteria: currentCriteria,
        status: FilterStatus.failure,
        error: '加载更多结果失败: ${e.toString()}',
      ));
    }
  }

  /// 更改排序选项
  Future<void> _onChangeSortOption(
    ChangeSortOption event,
    Emitter<FilterState> emit,
  ) async {
    final updatedCriteria = state.criteria.copyWith(
      sortBy: event.sortBy,
      sortDirection: event.sortDirection,
      page: 1, // 重置到第一页
    );

    emit(state.copyWith(
      criteria: updatedCriteria,
    ));

    add(ApplyFilter(criteria: updatedCriteria));
  }

  /// 应用预设筛选条件
  Future<void> _onApplyPresetFilter(
    ApplyPresetFilter event,
    Emitter<FilterState> emit,
  ) async {
    final presets = await _filterUseCase.getCommonFilterPresets();
    final presetCriteria = presets[event.presetName];

    if (presetCriteria != null) {
      emit(state.copyWith(
        criteria: presetCriteria,
        status: FilterStatus.initial,
      ));

      add(ApplyFilter(criteria: presetCriteria));
    }
  }

  /// 保存筛选预设
  Future<void> _onSaveFilterPreset(
    SaveFilterPreset event,
    Emitter<FilterState> emit,
  ) async {
    // 这里可以保存到本地存储
    // 暂时只更新状态
    final customPresets =
        Map<String, FundFilterCriteria>.from(state.customPresets);
    customPresets[event.presetName] = state.criteria;

    emit(state.copyWith(
      customPresets: customPresets,
    ));
  }

  /// 加载筛选统计信息
  Future<void> _onLoadFilterStatistics(
    LoadFilterStatistics event,
    Emitter<FilterState> emit,
  ) async {
    if (!state.criteria.hasAnyFilter) {
      emit(state.copyWith(
        statistics: FilterStatistics(
          totalFunds: 0,
          filteredFunds: 0,
          filterRatio: 0.0,
          averageReturn: 0.0,
          averageScale: 0.0,
          criteria: FundFilterCriteria.empty(),
        ),
      ));
      return;
    }

    try {
      final statistics =
          await _filterUseCase.getFilterStatistics(state.criteria);
      final localStatistics = FilterStatistics(
        totalFunds: statistics.totalFunds,
        filteredFunds: statistics.filteredFunds,
        filterRatio: statistics.filterRatio,
        averageReturn: statistics.averageReturn,
        averageScale: statistics.averageScale,
        criteria: statistics.criteria,
      );
      emit(state.copyWith(
        statistics: localStatistics,
      ));
    } catch (e) {
      // 统计信息加载失败不影响主流程
      emit(state.copyWith(
        statisticsError: e.toString(),
      ));
    }
  }

  /// 生成缓存键
  String _generateCacheKey(FundFilterCriteria criteria) {
    final buffer = StringBuffer();
    buffer.write(criteria.fundTypes?.join(',') ?? '');
    buffer.write('|${criteria.companies?.join(',') ?? ''}');
    buffer.write('|${criteria.scaleRange?.toString() ?? ''}');
    buffer.write('|${criteria.establishmentDateRange?.toString() ?? ''}');
    buffer.write('|${criteria.riskLevels?.join(',') ?? ''}');
    buffer.write('|${criteria.returnRange?.toString() ?? ''}');
    buffer.write('|${criteria.statuses?.join(',') ?? ''}');
    buffer.write('|${criteria.sortBy ?? ''}');
    buffer.write('|${criteria.sortDirection?.name ?? ''}');
    buffer.write('|${criteria.page}');
    buffer.write('|${criteria.pageSize}');
    return buffer.toString();
  }

  /// 防抖动处理
  void _debounceFilter(VoidCallback action) {
    final now = DateTime.now();
    if (_lastFilterTime != null &&
        now.difference(_lastFilterTime!) < debounceTime) {
      return;
    }
    _lastFilterTime = now;
    action();
  }

  /// 清除缓存
  void clearCache() {
    _resultCache.clear();
  }

  /// 获取当前筛选条件的描述
  String getFilterDescription() {
    return state.criteria.toString();
  }

  /// 检查是否有活跃的筛选条件
  bool hasActiveFilters() {
    return state.criteria.hasAnyFilter;
  }

  /// 获取活跃筛选条件的数量
  int getActiveFiltersCount() {
    int count = 0;
    if (state.criteria.fundTypes?.isNotEmpty == true) count++;
    if (state.criteria.companies?.isNotEmpty == true) count++;
    if (state.criteria.scaleRange != null) count++;
    if (state.criteria.establishmentDateRange != null) count++;
    if (state.criteria.riskLevels?.isNotEmpty == true) count++;
    if (state.criteria.returnRange != null) count++;
    if (state.criteria.statuses?.isNotEmpty == true) count++;
    return count;
  }
}
