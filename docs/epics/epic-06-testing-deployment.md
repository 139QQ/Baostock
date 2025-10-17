# Epic 6: 测试和部署

## 史诗概述
建立完整的测试体系和部署流程，包括单元测试和集成测试、性能测试、多平台部署以及监控和运维。通过系统化的测试验证和自动化的部署流程，确保应用质量并支持持续交付。

## 史诗目标
- 建立完善的测试体系，实现代码覆盖率>85%，自动化测试通过率>95%
- 构建性能测试平台，确保应用在各种负载下的稳定性和性能指标
- 实现多平台自动化部署，支持Web、移动端、桌面端的一键部署
- 建立完整的监控和运维体系，实现7×24小时实时监控和告警
- 构建CI/CD流水线，支持持续集成和持续交付

## 功能范围

### 1. 单元测试和集成测试
**测试框架搭建:**
```dart
// 测试配置
class TestConfig {
  static const String baseUrl = 'http://localhost:8080';
  static const Duration timeout = Duration(seconds: 30);
  static const bool enableLogging = true;

  // 测试数据配置
  static const String testUserPhone = '13800138000';
  static const String testUserCode = '123456';
  static const String testFundCode = '000001';
}

// 测试工具类
class TestUtils {
  // 创建测试用BLoC
  static T createTestBloc<T>(List<dynamic> dependencies) {
    return _createBlocWithMockDependencies<T>(dependencies);
  }

  // 创建Mock数据
  static FundRanking createMockFundRanking({
    String fundCode = '000001',
    String fundName = '测试基金',
    double returnRate = 10.5,
  }) {
    return FundRanking(
      fundCode: fundCode,
      fundName: fundName,
      category: '股票型',
      rankingPosition: 1,
      returnRate: returnRate,
      rankingPeriod: '1Y',
      rankingDate: DateTime.now(),
      totalCount: 100,
    );
  }

  // 创建Mock API响应
  static http.Response createMockResponse(
    dynamic data, {
    int statusCode = 200,
    Map<String, String> headers = const {},
  }) {
    return http.Response(
      jsonEncode(data),
      statusCode,
      headers: {
        'content-type': 'application/json',
        ...headers,
      },
    );
  }
}
```

**单元测试示例:**
```dart
// BLoC单元测试
group('FundRankingBloc', () {
  late FundRankingBloc bloc;
  late MockGetFundRankings mockGetFundRankings;
  late MockCacheService mockCacheService;

  setUp(() {
    mockGetFundRankings = MockGetFundRankings();
    mockCacheService = MockCacheService();

    bloc = FundRankingBloc(
      getFundRankings: mockGetFundRankings,
      cacheService: mockCacheService,
    );
  });

  tearDown(() {
    bloc.close();
  });

  blocTest<FundRankingBloc, FundRankingState>(
    'emits [loading, success] when LoadFundRankings is added and data is fetched successfully',
    build: () {
      when(mockCacheService.get<List<FundRanking>>(any))
          .thenAnswer((_) async => null);

      when(mockGetFundRankings(any))
          .thenAnswer((_) async => [
            TestUtils.createMockFundRanking(),
            TestUtils.createMockFundRanking(fundCode: '000002'),
          ]);

      return bloc;
    },
    act: (bloc) => bloc.add(LoadFundRankings(category: '股票型')),
    expect: () => [
      FundRankingState.initial().copyWith(status: LoadStatus.loading),
      FundRankingState.initial().copyWith(
        status: LoadStatus.success,
        rankings: [
          TestUtils.createMockFundRanking(),
          TestUtils.createMockFundRanking(fundCode: '000002'),
        ],
      ),
    ],
  );

  blocTest<FundRankingBloc, FundRankingState>(
    'emits [loading, error] when LoadFundRankings is added and data fetching fails',
    build: () {
      when(mockCacheService.get<List<FundRanking>>(any))
          .thenAnswer((_) async => null);

      when(mockGetFundRankings(any))
          .thenThrow(Exception('Network error'));

      return bloc;
    },
    act: (bloc) => bloc.add(LoadFundRankings(category: '股票型')),
    expect: () => [
      FundRankingState.initial().copyWith(status: LoadStatus.loading),
      FundRankingState.initial().copyWith(
        status: LoadStatus.error,
        error: 'Exception: Network error',
      ),
    ],
  );

  blocTest<FundRankingBloc, FundRankingState>(
    'uses cached data when available',
    build: () {
      final cachedRankings = [
        TestUtils.createMockFundRanking(),
      ];

      when(mockCacheService.get<List<FundRanking>>(any))
          .thenAnswer((_) async => cachedRankings);

      return bloc;
    },
    act: (bloc) => bloc.add(LoadFundRankings(category: '股票型')),
    expect: () => [
      FundRankingState.initial().copyWith(
        status: LoadStatus.success,
        rankings: [TestUtils.createMockFundRanking()],
      ),
    ],
    verify: (_) {
      verifyNever(mockGetFundRankings(any));
    },
  );
});
```

**Repository集成测试:**
```dart
// Repository集成测试
group('FundRepository', () {
  late FundRepository repository;
  late MockApiClient mockApiClient;
  late MockCacheService mockCacheService;

  setUp(() {
    mockApiClient = MockApiClient();
    mockCacheService = MockCacheService();
    repository = FundRepository(
      apiClient: mockApiClient,
      cacheService: mockCacheService,
    );
  });

  group('getFundRankings', () {
    test('returns fund rankings from API when cache is empty', () async {
      // Arrange
      final mockResponse = [
        {
          'fundCode': '000001',
          'fundName': '测试基金1',
          'category': '股票型',
          'rankingPosition': 1,
          'returnRate': 15.5,
          'rankingPeriod': '1Y',
          'rankingDate': '2024-01-01',
          'totalCount': 100,
        },
      ];

      when(mockCacheService.get<List<FundRanking>>(any))
          .thenAnswer((_) async => null);

      when(mockApiClient.get(any, queryParameters: anyNamed('queryParameters')))
          .thenAnswer((_) async => mockResponse);

      // Act
      final result = await repository.getFundRankings('股票型');

      // Assert
      expect(result, isA<List<FundRanking>>());
      expect(result.length, 1);
      expect(result.first.fundCode, '000001');
      expect(result.first.fundName, '测试基金1');

      // Verify cache was set
      verify(mockCacheService.set(
        argThat(contains('fund_rankings_股票型')),
        any,
        expiration: anyNamed('expiration'),
      )).called(1);
    });

    test('returns cached data when available', () async {
      // Arrange
      final cachedData = [
        TestUtils.createMockFundRanking(),
      ];

      when(mockCacheService.get<List<FundRanking>>(any))
          .thenAnswer((_) async => cachedData);

      // Act
      final result = await repository.getFundRankings('股票型');

      // Assert
      expect(result, equals(cachedData));

      // Verify API was not called
      verifyNever(mockApiClient.get(any, queryParameters: anyNamed('queryParameters')));
    });

    test('falls back to mock data when API fails', () async {
      // Arrange
      when(mockCacheService.get<List<FundRanking>>(any))
          .thenAnswer((_) async => null);

      when(mockApiClient.get(any, queryParameters: anyNamed('queryParameters')))
          .thenThrow(DioException(
        requestOptions: RequestOptions(path: '/fund/rankings/股票型'),
        error: 'Network error',
      ));

      // Act
      final result = await repository.getFundRankings('股票型');

      // Assert
      expect(result, isA<List<FundRanking>>());
      expect(result.isNotEmpty, true); // Should return mock data
    });
  });
});
```

**Widget测试:**
```dart
// Widget测试
group('FundRankingCard', () {
  testWidgets('displays fund information correctly', (WidgetTester tester) async {
    // Arrange
    final fundRanking = TestUtils.createMockFundRanking(
      fundCode: '000001',
      fundName: '华夏成长混合',
      returnRate: 12.5,
    );

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FundRankingCard(
            ranking: fundRanking,
            index: 1,
          ),
        ),
      ),
    );

    // Assert
    expect(find.text('华夏成长混合'), findsOneWidget);
    expect(find.text('000001'), findsOneWidget);
    expect(find.text('12.50%'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('navigates to fund detail on tap', (WidgetTester tester) async {
    // Arrange
    final fundRanking = TestUtils.createMockFundRanking();
    final mockNavigator = MockNavigator();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Navigator(
            onGenerateRoute: (settings) => MaterialPageRoute(
              builder: (context) => FundRankingCard(
                ranking: fundRanking,
                index: 1,
              ),
            ),
          ),
        ),
      ),
    );

    // Act
    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();

    // Assert
    // Verify navigation occurred
  });

  testWidgets('shows correct color for positive returns', (WidgetTester tester) async {
    // Arrange
    final fundRanking = TestUtils.createMockFundRanking(returnRate: 10.0);

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FundRankingCard(
            ranking: fundRanking,
            index: 1,
          ),
        ),
      ),
    );

    // Assert
    final returnText = tester.widget<Text>(find.text('10.00%'));
    expect(returnText.style?.color, equals(Colors.red));
  });

  testWidgets('shows correct color for negative returns', (WidgetTester tester) async {
    // Arrange
    final fundRanking = TestUtils.createMockFundRanking(returnRate: -5.0);

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FundRankingCard(
            ranking: fundRanking,
            index: 1,
          ),
        ),
      ),
    );

    // Assert
    final returnText = tester.widget<Text>(find.text('-5.00%'));
    expect(returnText.style?.color, equals(Colors.green));
  });
});
```

### 2. 性能测试
**性能测试框架:**
```dart
// 性能测试工具类
class PerformanceTestUtils {
  // 测量Widget构建时间
  static Future<Duration> measureWidgetBuildTime(
    Widget widget, {
    int iterations = 100,
  }) async {
    final stopwatch = Stopwatch()..start();

    for (int i = 0; i < iterations; i++) {
      await TestWidgetsFlutterBinding.ensureInitialized()
          .wrapWithDefaultView(widget);
    }

    stopwatch.stop();
    return stopwatch.elapsed;
  }

  // 测量异步操作时间
  static Future<Duration> measureAsyncOperation(
    Future<void> Function() operation, {
    int iterations = 10,
  }) async {
    final stopwatch = Stopwatch()..start();

    for (int i = 0; i < iterations; i++) {
      await operation();
    }

    stopwatch.stop();
    return stopwatch.elapsed;
  }

  // 模拟内存压力
  static Future<void> simulateMemoryPressure() async {
    final List<List<int>> memoryHog = [];

    // 分配大量内存
    for (int i = 0; i < 1000; i++) {
      memoryHog.add(List<int>.generate(10000, (index) => index));
    }

    // 等待一段时间
    await Future.delayed(Duration(seconds: 2));

    // 释放内存
    memoryHog.clear();
  }

  // 模拟网络延迟
  static Future<void> simulateNetworkDelay(Duration delay) async {
    await Future.delayed(delay);
  }
}
```

**性能测试用例:**
```dart
// 基金排行性能测试
group('Fund Ranking Performance Tests', () {
  test('fund ranking list performance with large dataset', () async {
    // Arrange
    final largeDataset = List<FundRanking>.generate(
      1000,
      (index) => TestUtils.createMockFundRanking(
        fundCode: '${index.toString().padLeft(6, '0')}',
        fundName: '测试基金$index',
      ),
    );

    // Act & Measure
    final buildTime = await PerformanceTestUtils.measureWidgetBuildTime(
      ListView.builder(
        itemCount: largeDataset.length,
        itemBuilder: (context, index) => FundRankingCard(
          ranking: largeDataset[index],
          index: index + 1,
        ),
      ),
      iterations: 10,
    );

    // Assert
    print('构建1000个基金卡片耗时: ${buildTime.inMilliseconds}ms');
    expect(buildTime.inMilliseconds, lessThan(1000)); // 1秒内完成
  });

  test('fund search performance', () async {
    // Arrange
    final searchTerms = ['华夏', '易方达', '嘉实', '南方', '广发'];
    final mockSearchResults = List<FundInfo>.generate(
      100,
      (index) => FundInfo(
        fundCode: '${index.toString().padLeft(6, '0')}',
        fundName: '测试基金${index % 5}_${index}',
        fundType: '股票型',
        companyCode: 'COMP${index % 10}',
        companyName: '测试公司${index % 10}',
      ),
    );

    // Act & Measure
    final searchTime = await PerformanceTestUtils.measureAsyncOperation(() async {
      for (final term in searchTerms) {
        final results = mockSearchResults
            .where((fund) => fund.fundName.contains(term))
            .toList();
        expect(results.isNotEmpty, true);
      }
    });

    // Assert
    print('搜索性能测试耗时: ${searchTime.inMilliseconds}ms');
    expect(searchTime.inMilliseconds, lessThan(500)); // 500ms内完成
  });

  test('memory usage during fund detail rendering', () async {
    // Arrange
    final fundDetail = FundDetail(
      fundCode: '000001',
      fundName: '测试基金',
      fundType: '股票型',
      companyName: '测试公司',
      currentNav: 1.2345,
      dailyReturn: 1.5,
      // 大量历史数据
      navHistory: List<FundNav>.generate(
        1000,
        (index) => FundNav(
          fundCode: '000001',
          navDate: DateTime.now().subtract(Duration(days: index)),
          unitNav: 1.0 + index * 0.001,
          accumulatedNav: 1.0 + index * 0.001,
          dailyReturn: Random().nextDouble() * 2 - 1,
        ),
      ),
    );

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FundDetailsView(),
        ),
      ),
    );

    // Simulate memory pressure
    await PerformanceTestUtils.simulateMemoryPressure();

    // Assert
    // Verify that the widget still renders correctly under memory pressure
    expect(find.text('测试基金'), findsOneWidget);
  });
});
```

**负载测试:**
```dart
// API负载测试
group('API Load Tests', () {
  test('concurrent API requests handling', () async {
    // Arrange
    final apiClient = ApiClient(TestConfig.baseUrl);
    final concurrentRequests = 50;
    final stopwatch = Stopwatch()..start();

    // Act
    final futures = List<Future<List<FundRanking>>>.generate(
      concurrentRequests,
      (index) => apiClient.getFundRankings('股票型', page: 1, pageSize: 20),
    );

    final results = await Future.wait(futures);
    stopwatch.stop();

    // Assert
    expect(results.length, concurrentRequests);
    expect(results.every((list) => list.isNotEmpty), true);
    print('并发请求测试: $concurrentRequests个请求耗时: ${stopwatch.elapsed.inMilliseconds}ms');
    expect(stopwatch.elapsed.inSeconds, lessThan(30)); // 30秒内完成
  });

  test('API response time under load', () async {
    // Arrange
    final apiClient = ApiClient(TestConfig.baseUrl);
    final requestCount = 100;
    final responseTimes = <Duration>[];

    // Act
    for (int i = 0; i < requestCount; i++) {
      final stopwatch = Stopwatch()..start();
      await apiClient.getFundRankings('股票型', page: 1, pageSize: 20);
      stopwatch.stop();
      responseTimes.add(stopwatch.elapsed);
    }

    // Calculate statistics
    final totalTime = responseTimes.fold(Duration.zero, (sum, time) => sum + time);
    final averageTime = totalTime ~/ requestCount;
    final sortedTimes = responseTimes..sort();
    final p95Time = sortedTimes[(requestCount * 0.95).round()];

    // Assert
    print('API响应时间统计:');
    print('平均响应时间: ${averageTime.inMilliseconds}ms');
    print('95分位响应时间: ${p95Time.inMilliseconds}ms');

    expect(averageTime.inMilliseconds, lessThan(500)); // 平均响应时间<500ms
    expect(p95Time.inMilliseconds, lessThan(1000)); // 95分位响应时间<1s
  });
});
```

### 3. 多平台部署
**Docker化部署:**
```dockerfile
# Flutter Web Dockerfile
FROM nginx:alpine

# 安装必要的工具
RUN apk add --no-cache curl

# 设置工作目录
WORKDIR /usr/share/nginx/html

# 复制构建产物
COPY build/web/ .

# 复制nginx配置
COPY nginx.conf /etc/nginx/nginx.conf

# 创建健康检查脚本
RUN echo 'location /health { \
    access_log off; \
    return 200 "healthy\n"; \
    add_header Content-Type text/plain; \
}' >> /etc/nginx/conf.d/default.conf

# 设置文件权限
RUN chown -R nginx:nginx /usr/share/nginx/html

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/health || exit 1

# 暴露端口
EXPOSE 80

# 启动nginx
CMD ["nginx", "-g", "daemon off;"]
```

```dockerfile
# ASP.NET Core API Dockerfile
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
RUN dotnet publish "FundService.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .

# 添加健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:80/health || exit 1

ENTRYPOINT ["dotnet", "FundService.dll"]
```

**Kubernetes部署配置:**
```yaml
# Web应用部署
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fund-web-app
  labels:
    app: fund-web-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: fund-web-app
  template:
    metadata:
      labels:
        app: fund-web-app
    spec:
      containers:
      - name: fund-web-app
        image: fund-web-app:latest
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
        livenessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
        env:
        - name: ENVIRONMENT
          value: "production"
        - name: API_BASE_URL
          value: "http://fund-api-service:80"
      imagePullSecrets:
      - name: regcred
---
apiVersion: v1
kind: Service
metadata:
  name: fund-web-app-service
spec:
  selector:
    app: fund-web-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: fund-web-app-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
  - hosts:
    - fund.jisuquant.com
    secretName: fund-web-app-tls
  rules:
  - host: fund.jisuquant.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: fund-web-app-service
            port:
              number: 80
```

**移动端构建配置:**
```yaml
# iOS构建配置
# ios/fastlane/Fastfile
default_platform(:ios)

platform :ios do
  desc "Build iOS app"
  lane :build do
    # 安装依赖
    sh "flutter pub get"

    # 构建iOS应用
    sh "flutter build ios --release --no-codesign"

    # 打包
    gym(
      workspace: "Runner.xcworkspace",
      scheme: "Runner",
      configuration: "Release",
      export_method: "app-store",
      export_options: {
        provisioningProfiles: {
          "com.jisuquant.fund" => "JiSu Fund App Store Distribution"
        }
      }
    )
  end

  desc "Deploy to TestFlight"
  lane :deploy_testflight do
    build

    # 上传到TestFlight
    upload_to_testflight(
      skip_waiting_for_build_processing: true,
      notify_external_testers: false
    )
  end

  desc "Deploy to App Store"
  lane :deploy_app_store do
    build

    # 上传到App Store
    upload_to_app_store(
      force: true,
      skip_metadata: false,
      skip_screenshots: false,
      submit_for_review: false
    )
  end
end
```

```yaml
# Android构建配置
# android/fastlane/Fastfile
default_platform(:android)

platform :android do
  desc "Build Android app"
  lane :build do
    # 安装依赖
    sh "flutter pub get"

    # 构建Android应用
    sh "flutter build apk --release"

    # 构建AAB
    sh "flutter build appbundle --release"
  end

  desc "Deploy to Google Play Internal Testing"
  lane :deploy_internal do
    build

    # 上传到内部测试
    upload_to_play_store(
      track: 'internal',
      aab: '../build/app/outputs/bundle/release/app-release.aab',
      skip_upload_metadata: true,
      skip_upload_images: true,
      skip_upload_screenshots: true
    )
  end

  desc "Deploy to Google Play Production"
  lane :deploy_production do
    build

    # 上传到生产环境
    upload_to_play_store(
      track: 'production',
      aab: '../build/app/outputs/bundle/release/app-release.aab',
      skip_upload_metadata: false,
      skip_upload_images: false,
      skip_upload_screenshots: false
    )
  end
end
```

### 4. 监控和运维
**应用性能监控:**
```dart
// 性能监控服务
class PerformanceMonitoringService {
  static final PerformanceMonitoringService _instance =
      PerformanceMonitoringService._internal();
  factory PerformanceMonitoringService() => _instance;
  PerformanceMonitoringService._internal();

  bool _isInitialized = false;

  // 初始化监控服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 初始化Firebase Performance
      await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);

      // 初始化Sentry
      await SentryFlutter.init(
        (options) {
          options.dsn = 'https://your-sentry-dsn@sentry.io/project-id';
          options.tracesSampleRate = 1.0;
          options.profilesSampleRate = 1.0;
        },
      );

      _isInitialized = true;
      print('Performance monitoring initialized');
    } catch (e) {
      print('Failed to initialize performance monitoring: $e');
    }
  }

  // 开始性能跟踪
  Future<T> trackPerformance<T>({
    required String name,
    required Future<T> Function() operation,
    Map<String, dynamic>? attributes,
  }) async {
    if (!_isInitialized) return await operation();

    final trace = FirebasePerformance.instance.newTrace(name);

    try {
      await trace.start();

      // 设置属性
      if (attributes != null) {
        attributes.forEach((key, value) {
          trace.putAttribute(key, value.toString());
        });
      }

      // 执行操作
      final result = await operation();

      // 标记成功
      trace.putAttribute('status', 'success');

      return result;
    } catch (e) {
      // 标记失败
      trace.putAttribute('status', 'error');
      trace.putAttribute('error', e.toString());
      rethrow;
    } finally {
      await trace.stop();
    }
  }

  // 跟踪Widget构建性能
  void trackWidgetBuild(String widgetName, VoidCallback buildFunction) {
    if (!_isInitialized) {
      buildFunction();
      return;
    }

    final span = Sentry.getSpan()?.startChild('widget.build', desc: widgetName);

    try {
      buildFunction();
      span?.setStatus(SpanStatus.ok());
    } catch (e) {
      span?.setStatus(SpanStatus.internalError());
      span?.throwable = e;
      rethrow;
    } finally {
      span?.finish();
    }
  }

  // 记录自定义指标
  void recordMetric(String name, double value, {String? unit}) {
    if (!_isInitialized) return;

    // 发送到Firebase Analytics
    FirebaseAnalytics.instance.logEvent(
      name: 'performance_metric',
      parameters: {
        'metric_name': name,
        'value': value,
        if (unit != null) 'unit': unit,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    // 发送到Sentry
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: 'Performance metric: $name = $value${unit ?? ''}',
        category: 'performance',
        data: {
          'metric_name': name,
          'value': value,
          if (unit != null) 'unit': unit,
        },
      ),
    );
  }
}
```

**错误监控和日志:**
```dart
// 错误监控服务
class ErrorMonitoringService {
  static final ErrorMonitoringService _instance =
      ErrorMonitoringService._internal();
  factory ErrorMonitoringService() => _instance;
  ErrorMonitoringService._internal();

  bool _isInitialized = false;

  // 初始化错误监控
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 设置Flutter错误处理器
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        _recordFlutterError(details);
      };

      // 设置平台通道错误处理器
      PlatformDispatcher.instance.onError = (error, stack) {
        _recordPlatformError(error, stack);
        return true;
      };

      // 设置异步错误处理器
      runZonedGuarded(
        () {
          // 应用主函数将在外部调用
        },
        (error, stackTrace) {
          _recordAsyncError(error, stackTrace);
        },
      );

      _isInitialized = true;
      print('Error monitoring initialized');
    } catch (e) {
      print('Failed to initialize error monitoring: $e');
    }
  }

  // 记录Flutter错误
  void _recordFlutterError(FlutterErrorDetails details) {
    final error = details.exception;
    final stackTrace = details.stack;

    // 发送到Sentry
    Sentry.captureException(
      error,
      stackTrace: stackTrace,
      hint: 'Flutter Framework Error',
    );

    // 记录到控制台
    print('Flutter Error: $error');
    print('Stack Trace: $stackTrace');

    // 显示用户友好的错误提示
    if (details.context != null) {
      _showErrorDialog('发生错误', '很抱歉，应用遇到了问题。请稍后重试。');
    }
  }

  // 记录平台错误
  void _recordPlatformError(Object error, StackTrace stackTrace) {
    // 发送到Sentry
    Sentry.captureException(
      error,
      stackTrace: stackTrace,
      hint: 'Platform Error',
    );

    // 记录到控制台
    print('Platform Error: $error');
    print('Stack Trace: $stackTrace');
  }

  // 记录异步错误
  void _recordAsyncError(Object error, StackTrace stackTrace) {
    // 发送到Sentry
    Sentry.captureException(
      error,
      stackTrace: stackTrace,
      hint: 'Async Error',
    );

    // 记录到控制台
    print('Async Error: $error');
    print('Stack Trace: $stackTrace');
  }

  // 记录自定义错误
  void recordError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? extra,
  }) {
    // 发送到Sentry
    Sentry.captureException(
      error,
      stackTrace: stackTrace,
      hint: context ?? 'Custom Error',
    );

    // 记录到本地日志
    _logError(error, stackTrace, context, extra);
  }

  // 记录错误到本地日志
  void _logError(
    dynamic error,
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? extra,
  ) {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = {
      'timestamp': timestamp,
      'level': 'ERROR',
      'message': error.toString(),
      'context': context,
      'stackTrace': stackTrace?.toString(),
      'extra': extra,
      'platform': Platform.operatingSystem,
      'appVersion': _getAppVersion(),
    };

    // 写入本地日志文件
    _writeToLogFile(jsonEncode(logEntry));
  }

  // 显示错误对话框
  void _showErrorDialog(String title, String message) {
    // 使用全局上下文显示对话框
    // 这里需要实现全局对话框显示机制
  }

  // 获取应用版本
  String _getAppVersion() {
    // 从包信息获取版本号
    return '1.0.0'; // 实际应该从PackageInfo获取
  }

  // 写入日志文件
  void _writeToLogFile(String logEntry) {
    // 实现日志文件写入逻辑
    // 可以按日期分割日志文件，定期清理旧日志
  }
}
```

**实时监控仪表板:**
```dart
// 监控数据模型
class MonitoringData {
  final DateTime timestamp;
  final Map<String, dynamic> metrics;
  final List<AppError> errors;
  final List<String> warnings;

  MonitoringData({
    required this.timestamp,
    required this.metrics,
    required this.errors,
    required this.warnings,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'metrics': metrics,
    'errors': errors.map((e) => {
      'message': e.message,
      'type': e.type.toString(),
    }).toList(),
    'warnings': warnings,
  };
}

// 监控服务
class MonitoringService {
  static final MonitoringService _instance = MonitoringService._internal();
  factory MonitoringService() => _instance;
  MonitoringService._internal();

  Timer? _monitoringTimer;
  final StreamController<MonitoringData> _dataStreamController =
      StreamController.broadcast();

  // 开始监控
  void startMonitoring() {
    _monitoringTimer = Timer.periodic(Duration(minutes: 1), (_) {
      _collectMonitoringData();
    });
  }

  // 收集监控数据
  Future<void> _collectMonitoringData() async {
    try {
      final metrics = await _collectMetrics();
      final errors = await _collectErrors();
      final warnings = await _collectWarnings();

      final data = MonitoringData(
        timestamp: DateTime.now(),
        metrics: metrics,
        errors: errors,
        warnings: warnings,
      );

      _dataStreamController.add(data);

      // 发送到远程监控服务
      await _sendToRemoteMonitoring(data);
    } catch (e) {
      print('Failed to collect monitoring data: $e');
    }
  }

  // 收集性能指标
  Future<Map<String, dynamic>> _collectMetrics() async {
    final memoryInfo = await MemoryManager().getMemoryInfo();

    return {
      'memory_usage_mb': memoryInfo.currentRSS / (1024 * 1024),
      'memory_usage_percentage': memoryInfo.usagePercentage,
      'active_users': await _getActiveUserCount(),
      'api_requests_per_minute': await _getApiRequestRate(),
      'average_response_time_ms': await _getAverageResponseTime(),
      'cache_hit_rate': await _getCacheHitRate(),
      'app_version': _getAppVersion(),
      'platform': Platform.operatingSystem,
    };
  }

  // 收集错误信息
  Future<List<AppError>> _collectErrors() async {
    // 从错误日志中收集最近一小时内的错误
    return await _getRecentErrors(Duration(hours: 1));
  }

  // 收集警告信息
  Future<List<String>> _collectWarnings() async {
    final warnings = <String>[];

    // 检查内存使用
    final memoryInfo = await MemoryManager().getMemoryInfo();
    if (memoryInfo.usagePercentage > 80) {
      warnings.add('High memory usage: ${memoryInfo.usagePercentage.toStringAsFixed(1)}%');
    }

    // 检查API响应时间
    final avgResponseTime = await _getAverageResponseTime();
    if (avgResponseTime > 1000) {
      warnings.add('High API response time: ${avgResponseTime}ms');
    }

    return warnings;
  }

  // 发送到远程监控服务
  Future<void> _sendToRemoteMonitoring(MonitoringData data) async {
    try {
      final response = await http.post(
        Uri.parse('https://monitoring.jisuquant.com/api/metrics'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getMonitoringToken()}',
        },
        body: jsonEncode(data.toJson()),
      );

      if (response.statusCode != 200) {
        print('Failed to send monitoring data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending monitoring data: $e');
    }
  }

  Stream<MonitoringData> get monitoringStream => _dataStreamController.stream;

  void dispose() {
    _monitoringTimer?.cancel();
    _dataStreamController.close();
  }
}
```

## 验收标准

### 测试覆盖率
- [ ] 单元测试覆盖率 > 85%
- [ ] 集成测试覆盖率 > 75%
- [ ] Widget测试覆盖率 > 80%
- [ ] 自动化测试通过率 > 95%

### 性能指标
- [ ] 压力测试支持1000并发用户
- [ ] API响应时间95分位 < 1秒
- [ ] 内存使用峰值 < 200MB
- [ ] 页面加载时间 < 3秒

### 部署和监控
- [ ] 支持一键多平台部署
- [ ] CI/CD流水线自动化程度 > 90%
- [ ] 监控覆盖率 > 95%
- [ ] 告警响应时间 < 5分钟

## 开发时间估算

### 工作量评估
- **单元测试和集成测试**: 48小时
- **性能测试**: 32小时
- **多平台部署**: 40小时
- **监控和运维**: 32小时
- **CI/CD流水线**: 24小时
- **文档和培训**: 16小时

**总计: 192小时（约24个工作日）**

## 依赖关系

### 前置依赖
- 所有功能开发完成
- 测试环境搭建完成
- 云服务账号和权限配置
- 监控平台接入完成

### 后续影响
- 确保产品质量和稳定性
- 支持持续交付和快速迭代
- 提供运维支持和故障排查能力

## 风险评估

### 技术风险
| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| 测试环境不稳定 | 中 | 中 | 准备多套测试环境 |
| 部署脚本失败 | 中 | 高 | 充分测试部署流程 |
| 监控数据丢失 | 低 | 高 | 多重备份和冗余 |

### 运维风险
| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| 生产环境故障 | 低 | 高 | 完善的回滚机制 |
| 监控误报 | 中 | 中 | 优化告警规则 |
| 性能瓶颈 | 中 | 中 | 持续性能优化 |

## 资源需求

### 人员配置
- **测试工程师**: 2人
- **DevOps工程师**: 2人
- **运维工程师**: 1人
- **安全工程师**: 1人（兼职）

### 技术资源
- 云服务平台账号
- 测试自动化工具
- 性能测试工具
- 监控和告警平台

## 交付物

### 代码交付
- 完整的测试用例代码
- 部署脚本和配置文件
- 监控和告警代码
- CI/CD流水线配置

### 文档交付
- 测试计划和报告
- 部署操作手册
- 监控配置文档
- 运维应急响应文档

### 测试交付
- 测试覆盖率报告
- 性能测试报告
- 安全测试报告
- 压力测试报告

---

**史诗负责人:** 质量保障经理
**预计开始时间:** 2026-02-26
**预计完成时间:** 2026-03-31
**优先级:** P0（最高）
**状态:** 待开始
**依赖史诗:** Epic 1, Epic 2, Epic 3, Epic 4, Epic 5