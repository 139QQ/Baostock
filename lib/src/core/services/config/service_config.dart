import 'dart:io';

/// R.3统一服务配置管理
///
/// 解决P0级别配置硬编码问题，支持环境变量和配置文件
class ServiceConfig {
  // 监控配置
  final Duration monitoringInterval;
  final Duration cleanupInterval;
  final Duration healthCheckInterval;

  // 缓存配置
  final int maxCacheSize;
  final Duration defaultCacheTtl;
  final int l1CacheMaxSize;

  // 网络配置
  final String networkEndpoint;
  final int networkPort;
  final Duration networkTimeout;
  final int maxRetryAttempts;

  // 性能配置
  final double memoryThreshold;
  final double cpuThreshold;
  final Duration performanceReportInterval;

  // 日志配置
  final bool enableDebugLogging;
  final int maxLogFileSize;
  final Duration logRetentionPeriod;

  const ServiceConfig({
    // 监控配置默认值
    this.monitoringInterval = const Duration(seconds: 5),
    this.cleanupInterval = const Duration(minutes: 10),
    this.healthCheckInterval = const Duration(minutes: 1),

    // 缓存配置默认值
    this.maxCacheSize = 1000,
    this.defaultCacheTtl = const Duration(hours: 1),
    this.l1CacheMaxSize = 100,

    // 网络配置默认值
    this.networkEndpoint = 'localhost',
    this.networkPort = 8080,
    this.networkTimeout = const Duration(seconds: 10),
    this.maxRetryAttempts = 3,

    // 性能配置默认值
    this.memoryThreshold = 0.8,
    this.cpuThreshold = 0.7,
    this.performanceReportInterval = const Duration(minutes: 5),

    // 日志配置默认值
    this.enableDebugLogging = false,
    this.maxLogFileSize = 10 * 1024 * 1024, // 10MB
    this.logRetentionPeriod = const Duration(days: 7),
  });

  /// 从环境变量创建配置
  factory ServiceConfig.fromEnvironment() {
    return ServiceConfig(
      // 监控配置
      monitoringInterval: Duration(
          seconds:
              int.parse(Platform.environment['MONITORING_INTERVAL'] ?? '5')),
      cleanupInterval: Duration(
          minutes: int.parse(Platform.environment['CLEANUP_INTERVAL'] ?? '10')),
      healthCheckInterval: Duration(
          minutes:
              int.parse(Platform.environment['HEALTH_CHECK_INTERVAL'] ?? '1')),

      // 缓存配置
      maxCacheSize: int.parse(Platform.environment['MAX_CACHE_SIZE'] ?? '1000'),
      defaultCacheTtl: Duration(
          hours: int.parse(
              Platform.environment['DEFAULT_CACHE_TTL_HOURS'] ?? '1')),
      l1CacheMaxSize:
          int.parse(Platform.environment['L1_CACHE_MAX_SIZE'] ?? '100'),

      // 网络配置
      networkEndpoint: Platform.environment['API_ENDPOINT'] ?? 'localhost',
      networkPort: int.parse(Platform.environment['API_PORT'] ?? '8080'),
      networkTimeout: Duration(
          seconds: int.parse(Platform.environment['NETWORK_TIMEOUT'] ?? '10')),
      maxRetryAttempts:
          int.parse(Platform.environment['MAX_RETRY_ATTEMPTS'] ?? '3'),

      // 性能配置
      memoryThreshold:
          double.parse(Platform.environment['MEMORY_THRESHOLD'] ?? '0.8'),
      cpuThreshold:
          double.parse(Platform.environment['CPU_THRESHOLD'] ?? '0.7'),
      performanceReportInterval: Duration(
          minutes: int.parse(
              Platform.environment['PERFORMANCE_REPORT_INTERVAL'] ?? '5')),

      // 日志配置
      enableDebugLogging:
          Platform.environment['ENABLE_DEBUG_LOGGING'] == 'true',
      maxLogFileSize: int.parse(Platform.environment['MAX_LOG_FILE_SIZE'] ??
          (10 * 1024 * 1024).toString()),
      logRetentionPeriod: Duration(
          days: int.parse(Platform.environment['LOG_RETENTION_DAYS'] ?? '7')),
    );
  }

  /// 开发环境配置
  factory ServiceConfig.development() {
    return ServiceConfig(
      monitoringInterval: const Duration(seconds: 10),
      enableDebugLogging: true,
      memoryThreshold: 0.9, // 开发环境允许更高内存使用
      networkTimeout: const Duration(seconds: 15), // 开发环境更长超时
    );
  }

  /// 生产环境配置
  factory ServiceConfig.production() {
    return ServiceConfig(
      monitoringInterval: const Duration(seconds: 5),
      enableDebugLogging: false,
      memoryThreshold: 0.75, // 生产环境更严格的内存控制
      networkTimeout: const Duration(seconds: 8), // 生产环境更快超时
      maxRetryAttempts: 5, // 生产环境更多重试
    );
  }

  /// 测试环境配置
  factory ServiceConfig.testing() {
    return ServiceConfig(
      monitoringInterval: const Duration(seconds: 1), // 测试环境快速监控
      cleanupInterval: const Duration(seconds: 30), // 测试环境频繁清理
      enableDebugLogging: true,
      maxCacheSize: 100, // 测试环境较小缓存
      networkPort: 0, // 测试环境使用随机端口
    );
  }

  /// 获取当前环境
  static String get currentEnvironment {
    return Platform.environment['ENVIRONMENT'] ?? 'development';
  }

  /// 获取当前环境的配置
  factory ServiceConfig.current() {
    final env = currentEnvironment;

    if (env == 'production') {
      return ServiceConfig.production();
    } else if (env == 'testing') {
      return ServiceConfig.testing();
    } else {
      // 优先使用环境变量配置，否则使用开发配置
      return Platform.environment.keys
              .any((key) => key.contains('MONITORING_INTERVAL'))
          ? ServiceConfig.fromEnvironment()
          : ServiceConfig.development();
    }
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'monitoring': {
        'intervalSeconds': monitoringInterval.inSeconds,
        'cleanupIntervalMinutes': cleanupInterval.inMinutes,
        'healthCheckIntervalMinutes': healthCheckInterval.inMinutes,
      },
      'cache': {
        'maxSize': maxCacheSize,
        'defaultTtlHours': defaultCacheTtl.inHours,
        'l1MaxSize': l1CacheMaxSize,
      },
      'network': {
        'endpoint': networkEndpoint,
        'port': networkPort,
        'timeoutSeconds': networkTimeout.inSeconds,
        'maxRetryAttempts': maxRetryAttempts,
      },
      'performance': {
        'memoryThreshold': memoryThreshold,
        'cpuThreshold': cpuThreshold,
        'reportIntervalMinutes': performanceReportInterval.inMinutes,
      },
      'logging': {
        'enableDebug': enableDebugLogging,
        'maxFileSizeBytes': maxLogFileSize,
        'retentionDays': logRetentionPeriod.inDays,
      },
    };
  }

  /// 从JSON创建配置
  factory ServiceConfig.fromJson(Map<String, dynamic> json) {
    final monitoring = json['monitoring'] as Map<String, dynamic>? ?? {};
    final cache = json['cache'] as Map<String, dynamic>? ?? {};
    final network = json['network'] as Map<String, dynamic>? ?? {};
    final performance = json['performance'] as Map<String, dynamic>? ?? {};
    final logging = json['logging'] as Map<String, dynamic>? ?? {};

    return ServiceConfig(
      monitoringInterval:
          Duration(seconds: monitoring['intervalSeconds'] as int? ?? 5),
      cleanupInterval:
          Duration(minutes: monitoring['cleanupIntervalMinutes'] as int? ?? 10),
      healthCheckInterval: Duration(
          minutes: monitoring['healthCheckIntervalMinutes'] as int? ?? 1),
      maxCacheSize: cache['maxSize'] as int? ?? 1000,
      defaultCacheTtl: Duration(hours: cache['defaultTtlHours'] as int? ?? 1),
      l1CacheMaxSize: cache['l1MaxSize'] as int? ?? 100,
      networkEndpoint: network['endpoint'] as String? ?? 'localhost',
      networkPort: network['port'] as int? ?? 8080,
      networkTimeout:
          Duration(seconds: network['timeoutSeconds'] as int? ?? 10),
      maxRetryAttempts: network['maxRetryAttempts'] as int? ?? 3,
      memoryThreshold:
          (performance['memoryThreshold'] as num?)?.toDouble() ?? 0.8,
      cpuThreshold: (performance['cpuThreshold'] as num?)?.toDouble() ?? 0.7,
      performanceReportInterval:
          Duration(minutes: performance['reportIntervalMinutes'] as int? ?? 5),
      enableDebugLogging: logging['enableDebug'] as bool? ?? false,
      maxLogFileSize: logging['maxFileSizeBytes'] as int? ?? 10 * 1024 * 1024,
      logRetentionPeriod: Duration(days: logging['retentionDays'] as int? ?? 7),
    );
  }

  @override
  String toString() {
    return 'ServiceConfig('
        'environment: ${currentEnvironment}, '
        'monitoringInterval: ${monitoringInterval.inSeconds}s, '
        'maxCacheSize: $maxCacheSize, '
        'networkEndpoint: $networkEndpoint:$networkPort, '
        'enableDebugLogging: $enableDebugLogging'
        ')';
  }
}
