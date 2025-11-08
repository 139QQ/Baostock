import 'package:flutter/material.dart';

/// 应用设计规范常量
/// 基于UX设计规范文档的Fluent Design设计令牌系统
///
/// 注意：此文件保留作为向后兼容，新开发请使用 design_tokens/ 目录下的设计令牌
@Deprecated('使用 design_tokens/ 目录下的新设计令牌系统')
class AppDesignConstants {
  AppDesignConstants._(); // 私有构造函数，防止实例化

  // ========== 颜色系统 ==========
  // Fluent Design 主色调
  static const Color primaryBlue = Color(0xFF0078D4);
  static const Color primaryBlueLight = Color(0xFF4096E6);
  static const Color primaryBlueDark = Color(0xFF005A9E);

  // 中性色
  static const Color neutralLight = Color(0xFFF3F2F1);
  static const Color neutralDark = Color(0xFF323130);
  static const Color neutralWhite = Color(0xFFFFFFFF);

  // 语义色
  static const Color success = Color(0xFF107C10);
  static const Color warning = Color(0xFFFF8C00);
  static const Color error = Color(0xFFD13438);
  static const Color info = Color(0xFF0078D4);

  // 金融专用色
  static const Color positiveReturn = Color(0xFF28A745); // 正收益
  static const Color negativeReturn = Color(0xFFDC3545); // 负收益
  static const Color flatReturn = Color(0xFF6C757D); // 平盘

  // ========== 尺寸系统 ==========
  // 圆角半径
  static const double radiusXS = 2.0;
  static const double radiusSM = 4.0;
  static const double radiusMD = 8.0;
  static const double radiusLG = 12.0;
  static const double radiusXL = 16.0;
  static const double radiusXXL = 24.0;
  static const double radiusFull = 999.0;

  // 间距系统 (基于8px网格)
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 16.0;
  static const double spacingLG = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;
  static const double spacingXXXL = 64.0;

  // ========== 字体系统 ==========
  // 字体大小
  static const double fontSizeH1 = 32.0;
  static const double fontSizeH2 = 28.0;
  static const double fontSizeH3 = 24.0;
  static const double fontSizeH4 = 20.0;
  static const double fontSizeH5 = 18.0;
  static const double fontSizeH6 = 16.0;
  static const double fontSizeBodyLarge = 16.0;
  static const double fontSizeBody = 14.0;
  static const double fontSizeBodySmall = 12.0;
  static const double fontSizeCaption = 11.0;
  static const double fontSizeLabel = 12.0;
  static const double fontSizeButton = 14.0;
  static const double fontSizeInput = 14.0;
  static const double fontSizeData = 13.0;
  static const double fontSizeFootnote = 10.0;

  // 字体权重
  static const FontWeight fontWeightThin = FontWeight.w100;
  static const FontWeight fontWeightExtraLight = FontWeight.w200;
  static const FontWeight fontWeightLight = FontWeight.w300;
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;
  static const FontWeight fontWeightExtraBold = FontWeight.w800;
  static const FontWeight fontWeightBlack = FontWeight.w900;

  // 行高
  static const double lineHeightTight = 1.2;
  static const double lineHeightNormal = 1.4;
  static const double lineHeightRelaxed = 1.6;
  static const double lineHeightLoose = 1.8;

  // ========== 边框与阴影 ==========
  // 边框
  static const double borderWidthThin = 0.5;
  static const double borderWidthNormal = 1.0;
  static const double borderWidthThick = 2.0;
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color borderColorLight = Color(0xFFF3F4F6);

  // 阴影层级
  static const List<BoxShadow> shadowSM = [
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  static const List<BoxShadow> shadowMD = [
    BoxShadow(
      color: Color(0x0F000000),
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -1,
    ),
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: -1,
    ),
  ];

  static const List<BoxShadow> shadowLG = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 10),
      blurRadius: 15,
      spreadRadius: -3,
    ),
    BoxShadow(
      color: Color(0x1F000000),
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -4,
    ),
  ];

  // ========== 动画系统 ==========
  // 动画时长
  static const Duration durationInstant = Duration(milliseconds: 0);
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);
  static const Duration durationSlower = Duration(milliseconds: 800);

  // 动画曲线
  static const Curve curveLinear = Curves.linear;
  static const Curve curveEase = Curves.ease;
  static const Curve curveEaseIn = Curves.easeIn;
  static const Curve curveEaseOut = Curves.easeOut;
  static const Curve curveEaseInOut = Curves.easeInOut;
  static const Curve curveSmooth = Cubic(0.4, 0.0, 0.2, 1.0);
  static const Curve curveSharp = Cubic(0.4, 0.0, 0.6, 1.0);

  // ========== 响应式断点 ==========
  // 桌面端优先断点
  static const double breakpointDesktopXL = 1600.0;
  static const double breakpointDesktopLG = 1200.0;
  static const double breakpointDesktopMD = 1024.0;
  static const double breakpointDesktopSM = 768.0;
  static const double breakpointTablet = 600.0;
  static const double breakpointMobile = 480.0;

  // 容器最大宽度
  static const double containerXL = 1400.0;
  static const double containerLG = 1200.0;
  static const double containerMD = 960.0;
  static const double containerSM = 720.0;
  static const double containerXS = 540.0;

  // ========== 组件尺寸 ==========
  // 最小尺寸
  static const double touchTargetMin = 44.0;
  static const double buttonHeightMin = 32.0;
  static const double inputHeightMin = 32.0;
  static const double iconSizeMin = 16.0;

  // 标准尺寸
  static const double buttonHeightSmall = 32.0;
  static const double buttonHeightMedium = 40.0;
  static const double buttonHeightLarge = 48.0;
  static const double inputHeightSmall = 32.0;
  static const double inputHeightMedium = 40.0;
  static const double inputHeightLarge = 48.0;

  // 图标尺寸
  static const double iconXS = 16.0;
  static const double iconSM = 20.0;
  static const double iconMD = 24.0;
  static const double iconLG = 32.0;
  static const double iconXL = 48.0;

  // 头像尺寸
  static const double avatarSmall = 32.0;
  static const double avatarMedium = 40.0;
  static const double avatarLarge = 56.0;
  static const double avatarXLarge = 80.0;

  // ========== 透明度系统 ==========
  static const double transparent = 0.0;
  static const double barely = 0.1;
  static const double light = 0.3;
  static const double medium = 0.5;
  static const double heavy = 0.7;
  static const double almost = 0.9;
  static const double opaque = 1.0;

  // 特殊透明度
  static const double disabled = 0.5;
  static const double hover = 0.8;
  static const double focus = 0.12;
  static const double selected = 0.08;

  // ========== Z-Index 层级系统 ==========
  static const int zIndexBackground = -1;
  static const int zIndexBase = 0;
  static const int zIndexRaised = 1;
  static const int zIndexDropdown = 1000;
  static const int zIndexSticky = 1020;
  static const int zIndexFixed = 1030;
  static const int zIndexModalBackdrop = 1040;
  static const int zIndexModal = 1050;
  static const int zIndexPopover = 1060;
  static const int zIndexTooltip = 1070;
  static const int zIndexToast = 1080;
}
