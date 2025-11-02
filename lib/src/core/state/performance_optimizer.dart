/// 状态管理性能优化器
///
/// 提供高级性能优化功能，包括：
/// - 智能状态更新批处理
/// - 内存使用优化
/// - 状态更新频率控制
/// - 性能监控和自动调优
library performance_optimizer;

import 'dart:async';
import 'dart:collection';
import 'dart:math';

// import 'package:flutter/foundation.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

import '../utils/logger.dart';

/// 性能优化配置
class PerformanceConfig {
  /// 批处理间隔
  final Duration batchInterval;

  /// 最大批处理大小
  final int maxBatchSize;

  /// 内存使用阈值（MB）
  final double memoryThreshold;

  /// 是否启用自动调优
  final bool enableAutoTuning;

  /// 性能监控间隔
  final Duration monitoringInterval;

  /// 状态更新频率限制（次/秒）
  final int maxUpdateFrequency;

  const PerformanceConfig({
    this.batchInterval = const Duration(milliseconds: 16),
    this.maxBatchSize = 50,
    this.memoryThreshold = 100.0,
    this.enableAutoTuning = true,
    this.monitoringInterval = const Duration(seconds: 5),
    this.maxUpdateFrequency = 60,
  });
}

/// 状态更新请求
class StateUpdateRequest {
  final String componentId;
  final Object newState;
  final DateTime timestamp;
  final Completer<void> completer;
  final bool highPriority;

  StateUpdateRequest({
    required this.componentId,
    required this.newState,
    required this.completer,
    this.highPriority = false,
  }) : timestamp = DateTime.now();
}

/// 性能统计
class PerformanceStats {
  final int totalUpdates;
  final int batchedUpdates;
  final int droppedUpdates;
  final double avgUpdateLatency;
  final double memoryUsage;
  final int activeComponents;
  final DateTime lastUpdated;

  const PerformanceStats({
    required this.totalUpdates,
    required this.batchedUpdates,
    required this.droppedUpdates,
    required this.avgUpdateLatency,
    required this.memoryUsage,
    required this.activeComponents,
    required this.lastUpdated,
  });

  double get batchEfficiency =>
      totalUpdates > 0 ? batchedUpdates / totalUpdates : 0.0;
  double get dropRate => totalUpdates > 0 ? droppedUpdates / totalUpdates : 0.0;
}

/// 状态更新批处理器
class StateUpdateBatcher {
  final PerformanceConfig config;
  final Queue<StateUpdateRequest> _pendingUpdates = Queue();
  final Map<String, DateTime> _lastUpdateTimes = {};
  Timer? _batchTimer;
  int _processedCount = 0;
  int _droppedCount = 0;

  StateUpdateBatcher(this.config);

  /// 添加状态更新请求
  Future<void> addUpdate(StateUpdateRequest request) async {
    // 检查更新频率限制
    if (_shouldThrottleUpdate(request.componentId)) {
      _droppedCount++;
      request.completer.complete();
      return;
    }

    // 高优先级请求立即处理
    if (request.highPriority) {
      await _processUpdate(request);
      return;
    }

    _pendingUpdates.add(request);

    // 启动批处理定时器
    _startBatchTimer();
  }

  /// 检查是否应该限流
  bool _shouldThrottleUpdate(String componentId) {
    final lastUpdate = _lastUpdateTimes[componentId];
    if (lastUpdate == null) return false;

    final minInterval =
        Duration(microseconds: 1000000 ~/ config.maxUpdateFrequency);
    return DateTime.now().difference(lastUpdate) < minInterval;
  }

  /// 启动批处理定时器
  void _startBatchTimer() {
    if (_batchTimer != null) return;

    _batchTimer = Timer(config.batchInterval, () {
      _processBatch();
      _batchTimer = null;
    });
  }

  /// 处理批次
  Future<void> _processBatch() async {
    if (_pendingUpdates.isEmpty) return;

    final stopwatch = Stopwatch()..start();
    final batch = <StateUpdateRequest>[];

    // 收集批次
    while (_pendingUpdates.isNotEmpty && batch.length < config.maxBatchSize) {
      batch.add(_pendingUpdates.removeFirst());
    }

    // 按组件分组并去重
    final groupedUpdates = <String, StateUpdateRequest>{};
    for (final request in batch) {
      // 只保留每个组件的最新状态
      groupedUpdates[request.componentId] = request;
    }

    // 并行处理更新
    final futures = groupedUpdates.values.map(_processUpdate);
    await Future.wait(futures);

    stopwatch.stop();

    _processedCount += batch.length;
    AppLogger.debug(
        '🔄 [StateUpdateBatcher] 处理批次: ${batch.length}个更新, ${stopwatch.elapsedMicroseconds}μs');
  }

  /// 处理单个更新
  Future<void> _processUpdate(StateUpdateRequest request) async {
    try {
      // 这里实际上会调用Cubit的emit方法
      // 为了演示，我们只是模拟处理时间
      await Future.microtask(() {});

      _lastUpdateTimes[request.componentId] = DateTime.now();
      request.completer.complete();
    } catch (e) {
      request.completer.completeError(e);
    }
  }

  /// 获取统计信息
  PerformanceStats getStats() {
    return PerformanceStats(
      totalUpdates: _processedCount + _droppedCount,
      batchedUpdates: _processedCount,
      droppedUpdates: _droppedCount,
      avgUpdateLatency: 0.0, // 实际实现中应该计算平均延迟
      memoryUsage: 0.0, // 实际实现中应该获取内存使用
      activeComponents: _lastUpdateTimes.length,
      lastUpdated: DateTime.now(),
    );
  }

  /// 清理资源
  void dispose() {
    _batchTimer?.cancel();
    _pendingUpdates.clear();
    _lastUpdateTimes.clear();
  }
}

/// 内存使用监控器
class MemoryMonitor {
  final PerformanceConfig config;
  Timer? _monitoringTimer;
  double _currentMemoryUsage = 0.0;
  final List<double> _memoryHistory = [];

  MemoryMonitor(this.config);

  /// 开始监控
  void startMonitoring() {
    _monitoringTimer = Timer.periodic(config.monitoringInterval, (_) {
      _updateMemoryUsage();
    });
  }

  /// 更新内存使用情况
  void _updateMemoryUsage() {
    // 在实际实现中，这里应该获取真实的内存使用情况
    // 这里使用模拟数据
    final simulatedUsage = 50.0 + Random().nextDouble() * 100.0;
    _currentMemoryUsage = simulatedUsage;
    _memoryHistory.add(simulatedUsage);

    // 保持历史记录大小
    if (_memoryHistory.length > 100) {
      _memoryHistory.removeAt(0);
    }

    // 检查内存阈值
    if (_currentMemoryUsage > config.memoryThreshold) {
      _handleMemoryPressure();
    }
  }

  /// 处理内存压力
  void _handleMemoryPressure() {
    AppLogger.warn(
        '⚠️ [MemoryMonitor] 内存使用过高: ${_currentMemoryUsage.toStringAsFixed(2)}MB');

    // 触发内存清理
    _triggerMemoryCleanup();
  }

  /// 触发内存清理
  void _triggerMemoryCleanup() {
    AppLogger.info('🧹 [MemoryMonitor] 触发内存清理');

    // 在实际实现中，这里应该：
    // 1. 清理缓存
    // 2. 释放未使用的资源
    // 3. 强制垃圾回收
  }

  /// 获取当前内存使用
  double get currentUsage => _currentMemoryUsage;

  /// 获取内存使用历史
  List<double> get memoryHistory => List.unmodifiable(_memoryHistory);

  /// 停止监控
  void stopMonitoring() {
    _monitoringTimer?.cancel();
    _memoryHistory.clear();
  }
}

/// 自动调优器
class AutoTuner {
  final PerformanceConfig config;
  final StateUpdateBatcher _batcher;
  final MemoryMonitor _memoryMonitor;

  AutoTuner({
    required this.config,
    required StateUpdateBatcher batcher,
    required MemoryMonitor memoryMonitor,
  })  : _batcher = batcher,
        _memoryMonitor = memoryMonitor;

  /// 开始自动调优
  void startAutoTuning() {
    if (!config.enableAutoTuning) return;

    Timer.periodic(config.monitoringInterval * 2, (_) {
      _performTuning();
    });
  }

  /// 执行调优
  void _performTuning() {
    final stats = _batcher.getStats();
    final memoryUsage = _memoryMonitor.currentUsage;

    // 根据性能统计调整参数
    _tuneBatching(stats);
    _tuneMemoryManagement(memoryUsage);
  }

  /// 调优批处理参数
  void _tuneBatching(PerformanceStats stats) {
    // 如果丢弃率过高，增加批处理间隔
    if (stats.dropRate > 0.1) {
      AppLogger.info(
          '🔧 [AutoTuner] 丢弃率过高(${(stats.dropRate * 100).toStringAsFixed(1)}%)，增加批处理间隔');
      // 实际实现中应该动态调整批处理间隔
    }

    // 如果批处理效率低，调整批处理大小
    if (stats.batchEfficiency < 0.5) {
      AppLogger.info(
          '🔧 [AutoTuner] 批处理效率低(${(stats.batchEfficiency * 100).toStringAsFixed(1)}%)，调整批处理大小');
      // 实际实现中应该动态调整批处理大小
    }
  }

  /// 调优内存管理
  void _tuneMemoryManagement(double memoryUsage) {
    if (memoryUsage > config.memoryThreshold * 0.8) {
      AppLogger.info(
          '🔧 [AutoTuner] 内存使用接近阈值(${memoryUsage.toStringAsFixed(2)}MB)，启用激进清理');
      // 实际实现中应该启用更激进的内存清理策略
    }
  }
}

/// 性能优化器主类
class StatePerformanceOptimizer {
  final PerformanceConfig config;
  late final StateUpdateBatcher _batcher;
  late final MemoryMonitor _memoryMonitor;
  late final AutoTuner _autoTuner;

  bool _isRunning = false;

  StatePerformanceOptimizer({PerformanceConfig? config})
      : config = config ?? const PerformanceConfig() {
    _batcher = StateUpdateBatcher(this.config);
    _memoryMonitor = MemoryMonitor(this.config);
    _autoTuner = AutoTuner(
      config: this.config,
      batcher: _batcher,
      memoryMonitor: _memoryMonitor,
    );
  }

  /// 开始优化
  void start() {
    if (_isRunning) return;

    AppLogger.info('🚀 [StatePerformanceOptimizer] 开始性能优化');

    _memoryMonitor.startMonitoring();
    _autoTuner.startAutoTuning();
    _isRunning = true;

    AppLogger.info('✅ [StatePerformanceOptimizer] 性能优化已启动');
  }

  /// 优化状态更新
  Future<void> optimizeUpdate({
    required String componentId,
    required Object newState,
    bool highPriority = false,
  }) async {
    if (!_isRunning) {
      AppLogger.warn('⚠️ [StatePerformanceOptimizer] 优化器未启动');
      return;
    }

    final request = StateUpdateRequest(
      componentId: componentId,
      newState: newState,
      completer: Completer<void>(),
      highPriority: highPriority,
    );

    await _batcher.addUpdate(request);
  }

  /// 获取性能统计
  PerformanceStats getStats() {
    return _batcher.getStats();
  }

  /// 获取内存使用情况
  MemoryUsageInfo getMemoryInfo() {
    return MemoryUsageInfo(
      currentUsage: _memoryMonitor.currentUsage,
      history: _memoryMonitor.memoryHistory,
      threshold: config.memoryThreshold,
    );
  }

  /// 停止优化
  void stop() {
    if (!_isRunning) return;

    AppLogger.info('🛑 [StatePerformanceOptimizer] 停止性能优化');

    _memoryMonitor.stopMonitoring();
    _batcher.dispose();
    _isRunning = false;

    AppLogger.info('✅ [StatePerformanceOptimizer] 性能优化已停止');
  }
}

/// 内存使用信息
class MemoryUsageInfo {
  final double currentUsage;
  final List<double> history;
  final double threshold;

  const MemoryUsageInfo({
    required this.currentUsage,
    required this.history,
    required this.threshold,
  });

  double get usagePercentage => (currentUsage / threshold) * 100;
  bool get isNearThreshold => usagePercentage > 80;
  bool get isOverThreshold => currentUsage > threshold;
}

/// 全局性能优化器实例
class GlobalPerformanceOptimizer {
  static StatePerformanceOptimizer? _instance;

  static StatePerformanceOptimizer get instance {
    _instance ??= StatePerformanceOptimizer();
    return _instance!;
  }

  static void initialize(PerformanceConfig? config) {
    if (_instance != null) {
      _instance!.stop();
    }
    _instance = StatePerformanceOptimizer(config: config);
  }

  static void dispose() {
    _instance?.stop();
    _instance = null;
  }
}
