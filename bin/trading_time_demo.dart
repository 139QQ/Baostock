/// A股交易时间检测演示
/// 命令行版本，展示交易时间判断逻辑

import 'dart:io';

/// 简化的交易时间演示（不依赖Flutter）
class SimpleTradingTimeDemo {

  /// A股交易时间定义
  static const Duration morningStart = Duration(hours: 9, minutes: 30);
  static const Duration morningEnd = Duration(hours: 11, minutes: 30);
  static const Duration afternoonStart = Duration(hours: 13, minutes: 0);
  static const Duration afternoonEnd = Duration(hours: 15, minutes: 0);

  /// 检查是否为工作日
  static bool isWorkday(DateTime date) {
    return date.weekday >= 1 && date.weekday <= 5;
  }

  /// 检查是否为交易时间
  static bool isTradingTime(DateTime date) {
    if (!isWorkday(date)) return false;

    final time = Duration(hours: date.hour, minutes: date.minute);
    return (time >= morningStart && time <= morningEnd) ||
           (time >= afternoonStart && time <= afternoonEnd);
  }

  /// 获取当前交易状态
  static String getTradingStatus(DateTime date) {
    if (!isWorkday(date)) return '🔴 周末休市';

    final time = Duration(hours: date.hour, minutes: date.minute);

    if (time >= morningStart && time <= morningEnd) {
      return '🟢 早盘交易中';
    } else if (time > morningEnd && time < afternoonStart) {
      return '🟡 午间休市';
    } else if (time >= afternoonStart && time <= afternoonEnd) {
      return '🟢 尾盘交易中';
    } else if (time > afternoonEnd || time < morningStart) {
      return '🔴 已收盘';
    }

    return '🔴 休市';
  }

  /// 模拟一天的各个时间点
  static void simulateTradingDay() {
    print('📅 A股交易时间模拟演示');
    print('=' * 50);

    final testDate = DateTime(2025, 1, 15); // 周三
    final testTimes = [
      DateTime(testDate.year, testDate.month, testDate.day, 9, 0),    // 开盘前
      DateTime(testDate.year, testDate.month, testDate.day, 9, 30),   // 早盘开盘
      DateTime(testDate.year, testDate.month, testDate.day, 10, 30),  // 早盘中
      DateTime(testDate.year, testDate.month, testDate.day, 11, 30),  // 早盘收盘
      DateTime(testDate.year, testDate.month, testDate.day, 12, 0),   // 午休
      DateTime(testDate.year, testDate.month, testDate.day, 13, 0),   // 尾盘开盘
      DateTime(testDate.year, testDate.month, testDate.day, 14, 0),   // 尾盘中
      DateTime(testDate.year, testDate.month, testDate.day, 15, 0),   // 尾盘收盘
      DateTime(testDate.year, testDate.month, testDate.day, 15, 30),  // 收盘后
    ];

    for (final time in testTimes) {
      final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      final status = getTradingStatus(time);
      final isTrading = isTradingTime(time);

      print('   $timeStr: $status ${isTrading ? '(可获取实时数据)' : '(使用历史数据)'}');
    }
  }

  /// 测试当前时间状态
  static void testCurrentTime() {
    print('\n🕐 当前时间状态测试');
    print('=' * 50);

    final now = DateTime.now();
    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final weekday = weekdays[now.weekday - 1];
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    print('📅 当前时间: $weekday $timeStr');
    print('📊 交易状态: ${getTradingStatus(now)}');
    print('💡 能否获取实时数据: ${isTradingTime(now) ? '✅ 是' : '❌ 否'}');
    print('💡 能否获取历史数据: ✅ 是 (24小时可用)');

    // 显示距离下一个交易时段的时间
    if (!isTradingTime(now)) {
      final nextSessionTime = _getNextTradingSession(now);
      if (nextSessionTime != null) {
        final diff = nextSessionTime.difference(now);
        final hours = diff.inHours;
        final minutes = diff.inMinutes % 60;
        print('⏰ 距离下一个交易时段: $hours小时$minutes分钟');
      }
    }
  }

  /// 获取下一个交易时段时间
  static DateTime? _getNextTradingSession(DateTime currentTime) {
    final now = DateTime(currentTime.year, currentTime.month, currentTime.day, currentTime.hour, currentTime.minute);

    if (!isWorkday(now)) {
      // 找下一个工作日
      DateTime nextDay = now.add(const Duration(days: 1));
      while (!isWorkday(nextDay)) {
        nextDay = nextDay.add(const Duration(days: 1));
      }
      return DateTime(nextDay.year, nextDay.month, nextDay.day, 9, 30);
    }

    final time = Duration(hours: now.hour, minutes: now.minute);

    if (time < morningStart) {
      return DateTime(now.year, now.month, now.day, 9, 30);
    } else if (time > morningEnd && time < afternoonStart) {
      return DateTime(now.year, now.month, now.day, 13, 0);
    } else if (time > afternoonEnd) {
      // 找下一个工作日
      DateTime nextDay = now.add(const Duration(days: 1));
      while (!isWorkday(nextDay)) {
        nextDay = nextDay.add(const Duration(days: 1));
      }
      return DateTime(nextDay.year, nextDay.month, nextDay.day, 9, 30);
    }

    return null; // 当前正在交易
  }

  /// 显示API使用建议
  static void showApiRecommendations() {
    print('\n💡 API使用建议');
    print('=' * 50);

    final now = DateTime.now();
    final isTrading = isTradingTime(now);

    if (isTrading) {
      print('🟢 当前是交易时间，推荐使用：');
      print('   • 实时指数API: stock_zh_index_spot_em');
      print('   • 分时数据API: index_zh_a_hist_min_em');
      print('   • 历史数据API: 仍然可用 (24小时)');
    } else {
      print('🔴 当前不是交易时间，推荐使用：');
      print('   • 历史数据API: stock_zh_index_daily_em (东方财富)');
      print('   • 历史数据API: stock_zh_index_daily (新浪)');
      print('   • 历史数据API: stock_zh_index_daily_tx (腾讯)');
      print('   ⚠️ 实时/分时API返回HTTP 500或空数据是正常现象');
    }

    print('\n📋 API可用时间总结：');
    print('   实时数据API: 仅交易时段可用');
    print('   分时数据API: 仅交易时段可用');
    print('   历史数据API: 24小时可用');
    print('   HTTP 500错误: 非交易时段的正常现象');
  }
}

Future<void> main() async {
  print('🚀 A股交易时间检测演示');
  print('=' * 60);

  // 1. 模拟交易时间
  SimpleTradingTimeDemo.simulateTradingDay();

  // 2. 测试当前时间
  SimpleTradingTimeDemo.testCurrentTime();

  // 3. 显示API使用建议
  SimpleTradingTimeDemo.showApiRecommendations();

  print('\n' + '=' * 60);
  print('✅ 演示完成！');
  print('\n🎯 核心要点：');
  print('   • HTTP 500错误通常是因为非交易时间');
  print('   • 实时数据只能在交易时段获取');
  print('   • 历史数据24小时可用，推荐替代方案');
  print('   • 分时数据仅在交易时段有效');
}