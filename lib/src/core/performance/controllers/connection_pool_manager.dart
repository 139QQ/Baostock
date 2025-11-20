import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../utils/logger.dart';

/// 连接状态
enum ConnectionState {
  idle, // 空闲
  active, // 活跃
  busy, // 忙碌
  closing, // 关闭中
  closed, // 已关闭
}

/// 连接优先级
enum ConnectionPriority {
  low, // 低优先级
  normal, // 普通优先级
  high, // 高优先级
  critical, // 关键优先级
}

/// 连接信息
class ConnectionInfo {
  final String id;
  final String host;
  final int port;
  final String protocol;
  final DateTime createdAt;
  final DateTime lastUsedAt;
  final ConnectionState state;
  final int requestCount;
  final Duration totalTime;
  final int errorCount;
  final double averageResponseTime;

  const ConnectionInfo({
    required this.id,
    required this.host,
    required this.port,
    required this.protocol,
    required this.createdAt,
    required this.lastUsedAt,
    required this.state,
    required this.requestCount,
    required this.totalTime,
    required this.errorCount,
    required this.averageResponseTime,
  });
}

/// 连接请求
class ConnectionRequest {
  final String id;
  final String host;
  final int port;
  final ConnectionPriority priority;
  final RequestOptions options;
  final Completer<Response> completer;
  final DateTime createdAt;
  final Duration timeout;

  ConnectionRequest({
    required this.id,
    required this.host,
    required this.port,
    required this.priority,
    required this.options,
    required this.completer,
    required this.createdAt,
    required this.timeout,
  });
}

/// 连接池配置
class ConnectionPoolConfig {
  /// 最大连接数
  final int maxConnections;

  /// 最大空闲连接数
  final int maxIdleConnections;

  /// 连接超时时间
  final Duration connectionTimeout;

  /// 空闲超时时间
  final Duration idleTimeout;

  /// 请求超时时间
  final Duration requestTimeout;

  /// 启用连接复用
  final bool enableConnectionReuse;

  /// 启用健康检查
  final bool enableHealthCheck;

  /// 健康检查间隔
  final Duration healthCheckInterval;

  /// 启用连接预热
  final bool enableConnectionWarmup;

  const ConnectionPoolConfig({
    this.maxConnections = 10,
    this.maxIdleConnections = 5,
    this.connectionTimeout = const Duration(seconds: 10),
    this.idleTimeout = const Duration(minutes: 5),
    this.requestTimeout = const Duration(seconds: 30),
    this.enableConnectionReuse = true,
    this.enableHealthCheck = true,
    this.healthCheckInterval = const Duration(minutes: 1),
    this.enableConnectionWarmup = true,
  });
}

/// 连接池统计信息
class ConnectionPoolStats {
  final int totalConnections;
  final int activeConnections;
  final int idleConnections;
  final int pendingRequests;
  final int successfulRequests;
  final int failedRequests;
  final double averageResponseTime;
  final int totalRequestsServed;
  final Map<String, int> hostConnectionCounts;

  const ConnectionPoolStats({
    required this.totalConnections,
    required this.activeConnections,
    required this.idleConnections,
    required this.pendingRequests,
    required this.successfulRequests,
    required this.failedRequests,
    required this.averageResponseTime,
    required this.totalRequestsServed,
    required this.hostConnectionCounts,
  });
}

/// 连接池管理器
///
/// 实现高效的连接池和请求队列管理
class ConnectionPoolManager {
  final ConnectionPoolConfig _config;
  final Map<String, Queue<ConnectionRequest>> _requestQueues = {};
  final Map<String, List<ConnectionInfo>> _connectionPools = {};

  final Map<String, Completer<Response>> _pendingRequests = {};
  Timer? _healthCheckTimer;
  Timer? _idleCheckTimer;

  int _requestCounter = 0;
  int _successfulRequests = 0;
  int _failedRequests = 0;
  double _totalResponseTime = 0.0;
  int _totalRequestsServed = 0;

  ConnectionPoolManager({ConnectionPoolConfig? config})
      : _config = config ?? ConnectionPoolConfig();

  /// 初始化连接池
  Future<void> initialize() async {
    AppLogger.business('初始化ConnectionPoolManager');

    // 启动健康检查
    if (_config.enableHealthCheck) {
      _startHealthCheck();
    }

    // 启动空闲连接检查
    _startIdleConnectionCheck();

    // 连接预热
    if (_config.enableConnectionWarmup) {
      await _warmupConnections();
    }

    AppLogger.business('连接池管理器初始化完成');
  }

  /// 执行请求
  Future<Response> executeRequest(
    String host,
    int port,
    RequestOptions options, {
    ConnectionPriority priority = ConnectionPriority.normal,
  }) async {
    final requestId = _generateRequestId();
    final completer = Completer<Response>();

    final request = ConnectionRequest(
      id: requestId,
      host: host,
      port: port,
      priority: priority,
      options: options,
      completer: completer,
      createdAt: DateTime.now(),
      timeout: options.receiveTimeout ?? _config.requestTimeout,
    );

    // 添加到请求队列
    _addToRequestQueue(host, request);

    // 尝试立即处理
    _processRequestQueue(host);

    return completer.future.timeout(request.timeout);
  }

  /// 获取连接池统计信息
  ConnectionPoolStats getStats() {
    int totalConnections = 0;
    int activeConnections = 0;
    int idleConnections = 0;
    final hostCounts = <String, int>{};

    for (final pool in _connectionPools.values) {
      totalConnections += pool.length;
      hostCounts[pool.first.host] = pool.length;

      for (final connection in pool) {
        switch (connection.state) {
          case ConnectionState.active:
            activeConnections++;
            break;
          case ConnectionState.idle:
            idleConnections++;
            break;
          default:
            break;
        }
      }
    }

    final pendingRequests =
        _requestQueues.values.fold<int>(0, (sum, queue) => sum + queue.length);

    return ConnectionPoolStats(
      totalConnections: totalConnections,
      activeConnections: activeConnections,
      idleConnections: idleConnections,
      pendingRequests: pendingRequests,
      successfulRequests: _successfulRequests,
      failedRequests: _failedRequests,
      averageResponseTime: _totalRequestsServed > 0
          ? _totalResponseTime / _totalRequestsServed
          : 0.0,
      totalRequestsServed: _totalRequestsServed,
      hostConnectionCounts: hostCounts,
    );
  }

  /// 关闭连接池
  Future<void> dispose() async {
    AppLogger.business('关闭ConnectionPoolManager');

    _healthCheckTimer?.cancel();
    _idleCheckTimer?.cancel();

    // 关闭所有连接
    for (final pool in _connectionPools.values) {
      for (final connection in pool) {
        await _closeConnection(connection);
      }
    }

    _connectionPools.clear();
    _requestQueues.clear();
    _pendingRequests.clear();

    AppLogger.business('连接池管理器已关闭');
  }

  /// 添加到请求队列
  void _addToRequestQueue(String host, ConnectionRequest request) {
    final queue =
        _requestQueues.putIfAbsent(host, () => Queue<ConnectionRequest>());

    // 按优先级插入
    if (queue.isEmpty || request.priority.index >= queue.first.priority.index) {
      queue.addFirst(request);
    } else {
      queue.addLast(request);
    }
  }

  /// 处理请求队列
  Future<void> _processRequestQueue(String host) async {
    final queue = _requestQueues[host];
    if (queue == null || queue.isEmpty) return;

    // 获取或创建连接池
    final pool = _connectionPools.putIfAbsent(host, () => <ConnectionInfo>[]);

    // 查找可用连接
    final availableConnection = _findAvailableConnection(pool);
    if (availableConnection != null) {
      final request = queue.removeFirst();
      await _executeRequest(availableConnection, request);
    } else if (pool.length < _config.maxConnections) {
      // 创建新连接
      final request = queue.removeFirst();
      final connection = await _createConnection(host, 80, 'http'); // 默认HTTP端口
      if (connection != null) {
        pool.add(connection);
        await _executeRequest(connection, request);
      }
    }
    // 如果没有可用连接且达到最大连接数，请求将在队列中等待
  }

  /// 查找可用连接
  ConnectionInfo? _findAvailableConnection(List<ConnectionInfo> pool) {
    if (!_config.enableConnectionReuse) {
      return null;
    }

    for (final connection in pool) {
      if (connection.state == ConnectionState.idle &&
          DateTime.now().difference(connection.lastUsedAt).inMinutes < 30) {
        // 标记为活跃
        _updateConnectionState(connection, ConnectionState.active);
        return connection;
      }
    }

    return null;
  }

  /// 创建新连接
  Future<ConnectionInfo?> _createConnection(
      String host, int port, String protocol) async {
    try {
      AppLogger.debug('创建新连接', '$host:$port');

      final connectionId = _generateConnectionId();
      final socket =
          await Socket.connect(host, port, timeout: _config.connectionTimeout);

      return ConnectionInfo(
        id: connectionId,
        host: host,
        port: port,
        protocol: protocol,
        createdAt: DateTime.now(),
        lastUsedAt: DateTime.now(),
        state: ConnectionState.active,
        requestCount: 0,
        totalTime: Duration.zero,
        errorCount: 0,
        averageResponseTime: 0.0,
      );
    } catch (e) {
      AppLogger.error('创建连接失败', e);
      return null;
    }
  }

  /// 执行请求
  Future<void> _executeRequest(
    ConnectionInfo connection,
    ConnectionRequest request,
  ) async {
    final stopwatch = Stopwatch()..start();

    try {
      AppLogger.debug('执行请求', '${connection.id} -> ${request.options.path}');

      // 使用Dio执行请求（简化实现）
      final dio = Dio();
      final response = await dio.fetch(request.options);

      stopwatch.stop();

      // 更新连接统计
      _updateConnectionStats(connection, stopwatch.elapsedMilliseconds, false);

      // 更新全局统计
      _successfulRequests++;
      _totalResponseTime += stopwatch.elapsedMilliseconds;
      _totalRequestsServed++;

      // 释放连接
      _updateConnectionState(connection, ConnectionState.idle);

      // 完成请求
      if (!request.completer.isCompleted) {
        request.completer.complete(response);
      }
    } catch (e) {
      stopwatch.stop();

      // 更新连接统计
      _updateConnectionStats(connection, stopwatch.elapsedMilliseconds, true);

      // 更新全局统计
      _failedRequests++;
      _totalResponseTime += stopwatch.elapsedMilliseconds;
      _totalRequestsServed++;

      // 标记连接为关闭状态
      _updateConnectionState(connection, ConnectionState.closing);

      // 完成请求
      if (!request.completer.isCompleted) {
        request.completer.completeError(e);
      }

      AppLogger.error('请求执行失败', e);
    }
  }

  /// 更新连接状态
  void _updateConnectionState(
      ConnectionInfo connection, ConnectionState newState) {
    // 在实际实现中，这里应该更新连接的状态
    // 由于ConnectionInfo是不可变的，我们需要在池中查找并替换
    for (final pool in _connectionPools.values) {
      for (int i = 0; i < pool.length; i++) {
        if (pool[i].id == connection.id) {
          // 创建新的连接信息（更新状态）
          final updatedConnection = ConnectionInfo(
            id: connection.id,
            host: connection.host,
            port: connection.port,
            protocol: connection.protocol,
            createdAt: connection.createdAt,
            lastUsedAt: DateTime.now(),
            state: newState,
            requestCount: connection.requestCount,
            totalTime: connection.totalTime,
            errorCount: connection.errorCount,
            averageResponseTime: connection.averageResponseTime,
          );
          pool[i] = updatedConnection;
          return;
        }
      }
    }
  }

  /// 更新连接统计
  void _updateConnectionStats(
    ConnectionInfo connection,
    int responseTimeMs,
    bool hasError,
  ) {
    // 在实际实现中，这里应该更新连接的统计信息
    for (final pool in _connectionPools.values) {
      for (int i = 0; i < pool.length; i++) {
        if (pool[i].id == connection.id) {
          final current = pool[i];
          final newRequestCount = current.requestCount + 1;
          final newTotalTime = Duration(
            milliseconds: current.totalTime.inMilliseconds + responseTimeMs,
          );
          final newErrorCount =
              hasError ? current.errorCount + 1 : current.errorCount;
          final newAverageResponseTime =
              newTotalTime.inMilliseconds / newRequestCount;

          final updatedConnection = ConnectionInfo(
            id: current.id,
            host: current.host,
            port: current.port,
            protocol: current.protocol,
            createdAt: current.createdAt,
            lastUsedAt: DateTime.now(),
            state: current.state,
            requestCount: newRequestCount,
            totalTime: newTotalTime,
            errorCount: newErrorCount,
            averageResponseTime: newAverageResponseTime,
          );
          pool[i] = updatedConnection;
          return;
        }
      }
    }
  }

  /// 关闭连接
  Future<void> _closeConnection(ConnectionInfo connection) async {
    try {
      _updateConnectionState(connection, ConnectionState.closed);
      AppLogger.debug('连接已关闭', connection.id);
    } catch (e) {
      AppLogger.error('关闭连接失败', e);
    }
  }

  /// 启动健康检查
  void _startHealthCheck() {
    _healthCheckTimer = Timer.periodic(
      _config.healthCheckInterval,
      (_) => _performHealthCheck(),
    );
  }

  /// 启动空闲连接检查
  void _startIdleConnectionCheck() {
    _idleCheckTimer = Timer.periodic(
      Duration(minutes: 1),
      (_) => _cleanupIdleConnections(),
    );
  }

  /// 执行健康检查
  Future<void> _performHealthCheck() async {
    for (final pool in _connectionPools.values) {
      for (final connection in pool) {
        if (connection.state == ConnectionState.idle &&
            connection.errorCount > 5) {
          // 错误过多的连接需要关闭
          await _closeConnection(connection);
        }
      }
    }
  }

  /// 清理空闲连接
  Future<void> _cleanupIdleConnections() async {
    final now = DateTime.now();

    for (final pool in _connectionPools.values) {
      final connectionsToRemove = <ConnectionInfo>[];

      for (final connection in pool) {
        if (connection.state == ConnectionState.idle &&
            now.difference(connection.lastUsedAt) > _config.idleTimeout) {
          connectionsToRemove.add(connection);
        }
      }

      for (final connection in connectionsToRemove) {
        await _closeConnection(connection);
        pool.remove(connection);
      }
    }
  }

  /// 连接预热
  Future<void> _warmupConnections() async {
    // 预创建一些常用连接
    final commonHosts = ['localhost', '127.0.0.1'];

    for (final host in commonHosts) {
      try {
        final connection = await _createConnection(host, 80, 'http');
        if (connection != null) {
          final pool =
              _connectionPools.putIfAbsent(host, () => <ConnectionInfo>[]);
          pool.add(connection);
        }
      } catch (e) {
        AppLogger.debug('连接预热失败', '$host: $e');
      }
    }
  }

  /// 生成请求ID
  String _generateRequestId() {
    return 'req_${++_requestCounter}_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// 生成连接ID
  String _generateConnectionId() {
    return 'conn_${DateTime.now().millisecondsSinceEpoch}';
  }
}
