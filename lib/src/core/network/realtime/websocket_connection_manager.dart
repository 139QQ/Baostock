import 'dart:async';
import 'dart:collection';
import '../hybrid/data_type.dart';
import '../utils/logger.dart';
import 'realtime_data_router.dart';
import 'realtime_data_service.dart';
import 'websocket_adapter.dart';

// ignore_for_file: directives_ordering, sort_constructors_first, public_member_api_docs
/// WebSocket连接管理器
///
/// 管理WebSocket连接的生命周期，提供连接状态监控和自动重连功能
class WebSocketConnectionManager {
  /// 单例实例
  static final WebSocketConnectionManager _instance =
      WebSocketConnectionManager._internal();

  factory WebSocketConnectionManager() => _instance;

  WebSocketConnectionManager._internal() : _config = _defaultConfig {
    _initialize();
  }

  /// 连接配置
  WebSocketConnectionConfig _config;

  /// 默认配置
  static WebSocketConnectionConfig get _defaultConfig {
    return WebSocketConnectionConfig(
      url: 'ws://localhost:8080/ws',
      connectTimeout: const Duration(seconds: 10),
      heartbeatInterval: const Duration(seconds: 30),
    );
  }

  /// WebSocket适配器
  WebSocketAdapter? _adapter;

  /// 数据路由器
  late final RealtimeDataRouter _router;

  /// 连接状态
  RealtimeServiceState _state = RealtimeServiceState.uninitialized;

  /// 状态流控制器
  final StreamController<RealtimeServiceState> _stateController =
      StreamController<RealtimeServiceState>.broadcast();

  /// 连接指标
  final ConnectionMetrics _metrics = ConnectionMetrics();

  /// 状态变化监听器
  final List<StateChangeListener> _stateListeners = [];

  /// 连接历史
  final Queue<ConnectionRecord> _connectionHistory = Queue<ConnectionRecord>();
  static const int _maxHistorySize = 100;

  /// 是否已初始化
  bool _isInitialized = false;

  /// 是否已启动
  bool _isStarted = false;

  /// 获取连接状态
  RealtimeServiceState get state => _state;

  /// 获取状态流
  Stream<RealtimeServiceState> get stateStream => _stateController.stream;

  /// 获取连接指标
  ConnectionMetrics get metrics => _metrics;

  /// 获取连接历史
  List<ConnectionRecord> get connectionHistory => _connectionHistory.toList();

  /// 初始化管理器
  void _initialize() {
    if (_isInitialized) return;

    try {
      // 默认配置
      _config = const WebSocketConnectionConfig();

      // 初始化路由器
      _router = RealtimeDataRouter();

      // 注册默认处理器
      _router.registerHandler(DataType.fundRanking, LoggingRealtimeHandler());
      _router.registerHandler(DataType.etfSpotData, CacheRealtimeHandler());
      _router.registerHandler(DataType.lofSpotData, CacheRealtimeHandler());
      _router.registerHandler(DataType.marketIndex, LoggingRealtimeHandler());

      _isInitialized = true;
      AppLogger.info('WebSocketConnectionManager: 初始化完成');
    } catch (e) {
      AppLogger.error('WebSocketConnectionManager: 初始化失败', e);
      rethrow;
    }
  }

  /// 配置连接参数
  void configure(WebSocketConnectionConfig config) {
    _config = config;
    AppLogger.info('WebSocketConnectionManager: 配置已更新');
  }

  /// 添加状态变化监听器
  void addStateChangeListener(StateChangeListener listener) {
    _stateListeners.add(listener);
  }

  /// 移除状态变化监听器
  void removeStateChangeListener(StateChangeListener listener) {
    _stateListeners.remove(listener);
  }

  /// 启动连接管理器
  Future<void> start() async {
    if (_isStarted) {
      AppLogger.warn('WebSocketConnectionManager: 已启动');
      return;
    }

    try {
      AppLogger.info('WebSocketConnectionManager: 启动中...');

      // 创建适配器
      _adapter = WebSocketAdapter();

      // 初始化适配器
      await _adapter!.initialize(RealtimeServiceConfig(
        url: _config.url,
        connectTimeout: _config.connectTimeout,
        heartbeatInterval: _config.heartbeatInterval,
        reconnectConfig: _config.reconnectConfig,
        authToken: _config.authToken,
        enableDebugMode: _config.enableDebugMode,
        headers: _config.headers,
      ));

      // 监听适配器状态
      _adapter!.stateStream.listen(_handleStateChange);

      // 监听数据
      _adapter!.dataStream.listen(_handleData);

      // 启动适配器
      await _adapter!.start();

      _isStarted = true;
      AppLogger.info('WebSocketConnectionManager: 启动完成');
    } catch (e) {
      _updateState(RealtimeServiceState.error);
      AppLogger.error('WebSocketConnectionManager: 启动失败', e);
      rethrow;
    }
  }

  /// 停止连接管理器
  Future<void> stop() async {
    if (!_isStarted) return;

    try {
      AppLogger.info('WebSocketConnectionManager: 停止中...');

      // 停止适配器
      await _adapter?.stop();

      _isStarted = false;
      AppLogger.info('WebSocketConnectionManager: 停止完成');
    } catch (e) {
      AppLogger.error('WebSocketConnectionManager: 停止失败', e);
    }
  }

  /// 更新状态
  void _updateState(RealtimeServiceState newState) {
    if (_state != newState) {
      final oldState = _state;
      _state = newState;

      // 通知状态监听器
      for (final listener in _stateListeners) {
        listener.onStateChanged(oldState, newState);
      }

      // 添加到状态流
      if (!_stateController.isClosed) {
        _stateController.add(newState);
      }

      AppLogger.info(
          'WebSocketConnectionManager: 状态变化', '$oldState -> $newState');
    }
  }

  /// 重新连接
  Future<void> reconnect() async {
    try {
      AppLogger.info('WebSocketConnectionManager: 重新连接...');
      await _adapter?.stop();
      await Future.delayed(const Duration(seconds: 1));
      await _adapter?.start();
    } catch (e) {
      AppLogger.error('WebSocketConnectionManager: 重新连接失败', '$e');
    }
  }

  /// 订阅数据类型
  Future<SubscriptionResult> subscribeToDataType(DataType dataType,
      {Map<String, dynamic>? parameters}) async {
    if (_adapter == null) {
      return SubscriptionResult.failure(error: '适配器未初始化');
    }

    try {
      final result =
          await _adapter!.subscribe(dataType, parameters: parameters);

      // 如果订阅成功，将服务注册到路由器
      if (result.success && result.subscriptionId != null) {
        _router.registerService(dataType, _adapter!);
        _metrics.recordSubscription(dataType, true);
      } else {
        _metrics.recordSubscription(dataType, false);
      }

      return result;
    } catch (e) {
      _metrics.recordSubscription(dataType, false);
      AppLogger.error('WebSocketConnectionManager: 订阅失败', e);
      return SubscriptionResult.failure(error: e.toString());
    }
  }

  /// 取消订阅数据类型
  Future<void> unsubscribeFromDataType(DataType dataType) async {
    if (_adapter == null) return;

    try {
      await _adapter!.unsubscribe(dataType);
      _router.unregisterService(dataType, _adapter!);
      _metrics.recordUnsubscription(dataType);
    } catch (e) {
      AppLogger.error('WebSocketConnectionManager: 取消订阅失败', e);
    }
  }

  /// 获取支持的数据类型
  Set<DataType> getSupportedDataTypes() {
    return _adapter?.supportedDataTypes ?? <DataType>{};
  }

  /// 获取数据流
  Stream<RealtimeDataEvent>? getDataStream(DataType dataType) {
    return _router.getDataTypeStream(dataType);
  }

  /// 获取全局数据流
  Stream<RealtimeDataEvent>? getGlobalDataStream() {
    return _router.globalDataStream;
  }

  /// 处理状态变化
  void _handleStateChange(RealtimeServiceState newState) {
    final oldState = _state;
    _state = newState;

    // 记录连接历史
    _recordConnection(oldState, newState);

    // 更新指标
    _metrics.recordStateChange(oldState, newState);

    // 通知监听器
    for (final listener in _stateListeners) {
      try {
        listener.onStateChanged(oldState, newState);
      } catch (e) {
        AppLogger.error('WebSocketConnectionManager: 状态监听器异常', e);
      }
    }

    // 发送状态流
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }

    AppLogger.debug('WebSocketConnectionManager: 状态变化',
        '${oldState.description} -> ${newState.description}');
  }

  /// 处理数据
  void _handleData(RealtimeDataEvent event) {
    _metrics.recordDataEvent(event);
    _router.routeData(event);
  }

  /// 记录连接历史
  void _recordConnection(
      RealtimeServiceState oldState, RealtimeServiceState newState) {
    final record = ConnectionRecord(
      timestamp: DateTime.now(),
      oldState: oldState,
      newState: newState,
      reason: 'State change',
    );

    _connectionHistory.add(record);

    // 保持历史记录大小
    while (_connectionHistory.length > _maxHistorySize) {
      _connectionHistory.removeFirst();
    }
  }

  /// 获取健康状态
  Future<Map<String, dynamic>> getHealthStatus() async {
    final adapterStatus = await _adapter?.getHealthStatus();

    return {
      'manager': {
        'initialized': _isInitialized,
        'started': _isStarted,
        'state': _state.description,
        'config': _config.toJson(),
      },
      'adapter': adapterStatus,
      'router': _router.getHealthStatus(),
      'metrics': _metrics.toJson(),
      'connectionHistory': _connectionHistory.map((r) => r.toJson()).toList(),
    };
  }

  /// 释放资源
  Future<void> dispose() async {
    await stop();

    _stateListeners.clear();
    await _stateController.close();
    await _router.dispose();

    _adapter = null;
    _isInitialized = false;

    AppLogger.info('WebSocketConnectionManager: 资源释放完成');
  }
}

/// WebSocket连接配置
class WebSocketConnectionConfig {
  /// 连接URL
  final String url;

  /// 连接超时
  final Duration connectTimeout;

  /// 心跳间隔
  final Duration heartbeatInterval;

  /// 重连配置
  final ReconnectConfig reconnectConfig;

  /// 认证令牌
  final String? authToken;

  /// 是否启用调试模式
  final bool enableDebugMode;

  /// 自定义头部
  final Map<String, String> headers;

  /// 支持的数据类型
  final Set<DataType> supportedDataTypes;

  /// 连接池大小
  final int connectionPoolSize;

  const WebSocketConnectionConfig({
    this.url = 'ws://154.44.25.92:8080/ws',
    this.connectTimeout = const Duration(seconds: 10),
    this.heartbeatInterval = const Duration(seconds: 30),
    this.reconnectConfig = const ReconnectConfig(),
    this.authToken,
    this.enableDebugMode = false,
    this.headers = const {},
    this.supportedDataTypes = const {
      DataType.fundRanking,
      DataType.etfSpotData,
      DataType.lofSpotData,
      DataType.marketIndex,
    },
    this.connectionPoolSize = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'connectTimeout': connectTimeout.inSeconds,
      'heartbeatInterval': heartbeatInterval.inSeconds,
      'authToken': authToken != null ? '***' : null,
      'enableDebugMode': enableDebugMode,
      'headers': headers,
      'supportedDataTypes': supportedDataTypes.map((t) => t.name).toList(),
      'connectionPoolSize': connectionPoolSize,
    };
  }
}

/// 连接指标
class ConnectionMetrics {
  int _totalConnections = 0;
  int _successfulConnections = 0;
  int _totalDisconnections = 0;
  int _totalDataEvents = 0;
  DateTime? _lastConnectionTime;
  DateTime? _lastDisconnectionTime;
  Duration _totalConnectedTime = Duration.zero;
  DateTime? _connectionStartTime;

  final Map<DataType, _DataTypeMetrics> _dataTypeMetrics = {};

  void recordStateChange(
      RealtimeServiceState oldState, RealtimeServiceState newState) {
    if (oldState != RealtimeServiceState.connected &&
        newState == RealtimeServiceState.connected) {
      _totalConnections++;
      _successfulConnections++;
      _lastConnectionTime = DateTime.now();
      _connectionStartTime = DateTime.now();
    } else if (oldState == RealtimeServiceState.connected &&
        newState != RealtimeServiceState.connected) {
      _totalDisconnections++;
      _lastDisconnectionTime = DateTime.now();
      if (_connectionStartTime != null) {
        _totalConnectedTime += DateTime.now().difference(_connectionStartTime!);
        _connectionStartTime = null;
      }
    }
  }

  void recordDataEvent(RealtimeDataEvent event) {
    _totalDataEvents++;
    _dataTypeMetrics.putIfAbsent(
        event.dataType, () => _DataTypeMetrics(event.dataType));
    _dataTypeMetrics[event.dataType]!.recordEvent();
  }

  void recordSubscription(DataType dataType, bool success) {
    _dataTypeMetrics.putIfAbsent(dataType, () => _DataTypeMetrics(dataType));
    if (success) {
      _dataTypeMetrics[dataType]!.recordSubscription();
    } else {
      _dataTypeMetrics[dataType]!.recordSubscriptionFailure();
    }
  }

  void recordUnsubscription(DataType dataType) {
    _dataTypeMetrics.putIfAbsent(dataType, () => _DataTypeMetrics(dataType));
    _dataTypeMetrics[dataType]!.recordUnsubscription();
  }

  double get connectionSuccessRate =>
      _totalConnections > 0 ? _successfulConnections / _totalConnections : 0.0;
  Duration get averageConnectionDuration => _successfulConnections > 0
      ? Duration(
          milliseconds:
              _totalConnectedTime.inMilliseconds ~/ _successfulConnections)
      : Duration.zero;
  bool get isConnected => _connectionStartTime != null;

  Map<String, dynamic> toJson() {
    return {
      'totalConnections': _totalConnections,
      'successfulConnections': _successfulConnections,
      'connectionSuccessRate': connectionSuccessRate,
      'totalDisconnections': _totalDisconnections,
      'totalDataEvents': _totalDataEvents,
      'lastConnectionTime': _lastConnectionTime?.toIso8601String(),
      'lastDisconnectionTime': _lastDisconnectionTime?.toIso8601String(),
      'averageConnectionDuration': averageConnectionDuration.inMilliseconds,
      'totalConnectedTime': _totalConnectedTime.inMilliseconds,
      'isConnected': isConnected,
      'dataTypeMetrics': _dataTypeMetrics
          .map((key, value) => MapEntry(key.name, value.toJson())),
    };
  }
}

/// 数据类型指标
class _DataTypeMetrics {
  final DataType dataType;
  int _events = 0;
  int _subscriptions = 0;
  int _subscriptionFailures = 0;
  int _unsubscriptions = 0;

  _DataTypeMetrics(this.dataType);

  void recordEvent() => _events++;
  void recordSubscription() => _subscriptions++;
  void recordSubscriptionFailure() => _subscriptionFailures++;
  void recordUnsubscription() => _unsubscriptions++;

  double get subscriptionSuccessRate {
    final total = _subscriptions + _subscriptionFailures;
    return total > 0 ? _subscriptions / total : 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'dataType': dataType.name,
      'events': _events,
      'subscriptions': _subscriptions,
      'subscriptionFailures': _subscriptionFailures,
      'unsubscriptions': _unsubscriptions,
      'subscriptionSuccessRate': subscriptionSuccessRate,
    };
  }
}

/// 连接记录
class ConnectionRecord {
  final DateTime timestamp;
  final RealtimeServiceState oldState;
  final RealtimeServiceState newState;
  final String reason;

  ConnectionRecord({
    required this.timestamp,
    required this.oldState,
    required this.newState,
    required this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'oldState': oldState.name,
      'newState': newState.name,
      'reason': reason,
    };
  }
}

/// 状态变化监听器接口
abstract class StateChangeListener {
  /// 状态变化回调
  void onStateChanged(
      RealtimeServiceState oldState, RealtimeServiceState newState);
}

/// 示例状态监听器：日志监听器
class LoggingStateChangeListener extends StateChangeListener {
  @override
  void onStateChanged(
      RealtimeServiceState oldState, RealtimeServiceState newState) {
    AppLogger.info('WebSocketConnectionManager: 状态变化',
        '${oldState.description} -> ${newState.description}');
  }
}
