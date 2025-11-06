import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 导航配置
///
/// 管理多平台导航系统的配置选项和启用状态
class NavigationConfig {
  static NavigationConfig? _instance;
  static NavigationConfig get instance {
    _instance ??= NavigationConfig._();
    return _instance!;
  }

  NavigationConfig._() {
    _initializeFromEnvironment();
  }

  /// 是否启用多平台导航
  bool _enableMultiPlatformNavigation = false;

  /// 是否使用响应式导航
  bool _useResponsiveNavigation = false;

  /// 是否启用Web端导航
  bool _enableWebNavigation = false;

  /// 是否启用移动端导航
  bool _enableMobileNavigation = false;

  /// 强制使用特定导航模式（开发测试用）
  MultiPlatformNavigationMode? _forcedNavigationMode;

  // Getters
  bool get enableMultiPlatformNavigation => _enableMultiPlatformNavigation;
  bool get useResponsiveNavigation => _useResponsiveNavigation;
  bool get enableWebNavigation => _enableWebNavigation;
  bool get enableMobileNavigation => _enableMobileNavigation;
  MultiPlatformNavigationMode? get forcedNavigationMode =>
      _forcedNavigationMode;

  /// 从环境变量初始化配置
  void _initializeFromEnvironment() {
    // 开发模式下默认启用多平台导航
    if (kDebugMode) {
      _enableMultiPlatformNavigation = true;
      _useResponsiveNavigation = true;
      _enableWebNavigation = kIsWeb;
      _enableMobileNavigation = !kIsWeb;
    } else {
      // 生产模式下根据平台自动决定
      _determineProductionSettings();
    }

    // 从环境变量读取配置（如果存在）
    _loadFromEnvironmentVariables();

    debugPrint(
        '🧭 NavigationConfig: 多平台导航已${_enableMultiPlatformNavigation ? '启用' : '禁用'}');
    debugPrint(
        '🧭 NavigationConfig: 响应式导航已${_useResponsiveNavigation ? '启用' : '禁用'}');
    debugPrint(
        '🧭 NavigationConfig: Web导航已${_enableWebNavigation ? '启用' : '禁用'}');
    debugPrint(
        '🧭 NavigationConfig: 移动导航已${_enableMobileNavigation ? '启用' : '禁用'}');
  }

  /// 确定生产环境设置
  void _determineProductionSettings() {
    if (kIsWeb) {
      // Web环境启用响应式导航
      _enableMultiPlatformNavigation = true;
      _useResponsiveNavigation = true;
      _enableWebNavigation = true;
      _enableMobileNavigation = false;
    } else {
      // 移动环境暂时使用传统导航，未来可启用移动导航
      _enableMultiPlatformNavigation = false;
      _useResponsiveNavigation = false;
      _enableWebNavigation = false;
      _enableMobileNavigation = false;
    }
  }

  /// 从环境变量加载配置
  void _loadFromEnvironmentVariables() {
    // 注意：这里可以从dart-define或环境变量读取配置
    // 例如：const enableMultiPlatform = String.fromEnvironment('ENABLE_MULTI_PLATFORM', defaultValue: 'false');

    // 暂时使用硬编码的开发配置
    if (kDebugMode) {
      // 开发环境可以通过dart-define配置
      const String forceMode =
          String.fromEnvironment('NAVIGATION_MODE', defaultValue: '');
      if (forceMode.isNotEmpty) {
        _forcedNavigationMode = MultiPlatformNavigationMode.values.firstWhere(
          (mode) => mode.toString() == 'MultiPlatformNavigationMode.$forceMode',
          orElse: () => MultiPlatformNavigationMode.auto,
        );
        debugPrint('🧭 NavigationConfig: 强制导航模式: $_forcedNavigationMode');
      }
    }
  }

  /// 获取当前应该使用的导航模式
  MultiPlatformNavigationMode getCurrentNavigationMode() {
    if (_forcedNavigationMode != null) {
      return _forcedNavigationMode!;
    }

    if (!_enableMultiPlatformNavigation) {
      return MultiPlatformNavigationMode.legacy;
    }

    if (!_useResponsiveNavigation) {
      return MultiPlatformNavigationMode.legacy;
    }

    return MultiPlatformNavigationMode.auto;
  }

  /// 检查是否应该使用Web导航
  bool shouldUseWebNavigation(BuildContext context) {
    if (!_enableMultiPlatformNavigation || !_enableWebNavigation) {
      return false;
    }

    if (_forcedNavigationMode == MultiPlatformNavigationMode.web) {
      return true;
    }

    if (_forcedNavigationMode != null &&
        _forcedNavigationMode != MultiPlatformNavigationMode.auto) {
      return false;
    }

    return kIsWeb;
  }

  /// 检查是否应该使用移动端导航
  bool shouldUseMobileNavigation(BuildContext context) {
    if (!_enableMultiPlatformNavigation || !_enableMobileNavigation) {
      return false;
    }

    if (_forcedNavigationMode == MultiPlatformNavigationMode.mobile) {
      return true;
    }

    if (_forcedNavigationMode != null &&
        _forcedNavigationMode != MultiPlatformNavigationMode.auto) {
      return false;
    }

    return !kIsWeb;
  }

  /// 手动更新配置（用于运行时切换）
  void updateConfig({
    bool? enableMultiPlatformNavigation,
    bool? useResponsiveNavigation,
    bool? enableWebNavigation,
    bool? enableMobileNavigation,
    MultiPlatformNavigationMode? forcedNavigationMode,
  }) {
    if (enableMultiPlatformNavigation != null) {
      _enableMultiPlatformNavigation = enableMultiPlatformNavigation;
    }
    if (useResponsiveNavigation != null) {
      _useResponsiveNavigation = useResponsiveNavigation;
    }
    if (enableWebNavigation != null) {
      _enableWebNavigation = enableWebNavigation;
    }
    if (enableMobileNavigation != null) {
      _enableMobileNavigation = enableMobileNavigation;
    }
    if (forcedNavigationMode != null) {
      _forcedNavigationMode = forcedNavigationMode;
    }

    debugPrint('🧭 NavigationConfig: 配置已更新');
  }

  /// 重置为默认配置
  void resetToDefaults() {
    _enableMultiPlatformNavigation = false;
    _useResponsiveNavigation = false;
    _enableWebNavigation = false;
    _enableMobileNavigation = false;
    _forcedNavigationMode = null;
    _initializeFromEnvironment();
  }

  /// 获取配置摘要
  Map<String, dynamic> getConfigSummary() {
    return {
      'enableMultiPlatformNavigation': _enableMultiPlatformNavigation,
      'useResponsiveNavigation': _useResponsiveNavigation,
      'enableWebNavigation': _enableWebNavigation,
      'enableMobileNavigation': _enableMobileNavigation,
      'forcedNavigationMode': _forcedNavigationMode?.toString(),
      'currentMode': getCurrentNavigationMode().toString(),
      'isWeb': kIsWeb,
      'isDebugMode': kDebugMode,
    };
  }

  /// 打印配置摘要
  void printConfigSummary() {
    final summary = getConfigSummary();
    debugPrint('🧭 NavigationConfig 配置摘要:');
    summary.forEach((key, value) {
      debugPrint('  $key: $value');
    });
  }
}

/// 导航模式枚举
enum MultiPlatformNavigationMode {
  /// 自动选择（根据平台和屏幕尺寸）
  auto,

  /// 使用传统导航
  legacy,

  /// 强制使用Web导航
  web,

  /// 强制使用移动端导航
  mobile,

  /// 强制使用桌面端导航
  desktop,
}

/// 导航模式扩展方法
extension MultiPlatformNavigationModeExtension on MultiPlatformNavigationMode {
  /// 获取模式显示名称
  String get displayName {
    switch (this) {
      case MultiPlatformNavigationMode.auto:
        return '自动';
      case MultiPlatformNavigationMode.legacy:
        return '传统';
      case MultiPlatformNavigationMode.web:
        return 'Web';
      case MultiPlatformNavigationMode.mobile:
        return '移动端';
      case MultiPlatformNavigationMode.desktop:
        return '桌面端';
    }
  }

  /// 获取模式描述
  String get description {
    switch (this) {
      case MultiPlatformNavigationMode.auto:
        return '根据平台和屏幕尺寸自动选择最适合的导航模式';
      case MultiPlatformNavigationMode.legacy:
        return '使用现有的传统导航系统';
      case MultiPlatformNavigationMode.web:
        return '强制使用Web端导航（扩展式或紧凑式）';
      case MultiPlatformNavigationMode.mobile:
        return '强制使用移动端导航（底部标签栏 + 抽屉菜单）';
      case MultiPlatformNavigationMode.desktop:
        return '强制使用桌面端导航（侧边栏）';
    }
  }
}
