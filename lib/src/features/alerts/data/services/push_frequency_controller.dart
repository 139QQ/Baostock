import 'dart:async';
import 'dart:collection';
import 'dart:math';

import '../models/market_change_event.dart';
import '../models/user_preferences.dart';
import '../models/change_severity.dart';

/// 推送频率控制器
///
/// 负责智能控制推送频率，防止过度推送
class PushFrequencyController {
  /// 用户推送记录
  final Map<String, Queue<PushRecord>> _userPushRecords = {};

  /// 全局推送记录（用于系统级频率控制）
  final Queue<PushRecord> _globalPushRecords = Queue();

  /// 频率控制配置
  final FrequencyControlConfig _config;

  /// 用户疲劳度跟踪
  final Map<String, UserFatigueProfile> _fatigueProfiles = {};

  /// 构造函数
  PushFrequencyController({
    FrequencyControlConfig? config,
  }) : _config = config ?? FrequencyControlConfig();

  /// 检查是否可以推送
  Future<FrequencyControlResult> checkPushAllowed({
    required String userId,
    required MarketChangeEvent event,
    required UserPreferences preferences,
  }) async {
    // 紧急事件绕过大部分检查
    if (event.severity == ChangeSeverity.high &&
        preferences.allowUrgentPushesDuringSilentHours) {
      return FrequencyControlResult(allowed: true);
    }

    // 先检查重复推送（优先级最高）
    if (_isDuplicatePush(userId, event)) {
      return FrequencyControlResult(
        allowed: false,
        reason: '重复推送',
        nextAllowedTime: DateTime.now().add(const Duration(hours: 2)),
      );
    }

    // 检查用户级频率限制
    final userResult = _checkUserFrequencyLimit(userId, event, preferences);
    if (!userResult.allowed) {
      return userResult;
    }

    // 检查系统级频率限制
    final systemResult = _checkSystemFrequencyLimit(event);
    if (!systemResult.allowed) {
      return systemResult;
    }

    // 检查用户疲劳度（在基础检查通过后）
    final fatigueResult = _checkUserFatigue(userId, event, preferences);
    if (!fatigueResult.allowed) {
      return fatigueResult;
    }

    // 检查智能频率控制（不包含重复检查，因为我们已经处理过了）
    final smartResult =
        _checkSmartFrequencyControlWithoutDuplicate(userId, event, preferences);
    return smartResult;
  }

  /// 记录推送事件
  void recordPush({
    required String userId,
    required String eventId,
    required MarketChangeType eventType,
    required ChangeSeverity severity,
  }) {
    final record = PushRecord(
      userId: userId,
      eventId: eventId,
      eventType: eventType,
      severity: severity,
      timestamp: DateTime.now(),
    );

    // 记录用户推送
    final userRecords = _userPushRecords.putIfAbsent(userId, () => Queue());
    userRecords.addFirst(record);

    // 记录全局推送
    _globalPushRecords.addFirst(record);

    // 清理过期记录
    _cleanupExpiredRecords();
  }

  /// 获取用户推送统计
  PushStatistics getUserStatistics(String userId) {
    final userRecords = _userPushRecords[userId] ?? Queue();
    final now = DateTime.now();

    final dailyPushes = userRecords.where((record) {
      return now.difference(record.timestamp).inDays <= 1;
    }).length;

    final hourlyPushes = userRecords.where((record) {
      return now.difference(record.timestamp).inHours <= 1;
    }).length;

    final highPriorityPushes = userRecords.where((record) {
      return record.severity == ChangeSeverity.high;
    }).length;

    return PushStatistics(
      dailyPushes: dailyPushes,
      hourlyPushes: hourlyPushes,
      highPriorityPushes: highPriorityPushes,
      totalPushes: userRecords.length,
    );
  }

  /// 检查用户频率限制
  FrequencyControlResult _checkUserFrequencyLimit(
    String userId,
    MarketChangeEvent event,
    UserPreferences preferences,
  ) {
    final userRecords = _userPushRecords[userId] ?? Queue();
    final now = DateTime.now();

    // 紧急事件绕过频率限制
    if (event.severity == ChangeSeverity.high &&
        preferences.allowUrgentPushesDuringSilentHours) {
      return FrequencyControlResult(allowed: true);
    }

    // 检查每小时推送限制
    final hourlyPushes = userRecords.where((record) {
      return now.difference(record.timestamp).inHours < 1;
    }).length;

    final hourlyLimit = _config.maxPushesPerHour;
    if (hourlyPushes >= hourlyLimit) {
      return FrequencyControlResult(
        allowed: false,
        reason: '超过每小时最大推送数量限制',
        nextAllowedTime: now.add(const Duration(minutes: 60)),
      );
    }

    // 检查每日推送限制
    final dailyPushes = userRecords.where((record) {
      return now.difference(record.timestamp).inDays < 1;
    }).length;

    final dailyLimit = (_config.maxPushesPerHour * 12); // 12小时工作日
    if (dailyPushes >= dailyLimit) {
      return FrequencyControlResult(
        allowed: false,
        reason: '超过每日最大推送数量限制',
        nextAllowedTime: now.add(const Duration(days: 1)),
      );
    }

    // 检查最小推送间隔
    final lastPush = userRecords.isNotEmpty ? userRecords.first : null;
    if (lastPush != null) {
      final interval = now.difference(lastPush.timestamp);
      const minInterval = 2;
      if (interval.inMinutes < minInterval) {
        return FrequencyControlResult(
          allowed: false,
          reason: '推送间隔过短',
          nextAllowedTime:
              lastPush.timestamp.add(Duration(minutes: minInterval)),
        );
      }
    }

    return FrequencyControlResult(allowed: true);
  }

  /// 检查系统频率限制
  FrequencyControlResult _checkSystemFrequencyLimit(MarketChangeEvent event) {
    final now = DateTime.now();

    // 检查系统每分钟推送限制
    final currentMinutePushes = _globalPushRecords.where((record) {
      final diff = now.difference(record.timestamp);
      return diff.inMinutes == 0;
    }).length;

    if (currentMinutePushes >= _config.maxSystemPushesPerMinute) {
      return FrequencyControlResult(
        allowed: false,
        reason: '系统推送频率过高',
        nextAllowedTime: now.add(const Duration(minutes: 1)),
      );
    }

    return FrequencyControlResult(allowed: true);
  }

  /// 检查智能频率控制
  FrequencyControlResult _checkSmartFrequencyControl(
    String userId,
    MarketChangeEvent event,
    UserPreferences preferences,
  ) {
    // 紧急事件总是允许推送
    if (event.severity == ChangeSeverity.high) {
      return FrequencyControlResult(allowed: true);
    }

    // 检查是否在静默时段
    if (_isInSilentHours(preferences)) {
      return FrequencyControlResult(
        allowed: false,
        reason: '当前在静默时段',
        nextAllowedTime: _getNextSilentHourEnd(preferences),
      );
    }

    // 检查重复推送
    if (_isDuplicatePush(userId, event)) {
      return FrequencyControlResult(
        allowed: false,
        reason: '重复推送',
        nextAllowedTime: DateTime.now().add(const Duration(hours: 2)),
      );
    }

    return FrequencyControlResult(allowed: true);
  }

  /// 检查智能频率控制（不包含重复检查）
  FrequencyControlResult _checkSmartFrequencyControlWithoutDuplicate(
    String userId,
    MarketChangeEvent event,
    UserPreferences preferences,
  ) {
    // 紧急事件总是允许推送
    if (event.severity == ChangeSeverity.high) {
      return FrequencyControlResult(allowed: true);
    }

    // 检查是否在静默时段
    if (_isInSilentHours(preferences)) {
      return FrequencyControlResult(
        allowed: false,
        reason: '当前在静默时段',
        nextAllowedTime: _getNextSilentHourEnd(preferences),
      );
    }

    return FrequencyControlResult(allowed: true);
  }

  /// 检查是否在静默时段
  bool _isInSilentHours(UserPreferences preferences) {
    final now = DateTime.now();
    final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);

    return preferences.silentHours.any((silentHour) {
      // 检查时间范围
      return _isTimeInRange(currentTime, silentHour.start, silentHour.end);
    });
  }

  /// 获取静默时段结束时间
  DateTime _getNextSilentHourEnd(UserPreferences preferences) {
    final now = DateTime.now();
    final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);

    for (final silentHour in preferences.silentHours) {
      // 检查是否在当前静默时段内
      if (_isTimeInRange(currentTime, silentHour.start, silentHour.end)) {
        return DateTime(
          now.year,
          now.month,
          now.day,
          silentHour.end.hour,
          silentHour.end.minute,
        );
      }
    }

    return now;
  }

  /// 检查是否为重复推送
  bool _isDuplicatePush(String userId, MarketChangeEvent event) {
    final userRecords = _userPushRecords[userId] ?? Queue();
    final now = DateTime.now();

    // 检查最近是否有相同实体的推送
    for (final record in userRecords.take(10)) {
      if (record.eventId == event.id) {
        final timeDiff = now.difference(record.timestamp);
        if (timeDiff.inHours < 2) {
          return true;
        }
      }
    }

    return false;
  }

  /// 检查时间是否在范围内
  bool _isTimeInRange(TimeOfDay current, TimeOfDay start, TimeOfDay end) {
    final currentMinutes = current.hour * 60 + current.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (startMinutes <= endMinutes) {
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } else {
      // 跨天的时间范围
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
  }

  /// 清理过期记录
  void _cleanupExpiredRecords() {
    final cutoffTime = DateTime.now().subtract(const Duration(days: 7));

    // 清理用户记录
    for (final userId in _userPushRecords.keys) {
      final records = _userPushRecords[userId]!;
      while (
          records.isNotEmpty && records.last.timestamp.isBefore(cutoffTime)) {
        records.removeLast();
      }
    }

    // 清理全局记录
    while (_globalPushRecords.isNotEmpty &&
        _globalPushRecords.last.timestamp.isBefore(cutoffTime)) {
      _globalPushRecords.removeLast();
    }
  }

  /// 清理所有缓存
  void clearCache() {
    _userPushRecords.clear();
    _globalPushRecords.clear();
    _fatigueProfiles.clear();
  }

  /// 检查用户疲劳度
  FrequencyControlResult _checkUserFatigue(
    String userId,
    MarketChangeEvent event,
    UserPreferences preferences,
  ) {
    final fatigueProfile = _getFatigueProfile(userId);
    final now = DateTime.now();

    // 获取最近24小时的推送数量
    final recentPushes = _userPushRecords[userId]?.where((record) {
          return now.difference(record.timestamp).inHours <= 24;
        }).length ??
        0;

    // 计算疲劳度分数 (0-1)
    final fatigueScore = _calculateFatigueScore(recentPushes, fatigueProfile);

    // 高疲劳度时拒绝推送
    if (fatigueScore >= 0.8) {
      return FrequencyControlResult(
        allowed: false,
        reason: '疲劳度过高',
        nextAllowedTime: now.add(const Duration(hours: 4)),
      );
    }

    // 中等疲劳度时延迟推送
    if (fatigueScore >= 0.6) {
      // 只允许高优先级事件
      if (event.severity != ChangeSeverity.high) {
        return FrequencyControlResult(
          allowed: false,
          reason: '用户疲劳度中等，仅允许重要事件推送',
          nextAllowedTime: now.add(const Duration(minutes: 30)),
        );
      }
    }

    // 更新疲劳度状态
    fatigueProfile.lastPushTime = now;
    fatigueProfile.dailyPushCount = recentPushes;

    return const FrequencyControlResult(allowed: true);
  }

  /// 获取用户疲劳度画像
  UserFatigueProfile _getFatigueProfile(String userId) {
    return _fatigueProfiles.putIfAbsent(
      userId,
      () => UserFatigueProfile(userId: userId),
    );
  }

  /// 计算疲劳度分数
  double _calculateFatigueScore(int recentPushes, UserFatigueProfile profile) {
    // 基于最近推送数量的基础疲劳度 - 降低阈值
    double baseFatigue = min(1.0, recentPushes / 10.0);

    // 考虑推送密度
    if (profile.lastPushTime != null) {
      final hoursSinceLastPush =
          DateTime.now().difference(profile.lastPushTime!).inHours;
      if (hoursSinceLastPush < 1) {
        baseFatigue += 0.2; // 1小时内推送增加疲劳度
      }
    }

    // 考虑用户交互反馈 (如果有)
    baseFatigue += profile.userFeedbackWeight * profile.averageEngagementScore;

    return baseFatigue.clamp(0.0, 1.0);
  }
}

/// 频率控制配置
class FrequencyControlConfig {
  /// 每小时最大推送数量
  final int maxPushesPerHour;

  /// 系统每分钟最大推送数量
  final int maxSystemPushesPerMinute;

  /// 记录保留天数
  final int retentionDays;

  const FrequencyControlConfig({
    this.maxPushesPerHour = 20,
    this.maxSystemPushesPerMinute = 100,
    this.retentionDays = 7,
  });
}

/// 推送记录
class PushRecord {
  /// 用户ID
  final String userId;

  /// 事件ID
  final String eventId;

  /// 事件类型
  final MarketChangeType eventType;

  /// 事件严重程度
  final ChangeSeverity severity;

  /// 推送时间
  final DateTime timestamp;

  const PushRecord({
    required this.userId,
    required this.eventId,
    required this.eventType,
    required this.severity,
    required this.timestamp,
  });
}

/// 频率控制结果
class FrequencyControlResult {
  /// 是否允许推送
  final bool allowed;

  /// 拒绝原因
  final String? reason;

  /// 下次允许推送时间
  final DateTime? nextAllowedTime;

  const FrequencyControlResult({
    required this.allowed,
    this.reason,
    this.nextAllowedTime,
  });
}

/// 推送统计
class PushStatistics {
  /// 每日推送数量
  final int dailyPushes;

  /// 每小时推送数量
  final int hourlyPushes;

  /// 高优先级推送数量
  final int highPriorityPushes;

  /// 总推送数量
  final int totalPushes;

  const PushStatistics({
    required this.dailyPushes,
    required this.hourlyPushes,
    required this.highPriorityPushes,
    required this.totalPushes,
  });
}

/// 用户疲劳度画像
class UserFatigueProfile {
  /// 用户ID
  final String userId;

  /// 最后推送时间
  DateTime? lastPushTime;

  /// 每日推送数量
  int dailyPushCount;

  /// 平均互动评分 (0-1)
  double averageEngagementScore;

  /// 用户反馈权重 (0-1)
  double userFeedbackWeight;

  /// 疲劳度阈值
  static const double highFatigueThreshold = 0.8;
  static const double mediumFatigueThreshold = 0.6;

  UserFatigueProfile({
    required this.userId,
    this.lastPushTime,
    this.dailyPushCount = 0,
    this.averageEngagementScore = 0.5,
    this.userFeedbackWeight = 0.3,
  });

  /// 更新用户反馈
  void updateFeedback(double engagementScore) {
    averageEngagementScore =
        (averageEngagementScore * 0.7 + engagementScore * 0.3);
  }

  /// 重置疲劳度
  void reset() {
    dailyPushCount = 0;
    averageEngagementScore = 0.5;
    lastPushTime = null;
  }

  /// 获取当前疲劳度状态
  FatigueLevel get currentFatigueLevel {
    if (dailyPushCount >= 20) return FatigueLevel.high;
    if (dailyPushCount >= 15) return FatigueLevel.medium;
    return FatigueLevel.low;
  }
}

/// 疲劳度级别
enum FatigueLevel {
  low,
  medium,
  high,
}
