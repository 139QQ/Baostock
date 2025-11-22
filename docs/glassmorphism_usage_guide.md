# 毛玻璃效果使用指南

## 概述

本文档介绍如何在基金分析平台中使用毛玻璃效果来增强UI视觉体验。

## 基础用法

### 1. 启用毛玻璃效果的基金卡片

```dart
FundRankingCard(
  ranking: fundData,
  position: 1,
  enableGlassmorphism: true, // 启用毛玻璃效果
)
```

### 2. 使用自定义毛玻璃配置

```dart
FundRankingCard(
  ranking: fundData,
  position: 1,
  enableGlassmorphism: true,
  glassmorphismConfig: GlassmorphismConfig(
    blur: 15.0,
    opacity: 0.15,
    borderRadius: 16.0,
    borderColor: Colors.white,
    backgroundColor: Colors.white,
  ),
)
```

## 预设配置

### 轻量效果
```dart
GlassmorphismPresets.light(
  child: yourContent,
)
```

### 中等效果
```dart
GlassmorphismPresets.medium(
  child: yourContent,
)
```

### 强烈效果
```dart
GlassmorphismPresets.strong(
  child: yourContent,
)
```

### 深色主题效果
```dart
GlassmorphismPresets.dark(
  child: yourContent,
)
```

## 性能优化

### 使用增强版基金卡片

```dart
EnhancedFundRankingCard(
  ranking: fundData,
  position: 1,
  enablePerformanceMonitoring: true,
  enableAutoDowngrade: true,
)
```

### 工厂方法

```dart
// 性能优先
GlassmorphismFundCardFactory.createPerformanceFocused(
  ranking: fundData,
  position: 1,
)

// 视觉效果优先
GlassmorphismFundCardFactory.createVisualFocused(
  ranking: fundData,
  position: 1,
)

// 调试模式
GlassmorphismFundCardFactory.createDebug(
  ranking: fundData,
  position: 1,
)
```

## 主题集成

### 在应用主题中配置毛玻璃

```dart
MaterialApp(
  theme: AppTheme.createGlassmorphismTheme(
    brightness: Brightness.light,
    glassmorphismTheme: GlassmorphismThemeData.light,
  ),
  darkTheme: AppTheme.createGlassmorphismTheme(
    brightness: Brightness.dark,
    glassmorphismTheme: GlassmorphismThemeData.dark,
  ),
  themeMode: ThemeMode.system,
  home: MyHomePage(),
)
```

### 使用主题管理器

```dart
final themeManager = GlassmorphismThemeManager();

// 设置毛玻璃配置
themeManager.setGlassmorphismConfig(GlassmorphismConfig.strong);

// 设置主题模式
themeManager.setThemeMode(ThemeMode.dark);

// 启用自适应配置
themeManager.setAdaptiveConfig(true);

// 设置用户强度偏好
themeManager.setUserIntensityPreference(1.5);
```

## 响应式设计

### 根据屏幕尺寸自动调整

```dart
GlassmorphismCard.responsive(
  context: context,
  child: yourContent,
)
```

### 根据设备性能自动调整

```dart
final performanceLevel = PerformanceUtils.calculatePerformanceLevel(metrics);
final config = ResponsiveGlassmorphismConfig.forDevicePerformance(performanceLevel);

GlassmorphismCard(
  child: yourContent,
  blur: config.blur,
  opacity: config.opacity,
  // ... 其他参数
)
```

## 性能监控

### 启用调试模式

```dart
PerformanceMonitor(
  debugMode: true,
  thresholds: PerformanceThresholds.performance,
  onPerformanceUpdate: (metrics) {
    print('FPS: ${metrics.frameRate}');
    print('渲染时间: ${metrics.renderTime}μs');
  },
  child: yourContent,
)
```

### 性能阈值配置

```dart
// 性能优先
PerformanceThresholds.performance

// 平衡配置
PerformanceThresholds.balanced

// 兼容性配置
PerformanceThresholds.compatibility
```

## 最佳实践

### 1. 性能考虑
- 在低端设备上使用性能优先配置
- 启用自动降级机制
- 监控性能指标

### 2. 用户体验
- 保持可读性，避免过度模糊
- 适配深色和浅色主题
- 提供用户可配置选项

### 3. 设计一致性
- 在整个应用中保持一致的毛玻璃风格
- 根据内容类型选择合适的强度
- 考虑品牌色彩和设计语言

## 故障排除

### 常见问题

1. **性能问题**
   - 降低模糊度参数
   - 启用性能优化
   - 使用预设的性能配置

2. **视觉效果不明显**
   - 增加透明度
   - 检查背景颜色
   - 确保有合适的背景内容

3. **跨平台兼容性问题**
   - 使用响应式配置
   - 测试不同设备
   - 考虑平台特性

## 示例代码

完整示例请参考：
- `lib/src/features/fund/presentation/widgets/enhanced_fund_ranking_card.dart`
- `test/features/fund/presentation/widgets/simple_glassmorphism_test.dart`

## 更新日志

- v1.0.0 - 初始版本，基础毛玻璃效果
- v1.1.0 - 添加性能监控和自动降级
- v1.2.0 - 集成主题系统和响应式配置