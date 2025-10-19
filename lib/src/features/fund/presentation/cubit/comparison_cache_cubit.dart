import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/multi_dimensional_comparison_criteria.dart';
import '../../domain/entities/comparison_result.dart';
import '../../../../core/utils/logger.dart';

/// 对比缓存状态
enum ComparisonCacheStatus {
  initial,
  loading,
  loaded,
  error,
  refreshing,
}

/// 缓存状态类
class ComparisonCacheState extends Equatable {
  const ComparisonCacheState({
    this.status = ComparisonCacheStatus.initial,
    this.cachedComparisons = const {},
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  final ComparisonCacheStatus status;
  final Map<String, ComparisonResult> cachedComparisons;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  ComparisonCacheState copyWith({
    ComparisonCacheStatus? status,
    Map<String, ComparisonResult>? cachedComparisons,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return ComparisonCacheState(
      status: status ?? this.status,
      cachedComparisons: cachedComparisons ?? this.cachedComparisons,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
        status,
        cachedComparisons,
        isLoading,
        error,
        lastUpdated,
      ];
}

/// 对比缓存管理Cubit
///
/// 负责管理对比结果的缓存、预加载和过期处理
class ComparisonCacheCubit extends Cubit<ComparisonCacheState> {
  static const String _tag = 'ComparisonCacheCubit';
  static const Duration _cacheExpiration = Duration(hours: 1);

  ComparisonCacheCubit() : super(const ComparisonCacheState()) {
    AppLogger.info(_tag, 'ComparisonCacheCubit initialized');
  }

  /// 从缓存获取对比结果
  ComparisonResult? getCachedComparison(
      MultiDimensionalComparisonCriteria criteria) {
    final cacheKey = _generateCacheKey(criteria);
    final cachedResult = state.cachedComparisons[cacheKey];

    if (cachedResult == null) {
      AppLogger.debug(_tag, 'Cache miss for criteria: $cacheKey');
      return null;
    }

    // 检查缓存是否过期
    if (_isCacheExpired(cachedResult)) {
      AppLogger.debug(_tag, 'Cache expired for criteria: $cacheKey');
      _removeFromCache(cacheKey);
      return null;
    }

    AppLogger.debug(_tag, 'Cache hit for criteria: $cacheKey');
    return cachedResult;
  }

  /// 缓存对比结果
  Future<void> cacheComparisonResult(
    ComparisonResult result,
  ) async {
    try {
      final cacheKey = _generateCacheKey(result.criteria);
      final updatedCache =
          Map<String, ComparisonResult>.from(state.cachedComparisons);

      updatedCache[cacheKey] = result;

      emit(state.copyWith(
        cachedComparisons: updatedCache,
        lastUpdated: DateTime.now(),
      ));

      // 异步持久化缓存
      await _persistCache();

      AppLogger.info(_tag, 'Comparison result cached: $cacheKey');
    } catch (e) {
      AppLogger.error(_tag, 'Failed to cache comparison result: $e');
    }
  }

  /// 预加载对比数据
  Future<void> preloadComparisons(
    List<MultiDimensionalComparisonCriteria> criteriaList,
  ) async {
    if (criteriaList.isEmpty) return;

    emit(state.copyWith(status: ComparisonCacheStatus.loading));

    try {
      AppLogger.info(_tag, 'Preloading ${criteriaList.length} comparisons');

      // 这里应该调用实际的API或服务来获取数据
      // 暂时跳过实际的数据获取，只更新状态
      for (final criteria in criteriaList) {
        // TODO: 实现实际的预加载逻辑
        final cacheKey = _generateCacheKey(criteria);
        AppLogger.debug(_tag, 'Preloading comparison for: $cacheKey');
      }

      emit(state.copyWith(
        status: ComparisonCacheStatus.loaded,
        lastUpdated: DateTime.now(),
      ));

      AppLogger.info(_tag, 'Preloading completed');
    } catch (e) {
      emit(state.copyWith(
        status: ComparisonCacheStatus.error,
        error: e.toString(),
      ));

      AppLogger.error(_tag, 'Preloading failed: $e');
    }
  }

  /// 刷新指定的对比缓存
  Future<void> refreshComparison(
    MultiDimensionalComparisonCriteria criteria,
  ) async {
    final cacheKey = _generateCacheKey(criteria);

    emit(state.copyWith(
      status: ComparisonCacheStatus.refreshing,
      isLoading: true,
    ));

    try {
      AppLogger.info(_tag, 'Refreshing comparison: $cacheKey');

      // 从缓存中移除旧的对比结果
      _removeFromCache(cacheKey);

      // TODO: 实现实际的刷新逻辑
      // 这里应该调用API获取新数据

      emit(state.copyWith(
        status: ComparisonCacheStatus.loaded,
        isLoading: false,
        lastUpdated: DateTime.now(),
      ));

      AppLogger.info(_tag, 'Comparison refreshed: $cacheKey');
    } catch (e) {
      emit(state.copyWith(
        status: ComparisonCacheStatus.error,
        isLoading: false,
        error: e.toString(),
      ));

      AppLogger.error(_tag, 'Comparison refresh failed: $e');
    }
  }

  /// 清除所有缓存
  Future<void> clearCache() async {
    try {
      emit(state.copyWith(
        cachedComparisons: {},
        status: ComparisonCacheStatus.initial,
        lastUpdated: DateTime.now(),
      ));

      // 清除持久化缓存
      await _clearPersistedCache();

      AppLogger.info(_tag, 'All cache cleared');
    } catch (e) {
      AppLogger.error(_tag, 'Failed to clear cache: $e');
    }
  }

  /// 清除过期缓存
  Future<void> clearExpiredCache() async {
    try {
      final validCache = <String, ComparisonResult>{};
      int expiredCount = 0;

      for (final entry in state.cachedComparisons.entries) {
        if (!_isCacheExpired(entry.value)) {
          validCache[entry.key] = entry.value;
        } else {
          expiredCount++;
        }
      }

      if (expiredCount > 0) {
        emit(state.copyWith(
          cachedComparisons: validCache,
          lastUpdated: DateTime.now(),
        ));

        await _persistCache();

        AppLogger.info(_tag, 'Cleared $expiredCount expired cache entries');
      }
    } catch (e) {
      AppLogger.error(_tag, 'Failed to clear expired cache: $e');
    }
  }

  /// 获取缓存统计信息
  Map<String, dynamic> getCacheStatistics() {
    final cache = state.cachedComparisons;
    int expiredCount = 0;
    int validCount = 0;

    for (final entry in cache.values) {
      if (_isCacheExpired(entry)) {
        expiredCount++;
      } else {
        validCount++;
      }
    }

    return {
      'totalEntries': cache.length,
      'validEntries': validCount,
      'expiredEntries': expiredCount,
      'lastUpdated': state.lastUpdated?.toIso8601String(),
      'cacheExpiration': _cacheExpiration.inMinutes,
    };
  }

  /// 检查是否有指定条件的缓存
  bool hasCachedComparison(MultiDimensionalComparisonCriteria criteria) {
    final cacheKey = _generateCacheKey(criteria);
    final cachedResult = state.cachedComparisons[cacheKey];

    if (cachedResult == null) return false;

    if (_isCacheExpired(cachedResult)) {
      _removeFromCache(cacheKey);
      return false;
    }

    return true;
  }

  /// 生成缓存键
  String _generateCacheKey(MultiDimensionalComparisonCriteria criteria) {
    // 对基金代码和时间段进行排序，确保相同条件生成相同的键
    final sortedFunds = List<String>.from(criteria.fundCodes)..sort();
    final sortedPeriods = List<String>.from(
      criteria.periods.map((p) => p.name),
    )..sort();

    return jsonEncode({
      'funds': sortedFunds,
      'periods': sortedPeriods,
      'metric': criteria.metric.name,
      'sortBy': criteria.sortBy.name,
      'includeStatistics': criteria.includeStatistics,
    });
  }

  /// 检查缓存是否过期
  bool _isCacheExpired(ComparisonResult result) {
    final now = DateTime.now();
    final createdAt = result.lastUpdated;

    if (createdAt == null) return true;

    return now.difference(createdAt) > _cacheExpiration;
  }

  /// 从缓存中移除指定条目
  void _removeFromCache(String cacheKey) {
    final updatedCache =
        Map<String, ComparisonResult>.from(state.cachedComparisons);
    updatedCache.remove(cacheKey);

    emit(state.copyWith(cachedComparisons: updatedCache));
  }

  /// 持久化缓存
  Future<void> _persistCache() async {
    try {
      // TODO: 实现实际的持久化逻辑
      // 可以使用SharedPreferences、Hive或其他存储方案
      AppLogger.debug(_tag, 'Cache persistence completed');
    } catch (e) {
      AppLogger.error(_tag, 'Failed to persist cache: $e');
    }
  }

  /// 清除持久化缓存
  Future<void> _clearPersistedCache() async {
    try {
      // TODO: 实现实际的清除持久化缓存逻辑
      AppLogger.debug(_tag, 'Persisted cache cleared');
    } catch (e) {
      AppLogger.error(_tag, 'Failed to clear persisted cache: $e');
    }
  }

  /// 从持久化存储加载缓存
  Future<void> loadPersistedCache() async {
    try {
      // TODO: 实现实际的加载持久化缓存逻辑
      AppLogger.debug(_tag, 'Persisted cache loaded');
    } catch (e) {
      AppLogger.error(_tag, 'Failed to load persisted cache: $e');
    }
  }

  @override
  Future<void> close() {
    AppLogger.info(_tag, 'ComparisonCacheCubit disposed');
    return super.close();
  }
}
