/// 缓存迁移进度跟踪器测试
library progress_tracker_test;

import 'dart:async';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';

/// 进度状态枚举
enum ProgressStatus {
  /// 未开始
  notStarted,

  /// 进行中
  inProgress,

  /// 已暂停
  paused,

  /// 已完成
  completed,

  /// 已失败
  failed,

  /// 已取消
  cancelled,
}

/// 进度事件类
class ProgressEvent {
  final String operationId;
  final ProgressStatus status;
  final int totalItems;
  final int processedItems;
  final int failedItems;
  final int skippedItems;
  final String? currentItem;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  final String? message;

  const ProgressEvent({
    required this.operationId,
    required this.status,
    required this.totalItems,
    required this.processedItems,
    required this.failedItems,
    required this.skippedItems,
    this.currentItem,
    required this.timestamp,
    this.metadata = const {},
    this.message,
  });

  /// 获取进度百分比
  double get progressPercentage {
    if (totalItems == 0) return 0.0;
    return processedItems / totalItems;
  }

  /// 获取成功率
  double get successRate {
    final attemptedItems = processedItems + failedItems;
    if (attemptedItems == 0) return 0.0;
    return processedItems / attemptedItems;
  }

  /// 是否已完成
  bool get isCompleted => status == ProgressStatus.completed;

  /// 是否正在进行中
  bool get isInProgress => status == ProgressStatus.inProgress;

  /// 是否已失败
  bool get isFailed => status == ProgressStatus.failed;

  @override
  String toString() {
    return 'ProgressEvent(id: $operationId, status: $status, progress: ${(progressPercentage * 100).toStringAsFixed(1)}%, item: $currentItem)';
  }
}

/// 进度统计信息类
class ProgressStatistics {
  final String operationId;
  final Duration duration;
  final double averageSpeed;
  final int peakSpeed;
  final int totalItems;
  final int processedItems;
  final int failedItems;
  final int skippedItems;
  final Map<String, int> statusCounts;

  const ProgressStatistics({
    required this.operationId,
    required this.duration,
    required this.averageSpeed,
    required this.peakSpeed,
    required this.totalItems,
    required this.processedItems,
    required this.failedItems,
    required this.skippedItems,
    required this.statusCounts,
  });

  /// 获取吞吐量（项目/秒）
  double get throughput {
    if (duration.inSeconds == 0) return 0.0;
    return processedItems / duration.inSeconds;
  }

  @override
  String toString() {
    return 'ProgressStats(id: $operationId, duration: ${duration.inSeconds}s, throughput: ${throughput.toStringAsFixed(1)}/s)';
  }
}

/// 进度回调类型
typedef ProgressCallback = void Function(ProgressEvent event);

/// 简化的进度跟踪器实现
class CacheMigrationProgressTracker {
  final Map<String, List<ProgressEvent>> _eventHistory = {};
  final Map<String, ProgressEvent> _latestEvents = {};
  final Map<String, DateTime> _startTimes = {};
  final Map<String, ProgressCallback> _callbacks = {};
  final Map<String, Timer> _timers = {};
  final Random _random = Random();

  /// 开始跟踪进度
  void startTracking(
    String operationId,
    int totalItems, {
    ProgressCallback? callback,
    Duration? updateInterval,
  }) {
    final startTime = DateTime.now();
    _startTimes[operationId] = startTime;

    // 创建初始事件
    final initialEvent = ProgressEvent(
      operationId: operationId,
      status: ProgressStatus.inProgress,
      totalItems: totalItems,
      processedItems: 0,
      failedItems: 0,
      skippedItems: 0,
      timestamp: startTime,
      message: '开始操作',
    );

    _addEvent(operationId, initialEvent);

    if (callback != null) {
      _callbacks[operationId] = callback;
    }

    // 启动定时更新
    if (updateInterval != null) {
      _startPeriodicUpdate(operationId, updateInterval);
    }
  }

  /// 更新进度
  void updateProgress(
    String operationId, {
    int? processedItems,
    int? failedItems,
    int? skippedItems,
    String? currentItem,
    String? message,
    Map<String, dynamic>? metadata,
  }) {
    final latestEvent = _latestEvents[operationId];
    if (latestEvent == null) return;

    final newEvent = ProgressEvent(
      operationId: operationId,
      status: ProgressStatus.inProgress,
      totalItems: latestEvent.totalItems,
      processedItems: processedItems ?? latestEvent.processedItems,
      failedItems: failedItems ?? latestEvent.failedItems,
      skippedItems: skippedItems ?? latestEvent.skippedItems,
      currentItem: currentItem,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
      message: message,
    );

    _addEvent(operationId, newEvent);
  }

  /// 完成跟踪
  void completeTracking(String operationId, {String? message}) {
    final latestEvent = _latestEvents[operationId];
    if (latestEvent == null) return;

    final finalEvent = ProgressEvent(
      operationId: operationId,
      status: ProgressStatus.completed,
      totalItems: latestEvent.totalItems,
      processedItems: latestEvent.processedItems,
      failedItems: latestEvent.failedItems,
      skippedItems: latestEvent.skippedItems,
      currentItem: latestEvent.currentItem,
      timestamp: DateTime.now(),
      message: message ?? '操作完成',
    );

    _addEvent(operationId, finalEvent);
    _stopPeriodicUpdate(operationId);
  }

  /// 失败跟踪
  void failTracking(String operationId, String error, {String? currentItem}) {
    final latestEvent = _latestEvents[operationId];
    if (latestEvent == null) return;

    final finalEvent = ProgressEvent(
      operationId: operationId,
      status: ProgressStatus.failed,
      totalItems: latestEvent.totalItems,
      processedItems: latestEvent.processedItems,
      failedItems: latestEvent.failedItems + 1,
      skippedItems: latestEvent.skippedItems,
      currentItem: currentItem,
      timestamp: DateTime.now(),
      message: '操作失败: $error',
    );

    _addEvent(operationId, finalEvent);
    _stopPeriodicUpdate(operationId);
  }

  /// 暂停跟踪
  void pauseTracking(String operationId, {String? reason}) {
    final latestEvent = _latestEvents[operationId];
    if (latestEvent == null) return;

    final pauseEvent = ProgressEvent(
      operationId: operationId,
      status: ProgressStatus.paused,
      totalItems: latestEvent.totalItems,
      processedItems: latestEvent.processedItems,
      failedItems: latestEvent.failedItems,
      skippedItems: latestEvent.skippedItems,
      currentItem: latestEvent.currentItem,
      timestamp: DateTime.now(),
      message: reason ?? '操作已暂停',
    );

    _addEvent(operationId, pauseEvent);
    _stopPeriodicUpdate(operationId);
  }

  /// 取消跟踪
  void cancelTracking(String operationId, {String? reason}) {
    final latestEvent = _latestEvents[operationId];
    if (latestEvent == null) return;

    final cancelEvent = ProgressEvent(
      operationId: operationId,
      status: ProgressStatus.cancelled,
      totalItems: latestEvent.totalItems,
      processedItems: latestEvent.processedItems,
      failedItems: latestEvent.failedItems,
      skippedItems: latestEvent.skippedItems,
      currentItem: latestEvent.currentItem,
      timestamp: DateTime.now(),
      message: reason ?? '操作已取消',
    );

    _addEvent(operationId, cancelEvent);
    _stopPeriodicUpdate(operationId);
  }

  /// 获取最新进度事件
  ProgressEvent? getLatestEvent(String operationId) {
    return _latestEvents[operationId];
  }

  /// 获取进度历史
  List<ProgressEvent> getEventHistory(String operationId) {
    return _eventHistory[operationId] ?? [];
  }

  /// 获取当前进度百分比
  double getProgressPercentage(String operationId) {
    final event = _latestEvents[operationId];
    return event?.progressPercentage ?? 0.0;
  }

  /// 获取当前成功率
  double getSuccessRate(String operationId) {
    final event = _latestEvents[operationId];
    return event?.successRate ?? 0.0;
  }

  /// 获取统计信息
  ProgressStatistics getStatistics(String operationId) {
    final events = _eventHistory[operationId] ?? [];
    if (events.isEmpty) {
      return ProgressStatistics(
        operationId: operationId,
        duration: Duration.zero,
        averageSpeed: 0.0,
        peakSpeed: 0,
        totalItems: 0,
        processedItems: 0,
        failedItems: 0,
        skippedItems: 0,
        statusCounts: {},
      );
    }

    final startTime = _startTimes[operationId] ?? events.first.timestamp;
    final endTime = events.last.timestamp;
    final duration = endTime.difference(startTime);

    final latestEvent = events.last;
    final statusCounts = <String, int>{};

    for (final event in events) {
      statusCounts[event.status.name] =
          (statusCounts[event.status.name] ?? 0) + 1;
    }

    // 计算平均速度和峰值速度
    final speeds = <int>[];
    for (int i = 1; i < events.length; i++) {
      final timeDiff = events[i]
          .timestamp
          .difference(events[i - 1].timestamp)
          .inMilliseconds;
      if (timeDiff > 0) {
        final itemsDiff =
            events[i].processedItems - events[i - 1].processedItems;
        final speed = (itemsDiff * 1000) ~/ timeDiff; // 项目/秒
        if (speed > 0) speeds.add(speed);
      }
    }

    final averageSpeed =
        speeds.isEmpty ? 0.0 : speeds.reduce((a, b) => a + b) / speeds.length;
    final peakSpeed = speeds.isEmpty ? 0 : speeds.reduce(max);

    return ProgressStatistics(
      operationId: operationId,
      duration: duration,
      averageSpeed: averageSpeed,
      peakSpeed: peakSpeed,
      totalItems: latestEvent.totalItems,
      processedItems: latestEvent.processedItems,
      failedItems: latestEvent.failedItems,
      skippedItems: latestEvent.skippedItems,
      statusCounts: statusCounts,
    );
  }

  /// 获取所有活动的操作ID
  List<String> getActiveOperations() {
    return _latestEvents.keys
        .where((id) => _latestEvents[id]?.isInProgress == true)
        .toList();
  }

  /// 清除操作历史
  void clearOperationHistory(String operationId) {
    _eventHistory.remove(operationId);
    _latestEvents.remove(operationId);
    _startTimes.remove(operationId);
    _callbacks.remove(operationId);
    _stopPeriodicUpdate(operationId);
  }

  /// 清除所有历史
  void clearAllHistory() {
    final operationIds = _eventHistory.keys.toList();
    for (final id in operationIds) {
      clearOperationHistory(id);
    }
  }

  /// 添加事件到历史记录
  void _addEvent(String operationId, ProgressEvent event) {
    if (!_eventHistory.containsKey(operationId)) {
      _eventHistory[operationId] = [];
    }

    _eventHistory[operationId]!.add(event);
    _latestEvents[operationId] = event;

    // 触发回调
    final callback = _callbacks[operationId];
    if (callback != null) {
      callback(event);
    }
  }

  /// 启动定期更新
  void _startPeriodicUpdate(String operationId, Duration interval) {
    _timers[operationId] = Timer.periodic(interval, (timer) {
      final latestEvent = _latestEvents[operationId];
      if (latestEvent == null ||
          latestEvent.isCompleted ||
          latestEvent.isFailed) {
        timer.cancel();
        return;
      }

      // 生成自动进度更新（模拟）
      final newProcessedCount = latestEvent.processedItems + _random.nextInt(3);
      final shouldFail = _random.nextDouble() < 0.05; // 5% 失败率

      if (shouldFail && newProcessedCount < latestEvent.totalItems) {
        failTracking(operationId, '模拟随机失败');
      } else if (newProcessedCount <= latestEvent.totalItems) {
        updateProgress(
          operationId,
          processedItems: newProcessedCount,
          message: '自动更新进度',
        );
      }
    });
  }

  /// 停止定期更新
  void _stopPeriodicUpdate(String operationId) {
    final timer = _timers[operationId];
    if (timer != null) {
      timer.cancel();
      _timers.remove(operationId);
    }
  }

  /// 获取跟踪器统计信息
  Map<String, dynamic> getTrackerStatistics() {
    final allOperations = _eventHistory.keys.toList();
    final activeOperations = getActiveOperations();
    final completedOperations = allOperations
        .where((id) => _latestEvents[id]?.isCompleted == true)
        .toList();
    final failedOperations = allOperations
        .where((id) => _latestEvents[id]?.isFailed == true)
        .toList();

    return {
      'total_operations': allOperations.length,
      'active_operations': activeOperations.length,
      'completed_operations': completedOperations.length,
      'failed_operations': failedOperations.length,
      'total_events_processed':
          _eventHistory.values.fold(0, (sum, events) => sum + events.length),
      'active_timers': _timers.length,
      'registered_callbacks': _callbacks.length,
    };
  }
}

void main() {
  group('缓存迁移进度跟踪器基础功能测试', () {
    late CacheMigrationProgressTracker tracker;

    setUp(() {
      tracker = CacheMigrationProgressTracker();
    });

    tearDown(() {
      tracker.clearAllHistory();
    });

    test('应该正确开始和跟踪进度', () {
      const operationId = 'test_operation';
      const totalItems = 100;

      tracker.startTracking(operationId, totalItems);

      final latestEvent = tracker.getLatestEvent(operationId);
      expect(latestEvent, isNotNull);
      expect(latestEvent!.operationId, equals(operationId));
      expect(latestEvent.totalItems, equals(totalItems));
      expect(latestEvent.processedItems, equals(0));
      expect(latestEvent.status, equals(ProgressStatus.inProgress));
      expect(latestEvent.progressPercentage, equals(0.0));
    });

    test('应该正确更新进度', () {
      const operationId = 'test_operation';
      const totalItems = 100;

      tracker.startTracking(operationId, totalItems);

      // 更新进度
      tracker.updateProgress(operationId,
          processedItems: 25, currentItem: 'item_25');

      final latestEvent = tracker.getLatestEvent(operationId);
      expect(latestEvent!.processedItems, equals(25));
      expect(latestEvent.progressPercentage, equals(0.25));
      expect(latestEvent.currentItem, equals('item_25'));
      expect(latestEvent.status, equals(ProgressStatus.inProgress));
    });

    test('应该正确完成跟踪', () {
      const operationId = 'test_operation';
      const totalItems = 100;

      tracker.startTracking(operationId, totalItems);
      tracker.updateProgress(operationId, processedItems: 100);
      tracker.completeTracking(operationId, message: '所有项目处理完成');

      final latestEvent = tracker.getLatestEvent(operationId);
      expect(latestEvent!.status, equals(ProgressStatus.completed));
      expect(latestEvent.processedItems, equals(100));
      expect(latestEvent.progressPercentage, equals(1.0));
      expect(latestEvent.message, equals('所有项目处理完成'));
    });

    test('应该正确处理失败情况', () {
      const operationId = 'test_operation';
      const totalItems = 100;

      tracker.startTracking(operationId, totalItems);
      tracker.updateProgress(operationId, processedItems: 50);
      tracker.failTracking(operationId, '网络连接错误', currentItem: 'item_51');

      final latestEvent = tracker.getLatestEvent(operationId);
      expect(latestEvent!.status, equals(ProgressStatus.failed));
      expect(latestEvent.processedItems, equals(50));
      expect(latestEvent.failedItems, equals(1));
      expect(latestEvent.message, equals('操作失败: 网络连接错误'));
      expect(latestEvent.currentItem, equals('item_51'));
    });

    test('应该正确处理暂停和取消', () {
      const operationId = 'test_operation';
      const totalItems = 100;

      tracker.startTracking(operationId, totalItems);
      tracker.updateProgress(operationId, processedItems: 30);

      // 暂停
      tracker.pauseTracking(operationId, reason: '用户请求暂停');
      var latestEvent = tracker.getLatestEvent(operationId);
      expect(latestEvent!.status, equals(ProgressStatus.paused));
      expect(latestEvent.message, equals('操作已暂停: 用户请求暂停'));

      // 取消
      tracker.cancelTracking(operationId, reason: '用户取消操作');
      latestEvent = tracker.getLatestEvent(operationId);
      expect(latestEvent!.status, equals(ProgressStatus.cancelled));
      expect(latestEvent.message, equals('操作已取消: 用户取消操作'));
    });
  });

  group('缓存迁移进度跟踪器回调测试', () {
    late CacheMigrationProgressTracker tracker;
    final capturedEvents = <ProgressEvent>[];

    setUp(() {
      tracker = CacheMigrationProgressTracker();
      capturedEvents.clear();
    });

    tearDown(() {
      tracker.clearAllHistory();
    });

    test('应该正确触发进度回调', () async {
      const operationId = 'test_operation';
      const totalItems = 10;

      tracker.startTracking(
        operationId,
        totalItems,
        callback: (event) => capturedEvents.add(event),
      );

      // 等待一小段时间让事件被处理
      await Future.delayed(const Duration(milliseconds: 100));

      // 手动更新进度
      for (int i = 1; i <= 5; i++) {
        tracker.updateProgress(operationId, processedItems: i);
        await Future.delayed(const Duration(milliseconds: 10));
      }

      tracker.completeTracking(operationId);

      // 验证捕获的事件
      expect(capturedEvents, isNotEmpty);
      expect(capturedEvents.first.operationId, equals(operationId));
      expect(capturedEvents.last.status, equals(ProgressStatus.completed));

      // 应该包含开始事件和完成事件
      final statusEvents = capturedEvents.map((e) => e.status).toList();
      expect(statusEvents, contains(ProgressStatus.inProgress));
      expect(statusEvents, contains(ProgressStatus.completed));
    });

    test('应该支持多个操作的独立回调', () async {
      const operationId1 = 'operation_1';
      const operationId2 = 'operation_2';
      final events1 = <ProgressEvent>[];
      final events2 = <ProgressEvent>[];

      tracker.startTracking(operationId1, 50,
          callback: (event) => events1.add(event));
      tracker.startTracking(operationId2, 30,
          callback: (event) => events2.add(event));

      await Future.delayed(const Duration(milliseconds: 50));

      tracker.updateProgress(operationId1, processedItems: 25);
      tracker.updateProgress(operationId2, processedItems: 15);

      await Future.delayed(const Duration(milliseconds: 50));

      tracker.completeTracking(operationId1);
      tracker.completeTracking(operationId2);

      // 验证每个操作的回调是独立的
      expect(events1.every((e) => e.operationId == operationId1), isTrue);
      expect(events2.every((e) => e.operationId == operationId2), isTrue);
      expect(events1, isNotEmpty);
      expect(events2, isNotEmpty);
    });
  });

  group('缓存迁移进度跟踪器统计测试', () {
    late CacheMigrationProgressTracker tracker;

    setUp(() {
      tracker = CacheMigrationProgressTracker();
    });

    tearDown(() {
      tracker.clearAllHistory();
    });

    test('应该正确计算进度百分比', () {
      const operationId = 'test_operation';
      const totalItems = 200;

      tracker.startTracking(operationId, totalItems);

      expect(tracker.getProgressPercentage(operationId), equals(0.0));

      tracker.updateProgress(operationId, processedItems: 50);
      expect(tracker.getProgressPercentage(operationId), equals(0.25));

      tracker.updateProgress(operationId, processedItems: 150);
      expect(tracker.getProgressPercentage(operationId), equals(0.75));

      tracker.updateProgress(operationId, processedItems: 200);
      expect(tracker.getProgressPercentage(operationId), equals(1.0));
    });

    test('应该正确计算成功率', () {
      const operationId = 'test_operation';
      const totalItems = 100;

      tracker.startTracking(operationId, totalItems);

      expect(tracker.getSuccessRate(operationId), equals(0.0));

      tracker.updateProgress(operationId, processedItems: 40, failedItems: 10);
      expect(tracker.getSuccessRate(operationId), equals(0.8)); // 40/(40+10)

      tracker.updateProgress(operationId, processedItems: 80, failedItems: 20);
      expect(tracker.getSuccessRate(operationId), equals(0.8)); // 80/(80+20)
    });

    test('应该生成详细的统计信息', () async {
      const operationId = 'test_operation';
      const totalItems = 10;

      final startTime = DateTime.now();
      tracker.startTracking(operationId, totalItems);

      // 模拟进度更新
      for (int i = 1; i <= 5; i++) {
        tracker.updateProgress(operationId,
            processedItems: i, currentItem: 'item_$i');
        await Future.delayed(const Duration(milliseconds: 20));
      }

      tracker.completeTracking(operationId);

      final stats = tracker.getStatistics(operationId);

      expect(stats.operationId, equals(operationId));
      expect(stats.totalItems, equals(totalItems));
      expect(stats.processedItems, equals(5));
      expect(stats.duration.inMilliseconds, greaterThan(0));
      expect(stats.throughput, greaterThan(0.0));
      expect(stats.statusCounts, isNotEmpty);
      expect(
          stats.statusCounts[ProgressStatus.inProgress.name], greaterThan(0));
      expect(stats.statusCounts[ProgressStatus.completed.name], equals(1));
    });

    test('应该提供跟踪器级别的统计信息', () {
      // 创建多个操作
      tracker.startTracking('op1', 100);
      tracker.startTracking('op2', 200);
      tracker.startTracking('op3', 150);

      // 完成一些操作
      tracker.completeTracking('op1');
      tracker.failTracking('op2', '测试失败');

      final trackerStats = tracker.getTrackerStatistics();

      expect(trackerStats['total_operations'], equals(3));
      expect(trackerStats['completed_operations'], equals(1));
      expect(trackerStats['failed_operations'], equals(1));
      expect(trackerStats['active_operations'], greaterThan(0));
      expect(trackerStats['total_events_processed'], greaterThan(0));
    });
  });

  group('缓存迁移进度跟踪器历史记录测试', () {
    late CacheMigrationProgressTracker tracker;

    setUp(() {
      tracker = CacheMigrationProgressTracker();
    });

    tearDown(() {
      tracker.clearAllHistory();
    });

    test('应该正确维护事件历史', () async {
      const operationId = 'test_operation';

      tracker.startTracking(operationId, 10);

      await Future.delayed(const Duration(milliseconds: 10));

      tracker.updateProgress(operationId, processedItems: 3);
      await Future.delayed(const Duration(milliseconds: 10));

      tracker.updateProgress(operationId, processedItems: 7, failedItems: 1);
      await Future.delayed(const Duration(milliseconds: 10));

      tracker.completeTracking(operationId);

      final history = tracker.getEventHistory(operationId);

      expect(history, hasLength(4)); // 开始 + 2次更新 + 完成
      expect(history.first.status, equals(ProgressStatus.inProgress));
      expect(history.last.status, equals(ProgressStatus.completed));

      // 检查进度进展
      expect(history[0].processedItems, equals(0));
      expect(history[1].processedItems, equals(3));
      expect(history[2].processedItems, equals(7));
      expect(history[2].failedItems, equals(1));
      expect(history[3].processedItems, equals(7));
    });

    test('应该正确清除操作历史', () {
      const operationId = 'test_operation';

      tracker.startTracking(operationId, 10);
      tracker.updateProgress(operationId, processedItems: 5);

      expect(tracker.getLatestEvent(operationId), isNotNull);
      expect(tracker.getEventHistory(operationId), isNotEmpty);

      tracker.clearOperationHistory(operationId);

      expect(tracker.getLatestEvent(operationId), isNull);
      expect(tracker.getEventHistory(operationId), isEmpty);
    });

    test('应该正确清除所有历史', () {
      tracker.startTracking('op1', 10);
      tracker.startTracking('op2', 20);
      tracker.startTracking('op3', 30);

      expect(tracker.getLatestEvent('op1'), isNotNull);
      expect(tracker.getLatestEvent('op2'), isNotNull);
      expect(tracker.getLatestEvent('op3'), isNotNull);

      tracker.clearAllHistory();

      expect(tracker.getLatestEvent('op1'), isNull);
      expect(tracker.getLatestEvent('op2'), isNull);
      expect(tracker.getLatestEvent('op3'), isNull);
    });
  });

  group('缓存迁移进度跟踪器并发测试', () {
    late CacheMigrationProgressTracker tracker;

    setUp(() {
      tracker = CacheMigrationProgressTracker();
    });

    tearDown(() {
      tracker.clearAllHistory();
    });

    test('应该支持多个并发操作', () async {
      const operationCount = 5;
      final operations = <String>[];

      // 创建多个并发操作
      for (int i = 0; i < operationCount; i++) {
        final operationId = 'operation_$i';
        operations.add(operationId);
        tracker.startTracking(operationId, (i + 1) * 10);
      }

      // 验证所有操作都已开始
      for (final operationId in operations) {
        final event = tracker.getLatestEvent(operationId);
        expect(event, isNotNull);
        expect(event!.isInProgress, isTrue);
      }

      // 并发更新进度
      for (int i = 0; i < operationCount; i++) {
        final operationId = operations[i];
        tracker.updateProgress(operationId, processedItems: (i + 1) * 5);
      }

      // 验证进度更新正确
      for (int i = 0; i < operationCount; i++) {
        final operationId = operations[i];
        final event = tracker.getLatestEvent(operationId);
        expect(event!.processedItems, equals((i + 1) * 5));
      }

      // 获取活动操作列表
      final activeOperations = tracker.getActiveOperations();
      expect(activeOperations, hasLength(operationCount));

      // 完成所有操作
      for (final operationId in operations) {
        tracker.completeTracking(operationId);
      }

      // 验证所有操作都已完成
      final finalActiveOperations = tracker.getActiveOperations();
      expect(finalActiveOperations, isEmpty);
    });

    test('应该正确处理混合状态的操作', () {
      tracker.startTracking('running_op', 100);
      tracker.updateProgress('running_op', processedItems: 30);

      tracker.startTracking('completed_op', 50);
      tracker.updateProgress('completed_op', processedItems: 50);
      tracker.completeTracking('completed_op');

      tracker.startTracking('failed_op', 80);
      tracker.updateProgress('failed_op', processedItems: 25);
      tracker.failTracking('failed_op', '测试错误');

      tracker.startTracking('paused_op', 60);
      tracker.updateProgress('paused_op', processedItems: 20);
      tracker.pauseTracking('paused_op');

      final activeOperations = tracker.getActiveOperations();
      expect(activeOperations, contains('running_op'));
      expect(activeOperations, contains('paused_op'));
      expect(activeOperations, isNot(contains('completed_op')));
      expect(activeOperations, isNot(contains('failed_op')));
      expect(activeOperations, hasLength(2));
    });
  });

  group('缓存迁移进度跟踪器性能测试', () {
    late CacheMigrationProgressTracker tracker;

    setUp(() {
      tracker = CacheMigrationProgressTracker();
    });

    tearDown(() {
      tracker.clearAllHistory();
    });

    test('应该高效处理大量操作', () async {
      const operationCount = 100;

      final stopwatch = Stopwatch()..start();

      // 创建大量操作
      for (int i = 0; i < operationCount; i++) {
        tracker.startTracking('op_$i', 100);
      }

      stopwatch.stop();

      // 创建操作应该很快完成
      expect(stopwatch.elapsedMilliseconds, lessThan(100));

      // 验证所有操作都正确创建
      expect(tracker.getTrackerStatistics()['total_operations'],
          equals(operationCount));
      expect(tracker.getActiveOperations(), hasLength(operationCount));
    });

    test('应该高效处理大量事件', () async {
      const operationId = 'performance_test';
      const eventCount = 1000;

      tracker.startTracking(operationId, eventCount);

      final stopwatch = Stopwatch()..start();

      // 生成大量进度更新事件
      for (int i = 1; i <= eventCount; i++) {
        tracker.updateProgress(operationId, processedItems: i);
      }

      stopwatch.stop();

      // 更新进度应该很快完成
      expect(stopwatch.elapsedMilliseconds, lessThan(500));

      // 验证事件历史正确记录
      final history = tracker.getEventHistory(operationId);
      expect(history, hasLength(eventCount + 1)); // +1 for start event

      final stats = tracker.getStatistics(operationId);
      expect(stats.processedItems, equals(eventCount));
    });
  });

  group('ProgressEvent对象测试', () {
    test('应该正确计算进度百分比', () {
      final event = ProgressEvent(
        operationId: 'test',
        status: ProgressStatus.inProgress,
        totalItems: 100,
        processedItems: 75,
        failedItems: 5,
        skippedItems: 0,
        timestamp: DateTime.now(),
      );

      expect(event.progressPercentage, equals(0.75));
    });

    test('应该正确计算成功率', () {
      final event = ProgressEvent(
        operationId: 'test',
        status: ProgressStatus.inProgress,
        totalItems: 100,
        processedItems: 80,
        failedItems: 20,
        skippedItems: 0,
        timestamp: DateTime.now(),
      );

      expect(event.successRate, equals(0.8)); // 80/(80+20)
    });

    test('应该正确识别状态', () {
      final completedEvent = ProgressEvent(
        operationId: 'test',
        status: ProgressStatus.completed,
        totalItems: 100,
        processedItems: 100,
        failedItems: 0,
        skippedItems: 0,
        timestamp: DateTime.now(),
      );

      final failedEvent = ProgressEvent(
        operationId: 'test',
        status: ProgressStatus.failed,
        totalItems: 100,
        processedItems: 50,
        failedItems: 1,
        skippedItems: 0,
        timestamp: DateTime.now(),
      );

      expect(completedEvent.isCompleted, isTrue);
      expect(completedEvent.isInProgress, isFalse);
      expect(completedEvent.isFailed, isFalse);

      expect(failedEvent.isCompleted, isFalse);
      expect(failedEvent.isInProgress, isFalse);
      expect(failedEvent.isFailed, isTrue);
    });

    test('应该正确格式化toString', () {
      final event = ProgressEvent(
        operationId: 'test_operation',
        status: ProgressStatus.inProgress,
        totalItems: 100,
        processedItems: 45,
        failedItems: 2,
        skippedItems: 1,
        currentItem: 'processing_item_45',
        timestamp: DateTime.now(),
      );

      final eventString = event.toString();
      expect(eventString, contains('test_operation'));
      expect(eventString, contains('ProgressStatus.inProgress'));
      expect(eventString, contains('45.0%'));
      expect(eventString, contains('processing_item_45'));
    });
  });

  group('ProgressStatistics对象测试', () {
    test('应该正确计算吞吐量', () {
      const stats = ProgressStatistics(
        operationId: 'test',
        duration: Duration(seconds: 10),
        averageSpeed: 5.0,
        peakSpeed: 8,
        totalItems: 100,
        processedItems: 50,
        failedItems: 5,
        skippedItems: 2,
        statusCounts: {},
      );

      expect(stats.throughput, equals(5.0)); // 50 items / 10 seconds
    });

    test('应该正确格式化toString', () {
      const stats = ProgressStatistics(
        operationId: 'test_operation',
        duration: Duration(seconds: 30),
        averageSpeed: 3.5,
        peakSpeed: 6,
        totalItems: 200,
        processedItems: 105,
        failedItems: 10,
        skippedItems: 5,
        statusCounts: {},
      );

      final statsString = stats.toString();
      expect(statsString, contains('test_operation'));
      expect(statsString, contains('30s'));
      expect(statsString, contains('3.5/s'));
    });
  });
}
