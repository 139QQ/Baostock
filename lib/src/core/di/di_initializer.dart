import '../utils/logger.dart';
import 'di_container_manager.dart';
import 'environment_config.dart';
import 'service_registry.dart';
import 'package:get_it/get_it.dart';

/// 依赖注入初始化配置
///
/// 用于配置依赖注入系统初始化过程中的各种参数和选项
class DIInitializationConfig {
  /// 创建默认配置
  ///
  /// [environment] 目标环境，默认为开发环境
  /// [serviceRegistry] 服务注册表，默认使用完整注册表
  /// [additionalEnvironmentVariables] 额外的环境变量
  factory DIInitializationConfig.defaultConfig({
    AppEnvironment? environment,
    IServiceRegistry? serviceRegistry,
    Map<String, dynamic>? additionalEnvironmentVariables,
  }) {
    return DIInitializationConfig(
      environment: environment ?? AppEnvironment.development,
      serviceRegistry: serviceRegistry ?? DefaultServiceRegistryBuilder.build(),
      additionalEnvironmentVariables: additionalEnvironmentVariables ?? {},
    );
  }

  /// 创建开发环境配置
  ///
  /// 启用性能监控和服务验证
  /// [serviceRegistry] 服务注册表，默认使用完整注册表
  /// [additionalEnvironmentVariables] 额外的环境变量
  factory DIInitializationConfig.development({
    IServiceRegistry? serviceRegistry,
    Map<String, dynamic>? additionalEnvironmentVariables,
  }) {
    return DIInitializationConfig(
      environment: AppEnvironment.development,
      serviceRegistry: serviceRegistry ?? DefaultServiceRegistryBuilder.build(),
      additionalEnvironmentVariables: additionalEnvironmentVariables ?? {},
      enablePerformanceMonitoring: true,
      enableServiceValidation: true,
    );
  }

  /// 创建测试环境配置
  ///
  /// 关闭性能监控，启用服务验证
  /// [serviceRegistry] 服务注册表，默认使用最小化注册表
  /// [additionalEnvironmentVariables] 额外的环境变量
  factory DIInitializationConfig.testing({
    IServiceRegistry? serviceRegistry,
    Map<String, dynamic>? additionalEnvironmentVariables,
  }) {
    return DIInitializationConfig(
      environment: AppEnvironment.testing,
      serviceRegistry:
          serviceRegistry ?? DefaultServiceRegistryBuilder.buildMinimal(),
      additionalEnvironmentVariables: additionalEnvironmentVariables ?? {},
      enablePerformanceMonitoring: false,
      enableServiceValidation: true,
    );
  }

  /// 创建生产环境配置
  ///
  /// 启用性能监控，关闭服务验证以提高性能
  /// [serviceRegistry] 服务注册表，默认使用完整注册表
  /// [additionalEnvironmentVariables] 额外的环境变量
  factory DIInitializationConfig.production({
    IServiceRegistry? serviceRegistry,
    Map<String, dynamic>? additionalEnvironmentVariables,
  }) {
    return DIInitializationConfig(
      environment: AppEnvironment.production,
      serviceRegistry: serviceRegistry ?? DefaultServiceRegistryBuilder.build(),
      additionalEnvironmentVariables: additionalEnvironmentVariables ?? {},
      enablePerformanceMonitoring: true,
      enableServiceValidation: false, // 生产环境关闭验证以提高性能
    );
  }

  /// 创建依赖注入初始化配置
  ///
  /// [environment] 目标环境
  /// [serviceRegistry] 服务注册表
  /// [additionalEnvironmentVariables] 额外的环境变量
  /// [enablePerformanceMonitoring] 是否启用性能监控，默认true
  /// [enableServiceValidation] 是否启用服务验证，默认true
  /// [initializationTimeout] 初始化超时时间，默认30秒
  const DIInitializationConfig({
    required this.environment,
    required this.serviceRegistry,
    this.additionalEnvironmentVariables = const {},
    this.enablePerformanceMonitoring = true,
    this.enableServiceValidation = true,
    this.initializationTimeout = const Duration(seconds: 30),
  });

  /// 目标环境
  final AppEnvironment environment;

  /// 服务注册表
  final IServiceRegistry serviceRegistry;

  /// 额外的环境变量
  final Map<String, dynamic> additionalEnvironmentVariables;

  /// 是否启用性能监控
  final bool enablePerformanceMonitoring;

  /// 是否启用服务验证
  final bool enableServiceValidation;

  /// 初始化超时时间
  final Duration initializationTimeout;
}

/// 依赖注入初始化结果
///
/// 包含初始化过程中的状态信息、性能指标和警告信息
class DIInitializationResult {
  /// 创建依赖注入初始化结果
  ///
  /// [success] 初始化是否成功
  /// [error] 错误信息（如果初始化失败）
  /// [initializationTime] 初始化耗时
  /// [registeredServicesCount] 注册的服务数量
  /// [warnings] 警告信息列表
  /// [metrics] 初始化指标数据
  const DIInitializationResult({
    required this.success,
    this.error,
    required this.initializationTime,
    required this.registeredServicesCount,
    this.warnings = const [],
    this.metrics = const {},
  });

  /// 初始化是否成功
  final bool success;

  /// 错误信息（如果初始化失败）
  final String? error;

  /// 初始化耗时
  final Duration initializationTime;

  /// 注册的服务数量
  final int registeredServicesCount;

  /// 警告信息列表
  final List<String> warnings;

  /// 初始化指标数据
  final Map<String, dynamic> metrics;

  @override
  String toString() {
    if (success) {
      return 'DIInitializationResult: SUCCESS (${initializationTime.inMilliseconds}ms, $registeredServicesCount services)';
    } else {
      return 'DIInitializationResult: FAILED - $error';
    }
  }
}

/// 依赖注入初始化器
class DIInitializer {
  static DIContainerManager? _containerManager;
  static EnvironmentConfig? _environmentConfig;
  static bool _isInitialized = false;

  /// 初始化依赖注入
  static Future<DIInitializationResult> initialize({
    DIInitializationConfig? config,
    AppEnvironment? environment,
    String? environmentName,
    IServiceRegistry? serviceRegistry,
    Map<String, dynamic>? additionalEnvironmentVariables,
  }) async {
    if (_isInitialized) {
      AppLogger.warning('Dependency injection already initialized');
      return DIInitializationResult(
        success: true,
        initializationTime: Duration.zero,
        registeredServicesCount:
            _containerManager?.registeredServicesCount ?? 0,
      );
    }

    final stopwatch = Stopwatch()..start();
    final warnings = <String>[];

    try {
      // 1. 准备配置
      final initConfig = config ??
          DIInitializationConfig.defaultConfig(
            environment: environment,
            serviceRegistry: serviceRegistry,
            additionalEnvironmentVariables: additionalEnvironmentVariables,
          );

      // 2. 初始化环境配置
      await _initializeEnvironmentConfig(initConfig, environmentName);
      warnings.addAll(_validateEnvironmentConfig(_environmentConfig!));

      // 3. 初始化容器管理器
      await _initializeContainerManager(initConfig);

      // 4. 注册服务
      final serviceWarnings = await _registerServices(initConfig);
      warnings.addAll(serviceWarnings);

      // 5. 验证服务注册
      if (initConfig.enableServiceValidation) {
        warnings.addAll(await _validateServices());
      }

      // 6. 收集指标
      final metrics = await _collectMetrics(initConfig);

      stopwatch.stop();

      _isInitialized = true;

      AppLogger.info('Dependency injection initialized successfully');
      AppLogger.info('Environment: ${_environmentConfig!.environmentName}');
      AppLogger.info(
          'Services registered: ${_containerManager!.registeredServicesCount}');
      AppLogger.info('Initialization time: ${stopwatch.elapsedMilliseconds}ms');

      return DIInitializationResult(
        success: true,
        initializationTime: stopwatch.elapsed,
        registeredServicesCount: _containerManager!.registeredServicesCount,
        warnings: warnings,
        metrics: metrics,
      );
    } catch (e, stackTrace) {
      stopwatch.stop();

      AppLogger.error(
          'Failed to initialize dependency injection', e, stackTrace);

      // 清理部分初始化的状态
      await _cleanupFailedInitialization();

      return DIInitializationResult(
        success: false,
        error: e.toString(),
        initializationTime: stopwatch.elapsed,
        registeredServicesCount: 0,
        warnings: warnings,
      );
    }
  }

  /// 重新初始化依赖注入
  static Future<DIInitializationResult> reinitialize({
    DIInitializationConfig? config,
  }) async {
    await reset();
    return await initialize(config: config);
  }

  /// 重置依赖注入
  static Future<void> reset() async {
    if (_containerManager != null) {
      await _containerManager!.reset();
      _containerManager = null;
    }

    _environmentConfig = null;
    _isInitialized = false;

    AppLogger.info('Dependency injection reset');
  }

  /// 获取容器管理器
  static DIContainerManager get containerManager {
    if (!_isInitialized || _containerManager == null) {
      throw StateError(
          'Dependency injection not initialized. Call initialize() first.');
    }
    return _containerManager!;
  }

  /// 获取环境配置
  static EnvironmentConfig get environmentConfig {
    if (!_isInitialized || _environmentConfig == null) {
      throw StateError(
          'Dependency injection not initialized. Call initialize() first.');
    }
    return _environmentConfig!;
  }

  /// 检查是否已初始化
  static bool get isInitialized => _isInitialized;

  /// 初始化环境配置
  static Future<void> _initializeEnvironmentConfig(
    DIInitializationConfig config,
    String? environmentName,
  ) async {
    EnvironmentConfigManager.reinitialize(
      environment: config.environment,
      environmentName: environmentName,
      additionalVariables: config.additionalEnvironmentVariables,
    );

    _environmentConfig = EnvironmentConfigManager.current;
  }

  /// 初始化容器管理器
  static Future<void> _initializeContainerManager(
      DIInitializationConfig config) async {
    _containerManager = DIContainerManager();

    final diConfig = DIContainerConfig.fromConfig(
      environment: config.environment.name,
      environmentVariables: _environmentConfig!.variables,
    );

    await _containerManager!.configure(diConfig);
  }

  /// 注册服务
  static Future<List<String>> _registerServices(
      DIInitializationConfig config) async {
    AppLogger.info('Registering services...');

    // 创建一个自定义的服务注册表监听器来收集错误
    final warnings = <String>[];

    // 由于我们修改了BaseServiceRegistry具有容错能力，我们需要从日志中推断是否有服务失败
    // 这是一个简化的实现，在生产环境中可能需要更复杂的错误收集机制
    // final initialServiceCount = _containerManager!.registeredServicesCount; // 暂时不使用

    await config.serviceRegistry.registerServices(_containerManager!);

    final finalServiceCount = _containerManager!.registeredServicesCount;
    final expectedServiceCount = config.serviceRegistry.getServices().length;

    if (finalServiceCount < expectedServiceCount) {
      final failedCount = expectedServiceCount - finalServiceCount;
      warnings.add(
          '$failedCount service(s) failed to register during initialization');
    }

    AppLogger.info('Services registered successfully');
    return warnings;
  }

  /// 验证环境配置
  static List<String> _validateEnvironmentConfig(
      EnvironmentConfig environmentConfig) {
    final warnings = <String>[];

    if (environmentConfig.isDevelopment) {
      final debugMode =
          environmentConfig.getVariable<bool>('debug_mode') ?? false;
      if (!debugMode) {
        warnings.add('Debug mode is disabled in development environment');
      }
    }

    if (environmentConfig.isProduction) {
      final debugMode =
          environmentConfig.getVariable<bool>('debug_mode') ?? false;
      if (debugMode) {
        warnings.add('Debug mode is enabled in production environment');
      }

      final sslVerification =
          environmentConfig.getVariable<bool>('security_ssl_verification') ??
              false;
      if (!sslVerification) {
        warnings.add('SSL verification is disabled in production environment');
      }
    }

    return warnings;
  }

  /// 验证服务注册
  static Future<List<String>> _validateServices() async {
    final warnings = <String>[];

    // 检查关键服务是否注册
    final criticalServices = [
      'unified_hive_cache_manager',
      'api_service',
      'fund_data_service',
      'security_monitor',
    ];

    for (final serviceName in criticalServices) {
      final registration =
          _containerManager!.getServiceRegistration(serviceName);
      if (registration == null) {
        warnings.add('Critical service not registered: $serviceName');
      }
    }

    // 检查服务数量合理性
    final serviceCount = _containerManager!.registeredServicesCount;
    if (serviceCount == 0) {
      warnings.add('No services registered');
    } else if (serviceCount > 200) {
      warnings.add(
          'Too many services registered ($serviceCount). Consider service consolidation.');
    }

    return warnings;
  }

  /// 收集指标
  static Future<Map<String, dynamic>> _collectMetrics(
      DIInitializationConfig config) async {
    final metrics = <String, dynamic>{
      'environment': config.environment.name,
      'service_count': _containerManager!.registeredServicesCount,
      'performance_monitoring_enabled': config.enablePerformanceMonitoring,
      'service_validation_enabled': config.enableServiceValidation,
      'initialization_timeout_seconds': config.initializationTimeout.inSeconds,
    };

    // 添加环境特定指标
    metrics.addAll(_environmentConfig!.variables);

    return metrics;
  }

  /// 清理失败的初始化
  static Future<void> _cleanupFailedInitialization() async {
    try {
      if (_containerManager != null) {
        await _containerManager!.reset();
      }
    } catch (e) {
      AppLogger.error('Failed to cleanup after initialization failure', e);
    }

    _containerManager = null;
    _environmentConfig = null;
    _isInitialized = false;
  }

  /// 获取服务（便捷方法）
  static T getService<T extends Object>() {
    return containerManager.get<T>();
  }

  /// 异步获取服务（便捷方法）
  static Future<T> getServiceAsync<T extends Object>() async {
    return await containerManager.getAsync<T>();
  }

  /// 检查服务是否已注册（便捷方法）
  static bool isServiceRegistered<T extends Object>() {
    return containerManager.isRegistered<T>();
  }

  /// 获取当前环境信息
  static Map<String, dynamic> getEnvironmentInfo() {
    if (!isInitialized) {
      return {'initialized': false};
    }

    return {
      'initialized': true,
      'environment': environmentConfig.environmentName,
      'is_development': environmentConfig.isDevelopment,
      'is_testing': environmentConfig.isTesting,
      'is_production': environmentConfig.isProduction,
      'service_count': containerManager.registeredServicesCount,
    };
  }
}

/// GetIt 服务定位器的快捷方式
///
/// 提供简化的服务访问语法，兼容原有代码
T sl<T extends Object>() {
  return DIInitializer.containerManager.get<T>();
}
