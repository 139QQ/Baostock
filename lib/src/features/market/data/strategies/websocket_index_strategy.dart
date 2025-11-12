import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../core/network/hybrid/data_fetch_strategy.dart';
import '../../../../core/network/hybrid/data_type.dart' as hybrid;
import '../../../../core/utils/logger.dart';
import '../../models/market_index_data.dart';

/// WebSocket指数数据策略
///
/// 为市场指数提供实时WebSocket数据获取能力
class WebSocketIndexStrategy extends DataFetchStrategy {
  @override
  String get name => 'WebSocketIndexStrategy';

  @override
  int get priority => 90; // 高优先级，优于HTTP轮询

  @override
  List<hybrid.DataType> get supportedDataTypes => [hybrid.DataType.marketIndex];

  /// 重试间隔
  Duration get defaultRetryInterval => const Duration(seconds: 5);

  /// 最大重试次数
  int get maxRetries => 3;

  /// WebSocket连接配置
  final WebSocketConfig _config;

  /// WebSocket连接
  WebSocketChannel? _channel;

  /// 连接状态
  WebSocketConnectionState _connectionState =
      WebSocketConnectionState.disconnected;

  /// 订阅的指数代码
  final Set<String> _subscribedIndices = {};

  /// 数据流控制器
  final StreamController<MarketIndexData> _dataController =
      StreamController<MarketIndexData>.broadcast();

  /// 状态流控制器
  final StreamController<WebSocketConnectionState> _stateController =
      StreamController<WebSocketConnectionState>.broadcast();

  /// 错误流控制器
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  /// 重连定时器
  Timer? _reconnectTimer;

  /// 心跳定时器
  Timer? _heartbeatTimer;

  /// 最后心跳时间
  DateTime _lastHeartbeat = DateTime.now();

  /// 连接统计
  final WebSocketStatistics _statistics = WebSocketStatistics();

  /// 构造函数
  WebSocketIndexStrategy({
    WebSocketConfig? config,
  }) : _config = config ?? const WebSocketConfig() {
    _initializeMessageHandlers();
  }

  /// 消息处理器
  final Map<String, MessageHandler> _messageHandlers = {};

  /// 初始化消息处理器
  void _initializeMessageHandlers() {
    _messageHandlers['index_data'] = _handleIndexDataMessage;
    _messageHandlers['heartbeat'] = _handleHeartbeatMessage;
    _messageHandlers['error'] = _handleErrorMessage;
    _messageHandlers['subscribe_response'] = _handleSubscribeResponseMessage;
    _messageHandlers['unsubscribe_response'] =
        _handleUnsubscribeResponseMessage;
  }

  /// 数据流
  Stream<MarketIndexData> get dataStream => _dataController.stream;

  /// 状态流
  Stream<WebSocketConnectionState> get stateStream => _stateController.stream;

  /// 错误流
  Stream<String> get errorStream => _errorController.stream;

  /// 当前连接状态
  WebSocketConnectionState get connectionState => _connectionState;

  /// 获取连接统计
  WebSocketStatistics get statistics => _statistics;

  /// 连接WebSocket
  Future<bool> connect() async {
    try {
      if (_connectionState == WebSocketConnectionState.connecting ||
          _connectionState == WebSocketConnectionState.connected) {
        return true;
      }

      _updateConnectionState(WebSocketConnectionState.connecting);

      final uri = Uri.parse(_config.websocketUrl);
      _channel = WebSocketChannel.connect(uri);

      await _channel!.ready;

      _setupChannelListeners();
      _startHeartbeat();
      _updateConnectionState(WebSocketConnectionState.connected);

      _statistics.recordConnection();
      AppLogger.info(
          'WebSocket connected successfully to ${_config.websocketUrl}');

      return true;
    } catch (e) {
      _updateConnectionState(WebSocketConnectionState.error);
      _errorController.add('WebSocket连接失败: $e');
      _statistics.recordError();
      AppLogger.error('WebSocket connection failed: $e', e);

      // 启动重连
      _scheduleReconnect();
      return false;
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    try {
      _reconnectTimer?.cancel();
      _heartbeatTimer?.cancel();

      if (_channel != null) {
        await _channel!.sink.close();
        _channel = null;
      }

      _updateConnectionState(WebSocketConnectionState.disconnected);
      _statistics.recordDisconnection();

      AppLogger.info('WebSocket disconnected');
    } catch (e) {
      AppLogger.error('Error during WebSocket disconnection: $e', e);
    }
  }

  /// 订阅指数数据
  Future<bool> subscribeIndex(String indexCode) async {
    try {
      if (!await _ensureConnected()) {
        return false;
      }

      if (_subscribedIndices.contains(indexCode)) {
        AppLogger.debug('Already subscribed to index: $indexCode');
        return true;
      }

      final subscribeMessage = {
        'type': 'subscribe',
        'data_type': 'market_index',
        'symbol': indexCode,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      _sendMessage(jsonEncode(subscribeMessage));
      _subscribedIndices.add(indexCode);

      _statistics.recordSubscription(indexCode);
      AppLogger.info('Subscribed to index: $indexCode');

      return true;
    } catch (e) {
      _errorController.add('订阅指数失败 $indexCode: $e');
      AppLogger.error('Failed to subscribe to index $indexCode: $e', e);
      return false;
    }
  }

  /// 取消订阅指数数据
  Future<bool> unsubscribeIndex(String indexCode) async {
    try {
      if (!_subscribedIndices.contains(indexCode)) {
        return true;
      }

      final unsubscribeMessage = {
        'type': 'unsubscribe',
        'data_type': 'market_index',
        'symbol': indexCode,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      _sendMessage(jsonEncode(unsubscribeMessage));
      _subscribedIndices.remove(indexCode);

      _statistics.recordUnsubscription(indexCode);
      AppLogger.info('Unsubscribed from index: $indexCode');

      return true;
    } catch (e) {
      _errorController.add('取消订阅指数失败 $indexCode: $e');
      AppLogger.error('Failed to unsubscribe from index $indexCode: $e', e);
      return false;
    }
  }

  /// 批量订阅指数
  Future<Map<String, bool>> subscribeIndices(List<String> indexCodes) async {
    final results = <String, bool>{};

    for (final indexCode in indexCodes) {
      results[indexCode] = await subscribeIndex(indexCode);
    }

    return results;
  }

  /// 获取当前订阅的指数列表
  Set<String> get subscribedIndices => Set.unmodifiable(_subscribedIndices);

  /// 发送消息
  void _sendMessage(String message) {
    try {
      if (_channel != null &&
          _connectionState == WebSocketConnectionState.connected) {
        _channel!.sink.add(message);
        _statistics.recordMessageSent(message.length);
        AppLogger.debug('WebSocket message sent: $message');
      }
    } catch (e) {
      _errorController.add('发送消息失败: $e');
      AppLogger.error('Failed to send WebSocket message: $e', e);
    }
  }

  /// 设置通道监听器
  void _setupChannelListeners() {
    _channel!.stream.listen(
      (message) {
        _handleMessage(message);
      },
      onError: (error) {
        _handleError(error);
      },
      onDone: () {
        _handleDisconnection();
      },
    );
  }

  /// 处理收到的消息
  void _handleMessage(dynamic message) {
    try {
      final messageStr = message.toString();
      _statistics.recordMessageReceived(messageStr.length);
      AppLogger.debug('WebSocket message received: $messageStr');

      // 解析JSON消息
      final Map<String, dynamic> messageData;
      try {
        messageData = jsonDecode(messageStr) as Map<String, dynamic>;
      } catch (e) {
        AppLogger.warn('Failed to parse WebSocket message as JSON: $e');
        _statistics.recordMessageParseError();
        return;
      }

      final messageType = messageData['type'] as String?;
      if (messageType != null && _messageHandlers.containsKey(messageType)) {
        _messageHandlers[messageType]!(messageData);
      } else {
        AppLogger.debug('Unknown message type: $messageType');
      }
    } catch (e) {
      _errorController.add('处理消息失败: $e');
      AppLogger.error('Error handling WebSocket message: $e', e);
    }
  }

  /// 处理指数数据消息
  void _handleIndexDataMessage(Map<String, dynamic> data) {
    try {
      final indexData = _parseIndexData(data['data'] as Map<String, dynamic>);
      if (indexData != null) {
        _dataController.add(indexData);
        _statistics.recordDataReceived();
      }
    } catch (e) {
      AppLogger.error('Error parsing index data: $e', e);
    }
  }

  /// 处理心跳消息
  void _handleHeartbeatMessage(Map<String, dynamic> data) {
    _lastHeartbeat = DateTime.now();
    AppLogger.debug('WebSocket heartbeat received');
  }

  /// 处理错误消息
  void _handleErrorMessage(Map<String, dynamic> data) {
    final errorMessage = data['message'] as String? ?? '未知错误';
    _errorController.add('服务器错误: $errorMessage');
    AppLogger.warn('WebSocket server error: $errorMessage');
  }

  /// 处理订阅响应消息
  void _handleSubscribeResponseMessage(Map<String, dynamic> data) {
    final symbol = data['symbol'] as String?;
    final success = data['success'] as bool? ?? false;

    if (symbol != null) {
      if (success) {
        AppLogger.info('Successfully subscribed to $symbol');
      } else {
        AppLogger.warn('Failed to subscribe to $symbol');
        _subscribedIndices.remove(symbol);
      }
    }
  }

  /// 处理取消订阅响应消息
  void _handleUnsubscribeResponseMessage(Map<String, dynamic> data) {
    final symbol = data['symbol'] as String?;
    final success = data['success'] as bool? ?? false;

    if (symbol != null && success) {
      AppLogger.info('Successfully unsubscribed from $symbol');
    }
  }

  /// 解析指数数据
  MarketIndexData? _parseIndexData(Map<String, dynamic> data) {
    try {
      return MarketIndexData.fromJson(data);
    } catch (e) {
      AppLogger.error('Failed to parse index data: $e', e);
      return null;
    }
  }

  /// 处理错误
  void _handleError(dynamic error) {
    _updateConnectionState(WebSocketConnectionState.error);
    _errorController.add('WebSocket错误: $error');
    _statistics.recordError();
    AppLogger.error('WebSocket error: $error', error);

    // 启动重连
    _scheduleReconnect();
  }

  /// 处理断开连接
  void _handleDisconnection() {
    _updateConnectionState(WebSocketConnectionState.disconnected);
    _statistics.recordDisconnection();
    AppLogger.warn('WebSocket disconnected');

    // 清理心跳
    _heartbeatTimer?.cancel();

    // 启动重连
    _scheduleReconnect();
  }

  /// 更新连接状态
  void _updateConnectionState(WebSocketConnectionState newState) {
    if (_connectionState != newState) {
      final oldState = _connectionState;
      _connectionState = newState;
      _stateController.add(newState);

      AppLogger.info(
          'WebSocket state changed: ${oldState.name} → ${newState.name}');
    }
  }

  /// 确保连接
  Future<bool> _ensureConnected() async {
    if (_connectionState == WebSocketConnectionState.connected) {
      return true;
    }

    return await connect();
  }

  /// 启动心跳
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_config.heartbeatInterval, (_) {
      _sendHeartbeat();
      _checkHeartbeatTimeout();
    });
  }

  /// 发送心跳
  void _sendHeartbeat() {
    final heartbeatMessage = {
      'type': 'heartbeat',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    _sendMessage(jsonEncode(heartbeatMessage));
  }

  /// 检查心跳超时
  void _checkHeartbeatTimeout() {
    final now = DateTime.now();
    final timeSinceLastHeartbeat = now.difference(_lastHeartbeat);

    if (timeSinceLastHeartbeat > _config.heartbeatTimeout) {
      _errorController.add('心跳超时，可能连接已断开');
      AppLogger.warn('WebSocket heartbeat timeout');

      // 触发重新连接
      disconnect();
      _scheduleReconnect();
    }
  }

  /// 安排重连
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();

    _reconnectTimer = Timer(_config.reconnectDelay, () async {
      AppLogger.info('Attempting to reconnect WebSocket...');
      await connect();
    });
  }

  /// 获取连接健康状态
  WebSocketHealthStatus getConnectionHealthStatus() {
    final now = DateTime.now();
    final uptime = _connectionState == WebSocketConnectionState.connected
        ? now.difference(_statistics.lastConnectionTime)
        : Duration.zero;

    final isHealthy = _connectionState == WebSocketConnectionState.connected &&
        now.difference(_lastHeartbeat) < _config.heartbeatTimeout;

    return WebSocketHealthStatus(
      isConnected: _connectionState == WebSocketConnectionState.connected,
      isHealthy: isHealthy,
      uptime: uptime,
      subscribedIndices: _subscribedIndices.toList(),
      lastHeartbeat: _lastHeartbeat,
      statistics: _statistics,
    );
  }

  /// 销毁策略
  Future<void> dispose() async {
    await disconnect();

    _dataController.close();
    _stateController.close();
    _errorController.close();

    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();

    AppLogger.info('WebSocketIndexStrategy disposed');
  }

  // 实现 DataFetchStrategy 接口要求的抽象方法

  @override
  bool isAvailable() {
    return _connectionState == WebSocketConnectionState.connected;
  }

  @override
  Stream<DataItem> getDataStream(hybrid.DataType type,
      {Map<String, dynamic>? parameters}) {
    if (type != hybrid.DataType.marketIndex) {
      return const Stream.empty();
    }

    return _dataController.stream.map((marketIndexData) => DataItem(
          dataType: type,
          data: marketIndexData.toJson(),
          timestamp: marketIndexData.updateTime,
          quality: hybrid.DataQualityLevel.good,
          source: DataSource.websocket,
          id: '${marketIndexData.code}_${marketIndexData.updateTime.millisecondsSinceEpoch}',
          dataKey: marketIndexData.code,
        ));
  }

  @override
  Future<FetchResult> fetchData(hybrid.DataType type,
      {Map<String, dynamic>? parameters}) async {
    if (type != hybrid.DataType.marketIndex) {
      return const FetchResult.failure('Unsupported data type');
    }

    if (!isAvailable()) {
      return const FetchResult.failure('WebSocket not connected');
    }

    try {
      // 获取最新的数据项
      final latestData = await _dataController.stream.first;

      final dataItem = DataItem(
        dataType: type,
        data: latestData.toJson(),
        timestamp: latestData.updateTime,
        quality: hybrid.DataQualityLevel.good,
        source: DataSource.websocket,
        id: '${latestData.code}_${latestData.updateTime.millisecondsSinceEpoch}',
        dataKey: latestData.code,
      );

      return FetchResult.success(dataItem);
    } catch (e) {
      return FetchResult.failure('Failed to fetch data: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getHealthStatus() async {
    final healthStatus = getConnectionHealthStatus();

    return {
      'strategy': name,
      'connectionState': _connectionState.name,
      'isConnected': healthStatus.isConnected,
      'isHealthy': healthStatus.isHealthy,
      'uptime': healthStatus.uptime.inMilliseconds,
      'subscribedIndices': healthStatus.subscribedIndices,
      'lastHeartbeat': healthStatus.lastHeartbeat.toIso8601String(),
      'statistics': {
        'totalConnections': healthStatus.statistics.totalConnections,
        'totalErrors': healthStatus.statistics.totalErrors,
        'totalSubscriptions': healthStatus.statistics.totalSubscriptions,
        'totalMessagesSent': healthStatus.statistics.totalMessagesSent,
        'totalMessagesReceived': healthStatus.statistics.totalMessagesReceived,
        'totalBytesSent': healthStatus.statistics.totalBytesSent,
        'totalBytesReceived': healthStatus.statistics.totalBytesReceived,
        'connectionSuccessRate': healthStatus.statistics.connectionSuccessRate,
        'averageMessageSize': healthStatus.statistics.averageMessageSize,
        'lastConnectionTime':
            healthStatus.statistics.lastConnectionTime.toIso8601String(),
        'lastMessageTime':
            healthStatus.statistics.lastMessageTime.toIso8601String(),
      },
    };
  }

  @override
  Future<void> start() async {
    AppLogger.info('Starting WebSocketIndexStrategy...');
    await connect();
  }

  @override
  Future<void> stop() async {
    AppLogger.info('Stopping WebSocketIndexStrategy...');
    await disconnect();
  }

  @override
  Duration? getDefaultPollingInterval(hybrid.DataType type) {
    // WebSocket 不需要轮询，返回 null
    return null;
  }

  @override
  Map<String, dynamic> getConfig() {
    return {
      'name': name,
      'priority': priority,
      'supportedDataTypes': supportedDataTypes.map((e) => e.name).toList(),
      'url': _config.url,
      'heartbeatInterval': _config.heartbeatInterval.inMilliseconds,
      'heartbeatTimeout': _config.heartbeatTimeout.inMilliseconds,
      'maxReconnectAttempts': _config.maxReconnectAttempts,
      'reconnectDelay': _config.reconnectDelay.inMilliseconds,
      'connectionTimeout': _config.connectionTimeout.inMilliseconds,
    };
  }

  @override
  String toString() {
    return 'WebSocketIndexStrategy(state: $_connectionState, subscriptions: ${_subscribedIndices.length})';
  }
}

/// WebSocket连接状态
enum WebSocketConnectionState {
  /// 已断开连接
  disconnected,

  /// 连接中
  connecting,

  /// 已连接
  connected,

  /// 重连中
  reconnecting,

  /// 连接错误
  error;

  /// 获取状态描述
  String get description {
    switch (this) {
      case WebSocketConnectionState.disconnected:
        return '已断开';
      case WebSocketConnectionState.connecting:
        return '连接中';
      case WebSocketConnectionState.connected:
        return '已连接';
      case WebSocketConnectionState.reconnecting:
        return '重连中';
      case WebSocketConnectionState.error:
        return '连接错误';
    }
  }
}

/// WebSocket配置
class WebSocketConfig {
  /// WebSocket URL
  final String websocketUrl;

  /// URL 别名
  final String url;

  /// 心跳间隔
  final Duration heartbeatInterval;

  /// 心跳超时
  final Duration heartbeatTimeout;

  /// 重连延迟
  final Duration reconnectDelay;

  /// 连接超时
  final Duration connectionTimeout;

  /// 最大消息大小
  final int maxMessageSize;

  /// 最大重连次数
  final int maxReconnectAttempts;

  /// 是否启用压缩
  final bool enableCompression;

  /// 请求头
  final Map<String, String> headers;

  /// 创建WebSocket配置
  const WebSocketConfig({
    this.websocketUrl = 'ws://localhost:8080/ws',
    this.url = 'ws://localhost:8080/ws',
    this.heartbeatInterval = const Duration(seconds: 30),
    this.heartbeatTimeout = const Duration(seconds: 90),
    this.reconnectDelay = const Duration(seconds: 5),
    this.connectionTimeout = const Duration(seconds: 10),
    this.maxMessageSize = 1024 * 1024, // 1MB
    this.maxReconnectAttempts = 5,
    this.enableCompression = true,
    this.headers = const {},
  });
}

/// WebSocket统计信息
class WebSocketStatistics {
  /// 总连接次数
  int totalConnections = 0;

  /// 总断开连接次数
  int totalDisconnections = 0;

  /// 总错误次数
  int totalErrors = 0;

  /// 总订阅次数
  int totalSubscriptions = 0;

  /// 总取消订阅次数
  int totalUnsubscriptions = 0;

  /// 总发送消息数
  int totalMessagesSent = 0;

  /// 总接收消息数
  int totalMessagesReceived = 0;

  /// 总发送字节数
  int totalBytesSent = 0;

  /// 总接收字节数
  int totalBytesReceived = 0;

  /// 总接收数据数
  int totalDataReceived = 0;

  /// 总解析错误数
  int totalParseErrors = 0;

  /// 最后连接时间
  DateTime lastConnectionTime = DateTime.now();

  /// 最后断开连接时间
  DateTime lastDisconnectionTime = DateTime.now();

  /// 最后消息时间
  DateTime lastMessageTime = DateTime.now();

  /// 记录连接
  void recordConnection() {
    totalConnections++;
    lastConnectionTime = DateTime.now();
  }

  /// 记录断开连接
  void recordDisconnection() {
    totalDisconnections++;
    lastDisconnectionTime = DateTime.now();
  }

  /// 记录错误
  void recordError() {
    totalErrors++;
  }

  /// 记录订阅
  void recordSubscription(String symbol) {
    totalSubscriptions++;
  }

  /// 记录取消订阅
  void recordUnsubscription(String symbol) {
    totalUnsubscriptions++;
  }

  /// 记录发送的消息
  void recordMessageSent(int bytes) {
    totalMessagesSent++;
    totalBytesSent += bytes;
    lastMessageTime = DateTime.now();
  }

  /// 记录接收的消息
  void recordMessageReceived(int bytes) {
    totalMessagesReceived++;
    totalBytesReceived += bytes;
    lastMessageTime = DateTime.now();
  }

  /// 记录接收的数据
  void recordDataReceived() {
    totalDataReceived++;
  }

  /// 记录解析错误
  void recordMessageParseError() {
    totalParseErrors++;
  }

  /// 获取连接成功率
  double get connectionSuccessRate {
    final total = totalConnections + totalErrors;
    return total > 0 ? totalConnections / total : 0.0;
  }

  /// 获取平均消息大小
  double get averageMessageSize {
    final total = totalMessagesSent + totalMessagesReceived;
    final bytes = totalBytesSent + totalBytesReceived;
    return total > 0 ? bytes / total : 0.0;
  }

  @override
  String toString() {
    return 'WebSocketStats(connections: $totalConnections, errors: $totalErrors, subscriptions: $totalSubscriptions)';
  }
}

/// WebSocket健康状态
class WebSocketHealthStatus {
  /// 是否已连接
  final bool isConnected;

  /// 是否健康
  final bool isHealthy;

  /// 运行时间
  final Duration uptime;

  /// 订阅的指数列表
  final List<String> subscribedIndices;

  /// 最后心跳时间
  final DateTime lastHeartbeat;

  /// 统计信息
  final WebSocketStatistics statistics;

  /// 创建WebSocket健康状态
  const WebSocketHealthStatus({
    required this.isConnected,
    required this.isHealthy,
    required this.uptime,
    required this.subscribedIndices,
    required this.lastHeartbeat,
    required this.statistics,
  });

  @override
  String toString() {
    return 'WebSocketHealth(connected: $isConnected, healthy: $isHealthy, uptime: $uptime)';
  }
}

/// 消息处理器类型定义
typedef MessageHandler = void Function(Map<String, dynamic> data);
