# 项目结构分析

## 项目基本信息

- **项目名称**: jisu_fund_analyzer (基速基金量化分析平台)
- **项目类型**: Flutter桌面应用
- **版本**: 0.5.5
- **仓库类型**: 单体应用 (Monolith)
- **目标平台**: Windows桌面应用

## 项目分类结果

### 项目类型检测
基于文件模式匹配，此项目被识别为 **desktop** 类型项目：

**匹配的关键文件模式**:
- `pubspec.yaml` - Flutter项目配置文件
- `analysis_options.yaml` - Dart分析配置
- 不包含 `package.json`、`go.mod`、`requirements.txt` 等其他语言包管理器

**检测到的工作空间配置**: 无 (非monorepo)

### 项目结构特征

#### Clean Architecture实现
- 采用标准的Clean Architecture + BLoC模式
- 清晰的分层结构：`data/`、`domain/`、`presentation/`
- 功能模块化：`features/fund/`、`features/auth/`、`features/home/`等

#### 主要目录结构
```
lib/
├── main.dart                    # 应用入口点
└── src/
    ├── core/                    # 核心模块
    │   ├── cache/              # 统一缓存系统
    │   ├── di/                 # 依赖注入
    │   ├── network/            # 网络层
    │   └── utils/              # 工具类
    ├── features/               # 功能模块
    │   ├── auth/               # 认证模块
    │   ├── fund/               # 基金核心功能
    │   ├── portfolio/          # 投资组合
    │   ├── navigation/         # 导航外壳
    │   ├── alerts/             # 价格提醒
    │   ├── data_center/        # 数据中心
    │   ├── home/               # 主页
    │   └── settings/           # 设置
    ├── bloc/                   # 全局状态管理
    └── models/                 # 数据模型
```

## 架构模式

### 主要架构模式
- **Clean Architecture**: 关注点分离，依赖倒置
- **BLoC Pattern**: 状态管理，业务逻辑与UI分离
- **Repository Pattern**: 数据访问抽象

### 技术特征
- **状态管理**: flutter_bloc
- **网络请求**: Dio + Retrofit
- **本地存储**: Hive + SharedPreferences
- **依赖注入**: GetIt
- **数据库**: SQL Server (sql_conn), PostgreSQL (postgres)
- **图表**: fl_chart
- **动画**: flutter_animate

## 多部分集成架构
**结果**: 此项目为单体应用，不包含多部分集成架构。

## 项目复杂度评估
- **复杂度**: 中等偏高
- **主要特征**: Clean Architecture + 多功能模块
- **预估文件数量**: 100+ Dart文件
- **代码质量**: 严格的分析规则配置

---

**扫描完成时间**: 2025-11-06T12:00:00Z
**扫描模式**: Quick Scan (模式匹配，未读取源文件)
**下一步**: 继续发现现有文档并收集用户上下文