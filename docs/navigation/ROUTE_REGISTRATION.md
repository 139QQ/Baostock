# 应用路由注册文档

## 📋 概述

本文档详细说明了基速基金分析器应用的导航路由配置，特别是**基金自选**和**持仓分析**两个核心功能模块的路由注册。

## 🏗️ 导航架构

### 主导航容器
- **文件位置**: `lib/src/features/navigation/presentation/pages/navigation_shell.dart`
- **组件**: `NavigationShell`
- **类型**: 侧边栏导航 (NavigationRail)

### 路由索引映射

| 索引 | 页面组件 | 功能描述 | 状态 | 高亮 |
|------|----------|----------|------|------|
| 0 | `DashboardPage` | 市场概览 | 正常 | - |
| 1 | `FundExplorationPage` | 基金筛选 | 正常 | - |
| **2** | **`WatchlistPage`** | **🌟 自选基金** | **正常** | **✅ 加粗** |
| **3** | **`PortfolioAnalysisPage`** | **📊 持仓分析** | **正常** | **✅ 加粗** |
| 4 | `AlertsPage` | 行情预警 | 正常 | - |
| 5 | `DataCenterPage` | 数据中心 | 正常 | - |
| 6 | `SettingsPage` | 系统设置 | 正常 | - |

## 🌟 核心路由详情

### 1. 自选基金路由 (索引 2)

#### 路由配置
```dart
_buildDestination(
  icon: Icons.star_outline,
  selectedIcon: Icons.star,
  label: '🌟 自选基金',
  tooltip: '管理关注基金',
  isHighlighted: true, // 🎯 重点功能 - 加粗显示
),
```

#### 页面组件
- **文件**: `lib/src/features/fund/presentation/pages/watchlist_page.dart`
- **类名**: `WatchlistPage`
- **功能**:
  - ✅ 查看和管理自选基金列表
  - ✅ 添加/删除自选基金
  - ✅ 实时更新基金数据
  - ✅ 基金搜索和筛选
  - ✅ 排序功能
  - ✅ **添加到持仓** (核心数据联动功能)

#### 数据联动
- **到持仓**: 点击基金卡片菜单 → "添加到持仓" → 自动导航到持仓分析页面
- **从持仓**: 可通过导航返回自选基金页面

### 2. 持仓分析路由 (索引 3)

#### 路由配置
```dart
_buildDestination(
  icon: Icons.analytics_outlined,
  selectedIcon: Icons.analytics,
  label: '📊 持仓分析',
  tooltip: '分析投资组合',
  isHighlighted: true, // 🎯 重点功能 - 加粗显示
),
```

#### 页面组件
- **文件**: `lib/src/features/portfolio/presentation/pages/portfolio_analysis_page.dart`
- **类名**: `PortfolioAnalysisPage`
- **功能**:
  - ✅ 持仓列表管理
  - ✅ 收益分析计算
  - ✅ 持仓添加/编辑/删除
  - ✅ **从自选导入** (核心数据联动功能)
  - ✅ 投资组合分析

#### 数据联动
- **从自选**: 自选基金页面 → "添加到持仓" → 自动填充持仓表单
- **数据同步**: 保持自选基金与持仓数据的一致性

## 🎨 视觉设计

### 加粗效果特性
1. **字体加粗**: `FontWeight.bold` (vs 正常 `FontWeight.w500`)
2. **字体大小**: `13.0` (vs 正常 `12.0`)
3. **图标大小**: 未选中 `24px` (vs 正常 `22px`)
4. **颜色主题**: 使用主题色进行强调
5. **表情符号**: 🌟 自选基金, 📊 持仓分析

### 导航状态
- **未选中**: 加粗字体 + 主题色图标
- **已选中**: 默认选中样式 (覆盖加粗效果)
- **悬停**: Tooltip 提示功能描述

## 🔄 数据联动工作流

### 自选 → 持仓 流程
```mermaid
graph LR
    A[自选基金页面] --> B[点击基金菜单]
    B --> C[选择"添加到持仓"]
    C --> D[自动导航到持仓页面]
    D --> E[预填充持仓表单]
    E --> F[确认添加持仓]
```

### 持仓 → 自选 流程
```mermaid
graph LR
    A[持仓分析页面] --> B[点击导航栏]
    B --> C[选择"自选基金"]
    C --> D[返回自选基金页面]
    D --> E[查看/管理自选列表]
```

## 🔧 技术实现

### 路由导航方法
```dart
// 页面间导航
void _navigateToPortfolioPage() {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => const PortfolioAnalysisPage(),
    ),
  );
}

// NavigationShell 内部导航
void navigateToPage(int index) {
  if (mounted && index >= 0 && index < _pages.length) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
```

### 状态管理
- **WatchlistPage**: 使用 `FundFavoriteCubit` 管理自选基金状态
- **PortfolioAnalysisPage**: 使用 `PortfolioAnalysisCubit` 管理持仓状态
- **共享服务**: `FavoriteToHoldingService` 处理数据转换

## 📱 响应式设计

### 桌面端
- NavigationRail 侧边栏导航
- 完整图标 + 文字标签
- 悬停提示

### 移动端 (未来支持)
- BottomNavigationBar 底部导航
- 紧凑图标布局
- 手势导航

## 🚀 扩展建议

### 短期改进
1. **快捷键支持**: 为重要路由添加键盘快捷键
2. **面包屑导航**: 在页面顶部显示导航路径
3. **路由动画**: 添加页面切换动画效果

### 长期规划
1. **深度链接**: 支持直接访问特定页面
2. **路由守卫**: 添加权限验证
3. **多标签页**: 支持同时打开多个页面

## 📝 维护说明

### 添加新路由
1. 在 `_pages` 列表中添加页面组件
2. 在 `destinations` 中添加对应配置
3. 更新本文档的路由映射表

### 修改路由顺序
1. 调整 `_pages` 列表中的索引
2. 更新所有引用该索引的代码
3. 测试导航功能是否正常

### 样式调整
1. 修改 `_buildDestination` 方法
2. 调整 `isHighlighted` 参数
3. 测试视觉效果

---

**文档版本**: v1.0
**最后更新**: 2025-10-22
**维护者**: 基速基金分析器开发团队