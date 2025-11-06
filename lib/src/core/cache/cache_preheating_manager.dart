import 'dart:async';
import 'dart:collection';

import '../utils/logger.dart';
import 'unified_hive_cache_manager.dart';
import 'cache_key_manager.dart';

/// 缓存预热策略
enum CachePreheatingStrategy {
  /// 应用启动时预热
  onStartup,

  /// 后台定时预热
  scheduled,

  /// 按需预热
  onDemand,

  /// 智能预热（基于访问模式）
  intelligent,

  /// 混合策略
  hybrid,
}

/// 缓存预热优先级
enum CachePreheatingPriority {
  /// 低优先级 - 空闲时预热
  low,

  /// 普通优先级 - 正常预热
  normal,

  /// 高优先级 - 尽快预热
  high,

  /// 紧急优先级 - 立即预热
  critical,
}

/// 缓存预热任务
class CachePreheatingTask {
  /// 任务ID
  final String id;

  /// 任务名称
  final String name;

  /// 缓存键列表
  final List<String> cacheKeys;

  /// 数据加载函数
  final Future<Map<String, dynamic>> Function() dataLoader;

  /// 优先级
  final CachePreheatingPriority priority;

  /// 预热策略
  final CachePreheatingStrategy strategy;

  /// 过期时间
  final Duration? expiration;

  /// 依赖的任务ID
  final List<String> dependencies;

  /// 重试次数
  final int maxRetries;

  /// 任务元数据
  final Map<String, dynamic>? metadata;

  /// 创建时间
  final DateTime createdAt;

  /// 执行时间
  DateTime? executedAt;

  /// 完成时间
  DateTime? completedAt;

  /// 重试次数
  int retryCount = 0;

  /// 任务状态
  PreheatingTaskStatus status = PreheatingTaskStatus.pending;

  CachePreheatingTask({
    required this.id,
    required this.name,
    required this.cacheKeys,
    required this.dataLoader,
    this.priority = CachePreheatingPriority.normal,
    this.strategy = CachePreheatingStrategy.onDemand,
    this.expiration,
    this.dependencies = const [],
    this.maxRetries = 3,
    this.metadata,
  }) : createdAt = DateTime.now();

  /// 获取任务执行耗时
  Duration? get executionDuration {
    if (executedAt == null || completedAt == null) return null;
    return completedAt!.difference(executedAt!);
  }

  /// 是否可以执行
  bool get canExecute =>
      status == PreheatingTaskStatus.pending && retryCount < maxRetries;

  @override
  String toString() {
    return 'CachePreheatingTask('
        'id: $id, '
        'name: $name, '
        'status: $status, '
        'priority: $priority, '
        'keys: ${cacheKeys.length}, '
        'retryCount: $retryCount'
        ')';
  }
}

/// 缓存预热任务状态
enum PreheatingTaskStatus {
  /// 等待执行
  pending,

  /// 正在执行
  running,

  /// 执行成功
  completed,

  /// 执行失败
  failed,

  /// 已取消
  cancelled,
}

/// 缓存预热结果
class CachePreheatingResult {
  /// 任务ID
  final String taskId;

  /// 成功预热的缓存键
  final List<String> successfulKeys;

  /// 失败的缓存键及错误信息
  final Map<String, String> failedKeys;

  /// 执行耗时
  final Duration executionTime;

  /// 预热的数据大小（字节）
  final int dataSize;

  /// 任务是否成功
  bool get isSuccess => failedKeys.isEmpty && successfulKeys.isNotEmpty;

  const CachePreheatingResult({
    required this.taskId,
    required this.successfulKeys,
    required this.failedKeys,
    required this.executionTime,
    required this.dataSize,
  });

  @override
  String toString() {
    return 'CachePreheatingResult('
        'taskId: $taskId, '
        'success: $isSuccess, '
        'successful: ${successfulKeys.length}, '
        'failed: ${failedKeys.length}, '
        'duration: ${executionTime.inMilliseconds}ms'
        ')';
  }
}

/// 缓存预热管理器
class CachePreheatingManager {
  static CachePreheatingManager? _instance;
  static CachePreheatingManager get instance {
    _instance ??= CachePreheatingManager._();
    return _instance!;
  }

  CachePreheatingManager._() {
    _initialize();
  }

  // 核心组件
  final UnifiedHiveCacheManager _cacheManager =
      UnifiedHiveCacheManager.instance;
  final CacheKeyManager _keyManager = CacheKeyManager.instance;

  // 任务管理
  final Queue<CachePreheatingTask> _pendingTasks = Queue();
  final Map<String, CachePreheatingTask> _runningTasks = {};
  final Map<String, CachePreheatingTask> _completedTasks = {};
  final Map<String, List<String>> _dependencyGraph = {};

  // 执行器
  Timer? _schedulerTimer;
  Timer? _maintenanceTimer;
  bool _isRunning = false;
  int _maxConcurrentTasks = 3;

  // 统计信息
  final _PreheatingStats _stats = _PreheatingStats();

  // 配置
  CachePreheatingStrategy _defaultStrategy = CachePreheatingStrategy.hybrid;
  Duration _schedulerInterval = const Duration(seconds: 5);
  Duration _maintenanceInterval = const Duration(minutes: 10);
  Duration _taskTimeout = const Duration(minutes: 5);

  /// 初始化预热管理器
  Future<void> initialize({
    CachePreheatingStrategy? defaultStrategy,
    int? maxConcurrentTasks,
    Duration? schedulerInterval,
    Duration? maintenanceInterval,
    Duration? taskTimeout,
  }) async {
    if (_isRunning) return;

    _defaultStrategy = defaultStrategy ?? _defaultStrategy;
    _maxConcurrentTasks = maxConcurrentTasks ?? _maxConcurrentTasks;
    _schedulerInterval = schedulerInterval ?? _schedulerInterval;
    _maintenanceInterval = maintenanceInterval ?? _maintenanceInterval;
    _taskTimeout = taskTimeout ?? _taskTimeout;

    // 启动调度器
    _startScheduler();
    _startMaintenanceTimer();

    _isRunning = true;
    AppLogger.info('🔥 CachePreheatingManager 已启动 (策略: $_defaultStrategy)');
  }

  /// 添加预热任务
  String addPreheatingTask({
    required String name,
    required List<String> cacheKeys,
    required Future<Map<String, dynamic>> Function() dataLoader,
    CachePreheatingPriority priority = CachePreheatingPriority.normal,
    CachePreheatingStrategy? strategy,
    Duration? expiration,
    List<String> dependencies = const [],
    int maxRetries = 3,
    Map<String, dynamic>? metadata,
  }) {
    final taskId = _generateTaskId();
    final task = CachePreheatingTask(
      id: taskId,
      name: name,
      cacheKeys: cacheKeys,
      dataLoader: dataLoader,
      priority: priority,
      strategy: strategy ?? _defaultStrategy,
      expiration: expiration,
      dependencies: dependencies,
      maxRetries: maxRetries,
      metadata: metadata,
    );

    _addTask(task);
    AppLogger.debug('🔥 添加预热任务: $name ($taskId)');

    return taskId;
  }

  /// 添加基金数据预热任务
  String addFundDataPreheatingTask({
    required String symbol,
    CachePreheatingPriority priority = CachePreheatingPriority.normal,
    bool includeRankings = true,
    bool includeDetails = false,
  }) {
    final cacheKeys = <String>[];

    // 生成基金排行缓存键
    if (includeRankings) {
      cacheKeys.add(_keyManager.fundListKey(symbol.isEmpty ? 'all' : symbol));
    }

    // 生成基金详情缓存键
    if (includeDetails) {
      // 这里可以添加具体的基金详情缓存键
    }

    return addPreheatingTask(
      name: '基金数据预热_$symbol',
      cacheKeys: cacheKeys,
      dataLoader: () => _loadFundData(symbol, includeRankings, includeDetails),
      priority: priority,
      strategy: CachePreheatingStrategy.intelligent,
      expiration: const Duration(minutes: 30),
      metadata: {
        'symbol': symbol,
        'include_rankings': includeRankings,
        'include_details': includeDetails,
        'task_type': 'fund_data',
      },
    );
  }

  /// 立即执行预热任务
  Future<CachePreheatingResult?> executeTask(String taskId) async {
    final task = _getTask(taskId);
    if (task == null) {
      AppLogger.warn('⚠️ 预热任务不存在: $taskId');
      return null;
    }

    return await _executeTask(task);
  }

  /// 取消预热任务
  bool cancelTask(String taskId) {
    final task = _getTask(taskId);
    if (task == null) return false;

    if (task.status == PreheatingTaskStatus.running) {
      // 正在运行的任务不能直接取消，标记为取消
      task.status = PreheatingTaskStatus.cancelled;
      _runningTasks.remove(taskId);
    } else if (task.status == PreheatingTaskStatus.pending) {
      // 从待执行队列中移除
      _pendingTasks.remove(task);
    }

    AppLogger.info('🔥 取消预热任务: $taskId');
    return true;
  }

  /// 获取任务状态
  PreheatingTaskStatus? getTaskStatus(String taskId) {
    final task = _getTask(taskId);
    return task?.status;
  }

  /// 获取所有任务状态
  Map<String, PreheatingTaskStatus> getAllTaskStatus() {
    final statusMap = <String, PreheatingTaskStatus>{};

    for (final task in _pendingTasks) {
      statusMap[task.id] = task.status;
    }

    for (final task in _runningTasks.values) {
      statusMap[task.id] = task.status;
    }

    for (final task in _completedTasks.values) {
      statusMap[task.id] = task.status;
    }

    return statusMap;
  }

  /// 获取统计信息
  Map<String, dynamic> getStats() {
    return {
      'is_running': _isRunning,
      'pending_tasks': _pendingTasks.length,
      'running_tasks': _runningTasks.length,
      'completed_tasks': _completedTasks.length,
      'max_concurrent_tasks': _maxConcurrentTasks,
      'default_strategy': _defaultStrategy.toString(),
      'stats': _stats.getSnapshot(),
    };
  }

  /// 清理已完成任务
  void clearCompletedTasks() {
    final cutoffTime = DateTime.now().subtract(const Duration(hours: 1));
    _completedTasks.removeWhere((key, task) {
      return task.completedAt != null && task.completedAt!.isBefore(cutoffTime);
    });

    AppLogger.debug('🔥 清理已完成的预热任务');
  }

  /// 停止预热管理器
  Future<void> stop() async {
    _schedulerTimer?.cancel();
    _maintenanceTimer?.cancel();
    _isRunning = false;

    // 取消所有正在运行的任务
    for (final task in _runningTasks.values) {
      task.status = PreheatingTaskStatus.cancelled;
    }
    _runningTasks.clear();

    AppLogger.info('🔥 CachePreheatingManager 已停止');
  }

  /// 销毁预热管理器
  Future<void> dispose() async {
    await stop();
    _pendingTasks.clear();
    _completedTasks.clear();
    _dependencyGraph.clear();

    AppLogger.info('🔥 CachePreheatingManager 已销毁');
  }

  // 私有方法

  void _initialize() {
    AppLogger.debug('🔥 初始化 CachePreheatingManager');
  }

  String _generateTaskId() {
    return 'preheat_${DateTime.now().millisecondsSinceEpoch}_${_pendingTasks.length}';
  }

  void _addTask(CachePreheatingTask task) {
    // 检查依赖关系
    if (task.dependencies.isNotEmpty) {
      _dependencyGraph[task.id] = [];
      for (final depId in task.dependencies) {
        _dependencyGraph[depId] ??= [];
        _dependencyGraph[task.id]!.add(depId);
      }
    }

    // 根据优先级插入任务
    _insertTaskByPriority(task);

    _stats.recordTaskAdded();
  }

  void _insertTaskByPriority(CachePreheatingTask task) {
    if (_pendingTasks.isEmpty) {
      _pendingTasks.add(task);
      return;
    }

    Queue<CachePreheatingTask> tempQueue = Queue();
    bool inserted = false;

    while (_pendingTasks.isNotEmpty) {
      final current = _pendingTasks.removeFirst();

      if (!inserted && current.priority.index < task.priority.index) {
        tempQueue.addLast(task);
        inserted = true;
      }

      tempQueue.addLast(current);
    }

    if (!inserted) {
      tempQueue.addLast(task);
    }

    _pendingTasks.addAll(tempQueue);
  }

  CachePreheatingTask? _getTask(String taskId) {
    // 在待执行队列中查找
    for (final task in _pendingTasks) {
      if (task.id == taskId) return task;
    }

    // 在正在运行的任务中查找
    return _runningTasks[taskId];
  }

  void _startScheduler() {
    _schedulerTimer = Timer.periodic(_schedulerInterval, (_) {
      _scheduleTasks();
    });
  }

  void _startMaintenanceTimer() {
    _maintenanceTimer = Timer.periodic(_maintenanceInterval, (_) {
      _performMaintenance();
    });
  }

  void _scheduleTasks() {
    // 检查是否还有容量执行新任务
    if (_runningTasks.length >= _maxConcurrentTasks) return;

    // 获取可执行的任务
    final executableTasks = <CachePreheatingTask>[];
    final tempQueue = Queue<CachePreheatingTask>();

    while (_pendingTasks.isNotEmpty &&
        executableTasks.length < _maxConcurrentTasks - _runningTasks.length) {
      final task = _pendingTasks.removeFirst();

      if (task.canExecute && _canExecuteTask(task)) {
        executableTasks.add(task);
      } else {
        tempQueue.addLast(task);
      }
    }

    // 将剩余任务放回队列
    _pendingTasks.addAll(tempQueue);

    // 执行可执行的任务
    for (final task in executableTasks) {
      _executeTaskAsync(task);
    }
  }

  bool _canExecuteTask(CachePreheatingTask task) {
    // 检查依赖是否完成
    for (final depId in task.dependencies) {
      final depTask = _completedTasks[depId];
      if (depTask == null || depTask.status != PreheatingTaskStatus.completed) {
        return false;
      }
    }

    return true;
  }

  void _executeTaskAsync(CachePreheatingTask task) {
    task.status = PreheatingTaskStatus.running;
    task.executedAt = DateTime.now();
    _runningTasks[task.id] = task;

    AppLogger.debug('🔥 开始执行预热任务: ${task.name}');

    // 异步执行任务
    _executeTask(task).timeout(_taskTimeout).then((result) {
      _handleTaskCompletion(task, result);
    }).catchError((e) {
      _handleTaskError(task, e);
    });
  }

  Future<CachePreheatingResult> _executeTask(CachePreheatingTask task) async {
    final startTime = DateTime.now();
    final successfulKeys = <String>[];
    final failedKeys = <String, String>{};
    int totalDataSize = 0;

    try {
      AppLogger.debug('🔥 加载数据: ${task.name} (${task.cacheKeys.length} 个键)');

      // 加载数据
      final data = await task.dataLoader();

      // 存储到缓存
      for (final key in task.cacheKeys) {
        try {
          if (data.containsKey(key)) {
            await _cacheManager.put(
              key,
              data[key],
              expiration: task.expiration,
            );
            successfulKeys.add(key);

            // 估算数据大小
            final dataSize = _estimateDataSize(data[key]);
            totalDataSize += dataSize;
          } else {
            failedKeys[key] = '数据中缺少键: $key';
          }
        } catch (e) {
          failedKeys[key] = e.toString();
          AppLogger.debug('缓存存储失败 $key: $e');
        }
      }

      final executionTime = DateTime.now().difference(startTime);

      AppLogger.info('✅ 预热任务完成: ${task.name} '
          '(成功: ${successfulKeys.length}, 失败: ${failedKeys.length}, '
          '耗时: ${executionTime.inMilliseconds}ms)');

      return CachePreheatingResult(
        taskId: task.id,
        successfulKeys: successfulKeys,
        failedKeys: failedKeys,
        executionTime: executionTime,
        dataSize: totalDataSize,
      );
    } catch (e) {
      AppLogger.error('❌ 预热任务失败: ${task.name}', e);
      rethrow;
    }
  }

  void _handleTaskCompletion(
      CachePreheatingTask task, CachePreheatingResult result) {
    task.status = result.isSuccess
        ? PreheatingTaskStatus.completed
        : PreheatingTaskStatus.failed;
    task.completedAt = DateTime.now();
    _runningTasks.remove(task.id);
    _completedTasks[task.id] = task;

    _stats.recordTaskCompleted(result);
    AppLogger.debug('🔥 任务执行完成: ${task.name}');
  }

  void _handleTaskError(CachePreheatingTask task, dynamic error) {
    task.retryCount++;

    if (task.retryCount < task.maxRetries) {
      // 重新加入队列进行重试
      task.status = PreheatingTaskStatus.pending;
      _insertTaskByPriority(task);
      AppLogger.warn('⚠️ 预热任务失败，准备重试: ${task.name} (第${task.retryCount}次)');
    } else {
      // 超过最大重试次数，标记为失败
      task.status = PreheatingTaskStatus.failed;
      task.completedAt = DateTime.now();
      _stats.recordTaskFailed();
      AppLogger.error('❌ 预热任务最终失败: ${task.name}', error);
    }

    _runningTasks.remove(task.id);
  }

  void _performMaintenance() {
    try {
      AppLogger.debug('🔥 执行预热任务维护');

      // 清理过期的已完成任务
      clearCompletedTasks();

      // 检查长时间运行的任务
      final now = DateTime.now();
      final longRunningTasks = <String>[];

      for (final task in _runningTasks.values) {
        if (task.executedAt != null &&
            now.difference(task.executedAt!).inMinutes > 10) {
          longRunningTasks.add(task.id);
        }
      }

      // 终止长时间运行的任务
      for (final taskId in longRunningTasks) {
        final task = _runningTasks[taskId];
        if (task != null) {
          task.status = PreheatingTaskStatus.failed;
          _runningTasks.remove(taskId);
          AppLogger.warn('⚠️ 终止长时间运行的预热任务: ${task.name}');
        }
      }

      _stats.recordMaintenance();
    } catch (e) {
      AppLogger.error('❌ 预热任务维护失败', e);
    }
  }

  Future<Map<String, dynamic>> _loadFundData(
      String symbol, bool includeRankings, bool includeDetails) async {
    final data = <String, dynamic>{};

    if (includeRankings) {
      try {
        // 这里应该调用实际的基金数据API
        // 模拟加载基金排行数据
        await Future.delayed(const Duration(seconds: 2));

        final cacheKey =
            _keyManager.fundListKey(symbol.isEmpty ? 'all' : symbol);
        data[cacheKey] = {
          'symbol': symbol,
          'timestamp': DateTime.now().toIso8601String(),
          'data': '模拟的基金排行数据', // 实际应用中这里应该是真实的基金数据
        };

        AppLogger.debug('🔥 加载基金排行数据: $symbol');
      } catch (e) {
        AppLogger.error('❌ 加载基金排行数据失败: $symbol', e);
      }
    }

    if (includeDetails) {
      // 这里可以加载基金详情数据
      AppLogger.debug('🔥 加载基金详情数据: $symbol (暂未实现)');
    }

    return data;
  }

  int _estimateDataSize(dynamic data) {
    // 简化的数据大小估算
    if (data == null) return 0;
    if (data is String) return data.length;
    if (data is Map) return data.length * 50; // 假设每个条目50字节
    if (data is List) return data.length * 50;
    return 100; // 默认估算值
  }
}

/// 预热统计信息
class _PreheatingStats {
  int totalTasksAdded = 0;
  int totalTasksCompleted = 0;
  int totalTasksFailed = 0;
  int maintenanceCount = 0;
  final List<Duration> executionTimes = [];

  void recordTaskAdded() {
    totalTasksAdded++;
  }

  void recordTaskCompleted(CachePreheatingResult result) {
    totalTasksCompleted++;
    executionTimes.add(result.executionTime);
  }

  void recordTaskFailed() {
    totalTasksFailed++;
  }

  void recordMaintenance() {
    maintenanceCount++;
  }

  Map<String, dynamic> getSnapshot() {
    final avgExecutionTime = executionTimes.isEmpty
        ? 0.0
        : executionTimes.fold<int>(0, (sum, d) => sum + d.inMilliseconds) /
            executionTimes.length;

    return {
      'total_tasks_added': totalTasksAdded,
      'total_tasks_completed': totalTasksCompleted,
      'total_tasks_failed': totalTasksFailed,
      'success_rate': totalTasksAdded > 0
          ? '${(totalTasksCompleted / totalTasksAdded * 100).toStringAsFixed(1)}%'
          : '0%',
      'average_execution_time_ms': avgExecutionTime.toStringAsFixed(2),
      'maintenance_count': maintenanceCount,
    };
  }
}

/// 缓存预热辅助类
class CachePreheatingHelper {
  static final CachePreheatingManager _manager =
      CachePreheatingManager.instance;

  /// 预热热门基金数据
  static String preheatPopularFunds({List<String>? symbols}) {
    return _manager.addFundDataPreheatingTask(
      symbol: 'popular_funds',
      priority: CachePreheatingPriority.high,
      includeRankings: true,
    );
  }

  /// 预热用户关注的基金
  static String preheatUserFavorites(List<String> favoriteSymbols) {
    return _manager.addFundDataPreheatingTask(
      symbol: 'user_favorites',
      priority: CachePreheatingPriority.normal,
      includeRankings: true,
    );
  }

  /// 预热市场概览数据
  static String preheatMarketOverview() {
    return _manager.addPreheatingTask(
      name: '市场概览预热',
      cacheKeys: ['market_overview', 'market_indices', 'sector_performance'],
      dataLoader: () async {
        await Future.delayed(const Duration(seconds: 1));
        return {
          'market_overview': {'status': 'up', 'change': '+1.2%'},
          'market_indices': {'sh': '3200', 'sz': '12000'},
          'sector_performance': {'tech': '+2.1%', 'finance': '+0.8%'},
        };
      },
      priority: CachePreheatingPriority.high,
      strategy: CachePreheatingStrategy.onStartup,
      expiration: const Duration(minutes: 15),
    );
  }
}
