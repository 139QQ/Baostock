import 'package:flutter/material.dart';

import '../theme/design_tokens/app_animation.dart';
import '../theme/design_tokens/app_spacing.dart';

/// 响应式布局系统
///
/// 基于UX设计规范的桌面端优先响应式布局框架
/// 提供网格、容器、断点管理等完整的响应式解决方案
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? largeDesktop;
  final Widget fallback;
  final Breakpoint breakpoint;

  const ResponsiveLayout({
    Key? key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
    required this.fallback,
    this.breakpoint = Breakpoint.system,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final actualBreakpoint = _getActualBreakpoint(width);

        switch (actualBreakpoint) {
          case BreakpointSize.mobile:
            return mobile;
          case BreakpointSize.tablet:
            return tablet ?? fallback;
          case BreakpointSize.desktop:
            return desktop ?? fallback;
          case BreakpointSize.largeDesktop:
            return largeDesktop ?? desktop ?? fallback;
        }
      },
    );
  }

  BreakpointSize _getActualBreakpoint(double width) {
    switch (breakpoint) {
      case Breakpoint.custom:
        // 自定义断点逻辑可以在这里实现
        return _getCustomBreakpoint(width);
      case Breakpoint.system:
      default:
        return _getSystemBreakpoint(width);
    }
  }

  BreakpointSize _getSystemBreakpoint(double width) {
    if (width < BreakpointTokens.tablet) {
      return BreakpointSize.mobile;
    } else if (width < BreakpointTokens.desktopSM) {
      return BreakpointSize.tablet;
    } else if (width < BreakpointTokens.desktopXL) {
      return BreakpointSize.desktop;
    } else {
      return BreakpointSize.largeDesktop;
    }
  }

  BreakpointSize _getCustomBreakpoint(double width) {
    // 可以根据需要实现自定义断点逻辑
    return _getSystemBreakpoint(width);
  }
}

/// 响应式容器
///
/// 提供最大宽度和居中对齐的响应式容器
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;
  final bool center;
  final Alignment alignment;

  const ResponsiveContainer({
    Key? key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.center = true,
    this.alignment = Alignment.topCenter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final containerMaxWidth =
            maxWidth ?? _getContainerMaxWidth(constraints.maxWidth);
        final containerPadding =
            padding ?? _getContainerPadding(constraints.maxWidth);

        return Container(
          width: containerMaxWidth,
          alignment: center ? alignment : null,
          padding: containerPadding,
          child: center ? child : _buildAlignedChild(child),
        );
      },
    );
  }

  Widget _buildAlignedChild(Widget child) {
    return Align(
      alignment: alignment,
      child: child,
    );
  }

  double _getContainerMaxWidth(double screenWidth) {
    if (screenWidth >= BreakpointTokens.containerXL) {
      return BreakpointTokens.containerXL;
    } else if (screenWidth >= BreakpointTokens.containerLG) {
      return BreakpointTokens.containerLG;
    } else if (screenWidth >= BreakpointTokens.containerMD) {
      return BreakpointTokens.containerMD;
    } else if (screenWidth >= BreakpointTokens.containerSM) {
      return BreakpointTokens.containerSM;
    } else {
      return double.infinity;
    }
  }

  EdgeInsets _getContainerPadding(double screenWidth) {
    if (screenWidth >= BreakpointTokens.desktopLG) {
      return const EdgeInsets.symmetric(
          horizontal: LayoutSpacing.largeDesktopPadding);
    } else if (screenWidth >= BreakpointTokens.tablet) {
      return const EdgeInsets.symmetric(
          horizontal: LayoutSpacing.desktopPadding);
    } else {
      return const EdgeInsets.symmetric(
          horizontal: LayoutSpacing.mobilePadding);
    }
  }
}

/// 响应式网格系统
///
/// 基于12列网格的响应式布局系统
class ResponsiveGrid extends StatelessWidget {
  final List<ResponsiveGridItem> children;
  final double gap;
  final EdgeInsets? padding;
  final WrapCrossAlignment crossAxisAlignment;

  const ResponsiveGrid({
    Key? key,
    required this.children,
    this.gap = BaseSpacing.md,
    this.padding,
    this.crossAxisAlignment = WrapCrossAlignment.start,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final breakpoint = _getBreakpointSize(constraints.maxWidth);
        final columns = _getColumnsForBreakpoint(breakpoint);

        return Padding(
          padding: padding ?? EdgeInsets.zero,
          child: Wrap(
            spacing: gap,
            runSpacing: gap,
            crossAxisAlignment: crossAxisAlignment,
            children: _buildGridItems(breakpoint, columns),
          ),
        );
      },
    );
  }

  List<Widget> _buildGridItems(BreakpointSize breakpoint, int totalColumns) {
    return children.map((item) {
      final columns = item.getColumnsForBreakpoint(breakpoint);
      return SizedBox(
        width: _calculateItemWidth(columns, totalColumns),
        child: item.child,
      );
    }).toList();
  }

  double _calculateItemWidth(int itemColumns, int totalColumns) {
    // 简化的列宽计算
    // 在实际应用中可能需要考虑gap的影响
    return (itemColumns / totalColumns) * 100.0;
  }

  int _getColumnsForBreakpoint(BreakpointSize breakpoint) {
    switch (breakpoint) {
      case BreakpointSize.mobile:
        return 4; // 移动端使用4列
      case BreakpointSize.tablet:
        return 8; // 平板端使用8列
      case BreakpointSize.desktop:
      case BreakpointSize.largeDesktop:
        return 12; // 桌面端使用12列
    }
  }

  BreakpointSize _getBreakpointSize(double width) {
    if (width < BreakpointTokens.tablet) {
      return BreakpointSize.mobile;
    } else if (width < BreakpointTokens.desktopSM) {
      return BreakpointSize.tablet;
    } else if (width < BreakpointTokens.desktopXL) {
      return BreakpointSize.desktop;
    } else {
      return BreakpointSize.largeDesktop;
    }
  }
}

/// 响应式网格项
class ResponsiveGridItem {
  final Widget child;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final int? largeDesktopColumns;
  final int defaultColumns;

  const ResponsiveGridItem({
    required this.child,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.largeDesktopColumns,
    this.defaultColumns = 12,
  });

  int getColumnsForBreakpoint(BreakpointSize breakpoint) {
    switch (breakpoint) {
      case BreakpointSize.mobile:
        return mobileColumns ?? defaultColumns;
      case BreakpointSize.tablet:
        return tabletColumns ?? mobileColumns ?? defaultColumns;
      case BreakpointSize.desktop:
        return desktopColumns ??
            tabletColumns ??
            mobileColumns ??
            defaultColumns;
      case BreakpointSize.largeDesktop:
        return largeDesktopColumns ??
            desktopColumns ??
            tabletColumns ??
            mobileColumns ??
            defaultColumns;
    }
  }
}

/// 响应式侧边栏布局
///
/// 可折叠的响应式侧边栏布局系统
class ResponsiveSidebarLayout extends StatefulWidget {
  final Widget sidebar;
  final Widget main;
  final Widget? header;
  final Widget? footer;
  final double sidebarWidth;
  final double mobileSidebarWidth;
  final bool autoHideSidebar;
  final Animation<double>? animation;

  const ResponsiveSidebarLayout({
    Key? key,
    required this.sidebar,
    required this.main,
    this.header,
    this.footer,
    this.sidebarWidth = 280,
    this.mobileSidebarWidth = 320,
    this.autoHideSidebar = true,
    this.animation,
  }) : super(key: key);

  @override
  State<ResponsiveSidebarLayout> createState() =>
      _ResponsiveSidebarLayoutState();
}

class _ResponsiveSidebarLayoutState extends State<ResponsiveSidebarLayout>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _isSidebarVisible = true;
  bool _isMobile = false;

  @override
  void initState() {
    super.initState();

    if (widget.animation != null) {
      _slideAnimation = widget.animation!;
      _fadeAnimation = widget.animation!;
    } else {
      _animationController = AnimationController(
        duration: AnimationDurations.normal,
        vsync: this,
      );

      _slideAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: AnimationCurves.easeOutCubic,
      ));

      _fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: AnimationCurves.easeOut,
      ));

      _animationController.forward();
    }
  }

  @override
  void dispose() {
    if (widget.animation == null) {
      _animationController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < BreakpointTokens.tablet;

        if (isMobile != _isMobile) {
          _isMobile = isMobile;
          if (widget.autoHideSidebar && isMobile) {
            _isSidebarVisible = false;
          }
        }

        if (isMobile) {
          return _buildMobileLayout();
        } else {
          return _buildDesktopLayout();
        }
      },
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      body: Column(
        children: [
          if (widget.header != null) widget.header!,
          Expanded(
            child: widget.main,
          ),
          if (widget.footer != null) widget.footer!,
        ],
      ),
      drawer: Drawer(
        width: widget.mobileSidebarWidth,
        child: widget.sidebar,
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        AnimatedBuilder(
          animation: widget.animation ?? _animationController,
          builder: (context, child) {
            return AnimatedContainer(
              duration: AnimationDurations.normal,
              width: _isSidebarVisible ? widget.sidebarWidth : 0,
              child: _isSidebarVisible
                  ? Transform.translate(
                      offset: Offset(
                        (1 - _slideAnimation.value) * -widget.sidebarWidth,
                        0,
                      ),
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: widget.sidebar,
                      ),
                    )
                  : null,
            );
          },
        ),
        Expanded(
          child: Column(
            children: [
              if (widget.header != null) widget.header!,
              Expanded(child: widget.main),
              if (widget.footer != null) widget.footer!,
            ],
          ),
        ),
      ],
    );
  }
}

/// 响应式断点工具
class ResponsiveUtils {
  ResponsiveUtils._();

  /// 获取当前断点
  static BreakpointSize getBreakpoint(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < BreakpointTokens.tablet) {
      return BreakpointSize.mobile;
    } else if (width < BreakpointTokens.desktopSM) {
      return BreakpointSize.tablet;
    } else if (width < BreakpointTokens.desktopXL) {
      return BreakpointSize.desktop;
    } else {
      return BreakpointSize.largeDesktop;
    }
  }

  /// 检查是否为移动端
  static bool isMobile(BuildContext context) {
    return getBreakpoint(context) == BreakpointSize.mobile;
  }

  /// 检查是否为平板端
  static bool isTablet(BuildContext context) {
    return getBreakpoint(context) == BreakpointSize.tablet;
  }

  /// 检查是否为桌面端
  static bool isDesktop(BuildContext context) {
    final breakpoint = getBreakpoint(context);
    return breakpoint == BreakpointSize.desktop ||
        breakpoint == BreakpointSize.largeDesktop;
  }

  /// 获取响应式值
  static T getValue<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    final breakpoint = getBreakpoint(context);
    switch (breakpoint) {
      case BreakpointSize.mobile:
        return mobile;
      case BreakpointSize.tablet:
        return tablet ?? mobile;
      case BreakpointSize.desktop:
        return desktop ?? tablet ?? mobile;
      case BreakpointSize.largeDesktop:
        return largeDesktop ?? desktop ?? tablet ?? mobile;
    }
  }

  /// 获取响应式字体大小
  static double getResponsiveFontSize(
      BuildContext context, double baseFontSize) {
    final breakpoint = getBreakpoint(context);
    switch (breakpoint) {
      case BreakpointSize.mobile:
        return baseFontSize * 0.875;
      case BreakpointSize.tablet:
        return baseFontSize * 0.9375;
      case BreakpointSize.desktop:
        return baseFontSize;
      case BreakpointSize.largeDesktop:
        return baseFontSize * 1.125;
    }
  }

  /// 获取响应式间距
  static double getResponsiveSpacing(BuildContext context, double baseSpacing) {
    final breakpoint = getBreakpoint(context);
    switch (breakpoint) {
      case BreakpointSize.mobile:
        return baseSpacing * 0.75;
      case BreakpointSize.tablet:
        return baseSpacing * 0.875;
      case BreakpointSize.desktop:
        return baseSpacing;
      case BreakpointSize.largeDesktop:
        return baseSpacing * 1.125;
    }
  }
}

/// 断点大小枚举
enum BreakpointSize {
  mobile,
  tablet,
  desktop,
  largeDesktop,
}

/// 断点类型
enum Breakpoint {
  system,
  custom,
}
