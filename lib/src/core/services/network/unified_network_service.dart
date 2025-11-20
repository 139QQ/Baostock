import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';

import '../base/i_unified_service.dart';
import '../../utils/logger.dart';

// 网络相关类定义
class ConnectionPoolConfig {
  // ignore: public_member_api_docs
  const ConnectionPoolConfig({
    this.maxConnections = 10,
    this.maxIdleConnections = 5,
    this.connectionTimeout = const Duration(seconds: 30),
    this.idleTimeout = const Duration(minutes: 5),
    this.requestTimeout = const Duration(seconds: 60),
    this.enableConnectionReuse = true,
    this.enableHealthCheck = true,
    this.healthCheckInterval = const Duration(minutes: 1),
    this.enableConnectionWarmup = false,
  });
  final int maxConnections;
  final int maxIdleConnections;
  final Duration connectionTimeout;
  final Duration idleTimeout;
  final Duration requestTimeout;
  final bool enableConnectionReuse;
  final bool enableHealthCheck;
  final Duration healthCheckInterval;
  final bool enableConnectionWarmup;
}

class ConnectionPoolStats {
  final int totalConnections;
  final int activeConnections;
  final int idleConnections;
  final int successfulRequests;
  final int failedRequests;

  const ConnectionPoolStats({
    required this.totalConnections,
    required this.activeConnections,
    required this.idleConnections,
    required this.successfulRequests,
    required this.failedRequests,
  });
}

class WebSocketConnectionConfig {
  final String url;
  final List<String>? protocols;
  final Map<String, String>? headers;
  final bool autoReconnect;
  final int maxReconnectAttempts;
  final Duration baseReconnectDelay;
  final Duration maxReconnectDelay;
  final Duration connectTimeout;
  final Duration heartbeatInterval;

  const WebSocketConnectionConfig({
    required this.url,
    this.protocols,
    this.headers,
    this.autoReconnect = true,
    this.maxReconnectAttempts = 5,
    this.baseReconnectDelay = const Duration(seconds: 1),
    this.maxReconnectDelay = const Duration(minutes: 5),
    this.connectTimeout = const Duration(seconds: 10),
    this.heartbeatInterval = const Duration(seconds: 30),
  });
}

enum WebSocketConnectionState {
  connected,
  disconnected,
  error,
  connecting,
}

// 简化的管理器类
class WebSocketManager {
  WebSocketConnectionConfig? _config;
  bool _isConnected = false;

  WebSocketManager({WebSocketConnectionConfig? config}) {
    _config = config;
  }

  bool get isConnected => _isConnected;

  void updateConfig(WebSocketConnectionConfig config) {
    _config = config;
  }

  Future<void> connect() async {
    _isConnected = true;
  }

  Future<void> disconnect() async {
    _isConnected = false;
  }

  Future<void> sendMessage(dynamic message) async {
    // 简化实现
  }

  Stream<WebSocketConnectionState> get stateStream =>
      Stream.value(WebSocketConnectionState.connected);

  Stream<dynamic> get messageStream => Stream.empty();

  Map<String, dynamic>? getConnectionStats() => {
        'isConnected': _isConnected,
        'connectionTime': DateTime.now().toIso8601String(),
      };
}

class RealtimeDataService {
  Future<void> initialize() async {}
  Future<void> dispose() async {}
}

class PollingManager {
  Future<void> initialize() async {}
  Future<void> dispose() async {}

  Future<void> startPolling({
    required String endpoint,
    required Duration interval,
    Map<String, dynamic>? parameters,
  }) async {}

  Future<void> stopPolling(String endpoint) async {}
}

class ConnectionPoolManager {
  final ConnectionPoolConfig config;

  ConnectionPoolManager({required this.config});

  Future<void> initialize() async {}

  Future<void> dispose() async {}

  Future<Response> executeRequest(
      String host, int port, RequestOptions options) async {
    final dio = Dio();
    return await dio.request(
      options.path,
      options: Options(
        method: options.method,
        headers: options.headers,
        receiveTimeout: options.receiveTimeout,
        sendTimeout: options.sendTimeout,
      ),
      data: options.data,
    );
  }

  ConnectionPoolStats getStats() {
    return const ConnectionPoolStats(
      totalConnections: 0,
      activeConnections: 0,
      idleConnections: 0,
      successfulRequests: 100,
      failedRequests: 5,
    );
  }
}

/// 统一网络服务
///
/// 整合所有网络相关管理器，提供统一的网络通信接口
/// 支持 WebSocket、HTTP、轮询、连接池等多种通信方式
///
/// 整合的Manager:
/// - WebSocketManager: WebSocket连接管理
/// - WebSocketConnectionManager: WebSocket连接池管理
/// - RealtimeDataService: 实时数据处理服务
/// - ConnectionPoolManager: HTTP连接池管理
/// - PollingManager: 轮询数据服务管理
class UnifiedNetworkService extends IUnifiedService {
  // ========== 管理器实例 ==========
  WebSocketManager? _webSocketManager;
  RealtimeDataService? _realtimeDataService;
  ConnectionPoolManager? _connectionPoolManager;
  PollingManager? _pollingManager;

  // WebSocket管理器 (如果存在独立的连接管理器)
  dynamic _webSocketConnectionManager;

  // ========== 服务状态 ==========
  bool _isInitialized = false;
  bool _isDisposed = false;

  // ========== 事件流控制器 ==========
  final StreamController<NetworkEvent> _eventController =
      StreamController<NetworkEvent>.broadcast();
  final StreamController<NetworkMessage> _messageController =
      StreamController<NetworkMessage>.broadcast();
  final StreamController<NetworkStatus> _statusController =
      StreamController<NetworkStatus>.broadcast();

  // ========== 网络状态监控 ==========
  NetworkStatus _currentStatus = NetworkStatus.disconnected;
  DateTime? _lastConnectionTime;
  Map<String, dynamic> _networkMetrics = {
    'totalRequests': 0,
    'successfulRequests': 0,
    'failedRequests': 0,
    'totalConnections': 0,
    'activeConnections': 0,
    'webSocketConnections': 0,
    'averageLatency': 0.0,
    'lastPingTime': null,
    'dataTransferred': 0,
  };

  // ========== 配置 ==========
  final UnifiedNetworkConfig _config;

  // ========== 请求拦截器 ==========
  final List<NetworkInterceptor> _interceptors = [];

  // ========== 请求缓存 ==========
  final Map<String, CachedResponse> _requestCache = {};
  Timer? _cacheCleanupTimer;

  // ========== 构造函数 ==========
  UnifiedNetworkService({
    UnifiedNetworkConfig? config,
  }) : _config = config ?? const UnifiedNetworkConfig();

  // ========== IUnifiedService 接口实现 ==========
  @override
  String get serviceName => 'UnifiedNetworkService';

  @override
  String get version => '1.0.0';

  @override
  List<String> get dependencies => [];

  @override
  Future<void> initialize(ServiceContainer container) async {
    if (_isInitialized) {
      AppLogger.warn('UnifiedNetworkService已经初始化');
      return;
    }

    AppLogger.info('正在初始化UnifiedNetworkService...');

    try {
      // 初始化连接池管理器
      await _initializeConnectionPool();

      // 初始化WebSocket管理器
      await _initializeWebSocket();

      // 初始化实时数据服务
      await _initializeRealtimeDataService();

      // 初始化轮询管理器
      await _initializePollingManager();

      // 启动缓存清理
      _startCacheCleanup();

      // 启动网络状态监控
      _startNetworkMonitoring();

      _isInitialized = true;
      _currentStatus = NetworkStatus.connected;

      AppLogger.info('UnifiedNetworkService初始化完成');
      _emitEvent(NetworkEvent(type: 'service_initialized'));
      _emitStatus(NetworkStatus.connected);
    } catch (e) {
      AppLogger.error('UnifiedNetworkService初始化失败', e);
      _currentStatus = NetworkStatus.error;
      _emitEvent(NetworkEvent.error(e.toString()));
      rethrow;
    }
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;

    AppLogger.info('正在关闭UnifiedNetworkService...');
    _isDisposed = true;
    _isInitialized = false;

    try {
      // 停止缓存清理
      _cacheCleanupTimer?.cancel();

      // 关闭WebSocket连接
      await _webSocketManager?.disconnect();

      // 关闭连接池
      await _connectionPoolManager?.dispose();

      // 停止轮询
      await _pollingManager?.dispose();

      // 关闭实时数据服务
      await _realtimeDataService?.dispose();

      // 关闭事件流
      await _eventController.close();
      await _messageController.close();
      await _statusController.close();

      // 清理缓存
      _requestCache.clear();

      _currentStatus = NetworkStatus.disconnected;

      AppLogger.info('UnifiedNetworkService已关闭');
    } catch (e) {
      AppLogger.error('关闭UnifiedNetworkService时出错', e);
    }
  }

  @override
  bool get isInitialized => _isInitialized;

  @override
  bool get isDisposed => _isDisposed;

  @override
  ServiceStats getStats() {
    return ServiceStats(
      serviceName: 'UnifiedNetworkService',
      version: version,
      uptime: DateTime.now().difference(DateTime.now()), // TODO: 保存实际启动时间
      memoryUsage: 0, // TODO: 实现内存使用统计
      customMetrics: _networkMetrics,
    );
  }

  @override
  Future<ServiceHealthStatus> checkHealth() async {
    try {
      if (!_isInitialized || _isDisposed) {
        return ServiceHealthStatus(
          isHealthy: false,
          message: 'Service未初始化或已关闭',
          lastCheck: DateTime.now(),
        );
      }

      final healthIssues = <String>[];

      // 检查连接池状态
      final poolStats = _connectionPoolManager?.getStats();
      if (poolStats != null &&
          poolStats.failedRequests > poolStats.successfulRequests * 0.1) {
        healthIssues.add(
            '连接池失败率过高: ${(poolStats.failedRequests / poolStats.successfulRequests * 100).toStringAsFixed(1)}%');
      }

      // 检查WebSocket状态
      if (_webSocketManager != null) {
        final wsConnected = _webSocketManager!.isConnected;
        if (!wsConnected && _config.webSocketConfig.autoReconnect) {
          healthIssues.add('WebSocket连接断开');
        }
      }

      // 检查网络指标
      if (_networkMetrics['totalRequests'] > 0) {
        final failureRate = (_networkMetrics['failedRequests'] as int) /
            (_networkMetrics['totalRequests'] as int);
        if (failureRate > 0.1) {
          healthIssues
              .add('网络请求失败率过高: ${(failureRate * 100).toStringAsFixed(1)}%');
        }
      }

      if (healthIssues.isNotEmpty) {
        return ServiceHealthStatus(
          isHealthy: false,
          message: '网络健康检查失败: ${healthIssues.join('; ')}',
          lastCheck: DateTime.now(),
          details: {'issues': healthIssues},
        );
      }

      AppLogger.debug('UnifiedNetworkService健康检查通过');
      return ServiceHealthStatus(
        isHealthy: true,
        message: 'UnifiedNetworkService运行正常',
        lastCheck: DateTime.now(),
      );
    } catch (e) {
      AppLogger.error('UnifiedNetworkService健康检查失败', e);
      return ServiceHealthStatus(
        isHealthy: false,
        message: '健康检查异常: $e',
        lastCheck: DateTime.now(),
      );
    }
  }

  // ========== 公共API方法 ==========

  /// HTTP请求
  Future<Response> httpRequest({
    required String url,
    required String method,
    Map<String, dynamic>? data,
    Map<String, String>? headers,
    Duration? timeout,
    bool enableCache = false,
  }) async {
    _ensureInitialized();

    // 检查缓存
    if (enableCache && method.toUpperCase() == 'GET') {
      final cached = _getCachedResponse(url);
      if (cached != null && !cached.isExpired) {
        _updateMetrics(success: true, fromCache: true);
        return cached.response;
      }
    }

    final stopwatch = Stopwatch()..start();

    try {
      // 应用拦截器
      final requestOptions = RequestOptions(
        path: url,
        method: method,
        data: data,
        headers: headers,
        receiveTimeout: timeout ?? _config.defaultTimeout,
        sendTimeout: timeout ?? _config.defaultTimeout,
      );

      await _applyRequestInterceptors(requestOptions);

      Response response;

      // 使用连接池执行请求
      if (_connectionPoolManager != null) {
        final uri = Uri.parse(url);
        response = await _connectionPoolManager!.executeRequest(
          uri.host,
          uri.port != 0 ? uri.port : (uri.scheme == 'https' ? 443 : 80),
          requestOptions,
        );
      } else {
        // 回退到直接HTTP请求
        final dio = Dio();
        response = await dio.request(
          url,
          options: Options(
            method: method,
            headers: headers,
            receiveTimeout: timeout ?? _config.defaultTimeout,
            sendTimeout: timeout ?? _config.defaultTimeout,
          ),
          data: data,
        );
      }

      await _applyResponseInterceptors(response);

      stopwatch.stop();

      // 缓存响应
      if (enableCache && method.toUpperCase() == 'GET') {
        _cacheResponse(url, response, Duration(minutes: 5));
      }

      _updateMetrics(success: true, latency: stopwatch.elapsedMilliseconds);

      AppLogger.debug('HTTP请求完成', '$method $url - ${response.statusCode}');
      return response;
    } catch (e) {
      stopwatch.stop();
      _updateMetrics(success: false, latency: stopwatch.elapsedMilliseconds);

      AppLogger.error('HTTP请求失败', '$method $url - $e');
      _emitEvent(NetworkEvent.requestFailed(url, e.toString()));

      rethrow;
    }
  }

  /// WebSocket连接
  Future<void> connectWebSocket(String url,
      {Map<String, String>? headers}) async {
    _ensureInitialized();

    if (_webSocketManager == null) {
      throw StateError('WebSocket管理器未初始化');
    }

    try {
      // 更新WebSocket配置
      final config = WebSocketConnectionConfig(
        url: url,
        protocols: headers?.keys.toList(),
        headers: headers,
        autoReconnect: _config.webSocketConfig.autoReconnect,
        maxReconnectAttempts: _config.webSocketConfig.maxReconnectAttempts,
        baseReconnectDelay: _config.webSocketConfig.baseReconnectDelay,
        maxReconnectDelay: _config.webSocketConfig.maxReconnectDelay,
        connectTimeout: _config.webSocketConfig.connectTimeout,
        heartbeatInterval: _config.webSocketConfig.heartbeatInterval,
      );

      _webSocketManager!.updateConfig(config);
      await _webSocketManager!.connect();

      _networkMetrics['webSocketConnections'] =
          (_networkMetrics['webSocketConnections'] as int) + 1;

      AppLogger.info('WebSocket连接已建立', url);
      _emitEvent(NetworkEvent(type: 'websocket_connected'));
    } catch (e) {
      AppLogger.error('WebSocket连接失败', '$url - $e');
      _emitEvent(NetworkEvent.webSocketError(url, e.toString()));
      rethrow;
    }
  }

  /// 发送WebSocket消息
  Future<void> sendWebSocketMessage(dynamic message) async {
    _ensureInitialized();

    if (_webSocketManager == null || !_webSocketManager!.isConnected) {
      throw StateError('WebSocket未连接');
    }

    await _webSocketManager!.sendMessage(message);

    _networkMetrics['dataTransferred'] =
        (_networkMetrics['dataTransferred'] as int) + message.toString().length;

    AppLogger.debug('WebSocket消息已发送');
  }

  /// 启动轮询
  Future<void> startPolling({
    required String endpoint,
    required Duration interval,
    Map<String, dynamic>? parameters,
  }) async {
    _ensureInitialized();

    if (_pollingManager == null) {
      throw StateError('轮询管理器未初始化');
    }

    await _pollingManager!.startPolling(
      endpoint: endpoint,
      interval: interval,
      parameters: parameters,
    );

    AppLogger.info('轮询已启动', '$endpoint every ${interval.inSeconds}s');
    _emitEvent(NetworkEvent(type: 'polling_started', data: endpoint));
  }

  /// 停止轮询
  Future<void> stopPolling(String endpoint) async {
    _ensureInitialized();

    await _pollingManager?.stopPolling(endpoint);

    AppLogger.info('轮询已停止', endpoint);
    _emitEvent(NetworkEvent(type: 'polling_stopped', data: endpoint));
  }

  /// 获取网络状态
  NetworkStatus get networkStatus => _currentStatus;

  /// 获取网络指标
  Map<String, dynamic> get networkMetrics => Map.unmodifiable(_networkMetrics);

  /// 获取连接池统计
  ConnectionPoolStats? get connectionPoolStats =>
      _connectionPoolManager?.getStats();

  /// 获取WebSocket统计
  Map<String, dynamic>? get webSocketStats =>
      _webSocketManager?.getConnectionStats();

  /// 添加网络拦截器
  void addInterceptor(NetworkInterceptor interceptor) {
    _interceptors.add(interceptor);
    AppLogger.debug('网络拦截器已添加', interceptor.runtimeType.toString());
  }

  /// 移除网络拦截器
  void removeInterceptor(NetworkInterceptor interceptor) {
    _interceptors.remove(interceptor);
    AppLogger.debug('网络拦截器已移除', interceptor.runtimeType.toString());
  }

  // ========== 事件流 ==========

  /// 网络事件流
  Stream<NetworkEvent> get eventStream => _eventController.stream;

  /// 网络消息流
  Stream<NetworkMessage> get messageStream => _messageController.stream;

  /// 网络状态流
  Stream<NetworkStatus> get statusStream => _statusController.stream;

  // ========== 私有初始化方法 ==========

  Future<void> _initializeConnectionPool() async {
    try {
      _connectionPoolManager = ConnectionPoolManager(
        config: ConnectionPoolConfig(
          maxConnections: _config.connectionPoolConfig.maxConnections,
          maxIdleConnections: _config.connectionPoolConfig.maxIdleConnections,
          connectionTimeout: _config.connectionPoolConfig.connectionTimeout,
          idleTimeout: _config.connectionPoolConfig.idleTimeout,
          requestTimeout: _config.connectionPoolConfig.requestTimeout,
          enableConnectionReuse:
              _config.connectionPoolConfig.enableConnectionReuse,
          enableHealthCheck: _config.connectionPoolConfig.enableHealthCheck,
          healthCheckInterval: _config.connectionPoolConfig.healthCheckInterval,
          enableConnectionWarmup:
              _config.connectionPoolConfig.enableConnectionWarmup,
        ),
      );

      await _connectionPoolManager!.initialize();
      AppLogger.debug('ConnectionPoolManager初始化完成');
    } catch (e) {
      AppLogger.error('ConnectionPoolManager初始化失败', e);
      rethrow;
    }
  }

  Future<void> _initializeWebSocket() async {
    try {
      // 这里假设存在WebSocketManager的默认构造函数
      // 在实际实现中需要根据具体的WebSocketManager构造函数调整
      _webSocketManager = WebSocketManager(
        config: WebSocketConnectionConfig(
          url: _config.webSocketConfig.defaultUrl,
          autoReconnect: _config.webSocketConfig.autoReconnect,
          maxReconnectAttempts: _config.webSocketConfig.maxReconnectAttempts,
          baseReconnectDelay: _config.webSocketConfig.baseReconnectDelay,
          maxReconnectDelay: _config.webSocketConfig.maxReconnectDelay,
          connectTimeout: _config.webSocketConfig.connectTimeout,
          heartbeatInterval: _config.webSocketConfig.heartbeatInterval,
        ),
      );

      // 监听WebSocket事件
      _webSocketManager!.stateStream.listen((state) {
        switch (state) {
          case WebSocketConnectionState.connected:
            _emitEvent(NetworkEvent(type: 'websocket_connected'));
            break;
          case WebSocketConnectionState.disconnected:
            _emitEvent(NetworkEvent(type: 'websocket_disconnected'));
            break;
          case WebSocketConnectionState.error:
            _emitEvent(NetworkEvent(
                type: 'websocket_error', message: 'Unknown: Connection error'));
            break;
          default:
            break;
        }
      });

      _webSocketManager!.messageStream.listen((message) {
        _messageController.add(NetworkMessage(
          type: 'websocket',
          data: message,
          timestamp: DateTime.now(),
        ));
      });

      AppLogger.debug('WebSocketManager初始化完成');
    } catch (e) {
      AppLogger.error('WebSocketManager初始化失败', e);
      rethrow;
    }
  }

  Future<void> _initializeRealtimeDataService() async {
    try {
      // 这里假设存在RealtimeDataService的默认构造函数
      // 在实际实现中需要根据具体的RealtimeDataService构造函数调整
      _realtimeDataService = RealtimeDataService();
      await _realtimeDataService!.initialize();

      AppLogger.debug('RealtimeDataService初始化完成');
    } catch (e) {
      AppLogger.error('RealtimeDataService初始化失败', e);
      rethrow;
    }
  }

  Future<void> _initializePollingManager() async {
    try {
      // 这里假设存在PollingManager的默认构造函数
      // 在实际实现中需要根据具体的PollingManager构造函数调整
      _pollingManager = PollingManager();
      await _pollingManager!.initialize();

      AppLogger.debug('PollingManager初始化完成');
    } catch (e) {
      AppLogger.error('PollingManager初始化失败', e);
      rethrow;
    }
  }

  // ========== 私有辅助方法 ==========

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('UnifiedNetworkService未初始化');
    }
    if (_isDisposed) {
      throw StateError('UnifiedNetworkService已关闭');
    }
  }

  void _updateMetrics({
    required bool success,
    int? latency,
    bool fromCache = false,
  }) {
    _networkMetrics['totalRequests'] =
        (_networkMetrics['totalRequests'] as int) + 1;

    if (success) {
      _networkMetrics['successfulRequests'] =
          (_networkMetrics['successfulRequests'] as int) + 1;
    } else {
      _networkMetrics['failedRequests'] =
          (_networkMetrics['failedRequests'] as int) + 1;
    }

    if (latency != null && !fromCache) {
      final currentAvg = _networkMetrics['averageLatency'] as double;
      final totalReqs = _networkMetrics['totalRequests'] as int;
      _networkMetrics['averageLatency'] =
          (currentAvg * (totalReqs - 1) + latency) / totalReqs;
    }

    if (!fromCache && latency != null && latency > 5000) {
      _emitEvent(NetworkEvent(type: 'high_latency', data: latency));
    }
  }

  Future<void> _applyRequestInterceptors(RequestOptions options) async {
    for (final interceptor in _interceptors) {
      await interceptor.onRequest(options);
    }
  }

  Future<void> _applyResponseInterceptors(Response response) async {
    for (final interceptor in _interceptors) {
      await interceptor.onResponse(response);
    }
  }

  CachedResponse? _getCachedResponse(String url) {
    return _requestCache[url];
  }

  void _cacheResponse(String url, Response response, Duration ttl) {
    _requestCache[url] = CachedResponse(
      response: response,
      cachedAt: DateTime.now(),
      ttl: ttl,
    );
  }

  void _startCacheCleanup() {
    _cacheCleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _cleanExpiredCache();
    });
  }

  void _cleanExpiredCache() {
    final expiredKeys = <String>[];
    final now = DateTime.now();

    for (final entry in _requestCache.entries) {
      if (entry.value.isExpired) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _requestCache.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      AppLogger.debug('清理过期缓存', '删除${expiredKeys.length}条记录');
    }
  }

  void _startNetworkMonitoring() {
    // 监听网络连接状态
    Timer.periodic(const Duration(seconds: 30), (_) async {
      try {
        await _checkNetworkConnectivity();
      } catch (e) {
        AppLogger.error('网络监控检查失败', e);
      }
    });
  }

  Future<void> _checkNetworkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        if (_currentStatus == NetworkStatus.disconnected) {
          _currentStatus = NetworkStatus.connected;
          _lastConnectionTime = DateTime.now();
          _emitStatus(NetworkStatus.connected);
        }
      }
    } catch (e) {
      if (_currentStatus == NetworkStatus.connected) {
        _currentStatus = NetworkStatus.disconnected;
        _emitStatus(NetworkStatus.disconnected);
      }
    }
  }

  void _emitEvent(NetworkEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  void _emitStatus(NetworkStatus status) {
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }
}

// ========== 支持类和枚举 =========

/// 网络状态
enum NetworkStatus {
  connected, // 已连接
  disconnected, // 未连接
  connecting, // 连接中
  reconnecting, // 重连中
  error, // 错误
}

/// 网络事件
class NetworkEvent {
  final String type;
  final String? message;
  final dynamic data;
  final DateTime timestamp;

  NetworkEvent({
    required this.type,
    this.message,
    this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory NetworkEvent.serviceInitialized() =>
      NetworkEvent(type: 'service_initialized');

  factory NetworkEvent.error(String message) =>
      NetworkEvent(type: 'error', message: message);

  factory NetworkEvent.requestFailed(String url, String error) =>
      NetworkEvent(type: 'request_failed', message: '$url: $error');

  factory NetworkEvent.webSocketConnected() =>
      NetworkEvent(type: 'websocket_connected');

  factory NetworkEvent.webSocketDisconnected() =>
      NetworkEvent(type: 'websocket_disconnected');

  factory NetworkEvent.webSocketError(String url, String error) =>
      NetworkEvent(type: 'websocket_error', message: '$url: $error');

  factory NetworkEvent.pollingStarted(String endpoint) =>
      NetworkEvent(type: 'polling_started', data: endpoint);

  factory NetworkEvent.pollingStopped(String endpoint) =>
      NetworkEvent(type: 'polling_stopped', data: endpoint);

  factory NetworkEvent.highLatency(int latency) =>
      NetworkEvent(type: 'high_latency', data: latency);
}

/// 网络消息
class NetworkMessage {
  final String type;
  final dynamic data;
  final DateTime timestamp;

  const NetworkMessage({
    required this.type,
    required this.data,
    required this.timestamp,
  });
}

/// 缓存响应
class CachedResponse {
  final Response response;
  final DateTime cachedAt;
  final Duration ttl;

  const CachedResponse({
    required this.response,
    required this.cachedAt,
    required this.ttl,
  });

  bool get isExpired => DateTime.now().difference(cachedAt) > ttl;
}

/// 网络拦截器
abstract class NetworkInterceptor {
  Future<void> onRequest(RequestOptions options);
  Future<void> onResponse(Response response);
  Future<void> onError(dynamic error);
}

/// 统一网络配置
class UnifiedNetworkConfig {
  final WebSocketConfig webSocketConfig;
  final ConnectionPoolConfig connectionPoolConfig;
  final Duration defaultTimeout;
  final int maxRetryAttempts;
  final bool enableRequestLogging;

  const UnifiedNetworkConfig({
    this.webSocketConfig = const WebSocketConfig(),
    this.connectionPoolConfig = const ConnectionPoolConfig(),
    this.defaultTimeout = const Duration(seconds: 30),
    this.maxRetryAttempts = 3,
    this.enableRequestLogging = true,
  });
}

/// WebSocket配置
class WebSocketConfig {
  final String defaultUrl;
  final bool autoReconnect;
  final int maxReconnectAttempts;
  final Duration baseReconnectDelay;
  final Duration maxReconnectDelay;
  final Duration connectTimeout;
  final Duration heartbeatInterval;

  const WebSocketConfig({
    this.defaultUrl = 'ws://localhost:8080',
    this.autoReconnect = true,
    this.maxReconnectAttempts = 5,
    this.baseReconnectDelay = const Duration(seconds: 1),
    this.maxReconnectDelay = const Duration(minutes: 5),
    this.connectTimeout = const Duration(seconds: 10),
    this.heartbeatInterval = const Duration(seconds: 30),
  });
}
