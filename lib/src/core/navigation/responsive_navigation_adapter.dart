import 'package:flutter/material.dart';

/// 响应式导航适配器
///
/// 根据不同的平台和屏幕尺寸提供最适合的导航体验
/// 支持桌面端、Web端和移动端的不同导航模式
class ResponsiveNavigationAdapter {
  const ResponsiveNavigationAdapter._();

  /// 获取当前平台的导航类型
  static NavigationType getNavigationType(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final targetPlatform = Theme.of(context).platform;

    // 桌面端判断
    if (_isDesktopPlatform(targetPlatform)) {
      if (screenWidth >= 1200) {
        return NavigationType.desktopWide;
      } else if (screenWidth >= 800) {
        return NavigationType.desktopCompact;
      } else {
        return NavigationType.tablet;
      }
    }

    // Web端判断
    if (_isWebPlatform(targetPlatform)) {
      if (screenWidth >= 1024) {
        return NavigationType.webDesktop;
      } else if (screenWidth >= 768) {
        return NavigationType.webTablet;
      } else {
        return NavigationType.mobile;
      }
    }

    // 移动端判断
    if (screenWidth >= 768) {
      return NavigationType.tablet;
    } else {
      return NavigationType.mobile;
    }
  }

  /// 获取导航栏配置
  static NavigationConfig getNavigationConfig(BuildContext context) {
    final navigationType = getNavigationType(context);

    switch (navigationType) {
      case NavigationType.desktopWide:
        return NavigationConfig(
          type: navigationType,
          railWidth: 100,
          railExtended: false,
          showAppBar: true,
          showBottomBar: false,
          appBarHeight: 64,
          contentPadding: const EdgeInsets.all(24),
          useMinimalistLayout: true,
        );

      case NavigationType.desktopCompact:
        return NavigationConfig(
          type: navigationType,
          railWidth: 80,
          railExtended: false,
          showAppBar: true,
          showBottomBar: false,
          appBarHeight: 60,
          contentPadding: const EdgeInsets.all(20),
          useMinimalistLayout: true,
        );

      case NavigationType.webDesktop:
        return NavigationConfig(
          type: navigationType,
          railWidth: 100,
          railExtended: true,
          showAppBar: true,
          showBottomBar: false,
          appBarHeight: 64,
          contentPadding: const EdgeInsets.all(24),
          useMinimalistLayout: false,
        );

      case NavigationType.webTablet:
        return NavigationConfig(
          type: navigationType,
          railWidth: 80,
          railExtended: false,
          showAppBar: true,
          showBottomBar: false,
          appBarHeight: 56,
          contentPadding: const EdgeInsets.all(16),
          useMinimalistLayout: false,
        );

      case NavigationType.tablet:
        return NavigationConfig(
          type: navigationType,
          railWidth: 70,
          railExtended: false,
          showAppBar: true,
          showBottomBar: true,
          appBarHeight: 56,
          contentPadding: const EdgeInsets.all(16),
          useMinimalistLayout: false,
        );

      case NavigationType.mobile:
        return NavigationConfig(
          type: navigationType,
          railWidth: 0,
          railExtended: false,
          showAppBar: true,
          showBottomBar: true,
          appBarHeight: 56,
          contentPadding: const EdgeInsets.all(12),
          useMinimalistLayout: false,
        );
    }
  }

  /// 判断是否为桌面平台
  static bool _isDesktopPlatform(TargetPlatform platform) {
    return platform == TargetPlatform.windows ||
        platform == TargetPlatform.macOS ||
        platform == TargetPlatform.linux;
  }

  /// 判断是否为Web平台
  static bool _isWebPlatform(TargetPlatform platform) {
    // 注意：这里假设Web平台会通过其他方式识别
    // 实际项目中可能需要使用 kIsWeb 来判断
    return false; // 暂时返回false，因为我们主要支持Windows
  }

  /// 获取导航栏标签显示类型
  static NavigationRailLabelType getRailLabelType(NavigationConfig config) {
    switch (config.type) {
      case NavigationType.desktopWide:
      case NavigationType.webDesktop:
        return NavigationRailLabelType.all;
      case NavigationType.desktopCompact:
      case NavigationType.webTablet:
        return NavigationRailLabelType.selected;
      case NavigationType.tablet:
      case NavigationType.mobile:
        return NavigationRailLabelType.all;
    }
  }

  /// 是否应该使用抽屉导航
  static bool shouldUseDrawer(NavigationConfig config) {
    return config.type == NavigationType.mobile || config.railWidth == 0;
  }

  /// 获取内容区域的边距
  static EdgeInsets getContentPadding(NavigationConfig config) {
    return config.contentPadding;
  }

  /// 获取最大内容宽度
  static double? getMaxContentWidth(NavigationConfig config) {
    switch (config.type) {
      case NavigationType.desktopWide:
        return 1400;
      case NavigationType.desktopCompact:
      case NavigationType.webDesktop:
        return 1200;
      case NavigationType.webTablet:
      case NavigationType.tablet:
        return null;
      case NavigationType.mobile:
        return null;
    }
  }
}

/// 导航类型枚举
enum NavigationType {
  desktopWide,
  desktopCompact,
  webDesktop,
  webTablet,
  tablet,
  mobile,
}

/// 导航配置类
class NavigationConfig {
  final NavigationType type;
  final double railWidth;
  final bool railExtended;
  final bool showAppBar;
  final bool showBottomBar;
  final double appBarHeight;
  final EdgeInsets contentPadding;
  final bool useMinimalistLayout;

  const NavigationConfig({
    required this.type,
    required this.railWidth,
    required this.railExtended,
    required this.showAppBar,
    required this.showBottomBar,
    required this.appBarHeight,
    required this.contentPadding,
    required this.useMinimalistLayout,
  });

  @override
  String toString() {
    return 'NavigationConfig(type: $type, railWidth: $railWidth, showAppBar: $showAppBar, useBottomBar: $showBottomBar)';
  }
}
