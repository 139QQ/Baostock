import 'dart:async';
import 'dart:developer' as developer;

import 'i_unified_service.dart';
import 'service_registry.dart';
import 'service_lifecycle_manager.dart';

/// 统一服务容器
///
/// 提供完整的服务管理功能，包括：
/// - 服务注册和发现
/// - 生命周期管理
/// - 依赖注入
/// - 健康检查
/// - 监控和统计
///
/// 这是服务架构的中央协调器，负责管理所有统一服务
class UnifiedServiceContainer implements ServiceContainer {
  final ServiceRegistry _registry;
  late final ServiceLifecycleManager _lifecycleManager;
  final Map<String, dynamic> _configuration;
  bool _isInitialized = false;

  /// 创建服务容器
  UnifiedServiceContainer({
    Map<String, dynamic>? configuration,
    Duration initializationTimeout = const Duration(seconds: 30),
  })  : _registry = ServiceRegistry(),
        _configuration = configuration ?? {} {
    _lifecycleManager = ServiceLifecycleManager(
      _registry,
      initializationTimeout: initializationTimeout,
    );

    developer.log('UnifiedServiceContainer创建完成',
        name: 'UnifiedServiceContainer');
  }

  /// 初始化容器
  Future<List<String>> initialize() async {
    if (_isInitialized) {
      developer.log('容器已初始化，跳过重复初始化', name: 'UnifiedServiceContainer');
      return _registry.getRegisteredServiceNames();
    }

    developer.log('开始初始化服务容器', name: 'UnifiedServiceContainer');

    try {
      final initializedServices =
          await _lifecycleManager.initializeAllServices();
      _isInitialized = true;

      developer.log('服务容器初始化完成，初始化了 ${initializedServices.length} 个服务',
          name: 'UnifiedServiceContainer');

      return initializedServices;
    } catch (e) {
      developer.log('服务容器初始化失败: $e',
          name: 'UnifiedServiceContainer', level: 1000);
      rethrow;
    }
  }

  /// 销毁容器
  Future<void> dispose() async {
    if (!_isInitialized) {
      return;
    }

    developer.log('开始销毁服务容器', name: 'UnifiedServiceContainer');

    try {
      await _lifecycleManager.disposeAllServices();
      await _registry.dispose();
      _lifecycleManager.dispose();
      _isInitialized = false;

      developer.log('服务容器销毁完成', name: 'UnifiedServiceContainer');
    } catch (e) {
      developer.log('服务容器销毁失败: $e',
          name: 'UnifiedServiceContainer', level: 1000);
    }
  }

  /// 注册服务实例
  @override
  Future<void> registerService<T extends IUnifiedService>(T service) async {
    if (_isInitialized) {
      throw StateError('容器已初始化，无法注册新服务');
    }

    await _registry.registerService(service);
  }

  /// 获取服务实例（类型安全）
  @override
  T getService<T extends IUnifiedService>() {
    _ensureInitialized();
    return _registry.getService<T>();
  }

  /// 获取服务实例（按名称）
  @override
  IUnifiedService? getServiceByName(String serviceName) {
    _ensureInitialized();
    return _registry.getServiceByName(serviceName);
  }

  /// 检查服务是否已注册
  @override
  bool isRegistered<T extends IUnifiedService>() {
    return _registry.isRegistered<T>();
  }

  /// 检查服务名称是否已注册
  bool isRegisteredByName(String serviceName) {
    return _registry.isRegisteredByName(serviceName);
  }

  /// 获取所有已注册的服务名称
  @override
  List<String> getRegisteredServiceNames() {
    return _registry.getRegisteredServiceNames();
  }

  /// 获取服务状态
  ServiceLifecycleState getServiceState(String serviceName) {
    return _lifecycleManager.getServiceState(serviceName);
  }

  /// 获取所有服务状态
  Map<String, ServiceLifecycleState> getAllServiceStates() {
    return _lifecycleManager.getAllServiceStates();
  }

  /// 检查所有服务是否都已初始化
  bool allServicesInitialized() {
    return _lifecycleManager.allServicesInitialized();
  }

  /// 获取健康状态报告
  Future<Map<String, ServiceHealthStatus>> getHealthReport() async {
    return _lifecycleManager.getHealthReport();
  }

  /// 获取容器统计信息
  Map<String, dynamic> getContainerStats() {
    final registryStats = _registry.getStats();
    final serviceStates = _lifecycleManager.getAllServiceStates();

    return {
      'container_initialized': _isInitialized,
      'total_services': registryStats['total_services'],
      'initialized_services': serviceStates.values
          .where((state) => state == ServiceLifecycleState.initialized)
          .length,
      'failed_services': serviceStates.values
          .where((state) => state == ServiceLifecycleState.error)
          .length,
      'registry_stats': registryStats,
      'configuration': Map.from(_configuration),
    };
  }

  /// 获取服务元数据
  ServiceMetadata? getServiceMetadata(String serviceName) {
    return _registry.getServiceMetadata(serviceName);
  }

  /// 获取所有服务元数据
  Map<String, ServiceMetadata> getAllServiceMetadata() {
    return _registry.getAllServiceMetadata();
  }

  /// 监听服务生命周期事件
  Stream<ServiceLifecycleEvent> get lifecycleEvents =>
      _lifecycleManager.lifecycleEvents;

  /// 重启服务
  Future<void> restartService(String serviceName) async {
    _ensureInitialized();

    final service = _registry.getServiceByName(serviceName);
    if (service == null) {
      throw ServiceDependencyException('', serviceName, '服务未找到');
    }

    developer.log('重启服务: $serviceName', name: 'UnifiedServiceContainer');

    try {
      // 销毁服务
      await service.dispose();

      // 重新初始化服务
      await service.initialize(this);

      developer.log('服务重启成功: $serviceName', name: 'UnifiedServiceContainer');
    } catch (e) {
      developer.log('服务重启失败: $serviceName, 错误: $e',
          name: 'UnifiedServiceContainer', level: 1000);
      rethrow;
    }
  }

  /// 重启所有服务
  Future<List<String>> restartAllServices() async {
    _ensureInitialized();

    developer.log('重启所有服务', name: 'UnifiedServiceContainer');

    await _lifecycleManager.disposeAllServices();
    return _lifecycleManager.initializeAllServices();
  }

  /// 验证服务配置
  Future<List<String>> validateConfiguration() async {
    final errors = <String>[];

    // 检查循环依赖
    final dependencyResolver = ServiceDependencyResolver(_registry);
    try {
      for (final serviceName in _registry.getRegisteredServiceNames()) {
        dependencyResolver.resolveDependencyChain(serviceName);
      }
    } catch (e) {
      errors.add('依赖关系验证失败: $e');
    }

    // 检查缺失的依赖
    final dependencyErrors = dependencyResolver.validateAllDependencies();
    errors.addAll(dependencyErrors);

    // 检查配置完整性
    final requiredConfigurations = _getRequiredConfigurations();
    for (final configKey in requiredConfigurations) {
      if (!_configuration.containsKey(configKey)) {
        errors.add('缺少必需配置: $configKey');
      }
    }

    return errors;
  }

  /// 获取必需的配置键
  List<String> _getRequiredConfigurations() {
    // 根据已注册的服务确定必需的配置
    final requiredConfigs = <String>{};

    for (final serviceName in _registry.getRegisteredServiceNames()) {
      switch (serviceName) {
        case 'UnifiedPerformanceService':
          requiredConfigs
              .addAll(['performance_monitoring_enabled', 'memory_limit_mb']);
          break;
        case 'UnifiedDataService':
          requiredConfigs.addAll(['cache_size_mb', 'data_retention_days']);
          break;
        case 'UnifiedNetworkService':
          requiredConfigs
              .addAll(['api_base_url', 'connection_timeout_seconds']);
          break;
        // 其他服务的配置要求...
      }
    }

    return requiredConfigs.toList();
  }

  /// 确保容器已初始化
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('服务容器未初始化，请先调用 initialize()');
    }
  }

  /// 获取配置值
  T? getConfig<T>(String key, [T? defaultValue]) {
    return _configuration[key] as T? ?? defaultValue;
  }

  /// 设置配置值
  void setConfig<T>(String key, T value) {
    _configuration[key] = value;
    developer.log('配置更新: $key = $value', name: 'UnifiedServiceContainer');
  }

  /// 获取所有配置
  Map<String, dynamic> getAllConfig() {
    return Map.unmodifiable(_configuration);
  }

  /// 从配置文件加载配置
  Future<void> loadConfigurationFromFile(String filePath) async {
    // 这里可以实现从文件加载配置的逻辑
    // 例如从JSON、YAML等格式的配置文件
    developer.log('从文件加载配置: $filePath', name: 'UnifiedServiceContainer');
    // 实现略...
  }

  /// 导出当前配置到文件
  Future<void> exportConfigurationToFile(String filePath) async {
    // 这里可以实现导出配置到文件的逻辑
    developer.log('导出配置到文件: $filePath', name: 'UnifiedServiceContainer');
    // 实现略...
  }
}

/// 服务容器构建器
///
/// 提供流式API来构建和配置服务容器
class ServiceContainerBuilder {
  final Map<String, dynamic> _configuration = {};
  Duration? _initializationTimeout;

  /// 设置配置
  ServiceContainerBuilder withConfig(String key, dynamic value) {
    _configuration[key] = value;
    return this;
  }

  /// 批量设置配置
  ServiceContainerBuilder withConfigs(Map<String, dynamic> configs) {
    _configuration.addAll(configs);
    return this;
  }

  /// 设置初始化超时
  ServiceContainerBuilder withInitializationTimeout(Duration timeout) {
    _initializationTimeout = timeout;
    return this;
  }

  /// 构建容器
  Future<UnifiedServiceContainer> build() async {
    final container = UnifiedServiceContainer(
      configuration: _configuration,
      initializationTimeout:
          _initializationTimeout ?? const Duration(seconds: 30),
    );

    return container;
  }

  /// 构建并初始化容器
  Future<UnifiedServiceContainer> buildAndInitialize() async {
    final container = await build();
    await container.initialize();
    return container;
  }
}

/// 服务容器工厂
///
/// 提供预配置的容器实例
class ServiceContainerFactory {
  /// 创建开发环境容器
  static Future<UnifiedServiceContainer> createDevelopmentContainer({
    Map<String, dynamic>? additionalConfig,
  }) async {
    return ServiceContainerBuilder()
        .withConfigs({
          'environment': 'development',
          'debug_mode': true,
          'log_level': 'debug',
          ...?additionalConfig,
        })
        .withInitializationTimeout(const Duration(seconds: 60))
        .buildAndInitialize();
  }

  /// 创建生产环境容器
  static Future<UnifiedServiceContainer> createProductionContainer({
    Map<String, dynamic>? additionalConfig,
  }) async {
    return ServiceContainerBuilder()
        .withConfigs({
          'environment': 'production',
          'debug_mode': false,
          'log_level': 'info',
          ...?additionalConfig,
        })
        .withInitializationTimeout(const Duration(seconds: 30))
        .buildAndInitialize();
  }

  /// 创建测试环境容器
  static Future<UnifiedServiceContainer> createTestContainer({
    Map<String, dynamic>? additionalConfig,
  }) async {
    return ServiceContainerBuilder()
        .withConfigs({
          'environment': 'test',
          'debug_mode': true,
          'log_level': 'debug',
          'mock_services': true,
          ...?additionalConfig,
        })
        .withInitializationTimeout(const Duration(seconds: 10))
        .buildAndInitialize();
  }
}
