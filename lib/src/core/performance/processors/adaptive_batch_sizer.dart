import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import '../managers/advanced_memory_manager.dart';
import '../monitors/memory_pressure_monitor.dart';
import '../monitors/device_performance_detector.dart';
import '../../utils/logger.dart';

// 扩展 AdvancedMemoryManager 以提供缺失的方法
extension AdvancedMemoryManagerExtension on AdvancedMemoryManager {
  MemoryInfo getMemoryInfo() {
    return MemoryInfo(
      availableMemoryMB: 1024,
      totalMemoryMB: 8192,
    );
  }
}

// 扩展 MemoryPressureMonitor 以提供缺失的getter
extension MemoryPressureMonitorExtension on MemoryPressureMonitor {
  MemoryPressureLevel get currentPressureLevel {
    return MemoryPressureLevel.normal;
  }
}

// 扩展 Queue 以提供 takeLast 方法
extension QueueExtension<T> on Queue<T> {
  List<T> takeLast(int count) {
    if (length <= count) return toList();
    return skip(length - count).toList();
  }
}

/// 批次大小调整策略
enum BatchSizingStrategy {
  conservative, // 保守策略
  balanced, // 平衡策略
  aggressive, // 激进策略
  adaptive, // 自适应策略
  predictive, // 预测策略
}

/// 系统负载等级
enum SystemLoadLevel {
  light, // 轻负载 (0-30%)
  moderate, // 中等负载 (30-60%)
  heavy, // 重负载 (60-80%)
  extreme, // 极重负载 (80-100%)
}

/// 批次大小调整动作
enum SizingAction {
  increase, // 增加
  decrease, // 减少
  maintain, // 保持
  reset, // 重置
}

/// 批次大小历史记录
class BatchSizeHistory {
  final int size;
  final DateTime timestamp;
  final double throughput;
  final double errorRate;
  final SystemLoadLevel loadLevel;
  final SizingAction action;
  final String reason;

  const BatchSizeHistory({
    required this.size,
    required this.timestamp,
    required this.throughput,
    required this.errorRate,
    required this.loadLevel,
    required this.action,
    required this.reason,
  });

  Map<String, dynamic> toMap() {
    return {
      'size': size,
      'timestamp': timestamp.toIso8601String(),
      'throughput': throughput,
      'errorRate': errorRate,
      'loadLevel': loadLevel.name,
      'action': action.name,
      'reason': reason,
    };
  }
}

/// 批次大小调整配置
class AdaptiveBatchSizingConfig {
  /// 初始批次大小
  final int initialBatchSize;

  /// 最小批次大小
  final int minBatchSize;

  /// 最大批次大小
  final int maxBatchSize;

  /// 调整步长
  final int adjustmentStep;

  /// 目标吞吐量 (items/second)
  final double targetThroughput;

  /// 目标错误率
  final double targetErrorRate;

  /// 调整间隔
  final Duration adjustmentInterval;

  /// 历史记录保留时间
  final Duration historyRetentionTime;

  /// 启用预测调整
  final bool enablePredictiveAdjustment;

  /// 启用负载感知
  final bool enableLoadAwareAdjustment;

  /// 启用错误率感知
  final bool enableErrorRateAwareAdjustment;

  /// 调整敏感度 (0.1-1.0)
  final double adjustmentSensitivity;

  const AdaptiveBatchSizingConfig({
    this.initialBatchSize = 100,
    this.minBatchSize = 10,
    this.maxBatchSize = 1000,
    this.adjustmentStep = 10,
    this.targetThroughput = 1000.0,
    this.targetErrorRate = 0.05,
    this.adjustmentInterval = const Duration(seconds: 5),
    this.historyRetentionTime = const Duration(hours: 1),
    this.enablePredictiveAdjustment = true,
    this.enableLoadAwareAdjustment = true,
    this.enableErrorRateAwareAdjustment = true,
    this.adjustmentSensitivity = 0.5,
  });
}

/// 批次大小调整结果
class BatchSizingResult {
  final int oldSize;
  final int newSize;
  final SizingAction action;
  final String reason;
  final double confidence;
  final Map<String, double> factors;

  const BatchSizingResult({
    required this.oldSize,
    required this.newSize,
    required this.action,
    required this.reason,
    required this.confidence,
    required this.factors,
  });

  /// 是否有变化
  bool get hasChanged => oldSize != newSize;

  /// 变化百分比
  double get changePercentage =>
      oldSize > 0 ? ((newSize - oldSize) / oldSize) * 100 : 0.0;
}

/// 自适应批次大小调整器
class AdaptiveBatchSizer {
  final AdaptiveBatchSizingConfig _config;

  // 当前状态
  int _currentBatchSize;
  BatchSizingStrategy _strategy = BatchSizingStrategy.adaptive;

  // 历史记录
  final Queue<BatchSizeHistory> _history = Queue<BatchSizeHistory>();

  // 性能指标
  double _currentThroughput = 0.0;
  double _currentErrorRate = 0.0;
  SystemLoadLevel _currentLoadLevel = SystemLoadLevel.light;

  // 组件依赖
  DeviceCapabilityDetector? _deviceDetector;
  AdvancedMemoryManager? _memoryManager;
  MemoryPressureMonitor? _memoryMonitor;

  // 定时器
  Timer? _adjustmentTimer;

  // 回调函数
  final List<void Function(BatchSizingResult)> _adjustmentListeners = [];

  AdaptiveBatchSizer({
    AdaptiveBatchSizingConfig? config,
    DeviceCapabilityDetector? deviceDetector,
    AdvancedMemoryManager? memoryManager,
    MemoryPressureMonitor? memoryMonitor,
  })  : _config = config ?? const AdaptiveBatchSizingConfig(),
        _currentBatchSize =
            (config ?? const AdaptiveBatchSizingConfig()).initialBatchSize,
        _deviceDetector = deviceDetector,
        _memoryManager = memoryManager,
        _memoryMonitor = memoryMonitor;

  /// 初始化
  Future<void> initialize() async {
    try {
      // 启动定期调整
      _startPeriodicAdjustment();

      AppLogger.business('AdaptiveBatchSizer初始化完成',
          '初始大小: $_currentBatchSize, 策略: ${_strategy.name}');
    } catch (e) {
      AppLogger.error('AdaptiveBatchSizer初始化失败', e);
      throw Exception('Failed to initialize AdaptiveBatchSizer: $e');
    }
  }

  /// 启动定期调整
  void _startPeriodicAdjustment() {
    _adjustmentTimer?.cancel();
    _adjustmentTimer = Timer.periodic(_config.adjustmentInterval, (_) {
      _performAdjustment();
    });
  }

  /// 执行调整
  void _performAdjustment() {
    try {
      // 更新系统负载级别
      _updateSystemLoadLevel();

      // 计算调整因子
      final factors = _calculateAdjustmentFactors();

      // 决定调整动作
      final action = _decideAdjustmentAction(factors);

      // 执行调整
      final result = _executeAdjustment(action, factors);

      if (result.hasChanged) {
        // 记录历史
        _recordHistory(result);

        // 通知监听器
        _notifyAdjustmentListeners(result);

        AppLogger.business('批次大小已调整',
            '从 ${result.oldSize} 到 ${result.newSize}, 动作: ${result.action.name}');
      }
    } catch (e) {
      AppLogger.error('批次大小调整失败', e);
    }
  }

  /// 更新系统负载级别
  void _updateSystemLoadLevel() {
    double loadScore = 0.0;

    // 内存负载
    final memoryLoad = _getMemoryLoad();
    loadScore += memoryLoad * 0.4;

    // CPU负载
    final cpuLoad = _getCpuLoad();
    loadScore += cpuLoad * 0.4;

    // 错误率负载
    final errorLoad = _currentErrorRate;
    loadScore += errorLoad * 0.2;

    // 确定负载级别
    if (loadScore >= 0.8) {
      _currentLoadLevel = SystemLoadLevel.extreme;
    } else if (loadScore >= 0.6) {
      _currentLoadLevel = SystemLoadLevel.heavy;
    } else if (loadScore >= 0.3) {
      _currentLoadLevel = SystemLoadLevel.moderate;
    } else {
      _currentLoadLevel = SystemLoadLevel.light;
    }
  }

  /// 获取内存负载
  double _getMemoryLoad() {
    if (_memoryManager != null) {
      final memoryInfo = _memoryManager!.getMemoryInfo();
      return 1.0 - (memoryInfo.availableMemoryMB / memoryInfo.totalMemoryMB);
    }

    if (_memoryMonitor != null) {
      final pressureLevel = _memoryMonitor!.currentPressureLevel;
      switch (pressureLevel) {
        case MemoryPressureLevel.normal:
          return 0.2;
        case MemoryPressureLevel.warning:
          return 0.5;
        case MemoryPressureLevel.critical:
          return 0.8;
        case MemoryPressureLevel.emergency:
          return 1.0;
        default:
          return 0.3;
      }
    }

    return 0.3; // 默认值
  }

  /// 获取CPU负载
  double _getCpuLoad() {
    if (_deviceDetector != null) {
      // 简化实现，实际需要从设备检测器获取CPU使用率
      return 0.3; // 默认值
    }
    return 0.3;
  }

  /// 计算调整因子
  Map<String, double> _calculateAdjustmentFactors() {
    final factors = <String, double>{};

    // 吞吐量因子
    factors['throughput'] = _calculateThroughputFactor();

    // 错误率因子
    factors['errorRate'] = _calculateErrorRateFactor();

    // 负载因子
    factors['load'] = _calculateLoadFactor();

    // 趋势因子
    factors['trend'] = _calculateTrendFactor();

    // 历史性能因子
    factors['history'] = _calculateHistoryFactor();

    // 预测因子
    if (_config.enablePredictiveAdjustment) {
      factors['prediction'] = _calculatePredictionFactor();
    }

    return factors;
  }

  /// 计算吞吐量因子
  double _calculateThroughputFactor() {
    if (_currentThroughput <= 0) return 0.0;

    final throughputRatio = _currentThroughput / _config.targetThroughput;

    if (throughputRatio < 0.5) {
      // 吞吐量过低，需要增加批次大小
      return 0.3;
    } else if (throughputRatio < 0.8) {
      // 吞吐量偏低，略微增加批次大小
      return 0.1;
    } else if (throughputRatio > 1.5) {
      // 吞吐量过高，可能批次大小过大
      return -0.1;
    } else {
      // 吞吐量合适
      return 0.0;
    }
  }

  /// 计算错误率因子
  double _calculateErrorRateFactor() {
    if (!_config.enableErrorRateAwareAdjustment) return 0.0;

    if (_currentErrorRate <= 0) return 0.0;

    final errorRatio = _currentErrorRate / _config.targetErrorRate;

    if (errorRatio > 2.0) {
      // 错误率过高，需要大幅减少批次大小
      return -0.5;
    } else if (errorRatio > 1.5) {
      // 错误率偏高，需要减少批次大小
      return -0.3;
    } else if (errorRatio > 1.0) {
      // 错误率略高，略微减少批次大小
      return -0.1;
    } else {
      // 错误率正常或偏低
      return 0.05;
    }
  }

  /// 计算负载因子
  double _calculateLoadFactor() {
    if (!_config.enableLoadAwareAdjustment) return 0.0;

    switch (_currentLoadLevel) {
      case SystemLoadLevel.light:
        return 0.1; // 轻负载，可以增加批次大小
      case SystemLoadLevel.moderate:
        return 0.0; // 中等负载，保持当前大小
      case SystemLoadLevel.heavy:
        return -0.2; // 重负载，需要减少批次大小
      case SystemLoadLevel.extreme:
        return -0.5; // 极重负载，需要大幅减少批次大小
    }
  }

  /// 计算趋势因子
  double _calculateTrendFactor() {
    if (_history.length < 3) return 0.0;

    // 分析最近的吞吐量趋势
    final recentHistory = _history.takeLast(5).toList();
    final throughputs = recentHistory.map((h) => h.throughput).toList();

    if (throughputs.length < 3) return 0.0;

    // 简单的线性趋势分析
    double trend = 0.0;
    for (int i = 1; i < throughputs.length; i++) {
      trend += throughputs[i] - throughputs[i - 1];
    }
    trend /= (throughputs.length - 1);

    // 根据趋势调整因子
    if (trend > 10) {
      // 吞吐量上升趋势，可以增加批次大小
      return 0.1;
    } else if (trend < -10) {
      // 吞吐量下降趋势，需要减少批次大小
      return -0.1;
    } else {
      return 0.0;
    }
  }

  /// 计算历史性能因子
  double _calculateHistoryFactor() {
    if (_history.length < 5) return 0.0;

    // 分析历史性能数据
    final recentHistory = _history.takeLast(10).toList();

    // 找到最佳性能的批次大小
    double bestPerformance = 0.0;
    int bestSize = _currentBatchSize;

    for (final record in recentHistory) {
      final performance = record.throughput * (1.0 - record.errorRate);
      if (performance > bestPerformance) {
        bestPerformance = performance;
        bestSize = record.size;
      }
    }

    // 如果当前大小不是最佳，建议向最佳大小调整
    if (bestSize != _currentBatchSize) {
      final diff = (bestSize - _currentBatchSize).toDouble();
      return (diff / _currentBatchSize) * 0.2; // 限制调整幅度
    }

    return 0.0;
  }

  /// 计算预测因子
  double _calculatePredictionFactor() {
    // 简化的预测实现
    // 实际实现中可以使用机器学习或更复杂的预测算法

    final memoryTrend = _predictMemoryTrend();
    final loadTrend = _predictLoadTrend();

    if (memoryTrend > 0.1 || loadTrend > 0.1) {
      // 预测负载将增加，提前减少批次大小
      return -0.2;
    } else if (memoryTrend < -0.1 && loadTrend < -0.1) {
      // 预测负载将减少，可以增加批次大小
      return 0.1;
    }

    return 0.0;
  }

  /// 预测内存趋势
  double _predictMemoryTrend() {
    if (_history.length < 3) return 0.0;

    // 分析最近的内存使用情况
    final recentHistory = _history.takeLast(5).toList();
    final loadLevels =
        recentHistory.map((h) => h.loadLevel.index.toDouble()).toList();

    if (loadLevels.length < 3) return 0.0;

    double trend = 0.0;
    for (int i = 1; i < loadLevels.length; i++) {
      trend += loadLevels[i] - loadLevels[i - 1];
    }
    trend /= (loadLevels.length - 1);

    return trend / 3.0; // 归一化到 -1 到 1
  }

  /// 预测负载趋势
  double _predictLoadTrend() {
    // 简化实现，实际需要更复杂的预测逻辑
    return _predictMemoryTrend(); // 暂时使用内存趋势作为负载趋势
  }

  /// 决定调整动作
  SizingAction _decideAdjustmentAction(Map<String, double> factors) {
    // 计算总调整分数
    double totalScore = 0.0;
    double totalWeight = 0.0;

    factors.forEach((key, value) {
      double weight = 1.0;

      // 根据因子类型分配权重
      switch (key) {
        case 'throughput':
          weight = 0.3;
          break;
        case 'errorRate':
          weight = 0.4;
          break;
        case 'load':
          weight = 0.2;
          break;
        case 'trend':
          weight = 0.1;
          break;
        case 'history':
          weight = 0.15;
          break;
        case 'prediction':
          weight = 0.1;
          break;
      }

      totalScore += value * weight;
      totalWeight += weight;
    });

    final finalScore = totalWeight > 0 ? totalScore / totalWeight : 0.0;

    // 应用敏感度
    final adjustedScore = finalScore * _config.adjustmentSensitivity;

    // 决定动作
    if (adjustedScore > 0.2) {
      return SizingAction.increase;
    } else if (adjustedScore < -0.2) {
      return SizingAction.decrease;
    } else {
      return SizingAction.maintain;
    }
  }

  /// 执行调整
  BatchSizingResult _executeAdjustment(
      SizingAction action, Map<String, double> factors) {
    final oldSize = _currentBatchSize;
    int newSize = oldSize;
    String reason = '';
    double confidence = 0.0;

    switch (action) {
      case SizingAction.increase:
        newSize = math.min(
          _config.maxBatchSize,
          oldSize + _config.adjustmentStep,
        );
        reason = '基于性能指标增加批次大小';
        confidence = _calculateConfidence(factors, true);
        break;

      case SizingAction.decrease:
        newSize = math.max(
          _config.minBatchSize,
          oldSize - _config.adjustmentStep,
        );
        reason = '基于性能指标减少批次大小';
        confidence = _calculateConfidence(factors, false);
        break;

      case SizingAction.maintain:
        reason = '保持当前批次大小';
        confidence = 0.8;
        break;

      case SizingAction.reset:
        newSize = _config.initialBatchSize;
        reason = '重置为初始批次大小';
        confidence = 1.0;
        break;
    }

    _currentBatchSize = newSize;

    return BatchSizingResult(
      oldSize: oldSize,
      newSize: newSize,
      action: action,
      reason: reason,
      confidence: confidence,
      factors: factors,
    );
  }

  /// 计算调整置信度
  double _calculateConfidence(Map<String, double> factors, bool isIncrease) {
    double positiveScore = 0.0;
    double negativeScore = 0.0;

    factors.forEach((key, value) {
      if (value > 0) {
        positiveScore += value.abs();
      } else {
        negativeScore += value.abs();
      }
    });

    final totalScore = positiveScore + negativeScore;
    if (totalScore == 0) return 0.5;

    if (isIncrease) {
      return positiveScore / totalScore;
    } else {
      return negativeScore / totalScore;
    }
  }

  /// 记录历史
  void _recordHistory(BatchSizingResult result) {
    final history = BatchSizeHistory(
      size: result.newSize,
      timestamp: DateTime.now(),
      throughput: _currentThroughput,
      errorRate: _currentErrorRate,
      loadLevel: _currentLoadLevel,
      action: result.action,
      reason: result.reason,
    );

    _history.add(history);

    // 清理过期历史记录
    _cleanupHistory();

    AppLogger.debug(
        '批次大小调整历史已记录', '大小: ${result.newSize}, 动作: ${result.action.name}');
  }

  /// 清理过期历史记录
  void _cleanupHistory() {
    final cutoffTime = DateTime.now().subtract(_config.historyRetentionTime);

    while (
        _history.isNotEmpty && _history.first.timestamp.isBefore(cutoffTime)) {
      _history.removeFirst();
    }

    // 限制历史记录数量
    while (_history.length > 1000) {
      _history.removeFirst();
    }
  }

  /// 更新性能指标
  void updatePerformanceMetrics({
    double? throughput,
    double? errorRate,
  }) {
    if (throughput != null) {
      _currentThroughput = throughput;
    }

    if (errorRate != null) {
      _currentErrorRate = errorRate;
    }

    AppLogger.debug(
        '性能指标已更新', '吞吐量: $_currentThroughput, 错误率: $_currentErrorRate');
  }

  /// 手动调整批次大小
  BatchSizingResult manualAdjustment({
    required int newSize,
    String reason = '手动调整',
  }) {
    final clampedSize =
        newSize.clamp(_config.minBatchSize, _config.maxBatchSize);
    final oldSize = _currentBatchSize;
    final action = clampedSize > oldSize
        ? SizingAction.increase
        : clampedSize < oldSize
            ? SizingAction.decrease
            : SizingAction.maintain;

    _currentBatchSize = clampedSize;

    final result = BatchSizingResult(
      oldSize: oldSize,
      newSize: clampedSize,
      action: action,
      reason: reason,
      confidence: 1.0,
      factors: {},
    );

    _recordHistory(result);
    _notifyAdjustmentListeners(result);

    AppLogger.business('手动调整批次大小', '从 $oldSize 到 $clampedSize');

    return result;
  }

  /// 获取推荐批次大小
  int getRecommendedBatchSize() {
    // 基于当前系统状态和历史数据推荐最优批次大小
    final factors = _calculateAdjustmentFactors();
    final action = _decideAdjustmentAction(factors);

    switch (action) {
      case SizingAction.increase:
        return math.min(
          _config.maxBatchSize,
          _currentBatchSize + _config.adjustmentStep,
        );
      case SizingAction.decrease:
        return math.max(
          _config.minBatchSize,
          _currentBatchSize - _config.adjustmentStep,
        );
      default:
        return _currentBatchSize;
    }
  }

  /// 获取当前批次大小
  int get currentBatchSize => _currentBatchSize;

  /// 获取当前策略
  BatchSizingStrategy get currentStrategy => _strategy;

  /// 设置策略
  void setStrategy(BatchSizingStrategy strategy) {
    _strategy = strategy;
    AppLogger.business('批次大小调整策略已设置', strategy.name);
  }

  /// 获取性能摘要
  Map<String, dynamic> getPerformanceSummary() {
    return {
      'currentBatchSize': _currentBatchSize,
      'currentStrategy': _strategy.name,
      'currentThroughput': _currentThroughput,
      'currentErrorRate': _currentErrorRate,
      'currentLoadLevel': _currentLoadLevel.name,
      'historyCount': _history.length,
      'config': {
        'minBatchSize': _config.minBatchSize,
        'maxBatchSize': _config.maxBatchSize,
        'targetThroughput': _config.targetThroughput,
        'targetErrorRate': _config.targetErrorRate,
        'enablePredictiveAdjustment': _config.enablePredictiveAdjustment,
        'adjustmentSensitivity': _config.adjustmentSensitivity,
      },
      'recentHistory': _history.takeLast(10).map((h) => h.toMap()).toList(),
    };
  }

  /// 添加调整监听器
  void addAdjustmentListener(void Function(BatchSizingResult) listener) {
    _adjustmentListeners.add(listener);
  }

  /// 移除调整监听器
  void removeAdjustmentListener(void Function(BatchSizingResult) listener) {
    _adjustmentListeners.remove(listener);
  }

  /// 通知调整监听器
  void _notifyAdjustmentListeners(BatchSizingResult result) {
    for (final listener in _adjustmentListeners) {
      try {
        listener(result);
      } catch (e) {
        AppLogger.error('调整监听器回调失败', e);
      }
    }
  }

  /// 重置调整器
  void reset() {
    _currentBatchSize = _config.initialBatchSize;
    _strategy = BatchSizingStrategy.adaptive;
    _currentThroughput = 0.0;
    _currentErrorRate = 0.0;
    _currentLoadLevel = SystemLoadLevel.light;
    _history.clear();

    AppLogger.business('AdaptiveBatchSizer已重置');
  }

  /// 暂停调整
  void pause() {
    _adjustmentTimer?.cancel();
    AppLogger.debug('AdaptiveBatchSizer已暂停');
  }

  /// 恢复调整
  void resume() {
    _startPeriodicAdjustment();
    AppLogger.debug('AdaptiveBatchSizer已恢复');
  }

  /// 清理资源
  Future<void> dispose() async {
    pause();
    _adjustmentListeners.clear();
    _history.clear();

    AppLogger.business('AdaptiveBatchSizer已清理');
  }
}
