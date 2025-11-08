import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens/app_spacing.dart';
import '../theme/design_tokens/app_typography.dart';

/// 动画持续时间常量
///
/// 定义应用中常用的动画持续时间，确保动画效果的一致性
class AnimationDurations {
  AnimationDurations._();

  /// 快速动画 (150ms)
  static const Duration fast = Duration(milliseconds: 150);

  /// 标准动画 (300ms)
  static const Duration normal = Duration(milliseconds: 300);

  /// 慢速动画 (500ms)
  static const Duration slow = Duration(milliseconds: 500);
}

/// 毛玻璃效果组件
///
/// 基于UX设计规范的Fluent Design毛玻璃效果
/// 支持自定义模糊度、透明度和动画效果
class GlassmorphismContainer extends StatelessWidget {
  final Widget child;
  final GlassmorphismConfig? config;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final bool enableAnimation;
  final Duration? animationDuration;

  const GlassmorphismContainer({
    Key? key,
    required this.child,
    this.config,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
    this.enableAnimation = true,
    this.animationDuration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glassConfig = config ??
        (theme.extension<GlassmorphismThemeData>()?.cardConfig ??
            GlassmorphismConfig.medium);

    final container = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius:
            borderRadius ?? BorderRadius.circular(glassConfig.borderRadius),
        border: Border.all(
          color: glassConfig.borderColor.withOpacity(0.3),
          width: glassConfig.borderWidth,
        ),
        boxShadow: _getGlassShadow(glassConfig),
      ),
      child: ClipRRect(
        borderRadius:
            borderRadius ?? BorderRadius.circular(glassConfig.borderRadius),
        child: Stack(
          children: [
            // 背景模糊层
            _buildBlurLayer(glassConfig),
            // 内容
            child,
          ],
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius:
            borderRadius ?? BorderRadius.circular(glassConfig.borderRadius),
        child: container,
      );
    }

    return enableAnimation
        ? _buildAnimatedContainer(container, glassConfig)
        : container;
  }

  Widget _buildBlurLayer(GlassmorphismConfig config) {
    return Container(
      decoration: BoxDecoration(
        color: config.backgroundColor.withOpacity(config.opacity),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: config.blur,
          sigmaY: config.blur,
        ),
        child: Container(),
      ),
    );
  }

  Widget _buildAnimatedContainer(Widget child, GlassmorphismConfig config) {
    return TweenAnimationBuilder<double>(
      duration: animationDuration ?? AnimationDurations.normal,
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  List<BoxShadow> _getGlassShadow(GlassmorphismConfig config) {
    return [
      BoxShadow(
        color: config.backgroundColor.withOpacity(0.1),
        blurRadius: config.blur / 2,
        offset: const Offset(0, 4),
        spreadRadius: 1,
      ),
      BoxShadow(
        color: config.backgroundColor.withOpacity(0.05),
        blurRadius: config.blur,
        offset: const Offset(0, 8),
        spreadRadius: 2,
      ),
    ];
  }
}

/// 毛玻璃卡片
///
/// 专门用于卡片布局的毛玻璃组件
class GlassmorphismCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final VoidCallback? onTap;
  final GlassmorphismConfig? config;

  const GlassmorphismCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.elevation,
    this.onTap,
    this.config,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final glassConfig = config ??
        (Theme.of(context).extension<GlassmorphismThemeData>()?.cardConfig ??
            GlassmorphismConfig.medium);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(glassConfig.borderRadius),
        boxShadow: elevation != null
            ? _getElevationShadow(elevation!, glassConfig)
            : _getGlassShadow(glassConfig),
      ),
      child: GlassmorphismContainer(
        config: glassConfig,
        padding: padding,
        onTap: onTap,
        child: child,
      ),
    );
  }

  List<BoxShadow> _getElevationShadow(
      double elevation, GlassmorphismConfig config) {
    return [
      BoxShadow(
        color: config.backgroundColor.withOpacity(0.1),
        blurRadius: elevation,
        offset: Offset(0, elevation / 2),
      ),
    ];
  }

  List<BoxShadow> _getGlassShadow(GlassmorphismConfig config) {
    return [
      BoxShadow(
        color: config.backgroundColor.withOpacity(0.1),
        blurRadius: config.blur / 2,
        offset: const Offset(0, 4),
        spreadRadius: 1,
      ),
    ];
  }
}

/// 毛玻璃对话框
///
/// 专用于对话框的毛玻璃效果
class GlassmorphismDialog extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final GlassmorphismConfig? config;

  const GlassmorphismDialog({
    Key? key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.borderRadius,
    this.config,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final glassConfig = config ??
        (Theme.of(context).extension<GlassmorphismThemeData>()?.dialogConfig ??
            GlassmorphismConfig.light);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassmorphismContainer(
        config: glassConfig,
        width: width,
        height: height,
        padding: padding ?? const EdgeInsets.all(BaseSpacing.lg),
        borderRadius:
            borderRadius ?? BorderRadius.circular(glassConfig.borderRadius),
        child: child,
      ),
    );
  }
}

/// 毛玻璃导航栏
///
/// 专用于导航栏的毛玻璃效果
class GlassmorphismAppBar extends StatelessWidget {
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final double? toolbarHeight;
  final GlassmorphismConfig? config;

  const GlassmorphismAppBar({
    Key? key,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.toolbarHeight,
    this.config,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final glassConfig = config ??
        (Theme.of(context)
                .extension<GlassmorphismThemeData>()
                ?.navigationConfig ??
            GlassmorphismConfig.performance);

    return Container(
      height: toolbarHeight ?? kToolbarHeight,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: glassConfig.borderColor.withOpacity(0.2),
            width: glassConfig.borderWidth,
          ),
        ),
      ),
      child: GlassmorphismContainer(
        config: glassConfig,
        child: NavigationToolbar(
          leading: leading,
          middle: title != null
              ? Text(
                  title!,
                  style: AppTextStyles.h6.copyWith(
                    color: Theme.of(context).appBarTheme.titleTextStyle?.color,
                  ),
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: actions ?? [],
          ),
        ),
      ),
    );
  }
}

/// 毛玻璃底部导航栏
///
/// 专用于底部导航的毛玻璃效果
class GlassmorphismBottomBar extends StatelessWidget {
  final List<BottomNavigationBarItem> items;
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final GlassmorphismConfig? config;

  const GlassmorphismBottomBar({
    Key? key,
    required this.items,
    required this.currentIndex,
    this.onTap,
    this.config,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final glassConfig = config ??
        (Theme.of(context)
                .extension<GlassmorphismThemeData>()
                ?.navigationConfig ??
            GlassmorphismConfig.performance);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: glassConfig.borderColor.withOpacity(0.2),
            width: glassConfig.borderWidth,
          ),
        ),
      ),
      child: GlassmorphismContainer(
        config: glassConfig,
        child: BottomNavigationBar(
          items: items,
          currentIndex: currentIndex,
          onTap: onTap,
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 12,
        ),
      ),
    );
  }
}

/// 毛玻璃浮动操作按钮
///
/// 专用于FAB的毛玻璃效果
class GlassmorphismFab extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String? tooltip;
  final BoxConstraints? constraints;
  final GlassmorphismConfig? config;

  const GlassmorphismFab({
    Key? key,
    required this.child,
    this.onPressed,
    this.tooltip,
    this.constraints,
    this.config,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final glassConfig = config ?? GlassmorphismConfig.light;

    final fab = Container(
      constraints: constraints,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: _getFabShadow(glassConfig),
      ),
      child: GlassmorphismContainer(
        config: glassConfig,
        child: child,
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: FloatingActionButton(
          onPressed: onPressed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: fab,
        ),
      );
    }

    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: fab,
    );
  }

  List<BoxShadow> _getFabShadow(GlassmorphismConfig config) {
    return [
      BoxShadow(
        color: config.backgroundColor.withOpacity(0.3),
        blurRadius: config.blur,
        offset: const Offset(0, 4),
        spreadRadius: 1,
      ),
    ];
  }
}

/// Windows 平台特有的毛玻璃工具
///
/// 提供Windows平台特定的毛玻璃效果支持
class WindowsGlassmorphism {
  WindowsGlassmorphism._();

  /// 检查是否支持Windows毛玻璃效果
  static bool get isSupported {
    // 在实际项目中，这里应该检查是否在Windows平台
    // 并且版本是否支持毛玻璃效果
    return true;
  }

  /// 获取系统毛玻璃配置
  static GlassmorphismConfig getSystemConfig() {
    // 返回基于系统主题的毛玻璃配置
    return GlassmorphismConfig(
      blur: 10.0,
      opacity: 0.1,
      borderRadius: 8.0,
      borderWidth: 1.0,
      borderColor: Colors.white.withOpacity(0.2),
      backgroundColor: Colors.white.withOpacity(0.1),
      enablePerformanceOptimization: true,
    );
  }

  /// 创建Windows风格的毛玻璃容器
  static Widget createWindowsGlassContainer({
    required Widget child,
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
  }) {
    return GlassmorphismContainer(
      config: getSystemConfig(),
      padding: padding,
      borderRadius: borderRadius,
      child: child,
    );
  }

  /// 创建Windows风格的毛玻璃卡片
  static Widget createWindowsGlassCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return GlassmorphismCard(
      config: getSystemConfig(),
      padding: padding,
      margin: margin,
      child: child,
    );
  }
}
