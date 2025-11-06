import 'dart:async';
import 'dart:collection';

import '../utils/logger.dart';
import 'unified_hive_cache_manager.dart';
import 'cache_key_manager.dart';

/// 缓存失效策略
enum CacheInvalidationStrategy {
  /// 基于时间的失效
  timeBased,

  /// 基于版本的失效
  versionBased,

  /// 基于依赖关系的失效
  dependencyBased,

  /// 智能预测失效
  predictive,

  /// 混合策略
  hybrid,
}

/// 缓存失效优先级
enum CacheInvalidationPriority {
  /// 低优先级 - 延迟处理
  low,

  /// 普通优先级 - 正常处理
  normal,

  /// 高优先级 - 立即处理
  high,

  /// 紧急优先级 - 强制立即处理
  critical,
}

/// 缓存失效原因
enum CacheInvalidationReason {
  /// 时间过期
  expired,

  /// 手动清除
  manual,

  /// 依赖更新
  dependencyUpdated,

  /// 内存压力
  memoryPressure,

  /// 版本不匹配
  versionMismatch,

  /// 数据损坏
  corrupted,

  /// 策略调整
  strategyChange,

  /// 预测性刷新
  predictiveRefresh,
}

/// 缓存失效事件
class CacheInvalidationEvent {
  /// 失效的缓存键
  final String key;

  /// 失效原因
  final CacheInvalidationReason reason;

  /// 失效时间
  final DateTime timestamp;

  /// 优先级
  final CacheInvalidationPriority priority;

  /// 附加信息
  final Map<String, dynamic>? metadata;

  /// 关联的缓存键（用于依赖失效）
  final List<String> relatedKeys;

  const CacheInvalidationEvent({
    required this.key,
    required this.reason,
    required this.timestamp,
    this.priority = CacheInvalidationPriority.normal,
    this.metadata,
    this.relatedKeys = const [],
  });

  @override
  String toString() {
    return 'CacheInvalidationEvent(key: $key, reason: $reason, priority: $priority, timestamp: $timestamp)';
  }
}

/// 缓存失效监听器
typedef CacheInvalidationListener = void Function(CacheInvalidationEvent event);

/// 智能缓存失效管理器
///
/// 提供高级缓存失效处理功能：
/// - 多种失效策略支持
/// - 智能预测性刷新
/// - 依赖关系管理
/// - 优先级处理队列
/// - 批量失效优化
/// - 事件监听机制
class SmartCacheInvalidationManager {
  static SmartCacheInvalidationManager? _instance;
  static SmartCacheInvalidationManager get instance {
    _instance ??= SmartCacheInvalidationManager._();
    return _instance!;
  }

  SmartCacheInvalidationManager._() {
    _initialize();
  }

  // 核心组件
  final UnifiedHiveCacheManager _cacheManager =
      UnifiedHiveCacheManager.instance;
  final CacheKeyManager _keyManager = CacheKeyManager.instance;

  // 失效事件队列
  final Queue<CacheInvalidationEvent> _invalidationQueue = Queue();
  final Map<String, CacheInvalidationEvent> _pendingInvalidations = {};

  // 依赖关系映射
  final Map<String, Set<String>> _dependencyGraph = {};
  final Map<String, Set<String>> _reverseDependencyGraph = {};

  // 监听器管理
  final List<CacheInvalidationListener> _listeners = [];

  // 定时器和调度器
  Timer? _processingTimer;
  Timer? _maintenanceTimer;
  Timer? _predictiveTimer;

  // 统计信息
  final _InvalidationStats _stats = _InvalidationStats();

  // 配置参数
  CacheInvalidationStrategy _strategy = CacheInvalidationStrategy.hybrid;
  Duration _processingInterval = const Duration(seconds: 1);
  Duration _maintenanceInterval = const Duration(minutes: 5);
  Duration _predictiveInterval = const Duration(minutes: 10);
  int _maxQueueSize = 1000;
  bool _enablePredictiveRefresh = true;

  /// 初始化失效管理器
  Future<void> initialize({
    CacheInvalidationStrategy strategy = CacheInvalidationStrategy.hybrid,
    Duration? processingInterval,
    Duration? maintenanceInterval,
    Duration? predictiveInterval,
    int? maxQueueSize,
    bool enablePredictiveRefresh = true,
  }) async {
    if (_processingTimer != null) {
      await dispose();
    }

    _strategy = strategy;
    _processingInterval = processingInterval ?? _processingInterval;
    _maintenanceInterval = maintenanceInterval ?? _maintenanceInterval;
    _predictiveInterval = predictiveInterval ?? _predictiveInterval;
    _maxQueueSize = maxQueueSize ?? _maxQueueSize;
    _enablePredictiveRefresh = enablePredictiveRefresh;

    // 启动定时器
    _startProcessingTimer();
    _startMaintenanceTimer();

    if (_enablePredictiveRefresh) {
      _startPredictiveTimer();
    }

    AppLogger.info('🔄 SmartCacheInvalidationManager 已初始化 (策略: $_strategy)');
  }

  /// 添加缓存失效监听器
  void addInvalidationListener(CacheInvalidationListener listener) {
    _listeners.add(listener);
    AppLogger.debug('👂 添加缓存失效监听器');
  }

  /// 移除缓存失效监听器
  void removeInvalidationListener(CacheInvalidationListener listener) {
    _listeners.remove(listener);
    AppLogger.debug('👂 移除缓存失效监听器');
  }

  /// 立即失效指定缓存
  Future<void> invalidate(
    String key, {
    CacheInvalidationReason reason = CacheInvalidationReason.manual,
    CacheInvalidationPriority priority = CacheInvalidationPriority.normal,
    Map<String, dynamic>? metadata,
  }) async {
    final event = CacheInvalidationEvent(
      key: key,
      reason: reason,
      timestamp: DateTime.now(),
      priority: priority,
      metadata: metadata,
    );

    await _addInvalidationEvent(event);
  }

  /// 批量失效缓存
  Future<void> invalidateBatch(
    List<String> keys, {
    CacheInvalidationReason reason = CacheInvalidationReason.manual,
    CacheInvalidationPriority priority = CacheInvalidationPriority.normal,
    Map<String, dynamic>? metadata,
  }) async {
    AppLogger.debug('📦 批量失效 ${keys.length} 个缓存项');

    for (final key in keys) {
      final event = CacheInvalidationEvent(
        key: key,
        reason: reason,
        timestamp: DateTime.now(),
        priority: priority,
        metadata: metadata,
      );

      await _addInvalidationEvent(event);
    }
  }

  /// 基于模式失效缓存
  Future<void> invalidateByPattern(
    String pattern, {
    CacheInvalidationReason reason = CacheInvalidationReason.manual,
    CacheInvalidationPriority priority = CacheInvalidationPriority.normal,
  }) async {
    try {
      final allKeys = await _cacheManager.getAllKeys();
      final matchingKeys = _filterKeysByPattern(allKeys, pattern);

      AppLogger.debug('🔍 模式 "$pattern" 匹配到 ${matchingKeys.length} 个缓存项');

      await invalidateBatch(matchingKeys, reason: reason, priority: priority);
    } catch (e) {
      AppLogger.error('❌ 基于模式失效缓存失败: $pattern', e);
    }
  }

  /// 基于依赖关系失效缓存
  Future<void> invalidateByDependency(
    String dependencyKey, {
    CacheInvalidationReason reason = CacheInvalidationReason.dependencyUpdated,
    CacheInvalidationPriority priority = CacheInvalidationPriority.high,
  }) async {
    final dependentKeys = _reverseDependencyGraph[dependencyKey] ?? <String>{};

    AppLogger.debug('🔗 依赖 "$dependencyKey" 影响到 ${dependentKeys.length} 个缓存项');

    final event = CacheInvalidationEvent(
      key: dependencyKey,
      reason: reason,
      timestamp: DateTime.now(),
      priority: priority,
      relatedKeys: dependentKeys.toList(),
    );

    await _addInvalidationEvent(event);
  }

  /// 设置缓存依赖关系
  void setDependency(String dependentKey, String dependencyKey) {
    _dependencyGraph.putIfAbsent(dependentKey, () => {}).add(dependencyKey);
    _reverseDependencyGraph
        .putIfAbsent(dependencyKey, () => {})
        .add(dependentKey);

    AppLogger.debug('🔗 设置缓存依赖: $dependentKey -> $dependencyKey');
  }

  /// 移除缓存依赖关系
  void removeDependency(String dependentKey, String dependencyKey) {
    _dependencyGraph[dependentKey]?.remove(dependencyKey);
    _reverseDependencyGraph[dependencyKey]?.remove(dependentKey);

    // 清理空集合
    if (_dependencyGraph[dependentKey]?.isEmpty == true) {
      _dependencyGraph.remove(dependentKey);
    }
    if (_reverseDependencyGraph[dependencyKey]?.isEmpty == true) {
      _reverseDependencyGraph.remove(dependencyKey);
    }

    AppLogger.debug('🔗 移除缓存依赖: $dependentKey -> $dependencyKey');
  }

  /// 预测性刷新缓存
  Future<void> predictiveRefresh(String key) async {
    if (!_enablePredictiveRefresh) return;

    try {
      // 检查缓存是否存在且即将过期
      final expiration = await _cacheManager.getExpiration(key);
      if (expiration != null && expiration.inMinutes <= 5) {
        final event = CacheInvalidationEvent(
          key: key,
          reason: CacheInvalidationReason.predictiveRefresh,
          timestamp: DateTime.now(),
          priority: CacheInvalidationPriority.low,
          metadata: {'predicted_expiry': expiration.inMinutes},
        );

        await _addInvalidationEvent(event);
        AppLogger.debug('🔮 预测性刷新缓存: $key (${expiration.inMinutes}分钟后过期)');
      }
    } catch (e) {
      AppLogger.debug('预测性刷新失败 $key: $e');
    }
  }

  /// 获取失效统计信息
  Map<String, dynamic> getStats() {
    return {
      'strategy': _strategy.toString(),
      'queue_size': _invalidationQueue.length,
      'pending_count': _pendingInvalidations.length,
      'dependency_count': _dependencyGraph.length,
      'listener_count': _listeners.length,
      'stats': _stats.getSnapshot(),
    };
  }

  /// 清理所有失效任务
  Future<void> clear() async {
    _invalidationQueue.clear();
    _pendingInvalidations.clear();
    _dependencyGraph.clear();
    _reverseDependencyGraph.clear();

    AppLogger.info('🧹 SmartCacheInvalidationManager 已清理');
  }

  /// 销毁失效管理器
  Future<void> dispose() async {
    _processingTimer?.cancel();
    _maintenanceTimer?.cancel();
    _predictiveTimer?.cancel();

    await clear();

    AppLogger.info('🔌 SmartCacheInvalidationManager 已销毁');
  }

  // 私有方法

  void _initialize() {
    AppLogger.debug('🔄 初始化 SmartCacheInvalidationManager');
  }

  /// 添加失效事件到队列
  Future<void> _addInvalidationEvent(CacheInvalidationEvent event) async {
    // 检查队列大小限制
    if (_invalidationQueue.length >= _maxQueueSize) {
      _stats.recordQueueOverflow();
      AppLogger.warn('⚠️ 失效队列已满，丢弃最旧的事件');
      _invalidationQueue.removeFirst();
    }

    // 根据优先级插入事件
    _insertEventByPriority(event);

    // 更新待处理失效映射
    _pendingInvalidations[event.key] = event;

    // 更新统计
    _stats.recordInvalidation(event.reason, event.priority);

    AppLogger.debug('📝 添加失效事件: ${event.key} (${event.reason})');

    // 如果是高优先级或紧急事件，立即处理
    if (event.priority.index >= CacheInvalidationPriority.high.index) {
      await _processInvalidationEvent(event);
    }
  }

  /// 根据优先级插入事件
  void _insertEventByPriority(CacheInvalidationEvent event) {
    if (_invalidationQueue.isEmpty) {
      _invalidationQueue.addLast(event);
      return;
    }

    // 找到插入位置（优先级从高到低）
    Queue<CacheInvalidationEvent> tempQueue = Queue();
    bool inserted = false;

    while (_invalidationQueue.isNotEmpty) {
      final current = _invalidationQueue.removeFirst();

      if (!inserted && current.priority.index < event.priority.index) {
        tempQueue.addLast(event);
        inserted = true;
      }

      tempQueue.addLast(current);
    }

    if (!inserted) {
      tempQueue.addLast(event);
    }

    _invalidationQueue.addAll(tempQueue);
  }

  /// 启动处理定时器
  void _startProcessingTimer() {
    _processingTimer = Timer.periodic(_processingInterval, (_) {
      _processInvalidationQueue();
    });
  }

  /// 启动维护定时器
  void _startMaintenanceTimer() {
    _maintenanceTimer = Timer.periodic(_maintenanceInterval, (_) {
      _performMaintenance();
    });
  }

  /// 启动预测定时器
  void _startPredictiveTimer() {
    _predictiveTimer = Timer.periodic(_predictiveInterval, (_) {
      _performPredictiveRefresh();
    });
  }

  /// 处理失效队列
  Future<void> _processInvalidationQueue() async {
    if (_invalidationQueue.isEmpty) return;

    final startTime = DateTime.now();
    int processedCount = 0;

    try {
      // 批量处理失效事件
      final batch = <CacheInvalidationEvent>[];

      // 每次最多处理10个事件
      while (_invalidationQueue.isNotEmpty && batch.length < 10) {
        final event = _invalidationQueue.removeFirst();
        batch.add(event);
      }

      // 并行处理批量事件
      final futures = batch.map((event) => _processInvalidationEvent(event));
      await Future.wait(futures);

      processedCount = batch.length;
      _stats.recordBatchProcessing(
          processedCount, DateTime.now().difference(startTime));
    } catch (e) {
      AppLogger.error('❌ 处理失效队列失败', e);
      _stats.recordError();
    }
  }

  /// 处理单个失效事件
  Future<void> _processInvalidationEvent(CacheInvalidationEvent event) async {
    try {
      AppLogger.debug('🔄 处理失效事件: ${event.key} (${event.reason})');

      // 执行实际的缓存失效
      await _executeInvalidation(event);

      // 处理相关的依赖失效
      for (final relatedKey in event.relatedKeys) {
        final relatedEvent = CacheInvalidationEvent(
          key: relatedKey,
          reason: CacheInvalidationReason.dependencyUpdated,
          timestamp: DateTime.now(),
          priority: event.priority,
          metadata: {'triggered_by': event.key},
        );

        await _executeInvalidation(relatedEvent);
      }

      // 通知监听器
      _notifyListeners(event);

      // 从待处理映射中移除
      _pendingInvalidations.remove(event.key);

      _stats.recordSuccessfulInvalidation(event.reason);
    } catch (e) {
      AppLogger.error('❌ 处理失效事件失败: ${event.key}', e);
      _stats.recordError();
    }
  }

  /// 执行实际的缓存失效
  Future<void> _executeInvalidation(CacheInvalidationEvent event) async {
    switch (_strategy) {
      case CacheInvalidationStrategy.timeBased:
        await _executeTimeBasedInvalidation(event);
        break;
      case CacheInvalidationStrategy.versionBased:
        await _executeVersionBasedInvalidation(event);
        break;
      case CacheInvalidationStrategy.dependencyBased:
        await _executeDependencyBasedInvalidation(event);
        break;
      case CacheInvalidationStrategy.predictive:
        await _executePredictiveInvalidation(event);
        break;
      case CacheInvalidationStrategy.hybrid:
        await _executeHybridInvalidation(event);
        break;
    }
  }

  /// 基于时间的失效
  Future<void> _executeTimeBasedInvalidation(
      CacheInvalidationEvent event) async {
    await _cacheManager.remove(event.key);
    AppLogger.debug('⏰ 时间失效完成: ${event.key}');
  }

  /// 基于版本的失效
  Future<void> _executeVersionBasedInvalidation(
      CacheInvalidationEvent event) async {
    // 检查缓存键版本信息
    final keyInfo = _keyManager.parseKey(event.key);
    if (keyInfo != null && keyInfo.version != 'latest') {
      await _cacheManager.remove(event.key);
      AppLogger.debug('📦 版本失效完成: ${event.key} (版本: ${keyInfo.version})');
    }
  }

  /// 基于依赖关系的失效
  Future<void> _executeDependencyBasedInvalidation(
      CacheInvalidationEvent event) async {
    await _cacheManager.remove(event.key);

    // 级联失效依赖项
    final dependents = _reverseDependencyGraph[event.key] ?? <String>{};
    for (final dependent in dependents) {
      await _cacheManager.remove(dependent);
    }

    AppLogger.debug('🔗 依赖失效完成: ${event.key} (影响 ${dependents.length} 个依赖项)');
  }

  /// 预测性失效
  Future<void> _executePredictiveInvalidation(
      CacheInvalidationEvent event) async {
    // 预测性失效不直接删除缓存，而是标记为即将过期
    // 这里可以设置一个较短的过期时间
    await _cacheManager.setExpiration(event.key, const Duration(minutes: 1));
    AppLogger.debug('🔮 预测失效完成: ${event.key}');
  }

  /// 混合策略失效
  Future<void> _executeHybridInvalidation(CacheInvalidationEvent event) async {
    // 根据失效原因选择最适合的策略
    switch (event.reason) {
      case CacheInvalidationReason.expired:
      case CacheInvalidationReason.manual:
        await _executeTimeBasedInvalidation(event);
        break;
      case CacheInvalidationReason.versionMismatch:
        await _executeVersionBasedInvalidation(event);
        break;
      case CacheInvalidationReason.dependencyUpdated:
        await _executeDependencyBasedInvalidation(event);
        break;
      case CacheInvalidationReason.predictiveRefresh:
        await _executePredictiveInvalidation(event);
        break;
      default:
        await _executeTimeBasedInvalidation(event);
        break;
    }
  }

  /// 执行维护任务
  Future<void> _performMaintenance() async {
    try {
      AppLogger.debug('🔧 执行缓存失效维护任务');

      // 清理过期的待处理失效
      final now = DateTime.now();
      final expiredKeys = <String>[];

      for (final entry in _pendingInvalidations.entries) {
        if (now.difference(entry.value.timestamp).inHours > 1) {
          expiredKeys.add(entry.key);
        }
      }

      for (final key in expiredKeys) {
        _pendingInvalidations.remove(key);
      }

      if (expiredKeys.isNotEmpty) {
        AppLogger.debug('🧹 清理了 ${expiredKeys.length} 个过期的待处理失效');
      }

      _stats.recordMaintenance();
    } catch (e) {
      AppLogger.error('❌ 执行维护任务失败', e);
    }
  }

  /// 执行预测性刷新
  Future<void> _performPredictiveRefresh() async {
    if (!_enablePredictiveRefresh) return;

    try {
      AppLogger.debug('🔮 执行预测性刷新');

      // 获取所有缓存键
      final allKeys = await _cacheManager.getAllKeys();

      // 并行检查多个键的过期时间
      final futures = allKeys.take(20).map((key) => predictiveRefresh(key));
      await Future.wait(futures);

      _stats.recordPredictiveRefresh();
    } catch (e) {
      AppLogger.error('❌ 预测性刷新失败', e);
    }
  }

  /// 根据模式过滤缓存键
  List<String> _filterKeysByPattern(List<String> keys, String pattern) {
    try {
      // 简单的通配符匹配
      final regex = RegExp(pattern.replaceAll('*', '.*'));
      return keys.where((key) => regex.hasMatch(key)).toList();
    } catch (e) {
      AppLogger.debug('模式匹配失败: $pattern, $e');
      // 降级到简单的字符串包含匹配
      return keys
          .where((key) => key.contains(pattern.replaceAll('*', '')))
          .toList();
    }
  }

  /// 通知所有监听器
  void _notifyListeners(CacheInvalidationEvent event) {
    for (final listener in _listeners) {
      try {
        listener(event);
      } catch (e) {
        AppLogger.debug('监听器通知失败: $e');
      }
    }
  }
}

/// 失效统计信息
class _InvalidationStats {
  int totalInvalidations = 0;
  int successfulInvalidations = 0;
  int batchProcessingCount = 0;
  int queueOverflows = 0;
  int maintenanceCount = 0;
  int predictiveRefreshCount = 0;
  int errorCount = 0;

  final Map<CacheInvalidationReason, int> invalidationReasons = {};
  final Map<CacheInvalidationPriority, int> invalidationPriorities = {};
  final List<Duration> batchProcessingTimes = [];

  void recordInvalidation(
      CacheInvalidationReason reason, CacheInvalidationPriority priority) {
    totalInvalidations++;
    invalidationReasons[reason] = (invalidationReasons[reason] ?? 0) + 1;
    invalidationPriorities[priority] =
        (invalidationPriorities[priority] ?? 0) + 1;
  }

  void recordSuccessfulInvalidation(CacheInvalidationReason reason) {
    successfulInvalidations++;
  }

  void recordBatchProcessing(int count, Duration duration) {
    batchProcessingCount++;
    batchProcessingTimes.add(duration);
  }

  void recordQueueOverflow() {
    queueOverflows++;
  }

  void recordMaintenance() {
    maintenanceCount++;
  }

  void recordPredictiveRefresh() {
    predictiveRefreshCount++;
  }

  void recordError() {
    errorCount++;
  }

  Map<String, dynamic> getSnapshot() {
    final avgBatchTime = batchProcessingTimes.isEmpty
        ? 0.0
        : batchProcessingTimes.fold<int>(
                0, (sum, d) => sum + d.inMilliseconds) /
            batchProcessingTimes.length;

    return {
      'total_invalidations': totalInvalidations,
      'successful_invalidations': successfulInvalidations,
      'success_rate': totalInvalidations > 0
          ? '${(successfulInvalidations / totalInvalidations * 100).toStringAsFixed(1)}%'
          : '0%',
      'batch_processing_count': batchProcessingCount,
      'average_batch_time': '${avgBatchTime.toStringAsFixed(2)}ms',
      'queue_overflows': queueOverflows,
      'maintenance_count': maintenanceCount,
      'predictive_refresh_count': predictiveRefreshCount,
      'error_count': errorCount,
      'invalidation_reasons':
          invalidationReasons.map((k, v) => MapEntry(k.toString(), v)),
      'invalidation_priorities':
          invalidationPriorities.map((k, v) => MapEntry(k.toString(), v)),
    };
  }
}
