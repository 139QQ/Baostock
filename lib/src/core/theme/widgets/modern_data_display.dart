import 'package:flutter/material.dart';
import '../design_tokens/app_colors.dart';
import 'gradient_container.dart';

/// 现代数字动画显示组件
///
/// 提供平滑的数字变化动画和渐变色彩效果
class AnimatedNumberDisplay extends StatefulWidget {
  final double value;
  final String? prefix;
  final String? suffix;
  final TextStyle? style;
  final Duration duration;
  final bool isPercentage;
  final bool isCurrency;
  final int? decimalPlaces;
  final Color? positiveColor;
  final Color? negativeColor;
  final Color? neutralColor;

  const AnimatedNumberDisplay({
    super.key,
    required this.value,
    this.prefix,
    this.suffix,
    this.style,
    this.duration = const Duration(milliseconds: 800),
    this.isPercentage = false,
    this.isCurrency = false,
    this.decimalPlaces,
    this.positiveColor,
    this.negativeColor,
    this.neutralColor,
  });

  @override
  State<AnimatedNumberDisplay> createState() => _AnimatedNumberDisplayState();
}

class _AnimatedNumberDisplayState extends State<AnimatedNumberDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousValue = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _previousValue = widget.value;
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedNumberDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _previousValue = oldWidget.value;
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final currentValue =
            _previousValue + (widget.value - _previousValue) * _animation.value;

        final formattedValue = _formatNumber(currentValue);
        final displayText =
            '${widget.prefix ?? ''}$formattedValue${widget.suffix ?? ''}';

        // 根据数值正负选择颜色
        Color textColor;
        if (currentValue > 0) {
          textColor = widget.positiveColor ?? FinancialColors.positive;
        } else if (currentValue < 0) {
          textColor = widget.negativeColor ?? FinancialColors.negative;
        } else {
          textColor = widget.neutralColor ?? FinancialColors.neutral;
        }

        return GradientText(
          displayText,
          style: (widget.style ?? const TextStyle()).copyWith(
            color: textColor,
          ),
          gradient: _getGradientForValue(currentValue),
        );
      },
    );
  }

  String _formatNumber(double value) {
    final decimals = widget.decimalPlaces ?? (value.abs() < 10 ? 2 : 0);
    final formatted = value.toStringAsFixed(decimals);

    if (widget.isCurrency) {
      return '¥$formatted';
    } else if (widget.isPercentage) {
      return '$formatted%';
    }

    return formatted;
  }

  LinearGradient? _getGradientForValue(double value) {
    if (value > 0) {
      return FinancialGradients.upTrendGradient;
    } else if (value < 0) {
      return FinancialGradients.downTrendGradient;
    }
    return null;
  }
}

/// 现代化数据卡片组件
class ModernDataCard extends StatefulWidget {
  final String title;
  final double value;
  final double? changeValue;
  final String? changeSuffix;
  final IconData? icon;
  final Gradient? backgroundGradient;
  final Color? iconColor;
  final VoidCallback? onTap;
  final bool animate;
  final EdgeInsetsGeometry? padding;

  const ModernDataCard({
    super.key,
    required this.title,
    required this.value,
    this.changeValue,
    this.changeSuffix,
    this.icon,
    this.backgroundGradient,
    this.iconColor,
    this.onTap,
    this.animate = true,
    this.padding,
  });

  @override
  State<ModernDataCard> createState() => _ModernDataCardState();
}

class _ModernDataCardState extends State<ModernDataCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _controller = AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
      _scaleAnimation = CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      );
      _slideAnimation = Tween<double>(
        begin: 0.3,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller.forward();
    }
  }

  @override
  void dispose() {
    if (widget.animate) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      padding: widget.padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            children: [
              if (widget.icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: widget.backgroundGradient ??
                        FinancialGradients.primaryGradient,
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.iconColor ?? Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 14,
                    color: NeutralColors.neutral600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 主要数值
          AnimatedNumberDisplay(
            value: widget.value,
            isCurrency: true,
            decimalPlaces: 2,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: NeutralColors.neutral900,
            ),
            duration: Duration(milliseconds: widget.animate ? 800 : 0),
          ),

          // 变化值
          if (widget.changeValue != null) ...[
            const SizedBox(height: 8),
            AnimatedNumberDisplay(
              value: widget.changeValue!,
              prefix: widget.changeValue! > 0 ? '+' : '',
              suffix: widget.changeSuffix ?? '%',
              isPercentage: widget.changeSuffix == '%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );

    if (widget.animate) {
      content = AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.translate(
              offset: Offset(0, (1 - _slideAnimation.value) * 20),
              child: Opacity(
                opacity: _slideAnimation.value,
                child: child,
              ),
            ),
          );
        },
        child: content,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: content,
      ),
    );
  }
}

/// 现代化进度条组件
class ModernProgressBar extends StatelessWidget {
  final double value;
  final double maxValue;
  final String? label;
  final Gradient? gradient;
  final Color? backgroundColor;
  final double height;
  final BorderRadius? borderRadius;
  final bool showPercentage;

  const ModernProgressBar({
    super.key,
    required this.value,
    this.maxValue = 100.0,
    this.label,
    this.gradient,
    this.backgroundColor,
    this.height = 8.0,
    this.borderRadius,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    final progress = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null || showPercentage) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (label != null)
                Text(
                  label!,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: NeutralColors.neutral700,
                  ),
                ),
              if (showPercentage)
                Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: NeutralColors.neutral800,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],

        // 进度条容器
        Container(
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor ?? NeutralColors.neutral200,
            borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
          ),
          child: Stack(
            children: [
              // 进度条
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: gradient ?? FinancialGradients.primaryGradient,
                    borderRadius:
                        borderRadius ?? BorderRadius.circular(height / 2),
                    boxShadow: [
                      BoxShadow(
                        color: (gradient ?? FinancialGradients.primaryGradient)
                            .colors
                            .first
                            .withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 现代化统计网格组件
class ModernStatsGrid extends StatelessWidget {
  final List<ModernDataCard> cards;
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  const ModernStatsGrid({
    super.key,
    required this.cards,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.2,
    this.crossAxisSpacing = 16,
    this.mainAxisSpacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
      children: cards,
    );
  }
}
