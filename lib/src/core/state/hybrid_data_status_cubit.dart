import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../network/hybrid/data_type.dart';
import '../network/hybrid/hybrid_data_manager.dart';
import '../network/polling/polling_manager.dart';
import '../utils/logger.dart';

/// 混合数据连接状态
enum HybridConnectionState {
  /// 离线
  offline,

  /// 连接中
  connecting,

  /// 已连接 (部分服务)
  connected,

  /// 已连接 (所有服务)
  fullyConnected,

  /// 重连中
  reconnecting,

  /// 错误状态
  error;

  /// 获取状态描述
  String get description {
    switch (this) {
      case HybridConnectionState.offline:
        return '离线';
      case HybridConnectionState.connecting:
        return '连接中';
      case HybridConnectionState.connected:
        return '已连接';
      case HybridConnectionState.fullyConnected:
        return '完全连接';
      case HybridConnectionState.reconnecting:
        return '重连中';
      case HybridConnectionState.error:
        return '连接错误';
    }
  }

  /// 是否为连接状态
  bool get isConnected {
    switch (this) {
      case HybridConnectionState.connected:
      case HybridConnectionState.fullyConnected:
        return true;
      default:
        return false;
    }
  }

  /// 是否为活动状态
  bool get isActive {
    switch (this) {
      case HybridConnectionState.connecting:
      case HybridConnectionState.connected:
      case HybridConnectionState.fullyConnected:
      case HybridConnectionState.reconnecting:
        return true;
      default:
        return false;
    }
  }
}

/// 数据类型状态
class DataTypeStatus extends Equatable {
  /// 数据类型
  final DataType dataType;

  /// 是否启用
  final bool enabled;

  /// 连接状态
  final HybridConnectionState connectionState;

  /// 最后更新时间
  final DateTime? lastUpdateTime;

  /// 最后成功时间
  final DateTime? lastSuccessTime;

  /// 错误信息
  final String? error;

  /// 质量级别
  final DataQualityLevel quality;

  /// 延迟 (毫秒)
  final int latency;

  /// 成功率
  final double successRate;

  /// 数据变化频率
  final double changeFrequency;

  /// 使用的策略
  final String? activeStrategy;

  const DataTypeStatus({
    required this.dataType,
    this.enabled = true,
    this.connectionState = HybridConnectionState.offline,
    this.lastUpdateTime,
    this.lastSuccessTime,
    this.error,
    this.quality = DataQualityLevel.unknown,
    this.latency = 0,
    this.successRate = 0.0,
    this.changeFrequency = 0.0,
    this.activeStrategy,
  });

  @override
  List<Object?> get props => [
        dataType,
        enabled,
        connectionState,
        lastUpdateTime,
        lastSuccessTime,
        error,
        quality,
        latency,
        successRate,
        changeFrequency,
        activeStrategy,
      ];

  /// 复制并更新部分属性
  DataTypeStatus copyWith({
    DataType? dataType,
    bool? enabled,
    HybridConnectionState? connectionState,
    DateTime? lastUpdateTime,
    DateTime? lastSuccessTime,
    String? error,
    DataQualityLevel? quality,
    int? latency,
    double? successRate,
    double? changeFrequency,
    String? activeStrategy,
  }) {
    return DataTypeStatus(
      dataType: dataType ?? this.dataType,
      enabled: enabled ?? this.enabled,
      connectionState: connectionState ?? this.connectionState,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      lastSuccessTime: lastSuccessTime ?? this.lastSuccessTime,
      error: error ?? this.error,
      quality: quality ?? this.quality,
      latency: latency ?? this.latency,
      successRate: successRate ?? this.successRate,
      changeFrequency: changeFrequency ?? this.changeFrequency,
      activeStrategy: activeStrategy ?? this.activeStrategy,
    );
  }

  /// 获取状态评分 (0-100)
  double get statusScore {
    double score = 0.0;

    // 连接状态权重 40%
    switch (connectionState) {
      case HybridConnectionState.fullyConnected:
        score += 40.0;
        break;
      case HybridConnectionState.connected:
        score += 30.0;
        break;
      case HybridConnectionState.connecting:
      case HybridConnectionState.reconnecting:
        score += 20.0;
        break;
      case HybridConnectionState.offline:
        score += 10.0;
        break;
      case HybridConnectionState.error:
        score += 0.0;
        break;
    }

    // 成功率权重 30%
    score += successRate * 30.0;

    // 质量级别权重 20%
    score += quality.value * 4.0; // quality.value is 1-5, scale to 0-20

    // 延迟权重 10% (延迟越低得分越高)
    if (latency <= 1000) {
      score += 10.0;
    } else if (latency <= 3000) {
      score += 7.0;
    } else if (latency <= 5000) {
      score += 5.0;
    } else {
      score += 2.0;
    }

    return score.clamp(0.0, 100.0);
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'dataType': dataType.code,
      'enabled': enabled,
      'connectionState': connectionState.name,
      'lastUpdateTime': lastUpdateTime?.toIso8601String(),
      'lastSuccessTime': lastSuccessTime?.toIso8601String(),
      'error': error,
      'quality': quality.name,
      'latency': latency,
      'successRate': successRate,
      'changeFrequency': changeFrequency,
      'activeStrategy': activeStrategy,
      'statusScore': statusScore,
    };
  }
}

/// 系统状态
class SystemStatus extends Equatable {
  /// 整体连接状态
  final HybridConnectionState overallState;

  /// 活跃数据类型数量
  final int activeDataTypes;

  /// 总数据类型数量
  final int totalDataTypes;

  /// 系统启动时间
  final DateTime startTime;

  /// 最后更新时间
  final DateTime? lastUpdateTime;

  /// 系统错误列表
  final List<String> systemErrors;

  /// 活跃策略列表
  final List<String> activeStrategies;

  const SystemStatus({
    this.overallState = HybridConnectionState.offline,
    this.activeDataTypes = 0,
    this.totalDataTypes = 0,
    required this.startTime,
    this.lastUpdateTime,
    this.systemErrors = const [],
    this.activeStrategies = const [],
  });

  @override
  List<Object?> get props => [
        overallState,
        activeDataTypes,
        totalDataTypes,
        startTime,
        lastUpdateTime,
        systemErrors,
        activeStrategies,
      ];

  /// 复制并更新部分属性
  SystemStatus copyWith({
    HybridConnectionState? overallState,
    int? activeDataTypes,
    int? totalDataTypes,
    DateTime? startTime,
    DateTime? lastUpdateTime,
    List<String>? systemErrors,
    List<String>? activeStrategies,
  }) {
    return SystemStatus(
      overallState: overallState ?? this.overallState,
      activeDataTypes: activeDataTypes ?? this.activeDataTypes,
      totalDataTypes: totalDataTypes ?? this.totalDataTypes,
      startTime: startTime ?? this.startTime,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      systemErrors: systemErrors ?? this.systemErrors,
      activeStrategies: activeStrategies ?? this.activeStrategies,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'overallState': overallState.name,
      'activeDataTypes': activeDataTypes,
      'totalDataTypes': totalDataTypes,
      'startTime': startTime.toIso8601String(),
      'lastUpdateTime': lastUpdateTime?.toIso8601String(),
      'systemErrors': systemErrors,
      'activeStrategies': activeStrategies,
    };
  }
}

/// 混合数据状态状态
class HybridDataStatusState extends Equatable {
  /// 系统状态
  final SystemStatus systemStatus;

  /// 各数据类型状态
  final Map<DataType, DataTypeStatus> dataTypeStatuses;

  /// 是否正在初始化
  final bool isInitializing;

  /// 是否正在加载
  final bool isLoading;

  /// 错误信息
  final String? error;

  const HybridDataStatusState({
    required this.systemStatus,
    this.dataTypeStatuses = const {},
    this.isInitializing = false,
    this.isLoading = false,
    this.error,
  });

  @override
  List<Object?> get props => [
        systemStatus,
        dataTypeStatuses,
        isInitializing,
        isLoading,
        error,
      ];

  /// 复制并更新部分属性
  HybridDataStatusState copyWith({
    SystemStatus? systemStatus,
    Map<DataType, DataTypeStatus>? dataTypeStatuses,
    bool? isInitializing,
    bool? isLoading,
    String? error,
  }) {
    return HybridDataStatusState(
      systemStatus: systemStatus ?? this.systemStatus,
      dataTypeStatuses: dataTypeStatuses ?? this.dataTypeStatuses,
      isInitializing: isInitializing ?? this.isInitializing,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  /// 获取指定数据类型状态
  DataTypeStatus? getDataTypeStatus(DataType dataType) {
    return dataTypeStatuses[dataType];
  }

  /// 获取活跃数据类型状态
  List<DataTypeStatus> getActiveDataTypeStatuses() {
    return dataTypeStatuses.values.where((status) => status.enabled).toList();
  }

  /// 获取有错误的数据类型
  List<DataTypeStatus> getErrorDataTypes() {
    return dataTypeStatuses.values
        .where((status) => status.error != null)
        .toList();
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'systemStatus': systemStatus.toJson(),
      'dataTypeStatuses': dataTypeStatuses.map(
        (key, value) => MapEntry(key.code, value.toJson()),
      ),
      'isInitializing': isInitializing,
      'isLoading': isLoading,
      'error': error,
    };
  }
}

/// 混合数据状态事件
abstract class HybridDataStatusEvent extends Equatable {
  const HybridDataStatusEvent();

  @override
  List<Object?> get props => [];
}

/// 初始化状态
class InitializeStatus extends HybridDataStatusEvent {}

/// 刷新状态
class RefreshStatus extends HybridDataStatusEvent {}

/// 更新数据类型状态
class UpdateDataTypeStatus extends HybridDataStatusEvent {
  final DataType dataType;
  final DataTypeStatus status;

  const UpdateDataTypeStatus(this.dataType, this.status);

  @override
  List<Object?> get props => [dataType, status];
}

/// 更新系统状态
class UpdateSystemStatus extends HybridDataStatusEvent {
  final SystemStatus systemStatus;

  const UpdateSystemStatus(this.systemStatus);

  @override
  List<Object?> get props => [systemStatus];
}

/// 添加系统错误
class AddSystemError extends HybridDataStatusEvent {
  final String error;

  const AddSystemError(this.error);

  @override
  List<Object?> get props => [error];
}

/// 清除系统错误
class ClearSystemErrors extends HybridDataStatusEvent {}

/// 混合数据状态Cubit
class HybridDataStatusCubit
    extends Bloc<HybridDataStatusEvent, HybridDataStatusState> {
  /// 混合数据管理器
  final HybridDataManager _hybridDataManager;

  /// 轮询管理器
  final PollingManager _pollingManager;

  /// 状态更新定时器
  Timer? _statusUpdateTimer;

  /// 订阅列表
  final List<StreamSubscription> _subscriptions = [];

  HybridDataStatusCubit({
    required HybridDataManager hybridDataManager,
    required PollingManager pollingManager,
  })  : _hybridDataManager = hybridDataManager,
        _pollingManager = pollingManager,
        super(HybridDataStatusState(
          systemStatus: SystemStatus(startTime: DateTime.now()),
        )) {
    on<HybridDataStatusEvent>(_onEvent);
    _initializeSubscriptions();
  }

  /// 初始化订阅
  void _initializeSubscriptions() {
    // 订阅混合数据管理器状态变化
    _subscriptions.add(
      _hybridDataManager.stateStream.listen((managerState) {
        _updateSystemStatus();
      }),
    );

    // 订阅轮询管理器状态变化
    _subscriptions.add(
      _pollingManager.stateStream.listen((pollingState) {
        _updateSystemStatus();
      }),
    );

    // 启动状态更新定时器
    _startStatusUpdateTimer();
  }

  /// 启动状态更新定时器
  void _startStatusUpdateTimer() {
    _statusUpdateTimer?.cancel();
    _statusUpdateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      add(RefreshStatus());
    });
  }

  @override
  Future<void> close() async {
    _statusUpdateTimer?.cancel();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await super.close();
  }

  /// 事件处理器
  Future<void> _onEvent(
      HybridDataStatusEvent event, Emitter<HybridDataStatusState> emit) async {
    try {
      if (event is InitializeStatus) {
        await _handleInitializeStatus();
      } else if (event is RefreshStatus) {
        await _handleRefreshStatus();
      } else if (event is UpdateDataTypeStatus) {
        _handleUpdateDataTypeStatus(event.dataType, event.status);
      } else if (event is UpdateSystemStatus) {
        _handleUpdateSystemStatus(event.systemStatus);
      } else if (event is AddSystemError) {
        _handleAddSystemError(event.error);
      } else if (event is ClearSystemErrors) {
        _handleClearSystemErrors();
      }
    } catch (e) {
      AppLogger.error('Error handling hybrid data status event: $e', e);
      emit(state.copyWith(error: e.toString()));
    }
  }

  /// 处理初始化状态事件
  Future<void> _handleInitializeStatus() async {
    emit(state.copyWith(
      isInitializing: true,
      isLoading: true,
    ));

    try {
      await _updateSystemStatus();
      await _updateDataTypeStatuses();

      emit(state.copyWith(
        isInitializing: false,
        isLoading: false,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isInitializing: false,
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  /// 处理刷新状态事件
  Future<void> _handleRefreshStatus() async {
    if (state.isInitializing) return;

    emit(state.copyWith(isLoading: true));

    try {
      await _updateSystemStatus();
      await _updateDataTypeStatuses();

      emit(state.copyWith(
        isLoading: false,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  /// 处理更新数据类型状态事件
  void _handleUpdateDataTypeStatus(DataType dataType, DataTypeStatus status) {
    final newStatuses =
        Map<DataType, DataTypeStatus>.from(state.dataTypeStatuses);
    newStatuses[dataType] = status;

    emit(state.copyWith(dataTypeStatuses: newStatuses));
  }

  /// 处理更新系统状态事件
  void _handleUpdateSystemStatus(SystemStatus systemStatus) {
    emit(state.copyWith(systemStatus: systemStatus));
  }

  /// 处理添加系统错误事件
  void _handleAddSystemError(String error) {
    final currentErrors = List<String>.from(state.systemStatus.systemErrors);
    currentErrors.add(error);

    final updatedSystemStatus = state.systemStatus.copyWith(
      systemErrors: currentErrors,
      lastUpdateTime: DateTime.now(),
    );

    emit(state.copyWith(systemStatus: updatedSystemStatus));
  }

  /// 处理清除系统错误事件
  void _handleClearSystemErrors() {
    final updatedSystemStatus = state.systemStatus.copyWith(
      systemErrors: [],
      lastUpdateTime: DateTime.now(),
    );

    emit(state.copyWith(systemStatus: updatedSystemStatus));
  }

  /// 更新系统状态
  Future<void> _updateSystemStatus() async {
    try {
      // 获取混合数据管理器状态
      final hybridState = _hybridDataManager.state;
      final pollingState = _pollingManager.state;

      // 获取健康状态
      final healthStatus = await _hybridDataManager.getHealthStatus();
      final pollingStats = _pollingManager.getStatistics();

      // 确定整体连接状态
      HybridConnectionState overallState;
      if (hybridState == ManagerState.running &&
          pollingState == PollingManagerState.running) {
        overallState = HybridConnectionState.fullyConnected;
      } else if (hybridState == ManagerState.running ||
          pollingState == PollingManagerState.running) {
        overallState = HybridConnectionState.connected;
      } else if (hybridState == ManagerState.starting ||
          pollingState == PollingManagerState.starting) {
        overallState = HybridConnectionState.connecting;
      } else {
        overallState = HybridConnectionState.offline;
      }

      // 获取活跃策略
      final activeStrategies = <String>[];
      final strategies =
          healthStatus['strategies'] as Map<String, dynamic>? ?? {};
      for (final entry in strategies.entries) {
        final strategyData = entry.value as Map<String, dynamic>? ?? {};
        if (strategyData['healthy'] == true) {
          activeStrategies.add(entry.key);
        }
      }

      final updatedSystemStatus = SystemStatus(
        overallState: overallState,
        activeDataTypes: state.getActiveDataTypeStatuses().length,
        totalDataTypes: DataType.values.length,
        startTime: state.systemStatus.startTime,
        lastUpdateTime: DateTime.now(),
        systemErrors: state.systemStatus.systemErrors,
        activeStrategies: activeStrategies,
      );

      emit(state.copyWith(systemStatus: updatedSystemStatus));
    } catch (e) {
      AppLogger.error('Failed to update system status: $e', e);
      add(AddSystemError('System status update failed: $e'));
    }
  }

  /// 更新数据类型状态
  Future<void> _updateDataTypeStatuses() async {
    try {
      final newStatuses = <DataType, DataTypeStatus>{};

      // 获取性能指标
      final performanceMetrics = _hybridDataManager.getPerformanceMetrics();

      for (final dataType in DataType.values) {
        final currentStatus = state.getDataTypeStatus(dataType);

        // 获取轮询统计信息
        final pollingStats = _pollingManager.getStatisticsForType(dataType);
        final performanceData =
            performanceMetrics[dataType.code] as Map<String, dynamic>? ?? {};

        // 确定连接状态
        HybridConnectionState connectionState = HybridConnectionState.offline;
        if (state.systemStatus.overallState.isConnected) {
          // 根据成功率和延迟确定状态
          final successRate = pollingStats?.successRate ?? 0.0;
          if (successRate > 0.8) {
            connectionState = HybridConnectionState.connected;
          } else if (successRate > 0.5) {
            connectionState = HybridConnectionState.connecting;
          } else {
            connectionState = HybridConnectionState.error;
          }
        }

        // 创建新的状态
        final newStatus = DataTypeStatus(
          dataType: dataType,
          enabled: currentStatus?.enabled ?? true,
          connectionState: connectionState,
          lastUpdateTime: DateTime.now(),
          lastSuccessTime: pollingStats != null && pollingStats.successCount > 0
              ? DateTime.now().subtract(const Duration(seconds: 30)) // 模拟最后成功时间
              : currentStatus?.lastSuccessTime,
          error: connectionState == HybridConnectionState.error
              ? 'High error rate detected'
              : currentStatus?.error,
          quality: _determineQualityLevel(
            (pollingStats?.averageLatencyMs ?? 0).toInt(),
            pollingStats?.successRate ?? 0.0,
          ),
          latency: (pollingStats?.averageLatencyMs ?? 0).round(),
          successRate: pollingStats?.successRate ?? 0.0,
          changeFrequency: _calculateChangeFrequency(dataType),
          activeStrategy: _determineActiveStrategy(dataType),
        );

        newStatuses[dataType] = newStatus;
      }

      emit(state.copyWith(dataTypeStatuses: newStatuses));
    } catch (e) {
      AppLogger.error('Failed to update data type statuses: $e', e);
      add(AddSystemError('Data type status update failed: $e'));
    }
  }

  /// 确定质量级别
  DataQualityLevel _determineQualityLevel(int latencyMs, double successRate) {
    if (successRate >= 0.95 && latencyMs <= 1000) {
      return DataQualityLevel.excellent;
    } else if (successRate >= 0.9 && latencyMs <= 3000) {
      return DataQualityLevel.good;
    } else if (successRate >= 0.8 && latencyMs <= 5000) {
      return DataQualityLevel.fair;
    } else if (successRate >= 0.5) {
      return DataQualityLevel.poor;
    } else {
      return DataQualityLevel.unknown;
    }
  }

  /// 计算数据变化频率 (模拟)
  double _calculateChangeFrequency(DataType dataType) {
    // 这里应该从实际的活跃度跟踪器获取数据
    // 暂时返回模拟值
    switch (dataType) {
      case DataType.fundNetValue:
        return 0.3; // 基金净值30%时间有变化
      case DataType.marketIndex:
        return 0.8; // 市场指数80%时间有变化
      case DataType.connectionStatus:
        return 0.1; // 连接状态10%时间有变化
      default:
        return 0.2;
    }
  }

  /// 确定活跃策略 (模拟)
  String? _determineActiveStrategy(DataType dataType) {
    if (dataType.isRealtime) {
      return 'WebSocketStrategy';
    } else if (dataType.isQuasiRealtime) {
      return 'HttpPollingStrategy';
    } else {
      return 'HttpOnDemandStrategy';
    }
  }

  /// 启用/禁用数据类型
  Future<void> setDataTypeEnabled(DataType dataType, bool enabled) async {
    final currentStatus = state.getDataTypeStatus(dataType);
    if (currentStatus != null) {
      final updatedStatus = currentStatus.copyWith(enabled: enabled);
      add(UpdateDataTypeStatus(dataType, updatedStatus));
    }
  }

  /// 手动刷新状态
  Future<void> refresh() async {
    add(RefreshStatus());
  }

  /// 清除错误
  void clearErrors() {
    add(ClearSystemErrors());
  }

  /// 获取状态报告
  Map<String, dynamic> getStatusReport() {
    return state.toJson();
  }
}
