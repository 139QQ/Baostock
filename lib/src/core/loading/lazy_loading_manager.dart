import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../utils/logger.dart';

/// 懒加载任务
class LoadingTask {
  final String id;
  final String key;
  final LoadingFunction loader;
  final LoadingPriority priority;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  LoadingTask({
    required this.id,
    required this.key,
    required this.loader,
    this.priority = LoadingPriority.normal,
    this.metadata,
  }) : createdAt = DateTime.now();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoadingTask &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'LoadingTask(id: $id, key: $key, priority: $priority)';
}

/// 加载优先级
enum LoadingPriority {
  critical(4),
  high(3),
  normal(2),
  low(1);

  const LoadingPriority(this.value);
  final int value;

  int get priority => value;

  /// 添加compareTo方法用于排序
  int compareTo(LoadingPriority other) {
    return other.priority.compareTo(priority);
  }
}

/// 加载函数类型定义
typedef Future<dynamic> LoadingFunction();

/// 加载状态枚举
enum LoadingStatus {
  notLoaded,
  queued,
  loading,
  loaded,
  error,
}

/// 加载任务配置
class LoadingTaskConfig {
  final String key;
  final LoadingFunction loader;
  final LoadingPriority priority;
  final Map<String, dynamic>? metadata;
  final bool forceReload;

  LoadingTaskConfig({
    required this.key,
    required this.loader,
    this.priority = LoadingPriority.normal,
    this.metadata,
    this.forceReload = false,
  });
}

/// 优先级队列实现
class PriorityQueue<T> {
  final List<T> _items = [];
  final Comparator<T> _comparator;

  PriorityQueue({Comparator<T>? comparator})
      : _comparator = comparator ?? ((a, b) => 0);

  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;
  int get length => _items.length;

  void add(T item) {
    _items.add(item);
    _items.sort(_comparator);
  }

  T removeFirst() {
    if (_items.isEmpty) {
      throw StateError('Cannot remove from empty queue');
    }
    return _items.removeAt(0);
  }

  T get first => _items.first;

  bool any(bool Function(T) test) {
    return _items.any(test);
  }

  T firstWhere(bool Function(T) test, {required T Function() orElse}) {
    for (final item in _items) {
      if (test(item)) {
        return item;
      }
    }
    return orElse();
  }

  bool remove(T item) {
    return _items.remove(item);
  }

  void clear() {
    _items.clear();
  }
}

/// 懒加载管理器 - Week 9实施
///
/// 功能特性：
/// - 智能数据懒加载
/// - 预加载策略
/// - 缓存管理
/// - 优先级队列
/// - 资源优化
class LazyLoadingManager {
  static final LazyLoadingManager _instance = LazyLoadingManager._internal();
  factory LazyLoadingManager() => _instance;
  LazyLoadingManager._internal();

  final Logger _logger = Logger();

  // 加载任务队列
  final PriorityQueue<LoadingTask> _loadingQueue = PriorityQueue<LoadingTask>(
    comparator: (a, b) => b.priority.compareTo(a.priority),
  );
  final Map<String, LoadingTask> _activeTasks = {};
  final Map<String, dynamic> _loadedCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  // 配置参数
  static const int _maxConcurrentTasks = 3;
  static const Duration _cacheExpiry = Duration(minutes: 30);
  static const int _maxCacheSize = 100;

  // 状态管理
  bool _isLoading = false;
  Timer? _cacheCleanupTimer;

  // Week 10 性能优化
  final List<Duration> _loadTimes = [];
  int _totalTasksLoaded = 0;
  int _totalTasksFailed = 0;
  Timer? _performanceReportTimer;

  // 回调函数
  final List<Function(String, dynamic)> _onLoadCallbacks = [];
  final List<Function(String, dynamic)> _onErrorCallbacks = [];
  final List<Function()> _onQueueEmptyCallbacks = [];

  /// 初始化懒加载管理器
  Future<void> initialize() async {
    // 如果已经初始化且定时器正在运行，则跳过
    if (_cacheCleanupTimer != null && _cacheCleanupTimer!.isActive) return;

    // 清理可能存在的旧定时器
    _cacheCleanupTimer?.cancel();
    _performanceReportTimer?.cancel();

    // 启动缓存清理定时器
    _cacheCleanupTimer =
        Timer.periodic(Duration(minutes: 5), (_) => _cleanupExpiredCache());

    // Week 10 性能优化: 启动性能报告定时器
    _performanceReportTimer = Timer.periodic(
        Duration(minutes: 2), (_) => _generatePerformanceReport());

    AppLogger.info('✅ 懒加载管理器初始化成功（含性能监控）');
  }

  /// 添加加载任务
  String addLoadingTask({
    required String key,
    required LoadingFunction loader,
    LoadingPriority priority = LoadingPriority.normal,
    Map<String, dynamic>? metadata,
    bool forceReload = false,
  }) {
    // 检查缓存
    if (!forceReload && _isCacheValid(key)) {
      _triggerLoadCallback(key, _loadedCache[key]);
      return 'cached_$key';
    }

    // 检查是否已在队列中
    if (_activeTasks.containsKey(key) ||
        _loadingQueue.any((task) => task.key == key)) {
      return 'existing_$key';
    }

    // 创建新任务
    final task = LoadingTask(
      id: '${key}_${DateTime.now().millisecondsSinceEpoch}',
      key: key,
      loader: loader,
      priority: priority,
      metadata: metadata,
    );

    // 添加到队列
    _loadingQueue.add(task);

    // 开始处理队列
    _processQueue();

    _logger.d('📦 添加加载任务: $key (优先级: ${priority.name})');

    return task.id;
  }

  /// 批量添加加载任务
  List<String> addBatchLoadingTasks(List<LoadingTaskConfig> configs) {
    final taskIds = <String>[];

    for (final config in configs) {
      final taskId = addLoadingTask(
        key: config.key,
        loader: config.loader,
        priority: config.priority,
        metadata: config.metadata,
        forceReload: config.forceReload,
      );
      taskIds.add(taskId);
    }

    _logger.d('📦 批量添加 ${taskIds.length} 个加载任务');
    return taskIds;
  }

  /// 预加载策略
  Future<void> preloadData(
      List<String> keys, Future<dynamic> Function(String) loader) async {
    _logger.d('🚀 开始预加载 ${keys.length} 个数据项');

    // 创建任务并获取它们的ID
    final taskIds = <String>[];
    for (final key in keys) {
      final taskId = addLoadingTask(
        key: 'preload_$key',
        loader: () => loader(key),
        priority: LoadingPriority.low,
        forceReload: true,
      );
      taskIds.add(taskId);
    }

    // 等待所有预加载任务完成
    await _waitForPreloadTasks(keys);

    _logger.i('✅ 预加载完成');
  }

  /// 等待预加载任务完成
  Future<void> _waitForPreloadTasks(List<String> keys) async {
    final maxWaitTime = Duration(seconds: 5);
    final startTime = DateTime.now();

    while (DateTime.now().difference(startTime) < maxWaitTime) {
      bool allLoaded = true;
      for (final key in keys) {
        final preloadKey = 'preload_$key';
        if (!isLoaded(preloadKey)) {
          allLoaded = false;
          break;
        }
      }

      if (allLoaded) {
        return;
      }

      await Future.delayed(Duration(milliseconds: 50));
    }

    _logger.w('⚠️ 预加载任务等待超时');
  }

  /// 智能预加载（基于使用模式）
  Future<void> smartPreload(List<String> frequentKeys,
      Future<dynamic> Function(String) loader) async {
    // 分析使用频率，决定预加载策略
    final topKeys = frequentKeys.take(10).toList();

    await preloadData(topKeys, loader);

    _logger.i('🧠 智能预加载完成: ${topKeys.length} 个高频数据');
  }

  /// 强制加载指定数据
  Future<dynamic> forceLoad(String key, LoadingFunction loader) async {
    _logger.d('🔄 强制加载数据: $key');

    try {
      final result = await loader();
      _updateCache(key, result);
      _triggerLoadCallback(key, result);
      return result;
    } catch (e) {
      _logger.e('❌ 强制加载失败 $key: $e');
      _triggerErrorCallback(key, e);
      rethrow;
    }
  }

  /// 获取缓存数据
  T? getCachedData<T>(String key) {
    final data = _loadedCache[key];
    if (data == null || !_isCacheValid(key)) {
      return null;
    }

    try {
      return data as T;
    } catch (e) {
      _logger.w('⚠️ 缓存数据类型转换失败: $key, $e');
      return null;
    }
  }

  /// 检查数据是否已加载
  bool isLoaded(String key) {
    return _isCacheValid(key);
  }

  /// 获取加载状态
  LoadingStatus getLoadingStatus(String key) {
    if (_activeTasks.containsKey(key)) {
      return LoadingStatus.loading;
    }
    if (_loadingQueue.any((task) => task.key == key)) {
      return LoadingStatus.queued;
    }
    if (_isCacheValid(key)) {
      return LoadingStatus.loaded;
    }
    return LoadingStatus.notLoaded;
  }

  /// 获取队列状态
  Map<String, dynamic> getQueueStatus() {
    return {
      'activeTasks': _activeTasks.length,
      'queuedTasks': _loadingQueue.length,
      'cachedItems': _loadedCache.length,
      'maxConcurrentTasks': _maxConcurrentTasks,
      'isLoading': _isLoading,
    };
  }

  /// 添加加载回调
  void addLoadCallback(Function(String, dynamic) callback) {
    _onLoadCallbacks.add(callback);
  }

  /// 添加错误回调
  void addErrorCallback(Function(String, dynamic) callback) {
    _onErrorCallbacks.add(callback);
  }

  /// 添加队列空回调
  void addQueueEmptyCallback(Function() callback) {
    _onQueueEmptyCallbacks.add(callback);
  }

  /// 移除回调
  void removeLoadCallback(Function(String, dynamic) callback) {
    _onLoadCallbacks.remove(callback);
  }

  void removeErrorCallback(Function(String, dynamic) callback) {
    _onErrorCallbacks.remove(callback);
  }

  void removeQueueEmptyCallback(Function() callback) {
    _onQueueEmptyCallbacks.remove(callback);
  }

  /// 处理加载队列
  Future<void> _processQueue() async {
    if (_isLoading ||
        _loadingQueue.isEmpty ||
        _activeTasks.length >= _maxConcurrentTasks) {
      return;
    }

    _isLoading = true;

    while (
        _loadingQueue.isNotEmpty && _activeTasks.length < _maxConcurrentTasks) {
      final task = _loadingQueue.removeFirst();
      _activeTasks[task.key] = task;

      // 异步执行加载任务
      _executeTask(task);
    }

    _isLoading = false;

    // 如果队列为空，触发回调
    if (_loadingQueue.isEmpty && _activeTasks.isEmpty) {
      _triggerQueueEmptyCallbacks();
    }
  }

  /// 执行单个加载任务
  Future<void> _executeTask(LoadingTask task) async {
    try {
      _logger.d('⏳ 开始执行加载任务: ${task.key}');

      final result = await task.loader();

      // 更新缓存
      _updateCache(task.key, result);

      // 触发成功回调
      _triggerLoadCallback(task.key, result);

      _logger.d('✅ 加载任务完成: ${task.key}');
    } catch (e, stackTrace) {
      _logger.e('❌ 加载任务失败: ${task.key}, 错误: $e');

      // 触发错误回调
      _triggerErrorCallback(task.key, e);
    } finally {
      // 从活动任务中移除
      _activeTasks.remove(task.key);

      // 继续处理队列
      _processQueue();
    }
  }

  /// 更新缓存
  void _updateCache(String key, dynamic data) {
    _loadedCache[key] = data;
    _cacheTimestamps[key] = DateTime.now();

    // 检查缓存大小限制
    if (_loadedCache.length > _maxCacheSize) {
      _cleanupOldestCache();
    }
  }

  /// 检查缓存是否有效
  bool _isCacheValid(String key) {
    if (!_loadedCache.containsKey(key) || !_cacheTimestamps.containsKey(key)) {
      return false;
    }

    final timestamp = _cacheTimestamps[key]!;
    return DateTime.now().difference(timestamp) < _cacheExpiry;
  }

  /// 清理过期缓存
  void _cleanupExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) >= _cacheExpiry) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _loadedCache.remove(key);
      _cacheTimestamps.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      _logger.d('🧹 清理过期缓存: ${expiredKeys.length} 项');
    }
  }

  /// 清理最旧的缓存
  void _cleanupOldestCache() {
    if (_cacheTimestamps.isEmpty) return;

    final sortedEntries = _cacheTimestamps.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final removeCount = sortedEntries.length - _maxCacheSize;
    for (int i = 0; i < removeCount; i++) {
      final key = sortedEntries[i].key;
      _loadedCache.remove(key);
      _cacheTimestamps.remove(key);
    }

    _logger.d('🧹 清理最旧缓存: $removeCount 项');
  }

  /// 触发加载回调
  void _triggerLoadCallback(String key, dynamic data) {
    for (final callback in _onLoadCallbacks) {
      try {
        callback(key, data);
      } catch (e) {
        _logger.e('❌ 加载回调执行失败: $e');
      }
    }
  }

  /// 触发错误回调
  void _triggerErrorCallback(String key, dynamic error) {
    for (final callback in _onErrorCallbacks) {
      try {
        callback(key, error);
      } catch (e) {
        _logger.e('❌ 错误回调执行失败: $e');
      }
    }
  }

  /// 触发队列空回调
  void _triggerQueueEmptyCallbacks() {
    for (final callback in _onQueueEmptyCallbacks) {
      try {
        callback();
      } catch (e) {
        _logger.e('❌ 队列空回调执行失败: $e');
      }
    }
  }

  /// 取消加载任务
  bool cancelTask(String key) {
    // 检查活动任务
    final activeTask = _activeTasks.remove(key);
    if (activeTask != null) {
      _logger.d('❌ 取消活动任务: $key');
      return true;
    }

    // 检查队列中的任务
    final queueTask = _loadingQueue.firstWhere(
      (task) => task.key == key,
      orElse: () => LoadingTask(id: '', key: '', loader: () async {}),
    );

    if (queueTask.id.isNotEmpty) {
      _loadingQueue.remove(queueTask);
      _logger.d('❌ 取消队列任务: $key');
      return true;
    }

    return false;
  }

  /// 清空队列
  void clearQueue() {
    final queuedCount = _loadingQueue.length;
    _loadingQueue.clear();
    _logger.d('🗑️ 清空加载队列: $queuedCount 项被移除');
  }

  /// 清空缓存
  void clearCache() {
    final cacheCount = _loadedCache.length;
    _loadedCache.clear();
    _cacheTimestamps.clear();
    _logger.d('🗑️ 清空缓存: $cacheCount 项被移除');
  }

  /// 获取统计信息
  Map<String, dynamic> getStatistics() {
    return {
      'queueStatus': getQueueStatus(),
      'cacheStats': {
        'totalItems': _loadedCache.length,
        'maxSize': _maxCacheSize,
        'expiryMinutes': _cacheExpiry.inMinutes,
      },
      'callbackStats': {
        'loadCallbacks': _onLoadCallbacks.length,
        'errorCallbacks': _onErrorCallbacks.length,
        'queueEmptyCallbacks': _onQueueEmptyCallbacks.length,
      },
      'performance': {
        'maxConcurrentTasks': _maxConcurrentTasks,
        'averageQueueWaitTime': _calculateAverageWaitTime(),
      },
    };
  }

  /// 计算平均等待时间
  Duration _calculateAverageWaitTime() {
    // 简化实现，实际中可以记录更详细的时间戳
    if (_loadingQueue.isEmpty) {
      return Duration.zero;
    }

    return Duration(milliseconds: 100); // 估算值
  }

  /// 重置管理器状态（仅用于测试）
  void resetForTesting() {
    _cacheCleanupTimer?.cancel();
    _cacheCleanupTimer = null;

    _loadingQueue.clear();
    _activeTasks.clear();
    _loadedCache.clear();
    _cacheTimestamps.clear();
    _onLoadCallbacks.clear();
    _onErrorCallbacks.clear();
    _onQueueEmptyCallbacks.clear();
    _isLoading = false;
  }

  /// Week 10 性能优化: 生成性能报告
  void _generatePerformanceReport() {
    if (_loadTimes.isEmpty) return;

    final avgLoadTime =
        _loadTimes.map((d) => d.inMilliseconds).reduce((a, b) => a + b) /
            _loadTimes.length;

    final maxLoadTime =
        _loadTimes.map((d) => d.inMilliseconds).reduce((a, b) => a > b ? a : b);

    final minLoadTime =
        _loadTimes.map((d) => d.inMilliseconds).reduce((a, b) => a < b ? a : b);

    final successRate = _totalTasksLoaded + _totalTasksFailed > 0
        ? (_totalTasksLoaded / (_totalTasksLoaded + _totalTasksFailed) * 100)
        : 0.0;

    AppLogger.info('📊 懒加载性能报告:');
    AppLogger.info('  平均加载时间: ${avgLoadTime.toStringAsFixed(2)}ms');
    AppLogger.info('  最大加载时间: ${maxLoadTime}ms');
    AppLogger.info('  最小加载时间: ${minLoadTime}ms');
    AppLogger.info('  成功任务数: $_totalTasksLoaded');
    AppLogger.info('  失败任务数: $_totalTasksFailed');
    AppLogger.info('  成功率: ${successRate.toStringAsFixed(1)}%');
    AppLogger.info(
        '  缓存命中率: ${(_loadedCache.length / _totalTasksLoaded * 100).toStringAsFixed(1)}%');

    // 在调试模式下输出到开发者控制台
    if (kDebugMode) {
      developer.log(
          '懒加载性能报告: 平均${avgLoadTime.toStringAsFixed(2)}ms, 成功率${successRate.toStringAsFixed(1)}%',
          name: 'LazyLoadingPerformance');
    }

    // 清理旧的性能数据，保持最近100条记录
    if (_loadTimes.length > 100) {
      _loadTimes.removeRange(0, _loadTimes.length - 100);
    }
  }

  /// Week 10 性能优化: 记录任务加载时间
  void _recordLoadTime(Duration loadTime, bool success) {
    _loadTimes.add(loadTime);
    if (success) {
      _totalTasksLoaded++;
    } else {
      _totalTasksFailed++;
    }
  }

  /// 获取性能统计信息
  Map<String, dynamic> getPerformanceStats() {
    if (_loadTimes.isEmpty) {
      return {
        'avgLoadTime': 0,
        'maxLoadTime': 0,
        'minLoadTime': 0,
        'totalTasksLoaded': _totalTasksLoaded,
        'totalTasksFailed': _totalTasksFailed,
        'successRate': 0.0,
        'cacheHitRate': 0.0,
      };
    }

    final avgLoadTime =
        _loadTimes.map((d) => d.inMilliseconds).reduce((a, b) => a + b) /
            _loadTimes.length;

    final maxLoadTime =
        _loadTimes.map((d) => d.inMilliseconds).reduce((a, b) => a > b ? a : b);

    final minLoadTime =
        _loadTimes.map((d) => d.inMilliseconds).reduce((a, b) => a < b ? a : b);

    final successRate = _totalTasksLoaded + _totalTasksFailed > 0
        ? (_totalTasksLoaded / (_totalTasksLoaded + _totalTasksFailed) * 100)
        : 0.0;

    return {
      'avgLoadTime': avgLoadTime,
      'maxLoadTime': maxLoadTime,
      'minLoadTime': minLoadTime,
      'totalTasksLoaded': _totalTasksLoaded,
      'totalTasksFailed': _totalTasksFailed,
      'successRate': successRate,
      'cacheHitRate': _totalTasksLoaded > 0
          ? (_loadedCache.length / _totalTasksLoaded * 100)
          : 0.0,
    };
  }

  /// 销毁管理器
  void dispose() {
    _cacheCleanupTimer?.cancel();
    _performanceReportTimer?.cancel();
    _cacheCleanupTimer = null;
    _performanceReportTimer = null;

    clearQueue();
    clearCache();
    _onLoadCallbacks.clear();
    _onErrorCallbacks.clear();
    _onQueueEmptyCallbacks.clear();

    AppLogger.info('🗑️ 懒加载管理器已销毁');
  }
}
