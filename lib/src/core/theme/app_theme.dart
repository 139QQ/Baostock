import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 导入设计令牌
import 'design_tokens/app_colors.dart';
import 'design_tokens/app_typography.dart';
import 'design_tokens/app_spacing.dart';
import '../performance/performance_detector.dart';

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
        return SemanticColors.success500;
      case PerformanceLevel.good:
        return BaseColors.primary500;
      case PerformanceLevel.fair:
        return SemanticColors.warning500;
      case PerformanceLevel.poor:
        return SemanticColors.error500;
    }
  }
}

/// 毛玻璃效果配置 (基于Fluent Design)
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
    this.borderColor = BaseColors.primary500,
    this.backgroundColor = BaseColors.primary50,
    this.enablePerformanceOptimization = true,
  });

  /// 轻量毛玻璃配置
  static const GlassmorphismConfig light = GlassmorphismConfig(
    blur: 5.0,
    opacity: 0.05,
    borderRadius: 8.0,
    borderWidth: 0.5,
    backgroundColor: BaseColors.primary50,
  );

  /// 中等毛玻璃配置
  static const GlassmorphismConfig medium = GlassmorphismConfig(
    blur: 10.0,
    opacity: 0.1,
    borderRadius: 12.0,
    borderWidth: 1.0,
    backgroundColor: BaseColors.primary100,
  );

  /// 强烈毛玻璃配置
  static const GlassmorphismConfig strong = GlassmorphismConfig(
    blur: 15.0,
    opacity: 0.15,
    borderRadius: 16.0,
    borderWidth: 1.5,
    backgroundColor: BaseColors.primary200,
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
    borderColor: NeutralColors.neutral600,
    backgroundColor: NeutralColors.neutral800,
  );
}

/// Fluent Design 主题配置
class FluentAppTheme {
  FluentAppTheme._();

  // 主色调
  static const Color primaryColor = BaseColors.primary500;
  static const Color primaryLightColor = BaseColors.primary400;
  static const Color primaryDarkColor = BaseColors.primary600;

  // 语义色
  static const Color successColor = SemanticColors.success500;
  static const Color warningColor = SemanticColors.warning500;
  static const Color errorColor = SemanticColors.error500;
  static const Color infoColor = SemanticColors.info500;

  // 中性色
  static const Color backgroundColor = NeutralColors.neutral50;
  static const Color surfaceColor = NeutralColors.white;
  static const Color cardColor = NeutralColors.white;

  // 文本色
  static const Color textPrimaryColor = NeutralColors.neutral900;
  static const Color textSecondaryColor = NeutralColors.neutral700;
  static const Color textTertiaryColor = NeutralColors.neutral500;

  // 金融色
  static const Color positiveColor = FinancialColors.positive;
  static const Color negativeColor = FinancialColors.negative;
  static const Color flatColor = FinancialColors.neutral;

  /// 默认毛玻璃配置
  static const GlassmorphismConfig defaultGlassmorphismConfig =
      GlassmorphismConfig.medium;
  static const GlassmorphismConfig lightGlassmorphismConfig =
      GlassmorphismConfig.light;
  static const GlassmorphismConfig darkGlassmorphismConfig =
      GlassmorphismConfig.dark;
  static const GlassmorphismConfig performanceGlassmorphismConfig =
      GlassmorphismConfig.performance;

  /// 浅色主题
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: BaseColors.primary300,
        surface: surfaceColor,
        background: backgroundColor,
        error: errorColor,
        onPrimary: NeutralColors.white,
        onSecondary: textPrimaryColor,
        onSurface: textPrimaryColor,
        onBackground: textPrimaryColor,
        onError: NeutralColors.white,
      ),

      // 文本主题
      textTheme: TextTheme(
        displayLarge: AppTextStyles.h1,
        displayMedium: AppTextStyles.h2,
        displaySmall: AppTextStyles.h3,
        headlineLarge: AppTextStyles.h4,
        headlineMedium: AppTextStyles.h5,
        headlineSmall: AppTextStyles.h6,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.body,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.label,
        labelMedium: AppTextStyles.label,
        labelSmall: AppTextStyles.caption,
      ),

      // 字体
      fontFamily: FontFamilies.defaultFamily,

      // AppBar 主题
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textPrimaryColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTextStyles.h5.copyWith(color: textPrimaryColor),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      // 卡片主题
      cardTheme: CardTheme(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BorderRadiusTokens.card),
          side: BorderSide(color: NeutralColors.neutral200, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // 按钮主题
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: NeutralColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BorderRadiusTokens.button),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: ComponentSpacing.buttonPaddingH,
            vertical: ComponentSpacing.buttonPaddingV,
          ),
          textStyle: AppTextStyles.button,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BorderRadiusTokens.button),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: ComponentSpacing.buttonPaddingH,
            vertical: ComponentSpacing.buttonPaddingV,
          ),
          textStyle: AppTextStyles.button,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BorderRadiusTokens.button),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: ComponentSpacing.buttonPaddingH,
            vertical: ComponentSpacing.buttonPaddingV,
          ),
          textStyle: AppTextStyles.button,
        ),
      ),

      // 输入框主题
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NeutralColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BorderRadiusTokens.input),
          borderSide: BorderSide(color: NeutralColors.neutral300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BorderRadiusTokens.input),
          borderSide: BorderSide(color: NeutralColors.neutral300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BorderRadiusTokens.input),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BorderRadiusTokens.input),
          borderSide: BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BorderRadiusTokens.input),
          borderSide: BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ComponentSpacing.inputPaddingH,
          vertical: ComponentSpacing.inputPaddingV,
        ),
        hintStyle:
            AppTextStyles.input.copyWith(color: NeutralColors.neutral500),
        labelStyle:
            AppTextStyles.label.copyWith(color: NeutralColors.neutral700),
        errorStyle: AppTextStyles.caption.copyWith(color: errorColor),
      ),

      // 分割线主题
      dividerTheme: DividerThemeData(
        color: NeutralColors.neutral200,
        thickness: 1,
        space: 1,
      ),

      // 图标主题
      iconTheme: IconThemeData(
        color: NeutralColors.neutral700,
        size: StandardSizes.iconMd,
      ),

      // 浮动操作按钮主题
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: NeutralColors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // 对话框主题
      dialogTheme: DialogTheme(
        backgroundColor: surfaceColor,
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BorderRadiusTokens.dialog),
        ),
        titleTextStyle: AppTextStyles.h5.copyWith(color: textPrimaryColor),
        contentTextStyle:
            AppTextStyles.body.copyWith(color: textSecondaryColor),
      ),

      // 底部导航栏主题
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: NeutralColors.neutral500,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle:
            AppTextStyles.caption.copyWith(fontWeight: FontWeights.medium),
        unselectedLabelStyle: AppTextStyles.caption,
      ),

      // Tab 主题
      tabBarTheme: TabBarTheme(
        labelColor: primaryColor,
        unselectedLabelColor: NeutralColors.neutral500,
        indicatorColor: primaryColor,
        labelStyle:
            AppTextStyles.label.copyWith(fontWeight: FontWeights.medium),
        unselectedLabelStyle: AppTextStyles.label,
        indicatorSize: TabBarIndicatorSize.label,
      ),

      // Chip 主题
      chipTheme: ChipThemeData(
        backgroundColor: NeutralColors.neutral100,
        selectedColor: BaseColors.primary100,
        disabledColor: NeutralColors.neutral50,
        labelStyle:
            AppTextStyles.label.copyWith(color: NeutralColors.neutral700),
        secondaryLabelStyle: AppTextStyles.label.copyWith(color: primaryColor),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BorderRadiusTokens.chip),
        ),
      ),

      // 扩展：毛玻璃主题
      extensions: [
        GlassmorphismThemeData.light,
      ],
    );
  }

  /// 深色主题
  static ThemeData get darkTheme {
    return lightTheme.copyWith(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: BaseColors.primary400,
        secondary: BaseColors.primary300,
        surface: NeutralColors.neutral900,
        background: NeutralColors.neutral950,
        error: errorColor,
        onPrimary: NeutralColors.neutral900,
        onSecondary: NeutralColors.neutral900,
        onSurface: NeutralColors.neutral100,
        onBackground: NeutralColors.neutral100,
        onError: NeutralColors.neutral100,
      ),

      // AppBar 主题
      appBarTheme: AppBarTheme(
        backgroundColor: NeutralColors.neutral900,
        foregroundColor: NeutralColors.neutral100,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle:
            AppTextStyles.h5.copyWith(color: NeutralColors.neutral100),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      // 卡片主题
      cardTheme: CardTheme(
        color: NeutralColors.neutral900,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BorderRadiusTokens.card),
          side: BorderSide(color: NeutralColors.neutral700, width: 1),
        ),
      ),

      // 扩展：毛玻璃主题
      extensions: [
        GlassmorphismThemeData.dark,
      ],
    );
  }

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
    final baseTheme = brightness == Brightness.dark ? darkTheme : lightTheme;

    return baseTheme.copyWith(
      extensions: [
        glassmorphismTheme ??
            (brightness == Brightness.dark
                ? GlassmorphismThemeData.dark
                : GlassmorphismThemeData.light),
      ],
    );
  }

  /// 获取响应式文本样式
  static TextStyle getResponsiveTextStyle(
    BuildContext context, {
    TextStyle? baseStyle,
    double scaleFactor = 1.0,
  }) {
    final width = MediaQuery.of(context).size.width;
    double responsiveScale = 1.0;

    if (width < BreakpointTokens.tablet) {
      responsiveScale = 0.875; // 移动端缩小
    } else if (width < BreakpointTokens.desktopMD) {
      responsiveScale = 0.9375; // 平板端略小
    } else if (width > BreakpointTokens.desktopXL) {
      responsiveScale = 1.125; // 超大桌面放大
    }

    final finalScale = responsiveScale * scaleFactor;
    return baseStyle?.copyWith(
          fontSize: (baseStyle.fontSize ?? 14) * finalScale,
        ) ??
        AppTextStyles.body.copyWith(
          fontSize: FontSizes.body * finalScale,
        );
  }

  /// 获取响应式间距
  static double getResponsiveSpacing(
    BuildContext context,
    double baseSpacing, {
    double scaleFactor = 1.0,
  }) {
    final width = MediaQuery.of(context).size.width;
    double responsiveScale = 1.0;

    if (width < BreakpointTokens.tablet) {
      responsiveScale = 0.75; // 移动端间距缩小
    } else if (width < BreakpointTokens.desktopMD) {
      responsiveScale = 0.875; // 平板端间距略小
    }

    return baseSpacing * responsiveScale * scaleFactor;
  }
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

/// 向后兼容的 AppTheme 类
@Deprecated('使用 FluentAppTheme 替代')
class AppTheme {
  static Color get primaryColor => FluentAppTheme.primaryColor;
  static Color get successColor => FluentAppTheme.successColor;
  static Color get warningColor => FluentAppTheme.warningColor;
  static Color get errorColor => FluentAppTheme.errorColor;
  static Color get neutralColor => FluentAppTheme.textSecondaryColor;
  static Color get backgroundColor => FluentAppTheme.backgroundColor;
  static Color get cardColor => FluentAppTheme.cardColor;

  static TextStyle get headlineLarge => AppTextStyles.h4;
  static TextStyle get headlineMedium => AppTextStyles.h5;
  static TextStyle get bodyLarge => AppTextStyles.bodyLarge;
  static TextStyle get bodyMedium => AppTextStyles.body;
  static TextStyle get bodySmall => AppTextStyles.bodySmall;

  static ThemeData get lightTheme => FluentAppTheme.lightTheme;

  /// 获取当前主题的毛玻璃配置
  static GlassmorphismConfig getCurrentGlassmorphismConfig(
      BuildContext context) {
    return FluentAppTheme.getCurrentGlassmorphismConfig(context);
  }

  /// 创建支持毛玻璃的主题数据
  static ThemeData createGlassmorphismTheme({
    Brightness brightness = Brightness.light,
    GlassmorphismThemeData? glassmorphismTheme,
  }) {
    return FluentAppTheme.createGlassmorphismTheme(
      brightness: brightness,
      glassmorphismTheme: glassmorphismTheme,
    );
  }
}
