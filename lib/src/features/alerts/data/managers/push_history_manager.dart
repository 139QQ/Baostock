import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';

import '../../../../core/utils/logger.dart';
import '../cache/push_history_cache_manager.dart';
import '../models/push_history_record.dart';

/// 推送历史管理器
///
/// 负责推送历史记录的全面管理，包括：
/// - 历史记录的存储和检索
/// - 数据分析和统计
/// - 智能查询和过滤
/// - 历史数据的清理和维护
class PushHistoryManager {
  // 构造函数
  PushHistoryManager._() : _cacheManager = PushHistoryCacheManager.instance;

  // 单例实例
  static PushHistoryManager? _instance;

  /// 获取推送历史管理器的单例实例
  static PushHistoryManager get instance {
    _instance ??= PushHistoryManager._();
    return _instance!;
  }

  // 依赖注入
  late final PushHistoryCacheManager _cacheManager;
  bool _isInitialized = false;

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  /// 初始化推送历史管理器
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      AppLogger.info('🚀 PushHistoryManager: 开始初始化');

      // 初始化缓存管理器
      await _cacheManager.initialize();

      _isInitialized = true;
      AppLogger.info('✅ PushHistoryManager: 初始化成功');
    } catch (e) {
      AppLogger.error('❌ PushHistoryManager: 初始化失败', e);
      rethrow;
    }
  }

  /// 记录推送历史
  Future<bool> recordPushHistory({
    required String id,
    required String pushType,
    required String priority,
    required String title,
    required String content,
    required String channel,
    List<String>? relatedEventIds,
    List<String>? relatedFundCodes,
    List<String>? relatedIndexCodes,
    String? templateId,
    double? personalizationScore,
    int? processingTimeMs,
    String? networkStatus,
    String? userActivityState,
    Map<String, dynamic>? deviceInfo,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isInitialized) {
      AppLogger.error('❌ PushHistoryManager: Not initialized',
          Exception('Push history manager not initialized'));
      return false;
    }

    try {
      final record = PushHistoryRecord(
        id: id,
        pushType: pushType,
        priority: priority,
        title: title,
        content: content,
        timestamp: DateTime.now(),
        isRead: false,
        isClicked: false,
        deliverySuccess: true,
        relatedEventIds: relatedEventIds ?? [],
        relatedFundCodes: relatedFundCodes ?? [],
        relatedIndexCodes: relatedIndexCodes ?? [],
        channel: channel,
        templateId: templateId,
        personalizationScore: personalizationScore ?? 0.0,
        effectivenessScore: 0.0, // 初始为0，后续根据用户行为更新
        processingTimeMs: processingTimeMs ?? 0,
        networkStatus: networkStatus ?? 'unknown',
        userActivityState: userActivityState ?? 'unknown',
        deviceInfo: deviceInfo ?? {},
        metadata: metadata ?? {},
      );

      return await _cacheManager.storePushHistory(record);
    } catch (e) {
      AppLogger.error('❌ PushHistoryManager: Failed to record push history', e);
      return false;
    }
  }

  /// 记录推送失败
  Future<bool> recordPushFailure({
    required String id,
    required String pushType,
    required String priority,
    required String title,
    required String content,
    required String failureReason,
    String? channel,
    int? processingTimeMs,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isInitialized) {
      AppLogger.error('❌ PushHistoryManager: Not initialized',
          Exception('Push history manager not initialized'));
      return false;
    }

    try {
      final record = PushHistoryRecord(
        id: id,
        pushType: pushType,
        priority: priority,
        title: title,
        content: content,
        timestamp: DateTime.now(),
        isRead: false,
        isClicked: false,
        deliverySuccess: false,
        deliveryFailureReason: failureReason,
        relatedEventIds: const [],
        relatedFundCodes: const [],
        relatedIndexCodes: const [],
        channel: channel ?? 'notification',
        personalizationScore: 0.0,
        effectivenessScore: 0.0,
        processingTimeMs: processingTimeMs ?? 0,
        networkStatus: 'failed',
        userActivityState: 'unknown',
        deviceInfo: const {},
        metadata: metadata ?? {},
      );

      return await _cacheManager.storePushHistory(record);
    } catch (e) {
      AppLogger.error('❌ PushHistoryManager: Failed to record push failure', e);
      return false;
    }
  }

  /// 标记推送为已读
  Future<bool> markAsRead(String id) async {
    if (!_isInitialized) {
      AppLogger.error('❌ PushHistoryManager: Not initialized',
          Exception('Push history manager not initialized'));
      return false;
    }

    try {
      final record = await _cacheManager.getPushHistory(id);
      if (record != null && !record.isRead) {
        final updatedRecord = record.markAsRead();
        return await _cacheManager.storePushHistory(updatedRecord);
      }
      return true;
    } catch (e) {
      AppLogger.error(
          '❌ PushHistoryManager: Failed to mark push as read: $id', e);
      return false;
    }
  }

  /// 标记推送为已点击
  Future<bool> markAsClicked(String id) async {
    if (!_isInitialized) {
      AppLogger.error('❌ PushHistoryManager: Not initialized',
          Exception('Push history manager not initialized'));
      return false;
    }

    try {
      final record = await _cacheManager.getPushHistory(id);
      if (record != null && !record.isClicked) {
        final updatedRecord = record.markAsClicked();
        // 更新效果评分
        final effectivenessScore = _calculateEffectivenessScore(updatedRecord);
        final finalRecord =
            updatedRecord.withEffectivenessScore(effectivenessScore);
        return await _cacheManager.storePushHistory(finalRecord);
      }
      return true;
    } catch (e) {
      AppLogger.error(
          '❌ PushHistoryManager: Failed to mark push as clicked: $id', e);
      return false;
    }
  }

  /// 设置用户反馈
  Future<bool> setUserFeedback(String id, String feedback) async {
    if (!_isInitialized) {
      AppLogger.error('❌ PushHistoryManager: Not initialized',
          Exception('Push history manager not initialized'));
      return false;
    }

    try {
      final record = await _cacheManager.getPushHistory(id);
      if (record != null) {
        final updatedRecord = record.withUserFeedback(feedback);
        // 更新效果评分
        final effectivenessScore = _calculateEffectivenessScore(updatedRecord);
        final finalRecord =
            updatedRecord.withEffectivenessScore(effectivenessScore);
        return await _cacheManager.storePushHistory(finalRecord);
      }
      return true;
    } catch (e) {
      AppLogger.error(
          '❌ PushHistoryManager: Failed to set user feedback: $id', e);
      return false;
    }
  }

  /// 获取推送历史记录
  Future<PushHistoryRecord?> getPushHistory(String id) async {
    if (!_isInitialized) {
      AppLogger.error('❌ PushHistoryManager: Not initialized',
          Exception('Push history manager not initialized'));
      return null;
    }

    try {
      return await _cacheManager.getPushHistory(id);
    } catch (e) {
      AppLogger.error(
          '❌ PushHistoryManager: Failed to get push history: $id', e);
      return null;
    }
  }

  /// 按时间范围获取推送历史
  Future<List<PushHistoryRecord>> getPushHistoryByTimeRange({
    DateTime? startTime,
    DateTime? endTime,
    int limit = 100,
    int offset = 0,
  }) async {
    if (!_isInitialized) {
      AppLogger.error('❌ PushHistoryManager: Not initialized',
          Exception('Push history manager not initialized'));
      return [];
    }

    try {
      return await _cacheManager.getPushHistoryByTimeRange(
        startTime: startTime,
        endTime: endTime,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      AppLogger.error(
          '❌ PushHistoryManager: Failed to get push history by time range', e);
      return [];
    }
  }

  /// 按推送类型获取历史记录
  Future<List<PushHistoryRecord>> getPushHistoryByType(
    String pushType, {
    int limit = 100,
  }) async {
    if (!_isInitialized) {
      AppLogger.error('❌ PushHistoryManager: Not initialized',
          Exception('Push history manager not initialized'));
      return [];
    }

    try {
      return await _cacheManager.getPushHistoryByType(pushType, limit: limit);
    } catch (e) {
      AppLogger.error(
          '❌ PushHistoryManager: Failed to get push history by type: $pushType',
          e);
      return [];
    }
  }

  /// 按优先级获取历史记录
  Future<List<PushHistoryRecord>> getPushHistoryByPriority(
    String priority, {
    int limit = 100,
  }) async {
    if (!_isInitialized) {
      AppLogger.error('❌ PushHistoryManager: Not initialized',
          Exception('Push history manager not initialized'));
      return [];
    }

    try {
      return await _cacheManager.getPushHistoryByPriority(priority,
          limit: limit);
    } catch (e) {
      AppLogger.error(
          '❌ PushHistoryManager: Failed to get push history by priority: $priority',
          e);
      return [];
    }
  }

  /// 获取未读推送数量
  Future<int> getUnreadCount() async {
    if (!_isInitialized) {
      AppLogger.error('❌ PushHistoryManager: Not initialized',
          Exception('Push history manager not initialized'));
      return 0;
    }

    try {
      final recentPushes = await _cacheManager.getPushHistoryByTimeRange(
        startTime: DateTime.now().subtract(const Duration(days: 7)),
        limit: 1000,
      );

      return recentPushes.where((push) => !push.isRead).length;
    } catch (e) {
      AppLogger.error('❌ PushHistoryManager: Failed to get unread count', e);
      return 0;
    }
  }

  /// 获取最近推送历史
  Future<List<PushHistoryRecord>> getRecentPushes({
    int limit = 50,
    bool onlyUnread = false,
  }) async {
    if (!_isInitialized) {
      AppLogger.error('❌ PushHistoryManager: Not initialized',
          Exception('Push history manager not initialized'));
      return [];
    }

    try {
      final pushes = await _cacheManager.getPushHistoryByTimeRange(
        startTime: DateTime.now().subtract(const Duration(days: 7)),
        limit: limit,
      );

      if (onlyUnread) {
        return pushes.where((push) => !push.isRead).toList();
      }

      return pushes;
    } catch (e) {
      AppLogger.error('❌ PushHistoryManager: Failed to get recent pushes', e);
      return [];
    }
  }

  /// 获取推送统计信息
  Future<PushStatistics> getPushStatistics({int days = 30}) async {
    if (!_isInitialized) {
      AppLogger.error('❌ PushHistoryManager: Not initialized',
          Exception('Push history manager not initialized'));
      return PushStatistics.empty();
    }

    try {
      final startTime = DateTime.now().subtract(Duration(days: days));
      final pushes = await _cacheManager.getPushHistoryByTimeRange(
        startTime: startTime,
        limit: 10000,
      );

      // 计算统计数据
      final totalPushes = pushes.length;
      final successfulPushes = pushes.where((p) => p.deliverySuccess).length;
      final readPushes = pushes.where((p) => p.isRead).length;
      final clickedPushes = pushes.where((p) => p.isClicked).length;

      final averagePersonalizationScore = pushes.isEmpty
          ? 0.0
          : pushes.map((p) => p.personalizationScore).reduce((a, b) => a + b) /
              pushes.length;

      final averageEffectivenessScore = pushes.isEmpty
          ? 0.0
          : pushes
                  .where((p) => p.effectivenessScore > 0)
                  .map((p) => p.effectivenessScore)
                  .fold(0.0, (a, b) => a + b) /
              pushes.where((p) => p.effectivenessScore > 0).length;

      // 按类型分组统计
      final typeStats = <String, int>{};
      for (final push in pushes) {
        typeStats[push.pushType] = (typeStats[push.pushType] ?? 0) + 1;
      }

      // 按优先级分组统计
      final priorityStats = <String, int>{};
      for (final push in pushes) {
        priorityStats[push.priority] = (priorityStats[push.priority] ?? 0) + 1;
      }

      // 按渠道分组统计
      final channelStats = <String, int>{};
      for (final push in pushes) {
        channelStats[push.channel] = (channelStats[push.channel] ?? 0) + 1;
      }

      // 用户反馈统计
      final feedbackStats = <String, int>{};
      for (final push in pushes) {
        if (push.userFeedback != null) {
          feedbackStats[push.userFeedback!] =
              (feedbackStats[push.userFeedback!] ?? 0) + 1;
        }
      }

      return PushStatistics(
        totalPushes: totalPushes,
        successfulPushes: successfulPushes,
        readPushes: readPushes,
        clickedPushes: clickedPushes,
        averagePersonalizationScore: averagePersonalizationScore,
        averageEffectivenessScore: averageEffectivenessScore,
        typeStats: typeStats,
        priorityStats: priorityStats,
        channelStats: channelStats,
        feedbackStats: feedbackStats,
        periodInDays: days,
      );
    } catch (e) {
      AppLogger.error('❌ PushHistoryManager: Failed to get push statistics', e);
      return PushStatistics.empty();
    }
  }

  /// 获取每日推送统计
  Future<Map<String, DailyStats>> getDailyStatistics({int days = 30}) async {
    if (!_isInitialized) {
      AppLogger.error('❌ PushHistoryManager: Not initialized',
          Exception('Push history manager not initialized'));
      return {};
    }

    try {
      final dailyStats = <String, DailyStats>{};
      final now = DateTime.now();

      for (int i = 0; i < days; i++) {
        final date = now.subtract(Duration(days: i));
        final startTime = DateTime(date.year, date.month, date.day);
        final endTime = startTime.add(const Duration(days: 1));

        final pushes = await _cacheManager.getPushHistoryByTimeRange(
          startTime: startTime,
          endTime: endTime,
          limit: 1000,
        );

        final totalPushes = pushes.length;
        final successfulPushes = pushes.where((p) => p.deliverySuccess).length;
        final readPushes = pushes.where((p) => p.isRead).length;
        final clickedPushes = pushes.where((p) => p.isClicked).length;

        final dateKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        dailyStats[dateKey] = DailyStats(
          date: date,
          totalPushes: totalPushes,
          successfulPushes: successfulPushes,
          readPushes: readPushes,
          clickedPushes: clickedPushes,
        );
      }

      return dailyStats;
    } catch (e) {
      AppLogger.error(
          '❌ PushHistoryManager: Failed to get daily statistics', e);
      return {};
    }
  }

  /// 搜索推送历史
  Future<List<PushHistoryRecord>> searchPushHistory({
    String? keyword,
    String? pushType,
    String? priority,
    DateTime? startTime,
    DateTime? endTime,
    bool? isRead,
    bool? isClicked,
    int limit = 100,
  }) async {
    if (!_isInitialized) {
      AppLogger.error('❌ PushHistoryManager: Not initialized',
          Exception('Push history manager not initialized'));
      return [];
    }

    try {
      // 获取基础数据
      List<PushHistoryRecord> pushes;
      if (startTime != null || endTime != null) {
        pushes = await _cacheManager.getPushHistoryByTimeRange(
          startTime: startTime,
          endTime: endTime,
          limit: 1000,
        );
      } else {
        pushes = await _cacheManager.getPushHistoryByTimeRange(
          startTime: DateTime.now().subtract(const Duration(days: 30)),
          limit: 1000,
        );
      }

      // 应用过滤条件
      var filteredPushes = pushes;

      if (pushType != null) {
        filteredPushes =
            filteredPushes.where((p) => p.pushType == pushType).toList();
      }

      if (priority != null) {
        filteredPushes =
            filteredPushes.where((p) => p.priority == priority).toList();
      }

      if (isRead != null) {
        filteredPushes =
            filteredPushes.where((p) => p.isRead == isRead).toList();
      }

      if (isClicked != null) {
        filteredPushes =
            filteredPushes.where((p) => p.isClicked == isClicked).toList();
      }

      if (keyword != null && keyword.isNotEmpty) {
        filteredPushes = filteredPushes
            .where((p) =>
                p.title.toLowerCase().contains(keyword.toLowerCase()) ||
                p.content.toLowerCase().contains(keyword.toLowerCase()))
            .toList();
      }

      // 按时间戳排序并限制结果数量
      filteredPushes.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return filteredPushes.take(limit).toList();
    } catch (e) {
      AppLogger.error('❌ PushHistoryManager: Failed to search push history', e);
      return [];
    }
  }

  /// 清理过期数据
  Future<void> cleanupExpiredData({Duration? retentionPeriod}) async {
    if (!_isInitialized) {
      AppLogger.error('❌ PushHistoryManager: Not initialized',
          Exception('Push history manager not initialized'));
      return;
    }

    try {
      await _cacheManager.cleanupExpiredData(retentionPeriod: retentionPeriod);
      AppLogger.info('✅ PushHistoryManager: Cleanup completed');
    } catch (e) {
      AppLogger.error(
          '❌ PushHistoryManager: Failed to cleanup expired data', e);
    }
  }

  /// 获取推送效果分析
  Future<PushEffectivenessAnalysis> getEffectivenessAnalysis(
      {int days = 30}) async {
    if (!_isInitialized) {
      AppLogger.error('❌ PushHistoryManager: Not initialized',
          Exception('Push history manager not initialized'));
      return PushEffectivenessAnalysis.empty();
    }

    try {
      final startTime = DateTime.now().subtract(Duration(days: days));
      final pushes = await _cacheManager.getPushHistoryByTimeRange(
        startTime: startTime,
        limit: 10000,
      );

      // 计算点击率
      final totalDelivered = pushes.where((p) => p.deliverySuccess).length;
      final totalClicked = pushes.where((p) => p.isClicked).length;
      final clickRate =
          totalDelivered > 0 ? totalClicked / totalDelivered : 0.0;

      // 计算阅读率
      final totalRead = pushes.where((p) => p.isRead).length;
      final readRate = totalDelivered > 0 ? totalRead / totalDelivered : 0.0;

      // 计算平均个性化评分
      final averagePersonalizationScore = pushes.isEmpty
          ? 0.0
          : pushes.map((p) => p.personalizationScore).reduce((a, b) => a + b) /
              pushes.length;

      // 计算平均效果评分
      final effectivePushes = pushes.where((p) => p.effectivenessScore > 0);
      final averageEffectivenessScore = effectivePushes.isEmpty
          ? 0.0
          : effectivePushes
                  .map((p) => p.effectivenessScore)
                  .reduce((a, b) => a + b) /
              effectivePushes.length;

      // 按推送类型分析
      final typeAnalysis = <String, TypeEffectiveness>{};
      final groupedByType = groupBy(pushes, (p) => p.pushType);
      for (final entry in groupedByType.entries) {
        final typePushes = entry.value;
        final typeDelivered = typePushes.where((p) => p.deliverySuccess).length;
        final typeClicked = typePushes.where((p) => p.isClicked).length;
        final typeRead = typePushes.where((p) => p.isRead).length;

        typeAnalysis[entry.key] = TypeEffectiveness(
          pushType: entry.key,
          totalPushes: typePushes.length,
          deliveredPushes: typeDelivered,
          clickedPushes: typeClicked,
          readPushes: typeRead,
          clickRate: typeDelivered > 0 ? typeClicked / typeDelivered : 0.0,
          readRate: typeDelivered > 0 ? typeRead / typeDelivered : 0.0,
        );
      }

      // 按优先级分析
      final priorityAnalysis = <String, TypeEffectiveness>{};
      final groupedByPriority = groupBy(pushes, (p) => p.priority);
      for (final entry in groupedByPriority.entries) {
        final priorityPushes = entry.value;
        final priorityDelivered =
            priorityPushes.where((p) => p.deliverySuccess).length;
        final priorityClicked = priorityPushes.where((p) => p.isClicked).length;
        final priorityRead = priorityPushes.where((p) => p.isRead).length;

        priorityAnalysis[entry.key] = TypeEffectiveness(
          pushType: entry.key,
          totalPushes: priorityPushes.length,
          deliveredPushes: priorityDelivered,
          clickedPushes: priorityClicked,
          readPushes: priorityRead,
          clickRate:
              priorityDelivered > 0 ? priorityClicked / priorityDelivered : 0.0,
          readRate:
              priorityDelivered > 0 ? priorityRead / priorityDelivered : 0.0,
        );
      }

      return PushEffectivenessAnalysis(
        periodInDays: days,
        totalPushes: pushes.length,
        deliveredPushes: totalDelivered,
        clickedPushes: totalClicked,
        readPushes: totalRead,
        clickRate: clickRate,
        readRate: readRate,
        averagePersonalizationScore: averagePersonalizationScore,
        averageEffectivenessScore: averageEffectivenessScore,
        typeAnalysis: typeAnalysis,
        priorityAnalysis: priorityAnalysis,
      );
    } catch (e) {
      AppLogger.error(
          '❌ PushHistoryManager: Failed to get effectiveness analysis', e);
      return PushEffectivenessAnalysis.empty();
    }
  }

  /// 计算效果评分
  double _calculateEffectivenessScore(PushHistoryRecord record) {
    double score = 0.0;

    // 基础分数：成功送达
    if (record.deliverySuccess) {
      score += 0.3;
    }

    // 阅读加分
    if (record.isRead) {
      score += 0.3;
    }

    // 点击加分
    if (record.isClicked) {
      score += 0.3;
    }

    // 用户反馈加分
    if (record.userFeedback == 'like') {
      score += 0.1;
    } else if (record.userFeedback == 'dislike') {
      score -= 0.1;
    }

    // 时间因素：快速响应加分
    if (record.isClicked && record.clickedAt != null) {
      final responseTime =
          record.clickedAt!.difference(record.timestamp).inMinutes;
      if (responseTime < 5) {
        score += 0.1;
      } else if (responseTime < 30) {
        score += 0.05;
      }
    }

    // 确保评分在0-1范围内
    return max(0.0, min(1.0, score));
  }

  /// 销毁管理器
  Future<void> dispose() async {
    await _cacheManager.dispose();
    _isInitialized = false;
    AppLogger.info('✅ PushHistoryManager: Disposed');
  }
}

/// 推送统计数据
class PushStatistics {
  final int totalPushes;
  final int successfulPushes;
  final int readPushes;
  final int clickedPushes;
  final double averagePersonalizationScore;
  final double averageEffectivenessScore;
  final Map<String, int> typeStats;
  final Map<String, int> priorityStats;
  final Map<String, int> channelStats;
  final Map<String, int> feedbackStats;
  final int periodInDays;

  const PushStatistics({
    required this.totalPushes,
    required this.successfulPushes,
    required this.readPushes,
    required this.clickedPushes,
    required this.averagePersonalizationScore,
    required this.averageEffectivenessScore,
    required this.typeStats,
    required this.priorityStats,
    required this.channelStats,
    required this.feedbackStats,
    required this.periodInDays,
  });

  factory PushStatistics.empty() {
    return const PushStatistics(
      totalPushes: 0,
      successfulPushes: 0,
      readPushes: 0,
      clickedPushes: 0,
      averagePersonalizationScore: 0.0,
      averageEffectivenessScore: 0.0,
      typeStats: {},
      priorityStats: {},
      channelStats: {},
      feedbackStats: {},
      periodInDays: 0,
    );
  }

  /// 成功率
  double get successRate =>
      totalPushes > 0 ? successfulPushes / totalPushes : 0.0;

  /// 阅读率
  double get readRate =>
      successfulPushes > 0 ? readPushes / successfulPushes : 0.0;

  /// 点击率
  double get clickRate =>
      successfulPushes > 0 ? clickedPushes / successfulPushes : 0.0;
}

/// 每日统计数据
class DailyStats {
  final DateTime date;
  final int totalPushes;
  final int successfulPushes;
  final int readPushes;
  final int clickedPushes;

  const DailyStats({
    required this.date,
    required this.totalPushes,
    required this.successfulPushes,
    required this.readPushes,
    required this.clickedPushes,
  });

  /// 成功率
  double get successRate =>
      totalPushes > 0 ? successfulPushes / totalPushes : 0.0;

  /// 阅读率
  double get readRate =>
      successfulPushes > 0 ? readPushes / successfulPushes : 0.0;

  /// 点击率
  double get clickRate =>
      successfulPushes > 0 ? clickedPushes / successfulPushes : 0.0;
}

/// 推送效果分析
class PushEffectivenessAnalysis {
  final int periodInDays;
  final int totalPushes;
  final int deliveredPushes;
  final int clickedPushes;
  final int readPushes;
  final double clickRate;
  final double readRate;
  final double averagePersonalizationScore;
  final double averageEffectivenessScore;
  final Map<String, TypeEffectiveness> typeAnalysis;
  final Map<String, TypeEffectiveness> priorityAnalysis;

  const PushEffectivenessAnalysis({
    required this.periodInDays,
    required this.totalPushes,
    required this.deliveredPushes,
    required this.clickedPushes,
    required this.readPushes,
    required this.clickRate,
    required this.readRate,
    required this.averagePersonalizationScore,
    required this.averageEffectivenessScore,
    required this.typeAnalysis,
    required this.priorityAnalysis,
  });

  factory PushEffectivenessAnalysis.empty() {
    return const PushEffectivenessAnalysis(
      periodInDays: 0,
      totalPushes: 0,
      deliveredPushes: 0,
      clickedPushes: 0,
      readPushes: 0,
      clickRate: 0.0,
      readRate: 0.0,
      averagePersonalizationScore: 0.0,
      averageEffectivenessScore: 0.0,
      typeAnalysis: {},
      priorityAnalysis: {},
    );
  }
}

/// 类型效果分析
class TypeEffectiveness {
  final String pushType;
  final int totalPushes;
  final int deliveredPushes;
  final int clickedPushes;
  final int readPushes;
  final double clickRate;
  final double readRate;

  const TypeEffectiveness({
    required this.pushType,
    required this.totalPushes,
    required this.deliveredPushes,
    required this.clickedPushes,
    required this.readPushes,
    required this.clickRate,
    required this.readRate,
  });
}
