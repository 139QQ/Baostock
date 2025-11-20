/// A股交易时间工具类
/// 用于判断当前是否为交易时间以及相关的交易信息

class TradingTimeUtils {
  /// 交易时段定义
  static const Duration morningStart = Duration(hours: 9, minutes: 30);
  static const Duration morningEnd = Duration(hours: 11, minutes: 30);
  static const Duration afternoonStart = Duration(hours: 13, minutes: 0);
  static const Duration afternoonEnd = Duration(hours: 15, minutes: 0);

  /// 检查当前是否为A股交易时间
  static bool isTradingTime({DateTime? currentTime}) {
    final now = currentTime ?? DateTime.now();

    // 检查是否为工作日（周一到周五）
    if (!isWorkday(now)) {
      return false;
    }

    // 获取当天的时间
    final time = Duration(hours: now.hour, minutes: now.minute);

    // 检查是否在交易时段内
    return (time >= morningStart && time <= morningEnd) ||
        (time >= afternoonStart && time <= afternoonEnd);
  }

  /// 检查是否为工作日（周一到周五）
  static bool isWorkday(DateTime date) {
    // 周六(6)和周日(7)不是工作日
    return date.weekday >= 1 && date.weekday <= 5;
  }

  /// 检查是否为交易日（排除常见的节假日）
  static bool isTradingDay(DateTime date) {
    if (!isWorkday(date)) {
      return false;
    }

    // 检查常见的节假日（这个列表可以扩展）
    final holidays = {
      // 元旦
      DateTime(date.year, 1, 1),
      // 春节（简化处理，实际需要每年更新）
      // 清明节（简化处理）
      // 劳动节
      DateTime(date.year, 5, 1),
      // 端午节（简化处理）
      // 中秋节（简化处理）
      // 国庆节
      DateTime(date.year, 10, 1),
      DateTime(date.year, 10, 2),
      DateTime(date.year, 10, 3),
    };

    // 检查是否是节假日（检查前后几天的调休）
    for (final holiday in holidays) {
      if (_isSameDay(date, holiday)) {
        return false;
      }
    }

    return true;
  }

  /// 获取当前交易时段状态
  static TradingSession getCurrentTradingSession({DateTime? currentTime}) {
    final now = currentTime ?? DateTime.now();

    if (!isWorkday(now)) {
      return TradingSession.closed;
    }

    final time = Duration(hours: now.hour, minutes: now.minute);

    if (time >= morningStart && time <= morningEnd) {
      return TradingSession.morning;
    } else if (time >= afternoonStart && time <= afternoonEnd) {
      return TradingSession.afternoon;
    } else if (time > morningEnd && time < afternoonStart) {
      return TradingSession.lunchBreak;
    } else {
      return TradingSession.closed;
    }
  }

  /// 获取距离下一个交易时段的时间
  static Duration getTimeToNextTradingSession({DateTime? currentTime}) {
    final now = currentTime ?? DateTime.now();
    final session = getCurrentTradingSession(currentTime: now);

    switch (session) {
      case TradingSession.morning:
        return Duration.zero; // 当前正在交易
      case TradingSession.lunchBreak:
        final afternoonTime = DateTime(now.year, now.month, now.day, 13, 0, 0);
        return afternoonTime.difference(now);
      case TradingSession.afternoon:
        return Duration.zero; // 当前正在交易
      case TradingSession.closed:
        // 找下一个交易日
        DateTime nextTradingDay = now.add(const Duration(days: 1));
        while (!isTradingDay(nextTradingDay)) {
          nextTradingDay = nextTradingDay.add(const Duration(days: 1));
        }
        final nextMorningTime = DateTime(nextTradingDay.year,
            nextTradingDay.month, nextTradingDay.day, 9, 30, 0);
        return nextMorningTime.difference(now);
    }
  }

  /// 获取交易状态描述
  static String getTradingStatusText({DateTime? currentTime}) {
    final now = currentTime ?? DateTime.now();
    final session = getCurrentTradingSession(currentTime: now);

    switch (session) {
      case TradingSession.morning:
        return '🟢 早盘交易中 (9:30-11:30)';
      case TradingSession.lunchBreak:
        return '🟡 午间休市 (11:30-13:00)';
      case TradingSession.afternoon:
        return '🟢 尾盘交易中 (13:00-15:00)';
      case TradingSession.closed:
        if (!isWorkday(now)) {
          return '🔴 非交易日（周末或节假日）';
        } else {
          final timeToNext = getTimeToNextTradingSession(currentTime: now);
          if (timeToNext.inDays > 0) {
            return '🔴 休市中 (下一个交易日开盘)';
          } else {
            final hours = timeToNext.inHours;
            final minutes = timeToNext.inMinutes % 60;
            return '🔴 休市中 (距离开盘还有${hours}小时${minutes}分钟)';
          }
        }
    }
  }

  /// 检查是否为开盘集合竞价时间（9:15-9:25）
  static bool isPreMarketTime({DateTime? currentTime}) {
    final now = currentTime ?? DateTime.now();

    if (!isWorkday(now)) {
      return false;
    }

    final time = Duration(hours: now.hour, minutes: now.minute);
    final preMarketStart = Duration(hours: 9, minutes: 15);
    final preMarketEnd = Duration(hours: 9, minutes: 25);

    return time >= preMarketStart && time <= preMarketEnd;
  }

  /// 获取下一个交易日的日期
  static DateTime getNextTradingDay(DateTime date) {
    DateTime nextDay = date.add(const Duration(days: 1));
    while (!isTradingDay(nextDay)) {
      nextDay = nextDay.add(const Duration(days: 1));
    }
    return nextDay;
  }

  /// 检查两个日期是否是同一天
  static bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// 获取交易时段的统计信息
  static Map<String, dynamic> getTradingSessionStats() {
    final now = DateTime.now();
    final session = getCurrentTradingSession(currentTime: now);
    final timeToNext = getTimeToNextTradingSession(currentTime: now);

    return {
      'currentSession': session.toString(),
      'isTradingTime': isTradingTime(),
      'isWorkday': isWorkday(now),
      'isTradingDay': isTradingDay(now),
      'isPreMarketTime': isPreMarketTime(),
      'timeToNextTradingSession':
          '${timeToNext.inHours}:${timeToNext.inMinutes % 60}',
      'statusText': getTradingStatusText(),
    };
  }
}

/// 交易时段枚举
enum TradingSession {
  morning, // 早盘 9:30-11:30
  lunchBreak, // 午休 11:30-13:00
  afternoon, // 尾盘 13:00-15:00
  closed, // 休市
}
