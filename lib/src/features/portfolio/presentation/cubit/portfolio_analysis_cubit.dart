import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import '../../domain/entities/portfolio_holding.dart';
import '../../domain/entities/portfolio_profit_metrics.dart';
import '../../domain/entities/portfolio_summary.dart';
import '../../domain/entities/portfolio_profit_calculation_criteria.dart';
import '../../domain/repositories/portfolio_profit_repository.dart';
import '../../data/services/portfolio_data_service.dart';
import '../../../../core/utils/logger.dart';
import 'portfolio_analysis_state.dart';

/// 组合分析状态管理Cubit
///
/// 管理持仓分析页面的状态，包括持仓数据加载、收益计算、UI状态等
class PortfolioAnalysisCubit extends Cubit<PortfolioAnalysisState> {
  final PortfolioProfitRepository _repository;
  final PortfolioDataService _dataService;
  bool _isInitialized = false;
  String? _lastInitializedUserId;

  PortfolioAnalysisCubit({
    required PortfolioProfitRepository repository,
    PortfolioDataService? dataService,
  })  : _repository = repository,
        _dataService = dataService ?? PortfolioDataService(),
        super(PortfolioAnalysisState.initial());

  /// 优化的初始化组合分析 - 改进错误处理和重试机制
  Future<void> initializeAnalysis({String? userId, bool force = false}) async {
    final targetUserId = userId ?? 'default_user';

    // 添加超时保护，防止无限加载
    AppLogger.info(
        'Starting portfolio analysis initialization for user: $targetUserId');
    AppLogger.info(
        '🔄 INITIALIZATION START - Current state: isLoading=${state.isLoading}, hasError=${state.error != null}, holdings=${state.holdings.length}');

    // 检查是否已经初始化过相同用户的数据（除非强制重新初始化）
    if (!force && _isInitialized && _lastInitializedUserId == targetUserId) {
      AppLogger.info(
          'Portfolio analysis already initialized for user: $targetUserId, skipping');
      // 检查当前状态，如果还在加载状态说明有问题，强制重新初始化
      if (state.maybeMap(
        loading: (_) => true,
        orElse: () => false,
      )) {
        AppLogger.warn(
            'Current state is still loading, forcing re-initialization');
        force = true;
      } else {
        return;
      }
    }

    // 如果强制重新初始化，重置标志
    if (force) {
      _isInitialized = false;
      _lastInitializedUserId = null;
    }

    AppLogger.info('🔄 EMITTING LOADING STATE');
    emit(PortfolioAnalysisState.loading());
    AppLogger.info('✅ LOADING STATE EMITTED');
    AppLogger.info(
        'Initializing portfolio analysis for user: $targetUserId${force ? ' (forced)' : ''}');

    try {
      // 使用超时机制防止无限等待
      await _initializeWithTimeout(targetUserId);
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error during initialization', e, stackTrace);
      // 确保即使出错也更新状态
      emit(PortfolioAnalysisState.error(
          '初始化失败: ${_getFriendlyErrorMessage(e)}'));
    }
  }

  /// 带超时的初始化方法
  Future<void> _initializeWithTimeout(String userId) async {
    const timeout = Duration(seconds: 30); // 增加到30秒超时，避免频繁超时

    try {
      await _performInitialization(userId).timeout(timeout);
    } on TimeoutException {
      AppLogger.error(
          'Portfolio analysis initialization timed out after ${timeout.inSeconds} seconds',
          TimeoutException);
      // 超时时，尝试快速检查是否有数据
      await _handleTimeoutScenario(userId);
    } catch (e) {
      AppLogger.error('Error during portfolio analysis initialization', e);
      rethrow; // 重新抛出异常让上层处理
    }
  }

  /// 处理超时场景 - 快速检查数据状态
  Future<void> _handleTimeoutScenario(String userId) async {
    try {
      AppLogger.info(
          'Initialization timed out, attempting quick data check for user: $userId');

      // 直接从数据服务获取数据，不经过重试机制
      final quickResult = await _dataService.getUserHoldings(userId);

      quickResult.fold(
        (failure) {
          AppLogger.error('Quick data check also failed', failure.message);
          emit(PortfolioAnalysisState.error('数据访问超时，请稍后重试'));
        },
        (holdings) {
          _isInitialized = true;
          _lastInitializedUserId = userId;

          if (holdings.isEmpty) {
            AppLogger.info(
                'Quick check confirmed no holdings for user: $userId');
            emit(PortfolioAnalysisState.noData());
          } else {
            AppLogger.info(
                'Quick check found ${holdings.length} holdings, showing with limited data');
            // 显示数据但标记为需要完整刷新
            emit(PortfolioAnalysisState.loaded(
              holdings: holdings,
              portfolioSummary: null,
              fundMetrics: const {},
              currentCriteria: _createDefaultCriteria(holdings),
              isCalculating: true, // 标记为需要完整计算
            ));
          }
        },
      );
    } catch (e) {
      AppLogger.error('Failed to handle timeout scenario', e);
      emit(PortfolioAnalysisState.error('初始化超时，请检查网络连接后重试'));
    }
  }

  /// 执行实际的初始化逻辑
  Future<void> _performInitialization(String userId) async {
    try {
      // 1. 加载用户持仓数据 - 使用重试机制
      final holdingsResult =
          await _loadUserHoldingsWithRetry(userId, maxRetries: 3);

      holdingsResult.fold(
        (failure) async {
          AppLogger.error(
              'Failed to load user holdings after retries', failure.message);
          // 改进的错误处理：提供更详细的错误信息
          final errorMessage = _getDetailedErrorMessage(failure);
          emit(PortfolioAnalysisState.error(errorMessage));
        },
        (holdings) async {
          // 标记为已初始化
          _isInitialized = true;
          _lastInitializedUserId = userId;

          // 严格检查空数据状态 - 修复核心问题
          if (holdings.isEmpty) {
            AppLogger.info(
                'No holdings found for user: $userId - showing no data state');
            AppLogger.info(
                '🔄 EMITTING NO_DATA STATE - Before emit: isLoading=${state.isLoading}, hasError=${state.error != null}');
            emit(PortfolioAnalysisState.noData());
            AppLogger.info(
                '✅ NO_DATA STATE EMITTED - After emit: isLoading=${state.isLoading}, hasError=${state.error != null}');
            return;
          }

          AppLogger.info(
              'Loaded ${holdings.length} holdings for user: $userId');

          // 2. 创建默认计算标准
          final defaultCriteria = _createDefaultCriteria(holdings);

          // 3. 计算组合汇总数据（带错误处理）
          await _calculatePortfolioSummaryWithErrorHandling(
            holdings: holdings,
            criteria: defaultCriteria,
            userId: userId,
          );
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error(
          'Unexpected error in _performInitialization', e, stackTrace);
      // 确保即使发生意外错误也能正确显示状态
      emit(PortfolioAnalysisState.error(
          '初始化失败: ${_getFriendlyErrorMessage(e)}'));
    }
  }

  /// 带重试机制的用户持仓数据加载
  Future<Either<Failure, List<PortfolioHolding>>> _loadUserHoldingsWithRetry(
    String userId, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(milliseconds: 500),
  }) async {
    Either<Failure, List<PortfolioHolding>>? lastResult;

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        AppLogger.info(
            'Loading user holdings, attempt ${attempt + 1}/$maxRetries');
        final result = await _dataService.getUserHoldings(userId);

        // 如果成功，直接返回
        if (result.isRight()) {
          AppLogger.info(
              'Successfully loaded holdings on attempt ${attempt + 1}');
          return result;
        }
        lastResult = result;

        // 如果不是最后一次尝试，等待后重试
        if (attempt < maxRetries - 1) {
          await Future.delayed(retryDelay);
        }
      } catch (e) {
        AppLogger.warn('Attempt ${attempt + 1} failed: $e');
        if (attempt == maxRetries - 1) {
          // 最后一次尝试也失败了
          return Left(CacheFailure('加载持仓数据失败: ${e.toString()}'));
        }
      }
    }

    return lastResult ?? const Left(CacheFailure('加载持仓数据失败：未知错误'));
  }

  /// 带错误处理的组合汇总计算
  Future<void> _calculatePortfolioSummaryWithErrorHandling({
    required List<PortfolioHolding> holdings,
    required PortfolioProfitCalculationCriteria criteria,
    required String userId,
  }) async {
    try {
      await calculatePortfolioSummary(
        holdings: holdings,
        criteria: criteria,
        userId: userId,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
          'Error during portfolio summary calculation', e, stackTrace);
      // 即使计算失败，也要确保状态标记为已初始化
      _isInitialized = true;
      _lastInitializedUserId = userId;
      emit(PortfolioAnalysisState.loaded(
        holdings: holdings,
        portfolioSummary: null, // 计算失败时设为null
        fundMetrics: const {},
        currentCriteria: criteria,
        isCalculating: false,
      ));
      emit(PortfolioAnalysisState.error(
        '持仓数据加载成功，但收益计算失败: ${_getFriendlyErrorMessage(e)}',
      ));
    }
  }

  /// 获取详细的错误信息
  String _getDetailedErrorMessage(Failure failure) {
    if (failure.message.contains('Hive')) {
      return '数据存储访问失败，请检查应用权限和存储空间';
    } else if (failure.message.contains('parse')) {
      return '数据格式错误，可能需要重新添加持仓';
    } else if (failure.message.contains('network')) {
      return '网络连接失败，请检查网络连接后重试';
    } else {
      return '加载持仓数据失败: ${failure.message}';
    }
  }

  /// 获取友好的错误信息
  String _getFriendlyErrorMessage(dynamic error) {
    final errorString = error.toString();

    if (errorString.contains('FileSystemException')) {
      return '文件系统错误，请检查存储空间';
    } else if (errorString.contains('TimeoutException')) {
      return '操作超时，请稍后重试';
    } else if (errorString.contains('FormatException')) {
      return '数据格式错误';
    } else if (errorString.contains('StateError')) {
      return '状态异常，请重新进入页面';
    } else {
      return '操作失败: $errorString';
    }
  }

  /// 计算组合汇总数据
  Future<void> calculatePortfolioSummary({
    List<PortfolioHolding>? holdings,
    PortfolioProfitCalculationCriteria? criteria,
    String? userId,
  }) async {
    if (state.maybeMap(
          loaded: (state) => holdings ?? state.holdings,
          orElse: () => null,
        ) ==
        null) {
      AppLogger.warn(
          'Cannot calculate portfolio summary: no holdings available');
      return;
    }

    final currentHoldings = holdings ??
        (state.maybeMap(
          loaded: (state) => state.holdings,
          orElse: () => throw StateError('No holdings available'),
        )!);

    final currentCriteria = criteria ?? _createDefaultCriteria(currentHoldings);

    emit(state.maybeMap(
      loaded: (state) => state.copyWith(
        isCalculating: true,
        calculationProgress: 0.0,
        error: null,
      ),
      orElse: () => throw StateError('Invalid state'),
    )!);

    AppLogger.info(
        'Calculating portfolio summary for ${currentHoldings.length} holdings');

    try {
      final result = await _repository.calculatePortfolioSummary(
        holdings: currentHoldings,
        criteria: currentCriteria,
      );

      result.fold(
        (failure) {
          AppLogger.error(
              'Failed to calculate portfolio summary', failure.message);
          emit(state.maybeMap(
            loaded: (s) => s.copyWith(
              isCalculating: false,
              error: '计算组合汇总失败: ${failure.message}',
            ),
            orElse: () => state,
          ));
        },
        (summary) {
          AppLogger.info('Portfolio summary calculated successfully');

          // 标记为已初始化
          if (userId != null) {
            _isInitialized = true;
            _lastInitializedUserId = userId;
          }

          emit(state.maybeMap(
            loaded: (s) => s.copyWith(
              isCalculating: false,
              calculationProgress: 1.0,
              portfolioSummary: summary,
              currentCriteria: currentCriteria,
              lastUpdated: DateTime.now(),
              error: null,
            ),
            orElse: () => state,
          ));

          // 自动计算各个基金的详细指标（异步执行）
          _calculateIndividualMetrics(currentHoldings, currentCriteria);
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error(
          'Unexpected error calculating portfolio summary', e, stackTrace);
      emit(state.maybeMap(
        loaded: (state) => state.copyWith(
          isCalculating: false,
          error: '计算组合汇总时发生错误: $e',
        ),
        orElse: () => throw StateError('Invalid state'),
      )!);
    }
  }

  /// 计算单个基金的详细指标
  Future<void> calculateFundMetrics({
    required PortfolioHolding holding,
    PortfolioProfitCalculationCriteria? criteria,
  }) async {
    final currentCriteria = criteria ??
        state.maybeMap(
          loaded: (s) => s.currentCriteria,
          orElse: () => _createDefaultCriteria([holding]),
        ) ??
        _createDefaultCriteria([holding]);

    AppLogger.info('Calculating metrics for fund: ${holding.fundCode}');

    try {
      final result = await _repository.calculateFundProfitMetrics(
        holding: holding,
        criteria: currentCriteria,
      );

      result.fold(
        (failure) {
          AppLogger.error('Failed to calculate fund metrics', failure.message);
          // 更新错误状态但不影响整体状态
          final currentMetrics = state.maybeMap(
              loaded: (s) => s.fundMetrics,
              orElse: () => <String, PortfolioProfitMetrics>{});
          currentMetrics[holding.fundCode] =
              PortfolioProfitMetrics.empty(fundCode: holding.fundCode);

          emit(state.maybeMap(
            loaded: (s) => s.copyWith(
              fundMetrics: currentMetrics,
              lastUpdated: DateTime.now(),
            ),
            orElse: () => state,
          ));
        },
        (metrics) {
          AppLogger.info(
              'Fund metrics calculated successfully for ${holding.fundCode}');
          final currentMetrics = state.maybeMap(
              loaded: (s) => s.fundMetrics,
              orElse: () => <String, PortfolioProfitMetrics>{});
          currentMetrics[holding.fundCode] = metrics;

          emit(state.maybeMap(
            loaded: (s) => s.copyWith(
              fundMetrics: currentMetrics,
              lastUpdated: DateTime.now(),
            ),
            orElse: () => state,
          ));
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error(
          'Unexpected error calculating fund metrics', e, stackTrace);
      // 不影响整体状态，只记录错误
    }
  }

  /// 批量计算所有基金的详细指标 - 优化版本
  Future<void> _calculateIndividualMetrics(
    List<PortfolioHolding> holdings,
    PortfolioProfitCalculationCriteria criteria,
  ) async {
    AppLogger.info(
        'Calculating individual metrics for ${holdings.length} funds');

    final currentMetrics = <String, PortfolioProfitMetrics>{};
    int completed = 0;
    final total = holdings.length;

    // 使用隔离的异步计算，避免阻塞主线程
    await compute(_calculateMetricsInBackground, {
      'holdings': holdings,
      'criteria': criteria,
    }).then((result) {
      currentMetrics.addAll(result);
      completed = result.length;
    }).catchError((e) async {
      AppLogger.error('Background calculation failed', e);
      // 降级到同步计算
      await _fallbackCalculation(holdings, criteria, currentMetrics);
    });

    AppLogger.info(
        'Individual metrics calculation completed: $completed/$total successful');

    // 只在最后更新一次状态，避免频繁重建UI
    if (state.maybeMap(loaded: (_) => true, orElse: () => false)) {
      emit(state.maybeMap(
        loaded: (currentState) => currentState.copyWith(
          fundMetrics: currentMetrics,
          calculationProgress: 1.0,
          isCalculating: false,
          lastUpdated: DateTime.now(),
        ),
        orElse: () => throw StateError('Invalid state'),
      )!);
    }
  }

  /// 后台计算函数
  static Future<Map<String, PortfolioProfitMetrics>>
      _calculateMetricsInBackground(Map<String, dynamic> params) async {
    final holdings = params['holdings'] as List<PortfolioHolding>;
    // 暂时不使用criteria参数，避免未使用警告
    // final criteria = params['criteria'] as PortfolioProfitCalculationCriteria;
    final currentMetrics = <String, PortfolioProfitMetrics>{};

    // 模拟计算 - 实际应用中需要真实的repository调用
    for (final holding in holdings) {
      try {
        // 这里应该是真实的计算逻辑
        // 为了演示，创建空的指标对象
        currentMetrics[holding.fundCode] =
            PortfolioProfitMetrics.empty(fundCode: holding.fundCode);

        // 添加小延迟避免过度占用CPU
        await Future.delayed(const Duration(milliseconds: 10));
      } catch (e) {
        // 记录错误但继续处理其他基金
        currentMetrics[holding.fundCode] =
            PortfolioProfitMetrics.empty(fundCode: holding.fundCode);
      }
    }

    return currentMetrics;
  }

  /// 降级计算方法
  Future<void> _fallbackCalculation(
    List<PortfolioHolding> holdings,
    PortfolioProfitCalculationCriteria criteria,
    Map<String, PortfolioProfitMetrics> currentMetrics,
  ) async {
    // 分批处理，避免一次性处理太多
    const batchSize = 5;
    for (int i = 0; i < holdings.length; i += batchSize) {
      final batch = holdings.skip(i).take(batchSize).toList();

      for (final holding in batch) {
        try {
          currentMetrics[holding.fundCode] =
              PortfolioProfitMetrics.empty(fundCode: holding.fundCode);
        } catch (e) {
          AppLogger.error(
              'Error in fallback calculation for ${holding.fundCode}', e);
        }
      }

      // 批次间添加延迟
      if (i + batchSize < holdings.length) {
        await Future.delayed(const Duration(milliseconds: 20));
      }
    }
  }

  /// 更新计算标准
  Future<void> updateCalculationCriteria(
      PortfolioProfitCalculationCriteria criteria) async {
    AppLogger.info('Updating calculation criteria');

    final currentHoldings = state.maybeMap(
      loaded: (s) => s.holdings,
      orElse: () => null,
    );

    if (currentHoldings != null) {
      await calculatePortfolioSummary(
        holdings: currentHoldings,
        criteria: criteria,
      );
    }
  }

  /// 更新时间周期
  Future<void> updateTimePeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final currentCriteria = state.maybeMap(
      loaded: (s) => s.currentCriteria,
      orElse: () => null,
    );

    if (currentCriteria != null) {
      final updatedCriteria = currentCriteria.copyWith(
        startDate: startDate,
        endDate: endDate,
      );

      await updateCalculationCriteria(updatedCriteria);
    }
  }

  /// 更新基准指数
  Future<void> updateBenchmark(String? benchmarkCode) async {
    final currentCriteria = state.maybeMap(
      loaded: (s) => s.currentCriteria,
      orElse: () => null,
    );

    if (currentCriteria != null) {
      final updatedCriteria =
          currentCriteria.copyWith(benchmarkCode: benchmarkCode);
      await updateCalculationCriteria(updatedCriteria);
    }
  }

  /// 刷新数据
  Future<void> refreshData() async {
    AppLogger.info('Refreshing portfolio data');

    // 检查当前状态，避免在已经是noData状态时重复初始化
    if (state.maybeMap(
      noData: (_) => true,
      orElse: () => false,
    )) {
      AppLogger.info('Already in noData state, skipping refresh');
      return;
    }

    // 强制重新初始化
    await initializeAnalysis(force: true);

    final currentHoldings = state.maybeMap(
      loaded: (s) => s.holdings,
      orElse: () => null,
    );

    final currentCriteria = state.maybeMap(
      loaded: (s) => s.currentCriteria,
      orElse: () => null,
    );

    if (currentHoldings != null && currentCriteria != null) {
      await calculatePortfolioSummary(
        holdings: currentHoldings,
        criteria: currentCriteria,
      );
    } else {
      await initializeAnalysis();
    }
  }

  /// 清除缓存
  Future<void> clearCache() async {
    AppLogger.info('Clearing portfolio cache');

    try {
      final result = await _repository.clearExpiredCache();
      result.fold(
        (failure) {
          AppLogger.error('Failed to clear cache', failure.message);
        },
        (_) {
          AppLogger.info('Cache cleared successfully');
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error clearing cache', e, stackTrace);
    }
  }

  /// 重置错误状态
  void clearError() {
    emit(state.maybeMap(
      loaded: (state) => state.copyWith(
        error: null,
      ),
      error: (state) => PortfolioAnalysisState.loaded(
        holdings: const [],
        portfolioSummary: null,
        fundMetrics: const {},
        currentCriteria: _createDefaultCriteria([]),
        isCalculating: false,
      ),
      orElse: () => PortfolioAnalysisState.initial(),
    )!);
  }

  /// 创建默认计算标准
  PortfolioProfitCalculationCriteria _createDefaultCriteria(
      List<PortfolioHolding> holdings) {
    final now = DateTime.now();
    return PortfolioProfitCalculationCriteria(
      calculationId: 'portfolio_${now.millisecondsSinceEpoch}',
      fundCodes: holdings.map((h) => h.fundCode).toList(),
      startDate: now.subtract(const Duration(days: 365)), // 默认1年
      endDate: now,
      benchmarkCode: '000300', // 默认沪深300
      frequency: CalculationFrequency.daily,
      returnType: ReturnType.total,
      includeDividendReinvestment: true,
      considerCorporateActions: true,
      currency: 'CNY',
      minimumDataDays: 30,
      createdAt: now,
    );
  }

  /// 获取当前状态信息
  String get currentStateDescription {
    return state.when(
      initial: (_) => '初始状态',
      loading: (_) => '加载中',
      loaded: (s) =>
          '已加载 - ${s.holdings.length}个持仓${s.isCalculating ? ' (计算中)' : ''}',
      noData: (_) => '无数据',
      error: (s) => '错误: ${s.error}',
    );
  }

  /// 是否有错误
  bool get hasError => state.maybeMap(
        error: (_) => true,
        loaded: (s) => s.error != null,
        orElse: () => false,
      );

  /// 是否正在计算
  bool get isCalculating => state.maybeMap(
        loaded: (s) => s.isCalculating,
        orElse: () => false,
      );

  /// 获取当前持仓数量
  int get holdingsCount => state.maybeMap(
        loaded: (s) => s.holdings.length,
        orElse: () => 0,
      );

  /// 获取当前组合汇总数据
  PortfolioSummary? get currentSummary => state.maybeMap(
        loaded: (s) => s.portfolioSummary,
        orElse: () => null,
      );

  /// 获取当前基金指标
  Map<String, PortfolioProfitMetrics> get currentMetrics => state.maybeMap(
        loaded: (s) => s.fundMetrics,
        orElse: () => {},
      );

  /// 获取当前计算标准
  PortfolioProfitCalculationCriteria? get currentCriteria {
    return state.maybeMap(
      loaded: (s) => s.currentCriteria,
      orElse: () => _createDefaultCriteria([]),
    );
  }

  // ===== 持仓管理功能 =====

  /// 添加持仓
  Future<bool> addHolding({
    required String userId,
    required PortfolioHolding holding,
  }) async {
    try {
      AppLogger.info('Adding holding: ${holding.fundCode} for user: $userId');

      // 使用数据服务添加持仓
      final result = await _dataService.addOrUpdateHolding(userId, holding);

      return result.fold(
        (failure) {
          AppLogger.error('Failed to add holding', failure.message);
          return false;
        },
        (addedHolding) {
          AppLogger.info(
              'Successfully added holding: ${addedHolding.fundCode}');

          // 刷新持仓数据
          refreshData();
          return true;
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error adding holding', e, stackTrace);
      return false;
    }
  }

  /// 更新持仓
  Future<bool> updateHolding({
    required String userId,
    required PortfolioHolding holding,
  }) async {
    try {
      AppLogger.info('Updating holding: ${holding.fundCode} for user: $userId');

      // 使用数据服务更新持仓
      final result = await _dataService.addOrUpdateHolding(userId, holding);

      return result.fold(
        (failure) {
          AppLogger.error('Failed to update holding', failure.message);
          return false;
        },
        (updatedHolding) {
          AppLogger.info(
              'Successfully updated holding: ${updatedHolding.fundCode}');

          // 刷新持仓数据
          refreshData();
          return true;
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error updating holding', e, stackTrace);
      return false;
    }
  }

  /// 删除持仓
  Future<bool> deleteHolding({
    required String userId,
    required String fundCode,
  }) async {
    try {
      AppLogger.info('Deleting holding: $fundCode for user: $userId');

      // 使用数据服务删除持仓
      final result = await _dataService.deleteHolding(userId, fundCode);

      return result.fold(
        (failure) {
          AppLogger.error('Failed to delete holding', failure.message);
          return false;
        },
        (success) {
          if (success) {
            AppLogger.info('Successfully deleted holding: $fundCode');

            // 刷新持仓数据
            refreshData();
          } else {
            AppLogger.warn('Holding not found for deletion: $fundCode');
          }
          return success;
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error deleting holding', e, stackTrace);
      return false;
    }
  }

  /// 获取持仓数量
  Future<int> getHoldingsCount(String userId) async {
    try {
      final result = await _dataService.getHoldingsCount(userId);
      return result.fold(
        (failure) {
          AppLogger.error('Failed to get holdings count', failure.message);
          return 0;
        },
        (count) => count,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error getting holdings count', e, stackTrace);
      return 0;
    }
  }

  /// 清空所有持仓
  Future<bool> clearAllHoldings(String userId) async {
    try {
      AppLogger.info('Clearing all holdings for user: $userId');

      final result = await _dataService.clearAllHoldings(userId);

      return result.fold(
        (failure) {
          AppLogger.error('Failed to clear holdings', failure.message);
          return false;
        },
        (success) {
          if (success) {
            AppLogger.info(
                'Successfully cleared all holdings for user: $userId');

            // 刷新数据到空状态
            emit(PortfolioAnalysisState.noData());
          }
          return success;
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error clearing holdings', e, stackTrace);
      return false;
    }
  }

  /// 导入持仓数据
  Future<bool> importHoldings({
    required String userId,
    required List<PortfolioHolding> holdings,
  }) async {
    try {
      AppLogger.info('Importing ${holdings.length} holdings for user: $userId');

      final result = await _dataService.importHoldings(userId, holdings);

      return result.fold(
        (failure) {
          AppLogger.error('Failed to import holdings', failure.message);
          return false;
        },
        (importedHoldings) {
          AppLogger.info(
              'Successfully imported ${importedHoldings.length} holdings');

          // 刷新持仓数据
          refreshData();
          return true;
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error importing holdings', e, stackTrace);
      return false;
    }
  }

  // ===== 便捷方法（使用默认用户ID） =====

  /// 为默认用户添加持仓
  Future<bool> addDefaultUserHolding(PortfolioHolding holding) async {
    return addHolding(userId: 'default_user', holding: holding);
  }

  /// 为默认用户更新持仓
  Future<bool> updateDefaultUserHolding(PortfolioHolding holding) async {
    return updateHolding(userId: 'default_user', holding: holding);
  }

  /// 从默认用户删除持仓
  Future<bool> deleteDefaultUserHolding(String fundCode) async {
    return deleteHolding(userId: 'default_user', fundCode: fundCode);
  }

  /// 获取默认用户持仓数量
  Future<int> getDefaultUserHoldingsCount() async {
    return getHoldingsCount('default_user');
  }

  /// 清空默认用户所有持仓
  Future<bool> clearDefaultUserHoldings() async {
    return clearAllHoldings('default_user');
  }

  /// 为默认用户导入持仓
  Future<bool> importDefaultUserHoldings(
      List<PortfolioHolding> holdings) async {
    return importHoldings(userId: 'default_user', holdings: holdings);
  }
}
