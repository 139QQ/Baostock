/// 优化版基金探索Cubit - 状态迁移实战示例
///
/// 展示如何将现有的FundExplorationCubit迁移到OptimizedCubit架构
/// 体现新状态管理系统的优势：防抖、追踪、持久化、资源管理
library optimized_fund_exploration_cubit;

import 'dart:async';

import 'package:equatable/equatable.dart';

import 'package:jisu_fund_analyzer/src/features/fund/shared/services/fund_data_service.dart';
import 'package:jisu_fund_analyzer/src/features/fund/shared/services/search_service.dart';
import 'package:jisu_fund_analyzer/src/features/fund/shared/models/fund_ranking.dart';
import 'package:jisu_fund_analyzer/src/features/fund/shared/services/money_fund_service.dart';
import 'package:jisu_fund_analyzer/src/features/fund/shared/models/money_fund.dart';
import 'package:jisu_fund_analyzer/src/core/utils/logger.dart';
import 'package:jisu_fund_analyzer/src/core/state/optimized_cubit.dart';

/// 优化版基金探索状态
class OptimizedFundExplorationState extends Equatable {
  final List<FundRanking> funds;
  final List<MoneyFund> moneyFunds;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final String searchQuery;
  final String selectedCategory;
  final Set<String> expandedItems;
  final int currentPage;
  final bool hasMore;
  final DateTime lastUpdated;
  final int version;

  const OptimizedFundExplorationState({
    this.funds = const [],
    this.moneyFunds = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.searchQuery = '',
    this.selectedCategory = '全部',
    this.expandedItems = const {},
    this.currentPage = 1,
    this.hasMore = true,
    required this.lastUpdated,
    this.version = 1,
  });

  factory OptimizedFundExplorationState.initial() =>
      OptimizedFundExplorationState(
        lastUpdated: DateTime.now(),
      );

  OptimizedFundExplorationState copyWith({
    List<FundRanking>? funds,
    List<MoneyFund>? moneyFunds,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    String? searchQuery,
    String? selectedCategory,
    Set<String>? expandedItems,
    int? currentPage,
    bool? hasMore,
    DateTime? lastUpdated,
    int? version,
  }) {
    return OptimizedFundExplorationState(
      funds: funds ?? this.funds,
      moneyFunds: moneyFunds ?? this.moneyFunds,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      expandedItems: expandedItems ?? this.expandedItems,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      version: (version ?? this.version) + 1,
    );
  }

  @override
  List<Object?> get props => [
        funds,
        moneyFunds,
        isLoading,
        isRefreshing,
        error,
        searchQuery,
        selectedCategory,
        expandedItems,
        currentPage,
        hasMore,
        lastUpdated,
        version,
      ];
}

/// 优化版基金探索Cubit
///
/// 相比原版的改进：
/// 1. 继承OptimizedCubit，自动获得资源管理、状态追踪、防抖等功能
/// 2. 集成状态持久化，支持应用重启后状态恢复
/// 3. 增强的错误处理和恢复机制
/// 4. 更好的性能监控和调试支持
class OptimizedFundExplorationCubit
    extends OptimizedCubit<OptimizedFundExplorationState> {
  final FundDataService _fundDataService;
  final SearchService _searchService;
  final MoneyFundService _moneyFundService;

  /// 构造函数
  OptimizedFundExplorationCubit({
    required FundDataService fundDataService,
    required SearchService searchService,
    required MoneyFundService moneyFundService,
  })  : _fundDataService = fundDataService,
        _searchService = searchService,
        _moneyFundService = moneyFundService,
        super('OptimizedFundExplorationCubit',
            OptimizedFundExplorationState.initial());

  /// 初始化钩子方法
  @override
  Future<void> onInitialize() async {
    AppLogger.debug('🚀 [OptimizedFundExplorationCubit] 开始初始化');

    // 尝试加载持久化状态
    await _loadPersistedState();

    // 如果没有持久化状态或状态为空，则初始化数据
    if (state.funds.isEmpty && !state.isLoading) {
      await loadFunds();
    }

    AppLogger.debug('✅ [OptimizedFundExplorationCubit] 初始化完成');
  }

  /// 加载持久化状态
  Future<void> _loadPersistedState() async {
    try {
      final persistedState =
          await loadPersistedState<OptimizedFundExplorationState>('main_state');
      if (persistedState != null) {
        emit(persistedState.copyWith(
          lastUpdated: DateTime.now(),
          version: persistedState.version + 1,
        ));
        AppLogger.debug('📂 [OptimizedFundExplorationCubit] 已加载持久化状态');
      }
    } catch (e) {
      AppLogger.error('❌ [OptimizedFundExplorationCubit] 加载持久化状态失败', e);
    }
  }

  /// 持久化当前状态
  Future<void> _persistState() async {
    try {
      await persistState('main_state', state);
      AppLogger.debug('💾 [OptimizedFundExplorationCubit] 状态已持久化');
    } catch (e) {
      AppLogger.error('❌ [OptimizedFundExplorationCubit] 状态持久化失败', e);
    }
  }

  /// 加载基金数据（带追踪和防抖）
  Future<void> loadFunds({bool refresh = false}) async {
    await executeTracked(
      operation: refresh ? '刷新基金数据' : '加载基金数据',
      body: () async {
        if (refresh) {
          emit(state.copyWith(isRefreshing: true, error: null));
        } else {
          emit(state.copyWith(isLoading: true, error: null));
        }

        try {
          // 使用现有的FundDataService获取数据
          final fundResult = await _fundDataService.getFundRankings(
            symbol: state.selectedCategory,
            forceRefresh: refresh,
          );

          if (fundResult.isFailure) {
            throw Exception(fundResult.errorMessage ?? '获取基金数据失败');
          }

          final funds = fundResult.data ?? [];

          // 获取货币基金数据
          final moneyFundResult = await _moneyFundService.getMoneyFunds();

          if (moneyFundResult.isFailure) {
            throw Exception(moneyFundResult.errorMessage ?? '获取货币基金数据失败');
          }

          final moneyFunds = moneyFundResult.data ?? [];

          emit(state.copyWith(
            funds: funds,
            moneyFunds: moneyFunds,
            isLoading: false,
            isRefreshing: false,
            error: null,
            currentPage: 1,
            hasMore: funds.isNotEmpty,
            lastUpdated: DateTime.now(),
          ));

          // 持久化状态
          await _persistState();

          AppLogger.debug(
              '✅ [OptimizedFundExplorationCubit] 基金数据加载完成: ${funds.length}只基金');
        } catch (e) {
          emit(state.copyWith(
            isLoading: false,
            isRefreshing: false,
            error: e.toString(),
          ));
          rethrow;
        }
      },
    );
  }

  /// 搜索基金（使用内置防抖机制）
  void searchFunds(String query) {
    // 使用OptimizedCubit的防抖功能
    addDebouncedOperation(
      'search',
      duration: const Duration(milliseconds: 300),
      operation: () => _performSearch(query),
    );
  }

  /// 执行搜索
  Future<void> _performSearch(String query) async {
    await executeTracked(
      operation: '搜索基金: $query',
      body: () async {
        emit(state.copyWith(searchQuery: query, isLoading: true, error: null));

        try {
          if (query.isEmpty) {
            // 如果搜索为空，加载所有基金
            await loadFunds();
            return;
          }

          // 执行搜索
          final searchResult = await _searchService.search(query);

          if (searchResult.isFailure) {
            throw Exception(searchResult.errorMessage ?? '搜索失败');
          }

          final searchResults = searchResult.results;

          emit(state.copyWith(
            funds: searchResults,
            isLoading: false,
            error: null,
            lastUpdated: DateTime.now(),
          ));

          await _persistState();

          AppLogger.debug(
              '🔍 [OptimizedFundExplorationCubit] 搜索完成: ${searchResults.length}个结果');
        } catch (e) {
          emit(state.copyWith(
            isLoading: false,
            error: e.toString(),
          ));
          rethrow;
        }
      },
    );
  }

  /// 选择基金类别
  void selectCategory(String category) async {
    await executeTracked(
      operation: '选择基金类别: $category',
      body: () async {
        if (state.selectedCategory == category) return;

        emit(state.copyWith(
          selectedCategory: category,
          searchQuery: '',
          currentPage: 1,
        ));

        await loadFunds();
      },
    );
  }

  /// 切换展开状态
  void toggleExpanded(String fundCode) {
    final expandedItems = Set<String>.from(state.expandedItems);
    if (expandedItems.contains(fundCode)) {
      expandedItems.remove(fundCode);
    } else {
      expandedItems.add(fundCode);
    }

    emit(state.copyWith(
      expandedItems: expandedItems,
      lastUpdated: DateTime.now(),
    ));

    // 持久化展开状态
    _persistState();
  }

  /// 加载更多数据
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    await executeTracked(
      operation: '加载更多基金数据',
      body: () async {
        final nextPage = state.currentPage + 1;
        emit(state.copyWith(isLoading: true));

        try {
          // 这里应该实现分页加载逻辑
          // 暂时模拟没有更多数据
          await Future.delayed(const Duration(milliseconds: 500));

          emit(state.copyWith(
            isLoading: false,
            hasMore: false,
            currentPage: nextPage,
          ));

          AppLogger.debug('📄 [OptimizedFundExplorationCubit] 加载更多数据完成');
        } catch (e) {
          emit(state.copyWith(
            isLoading: false,
            error: e.toString(),
          ));
          rethrow;
        }
      },
    );
  }

  /// 清除错误
  void clearError() {
    if (state.error != null) {
      emit(state.copyWith(error: null));
      _persistState();
    }
  }

  /// 重置状态
  @override
  Future<void> onReset() async {
    await super.onReset();
    emit(OptimizedFundExplorationState.initial());
    await _persistState();
    AppLogger.debug('🔄 [OptimizedFundExplorationCubit] 状态已重置');
  }

  /// 关闭钩子方法
  @override
  Future<void> onClose() async {
    // 持久化最终状态
    await _persistState();

    // 清理资源
    clearHistory();

    AppLogger.debug('🗑️ [OptimizedFundExplorationCubit] 已关闭');
    await super.onClose();
  }

  /// 获取性能统计
  Map<String, dynamic> getPerformanceStats() {
    final cubitStats = getStats();
    return {
      'componentId': componentId,
      'stateVersion': state.version,
      'fundsCount': state.funds.length,
      'moneyFundsCount': state.moneyFunds.length,
      'lastUpdated': state.lastUpdated.toIso8601String(),
      'isLoading': state.isLoading,
      'hasError': state.error != null,
      'changeCount': changeCount,
      'cubitStats': cubitStats,
    };
  }
}
