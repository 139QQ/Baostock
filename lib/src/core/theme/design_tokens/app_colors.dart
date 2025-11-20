import 'package:flutter/material.dart';

/// 现代FinTech基础色彩 (Modern FinTech Base Colors)
///
/// 基于现代金融科技设计规范，提供渐变色彩支持
/// 采用深蓝+金色配色方案，体现专业金融科技感
class BaseColors {
  BaseColors._();

  // 现代金融科技主色调 - 深蓝渐变系列
  static const Color primary50 = Color(0xFFF0F4FF);
  static const Color primary100 = Color(0xFFE0EAFF);
  static const Color primary200 = Color(0xFFC7D8FF);
  static const Color primary300 = Color(0xFFA4BEFF);
  static const Color primary400 = Color(0xFF819DFF);
  static const Color primary500 = Color(0xFF5E7CFF); // 现代主色
  static const Color primary600 = Color(0xFF4A6CFF);
  static const Color primary700 = Color(0xFF3B5BD8);
  static const Color primary800 = Color(0xFF2E4AB8);
  static const Color primary900 = Color(0xFF233997);

  // 金融金色系列 - 用于重要信息和增长指标
  static const Color gold50 = Color(0xFFFFFAF0);
  static const Color gold100 = Color(0xFFFFF3D6);
  static const Color gold200 = Color(0xFFFFE4A1);
  static const Color gold300 = Color(0xFFFFD966);
  static const Color gold400 = Color(0xFFFFCC33);
  static const Color gold500 = Color(0xFFFFBF00); // 金融金色
  static const Color gold600 = Color(0xFFE6AC00);
  static const Color gold700 = Color(0xFFCC9900);
  static const Color gold800 = Color(0xFFB38600);
  static const Color gold900 = Color(0xFF997300);

  // 科技紫色系列 - 用于创新功能
  static const Color tech50 = Color(0xFFF8F5FF);
  static const Color tech100 = Color(0xFFEDE5FF);
  static const Color tech200 = Color(0xFFD8C4FF);
  static const Color tech300 = Color(0xFFC099FF);
  static const Color tech400 = Color(0xFFA866FF);
  static const Color tech500 = Color(0xFF9333FF); // 科技紫
  static const Color tech600 = Color(0xFF7E22CE);
  static const Color tech700 = Color(0xFF6B21A8);
  static const Color tech800 = Color(0xFF581C87);
  static const Color tech900 = Color(0xFF441E68);
}

/// 中性色 (Neutral Colors)
///
/// 提供完整的灰度色阶，用于文本、边框和背景
class NeutralColors {
  NeutralColors._();

  static const Color white = Color(0xFFFFFFFF);
  static const Color neutral50 = Color(0xFFF8F9FA); // 极浅灰
  static const Color neutral100 = Color(0xFFF1F3F4); // 浅灰
  static const Color neutral200 = Color(0xFFE8EAED); // 中浅灰
  static const Color neutral300 = Color(0xFFDADCE0); // 较浅灰
  static const Color neutral400 = Color(0xFFBDC1C6); // 浅中性灰
  static const Color neutral500 = Color(0xFF9AA0A6); // 中性灰
  static const Color neutral600 = Color(0xFF80868B); // 中深灰
  static const Color neutral700 = Color(0xFF5F6368); // 深灰
  static const Color neutral800 = Color(0xFF3C4043); // 较深灰
  static const Color neutral900 = Color(0xFF202124); // 深灰
  static const Color neutral950 = Color(0xFF1A1A1A); // 极深灰
  static const Color black = Color(0xFF000000);
}

/// 语义色 (Semantic Colors)
///
/// 用于状态指示、反馈和交互的预定义颜色
class SemanticColors {
  SemanticColors._();

  // 成功色系
  static const Color success50 = Color(0xFFF6FEDF); // 极浅绿
  static const Color success100 = Color(0xFFE7F5C6); // 浅绿
  static const Color success500 = Color(0xFF107C10); // 主绿
  static const Color success600 = Color(0xFF0E5C0E); // 深绿

  // 警告色系
  static const Color warning50 = Color(0xFFFFFAEB); // 极浅黄
  static const Color warning100 = Color(0xFFFFF0CC); // 浅黄
  static const Color warning500 = Color(0xFFFF8C00); // 主橙黄
  static const Color warning600 = Color(0xFFE67E00); // 深橙黄

  // 错误色系
  static const Color error50 = Color(0xFFFFF1F0); // 极浅红
  static const Color error100 = Color(0xFFFFE5E5); // 浅红
  static const Color error500 = Color(0xFFD13438); // 主红
  static const Color error600 = Color(0xFFA4262C); // 深红

  // 信息色系
  static const Color info50 = Color(0xFFF6FBFF); // 极浅信息蓝
  static const Color info100 = Color(0xFFE1F5FF); // 浅信息蓝
  static const Color info500 = Color(0xFF0078D4); // 主信息蓝
  static const Color info600 = Color(0xFF005A9E); // 深信息蓝
}

/// 金融专用颜色 (Financial Colors)
///
/// 专门用于金融数据展示的颜色系统
class FinancialColors {
  FinancialColors._();

  // 正收益 - 绿色系
  static const Color positiveLight = Color(0xFFD4EDDA);
  static const Color positive = Color(0xFF28A745);
  static const Color positiveDark = Color(0xFF155724);

  // 负收益 - 红色系
  static const Color negativeLight = Color(0xFFF8D7DA);
  static const Color negative = Color(0xFFDC3545);
  static const Color negativeDark = Color(0xFF721C24);

  // 平盘 - 灰色系
  static const Color neutral = Color(0xFF6C757D);
  static const Color neutralDark = Color(0xFF495057);
}

/// 渐变色彩系统 (Gradient Colors)
///
/// 现代FinTech渐变配色方案
class FinancialGradients {
  FinancialGradients._();

  // 主要渐变 - 深蓝到浅蓝
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF233997), Color(0xFF5E7CFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 成功/增长渐变 - 金色系
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFFFFD966), Color(0xFFFFBF00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 科技创新渐变 - 紫色系
  static const LinearGradient techGradient = LinearGradient(
    colors: [Color(0xFF6B21A8), Color(0xFF9333FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 市场数据渐变 - 蓝金组合
  static const LinearGradient marketGradient = LinearGradient(
    colors: [Color(0xFF4A6CFF), Color(0xFFFFBF00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 背景渐变 - 深色主题
  static const LinearGradient darkBackgroundGradient = LinearGradient(
    colors: [Color(0xFF1A1F36), Color(0xFF0F172A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // 卡片渐变 - 玻璃拟态效果
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 按钮渐变 - 主要操作
  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF5E7CFF), Color(0xFF4A6CFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 数据图表渐变 - 上升趋势
  static const LinearGradient upTrendGradient = LinearGradient(
    colors: [Color(0xFF28A745), Color(0xFF20C997)],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );

  // 数据图表渐变 - 下降趋势
  static const LinearGradient downTrendGradient = LinearGradient(
    colors: [Color(0xFFDC3545), Color(0xFFFF6B6B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 中性渐变 - 平盘状态
  static const LinearGradient neutralGradient = LinearGradient(
    colors: [Color(0xFF6C757D), Color(0xFF495057)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// 风险等级颜色 (Risk Level Colors)
///
/// 用于风险等级展示的渐变色系
class RiskColors {
  RiskColors._();

  // 低风险 - 绿色渐变
  static const Color lowRiskStart = Color(0xFF28A745);
  static const Color lowRiskEnd = Color(0xFF20C997);

  // 中风险 - 黄色渐变
  static const Color mediumRiskStart = Color(0xFFFFC107);
  static const Color mediumRiskEnd = Color(0xFFFF8C00);

  // 高风险 - 红色渐变
  static const Color highRiskStart = Color(0xFFDC3545);
  static const Color highRiskEnd = Color(0xFFFF6B6B);
}

/// 品牌色彩系统 (Brand Colors)
///
/// 基速基金专用品牌色彩
class BrandColors {
  BrandColors._();

  // 品牌主色 - 深海蓝
  static const Color brandPrimary = Color(0xFF1A365D);
  static const Color brandPrimaryLight = Color(0xFF2E4AB8);
  static const Color brandPrimaryDark = Color(0xFF0F1E3D);

  // 品牌辅色 - 金融金
  static const Color brandAccent = Color(0xFFD69E2E);
  static const Color brandAccentLight = Color(0xFFFFBF00);
  static const Color brandAccentDark = Color(0xFFB38600);

  // 品牌中性色
  static const Color brandNeutral = Color(0xFF1A202C);
  static const Color brandNeutralLight = Color(0xFF2D3748);
  static const Color brandNeutralDark = Color(0xFF0F1419);
}
