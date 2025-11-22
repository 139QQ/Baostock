# 基速基金量化分析平台 - 开发指南

## 📋 开发环境准备

### 系统要求

**最低要求**:
- **操作系统**: Windows 10/11 (主要), macOS 10.15+, Ubuntu 18.04+
- **内存**: 8GB RAM (推荐16GB)
- **存储**: 10GB 可用空间
- **网络**: 稳定的互联网连接

**开发工具**:
- **Flutter**: 3.13.0 (Channel stable)
- **Dart**: 3.1.0
- **IDE**: VS Code / Android Studio / IntelliJ IDEA
- **Git**: 版本控制
- **PostgreSQL**: 数据库 (可选，用于开发环境)

### 环境安装

#### 1. Flutter SDK 安装

```bash
# 下载 Flutter SDK
# 官网: https://flutter.dev/docs/get-started/install/windows

# 验证安装
flutter doctor

# 配置环境变量
# 将 Flutter SDK 的 bin 目录添加到 PATH
```

#### 2. 开发工具安装

**VS Code** (推荐):
```bash
# 安装 VS Code
# 安装扩展:
- Dart
- Flutter
- GitLens
- Flutter Widget Snippets
- Better Comments
```

**Android Studio**:
```bash
# 安装 Android Studio
# 安装 Flutter 和 Dart 插件
# 配置 Android SDK
```

#### 3. 项目设置

```bash
# 克隆项目
git clone <repository-url>
cd Baostock

# 设置开发环境
./scripts/setup-env.bat development

# 获取依赖
flutter pub get

# 运行代码生成
dart run build_runner build

# 启动开发服务器
flutter run -d windows
```

---

## 🏗️ 项目架构理解

### 目录结构

```
Baostock/
├── 📁 lib/                    # 🔥 主要源代码
│   ├── 📄 main.dart           # 应用入口
│   └── 📁 src/                # 源代码
│       ├── 📁 core/           # 核心基础设施
│       ├── 📁 features/       # 功能模块
│       ├── 📁 bloc/           # 全局状态管理
│       ├── 📁 models/         # 数据模型
│       └── 📁 services/       # 业务服务
├── 📁 test/                   # 测试代码
├── 📁 docs/                   # 项目文档
├── 📁 assets/                 # 静态资源
├── 📁 windows/                # Windows平台代码
└── 📄 pubspec.yaml            # 项目配置
```

### 架构模式

**Clean Architecture**:
```
┌─────────────────┐
│   Presentation  │ ← UI组件、状态管理
├─────────────────┤
│     Domain      │ ← 业务逻辑、用例
├─────────────────┤
│      Data       │ ← 数据访问、仓库
└─────────────────┘
```

**BLoC状态管理**:
```
Event → BLoC → State → UI
```

---

## 🚀 开发工作流

### 1. 创建新功能

#### 步骤1: 创建功能模块结构
```bash
# 在 features 目录下创建新功能
mkdir lib/src/features/new_feature
cd lib/src/features/new_feature

# 创建Clean Architecture目录结构
mkdir -p data/{datasources,repositories}
mkdir -p domain/{entities,repositories,usecases}
mkdir -p presentation/{pages,widgets,bloc}
```

#### 步骤2: 实现领域层
```dart
// domain/entities/new_feature_entity.dart
class NewFeatureEntity extends Equatable {
  final String id;
  final String name;
  final DateTime createdAt;

  const NewFeatureEntity({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, createdAt];
}
```

```dart
// domain/repositories/new_feature_repository.dart
abstract class NewFeatureRepository {
  Future<Either<Failure, List<NewFeatureEntity>>> getFeatures();
  Future<Either<Failure, void>> saveFeature(NewFeatureEntity feature);
}
```

```dart
// domain/usecases/get_new_features.dart
class GetNewFeatures implements UseCase<List<NewFeatureEntity>, NoParams> {
  final NewFeatureRepository repository;

  GetNewFeatures(this.repository);

  @override
  Future<Either<Failure, List<NewFeatureEntity>>> call(NoParams params) async {
    return await repository.getFeatures();
  }
}
```

#### 步骤3: 实现数据层
```dart
// data/repositories/new_feature_repository_impl.dart
class NewFeatureRepositoryImpl implements NewFeatureRepository {
  final NewFeatureRemoteDataSource remoteDataSource;
  final NewFeatureLocalDataSource localDataSource;

  NewFeatureRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<NewFeatureEntity>>> getFeatures() async {
    try {
      final remoteModels = await remoteDataSource.getFeatures();
      return Right(remoteModels.map((model) => model.toEntity()).toList());
    } on ServerException {
      return Left(ServerFailure());
    }
  }
}
```

#### 步骤4: 实现表现层
```dart
// presentation/bloc/new_feature_bloc.dart
class NewFeatureBloc extends Bloc<NewFeatureEvent, NewFeatureState> {
  final GetNewFeatures getFeatures;

  NewFeatureBloc({required this.getFeatures}) : super(NewFeatureInitial()) {
    on<LoadFeatures>(_onLoadFeatures);
  }

  Future<void> _onLoadFeatures(
    LoadFeatures event,
    Emitter<NewFeatureState> emit,
  ) async {
    emit(NewFeatureLoading());
    final result = await getFeatures(NoParams());

    result.fold(
      (failure) => emit(NewFeatureError(failure.message)),
      (features) => emit(NewFeatureLoaded(features)),
    );
  }
}
```

#### 步骤5: 注册依赖
```dart
// lib/src/core/di/service_locator.dart
Future<void> initDependencies() async {
  // 数据源
  serviceLocator.registerLazySingleton<NewFeatureRemoteDataSource>(
    () => NewFeatureRemoteDataSourceImpl(),
  );

  // 仓库
  serviceLocator.registerLazySingleton<NewFeatureRepository>(
    () => NewFeatureRepositoryImpl(
      remoteDataSource: serviceLocator<NewFeatureRemoteDataSource>(),
      localDataSource: serviceLocator<NewFeatureLocalDataSource>(),
    ),
  );

  // 用例
  serviceLocator.registerFactory<GetNewFeatures>(
    () => GetNewFeatures(serviceLocator<NewFeatureRepository>()),
  );

  // BLoC
  serviceLocator.registerFactory<NewFeatureBloc>(
    () => NewFeatureBloc(getFeatures: serviceLocator<GetNewFeatures>()),
  );
}
```

### 2. 开发智能组件

#### AdaptiveCard 基础模板
```dart
class AdaptiveWidget extends StatefulWidget {
  final Widget child;
  final AnimationConfig? animationConfig;

  const AdaptiveWidget({
    Key? key,
    required this.child,
    this.animationConfig,
  }) : super(key: key);

  @override
  State<AdaptiveWidget> createState() => _AdaptiveWidgetState();
}

class _AdaptiveWidgetState extends State<AdaptiveWidget> {
  late final DevicePerformanceMonitor _performanceMonitor;
  late AnimationLevel _animationLevel;

  @override
  void initState() {
    super.initState();
    _performanceMonitor = DevicePerformanceMonitor();
    _animationLevel = _determineAnimationLevel();
  }

  AnimationLevel _determineAnimationLevel() {
    final score = _performanceMonitor.getPerformanceScore();

    if (score < 30) return AnimationLevel.disabled;
    if (score < 70) return AnimationLevel.basic;
    return AnimationLevel.full;
  }

  @override
  Widget build(BuildContext context) {
    switch (_animationLevel) {
      case AnimationLevel.disabled:
        return _buildStaticWidget();
      case AnimationLevel.basic:
        return _buildBasicAnimatedWidget();
      case AnimationLevel.full:
        return _buildFullAnimatedWidget();
    }
  }

  Widget _buildStaticWidget() => widget.child;
  Widget _buildBasicAnimatedWidget() => _buildWithBasicAnimation();
  Widget _buildFullAnimatedWidget() => _buildWithFullAnimation();
}
```

### 3. 添加新测试

#### 单元测试示例
```dart
// test/unit/features/new_feature/domain/usecases/get_new_features_test.dart
void main() {
  late GetNewFeatures usecase;
  late MockNewFeatureRepository mockRepository;

  setUp(() {
    mockRepository = MockNewFeatureRepository();
    usecase = GetNewFeatures(mockRepository);
  });

  test('should get features from repository', () async {
    // arrange
    final testFeatures = [
      NewFeatureEntity(id: '1', name: 'Test Feature', createdAt: DateTime.now()),
    ];

    when(() => mockRepository.getFeatures())
        .thenAnswer((_) async => Right(testFeatures));

    // act
    final result = await usecase(NoParams());

    // assert
    expect(result, Right(testFeatures));
    verify(() => mockRepository.getFeatures()).called(1);
  });
}
```

#### Widget 测试示例
```dart
// test/unit/features/new_feature/presentation/widgets/new_feature_widget_test.dart
void main() {
  testWidgets('should display loading indicator when loading', (tester) async {
    // arrange
    final mockBloc = MockNewFeatureBloc();
    whenListen(mockBloc, [], initialState: NewFeatureLoading());

    // act
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<NewFeatureBloc>.value(
          value: mockBloc,
          child: NewFeaturePage(),
        ),
      ),
    );

    // assert
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
```

---

## 🔧 常用开发命令

### 依赖管理
```bash
# 获取依赖
flutter pub get

# 更新依赖
flutter pub upgrade

# 清理依赖缓存
flutter pub cache clean

# 查看依赖树
flutter pub deps
```

### 代码生成
```bash
# 运行所有代码生成
dart run build_runner build

# 监听模式自动生成
dart run build_runner watch

# 清理并重新生成
dart run build_runner clean && dart run build_runner build

# 删除冲突的生成文件
dart run build_runner build --delete-conflicting-outputs
```

### 运行和调试
```bash
# 运行Windows应用
flutter run -d windows

# 运行Android应用
flutter run -d android

# 运行Web应用
flutter run -d chrome

# 热重载
# 在运行时按 'r' 键
# 热重启
# 在运行时按 'R' 键
```

### 测试
```bash
# 运行所有测试
flutter test

# 运行特定测试文件
flutter test test/unit/features/new_feature/

# 运行测试并生成覆盖率
flutter test --coverage

# 查看覆盖率报告
genhtml coverage/lcov.info -o coverage/html
```

### 构建
```bash
# Windows Debug构建
flutter build windows --debug

# Windows Release构建
flutter build windows --release

# Android Debug构建
flutter build apk --debug

# Android Release构建
flutter build apk --release
```

---

## 📊 性能优化指南

### 1. Flutter性能最佳实践

#### Widget优化
```dart
// ❌ 错误示例 - 每次重建都会创建新列表
class BadWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 1000,
      itemBuilder: (context, index) {
        return ListTile(title: Text('Item $index')); // 每次都创建新Text
      },
    );
  }
}

// ✅ 正确示例 - 使用const构造函数
class GoodWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 1000,
      itemBuilder: (context, index) {
        return ListTile(title: Text('Item $index')); // 优化：可以考虑使用缓存
      },
    );
  }
}
```

#### 状态管理优化
```dart
// ✅ 使用Equatable减少不必要的重建
class FeatureState extends Equatable {
  final List<Feature> features;
  final bool isLoading;
  final String? error;

  const FeatureState({
    required this.features,
    required this.isLoading,
    this.error,
  });

  @override
  List<Object?> get props => [features, isLoading, error];

  FeatureState copyWith({
    List<Feature>? features,
    bool? isLoading,
    String? error,
  }) {
    return FeatureState(
      features: features ?? this.features,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
```

### 2. 内存优化

#### 图片优化
```dart
// 使用CachedNetworkImage缓存图片
CachedNetworkImage(
  imageUrl: 'https://example.com/image.jpg',
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
  memCacheWidth: 300, // 限制内存中的图片尺寸
  memCacheHeight: 200,
)

// 使用flutter_image_compress压缩图片
final compressedImage = await FlutterImageCompress.compressWithFile(
  imageFile.path,
  minWidth: 800,
  minHeight: 600,
  quality: 80,
);
```

#### 列表优化
```dart
// 使用AutomaticKeepAliveClientMixin保持页面状态
class FeatureListPage extends StatefulWidget {
  @override
  _FeatureListPageState createState() => _FeatureListPageState();
}

class _FeatureListPageState extends State<FeatureListPage>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用
    return ListView.builder(
      // ...
    );
  }
}
```

### 3. 网络优化

#### 请求优化
```dart
// 使用Dio的缓存和压缩
final dio = Dio();
dio.options.headers = {
  'Accept-Encoding': 'gzip, deflate', // 启用压缩
  'Cache-Control': 'max-age=3600',    // 设置缓存
};

// 添加拦截器进行缓存
dio.interceptors.add(
  DioCacheManager(
    CacheConfig(
      baseUrl: 'https://api.example.com',
      maxSize: 50 * 1024 * 1024, // 50MB
    ),
  ),
);
```

#### 并发请求优化
```dart
// 使用Future.wait并发请求
Future<List<Feature>> loadFeatures() async {
  final results = await Future.wait([
    repository.getFeatures(type: 'popular'),
    repository.getFeatures(type: 'recent'),
    repository.getFeatures(type: 'featured'),
  ]);

  return results.expand((list) => list).toList();
}
```

---

## 🐛 调试和故障排除

### 1. 常见问题

#### Flutter Doctor 问题
```bash
# 运行诊断
flutter doctor -v

# 常见解决方案:
# 1. Android licenses not accepted
flutter doctor --android-licenses

# 2. Chrome not found
# 设置CHROME_EXECUTABLE环境变量

# 3. Windows Desktop not enabled
flutter config --enable-windows-desktop
```

#### 依赖冲突
```bash
# 查看依赖树
flutter pub deps

# 解决版本冲突
# 在 pubspec.yaml 中使用 dependency_overrides
dependency_overrides:
  intl: ^0.18.1  # 强制使用特定版本
```

#### 热重载问题
```bash
# 热重载失效的常见原因:
# 1. 修改了 const 变量
# 2. 修改了枚举类型
# 3. 修改了泛型类型
# 4. 添加了新的成员变量

# 解决方案: 热重启 (按 R 键)
```

### 2. 调试技巧

#### 日志调试
```dart
import 'package:logger/logger.dart';

final logger = Logger();

// 不同级别的日志
logger.d('Debug message');
logger.i('Info message');
logger.w('Warning message');
logger.e('Error message', error: error, stackTrace: stackTrace);

// Flutter内置日志
debugPrint('Debug message');
```

#### 断点调试
```dart
// 在代码中添加断点
void calculateResult() {
  debugPrint('Starting calculation...'); // 这里可以设置断点

  final result = performCalculation();

  debugPrint('Calculation result: $result'); // 这里也可以设置断点
}
```

#### 性能调试
```dart
// 使用Flutter Inspector
// 在VS Code中:
// 1. 打开命令面板 (Ctrl+Shift+P)
// 2. 输入 "Flutter: Open Flutter Inspector"

// 使用性能分析
void performHeavyOperation() {
  final stopwatch = Stopwatch()..start();

  // 执行耗时操作
  heavyOperation();

  stopwatch.stop();
  debugPrint('Operation took: ${stopwatch.elapsedMilliseconds}ms');
}
```

---

## 📝 代码规范

### 1. Dart/Flutter 代码规范

#### 命名规范
```dart
// 类名: PascalCase
class FundAnalysisService {}

// 变量名: camelCase
final fundAnalysisService = FundAnalysisService();

// 常量名: SCREAMING_SNAKE_CASE
const API_BASE_URL = 'https://api.example.com';

// 私有成员: 下划线前缀
class _PrivateClass {
  String _privateField;
  void _privateMethod() {}
}
```

#### 文件组织
```dart
// 文件头部注释
/// 基金分析服务
///
/// 提供基金数据分析和处理功能
library fund_analysis_service;

// 导入顺序
import 'dart:async';      // dart库
import 'package:flutter/material.dart';  // flutter库
import 'package:dartz/dartz.dart';       // 第三方库
import '../../core/errors/failures.dart'; // 项目库
import '../entities/fund.dart';           // 相对路径

// 类定义
class FundAnalysisService {
  // 公共字段
  final String apiKey;

  // 私有字段
  late final FundRepository _repository;

  // 构造函数
  FundAnalysisService({
    required this.apiKey,
    required FundRepository repository,
  }) : _repository = repository;

  // 公共方法
  Future<Either<Failure, List<Fund>>> analyzeFunds() async {
    // 实现
  }

  // 私有方法
  List<Fund> _filterFunds(List<Fund> funds) {
    // 实现
  }
}
```

### 2. Git 工作流

#### 分支策略
```bash
# 主分支
main        # 生产代码
develop     # 开发代码

# 功能分支
feature/fund-analysis    # 新功能
feature/ui-redesign      # UI重设计

# 修复分支
hotfix/critical-bug      # 紧急修复
bugfix/minor-issue       # 小修复

# 发布分支
release/v0.6.0         # 发布准备
```

#### 提交规范
```bash
# 提交消息格式
<type>(<scope>): <description>

# 类型:
feat:     新功能
fix:      修复bug
docs:     文档更新
style:    代码格式化
refactor: 代码重构
test:     测试相关
chore:    构建工具或辅助工具的变动

# 示例:
feat(fund): add fund analysis feature
fix(api): resolve null pointer exception
docs(readme): update installation guide
```

---

## 🔌 集成和部署

### 1. API集成

#### 创建API客户端
```dart
// lib/src/core/network/api_client.dart
class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.instance.apiBaseUrl,
      connectTimeout: Duration(seconds: 30),
      receiveTimeout: Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _setupInterceptors();
  }

  void _setupInterceptors() {
    // 日志拦截器
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));

    // 错误处理拦截器
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          _handleError(error);
          handler.next(error);
        },
      ),
    );
  }

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get<T>(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(String path, {dynamic data}) {
    return _dio.post<T>(path, data: data);
  }
}
```

#### API响应处理
```dart
// 统一的API响应模型
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int? code;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.code,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(Object?) fromJson) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      data: json['data'] != null ? fromJson(json['data']) : null,
      error: json['error'],
      code: json['code'],
    );
  }
}
```

### 2. 数据库集成

#### Hive数据库配置
```dart
// lib/src/core/database/hive_config.dart
class HiveConfig {
  static const String _dbName = 'baostock_db';
  static const int _dbVersion = 1;

  static Future<void> initialize() async {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    final dbPath = '${appDocumentDir.path}/$_dbName';

    await Hive.initFlutter(dbPath);

    // 注册适配器
    _registerAdapters();

    // 打开数据库
    await _openBoxes();
  }

  static void _registerAdapters() {
    Hive.registerAdapter(FundInfoAdapter());
    Hive.registerAdapter(PortfolioAdapter());
    Hive.registerAdapter(UserPreferencesAdapter());
  }

  static Future<void> _openBoxes() async {
    await Hive.openBox<FundInfo>('funds');
    await Hive.openBox<Portfolio>('portfolios');
    await Hive.openBox<UserPreferences>('preferences');
  }
}
```

### 3. 环境配置

#### 多环境配置
```dart
// lib/src/core/config/app_config.dart
enum AppEnvironment { development, staging, production }

class AppConfig {
  static AppConfig? _instance;
  static AppConfig get instance => _instance ??= AppConfig._();

  late final AppEnvironment environment;
  late final String apiBaseUrl;
  late final String databaseUrl;
  late final bool enableDebugging;

  AppConfig._();

  Future<void> loadConfig() async {
    final env = String.fromEnvironment('FLUTTER_ENV', defaultValue: 'development');
    environment = AppEnvironment.values.firstWhere(
      (e) => e.name == env,
      orElse: () => AppEnvironment.development,
    );

    await dotenv.load(fileName: _getEnvFileName());

    apiBaseUrl = dotenv.env['API_BASE_URL'] ?? _getDefaultApiUrl();
    databaseUrl = dotenv.env['DATABASE_URL'] ?? _getDefaultDatabaseUrl();
    enableDebugging = environment != AppEnvironment.production;
  }

  String _getEnvFileName() {
    switch (environment) {
      case AppEnvironment.development:
        return '.env.development';
      case AppEnvironment.staging:
        return '.env.staging';
      case AppEnvironment.production:
        return '.env.production';
    }
  }
}
```

---

## 📚 学习资源

### 官方文档
- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Language Guide](https://dart.dev/guides)
- [BLoC Library](https://bloclibrary.dev)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)

### 推荐书籍
- "Flutter in Action" - Eric Windmill
- "Beginning Flutter" - Marco Napoli
- "Clean Architecture" - Robert C. Martin

### 在线课程
- Flutter & Dart - Complete Development Course
- Advanced Flutter & Firebase
- Flutter Clean Architecture

### 社区资源
- [Flutter Community](https://flutter.dev/community)
- [DartLang Gitter](https://gitter.im/dart-lang/home)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)

---

## 🤝 贡献指南

### 开发流程
1. Fork 项目仓库
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'feat: add amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建 Pull Request

### 代码审查
- 确保所有测试通过
- 遵循代码规范
- 更新相关文档
- 提供清晰的PR描述

### 发布流程
1. 更新版本号
2. 更新CHANGELOG
3. 创建发布标签
4. 自动构建和发布

---

这份开发指南涵盖了基速基金量化分析平台的完整开发流程，从环境设置到部署发布。遵循这些指南，开发者可以高效地为项目做出贡献。