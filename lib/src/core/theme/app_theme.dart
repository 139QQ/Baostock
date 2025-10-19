import 'package:flutter/material.dart';

/// 性能等级枚举
enum PerformanceLevel {
  excellent,
  good,
  fair,
  poor,
}

extension PerformanceLevelExtension on PerformanceLevel {
  String get displayName {
    switch (this) {
      case PerformanceLevel.excellent:
        return '优秀';
      case PerformanceLevel.good:
        return '良好';
      case PerformanceLevel.fair:
        return '一般';
      case PerformanceLevel.poor:
        return '较差';
    }
  }

  Color get color {
    switch (this) {
      case PerformanceLevel.excellent:
        return Colors.green;
      case PerformanceLevel.good:
        return Colors.blue;
      case PerformanceLevel.fair:
        return Colors.orange;
      case PerformanceLevel.poor:
        return Colors.red;
    }
  }
}

/// 毛玻璃效果配置
class GlassmorphismConfig {
  final double blur;
  final double opacity;
  final double borderRadius;
  final double borderWidth;
  final Color borderColor;
  final Color backgroundColor;
  final bool enablePerformanceOptimization;

  const GlassmorphismConfig({
    this.blur = 10.0,
    this.opacity = 0.1,
    this.borderRadius = 12.0,
    this.borderWidth = 1.0,
    this.borderColor = Colors.white,
    this.backgroundColor = Colors.white,
    this.enablePerformanceOptimization = true,
  });

  /// 轻量毛玻璃配置
  static const GlassmorphismConfig light = GlassmorphismConfig(
    blur: 5.0,
    opacity: 0.05,
    borderRadius: 8.0,
    borderWidth: 0.5,
  );

  /// 中等毛玻璃配置
  static const GlassmorphismConfig medium = GlassmorphismConfig(
    blur: 10.0,
    opacity: 0.1,
    borderRadius: 12.0,
    borderWidth: 1.0,
  );

  /// 强烈毛玻璃配置
  static const GlassmorphismConfig strong = GlassmorphismConfig(
    blur: 15.0,
    opacity: 0.15,
    borderRadius: 16.0,
    borderWidth: 1.5,
  );

  /// 性能优先配置
  static const GlassmorphismConfig performance = GlassmorphismConfig(
    blur: 8.0,
    opacity: 0.08,
    borderRadius: 12.0,
    borderWidth: 1.0,
    enablePerformanceOptimization: true,
  );

  /// 深色主题配置
  static const GlassmorphismConfig dark = GlassmorphismConfig(
    blur: 8.0,
    opacity: 0.08,
    borderRadius: 12.0,
    borderWidth: 1.0,
    borderColor: Color(0xFF333333),
    backgroundColor: Color(0xFF1A1A1A),
  );
}

class AppTheme {
  static Color primaryColor = const Color(0xFF2563EB);
  static Color successColor = const Color(0xFF16A34A);
  static Color warningColor = const Color(0xFFCA8A04);
  static Color errorColor = const Color(0xFFDC2626);
  static Color neutralColor = const Color(0xFF6B7280);
  static Color backgroundColor = const Color(0xFFF9FAFB);
  static Color cardColor = const Color(0xFFFFFFFF);

  /// 默认毛玻璃配置
  static GlassmorphismConfig defaultGlassmorphismConfig =
      GlassmorphismConfig.medium;

  /// 浅色主题毛玻璃配置
  static GlassmorphismConfig lightGlassmorphismConfig =
      GlassmorphismConfig.light;

  /// 深色主题毛玻璃配置
  static GlassmorphismConfig darkGlassmorphismConfig = GlassmorphismConfig.dark;

  /// 性能优化毛玻璃配置
  static GlassmorphismConfig performanceGlassmorphismConfig =
      GlassmorphismConfig.performance;

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    cardColor: cardColor,
    fontFamily: 'Microsoft YaHei',
  );

  static TextStyle headlineLarge = const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Color(0xFF000000),
  );

  static TextStyle headlineMedium = const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Color(0xFF000000),
  );

  static TextStyle bodyLarge = const TextStyle(
    fontSize: 16,
    color: Color(0xDD000000),
  );

  static TextStyle bodyMedium = const TextStyle(
    fontSize: 14,
    color: Color(0x8A000000),
  );

  static TextStyle bodySmall = const TextStyle(
    fontSize: 12,
    color: Color(0x73000000),
  );

  /// 获取当前主题的毛玻璃配置
  static GlassmorphismConfig getCurrentGlassmorphismConfig(
      BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    if (brightness == Brightness.dark) {
      return darkGlassmorphismConfig;
    } else {
      return lightGlassmorphismConfig;
    }
  }

  /// 创建支持毛玻璃的主题数据
  static ThemeData createGlassmorphismTheme({
    Brightness brightness = Brightness.light,
    GlassmorphismThemeData? glassmorphismTheme,
  }) {
    final baseTheme =
        brightness == Brightness.dark ? _darkThemeBase : lightTheme;

    return baseTheme.copyWith(
      extensions: [
        glassmorphismTheme ??
            (brightness == Brightness.dark
                ? GlassmorphismThemeData.dark
                : GlassmorphismThemeData.light),
      ],
    );
  }

  /// 深色主题基础配置
  static ThemeData get _darkThemeBase => ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF1E40AF),
        scaffoldBackgroundColor: const Color(0xFF111827),
        cardColor: const Color(0xFF1F2937),
        fontFamily: 'Microsoft YaHei',
      );
}

/// 毛玻璃主题数据
class GlassmorphismThemeData extends ThemeExtension<GlassmorphismThemeData> {
  final GlassmorphismConfig cardConfig;
  final GlassmorphismConfig dialogConfig;
  final GlassmorphismConfig navigationConfig;
  final GlassmorphismConfig backgroundConfig;

  const GlassmorphismThemeData({
    required this.cardConfig,
    required this.dialogConfig,
    required this.navigationConfig,
    required this.backgroundConfig,
  });

  @override
  GlassmorphismThemeData copyWith({
    GlassmorphismConfig? cardConfig,
    GlassmorphismConfig? dialogConfig,
    GlassmorphismConfig? navigationConfig,
    GlassmorphismConfig? backgroundConfig,
  }) {
    return GlassmorphismThemeData(
      cardConfig: cardConfig ?? this.cardConfig,
      dialogConfig: dialogConfig ?? this.dialogConfig,
      navigationConfig: navigationConfig ?? this.navigationConfig,
      backgroundConfig: backgroundConfig ?? this.backgroundConfig,
    );
  }

  @override
  GlassmorphismThemeData lerp(
      ThemeExtension<GlassmorphismThemeData>? other, double t) {
    if (other is! GlassmorphismThemeData) return this;

    return GlassmorphismThemeData(
      cardConfig: _lerpConfig(cardConfig, other.cardConfig, t),
      dialogConfig: _lerpConfig(dialogConfig, other.dialogConfig, t),
      navigationConfig:
          _lerpConfig(navigationConfig, other.navigationConfig, t),
      backgroundConfig:
          _lerpConfig(backgroundConfig, other.backgroundConfig, t),
    );
  }

  GlassmorphismConfig _lerpConfig(
      GlassmorphismConfig a, GlassmorphismConfig b, double t) {
    return GlassmorphismConfig(
      blur: a.blur + (b.blur - a.blur) * t,
      opacity: a.opacity + (b.opacity - a.opacity) * t,
      borderRadius: a.borderRadius + (b.borderRadius - a.borderRadius) * t,
      borderWidth: a.borderWidth + (b.borderWidth - a.borderWidth) * t,
      borderColor: Color.lerp(a.borderColor, b.borderColor, t) ?? a.borderColor,
      backgroundColor: Color.lerp(a.backgroundColor, b.backgroundColor, t) ??
          a.backgroundColor,
      enablePerformanceOptimization: t < 0.5
          ? a.enablePerformanceOptimization
          : b.enablePerformanceOptimization,
    );
  }

  /// 默认浅色主题
  static const GlassmorphismThemeData light = GlassmorphismThemeData(
    cardConfig: GlassmorphismConfig.medium,
    dialogConfig: GlassmorphismConfig.light,
    navigationConfig: GlassmorphismConfig.performance,
    backgroundConfig: GlassmorphismConfig.strong,
  );

  /// 默认深色主题
  static const GlassmorphismThemeData dark = GlassmorphismThemeData(
    cardConfig: GlassmorphismConfig.dark,
    dialogConfig: GlassmorphismConfig.dark,
    navigationConfig: GlassmorphismConfig.performance,
    backgroundConfig: GlassmorphismConfig.dark,
  );
}
