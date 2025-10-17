# 技术栈详细说明

## 1. 前端核心技术

### 1.1 Flutter框架
- **版本**: 3.13+
- **选择理由**:
  - 跨平台一致性，单代码库支持Web/移动端/桌面端
  - 高性能渲染引擎，媲美原生应用的性能表现
  - 丰富的UI组件库和Material Design支持
  - 强大的开发工具和调试能力
- **应用场景**: 整个应用UI层构建
- **替代方案**: React Native, Xamarin

### 1.2 状态管理 - flutter_bloc
- **版本**: 9.1.1
- **核心概念**:
  - Event: 用户交互和系统事件
  - State: 应用状态快照
  - BLoC: 业务逻辑组件，处理事件并生成状态
- **优势**:
  - 可预测的状态管理
  - 优秀的测试支持
  - 清晰的代码分离
  - 强大的调试工具
- **使用模式**: 每个功能模块独立BLoC管理

### 1.3 网络通信 - Dio + Retrofit
- **Dio版本**: 5.3.0
- **Retrofit版本**: 4.0.3
- **功能特性**:
  - 拦截器支持（日志、缓存、认证）
  - 请求/响应转换器
  - 全局配置和错误处理
  - 文件上传下载
  - 网络状态监听
- **配置示例**:
```dart
final dio = Dio()
  ..options.baseUrl = 'http://154.44.25.92:8080'
  ..options.connectTimeout = const Duration(seconds: 5)
  ..options.receiveTimeout = const Duration(seconds: 10)
  ..interceptors.add(LogInterceptor());
```

## 2. 数据存储技术

### 2.1 本地缓存 - Hive
- **版本**: 2.2.3
- **技术特点**:
  - 纯Dart实现，无原生依赖
  - 高性能键值存储
  - 支持复杂数据类型
  - 自动加密支持
  - 小内存占用
- **使用场景**:
  - 基金基础信息缓存
  - 用户偏好设置
  - 应用状态持久化
  - 临时数据存储

### 2.2 轻量存储 - shared_preferences
- **版本**: 2.2.2
- **适用数据**:
  - 简单配置项
  - 用户登录状态
  - 主题偏好
  - 功能开关
- **与Hive分工**: 简单数据用shared_preferences，复杂对象用Hive

### 2.3 数据库连接
- **SQL Server**: sql_conn 0.0.3
  - 企业级数据分析
  - 复杂查询支持
  - 事务处理
- **PostgreSQL**: postgres 2.6.1
  - 开源关系数据库
  - JSON数据支持
  - 地理信息扩展

## 3. 可视化技术

### 3.1 图表库 - fl_chart
- **版本**: 0.55.2
- **支持的图表类型**:
  - 折线图（基金净值走势）
  - 柱状图（收益对比）
  - 饼图（资产配置）
  - 散点图（风险收益分析）
  - 雷达图（多维度评估）
- **交互特性**:
  - 触摸事件处理
  - 数据点提示
  - 缩放和平移
  - 动画效果

### 3.2 动画效果
- **flutter_animate**: 4.1.0
  - 声明式动画定义
  - 丰富的动画效果库
  - 性能优化
- **animations**: 2.0.8
  - Material Design动画
  - 页面转场效果
  - 微交互设计

## 4. UI增强技术

### 4.1 字体系统 - google_fonts
- **版本**: 6.1.0
- **优势**:
  - 丰富的字体选择
  - 自动字体加载
  - 字体缓存优化
  - 多语言支持
- **金融应用适用性**:
  - 清晰的数据展示
  - 专业的视觉感受
  - 良好的可读性

### 4.2 图标系统 - cupertino_icons
- **版本**: 1.0.6
- **特点**:
  - iOS风格图标
  - 矢量图标支持
  - 一致性设计

### 4.3 加载效果 - shimmer
- **版本**: 3.0.0
- **用途**:
  - 数据加载占位符
  - 提升用户体验
  - 减少感知等待时间

## 5. 工具类库

### 5.1 依赖注入 - get_it
- **版本**: 8.2.0
- **核心功能**:
  - 服务定位器模式
  - 工厂函数注册
  - 单例管理
  - 异步初始化
  - 依赖作用域
- **使用示例**:
```dart
// 注册服务
getIt.registerSingleton<ApiService>(ApiService());
getIt.registerFactory<FundRepository>(() => FundRepositoryImpl());

// 获取服务
final apiService = getIt<ApiService>();
```

### 5.2 国际化 - intl
- **版本**: 0.18.1 (重载至0.20.2)
- **功能**:
  - 多语言支持
  - 日期时间格式化
  - 数字货币格式化
  - 消息复数处理

### 5.3 日志系统 - logger
- **版本**: 2.0.2+1
- **特性**:
  - 分级日志（debug, info, warning, error）
  - 彩色控制台输出
  - 日志过滤
  - 自定义输出格式
  - 文件日志支持

### 5.4 路径管理 - path + path_provider
- **path版本**: 1.8.3
- **path_provider版本**: 2.1.1
- **用途**:
  - 跨平台路径处理
  - 应用文档目录访问
  - 临时文件管理

## 6. 代码生成工具

### 6.1 构建运行器 - build_runner
- **版本**: 2.4.0
- **配合使用的生成器**:
  - json_serializable: JSON序列化
  - retrofit_generator: API接口生成
  - hive_generator: Hive类型适配

### 6.2 JSON序列化 - json_annotation
- **版本**: 4.8.1
- **使用方式**:
```dart
@JsonSerializable()
class Fund {
  final String code;
  final String name;
  final double nav;

  Fund({required this.code, required this.name, required this.nav});
  factory Fund.fromJson(Map<String, dynamic> json) => _$FundFromJson(json);
  Map<String, dynamic> toJson() => _$FundToJson(this);
}
```

## 7. 开发工具

### 7.1 代码质量
- **flutter_lints**: 4.0.0
  - Flutter官方lint规则
  - 代码风格统一
  - 潜在问题检测

### 7.2 测试框架
- **flutter_test**: SDK内置
  - 单元测试
  - 组件测试
  - 集成测试

## 8. 技术选型对比

### 8.1 状态管理方案对比
| 方案 | 学习成本 | 性能 | 测试性 | 适用场景 |
|------|----------|------|--------|----------|
| BLoC | 中 | 高 | 优秀 | 复杂业务逻辑 |
| Provider | 低 | 中 | 良好 | 中小型应用 |
| Riverpod | 中 | 高 | 优秀 | 现代化新应用 |
| Redux | 高 | 中 | 优秀 | 复杂状态管理 |

**选择BLoC的理由**: 在复杂性和性能之间取得平衡，团队熟悉度高。

### 8.2 存储方案对比
| 方案 | 性能 | 数据类型 | 查询能力 | 适用场景 |
|------|------|----------|----------|----------|
| Hive | 极高 | 键值/对象 | 基础 | 配置/缓存数据 |
| SQLite | 高 | 关系型 | 强大 | 复杂关系数据 |
| shared_preferences | 中 | 简单类型 | 无 | 应用配置 |
| Sembast | 高 | JSON文档 | 中等 | NoSQL场景 |

**选择Hive的理由**: 性能优秀，使用简单，适合基金数据缓存场景。

### 8.3 网络库对比
| 方案 | 功能丰富度 | 类型安全 | 拦截器 | 代码生成 |
|------|------------|----------|--------|----------|
| Dio | 高 | 手动 | 支持 | 不支持 |
| Retrofit | 中 | 自动 | 配合Dio | 支持 |
| http | 基础 | 手动 | 不支持 | 不支持 |
| chopper | 中 | 自动 | 支持 | 支持 |

**选择Dio+Retrofit的理由**: 功能强大且支持代码生成，提升开发效率。

## 9. 性能基准

### 9.1 框架性能指标
- **Flutter**:
  - 60FPS流畅渲染
  - 内存占用相对原生增加15-20%
  - 应用包大小增加约5-8MB
- **Hive**:
  - 读写性能比SQLite快2-3倍
  - 内存占用仅为SQLite的1/10

### 9.2 应用性能目标
- 页面加载时间: ≤3秒
- 列表滚动: 60FPS
- 内存占用: ≤100MB增量
- 包大小: ≤25MB (Web), ≤15MB (移动端)

## 10. 版本管理策略

### 10.1 依赖版本锁定
- 使用`pubspec.lock`锁定生产环境依赖版本
- 定期更新依赖包，评估兼容性
- 重大版本升级前充分测试

### 10.2 Flutter版本管理
- 使用fvm (Flutter Version Management)管理多版本
- 生产环境使用稳定版本
- 开发环境可试用最新版本

---

**最后更新**: 2025-09-26
**维护者**: 技术架构团队
**审核状态**: 已审核