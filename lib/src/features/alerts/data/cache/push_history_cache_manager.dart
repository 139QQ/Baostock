import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/utils/logger.dart';
import '../models/push_history_record.dart';

/// 推送历史缓存管理器
///
/// 专门负责推送历史数据的缓存管理，包括：
/// - 推送记录的存储和检索
/// - 历史数据的分析和统计
/// - 过期数据的自动清理
/// - 多维度查询支持
class PushHistoryCacheManager {
  // 构造函数
  PushHistoryCacheManager._();

  // 单例实例
  static PushHistoryCacheManager? _instance;

  /// 获取推送历史缓存管理器的单例实例
  static PushHistoryCacheManager get instance {
    _instance ??= PushHistoryCacheManager._();
    return _instance!;
  }

  // Hive boxes
  Box? _pushHistoryBox;
  Box? _pushStatisticsBox;
  Box? _pushIndexBox;

  // 状态管理
  bool _isInitialized = false;
  Timer? _cleanupTimer;

  // 配置常量
  static const String _pushHistoryBoxName = 'push_history_cache';
  static const String _pushStatisticsBoxName = 'push_statistics_cache';
  static const String _pushIndexBoxName = 'push_index_cache';
  static const int _maxHistoryRecords = 10000; // 最大历史记录数
  static const Duration _defaultRetentionPeriod = Duration(days: 90); // 默认保留期
  static const Duration _cleanupInterval = Duration(hours: 6); // 清理间隔

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  /// 初始化推送历史缓存管理器
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      AppLogger.info('🚀 PushHistoryCacheManager: 开始初始化');

      // 打开Hive boxes
      await _openBoxes();

      // 启动定期清理任务
      _startCleanupTimer();

      _isInitialized = true;
      AppLogger.info('✅ PushHistoryCacheManager: 初始化成功');
    } catch (e) {
      AppLogger.error('❌ PushHistoryCacheManager: 初始化失败', e);
      rethrow;
    }
  }

  /// 打开Hive boxes
  Future<void> _openBoxes() async {
    try {
      _pushHistoryBox = await Hive.openBox(_pushHistoryBoxName);
      _pushStatisticsBox = await Hive.openBox(_pushStatisticsBoxName);
      _pushIndexBox = await Hive.openBox(_pushIndexBoxName);

      AppLogger.debug(
          '✅ PushHistoryCacheManager: Hive boxes opened successfully');
    } catch (e) {
      AppLogger.error(
          '❌ PushHistoryCacheManager: Failed to open Hive boxes', e);
      rethrow;
    }
  }

  /// 存储推送历史记录
  Future<bool> storePushHistory(PushHistoryRecord record) async {
    if (!_isInitialized || _pushHistoryBox == null) {
      AppLogger.error('❌ PushHistoryCacheManager: Not initialized',
          Exception('Cache manager not initialized'));
      return false;
    }

    try {
      // 生成唯一键
      final key = _generateHistoryKey(record);

      // 存储记录
      await _pushHistoryBox!.put(key, record.toJson());

      // 更新索引
      await _updateIndexes(record);

      // 更新统计信息
      await _updateStatistics(record);

      // 检查存储限制
      await _enforceStorageLimits();

      AppLogger.debug(
          '✅ PushHistoryCacheManager: Stored push history: ${record.id}');
      return true;
    } catch (e) {
      AppLogger.error(
          '❌ PushHistoryCacheManager: Failed to store push history', e);
      return false;
    }
  }

  /// 批量存储推送历史记录
  Future<bool> storePushHistoryBatch(List<PushHistoryRecord> records) async {
    if (!_isInitialized || _pushHistoryBox == null) {
      AppLogger.error('❌ PushHistoryCacheManager: Not initialized',
          Exception('Cache manager not initialized'));
      return false;
    }

    try {
      final batch = <String, dynamic>{};
      final indexUpdates = <PushHistoryRecord>[];

      for (final record in records) {
        final key = _generateHistoryKey(record);
        batch[key] = record.toJson();
        indexUpdates.add(record);
      }

      // 批量存储
      await _pushHistoryBox!.putAll(batch);

      // 批量更新索引
      for (final record in indexUpdates) {
        await _updateIndexes(record);
        await _updateStatistics(record);
      }

      // 检查存储限制
      await _enforceStorageLimits();

      AppLogger.info(
          '✅ PushHistoryCacheManager: Batch stored ${records.length} push history records');
      return true;
    } catch (e) {
      AppLogger.error(
          '❌ PushHistoryCacheManager: Failed to batch store push history', e);
      return false;
    }
  }

  /// 获取推送历史记录
  Future<PushHistoryRecord?> getPushHistory(String id) async {
    if (!_isInitialized || _pushHistoryBox == null) {
      AppLogger.error('❌ PushHistoryCacheManager: Not initialized',
          Exception('Cache manager not initialized'));
      return null;
    }

    try {
      final key = 'push_$id';
      final data = _pushHistoryBox!.get(key);

      if (data != null) {
        return PushHistoryRecord.fromJson(Map<String, dynamic>.from(data));
      }

      return null;
    } catch (e) {
      AppLogger.error(
          '❌ PushHistoryCacheManager: Failed to get push history: $id', e);
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
    if (!_isInitialized || _pushHistoryBox == null) {
      AppLogger.error('❌ PushHistoryCacheManager: Not initialized',
          Exception('Cache manager not initialized'));
      return [];
    }

    try {
      final records = <PushHistoryRecord>[];
      final now = DateTime.now();
      final effectiveStartTime =
          startTime ?? now.subtract(const Duration(days: 30));
      final effectiveEndTime = endTime ?? now;

      // 按时间戳索引查找
      final timeIndexKey = _getTimeIndexKey(effectiveStartTime);
      final indexKeys = _pushIndexBox!.keys
          .where((key) =>
              key.toString().startsWith('time_') &&
              key.toString().compareTo(timeIndexKey) >= 0)
          .toList();

      indexKeys.sort();

      for (final key in indexKeys.take(limit + offset)) {
        final recordIds = List<String>.from(_pushIndexBox!.get(key) ?? []);
        for (final recordId in recordIds) {
          final record = await getPushHistory(recordId);
          if (record != null &&
              record.timestamp.isAfter(effectiveStartTime) &&
              record.timestamp.isBefore(effectiveEndTime)) {
            records.add(record);
          }
        }
      }

      // 按时间戳排序
      records.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return records.skip(offset).take(limit).toList();
    } catch (e) {
      AppLogger.error(
          '❌ PushHistoryCacheManager: Failed to get push history by time range',
          e);
      return [];
    }
  }

  /// 按推送类型获取历史记录
  Future<List<PushHistoryRecord>> getPushHistoryByType(String pushType,
      {int limit = 100}) async {
    if (!_isInitialized || _pushIndexBox == null) {
      AppLogger.error('❌ PushHistoryCacheManager: Not initialized',
          Exception('Cache manager not initialized'));
      return [];
    }

    try {
      final typeIndexKey = 'type_$pushType';
      final recordIds =
          List<String>.from(_pushIndexBox!.get(typeIndexKey) ?? []);
      final records = <PushHistoryRecord>[];

      for (final recordId in recordIds.take(limit)) {
        final record = await getPushHistory(recordId);
        if (record != null) {
          records.add(record);
        }
      }

      // 按时间戳排序
      records.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return records;
    } catch (e) {
      AppLogger.error(
          '❌ PushHistoryCacheManager: Failed to get push history by type: $pushType',
          e);
      return [];
    }
  }

  /// 按优先级获取历史记录
  Future<List<PushHistoryRecord>> getPushHistoryByPriority(String priority,
      {int limit = 100}) async {
    if (!_isInitialized || _pushIndexBox == null) {
      AppLogger.error('❌ PushHistoryCacheManager: Not initialized',
          Exception('Cache manager not initialized'));
      return [];
    }

    try {
      final priorityIndexKey = 'priority_$priority';
      final recordIds =
          List<String>.from(_pushIndexBox!.get(priorityIndexKey) ?? []);
      final records = <PushHistoryRecord>[];

      for (final recordId in recordIds.take(limit)) {
        final record = await getPushHistory(recordId);
        if (record != null) {
          records.add(record);
        }
      }

      // 按时间戳排序
      records.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return records;
    } catch (e) {
      AppLogger.error(
          '❌ PushHistoryCacheManager: Failed to get push history by priority: $priority',
          e);
      return [];
    }
  }

  /// 获取推送统计信息
  Future<Map<String, dynamic>> getPushStatistics() async {
    if (!_isInitialized || _pushStatisticsBox == null) {
      AppLogger.error('❌ PushHistoryCacheManager: Not initialized',
          Exception('Cache manager not initialized'));
      return {};
    }

    try {
      final stats = _pushStatisticsBox!.get('global_stats') ?? {};
      return Map<String, dynamic>.from(stats);
    } catch (e) {
      AppLogger.error(
          '❌ PushHistoryCacheManager: Failed to get push statistics', e);
      return {};
    }
  }

  /// 按日期分组获取推送统计
  Future<Map<String, int>> getDailyPushStats({int days = 30}) async {
    if (!_isInitialized || _pushStatisticsBox == null) {
      AppLogger.error('❌ PushHistoryCacheManager: Not initialized',
          Exception('Cache manager not initialized'));
      return {};
    }

    try {
      final dailyStats = <String, int>{};
      final now = DateTime.now();

      for (int i = 0; i < days; i++) {
        final date = now.subtract(Duration(days: i));
        final dateKey = _getDateKey(date);
        final count = _pushStatisticsBox!.get(dateKey) ?? 0;
        dailyStats[dateKey] = count as int;
      }

      return dailyStats;
    } catch (e) {
      AppLogger.error(
          '❌ PushHistoryCacheManager: Failed to get daily push stats', e);
      return {};
    }
  }

  /// 清理过期数据
  Future<void> cleanupExpiredData({Duration? retentionPeriod}) async {
    if (!_isInitialized || _pushHistoryBox == null) {
      AppLogger.error('❌ PushHistoryCacheManager: Not initialized',
          Exception('Cache manager not initialized'));
      return;
    }

    try {
      final retention = retentionPeriod ?? _defaultRetentionPeriod;
      final cutoffTime = DateTime.now().subtract(retention);
      int deletedCount = 0;

      // 查找过期记录
      final expiredKeys = <String>[];
      for (final key in _pushHistoryBox!.keys) {
        final data = _pushHistoryBox!.get(key);
        if (data != null) {
          final timestamp = DateTime.parse(data['timestamp'] as String);
          if (timestamp.isBefore(cutoffTime)) {
            expiredKeys.add(key.toString());
          }
        }
      }

      // 删除过期记录
      for (final key in expiredKeys) {
        await _pushHistoryBox!.delete(key);
        deletedCount++;
      }

      // 重建索引
      await _rebuildIndexes();

      AppLogger.info(
          '✅ PushHistoryCacheManager: Cleaned up $deletedCount expired records');
    } catch (e) {
      AppLogger.error(
          '❌ PushHistoryCacheManager: Failed to cleanup expired data', e);
    }
  }

  /// 生成历史记录键
  String _generateHistoryKey(PushHistoryRecord record) {
    return 'push_${record.id}';
  }

  /// 生成时间索引键
  String _getTimeIndexKey(DateTime timestamp) {
    return 'time_${timestamp.year}_${timestamp.month}_${timestamp.day}';
  }

  /// 生成日期键
  String _getDateKey(DateTime date) {
    return '${date.year}_${date.month}_${date.day}';
  }

  /// 更新索引
  Future<void> _updateIndexes(PushHistoryRecord record) async {
    if (_pushIndexBox == null) return;

    try {
      // 时间索引
      final timeIndexKey = _getTimeIndexKey(record.timestamp);
      final timeIndex =
          List<String>.from(_pushIndexBox!.get(timeIndexKey) ?? []);
      if (!timeIndex.contains(record.id)) {
        timeIndex.add(record.id);
        await _pushIndexBox!.put(timeIndexKey, timeIndex);
      }

      // 类型索引
      final typeIndexKey = 'type_${record.pushType}';
      final typeIndex =
          List<String>.from(_pushIndexBox!.get(typeIndexKey) ?? []);
      if (!typeIndex.contains(record.id)) {
        typeIndex.add(record.id);
        await _pushIndexBox!.put(typeIndexKey, typeIndex);
      }

      // 优先级索引
      final priorityIndexKey = 'priority_${record.priority}';
      final priorityIndex =
          List<String>.from(_pushIndexBox!.get(priorityIndexKey) ?? []);
      if (!priorityIndex.contains(record.id)) {
        priorityIndex.add(record.id);
        await _pushIndexBox!.put(priorityIndexKey, priorityIndex);
      }
    } catch (e) {
      AppLogger.error('❌ PushHistoryCacheManager: Failed to update indexes', e);
    }
  }

  /// 更新统计信息
  Future<void> _updateStatistics(PushHistoryRecord record) async {
    if (_pushStatisticsBox == null) return;

    try {
      // 更新全局统计
      final globalStats = Map<String, dynamic>.from(
          _pushStatisticsBox!.get('global_stats') ?? {});
      globalStats['total_pushes'] = (globalStats['total_pushes'] ?? 0) + 1;
      globalStats['last_updated'] = DateTime.now().toIso8601String();
      await _pushStatisticsBox!.put('global_stats', globalStats);

      // 更新日期统计
      final dateKey = _getDateKey(record.timestamp);
      final dailyCount = _pushStatisticsBox!.get(dateKey) ?? 0;
      await _pushStatisticsBox!.put(dateKey, dailyCount + 1);

      // 更新类型统计
      final typeStatsKey = 'type_stats_${record.pushType}';
      final typeStats = Map<String, dynamic>.from(
          _pushStatisticsBox!.get(typeStatsKey) ?? {});
      typeStats['count'] = (typeStats['count'] ?? 0) + 1;
      typeStats['last_updated'] = DateTime.now().toIso8601String();
      await _pushStatisticsBox!.put(typeStatsKey, typeStats);
    } catch (e) {
      AppLogger.error(
          '❌ PushHistoryCacheManager: Failed to update statistics', e);
    }
  }

  /// 强制执行存储限制
  Future<void> _enforceStorageLimits() async {
    if (_pushHistoryBox == null) return;

    try {
      final currentSize = _pushHistoryBox!.length;
      if (currentSize <= _maxHistoryRecords) return;

      final recordsToDelete = currentSize - _maxHistoryRecords;
      final allKeys = _pushHistoryBox!.keys.toList();

      // 按时间戳排序，删除最旧的记录
      final sortedKeys = <String>[];
      for (final key in allKeys) {
        final data = _pushHistoryBox!.get(key);
        if (data != null) {
          sortedKeys.add(key.toString());
        }
      }

      sortedKeys.sort((a, b) {
        final dataA = _pushHistoryBox!.get(a);
        final dataB = _pushHistoryBox!.get(b);
        if (dataA != null && dataB != null) {
          final timestampA = DateTime.parse(dataA['timestamp'] as String);
          final timestampB = DateTime.parse(dataB['timestamp'] as String);
          return timestampA.compareTo(timestampB);
        }
        return 0;
      });

      // 删除最旧的记录
      for (int i = 0; i < recordsToDelete && i < sortedKeys.length; i++) {
        await _pushHistoryBox!.delete(sortedKeys[i]);
      }

      // 重建索引
      await _rebuildIndexes();

      AppLogger.info(
          '✅ PushHistoryCacheManager: Deleted $recordsToDelete old records to enforce storage limits');
    } catch (e) {
      AppLogger.error(
          '❌ PushHistoryCacheManager: Failed to enforce storage limits', e);
    }
  }

  /// 重建索引
  Future<void> _rebuildIndexes() async {
    if (_pushHistoryBox == null || _pushIndexBox == null) return;

    try {
      // 清空现有索引
      await _pushIndexBox!.clear();

      // 重建索引
      for (final key in _pushHistoryBox!.keys) {
        final data = _pushHistoryBox!.get(key);
        if (data != null) {
          final record =
              PushHistoryRecord.fromJson(Map<String, dynamic>.from(data));
          await _updateIndexes(record);
        }
      }

      AppLogger.debug(
          '✅ PushHistoryCacheManager: Indexes rebuilt successfully');
    } catch (e) {
      AppLogger.error(
          '❌ PushHistoryCacheManager: Failed to rebuild indexes', e);
    }
  }

  /// 启动清理定时器
  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(_cleanupInterval, (_) {
      cleanupExpiredData();
    });
    AppLogger.debug('✅ PushHistoryCacheManager: Cleanup timer started');
  }

  /// 销毁缓存管理器
  Future<void> dispose() async {
    _cleanupTimer?.cancel();

    await _pushHistoryBox?.close();
    await _pushStatisticsBox?.close();
    await _pushIndexBox?.close();

    _isInitialized = false;
    AppLogger.info('✅ PushHistoryCacheManager: Disposed');
  }
}
