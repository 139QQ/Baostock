import 'package:flutter/material.dart';

import '../../domain/entities/fund_ranking.dart';
import 'fund_ranking_card.dart';
import 'performance_monitor.dart';
import '../../../../core/theme/app_theme.dart' hide PerformanceLevel;

/// 增强版基金排行榜卡片
///
/// 集成了毛玻璃效果和性能监控：
/// - 自适应性能优化
/// - 自动降级机制
/// - 性能监控和报告
/// - 主题适配
class EnhancedFundRankingCard extends StatefulWidget {
  /// 排行榜数据
  final FundRanking ranking;

  /// 排名位置
  final int position;

  /// 点击回调
  final VoidCallback? onTap;

  /// 收藏回调
  final Function(bool)? onFavorite;

  /// 动画延迟
  final Duration? animationDelay;

  /// 是否显示收藏按钮
  final bool showFavoriteButton;

  /// 是否显示详情按钮
  final bool showDetailButton;

  /// 是否启用毛玻璃效果
  final bool enableGlassmorphism;

  /// 毛玻璃配置
  final GlassmorphismConfig? glassmorphismConfig;

  /// 是否启用性能监控
  final bool enablePerformanceMonitoring;

  /// 性能阈值配置
  final PerformanceThresholds performanceThresholds;

  /// 调试模式
  final bool debugMode;

  /// 是否启用自适应降级
  final bool enableAutoDowngrade;

  const EnhancedFundRankingCard({
    super.key,
    required this.ranking,
    required this.position,
    this.onTap,
    this.onFavorite,
    this.animationDelay,
    this.showFavoriteButton = true,
    this.showDetailButton = true,
    this.enableGlassmorphism = true,
    this.glassmorphismConfig,
    this.enablePerformanceMonitoring = true,
    this.performanceThresholds = PerformanceThresholds.balanced,
    this.debugMode = false,
    this.enableAutoDowngrade = true,
  });

  @override
  State<EnhancedFundRankingCard> createState() =>
      _EnhancedFundRankingCardState();
}

class _EnhancedFundRankingCardState extends State<EnhancedFundRankingCard> {
  GlassmorphismConfig _currentGlassmorphismConfig = GlassmorphismConfig.medium;
  PerformanceLevel _currentPerformanceLevel = PerformanceLevel.good;

  @override
  void initState() {
    super.initState();
    _currentGlassmorphismConfig =
        widget.glassmorphismConfig ?? AppTheme.defaultGlassmorphismConfig;
  }

  void _onPerformanceUpdate(PerformanceMetrics metrics) {
    if (!mounted) return;

    final newLevel = PerformanceUtils.calculatePerformanceLevel(metrics);

    if (newLevel != _currentPerformanceLevel) {
      setState(() {
        _currentPerformanceLevel = newLevel;
        _updateGlassmorphismConfig();
      });
    }
  }

  void _updateGlassmorphismConfig() {
    if (!widget.enableAutoDowngrade) return;

    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final suggestedConfig = PerformanceUtils.suggestGlassmorphismConfig(
      _currentPerformanceLevel,
      isDarkTheme,
    );

    setState(() {
      _currentGlassmorphismConfig = suggestedConfig;
    });
  }

  @override
  Widget build(BuildContext context) {
    final card = FundRankingCard(
      ranking: widget.ranking,
      position: widget.position,
      onTap: widget.onTap,
      onFavorite: widget.onFavorite,
      animationDelay: widget.animationDelay,
      showFavoriteButton: widget.showFavoriteButton,
      showDetailButton: widget.showDetailButton,
      enableGlassmorphism: widget.enableGlassmorphism,
      glassmorphismConfig: _currentGlassmorphismConfig,
    );

    // 如果启用性能监控
    if (widget.enablePerformanceMonitoring) {
      return PerformanceMonitor(
        thresholds: widget.performanceThresholds,
        onPerformanceUpdate: _onPerformanceUpdate,
        enableAutoDowngrade: widget.enableAutoDowngrade,
        debugMode: widget.debugMode,
        child: card,
      );
    }

    return card;
  }
}

/// 毛玻璃基金卡片工厂
class GlassmorphismFundCardFactory {
  /// 创建默认配置的增强卡片
  static EnhancedFundRankingCard createDefault({
    required FundRanking ranking,
    required int position,
    VoidCallback? onTap,
    Function(bool)? onFavorite,
  }) {
    return EnhancedFundRankingCard(
      ranking: ranking,
      position: position,
      onTap: onTap,
      onFavorite: onFavorite,
      enableGlassmorphism: true,
      enablePerformanceMonitoring: true,
    );
  }

  /// 创建性能优先的卡片
  static EnhancedFundRankingCard createPerformanceFocused({
    required FundRanking ranking,
    required int position,
    VoidCallback? onTap,
    Function(bool)? onFavorite,
  }) {
    return EnhancedFundRankingCard(
      ranking: ranking,
      position: position,
      onTap: onTap,
      onFavorite: onFavorite,
      enableGlassmorphism: true,
      glassmorphismConfig: GlassmorphismConfig.performance,
      enablePerformanceMonitoring: true,
      performanceThresholds: PerformanceThresholds.performance,
      enableAutoDowngrade: true,
    );
  }

  /// 创建视觉效果优先的卡片
  static EnhancedFundRankingCard createVisualFocused({
    required FundRanking ranking,
    required int position,
    VoidCallback? onTap,
    Function(bool)? onFavorite,
  }) {
    return EnhancedFundRankingCard(
      ranking: ranking,
      position: position,
      onTap: onTap,
      onFavorite: onFavorite,
      enableGlassmorphism: true,
      glassmorphismConfig: GlassmorphismConfig.strong,
      enablePerformanceMonitoring: true,
      performanceThresholds: PerformanceThresholds.compatibility,
      enableAutoDowngrade: false,
    );
  }

  /// 创建调试模式的卡片
  static EnhancedFundRankingCard createDebug({
    required FundRanking ranking,
    required int position,
    VoidCallback? onTap,
    Function(bool)? onFavorite,
  }) {
    return EnhancedFundRankingCard(
      ranking: ranking,
      position: position,
      onTap: onTap,
      onFavorite: onFavorite,
      enableGlassmorphism: true,
      enablePerformanceMonitoring: true,
      debugMode: true,
      enableAutoDowngrade: true,
    );
  }
}
