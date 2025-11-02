/// 统一状态管理器
///
/// 基于现有代码优化的状态管理解决方案，提供：
/// - 统一的状态变更追踪
/// - 防抖机制优化
/// - 资源管理自动化
/// - 状态持久化支持
library unified_state_manager;

import 'dart:async';
import 'dart:collection';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../utils/logger.dart';

/// 状态变更记录
class StateChangeRecord extends Equatable {
  final String componentId;
  final String changeType;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic>? fromState;
  final Map<String, dynamic>? toState;
  final int duration;

  const StateChangeRecord({
    required this.componentId,
    required this.changeType,
    required this.description,
    required this.timestamp,
    this.fromState,
    this.toState,
    required this.duration,
  });

  @override
  List<Object?> get props => [
        componentId,
        changeType,
        description,
        timestamp,
        fromState,
        toState,
        duration,
      ];
}

/// 防抖管理器
class DebounceManager {
  final Map<String, Timer> _timers = {};
  final Map<String, Function()> _callbacks = {};

  /// 添加防抖回调
  void addDebounce(String key, Duration duration, Function() callback) {
    // 取消之前的定时器
    _timers[key]?.cancel();

    // 设置新的定时器
    _timers[key] = Timer(duration, () {
      callback();
      _timers.remove(key);
      _callbacks.remove(key);
    });

    _callbacks[key] = callback;
  }

  /// 立即执行并取消防抖
  void executeImmediately(String key) {
    _timers[key]?.cancel();
    final callback = _callbacks[key];
    if (callback != null) {
      callback();
      _timers.remove(key);
      _callbacks.remove(key);
    }
  }

  /// 取消特定防抖
  void cancelDebounce(String key) {
    _timers[key]?.cancel();
    _timers.remove(key);
    _callbacks.remove(key);
  }

  /// 取消所有防抖
  void cancelAll() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _callbacks.clear();
  }

  /// 清理资源
  void dispose() {
    cancelAll();
  }
}

/// 资源管理器
class ResourceManager {
  final List<StreamSubscription> _subscriptions = [];
  final List<Timer> _timers = [];
  final List<Function()> _disposers = [];

  /// 添加订阅
  void addSubscription(StreamSubscription subscription) {
    _subscriptions.add(subscription);
  }

  /// 添加定时器
  void addTimer(Timer timer) {
    _timers.add(timer);
  }

  /// 添加清理函数
  void addDisposer(Function() disposer) {
    _disposers.add(disposer);
  }

  /// 清理所有资源
  Future<void> disposeAll() async {
    // 取消订阅
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();

    // 取消定时器
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();

    // 执行清理函数
    for (final disposer in _disposers) {
      try {
        disposer();
      } catch (e) {
        AppLogger.error('资源清理失败', e);
      }
    }
    _disposers.clear();
  }
}

/// 状态追踪器
class StateTracker {
  final Queue<StateChangeRecord> _history = Queue<StateChangeRecord>();
  final int _maxHistorySize;

  StateTracker({int maxHistorySize = 100}) : _maxHistorySize = maxHistorySize;

  /// 记录状态变更
  void recordChange({
    required String componentId,
    required String changeType,
    required String description,
    required Map<String, dynamic> fromState,
    required Map<String, dynamic> toState,
    required int duration,
  }) {
    final record = StateChangeRecord(
      componentId: componentId,
      changeType: changeType,
      description: description,
      timestamp: DateTime.now(),
      fromState: fromState,
      toState: toState,
      duration: duration,
    );

    _history.add(record);

    // 保持历史记录大小
    while (_history.length > _maxHistorySize) {
      _history.removeFirst();
    }

    if (kDebugMode) {
      AppLogger.debug('🔄 状态变更: ${record.toString()}');
    }
  }

  /// 获取组件的历史记录
  List<StateChangeRecord> getHistory(String componentId) {
    return _history
        .where((record) => record.componentId == componentId)
        .toList();
  }

  /// 获取所有历史记录
  List<StateChangeRecord> getAllHistory() {
    return _history.toList();
  }

  /// 获取最近的变更
  StateChangeRecord? getLastChange(String componentId) {
    final history = getHistory(componentId);
    return history.isNotEmpty ? history.last : null;
  }

  /// 清理历史记录
  void clearHistory({String? componentId}) {
    if (componentId != null) {
      _history.removeWhere((record) => record.componentId == componentId);
    } else {
      _history.clear();
    }
  }
}

/// 状态持久化管理器
class StatePersistenceManager {
  final Map<String, dynamic> _cache = {};

  /// 保存状态
  Future<void> saveState(String key, dynamic state) async {
    try {
      // 这里可以集成到现有的缓存系统
      _cache[key] = state;
      AppLogger.debug('💾 状态已保存: $key');
    } catch (e) {
      AppLogger.error('状态保存失败: $key', e);
    }
  }

  /// 加载状态
  Future<T?> loadState<T>(String key) async {
    try {
      final state = _cache[key] as T?;
      AppLogger.debug('📂 状态已加载: $key, 成功: ${state != null}');
      return state;
    } catch (e) {
      AppLogger.error('状态加载失败: $key', e);
      return null;
    }
  }

  /// 删除状态
  Future<void> removeState(String key) async {
    try {
      _cache.remove(key);
      AppLogger.debug('🗑️ 状态已删除: $key');
    } catch (e) {
      AppLogger.error('状态删除失败: $key', e);
    }
  }

  /// 清空所有状态
  Future<void> clearAll() async {
    try {
      _cache.clear();
      AppLogger.debug('🗑️ 所有状态已清空');
    } catch (e) {
      AppLogger.error('状态清空失败', e);
    }
  }
}

/// 统一状态管理器
class UnifiedStateManager {
  static UnifiedStateManager? _instance;
  static UnifiedStateManager get instance {
    _instance ??= UnifiedStateManager._();
    return _instance!;
  }

  UnifiedStateManager._();

  final DebounceManager _debounceManager = DebounceManager();
  final ResourceManager _resourceManager = ResourceManager();
  final StateTracker _stateTracker = StateTracker();
  final StatePersistenceManager _persistenceManager = StatePersistenceManager();

  /// 获取防抖管理器
  DebounceManager get debounceManager => _debounceManager;

  /// 获取资源管理器
  ResourceManager get resourceManager => _resourceManager;

  /// 获取状态追踪器
  StateTracker get stateTracker => _stateTracker;

  /// 获取持久化管理器
  StatePersistenceManager get persistenceManager => _persistenceManager;

  /// 为Cubit添加状态追踪装饰器
  T createTrackedCubit<T extends Cubit>(
    String componentId,
    T Function() cubitFactory,
  ) {
    final cubit = cubitFactory();

    // 监听状态变更
    cubit.stream.listen((newState) {
      // 这里可以添加自动追踪逻辑
      AppLogger.debug('🔄 [$componentId] 状态更新: ${newState.runtimeType}');
    });

    return cubit;
  }

  /// 执行带追踪的状态操作
  Future<T> executeTrackedOperation<T>({
    required String componentId,
    required String operationType,
    required String description,
    required Future<T> Function() operation,
    Map<String, dynamic>? fromState,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      AppLogger.debug('🚀 [$componentId] 开始操作: $description');

      final result = await operation();

      stopwatch.stop();

      // 记录成功变更
      _stateTracker.recordChange(
        componentId: componentId,
        changeType: operationType,
        description: description,
        fromState: fromState ?? {},
        toState: {'result': result.toString()},
        duration: stopwatch.elapsedMilliseconds,
      );

      AppLogger.debug(
          '✅ [$componentId] 操作完成: $description (${stopwatch.elapsedMilliseconds}ms)');

      return result;
    } catch (e) {
      stopwatch.stop();

      // 记录失败变更
      _stateTracker.recordChange(
        componentId: componentId,
        changeType: operationType,
        description: '$description (失败)',
        fromState: fromState ?? {},
        toState: {'error': e.toString()},
        duration: stopwatch.elapsedMilliseconds,
      );

      AppLogger.error('❌ [$componentId] 操作失败: $description', e);

      rethrow;
    }
  }

  /// 批量保存状态
  Future<void> batchSaveStates(Map<String, dynamic> states) async {
    for (final entry in states.entries) {
      await _persistenceManager.saveState(entry.key, entry.value);
    }
  }

  /// 批量加载状态
  Future<Map<String, dynamic>> batchLoadStates(List<String> keys) async {
    final result = <String, dynamic>{};
    for (final key in keys) {
      final state = await _persistenceManager.loadState(key);
      if (state != null) {
        result[key] = state;
      }
    }
    return result;
  }

  /// 获取组件统计信息
  Map<String, dynamic> getComponentStats(String componentId) {
    final history = _stateTracker.getHistory(componentId);
    final lastChange = _stateTracker.getLastChange(componentId);

    return {
      'componentId': componentId,
      'totalChanges': history.length,
      'lastChange': lastChange?.timestamp.toIso8601String(),
      'lastChangeType': lastChange?.changeType,
      'averageDuration': history.isEmpty
          ? 0
          : history.map((r) => r.duration).reduce((a, b) => a + b) /
              history.length,
      'recentChanges': history.take(5).map((r) => r.description).toList(),
    };
  }

  /// 获取全局统计信息
  Map<String, dynamic> getGlobalStats() {
    final allHistory = _stateTracker.getAllHistory();
    final componentIds = allHistory.map((r) => r.componentId).toSet();

    return {
      'totalComponents': componentIds.length,
      'totalChanges': allHistory.length,
      'components': componentIds.map((id) => getComponentStats(id)).toList(),
      'activeDebouncers': _debounceManager._timers.length,
      'activeSubscriptions': _resourceManager._subscriptions.length,
      'activeTimers': _resourceManager._timers.length,
    };
  }

  /// 清理所有资源
  Future<void> dispose() async {
    AppLogger.info('🧹 统一状态管理器开始清理资源');

    await _resourceManager.disposeAll();
    _debounceManager.dispose();
    _stateTracker.clearHistory();
    await _persistenceManager.clearAll();

    AppLogger.info('✅ 统一状态管理器资源清理完成');
  }
}

/// 扩展Cubit以支持统一状态管理
extension UnifiedStateCubitExtension<T> on Cubit<T> {
  /// 添加资源到管理器
  void addResourceToManager({
    StreamSubscription? subscription,
    Timer? timer,
    Function()? disposer,
  }) {
    final manager = UnifiedStateManager.instance.resourceManager;
    if (subscription != null) manager.addSubscription(subscription);
    if (timer != null) manager.addTimer(timer);
    if (disposer != null) manager.addDisposer(disposer);
  }

  /// 添加防抖操作
  void addDebouncedOperation(
    String key,
    Duration duration,
    Function() operation,
  ) {
    UnifiedStateManager.instance.debounceManager
        .addDebounce(key, duration, operation);
  }

  /// 立即执行防抖操作
  void executeDebouncedOperation(String key) {
    UnifiedStateManager.instance.debounceManager.executeImmediately(key);
  }

  /// 持久化状态
  Future<void> persistState(String key, dynamic state) async {
    await UnifiedStateManager.instance.persistenceManager.saveState(key, state);
  }

  /// 加载持久化状态
  Future<S?> loadPersistedState<S>(String key) async {
    return await UnifiedStateManager.instance.persistenceManager
        .loadState<S>(key);
  }
}
