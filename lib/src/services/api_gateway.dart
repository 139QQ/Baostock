import 'dart:async';
import 'dart:convert';
import 'dart:math';

import '../core/utils/logger.dart';
import 'interfaces/service_interfaces.dart';

/// API Gateway - 统一服务网关
///
/// 功能特性：
/// 1. 服务注册与发现
/// 2. 智能路由和负载均衡
/// 3. 容错机制和故障转移
/// 4. 请求限流和熔断保护
/// 5. 统一的API管理和监控
class ApiGateway {
  static final ApiGateway _instance = ApiGateway._internal();
  factory ApiGateway() => _instance;
  ApiGateway._internal() {
    _initialize();
  }

  // 服务注册表
  final Map<String, ServiceRegistration> _services = {};
  final Map<String, List<ServiceInstance>> _serviceInstances = {};
  final Map<String, ServiceHealth> _serviceHealth = {};

  // 负载均衡器
  final Map<String, LoadBalancer> _loadBalancers = {};

  // 熔断器
  final Map<String, CircuitBreaker> _circuitBreakers = {};

  // 限流器
  final Map<String, RateLimiter> _rateLimiters = {};

  // 统计信息
  final GatewayStats _stats = GatewayStats();

  // 核心服务实例
  late final IApiService _apiService;
  late final IFundDataService _fundService;
  late final IPortfolioService _portfolioService;

  /// 初始化网关
  Future<void> _initialize() async {
    try {
      // 初始化核心服务
      // 这些服务需要从依赖注入容器获取或通过工厂方法创建
      throw UnimplementedError('API Gateway 需要通过依赖注入容器获取服务实例');

      // 注册核心服务
      await _registerCoreServices();

      // 初始化监控和统计
      _initializeMonitoring();

      AppLogger.info('✅ ApiGateway: 初始化完成');
    } catch (e) {
      AppLogger.error('❌ ApiGateway: 初始化失败', e);
      rethrow;
    }
  }

  /// 注册核心服务
  Future<void> _registerCoreServices() async {
    try {
      // 注册API服务
      await registerService(
        ServiceRegistration(
          name: 'api-service',
          version: '2.0.0',
          type: ServiceType.api,
          healthCheckPath: '/health',
          endpoints: [
            ServiceEndpoint(path: '/funds', methods: ['GET']),
            ServiceEndpoint(
                path: '/funds/*', methods: ['GET', 'POST', 'PUT', 'DELETE']),
            ServiceEndpoint(path: '/market/*', methods: ['GET']),
          ],
        ),
      );

      // 注册基金数据服务
      await registerService(
        ServiceRegistration(
          name: 'fund-data-service',
          version: '2.0.0',
          type: ServiceType.data,
          healthCheckPath: '/health',
          endpoints: [
            ServiceEndpoint(path: '/fund-rankings', methods: ['GET']),
            ServiceEndpoint(path: '/fund-search', methods: ['GET', 'POST']),
            ServiceEndpoint(path: '/fund-detail/*', methods: ['GET']),
          ],
        ),
      );

      // 注册投资组合服务
      await registerService(
        ServiceRegistration(
          name: 'portfolio-service',
          version: '2.0.0',
          type: ServiceType.business,
          healthCheckPath: '/health',
          endpoints: [
            ServiceEndpoint(
                path: '/portfolio/*',
                methods: ['GET', 'POST', 'PUT', 'DELETE']),
            ServiceEndpoint(path: '/portfolio/*/profit', methods: ['GET']),
            ServiceEndpoint(path: '/portfolio/*/analysis', methods: ['GET']),
          ],
        ),
      );

      AppLogger.info('✅ 核心服务注册完成');
    } catch (e) {
      AppLogger.error('❌ 核心服务注册失败', e);
      rethrow;
    }
  }

  /// 注册服务
  Future<void> registerService(ServiceRegistration registration) async {
    try {
      final serviceName = registration.name;

      // 注册服务信息
      _services[serviceName] = registration;

      // 初始化服务实例列表
      _serviceInstances[serviceName] = [];

      // 初始化负载均衡器
      _loadBalancers[serviceName] = LoadBalancer(
        strategy: registration.loadBalanceStrategy,
      );

      // 初始化熔断器
      _circuitBreakers[serviceName] = CircuitBreaker(
        failureThreshold: registration.circuitBreakerFailureThreshold,
        recoveryTimeout: registration.circuitBreakerRecoveryTimeout,
      );

      // 初始化限流器
      _rateLimiters[serviceName] = RateLimiter(
        maxRequests: registration.rateLimitMaxRequests,
        windowDuration: registration.rateLimitWindowDuration,
      );

      // 添加默认服务实例
      await addServiceInstance(
          serviceName,
          ServiceInstance(
            id: '${serviceName}_default',
            host: 'localhost',
            port: 8080,
            weight: 1,
            healthy: true,
          ));

      AppLogger.info('✅ 服务注册成功: $serviceName');
    } catch (e) {
      AppLogger.error('❌ 服务注册失败: ${registration.name}', e);
      rethrow;
    }
  }

  /// 添加服务实例
  Future<void> addServiceInstance(
      String serviceName, ServiceInstance instance) async {
    try {
      if (!_services.containsKey(serviceName)) {
        throw ArgumentError('服务未注册: $serviceName');
      }

      _serviceInstances[serviceName]!.add(instance);

      // 启动健康检查
      _startHealthCheck(serviceName, instance);

      AppLogger.info('✅ 服务实例添加成功: $serviceName -> ${instance.id}');
    } catch (e) {
      AppLogger.error('❌ 服务实例添加失败', e);
      rethrow;
    }
  }

  /// 路由请求
  Future<GatewayResponse> route(GatewayRequest request) async {
    final stopwatch = Stopwatch()..start();
    final requestId = _generateRequestId();

    try {
      AppLogger.debug(
          '🚀 网关路由请求 [$requestId]: ${request.method} ${request.path}');

      // 更新统计
      _stats.totalRequests++;

      // 查找目标服务
      final targetService = _findTargetService(request.path, request.method);
      if (targetService == null) {
        _stats.routeErrors++;
        return GatewayResponse.notFound('服务未找到: ${request.path}');
      }

      // 检查熔断器
      final circuitBreaker = _circuitBreakers[targetService]!;
      if (circuitBreaker.isOpen()) {
        _stats.circuitBreakerTrips++;
        return GatewayResponse.serviceUnavailable('服务熔断: $targetService');
      }

      // 检查限流
      final rateLimiter = _rateLimiters[targetService]!;
      if (!rateLimiter.allowRequest()) {
        _stats.rateLimitHits++;
        return GatewayResponse.tooManyRequests('请求频率超限: $targetService');
      }

      // 负载均衡选择实例
      final instances = _serviceInstances[targetService]!
          .where((instance) => instance.healthy)
          .toList();

      if (instances.isEmpty) {
        _stats.noHealthyInstances++;
        return GatewayResponse.serviceUnavailable('无健康实例: $targetService');
      }

      final selectedInstance =
          _loadBalancers[targetService]!.selectInstance(instances);

      // 执行请求
      final response = await _executeRequest(
        targetService,
        selectedInstance,
        request,
        requestId,
      );

      // 更新熔断器状态
      if (response.isSuccess) {
        circuitBreaker.recordSuccess();
        _stats.successfulRequests++;
      } else {
        circuitBreaker.recordFailure();
        _stats.failedRequests++;
      }

      stopwatch.stop();
      _stats.recordResponseTime(stopwatch.elapsedMilliseconds);

      AppLogger.info(
          '✅ 网关路由完成 [$requestId]: ${response.statusCode} (${stopwatch.elapsedMilliseconds}ms)');

      return response;
    } catch (e) {
      stopwatch.stop();
      _stats.errors++;
      _stats.recordResponseTime(stopwatch.elapsedMilliseconds);

      AppLogger.error('❌ 网关路由失败 [$requestId]', e);

      return GatewayResponse.internalError('网关内部错误: $e');
    }
  }

  /// 查找目标服务
  String? _findTargetService(String path, String method) {
    for (final serviceName in _services.keys) {
      final registration = _services[serviceName]!;

      for (final endpoint in registration.endpoints) {
        if (_matchPath(endpoint.path, path) &&
            endpoint.methods.contains(method.toUpperCase())) {
          return serviceName;
        }
      }
    }
    return null;
  }

  /// 路径匹配
  bool _matchPath(String pattern, String path) {
    if (pattern == path) return true;

    // 简单的通配符匹配
    if (pattern.endsWith('/*')) {
      final prefix = pattern.substring(0, pattern.length - 2);
      return path.startsWith(prefix);
    }

    return false;
  }

  /// 执行请求
  Future<GatewayResponse> _executeRequest(
    String serviceName,
    ServiceInstance instance,
    GatewayRequest request,
    String requestId,
  ) async {
    try {
      switch (serviceName) {
        case 'api-service':
          return await _executeApiServiceRequest(request, requestId);
        case 'fund-data-service':
          return await _executeFundServiceRequest(request, requestId);
        case 'portfolio-service':
          return await _executePortfolioServiceRequest(request, requestId);
        default:
          return GatewayResponse.notFound('未知服务: $serviceName');
      }
    } catch (e) {
      AppLogger.error('❌ 执行服务请求失败: $serviceName', e);
      return GatewayResponse.internalError('服务执行失败: $e');
    }
  }

  /// 执行API服务请求
  Future<GatewayResponse> _executeApiServiceRequest(
    GatewayRequest request,
    String requestId,
  ) async {
    try {
      // 解析路径
      final pathSegments =
          request.path.split('/').where((s) => s.isNotEmpty).toList();

      if (pathSegments.isEmpty) {
        return GatewayResponse.badRequest('无效的API路径');
      }

      final response = await _apiService.get<Map<String, dynamic>>(
        request.path,
        queryParameters: request.queryParameters,
        headers: request.headers,
      );

      return GatewayResponse.success(
        response.data!,
        statusCode: response.statusCode ?? 200,
        headers: response.headers,
        requestId: requestId,
      );
    } catch (e) {
      return GatewayResponse.internalError('API服务请求失败: $e');
    }
  }

  /// 执行基金服务请求
  Future<GatewayResponse> _executeFundServiceRequest(
    GatewayRequest request,
    String requestId,
  ) async {
    try {
      final pathSegments =
          request.path.split('/').where((s) => s.isNotEmpty).toList();

      if (pathSegments.length < 2) {
        return GatewayResponse.badRequest('无效的基金服务路径');
      }

      final endpoint = pathSegments[1];

      switch (endpoint) {
        case 'fund-rankings':
          final symbol = request.queryParameters?['symbol'] ?? '全部';
          final forceRefresh =
              request.queryParameters?['forceRefresh'] == 'true';
          final useHighPerformance =
              request.queryParameters?['highPerformance'] == 'true';

          final result = await _fundService.getFundRankings(
            symbol: symbol,
            forceRefresh: forceRefresh,
            useHighPerformance: useHighPerformance,
          );

          if (result.isSuccess) {
            return GatewayResponse.success(
              result.data!.map((r) => r.toJson()).toList(),
              requestId: requestId,
            );
          } else {
            return GatewayResponse.badRequest(
                result.errorMessage ?? '获取基金排行失败');
          }

        case 'fund-search':
          final query = request.queryParameters?['q'] ?? '';
          final useHighPerformance =
              request.queryParameters?['highPerformance'] == 'true';

          final result = await _fundService.searchFunds(
            query,
            useHighPerformance: useHighPerformance,
          );

          if (result.isSuccess) {
            return GatewayResponse.success(
              result.data!.map((r) => r.toJson()).toList(),
              requestId: requestId,
            );
          } else {
            return GatewayResponse.badRequest(result.errorMessage ?? '搜索基金失败');
          }

        default:
          return GatewayResponse.notFound('未知的基金服务端点: $endpoint');
      }
    } catch (e) {
      return GatewayResponse.internalError('基金服务请求失败: $e');
    }
  }

  /// 执行投资组合服务请求
  Future<GatewayResponse> _executePortfolioServiceRequest(
    GatewayRequest request,
    String requestId,
  ) async {
    try {
      final pathSegments =
          request.path.split('/').where((s) => s.isNotEmpty).toList();

      if (pathSegments.length < 2) {
        return GatewayResponse.badRequest('无效的投资组合服务路径');
      }

      final userId = pathSegments[1];

      if (request.method == 'GET') {
        if (pathSegments.length > 2) {
          final action = pathSegments[2];

          switch (action) {
            case 'profit':
              final result =
                  await _portfolioService.calculatePortfolioProfit(userId);

              return result.fold(
                (failure) => GatewayResponse.badRequest(failure.message),
                (profit) {
                  if (profit != null && profit is Map<String, dynamic>) {
                    return GatewayResponse.success(profit,
                        requestId: requestId);
                  } else if (profit != null) {
                    return GatewayResponse.success({'data': profit.toString()},
                        requestId: requestId);
                  } else {
                    return GatewayResponse.success({}, requestId: requestId);
                  }
                },
              );

            case 'analysis':
              final result =
                  await _portfolioService.getPortfolioAnalysis(userId);

              return result.fold(
                (failure) => GatewayResponse.badRequest(failure.message),
                (analysis) {
                  if (analysis != null && analysis is Map<String, dynamic>) {
                    return GatewayResponse.success(analysis,
                        requestId: requestId);
                  } else if (analysis != null) {
                    return GatewayResponse.success(
                        {'data': analysis.toString()},
                        requestId: requestId);
                  } else {
                    return GatewayResponse.success({}, requestId: requestId);
                  }
                },
              );

            default:
              return GatewayResponse.notFound('未知的投资组合操作: $action');
          }
        } else {
          // 获取持仓
          final result = await _portfolioService.getUserHoldings(userId);

          return result.fold(
            (failure) => GatewayResponse.badRequest(failure.message),
            (holdings) => GatewayResponse.success(
              holdings.map((h) => h.toJson()).toList(),
              requestId: requestId,
            ),
          );
        }
      } else {
        return GatewayResponse.methodNotAllowed(
            '不支持的HTTP方法: ${request.method}');
      }
    } catch (e) {
      return GatewayResponse.internalError('投资组合服务请求失败: $e');
    }
  }

  /// 启动健康检查
  void _startHealthCheck(String serviceName, ServiceInstance instance) {
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      try {
        final isHealthy = await _checkInstanceHealth(instance);
        final previousHealthy = instance.healthy;
        instance.healthy = isHealthy;

        if (previousHealthy != isHealthy) {
          AppLogger.info(
              '🏥 实例健康状态变更: ${instance.id} -> ${isHealthy ? "健康" : "不健康"}');
        }
      } catch (e) {
        AppLogger.warn('⚠️ 健康检查失败: ${instance.id} - $e');
        instance.healthy = false;
      }
    });
  }

  /// 检查实例健康状态
  Future<bool> _checkInstanceHealth(ServiceInstance instance) async {
    try {
      // 简单的健康检查实现
      // 实际应该调用实例的健康检查端点
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 初始化监控
  void _initializeMonitoring() {
    // 定期清理统计数据
    Timer.periodic(const Duration(minutes: 5), (timer) {
      _stats.cleanup();
    });

    // 定期报告统计信息
    Timer.periodic(const Duration(minutes: 10), (timer) {
      _reportStats();
    });
  }

  /// 报告统计信息
  void _reportStats() {
    AppLogger.info('📊 网关统计信息: ${jsonEncode(_stats.toJson())}');
  }

  /// 生成请求ID
  String _generateRequestId() {
    return 'gw_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }

  /// 获取网关统计信息
  Map<String, dynamic> getStats() {
    return {
      'gateway': _stats.toJson(),
      'services': _services.map((k, v) => MapEntry(k, v.toJson())),
      'instances': _serviceInstances.map((k, v) => MapEntry(k, v.length)),
      'health': _serviceHealth.map((k, v) => MapEntry(k, v.toJson())),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// 清理资源
  Future<void> dispose() async {
    try {
      _services.clear();
      _serviceInstances.clear();
      _serviceHealth.clear();
      _loadBalancers.clear();
      _circuitBreakers.clear();
      _rateLimiters.clear();

      AppLogger.info('✅ ApiGateway: 资源清理完成');
    } catch (e) {
      AppLogger.error('❌ ApiGateway: 资源清理失败', e);
    }
  }
}

// 辅助类定义

/// 服务注册信息
class ServiceRegistration {
  final String name;
  final String version;
  final ServiceType type;
  final String healthCheckPath;
  final List<ServiceEndpoint> endpoints;
  final LoadBalanceStrategy loadBalanceStrategy;
  final int circuitBreakerFailureThreshold;
  final Duration circuitBreakerRecoveryTimeout;
  final int rateLimitMaxRequests;
  final Duration rateLimitWindowDuration;

  const ServiceRegistration({
    required this.name,
    required this.version,
    required this.type,
    required this.healthCheckPath,
    required this.endpoints,
    this.loadBalanceStrategy = LoadBalanceStrategy.roundRobin,
    this.circuitBreakerFailureThreshold = 5,
    this.circuitBreakerRecoveryTimeout = const Duration(seconds: 60),
    this.rateLimitMaxRequests = 100,
    this.rateLimitWindowDuration = const Duration(minutes: 1),
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'version': version,
      'type': type.toString(),
      'healthCheckPath': healthCheckPath,
      'endpoints': endpoints.map((e) => e.toJson()).toList(),
      'loadBalanceStrategy': loadBalanceStrategy.toString(),
    };
  }
}

/// 服务端点
class ServiceEndpoint {
  final String path;
  final List<String> methods;

  const ServiceEndpoint({
    required this.path,
    required this.methods,
  });

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'methods': methods,
    };
  }
}

/// 服务实例
class ServiceInstance {
  final String id;
  final String host;
  final int port;
  final int weight;
  bool healthy;

  ServiceInstance({
    required this.id,
    required this.host,
    required this.port,
    required this.weight,
    this.healthy = true,
  });

  String get url => 'http://$host:$port';
}

/// 服务类型
enum ServiceType {
  api,
  data,
  business,
  infrastructure,
}

/// 负载均衡策略
enum LoadBalanceStrategy {
  roundRobin,
  weighted,
  leastConnections,
}

/// 负载均衡器
class LoadBalancer {
  final LoadBalanceStrategy strategy;
  int _currentIndex = 0;

  LoadBalancer({required this.strategy});

  ServiceInstance selectInstance(List<ServiceInstance> instances) {
    if (instances.isEmpty) {
      throw ArgumentError('没有可用的服务实例');
    }

    switch (strategy) {
      case LoadBalanceStrategy.roundRobin:
        return _roundRobin(instances);
      case LoadBalanceStrategy.weighted:
        return _weighted(instances);
      case LoadBalanceStrategy.leastConnections:
        return _leastConnections(instances);
    }
  }

  ServiceInstance _roundRobin(List<ServiceInstance> instances) {
    final instance = instances[_currentIndex % instances.length];
    _currentIndex++;
    return instance;
  }

  ServiceInstance _weighted(List<ServiceInstance> instances) {
    // 简单的加权随机实现
    final totalWeight =
        instances.fold<int>(0, (sum, instance) => sum + instance.weight);
    final random = Random().nextInt(totalWeight);

    var currentWeight = 0;
    for (final instance in instances) {
      currentWeight += instance.weight;
      if (random < currentWeight) {
        return instance;
      }
    }

    return instances.first;
  }

  ServiceInstance _leastConnections(List<ServiceInstance> instances) {
    // 简化实现，返回第一个实例
    // 实际应该跟踪每个实例的连接数
    return instances.first;
  }
}

/// 熔断器
class CircuitBreaker {
  final int failureThreshold;
  final Duration recoveryTimeout;

  int _failureCount = 0;
  DateTime? _lastFailureTime;
  CircuitBreakerState _state = CircuitBreakerState.closed;

  CircuitBreaker({
    required this.failureThreshold,
    required this.recoveryTimeout,
  });

  bool isOpen() {
    if (_state == CircuitBreakerState.open) {
      if (_lastFailureTime != null &&
          DateTime.now().difference(_lastFailureTime!) > recoveryTimeout) {
        _state = CircuitBreakerState.halfOpen;
        return false;
      }
      return true;
    }
    return false;
  }

  void recordSuccess() {
    _failureCount = 0;
    if (_state == CircuitBreakerState.halfOpen) {
      _state = CircuitBreakerState.closed;
    }
  }

  void recordFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();

    if (_failureCount >= failureThreshold) {
      _state = CircuitBreakerState.open;
    }
  }
}

enum CircuitBreakerState {
  closed,
  open,
  halfOpen,
}

/// 限流器
class RateLimiter {
  final int maxRequests;
  final Duration windowDuration;

  final List<DateTime> _requests = [];

  RateLimiter({
    required this.maxRequests,
    required this.windowDuration,
  });

  bool allowRequest() {
    final now = DateTime.now();

    // 清理过期的请求记录
    _requests.removeWhere((time) => now.difference(time) > windowDuration);

    if (_requests.length < maxRequests) {
      _requests.add(now);
      return true;
    }

    return false;
  }
}

/// 网关统计信息
class GatewayStats {
  int totalRequests = 0;
  int successfulRequests = 0;
  int failedRequests = 0;
  int errors = 0;
  int routeErrors = 0;
  int circuitBreakerTrips = 0;
  int rateLimitHits = 0;
  int noHealthyInstances = 0;

  final List<int> _responseTimes = [];

  void recordResponseTime(int milliseconds) {
    _responseTimes.add(milliseconds);

    // 保持最近1000个响应时间记录
    if (_responseTimes.length > 1000) {
      _responseTimes.removeAt(0);
    }
  }

  void cleanup() {
    // 清理过期的统计数据
    if (_responseTimes.length > 100) {
      _responseTimes.removeRange(0, _responseTimes.length - 100);
    }
  }

  Map<String, dynamic> toJson() {
    final avgResponseTime = _responseTimes.isEmpty
        ? 0.0
        : _responseTimes.reduce((a, b) => a + b) / _responseTimes.length;

    return {
      'total_requests': totalRequests,
      'successful_requests': successfulRequests,
      'failed_requests': failedRequests,
      'errors': errors,
      'route_errors': routeErrors,
      'circuit_breaker_trips': circuitBreakerTrips,
      'rate_limit_hits': rateLimitHits,
      'no_healthy_instances': noHealthyInstances,
      'avg_response_time_ms': avgResponseTime.toStringAsFixed(2),
      'success_rate': totalRequests > 0
          ? ((successfulRequests / totalRequests) * 100).toStringAsFixed(2) +
              '%'
          : '0%',
    };
  }
}

/// 服务健康状态
class ServiceHealth {
  final bool healthy;
  final DateTime lastCheck;
  final String? message;

  const ServiceHealth({
    required this.healthy,
    required this.lastCheck,
    this.message,
  });

  Map<String, dynamic> toJson() {
    return {
      'healthy': healthy,
      'last_check': lastCheck.toIso8601String(),
      'message': message,
    };
  }
}

/// 网关请求
class GatewayRequest {
  final String method;
  final String path;
  final Map<String, dynamic>? queryParameters;
  final Map<String, String>? headers;
  final dynamic body;

  const GatewayRequest({
    required this.method,
    required this.path,
    this.queryParameters,
    this.headers,
    this.body,
  });
}

/// 网关响应
class GatewayResponse {
  final dynamic data;
  final int statusCode;
  final Map<String, String>? headers;
  final String? requestId;
  final bool isSuccess;

  const GatewayResponse._({
    this.data,
    required this.statusCode,
    this.headers,
    this.requestId,
    required this.isSuccess,
  });

  factory GatewayResponse.success(
    dynamic data, {
    int statusCode = 200,
    Map<String, String>? headers,
    String? requestId,
  }) {
    return GatewayResponse._(
      data: data,
      statusCode: statusCode,
      headers: headers,
      requestId: requestId,
      isSuccess: true,
    );
  }

  factory GatewayResponse.badRequest(String message, {String? requestId}) {
    return GatewayResponse._(
      data: {'error': message},
      statusCode: 400,
      requestId: requestId,
      isSuccess: false,
    );
  }

  factory GatewayResponse.notFound(String message, {String? requestId}) {
    return GatewayResponse._(
      data: {'error': message},
      statusCode: 404,
      requestId: requestId,
      isSuccess: false,
    );
  }

  factory GatewayResponse.methodNotAllowed(String message,
      {String? requestId}) {
    return GatewayResponse._(
      data: {'error': message},
      statusCode: 405,
      requestId: requestId,
      isSuccess: false,
    );
  }

  factory GatewayResponse.tooManyRequests(String message, {String? requestId}) {
    return GatewayResponse._(
      data: {'error': message},
      statusCode: 429,
      requestId: requestId,
      isSuccess: false,
    );
  }

  factory GatewayResponse.serviceUnavailable(String message,
      {String? requestId}) {
    return GatewayResponse._(
      data: {'error': message},
      statusCode: 503,
      requestId: requestId,
      isSuccess: false,
    );
  }

  factory GatewayResponse.internalError(String message, {String? requestId}) {
    return GatewayResponse._(
      data: {'error': message},
      statusCode: 500,
      requestId: requestId,
      isSuccess: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'status_code': statusCode,
      'headers': headers,
      'request_id': requestId,
      'success': isSuccess,
    };
  }
}
