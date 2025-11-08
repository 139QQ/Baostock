import 'package:flutter/material.dart';

/// 基础色彩 (Base Colors)
///
/// 基于UX设计规范文档的Fluent Design色彩系统
/// 提供完整的主色调、中性色和语义色定义
class BaseColors {
  BaseColors._();

  // 主蓝色 - Fluent Design 标准
  static const Color primary50 = Color(0xFFF3F9FF); // 极浅蓝
  static const Color primary100 = Color(0xFFE1F0FF); // 浅蓝
  static const Color primary200 = Color(0xFFBAE0FF); // 中浅蓝
  static const Color primary300 = Color(0xFF7FC4FF); // 较浅蓝
  static const Color primary400 = Color(0xFF38A7FF); // 浅主蓝
  static const Color primary500 = Color(0xFF0078D4); // 主蓝
  static const Color primary600 = Color(0xFF005A9E); // 深蓝
  static const Color primary700 = Color(0xFF004578); // 较深蓝
  static const Color primary800 = Color(0xFF003455); // 深蓝
  static const Color primary900 = Color(0xFF002233); // 极深蓝
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
