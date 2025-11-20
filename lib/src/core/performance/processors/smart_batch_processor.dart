import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';

import '../monitors/device_performance_detector.dart';
import '../managers/advanced_memory_manager.dart';
import '../../utils/logger.dart';

/// 批次处理状态
enum BatchProcessingState {
  idle, // 空闲
  processing, // 处理中
  paused, // 暂停
  throttling, // 限流
  error, // 错误
  completed, // 完成
}

/// 批次处理策略
enum BatchProcessingStrategy {
  immediate, // 立即处理
  delayed, // 延迟处理
  adaptive, // 自适应处理
  prioritized, // 优先级处理
  streaming, // 流式处理
}

/// 批次处理结果
class BatchProcessingResult<T> {
  final List<T> processedItems;
  final List<T> failedItems;
  final int totalItems;
  final int successCount;
  final int failureCount;
  final Duration processingTime;
  final double throughput; // items/second
  final Map<String, dynamic> metrics;

  const BatchProcessingResult({
    required this.processedItems,
    required this.failedItems,
    required this.totalItems,
    required this.successCount,
    required this.failureCount,
    required this.processingTime,
    required this.throughput,
    required this.metrics,
  });

  /// 成功率
  double get successRate => totalItems > 0 ? successCount / totalItems : 0.0;

  /// 失败率
  double get failureRate => 1.0 - successRate;
}

/// 批次处理配置
class BatchProcessingConfig {
  /// 初始批次大小
  final int initialBatchSize;

  /// 最小批次大小
  final int minBatchSize;

  /// 最大批次大小
  final int maxBatchSize;

  /// 最大队列长度
  final int maxQueueSize;

  /// 处理超时时间
  final Duration processingTimeout;

  /// 背压阈值
  final double backpressureThreshold;

  /// 内存使用阈值
  final double memoryThreshold;

  /// 处理策略
  final BatchProcessingStrategy strategy;

  /// 启用自适应调整
  final bool enableAdaptiveSizing;

  /// 启用性能监控
  final bool enablePerformanceMonitoring;

  /// 错误重试次数
  final int maxRetries;

  const BatchProcessingConfig({
    this.initialBatchSize = 100,
    this.minBatchSize = 10,
    this.maxBatchSize = 1000,
    this.maxQueueSize = 10000,
    this.processingTimeout = const Duration(seconds: 30),
    this.backpressureThreshold = 0.8,
    this.memoryThreshold = 0.85,
    this.strategy = BatchProcessingStrategy.adaptive,
    this.enableAdaptiveSizing = true,
    this.enablePerformanceMonitoring = true,
    this.maxRetries = 3,
  });
}

/// 批次处理任务
class BatchTask<T> {
  final String id;
  final List<T> items;
  final Future<void> Function(List<T>) processor;
  final int priority;
  final DateTime createdAt;
  final Duration? timeout;

  BatchTask({
    required this.id,
    required this.items,
    required this.processor,
    this.priority = 0,
    DateTime? createdAt,
    this.timeout,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 任务大小
  int get size => items.length;
}

/// 性能指标
class BatchProcessingMetrics {
  int totalItemsProcessed = 0;
  int totalBatchesProcessed = 0;
  Duration totalProcessingTime = Duration.zero;
  double averageThroughput = 0.0;
  double currentThroughput = 0.0;
  int currentQueueSize = 0;
  double memoryUsageRatio = 0.0;
  double cpuUsageRatio = 0.0;
  int errorCount = 0;
  int retryCount = 0;

  /// 重置指标
  void reset() {
    totalItemsProcessed = 0;
    totalBatchesProcessed = 0;
    totalProcessingTime = Duration.zero;
    averageThroughput = 0.0;
    currentThroughput = 0.0;
    currentQueueSize = 0;
    memoryUsageRatio = 0.0;
    cpuUsageRatio = 0.0;
    errorCount = 0;
    retryCount = 0;
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'totalItemsProcessed': totalItemsProcessed,
      'totalBatchesProcessed': totalBatchesProcessed,
      'totalProcessingTimeMs': totalProcessingTime.inMilliseconds,
      'averageThroughput': averageThroughput,
      'currentThroughput': currentThroughput,
      'currentQueueSize': currentQueueSize,
      'memoryUsageRatio': memoryUsageRatio,
      'cpuUsageRatio': cpuUsageRatio,
      'errorCount': errorCount,
      'retryCount': retryCount,
    };
  }
}

/// 智能批次处理器
class SmartBatchProcessor<T> {
  final BatchProcessingConfig _config;
  final Queue<BatchTask<T>> _processingQueue = Queue<BatchTask<T>>();

  BatchProcessingState _state = BatchProcessingState.idle;
  int _currentBatchSize;
  Timer? _processingTimer;
  Timer? _metricsUpdateTimer;

  // 性能监控
  final BatchProcessingMetrics _metrics = BatchProcessingMetrics();
  final List<double> _throughputHistory = [];
  final List<double> _processingTimeHistory = [];

  // 组件依赖
  DeviceCapabilityDetector? _deviceDetector;
  AdvancedMemoryManager? _memoryManager;

  // 事件回调
  final List<void Function(BatchProcessingState)> _stateChangeListeners = [];
  final List<void Function(BatchProcessingMetrics)> _metricsUpdateListeners =
      [];
  final List<void Function(String, dynamic)> _errorListeners = [];

  SmartBatchProcessor({
    BatchProcessingConfig? config,
    DeviceCapabilityDetector? deviceDetector,
    AdvancedMemoryManager? memoryManager,
  })  : _config = config ?? const BatchProcessingConfig(),
        _currentBatchSize =
            (config ?? const BatchProcessingConfig()).initialBatchSize,
        _deviceDetector = deviceDetector,
        _memoryManager = memoryManager;

  /// 初始化
  Future<void> initialize() async {
    try {
      // 启动性能指标定时更新
      if (_config.enablePerformanceMonitoring) {
        _startMetricsUpdate();
      }

      AppLogger.business('SmartBatchProcessor初始化完成',
          '批次大小: $_currentBatchSize, 策略: ${_config.strategy.name}');
    } catch (e) {
      AppLogger.error('SmartBatchProcessor初始化失败', e);
      throw Exception('Failed to initialize SmartBatchProcessor: $e');
    }
  }

  /// 启动指标更新定时器
  void _startMetricsUpdate() {
    _metricsUpdateTimer?.cancel();
    _metricsUpdateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateMetrics();
      _notifyMetricsUpdateListeners();
    });
  }

  /// 更新性能指标
  void _updateMetrics() {
    _metrics.currentQueueSize = _processingQueue.length;
    _metrics.memoryUsageRatio = _getMemoryUsageRatio();
    _metrics.cpuUsageRatio = _getCpuUsageRatio();

    // 计算当前吞吐量
    if (_throughputHistory.isNotEmpty) {
      _metrics.currentThroughput = _throughputHistory.reduce((a, b) => a + b) /
          _throughputHistory.length;
    }

    // 保持历史记录在合理范围内
    if (_throughputHistory.length > 60) {
      _throughputHistory.removeAt(0);
      _processingTimeHistory.removeAt(0);
    }
  }

  /// 获取内存使用率
  double _getMemoryUsageRatio() {
    if (_memoryManager != null) {
      final memoryInfo = _memoryManager!.getMemoryInfo();
      return memoryInfo.availableMemoryMB / memoryInfo.totalMemoryMB;
    }
    return 0.5; // 默认值
  }

  /// 获取CPU使用率
  double _getCpuUsageRatio() {
    if (_deviceDetector != null) {
      // 简化实现，实际需要从设备检测器获取CPU使用率
      return 0.3; // 默认值
    }
    return 0.3;
  }

  /// 添加批次任务
  String addBatchTask({
    required List<T> items,
    required Future<void> Function(List<T>) processor,
    int priority = 0,
    Duration? timeout,
  }) {
    final taskId = 'batch_${DateTime.now().millisecondsSinceEpoch}';

    final task = BatchTask<T>(
      id: taskId,
      items: items,
      processor: processor,
      priority: priority,
      timeout: timeout,
    );

    // 检查背压情况
    if (_shouldApplyBackpressure()) {
      _applyBackpressure();
    }

    _processingQueue.add(task);
    _sortQueueByPriority();

    // 启动处理
    _scheduleProcessing();

    AppLogger.debug('批次任务已添加',
        'ID: $taskId, 大小: ${items.length}, 队列长度: ${_processingQueue.length}');

    return taskId;
  }

  /// 判断是否应该应用背压控制
  bool _shouldApplyBackpressure() {
    return _processingQueue.length >=
            _config.maxQueueSize * _config.backpressureThreshold ||
        _metrics.memoryUsageRatio >= _config.memoryThreshold;
  }

  /// 应用背压控制
  void _applyBackpressure() {
    _setState(BatchProcessingState.throttling);

    // 减少批次大小
    if (_config.enableAdaptiveSizing) {
      _currentBatchSize = math.max(
        _config.minBatchSize,
        (_currentBatchSize * 0.7).round(),
      );
    }

    // 可以选择丢弃低优先级任务
    _dropLowPriorityTasks();

    AppLogger.debug('应用背压控制',
        '队列长度: ${_processingQueue.length}, 新批次大小: $_currentBatchSize');
  }

  /// 丢弃低优先级任务
  void _dropLowPriorityTasks() {
    if (_processingQueue.length <= _config.maxQueueSize) return;

    // 按优先级排序，移除低优先级任务
    final sortedTasks = _processingQueue.toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));

    final tasksToRemove = sortedTasks.skip(_config.maxQueueSize);

    for (final task in tasksToRemove) {
      _processingQueue.remove(task);
      _metrics.errorCount++;
      AppLogger.debug('丢弃低优先级批次任务', 'ID: ${task.id}, 大小: ${task.size}');
    }
  }

  /// 按优先级排序队列
  void _sortQueueByPriority() {
    if (_processingQueue.isEmpty) return;

    final sortedTasks = _processingQueue.toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));

    _processingQueue.clear();
    _processingQueue.addAll(sortedTasks);
  }

  /// 调度处理
  void _scheduleProcessing() {
    if (_state == BatchProcessingState.processing) return;

    _processingTimer?.cancel();
    _processingTimer = Timer(Duration.zero, () {
      _processBatch();
    });
  }

  /// 处理批次
  Future<void> _processBatch() async {
    if (_processingQueue.isEmpty || _state == BatchProcessingState.processing) {
      return;
    }

    _setState(BatchProcessingState.processing);

    try {
      final stopwatch = Stopwatch()..start();

      // 获取当前批次
      final batch = _extractCurrentBatch();
      if (batch.isEmpty) {
        _setState(BatchProcessingState.idle);
        return;
      }

      // 处理批次
      await _processBatchWithRetry(batch);

      stopwatch.stop();

      // 更新指标
      _updateBatchMetrics(batch.length, stopwatch.elapsed);

      // 调整批次大小
      if (_config.enableAdaptiveSizing) {
        _adjustBatchSize(stopwatch.elapsed, batch.length);
      }

      AppLogger.debug('批次处理完成',
          '大小: ${batch.length}, 耗时: ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      AppLogger.error('批次处理失败', e);
      _metrics.errorCount++;
      _notifyErrorListeners('batch_processing_error', e);
    }

    // 继续处理下一个批次
    _scheduleProcessing();
  }

  /// 提取当前批次
  List<T> _extractCurrentBatch() {
    final batch = <T>[];
    int remainingSize = _currentBatchSize;

    while (remainingSize > 0 && _processingQueue.isNotEmpty) {
      final task = _processingQueue.first;

      if (task.items.length <= remainingSize) {
        // 整个任务都可以包含在当前批次中
        batch.addAll(task.items);
        _processingQueue.removeFirst();
        remainingSize -= task.items.length;
      } else {
        // 部分任务包含在当前批次中
        batch.addAll(task.items.take(remainingSize));

        // 更新任务，移除已处理的项目
        final remainingItems = task.items.skip(remainingSize).toList();
        _processingQueue.removeFirst();

        // 创建新任务包含剩余项目
        final newTask = BatchTask<T>(
          id: '${task.id}_remaining',
          items: remainingItems,
          processor: task.processor,
          priority: task.priority,
          timeout: task.timeout,
        );

        _processingQueue.addFirst(newTask);
        break;
      }
    }

    return batch;
  }

  /// 带重试的批次处理
  Future<void> _processBatchWithRetry(List<T> batch) async {
    int retryCount = 0;

    while (retryCount <= _config.maxRetries) {
      try {
        // 这里需要一个处理器来处理批次
        // 实际实现中应该从外部传入处理器
        await _processBatchItems(batch);
        break; // 成功，跳出重试循环
      } catch (e) {
        retryCount++;
        _metrics.retryCount++;

        if (retryCount > _config.maxRetries) {
          AppLogger.error('批次处理重试失败', '重试次数: $retryCount');
          rethrow;
        }

        // 指数退避等待
        final delay =
            Duration(milliseconds: 100 * math.pow(2, retryCount - 1).toInt());
        await Future.delayed(delay);
      }
    }
  }

  /// 处理批次项目（需要外部实现）
  Future<void> _processBatchItems(List<T> items) async {
    // 这是一个抽象方法，实际使用时需要外部提供具体的处理逻辑
    // 可以通过构造函数传入处理器函数

    // 简化实现：模拟处理时间
    await Future.delayed(Duration(milliseconds: items.length ~/ 10));

    // 记录处理的项目数
    _metrics.totalItemsProcessed += items.length;
  }

  /// 更新批次指标
  void _updateBatchMetrics(int batchSize, Duration processingTime) {
    _metrics.totalBatchesProcessed++;
    _metrics.totalProcessingTime += processingTime;

    // 计算吞吐量
    final throughput = batchSize / processingTime.inSeconds * 1000;
    _throughputHistory.add(throughput);
    _processingTimeHistory.add(processingTime.inMilliseconds.toDouble());

    // 计算平均吞吐量
    if (_metrics.totalProcessingTime.inMilliseconds > 0) {
      _metrics.averageThroughput = _metrics.totalItemsProcessed /
          _metrics.totalProcessingTime.inSeconds *
          1000;
    }
  }

  /// 自适应调整批次大小
  void _adjustBatchSize(Duration processingTime, int batchSize) {
    // 基于处理时间和系统负载调整批次大小
    final targetProcessingTime = 100; // 目标处理时间 100ms
    final actualProcessingTime = processingTime.inMilliseconds.toDouble();

    double adjustmentFactor = targetProcessingTime / actualProcessingTime;

    // 考虑系统负载
    final loadFactor = 1.0 - _metrics.memoryUsageRatio;
    adjustmentFactor *= loadFactor;

    // 应用调整
    int newBatchSize = (_currentBatchSize * adjustmentFactor).round();
    newBatchSize =
        newBatchSize.clamp(_config.minBatchSize, _config.maxBatchSize);

    if (newBatchSize != _currentBatchSize) {
      _currentBatchSize = newBatchSize;
      AppLogger.debug('批次大小已调整',
          '从 ${_currentBatchSize} 到 $newBatchSize, 因子: $adjustmentFactor');
    }
  }

  /// 设置状态
  void _setState(BatchProcessingState newState) {
    if (_state != newState) {
      final oldState = _state;
      _state = newState;

      AppLogger.debug('批次处理状态变更', '从 ${oldState.name} 到 ${newState.name}');

      _notifyStateChangeListeners(newState);
    }
  }

  /// 暂停处理
  void pause() {
    _setState(BatchProcessingState.paused);
    _processingTimer?.cancel();
  }

  /// 恢复处理
  void resume() {
    if (_state == BatchProcessingState.paused) {
      _setState(BatchProcessingState.idle);
      _scheduleProcessing();
    }
  }

  /// 清空队列
  void clearQueue() {
    _processingQueue.clear();
    AppLogger.debug('批次处理队列已清空');
  }

  /// 获取当前状态
  BatchProcessingState get currentState => _state;

  /// 获取当前批次大小
  int get currentBatchSize => _currentBatchSize;

  /// 获取队列长度
  int get queueLength => _processingQueue.length;

  /// 获取性能指标
  BatchProcessingMetrics get metrics => _metrics;

  /// 检查是否空闲
  bool get isIdle => _state == BatchProcessingState.idle;

  /// 检查是否正在处理
  bool get isProcessing => _state == BatchProcessingState.processing;

  /// 添加状态变更监听器
  void addStateChangeListener(void Function(BatchProcessingState) listener) {
    _stateChangeListeners.add(listener);
  }

  /// 移除状态变更监听器
  void removeStateChangeListener(void Function(BatchProcessingState) listener) {
    _stateChangeListeners.remove(listener);
  }

  /// 添加指标更新监听器
  void addMetricsUpdateListener(
      void Function(BatchProcessingMetrics) listener) {
    _metricsUpdateListeners.add(listener);
  }

  /// 移除指标更新监听器
  void removeMetricsUpdateListener(
      void Function(BatchProcessingMetrics) listener) {
    _metricsUpdateListeners.remove(listener);
  }

  /// 添加错误监听器
  void addErrorListener(void Function(String, dynamic) listener) {
    _errorListeners.add(listener);
  }

  /// 移除错误监听器
  void removeErrorListener(void Function(String, dynamic) listener) {
    _errorListeners.remove(listener);
  }

  /// 通知状态变更监听器
  void _notifyStateChangeListeners(BatchProcessingState state) {
    for (final listener in _stateChangeListeners) {
      try {
        listener(state);
      } catch (e) {
        AppLogger.error('状态变更监听器回调失败', e);
      }
    }
  }

  /// 通知指标更新监听器
  void _notifyMetricsUpdateListeners() {
    for (final listener in _metricsUpdateListeners) {
      try {
        listener(_metrics);
      } catch (e) {
        AppLogger.error('指标更新监听器回调失败', e);
      }
    }
  }

  /// 通知错误监听器
  void _notifyErrorListeners(String errorType, dynamic error) {
    for (final listener in _errorListeners) {
      try {
        listener(errorType, error);
      } catch (e) {
        AppLogger.error('错误监听器回调失败', e);
      }
    }
  }

  /// 重置处理器
  void reset() {
    pause();
    clearQueue();
    _metrics.reset();
    _currentBatchSize = _config.initialBatchSize;
    _throughputHistory.clear();
    _processingTimeHistory.clear();
    _setState(BatchProcessingState.idle);

    AppLogger.business('SmartBatchProcessor已重置');
  }

  /// 获取性能摘要
  Map<String, dynamic> getPerformanceSummary() {
    return {
      'state': _state.name,
      'currentBatchSize': _currentBatchSize,
      'queueLength': _processingQueue.length,
      'metrics': _metrics.toMap(),
      'config': {
        'initialBatchSize': _config.initialBatchSize,
        'minBatchSize': _config.minBatchSize,
        'maxBatchSize': _config.maxBatchSize,
        'maxQueueSize': _config.maxQueueSize,
        'strategy': _config.strategy.name,
        'enableAdaptiveSizing': _config.enableAdaptiveSizing,
      },
    };
  }

  /// 清理资源
  Future<void> dispose() async {
    pause();
    clearQueue();

    _processingTimer?.cancel();
    _metricsUpdateTimer?.cancel();

    _stateChangeListeners.clear();
    _metricsUpdateListeners.clear();
    _errorListeners.clear();

    AppLogger.business('SmartBatchProcessor已清理');
  }
}
