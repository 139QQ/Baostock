# Test Design: Story fund.multi-dimensional-profit-comparison

Date: 2025-10-19
Designer: Quinn (Test Architect)
Source: docs/stories/story-multi-dimensional-profit-comparison.md

## Test Strategy Overview

- **Total test scenarios**: 28
- **Unit tests**: 16 (57%)
- **Integration tests**: 8 (29%)
- **E2E tests**: 4 (14%)
- **Priority distribution**: P0: 12, P1: 10, P2: 6

## Test Scenarios by Acceptance Criteria

### AC1: 多基金对比功能 - 支持用户选择2-5个基金进行同时对比

#### Scenarios

| ID | Level | Priority | Test Scenario | Justification |
|----|-------|----------|----------------|---------------|
| fund.multi-UNIT-001 | Unit | P0 | 验证基金选择数量范围(2-5) | 纯输入验证逻辑，边界条件测试 |
| fund.multi-UNIT-002 | Unit | P1 | 验证重复基金选择处理 | 业务逻辑验证，快速失败 |
| fund.multi-UNIT-003 | Unit | P2 | 验证无效基金代码处理 | 错误处理逻辑测试 |
| fund.multi-INT-001 | Integration | P0 | 基金选择器与状态管理集成 | 关键组件交互测试 |
| fund.multi-INT-002 | Integration | P1 | 基金数据获取与验证流程 | API集成测试 |
| fund.multi-E2E-001 | E2E | P1 | 用户完成多基金选择流程 | 关键用户路径验证 |

### AC2: 多时间维度分析 - 提供近1月、近3月、近6月、近1年、近3年五个主要时间段的收益对比

#### Scenarios

| ID | Level | Priority | Test Scenario | Justification |
|----|-------|----------|----------------|---------------|
| fund.multi-UNIT-004 | Unit | P0 | 验证标准时间段枚举值 | 纯数据结构验证 |
| fund.multi-UNIT-005 | Unit | P0 | 收益计算算法准确性 | 复杂业务逻辑测试 |
| fund.multi-UNIT-006 | Unit | P1 | 时间段边界日期计算 | 日期算法测试 |
| fund.multi-UNIT-007 | Unit | P2 | 非标准时间段处理 | 边界条件测试 |
| fund.multi-INT-003 | Integration | P0 | 多时间段数据批量获取 | 数据库/API集成测试 |
| fund.multi-INT-004 | Integration | P1 | 历史数据缓存机制验证 | 缓存层集成测试 |
| fund.multi-E2E-002 | E2E | P1 | 用户查看多时间段对比结果 | 完整用户旅程测试 |

### AC3: 直观数据展示 - 通过表格形式清晰展示各基金在不同时间段的收益表现

#### Scenarios

| ID | Level | Priority | Test Scenario | Justification |
|----|-------|----------|----------------|---------------|
| fund.multi-UNIT-008 | Unit | P1 | 表格数据格式化逻辑 | 数据转换逻辑测试 |
| fund.multi-UNIT-009 | Unit | P2 | 收益值颜色编码规则 | UI逻辑测试 |
| fund.multi-INT-005 | Integration | P0 | 表格组件与数据绑定 | 关键UI组件集成 |
| fund.multi-INT-006 | Integration | P1 | 表格排序功能验证 | 组件功能集成测试 |
| fund.multi-E2E-003 | E2E | P0 | 用户查看完整对比表格 | 核心用户体验验证 |

### AC4: 基础统计分析 - 提供收益平均值、最大值、最小值等基础统计信息

#### Scenarios

| ID | Level | Priority | Test Scenario | Justification |
|----|-------|----------|----------------|---------------|
| fund.multi-UNIT-010 | Unit | P0 | 统计计算算法验证 | 复杂计算逻辑测试 |
| fund.multi-UNIT-011 | Unit | P1 | 空数据集统计处理 | 边界条件测试 |
| fund.multi-UNIT-012 | Unit | P2 | 异常值对统计影响测试 | 数据质量测试 |
| fund.multi-INT-007 | Integration | P1 | 统计组件与数据流集成 | 组件集成验证 |

### AC5: 现有基金详情页面继续正常工作 - 对比功能作为新增页面，不影响现有功能

#### Scenarios

| ID | Level | Priority | Test Scenario | Justification |
|----|-------|----------|----------------|---------------|
| fund.multi-INT-008 | Integration | P0 | 现有页面导航无影响 | 关键回归测试 |
| fund.multi-E2E-004 | E2E | P0 | 用户使用现有功能无变化 | 完整回归验证 |

### AC6: 新功能遵循现有BLoC模式 - 使用FundRankingBloc相似的状态管理模式

#### Scenarios

| ID | Level | Priority | Test Scenario | Justification |
|----|-------|----------|----------------|---------------|
| fund.multi-UNIT-013 | Unit | P1 | BLoC状态转换逻辑 | 状态管理测试 |
| fund.multi-UNIT-014 | Unit | P2 | 错误状态处理机制 | 异常处理测试 |
| fund.multi-INT-008 | Integration | P1 | BLoC与UI组件集成 | 架构合规性测试 |

### AC7: 与现有API服务集成 - 复用http://154.44.25.92:8080/的基金数据接口

#### Scenarios

| ID | Level | Priority | Test Scenario | Justification |
|----|-------|----------|----------------|---------------|
| fund.multi-INT-009 | Integration | P0 | API调用契约验证 | 关键集成点测试 |
| fund.multi-INT-010 | Integration | P1 | API错误响应处理 | 错误处理集成测试 |

### AC8: 对比功能覆盖单元测试 - 确保计算逻辑和数据展示的准确性

#### Scenarios

| ID | Level | Priority | Test Scenario | Justification |
|----|-------|----------|----------------|---------------|
| fund.multi-UNIT-015 | Unit | P0 | 测试覆盖率达到80% | 质量要求验证 |
| fund.multi-UNIT-016 | Unit | P1 | 关键计算路径测试 | 质量保证测试 |

### AC9: 性能影响最小化 - 对比数据加载时间控制在3秒以内

#### Scenarios

| ID | Level | Priority | Test Scenario | Justification |
|----|-------|----------|----------------|---------------|
| fund.multi-INT-011 | Integration | P0 | 数据加载性能基准测试 | 关键性能要求 |
| fund.multi-INT-012 | Integration | P1 | 并发用户性能测试 | 性能压力测试 |

## Risk Coverage

Based on the risk assessment (fund.multi-dimensional-profit-comparison-risk-20251019.md), the following test scenarios address identified risks:

### High Priority Risk Mitigation

1. **Performance SLA Risk (3-second target)**
   - Covered by: fund.multi-INT-011, fund.multi-INT-012
   - Test level: Integration (performance testing)
   - Justification: Requires realistic data loading conditions

2. **Statistics Calculation Accuracy**
   - Covered by: fund.multi-UNIT-010, fund.multi-UNIT-011, fund.multi-UNIT-012
   - Test level: Unit (calculation logic)
   - Justification: Complex business logic requiring isolated testing

3. **Data Integrity in Comparison**
   - Covered by: fund.multi-UNIT-005, fund.multi-INT-003
   - Test level: Unit + Integration
   - Justification: Multi-layer validation required

### Medium Priority Risk Mitigation

1. **UI Component Integration**
   - Covered by: fund.multi-INT-005, fund.multi-INT-006
   - Test level: Integration
   - Justification: Component interaction critical for user experience

2. **API Reliability**
   - Covered by: fund.multi-INT-009, fund.multi-INT-010
   - Test level: Integration
   - Justification: External dependency requiring contract testing

## Test Data Requirements

### Unit Test Data

```dart
// 基础测试数据集
final testFunds = [
  '000001', // 股票型基金
  '110022', // 混合型基金
  '000003', // 指数型基金
  '161725', // 债券型基金
  '005827', // QDII基金
];

final testPeriods = [
  RankingPeriod.oneMonth,
  RankingPeriod.threeMonths,
  RankingPeriod.sixMonths,
  RankingPeriod.oneYear,
  RankingPeriod.threeYears,
];

// 边界条件数据
final edgeCaseFunds = ['', 'INVALID', '1234567890'];
final edgeCasePeriods = [null, RankingPeriod.invalid];
```

### Integration Test Data

```dart
// 真实基金代码（用于集成测试）
final realFundCodes = [
  '000001', // 华夏成长混合
  '110022', // 易方达消费行业
  '000003', // 中国增长
];

// 模拟API响应数据
final mockApiResponse = {
  '000001': {
    '1M': 0.0523,
    '3M': 0.1567,
    '6M': 0.2345,
    '1Y': 0.4567,
    '3Y': 0.7890,
  },
  // ... 其他基金数据
};
```

### E2E Test Scenarios

```yaml
user_journeys:
  - name: "完整对比流程"
    steps:
      1. 打开基金对比页面
      2. 选择3个基金进行对比
      3. 选择3个时间段
      4. 查看对比结果
      5. 验证统计数据准确性

  - name: "回归测试流程"
    steps:
      1. 访问基金详情页面
      2. 验证页面正常加载
      3. 检查现有功能无变化
      4. 确认导航正常工作
```

## Recommended Execution Order

### Phase 1: Foundation (P0 Unit Tests)
1. fund.multi-UNIT-001: 基金选择验证
2. fund.multi-UNIT-004: 时间段验证
3. fund.multi-UNIT-005: 收益计算算法
4. fund.multi-UNIT-010: 统计计算算法
5. fund.multi-UNIT-015: 测试覆盖率验证

### Phase 2: Integration (P0 Integration Tests)
1. fund.multi-INT-001: 基金选择器集成
2. fund.multi-INT-003: 多时间段数据获取
3. fund.multi-INT-005: 表格组件集成
4. fund.multi-INT-008: 现有功能回归
5. fund.multi-INT-009: API集成验证
6. fund.multi-INT-011: 性能基准测试

### Phase 3: User Experience (P0 E2E Tests)
1. fund.multi-E2E-001: 多基金选择流程
2. fund.multi-E2E-003: 查看对比表格
3. fund.multi-E2E-004: 现有功能回归验证

### Phase 4: Edge Cases (P1 Tests)
1. 执行所有P1单元测试
2. 执行所有P1集成测试
3. 执行所有P1 E2E测试

### Phase 5: Comprehensive Coverage (P2 Tests)
1. 执行所有P2测试（如果时间允许）

## Test Environment Setup

### Unit Test Environment
- Flutter test framework
- Mock dependencies (Repository, API clients)
- In-memory data structures
- Fast execution (< 1 second per test)

### Integration Test Environment
- Test database (SQLite in-memory)
- Mock API server (http_mock_adapter)
- Real component interactions
- Moderate execution time (5-30 seconds per test)

### E2E Test Environment
- Flutter integration test framework
- Real device/emulator
- Test API endpoints (staging environment)
- Slower execution (30 seconds - 2 minutes per test)

## Performance Testing Requirements

### Baseline Performance Targets
- 数据加载时间: < 3秒 (P0要求)
- UI渲染时间: < 500ms
- 内存使用增长: < 50MB
- CPU使用率: < 80% (峰值)

### Performance Test Scenarios
1. **基准性能测试** (fund.multi-INT-011)
   - 单用户对比2-5个基金
   - 测量完整流程时间
   - 验证3秒SLA达标

2. **并发性能测试** (fund.multi-INT-012)
   - 模拟10个并发用户
   - 测量响应时间变化
   - 验证系统稳定性

3. **大数据量测试**
   - 对比最大基金数量(5个)
   - 使用最大时间段数量(5个)
   - 验证性能不显著下降

## Quality Gates

### Entry Criteria
- All code changes committed
- Static analysis passes
- Documentation updated
- Test environment prepared

### Exit Criteria
- All P0 tests pass (100%)
- All P1 tests pass (90%+)
- P2 tests pass (70%+ if executed)
- Performance targets met
- Code coverage >= 80%
- No critical defects

### Test Metrics Dashboard
- Test execution results
- Code coverage trends
- Performance benchmark results
- Defect density and trends
- Test execution time trends

## Maintenance Considerations

### Test Data Management
- Regularly update test fund codes
- Refresh mock API responses
- Maintain test data validity
- Version control test datasets

### Test Execution Optimization
- Parallel test execution where possible
- Selective test execution based on changes
- Cached test results for unchanged code
- Automated test scheduling

### Regression Test Strategy
- Full test suite execution before releases
- Smoke tests for quick validation
- Critical path testing for hotfixes
- Automated regression in CI/CD pipeline

---

**Generated**: 2025-10-19
**Total Test Investment**: ~40 hours development + ~10 hours maintenance
**Risk Coverage**: High - All critical risks addressed with appropriate test levels
**Confidence Score**: 85% - Comprehensive coverage with performance focus