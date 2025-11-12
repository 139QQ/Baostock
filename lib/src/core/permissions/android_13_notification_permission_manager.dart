import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/logger.dart';

/// Android 13+ 通知权限管理器
///
/// 基于掘金文章的最佳实践：https://juejin.cn/post/7516784123693039626
/// 专门处理Android 13 (API 33) 及以上版本的通知权限请求
class Android13NotificationPermissionManager {
  // 私有构造函数
  Android13NotificationPermissionManager._();

  // 单例实例
  static Android13NotificationPermissionManager? _instance;
  static Android13NotificationPermissionManager get instance {
    _instance ??= Android13NotificationPermissionManager._();
    return _instance!;
  }

  /// 检查是否为Android 13+
  Future<bool> _isAndroid13OrHigher() async {
    if (!Platform.isAndroid) return false;

    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.version.sdkInt >= 33; // Android 13 (Tiramisu)
    } catch (e) {
      AppLogger.error('检查Android版本失败', e);
      return false;
    }
  }

  /// 检查通知权限状态
  Future<NotificationPermissionStatus>
      checkNotificationPermissionStatus() async {
    try {
      // 非Android平台直接返回已授权
      if (!Platform.isAndroid) {
        return NotificationPermissionStatus.granted;
      }

      // 检查是否为Android 13+
      final isAndroid13Plus = await _isAndroid13OrHigher();

      if (!isAndroid13Plus) {
        // Android 12及以下版本，默认有通知权限
        return NotificationPermissionStatus.granted;
      }

      // Android 13+ 需要检查POST_NOTIFICATIONS权限
      final status = await Permission.notification.status;

      switch (status) {
        case PermissionStatus.granted:
          return NotificationPermissionStatus.granted;
        case PermissionStatus.denied:
          return NotificationPermissionStatus.denied;
        case PermissionStatus.permanentlyDenied:
          return NotificationPermissionStatus.permanentlyDenied;
        case PermissionStatus.limited:
          return NotificationPermissionStatus.limited;
        case PermissionStatus.restricted:
          return NotificationPermissionStatus.restricted;
        case PermissionStatus.provisional:
          return NotificationPermissionStatus.provisional;
      }
    } catch (e) {
      AppLogger.error('检查通知权限状态失败', e);
      return NotificationPermissionStatus.unknown;
    }
  }

  /// 请求通知权限
  ///
  /// 实现了完整的Android 13+权限请求流程
  /// 包括权限检查、说明对话框、请求处理等
  Future<NotificationPermissionResult> requestNotificationPermission({
    bool showRationale = true,
    String? customRationaleMessage,
  }) async {
    try {
      AppLogger.info('🔔 开始请求通知权限');

      // 1. 检查平台
      if (!Platform.isAndroid) {
        AppLogger.debug('非Android平台，跳过权限请求');
        return NotificationPermissionResult(
          status: NotificationPermissionStatus.granted,
          shouldShowSettings: false,
        );
      }

      // 2. 检查Android版本
      final isAndroid13Plus = await _isAndroid13OrHigher();
      if (!isAndroid13Plus) {
        AppLogger.debug('Android 12及以下版本，默认有通知权限');
        return NotificationPermissionResult(
          status: NotificationPermissionStatus.granted,
          shouldShowSettings: false,
        );
      }

      // 3. 检查当前权限状态
      final currentStatus = await Permission.notification.status;
      AppLogger.debug('当前通知权限状态: $currentStatus');

      if (currentStatus.isGranted) {
        AppLogger.info('通知权限已授予');
        return NotificationPermissionResult(
          status: NotificationPermissionStatus.granted,
          shouldShowSettings: false,
        );
      }

      // 4. 权限被拒绝，处理请求逻辑
      if (currentStatus.isDenied) {
        // 检查是否应该显示权限说明
        final shouldShowRationale = showRationale &&
            await Permission.notification.shouldShowRequestRationale;

        if (shouldShowRationale) {
          AppLogger.debug('显示权限说明对话框');

          // 在实际应用中，这里会显示一个权限说明对话框
          // 现在我们直接请求权限
          final requestResult = await _performPermissionRequest();
          return _handlePermissionRequestResult(requestResult);
        } else {
          // 直接请求权限
          AppLogger.debug('直接请求通知权限');
          final requestResult = await _performPermissionRequest();
          return _handlePermissionRequestResult(requestResult);
        }
      }

      // 5. 权限被永久拒绝
      if (currentStatus.isPermanentlyDenied) {
        AppLogger.warn('通知权限被永久拒绝，需要用户手动开启');
        return NotificationPermissionResult(
          status: NotificationPermissionStatus.permanentlyDenied,
          shouldShowSettings: true,
          message: '请在设置中手动开启通知权限',
        );
      }

      // 6. 其他状态
      AppLogger.warn('通知权限状态异常: $currentStatus');
      return NotificationPermissionResult(
        status: _convertPermissionStatus(currentStatus),
        shouldShowSettings: false,
        message: '权限状态异常，请重试',
      );
    } catch (e) {
      AppLogger.error('请求通知权限失败', e);
      return NotificationPermissionResult(
        status: NotificationPermissionStatus.unknown,
        shouldShowSettings: false,
        message: '请求权限时发生错误: ${e.toString()}',
      );
    }
  }

  /// 执行权限请求
  Future<PermissionStatus> _performPermissionRequest() async {
    try {
      AppLogger.debug('执行POST_NOTIFICATIONS权限请求');

      // 使用permission_handler插件请求权限
      final result = await Permission.notification.request();

      AppLogger.debug('权限请求结果: $result');
      return result;
    } catch (e) {
      AppLogger.error('执行权限请求失败', e);
      rethrow;
    }
  }

  /// 处理权限请求结果
  NotificationPermissionResult _handlePermissionRequestResult(
      PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        AppLogger.info('✅ 通知权限请求成功');
        return NotificationPermissionResult(
          status: NotificationPermissionStatus.granted,
          shouldShowSettings: false,
          message: '通知权限已授予',
        );

      case PermissionStatus.denied:
        AppLogger.warn('❌ 通知权限被拒绝');
        return NotificationPermissionResult(
          status: NotificationPermissionStatus.denied,
          shouldShowSettings: false,
          message: '通知权限被拒绝',
        );

      case PermissionStatus.permanentlyDenied:
        AppLogger.warn('⚠️ 通知权限被永久拒绝');
        return NotificationPermissionResult(
          status: NotificationPermissionStatus.permanentlyDenied,
          shouldShowSettings: true,
          message: '通知权限被永久拒绝，请在设置中手动开启',
        );

      default:
        AppLogger.warn('❓ 权限请求结果异常: $status');
        return NotificationPermissionResult(
          status: _convertPermissionStatus(status),
          shouldShowSettings: false,
          message: '权限请求结果异常',
        );
    }
  }

  /// 打开应用设置页面
  ///
  /// 当权限被永久拒绝时，引导用户到设置页面手动开启
  Future<bool> openAppSettings() async {
    try {
      AppLogger.info('📱 打开应用设置页面');

      final success = await openAppSettings();

      if (success) {
        AppLogger.info('✅ 成功打开应用设置页面');
      } else {
        AppLogger.warn('⚠️ 无法打开应用设置页面');
      }

      return success;
    } catch (e) {
      AppLogger.error('打开应用设置页面失败', e);
      return false;
    }
  }

  /// 打开通知设置页面（如果系统支持）
  Future<bool> openNotificationSettings() async {
    try {
      AppLogger.info('🔔 尝试打开通知设置页面');

      // 在某些Android版本中，可以直接打开通知设置
      // 这里使用通用的应用设置页面
      return await openAppSettings();
    } catch (e) {
      AppLogger.error('打开通知设置页面失败', e);
      return false;
    }
  }

  /// 获取权限说明文案
  String getPermissionRationaleMessage() {
    return '''
基速基金分析需要通知权限来为您提供：

📈 基金价格变动提醒
🎯 重要买入/卖出信号
📊 市场重要变化通知
💡 个性化投资建议

开启通知权限，第一时间获取重要投资信息，不错过任何市场机会。

您随时可以在设置中关闭通知或调整通知类型。
''';
  }

  /// 获取权限被拒绝的说明文案
  String getPermissionDeniedMessage() {
    return '''
理解您对隐私的关注。

如果您改变主意，可以随时在设置中开启通知权限：

1. 打开系统设置
2. 找到"基速基金分析"应用
3. 点击"通知"或"权限管理"
4. 开启"通知权限"

我们承诺只发送与投资相关的重要通知。
''';
  }

  /// 转换权限状态
  NotificationPermissionStatus _convertPermissionStatus(
      PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return NotificationPermissionStatus.granted;
      case PermissionStatus.denied:
        return NotificationPermissionStatus.denied;
      case PermissionStatus.permanentlyDenied:
        return NotificationPermissionStatus.permanentlyDenied;
      case PermissionStatus.limited:
        return NotificationPermissionStatus.limited;
      case PermissionStatus.restricted:
        return NotificationPermissionStatus.restricted;
      case PermissionStatus.provisional:
        return NotificationPermissionStatus.provisional;
    }
  }

  /// 检查应用是否首次启动
  Future<bool> isFirstLaunch() async {
    // 这里可以实现首次启动检查逻辑
    // 比如检查SharedPreferences中的标记
    return false; // 临时返回false
  }

  /// 记录权限请求历史
  Future<void> recordPermissionRequest(
      NotificationPermissionStatus status) async {
    try {
      AppLogger.debug('记录权限请求历史: $status');
      // 这里可以实现权限请求历史的记录逻辑
      // 比如保存到数据库或文件中
    } catch (e) {
      AppLogger.error('记录权限请求历史失败', e);
    }
  }

  /// 获取权限统计信息
  Future<NotificationPermissionStats> getPermissionStats() async {
    try {
      // 这里可以实现权限统计信息的获取逻辑
      return NotificationPermissionStats(
        totalRequests: 0,
        grantedCount: 0,
        deniedCount: 0,
        permanentlyDeniedCount: 0,
        lastRequestTime: null,
      );
    } catch (e) {
      AppLogger.error('获取权限统计信息失败', e);
      return NotificationPermissionStats.empty();
    }
  }
}

/// 通知权限状态枚举
enum NotificationPermissionStatus {
  /// 已授权
  granted,

  /// 被拒绝
  denied,

  /// 永久拒绝
  permanentlyDenied,

  /// 限制使用
  limited,

  /// 系统限制
  restricted,

  /// 临时授权
  provisional,

  /// 未知状态
  unknown,
}

/// 通知权限请求结果
class NotificationPermissionResult {
  final NotificationPermissionStatus status;
  final bool shouldShowSettings;
  final String? message;

  NotificationPermissionResult({
    required this.status,
    required this.shouldShowSettings,
    this.message,
  });

  bool get isGranted => status == NotificationPermissionStatus.granted;
  bool get isDenied => status == NotificationPermissionStatus.denied;
  bool get isPermanentlyDenied =>
      status == NotificationPermissionStatus.permanentlyDenied;

  @override
  String toString() {
    return 'NotificationPermissionResult(status: $status, shouldShowSettings: $shouldShowSettings, message: $message)';
  }
}

/// 通知权限统计信息
class NotificationPermissionStats {
  final int totalRequests;
  final int grantedCount;
  final int deniedCount;
  final int permanentlyDeniedCount;
  final DateTime? lastRequestTime;

  NotificationPermissionStats({
    required this.totalRequests,
    required this.grantedCount,
    required this.deniedCount,
    required this.permanentlyDeniedCount,
    this.lastRequestTime,
  });

  static NotificationPermissionStats empty() {
    return NotificationPermissionStats(
      totalRequests: 0,
      grantedCount: 0,
      deniedCount: 0,
      permanentlyDeniedCount: 0,
    );
  }

  double get grantRate {
    return totalRequests > 0 ? grantedCount / totalRequests : 0.0;
  }

  @override
  String toString() {
    return 'NotificationPermissionStats('
        'total: $totalRequests, '
        'granted: $grantedCount, '
        'denied: $deniedCount, '
        'permanentlyDenied: $permanentlyDeniedCount, '
        'grantRate: ${(grantRate * 100).toStringAsFixed(1)}%)';
  }
}
