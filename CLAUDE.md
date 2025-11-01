# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

**基速基金量化分析平台** (jisu_fund_analyzer) - 基于 Flutter 开发的专业桌面端基金分析工具，采用 Clean Architecture + BLoC 模式，支持 Windows 桌面应用。

## 开发环境要求

- **Flutter**: 3.13.0 (Channel stable)
- **Dart**: 3.1.0
- **Platform**: Windows (主要支持)
- **IDE**: VS Code / Android Studio / IntelliJ IDEA

## 常用开发命令

### 基础开发命令

```bash
# 检查Flutter环境
flutter doctor

# 获取依赖
flutter pub get

# 运行应用 (Windows桌面)
flutter run -d windows

# 构建Windows发布版
flutter build windows --release

# 静态代码分析
flutter analyze

# 代码格式化
dart format .

# 运行所有测试
flutter test

# 运行特定测试文件
flutter test test/integration/data_layer_optimizer_test.dart

# 运行测试并生成覆盖率报告
flutter test --coverage
```

### 代码生成命令

```bash
# 运行代码生成 (JSON序列化、Hive适配器、Retrofit等)
dart run build_runner build

# 清理并重新生成
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs

# 监听模式自动生成
dart run build_runner watch
```

### 项目清理命令

```bash
# 清理项目缓存
flutter clean

# 清理构建产物
flutter pub cache clean
```

## 项目架构

### 整体架构模式

- **Clean Architecture**: 分层架构，关注点分离
- **BLoC Pattern**: 状态管理，业务逻辑与UI分离
- **Domain-Driven Design**: 领域驱动设计
- **Dependency Injection**: 依赖注入 (get_it)

### 目录结构

```
lib/
├── main.dart                    # 应用入口
└── src/
    ├── core/                    # 核心模块
    │   ├── cache/              # 缓存系统 (Hive + 统一缓存)
    │   ├── database/           # 数据库 (SQL Server支持)
    │   ├── di/                 # 依赖注入容器
    │   ├── error/              # 错误处理
    │   ├── network/            # 网络层 (Dio + Retrofit)
    │   ├── services/           # 核心服务
    │   ├── theme/              # 主题配置
    │   └── utils/              # 工具类
    ├── features/               # 功能模块
    │   ├── auth/               # 认证模块
    │   ├── fund/               # 基金核心功能
    │   ├── portfolio/          # 投资组合
    │   ├── home/               # 主页
    │   ├── market/             # 市场数据
    │   ├── settings/           # 设置
    │   └── navigation/         # 导航
    ├── shared/                 # 共享组件
    │   └── widgets/            # 通用组件
    ├── models/                 # 数据模型
    └── services/               # 业务服务
```

### 核心技术栈

#### 状态管理
- **flutter_bloc**: BLoC状态管理
- **equatable**: 对象相等性比较
- **dartz**: 函数式编程工具

#### 数据持久化
- **hive**: 轻量级NoSQL数据库 (主要缓存)
- **hive_flutter**: Flutter Hive支持
- **shared_preferences**: 简单键值存储
- **sql_conn**: SQL Server数据库支持

#### 网络请求
- **dio**: HTTP客户端 (支持gzip压缩、HTTP/2)
- **retrofit**: 类型安全的API客户端
- **dio_http_cache_lts**: HTTP缓存

#### 高精度计算
- **decimal**: 高精度数值计算 (基金计算必需)

#### UI组件
- **fl_chart**: 图表库
- **google_fonts**: 字体
- **flutter_animate**: 动画效果
- **shimmer**: 加载动画

## API集成规范

### 基金数据API

**主要API端点**: `http://154.44.25.92:8080/`

**API文档参考**: `docs/api/fund_public.md`

**缓存策略**:
1. **高效请求**: 启用gzip压缩，批量拉取数据
2. **异步解析**: 使用`compute`在独立isolate中解析JSON
3. **高效存储**: Hive批量写入 + 内存索引构建

**示例缓存实现**:
```dart
// 启用压缩的Dio配置
final dio = Dio()..options.headers = {'Accept-Encoding': 'gzip'};

// 异步解析
final funds = await compute(parseFunds, response.data);

// 批量写入Hive
await fundBox.putAll({for (var f in funds) f.code: f});
```

## 测试策略

### 测试结构
- **单元测试**: `test/unit/` - 单个组件和逻辑
- **集成测试**: `test/integration/` - 多组件协作
- **功能测试**: `test/features/` - 端到端业务流程

### 测试工具
- **flutter_test**: Flutter测试框架
- **bloc_test**: BLoC状态测试
- **mockito**: Mock对象
- **build_runner**: 测试代码生成

### 运行测试建议
```bash
# 开发时运行特定测试
flutter test test/unit/core/cache/ --coverage

# 完整测试套件
flutter test --reporter=expanded

# 性能测试
flutter test test/performance/
```

## 代码质量标准

### Linting配置
- 基于`package:flutter_lints/flutter.yaml`
- 自定义排除规则在`analysis_options.yaml`中配置

### 代码规范
- 遵循Dart官方代码风格
- 使用`dart format`格式化代码
- 所有公共API需要添加文档注释
- 避免在生产代码中使用`print`语句

## 特殊开发要求

### 多语言支持
- 简体中文为主要开发语言
- 使用`flutter_localizations`支持国际化
- 所有用户界面文本使用中文

### Windows平台特定
- 主要目标平台为Windows桌面
- 支持Windows特定的UI/UX模式
- 注意Windows文件路径处理

### 性能优化
- 基金数据量大，需要优化列表渲染性能
- 使用内存缓存和预加载策略
- 图表数据需要异步处理

## Git工作流

### 分支策略
- `master`: 主分支，稳定版本
- `develop`: 开发分支
- `feature/*`: 功能分支

### 提交规范
- 参考Git手册: `docs/Git 分支合并与远程同步操作手册.md`
- 小版本更新格式: `0.5.1`, `0.5.2`等

### 文档更新
- 每完成重要进度需要更新`PROGRESS.md`
- API文档保存在`docs/api/`目录下
- 技术文档按功能模块分类存放

## 常见问题解决

### 构建问题
```bash
# 清理并重新获取依赖
flutter clean && flutter pub get

# 重新生成代码
dart run build_runner clean && dart run build_runner build
```

### 分析问题处理
- 当前有3000+个分析警告，主要是`avoid_print`和`unused_import`
- 优先处理核心业务模块的警告
- 工具类和调试脚本可以适当放宽要求

### 缓存问题
- Hive数据库版本迁移需要特别注意
- 使用`cache_migration`工具处理数据迁移
- 测试时使用独立的测试数据库

## 开发角色定位

- **架构师**: 严谨设计项目架构，确保代码质量和可维护性
- **UI设计师**: 创造想象力的用户界面，注重用户体验
- **高级程序员**: 精通多语言，实现复杂业务逻辑
- **测试员**: 一丝不苟测试，确保功能正确性

每个开发阶段都要严格按照相应的角色标准执行工作。