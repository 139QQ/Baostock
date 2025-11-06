import 'package:flutter/material.dart';

/// 响应式布局构建器
///
/// 提供统一的响应式布局解决方案，支持：
/// - 多设备断点定义
/// - 响应式尺寸计算
/// - 布局适配策略
/// - 主题样式切换
class ResponsiveLayoutBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ScreenType screenType) builder;
  final Widget? mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayoutBuilder({
    super.key,
    required this.builder,
    this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenType = ResponsiveUtils.getScreenType(constraints.maxWidth);
        return builder(context, screenType);
      },
    );
  }
}

/// 响应式工具类
class ResponsiveUtils {
  /// 断点定义
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
  static const double largeDesktopBreakpoint = 1600;

  /// 获取屏幕类型
  static ScreenType getScreenType(double width) {
    if (width >= largeDesktopBreakpoint) {
      return ScreenType.largeDesktop;
    } else if (width >= desktopBreakpoint) {
      return ScreenType.desktop;
    } else if (width >= tabletBreakpoint) {
      return ScreenType.tablet;
    } else {
      return ScreenType.mobile;
    }
  }

  /// 获取响应式列数
  static int getResponsiveColumns({
    required double width,
    required Map<ScreenType, int> columns,
  }) {
    final screenType = getScreenType(width);
    return columns[screenType] ?? columns[ScreenType.mobile] ?? 1;
  }

  /// 获取响应式间距
  static double getResponsiveSpacing({
    required double width,
    required Map<ScreenType, double> spacings,
  }) {
    final screenType = getScreenType(width);
    return spacings[screenType] ?? spacings[ScreenType.mobile] ?? 8.0;
  }

  /// 获取响应式字体大小
  static double getResponsiveFontSize({
    required double width,
    required Map<ScreenType, double> sizes,
  }) {
    final screenType = getScreenType(width);
    return sizes[screenType] ?? sizes[ScreenType.mobile] ?? 14.0;
  }

  /// 获取响应式内边距
  static EdgeInsets getResponsivePadding({
    required double width,
    required Map<ScreenType, EdgeInsets> paddings,
  }) {
    final screenType = getScreenType(width);
    return paddings[screenType] ??
        paddings[ScreenType.mobile] ??
        const EdgeInsets.all(16);
  }

  /// 获取响应式组件高度
  static double getResponsiveHeight({
    required double width,
    required Map<ScreenType, double> heights,
  }) {
    final screenType = getScreenType(width);
    return heights[screenType] ?? heights[ScreenType.mobile] ?? 200.0;
  }

  /// 判断是否为移动设备
  static bool isMobile(double width) {
    return width < tabletBreakpoint;
  }

  /// 判断是否为平板设备
  static bool isTablet(double width) {
    return width >= tabletBreakpoint && width < desktopBreakpoint;
  }

  /// 判断是否为桌面设备
  static bool isDesktop(double width) {
    return width >= desktopBreakpoint;
  }

  /// 获取响应式边距
  static double getResponsiveMargin({
    required double width,
    required Map<ScreenType, double> margins,
  }) {
    final screenType = getScreenType(width);
    return margins[screenType] ?? margins[ScreenType.mobile] ?? 8.0;
  }

  /// 获取响应式图标大小
  static double getResponsiveIconSize({
    required double width,
    required Map<ScreenType, double> sizes,
  }) {
    final screenType = getScreenType(width);
    return sizes[screenType] ?? sizes[ScreenType.mobile] ?? 24.0;
  }

  /// 获取响应式圆角半径
  static double getResponsiveBorderRadius({
    required double width,
    required Map<ScreenType, double> radii,
  }) {
    final screenType = getScreenType(width);
    return radii[screenType] ?? radii[ScreenType.mobile] ?? 8.0;
  }
}

/// 屏幕类型枚举
enum ScreenType {
  mobile,
  tablet,
  desktop,
  largeDesktop,
}

/// 响应式布局常量
class ResponsiveConstants {
  // 列数配置
  static const Map<ScreenType, int> defaultGridColumns = {
    ScreenType.mobile: 1,
    ScreenType.tablet: 2,
    ScreenType.desktop: 3,
    ScreenType.largeDesktop: 4,
  };

  // 间距配置
  static const Map<ScreenType, double> defaultSpacing = {
    ScreenType.mobile: 8.0,
    ScreenType.tablet: 12.0,
    ScreenType.desktop: 16.0,
    ScreenType.largeDesktop: 20.0,
  };

  // 字体大小配置
  static const Map<ScreenType, double> defaultFontSizes = {
    ScreenType.mobile: 14.0,
    ScreenType.tablet: 15.0,
    ScreenType.desktop: 16.0,
    ScreenType.largeDesktop: 18.0,
  };

  // 内边距配置
  static const Map<ScreenType, EdgeInsets> defaultPadding = {
    ScreenType.mobile: EdgeInsets.all(16),
    ScreenType.tablet: EdgeInsets.all(20),
    ScreenType.desktop: EdgeInsets.all(24),
    ScreenType.largeDesktop: EdgeInsets.all(32),
  };

  // 组件高度配置
  static const Map<ScreenType, double> defaultHeights = {
    ScreenType.mobile: 200.0,
    ScreenType.tablet: 250.0,
    ScreenType.desktop: 300.0,
    ScreenType.largeDesktop: 350.0,
  };

  // 图标大小配置
  static const Map<ScreenType, double> defaultIconSizes = {
    ScreenType.mobile: 20.0,
    ScreenType.tablet: 22.0,
    ScreenType.desktop: 24.0,
    ScreenType.largeDesktop: 26.0,
  };

  // 圆角半径配置
  static const Map<ScreenType, double> defaultBorderRadius = {
    ScreenType.mobile: 8.0,
    ScreenType.tablet: 10.0,
    ScreenType.desktop: 12.0,
    ScreenType.largeDesktop: 14.0,
  };
}

/// 响应式容器组件
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? maxWidth;
  final bool centerContent;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth,
    this.centerContent = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final responsivePadding = padding ??
            ResponsiveUtils.getResponsivePadding(
              width: constraints.maxWidth,
              paddings: ResponsiveConstants.defaultPadding,
            );

        final containerMaxWidth = maxWidth ??
            (ResponsiveUtils.isDesktop(constraints.maxWidth)
                ? 1200.0
                : double.infinity);

        return Container(
          width: double.infinity,
          padding: responsivePadding,
          child: centerContent
              ? Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: containerMaxWidth),
                    child: child,
                  ),
                )
              : ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: containerMaxWidth),
                  child: child,
                ),
        );
      },
    );
  }
}

/// 响应式网格组件
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final Map<ScreenType, int>? columns;
  final Map<ScreenType, double>? spacing;
  final Map<ScreenType, double>? runSpacing;
  final bool shrinkWrap;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.columns,
    this.spacing,
    this.runSpacing,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = ResponsiveUtils.getResponsiveColumns(
          width: constraints.maxWidth,
          columns: columns ?? ResponsiveConstants.defaultGridColumns,
        );

        final childSpacing = ResponsiveUtils.getResponsiveSpacing(
          width: constraints.maxWidth,
          spacings: spacing ?? ResponsiveConstants.defaultSpacing,
        );

        final childRunSpacing = ResponsiveUtils.getResponsiveSpacing(
          width: constraints.maxWidth,
          spacings: runSpacing ?? ResponsiveConstants.defaultSpacing,
        );

        return GridView.count(
          shrinkWrap: shrinkWrap,
          physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: childSpacing,
          mainAxisSpacing: childRunSpacing,
          children: children,
        );
      },
    );
  }
}

/// 响应式文本组件
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Map<ScreenType, TextStyle>? responsiveStyles;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.responsiveStyles,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenType = ResponsiveUtils.getScreenType(constraints.maxWidth);

        TextStyle effectiveStyle = style ?? const TextStyle();

        if (responsiveStyles != null &&
            responsiveStyles!.containsKey(screenType)) {
          effectiveStyle = effectiveStyle.merge(responsiveStyles![screenType]);
        }

        return Text(
          text,
          style: effectiveStyle,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );
      },
    );
  }
}

/// 响应式卡片组件
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final Map<ScreenType, EdgeInsets>? padding;
  final Map<ScreenType, double>? borderRadius;
  final Map<ScreenType, double>? elevation;
  final Color? color;
  final VoidCallback? onTap;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.elevation,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenType = ResponsiveUtils.getScreenType(constraints.maxWidth);

        final cardPadding = ResponsiveUtils.getResponsivePadding(
          width: constraints.maxWidth,
          paddings: padding ??
              {
                ScreenType.mobile: const EdgeInsets.all(12),
                ScreenType.tablet: const EdgeInsets.all(16),
                ScreenType.desktop: const EdgeInsets.all(20),
                ScreenType.largeDesktop: const EdgeInsets.all(24),
              },
        );

        final cardBorderRadius = ResponsiveUtils.getResponsiveBorderRadius(
          width: constraints.maxWidth,
          radii: borderRadius ?? ResponsiveConstants.defaultBorderRadius,
        );

        final cardElevation = elevation?[screenType] ??
            (ResponsiveUtils.isDesktop(constraints.maxWidth) ? 4.0 : 2.0);

        return Card(
          elevation: cardElevation,
          color: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardBorderRadius),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(cardBorderRadius),
            child: Padding(
              padding: cardPadding,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
