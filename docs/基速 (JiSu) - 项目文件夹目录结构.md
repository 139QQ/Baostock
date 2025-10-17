jisu_fund_quant/
├── android/                    # Android平台代码（保留，为未来跨平台准备）
├── ios/                        # iOS平台代码（保留，为未来跨平台准备）
├── linux/                      # Linux桌面端特定代码
├── macos/                      # macOS桌面端特定代码
├── windows/                    # Windows桌面端特定代码
├── web/                        # Web平台代码（保留）
├── lib/                        # 主要Dart源代码
│   ├── src/                    # 应用核心源代码
│   │   ├── core/               # 核心功能模块
│   │   │   ├── constants/      # 常量定义
│   │   │   │   ├── app_constants.dart
│   │   │   │   ├── api_constants.dart
│   │   │   │   ├── style_constants.dart
│   │   │   │   └── database_constants.dart
│   │   │   ├── errors/         # 错误处理
│   │   │   │   ├── exceptions.dart
│   │   │   │   ├── error_codes.dart
│   │   │   │   └── error_handler.dart
│   │   │   ├── extensions/     # Dart扩展
│   │   │   │   ├── datetime_extensions.dart
│   │   │   │   ├── string_extensions.dart
│   │   │   │   └── num_extensions.dart
│   │   │   ├── utils/          # 工具类
│   │   │   │   ├── date_utils.dart
│   │   │   │   ├── calculation_utils.dart
│   │   │   │   ├── format_utils.dart
│   │   │   │   └── file_utils.dart
│   │   │   └── widgets/        # 通用Widgets
│   │   │       ├── common/
│   │   │       │   ├── app_button.dart
│   │   │       │   ├── app_card.dart
│   │   │       │   └── loading_indicator.dart
│   │   │       ├── charts/     # 图表组件
│   │   │       │   ├── fund_chart.dart
│   │   │       │   ├── performance_chart.dart
│   │   │       │   └── comparison_chart.dart
│   │   │       └── tables/     # 表格组件
│   │   │           ├── data_table.dart
│   │   │           ├── sortable_table.dart
│   │   │           └── paginated_table.dart
│   │   ├── data/               # 数据层
│   │   │   ├── datasources/    # 数据源
│   │   │   │   ├── remote/     # 远程数据源
│   │   │   │   │   ├── akshare_api_service.dart
│   │   │   │   │   ├── api_client.dart
│   │   │   │   │   └── api_endpoints.dart
│   │   │   │   └── local/      # 本地数据源
│   │   │   │       ├── database_helper.dart
│   │   │   │       ├── hive_service.dart
│   │   │   │       └── cache_manager.dart
│   │   │   ├── models/         # 数据模型
│   │   │   │   ├── fund/       # 基金相关模型
│   │   │   │   │   ├── fund_model.dart
│   │   │   │   │   ├── fund_nav_model.dart
│   │   │   │   │   ├── fund_metrics_model.dart
│   │   │   │   │   └── fund_holding_model.dart
│   │   │   │   ├── portfolio/  # 组合相关模型
│   │   │   │   │   ├── portfolio_model.dart
│   │   │   │   │   ├── holding_model.dart
│   │   │   │   │   └── transaction_model.dart
│   │   │   │   ├── user/       # 用户相关模型
│   │   │   │   │   ├── user_setting_model.dart
│   │   │   │   │   ├── watchlist_model.dart
│   │   │   │   │   └── preference_model.dart
│   │   │   │   └── api/        # API响应模型
│   │   │   │       ├── api_response.dart
│   │   │   │       ├── api_error.dart
│   │   │   │       └── paginated_response.dart
│   │   │   ├── repositories/   # 数据仓库
│   │   │   │   ├── fund_repository.dart
│   │   │   │   ├── portfolio_repository.dart
│   │   │   │   ├── watchlist_repository.dart
│   │   │   │   └── settings_repository.dart
│   │   │   └── services/       # 数据服务
│   │   │       ├── fund_service.dart
│   │   │       ├── portfolio_service.dart
│   │   │       ├── calculation_service.dart
│   │   │       └── sync_service.dart
│   │   ├── domain/             # 领域层
│   │   │   ├── entities/       # 领域实体
│   │   │   │   ├── fund_entity.dart
│   │   │   │   ├── portfolio_entity.dart
│   │   │   │   └── watchlist_entity.dart
│   │   │   ├── repositories/   # 领域仓库接口
│   │   │   │   ├── i_fund_repository.dart
│   │   │   │   ├── i_portfolio_repository.dart
│   │   │   │   └── i_watchlist_repository.dart
│   │   │   └── usecases/       # 用例
│   │   │       ├── fund_usecases.dart
│   │   │       ├── portfolio_usecases.dart
│   │   │       └── watchlist_usecases.dart
│   │   └── presentation/       # 表现层
│   │       ├── blocs/          # 状态管理(BLoC)
│   │       │   ├── fund_bloc/
│   │       │   │   ├── fund_bloc.dart
│   │       │   │   ├── fund_event.dart
│   │       │   │   └── fund_state.dart
│   │       │   ├── portfolio_bloc/
│   │       │   │   ├── portfolio_bloc.dart
│   │       │   │   ├── portfolio_event.dart
│   │       │   │   └── portfolio_state.dart
│   │       │   ├── watchlist_bloc/
│   │       │   │   ├── watchlist_bloc.dart
│   │       │   │   ├── watchlist_event.dart
│   │       │   │   └── watchlist_state.dart
│   │       │   ├── settings_bloc/
│   │       │   │   ├── settings_bloc.dart
│   │       │   │   ├── settings_event.dart
│   │       │   │   └── settings_state.dart
│   │       │   └── app_bloc/   # 应用全局状态
│   │       │       ├── app_bloc.dart
│   │       │       ├── app_event.dart
│   │       │       └── app_state.dart
│   │       ├── pages/          # 页面组件
│   │       │   ├── dashboard/  # 仪表盘页
│   │       │   │   ├── dashboard_page.dart
│   │       │   │   └── dashboard_view.dart
│   │       │   ├── fund_detail/ # 基金详情页
│   │       │   │   ├── fund_detail_page.dart
│   │       │   │   ├── fund_detail_view.dart
│   │       │   │   ├── tabs/
│   │       │   │   │   ├── overview_tab.dart
│   │       │   │   │   ├── history_tab.dart
│   │       │   │   │   ├── holdings_tab.dart
│   │       │   │   │   └── metrics_tab.dart
│   │       │   │   └── components/
│   │       │   │       ├── fund_header.dart
│   │       │   │       ├── chart_container.dart
│   │       │   │       └── metrics_grid.dart
│   │       │   ├── watchlist/  # 自选页面
│   │       │   │   ├── watchlist_page.dart
│   │       │   │   ├── watchlist_view.dart
│   │       │   │   └── components/
│   │       │   │       ├── watchlist_table.dart
│   │       │   │       ├── group_selector.dart
│   │       │   │       └── batch_actions.dart
│   │       │   ├── explore/    # 基金探索页
│   │       │   │   ├── explore_page.dart
│   │       │   │   ├── explore_view.dart
│   │       │   │   └── components/
│   │       │   │       ├── search_bar.dart
│   │       │   │       ├── filter_panel.dart
│   │       │   │       └── fund_grid.dart
│   │       │   ├── settings/   # 设置页
│   │       │   │   ├── settings_page.dart
│   │       │   │   ├── settings_view.dart
│   │       │   │   └── tabs/
│   │       │   │       ├── general_tab.dart
│   │       │   │       ├── data_tab.dart
│   │       │   │       ├── appearance_tab.dart
│   │       │   │       └── about_tab.dart
│   │       │   └── common/     # 通用页面组件
│   │       │       ├── layout/
│   │       │       │   ├── app_scaffold.dart
│   │       │       │   ├── navigation_rail.dart
│   │       │       │   └── app_bar.dart
│   │       │       ├── empty_states/
│   │       │       │   ├── no_results.dart
│   │       │       │   ├── empty_watchlist.dart
│   │       │       │   └── offline_state.dart
│   │       │       └── error_states/
│   │       │           ├── api_error.dart
│   │       │           ├── connection_error.dart
│   │       │           └── generic_error.dart
│   │       ├── themes/         # 主题与样式
│   │       │   ├── app_theme.dart
│   │       │   ├── color_palette.dart
│   │       │   ├── text_styles.dart
│   │       │   ├── button_styles.dart
│   │       │   └── input_styles.dart
│   │       └── routers/        # 路由管理
│   │           ├── app_router.dart
│   │           ├── route_names.dart
│   │           └── route_transitions.dart
│   ├── main.dart               # 应用入口点
│   ├── app.dart                # 主应用组件
│   ├── di.dart                 # 依赖注入配置
│   └── generated/              # 代码生成目录（freezed, json_serializable等）
│       ├── models/
│       └── routers/
├── test/                       # 测试代码
│   ├── unit/                   # 单元测试
│   │   ├── core/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── widget/                 # Widget测试
│   │   ├── core/
│   │   ├── pages/
│   │   └── common/
│   ├── integration/            # 集成测试
│   │   ├── app_test.dart
│   │   ├── fund_flow_test.dart
│   │   └── watchlist_flow_test.dart
│   └── helpers/                # 测试辅助工具
│       ├── mock_services.dart
│       ├── test_constants.dart
│       └── test_utils.dart
├── assets/                     # 静态资源
│   ├── images/                 # 图片资源
│   │   ├── icons/              # 图标
│   │   ├── illustrations/      # 插画
│   │   └── logos/              # Logo
│   ├── fonts/                  # 字体文件
│   └── data/                   # 初始数据文件
│       ├── fund_list_sample.json
│       └── mock_data.json
├── scripts/                    # 脚本文件
│   ├── build/                  # 构建脚本
│   ├── deployment/             # 部署脚本
│   ├── code_generation/        # 代码生成脚本
│   └── database/               # 数据库管理脚本
├── tools/                      # 开发工具
│   ├── codegen_runner.dart     # 代码生成运行器
│   └── database_helper.dart    # 数据库管理工具
├── .github/                    # GitHub配置
│   ├── workflows/              # CI/CD工作流
│   │   ├── build.yml
│   │   ├── test.yml
│   │   └── release.yml
│   └── ISSUE_TEMPLATE/         # Issue模板
├── .vscode/                    # VSCode配置
│   ├── settings.json
│   ├── launch.json
│   └── extensions.json
├── .idea/                      # IDEA配置（可选）
├── build/                      # 构建输出目录
├── dist/                       # 发布文件目录
├── doc/                        # 项目文档
│   ├── api/                    # API文档
│   ├── design/                 # 设计文档
│   │   ├── ui_design.md
│   │   ├── ux_design.md
│   │   └── database_design.md
│   ├── development/            # 开发文档
│   │   ├── setup_guide.md
│   │   ├── architecture.md
│   │   └── contributing.md
│   ├── user/                   # 用户文档
│   │   ├── getting_started.md
│   │   ├── user_guide.md
│   │   └── faq.md
│   └── assets/                 # 文档资源
│       ├── diagrams/
│       └── screenshots/
├── LICENSE
├── README.md
├── CHANGELOG.md
├── pubspec.yaml                # 项目依赖配置
├── pubspec.lock
├── analysis_options.yaml       # 静态分析配置
├── l10n.yaml                   # 国际化配置
└── .gitignore

## 目录结构说明

### 1. 平台特定目录

- `linux/`, `macos/`, `windows/`: 包含各桌面平台的特定代码和配置
- 保留 `android/`, `ios/`, `web/` 目录以便未来扩展

### 2. 核心源代码 (lib/src)

采用清晰的分层架构：

- **core/**: 通用工具、扩展和基础组件
- **data/**: 数据层，处理所有数据相关的操作
- **domain/**: 领域层，包含业务逻辑和用例
- **presentation/**: 表现层，处理UI和用户交互

### 3. 测试目录 (test/)

- 按照功能模块组织测试代码
- 包含单元测试、Widget测试和集成测试

### 4. 资源文件 (assets/)

- 集中管理所有静态资源
- 包含图片、字体和示例数据

### 5. 脚本和工具 (scripts/, tools/)

- 自动化构建和部署脚本
- 代码生成和数据库管理工具

### 6. 文档目录 (doc/)

- 完整的项目文档，包括设计、开发和用户指南

### 7. 配置文件

- 各种配置文件确保开发环境一致性
- 包含代码分析、国际化和Git相关配置

## 开发环境设置建议

1. **IDE配置**: 使用VS Code或Android Studio，安装Flutter和Dart插件
2. **代码生成**: 配置freezed和json_serializable用于模型生成
3. **代码格式化**: 使用dart format保持代码风格一致
4. **静态分析**: 配置analysis_options.yaml进行代码质量检查
5. **Git钩子**: 设置pre-commit钩子运行格式化和分析