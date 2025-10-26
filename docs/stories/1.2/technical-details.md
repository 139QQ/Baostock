# Technical Details

### 组件结构
```
lib/src/features/fund/presentation/fund_exploration/presentation/widgets/
├── collapsible_tool_panel.dart           # 主面板组件
├── panel_sections/
│   ├── advanced_filter_section.dart     # 高级筛选部分
│   ├── comparison_tools_section.dart    # 对比工具部分
│   ├── calculator_section.dart          # 计算器部分
│   └── sort_options_section.dart        # 排序选项部分
└── panel_state_manager.dart             # 面板状态管理
```

### 状态管理设计
```dart
class CollapsiblePanelState {
  final Map<PanelType, bool> expandedStates;
  final PanelDimensions dimensions;
  final AnimationStatus animationStatus;

  // 面板类型枚举
  enum PanelType {
    advancedFilter,
    comparisonTools,
    calculator,
    sortOptions,
  }
}
```

### 本地存储结构
```dart
// localStorage 存储
{
  "collapsible_panels": {
    "advanced_filter": true,
    "comparison_tools": false,
    "calculator": false,
    "sort_options": true,
    "last_updated": "2025-10-22T10:30:00Z"
  }
}
```
