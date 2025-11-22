# 基金卡片组件使用示例与最佳实践指南

## 概述

本指南提供基速基金量化分析平台基金卡片组件的详细使用示例和最佳实践，帮助开发者快速上手并正确使用组件系统。

## 快速开始

### 基础用法

最简单的基金卡片使用方式：

```dart
import 'package:baostock/src/features/fund/presentation/widgets/cards/fund_card_factory.dart';

// 创建基本的自适应卡片
FundCardFactory.createFundCard(
  fund: fundInfo,
  cardType: FundCardType.adaptive,
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => FundDetailPage(fund: fundInfo)),
  ),
)
```

## 使用场景示例

### 场景1：基金搜索结果列表

适用于基金搜索结果展示，支持快速浏览和基础操作。

```dart
class FundSearchResults extends StatelessWidget {
  final List<Fund> funds;

  const FundSearchResults({super.key, required this.funds});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: funds.length,
      itemBuilder: (context, index) {
        final fund = funds[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: FundCardFactory.createFundCard(
            fund: fund,
            cardType: FundCardType.adaptive,
            onTap: () => _navigateToFundDetail(fund),
            onAddToWatchlist: () => _addToWatchlist(fund),
            config: FundCardConfig(
              animationLevel: 1, // 基础动画，列表滚动性能优化
              enableHoverEffects: true,
              cardStyle: CardStyle.modern,
            ),
          ),
        );
      },
    );
  }

  void _navigateToFundDetail(Fund fund) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FundDetailPage(fund: fund)),
    );
  }

  void _addToWatchlist(Fund fund) {
    context.read<WatchlistCubit>().addToWatchlist(fund);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已添加 ${fund.name} 到自选')),
    );
  }
}
```

**最佳实践**：
- 使用 `animationLevel: 1` 优化列表滚动性能
- 启用悬停效果提升桌面端体验
- 提供清晰的导航和反馈

### 场景2：自选基金管理

支持复选框选择和批量操作的基金管理界面。

```dart
class WatchlistManager extends StatefulWidget {
  const WatchlistManager({super.key});

  @override
  State<WatchlistManager> createState() => _WatchlistManagerState();
}

class _WatchlistManagerState extends State<WatchlistManager> {
  final Set<String> _selectedFunds = {};
  bool _isSelectionMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode ? '已选择 ${_selectedFunds.length}' : '我的自选'),
        actions: [
          IconButton(
            icon: Icon(_isSelectionMode ? Icons.close : Icons.checklist),
            onPressed: _toggleSelectionMode,
          ),
          if (_selectedFunds.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: _handleBatchAction,
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'compare', child: Text('批量对比')),
                const PopupMenuItem(value: 'remove', child: Text('移除自选')),
              ],
            ),
        ],
      ),
      body: BlocBuilder<WatchlistCubit, WatchlistState>(
        builder: (context, state) {
          if (state is WatchlistLoaded) {
            return ListView.builder(
              itemCount: state.funds.length,
              itemBuilder: (context, index) {
                final fund = state.funds[index];
                final isSelected = _selectedFunds.contains(fund.code);

                return FundCardFactory.createFundCard(
                  fund: fund,
                  cardType: FundCardType.adaptive,
                  onTap: () => _isSelectionMode
                      ? _toggleSelection(fund.code)
                      : _navigateToDetail(fund),
                  onAddToWatchlist: () => _removeFromWatchlist(fund),
                  onCompare: () => _addToComparison(fund),
                  showComparisonCheckbox: _isSelectionMode,
                  isSelected: isSelected,
                  onSelectionChanged: (selected) => _toggleSelection(fund.code),
                  config: FundCardConfig(
                    animationLevel: 0, // 选择模式下禁用动画提升性能
                    enableHoverEffects: !_isSelectionMode,
                    cardStyle: CardStyle.modern,
                  ),
                );
              },
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) _selectedFunds.clear();
    });
  }

  void _toggleSelection(String fundCode) {
    setState(() {
      if (_selectedFunds.contains(fundCode)) {
        _selectedFunds.remove(fundCode);
      } else {
        _selectedFunds.add(fundCode);
      }
    });
  }

  void _handleBatchAction(String action) {
    switch (action) {
      case 'compare':
        _compareSelectedFunds();
        break;
      case 'remove':
        _removeSelectedFunds();
        break;
    }
  }

  void _compareSelectedFunds() {
    final selectedFunds = context.read<WatchlistCubit>().state.funds
        .where((fund) => _selectedFunds.contains(fund.code))
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FundComparisonPage(funds: selectedFunds),
      ),
    );
  }
}
```

**最佳实践**：
- 使用复选框模式支持批量操作
- 在选择模式下禁用动画提升性能
- 提供清晰的状态反馈和操作提示
- 使用Bloc管理状态，确保数据一致性

### 场景3：微交互增强的基金推荐

使用MicrointeractiveFundCard提供丰富的交互体验。

```dart
class FundRecommendationCarousel extends StatefulWidget {
  final List<Fund> recommendedFunds;

  const FundRecommendationCarousel({super.key, required this.recommendedFunds});

  @override
  State<FundRecommendationCarousel> createState() => _FundRecommendationCarouselState();
}

class _FundRecommendationCarouselState extends State<FundRecommendationCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.9);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.recommend, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                '为您推荐',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _refreshRecommendations,
                child: const Text('刷新'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.recommendedFunds.length,
            itemBuilder: (context, index) {
              final fund = widget.recommendedFunds[index];
              return MicrointeractiveFundCard(
                fund: fund,
                onTap: () => _navigateToDetail(fund),
                onAddToWatchlist: () => _addToWatchlist(fund),
                onCompare: () => _addToComparison(fund),
                gestureConfig: GestureConfig(
                  enableSwipeLeft: true,
                  enableSwipeRight: true,
                  enableHapticFeedback: true,
                  swipeThreshold: 50.0,
                  onSwipeLeft: () => _addToWatchlistWithFeedback(fund),
                  onSwipeRight: () => _addToComparisonWithFeedback(fund),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _addToWatchlistWithFeedback(Fund fund) {
    context.read<WatchlistCubit>().addToWatchlist(fund);
    _showSuccessFeedback('已添加 ${fund.name} 到自选');
  }

  void _addToComparisonWithFeedback(Fund fund) {
    context.read<ComparisonCubit>().addToComparison(fund);
    _showSuccessFeedback('已添加 ${fund.name} 到对比');
  }

  void _showSuccessFeedback(String message) {
    // 触觉反馈
    HapticFeedback.lightImpact();

    // 视觉反馈
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: '查看',
          onPressed: () {
            // 导航到相关页面
          },
        ),
      ),
    );
  }

  void _refreshRecommendations() {
    context.read<RecommendationCubit>().refreshRecommendations();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
```

**最佳实践**：
- 使用手势操作增强用户体验
- 提供触觉反馈提升交互感知
- 结合PageView创建轮播效果
- 提供清晰的操作反馈

### 场景4：性能优化的大列表展示

针对大量数据的性能优化展示。

```dart
class OptimizedFundList extends StatefulWidget {
  final List<Fund> funds;

  const OptimizedFundList({super.key, required this.funds});

  @override
  State<OptimizedFundList> createState() => _OptimizedFundListState();
}

class _OptimizedFundListState extends State<OptimizedFundList>
    with ComponentMonitorMixin {

  @override
  String get componentKey => 'OptimizedFundList';

  @override
  Widget build(BuildContext context) {
    return monitoredBuild(context, () {
      return NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: ListView.builder(
          itemCount: widget.funds.length,
          cacheExtent: 500, // 预缓存范围
          itemBuilder: (context, index) {
            final fund = widget.funds[index];

            return FundCardFactory.createFundCard(
              fund: fund,
              cardType: FundCardType.adaptive,
              onTap: () => _navigateToDetail(fund),
              onAddToWatchlist: () => _addToWatchlist(fund),
              config: FundCardConfig(
                animationLevel: _getAnimationLevel(),
                enableHoverEffects: true,
                enablePerformanceMonitoring: kDebugMode, // 仅调试模式启用监控
                cardStyle: CardStyle.modern,
              ),
            );
          },
        ),
      );
    });
  }

  int _getAnimationLevel() {
    // 根据设备性能动态调整动画级别
    final deviceScore = DevicePerformanceDetector.instance.getScore();
    if (deviceScore < 40) return 0;      // 低性能设备禁用动画
    if (deviceScore < 70) return 1;      // 中等性能设备基础动画
    return 2;                            // 高性能设备完整动画
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      // 快速滚动时降低动画级别
      if (notification.metrics.pixelsPerSecond.abs() > 800) {
        _updateAnimationLevel(0);
      } else {
        _updateAnimationLevel(_getAnimationLevel());
      }
    }
    return false;
  }

  void _updateAnimationLevel(int level) {
    // 动态更新动画级别（实际实现可能需要更复杂的逻辑）
    setState(() {});
  }

  void _addToWatchlist(Fund fund) {
    // 批量操作节流
    _debouncedAction(() {
      context.read<WatchlistCubit>().addToWatchlist(fund);
    });
  }

  void _debouncedAction(VoidCallback action) {
    // 实现防抖逻辑，避免快速操作导致的性能问题
    // 实际项目中可以使用timer或Stream.debounce
    action.call();
  }
}
```

**最佳实践**：
- 使用性能监控组件监控渲染性能
- 根据设备性能动态调整动画级别
- 滚动时自动降低动画复杂度
- 实现操作防抖避免性能问题
- 合理设置缓存范围

## 高级用法

### 1. 自定义卡片配置

```dart
class CustomFundCardExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FundCardFactory.createFundCard(
      fund: fund,
      cardType: FundCardType.adaptive,
      config: FundCardConfig(
        animationLevel: 2,                    // 完整动画
        enableAnimations: true,
        enableHoverEffects: true,
        enableGestureFeedback: true,
        enablePerformanceMonitoring: kDebugMode,
        cardStyle: CardStyle.enhanced,
        customTheme: FundCardTheme(
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 4.0,
          borderRadius: BorderRadius.circular(16),
          padding: EdgeInsets.all(16),
        ),
      ),
    );
  }
}
```

### 2. 批量创建和缓存优化

```dart
class BatchFundCardCreationExample extends StatelessWidget {
  final List<Fund> funds;

  const BatchFundCardCreationExample({super.key, required this.funds});

  @override
  Widget build(BuildContext context) {
    // 预热缓存
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FundCardFactory.warmupCache(funds);
    });

    return Column(
      children: [
        Text('基金列表 (${funds.length})'),
        const SizedBox(height: 16),
        ...funds.map((fund) =>
          FundCardFactory.createFundCard(
            fund: fund,
            cardType: FundCardType.adaptive,
            config: FundCardConfig(
              animationLevel: 1, // 批量展示时使用基础动画
              enablePerformanceMonitoring: false, // 批量操作时关闭监控
            ),
          )
        ).toList(),
      ],
    );
  }
}
```

### 3. 主题集成

```dart
class ThemedFundCardExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FundCardFactory.createFundCard(
      fund: fund,
      cardType: FundCardType.adaptive,
      config: FundCardConfig(
        cardStyle: CardStyle.modern,
        customTheme: FundCardTheme(
          backgroundColor: theme.colorScheme.primaryContainer,
          textColor: theme.colorScheme.onPrimaryContainer,
          positiveColor: theme.colorScheme.primary,
          negativeColor: theme.colorScheme.error,
          elevation: theme.cardTheme.elevation ?? 2.0,
          borderRadius: theme.cardTheme.shape != null
              ? (theme.cardTheme.shape as RoundedRectangleBorder).borderRadius
              : BorderRadius.circular(12),
        ),
      ),
    );
  }
}
```

## 性能优化指南

### 1. 动画级别选择

| 场景 | 推荐动画级别 | 说明 |
|------|-------------|------|
| 大列表(>50项) | 0-1 | 减少动画提升滚动性能 |
| 卡片轮播 | 1-2 | 提升视觉体验 |
| 搜索结果 | 1 | 平衡性能和体验 |
| 设备性能差 | 0 | 确保基础功能 |

### 2. 缓存策略

```dart
// 应用启动时预热常用卡片
class AppInitializationService {
  static Future<void> initializeFundCards() async {
    // 预加载用户常用基金类型的卡片
    final commonFundTypes = [FundType.stock, FundType.bond, FundType.mixed];

    for (final type in commonFundTypes) {
      final sampleFund = Fund.sample(type: type);
      FundCardFactory.createFundCard(
        fund: sampleFund,
        cardType: FundCardType.adaptive,
      );
    }

    // 优化缓存
    FundCardFactory.optimizeCache();
  }
}
```

### 3. 内存管理

```dart
class MemoryOptimizedFundList extends StatefulWidget {
  @override
  State<MemoryOptimizedFundList> createState() => _MemoryOptimizedFundListState();
}

class _MemoryOptimizedFundListState extends State<MemoryOptimizedFundList>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    FundCardFactory.clearCache(); // 清理缓存
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        // 应用暂停时优化缓存
        FundCardFactory.optimizeCache();
        break;
      case AppLifecycleState.detached:
        // 应用销毁时清理缓存
        FundCardFactory.clearCache();
        break;
      default:
        break;
    }
  }
}
```

## 测试指南

### 1. 单元测试

```dart
void main() {
  group('FundCardFactory', () {
    testWidgets('创建自适应卡片', (WidgetTester tester) async {
      final fund = Fund.sample();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FundCardFactory.createFundCard(
              fund: fund,
              cardType: FundCardType.adaptive,
            ),
          ),
        ),
      );

      expect(find.byType(AdaptiveFundCard), findsOneWidget);
      expect(find.text(fund.name), findsOneWidget);
    });

    testWidgets('测试点击事件', (WidgetTester tester) async {
      bool tapped = false;
      final fund = Fund.sample();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FundCardFactory.createFundCard(
              fund: fund,
              cardType: FundCardType.adaptive,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AdaptiveFundCard));
      expect(tapped, isTrue);
    });
  });
}
```

### 2. 性能测试

```dart
void main() {
  group('FundCard Performance', () {
    testWidgets('大量卡片渲染性能', (WidgetTester tester) async {
      final funds = List.generate(100, (index) => Fund.sample(index: index));

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: funds.length,
              itemBuilder: (context, index) => FundCardFactory.createFundCard(
                fund: funds[index],
                cardType: FundCardType.adaptive,
                config: FundCardConfig(animationLevel: 0), // 禁用动画测试基础性能
              ),
            ),
          ),
        ),
      );

      stopwatch.stop();

      // 验证渲染时间 < 1秒
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      expect(find.byType(AdaptiveFundCard), findsNWidgets(100));
    });
  });
}
```

## 常见问题与解决方案

### Q: 如何处理网络图片加载失败？

```dart
FundCardFactory.createFundCard(
  fund: fund,
  cardType: FundCardType.adaptive,
  config: FundCardConfig(
    errorBuilder: (context, error, stackTrace) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.broken_image, color: Colors.grey),
      );
    },
  ),
)
```

### Q: 如何自定义卡片布局？

```dart
class CustomFundCard extends BaseFundCard {
  const CustomFundCard({super.key, required super.fund});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          // 自定义头部
          _buildCustomHeader(),

          // 基金信息
          Expanded(child: _buildFundInfo()),

          // 自定义操作区
          _buildCustomActions(),
        ],
      ),
    );
  }
}
```

### Q: 如何实现无障碍支持？

```dart
FundCardFactory.createFundCard(
  fund: fund,
  cardType: FundCardType.adaptive,
  config: FundCardConfig(
    semanticLabel: '${fund.name}基金，代码${fund.code}，${fund.fundType}',
    semanticHint: '点击查看详情，长按添加到自选',
  ),
)
```

## 总结

通过本指南，开发者应该能够：

1. **快速上手**: 使用基础API快速创建基金卡片
2. **场景应用**: 根据不同需求选择合适的卡片类型和配置
3. **性能优化**: 掌握动画级别、缓存策略和内存管理
4. **测试验证**: 编写有效的单元测试和性能测试
5. **问题解决**: 处理常见问题和边界情况

### 核心原则

- **渐进增强**: 基础功能优先，增强特性可选
- **性能第一**: 根据设备能力动态调整复杂度
- **用户体验**: 提供清晰的反馈和流畅的交互
- **代码质量**: 遵循统一接口和最佳实践

---

**文档版本**: v1.0.0
**创建日期**: 2025-11-21
**对应故事**: R.4 组件架构重构
**维护状态**: 活跃维护