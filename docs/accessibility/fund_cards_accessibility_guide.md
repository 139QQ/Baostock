# 基金卡片组件无障碍性使用指南

## 概述

本指南详细介绍智能基金卡片组件的无障碍性支持，确保所有用户，包括使用辅助技术的用户，都能充分使用基金分析功能。

## 无障碍性标准

### 🎯 符合标准

本组件严格遵循以下无障碍性标准：

- **WCAG 2.1 AA**: Web Content Accessibility Guidelines 2.1 AA级别
- **Flutter 无障碍性指南**: Google Flutter 官方无障碍性最佳实践
- **屏幕阅读器兼容**: 支持NVDA、JAWS、TalkBack等主流屏幕阅读器
- **键盘导航完整**: 完整的键盘操作支持

### 📋 核心无障碍性特性

1. **语义化标签**: 所有交互元素都有适当的语义标签
2. **屏幕阅读器支持**: 完整的语音播报功能
3. **键盘导航**: Tab键导航和快捷键支持
4. **高对比度**: 支持系统高对比度模式
5. **焦点管理**: 清晰的焦点指示和逻辑顺序

## 无障碍性功能详解

### 1. 语义化支持

#### 基金卡片语义结构
```dart
Semantics(
  label: '基金卡片：${fund.name}，基金代码：${fund.code}',
  hint: '点击查看详细信息，左右滑动可快速操作',
  child: Card(
    child: _buildCardContent(),
  ),
)
```

#### 收藏按钮语义标签
```dart
Semantics(
  button: true,
  label: fund.isFavorite ? '取消收藏基金' : '收藏基金',
  hint: fund.isFavorite ? '点击从收藏列表中移除' : '点击添加到收藏列表',
  child: IconButton(
    icon: Icon(fund.isFavorite ? Icons.favorite : Icons.favorite_border),
    onPressed: _toggleFavorite,
  ),
)
```

#### 对比按钮语义标签
```dart
Semantics(
  button: true,
  label: '基金对比',
  hint: fund.isInComparison ? '点击从对比列表中移除' : '点击添加到对比列表',
  selected: fund.isInComparison,
  child: IconButton(
    icon: Icon(Icons.compare_arrows),
    onPressed: _toggleComparison,
  ),
)
```

### 2. 屏幕阅读器支持

#### 收益率播报
```dart
Semantics(
  label: _buildAccessibilityReturnRateLabel(),
  liveRegion: true,  // 实时播报数值变化
  child: AnimatedSwitcher(
    duration: const Duration(milliseconds: 300),
    child: Text(
      _formatReturnRate(fund.returnRate),
      key: ValueKey(fund.returnRate),
    ),
  ),
)

String _buildAccessibilityReturnRateLabel() {
  final returnRate = fund.returnRate;
  final percentage = (returnRate * 100).toStringAsFixed(2);
  final sign = returnRate >= 0 ? '上涨' : '下跌';
  return '收益率：${percentage}%，${sign}${percentage.abs()}个百分点';
}
```

#### 基金信息播报
```dart
String _buildFundAccessibilityInfo() {
  final buffer = StringBuffer();
  buffer.writeln('基金名称：${fund.name}');
  buffer.writeln('基金代码：${fund.code}');
  buffer.writeln('基金类型：${fund.type}');
  buffer.writeln('收益率：${(fund.returnRate * 100).toStringAsFixed(2)}%');

  if (fund.riskLevel != null) {
    buffer.writeln('风险等级：${fund.riskLevel}');
  }

  if (fund.isFavorite) {
    buffer.writeln('已收藏');
  }

  if (fund.isInComparison) {
    buffer.writeln('已加入对比');
  }

  return buffer.toString();
}
```

### 3. 键盘导航支持

#### 焦点管理
```dart
class _FundCardState extends State<FundCard> {
  final FocusNode _cardFocusNode = FocusNode();
  final FocusNode _favoriteFocusNode = FocusNode();
  final FocusNode _comparisonFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _cardFocusNode,
      onKey: _handleKeyPress,
      child: Card(
        child: _buildCardContent(),
      ),
    );
  }

  KeyEventResult _handleKeyPress(FocusNode node, RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        _onCardTap();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.space) {
        _onCardTap();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _favoriteFocusNode.requestFocus();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _comparisonFocusNode.requestFocus();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }
}
```

#### 快捷键支持
```dart
Map<LogicalKeyboardKey, VoidCallback> _shortcuts = {
  LogicalKeyboardKey.keyF: () => _toggleFavorite(),
  LogicalKeyboardKey.keyC: () => _toggleComparison(),
  LogicalKeyboardKey.enter: () => _onCardTap(),
  LogicalKeyboardKey.space: () => _onCardTap(),
  LogicalKeyboardKey.arrowRight: () => _navigateToNext(),
  LogicalKeyboardKey.arrowLeft: () => _navigateToPrevious(),
};
```

### 4. 高对比度支持

#### 自适应颜色方案
```dart
Color _getAdaptiveColor(BuildContext context, Color normalColor, Color darkColor) {
  final isHighContrast = MediaQuery.of(context).highContrast;
  final theme = Theme.of(context);

  if (isHighContrast) {
    return theme.brightness == Brightness.dark
        ? darkColor
        : normalColor;
  }

  return normalColor;
}

// 使用示例
Container(
  decoration: BoxDecoration(
    color: _getAdaptiveColor(
      context,
      Colors.grey[100]!,
      Colors.grey[800]!,
    ),
    border: Border.all(
      color: _getAdaptiveColor(
        context,
        Colors.grey[300]!,
        Colors.grey[600]!,
      ),
    ),
  ),
  child: _buildContent(),
)
```

### 5. 动画无障碍性

#### 减少动画模式
```dart
class _FundCardState extends State<FundCard> {
  late bool _reduceAnimations;

  @override
  void initState() {
    super.initState();
    _reduceAnimations = MediaQuery.of(context).accessibleNavigation;
  }

  Widget _buildAnimatedContent() {
    if (_reduceAnimations) {
      // 无动画版本
      return _buildStaticContent();
    } else {
      // 动画版本
      return AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return _buildAnimatedContent();
        },
      );
    }
  }
}
```

## 测试和验证

### 1. 无障碍性测试清单

#### 基础测试项
- [ ] 所有交互元素都有语义标签
- [ ] 屏幕阅读器能正确播报所有信息
- [ ] 键盘导航覆盖所有功能
- [ ] 焦点指示清晰可见
- [ ] 高对比度模式正常显示

#### 高级测试项
- [ ] 动画在无障碍模式下适当减少
- [ ] 实时数值变化能正确播报
- [ ] 语义标签描述准确且简洁
- [ ] 焦点顺序逻辑合理
- [ ] 快捷键功能正常

### 2. 测试工具和方法

#### Flutter 无障碍性检查
```dart
// 启用无障碍性调试
MaterialApp(
  debugShowCheckedModeBanner: true,
  builder: (context, child) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        accessibleNavigation: true,
        disableAnimations: true,
        highContrast: true,
      ),
      child: child!,
    );
  },
  home: FundListPage(),
)
```

#### 屏幕阅读器测试
```bash
# Windows 测试
# 1. 安装并启动 NVDA (https://www.nvaccess.org/)
# 2. 启动应用
# 3. 使用 Tab 键导航
# 4. 验证语音播报内容

# Android 测试
# 1. 启用 TalkBack
# 2. 打开应用
# 3. 使用手指滑动导航
# 4. 验证语音反馈
```

#### 键盘导航测试
```dart
// 自动化键盘导航测试
testWidgets('基金卡片键盘导航测试', (WidgetTester tester) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: FundCard(fund: sampleFund),
    ),
  ));

  // Tab 键导航到卡片
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pump();

  // 验证焦点
  expect(finder.byType(Focus), findsOneWidget);

  // Enter 键点击
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.pump();

  // 验证导航事件
  verify(mockNavigator.push(any)).called(1);
});
```

## 用户指南

### 1. 屏幕阅读器用户

#### 导航操作
- **Tab键**: 在元素间移动焦点
- **Shift+Tab**: 反向移动焦点
- **Enter/Space**: 激活当前元素
- **箭头键**: 在列表中导航

#### 语音播报内容
每张基金卡片会播报以下信息：
- 基金名称和代码
- 当前收益率和涨跌状态
- 是否已收藏
- 是否已加入对比
- 可用的操作提示

### 2. 键盘用户

#### 快捷键操作
- **F**: 切换收藏状态
- **C**: 切换对比状态
- **Enter/Space**: 查看详细信息
- **←/→**: 在卡片间导航
- **↑/↓**: 在列表中滚动

#### 焦点指示
当前焦点元素会有明显的视觉指示，通常是边框高亮或背景色变化。

### 3. 视觉障碍用户

#### 高对比度模式
系统会自动检测高对比度设置并调整颜色方案：
- 增强边框对比度
- 使用更鲜明的颜色
- 增大字体和图标尺寸

#### 字体缩放
应用支持系统字体缩放设置：
```dart
Text(
  fund.name,
  style: Theme.of(context).textTheme.titleLarge?.copyWith(
    fontSize: MediaQuery.of(context).textScaleFactor * 18,
  ),
)
```

## 开发者指南

### 1. 集成最佳实践

#### 基础集成
```dart
// ✅ 推荐：完整无障碍性实现
AdaptiveFundCard(
  fund: fund,
  semanticLabel: '基金卡片：${fund.name}',
  onTap: () => _navigateToDetail(fund),
  onFavoriteToggle: () => _toggleFavorite(fund),
  onComparisonToggle: () => _toggleComparison(fund),
)

// ✅ 推荐：键盘导航支持
Shortcuts(
  shortcuts: {
    LogicalKeyboardKey.keyF: const Intent(ActivateIntent()),
    LogicalKeyboardKey.keyC: const Intent(ActivateIntent()),
  },
  child: Actions(
    actions: {
      ActivateIntent: CallbackAction<ActivateIntent>(
        onInvoke: (intent) => _handleShortcut(intent.logicalKey),
      ),
    },
    child: AdaptiveFundCard(fund: fund),
  ),
)
```

#### 列表集成
```dart
// ✅ 推荐：列表中的无障碍性优化
ListView.builder(
  itemCount: funds.length,
  itemBuilder: (context, index) {
    return Semantics(
      index: index,
      child: AdaptiveFundCard(
        fund: funds[index],
        // 设置唯一的语义标签
        semanticLabel: '第${index + 1}个基金：${funds[index].name}',
      ),
    );
  },
)
```

### 2. 测试集成

#### 单元测试
```dart
testWidgets('基金卡片无障碍性测试', (WidgetTester tester) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: AdaptiveFundCard(fund: sampleFund),
    ),
  ));

  // 检查语义标签
  expect(
    tester.semantics(find.byType(FundCard)),
    matchesSemantics(
      label: contains('基金卡片'),
      hasTapAction: true,
    ),
  );
});
```

#### 集成测试
```dart
testWidgets('键盘导航集成测试', (WidgetTester tester) async {
  await tester.pumpWidget(MaterialApp(
    home: FundListPage(funds: sampleFunds),
  ));

  // 使用键盘导航整个列表
  for (int i = 0; i < sampleFunds.length; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(finder.byType(Focus), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    verify(mockNavigator.push(any)).called(1);
  }
});
```

### 3. 调试和诊断

#### 无障碍性检查工具
```dart
// 在调试模式下显示无障碍性信息
class AccessibilityOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    return Positioned(
      top: 10,
      left: 10,
      child: Container(
        padding: const EdgeInsets.all(8),
        color: Colors.black87,
        child: StreamBuilder<MediaQueryData>(
          stream: _mediaQueryStream,
          builder: (context, snapshot) {
            return Text(
              '无障碍性状态：\n'
              '高对比度：${snapshot.data?.highContrast ?? false}\n'
              '减少动画：${snapshot.data?.accessibleNavigation ?? false}\n'
              '字体缩放：${snapshot.data?.textScaleFactor ?? 1.0}',
              style: const TextStyle(color: Colors.white),
            );
          },
        ),
      ),
    );
  }
}
```

## 故障排除

### 常见问题及解决方案

#### 1. 语义标签不显示
**症状**: 屏幕阅读器无法播报内容
**原因**: 缺少语义标签或标签为空
**解决方案**:
```dart
// ✅ 正确：添加语义标签
Semantics(
  label: '基金卡片：${fund.name}',
  child: Card(...),
)

// ❌ 错误：没有语义标签
Card(...) // 屏幕阅读器无法识别
```

#### 2. 键盘导航不工作
**症状**: Tab键无法聚焦元素
**原因**: 元素不是可聚焦的
**解决方案**:
```dart
// ✅ 正确：使元素可聚焦
Focus(
  focusNode: _focusNode,
  child: ElevatedButton(...),
)

// ❌ 错误：容器不可聚焦
Container(child: ElevatedButton(...))
```

#### 3. 动画影响无障碍性
**症状**: 动画过快影响屏幕阅读器
**原因**: 没有检测无障碍性设置
**解决方案**:
```dart
// ✅ 正确：检测无障碍性设置
final shouldReduceAnimations = MediaQuery.of(context).accessibleNavigation;
final animationDuration = shouldReduceAnimations ? Duration.zero : Duration(milliseconds: 300);
```

### 性能影响

#### 无障碍性性能优化
- 使用`RepaintBoundary`隔离无障碍性组件
- 避免过度复杂的语义树结构
- 合理使用`liveRegion`，避免过多实时播报

```dart
// ✅ 推荐：优化的无障碍性实现
RepaintBoundary(
  child: Semantics(
    label: _cachedLabel, // 使用缓存的标签
    liveRegion: _shouldLiveRegion, // 条件性实时播报
    child: _buildContent(),
  ),
)
```

## 总结

智能基金卡片组件的无障碍性支持确保了：

1. **包容性**: 所有用户都能使用基金分析功能
2. **标准合规**: 符合WCAG 2.1 AA级别标准
3. **功能完整**: 所有功能都有相应的无障碍性支持
4. **性能优化**: 无障碍性功能不影响应用性能
5. **易于维护**: 清晰的代码结构和完整的测试覆盖

通过遵循本指南，开发者可以创建出真正包容性的用户界面，为所有用户提供优秀的使用体验。