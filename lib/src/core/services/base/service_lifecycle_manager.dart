import 'dart:async';
import 'dart:developer' as developer;
import 'i_unified_service.dart';

/// 服务生命周期管理器
///
/// 负责管理所有统一服务的生命周期，包括：
/// - 服务初始化顺序控制
/// - 依赖关系解析
/// - 状态跟踪和监控
/// - 错误处理和恢复
///
/// 支持以下特性：
/// - 拓扑排序确保正确的初始化顺序
/// - 循环依赖检测
/// - 初始化超时控制
/// - 优雅的服务关闭
class ServiceLifecycleManager {
  final ServiceContainer _container;
  final Map<String, ServiceLifecycleState> _states = {};
  final Map<String, DateTime> _stateTimestamps = {};
  final Map<String, String> _errorMessages = {};
  final Duration _initializationTimeout;
  final StreamController<ServiceLifecycleEvent> _eventController =
      StreamController<ServiceLifecycleEvent>.broadcast();

  /// 创建生命周期管理器
  ServiceLifecycleManager(
    this._container, {
    Duration initializationTimeout = const Duration(seconds: 30),
  }) : _initializationTimeout = initializationTimeout;

  /// 服务生命周期事件流
  Stream<ServiceLifecycleEvent> get lifecycleEvents => _eventController.stream;

  /// 初始化所有服务
  ///
  /// 按照依赖关系顺序初始化所有已注册的服务
  /// 如果服务初始化失败，会尝试继续初始化其他独立服务
  Future<List<String>> initializeAllServices() async {
    developer.log('开始初始化所有服务', name: 'ServiceLifecycleManager');

    final serviceNames = _container.getRegisteredServiceNames();
    if (serviceNames.isEmpty) {
      developer.log('没有找到需要初始化的服务', name: 'ServiceLifecycleManager');
      return [];
    }

    try {
      // 计算初始化顺序（拓扑排序）
      final initOrder = _calculateInitializationOrder(serviceNames);
      developer.log('计算得到服务初始化顺序: $initOrder', name: 'ServiceLifecycleManager');

      final List<String> initializedServices = [];
      final List<String> failedServices = [];

      // 按顺序初始化服务
      for (final serviceName in initOrder) {
        try {
          developer.log('开始初始化服务: $serviceName',
              name: 'ServiceLifecycleManager');
          await _initializeService(serviceName);
          initializedServices.add(serviceName);
          developer.log('服务初始化成功: $serviceName',
              name: 'ServiceLifecycleManager');
        } catch (e) {
          failedServices.add(serviceName);
          developer.log('服务初始化失败: $serviceName, 错误: $e',
              name: 'ServiceLifecycleManager', level: 1000);
          developer.log('添加到失败列表: $serviceName',
              name: 'ServiceLifecycleManager');
          // 不需要在这里设置状态，_initializeService已经处理了
        }
      }

      // 记录初始化结果
      if (failedServices.isNotEmpty) {
        final message = '部分服务初始化失败: $failedServices';
        developer.log(message, name: 'ServiceLifecycleManager', level: 1000);
        _eventController.add(ServiceLifecycleEvent.error(
          'initialization_partial_failure',
          message,
          details: {'failed_services': failedServices},
        ));
      } else {
        _eventController.add(ServiceLifecycleEvent.success(
          'all_services_initialized',
          '所有服务初始化成功',
          details: {'initialized_services': initializedServices},
        ));
      }

      return initializedServices;
    } catch (e) {
      final message = '服务初始化过程发生严重错误: $e';
      developer.log(message, name: 'ServiceLifecycleManager', level: 1000);
      _eventController.add(ServiceLifecycleEvent.error(
        'initialization_failure',
        message,
      ));

      // 循环依赖和架构错误应该重新抛出，单个服务失败应该优雅降级
      if (e is StateError && e.toString().contains('循环依赖')) {
        rethrow;
      }

      // 根据R.3规范，其他错误支持优雅降级
      return [];
    }
  }

  /// 初始化单个服务
  Future<void> _initializeService(String serviceName) async {
    final service = _container.getServiceByName(serviceName);
    if (service == null) {
      throw ServiceDependencyException(serviceName, '', '服务未找到');
    }

    if (_states[serviceName] == ServiceLifecycleState.initialized) {
      return; // 已经初始化
    }

    _updateState(serviceName, ServiceLifecycleState.initializing);

    try {
      await _initializeServiceWithTimeout(service);
      _updateState(serviceName, ServiceLifecycleState.initialized);
    } catch (e) {
      _updateState(serviceName, ServiceLifecycleState.error);
      _errorMessages[serviceName] = e.toString();
      rethrow;
    }
  }

  /// 带超时的服务初始化
  Future<void> _initializeServiceWithTimeout(IUnifiedService service) async {
    try {
      await service.initialize(_container).timeout(_initializationTimeout);
    } catch (e) {
      if (e is TimeoutException) {
        throw ServiceInitializationTimeoutException(
            service.serviceName, _initializationTimeout);
      }
      rethrow;
    }
  }

  /// 销毁所有服务
  ///
  /// 按照初始化的逆序销毁所有服务
  Future<void> disposeAllServices() async {
    developer.log('开始销毁所有服务', name: 'ServiceLifecycleManager');

    final serviceNames = _container.getRegisteredServiceNames();
    final initializedServices = serviceNames
        .where((name) => _states[name] == ServiceLifecycleState.initialized)
        .toList();

    // 按初始化的逆序销毁
    final initOrder = _calculateInitializationOrder(initializedServices);
    final disposeOrder = initOrder.reversed.toList();

    final List<String> disposedServices = [];
    final List<String> failedServices = [];

    for (final serviceName in disposeOrder) {
      try {
        await _disposeService(serviceName);
        disposedServices.add(serviceName);
        developer.log('服务销毁成功: $serviceName', name: 'ServiceLifecycleManager');
      } catch (e) {
        failedServices.add(serviceName);
        developer.log('服务销毁失败: $serviceName, 错误: $e',
            name: 'ServiceLifecycleManager', level: 1000);
      }
    }

    if (failedServices.isNotEmpty) {
      _eventController.add(ServiceLifecycleEvent.error(
        'disposal_partial_failure',
        '部分服务销毁失败',
        details: {'failed_services': failedServices},
      ));
    } else {
      _eventController.add(ServiceLifecycleEvent.success(
        'all_services_disposed',
        '所有服务销毁成功',
      ));
    }
  }

  /// 销毁单个服务
  Future<void> _disposeService(String serviceName) async {
    final service = _container.getServiceByName(serviceName);
    if (service == null) return;

    _updateState(serviceName, ServiceLifecycleState.disposing);

    try {
      await service.dispose();
      _updateState(serviceName, ServiceLifecycleState.disposed);
    } catch (e) {
      _updateState(serviceName, ServiceLifecycleState.error);
      _errorMessages[serviceName] = e.toString();
      rethrow;
    }
  }

  /// 计算服务初始化顺序（拓扑排序）
  List<String> _calculateInitializationOrder(List<String> serviceNames) {
    final Map<String, List<String>> graph = {};

    // 构建依赖图
    for (final serviceName in serviceNames) {
      final service = _container.getServiceByName(serviceName);
      graph[serviceName] = service?.dependencies ?? [];
    }

    // 检测循环依赖
    final cycle = _detectCycle(graph);
    if (cycle != null) {
      throw StateError('检测到循环依赖: ${cycle.join(' -> ')}');
    }

    // 拓扑排序
    return _topologicalSort(graph);
  }

  /// 检测循环依赖
  List<String>? _detectCycle(Map<String, List<String>> graph) {
    final Map<String, int> visitState = {};

    for (final node in graph.keys) {
      visitState[node] = 0; // 0: 未访问, 1: 访问中, 2: 已访问
    }

    List<String>? cycleDFS(String node, List<String> path) {
      visitState[node] = 1;
      path.add(node);

      for (final neighbor in graph[node] ?? []) {
        if (!visitState.containsKey(neighbor)) continue;

        if (visitState[neighbor] == 1) {
          // 找到循环
          final cycleStart = path.indexOf(neighbor);
          return path.sublist(cycleStart);
        } else if (visitState[neighbor] == 0) {
          final cycle = cycleDFS(neighbor, path);
          if (cycle != null) return cycle;
        }
      }

      visitState[node] = 2;
      path.removeLast();
      return null;
    }

    for (final node in graph.keys) {
      if (visitState[node] == 0) {
        final cycle = cycleDFS(node, []);
        if (cycle != null) return cycle;
      }
    }

    return null;
  }

  /// 拓扑排序
  List<String> _topologicalSort(Map<String, List<String>> graph) {
    final Map<String, int> inDegree = {};
    final List<String> result = [];

    // 计算入度
    for (final node in graph.keys) {
      inDegree[node] = 0;
    }

    // 对于每个服务，如果有依赖，增加自己的入度
    for (final node in graph.keys) {
      for (final dependency in graph[node] ?? []) {
        if (inDegree.containsKey(node)) {
          inDegree[node] = (inDegree[node] ?? 0) + 1;
        }
      }
    }

    // 找到所有入度为0的节点
    final queue = <String>[];
    for (final entry in inDegree.entries) {
      if (entry.value == 0) {
        queue.add(entry.key);
      }
    }

    // 拓扑排序
    while (queue.isNotEmpty) {
      final node = queue.removeAt(0);
      result.add(node);

      // 找到所有依赖当前节点的其他节点
      for (final otherNode in graph.keys) {
        if (graph[otherNode]?.contains(node) == true) {
          inDegree[otherNode] = (inDegree[otherNode] ?? 0) - 1;
          if (inDegree[otherNode] == 0) {
            queue.add(otherNode);
          }
        }
      }
    }

    return result;
  }

  /// 更新服务状态
  void _updateState(String serviceName, ServiceLifecycleState newState) {
    final oldState = _states[serviceName];
    _states[serviceName] = newState;
    _stateTimestamps[serviceName] = DateTime.now();

    _eventController.add(ServiceLifecycleEvent.stateChanged(
      serviceName,
      oldState ?? ServiceLifecycleState.uninitialized,
      newState,
    ));

    developer.log(
        '服务状态更新: $serviceName ${oldState?.name ?? 'null'} -> ${newState.name}',
        name: 'ServiceLifecycleManager');
  }

  /// 获取服务状态
  ServiceLifecycleState getServiceState(String serviceName) {
    return _states[serviceName] ?? ServiceLifecycleState.uninitialized;
  }

  /// 获取所有服务状态
  Map<String, ServiceLifecycleState> getAllServiceStates() {
    return Map.unmodifiable(_states);
  }

  /// 获取服务错误信息
  String? getServiceError(String serviceName) {
    return _errorMessages[serviceName];
  }

  /// 检查所有服务是否都已初始化
  bool allServicesInitialized() {
    final serviceNames = _container.getRegisteredServiceNames();
    return serviceNames
        .every((name) => _states[name] == ServiceLifecycleState.initialized);
  }

  /// 获取健康状态报告
  Future<Map<String, ServiceHealthStatus>> getHealthReport() async {
    final report = <String, ServiceHealthStatus>{};

    for (final serviceName in _container.getRegisteredServiceNames()) {
      final service = _container.getServiceByName(serviceName);
      if (service != null) {
        try {
          report[serviceName] = await service.checkHealth();
        } catch (e) {
          report[serviceName] = ServiceHealthStatus(
            isHealthy: false,
            message: 'Health check failed: $e',
            lastCheck: DateTime.now(),
          );
        }
      }
    }

    return report;
  }

  /// 释放资源
  void dispose() {
    _eventController.close();
  }
}

/// 服务生命周期事件
class ServiceLifecycleEvent {
  final String type;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic> details;

  ServiceLifecycleEvent._({
    required this.type,
    required this.message,
    required this.details,
  }) : timestamp = DateTime.now();

  factory ServiceLifecycleEvent.stateChanged(
    String serviceName,
    ServiceLifecycleState oldState,
    ServiceLifecycleState newState,
  ) {
    return ServiceLifecycleEvent._(
      type: 'state_changed',
      message:
          'Service $serviceName state changed from ${oldState.name} to ${newState.name}',
      details: {
        'service_name': serviceName,
        'old_state': oldState.name,
        'new_state': newState.name,
      },
    );
  }

  factory ServiceLifecycleEvent.success(String operation, String message,
      {Map<String, dynamic>? details}) {
    return ServiceLifecycleEvent._(
      type: 'success',
      message: message,
      details: {'operation': operation, ...?details},
    );
  }

  factory ServiceLifecycleEvent.error(String operation, String message,
      {Map<String, dynamic>? details}) {
    return ServiceLifecycleEvent._(
      type: 'error',
      message: message,
      details: {'operation': operation, ...?details},
    );
  }

  @override
  String toString() {
    return 'ServiceLifecycleEvent(type: $type, message: $message, timestamp: $timestamp)';
  }
}

/// 服务初始化超时异常
class ServiceInitializationTimeoutException implements Exception {
  final String serviceName;
  final Duration timeout;

  const ServiceInitializationTimeoutException(this.serviceName, this.timeout);

  @override
  String toString() {
    return 'ServiceInitializationTimeoutException($serviceName): 初始化超时 (${timeout.inSeconds}秒)';
  }
}
