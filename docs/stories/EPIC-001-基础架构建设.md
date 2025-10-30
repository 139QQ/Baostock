# EPIC-001: 基础架构建设

## 🏗️ 史诗概述

**史诗目标**: 建立稳固的技术基础架构，为后续功能开发提供可靠的技术支撑。包括Flutter框架搭建、状态管理、网络通信、数据存储等核心基础设施。

**商业价值**:
- 技术基础: 为整个项目提供稳定可靠的技术基础
- 开发效率: 标准化的开发框架和工具链
- 质量保证: 建立代码质量和测试保障体系
- 团队协作: 统一的开发规范和协作流程

**开发时间**: 4周
**团队规模**: 3-4人
**依赖关系**: 无

---

## 📋 用户故事详细列表

### 🏗️ 基础框架建设

#### US-001.1: 搭建Flutter项目框架

**用户故事**: 作为开发工程师，我希望搭建一个标准化的Flutter项目框架，以便为整个项目提供统一的开发基础。

**优先级**: P0
**复杂度**: 中
**预估工期**: 2天
**依赖关系**: 无

**验收标准**:
- [ ] Flutter项目可以正常编译和运行
- [ ] 支持iOS、Android、Web三个平台
- [ ] 项目目录结构符合团队规范
- [ ] 基础依赖配置完整
- [ ] 应用图标和启动页配置正确

**技术要点**:
```yaml
Flutter版本: 3.16+
Dart版本: 3.2+
项目结构:
  lib/
  ├── core/           # 核心功能
  ├── data/           # 数据层
  ├── domain/         # 业务逻辑层
  ├── presentation/   # UI层
  └── main.dart       # 应用入口
依赖管理:
  flutter_riverpod: ^2.4.0  # 状态管理
  dio: ^5.3.0              # 网络请求
  hive: ^2.2.3             # 本地存储
  go_router: ^12.1.0       # 路由管理
  fl_chart: ^0.64.0        # 图表组件
```

**UI/UX要求**:
- 应用启动画面符合品牌设计
- 基础主题色彩和字体配置
- 适配不同屏幕尺寸

**测试要点**:
- 项目在不同平台的编译测试
- 基础功能启动测试
- 依赖版本兼容性测试

---

#### US-001.2: 配置开发环境和工具链

**用户故事**: 作为开发工程师，我希望配置完整的开发环境和工具链，以便提高开发效率和代码质量。

**优先级**: P0
**复杂度**: 中
**预估工期**: 2天
**依赖关系**: US-001.1

**验收标准**:
- [ ] 开发环境配置文档完整
- [ ] 代码格式化工具配置
- [ ] 静态代码分析工具集成
- [ ] Git hooks配置完成
- [ ] IDE插件推荐和配置

**技术要点**:
```yaml
开发工具:
  IDE: VS Code / Android Studio
  Flutter插件: Flutter, Dart, Code Runner
  版本控制: Git + GitLens

代码质量工具:
  格式化: dart format
  静态分析: dart analyze
  代码检查: very_good_analysis

Git Hooks:
  pre-commit: 代码格式化、静态分析
  pre-push: 单元测试执行
  commit-msg: 提交信息格式检查
```

**配置文件示例**:
```yaml
# analysis_options.yaml
include: package:very_good_analysis/analysis_options.yaml

linter:
  rules:
    prefer_single_quotes: true
    sort_constructors_first: true
    sort_unnamed_constructors_first: true

# .gitignore
# Flutter项目标准忽略文件
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
.pub-cache/
.pub/
/build/
```

**测试要点**:
- 工具链在不同开发环境的兼容性
- 代码质量检查规则的有效性
- Git hooks触发和执行正确性

---

#### US-001.3: 建立代码规范和质量检查

**用户故事**: 作为团队负责人，我希望建立统一的代码规范和质量检查机制，以便确保代码质量和团队协作效率。

**优先级**: P0
**复杂度**: 中
**预估工期**: 3天
**依赖关系**: US-001.2

**验收标准**:
- [ ] 代码规范文档完整且易懂
- [ ] 静态代码分析规则配置完成
- [ ] 代码覆盖率要求≥80%
- [ ] 代码审查流程建立
- [ ] 质量门禁配置完成

**代码规范要点**:
```yaml
命名规范:
  文件名: snake_case (example: user_service.dart)
  类名: PascalCase (example: UserService)
  变量名: camelCase (example: userName)
  常量名: SCREAMING_SNAKE_CASE (example: API_BASE_URL)

代码结构:
  文件长度: ≤300行
  函数长度: ≤50行
  类复杂度: ≤10
  嵌套层级: ≤3层

注释规范:
  公共API必须有文档注释
  复杂逻辑必须有行内注释
  TODO/FIXME标记格式规范
```

**质量检查配置**:
```yaml
# pubspec.yaml
dev_dependencies:
  test: ^1.24.0
  mockito: ^5.4.0
  build_runner: ^2.4.0
  json_serializable: ^6.7.0
  very_good_analysis: ^5.1.0

coverage:
  minimum: 80%
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
```

**测试要点**:
- 代码规范检查的准确性
- 质量门禁的触发条件
- 代码覆盖率统计的准确性

---

#### US-001.4: 配置CI/CD自动化流水线

**用户故事**: 作为DevOps工程师，我希望配置完整的CI/CD自动化流水线，以便实现自动化的构建、测试和部署。

**优先级**: P0
**复杂度**: 高
**预估工期**: 3天
**依赖关系**: US-001.3

**验收标准**:
- [ ] CI流水线配置完成且正常运行
- [ ] 自动化测试集成完成
- [ ] 构建产物自动生成
- [ ] 部署脚本配置完成
- [ ] 构建状态通知机制

**CI/CD配置**:
```yaml
# .github/workflows/flutter.yml
name: Flutter CI/CD

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: 'stable'
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v3

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter build apk --release
      - run: flutter build web --release
```

**部署配置**:
```yaml
部署环境:
  开发环境: 自动部署到测试服务器
  测试环境: 手动触发部署
  生产环境: 需要审批后部署

构建产物:
  Android: APK文件
  iOS: IPA文件
  Web: 静态文件包
```

**测试要点**:
- CI流水线的触发机制
- 测试执行和结果收集
- 构建过程稳定性
- 部署脚本正确性

---

### 🔄 状态管理架构

#### US-001.5: 实现BLoC状态管理架构

**用户故事**: 作为开发工程师，我希望实现BLoC状态管理架构，以便管理应用的状态和数据流。

**优先级**: P0
**复杂度**: 高
**预估工期**: 4天
**依赖关系**: US-001.1

**验收标准**:
- [ ] BLoC架构模式实现完整
- [ ] 状态管理逻辑清晰
- [ ] 状态持久化机制
- [ ] 错误处理机制完善
- [ ] 状态变更可追踪

**技术架构**:
```dart
// 基础BLoC抽象类
abstract class BaseBloc<Event, State> extends Bloc<Event, State> {
  BaseBloc(super.initialState);

  @override
  void onChange(Change<State> change) {
    super.onChange(change);
    // 状态变更日志记录
    log('${change.currentState} → ${change.nextState}');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    // 错误处理和日志记录
    log('BLoC Error: $error', stackTrace: stackTrace);
  }
}

// 用户状态管理示例
class UserBloc extends BaseBloc<UserEvent, UserState> {
  final UserRepository _userRepository;

  UserBloc(this._userRepository) : super(UserInitialState()) {
    on<LoadUserEvent>(_onLoadUser);
    on<UpdateUserEvent>(_onUpdateUser);
  }

  Future<void> _onLoadUser(
    LoadUserEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoadingState());
    try {
      final user = await _userRepository.getUser(event.userId);
      emit(UserLoadedState(user));
    } catch (e) {
      emit(UserErrorState(e.toString()));
    }
  }
}
```

**状态管理原则**:
- 单一数据源原则
- 状态不可变性
- 事件驱动状态变更
- 清晰的状态流转

**测试要点**:
- BLoC状态变更正确性
- 事件处理逻辑
- 错误状态处理
- 状态持久化功能

---

#### US-001.6: 建立全局状态管理机制

**用户故事**: 作为开发工程师，我希望建立全局状态管理机制，以便在应用各部分之间共享状态和数据。

**优先级**: P0
**复杂度**: 中
**预估工期**: 3天
**依赖关系**: US-001.5

**验收标准**:
- [ ] 全局状态提供者配置
- [ ] 状态在应用重启后持久化
- [ ] 跨页面状态共享正常
- [ ] 状态变更响应及时
- [ ] 内存使用优化

**全局状态架构**:
```dart
// 全局状态提供者
class AppProvider {
  static final AppProvider _instance = AppProvider._internal();
  factory AppProvider() => _instance;
  AppProvider._internal();

  late final UserBloc userBloc;
  late final ThemeBloc themeBloc;
  late final SettingsBloc settingsBloc;

  Future<void> initialize() async {
    // 初始化所有BLoC
    userBloc = UserBloc(UserRepository());
    themeBloc = ThemeBloc();
    settingsBloc = SettingsBloc();

    // 恢复持久化状态
    await _restorePersistedState();
  }

  Future<void> _restorePersistedState() async {
    // 从本地存储恢复状态
  }

  Future<void> dispose() async {
    await userBloc.close();
    await themeBloc.close();
    await settingsBloc.close();
  }
}

// 全局状态访问
final appProvider = Provider<AppProvider>((ref) => AppProvider());
```

**状态持久化**:
```dart
// 状态持久化工具
class StatePersistence {
  static const String _stateKey = 'app_state';

  static Future<void> saveState(Map<String, dynamic> state) async {
    final box = await Hive.openBox('app_state');
    await box.put(_stateKey, jsonEncode(state));
  }

  static Future<Map<String, dynamic>?> loadState() async {
    try {
      final box = await Hive.openBox('app_state');
      final stateJson = box.get(_stateKey);
      return stateJson != null ? jsonDecode(stateJson) : null;
    } catch (e) {
      return null;
    }
  }
}
```

**测试要点**:
- 全局状态初始化
- 状态持久化/恢复
- 跨页面状态同步
- 内存泄漏检查

---

#### US-001.7: 实现页面间状态同步

**用户故事**: 作为用户，我希望在不同页面之间切换时，应用状态能够正确同步，以便获得连续的使用体验。

**优先级**: P1
**复杂度**: 中
**预估工期**: 2天
**依赖关系**: US-001.6

**验收标准**:
- [ ] 页面切换时状态保持一致
- [ ] 返回页面时状态正确恢复
- [ ] 深度链接访问时状态正确
- [ ] 多Tab页面状态独立
- [ ] 页面重建时状态保持

**状态同步实现**:
```dart
// 页面状态管理
class PageStateContainer extends StatefulWidget {
  final Widget child;
  final String pageKey;

  const PageStateContainer({
    super.key,
    required this.child,
    required this.pageKey,
  });

  @override
  State<PageStateContainer> createState() => _PageStateContainerState();
}

class _PageStateContainerState extends State<PageStateContainer>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

// 路由状态同步
class AppRouter {
  static final GoRouter _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/fund/:id',
        builder: (context, state) {
          final fundId = state.pathParameters['id']!;
          return FundDetailPage(fundId: fundId);
        },
      ),
    ],
    redirect: (context, state) {
      // 路由重定向逻辑
      return null;
    },
  );
}
```

**测试要点**:
- 页面状态保持
- 路由参数传递
- 深度链接处理
- 内存使用优化

---

#### US-001.8: 建立状态持久化机制

**用户故事**: 作为用户，我希望应用的状态和数据能够持久化保存，以便在应用重启后能够恢复之前的设置和数据。

**优先级**: P1
**复杂度**: 中
**预估工期**: 3天
**依赖关系**: US-001.7

**验收标准**:
- [ ] 用户设置持久化保存
- [ ] 登录状态持久化
- [ ] 收藏数据持久化
- [ ] 应用配置持久化
- [ ] 数据迁移机制

**持久化实现**:
```dart
// 持久化服务接口
abstract class PersistenceService {
  Future<void> save<T>(String key, T value);
  Future<T?> get<T>(String key, T? defaultValue);
  Future<void> remove(String key);
  Future<void> clear();
}

// Hive持久化实现
class HivePersistenceService implements PersistenceService {
  late Box _box;

  Future<void> initialize() async {
    _box = await Hive.openBox('app_persistence');
  }

  @override
  Future<void> save<T>(String key, T value) async {
    await _box.put(key, value);
  }

  @override
  Future<T?> get<T>(String key, T? defaultValue) async {
    return _box.get(key, defaultValue: defaultValue);
  }

  @override
  Future<void> remove(String key) async {
    await _box.delete(key);
  }

  @override
  Future<void> clear() async {
    await _box.clear();
  }
}

// 状态持久化BLoC
class PersistedBloc<Event, State> extends Bloc<Event, State> {
  final String persistenceKey;
  final PersistenceService _persistenceService;

  PersistedBloc(
    super.initialState,
    this.persistenceKey,
    this._persistenceService,
  ) {
    _loadPersistedState();
  }

  Future<void> _loadPersistedState() async {
    final persistedState = await _persistenceService.get<State>(
      persistenceKey,
      state,
    );
    if (persistedState != state) {
      emit(persistedState);
    }
  }

  @override
  void onChange(Change<State> change) {
    super.onChange(change);
    _persistenceService.save(persistenceKey, change.nextState);
  }
}
```

**数据迁移**:
```dart
// 数据迁移管理
class MigrationManager {
  static const int _currentVersion = 1;
  static const String _versionKey = 'migration_version';

  static Future<void> runMigrations() async {
    final persistenceService = HivePersistenceService();
    await persistenceService.initialize();

    final currentVersion = await persistenceService.get<int>(
      _versionKey,
      0,
    );

    for (int version = currentVersion + 1; version <= _currentVersion; version++) {
      await _runMigration(version, persistenceService);
    }

    await persistenceService.save(_versionKey, _currentVersion);
  }

  static Future<void> _runMigration(
    int version,
    PersistenceService service,
  ) async {
    switch (version) {
      case 1:
        await _migrationV1(service);
        break;
      // 未来版本迁移逻辑
    }
  }

  static Future<void> _migrationV1(PersistenceService service) async {
    // V1版本数据迁移逻辑
  }
}
```

**测试要点**:
- 数据持久化准确性
- 数据迁移正确性
- 应用重启状态恢复
- 数据版本兼容性

---

### 🌐 网络通信架构

#### US-001.9: 配置HTTP客户端和API通信

**用户故事**: 作为开发工程师，我希望配置统一的HTTP客户端和API通信机制，以便与后端服务进行稳定高效的数据交互。

**优先级**: P0
**复杂度**: 中
**预估工期**: 3天
**依赖关系**: US-001.1

**验收标准**:
- [ ] HTTP客户端配置完整
- [ ] API请求封装完善
- [ ] 错误处理机制健全
- [ ] 网络状态监控
- [ ] 请求日志记录

**HTTP客户端实现**:
```dart
// API客户端配置
class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://api.baostock.com/v1',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _setupInterceptors();
  }

  void _setupInterceptors() {
    // 请求拦截器
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // 添加认证token
        final token = _getAuthToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        // 添加请求ID
        options.headers['X-Request-ID'] = _generateRequestId();

        // 记录请求日志
        log('API Request: ${options.method} ${options.path}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        // 记录响应日志
        log('API Response: ${response.statusCode} ${response.requestOptions.path}');
        handler.next(response);
      },
      onError: (error, handler) {
        // 错误处理和日志记录
        log('API Error: ${error.message}');
        _handleApiError(error);
        handler.next(error);
      },
    ));

    // 重试拦截器
    _dio.interceptors.add(RetryInterceptor(
      dio: _dio,
      options: const RetryOptions(
        retries: 3,
        retryInterval: Duration(seconds: 1),
      ),
    ));
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.get<T>(path, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}
```

**API服务封装**:
```dart
// 基金API服务
class FundApiService {
  final ApiClient _apiClient;

  FundApiService(this._apiClient);

  Future<List<Fund>> getFunds({
    int page = 1,
    int size = 20,
    String? type,
    String? sortBy,
  }) async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '/funds',
        queryParameters: {
          'page': page,
          'size': size,
          if (type != null) 'type': type,
          if (sortBy != null) 'sort_by': sortBy,
        },
      );

      final funds = response.data!
          .map((json) => Fund.fromJson(json as Map<String, dynamic>))
          .toList();

      return funds;
    } on DioException catch (e) {
      throw _handleApiException(e);
    }
  }

  Future<FundDetail> getFundDetail(String fundCode) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/funds/$fundCode',
      );

      return FundDetail.fromJson(response.data!);
    } on DioException catch (e) {
      throw _handleApiException(e);
    }
  }

  ApiException _handleApiException(DioException exception) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
        return const ApiException('连接超时，请检查网络连接');
      case DioExceptionType.receiveTimeout:
        return const ApiException('响应超时，请稍后重试');
      case DioExceptionType.badResponse:
        final statusCode = exception.response?.statusCode;
        switch (statusCode) {
          case 401:
            return const ApiException('未授权，请重新登录');
          case 403:
            return const ApiException('访问被拒绝');
          case 404:
            return const ApiException('请求的资源不存在');
          case 500:
            return const ApiException('服务器内部错误');
          default:
            return ApiException('请求失败: $statusCode');
        }
      default:
        return ApiException('网络错误: ${exception.message}');
    }
  }
}
```

**测试要点**:
- HTTP客户端配置正确性
- API请求/响应处理
- 错误处理机制
- 网络异常情况处理

---

#### US-001.10: 实现请求拦截和错误处理

**用户故事**: 作为开发工程师，我希望实现完善的请求拦截和错误处理机制，以便提供更好的用户体验和系统稳定性。

**优先级**: P0
**复杂度**: 中
**预估工期**: 2天
**依赖关系**: US-001.9

**验收标准**:
- [ ] 请求拦截器功能完整
- [ ] 响应拦截器正常工作
- [ ] 错误分类和处理完善
- [ ] 用户友好的错误提示
- [ ] 网络异常自动重试

**请求拦截实现**:
```dart
// 认证拦截器
class AuthInterceptor extends Interceptor {
  final TokenService _tokenService;

  AuthInterceptor(this._tokenService);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // 自动添加认证token
    final token = await _tokenService.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // 添加设备信息
    options.headers['X-Device-ID'] = await _getDeviceId();
    options.headers['X-App-Version'] = await _getAppVersion();

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // 处理认证错误
    if (err.response?.statusCode == 401) {
      try {
        // 尝试刷新token
        final newToken = await _tokenService.refreshToken();
        if (newToken != null) {
          // 重试原请求
          final retryOptions = err.requestOptions;
          retryOptions.headers['Authorization'] = 'Bearer $newToken';

          final response = await _retry(retryOptions);
          handler.resolve(response);
          return;
        }
      } catch (e) {
        // Token刷新失败，跳转登录页
        await _tokenService.clearTokens();
        _navigateToLogin();
      }
    }

    handler.next(err);
  }

  Future<Response> _retry(RequestOptions options) async {
    final dio = Dio();
    return dio.fetch(options);
  }
}

// 日志拦截器
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    log('🚀 API Request: ${options.method} ${options.uri}');
    if (options.data != null) {
      log('📤 Request Data: ${options.data}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    log('✅ API Response: ${response.statusCode} ${response.requestOptions.uri}');
    log('📥 Response Data: ${response.data}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    log('❌ API Error: ${err.message}');
    log('📍 Error URL: ${err.requestOptions.uri}');
    log('📊 Error Response: ${err.response?.data}');
    handler.next(err);
  }
}

// 缓存拦截器
class CacheInterceptor extends Interceptor {
  final CacheManager _cacheManager;

  CacheInterceptor(this._cacheManager);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // 检查缓存
    if (options.extra['cache'] == true) {
      final cachedResponse = await _cacheManager.get(options.uri.toString());
      if (cachedResponse != null) {
        handler.resolve(cachedResponse);
        return;
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    // 缓存响应
    if (response.requestOptions.extra['cache'] == true) {
      await _cacheManager.put(
        response.requestOptions.uri.toString(),
        response,
        ttl: const Duration(minutes: 5),
      );
    }
    handler.next(response);
  }
}
```

**错误处理机制**:
```dart
// 全局错误处理器
class GlobalErrorHandler {
  static void handleError(dynamic error, StackTrace? stackTrace) {
    // 记录错误日志
    log('Global Error: $error', stackTrace: stackTrace);

    // 上报错误到监控系统
    _reportError(error, stackTrace);

    // 显示用户友好的错误提示
    _showUserFriendlyMessage(error);
  }

  static void _reportError(dynamic error, StackTrace? stackTrace) {
    // 集成错误监控服务 (如Sentry)
    // Sentry.captureException(error, stackTrace: stackTrace);
  }

  static void _showUserFriendlyMessage(dynamic error) {
    String message;

    if (error is ApiException) {
      message = error.message;
    } else if (error is NetworkException) {
      message = '网络连接异常，请检查网络设置';
    } else if (error is ServerException) {
      message = '服务器暂时不可用，请稍后重试';
    } else {
      message = '发生未知错误，请联系客服';
    }

    // 使用Toast或其他方式显示错误信息
    _showErrorToast(message);
  }
}
```

**测试要点**:
- 拦截器功能正确性
- 错误处理覆盖性
- 自动重试机制
- 用户体验友好性

---

#### US-001.11: 建立网络状态监控机制

**用户故事**: 作为用户，我希望应用能够监控网络状态变化，并在网络异常时提供相应的提示和处理。

**优先级**: P1
**复杂度**: 中
**预估工期**: 2天
**依赖关系**: US-001.10

**验收标准**:
- [ ] 网络状态实时监控
- [ ] 网络变化时自动处理
- [ ] 离线模式支持
- [ ] 网络恢复时自动同步
- [ ] 用户友好的网络状态提示

**网络状态监控实现**:
```dart
// 网络状态服务
class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final StreamController<NetworkStatus> _statusController =
      StreamController<NetworkStatus>.broadcast();

  NetworkStatus _currentStatus = NetworkStatus.unknown;

  Stream<NetworkStatus> get statusStream => _statusController.stream;
  NetworkStatus get currentStatus => _currentStatus;
  bool get isConnected => _currentStatus == NetworkStatus.connected;

  Future<void> initialize() async {
    // 初始化网络状态监听
    await _setupNetworkMonitoring();
  }

  Future<void> _setupNetworkMonitoring() async {
    // 使用connectivity_plus包监听网络状态
    final connectivity = Connectivity();

    connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      _handleConnectivityChange(result);
    });

    // 获取初始网络状态
    final initialStatus = await connectivity.checkConnectivity();
    _handleConnectivityChange(initialStatus);
  }

  void _handleConnectivityChange(ConnectivityResult result) {
    final newStatus = _convertConnectivityResult(result);

    if (newStatus != _currentStatus) {
      _currentStatus = newStatus;
      _statusController.add(newStatus);

      log('Network status changed: $newStatus');

      // 处理网络状态变化
      _onNetworkStatusChanged(newStatus);
    }
  }

  NetworkStatus _convertConnectivityResult(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return NetworkStatus.connected;
      case ConnectivityResult.mobile:
        return NetworkStatus.connected;
      case ConnectivityResult.ethernet:
        return NetworkStatus.connected;
      case ConnectivityResult.none:
        return NetworkStatus.disconnected;
      default:
        return NetworkStatus.unknown;
    }
  }

  void _onNetworkStatusChanged(NetworkStatus status) {
    switch (status) {
      case NetworkStatus.connected:
        _onNetworkReconnected();
        break;
      case NetworkStatus.disconnected:
        _onNetworkDisconnected();
        break;
      case NetworkStatus.unknown:
        // 处理未知状态
        break;
    }
  }

  void _onNetworkReconnected() {
    // 网络恢复时的处理逻辑
    log('Network reconnected');

    // 显示网络恢复提示
    _showNetworkRestoredMessage();

    // 触发数据同步
    _triggerDataSync();
  }

  void _onNetworkDisconnected() {
    // 网络断开时的处理逻辑
    log('Network disconnected');

    // 显示网络断开提示
    _showNetworkLostMessage();

    // 启用离线模式
    _enableOfflineMode();
  }

  void _showNetworkRestoredMessage() {
    // 显示网络恢复的Toast消息
    showToast('网络已恢复');
  }

  void _showNetworkLostMessage() {
    // 显示网络断开的Toast消息
    showToast('网络连接已断开');
  }

  void _triggerDataSync() {
    // 触发数据同步逻辑
    // 可以通过事件总线通知其他组件
  }

  void _enableOfflineMode() {
    // 启用离线模式
    // 缓存用户操作，待网络恢复后同步
  }

  void dispose() {
    _statusController.close();
  }
}

enum NetworkStatus {
  connected,
  disconnected,
  unknown,
}
```

**离线队列实现**:
```dart
// 离线操作队列
class OfflineQueue {
  final Queue<OfflineOperation> _operations = Queue();
  final Isar _database;
  bool _isProcessing = false;

  OfflineQueue(this._database);

  Future<void> addOperation(OfflineOperation operation) async {
    // 保存操作到本地数据库
    await _database.writeTxn(() async {
      await _database.offlineOperations.put(operation);
    });

    // 如果网络连接，尝试处理操作
    if (NetworkService().isConnected && !_isProcessing) {
      await _processOperations();
    }
  }

  Future<void> _processOperations() async {
    if (_isProcessing) return;

    _isProcessing = true;

    try {
      while (NetworkService().isConnected) {
        final operation = await _getNextOperation();
        if (operation == null) break;

        try {
          await _executeOperation(operation);
          await _removeOperation(operation);
        } catch (e) {
          log('Failed to execute offline operation: $e');
          break; // 遇到错误停止处理
        }
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<OfflineOperation?> _getNextOperation() async {
    return await _database.readTxn(() async {
      return await _database.offlineOperations
          .where()
          .sortByCreatedAt()
          .findFirst();
    });
  }

  Future<void> _executeOperation(OfflineOperation operation) async {
    // 根据操作类型执行相应的API请求
    switch (operation.type) {
      case OperationType.create:
        await _executeCreateOperation(operation);
        break;
      case OperationType.update:
        await _executeUpdateOperation(operation);
        break;
      case OperationType.delete:
        await _executeDeleteOperation(operation);
        break;
    }
  }

  Future<void> _removeOperation(OfflineOperation operation) async {
    await _database.writeTxn(() async {
      await _database.offlineOperations.delete(operation.id!);
    });
  }
}
```

**测试要点**:
- 网络状态监测准确性
- 状态变化响应及时性
- 离线操作队列功能
- 网络恢复后数据同步

---

#### US-001.12: 实现API请求缓存策略

**用户故事**: 作为用户，我希望应用能够缓存常用的API请求数据，以便在网络不佳或离线时仍能快速访问数据。

**优先级**: P1
**复杂度**: 中
**预估工期**: 2天
**依赖关系**: US-001.11

**验收标准**:
- [ ] API响应数据自动缓存
- [ ] 缓存过期机制
- [ ] 离线时从缓存读取
- [ ] 缓存大小限制
- [ ] 缓存清理机制

**缓存策略实现**:
```dart
// 缓存管理器
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  final Map<String, CacheEntry> _memoryCache = {};
  final Isar _database;
  Timer? _cleanupTimer;

  static const int _maxMemoryCacheSize = 100;
  static const Duration _defaultTtl = Duration(minutes: 5);

  CacheManager(this._database) {
    _startCleanupTimer();
  }

  Future<Response?> get(String key) async {
    // 先检查内存缓存
    final memoryEntry = _memoryCache[key];
    if (memoryEntry != null && !memoryEntry.isExpired) {
      return memoryEntry.response;
    }

    // 检查持久化缓存
    final persistentEntry = await _getPersistentCache(key);
    if (persistentEntry != null && !persistentEntry.isExpired) {
      // 重新加载到内存缓存
      _memoryCache[key] = persistentEntry;
      return persistentEntry.response;
    }

    return null;
  }

  Future<void> put(
    String key,
    Response response, {
    Duration? ttl,
  }) async {
    final entry = CacheEntry(
      key: key,
      response: response,
      expiresAt: DateTime.now().add(ttl ?? _defaultTtl),
    );

    // 添加到内存缓存
    _memoryCache[key] = entry;
    _evictOldEntries();

    // 保存到持久化缓存
    await _savePersistentCache(entry);
  }

  Future<void> remove(String key) async {
    _memoryCache.remove(key);
    await _removePersistentCache(key);
  }

  Future<void> clear() async {
    _memoryCache.clear();
    await _clearPersistentCache();
  }

  void _evictOldEntries() {
    if (_memoryCache.length <= _maxMemoryCacheSize) return;

    // 按过期时间排序，删除最旧的条目
    final entries = _memoryCache.entries.toList()
      ..sort((a, b) => a.value.expiresAt.compareTo(b.value.expiresAt));

    final toRemove = entries.length - _maxMemoryCacheSize;
    for (int i = 0; i < toRemove; i++) {
      _memoryCache.remove(entries[i].key);
    }
  }

  Future<CacheEntry?> _getPersistentCache(String key) async {
    return await _database.readTxn(() async {
      final cacheEntity = await _database.cacheEntities.get(key);
      if (cacheEntity == null) return null;

      if (cacheEntity.expiresAt.isBefore(DateTime.now())) {
        await _database.cacheEntities.delete(cacheEntity.id!);
        return null;
      }

      return CacheEntry.fromEntity(cacheEntity);
    });
  }

  Future<void> _savePersistentCache(CacheEntry entry) async {
    final entity = entry.toEntity();
    await _database.writeTxn(() async {
      await _database.cacheEntities.put(entity);
    });
  }

  Future<void> _removePersistentCache(String key) async {
    await _database.writeTxn(() async {
      await _database.cacheEntities.delete(key);
    });
  }

  Future<void> _clearPersistentCache() async {
    await _database.writeTxn(() async {
      await _database.cacheEntities.clear();
    });
  }

  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(Duration(minutes: 10), (_) {
      _cleanupExpiredEntries();
    });
  }

  Future<void> _cleanupExpiredEntries() async {
    // 清理内存缓存中的过期条目
    _memoryCache.removeWhere((key, entry) => entry.isExpired);

    // 清理持久化缓存中的过期条目
    await _database.writeTxn(() async {
      final expiredEntities = await _database.cacheEntities
          .where()
          .expiresAtLessThan(DateTime.now())
          .findAll();

      for (final entity in expiredEntities) {
        await _database.cacheEntities.delete(entity.id!);
      }
    });
  }

  void dispose() {
    _cleanupTimer?.cancel();
  }
}

// 缓存条目
class CacheEntry {
  final String key;
  final Response response;
  final DateTime expiresAt;

  CacheEntry({
    required this.key,
    required this.response,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  CacheEntity toEntity() {
    return CacheEntity()
      ..key = key
      ..statusCode = response.statusCode
      ..data = jsonEncode(response.data)
      ..headers = jsonEncode(response.headers.map)
      ..expiresAt = expiresAt;
  }

  static CacheEntry fromEntity(CacheEntity entity) {
    return CacheEntry(
      key: entity.key,
      response: Response(
        statusCode: entity.statusCode,
        data: jsonDecode(entity.data),
        headers: Headers.fromMap(jsonDecode(entity.headers)),
      ),
      expiresAt: entity.expiresAt,
    );
  }
}

// 智能缓存策略
class SmartCacheStrategy {
  static Duration getCacheTtl(String url, dynamic data) {
    // 根据URL和数据类型确定缓存时间
    if (url.contains('/funds/')) {
      // 基金数据缓存5分钟
      return Duration(minutes: 5);
    } else if (url.contains('/market/')) {
      // 市场数据缓存1分钟
      return Duration(minutes: 1);
    } else if (url.contains('/news/')) {
      // 新闻数据缓存30分钟
      return Duration(minutes: 30);
    } else {
      // 默认缓存5分钟
      return Duration(minutes: 5);
    }
  }

  static bool shouldCache(String url, int statusCode) {
    // 只缓存成功的GET请求
    return statusCode >= 200 && statusCode < 300;
  }

  static String generateCacheKey(String url, Map<String, dynamic>? params) {
    if (params == null || params.isEmpty) {
      return url;
    }

    final sortedParams = Map.fromEntries(
      params.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
    );

    return '$url?${sortedParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';
  }
}
```

**测试要点**:
- 缓存读写正确性
- 过期机制有效性
- 缓存大小控制
- 离线模式下的缓存使用

---

### 💾 数据存储架构

#### US-001.13: 配置本地数据库(Hive)

**用户故事**: 作为开发工程师，我希望配置高性能的本地数据库(Hive)，以便在设备本地存储和管理应用数据。

**优先级**: P0
**复杂度**: 中
**预估工期**: 2天
**依赖关系**: US-001.1

**验收标准**:
- [ ] Hive数据库配置完成
- [ ] 数据模型定义完整
- [ ] 数据库操作封装完善
- [ ] 数据迁移机制
- [ ] 性能优化配置

**Hive配置实现**:
```dart
// 数据库服务
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  late final LazyBox _settingsBox;
  late final LazyBox _favoritesBox;
  late final LazyBox _historyBox;

  Future<void> initialize() async {
    // 初始化Hive
    await Hive.initFlutter();

    // 注册自定义类型适配器
    _registerAdapters();

    // 打开数据表
    await _openBoxes();

    log('Database initialized successfully');
  }

  void _registerAdapters() {
    // 注册数据模型适配器
    Hive.registerAdapter(FundAdapter());
    Hive.registerAdapter(FundDetailAdapter());
    Hive.registerAdapter(UserAdapter());
    Hive.registerAdapter(SearchHistoryAdapter());
  }

  Future<void> _openBoxes() async {
    _settingsBox = await Hive.openLazyBox('settings');
    _favoritesBox = await Hive.openLazyBox('favorites');
    _historyBox = await Hive.openLazyBox('history');
  }

  // 设置数据操作
  Future<T?> getSetting<T>(String key, T? defaultValue) async {
    return await _settingsBox.get(key, defaultValue: defaultValue);
  }

  Future<void> setSetting<T>(String key, T value) async {
    await _settingsBox.put(key, value);
  }

  // 收藏数据操作
  Future<List<Fund>> getFavorites() async {
    final favorites = await _favoritesBox.getAll();
    return favorites.cast<Fund>();
  }

  Future<void> addToFavorites(Fund fund) async {
    await _favoritesBox.put(fund.code, fund);
  }

  Future<void> removeFromFavorites(String fundCode) async {
    await _favoritesBox.delete(fundCode);
  }

  Future<bool> isFavorite(String fundCode) async {
    return await _favoritesBox.containsKey(fundCode);
  }

  // 搜索历史操作
  Future<List<String>> getSearchHistory() async {
    final history = await _historyBox.getAll();
    return history.cast<String>();
  }

  Future<void> addToSearchHistory(String query) async {
    final history = await getSearchHistory();

    // 移除重复项
    history.remove(query);

    // 添加到开头
    history.insert(0, query);

    // 限制历史记录数量
    if (history.length > 20) {
      history.removeRange(20, history.length);
    }

    // 重新保存
    await _historyBox.clear();
    for (int i = 0; i < history.length; i++) {
      await _historyBox.put(i, history[i]);
    }
  }

  Future<void> clearSearchHistory() async {
    await _historyBox.clear();
  }

  // 数据库维护
  Future<void> compact() async {
    await _settingsBox.compact();
    await _favoritesBox.compact();
    await _historyBox.compact();
  }

  Future<Map<String, dynamic>> getDatabaseStats() async {
    return {
      'settings_count': await _settingsBox.length,
      'favorites_count': await _favoritesBox.length,
      'history_count': await _historyBox.length,
      'total_size_bytes': await _getTotalSize(),
    };
  }

  Future<int> _getTotalSize() async {
    // 估算数据库大小
    return (_settingsBox.length +
            _favoritesBox.length +
            _historyBox.length) * 1024; // 粗略估算
  }

  Future<void> clearAllData() async {
    await _settingsBox.clear();
    await _favoritesBox.clear();
    await _historyBox.clear();
  }
}
```

**数据模型定义**:
```dart
// 基金数据模型
@HiveType(typeId: 0)
class Fund extends HiveObject {
  @HiveField(0)
  final String code;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String type;

  @HiveField(3)
  final String company;

  @HiveField(4)
  final DateTime establishedDate;

  @HiveField(5)
  final double nav;

  @HiveField(6)
  final DateTime navDate;

  @HiveField(7)
  final double? minInvestment;

  @HiveField(8)
  final String? riskLevel;

  Fund({
    required this.code,
    required this.name,
    required this.type,
    required this.company,
    required this.establishedDate,
    required this.nav,
    required this.navDate,
    this.minInvestment,
    this.riskLevel,
  });

  factory Fund.fromJson(Map<String, dynamic> json) {
    return Fund(
      code: json['code'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      company: json['company'] as String,
      establishedDate: DateTime.parse(json['established_date'] as String),
      nav: (json['nav'] as num).toDouble(),
      navDate: DateTime.parse(json['nav_date'] as String),
      minInvestment: json['min_investment'] as double?,
      riskLevel: json['risk_level'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'type': type,
      'company': company,
      'established_date': establishedDate.toIso8601String(),
      'nav': nav,
      'nav_date': navDate.toIso8601String(),
      'min_investment': minInvestment,
      'risk_level': riskLevel,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Fund && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;
}

// 数据库适配器
class FundAdapter extends TypeAdapter<Fund> {
  @override
  final int typeId = 0;

  @override
  Fund read(BinaryReader reader) {
    final fields = <int, dynamic>{};
    for (int i = 0; i < 9; i++) {
      fields[i] = reader.read();
    }

    return Fund(
      code: fields[0] as String,
      name: fields[1] as String,
      type: fields[2] as String,
      company: fields[3] as String,
      establishedDate: fields[4] as DateTime,
      nav: fields[5] as double,
      navDate: fields[6] as DateTime,
      minInvestment: fields[7] as double?,
      riskLevel: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Fund obj) {
    writer.write(obj.code);
    writer.write(obj.name);
    writer.write(obj.type);
    writer.write(obj.company);
    writer.write(obj.establishedDate);
    writer.write(obj.nav);
    writer.write(obj.navDate);
    writer.write(obj.minInvestment);
    writer.write(obj.riskLevel);
  }
}
```

**测试要点**:
- 数据库初始化
- 数据模型序列化/反序列化
- CRUD操作正确性
- 数据迁移功能

---

#### US-001.14: 建立数据模型和序列化机制

**用户故事**: 作为开发工程师，我希望建立完整的数据模型和序列化机制，以便在应用中高效地处理和管理数据。

**优先级**: P0
**复杂度**: 中
**预估工期**: 3天
**依赖关系**: US-001.13

**验收标准**:
- [ ] 数据模型定义完整
- [ ] JSON序列化/反序列化
- [ ] 数据验证机制
- [ ] 类型安全保证
- [ ] 性能优化

**数据模型架构**:
```dart
// 基础数据模型
abstract class BaseModel {
  String get id;

  Map<String, dynamic> toJson();

  // 数据验证
  List<String> validate();

  // 复制方法
  BaseModel copyWith(Map<String, dynamic> changes);
}

// 用户模型
class User extends BaseModel {
  @override
  final String id;
  final String username;
  final String email;
  final String? avatar;
  final UserPreferences preferences;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.username,
    required this.email,
    this.avatar,
    required this.preferences,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      avatar: json['avatar'] as String?,
      preferences: UserPreferences.fromJson(
        json['preferences'] as Map<String, dynamic>,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'avatar': avatar,
      'preferences': preferences.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<String> validate() {
    final errors = <String>[];

    if (username.isEmpty) {
      errors.add('Username cannot be empty');
    }

    if (!email.contains('@')) {
      errors.add('Invalid email format');
    }

    return errors;
  }

  @override
  User copyWith(Map<String, dynamic> changes) {
    return User(
      id: changes['id'] ?? id,
      username: changes['username'] ?? username,
      email: changes['email'] ?? email,
      avatar: changes['avatar'],
      preferences: changes['preferences'] ?? preferences,
      createdAt: changes['created_at'] ?? createdAt,
      updatedAt: changes['updated_at'] ?? updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// 用户偏好设置
class UserPreferences {
  final String theme;
  final String language;
  final bool notificationsEnabled;
  final List<String> favoriteCategories;
  final Map<String, dynamic> customSettings;

  const UserPreferences({
    required this.theme,
    required this.language,
    required this.notificationsEnabled,
    required this.favoriteCategories,
    required this.customSettings,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      theme: json['theme'] as String? ?? 'light',
      language: json['language'] as String? ?? 'zh_CN',
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      favoriteCategories: (json['favorite_categories'] as List<dynamic>?)
              ?.cast<String>() ??
          [],
      customSettings: json['custom_settings'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'language': language,
      'notifications_enabled': notificationsEnabled,
      'favorite_categories': favoriteCategories,
      'custom_settings': customSettings,
    };
  }
}

// API响应模型
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? code;
  final Map<String, dynamic>? meta;

  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.code,
    this.meta,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      message: json['message'] as String?,
      code: json['code'] as int?,
      meta: json['meta'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson(dynamic Function(T) toJsonT) {
    return {
      'success': success,
      'data': data != null ? toJsonT(data as T) : null,
      'message': message,
      'code': code,
      'meta': meta,
    };
  }
}
```

**序列化工具**:
```dart
// 序列化管理器
class SerializationManager {
  static final SerializationManager _instance = SerializationManager._internal();
  factory SerializationManager() => _instance;
  SerializationManager._internal();

  final Map<Type, Function> _fromJsonFactories = {};
  final Map<Type, Function> _toJsonFactories = {};

  void registerModel<T>(
    T Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic> Function(T) toJson,
  ) {
    _fromJsonFactories[T] = fromJson;
    _toJsonFactories[T] = toJson;
  }

  T? deserialize<T>(dynamic data) {
    if (data == null) return null;

    final factory = _fromJsonFactories[T];
    if (factory == null) {
      throw ArgumentError('No factory registered for type $T');
    }

    if (data is String) {
      data = jsonDecode(data);
    }

    return factory(data as Map<String, dynamic>) as T;
  }

  dynamic serialize<T>(T object) {
    final factory = _toJsonFactories[T];
    if (factory == null) {
      throw ArgumentError('No factory registered for type $T');
    }

    return factory(object);
  }

  List<T> deserializeList<T>(dynamic data) {
    if (data == null) return [];

    final List<dynamic> dataList;
    if (data is String) {
      dataList = jsonDecode(data) as List<dynamic>;
    } else {
      dataList = data as List<dynamic>;
    }

    return dataList.map((item) => deserialize<T>(item)!).toList();
  }

  String serializeList<T>(List<T> objects) {
    final serializedList = objects.map(serialize<T>).toList();
    return jsonEncode(serializedList);
  }
}

// 自动生成的序列化代码 (使用build_runner)
// 运行: flutter packages pub run build_runner build

// 用户模型生成器
part 'user.g.dart';

@HiveType(typeId: 1)
@JsonSerializable()
class User extends BaseModel {
  @override
  @HiveField(0)
  @JsonKey(name: 'id')
  final String id;

  @HiveField(1)
  @JsonKey(name: 'username')
  final String username;

  @HiveField(2)
  @JsonKey(name: 'email')
  final String email;

  @HiveField(3)
  @JsonKey(name: 'avatar')
  final String? avatar;

  @HiveField(4)
  @JsonKey(name: 'preferences')
  final UserPreferences preferences;

  @HiveField(5)
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @HiveField(6)
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.username,
    required this.email,
    this.avatar,
    required this.preferences,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  @override
  List<String> validate() {
    // 验证逻辑
    return [];
  }

  @override
  User copyWith(Map<String, dynamic> changes) {
    return _$UserFromJson({...toJson(), ...changes});
  }
}
```

**测试要点**:
- 序列化/反序列化正确性
- 数据验证机制
- 类型安全保证
- 性能基准测试

---

#### US-001.15: 实现数据同步和备份机制

**用户故事**: 作为用户，我希望应用的数据能够在云端同步和备份，以便在不同设备间保持数据一致性，并防止数据丢失。

**优先级**: P1
**复杂度**: 高
**预估工期**: 4天
**依赖关系**: US-001.14

**验收标准**:
- [ ] 数据自动同步到云端
- [ ] 设备间数据一致性
- [ ] 数据备份和恢复
- [ ] 离线数据同步
- [ ] 冲突解决机制

**数据同步架构**:
```dart
// 数据同步服务
class DataSyncService {
  static final DataSyncService _instance = DataSyncService._internal();
  factory DataSyncService() => _instance;
  DataSyncService._internal();

  final ApiClient _apiClient;
  final DatabaseService _database;
  final NetworkService _networkService;

  bool _isSyncing = false;
  final StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();

  Stream<SyncStatus> get statusStream => _statusController.stream;
  bool get isSyncing => _isSyncing;

  DataSyncService(
    this._apiClient,
    this._database,
    this._networkService,
  );

  Future<void> initialize() async {
    // 启动自动同步
    _startAutoSync();

    // 监听网络状态变化
    _networkService.statusStream.listen(_onNetworkStatusChanged);
  }

  void _startAutoSync() {
    // 每30分钟同步一次
    Timer.periodic(Duration(minutes: 30), (_) {
      if (_networkService.isConnected && !_isSyncing) {
        syncData();
      }
    });
  }

  void _onNetworkStatusChanged(NetworkStatus status) {
    if (status == NetworkStatus.connected && !_isSyncing) {
      syncData();
    }
  }

  Future<SyncResult> syncData() async {
    if (_isSyncing) {
      return SyncResult.success('Sync already in progress');
    }

    _isSyncing = true;
    _statusController.add(SyncStatus.syncing);

    try {
      // 获取本地数据的最后同步时间
      final lastSyncTime = await _getLastSyncTime();

      // 同步收藏数据
      await _syncFavorites(lastSyncTime);

      // 同步用户设置
      await _syncSettings(lastSyncTime);

      // 同步搜索历史
      await _syncSearchHistory(lastSyncTime);

      // 更新最后同步时间
      await _updateLastSyncTime();

      _statusController.add(SyncStatus.completed);
      return SyncResult.success('Data synchronized successfully');

    } catch (e) {
      _statusController.add(SyncStatus.error(e.toString()));
      return SyncResult.error(e.toString());
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncFavorites(DateTime lastSyncTime) async {
    // 上传本地收藏数据
    final localFavorites = await _database.getFavorites();
    await _uploadFavorites(localFavorites, lastSyncTime);

    // 下载远程收藏数据
    final remoteFavorites = await _downloadFavorites(lastSyncTime);
    await _mergeFavorites(remoteFavorites);
  }

  Future<void> _uploadFavorites(List<Fund> favorites, DateTime since) async {
    if (favorites.isEmpty) return;

    try {
      await _apiClient.post('/sync/favorites', data: {
        'favorites': favorites.map((f) => f.toJson()).toList(),
        'last_sync_time': since.toIso8601String(),
      });
    } on ApiException catch (e) {
      log('Failed to upload favorites: ${e.message}');
      throw e;
    }
  }

  Future<List<Fund>> _downloadFavorites(DateTime since) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/sync/favorites',
        queryParameters: {'since': since.toIso8601String()},
      );

      final favoritesJson = response.data!['favorites'] as List<dynamic>;
      return favoritesJson
          .map((json) => Fund.fromJson(json as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      log('Failed to download favorites: ${e.message}');
      return [];
    }
  }

  Future<void> _mergeFavorites(List<Fund> remoteFavorites) async {
    final localFavorites = await _database.getFavorites();
    final mergedFavorites = <String, Fund>{};

    // 添加本地收藏
    for (final fund in localFavorites) {
      mergedFavorites[fund.code] = fund;
    }

    // 合并远程收藏 (远程优先)
    for (final fund in remoteFavorites) {
      mergedFavorites[fund.code] = fund;
    }

    // 保存合并后的收藏
    await _database.clearFavorites();
    for (final fund in mergedFavorites.values) {
      await _database.addToFavorites(fund);
    }
  }

  Future<void> _syncSettings(DateTime lastSyncTime) async {
    // 类似的同步逻辑
  }

  Future<void> _syncSearchHistory(DateTime lastSyncTime) async {
    // 类似的同步逻辑
  }

  Future<DateTime> _getLastSyncTime() async {
    final timestamp = await _database.getSetting<int>('last_sync_time', null);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<void> _updateLastSyncTime() async {
    await _database.setSetting(
      'last_sync_time',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  // 数据备份
  Future<BackupResult> createBackup() async {
    try {
      final backupData = await _generateBackupData();
      final backupId = await _uploadBackup(backupData);

      return BackupResult.success(backupId);
    } catch (e) {
      return BackupResult.error(e.toString());
    }
  }

  Future<Map<String, dynamic>> _generateBackupData() async {
    return {
      'version': '1.0',
      'timestamp': DateTime.now().toIso8601String(),
      'user_id': await _getCurrentUserId(),
      'data': {
        'favorites': (await _database.getFavorites())
            .map((f) => f.toJson())
            .toList(),
        'settings': await _database.getAllSettings(),
        'search_history': await _database.getSearchHistory(),
      },
    };
  }

  Future<String> _uploadBackup(Map<String, dynamic> backupData) async {
    final response = await _apiClient.post('/backup/create', data: backupData);
    return response.data!['backup_id'] as String;
  }

  // 数据恢复
  Future<RestoreResult> restoreFromBackup(String backupId) async {
    try {
      final backupData = await _downloadBackup(backupId);
      await _restoreFromBackupData(backupData);

      return RestoreResult.success();
    } catch (e) {
      return RestoreResult.error(e.toString());
    }
  }

  Future<Map<String, dynamic>> _downloadBackup(String backupId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/backup/$backupId',
    );
    return response.data!;
  }

  Future<void> _restoreFromBackupData(Map<String, dynamic> backupData) async {
    final data = backupData['data'] as Map<String, dynamic>;

    // 清空现有数据
    await _database.clearAllData();

    // 恢复收藏数据
    final favoritesJson = data['favorites'] as List<dynamic>;
    for (final json in favoritesJson) {
      final fund = Fund.fromJson(json as Map<String, dynamic>);
      await _database.addToFavorites(fund);
    }

    // 恢复设置数据
    final settings = data['settings'] as Map<String, dynamic>;
    for (final entry in settings.entries) {
      await _database.setSetting(entry.key, entry.value);
    }

    // 恢复搜索历史
    final history = data['search_history'] as List<dynamic>;
    for (int i = 0; i < history.length; i++) {
      await _database.addToSearchHistory(history[i] as String);
    }
  }

  String? _getCurrentUserId() {
    // 获取当前用户ID
    return null; // TODO: 实现获取用户ID逻辑
  }
}

// 同步状态
enum SyncStatus {
  idle,
  syncing,
  completed,
  error,
}

class SyncResult {
  final bool success;
  final String message;

  SyncResult.success(this.message) : success = true;
  SyncResult.error(this.message) : success = false;
}

class BackupResult {
  final bool success;
  final String? backupId;
  final String? error;

  BackupResult.success(this.backupId) : success = true, error = null;
  BackupResult.error(this.error) : success = false, backupId = null;
}

class RestoreResult {
  final bool success;
  final String? error;

  RestoreResult.success() : success = true, error = null;
  RestoreResult.error(this.error) : success = false;
}
```

**冲突解决机制**:
```dart
// 冲突解决策略
class ConflictResolver {
  static Future<T> resolveConflict<T>(
    T localData,
    T remoteData,
    DateTime localModified,
    DateTime remoteModified,
  ) async {
    // 策略1: 最新修改优先
    if (remoteModified.isAfter(localModified)) {
      return remoteData;
    } else {
      return localData;
    }

    // 策略2: 用户选择 (可以扩展为让用户手动选择)
    // return await _showConflictDialog(localData, remoteData);
  }

  static Future<bool> _showConflictDialog<T>(T localData, T remoteData) {
    // 显示冲突解决对话框
    // 返回true选择远程数据，false选择本地数据
    return Future.value(true);
  }
}
```

**测试要点**:
- 数据同步准确性
- 冲突解决机制
- 离线同步功能
- 备份恢复功能

---

#### US-001.16: 建立数据迁移和版本管理

**用户故事**: 作为开发工程师，我希望建立完善的数据迁移和版本管理机制，以便在应用升级时能够平滑地迁移用户数据。

**优先级**: P1
**复杂度**: 中
**预估工期**: 3天
**依赖关系**: US-001.15

**验收标准**:
- [ ] 数据版本管理系统
- [ ] 自动数据迁移
- [ ] 迁移失败回滚
- [ ] 迁移进度通知
- [ ] 数据完整性验证

**数据迁移系统**:
```dart
// 数据迁移管理器
class MigrationManager {
  static final MigrationManager _instance = MigrationManager._internal();
  factory MigrationManager() => _instance;
  MigrationManager._internal();

  final Map<int, Migration> _migrations = {};
  int _currentVersion = 0;
  int _targetVersion = 0;

  void registerMigration(int version, Migration migration) {
    _migrations[version] = migration;
  }

  Future<void> initialize() async {
    await _loadCurrentVersion();
    _targetVersion = _getTargetVersion();
  }

  Future<void> migrate() async {
    if (_currentVersion >= _targetVersion) {
      log('Database is already up to date (version $_currentVersion)');
      return;
    }

    log('Starting migration from version $_currentVersion to $_targetVersion');

    try {
      // 创建备份
      await _createBackup();

      // 执行迁移
      for (int version = _currentVersion + 1; version <= _targetVersion; version++) {
        final migration = _migrations[version];
        if (migration == null) {
          throw MigrationException('Migration for version $version not found');
        }

        log('Executing migration for version $version');
        await migration.execute();
        await _updateVersion(version);
      }

      log('Migration completed successfully');

      // 验证数据完整性
      await _validateDataIntegrity();

    } catch (e) {
      log('Migration failed: $e');

      // 回滚迁移
      await _rollbackMigration();

      rethrow;
    }
  }

  Future<void> _loadCurrentVersion() async {
    _currentVersion = await _getDatabaseVersion();
  }

  Future<int> _getDatabaseVersion() async {
    // 从数据库获取当前版本
    final database = DatabaseService();
    return await database.getSetting<int>('db_version', 0) ?? 0;
  }

  int _getTargetVersion() {
    // 获取目标版本 (最新注册的迁移版本)
    return _migrations.keys.isEmpty ? 0 : _migrations.keys.reduce(max);
  }

  Future<void> _createBackup() async {
    log('Creating backup before migration');
    // 创建数据库备份
    final backupService = DataSyncService();
    final backupResult = await backupService.createBackup();

    if (!backupResult.success) {
      throw MigrationException('Failed to create backup: ${backupResult.error}');
    }

    log('Backup created: ${backupResult.backupId}');
  }

  Future<void> _updateVersion(int version) async {
    final database = DatabaseService();
    await database.setSetting('db_version', version);
    _currentVersion = version;
  }

  Future<void> _validateDataIntegrity() async {
    log('Validating data integrity after migration');

    // 验证基本数据结构
    final database = DatabaseService();
    final stats = await database.getDatabaseStats();

    log('Database stats: $stats');

    // 验证数据完整性
    // TODO: 实现具体的数据完整性检查
  }

  Future<void> _rollbackMigration() async {
    log('Rolling back migration due to error');

    try {
      // 恢复备份
      // TODO: 实现备份恢复逻辑
      log('Migration rollback completed');
    } catch (e) {
      log('Failed to rollback migration: $e');
    }
  }
}

// 迁移抽象基类
abstract class Migration {
  final int version;
  final String description;

  Migration(this.version, this.description);

  Future<void> execute() async {
    log('Executing migration: $description');
    await _migrate();
    log('Migration $version completed');
  }

  Future<void> _migrate();

  Future<void> rollback() async {
    log('Rolling back migration: $description');
    await _rollback();
    log('Migration $version rollback completed');
  }

  Future<void> _rollback();
}

// 具体迁移实现
class MigrationV1 extends Migration {
  MigrationV1() : super(1, 'Initialize database structure');

  @override
  Future<void> _migrate() async {
    final database = DatabaseService();

    // 初始化基础表结构
    await _initializeFavoritesTable();
    await _initializeSettingsTable();
    await _initializeHistoryTable();

    // 迁移旧数据 (如果有的话)
    await _migrateLegacyData();
  }

  Future<void> _initializeFavoritesTable() async {
    // 初始化收藏表
    log('Initializing favorites table');
  }

  Future<void> _initializeSettingsTable() async {
    // 初始化设置表
    log('Initializing settings table');
  }

  Future<void> _initializeHistoryTable() async {
    // 初始化历史表
    log('Initializing history table');
  }

  Future<void> _migrateLegacyData() async {
    // 迁移旧版本数据
    log('Migrating legacy data');
  }

  @override
  Future<void> _rollback() async {
    final database = DatabaseService();
    await database.clearAllData();
  }
}

class MigrationV2 extends Migration {
  MigrationV2() : super(2, 'Add fund performance data');

  @override
  Future<void> _migrate() async {
    final database = DatabaseService();

    // 添加基金业绩数据字段
    await _addPerformanceFields();

    // 更新现有数据
    await _updateExistingFunds();
  }

  Future<void> _addPerformanceFields() async {
    // 添加新的性能字段
    log('Adding performance fields to fund model');
  }

  Future<void> _updateExistingFunds() async {
    // 更新现有基金数据
    log('Updating existing fund data with performance info');
  }

  @override
  Future<void> _rollback() async {
    // 移除性能字段
    log('Removing performance fields');
  }
}

class MigrationV3 extends Migration {
  MigrationV3() : super(3, 'Add user preferences and themes');

  @override
  Future<void> _migrate() async {
    // 添加用户偏好设置
    await _addUserPreferences();

    // 添加主题支持
    await _addThemeSupport();

    // 迁移现有设置
    await _migrateExistingSettings();
  }

  Future<void> _addUserPreferences() async {
    log('Adding user preferences structure');
  }

  Future<void> _addThemeSupport() async {
    log('Adding theme support');
  }

  Future<void> _migrateExistingSettings() async {
    log('Migrating existing settings to new format');
  }

  @override
  Future<void> _rollback() async {
    log('Removing user preferences and theme support');
  }
}

// 迁移异常
class MigrationException implements Exception {
  final String message;

  const MigrationException(this.message);

  @override
  String toString() => 'MigrationException: $message';
}

// 迁移配置
class MigrationConfig {
  static void configureMigrations() {
    final manager = MigrationManager();

    // 注册所有迁移
    manager.registerMigration(1, MigrationV1());
    manager.registerMigration(2, MigrationV2());
    manager.registerMigration(3, MigrationV3());

    // 可以继续添加更多迁移
  }
}
```

**迁移监控和通知**:
```dart
// 迁移通知服务
class MigrationNotificationService {
  static final MigrationNotificationService _instance =
      MigrationNotificationService._internal();
  factory MigrationNotificationService() => _instance;
  MigrationNotificationService._internal();

  final StreamController<MigrationEvent> _eventController =
      StreamController<MigrationEvent>.broadcast();

  Stream<MigrationEvent> get eventStream => _eventController.stream;

  void notifyEvent(MigrationEvent event) {
    _eventController.add(event);
    log('Migration event: ${event.type} - ${event.message}');
  }

  void notifyStart(int fromVersion, int toVersion) {
    notifyEvent(MigrationEvent(
      type: MigrationEventType.start,
      message: 'Starting migration from $fromVersion to $toVersion',
      data: {'from': fromVersion, 'to': toVersion},
    ));
  }

  void notifyProgress(int currentVersion, String description) {
    notifyEvent(MigrationEvent(
      type: MigrationEventType.progress,
      message: 'Migrating to version $currentVersion: $description',
      data: {'version': currentVersion, 'description': description},
    ));
  }

  void notifyComplete(int finalVersion) {
    notifyEvent(MigrationEvent(
      type: MigrationEventType.complete,
      message: 'Migration completed successfully',
      data: {'version': finalVersion},
    ));
  }

  void notifyError(String error) {
    notifyEvent(MigrationEvent(
      type: MigrationEventType.error,
      message: 'Migration failed: $error',
      data: {'error': error},
    ));
  }
}

// 迁移事件
class MigrationEvent {
  final MigrationEventType type;
  final String message;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  MigrationEvent({
    required this.type,
    required this.message,
    this.data,
  }) : timestamp = DateTime.now();
}

enum MigrationEventType {
  start,
  progress,
  complete,
  error,
}
```

**测试要点**:
- 数据迁移正确性
- 版本管理准确性
- 错误处理和回滚
- 数据完整性验证

---

## 📊 史诗验收标准

### 功能验收标准

- [ ] Flutter项目可在所有目标平台正常运行
- [ ] 状态管理架构支持复杂业务场景
- [ ] 网络通信稳定可靠，错误处理完善
- [ ] 数据存储性能满足要求，数据安全可靠
- [ ] 代码质量达到既定标准，测试覆盖率≥80%

### 性能验收标准

- [ ] 应用启动时间≤3秒
- [ ] 页面切换响应时间≤500ms
- [ ] 数据库操作响应时间≤100ms
- [ ] API请求响应时间≤2秒
- [ ] 内存使用≤200MB

### 质量验收标准

- [ ] 代码覆盖率≥80%
- [ ] 静态分析无错误
- [ ] 性能测试通过
- [ ] 安全测试通过
- [ ] 兼容性测试通过

---

## 🚀 后续计划

EPIC-001的完成为整个项目奠定了坚实的技术基础。接下来将进入EPIC-002: 基金数据管理，基于已建立的基础架构开发具体的业务功能。

**预计开始时间**: EPIC-001完成后1周
**依赖关系**: 无其他依赖
**风险等级**: 低 (基础架构相对稳定)

---

*本用户故事文档将随着开发进展持续更新，确保与实际开发进度保持同步。*