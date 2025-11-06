# 多平台导航组件

本目录包含了为基速基金应用设计的多平台导航组件，支持Web端、桌面端和移动端的不同导航模式。

## 组件概览

### 🌐 Web端导航

#### 1. WebExpandedNavigationBar (扩展式导航栏)
- **适用场景**: 大屏幕Web端 (>1200px)
- **特性**:
  - 水平扩展式布局
  - 大屏幕优化显示
  - 鼠标悬停效果
  - 响应式菜单项
  - 品牌Logo + 导航菜单 + 搜索框 + 用户区域

#### 2. WebCompactNavigationBar (紧凑导航栏)
- **适用场景**: 中等屏幕Web端 (768px-1200px)
- **特性**:
  - 紧凑的布局设计
  - 图标 + 文字标签
  - 核心功能保留
  - 更小的交互元素

### 📱 移动端导航

#### 1. MobileNavigationShell (移动端导航外壳)
- **适用场景**: 移动设备 (<768px)
- **特性**:
  - 底部标签栏导航
  - 浮动操作按钮 (FAB)
  - 顶部应用栏
  - 触摸友好的交互设计

#### 2. MobileDrawerMenu (抽屉式菜单)
- **特性**:
  - 侧边滑出式菜单
  - 用户信息展示
  - 快捷操作入口
  - 设置和登出选项

### 🖥️ 桌面端导航

#### NavigationShell (现有组件)
- **适用场景**: Windows/macOS/Linux桌面应用
- **特性**:
  - 侧边导航栏
  - 全局导航栏
  - 极简布局支持

## 核心组件

### ResponsiveNavigationBar (响应式导航栏)
- **功能**: 根据平台和屏幕尺寸自动选择合适的导航组件
- **支持的判断条件**:
  - 平台类型检测 (Web/iOS/Android/Windows/macOS/Linux)
  - 屏幕尺寸检测 (桌面/平板/手机)
  - 自动切换导航模式

## 使用方法

### 基本用法

```dart
import 'package:flutter/material.dart';
import 'responsive_navigation_bar.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ResponsiveNavigationBar(
        user: User(displayText: '用户名'),
        onLogout: () => print('登出'),
        onNavigate: (index) => print('导航到页面 $index'),
        selectedIndex: 0,
        showLayoutToggle: true,
        onToggleLayout: () => print('切换布局'),
        isMinimalistLayout: false,
      ),
    );
  }
}
```

### 高级用法

```dart
ResponsiveNavigationBar(
  user: currentUser,
  onLogout: _handleLogout,
  onNavigate: _handleNavigation,
  selectedIndex: _currentIndex,
  showLayoutToggle: _shouldShowLayoutToggle(),
  onToggleLayout: _toggleLayout,
  isMinimalistLayout: _isMinimalistLayout,
)
```

## 平台适配策略

### Web端 (kIsWeb)
- **桌面尺寸**: WebExpandedNavigationBar
- **平板尺寸**: WebCompactNavigationBar
- **手机尺寸**: 移动端导航

### 移动端 (iOS/Android)
- **所有尺寸**: MobileNavigationShell + MobileDrawerMenu

### 桌面端 (Windows/macOS/Linux)
- **所有尺寸**: NavigationShell (现有组件)

## 文件结构

```
widgets/
├── responsive_navigation_bar.dart          # 响应式导航主组件
├── web_expanded_navigation_bar.dart       # Web端扩展导航栏
├── web_compact_navigation_bar.dart        # Web端紧凑导航栏
├── mobile_navigation_shell.dart           # 移动端导航外壳
├── mobile_drawer_menu.dart                # 移动端抽屉菜单
├── multi_platform_navigation_example.dart # 使用示例
└── README.md                              # 本文档
```

## 样式和设计原则

### 色彩系统
- **主色调**: Color(0xFF2563EB) -> Color(0xFF3B82F6) (蓝色渐变)
- **背景色**: 白色和浅灰色
- **文字色**: Color(0xFF1E293B) (深灰蓝色)
- **辅助色**: 各功能模块使用不同的强调色

### 交互设计
- **悬停效果**: Web端使用鼠标悬停状态
- **触觉反馈**: 移动端使用 HapticFeedback
- **动画过渡**: 使用流畅的动画切换
- **响应式**: 根据屏幕尺寸调整布局

### 可访问性
- **语义化**: 使用正确的语义组件
- **键盘导航**: 支持键盘操作
- **屏幕阅读器**: 提供适当的标签
- **对比度**: 符合WCAG对比度标准

## 扩展和自定义

### 添加新的导航项

```dart
final List<NavigationItem> customNavItems = [
  NavigationItem(
    icon: Icons.new_feature,
    selectedIcon: Icons.new_feature_active,
    label: '新功能',
    tooltip: '描述新功能',
    index: 5,
  ),
];
```

### 自定义主题

```dart
MaterialApp(
  theme: ThemeData(
    primarySwatch: Colors.blue,
    // 自定义导航样式
    navigationBarTheme: NavigationBarThemeData(
      // ... 自定义配置
    ),
  ),
  home: ResponsiveNavigationBar(...),
)
```

### 平台特定功能

```dart
if (kIsWeb) {
  // Web端特定功能
  return WebSpecificFeature();
} else if (Platform.isIOS) {
  // iOS特定功能
  return IOSSpecificFeature();
}
```

## 测试

示例应用 `MultiPlatformNavigationExample` 可以用来测试不同平台和屏幕尺寸下的导航表现。

### 测试方法
1. 在不同设备上运行应用
2. 使用浏览器开发者工具模拟不同屏幕尺寸
3. 使用Flutter的设备模拟器测试移动端体验
4. 在桌面平台上测试桌面端导航

## 未来规划

- [ ] 添加更多平台支持 (如Flutter Web、Flutter Desktop)
- [ ] 实现更丰富的动画效果
- [ ] 添加主题切换功能
- [ ] 优化性能和内存使用
- [ ] 添加更多的快捷操作
- [ ] 支持自定义导航栏样式
- [ ] 实现导航历史和面包屑
- [ ] 添加无障碍功能增强

## 贡献指南

如需修改或扩展这些组件，请遵循以下原则：

1. **保持响应式设计**: 确保新功能在不同平台上都能正常工作
2. **遵循设计系统**: 使用统一的颜色、字体和间距
3. **编写测试**: 为新功能添加相应的测试用例
4. **更新文档**: 及时更新README和相关文档
5. **考虑性能**: 注意动画和渲染性能

## 许可证

这些组件遵循项目的整体许可证协议。