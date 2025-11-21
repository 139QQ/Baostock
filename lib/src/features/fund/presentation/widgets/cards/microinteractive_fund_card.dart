import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'adaptive_fund_card.dart';
import 'base_fund_card.dart';

/// 微交互基金卡片组件
///
/// 提供丰富微交互和手势操作的高级卡片：
/// - 左滑收藏、右滑对比的手势交互
/// - 智能手势冲突检测
/// - 触觉反馈系统集成
/// - 性能监控和警告系统
/// - 丰富的视觉反馈效果
class MicrointeractiveFundCard extends BaseFundCard {
  /// 创建微交互基金卡片
  const MicrointeractiveFundCard({
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

    // 微交互特定参数
    this.enableSwipeGestures = true,
    this.swipeThreshold = 50.0,
    this.enableHapticFeedback = true,
    this.enableRippleEffects = true,
    this.gestureConflictResolution = GestureConflictPriority.userDefined,
    this.performanceWarningThreshold = 16.0, // 16ms for 60fps
    this.enablePerformanceMonitoring = true,
    this.enableAccessibility = true,
    this.performanceLevel = PerformanceLevelSimple.medium,
    this.forceAnimationLevel,
  });

  /// 是否启用手势操作
  final bool enableSwipeGestures;

  /// 滑动手势阈值 (像素)
  final double swipeThreshold;

  /// 是否启用触觉反馈
  final bool enableHapticFeedback;

  /// 是否启用波纹效果
  final bool enableRippleEffects;

  /// 手势冲突解决策略
  final GestureConflictPriority gestureConflictResolution;

  /// 性能警告阈值 (毫秒)
  final double performanceWarningThreshold;

  /// 是否启用性能监控
  final bool enablePerformanceMonitoring;

  /// 是否启用无障碍功能
  final bool enableAccessibility;

  /// 性能级别
  final PerformanceLevelSimple performanceLevel;

  /// 强制动画级别
  final int? forceAnimationLevel;

  @override
  State<MicrointeractiveFundCard> createState() =>
      _MicrointeractiveFundCardState();
}

class _MicrointeractiveFundCardState extends State<MicrointeractiveFundCard>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _swipeController;
  late AnimationController _rippleController;
  late AnimationController _shimmerController;

  late Animation<double> _swipeAnimation;
  late Animation<double> _rippleAnimation;
  late Animation<double> _shimmerAnimation;

  final _GestureStateManager _gestureManager = _GestureStateManager();

  bool _isSwiping = false;
  bool _showSwipeHint = false;
  SwipeDirection? _pendingSwipeDirection;
  Offset? _swipeStartPosition;
  DateTime? _swipeStartTime;

  // 性能监控
  DateTime _performanceCheckTime = DateTime.now();
  final List<double> _frameTimes = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeMicroInteractions();
    _startPerformanceMonitoring();
    _setupGestureConflictResolution();
  }

  void _initializeMicroInteractions() {
    // 滑动动画控制器
    _swipeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // 波纹动画控制器
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // 闪光动画控制器 (用于提示效果)
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // 设置动画值
    _swipeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: Curves.easeOutCubic,
    ));

    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOutCubic,
    ));

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    // 显示滑动提示
    _showSwipeHintAfterDelay();
  }

  void _showSwipeHintAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && widget.enableSwipeGestures) {
        setState(() {
          _showSwipeHint = true;
        });
        _shimmerController.repeat();

        // 5秒后隐藏提示
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _showSwipeHint = false;
            });
            _shimmerController.stop();
            _shimmerController.reset();
          }
        });
      }
    });
  }

  void _startPerformanceMonitoring() {
    if (widget.enablePerformanceMonitoring) {
      _performanceCheckTime = DateTime.now();

      // 开始帧率监控
      WidgetsBinding.instance.addPostFrameCallback(_onFrameRendered);
    }
  }

  void _onFrameRendered(Duration timestamp) {
    if (!mounted || !widget.enablePerformanceMonitoring) return;

    final now = DateTime.now();
    final frameTime =
        now.difference(_performanceCheckTime).inMicroseconds / 1000.0;

    _frameTimes.add(frameTime);
    if (_frameTimes.length > 60) {
      // 保留最近60帧
      _frameTimes.removeAt(0);
    }

    // 检查性能警告
    if (frameTime > widget.performanceWarningThreshold) {
      _handlePerformanceIssue(frameTime);
    }

    _performanceCheckTime = now;
    WidgetsBinding.instance.addPostFrameCallback(_onFrameRendered);
  }

  void _handlePerformanceIssue(double frameTime) {
    debugPrint(
        'Performance warning: Frame time ${frameTime.toStringAsFixed(2)}ms exceeds threshold');

    // 如果性能问题严重，自动降级
    if (frameTime > widget.performanceWarningThreshold * 2) {
      _handleAutoDowngrade();
    }
  }

  void _handleAutoDowngrade() {
    if (mounted && widget.forceAnimationLevel == null) {
      // 这里可以实现自动降级逻辑
      debugPrint('Auto-downgrading due to performance issues');
    }
  }

  void _setupGestureConflictResolution() {
    _gestureManager.priority = widget.gestureConflictResolution;
  }

  @override
  void dispose() {
    _swipeController.dispose();
    _rippleController.dispose();
    _shimmerController.dispose();
    _gestureManager.dispose();
    super.dispose();
  }

  void _handlePanStart(DragStartDetails details) {
    if (!widget.enableSwipeGestures) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    _swipeStartPosition = renderBox.globalToLocal(details.globalPosition);
    _swipeStartTime = DateTime.now();
    _isSwiping = true;

    // 取消其他动画
    _swipeController.stop();
    _rippleController.stop();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!widget.enableSwipeGestures || !_isSwiping) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final currentPosition = renderBox.globalToLocal(details.globalPosition);
    final deltaX = currentPosition.dx - _swipeStartPosition!.dx;

    // 检测滑动方向
    if (deltaX.abs() > 10) {
      // 10像素的死区
      final direction = deltaX > 0 ? SwipeDirection.right : SwipeDirection.left;

      if (_gestureManager.canProcessGesture(direction)) {
        _pendingSwipeDirection = direction;
        _swipeController.value =
            (deltaX.abs() / renderBox.size.width).clamp(0.0, 1.0);
      }
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    if (!widget.enableSwipeGestures || !_isSwiping) return;

    _isSwiping = false;

    final velocity = details.primaryVelocity ?? 0;
    final currentTime = DateTime.now();
    final swipeDuration =
        currentTime.difference(_swipeStartTime!).inMilliseconds;

    // 判断是否为有效滑动
    final isValidSwipe = _pendingSwipeDirection != null &&
        (velocity.abs() > 300 || swipeDuration < 300);

    if (isValidSwipe) {
      _executeSwipeAction(_pendingSwipeDirection!);
    } else {
      // 回弹动画
      _swipeController.reverse();
    }

    _pendingSwipeDirection = null;
    _swipeStartPosition = null;
    _swipeStartTime = null;
  }

  void _executeSwipeAction(SwipeDirection direction) {
    switch (direction) {
      case SwipeDirection.left:
        _handleSwipeLeft();
        break;
      case SwipeDirection.right:
        _handleSwipeRight();
        break;
    }
  }

  void _handleSwipeLeft() {
    if (widget.enableHapticFeedback) {
      HapticFeedback.mediumImpact();
    }

    // 触发波纹效果
    if (widget.enableRippleEffects) {
      _triggerRippleEffect(SwipeDirection.left);
    }

    // 执行左滑操作 (收藏)
    widget.onSwipeLeft?.call();
    widget.onAddToWatchlist?.call();

    // 显示收藏提示
    _showActionFeedback('已添加到关注列表');

    _swipeController.reverse();
  }

  void _handleSwipeRight() {
    if (widget.enableHapticFeedback) {
      HapticFeedback.mediumImpact();
    }

    // 触发波纹效果
    if (widget.enableRippleEffects) {
      _triggerRippleEffect(SwipeDirection.right);
    }

    // 执行右滑操作 (对比)
    widget.onSwipeRight?.call();
    widget.onCompare?.call();

    // 显示对比提示
    _showActionFeedback('已添加到对比列表');

    _swipeController.reverse();
  }

  void _triggerRippleEffect(SwipeDirection direction) {
    _rippleController.forward().then((_) {
      _rippleController.reverse();
    });
  }

  void _showActionFeedback(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildSwipeIndicators() {
    if (!widget.enableSwipeGestures) return const SizedBox.shrink();

    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _swipeAnimation,
          builder: (context, child) {
            return Stack(
              children: [
                // 左侧收藏指示器
                if (_pendingSwipeDirection == SwipeDirection.left ||
                    _showSwipeHint)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 80,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color:
                            Colors.red.withOpacity(0.3 * _swipeAnimation.value),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),

                // 右侧对比指示器
                if (_pendingSwipeDirection == SwipeDirection.right ||
                    _showSwipeHint)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: 80,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.blue
                            .withOpacity(0.3 * _swipeAnimation.value),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.compare_arrows,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),

                // 提示文字
                if (_showSwipeHint)
                  Center(
                    child: AnimatedBuilder(
                      animation: _shimmerAnimation,
                      builder: (context, child) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '左滑收藏 • 右滑对比',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRippleEffect() {
    if (!widget.enableRippleEffects) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _rippleAnimation,
      builder: (context, child) {
        return Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(
                        _rippleAnimation.value * 0.5,
                      ),
                  width: 2,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBasicCardContent(BuildContext context) {
    // 简化的基础卡片内容
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 基金名称和代码
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.fund.name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.fund.code,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                      ],
                    ),
                  ),
                  // 快速操作按钮
                  if (widget.showQuickActions)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            widget.isSelected
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: widget.isSelected ? Colors.red : null,
                          ),
                          onPressed: () {
                            widget.onAddToWatchlist?.call();
                          },
                          tooltip: '添加到关注',
                        ),
                        if (widget.showComparisonCheckbox)
                          Checkbox(
                            value: widget.isSelected,
                            onChanged: (bool? value) {
                              widget.onSelectionChanged?.call(value ?? false);
                            },
                          ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // 净值和收益率
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '单位净值',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      Text(
                        widget.fund.unitNav.toStringAsFixed(4),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '日收益率',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      Text(
                        '${widget.fund.dailyReturn >= 0 ? '+' : ''}${widget.fund.dailyReturn.toStringAsFixed(2)}%',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: widget.fund.dailyReturn >= 0
                                  ? Colors.green
                                  : Colors.red,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Stack(
      children: [
        // 基础卡片内容
        _buildBasicCardContent(context),

        // 滑动指示器
        if (widget.enableSwipeGestures) _buildSwipeIndicators(),

        // 波纹效果
        _buildRippleEffect(),

        // 手势检测器
        if (widget.enableSwipeGestures)
          Positioned.fill(
            child: GestureDetector(
              onPanStart: _handlePanStart,
              onPanUpdate: _handlePanUpdate,
              onPanEnd: _handlePanEnd,
              behavior: HitTestBehavior.translucent,
            ),
          ),
      ],
    );
  }
}

/// 滑动方向枚举
enum SwipeDirection {
  /// 向左滑动
  left,

  /// 向右滑动
  right,
}

/// 手势冲突解决优先级
enum GestureConflictPriority {
  /// 用户手势优先
  userDefined,

  /// 系统默认优先级
  systemDefault,

  /// 禁用手势
  disabled,
}

/// 手势状态管理器
class _GestureStateManager {
  GestureConflictPriority _priority = GestureConflictPriority.userDefined;
  final Set<SwipeDirection> _activeGestures = <SwipeDirection>{};

  set priority(GestureConflictPriority priority) {
    _priority = priority;
  }

  bool canProcessGesture(SwipeDirection direction) {
    switch (_priority) {
      case GestureConflictPriority.userDefined:
        return true;
      case GestureConflictPriority.systemDefault:
        return !_activeGestures.contains(direction);
      case GestureConflictPriority.disabled:
        return false;
    }
  }

  void addActiveGesture(SwipeDirection direction) {
    _activeGestures.add(direction);
  }

  void removeActiveGesture(SwipeDirection direction) {
    _activeGestures.remove(direction);
  }

  Set<dynamic> getGestureRecognizers() {
    // 这里可以返回自定义的手势识别器
    // 用于解决手势冲突
    return <dynamic>{};
  }

  void dispose() {
    _activeGestures.clear();
  }
}
