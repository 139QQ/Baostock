# 基金多维对比功能使用指南

## 概述

基金多维对比功能是Baostock应用的核心功能之一，允许用户对比2-5只基金在不同时间段的表现，帮助投资者做出更明智的投资决策。

## 功能特性

### 🎯 核心功能
- **多基金对比**: 支持2-5只基金同时对比
- **多时间段分析**: 支持1个月、3个月、6个月、1年、3年等时间段
- **多维度指标**: 收益率、波动率、夏普比率、最大回撤等
- **实时数据**: 支持API实时数据获取和本地缓存
- **智能分析**: 自动计算相关性、风险等级、收益分析等

### 📊 对比指标
- **收益指标**: 累计收益率、年化收益率、超越同类/基准表现
- **风险指标**: 波动率、最大回撤、风险等级评估
- **风险调整收益**: 夏普比率、收益风险比
- **统计指标**: 相关性矩阵、收益分布、胜率分析

### 🎨 用户界面
- **直观选择器**: 易于使用的基金和时间段选择界面
- **对比表格**: 清晰的数据展示和排序功能
- **可视化图表**: 多种图表类型展示对比结果
- **响应式设计**: 适配不同屏幕尺寸

## 快速开始

### 1. 基础使用

```dart
import 'package:baostock/src/features/fund/presentation/widgets/fund_comparison_entry.dart';

// 在现有页面中添加对比入口
FundComparisonEntryFactory.createPrimaryButton(
  availableFunds: fundList,
  onTap: () => _onComparisonTap(),
)
```

### 2. 预选基金对比

```dart
FundComparisonEntryFactory.createFeatureCard(
  availableFunds: fundList,
  preselectedFunds: ['000001', '110022'], // 预选基金代码
  onTap: () => _onComparisonTap(),
)
```

### 3. 导航到对比页面

```dart
import 'package:baostock/src/features/fund/presentation/routes/fund_comparison_routes.dart';

FundComparisonRoutes.navigateToComparison(
  context,
  availableFunds: fundList,
  initialCriteria: MultiDimensionalComparisonCriteria(
    fundCodes: ['000001', '110022'],
    periods: [RankingPeriod.oneYear],
    metric: ComparisonMetric.totalReturn,
  ),
);
```

## 详细使用指南

### 创建对比条件

```dart
final criteria = MultiDimensionalComparisonCriteria(
  fundCodes: ['000001', '110022', '000002'], // 2-5只基金
  periods: [RankingPeriod.oneYear, RankingPeriod.threeMonths], // 时间段
  metric: ComparisonMetric.totalReturn, // 对比指标
  includeStatistics: true, // 包含统计信息
  sortBy: ComparisonSortBy.totalReturn, // 排序方式
  name: '我的对比', // 对比名称（可选）
);

// 验证条件有效性
if (criteria.isValid) {
  // 执行对比
} else {
  print(criteria.getValidationError()); // 显示错误信息
}
```

### 对比结果分析

```dart
final result = await fundComparisonCubit.loadComparison(criteria);

if (result.hasData) {
  // 获取最佳表现基金
  final bestFund = result.getBestPerformingFund();

  // 获取最差表现基金
  final worstFund = result.getWorstPerformingFund();

  // 获取统计信息
  final stats = result.statistics;
  print('平均收益率: ${stats.averageReturn * 100}%');
  print('平均波动率: ${stats.averageVolatility * 100}%');

  // 获取特定基金数据
  final fundData = result.getFundData('000001');
}
```

### 自定义对比入口

```dart
// 创建主要按钮
FundComparisonEntryFactory.createPrimaryButton(
  availableFunds: funds,
  preselectedFunds: selectedFunds,
  onTap: () => handleComparisonTap(),
)

// 创建功能卡片
FundComparisonEntryFactory.createFeatureCard(
  availableFunds: funds,
  title: '专业基金对比',
  description: '深度分析基金表现差异',
  onTap: () => handleComparisonTap(),
)

// 创建浮动操作按钮
FundComparisonEntryFactory.createFloatingAction(
  availableFunds: funds,
  onTap: () => handleComparisonTap(),
)
```

## 高级功能

### 缓存管理

```dart
// 获取缓存管理器
final cacheCubit = ComparisonCacheCubit();

// 检查是否有缓存
if (cacheCubit.hasCachedComparison(criteria)) {
  final cachedResult = cacheCubit.getCachedComparison(criteria);
}

// 缓存对比结果
await cacheCubit.cacheComparisonResult(result);

// 清除过期缓存
await cacheCubit.clearExpiredCache();

// 获取缓存统计
final stats = cacheCubit.getCacheStatistics();
```

### 错误处理

```dart
try {
  final result = await fundComparisonCubit.loadComparison(criteria);
  // 处理成功结果
} catch (e) {
  // 处理错误
  final friendlyMessage = ComparisonErrorHandler.getUserFriendlyMessage(e);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(friendlyMessage)),
  );
}
```

### API集成

```dart
// 使用实时API数据
final result = await fundComparisonService.getRealtimeComparisonData(criteria);

// 带重试的API调用
final result = await ComparisonErrorHandler.executeWithErrorHandling(
  () => apiService.getFundData(fundCodes),
  fallbackValue: defaultData,
  retryConfig: RetryConfig(maxRetries: 3),
);
```

## 最佳实践

### 1. 性能优化

```dart
// 使用缓存减少API调用
final cacheCubit = context.read<ComparisonCacheCubit>();
final cachedResult = cacheCubit.getCachedComparison(criteria);

if (cachedResult != null) {
  return cachedResult; // 使用缓存数据
}

// 异步加载，避免阻塞UI
unawaited(fundComparisonCubit.loadComparison(criteria));
```

### 2. 用户体验优化

```dart
// 显示加载状态
if (isLoading) {
  return const Center(child: CircularProgressIndicator());
}

// 提供有意义的错误信息
if (hasError) {
  return ErrorWidget(
    message: ComparisonErrorHandler.getUserFriendlyMessage(error),
    onRetry: () => retryLoad(),
  );
}

// 提供空状态提示
if (fundList.isEmpty) {
  return EmptyStateWidget(
    message: '暂无基金数据，请稍后重试',
    action: () => refreshData(),
  );
}
```

### 3. 数据验证

```dart
// 验证输入参数
final validationError = ComparisonErrorHandler.validateInput(criteria);
if (validationError != null) {
  throw ValidationException(validationError);
}

// 验证API响应
if (response.statusCode != 200) {
  final error = ComparisonErrorHandler.parseApiError(
    response.body,
    response.statusCode,
  );
  throw ApiException(error.message);
}
```

## 故障排除

### 常见问题

**Q: 对比结果显示"暂无数据"**
A: 检查以下几点：
- 确保选择了2-5只基金
- 确保选择了至少一个时间段
- 检查网络连接状态
- 尝试刷新数据

**Q: 加载速度很慢**
A: 优化建议：
- 减少对比的基金数量
- 减少选择的时间段
- 使用缓存功能
- 检查网络连接质量

**Q: 数据不准确**
A: 可能原因：
- 数据源更新延迟
- 缓存数据过期
- API响应异常
- 尝试强制刷新数据

### 调试技巧

```dart
// 启用调试日志
AppLogger.setLevel(LogLevel.debug);

// 监听状态变化
fundComparisonCubit.stream.listen((state) {
  print('状态变更: ${state.status}');
  if (state.hasError) {
    print('错误信息: ${state.error}');
  }
});

// 获取详细的API响应
final response = await apiClient.getFundsForComparison(fundCodes);
print('API响应: ${response}');
```

## 版本更新日志

### v1.0.0 (当前版本)
- ✅ 基础对比功能
- ✅ 多时间段分析
- ✅ 实时数据集成
- ✅ 缓存机制
- ✅ 错误处理
- ✅ 单元测试

### 计划功能
- 🔄 更多图表类型
- 🔄 对比结果导出
- 🔄 历史对比记录
- 🔄 自定义指标
- 🔄 分享功能

## 技术支持

如果遇到问题或需要技术支持，请：

1. 查看本文档的故障排除部分
2. 检查应用的日志输出
3. 提交Issue到项目仓库
4. 联系开发团队

## 贡献指南

欢迎为基金对比功能贡献代码：

1. Fork项目仓库
2. 创建功能分支
3. 编写测试用例
4. 提交Pull Request
5. 等待代码审查

---

*最后更新: 2024年1月*