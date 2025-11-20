import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';

import '../base/i_unified_service.dart';
import '../../utils/logger.dart';

// 推送相关管理器类定义
class PushHistoryManager {
  static final PushHistoryManager instance = PushHistoryManager._internal();
  PushHistoryManager._internal();

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    _isInitialized = true;
  }

  Future<PushHistoryRecord> recordPush({
    required PushNotification notification,
    required PushPriority priority,
    required PushStatus status,
    String? error,
  }) async {
    final record = PushHistoryRecord(
      id: 'record_${DateTime.now().millisecondsSinceEpoch}',
      notification: notification,
      timestamp: DateTime.now(),
      status: status,
      priority: priority,
      error: error,
    );
    return record;
  }

  Future<List<PushHistoryRecord>> getHistory({
    PushHistoryFilter? filter,
    int limit = 50,
    int offset = 0,
  }) async {
    return [];
  }

  Future<void> updatePushStatus(String recordId, PushStatus status,
      {String? error}) async {
    // 简化实现
  }

  Future<void> cleanupHistory({
    DateTime? olderThan,
    PushStatus? statusFilter,
  }) async {
    // 简化实现
  }
}

class PushHistoryCacheManager {
  static final PushHistoryCacheManager instance =
      PushHistoryCacheManager._internal();
  PushHistoryCacheManager._internal();

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    _isInitialized = true;
  }
}

class PushPriorityManager {
  static final PushPriorityManager instance = PushPriorityManager._internal();
  PushPriorityManager._internal();

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    _isInitialized = true;
  }

  PushPriority calculatePriority(PushNotification notification) {
    // 简化实现
    return PushPriority.medium;
  }
}

class PushNotificationCubit {
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    _isInitialized = true;
  }

  void updatePreferences(PushPreferences preferences) {
    // 简化实现
  }
}

class PushNotificationBloc {
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    _isInitialized = true;
  }
}

// 推送数据模型
class PushPreferences {
  final bool enabled;
  final bool doNotDisturb;
  final Map<String, bool> typeSettings;

  const PushPreferences({
    required this.enabled,
    required this.doNotDisturb,
    required this.typeSettings,
  });

  static PushPreferences defaultPreferences() {
    return const PushPreferences(
      enabled: true,
      doNotDisturb: false,
      typeSettings: {
        'fundAlert': true,
        'marketUpdate': true,
        'portfolioChange': true,
        'systemNotification': true,
      },
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'doNotDisturb': doNotDisturb,
      'typeSettings': typeSettings,
    };
  }
}

class PushHistoryRecord {
  final String id;
  final PushNotification notification;
  final DateTime timestamp;
  final PushStatus status;
  final PushPriority priority;
  final String? error;

  const PushHistoryRecord({
    required this.id,
    required this.notification,
    required this.timestamp,
    required this.status,
    required this.priority,
    this.error,
  });
}

class PushPriority {
  final String name;
  final int level;

  const PushPriority._internal(this.name, this.level);

  static const PushPriority low = PushPriority._internal('low', 1);
  static const PushPriority medium = PushPriority._internal('medium', 2);
  static const PushPriority high = PushPriority._internal('high', 3);
}

/// 统一推送服务
///
/// 整合项目中的所有推送相关Manager类，提供统一的推送管理接口。
/// 整合的Manager包括：
/// - PushHistoryManager: 推送历史管理
/// - PushHistoryCacheManager: 推送历史缓存管理
/// - PushPriorityManager: 推送优先级管理
/// - PushNotificationCubit: 推送通知Cubit
/// - PushNotificationBloc: 推送通知Bloc
class UnifiedPushService extends IUnifiedService {
  late final PushHistoryManager _pushHistoryManager;
  late final PushHistoryCacheManager _pushHistoryCacheManager;
  late final PushPriorityManager _pushPriorityManager;
  late final PushNotificationCubit _pushNotificationCubit;
  late final PushNotificationBloc _pushNotificationBloc;

  // 推送流控制器
  StreamController<PushOperationEvent>? _pushOperationStreamController;
  StreamController<PushLifecycleEvent>? _pushLifecycleStreamController;
  StreamController<PushAnalyticsEvent>? _pushAnalyticsStreamController;

  // 推送配置和状态
  PushPreferences _preferences = PushPreferences.defaultPreferences();
  Timer? _analyticsTimer;
  Map<String, PushAnalytics> _statistics = {};

  // 服务状态管理
  ServiceLifecycleState _lifecycleState = ServiceLifecycleState.uninitialized;

  @override
  String get serviceName => 'UnifiedPushService';

  @override
  String get version => '1.0.0';

  @override
  List<String> get dependencies => [
        'UnifiedStateService',
      ];

  bool get isInitialized =>
      _lifecycleState == ServiceLifecycleState.initialized;

  bool get isDisposed => _lifecycleState == ServiceLifecycleState.disposed;

  /// 获取推送操作事件流
  Stream<PushOperationEvent> get pushOperationStream =>
      _pushOperationStreamController?.stream ?? const Stream.empty();

  /// 获取推送生命周期事件流
  Stream<PushLifecycleEvent> get pushLifecycleStream =>
      _pushLifecycleStreamController?.stream ?? const Stream.empty();

  /// 获取推送分析事件流
  Stream<PushAnalyticsEvent> get pushAnalyticsStream =>
      _pushAnalyticsStreamController?.stream ?? const Stream.empty();

  /// 获取当前推送偏好设置
  PushPreferences get preferences => _preferences;

  @override
  Future<void> initialize(ServiceContainer container) async {
    setLifecycleState(ServiceLifecycleState.initializing);

    try {
      // 初始化流控制器
      _initializeStreamControllers();

      // 初始化推送历史缓存管理器
      _pushHistoryCacheManager = PushHistoryCacheManager.instance;
      await _pushHistoryCacheManager.initialize();

      // 初始化推送历史管理器
      _pushHistoryManager = PushHistoryManager.instance;
      await _pushHistoryManager.initialize();

      // 初始化推送优先级管理器
      _pushPriorityManager = PushPriorityManager.instance;
      await _pushPriorityManager.initialize();

      // 加载推送偏好设置
      await _loadPreferences();

      // 初始化推送通知Cubit
      _pushNotificationCubit = PushNotificationCubit();
      await _pushNotificationCubit.initialize();

      // 初始化推送通知Bloc
      _pushNotificationBloc = PushNotificationBloc();
      await _pushNotificationBloc.initialize();

      // 启动分析定时器
      _startAnalyticsCollection();

      setLifecycleState(ServiceLifecycleState.initialized);

      if (kDebugMode) {
        print('UnifiedPushService initialized successfully');
      }
    } catch (e, stackTrace) {
      setLifecycleState(ServiceLifecycleState.error);
      throw ServiceInitializationException(
        serviceName,
        'Failed to initialize UnifiedPushService: $e',
        e,
      );
    }
  }

  @override
  Future<void> dispose() async {
    setLifecycleState(ServiceLifecycleState.disposing);

    try {
      // 停止分析定时器
      _analyticsTimer?.cancel();

      // 关闭流控制器
      await _closeStreamControllers();

      // 销毁各个管理器
      await _disposeManagers();

      setLifecycleState(ServiceLifecycleState.disposed);

      if (kDebugMode) {
        print('UnifiedPushService disposed successfully');
      }
    } catch (e) {
      setLifecycleState(ServiceLifecycleState.error);
      if (kDebugMode) {
        print('Error disposing UnifiedPushService: $e');
      }
    }
  }

  @override
  Future<ServiceHealthStatus> checkHealth() async {
    try {
      final isHealthy = lifecycleState == ServiceLifecycleState.initialized &&
          await _areManagersHealthy();

      return ServiceHealthStatus(
        isHealthy: isHealthy,
        message: isHealthy
            ? 'All push managers are healthy'
            : 'Some push managers have issues',
        lastCheck: DateTime.now(),
        details: await _getHealthDetails(),
      );
    } catch (e) {
      return ServiceHealthStatus(
        isHealthy: false,
        message: 'Health check failed: $e',
        lastCheck: DateTime.now(),
      );
    }
  }

  @override
  ServiceStats getStats() {
    return ServiceStats(
      serviceName: 'UnifiedPushService',
      version: version,
      uptime: Duration.zero, // TODO: 保存实际启动时间
      memoryUsage: _getCurrentMemoryUsage(),
      customMetrics: {
        'activeManagers': _getActiveManagerCount(),
        'totalPushes': _getTotalPushCount(),
        'deliveredPushes': _getDeliveredPushCount(),
        'failedPushes': _getFailedPushCount(),
        'lastPushTime': _getLastPushTime(),
      },
    );
  }

  /// 发送推送通知
  Future<PushResult> sendPushNotification(PushNotification notification) async {
    try {
      _emitPushOperationEvent(
        operationType: PushOperationType.send,
        notificationType: notification.type.name,
        success: true,
        metadata: {'notificationId': notification.id},
      );

      // 确定推送优先级
      final priority = _pushPriorityManager.calculatePriority(notification);

      // 记录推送历史
      final historyRecord = await _pushHistoryManager.recordPush(
        notification: notification,
        priority: priority,
        status: PushStatus.sent,
      );

      // 实际发送推送
      final result = await _performSend(notification, priority);

      // 更新推送历史
      if (result.success) {
        await _pushHistoryManager.updatePushStatus(
          historyRecord.id,
          PushStatus.delivered,
        );

        _emitPushLifecycleEvent(
          lifecycleEvent: PushLifecycleEventType.delivered,
          notificationId: notification.id,
          details: result.details,
        );
      } else {
        await _pushHistoryManager.updatePushStatus(
          historyRecord.id,
          PushStatus.failed,
          error: result.error,
        );

        _emitPushLifecycleEvent(
          lifecycleEvent: PushLifecycleEventType.failed,
          notificationId: notification.id,
          error: result.error,
        );
      }

      return result;
    } catch (e) {
      _emitPushOperationEvent(
        operationType: PushOperationType.send,
        notificationType: notification.type.name,
        success: false,
        error: e.toString(),
      );

      return PushResult(
        success: false,
        error: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  /// 批量发送推送通知
  Future<List<PushResult>> sendBatchPushNotifications(
    List<PushNotification> notifications,
  ) async {
    final results = <PushResult>[];

    _emitPushOperationEvent(
      operationType: PushOperationType.batchSend,
      notificationType: 'batch',
      success: true,
      metadata: {'count': notifications.length},
    );

    for (final notification in notifications) {
      try {
        final result = await sendPushNotification(notification);
        results.add(result);
      } catch (e) {
        results.add(PushResult(
          success: false,
          error: e.toString(),
          timestamp: DateTime.now(),
        ));
      }
    }

    return results;
  }

  /// 获取推送历史记录
  Future<List<PushHistoryRecord>> getPushHistory({
    PushHistoryFilter? filter,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      return await _pushHistoryManager.getHistory(
        filter: filter,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      _emitPushOperationEvent(
        operationType: PushOperationType.read,
        notificationType: 'history',
        success: false,
        error: e.toString(),
      );
      return [];
    }
  }

  /// 更新推送偏好设置
  Future<void> updatePreferences(PushPreferences preferences) async {
    try {
      _preferences = preferences;

      // 保存偏好设置到本地存储
      await _savePreferences();

      // 通知Cubit更新偏好
      _pushNotificationCubit.updatePreferences(preferences);

      _emitPushOperationEvent(
        operationType: PushOperationType.update,
        notificationType: 'preferences',
        success: true,
        metadata: preferences.toJson(),
      );

      if (kDebugMode) {
        print('Push preferences updated successfully');
      }
    } catch (e) {
      _emitPushOperationEvent(
        operationType: PushOperationType.update,
        notificationType: 'preferences',
        success: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// 清理推送历史记录
  Future<void> cleanupPushHistory({
    DateTime? olderThan,
    PushStatus? statusFilter,
  }) async {
    try {
      await _pushHistoryManager.cleanupHistory(
        olderThan: olderThan,
        statusFilter: statusFilter,
      );

      _emitPushOperationEvent(
        operationType: PushOperationType.cleanup,
        notificationType: 'history',
        success: true,
        metadata: {
          'olderThan': olderThan?.toIso8601String(),
          'statusFilter': statusFilter?.name,
        },
      );

      if (kDebugMode) {
        print('Push history cleanup completed');
      }
    } catch (e) {
      _emitPushOperationEvent(
        operationType: PushOperationType.cleanup,
        notificationType: 'history',
        success: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// 获取推送统计信息
  Future<PushAnalytics> getPushAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final history = await _pushHistoryManager.getHistory(
        filter: PushHistoryFilter(
          startDate: startDate,
          endDate: endDate,
        ),
      );

      return PushAnalytics.fromHistory(history);
    } catch (e) {
      _emitPushOperationEvent(
        operationType: PushOperationType.analyze,
        notificationType: 'analytics',
        success: false,
        error: e.toString(),
      );
      return PushAnalytics.empty();
    }
  }

  /// 测试推送通知
  Future<PushResult> testPushNotification() async {
    final testNotification = PushNotification(
      id: 'test_${DateTime.now().millisecondsSinceEpoch}',
      title: '测试推送',
      body: '这是一条测试推送通知',
      type: PushType.test,
      priority: PushPriority.low,
      data: {'test': true},
    );

    return await sendPushNotification(testNotification);
  }

  // 私有方法

  void _initializeStreamControllers() {
    _pushOperationStreamController =
        StreamController<PushOperationEvent>.broadcast();
    _pushLifecycleStreamController =
        StreamController<PushLifecycleEvent>.broadcast();
    _pushAnalyticsStreamController =
        StreamController<PushAnalyticsEvent>.broadcast();
  }

  Future<void> _closeStreamControllers() async {
    await _pushOperationStreamController?.close();
    await _pushLifecycleStreamController?.close();
    await _pushAnalyticsStreamController?.close();
  }

  void _startAnalyticsCollection() {
    _analyticsTimer = Timer.periodic(
      const Duration(minutes: 10),
      (_) => _collectAnalytics(),
    );
  }

  Future<void> _collectAnalytics() async {
    try {
      final analytics = await getPushAnalytics();

      _emitPushAnalyticsEvent(
        eventType: PushAnalyticsEventType.collected,
        analytics: analytics,
      );

      // 更新统计信息
      _statistics['current'] = analytics;
    } catch (e) {
      if (kDebugMode) {
        print('Error collecting analytics: $e');
      }
    }
  }

  Future<void> _loadPreferences() async {
    try {
      // 从本地存储加载偏好设置
      // 这里简化实现，实际项目中应使用SharedPreferences或其他持久化方案
      _preferences = PushPreferences.defaultPreferences();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading preferences: $e');
      }
      _preferences = PushPreferences.defaultPreferences();
    }
  }

  Future<void> _savePreferences() async {
    try {
      // 保存偏好设置到本地存储
      // 这里简化实现，实际项目中应使用SharedPreferences或其他持久化方案
    } catch (e) {
      if (kDebugMode) {
        print('Error saving preferences: $e');
      }
    }
  }

  Future<PushResult> _performSend(
    PushNotification notification,
    PushPriority priority,
  ) async {
    try {
      // 检查用户是否启用了推送
      if (!_preferences.enabled) {
        return PushResult(
          success: false,
          error: 'Push notifications are disabled',
          timestamp: DateTime.now(),
        );
      }

      // 检查免打扰模式
      if (_preferences.doNotDisturb && _isInDoNotDisturbPeriod()) {
        return PushResult(
          success: false,
          error: 'Do not disturb period active',
          timestamp: DateTime.now(),
        );
      }

      // 实际的推送发送逻辑
      // 这里简化实现，实际项目中应集成具体的推送服务（如Firebase Cloud Messaging）

      // 模拟发送延迟
      await Future.delayed(Duration(milliseconds: 500));

      return PushResult(
        success: true,
        timestamp: DateTime.now(),
        details: {
          'priority': priority.name,
          'deliveryMethod': 'mock',
        },
      );
    } catch (e) {
      return PushResult(
        success: false,
        error: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  bool _isInDoNotDisturbPeriod() {
    // 简化实现：检查当前时间是否在免打扰时间段内
    final now = DateTime.now();
    final hour = now.hour;

    // 假设免打扰时间段为晚上10点到早上8点
    return hour >= 22 || hour < 8;
  }

  Future<bool> _areManagersHealthy() async {
    try {
      final managers = [
        _pushHistoryManager,
        _pushHistoryCacheManager,
        _pushPriorityManager,
        _pushNotificationCubit,
        _pushNotificationBloc,
      ];

      for (final manager in managers) {
        if (manager is PushHistoryManager && !manager.isInitialized) {
          return false;
        } else if (manager is PushHistoryCacheManager &&
            !manager.isInitialized) {
          return false;
        } else if (manager is PushPriorityManager && !manager.isInitialized) {
          return false;
        } else if (manager is PushNotificationCubit && !manager.isInitialized) {
          return false;
        } else if (manager is PushNotificationBloc && !manager.isInitialized) {
          return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> _getHealthDetails() async {
    return {
      'pushHistoryManager': {
        'isInitialized': _pushHistoryManager.isInitialized,
      },
      'pushHistoryCacheManager': {
        'isInitialized': _pushHistoryCacheManager.isInitialized,
      },
      'pushPriorityManager': {
        'isInitialized': _pushPriorityManager.isInitialized,
      },
      'preferences': _preferences.toJson(),
    };
  }

  Future<void> _disposeManagers() async {
    final managers = [
      _pushNotificationBloc,
      _pushNotificationCubit,
      // _pushHistoryManager 和 _pushHistoryCacheManager 是单例，不需要销毁
      // _pushPriorityManager 也是单例
    ];

    for (final manager in managers) {
      try {
        if (manager is PushNotificationBloc) {
          // PushNotificationBloc需要实现dispose方法
          // await manager.dispose(); // 简化实现，注释掉直到有具体实现
        } else if (manager is PushNotificationCubit) {
          // PushNotificationCubit需要实现dispose方法
          // await manager.dispose(); // 简化实现，注释掉直到有具体实现
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error disposing push manager: $e');
        }
      }
    }
  }

  void _emitPushOperationEvent({
    required PushOperationType operationType,
    required String notificationType,
    required bool success,
    String? error,
    Map<String, dynamic>? metadata,
  }) {
    final event = PushOperationEvent(
      timestamp: DateTime.now(),
      operationType: operationType,
      notificationType: notificationType,
      success: success,
      error: error,
      metadata: metadata ?? {},
    );

    _pushOperationStreamController?.add(event);
  }

  void _emitPushLifecycleEvent({
    required PushLifecycleEventType lifecycleEvent,
    required String notificationId,
    String? error,
    Map<String, dynamic>? details,
  }) {
    final event = PushLifecycleEvent(
      timestamp: DateTime.now(),
      lifecycleEvent: lifecycleEvent,
      notificationId: notificationId,
      error: error,
      details: details ?? {},
    );

    _pushLifecycleStreamController?.add(event);
  }

  void _emitPushAnalyticsEvent({
    required PushAnalyticsEventType eventType,
    required PushAnalytics analytics,
  }) {
    final event = PushAnalyticsEvent(
      timestamp: DateTime.now(),
      eventType: eventType,
      analytics: analytics,
    );

    _pushAnalyticsStreamController?.add(event);
  }

  int _getCurrentMemoryUsage() {
    try {
      return 0; // 简化实现
    } catch (e) {
      return 0;
    }
  }

  int _getActiveManagerCount() {
    return 5; // 固定的管理器数量
  }

  int _getTotalPushCount() {
    return _statistics['current']?.totalPushes ?? 0;
  }

  int _getDeliveredPushCount() {
    return _statistics['current']?.deliveredPushes ?? 0;
  }

  int _getFailedPushCount() {
    return _statistics['current']?.failedPushes ?? 0;
  }

  DateTime _getLastPushTime() {
    // PushAnalytics没有lastPushTime属性，使用DateTime.now()作为默认值
    return DateTime.now();
  }
}

// 辅助类和枚举定义

/// 推送操作事件
class PushOperationEvent {
  final DateTime timestamp;
  final PushOperationType operationType;
  final String notificationType;
  final bool success;
  final String? error;
  final Map<String, dynamic> metadata;

  const PushOperationEvent({
    required this.timestamp,
    required this.operationType,
    required this.notificationType,
    required this.success,
    this.error,
    required this.metadata,
  });
}

/// 推送生命周期事件
class PushLifecycleEvent {
  final DateTime timestamp;
  final PushLifecycleEventType lifecycleEvent;
  final String notificationId;
  final String? error;
  final Map<String, dynamic> details;

  const PushLifecycleEvent({
    required this.timestamp,
    required this.lifecycleEvent,
    required this.notificationId,
    this.error,
    required this.details,
  });
}

// 推送生命周期事件类型枚举
enum PushLifecycleEventType {
  delivered,
  failed,
}

/// 推送分析事件
class PushAnalyticsEvent {
  final DateTime timestamp;
  final PushAnalyticsEventType eventType;
  final PushAnalytics analytics;

  const PushAnalyticsEvent({
    required this.timestamp,
    required this.eventType,
    required this.analytics,
  });
}

/// 推送通知
class PushNotification {
  final String id;
  final String title;
  final String body;
  final PushType type;
  final PushPriority priority;
  final Map<String, dynamic> data;
  final DateTime? scheduledTime;

  const PushNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.priority,
    this.data = const {},
    this.scheduledTime,
  });
}

/// 推送结果
class PushResult {
  final bool success;
  final String? error;
  final DateTime timestamp;
  final Map<String, dynamic>? details;

  const PushResult({
    required this.success,
    this.error,
    required this.timestamp,
    this.details,
  });
}

/// 推送历史过滤器
class PushHistoryFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final PushType? type;
  final PushStatus? status;

  const PushHistoryFilter({
    this.startDate,
    this.endDate,
    this.type,
    this.status,
  });
}

/// 推送分析
class PushAnalytics {
  final int totalPushes;
  final int deliveredPushes;
  final int failedPushes;
  final double deliveryRate;
  final DateTime startDate;
  final DateTime endDate;
  final Map<PushType, int> typeDistribution;
  final Map<PushStatus, int> statusDistribution;

  const PushAnalytics({
    required this.totalPushes,
    required this.deliveredPushes,
    required this.failedPushes,
    required this.deliveryRate,
    required this.startDate,
    required this.endDate,
    required this.typeDistribution,
    required this.statusDistribution,
  });

  factory PushAnalytics.empty() {
    return PushAnalytics(
      totalPushes: 0,
      deliveredPushes: 0,
      failedPushes: 0,
      deliveryRate: 0.0,
      startDate: DateTime.now(),
      endDate: DateTime.now(),
      typeDistribution: {},
      statusDistribution: {},
    );
  }

  factory PushAnalytics.fromHistory(List<PushHistoryRecord> history) {
    final totalPushes = history.length;
    final deliveredPushes =
        history.where((r) => r.status == PushStatus.delivered).length;
    final failedPushes =
        history.where((r) => r.status == PushStatus.failed).length;
    final deliveryRate = totalPushes > 0 ? deliveredPushes / totalPushes : 0.0;

    final typeDistribution = <PushType, int>{};
    final statusDistribution = <PushStatus, int>{};

    for (final record in history) {
      typeDistribution[record.notification.type] =
          (typeDistribution[record.notification.type] ?? 0) + 1;
      statusDistribution[record.status] =
          (statusDistribution[record.status] ?? 0) + 1;
    }

    final sortedHistory = List<PushHistoryRecord>.from(history)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return PushAnalytics(
      totalPushes: totalPushes,
      deliveredPushes: deliveredPushes,
      failedPushes: failedPushes,
      deliveryRate: deliveryRate,
      startDate: sortedHistory.first.timestamp,
      endDate: sortedHistory.last.timestamp,
      typeDistribution: typeDistribution,
      statusDistribution: statusDistribution,
    );
  }
}

/// 推送类型枚举
enum PushType {
  fundAlert,
  marketUpdate,
  portfolioChange,
  systemNotification,
  promotional,
  test,
}

/// 推送状态枚举
enum PushStatus {
  pending,
  sent,
  delivered,
  failed,
  expired,
  cancelled,
}

/// 推送操作类型枚举
enum PushOperationType {
  send,
  batchSend,
  read,
  update,
  delete,
  cleanup,
  analyze,
}

/// 推送分析事件类型枚举
enum PushAnalyticsEventType {
  collected,
  aggregated,
  reported,
}

// 扩展方法

extension PushTypeExtension on PushType {
  String get name {
    switch (this) {
      case PushType.fundAlert:
        return 'fundAlert';
      case PushType.marketUpdate:
        return 'marketUpdate';
      case PushType.portfolioChange:
        return 'portfolioChange';
      case PushType.systemNotification:
        return 'systemNotification';
      case PushType.promotional:
        return 'promotional';
      case PushType.test:
        return 'test';
    }
  }
}

extension PushStatusExtension on PushStatus {
  String get name {
    switch (this) {
      case PushStatus.pending:
        return 'pending';
      case PushStatus.sent:
        return 'sent';
      case PushStatus.delivered:
        return 'delivered';
      case PushStatus.failed:
        return 'failed';
      case PushStatus.expired:
        return 'expired';
      case PushStatus.cancelled:
        return 'cancelled';
    }
  }
}

extension PushOperationTypeExtension on PushOperationType {
  String get name {
    switch (this) {
      case PushOperationType.send:
        return 'send';
      case PushOperationType.batchSend:
        return 'batchSend';
      case PushOperationType.read:
        return 'read';
      case PushOperationType.update:
        return 'update';
      case PushOperationType.delete:
        return 'delete';
      case PushOperationType.cleanup:
        return 'cleanup';
      case PushOperationType.analyze:
        return 'analyze';
    }
  }
}

extension PushLifecycleEventTypeExtension on PushLifecycleEventType {
  String get name {
    switch (this) {
      case PushLifecycleEventType.delivered:
        return 'delivered';
      case PushLifecycleEventType.failed:
        return 'failed';
    }
  }
}

extension PushAnalyticsEventTypeExtension on PushAnalyticsEventType {
  String get name {
    switch (this) {
      case PushAnalyticsEventType.collected:
        return 'collected';
      case PushAnalyticsEventType.aggregated:
        return 'aggregated';
      case PushAnalyticsEventType.reported:
        return 'reported';
    }
  }
}
