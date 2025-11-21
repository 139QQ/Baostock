# 基金卡片组件库

这是一个统一的基金卡片组件库，提供了多种类型的基金卡片组件，支持自适应性能优化和丰富的交互体验。

## 组件架构

### 分层设计

```
┌─────────────────────────────────────┐
│           Business Layer           │  (业务层)
│     RecommendationCard            │  特定业务逻辑的组件
│     ComparisonCard                │
└─────────────────────────────────────┘
                ↕
┌─────────────────────────────────────┐
│         Interactive Layer          │  (交互层)
│    AdaptiveFundCard               │  自适应性能的智能卡片
│  MicrointeractiveFundCard          │  微交互增强卡片
└─────────────────────────────────────┘
                ↕
┌─────────────────────────────────────┐
│           Base Layer               │  (基础层)
│        BaseFundCard               │  抽象基类，定义通用接口
│        FundCardUtils              │  通用工具类
└─────────────────────────────────────┘
```

## 核心组件

### 1. AdaptiveFundCard (自适应基金卡片)

智能自适应基金卡片，根据设备性能自动调整动画效果。

**特性：**
- 🎯 设备性能自动检测 (0-100分评分系统)
- 🚀 3级动画自适应 (禁用/基础/完整)
- 🔄 智能错误处理和降级机制
- ♿ 完整的无障碍性支持
- 📊 性能监控和警告系统

**适用场景：**
- 需要在不同性能设备上提供一致体验的场景
- 对性能要求较高的列表展示
- 需要自动降级的企业级应用

```dart
AdaptiveFundCard(
  fund: fund,
  performanceLevel: PerformanceLevel.medium, // 可选，会自动检测
  enablePerformanceMonitoring: true,
  onTap: () => Navigator.push(...),
  onAddToWatchlist: () => addToWatchlist(fund),
)
```

### 2. MicrointeractiveFundCard (微交互基金卡片)

提供丰富微交互和手势操作的高级卡片。

**特性：**
- 📱 丰富的手势操作 (左滑收藏/右滑对比)
- 🤚 智能手势冲突检测
- 📳 触觉反馈系统集成
- ⚡ 性能监控和警告系统
- ✨ 视觉反馈效果

**适用场景：**
- 移动端应用，注重用户体验
- 需要手势操作的交互密集型应用
- 对用户体验要求极高的场景

```dart
MicrointeractiveFundCard(
  fund: fund,
  enableSwipeGestures: true,
  enableHapticFeedback: true,
  onSwipeLeft: () => addToFavorites(fund),
  onSwipeRight: () => addToComparison(fund),
)
```

### 3. BaseFundCard (基金卡片基类)

所有基金卡片组件的抽象基类，定义了通用的接口和属性。

**特性：**
- 🏛️ 统一的组件接口
- 🔧 通用的配置系统
- 📝 标准化的回调函数
- 🎨 一致的设计语言

### 4. FundCardFactory (卡片工厂)

统一的卡片创建工厂，提供智能组件选择和性能优化。

**特性：**
- 🏭 智能组件选择算法
- 🎛️ 性能自适应配置
- 📦 组件缓存和复用
- ⚡ 批量创建优化

**使用方法：**

```dart
// 智能创建（推荐）
Widget card = FundCardFactory.createSmartFundCard(
  fund: fund,
  onTap: () => showFundDetails(fund),
);

// 手动指定类型
Widget card = FundCardFactory.createFundCard(
  fund: fund,
  cardType: FundCardType.adaptive,
  config: FundCardConfig.enhanced,
);

// 批量创建
List<Widget> cards = FundCardFactory.createFundCardList(
  funds: fundList,
  cardType: FundCardType.microinteractive,
);
```

## 性能优化

### 设备性能分级

系统会自动检测设备性能并分为三级：

- **高性能设备** (80-100分): 使用 MicrointeractiveFundCard，完整动画效果
- **中等性能设备** (40-79分): 使用 AdaptiveFundCard，基础动画效果
- **低性能设备** (0-39分): 使用 AdaptiveFundCard，禁用动画

### 动画级别配置

```dart
enum AnimationLevel {
  disabled, // 禁用所有动画，最佳性能
  basic,    // 基础动画，平衡性能和体验
  enhanced, // 完整动画，最佳用户体验
}
```

### 性能监控

所有组件都内置了性能监控功能：

- 帧率监控 (60fps目标)
- 渲染时间统计
- 内存使用监控
- 自动降级机制

## 使用指南

### 1. 快速开始

```dart
import 'package:your_app/src/features/fund/presentation/widgets/cards/fund_cards.dart';

// 在列表中使用智能卡片
ListView.builder(
  itemCount: funds.length,
  itemBuilder: (context, index) {
    return FundCardFactory.createSmartFundCard(
      fund: funds[index],
      onTap: () => showFundDetails(funds[index]),
    );
  },
);
```

### 2. 自定义配置

```dart
final customConfig = FundCardConfig(
  animationLevel: 2,
  enableHoverEffects: true,
  enableGestureFeedback: true,
  animationDuration: Duration(milliseconds: 400),
);

FundCardFactory.createFundCard(
  fund: fund,
  cardType: FundCardType.adaptive,
  config: customConfig,
);
```

### 3. 性能优化

```dart
// 预热缓存
await FundCardFactory.warmupCache(
  popularFunds: hotFunds,
  preferredType: FundCardType.adaptive,
);

// 监控缓存使用
final stats = FundCardFactory.getCacheStats();
print('缓存统计: $stats');

// 清理缓存
FundCardFactory.clearCache();
```

## 最佳实践

### 1. 性能优化建议

- 在长列表中使用 `createSmartFundCard` 让系统自动选择
- 启用组件缓存以提升滚动性能
- 定期调用 `optimizeCache()` 清理未使用的缓存

### 2. 用户体验建议

- 为触摸操作启用触觉反馈
- 实现有意义的无障碍标签
- 使用适当的动画时长（200-400ms）

### 3. 维护建议

- 优先使用工厂方法创建卡片
- 避免直接实例化具体卡片类型
- 定期更新性能检测算法

## 迁移指南

如果你在使用旧的卡片组件，这里是如何迁移到新组件库：

### 旧的写法

```dart
// 不推荐：直接使用具体组件
FundRankingCard(
  fund: fund,
  onTap: () => showDetails(fund),
)

EnhancedFundRankingCard(
  fund: fund,
  enableGlassmorphism: true,
  onTap: () => showDetails(fund),
)
```

### 新的写法

```dart
// 推荐：使用工厂方法
FundCardFactory.createSmartFundCard(
  fund: fund,
  onTap: () => showDetails(fund),
)

// 或者指定具体类型
FundCardFactory.createFundCard(
  fund: fund,
  cardType: FundCardType.adaptive,
  onTap: () => showDetails(fund),
)
```

## 故障排除

### 常见问题

1. **动画卡顿**
   - 检查设备性能检测是否正常
   - 尝试降低动画级别
   - 启用性能监控查看瓶颈

2. **手势冲突**
   - 检查手势识别器优先级设置
   - 使用 `gestureConflictResolution` 参数
   - 确保父组件没有干扰手势

3. **内存占用高**
   - 定期清理缓存：`FundCardFactory.optimizeCache()`
   - 检查是否有内存泄漏
   - 限制缓存大小

### 调试工具

```dart
// 启用调试模式
MicrointeractiveFundCard(
  fund: fund,
  enablePerformanceMonitoring: true,
  debugMode: true, // 显示性能信息
)

// 查看缓存状态
print(FundCardFactory.getCacheStats());
```

## 版本历史

- **v1.0.0** (2025-11-20): 初始版本
  - 实现 AdaptiveFundCard 和 MicrointeractiveFundCard
  - 添加 FundCardFactory 和性能优化
  - 完整的文档和示例

## 贡献指南

欢迎提交问题和改进建议！

### 开发规范

1. 遵循现有的代码风格和命名约定
2. 为新功能添加完整的文档注释
3. 编写单元测试覆盖新功能
4. 确保向后兼容性

### 测试要求

```bash
# 运行组件测试
flutter test test/unit/fund/widgets/cards/

# 运行性能测试
flutter test test/performance/fund_cards_benchmark.dart

# 运行无障碍测试
flutter test test/accessibility/fund_cards_test.dart
```