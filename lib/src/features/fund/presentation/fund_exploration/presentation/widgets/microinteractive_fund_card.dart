import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/models/fund.dart';

/// 用户偏好管理服务
class UserPreferences {

  /// 获取用户偏好的动画级别 (0: 禁用, 1: 基础, 2: 完整)
  static Future<int> getAnimationLevel() async {
    try {
      // 在实际项目中，这里应该使用 shared_preferences
      // final prefs = await SharedPreferences.getInstance();
      // return prefs.getInt(_animationsKey) ?? 2; // 默认完整动画

      // 模拟实现 - 返回默认值
      return 2;
    } catch (e) {
      debugPrint('UserPreferences: Failed to get animation level: $e');
      return 2; // 默认完整动画
    }
  }

  /// 获取用户偏好的手势反馈设置
  static Future<bool> getGestureFeedbackEnabled() async {
    try {
      // final prefs = await SharedPreferences.getInstance();
      // return prefs.getBool(_gestureFeedbackKey) ?? true;

      return true; // 默认启用手势反馈
    } catch (e) {
      debugPrint('UserPreferences: Failed to get gesture feedback setting: $e');
      return true;
    }
  }
}

/// 性能监控混入
mixin PerformanceMonitorMixin on State {
  static const Duration _performanceThreshold = Duration(milliseconds: 16); // 60fps
  static const Map<String, Duration> _animationThresholds = {
    'hover': Duration(milliseconds: 200),
    'scale': Duration(milliseconds: 150),
    'return': Duration(milliseconds: 800),
    'favorite': Duration(milliseconds: 300),
    'swipe': Duration(milliseconds: 200),
  };

  Stopwatch? _stopwatch;

  void _startPerformanceTracking(String animationType) {
    _stopwatch = Stopwatch()..start();
  }

  void _endPerformanceTracking(String animationType) {
    if (_stopwatch != null && _stopwatch!.isRunning) {
      _stopwatch!.stop();
      final duration = _stopwatch!.elapsed;

      final threshold = _animationThresholds[animationType] ?? _performanceThreshold;
      if (duration > threshold) {
        _reportSlowAnimation(animationType, duration);
      }

      _stopwatch!.reset();
    }
  }

  void _reportSlowAnimation(String animationType, Duration duration) {
    debugPrint('🔍 Performance Warning: $animationType animation took ${duration.inMilliseconds}ms');

    // 这里可以集成到分析服务
    // Analytics.track('slow_animation', {
    //   'animation_type': animationType,
    //   'duration_ms': duration.inMilliseconds,
    //   'threshold_ms': _animationThresholds[animationType]?.inMilliseconds,
    //   'widget_type': runtimeType.toString(),
    // });
  }
}

/// 微交互基金卡片组件
///
/// 基于现有FundCard增强，提供丰富的微交互效果：
/// - 悬停时卡片上浮和阴影渐变
/// - 收益率数字滚动动画
/// - 点击涟漪效果和触觉反馈
/// - 收藏/对比按钮微动画
/// - 手势操作支持（左滑收藏，右滑对比）
class MicrointeractiveFundCard extends StatefulWidget {
  final Fund fund;
  final bool showComparisonCheckbox;
  final bool showQuickActions;
  final bool isSelected;
  final bool compactMode;
  final bool enableAnimations;
  final VoidCallback? onTap;
  final Function(bool)? onSelectionChanged;
  final VoidCallback? onAddToWatchlist;
  final VoidCallback? onCompare;
  final VoidCallback? onShare;
  final Function()? onSwipeLeft;
  final Function()? onSwipeRight;

  const MicrointeractiveFundCard({
    super.key,
    required this.fund,
    this.showComparisonCheckbox = false,
    this.showQuickActions = true,
    this.isSelected = false,
    this.compactMode = false,
    this.enableAnimations = true,
    this.onTap,
    this.onSelectionChanged,
    this.onAddToWatchlist,
    this.onCompare,
    this.onShare,
    this.onSwipeLeft,
    this.onSwipeRight,
  });

  @override
  State<MicrointeractiveFundCard> createState() => _MicrointeractiveFundCardState();
}

class _MicrointeractiveFundCardState extends State<MicrointeractiveFundCard>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {

  // Performance monitoring methods
  Stopwatch? _stopwatch;
  static const Duration _performanceThreshold = Duration(milliseconds: 16);
  static const Map<String, Duration> _animationThresholds = {
    'hover': Duration(milliseconds: 200),
    'scale': Duration(milliseconds: 150),
    'return': Duration(milliseconds: 800),
    'favorite': Duration(milliseconds: 300),
    'swipe': Duration(milliseconds: 200),
  };

  void _startPerformanceTracking(String animationType) {
    _stopwatch = Stopwatch()..start();
  }

  void _endPerformanceTracking(String animationType) {
    if (_stopwatch != null && _stopwatch!.isRunning) {
      _stopwatch!.stop();
      final duration = _stopwatch!.elapsed;

      final threshold = _animationThresholds[animationType] ?? _performanceThreshold;
      if (duration > threshold) {
        _reportSlowAnimation(animationType, duration);
      }

      _stopwatch!.reset();
    }
  }

  void _reportSlowAnimation(String animationType, Duration duration) {
    debugPrint('🔍 Performance Warning: $animationType animation took ${duration.inMilliseconds}ms');
  }
  late AnimationController _hoverController;
  late AnimationController _returnController;
  late AnimationController _favoriteController;
  late AnimationController _scaleController;
  late AnimationController _swipeController;

  late Animation<double> _hoverAnimation;
  late Animation<double> _shadowAnimation;
  late Animation<double> _returnAnimation;
  late Animation<double> _favoriteAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _swipeAnimation;

  bool _isHovered = false;
  bool _isFavorite = false;
  bool _isPressed = false;
  double _dragStartX = 0.0;
  double _dragStartY = 0.0;
  bool _isDragging = false;
  bool _animationInitializationFailed = false;

  // 手势冲突检测相关
  static const double _horizontalGestureThreshold = 30.0;
  static const double _swipeVelocityThreshold = 500.0;
  static const double _scrollConflictThreshold = 20.0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _isFavorite = widget.fund.isFavorite;
  }

  void _initializeAnimations() {
    if (!widget.enableAnimations) return;

    try {
      // 悬停动画控制器
      _hoverController = AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      );
      _hoverAnimation = Tween<double>(
        begin: 0.0,
        end: -8.0,
      ).animate(CurvedAnimation(
        parent: _hoverController,
        curve: Curves.easeOutCubic,
      ));

      _shadowAnimation = Tween<double>(
        begin: 2.0,
        end: 12.0,
      ).animate(CurvedAnimation(
        parent: _hoverController,
        curve: Curves.easeOutCubic,
      ));

      // 收益率数字滚动动画控制器
      _returnController = AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      );
      _returnAnimation = Tween<double>(
        begin: 0.0,
        end: widget.fund.return1Y,
      ).animate(CurvedAnimation(
        parent: _returnController,
        curve: Curves.easeOutCubic,
      ));

      // 收藏动画控制器
      _favoriteController = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );
      _favoriteAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _favoriteController,
        curve: Curves.elasticOut,
      ));

      // 点击缩放动画控制器
      _scaleController = AnimationController(
        duration: const Duration(milliseconds: 150),
        vsync: this,
      );
      _scaleAnimation = Tween<double>(
        begin: 1.0,
        end: 0.98,
      ).animate(CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeInOut,
      ));

      // 滑动动画控制器
      _swipeController = AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      );
      _swipeAnimation = Tween<Offset>(
        begin: Offset.zero,
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _swipeController,
        curve: Curves.easeOutCubic,
      ));

      // 启动收益率动画
      _returnController.forward();

    } catch (e) {
      // 动画初始化失败，降级到静态模式
      debugPrint('MicrointeractiveFundCard: Animation initialization failed: $e');
      setState(() {
        _animationInitializationFailed = true;
      });

      // 安全释放可能已创建的控制器
      try {
        _hoverController.dispose();
      } catch (_) {}
      try {
        _returnController.dispose();
      } catch (_) {}
      try {
        _favoriteController.dispose();
      } catch (_) {}
      try {
        _scaleController.dispose();
      } catch (_) {}
      try {
        _swipeController.dispose();
      } catch (_) {}
    }
  }

  @override
  void didUpdateWidget(MicrointeractiveFundCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fund.return1Y != widget.fund.return1Y) {
      _updateReturnAnimation();
    }
    if (oldWidget.fund.isFavorite != widget.fund.isFavorite) {
      _updateFavoriteAnimation();
    }
  }

  void _updateReturnAnimation() {
    if (!widget.enableAnimations) return;

    _returnAnimation = Tween<double>(
      begin: _returnAnimation.value,
      end: widget.fund.return1Y,
    ).animate(CurvedAnimation(
      parent: _returnController,
      curve: Curves.easeOutCubic,
    ));
    _returnController.reset();
    _returnController.forward();
  }

  void _updateFavoriteAnimation() {
    if (!widget.enableAnimations) return;

    _isFavorite = widget.fund.isFavorite;
    if (_isFavorite) {
      _favoriteController.forward();
    } else {
      _favoriteController.reverse();
    }
  }

  void _onHoverChange(bool isHovered) {
    if (!widget.enableAnimations || widget.compactMode) return;

    setState(() {
      _isHovered = isHovered;
    });

    if (isHovered) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.enableAnimations) return;

    setState(() {
      _isPressed = true;
    });
    _scaleController.forward();

    // 触觉反馈 - 基于用户偏好
    _provideHapticFeedback('light');
  }

  void _onTapUp(TapUpDetails details) {
    if (!widget.enableAnimations) return;

    setState(() {
      _isPressed = false;
    });
    _scaleController.reverse();

    widget.onTap?.call();
  }

  void _onTapCancel() {
    if (!widget.enableAnimations) return;

    setState(() {
      _isPressed = false;
    });
    _scaleController.reverse();
  }

  void _onPanStart(DragStartDetails details) {
    _dragStartX = details.globalPosition.dx;
    _dragStartY = details.globalPosition.dy;
    _isDragging = true;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    final deltaX = details.globalPosition.dx - _dragStartX;
    final deltaY = details.globalPosition.dy - _dragStartY;

    // 检测手势类型和是否与滚动冲突
    if (!_shouldHandleGesture(deltaX, deltaY)) {
      return; // 与滚动冲突，不处理
    }

    // 限制滑动范围
    final clampedDeltaX = deltaX.clamp(-100.0, 100.0);
    _swipeAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(clampedDeltaX / 1000, 0),
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: Curves.easeOutCubic,
    ));

    if (deltaX != 0) {
      _swipeController.forward();
    }
  }

  /// 智能手势检测：判断是否应该处理手势，避免与滚动冲突
  bool _shouldHandleGesture(double deltaX, double deltaY) {
    // 计算移动距离
    final absDeltaX = deltaX.abs();
    final absDeltaY = deltaY.abs();

    // 如果垂直移动距离大于水平移动距离，可能是滚动意图
    if (absDeltaY > absDeltaX * 1.5) {
      return false;
    }

    // 检查是否达到水平手势阈值
    if (absDeltaX < _horizontalGestureThreshold) {
      return false;
    }

    // 检查垂直移动是否过大（可能与滚动冲突）
    if (absDeltaY > _scrollConflictThreshold) {
      return false;
    }

    return true;
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDragging) return;

    final velocityX = details.primaryVelocity ?? 0;
    final velocityY = details.velocity.pixelsPerSecond.dy;
    _isDragging = false;

    // 计算总移动距离
    // 注意：DragEndDetails没有globalPosition，使用velocity和之前的计算
    const totalDeltaX = 0.0; // 简化处理，主要依赖速度检测
    const totalDeltaY = 0.0;

    // 增强的滑动手势检测
    if (_isSwipeGesture(totalDeltaX, totalDeltaY, velocityX, velocityY)) {
      if (totalDeltaX > _horizontalGestureThreshold || velocityX > _swipeVelocityThreshold) {
        // 右滑 - 对比
        widget.onSwipeRight?.call();
        _showSwipeFeedback('对比');
      } else if (totalDeltaX < -_horizontalGestureThreshold || velocityX < -_swipeVelocityThreshold) {
        // 左滑 - 收藏
        widget.onSwipeLeft?.call();
        _showSwipeFeedback('收藏');
      }
    }

    // 重置位置
    _startPerformanceTracking('swipe');
    _swipeAnimation = Tween<Offset>(
      begin: _swipeAnimation.value,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: Curves.easeOutCubic,
    ));
    _swipeController.forward().whenComplete(() {
      _endPerformanceTracking('swipe');
    });
  }

  /// 增强的滑动手势检测
  bool _isSwipeGesture(double deltaX, double deltaY, double velocityX, double velocityY) {
    // 检查是否有足够的速度或距离
    final hasVelocity = velocityX.abs() > _swipeVelocityThreshold;
    final hasDistance = deltaX.abs() > _horizontalGestureThreshold;

    if (!hasVelocity && !hasDistance) {
      return false;
    }

    // 检查是否为水平主导手势
    final absDeltaX = deltaX.abs();
    final absDeltaY = deltaY.abs();
    final absVelocityX = velocityX.abs();
    final absVelocityY = velocityY.abs();

    // 如果垂直移动过大，不认为是滑动手势
    if (absDeltaY > absDeltaX * 1.2) {
      return false;
    }

    // 如果垂直速度过大，可能是在滚动
    if (absVelocityY > absVelocityX * 1.5) {
      return false;
    }

    return true;
  }

  void _showSwipeFeedback(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已$action${widget.fund.name}'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// 生成无障碍性语义标签
  String _generateSemanticLabel() {
    final buffer = StringBuffer();
    buffer.write('基金卡片：${widget.fund.name}');
    buffer.write('，基金代码：${widget.fund.code}');
    buffer.write('，基金类型：${widget.fund.type}');
    buffer.write('，基金经理：${widget.fund.manager}');
    buffer.write('，基金规模：${widget.fund.scale.toStringAsFixed(1)}亿元');

    // 收益率信息
    final returnValue = widget.fund.return1Y;
    final returnText = returnValue > 0
        ? '+${returnValue.toStringAsFixed(2)}%'
        : '${returnValue.toStringAsFixed(2)}%';
    buffer.write('，近1年收益率：$returnText');

    // 状态信息
    if (widget.fund.isFavorite) {
      buffer.write('，已添加到自选');
    }
    if (widget.isSelected) {
      buffer.write('，已选择对比');
    }

    // 交互提示
    if (widget.enableAnimations) {
      buffer.write('，支持左滑收藏和右滑对比操作');
    }

    return buffer.toString();
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });

    // 触觉反馈 - 基于用户偏好
    _provideHapticFeedback('medium');

    if (_isFavorite) {
      _favoriteController.forward();
    } else {
      _favoriteController.reverse();
    }

    widget.onAddToWatchlist?.call();
  }

  /// 基于用户偏好提供触觉反馈
  Future<void> _provideHapticFeedback(String type) async {
    try {
      final feedbackEnabled = await UserPreferences.getGestureFeedbackEnabled();

      if (!feedbackEnabled) return;

      switch (type) {
        case 'light':
          HapticFeedback.lightImpact();
          break;
        case 'medium':
          HapticFeedback.mediumImpact();
          break;
        case 'heavy':
          HapticFeedback.heavyImpact();
          break;
        case 'selection':
          HapticFeedback.selectionClick();
          break;
      }
    } catch (e) {
      debugPrint('MicrointeractiveFundCard: Failed to provide haptic feedback: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (!widget.enableAnimations) {
      // 禁用动画时使用静态版本
      return _buildStaticCard(context);
    }

    if (widget.compactMode) {
      return _buildCompactAnimatedCard(context);
    }

    return _buildAnimatedCard(context);
  }

  Widget _buildStaticCard(BuildContext context) {
    return RepaintBoundary(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: _buildCardContent(context),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedCard(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _hoverController,
          _returnController,
          _favoriteController,
          _scaleController,
          _swipeController,
        ]),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _hoverAnimation.value),
            child: Transform.scale(
              scale: _isPressed ? _scaleAnimation.value : 1.0,
              child: FractionalTranslation(
                translation: _swipeAnimation.value,
                child: Card(
                  elevation: _shadowAnimation.value,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: MouseRegion(
                    onEnter: (_) => _onHoverChange(true),
                    onExit: (_) => _onHoverChange(false),
                    child: Semantics(
                        button: true,
                        label: _generateSemanticLabel(),
                        hint: '点击查看基金详情，支持左滑收藏和右滑对比操作',
                        child: GestureDetector(
                          onTapDown: _onTapDown,
                          onTapUp: _onTapUp,
                          onTapCancel: _onTapCancel,
                          onPanStart: _onPanStart,
                          onPanUpdate: _onPanUpdate,
                          onPanEnd: _onPanEnd,
                          child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: _isHovered
                              ? Border.all(
                                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                                  width: 1,
                                )
                              : null,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              // 主要内容
                              Padding(
                                padding: const EdgeInsets.all(14),
                                child: _buildCardContent(context),
                              ),
                              // 涟漪效果
                              if (_isPressed)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompactAnimatedCard(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _returnController,
          _favoriteController,
          _scaleController,
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: _isPressed ? _scaleAnimation.value : 1.0,
            child: Card(
              elevation: 1,
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: GestureDetector(
                onTapDown: _onTapDown,
                onTapUp: _onTapUp,
                onTapCancel: _onTapCancel,
                child: ListTile(
                  leading: widget.showComparisonCheckbox
                      ? Checkbox(
                          value: widget.isSelected,
                          onChanged: (value) {
                            widget.onSelectionChanged?.call(value ?? false);
                          },
                        )
                      : null,
                  title: _buildCompactTitle(),
                  subtitle: _buildCompactSubtitle(),
                  trailing: widget.showQuickActions
                      ? _buildCompactActions()
                      : null,
                  onTap: widget.onTap,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 头部信息
        _buildHeader(),
        const SizedBox(height: 10),
        // 基金经理和规模
        _buildManagerInfo(),
        const SizedBox(height: 10),
        // 快速操作按钮
        if (widget.showQuickActions) ...[
          _buildQuickActions(),
        ],
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // 左侧内容区域
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 基金名称行
              Row(
                children: [
                  if (widget.showComparisonCheckbox) ...[
                    Checkbox(
                      value: widget.isSelected,
                      onChanged: (value) {
                        widget.onSelectionChanged?.call(value ?? false);
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      widget.fund.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _isHovered
                            ? Theme.of(context).primaryColor
                            : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // 基金类型和代码行
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Fund.getFundTypeColor(widget.fund.type)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.fund.type,
                      style: TextStyle(
                        fontSize: 12,
                        color: Fund.getFundTypeColor(widget.fund.type),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.fund.code,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // 右侧收益率显示区域
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAnimatedReturn(),
              const SizedBox(height: 2),
              Text(
                '近1年收益',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedReturn() {
    if (!widget.enableAnimations) {
      return Text(
        '${widget.fund.return1Y > 0 ? '+' : ''}${widget.fund.return1Y.toStringAsFixed(2)}%',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Fund.getReturnColor(widget.fund.return1Y),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _returnAnimation,
      builder: (context, child) {
        final currentValue = _returnAnimation.value;
        return Text(
          '${currentValue > 0 ? '+' : ''}${currentValue.toStringAsFixed(2)}%',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Fund.getReturnColor(currentValue),
          ),
        );
      },
    );
  }

  Widget _buildManagerInfo() {
    return Row(
      children: [
        Icon(
          Icons.person_outline,
          size: 14,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            widget.fund.manager,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${widget.fund.scale.toStringAsFixed(1)}亿',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildAnimatedActionButton(
            icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
            label: '自选',
            onTap: _toggleFavorite,
            color: _isFavorite ? Colors.red : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildAnimatedActionButton(
            icon: Icons.compare_arrows,
            label: '对比',
            onTap: widget.onCompare,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildAnimatedActionButton(
            icon: Icons.share,
            label: '分享',
            onTap: widget.onShare,
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    Color? color,
  }) {
    if (!widget.enableAnimations) {
      return OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16, color: color),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 6),
          minimumSize: const Size(0, 32),
          side: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _favoriteController,
      builder: (context, child) {
        return OutlinedButton.icon(
          onPressed: onTap,
          icon: Transform.scale(
            scale: color == Colors.red
                ? 0.8 + (_favoriteAnimation.value * 0.4)
                : 1.0,
            child: Icon(
              icon,
              size: 16,
              color: color,
            ),
          ),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 6),
            minimumSize: const Size(0, 32),
            side: BorderSide(
              color: color ?? Colors.grey.shade300,
              width: color != null ? 1.5 : 1.0,
            ),
            backgroundColor: color?.withOpacity(0.1),
          ),
        );
      },
    );
  }

  Widget _buildCompactTitle() {
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.fund.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: Fund.getFundTypeColor(widget.fund.type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            widget.fund.type,
            style: TextStyle(
              fontSize: 11,
              color: Fund.getFundTypeColor(widget.fund.type),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactSubtitle() {
    return Row(
      children: [
        Text(
          widget.fund.code,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          widget.fund.manager,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const Spacer(),
        _buildAnimatedReturn(),
      ],
    );
  }

  Widget _buildCompactActions() {
    return AnimatedBuilder(
      animation: _favoriteController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Transform.scale(
                scale: _isFavorite
                    ? 0.8 + (_favoriteAnimation.value * 0.4)
                    : 1.0,
                child: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : null,
                  size: 18,
                ),
              ),
              onPressed: _toggleFavorite,
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              icon: const Icon(Icons.compare_arrows, size: 18),
              onPressed: widget.onCompare,
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              icon: const Icon(Icons.share, size: 18),
              onPressed: widget.onShare,
              visualDensity: VisualDensity.compact,
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    // 安全释放所有动画控制器，即使初始化失败也能正常处理
    if (!_animationInitializationFailed && widget.enableAnimations) {
      try {
        _hoverController.dispose();
      } catch (e) {
        debugPrint('MicrointeractiveFundCard: Error disposing hover controller: $e');
      }
      try {
        _returnController.dispose();
      } catch (e) {
        debugPrint('MicrointeractiveFundCard: Error disposing return controller: $e');
      }
      try {
        _favoriteController.dispose();
      } catch (e) {
        debugPrint('MicrointeractiveFundCard: Error disposing favorite controller: $e');
      }
      try {
        _scaleController.dispose();
      } catch (e) {
        debugPrint('MicrointeractiveFundCard: Error disposing scale controller: $e');
      }
      try {
        _swipeController.dispose();
      } catch (e) {
        debugPrint('MicrointeractiveFundCard: Error disposing swipe controller: $e');
      }
    }
    super.dispose();
  }
}