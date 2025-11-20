// ignore_for_file: public_member_api_docs, directives_ordering, sort_constructors_first

import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import '../managers/advanced_memory_manager.dart';
import '../monitors/memory_pressure_monitor.dart';
import '../monitors/device_performance_detector.dart';
import '../../utils/logger.dart';

/// 背压控制级别
enum BackpressureLevel {
  none, // 无背压
  low, // 轻微背压
  medium, // 中等背压
  high, // 高背压
  critical, // 严重背压
  emergency, // 紧急背压
}

/// 背压控制策略
enum BackpressureStrategy {
  rejectNew, // 拒绝新请求
  queueLimit, // 限制队列长度
  slowDown, // 减慢处理速度
  dropLowPriority, // 丢弃低优先级项目
  throttleRate, // 限制速率
  gracefulShutdown // 优雅关闭
}

/// 队列状态
enum QueueState {
  healthy, // 健康
  warning, // 警告
  critical, // 危险
  overflow, // 溢出
}

/// 背压指标
class BackpressureMetrics {
  int currentQueueSize = 0;
  int maxQueueSize = 0;
  double memoryUsageRatio = 0.0;
  double cpuUsageRatio = 0.0;
  double processingLatency = 0.0;
  int rejectedRequests = 0;
  int droppedItems = 0;
  int throttledRequests = 0;
  BackpressureLevel currentLevel = BackpressureLevel.none;
  QueueState queueState = QueueState.healthy;
  DateTime lastAdjustedAt = DateTime.now();

  /// 重置指标
  void reset() {
    currentQueueSize = 0;
    maxQueueSize = 0;
    memoryUsageRatio = 0.0;
    cpuUsageRatio = 0.0;
    processingLatency = 0.0;
    rejectedRequests = 0;
    droppedItems = 0;
    throttledRequests = 0;
    currentLevel = BackpressureLevel.none;
    queueState = QueueState.healthy;
    lastAdjustedAt = DateTime.now();
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'currentQueueSize': currentQueueSize,
      'maxQueueSize': maxQueueSize,
      'memoryUsageRatio': memoryUsageRatio,
      'cpuUsageRatio': cpuUsageRatio,
      'processingLatency': processingLatency,
      'rejectedRequests': rejectedRequests,
      'droppedItems': droppedItems,
      'throttledRequests': throttledRequests,
      'currentLevel': currentLevel.name,
      'queueState': queueState.name,
      'lastAdjustedAt': lastAdjustedAt.toIso8601String(),
    };
  }
}

/// 背压动作
class BackpressureAction {
  final BackpressureStrategy strategy;
  final Map<String, dynamic> parameters;
  final DateTime timestamp;
  final String description;

  BackpressureAction({
    required this.strategy,
    required this.parameters,
    required this.description,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'strategy': strategy.name,
      'parameters': parameters,
      'timestamp': timestamp.toIso8601String(),
      'description': description,
    };
  }
}

/// 背压控制配置
class BackpressureConfig {
  /// 最大队列长度
  int maxQueueSize;

  /// 内存使用阈值
  final double memoryThreshold;

  /// CPU使用阈值
  final double cpuThreshold;

  /// 处理延迟阈值（毫秒）
  final double latencyThreshold;

  /// 低优先级丢弃阈值
  final double lowPriorityDropThreshold;

  /// 速率限制因子
  final double throttlingFactor;

  /// 检查间隔
  final Duration checkInterval;

  /// 调整间隔
  final Duration adjustmentInterval;

  /// 启用自动调整
  final bool enableAutoAdjustment;

  /// 启用渐进式调整
  final bool enableGradualAdjustment;

  /// 动态调整字段
  double autoAdjustThreshold = 0.6;
  double rejectionThreshold = 0.8;
  Duration processingInterval = const Duration(milliseconds: 50);
  bool enableRateLimiting = false;
  int maxRequestsPerSecond = 100;
  bool enablePriorityFiltering = false;
  bool enableRequestRejection = false;
  bool enableEmergencyMode = false;

  BackpressureConfig({
    this.maxQueueSize = 1000,
    this.memoryThreshold = 0.8,
    this.cpuThreshold = 0.7,
    this.latencyThreshold = 500.0,
    this.lowPriorityDropThreshold = 0.9,
    this.throttlingFactor = 0.5,
    this.checkInterval = const Duration(milliseconds: 100),
    this.adjustmentInterval = const Duration(seconds: 1),
    this.enableAutoAdjustment = true,
    this.enableGradualAdjustment = true,
  });
}

/// 背压控制器
class BackpressureController {
  final BackpressureConfig _config;
  final BackpressureMetrics _metrics = BackpressureMetrics();

  // 组件依赖
  AdvancedMemoryManager? _memoryManager;
  MemoryPressureMonitor? _memoryMonitor;
  DeviceCapabilityDetector? _deviceDetector;

  // 定时器
  Timer? _checkTimer;
  Timer? _adjustmentTimer;

  // 状态管理
  BackpressureLevel _currentLevel = BackpressureLevel.none;
  BackpressureStrategy _currentStrategy = BackpressureStrategy.throttleRate;
  final Queue<BackpressureAction> _actionHistory = Queue<BackpressureAction>();

  // 回调函数
  final List<void Function(BackpressureLevel)> _levelChangeListeners = [];
  final List<void Function(BackpressureMetrics)> _metricsUpdateListeners = [];
  final List<void Function(BackpressureAction)> _actionListeners = [];

  // 队列信息（需要外部提供）
  int Function()? _queueSizeProvider;
  double Function()? _processingLatencyProvider;

  BackpressureController({
    BackpressureConfig? config,
    AdvancedMemoryManager? memoryManager,
    MemoryPressureMonitor? memoryMonitor,
    DeviceCapabilityDetector? deviceDetector,
    int Function()? queueSizeProvider,
    double Function()? processingLatencyProvider,
  })  : _config = config ?? BackpressureConfig(),
        _memoryManager = memoryManager,
        _memoryMonitor = memoryMonitor,
        _deviceDetector = deviceDetector,
        _queueSizeProvider = queueSizeProvider,
        _processingLatencyProvider = processingLatencyProvider;

  /// 初始化
  Future<void> initialize() async {
    try {
      // 启动定期检查
      if (_config.enableAutoAdjustment) {
        _startPeriodicCheck();
        _startPeriodicAdjustment();
      }

      AppLogger.business('BackpressureController初始化完成',
          '最大队列: ${_config.maxQueueSize}, 内存阈值: ${_config.memoryThreshold}');
    } catch (e) {
      AppLogger.error('BackpressureController初始化失败', e);
      throw Exception('Failed to initialize BackpressureController: $e');
    }
  }

  /// 启动定期检查
  void _startPeriodicCheck() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(_config.checkInterval, (_) {
      _updateMetrics();
      _evaluateBackpressure();
    });
  }

  /// 启动定期调整
  void _startPeriodicAdjustment() {
    _adjustmentTimer?.cancel();
    _adjustmentTimer = Timer.periodic(_config.adjustmentInterval, (_) {
      _performAdjustment();
    });
  }

  /// 更新指标
  void _updateMetrics() {
    // 更新队列大小
    _metrics.currentQueueSize = _queueSizeProvider?.call() ?? 0;
    _metrics.maxQueueSize =
        math.max(_metrics.maxQueueSize, _metrics.currentQueueSize);

    // 更新内存使用率
    _metrics.memoryUsageRatio = _getMemoryUsageRatio();

    // 更新CPU使用率
    _metrics.cpuUsageRatio = _getCpuUsageRatio();

    // 更新处理延迟
    _metrics.processingLatency = _processingLatencyProvider?.call() ?? 0.0;

    // 更新队列状态
    _updateQueueState();

    // 通知指标更新
    _notifyMetricsUpdateListeners();
  }

  /// 获取内存使用率
  double _getMemoryUsageRatio() {
    if (_memoryManager != null) {
      final memoryInfo = _memoryManager!.getMemoryInfo();
      return 1.0 - (memoryInfo.availableMemoryMB / memoryInfo.totalMemoryMB);
    }

    if (_memoryMonitor != null) {
      final pressureLevel = _memoryMonitor!.currentPressureLevel;
      switch (pressureLevel) {
        case MemoryPressureLevel.normal:
          return 0.3;
        case MemoryPressureLevel.warning:
          return 0.6;
        case MemoryPressureLevel.critical:
          return 0.8;
        case MemoryPressureLevel.emergency:
          return 0.95;
        default:
          return 0.5;
      }
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

  /// 更新队列状态
  void _updateQueueState() {
    final queueRatio = _metrics.currentQueueSize / _config.maxQueueSize;

    if (queueRatio >= 1.0) {
      _metrics.queueState = QueueState.overflow;
    } else if (queueRatio >= 0.8) {
      _metrics.queueState = QueueState.critical;
    } else if (queueRatio >= 0.6) {
      _metrics.queueState = QueueState.warning;
    } else {
      _metrics.queueState = QueueState.healthy;
    }
  }

  /// 评估背压情况
  void _evaluateBackpressure() {
    final newLevel = _calculateBackpressureLevel();

    if (newLevel != _currentLevel) {
      final oldLevel = _currentLevel;
      _currentLevel = newLevel;
      _metrics.currentLevel = newLevel;

      AppLogger.business('背压级别变更', '从 ${oldLevel.name} 到 ${newLevel.name}');

      // 立即响应级别变更
      _handleLevelChange(oldLevel, newLevel);

      // 通知级别变更监听器
      _notifyLevelChangeListeners(newLevel);
    }
  }

  /// 计算背压级别
  BackpressureLevel _calculateBackpressureLevel() {
    double pressureScore = 0.0;

    // 队列压力
    final queueRatio = _metrics.currentQueueSize / _config.maxQueueSize;
    pressureScore += queueRatio * 0.4;

    // 内存压力
    pressureScore += _metrics.memoryUsageRatio * 0.3;

    // CPU压力
    pressureScore += _metrics.cpuUsageRatio * 0.2;

    // 延迟压力
    final latencyRatio = math.min(
      _metrics.processingLatency / _config.latencyThreshold,
      1.0,
    );
    pressureScore += latencyRatio * 0.1;

    // 确定背压级别
    if (pressureScore >= 0.9) {
      return BackpressureLevel.emergency;
    } else if (pressureScore >= 0.8) {
      return BackpressureLevel.critical;
    } else if (pressureScore >= 0.6) {
      return BackpressureLevel.high;
    } else if (pressureScore >= 0.4) {
      return BackpressureLevel.medium;
    } else if (pressureScore >= 0.2) {
      return BackpressureLevel.low;
    } else {
      return BackpressureLevel.none;
    }
  }

  /// 处理级别变更
  void _handleLevelChange(
    BackpressureLevel oldLevel,
    BackpressureLevel newLevel,
  ) {
    // 根据级别变更执行相应的策略
    switch (newLevel) {
      case BackpressureLevel.low:
        _applyLowBackpressure();
        break;
      case BackpressureLevel.medium:
        _applyMediumBackpressure();
        break;
      case BackpressureLevel.high:
        _applyHighBackpressure();
        break;
      case BackpressureLevel.critical:
        _applyCriticalBackpressure();
        break;
      case BackpressureLevel.emergency:
        _applyEmergencyBackpressure();
        break;
      case BackpressureLevel.none:
        _applyNoBackpressure();
        break;
    }
  }

  /// 应用轻微背压
  void _applyLowBackpressure() {
    final action = BackpressureAction(
      strategy: BackpressureStrategy.throttleRate,
      parameters: {
        'throttlingFactor': 0.9,
        'description': '轻微限流处理',
      },
      description: '应用轻微背压控制',
    );

    _executeAction(action);
  }

  /// 应用中等背压
  void _applyMediumBackpressure() {
    final action = BackpressureAction(
      strategy: BackpressureStrategy.throttleRate,
      parameters: {
        'throttlingFactor': 0.7,
        'description': '中等限流处理',
      },
      description: '应用中等背压控制',
    );

    _executeAction(action);
  }

  /// 应用高背压
  void _applyHighBackpressure() {
    final action = BackpressureAction(
      strategy: BackpressureStrategy.queueLimit,
      parameters: {
        'maxQueueSize': _config.maxQueueSize * 0.8,
        'description': '限制队列长度',
      },
      description: '应用高背压控制',
    );

    _executeAction(action);
  }

  /// 应用严重背压
  void _applyCriticalBackpressure() {
    final action = BackpressureAction(
      strategy: BackpressureStrategy.dropLowPriority,
      parameters: {
        'dropThreshold': _config.lowPriorityDropThreshold,
        'description': '丢弃低优先级项目',
      },
      description: '应用严重背压控制',
    );

    _executeAction(action);
  }

  /// 应用紧急背压
  void _applyEmergencyBackpressure() {
    final action = BackpressureAction(
      strategy: BackpressureStrategy.rejectNew,
      parameters: {
        'rejectMessage': '系统负载过高，请稍后重试',
        'description': '拒绝新请求',
      },
      description: '应用紧急背压控制',
    );

    _executeAction(action);
  }

  /// 应用无背压
  void _applyNoBackpressure() {
    final action = BackpressureAction(
      strategy: BackpressureStrategy.throttleRate,
      parameters: {
        'throttlingFactor': 1.0,
        'description': '恢复正常处理',
      },
      description: '解除背压控制',
    );

    _executeAction(action);
  }

  /// 执行背压动作
  void _executeAction(BackpressureAction action) {
    _actionHistory.add(action);
    _metrics.lastAdjustedAt = action.timestamp;

    // 保持历史记录在合理范围内
    if (_actionHistory.length > 100) {
      _actionHistory.removeFirst();
    }

    AppLogger.business(
        '执行背压动作', '策略: ${action.strategy.name}, 描述: ${action.description}');

    // 通知动作监听器
    _notifyActionListeners(action);
  }

  /// 执行定期调整
  void _performAdjustment() {
    if (!_config.enableAutoAdjustment) return;

    // 渐进式调整策略
    if (_config.enableGradualAdjustment) {
      _performGradualAdjustment();
    }

    // 重新评估背压级别
    _evaluateBackpressure();
  }

  /// 执行渐进式调整
  void _performGradualAdjustment() {
    final timeSinceLastAdjustment =
        DateTime.now().difference(_metrics.lastAdjustedAt).inSeconds;

    // 如果距离上次调整时间较短，跳过
    if (timeSinceLastAdjustment < 5) return;

    // 根据当前趋势进行微调
    final queueTrend = _calculateQueueTrend();
    if (queueTrend > 0.1) {
      // 队列增长趋势，稍微加强背压
      _adjustBackpressureGradually(0.1);
    } else if (queueTrend < -0.1) {
      // 队列减少趋势，稍微减弱背压
      _adjustBackpressureGradually(-0.1);
    }
  }

  /// 计算队列趋势
  double _calculateQueueTrend() {
    // 简化实现，实际需要历史数据分析
    final currentRatio = _metrics.currentQueueSize / _config.maxQueueSize;
    final avgRatio = 0.5; // 假设平均值

    return currentRatio - avgRatio;
  }

  /// 渐进式调整背压
  void _adjustBackpressureGradually(double adjustment) {
    final newThrottlingFactor = math.max(
      0.1,
      math.min(1.0, _config.throttlingFactor + adjustment),
    );

    final action = BackpressureAction(
      strategy: BackpressureStrategy.throttleRate,
      parameters: {
        'throttlingFactor': newThrottlingFactor,
        'description': '渐进式调整',
        'adjustment': adjustment,
      },
      description: '渐进式调整背压',
    );

    _executeAction(action);
  }

  /// 手动触发背压控制
  void triggerBackpressure({
    required BackpressureStrategy strategy,
    Map<String, dynamic>? parameters,
    String? description,
  }) {
    final action = BackpressureAction(
      strategy: strategy,
      parameters: parameters ?? {},
      description: description ?? '手动触发的背压控制',
    );

    _executeAction(action);
  }

  /// 检查是否应该拒绝新请求
  bool shouldRejectNewRequest() {
    return _currentLevel == BackpressureLevel.emergency ||
        _metrics.queueState == QueueState.overflow;
  }

  /// 检查是否应该限流
  bool shouldThrottle() {
    return _currentLevel.index >= BackpressureLevel.low.index;
  }

  /// 检查是否应该丢弃低优先级项目
  bool shouldDropLowPriority() {
    return _currentLevel.index >= BackpressureLevel.critical.index ||
        _metrics.queueState == QueueState.critical;
  }

  /// 获取当前限流因子
  double getCurrentThrottlingFactor() {
    switch (_currentLevel) {
      case BackpressureLevel.none:
        return 1.0;
      case BackpressureLevel.low:
        return 0.9;
      case BackpressureLevel.medium:
        return 0.7;
      case BackpressureLevel.high:
        return 0.5;
      case BackpressureLevel.critical:
        return 0.3;
      case BackpressureLevel.emergency:
        return 0.1;
    }
  }

  /// 获取最大允许队列大小
  int getMaxAllowedQueueSize() {
    switch (_currentLevel) {
      case BackpressureLevel.none:
        return _config.maxQueueSize;
      case BackpressureLevel.low:
        return (_config.maxQueueSize * 0.9).round();
      case BackpressureLevel.medium:
        return (_config.maxQueueSize * 0.8).round();
      case BackpressureLevel.high:
        return (_config.maxQueueSize * 0.6).round();
      case BackpressureLevel.critical:
        return (_config.maxQueueSize * 0.4).round();
      case BackpressureLevel.emergency:
        return (_config.maxQueueSize * 0.2).round();
    }
  }

  /// 记录拒绝的请求
  void recordRejectedRequest() {
    _metrics.rejectedRequests++;
  }

  /// 记录丢弃的项目
  void recordDroppedItem() {
    _metrics.droppedItems++;
  }

  /// 记录限流的请求
  void recordThrottledRequest() {
    _metrics.throttledRequests++;
  }

  /// 获取当前级别
  BackpressureLevel get currentLevel => _currentLevel;

  /// 获取指标
  BackpressureMetrics get metrics => BackpressureMetrics()
    ..currentQueueSize = _metrics.currentQueueSize
    ..maxQueueSize = _metrics.maxQueueSize
    ..memoryUsageRatio = _metrics.memoryUsageRatio
    ..cpuUsageRatio = _metrics.cpuUsageRatio
    ..processingLatency = _metrics.processingLatency
    ..rejectedRequests = _metrics.rejectedRequests
    ..droppedItems = _metrics.droppedItems
    ..throttledRequests = _metrics.throttledRequests
    ..currentLevel = _metrics.currentLevel
    ..queueState = _metrics.queueState
    ..lastAdjustedAt = _metrics.lastAdjustedAt;

  /// 获取动作历史
  List<BackpressureAction> get actionHistory => _actionHistory.toList();

  /// 添加级别变更监听器
  void addLevelChangeListener(void Function(BackpressureLevel) listener) {
    _levelChangeListeners.add(listener);
  }

  /// 移除级别变更监听器
  void removeLevelChangeListener(void Function(BackpressureLevel) listener) {
    _levelChangeListeners.remove(listener);
  }

  /// 添加指标更新监听器
  void addMetricsUpdateListener(void Function(BackpressureMetrics) listener) {
    _metricsUpdateListeners.add(listener);
  }

  /// 移除指标更新监听器
  void removeMetricsUpdateListener(
      void Function(BackpressureMetrics) listener) {
    _metricsUpdateListeners.remove(listener);
  }

  /// 添加动作监听器
  void addActionListener(void Function(BackpressureAction) listener) {
    _actionListeners.add(listener);
  }

  /// 移除动作监听器
  void removeActionListener(void Function(BackpressureAction) listener) {
    _actionListeners.remove(listener);
  }

  /// 通知级别变更监听器
  void _notifyLevelChangeListeners(BackpressureLevel level) {
    for (final listener in _levelChangeListeners) {
      try {
        listener(level);
      } catch (e) {
        AppLogger.error('级别变更监听器回调失败', e);
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

  /// 通知动作监听器
  void _notifyActionListeners(BackpressureAction action) {
    for (final listener in _actionListeners) {
      try {
        listener(action);
      } catch (e) {
        AppLogger.error('动作监听器回调失败', e);
      }
    }
  }

  /// 重置控制器
  void reset() {
    _currentLevel = BackpressureLevel.none;
    _metrics.reset();
    _actionHistory.clear();

    AppLogger.business('BackpressureController已重置');
  }

  /// 获取性能摘要
  Map<String, dynamic> getPerformanceSummary() {
    return {
      'currentLevel': _currentLevel.name,
      'metrics': _metrics.toMap(),
      'config': {
        'maxQueueSize': _config.maxQueueSize,
        'memoryThreshold': _config.memoryThreshold,
        'cpuThreshold': _config.cpuThreshold,
        'latencyThreshold': _config.latencyThreshold,
        'enableAutoAdjustment': _config.enableAutoAdjustment,
        'enableGradualAdjustment': _config.enableGradualAdjustment,
      },
      'recentActions': _actionHistory.length > 10
          ? _actionHistory
              .skip(_actionHistory.length - 10)
              .map((a) => a.toMap())
              .toList()
          : _actionHistory.map((a) => a.toMap()).toList(),
    };
  }

  /// 暂停控制
  void pause() {
    _checkTimer?.cancel();
    _adjustmentTimer?.cancel();
    AppLogger.debug('BackpressureController已暂停');
  }

  /// 恢复控制
  void resume() {
    if (_config.enableAutoAdjustment) {
      _startPeriodicCheck();
      _startPeriodicAdjustment();
    }
    AppLogger.debug('BackpressureController已恢复');
  }

  /// 启用平衡模式
  void enableBalancedMode() {
    AppLogger.business('启用背压平衡模式');

    // 设置平衡模式配置
    _config.autoAdjustThreshold = 0.6;
    _config.maxQueueSize = (_config.maxQueueSize * 1.2).round();
    _config.rejectionThreshold = 0.8;

    // 设置平衡策略
    _currentStrategy = BackpressureStrategy.slowDown;

    AppLogger.debug(
        '背压平衡模式已启用',
        '阈值: ${_config.autoAdjustThreshold}, '
            '最大队列: ${_config.maxQueueSize}');
  }

  /// 应用背压控制
  void applyBackpressure() {
    if (_currentLevel == BackpressureLevel.none) {
      return; // 无需应用背压
    }

    AppLogger.debug('应用背压控制', '当前级别: ${_currentLevel.name}');

    switch (_currentLevel) {
      case BackpressureLevel.low:
        _applyLowBackpressure();
        break;
      case BackpressureLevel.medium:
        _applyMediumBackpressure();
        break;
      case BackpressureLevel.high:
        _applyHighBackpressure();
        break;
      case BackpressureLevel.critical:
        _applyCriticalBackpressure();
        break;
      case BackpressureLevel.emergency:
        _applyEmergencyBackpressure();
        break;
      case BackpressureLevel.none:
        break;
    }
  }

  /// 清理资源
  Future<void> dispose() async {
    pause();

    _levelChangeListeners.clear();
    _metricsUpdateListeners.clear();
    _actionListeners.clear();
    _actionHistory.clear();

    AppLogger.business('BackpressureController已清理');
  }
}
