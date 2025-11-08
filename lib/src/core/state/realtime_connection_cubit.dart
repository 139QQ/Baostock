import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../network/realtime/websocket_manager.dart';
import '../network/realtime/websocket_models.dart';
import '../utils/logger.dart';

/// 连接状态Cubit状态
class RealtimeConnectionState extends Equatable {
  /// 当前连接状态
  final WebSocketConnectionState connectionState;

  /// 连接质量指标
  final Map<String, dynamic> qualityMetrics;

  /// 最后消息时间
  final DateTime? lastMessageTime;

  /// 连接开始时间
  final DateTime? connectionStartTime;

  /// 错误信息
  final String? errorMessage;

  /// 重连次数
  final int reconnectCount;

  /// 是否已启用自动重连
  final bool autoReconnectEnabled;

  /// 连接URL
  final String? connectionUrl;

  /// 网络延迟（毫秒）
  final double latency;

  /// 连接稳定性评分（0-100）
  final double stabilityScore;

  const RealtimeConnectionState({
    this.connectionState = WebSocketConnectionState.disconnected,
    this.qualityMetrics = const {},
    this.lastMessageTime,
    this.connectionStartTime,
    this.errorMessage,
    this.reconnectCount = 0,
    this.autoReconnectEnabled = true,
    this.connectionUrl,
    this.latency = 0.0,
    this.stabilityScore = 100.0,
  });

  /// 创建初始状态
  factory RealtimeConnectionState.initial() {
    return const RealtimeConnectionState();
  }

  /// 是否已连接
  bool get isConnected => connectionState == WebSocketConnectionState.connected;

  /// 是否正在连接
  bool get isConnecting =>
      connectionState == WebSocketConnectionState.connecting;

  /// 是否正在重连
  bool get isReconnecting =>
      connectionState == WebSocketConnectionState.reconnecting;

  /// 是否已断开
  bool get isDisconnected =>
      connectionState == WebSocketConnectionState.disconnected;

  /// 是否有错误
  bool get hasError => errorMessage != null;

  /// 连接持续时间
  Duration? get connectionDuration {
    if (connectionStartTime == null) return null;
    return DateTime.now().difference(connectionStartTime!);
  }

  /// 获取连接状态描述
  String get connectionStateDescription {
    switch (connectionState) {
      case WebSocketConnectionState.disconnected:
        return '未连接';
      case WebSocketConnectionState.connecting:
        return '连接中';
      case WebSocketConnectionState.connected:
        return '已连接';
      case WebSocketConnectionState.reconnecting:
        return '重连中';
      case WebSocketConnectionState.error:
        return '连接错误';
      case WebSocketConnectionState.closed:
        return '已关闭';
    }
  }

  /// 获取连接质量等级
  String get qualityLevel {
    if (stabilityScore >= 90) return '优秀';
    if (stabilityScore >= 75) return '良好';
    if (stabilityScore >= 60) return '一般';
    if (stabilityScore >= 40) return '较差';
    return '很差';
  }

  /// 获取连接质量颜色
  String get qualityColor {
    if (stabilityScore >= 90) return 'green';
    if (stabilityScore >= 75) return 'blue';
    if (stabilityScore >= 60) return 'orange';
    return 'red';
  }

  RealtimeConnectionState copyWith({
    WebSocketConnectionState? connectionState,
    Map<String, dynamic>? qualityMetrics,
    DateTime? lastMessageTime,
    DateTime? connectionStartTime,
    String? errorMessage,
    int? reconnectCount,
    bool? autoReconnectEnabled,
    String? connectionUrl,
    double? latency,
    double? stabilityScore,
  }) {
    return RealtimeConnectionState(
      connectionState: connectionState ?? this.connectionState,
      qualityMetrics: qualityMetrics ?? this.qualityMetrics,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      connectionStartTime: connectionStartTime ?? this.connectionStartTime,
      errorMessage: errorMessage ?? this.errorMessage,
      reconnectCount: reconnectCount ?? this.reconnectCount,
      autoReconnectEnabled: autoReconnectEnabled ?? this.autoReconnectEnabled,
      connectionUrl: connectionUrl ?? this.connectionUrl,
      latency: latency ?? this.latency,
      stabilityScore: stabilityScore ?? this.stabilityScore,
    );
  }

  @override
  List<Object?> get props => [
        connectionState,
        qualityMetrics,
        lastMessageTime,
        connectionStartTime,
        errorMessage,
        reconnectCount,
        autoReconnectEnabled,
        connectionUrl,
        latency,
        stabilityScore,
      ];

  @override
  String toString() {
    return 'RealtimeConnectionState('
        'connectionState: $connectionState, '
        'isConnected: $isConnected, '
        'latency: ${latency}ms, '
        'stabilityScore: $stabilityScore, '
        'qualityLevel: $qualityLevel, '
        'reconnectCount: $reconnectCount, '
        'errorMessage: $errorMessage'
        ')';
  }
}

/// 连接状态Cubit事件
abstract class RealtimeConnectionEvent extends Equatable {
  const RealtimeConnectionEvent();

  @override
  List<Object?> get props => [];
}

/// 连接状态变化事件
class ConnectionStateChangedEvent extends RealtimeConnectionEvent {
  final WebSocketConnectionState newState;
  final WebSocketConnectionState? oldState;

  const ConnectionStateChangedEvent(this.newState, {this.oldState});

  @override
  List<Object?> get props => [newState, oldState];
}

/// 收到消息事件
class MessageReceivedEvent extends RealtimeConnectionEvent {
  final WebSocketMessage message;

  const MessageReceivedEvent(this.message);

  @override
  List<Object?> get props => [message];
}

/// 连接质量更新事件
class QualityUpdatedEvent extends RealtimeConnectionEvent {
  final Map<String, dynamic> metrics;

  const QualityUpdatedEvent(this.metrics);

  @override
  List<Object?> get props => [metrics];
}

/// 连接错误事件
class ConnectionErrorEvent extends RealtimeConnectionEvent {
  final String error;

  const ConnectionErrorEvent(this.error);

  @override
  List<Object?> get props => [error];
}

/// 重连计数更新事件
class ReconnectCountUpdatedEvent extends RealtimeConnectionEvent {
  final int count;

  const ReconnectCountUpdatedEvent(this.count);

  @override
  List<Object?> get props => [count];
}

/// 配置更新事件
class ConfigurationUpdatedEvent extends RealtimeConnectionEvent {
  final WebSocketConnectionConfig config;

  const ConfigurationUpdatedEvent(this.config);

  @override
  List<Object?> get props => [config];
}

/// 重置状态事件
class ResetConnectionStateEvent extends RealtimeConnectionEvent {}

/// 清除错误事件
class ClearErrorEvent extends RealtimeConnectionEvent {}

/// 实时连接状态管理Bloc
class RealtimeConnectionCubit
    extends Bloc<RealtimeConnectionEvent, RealtimeConnectionState> {
  late WebSocketManager _webSocketManager;
  StreamSubscription? _stateSubscription;
  StreamSubscription? _messageSubscription;

  RealtimeConnectionCubit(WebSocketManager webSocketManager)
      : _webSocketManager = webSocketManager,
        super(RealtimeConnectionState.initial()) {
    _initializeSubscriptions();
    _initializeEventHandlers();
    _updateInitialState();
  }

  /// 初始化订阅
  void _initializeSubscriptions() {
    // 订阅WebSocket状态变化
    _stateSubscription = _webSocketManager.stateStream.listen((newState) {
      final oldState = state.connectionState;
      add(ConnectionStateChangedEvent(newState, oldState: oldState));
    });

    // 订阅WebSocket消息
    _messageSubscription = _webSocketManager.messageStream.listen((message) {
      add(MessageReceivedEvent(message));
    });
  }

  /// 更新初始状态
  void _updateInitialState() {
    // 在构造函数中不能直接使用emit，需要通过add来触发状态更新
    add(ConfigurationUpdatedEvent(_webSocketManager.config));
  }

  /// 初始化事件处理器
  void _initializeEventHandlers() {
    on<ConnectionStateChangedEvent>(_handleConnectionStateChanged);
    on<MessageReceivedEvent>(_handleMessageReceived);
    on<QualityUpdatedEvent>(_handleQualityUpdated);
    on<ConnectionErrorEvent>(_handleConnectionError);
    on<ReconnectCountUpdatedEvent>(_handleReconnectCountUpdated);
    on<ConfigurationUpdatedEvent>(_handleConfigurationUpdated);
    on<ResetConnectionStateEvent>(_handleResetConnectionState);
    on<ClearErrorEvent>(_handleClearError);
  }

  /// 处理连接状态变化
  Future<void> _handleConnectionStateChanged(ConnectionStateChangedEvent event,
      Emitter<RealtimeConnectionState> emit) async {
    final newState = event.newState;
    final connectionStartTime = (newState == WebSocketConnectionState.connected)
        ? DateTime.now()
        : (newState != WebSocketConnectionState.connected
            ? null
            : state.connectionStartTime);

    // 计算稳定性评分
    final newStabilityScore = _calculateStabilityScore(newState);

    emit(state.copyWith(
      connectionState: newState,
      connectionStartTime: connectionStartTime,
      errorMessage: newState == WebSocketConnectionState.error
          ? state.errorMessage
          : null,
      stabilityScore: newStabilityScore,
    ));

    AppLogger.info('连接状态已更新', newState.toString());
  }

  /// 处理收到消息
  Future<void> _handleMessageReceived(
      MessageReceivedEvent event, Emitter<RealtimeConnectionState> emit) async {
    emit(state.copyWith(
      lastMessageTime: DateTime.now(),
    ));

    // 如果是心跳消息，更新延迟
    if (event.message.type == WebSocketMessageType.pong) {
      final latency =
          _webSocketManager.qualityMetrics['lastLatency'] as double? ?? 0.0;
      emit(state.copyWith(latency: latency));
    }
  }

  /// 处理质量更新
  Future<void> _handleQualityUpdated(
      QualityUpdatedEvent event, Emitter<RealtimeConnectionState> emit) async {
    final metrics = event.metrics;
    final latency = metrics['lastLatency'] as double? ?? state.latency;
    final reconnectCount =
        metrics['reconnectCount'] as int? ?? state.reconnectCount;
    final stabilityScore =
        _calculateStabilityScore(state.connectionState, metrics);

    emit(state.copyWith(
      qualityMetrics: metrics,
      latency: latency,
      reconnectCount: reconnectCount,
      stabilityScore: stabilityScore,
    ));
  }

  /// 处理连接错误
  Future<void> _handleConnectionError(
      ConnectionErrorEvent event, Emitter<RealtimeConnectionState> emit) async {
    emit(state.copyWith(
      errorMessage: event.error,
    ));

    AppLogger.error('连接错误', event.error);
  }

  /// 处理重连计数更新
  Future<void> _handleReconnectCountUpdated(ReconnectCountUpdatedEvent event,
      Emitter<RealtimeConnectionState> emit) async {
    emit(state.copyWith(
      reconnectCount: event.count,
    ));
  }

  /// 处理配置更新
  Future<void> _handleConfigurationUpdated(ConfigurationUpdatedEvent event,
      Emitter<RealtimeConnectionState> emit) async {
    emit(state.copyWith(
      connectionState: _webSocketManager.connectionState,
      connectionUrl: event.config.url,
      autoReconnectEnabled: event.config.autoReconnect,
      qualityMetrics: _webSocketManager.qualityMetrics,
    ));

    AppLogger.info('连接配置已更新', event.config.toString());
  }

  /// 处理重置状态
  Future<void> _handleResetConnectionState(ResetConnectionStateEvent event,
      Emitter<RealtimeConnectionState> emit) async {
    emit(RealtimeConnectionState.initial());
    _updateInitialState();
  }

  /// 处理清除错误
  Future<void> _handleClearError(
      ClearErrorEvent event, Emitter<RealtimeConnectionState> emit) async {
    emit(state.copyWith(errorMessage: null));
  }

  /// 计算连接稳定性评分
  double _calculateStabilityScore(
    WebSocketConnectionState connectionState, [
    Map<String, dynamic>? metrics,
  ]) {
    final qualityMetrics = metrics ?? _webSocketManager.qualityMetrics;

    double score = 100.0;

    // 根据连接状态调整评分
    switch (connectionState) {
      case WebSocketConnectionState.connected:
        score = 100.0;
        break;
      case WebSocketConnectionState.connecting:
        score = 70.0;
        break;
      case WebSocketConnectionState.reconnecting:
        score = 50.0;
        break;
      case WebSocketConnectionState.disconnected:
        score = 0.0;
        break;
      case WebSocketConnectionState.error:
        score = 20.0;
        break;
      case WebSocketConnectionState.closed:
        score = 10.0;
        break;
    }

    // 根据延迟调整评分
    final latency = qualityMetrics['lastLatency'] as double? ?? 0.0;
    if (latency > 1000) {
      score -= 20;
    } else if (latency > 500) {
      score -= 10;
    } else if (latency > 200) {
      score -= 5;
    }

    // 根据重连次数调整评分
    final reconnectCount = qualityMetrics['reconnectCount'] as int? ?? 0;
    score -= (reconnectCount * 5).clamp(0.0, 30.0);

    // 根据错误次数调整评分
    final errorCount = qualityMetrics['errorCount'] as int? ?? 0;
    final totalMessages = qualityMetrics['totalMessages'] as int? ?? 1;
    final errorRate = errorCount / totalMessages;
    score -= (errorRate * 50).clamp(0.0, 40.0);

    return score.clamp(0.0, 100.0);
  }

  /// 连接到WebSocket服务器
  Future<void> connect() async {
    try {
      await _webSocketManager.connect();
    } catch (e) {
      add(ConnectionErrorEvent('连接失败: ${e.toString()}'));
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    try {
      await _webSocketManager.disconnect();
    } catch (e) {
      add(ConnectionErrorEvent('断开连接失败: ${e.toString()}'));
    }
  }

  /// 重新连接
  Future<void> reconnect() async {
    try {
      await _webSocketManager.reconnect();
    } catch (e) {
      add(ConnectionErrorEvent('重连失败: ${e.toString()}'));
    }
  }

  /// 发送消息
  Future<void> sendMessage(dynamic message) async {
    try {
      await _webSocketManager.sendMessage(message);
    } catch (e) {
      add(ConnectionErrorEvent('发送消息失败: ${e.toString()}'));
    }
  }

  /// 更新WebSocket配置
  void updateConfig(WebSocketConnectionConfig config) {
    _webSocketManager.updateConfig(config);
    add(ConfigurationUpdatedEvent(config));
  }

  /// 获取连接统计信息
  Map<String, dynamic> getConnectionStats() {
    return {
      ...state.toJson(),
      'webSocketStats': _webSocketManager.getConnectionStats(),
    };
  }

  /// 刷新连接状态
  void refreshConnectionStatus() {
    final metrics = _webSocketManager.qualityMetrics;
    add(QualityUpdatedEvent(metrics));
  }

  /// 清除错误信息
  void clearError() {
    // 需要通过事件来处理状态更新
    add(ClearErrorEvent());
  }

  @override
  Future<void> close() async {
    await _stateSubscription?.cancel();
    await _messageSubscription?.cancel();
    await super.close();
  }
}

/// 扩展RealtimeConnectionState以支持JSON序列化
extension RealtimeConnectionStateExtension on RealtimeConnectionState {
  Map<String, dynamic> toJson() {
    return {
      'connectionState': connectionState.toString(),
      'connectionStateDescription': connectionStateDescription,
      'qualityMetrics': qualityMetrics,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'connectionStartTime': connectionStartTime?.toIso8601String(),
      'connectionDuration': connectionDuration?.inMilliseconds,
      'errorMessage': errorMessage,
      'reconnectCount': reconnectCount,
      'autoReconnectEnabled': autoReconnectEnabled,
      'connectionUrl': connectionUrl,
      'latency': latency,
      'stabilityScore': stabilityScore,
      'qualityLevel': qualityLevel,
      'qualityColor': qualityColor,
      'isConnected': isConnected,
      'isConnecting': isConnecting,
      'isReconnecting': isReconnecting,
      'isDisconnected': isDisconnected,
      'hasError': hasError,
    };
  }
}
