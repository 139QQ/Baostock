import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/network/realtime/fallback_http_service.dart';
import '../../../../core/network/realtime/websocket_manager.dart';
import '../../../../core/network/realtime/websocket_models.dart';
import '../../../../core/state/realtime_connection_cubit.dart';

/// 实时数据状态
class RealtimeDataState extends Equatable {
  /// 是否正在加载
  final bool isLoading;

  /// 是否有错误
  final bool hasError;

  /// 错误信息
  final String? errorMessage;

  /// 实时数据
  final Map<String, dynamic> realtimeData;

  /// 最后更新时间
  final DateTime? lastUpdateTime;

  /// 数据来源类型
  final DataSourceType dataSource;

  /// WebSocket连接状态
  final WebSocketConnectionState connectionState;

  /// HTTP轮询状态
  final bool isPolling;

  /// 连接质量评分
  final double qualityScore;

  /// 缓存的数据项数量
  final int cachedDataCount;

  /// 是否处于降级模式
  final bool isFallbackMode;

  /// 创建实时数据状态
  const RealtimeDataState({
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage,
    this.realtimeData = const {},
    this.lastUpdateTime,
    this.dataSource = DataSourceType.none,
    this.connectionState = WebSocketConnectionState.disconnected,
    this.isPolling = false,
    this.qualityScore = 0.0,
    this.cachedDataCount = 0,
    this.isFallbackMode = false,
  });

  /// 创建初始状态
  factory RealtimeDataState.initial() {
    return const RealtimeDataState();
  }

  /// 是否有数据
  bool get hasData => realtimeData.isNotEmpty;

  /// 是否连接正常
  bool get isConnected =>
      connectionState == WebSocketConnectionState.connected || isPolling;

  /// 获取数据来源描述
  String get dataSourceDescription {
    switch (dataSource) {
      case DataSourceType.websocket:
        return 'WebSocket';
      case DataSourceType.httpPolling:
        return 'HTTP轮询';
      case DataSourceType.cache:
        return '缓存数据';
      case DataSourceType.none:
        return '无数据源';
    }
  }

  /// 复制并修改状态
  RealtimeDataState copyWith({
    bool? isLoading,
    bool? hasError,
    String? errorMessage,
    Map<String, dynamic>? realtimeData,
    DateTime? lastUpdateTime,
    DataSourceType? dataSource,
    WebSocketConnectionState? connectionState,
    bool? isPolling,
    double? qualityScore,
    int? cachedDataCount,
    bool? isFallbackMode,
  }) {
    return RealtimeDataState(
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      realtimeData: realtimeData ?? this.realtimeData,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      dataSource: dataSource ?? this.dataSource,
      connectionState: connectionState ?? this.connectionState,
      isPolling: isPolling ?? this.isPolling,
      qualityScore: qualityScore ?? this.qualityScore,
      cachedDataCount: cachedDataCount ?? this.cachedDataCount,
      isFallbackMode: isFallbackMode ?? this.isFallbackMode,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        hasError,
        errorMessage,
        realtimeData,
        lastUpdateTime,
        dataSource,
        connectionState,
        isPolling,
        qualityScore,
        cachedDataCount,
        isFallbackMode,
      ];

  @override
  String toString() {
    return 'RealtimeDataState('
        'isLoading: $isLoading, '
        'hasData: $hasData, '
        'dataSource: $dataSource, '
        'isConnected: $isConnected, '
        'qualityScore: $qualityScore'
        ')';
  }
}

/// 数据来源类型
enum DataSourceType {
  /// WebSocket实时连接
  websocket,

  /// HTTP轮询
  httpPolling,

  /// 缓存数据
  cache,

  /// 无数据源
  none,
}

/// 实时数据Cubit事件
abstract class RealtimeDataEvent extends Equatable {
  /// 创建实时数据事件
  const RealtimeDataEvent();

  @override
  List<Object?> get props => [];
}

/// 请求开始连接
class ConnectRequestedEvent extends RealtimeDataEvent {}

/// 请求断开连接
class DisconnectRequestedEvent extends RealtimeDataEvent {}

/// WebSocket状态变化事件
class WebSocketStateChangedEvent extends RealtimeDataEvent {
  /// 新的WebSocket连接状态
  final WebSocketConnectionState newState;

  /// 实时连接状态
  final RealtimeConnectionState connectionState;

  /// 创建WebSocket状态变化事件
  const WebSocketStateChangedEvent(this.newState, this.connectionState);

  @override
  List<Object?> get props => [newState, connectionState];
}

/// 收到WebSocket消息事件
class WebSocketMessageReceivedEvent extends RealtimeDataEvent {
  /// WebSocket消息
  final WebSocketMessage message;

  /// 创建WebSocket消息接收事件
  const WebSocketMessageReceivedEvent(this.message);

  @override
  List<Object?> get props => [message];
}

/// HTTP轮询状态变化事件
class PollingStateChangedEvent extends RealtimeDataEvent {
  final FallbackServiceState state;

  const PollingStateChangedEvent(this.state);

  @override
  List<Object?> get props => [state];
}

/// 收到HTTP轮询数据事件
class PollingDataReceivedEvent extends RealtimeDataEvent {
  final FallbackDataMessage message;

  const PollingDataReceivedEvent(this.message);

  @override
  List<Object?> get props => [message];
}

/// 数据更新事件
class DataUpdatedEvent extends RealtimeDataEvent {
  final Map<String, dynamic> data;
  final DataSourceType source;

  const DataUpdatedEvent(this.data, this.source);

  @override
  List<Object?> get props => [data, source];
}

/// 错误事件
class ErrorEvent extends RealtimeDataEvent {
  final String error;
  final DataSourceType? source;

  const ErrorEvent(this.error, {this.source});

  @override
  List<Object?> get props => [error, source];
}

/// 清除错误事件
class ClearErrorEvent extends RealtimeDataEvent {}

/// 刷新数据事件
class RefreshDataEvent extends RealtimeDataEvent {}

/// 实时数据管理Cubit
class RealtimeDataCubit extends Cubit<RealtimeDataState> {
  final WebSocketManager _webSocketManager;
  final FallbackHttpService _fallbackHttpService;
  final RealtimeConnectionCubit _connectionCubit;

  // Stream订阅
  StreamSubscription? _webSocketStateSubscription;
  StreamSubscription? _webSocketMessageSubscription;
  StreamSubscription? _pollingStateSubscription;
  StreamSubscription? _pollingDataSubscription;
  StreamSubscription? _connectionStateSubscription;

  RealtimeDataCubit({
    required WebSocketManager webSocketManager,
    required FallbackHttpService fallbackHttpService,
    required RealtimeConnectionCubit connectionCubit,
  })  : _webSocketManager = webSocketManager,
        _fallbackHttpService = fallbackHttpService,
        _connectionCubit = connectionCubit,
        super(RealtimeDataState.initial()) {
    _initializeSubscriptions();
  }

  /// 初始化订阅
  void _initializeSubscriptions() {
    // 订阅WebSocket状态变化
    _webSocketStateSubscription = _webSocketManager.stateStream.listen(
      (state) => _handleWebSocketStateChanged(
          WebSocketStateChangedEvent(state, _connectionCubit.state)),
    );

    // 订阅WebSocket消息
    _webSocketMessageSubscription = _webSocketManager.messageStream.listen(
      (message) => _handleWebSocketMessageReceivedEvent(
          WebSocketMessageReceivedEvent(message)),
    );

    // 订阅HTTP轮询状态
    _pollingStateSubscription = _fallbackHttpService.stateStream.listen(
      (state) =>
          _handlePollingStateChangedEvent(PollingStateChangedEvent(state)),
    );

    // 订阅HTTP轮询数据
    _pollingDataSubscription = _fallbackHttpService.dataStream.listen(
      (message) =>
          _handlePollingDataReceivedEvent(PollingDataReceivedEvent(message)),
    );

    // 订阅连接Cubit状态
    _connectionStateSubscription = _connectionCubit.stream.listen(
      (connectionState) {
        // 同步连接状态到当前状态
        emit(state.copyWith(
          connectionState: connectionState.connectionState,
          qualityScore: connectionState.stabilityScore,
        ));
      },
    );
  }

  /// 处理连接请求
  Future<void> _handleConnectRequested() async {
    emit(state.copyWith(isLoading: true));

    try {
      // 首先尝试WebSocket连接
      await _webSocketManager.connect();

      emit(state.copyWith(
        isLoading: false,
        dataSource: DataSourceType.websocket,
      ));
    } catch (e) {
      // WebSocket连接失败，启动HTTP轮询作为降级方案
      await _fallbackHttpService.startPolling();

      emit(state.copyWith(
        isLoading: false,
        isFallbackMode: true,
        dataSource: DataSourceType.httpPolling,
      ));
    }
  }

  /// 处理断开连接请求
  Future<void> _handleDisconnectRequested() async {
    await _webSocketManager.disconnect();
    await _fallbackHttpService.stopPolling();

    emit(state.copyWith(
      dataSource: DataSourceType.none,
      isFallbackMode: false,
      isPolling: false,
    ));
  }

  /// 处理WebSocket状态变化
  Future<void> _handleWebSocketStateChanged(
      WebSocketStateChangedEvent event) async {
    final newState = event.newState;
    final connectionState = event.connectionState;

    emit(state.copyWith(
      connectionState: newState,
      qualityScore: connectionState.stabilityScore,
    ));

    // 根据连接状态决定是否启用降级机制
    if (newState == WebSocketConnectionState.connected) {
      // WebSocket连接成功，停止HTTP轮询
      if (_fallbackHttpService.isPolling) {
        await _fallbackHttpService.stopPolling();
      }

      emit(state.copyWith(
        isFallbackMode: false,
        dataSource: DataSourceType.websocket,
      ));
    } else if (newState == WebSocketConnectionState.error ||
        newState == WebSocketConnectionState.disconnected) {
      // WebSocket连接失败，启动HTTP轮询降级
      if (!_fallbackHttpService.isPolling) {
        await _fallbackHttpService.startPolling();
      }

      emit(state.copyWith(
        isFallbackMode: true,
        dataSource: DataSourceType.httpPolling,
      ));
    }
  }

  /// 处理WebSocket消息接收
  Future<void> _handleWebSocketMessageReceivedEvent(
      WebSocketMessageReceivedEvent event) async {
    final message = event.message;

    if (message.type == WebSocketMessageType.data && message.data != null) {
      await _handleDataUpdatedEvent(DataUpdatedEvent(
        message.data is Map
            ? message.data as Map<String, dynamic>
            : {'data': message.data},
        DataSourceType.websocket,
      ));
    } else if (message.type == WebSocketMessageType.error) {
      await _handleErrorEvent(ErrorEvent(
        message.data.toString(),
        source: DataSourceType.websocket,
      ));
    }
  }

  /// 处理HTTP轮询状态变化
  Future<void> _handlePollingStateChangedEvent(
      PollingStateChangedEvent event) async {
    final pollingState = event.state;

    emit(state.copyWith(
      isPolling: pollingState == FallbackServiceState.polling,
    ));

    if (pollingState == FallbackServiceState.error) {
      await _handleErrorEvent(const ErrorEvent(
        'HTTP轮询服务错误',
        source: DataSourceType.httpPolling,
      ));
    }
  }

  /// 处理HTTP轮询数据接收
  Future<void> _handlePollingDataReceivedEvent(
      PollingDataReceivedEvent event) async {
    final message = event.message;

    if (message.isSuccess && message.data != null) {
      await _handleDataUpdatedEvent(DataUpdatedEvent(
        message.data!,
        DataSourceType.httpPolling,
      ));
    } else if (message.isError) {
      await _handleErrorEvent(ErrorEvent(
        message.error!,
        source: DataSourceType.httpPolling,
      ));
    }
  }

  /// 处理数据更新
  Future<void> _handleDataUpdatedEvent(DataUpdatedEvent event) async {
    emit(state.copyWith(
      realtimeData: event.data,
      lastUpdateTime: DateTime.now(),
      hasError: false,
      errorMessage: null,
    ));
  }

  /// 处理错误
  Future<void> _handleErrorEvent(ErrorEvent event) async {
    emit(state.copyWith(
      hasError: true,
      errorMessage: event.error,
    ));
  }

  /// 处理清除错误
  Future<void> _handleClearErrorEvent() async {
    emit(state.copyWith(
      hasError: false,
      errorMessage: null,
    ));
  }

  /// 处理刷新数据
  Future<void> _handleRefreshDataEvent() async {
    if (state.dataSource == DataSourceType.websocket) {
      // WebSocket模式下，发送心跳请求
      try {
        await _webSocketManager.sendMessage({'type': 'refresh'});
      } catch (e) {
        await _handleErrorEvent(ErrorEvent('刷新请求失败: $e'));
      }
    } else if (state.dataSource == DataSourceType.httpPolling) {
      // HTTP轮询模式下，立即执行一次轮询
      try {
        await _fallbackHttpService.pollNow();
      } catch (e) {
        await _handleErrorEvent(ErrorEvent('轮询刷新失败: $e'));
      }
    }
  }

  /// 公共方法：连接
  Future<void> connect() async => await _handleConnectRequested();

  /// 公共方法：断开连接
  Future<void> disconnect() async => await _handleDisconnectRequested();

  /// 公共方法：发送消息
  Future<void> sendMessage(dynamic message) async {
    try {
      await _webSocketManager.sendMessage(message);
    } catch (e) {
      await _handleErrorEvent(ErrorEvent('发送消息失败: $e'));
    }
  }

  /// 公共方法：刷新数据
  Future<void> refreshData() async => await _handleRefreshDataEvent();

  /// 公共方法：清除错误
  Future<void> clearError() async => await _handleClearErrorEvent();

  /// 获取连接统计信息
  Map<String, dynamic> getConnectionStats() {
    return {
      'realtimeDataState': state.toJson(),
      'webSocketStats': _webSocketManager.getConnectionStats(),
      'fallbackStats': _fallbackHttpService.getServiceStats(),
      'connectionStats': _connectionCubit.getConnectionStats(),
    };
  }

  /// 获取缓存数据
  List<Map<String, dynamic>> getCachedData() {
    return _fallbackHttpService
        .getCachedData()
        .map((item) => item.toJson())
        .toList();
  }

  @override
  Future<void> close() async {
    await _webSocketStateSubscription?.cancel();
    await _webSocketMessageSubscription?.cancel();
    await _pollingStateSubscription?.cancel();
    await _pollingDataSubscription?.cancel();
    await _connectionStateSubscription?.cancel();

    await super.close();
  }
}

/// 扩展RealtimeDataState以支持JSON序列化
extension RealtimeDataStateExtension on RealtimeDataState {
  /// 将状态转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'isLoading': isLoading,
      'hasError': hasError,
      'errorMessage': errorMessage,
      'realtimeData': realtimeData,
      'lastUpdateTime': lastUpdateTime?.toIso8601String(),
      'dataSource': dataSource.toString(),
      'dataSourceDescription': dataSourceDescription,
      'connectionState': connectionState.toString(),
      'isPolling': isPolling,
      'qualityScore': qualityScore,
      'cachedDataCount': cachedDataCount,
      'isFallbackMode': isFallbackMode,
      'hasData': hasData,
      'isConnected': isConnected,
    };
  }
}
