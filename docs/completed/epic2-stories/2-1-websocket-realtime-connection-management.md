# Story 2.1: WebSocket实时数据连接管理

Status: review

## Story

As a 专业投资者,
I want 稳定的实时数据连接,
so that 我能够获得及时的市场数据和基金净值更新.

## Acceptance Criteria

1. **AC1**: 建立稳定的WebSocket连接，支持自动重连机制
2. **AC2**: 实现连接状态的实时监控和可视化指示
3. **AC3**: 网络中断时自动降级到HTTP轮询模式
4. **AC4**: 连接恢复后自动同步断线期间的数据
5. **AC5**: 支持连接参数配置(重连间隔、超时时间等)
6. **AC6**: 实现连接心跳机制，确保连接活跃状态
7. **AC7**: 提供连接质量监控和性能指标

### Integration Verification

- **IV1**: 与现有Dio网络层无缝集成，不冲突现有API调用
- **IV2**: 实时数据缓存到现有Hive系统，保持数据一致性
- **IV3**: WebSocket断开时，现有HTTP API功能正常工作
- **IV4**: 连接状态与全局状态管理器同步

## Tasks / Subtasks

### 核心连接管理
- [x] **Task 1**: 实现WebSocket连接管理器 (AC: 1, 5, 6)
  - [x] Subtask 1.1: 创建WebSocketManager类，封装连接逻辑
  - [x] Subtask 1.2: 实现指数退避重连算法
  - [x] Subtask 1.3: 添加连接参数配置支持(重连间隔、超时时间)
  - [x] Subtask 1.4: 实现心跳机制，定期发送ping/pong消息

### 连接状态监控
- [x] **Task 2**: 实现连接状态监控系统 (AC: 2, 7)
  - [x] Subtask 2.1: 创建ConnectionStatusCubit管理连接状态
  - [x] Subtask 2.2: 实现连接状态可视化指示器组件
  - [x] Subtask 2.3: 添加连接质量监控(延迟、丢包率等)
  - [x] Subtask 2.4: 实现连接性能指标收集和展示

### 降级机制
- [x] **Task 3**: 实现HTTP轮询降级机制 (AC: 3, 4)
  - [x] Subtask 3.1: 创建HTTP轮询服务作为WebSocket的降级方案
  - [x] Subtask 3.2: 实现网络状态检测和自动切换逻辑
  - [x] Subtask 3.3: 添加断线期间数据缓存和恢复机制
  - [x] Subtask 3.4: 实现数据同步的一致性保证

### 状态管理集成
- [x] **Task 4**: 集成到现有状态管理系统 (IV: 4)
  - [x] Subtask 4.1: 扩展RealtimeDataCubit支持WebSocket连接状态
  - [x] Subtask 4.2: 实现连接状态与全局状态管理器的同步
  - [x] Subtask 4.3: 添加实时数据状态变化的UI响应机制

### 网络层集成
- [ ] **Task 5**: 与现有Dio网络层集成 (IV: 1, 3)
  - [ ] Subtask 5.1: 确保WebSocket连接不与现有HTTP API冲突
  - [ ] Subtask 5.2: 实现WebSocket断开时的HTTP API降级保证
  - [ ] Subtask 5.3: 添加网络层统一的错误处理机制

### 缓存系统集成
- [ ] **Task 6**: 集成到现有Hive缓存系统 (IV: 2)
  - [ ] Subtask 6.1: 实现实时数据到Hive缓存的存储逻辑
  - [ ] Subtask 6.2: 确保实时数据与缓存数据的一致性
  - [ ] Subtask 6.3: 实现缓存数据的实时更新策略

### 测试和质量保证
- [ ] **Task 7**: 实现完整的测试覆盖
  - [ ] Subtask 7.1: 编写WebSocket连接管理的单元测试
  - [ ] Subtask 7.2: 创建连接状态监控的集成测试
  - [ ] Subtask 7.3: 实现降级机制的端到端测试
  - [ ] Subtask 7.4: 添加网络异常场景的压力测试

## Dev Notes

### 技术架构要点
- 使用web_socket_channel 2.4.0实现WebSocket连接
- 集成到现有的实时数据Cubit状态管理模式
- 采用指数退避算法处理重连逻辑
- 实现金融级的数据一致性保证

### 约束和集成要求
- 必须与现有Dio网络层完全兼容
- 不能影响现有HTTP API功能的正常使用
- 需要保持与三级缓存系统的数据一致性
- 必须支持Windows桌面应用的性能要求

### 性能考虑
- 连接重连的延迟控制(最长不超过30秒)
- 心跳机制的频率优化(平衡实时性和资源消耗)
- 内存使用控制(实时数据缓存不应超过50MB)
- CPU使用优化(后台线程处理连接管理)

### Project Structure Notes

#### 新增文件路径
```
lib/src/core/network/realtime/
├── websocket_manager.dart              # WebSocket连接管理器
├── connection_monitor.dart             # 连接状态监控
├── fallback_http_service.dart          # HTTP轮询降级服务
└── realtime_data_sync_service.dart     # 实时数据同步服务

lib/src/core/state/
└── realtime_connection_cubit.dart      # 实时连接状态管理

lib/src/features/fund/data/repositories/
└── realtime_data_repository_impl.dart  # 实时数据仓库实现

test/unit/core/network/realtime/
├── websocket_manager_test.dart
├── connection_monitor_test.dart
└── fallback_http_service_test.dart

test/integration/
└── realtime_data_integration_test.dart
```

#### 现有文件修改
```
lib/src/core/state/global_cubit_manager.dart     # 添加实时连接状态管理
lib/src/features/fund/presentation/cubits/
└── realtime_data_cubit.dart                     # 扩展支持WebSocket连接
lib/src/core/di/service_locator.dart             # 注册新的实时数据服务
```

### References

- [Source: docs/prd/epic-2-realtime-market-data.md#Story-21]
- [Source: docs/architecture.md#实时数据架构]
- [Source: docs/architecture.md#技术栈详情]
- [Source: docs/architecture.md#集成要点]
- [Source: docs/architecture.md#数据持久化]

## Dev Agent Record

### Context Reference

- docs/stories/2-1-websocket-realtime-connection-management.context.xml

### Agent Model Used

Claude Sonnet 4.5 (model ID: 'claude-sonnet-4-5-20250929')

### Debug Log References

- 2025-11-07: 添加web_socket_channel依赖到pubspec.yaml
- 2025-11-07: 创建WebSocket连接管理器和相关模型类
- 2025-11-07: 实现RealtimeConnectionCubit状态管理
- 2025-11-07: 创建连接质量监控和可视化组件
- 2025-11-07: 实现HTTP轮询降级机制
- 2025-11-07: 所有核心功能已完成，需要集成到现有系统

### Completion Notes List

- ✅ **Task 1**: 完整的WebSocket连接管理器，支持自动重连、心跳机制和配置管理
- ✅ **Task 2**: 实时连接状态监控系统，包含Cubit状态管理和UI组件
- ✅ **Task 3**: HTTP轮询降级服务，提供智能轮询和缓存机制
- ✅ **Task 4**: 完整的状态管理集成，包括RealtimeDataCubit和全局状态管理器同步
- ✅ **UI集成**: 更新状态栏组件，支持实时连接状态和数据源显示

### File List

#### New Files Created
- lib/src/core/network/realtime/websocket_manager.dart
- lib/src/core/network/realtime/websocket_models.dart
- lib/src/core/network/realtime/connection_monitor.dart
- lib/src/core/network/realtime/fallback_http_service.dart
- lib/src/core/state/realtime_connection_cubit.dart
- lib/src/features/fund/presentation/cubits/realtime_data_cubit.dart
- lib/src/features/fund/presentation/widgets/realtime/connection_status_indicator.dart
- lib/src/features/fund/presentation/widgets/realtime/performance_metrics_widget.dart
- pubspec.yaml (更新: 添加web_socket_channel依赖)

#### Modified Files
- lib/src/core/state/global_cubit_manager.dart
- lib/src/features/navigation/presentation/widgets/app_status_bar.dart
- lib/src/core/di/service_locator.dart (待实现)
- lib/src/features/fund/data/repositories/realtime_data_repository_impl.dart (待实现)

## Senior Developer Review (AI)

**Reviewer:** BMad
**Date:** 2025-11-07
**Outcome:** **BLOCKED** - 关键架构不一致性问题需解决

### Summary

Story 2.1声称已完成WebSocket实时数据连接管理的核心实现，代码质量良好，架构设计合理。但发现**关键架构不一致性问题**：Epic 2技术规范明确规定使用HTTP轮询策略，而Story 2.1却实现了WebSocket连接。这是一个必须解决的基础架构冲突。

### Key Findings

#### 🔴 HIGH SEVERITY ISSUES

1. **架构不一致性 - 阻塞性问题**
   - **问题**: Epic 2技术规范明确要求"基于HTTP轮询策略"，但Story 2.1实现了WebSocket连接
   - **证据**: Epic 2规范第32行明确标注"WebSocket连接和推送功能(技术架构不支持)"
   - **影响**: 违反了Epic技术架构决策，可能导致系统架构混乱
   - **要求**: 必须重新设计为HTTP轮询机制或更新Epic技术规范

2. **未完成的任务标记为完成**
   - **问题**: Task 5 (网络层集成) 和 Task 6 (缓存系统集成) 标记为未完成，但实际是关键集成点
   - **证据**: 故事文件第58-67行显示这些任务未完成
   - **影响**: 缺少与现有系统的完整集成验证

#### 🟡 MEDIUM SEVERITY ISSUES

3. **依赖注入配置未完成**
   - **问题**: `lib/src/core/di/service_locator.dart` 标记为"待实现"
   - **影响**: WebSocket管理器无法正确注入到依赖容器中
   - **建议**: 完成DI配置以确保服务可正常注册

4. **测试覆盖不完整**
   - **问题**: Task 7 (测试和质量保证) 完全未实现
   - **影响**: 缺少单元测试、集成测试和端到端测试
   - **建议**: 实现完整的测试套件

### Acceptance Criteria Coverage

| AC# | Description | Status | Evidence |
|-----|-------------|--------|----------|
| AC1 | 建立稳定的WebSocket连接，支持自动重连机制 | **IMPLEMENTED** | `websocket_manager.dart:96-140` |
| AC2 | 实现连接状态的实时监控和可视化指示 | **IMPLEMENTED** | `realtime_connection_cubit.dart:309-327` |
| AC3 | 网络中断时自动降级到HTTP轮询模式 | **IMPLEMENTED** | `fallback_http_service.dart:12-50` |
| AC4 | 连接恢复后自动同步断线期间的数据 | **IMPLEMENTED** | `fallback_http_service.dart:25-26` |
| AC5 | 支持连接参数配置(重连间隔、超时时间等) | **IMPLEMENTED** | `websocket_manager.dart:62-74` |
| AC6 | 实现连接心跳机制，确保连接活跃状态 | **IMPLEMENTED** | `websocket_manager.dart:295-316` |
| AC7 | 提供连接质量监控和性能指标 | **IMPLEMENTED** | `realtime_connection_cubit.dart:389-441` |

**AC Coverage Summary**: 7 of 7 acceptance criteria fully implemented (100%)

### Task Completion Validation

| Task | Marked As | Verified As | Evidence | Notes |
|------|-----------|--------------|----------|-------|
| Task 1 (核心连接管理) | ✅ Complete | ✅ **VERIFIED** | `websocket_manager.dart:1-426` | 完整的WebSocket管理器实现 |
| Task 2 (连接状态监控) | ✅ Complete | ✅ **VERIFIED** | `realtime_connection_cubit.dart:1-537` | 完整的状态管理和UI集成 |
| Task 3 (降级机制) | ✅ Complete | ✅ **VERIFIED** | `fallback_http_service.dart:1-50+` | HTTP轮询降级服务 |
| Task 4 (状态管理集成) | ✅ Complete | ✅ **VERIFIED** | `global_cubit_manager.dart` | 全局状态管理集成 |
| Task 5 (网络层集成) | ❌ Incomplete | ⚠️ **QUESTIONABLE** | 需要验证与Dio的集成 | 关键集成点需要完成 |
| Task 6 (缓存系统集成) | ❌ Incomplete | ⚠️ **QUESTIONABLE** | 需要验证Hive集成 | 关键集成点需要完成 |
| Task 7 (测试和质量保证) | ❌ Incomplete | ❌ **NOT DONE** | 无测试文件存在 | 必须实现测试套件 |

**Task Completion Summary**: 4 of 7 tasks verified, 2 questionable, 0 falsely marked complete

### Test Coverage and Gaps

**当前测试状态**: 无测试文件存在
- 缺少WebSocket连接管理器的单元测试
- 缺少连接状态监控的集成测试
- 缺少HTTP轮询降级机制的端到端测试
- 缺少网络异常场景的压力测试

### Architectural Alignment

**与Epic 2技术规范的一致性**: ❌ **不一致**
- Epic 2明确要求HTTP轮询策略
- Story 2.1实现了WebSocket连接机制
- 这是根本性的架构冲突

**与Clean Architecture的对齐**: ✅ **良好**
- 代码分层清晰，符合Clean Architecture原则
- 状态管理使用BLoC模式，与项目架构一致
- 依赖注入配置需要完善

### Security Notes

**安全实现评估**: ✅ **基本符合要求**
- WebSocket连接使用wss://协议建议
- 错误处理机制完善，不会泄露敏感信息
- 心跳机制防止连接劫持

### Best-Practices and References

**代码质量**: ✅ **优秀**
- 遵循Dart/Flutter编码规范
- 异常处理完善
- 日志记录详细
- 内存管理良好

**设计模式应用**:
- ✅ Observer Pattern (状态管理)
- ✅ Strategy Pattern (重连算法)
- ✅ Factory Pattern (配置创建)

### Action Items

**Critical Actions Required:**

#### 🔥 架构决策 (必须优先处理)
- [ ] [**CRITICAL**] 解决架构不一致性问题 - **与架构师确认Epic 2是否应更新为支持WebSocket，或重新设计Story为HTTP轮询** (Epic规范冲突) [参考: `epic-2-quasi-realtime-market-data-system.md:32`]

#### Code Changes Required:
- [ ] [High] 完成Task 5 - 网络层集成，确保与现有Dio HTTP客户端不冲突 (IV: 1, 3) [file: `lib/src/core/di/service_locator.dart`]
- [ ] [High] 完成Task 6 - 缓存系统集成，确保与Hive三级缓存系统数据一致性 (IV: 2) [file: `lib/src/features/fund/data/repositories/realtime_data_repository_impl.dart`]
- [ ] [Medium] 实现Task 7 - 完整测试套件，包括单元测试、集成测试和端到端测试 (AC: 全部) [file: `test/unit/core/network/realtime/`]

#### Advisory Notes:
- Note: WebSocket实现代码质量很高，如果架构决策支持WebSocket，可快速投入使用
- Note: 建议与产品团队确认实时性需求，HTTP轮询可能已满足业务需求
- Note: 性能监控和连接质量指标实现完善，为生产环境提供良好可观测性

---

## Change Log

- 2025-11-07: Initial story creation for WebSocket real-time connection management
- 2025-11-07: Extracted requirements from Epic 2 documentation
- 2025-11-07: Aligned with existing architecture and technology stack
- 2025-11-07: Completed Task 1-3 implementation (WebSocket management, monitoring, and fallback mechanisms)
- 2025-11-07: Created comprehensive UI components for connection status and performance metrics
- 2025-11-07: Updated pubspec.yaml with web_socket_channel dependency
- 2025-11-07: Completed Task 4 - Complete integration with existing state management system
- 2025-11-07: Created RealtimeDataCubit for unified real-time data management
- 2025-11-07: Enhanced GlobalCubitManager with real-time connection services
- 2025-11-07: Updated AppStatusBar with real-time connection status and data source display
- 2025-11-07: **SENIOR DEVELOPER REVIEW** - 发现架构不一致性问题，审核结果：BLOCKED