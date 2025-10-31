# 数据层架构说明

## 概述

本项目的数据层采用分层架构设计，整合了多个高性能的数据管理组件，提供统一、高效、可靠的数据访问服务。

## 架构组件

### 核心组件

1. **DataLayerCoordinator** - 数据层协调器
   - 统一的数据访问接口
   - 组件间协调和数据流管理
   - 健康检查和性能监控

2. **UnifiedCacheManager** - 统一缓存管理器
   - 多层缓存策略（内存 + 持久化）
   - 智能缓存失效和更新
   - 自适应缓存大小管理

3. **IntelligentDataSourceSwitcher** - 智能数据源切换器
   - API源自动切换和故障转移
   - 健康检查机制
   - 模拟数据回退

4. **DataSyncManager** - 数据同步管理器
   - 智能数据同步策略
   - 增量更新机制
   - 数据版本控制和冲突解决

5. **SmartCacheManager** - 智能缓存管理器
   - LRU淘汰算法
   - 缓存预热和预加载
   - 性能统计和监控

6. **OptimizedFundService** - 优化版基金服务
   - 请求去重避免重复请求
   - 网络优化和批量操作
   - 统一错误处理

7. **IntelligentPreloadService** - 智能预加载服务
   - 基于用户行为的预测性预加载
   - 常用筛选组合预加载
   - 增量更新

### 支持组件

- **DataLayerOptimizer** - 数据层优化器
- **DataLayerIntegration** - 数据层集成配置
- **UnifiedCacheAdapter** - 统一缓存适配器

## 使用指南

### 基本使用

```dart
import 'package:your_app/src/core/data/config/data_layer_integration.dart';

// 1. 配置数据层（开发环境）
final coordinator = await DataLayerIntegration.configureForDevelopment();

// 2. 获取基金列表
final funds = await coordinator.getFunds();

// 3. 搜索基金
final searchResults = await coordinator.searchFunds(criteria);

// 4. 获取排行榜数据
final rankings = await coordinator.getFundRankings(rankingCriteria);

// 5. 批量获取基金数据
final batchFunds = await coordinator.getBatchFunds(fundCodes);
```

### 高级配置

```dart
import 'package:your_app/src/core/data/config/data_layer_integration.dart';

// 自定义配置
final coordinator = await DataLayerFactory.createCustom(
  environment: 'production',
  enableMonitoring: true,
  enableDebugLogging: false,
);
```

### 性能监控

```dart
import 'package:your_app/src/core/data/optimization/data_layer_optimizer.dart';

// 1. 创建优化器
final optimizer = DataLayerOptimizer(coordinator);

// 2. 启动自动优化
optimizer.startAutoOptimization();

// 3. 获取性能指标
final metrics = await coordinator.getPerformanceMetrics();

// 4. 获取优化建议
final suggestions = await optimizer.getOptimizationSuggestions();

// 5. 手动执行优化
final result = await optimizer.performManualOptimization([
  'cache_hit_rate',
  'response_time',
]);

// 6. 生成优化报告
final report = await optimizer.generateReport();
print(report.summary);
```

### 健康检查

```dart
// 获取健康报告
final healthReport = await coordinator.getHealthReport();

if (!healthReport.isHealthy) {
  print('健康问题: ${healthReport.issues}');
  // 执行修复操作
  await coordinator.refreshCache();
}
```

### 事件监听

```dart
// 监听数据源切换事件
coordinator.getEventStream<DataSourceSwitchedEvent>('dataSourceSwitched')
  .listen((event) {
    print('数据源已切换: ${event.from?.name} -> ${event.to.name}');
  });
```

## 环境配置

### 开发环境

```dart
final coordinator = await DataLayerIntegration.configureForDevelopment();
```

特点：
- 启用调试日志
- 较短的缓存时间
- 频繁的健康检查
- 较小的缓存大小

### 生产环境

```dart
final coordinator = await DataLayerIntegration.configureForProduction();
```

特点：
- 禁用调试日志
- 较长的缓存时间
- 优化的健康检查间隔
- 较大的缓存大小
- 启用压缩和加密

### 测试环境

```dart
final coordinator = await DataLayerIntegration.configureForTesting();
```

特点：
- 最小化的配置
- 内存缓存优先
- 快速初始化

## 性能优化

### 自动优化

数据层优化器提供自动优化功能：

- **缓存命中率优化**: 当命中率低于70%时自动触发
- **响应时间优化**: 当响应时间超过100ms时自动触发
- **内存使用优化**: 当内存缓存超过2000项时自动触发
- **健康问题修复**: 当检测到健康问题时自动触发

### 手动优化

```dart
// 手动执行特定优化
await optimizer.performManualOptimization([
  'cache_hit_rate',      // 优化缓存命中率
  'response_time',       // 优化响应时间
  'memory_usage',        // 优化内存使用
  'health_issues',       // 修复健康问题
]);
```

### 性能调优配置

```dart
// 激进优化配置
final aggressiveConfig = DataLayerOptimizationConfig.aggressive();

// 保守优化配置
final conservativeConfig = DataLayerOptimizationConfig.conservative();

// 自定义配置
final customConfig = DataLayerOptimizationConfig(
  optimizationInterval: Duration(minutes: 5),
  minCacheHitRate: 0.8,
  maxResponseTime: 50.0,
  maxMemoryCacheSize: 1000,
);
```

## 最佳实践

### 1. 初始化和生命周期管理

```dart
class MyService {
  DataLayerCoordinator? _coordinator;
  DataLayerOptimizer? _optimizer;

  Future<void> initialize() async {
    // 配置数据层
    _coordinator = await DataLayerFactory.createProduction();

    // 创建优化器
    _optimizer = DataLayerOptimizer(_coordinator);
    _optimizer!.startAutoOptimization();
  }

  Future<void> dispose() async {
    _optimizer?.dispose();
    await _coordinator?.dispose();
  }
}
```

### 2. 错误处理

```dart
try {
  final funds = await coordinator.getFunds(
    criteria: criteria,
    forceRefresh: false,
    timeout: Duration(seconds: 10),
  );
  // 处理成功结果
} catch (e) {
  // 处理错误
  print('获取基金列表失败: $e');

  // 可以尝试降级策略
  if (e is DataSourceException) {
    final cachedFunds = await _getCachedFunds(criteria);
    if (cachedFunds.isNotEmpty) {
      return cachedFunds;
    }
  }

  rethrow;
}
```

### 3. 批量操作

```dart
// 推荐：使用批量API减少网络请求
final batchFunds = await coordinator.getBatchFunds(fundCodes);

// 避免：循环单个请求
final funds = <Fund>[];
for (final code in fundCodes) {
  final fund = await coordinator.getFundDetail(code);
  funds.add(fund);
}
```

### 4. 缓存策略

```dart
// 对于不常变化的数据，使用长缓存时间
final funds = await coordinator.getFunds(
  criteria: staticCriteria,
  forceRefresh: false, // 优先使用缓存
);

// 对于实时性要求高的数据，强制刷新
final realTimeData = await coordinator.getFunds(
  criteria: dynamicCriteria,
  forceRefresh: true,  // 强制刷新
);
```

## 故障排查

### 常见问题

1. **缓存命中率低**
   - 检查缓存键生成逻辑
   - 确认缓存时间配置
   - 执行缓存优化

2. **响应时间慢**
   - 检查网络连接
   - 清理过期缓存
   - 优化内存使用

3. **内存使用过高**
   - 减少缓存大小
   - 清理不常用数据
   - 调整数据保留策略

### 调试工具

```dart
// 启用调试日志
final coordinator = await DataLayerConfigBuilder()
    .setEnvironment('development')
    .setDebugLoggingEnabled(true)
    .build();

// 获取详细状态
final status = DataLayerIntegration.getStatus();
print('组件状态: ${status.components}');

// 获取性能指标
final metrics = await coordinator.getPerformanceMetrics();
print('缓存命中率: ${metrics.cacheHitRate}');
print('响应时间: ${metrics.averageResponseTime}ms');

// 生成健康报告
final healthReport = await coordinator.getHealthReport();
if (!healthReport.isHealthy) {
  print('健康问题: ${healthReport.issues}');
}
```

## 性能指标

### 目标指标

- **缓存命中率**: > 80%
- **平均响应时间**: < 100ms
- **内存缓存大小**: < 2000项
- **数据同步成功率**: > 95%

### 监控指标

- 缓存命中率趋势
- 响应时间分布
- 内存使用情况
- 错误率和重试次数
- 数据源切换频率

## 扩展指南

### 添加新的数据源

1. 实现数据源接口
2. 在 `IntelligentDataSourceSwitcher` 中注册
3. 更新配置文件

### 添加新的缓存策略

1. 实现 `ICacheStrategy` 接口
2. 在 `CacheStrategyFactory` 中注册
3. 更新配置管理器

### 添加新的优化策略

1. 在 `DataLayerOptimizer` 中添加新的优化类型
2. 实现具体的优化逻辑
3. 更新配置和建议生成

---

## 总结

本数据层架构提供了：

✅ **统一的数据访问接口**
✅ **高性能的缓存管理**
✅ **智能的数据源切换**
✅ **自动的性能优化**
✅ **完善的监控和诊断**

通过合理配置和使用，可以显著提升应用的数据访问性能和用户体验。