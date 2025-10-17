# 源代码结构规范

## 1. 项目结构概述

项目采用**功能模块化**的代码组织方式，结合**分层架构**设计，确保代码的可维护性、可测试性和可扩展性。

### 1.1 顶级目录结构
```
jisu_fund_analyzer/
├── lib/                    # 主要源代码
│   ├── src/               # 源码根目录
│   │   ├── core/          # 核心模块
│   │   ├── features/      # 功能模块
│   │   └── shared/        # 共享组件
│   └── main.dart          # 应用入口
├── test/                  # 测试代码
├── docs/                  # 项目文档
├── assets/                # 静态资源
├── tools/                 # 开发工具
└── pubspec.yaml          # 项目配置
```

### 1.2 源码目录详细结构

#### 1.2.1 核心模块 (core/)
```
core/
├── cache/                 # 缓存管理
│   ├── hive_cache_manager.dart
│   └── cache_constants.dart
├── constants/             # 常量定义
│   ├── app_constants.dart
│   ├── api_constants.dart
│   └── app_design_constants.dart
├── database/              # 数据库相关
│   ├── repositories/      # 数据访问对象
│   ├── sql_scripts/       # SQL脚本
│   ├── sql_server_config.dart
│   └── sql_server_manager.dart
├── di/                    # 依赖注入
│   ├── injection_container.dart      # 主容器
│   ├── hive_injection_container.dart # Hive模块
│   └── sql_server_injection_container.dart
├── logger/                # 日志系统
│   └── app_logger.dart
├── network/               # 网络通信
│   ├── api_service.dart
│   ├── fund_api_client.dart
│   └── interceptors/      # 网络拦截器
├── services/              # 核心服务
│   ├── market_real_service.dart
│   └── data_sync_service.dart
├── theme/                 # 主题管理
│   ├── app_theme.dart
│   ├── color_schemes.dart
│   └── text_themes.dart
└── utils/                 # 工具类
    ├── validators.dart
    ├── formatters.dart
    └── extensions/        # 扩展方法
```

#### 1.2.2 功能模块 (features/)
每个功能模块遵循**清洁架构**原则，包含完整的分层结构：

```
features/
├── fund/                  # 基金排行模块
│   ├── data/             # 数据层
│   │   ├── datasources/  # 数据源
│   │   ├── models/       # 数据模型
│   │   └── repositories/ # 仓库实现
│   ├── domain/           # 领域层
│   │   ├── entities/     # 实体类
│   │   ├── repositories/ # 仓库接口
│   │   └── usecases/     # 用例
│   └── presentation/     # 表示层
│       ├── bloc/         # 状态管理
│       ├── pages/        # 页面
│       └── widgets/      # 组件
├── fund_exploration/     # 基金探索模块
├── home/                 # 首页模块
├── market/               # 市场数据模块
├── portfolio/            # 组合管理模块
├── data_center/          # 数据中心模块
├── alerts/               # 提醒通知模块
├── settings/             # 设置模块
└── navigation/           # 导航模块
```

#### 1.2.3 共享组件 (shared/)
```
shared/
├── widgets/              # 通用UI组件
│   ├── cards/           # 卡片组件
│   ├── buttons/         # 按钮组件
│   └── charts/          # 图表组件
├── utils/               # 通用工具
└── constants/           # 共享常量
```

## 2. 文件命名规范

### 2.1 Dart文件命名
- **小写+下划线**: 使用小写字母，多个单词用下划线分隔
- **功能描述性**: 文件名应准确描述文件内容
- **避免缩写**: 除非是通用缩写（如api, ui等）

```dart
// ✅ 正确
good examples:
- fund_detail_page.dart
- api_constants.dart
- fund_repository_impl.dart

// ❌ 错误
bad examples:
- FundDetailPage.dart      // 不应使用驼峰
- fundetail.dart          // 不清晰
- fund_repo.dart          // 不必要缩写
```

### 2.2 测试文件命名
- **后缀标识**: 使用`_test.dart`后缀
- **对应源文件**: 测试文件名应与被测试文件名对应

```
lib/src/features/fund/presentation/pages/fund_page.dart
test/features/fund/presentation/pages/fund_page_test.dart
```

### 2.3 资源文件命名
- **小写+连字符**: 使用小写字母，多个单词用连字符分隔
- **类型前缀**: 根据资源类型添加前缀

```
assets/
├── images/
│   ├── img-fund-placeholder.png
│   └── img-market-banner.jpg
├── icons/
│   ├── ic-fund-star.svg
│   └── ic-nav-home.svg
└── fonts/
    ├── fnt-primary-regular.ttf
    └── fnt-primary-bold.ttf
```

## 3. 代码组织原则

### 3.1 单一职责原则
每个文件、类、函数应只负责一项职责：

```dart
// ✅ 正确 - 单一职责
class FundRepository {
  Future<List<Fund>> getFunds() async {
    // 只负责基金数据的获取
  }
}

class FundCacheManager {
  Future<void> cacheFunds(List<Fund> funds) async {
    // 只负责基金数据的缓存
  }
}

// ❌ 错误 - 多重职责
class FundManager {
  Future<List<Fund>> getFunds() async {
    // 获取数据
  }

  Future<void> cacheFunds(List<Fund> funds) async {
    // 缓存数据
  }

  void displayFunds(List<Fund> funds) {
    // 显示数据
  }
}
```

### 3.2 依赖倒置原则
高层模块不应依赖低层模块，二者都应依赖抽象：

```dart
// ✅ 正确 - 依赖抽象
abstract class FundRepository {
  Future<List<Fund>> getFunds();
}

class FundRepositoryImpl implements FundRepository {
  @override
  Future<List<Fund>> getFunds() async {
    // 具体实现
  }
}

class FundBloc extends Bloc<FundEvent, FundState> {
  final FundRepository repository;  // 依赖抽象

  FundBloc({required this.repository});
}

// ❌ 错误 - 依赖具体实现
class FundBloc extends Bloc<FundEvent, FundState> {
  final FundRepositoryImpl repository;  // 依赖具体实现

  FundBloc() : repository = FundRepositoryImpl();
}
```

### 3.3 接口隔离原则
使用多个专门的接口，而不是单一的总接口：

```dart
// ✅ 正确 - 专门接口
abstract class FundCache {
  Future<void> cacheFund(Fund fund);
  Future<Fund?> getFund(String code);
}

abstract class FundSearch {
  Future<List<Fund>> searchFunds(String query);
}

class FundRepository implements FundCache, FundSearch {
  // 实现多个专门接口
}

// ❌ 错误 - 臃肿接口
abstract class FundManager {
  Future<void> cacheFund(Fund fund);
  Future<Fund?> getFund(String code);
  Future<List<Fund>> searchFunds(String query);
  Future<void> updateFund(Fund fund);
  Future<void> deleteFund(String code);
  // ... 更多方法
}
```

## 4. 模块间依赖关系

### 4.1 依赖方向
依赖关系应指向内部，避免循环依赖：

```
Presentation Layer → Domain Layer → Data Layer → Core Layer
```

### 4.2 依赖管理示例
```dart
// ✅ 正确的依赖方向
// core/ 不应依赖任何feature模块
// feature模块可以依赖core模块
// feature模块间不应相互依赖

// 在injection_container.dart中
import 'package:jisu_fund_analyzer/src/features/fund/data/datasources/fund_api.dart';
import 'package:jisu_fund_analyzer/src/features/fund/data/repositories/fund_repository_impl.dart';
import 'package:jisu_fund_analyzer/src/features/fund/domain/repositories/fund_repository.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/bloc/fund_bloc.dart';
```

## 5. 公共API设计

### 5.1 导出文件 (barrel files)
每个目录应包含`export.dart`文件，统一管理导出：

```dart
// lib/src/core/core.dart
export 'cache/cache.dart';
export 'constants/constants.dart';
export 'network/network.dart';
export 'theme/theme.dart';
export 'utils/utils.dart';

// lib/src/features/fund/fund.dart
export 'data/data.dart';
export 'domain/domain.dart';
export 'presentation/presentation.dart';
```

### 5.2 简化的导入路径
通过包配置提供简化的导入路径：

```yaml
# pubspec.yaml
flutter:
  assets:
    - assets/images/
    - assets/icons/

# 使用简化导入
import 'package:jisu_fund_analyzer/core.dart';
import 'package:jisu_fund_analyzer/fund.dart';
```

## 6. 配置管理

### 6.1 环境配置
```
lib/
├── config/
│   ├── app_config.dart          # 应用配置
│   ├── environment_config.dart  # 环境配置
│   └── api_config.dart          # API配置
```

### 6.2 配置文件示例
```dart
// config/app_config.dart
class AppConfig {
  static const String appName = '基速基金分析';
  static const String appVersion = '0.1.0';
  static const String buildNumber = '1';

  static const int apiTimeout = 10000; // 10秒
  static const int cacheTimeout = 900000; // 15分钟
}
```

## 7. 代码复用策略

### 7.1 组件复用
- **原子组件**: 最基础的UI元素
- **分子组件**: 由原子组件组合而成
- **有机体组件**: 完整的UI模块

```
shared/widgets/
├── atoms/           # 原子组件
│   ├── app_button.dart
│   ├── app_input.dart
│   └── app_text.dart
├── molecules/       # 分子组件
│   ├── search_bar.dart
│   └── filter_chip.dart
└── organisms/       # 有机体组件
    ├── fund_card.dart
    └── chart_container.dart
```

### 7.2 逻辑复用
- **Mixin**: 共享行为
- **扩展函数**: 增强现有类
- **工具类**: 静态方法集合

```dart
// utils/extensions/datetime_extension.dart
extension DateTimeExtension on DateTime {
  String toFormattedString() {
    return DateFormat('yyyy-MM-dd').format(this);
  }

  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}
```

## 8. 测试结构

### 8.1 测试目录结构
```
test/
├── core/                  # 核心模块测试
├── features/              # 功能模块测试
│   └── fund/
│       ├── data/          # 数据层测试
│       ├── domain/        # 领域层测试
│       └── presentation/  # 表示层测试
├── fixtures/              # 测试数据
└── helpers/               # 测试辅助工具
```

### 8.2 测试文件组织
```
# 单元测试
test/unit/
├── core/
└── features/

# 组件测试
test/widget/
└── features/

# 集成测试
test/integration/
└── app_test.dart
```

## 9. 文档结构

### 9.1 代码内文档
- **公共API**: 完整的dartdoc注释
- **复杂逻辑**: 实现注释说明
- **算法说明**: 关键算法的时间复杂度

```dart
/// 基金数据仓库接口
///
/// 提供基金数据的CRUD操作，支持本地缓存和网络数据源
abstract class FundRepository {
  /// 获取基金列表
  ///
  /// [forceRefresh] 为true时强制从网络获取最新数据
  /// 返回按收益率排序的基金列表
  ///
  /// 时间复杂度: O(n log n)，其中n为基金数量
  Future<List<Fund>> getFunds({bool forceRefresh = false});
}
```

### 9.2 README文件
每个主要目录应包含README.md文件：

```markdown
# Core Module

## Overview
核心模块提供应用的基础功能支持...

## Structure
- cache/ - 缓存管理
- network/ - 网络通信
- theme/ - 主题管理

## Usage
```dart
import 'package:jisu_fund_analyzer/core.dart';
```

## Testing
运行核心模块测试:
```bash
flutter test test/core/
```
```

---

**最后更新**: 2025-09-26
**维护者**: 开发团队
**审核状态**: 已审核
**关联文档**: [架构文档](../architecture.md), [编码规范](./coding-standards.md)"}