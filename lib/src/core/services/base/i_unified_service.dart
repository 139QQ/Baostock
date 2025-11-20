import 'dart:async';
import 'package:meta/meta.dart';

/// 统一服务基础接口
///
/// 定义所有统一服务必须实现的核心契约，包括服务生命周期管理、
/// 依赖关系处理和服务间通信机制。
///
/// 实现类必须遵循以下原则：
/// 1. 线程安全的初始化和销毁
/// 2. 明确的依赖关系声明
/// 3. 优雅的错误处理
/// 4. 资源清理保证
abstract class IUnifiedService {
  /// 内部状态 - 子类不要直接访问
  ServiceLifecycleState _lifecycleState = ServiceLifecycleState.uninitialized;
  DateTime _startTime = DateTime.now();

  /// 服务名称 - 必须在所有服务中唯一
  String get serviceName;

  /// 服务版本 - 用于兼容性检查和迁移
  String get version;

  /// 此服务依赖的其他服务列表
  List<String> get dependencies;

  /// 服务当前的生命周期状态
  ServiceLifecycleState get lifecycleState => _lifecycleState;

  /// 服务初始化
  ///
  /// 在此方法中完成服务的所有初始化工作，包括：
  /// - 资源分配
  /// - 依赖服务获取
  /// - 内部状态设置
  /// - 事件监听器注册
  ///
  /// [container] 提供对其他服务的访问
  ///
  /// 抛出 [ServiceInitializationException] 当初始化失败时
  Future<void> initialize(ServiceContainer container);

  /// 服务销毁
  ///
  /// 在此方法中清理所有资源：
  /// - 取消事件监听
  /// - 释放内存资源
  /// - 关闭网络连接
  /// - 持久化关键状态
  ///
  /// 必须保证即使多次调用也是安全的
  Future<void> dispose();

  /// 健康检查
  ///
  /// 返回服务的健康状态信息
  /// 子类可以重写此方法提供详细的健康检查逻辑
  Future<ServiceHealthStatus> checkHealth() async {
    return ServiceHealthStatus(
      isHealthy: lifecycleState == ServiceLifecycleState.initialized,
      message: 'Service is ${lifecycleState.name}',
      lastCheck: DateTime.now(),
    );
  }

  /// 获取服务统计信息
  ///
  /// 返回服务的运行时统计信息，用于监控和调试
  /// 子类可以重写提供具体指标
  ServiceStats getStats() {
    return ServiceStats(
      serviceName: serviceName,
      version: version,
      uptime: DateTime.now().difference(_startTime),
      memoryUsage: 0, // 子类可以提供具体实现
    );
  }

  /// 受保护的状态设置方法 - 供子类使用
  @protected
  void setLifecycleState(ServiceLifecycleState state) {
    _lifecycleState = state;
    if (state == ServiceLifecycleState.initialized) {
      _startTime = DateTime.now();
    }
  }
}

/// 服务生命周期状态
enum ServiceLifecycleState {
  /// 未初始化
  uninitialized,

  /// 正在初始化
  initializing,

  /// 已初始化，可以提供服务
  initialized,

  /// 正在销毁
  disposing,

  /// 已销毁
  disposed,

  /// 错误状态
  error,
}

/// 服务健康状态
class ServiceHealthStatus {
  final bool isHealthy;
  final String message;
  final DateTime lastCheck;
  final Map<String, dynamic>? details;

  const ServiceHealthStatus({
    required this.isHealthy,
    required this.message,
    required this.lastCheck,
    this.details,
  });

  @override
  String toString() {
    return 'ServiceHealthStatus(isHealthy: $isHealthy, message: $message, lastCheck: $lastCheck)';
  }
}

/// 服务统计信息
class ServiceStats {
  final String serviceName;
  final String version;
  final Duration uptime;
  final int memoryUsage;
  final Map<String, dynamic>? customMetrics;

  const ServiceStats({
    required this.serviceName,
    required this.version,
    required this.uptime,
    required this.memoryUsage,
    this.customMetrics,
  });

  @override
  String toString() {
    return 'ServiceStats(service: $serviceName, version: $version, uptime: $uptime, memory: ${memoryUsage}KB)';
  }
}

/// 服务初始化异常
class ServiceInitializationException implements Exception {
  final String serviceName;
  final String message;
  final dynamic originalError;

  const ServiceInitializationException(
    this.serviceName,
    this.message, [
    this.originalError,
  ]);

  @override
  String toString() {
    return 'ServiceInitializationException($serviceName): $message${originalError != null ? ' (caused by: $originalError)' : ''}';
  }
}

/// 服务依赖解析异常
class ServiceDependencyException implements Exception {
  final String serviceName;
  final String dependencyName;
  final String message;

  const ServiceDependencyException(
    this.serviceName,
    this.dependencyName,
    this.message,
  );

  @override
  String toString() {
    return 'ServiceDependencyException($serviceName -> $dependencyName): $message';
  }
}

/// 服务容器接口
///
/// 提供服务注册、发现和依赖注入功能
abstract class ServiceContainer {
  /// 注册服务实例
  Future<void> registerService<T extends IUnifiedService>(T service);

  /// 获取服务实例
  T getService<T extends IUnifiedService>();

  /// 检查服务是否已注册
  bool isRegistered<T extends IUnifiedService>();

  /// 获取所有已注册的服务名称
  List<String> getRegisteredServiceNames();

  /// 按名称获取服务
  IUnifiedService? getServiceByName(String serviceName);
}

/// 服务元数据
class ServiceMetadata {
  final String serviceName;
  final String version;
  final List<String> dependencies;
  final String description;
  final Map<String, dynamic> tags;

  const ServiceMetadata({
    required this.serviceName,
    required this.version,
    required this.dependencies,
    this.description = '',
    this.tags = const {},
  });
}
