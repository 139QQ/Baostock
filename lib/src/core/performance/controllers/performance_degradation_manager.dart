import 'dart:async';

import '../monitors/device_performance_detector.dart';
import '../monitors/memory_pressure_monitor.dart';
import '../profiles/device_performance_profile.dart';
import '../managers/advanced_memory_manager.dart';
import '../../utils/logger.dart';

/// 性能降级级别
enum DegradationLevel {
  none, // 无降级 - 100%性能
  minimal, // 最小降级 - 80%性能
  moderate, // 适度降级 - 60%性能
  significant, // 显著降级 - 40%性能
  severe, // 严重降级 - 20%性能
}

/// 降级触发条件
enum DegradationTrigger {
  memoryPressure, // 内存压力
  cpuUsage, // CPU使用率
  thermalThrottling, // 热降频
  batteryLow, // 低电量
  networkCongestion, // 网络拥塞
  userPreference, // 用户偏好
  custom, // 自定义条件
}

/// 降级策略配置
class DegradationStrategy {
  final DegradationLevel level;
  final DegradationTrigger trigger;
  final Map<String, dynamic> adjustments;
  final Duration cooldown;
  final bool autoRecovery;

  const DegradationStrategy({
    required this.level,
    required this.trigger,
    required this.adjustments,
    this.cooldown = const Duration(minutes: 5),
    this.autoRecovery = true,
  });
}

/// 性能降级状态
class DegradationState {
  final DegradationLevel currentLevel;
  final DegradationLevel previousLevel;
  final DateTime lastChangedAt;
  final DegradationTrigger lastTrigger;
  final Map<String, dynamic> activeAdjustments;
  final Duration timeInCurrentState;

  DegradationState({
    required this.currentLevel,
    this.previousLevel = DegradationLevel.none,
    required this.lastChangedAt,
    required this.lastTrigger,
    required this.activeAdjustments,
  }) : timeInCurrentState = DateTime.now().difference(lastChangedAt);

  /// 是否处于降级状态
  bool get isDegraded => currentLevel != DegradationLevel.none;

  /// 降级持续时间
  Duration get degradationDuration => timeInCurrentState;
}

/// 性能指标阈值
class PerformanceThresholds {
  final double memoryUsageThreshold; // 内存使用率阈值 (0-1)
  final double cpuUsageThreshold; // CPU使用率阈值 (0-1)
  final double thermalThreshold; // 温度阈值 (摄氏度)
  final double batteryLevelThreshold; // 电量阈值 (0-1)
  final int networkLatencyThreshold; // 网络延迟阈值 (毫秒)

  const PerformanceThresholds({
    this.memoryUsageThreshold = 0.85,
    this.cpuUsageThreshold = 0.80,
    this.thermalThreshold = 70.0,
    this.batteryLevelThreshold = 0.20,
    this.networkLatencyThreshold = 2000,
  });
}

/// 性能降级管理器
class PerformanceDegradationManager {
  static PerformanceDegradationManager? _instance;
  static PerformanceDegradationManager get instance =>
      _instance ??= PerformanceDegradationManager._();

  PerformanceDegradationManager._();

  // 核心组件
  DeviceCapabilityDetector? _deviceDetector;
  MemoryPressureMonitor? _memoryMonitor;
  DeviceProfileManager? _profileManager;

  // 状态管理
  DegradationState? _currentState;
  final List<DegradationStrategy> _strategies = [];
  final Map<DegradationTrigger, DateTime> _triggerCooldowns = {};

  // 监控定时器
  Timer? _monitoringTimer;
  Timer? _recoveryCheckTimer;

  // 配置
  PerformanceThresholds _thresholds = const PerformanceThresholds();
  Duration _monitoringInterval = const Duration(seconds: 2);
  Duration _recoveryCheckInterval = const Duration(seconds: 30);

  // 事件回调
  final List<void Function(DegradationState)> _degradationListeners = [];
  final List<void Function(DegradationState)> _recoveryListeners = [];

  /// 初始化降级管理器
  Future<void> initialize({
    DeviceCapabilityDetector? deviceDetector,
    MemoryPressureMonitor? memoryMonitor,
    DeviceProfileManager? profileManager,
    PerformanceThresholds? thresholds,
    Duration? monitoringInterval,
    Duration? recoveryCheckInterval,
  }) async {
    try {
      _deviceDetector = deviceDetector;
      _memoryMonitor = memoryMonitor;
      _profileManager = profileManager;

      if (thresholds != null) _thresholds = thresholds;
      if (monitoringInterval != null) _monitoringInterval = monitoringInterval;
      if (recoveryCheckInterval != null)
        _recoveryCheckInterval = recoveryCheckInterval;

      // 初始化状态
      _currentState = DegradationState(
        currentLevel: DegradationLevel.none,
        lastChangedAt: DateTime.now(),
        lastTrigger: DegradationTrigger.custom,
        activeAdjustments: {},
      );

      // 设置默认降级策略
      _setupDefaultStrategies();

      // 启动监控
      _startMonitoring();

      AppLogger.business('PerformanceDegradationManager初始化完成');
    } catch (e) {
      AppLogger.error('PerformanceDegradationManager初始化失败', e);
    }
  }

  /// 设置默认降级策略
  void _setupDefaultStrategies() {
    _strategies.clear();

    // 内存压力策略
    _strategies.add(const DegradationStrategy(
      level: DegradationLevel.minimal,
      trigger: DegradationTrigger.memoryPressure,
      adjustments: {
        'cache_size_multiplier': 0.8,
        'preload_count_multiplier': 0.7,
        'animation_duration_multiplier': 0.8,
        'max_concurrent_requests': 4,
      },
    ));

    _strategies.add(DegradationStrategy(
      level: DegradationLevel.moderate,
      trigger: DegradationTrigger.memoryPressure,
      adjustments: {
        'cache_size_multiplier': 0.6,
        'preload_count_multiplier': 0.5,
        'animation_duration_multiplier': 0.5,
        'max_concurrent_requests': 3,
        'enable_background_processing': false,
      },
    ));

    _strategies.add(DegradationStrategy(
      level: DegradationLevel.significant,
      trigger: DegradationTrigger.memoryPressure,
      adjustments: {
        'cache_size_multiplier': 0.4,
        'preload_count_multiplier': 0.3,
        'animation_duration_multiplier': 0.2,
        'max_concurrent_requests': 2,
        'enable_compression': true,
        'enable_advanced_features': false,
      },
    ));

    // CPU使用率策略
    _strategies.add(DegradationStrategy(
      level: DegradationLevel.minimal,
      trigger: DegradationTrigger.cpuUsage,
      adjustments: {
        'ui_update_interval_ms': 200,
        'batch_size_multiplier': 0.8,
        'animation_duration_multiplier': 0.7,
      },
    ));

    _strategies.add(DegradationStrategy(
      level: DegradationLevel.moderate,
      trigger: DegradationTrigger.cpuUsage,
      adjustments: {
        'ui_update_interval_ms': 500,
        'batch_size_multiplier': 0.6,
        'animation_duration_multiplier': 0.3,
      },
    ));

    // 热降频策略
    _strategies.add(DegradationStrategy(
      level: DegradationLevel.significant,
      trigger: DegradationTrigger.thermalThrottling,
      adjustments: {
        'max_concurrent_requests': 2,
        'enable_background_processing': false,
        'ui_update_interval_ms': 1000,
        'animation_duration_multiplier': 0.0,
      },
      cooldown: const Duration(minutes: 10),
    ));

    // 低电量策略
    _strategies.add(DegradationStrategy(
      level: DegradationLevel.minimal,
      trigger: DegradationTrigger.batteryLow,
      adjustments: {
        'cache_size_multiplier': 0.7,
        'preload_count_multiplier': 0.5,
        'animation_duration_multiplier': 0.5,
        'enable_background_processing': false,
      },
    ));
  }

  /// 启动性能监控
  void _startMonitoring() {
    _monitoringTimer?.cancel();
    _recoveryCheckTimer?.cancel();

    // 性能监控定时器
    _monitoringTimer = Timer.periodic(_monitoringInterval, (_) {
      _checkPerformanceMetrics();
    });

    // 恢复检查定时器
    _recoveryCheckTimer = Timer.periodic(_recoveryCheckInterval, (_) {
      _checkRecoveryConditions();
    });

    AppLogger.debug('性能降级监控已启动');
  }

  /// 检查性能指标
  Future<void> _checkPerformanceMetrics() async {
    try {
      final metrics = await _collectPerformanceMetrics();
      final triggers = _evaluateTriggers(metrics);

      for (final trigger in triggers) {
        if (_shouldApplyDegradation(trigger)) {
          await _applyDegradation(trigger);
        }
      }
    } catch (e) {
      AppLogger.error('性能指标检查失败', e);
    }
  }

  /// 收集性能指标
  Future<Map<String, double>> _collectPerformanceMetrics() async {
    final metrics = <String, double>{};

    try {
      // 内存使用率
      if (_memoryMonitor != null) {
        final pressureLevel = _memoryMonitor!.currentPressureLevel;
        final memoryUsage = _pressureToUsage(pressureLevel);
        metrics['memory_usage'] = memoryUsage;
      } else {
        metrics['memory_usage'] = 0.5; // 默认值
      }

      // CPU使用率 (简化实现)
      metrics['cpu_usage'] = 0.3; // 实际需要使用系统API

      // 温度 (简化实现)
      metrics['thermal'] = 45.0; // 实际需要使用温度传感器API

      // 电量 (简化实现)
      metrics['battery_level'] = 0.8; // 实际需要使用电池API

      // 网络延迟 (简化实现)
      metrics['network_latency'] = 150.0; // 实际需要网络测试
    } catch (e) {
      AppLogger.debug('性能指标收集失败，使用默认值');
      metrics.addAll({
        'memory_usage': 0.5,
        'cpu_usage': 0.3,
        'thermal': 45.0,
        'battery_level': 0.8,
        'network_latency': 150.0,
      });
    }

    return metrics;
  }

  /// 将压力级别转换为使用率
  double _pressureToUsage(MemoryPressureLevel level) {
    switch (level) {
      case MemoryPressureLevel.normal:
        return 0.3;
      case MemoryPressureLevel.warning:
        return 0.6;
      case MemoryPressureLevel.critical:
        return 0.8;
      case MemoryPressureLevel.emergency:
        return 0.95;
    }
  }

  /// 评估触发条件
  List<DegradationTrigger> _evaluateTriggers(Map<String, double> metrics) {
    final triggers = <DegradationTrigger>[];

    // 内存压力
    if (metrics['memory_usage']! > _thresholds.memoryUsageThreshold) {
      triggers.add(DegradationTrigger.memoryPressure);
    }

    // CPU使用率
    if (metrics['cpu_usage']! > _thresholds.cpuUsageThreshold) {
      triggers.add(DegradationTrigger.cpuUsage);
    }

    // 热降频
    if (metrics['thermal']! > _thresholds.thermalThreshold) {
      triggers.add(DegradationTrigger.thermalThrottling);
    }

    // 低电量
    if (metrics['battery_level']! < _thresholds.batteryLevelThreshold) {
      triggers.add(DegradationTrigger.batteryLow);
    }

    // 网络拥塞
    if (metrics['network_latency']! > _thresholds.networkLatencyThreshold) {
      triggers.add(DegradationTrigger.networkCongestion);
    }

    return triggers;
  }

  /// 判断是否应该应用降级
  bool _shouldApplyDegradation(DegradationTrigger trigger) {
    // 检查冷却时间
    final now = DateTime.now();
    final lastTriggered = _triggerCooldowns[trigger];
    if (lastTriggered != null && now.difference(lastTriggered).inSeconds < 60) {
      return false;
    }

    // 检查当前降级级别
    final currentLevel = _currentState?.currentLevel ?? DegradationLevel.none;
    if (currentLevel == DegradationLevel.severe) {
      return false; // 已经是最高降级级别
    }

    return true;
  }

  /// 应用降级策略
  Future<void> _applyDegradation(DegradationTrigger trigger) async {
    try {
      // 查找合适的降级策略
      final strategy = _findStrategyForTrigger(trigger);
      if (strategy == null) return;

      // 记录触发时间
      _triggerCooldowns[trigger] = DateTime.now();

      // 应用调整
      final newAdjustments =
          Map<String, dynamic>.from(_currentState?.activeAdjustments ?? {});
      newAdjustments.addAll(strategy.adjustments);

      // 创建新状态
      final newState = DegradationState(
        currentLevel: strategy.level,
        previousLevel: _currentState?.currentLevel ?? DegradationLevel.none,
        lastChangedAt: DateTime.now(),
        lastTrigger: trigger,
        activeAdjustments: newAdjustments,
      );

      _currentState = newState;

      // 应用到性能配置
      await _applyToPerformanceProfile(strategy);

      // 通知监听器
      _notifyDegradationListeners(newState);

      AppLogger.business(
          '性能降级已应用', '级别: ${strategy.level.name}, 触发: ${trigger.name}');
    } catch (e) {
      AppLogger.error('应用性能降级失败', e);
    }
  }

  /// 查找触发条件对应的策略
  DegradationStrategy? _findStrategyForTrigger(DegradationTrigger trigger) {
    // 根据当前状态和触发条件选择合适的策略
    final currentLevel = _currentState?.currentLevel ?? DegradationLevel.none;

    for (final strategy in _strategies) {
      if (strategy.trigger == trigger &&
          strategy.level.index > currentLevel.index) {
        return strategy;
      }
    }

    return null;
  }

  /// 应用到性能配置
  Future<void> _applyToPerformanceProfile(DegradationStrategy strategy) async {
    if (_profileManager == null) return;

    try {
      await _profileManager!.updateSettings(strategy.adjustments);
      AppLogger.debug('性能降级设置已应用到配置文件');
    } catch (e) {
      AppLogger.error('应用性能降级设置失败', e);
    }
  }

  /// 检查恢复条件
  Future<void> _checkRecoveryConditions() async {
    if (_currentState == null || !_currentState!.isDegraded) return;

    try {
      final canRecover = await _evaluateRecoveryConditions();
      if (canRecover) {
        await _performRecovery();
      }
    } catch (e) {
      AppLogger.error('恢复条件检查失败', e);
    }
  }

  /// 评估恢复条件
  Future<bool> _evaluateRecoveryConditions() async {
    final metrics = await _collectPerformanceMetrics();

    // 检查各项指标是否都在安全范围内
    if (metrics['memory_usage']! > _thresholds.memoryUsageThreshold * 0.8) {
      return false;
    }

    if (metrics['cpu_usage']! > _thresholds.cpuUsageThreshold * 0.8) {
      return false;
    }

    if (metrics['thermal']! > _thresholds.thermalThreshold * 0.9) {
      return false;
    }

    // 检查降级持续时间
    const minDuration = Duration(minutes: 2);
    if (_currentState!.degradationDuration < minDuration) {
      return false;
    }

    return true;
  }

  /// 执行恢复
  Future<void> _performRecovery() async {
    try {
      final previousLevel = _currentState!.previousLevel;
      final newAdjustments = <String, dynamic>{};

      // 根据恢复级别调整设置
      if (previousLevel == DegradationLevel.none) {
        // 完全恢复
        await _profileManager?.resetToDefault();
        newAdjustments.clear();
      } else {
        // 部分恢复，找到对应级别的设置
        final strategy =
            _strategies.where((s) => s.level == previousLevel).firstOrNull;
        if (strategy != null) {
          newAdjustments.addAll(strategy.adjustments);
        }
      }

      // 创建恢复状态
      final recoveredState = DegradationState(
        currentLevel: previousLevel,
        previousLevel: _currentState!.currentLevel,
        lastChangedAt: DateTime.now(),
        lastTrigger: DegradationTrigger.custom,
        activeAdjustments: newAdjustments,
      );

      _currentState = recoveredState;

      // 通知恢复监听器
      _notifyRecoveryListeners(recoveredState);

      AppLogger.business('性能降级已恢复', '恢复到级别: ${previousLevel.name}');
    } catch (e) {
      AppLogger.error('性能降级恢复失败', e);
    }
  }

  /// 手动触发降级
  Future<void> triggerDegradation({
    required DegradationLevel level,
    required Map<String, dynamic> adjustments,
    DegradationTrigger trigger = DegradationTrigger.custom,
  }) async {
    const strategy = DegradationStrategy(
      level: DegradationLevel.minimal, // 使用一个默认值
      trigger: DegradationTrigger.custom,
      adjustments: {},
    );

    await _applyDegradation(trigger);
  }

  /// 手动恢复
  Future<void> manualRecovery() async {
    if (_currentState?.isDegraded ?? false) {
      await _performRecovery();
    }
  }

  /// 获取当前状态
  DegradationState? get currentState => _currentState;

  /// 是否处于降级状态
  bool get isDegraded => _currentState?.isDegraded ?? false;

  /// 获取当前降级级别
  DegradationLevel get currentLevel =>
      _currentState?.currentLevel ?? DegradationLevel.none;

  /// 添加降级监听器
  void addDegradationListener(void Function(DegradationState) listener) {
    _degradationListeners.add(listener);
  }

  /// 添加恢复监听器
  void addRecoveryListener(void Function(DegradationState) listener) {
    _recoveryListeners.add(listener);
  }

  /// 移除降级监听器
  void removeDegradationListener(void Function(DegradationState) listener) {
    _degradationListeners.remove(listener);
  }

  /// 移除恢复监听器
  void removeRecoveryListener(void Function(DegradationState) listener) {
    _recoveryListeners.remove(listener);
  }

  /// 通知降级监听器
  void _notifyDegradationListeners(DegradationState state) {
    for (final listener in _degradationListeners) {
      try {
        listener(state);
      } catch (e) {
        AppLogger.error('降级监听器回调失败', e);
      }
    }
  }

  /// 通知恢复监听器
  void _notifyRecoveryListeners(DegradationState state) {
    for (final listener in _recoveryListeners) {
      try {
        listener(state);
      } catch (e) {
        AppLogger.error('恢复监听器回调失败', e);
      }
    }
  }

  /// 更新阈值
  void updateThresholds(PerformanceThresholds newThresholds) {
    _thresholds = newThresholds;
    AppLogger.debug('性能降级阈值已更新');
  }

  /// 添加自定义策略
  void addCustomStrategy(DegradationStrategy strategy) {
    _strategies.add(strategy);
    AppLogger.debug('自定义降级策略已添加');
  }

  /// 获取性能统计
  Map<String, dynamic> getPerformanceStats() {
    return {
      'currentLevel': currentLevel.name,
      'isDegraded': isDegraded,
      'degradationDuration': _currentState?.degradationDuration.inSeconds ?? 0,
      'lastTrigger': _currentState?.lastTrigger.name,
      'activeAdjustments': _currentState?.activeAdjustments ?? {},
      'strategiesCount': _strategies.length,
      'triggerCooldowns': _triggerCooldowns
          .map((k, v) => MapEntry(k.name, v.toIso8601String())),
    };
  }

  /// 暂停监控
  void pauseMonitoring() {
    _monitoringTimer?.cancel();
    _recoveryCheckTimer?.cancel();
    AppLogger.debug('性能降级监控已暂停');
  }

  /// 恢复监控
  void resumeMonitoring() {
    if (_monitoringTimer == null || !_monitoringTimer!.isActive) {
      _startMonitoring();
    }
    AppLogger.debug('性能降级监控已恢复');
  }

  /// 清理资源
  Future<void> dispose() async {
    _monitoringTimer?.cancel();
    _recoveryCheckTimer?.cancel();

    _degradationListeners.clear();
    _recoveryListeners.clear();
    _strategies.clear();
    _triggerCooldowns.clear();

    _currentState = null;

    AppLogger.business('PerformanceDegradationManager已清理');
  }
}
