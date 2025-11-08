import 'dart:async';
import 'dart:convert';
import '../utils/logger.dart';
import 'data_type.dart';
import 'data_fetch_strategy.dart';
import '../realtime/websocket_manager.dart';
import '../realtime/websocket_models.dart';

/// WebSocket数据获取策略
///
/// 实现基于WebSocket的实时数据获取策略，为未来的实时数据扩展预留接口
/// 当前作为适配器模式的基础，可以轻松切换到实际的WebSocket实现
class WebSocketStrategy extends BaseDataFetchStrategy {
  /// WebSocket管理器
  final WebSocketManager _webSocketManager;

  /// 支持的数据类型 (实时数据类型)
  static const List<DataType> _supportedDataTypes = [
    DataType.marketIndex,
    DataType.etfSpotPrice,
    DataType.macroeconomicIndicator,
    DataType.connectionStatus,
  ];

  /// 数据流控制器映射
  final Map<DataType, StreamController<DataItem>> _controllers = {};

  /// 连接状态订阅
  StreamSubscription<WebSocketConnectionState>? _connectionSubscription;

  /// 消息订阅
  StreamSubscription<WebSocketMessage>? _messageSubscription;

  /// 策略配置
  final WebSocketStrategyConfig config;

  WebSocketStrategy(this._webSocketManager,
      {this.config = const WebSocketStrategyConfig()}) {
    _initializeControllers();
  }

  @override
  String get name => 'WebSocketStrategy';

  @override
  bool supportsDataType(DataType dataType) {
    return _supportedDataTypes.contains(dataType);
  }

  /// 记录错误
  void _recordError(String message) {
    AppLogger.error('WebSocketStrategy: $message');
  }

  /// 更新状态
  void _updateState(WebSocketConnectionState newState) {
    AppLogger.debug('WebSocketStrategy connection state updated to: $newState');
  }

  /// 更新策略状态
  void _updateStrategyState(StrategyState newState) {
    AppLogger.debug('WebSocketStrategy state updated to: $newState');
  }

  @override
  int get priority => 95; // 高优先级，适合实时数据

  @override
  List<DataType> get supportedDataTypes =>
      List.unmodifiable(_supportedDataTypes);

  /// 初始化数据流控制器
  void _initializeControllers() {
    for (final dataType in _supportedDataTypes) {
      _controllers[dataType] = StreamController<DataItem>.broadcast();
    }
  }

  @override
  Future<void> onStart() async {
    try {
      AppLogger.info('Starting WebSocket strategy...');

      // 订阅连接状态变化
      _connectionSubscription = _webSocketManager.stateStream.listen(
        _handleConnectionStateChange,
      );

      // 订阅WebSocket消息
      _messageSubscription = _webSocketManager.messageStream.listen(
        _handleWebSocketMessage,
      );

      // 连接WebSocket
      await _webSocketManager.connect();

      AppLogger.info('WebSocket strategy started successfully');
    } catch (e) {
      AppLogger.error('Failed to start WebSocket strategy: $e');
      _recordError('Failed to start: $e');
      rethrow;
    }
  }

  @override
  Future<void> onStop() async {
    try {
      AppLogger.info('Stopping WebSocket strategy...');

      // 取消订阅
      await _connectionSubscription?.cancel();
      await _messageSubscription?.cancel();

      // 关闭所有控制器
      for (final controller in _controllers.values) {
        await controller.close();
      }
      _controllers.clear();

      // 断开WebSocket连接
      await _webSocketManager.disconnect();

      AppLogger.info('WebSocket strategy stopped successfully');
    } catch (e) {
      AppLogger.error('Failed to stop WebSocket strategy: $e');
      _recordError('Failed to stop: $e');
      rethrow;
    }
  }

  @override
  Stream<DataItem> getDataStream(DataType type,
      {Map<String, dynamic>? parameters}) {
    if (!_controllers.containsKey(type)) {
      return Stream.error(ArgumentError('Unsupported data type: ${type.code}'));
    }

    return _controllers[type]!.stream;
  }

  @override
  Future<FetchResult> fetchData(DataType type,
      {Map<String, dynamic>? parameters}) async {
    if (!supportsDataType(type)) {
      return FetchResult.failure(
          'WebSocket strategy does not support ${type.code}');
    }

    if (!isAvailable()) {
      return const FetchResult.failure('WebSocket strategy is not available');
    }

    try {
      // 构造请求消息
      final request = _buildRequestMessage(type, parameters);

      // 发送请求
      await _webSocketManager.sendMessage(request);

      // 等待响应 (使用超时)
      final responseFuture = _waitForResponse(type);
      final response = await responseFuture.timeout(
        const Duration(seconds: 10),
        onTimeout: () => null,
      );

      if (response != null) {
        return FetchResult.success(response);
      } else {
        return const FetchResult.failure('WebSocket request timeout');
      }
    } catch (e) {
      AppLogger.error('WebSocket fetch error for ${type.code}: $e');
      return FetchResult.failure('WebSocket fetch error: $e');
    }
  }

  /// 构造WebSocket请求消息
  WebSocketMessage _buildRequestMessage(
      DataType type, Map<String, dynamic>? parameters) {
    return WebSocketMessage(
      type: WebSocketMessageType.data,
      data: {
        'dataType': type.code,
        'parameters': parameters ?? {},
        'requestId': _generateRequestId(),
      },
      timestamp: DateTime.now(),
      id: _generateRequestId(),
    );
  }

  /// 生成请求ID
  String _generateRequestId() {
    return 'ws_${DateTime.now().millisecondsSinceEpoch}_${hashCode}';
  }

  /// 等待特定数据类型的响应
  Future<DataItem?> _waitForResponse(DataType type) async {
    final completer = Completer<DataItem?>();

    late StreamSubscription subscription;
    subscription = _controllers[type]!.stream.listen(
      (dataItem) {
        if (!completer.isCompleted) {
          completer.complete(dataItem);
          subscription.cancel();
        }
      },
      onError: (error) {
        if (!completer.isCompleted) {
          completer.completeError(error);
          subscription.cancel();
        }
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      },
    );

    // 设置超时
    Timer(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        completer.complete(null);
        subscription.cancel();
      }
    });

    return completer.future;
  }

  /// 处理连接状态变化
  void _handleConnectionStateChange(WebSocketConnectionState state) {
    switch (state) {
      case WebSocketConnectionState.connected:
        _updateStrategyState(StrategyState.running);
        AppLogger.info('WebSocket connected');
        break;

      case WebSocketConnectionState.connecting:
        _updateStrategyState(StrategyState.starting);
        break;

      case WebSocketConnectionState.reconnecting:
        AppLogger.info('WebSocket reconnecting...');
        break;

      case WebSocketConnectionState.disconnected:
        _updateStrategyState(StrategyState.stopped);
        AppLogger.warning('WebSocket disconnected');
        break;

      case WebSocketConnectionState.closed:
        _updateStrategyState(StrategyState.stopped);
        AppLogger.info('WebSocket connection closed');
        break;

      case WebSocketConnectionState.error:
        _updateStrategyState(StrategyState.error);
        AppLogger.error('WebSocket connection error');
        break;
    }
  }

  /// 处理WebSocket消息
  void _handleWebSocketMessage(WebSocketMessage message) {
    try {
      switch (message.type) {
        case WebSocketMessageType.data:
          _handleDataResponse(message);
          break;

        case WebSocketMessageType.status:
          _handleSystemNotification(message);
          break;

        case WebSocketMessageType.error:
          _handleErrorMessage(message);
          break;

        default:
          AppLogger.debug('Unhandled WebSocket message type: ${message.type}');
      }
    } catch (e) {
      AppLogger.error('Error handling WebSocket message: $e');
    }
  }

  /// 处理数据响应消息
  void _handleDataResponse(WebSocketMessage message) {
    try {
      final data = message.data;
      final dataTypeCode = data['dataType'] as String?;
      final dataType = DataType.fromCode(dataTypeCode ?? '');

      if (dataType == null) {
        AppLogger.warning(
            'Unknown data type in WebSocket response: $dataTypeCode');
        return;
      }

      final controller = _controllers[dataType];
      if (controller != null && !controller.isClosed) {
        final dataItem = DataItem(
          dataType: dataType,
          data: data['payload'],
          timestamp: DateTime.parse(data['timestamp'] as String),
          quality: _parseDataQuality(data['quality']),
          source: DataSource.websocket,
          id: data['id'] as String? ?? _generateRequestId(),
          expiresAt: _calculateExpirationTime(dataType),
        );

        controller.add(dataItem);
        AppLogger.debug('Received WebSocket data for ${dataType.code}');
      }
    } catch (e) {
      AppLogger.error('Error processing WebSocket data response: $e');
    }
  }

  /// 处理系统通知消息
  void _handleSystemNotification(WebSocketMessage message) {
    final notification = message.data;
    AppLogger.info('WebSocket system notification: $notification');

    // 如果有连接状态更新，发送到相应的控制器
    if (_controllers.containsKey(DataType.connectionStatus)) {
      final statusItem = DataItem(
        dataType: DataType.connectionStatus,
        data: notification,
        timestamp: DateTime.now(),
        quality: DataQualityLevel.good,
        source: DataSource.websocket,
        id: _generateRequestId(),
      );

      _controllers[DataType.connectionStatus]?.add(statusItem);
    }
  }

  /// 处理错误消息
  void _handleErrorMessage(WebSocketMessage message) {
    final error = message.data;
    AppLogger.error('WebSocket error message: $error');

    // 记录错误但不抛出异常
    _recordError('WebSocket error: $error');
  }

  /// 解析数据质量级别
  DataQualityLevel _parseDataQuality(dynamic qualityData) {
    if (qualityData is String) {
      return DataQualityLevel.values.firstWhere(
        (level) => level.name == qualityData,
        orElse: () => DataQualityLevel.good,
      );
    } else if (qualityData is int) {
      return DataQualityLevel.fromValue(qualityData);
    }
    return DataQualityLevel.good;
  }

  /// 计算数据过期时间
  DateTime? _calculateExpirationTime(DataType dataType) {
    // 实时数据较短过期时间
    if (dataType.isRealtime) {
      return DateTime.now().add(dataType.defaultUpdateInterval);
    }
    return null; // 其他数据不过期
  }

  @override
  Duration? getDefaultPollingInterval(DataType type) {
    // WebSocket不需要轮询，但返回数据类型的默认更新间隔作为参考
    return type.defaultUpdateInterval;
  }

  @override
  Map<String, dynamic> getConfig() {
    final baseConfig = super.getConfig();
    return {
      ...baseConfig,
      'config': {
        'autoReconnect': config.autoReconnect,
        'heartbeatInterval': config.heartbeatInterval.inSeconds,
        'maxReconnectAttempts': config.maxReconnectAttempts,
        'connectionTimeout': config.connectionTimeout.inSeconds,
      },
      'supportedDataTypes': _supportedDataTypes.map((t) => t.code).toList(),
    };
  }
}

/// WebSocket策略配置
class WebSocketStrategyConfig {
  /// 是否自动重连
  final bool autoReconnect;

  /// 心跳间隔
  final Duration heartbeatInterval;

  /// 最大重连次数
  final int maxReconnectAttempts;

  /// 连接超时时间
  final Duration connectionTimeout;

  /// 消息队列大小限制
  final int messageQueueLimit;

  /// 是否启用消息压缩
  final bool enableCompression;

  const WebSocketStrategyConfig({
    this.autoReconnect = true,
    this.heartbeatInterval = const Duration(seconds: 30),
    this.maxReconnectAttempts = 5,
    this.connectionTimeout = const Duration(seconds: 10),
    this.messageQueueLimit = 1000,
    this.enableCompression = true,
  });

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'autoReconnect': autoReconnect,
      'heartbeatInterval': heartbeatInterval.inSeconds,
      'maxReconnectAttempts': maxReconnectAttempts,
      'connectionTimeout': connectionTimeout.inSeconds,
      'messageQueueLimit': messageQueueLimit,
      'enableCompression': enableCompression,
    };
  }

  /// 从JSON创建配置
  factory WebSocketStrategyConfig.fromJson(Map<String, dynamic> json) {
    return WebSocketStrategyConfig(
      autoReconnect: json['autoReconnect'] as bool? ?? true,
      heartbeatInterval:
          Duration(seconds: json['heartbeatInterval'] as int? ?? 30),
      maxReconnectAttempts: json['maxReconnectAttempts'] as int? ?? 5,
      connectionTimeout:
          Duration(seconds: json['connectionTimeout'] as int? ?? 10),
      messageQueueLimit: json['messageQueueLimit'] as int? ?? 1000,
      enableCompression: json['enableCompression'] as bool? ?? true,
    );
  }
}
