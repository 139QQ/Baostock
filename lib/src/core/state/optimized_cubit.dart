/// 优化的Cubit基类
///
/// 集成统一状态管理功能，提供：
/// - 自动资源管理
/// - 状态变更追踪
/// - 防抖机制
/// - 持久化支持
library optimized_cubit;

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'unified_state_manager.dart';
import '../utils/logger.dart';

/// 优化的Cubit基类
abstract class OptimizedCubit<State> extends Cubit<State> {
  /// 组件ID，用于追踪和管理
  final String componentId;

  /// 统一状态管理器
  final UnifiedStateManager _stateManager = UnifiedStateManager.instance;

  /// 状态追踪器
  StateTracker get _stateTracker => _stateManager.stateTracker;

  /// 上一个状态
  State? _previousState;

  /// 状态变更计数
  int _changeCount = 0;

  /// 初始化是否完成
  bool _isInitialized = false;

  OptimizedCubit(this.componentId, State initialState) : super(initialState) {
    AppLogger.debug('🔄 [$componentId] OptimizedCubit 初始化');
  }

  /// 获取组件ID
  String get id => componentId;

  /// 获取状态变更次数
  int get changeCount => _changeCount;

  /// 获取上一个状态
  State? get previousState => _previousState;

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  /// 带追踪的状态发射
  @override
  void emit(State state) {
    if (state == this.state) {
      AppLogger.debug('⏭️ [$componentId] 状态未变更，跳过发射');
      return;
    }

    final stopwatch = Stopwatch()..start();

    // 记录状态变更
    _previousState = this.state;
    _changeCount++;

    // 发射状态
    super.emit(state);

    stopwatch.stop();

    // 记录到追踪器
    _stateTracker.recordChange(
      componentId: componentId,
      changeType: 'state_change',
      description: '状态从 ${_previousState.runtimeType} 变更为 ${state.runtimeType}',
      fromState: {'state': _previousState.toString()},
      toState: {'state': state.toString()},
      duration: stopwatch.elapsedMilliseconds,
    );

    AppLogger.debug(
        '🔄 [$componentId] 状态已发射 (#$_changeCount): ${state.runtimeType} (${stopwatch.elapsedMilliseconds}ms)');
  }

  /// 带追踪的异步状态更新
  Future<void> emitAsync(Future<State> Function() stateProvider) async {
    if (isClosed) return;

    final stopwatch = Stopwatch()..start();

    try {
      AppLogger.debug('🚀 [$componentId] 开始异步状态更新');

      final newState = await stateProvider();
      emit(newState);

      stopwatch.stop();
      AppLogger.debug(
          '✅ [$componentId] 异步状态更新完成 (${stopwatch.elapsedMilliseconds}ms)');
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('❌ [$componentId] 异步状态更新失败', e);

      // 发射错误状态（如果支持）
      if (this is ErrorCubit) {
        (this as ErrorCubit).emitError(e.toString());
      }
    }
  }

  /// 添加防抖操作
  void addDebouncedOperation(
    String key, {
    Duration duration = const Duration(milliseconds: 300),
    required Function() operation,
  }) {
    final fullKey = '${componentId}_$key';
    _stateManager.debounceManager.addDebounce(fullKey, duration, operation);
    AppLogger.debug(
        '⏱️ [$componentId] 添加防抖操作: $key (${duration.inMilliseconds}ms)');
  }

  /// 立即执行防抖操作
  void executeDebouncedOperation(String key) {
    final fullKey = '${componentId}_$key';
    _stateManager.debounceManager.executeImmediately(fullKey);
    AppLogger.debug('⚡ [$componentId] 立即执行防抖操作: $key');
  }

  /// 取消防抖操作
  void cancelDebouncedOperation(String key) {
    final fullKey = '${componentId}_$key';
    _stateManager.debounceManager.cancelDebounce(fullKey);
    AppLogger.debug('🚫 [$componentId] 取消防抖操作: $key');
  }

  /// 执行带追踪的操作
  Future<T> executeTracked<T>({
    required String operation,
    required Future<T> Function() body,
  }) async {
    return await _stateManager.executeTrackedOperation<T>(
      componentId: componentId,
      operationType: 'cubit_operation',
      description: operation,
      operation: body,
      fromState: {'currentState': state.toString()},
    );
  }

  /// 添加资源到管理器
  void addResource({
    StreamSubscription? subscription,
    Timer? timer,
    Function()? disposer,
  }) {
    if (subscription != null) {
      _stateManager.resourceManager.addSubscription(subscription);
    }
    if (timer != null) {
      _stateManager.resourceManager.addTimer(timer);
    }
    if (disposer != null) {
      _stateManager.resourceManager.addDisposer(disposer);
    }
    AppLogger.debug('📎 [$componentId] 资源已添加到管理器');
  }

  /// 初始化组件
  Future<void> initialize() async {
    if (_isInitialized) {
      AppLogger.debug('⏭️ [$componentId] 已初始化，跳过');
      return;
    }

    AppLogger.debug('🚀 [$componentId] 开始初始化');

    try {
      await onInitialize();
      _isInitialized = true;
      AppLogger.debug('✅ [$componentId] 初始化完成');
    } catch (e) {
      AppLogger.error('❌ [$componentId] 初始化失败', e);
      rethrow;
    }
  }

  /// 初始化钩子方法，子类重写
  Future<void> onInitialize() async {}

  /// 重新初始化
  Future<void> reinitialize() async {
    _isInitialized = false;
    await initialize();
  }

  /// 重置状态
  Future<void> reset() async {
    AppLogger.debug('🔄 [$componentId] 重置状态');

    try {
      await onReset();
      _changeCount = 0;
      _previousState = null;
      AppLogger.debug('✅ [$componentId] 状态重置完成');
    } catch (e) {
      AppLogger.error('❌ [$componentId] 状态重置失败', e);
      rethrow;
    }
  }

  /// 重置钩子方法，子类重写
  Future<void> onReset() async {}

  /// 持久化状态
  Future<void> persistState(String key, dynamic state) async {
    final fullKey = '${componentId}_$key';
    await _stateManager.persistenceManager.saveState(fullKey, state);
    AppLogger.debug('💾 [$componentId] 状态已持久化: $key');
  }

  /// 加载持久化状态
  Future<T?> loadPersistedState<T>(String key) async {
    final fullKey = '${componentId}_$key';
    final state = await _stateManager.persistenceManager.loadState<T>(fullKey);
    AppLogger.debug('📂 [$componentId] 加载持久化状态: $key, 成功: ${state != null}');
    return state;
  }

  /// 获取组件统计信息
  Map<String, dynamic> getStats() {
    return _stateManager.getComponentStats(componentId);
  }

  /// 清理组件历史记录
  void clearHistory() {
    _stateTracker.clearHistory(componentId: componentId);
    AppLogger.debug('🧹 [$componentId] 历史记录已清理');
  }

  @override
  Future<void> close() async {
    if (isClosed) return;

    AppLogger.debug('🗑️ [$componentId] OptimizedCubit 开始关闭');

    try {
      await onClose();
      await super.close();
      AppLogger.debug('✅ [$componentId] OptimizedCubit 关闭完成');
    } catch (e) {
      AppLogger.error('❌ [$componentId] OptimizedCubit 关闭失败', e);
    }
  }

  /// 关闭钩子方法，子类重写
  Future<void> onClose() async {
    clearHistory();
    // 资源会通过ResourceManager自动清理
  }
}

/// 支持错误的Cubit基类
abstract class ErrorCubit<State> extends OptimizedCubit<State> {
  ErrorCubit(super.componentId, super.initialState);

  /// 发射错误状态
  void emitError(String error) {
    AppLogger.error('💥 [$componentId] 状态错误: $error', Exception(error));
    // 子类可以重写此方法来处理错误状态
  }

  /// 带错误处理的异步操作
  Future<T?> safeExecute<T>({
    required String operation,
    required Future<T> Function() body,
    T? defaultValue,
  }) async {
    try {
      return await executeTracked<T>(
        operation: operation,
        body: body,
      );
    } catch (e) {
      AppLogger.error('❌ [$componentId] 操作失败: $operation', e);
      emitError(e.toString());
      return defaultValue;
    }
  }
}

/// 简化的数据Cubit基类
abstract class DataCubit<T> extends ErrorCubit<DataState<T>> {
  DataCubit(String componentId) : super(componentId, DataState<T>.initial());

  /// 数据
  T get data => state.data ?? (throw StateError('Data is null'));

  /// 是否为空
  bool get isEmpty => state.isEmpty;

  /// 是否有数据
  bool get hasData => state.hasData;

  /// 是否正在加载
  bool get isLoading => state.isLoading;

  /// 是否有错误
  bool get hasError => state.hasError;

  /// 错误信息
  String? get error => state.error;

  /// 设置加载状态
  void setLoading({String? message}) {
    emit(DataState<T>.loading(
      data: state.data,
      message: message,
    ));
  }

  /// 设置成功状态
  void setSuccess(T data, {String? message}) {
    emit(DataState<T>.success(data, message: message));
  }

  /// 设置错误状态
  void setError(String error, {T? data}) {
    emit(DataState<T>.failure(error, data: data ?? state.data));
  }

  /// 带追踪的数据加载
  Future<void> loadData(Future<T> Function() loader,
      {String? operation}) async {
    await safeExecute(
      operation: operation ?? 'loadData',
      body: () async {
        setLoading();
        final data = await loader();
        setSuccess(data);
        return data;
      },
    );
  }

  /// 刷新数据
  Future<void> refreshData(Future<T> Function() loader) async {
    await loadData(loader, operation: 'refreshData');
  }
}

/// 数据状态类
class DataState<T> {
  final T? data;
  final bool isLoading;
  final String? error;
  final String? message;
  final DateTime? lastUpdated;
  final int version;

  DataState({
    this.data,
    this.isLoading = false,
    this.error,
    this.message,
    this.lastUpdated,
    this.version = 0,
  });

  factory DataState.initial() => DataState<T>();

  factory DataState.loading({T? data, String? message}) => DataState(
        data: data,
        isLoading: true,
        message: message,
        lastUpdated: DateTime.now(),
        version: 1,
      );

  factory DataState.success(T data, {String? message}) => DataState<T>(
        data: data,
        isLoading: false,
        message: message,
        lastUpdated: DateTime.now(),
        version: 1,
      );

  factory DataState.failure(String error, {T? data}) => DataState<T>(
        data: data,
        isLoading: false,
        error: error,
        lastUpdated: DateTime.now(),
        version: 1,
      );

  bool get isEmpty => data == null;
  bool get hasData => data != null;
  bool get hasError => error != null;

  DataState<T> copyWith({
    T? data,
    bool? isLoading,
    String? error,
    String? message,
    DateTime? lastUpdated,
    int? version,
  }) {
    return DataState<T>(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      message: message ?? this.message,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      version: version ?? this.version,
    );
  }

  @override
  String toString() {
    return 'DataState<${T.toString()}>(data: $data, loading: $isLoading, error: $error, lastUpdated: $lastUpdated, version: $version)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DataState<T> &&
        other.data == data &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.version == version;
  }

  @override
  int get hashCode {
    return data.hashCode ^
        isLoading.hashCode ^
        error.hashCode ^
        version.hashCode;
  }
}
