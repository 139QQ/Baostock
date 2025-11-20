import 'dart:async';
import 'dart:developer' as developer;
import 'package:get_it/get_it.dart';
import '../base/service_container.dart';
import '../base/i_unified_service.dart';

/// 服务依赖注入配置
///
/// 提供与GetIt容器的集成，支持：
/// - 统一服务的依赖注入配置
/// - GetIt和ServiceRegistry的双向同步
/// - 现有GetIt服务的平滑迁移
/// - 单例和工厂模式支持
class ServiceInjectionConfig {
  static final ServiceInjectionConfig _instance =
      ServiceInjectionConfig._internal();
  factory ServiceInjectionConfig() => _instance;
  ServiceInjectionConfig._internal();

  final GetIt _getIt = GetIt.instance;
  UnifiedServiceContainer? _serviceContainer;

  /// 初始化依赖注入配置
  Future<void> initialize(UnifiedServiceContainer serviceContainer) async {
    if (_serviceContainer != null) {
      developer.log('ServiceInjectionConfig已初始化',
          name: 'ServiceInjectionConfig');
      return;
    }

    _serviceContainer = serviceContainer;

    // 同步现有服务到GetIt
    await _syncServicesToGetIt();

    developer.log('ServiceInjectionConfig初始化完成',
        name: 'ServiceInjectionConfig');
  }

  /// 注册服务到GetIt
  Future<void> registerServiceToGetIt<T extends IUnifiedService>({
    bool isSingleton = true,
    String? instanceName,
  }) async {
    if (_serviceContainer == null) {
      throw StateError('ServiceInjectionConfig未初始化');
    }

    final service = _serviceContainer!.getService<T>();

    if (isSingleton) {
      if (instanceName != null) {
        _getIt.registerSingleton<T>(service, instanceName: instanceName);
      } else {
        _getIt.registerSingleton<T>(service);
      }
    } else {
      if (instanceName != null) {
        _getIt.registerFactory<T>(() => _serviceContainer!.getService<T>(),
            instanceName: instanceName);
      } else {
        _getIt.registerFactory<T>(() => _serviceContainer!.getService<T>());
      }
    }

    developer.log('服务已注册到GetIt: ${T.toString()}',
        name: 'ServiceInjectionConfig');
  }

  /// 从GetIt获取服务
  T getFromGetIt<T extends Object>({String? instanceName}) {
    if (instanceName != null) {
      return _getIt.get<T>(instanceName: instanceName);
    } else {
      return _getIt.get<T>();
    }
  }

  /// 检查GetIt中是否注册了服务
  bool isRegisteredInGetIt<Type extends Object>({String? instanceName}) {
    return _getIt.isRegistered<Type>(instanceName: instanceName);
  }

  /// 同步ServiceRegistry中的服务到GetIt
  Future<void> _syncServicesToGetIt() async {
    if (_serviceContainer == null) return;

    try {
      final serviceNames = _serviceContainer!.getRegisteredServiceNames();

      for (final serviceName in serviceNames) {
        try {
          final service = _serviceContainer!.getServiceByName(serviceName);
          if (service != null) {
            // 使用运行时类型进行注册
            await _registerServiceByType(service);
          }
        } catch (e) {
          developer.log('同步服务到GetIt失败: $serviceName, 错误: $e',
              name: 'ServiceInjectionConfig', level: 900);
        }
      }
    } catch (e) {
      developer.log('获取服务名称列表失败: $e',
          name: 'ServiceInjectionConfig', level: 900);
    }
  }

  /// 根据类型注册服务
  Future<void> _registerServiceByType(IUnifiedService service) async {
    final serviceType = service.runtimeType;

    try {
      // 注册为IUnifiedService类型
      _getIt.registerSingleton<IUnifiedService>(
        service,
        instanceName: service.serviceName,
      );

      developer.log('服务类型已注册到GetIt: $serviceType',
          name: 'ServiceInjectionConfig');
    } catch (e) {
      developer.log('注册服务类型到GetIt失败: $serviceType, 错误: $e',
          name: 'ServiceInjectionConfig', level: 900);
    }
  }

  /// 从GetIt注销服务
  Future<void> unregisterFromGetIt<T extends Object>(
      {String? instanceName}) async {
    try {
      if (_getIt.isRegistered<T>(instanceName: instanceName)) {
        _getIt.unregister<T>(instanceName: instanceName);
        developer.log('服务已从GetIt注销: ${T.toString()}',
            name: 'ServiceInjectionConfig');
      }
    } catch (e) {
      developer.log('从GetIt注销服务失败: ${T.toString()}, 错误: $e',
          name: 'ServiceInjectionConfig', level: 900);
    }
  }

  /// 清理所有注册
  Future<void> clearAllRegistrations() async {
    try {
      await _getIt.reset();
      developer.log('所有GetIt注册已清理', name: 'ServiceInjectionConfig');
    } catch (e) {
      developer.log('清理GetIt注册失败: $e',
          name: 'ServiceInjectionConfig', level: 1000);
    }
  }

  /// 获取GetIt统计信息
  Map<String, dynamic> getGetItStats() {
    try {
      final allReady = _getIt.allReadySync();
      final registeredTypes = <String>[];

      // 尝试获取已注册的类型
      if (allReady) {
        // 如果所有服务都已准备好，我们可以获取统计信息
        final instance = _getIt;
        // 使用isRegistered来检查常见的服务类型
        registeredTypes.addAll([
          if (instance.isRegistered<IUnifiedService>()) 'IUnifiedService',
          // 可以添加更多的服务类型检查
        ]);
      }

      return {
        'total_registrations': registeredTypes.length,
        'registered_types': registeredTypes,
        'all_ready': allReady,
      };
    } catch (e) {
      return {
        'total_registrations': 0,
        'registered_types': <String>[],
        'all_ready': false,
        'error': e.toString(),
      };
    }
  }

  /// 配置现有的GetIt服务
  Future<void> configureExistingServices() async {
    if (_serviceContainer == null) return;

    developer.log('开始配置现有GetIt服务', name: 'ServiceInjectionConfig');

    // 这里可以配置项目中现有的GetIt服务
    // 例如：_configureLegacyServices();

    // 暂时记录日志
    developer.log('现有GetIt服务配置完成', name: 'ServiceInjectionConfig');
  }

  /// 销毁配置
  Future<void> dispose() async {
    await clearAllRegistrations();
    _serviceContainer = null;
    developer.log('ServiceInjectionConfig已销毁', name: 'ServiceInjectionConfig');
  }
}

/// 服务注入辅助类
///
/// 提供便捷的服务注入和获取方法
class ServiceInjector {
  static final ServiceInjectionConfig _config = ServiceInjectionConfig();

  /// 初始化服务注入
  static Future<void> initialize(
      UnifiedServiceContainer serviceContainer) async {
    await _config.initialize(serviceContainer);
  }

  /// 获取服务（从ServiceContainer）
  static T getService<T extends IUnifiedService>() {
    return GetIt.instance<T>();
  }

  /// 获取服务（从GetIt，支持实例名）
  static T getServiceByName<T extends Object>({String? instanceName}) {
    return _config.getFromGetIt<T>(instanceName: instanceName);
  }

  /// 检查服务是否已注册
  static bool isServiceRegistered<T extends Object>({String? instanceName}) {
    return _config.isRegisteredInGetIt<T>(instanceName: instanceName);
  }

  /// 获取服务容器
  static UnifiedServiceContainer? getServiceContainer() {
    return ServiceInjectionConfig()._serviceContainer;
  }

  /// 注册服务到GetIt
  static Future<void> registerToGetIt<T extends IUnifiedService>({
    bool isSingleton = true,
    String? instanceName,
  }) async {
    await _config.registerServiceToGetIt<T>(
      isSingleton: isSingleton,
      instanceName: instanceName,
    );
  }

  /// 重置所有注册
  static Future<void> reset() async {
    await _config.clearAllRegistrations();
  }
}

/// 服务注入装饰器
///
/// 用于在服务类上标记注入相关的元数据
abstract class ServiceInjectable {
  /// 服务名称
  String get serviceName;

  /// 是否为单例
  bool get isSingleton => true;

  /// 依赖的其他服务
  List<String> get dependencies => [];

  /// 服务版本
  String get version => '1.0.0';

  /// 服务描述
  String get description => '';

  /// 自定义实例名
  String get instanceName => serviceName;
}

/// 服务注入注解
class ServiceInject {
  final String? instanceName;
  final bool isSingleton;
  final List<String> dependencies;

  const ServiceInject({
    this.instanceName,
    this.isSingleton = true,
    this.dependencies = const [],
  });
}

/// 依赖注入配置构建器
class DiConfigurationBuilder {
  final List<DiServiceRegistration> _registrations = [];
  final Map<String, dynamic> _configurations = {};

  /// 添加服务注册
  DiConfigurationBuilder addService<T extends IUnifiedService>({
    bool isSingleton = true,
    String? instanceName,
    List<String> dependencies = const [],
    String version = '1.0.0',
    String description = '',
  }) {
    _registrations.add(DiServiceRegistration<T>(
      isSingleton: isSingleton,
      instanceName: instanceName,
      dependencies: dependencies,
      version: version,
      description: description,
    ));
    return this;
  }

  /// 添加配置
  DiConfigurationBuilder addConfig(String key, dynamic value) {
    _configurations[key] = value;
    return this;
  }

  /// 应用配置
  Future<void> apply(UnifiedServiceContainer container) async {
    // 应用服务注册
    for (final registration in _registrations) {
      await registration.apply(container);
    }

    // 应用配置
    for (final entry in _configurations.entries) {
      container.setConfig(entry.key, entry.value);
    }
  }
}

/// 服务注册信息
class DiServiceRegistration<T extends IUnifiedService> {
  final bool isSingleton;
  final String? instanceName;
  final List<String> dependencies;
  final String version;
  final String description;

  DiServiceRegistration({
    required this.isSingleton,
    this.instanceName,
    required this.dependencies,
    required this.version,
    required this.description,
  });

  Future<void> apply(UnifiedServiceContainer container) async {
    // 这里可以实现具体的服务注册逻辑
    // 由于类型擦除，需要使用工厂方法或其他方式
    developer.log('应用服务注册: $T', name: 'DiServiceRegistration');
  }
}
