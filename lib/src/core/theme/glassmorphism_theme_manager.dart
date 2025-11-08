import 'package:flutter/material.dart';

import '../performance/performance_detector.dart';
import 'app_theme.dart';

/// 毛玻璃主题管理器
///
/// 管理毛玻璃效果的主题配置：
/// - 主题切换时的平滑过渡
/// - 动态配置调整
/// - 用户偏好保存
/// - 响应式配置
class GlassmorphismThemeManager extends ChangeNotifier {
  static final GlassmorphismThemeManager _instance =
      GlassmorphismThemeManager._internal();
  factory GlassmorphismThemeManager() => _instance;
  GlassmorphismThemeManager._internal();

  GlassmorphismConfig _currentConfig =
      FluentAppTheme.defaultGlassmorphismConfig;
  ThemeMode _themeMode = ThemeMode.system;
  bool _isDarkTheme = false;
  bool _enableAdaptiveConfig = true;
  double _userIntensityPreference = 1.0; // 0.0 - 2.0

  // Getters
  GlassmorphismConfig get currentConfig => _currentConfig;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkTheme => _isDarkTheme;
  bool get enableAdaptiveConfig => _enableAdaptiveConfig;
  double get userIntensityPreference => _userIntensityPreference;

  /// 设置毛玻璃配置
  void setGlassmorphismConfig(GlassmorphismConfig config) {
    _currentConfig = config;
    notifyListeners();
  }

  /// 设置主题模式
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _updateThemeConfig();
    notifyListeners();
  }

  /// 更新主题状态
  void updateThemeState(bool isDark) {
    if (_isDarkTheme != isDark) {
      _isDarkTheme = isDark;
      _updateThemeConfig();
      notifyListeners();
    }
  }

  /// 启用/禁用自适应配置
  void setAdaptiveConfig(bool enabled) {
    _enableAdaptiveConfig = enabled;
    _updateThemeConfig();
    notifyListeners();
  }

  /// 设置用户强度偏好
  void setUserIntensityPreference(double preference) {
    _userIntensityPreference = preference.clamp(0.0, 2.0);
    _updateThemeConfig();
    notifyListeners();
  }

  /// 更新主题配置
  void _updateThemeConfig() {
    if (!_enableAdaptiveConfig) return;

    final baseConfig = _getBaseConfigForTheme();
    final adjustedConfig = _applyUserPreferences(baseConfig);

    _currentConfig = adjustedConfig;
  }

  /// 获取主题基础配置
  GlassmorphismConfig _getBaseConfigForTheme() {
    if (_themeMode == ThemeMode.dark) {
      return FluentAppTheme.darkGlassmorphismConfig;
    } else if (_themeMode == ThemeMode.light) {
      return FluentAppTheme.lightGlassmorphismConfig;
    } else {
      // 系统主题
      return _isDarkTheme
          ? FluentAppTheme.darkGlassmorphismConfig
          : FluentAppTheme.lightGlassmorphismConfig;
    }
  }

  /// 应用用户偏好
  GlassmorphismConfig _applyUserPreferences(GlassmorphismConfig baseConfig) {
    return GlassmorphismConfig(
      blur: baseConfig.blur * _userIntensityPreference,
      opacity: baseConfig.opacity * _userIntensityPreference.clamp(0.5, 1.5),
      borderRadius: baseConfig.borderRadius,
      borderWidth: baseConfig.borderWidth,
      borderColor: baseConfig.borderColor,
      backgroundColor: baseConfig.backgroundColor,
      enablePerformanceOptimization: baseConfig.enablePerformanceOptimization,
    );
  }

  /// 预设配置
  static const Map<String, GlassmorphismConfig> presetConfigs = {
    'subtle': GlassmorphismConfig.light,
    'balanced': GlassmorphismConfig.medium,
    'strong': GlassmorphismConfig.strong,
    'performance': GlassmorphismConfig.performance,
    'dark': GlassmorphismConfig.dark,
  };

  /// 应用预设配置
  void applyPresetConfig(String presetName) {
    final config = presetConfigs[presetName];
    if (config != null) {
      _currentConfig = config;
      notifyListeners();
    }
  }

  /// 创建自定义配置
  GlassmorphismConfig createCustomConfig({
    double? blur,
    double? opacity,
    double? borderRadius,
    double? borderWidth,
    Color? borderColor,
    Color? backgroundColor,
    bool? enablePerformanceOptimization,
  }) {
    return GlassmorphismConfig(
      blur: blur ?? _currentConfig.blur,
      opacity: opacity ?? _currentConfig.opacity,
      borderRadius: borderRadius ?? _currentConfig.borderRadius,
      borderWidth: borderWidth ?? _currentConfig.borderWidth,
      borderColor: borderColor ?? _currentConfig.borderColor,
      backgroundColor: backgroundColor ?? _currentConfig.backgroundColor,
      enablePerformanceOptimization: enablePerformanceOptimization ??
          _currentConfig.enablePerformanceOptimization,
    );
  }

  /// 获取配置摘要信息
  Map<String, dynamic> getConfigSummary() {
    return {
      'blur': _currentConfig.blur,
      'opacity': _currentConfig.opacity,
      'borderRadius': _currentConfig.borderRadius,
      'borderWidth': _currentConfig.borderWidth,
      'enablePerformanceOptimization':
          _currentConfig.enablePerformanceOptimization,
      'themeMode': _themeMode.toString(),
      'isDarkTheme': _isDarkTheme,
      'enableAdaptiveConfig': _enableAdaptiveConfig,
      'userIntensityPreference': _userIntensityPreference,
    };
  }

  /// 重置为默认配置
  void resetToDefault() {
    _currentConfig = FluentAppTheme.defaultGlassmorphismConfig;
    _themeMode = ThemeMode.system;
    _enableAdaptiveConfig = true;
    _userIntensityPreference = 1.0;
    notifyListeners();
  }
}

/// 响应式毛玻璃配置生成器
class ResponsiveGlassmorphismConfig {
  /// 根据屏幕尺寸生成配置
  static GlassmorphismConfig forScreenSize(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final isLargeScreen = screenSize.width > 1200;

    if (isSmallScreen) {
      // 小屏幕 - 减少模糊度以提升性能
      return const GlassmorphismConfig(
        blur: 5.0,
        opacity: 0.08,
        borderRadius: 8.0,
        enablePerformanceOptimization: true,
      );
    } else if (isLargeScreen) {
      // 大屏幕 - 可以使用更强的效果
      return const GlassmorphismConfig(
        blur: 12.0,
        opacity: 0.12,
        borderRadius: 16.0,
        enablePerformanceOptimization: false,
      );
    } else {
      // 中等屏幕 - 默认配置
      return GlassmorphismConfig.medium;
    }
  }

  /// 根据设备性能生成配置
  static GlassmorphismConfig forDevicePerformance(PerformanceLevel level) {
    switch (level) {
      case PerformanceLevel.excellent:
        return GlassmorphismConfig.strong;
      case PerformanceLevel.good:
        return GlassmorphismConfig.medium;
      case PerformanceLevel.fair:
        return GlassmorphismConfig.light;
      case PerformanceLevel.poor:
        return GlassmorphismConfig.performance;
    }
    // 添加默认返回确保函数总是有返回值
    return GlassmorphismConfig.medium;
  }

  /// 根据内容类型生成配置
  static GlassmorphismConfig forContentType(GlassmorphismContentType type) {
    switch (type) {
      case GlassmorphismContentType.card:
        return GlassmorphismConfig.medium;
      case GlassmorphismContentType.dialog:
        return GlassmorphismConfig.light;
      case GlassmorphismContentType.navigation:
        return GlassmorphismConfig.performance;
      case GlassmorphismContentType.background:
        return GlassmorphismConfig.strong;
    }
  }
}

/// 毛玻璃内容类型枚举
enum GlassmorphismContentType {
  card,
  dialog,
  navigation,
  background,
}

extension GlassmorphismContentTypeExtension on GlassmorphismContentType {
  String get displayName {
    switch (this) {
      case GlassmorphismContentType.card:
        return '卡片';
      case GlassmorphismContentType.dialog:
        return '对话框';
      case GlassmorphismContentType.navigation:
        return '导航';
      case GlassmorphismContentType.background:
        return '背景';
    }
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
