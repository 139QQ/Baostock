import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:system_theme/system_theme.dart';
import 'package:window_manager/window_manager.dart';

/// Windows平台系统集成管理器
/// 提供Windows原生功能集成，包括主题检测、窗口管理等
class WindowsIntegration {
  static bool _isInitialized = false;
  static const MethodChannel _channel = MethodChannel('windows_integration');

  /// 初始化Windows集成功能
  static Future<void> initialize() async {
    if (!Platform.isWindows || _isInitialized) return;

    try {
      // 初始化窗口管理器
      await windowManager.ensureInitialized();

      // 系统主题会在首次访问时自动初始化

      // 配置窗口
      await _configureWindow();

      // 监听系统主题变化
      SystemTheme.onChange.listen((SystemAccentColor accentColor) {
        _onSystemThemeChanged(accentColor);
      });

      _isInitialized = true;
      print('Windows集成功能初始化成功');
    } catch (e) {
      print('Windows集成功能初始化失败: $e');
    }
  }

  /// 配置窗口属性
  static Future<void> _configureWindow() async {
    const windowOptions = WindowOptions(
      size: Size(1200, 800),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      windowButtonVisibility: true,
      minimumSize: Size(800, 600),
      maximumSize: Size(1920, 1080),
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  /// 系统主题变化处理
  static void _onSystemThemeChanged(SystemAccentColor accentColor) {
    // 根据系统主题调整应用主题
    // 注意：SystemTheme库不直接提供isDarkMode，需要使用其他方式检测
    print('系统主题变化: 强调色 = ${accentColor.accent}');
  }

  /// 检查是否为深色模式
  static Future<bool> isDarkMode() async {
    if (!Platform.isWindows) return false;

    // SystemTheme库不直接提供isDarkMode，使用替代方法
    // 这里返回默认值，实际项目中可以集成其他主题检测库
    try {
      // 可以通过其他方式检测系统主题，比如使用windows特定的API
      return false; // 默认返回浅色模式
    } catch (e) {
      return false;
    }
  }

  /// 获取系统强调色
  static Color? getSystemAccentColor() {
    if (!Platform.isWindows) return null;

    try {
      final accentColor = SystemTheme.accentColor;
      // 将SystemAccentColor转换为Color
      // 使用accent属性
      return Color(accentColor.accent.value);
    } catch (e) {
      print('获取系统强调色失败: $e');
      return null;
    }
  }

  /// 设置任务栏进度
  static Future<void> setTaskbarProgress(double progress) async {
    if (!Platform.isWindows) return;
    try {
      await _channel.invokeMethod('setTaskbarProgress', {'progress': progress});
    } catch (e) {
      print('设置任务栏进度失败: $e');
    }
  }

  /// 清除任务栏进度
  static Future<void> clearTaskbarProgress() async {
    if (!Platform.isWindows) return;
    try {
      await _channel.invokeMethod('clearTaskbarProgress');
    } catch (e) {
      print('清除任务栏进度失败: $e');
    }
  }

  /// 闪烁窗口以获取用户注意
  static Future<void> flashWindow() async {
    if (!Platform.isWindows) return;
    try {
      // WindowManager不提供flashWindow方法，使用替代方案
      // 闪烁窗口标题栏来获取用户注意
      await windowManager.focus();
      print('窗口已聚焦以获取用户注意');
    } catch (e) {
      print('聚焦窗口失败: $e');
    }
  }

  /// 检查是否支持Windows 10/11功能
  static bool isWindows10OrLater() {
    if (!Platform.isWindows) return false;
    try {
      final version = Platform.operatingSystemVersion;
      final majorVersion = int.tryParse(version.split(' ')[0]) ?? 0;
      return majorVersion >= 10;
    } catch (e) {
      return false;
    }
  }

  /// 获取Windows版本信息
  static Future<WindowsVersion?> getWindowsVersion() async {
    if (!Platform.isWindows) return null;
    try {
      final versionInfo = await _channel.invokeMethod('getWindowsVersion');
      return WindowsVersion.fromMap(versionInfo);
    } catch (e) {
      print('获取Windows版本失败: $e');
      return null;
    }
  }

  /// 设置窗口为全屏模式
  static Future<void> setFullScreen(bool isFullScreen) async {
    if (!Platform.isWindows) return;

    try {
      if (isFullScreen) {
        await windowManager.setFullScreen(true);
      } else {
        await windowManager.setFullScreen(false);
        await windowManager.center();
      }
    } catch (e) {
      print('设置全屏模式失败: $e');
    }
  }

  /// 设置窗口为最大化
  static Future<void> setMaximized(bool isMaximized) async {
    if (!Platform.isWindows) return;

    try {
      if (isMaximized) {
        await windowManager.maximize();
      } else {
        await windowManager.unmaximize();
      }
    } catch (e) {
      print('设置最大化状态失败: $e');
    }
  }

  /// 最小化窗口
  static Future<void> minimizeWindow() async {
    if (!Platform.isWindows) return;

    try {
      await windowManager.minimize();
    } catch (e) {
      print('最小化窗口失败: $e');
    }
  }

  /// 恢复窗口
  static Future<void> restoreWindow() async {
    if (!Platform.isWindows) return;

    try {
      await windowManager.restore();
    } catch (e) {
      print('恢复窗口失败: $e');
    }
  }
}

/// 跳转列表项目
class JumpListItem {
  final String name;
  final String description;
  final String arguments;
  final String iconPath;
  final String? workingDirectory;

  JumpListItem({
    required this.name,
    required this.description,
    required this.arguments,
    required this.iconPath,
    this.workingDirectory,
  });

  Map<String, String> toMap() {
    return {
      'name': name,
      'description': description,
      'arguments': arguments,
      'iconPath': iconPath,
      if (workingDirectory != null) 'workingDirectory': workingDirectory!,
    };
  }
}

/// Windows版本信息
class WindowsVersion {
  final int major;
  final int minor;
  final int build;
  final String? edition;

  WindowsVersion({
    required this.major,
    required this.minor,
    required this.build,
    this.edition,
  });

  factory WindowsVersion.fromMap(Map<String, dynamic> map) {
    return WindowsVersion(
      major: map['major'] ?? 0,
      minor: map['minor'] ?? 0,
      build: map['build'] ?? 0,
      edition: map['edition'],
    );
  }

  bool get isWindows10OrLater => major >= 10;
  bool get isWindows11OrLater => major >= 11;

  @override
  String toString() {
    return 'Windows $major.$minor.$build${edition != null ? ' ($edition)' : ''}';
  }
}
