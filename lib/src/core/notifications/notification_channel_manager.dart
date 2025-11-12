import 'package:flutter/foundation.dart';
import '../utils/logger.dart';

/// 通知渠道管理器
///
/// 基于Android 8.0+的通知渠道系统，提供精细化的通知管理
/// 参考：https://juejin.cn/post/7516784123693039626
class NotificationChannelManager {
  // 单例模式
  NotificationChannelManager._();
  static final NotificationChannelManager _instance =
      NotificationChannelManager._();
  static NotificationChannelManager get instance => _instance;

  // 通知渠道ID常量
  static const String CHANNEL_ID_FUND_ALERTS = 'fund_alerts';
  static const String CHANNEL_ID_MARKET_NEWS = 'market_news';
  static const String CHANNEL_ID_TRADE_SIGNALS = 'trade_signals';
  static const String CHANNEL_ID_PORTFOLIO_UPDATES = 'portfolio_updates';
  static const String CHANNEL_ID_SYSTEM_NOTIFICATIONS = 'system_notifications';

  // 通知渠道名称常量
  static const String CHANNEL_NAME_FUND_ALERTS = '基金价格提醒';
  static const String CHANNEL_NAME_MARKET_NEWS = '市场新闻';
  static const String CHANNEL_NAME_TRADE_SIGNALS = '交易信号';
  static const String CHANNEL_NAME_PORTFOLIO_UPDATES = '投资组合更新';
  static const String CHANNEL_NAME_SYSTEM_NOTIFICATIONS = '系统通知';

  /// 初始化所有通知渠道
  ///
  /// 注意：通知渠道一旦创建就无法修改，所以这个方法应该在应用启动时调用
  Future<void> initializeChannels() async {
    try {
      AppLogger.info('🔔 初始化通知渠道...');

      // 创建基金价格提醒渠道（高优先级）
      await _createFundAlertsChannel();

      // 创建市场新闻渠道（默认优先级）
      await _createMarketNewsChannel();

      // 创建交易信号渠道（高优先级）
      await _createTradeSignalsChannel();

      // 创建投资组合更新渠道（低优先级）
      await _createPortfolioUpdatesChannel();

      // 创建系统通知渠道（默认优先级）
      await _createSystemNotificationsChannel();

      AppLogger.info('✅ 通知渠道初始化完成');
    } catch (e) {
      AppLogger.error('❌ 初始化通知渠道失败', e);
    }
  }

  /// 创建基金价格提醒渠道
  ///
  /// 用途：基金净值变化、价格异动等重要提醒
  /// 重要性：高（IMPORTANCE_HIGH）- 以横幅形式显示，有提示音
  Future<void> _createFundAlertsChannel() async {
    final channelInfo = NotificationChannelInfo(
      channelId: CHANNEL_ID_FUND_ALERTS,
      channelName: CHANNEL_NAME_FUND_ALERTS,
      description: '基金净值变化、价格异动等重要投资提醒',
      importance: NotificationImportance.high,
      enableVibration: true,
      enableLights: true,
      soundPath: 'fund_alert_sound.mp3',
    );

    await _createChannel(channelInfo);
  }

  /// 创建市场新闻渠道
  ///
  /// 用途：市场动态、行业新闻、政策变化等
  /// 重要性：中等（IMPORTANCE_MEDIUM）- 有提示音，无横幅
  Future<void> _createMarketNewsChannel() async {
    final channelInfo = NotificationChannelInfo(
      channelId: CHANNEL_ID_MARKET_NEWS,
      channelName: CHANNEL_NAME_MARKET_NEWS,
      description: '市场动态、行业新闻、政策变化等资讯推送',
      importance: NotificationImportance.medium,
      enableVibration: false,
      enableLights: false,
    );

    await _createChannel(channelInfo);
  }

  /// 创建交易信号渠道
  ///
  /// 用途：买入/卖出信号、操作建议等重要交易提醒
  /// 重要性：高（IMPORTANCE_HIGH）- 以横幅形式显示，有提示音
  Future<void> _createTradeSignalsChannel() async {
    final channelInfo = NotificationChannelInfo(
      channelId: CHANNEL_ID_TRADE_SIGNALS,
      channelName: CHANNEL_NAME_TRADE_SIGNALS,
      description: '买入/卖出信号、操作建议等重要交易提醒',
      importance: NotificationImportance.high,
      enableVibration: true,
      enableLights: true,
      soundPath: 'trade_signal_sound.mp3',
    );

    await _createChannel(channelInfo);
  }

  /// 创建投资组合更新渠道
  ///
  /// 用途：投资组合收益、风险评估等
  /// 重要性：低（IMPORTANCE_LOW）- 无提示音，无横幅
  Future<void> _createPortfolioUpdatesChannel() async {
    final channelInfo = NotificationChannelInfo(
      channelId: CHANNEL_ID_PORTFOLIO_UPDATES,
      channelName: CHANNEL_NAME_PORTFOLIO_UPDATES,
      description: '投资组合收益、风险评估等定期更新',
      importance: NotificationImportance.low,
      enableVibration: false,
      enableLights: false,
    );

    await _createChannel(channelInfo);
  }

  /// 创建系统通知渠道
  ///
  /// 用途：应用更新、系统维护等
  /// 重要性：中等（IMPORTANCE_MEDIUM）- 有提示音，无横幅
  Future<void> _createSystemNotificationsChannel() async {
    final channelInfo = NotificationChannelInfo(
      channelId: CHANNEL_ID_SYSTEM_NOTIFICATIONS,
      channelName: CHANNEL_NAME_SYSTEM_NOTIFICATIONS,
      description: '应用更新、系统维护、重要通知等',
      importance: NotificationImportance.medium,
      enableVibration: false,
      enableLights: false,
    );

    await _createChannel(channelInfo);
  }

  /// 创建单个通知渠道
  Future<void> _createChannel(NotificationChannelInfo channelInfo) async {
    try {
      AppLogger.debug('创建通知渠道: ${channelInfo.channelName}');

      // 这里应该调用平台特定的API来创建通知渠道
      // 在实际的Flutter应用中，会使用flutter_local_notifications插件
      if (kDebugMode) {
        AppLogger.info('🔔 [模拟] 创建通知渠道: ${channelInfo.toJson()}');
      }

      // 实际实现示例（使用flutter_local_notifications）:
      /*
      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      final androidChannel = AndroidNotificationChannel(
        channelInfo.channelId,
        channelInfo.channelName,
        description: channelInfo.description,
        importance: _convertImportanceToAndroid(channelInfo.importance),
        enableVibration: channelInfo.enableVibration,
        enableLights: channelInfo.enableLights,
        sound: channelInfo.soundPath,
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
      */
    } catch (e) {
      AppLogger.error('创建通知渠道失败: ${channelInfo.channelId}', e);
    }
  }

  /// 获取所有通知渠道信息
  List<NotificationChannelInfo> getAllChannels() {
    return [
      NotificationChannelInfo(
        channelId: CHANNEL_ID_FUND_ALERTS,
        channelName: CHANNEL_NAME_FUND_ALERTS,
        description: '基金净值变化、价格异动等重要投资提醒',
        importance: NotificationImportance.high,
        enableVibration: true,
        enableLights: true,
      ),
      NotificationChannelInfo(
        channelId: CHANNEL_ID_MARKET_NEWS,
        channelName: CHANNEL_NAME_MARKET_NEWS,
        description: '市场动态、行业新闻、政策变化等资讯推送',
        importance: NotificationImportance.medium,
        enableVibration: false,
        enableLights: false,
      ),
      NotificationChannelInfo(
        channelId: CHANNEL_ID_TRADE_SIGNALS,
        channelName: CHANNEL_NAME_TRADE_SIGNALS,
        description: '买入/卖出信号、操作建议等重要交易提醒',
        importance: NotificationImportance.high,
        enableVibration: true,
        enableLights: true,
      ),
      NotificationChannelInfo(
        channelId: CHANNEL_ID_PORTFOLIO_UPDATES,
        channelName: CHANNEL_NAME_PORTFOLIO_UPDATES,
        description: '投资组合收益、风险评估等定期更新',
        importance: NotificationImportance.low,
        enableVibration: false,
        enableLights: false,
      ),
      NotificationChannelInfo(
        channelId: CHANNEL_ID_SYSTEM_NOTIFICATIONS,
        channelName: CHANNEL_NAME_SYSTEM_NOTIFICATIONS,
        description: '应用更新、系统维护、重要通知等',
        importance: NotificationImportance.medium,
        enableVibration: false,
        enableLights: false,
      ),
    ];
  }

  /// 根据通知类型获取渠道ID
  String getChannelIdForNotificationType(NotificationType type) {
    switch (type) {
      case NotificationType.fundAlert:
        return CHANNEL_ID_FUND_ALERTS;
      case NotificationType.marketNews:
        return CHANNEL_ID_MARKET_NEWS;
      case NotificationType.tradeSignal:
        return CHANNEL_ID_TRADE_SIGNALS;
      case NotificationType.portfolioUpdate:
        return CHANNEL_ID_PORTFOLIO_UPDATES;
      case NotificationType.systemNotification:
        return CHANNEL_ID_SYSTEM_NOTIFICATIONS;
    }
  }

  /// 检查通知渠道是否存在
  Future<bool> channelExists(String channelId) async {
    try {
      // 这里应该调用平台特定API检查渠道是否存在
      // 在实际的Flutter应用中，会使用flutter_local_notifications插件
      if (kDebugMode) {
        AppLogger.debug('检查通知渠道是否存在: $channelId');
        return true; // 模拟返回
      }

      // 实际实现示例:
      /*
      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      final channels = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.getNotificationChannels();

      return channels?.any((channel) => channel.id == channelId) ?? false;
      */

      return false;
    } catch (e) {
      AppLogger.error('检查通知渠道失败: $channelId', e);
      return false;
    }
  }
}

/// 通知渠道信息模型
class NotificationChannelInfo {
  final String channelId;
  final String channelName;
  final String description;
  final NotificationImportance importance;
  final bool enableVibration;
  final bool enableLights;
  final String? soundPath;

  NotificationChannelInfo({
    required this.channelId,
    required this.channelName,
    required this.description,
    required this.importance,
    this.enableVibration = false,
    this.enableLights = false,
    this.soundPath,
  });

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'channelId': channelId,
      'channelName': channelName,
      'description': description,
      'importance': importance.name,
      'enableVibration': enableVibration,
      'enableLights': enableLights,
      'soundPath': soundPath,
    };
  }

  @override
  String toString() {
    return 'NotificationChannelInfo(channelId: $channelId, channelName: $channelName)';
  }
}

/// 通知重要性等级
enum NotificationImportance {
  /// 高重要性：以横幅形式显示，有提示音
  high,

  /// 中等重要性：有提示音，无横幅
  medium,

  /// 低重要性：无提示音，无横幅
  low,

  /// 最小重要性：不显示任何提示
  min,
}

/// 通知类型
enum NotificationType {
  /// 基金提醒
  fundAlert,

  /// 市场新闻
  marketNews,

  /// 交易信号
  tradeSignal,

  /// 投资组合更新
  portfolioUpdate,

  /// 系统通知
  systemNotification,
}
