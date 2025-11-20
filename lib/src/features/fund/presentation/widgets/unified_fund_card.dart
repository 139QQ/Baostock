import 'package:flutter/material.dart';

import '../../../../core/utils/logger.dart';
import 'base_fund_card.dart';
import 'fund_card_utils.dart';

/// 统一的基金卡片组件
///
/// 整合了所有基金卡片功能，消除了代码冗余：
/// - 自适应性能优化
/// - 多种显示模式（简约/现代/增强）
/// - 智能手势识别
/// - 统一的动画系统
/// - 可配置的UI风格
class UnifiedFundCard extends BaseFundCard {
  /// 创建统一的基金卡片组件
  const UnifiedFundCard({
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
    this.config,
    this.forceStyle,
  });

  /// 卡片配置
  final FundCardConfig? config;

  /// 强制指定的卡片样式
  final CardStyle? forceStyle;

  @override
  State<UnifiedFundCard> createState() => _UnifiedFundCardState();
}

class _UnifiedFundCardState extends State<UnifiedFundCard>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late FundCardConfig _config;

  late AnimationController _hoverController;
  late AnimationController _returnController;
  late AnimationController _favoriteController;
  late AnimationController _scaleController;
  late AnimationController? _swipeController;

  late Animation<double> _hoverAnimation;
  late Animation<double> _shadowAnimation;
  late Animation<double> _returnAnimation;
  late Animation<double> _favoriteAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset>? _swipeAnimation;

  bool _isHovered = false;
  bool _isFavorite = false;
  bool _isPressed = false;
  bool _isInitialized = false;

  // 手势检测相关
  double _dragStartX = 0.0;
  double _dragStartY = 0.0;
  bool _isDragging = false;
  static const double _horizontalGestureThreshold = 30.0;
  static const double _swipeVelocityThreshold = 500.0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeConfig();
    _initializeAnimations();
    // 注意：Fund类没有isFavorite属性，我们在本地管理收藏状态
    _isFavorite = false;
  }

  Future<void> _initializeConfig() async {
    if (widget.config != null) {
      _config = widget.config!;
    } else {
      // 异步获取用户偏好和设备性能
      final userAnimationLevel =
          await UserPreferencesService.getAnimationLevel();
      final userHoverEffects =
          await UserPreferencesService.getHoverEffectsEnabled();
      final userGestureFeedback =
          await UserPreferencesService.getGestureFeedbackEnabled();
      final performanceMode = await UserPreferencesService.getPerformanceMode();

      // 获取设备性能推荐配置
      final deviceConfig =
          DevicePerformanceService.getRecommendedConfig(context);

      // 应用用户偏好和性能限制
      _config = FundCardConfig(
        animationLevel: performanceMode
            ? 0
            : (userAnimationLevel < deviceConfig.animationLevel
                ? userAnimationLevel
                : deviceConfig.animationLevel),
        enableAnimations: !performanceMode &&
            deviceConfig.enableAnimations &&
            userAnimationLevel > 0,
        enableHoverEffects: !performanceMode &&
            deviceConfig.enableHoverEffects &&
            userHoverEffects,
        enableGestureFeedback:
            deviceConfig.enableGestureFeedback && userGestureFeedback,
        enablePerformanceMonitoring: deviceConfig.enablePerformanceMonitoring,
        cardStyle: widget.forceStyle ?? deviceConfig.cardStyle,
      );
    }

    setState(() {
      _isInitialized = true;
    });
  }

  void _initializeAnimations() {
    if (!_config.enableAnimations) return;

    try {
      final duration = _config.animationLevel == 1 ? 100 : 200;

      _hoverController = AnimationController(
        duration: Duration(milliseconds: duration),
        vsync: this,
      );

      _returnController = AnimationController(
        duration:
            Duration(milliseconds: _config.animationLevel == 1 ? 400 : 800),
        vsync: this,
      );

      _favoriteController = AnimationController(
        duration:
            Duration(milliseconds: _config.animationLevel == 1 ? 150 : 300),
        vsync: this,
      );

      _scaleController = AnimationController(
        duration:
            Duration(milliseconds: _config.animationLevel == 1 ? 75 : 150),
        vsync: this,
      );

      // 滑动动画（仅在增强模式下启用）
      if (_config.cardStyle == CardStyle.enhanced) {
        _swipeController = AnimationController(
          duration: const Duration(milliseconds: 200),
          vsync: this,
        );
      }

      _setupAnimations();
    } catch (e) {
      AppLogger.error('动画初始化失败: ${widget.fund.name}', e);
      setState(() {
        _config = _config.copyWith(
          enableAnimations: false,
          enableHoverEffects: false,
        );
      });
    }
  }

  void _setupAnimations() {
    // 悬停动画
    _hoverAnimation = Tween<double>(
      begin: 0.0,
      end: _config.animationLevel == 2 ? -8.0 : -4.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOutCubic,
    ));

    _shadowAnimation = Tween<double>(
      begin: 2.0,
      end: _config.animationLevel == 2 ? 12.0 : 6.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOutCubic,
    ));

    // 收益率动画
    _returnAnimation = Tween<double>(
      begin: 0.0,
      end: widget.fund.return1Y,
    ).animate(CurvedAnimation(
      parent: _returnController,
      curve: Curves.easeOutCubic,
    ));

    // 收藏动画
    _favoriteAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _favoriteController,
      curve: _config.animationLevel == 2 ? Curves.elasticOut : Curves.easeOut,
    ));

    // 缩放动画
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: _config.animationLevel == 2 ? 0.98 : 0.99,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    // 滑动动画
    if (_swipeController != null) {
      _swipeAnimation = Tween<Offset>(
        begin: Offset.zero,
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _swipeController!,
        curve: Curves.easeOutCubic,
      ));
    }

    // 启动初始动画
    _returnController.forward();
  }

  @override
  void didUpdateWidget(UnifiedFundCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fund.return1Y != widget.fund.return1Y &&
        _config.enableAnimations) {
      _updateReturnAnimation();
    }
    // 注意：Fund类没有isFavorite属性，收藏状态由本地管理
    // if (oldWidget.fund.isFavorite != widget.fund.isFavorite) {
    //   _updateFavoriteAnimation();
    // }
  }

  void _updateReturnAnimation() {
    if (!_config.enableAnimations || !_isInitialized) return;

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

  // void _updateFavoriteAnimation() {
  //   if (!_config.enableAnimations || !_isInitialized) return;

  //   _isFavorite = widget.fund.isFavorite;
  //   if (_isFavorite) {
  //     _favoriteController.forward();
  //   } else {
  //     _favoriteController.reverse();
  //   }
  // }

  void _onHoverChange(bool isHovered) {
    if (!_config.enableHoverEffects || widget.compactMode || !_isInitialized)
      return;

    setState(() {
      _isHovered = isHovered;
    });

    if (_config.enablePerformanceMonitoring) {
      PerformanceMonitorService.startTracking('hover');
    }

    if (isHovered) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }

    if (_config.enablePerformanceMonitoring) {
      PerformanceMonitorService.endTracking('hover');
    }
  }

  void _onTapDown(TapDownDetails details) {
    if (!_config.enableAnimations || !_isInitialized) return;

    setState(() {
      _isPressed = true;
    });
    _scaleController.forward();

    if (_config.enableGestureFeedback) {
      HapticFeedbackService.provideFeedback('light');
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (!_config.enableAnimations || !_isInitialized) return;

    setState(() {
      _isPressed = false;
    });
    _scaleController.reverse();

    widget.onTap?.call();
  }

  void _onTapCancel() {
    if (!_config.enableAnimations || !_isInitialized) return;

    setState(() {
      _isPressed = false;
    });
    _scaleController.reverse();
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });

    if (_config.enableGestureFeedback) {
      HapticFeedbackService.provideFeedback('medium');
    }

    if (_config.enablePerformanceMonitoring) {
      PerformanceMonitorService.startTracking('favorite');
    }

    if (_isFavorite) {
      _favoriteController.forward();
    } else {
      _favoriteController.reverse();
    }

    if (_config.enablePerformanceMonitoring) {
      PerformanceMonitorService.endTracking('favorite');
    }

    widget.onAddToWatchlist?.call();
  }

  // 手势处理（仅在增强模式下启用）
  void _onPanStart(DragStartDetails details) {
    if (_config.cardStyle != CardStyle.enhanced || _swipeController == null)
      return;

    _dragStartX = details.globalPosition.dx;
    _dragStartY = details.globalPosition.dy;
    _isDragging = true;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging ||
        _config.cardStyle != CardStyle.enhanced ||
        _swipeController == null) return;

    final deltaX = details.globalPosition.dx - _dragStartX;
    final deltaY = details.globalPosition.dy - _dragStartY;

    if (!_shouldHandleGesture(deltaX, deltaY)) return;

    final clampedDeltaX = deltaX.clamp(-100.0, 100.0);
    _swipeAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(clampedDeltaX / 1000, 0),
    ).animate(CurvedAnimation(
      parent: _swipeController!,
      curve: Curves.easeOutCubic,
    ));

    if (deltaX != 0) {
      _swipeController!.forward();
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDragging || _config.cardStyle != CardStyle.enhanced) return;

    final velocityX = details.primaryVelocity ?? 0;
    _isDragging = false;

    if (_isSwipeGesture(velocityX)) {
      if (velocityX > _swipeVelocityThreshold) {
        widget.onSwipeRight?.call();
        _showSwipeFeedback('对比');
      } else if (velocityX < -_swipeVelocityThreshold) {
        widget.onSwipeLeft?.call();
        _showSwipeFeedback('收藏');
      }
    }

    // 重置位置
    if (_swipeController != null) {
      _swipeAnimation = Tween<Offset>(
        begin: _swipeAnimation!.value,
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _swipeController!,
        curve: Curves.easeOutCubic,
      ));
      _swipeController!.forward();
    }
  }

  bool _shouldHandleGesture(double deltaX, double deltaY) {
    final absDeltaX = deltaX.abs();
    final absDeltaY = deltaY.abs();

    if (absDeltaY > absDeltaX * 1.5) return false;
    if (absDeltaX < _horizontalGestureThreshold) return false;
    if (absDeltaY > 20.0) return false; // 滚动冲突阈值

    return true;
  }

  bool _isSwipeGesture(double velocityX) {
    return velocityX.abs() > _swipeVelocityThreshold;
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

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (!_isInitialized) {
      return _buildLoadingCard();
    }

    if (!_config.enableAnimations) {
      return _buildStaticCard();
    }

    if (widget.compactMode) {
      return _buildCompactAnimatedCard();
    }

    return _buildAnimatedCard();
  }

  Widget _buildLoadingCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        height: widget.compactMode ? 80 : 160,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildStaticCard() {
    return RepaintBoundary(
      child: Card(
        elevation: _getCardElevation(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_getBorderRadius()),
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(_getBorderRadius()),
          child: Padding(
            padding: EdgeInsets.all(_getCardPadding()),
            child: _buildCardContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedCard() {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _hoverController,
          _returnController,
          _favoriteController,
          _scaleController,
          if (_swipeController != null) _swipeController!,
        ]),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _hoverAnimation.value),
            child: Transform.scale(
              scale: _isPressed ? _scaleAnimation.value : 1.0,
              child: FractionalTranslation(
                translation: _swipeAnimation?.value ?? Offset.zero,
                child: Card(
                  elevation: _shadowAnimation.value,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_getBorderRadius()),
                  ),
                  child: MouseRegion(
                    onEnter: (_) => _onHoverChange(true),
                    onExit: (_) => _onHoverChange(false),
                    child: GestureDetector(
                      onTapDown: _onTapDown,
                      onTapUp: _onTapUp,
                      onTapCancel: _onTapCancel,
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(_getBorderRadius()),
                          border: _isHovered && _config.enableHoverEffects
                              ? Border.all(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.3),
                                  width: 1,
                                )
                              : null,
                        ),
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(_getBorderRadius()),
                          child: Stack(
                            children: [
                              Padding(
                                padding: EdgeInsets.all(_getCardPadding()),
                                child: _buildCardContent(),
                              ),
                              if (_isPressed && _config.animationLevel == 2)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(
                                          _getBorderRadius()),
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
          );
        },
      ),
    );
  }

  Widget _buildCompactAnimatedCard() {
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
                trailing:
                    widget.showQuickActions ? _buildCompactActions() : null,
                onTap: widget.onTap,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        SizedBox(height: _getSpacing()),
        _buildManagerInfo(),
        SizedBox(height: _getSpacing()),
        if (widget.showQuickActions) _buildQuickActions(),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                        fontSize: _getFontSize(15),
                        fontWeight: FontWeight.bold,
                        color: _isHovered && _config.enableHoverEffects
                            ? Theme.of(context).primaryColor
                            : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: _getSpacing() * 0.4),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: _getFontSize(8),
                      vertical: _getFontSize(4),
                    ),
                    decoration: BoxDecoration(
                      color: FundCardUtils.getFundTypeColor(widget.fund.type)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.fund.type,
                      style: TextStyle(
                        fontSize: _getFontSize(12),
                        color: FundCardUtils.getFundTypeColor(widget.fund.type),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.fund.code,
                    style: TextStyle(
                      fontSize: _getFontSize(12),
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildReturnDisplay(),
              SizedBox(height: _getSpacing() * 0.2),
              Text(
                '近1年收益',
                style: TextStyle(
                  fontSize: _getFontSize(12),
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReturnDisplay() {
    if (!_config.enableAnimations) {
      return Text(
        '${widget.fund.return1Y > 0 ? '+' : ''}${widget.fund.return1Y.toStringAsFixed(2)}%',
        style: TextStyle(
          fontSize: _getFontSize(18),
          fontWeight: FontWeight.bold,
          color: FundCardUtils.getReturnColor(widget.fund.return1Y),
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
            fontSize: _getFontSize(18),
            fontWeight: FontWeight.bold,
            color: FundCardUtils.getReturnColor(currentValue),
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
          size: _getFontSize(14),
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            widget.fund.manager,
            style: TextStyle(
              fontSize: _getFontSize(13),
              color: Colors.grey.shade700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${widget.fund.scale.toStringAsFixed(1)}亿',
          style: TextStyle(
            fontSize: _getFontSize(13),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    final buttonCount = _config.cardStyle == CardStyle.enhanced ? 3 : 2;

    return Row(
      children: List.generate(buttonCount, (index) {
        final isLast = index == buttonCount - 1;
        return [
          Expanded(
            child: _buildActionButton(index),
          ),
          if (!isLast) const SizedBox(width: 8),
        ];
      }).expand((e) => e).toList(),
    );
  }

  Widget _buildActionButton(int index) {
    final actions = [
      {
        'icon': _isFavorite ? Icons.favorite : Icons.favorite_border,
        'label': '自选',
        'color': _isFavorite ? Colors.red : null
      },
      {'icon': Icons.compare_arrows, 'label': '对比', 'color': null},
      if (_config.cardStyle == CardStyle.enhanced)
        {'icon': Icons.share, 'label': '分享', 'color': null},
    ];

    if (index >= actions.length) return const SizedBox();

    final action = actions[index];
    final VoidCallback? onTap = index == 0
        ? _toggleFavorite
        : index == 1
            ? widget.onCompare
            : widget.onShare;

    if (!_config.enableAnimations) {
      return OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(action['icon'] as IconData,
            size: 16, color: action['color'] as Color?),
        label: Text(action['label'] as String),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: _getFontSize(6)),
          minimumSize: const Size(0, 32),
          side: BorderSide(color: Colors.grey.shade300),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _favoriteController,
      builder: (context, child) {
        return OutlinedButton.icon(
          onPressed: onTap,
          icon: action['color'] != null
              ? Transform.scale(
                  scale: 0.8 + (_favoriteAnimation.value * 0.4),
                  child: Icon(action['icon'] as IconData,
                      size: 16, color: action['color'] as Color?),
                )
              : Icon(action['icon'] as IconData, size: 16),
          label: Text(action['label'] as String),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: _getFontSize(6)),
            minimumSize: const Size(0, 32),
            side: BorderSide(
              color: (action['color'] as Color?) ?? Colors.grey.shade300,
              width: action['color'] != null ? 1.5 : 1.0,
            ),
            backgroundColor: (action['color'] as Color?)?.withOpacity(0.1),
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
            style: TextStyle(
              fontSize: _getFontSize(14),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: FundCardUtils.getFundTypeColor(widget.fund.type)
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            widget.fund.type,
            style: TextStyle(
              fontSize: _getFontSize(11),
              color: FundCardUtils.getFundTypeColor(widget.fund.type),
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
            fontSize: _getFontSize(12),
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          widget.fund.manager,
          style: TextStyle(
            fontSize: _getFontSize(12),
            color: Colors.grey.shade600,
          ),
        ),
        const Spacer(),
        _buildReturnDisplay(),
      ],
    );
  }

  Widget _buildCompactActions() {
    if (!_config.enableAnimations) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : null, size: 18),
            onPressed: _toggleFavorite,
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: const Icon(Icons.compare_arrows, size: 18),
            onPressed: widget.onCompare,
            visualDensity: VisualDensity.compact,
          ),
          if (_config.cardStyle == CardStyle.enhanced)
            IconButton(
              icon: const Icon(Icons.share, size: 18),
              onPressed: widget.onShare,
              visualDensity: VisualDensity.compact,
            ),
        ],
      );
    }

    return AnimatedBuilder(
      animation: _favoriteController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Transform.scale(
                scale:
                    _isFavorite ? 0.8 + (_favoriteAnimation.value * 0.4) : 1.0,
                child: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : null,
                    size: 18),
              ),
              onPressed: _toggleFavorite,
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              icon: const Icon(Icons.compare_arrows, size: 18),
              onPressed: widget.onCompare,
              visualDensity: VisualDensity.compact,
            ),
            if (_config.cardStyle == CardStyle.enhanced)
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

  // 辅助方法
  double _getCardElevation() {
    switch (_config.cardStyle) {
      case CardStyle.minimal:
        return 1;
      case CardStyle.modern:
        return 2;
      case CardStyle.enhanced:
        return 3;
    }
  }

  double _getBorderRadius() {
    switch (_config.cardStyle) {
      case CardStyle.minimal:
        return 8;
      case CardStyle.modern:
        return 12;
      case CardStyle.enhanced:
        return 16;
    }
  }

  double _getCardPadding() {
    switch (_config.cardStyle) {
      case CardStyle.minimal:
        return 10;
      case CardStyle.modern:
        return 14;
      case CardStyle.enhanced:
        return 16;
    }
  }

  double _getFontSize(double baseSize) {
    switch (_config.animationLevel) {
      case 0:
        return baseSize * 0.9;
      case 1:
        return baseSize * 0.95;
      case 2:
      default:
        return baseSize;
    }
  }

  double _getSpacing() {
    switch (_config.cardStyle) {
      case CardStyle.minimal:
        return 6;
      case CardStyle.modern:
        return 10;
      case CardStyle.enhanced:
        return 12;
    }
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _returnController.dispose();
    _favoriteController.dispose();
    _scaleController.dispose();
    _swipeController?.dispose();
    super.dispose();
  }
}

// FundCardConfig 扩展
/// FundCardConfig 的复制扩展方法
extension FundCardConfigCopy on FundCardConfig {
  /// 创建配置的副本
  FundCardConfig copyWith({
    int? animationLevel,
    bool? enableAnimations,
    bool? enableHoverEffects,
    bool? enableGestureFeedback,
    bool? enablePerformanceMonitoring,
    CardStyle? cardStyle,
  }) {
    return FundCardConfig(
      animationLevel: animationLevel ?? this.animationLevel,
      enableAnimations: enableAnimations ?? this.enableAnimations,
      enableHoverEffects: enableHoverEffects ?? this.enableHoverEffects,
      enableGestureFeedback:
          enableGestureFeedback ?? this.enableGestureFeedback,
      enablePerformanceMonitoring:
          enablePerformanceMonitoring ?? this.enablePerformanceMonitoring,
      cardStyle: cardStyle ?? this.cardStyle,
    );
  }
}
