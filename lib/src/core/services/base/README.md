# 统一服务基础架构

这个目录包含了数据层清理重构的统一服务基础架构组件。

## 📁 文件结构

```
base/
├── README.md                              # 本文档
├── i_unified_service.dart                 # 统一服务基础接口
├── service_lifecycle_manager.dart         # 服务生命周期管理器
├── service_registry.dart                  # 服务注册表和依赖注入
├── service_container.dart                 # 统一服务容器
└── test/                                  # 单元测试
    ├── service_lifecycle_manager_test.dart
    ├── service_registry_test.dart
    └── service_container_test.dart
```

## 🏗️ 核心组件

### IUnifiedService
所有统一服务必须实现的基础接口，定义了：
- 服务生命周期管理 (initialize, dispose)
- 依赖关系声明 (dependencies)
- 健康检查 (checkHealth)
- 统计信息 (getStats)

### ServiceLifecycleManager
负责管理所有服务的生命周期，包括：
- 拓扑排序确保正确的初始化顺序
- 循环依赖检测
- 初始化超时控制
- 优雅的服务关闭

### ServiceRegistry
服务注册和发现机制，支持：
- 单例和工厂模式
- 依赖关系解析
- 类型安全的服务访问
- 服务元数据管理

### UnifiedServiceContainer
统一服务容器，作为服务架构的中央协调器：
- 服务注册和发现
- 生命周期管理
- 依赖注入
- 健康检查和监控
- 配置管理

## 🚀 快速开始

### 创建统一服务

```dart
class MyUnifiedService implements IUnifiedService {
  @override
  String get serviceName => 'MyService';

  @override
  String get version => '1.0.0';

  @override
  List<String> get dependencies => ['OtherService'];

  @override
  Future<void> initialize(ServiceContainer container) async {
    // 服务初始化逻辑
    final otherService = container.getServiceByName('OtherService');
    // ...
  }

  @override
  Future<void> dispose() async {
    // 资源清理逻辑
  }
}
```

### 配置服务容器

```dart
// 使用构建器模式
final container = await ServiceContainerBuilder()
    .withConfig('debug_mode', true)
    .withService(MyService())
    .buildAndInitialize();

// 或者使用工厂方法
final container = await ServiceContainerFactory.createDevelopmentContainer();
```

### 获取服务

```dart
// 类型安全获取
final myService = container.getService<MyService>();

// 按名称获取
final service = container.getServiceByName('MyService');

// 检查服务状态
final state = container.getServiceState('MyService');
```

## 🔧 高级功能

### 服务依赖管理

```dart
class DependentService implements IUnifiedService {
  @override
  List<String> get dependencies => ['Service1', 'Service2'];

  @override
  Future<void> initialize(ServiceContainer container) async {
    // 依赖服务会自动按正确顺序初始化
    final service1 = container.getServiceByName('Service1');
    final service2 = container.getServiceByName('Service2');
  }
}
```

### 健康检查

```dart
final healthReport = await container.getHealthReport();
healthReport.forEach((serviceName, status) {
  print('$serviceName: ${status.isHealthy ? "Healthy" : "Unhealthy"}');
});
```

### 监控服务事件

```dart
container.lifecycleEvents.listen((event) {
  print('服务事件: ${event.type} - ${event.message}');
});
```

## 🧪 测试

基础架构包含全面的单元测试，覆盖：
- 服务注册和发现
- 生命周期管理
- 依赖关系解析
- 错误处理和恢复
- 容器配置和管理

运行测试：
```bash
flutter test test/unit/core/services/base/
```

## 📊 性能特性

- **依赖解析优化**: 使用拓扑排序算法，O(V+E)复杂度
- **内存管理**: 自动服务生命周期管理，防止内存泄漏
- **初始化性能**: 并行初始化独立服务，减少启动时间
- **类型安全**: 编译时类型检查，避免运行时错误

## 🛡️ 安全特性

- **循环依赖检测**: 启动时自动检测和报告循环依赖
- **初始化超时**: 防止服务初始化阻塞应用启动
- **优雅降级**: 部分服务初始化失败时不影响其他服务
- **资源清理**: 自动释放服务资源，防止内存泄漏

## 🔗 集成

### 与现有GetIt集成

```dart
// 初始化服务注入配置
await ServiceInjector.initialize(container);

// 获取服务（从GetIt）
final service = ServiceInjector.getService<MyService>();
```

### 依赖注入配置

```dart
// 配置现有GetIt服务
final builder = ServiceContainerBuilder()
    .withConfig('existing_service_config', true);

await ServiceInjectionConfig().configureExistingServices();
```

## 📋 最佳实践

1. **服务设计原则**
   - 单一职责：每个服务专注于一个特定领域
   - 明确依赖：清楚声明服务依赖关系
   - 无状态：优先设计无状态服务

2. **依赖管理**
   - 最小化依赖：减少不必要的依赖关系
   - 避免循环：使用事件或消息模式替代循环依赖
   - 版本控制：明确声明服务版本兼容性

3. **错误处理**
   - 优雅降级：服务失败时提供降级功能
   - 详细日志：记录初始化和运行时错误
   - 健康检查：定期检查服务健康状态

## 🚧 下一步

基础架构完成后，下一步是实现具体的统一服务：

1. **UnifiedPerformanceService** - 整合性能相关Manager
2. **UnifiedDataService** - 整合数据管理Manager
3. **UnifiedStateService** - 整合状态管理Manager
4. **UnifiedPushService** - 整合推送相关Manager
5. **UnifiedPermissionService** - 整合权限管理Manager
6. **UnifiedNetworkService** - 整合网络连接Manager
7. **UnifiedUIService** - 整合UI相关Manager
8. **UnifiedConfigurationService** - 整合配置管理Manager

## 📈 预期收益

- **代码减少**: 预计减少30%的重复代码
- **内存优化**: 减少约25%的内存使用
- **启动优化**: 提升约30%的启动速度
- **维护性**: 统一接口，简化维护流程
- **可测试性**: 更容易实现单元测试和集成测试