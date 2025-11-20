import 'i_unified_service.dart';

/// 简单的服务容器实现
/// 用于测试环境中的服务依赖注入
class SimpleServiceContainer implements ServiceContainer {
  final Map<String, IUnifiedService> _services = {};
  final Map<Type, String> _typeToName = {};

  @override
  Future<void> registerService<T extends IUnifiedService>(T service) async {
    final serviceName = service.serviceName;
    _services[serviceName] = service;
    _typeToName[T] = serviceName;
  }

  @override
  T getService<T extends IUnifiedService>() {
    final serviceName = _typeToName[T];
    if (serviceName == null) {
      throw StateError('Service of type $T not registered');
    }
    final service = _services[serviceName];
    if (service is! T) {
      throw StateError('Service $serviceName is not of type $T');
    }
    return service;
  }

  @override
  bool isRegistered<T extends IUnifiedService>() {
    final serviceName = _typeToName[T];
    return serviceName != null && _services.containsKey(serviceName);
  }

  @override
  List<String> getRegisteredServiceNames() {
    return _services.keys.toList();
  }

  @override
  IUnifiedService? getServiceByName(String serviceName) {
    return _services[serviceName];
  }

  /// 清理所有服务
  Future<void> disposeAll() async {
    for (final service in _services.values) {
      try {
        await service.dispose();
      } catch (e) {
        // 忽略dispose时的错误
      }
    }
    _services.clear();
    _typeToName.clear();
  }
}
