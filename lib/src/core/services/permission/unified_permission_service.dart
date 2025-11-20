import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';

import '../base/i_unified_service.dart';
import '../../utils/logger.dart';

// 权限相关枚举和类定义（简化版本，避免外部依赖）
enum Permission {
  notification,
  camera,
  microphone,
  location,
  storage,
  batteryOptimization,
  photos,
  contacts,
  settings,
  phone,
  sms,
  calendar,
  batch,
  cache,
  history,
  analytics,
}

enum PermissionStatus {
  granted,
  denied,
  restricted,
  permanentlyDenied,
  limited,
  unknown,
  temporarilyDenied,
}

// 权限相关类定义
class IntelligentPermissionManager {
  static final IntelligentPermissionManager instance =
      IntelligentPermissionManager._internal();
  IntelligentPermissionManager._internal();

  Future<PermissionResult> requestPermission(
    Permission permission, {
    String? rationale,
    bool forceRequest = false,
  }) async {
    // 简化实现
    return PermissionResult(
      status: PermissionStatus.granted,
      timestamp: DateTime.now(),
    );
  }

  Future<PermissionStatus> checkPermissionStatus(Permission permission) async {
    // 简化实现
    return PermissionStatus.granted;
  }

  Future<void> openPermissionSettings() async {
    // 简化实现
  }
}

class PermissionHistoryManager {
  static final PermissionHistoryManager instance =
      PermissionHistoryManager._internal();
  PermissionHistoryManager._internal();

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    _isInitialized = true;
  }

  Future<void> recordPermission({
    required Permission permission,
    required PermissionStatus status,
    required DateTime timestamp,
    String? rationale,
    PermissionRequestContext? context,
  }) async {
    // 简化实现
  }

  Future<List<PermissionRequestRecord>> getHistory({
    Permission? permission,
    PermissionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    return [];
  }

  Future<void> cleanupHistory({
    DateTime? olderThan,
    Permission? permission,
    int? maxRecords,
  }) async {
    // 简化实现
  }
}

class Android13NotificationPermissionManager {
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    _isInitialized = true;
  }

  Future<void> dispose() async {
    // 清理资源
  }
}

class PermissionRequestRecord {
  final String id;
  final Permission permission;
  final DateTime requestedAt;
  final String? rationale;
  final PermissionRequestContext context;
  final bool forceRequest;

  const PermissionRequestRecord({
    required this.id,
    required this.permission,
    required this.requestedAt,
    this.rationale,
    required this.context,
    required this.forceRequest,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'permission': permission.name,
      'requestedAt': requestedAt.toIso8601String(),
      'rationale': rationale,
      'context': context.name,
      'forceRequest': forceRequest,
    };
  }
}

class PermissionStatistics {
  final int totalRequests;
  final int grantedCount;
  final int deniedCount;
  final double successRate;
  final DateTime lastRequestTime;

  const PermissionStatistics({
    required this.totalRequests,
    required this.grantedCount,
    required this.deniedCount,
    required this.successRate,
    required this.lastRequestTime,
  });

  static PermissionStatistics empty() {
    return PermissionStatistics(
      totalRequests: 0,
      grantedCount: 0,
      deniedCount: 0,
      successRate: 0.0,
      lastRequestTime: DateTime.now(),
    );
  }

  PermissionStatistics copyWith({
    int? totalRequests,
    int? grantedCount,
    int? deniedCount,
    double? successRate,
    DateTime? lastRequestTime,
  }) {
    return PermissionStatistics(
      totalRequests: totalRequests ?? this.totalRequests,
      grantedCount: grantedCount ?? this.grantedCount,
      deniedCount: deniedCount ?? this.deniedCount,
      successRate: successRate ?? this.successRate,
      lastRequestTime: lastRequestTime ?? this.lastRequestTime,
    );
  }

  static PermissionStatistics fromHistory(
      List<PermissionRequestRecord> history) {
    final totalRequests = history.length;
    final grantedCount = history
        .where((r) => r.context != PermissionRequestContext.unknown)
        .length;
    final deniedCount = totalRequests - grantedCount;
    final successRate = totalRequests > 0 ? grantedCount / totalRequests : 0.0;
    final lastRequestTime = history.isNotEmpty
        ? history
            .map((r) => r.requestedAt)
            .reduce((a, b) => a.isAfter(b) ? a : b)
        : DateTime.now();

    return PermissionStatistics(
      totalRequests: totalRequests,
      grantedCount: grantedCount,
      deniedCount: deniedCount,
      successRate: successRate,
      lastRequestTime: lastRequestTime,
    );
  }
}

/// 统一权限服务
///
/// 整合项目中的所有权限相关Manager类，提供统一的权限管理接口。
/// 整合的Manager包括：
/// - IntelligentPermissionManager: 智能权限管理
/// - PermissionHistoryManager: 权限历史管理
/// - Android13NotificationPermissionManager: Android 13通知权限管理
/// - 权限请求记录和分析
class UnifiedPermissionService extends IUnifiedService {
  // 内部状态
  bool _isInitialized = false;
  bool _isDisposed = false;
  DateTime _startTime = DateTime.now();
  late final IntelligentPermissionManager _intelligentPermissionManager;
  late final PermissionHistoryManager _permissionHistoryManager;
  late final Android13NotificationPermissionManager
      _android13NotificationManager;

  // 权限流控制器
  StreamController<PermissionOperationEvent>?
      _permissionOperationStreamController;
  StreamController<PermissionRequestEvent>? _permissionRequestStreamController;
  StreamController<PermissionStatusChangeEvent>?
      _statusChangeEventStreamController;

  // 权限状态缓存
  final Map<Permission, PermissionStatus> _permissionStatusCache = {};

  // 统计信息
  PermissionStatistics _statistics = PermissionStatistics.empty();

  @override
  String get serviceName => 'UnifiedPermissionService';

  @override
  String get version => '1.0.0';

  @override
  List<String> get dependencies => [];

  @override
  bool get isInitialized => _isInitialized;

  @override
  bool get isDisposed => _isDisposed;

  /// 获取权限操作事件流
  Stream<PermissionOperationEvent> get permissionOperationStream =>
      _permissionOperationStreamController?.stream ?? const Stream.empty();

  /// 获取权限请求事件流
  Stream<PermissionRequestEvent> get permissionRequestStream =>
      _permissionRequestStreamController?.stream ?? const Stream.empty();

  /// 获取权限状态变化事件流
  Stream<PermissionStatusChangeEvent> get statusChangeEventStream =>
      _statusChangeEventStreamController?.stream ?? const Stream.empty();

  /// 获取当前权限统计信息
  PermissionStatistics get statistics => _statistics;

  @override
  Future<void> initialize(ServiceContainer container) async {
    if (_isInitialized) {
      AppLogger.warn('UnifiedPermissionService已经初始化');
      return;
    }

    setLifecycleState(ServiceLifecycleState.initializing);
    AppLogger.info('正在初始化UnifiedPermissionService...');

    try {
      // 初始化流控制器
      _initializeStreamControllers();

      // 初始化权限历史管理器
      _permissionHistoryManager = PermissionHistoryManager.instance;
      await _permissionHistoryManager.initialize();

      // 初始化智能权限管理器
      _intelligentPermissionManager = IntelligentPermissionManager.instance;

      // 初始化Android 13通知权限管理器
      _android13NotificationManager = Android13NotificationPermissionManager();
      await _android13NotificationManager.initialize();

      // 初始化权限状态缓存
      await _initializePermissionCache();

      // 加载权限统计数据
      await _loadStatistics();

      _isInitialized = true;
      setLifecycleState(ServiceLifecycleState.initialized);

      AppLogger.info('UnifiedPermissionService初始化完成');
    } catch (e) {
      setLifecycleState(ServiceLifecycleState.error);
      AppLogger.error('UnifiedPermissionService初始化失败', e);
      rethrow;
    }
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;

    setLifecycleState(ServiceLifecycleState.disposing);
    AppLogger.info('正在关闭UnifiedPermissionService...');
    _isDisposed = true;
    _isInitialized = false;

    try {
      // 关闭流控制器
      await _closeStreamControllers();

      // 销毁各个管理器
      await _disposeManagers();

      setLifecycleState(ServiceLifecycleState.disposed);
      AppLogger.info('UnifiedPermissionService已关闭');
    } catch (e) {
      setLifecycleState(ServiceLifecycleState.error);
      AppLogger.error('关闭UnifiedPermissionService时出错', e);
    }
  }

  @override
  Future<ServiceHealthStatus> checkHealth() async {
    try {
      if (!_isInitialized || _isDisposed) {
        return ServiceHealthStatus(
          isHealthy: false,
          message: 'Service未初始化或已关闭',
          lastCheck: DateTime.now(),
        );
      }

      return ServiceHealthStatus(
        isHealthy: true,
        message: 'UnifiedPermissionService运行正常',
        lastCheck: DateTime.now(),
        details: await _getHealthDetails(),
      );
    } catch (e) {
      return ServiceHealthStatus(
        isHealthy: false,
        message: '健康检查失败: $e',
        lastCheck: DateTime.now(),
      );
    }
  }

  @override
  ServiceStats getStats() {
    return ServiceStats(
      serviceName: 'UnifiedPermissionService',
      version: version,
      uptime: DateTime.now().difference(_startTime),
      memoryUsage: _getCurrentMemoryUsage(),
      customMetrics: {
        'activeManagers': _getActiveManagerCount(),
        'grantedPermissions': _getGrantedPermissionsCount(),
        'deniedPermissions': _getDeniedPermissionsCount(),
        'totalRequests': _statistics.totalRequests,
        'successRate': _statistics.successRate,
        'lastRequestTime': _statistics.lastRequestTime.toIso8601String(),
      },
    );
  }

  /// 请求权限
  Future<PermissionResult> requestPermission(
    Permission permission, {
    String? rationale,
    bool forceRequest = false,
    PermissionRequestContext? context,
  }) async {
    try {
      final requestRecord = PermissionRequestRecord(
        id: 'req_${DateTime.now().millisecondsSinceEpoch}',
        permission: permission,
        requestedAt: DateTime.now(),
        rationale: rationale,
        context: context ?? PermissionRequestContext.unknown,
        forceRequest: forceRequest,
      );

      _emitPermissionRequestEvent(
        eventType: PermissionRequestEventType.requested,
        permission: permission,
        requestId: requestRecord.id,
        metadata: requestRecord.toJson(),
      );

      // 检查是否需要强制请求
      if (!forceRequest) {
        final cachedStatus = _getCachedPermissionStatus(permission);
        if (cachedStatus == PermissionStatus.granted) {
          return _createSuccessResult(permission, 'Already granted');
        }
      }

      // 使用智能权限管理器请求权限
      final result = await _intelligentPermissionManager.requestPermission(
        permission,
        rationale: rationale,
        forceRequest: forceRequest,
      );

      // 更新权限状态缓存
      _updatePermissionCache(permission, result.status);

      // 记录权限历史
      await _permissionHistoryManager.recordPermission(
        permission: permission,
        status: result.status,
        timestamp: DateTime.now(),
        rationale: rationale,
        context: context,
      );

      // 更新统计信息
      _updateStatistics(result);

      // 发送状态变化事件
      _emitStatusChangeEvent(
        permission: permission,
        oldStatus: PermissionStatus.unknown,
        newStatus: result.status,
      );

      return result;
    } catch (e) {
      _emitPermissionOperationEvent(
        operationType: PermissionOperationType.request,
        permission: permission,
        success: false,
        error: e.toString(),
      );

      return PermissionResult(
        status: PermissionStatus.denied,
        message: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  /// 批量请求权限
  Future<List<PermissionResult>> requestPermissions(
    List<Permission> permissions, {
    Map<Permission, String>? rationales,
    bool forceRequest = false,
    PermissionRequestContext? context,
  }) async {
    final results = <PermissionResult>[];

    _emitPermissionOperationEvent(
      operationType: PermissionOperationType.batchRequest,
      permission: Permission.batch,
      success: true,
      metadata: {'count': permissions.length},
    );

    for (final permission in permissions) {
      try {
        final rationale = rationales?[permission];
        final result = await requestPermission(
          permission,
          rationale: rationale,
          forceRequest: forceRequest,
          context: context,
        );
        results.add(result);
      } catch (e) {
        results.add(PermissionResult(
          status: PermissionStatus.denied,
          message: e.toString(),
          timestamp: DateTime.now(),
        ));
      }
    }

    return results;
  }

  /// 检查权限状态
  Future<PermissionStatus> checkPermissionStatus(Permission permission) async {
    try {
      final cachedStatus = _getCachedPermissionStatus(permission);
      if (cachedStatus != PermissionStatus.unknown) {
        return cachedStatus;
      }

      // 使用智能权限管理器检查权限状态
      final result =
          await _intelligentPermissionManager.checkPermissionStatus(permission);

      // 更新缓存
      _updatePermissionCache(permission, result);

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking permission status: $e');
      }
      return PermissionStatus.denied;
    }
  }

  /// 检查权限状态（同步版本）
  PermissionStatus checkPermissionStatusSync(Permission permission) {
    final cachedStatus = _getCachedPermissionStatus(permission);
    if (cachedStatus != PermissionStatus.unknown) {
      return cachedStatus;
    }

    // 同步检查权限状态（简化实现）
    // 在实际项目中应该使用权限检查库
    return PermissionStatus.unknown;
  }

  /// 打开权限设置
  Future<void> openPermissionSettings() async {
    try {
      _emitPermissionOperationEvent(
        operationType: PermissionOperationType.openSettings,
        permission: Permission.settings,
        success: true,
      );

      // 使用智能权限管理器打开权限设置
      await _intelligentPermissionManager.openPermissionSettings();
    } catch (e) {
      _emitPermissionOperationEvent(
        operationType: PermissionOperationType.openSettings,
        permission: Permission.settings,
        success: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// 检查权限请求历史
  Future<List<PermissionRequestRecord>> getPermissionHistory({
    Permission? permission,
    PermissionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      return await _permissionHistoryManager.getHistory(
        permission: permission,
        status: status,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );
    } catch (e) {
      _emitPermissionOperationEvent(
        operationType: PermissionOperationType.read,
        permission: Permission.history,
        success: false,
        error: e.toString(),
      );
      return [];
    }
  }

  /// 清理权限历史记录
  Future<void> cleanupPermissionHistory({
    DateTime? olderThan,
    Permission? permission,
    int? maxRecords,
  }) async {
    try {
      await _permissionHistoryManager.cleanupHistory(
        olderThan: olderThan,
        permission: permission,
        maxRecords: maxRecords,
      );

      _emitPermissionOperationEvent(
        operationType: PermissionOperationType.cleanup,
        permission: Permission.history,
        success: true,
        metadata: {
          'olderThan': olderThan?.toIso8601String(),
          'permission': permission?.name,
          'maxRecords': maxRecords,
        },
      );
    } catch (e) {
      _emitPermissionOperationEvent(
        operationType: PermissionOperationType.cleanup,
        permission: Permission.history,
        success: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// 获取权限统计信息
  Future<PermissionStatistics> getPermissionStatistics({
    Permission? permission,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final history = await getPermissionHistory(
        permission: permission,
        startDate: startDate,
        endDate: endDate,
        limit: 1000,
      );

      return PermissionStatistics.fromHistory(history);
    } catch (e) {
      _emitPermissionOperationEvent(
        operationType: PermissionOperationType.analyze,
        permission: Permission.analytics,
        success: false,
        error: e.toString(),
      );
      return PermissionStatistics.empty();
    }
  }

  /// 重置权限缓存
  void resetPermissionCache() {
    _permissionStatusCache.clear();

    _emitPermissionOperationEvent(
      operationType: PermissionOperationType.resetCache,
      permission: Permission.cache,
      success: true,
    );
  }

  /// 测试权限请求
  Future<PermissionResult> testPermissionRequest() async {
    // 使用通知权限进行测试
    return await requestPermission(
      Permission.notification,
      rationale: '这是一个测试权限请求',
      forceRequest: false,
      context: PermissionRequestContext.test,
    );
  }

  // 私有方法

  void _initializeStreamControllers() {
    _permissionOperationStreamController =
        StreamController<PermissionOperationEvent>.broadcast();
    _permissionRequestStreamController =
        StreamController<PermissionRequestEvent>.broadcast();
    _statusChangeEventStreamController =
        StreamController<PermissionStatusChangeEvent>.broadcast();
  }

  Future<void> _closeStreamControllers() async {
    await _permissionOperationStreamController?.close();
    await _permissionRequestStreamController?.close();
    await _statusChangeEventStreamController?.close();
  }

  Future<void> _initializePermissionCache() async {
    // 初始化常用权限的缓存状态
    final commonPermissions = [
      Permission.notification,
      Permission.camera,
      Permission.photos,
      Permission.storage,
      Permission.location,
      Permission.microphone,
      Permission.contacts,
    ];

    for (final permission in commonPermissions) {
      _updatePermissionCache(permission, PermissionStatus.unknown);
    }
  }

  Future<void> _loadStatistics() async {
    try {
      final history = await getPermissionHistory(limit: 1000);
      _statistics = PermissionStatistics.fromHistory(history);
    } catch (e) {
      if (kDebugMode) {
        print('Error loading statistics: $e');
      }
      _statistics = PermissionStatistics.empty();
    }
  }

  PermissionStatus _getCachedPermissionStatus(Permission permission) {
    return _permissionStatusCache[permission] ?? PermissionStatus.unknown;
  }

  void _updatePermissionCache(Permission permission, PermissionStatus status) {
    _permissionStatusCache[permission] = status;
  }

  PermissionResult _createSuccessResult(
    Permission permission,
    String? message,
  ) {
    return PermissionResult(
      status: PermissionStatus.granted,
      message: message ?? 'Permission granted',
      timestamp: DateTime.now(),
    );
  }

  void _updateStatistics(PermissionResult result) {
    if (result.status == PermissionStatus.granted) {
      _statistics = _statistics.copyWith(
        grantedCount: _statistics.grantedCount + 1,
        successRate:
            (_statistics.grantedCount + 1) / (_statistics.totalRequests + 1),
      );
    } else {
      _statistics = _statistics.copyWith(
        deniedCount: _statistics.deniedCount + 1,
        successRate: _statistics.grantedCount / (_statistics.totalRequests + 1),
      );
    }

    _statistics = _statistics.copyWith(
      totalRequests: _statistics.totalRequests + 1,
      lastRequestTime: DateTime.now(),
    );
  }

  void _emitPermissionOperationEvent({
    required PermissionOperationType operationType,
    required Permission permission,
    required bool success,
    String? error,
    Map<String, dynamic>? metadata,
  }) {
    final event = PermissionOperationEvent(
      timestamp: DateTime.now(),
      operationType: operationType,
      permission: permission,
      success: success,
      error: error,
      metadata: metadata ?? {},
    );

    _permissionOperationStreamController?.add(event);
  }

  void _emitPermissionRequestEvent({
    required PermissionRequestEventType eventType,
    required Permission permission,
    required String requestId,
    Map<String, dynamic>? metadata,
  }) {
    final event = PermissionRequestEvent(
      timestamp: DateTime.now(),
      eventType: eventType,
      permission: permission,
      requestId: requestId,
      metadata: metadata ?? {},
    );

    _permissionRequestStreamController?.add(event);
  }

  void _emitStatusChangeEvent({
    required Permission permission,
    required PermissionStatus oldStatus,
    required PermissionStatus newStatus,
  }) {
    final event = PermissionStatusChangeEvent(
      timestamp: DateTime.now(),
      permission: permission,
      oldStatus: oldStatus,
      newStatus: newStatus,
    );

    _statusChangeEventStreamController?.add(event);
  }

  Future<bool> _areManagersHealthy() async {
    try {
      final managers = [
        _intelligentPermissionManager,
        _permissionHistoryManager,
        _android13NotificationManager,
      ];

      for (final manager in managers) {
        if (manager is PermissionHistoryManager && !manager.isInitialized) {
          return false;
        } else if (manager is Android13NotificationPermissionManager &&
            !manager.isInitialized) {
          return false;
        }
        // IntelligentPermissionManager是单例，总是初始化的
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> _getHealthDetails() async {
    return {
      'intelligentPermissionManager': {
        'isInitialized': true, // 智能权限管理器是单例，总是初始化的
      },
      'permissionHistoryManager': {
        'isInitialized': _permissionHistoryManager.isInitialized,
      },
      'android13NotificationManager': {
        'isInitialized': _android13NotificationManager.isInitialized,
      },
      'permissionCache': {
        'size': _permissionStatusCache.length,
        'grantedCount': _permissionStatusCache.values
            .where((status) => status == PermissionStatus.granted)
            .length,
        'deniedCount': _permissionStatusCache.values
            .where((status) => status == PermissionStatus.denied)
            .length,
      },
    };
  }

  Future<void> _disposeManagers() async {
    final managers = [
      _android13NotificationManager,
      // _intelligentPermissionManager 和 _permissionHistoryManager 是单例，不需要销毁
    ];

    for (final manager in managers) {
      try {
        if (manager is Android13NotificationPermissionManager) {
          await manager.dispose();
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error disposing permission manager: $e');
        }
      }
    }
  }

  int _getCurrentMemoryUsage() {
    try {
      return 0; // 简化实现
    } catch (e) {
      return 0;
    }
  }

  int _getActiveManagerCount() {
    return 3; // 固定的管理器数量
  }

  int _getGrantedPermissionsCount() {
    return _permissionStatusCache.values
        .where((status) => status == PermissionStatus.granted)
        .length;
  }

  int _getDeniedPermissionsCount() {
    return _permissionStatusCache.values
        .where((status) => status == PermissionStatus.denied)
        .length;
  }
}

// 辅助类和枚举定义

/// 权限操作事件
class PermissionOperationEvent {
  final DateTime timestamp;
  final PermissionOperationType operationType;
  final Permission permission;
  final bool success;
  final String? error;
  final Map<String, dynamic> metadata;

  const PermissionOperationEvent({
    required this.timestamp,
    required this.operationType,
    required this.permission,
    required this.success,
    this.error,
    required this.metadata,
  });
}

/// 权限请求事件
class PermissionRequestEvent {
  final DateTime timestamp;
  final PermissionRequestEventType eventType;
  final Permission permission;
  final String requestId;
  final Map<String, dynamic> metadata;

  const PermissionRequestEvent({
    required this.timestamp,
    required this.eventType,
    required this.permission,
    required this.requestId,
    required this.metadata,
  });
}

/// 权限状态变化事件
class PermissionStatusChangeEvent {
  final DateTime timestamp;
  final Permission permission;
  final PermissionStatus oldStatus;
  final PermissionStatus newStatus;

  const PermissionStatusChangeEvent({
    required this.timestamp,
    required this.permission,
    required this.oldStatus,
    required this.newStatus,
  });
}

/// 权限结果
class PermissionResult {
  final PermissionStatus status;
  final String? message;
  final DateTime timestamp;

  const PermissionResult({
    required this.status,
    this.message,
    required this.timestamp,
  });
}

/// 权限操作类型枚举
enum PermissionOperationType {
  request,
  batchRequest,
  check,
  read,
  update,
  openSettings,
  cleanup,
  resetCache,
  analyze,
}

/// 权限请求事件类型枚举
enum PermissionRequestEventType {
  requested,
  started,
  completed,
  cancelled,
  failed,
}

/// 权限请求上下文枚举
enum PermissionRequestContext {
  unknown,
  appStartup,
  userAction,
  featureAccess,
  criticalOperation,
  test,
  emergency,
}

// 扩展方法

extension PermissionExtension on Permission {
  String get name {
    switch (this) {
      case Permission.notification:
        return 'notification';
      case Permission.camera:
        return 'camera';
      case Permission.microphone:
        return 'microphone';
      case Permission.location:
        return 'location';
      case Permission.storage:
        return 'storage';
      case Permission.batteryOptimization:
        return 'batteryOptimization';
      case Permission.photos:
        return 'photos';
      case Permission.contacts:
        return 'contacts';
      case Permission.settings:
        return 'settings';
      case Permission.phone:
        return 'phone';
      case Permission.sms:
        return 'sms';
      case Permission.calendar:
        return 'calendar';
      case Permission.batch:
        return 'batch';
      case Permission.cache:
        return 'cache';
      case Permission.history:
        return 'history';
      case Permission.analytics:
        return 'analytics';
    }
  }
}

extension PermissionOperationTypeExtension on PermissionOperationType {
  String get name {
    switch (this) {
      case PermissionOperationType.request:
        return 'request';
      case PermissionOperationType.batchRequest:
        return 'batchRequest';
      case PermissionOperationType.check:
        return 'check';
      case PermissionOperationType.read:
        return 'read';
      case PermissionOperationType.update:
        return 'update';
      case PermissionOperationType.openSettings:
        return 'openSettings';
      case PermissionOperationType.cleanup:
        return 'cleanup';
      case PermissionOperationType.resetCache:
        return 'resetCache';
      case PermissionOperationType.analyze:
        return 'analyze';
    }
  }
}

extension PermissionRequestEventTypeExtension on PermissionRequestEventType {
  String get name {
    switch (this) {
      case PermissionRequestEventType.requested:
        return 'requested';
      case PermissionRequestEventType.started:
        return 'started';
      case PermissionRequestEventType.completed:
        return 'completed';
      case PermissionRequestEventType.cancelled:
        return 'cancelled';
      case PermissionRequestEventType.failed:
        return 'failed';
    }
  }
}

extension PermissionStatusExtension on PermissionStatus {
  String get name {
    switch (this) {
      case PermissionStatus.granted:
        return 'granted';
      case PermissionStatus.denied:
        return 'denied';
      case PermissionStatus.restricted:
        return 'restricted';
      case PermissionStatus.permanentlyDenied:
        return 'permanentlyDenied';
      case PermissionStatus.limited:
        return 'limited';
      case PermissionStatus.unknown:
        return 'unknown';
      case PermissionStatus.temporarilyDenied:
        return 'temporarilyDenied';
    }
  }
}

extension PermissionRequestContextExtension on PermissionRequestContext {
  String get name {
    switch (this) {
      case PermissionRequestContext.unknown:
        return 'unknown';
      case PermissionRequestContext.appStartup:
        return 'appStartup';
      case PermissionRequestContext.userAction:
        return 'userAction';
      case PermissionRequestContext.featureAccess:
        return 'featureAccess';
      case PermissionRequestContext.criticalOperation:
        return 'criticalOperation';
      case PermissionRequestContext.test:
        return 'test';
      case PermissionRequestContext.emergency:
        return 'emergency';
    }
  }
}
