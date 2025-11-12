import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../models/market_index_data.dart';
import '../../models/index_change_data.dart';
import '../../data/processors/market_index_data_manager.dart';
import '../../data/processors/index_change_analyzer.dart';
import '../../data/monitors/index_latency_monitor.dart';

/// 市场指数常量
class MarketIndexConstants {
  /// 所有主要指数代码
  static const List<String> allMajorIndices = [
    '000001', // 上证指数
    '399001', // 深证成指
    '399006', // 创业板指
    '000300', // 沪深300
    '000016', // 上证50
    '000905', // 中证500
    '000852', // 中证1000
    '000688', // 科创50
  ];
}

/// 市场指数状态
@immutable
class MarketIndexState extends Equatable {
  final List<MarketIndexData> indices;
  final Map<String, IndexChangeData> indexChanges;
  final Map<String, IndexStatistics> statistics;
  final bool isLoading;
  final bool isPolling;
  final String? error;
  final DateTime lastUpdated;
  final List<String> trackedIndices;
  final MarketIndexPreferences preferences;

  // 兼容页面使用的属性
  String? get errorMessage => error;
  DateTime? get lastUpdateTime => lastUpdated;
  int get updateCount =>
      statistics.values.fold(0, (sum, stat) => sum + stat.totalUpdates);
  Duration get pollingInterval => preferences.pollingInterval;

  const MarketIndexState({
    this.indices = const [],
    this.indexChanges = const {},
    this.statistics = const {},
    this.isLoading = false,
    this.isPolling = false,
    this.error,
    required this.lastUpdated,
    this.trackedIndices = const [],
    this.preferences = const MarketIndexPreferences(),
  });

  MarketIndexState copyWith({
    List<MarketIndexData>? indices,
    Map<String, IndexChangeData>? indexChanges,
    Map<String, IndexStatistics>? statistics,
    bool? isLoading,
    bool? isPolling,
    String? error,
    DateTime? lastUpdated,
    List<String>? trackedIndices,
    MarketIndexPreferences? preferences,
  }) {
    return MarketIndexState(
      indices: indices ?? this.indices,
      indexChanges: indexChanges ?? this.indexChanges,
      statistics: statistics ?? this.statistics,
      isLoading: isLoading ?? this.isLoading,
      isPolling: isPolling ?? this.isPolling,
      error: error ?? this.error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      trackedIndices: trackedIndices ?? this.trackedIndices,
      preferences: preferences ?? this.preferences,
    );
  }

  @override
  List<Object?> get props => [
        indices,
        indexChanges,
        statistics,
        isLoading,
        isPolling,
        error,
        lastUpdated,
        trackedIndices,
        preferences,
      ];
}

/// 市场指数统计信息
@immutable
class IndexStatistics extends Equatable {
  final String indexCode;
  final int totalUpdates;
  final double averageUpdateInterval;
  final double successRate;
  final DateTime lastUpdateTime;
  final IndexTrend currentTrend;
  final List<IndexChangeData> recentChanges;

  const IndexStatistics({
    required this.indexCode,
    required this.totalUpdates,
    required this.averageUpdateInterval,
    required this.successRate,
    required this.lastUpdateTime,
    required this.currentTrend,
    required this.recentChanges,
  });

  @override
  List<Object?> get props => [
        indexCode,
        totalUpdates,
        averageUpdateInterval,
        successRate,
        lastUpdateTime,
        currentTrend,
        recentChanges,
      ];
}

/// 指数趋势
enum IndexTrend {
  up,
  down,
  sideways,
  unknown;

  String get description {
    switch (this) {
      case IndexTrend.up:
        return '上升';
      case IndexTrend.down:
        return '下降';
      case IndexTrend.sideways:
        return '横盘';
      case IndexTrend.unknown:
        return '未知';
    }
  }
}

/// 市场指数偏好设置
@immutable
class MarketIndexPreferences extends Equatable {
  final Duration pollingInterval;
  final bool enableNotifications;
  final bool enableAutoRefresh;
  final List<String> favoriteIndices;
  final bool showTechnicalSignals;
  final int maxTrackedIndices;
  final bool enableSoundAlerts;

  const MarketIndexPreferences({
    this.pollingInterval = const Duration(seconds: 30),
    this.enableNotifications = true,
    this.enableAutoRefresh = true,
    this.favoriteIndices = const [],
    this.showTechnicalSignals = true,
    this.maxTrackedIndices = 20,
    this.enableSoundAlerts = false,
  });

  MarketIndexPreferences copyWith({
    Duration? pollingInterval,
    bool? enableNotifications,
    bool? enableAutoRefresh,
    List<String>? favoriteIndices,
    bool? showTechnicalSignals,
    int? maxTrackedIndices,
    bool? enableSoundAlerts,
  }) {
    return MarketIndexPreferences(
      pollingInterval: pollingInterval ?? this.pollingInterval,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableAutoRefresh: enableAutoRefresh ?? this.enableAutoRefresh,
      favoriteIndices: favoriteIndices ?? this.favoriteIndices,
      showTechnicalSignals: showTechnicalSignals ?? this.showTechnicalSignals,
      maxTrackedIndices: maxTrackedIndices ?? this.maxTrackedIndices,
      enableSoundAlerts: enableSoundAlerts ?? this.enableSoundAlerts,
    );
  }

  @override
  List<Object?> get props => [
        pollingInterval,
        enableNotifications,
        enableAutoRefresh,
        favoriteIndices,
        showTechnicalSignals,
        maxTrackedIndices,
        enableSoundAlerts,
      ];
}

/// 市场指数Cubit事件
abstract class MarketIndexEvent extends Equatable {
  const MarketIndexEvent();

  @override
  List<Object?> get props => [];
}

/// 加载指数数据
class LoadMarketIndexData extends MarketIndexEvent {
  final List<String> indexCodes;

  const LoadMarketIndexData(this.indexCodes);

  @override
  List<Object?> get props => [indexCodes];
}

/// 刷新指数数据
class RefreshMarketIndexData extends MarketIndexEvent {
  final List<String>? indexCodes;

  const RefreshMarketIndexData({this.indexCodes});

  @override
  List<Object?> get props => [indexCodes];
}

/// 开始轮询
class StartPolling extends MarketIndexEvent {
  final Duration? interval;

  const StartPolling({this.interval});

  @override
  List<Object?> get props => [interval];
}

/// 停止轮询
class StopPolling extends MarketIndexEvent {}

/// 添加跟踪指数
class AddTrackedIndex extends MarketIndexEvent {
  final String indexCode;

  const AddTrackedIndex(this.indexCode);

  @override
  List<Object?> get props => [indexCode];
}

/// 移除跟踪指数
class RemoveTrackedIndex extends MarketIndexEvent {
  final String indexCode;

  const RemoveTrackedIndex(this.indexCode);

  @override
  List<Object?> get props => [indexCode];
}

/// 更新偏好设置
class UpdatePreferences extends MarketIndexEvent {
  final MarketIndexPreferences preferences;

  const UpdatePreferences(this.preferences);

  @override
  List<Object?> get props => [preferences];
}

/// 切换指数收藏状态
class ToggleIndexFavorite extends MarketIndexEvent {
  final String indexCode;

  const ToggleIndexFavorite(this.indexCode);

  @override
  List<Object?> get props => [indexCode];
}

/// 获取指数历史数据
class FetchIndexHistory extends MarketIndexEvent {
  final String indexCode;
  final Duration period;

  const FetchIndexHistory({
    required this.indexCode,
    this.period = const Duration(days: 7),
  });

  @override
  List<Object?> get props => [indexCode, period];
}

/// 清除错误
class ClearError extends MarketIndexEvent {}

/// 市场指数Cubit
class MarketIndexCubit extends Cubit<MarketIndexState> {
  final MarketIndexDataManager _dataManager;
  final IndexChangeAnalyzer _changeAnalyzer;
  final IndexLatencyMonitor _latencyMonitor;

  StreamSubscription? _dataSubscription;
  StreamSubscription? _changeSubscription;

  MarketIndexCubit({
    MarketIndexDataManager? dataManager,
    IndexChangeAnalyzer? changeAnalyzer,
    IndexLatencyMonitor? latencyMonitor,
  })  : _dataManager = dataManager ?? MarketIndexDataManager(),
        _changeAnalyzer = changeAnalyzer ?? IndexChangeAnalyzer(),
        _latencyMonitor = latencyMonitor ?? IndexLatencyMonitor(),
        super(MarketIndexState(
          lastUpdated: DateTime.now(),
        )) {
    _setupListeners();
  }

  /// 设置监听器
  void _setupListeners() {
    // 监听数据更新
    _dataSubscription = _dataManager.updateStream.listen((event) {
      _handleDataUpdate(event);
    });

    // 监听延迟预警
    _latencyMonitor.alertStream.listen((alert) {
      _handleLatencyAlert(alert);
    });
  }

  /// 处理数据更新
  void _handleDataUpdate(MarketIndexUpdateEvent event) {
    final currentIndices = <MarketIndexData>[];
    final currentIndexCodes = <String>[];
    final currentChanges = <String, IndexChangeData>{};
    final currentStatistics = <String, IndexStatistics>{};

    // 更新当前指数数据
    for (int i = 0; i < state.indices.length; i++) {
      final indexData = state.indices[i];
      if (indexData.code == event.indexCode) {
        currentIndices.add(event.indexData);
        currentIndexCodes.add(event.indexCode);
        currentChanges[event.indexCode] = event.changeData;
      } else {
        currentIndices.add(indexData);
        currentIndexCodes.add(indexData.code);
      }
    }

    // 如果是新指数，添加到列表
    if (!currentIndexCodes.contains(event.indexCode)) {
      currentIndices.add(event.indexData);
      currentIndexCodes.add(event.indexCode);
      currentChanges[event.indexCode] = event.changeData;
    }

    // 更新统计信息
    for (final indexCode in currentIndexCodes) {
      final statistics = _calculateIndexStatistics(indexCode);
      currentStatistics[indexCode] = statistics;
    }

    emit(state.copyWith(
      indices: currentIndices,
      indexChanges: currentChanges,
      statistics: currentStatistics,
      lastUpdated: DateTime.now(),
      error: null,
    ));
  }

  /// 处理延迟预警
  void _handleLatencyAlert(LatencyAlert alert) {
    // 这里可以实现延迟预警的处理逻辑
    // 比如显示通知、调整轮询频率等
  }

  /// 计算指数统计信息
  IndexStatistics _calculateIndexStatistics(String indexCode) {
    final indexData = state.indexChanges[indexCode];
    if (indexData == null) {
      return IndexStatistics(
        indexCode: indexCode,
        totalUpdates: 0,
        averageUpdateInterval: 0.0,
        successRate: 1.0,
        lastUpdateTime: DateTime.now(),
        currentTrend: IndexTrend.unknown,
        recentChanges: [],
      );
    }

    final latencyStats = _latencyMonitor.getStatistics(indexCode);
    final changeHistory = _changeAnalyzer.getChangeHistory(indexCode);

    return IndexStatistics(
      indexCode: indexCode,
      totalUpdates: changeHistory.length,
      averageUpdateInterval:
          latencyStats?.averageLatency.inMilliseconds.toDouble() ?? 0.0,
      successRate: latencyStats?.successRate ?? 1.0,
      lastUpdateTime: indexData.currentData.updateTime,
      currentTrend: _determineCurrentTrend(indexData),
      recentChanges: changeHistory.take(10).toList(),
    );
  }

  /// 确定当前趋势
  IndexTrend _determineCurrentTrend(IndexChangeData changeData) {
    if (changeData.currentData.isRising) {
      return IndexTrend.up;
    } else if (changeData.currentData.isFalling) {
      return IndexTrend.down;
    } else {
      return IndexTrend.sideways;
    }
  }

  @override
  Future<void> close() async {
    _dataSubscription?.cancel();
    _changeSubscription?.cancel();
    _dataManager.dispose();
    // _changeAnalyzer.dispose(); // IndexChangeAnalyzer 没有dispose方法
    _latencyMonitor.dispose();
    await super.close();
  }

  /// 事件处理
  Future<void> onEvent(MarketIndexEvent event) async {
    switch (event.runtimeType) {
      case LoadMarketIndexData:
        await _onLoadMarketIndexData(event as LoadMarketIndexData);
        break;
      case RefreshMarketIndexData:
        await _onRefreshMarketIndexData(event as RefreshMarketIndexData);
        break;
      case StartPolling:
        await _onStartPolling(event as StartPolling);
        break;
      case StopPolling:
        await _onStopPolling();
        break;
      case AddTrackedIndex:
        await _onAddTrackedIndex(event as AddTrackedIndex);
        break;
      case RemoveTrackedIndex:
        await _onRemoveTrackedIndex(event as RemoveTrackedIndex);
        break;
      case UpdatePreferences:
        await _onUpdatePreferences(event as UpdatePreferences);
        break;
      case ToggleIndexFavorite:
        await _onToggleIndexFavorite(event as ToggleIndexFavorite);
        break;
      case FetchIndexHistory:
        await _onFetchIndexHistory(event as FetchIndexHistory);
        break;
      case ClearError:
        _onClearError();
        break;
    }
  }

  /// 加载市场指数数据
  Future<void> _onLoadMarketIndexData(LoadMarketIndexData event) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));

      final indexCodes = event.indexCodes.isEmpty
          ? MarketIndexConstants.allMajorIndices
          : event.indexCodes;

      // 启动跟踪指数
      for (final indexCode in indexCodes) {
        await _dataManager.startTrackingIndex(indexCode);
      }

      // 获取当前数据
      final currentData = <MarketIndexData>[];
      final currentChanges = <String, IndexChangeData>{};

      for (final indexCode in indexCodes) {
        // 暂时跳过获取缓存数据，等待MarketIndexDataManager提供公共接口
        // final data = await _dataManager.getCachedIndexData(indexCode);
        // if (data != null) {
        //   currentData.add(data);
        //   // 计算变化数据
        //   final changeData = _changeAnalyzer.analyzeChange(data, null);
        //   currentChanges[indexCode] = changeData;
        // }
      }

      emit(state.copyWith(
        indices: currentData,
        indexChanges: currentChanges,
        trackedIndices: indexCodes,
        isLoading: false,
        lastUpdated: DateTime.now(),
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: '加载指数数据失败: $e',
      ));
    }
  }

  /// 刷新市场指数数据
  Future<void> _onRefreshMarketIndexData(RefreshMarketIndexData event) async {
    try {
      final indexCodes = event.indexCodes ?? state.trackedIndices;

      for (final indexCode in indexCodes) {
        // 触发数据刷新 - 需要实现公共接口或重新设计
        // await _dataManager._refreshIndexData(indexCode);
        // 暂时注释，等待MarketIndexDataManager提供公共刷新接口
      }
    } catch (e) {
      emit(state.copyWith(error: '刷新指数数据失败: $e'));
    }
  }

  /// 开始轮询
  Future<void> _onStartPolling(StartPolling event) async {
    try {
      await _dataManager.startBatchPolling();

      if (event.interval != null) {
        await _dataManager.setPollingInterval(event.interval!);
      }

      emit(state.copyWith(isPolling: true));
    } catch (e) {
      emit(state.copyWith(error: '启动轮询失败: $e'));
    }
  }

  /// 停止轮询
  Future<void> _onStopPolling() async {
    try {
      await _dataManager.stopBatchPolling();
      emit(state.copyWith(isPolling: false));
    } catch (e) {
      emit(state.copyWith(error: '停止轮询失败: $e'));
    }
  }

  /// 添加跟踪指数
  Future<void> _onAddTrackedIndex(AddTrackedIndex event) async {
    try {
      if (state.trackedIndices.length >= state.preferences.maxTrackedIndices) {
        emit(state.copyWith(error: '已达到最大跟踪指数数量限制'));
        return;
      }

      if (state.trackedIndices.contains(event.indexCode)) {
        return; // 已经在跟踪列表中
      }

      await _dataManager.startTrackingIndex(event.indexCode);

      final newTrackedIndices = [...state.trackedIndices, event.indexCode];
      emit(state.copyWith(trackedIndices: newTrackedIndices));
    } catch (e) {
      emit(state.copyWith(error: '添加跟踪指数失败: $e'));
    }
  }

  /// 移除跟踪指数
  Future<void> _onRemoveTrackedIndex(RemoveTrackedIndex event) async {
    try {
      await _dataManager.stopTrackingIndex(event.indexCode);

      final newTrackedIndices = state.trackedIndices
          .where((code) => code != event.indexCode)
          .toList();

      final newIndices = state.indices
          .where((index) => index.code != event.indexCode)
          .toList();

      final newChanges = Map<String, IndexChangeData>.from(state.indexChanges)
        ..remove(event.indexCode);

      final newStatistics = Map<String, IndexStatistics>.from(state.statistics)
        ..remove(event.indexCode);

      emit(state.copyWith(
        trackedIndices: newTrackedIndices,
        indices: newIndices,
        indexChanges: newChanges,
        statistics: newStatistics,
      ));
    } catch (e) {
      emit(state.copyWith(error: '移除跟踪指数失败: $e'));
    }
  }

  /// 更新偏好设置
  Future<void> _onUpdatePreferences(UpdatePreferences event) async {
    try {
      emit(state.copyWith(preferences: event.preferences));

      // 应用偏好设置
      if (state.preferences.enableAutoRefresh && !state.isPolling) {
        await _dataManager.startBatchPolling();
      } else if (!state.preferences.enableAutoRefresh && state.isPolling) {
        await _dataManager.stopBatchPolling();
      }

      await _dataManager.setPollingInterval(state.preferences.pollingInterval);
    } catch (e) {
      emit(state.copyWith(error: '更新偏好设置失败: $e'));
    }
  }

  /// 切换指数收藏状态
  Future<void> _onToggleIndexFavorite(ToggleIndexFavorite event) async {
    final favorites = List<String>.from(state.preferences.favoriteIndices);

    if (favorites.contains(event.indexCode)) {
      favorites.remove(event.indexCode);
    } else {
      favorites.add(event.indexCode);
    }

    final newPreferences = state.preferences.copyWith(
      favoriteIndices: favorites,
    );

    await _onUpdatePreferences(UpdatePreferences(newPreferences));
  }

  /// 获取指数历史数据
  Future<void> _onFetchIndexHistory(FetchIndexHistory event) async {
    // 这里可以实现获取历史数据的逻辑
    // 由于当前架构主要关注实时数据，历史数据可能需要从其他数据源获取
  }

  /// 清除错误
  void _onClearError() {
    emit(state.copyWith(error: null));
  }

  /// 获取指定指数的数据
  MarketIndexData? getIndexData(String indexCode) {
    try {
      return state.indices.firstWhere((index) => index.code == indexCode);
    } catch (e) {
      return null;
    }
  }

  /// 获取指定指数的变化数据
  IndexChangeData? getIndexChangeData(String indexCode) {
    return state.indexChanges[indexCode];
  }

  /// 获取指定指数的统计信息
  IndexStatistics? getIndexStatistics(String indexCode) {
    return state.statistics[indexCode];
  }

  /// 检查指数是否被收藏
  bool isIndexFavorite(String indexCode) {
    return state.preferences.favoriteIndices.contains(indexCode);
  }

  /// 获取性能统计
  Map<String, dynamic> getPerformanceStats() {
    return _dataManager.getPerformanceStats();
  }

  /// 获取延迟统计
  Map<String, dynamic> getLatencyStats() {
    return _latencyMonitor.getAllStatistics();
  }

  // 页面期望的方法
  /// 启动轮询
  Future<void> startPolling() async {
    await onEvent(StartPolling());
  }

  /// 停止轮询
  Future<void> stopPolling() async {
    await onEvent(StopPolling());
  }

  /// 刷新数据
  Future<void> refreshData() async {
    await onEvent(RefreshMarketIndexData());
  }

  /// 设置轮询间隔
  Future<void> setPollingInterval(Duration duration) async {
    final newPreferences =
        state.preferences.copyWith(pollingInterval: duration);
    await onEvent(UpdatePreferences(newPreferences));
  }
}
