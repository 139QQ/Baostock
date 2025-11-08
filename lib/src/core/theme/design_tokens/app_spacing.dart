import 'package:flutter/material.dart';

/// 基础间距 (Base Spacing)
///
/// 定义基于8px网格系统的间距标准
class BaseSpacing {
  BaseSpacing._();

  static const double xs = 4.0; // 极小间距
  static const double sm = 8.0; // 小间距
  static const double md = 16.0; // 中间距
  static const double lg = 24.0; // 大间距
  static const double xl = 32.0; // 超大间距
  static const double xxl = 48.0; // 极大间距
  static const double xxxl = 64.0; // 超极大间距
}

/// 组件间距 (Component Spacing)
///
/// 组件内部和组件之间的间距定义
class ComponentSpacing {
  ComponentSpacing._();

  // 内边距
  static const double paddingXS = 4.0; // 极小内边距
  static const double paddingSM = 8.0; // 小内边距
  static const double paddingMD = 16.0; // 中内边距
  static const double paddingLG = 24.0; // 大内边距
  static const double paddingXL = 32.0; // 超大内边距
  static const double paddingXXL = 48.0; // 极大内边距

  // 外边距
  static const double marginXS = 4.0; // 极小外边距
  static const double marginSM = 8.0; // 小外边距
  static const double marginMD = 16.0; // 中外边距
  static const double marginLG = 24.0; // 大外边距
  static const double marginXL = 32.0; // 超大外边距
  static const double marginXXL = 48.0; // 极大外边距

  // 元素间距
  static const double gapXS = 4.0; // 极小间隔
  static const double gapSM = 8.0; // 小间隔
  static const double gapMD = 16.0; // 中间隔
  static const double gapLG = 24.0; // 大间隔
  static const double gapXL = 32.0; // 超大间隔
  static const double gapXXL = 48.0; // 极大间隔

  // 卡片间距
  static const double cardPadding = 16.0; // 卡片内边距
  static const double cardPaddingLarge = 24.0; // 大卡片内边距
  static const double cardPaddingSmall = 12.0; // 小卡片内边距
  static const double cardGap = 16.0; // 卡片间距

  // 列表间距
  static const double listItemPadding = 12.0; // 列表项内边距
  static const double listItemGap = 8.0; // 列表项间距
  static const double listSectionGap = 24.0; // 列表区块间距

  // 按钮间距
  static const double buttonPaddingH = 16.0; // 按钮水平内边距
  static const double buttonPaddingV = 8.0; // 按钮垂直内边距
  static const double buttonPaddingHSmall = 12.0; // 小按钮水平内边距
  static const double buttonPaddingVSmall = 6.0; // 小按钮垂直内边距
  static const double buttonGap = 12.0; // 按钮间距

  // 输入框间距
  static const double inputPaddingH = 12.0; // 输入框水平内边距
  static const double inputPaddingV = 12.0; // 输入框垂直内边距
  static const double inputGap = 16.0; // 输入框间距

  // 表单间距
  static const double formFieldGap = 16.0; // 表单字段间距
  static const double formSectionGap = 24.0; // 表单区块间距
  static const double formLabelGap = 8.0; // 标签与输入框间距
}

/// 布局间距 (Layout Spacing)
///
/// 页面和布局级别的间距定义
class LayoutSpacing {
  LayoutSpacing._();

  // 页面布局
  static const double pageHorizontal = 24.0; // 页面水平边距
  static const double pageVertical = 32.0; // 页面垂直边距
  static const double pageHorizontalSmall = 16.0; // 小页面水平边距
  static const double pageVerticalSmall = 24.0; // 小页面垂直边距
  static const double pageHorizontalLarge = 32.0; // 大页面水平边距
  static const double pageVerticalLarge = 48.0; // 大页面垂直边距

  // 区块间距
  static const double sectionVertical = 48.0; // 区块垂直间距
  static const double sectionVerticalSmall = 32.0; // 小区块垂直间距
  static const double sectionVerticalLarge = 64.0; // 大区块垂直间距

  // 网格系统
  static const double gridGap = 16.0; // 网格间距
  static const double gridGapSmall = 12.0; // 小网格间距
  static const double gridGapLarge = 24.0; // 大网格间距
  static const double gridGapXLarge = 32.0; // 超大网格间距

  // 容器间距
  static const double containerPadding = 24.0; // 容器内边距
  static const double containerMargin = 16.0; // 容器外边距

  // 导航间距
  static const double navItemPadding = 12.0; // 导航项内边距
  static const double navItemGap = 4.0; // 导航项间距
  static const double navSectionGap = 16.0; // 导航区块间距

  // 响应式间距
  static const double mobilePadding = 16.0; // 移动端内边距
  static const double tabletPadding = 20.0; // 平板端内边距
  static const double desktopPadding = 24.0; // 桌面端内边距
  static const double largeDesktopPadding = 32.0; // 大桌面端内边距

  // 内容间距
  static const double contentSpacing = 16.0; // 内容间距
  static const double contentSpacingSmall = 12.0; // 小内容间距
  static const double contentSpacingLarge = 24.0; // 大内容间距

  // 边框间距
  static const double borderSpacing = 8.0; // 边框间距
  static const double borderWidth = 1.0; // 边框宽度
  static const double borderWidthThick = 2.0; // 粗边框宽度
}

/// 金融组件专用间距
///
/// 金融数据展示组件的间距定义
class FinancialSpacing {
  FinancialSpacing._();

  // 数据卡片间距
  static const double dataCardPadding = 16.0; // 数据卡片内边距
  static const double dataCardGap = 12.0; // 数据卡片间距
  static const double dataCardPaddingSmall = 12.0; // 小数据卡片内边距
  static const double dataCardPaddingLarge = 20.0; // 大数据卡片内边距

  // 价格显示间距
  static const double priceGap = 8.0; // 价格元素间距
  static const double priceLabelGap = 4.0; // 价格标签间距

  // 图表间距
  static const double chartPadding = 16.0; // 图表内边距
  static const double chartMargin = 16.0; // 图表外边距
  static const double chartLegendGap = 12.0; // 图表图例间距

  // 表格间距
  static const double tableCellPadding = 12.0; // 表格单元格内边距
  static const double tableHeaderPadding = 16.0; // 表格头内边距
  static const double tableRowGap = 1.0; // 表格行间距

  // 统计数据间距
  static const double statsGap = 16.0; // 统计数据间距
  static const double statsItemGap = 8.0; // 统计项间距
}

/// 圆角系统 (Border Radius Tokens)
class BorderRadiusTokens {
  BorderRadiusTokens._();

  // 圆角尺寸
  static const double none = 0.0; // 无圆角
  static const double xs = 2.0; // 极小圆角
  static const double sm = 4.0; // 小圆角
  static const double md = 8.0; // 中圆角
  static const double lg = 12.0; // 大圆角
  static const double xl = 16.0; // 超大圆角
  static const double xxl = 24.0; // 极大圆角
  static const double full = 999.0; // 完全圆角

  // 特殊圆角
  static const double button = 4.0; // 按钮圆角
  static const double card = 8.0; // 卡片圆角
  static const double input = 4.0; // 输入框圆角
  static const double dialog = 12.0; // 对话框圆角
  static const double chip = 16.0; // 标签圆角
  static const double avatar = 999.0; // 头像圆角
}

/// 尺寸系统 (Size Tokens)
class StandardSizes {
  StandardSizes._();

  // 按钮尺寸
  static const double buttonSmall = 32.0;
  static const double buttonMedium = 40.0;
  static const double buttonLarge = 48.0;

  // 输入框尺寸
  static const double inputSmall = 32.0;
  static const double inputMedium = 40.0;
  static const double inputLarge = 48.0;

  // 图标尺寸
  static const double iconXs = 16.0;
  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;

  // 头像尺寸
  static const double avatarSmall = 32.0;
  static const double avatarMedium = 40.0;
  static const double avatarLarge = 56.0;
  static const double avatarXLarge = 80.0;
}

/// 断点系统 (Breakpoint Tokens)
class BreakpointTokens {
  BreakpointTokens._();

  // 桌面端优先断点
  static const double desktopXL = 1600.0; // 超大桌面
  static const double desktopLG = 1200.0; // 大桌面
  static const double desktopMD = 1024.0; // 桌面
  static const double desktopSM = 768.0; // 小桌面
  static const double tablet = 600.0; // 平板
  static const double mobile = 480.0; // 手机

  // 容器最大宽度
  static const double containerXL = 1400.0;
  static const double containerLG = 1200.0;
  static const double containerMD = 960.0;
  static const double containerSM = 720.0;
  static const double containerXS = 540.0;
}

/// 间距工具类
///
/// 提供间距计算和转换的实用方法
class SpacingUtils {
  SpacingUtils._();

  /// 获取响应式间距
  static double getResponsiveSpacing(
    double baseSpacing, {
    required BuildContext context,
    double mobileFactor = 0.75,
    double tabletFactor = 0.875,
    double desktopFactor = 1.0,
    double largeDesktopFactor = 1.125,
  }) {
    final width = MediaQuery.of(context).size.width;

    if (width < BreakpointTokens.tablet) {
      return baseSpacing * mobileFactor;
    } else if (width < BreakpointTokens.desktopMD) {
      return baseSpacing * tabletFactor;
    } else if (width < BreakpointTokens.desktopLG) {
      return baseSpacing * desktopFactor;
    } else {
      return baseSpacing * largeDesktopFactor;
    }
  }

  /// 创建对称间距
  static EdgeInsets symmetric({
    double horizontal = 0,
    double vertical = 0,
  }) {
    return EdgeInsets.symmetric(
      horizontal: horizontal,
      vertical: vertical,
    );
  }

  /// 创建所有方向相同间距
  static EdgeInsets all(double spacing) {
    return EdgeInsets.all(spacing);
  }

  /// 创建自定义间距
  static EdgeInsets only({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) {
    return EdgeInsets.only(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
    );
  }

  /// 创建水平间距
  static EdgeInsets horizontal(double spacing) {
    return EdgeInsets.symmetric(horizontal: spacing);
  }

  /// 创建垂直间距
  static EdgeInsets vertical(double spacing) {
    return EdgeInsets.symmetric(vertical: spacing);
  }

  /// 创建左边距
  static EdgeInsets left(double spacing) {
    return EdgeInsets.only(left: spacing);
  }

  /// 创建右边距
  static EdgeInsets right(double spacing) {
    return EdgeInsets.only(right: spacing);
  }

  /// 创建上边距
  static EdgeInsets top(double spacing) {
    return EdgeInsets.only(top: spacing);
  }

  /// 创建下边距
  static EdgeInsets bottom(double spacing) {
    return EdgeInsets.only(bottom: spacing);
  }

  /// 获取安全区域 + 间距
  static EdgeInsets safeAreaPlus(
    BuildContext context, {
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) {
    final padding = MediaQuery.of(context).padding;
    return EdgeInsets.only(
      left: padding.left + left,
      top: padding.top + top,
      right: padding.right + right,
      bottom: padding.bottom + bottom,
    );
  }
}
