import 'dart:async';
import 'dart:convert';
import '../hybrid/data_type.dart';
import '../utils/logger.dart';

// ignore_for_file: sort_constructors_first, public_member_api_docs, directives_ordering, no_default_cases
/// 实时数据服务抽象接口
///
/// 为WebSocket和其他实时数据传输方式提供统一的抽象接口
/// 支持插拔式实现，不影响现有功能
abstract class RealtimeDataService {
  /// 服务名称
  String get name;

  /// 服务状态
  RealtimeServiceState get state;

  /// 支持的数据类型
  Set<DataType> get supportedDataTypes;

  /// 状态变化流
  Stream<RealtimeServiceState> get stateStream;

  /// 数据接收流
  Stream<RealtimeDataEvent> get dataStream;

  /// 初始化服务
  Future<void> initialize(RealtimeServiceConfig config);

  /// 启动服务
  Future<void> start();

  /// 停止服务
  Future<void> stop();

  /// 订阅数据
  Future<SubscriptionResult> subscribe(DataType dataType,
      {Map<String, dynamic>? parameters});

  /// 取消订阅
  Future<void> unsubscribe(DataType dataType);

  /// 发送消息
  Future<void> sendMessage(RealtimeMessage message);

  /// 获取健康状态
  Future<Map<String, dynamic>> getHealthStatus();

  /// 释放资源
  Future<void> dispose();
}

/// 实时数据服务状态
enum RealtimeServiceState {
  /// 未初始化
  uninitialized,

  /// 初始化中
  initializing,

  /// 已就绪
  ready,

  /// 连接中
  connecting,

  /// 已连接
  connected,

  /// 重连中
  reconnecting,

  /// 已断开
  disconnected,

  /// 错误状态
  error,

  /// 已停止
  stopped;

  /// 获取状态描述
  String get description {
    switch (this) {
      case RealtimeServiceState.uninitialized:
        return '未初始化';
      case RealtimeServiceState.initializing:
        return '初始化中';
      case RealtimeServiceState.ready:
        return '已就绪';
      case RealtimeServiceState.connecting:
        return '连接中';
      case RealtimeServiceState.connected:
        return '已连接';
      case RealtimeServiceState.reconnecting:
        return '重连中';
      case RealtimeServiceState.disconnected:
        return '已断开';
      case RealtimeServiceState.error:
        return '错误状态';
      case RealtimeServiceState.stopped:
        return '已停止';
    }
  }

  /// 是否为连接状态
  bool get isConnected {
    switch (this) {
      case RealtimeServiceState.connected:
        return true;
      case RealtimeServiceState.uninitialized:
      case RealtimeServiceState.initializing:
      case RealtimeServiceState.ready:
      case RealtimeServiceState.connecting:
      case RealtimeServiceState.reconnecting:
      case RealtimeServiceState.disconnected:
      case RealtimeServiceState.error:
      case RealtimeServiceState.stopped:
        return false;
    }
  }

  /// 是否为活动状态
  bool get isActive {
    switch (this) {
      case RealtimeServiceState.ready:
      case RealtimeServiceState.connecting:
      case RealtimeServiceState.connected:
      case RealtimeServiceState.reconnecting:
        return true;
      case RealtimeServiceState.uninitialized:
      case RealtimeServiceState.initializing:
      case RealtimeServiceState.disconnected:
      case RealtimeServiceState.error:
      case RealtimeServiceState.stopped:
        return false;
    }
  }
}

/// 实时数据服务配置
class RealtimeServiceConfig {
  /// 服务URL
  final String url;

  /// 连接超时
  final Duration connectTimeout;

  /// 心跳间隔
  final Duration heartbeatInterval;

  /// 重连配置
  final ReconnectConfig reconnectConfig;

  /// 认证信息
  final String? authToken;

  /// 是否启用调试模式
  final bool enableDebugMode;

  /// 自定义头部
  final Map<String, String> headers;

  /// 消息压缩
  final bool enableCompression;

  /// 缓冲区大小
  final int bufferSize;

  const RealtimeServiceConfig({
    required this.url,
    this.connectTimeout = const Duration(seconds: 10),
    this.heartbeatInterval = const Duration(seconds: 30),
    this.reconnectConfig = const ReconnectConfig(),
    this.authToken,
    this.enableDebugMode = false,
    this.headers = const {},
    this.enableCompression = false,
    this.bufferSize = 1024 * 1024, // 1MB
  });
}

/// 重连配置
class ReconnectConfig {
  /// 是否启用自动重连
  final bool enabled;

  /// 基础重连延迟
  final Duration baseDelay;

  /// 最大重连延迟
  final Duration maxDelay;

  /// 最大重连次数 (-1表示无限重连)
  final int maxAttempts;

  /// 指数退避因子
  final double backoffFactor;

  const ReconnectConfig({
    this.enabled = true,
    this.baseDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.maxAttempts = -1,
    this.backoffFactor = 2.0,
  });
}

/// 实时数据事件
class RealtimeDataEvent {
  /// 数据类型
  final DataType dataType;

  /// 事件类型
  final RealtimeEventType eventType;

  /// 数据内容
  final Map<String, dynamic> data;

  /// 事件时间戳
  final DateTime timestamp;

  /// 事件ID
  final String eventId;

  /// 额外元数据
  final Map<String, dynamic>? metadata;

  const RealtimeDataEvent({
    required this.dataType,
    required this.eventType,
    required this.data,
    required this.timestamp,
    required this.eventId,
    this.metadata,
  });

  /// 创建数据更新事件
  factory RealtimeDataEvent.dataUpdate({
    required DataType dataType,
    required Map<String, dynamic> data,
    String? eventId,
    Map<String, dynamic>? metadata,
  }) {
    return RealtimeDataEvent(
      dataType: dataType,
      eventType: RealtimeEventType.dataUpdate,
      data: data,
      timestamp: DateTime.now(),
      eventId: eventId ?? _generateEventId(),
      metadata: metadata,
    );
  }

  /// 创建错误事件
  factory RealtimeDataEvent.error({
    required DataType dataType,
    required String error,
    String? eventId,
    Map<String, dynamic>? metadata,
  }) {
    return RealtimeDataEvent(
      dataType: dataType,
      eventType: RealtimeEventType.error,
      data: {'error': error},
      timestamp: DateTime.now(),
      eventId: eventId ?? _generateEventId(),
      metadata: metadata,
    );
  }

  /// 生成事件ID
  static String _generateEventId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'dataType': dataType.name,
      'eventType': eventType.name,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'eventId': eventId,
      'metadata': metadata,
    };
  }

  /// 从JSON创建
  factory RealtimeDataEvent.fromJson(Map<String, dynamic> json) {
    return RealtimeDataEvent(
      dataType: DataType.values.firstWhere(
        (type) => type.name == json['dataType'],
        orElse: () => DataType.unknown,
      ),
      eventType: RealtimeEventType.values.firstWhere(
        (type) => type.name == json['eventType'],
        orElse: () => RealtimeEventType.unknown,
      ),
      data: json['data'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
      eventId: json['eventId'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

/// 实时事件类型
enum RealtimeEventType {
  /// 数据更新
  dataUpdate,

  /// 连接建立
  connectionEstablished,

  /// 连接断开
  connectionLost,

  /// 错误事件
  error,

  /// 心跳事件
  heartbeat,

  /// 订阅确认
  subscriptionConfirmed,

  /// 取消订阅确认
  unsubscriptionConfirmed,

  /// 未知事件
  unknown;
}

/// 订阅结果
class SubscriptionResult {
  /// 是否成功
  final bool success;

  /// 订阅ID
  final String? subscriptionId;

  /// 错误信息
  final String? error;

  /// 订阅时间
  final DateTime timestamp;

  const SubscriptionResult({
    required this.success,
    this.subscriptionId,
    this.error,
    required this.timestamp,
  });

  /// 创建成功结果
  factory SubscriptionResult.success({
    required String subscriptionId,
  }) {
    return SubscriptionResult(
      success: true,
      subscriptionId: subscriptionId,
      timestamp: DateTime.now(),
    );
  }

  /// 创建失败结果
  factory SubscriptionResult.failure({
    required String error,
  }) {
    return SubscriptionResult(
      success: false,
      error: error,
      timestamp: DateTime.now(),
    );
  }
}

/// 实时消息
class RealtimeMessage {
  /// 消息类型
  final RealtimeMessageType type;

  /// 消息内容
  final Map<String, dynamic> payload;

  /// 消息ID
  final String messageId;

  /// 时间戳
  final DateTime timestamp;

  const RealtimeMessage({
    required this.type,
    required this.payload,
    required this.messageId,
    required this.timestamp,
  });

  /// 创建订阅消息
  factory RealtimeMessage.subscribe({
    required DataType dataType,
    Map<String, dynamic>? parameters,
  }) {
    return RealtimeMessage(
      type: RealtimeMessageType.subscribe,
      payload: {
        'dataType': dataType.name,
        if (parameters != null) 'parameters': parameters,
      },
      messageId: _generateMessageId(),
      timestamp: DateTime.now(),
    );
  }

  /// 创建取消订阅消息
  factory RealtimeMessage.unsubscribe({
    required DataType dataType,
    String? subscriptionId,
  }) {
    return RealtimeMessage(
      type: RealtimeMessageType.unsubscribe,
      payload: {
        'dataType': dataType.name,
        if (subscriptionId != null) 'subscriptionId': subscriptionId,
      },
      messageId: _generateMessageId(),
      timestamp: DateTime.now(),
    );
  }

  /// 创建心跳消息
  factory RealtimeMessage.heartbeat() {
    return RealtimeMessage(
      type: RealtimeMessageType.heartbeat,
      payload: {'timestamp': DateTime.now().toIso8601String()},
      messageId: _generateMessageId(),
      timestamp: DateTime.now(),
    );
  }

  /// 创建认证消息
  factory RealtimeMessage.authenticate({
    required String token,
  }) {
    return RealtimeMessage(
      type: RealtimeMessageType.authenticate,
      payload: {'token': token},
      messageId: _generateMessageId(),
      timestamp: DateTime.now(),
    );
  }

  /// 生成消息ID
  static String _generateMessageId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  /// 序列化为JSON字符串
  String toJsonString() {
    return jsonEncode({
      'type': type.name,
      'payload': payload,
      'messageId': messageId,
      'timestamp': timestamp.toIso8601String(),
    });
  }

  /// 从JSON字符串解析
  factory RealtimeMessage.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return RealtimeMessage(
      type: RealtimeMessageType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => RealtimeMessageType.unknown,
      ),
      payload: json['payload'] as Map<String, dynamic>,
      messageId: json['messageId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// 实时消息类型
enum RealtimeMessageType {
  /// 订阅
  subscribe,

  /// 取消订阅
  unsubscribe,

  /// 心跳
  heartbeat,

  /// 认证
  authenticate,

  /// 数据请求
  dataRequest,

  /// 数据响应
  dataResponse,

  /// 错误
  error,

  /// 未知消息
  unknown;
}

/// 实时数据服务管理器
///
/// 管理多个实时数据服务实例，提供统一的访问接口
class RealtimeServiceManager {
  static final RealtimeServiceManager _instance =
      RealtimeServiceManager._internal();

  factory RealtimeServiceManager() => _instance;

  RealtimeServiceManager._internal() {
    _initialize();
  }

  /// 注册的服务
  final Map<String, RealtimeDataService> _services = {};

  /// 是否已初始化
  bool _isInitialized = false;

  /// 初始化管理器
  void _initialize() {
    if (_isInitialized) return;

    AppLogger.info('RealtimeServiceManager: 初始化实时数据服务管理器');
    _isInitialized = true;
  }

  /// 注册服务
  void registerService(RealtimeDataService service) {
    if (_services.containsKey(service.name)) {
      AppLogger.warn('RealtimeServiceManager: 服务已存在，将被覆盖', service.name);
    }

    _services[service.name] = service;
    AppLogger.info('RealtimeServiceManager: 注册服务', service.name);
  }

  /// 获取服务
  RealtimeDataService? getService(String name) {
    return _services[name];
  }

  /// 获取所有服务
  Map<String, RealtimeDataService> getAllServices() {
    return Map.unmodifiable(_services);
  }

  /// 启动所有服务
  Future<void> startAllServices() async {
    AppLogger.info('RealtimeServiceManager: 启动所有服务');

    for (final service in _services.values) {
      try {
        await service.start();
        AppLogger.debug('RealtimeServiceManager: 服务启动成功', service.name);
      } catch (e) {
        AppLogger.error(
            'RealtimeServiceManager: 服务启动失败', '${service.name}: $e');
      }
    }
  }

  /// 停止所有服务
  Future<void> stopAllServices() async {
    AppLogger.info('RealtimeServiceManager: 停止所有服务');

    for (final service in _services.values) {
      try {
        await service.stop();
        AppLogger.debug('RealtimeServiceManager: 服务停止成功', service.name);
      } catch (e) {
        AppLogger.error(
            'RealtimeServiceManager: 服务停止失败', '${service.name}: $e');
      }
    }
  }

  /// 释放所有服务
  Future<void> disposeAllServices() async {
    AppLogger.info('RealtimeServiceManager: 释放所有服务');

    for (final service in _services.values) {
      try {
        await service.dispose();
      } catch (e) {
        AppLogger.error(
            'RealtimeServiceManager: 服务释放失败', '${service.name}: $e');
      }
    }

    _services.clear();
    _isInitialized = false;
    AppLogger.info('RealtimeServiceManager: 所有服务已释放');
  }

  /// 获取管理器状态
  Map<String, dynamic> getStatus() {
    return {
      'initialized': _isInitialized,
      'serviceCount': _services.length,
      'services': _services.map((name, service) => MapEntry(
            name,
            {
              'name': service.name,
              'state': service.state.name,
              'supportedDataTypes':
                  service.supportedDataTypes.map((t) => t.name).toList(),
            },
          )),
    };
  }
}
