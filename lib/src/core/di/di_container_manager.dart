// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:get_it/get_it.dart';
import '../utils/logger.dart';

/// 服务生命周期枚举
enum ServiceLifetime {
  /// 单例模式 - 整个应用生命周期内只创建一次
  singleton,

  /// 懒加载单例 - 首次使用时创建，之后复用
  lazySingleton,

  /// 每次请求都创建新实例
  factory,

  /// 异步单例 - 异步初始化的单例
  asyncSingleton,
}

/// 服务注册配置
class ServiceRegistration {
  final String name;
  final ServiceLifetime lifetime;
  final Type implementationType;
  final Type? interfaceType;
  final bool asyncInitialization;
  final Function()? factory;
  final Future<void> Function(DIContainerManager)? registrationFunction;

  const ServiceRegistration({
    required this.name,
    required this.lifetime,
    required this.implementationType,
    this.interfaceType,
    this.asyncInitialization = false,
    this.factory,
    this.registrationFunction,
  });

  /// 创建单例服务注册
  factory ServiceRegistration.singleton({
    required String name,
    required Type implementationType,
    Type? interfaceType,
    Function()? factory,
  }) {
    return ServiceRegistration(
      name: name,
      lifetime: ServiceLifetime.singleton,
      implementationType: implementationType,
      interfaceType: interfaceType,
      factory: factory,
    );
  }

  /// 创建懒加载单例服务注册
  factory ServiceRegistration.lazySingleton({
    required String name,
    required Type implementationType,
    Type? interfaceType,
    bool asyncInitialization = false,
    Function()? factory,
  }) {
    return ServiceRegistration(
      name: name,
      lifetime: ServiceLifetime.lazySingleton,
      implementationType: implementationType,
      interfaceType: interfaceType,
      asyncInitialization: asyncInitialization,
      factory: factory,
    );
  }

  /// 创建工厂服务注册
  factory ServiceRegistration.factory({
    required String name,
    required Type implementationType,
    Type? interfaceType,
    Function()? factory,
  }) {
    return ServiceRegistration(
      name: name,
      lifetime: ServiceLifetime.factory,
      implementationType: implementationType,
      interfaceType: interfaceType,
      factory: factory,
    );
  }

  /// 创建异步单例服务注册
  factory ServiceRegistration.asyncSingleton({
    required String name,
    required Type implementationType,
    Type? interfaceType,
    Function()? factory,
  }) {
    return ServiceRegistration(
      name: name,
      lifetime: ServiceLifetime.asyncSingleton,
      implementationType: implementationType,
      interfaceType: interfaceType,
      asyncInitialization: true,
      factory: factory,
    );
  }
}

/// 服务注册异常
class ServiceRegistrationException implements Exception {
  final String message;
  final String? serviceName;

  const ServiceRegistrationException(this.message, [this.serviceName]);

  @override
  String toString() {
    if (serviceName != null) {
      return 'ServiceRegistrationException: $message (Service: $serviceName)';
    }
    return 'ServiceRegistrationException: $message';
  }
}

/// 依赖注入容器配置
class DIContainerConfig {
  final Map<String, dynamic> environmentVariables;
  final String environment;

  const DIContainerConfig({
    required this.environmentVariables,
    required this.environment,
  });

  /// 从配置创建容器配置
  factory DIContainerConfig.fromConfig({
    required String environment,
    Map<String, dynamic>? environmentVariables,
  }) {
    return DIContainerConfig(
      environment: environment,
      environmentVariables: environmentVariables ?? {},
    );
  }

  /// 获取环境变量
  T? getEnvironmentVariable<T>(String key) {
    return environmentVariables[key] as T?;
  }

  /// 是否为开发环境
  bool get isDevelopment => environment == 'development';

  /// 是否为测试环境
  bool get isTesting => environment == 'testing';

  /// 是否为生产环境
  bool get isProduction => environment == 'production';
}

/// 依赖注入容器管理器
class DIContainerManager {
  final GetIt _getIt;
  DIContainerConfig? _config;
  final Map<String, String> _registeredServices = {};
  final Set<String> _initializingServices = {};

  DIContainerManager({GetIt? getIt}) : _getIt = getIt ?? GetIt.instance;

  /// 获取GetIt实例
  GetIt get getIt => _getIt;

  /// 配置容器
  Future<void> configure(DIContainerConfig config) async {
    _config = config;
    AppLogger.info(
        'DI Container configured for environment: ${config.environment}');
  }

  /// 获取当前配置
  DIContainerConfig? get currentConfig => _config;

  /// 注册服务实例（单例）
  void registerSingletonInstance<T extends Object>(T instance, {String? name}) {
    final serviceName = name ?? T.toString();

    if (_registeredServices.containsKey(serviceName)) {
      AppLogger.debug('Service $serviceName already registered, skipping...');
      return;
    }

    try {
      _getIt.registerSingleton<T>(instance);
      _registeredServices[serviceName] = 'singleton';
      AppLogger.debug('Registered singleton instance: $serviceName');
    } catch (e) {
      throw ServiceRegistrationException(
        'Failed to register singleton $serviceName: $e',
        serviceName,
      );
    }
  }

  /// 注册懒加载单例工厂
  void registerLazySingleton<T extends Object>(
    T Function() factory, {
    String? name,
  }) {
    final serviceName = name ?? T.toString();

    if (_registeredServices.containsKey(serviceName)) {
      AppLogger.debug('Service $serviceName already registered, skipping...');
      return;
    }

    try {
      _getIt.registerLazySingleton<T>(factory);
      _registeredServices[serviceName] = 'lazySingleton';
      AppLogger.debug('Registered lazy singleton: $serviceName');
    } catch (e) {
      throw ServiceRegistrationException(
        'Failed to register lazy singleton $serviceName: $e',
        serviceName,
      );
    }
  }

  /// 注册工厂服务
  void registerFactory<T extends Object>(
    T Function() factory, {
    String? name,
  }) {
    final serviceName = name ?? T.toString();

    if (_registeredServices.containsKey(serviceName)) {
      AppLogger.debug('Service $serviceName already registered, skipping...');
      return;
    }

    try {
      _getIt.registerFactory<T>(factory);
      _registeredServices[serviceName] = 'factory';
      AppLogger.debug('Registered factory: $serviceName');
    } catch (e) {
      throw ServiceRegistrationException(
        'Failed to register factory $serviceName: $e',
        serviceName,
      );
    }
  }

  /// 注册异步单例服务
  Future<void> registerAsyncSingleton<T extends Object>(
    Future<T> Function() factory, {
    String? name,
  }) async {
    final serviceName = name ?? T.toString();

    if (_registeredServices.containsKey(serviceName)) {
      AppLogger.debug('Service $serviceName already registered, skipping...');
      return;
    }

    try {
      _getIt.registerSingletonAsync<T>(factory);
      _registeredServices[serviceName] = 'asyncSingleton';
      AppLogger.debug('Registered async singleton: $serviceName');
    } catch (e) {
      throw ServiceRegistrationException(
        'Failed to register async singleton $serviceName: $e',
        serviceName,
      );
    }
  }

  /// 获取服务
  T get<T extends Object>() {
    try {
      return _getIt.get<T>();
    } catch (e) {
      AppLogger.error('Failed to get service ${T.toString()}: $e', e);
      rethrow;
    }
  }

  /// 异步获取服务
  Future<T> getAsync<T extends Object>() async {
    try {
      return await _getIt.getAsync<T>();
    } catch (e) {
      AppLogger.error('Failed to get async service ${T.toString()}: $e', e);
      rethrow;
    }
  }

  /// 检查服务是否已注册
  bool isRegistered<T extends Object>() {
    return _getIt.isRegistered<T>();
  }

  /// 检查服务名称是否已注册
  bool isServiceNameRegistered(String name) {
    return _registeredServices.containsKey(name);
  }

  /// 获取服务注册类型
  String? getServiceRegistrationType(String name) {
    return _registeredServices[name];
  }

  /// 获取服务注册信息（兼容性方法）
  ServiceRegistration? getServiceRegistration(String name) {
    if (!_registeredServices.containsKey(name)) {
      return null;
    }

    // 根据注册类型创建基本的 ServiceRegistration
    final type = _registeredServices[name];
    ServiceLifetime lifetime;

    switch (type) {
      case 'singleton':
        lifetime = ServiceLifetime.singleton;
        break;
      case 'lazySingleton':
        lifetime = ServiceLifetime.lazySingleton;
        break;
      case 'factory':
        lifetime = ServiceLifetime.factory;
        break;
      case 'asyncSingleton':
        lifetime = ServiceLifetime.asyncSingleton;
        break;
      default:
        lifetime = ServiceLifetime.lazySingleton;
    }

    return ServiceRegistration(
      name: name,
      lifetime: lifetime,
      implementationType: dynamic, // 无法确定具体类型
    );
  }

  /// 重置容器（主要用于测试）
  Future<void> reset() async {
    try {
      await _getIt.reset();
      _registeredServices.clear();
      _initializingServices.clear();
      _config = null;
      AppLogger.info('DI Container reset completed');
    } catch (e) {
      AppLogger.error('Failed to reset DI container: $e', e);
      rethrow;
    }
  }

  /// 获取已注册服务数量
  int get registeredServicesCount => _registeredServices.length;

  /// 获取服务注册信息
  Map<String, String> get registeredServices =>
      Map.unmodifiable(_registeredServices);

  /// 获取所有已注册的服务名称
  List<String> get registeredServiceNames => _registeredServices.keys.toList();

  /// 检查容器是否已配置
  bool get isConfigured => _config != null;

  /// 获取当前环境
  String get currentEnvironment => _config?.environment ?? 'unknown';

  /// 是否为开发环境
  bool get isDevelopment => _config?.isDevelopment ?? false;

  /// 是否为测试环境
  bool get isTesting => _config?.isTesting ?? false;

  /// 是否为生产环境
  bool get isProduction => _config?.isProduction ?? false;

  /// 便捷方法：按名称获取服务（需要类型转换）
  T getByName<T extends Object>(String name) {
    if (!_registeredServices.containsKey(name)) {
      throw ServiceRegistrationException(
        'Service not found: $name',
        name,
      );
    }

    try {
      return _getIt.get<T>();
    } catch (e) {
      throw ServiceRegistrationException(
        'Failed to get service by name $name: $e',
        name,
      );
    }
  }

  /// 注册服务
  Future<void> registerService(ServiceRegistration registration) async {
    if (_registeredServices.containsKey(registration.name)) {
      AppLogger.debug(
          'Service ${registration.name} already registered, skipping...');
      return;
    }

    try {
      // 执行自定义注册函数
      if (registration.registrationFunction != null) {
        await registration.registrationFunction!(this);
      } else {
        // 基本的注册逻辑
        _registeredServices[registration.name] = registration.lifetime.name;
        AppLogger.debug(
            'Registered service: ${registration.name} (${registration.lifetime.name})');
      }
    } catch (e) {
      throw ServiceRegistrationException(
        'Failed to register service ${registration.name}: $e',
        registration.name,
      );
    }
  }

  /// 批量注册服务
  Future<void> registerBatch(
      List<Future<void> Function()> registrations) async {
    for (final registration in registrations) {
      try {
        await registration();
      } catch (e) {
        AppLogger.error('Batch registration failed: $e', e);
        rethrow;
      }
    }
    AppLogger.info(
        'Batch registration completed: ${registrations.length} services');
  }

  /// 获取容器状态信息
  Map<String, dynamic> get containerStatus {
    return {
      'isConfigured': isConfigured,
      'environment': currentEnvironment,
      'registeredServicesCount': registeredServicesCount,
      'registeredServices': Map.from(_registeredServices),
      'isDevelopment': isDevelopment,
      'isTesting': isTesting,
      'isProduction': isProduction,
    };
  }
}

/// 全局依赖注入容器管理器实例
final DIContainerManager diContainer = DIContainerManager();
