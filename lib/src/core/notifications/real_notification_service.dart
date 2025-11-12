import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import '../utils/logger.dart';
import 'notification_channel_manager.dart';
import '../permissions/android_13_notification_permission_manager.dart';
import 'windows_desktop_notification_service.dart';
import 'package:local_notifier/local_notifier.dart';
import 'simple_local_notification_service.dart';

/// 真实通知服务
///
/// 基于掘金文章的最佳实践实现：https://juejin.cn/post/7516784123693039626
/// 集成了通知渠道管理和Android 13+权限处理
class RealNotificationService {
  // 私有构造函数，确保单例模式
  RealNotificationService._();

  /// 单例实例
  static RealNotificationService? _instance;

  /// 获取单例实例
  static RealNotificationService get instance =>
      _instance ??= RealNotificationService._();

  bool _isInitialized = false;

  /// 初始化通知服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      AppLogger.info('🔔 初始化RealNotificationService');

      // 初始化通知渠道管理器
      await NotificationChannelManager.instance.initializeChannels();

      // 检查通知权限状态
      final permissionStatus = await Android13NotificationPermissionManager
          .instance
          .checkNotificationPermissionStatus();

      AppLogger.info('通知权限状态: $permissionStatus');

      _isInitialized = true;
      AppLogger.info('✅ RealNotificationService初始化完成');
    } catch (e) {
      AppLogger.error('❌ RealNotificationService初始化失败', e);
      rethrow;
    }
  }

  /// 发送测试通知
  Future<void> sendTestNotification() async {
    try {
      // 在Windows平台上使用简化本地通知服务
      if (Platform.isWindows) {
        AppLogger.info('🪟 Windows平台：使用简化本地通知服务');

        // 发送简化本地通知
        await SimpleLocalNotificationService.instance.sendTestNotification();

        AppLogger.info('✅ Windows测试通知发送成功');
        return;
      }

      // 非Windows平台：确保服务已初始化
      await initialize();

      // 使用Android 13+权限管理器检查权限
      final permissionResult = await Android13NotificationPermissionManager
          .instance
          .requestNotificationPermission();

      if (!permissionResult.isGranted) {
        AppLogger.warn('❌ 通知权限未授予，无法发送通知: ${permissionResult.message}');
        return;
      }

      AppLogger.info('📱 发送测试通知...');

      // 获取通知渠道ID
      final channelId = NotificationChannelManager.instance
          .getChannelIdForNotificationType(NotificationType.systemNotification);

      // 构建测试通知数据
      final notificationData = NotificationData(
        id: _generateNotificationId(),
        channelId: channelId,
        title: '🧪 测试通知',
        body: '这是一条来自基速基金分析的测试通知',
        data: {
          'type': 'test_notification',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      // 发送通知
      await _sendNotification(notificationData);

      AppLogger.info('✅ 测试通知发送成功');
    } catch (e) {
      AppLogger.error('❌ 发送测试通知失败', e);
    }
  }

  /// 发送基金价格提醒通知
  static Future<void> sendFundPriceAlert({
    required String fundCode,
    required String fundName,
    required double currentPrice,
    required double priceChange,
    required double changePercent,
  }) async {
    try {
      // 在Windows平台上使用简化本地通知服务
      if (Platform.isWindows) {
        AppLogger.info('🪟 Windows平台：使用简化本地通知服务');

        // 发送简化本地通知
        await SimpleLocalNotificationService.instance.sendFundPriceAlert(
          fundCode: fundCode,
          fundName: fundName,
          currentPrice: currentPrice,
          priceChange: priceChange,
          changePercent: changePercent,
        );

        AppLogger.info('✅ Windows基金价格提醒通知发送成功');
        return;
      }

      // 非Windows平台：检查通知权限
      final PermissionStatus status = await Permission.notification.status;
      if (!status.isGranted) {
        AppLogger.warn('❌ 通知权限未授予，无法发送基金价格提醒');
        return;
      }

      final String changeEmoji = priceChange >= 0 ? '📈' : '📉';
      final String changeText = priceChange >= 0 ? '上涨' : '下跌';

      final String title = '$changeEmoji $fundName 价格提醒';
      final String body = '当前价格: ¥${currentPrice.toStringAsFixed(4)}\n'
          '变化: ¥${priceChange.abs().toStringAsFixed(4)} ($changeText ${changePercent.abs().toStringAsFixed(2)}%)';

      AppLogger.info('📱 发送基金价格提醒通知...');
      AppLogger.info('📋 标题: $title');
      AppLogger.info('📋 内容: $body');
      AppLogger.info('📋 基金代码: $fundCode');

      // 模拟通知发送
      _simulateNotification(
        title: title,
        body: body,
        payload: {
          'type': 'fund_price_alert',
          'fundCode': fundCode,
          'fundName': fundName,
          'currentPrice': currentPrice,
          'priceChange': priceChange,
          'changePercent': changePercent,
        },
      );

      AppLogger.info('✅ 基金价格提醒通知发送成功');
    } catch (e) {
      AppLogger.error('❌ 发送基金价格提醒失败', e);
    }
  }

  /// 发送基金买入/卖出信号通知
  static Future<void> sendTradeSignal({
    required String fundCode,
    required String fundName,
    required String signalType, // 'buy' 或 'sell'
    required String reason,
    required double targetPrice,
    required double currentPrice,
  }) async {
    try {
      // 在Windows平台上使用简化本地通知服务
      if (Platform.isWindows) {
        AppLogger.info('🪟 Windows平台：使用简化本地通知服务');

        // 发送简化本地通知
        await SimpleLocalNotificationService.instance.sendTradeSignal(
          fundCode: fundCode,
          fundName: fundName,
          signalType: signalType,
          reason: reason,
          targetPrice: targetPrice,
          currentPrice: currentPrice,
        );

        AppLogger.info('✅ Windows交易信号通知发送成功');
        return;
      }

      // 非Windows平台：检查通知权限
      final PermissionStatus status = await Permission.notification.status;
      if (!status.isGranted) {
        AppLogger.warn('❌ 通知权限未授予，无法发送交易信号通知');
        return;
      }

      final String emoji = signalType == 'buy' ? '🟢' : '🔴';
      final String action = signalType == 'buy' ? '买入' : '卖出';

      final String title = '$emoji $fundName $action信号';
      final String body = '信号类型: $action\n'
          '当前价格: ¥${currentPrice.toStringAsFixed(4)}\n'
          '目标价格: ¥${targetPrice.toStringAsFixed(4)}\n'
          '触发原因: $reason';

      AppLogger.info('📱 发送交易信号通知...');
      AppLogger.info('📋 标题: $title');
      AppLogger.info('📋 内容: $body');

      // 模拟通知发送
      _simulateNotification(
        title: title,
        body: body,
        payload: {
          'type': 'trade_signal',
          'fundCode': fundCode,
          'fundName': fundName,
          'signalType': signalType,
          'reason': reason,
          'targetPrice': targetPrice,
          'currentPrice': currentPrice,
        },
      );

      AppLogger.info('✅ 交易信号通知发送成功');
    } catch (e) {
      AppLogger.error('❌ 发送交易信号通知失败', e);
    }
  }

  /// 发送投资组合建议通知
  static Future<void> sendPortfolioSuggestion({
    required String suggestionType,
    required String description,
    required List<String> recommendedFunds,
  }) async {
    try {
      // 在Windows平台上使用简化本地通知服务
      if (Platform.isWindows) {
        AppLogger.info('🪟 Windows平台：使用简化本地通知服务');

        // 发送简化本地通知
        await SimpleLocalNotificationService.instance.sendPortfolioSuggestion(
          suggestionType: suggestionType,
          description: description,
          recommendedFunds: recommendedFunds,
        );

        AppLogger.info('✅ Windows投资组合建议通知发送成功');
        return;
      }

      // 非Windows平台：检查通知权限
      final PermissionStatus status = await Permission.notification.status;
      if (!status.isGranted) {
        AppLogger.warn('❌ 通知权限未授予，无法发送投资组合建议');
        return;
      }

      const String title = '💡 投资组合建议';
      final String body = '建议类型: $suggestionType\n'
          '描述: $description\n'
          '推荐基金: ${recommendedFunds.join(', ')}';

      AppLogger.info('📱 发送投资组合建议通知...');
      AppLogger.info('📋 标题: $title');
      AppLogger.info('📋 内容: $body');

      // 模拟通知发送
      _simulateNotification(
        title: title,
        body: body,
        payload: {
          'type': 'portfolio_suggestion',
          'suggestionType': suggestionType,
          'description': description,
          'recommendedFunds': recommendedFunds,
        },
      );

      AppLogger.info('✅ 投资组合建议通知发送成功');
    } catch (e) {
      AppLogger.error('❌ 发送投资组合建议失败', e);
    }
  }

  /// 模拟通知发送（用于测试）
  static void _simulateNotification({
    final String title = '测试通知',
    final String body = '这是一个测试通知内容',
    Map<String, dynamic>? payload,
  }) {
    // 在实际应用中，这里会使用 flutter_local_notifications 插件发送真实通知
    // 现在我们只是记录通知信息到日志中

    AppLogger.info('🔔 ========== 通知详情 ==========');
    AppLogger.info('📰 标题: $title');
    AppLogger.info('📝 内容: $body');
    if (payload != null) {
      AppLogger.info('📦 数据: $payload');
    }
    AppLogger.info('⏰ 时间: ${DateTime.now().toString().substring(0, 19)}');
    AppLogger.info('🔔 ===============================');

    // 在真实环境中，这里会调用 Flutter Local Notifications
    // 例如：
    // await flutterLocalNotifications.show(
    //   id: notificationId++,
    //   title: title,
    //   body: body,
    //   payload: jsonEncode(payload),
    // );
  }

  /// 获取通知权限状态
  Future<bool> isNotificationEnabled() async {
    try {
      final status = await Android13NotificationPermissionManager.instance
          .checkNotificationPermissionStatus();
      return status == NotificationPermissionStatus.granted;
    } catch (e) {
      AppLogger.error('检查通知权限状态失败', e);
      return false;
    }
  }

  /// 打印通知设置信息
  static Future<void> printNotificationSettings() async {
    try {
      final PermissionStatus status = await Permission.notification.status;
      final bool isGranted = status.isGranted;
      final bool isDenied = status.isDenied;
      final bool isPermanentlyDenied = status.isPermanentlyDenied;
      final bool isLimited = status.isLimited;
      final bool isRestricted = status.isRestricted;

      AppLogger.info('🔔 通知设置详情:');
      AppLogger.info('   - 状态: $status');
      AppLogger.info('   - 已授权: $isGranted');
      AppLogger.info('   - 被拒绝: $isDenied');
      AppLogger.info('   - 永久拒绝: $isPermanentlyDenied');
      AppLogger.info('   - 限制使用: $isLimited');
      AppLogger.info('   - 系统限制: $isRestricted');

      if (!isGranted) {
        AppLogger.warn('⚠️ 通知权限未授权，请在设置中开启通知权限');
      }
    } catch (e) {
      AppLogger.error('获取通知设置失败', e);
    }
  }

  /// 生成通知ID
  int _generateNotificationId() {
    return DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }

  /// 发送通知的统一方法
  Future<void> _sendNotification(NotificationData notificationData) async {
    try {
      AppLogger.debug('发送通知: ${notificationData.title}');

      // 在实际应用中，这里会使用 flutter_local_notifications 插件
      // 现在我们用日志模拟通知发送

      _simulateNotificationWithChannel(
        title: notificationData.title,
        body: notificationData.body,
        channelId: notificationData.channelId,
        payload: notificationData.data,
      );

      AppLogger.debug('通知发送完成: ${notificationData.id}');
    } catch (e) {
      AppLogger.error('发送通知失败', e);
      rethrow;
    }
  }

  /// 模拟通知发送（带渠道信息）
  void _simulateNotificationWithChannel({
    required String title,
    required String body,
    required String channelId,
    Map<String, dynamic>? payload,
  }) {
    AppLogger.info('🔔 ========== 通知详情 ==========');
    AppLogger.info('📰 标题: $title');
    AppLogger.info('📝 内容: $body');
    AppLogger.info('📂 渠道ID: $channelId');
    if (payload != null) {
      AppLogger.info('📦 数据: $payload');
    }
    AppLogger.info('⏰ 时间: ${DateTime.now().toString().substring(0, 19)}');
    AppLogger.info('🔔 ===============================');

    // 在真实环境中，这里会调用 Flutter Local Notifications
    /*
    await flutterLocalNotificationsPlugin.show(
      id: notificationId,
      title: title,
      body: body,
      payload: jsonEncode(payload),
      androidDetails: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: importance,
        priority: priority,
        icon: '@mipmap/ic_launcher',
      ),
    );
    */
  }
}

/// 通知数据模型
class NotificationData {
  final int id;
  final String channelId;
  final String title;
  final String body;
  final Map<String, dynamic>? data;

  NotificationData({
    required this.id,
    required this.channelId,
    required this.title,
    required this.body,
    this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'channelId': channelId,
      'title': title,
      'body': body,
      'data': data,
    };
  }

  @override
  String toString() {
    return 'NotificationData(id: $id, channelId: $channelId, title: $title)';
  }
}
