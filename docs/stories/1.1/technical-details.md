# Technical Details

### 组件结构
```
lib/src/features/fund/presentation/fund_exploration/
├── presentation/
│   ├── pages/
│   │   └── fund_exploration_page_refactored.dart  # 新重构页面
│   ├── widgets/
│   │   ├── main_search_section.dart              # 主搜索区域
│   │   ├── recommendation_section.dart           # 推荐区域
│   │   ├── collapsible_tool_panel.dart           # 可折叠工具面板
│   │   └── simplified_fund_card.dart             # 简化基金卡片
│   └── cubit/
│       └── fund_exploration_refactored_cubit.dart # 重构状态管理
```

### 状态管理
- 复用现有 `FundExplorationCubit`
- 新增 `FundExplorationRefactoredCubit` 处理新界面状态
- 保持与 `FundRankingBloc` 的集成

### API集成
- 保持现有 `FundApiClient` 接口
- 复用 `GetFundRankings` 用例
- 新增推荐数据获取逻辑
