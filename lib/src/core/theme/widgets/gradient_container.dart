import 'package:flutter/material.dart';
import '../design_tokens/app_colors.dart';

/// 现代渐变容器组件
///
/// 提供多种预定义渐变效果，支持FinTech设计风格
class GradientContainer extends StatelessWidget {
  final Widget child;
  final Gradient? gradient;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final DecorationImage? image;
  final Color? backgroundColor;

  const GradientContainer({
    Key? key,
    required this.child,
    this.gradient,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.border,
    this.boxShadow,
    this.image,
    this.backgroundColor,
  }) : super(key: key);

  /// 主渐变容器 - 深蓝到浅蓝
  factory GradientContainer.primary({
    Key? key,
    required Widget child,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BorderRadius? borderRadius,
    BoxBorder? border,
    List<BoxShadow>? boxShadow,
  }) {
    return GradientContainer(
      key: key,
      gradient: FinancialGradients.primaryGradient,
      child: child,
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      border: border,
      boxShadow: boxShadow ??
          [
            BoxShadow(
              color: BaseColors.primary600.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
    );
  }

  /// 成功/增长渐变容器 - 金色系
  factory GradientContainer.success({
    Key? key,
    required Widget child,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BorderRadius? borderRadius,
    BoxBorder? border,
    List<BoxShadow>? boxShadow,
  }) {
    return GradientContainer(
      key: key,
      gradient: FinancialGradients.successGradient,
      child: child,
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      border: border,
      boxShadow: boxShadow ??
          [
            BoxShadow(
              color: BaseColors.gold600.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
    );
  }

  /// 科技创新渐变容器 - 紫色系
  factory GradientContainer.tech({
    Key? key,
    required Widget child,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BorderRadius? borderRadius,
    BoxBorder? border,
    List<BoxShadow>? boxShadow,
  }) {
    return GradientContainer(
      key: key,
      gradient: FinancialGradients.techGradient,
      child: child,
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      border: border,
      boxShadow: boxShadow ??
          [
            BoxShadow(
              color: BaseColors.tech600.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
    );
  }

  /// 市场数据渐变容器 - 蓝金组合
  factory GradientContainer.market({
    Key? key,
    required Widget child,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BorderRadius? borderRadius,
    BoxBorder? border,
    List<BoxShadow>? boxShadow,
  }) {
    return GradientContainer(
      key: key,
      gradient: FinancialGradients.marketGradient,
      child: child,
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      border: border,
      boxShadow: boxShadow ??
          [
            BoxShadow(
              color: BaseColors.primary600.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
    );
  }

  /// 玻璃拟态卡片容器
  factory GradientContainer.glass({
    Key? key,
    required Widget child,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BorderRadius? borderRadius,
    BoxBorder? border,
    double opacity = 0.1,
  }) {
    return GradientContainer(
      key: key,
      gradient: FinancialGradients.cardGradient,
      backgroundColor: Colors.white.withOpacity(opacity),
      child: child,
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      border: border ??
          Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.white.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(-2, -2),
        ),
      ],
    );
  }

  /// 按钮渐变容器
  factory GradientContainer.button({
    Key? key,
    required Widget child,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
    VoidCallback? onTap,
  }) {
    return GradientContainer(
      key: key,
      gradient: FinancialGradients.buttonGradient,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
          child: Container(
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: child,
          ),
        ),
      ),
      width: width,
      height: height,
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
          color: BaseColors.primary600.withOpacity(0.4),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        gradient: gradient,
        color: backgroundColor,
        borderRadius: borderRadius,
        border: border,
        boxShadow: boxShadow,
        image: image,
      ),
      child: child,
    );
  }
}

/// 渐变文本组件
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Gradient? gradient;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const GradientText(
    this.text, {
    Key? key,
    this.style,
    this.gradient,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : super(key: key);

  /// 主渐变文本
  factory GradientText.primary(
    String text, {
    Key? key,
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return GradientText(
      text,
      key: key,
      gradient: FinancialGradients.primaryGradient,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  /// 金色渐变文本
  factory GradientText.gold(
    String text, {
    Key? key,
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return GradientText(
      text,
      key: key,
      gradient: FinancialGradients.successGradient,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) =>
          (gradient ?? FinancialGradients.primaryGradient).createShader(bounds),
      child: Text(
        text,
        style: (style ?? const TextStyle()).copyWith(
          color: Colors.white,
        ),
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }
}
