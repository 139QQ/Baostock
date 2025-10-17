/// 图表主题管理器
///
/// 提供统一的图表主题配置，支持明暗模式切换和自定义样式
/// 确保所有图表组件使用一致的视觉设计
library chart_theme_manager;

import 'package:flutter/material.dart';

/// 图表主题配置
///
/// 定义图表的颜色、字体、尺寸等视觉属性
class ChartTheme {
  const ChartTheme({
    required this.primaryColor,
    required this.backgroundColor,
    required this.textColor,
    required this.gridColor,
    required this.legendStyle,
    required this.titleStyle,
    required this.tooltipStyle,
    this.secondaryColors = const [],
    this.gradientColors = const [],
  });

  final Color primaryColor;
  final Color backgroundColor;
  final Color textColor;
  final Color gridColor;
  final TextStyle legendStyle;
  final TextStyle titleStyle;
  final TextStyle tooltipStyle;
  final List<Color> secondaryColors;
  final List<Color> gradientColors;

  /// 创建浅色主题
  factory ChartTheme.light() {
    return ChartTheme(
      primaryColor: const Color(0xFF1976D2),
      backgroundColor: Colors.white,
      textColor: const Color(0xFF212121),
      gridColor: const Color(0xFFE0E0E0),
      legendStyle: const TextStyle(
        fontSize: 12,
        color: Color(0xFF424242),
        fontWeight: FontWeight.w500,
      ),
      titleStyle: const TextStyle(
        fontSize: 16,
        color: Color(0xFF212121),
        fontWeight: FontWeight.w600,
      ),
      tooltipStyle: const TextStyle(
        fontSize: 11,
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
      secondaryColors: [
        const Color(0xFF2196F3),
        const Color(0xFF4CAF50),
        const Color(0xFFFF9800),
        const Color(0xFF9C27B0),
        const Color(0xFFF44336),
        const Color(0xFF00BCD4),
        const Color(0xFFFFEB3B),
        const Color(0xFF795548),
      ],
      gradientColors: [
        const Color(0xFF1976D2),
        const Color(0xFF42A5F5),
      ],
    );
  }

  /// 创建深色主题
  factory ChartTheme.dark() {
    return ChartTheme(
      primaryColor: const Color(0xFF64B5F6),
      backgroundColor: const Color(0xFF121212),
      textColor: const Color(0xFFFFFFFF),
      gridColor: const Color(0xFF424242),
      legendStyle: const TextStyle(
        fontSize: 12,
        color: Color(0xFFB0B0B0),
        fontWeight: FontWeight.w500,
      ),
      titleStyle: const TextStyle(
        fontSize: 16,
        color: Color(0xFFFFFFFF),
        fontWeight: FontWeight.w600,
      ),
      tooltipStyle: const TextStyle(
        fontSize: 11,
        color: Color(0xFF212121),
        fontWeight: FontWeight.w500,
      ),
      secondaryColors: [
        const Color(0xFF64B5F6),
        const Color(0xFF81C784),
        const Color(0xFFFFB74D),
        const Color(0xFFBA68C8),
        const Color(0xFFE57373),
        const Color(0xFF4DD0E1),
        const Color(0xFFFFF176),
        const Color(0xFFA1887F),
      ],
      gradientColors: [
        const Color(0xFF64B5F6),
        const Color(0xFF90CAF9),
      ],
    );
  }

  /// 创建主题副本
  ChartTheme copyWith({
    Color? primaryColor,
    Color? backgroundColor,
    Color? textColor,
    Color? gridColor,
    TextStyle? legendStyle,
    TextStyle? titleStyle,
    TextStyle? tooltipStyle,
    List<Color>? secondaryColors,
    List<Color>? gradientColors,
  }) {
    return ChartTheme(
      primaryColor: primaryColor ?? this.primaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      gridColor: gridColor ?? this.gridColor,
      legendStyle: legendStyle ?? this.legendStyle,
      titleStyle: titleStyle ?? this.titleStyle,
      tooltipStyle: tooltipStyle ?? this.tooltipStyle,
      secondaryColors: secondaryColors ?? this.secondaryColors,
      gradientColors: gradientColors ?? this.gradientColors,
    );
  }

  /// 根据索引获取颜色
  Color getColorForIndex(int index) {
    if (index == 0) return primaryColor;
    if (index < secondaryColors.length) {
      return secondaryColors[index - 1];
    }
    // 如果索引超出范围，循环使用颜色
    return secondaryColors[(index - 1) % secondaryColors.length];
  }

  /// 创建渐变色
  Gradient createGradient([List<Color>? colors]) {
    final gradientColorList = colors ?? gradientColors;
    if (gradientColorList.length < 2) {
      return LinearGradient(
        colors: [primaryColor, primaryColor.withOpacity(0.7)],
      );
    }
    return LinearGradient(
      colors: gradientColorList,
    );
  }
}

/// 图表主题管理器
///
/// 负责管理图表主题的创建、切换和应用
class ChartThemeManager {
  static ChartThemeManager? _instance;
  static ChartThemeManager get instance {
    _instance ??= ChartThemeManager._();
    return _instance!;
  }

  ChartThemeManager._();

  ChartTheme _currentTheme = ChartTheme.light();
  final List<VoidCallback> _listeners = [];

  /// 获取当前主题
  ChartTheme get currentTheme => _currentTheme;

  /// 设置主题
  void setTheme(ChartTheme theme) {
    if (_currentTheme != theme) {
      _currentTheme = theme;
      _notifyListeners();
    }
  }

  /// 切换到浅色主题
  void setLightTheme() {
    setTheme(ChartTheme.light());
  }

  /// 切换到深色主题
  void setDarkTheme() {
    setTheme(ChartTheme.dark());
  }

  /// 根据系统主题模式自动切换
  void updateSystemTheme(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    if (brightness == Brightness.dark) {
      setDarkTheme();
    } else {
      setLightTheme();
    }
  }

  /// 添加主题变化监听器
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  /// 移除主题变化监听器
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  /// 通知所有监听器
  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  /// 创建专用于金融数据的主题
  ChartTheme createFinancialTheme({
    Color? positiveColor,
    Color? negativeColor,
    Color? neutralColor,
  }) {
    final baseTheme = _currentTheme;

    return ChartTheme(
      primaryColor: positiveColor ?? const Color(0xFF4CAF50),
      backgroundColor: baseTheme.backgroundColor,
      textColor: baseTheme.textColor,
      gridColor: baseTheme.gridColor,
      legendStyle: baseTheme.legendStyle,
      titleStyle: baseTheme.titleStyle,
      tooltipStyle: baseTheme.tooltipStyle,
      secondaryColors: [
        positiveColor ?? const Color(0xFF4CAF50), // 上涨 - 绿色
        negativeColor ?? const Color(0xFFF44336), // 下跌 - 红色
        neutralColor ?? const Color(0xFF9E9E9E), // 平盘 - 灰色
        const Color(0xFF2196F3), // 蓝色
        const Color(0xFFFF9800), // 橙色
        const Color(0xFF9C27B0), // 紫色
        const Color(0xFF00BCD4), // 青色
        const Color(0xFF795548), // 棕色
      ],
      gradientColors: [
        positiveColor ?? const Color(0xFF4CAF50),
        (positiveColor ?? const Color(0xFF4CAF50)).withOpacity(0.7),
      ],
    );
  }

  /// 获取响应式字体大小
  double getResponsiveFontSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      return baseSize * 0.85; // 移动端
    } else if (screenWidth < 1200) {
      return baseSize; // 平板
    } else {
      return baseSize * 1.1; // 桌面端
    }
  }

  /// 获取响应式内边距
  EdgeInsets getResponsivePadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      return const EdgeInsets.all(8.0); // 移动端
    } else if (screenWidth < 1200) {
      return const EdgeInsets.all(16.0); // 平板
    } else {
      return const EdgeInsets.all(24.0); // 桌面端
    }
  }

  /// 获取响应式图表高度
  double getResponsiveChartHeight(BuildContext context,
      {double minHeight = 200}) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 600) {
      // 移动端：使用屏幕高度的30%-40%
      return (screenHeight * 0.35).clamp(minHeight, 300);
    } else if (screenWidth < 1200) {
      // 平板：使用屏幕高度的40%-50%
      return (screenHeight * 0.45).clamp(minHeight, 400);
    } else {
      // 桌面端：固定高度或使用屏幕高度的35%
      return (screenHeight * 0.35).clamp(minHeight, 500);
    }
  }
}
