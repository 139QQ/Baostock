# Epic 2: 数据层架构

## 史诗概述
构建完整的数据层架构，包括API服务集成、数据模型设计、缓存机制实现和状态管理(BLoC)，确保数据的高效获取、存储、同步和管理，为应用提供稳定可靠的数据支撑。

## 史诗目标
- 建立统一的API服务集成层，支持多数据源和降级机制
- 设计完整的数据模型体系，覆盖基金相关的所有业务数据
- 实现高性能的多级缓存机制，提升应用响应速度
- 构建基于BLoC的响应式状态管理系统
- 建立数据同步和一致性保障机制

## 功能范围

### 1. API服务集成
**技术要求:**
- 支持自建API服务 (http://154.44.25.92:8080/)
- 集成AKShare基金数据接口
- 实现多数据源降级机制
- 支持请求重试和错误处理

**API集成架构:**
```dart
// 统一API客户端配置
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
      RetryInterceptor(retries: 3),
      CacheInterceptor(),
    ]);
  }
}

// 多数据源配置
class DataSourceConfig {
  static const String primaryUrl = 'http://154.44.25.92:8080/';
  static const String fallbackUrl = 'https://aktools.akfamily.xyz/aktools/';
  static const String mockDataPath = 'assets/mock/';
}
```

**基金数据API接口:**
```dart
abstract class IFundApi {
  // 基金排行
  Future<List<FundRanking>> getFundRankings(String category, {int page = 1, int pageSize = 20});

  // 基金详情
  Future<FundDetail> getFundDetail(String fundCode);

  // 基金净值
  Future<List<FundNav>> getFundNavHistory(String fundCode, {DateTime? startDate, DateTime? endDate});

  // 基金筛选
  Future<List<FundInfo>> searchFunds(String keyword, {Map<String, dynamic>? filters});
}

// 自建API实现
class CustomFundApi implements IFundApi {
  final ApiClient _client;

  @override
  Future<List<FundRanking>> getFundRankings(String category, {int page = 1, int pageSize = 20}) async {
    final response = await _client.get('/fund/rankings/$category', queryParameters: {
      'page': page,
      'pageSize': pageSize,
    });

    return (response.data as List)
        .map((json) => FundRanking.fromJson(json))
        .toList();
  }
}
```

### 2. 数据模型设计
**核心数据模型:**
```dart
// 基金基础信息
class FundInfo {
  final String fundCode;
  final String fundName;
  final String fundType;
  final String companyCode;
  final String companyName;
  final DateTime? establishmentDate;
  final double? fundScale;
  final String status;

  FundInfo({
    required this.fundCode,
    required this.fundName,
    required this.fundType,
    required this.companyCode,
    required this.companyName,
    this.establishmentDate,
    this.fundScale,
    this.status = 'active',
  });

  factory FundInfo.fromJson(Map<String, dynamic> json) => _$FundInfoFromJson(json);
  Map<String, dynamic> toJson() => _$FundInfoToJson(this);
}

// 基金排行数据
class FundRanking {
  final String fundCode;
  final String fundName;
  final String category;
  final int rankingPosition;
  final double returnRate;
  final String rankingPeriod; // 1W, 1M, 3M, 6M, 1Y, 2Y, 3Y, YTD
  final DateTime rankingDate;
  final int totalCount;

  FundRanking({
    required this.fundCode,
    required this.fundName,
    required this.category,
    required this.rankingPosition,
    required this.returnRate,
    required this.rankingPeriod,
    required this.rankingDate,
    required this.totalCount,
  });

  factory FundRanking.fromJson(Map<String, dynamic> json) => _$FundRankingFromJson(json);
}

// 基金净值数据
class FundNav {
  final String fundCode;
  final DateTime navDate;
  final double unitNav;
  final double accumulatedNav;
  final double? dailyReturn;

  FundNav({
    required this.fundCode,
    required this.navDate,
    required this.unitNav,
    required this.accumulatedNav,
    this.dailyReturn,
  });

  factory FundNav.fromJson(Map<String, dynamic> json) => _$FundNavFromJson(json);
}
```

**数据验证和转换:**
```dart
// 数据验证器
class FundDataValidator {
  static bool validateFundCode(String fundCode) {
    final regex = RegExp(r'^[0-9]{6}$');
    return regex.hasMatch(fundCode);
  }

  static bool validateReturnRate(double returnRate) {
    return returnRate >= -100 && returnRate <= 1000;
  }

  static DateTime? parseDate(String? dateStr) {
    if (dateStr == null) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return null;
    }
  }
}
```

### 3. 缓存机制实现
**多级缓存架构:**
```dart
// 缓存抽象层
abstract class CacheService {
  Future<T?> get<T>(String key);
  Future<void> set<T>(String key, T value, {Duration? expiration});
  Future<void> remove(String key);
  Future<void> clear();
}

// Hive缓存实现
class HiveCacheService implements CacheService {
  final Box<dynamic> _box;

  HiveCacheService(this._box);

  @override
  Future<T?> get<T>(String key) async {
    final value = _box.get(key);
    if (value == null) return null;

    // 检查过期时间
    if (value is Map && value.containsKey('expireAt')) {
      final expireAt = DateTime.parse(value['expireAt']);
      if (DateTime.now().isAfter(expireAt)) {
        await remove(key);
        return null;
      }
    }

    return value as T?;
  }

  @override
  Future<void> set<T>(String key, T value, {Duration? expiration}) async {
    if (expiration != null) {
      final cacheData = {
        'data': value,
        'expireAt': DateTime.now().add(expiration).toIso8601String(),
      };
      await _box.put(key, cacheData);
    } else {
      await _box.put(key, value);
    }
  }
}

// 缓存策略配置
class CachePolicy {
  static const Duration fundRankingsCache = Duration(minutes: 15);
  static const Duration fundDetailCache = Duration(minutes: 30);
  static const Duration fundNavCache = Duration(hours: 24);
  static const Duration searchResultsCache = Duration(minutes: 10);
}
```

### 4. 状态管理(BLoC)
**BLoC架构设计:**
```dart
// 基金排行BLoC
class FundRankingBloc extends Bloc<FundRankingEvent, FundRankingState> {
  final GetFundRankings _getFundRankings;
  final CacheService _cacheService;

  FundRankingBloc({
    required GetFundRankings getFundRankings,
    required CacheService cacheService,
  }) : _getFundRankings = getFundRankings,
       _cacheService = cacheService,
       super(FundRankingState.initial()) {
    on<LoadFundRankings>(_onLoadFundRankings);
    on<RefreshFundRankings>(_onRefreshFundRankings);
    on<ChangeRankingCategory>(_onChangeRankingCategory);
  }

  Future<void> _onLoadFundRankings(
    LoadFundRankings event,
    Emitter<FundRankingState> emit,
  ) async {
    emit(state.copyWith(status: LoadStatus.loading));

    try {
      // 1. 尝试从缓存获取
      final cacheKey = 'fund_rankings_${event.category}';
      final cachedData = await _cacheService.get<List<FundRanking>>(cacheKey);

      if (cachedData != null) {
        emit(state.copyWith(
          rankings: cachedData,
          status: LoadStatus.success,
        ));
        return;
      }

      // 2. 从API获取数据
      final rankings = await _getFundRankings(
        category: event.category,
        page: event.page,
        pageSize: event.pageSize,
      );

      // 3. 缓存数据
      await _cacheService.set(cacheKey, rankings, expiration: CachePolicy.fundRankingsCache);

      emit(state.copyWith(
        rankings: rankings,
        status: LoadStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: LoadStatus.error,
        error: e.toString(),
      ));
    }
  }
}

// 状态定义
class FundRankingState {
  final List<FundRanking> rankings;
  final LoadStatus status;
  final String? error;
  final String currentCategory;
  final int currentPage;
  final bool hasMore;

  const FundRankingState({
    required this.rankings,
    required this.status,
    this.error,
    required this.currentCategory,
    required this.currentPage,
    required this.hasMore,
  });

  factory FundRankingState.initial() {
    return FundRankingState(
      rankings: [],
      status: LoadStatus.initial,
      currentCategory: '股票型',
      currentPage: 1,
      hasMore: true,
    );
  }
}
```

**全局状态管理:**
```dart
// 应用状态
class AppState {
  final UserState user;
  final FundState fund;
  final SettingsState settings;
  final NavigationState navigation;

  const AppState({
    required this.user,
    required this.fund,
    required this.settings,
    required this.navigation,
  });

  factory AppState.initial() {
    return AppState(
      user: UserState.initial(),
      fund: FundState.initial(),
      settings: SettingsState.initial(),
      navigation: NavigationState.initial(),
    );
  }
}

// 状态观察器
class StateObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    print('${bloc.runtimeType} $change');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    print('${bloc.runtimeType} $error');
  }
}
```

## 验收标准

### 功能验收
- [ ] API客户端支持多数据源和自动降级
- [ ] 数据模型覆盖所有基金相关业务场景
- [ ] 多级缓存机制正常工作，命中率 > 80%
- [ ] BLoC状态管理系统响应及时，无内存泄漏
- [ ] 数据同步机制保证数据一致性

### 性能验收
- [ ] API响应时间 < 500ms（95th percentile）
- [ ] 缓存读取时间 < 50ms
- [ ] 状态管理性能开销 < 10%
- [ ] 数据序列化/反序列化时间 < 100ms

### 质量验收
- [ ] 所有数据模型包含完整的验证逻辑
- [ ] 错误处理覆盖所有异常情况
- [ ] 单元测试覆盖率 > 85%
- [ ] 集成测试验证API和缓存功能

## 开发时间估算

### 工作量评估
- **API服务集成**: 24小时
- **数据模型设计**: 16小时
- **缓存机制实现**: 20小时
- **BLoC状态管理**: 24小时
- **数据同步机制**: 16小时
- **测试和优化**: 16小时

**总计: 116小时（约14.5个工作日）**

## 依赖关系

### 前置依赖
- Epic 1: 基础架构搭建完成
- API服务接口文档确认
- 数据需求分析完成

### 后续影响
- 为所有业务功能提供数据支持
- 影响应用整体性能和用户体验
- 决定数据一致性和可靠性

## 风险评估

### 技术风险
| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| API服务不稳定 | 高 | 高 | 实现完善的降级机制和重试策略 |
| 缓存一致性问题 | 中 | 中 | 设计合理的缓存失效策略 |
| 状态管理复杂性 | 中 | 中 | 采用成熟BLoC模式，严格状态分层 |

### 性能风险
| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| 大数据量处理性能问题 | 中 | 高 | 实现分页加载和虚拟滚动 |
| 缓存穿透问题 | 低 | 中 | 实现布隆过滤器和热点数据预加载 |

## 资源需求

### 人员配置
- **后端开发工程师**: 2人
- **Flutter开发工程师**: 2人
- **数据架构师**: 1人（兼职）
- **测试工程师**: 1人（兼职）

### 技术资源
- API测试环境
- 数据库开发环境
- Redis缓存服务
- 性能测试工具

## 交付物

### 代码交付
- API客户端和服务集成代码
- 完整的数据模型定义
- 缓存服务实现代码
- BLoC状态管理代码

### 文档交付
- API集成文档
- 数据模型设计文档
- 缓存策略说明
- 状态管理使用指南

### 测试交付
- API集成测试用例
- 数据模型验证测试
- 缓存性能测试报告
- 状态管理测试用例

---

**史诗负责人:** 数据架构师
**预计开始时间:** 2025-10-16
**预计完成时间:** 2025-11-05
**优先级:** P0（最高）
**状态:** 待开始
**依赖史诗:** Epic 1