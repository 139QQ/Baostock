# 基速基金量化分析平台 - 决策架构文档

## Executive Summary

基速基金量化分析平台架构采用Flutter + Clean Architecture + BLoC模式，实现"专业可靠"的产品魔法。通过智能自适应UI、实时数据同步和金融级数据验证，为普通投资者提供机构级别的分析工具和银行级的使用体验。架构支持Windows桌面应用优先，兼顾移动端跨平台一致性，通过多层缓存和性能优化确保专业工具的响应速度和稳定性。

## Decision Summary

| Category | Decision | Version | Affects Epics | Rationale |
| -------- | -------- | ------- | ------------- | --------- |
| 实时数据架构 | 混合同步策略 (WebSocket + HTTP轮询) | web_socket_channel 2.4.0 | Epic 1 (全部) | 关键数据实时推送，批量数据定期同步，网络异常智能降级 |
| UI组件架构 | 分层组件设计 (基础层+交互层+业务层) | Flutter 3.13.0 | Story 1.3, 1.4, 1.6 | 单一数据源，性能分级自适应，状态同步一致性 |
| 动画优化 | 三级自适应系统 (禁用/基础/增强) | flutter_animate 4.2.0 | Story 1.3, 1.5, 1.6 | 设备性能自动检测，运行时动态调整，用户偏好记忆 |
| 错误处理 | 多层错误处理架构 (全局+局部) | 自定义实现 | Epic 1 (全部) | 金融级可靠性要求，优雅降级，自动重试机制 |
| 数据持久化 | 三级缓存系统 (内存+Hive+远程) | Hive 2.2.3 | Epic 1 (全部) | 高性能本地存储，离线能力，数据一致性保证 |
| 状态管理 | BLoC/Cubit混合模式 | flutter_bloc 8.1.3 | Epic 1 (全部) | 业务逻辑与UI分离，可测试性，状态可预测 |

## Project Structure

```
D:\Git\Github\Baostock/
├── lib/
│   ├── main.dart                           # 应用入口
│   └── src/
│       ├── core/                           # 核心模块
│       │   ├── cache/                      # 统一缓存系统
│       │   │   ├── unified_hive_cache_manager.dart
│       │   │   ├── cache_strategy.dart
│       │   │   └── performance_optimizer.dart
│       │   ├── network/                    # 网络层
│       │   │   ├── hybrid/                 # 混合数据获取架构
│       │   │   │   ├── hybrid_data_manager.dart
│       │   │   │   ├── data_fetch_strategy.dart
│       │   │   │   ├── http_polling_strategy.dart
│       │   │   │   ├── websocket_strategy.dart
│       │   │   │   └── data_type_router.dart
│       │   │   ├── polling/                # HTTP轮询管理
│       │   │   │   ├── polling_manager.dart
│       │   │   │   ├── polling_scheduler.dart
│       │   │   │   └── network_monitor.dart
│       │   │   └── realtime/               # 实时数据架构(扩展)
│       │   │       ├── websocket_manager.dart
│       │   │       └── data_sync_service.dart
│       │   │   │   └── fallback_http_service.dart
│       │   │   ├── api/                    # API客户端
│       │   │   │   ├── fund_api_client.dart
│       │   │   │   └── market_data_client.dart
│       │   │   └── error_handling/         # 错误处理
│       │   │       ├── global_error_boundary.dart
│       │   │       ├── network_exception_handler.dart
│       │   │       └── data_validation_handler.dart
│       │   ├── state/                      # 全局状态管理
│       │   │   ├── global_cubit_manager.dart
│       │   │   ├── hybrid_data_status_cubit.dart
│       │   │   ├── realtime_settings_cubit.dart
│       │   │   └── realtime_data_cubit.dart
│       │   │   └── user_preferences_cubit.dart
│       │   ├── utils/                      # 工具类
│       │   │   ├── performance_detector.dart    # 设备性能检测
│       │   │   ├── animation_controller.dart    # 动画控制器
│       │   │   ├── time_utils.dart             # 时间处理
│       │   │   └── validation_utils.dart       # 数据验证
│       │   └── constants/                  # 常量定义
│       │       ├── error_codes.dart
│       │       ├── api_endpoints.dart
│       │       └── animation_levels.dart
│       ├── features/                       # 功能模块 (Clean Architecture)
│       │   ├── fund/                       # 基金核心功能
│       │   │   ├── data/                   # 数据层
│       │   │   │   ├── datasources/        # 数据源
│       │   │   │   │   ├── fund_remote_datasource.dart
│       │   │   │   │   ├── fund_local_datasource.dart
│       │   │   │   │   └── market_data_datasource.dart
│       │   │   │   ├── models/             # 数据模型
│       │   │   │   │   ├── fund_info_model.dart
│       │   │   │   │   ├── market_data_model.dart
│       │   │   │   │   └── recommendation_model.dart
│       │   │   │   └── repositories/       # 仓库实现
│       │   │   │       ├── fund_repository_impl.dart
│       │   │   │       └── realtime_data_repository_impl.dart
│       │   │   ├── domain/                 # 领域层
│       │   │   │   ├── entities/           # 实体
│       │   │   │   │   ├── fund.dart
│       │   │   │   │   ├── market_index.dart
│       │   │   │   │   └── recommendation.dart
│       │   │   │   ├── repositories/       # 仓库接口
│       │   │   │   │   ├── fund_repository.dart
│       │   │   │   │   └── realtime_data_repository.dart
│       │   │   │   └── usecases/           # 用例
│       │   │   │       ├── search_funds_usecase.dart
│       │   │   │       ├── get_fund_details_usecase.dart
│       │   │   │       ├── compare_funds_usecase.dart
│       │   │   │       └── get_recommendations_usecase.dart
│       │   │   └── presentation/          # 表现层
│       │   │       ├── pages/              # 页面
│       │   │       │   ├── fund_exploration_page.dart
│       │   │       │   ├── fund_comparison_page.dart
│       │   │       │   └── fund_detail_page.dart
│       │   │       ├── cubits/             # 状态管理
│       │   │       │   ├── fund_search_cubit.dart
│       │   │       │   ├── fund_comparison_cubit.dart
│       │   │       │   └── fund_recommendation_cubit.dart
│       │   │       └── widgets/            # UI组件
│       │   │           ├── cards/          # 卡片组件
│       │   │           │   ├── base/      # 基础层
│       │   │           │   │   ├── base_fund_card.dart
│       │   │           │   │   ├── base_action_button.dart
│       │   │           │   │   └── base_text_field.dart
│       │   │           │   ├── interactive/ # 交互层
│       │   │           │   │   ├── adaptive_fund_card.dart
│       │   │           │   │   ├── microinteractive_fund_card.dart
│       │   │           │   │   └── gesture_handler.dart
│       │   │           │   └── business/   # 业务层
│       │   │           │       ├── recommendation_card.dart
│       │   │           │       ├── comparison_card.dart
│       │   │           │       └── search_result_card.dart
│       │   │           ├── panels/         # 面板组件
│       │   │           │   ├── tool_panel_container.dart
│       │   │           │   ├── filter_panel.dart
│       │   │           │   └── calculator_panel.dart
│       │   │           └── layouts/        # 布局组件
│       │   │               ├── minimalist_main_layout.dart
│       │   │               └── collapsible_section.dart
│       │   ├── search/                      # 搜索功能模块
│       │   │   ├── data/
│       │   │   ├── domain/
│       │   │   └── presentation/
│       │   │       ├── widgets/
│       │   │       │   ├── unified_search_bar.dart
│       │   │       │   ├── search_suggestions.dart
│       │   │       │   └── search_history.dart
│       │   │       └── cubits/
│       │   │           └── unified_search_cubit.dart
│       │   ├── comparison/                  # 对比功能模块
│       │   │   └── presentation/
│       │   │       ├── widgets/
│       │   │       │   ├── comparison_slider.dart
│       │   │       │   ├── metrics_progress_bar.dart
│       │   │       │   └── comparison_export_dialog.dart
│       │   │       └── cubits/
│       │   │           └── fund_comparison_cubit.dart
│       │   └── recommendations/             # 推荐功能模块
│       │       └── presentation/
│       │           ├── widgets/
│       │           │   ├── recommendation_carousel.dart
│       │           │   ├── recommendation_card.dart
│       │           │   └── recommendation_reasoning.dart
│       │           └── cubits/
│       │               └── recommendation_cubit.dart
│       ├── navigation/                     # 导航外壳
│       │   ├── navigation_shell.dart
│       │   └── app_routes.dart
│       ├── shared/                         # 共享组件
│       │   ├── widgets/
│       │   │   ├── error_boundary.dart
│       │   │   ├── loading_indicator.dart
│       │   │   └── empty_state.dart
│       │   ├── themes/
│       │   │   ├── app_theme.dart
│       │   │   ├── color_scheme.dart
│       │   │   └── text_styles.dart
│       │   └── constants/
│       │       ├── app_constants.dart
│       │       └── layout_constants.dart
│       └── services/                       # 业务服务
│           ├── initialization_service.dart
│           ├── performance_monitoring_service.dart
│           └── logging_service.dart
├── test/                                   # 测试文件
│   ├── unit/                               # 单元测试
│   │   ├── core/
│   │   ├── features/
│   │   └── shared/
│   ├── integration/                        # 集成测试
│   │   ├── data_flow_test.dart
│   │   ├── api_integration_test.dart
│   │   └── cache_strategy_test.dart
│   └── widget/                             # 组件测试
│       ├── fund_cards_test.dart
│       └── search_widgets_test.dart
├── docs/                                   # 文档
│   ├── architecture.md                     # 架构文档
│   ├── api/                               # API文档
│   └── user_guides/                       # 用户指南
└── analysis_options.yaml                  # 分析配置
```

## Epic to Architecture Mapping

### Epic 1: 基金探索界面极简重构

| Story | Architecture Component | Location | Integration Points |
|-------|-----------------------|----------|-------------------|
| Story 1.1 统一搜索服务重构 | UnifiedSearchCubit + SearchFundsUseCase | `features/search/` | 与现有FundRepository兼容，复用Hive缓存 |
| Story 1.2 极简主界面布局重构 | MinimalistMainLayout + CollapsibleSection | `features/fund/presentation/pages/` | 与NavigationShell集成，保持路由兼容性 |
| Story 1.3 微交互基金卡片设计 | AdaptiveFundCard + MicrointeractiveFundCard | `features/fund/presentation/widgets/cards/` | 与BLoC状态同步，支持设备性能自适应 |
| Story 1.4 智能推荐系统极简实现 | RecommendationCubit + Real-time Data | `features/recommendations/` | 基于现有基金数据，复用缓存机制 |
| Story 1.5 极简对比界面重构 | ComparisonSlider + MetricsProgressBar | `features/comparison/` | 保持现有对比算法，优化UI展示 |
| Story 1.6 折叠式工具面板集成 | ToolPanelContainer + FilterPanel | `features/fund/presentation/widgets/panels/` | 整合现有筛选器和计算器功能 |

## Technology Stack Details

### Core Technologies

**Flutter Framework**
- Flutter SDK: 3.13.0 (Channel stable)
- Dart: 3.1.0
- 目标平台: Windows (主要), Android, Web (实验性)

**状态管理**
- flutter_bloc: 8.1.3
- equatable: 2.0.5
- dartz: 0.10.1 (函数式编程工具)

**数据持久化**
- hive: 2.2.3 (主要本地缓存)
- hive_flutter: 1.1.0
- shared_preferences: 2.2.2
- decimal: 2.3.2 (高精度数值计算)

**网络层**
- dio: 5.3.2 (HTTP客户端，支持gzip压缩)
- retrofit: 4.0.2 (类型安全API客户端)
- web_socket_channel: 2.4.0 (实时数据推送)
- dio_http_cache_lts: 0.3.0 (HTTP缓存)

**UI组件**
- fl_chart: 0.65.0 (图表库)
- google_fonts: 6.1.0 (字体)
- flutter_animate: 4.2.0 (动画效果)
- shimmer: 3.0.0 (加载动画)

### Integration Points

**混合数据获取架构**
```
HybridDataManager → DataType Router → Strategy Selection → Data Stream
        ↓                      ↓                  ↓              ↓
  Data Priority       Data Classification    Polling/WS     Cache Layer
        ↓                      ↓                  ↓              ↓
  Quality Monitor      Network Monitor      Frequency Control  Sync Service
```

**缓存系统架构**
```
L1: Memory Cache (毫秒级访问)
├── 基金搜索索引
├── 实时市场数据
└── UI状态缓存

L2: Hive Local Cache (快速持久化)
├── 基金基本信息
├── 历史数据
└── 用户偏好设置

L3: Remote API (企业级数据)
├── 基金净值数据
├── 市场指数
└── 分析报告
```

**状态管理架构**
```
GlobalCubitManager
├── FundSearchCubit (搜索状态)
├── FundComparisonCubit (对比状态)
├── RecommendationCubit (推荐状态)
├── HybridDataStatusCubit (混合数据状态)
├── RealtimeSettingsCubit (实时性设置状态)
├── RealtimeDataCubit (实时数据状态)
└── UserPreferencesCubit (用户偏好状态)
```

## Novel Pattern Designs

### 1. 智能自适应UI模式 (AdaptiveUI Pattern)

**设计目标**: 基于设备性能自动调整UI复杂度，确保低端设备流畅运行，高端设备获得丰富体验。

**核心实现**:
```dart
class AdaptiveUIController {
  final DevicePerformance _performance;
  final Map<AnimationLevel, WidgetFactory> _factories;

  Widget createFundCard(FundData data) {
    final level = _performance.getOptimalAnimationLevel();
    return _factories[level]?.createCard(data) ??
           _factories[AnimationLevel.basic]!.createCard(data);
  }
}

enum AnimationLevel { disabled, basic, enhanced }
```

**组件层级架构**:
- **基础层**: 纯数据展示，无动画效果
- **交互层**: 自适应动画效果，根据设备性能调整
- **业务层**: 完整微交互，专业级用户体验

### 2. 混合同步模式 (Hybrid Data Sync Pattern)

**设计目标**: 实现金融级数据准确性的同时保证离线能力，支持实时市场数据推送。

**核心实现**:
```dart
class HybridDataSyncManager {
  final WebSocketManager _realtimeChannel;  // 关键数据实时推送
  final HttpPollingService _batchService;   // 批量数据定期同步
  final LocalCacheManager _offlineCache;    // 离线数据缓存

  Future<void> syncFundData() async {
    // 实时数据: 净值、市场指数 (延迟<30秒)
    await _realtimeChannel.subscribe([
      'fund.nav_updates', 'market.index_changes'
    ]);

    // 批量数据: 基金基本信息、历史数据 (每小时同步)
    await _batchService.schedulePeriodicSync(
      interval: Duration(hours: 1),
      fallback: Duration(minutes: 30)
    );
  }
}
```

**数据流策略**:
- **关键数据**: WebSocket实时推送，网络异常时HTTP轮询降级
- **批量数据**: HTTP定期同步，本地缓存优先
- **离线支持**: 完整的离线功能，网络恢复自动同步

### 3. 渐进式工具展示模式 (Progressive Tool Disclosure Pattern)

**设计目标**: 解决专业功能密度与界面简洁性的矛盾，支持从初学者到专家的渐进式工具展示。

**核心实现**:
```dart
class ProgressiveToolPanel {
  final Map<ToolComplexity, List<AdvancedTool>> _tools;

  Widget buildPanel() {
    return ExpandablePanel(
      header: _buildMinimalHeader(),
      collapsed: _buildBasicTools(),        // 筛选器、搜索
      expanded: _buildProgressiveTools(),  // 对比工具、计算器、分析工具
      onExpansionChanged: _trackUsage,
    );
  }
}
```

**工具复杂度分级**:
- **基础工具**: 搜索、筛选器 (所有用户)
- **中级工具**: 对比工具、计算器 (进阶用户)
- **高级工具**: 分析工具、导出功能 (专家用户)

### 4. 金融级数据验证模式 (Financial-grade Validation Pattern)

**设计目标**: 确保金融数据零误差，支持多源数据交叉验证和监管合规。

**核心实现**:
```dart
class FinancialDataValidator {
  final List<DataValidator> _validators;
  final CrossReferenceChecker _crossChecker;

  Future<ValidationResult> validateFundData(FundData data) async {
    // 第一层: 格式验证
    final formatResult = await _validateFormat(data);
    if (!formatResult.isValid) return formatResult;

    // 第二层: 业务逻辑验证
    final businessResult = await _validateBusinessRules(data);
    if (!businessResult.isValid) return businessResult;

    // 第三层: 交叉验证 (多数据源)
    final crossRefResult = await _crossChecker.validate(data);
    if (!crossRefResult.isValid) return crossRefResult;

    // 第四层: 合规性检查
    return await _validateCompliance(data);
  }
}
```

**验证层级**:
- **格式验证**: 数据类型、范围、格式正确性
- **业务验证**: 金融业务规则、逻辑一致性
- **交叉验证**: 多数据源对比、权威性验证
- **合规检查**: 金融监管要求、数据展示规范

### 5. 分层混合数据获取模式 (Hybrid Data Fetching Pattern)

**设计目标**: 实现智能的数据获取策略，根据数据类型、网络状况和用户需求动态选择最优获取方式，支持未来实时数据扩展。

**核心实现**:
```dart
abstract class DataFetchStrategy {
  Stream<DataItem> getDataStream(DataType type);
  bool isAvailable();
  int getPriority();
  Duration getPollingInterval();
}

class HybridDataManager {
  final Map<DataType, List<DataFetchStrategy>> _strategies;
  final NetworkMonitor _networkMonitor;
  final CacheManager _cacheManager;

  Stream<DataItem> getMixedDataStream(DataType type) {
    final availableStrategies = _getAvailableStrategies(type);
    final optimalStrategy = _selectOptimalStrategy(availableStrategies, type);

    return optimalStrategy.getDataStream(type)
        .handleError(_handleDataError)
        .transform(_dataQualityFilter);
  }

  DataFetchStrategy _selectOptimalStrategy(
    List<DataFetchStrategy> strategies,
    DataType type
  ) {
    // 智能策略选择算法
    if (_networkMonitor.isRealtimeAvailable && type.isHighPriority) {
      return strategies.firstWhere((s) => s is WebSocketStrategy);
    }
    return strategies.firstWhere((s) => s is HttpPollingStrategy);
  }
}
```

**数据分层策略**:
```dart
enum DataType {
  // 高优先级实时数据 (未来WebSocket)
  marketIndex(priority: 1, interval: Duration(seconds: 30)),
  etfPrice(priority: 1, interval: Duration(seconds: 30)),

  // 中等优先级准实时数据 (当前HTTP轮询)
  fundNav(priority: 2, interval: Duration(minutes: 15)),
  fundInfo(priority: 2, interval: Duration(hours: 1)),

  // 低优先级按需数据 (HTTP按需请求)
  historicalData(priority: 3, interval: null),
  portfolioDetails(priority: 3, interval: null);
}
```

**智能特性**:
- **自适应频率调整**: 基于数据变化活跃度和用户行为
- **网络异常降级**: 自动切换到缓存优先模式
- **断线恢复同步**: 智能同步断线期间的数据差异
- **数据质量监控**: 实时监控数据延迟、完整性和准确性

## Implementation Patterns

### 命名约定

**文件命名**: `snake_case.dart`
```
fund_exploration_page.dart          # 页面文件
adaptive_fund_card.dart             # 组件文件
fund_search_cubit.dart              # 状态管理文件
search_funds_usecase.dart           # 用例文件
performance_detector.dart          # 工具类文件
```

**类命名**: `PascalCase`
```
class FundExplorationPage extends StatelessWidget { }
class AdaptiveFundCard extends StatefulWidget { }
class FundSearchCubit extends Cubit<FundSearchState> { }
class SearchFundsUseCase { }
class PerformanceDetector { }
```

**变量命名**: `camelCase` (私有变量使用 `_` 前缀)
```
final _isLoading = false;
final _hasError = true;
final List<Fund> _funds = [];
Fund? _selectedFund;
static const String API_BASE_URL = 'http://154.44.25.92:8080';
```

### 代码组织

**目录结构标准**:
```
features/feature_name/
├── data/                    # 数据层 (外部数据源、模型、仓库实现)
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/                  # 领域层 (实体、仓库接口、用例)
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/            # 表现层 (页面、组件、状态管理)
    ├── pages/
    ├── widgets/
    └── cubits/
```

**导入顺序标准**:
1. Dart内置库
2. Flutter框架库
3. 第三方包
4. 项目内部库 (按层级排序)

### 错误处理

**全局错误边界**:
```dart
class AppErrorBoundary extends StatelessWidget {
  Widget build(BuildContext context) {
    return BlocListener<GlobalErrorCubit, GlobalErrorState>(
      listener: (context, state) {
        if (state is GlobalErrorOccurred) {
          _handleError(context, state.error);
        }
      },
      child: widget.child,
    );
  }
}
```

**错误响应格式**:
```dart
class AppError {
  final String code;          // 标准化错误代码
  final String message;       // 用户友好消息
  final String? technicalInfo; // 技术详情
  final ErrorSeverity severity; // 严重程度
  final DateTime timestamp;   // 错误时间
}
```

**错误恢复策略**:
- **网络错误**: 指数退避重试，智能降级到离线模式
- **数据错误**: 数据验证失败，使用缓存数据
- **UI错误**: 降级显示，错误边界捕获异常

### 日志策略

**结构化日志格式**:
```dart
class AppLog {
  final LogLevel level;
  final String category;     // 'NETWORK', 'DATA', 'UI', 'BUSINESS'
  final String action;       // 具体操作
  final String details;      // 详细信息
  final Map<String, dynamic>? metadata; // 结构化数据
  final DateTime timestamp;
}
```

**日志级别**:
- **DEBUG**: 开发调试信息
- **INFO**: 重要业务操作
- **WARN**: 性能警告、降级操作
- **ERROR**: 错误和异常
- **CRITICAL**: 系统级故障

## Data Architecture

### 数据模型

**基金数据模型**:
```dart
@JsonSerializable()
class FundInfo {
  final String code;              // 基金代码 (6位数字)
  final String name;              // 基金名称
  final double nav;               // 净值 (精确到小数点后4位)
  final double yieldRate;         // 收益率 (百分比)
  final String fundType;          // 基金类型
  final DateTime lastUpdate;      // 最后更新时间

  const FundInfo({
    required this.code,
    required this.name,
    required this.nav,
    required this.yieldRate,
    required this.fundType,
    required this.lastUpdate,
  });
}
```

**市场数据模型**:
```dart
@JsonSerializable()
class MarketData {
  final String indexCode;         // 指数代码
  final double indexValue;        // 指数值
  final double changePercent;     // 涨跌幅
  final DateTime timestamp;       // 数据时间

  const MarketData({
    required this.indexCode,
    required this.indexValue,
    required this.changePercent,
    required this.timestamp,
  });
}
```

### 数据关系

```
FundInfo (基金信息)
├── BasicInfo (基本信息)
│   ├── code: String
│   ├── name: String
│   └── fundType: String
├── Performance (性能数据)
│   ├── nav: double
│   ├── yieldRate: double
│   └── riskLevel: int
└── Metadata (元数据)
    ├── lastUpdate: DateTime
    ├── dataSource: String
    └── validated: bool

MarketData (市场数据)
├── IndexData (指数数据)
│   ├── indexCode: String
│   ├── indexValue: double
│   └── changePercent: double
└── Timestamp (时间戳)
    ├── timestamp: DateTime
    └── source: String
```

## API Contracts

### 基金API端点

**主要API端点**: `http://154.44.25.92:8080/`

**核心API**:
```dart
abstract class FundApiService {
  @GET('/funds/search')
  Future<ApiResponse<List<FundInfo>>> searchFunds(
    @Query('q') String query,
    @Query('type') String? fundType,
    @Query('limit') int limit = 20,
  );

  @GET('/funds/{code}')
  Future<ApiResponse<FundInfo>> getFundDetails(
    @Path('code') String code,
  );

  @GET('/funds/compare')
  Future<ApiResponse<Map<String, dynamic>>> compareFunds(
    @Query('codes') List<String> codes,
  );

  @GET('/recommendations')
  Future<ApiResponse<List<Recommendation>>> getRecommendations(
    @Query('riskLevel') int? riskLevel,
    @Query('fundType') String? fundType,
  );
}
```

**实时数据API**:
```dart
abstract class RealtimeApiService {
  @GET('/market/realtime')
  Stream<MarketData> getMarketData();

  @GET('/funds/{code}/realtime')
  Stream<FundInfo> getFundRealtimeData(@Path('code') String code);
}
```

**统一响应格式**:
```dart
class ApiResponse<T> {
  final bool success;
  final T? data;
  final ApiError? error;
  final String? code;
  final Map<String, dynamic>? metadata;

  const ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.code,
    this.metadata,
  });
}
```

## Security Architecture

### 数据安全

**数据加密**:
- **传输加密**: TLS 1.3协议加密所有网络通信
- **存储加密**: Hive数据库使用AES-256加密敏感数据
- **内存安全**: 敏感数据处理后立即清理内存

**数据验证**:
```dart
class DataValidationUtils {
  static bool isValidFundCode(String code) {
    return RegExp(r'^[0-9]{6}$').hasMatch(code);
  }

  static bool isValidYieldRate(double rate) {
    return rate >= -100 && rate <= 1000; // 合理收益率范围
  }

  static bool isValidDate(DateTime date) {
    final now = DateTime.now();
    return date.isBefore(now) && date.isAfter(now.subtract(Duration(days: 365 * 10)));
  }
}
```

### 访问控制

**功能权限控制**:
```dart
enum FeaturePermission {
  fundSearch,      // 基金搜索
  fundAnalysis,    // 基金分析
  dataExport,      // 数据导出
  advancedTools,   // 高级工具
  settingsModify   // 设置修改
}

class PermissionManager {
  bool hasPermission(FeaturePermission permission) {
    // 基于用户级别和应用状态检查权限
    return _userPermissions.contains(permission);
  }
}
```

**审计日志**:
```dart
class AuditLogger {
  static void logUserAction(String action, Map<String, dynamic>? context) {
    final auditEntry = AuditEntry(
      action: action,
      context: context,
      timestamp: DateTime.now(),
      userId: _currentUserId,
    );
    _auditLogger.log(auditEntry.toJson());
  }
}
```

## Performance Considerations

### 性能优化策略

**启动优化**:
- **延迟加载**: 按需加载非核心模块
- **预编译缓存**: 启动时缓存常用数据
- **异步初始化**: 非关键组件异步加载
- **目标**: 启动时间 < 3秒

**运行时性能**:
```dart
class PerformanceOptimizer {
  // 智能缓存策略
  Future<T?> getCachedData<T>(String key) async {
    // L1: 内存缓存 (毫秒级)
    final memoryData = _memoryCache.get<T>(key);
    if (memoryData != null) return memoryData;

    // L2: Hive缓存 (快速)
    final hiveData = await _hiveCache.get<T>(key);
    if (hiveData != null) {
      _memoryCache.set(key, hiveData);
      return hiveData;
    }

    // L3: 网络请求 (慢速)
    final networkData = await _fetchFromNetwork<T>(key);
    if (networkData != null) {
      _memoryCache.set(key, networkData);
      await _hiveCache.set(key, networkData);
    }

    return networkData;
  }
}
```

**内存管理**:
- **弱引用**: 大对象使用WeakReference
- **自动清理**: 定期清理过期缓存
- **内存监控**: 实时监控内存使用情况
- **目标**: 正常使用 < 500MB

**动画性能**:
```dart
class AdaptiveAnimationController {
  AnimationLevel getOptimalLevel() {
    final deviceScore = _performanceDetector.getScore();

    if (deviceScore < 30) return AnimationLevel.disabled;
    if (deviceScore < 70) return AnimationLevel.basic;
    return AnimationLevel.enhanced;
  }
}
```

### 性能监控

**关键指标监控**:
- 应用启动时间
- API响应时间
- 内存使用情况
- CPU使用率
- 动画帧率

```dart
class PerformanceMonitor {
  void startMonitoring() {
    // 启动时间监控
    _monitorStartupTime();

    // API性能监控
    _monitorAPICalls();

    // 内存使用监控
    _monitorMemoryUsage();

    // 动画性能监控
    _monitorAnimationPerformance();
  }
}
```

## Deployment Architecture

### Windows桌面应用部署

**构建配置**:
```yaml
# pubspec.yaml
flutter:
  assets:
    - assets/images/
    - assets/data/

  fonts:
    - family: Roboto
      fonts:
        - asset: fonts/Roboto-Regular.ttf
        - asset: fonts/Roboto-Bold.ttf
```

**发布构建**:
```bash
# Windows发布版本构建
flutter build windows --release

# 性能优化构建
flutter build windows --release --tree-shake-icons
```

**应用签名**:
- Windows代码签名证书
- 自动化更新机制
- 错误报告收集

### 跨平台支持

**Android构建**:
```bash
flutter build apk --release
flutter build appbundle --release
```

**Web构建**:
```bash
flutter build web --release --web-renderer canvaskit
```

**部署策略**:
- **Windows**: 主要平台，完整功能支持
- **Android**: 移动端辅助功能
- **Web**: 实验性支持，基础功能

## Development Environment

### Prerequisites

**开发环境要求**:
- Flutter SDK: 3.13.0 (Channel stable)
- Dart: 3.1.0
- Visual Studio 2022 (Windows开发)
- Git 2.40+
- Windows 10/11 (主要开发平台)

**推荐工具**:
- VS Code + Flutter插件
- Android Studio (模拟器管理)
- Windows Terminal
- Postman (API测试)

### Setup Commands

```bash
# 1. 克隆项目
git clone https://github.com/your-org/baostock.git
cd baostock

# 2. 安装依赖
flutter pub get

# 3. 运行代码生成
dart run build_runner build --delete-conflicting-outputs

# 4. 检查环境
flutter doctor

# 5. 运行开发服务器
flutter run -d windows

# 6. 运行测试
flutter test

# 7. 代码分析
flutter analyze

# 8. 代码格式化
dart format .
```

**开发工作流**:
```bash
# 功能开发流程
git checkout -b feature/story-name
# ... 开发功能 ...
flutter test                          # 运行测试
flutter analyze                      # 静态分析
dart run build_runner build          # 代码生成
flutter test --coverage              # 覆盖率测试
git add .
git commit -m "feat: 实现xxx功能"
git push origin feature/story-name
# 创建Pull Request
```

## Architecture Decision Records (ADRs)

### ADR-001: 混合数据获取架构选择

**决策**: 采用分层的混合数据获取策略 (HTTP轮询 + 预留WebSocket扩展)

**背景**: 基金数据需要准实时性保证，同时需要支持未来实时性升级和可扩展架构

**考虑方案**:
1. 纯WebSocket: 实时性好，但连接不稳定，架构复杂度高
2. 纯HTTP轮询: 稳定性好，但实时性有限
3. 分层混合策略: 平衡实时性、稳定性和未来扩展性

**决策理由**:
- **阶段化实施**: 当前基于HTTP轮询的准实时数据，未来扩展关键数据的WebSocket实时推送
- **智能分层**: 根据数据类型和优先级选择最优获取策略
- **向前兼容**: 预留WebSocket扩展接口，确保架构的平滑升级
- **网络适应性**: 网络异常时自动降级到缓存优先模式
- **确保金融级数据准确性**: 分层数据验证和同步机制

**数据分层策略**:
- **高优先级实时数据** (未来WebSocket): 市场指数、ETF价格、宏观经济指标
- **中等优先级准实时数据** (当前HTTP轮询): 基金净值(15分钟更新)、基础信息
- **低优先级按需数据** (HTTP按需请求): 历史业绩、持仓详情

**核心架构组件**:
- `HybridDataManager`: 混合数据管理器，统一数据获取接口
- `DataFetchStrategy`: 数据获取策略接口，支持多种获取方式
- `PollingManager`: HTTP轮询管理器，智能频率调整
- `HybridDataStatusCubit`: 混合数据状态管理

**影响**:
- 需要实现智能数据路由和优先级管理
- 需要设计分层数据缓存和同步机制
- 增加了系统复杂度，但提供了强大的扩展能力
- 为未来实时数据需求奠定了架构基础

### ADR-002: 智能自适应UI架构

**决策**: 实现基于设备性能的三级自适应UI系统

**背景**: 需要在低端设备上保证流畅运行，在高端设备上提供丰富体验

**技术方案**:
```dart
enum AnimationLevel { disabled, basic, enhanced }

class AdaptiveUIController {
  AnimationLevel getOptimalLevel() {
    final deviceScore = _performanceDetector.getScore();
    if (deviceScore < 30) return AnimationLevel.disabled;
    if (deviceScore < 70) return AnimationLevel.basic;
    return AnimationLevel.enhanced;
  }
}
```

**决策理由**:
- 性能检测在应用启动时自动进行
- 运行时根据系统负载动态调整
- 用户可以手动设置偏好级别
- 确保核心功能在所有设备上可用

**影响**:
- UI组件需要支持三种渲染模式
- 需要实现性能监控和动态调整机制
- 增加了开发和测试复杂度

### ADR-003: 分层组件架构

**决策**: 采用三层组件架构(基础层+交互层+业务层)

**背景**: 需要平衡代码复用性、性能和用户体验

**架构设计**:
```dart
// 基础层: 纯数据展示
class BaseFundCard extends StatelessWidget { }

// 交互层: 自适应动画和手势
class AdaptiveFundCard extends StatefulWidget { }
class MicrointeractiveFundCard extends StatefulWidget { }

// 业务层: 特定业务逻辑
class RecommendationCard extends StatelessWidget { }
class ComparisonCard extends StatelessWidget { }
```

**决策理由**:
- 基础组件确保功能一致性
- 交互组件提供差异化体验
- 业务组件封装特定逻辑
- 支持渐进式功能增强

### ADR-004: 金融级数据验证策略

**决策**: 实现四层数据验证架构

**背景**: 金融数据要求零误差，需要多层数据验证和交叉校验

**验证层级**:
1. **格式验证**: 数据类型、范围、格式
2. **业务验证**: 金融业务规则、逻辑一致性
3. **交叉验证**: 多数据源对比、权威性验证
4. **合规检查**: 金融监管要求、数据展示规范

**决策理由**:
- 确保数据准确性100%
- 支持多数据源交叉验证
- 符合金融监管要求
- 建立用户信任

### ADR-005: 渐进式工具展示模式

**决策**: 实现基于用户熟练度的渐进式工具展示

**背景**: 需要平衡专业功能密度与界面简洁性

**实现策略**:
- **基础工具**: 搜索、筛选器(所有用户)
- **中级工具**: 对比工具、计算器(进阶用户)
- **高级工具**: 分析工具、导出功能(专家用户)

**决策理由**:
- 降低新用户学习门槛
- 支持用户成长路径
- 保持界面简洁性
- 满足专业用户需求

---

**架构文档版本**: v1.0.0
**生成日期**: 2025年11月7日
**创建者**: BMAD Decision Architecture Workflow
**目标用户**: AI代理开发团队
**适用项目**: 基速基金量化分析平台 (Epic 1重构)

**重要提醒**: 所有AI代理必须严格遵循此架构文档，确保代码一致性和系统可靠性。任何偏离此架构的决策都需要充分理由和团队评审。