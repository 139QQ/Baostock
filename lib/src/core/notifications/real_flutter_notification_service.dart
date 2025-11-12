import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:device_info_plus/device_info_plus.dart';

import '../utils/logger.dart';
import 'notification_channel_manager.dart';
import '../permissions/android_13_notification_permission_manager.dart';

/// 后台通知响应处理器（必须是顶级函数或静态函数）
@pragma('vm:entry-point')
void backgroundNotificationResponseHandler(NotificationResponse response) {
  try {
    AppLogger.info('后台通知被点击: ${response.payload}');

    // 解析payload数据
    if (response.payload != null) {
      final payload = jsonDecode(response.payload!);
      _handleBackgroundNotificationAction(payload);
    }
  } catch (e) {
    AppLogger.error('处理后台通知点击失败', e);
  }
}

/// 处理后台通知操作（静态函数）
void _handleBackgroundNotificationAction(Map<String, dynamic> payload) {
  try {
    final type = payload['type'] as String?;

    switch (type) {
      case 'fund_price_alert':
        AppLogger.info('后台处理基金价格提醒: ${payload['fundCode']}');
        break;
      case 'trade_signal':
        AppLogger.info(
            '后台处理交易信号: ${payload['fundCode']}, ${payload['signalType']}');
        break;
      case 'portfolio_suggestion':
        AppLogger.info('后台处理投资组合建议: ${payload['suggestionType']}');
        break;
      case 'test_notification':
        AppLogger.info('后台处理测试通知');
        break;
      default:
        AppLogger.debug('后台未知通知类型: $type');
    }
  } catch (e) {
    AppLogger.error('后台处理通知操作失败', e);
  }
}

/// 真实的Flutter通知服务
///
/// 基于掘金文章的最佳实践实现：https://juejin.cn/post/7516784123693039626
/// 使用flutter_local_notifications插件实现真实的通知发送
class RealFlutterNotificationService {
  // 私有构造函数，确保单例模式
  RealFlutterNotificationService._();

  /// 单例实例
  static RealFlutterNotificationService? _instance;
  static RealFlutterNotificationService get instance {
    _instance ??= RealFlutterNotificationService._();
    return _instance!;
  }

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// 初始化通知服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      AppLogger.info('🔔 初始化RealFlutterNotificationService');

      // 初始化时区
      tz.initializeTimeZones();

      // 初始化Android设置
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // 初始化iOS设置
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // 初始化设置
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      // 初始化插件
      await _flutterLocalNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
        onDidReceiveBackgroundNotificationResponse:
            backgroundNotificationResponseHandler,
      );

      // 初始化通知渠道
      await _initializeNotificationChannels();

      _isInitialized = true;
      AppLogger.info('✅ RealFlutterNotificationService初始化完成');
    } catch (e) {
      AppLogger.error('❌ RealFlutterNotificationService初始化失败', e);
      rethrow;
    }
  }

  /// 初始化通知渠道
  Future<void> _initializeNotificationChannels() async {
    try {
      AppLogger.debug('初始化通知渠道...');

      final channelManager = NotificationChannelManager.instance;
      final allChannels = channelManager.getAllChannels();

      for (final channelInfo in allChannels) {
        await _createNotificationChannel(channelInfo);
      }

      AppLogger.debug('✅ 所有通知渠道初始化完成');
    } catch (e) {
      AppLogger.error('初始化通知渠道失败', e);
    }
  }

  /// 创建单个通知渠道
  Future<void> _createNotificationChannel(
      NotificationChannelInfo channelInfo) async {
    try {
      if (!Platform.isAndroid) return;

      final androidChannel = AndroidNotificationChannel(
        channelInfo.channelId,
        channelInfo.channelName,
        description: channelInfo.description,
        importance: _convertImportance(channelInfo.importance),
        enableVibration: channelInfo.enableVibration,
        enableLights: channelInfo.enableLights,
        sound: channelInfo.soundPath != null
            ? RawResourceAndroidNotificationSound(channelInfo.soundPath!)
            : null,
      );

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      AppLogger.debug('创建通知渠道: ${channelInfo.channelName}');
    } catch (e) {
      AppLogger.error('创建通知渠道失败: ${channelInfo.channelId}', e);
    }
  }

  /// 转换重要性等级
  Importance _convertImportance(NotificationImportance importance) {
    switch (importance) {
      case NotificationImportance.high:
        return Importance.high;
      case NotificationImportance.medium:
        return Importance.defaultImportance;
      case NotificationImportance.low:
        return Importance.low;
      case NotificationImportance.min:
        return Importance.min;
    }
  }

  /// 通知点击回调
  void _onNotificationTapped(NotificationResponse response) {
    try {
      AppLogger.info('通知被点击: ${response.payload}');

      // 解析payload数据
      if (response.payload != null) {
        final payload = jsonDecode(response.payload!);
        _handleNotificationAction(payload);
      }
    } catch (e) {
      AppLogger.error('处理通知点击失败', e);
    }
  }

  /// 处理通知操作
  void _handleNotificationAction(Map<String, dynamic> payload) {
    try {
      final type = payload['type'] as String?;

      switch (type) {
        case 'fund_price_alert':
          _handleFundPriceAlert(payload);
          break;
        case 'trade_signal':
          _handleTradeSignal(payload);
          break;
        case 'portfolio_suggestion':
          _handlePortfolioSuggestion(payload);
          break;
        case 'test_notification':
          _handleTestNotification(payload);
          break;
        default:
          AppLogger.debug('未知通知类型: $type');
      }
    } catch (e) {
      AppLogger.error('处理通知操作失败', e);
    }
  }

  /// 处理基金价格提醒
  void _handleFundPriceAlert(Map<String, dynamic> payload) {
    final fundCode = payload['fundCode'] as String?;
    AppLogger.info('处理基金价格提醒: $fundCode');
    // 这里可以导航到基金详情页面
  }

  /// 处理交易信号
  void _handleTradeSignal(Map<String, dynamic> payload) {
    final fundCode = payload['fundCode'] as String?;
    final signalType = payload['signalType'] as String?;
    AppLogger.info('处理交易信号: $fundCode, $signalType');
    // 这里可以导航到交易信号页面
  }

  /// 处理投资组合建议
  void _handlePortfolioSuggestion(Map<String, dynamic> payload) {
    final suggestionType = payload['suggestionType'] as String?;
    AppLogger.info('处理投资组合建议: $suggestionType');
    // 这里可以导航到投资组合页面
  }

  /// 处理测试通知
  void _handleTestNotification(Map<String, dynamic> payload) {
    AppLogger.info('处理测试通知');
    // 测试通知不需要特殊处理
  }

  /// 发送测试通知
  Future<void> sendTestNotification() async {
    try {
      await initialize();

      // 检查权限
      final permissionResult = await Android13NotificationPermissionManager
          .instance
          .requestNotificationPermission();

      if (!permissionResult.isGranted) {
        AppLogger.warn('❌ 通知权限未授予，无法发送通知');
        return;
      }

      // 获取通知渠道ID
      final channelId = NotificationChannelManager.instance
          .getChannelIdForNotificationType(NotificationType.systemNotification);

      // 构建通知详情
      const androidDetails = AndroidNotificationDetails(
        NotificationChannelManager.CHANNEL_ID_SYSTEM_NOTIFICATIONS,
        NotificationChannelManager.CHANNEL_NAME_SYSTEM_NOTIFICATIONS,
        channelDescription: '应用更新、系统维护、重要通知等',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: DefaultStyleInformation(true, true),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // 发送通知
      await _flutterLocalNotificationsPlugin.show(
        _generateNotificationId(),
        '🧪 测试通知',
        '这是一条来自基速基金分析的真实测试通知',
        platformDetails,
        payload: jsonEncode({
          'type': 'test_notification',
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      AppLogger.info('✅ 测试通知发送成功');
    } catch (e) {
      AppLogger.error('❌ 发送测试通知失败', e);
    }
  }

  /// 发送基金价格提醒通知
  Future<void> sendFundPriceAlert({
    required String fundCode,
    required String fundName,
    required double currentPrice,
    required double priceChange,
    required double changePercent,
  }) async {
    try {
      await initialize();

      // 检查权限
      final permissionResult = await Android13NotificationPermissionManager
          .instance
          .requestNotificationPermission();

      if (!permissionResult.isGranted) {
        AppLogger.warn('❌ 通知权限未授予，无法发送基金价格提醒');
        return;
      }

      final String changeEmoji = priceChange >= 0 ? '📈' : '📉';
      final String changeText = priceChange >= 0 ? '上涨' : '下跌';
      final Color changeColor = priceChange >= 0 ? Colors.green : Colors.red;

      final String title = '$changeEmoji $fundName 价格提醒';
      final String body = '当前价格: ¥${currentPrice.toStringAsFixed(4)}\n'
          '变化: ¥${priceChange.abs().toStringAsFixed(4)} ($changeText ${changePercent.abs().toStringAsFixed(2)}%)';

      // 获取通知渠道ID
      final channelId = NotificationChannelManager.instance
          .getChannelIdForNotificationType(NotificationType.fundAlert);

      // 构建通知详情
      final androidDetails = AndroidNotificationDetails(
        channelId,
        NotificationChannelManager.CHANNEL_NAME_FUND_ALERTS,
        channelDescription: '基金净值变化、价格异动等重要投资提醒',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: changeColor,
        enableVibration: true,
        enableLights: true,
        styleInformation: BigTextStyleInformation(
          body,
          htmlFormatBigText: true,
          contentTitle: title,
        ),
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        subtitle: '基金代码: $fundCode',
      );

      final platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // 发送通知
      await _flutterLocalNotificationsPlugin.show(
        _generateNotificationId(),
        title,
        body,
        platformDetails,
        payload: jsonEncode({
          'type': 'fund_price_alert',
          'fundCode': fundCode,
          'fundName': fundName,
          'currentPrice': currentPrice,
          'priceChange': priceChange,
          'changePercent': changePercent,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      AppLogger.info('✅ 基金价格提醒通知发送成功: $fundName');
    } catch (e) {
      AppLogger.error('❌ 发送基金价格提醒失败', e);
    }
  }

  /// 发送交易信号通知
  Future<void> sendTradeSignal({
    required String fundCode,
    required String fundName,
    required String signalType, // 'buy' 或 'sell'
    required String reason,
    required double targetPrice,
    required double currentPrice,
  }) async {
    try {
      await initialize();

      // 检查权限
      final permissionResult = await Android13NotificationPermissionManager
          .instance
          .requestNotificationPermission();

      if (!permissionResult.isGranted) {
        AppLogger.warn('❌ 通知权限未授予，无法发送交易信号通知');
        return;
      }

      final String emoji = signalType == 'buy' ? '🟢' : '🔴';
      final String action = signalType == 'buy' ? '买入' : '卖出';
      final Color signalColor = signalType == 'buy' ? Colors.green : Colors.red;

      final String title = '$emoji $fundName $action信号';
      final String body = '信号类型: $action\n'
          '当前价格: ¥${currentPrice.toStringAsFixed(4)}\n'
          '目标价格: ¥${targetPrice.toStringAsFixed(4)}\n'
          '触发原因: $reason';

      // 获取通知渠道ID
      final channelId = NotificationChannelManager.instance
          .getChannelIdForNotificationType(NotificationType.tradeSignal);

      // 构建通知详情
      final androidDetails = AndroidNotificationDetails(
        channelId,
        NotificationChannelManager.CHANNEL_NAME_TRADE_SIGNALS,
        channelDescription: '买入/卖出信号、操作建议等重要交易提醒',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: signalColor,
        enableVibration: true,
        enableLights: true,
        styleInformation: BigTextStyleInformation(
          body,
          htmlFormatBigText: true,
          contentTitle: title,
        ),
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        subtitle: '基金代码: $fundCode',
      );

      final platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // 发送通知
      await _flutterLocalNotificationsPlugin.show(
        _generateNotificationId(),
        title,
        body,
        platformDetails,
        payload: jsonEncode({
          'type': 'trade_signal',
          'fundCode': fundCode,
          'fundName': fundName,
          'signalType': signalType,
          'reason': reason,
          'targetPrice': targetPrice,
          'currentPrice': currentPrice,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      AppLogger.info('✅ 交易信号通知发送成功: $fundName - $action');
    } catch (e) {
      AppLogger.error('❌ 发送交易信号通知失败', e);
    }
  }

  /// 发送投资组合建议通知
  Future<void> sendPortfolioSuggestion({
    required String suggestionType,
    required String description,
    required List<String> recommendedFunds,
  }) async {
    try {
      await initialize();

      // 检查权限
      final permissionResult = await Android13NotificationPermissionManager
          .instance
          .requestNotificationPermission();

      if (!permissionResult.isGranted) {
        AppLogger.warn('❌ 通知权限未授予，无法发送投资组合建议');
        return;
      }

      const String title = '💡 投资组合建议';
      final String body = '建议类型: $suggestionType\n'
          '描述: $description\n'
          '推荐基金: ${recommendedFunds.join(', ')}';

      // 获取通知渠道ID
      final channelId = NotificationChannelManager.instance
          .getChannelIdForNotificationType(NotificationType.portfolioUpdate);

      // 构建通知详情
      final androidDetails = AndroidNotificationDetails(
        channelId,
        NotificationChannelManager.CHANNEL_NAME_PORTFOLIO_UPDATES,
        channelDescription: '投资组合收益、风险评估等定期更新',
        importance: Importance.low,
        priority: Priority.low,
        icon: '@mipmap/ic_launcher',
        enableVibration: false,
        enableLights: false,
        styleInformation: BigTextStyleInformation(
          body,
          htmlFormatBigText: true,
          contentTitle: title,
        ),
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false, // 低重要性，不需要声音
      );

      final platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // 发送通知
      await _flutterLocalNotificationsPlugin.show(
        _generateNotificationId(),
        title,
        body,
        platformDetails,
        payload: jsonEncode({
          'type': 'portfolio_suggestion',
          'suggestionType': suggestionType,
          'description': description,
          'recommendedFunds': recommendedFunds,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      AppLogger.info('✅ 投资组合建议通知发送成功');
    } catch (e) {
      AppLogger.error('❌ 发送投资组合建议失败', e);
    }
  }

  /// 发送市场新闻通知
  Future<void> sendMarketNews({
    required String title,
    required String content,
    String? imageUrl,
  }) async {
    try {
      await initialize();

      // 检查权限
      final permissionResult = await Android13NotificationPermissionManager
          .instance
          .requestNotificationPermission();

      if (!permissionResult.isGranted) {
        AppLogger.warn('❌ 通知权限未授予，无法发送市场新闻');
        return;
      }

      // 获取通知渠道ID
      final channelId = NotificationChannelManager.instance
          .getChannelIdForNotificationType(NotificationType.marketNews);

      // 构建通知详情
      final androidDetails = AndroidNotificationDetails(
        channelId,
        NotificationChannelManager.CHANNEL_NAME_MARKET_NEWS,
        channelDescription: '市场动态、行业新闻、政策变化等资讯推送',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
        enableVibration: false,
        enableLights: false,
        styleInformation: imageUrl != null
            ? BigPictureStyleInformation(
                FilePathAndroidBitmap(imageUrl),
                largeIcon: FilePathAndroidBitmap(imageUrl),
                contentTitle: title,
                htmlFormatContentTitle: true,
                summaryText: content,
                htmlFormatSummaryText: true,
              )
            : BigTextStyleInformation(
                content,
                htmlFormatBigText: true,
                contentTitle: title,
                htmlFormatContentTitle: true,
              ),
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
        subtitle: '市场新闻',
      );

      final platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // 发送通知
      await _flutterLocalNotificationsPlugin.show(
        _generateNotificationId(),
        title,
        content,
        platformDetails,
        payload: jsonEncode({
          'type': 'market_news',
          'title': title,
          'content': content,
          'imageUrl': imageUrl,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      AppLogger.info('✅ 市场新闻通知发送成功: $title');
    } catch (e) {
      AppLogger.error('❌ 发送市场新闻通知失败', e);
    }
  }

  /// 取消指定ID的通知
  Future<void> cancelNotification(int id) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(id);
      AppLogger.debug('取消通知: $id');
    } catch (e) {
      AppLogger.error('取消通知失败: $id', e);
    }
  }

  /// 取消所有通知
  Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      AppLogger.debug('取消所有通知');
    } catch (e) {
      AppLogger.error('取消所有通知失败', e);
    }
  }

  /// 获取待发送的通知
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _flutterLocalNotificationsPlugin
          .pendingNotificationRequests();
    } catch (e) {
      AppLogger.error('获取待发送通知失败', e);
      return [];
    }
  }

  /// 生成通知ID
  int _generateNotificationId() {
    return DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }

  /// 检查通知权限状态
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

  /// 获取通知权限状态详情
  Future<Map<String, dynamic>> getNotificationPermissionDetails() async {
    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final permissionStatus = await Android13NotificationPermissionManager
          .instance
          .checkNotificationPermissionStatus();

      return {
        'androidVersion': androidInfo.version.release,
        'sdkInt': androidInfo.version.sdkInt,
        'isAndroid13Plus': androidInfo.version.sdkInt >= 33,
        'permissionStatus': permissionStatus.name,
        'isInitialized': _isInitialized,
        'pendingNotificationsCount': (await getPendingNotifications()).length,
      };
    } catch (e) {
      AppLogger.error('获取通知权限详情失败', e);
      return {};
    }
  }

  /// 获取活跃的通知渠道
  Future<List<AndroidNotificationChannel>>
      getActiveNotificationChannels() async {
    try {
      if (!Platform.isAndroid) return [];

      return await _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.getNotificationChannels() ??
          [];
    } catch (e) {
      AppLogger.error('获取活跃通知渠道失败', e);
      return [];
    }
  }
}
