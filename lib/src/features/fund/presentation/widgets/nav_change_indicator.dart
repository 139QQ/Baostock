import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../data/processors/nav_change_detector.dart';

/// 净值变化指示器
///
/// 专门用于显示净值变化的视觉提示组件
/// 支持多种动画效果和自定义样式
class NavChangeIndicator extends StatefulWidget {
  /// 变化信息
  final NavChangeInfo changeInfo;

  /// 指示器样式
  final NavChangeIndicatorStyle style;

  /// 是否启用动画
  final bool enableAnimation;

  /// 动画配置
  final NavChangeAnimationConfig? animationConfig;

  /// 自定义文本
  final String? customText;

  /// 是否显示图标
  final bool showIcon;

  /// 是否显示百分比
  final bool showPercentage;

  /// 自定义颜色
  final Color? customColor;

  const NavChangeIndicator({
    Key? key,
    required this.changeInfo,
    this.style = NavChangeIndicatorStyle.badge,
    this.enableAnimation = true,
    this.animationConfig,
    this.customText,
    this.showIcon = true,
    this.showPercentage = true,
    this.customColor,
  }) : super(key: key);

  @override
  State<NavChangeIndicator> createState() => _NavChangeIndicatorState();
}

class _NavChangeIndicatorState extends State<NavChangeIndicator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 初始化动画
  void _initializeAnimation() {
    final duration = widget.animationConfig?.duration ??
        _getDefaultDurationForChangeType();

    _animationController = AnimationController(
      duration: duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.enableAnimation) {
      _animationController.forward();
    }
  }

  /// 获取变化类型对应的默认动画时长
  Duration _getDefaultDurationForChangeType() {
    switch (widget.changeInfo.changeType) {
      case NavChangeType.surge:
      case NavChangeType.plunge:
        return const Duration(milliseconds: 800);
      case NavChangeType.rise:
      case NavChangeType.fall:
        return const Duration(milliseconds: 600);
      case NavChangeType.slightRise:
      case NavChangeType.slightFall:
        return const Duration(milliseconds: 400);
      case NavChangeType.flat:
        return const Duration(milliseconds: 300);
      case NavChangeType.none:
        return const Duration(milliseconds: 200);
      case NavChangeType.dataError:
        return const Duration(milliseconds: 700);
      case NavChangeType.unknown:
        return const Duration(milliseconds: 500);
    }
  }

  /// 获取变化颜色
  Color _getChangeColor() {
    if (widget.customColor != null) return widget.customColor!;

    switch (widget.changeInfo.changeType) {
      case NavChangeType.surge:
        return Colors.green.shade600;
      case NavChangeType.rise:
        return Colors.green.shade500;
      case NavChangeType.slightRise:
        return Colors.green.shade400;
      case NavChangeType.flat:
        return Colors.grey.shade500;
      case NavChangeType.none:
        return Colors.grey.shade400;
      case NavChangeType.dataError:
        return Colors.orange.shade600;
      case NavChangeType.slightFall:
        return Colors.red.shade400;
      case NavChangeType.fall:
        return Colors.red.shade500;
      case NavChangeType.plunge:
        return Colors.red.shade600;
      case NavChangeType.unknown:
        return Colors.grey.shade400;
    }
  }

  /// 获取变化图标
  IconData _getChangeIcon() {
    switch (widget.changeInfo.changeType) {
      case NavChangeType.surge:
        return Icons.trending_up_rounded;
      case NavChangeType.rise:
        return Icons.arrow_upward_rounded;
      case NavChangeType.slightRise:
        return Icons.arrow_upward;
      case NavChangeType.flat:
        return Icons.remove;
      case NavChangeType.none:
        return Icons.remove_outlined;
      case NavChangeType.dataError:
        return Icons.error_outline;
      case NavChangeType.slightFall:
        return Icons.arrow_downward;
      case NavChangeType.fall:
        return Icons.arrow_downward_rounded;
      case NavChangeType.plunge:
        return Icons.trending_down_rounded;
      case NavChangeType.unknown:
        return Icons.help_outline;
    }
  }

  /// 构建徽章样式指示器
  Widget _buildBadgeIndicator() {
    final color = _getChangeColor();
    final icon = _getChangeIcon();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showIcon) ...[
            Icon(
              icon,
              size: 14,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
          ],
          if (widget.showPercentage)
            Text(
              widget.customText ?? '${widget.changeInfo.changePercentage.toStringAsFixed(2)}%',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  /// 构建标签样式指示器
  Widget _buildTagIndicator() {
    final color = _getChangeColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showIcon) ...[
            Icon(
              _getChangeIcon(),
              size: 16,
              color: color,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            widget.customText ?? widget.changeInfo.changeType.description,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          if (widget.showPercentage) ...[
            const SizedBox(width: 4),
            Text(
              '${widget.changeInfo.changePercentage.toStringAsFixed(2)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建图标样式指示器
  Widget _buildIconIndicator() {
    final color = _getChangeColor();

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Icon(
        _getChangeIcon(),
        size: 18,
        color: color,
      ),
    );
  }

  /// 构建文本样式指示器
  Widget _buildTextIndicator() {
    final color = _getChangeColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        widget.customText ?? '${widget.changeInfo.changePercentage.toStringAsFixed(2)}%',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  /// 构建详细样式指示器
  Widget _buildDetailedIndicator() {
    final color = _getChangeColor();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                _getChangeIcon(),
                size: 20,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                widget.changeInfo.changeType.description,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '变化率: ',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                '${widget.changeInfo.changePercentage.toStringAsFixed(2)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          if (widget.changeInfo.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              widget.changeInfo.description,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget indicator;

    switch (widget.style) {
      case NavChangeIndicatorStyle.badge:
        indicator = _buildBadgeIndicator();
        break;
      case NavChangeIndicatorStyle.tag:
        indicator = _buildTagIndicator();
        break;
      case NavChangeIndicatorStyle.icon:
        indicator = _buildIconIndicator();
        break;
      case NavChangeIndicatorStyle.text:
        indicator = _buildTextIndicator();
        break;
      case NavChangeIndicatorStyle.detailed:
        indicator = _buildDetailedIndicator();
        break;
    }

    if (!widget.enableAnimation) {
      return indicator;
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _opacityAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: indicator,
          ),
        );
      },
    );
  }
}

/// 净值变化指示器样式
enum NavChangeIndicatorStyle {
  /// 徽章样式 (适合卡片角落)
  badge,

  /// 标签样式 (适合列表项)
  tag,

  /// 图标样式 (适合紧凑显示)
  icon,

  /// 文本样式 (简洁显示)
  text,

  /// 详细样式 (显示完整信息)
  detailed,
}

/// 净值变化动画配置
class NavChangeAnimationConfig {
  /// 动画时长
  final Duration duration;

  /// 动画曲线
  final Curve curve;

  /// 是否启用缩放
  final bool enableScale;

  /// 是否启用淡入
  final bool enableFade;

  const NavChangeAnimationConfig({
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.elasticOut,
    this.enableScale = true,
    this.enableFade = true,
  });
}

/// 净值变化指示器工厂
class NavChangeIndicatorFactory {
  /// 创建徽章样式指示器
  static Widget badge({
    required NavChangeInfo changeInfo,
    String? customText,
    Color? customColor,
    bool showIcon = true,
    bool showPercentage = true,
  }) {
    return NavChangeIndicator(
      changeInfo: changeInfo,
      style: NavChangeIndicatorStyle.badge,
      customText: customText,
      customColor: customColor,
      showIcon: showIcon,
      showPercentage: showPercentage,
    );
  }

  /// 创建标签样式指示器
  static Widget tag({
    required NavChangeInfo changeInfo,
    String? customText,
    Color? customColor,
    bool showIcon = true,
    bool showPercentage = true,
  }) {
    return NavChangeIndicator(
      changeInfo: changeInfo,
      style: NavChangeIndicatorStyle.tag,
      customText: customText,
      customColor: customColor,
      showIcon: showIcon,
      showPercentage: showPercentage,
    );
  }

  /// 创建图标样式指示器
  static Widget icon({
    required NavChangeInfo changeInfo,
    Color? customColor,
    double? size,
  }) {
    return SizedBox(
      width: size ?? 32,
      height: size ?? 32,
      child: NavChangeIndicator(
        changeInfo: changeInfo,
        style: NavChangeIndicatorStyle.icon,
        customColor: customColor,
        showPercentage: false,
      ),
    );
  }

  /// 创建文本样式指示器
  static Widget text({
    required NavChangeInfo changeInfo,
    String? customText,
    Color? customColor,
  }) {
    return NavChangeIndicator(
      changeInfo: changeInfo,
      style: NavChangeIndicatorStyle.text,
      customText: customText,
      customColor: customColor,
      showIcon: false,
    );
  }

  /// 创建详细样式指示器
  static Widget detailed({
    required NavChangeInfo changeInfo,
    Color? customColor,
  }) {
    return NavChangeIndicator(
      changeInfo: changeInfo,
      style: NavChangeIndicatorStyle.detailed,
      customColor: customColor,
    );
  }
}

/// 净值变化组合指示器
/// 可以同时显示多种样式的组合指示器
class NavChangeComboIndicator extends StatelessWidget {
  /// 变化信息
  final NavChangeInfo changeInfo;

  /// 主指示器样式
  final NavChangeIndicatorStyle primaryStyle;

  /// 副指示器样式 (可选)
  final NavChangeIndicatorStyle? secondaryStyle;

  /// 是否显示时间戳
  final bool showTimestamp;

  /// 布局方向
  final Axis direction;

  /// 间距
  final double spacing;

  const NavChangeComboIndicator({
    Key? key,
    required this.changeInfo,
    this.primaryStyle = NavChangeIndicatorStyle.badge,
    this.secondaryStyle,
    this.showTimestamp = false,
    this.direction = Axis.horizontal,
    this.spacing = 8.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      NavChangeIndicator(
        changeInfo: changeInfo,
        style: primaryStyle,
      ),
    ];

    if (secondaryStyle != null) {
      children.add(
        NavChangeIndicator(
          changeInfo: changeInfo,
          style: secondaryStyle!,
          showPercentage: false,
        ),
      );
    }

    if (showTimestamp) {
      children.add(
        Text(
          _formatTimestamp(changeInfo.detectionTime),
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade500,
          ),
        ),
      );
    }

    if (direction == Axis.horizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: children
            .map((child) => Padding(
                  padding: EdgeInsets.only(right: spacing),
                  child: child,
                ))
            .toList(),
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: children
            .map((child) => Padding(
                  padding: EdgeInsets.only(bottom: spacing),
                  child: child,
                ))
            .toList(),
      );
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前';
    } else {
      return '${difference.inDays}天前';
    }
  }
}