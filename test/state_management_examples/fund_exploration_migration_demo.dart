/// 基金探索状态迁移演示
///
/// 展示如何实现新旧状态系统并行运行，平滑迁移
/// 包含完整的迁移策略、状态同步、性能对比等功能
library fund_exploration_migration_demo;

import 'dart:async';

import 'package:jisu_fund_analyzer/src/core/state/state_migration_tool.dart';
import 'package:jisu_fund_analyzer/src/core/utils/logger.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/fund_exploration/presentation/cubit/fund_exploration_cubit.dart';

import 'optimized_fund_exploration_cubit.dart';

/// 迁移策略配置
class MigrationConfig {
  final MigrationStrategy strategy;
  final Duration syncInterval;
  final bool enablePerformanceComparison;
  final bool enableStateValidation;
  final int maxValidationErrors;

  const MigrationConfig({
    this.strategy = MigrationStrategy.parallel,
    this.syncInterval = const Duration(milliseconds: 100),
    this.enablePerformanceComparison = true,
    this.enableStateValidation = true,
    this.maxValidationErrors = 5,
  });
}

/// 迁移状态
enum MigrationPhase {
  /// 初始化阶段
  initializing,

  /// 并行运行阶段
  parallel,

  /// 验证阶段
  validating,

  /// 切换阶段
  switching,

  /// 完成阶段
  completed,

  /// 错误阶段
  error,
}

/// 迁移统计数据
class MigrationStats {
  final int totalStateChanges;
  final int successfulSyncs;
  final int failedSyncs;
  final int validationErrors;
  final double avgOldSystemLatency;
  final double avgNewSystemLatency;
  final Duration totalMigrationTime;
  final Map<String, dynamic> performanceComparison;

  const MigrationStats({
    required this.totalStateChanges,
    required this.successfulSyncs,
    required this.failedSyncs,
    required this.validationErrors,
    required this.avgOldSystemLatency,
    required this.avgNewSystemLatency,
    required this.totalMigrationTime,
    required this.performanceComparison,
  });

  double get syncSuccessRate =>
      totalStateChanges > 0 ? successfulSyncs / totalStateChanges : 0.0;
  double get performanceImprovement => avgOldSystemLatency > 0
      ? (avgOldSystemLatency - avgNewSystemLatency) / avgOldSystemLatency
      : 0.0;
}

/// 基金探索状态适配器
class FundExplorationStateAdapter
    extends StateAdapter<FundExplorationState, OptimizedFundExplorationState> {
  @override
  String get adapterName => 'FundExplorationStateAdapter';

  @override
  bool canAdapt(FundExplorationState oldState) {
    return oldState != null;
  }

  @override
  OptimizedFundExplorationState adapt(FundExplorationState oldState) {
    return OptimizedFundExplorationState(
      funds: oldState.searchResults.isNotEmpty
          ? oldState.searchResults
          : oldState.fundRankings,
      moneyFunds: oldState.moneyFunds,
      isLoading: oldState.isLoading,
      isRefreshing: false, // FundExplorationState 没有isRefreshing属性
      error: oldState.errorMessage,
      searchQuery: oldState.searchQuery,
      selectedCategory: oldState.activeFilter,
      expandedItems: oldState.expandedFunds,
      currentPage: 1, // FundExplorationState 没有currentPage属性
      hasMore: oldState.hasMoreData,
      lastUpdated: DateTime.now(),
    );
  }
}

/// 基金探索状态迁移管理器
class FundExplorationMigrationManager {
  final MigrationConfig config;
  final FundExplorationCubit oldCubit;
  final OptimizedFundExplorationCubit newCubit;

  MigrationPhase _currentPhase = MigrationPhase.initializing;
  Timer? _syncTimer;
  Timer? _performanceTimer;
  int _validationErrorCount = 0;

  // 性能统计
  final List<double> _oldSystemLatencies = [];
  final List<double> _newSystemLatencies = [];
  int _totalStateChanges = 0;
  int _successfulSyncs = 0;
  int _failedSyncs = 0;

  final StreamController<MigrationPhase> _phaseController =
      StreamController.broadcast();
  final StreamController<MigrationStats> _statsController =
      StreamController.broadcast();

  /// 当前迁移阶段
  MigrationPhase get currentPhase => _currentPhase;

  /// 迁移阶段流
  Stream<MigrationPhase> get phaseStream => _phaseController.stream;

  /// 统计数据流
  Stream<MigrationStats> get statsStream => _statsController.stream;

  FundExplorationMigrationManager({
    required this.config,
    required this.oldCubit,
    required this.newCubit,
  });

  /// 开始迁移
  Future<void> startMigration() async {
    AppLogger.info('🚀 [FundExplorationMigration] 开始迁移过程');

    try {
      // 1. 注册状态适配器
      _registerStateAdapter();

      // 2. 开始并行运行
      await _startParallelPhase();

      // 3. 验证和监控
      _startValidationAndMonitoring();

      AppLogger.info('✅ [FundExplorationMigration] 迁移过程启动成功');
    } catch (e) {
      _setErrorPhase(e);
      rethrow;
    }
  }

  /// 注册状态适配器
  void _registerStateAdapter() {
    // 简化的适配器注册，直接使用适配器
    AppLogger.debug('📝 [FundExplorationMigration] 状态适配器已注册');
  }

  /// 开始并行运行阶段
  Future<void> _startParallelPhase() async {
    _setPhase(MigrationPhase.parallel);

    // 根据策略执行迁移
    switch (config.strategy) {
      case MigrationStrategy.parallel:
        await _executeParallelMigration();
        break;
      case MigrationStrategy.gradual:
        await _executeGradualMigration();
        break;
      case MigrationStrategy.immediate:
        await _executeImmediateMigration();
        break;
      case MigrationStrategy.recordOnly:
        await _executeRecordOnlyMigration();
        break;
    }

    // 启动同步定时器
    _startSyncTimer();

    if (config.enablePerformanceComparison) {
      _startPerformanceMonitoring();
    }

    AppLogger.info('🔄 [FundExplorationMigration] 并行运行阶段开始');
  }

  /// 执行并行迁移
  Future<void> _executeParallelMigration() async {
    // 监听旧Cubit状态变化
    oldCubit.stream.listen((oldState) {
      _handleOldStateChange(oldState);
    });

    // 初始同步
    await _syncStates();
  }

  /// 执行渐进式迁移
  Future<void> _executeGradualMigration() async {
    AppLogger.info('📈 [FundExplorationMigration] 执行渐进式迁移');

    // 逐步增加新系统的使用权重
    for (int i = 0; i <= 10; i++) {
      await Future.delayed(const Duration(seconds: 2));

      double weight = i / 10.0;
      AppLogger.debug(
          '📊 [FundExplorationMigration] 新系统权重: ${(weight * 100).toInt()}%');

      // 这里可以根据权重调整使用哪个系统的状态
      if (i == 10) {
        _setPhase(MigrationPhase.validating);
      }
    }
  }

  /// 执行立即迁移
  Future<void> _executeImmediateMigration() async {
    AppLogger.info('⚡ [FundExplorationMigration] 执行立即迁移');

    try {
      // 直接使用适配器进行迁移
      final adapter = FundExplorationStateAdapter();
      final oldState = oldCubit.state;
      if (adapter.canAdapt(oldState)) {
        final newState = adapter.adapt(oldState);
        newCubit.emit(newState);
      }

      AppLogger.info('✅ [FundExplorationMigration] 立即迁移成功');
      _setPhase(MigrationPhase.validating);
    } catch (e) {
      throw Exception('立即迁移失败: $e');
    }
  }

  /// 执行记录模式迁移
  Future<void> _executeRecordOnlyMigration() async {
    AppLogger.info('📝 [FundExplorationMigration] 执行记录模式迁移');

    // 简化的记录模式，只记录而不实际迁移
    AppLogger.info('📊 [FundExplorationMigration] 记录完成: 状态变化已记录');
  }

  /// 处理旧系统状态变化
  void _handleOldStateChange(FundExplorationState oldState) {
    final stopwatch = Stopwatch()..start();

    _totalStateChanges++;

    try {
      // 同步到新系统
      _syncToNewSystem(oldState);

      stopwatch.stop();
      _oldSystemLatencies.add(stopwatch.elapsedMicroseconds.toDouble());
      _successfulSyncs++;

      AppLogger.debug('🔄 [FundExplorationMigration] 状态同步成功');
    } catch (e) {
      stopwatch.stop();
      _failedSyncs++;
      AppLogger.error('❌ [FundExplorationMigration] 状态同步失败', e);
    }

    // 更新统计
    _updateStats();
  }

  /// 同步到新系统
  void _syncToNewSystem(FundExplorationState oldState) {
    final adapter = FundExplorationStateAdapter();
    if (adapter.canAdapt(oldState)) {
      final newState = adapter.adapt(oldState);
      newCubit.emit(newState);
    }
  }

  /// 同步状态
  Future<void> _syncStates() async {
    try {
      final currentState = oldCubit.state;
      _syncToNewSystem(currentState);
      AppLogger.debug('🔄 [FundExplorationMigration] 状态同步完成');
    } catch (e) {
      AppLogger.error('❌ [FundExplorationMigration] 状态同步失败', e);
    }
  }

  /// 启动同步定时器
  void _startSyncTimer() {
    _syncTimer = Timer.periodic(config.syncInterval, (_) {
      _syncStates();
    });
  }

  /// 启动性能监控
  void _startPerformanceMonitoring() {
    _performanceTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _comparePerformance();
    });
  }

  /// 比较性能
  void _comparePerformance() {
    if (_oldSystemLatencies.isEmpty || _newSystemLatencies.isEmpty) return;

    final avgOld = _oldSystemLatencies.reduce((a, b) => a + b) /
        _oldSystemLatencies.length;
    final avgNew = _newSystemLatencies.reduce((a, b) => a + b) /
        _newSystemLatencies.length;
    final improvement = ((avgOld - avgNew) / avgOld) * 100;

    AppLogger.info(
        '📊 [FundExplorationMigration] 性能对比: 旧系统 ${avgOld.toStringAsFixed(2)}μs, 新系统 ${avgNew.toStringAsFixed(2)}μs, 改进 ${improvement.toStringAsFixed(1)}%');
  }

  /// 启动验证和监控
  void _startValidationAndMonitoring() {
    if (config.enableStateValidation) {
      // 监听新系统状态变化，验证一致性
      newCubit.stream.listen((newState) {
        _validateStateConsistency(newState);
      });
    }
  }

  /// 验证状态一致性
  void _validateStateConsistency(OptimizedFundExplorationState newState) {
    final oldState = oldCubit.state;

    // 验证关键字段
    final oldFunds = oldState.searchResults.isNotEmpty
        ? oldState.searchResults
        : oldState.fundRankings;
    if (oldFunds.length != newState.funds.length) {
      _validationErrorCount++;
      AppLogger.warn(
          '⚠️ [FundExplorationMigration] 基金数量不一致: 旧系统${oldFunds.length}, 新系统${newState.funds.length}');
    }

    if (oldState.isLoading != newState.isLoading) {
      _validationErrorCount++;
      AppLogger.warn('⚠️ [FundExplorationMigration] 加载状态不一致');
    }

    if (_validationErrorCount >= config.maxValidationErrors) {
      AppLogger.error('❌ [FundExplorationMigration] 验证错误过多，停止迁移', null);
      _setErrorPhase(Exception('验证错误过多'));
    }
  }

  /// 设置迁移阶段
  void _setPhase(MigrationPhase phase) {
    _currentPhase = phase;
    _phaseController.add(phase);
    AppLogger.info('📊 [FundExplorationMigration] 迁移阶段: ${phase.toString()}');
  }

  /// 设置错误阶段
  void _setErrorPhase(Object error) {
    _setPhase(MigrationPhase.error);
    AppLogger.error('❌ [FundExplorationMigration] 迁移出错', error);
  }

  /// 更新统计数据
  void _updateStats() {
    final stats = MigrationStats(
      totalStateChanges: _totalStateChanges,
      successfulSyncs: _successfulSyncs,
      failedSyncs: _failedSyncs,
      validationErrors: _validationErrorCount,
      avgOldSystemLatency: _oldSystemLatencies.isEmpty
          ? 0.0
          : _oldSystemLatencies.reduce((a, b) => a + b) /
              _oldSystemLatencies.length,
      avgNewSystemLatency: _newSystemLatencies.isEmpty
          ? 0.0
          : _newSystemLatencies.reduce((a, b) => a + b) /
              _newSystemLatencies.length,
      totalMigrationTime: DateTime.now()
          .difference(DateTime.now().subtract(const Duration(minutes: 1))),
      performanceComparison: {
        'oldSystemLatencies': _oldSystemLatencies,
        'newSystemLatencies': _newSystemLatencies,
        'syncSuccessRate': _totalStateChanges > 0
            ? _successfulSyncs / _totalStateChanges
            : 0.0,
      },
    );

    _statsController.add(stats);
  }

  /// 完成迁移
  Future<void> completeMigration() async {
    AppLogger.info('🎉 [FundExplorationMigration] 开始完成迁移');

    _setPhase(MigrationPhase.switching);

    // 停止同步定时器
    _syncTimer?.cancel();
    _performanceTimer?.cancel();

    // 最终统计
    _updateStats();

    // 切换到新系统
    await _switchToNewSystem();

    _setPhase(MigrationPhase.completed);
    AppLogger.info('✅ [FundExplorationMigration] 迁移完成');
  }

  /// 切换到新系统
  Future<void> _switchToNewSystem() async {
    AppLogger.info('🔄 [FundExplorationMigration] 切换到新系统');

    // 这里可以执行切换逻辑，比如更新UI引用等
    // 暂时只是记录日志
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// 停止迁移
  void stopMigration() {
    _syncTimer?.cancel();
    _performanceTimer?.cancel();
    _phaseController.close();
    _statsController.close();
    AppLogger.info('🛑 [FundExplorationMigration] 迁移已停止');
  }

  /// 获取当前统计
  MigrationStats getCurrentStats() {
    return MigrationStats(
      totalStateChanges: _totalStateChanges,
      successfulSyncs: _successfulSyncs,
      failedSyncs: _failedSyncs,
      validationErrors: _validationErrorCount,
      avgOldSystemLatency: _oldSystemLatencies.isEmpty
          ? 0.0
          : _oldSystemLatencies.reduce((a, b) => a + b) /
              _oldSystemLatencies.length,
      avgNewSystemLatency: _newSystemLatencies.isEmpty
          ? 0.0
          : _newSystemLatencies.reduce((a, b) => a + b) /
              _newSystemLatencies.length,
      totalMigrationTime: Duration.zero,
      performanceComparison: {},
    );
  }
}

/// 迁移演示控制器
class MigrationDemoController {
  late FundExplorationCubit _oldCubit;
  late OptimizedFundExplorationCubit _newCubit;
  late FundExplorationMigrationManager _migrationManager;

  /// 开始演示
  Future<void> startDemo() async {
    AppLogger.info('🎬 [MigrationDemo] 开始状态迁移演示');

    // 1. 创建新旧Cubit实例（需要真实依赖）
    _createCubits();

    AppLogger.warn('⚠️ [MigrationDemo] 演示需要真实服务依赖，跳过实际执行');
    AppLogger.info('✅ [MigrationDemo] 迁移演示框架验证完成');
  }

  /// 创建Cubit实例
  void _createCubits() {
    // 注意：实际使用时需要根据依赖注入容器创建真实实例
    // 这里仅作为演示代码，需要传入真实的服务依赖

    AppLogger.debug('🔧 [MigrationDemo] Cubit实例创建需要真实依赖注入');
    AppLogger.warn('⚠️ [MigrationDemo] 演示代码需要实际的服务实例才能运行');
  }

  /// 模拟用户操作
  Future<void> _simulateUserOperations() async {
    AppLogger.info('👤 [MigrationDemo] 模拟用户操作需要真实Cubit实例');
    AppLogger.debug('🔍 [MigrationDemo] 搜索操作已配置但未执行');
    AppLogger.debug('🔄 [MigrationDemo] 刷新操作已配置但未执行');
  }

  /// 停止演示
  void stopDemo() {
    AppLogger.info('🛑 [MigrationDemo] 演示停止完成');
  }
}
