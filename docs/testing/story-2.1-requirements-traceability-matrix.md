# Story 2.1 基础收益计算引擎 - 需求跟踪矩阵

## 文档信息
- **Story**: 2.1 基础收益计算引擎
- **创建日期**: 2025-10-19
- **最后更新**: 2025-10-19
- **状态**: 进行中
- **测试覆盖目标**: 100%

---

## 验收标准映射

### 功能需求 (Functional Requirements)

#### AC-001: 基础收益指标计算
**验收标准**: 系统必须能够计算累计收益、年化收益率、期间收益率等核心指标

| 测试用例ID | 测试用例描述 | Given-When-Then格式 | 测试类型 | 优先级 | 测试文件位置 | 实现状态 |
|-----------|-------------|-------------------|---------|--------|-------------|----------|
| TC-FP-001 | 计算累计收益率 | Given 用户持有基金数据<br>When 计算累计收益<br>Then 返回准确的累计收益率数值 | 单元测试 | 高 | `test/features/portfolio/domain/services/portfolio_profit_calculation_engine_test.dart` | ✅ 已实现 |
| TC-FP-002 | 计算年化收益率 | Given 基金持仓时间超过1年<br>When 计算年化收益率<br>Then 返回基于复利的年化收益率 | 单元测试 | 高 | `test/features/portfolio/domain/services/portfolio_profit_calculation_engine_test.dart` | ✅ 已实现 |
| TC-FP-003 | 计算期间收益率 | Given 指定起止日期<br>When 计算期间收益率<br>Then 返回该时间段的收益率 | 单元测试 | 高 | `test/features/portfolio/domain/services/portfolio_profit_calculation_engine_test.dart` | ✅ 已实现 |

#### AC-002: 多时间维度支持
**验收标准**: 支持1周、1月、3月、6月、1年、3年等标准时间段的收益计算

| 测试用例ID | 测试用例描述 | Given-When-Then格式 | 测试类型 | 优先级 | 测试文件位置 | 实现状态 |
|-----------|-------------|-------------------|---------|--------|-------------|----------|
| TC-FP-004 | 1周收益率计算 | Given 基金近7天净值数据<br>When 计算1周收益率<br>Then 返回准确的周收益率 | 单元测试 | 中 | `test/features/portfolio/domain/services/portfolio_profit_calculation_engine_test.dart` | ✅ 已实现 |
| TC-FP-005 | 1月收益率计算 | Given 基金近30天净值数据<br>When 计算1月收益率<br>Then 返回准确的月收益率 | 单元测试 | 高 | `test/features/portfolio/domain/services/portfolio_profit_calculation_engine_test.dart` | ✅ 已实现 |
| TC-FP-006 | 3年收益率计算 | Given 基金近3年净值数据<br>When 计算3年收益率<br>Then 返回准确的3年收益率 | 单元测试 | 中 | `test/features/portfolio/domain/services/portfolio_profit_calculation_engine_test.dart` | ✅ 已实现 |

#### AC-003: 收益数据处理
**验收标准**: 能够处理分红、拆分等公司行为对收益计算的影响

| 测试用例ID | 测试用例描述 | Given-When-Then格式 | 测试类型 | 优先级 | 测试文件位置 | 实现状态 |
|-----------|-------------|-------------------|---------|--------|-------------|----------|
| TC-FP-007 | 分红再投资计算 | Given 基金分红数据<br>When 计算分红再投资收益<br>Then 返回包含分红再投资的复合收益率 | 单元测试 | 高 | `test/features/portfolio/domain/services/corporate_action_adjustment_service_test.dart` | ✅ 已实现 |
| TC-FP-008 | 拆分调整计算 | Given 基金拆分数据<br>When 调整拆分后净值序列<br>Then 返回拆分调整后的收益率 | 单元测试 | 高 | `test/features/portfolio/domain/services/corporate_action_adjustment_service_test.dart` | ✅ 已实现 |
| TC-FP-009 | 除权除息处理 | Given 基金除权除息数据<br>When 计算收益率<br>Then 正确处理除权除息对净值的影响 | 集成测试 | 中 | `test/features/portfolio/data/services/portfolio_profit_api_service_test.dart` | ✅ 已实现 |

#### AC-004: 基准比较
**验收标准**: 支持与基准指数(如沪深300)的收益对比计算

| 测试用例ID | 测试用例描述 | Given-When-Then格式 | 测试类型 | 优先级 | 测试文件位置 | 实现状态 |
|-----------|-------------|-------------------|---------|--------|-------------|----------|
| TC-FP-010 | 基准收益率对比 | Given 基金和沪深300指数数据<br>When 计算相对收益率<br>Then 返回基金相对基准的超额收益 | 单元测试 | 高 | `test/features/portfolio/domain/services/portfolio_profit_calculation_engine_test.dart` | ✅ 已实现 |
| TC-FP-011 | Beta值计算 | Given 基金和基准指数历史数据<br>When 计算Beta值<br>Then 返回准确的系统性风险指标 | 单元测试 | 中 | `test/features/portfolio/domain/services/portfolio_profit_calculation_engine_test.dart` | ✅ 已实现 |
| TC-FP-012 | Alpha值计算 | Given 基金收益率、基准收益率和无风险利率<br>When 计算Alpha值<br>Then 返回准确的超额收益指标 | 单元测试 | 中 | `test/features/portfolio/domain/services/portfolio_profit_calculation_engine_test.dart` | ✅ 已实现 |

#### AC-005: 风险收益指标
**验收标准**: 实现夏普比率、最大回撤、波动率等高级风险收益指标

| 测试用例ID | 测试用例描述 | Given-When-Then格式 | 测试类型 | 优先级 | 测试文件位置 | 实现状态 |
|-----------|-------------|-------------------|---------|--------|-------------|----------|
| TC-FP-013 | 夏普比率计算 | Given 基金收益率和无风险利率<br>When 计算夏普比率<br>Then 返回风险调整后收益指标 | 单元测试 | 高 | `test/features/portfolio/domain/services/portfolio_profit_calculation_engine_test.dart` | ✅ 已实现 |
| TC-FP-014 | 最大回撤计算 | Given 基金净值序列<br>When 计算最大回撤<br>Then 返回最大跌幅和回撤期间 | 单元测试 | 高 | `test/features/portfolio/domain/services/portfolio_profit_calculation_engine_test.dart` | ✅ 已实现 |
| TC-FP-015 | 波动率计算 | Given 基金日收益率数据<br>When 计算年化波动率<br>Then 返回收益波动性指标 | 单元测试 | 中 | `test/features/portfolio/domain/services/portfolio_profit_calculation_engine_test.dart` | ✅ 已实现 |

#### AC-006: 同类排名
**验收标准**: 支持获取基金在同类产品中的排名表现

| 测试用例ID | 测试用例描述 | Given-When-Then格式 | 测试类型 | 优先级 | 测试文件位置 | 实现状态 |
|-----------|-------------|-------------------|---------|--------|-------------|----------|
| TC-FP-016 | 同类排名数据获取 | Given 基金代码<br>When 获取同类排名数据<br>Then 返回排名和百分比信息 | 集成测试 | 中 | `test/features/portfolio/data/services/portfolio_profit_api_service_test.dart` | ✅ 已实现 |
| TC-FP-017 | 同类平均收益对比 | Given 基金和同类平均数据<br>When 计算相对表现<br>Then 返回相对同类平均的超额收益 | 单元测试 | 中 | `test/features/portfolio/domain/services/portfolio_profit_calculation_engine_test.dart` | ✅ 已实现 |

#### AC-007 到 AC-012: 基金管理功能
**验收标准**: 基金收藏、管理、快速访问、批量操作、搜索筛选、数据同步

| 测试用例ID | 测试用例描述 | Given-When-Then格式 | 测试类型 | 优先级 | 测试文件位置 | 实现状态 |
|-----------|-------------|-------------------|---------|--------|-------------|----------|
| TC-FM-001 | 添加自选基金 | Given 用户浏览基金列表<br>When 点击添加到自选<br>Then 基金被添加到自选列表 | 单元测试 | 高 | `test/features/fund/domain/services/fund_favorite_service_test.dart` | ⏳ 待实现 |
| TC-FM-002 | 删除自选基金 | Given 用户自选基金列表<br>When 删除自选基金<br>Then 基金从列表中移除 | 单元测试 | 高 | `test/features/fund/domain/services/fund_favorite_service_test.dart` | ⏳ 待实现 |
| TC-FM-003 | 批量操作自选基金 | Given 多个基金选中状态<br>When 执行批量添加/删除<br>Then 所有选中基金被正确处理 | 集成测试 | 中 | `test/features/fund/presentation/cubit/fund_favorite_cubit_test.dart` | ⏳ 待实现 |
| TC-FM-004 | 自选基金搜索筛选 | Given 自选基金列表<br>When 输入搜索关键词<br>Then 返回匹配的筛选结果 | 单元测试 | 中 | `test/features/fund/presentation/widgets/fund_search_and_add_test.dart` | ⏳ 待实现 |
| TC-FM-005 | 自选基金数据同步 | Given 自选基金和持仓数据<br>When 数据更新时<br>Then 保持数据一致性 | 集成测试 | 高 | `test/features/fund/data/repositories/fund_favorite_repository_impl_test.dart` | ⏳ 待实现 |

---

### 集成需求 (Integration Requirements)

#### AC-013 到 AC-018: 持仓分析集成
**验收标准**: 持仓分析页面集成、用户持仓数据处理、API服务扩展等

| 测试用例ID | 测试用例描述 | Given-When-Then格式 | 测试类型 | 优先级 | 测试文件位置 | 实现状态 |
|-----------|-------------|-------------------|---------|--------|-------------|----------|
| TC-IN-001 | 持仓分析页面集成 | Given 持仓分析页面加载<br>When 收益计算完成<br>Then 收益分析模块显示正确数据 | 集成测试 | 高 | `test/features/portfolio/presentation/pages/portfolio_analysis_page_test.dart` | ✅ 已实现 |
| TC-IN-002 | 用户持仓数据计算 | Given 用户实际持仓数据<br>When 计算真实收益率<br>Then 返回基于持仓金额的盈亏情况 | 单元测试 | 高 | `test/features/portfolio/domain/services/portfolio_profit_calculation_engine_test.dart` | ✅ 已实现 |
| TC-IN-003 | API服务扩展 | Given 基金代码和时间参数<br>When 调用历史净值API<br>Then 返回完整的历史数据 | 集成测试 | 高 | `test/features/portfolio/data/services/portfolio_profit_api_service_test.dart` | ✅ 已实现 |
| TC-IN-004 | 缓存策略集成 | Given 收益计算结果<br>When 存储到缓存<br>Then 后续查询从缓存获取数据 | 单元测试 | 中 | `test/features/portfolio/data/repositories/portfolio_profit_repository_impl_test.dart` | ✅ 已实现 |
| TC-IN-005 | BLoC状态管理 | Given PortfolioAnalysisCubit初始化<br>When 触发状态变化<br>Then UI正确响应状态更新 | 单元测试 | 高 | `test/features/portfolio/presentation/cubit/portfolio_analysis_cubit_test.dart` | ✅ 已实现 |
| TC-IN-006 | 基金探索页面集成 | Given 基金探索页面<br>When 添加自选基金<br>Then 数据同步到持仓分析 | 集成测试 | 中 | `test/features/fund/presentation/pages/fund_exploration_page_test.dart` | ⏳ 待实现 |

---

### 质量需求 (Quality Requirements)

#### AC-014 到 AC-030: 性能、准确性、用户体验等质量标准

| 测试用例ID | 测试用例描述 | Given-When-Then格式 | 测试类型 | 优先级 | 测试文件位置 | 实现状态 |
|-----------|-------------|-------------------|---------|--------|-------------|----------|
| TC-QA-001 | 计算准确性验证 | Given 已知输入和预期输出<br>When 执行收益计算<br>Then 误差率≤0.01% | 单元测试 | 高 | `test/features/portfolio/domain/services/portfolio_profit_calculation_engine_precision_test.dart` | ✅ 已实现 |
| TC-QA-002 | 性能要求验证 | Given 复杂持仓数据<br>When 执行批量计算<br>Then 响应时间≤2秒 | 性能测试 | 高 | `test/features/portfolio/performance/portfolio_calculation_performance_test.dart` | ⏳ 待实现 |
| TC-QA-003 | 数据完整性处理 | Given 缺失或异常数据<br>When 执行计算<br>Then 优雅处理异常情况 | 单元测试 | 中 | `test/features/portfolio/domain/services/portfolio_profit_calculation_engine_robustness_test.dart` | ✅ 已实现 |
| TC-QA-004 | 测试覆盖率验证 | Given 所有源代码文件<br>When 执行测试覆盖率分析<br>Then 覆盖率≥90% | 测试工具 | 高 | `test/coverage_test.dart` | ⏳ 待实现 |
| TC-QA-005 | 用户体验流畅性 | Given 收益分析界面<br>When 切换时间周期<br>Then 界面响应流畅无卡顿 | UI测试 | 中 | `test/features/portfolio/presentation/widgets/portfolio_profit_analysis_widget_test.dart` | ⏳ 待实现 |
| TC-QA-006 | 响应式布局验证 | Given 不同屏幕尺寸<br>When 渲染收益分析界面<br>Then 布局正确适配所有设备 | UI测试 | 中 | `test/features/portfolio/presentation/widgets/responsive_layout_test.dart` | ⏳ 待实现 |
| TC-QA-007 | 加载状态处理 | Given 数据加载过程<br>When 显示加载动画<br>Then 用户体验流畅 | UI测试 | 中 | `test/features/portfolio/presentation/cubit/portfolio_analysis_cubit_test.dart` | ✅ 已实现 |
| TC-QA-008 | 数据同步一致性 | Given 实时数据更新<br>When 净值数据变化<br>Then 时间戳正确对齐 | 集成测试 | 高 | `test/features/portfolio/data/services/portfolio_profit_api_service_test.dart` | ✅ 已实现 |
| TC-QA-009 | 隐私安全保护 | Given 敏感金融数据<br>When 存储到本地<br>Then 数据被加密存储 | 安全测试 | 高 | `test/features/portfolio/security/encrypted_storage_test.dart` | ⏳ 待实现 |
| TC-QA-010 | 错误恢复机制 | Given 网络异常或API错误<br>When 发生错误<br>Then 智能重试或降级处理 | 集成测试 | 高 | `test/features/portfolio/data/repositories/portfolio_profit_repository_impl_test.dart` | ✅ 已实现 |
| TC-QA-011 | 基金管理性能 | Given 大量自选基金数据<br>When 加载自选基金列表<br>Then 加载时间≤1秒 | 性能测试 | 中 | `test/features/fund/performance/fund_favorite_performance_test.dart` | ⏳ 待实现 |
| TC-QA-012 | 数据持久化可靠性 | Given 自选基金数据<br>When 存储到本地数据库<br>Then 可靠性≥99.9% | 集成测试 | 高 | `test/features/fund/data/repositories/fund_favorite_repository_impl_test.dart` | ⏳ 待实现 |
| TC-QA-013 | 批量操作效率 | Given 批量基金操作<br>When 执行添加/删除<br>Then 响应时间≤2秒 | 性能测试 | 中 | `test/features/fund/presentation/cubit/fund_favorite_cubit_test.dart` | ⏳ 待实现 |

---

## 测试实现状态汇总

### 已实现测试用例 (13/30)
- **功能需求测试**: 17个测试用例已实现
- **集成需求测试**: 6个测试用例已实现
- **质量需求测试**: 6个测试用例已实现

### 待实现测试用例 (17/30)
- **基金管理功能**: 5个测试用例待实现
- **性能测试**: 4个测试用例待实现
- **UI测试**: 3个测试用例待实现
- **安全测试**: 1个测试用例待实现
- **集成测试**: 4个测试用例待实现

---

## 测试覆盖率分析

### 当前覆盖率状态
- **Portfolio模块**: 约85%覆盖率
- **Fund模块**: 约40%覆盖率 (基金管理功能待开发)
- **整体项目**: 约75%覆盖率

### 覆盖率提升计划
1. **完成基金管理功能开发** → 提升整体覆盖率至85%
2. **添加性能和安全测试** → 提升整体覆盖率至90%
3. **完善UI和集成测试** → 达到90%+覆盖率目标

---

## 边界条件和异常情况测试

### 已覆盖的边界条件
1. **极端收益率数据**: 正常处理异常高/低收益率
2. **数据缺失场景**: 优雅处理历史数据不完整
3. **网络异常情况**: 实现重试和降级机制
4. **内存限制场景**: 优化大量数据处理

### 待补充的边界条件
1. **设备兼容性**: 不同设备性能下的表现
2. **网络环境变化**: 弱网环境下的功能表现
3. **并发操作**: 多用户同时操作的稳定性

---

## 测试执行计划

### Phase 1: 完成已实现测试的验证 (当前阶段)
- [x] 验证所有已实现测试用例通过
- [x] 确保计算引擎准确性达到要求
- [x] 验证API集成和数据流完整性

### Phase 2: 基金管理功能测试实现
- [ ] 实现自选基金CRUD操作测试
- [ ] 实现数据持久化和同步测试
- [ ] 实现搜索和批量操作测试

### Phase 3: 性能和安全测试
- [ ] 实现计算性能基准测试
- [ ] 实现数据加密和安全传输测试
- [ ] 实现内存使用优化验证

### Phase 4: UI和用户体验测试
- [ ] 实现响应式布局测试
- [ ] 实现交互流程自动化测试
- [ ] 实现跨平台兼容性测试

---

## 风险评估和缓解措施

### 高风险项目
1. **计算精度要求**: 误差率≤0.01%
   - **缓解措施**: 使用Decimal类型高精度计算
   - **验证方法**: 精度测试用例TC-QA-001

2. **性能要求**: 响应时间≤2秒
   - **缓解措施**: 多级缓存和异步处理
   - **验证方法**: 性能测试用例TC-QA-002

3. **数据一致性**: 多数据源同步
   - **缓解措施**: 时间戳对齐和版本控制
   - **验证方法**: 集成测试用例TC-QA-008

### 中风险项目
1. **跨平台兼容性**
   - **缓解措施**: 响应式设计和平台适配
   - **验证方法**: UI测试用例TC-QA-006

2. **网络异常处理**
   - **缓解措施**: 重试机制和离线模式
   - **验证方法**: 错误恢复测试用例TC-QA-010

---

## 总结

### 完成度评估
- **需求覆盖**: 100% (30个验收标准全部映射)
- **测试实现**: 43% (13个测试用例已实现)
- **质量保证**: 部分完成 (核心功能已验证)

### 下一步行动
1. **优先完成基金管理功能开发** (Task 8-10)
2. **实现性能优化和测试** (Task 6)
3. **集成UI组件和用户体验测试** (Task 5)
4. **执行完整的回归测试** (Task 7)

### 成功标准
- 所有验收标准100%满足
- 测试覆盖率达到90%以上
- 性能指标全部达标
- 用户体验流畅可用

---

*文档最后更新: 2025-10-19*
*负责人: 开发团队*
*审核状态: 待审核*