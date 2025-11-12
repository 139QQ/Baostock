import 'dart:io';
import 'package:local_notifier/local_notifier.dart';
import '../utils/logger.dart';

/// 简化的本地通知服务
/// 使用local_notifier插件实现跨平台桌面通知
class SimpleLocalNotificationService {
  static final SimpleLocalNotificationService _instance =
      SimpleLocalNotificationService._();
  static SimpleLocalNotificationService get instance => _instance;

  SimpleLocalNotificationService._();

  bool _isInitialized = false;

  /// 初始化本地通知服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      AppLogger.info('🔔 初始化SimpleLocalNotificationService');

      // 检查是否支持本地通知
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // 设置本地通知器
        await localNotifier.setup(
          appName: '基速基金分析平台',
        );

        AppLogger.info('✅ local_notifier设置完成');
      } else {
        AppLogger.warn('⚠️ 当前平台不支持本地通知: ${Platform.operatingSystem}');
      }

      _isInitialized = true;
      AppLogger.info('✅ SimpleLocalNotificationService初始化完成');
    } catch (e) {
      AppLogger.error('❌ SimpleLocalNotificationService初始化失败', e);
      rethrow;
    }
  }

  /// 发送测试通知
  Future<void> sendTestNotification() async {
    try {
      await initialize();

      final notification = LocalNotification(
        title: '基速基金分析平台',
        body: '这是一条测试通知',
      );

      await notification.show();
      AppLogger.info('✅ 本地测试通知发送成功');
    } catch (e) {
      AppLogger.error('❌ 本地测试通知发送失败', e);
      rethrow;
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

      final changeEmoji = priceChange >= 0 ? '📈' : '📉';
      final changeText = priceChange >= 0 ? '+' : '';

      final notification = LocalNotification(
        title: '$changeEmoji 基金价格提醒',
        body:
            '$fundName($fundCode)\n当前价格: ¥${currentPrice.toStringAsFixed(4)}\n变化: $changeText${priceChange.toStringAsFixed(4)} ($changeText${changePercent.toStringAsFixed(2)}%)',
      );

      await notification.show();
      AppLogger.info('✅ 本地基金价格提醒通知发送成功');
    } catch (e) {
      AppLogger.error('❌ 本地基金价格提醒通知发送失败', e);
      rethrow;
    }
  }

  /// 发送交易信号通知
  Future<void> sendTradeSignal({
    required String fundCode,
    required String fundName,
    required String signalType,
    required String reason,
    required double targetPrice,
    required double currentPrice,
  }) async {
    try {
      await initialize();

      final signalEmoji = signalType == '买入' ? '🟢' : '🔴';

      final notification = LocalNotification(
        title: '$signalEmoji 交易信号提醒',
        body:
            '$fundName($fundCode)\n信号类型: $signalType\n目标价格: ¥${targetPrice.toStringAsFixed(4)}\n当前价格: ¥${currentPrice.toStringAsFixed(4)}\n分析: $reason',
      );

      await notification.show();
      AppLogger.info('✅ 本地交易信号通知发送成功');
    } catch (e) {
      AppLogger.error('❌ 本地交易信号通知发送失败', e);
      rethrow;
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

      var fundsText = recommendedFunds.take(3).join(', ');
      if (recommendedFunds.length > 3) {
        fundsText = '$fundsText 等${recommendedFunds.length}只基金';
      }

      final notification = LocalNotification(
        title: '💡 投资组合建议',
        body: '建议类型: $suggestionType\n详情: $description\n推荐基金: $fundsText',
      );

      await notification.show();
      AppLogger.info('✅ 本地投资组合建议通知发送成功');
    } catch (e) {
      AppLogger.error('❌ 本地投资组合建议通知发送失败', e);
      rethrow;
    }
  }

  /// 检查通知是否可用
  Future<bool> isNotificationAvailable() async {
    try {
      if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
        return false;
      }

      // local_notifier在桌面平台通常是可用的
      return true;
    } catch (e) {
      AppLogger.error('检查通知可用性失败', e);
      return false;
    }
  }

  /// 获取通知服务状态详情
  Future<Map<String, dynamic>> getNotificationStatus() async {
    try {
      final isAvailable = await isNotificationAvailable();

      return {
        'platform': Platform.operatingSystem,
        'isInitialized': _isInitialized,
        'isAvailable': isAvailable,
        'isSupported':
            Platform.isWindows || Platform.isLinux || Platform.isMacOS,
        'serviceType': 'local_notifier',
      };
    } catch (e) {
      AppLogger.error('获取通知状态失败', e);
      return {
        'platform': Platform.operatingSystem,
        'isInitialized': _isInitialized,
        'isAvailable': false,
        'error': e.toString(),
      };
    }
  }

  /// 测试通知系统
  Future<void> runNotificationTest() async {
    AppLogger.info('🧪 开始运行通知系统测试');

    try {
      // 1. 检查支持状态
      final status = await getNotificationStatus();
      AppLogger.info('📊 通知状态: $status');

      if (!status['isSupported']) {
        AppLogger.warn('❌ 当前平台不支持本地通知');
        return;
      }

      // 2. 初始化服务
      await initialize();

      // 3. 发送测试通知
      await sendTestNotification();

      AppLogger.info('✅ 通知系统测试完成');
    } catch (e) {
      AppLogger.error('❌ 通知系统测试失败', e);
      rethrow;
    }
  }
}
