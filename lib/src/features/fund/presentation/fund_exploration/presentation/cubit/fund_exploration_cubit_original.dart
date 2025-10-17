import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jisu_fund_analyzer/src/core/di/hive_injection_container.dart';
import '../../domain/data/services/fund_service.dart';

import '../../domain/repositories/cache_repository.dart';

import '../../domain/models/fund.dart';
import '../../domain/models/fund_filter.dart';

part 'fund_exploration_state.dart';

/// 基金探索页面状态管理
///
/// 负责管理基金数据的加载、搜索、筛选、排序等状态
/// 提供统一的接口供UI组件调用
class FundExplorationCubit extends Cubit<FundExplorationState> {
  final FundService _fundService;
  final CacheRepository _cacheRepository;

  FundExplorationCubit(
      {FundService? fundService, CacheRepository? cacheRepository})
      : _fundService = fundService ?? HiveInjectionContainer.sl<FundService>(),
        _cacheRepository =
            cacheRepository ?? HiveInjectionContainer.sl<CacheRepository>(),
        super(FundExplorationState());

  /// 初始化加载基金数据（完全轻量级初始化，不加载任何实际数据）
  Future<void> initialize() async {
    emit(state.copyWith(status: FundExplorationStatus.loading));

    try {
      // 完全不加载数据，只做状态初始化
      debugPrint('🔄 完全轻量级初始化，不加载任何实际数据...');

      emit(state.copyWith(
        status: FundExplorationStatus.loaded,
        funds: [], // 空数组，数据完全按需加载
        hotFunds: [], // 空数组，等待按需加载
        fundRankings: [], // 空数组，等待按需加载
      ));

      debugPrint('✅ 完全轻量级初始化完成');
    } catch (e) {
      debugPrint('❌ 轻量级初始化失败: $e');
      emit(state.copyWith(
        status: FundExplorationStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// 按需加载热门基金（缓存优先策略）
  Future<void> loadHotFunds() async {
    if (state.hotFunds.isNotEmpty) {
      debugPrint('✅ 热门基金已加载，跳过重复加载');
      return;
    }

    // 检查Bloc是否已关闭
    if (isClosed) {
      debugPrint('⚠️ Bloc已关闭，跳过热门基金加载');
      return;
    }

    emit(state.copyWith(status: FundExplorationStatus.loading));

    try {
      debugPrint('🔄 开始加载热门基金...');

      // 首先尝试从缓存获取
      final cachedHotFunds = await _cacheRepository.getCachedFunds('hot_funds');
      final isCacheExpired = await _cacheRepository.isCacheExpired('hot_funds');

      if (cachedHotFunds != null &&
          cachedHotFunds.isNotEmpty &&
          !isCacheExpired) {
        debugPrint('✅ 从缓存获取热门基金，共 ${cachedHotFunds.length} 条（缓存未过期）');

        // 检查Bloc是否已关闭
        if (!isClosed) {
          emit(state.copyWith(
            hotFunds: cachedHotFunds,
            status: FundExplorationStatus.loaded,
          ));
        }

        // 异步刷新缓存数据（后台更新）
        _refreshHotFundsInBackground();
        return;
      } else if (cachedHotFunds != null &&
          cachedHotFunds.isNotEmpty &&
          isCacheExpired) {
        debugPrint('⚠️ 热门基金缓存数据已过期，先显示旧数据，后台更新新数据...');

        // 检查Bloc是否已关闭
        if (!isClosed) {
          emit(state.copyWith(
            hotFunds: cachedHotFunds,
            status: FundExplorationStatus.loaded,
          ));
        }

        // 后台异步更新数据
        _refreshHotFundsInBackground();
        return;
      }

      // 缓存不存在，从API加载
      final hotFunds = await _loadHotFunds();

      // 缓存新数据
      await _cacheRepository.cacheFunds('hot_funds', hotFunds,
          ttl: const Duration(minutes: 15));

      // 检查Bloc是否已关闭
      if (!isClosed) {
        emit(state.copyWith(
          hotFunds: hotFunds,
          status: FundExplorationStatus.loaded,
        ));
      }

      debugPrint('✅ 热门基金加载完成，共 ${hotFunds.length} 条');
    } catch (e) {
      debugPrint('❌ 热门基金加载失败: $e');

      // 检查Bloc是否已关闭
      if (!isClosed) {
        emit(state.copyWith(
          hotFunds: [], // 空数组表示加载失败
          status: FundExplorationStatus.loaded,
          errorMessage: '热门基金加载失败: $e',
        ));
      }
    }
  }

  /// 按需加载基金排行（缓存优先策略）
  Future<void> loadFundRankings() async {
    await _loadFundRankingsWithPage(page: 1);
  }

  /// 加载更多基金排行（分页加载）
  Future<void> loadMoreFundRankings() async {
    final currentPage = state.fundRankingsPage;
    final nextPage = currentPage + 1;

    if (!state.hasMoreFundRankings) {
      debugPrint('⚠️ 没有更多基金排行数据');
      return;
    }

    debugPrint('🔄 加载更多基金排行，第 $nextPage 页');
    await _loadFundRankingsWithPage(page: nextPage, isLoadMore: true);
  }

  /// 频率限制状态跟踪
  DateTime? _lastRateLimitTime;
  Duration _rateLimitBackoff = const Duration(seconds: 3);
  int _rateLimitRetryCount = 0;
  static const int maxRateLimitRetries = 3;

  /// 检查是否应该跳过API调用（避免频率限制）
  bool _shouldSkipApiCall() {
    if (_lastRateLimitTime == null) return false;

    final now = DateTime.now();
    final timeSinceLastLimit = now.difference(_lastRateLimitTime!);

    // 如果距离上次频率限制时间很短，跳过API调用
    if (timeSinceLastLimit < const Duration(seconds: 10)) {
      debugPrint(
          '⚠️ _shouldSkipApiCall: 距离上次频率限制仅${timeSinceLastLimit.inSeconds}秒，跳过API调用');
      return true;
    }

    return false;
  }

  /// 记录频率限制事件
  void _recordRateLimit() {
    _lastRateLimitTime = DateTime.now();
    _rateLimitRetryCount++;

    // 指数退避策略
    if (_rateLimitRetryCount > 1) {
      _rateLimitBackoff = _rateLimitBackoff * 2;
      if (_rateLimitBackoff > const Duration(minutes: 5)) {
        _rateLimitBackoff = const Duration(minutes: 5); // 最大退避时间
      }
    }

    debugPrint(
        '📊 _recordRateLimit: 记录频率限制，重试次数: $_rateLimitRetryCount, 退避时间: ${_rateLimitBackoff.inSeconds}秒');
  }

  /// 重置频率限制状态
  void _resetRateLimit() {
    if (_rateLimitRetryCount > 0) {
      debugPrint('🔄 _resetRateLimit: 重置频率限制状态');
      _rateLimitRetryCount = 0;
      _rateLimitBackoff = const Duration(seconds: 3);
      _lastRateLimitTime = null;
    }
  }

  Future<void> _loadFundRankingsWithPage({
    required int page,
    bool isLoadMore = false,
  }) async {
    // 检查是否应该跳过API调用以避免频率限制
    if (_shouldSkipApiCall()) {
      debugPrint('⚠️ _loadFundRankingsWithPage: 跳过API调用以避免频率限制');
      emit(state.copyWith(
        status: FundExplorationStatus.loaded,
        errorMessage: 'API调用过于频繁，请稍后再试',
      ));
      return;
    }
    // 修改逻辑：即使是非加载更多情况，如果当前是模拟数据，也应该重新加载真实数据
    if (!isLoadMore &&
        state.fundRankings.isNotEmpty &&
        state.isFundRankingsRealData) {
      debugPrint('✅ 基金排行真实数据已加载，跳过重复加载');
      return;
    }

    emit(state.copyWith(status: FundExplorationStatus.loading));

    // 移除加载超时保护机制 - 让请求自然完成或失败
    // 避免因网络延迟导致的过早状态变更
    // final loadTimeout = Timer(Duration(seconds: 45), () {
    //   if (state.status == FundExplorationStatus.loading) {
    //     debugPrint('⚠️ _loadFundRankingsWithPage: 加载超时保护触发，强制设置完成状态');
    //     emit(state.copyWith(
    //       status: FundExplorationStatus.loaded,
    //       errorMessage: '数据加载超时，请稍后重试',
    //     ));
    //   }
    // });

    try {
      debugPrint('🔄 开始加载基金排行...');

      // 首先尝试从缓存获取
      final cachedRankingsData =
          await _cacheRepository.getCachedFundRankings('all');
      const cacheKey = 'fund_rankings_all';
      final isCacheExpired = await _cacheRepository.isCacheExpired(cacheKey);

      // 优化缓存策略：根据数据新鲜度调整缓存时间
      final cacheAge = await _cacheRepository.getCacheAge(cacheKey);

      debugPrint(
          '🔍 缓存检查: 数据存在=${cachedRankingsData != null}, 未过期=${!isCacheExpired}, 缓存时间=${cacheAge?.inMinutes}分钟');

      if (cachedRankingsData != null &&
          cachedRankingsData.isNotEmpty &&
          !isCacheExpired) {
        debugPrint('✅ 从缓存获取基金排行，共 ${cachedRankingsData.length} 条（缓存未过期）');

        // 将缓存数据转换为FundRanking对象
        final cachedRankings = cachedRankingsData
            .map((data) => FundRanking(
                  fundCode: data['基金代码'] ?? '',
                  fundName: data['基金简称'] ?? '',
                  fundType: data['基金类型'] ?? '',
                  company: data['公司名称'] ?? '',
                  rankingPosition: data['序号'] ?? 0,
                  totalCount: data['总数'] ?? 0,
                  unitNav: (data['单位净值'] ?? 0).toDouble(),
                  accumulatedNav: (data['累计净值'] ?? 0).toDouble(),
                  dailyReturn: (data['日增长率'] ?? 0).toDouble(),
                  return1W: (data['近1周'] ?? 0).toDouble(),
                  return1M: (data['近1月'] ?? 0).toDouble(),
                  return3M: (data['近3月'] ?? 0).toDouble(),
                  return6M: (data['近6月'] ?? 0).toDouble(),
                  return1Y: (data['近1年'] ?? 0).toDouble(),
                  return2Y: (data['近2年'] ?? 0).toDouble(),
                  return3Y: (data['近3年'] ?? 0).toDouble(),
                  returnYTD: (data['今年来'] ?? 0).toDouble(),
                  returnSinceInception: (data['成立来'] ?? 0).toDouble(),
                  date: data['日期'] ?? DateTime.now().toIso8601String(),
                  fee: (data['手续费'] ?? 0).toDouble(),
                ))
            .toList();

        // 检测缓存数据是否为模拟数据
        final isCachedMockData = cachedRankings.isNotEmpty &&
            cachedRankings.every((r) => r.fundCode.startsWith('1000')) &&
            cachedRankings
                .map((r) => int.tryParse(r.fundCode) ?? 0)
                .every((code) => code >= 100000 && (code - 100000) % 11 == 0);

        if (isCachedMockData) {
          debugPrint('⚠️ _loadFundRankingsWithPage: 检测到缓存中的模拟数据');
        } else {
          debugPrint('✅ _loadFundRankingsWithPage: 检测到缓存中的真实数据');
        }

        emit(state.copyWith(
          fundRankings: cachedRankings,
          status: FundExplorationStatus.loaded,
          isFundRankingsRealData: !isCachedMockData, // 根据检测结果设置是否为真实数据
        ));

        // 异步刷新缓存数据（后台更新）
        _refreshFundRankingsInBackground();
        return;
      } else if (cachedRankingsData != null &&
          cachedRankingsData.isNotEmpty &&
          isCacheExpired) {
        debugPrint('⚠️ 缓存数据已过期，先显示旧数据，后台更新新数据...');

        // 将缓存数据转换为FundRanking对象
        final cachedRankings = cachedRankingsData
            .map((data) => FundRanking(
                  fundCode: data['基金代码'] ?? '',
                  fundName: data['基金简称'] ?? '',
                  fundType: data['基金类型'] ?? '',
                  company: data['公司名称'] ?? '',
                  rankingPosition: data['序号'] ?? 0,
                  totalCount: data['总数'] ?? 0,
                  unitNav: (data['单位净值'] ?? 0).toDouble(),
                  accumulatedNav: (data['累计净值'] ?? 0).toDouble(),
                  dailyReturn: (data['日增长率'] ?? 0).toDouble(),
                  return1W: (data['近1周'] ?? 0).toDouble(),
                  return1M: (data['近1月'] ?? 0).toDouble(),
                  return3M: (data['近3月'] ?? 0).toDouble(),
                  return6M: (data['近6月'] ?? 0).toDouble(),
                  return1Y: (data['近1年'] ?? 0).toDouble(),
                  return2Y: (data['近2年'] ?? 0).toDouble(),
                  return3Y: (data['近3年'] ?? 0).toDouble(),
                  returnYTD: (data['今年来'] ?? 0).toDouble(),
                  returnSinceInception: (data['成立来'] ?? 0).toDouble(),
                  date: data['日期'] ?? DateTime.now().toIso8601String(),
                  fee: (data['手续费'] ?? 0).toDouble(),
                ))
            .toList();

        // 检测缓存数据是否为模拟数据
        final isCachedMockData = cachedRankings.isNotEmpty &&
            cachedRankings.every((r) => r.fundCode.startsWith('1000')) &&
            cachedRankings
                .map((r) => int.tryParse(r.fundCode) ?? 0)
                .every((code) => code >= 100000 && (code - 100000) % 11 == 0);

        if (isCachedMockData) {
          debugPrint('⚠️ _loadFundRankingsWithPage: 检测到缓存中的模拟数据');
        } else {
          debugPrint('✅ _loadFundRankingsWithPage: 检测到缓存中的真实数据');
        }

        emit(state.copyWith(
          fundRankings: cachedRankings,
          status: FundExplorationStatus.loaded,
          isFundRankingsRealData: !isCachedMockData, // 根据检测结果设置是否为真实数据
        ));

        // 后台异步更新数据
        _refreshFundRankingsInBackground();
        return;
      }

      // 缓存不存在，从API加载（支持分页）
      debugPrint('🔄 开始从API加载基金排行数据...');
      final rankings = await _loadFundRankings(
        page: state.fundRankingsPage,
        pageSize: state.fundRankingsPageSize,
      );
      debugPrint('✅ API数据加载成功，获取到 ${rankings.length} 条基金排行数据');

      // 检测是否为模拟数据（基金代码以1000开头且按11递增）
      final isMockData = rankings.isNotEmpty &&
          rankings.every((r) => r.fundCode.startsWith('1000')) &&
          rankings
              .map((r) => int.tryParse(r.fundCode) ?? 0)
              .every((code) => code >= 100000 && (code - 100000) % 11 == 0);

      if (isMockData) {
        debugPrint('⚠️ _loadFundRankingsWithPage: 检测到模拟数据，标记为非真实数据');
      } else {
        debugPrint('✅ _loadFundRankingsWithPage: 检测到真实数据');
      }

      // 分页数据合并逻辑
      debugPrint(
          '📊 分页数据处理: 当前${state.fundRankings.length}条 + 新${rankings.length}条');

      // 根据是否加载更多来决定是追加还是替换数据
      final updatedRankings =
          state.fundRankings.isNotEmpty && state.fundRankingsPage > 1
              ? [...state.fundRankings, ...rankings]
              : rankings;

      // 判断是否还有更多数据（如果返回数据少于请求数量，说明是最后一页）
      final hasMoreData = rankings.length >= state.fundRankingsPageSize;

      debugPrint(
          '✅ 分页数据合并完成，总计${updatedRankings.length}条，还有更多数据: $hasMoreData');

      // 缓存新数据
      debugPrint('💾 开始缓存基金排行数据...');
      try {
        // 检查数据类型并转换
        debugPrint('🔍 _loadFundRankingsWithPage: 检查数据类型...');
        debugPrint(
            '🔍 _loadFundRankingsWithPage: rankings类型: ${rankings.runtimeType}');
        debugPrint(
            '🔍 _loadFundRankingsWithPage: rankings长度: ${rankings.length}');

        if (rankings.isNotEmpty) {
          debugPrint(
              '🔍 _loadFundRankingsWithPage: 第一条数据类型: ${rankings.first.runtimeType}');
          debugPrint('🔍 _loadFundRankingsWithPage: 准备转换为Map格式...');
        }

        final rankingsMap = rankings
            .map((ranking) => {
                  '基金代码': ranking.fundCode,
                  '基金简称': ranking.fundName,
                  '基金类型': ranking.fundType,
                  '公司名称': ranking.company,
                  '序号': ranking.rankingPosition,
                  '总数': ranking.totalCount,
                  '单位净值': ranking.unitNav,
                  '累计净值': ranking.accumulatedNav,
                  '日增长率': ranking.dailyReturn,
                  '近1周': ranking.return1W,
                  '近1月': ranking.return1M,
                  '近3月': ranking.return3M,
                  '近6月': ranking.return6M,
                  '近1年': ranking.return1Y,
                  '近2年': ranking.return2Y,
                  '近3年': ranking.return3Y,
                  '今年来': ranking.returnYTD,
                  '成立来': ranking.returnSinceInception,
                  '日期': ranking.date,
                  '手续费': ranking.fee,
                })
            .toList();

        debugPrint('✅ _loadFundRankingsWithPage: 数据转换完成，准备缓存...');
        await _cacheRepository.cacheFundRankings('all', rankingsMap,
            ttl: const Duration(minutes: 30));
        debugPrint('✅ _loadFundRankingsWithPage: 数据缓存完成');
      } catch (cacheError) {
        debugPrint('⚠️ _loadFundRankingsWithPage: 缓存失败，但不影响数据展示: $cacheError');
        // 缓存失败不影响主要功能，继续执行
      }

      debugPrint('📤 开始更新状态...');
      emit(state.copyWith(
        fundRankings: updatedRankings,
        fundRankingsPage: state.fundRankingsPage + (hasMoreData ? 1 : 0),
        hasMoreFundRankings: hasMoreData,
        status: FundExplorationStatus.loaded,
        isFundRankingsRealData: !isMockData, // 根据检测结果设置是否为真实数据
      ));

      debugPrint('✅ 基金排行加载完成，共 ${rankings.length} 条');
    } catch (e, stackTrace) {
      debugPrint('❌ _loadFundRankingsWithPage: 基金排行加载失败');
      debugPrint('❌ _loadFundRankingsWithPage: 错误类型: ${e.runtimeType}');
      debugPrint('❌ _loadFundRankingsWithPage: 错误信息: $e');
      debugPrint('❌ _loadFundRankingsWithPage: 堆栈信息: $stackTrace');

      // 区分不同类型的错误，提供更友好的错误信息
      String errorMessage;
      bool isRateLimitError = false;

      if (e.toString().contains('timeout') ||
          e.toString().contains('Timeout')) {
        errorMessage = '网络连接超时，请检查网络后重试';
      } else if (e.toString().contains('frequency') ||
          e.toString().contains('频率') ||
          e.toString().contains('rate limit')) {
        errorMessage = '请求过于频繁，请稍后再试';
        isRateLimitError = true;
      } else if (e.toString().contains('connection') ||
          e.toString().contains('Connection')) {
        errorMessage = '网络连接失败，请检查网络设置';
      } else {
        errorMessage =
            '基金排行数据加载失败: ${e.toString().substring(0, e.toString().length > 100 ? 100 : e.toString().length)}';
      }

      debugPrint('❌ _loadFundRankingsWithPage: 设置错误信息: $errorMessage');

      // 如果是频率限制错误，尝试使用缓存数据作为降级方案
      if (isRateLimitError) {
        debugPrint('⚠️ _loadFundRankingsWithPage: 频率限制错误，尝试使用缓存数据降级...');
        try {
          final cachedRankingsData =
              await _cacheRepository.getCachedFundRankings('all');
          if (cachedRankingsData != null && cachedRankingsData.isNotEmpty) {
            debugPrint(
                '✅ _loadFundRankingsWithPage: 使用缓存数据降级，共${cachedRankingsData.length}条数据');

            // 转换缓存数据
            final cachedRankings = cachedRankingsData
                .map((data) => FundRanking(
                      fundCode: data['基金代码'] ?? '',
                      fundName: data['基金简称'] ?? '',
                      fundType: data['基金类型'] ?? '',
                      company: data['公司名称'] ?? '',
                      rankingPosition: data['序号'] ?? 0,
                      totalCount: data['总数'] ?? 0,
                      unitNav: (data['单位净值'] ?? 0).toDouble(),
                      accumulatedNav: (data['累计净值'] ?? 0).toDouble(),
                      dailyReturn: (data['日增长率'] ?? 0).toDouble(),
                      return1W: (data['近1周'] ?? 0).toDouble(),
                      return1M: (data['近1月'] ?? 0).toDouble(),
                      return3M: (data['近3月'] ?? 0).toDouble(),
                      return6M: (data['近6月'] ?? 0).toDouble(),
                      return1Y: (data['近1年'] ?? 0).toDouble(),
                      return2Y: (data['近2年'] ?? 0).toDouble(),
                      return3Y: (data['近3年'] ?? 0).toDouble(),
                      returnYTD: (data['今年来'] ?? 0).toDouble(),
                      returnSinceInception: (data['成立来'] ?? 0).toDouble(),
                      date: data['日期'] ?? DateTime.now().toIso8601String(),
                      fee: (data['手续费'] ?? 0).toDouble(),
                    ))
                .toList();

            emit(state.copyWith(
              fundRankings: cachedRankings,
              status: FundExplorationStatus.loaded,
              errorMessage: '当前使用缓存数据（$errorMessage）',
            ));
            return; // 成功使用缓存数据，直接返回
          } else {
            debugPrint('⚠️ _loadFundRankingsWithPage: 无可用缓存数据');
          }
        } catch (cacheError) {
          debugPrint('⚠️ _loadFundRankingsWithPage: 缓存降级失败: $cacheError');
        }
      }

      // 如果没有缓存数据或缓存也失败，则显示错误状态
      emit(state.copyWith(
        fundRankings: [], // 空数组表示加载失败
        status: FundExplorationStatus.loaded,
        errorMessage: errorMessage,
      ));
    }
  }

  /// 后台刷新热门基金数据（静默更新）
  Future<void> _refreshHotFundsInBackground() async {
    try {
      debugPrint('🔄 后台静默刷新热门基金数据...');
      final newHotFunds = await _loadHotFunds();

      // 更新缓存
      await _cacheRepository.cacheFunds('hot_funds', newHotFunds,
          ttl: const Duration(minutes: 15));

      // 静默更新状态（不显示加载状态）
      // 检查Bloc是否已关闭
      if (!isClosed) {
        emit(state.copyWith(
          hotFunds: newHotFunds,
          // 保持当前状态，不显示加载指示器
        ));
        debugPrint('✅ 后台静默刷新完成，更新 ${newHotFunds.length} 条热门基金数据');
      }
    } catch (e) {
      debugPrint('⚠️ 后台静默刷新失败: $e');
      // 后台刷新失败不显示错误，保持现有数据
    }
  }

  /// 后台刷新基金排行数据（静默更新）
  Future<void> _refreshFundRankingsInBackground() async {
    try {
      debugPrint('🔄 后台静默刷新基金排行数据...');
      final newRankings = await _loadFundRankings(
        page: 1, // 默认第一页
        pageSize: 50, // 限制后台刷新数据量，避免过多请求
      );

      // 更新缓存（转换为Map格式，使用与API一致的中文字段名）
      final rankingsData = newRankings
          .map((ranking) => {
                '基金代码': ranking.fundCode,
                '基金简称': ranking.fundName,
                '基金类型': ranking.fundType,
                '公司名称': ranking.company,
                '序号': ranking.rankingPosition,
                '总数': ranking.totalCount,
                '单位净值': ranking.unitNav,
                '累计净值': ranking.accumulatedNav,
                '日增长率': ranking.dailyReturn,
                '近1周': ranking.return1W,
                '近1月': ranking.return1M,
                '近3月': ranking.return3M,
                '近6月': ranking.return6M,
                '近1年': ranking.return1Y,
                '近2年': ranking.return2Y,
                '近3年': ranking.return3Y,
                '今年来': ranking.returnYTD,
                '成立来': ranking.returnSinceInception,
                '日期': ranking.date,
                '手续费': ranking.fee,
              })
          .toList();

      await _cacheRepository.cacheFundRankings('all', rankingsData,
          ttl: const Duration(minutes: 30));

      // 静默更新状态（不显示加载状态）
      // 后台刷新成功，更新状态
      debugPrint("✅ 后台静默刷新成功，共${newRankings.length}条数据");

      // 检查Bloc是否已关闭
      if (!isClosed) {
        emit(state.copyWith(
          status: FundExplorationStatus.loaded,
        ));
      }
    } catch (e) {
      debugPrint('⚠️ 后台静默刷新失败: $e');
      // 后台刷新失败不显示错误，保持现有数据
    }
  }

  /// 加载热门基金
  Future<List<Fund>> _loadHotFunds() async {
    try {
      final hotFundsDto = await _fundService.getHotFunds(limit: 10);
      return hotFundsDto.map((dto) => dto.toDomainModel()).toList();
    } catch (e) {
      // 返回模拟数据作为后备
      return _getMockHotFunds();
    }
  }

  /// 强制重新加载基金排行（即使有数据也重新加载）
  Future<void> forceReloadFundRankings() async {
    debugPrint('🔄 forceReloadFundRankings: 强制重新加载基金排行数据');

    // 重置分页信息
    emit(state.copyWith(
      fundRankingsPage: 1,
      hasMoreFundRankings: true,
    ));

    // 强制重新加载，忽略现有数据
    await _loadFundRankingsWithPage(
      page: 1,
      isLoadMore: false,
    );
  }

  /// 加载基金排行榜（支持分页参数）- 增强版频率限制处理
  Future<List<FundRanking>> _loadFundRankings(
      {int? page, int? pageSize}) async {
    try {
      debugPrint('🔄 _loadFundRankings: 开始加载基金排行榜...');

      // 添加分页参数支持，优化API调用
      // 根据当前状态计算分页参数
      final currentPage = page ?? state.fundRankingsPage;
      final currentPageSize = pageSize ?? state.fundRankingsPageSize;

      debugPrint(
          '📄 _loadFundRankings: 分页参数 - 第$currentPage页, 每页$currentPageSize条');

      debugPrint('📡 _loadFundRankings: 调用API服务...');
      final rankingsDto = await _fundService.getFundRankings(
        symbol: '', // 设置基金类型
        pageSize: currentPageSize, // 设置分页大小
        enableCache: true, // 启用缓存
        timeout: const Duration(seconds: 60), // 设置超时时间（修复45秒超时问题）
      );

      debugPrint(
          '✅ _loadFundRankings: API数据加载成功，获取到 ${rankingsDto.length} 条数据');

      // 转换并返回数据
      debugPrint('🔄 _loadFundRankings: 开始转换数据格式...');
      final rankings = rankingsDto.map((dto) => dto.toDomainModel()).toList();

      debugPrint('✅ _loadFundRankings: 数据转换完成，共 ${rankings.length} 条');

      // 检测是否为模拟数据（基金代码以1000开头且按11递增）
      final isMockData = rankings.isNotEmpty &&
          rankings.every((r) => r.fundCode.startsWith('1000')) &&
          rankings
              .map((r) => int.tryParse(r.fundCode) ?? 0)
              .every((code) => code >= 100000 && (code - 100000) % 11 == 0);

      if (isMockData) {
        debugPrint('⚠️ _loadFundRankings: 检测到模拟数据，标记为非真实数据');
      } else {
        debugPrint('✅ _loadFundRankings: 检测到真实数据');
      }

      debugPrint('📤 _loadFundRankings: 准备返回数据...');
      return rankings;
    } catch (e, stackTrace) {
      debugPrint('❌ _loadFundRankings: 加载基金排行榜失败');
      debugPrint('❌ _loadFundRankings: 错误类型: ${e.runtimeType}');
      debugPrint('❌ _loadFundRankings: 错误信息: $e');
      debugPrint('❌ _loadFundRankings: 堆栈信息: $stackTrace');

      // 智能频率限制处理
      if (e.toString().contains('频率限制') ||
          e.toString().contains('冷却') ||
          e.toString().contains('冷却期') ||
          e.toString().contains('cooldown') ||
          e.toString().contains('rate limit')) {
        debugPrint('⏰ _loadFundRankings: 检测到频率限制，分析冷却信息...');

        // 记录频率限制事件
        _recordRateLimit();

        // 尝试从错误信息中提取冷却时间
        Duration waitTime = _rateLimitBackoff; // 使用当前退避时间
        String errorMsg = e.toString();

        // 解析冷却时间（支持多种格式）
        // 格式1: "冷却至 2025-09-29 20:21:38.536214（冷却时间：8秒）"
        // 格式2: "冷却时间：8秒"
        // 格式3: "冷却期：8秒"

        // 尝试提取秒数
        final secondPatterns = [
          RegExp(r'冷却时间：(\d+)秒'),
          RegExp(r'冷却期：(\d+)秒'),
          RegExp(r'冷却时间:(\d+)秒'),
          RegExp(r'\((\d+)秒\)'),
          RegExp(r'(\d+)秒'),
        ];

        for (final pattern in secondPatterns) {
          final match = pattern.firstMatch(errorMsg);
          if (match != null) {
            final seconds = int.tryParse(match.group(1) ?? '3') ?? 3;
            waitTime = Duration(seconds: seconds + 2); // 额外加2秒确保冷却完成
            debugPrint(
                '⏰ _loadFundRankings: 提取到冷却时间: $seconds秒，实际等待: ${seconds + 2}秒');
            break;
          }
        }

        // 尝试提取具体时间（如果存在）
        final timePattern =
            RegExp(r'冷却至 (\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})');
        final timeMatch = timePattern.firstMatch(errorMsg);
        if (timeMatch != null) {
          try {
            final targetTimeStr = timeMatch.group(1)!;
            final targetTime = DateTime.parse(targetTimeStr);
            final now = DateTime.now();
            final calculatedWait = targetTime.difference(now);

            if (calculatedWait.inMilliseconds > 0) {
              waitTime = calculatedWait +
                  const Duration(milliseconds: 200); // 额外加200毫秒
              debugPrint(
                  '⏰ _loadFundRankings: 提取到目标时间: $targetTimeStr，计算等待时间: ${waitTime.inMilliseconds}毫秒');
            }
          } catch (e) {
            debugPrint('⚠️ _loadFundRankings: 解析时间失败，使用默认等待时间');
          }
        }

        // 检查是否超过最大重试次数
        if (_rateLimitRetryCount >= maxRateLimitRetries) {
          debugPrint(
              '⚠️ _loadFundRankings: 超过最大重试次数($maxRateLimitRetries)，停止重试');
          throw Exception('API频率限制，请稍后再试（已重试$_rateLimitRetryCount次）');
        }

        debugPrint(
            '⏰ _loadFundRankings: 等待 ${waitTime.inSeconds} 秒后重试（第$_rateLimitRetryCount次）...');
        await Future.delayed(waitTime);

        // 重试一次
        try {
          debugPrint('🔄 _loadFundRankings: 重试加载基金排行榜...');
          final rankingsDto = await _fundService.getFundRankings(
            symbol: '', // 设置基金类型
            pageSize: 50, // 设置默认分页大小
            timeout: const Duration(seconds: 60), // 设置超时时间（修复45秒超时问题）
          );

          // 重试成功，重置频率限制状态
          _resetRateLimit();
          debugPrint('✅ _loadFundRankings: 重试成功，获取到 ${rankingsDto.length} 条数据');

          // 检测是否为模拟数据（基金代码以100000开头且按11递增）
          final retryRankings =
              rankingsDto.map((dto) => dto.toDomainModel()).toList();
          final isRetryMockData = retryRankings.isNotEmpty &&
              retryRankings.every((r) => r.fundCode.startsWith('10000')) &&
              retryRankings
                  .map((r) => int.tryParse(r.fundCode) ?? 0)
                  .every((code) => code >= 100000 && (code - 100000) % 11 == 0);

          if (isRetryMockData) {
            debugPrint('⚠️ _loadFundRankings: 重试后检测到模拟数据');
          } else {
            debugPrint('✅ _loadFundRankings: 重试后检测到真实数据');
          }

          return retryRankings;
        } catch (retryError) {
          debugPrint('❌ _loadFundRankings: 重试失败: $retryError');

          // 如果还是频率限制，继续记录但不等待（由调用方决定是否继续重试）
          if (retryError.toString().contains('频率限制') ||
              retryError.toString().contains('冷却')) {
            debugPrint('⏰ _loadFundRankings: 仍然是频率限制，已记录退避策略');
          }
        }
      }

      // 不再使用模拟数据降级，抛出异常让UI处理空状态
      debugPrint('❌ 无法加载基金排行数据，抛出异常');
      throw Exception('基金排行数据加载失败，请稍后重试');
    }
  }

  /// 搜索基金
  Future<void> searchFunds(String query) async {
    if (query.isEmpty) {
      emit(state.copyWith(searchResults: [], searchQuery: ''));
      return;
    }

    emit(state.copyWith(
      status: FundExplorationStatus.searching,
      searchQuery: query,
    ));

    try {
      final searchResults = await _fundService.searchFunds(
        query: query,
        limit: 20,
      );

      final funds = searchResults.map((dto) => dto.toDomainModel()).toList();

      emit(state.copyWith(
        status: FundExplorationStatus.loaded,
        searchResults: funds,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FundExplorationStatus.error,
        errorMessage: '搜索失败: ${e.toString()}',
      ));
    }
  }

  /// 应用筛选条件
  Future<void> applyFilters(FundFilter filter) async {
    emit(state.copyWith(
      status: FundExplorationStatus.filtering,
      currentFilter: filter,
    ));

    try {
      // 根据筛选条件调用相应的API
      final filteredFunds = await _loadFilteredFunds(filter);

      emit(state.copyWith(
        status: FundExplorationStatus.loaded,
        filteredFunds: filteredFunds,
        activeView: FundExplorationView.filtered,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FundExplorationStatus.error,
        errorMessage: '筛选失败: ${e.toString()}',
      ));
    }
  }

  /// 加载筛选后的基金
  Future<List<Fund>> _loadFilteredFunds(FundFilter filter) async {
    try {
      // 构建API参数
      final page = filter.page ?? 1;
      final pageSize = filter.pageSize ?? 20;
      final fundsDto = await _fundService.getFundBasicInfo(
        limit: pageSize,
        offset: (page - 1) * pageSize,
        fundType: filter.fundTypes.isNotEmpty ? filter.fundTypes.first : null,
        company: filter.companies?.isNotEmpty == true
            ? filter.companies!.first
            : null,
      );

      return fundsDto.map((dto) => dto.toDomainModel()).toList();
    } catch (e) {
      // 不再使用模拟数据降级，抛出异常让UI处理空状态
      debugPrint('❌ 无法加载筛选基金数据: $e');
      throw Exception('基金筛选数据加载失败，请稍后重试');
    }
  }

  /// 切换视图
  void switchView(FundExplorationView view) {
    emit(state.copyWith(activeView: view));
  }

  /// 添加基金到对比列表
  void addToComparison(Fund fund) {
    final currentComparison = List<Fund>.from(state.comparisonFunds);
    if (currentComparison.length < 5 && !currentComparison.contains(fund)) {
      currentComparison.add(fund);
      emit(state.copyWith(comparisonFunds: currentComparison));
    }
  }

  /// 从对比列表移除基金
  void removeFromComparison(Fund fund) {
    final currentComparison = List<Fund>.from(state.comparisonFunds);
    currentComparison.remove(fund);
    emit(state.copyWith(comparisonFunds: currentComparison));
  }

  /// 清空对比列表
  void clearComparison() {
    emit(state.copyWith(comparisonFunds: []));
  }

  /// 更新排序方式
  void updateSortBy(String sortBy) {
    emit(state.copyWith(sortBy: sortBy));
    _applySorting(sortBy);
  }

  /// 应用排序
  void _applySorting(String sortBy) {
    final currentFunds = List<Fund>.from(state.displayFunds);

    switch (sortBy) {
      case 'return1Y':
        currentFunds.sort((a, b) => b.return1Y.compareTo(a.return1Y));
        break;
      case 'return3Y':
        currentFunds.sort((a, b) => b.return3Y.compareTo(a.return3Y));
        break;
      case 'scale':
        currentFunds.sort((a, b) => b.scale.compareTo(a.scale));
        break;
      case 'name':
        currentFunds.sort((a, b) => a.name.compareTo(b.name));
        break;
      default:
        // 默认按代码排序
        currentFunds.sort((a, b) => a.code.compareTo(b.code));
    }

    emit(state.copyWith(
      funds: state.activeView == FundExplorationView.all
          ? currentFunds
          : state.funds,
      filteredFunds: state.activeView == FundExplorationView.filtered
          ? currentFunds
          : state.filteredFunds,
      searchResults: state.activeView == FundExplorationView.search
          ? currentFunds
          : state.searchResults,
    ));
  }

  /// 刷新数据
  Future<void> refreshData() async {
    emit(state.copyWith(isRefreshing: true));

    try {
      // 清理过期缓存
      await clearExpiredCache();

      await initialize();
    } catch (e) {
      emit(state.copyWith(
        status: FundExplorationStatus.error,
        errorMessage: e.toString(),
      ));
    } finally {
      emit(state.copyWith(isRefreshing: false));
    }
  }

  /// 清理所有缓存
  Future<void> clearAllCache() async {
    try {
      await HiveInjectionContainer.clearCache();
      debugPrint('所有缓存已清理');
    } catch (e) {
      debugPrint('清理缓存失败: $e');
    }
  }

  /// 清理过期缓存
  Future<void> clearExpiredCache() async {
    try {
      await HiveInjectionContainer.clearExpiredCache();
      debugPrint('过期缓存已清理');
    } catch (e) {
      debugPrint('清理过期缓存失败: $e');
    }
  }

  /// 获取缓存统计信息
  Map<String, dynamic> getCacheStats() {
    return HiveInjectionContainer.getCacheStats();
  }

  // 模拟数据方法
  List<Fund> _getMockHotFunds() {
    return [
      Fund(
        code: '005827',
        name: '易方达蓝筹精选混合',
        type: '混合型',
        company: '易方达基金',
        manager: '张坤',
        return1W: 2.15,
        return1M: 8.92,
        return3M: 15.67,
        return6M: 28.45,
        return1Y: 22.34,
        return3Y: 45.67,
        scale: 234.56,
        riskLevel: 'R3',
        status: 'active',
      ),
      Fund(
        code: '161005',
        name: '富国天惠成长混合',
        type: '混合型',
        company: '富国基金',
        manager: '朱少醒',
        return1W: 1.87,
        return1M: 7.23,
        return3M: 12.45,
        return6M: 22.34,
        return1Y: 19.67,
        return3Y: 38.92,
        scale: 189.23,
        riskLevel: 'R3',
        status: 'active',
      ),
      Fund(
        code: '260108',
        name: '景顺长城新兴成长混合',
        type: '混合型',
        company: '景顺长城基金',
        manager: '刘彦春',
        return1W: 2.34,
        return1M: 9.12,
        return3M: 18.23,
        return6M: 32.45,
        return1Y: 25.67,
        return3Y: 52.34,
        scale: 156.78,
        riskLevel: 'R3',
        status: 'active',
      ),
    ];
  }

  @override
  Future<void> close() {
    _fundService.dispose();
    return super.close();
  }
}
