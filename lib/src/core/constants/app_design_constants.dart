import 'package:flutter/material.dart';

/// 应用设计规范常量
/// 统一视觉风格、字体层级、配色系统、交互体验等设计规范
class AppDesignConstants {
  // 尺寸规范
  static double adiusSmall = 4.0;
  static double adiusMedium = 8.0;
  static double adiusLarge = 12.0;
  static double adiusXLarge = 16.0;

  // 间距规范
  static double pacingXS = 4.0;
  static double pacingSM = 8.0;
  static double pacingMD = 12.0;
  static double pacingLG = 16.0;
  static double pacingXL = 20.0;
  static double pacingXXL = 24.0;
  static double pacingXXXL = 32.0;

  // 边框规范
  static double orderWidth = 1.0;
  static Color orderColor = const Color(0xFFE5E7EB); // 浅灰色边框

  // 阴影规范
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get cardShadowHover => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  // 字体规范
  static double ontSizeTitle = 16.0; // 标题
  static double ontSizeData = 20.0; // 核心数据
  static double ontSizeDataLarge = 24.0; // 重要数据
  static double ontSizeHelper = 12.0; // 辅助信息
  static double ontSizeSmall = 11.0; // 小字
  static double ontSizeMedium = 13.0; // 中等字号
  static double ontSizeLarge = 18.0; // 大字号

  // 字重规范
  static FontWeight ontWeightRegular = FontWeight.w400;
  static FontWeight ontWeightMedium = FontWeight.w500;
  static FontWeight ontWeightSemibold = FontWeight.w600;
  static FontWeight ontWeightBold = FontWeight.w700;

  // 颜色系统
  static Color olorTextPrimary = const Color(0xFF1F2937); // 主要文字
  static Color olorTextSecondary = const Color(0xFF6B7280); // 次要文字
  static Color olorTextTertiary = const Color(0xFF9CA3AF); // 辅助文字

  // 上涨下跌颜色（统一红绿配色）
  static Color olorUp = const Color(0xFFEF4444); // 红色 - 统一上涨色
  static Color olorDown = const Color(0xFF10B981); // 绿色 - 统一下跌色
  static Color olorFlat = const Color(0xFF6B7280); // 灰色 - 平盘

  // 背景颜色
  static Color olorBackground = const Color(0xFFF8FAFC); // 背景色
  static Color olorCardBackground = Colors.white; // 卡片背景
  static Color olorHoverBackground = const Color(0xFFF8FAFC); // 悬浮背景

  // 主题颜色
  static Color olorPrimary = const Color(0xFF2563EB); // 主色调
  static Color olorPrimaryLight = const Color(0xFF3B82F6); // 主色调-浅
  static Color olorPrimaryDark = const Color(0xFF1D4ED8); // 主色调-深

  // 交互动效规范
  static Duration nimationDuration = const Duration(milliseconds: 200);
  static Curve nimationCurve = Curves.easeInOut;

  // 响应式断点
  static double reakpointMobile = 600.0;
  static double reakpointTablet = 900.0;
  static double reakpointDesktop = 1200.0;

  // 卡片尺寸规范
  static double ardPadding = 16.0;
  static double ardPaddingLarge = 20.0;
  static double ardPaddingSmall = 12.0;

  // 组件高度规范
  static double uttonHeight = 40.0;
  static double uttonHeightSmall = 32.0;
  static double nputHeight = 48.0;
}
