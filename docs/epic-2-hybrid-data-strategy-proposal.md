# Epic 2 技术规范更新建议：混合数据获取策略

**日期**: 2025-11-07
**作者**: BMad (Scrum Master)
**Epic ID**: 2
**状态**: 建议更新

---

## 📋 更新背景

基于用户对实时参数的需求反馈，以及Story 2.1审核过程中发现的架构不一致性问题，建议将Epic 2的技术规范从纯HTTP轮询策略更新为**混合数据获取策略**，既保持架构一致性，又满足关键数据的实时性需求。

## 🎯 核心变更建议

### 1. 数据获取策略演进

**当前策略**: 纯HTTP轮询
```
HTTP轮询 → 所有数据类型 → 固定频率获取
```

**建议策略**: 混合数据获取
```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ 实时数据层   │ →  │ WebSocket   │ →  │ 关键参数     │
│ (毫秒级)     │    │ (预留扩展)   │    │ (指数、ETF) │
└─────────────┘    └─────────────┘    └─────────────┘
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ 准实时数据层 │ →  │ HTTP轮询    │ →  │ 基金数据     │
│ (秒级)       │    │ (当前实现)   │    │ (净值、信息) │
└─────────────┘    └─────────────┘    └─────────────┘
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ 历史数据层   │ →  │ HTTP按需    │ →  │ 分析数据     │
│ (按需)       │    │ (现有实现)   │    │ (业绩、报告) │
└─────────────┘    └─────────────┘    └─────────────┘
```

### 2. 数据分类和优先级

**高优先级 - 实时数据 (未来WebSocket扩展)**
- 市场指数：上证指数、深证成指、创业板指等
- ETF实时价格：交易时段的实时价格
- 宏观经济指标：重要发布的经济数据
- 突发市场事件：影响投资决策的即时信息

**中优先级 - 准实时数据 (当前HTTP轮询)**
- 基金净值：交易时段每15分钟更新
- 基金基础信息：定期更新的基金信息
- 市场交易数据：批量市场交易信息

**低优先级 - 按需数据 (现有HTTP API)**
- 历史业绩数据：基金历史表现
- 基金持仓详情：季度持仓报告
- 分析报告数据：专业分析报告

## 🏗️ 架构设计建议

### 1. 可插拔数据获取架构

```dart
// 数据获取策略接口
abstract class DataFetchStrategy {
  Stream<DataItem> getDataStream(DataType type);
  bool isAvailable();
  int getPriority();
  Duration getDefaultInterval();
}

// HTTP轮询策略 (当前实现)
class HttpPollingStrategy implements DataFetchStrategy {
  final Dio _dio;
  final Map<DataType, Duration> _intervals;

  @override
  Stream<DataItem> getDataStream(DataType type) {
    // HTTP轮询实现
  }
}

// WebSocket策略 (未来扩展)
class WebSocketStrategy implements DataFetchStrategy {
  final WebSocketManager _wsManager;

  @override
  Stream<DataItem> getDataStream(DataType type) {
    // WebSocket实现
  }
}

// 混合数据管理器
class HybridDataManager {
  final Map<DataType, List<DataFetchStrategy>> _strategies;
  final DataTypeRouter _router;

  Stream<DataItem> getOptimalDataStream(DataType type) {
    final availableStrategies = _getAvailableStrategies(type);
    final optimalStrategy = _selectOptimalStrategy(availableStrategies);
    return optimalStrategy.getDataStream(type);
  }
}
```

### 2. 智能数据路由系统

```dart
enum DataSourcePriority {
  realtime,     // WebSocket - 毫秒级
  polling,      // HTTP轮询 - 秒级到分钟级
  onDemand,     // HTTP按需 - 无固定时间要求
}

class DataType {
  final String id;
  final String name;
  final DataSourcePriority priority;
  final Duration defaultInterval;
  final List<String> dependencies;

  // 预定义数据类型
  static const marketIndex = DataType(
    id: 'market_index',
    name: '市场指数',
    priority: DataSourcePriority.realtime,
    defaultInterval: Duration(seconds: 1),
  );

  static const fundNav = DataType(
    id: 'fund_nav',
    name: '基金净值',
    priority: DataSourcePriority.polling,
    defaultInterval: Duration(minutes: 15),
  );
}
```

## 📊 实施路径建议

### 阶段1：HTTP轮询基础 (当前Sprint)
- ✅ 实现HybridDataManager基础架构
- ✅ 完成HTTP轮询策略实现
- ✅ 预留WebSocket扩展接口
- ✅ 实现数据类型路由和优先级系统

### 阶段2：实时数据扩展 (下个Sprint)
- 🔄 实现WebSocket基础连接
- 🔄 集成关键实时数据获取
- 🔄 智能路由算法优化
- 🔄 用户配置和实时性级别控制

### 阶段3：智能优化 (后续Sprint)
- ⏳ 基于用户行为的智能频率调整
- ⏳ 预测性数据获取
- ⏳ 性能优化和成本控制
- ⏳ 高级缓存策略

## 🎛️ 用户配置系统

### 实时性级别配置

```dart
enum RealtimeLevel {
  conservative,  // 保守：仅HTTP轮询
  balanced,      // 平衡：关键数据WebSocket
  aggressive,    // 激进：最大化实时性
}

class RealtimeSettings {
  RealtimeLevel level = RealtimeLevel.balanced;
  bool enableMarketIndexRealtime = true;
  bool enableFundValuePolling = true;
  bool enableEventPush = true;

  Map<DataType, Duration> customIntervals = {};
  Set<DataType> disabledDataTypes = {};
}
```

## 🔍 影响评估

### 技术影响
- **✅ 架构一致性**：保持现有Dio + BLoC架构，最小化变更
- **✅ 向后兼容**：现有功能完全不受影响
- **✅ 扩展性**：为未来WebSocket实现预留清晰接口
- **✅ 可维护性**：策略模式设计，易于测试和维护

### 性能影响
- **📈 实时性提升**：关键数据从分钟级提升到秒级
- **📉 资源消耗可控**：用户可配置实时性级别
- **⚖️ 成本效益平衡**：按需使用实时数据，避免过度资源消耗

### 用户体验影响
- **🎯 满足专业需求**：关键参数的实时更新
- **⚙️ 灵活配置**：用户可根据需求调整实时性级别
- **📱 渐进式体验**：可逐步启用更高级的实时功能

## 🚀 建议的下一步行动

### 立即行动 (当前Sprint)
1. **审核并批准本建议**：确认混合数据获取策略方向
2. **更新Epic 2技术规范**：将本建议集成到官方技术规范中
3. **完成Story 2.1开发**：实现混合数据管理基础架构
4. **设计WebSocket扩展接口**：为下个阶段做好准备

### 后续规划
1. **评估WebSocket基础设施**：确认服务器支持和部署需求
2. **制定实时数据范围**：明确哪些数据需要WebSocket支持
3. **用户调研**：了解专业投资者对实时性的具体需求
4. **性能基准测试**：验证混合架构的性能表现

## 📝 总结

混合数据获取策略既解决了当前架构一致性问题，又为用户提供了关键的实时参数支持。通过分层数据获取和智能路由，我们能够在保持系统稳定性的同时，逐步提升实时性能力。

**建议优先级**：🔥 **高优先级**
- 解决了架构不一致性阻塞性问题
- 满足了用户对实时参数的需求
- 保持了技术栈的一致性和稳定性
- 为未来扩展预留了清晰的路径

这个更新将为基速基金量化分析平台提供更加灵活和强大的数据获取能力，同时保持架构的整洁和可维护性。