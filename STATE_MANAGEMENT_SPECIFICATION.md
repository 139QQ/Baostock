# 📋 状态管理规范文档

## 🎯 项目概述

**项目名称**: Baostock基金分析器
**状态管理框架**: Flutter Bloc
**版本**: 2.0
**创建日期**: 2025年10月17日
**目标**: 统一状态管理范式，建立清晰的数据流架构

---

## 🏗️ 状态管理架构

### 统一状态管理范式

**选择**: **Bloc模式** 作为项目的统一状态管理方式

**理由**:
- ✅ 更强大的事件驱动架构
- ✅ 更好的状态可预测性
- ✅ 更丰富的调试支持
- ✅ 更复杂的状态管理能力
- ✅ 更好的测试支持
- ✅ 更清晰的代码组织

---

## 📊 状态管理分层架构

### 1. 应用层状态管理 (Application Layer)

#### AppBloc
- **职责**: 应用级状态管理
- **状态**: AppLoading, AppLoaded, AppError
- **事件**: AppStarted, AppRefreshed, AppErrorOccurred
- **功能**:
  - 应用启动状态管理
  - 全局错误处理
  - 主题切换
  - 语言设置

### 2. 功能层状态管理 (Feature Layer)

#### AuthBloc ✅
- **位置**: `lib/src/features/auth/presentation/bloc/auth_bloc.dart`
- **状态**: 已实现完整功能
- **职责**: 用户认证状态管理
- **功能**: 登录、注册、令牌管理、用户信息

#### FundBloc
- **位置**: `lib/src/features/fund/presentation/bloc/fund_bloc.dart`
- **职责**: 基金基础操作状态管理
- **功能**:
  - 基金基本信息加载
  - 基金搜索基础功能
  - 基金收藏状态管理
  - 基金详情缓存

#### FundRankingBloc ✅ (主要排行榜状态管理)
- **位置**: `lib/src/features/fund/presentation/bloc/fund_ranking_bloc.dart`
- **状态**: 600+行，功能完整
- **职责**: 基金排行榜综合状态管理
- **功能**:
  - 排行榜数据加载和刷新
  - 多维度筛选（基金类型、收益率范围）
  - 多种排序方式
  - 分页加载
  - 收藏功能
  - 搜索功能
  - 定时刷新
  - 统计信息加载
  - 历史数据支持

#### FilterBloc
- **位置**: `lib/src/features/fund/presentation/bloc/filter_bloc.dart`
- **职责**: 筛选条件状态管理
- **功能**:
  - 筛选条件持久化
  - 筛选状态同步
  - 预设筛选方案

#### SearchBloc
- **位置**: `lib/src/features/fund/presentation/bloc/search_bloc.dart`
- **职责**: 搜索状态管理
- **功能**:
  - 搜索历史管理
  - 搜索建议
  - 搜索结果缓存

### 3. 共享层状态管理 (Shared Layer)

#### CacheBloc
- **职责**: 统一缓存管理
- **功能**:
  - 缓存策略统一管理
  - 缓存过期处理
  - 缓存清理
  - 缓存统计

#### NetworkBloc
- **职责**: 网络状态管理
- **功能**:
  - 网络连接状态监控
  - 网络错误处理
  - 离线模式支持

---

## 🔄 数据流规范

### 数据流向
```
UI Components → Events → BLoCs → Use Cases → Repositories → Data Sources
     ↑                                                    ↓
States ← BLoCs ← Use Cases ← Repositories ← Data Sources
```

### 状态更新流程
1. **UI事件触发**: 用户操作触发UI事件
2. **事件分发**: UI组件将事件发送给对应的Bloc
3. **状态处理**: Bloc处理事件，调用Use Cases
4. **数据获取**: Use Cases通过Repository获取数据
5. **状态更新**: Bloc更新状态并通知UI
6. **UI重建**: UI组件监听状态变化并重建

### 状态同步策略
- **单向数据流**: 严格遵循单向数据流原则
- **事件驱动**: 所有状态变更通过事件触发
- **状态不可变**: 状态对象不可变，通过新状态替换

---

## 🗂️ 组件重构规范

### FundExploration重构
**当前状态**: 1079行的Cubit实现
**重构目标**: 简化为纯UI状态管理，委托数据操作给专业Bloc

#### 重构后职责
- **UI状态管理**: 页面显示状态、加载状态、错误状态
- **导航状态**: 页面切换、标签页状态
- **临时状态**: 表单输入、滚动位置
- **数据委托**: 所有数据操作委托给FundRankingBloc

#### 数据交互
```dart
// FundExplorationCubit 简化后的职责
class FundExplorationCubit extends Cubit<FundExplorationState> {
  final FundRankingBloc _fundRankingBloc;

  // 委托数据操作
  void loadRankingData() => _fundRankingBloc.add(LoadFundRanking());

  // 管理UI状态
  void setSelectedTab(int index) => emit(state.copyWith(selectedTab: index));
}
```

---

## 📦 数据模型统一

### 统一模型策略
**选择**: **FundRanking模型** 作为统一的基金数据模型

#### 理由
- ✅ 功能更完整，包含排行榜特有字段
- ✅ 与FundRankingBloc完美集成
- ✅ 支持更多业务场景
- ✅ 数据结构更稳定

#### 模型映射
```dart
// Fund模型到FundRanking的转换
extension FundToRankingExtension on Fund {
  FundRanking toFundRanking() {
    return FundRanking(
      fundCode: this.code,
      fundName: this.name,
      fundType: this.type,
      // ... 其他字段映射
      rank: 0, // 排行榜特有字段
      rankChange: 0,
    );
  }
}
```

---

## 🔧 依赖注入规范

### 服务定位器模式
```dart
// 统一的服务容器
class ServiceLocator {
  static final Map<Type, dynamic> _services = {};

  static T<T>() {
    return _services[T] ?? (throw Exception('Service $T not registered'));
  }

  static void register<T>(T service) {
    _services[T] = service;
  }
}
```

### Bloc提供者规范
```dart
// 多Bloc提供者
class MultiBlocProviderWrapper extends StatelessWidget {
  final Widget child;

  const MultiBlocProviderWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ServiceLocator<AuthBloc>()),
        BlocProvider(create: (_) => ServiceLocator<FundRankingBloc>()),
        BlocProvider(create: (_) => ServiceLocator<FundExplorationCubit>()),
        // ... 其他Bloc
      ],
      child: child,
    );
  }
}
```

---

## 🧪 测试规范

### Bloc测试
```dart
// Bloc测试模板
void main() {
  group('FundRankingBloc', () {
    late FundRankingBloc fundRankingBloc;
    late MockFundRepository mockRepository;

    setUp(() {
      mockRepository = MockFundRepository();
      fundRankingBloc = FundRankingBloc(repository: mockRepository);
    });

    tearDown(() {
      fundRankingBloc.close();
    });

    blocTest<FundRankingBloc, FundRankingState>(
      'emits [FundRankingLoading, FundRankingLoaded] when LoadFundRanking is added',
      build: () {
        when(mockRepository.getFundRanking())
            .thenAnswer((_) async => Right(mockRankingData));
        return fundRankingBloc;
      },
      act: (bloc) => bloc.add(LoadFundRanking()),
      expect: () => [
        FundRankingLoading(),
        FundRankingLoaded(funds: mockRankingData),
      ],
    );
  });
}
```

---

## 📊 错误处理规范

### 错误状态统一
```dart
abstract class Failure {
  const Failure(this.message);
  final String message;
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}
```

### 错误处理策略
1. **网络错误**: 显示重试按钮，提供离线提示
2. **服务器错误**: 显示错误信息，提供反馈渠道
3. **缓存错误**: 静默处理，记录日志
4. **未知错误**: 显示通用错误信息，提供客服支持

---

## 🎯 性能优化规范

### 状态优化
- **状态去重**: 避免重复状态更新
- **状态缓存**: 合理缓存状态数据
- **异步处理**: 所有异步操作正确处理

### 内存管理
- **及时释放**: Bloc和Controller及时dispose
- **内存监控**: 集成内存监控工具
- **泄漏检测**: 定期进行内存泄漏检测

---

## 📋 迁移检查清单

### 阶段1: 清理重复实现 ✅
- [x] 删除FundRankingCubit
- [x] 删除重复的fund_card组件
- [x] 清理无用导入和依赖

### 阶段2: 重构FundExplorationCubit (进行中)
- [ ] 简化FundExplorationCubit为纯UI状态管理
- [ ] 建立与FundRankingBloc的委托关系
- [ ] 更新相关UI组件

### 阶段3: 统一数据模型
- [ ] 统一使用FundRanking模型
- [ ] 创建模型转换工具
- [ ] 更新所有相关组件

### 阶段4: 优化依赖注入
- [ ] 实现统一的服务容器
- [ ] 简化Bloc提供者
- [ ] 优化依赖关系

### 阶段5: 测试和验证
- [ ] 编写完整的Bloc测试
- [ ] 进行集成测试
- [ ] 性能回归测试

---

## 📈 成功标准

### 功能标准
- ✅ 所有现有功能保持不变
- ✅ 状态管理更加清晰和可预测
- ✅ 错误处理更加健壮

### 质量标准
- ✅ 代码重复率降低40%以上
- ✅ 状态管理代码可维护性提升50%
- ✅ 测试覆盖率达到70%以上

### 性能标准
- ✅ 内存使用减少30%
- ✅ UI响应速度提升40%
- ✅ 状态更新延迟减少60%

---

**文档版本**: 1.0
**最后更新**: 2025年10月17日
**负责人**: Claude AI Assistant
**审核状态**: 待审核

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>