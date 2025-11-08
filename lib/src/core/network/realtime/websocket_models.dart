/// WebSocket连接状态枚举
enum WebSocketConnectionState {
  /// 未连接
  disconnected,

  /// 连接中
  connecting,

  /// 已连接
  connected,

  /// 重连中
  reconnecting,

  /// 连接错误
  error,

  /// 已关闭
  closed,
}

/// WebSocket消息类型枚举
enum WebSocketMessageType {
  /// 数据消息
  data,

  /// 心跳ping
  ping,

  /// 心跳pong
  pong,

  /// 错误消息
  error,

  /// 连接状态变化
  status,
}

// ignore_for_file: sort_constructors_first
/// WebSocket连接配置
class WebSocketConnectionConfig {
  /// WebSocket服务器URL
  final String url;

  /// 连接超时时间
  final Duration connectTimeout;

  /// 心跳间隔时间
  final Duration heartbeatInterval;

  /// 重连基础间隔时间（指数退避）
  final Duration baseReconnectDelay;

  /// 最大重连间隔时间
  final Duration maxReconnectDelay;

  /// 最大重连次数（-1表示无限重连）
  final int maxReconnectAttempts;

  /// 是否启用自动重连
  final bool autoReconnect;

  /// 连接请求头
  final Map<String, String>? headers;

  /// 自定义协议
  final List<String>? protocols;

  /// 创建WebSocket连接配置
  const WebSocketConnectionConfig({
    required this.url,
    this.connectTimeout = const Duration(seconds: 10),
    this.heartbeatInterval = const Duration(seconds: 30),
    this.baseReconnectDelay = const Duration(seconds: 1),
    this.maxReconnectDelay = const Duration(seconds: 30),
    this.maxReconnectAttempts = -1,
    this.autoReconnect = true,
    this.headers,
    this.protocols,
  });

  /// 从JSON创建配置
  factory WebSocketConnectionConfig.fromJson(Map<String, dynamic> json) {
    return WebSocketConnectionConfig(
      url: json['url'] as String,
      connectTimeout:
          Duration(milliseconds: json['connectTimeout'] as int? ?? 10000),
      heartbeatInterval:
          Duration(milliseconds: json['heartbeatInterval'] as int? ?? 30000),
      baseReconnectDelay:
          Duration(milliseconds: json['baseReconnectDelay'] as int? ?? 1000),
      maxReconnectDelay:
          Duration(milliseconds: json['maxReconnectDelay'] as int? ?? 30000),
      maxReconnectAttempts: json['maxReconnectAttempts'] as int? ?? -1,
      autoReconnect: json['autoReconnect'] as bool? ?? true,
      headers: json['headers'] as Map<String, String>?,
      protocols: (json['protocols'] as List<dynamic>?)?.cast<String>(),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'connectTimeout': connectTimeout.inMilliseconds,
      'heartbeatInterval': heartbeatInterval.inMilliseconds,
      'baseReconnectDelay': baseReconnectDelay.inMilliseconds,
      'maxReconnectDelay': maxReconnectDelay.inMilliseconds,
      'maxReconnectAttempts': maxReconnectAttempts,
      'autoReconnect': autoReconnect,
      'headers': headers,
      'protocols': protocols,
    };
  }

  /// 复制并修改部分配置
  WebSocketConnectionConfig copyWith({
    String? url,
    Duration? connectTimeout,
    Duration? heartbeatInterval,
    Duration? baseReconnectDelay,
    Duration? maxReconnectDelay,
    int? maxReconnectAttempts,
    bool? autoReconnect,
    Map<String, String>? headers,
    List<String>? protocols,
  }) {
    return WebSocketConnectionConfig(
      url: url ?? this.url,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      heartbeatInterval: heartbeatInterval ?? this.heartbeatInterval,
      baseReconnectDelay: baseReconnectDelay ?? this.baseReconnectDelay,
      maxReconnectDelay: maxReconnectDelay ?? this.maxReconnectDelay,
      maxReconnectAttempts: maxReconnectAttempts ?? this.maxReconnectAttempts,
      autoReconnect: autoReconnect ?? this.autoReconnect,
      headers: headers ?? this.headers,
      protocols: protocols ?? this.protocols,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WebSocketConnectionConfig &&
        other.url == url &&
        other.connectTimeout == connectTimeout &&
        other.heartbeatInterval == heartbeatInterval &&
        other.baseReconnectDelay == baseReconnectDelay &&
        other.maxReconnectDelay == maxReconnectDelay &&
        other.maxReconnectAttempts == maxReconnectAttempts &&
        other.autoReconnect == autoReconnect &&
        other.headers == headers &&
        other.protocols == protocols;
  }

  @override
  int get hashCode {
    return Object.hash(
      url,
      connectTimeout,
      heartbeatInterval,
      baseReconnectDelay,
      maxReconnectDelay,
      maxReconnectAttempts,
      autoReconnect,
      headers,
      protocols,
    );
  }

  @override
  String toString() {
    return 'WebSocketConnectionConfig('
        'url: $url, '
        'connectTimeout: $connectTimeout, '
        'heartbeatInterval: $heartbeatInterval, '
        'baseReconnectDelay: $baseReconnectDelay, '
        'maxReconnectDelay: $maxReconnectDelay, '
        'maxReconnectAttempts: $maxReconnectAttempts, '
        'autoReconnect: $autoReconnect'
        ')';
  }
}

/// WebSocket消息封装类
class WebSocketMessage {
  /// 消息类型
  final WebSocketMessageType type;

  /// 消息内容
  final dynamic data;

  /// 时间戳
  final DateTime timestamp;

  /// 消息ID（可选）
  final String? id;

  /// 消息来源
  final String? source;

  /// 创建WebSocket消息
  const WebSocketMessage({
    required this.type,
    required this.data,
    required this.timestamp,
    this.id,
    this.source,
  });

  /// 创建数据消息
  factory WebSocketMessage.data(dynamic data, {String? id, String? source}) {
    return WebSocketMessage(
      type: WebSocketMessageType.data,
      data: data,
      timestamp: DateTime.now(),
      id: id,
      source: source,
    );
  }

  /// 创建心跳ping消息
  factory WebSocketMessage.ping({String? id}) {
    return WebSocketMessage(
      type: WebSocketMessageType.ping,
      data: 'ping',
      timestamp: DateTime.now(),
      id: id,
    );
  }

  /// 创建心跳pong消息
  factory WebSocketMessage.pong({String? id}) {
    return WebSocketMessage(
      type: WebSocketMessageType.pong,
      data: 'pong',
      timestamp: DateTime.now(),
      id: id,
    );
  }

  /// 创建错误消息
  factory WebSocketMessage.error(String error, {String? id, String? source}) {
    return WebSocketMessage(
      type: WebSocketMessageType.error,
      data: error,
      timestamp: DateTime.now(),
      id: id,
      source: source,
    );
  }

  /// 创建状态变化消息
  factory WebSocketMessage.status(WebSocketConnectionState state,
      {String? id}) {
    return WebSocketMessage(
      type: WebSocketMessageType.status,
      data: state.toString(),
      timestamp: DateTime.now(),
      id: id,
    );
  }

  /// 从JSON创建消息
  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketMessage(
      type: WebSocketMessageType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => WebSocketMessageType.data,
      ),
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp'] as String),
      id: json['id'] as String?,
      source: json['source'] as String?,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'id': id,
      'source': source,
    };
  }

  @override
  String toString() {
    return 'WebSocketMessage(type: $type, data: $data, timestamp: $timestamp, id: $id, source: $source)';
  }
}
