import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/logger.dart';
import 'permission_history_manager.dart';

/// 简单的权限请求工具类
class SimplePermissionRequester {
  /// 在应用启动时只检查权限状态，不主动请求
  static Future<void> checkPermissionsOnStartup() async {
    if (kIsWeb) {
      AppLogger.debug('Web平台跳过权限检查');
      return;
    }

    try {
      AppLogger.debug('🔍 检查应用权限状态');

      // 只检查权限状态，不主动请求
      await checkAllPermissions();

      AppLogger.debug('✅ 权限状态检查完成');
    } catch (e, stack) {
      AppLogger.error('❌ 权限状态检查失败', e, stack);
    }
  }

  /// 请求通知权限
  static Future<bool> _requestNotificationPermission() async {
    try {
      AppLogger.debug('📱 请求通知权限');

      // 检查并请求通知权限
      PermissionStatus status = await Permission.notification.request();

      if (status.isGranted) {
        AppLogger.debug('✅ 通知权限已授予');
        return true;
      } else if (status.isDenied) {
        AppLogger.debug('❌ 通知权限被拒绝');
        // 可以再次请求
        await Future.delayed(const Duration(seconds: 1));
        PermissionStatus retryStatus = await Permission.notification.request();
        if (retryStatus.isGranted) {
          AppLogger.debug('✅ 重试后通知权限已授予');
          return true;
        }
      } else if (status.isPermanentlyDenied) {
        AppLogger.debug('⚠️ 通知权限被永久拒绝，需要手动开启');
        await _showPermissionRationale(
            Permission.notification, '通知权限', '请在设置中开启通知权限以接收重要信息');
      }

      AppLogger.debug('📱 通知权限状态: $status');
      return status.isGranted;
    } catch (e) {
      AppLogger.error('请求通知权限时出错', e);
      return false;
    }
  }

  /// 请求存储权限 (Android 13+)
  static Future<bool> _requestStoragePermission() async {
    try {
      AppLogger.debug('💾 请求存储权限');

      // Android 13+ 需要分别请求媒体权限
      PermissionStatus status = await Permission.photos.request();

      if (status.isGranted) {
        AppLogger.debug('✅ 存储权限已授予');
        return true;
      } else if (status.isDenied) {
        AppLogger.debug('❌ 存储权限被拒绝');
      } else if (status.isPermanentlyDenied) {
        AppLogger.debug('⚠️ 存储权限被永久拒绝');
      }

      AppLogger.debug('💾 存储权限状态: $status');
      return status.isGranted;
    } catch (e) {
      AppLogger.error('请求存储权限时出错', e);
      return false;
    }
  }

  /// 请求相机权限
  static Future<bool> _requestCameraPermission() async {
    try {
      AppLogger.debug('📷 请求相机权限');

      PermissionStatus status = await Permission.camera.request();

      if (status.isGranted) {
        AppLogger.debug('✅ 相机权限已授予');
        return true;
      } else if (status.isDenied) {
        AppLogger.debug('❌ 相机权限被拒绝');
        // 可以再次请求
        await Future.delayed(const Duration(seconds: 1));
        PermissionStatus retryStatus = await Permission.camera.request();
        if (retryStatus.isGranted) {
          AppLogger.debug('✅ 重试后相机权限已授予');
          return true;
        }
      } else if (status.isPermanentlyDenied) {
        AppLogger.debug('⚠️ 相机权限被永久拒绝，需要手动开启');
        await _showPermissionRationale(
            Permission.camera, '相机权限', '请在设置中开启相机权限以拍摄照片和视频');
      }

      AppLogger.debug('📷 相机权限状态: $status');
      return status.isGranted;
    } catch (e) {
      AppLogger.error('请求相机权限时出错', e);
      return false;
    }
  }

  /// 请求麦克风权限
  static Future<bool> _requestMicrophonePermission() async {
    try {
      AppLogger.debug('🎤 请求麦克风权限');

      PermissionStatus status = await Permission.microphone.request();

      if (status.isGranted) {
        AppLogger.debug('✅ 麦克风权限已授予');
        return true;
      } else if (status.isDenied) {
        AppLogger.debug('❌ 麦克风权限被拒绝');
      } else if (status.isPermanentlyDenied) {
        AppLogger.debug('⚠️ 麦克风权限被永久拒绝');
      }

      AppLogger.debug('🎤 麦克风权限状态: $status');
      return status.isGranted;
    } catch (e) {
      AppLogger.error('请求麦克风权限时出错', e);
      return false;
    }
  }

  /// 请求位置权限
  static Future<bool> _requestLocationPermission() async {
    try {
      AppLogger.debug('📍 请求位置权限');

      // 先请求精确位置权限
      PermissionStatus status = await Permission.location.request();

      if (status.isGranted) {
        AppLogger.debug('✅ 位置权限已授予');
        return true;
      } else if (status.isDenied) {
        AppLogger.debug('❌ 位置权限被拒绝');
        // 尝试请求模糊位置权限
        PermissionStatus coarseStatus =
            await Permission.locationWhenInUse.request();
        if (coarseStatus.isGranted) {
          AppLogger.debug('✅ 模糊位置权限已授予');
          return true;
        }
      } else if (status.isPermanentlyDenied) {
        AppLogger.debug('⚠️ 位置权限被永久拒绝');
      }

      AppLogger.debug('📍 位置权限状态: $status');
      return status.isGranted;
    } catch (e) {
      AppLogger.error('请求位置权限时出错', e);
      return false;
    }
  }

  /// 请求系统悬浮窗权限
  static Future<bool> _requestSystemAlertWindowPermission() async {
    try {
      AppLogger.debug('🖼️ 请求系统悬浮窗权限');

      PermissionStatus status = await Permission.systemAlertWindow.request();

      if (status.isGranted) {
        AppLogger.debug('✅ 系统悬浮窗权限已授予');
        return true;
      } else if (status.isDenied) {
        AppLogger.debug('❌ 系统悬浮窗权限被拒绝');
      } else if (status.isPermanentlyDenied) {
        AppLogger.debug('⚠️ 系统悬浮窗权限被永久拒绝');
      }

      AppLogger.debug('🖼️ 系统悬浮窗权限状态: $status');
      return status.isGranted;
    } catch (e) {
      AppLogger.error('请求系统悬浮窗权限时出错', e);
      return false;
    }
  }

  /// 请求忽略电池优化权限
  static Future<bool> _requestBatteryOptimizationPermission() async {
    try {
      AppLogger.debug('🔋 请求忽略电池优化权限');

      PermissionStatus status =
          await Permission.ignoreBatteryOptimizations.request();

      if (status.isGranted) {
        AppLogger.debug('✅ 忽略电池优化权限已授予');
        return true;
      }

      AppLogger.debug('🔋 忽略电池优化权限状态: $status');
      return status.isGranted;
    } catch (e) {
      AppLogger.error('请求忽略电池优化权限时出错', e);
      return false;
    }
  }

  /// 检查所有关键权限的状态
  static Future<Map<String, bool>> checkAllPermissions() async {
    if (kIsWeb) return {};

    try {
      Map<String, bool> permissions = {};

      permissions['通知'] = await Permission.notification.isGranted;
      permissions['照片'] = await Permission.photos.isGranted;
      permissions['存储'] = await Permission.storage.isGranted;
      permissions['忽略电池优化'] =
          await Permission.ignoreBatteryOptimizations.isGranted;

      AppLogger.debug('📋 权限检查结果: $permissions');
      return permissions;
    } catch (e) {
      AppLogger.error('检查权限状态时出错', e);
      return {};
    }
  }

  /// 请求特定权限
  static Future<bool> requestSpecificPermission(Permission permission) async {
    try {
      AppLogger.debug('🔐 请求权限: ${permission.toString()}');

      PermissionStatus status = await permission.request();
      bool granted = status.isGranted;

      AppLogger.debug('🔐 权限 ${permission.toString()} 结果: $granted');
      return granted;
    } catch (e) {
      AppLogger.error('请求权限时出错', e);
      return false;
    }
  }

  /// 按需请求权限（智能权限请求）
  /// 根据功能模块和上下文智能决定是否需要请求权限
  static Future<bool> requestPermissionOnDemand({
    required Permission permission,
    required String featureModule,
    required String context,
    bool showRationale = true,
    String? customRationaleMessage,
  }) async {
    if (kIsWeb) {
      AppLogger.debug('Web平台跳过权限请求');
      return true; // Web平台通常不需要权限请求
    }

    try {
      AppLogger.debug(
          '🎯 按需请求权限: ${permission.toString()} (模块: $featureModule, 上下文: $context)');

      // 1. 检查权限是否已经授予
      if (await permission.isGranted) {
        AppLogger.debug('✅ 权限已授予: ${permission.toString()}');
        return true;
      }

      // 2. 检查权限是否被永久拒绝
      if (await permission.isPermanentlyDenied) {
        AppLogger.warn('⚠️ 权限被永久拒绝，需要手动开启: ${permission.toString()}');
        await _showPermanentlyDeniedDialog(permission, featureModule);
        return false;
      }

      // 3. 显示权限说明（如果需要）
      if (showRationale && await permission.isDenied) {
        bool shouldContinue = await _showPermissionRationale(
            permission, featureModule, customRationaleMessage);
        if (!shouldContinue) {
          AppLogger.debug('❌ 用户取消了权限请求: ${permission.toString()}');
          return false;
        }
      }

      // 4. 执行权限请求
      final startTime = DateTime.now();
      PermissionStatus status = await permission.request();
      final duration = DateTime.now().difference(startTime).inMilliseconds;

      // 5. 记录权限请求历史
      await PermissionHistoryManager.instance.recordPermissionRequest(
        permission: permission,
        status: status,
        featureModule: featureModule,
        context: context,
        isFirstRequest: await _isFirstRequest(permission),
        showedRationale: showRationale && await permission.isDenied,
        durationMs: duration,
      );

      // 6. 处理请求结果
      if (status.isGranted) {
        AppLogger.info('✅ 权限请求成功: ${permission.toString()}');
        return true;
      } else if (status.isPermanentlyDenied) {
        AppLogger.warn('⚠️ 权限被永久拒绝: ${permission.toString()}');
        await _showPermanentlyDeniedDialog(permission, featureModule);
        return false;
      } else {
        AppLogger.debug('❌ 权限请求被拒绝: ${permission.toString()}');
        return false;
      }
    } catch (e, stack) {
      AppLogger.error('❌ 按需权限请求失败: ${permission.toString()}', e, stack);
      return false;
    }
  }

  /// 检查是否是首次请求权限
  static Future<bool> _isFirstRequest(Permission permission) async {
    final history = await PermissionHistoryManager.instance
        .getLastPermissionRequest(permission);
    return history == null;
  }

  /// 显示权限说明对话框
  static Future<bool> _showPermissionRationale(Permission permission,
      String featureModule, String? customMessage) async {
    // 这里应该显示一个UI对话框
    // 由于这是工具类，我们返回true表示继续请求
    // 实际应用中应该通过回调或事件系统显示UI
    AppLogger.debug('📋 显示权限说明: ${permission.toString()}');
    return true;
  }

  /// 显示永久拒绝权限的对话框
  static Future<void> _showPermanentlyDeniedDialog(
      Permission permission, String featureModule) async {
    try {
      AppLogger.debug('📋 显示永久拒绝权限对话框: ${permission.toString()}');

      // 打开应用设置页面让用户手动开启权限
      bool opened = await openAppSettings();
      if (opened) {
        AppLogger.debug('✅ 已打开应用设置页面');
      } else {
        AppLogger.warn('❌ 无法打开应用设置页面');
      }
    } catch (e) {
      AppLogger.error('显示永久拒绝权限对话框失败', e);
    }
  }
}
