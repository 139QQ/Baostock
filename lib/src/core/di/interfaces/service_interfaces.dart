import 'package:meta/meta.dart';

/// ==================== 基础服务接口 ====================

/// 可初始化服务接口
abstract class IInitializableService {
  /// 异步初始化服务
  Future<void> initialize();

  /// 检查服务是否已初始化
  bool get isInitialized;

  /// 服务名称
  String get serviceName;
}

/// 可配置服务接口
abstract class IConfigurableService {
  /// 配置服务
  Future<void> configure(Map<String, dynamic> config);

  /// 获取当前配置
  Map<String, dynamic> get currentConfig;

  /// 验证配置
  bool validateConfig(Map<String, dynamic> config);
}

/// 可释放资源的服务接口
abstract class IDisposableService {
  /// 释放服务资源
  Future<void> dispose();

  /// 检查服务是否已释放
  bool get isDisposed;
}

/// 健康检查服务接口
abstract class IHealthCheckService {
  /// 执行健康检查
  Future<HealthCheckResult> checkHealth();

  /// 获取服务状态
  ServiceStatus get status;
}

/// ==================== 缓存服务接口 ====================

/// 统一缓存服务接口
abstract class ICacheService {
  /// 存储数据
  Future<void> set<T>(String key, T value, {Duration? ttl});

  /// 获取数据
  Future<T?> get<T>(String key);

  /// 删除数据
  Future<void> remove(String key);

  /// 检查键是否存在
  Future<bool> containsKey(String key);

  /// 清空缓存
  Future<void> clear();

  /// 获取缓存大小
  Future<int> get size;

  /// 获取缓存统计信息
  CacheStats get stats;
}

/// 缓存统计信息
class CacheStats {
  final int hitCount;
  final int missCount;
  final int evictionCount;
  final double hitRate;
  final int currentSize;
  final int maxSize;

  const CacheStats({
    required this.hitCount,
    required this.missCount,
    required this.evictionCount,
    required this.hitRate,
    required this.currentSize,
    required this.maxSize,
  });

  @override
  String toString() {
    return 'CacheStats(hitRate: ${(hitRate * 100).toStringAsFixed(2)}%, '
        'size: $currentSize/$maxSize, '
        'hits: $hitCount, misses: $missCount)';
  }
}

/// 缓存键管理器接口
abstract class ICacheKeyManager {
  /// 生成缓存键
  String generateKey(String prefix, Map<String, dynamic>? parameters);

  /// 验证缓存键格式
  bool validateKey(String key);

  /// 获取键的命名空间
  String getKeyNamespace(String key);
}

/// ==================== 网络服务接口 ====================

/// API服务接口
abstract class IApiService {
  /// 执行GET请求
  Future<T> get<T>(String path, {Map<String, dynamic>? queryParameters});

  /// 执行POST请求
  Future<T> post<T>(String path, {dynamic data});

  /// 执行PUT请求
  Future<T> put<T>(String path, {dynamic data});

  /// 执行DELETE请求
  Future<T> delete<T>(String path);

  /// 设置请求头
  void setHeaders(Map<String, String> headers);

  /// 添加拦截器
  void addInterceptor(dynamic interceptor);
}

/// 网络监控器接口
abstract class INetworkMonitor {
  /// 开始监控
  void startMonitoring();

  /// 停止监控
  void stopMonitoring();

  /// 获取网络状态
  NetworkStatus get currentStatus;

  /// 网络状态变化流
  Stream<NetworkStatus> get statusStream;
}

/// 网络状态枚举
enum NetworkStatus {
  unknown,
  disconnected,
  connected,
  connecting,
  slow,
}

/// ==================== 安全服务接口 ====================

/// 安全监控器接口
abstract class ISecurityMonitor {
  /// 检查安全状态
  Future<SecurityStatus> checkSecurity();

  /// 报告安全事件
  void reportSecurityEvent(SecurityEvent event);

  /// 安全事件流
  Stream<SecurityEvent> get securityEventStream;
}

/// 安全状态
class SecurityStatus {
  final bool isSecure;
  final List<SecurityIssue> issues;
  final DateTime lastChecked;

  const SecurityStatus({
    required this.isSecure,
    required this.issues,
    required this.lastChecked,
  });
}

/// 安全问题
class SecurityIssue {
  final String description;
  final SecurityLevel level;
  final String recommendation;

  const SecurityIssue({
    required this.description,
    required this.level,
    required this.recommendation,
  });
}

/// 安全级别
enum SecurityLevel {
  low,
  medium,
  high,
  critical,
}

/// 安全事件
class SecurityEvent {
  final String type;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const SecurityEvent({
    required this.type,
    required this.description,
    required this.timestamp,
    this.metadata,
  });
}

/// 安全存储服务接口
abstract class ISecureStorageService {
  /// 存储敏感数据
  Future<void> store(String key, String value);

  /// 读取敏感数据
  Future<String?> read(String key);

  /// 删除敏感数据
  Future<void> delete(String key);

  /// 清空所有数据
  Future<void> clear();

  /// 检查键是否存在
  Future<bool> containsKey(String key);
}

/// ==================== 性能服务接口 ====================

/// 性能监控器接口
abstract class IPerformanceMonitor {
  /// 开始监控
  void startMonitoring();

  /// 停止监控
  void stopMonitoring();

  /// 记录性能指标
  void recordMetric(PerformanceMetric metric);

  /// 获取性能报告
  Future<PerformanceReport> getReport();

  /// 性能指标流
  Stream<PerformanceMetric> get metricStream;
}

/// 性能指标
class PerformanceMetric {
  final String name;
  final double value;
  final String unit;
  final DateTime timestamp;
  final Map<String, dynamic>? tags;

  const PerformanceMetric({
    required this.name,
    required this.value,
    required this.unit,
    required this.timestamp,
    this.tags,
  });
}

/// 性能报告
class PerformanceReport {
  final Map<String, dynamic> metrics;
  final DateTime generatedAt;
  final Duration reportingPeriod;

  const PerformanceReport({
    required this.metrics,
    required this.generatedAt,
    required this.reportingPeriod,
  });
}

/// 内存监控器接口
abstract class IMemoryMonitor {
  /// 获取当前内存使用情况
  MemoryUsage getCurrentMemoryUsage();

  /// 开始内存监控
  void startMonitoring({Duration? interval});

  /// 停止内存监控
  void stopMonitoring();

  /// 内存使用变化流
  Stream<MemoryUsage> get memoryUsageStream;

  /// 检查内存压力
  MemoryPressureLevel get currentPressureLevel;
}

/// 内存使用情况
class MemoryUsage {
  final int totalMemory;
  final int usedMemory;
  final int freeMemory;
  final double usagePercentage;
  final DateTime timestamp;

  const MemoryUsage({
    required this.totalMemory,
    required this.usedMemory,
    required this.freeMemory,
    required this.usagePercentage,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'MemoryUsage(${(usagePercentage * 100).toStringAsFixed(2)}%, '
        '${(usedMemory / 1024 / 1024).toStringAsFixed(2)}MB used)';
  }
}

/// 内存压力级别
enum MemoryPressureLevel {
  normal,
  warning,
  critical,
  emergency,
}

/// ==================== 数据服务接口 ====================

/// 数据仓库接口
abstract class IRepository<T> {
  /// 获取数据
  Future<List<T>> getAll({Map<String, dynamic>? filters});

  /// 根据ID获取数据
  Future<T?> getById(String id);

  /// 保存数据
  Future<void> save(T entity);

  /// 删除数据
  Future<void> delete(String id);

  /// 更新数据
  Future<void> update(T entity);

  /// 搜索数据
  Future<List<T>> search(String query);
}

/// 数据验证器接口
abstract class IDataValidator {
  /// 验证数据
  ValidationResult validate(dynamic data);

  /// 获取验证规则
  List<ValidationRule> get rules;
}

/// 验证结果
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });
}

/// 验证规则
class ValidationRule {
  final String name;
  final String description;
  final bool Function(dynamic) validator;

  const ValidationRule({
    required this.name,
    required this.description,
    required this.validator,
  });
}

/// ==================== 健康检查相关 ====================

/// 健康检查结果
class HealthCheckResult {
  final bool isHealthy;
  final Map<String, dynamic> details;
  final DateTime timestamp;
  final Duration? responseTime;

  const HealthCheckResult({
    required this.isHealthy,
    required this.details,
    required this.timestamp,
    this.responseTime,
  });
}

/// 服务状态
enum ServiceStatus {
  unknown,
  healthy,
  unhealthy,
  degraded,
  disabled,
}

/// ==================== 服务定位器接口 ====================

/// 服务定位器接口
abstract class IServiceLocator {
  /// 注册服务
  void register<T extends Object>(T service);

  /// 注册懒加载服务
  void registerLazy<T extends Object>(T Function() factory);

  /// 获取服务
  T get<T extends Object>();

  /// 检查服务是否已注册
  bool isRegistered<T extends Object>();

  /// 释放服务
  Future<void> dispose<T extends Object>();

  /// 重置所有服务
  Future<void> reset();
}
