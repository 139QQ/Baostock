import 'package:flutter/material.dart';
import '../design_tokens/app_colors.dart';
import 'gradient_container.dart';

/// 现代品牌Logo组件
///
/// 基速基金的现代化品牌标识
/// 采用渐变色彩和动画效果
class ModernBrandLogo extends StatefulWidget {
  final double size;
  final bool showText;
  final bool animated;
  final Color? textColor;
  final bool compact;

  const ModernBrandLogo({
    Key? key,
    this.size = 40.0,
    this.showText = true,
    this.animated = true,
    this.textColor,
    this.compact = false,
  }) : super(key: key);

  @override
  State<ModernBrandLogo> createState() => _ModernBrandLogoState();
}

class _ModernBrandLogoState extends State<ModernBrandLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _gradientAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    if (!widget.animated) return;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 0.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _gradientAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    if (widget.animated) {
      _animationController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logoSize = widget.size;
    final iconSize = logoSize * 0.6;
    final fontSize = logoSize * 0.35;

    return AnimatedBuilder(
      animation: widget.animated
          ? _animationController
          : const AlwaysStoppedAnimation(1),
      builder: (context, child) {
        return Transform.scale(
          scale: widget.animated ? _scaleAnimation.value : 1.0,
          child: Transform.rotate(
            angle: widget.animated ? _rotationAnimation.value : 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 现代化Logo图标
                _buildModernIcon(iconSize),
                if (widget.showText && !widget.compact) ...[
                  const SizedBox(width: 12),
                  _buildBrandText(fontSize),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernIcon(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.2),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.animated && _gradientAnimation.value > 0
              ? [
                  Color.lerp(BrandColors.brandPrimary, BaseColors.primary600,
                      _gradientAnimation.value)!,
                  Color.lerp(BrandColors.brandAccent, BaseColors.gold500,
                      _gradientAnimation.value)!,
                ]
              : [BrandColors.brandPrimary, BrandColors.brandAccent],
        ),
        boxShadow: [
          BoxShadow(
            color: BaseColors.primary600.withOpacity(0.3),
            blurRadius: size * 0.2,
            offset: Offset(0, size * 0.1),
          ),
          if (widget.animated)
            BoxShadow(
              color: BaseColors.gold500
                  .withOpacity(_gradientAnimation.value * 0.4),
              blurRadius: size * 0.3,
              offset: Offset(0, size * 0.15),
            ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.trending_up_rounded,
          color: Colors.white,
          size: size * 0.5,
        ),
      ),
    );
  }

  Widget _buildBrandText(double fontSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 主标题 - 渐变文字
        GradientText(
          '基速基金',
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.animated && _gradientAnimation.value > 0
                ? [
                    Color.lerp(BrandColors.brandPrimary, BaseColors.primary700,
                        _gradientAnimation.value)!,
                    Color.lerp(BrandColors.brandAccent, BaseColors.gold600,
                        _gradientAnimation.value)!,
                  ]
                : [BrandColors.brandPrimary, BrandColors.brandAccent],
          ),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        // 副标题
        if (!widget.compact)
          Text(
            'JISU FUND',
            style: TextStyle(
              fontSize: fontSize * 0.4,
              fontWeight: FontWeight.w500,
              color: widget.textColor ?? BaseColors.primary600,
              letterSpacing: 2.0,
            ),
          ),
      ],
    );
  }
}

/// 迷你品牌Logo - 用于紧凑空间
class MiniBrandLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const MiniBrandLogo({
    Key? key,
    this.size = 24.0,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.25),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color ?? BrandColors.brandPrimary,
            color ?? BrandColors.brandAccent,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: (color ?? BrandColors.brandPrimary).withOpacity(0.3),
            blurRadius: size * 0.15,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.trending_up,
          color: Colors.white,
          size: size * 0.5,
        ),
      ),
    );
  }
}

/// 浮动品牌Logo - 带悬浮动画效果
class FloatingBrandLogo extends StatefulWidget {
  final double size;
  final bool showText;

  const FloatingBrandLogo({
    Key? key,
    this.size = 60.0,
    this.showText = true,
  }) : super(key: key);

  @override
  State<FloatingBrandLogo> createState() => _FloatingBrandLogoState();
}

class _FloatingBrandLogoState extends State<FloatingBrandLogo>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late Animation<double> _floatAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initFloatingAnimations();
  }

  void _initFloatingAnimations() {
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _floatAnimation = Tween<double>(
      begin: -0.05,
      end: 0.05,
    ).animate(CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _floatController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_floatController, _pulseController]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, widget.size * _floatAnimation.value),
          child: Transform.scale(
            scale: _pulseAnimation.value,
            child: ModernBrandLogo(
              size: widget.size,
              showText: widget.showText,
              animated: false,
            ),
          ),
        );
      },
    );
  }
}
