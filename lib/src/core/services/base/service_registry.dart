import 'dart:async';
import 'dart:developer' as developer;
import 'i_unified_service.dart';

/// 服务注册表
///
/// 实现服务的注册、发现和依赖注入功能
/// 支持以下特性：
/// - 单例和工厂模式
/// - 依赖关系解析
/// - 服务生命周期管理
/// - 类型安全的服务访问
class ServiceRegistry implements ServiceContainer {
  final Map<String, ServiceEntry> _services = {};
  final Map<Type, String> _typeToName = {};
  final Map<String, ServiceMetadata> _metadata = {};
  bool _disposed = false;

  /// 注册服务实例（单例模式）
  @override
  Future<void> registerService<T extends IUnifiedService>(T service) async {
    final serviceName = service.serviceName;

    if (_disposed) {
      throw StateError('ServiceRegistry已销毁，无法注册服务');
    }

    if (_services.containsKey(serviceName)) {
      developer.log('警告: 服务已存在，将被覆盖: $serviceName',
          name: 'ServiceRegistry', level: 900);
    }

    // 验证依赖关系
    await _validateDependencies(service);

    // 注册服务
    _services[serviceName] = ServiceEntry<T>(
      service: service,
      factory: null,
      isSingleton: true,
      instance: service,
    );

    _typeToName[T] = serviceName;
    _metadata[serviceName] = ServiceMetadata(
      serviceName: serviceName,
      version: service.version,
      dependencies: service.dependencies,
      description: service.runtimeType.toString(),
    );

    developer.log('服务注册成功: $serviceName (${T.toString()})',
        name: 'ServiceRegistry');
  }

  /// 注册服务工厂
  Future<void> registerServiceFactory<T extends IUnifiedService>(
    String serviceName,
    T Function() factory, {
    List<String> dependencies = const [],
    String version = '1.0.0',
    String description = '',
  }) async {
    if (_disposed) {
      throw StateError('ServiceRegistry已销毁，无法注册服务工厂');
    }

    if (_services.containsKey(serviceName)) {
      developer.log('警告: 服务工厂已存在，将被覆盖: $serviceName',
          name: 'ServiceRegistry', level: 900);
    }

    // 验证工厂
    try {
      final testInstance = factory();
      await _validateDependencies(testInstance);
    } catch (e) {
      throw ServiceInitializationException(serviceName, '工厂验证失败: $e');
    }

    // 注册工厂
    _services[serviceName] = ServiceEntry<T>(
      service: null,
      factory: factory,
      isSingleton: false,
      instance: null,
    );

    _typeToName[T] = serviceName;
    _metadata[serviceName] = ServiceMetadata(
      serviceName: serviceName,
      version: version,
      dependencies: dependencies,
      description: description,
    );

    developer.log('服务工厂注册成功: $serviceName (${T.toString()})',
        name: 'ServiceRegistry');
  }

  /// 注册单例服务工厂
  Future<void> registerSingletonServiceFactory<T extends IUnifiedService>(
    String serviceName,
    T Function() factory, {
    List<String> dependencies = const [],
    String version = '1.0.0',
    String description = '',
  }) async {
    if (_disposed) {
      throw StateError('ServiceRegistry已销毁，无法注册单例服务工厂');
    }

    if (_services.containsKey(serviceName)) {
      developer.log('警告: 单例服务工厂已存在，将被覆盖: $serviceName',
          name: 'ServiceRegistry', level: 900);
    }

    // 验证工厂
    try {
      final testInstance = factory();
      await _validateDependencies(testInstance);
    } catch (e) {
      throw ServiceInitializationException(serviceName, '工厂验证失败: $e');
    }

    // 注册单例工厂
    _services[serviceName] = ServiceEntry<T>(
      service: null,
      factory: factory,
      isSingleton: true,
      instance: null,
    );

    _typeToName[T] = serviceName;
    _metadata[serviceName] = ServiceMetadata(
      serviceName: serviceName,
      version: version,
      dependencies: dependencies,
      description: description,
    );

    developer.log('单例服务工厂注册成功: $serviceName (${T.toString()})',
        name: 'ServiceRegistry');
  }

  /// 获取服务实例（类型安全）
  @override
  T getService<T extends IUnifiedService>() {
    final serviceName = _typeToName[T];
    if (serviceName == null) {
      throw ServiceDependencyException(T.toString(), '', '服务类型未注册');
    }

    final service = getServiceByName(serviceName);
    if (service == null) {
      throw ServiceDependencyException(T.toString(), serviceName, '服务实例未找到');
    }

    return service as T;
  }

  /// 获取服务实例（按名称）
  @override
  IUnifiedService? getServiceByName(String serviceName) {
    if (_disposed) {
      throw StateError('ServiceRegistry已销毁，无法获取服务');
    }

    final entry = _services[serviceName];
    if (entry == null) {
      return null;
    }

    if (entry.instance != null) {
      return entry.instance;
    }

    // 创建实例
    if (entry.factory != null) {
      final instance = entry.factory!();

      if (entry.isSingleton) {
        // 保存单例实例
        entry.instance = instance;
        developer.log('创建单例实例: $serviceName', name: 'ServiceRegistry');
      } else {
        developer.log('创建实例: $serviceName', name: 'ServiceRegistry');
      }

      return instance;
    }

    return null;
  }

  /// 检查服务是否已注册
  @override
  bool isRegistered<T extends IUnifiedService>() {
    final serviceName = _typeToName[T];
    return serviceName != null && _services.containsKey(serviceName);
  }

  /// 检查服务名称是否已注册
  bool isRegisteredByName(String serviceName) {
    return _services.containsKey(serviceName);
  }

  /// 获取所有已注册的服务名称
  @override
  List<String> getRegisteredServiceNames() {
    return List.unmodifiable(_services.keys.toList());
  }

  /// 获取服务元数据
  ServiceMetadata? getServiceMetadata(String serviceName) {
    return _metadata[serviceName];
  }

  /// 获取所有服务元数据
  Map<String, ServiceMetadata> getAllServiceMetadata() {
    return Map.unmodifiable(_metadata);
  }

  /// 验证服务依赖关系
  Future<void> _validateDependencies(IUnifiedService service) async {
    // 移除依赖服务必须已注册的检查，允许循环依赖被注册
    // 循环依赖将在解析阶段被检测到
    for (final dependencyName in service.dependencies) {
      // 仅验证依赖名称不为空
      if (dependencyName.isEmpty) {
        throw ServiceDependencyException(
          service.serviceName,
          dependencyName,
          '依赖服务名称不能为空',
        );
      }
    }
  }

  /// 注销服务
  Future<void> unregisterService(String serviceName) async {
    if (_disposed) {
      throw StateError('ServiceRegistry已销毁，无法注销服务');
    }

    final entry = _services.remove(serviceName);
    if (entry == null) {
      return; // 服务不存在
    }

    // 销毁实例
    if (entry.instance != null) {
      try {
        await entry.instance!.dispose();
        developer.log('服务销毁成功: $serviceName', name: 'ServiceRegistry');
      } catch (e) {
        developer.log('服务销毁失败: $serviceName, 错误: $e',
            name: 'ServiceRegistry', level: 1000);
      }
    }

    // 清理类型映射
    _typeToName.removeWhere((key, value) => value == serviceName);
    _metadata.remove(serviceName);

    developer.log('服务注销成功: $serviceName', name: 'ServiceRegistry');
  }

  /// 清理所有服务
  Future<void> clear() async {
    if (_disposed) {
      return;
    }

    developer.log('开始清理所有服务', name: 'ServiceRegistry');

    final serviceNames = List.unmodifiable(_services.keys.toList());

    // 按注册的逆序销毁
    for (final serviceName in serviceNames.reversed) {
      try {
        await unregisterService(serviceName);
      } catch (e) {
        developer.log('清理服务失败: $serviceName, 错误: $e',
            name: 'ServiceRegistry', level: 1000);
      }
    }

    developer.log('所有服务清理完成', name: 'ServiceRegistry');
  }

  /// 获取服务统计信息
  Map<String, dynamic> getStats() {
    final stats = <String, dynamic>{
      'total_services': _services.length,
      'singleton_services': 0,
      'factory_services': 0,
      'initialized_instances': 0,
    };

    for (final entry in _services.values) {
      if (entry.isSingleton) {
        stats['singleton_services']++;
      } else {
        stats['factory_services']++;
      }

      if (entry.instance != null) {
        stats['initialized_instances']++;
      }
    }

    return stats;
  }

  /// 销毁注册表
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }

    await clear();
    _services.clear();
    _typeToName.clear();
    _metadata.clear();
    _disposed = true;

    developer.log('ServiceRegistry已销毁', name: 'ServiceRegistry');
  }
}

/// 服务注册表项
class ServiceEntry<T extends IUnifiedService> {
  final T? service;
  final T Function()? factory;
  final bool isSingleton;
  T? instance;

  ServiceEntry({
    this.service,
    this.factory,
    required this.isSingleton,
    this.instance,
  }) {
    if (service != null) {
      instance = service;
    }
  }
}

/// 服务依赖解析器
class ServiceDependencyResolver {
  final ServiceRegistry _registry;

  ServiceDependencyResolver(this._registry);

  /// 解析服务依赖链
  List<String> resolveDependencyChain(String serviceName) {
    final visited = <String>{};
    final chain = <String>[];
    final result = <String>[];

    void dfs(String name) {
      if (visited.contains(name)) {
        throw StateError('检测到循环依赖: ${chain.join(' -> ')} -> $name');
      }

      visited.add(name);
      chain.add(name);

      final metadata = _registry.getServiceMetadata(name);
      if (metadata != null) {
        for (final dependency in metadata.dependencies) {
          if (_registry.isRegisteredByName(dependency)) {
            dfs(dependency);
          }
        }
      }

      chain.removeLast();
      result.add(name); // 添加到结果中，这样依赖关系是从依赖到被依赖者
    }

    dfs(serviceName);
    return result.reversed.toList(); // 反转使得从基础依赖到目标服务
  }

  /// 获取依赖图
  Map<String, List<String>> getDependencyGraph() {
    final graph = <String, List<String>>{};

    for (final serviceName in _registry.getRegisteredServiceNames()) {
      final metadata = _registry.getServiceMetadata(serviceName);
      graph[serviceName] = metadata?.dependencies ?? [];
    }

    return graph;
  }

  /// 验证所有依赖关系
  List<String> validateAllDependencies() {
    final errors = <String>[];

    for (final serviceName in _registry.getRegisteredServiceNames()) {
      final metadata = _registry.getServiceMetadata(serviceName);
      if (metadata != null) {
        for (final dependency in metadata.dependencies) {
          if (!_registry.isRegisteredByName(dependency)) {
            errors.add('服务 $serviceName 依赖的服务 $dependency 未注册');
          }
        }
      }
    }

    return errors;
  }
}

/// 服务配置构建器
class ServiceConfigurationBuilder {
  final ServiceRegistry _registry;
  final List<_PendingRegistration> _pendingRegistrations = [];

  ServiceConfigurationBuilder(this._registry);

  /// 添加服务实例
  ServiceConfigurationBuilder addService<T extends IUnifiedService>(T service) {
    _pendingRegistrations.add(_PendingRegistration<T>(
      type: _RegistrationType.instance,
      service: service,
      serviceName: service.serviceName,
    ));
    return this;
  }

  /// 添加服务工厂
  ServiceConfigurationBuilder addServiceFactory<T extends IUnifiedService>(
    String serviceName,
    T Function() factory, {
    List<String> dependencies = const [],
    String version = '1.0.0',
    String description = '',
  }) {
    _pendingRegistrations.add(_PendingRegistration<T>(
      type: _RegistrationType.factory,
      factory: factory,
      serviceName: serviceName,
      dependencies: dependencies,
      version: version,
      description: description,
    ));
    return this;
  }

  /// 添加单例服务工厂
  ServiceConfigurationBuilder
      addSingletonServiceFactory<T extends IUnifiedService>(
    String serviceName,
    T Function() factory, {
    List<String> dependencies = const [],
    String version = '1.0.0',
    String description = '',
  }) {
    _pendingRegistrations.add(_PendingRegistration<T>(
      type: _RegistrationType.singletonFactory,
      factory: factory,
      serviceName: serviceName,
      dependencies: dependencies,
      version: version,
      description: description,
    ));
    return this;
  }

  /// 应用配置
  Future<void> apply() async {
    for (final registration in _pendingRegistrations) {
      switch (registration.type) {
        case _RegistrationType.instance:
          await _registry.registerService(registration.service!);
          break;
        case _RegistrationType.factory:
          await _registry.registerServiceFactory(
            registration.serviceName!,
            registration.factory!,
            dependencies: registration.dependencies,
            version: registration.version,
            description: registration.description,
          );
          break;
        case _RegistrationType.singletonFactory:
          await _registry.registerSingletonServiceFactory(
            registration.serviceName!,
            registration.factory!,
            dependencies: registration.dependencies,
            version: registration.version,
            description: registration.description,
          );
          break;
      }
    }

    _pendingRegistrations.clear();
  }
}

enum _RegistrationType { instance, factory, singletonFactory }

class _PendingRegistration<T extends IUnifiedService> {
  final _RegistrationType type;
  final T? service;
  final T Function()? factory;
  final String? serviceName;
  final List<String> dependencies;
  final String version;
  final String description;

  _PendingRegistration({
    required this.type,
    this.service,
    this.factory,
    this.serviceName,
    this.dependencies = const [],
    this.version = '1.0.0',
    this.description = '',
  });
}
