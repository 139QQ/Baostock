import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/utils/logger.dart';
import '../../../../shared/services/fund_data_service.dart';
import '../../../../shared/services/search_service.dart';
import '../../../../shared/models/fund_ranking.dart';
import '../../../../shared/services/money_fund_service.dart';
import '../../../../shared/models/money_fund.dart';

part 'fund_exploration_state.dart';

/// 统一的基金探索状态管理Cubit
///
/// 职责：
/// - 基金探索页面的统一状态管理
/// - 基金排行数据获取和缓存
/// - 搜索和筛选功能
/// - UI状态管理（加载、错误、展开等）
/// - 分页和刷新功能
///
/// 设计模式：
/// - 单一职责原则：专注于基金探索相关状态
/// - 观察者模式：通过Cubit通知UI状态变化
/// - 策略模式：支持不同的搜索和筛选策略
class FundExplorationCubit extends Cubit<FundExplorationState> {
  final FundDataService _fundDataService;
  final SearchService _searchService;
  final MoneyFundService _moneyFundService;

  // 搜索防抖定时器
  Timer? _searchDebounce;

  // Cubit是否已关闭标志
  bool _isClosed = false;

  FundExplorationCubit({
    required FundDataService fundDataService,
    required SearchService searchService,
    required MoneyFundService moneyFundService,
    bool autoInitialize = true,
  })  : _fundDataService = fundDataService,
        _searchService = searchService,
        _moneyFundService = moneyFundService,
        super(const FundExplorationState.initial()) {
    if (autoInitialize) {
      _initialize();
    }
  }

  /// 安全的emit方法，防止在Cubit关闭后发射状态
  void _safeEmit(FundExplorationState newState) {
    if (!_isClosed && !isClosed) {
      emit(newState);
    } else {
      AppLogger.debug('⚠️ FundExplorationCubit: Cubit已关闭，跳过状态发射');
    }
  }

  /// 初始化状态管理器
  Future<void> _initialize() async {
    AppLogger.debug('🔄 FundExplorationCubit: 初始化');
    await loadFundRankings();
  }

  /// 加载基金排行数据 - 增强版本，包含重试机制
  Future<void> loadFundRankings({
    String symbol = '', // 基金排行API不需要参数
    bool forceRefresh = false,
    int maxRetries = 3,
  }) async {
    // 检查Cubit是否已关闭
    if (_isClosed || isClosed) {
      AppLogger.debug('⚠️ FundExplorationCubit: Cubit已关闭，取消加载操作');
      return;
    }

    if (!forceRefresh && state.isLoading) {
      AppLogger.debug('⏭️ FundExplorationCubit: 正在加载中，跳过重复请求');
      return;
    }

    AppLogger.debug(
        '🔄 FundExplorationCubit: 开始加载基金排行数据 (forceRefresh: $forceRefresh, maxRetries: $maxRetries)');

    _safeEmit(state.copyWith(
      status: FundExplorationStatus.loading,
      isLoading: true,
      errorMessage: null,
    ));

    // 增强的重试机制
    int attemptCount = 0;
    dynamic lastError;

    while (attemptCount <= maxRetries) {
      try {
        AppLogger.debug('🔄 FundExplorationCubit: 第${attemptCount + 1}次尝试加载数据');

        final result = await _fundDataService.getFundRankings(
          symbol: symbol,
          forceRefresh: forceRefresh,
          onProgress: (progress) {
            // 安全地发射进度状态
            _safeEmit(state.copyWith(loadProgress: progress));
          },
        );

        // 检查Cubit是否在异步操作过程中被关闭
        if (_isClosed || isClosed) {
          AppLogger.debug('⚠️ FundExplorationCubit: Cubit在数据加载过程中被关闭，取消状态更新');
          return;
        }

        if (result.isSuccess) {
          final rankings = result.data!;

          // 验证数据有效性
          if (rankings.isEmpty) {
            final errorMsg = '获取的基金数据为空，请重试';
            AppLogger.warn('⚠️ FundExplorationCubit: $errorMsg');
            if (attemptCount < maxRetries) {
              attemptCount++;
              lastError = errorMsg;
              await Future.delayed(Duration(seconds: 2 * attemptCount)); // 递增延迟
              continue;
            }
            _safeEmit(state.copyWith(
              status: FundExplorationStatus.error,
              isLoading: false,
              errorMessage: errorMsg,
            ));
            return;
          }

          // 构建搜索索引
          try {
            _searchService.buildIndex(rankings);
          } catch (indexError) {
            AppLogger.warn(
                '⚠️ FundExplorationCubit: 构建搜索索引失败，但继续处理: $indexError');
            // 索引构建失败不影响主要功能
          }

          // 暂时禁用模拟数据检测，显示所有数据
          const isRealData = true; // _checkIfRealData(rankings);

          AppLogger.debug(
              '✅ FundExplorationCubit: 数据加载成功 (${rankings.length}条, isRealData: $isRealData, attempt: ${attemptCount + 1})');

          _safeEmit(state.copyWith(
            status: FundExplorationStatus.loaded,
            isLoading: false,
            fundRankings: rankings,
            searchResults: rankings, // 初始搜索结果为全部数据
            totalCount: rankings.length,
            lastUpdateTime: DateTime.now(),
            isRealData: isRealData,
            loadProgress: 1.0,
          ));
          return; // 成功，退出重试循环
        } else {
          final errorMsg = result.errorMessage ?? '未知错误';
          AppLogger.warn(
              '⚠️ FundExplorationCubit: 数据加载失败 (attempt: ${attemptCount + 1}): $errorMsg');

          if (attemptCount < maxRetries) {
            attemptCount++;
            lastError = errorMsg;
            // 根据错误类型决定是否重试
            if (_shouldRetryForError(errorMsg)) {
              await Future.delayed(Duration(seconds: 2 * attemptCount)); // 递增延迟
              continue;
            } else {
              // 不应重试的错误，直接失败
              break;
            }
          } else {
            // 达到最大重试次数
            _safeEmit(state.copyWith(
              status: FundExplorationStatus.error,
              isLoading: false,
              errorMessage: '加载失败: $errorMsg',
            ));
            return;
          }
        }
      } catch (e) {
        final errorMsg = '加载失败: $e';
        AppLogger.error(
            '❌ FundExplorationCubit: $errorMsg (attempt: ${attemptCount + 1})',
            e);

        if (attemptCount < maxRetries) {
          attemptCount++;
          lastError = e;
          // 根据异常类型决定是否重试
          if (_shouldRetryForException(e)) {
            await Future.delayed(Duration(seconds: 2 * attemptCount)); // 递增延迟
            continue;
          } else {
            // 不应重试的异常，直接失败
            break;
          }
        } else {
          // 达到最大重试次数
          break;
        }
      }
    }

    // 所有重试都失败了
    final finalErrorMsg = '加载失败: $lastError';
    AppLogger.debug('🔄 FundExplorationCubit: 发射错误状态');
    _safeEmit(state.copyWith(
      status: FundExplorationStatus.error,
      isLoading: false,
      errorMessage: finalErrorMsg,
    ));
    AppLogger.debug('✅ FundExplorationCubit: 错误状态已发射');
  }

  /// 搜索基金
  void searchFunds(String query) {
    emit(state.copyWith(searchQuery: query));

    // 清除之前的防抖定时器
    _searchDebounce?.cancel();

    if (query.isEmpty) {
      emit(state.copyWith(
        status: FundExplorationStatus.loaded,
        searchResults: state.fundRankings,
      ));
      return;
    }

    emit(state.copyWith(status: FundExplorationStatus.searching));

    // 防抖搜索
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  /// 执行搜索
  Future<void> _performSearch(String query) async {
    AppLogger.debug('🔍 FundExplorationCubit: 执行搜索 (query: $query)');

    try {
      const searchOptions = SearchOptions(
        limit: 100,
        sortBy: SearchSortBy.relevance,
        useCache: true,
        cacheResults: true,
        fuzzyThreshold: 0.6,
      );

      final searchResult =
          await _searchService.search(query, options: searchOptions);

      if (searchResult.isSuccess) {
        AppLogger.debug(
            '✅ FundExplorationCubit: 搜索完成 (${searchResult.results.length}条结果)');

        // 添加到搜索历史
        _addToSearchHistory(query);

        emit(state.copyWith(
          status: FundExplorationStatus.searched,
          searchResults: searchResult.results,
        ));
      } else {
        AppLogger.debug(
            '❌ FundExplorationCubit: 搜索失败: ${searchResult.errorMessage}');
        emit(state.copyWith(
          status: FundExplorationStatus.error,
          errorMessage: searchResult.errorMessage,
        ));
      }
    } catch (e) {
      final errorMsg = '搜索失败: $e';
      AppLogger.debug('❌ FundExplorationCubit: $errorMsg');
      emit(state.copyWith(
        status: FundExplorationStatus.error,
        errorMessage: errorMsg,
      ));
    }
  }

  /// 获取搜索建议
  List<String> getSearchSuggestions(String query) {
    return _searchService.getSearchSuggestions(query, limit: 10);
  }

  /// 获取最近搜索
  List<String> getRecentSearches() {
    return _searchService.getRecentSearches(10);
  }

  /// 应用筛选条件
  void applyFilter({
    String? fundType,
    String? sortBy,
    String? sortOrder,
    double? minReturn,
    double? maxReturn,
    String? riskLevel,
    double? minFundSize,
  }) {
    AppLogger.debug('🔍 FundExplorationCubit: 应用筛选条件');

    List<FundRanking> filteredRankings = List.from(state.searchResults);

    // 按基金类型筛选
    if (fundType != null && fundType.isNotEmpty) {
      filteredRankings = filteredRankings
          .where((r) =>
              r.fundType.contains(fundType) || r.shortType.contains(fundType))
          .toList();
    }

    // 按风险等级筛选
    if (riskLevel != null && riskLevel.isNotEmpty) {
      filteredRankings = filteredRankings
          .where((r) => r.getRiskLevel().displayName == riskLevel)
          .toList();
    }

    // 按收益率筛选
    if (minReturn != null) {
      filteredRankings =
          filteredRankings.where((r) => r.oneYearReturn >= minReturn).toList();
    }
    if (maxReturn != null) {
      filteredRankings =
          filteredRankings.where((r) => r.oneYearReturn <= maxReturn).toList();
    }

    // 按基金规模筛选
    if (minFundSize != null) {
      filteredRankings =
          filteredRankings.where((r) => r.fundSize >= minFundSize).toList();
    }

    // 排序
    if (sortBy != null) {
      switch (sortBy) {
        case 'return1Y':
          filteredRankings
              .sort((a, b) => b.oneYearReturn.compareTo(a.oneYearReturn));
          break;
        case 'return3Y':
          filteredRankings
              .sort((a, b) => b.threeYearReturn.compareTo(a.threeYearReturn));
          break;
        case 'dailyReturn':
          filteredRankings
              .sort((a, b) => b.dailyReturn.compareTo(a.dailyReturn));
          break;
        case 'fundName':
          filteredRankings.sort((a, b) => a.fundName.compareTo(b.fundName));
          break;
        case 'fundCode':
          filteredRankings.sort((a, b) => a.fundCode.compareTo(b.fundCode));
          break;
        case 'fundSize':
          filteredRankings.sort((a, b) => b.fundSize.compareTo(a.fundSize));
          break;
        case 'relevance':
          // 保持搜索结果的原始相关性排序
          break;
      }

      // 如果指定了降序，反转结果
      if (sortOrder == 'desc' && sortBy != 'fundName' && sortBy != 'fundCode') {
        filteredRankings = filteredRankings.reversed.toList();
      }
    }

    emit(state.copyWith(
      status: FundExplorationStatus.filtered,
      filteredRankings: filteredRankings,
      activeFilter: fundType ?? '',
      activeSortBy: sortBy ?? 'return1Y',
      activeSortOrder: sortOrder ?? 'desc',
    ));

    AppLogger.debug(
        '✅ FundExplorationCubit: 筛选完成，剩余${filteredRankings.length}条');
  }

  /// 应用筛选条件（别名方法，保持向后兼容）
  void applyFilters({
    String? fundType,
    String? sortBy,
    String? minReturn,
    String? maxReturn,
    String? riskLevel,
    String? minFundSize,
  }) {
    applyFilter(
      fundType: fundType,
      sortBy: sortBy,
      minReturn: minReturn != null ? double.tryParse(minReturn) : null,
      maxReturn: maxReturn != null ? double.tryParse(maxReturn) : null,
      riskLevel: riskLevel,
      minFundSize: minFundSize != null ? double.tryParse(minFundSize) : null,
    );
  }

  /// 清除对比状态
  void clearComparison() {
    // 清除选中的对比基金
    emit(state.copyWith(
      comparisonFunds: [],
      isComparing: false,
    ));
    AppLogger.debug('🗑️ FundExplorationCubit: 已清除对比状态');
  }

  /// 添加基金到对比列表
  void addToComparison(FundRanking fund) {
    final currentComparison = List<FundRanking>.from(state.comparisonFunds);

    // 检查是否已经在对比列表中
    if (currentComparison.any((f) => f.fundCode == fund.fundCode)) {
      AppLogger.debug('⚠️ FundExplorationCubit: 基金 ${fund.fundCode} 已在对比列表中');
      return;
    }

    // 限制对比基金数量（最多5个）
    if (currentComparison.length >= 5) {
      AppLogger.debug('⚠️ FundExplorationCubit: 对比列表已满（最多5个）');
      return;
    }

    currentComparison.add(fund);

    emit(state.copyWith(
      comparisonFunds: currentComparison,
      isComparing: true,
    ));

    AppLogger.debug('✅ FundExplorationCubit: 已添加基金 ${fund.fundCode} 到对比列表');
  }

  /// 从对比列表中移除基金
  void removeFromComparison(String fundCode) {
    final currentComparison = List<FundRanking>.from(state.comparisonFunds);
    currentComparison.removeWhere((f) => f.fundCode == fundCode);

    if (currentComparison.length != state.comparisonFunds.length) {
      emit(state.copyWith(
        comparisonFunds: currentComparison,
        isComparing: currentComparison.isNotEmpty,
      ));
      AppLogger.debug('✅ FundExplorationCubit: 已从对比列表移除基金 $fundCode');
    } else {
      AppLogger.debug('⚠️ FundExplorationCubit: 基金 $fundCode 不在对比列表中');
    }
  }

  /// 切换基金的对比状态
  void toggleComparison(FundRanking fund) {
    if (state.comparisonFunds.any((f) => f.fundCode == fund.fundCode)) {
      removeFromComparison(fund.fundCode);
    } else {
      addToComparison(fund);
    }
  }

  /// 通过基金代码切换收藏状态
  void toggleFavorite(String fundCode) {
    final currentFavorites = Set<String>.from(state.favoriteFunds);

    if (currentFavorites.contains(fundCode)) {
      currentFavorites.remove(fundCode);
      AppLogger.debug('💔 FundExplorationCubit: 已取消收藏基金 $fundCode');
    } else {
      currentFavorites.add(fundCode);
      AppLogger.debug('❤️ FundExplorationCubit: 已收藏基金 $fundCode');
    }

    emit(state.copyWith(favoriteFunds: currentFavorites));
  }

  /// 通过基金代码切换对比状态
  void toggleComparisonByCode(String fundCode) {
    final currentComparing = Set<String>.from(state.comparingFunds);

    if (currentComparing.contains(fundCode)) {
      currentComparing.remove(fundCode);
      AppLogger.debug('📊 FundExplorationCubit: 已移除对比基金 $fundCode');
    } else {
      // 限制对比基金数量（最多5个）
      if (currentComparing.length >= 5) {
        AppLogger.debug('⚠️ FundExplorationCubit: 对比列表已满（最多5个）');
        return;
      }
      currentComparing.add(fundCode);
      AppLogger.debug('📊 FundExplorationCubit: 已添加对比基金 $fundCode');
    }

    emit(state.copyWith(comparingFunds: currentComparing));
  }

  /// 清除搜索状态
  void clearSearch() {
    emit(state.copyWith(
      status: FundExplorationStatus.loaded,
      searchResults: [],
      searchQuery: '',
      errorMessage: null,
    ));
    AppLogger.debug('🔍 FundExplorationCubit: 已清除搜索状态');
  }

  /// 添加到搜索历史
  void addToSearchHistory(String query) {
    final currentHistory = List<String>.from(state.searchHistory);

    // 移除重复项
    currentHistory.remove(query);

    // 添加到开头
    currentHistory.insert(0, query);

    // 限制历史记录数量
    final limitedHistory = currentHistory.take(10).toList();

    emit(state.copyWith(searchHistory: limitedHistory));
    AppLogger.debug('📝 FundExplorationCubit: 已添加到搜索历史: $query');
  }

  /// 更新搜索查询
  void updateSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
    AppLogger.debug('🔍 FundExplorationCubit: 已更新搜索查询: $query');
  }

  /// 初始化方法（兼容性）
  Future<void> initialize() async {
    AppLogger.debug('🔄 FundExplorationCubit: 初始化');
    await _initialize();
  }

  /// 更新排序方式
  void updateSortBy(String sortBy) {
    AppLogger.debug('🔄 FundExplorationCubit: 更新排序方式 (sortBy: $sortBy)');

    emit(state.copyWith(
      sortBy: sortBy,
      activeSortBy: sortBy,
    ));

    // 如果有数据，重新应用排序
    if (state.searchResults.isNotEmpty) {
      _applyCurrentSorting();
    }
  }

  /// 应用当前排序
  void _applyCurrentSorting() {
    List<FundRanking> dataToSort =
        state.status == FundExplorationStatus.filtered
            ? List.from(state.filteredRankings)
            : List.from(state.searchResults);

    switch (state.sortBy) {
      case 'return1Y':
        dataToSort.sort((a, b) => b.oneYearReturn.compareTo(a.oneYearReturn));
        break;
      case 'return3Y':
        dataToSort
            .sort((a, b) => b.threeYearReturn.compareTo(a.threeYearReturn));
        break;
      case 'dailyReturn':
        dataToSort.sort((a, b) => b.dailyReturn.compareTo(a.dailyReturn));
        break;
      case 'fundName':
        dataToSort.sort((a, b) => a.fundName.compareTo(b.fundName));
        break;
      case 'fundCode':
        dataToSort.sort((a, b) => a.fundCode.compareTo(b.fundCode));
        break;
      case 'fundSize':
        dataToSort.sort((a, b) => b.fundSize.compareTo(a.fundSize));
        break;
    }

    if (state.status == FundExplorationStatus.filtered) {
      emit(state.copyWith(filteredRankings: dataToSort));
    } else {
      emit(state.copyWith(searchResults: dataToSort));
    }

    AppLogger.debug('✅ FundExplorationCubit: 排序应用完成');
  }

  /// 重置筛选条件
  void resetFilter() {
    emit(state.copyWith(
      status: FundExplorationStatus.searched,
      filteredRankings: [],
      activeFilter: '',
      activeSortBy: 'return1Y',
      activeSortOrder: 'desc',
    ));
  }

  /// 刷新数据
  Future<void> refreshData() async {
    AppLogger.debug('🔄 FundExplorationCubit: 刷新数据');
    await loadFundRankings(forceRefresh: true);
  }

  /// 强制重新加载所有数据
  Future<void> forceReloadData() async {
    AppLogger.debug('🔄 FundExplorationCubit: 强制重新加载数据');

    // 清除缓存
    try {
      await _fundDataService.clearCache();
    } catch (e) {
      AppLogger.warn('⚠️ 清除缓存失败: $e');
    }

    // 重新加载数据
    await loadFundRankings(forceRefresh: true);
  }

  /// 加载更多数据
  Future<void> loadMoreData() async {
    if (state.isLoading || !state.hasMoreData) return;

    emit(state.copyWith(isLoadingMore: true));

    try {
      // 这里可以实现分页加载逻辑
      // 暂时使用模拟的分页
      await Future.delayed(const Duration(seconds: 1));

      final currentLength = state.searchResults.length;
      final moreLength = min(20, state.fundRankings.length - currentLength);

      if (moreLength > 0) {
        final moreData =
            state.fundRankings.skip(currentLength).take(moreLength).toList();
        final allSearchResults = [...state.searchResults, ...moreData];

        emit(state.copyWith(
          searchResults: allSearchResults,
          isLoadingMore: false,
          hasMoreData: currentLength + moreLength < state.fundRankings.length,
        ));

        AppLogger.debug('📄 FundExplorationCubit: 加载更多成功，新增$moreLength条');
      } else {
        emit(state.copyWith(
          isLoadingMore: false,
          hasMoreData: false,
        ));
      }
    } catch (e) {
      AppLogger.debug('❌ FundExplorationCubit: 加载更多失败: $e');
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  /// 切换基金展开状态
  void toggleFundExpanded(String fundCode) {
    final expandedFunds = Set<String>.from(state.expandedFunds);

    if (expandedFunds.contains(fundCode)) {
      expandedFunds.remove(fundCode);
    } else {
      expandedFunds.add(fundCode);
    }

    emit(state.copyWith(expandedFunds: expandedFunds));
  }

  /// 清除错误信息
  void clearError() {
    if (state.errorMessage != null) {
      emit(state.copyWith(clearErrorMessage: true));
    }
  }

  /// 获取当前视图的数据
  List<FundRanking> get currentData {
    switch (state.status) {
      case FundExplorationStatus.searching:
      case FundExplorationStatus.searched:
        return state.searchResults;
      case FundExplorationStatus.filtered:
        return state.filteredRankings;
      default:
        return state.fundRankings;
    }
  }

  /// 检查是否为真实数据
  bool _checkIfRealData(List<FundRanking> rankings) {
    if (rankings.isEmpty) return true;

    // 检测模拟数据的模式：基金代码以1000开头且按11递增
    final isMockData = rankings.every((r) => r.fundCode.startsWith('1000')) &&
        rankings
            .map((r) => int.tryParse(r.fundCode) ?? 0)
            .every((code) => code >= 100000 && (code - 100000) % 11 == 0);

    return !isMockData;
  }

  /// 获取基金详细信息
  Future<FundDataResult<Map<String, dynamic>>> getFundDetail(
      String fundCode) async {
    AppLogger.debug('🔍 FundExplorationCubit: 获取基金详情 (fundCode: $fundCode)');
    return await _fundDataService.getFundDetail(fundCode);
  }

  /// 获取热门基金（基于收益和规模）
  List<FundRanking> getHotFunds({int limit = 10}) {
    return state.fundRankings.where((fund) => fund.isHot).take(limit).toList();
  }

  /// 获取推荐基金（基于综合评分）
  List<FundRanking> getRecommendedFunds({int limit = 10}) {
    final sortedFunds = state.fundRankings
        .map((fund) => MapEntry(fund, fund.comprehensiveScore))
        .toList();
    sortedFunds.sort((a, b) => b.value.compareTo(a.value));
    return sortedFunds.map((entry) => entry.key).take(limit).toList();
  }

  /// 获取统计信息
  FundExplorationStatistics getStatistics() {
    final rankings = state.fundRankings;
    if (rankings.isEmpty) {
      return const FundExplorationStatistics(
        totalFunds: 0,
        averageReturn: 0.0,
        bestPerformingFund: null,
        worstPerformingFund: null,
        fundTypeDistribution: {},
      );
    }

    final totalReturn =
        rankings.fold<double>(0.0, (sum, fund) => sum + fund.oneYearReturn);
    final averageReturn = totalReturn / rankings.length;

    final sortedByReturn = List<FundRanking>.from(rankings)
      ..sort((a, b) => b.oneYearReturn.compareTo(a.oneYearReturn));

    final fundTypeDistribution = <String, int>{};
    for (final fund in rankings) {
      final type = fund.shortType;
      fundTypeDistribution[type] = (fundTypeDistribution[type] ?? 0) + 1;
    }

    return FundExplorationStatistics(
      totalFunds: rankings.length,
      averageReturn: averageReturn,
      bestPerformingFund:
          sortedByReturn.isNotEmpty ? sortedByReturn.first : null,
      worstPerformingFund:
          sortedByReturn.isNotEmpty ? sortedByReturn.last : null,
      fundTypeDistribution: fundTypeDistribution,
    );
  }

  /// 添加搜索历史
  void _addToSearchHistory(String query) {
    if (query.trim().isEmpty) return;

    final trimmedQuery = query.trim();
    final currentHistory = List<String>.from(state.searchHistory);

    // 移除重复项
    currentHistory.remove(trimmedQuery);

    // 添加到开头
    currentHistory.insert(0, trimmedQuery);

    // 限制历史记录数量
    final limitedHistory = currentHistory.take(10).toList();

    emit(state.copyWith(searchHistory: limitedHistory));
  }

  /// 清空搜索历史
  void clearSearchHistory() {
    emit(state.copyWith(searchHistory: []));
  }

  /// 从搜索历史中删除特定项
  void removeFromSearchHistory(String query) {
    final currentHistory = List<String>.from(state.searchHistory);
    currentHistory.remove(query);
    emit(state.copyWith(searchHistory: currentHistory));
  }

  /// 货币基金相关方法

  /// 加载货币基金数据
  Future<void> loadMoneyFunds({bool forceRefresh = false}) async {
    if (!forceRefresh && state.isMoneyFundsLoading) {
      AppLogger.debug('⏭️ FundExplorationCubit: 正在加载货币基金，跳过重复请求');
      return;
    }

    AppLogger.debug(
        '🔄 FundExplorationCubit: 开始加载货币基金数据 (forceRefresh: $forceRefresh)');

    emit(state.copyWith(isMoneyFundsLoading: true, moneyFundsError: null));

    try {
      final result = await _moneyFundService.getMoneyFunds();

      if (result.isSuccess) {
        final moneyFunds = result.data!;

        AppLogger.debug(
            '✅ FundExplorationCubit: 货币基金数据加载成功 (${moneyFunds.length}条)');

        emit(state.copyWith(
          moneyFunds: moneyFunds,
          isMoneyFundsLoading: false,
          moneyFundsError: null,
        ));
      } else {
        emit(state.copyWith(
          isMoneyFundsLoading: false,
          moneyFundsError: result.errorMessage,
        ));
      }
    } catch (e) {
      final errorMsg = '加载货币基金失败: $e';
      AppLogger.debug('❌ FundExplorationCubit: $errorMsg');
      emit(state.copyWith(
        isMoneyFundsLoading: false,
        moneyFundsError: errorMsg,
      ));
    }
  }

  /// 搜索货币基金
  void searchMoneyFunds(String query) {
    emit(state.copyWith(searchQuery: query));

    // 清除之前的防抖定时器
    _searchDebounce?.cancel();

    if (query.isEmpty) {
      emit(state.copyWith(moneyFundSearchResults: []));
      return;
    }

    // 防抖搜索
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _performMoneyFundSearch(query);
    });
  }

  /// 执行货币基金搜索
  Future<void> _performMoneyFundSearch(String query) async {
    AppLogger.debug('🔍 FundExplorationCubit: 执行货币基金搜索 (query: $query)');

    try {
      final result = await _moneyFundService.searchMoneyFunds(query);

      if (result.isSuccess) {
        AppLogger.debug(
            '✅ FundExplorationCubit: 货币基金搜索完成 (${result.data!.length}条结果)');

        // 添加到搜索历史
        _addToSearchHistory(query);

        emit(state.copyWith(moneyFundSearchResults: result.data!));
      } else {
        AppLogger.debug(
            '❌ FundExplorationCubit: 货币基金搜索失败: ${result.errorMessage}');
        emit(state.copyWith(moneyFundsError: result.errorMessage));
      }
    } catch (e) {
      final errorMsg = '货币基金搜索失败: $e';
      AppLogger.debug('❌ FundExplorationCubit: $errorMsg');
      emit(state.copyWith(moneyFundsError: errorMsg));
    }
  }

  /// 获取高收益货币基金
  Future<void> loadTopYieldMoneyFunds({int count = 10}) async {
    AppLogger.debug('🏆 FundExplorationCubit: 获取高收益货币基金 (count: $count)');

    try {
      final result =
          await _moneyFundService.getTopYieldMoneyFunds(count: count);

      if (result.isSuccess) {
        final topFunds = result.data!;
        AppLogger.debug(
            '✅ FundExplorationCubit: 高收益货币基金获取成功 (${topFunds.length}条)');

        emit(state.copyWith(moneyFunds: topFunds));
      } else {
        AppLogger.debug(
            '❌ FundExplorationCubit: 高收益货币基金获取失败: ${result.errorMessage}');
        emit(state.copyWith(moneyFundsError: result.errorMessage));
      }
    } catch (e) {
      final errorMsg = '获取高收益货币基金失败: $e';
      AppLogger.debug('❌ FundExplorationCubit: $errorMsg');
      emit(state.copyWith(moneyFundsError: errorMsg));
    }
  }

  /// 切换到货币基金视图
  void switchToMoneyFundsView() {
    AppLogger.debug('🔄 FundExplorationCubit: 切换到货币基金视图');
    emit(state.copyWith(activeView: FundExplorationView.moneyFunds));

    // 如果货币基金数据为空，自动加载
    if (state.moneyFunds.isEmpty && !state.isMoneyFundsLoading) {
      loadMoneyFunds();
    }
  }

  /// 切换到基金排行视图
  void switchToRankingView() {
    AppLogger.debug('🔄 FundExplorationCubit: 切换到基金排行视图');
    emit(state.copyWith(activeView: FundExplorationView.ranking));
  }

  /// 切换到搜索视图
  void switchToSearchView() {
    AppLogger.debug('🔄 FundExplorationCubit: 切换到搜索视图');
    emit(state.copyWith(activeView: FundExplorationView.search));
  }

  /// 切换到对比视图
  void switchToComparisonView() {
    AppLogger.debug('🔄 FundExplorationCubit: 切换到对比视图');
    emit(state.copyWith(activeView: FundExplorationView.comparison));
  }

  /// 切换到热门视图
  void switchToHotView() {
    AppLogger.debug('🔄 FundExplorationCubit: 切换到热门视图');
    emit(state.copyWith(activeView: FundExplorationView.hot));
  }

  /// 清除货币基金搜索结果
  void clearMoneyFundSearch() {
    emit(state.copyWith(
      searchQuery: '',
      moneyFundSearchResults: [],
    ));
  }

  /// 获取货币基金统计数据
  Future<Map<String, dynamic>?> getMoneyFundStatistics() async {
    AppLogger.debug('📊 FundExplorationCubit: 获取货币基金统计数据');

    try {
      final result = await _moneyFundService.getMoneyFundStatistics();

      if (result.isSuccess) {
        AppLogger.debug('✅ FundExplorationCubit: 货币基金统计数据获取成功');
        return result.data;
      } else {
        AppLogger.debug(
            '❌ FundExplorationCubit: 货币基金统计数据获取失败: ${result.errorMessage}');
        return null;
      }
    } catch (e) {
      final errorMsg = '获取货币基金统计数据失败: $e';
      AppLogger.debug('❌ FundExplorationCubit: $errorMsg');
      return null;
    }
  }

  /// 判断错误是否适合重试
  bool _shouldRetryForError(String errorMsg) {
    // 适合重试的错误类型
    final retryableErrors = [
      '网络连接失败',
      '请求超时',
      '服务器暂时繁忙',
      '服务器响应异常',
      '当前请求过多',
      '缓存服务暂时不可用',
      '数据验证失败',
    ];

    for (final retryableError in retryableErrors) {
      if (errorMsg.contains(retryableError)) {
        return true;
      }
    }

    // 检查是否包含超时相关的关键词
    final timeoutKeywords = ['timeout', '超时', 'timeoutexception'];
    for (final keyword in timeoutKeywords) {
      if (errorMsg.toLowerCase().contains(keyword)) {
        return true;
      }
    }

    // 检查是否包含网络相关的关键词
    final networkKeywords = ['network', 'connection', 'socket', '网络', '连接'];
    for (final keyword in networkKeywords) {
      if (errorMsg.toLowerCase().contains(keyword)) {
        return true;
      }
    }

    return false;
  }

  /// 判断异常是否适合重试
  bool _shouldRetryForException(dynamic e) {
    // 这些异常类型通常可以通过重试解决
    if (e is TimeoutException) return true;
    if (e is SocketException) return true;

    // HTTP异常中，某些状态码可以重试
    if (e is HttpException) {
      final message = e.message.toLowerCase();
      // 500-599 服务器错误可以重试
      if (message.contains('500') ||
          message.contains('502') ||
          message.contains('503') ||
          message.contains('504')) {
        return true;
      }
    }

    // 检查异常消息中是否包含可重试的关键词
    final exceptionMessage = e.toString().toLowerCase();
    final retryableKeywords = [
      'timeout',
      'network',
      'connection',
      'socket',
      '超时',
      '网络',
      '连接',
      'timeoutexception'
    ];

    for (final keyword in retryableKeywords) {
      if (exceptionMessage.contains(keyword)) {
        return true;
      }
    }

    return false;
  }

  @override
  Future<void> close() {
    AppLogger.debug('🔄 FundExplorationCubit: 正在关闭Cubit');
    _isClosed = true;
    _searchDebounce?.cancel();
    return super.close();
  }
}

/// 基金探索统计信息
class FundExplorationStatistics extends Equatable {
  final int totalFunds;
  final double averageReturn;
  final FundRanking? bestPerformingFund;
  final FundRanking? worstPerformingFund;
  final Map<String, int> fundTypeDistribution;

  const FundExplorationStatistics({
    required this.totalFunds,
    required this.averageReturn,
    this.bestPerformingFund,
    this.worstPerformingFund,
    required this.fundTypeDistribution,
  });

  @override
  List<Object?> get props => [
        totalFunds,
        averageReturn,
        bestPerformingFund,
        worstPerformingFund,
        fundTypeDistribution,
      ];

  @override
  String toString() {
    return 'FundExplorationStatistics(totalFunds: $totalFunds, averageReturn: ${averageReturn.toStringAsFixed(2)}%)';
  }
}
