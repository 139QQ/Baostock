import 'dart:io';
import 'package:local_notifier/local_notifier.dart';

/// 独立的通知测试脚本
/// 用于验证Windows通知功能
void main() async {
  print('🧪 开始Windows通知功能独立测试');

  try {
    // 1. 检查平台
    print('📊 当前平台: ${Platform.operatingSystem}');

    if (!Platform.isWindows) {
      print('❌ 此测试脚本仅支持Windows平台');
      return;
    }

    // 2. 初始化local_notifier
    print('🔧 初始化local_notifier...');
    await localNotifier.setup(appName: '基速基金分析平台测试');
    print('✅ local_notifier初始化完成');

    // 3. 发送测试通知
    print('📱 发送测试通知...');
    final notification = LocalNotification(
      title: '🧪 独立测试通知',
      body: '这是一条来自独立测试脚本的Windows通知\n时间: ${DateTime.now().toString().substring(11, 19)}',
    );

    await notification.show();
    print('✅ 测试通知发送成功！');

    // 4. 发送另一条通知测试
    print('📈 发送基金价格测试通知...');
    final priceNotification = LocalNotification(
      title: '📈 基金价格上涨提醒',
      body: '易方达裕添收益债券A(110022)\n当前价格: ¥1.2345\n变化: +0.0023 (+1.89%)',
    );

    await priceNotification.show();
    print('✅ 基金价格通知发送成功！');

    print('🎉 所有测试通过！');

  } catch (e, stack) {
    print('❌ 测试失败: $e');
    print('📚 错误堆栈: $stack');
  }

  print('🏁 测试完成');
}