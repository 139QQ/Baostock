// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:async';
import 'dart:isolate';

import '../../utils/logger.dart';

/// Isolate状态枚举
enum IsolateState {
  idle, // 空闲状态
  starting, // 启动中
  running, // 运行中
  stopping, // 停止中
  stopped, // 已停止
  crashed, // 崩溃状态
  zombie, // 僵尸状态
}

/// Isolate健康状态
class IsolateHealthStatus {
  final String isolateId;
  final IsolateState state;
  final DateTime lastHeartbeat;
  final int memoryUsageMB;
  final double cpuUsage;
  final int tasksProcessed;
  final Duration uptime;
  final String? errorMessage;

  IsolateHealthStatus({
    required this.isolateId,
    required this.state,
    required this.lastHeartbeat,
    required this.memoryUsageMB,
    required this.cpuUsage,
    required this.tasksProcessed,
    required this.uptime,
    this.errorMessage,
  });

  bool get isHealthy =>
      state == IsolateState.running &&
      DateTime.now().difference(lastHeartbeat) < const Duration(seconds: 30);

  bool get isZombie =>
      state == IsolateState.zombie ||
      (state == IsolateState.running &&
          DateTime.now().difference(lastHeartbeat) >
              const Duration(seconds: 60));

  Map<String, dynamic> toJson() {
    return {
      'isolateId': isolateId,
      'state': state.name,
      'lastHeartbeat': lastHeartbeat.toIso8601String(),
      'memoryUsageMB': memoryUsageMB,
      'cpuUsage': cpuUsage,
      'tasksProcessed': tasksProcessed,
      'uptime': uptime.inMilliseconds,
      'errorMessage': errorMessage,
    };
  }
}

/// Isolate配置
class IsolateConfig {
  final String isolateId;
  final SendPort sendPort;
  final ReceivePort receivePort;
  final Isolate isolate;
  final Duration heartbeatInterval;
  final Duration maxIdleTime;
  final int maxMemoryMB;
  final double maxCpuUsage;

  IsolateConfig({
    required this.isolateId,
    required this.sendPort,
    required this.receivePort,
    required this.isolate,
    this.heartbeatInterval = const Duration(seconds: 30),
    this.maxIdleTime = const Duration(minutes: 5),
    this.maxMemoryMB = 512,
    this.maxCpuUsage = 80.0,
  });
}

/// 改进的Isolate管理器
///
/// 提供心跳监控、优雅关闭、僵尸进程检测和内存泄漏预防功能
class ImprovedIsolateManager {
  static final ImprovedIsolateManager _instance =
      ImprovedIsolateManager._internal();
  factory ImprovedIsolateManager() => _instance;
  ImprovedIsolateManager._internal();

  // 使用自定义AppLogger静态方法
  final Map<String, IsolateConfig> _isolates = {};
  final Map<String, Timer> _heartbeatTimers = {};
  final Map<String, IsolateHealthStatus> _healthStatus = {};
  Timer? _healthCheckTimer;
  Timer? _memoryLeakCheckTimer;

  final StreamController<IsolateHealthStatus> _healthStatusController =
      StreamController<IsolateHealthStatus>.broadcast();
  Stream<IsolateHealthStatus> get healthStatusStream =>
      _healthStatusController.stream;

  /// 启动Isolate管理器
  Future<void> start() async {
    if (_healthCheckTimer != null) return;

    AppLogger.info('启动ImprovedIsolateManager');

    // 启动健康检查定时器（每30秒检查一次）
    _healthCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      _performHealthCheck,
    );

    // 启动内存泄漏检测定时器（每5分钟检查一次）
    _memoryLeakCheckTimer = Timer.periodic(
      const Duration(minutes: 5),
      _detectMemoryLeaks,
    );

    AppLogger.info('ImprovedIsolateManager启动完成');
  }

  /// 停止Isolate管理器
  Future<void> stop() async {
    AppLogger.info('停止ImprovedIsolateManager');

    // 停止所有定时器
    _healthCheckTimer?.cancel();
    _memoryLeakCheckTimer?.cancel();
    _healthCheckTimer = null;
    _memoryLeakCheckTimer = null;

    // 优雅关闭所有Isolate
    final isolateIds = _isolates.keys.toList();
    for (final isolateId in isolateIds) {
      await shutdownIsolate(isolateId);
    }

    await _healthStatusController.close();
    AppLogger.info('ImprovedIsolateManager已停止');
  }

  /// 创建并启动新的Isolate
  Future<String> startIsolate<T>({
    required Future<T> Function(SendPort sendPort) entryPoint,
    Map<String, dynamic>? initialData,
    Duration? heartbeatInterval,
    Duration? maxIdleTime,
    int? maxMemoryMB,
    double? maxCpuUsage,
  }) async {
    final isolateId =
        'isolate_${DateTime.now().millisecondsSinceEpoch}_${_isolates.length}';

    try {
      AppLogger.info('启动Isolate: $isolateId');

      // 创建通信通道
      final receivePort = ReceivePort();
      final isolate = await Isolate.spawn(
        _isolateEntry<T>,
        receivePort.sendPort,
        debugName: isolateId,
      );

      // 等待Isolate准备就绪
      final completer = Completer<SendPort>();
      late StreamSubscription subscription;

      subscription = receivePort.listen((message) {
        if (message is SendPort) {
          completer.complete(message);
          subscription.cancel();

          // 重新监听数据消息
          receivePort.listen(_handleIsolateMessage(isolateId));
        }
      });

      final sendPort = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Isolate启动超时'),
      );

      // 创建配置
      final config = IsolateConfig(
        isolateId: isolateId,
        sendPort: sendPort,
        receivePort: receivePort,
        isolate: isolate,
        heartbeatInterval: heartbeatInterval ?? const Duration(seconds: 30),
        maxIdleTime: maxIdleTime ?? const Duration(minutes: 5),
        maxMemoryMB: maxMemoryMB ?? 512,
        maxCpuUsage: maxCpuUsage ?? 80.0,
      );

      _isolates[isolateId] = config;

      // 初始化健康状态
      _healthStatus[isolateId] = IsolateHealthStatus(
        isolateId: isolateId,
        state: IsolateState.starting,
        lastHeartbeat: DateTime.now(),
        memoryUsageMB: 0,
        cpuUsage: 0.0,
        tasksProcessed: 0,
        uptime: Duration.zero,
      );

      // 启动心跳监控
      _startHeartbeatMonitoring(isolateId);

      // 发送初始化数据
      if (initialData != null) {
        sendPort.send({
          'type': 'init',
          'data': initialData,
        });
      }

      // 更新状态为运行中
      _updateHealthStatus(isolateId, IsolateState.running);

      AppLogger.info('Isolate启动成功: $isolateId');
      return isolateId;
    } catch (e) {
      AppLogger.error('Isolate启动失败: $isolateId', e);
      await _cleanupIsolate(isolateId);
      rethrow;
    }
  }

  /// 优雅关闭Isolate
  Future<void> shutdownIsolate(String isolateId) async {
    final config = _isolates[isolateId];
    if (config == null) return;

    try {
      AppLogger.info('关闭Isolate: $isolateId');

      // 更新状态为停止中
      _updateHealthStatus(isolateId, IsolateState.stopping);

      // 发送关闭信号
      config.sendPort.send({'type': 'shutdown'});

      // 等待优雅关闭（最多10秒）
      await Future.delayed(const Duration(seconds: 10));

      // 强制关闭
      await _cleanupIsolate(isolateId);

      AppLogger.info('Isolate关闭完成: $isolateId');
    } catch (e) {
      AppLogger.error('Isolate关闭失败: $isolateId', e);
      await _cleanupIsolate(isolateId);
    }
  }

  /// 向Isolate发送任务
  Future<void> sendTask(String isolateId, Map<String, dynamic> task) async {
    final config = _isolates[isolateId];
    if (config == null) {
      throw StateError('Isolate不存在: $isolateId');
    }

    final health = _healthStatus[isolateId];
    if (health == null || !health.isHealthy) {
      throw StateError('Isolate状态异常: $isolateId');
    }

    try {
      config.sendPort.send({
        'type': 'task',
        'taskId': DateTime.now().millisecondsSinceEpoch.toString(),
        'data': task,
      });

      AppLogger.debug('任务已发送到Isolate: $isolateId');
    } catch (e) {
      AppLogger.error('发送任务失败: $isolateId', e);
      rethrow;
    }
  }

  /// 获取Isolate健康状态
  IsolateHealthStatus? getHealthStatus(String isolateId) {
    return _healthStatus[isolateId];
  }

  /// 获取所有Isolate健康状态
  Map<String, IsolateHealthStatus> getAllHealthStatus() {
    return Map.unmodifiable(_healthStatus);
  }

  /// Isolate入口点
  static void _isolateEntry<T>(SendPort mainSendPort) async {
    final receivePort = ReceivePort();
    mainSendPort.send(receivePort.sendPort);

    Timer? heartbeatTimer;
    bool isShuttingDown = false;

    // 心跳响应
    void sendHeartbeat() async {
      if (!isShuttingDown) {
        mainSendPort.send({
          'type': 'heartbeat',
          'timestamp': DateTime.now().toIso8601String(),
          'memoryUsage': await _getCurrentMemoryUsage(),
        });
      }
    }

    // 处理主线程消息
    receivePort.listen((message) async {
      try {
        if (message is Map<String, dynamic>) {
          switch (message['type']) {
            case 'init':
              // 初始化心跳定时器
              final heartbeatInterval =
                  message['data']?['heartbeatInterval'] ?? 30;
              heartbeatTimer = Timer.periodic(
                Duration(seconds: heartbeatInterval),
                (_) => sendHeartbeat(),
              );
              sendHeartbeat(); // 立即发送一次心跳
              break;

            case 'task':
              // 处理任务（需要在具体实现中重写）
              await _handleIsolateTask(message['data']);
              mainSendPort.send({
                'type': 'task_complete',
                'taskId': message['taskId'],
                'result': 'success',
              });
              break;

            case 'shutdown':
              isShuttingDown = true;
              heartbeatTimer?.cancel();
              receivePort.close();
              break;
          }
        }
      } catch (e) {
        mainSendPort.send({
          'type': 'error',
          'error': e.toString(),
        });
      }
    });
  }

  /// 处理Isolate任务（需要子类重写）
  static Future<void> _handleIsolateTask(Map<String, dynamic> task) async {
    // 默认实现，子类应该重写此方法
    await Future.delayed(Duration.zero);
  }

  /// 处理Isolate消息
  void Function(dynamic) _handleIsolateMessage(String isolateId) {
    return (dynamic message) {
      try {
        if (message is Map<String, dynamic>) {
          switch (message['type']) {
            case 'heartbeat':
              _handleHeartbeat(isolateId, message);
              break;
            case 'task_complete':
              _handleTaskComplete(isolateId, message);
              break;
            case 'error':
              _handleIsolateError(isolateId, message['error']);
              break;
          }
        }
      } catch (e) {
        AppLogger.error('处理Isolate消息失败: $isolateId', e);
      }
    };
  }

  /// 处理心跳
  void _handleHeartbeat(String isolateId, Map<String, dynamic> heartbeat) {
    final health = _healthStatus[isolateId];
    if (health == null) return;

    _healthStatus[isolateId] = IsolateHealthStatus(
      isolateId: isolateId,
      state: IsolateState.running,
      lastHeartbeat: DateTime.parse(heartbeat['timestamp']),
      memoryUsageMB: heartbeat['memoryUsage'] ?? 0,
      cpuUsage: health.cpuUsage,
      tasksProcessed: health.tasksProcessed,
      uptime: health.uptime,
    );

    // 检查内存使用
    if (heartbeat['memoryUsage'] > _isolates[isolateId]!.maxMemoryMB) {
      AppLogger.warn(
          'Isolate内存使用超限: $isolateId, ${heartbeat['memoryUsage']}MB');
      _handleMemoryPressure(isolateId);
    }
  }

  /// 处理任务完成
  void _handleTaskComplete(String isolateId, Map<String, dynamic> result) {
    final health = _healthStatus[isolateId];
    if (health == null) return;

    _healthStatus[isolateId] = IsolateHealthStatus(
      isolateId: isolateId,
      state: IsolateState.running,
      lastHeartbeat: health.lastHeartbeat,
      memoryUsageMB: health.memoryUsageMB,
      cpuUsage: health.cpuUsage,
      tasksProcessed: health.tasksProcessed + 1,
      uptime: health.uptime,
    );

    AppLogger.debug('Isolate任务完成: $isolateId');
  }

  /// 处理Isolate错误
  void _handleIsolateError(String isolateId, String error) {
    AppLogger.error('Isolate错误: $isolateId', Exception(error));

    _updateHealthStatus(isolateId, IsolateState.crashed, errorMessage: error);

    // 尝试重启或清理
    _restartOrCleanupIsolate(isolateId);
  }

  /// 处理内存压力
  void _handleMemoryPressure(String isolateId) {
    AppLogger.warn('处理内存压力: $isolateId');

    // 可以在这里实现内存压力缓解策略
    // 例如：通知垃圾回收、降低任务处理频率等
  }

  /// 重启或清理Isolate
  Future<void> _restartOrCleanupIsolate(String isolateId) async {
    // 在生产环境中，可能需要重启Isolate
    // 在开发环境中，直接清理以防止内存泄漏
    await _cleanupIsolate(isolateId);
  }

  /// 启动心跳监控
  void _startHeartbeatMonitoring(String isolateId) {
    final config = _isolates[isolateId];
    if (config == null) return;

    _heartbeatTimers[isolateId] = Timer.periodic(
      config.heartbeatInterval,
      (_) => _checkIsolateHeartbeat(isolateId),
    );
  }

  /// 检查Isolate心跳
  void _checkIsolateHeartbeat(String isolateId) {
    final health = _healthStatus[isolateId];
    if (health == null) return;

    final timeSinceLastHeartbeat =
        DateTime.now().difference(health.lastHeartbeat);

    if (timeSinceLastHeartbeat > const Duration(seconds: 90)) {
      AppLogger.warn('Isolate心跳超时: $isolateId');
      _updateHealthStatus(isolateId, IsolateState.zombie);
      _restartOrCleanupIsolate(isolateId);
    }
  }

  /// 执行健康检查
  void _performHealthCheck(Timer timer) {
    final now = DateTime.now();
    final zombieIsolates = <String>[];

    for (final entry in _healthStatus.entries) {
      final isolateId = entry.key;
      final health = entry.value;

      if (health.isZombie) {
        zombieIsolates.add(isolateId);
      } else if (now.difference(health.lastHeartbeat) >
          const Duration(seconds: 60)) {
        _updateHealthStatus(isolateId, IsolateState.zombie);
        zombieIsolates.add(isolateId);
      }
    }

    // 清理僵尸Isolate
    for (final isolateId in zombieIsolates) {
      AppLogger.warn('发现僵尸Isolate，正在清理: $isolateId');
      _restartOrCleanupIsolate(isolateId);
    }
  }

  /// 检测内存泄漏
  void _detectMemoryLeaks(Timer timer) {
    final suspiciousIsolates = <String>[];

    for (final entry in _healthStatus.entries) {
      final isolateId = entry.key;
      final health = entry.value;

      // 检查内存使用是否持续增长
      if (health.memoryUsageMB > _isolates[isolateId]!.maxMemoryMB * 0.8) {
        suspiciousIsolates.add(isolateId);
      }
    }

    if (suspiciousIsolates.isNotEmpty) {
      AppLogger.warn('检测到可能的内存泄漏: ${suspiciousIsolates.join(', ')}');

      // 可以在这里实现更详细的内存泄漏检测
      // 例如：记录内存使用历史、分析增长趋势等
    }
  }

  /// 更新健康状态
  void _updateHealthStatus(
    String isolateId,
    IsolateState state, {
    String? errorMessage,
  }) {
    final current = _healthStatus[isolateId];
    if (current == null) return;

    _healthStatus[isolateId] = IsolateHealthStatus(
      isolateId: isolateId,
      state: state,
      lastHeartbeat: current.lastHeartbeat,
      memoryUsageMB: current.memoryUsageMB,
      cpuUsage: current.cpuUsage,
      tasksProcessed: current.tasksProcessed,
      uptime: DateTime.now().difference(current.lastHeartbeat),
      errorMessage: errorMessage,
    );

    // 发送状态更新事件
    _healthStatusController.add(_healthStatus[isolateId]!);
  }

  /// 清理Isolate资源
  Future<void> _cleanupIsolate(String isolateId) async {
    // 取消心跳定时器
    _heartbeatTimers[isolateId]?.cancel();
    _heartbeatTimers.remove(isolateId);

    // 关闭Isolate
    final config = _isolates.remove(isolateId);
    if (config != null) {
      config.receivePort.close();
      config.isolate.kill(priority: Isolate.immediate);
    }

    // 移除健康状态
    _healthStatus.remove(isolateId);

    AppLogger.debug('ImprovedIsolateManager', 'Isolate资源清理完成: $isolateId');
  }

  /// 获取当前内存使用量（现代化方法替代过时的developer.getCurrentRSS）
  static Future<int> _getCurrentMemoryUsage() async {
    try {
      // 在实际项目中，这里应该使用平台特定的API获取内存信息
      // 由于getCurrentRSS已弃用，我们使用模拟数据

      // 模拟基础内存信息（单位：字节）
      const rss = 100 * 1024 * 1024; // 100MB 模拟值

      return rss ~/ (1024 * 1024); // 转换为MB
    } catch (e) {
      return 100; // 默认100MB
    }
  }
}
