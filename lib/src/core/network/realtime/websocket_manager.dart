import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../utils/logger.dart';
import 'websocket_models.dart';

// ignore_for_file: sort_constructors_first
/// WebSocket连接管理器
///
/// 提供稳定的WebSocket连接，支持自动重连、心跳机制和连接状态监控
/// 实现指数退避重连算法，确保连接的稳定性和可靠性
class WebSocketManager {
  /// WebSocket连接配置
  WebSocketConnectionConfig _config;

  /// WebSocket通道
  WebSocketChannel? _channel;

  /// 当前连接状态
  WebSocketConnectionState _connectionState =
      WebSocketConnectionState.disconnected;

  /// 重连次数计数器
  int _reconnectAttempts = 0;

  /// 心跳定时器
  Timer? _heartbeatTimer;

  /// 重连定时器
  Timer? _reconnectTimer;

  /// 连接超时定时器
  Timer? _connectTimeoutTimer;

  /// 最后收到消息的时间
  DateTime _lastMessageTime = DateTime.now();

  /// 最后发送心跳的时间
  DateTime _lastPingTime = DateTime.now();

  /// 消息流控制器
  final StreamController<WebSocketMessage> _messageController =
      StreamController<WebSocketMessage>.broadcast();

  /// 连接状态流控制器
  final StreamController<WebSocketConnectionState> _stateController =
      StreamController<WebSocketConnectionState>.broadcast();

  /// 是否正在主动关闭连接
  bool _isClosing = false;

  /// 连接质量监控数据
  final Map<String, dynamic> _qualityMetrics = {
    'totalMessages': 0,
    'errorCount': 0,
    'reconnectCount': 0,
    'lastLatency': 0.0,
    'averageLatency': 0.0,
    'connectionUptime': 0.0,
  };

  /// 构造函数
  WebSocketManager({
    required WebSocketConnectionConfig config,
  }) : _config = config;

  /// 获取当前配置
  WebSocketConnectionConfig get config => _config;

  /// 更新配置
  void updateConfig(WebSocketConnectionConfig config) {
    _config = config;
    AppLogger.info('WebSocket配置已更新', config.toString());
  }

  /// 获取当前连接状态
  WebSocketConnectionState get connectionState => _connectionState;

  /// 是否已连接
  bool get isConnected =>
      _connectionState == WebSocketConnectionState.connected;

  /// 是否正在连接
  bool get isConnecting =>
      _connectionState == WebSocketConnectionState.connecting;

  /// 是否正在重连
  bool get isReconnecting =>
      _connectionState == WebSocketConnectionState.reconnecting;

  /// 消息流
  Stream<WebSocketMessage> get messageStream => _messageController.stream;

  /// 连接状态流
  Stream<WebSocketConnectionState> get stateStream => _stateController.stream;

  /// 连接质量指标
  Map<String, dynamic> get qualityMetrics => Map.unmodifiable(_qualityMetrics);

  /// 连接到WebSocket服务器
  Future<void> connect() async {
    if (_connectionState == WebSocketConnectionState.connecting ||
        _connectionState == WebSocketConnectionState.connected) {
      AppLogger.warn('WebSocket已在连接或已连接状态');
      return;
    }

    _isClosing = false;
    await _performConnect();
  }

  /// 执行连接操作
  Future<void> _performConnect() async {
    try {
      _updateConnectionState(WebSocketConnectionState.connecting);
      AppLogger.info('正在连接WebSocket服务器', _config.url);

      // 创建WebSocket连接
      _channel = WebSocketChannel.connect(
        Uri.parse(_config.url),
        protocols: _config.protocols,
      );

      // 设置连接超时
      _connectTimeoutTimer?.cancel();
      _connectTimeoutTimer = Timer(_config.connectTimeout, () {
        AppLogger.error('WebSocket连接超时');
        _handleConnectionError(
            TimeoutException('WebSocket连接超时', _config.connectTimeout));
      });

      // 监听消息流
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleConnectionDone,
        cancelOnError: false,
      );

      AppLogger.info('WebSocket连接请求已发送');
    } catch (e) {
      AppLogger.error('WebSocket连接失败', e);
      await _handleConnectionError(e);
    }
  }

  /// 处理接收到的消息
  void _handleMessage(dynamic message) {
    _lastMessageTime = DateTime.now();

    try {
      // 取消连接超时定时器
      _connectTimeoutTimer?.cancel();

      // 如果是第一次收到消息，标记为已连接
      if (_connectionState == WebSocketConnectionState.connecting) {
        _updateConnectionState(WebSocketConnectionState.connected);
        _resetReconnectAttempts();
        _startHeartbeat();
        AppLogger.info('WebSocket连接已建立');
      }

      // 更新质量指标
      _qualityMetrics['totalMessages'] =
          (_qualityMetrics['totalMessages'] as int) + 1;

      // 解析消息
      String messageStr;
      if (message is String) {
        messageStr = message;
      } else if (message is List<int>) {
        messageStr = utf8.decode(message);
      } else {
        messageStr = message.toString();
      }

      // 处理心跳响应
      if (messageStr.toLowerCase().contains('pong')) {
        final latency =
            DateTime.now().difference(_lastPingTime).inMilliseconds.toDouble();
        _updateLatencyMetrics(latency);
        AppLogger.debug('收到心跳响应', '延迟: ${latency}ms');
        return;
      }

      // 尝试解析JSON消息
      dynamic data;
      try {
        data = jsonDecode(messageStr);
      } catch (e) {
        // 如果不是JSON，直接使用原始字符串
        data = messageStr;
      }

      // 创建消息对象并发送到流
      final webSocketMessage = WebSocketMessage.data(
        data,
        source: 'websocket_manager',
      );

      if (!_messageController.isClosed) {
        _messageController.add(webSocketMessage);
      }

      AppLogger.debug('收到WebSocket消息', data.toString());
    } catch (e) {
      AppLogger.error('处理WebSocket消息失败', e);
      _qualityMetrics['errorCount'] =
          (_qualityMetrics['errorCount'] as int) + 1;
    }
  }

  /// 处理错误
  void _handleError(dynamic error) {
    AppLogger.error('WebSocket错误', error);
    _qualityMetrics['errorCount'] = (_qualityMetrics['errorCount'] as int) + 1;

    // 发送错误消息
    final errorMessage = WebSocketMessage.error(
      error.toString(),
      source: 'websocket_manager',
    );

    if (!_messageController.isClosed) {
      _messageController.add(errorMessage);
    }
  }

  /// 处理连接关闭
  void _handleConnectionDone() {
    AppLogger.warn('WebSocket连接已关闭');

    _connectTimeoutTimer?.cancel();
    _heartbeatTimer?.cancel();

    if (_connectionState != WebSocketConnectionState.closed) {
      _updateConnectionState(WebSocketConnectionState.disconnected);

      // 如果不是主动关闭且启用了自动重连，则尝试重连
      if (!_isClosing && _config.autoReconnect) {
        _scheduleReconnect();
      }
    }
  }

  /// 处理连接错误
  Future<void> _handleConnectionError(dynamic error) async {
    _connectTimeoutTimer?.cancel();
    _heartbeatTimer?.cancel();

    _updateConnectionState(WebSocketConnectionState.error);

    if (!_isClosing && _config.autoReconnect) {
      _scheduleReconnect();
    }
  }

  /// 安排重连
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _config.maxReconnectAttempts &&
        _config.maxReconnectAttempts != -1) {
      AppLogger.error('WebSocket重连次数已达上限', '尝试次数: $_reconnectAttempts');
      _updateConnectionState(WebSocketConnectionState.closed);
      return;
    }

    // 计算重连延迟（指数退避算法）
    final delay = _calculateReconnectDelay();

    _updateConnectionState(WebSocketConnectionState.reconnecting);
    AppLogger.info('安排WebSocket重连',
        '延迟: ${delay.inSeconds}秒, 尝试次数: ${_reconnectAttempts + 1}');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () async {
      _reconnectAttempts++;
      _qualityMetrics['reconnectCount'] =
          (_qualityMetrics['reconnectCount'] as int) + 1;
      await _performConnect();
    });
  }

  /// 计算重连延迟（指数退避算法）
  Duration _calculateReconnectDelay() {
    // 指数退避: delay = baseDelay * (2 ^ attempt) + jitter
    final exponentialDelay = _config.baseReconnectDelay.inMilliseconds *
        pow(2, min(_reconnectAttempts, 10));

    // 添加随机抖动（±25%），避免多个客户端同时重连
    final jitter = (Random().nextDouble() - 0.5) * exponentialDelay * 0.5;

    final totalDelay = exponentialDelay + jitter;

    // 限制在最大延迟时间内
    final clampedDelay =
        min(totalDelay, _config.maxReconnectDelay.inMilliseconds.toDouble());

    return Duration(milliseconds: clampedDelay.toInt());
  }

  /// 重置重连次数
  void _resetReconnectAttempts() {
    _reconnectAttempts = 0;
  }

  /// 开始心跳
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_config.heartbeatInterval, (_) {
      _sendPing();
    });
  }

  /// 发送心跳ping
  void _sendPing() {
    if (isConnected && _channel != null) {
      try {
        _lastPingTime = DateTime.now();
        final pingMessage = WebSocketMessage.ping();
        _channel!.sink.add(jsonEncode(pingMessage.toJson()));
        AppLogger.debug('发送心跳ping');
      } catch (e) {
        AppLogger.error('发送心跳失败', e);
        _handleError(e);
      }
    }
  }

  /// 发送消息
  Future<void> sendMessage(dynamic message) async {
    if (!isConnected || _channel == null) {
      throw StateError('WebSocket未连接');
    }

    try {
      String messageStr;
      if (message is String) {
        messageStr = message;
      } else if (message is Map || message is List) {
        messageStr = jsonEncode(message);
      } else {
        messageStr = message.toString();
      }

      _channel!.sink.add(messageStr);
      AppLogger.debug('发送WebSocket消息', messageStr);
    } catch (e) {
      AppLogger.error('发送WebSocket消息失败', e);
      rethrow;
    }
  }

  /// 更新连接状态
  void _updateConnectionState(WebSocketConnectionState newState) {
    if (_connectionState != newState) {
      final oldState = _connectionState;
      _connectionState = newState;

      AppLogger.info('WebSocket状态变化', '$oldState -> $newState');

      if (!_stateController.isClosed) {
        _stateController.add(newState);
      }
    }
  }

  /// 更新延迟指标
  void _updateLatencyMetrics(double latency) {
    _qualityMetrics['lastLatency'] = latency;

    // 计算平均延迟
    final totalMessages = _qualityMetrics['totalMessages'] as int;
    if (totalMessages == 1) {
      _qualityMetrics['averageLatency'] = latency;
    } else {
      final currentAvg = _qualityMetrics['averageLatency'] as double;
      _qualityMetrics['averageLatency'] =
          (currentAvg * (totalMessages - 1) + latency) / totalMessages;
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    _isClosing = true;

    _connectTimeoutTimer?.cancel();
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();

    _updateConnectionState(WebSocketConnectionState.closed);

    if (_channel != null) {
      try {
        await _channel!.sink.close();
        AppLogger.info('WebSocket连接已主动关闭');
      } catch (e) {
        AppLogger.error('关闭WebSocket连接失败', e);
      } finally {
        _channel = null;
      }
    }
  }

  /// 重新连接
  Future<void> reconnect() async {
    await disconnect();
    _resetReconnectAttempts();
    await Future.delayed(const Duration(seconds: 1));
    await connect();
  }

  /// 销毁管理器
  Future<void> dispose() async {
    await disconnect();

    await _messageController.close();
    await _stateController.close();

    AppLogger.info('WebSocket管理器已销毁');
  }

  /// 获取连接统计信息
  Map<String, dynamic> getConnectionStats() {
    return {
      'state': _connectionState.toString(),
      'url': _config.url,
      'reconnectAttempts': _reconnectAttempts,
      'lastMessageTime': _lastMessageTime.toIso8601String(),
      'lastPingTime': _lastPingTime.toIso8601String(),
      'isConnected': isConnected,
      'isConnecting': isConnecting,
      'isReconnecting': isReconnecting,
      'qualityMetrics': _qualityMetrics,
      'config': _config.toJson(),
    };
  }
}
