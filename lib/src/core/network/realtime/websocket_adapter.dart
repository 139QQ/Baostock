import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../hybrid/data_type.dart';
import '../utils/logger.dart';
import 'realtime_data_service.dart';

// ignore_for_file: directives_ordering
/// WebSocket适配器
///
/// 实现RealtimeDataService接口，提供WebSocket连接功能
class WebSocketAdapter implements RealtimeDataService {
  @override
  String get name => 'WebSocketAdapter';

  RealtimeServiceState _state = RealtimeServiceState.uninitialized;
  @override
  RealtimeServiceState get state => _state;

  /// 支持的数据类型（可在配置中自定义）
  @override
  Set<DataType> get supportedDataTypes => _supportedDataTypes;

  Set<DataType> _supportedDataTypes = {
    DataType.fundRanking,
    DataType.etfSpotData,
    DataType.lofSpotData,
    DataType.marketIndex,
    DataType.connectionStatus,
  };

  /// 状态流控制器
  final StreamController<RealtimeServiceState> _stateController =
      StreamController<RealtimeServiceState>.broadcast();

  /// 数据流控制器
  final StreamController<RealtimeDataEvent> _dataController =
      StreamController<RealtimeDataEvent>.broadcast();

  /// WebSocket通道
  WebSocketChannel? _channel;

  /// 服务配置
  late final RealtimeServiceConfig _config;

  /// 当前订阅
  final Map<DataType, String> _subscriptions = {};

  /// 心跳定时器
  Timer? _heartbeatTimer;

  /// 重连定时器
  Timer? _reconnectTimer;

  /// 重连次数
  int _reconnectAttempts = 0;

  /// 最后收到消息的时间
  DateTime? _lastMessageTime;

  @override
  Stream<RealtimeServiceState> get stateStream => _stateController.stream;

  @override
  Stream<RealtimeDataEvent> get dataStream => _dataController.stream;

  /// 初始化服务
  @override
  Future<void> initialize(RealtimeServiceConfig config) async {
    try {
      _updateState(RealtimeServiceState.initializing);
      _config = config;

      // 设置支持的数据类型（可从配置中自定义）
      if (config.headers.containsKey('supportedDataTypes')) {
        final dataTypes = config.headers['supportedDataTypes'];
        if (dataTypes != null) {
          _supportedDataTypes = dataTypes
              .split(',')
              .map((name) => DataType.values.firstWhere(
                    (type) => type.name == name.trim(),
                    orElse: () => DataType.unknown,
                  ))
              .where((type) => type != DataType.unknown)
              .toSet();
        }
      }

      _updateState(RealtimeServiceState.ready);
      AppLogger.info('WebSocketAdapter: 初始化完成');
    } catch (e) {
      _updateState(RealtimeServiceState.error);
      AppLogger.error('WebSocketAdapter: 初始化失败', e);
      rethrow;
    }
  }

  /// 启动服务
  @override
  Future<void> start() async {
    if (_state == RealtimeServiceState.connected) {
      AppLogger.warn('WebSocketAdapter: 服务已连接');
      return;
    }

    try {
      _updateState(RealtimeServiceState.connecting);
      await _connectWebSocket();
      _startHeartbeat();
      _updateState(RealtimeServiceState.connected);
      AppLogger.info('WebSocketAdapter: 连接成功', _config.url);
    } catch (e) {
      _updateState(RealtimeServiceState.error);
      AppLogger.error('WebSocketAdapter: 连接失败', e);

      // 启动重连
      if (_config.reconnectConfig.enabled) {
        _scheduleReconnect();
      }
    }
  }

  /// 停止服务
  @override
  Future<void> stop() async {
    try {
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
      _heartbeatTimer?.cancel();
      _heartbeatTimer = null;

      await _channel?.sink.close();
      _channel = null;
      _subscriptions.clear();

      _updateState(RealtimeServiceState.disconnected);
      AppLogger.info('WebSocketAdapter: 连接已断开');
    } catch (e) {
      AppLogger.error('WebSocketAdapter: 停止服务失败', e);
    }
  }

  /// 订阅数据
  @override
  Future<SubscriptionResult> subscribe(DataType dataType,
      {Map<String, dynamic>? parameters}) async {
    if (!_supportedDataTypes.contains(dataType)) {
      return SubscriptionResult.failure(
        error: '不支持的数据类型: ${dataType.name}',
      );
    }

    if (_state != RealtimeServiceState.connected) {
      return SubscriptionResult.failure(
        error: '服务未连接，当前状态: ${_state.description}',
      );
    }

    if (_subscriptions.containsKey(dataType)) {
      return SubscriptionResult.failure(
        error: '数据类型已订阅: ${dataType.name}',
      );
    }

    try {
      final message = RealtimeMessage.subscribe(
        dataType: dataType,
        parameters: parameters,
      );

      await sendMessage(message);

      final subscriptionId = _generateSubscriptionId(dataType);
      _subscriptions[dataType] = subscriptionId;

      AppLogger.info(
          'WebSocketAdapter: 订阅成功', '${dataType.name} -> $subscriptionId');
      return SubscriptionResult.success(subscriptionId: subscriptionId);
    } catch (e) {
      AppLogger.error('WebSocketAdapter: 订阅失败', '${dataType.name}: $e');
      return SubscriptionResult.failure(error: e.toString());
    }
  }

  /// 取消订阅
  @override
  Future<void> unsubscribe(DataType dataType) async {
    if (!_subscriptions.containsKey(dataType)) {
      AppLogger.warn('WebSocketAdapter: 未订阅的数据类型', dataType.name);
      return;
    }

    try {
      final subscriptionId = _subscriptions[dataType]!;
      final message = RealtimeMessage.unsubscribe(
        dataType: dataType,
        subscriptionId: subscriptionId,
      );

      await sendMessage(message);
      _subscriptions.remove(dataType);

      AppLogger.info('WebSocketAdapter: 取消订阅成功', dataType.name);
    } catch (e) {
      AppLogger.error('WebSocketAdapter: 取消订阅失败', '${dataType.name}: $e');
    }
  }

  /// 发送消息
  @override
  Future<void> sendMessage(RealtimeMessage message) async {
    if (_state != RealtimeServiceState.connected) {
      throw StateError('服务未连接，无法发送消息');
    }

    if (_channel == null) {
      throw StateError('WebSocket通道未建立');
    }

    try {
      final jsonMessage = message.toJsonString();
      _channel!.sink.add(jsonMessage);

      if (_config.enableDebugMode) {
        AppLogger.debug('WebSocketAdapter: 发送消息', message.type.name);
      }
    } catch (e) {
      AppLogger.error('WebSocketAdapter: 发送消息失败', e);
      rethrow;
    }
  }

  /// 获取健康状态
  @override
  Future<Map<String, dynamic>> getHealthStatus() async {
    return {
      'name': name,
      'state': _state.name,
      'url': _config.url,
      'supportedDataTypes': supportedDataTypes.map((t) => t.name).toList(),
      'activeSubscriptions': _subscriptions.keys.map((t) => t.name).toList(),
      'lastMessageTime': _lastMessageTime?.toIso8601String(),
      'reconnectAttempts': _reconnectAttempts,
      'connectionDuration': _calculateConnectionDuration(),
    };
  }

  /// 释放资源
  @override
  Future<void> dispose() async {
    await stop();

    await _stateController.close();
    await _dataController.close();

    AppLogger.info('WebSocketAdapter: 资源释放完成');
  }

  /// 连接WebSocket
  Future<void> _connectWebSocket() async {
    final uri = Uri.parse(_config.url);

    // 构建连接头
    final headers = <String, String>{
      'Content-Type': 'application/json',
      ..._config.headers,
    };

    if (_config.authToken != null) {
      headers['Authorization'] = 'Bearer ${_config.authToken}';
    }

    _channel = WebSocketChannel.connect(
      uri,
      protocols: ['json'],
    );

    // 设置超时
    await _channel!.ready.timeout(_config.connectTimeout);

    // 监听消息
    _channel!.stream.listen(
      _handleMessage,
      onError: _handleError,
      onDone: _handleConnectionClosed,
    );

    // 发送认证消息（如果有token）
    if (_config.authToken != null) {
      await sendMessage(
          RealtimeMessage.authenticate(token: _config.authToken!));
    }

    _reconnectAttempts = 0;
  }

  /// 处理接收到的消息
  void _handleMessage(dynamic message) {
    try {
      _lastMessageTime = DateTime.now();

      if (message is String) {
        final jsonData = jsonDecode(message) as Map<String, dynamic>;
        _processJsonMessage(jsonData);
      } else if (message is Map<String, dynamic>) {
        _processJsonMessage(message);
      } else {
        AppLogger.warn('WebSocketAdapter: 未知消息类型', message.runtimeType);
      }
    } catch (e) {
      AppLogger.error('WebSocketAdapter: 消息处理失败', e);
    }
  }

  /// 处理JSON消息
  void _processJsonMessage(Map<String, dynamic> jsonData) {
    final eventType = jsonData['eventType'] as String?;
    final dataTypeName = jsonData['dataType'] as String?;

    if (eventType == null) {
      AppLogger.warn('WebSocketAdapter: 消息缺少事件类型', jsonData);
      return;
    }

    // 解析数据类型
    DataType dataType = DataType.unknown;
    if (dataTypeName != null) {
      try {
        dataType = DataType.values.firstWhere(
          (type) => type.name == dataTypeName,
          orElse: () => DataType.unknown,
        );
      } catch (e) {
        AppLogger.warn('WebSocketAdapter: 未知数据类型', dataTypeName);
      }
    }

    // 处理不同类型的消息
    switch (eventType) {
      case 'dataUpdate':
      case 'DATA_UPDATE':
        _handleDataUpdate(dataType, jsonData);
        break;
      case 'error':
      case 'ERROR':
        _handleErrorEvent(dataType, jsonData);
        break;
      case 'heartbeat':
      case 'HEARTBEAT':
        _handleHeartbeat(jsonData);
        break;
      case 'subscriptionConfirmed':
      case 'SUBSCRIPTION_CONFIRMED':
        _handleSubscriptionConfirmed(dataType, jsonData);
        break;
      default:
        AppLogger.debug('WebSocketAdapter: 未处理的事件类型', eventType);
    }
  }

  /// 处理数据更新
  void _handleDataUpdate(DataType dataType, Map<String, dynamic> jsonData) {
    final data = jsonData['data'] as Map<String, dynamic>? ?? {};
    final eventId = jsonData['eventId'] as String?;
    final metadata = jsonData['metadata'] as Map<String, dynamic>?;

    final event = RealtimeDataEvent.dataUpdate(
      dataType: dataType,
      data: data,
      eventId: eventId,
      metadata: metadata,
    );

    _dataController.add(event);
    AppLogger.debug('WebSocketAdapter: 数据更新', dataType.name);
  }

  /// 处理错误事件
  void _handleErrorEvent(DataType dataType, Map<String, dynamic> jsonData) {
    final error = jsonData['data']?['error'] as String? ?? '未知错误';
    final eventId = jsonData['eventId'] as String?;
    final metadata = jsonData['metadata'] as Map<String, dynamic>?;

    final event = RealtimeDataEvent.error(
      dataType: dataType,
      error: error,
      eventId: eventId,
      metadata: metadata,
    );

    _dataController.add(event);
    AppLogger.error('WebSocketAdapter: 收到错误事件', error);
  }

  /// 处理心跳
  void _handleHeartbeat(Map<String, dynamic> jsonData) {
    AppLogger.debug('WebSocketAdapter: 收到心跳');
  }

  /// 处理订阅确认
  void _handleSubscriptionConfirmed(
      DataType dataType, Map<String, dynamic> jsonData) {
    AppLogger.info('WebSocketAdapter: 订阅确认', dataType.name);
  }

  /// 处理连接错误
  void _handleError(dynamic error) {
    AppLogger.error('WebSocketAdapter: 连接错误', error);
    _updateState(RealtimeServiceState.error);

    // 启动重连
    if (_config.reconnectConfig.enabled) {
      _scheduleReconnect();
    }
  }

  /// 处理连接关闭
  void _handleConnectionClosed() {
    AppLogger.warn('WebSocketAdapter: 连接已关闭');
    _updateState(RealtimeServiceState.disconnected);

    // 启动重连
    if (_config.reconnectConfig.enabled &&
        _state != RealtimeServiceState.stopped) {
      _scheduleReconnect();
    }
  }

  /// 启动心跳
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_config.heartbeatInterval, (_) {
      if (_state == RealtimeServiceState.connected) {
        try {
          sendMessage(RealtimeMessage.heartbeat());
        } catch (e) {
          AppLogger.warn('WebSocketAdapter: 心跳发送失败', e);
        }
      }
    });
  }

  /// 安排重连
  void _scheduleReconnect() {
    if (!_config.reconnectConfig.enabled) return;

    if (_reconnectTimer?.isActive ?? false) return;

    // 检查重连次数限制
    if (_config.reconnectConfig.maxAttempts > 0 &&
        _reconnectAttempts >= _config.reconnectConfig.maxAttempts) {
      AppLogger.error(
          'WebSocketAdapter: 达到最大重连次数', _config.reconnectConfig.maxAttempts);
      return;
    }

    // 计算重连延迟
    final delay = _calculateReconnectDelay();
    _reconnectAttempts++;

    AppLogger.info('WebSocketAdapter: 安排重连',
        '${delay.inSeconds}秒后 (第$_reconnectAttempts次)');

    _reconnectTimer = Timer(delay, () {
      _updateState(RealtimeServiceState.reconnecting);
      start();
    });
  }

  /// 计算重连延迟
  Duration _calculateReconnectDelay() {
    final baseDelay = _config.reconnectConfig.baseDelay;
    final maxDelay = _config.reconnectConfig.maxDelay;
    final backoffFactor = _config.reconnectConfig.backoffFactor;

    final delay = baseDelay * pow(backoffFactor, _reconnectAttempts);
    return delay > maxDelay ? maxDelay : delay;
  }

  /// 更新状态
  void _updateState(RealtimeServiceState newState) {
    if (_state != newState) {
      final oldState = _state;
      _state = newState;

      if (!_stateController.isClosed) {
        _stateController.add(newState);
      }

      AppLogger.debug('WebSocketAdapter: 状态变化',
          '${oldState.description} -> ${newState.description}');
    }
  }

  /// 生成订阅ID
  String _generateSubscriptionId(DataType dataType) {
    return '${name}_${dataType.name}_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// 计算连接持续时间
  Duration? _calculateConnectionDuration() {
    if (_lastMessageTime == null) return null;
    return DateTime.now().difference(_lastMessageTime!);
  }
}
