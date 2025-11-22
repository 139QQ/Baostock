# 状态管理开发规范

## 概述

本文档定义了基速基金量化分析平台中状态管理的开发规范和最佳实践。所有开发人员必须遵循这些规范以确保代码质量和一致性。

## 状态管理模式选择

### 默认选择

- **新项目**: 必须使用BLoC模式
- **现有模块**: 逐步从Cubit迁移到BLoC
- **临时功能**: 可使用Cubit，但必须有明确的迁移计划

### 选择标准

| 场景 | 推荐模式 | 理由 |
|------|----------|------|
| 复杂业务逻辑 | BLoC | 事件驱动架构更适合复杂状态流转 |
| 简单UI状态 | Cubit | 简单直接，开发效率高 |
| 跨页面状态 | BLoC + GlobalStateManager | 统一的状态管理模式 |
| 临时功能 | Cubit | 快速开发，后续可迁移 |

## BLoC开发规范

### 文件结构

```
lib/src/features/feature_name/
├── domain/
│   ├── entities/
│   │   └── feature_entity.dart
│   └── events/
│       └── feature_event.dart
├── presentation/
│   └── bloc/
│       ├── feature_bloc.dart
│       └── feature_state.dart
└── data/
    ├── repositories/
    └── datasources/
```

### 命名规范

#### BLoC类命名
```dart
// ✅ 正确的命名
class UserAuthenticationBloc extends Bloc<UserAuthenticationEvent, UserAuthenticationState>

class FundSearchBloc extends Bloc<FundSearchEvent, FundSearchState>

// ❌ 错误的命名
class UserBloc // 过于笼统
class Search // 没有Bloc后缀
class FundSearchManager // 不是BLoC
```

#### Event命名
```dart
// ✅ 正确的命名
abstract class UserAuthenticationEvent extends Equatable {}
class LoginRequested extends UserAuthenticationEvent {}
class LogoutRequested extends UserAuthenticationEvent {}
class ProfileUpdated extends UserAuthenticationEvent {}

// ❌ 错误的命名
class UserEvent // 过于笼统
class Login // 缺少动词，不够明确
class OnLoginClick // 体现UI交互，而非业务事件
```

#### State命名
```dart
// ✅ 正确的命名
abstract class UserAuthenticationState extends Equatable {}
class UserAuthenticationInitial extends UserAuthenticationState {}
class UserAuthenticationLoading extends UserAuthenticationState {}
class UserAuthenticationSuccess extends UserAuthenticationState {}
class UserAuthenticationFailure extends UserAuthenticationState {}

// ❌ 错误的命名
class UserState // 过于笼统
class LoginState // 没有体现完整的认证状态
class Loading // 缺少上下文
```

### BLoC实现规范

#### 基本结构
```dart
class UserAuthenticationBloc extends Bloc<UserAuthenticationEvent, UserAuthenticationState> {
  final UserRepository _userRepository;
  final AnalyticsService _analyticsService;

  UserAuthenticationBloc({
    required UserRepository userRepository,
    required AnalyticsService analyticsService,
  }) : _userRepository = userRepository,
       _analyticsService = analyticsService,
       super(UserAuthenticationInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<ProfileUpdated>(_onProfileUpdated);
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<UserAuthenticationState> emit,
  ) async {
    emit(UserAuthenticationLoading());

    try {
      final user = await _userRepository.login(
        email: event.email,
        password: event.password,
      );

      await _analyticsService.trackLogin(user.id);
      emit(UserAuthenticationSuccess(user: user));
    } catch (e) {
      emit(UserAuthenticationFailure(error: e.toString()));
    }
  }

  // 其他事件处理方法...
}
```

#### 错误处理规范
```dart
// ✅ 正确的错误处理
try {
  final result = await repository.getData();
  emit(DataLoaded(data: result));
} catch (e) {
  // 记录详细错误日志
  AppLogger.error('获取数据失败', e, {
    'userId': 'current_user',
    'timestamp': DateTime.now().toIso8601String(),
  });

  // 发送有意义的错误状态
  emit(DataFailure(
    error: '获取数据失败',
    errorCode: _getErrorCode(e),
    retryable: _isRetryableError(e),
  ));
}

// ❌ 错误的错误处理
try {
  final result = await repository.getData();
  emit(DataLoaded(data: result));
} catch (e) {
  emit(DataError()); // 错误信息不够详细
}
```

### 事件设计规范

#### 事件参数
```dart
// ✅ 正确的事件设计
class FundSearchRequested extends FundSearchEvent {
  final String query;
  final int limit;
  final FundCategory? category;
  final SortOption sortBy;

  const FundSearchRequested({
    required this.query,
    this.limit = 20,
    this.category,
    this.sortBy = SortOption.defaultOption,
  });

  @override
  List<Object?> get props => [query, limit, category, sortBy];
}

// ❌ 错误的事件设计
class FundSearchRequested extends FundSearchEvent {
  String query; // 应该是final
  int limit = 10; // 应该在构造函数中指定
  // 缺少其他必要参数
}
```

#### 事件继承
```dart
// ✅ 正确的事件继承结构
abstract class FundSearchEvent extends Equatable {}

// 搜索相关事件
abstract class FundSearchQueryEvent extends FundSearchEvent {}

class FundSearchRequested extends FundSearchQueryEvent {}
class FundSearchLoadMore extends FundSearchQueryEvent {}

// 过滤相关事件
abstract class FundSearchFilterEvent extends FundSearchEvent {}

class FundSearchFilterByCategory extends FundSearchFilterEvent {}
class FundSearchFilterByRiskLevel extends FundSearchFilterEvent {}
```

### 状态设计规范

#### 状态继承
```dart
// ✅ 正确的状态设计
abstract class FundSearchState extends Equatable {
  const FundSearchState();

  @override
  List<Object?> get props => [];
}

class FundSearchInitial extends FundSearchState {}

class FundSearchLoading extends FundSearchState {
  final List<Fund> cachedResults;

  const FundSearchLoading({this.cachedResults = const []});

  @override
  List<Object?> get props => [cachedResults];
}

class FundSearchLoaded extends FundSearchState {
  final List<Fund> results;
  final bool hasReachedMax;
  final int totalCount;

  const FundSearchLoaded({
    required this.results,
    this.hasReachedMax = false,
    required this.totalCount,
  });

  @override
  List<Object?> get props => [results, hasReachedMax, totalCount];
}

class FundSearchError extends FundSearchState {
  final String message;
  final String? errorCode;

  const FundSearchError({
    required this.message,
    this.errorCode,
  });

  @override
  List<Object?> get props => [message, errorCode];
}
```

## Cubit开发规范

### 使用场景

Cubit主要用于以下场景：
- 简单的UI状态管理
- 临时功能或原型开发
- 不涉及复杂业务逻辑的状态管理

### 实现规范

```dart
class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(ThemeState.initial());

  // 使用明确的方法名
  void setLightTheme() => emit(ThemeState.light());
  void setDarkTheme() => emit(ThemeState.dark());
  void setSystemTheme() => emit(ThemeState.system());

  // 复杂逻辑需要有详细注释
  Future<void> loadUserPreference() async {
    try {
      final theme = await _themeRepository.getUserTheme();
      emit(ThemeState.fromTheme(theme));
    } catch (e) {
      AppLogger.error('加载用户主题偏好失败', e);
      emit(ThemeState.system()); // 降级到系统主题
    }
  }
}
```

## 依赖注入规范

### 服务注册

```dart
// ✅ 正确的服务注册
void setupDependencies() {
  // 单例服务
  sl.registerLazySingleton<AnalyticsService>(() => AnalyticsService());

  // 有依赖的服务
  sl.registerLazySingleton<UserRepository>(() => UserRepositoryImpl(
    apiClient: sl<ApiClient>(),
    cacheManager: sl<CacheManager>(),
  ));

  // BLoC工厂
  sl.registerLazySingleton<UserBlocFactory>(() => UserBlocFactory());
}
```

### 依赖获取

```dart
// ✅ 正确的依赖获取
class UserBloc extends Bloc<UserEvent, UserState> {
  final UserRepository _userRepository;
  final AnalyticsService _analyticsService;

  UserBloc()
      : _userRepository = sl<UserRepository>(),
       _analyticsService = sl<AnalyticsService>(),
       super(UserInitial()) {
    // 初始化逻辑
  }
}

// ❌ 错误的依赖获取
class UserBloc extends Bloc<UserEvent, UserState> {
  UserBloc() : super(UserInitial()) {
    // 在BLoC内部直接调用全局服务
    final userRepository = UserRepositoryImpl(); // 应该通过依赖注入
  }
}
```

## 测试规范

### BLoC测试

```dart
// ✅ 正确的BLoC测试
void main() {
  group('UserBloc', () {
    late UserRepository mockRepository;
    late AnalyticsService mockAnalytics;
    late UserBloc userBloc;

    setUp(() {
      mockRepository = MockUserRepository();
      mockAnalytics = MockAnalyticsService();
      userBloc = UserBloc(
        userRepository: mockRepository,
        analyticsService: mockAnalytics,
      );
    });

    tearDown(() {
      userBloc.close();
    });

    test('初始状态是UserInitial', () {
      expect(userBloc.state, equals(UserInitial()));
    });

    blocTest<UserBloc, UserState>(
      '登录成功时发出UserAuthenticationSuccess',
      build: () => userBloc,
      act: (bloc) => bloc.add(LoginRequested(
        email: 'test@example.com',
        password: 'password',
      )),
      setUp: () {
        when(mockRepository.login(any, any))
            .thenAnswer((_) async => mockUser);
      },
      expect: () => [
        UserAuthenticationLoading(),
        UserAuthenticationSuccess(user: mockUser),
      ],
      verify: (_) {
        verify(mockRepository.login('test@example.com', 'password')).called(1);
        verify(mockAnalytics.trackLogin(mockUser.id)).called(1);
      },
    );
  });
}
```

### Cubit测试

```dart
// ✅ 正确的Cubit测试
void main() {
  group('ThemeCubit', () {
    late ThemeCubit themeCubit;

    setUp(() {
      themeCubit = ThemeCubit();
    });

    tearDown(() {
      themeCubit.close();
    });

    test('初始状态是系统主题', () {
      expect(themeCubit.state, equals(ThemeState.system()));
    });

    test('切换到亮色主题', () {
      themeCubit.setLightTheme();
      expect(themeCubit.state, equals(ThemeState.light()));
    });

    test('切换到暗色主题', () {
      themeCubit.setDarkTheme();
      expect(themeCubit.state, equals(ThemeState.dark()));
    });
  });
}
```

## 性能优化规范

### 状态优化

```dart
// ✅ 正确的状态优化
class FundListState extends Equatable {
  final List<Fund> funds;
  final bool isLoading;
  final String? error;

  const FundListState({
    this.funds = const [],
    this.isLoading = false,
    this.error,
  });

  FundListState copyWith({
    List<Fund>? funds,
    bool? isLoading,
    String? error,
  }) {
    return FundListState(
      funds: funds ?? this.funds,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [funds, isLoading, error];
}
```

### 事件批处理

```dart
// ✅ 正确的事件批处理
blocTest<FundSearchBloc, FundSearchState>(
  '连续搜索请求只处理最后一个',
  build: () => fundSearchBloc,
  act: (bloc) {
    bloc.add(FundSearchRequested(query: '基金'));
    bloc.add(FundSearchRequested(query: '基金A'));
    bloc.add(FundSearchRequested(query: '基金AB'));
  },
  expect: () => [
    FundSearchLoading(),
    FundSearchLoaded(results: ['基金AB']), // 只处理最后一个
  ],
);
```

## 调试和日志规范

### 日志级别

```dart
// ✅ 正确的日志使用
class FundBloc extends Bloc<FundEvent, FundState> {
  Future<void> _onLoadFunds(
    LoadFunds event,
    Emitter<FundState> emit,
  ) async {
    AppLogger.debug('开始加载基金数据', {
      'eventId': event.runtimeType.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    });

    emit(FundLoading());

    try {
      final funds = await _repository.getFunds();

      AppLogger.info('基金数据加载成功', {
        'count': funds.length,
        'executionTime': _stopwatch.elapsedMilliseconds,
      });

      emit(FundLoaded(funds: funds));
    } catch (e) {
      AppLogger.error('基金数据加载失败', e, {
        'eventId': event.runtimeType.toString(),
      });

      emit(FundError(error: e.toString()));
    }
  }
}
```

### 性能监控

```dart
// ✅ 正确的性能监控
class FundBloc extends Bloc<FundEvent, FundState> {
  final Stopwatch _stopwatch = Stopwatch();

  Future<void> _onLoadFunds(
    LoadFunds event,
    Emitter<FundState> emit,
  ) async {
    _stopwatch.start();

    try {
      final funds = await _repository.getFunds();

      _stopwatch.stop();
      _trackPerformance('load_funds', _stopwatch.elapsedMilliseconds);

      emit(FundLoaded(funds: funds));
    } catch (e) {
      _stopwatch.stop();
      _trackPerformance('load_funds_error', _stopwatch.elapsedMilliseconds);

      emit(FundError(error: e.toString()));
    } finally {
      _stopwatch.reset();
    }
  }

  void _trackPerformance(String operation, int durationMs) {
    if (durationMs > 1000) {
      AppLogger.warning('性能警告', null, {
        'operation': operation,
        'duration': durationMs,
      });
    } else {
      AppLogger.debug('性能指标', null, {
        'operation': operation,
        'duration': durationMs,
      });
    }
  }
}
```

## 代码审查清单

### BLoC审查要点

- [ ] 命名规范是否正确
- [ ] Event和State是否使用Equatable
- [ ] 错误处理是否完善
- [ ] 依赖注入是否正确
- [ ] 日志记录是否充分
- [ ] 性能优化是否合理
- [ ] 测试覆盖率是否达标

### Cubit审查要点

- [ ] 使用场景是否合适
- [ ] 状态是否过于复杂（应该用BLoC）
- [ ] 方法命名是否清晰
- [ ] 错误处理是否完善
- [ ] 测试是否充分

## 迁移指南

### Cubit到BLoC迁移步骤

1. **分析状态复杂度**
   - 如果状态流转复杂，直接使用BLoC
   - 如果状态简单，考虑保留Cubit

2. **创建Event类**
   - 将Cubit方法转换为Event类
   - 保持参数的一致性

3. **创建State类**
   - 将Cubit状态转换为State类
   - 使用Equatable进行优化

4. **实现BLoC类**
   - 将Cubit逻辑转换为BLoC事件处理
   - 保持业务逻辑的一致性

5. **更新UI层**
   - 使用BlocBuilder替代BlocProvider
   - 添加事件触发逻辑

6. **添加测试**
   - 为新的BLoC添加测试
   - 确保行为与原Cubit一致

## 参考资料

1. [Flutter BLoC官方文档](https://bloclibrary.dev/)
2. [Effective Dart: Style Guide](https://dart.dev/guides/language/effective-dart/style)
3. [Flutter Testing Documentation](https://docs.flutter.dev/cookbook/testing)

---

**文档维护**: 开发团队
**最后更新**: 2025-11-17
**版本**: 1.0.0