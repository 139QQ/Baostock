import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 字体族 (Font Families)
///
/// 定义中英文和数字的字体族，确保跨平台一致性
class FontFamilies {
  FontFamilies._();

  // 中文字体族
  static const String chinesePrimary = 'PingFang SC';
  static const String chineseSecondary = 'Microsoft YaHei';
  static const String chineseMonospace = 'Consolas';

  // 英文字体族
  static const String englishPrimary = 'Segoe UI';
  static const String englishSecondary = 'Arial';
  static const String englishMonospace = 'Consolas';

  // 数字字体族
  static const String numbers = 'SF Mono';

  // 默认字体族
  static String get defaultFamily =>
      Platform.isWindows ? chineseSecondary : chinesePrimary;
}

/// 字体大小 (Font Sizes)
///
/// 基于设计规范的完整字体尺寸系统
class FontSizes {
  FontSizes._();

  // 标题层级
  static const double h1 = 32.0; // 页面主标题
  static const double h2 = 28.0; // 区块标题
  static const double h3 = 24.0; // 子区块标题
  static const double h4 = 20.0; // 卡片标题
  static const double h5 = 18.0; // 小标题
  static const double h6 = 16.0; // 正文标题

  // 正文层级
  static const double bodyLarge = 16.0; // 大正文
  static const double body = 14.0; // 标准正文
  static const double bodySmall = 12.0; // 小正文
  static const double caption = 11.0; // 说明文字
  static const double label = 12.0; // 标签文字

  // 特殊用途
  static const double button = 14.0; // 按钮文字
  static const double input = 14.0; // 输入框文字
  static const double data = 13.0; // 数据表格
  static const double footnote = 10.0; // 脚注

  // 金融数据专用
  static const double priceLarge = 24.0; // 大价格显示
  static const double priceMedium = 20.0; // 中价格显示
  static const double priceSmall = 16.0; // 小价格显示
  static const double percentage = 14.0; // 百分比显示
}

/// 字体权重 (Font Weights)
///
/// 定义完整的字重等级
class FontWeights {
  FontWeights._();

  static const FontWeight thin = FontWeight.w100; // 极细
  static const FontWeight extraLight = FontWeight.w200; // 超细
  static const FontWeight light = FontWeight.w300; // 细
  static const FontWeight regular = FontWeight.w400; // 常规
  static const FontWeight medium = FontWeight.w500; // 中等
  static const FontWeight semiBold = FontWeight.w600; // 半粗
  static const FontWeight bold = FontWeight.w700; // 粗体
  static const FontWeight extraBold = FontWeight.w800; // 超粗
  static const FontWeight black = FontWeight.w900; // 极粗
}

/// 行高 (Line Heights)
///
/// 定义不同用途的行高比例
class LineHeights {
  LineHeights._();

  static const double tight = 1.2; // 紧凑
  static const double normal = 1.4; // 正常
  static const double relaxed = 1.6; // 宽松
  static const double loose = 1.8; // 很宽松

  // 特殊用途
  static const double heading = 1.2; // 标题
  static const double body = 1.5; // 正文
  static const double data = 1.4; // 数据
}

/// 预定义文本样式 (Predefined Text Styles)
///
/// 基于设计令牌的常用文本样式组合
class AppTextStyles {
  AppTextStyles._();

  // 标题样式
  static TextStyle get h1 => TextStyle(
        fontSize: FontSizes.h1,
        fontWeight: FontWeights.bold,
        height: LineHeights.heading,
        fontFamily: FontFamilies.defaultFamily,
        color: NeutralColors.neutral900,
      );

  static TextStyle get h2 => TextStyle(
        fontSize: FontSizes.h2,
        fontWeight: FontWeights.semiBold,
        height: LineHeights.heading,
        fontFamily: FontFamilies.defaultFamily,
        color: NeutralColors.neutral900,
      );

  static TextStyle get h3 => TextStyle(
        fontSize: FontSizes.h3,
        fontWeight: FontWeights.semiBold,
        height: LineHeights.heading,
        fontFamily: FontFamilies.defaultFamily,
        color: NeutralColors.neutral800,
      );

  static TextStyle get h4 => TextStyle(
        fontSize: FontSizes.h4,
        fontWeight: FontWeights.medium,
        height: LineHeights.heading,
        fontFamily: FontFamilies.defaultFamily,
        color: NeutralColors.neutral800,
      );

  static TextStyle get h5 => TextStyle(
        fontSize: FontSizes.h5,
        fontWeight: FontWeights.medium,
        height: LineHeights.normal,
        fontFamily: FontFamilies.defaultFamily,
        color: NeutralColors.neutral700,
      );

  static TextStyle get h6 => TextStyle(
        fontSize: FontSizes.h6,
        fontWeight: FontWeights.medium,
        height: LineHeights.normal,
        fontFamily: FontFamilies.defaultFamily,
        color: NeutralColors.neutral700,
      );

  // 正文样式
  static TextStyle get bodyLarge => TextStyle(
        fontSize: FontSizes.bodyLarge,
        fontWeight: FontWeights.regular,
        height: LineHeights.body,
        fontFamily: FontFamilies.defaultFamily,
        color: NeutralColors.neutral800,
      );

  static TextStyle get body => TextStyle(
        fontSize: FontSizes.body,
        fontWeight: FontWeights.regular,
        height: LineHeights.body,
        fontFamily: FontFamilies.defaultFamily,
        color: NeutralColors.neutral700,
      );

  static TextStyle get bodySmall => TextStyle(
        fontSize: FontSizes.bodySmall,
        fontWeight: FontWeights.regular,
        height: LineHeights.body,
        fontFamily: FontFamilies.defaultFamily,
        color: NeutralColors.neutral600,
      );

  static TextStyle get caption => TextStyle(
        fontSize: FontSizes.caption,
        fontWeight: FontWeights.regular,
        height: LineHeights.normal,
        fontFamily: FontFamilies.defaultFamily,
        color: NeutralColors.neutral500,
      );

  static TextStyle get label => TextStyle(
        fontSize: FontSizes.label,
        fontWeight: FontWeights.medium,
        height: LineHeights.normal,
        fontFamily: FontFamilies.defaultFamily,
        color: NeutralColors.neutral700,
      );

  // 特殊用途样式
  static TextStyle get button => TextStyle(
        fontSize: FontSizes.button,
        fontWeight: FontWeights.medium,
        height: LineHeights.tight,
        fontFamily: FontFamilies.defaultFamily,
      );

  static TextStyle get input => TextStyle(
        fontSize: FontSizes.input,
        fontWeight: FontWeights.regular,
        height: LineHeights.normal,
        fontFamily: FontFamilies.defaultFamily,
        color: NeutralColors.neutral800,
      );

  static TextStyle get data => TextStyle(
        fontSize: FontSizes.data,
        fontWeight: FontWeights.regular,
        height: LineHeights.data,
        fontFamily: FontFamilies.numbers,
        color: NeutralColors.neutral800,
      );

  // 金融数据专用样式
  static TextStyle get priceLarge => TextStyle(
        fontSize: FontSizes.priceLarge,
        fontWeight: FontWeights.bold,
        height: LineHeights.tight,
        fontFamily: FontFamilies.numbers,
      );

  static TextStyle get priceMedium => TextStyle(
        fontSize: FontSizes.priceMedium,
        fontWeight: FontWeights.semiBold,
        height: LineHeights.tight,
        fontFamily: FontFamilies.numbers,
      );

  static TextStyle get priceSmall => TextStyle(
        fontSize: FontSizes.priceSmall,
        fontWeight: FontWeights.medium,
        height: LineHeights.tight,
        fontFamily: FontFamilies.numbers,
      );

  static TextStyle get percentage => TextStyle(
        fontSize: FontSizes.percentage,
        fontWeight: FontWeights.medium,
        height: LineHeights.tight,
        fontFamily: FontFamilies.numbers,
      );

  // 状态样式
  static TextStyle get success => TextStyle(
        fontSize: FontSizes.body,
        fontWeight: FontWeights.medium,
        color: SemanticColors.success500,
        fontFamily: FontFamilies.defaultFamily,
      );

  static TextStyle get warning => TextStyle(
        fontSize: FontSizes.body,
        fontWeight: FontWeights.medium,
        color: SemanticColors.warning500,
        fontFamily: FontFamilies.defaultFamily,
      );

  static TextStyle get error => TextStyle(
        fontSize: FontSizes.body,
        fontWeight: FontWeights.medium,
        color: SemanticColors.error500,
        fontFamily: FontFamilies.defaultFamily,
      );

  static TextStyle get info => TextStyle(
        fontSize: FontSizes.body,
        fontWeight: FontWeights.medium,
        color: SemanticColors.info500,
        fontFamily: FontFamilies.defaultFamily,
      );

  // 链接样式
  static TextStyle get link => TextStyle(
        fontSize: FontSizes.body,
        fontWeight: FontWeights.medium,
        color: BaseColors.primary500,
        fontFamily: FontFamilies.defaultFamily,
        decoration: TextDecoration.underline,
      );
}

/// 响应式字体大小
///
/// 根据屏幕尺寸调整字体大小
class ResponsiveFontSizes {
  ResponsiveFontSizes._();

  // 移动端字体大小
  static const double mobileH1 = 24.0;
  static const double mobileH2 = 20.0;
  static const double mobileH3 = 18.0;
  static const double mobileBody = 16.0;
  static const double mobileCaption = 12.0;

  // 平板端字体大小
  static const double tabletH1 = 28.0;
  static const double tabletH2 = 24.0;
  static const double tabletH3 = 20.0;
  static const double tabletBody = 14.0;
  static const double tabletCaption = 11.0;

  // 桌面端字体大小
  static const double desktopH1 = 32.0;
  static const double desktopH2 = 28.0;
  static const double desktopH3 = 24.0;
  static const double desktopBody = 14.0;
  static const double desktopCaption = 11.0;
}
