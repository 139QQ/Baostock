import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:window_manager/window_manager.dart';

import 'windows_integration.dart';

/// 窗口效果管理器
/// 提供Windows原生窗口效果，包括毛玻璃、透明度、动画等
class WindowEffects {
  static bool _isInitialized = false;

  /// 初始化窗口效果
  static Future<void> initialize() async {
    if (!Platform.isWindows || _isInitialized) return;

    try {
      await Window.initialize();
      _isInitialized = true;
      print('窗口效果管理器初始化成功');
    } catch (e) {
      print('窗口效果管理器初始化失败: $e');
    }
  }

  /// 设置窗口毛玻璃效果
  static Future<void> setAcrylicEffect({
    Color tint = Colors.white,
    double opacity = 0.7,
  }) async {
    if (!Platform.isWindows || !_isInitialized) return;

    try {
      await Window.setEffect(
        effect: WindowEffect.acrylic,
        color: tint.withOpacity(opacity),
      );
    } catch (e) {
      print('设置毛玻璃效果失败: $e');
    }
  }

  /// 设置窗口透明效果
  static Future<void> setTransparentEffect({
    Color color = Colors.transparent,
    double opacity = 0.9,
  }) async {
    if (!Platform.isWindows || !_isInitialized) return;

    try {
      await Window.setEffect(
        effect: WindowEffect.transparent,
        color: color.withOpacity(opacity),
      );
    } catch (e) {
      print('设置透明效果失败: $e');
    }
  }

  /// 移除窗口效果
  static Future<void> clearEffect() async {
    if (!Platform.isWindows || !_isInitialized) return;

    try {
      await Window.setEffect(effect: WindowEffect.disabled);
    } catch (e) {
      print('清除窗口效果失败: $e');
    }
  }

  /// 检查是否支持特定效果
  static Future<bool> isEffectSupported(WindowEffect effect) async {
    if (!Platform.isWindows || !_isInitialized) return false;

    try {
      // 尝试应用效果来测试支持情况
      await Window.setEffect(effect: effect);
      // 如果成功应用，则清除效果并返回true
      await Window.setEffect(effect: WindowEffect.disabled);
      return true;
    } catch (e) {
      // 如果失败，说明不支持该效果
      return false;
    }
  }

  /// 根据Windows版本自动选择最佳效果
  static Future<void> applyOptimalEffect() async {
    if (!Platform.isWindows) return;

    final version = await WindowsIntegration.getWindowsVersion();
    if (version == null) return;

    if (version.isWindows11OrLater) {
      // Windows 11 使用 Mica 效果（如果支持）
      if (await isEffectSupported(WindowEffect.mica)) {
        await Window.setEffect(effect: WindowEffect.mica);
      } else {
        await setAcrylicEffect(
          tint: Colors.white.withOpacity(0.1),
        );
      }
    } else if (version.isWindows10OrLater) {
      // Windows 10 使用毛玻璃效果
      await setAcrylicEffect(
        tint: Colors.white.withOpacity(0.1),
      );
    }
  }

  /// 应用主题相关效果
  static Future<void> applyThemeEffect(bool isDarkMode) async {
    if (!Platform.isWindows) return;

    if (isDarkMode) {
      await setAcrylicEffect(
        tint: Colors.black.withOpacity(0.2),
      );
    } else {
      await setAcrylicEffect(
        tint: Colors.white.withOpacity(0.1),
      );
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

  /// 窗口震动效果（用于警告或提醒）
  static Future<void> shakeWindow({
    int count = 3,
    Duration duration = const Duration(milliseconds: 100),
  }) async {
    if (!Platform.isWindows) return;

    try {
      final originalPosition = await windowManager.getPosition();

      for (int i = 0; i < count; i++) {
        final offset = (i % 2 == 0) ? 10 : -10;
        await windowManager.setPosition(
          Offset(originalPosition.dx + offset, originalPosition.dy),
        );

        await Future.delayed(const Duration(milliseconds: 50));
      }

      // 恢复原始位置
      await windowManager.setPosition(originalPosition);
    } catch (e) {
      print('窗口震动效果失败: $e');
    }
  }

  /// 设置窗口大小
  static Future<void> setWindowSize(Size size) async {
    if (!Platform.isWindows) return;

    try {
      await windowManager.setSize(size);
    } catch (e) {
      print('设置窗口大小失败: $e');
    }
  }

  /// 设置窗口位置
  static Future<void> setWindowPosition(Offset position) async {
    if (!Platform.isWindows) return;

    try {
      await windowManager.setPosition(position);
    } catch (e) {
      print('设置窗口位置失败: $e');
    }
  }

  /// 设置窗口标题
  static Future<void> setWindowTitle(String title) async {
    if (!Platform.isWindows) return;

    try {
      await windowManager.setTitle(title);
    } catch (e) {
      print('设置窗口标题失败: $e');
    }
  }

  /// 获取窗口大小
  static Future<Size?> getWindowSize() async {
    if (!Platform.isWindows) return null;

    try {
      return await windowManager.getSize();
    } catch (e) {
      print('获取窗口大小失败: $e');
      return null;
    }
  }

  /// 获取窗口位置
  static Future<Offset?> getWindowPosition() async {
    if (!Platform.isWindows) return null;

    try {
      return await windowManager.getPosition();
    } catch (e) {
      print('获取窗口位置失败: $e');
      return null;
    }
  }

  /// 窗口是否可见
  static Future<bool> isWindowVisible() async {
    if (!Platform.isWindows) return false;

    try {
      return await windowManager.isVisible();
    } catch (e) {
      print('检查窗口可见性失败: $e');
      return false;
    }
  }

  /// 显示窗口
  static Future<void> showWindow() async {
    if (!Platform.isWindows) return;

    try {
      await windowManager.show();
    } catch (e) {
      print('显示窗口失败: $e');
    }
  }

  /// 隐藏窗口
  static Future<void> hideWindow() async {
    if (!Platform.isWindows) return;

    try {
      await windowManager.hide();
    } catch (e) {
      print('隐藏窗口失败: $e');
    }
  }

  /// 设置窗口置顶
  static Future<void> setAlwaysOnTop(bool alwaysOnTop) async {
    if (!Platform.isWindows) return;

    try {
      await windowManager.setAlwaysOnTop(alwaysOnTop);
    } catch (e) {
      print('设置窗口置顶失败: $e');
    }
  }
}
