import 'dart:io';

/// 应用环境枚举
enum AppEnvironment {
  /// 开发环境
  development,

  /// 测试环境
  testing,

  /// 预发布环境
  staging,

  /// 生产环境
  production,
}

/// 环境配置接口
///
/// 定义了获取环境配置信息的基本接口
abstract class IEnvironmentConfig {
  /// 当前环境
  AppEnvironment get environment;

  /// 环境名称
  String get environmentName;

  /// 环境变量映射
  Map<String, dynamic> get variables;

  /// 获取指定类型的环境变量
  T? getVariable<T>(String key);

  /// 是否为开发环境
  bool get isDevelopment;

  /// 是否为测试环境
  bool get isTesting;

  /// 是否为预发布环境
  bool get isStaging;

  /// 是否为生产环境
  bool get isProduction;
}

/// 环境配置实现
///
/// 提供完整的环境配置管理功能，包括不同环境的默认变量配置
class EnvironmentConfig implements IEnvironmentConfig {
  /// 创建开发环境配置
  ///
  /// 包含开发环境的默认变量，如本地API、详细日志等
  /// [additionalVariables] 额外的环境变量
  factory EnvironmentConfig.development(
      {Map<String, dynamic>? additionalVariables}) {
    final variables = _getDevelopmentVariables();
    variables.addAll(additionalVariables ?? {});
    return EnvironmentConfig._(
      environment: AppEnvironment.development,
      variables: variables,
    );
  }

  /// 创建测试环境配置
  ///
  /// 包含测试环境的默认变量，如测试API、基础监控等
  /// [additionalVariables] 额外的环境变量
  factory EnvironmentConfig.testing(
      {Map<String, dynamic>? additionalVariables}) {
    final variables = _getTestingVariables();
    variables.addAll(additionalVariables ?? {});
    return EnvironmentConfig._(
      environment: AppEnvironment.testing,
      variables: variables,
    );
  }

  /// 创建预发布环境配置
  ///
  /// 包含预发布环境的默认变量，如预发布API、性能监控等
  /// [additionalVariables] 额外的环境变量
  factory EnvironmentConfig.staging(
      {Map<String, dynamic>? additionalVariables}) {
    final variables = _getStagingVariables();
    variables.addAll(additionalVariables ?? {});
    return EnvironmentConfig._(
      environment: AppEnvironment.staging,
      variables: variables,
    );
  }

  /// 创建生产环境配置
  ///
  /// 包含生产环境的默认变量，如生产API、警告级别日志等
  /// [additionalVariables] 额外的环境变量
  factory EnvironmentConfig.production(
      {Map<String, dynamic>? additionalVariables}) {
    final variables = _getProductionVariables();
    variables.addAll(additionalVariables ?? {});
    return EnvironmentConfig._(
      environment: AppEnvironment.production,
      variables: variables,
    );
  }

  /// 从环境变量创建配置
  ///
  /// 优先使用指定的环境名称，其次读取系统环境变量 FLUTTER_ENV
  /// [environmentName] 环境名称
  factory EnvironmentConfig.fromEnvironment({String? environmentName}) {
    final envName =
        environmentName ?? Platform.environment['FLUTTER_ENV'] ?? 'development';

    switch (envName.toLowerCase()) {
      case 'production':
      case 'prod':
        return EnvironmentConfig.production();
      case 'staging':
      case 'stage':
        return EnvironmentConfig.staging();
      case 'testing':
      case 'test':
        return EnvironmentConfig.testing();
      case 'development':
      case 'dev':
      default:
        return EnvironmentConfig.development();
    }
  }

  EnvironmentConfig._({
    required AppEnvironment environment,
    required Map<String, dynamic> variables,
  })  : _environment = environment,
        _variables = Map.unmodifiable(variables);

  /// 当前环境
  final AppEnvironment _environment;

  /// 环境变量映射
  final Map<String, dynamic> _variables;

  @override
  AppEnvironment get environment => _environment;

  @override
  String get environmentName => _environment.name;

  @override
  Map<String, dynamic> get variables => _variables;

  @override
  T? getVariable<T>(String key) {
    return _variables[key] as T?;
  }

  @override
  bool get isDevelopment => _environment == AppEnvironment.development;

  @override
  bool get isTesting => _environment == AppEnvironment.testing;

  @override
  bool get isStaging => _environment == AppEnvironment.staging;

  @override
  bool get isProduction => _environment == AppEnvironment.production;

  /// 开发环境默认变量
  static Map<String, dynamic> _getDevelopmentVariables() {
    return {
      // API配置
      'api_base_url': 'http://localhost:8080',
      'api_timeout': 30,
      'api_connect_timeout': 30,
      'api_receive_timeout': 120,
      'api_send_timeout': 30,

      // 缓存配置
      'cache_enabled': true,
      'cache_max_size': 100 * 1024 * 1024, // 100MB
      'cache_ttl': 3600, // 1小时
      'cache_cleanup_interval': 1800, // 30分钟

      // 日志配置
      'log_level': 'debug',
      'log_to_console': true,
      'log_to_file': true,
      'log_file_path': 'logs/app.log',

      // 性能配置
      'performance_monitoring_enabled': true,
      'memory_monitoring_enabled': true,
      'cache_monitoring_enabled': true,

      // 功能开关
      'feature_analytics_enabled': false,
      'feature_crash_reporting_enabled': false,
      'feature_remote_config_enabled': false,

      // 调试配置
      'debug_mode': true,
      'debug_network_logging': true,
      'debug_cache_logging': true,

      // 数据库配置
      'hive_enabled': true,
      'hive_path': 'hive_data',
      'sql_server_enabled': false,

      // 安全配置
      'security_encryption_enabled': false,
      'security_ssl_verification': false,
    };
  }

  /// 测试环境默认变量
  static Map<String, dynamic> _getTestingVariables() {
    return {
      // API配置
      'api_base_url': 'http://test-api.example.com',
      'api_timeout': 10,
      'api_connect_timeout': 5,
      'api_receive_timeout': 30,
      'api_send_timeout': 10,

      // 缓存配置
      'cache_enabled': true,
      'cache_max_size': 50 * 1024 * 1024, // 50MB
      'cache_ttl': 300, // 5分钟
      'cache_cleanup_interval': 600, // 10分钟

      // 日志配置
      'log_level': 'info',
      'log_to_console': true,
      'log_to_file': false,

      // 性能配置
      'performance_monitoring_enabled': true,
      'memory_monitoring_enabled': true,
      'cache_monitoring_enabled': true,

      // 功能开关
      'feature_analytics_enabled': false,
      'feature_crash_reporting_enabled': false,
      'feature_remote_config_enabled': false,

      // 调试配置
      'debug_mode': true,
      'debug_network_logging': true,
      'debug_cache_logging': false,

      // 数据库配置
      'hive_enabled': true,
      'hive_path': 'test_hive_data',
      'sql_server_enabled': false,

      // 安全配置
      'security_encryption_enabled': true,
      'security_ssl_verification': true,
    };
  }

  /// 预发布环境默认变量
  static Map<String, dynamic> _getStagingVariables() {
    return {
      // API配置
      'api_base_url': 'https://staging-api.example.com',
      'api_timeout': 20,
      'api_connect_timeout': 15,
      'api_receive_timeout': 60,
      'api_send_timeout': 15,

      // 缓存配置
      'cache_enabled': true,
      'cache_max_size': 200 * 1024 * 1024, // 200MB
      'cache_ttl': 1800, // 30分钟
      'cache_cleanup_interval': 900, // 15分钟

      // 日志配置
      'log_level': 'info',
      'log_to_console': false,
      'log_to_file': true,
      'log_file_path': 'logs/staging.log',

      // 性能配置
      'performance_monitoring_enabled': true,
      'memory_monitoring_enabled': true,
      'cache_monitoring_enabled': true,

      // 功能开关
      'feature_analytics_enabled': true,
      'feature_crash_reporting_enabled': true,
      'feature_remote_config_enabled': true,

      // 调试配置
      'debug_mode': false,
      'debug_network_logging': false,
      'debug_cache_logging': false,

      // 数据库配置
      'hive_enabled': true,
      'hive_path': 'staging_hive_data',
      'sql_server_enabled': true,
      'sql_server_connection_string': 'staging_connection_string',

      // 安全配置
      'security_encryption_enabled': true,
      'security_ssl_verification': true,
    };
  }

  /// 生产环境默认变量
  static Map<String, dynamic> _getProductionVariables() {
    return {
      // API配置
      'api_base_url': 'http://154.44.25.92:8080',
      'api_timeout': 30,
      'api_connect_timeout': 15,
      'api_receive_timeout': 120,
      'api_send_timeout': 30,

      // 缓存配置
      'cache_enabled': true,
      'cache_max_size': 500 * 1024 * 1024, // 500MB
      'cache_ttl': 7200, // 2小时
      'cache_cleanup_interval': 3600, // 1小时

      // 日志配置
      'log_level': 'warning',
      'log_to_console': false,
      'log_to_file': true,
      'log_file_path': 'logs/production.log',

      // 性能配置
      'performance_monitoring_enabled': true,
      'memory_monitoring_enabled': true,
      'cache_monitoring_enabled': false, // 生产环境关闭详细缓存监控

      // 功能开关
      'feature_analytics_enabled': true,
      'feature_crash_reporting_enabled': true,
      'feature_remote_config_enabled': true,

      // 调试配置
      'debug_mode': false,
      'debug_network_logging': false,
      'debug_cache_logging': false,

      // 数据库配置
      'hive_enabled': true,
      'hive_path': 'hive_data',
      'sql_server_enabled': true,
      'sql_server_connection_string': 'production_connection_string',

      // 安全配置
      'security_encryption_enabled': true,
      'security_ssl_verification': true,
    };
  }

  /// 复制配置并添加/覆盖变量
  EnvironmentConfig copyWith({
    AppEnvironment? environment,
    Map<String, dynamic>? additionalVariables,
    Map<String, dynamic>? overrideVariables,
  }) {
    final newEnvironment = environment ?? _environment;
    final newVariables = Map<String, dynamic>.from(_variables);

    if (additionalVariables != null) {
      newVariables.addAll(additionalVariables);
    }

    if (overrideVariables != null) {
      overrideVariables.forEach((key, value) {
        newVariables[key] = value;
      });
    }

    return EnvironmentConfig._(
      environment: newEnvironment,
      variables: newVariables,
    );
  }

  @override
  String toString() {
    return 'EnvironmentConfig(environment: $environmentName, variables: ${_variables.keys.length})';
  }
}

/// 环境配置管理器
class EnvironmentConfigManager {
  static EnvironmentConfig? _currentConfig;

  /// 获取当前环境配置
  static EnvironmentConfig get current {
    if (_currentConfig == null) {
      throw StateError(
          'Environment config not initialized. Call initialize() first.');
    }
    return _currentConfig!;
  }

  /// 初始化环境配置
  static void initialize({
    AppEnvironment? environment,
    String? environmentName,
    Map<String, dynamic>? additionalVariables,
  }) {
    if (environment != null) {
      _currentConfig =
          _createConfigForEnvironment(environment, additionalVariables);
    } else {
      _currentConfig = EnvironmentConfig.fromEnvironment(
        environmentName: environmentName,
      );

      if (additionalVariables != null) {
        _currentConfig = _currentConfig!.copyWith(
          additionalVariables: additionalVariables,
        );
      }
    }
  }

  /// 重新初始化环境配置
  static void reinitialize({
    AppEnvironment? environment,
    String? environmentName,
    Map<String, dynamic>? additionalVariables,
  }) {
    _currentConfig = null;
    initialize(
      environment: environment,
      environmentName: environmentName,
      additionalVariables: additionalVariables,
    );
  }

  /// 创建指定环境的配置
  static EnvironmentConfig _createConfigForEnvironment(
    AppEnvironment environment,
    Map<String, dynamic>? additionalVariables,
  ) {
    switch (environment) {
      case AppEnvironment.development:
        return EnvironmentConfig.development(
            additionalVariables: additionalVariables);
      case AppEnvironment.testing:
        return EnvironmentConfig.testing(
            additionalVariables: additionalVariables);
      case AppEnvironment.staging:
        return EnvironmentConfig.staging(
            additionalVariables: additionalVariables);
      case AppEnvironment.production:
        return EnvironmentConfig.production(
            additionalVariables: additionalVariables);
    }
  }

  /// 重置环境配置
  static void reset() {
    _currentConfig = null;
  }

  /// 检查是否已初始化
  static bool get isInitialized => _currentConfig != null;
}
