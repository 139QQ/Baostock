import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import '../../../../core/utils/logger.dart';
import '../../models/fund_nav_data.dart';

/// 智能缓存更新策略管理器
///
/// 基于数据新鲜度、访问模式、系统负载等因素动态调整缓存更新策略
/// 实现智能预取、优先级调度和自适应更新频率
class IntelligentCacheStrategy {
  /// 单例实例
  static final IntelligentCacheStrategy _instance = IntelligentCacheStrategy._internal();

  factory IntelligentCacheStrategy() => _instance;

  IntelligentCacheStrategy._internal() {
    _initialize();
  }

  /// 策略配置
  final StrategyConfig _config = StrategyConfig();

  /// 访问模式分析器
  final AccessPatternAnalyzer _patternAnalyzer = AccessPatternAnalyzer();

  /// 数据新鲜度管理器
  final DataFreshnessManager _freshnessManager = DataFreshnessManager();

  /// 预取调度器
  final PrefetchScheduler _prefetchScheduler = PrefetchScheduler();

  /// 优先级管理器
  final PriorityManager _priorityManager = PriorityManager();

  /// 缓存策略映射
  final Map<String, CacheStrategy> _fundStrategies = {};

  /// 更新任务队列
  final Queue<UpdateTask> _updateQueue = Queue<UpdateTask>();

  /// 更新定时器
  Timer? _updateTimer;

  /// 性能监控
  final StrategyPerformanceMonitor _performanceMonitor = StrategyPerformanceMonitor();

  /// 策略统计
  final StrategyStatistics _statistics = StrategyStatistics();

  /// 初始化策略管理器
  Future<void> _initialize() async {
    try {
      // 启动更新调度器
      _startUpdateScheduler();

      // 启动预取调度器
      _prefetchScheduler.start();

      // 启动性能监控
      _performanceMonitor.start();

      AppLogger.info('IntelligentCacheStrategy initialized successfully');
    } catch (e) {
      AppLogger.error('Failed to initialize IntelligentCacheStrategy', e);
    }
  }

  /// 注册基金缓存策略
  void registerFundStrategy(String fundCode, CacheStrategy strategy) {
    _fundStrategies[fundCode] = strategy;
    _patternAnalyzer.trackFund(fundCode);
    _freshnessManager.trackFund(fundCode);

    AppLogger.debug('注册基金缓存策略: $fundCode -> ${strategy.name}');
  }

  /// 分析并更新策略
  Future<void> analyzeAndUpdateStrategy(String fundCode, {FundNavData? navData}) async {
    try {
      // 1. 分析访问模式
      final accessPattern = _patternAnalyzer.analyzePattern(fundCode);

      // 2. 评估数据新鲜度
      final freshnessScore = _freshnessManager.calculateFreshnessScore(fundCode, navData);

      // 3. 计算动态优先级
      final priority = _priorityManager.calculatePriority(
        fundCode,
        accessPattern,
        freshnessScore,
      );

      // 4. 生成或更新策略
      final strategy = _generateOptimalStrategy(fundCode, accessPattern, freshnessScore, priority);
      _fundStrategies[fundCode] = strategy;

      // 5. 调度更新任务
      _scheduleUpdateTask(fundCode, strategy);

      // 6. 记录统计
      _statistics.recordStrategyUpdate(fundCode, strategy);

      AppLogger.debug('策略更新完成: $fundCode -> ${strategy.name} (优先级: ${priority.toStringAsFixed(2)})');
    } catch (e) {
      AppLogger.error('分析更新策略失败: $fundCode', e);
    }
  }

  /// 批量分析并更新策略
  Future<void> batchUpdateStrategies(List<String> fundCodes) async {
    try {
      AppLogger.debug('开始批量更新策略: ${fundCodes.length}个基金');

      // 并发分析
      final futures = fundCodes.map((fundCode) => analyzeAndUpdateStrategy(fundCode));
      await Future.wait(futures);

      AppLogger.info('批量策略更新完成: ${fundCodes.length}个基金');
    } catch (e) {
      AppLogger.error('批量更新策略失败', e);
    }
  }

  /// 获取基金缓存策略
  CacheStrategy? getFundStrategy(String fundCode) {
    return _fundStrategies[fundCode];
  }

  /// 获取推荐更新时间
  DateTime? getRecommendedUpdateTime(String fundCode) {
    final strategy = _fundStrategies[fundCode];
    if (strategy == null) return null;

    return DateTime.now().add(strategy.updateInterval);
  }

  /// 检查是否需要更新
  bool shouldUpdate(String fundCode, {DateTime? lastUpdate}) {
    final strategy = _fundStrategies[fundCode];
    if (strategy == null) return false;

    final effectiveLastUpdate = lastUpdate ?? DateTime.now().subtract(strategy.updateInterval * 2);
    final nextUpdate = effectiveLastUpdate.add(strategy.updateInterval);

    return DateTime.now().isAfter(nextUpdate);
  }

  /// 智能预取建议
  List<String> getPrefetchSuggestions({int limit = 10}) {
    return _prefetchGenerator.getSuggestions(limit: limit);
  }

  /// 动态调整更新频率
  void adjustUpdateFrequency(String fundCode, {bool? increase, Duration? customInterval}) {
    final strategy = _fundStrategies[fundCode];
    if (strategy == null) return;

    Duration newInterval;
    if (customInterval != null) {
      newInterval = customInterval;
    } else if (increase == true) {
      newInterval = Duration(milliseconds: (strategy.updateInterval.inMilliseconds * 0.8).round());
    } else if (increase == false) {
      newInterval = Duration(milliseconds: (strategy.updateInterval.inMilliseconds * 1.2).round());
    } else {
      return;
    }

    // 限制更新频率范围
    if (newInterval < const Duration(seconds: 10)) {
      newInterval = const Duration(seconds: 10);
    } else if (newInterval > const Duration(hours: 1)) {
      newInterval = const Duration(hours: 1);
    }

    strategy.updateInterval = newInterval;
    _statistics.recordFrequencyAdjustment(fundCode, strategy.updateInterval);

    AppLogger.debug('调整更新频率: $fundCode -> ${newInterval.inSeconds}秒');
  }

  /// 获取策略统计
  Map<String, dynamic> getStrategyStatistics() {
    return {
      'totalStrategies': _fundStrategies.length,
      'strategyDistribution': _getStrategyDistribution(),
      'averageUpdateInterval': _calculateAverageUpdateInterval(),
      'performanceMetrics': _performanceMonitor.getMetrics(),
      'statistics': _statistics.toJson(),
      'lastOptimized': DateTime.now().toIso8601String(),
    };
  }

  /// 生成最优策略
  CacheStrategy _generateOptimalStrategy(
    String fundCode,
    AccessPattern accessPattern,
    double freshnessScore,
    double priority,
  ) {
    // 基于访问模式选择基础策略
    CacheStrategy baseStrategy;
    switch (accessPattern.type) {
      case AccessPatternType.frequent:
        baseStrategy = CacheStrategy.highFrequency;
        break;
      case AccessPatternType.regular:
        baseStrategy = CacheStrategy.balanced;
        break;
      case AccessPatternType.sporadic:
        baseStrategy = CacheStrategy.lowFrequency;
        break;
      case AccessPatternType.peak:
        baseStrategy = CacheStrategy.adaptive;
        break;
    }

    // 根据新鲜度调整
    Duration updateInterval = baseStrategy.updateInterval;
    if (freshnessScore < 0.3) {
      updateInterval = Duration(milliseconds: (updateInterval.inMilliseconds * 0.5).round());
    } else if (freshnessScore > 0.8) {
      updateInterval = Duration(milliseconds: (updateInterval.inMilliseconds * 1.5).round());
    }

    // 根据优先级调整
    if (priority > 0.8) {
      updateInterval = Duration(milliseconds: (updateInterval.inMilliseconds * 0.7).round());
    } else if (priority < 0.3) {
      updateInterval = Duration(milliseconds: (updateInterval.inMilliseconds * 1.3).round());
    }

    return CacheStrategy(
      name: 'dynamic_${fundCode}',
      updateInterval: updateInterval,
      prefetchEnabled: priority > 0.5 && accessPattern.frequency > 0.3,
      compressionEnabled: accessPattern.dataSize > 1024 * 1024, // 1MB
      priority: priority,
      accessPattern: accessPattern,
      freshnessScore: freshnessScore,
    );
  }

  /// 调度更新任务
  void _scheduleUpdateTask(String fundCode, CacheStrategy strategy) {
    final task = UpdateTask(
      fundCode: fundCode,
      strategy: strategy,
      scheduledTime: DateTime.now().add(strategy.updateInterval),
      priority: strategy.priority,
    );

    _updateQueue.add(task);
    final sortedQueue = List<UpdateTask>.from(_updateQueue);
    sortedQueue.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    _updateQueue.clear();
    _updateQueue.addAll(sortedQueue);

    // 保持队列大小在合理范围内
    while (_updateQueue.length > _config.maxQueueSize) {
      _updateQueue.removeFirst();
    }
  }

  /// 启动更新调度器
  void _startUpdateScheduler() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _processUpdateQueue();
    });
  }

  /// 处理更新队列
  void _processUpdateQueue() {
    if (_updateQueue.isEmpty) return;

    final now = DateTime.now();
    final readyTasks = <UpdateTask>[];

    // 找出准备执行的任务
    while (_updateQueue.isNotEmpty && _updateQueue.first.scheduledTime.isBefore(now)) {
      readyTasks.add(_updateQueue.removeFirst());
    }

    // 执行任务
    for (final task in readyTasks) {
      _executeUpdateTask(task);
    }
  }

  /// 执行更新任务
  void _executeUpdateTask(UpdateTask task) {
    try {
      AppLogger.debug('执行更新任务: ${task.fundCode} (优先级: ${task.priority.toStringAsFixed(2)})');

      // 这里会触发实际的更新操作
      // 通过事件或回调通知外部系统
      _statistics.recordTaskExecution(task);

      // 重新调度下一个更新
      _scheduleUpdateTask(task.fundCode, task.strategy);
    } catch (e) {
      AppLogger.error('执行更新任务失败: ${task.fundCode}', e);
      _statistics.recordTaskFailure(task);
    }
  }

  /// 获取策略分布
  Map<String, int> _getStrategyDistribution() {
    final distribution = <String, int>{};
    for (final strategy in _fundStrategies.values) {
      distribution[strategy.name] = (distribution[strategy.name] ?? 0) + 1;
    }
    return distribution;
  }

  /// 计算平均更新间隔
  Duration _calculateAverageUpdateInterval() {
    if (_fundStrategies.isEmpty) return Duration.zero;

    final totalMs = _fundStrategies.values
        .map((s) => s.updateInterval.inMilliseconds)
        .reduce((a, b) => a + b);

    return Duration(milliseconds: totalMs ~/ _fundStrategies.length);
  }

  /// 预取生成器（内部类）
  late final _PrefetchGenerator _prefetchGenerator = _PrefetchGenerator(this);

  /// 释放资源
  Future<void> dispose() async {
    _updateTimer?.cancel();
    _prefetchScheduler.stop();
    _performanceMonitor.stop();

    _fundStrategies.clear();
    _updateQueue.clear();

    AppLogger.info('IntelligentCacheStrategy disposed');
  }
}

/// 缓存策略
class CacheStrategy {
  final String name;
  Duration updateInterval;
  final bool prefetchEnabled;
  final bool compressionEnabled;
  final double priority;
  final AccessPattern? accessPattern;
  final double? freshnessScore;

  CacheStrategy({
    required this.name,
    required this.updateInterval,
    this.prefetchEnabled = false,
    this.compressionEnabled = false,
    this.priority = 0.5,
    this.accessPattern,
    this.freshnessScore,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'updateIntervalSeconds': updateInterval.inSeconds,
      'prefetchEnabled': prefetchEnabled,
      'compressionEnabled': compressionEnabled,
      'priority': priority,
      'accessPatternType': accessPattern?.type.name,
      'freshnessScore': freshnessScore,
    };
  }

  @override
  String toString() {
    return 'CacheStrategy(name: $name, interval: ${updateInterval.inSeconds}s, priority: ${priority.toStringAsFixed(2)})';
  }

  /// 预定义的缓存策略实例
  static final CacheStrategy highFrequency = CacheStrategy(
    name: 'highFrequency',
    updateInterval: const Duration(seconds: 10),
    prefetchEnabled: true,
    compressionEnabled: false,
    priority: 0.9,
  );

  static final CacheStrategy balanced = CacheStrategy(
    name: 'balanced',
    updateInterval: const Duration(seconds: 30),
    prefetchEnabled: true,
    compressionEnabled: true,
    priority: 0.5,
  );

  static final CacheStrategy lowFrequency = CacheStrategy(
    name: 'lowFrequency',
    updateInterval: const Duration(minutes: 5),
    prefetchEnabled: false,
    compressionEnabled: true,
    priority: 0.3,
  );

  static final CacheStrategy adaptive = CacheStrategy(
    name: 'adaptive',
    updateInterval: const Duration(minutes: 1),
    prefetchEnabled: true,
    compressionEnabled: true,
    priority: 0.7,
  );
}

/// 访问模式
class AccessPattern {
  final AccessPatternType type;
  final double frequency; // 访问频率 0-1
  final int dataSize; // 平均数据大小
  final List<DateTime> recentAccesses;
  final Map<String, dynamic> metadata;

  AccessPattern({
    required this.type,
    required this.frequency,
    required this.dataSize,
    required this.recentAccesses,
    this.metadata = const <String, dynamic>{},
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'frequency': frequency,
      'dataSize': dataSize,
      'accessCount': recentAccesses.length,
      'metadata': metadata,
    };
  }
}

/// 访问模式类型
enum AccessPatternType {
  frequent,   // 频繁访问
  regular,    // 定期访问
  sporadic,   // 偶尔访问
  peak,       // 峰值访问
}

/// 更新任务
class UpdateTask {
  final String fundCode;
  final CacheStrategy strategy;
  final DateTime scheduledTime;
  final double priority;
  final DateTime createdAt;

  UpdateTask({
    required this.fundCode,
    required this.strategy,
    required this.scheduledTime,
    required this.priority,
  }) : createdAt = DateTime.now();

  bool get isOverdue => DateTime.now().isAfter(scheduledTime);
  Duration get overdueDuration => isOverdue ? DateTime.now().difference(scheduledTime) : Duration.zero;
}

/// 策略配置
class StrategyConfig {
  final int maxQueueSize;
  final Duration optimizationInterval;
  final double priorityThreshold;
  final int maxRecentAccesses;

  const StrategyConfig({
    this.maxQueueSize = 1000,
    this.optimizationInterval = const Duration(minutes: 5),
    this.priorityThreshold = 0.7,
    this.maxRecentAccesses = 50,
  });
}

/// 访问模式分析器
class AccessPatternAnalyzer {
  final Map<String, List<DateTime>> _accessHistory = {};
  final Map<String, Queue<int>> _dataSizeHistory = {};

  void trackFund(String fundCode) {
    _accessHistory.putIfAbsent(fundCode, () => []);
    _dataSizeHistory.putIfAbsent(fundCode, () => Queue<int>());
  }

  void recordAccess(String fundCode, int dataSize) {
    trackFund(fundCode);
    _accessHistory[fundCode]!.add(DateTime.now());
    _dataSizeHistory[fundCode]!.add(dataSize);

    // 限制历史记录数量
    if (_accessHistory[fundCode]!.length > 50) {
      _accessHistory[fundCode]!.removeAt(0);
    }
    if (_dataSizeHistory[fundCode]!.length > 50) {
      _dataSizeHistory[fundCode]!.removeFirst();
    }
  }

  AccessPattern analyzePattern(String fundCode) {
    final accesses = _accessHistory[fundCode] ?? [];
    final dataSizes = _dataSizeHistory[fundCode]?.toList() ?? [];

    if (accesses.isEmpty) {
      return AccessPattern(
        type: AccessPatternType.sporadic,
        frequency: 0.0,
        dataSize: 0,
        recentAccesses: [],
      );
    }

    // 计算访问频率
    final now = DateTime.now();
    final recentAccesses = accesses.where((time) => now.difference(time).inHours <= 24).toList();
    final frequency = math.min(1.0, recentAccesses.length / 24.0);

    // 计算平均数据大小
    final avgDataSize = dataSizes.isEmpty ? 0 : dataSizes.reduce((a, b) => a + b) ~/ dataSizes.length;

    // 分析访问模式类型
    AccessPatternType type;
    if (frequency > 0.8) {
      type = AccessPatternType.frequent;
    } else if (frequency > 0.3) {
      type = AccessPatternType.regular;
    } else if (frequency > 0.1) {
      type = AccessPatternType.sporadic;
    } else {
      type = AccessPatternType.peak;
    }

    return AccessPattern(
      type: type,
      frequency: frequency,
      dataSize: avgDataSize,
      recentAccesses: recentAccesses,
      metadata: {
        'totalAccesses': accesses.length,
        'avgInterval': _calculateAverageInterval(accesses),
      },
    );
  }

  Duration _calculateAverageInterval(List<DateTime> accesses) {
    if (accesses.length < 2) return Duration.zero;

    final intervals = <Duration>[];
    for (int i = 1; i < accesses.length; i++) {
      intervals.add(accesses[i].difference(accesses[i - 1]));
    }

    final totalMs = intervals.map((d) => d.inMilliseconds).reduce((a, b) => a + b);
    return Duration(milliseconds: totalMs ~/ intervals.length);
  }
}

/// 数据新鲜度管理器
class DataFreshnessManager {
  final Map<String, DateTime> _lastUpdateTimes = {};
  final Map<String, double> _freshnessScores = {};

  void trackFund(String fundCode) {
    _lastUpdateTimes.putIfAbsent(fundCode, () => DateTime.now());
    _freshnessScores.putIfAbsent(fundCode, () => 1.0);
  }

  void recordUpdate(String fundCode, {DateTime? updateTime}) {
    trackFund(fundCode);
    _lastUpdateTimes[fundCode] = updateTime ?? DateTime.now();
    _freshnessScores[fundCode] = 1.0; // 重置新鲜度
  }

  double calculateFreshnessScore(String fundCode, FundNavData? navData) {
    trackFund(fundCode);

    final lastUpdate = _lastUpdateTimes[fundCode]!;
    final age = DateTime.now().difference(lastUpdate);

    // 基于时间衰减的新鲜度计算
    double timeBasedScore = math.exp(-age.inHours / 24.0); // 24小时半衰期

    // 基于数据质量的新鲜度调整
    double qualityAdjustment = 1.0;
    if (navData != null) {
      final dataAge = DateTime.now().difference(navData.navDate);
      if (dataAge.inDays > 1) {
        qualityAdjustment = math.exp(-dataAge.inDays / 7.0); // 7天半衰期
      }
    }

    final finalScore = timeBasedScore * qualityAdjustment;
    _freshnessScores[fundCode] = finalScore;

    return finalScore;
  }
}

/// 预取调度器
class PrefetchScheduler {
  Timer? _timer;
  bool _isRunning = false;

  void start() {
    if (_isRunning) return;
    _isRunning = true;

    _timer = Timer.periodic(const Duration(minutes: 5), (_) {
      _schedulePrefetch();
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
  }

  void _schedulePrefetch() {
    // 预取调度逻辑
    // 这里可以实现基于访问模式的智能预取
  }
}

/// 优先级管理器
class PriorityManager {
  double calculatePriority(
    String fundCode,
    AccessPattern accessPattern,
    double freshnessScore,
  ) {
    // 基础优先级基于访问频率
    double basePriority = accessPattern.frequency;

    // 新鲜度调整
    if (freshnessScore < 0.3) {
      basePriority *= 1.5; // 数据不新鲜时提高优先级
    }

    // 访问模式调整
    switch (accessPattern.type) {
      case AccessPatternType.frequent:
        basePriority *= 1.2;
        break;
      case AccessPatternType.peak:
        basePriority *= 1.3;
        break;
      case AccessPatternType.regular:
        basePriority *= 1.0;
        break;
      case AccessPatternType.sporadic:
        basePriority *= 0.8;
        break;
    }

    return math.min(1.0, basePriority);
  }
}

/// 策略性能监控器
class StrategyPerformanceMonitor {
  Timer? _timer;
  bool _isRunning = false;

  void start() {
    if (_isRunning) return;
    _isRunning = true;

    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      _collectMetrics();
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
  }

  void _collectMetrics() {
    // 性能指标收集逻辑
  }

  Map<String, dynamic> getMetrics() {
    return {
      'isRunning': _isRunning,
      'lastCollection': DateTime.now().toIso8601String(),
    };
  }
}

/// 策略统计
class StrategyStatistics {
  int totalUpdates = 0;
  int frequencyAdjustments = 0;
  int tasksExecuted = 0;
  int tasksFailed = 0;
  final Map<String, int> strategyUsage = {};

  void recordStrategyUpdate(String fundCode, CacheStrategy strategy) {
    totalUpdates++;
    strategyUsage[strategy.name] = (strategyUsage[strategy.name] ?? 0) + 1;
  }

  void recordFrequencyAdjustment(String fundCode, Duration newInterval) {
    frequencyAdjustments++;
  }

  void recordTaskExecution(UpdateTask task) {
    tasksExecuted++;
  }

  void recordTaskFailure(UpdateTask task) {
    tasksFailed++;
  }

  Map<String, dynamic> toJson() {
    return {
      'totalUpdates': totalUpdates,
      'frequencyAdjustments': frequencyAdjustments,
      'tasksExecuted': tasksExecuted,
      'tasksFailed': tasksFailed,
      'successRate': tasksExecuted > 0 ? (tasksExecuted - tasksFailed) / tasksExecuted : 0.0,
      'strategyUsage': strategyUsage,
    };
  }
}

/// 预取生成器（内部类实现）
class _PrefetchGenerator {
  final IntelligentCacheStrategy _strategy;

  _PrefetchGenerator(this._strategy);

  List<String> getSuggestions({int limit = 10}) {
    // 基于访问模式和优先级生成预取建议
    final suggestions = <String>[];

    // 这里可以实现更复杂的预取算法
    // 目前返回空列表作为占位符

    return suggestions.take(limit).toList();
  }
}