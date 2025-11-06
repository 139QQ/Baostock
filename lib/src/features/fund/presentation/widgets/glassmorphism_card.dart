import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glassmorphism_theme_manager.dart';

/// 毛玻璃效果组件
///
/// 提供可配置的毛玻璃视觉效果，支持：
/// - 可调节模糊度
/// - 透明度层次管理
/// - 主题适配
/// - 性能优化
class GlassmorphismCard extends StatefulWidget {
  /// 子组件
  final Widget child;

  /// 模糊度 (0.0-20.0)
  final double blur;

  /// 透明度 (0.0-1.0)
  final double opacity;

  /// 边框圆角
  final double borderRadius;

  /// 边框宽度
  final double borderWidth;

  /// 边框颜色
  final Color borderColor;

  /// 背景颜色
  final Color backgroundColor;

  /// 阴影
  final List<BoxShadow>? boxShadow;

  /// 是否启用性能优化模式
  final bool enablePerformanceOptimization;

  /// 自定义高度
  final double? height;

  /// 自定义宽度
  final double? width;

  /// 外边距
  final EdgeInsetsGeometry? margin;

  /// 内边距
  final EdgeInsetsGeometry? padding;

  const GlassmorphismCard({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.opacity = 0.1,
    this.borderRadius = 12.0,
    this.borderWidth = 1.0,
    this.borderColor = Colors.white,
    this.backgroundColor = Colors.white,
    this.boxShadow,
    this.enablePerformanceOptimization = true,
    this.height,
    this.width,
    this.margin,
    this.padding,
  });

  /// 从主题创建毛玻璃卡片
  factory GlassmorphismCard.fromTheme({
    Key? key,
    required Widget child,
    required BuildContext context,
    GlassmorphismConfig? config,
    double? height,
    double? width,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    List<BoxShadow>? boxShadow,
  }) {
    final themeManager = GlassmorphismThemeManager();
    final finalConfig = config ?? themeManager.currentConfig;

    return GlassmorphismCard(
      key: key,
      blur: finalConfig.blur,
      opacity: finalConfig.opacity,
      borderRadius: finalConfig.borderRadius,
      borderWidth: finalConfig.borderWidth,
      borderColor: finalConfig.borderColor,
      backgroundColor: finalConfig.backgroundColor,
      enablePerformanceOptimization: finalConfig.enablePerformanceOptimization,
      height: height,
      width: width,
      margin: margin,
      padding: padding,
      boxShadow: boxShadow,
      child: child,
    );
  }

  /// 创建响应式毛玻璃卡片
  factory GlassmorphismCard.responsive({
    Key? key,
    required Widget child,
    required BuildContext context,
    GlassmorphismConfig? config,
    double? height,
    double? width,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    List<BoxShadow>? boxShadow,
  }) {
    final responsiveConfig =
        config ?? ResponsiveGlassmorphismConfig.forScreenSize(context);

    return GlassmorphismCard(
      key: key,
      blur: responsiveConfig.blur,
      opacity: responsiveConfig.opacity,
      borderRadius: responsiveConfig.borderRadius,
      borderWidth: responsiveConfig.borderWidth,
      borderColor: responsiveConfig.borderColor,
      backgroundColor: responsiveConfig.backgroundColor,
      enablePerformanceOptimization:
          responsiveConfig.enablePerformanceOptimization,
      height: height,
      width: width,
      margin: margin,
      padding: padding,
      boxShadow: boxShadow,
      child: child,
    );
  }

  @override
  State<GlassmorphismCard> createState() => _GlassmorphismCardState();
}

class _GlassmorphismCardState extends State<GlassmorphismCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => widget.enablePerformanceOptimization;

  /// 验证参数范围
  bool _validateParameters() {
    return widget.blur >= 0.0 &&
        widget.blur <= 20.0 &&
        widget.opacity >= 0.0 &&
        widget.opacity <= 1.0;
  }

  /// 获取优化后的模糊度
  double _getOptimizedBlur() {
    if (!widget.enablePerformanceOptimization) {
      return widget.blur;
    }

    // 根据设备性能调整模糊度
    final defaultBlur = widget.blur.clamp(5.0, 15.0);
    return defaultBlur;
  }

  /// 获取优化后的透明度
  double _getOptimizedOpacity() {
    if (!widget.enablePerformanceOptimization) {
      return widget.opacity;
    }

    // 确保最小可见性
    return widget.opacity.clamp(0.05, 0.2);
  }

  /// 获取背景颜色
  Color _getBackgroundColor() {
    return widget.backgroundColor.withOpacity(_getOptimizedOpacity());
  }

  /// 获取默认阴影
  List<BoxShadow> _getDefaultShadow() {
    if (widget.boxShadow != null) {
      return widget.boxShadow!;
    }

    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        spreadRadius: 2,
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // 参数验证
    if (!_validateParameters()) {
      return Container(
        width: widget.width,
        height: widget.height,
        margin: widget.margin,
        padding: widget.padding,
        child: const Card(
          child: Center(
            child: Text('Invalid glassmorphism parameters'),
          ),
        ),
      );
    }

    final optimizedBlur = _getOptimizedBlur();
    final backgroundColor = _getBackgroundColor();
    final shadow = _getDefaultShadow();

    return Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: optimizedBlur,
            sigmaY: optimizedBlur,
          ),
          child: Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: widget.borderColor.withOpacity(0.3),
                width: widget.borderWidth,
              ),
              boxShadow: shadow,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// 毛玻璃预设样式
class GlassmorphismPresets {
  /// 轻微毛玻璃效果
  static GlassmorphismCard light({
    required Widget child,
    double? borderRadius,
  }) {
    return GlassmorphismCard(
      blur: 5.0,
      opacity: 0.05,
      borderRadius: borderRadius ?? 8.0,
      borderWidth: 0.5,
      borderColor: Colors.white,
      backgroundColor: Colors.white,
      child: child,
    );
  }

  /// 中等毛玻璃效果
  static GlassmorphismCard medium({
    required Widget child,
    double? borderRadius,
  }) {
    return GlassmorphismCard(
      blur: 10.0,
      opacity: 0.1,
      borderRadius: borderRadius ?? 12.0,
      borderWidth: 1.0,
      borderColor: Colors.white,
      backgroundColor: Colors.white,
      child: child,
    );
  }

  /// 强烈毛玻璃效果
  static GlassmorphismCard strong({
    required Widget child,
    double? borderRadius,
  }) {
    return GlassmorphismCard(
      blur: 15.0,
      opacity: 0.15,
      borderRadius: borderRadius ?? 16.0,
      borderWidth: 1.5,
      borderColor: Colors.white,
      backgroundColor: Colors.white,
      child: child,
    );
  }

  /// 深色主题毛玻璃效果
  static GlassmorphismCard dark({
    required Widget child,
    double? borderRadius,
  }) {
    return GlassmorphismCard(
      blur: 8.0,
      opacity: 0.08,
      borderRadius: borderRadius ?? 12.0,
      borderWidth: 1.0,
      borderColor: Colors.black.withOpacity(0.3),
      backgroundColor: Colors.black,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          spreadRadius: 2,
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
      child: child,
    );
  }
}
