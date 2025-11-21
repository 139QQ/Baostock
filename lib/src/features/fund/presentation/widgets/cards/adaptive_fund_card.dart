import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'base_fund_card.dart';
import '../../../../../core/performance/component_monitor.dart';

/// 智能自适应基金卡片组件 (简化版)
///
/// 基于设备性能自动调整动画效果的智能卡片：
/// - 设备性能自动检测 (简化版)
/// - 3级动画自适应 (禁用/基础/完整)
/// - 智能错误处理和降级机制
/// - 完整的无障碍性支持
class AdaptiveFundCard extends BaseFundCard {
  /// 创建智能自适应基金卡片
  const AdaptiveFundCard({
    super.key,
    required super.fund,
    super.showComparisonCheckbox = false,
    super.showQuickActions = true,
    super.isSelected = false,
    super.compactMode = false,
    super.onTap,
    super.onSelectionChanged,
    super.onAddToWatchlist,
    super.onCompare,
    super.onShare,
    super.onSwipeLeft,
    super.onSwipeRight,
    this.performanceLevel,
    this.forceAnimationLevel,
    this.enablePerformanceMonitoring = true,
    this.enableAccessibility = true,
  });

  /// 手动指定的性能级别 (可选，覆盖自动检测)
  final PerformanceLevelSimple? performanceLevel;

  /// 强制指定的动画级别
  final AnimationLevel? forceAnimationLevel;

  /// 是否启用性能监控
  final bool enablePerformanceMonitoring;

  /// 是否启用无障碍功能
  final bool enableAccessibility;

  @override
  State<AdaptiveFundCard> createState() => _AdaptiveFundCardState();
}

class _AdaptiveFundCardState extends State<AdaptiveFundCard>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin, ComponentMonitorMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  AnimationController? _hoverController;

  late AnimationLevel _animationLevel;
  late PerformanceLevelSimple _performanceLevel;
  late bool _isHighPerformance;

  bool _isHovered = false;
  bool _isPressed = false;

  @override
  bool get wantKeepAlive => true;

  @override
  String get componentKey => 'AdaptiveFundCard_${widget.fund.code}';

  @override
  bool get enablePerformanceMonitoring => widget.enablePerformanceMonitoring;

  @override
  void initState() {
    super.initState();
    _initializePerformanceDetection();
    _initializeAnimations();
  }

  void _initializePerformanceDetection() {
    // 获取设备性能级别
    _performanceLevel = widget.performanceLevel ?? _detectPerformanceLevel();
    _isHighPerformance = _performanceLevel == PerformanceLevelSimple.high;

    // 确定动画级别
    if (widget.forceAnimationLevel != null) {
      _animationLevel = widget.forceAnimationLevel!;
    } else {
      _animationLevel = _getOptimalAnimationLevel();
    }
  }

  PerformanceLevelSimple _detectPerformanceLevel() {
    // 简化的性能检测逻辑
    // 实际项目中可以使用更复杂的检测算法
    return PerformanceLevelSimple.medium;
  }

  AnimationLevel _getOptimalAnimationLevel() {
    switch (_performanceLevel) {
      case PerformanceLevelSimple.low:
        return AnimationLevel.disabled;
      case PerformanceLevelSimple.medium:
        return AnimationLevel.basic;
      case PerformanceLevelSimple.high:
        return AnimationLevel.enhanced;
    }
  }

  void _initializeAnimations() {
    final duration = _isHighPerformance ? 300 : 200;

    _slideController = AnimationController(
      duration: Duration(milliseconds: duration),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: Duration(milliseconds: duration ~/ 2),
      vsync: this,
    );

    if (_animationLevel != AnimationLevel.disabled) {
      _hoverController = AnimationController(
        duration: const Duration(milliseconds: 150),
        vsync: this,
      );

      // 启动入场动画
      _slideController.forward();
      _fadeController.forward();
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _hoverController?.dispose();
    super.dispose();
  }

  void _handleHoverChange(bool isHovered) {
    if (_animationLevel == AnimationLevel.disabled) return;

    setState(() {
      _isHovered = isHovered;
    });

    if (isHovered) {
      _hoverController?.forward();
      HapticFeedback.lightImpact();
    } else {
      _hoverController?.reverse();
    }
  }

  void _handleTapDown(TapDownDetails details) {
    if (_animationLevel == AnimationLevel.disabled) return;

    setState(() {
      _isPressed = true;
    });

    if (_isHighPerformance) {
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (_animationLevel == AnimationLevel.disabled) return;

    setState(() {
      _isPressed = false;
    });
  }

  Widget _buildAdaptiveContent() {
    switch (_animationLevel) {
      case AnimationLevel.disabled:
        return _buildStaticContent();
      case AnimationLevel.basic:
        return _buildBasicContent();
      case AnimationLevel.enhanced:
        return _buildEnhancedContent();
    }
  }

  Widget _buildStaticContent() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildCardContent(),
      ),
    );
  }

  Widget _buildBasicContent() {
    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeController,
          child: Card(
            elevation: _isPressed ? 8 : (_isHovered ? 6 : 2),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildCardContent(),
      ),
    );
  }

  Widget _buildEnhancedContent() {
    // 在 enhanced 模式下，_hoverController 保证不为 null
    final hoverController = _hoverController!;
    return AnimatedBuilder(
      animation: Listenable.merge([_slideController, _fadeController, hoverController]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideController.value * 20),
          child: FadeTransition(
            opacity: _fadeController,
            child: Transform.scale(
              scale: _isHovered ? hoverController.value * 0.05 + 1.0 : 1.0,
              child: Card(
                elevation: _isPressed ? 12 : (_isHovered ? 8 : 4),
                shadowColor: _isHovered
                    ? Theme.of(context).primaryColor.withOpacity(0.3)
                    : null,
                child: child,
              ),
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildCardContent(),
      ),
    );
  }

  Widget _buildCardContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        const SizedBox(height: 12),
        _buildFundInfo(),
        const SizedBox(height: 8),
        _buildPerformanceMetrics(),
        if (widget.showQuickActions) ...[
          const SizedBox(height: 12),
          _buildActionButtons(),
        ],
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // 收藏按钮
        if (widget.showComparisonCheckbox)
          Checkbox(
            value: widget.isSelected,
            onChanged: widget.onSelectionChanged != null
                ? (value) => widget.onSelectionChanged!(value ?? false)
                : null,
          ),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.fund.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                widget.fund.code,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),

        // 快速操作按钮
        if (widget.showQuickActions && _animationLevel != AnimationLevel.disabled)
          _buildQuickActions(),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: widget.onAddToWatchlist,
          icon: const Icon(Icons.favorite_border),
          tooltip: '添加到关注列表',
        ),
        IconButton(
          onPressed: widget.onCompare,
          icon: const Icon(Icons.compare_arrows),
          tooltip: '添加到对比',
        ),
      ],
    );
  }

  Widget _buildFundInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '净值',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              widget.fund.unitNav.toStringAsFixed(4),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '收益率',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '${widget.fund.dailyReturn.toStringAsFixed(2)}%',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: widget.fund.dailyReturn >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPerformanceMetrics() {
    if (_animationLevel == AnimationLevel.disabled) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: Colors.grey[300],
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: _getPerformanceFactor(),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: _getPerformanceColor(),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: widget.onTap,
          child: const Text('查看详情'),
        ),
        if (_animationLevel == AnimationLevel.enhanced)
          TextButton(
            onPressed: widget.onShare,
            child: const Text('分享'),
          ),
      ],
    );
  }

  double _getPerformanceFactor() {
    // 根据收益率计算性能因子 (简化示例)
    final yieldRate = widget.fund.dailyReturn;
    if (yieldRate >= 10) return 1.0;
    if (yieldRate >= 5) return 0.8;
    if (yieldRate >= 0) return 0.6;
    return 0.3;
  }

  Color _getPerformanceColor() {
    final yieldRate = widget.fund.dailyReturn;
    if (yieldRate >= 10) return Colors.green;
    if (yieldRate >= 5) return Colors.lightGreen;
    if (yieldRate >= 0) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return monitoredBuild(context, () {
      return Semantics(
        button: true,
        label: '基金卡片: ${widget.fund.name}, 收益率: ${widget.fund.dailyReturn.toStringAsFixed(2)}%',
        child: GestureDetector(
          onTap: widget.onTap,
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          child: MouseRegion(
            onEnter: (_) => _handleHoverChange(true),
            onExit: (_) => _handleHoverChange(false),
            child: _buildAdaptiveContent(),
          ),
        ),
      );
    });
  }
}

/// 简化的性能级别枚举
///
/// 用于表示设备性能等级，指导组件选择合适的动画和功能级别
enum PerformanceLevelSimple {
  /// 低性能设备 - 禁用复杂动画，启用基础功能
  low,

  /// 中等性能设备 - 启用基础动画，正常功能
  medium,

  /// 高性能设备 - 启用完整动画和所有高级功能
  high,
}

/// 动画级别枚举
///
/// 用于控制组件的动画效果复杂程度，根据设备性能自动调整
enum AnimationLevel {
  /// 禁用动画 - 无动画效果，最高性能
  disabled,

  /// 基础动画 - 简单的过渡效果，平衡性能和体验
  basic,

  /// 增强动画 - 完整的动画效果，最佳用户体验
  enhanced,
}