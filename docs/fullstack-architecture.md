# 基金分析应用全栈架构设计

## 1. 架构概述

### 1.1 设计理念
基于云原生、微服务和响应式设计原则，构建高可用、高性能、可扩展的基金分析应用全栈架构。采用前后端分离架构，支持多平台部署，确保99.9%的系统可用性。

### 1.2 架构目标
- **高可用性**: 99.9%系统可用性，支持故障自动恢复
- **高性能**: 页面加载<3秒，API响应<500ms
- **可扩展性**: 支持水平扩展，弹性伸缩
- **安全性**: 多层安全防护，数据加密传输
- **可维护性**: 模块化设计，易于维护和升级

### 1.3 技术栈选型
```
前端: Flutter (Web/移动端/桌面端)
状态管理: BLoC Pattern
UI框架: Material Design
路由: GoRouter

后端: ASP.NET Core 6.0
数据库: SQL Server + PostgreSQL
缓存: Redis
消息队列: RabbitMQ
监控: Prometheus + Grafana

基础设施: Docker + Kubernetes
CI/CD: GitHub Actions
云服务: 自建服务器集群
```

## 2. 前端架构设计

### 2.1 Flutter跨平台架构
```
┌─────────────────────────────────────────────────────────┐
│                 Presentation Layer                       │
│  ┌─────────────┬──────────────┬────────────────────┐   │
│  │   Web       │   Mobile     │    Desktop         │   │
│  │  (PWA)      │  (iOS/Android)│   (Windows/macOS) │   │
│  └─────────────┴──────────────┴────────────────────┘   │
├─────────────────────────────────────────────────────────┤
│                   BLoC State Management                  │
│  ┌─────────────┬──────────────┬────────────────────┐   │
│  │ FundBloc    │ RankingBloc  │  NavigationBloc    │   │
│  │ WatchlistBloc│ SettingsBloc │  ThemeBloc         │   │
│  └─────────────┴──────────────┴────────────────────┘   │
├─────────────────────────────────────────────────────────┤
│                 Repository Layer                         │
│  ┌─────────────┬──────────────┬────────────────────┐   │
│  │ FundRepo    │ RankingRepo  │  UserRepo          │   │
│  │ CacheRepo   │ SettingsRepo │  AnalyticsRepo     │   │
│  └─────────────┴──────────────┴────────────────────┘   │
├─────────────────────────────────────────────────────────┤
│                 Service Layer                            │
│  ┌─────────────┬──────────────┬────────────────────┐   │
│  │ ApiService  │ CacheService │  AnalyticsService  │   │
│  │ AuthService │ LocalService │  ErrorService      │   │
│  └─────────────┴──────────────┴────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

### 2.2 MVVM + BLoC架构模式
```dart
// View层 - UI组件
class FundRankingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FundRankingBloc(),
      child: FundRankingView(),
    );
  }
}

// ViewModel层 - BLoC状态管理
class FundRankingBloc extends Bloc<FundRankingEvent, FundRankingState> {
  final GetFundRankings _getFundRankings;

  @override
  Stream<FundRankingState> mapEventToState(FundRankingEvent event) async* {
    if (event is LoadFundRankings) {
      yield* _mapLoadFundRankingsToState(event);
    }
  }
}

// Model层 - 数据模型
class FundRanking {
  final String fundCode;
  final String fundName;
  final double return1Y;
  final double return3Y;
  // ... 其他属性
}
```

### 2.3 响应式UI设计
```dart
class ResponsiveLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1200) {
          return DesktopLayout(); // 桌面端布局
        } else if (constraints.maxWidth >= 600) {
          return TabletLayout(); // 平板布局
        } else {
          return MobileLayout(); // 移动端布局
        }
      },
    );
  }
}
```

### 2.4 状态管理策略
```dart
// 全局状态管理
class AppState {
  final UserState user;
  final FundState fund;
  final SettingsState settings;
  final NavigationState navigation;
}

// 局部状态管理
class FundRankingState {
  final List<FundRanking> rankings;
  final LoadStatus status;
  final String? error;
  final bool hasMore;
}
```

## 3. 后端架构设计

### 3.1 微服务架构
```
┌─────────────────────────────────────────────────────────┐
│                    API Gateway                           │
│                  (Kong / Ocelot)                         │
├─────────────────────────────────────────────────────────┤
│                  Load Balancer                           │
│                (Nginx / HAProxy)                         │
├─────────────────────────────────────────────────────────┤
│                   Microservices                          │
│  ┌─────────────┬──────────────┬────────────────────┐   │
│  │Fund Service │User Service  │Analytics Service   │   │
│  │├───────────┐│├───────────┐  │├───────────────┐  │   │
│  ││Fund API   │││Auth API   │  ││Analytics API  │  │   │
│  ││Ranking API│││Profile API│  ││Reporting API  │  │   │
│  │└───────────┘│└───────────┘  │└───────────────┘  │   │
│  └─────────────┴──────────────┴────────────────────┘   │
├─────────────────────────────────────────────────────────┤
│                   Data Layer                             │
│  ┌─────────────┬──────────────┬────────────────────┐   │
│  │PostgreSQL   │Redis Cache   │RabbitMQ            │   │
│  │(主数据库)    │(缓存层)      │(消息队列)          │   │
│  └─────────────┴──────────────┴────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

### 3.2 基金数据服务
```csharp
// ASP.NET Core Web API
[ApiController]
[Route("api/[controller]")]
public class FundController : ControllerBase
{
    private readonly IFundService _fundService;
    private readonly ICacheService _cacheService;

    [HttpGet("rankings/{category}")]
    public async Task<ActionResult<List<FundRankingDto>>> GetFundRankings(
        string category,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var cacheKey = $"fund_rankings_{category}_{page}_{pageSize}";
        var cachedData = await _cacheService.GetAsync<List<FundRankingDto>>(cacheKey);

        if (cachedData != null)
            return Ok(cachedData);

        var rankings = await _fundService.GetFundRankingsAsync(category, page, pageSize);
        await _cacheService.SetAsync(cacheKey, rankings, TimeSpan.FromMinutes(15));

        return Ok(rankings);
    }
}
```

### 3.3 数据源集成
```csharp
public interface IFundDataProvider
{
    Task<List<FundRanking>> GetFundRankingsAsync(string symbol);
}

// AKShare数据源
public class AkShareDataProvider : IFundDataProvider
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<AkShareDataProvider> _logger;

    public async Task<List<FundRanking>> GetFundRankingsAsync(string symbol)
    {
        try
        {
            var response = await _httpClient.GetAsync($"http://154.44.25.92:8080/aktools/fund/rankings/{symbol}");
            response.EnsureSuccessStatusCode();

            var json = await response.Content.ReadAsStringAsync();
            return JsonSerializer.Deserialize<List<FundRanking>>(json);
        }
        catch (HttpRequestException ex)
        {
            _logger.LogError(ex, "AKShare API调用失败");
            throw new FundDataException("基金数据服务暂不可用", ex);
        }
    }
}

// 降级数据源
public class FallbackDataProvider : IFundDataProvider
{
    public async Task<List<FundRanking>> GetFundRankingsAsync(string symbol)
    {
        // 返回模拟数据或缓存数据
        return GenerateMockData(symbol);
    }
}
```

### 3.4 API网关配置
```yaml
# Kong API Gateway配置
services:
  - name: fund-service
    url: http://fund-service:8080
    routes:
      - name: fund-rankings
        paths:
          - /api/fund
        methods:
          - GET
        plugins:
          - name: rate-limiting
            config:
              minute: 100
              hour: 1000
          - name: cors
            config:
              origins:
                - "https://fund-app.com"
                - "http://localhost:3000"
              credentials: true
```

## 4. 数据架构设计

### 4.1 数据库设计
```sql
-- 基金主表
CREATE TABLE funds (
    id SERIAL PRIMARY KEY,
    fund_code VARCHAR(10) UNIQUE NOT NULL,
    fund_name VARCHAR(100) NOT NULL,
    fund_type VARCHAR(20) NOT NULL,
    company_code VARCHAR(10) NOT NULL,
    company_name VARCHAR(100) NOT NULL,
    establishment_date DATE,
    fund_scale DECIMAL(15,2),
    status VARCHAR(10) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 基金净值表
CREATE TABLE fund_nav (
    id SERIAL PRIMARY KEY,
    fund_code VARCHAR(10) NOT NULL,
    nav_date DATE NOT NULL,
    unit_nav DECIMAL(10,4) NOT NULL,
    accumulated_nav DECIMAL(10,4) NOT NULL,
    daily_return DECIMAL(8,4),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(fund_code, nav_date),
    FOREIGN KEY (fund_code) REFERENCES funds(fund_code)
);

-- 基金排行表
CREATE TABLE fund_rankings (
    id SERIAL PRIMARY KEY,
    fund_code VARCHAR(10) NOT NULL,
    ranking_date DATE NOT NULL,
    ranking_period VARCHAR(10) NOT NULL, -- 1W, 1M, 3M, 6M, 1Y, 2Y, 3Y, YTD
    ranking_position INTEGER NOT NULL,
    return_rate DECIMAL(8,4) NOT NULL,
    total_count INTEGER NOT NULL,
    category VARCHAR(20) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(fund_code, ranking_date, ranking_period, category),
    FOREIGN KEY (fund_code) REFERENCES funds(fund_code)
);
```

### 4.2 缓存策略
```csharp
public class CacheService : ICacheService
{
    private readonly IDistributedCache _cache;
    private readonly ILogger<CacheService> _logger;

    public async Task<T> GetAsync<T>(string key)
    {
        var cachedData = await _cache.GetStringAsync(key);
        if (cachedData != null)
        {
            return JsonSerializer.Deserialize<T>(cachedData);
        }
        return default;
    }

    public async Task SetAsync<T>(string key, T value, TimeSpan expiration)
    {
        var options = new DistributedCacheEntryOptions
        {
            SlidingExpiration = expiration
        };

        var serializedData = JsonSerializer.Serialize(value);
        await _cache.SetStringAsync(key, serializedData, options);
    }

    // 多级缓存策略
    public async Task<T> GetOrCreateAsync<T>(string key, Func<Task<T>> factory, TimeSpan expiration)
    {
        // L1缓存 - 内存缓存
        var memoryCache = MemoryCache.Default;
        if (memoryCache.Contains(key))
        {
            return (T)memoryCache.Get(key);
        }

        // L2缓存 - Redis缓存
        var redisData = await GetAsync<T>(key);
        if (redisData != null)
        {
            memoryCache.Set(key, redisData, DateTimeOffset.Now.AddMinutes(5));
            return redisData;
        }

        // 回源获取数据
        var data = await factory();
        await SetAsync(key, data, expiration);
        memoryCache.Set(key, data, DateTimeOffset.Now.AddMinutes(5));

        return data;
    }
}
```

### 4.3 数据流处理
```
实时数据流处理架构:
┌─────────────────────────────────────────────────────────┐
│                  Data Sources                            │
│  ┌─────────────┬──────────────┬────────────────────┐   │
│  │AKShare API  │自建API       │第三方数据          │   │
│  └─────────────┴──────────────┴────────────────────┘   │
├─────────────────────────────────────────────────────────┤
│                 Data Ingestion                           │
│  ┌─────────────┬──────────────┬────────────────────┐   │
│  │REST API     │WebSocket     │Message Queue       │   │
│  └─────────────┴──────────────┴────────────────────┘   │
├─────────────────────────────────────────────────────────┤
│                 Data Processing                          │
│  ┌─────────────┬──────────────┬────────────────────┐   │
│  │ETL Pipeline │Data Validation│Data Transformation │   │
│  └─────────────┴──────────────┴────────────────────┘   │
├─────────────────────────────────────────────────────────┤
│                 Data Storage                             │
│  ┌─────────────┬──────────────┬────────────────────┐   │
│  │PostgreSQL   │Redis Cache   │Time Series DB      │   │
│  └─────────────┴──────────────┴────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

## 5. 系统集成设计

### 5.1 API集成模式
```dart
// 统一API客户端
class ApiClient {
  final Dio _dio;
  final String _baseUrl;

  ApiClient(this._baseUrl) : _dio = Dio() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = Duration(seconds: 30);
    _dio.options.receiveTimeout = Duration(seconds: 30);

    // 添加拦截器
    _dio.interceptors.addAll([
      LogInterceptor(),
      ErrorInterceptor(),
      RetryInterceptor(),
      CacheInterceptor(),
    ]);
  }

  // 基金排行API
  Future<List<FundRanking>> getFundRankings(String category, {int page = 1, int pageSize = 20}) async {
    try {
      final response = await _dio.get('/fund/rankings/$category', queryParameters: {
        'page': page,
        'pageSize': pageSize,
      });

      return (response.data as List)
          .map((json) => FundRanking.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}

// 多数据源集成
class FundRepository implements IFundRepository {
  final ApiClient _primaryClient;
  final ApiClient _fallbackClient;
  final CacheService _cacheService;

  @override
  Future<List<FundRanking>> getFundRankings(String category) async {
    // 1. 尝试缓存
    final cachedData = await _cacheService.getFundRankings(category);
    if (cachedData != null && !cachedData.isExpired) {
      return cachedData.data;
    }

    // 2. 尝试主数据源
    try {
      final rankings = await _primaryClient.getFundRankings(category);
      await _cacheService.cacheFundRankings(category, rankings);
      return rankings;
    } catch (e) {
      // 3. 降级到备用数据源
      try {
        final rankings = await _fallbackClient.getFundRankings(category);
        await _cacheService.cacheFundRankings(category, rankings);
        return rankings;
      } catch (e) {
        // 4. 使用模拟数据
        return _generateMockRankings(category);
      }
    }
  }
}
```

### 5.2 错误处理和降级机制
```dart
// 错误分类和处理
class ErrorHandler {
  static AppError handleError(dynamic error) {
    if (error is TimeoutException) {
      return NetworkError.timeout();
    } else if (error is SocketException) {
      return NetworkError.noInternet();
    } else if (error is DioException) {
      switch (error.response?.statusCode) {
        case 401:
          return AuthError.unauthorized();
        case 403:
          return AuthError.forbidden();
        case 404:
          return NetworkError.notFound();
        case 500:
        case 502:
        case 503:
          return ServerError.serviceUnavailable();
        default:
          return NetworkError.unknown();
      }
    } else if (error is FormatException) {
      return DataError.parseError();
    } else {
      return AppError.unknown(error.toString());
    }
  }
}

// 降级策略
class FallbackStrategy {
  static Future<T> executeWithFallback<T>(
    Future<T> Function() primary,
    Future<T> Function() fallback,
    T Function() mock,
  ) async {
    try {
      return await primary();
    } catch (e) {
      try {
        return await fallback();
      } catch (e) {
        return mock();
      }
    }
  }
}
```

### 5.3 安全架构
```dart
// 认证和授权
class AuthService {
  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> setAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
}

// 数据加密
class EncryptionService {
  static String encrypt(String data) {
    final key = Key.fromUtf8('32-character-long-key-here!');
    final iv = IV.fromLength(16);
    final encrypter = Encrypter(AES(key));

    return encrypter.encrypt(data, iv: iv).base64;
  }

  static String decrypt(String encrypted) {
    final key = Key.fromUtf8('32-character-long-key-here!');
    final iv = IV.fromLength(16);
    final encrypter = Encrypter(AES(key));

    return encrypter.decrypt64(encrypted, iv: iv);
  }
}
```

## 6. 监控和日志系统

### 6.1 应用性能监控
```dart
// 性能监控
class PerformanceMonitor {
  static void trackApiCall(String endpoint, Duration duration) {
    // 记录API调用性能
    FirebaseAnalytics.instance.logEvent(
      name: 'api_performance',
      parameters: {
        'endpoint': endpoint,
        'duration': duration.inMilliseconds,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  static void trackWidgetBuild(String widgetName, Duration duration) {
    // 记录组件构建性能
    if (kDebugMode) {
      print('Widget $widgetName built in ${duration.inMilliseconds}ms');
    }
  }

  static void trackMemoryUsage() {
    // 监控内存使用情况
    if (kDebugMode) {
      print('Current memory usage: ${ProcessInfo.currentRss} bytes');
    }
  }
}
```

### 6.2 错误日志系统
```dart
// 日志服务
class LoggingService {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  static void info(String message) {
    _logger.i(message);
  }

  static void warning(String message) {
    _logger.w(message);
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);

    // 发送到远程日志服务
    _sendToRemoteLogging(message, error, stackTrace);
  }

  static void _sendToRemoteLogging(String message, dynamic error, StackTrace? stackTrace) {
    // 实现远程日志发送逻辑
    final errorInfo = {
      'message': message,
      'error': error?.toString(),
      'stackTrace': stackTrace?.toString(),
      'timestamp': DateTime.now().toIso8601String(),
      'deviceInfo': _getDeviceInfo(),
      'appVersion': _getAppVersion(),
    };

    // 发送到日志收集服务
    _sendToLogService(errorInfo);
  }
}
```

### 6.3 业务指标监控
```dart
// 业务指标监控
class BusinessMetrics {
  static void trackFundView(String fundCode) {
    FirebaseAnalytics.instance.logEvent(
      name: 'fund_view',
      parameters: {'fund_code': fundCode},
    );
  }

  static void trackFundRankingView(String category) {
    FirebaseAnalytics.instance.logEvent(
      name: 'fund_ranking_view',
      parameters: {'category': category},
    );
  }

  static void trackUserEngagement(String action) {
    FirebaseAnalytics.instance.logEvent(
      name: 'user_engagement',
      parameters: {'action': action},
    );
  }
}
```

## 7. 部署和运维

### 7.1 容器化部署
```dockerfile
# Dockerfile for Flutter Web
FROM nginx:alpine

# 复制构建产物
COPY build/web /usr/share/nginx/html

# 复制nginx配置
COPY nginx.conf /etc/nginx/nginx.conf

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/ || exit 1

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

```dockerfile
# Dockerfile for ASP.NET Core API
FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src
COPY ["FundService/FundService.csproj", "FundService/"]
RUN dotnet restore "FundService/FundService.csproj"
COPY . .
WORKDIR "/src/FundService"
RUN dotnet build "FundService.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "FundService.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "FundService.dll"]
```

### 7.2 Kubernetes部署配置
```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fund-app
  labels:
    app: fund-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: fund-app
  template:
    metadata:
      labels:
        app: fund-app
    spec:
      containers:
      - name: fund-app
        image: fund-app:latest
        ports:
        - containerPort: 80
        env:
        - name: ASPNETCORE_ENVIRONMENT
          value: "Production"
        - name: ConnectionStrings__DefaultConnection
          valueFrom:
            secretKeyRef:
              name: fund-app-secrets
              key: connection-string
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health/ready
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: fund-app-service
spec:
  selector:
    app: fund-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: LoadBalancer
```

### 7.3 CI/CD流水线
```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3

    - name: Setup .NET
      uses: actions/setup-dotnet@v3
      with:
        dotnet-version: '6.0.x'

    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.x'

    - name: Restore dependencies
      run: |
        dotnet restore
        flutter pub get

    - name: Run tests
      run: |
        dotnet test
        flutter test

    - name: Build Flutter Web
      run: |
        flutter build web --release

    - name: Build .NET API
      run: |
        dotnet publish -c Release -o ./publish

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
    - name: Build Docker images
      run: |
        docker build -t fund-app:${{ github.sha }} .
        docker build -f Dockerfile.api -t fund-api:${{ github.sha }} .

    - name: Push to registry
      run: |
        echo ${{ secrets.DOCKER_PASSWORD }} | docker login -u ${{ secrets.DOCKER_USERNAME }} --password-stdin
        docker push fund-app:${{ github.sha }}
        docker push fund-api:${{ github.sha }}

    - name: Deploy to Kubernetes
      run: |
        kubectl set image deployment/fund-app fund-app=fund-app:${{ github.sha }}
        kubectl set image deployment/fund-api fund-api=fund-api:${{ github.sha }}
        kubectl rollout status deployment/fund-app
        kubectl rollout status deployment/fund-api
```

## 8. 安全和合规

### 8.1 数据安全
```csharp
// 数据加密服务
public class DataEncryptionService
{
    private readonly IConfiguration _configuration;

    public string EncryptSensitiveData(string data)
    {
        var key = _configuration["Encryption:Key"];
        var iv = _configuration["Encryption:IV"];

        using (var aes = Aes.Create())
        {
            aes.Key = Convert.FromBase64String(key);
            aes.IV = Convert.FromBase64String(iv);

            var encryptor = aes.CreateEncryptor(aes.Key, aes.IV);

            using (var ms = new MemoryStream())
            {
                using (var cs = new CryptoStream(ms, encryptor, CryptoStreamMode.Write))
                using (var sw = new StreamWriter(cs))
                {
                    sw.Write(data);
                }

                return Convert.ToBase64String(ms.ToArray());
            }
        }
    }
}
```

### 8.2 API安全
```csharp
// JWT认证
services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = configuration["Jwt:Issuer"],
            ValidAudience = configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(configuration["Jwt:Key"]))
        };
    });

// 速率限制
services.AddRateLimiter(options =>
{
    options.AddFixedWindowLimiter("api", config =>
    {
        config.PermitLimit = 100;
        config.Window = TimeSpan.FromMinutes(1);
        config.QueueLimit = 10;
    });
});
```

### 8.3 审计日志
```csharp
// 审计服务
public class AuditService : IAuditService
{
    private readonly ApplicationDbContext _context;
    private readonly IHttpContextAccessor _httpContextAccessor;

    public async Task LogAsync(string action, object data = null)
    {
        var auditLog = new AuditLog
        {
            UserId = _httpContextAccessor.HttpContext?.User?.Identity?.Name,
            Action = action,
            Data = data != null ? JsonSerializer.Serialize(data) : null,
            IpAddress = _httpContextAccessor.HttpContext?.Connection?.RemoteIpAddress?.ToString(),
            UserAgent = _httpContextAccessor.HttpContext?.Request?.Headers["User-Agent"].ToString(),
            Timestamp = DateTime.UtcNow
        };

        _context.AuditLogs.Add(auditLog);
        await _context.SaveChangesAsync();
    }
}
```

## 9. 性能优化

### 9.1 前端性能优化
```dart
// 图片懒加载
class LazyImage extends StatelessWidget {
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Icon(Icons.error);
      },
      cacheWidth: 300, // 限制图片尺寸
      cacheHeight: 200,
    );
  }
}

// 虚拟滚动
class VirtualList extends StatelessWidget {
  final List<FundRanking> items;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        return FundRankingCard(
          key: ValueKey(items[index].fundCode),
          fund: items[index],
        );
      },
      // 预加载优化
      cacheExtent: 200.0,
    );
  }
}
```

### 9.2 后端性能优化
```csharp
// 数据库查询优化
public class FundRepository : IFundRepository
{
    private readonly ApplicationDbContext _context;

    public async Task<List<FundRanking>> GetTopPerformingFundsAsync(string category, int top = 100)
    {
        return await _context.FundRankings
            .Include(fr => fr.Fund)
            .Where(fr => fr.Category == category && fr.RankingDate == DateTime.Today)
            .OrderBy(fr => fr.RankingPosition)
            .Take(top)
            .AsNoTracking() // 只读查询优化
            .ToListAsync();
    }

    // 异步批量操作
    public async Task BulkUpdateFundRankingsAsync(List<FundRanking> rankings)
    {
        using var transaction = await _context.Database.BeginTransactionAsync();
        try
        {
            _context.FundRankings.AddRange(rankings);
            await _context.SaveChangesAsync();
            await transaction.CommitAsync();
        }
        catch
        {
            await transaction.RollbackAsync();
            throw;
        }
    }
}
```

### 9.3 缓存策略优化
```csharp
// 分布式缓存
public class DistributedCacheService : ICacheService
{
    private readonly IDistributedCache _cache;
    private readonly ILogger<DistributedCacheService> _logger;

    public async Task<T> GetOrCreateAsync<T>(
        string key,
        Func<Task<T>> factory,
        TimeSpan? expiration = null)
    {
        var cachedData = await _cache.GetStringAsync(key);
        if (cachedData != null)
        {
            return JsonSerializer.Deserialize<T>(cachedData);
        }

        var data = await factory();
        var options = new DistributedCacheEntryOptions
        {
            SlidingExpiration = expiration ?? TimeSpan.FromMinutes(15)
        };

        await _cache.SetStringAsync(
            key,
            JsonSerializer.Serialize(data),
            options);

        return data;
    }

    // 缓存预热
    public async Task PreloadCacheAsync()
    {
        var popularCategories = new[] { "股票型", "混合型", "债券型", "货币型" };

        foreach (var category in popularCategories)
        {
            var cacheKey = $"fund_rankings_{category}";
            var rankings = await _fundService.GetFundRankingsAsync(category);

            await SetAsync(cacheKey, rankings, TimeSpan.FromHours(1));
        }
    }
}
```

## 10. 扩展性和演进

### 10.1 微服务拆分
```
未来架构演进方向:
┌─────────────────────────────────────────────────────────┐
│                  API Gateway                             │
├─────────────────────────────────────────────────────────┤
│              Service Mesh (Istio)                        │
├─────────────────────────────────────────────────────────┤
│           Microservices Architecture                     │
│  ┌─────────────┬──────────────┬────────────────────┐   │
│  │Fund Service │User Service  │Analytics Service   │   │
│  │├───────────┐│├───────────┐  │├───────────────┐  │   │
│  ││Ranking    │││Profile    │  ││Real-time      │  │   │
│  ││Search     │││Auth       │  ││Batch          │  │   │
│  ││Details    │││Settings   │  ││ML Pipeline    │  │   │
│  │└───────────┘│└───────────┘  │└───────────────┘  │   │
│  ├─────────────┼──────────────┼────────────────────┤   │
│  │Portfolio    │Notification   │Recommendation      │   │
│  │Service      │Service        │Service             │   │
│  └─────────────┴──────────────┴────────────────────┘   │
├─────────────────────────────────────────────────────────┤
│              Data Platform                               │
│  ┌─────────────┬──────────────┬────────────────────┐   │
│  │PostgreSQL   │MongoDB       │Elasticsearch       │   │
│  │(Transaction)│(Document)    │(Search)            │   │
│  └─────────────┴──────────────┴────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

### 10.2 技术演进路线
```
Phase 1 (当前): 基础架构完成
├── Flutter前端开发
├── ASP.NET Core API服务
├── 基础数据架构
└── 简单部署方案

Phase 2 (3-6个月): 性能优化
├── 微服务架构拆分
├── 缓存层优化
├── 数据库分库分表
└── CDN加速

Phase 3 (6-12个月): 智能化
├── 机器学习推荐系统
├── 实时数据分析
├── 智能预警系统
└── A/B测试平台

Phase 4 (12个月+): 生态化
├── 第三方集成平台
├── 开放API生态
├── 多租户架构
└── 全球化部署
```

### 10.3 监控告警体系
```yaml
# 监控指标定义
groups:
- name: fund-app-alerts
  rules:
  - alert: HighErrorRate
    expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.1
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "High error rate detected"
      description: "Error rate is {{ $value }}% for {{ $labels.service }}"

  - alert: HighLatency
    expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 0.5
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High latency detected"
      description: "95th percentile latency is {{ $value }}s for {{ $labels.service }}"

  - alert: HighMemoryUsage
    expr: process_resident_memory_bytes / 1024 / 1024 > 512
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High memory usage"
      description: "Memory usage is {{ $value }}MB for {{ $labels.instance }}"
```

---

**架构版本**: v1.0
**创建日期**: 2025-09-26
**架构团队**: 猫娘工程师-幽浮喵
**审核状态**: 待审核
**最后更新**: 2025-09-26