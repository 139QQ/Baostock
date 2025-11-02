/// 状态迁移工具
///
/// 帮助从现有状态管理平滑迁移到统一状态管理
library state_migration_tool;

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'optimized_cubit.dart';
import '../utils/logger.dart';

/// 迁移策略
enum MigrationStrategy {
  /// 立即迁移
  immediate,

  /// 渐进式迁移
  gradual,

  /// 并行运行
  parallel,

  /// 仅记录，不迁移
  recordOnly,
}

/// 迁移结果
class MigrationResult {
  final String componentId;
  final bool success;
  final String? error;
  final int migratedStates;
  final Duration migrationTime;
  final Map<String, dynamic> metadata;

  const MigrationResult({
    required this.componentId,
    required this.success,
    this.error,
    required this.migratedStates,
    required this.migrationTime,
    this.metadata = const {},
  });

  @override
  String toString() {
    return 'MigrationResult(componentId: $componentId, success: $success, migratedStates: $migratedStates, time: ${migrationTime.inMilliseconds}ms)';
  }
}

/// 状态适配器接口
abstract class StateAdapter<OldState, NewState> {
  /// 适配旧状态到新状态
  NewState adapt(OldState oldState);

  /// 是否可以适配
  bool canAdapt(OldState oldState);

  /// 获取适配器名称
  String get adapterName;
}

/// 默认状态适配器
class DefaultStateAdapter<OldState, NewState>
    extends StateAdapter<OldState, NewState> {
  final NewState Function(OldState) adapterFunction;
  final bool Function(OldState) canAdaptFunction;
  final String name;

  DefaultStateAdapter({
    required this.adapterFunction,
    required this.canAdaptFunction,
    required this.name,
  });

  @override
  NewState adapt(OldState oldState) => adapterFunction(oldState);

  @override
  bool canAdapt(OldState oldState) => canAdaptFunction(oldState);

  @override
  String get adapterName => name;
}

/// 状态迁移管理器
class StateMigrationManager {
  static StateMigrationManager? _instance;
  static StateMigrationManager get instance {
    _instance ??= StateMigrationManager._();
    return _instance!;
  }

  StateMigrationManager._();

  final Map<String, StateAdapter> _adapters = {};
  final Map<String, MigrationResult> _migrationHistory = {};
  final Map<String, bool> _migrationLocks = {};

  /// 注册状态适配器
  void registerAdapter<OldState, NewState>(
    String componentId,
    StateAdapter<OldState, NewState> adapter,
  ) {
    _adapters[componentId] = adapter;
    AppLogger.debug('📝 状态适配器已注册: $componentId -> ${adapter.adapterName}');
  }

  /// 注册函数式适配器
  void registerFunctionAdapter<OldState, NewState>(
    String componentId,
    NewState Function(OldState) adapter,
    bool Function(OldState) canAdapt,
    String name,
  ) {
    registerAdapter(
      componentId,
      DefaultStateAdapter<OldState, NewState>(
        adapterFunction: adapter,
        canAdaptFunction: canAdapt,
        name: name,
      ),
    );
  }

  /// 迁移单个组件
  Future<MigrationResult> migrateComponent<OldState, NewState>({
    required String componentId,
    required Cubit<OldState> oldCubit,
    required OptimizedCubit<NewState> newCubit,
    MigrationStrategy strategy = MigrationStrategy.immediate,
    bool preserveHistory = true,
  }) async {
    if (_migrationLocks[componentId] == true) {
      return MigrationResult(
        componentId: componentId,
        success: false,
        error: '组件正在迁移中',
        migratedStates: 0,
        migrationTime: Duration.zero,
      );
    }

    _migrationLocks[componentId] = true;
    final stopwatch = Stopwatch()..start();

    try {
      AppLogger.info('🔄 开始迁移组件: $componentId (策略: $strategy)');

      final adapter = _adapters[componentId];
      if (adapter == null) {
        throw Exception('未找到组件 $componentId 的状态适配器');
      }

      int migratedStates = 0;

      switch (strategy) {
        case MigrationStrategy.immediate:
          migratedStates = await _migrateImmediately(
            oldCubit,
            newCubit,
            adapter,
          );
          break;

        case MigrationStrategy.gradual:
          migratedStates = await _migrateGradually(
            oldCubit,
            newCubit,
            adapter,
          );
          break;

        case MigrationStrategy.parallel:
          migratedStates = await _migrateParallel(
            oldCubit,
            newCubit,
            adapter,
          );
          break;

        case MigrationStrategy.recordOnly:
          migratedStates = await _recordMigration(
            oldCubit,
            newCubit,
            adapter,
          );
          break;
      }

      stopwatch.stop();

      final result = MigrationResult(
        componentId: componentId,
        success: true,
        migratedStates: migratedStates,
        migrationTime: stopwatch.elapsed,
        metadata: {
          'strategy': strategy.toString(),
          'adapterName': adapter.adapterName,
        },
      );

      _migrationHistory[componentId] = result;

      AppLogger.info(
          '✅ 组件迁移完成: $componentId (${result.migratedStates}个状态, ${result.migrationTime.inMilliseconds}ms)');

      return result;
    } catch (e) {
      stopwatch.stop();

      final result = MigrationResult(
        componentId: componentId,
        success: false,
        error: e.toString(),
        migratedStates: 0,
        migrationTime: stopwatch.elapsed,
      );

      _migrationHistory[componentId] = result;

      AppLogger.error('❌ 组件迁移失败: $componentId', e);

      return result;
    } finally {
      _migrationLocks[componentId] = false;
    }
  }

  /// 立即迁移
  Future<int> _migrateImmediately<OldState, NewState>(
    Cubit<OldState> oldCubit,
    OptimizedCubit<NewState> newCubit,
    StateAdapter<OldState, NewState> adapter,
  ) async {
    final currentState = oldCubit.state;
    if (!adapter.canAdapt(currentState)) {
      throw Exception('无法适配当前状态: ${currentState.runtimeType}');
    }

    final newState = adapter.adapt(currentState);
    newCubit.emit(newState);

    AppLogger.debug(
        '⚡ 立即迁移完成: ${currentState.runtimeType} -> ${newState.runtimeType}');

    return 1;
  }

  /// 渐进式迁移
  Future<int> _migrateGradually<OldState, NewState>(
    Cubit<OldState> oldCubit,
    OptimizedCubit<NewState> newCubit,
    StateAdapter<OldState, NewState> adapter,
  ) async {
    int migratedStates = 0;
    StreamSubscription? subscription;

    try {
      // 监听旧Cubit的状态变化
      subscription = oldCubit.stream.listen((oldState) {
        if (adapter.canAdapt(oldState)) {
          final newState = adapter.adapt(oldState);
          newCubit.emit(newState);
          migratedStates++;
          AppLogger.debug('📈 渐进式迁移: $migratedStates 个状态');
        }
      });

      // 等待一段时间让初始状态迁移完成
      await Future.delayed(const Duration(milliseconds: 100));

      return migratedStates;
    } finally {
      await subscription?.cancel();
    }
  }

  /// 并行迁移
  Future<int> _migrateParallel<OldState, NewState>(
    Cubit<OldState> oldCubit,
    OptimizedCubit<NewState> newCubit,
    StateAdapter<OldState, NewState> adapter,
  ) async {
    int migratedStates = 0;

    // 迁移当前状态
    final currentState = oldCubit.state;
    if (adapter.canAdapt(currentState)) {
      final newState = adapter.adapt(currentState);
      newCubit.emit(newState);
      migratedStates++;
    }

    // 设置并行监听
    StreamSubscription? subscription;
    try {
      subscription = oldCubit.stream.listen((oldState) {
        if (adapter.canAdapt(oldState)) {
          final newState = adapter.adapt(oldState);
          // 在下一个微任务中发射状态，避免递归
          Future.microtask(() {
            if (!newCubit.isClosed) {
              newCubit.emit(newState);
              migratedStates++;
            }
          });
        }
      });

      // 等待一段时间让初始状态迁移完成
      await Future.delayed(const Duration(milliseconds: 100));

      return migratedStates;
    } finally {
      await subscription?.cancel();
    }
  }

  /// 仅记录迁移
  Future<int> _recordMigration<OldState, NewState>(
    Cubit<OldState> oldCubit,
    OptimizedCubit<NewState> newCubit,
    StateAdapter<OldState, NewState> adapter,
  ) async {
    final currentState = oldCubit.state;
    int migratedStates = 0;

    if (adapter.canAdapt(currentState)) {
      final newState = adapter.adapt(currentState);
      // 仅记录，不实际迁移
      AppLogger.debug(
          '📝 记录迁移: ${currentState.runtimeType} -> ${newState.runtimeType}');
      migratedStates++;
    }

    // 设置监听记录后续状态变化
    StreamSubscription? subscription;
    try {
      subscription = oldCubit.stream.listen((oldState) {
        if (adapter.canAdapt(oldState)) {
          final newState = adapter.adapt(oldState);
          AppLogger.debug(
              '📝 记录状态变化: ${oldState.runtimeType} -> ${newState.runtimeType}');
          migratedStates++;
        }
      });

      await Future.delayed(const Duration(milliseconds: 100));

      return migratedStates;
    } finally {
      await subscription?.cancel();
    }
  }

  /// 批量迁移
  Future<List<MigrationResult>> migrateBatch(List<MigrationTask> tasks) async {
    AppLogger.info('🔄 开始批量迁移 ${tasks.length} 个组件');

    final results = <MigrationResult>[];
    final futures = tasks.map((task) => task.execute()).toList();

    // 并行执行所有迁移任务
    final batchResults = await Future.wait(futures);
    results.addAll(batchResults);

    final successCount = results.where((r) => r.success).length;
    final failureCount = results.length - successCount;

    AppLogger.info('✅ 批量迁移完成: $successCount 成功, $failureCount 失败');

    return results;
  }

  /// 获取迁移历史
  MigrationResult? getMigrationHistory(String componentId) {
    return _migrationHistory[componentId];
  }

  /// 获取所有迁移历史
  Map<String, MigrationResult> getAllMigrationHistory() {
    return Map.from(_migrationHistory);
  }

  /// 清理迁移历史
  void clearMigrationHistory({String? componentId}) {
    if (componentId != null) {
      _migrationHistory.remove(componentId);
    } else {
      _migrationHistory.clear();
    }
    AppLogger.debug('🧹 迁移历史已清理');
  }

  /// 生成迁移报告
  Map<String, dynamic> generateMigrationReport() {
    final allResults = _migrationHistory.values.toList();
    final successCount = allResults.where((r) => r.success).length;
    final failureCount = allResults.length - successCount;

    final totalStates = allResults.fold<int>(
      0,
      (sum, result) => sum + result.migratedStates,
    );

    final totalTime = allResults.fold<Duration>(
      Duration.zero,
      (sum, result) => sum + result.migrationTime,
    );

    return {
      'totalComponents': allResults.length,
      'successfulMigrations': successCount,
      'failedMigrations': failureCount,
      'successRate': allResults.isNotEmpty
          ? '${(successCount / allResults.length * 100).toStringAsFixed(2)}%'
          : '0%',
      'totalStatesMigrated': totalStates,
      'totalMigrationTime': '${totalTime.inMilliseconds}ms',
      'averageMigrationTime': allResults.isNotEmpty
          ? '${(totalTime.inMilliseconds / allResults.length).toStringAsFixed(2)}ms'
          : '0ms',
      'registeredAdapters': _adapters.length,
      'activeLocks': _migrationLocks.values.where((locked) => locked).length,
      'migrationDetails': allResults.map((r) => r.toString()).toList(),
    };
  }
}

/// 迁移任务
class MigrationTask {
  final String componentId;
  final Function() migrationFunction;

  MigrationTask({
    required this.componentId,
    required this.migrationFunction,
  });

  Future<MigrationResult> execute() async {
    try {
      final result = await migrationFunction();
      if (result is MigrationResult) {
        return result;
      }
      throw Exception('迁移函数返回了无效结果');
    } catch (e) {
      return MigrationResult(
        componentId: componentId,
        success: false,
        error: e.toString(),
        migratedStates: 0,
        migrationTime: Duration.zero,
      );
    }
  }
}

/// 迁移工具类
class MigrationUtils {
  /// 创建简单的状态适配器
  static StateAdapter<OldState, NewState>
      createSimpleAdapter<OldState, NewState>(
    NewState Function(OldState) adapter,
    String name,
  ) {
    return DefaultStateAdapter<OldState, NewState>(
      adapterFunction: adapter,
      canAdaptFunction: (oldState) => true,
      name: name,
    );
  }

  /// 创建条件状态适配器
  static StateAdapter<OldState, NewState>
      createConditionalAdapter<OldState, NewState>(
    NewState Function(OldState) adapter,
    bool Function(OldState) condition,
    String name,
  ) {
    return DefaultStateAdapter<OldState, NewState>(
      adapterFunction: adapter,
      canAdaptFunction: condition,
      name: name,
    );
  }

  /// 创建类型检查适配器
  static StateAdapter<OldState, NewState> createTypeAdapter<OldState, NewState>(
    NewState Function(OldState) adapter,
    Type expectedOldType,
    String name,
  ) {
    return DefaultStateAdapter<OldState, NewState>(
      adapterFunction: adapter,
      canAdaptFunction: (oldState) => oldState.runtimeType == expectedOldType,
      name: name,
    );
  }

  /// 创建空安全适配器
  static StateAdapter<OldState?, NewState>
      createNullSafeAdapter<OldState, NewState>(
    NewState Function(OldState) adapter,
    NewState defaultValue,
    String name,
  ) {
    return DefaultStateAdapter<OldState?, NewState>(
      adapterFunction: (oldState) =>
          oldState != null ? adapter(oldState) : defaultValue,
      canAdaptFunction: (oldState) => true,
      name: name,
    );
  }
}
