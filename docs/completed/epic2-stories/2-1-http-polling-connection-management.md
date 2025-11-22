# Story 2.1: HTTP轮询数据连接管理

Status: drafted

## Story

As a 专业投资者,
I want 稳定的准实时数据轮询连接,
so that 我能够获得及时的市场数据和基金净值更新,同时保持与现有HTTP架构的完全兼容.

## Acceptance Criteria

1. **AC1**: 建立稳定的HTTP轮询机制，支持智能频率调整
2. **AC2**: 实现轮询状态的实时监控和可视化指示
3. **AC3**: 网络异常时自动延长轮询间隔，恢复后恢复正常频率
4. **AC4**: 轮询恢复后自动同步断线期间的数据
5. **AC5**: 支持轮询参数配置(轮询间隔、重试次数、超时时间等)
6. **AC6**: 实现智能轮询频率调整，基于数据变化活跃度
7. **AC7**: 提供轮询质量监控和性能指标

### Integration Verification

- **IV1**: 与现有Dio网络层无缝集成，不冲突现有API调用
- **IV2**: 实时数据缓存到现有Hive系统，保持数据一致性
- **IV3**: 轮询断开时，现有HTTP API功能正常工作
- **IV4**: 连接状态与全局状态管理器同步

## Tasks / Subtasks

### 核心轮询管理
- [ ] **Task 1**: 实现HTTP轮询管理器 (AC: 1, 5, 6)
  - [ ] Subtask 1.1: 创建PollingManager类，封装轮询逻辑
  - [ ] Subtask 1.2: 实现智能频率调整算法
  - [ ] Subtask 1.3: 添加轮询参数配置支持(轮询间隔、重试次数)
  - [ ] Subtask 1.4: 实现基于数据活跃度的智能调整

### 轮询状态监控
- [ ] **Task 2**: 实现轮询状态监控系统 (AC: 2, 7)
  - [ ] Subtask 2.1: 创建PollingStatusCubit管理轮询状态
  - [ ] Subtask 2.2: 实现轮询状态可视化指示器组件
  - [ ] Subtask 2.3: 添加轮询质量监控(延迟、成功率等)
  - [ ] Subtask 2.4: 实现轮询性能指标收集和展示

### 网络异常处理
- [ ] **Task 3**: 实现网络异常处理机制 (AC: 3, 4)
  - [ ] Subtask 3.1: 创建网络状态检测服务
  - [ ] Subtask 3.2: 实现网络异常时自动延长轮询间隔
  - [ ] Subtask 3.3: 添加断线期间数据缓存和恢复机制
  - [ ] Subtask 3.4: 实现数据同步的一致性保证

### 状态管理集成
- [ ] **Task 4**: 集成到现有状态管理系统 (IV: 4)
  - [ ] Subtask 4.1: 扩展PollingDataCubit支持HTTP轮询状态
  - [ ] Subtask 4.2: 实现轮询状态与全局状态管理器的同步
  - [ ] Subtask 4.3: 添加轮询数据状态变化的UI响应机制

### 网络层集成
- [ ] **Task 5**: 与现有Dio网络层集成 (IV: 1, 3)
  - [ ] Subtask 5.1: 确保HTTP轮询不与现有HTTP API冲突
  - [ ] Subtask 5.2: 实现轮询断开时的HTTP API降级保证
  - [ ] Subtask 5.3: 添加网络层统一的错误处理机制

### 缓存系统集成
- [ ] **Task 6**: 集成到现有Hive缓存系统 (IV: 2)
  - [ ] Subtask 6.1: 实现轮询数据到Hive缓存的存储逻辑
  - [ ] Subtask 6.2: 确保轮询数据与缓存数据的一致性
  - [ ] Subtask 6.3: 实现缓存数据的轮询更新策略

### 测试和质量保证
- [ ] **Task 7**: 实现完整的测试覆盖
  - [ ] Subtask 7.1: 编写HTTP轮询管理的单元测试
  - [ ] Subtask 7.2: 创建轮询状态监控的集成测试
  - [ ] Subtask 7.3: 实现网络异常处理的端到端测试
  - [ ] Subtask 7.4: 添加网络异常场景的压力测试

## Dev Notes

### 技术架构要点
- 基于现有Dio 5.3.0实现HTTP轮询，保持架构一致性
- 集成到现有的轮询数据Cubit状态管理模式
- 采用智能频率调整算法处理轮询优化
- 实现金融级的数据一致性保证

### 约束和集成要求
- 必须与现有Dio网络层完全兼容
- 不能影响现有HTTP API功能的正常使用
- 需要保持与三级缓存系统的数据一致性
- 必须支持Windows桌面应用的性能要求

### 性能考虑
- 轮询频率控制(默认30秒，可调整范围15-300秒)
- 智能频率调整(基于数据变化活跃度)
- 内存使用控制(轮询数据缓存不应超过50MB)
- CPU使用优化(后台线程处理轮询管理)

### Project Structure Notes

#### 新增文件路径
```
lib/src/core/network/polling/
├── polling_manager.dart                # HTTP轮询管理器
├── polling_scheduler.dart               # 轮询调度器
├── network_monitor.dart                 # 网络状态监控
└── polling_sync_service.dart            # 轮询数据同步服务

lib/src/core/state/
└── polling_status_cubit.dart            # 轮询状态管理

lib/src/features/fund/data/repositories/
└── polling_data_repository_impl.dart     # 轮询数据仓库实现

test/unit/core/network/polling/
├── polling_manager_test.dart
├── polling_scheduler_test.dart
└── network_monitor_test.dart

test/integration/
└── polling_data_integration_test.dart
```

#### 现有文件修改
```
lib/src/core/state/global_cubit_manager.dart     # 添加轮询状态管理
lib/src/features/fund/presentation/cubits/
└── polling_data_cubit.dart                     # 扩展支持HTTP轮询
lib/src/core/di/service_locator.dart             # 注册新的轮询数据服务
lib/src/core/network/fund_api_client.dart         # 扩展支持轮询配置
```

### References

- [Source: docs/epics/epic-2-quasi-realtime-market-data-system.md#Story-21-HTTP轮询数据连接管理]
- [Source: docs/architecture.md#实时数据架构]
- [Source: docs/architecture.md#技术栈详情]
- [Source: docs/architecture.md#集成要点]
- [Source: docs/architecture.md#数据持久化]

### 从前一个Epic的学习

**Epic 1完成状态**: 已完成
- **UI组件模式**: AdaptiveFundCard和MicrointeractiveFundCard已建立，可复用动画和状态管理模式
- **状态管理集成**: GlobalCubitManager已验证，可直接集成轮询状态管理
- **网络层架构**: Dio网络层已稳定，可安全添加轮询功能而不影响现有API
- **缓存系统**: Hive三级缓存已验证，轮询数据可直接复用现有缓存策略

## Dev Agent Record

### Context Reference

<!-- Path(s) to story context XML will be added here by context workflow -->

### Agent Model Used

Claude Sonnet 4.5 (model ID: 'claude-sonnet-4-5-20250929')

### Debug Log References

### Completion Notes List

### File List

#### New Files Created

#### Modified Files

## Change Log

- 2025-11-07: Initial story creation for HTTP polling connection management (redesigned from WebSocket)
- 2025-11-07: Extracted requirements from Epic 2 documentation (HTTP polling strategy)
- 2025-11-07: Aligned with existing architecture and technology stack (Dio + BLoC)
- 2025-11-07: Based on HTTP polling strategy instead of WebSocket (architecture consistency)
- 2025-11-07: Integrated learning from Epic 1 completion for UI and state management patterns