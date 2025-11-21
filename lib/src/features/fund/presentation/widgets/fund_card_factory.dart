import 'package:flutter/material.dart';
import '../../domain/entities/fund.dart';
import 'cards/adaptive_fund_card.dart';
import 'cards/base_fund_card.dart';
import 'cards/performance_detector_adapter.dart';
import '../../../../core/performance/performance_detector.dart';

/// 基金卡片工厂类
///
/// 提供统一的卡片创建接口，简化使用方式：
/// - 自动性能检测和配置
/// - 预设样式配置
/// - 批量创建支持
/// - 主题适配
class FundCardFactory {
  /// 创建标准基金卡片
  static Widget createStandard({
    Key? key,
    required Fund fund,
    bool showComparisonCheckbox = false,
    bool showQuickActions = true,
    bool isSelected = false,
    bool compactMode = false,
    VoidCallback? onTap,
    Function(bool)? onSelectionChanged,
    VoidCallback? onAddToWatchlist,
    VoidCallback? onCompare,
    VoidCallback? onShare,
    Function()? onSwipeLeft,
    Function()? onSwipeRight,
  }) {
    return AdaptiveFundCard(
      key: key,
      fund: fund,
      showComparisonCheckbox: showComparisonCheckbox,
      showQuickActions: showQuickActions,
      isSelected: isSelected,
      compactMode: compactMode,
      onTap: onTap,
      onSelectionChanged: onSelectionChanged,
      onAddToWatchlist: onAddToWatchlist,
      onCompare: onCompare,
      onShare: onShare,
      onSwipeLeft: onSwipeLeft,
      onSwipeRight: onSwipeRight,
    );
  }

  /// 创建简约风格卡片
  static Widget createMinimal({
    Key? key,
    required Fund fund,
    bool showComparisonCheckbox = false,
    bool showQuickActions = true,
    bool isSelected = false,
    bool compactMode = false,
    VoidCallback? onTap,
    Function(bool)? onSelectionChanged,
    VoidCallback? onAddToWatchlist,
    VoidCallback? onCompare,
    VoidCallback? onShare,
    Function()? onSwipeLeft,
    Function()? onSwipeRight,
  }) {
    return AdaptiveFundCard(
      key: key,
      fund: fund,
      showComparisonCheckbox: showComparisonCheckbox,
      showQuickActions: showQuickActions,
      isSelected: isSelected,
      compactMode: compactMode,
      onTap: onTap,
      onSelectionChanged: onSelectionChanged,
      onAddToWatchlist: onAddToWatchlist,
      onCompare: onCompare,
      onShare: onShare,
      onSwipeLeft: onSwipeLeft,
      onSwipeRight: onSwipeRight,
      forceAnimationLevel: AnimationLevel.disabled,
    );
  }

  /// 创建现代风格卡片
  static Widget createModern({
    Key? key,
    required Fund fund,
    bool showComparisonCheckbox = false,
    bool showQuickActions = true,
    bool isSelected = false,
    bool compactMode = false,
    VoidCallback? onTap,
    Function(bool)? onSelectionChanged,
    VoidCallback? onAddToWatchlist,
    VoidCallback? onCompare,
    VoidCallback? onShare,
    Function()? onSwipeLeft,
    Function()? onSwipeRight,
  }) {
    return AdaptiveFundCard(
      key: key,
      fund: fund,
      showComparisonCheckbox: showComparisonCheckbox,
      showQuickActions: showQuickActions,
      isSelected: isSelected,
      compactMode: compactMode,
      onTap: onTap,
      onSelectionChanged: onSelectionChanged,
      onAddToWatchlist: onAddToWatchlist,
      onCompare: onCompare,
      onShare: onShare,
      onSwipeLeft: onSwipeLeft,
      onSwipeRight: onSwipeRight,
      forceAnimationLevel: AnimationLevel.basic,
    );
  }

  /// 创建增强风格卡片（包含所有交互）
  static Widget createEnhanced({
    Key? key,
    required Fund fund,
    bool showComparisonCheckbox = false,
    bool showQuickActions = true,
    bool isSelected = false,
    bool compactMode = false,
    VoidCallback? onTap,
    Function(bool)? onSelectionChanged,
    VoidCallback? onAddToWatchlist,
    VoidCallback? onCompare,
    VoidCallback? onShare,
    Function()? onSwipeLeft,
    Function()? onSwipeRight,
  }) {
    return AdaptiveFundCard(
      key: key,
      fund: fund,
      showComparisonCheckbox: showComparisonCheckbox,
      showQuickActions: showQuickActions,
      isSelected: isSelected,
      compactMode: compactMode,
      onTap: onTap,
      onSelectionChanged: onSelectionChanged,
      onAddToWatchlist: onAddToWatchlist,
      onCompare: onCompare,
      onShare: onShare,
      onSwipeLeft: onSwipeLeft,
      onSwipeRight: onSwipeRight,
      forceAnimationLevel: AnimationLevel.enhanced,
    );
  }

  /// 创建自适应性能卡片
  static Widget createAdaptive({
    Key? key,
    required Fund fund,
    required BuildContext context,
    bool showComparisonCheckbox = false,
    bool showQuickActions = true,
    bool isSelected = false,
    bool compactMode = false,
    VoidCallback? onTap,
    Function(bool)? onSelectionChanged,
    VoidCallback? onAddToWatchlist,
    VoidCallback? onCompare,
    VoidCallback? onShare,
    Function()? onSwipeLeft,
    Function()? onSwipeRight,
  }) {
    final performanceDetector = PerformanceDetector();
    final performanceLevel = performanceDetector.getPerformanceLevel();

    // 根据性能级别选择合适的配置
    final animationLevel = _getAnimationLevelForPerformance(performanceLevel);

    return AdaptiveFundCard(
      key: key,
      fund: fund,
      showComparisonCheckbox: showComparisonCheckbox,
      showQuickActions: showQuickActions,
      isSelected: isSelected,
      compactMode: compactMode,
      onTap: onTap,
      onSelectionChanged: onSelectionChanged,
      onAddToWatchlist: onAddToWatchlist,
      onCompare: onCompare,
      onShare: onShare,
      onSwipeLeft: onSwipeLeft,
      onSwipeRight: onSwipeRight,
      forceAnimationLevel: animationLevel,
    );
  }

  /// 创建自定义配置卡片
  static Widget createCustom({
    Key? key,
    required Fund fund,
    required FundCardConfig config,
    bool showComparisonCheckbox = false,
    bool showQuickActions = true,
    bool isSelected = false,
    bool compactMode = false,
    VoidCallback? onTap,
    Function(bool)? onSelectionChanged,
    VoidCallback? onAddToWatchlist,
    VoidCallback? onCompare,
    VoidCallback? onShare,
    Function()? onSwipeLeft,
    Function()? onSwipeRight,
  }) {
    return AdaptiveFundCard(
      key: key,
      fund: fund,
      showComparisonCheckbox: showComparisonCheckbox,
      showQuickActions: showQuickActions,
      isSelected: isSelected,
      compactMode: compactMode,
      onTap: onTap,
      onSelectionChanged: onSelectionChanged,
      onAddToWatchlist: onAddToWatchlist,
      onCompare: onCompare,
      onShare: onShare,
      onSwipeLeft: onSwipeLeft,
      onSwipeRight: onSwipeRight,
      forceAnimationLevel: _getAnimationLevelFromConfig(config),
    );
  }

  /// 批量创建卡片列表
  static List<Widget> createList({
    required List<Fund> funds,
    required BuildContext context,
    CardStyle style = CardStyle.modern,
    bool showComparisonCheckbox = false,
    bool showQuickActions = true,
    Set<String>? selectedFunds,
    bool compactMode = false,
    Function(Fund, bool)? onSelectionChanged,
    Function(Fund)? onTap,
    Function(Fund)? onAddToWatchlist,
    Function(Fund)? onCompare,
    Function(Fund)? onShare,
    Function(Fund)? onSwipeLeft,
    Function(Fund)? onSwipeRight,
  }) {
    return funds.map((fund) {
      return createCustom(
        key: ValueKey(fund.code),
        fund: fund,
        config: FundCardConfig(
          animationLevel: _getAnimationLevelFromStyle(style).index,
          enableAnimations: true,
          enableHoverEffects: true,
          enableGestureFeedback: true,
        ),
        showComparisonCheckbox: showComparisonCheckbox,
        showQuickActions: showQuickActions,
        isSelected: selectedFunds?.contains(fund.code) ?? false,
        compactMode: compactMode,
        onTap: onTap != null ? () => onTap(fund) : null,
        onSelectionChanged: onSelectionChanged != null
            ? (selected) => onSelectionChanged(fund, selected)
            : null,
        onAddToWatchlist:
            onAddToWatchlist != null ? () => onAddToWatchlist(fund) : null,
        onCompare: onCompare != null ? () => onCompare(fund) : null,
        onShare: onShare != null ? () => onShare(fund) : null,
        onSwipeLeft: onSwipeLeft != null ? () => onSwipeLeft(fund) : null,
        onSwipeRight: onSwipeRight != null ? () => onSwipeRight(fund) : null,
      );
    }).toList();
  }

  /// 创建网格布局卡片
  static Widget createGrid({
    required List<Fund> funds,
    required BuildContext context,
    CardStyle style = CardStyle.modern,
    int crossAxisCount = 2,
    double childAspectRatio = 1.6,
    double crossAxisSpacing = 12.0,
    double mainAxisSpacing = 12.0,
    EdgeInsetsGeometry? padding,
    bool showQuickActions = true,
    Set<String>? selectedFunds,
    Function(Fund, bool)? onSelectionChanged,
    Function(Fund)? onTap,
    Function(Fund)? onAddToWatchlist,
    Function(Fund)? onCompare,
    Function(Fund)? onShare,
  }) {
    return Padding(
      padding: padding ?? const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
        ),
        itemCount: funds.length,
        itemBuilder: (context, index) {
          final fund = funds[index];
          return createCustom(
            key: ValueKey('grid_${fund.code}'),
            fund: fund,
            config: FundCardConfig(
              animationLevel: _getAnimationLevelFromStyle(style).index,
              enableAnimations: true,
              enableHoverEffects: true,
              enableGestureFeedback: true,
            ),
            showQuickActions: showQuickActions,
            isSelected: selectedFunds?.contains(fund.code) ?? false,
            compactMode: true, // 网格模式使用紧凑布局
            onTap: onTap != null ? () => onTap(fund) : null,
            onSelectionChanged: onSelectionChanged != null
                ? (selected) => onSelectionChanged(fund, selected)
                : null,
            onAddToWatchlist:
                onAddToWatchlist != null ? () => onAddToWatchlist(fund) : null,
            onCompare: onCompare != null ? () => onCompare(fund) : null,
            onShare: onShare != null ? () => onShare(fund) : null,
          );
        },
      ),
    );
  }

  /// 创建列表布局卡片
  static Widget createListview({
    required List<Fund> funds,
    required BuildContext context,
    CardStyle style = CardStyle.modern,
    bool showComparisonCheckbox = false,
    bool showQuickActions = true,
    Set<String>? selectedFunds,
    bool compactMode = false,
    EdgeInsetsGeometry? padding,
    Function(Fund, bool)? onSelectionChanged,
    Function(Fund)? onTap,
    Function(Fund)? onAddToWatchlist,
    Function(Fund)? onCompare,
    Function(Fund)? onShare,
    Function(Fund)? onSwipeLeft,
    Function(Fund)? onSwipeRight,
    Widget? separator,
  }) {
    return Padding(
      padding: padding ?? const EdgeInsets.all(16.0),
      child: ListView.separated(
        itemCount: funds.length,
        separatorBuilder: (context, index) =>
            separator ?? const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final fund = funds[index];
          return createCustom(
            key: ValueKey('list_${fund.code}'),
            fund: fund,
            config: FundCardConfig(
              animationLevel: _getAnimationLevelFromStyle(style).index,
              enableAnimations: true,
              enableHoverEffects: true,
              enableGestureFeedback: true,
            ),
            showComparisonCheckbox: showComparisonCheckbox,
            showQuickActions: showQuickActions,
            isSelected: selectedFunds?.contains(fund.code) ?? false,
            compactMode: compactMode,
            onTap: onTap != null ? () => onTap(fund) : null,
            onSelectionChanged: onSelectionChanged != null
                ? (selected) => onSelectionChanged(fund, selected)
                : null,
            onAddToWatchlist:
                onAddToWatchlist != null ? () => onAddToWatchlist(fund) : null,
            onCompare: onCompare != null ? () => onCompare(fund) : null,
            onShare: onShare != null ? () => onShare(fund) : null,
            onSwipeLeft: onSwipeLeft != null ? () => onSwipeLeft(fund) : null,
            onSwipeRight:
                onSwipeRight != null ? () => onSwipeRight(fund) : null,
          );
        },
      ),
    );
  }

  /// 根据性能级别获取动画级别
  static AnimationLevel _getAnimationLevelForPerformance(PerformanceLevel level) {
    switch (level) {
      case PerformanceLevel.excellent:
        return AnimationLevel.enhanced;
      case PerformanceLevel.good:
        return AnimationLevel.basic;
      case PerformanceLevel.fair:
        return AnimationLevel.disabled;
      case PerformanceLevel.poor:
        return AnimationLevel.disabled;
    }
  }

  /// 根据样式获取动画级别
  static AnimationLevel _getAnimationLevelFromStyle(CardStyle style) {
    switch (style) {
      case CardStyle.minimal:
        return AnimationLevel.disabled;
      case CardStyle.modern:
        return AnimationLevel.basic;
      case CardStyle.enhanced:
        return AnimationLevel.enhanced;
    }
  }

  /// 从配置获取动画级别
  static AnimationLevel _getAnimationLevelFromConfig(FundCardConfig config) {
    return AnimationLevel.values[config.animationLevel.clamp(0, AnimationLevel.values.length - 1)];
  }
}

/// 主题适配器
class FundCardThemeAdapter {
  /// 根据当前主题创建配置
  static FundCardConfig createThemeConfig(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FundCardConfig(
      animationLevel: isDark ? 0 : 1, // 暗色主题减少动画
      enableAnimations: !isDark,
      enableHoverEffects: true,
      enableGestureFeedback: true,
      enablePerformanceMonitoring: true,
    );
  }

  /// 创建Material 3风格配置
  static FundCardConfig createMaterial3Config(BuildContext context) {
    return FundCardConfig(
      animationLevel: 2,
      enableAnimations: true,
      enableHoverEffects: true,
      enableGestureFeedback: true,
      enablePerformanceMonitoring: true,
    );
  }

  /// 创建iOS风格配置
  static FundCardConfig createIosConfig(BuildContext context) {
    return FundCardConfig(
      animationLevel: 1,
      enableAnimations: true,
      enableHoverEffects: false, // iOS风格减少悬停效果
      enableGestureFeedback: true,
    );
  }
}