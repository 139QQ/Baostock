import 'package:dio/dio.dart';

/// 多数据源API配置
class MultiSourceApiConfig {
  /// 主要API源 - 自建服务
  static String rimaryApiBaseUrl = 'http://154.44.25.92:8080/';

  /// 备用API源配置
  static final List<ApiSource> backupSources = [
    // AKShare官方服务
    ApiSource(
      name: 'akshare_official',
      baseUrl: 'https://aktools.akfamily.xyz/api/public/',
      priority: 1,
      timeout: const Duration(seconds: 10),
      healthCheckEndpoint: 'fund_name_em',
      rateLimit: RateLimitConfig(
          maxRequests: 100, timeWindow: const Duration(minutes: 1)),
    ),
    // 第三方金融数据API（需要注册）
    ApiSource(
      name: 'tushare',
      baseUrl: 'https://api.tushare.pro/',
      priority: 2,
      timeout: const Duration(seconds: 15),
      healthCheckEndpoint: '',
      requiresAuth: true,
      authConfig: AuthConfig(type: AuthType.token, tokenKey: 'TUSHARE_TOKEN'),
      rateLimit: RateLimitConfig(
          maxRequests: 500, timeWindow: const Duration(minutes: 1)),
    ),
    // 腾讯财经API
    ApiSource(
      name: 'tencent_finance',
      baseUrl: 'https://qt.gtimg.cn/',
      priority: 3,
      timeout: const Duration(seconds: 8),
      healthCheckEndpoint: '',
      rateLimit: RateLimitConfig(
          maxRequests: 200, timeWindow: const Duration(minutes: 1)),
    ),
    // 网易财经API
    ApiSource(
      name: 'netease_finance',
      baseUrl: 'https://quotes.money.163.com/',
      priority: 4,
      timeout: const Duration(seconds: 12),
      healthCheckEndpoint: '',
      rateLimit: RateLimitConfig(
          maxRequests: 150, timeWindow: const Duration(minutes: 1)),
    ),
    // 新浪财经API
    ApiSource(
      name: 'sina_finance',
      baseUrl: 'https://hq.sinajs.cn/',
      priority: 5,
      timeout: const Duration(seconds: 10),
      healthCheckEndpoint: '',
      rateLimit: RateLimitConfig(
          maxRequests: 300, timeWindow: const Duration(minutes: 1)),
    ),
  ];

  /// 模拟数据源
  static final ApiSource mockSource = ApiSource(
    name: 'mock_data',
    baseUrl: 'mock://localhost/',
    priority: 999,
    timeout: const Duration(seconds: 2),
    healthCheckEndpoint: '',
    isMock: true,
    rateLimit: RateLimitConfig(
        maxRequests: 1000, timeWindow: const Duration(minutes: 1)),
  );
}

/// API源配置类
class ApiSource {
  final String name;
  final String baseUrl;
  final int priority; // 优先级，数字越小优先级越高
  final Duration timeout;
  final String healthCheckEndpoint;
  final bool requiresAuth;
  final AuthConfig? authConfig;
  final RateLimitConfig rateLimit;
  final bool isMock;
  bool isHealthy = true;
  DateTime? lastHealthCheck;
  int consecutiveFailures = 0;

  ApiSource({
    required this.name,
    required this.baseUrl,
    required this.priority,
    required this.timeout,
    required this.healthCheckEndpoint,
    this.requiresAuth = false,
    this.authConfig,
    required this.rateLimit,
    this.isMock = false,
  });

  /// 获取Dio实例配置
  Dio createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: timeout,
        receiveTimeout: timeout,
        sendTimeout: timeout,
        headers: _buildHeaders(),
      ),
    );

    // 添加拦截器
    dio.interceptors.addAll(_buildInterceptors());

    return dio;
  }

  Map<String, dynamic> _buildHeaders() {
    final headers = <String, dynamic>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'FundAnalysisApp/1.0.0',
    };

    if (requiresAuth && authConfig != null) {
      switch (authConfig!.type) {
        case AuthType.token:
          headers['Authorization'] = 'Bearer ${authConfig!.token}';
          break;
        case AuthType.apiKey:
          headers[authConfig!.apiKeyHeader ?? 'X-API-Key'] =
              authConfig!.apiKey!;
          break;
        case AuthType.basic:
          headers['Authorization'] = 'Basic ${authConfig!.basicAuth}';
          break;
      }
    }

    return headers;
  }

  List<Interceptor> _buildInterceptors() {
    return [
      // 日志拦截器
      LogInterceptor(
        request: true,
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        responseHeader: false,
        error: true,
      ),
      // 限流拦截器
      RateLimitInterceptor(rateLimit),
      // 重试拦截器
      RetryInterceptor(
        retries: 3,
        retryDelays: const [
          Duration(seconds: 1),
          Duration(seconds: 3),
          Duration(seconds: 5),
        ],
      ),
    ];
  }

  /// 更新健康状态
  void updateHealthStatus(bool healthy) {
    isHealthy = healthy;
    lastHealthCheck = DateTime.now();

    if (healthy) {
      consecutiveFailures = 0;
    } else {
      consecutiveFailures++;
    }
  }

  /// 是否应该被跳过
  bool shouldSkip() {
    if (!isHealthy && consecutiveFailures >= 3) {
      return true;
    }
    return false;
  }

  @override
  String toString() =>
      'ApiSource(name: $name, priority: $priority, healthy: $isHealthy)';
}

/// 认证配置
class AuthConfig {
  final AuthType type;
  final String? token;
  final String? tokenKey; // 环境变量中的key
  final String? apiKey;
  final String? apiKeyHeader;
  final String? basicAuth;

  AuthConfig({
    required this.type,
    this.token,
    this.tokenKey,
    this.apiKey,
    this.apiKeyHeader,
    this.basicAuth,
  });
}

enum AuthType {
  token,
  apiKey,
  basic,
}

/// 限流配置
class RateLimitConfig {
  final int maxRequests;
  final Duration timeWindow;
  int currentRequests = 0;
  DateTime? windowStart;

  RateLimitConfig({
    required this.maxRequests,
    required this.timeWindow,
  });

  bool canMakeRequest() {
    final now = DateTime.now();

    if (windowStart == null || now.difference(windowStart!) >= timeWindow) {
      // 新时间窗口
      windowStart = now;
      currentRequests = 0;
      return true;
    }

    if (currentRequests < maxRequests) {
      return true;
    }

    return false;
  }

  void recordRequest() {
    if (canMakeRequest()) {
      currentRequests++;
    }
  }
}

/// 限流拦截器
class RateLimitInterceptor extends Interceptor {
  final RateLimitConfig config;

  RateLimitInterceptor(this.config);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (config.canMakeRequest()) {
      config.recordRequest();
      handler.next(options);
    } else {
      handler.reject(
        DioException(
          requestOptions: options,
          error: 'Rate limit exceeded',
          type: DioExceptionType.badResponse,
        ),
      );
    }
  }
}

/// 重试拦截器
class RetryInterceptor extends Interceptor {
  final int retries;
  final List<Duration> retryDelays;

  RetryInterceptor({
    required this.retries,
    required this.retryDelays,
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRetry(err) &&
        err.requestOptions.extra['retry_count'] != retries) {
      final retryCount = (err.requestOptions.extra['retry_count'] ?? 0) as int;

      if (retryCount < retries) {
        err.requestOptions.extra['retry_count'] = retryCount + 1;

        final delay = retryDelays[retryCount.clamp(0, retryDelays.length - 1)];
        await Future.delayed(delay);

        try {
          final response = await Dio().fetch(err.requestOptions);
          handler.resolve(response);
          return;
        } catch (e) {
          // 继续重试或最终失败
        }
      }
    }

    handler.next(err);
  }

  bool _shouldRetry(DioException error) {
    // 只在网络错误或5xx服务器错误时重试
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        (error.response?.statusCode ?? 0) >= 500;
  }
}
