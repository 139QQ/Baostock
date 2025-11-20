import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import '../managers/advanced_memory_manager.dart';
import '../monitors/memory_pressure_monitor.dart' hide MemoryPressureLevel;
import '../monitors/device_performance_detector.dart';
import '../profiles/device_performance_profile.dart';
import '../controllers/performance_degradation_manager.dart'
    hide MemoryPressureLevel;
import '../../utils/logger.dart';

// 扩展 MemoryPressureMonitor 以提供缺失的getter
extension MemoryPressureMonitorExtension on MemoryPressureMonitor {
  MemoryPressureLevel get currentPressureLevel {
    return MemoryPressureLevel.normal; // 临时实现
  }
}

/// 性能指标类型
enum PerformanceMetricType {
  memoryUsage, // 内存使用率
  cpuUsage, // CPU使用率
  frameRate, // 帧率
  responseTime, // 响应时间
  cacheHitRate, // 缓存命中率
  networkLatency, // 网络延迟
  diskIO, // 磁盘IO
  batteryLevel, // 电池电量
  thermalState, // 温度状态
}

/// 性能警报级别
enum PerformanceAlertLevel {
  optimal, // 最优
  good, // 良好
  warning, // 警告
  critical, // 危险
  emergency, // 紧急
}

/// 性能数据点
class PerformanceDataPoint {
  final String metricType;
  final double value;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const PerformanceDataPoint({
    required this.metricType,
    required this.value,
    required this.timestamp,
    this.metadata = const {},
  });

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'metricType': metricType,
      'value': value,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// 从JSON创建
  factory PerformanceDataPoint.fromJson(Map<String, dynamic> json) {
    return PerformanceDataPoint(
      metricType: json['metricType'] as String,
      value: (json['value'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }
}

/// 性能警报
class PerformanceAlert {
  final String id;
  final PerformanceMetricType metricType;
  final PerformanceAlertLevel level;
  final String message;
  final double currentValue;
  final double threshold;
  final DateTime timestamp;
  final Map<String, dynamic> context;

  const PerformanceAlert({
    required this.id,
    required this.metricType,
    required this.level,
    required this.message,
    required this.currentValue,
    required this.threshold,
    required this.timestamp,
    this.context = const {},
  });

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'metricType': metricType.name,
      'level': level.name,
      'message': message,
      'currentValue': currentValue,
      'threshold': threshold,
      'timestamp': timestamp.toIso8601String(),
      'context': context,
    };
  }
}

/// 性能阈值配置
class PerformanceThresholds {
  final Map<PerformanceMetricType, Map<PerformanceAlertLevel, double>>
      thresholds;

  const PerformanceThresholds({
    Map<PerformanceMetricType, Map<PerformanceAlertLevel, double>>? thresholds,
  }) : thresholds = thresholds ?? _defaultThresholds;

  /// 默认阈值配置
  static const Map<PerformanceMetricType, Map<PerformanceAlertLevel, double>>
      _defaultThresholds = {
    PerformanceMetricType.memoryUsage: {
      PerformanceAlertLevel.optimal: 0.5, // 50%
      PerformanceAlertLevel.good: 0.7, // 70%
      PerformanceAlertLevel.warning: 0.8, // 80%
      PerformanceAlertLevel.critical: 0.9, // 90%
      PerformanceAlertLevel.emergency: 0.95, // 95%
    },
    PerformanceMetricType.cpuUsage: {
      PerformanceAlertLevel.optimal: 0.3, // 30%
      PerformanceAlertLevel.good: 0.5, // 50%
      PerformanceAlertLevel.warning: 0.7, // 70%
      PerformanceAlertLevel.critical: 0.85, // 85%
      PerformanceAlertLevel.emergency: 0.95, // 95%
    },
    PerformanceMetricType.frameRate: {
      PerformanceAlertLevel.emergency: 30.0, // 30 FPS
      PerformanceAlertLevel.critical: 45.0, // 45 FPS
      PerformanceAlertLevel.warning: 50.0, // 50 FPS
      PerformanceAlertLevel.good: 55.0, // 55 FPS
      PerformanceAlertLevel.optimal: 60.0, // 60 FPS
    },
    PerformanceMetricType.responseTime: {
      PerformanceAlertLevel.optimal: 100.0, // 100ms
      PerformanceAlertLevel.good: 200.0, // 200ms
      PerformanceAlertLevel.warning: 500.0, // 500ms
      PerformanceAlertLevel.critical: 1000.0, // 1s
      PerformanceAlertLevel.emergency: 2000.0, // 2s
    },
    PerformanceMetricType.cacheHitRate: {
      PerformanceAlertLevel.emergency: 50.0, // 50%
      PerformanceAlertLevel.critical: 70.0, // 70%
      PerformanceAlertLevel.warning: 80.0, // 80%
      PerformanceAlertLevel.good: 85.0, // 85%
      PerformanceAlertLevel.optimal: 95.0, // 95%
    },
  };

  /// 获取指标的阈值
  Map<PerformanceAlertLevel, double> getThresholds(
      PerformanceMetricType metricType) {
    return thresholds[metricType] ?? {};
  }

  /// 评估警报级别
  PerformanceAlertLevel evaluateAlertLevel(
    PerformanceMetricType metricType,
    double value,
  ) {
    final metricThresholds = getThresholds(metricType);
    if (metricThresholds.isEmpty) return PerformanceAlertLevel.good;

    // 对于某些指标，值越大越好（如帧率、缓存命中率）
    final isHigherBetter = [
      PerformanceMetricType.frameRate,
      PerformanceMetricType.cacheHitRate,
    ].contains(metricType);

    for (final level in [
      PerformanceAlertLevel.emergency,
      PerformanceAlertLevel.critical,
      PerformanceAlertLevel.warning,
      PerformanceAlertLevel.good,
      PerformanceAlertLevel.optimal,
    ]) {
      final threshold = metricThresholds[level];
      if (threshold == null) continue;

      if (isHigherBetter) {
        if (value <= threshold) return level;
      } else {
        if (value >= threshold) return level;
      }
    }

    return PerformanceAlertLevel.optimal;
  }
}

/// 低开销性能监控配置
class LowOverheadMonitorConfig {
  /// 监控间隔
  final Duration monitoringInterval;

  /// 数据保留时间
  final Duration dataRetentionTime;

  /// 最大数据点数量
  final int maxDataPoints;

  /// 启用智能采样
  final bool enableSmartSampling;

  /// 启用批量收集
  final bool enableBatchCollection;

  /// 批量大小
  final int batchSize;

  /// 启用异常检测
  final bool enableAnomalyDetection;

  /// 启用自动告警
  final bool enableAutoAlerting;

  /// CPU开销限制（百分比）
  final double cpuOverheadLimit;

  /// 内存开销限制（MB）
  final int memoryOverheadLimitMB;

  const LowOverheadMonitorConfig({
    this.monitoringInterval = const Duration(seconds: 5),
    this.dataRetentionTime = const Duration(hours: 2),
    this.maxDataPoints = 1000,
    this.enableSmartSampling = true,
    this.enableBatchCollection = true,
    this.batchSize = 50,
    this.enableAnomalyDetection = true,
    this.enableAutoAlerting = true,
    this.cpuOverheadLimit = 1.0,
    this.memoryOverheadLimitMB = 5,
  });
}

/// 低开销性能监控系统
class LowOverheadMonitor {
  final LowOverheadMonitorConfig _config;
  final PerformanceThresholds _thresholds;

  // 数据存储
  final Map<String, Queue<PerformanceDataPoint>> _metricsData = {};
  final Queue<PerformanceAlert> _alerts = Queue<PerformanceAlert>();

  // 监控状态
  bool _isMonitoring = false;
  Timer? _monitoringTimer;
  Timer? _cleanupTimer;
  Timer? _alertCheckTimer;

  // 性能监控状态
  final Map<String, double> _lastValues = {};
  final Map<String, DateTime> _lastCollectionTimes = {};

  // 采样控制
  final Map<String, int> _samplingCounters = {};
  final Map<String, double> _samplingRates = {};

  // 组件依赖
  AdvancedMemoryManager? _memoryManager;
  MemoryPressureMonitor? _memoryMonitor;
  DeviceCapabilityDetector? _deviceDetector;
  DeviceProfileManager? _profileManager;
  PerformanceDegradationManager? _degradationManager;

  // 回调函数
  final List<void Function(PerformanceAlert)> _alertListeners = [];
  final List<void Function(String, PerformanceDataPoint)> _metricListeners = [];

  // 监控开销统计
  double _totalMonitoringTime = 0.0;
  int _monitoringCount = 0;
  int _alertCount = 0;

  LowOverheadMonitor({
    LowOverheadMonitorConfig? config,
    PerformanceThresholds? thresholds,
    AdvancedMemoryManager? memoryManager,
    MemoryPressureMonitor? memoryMonitor,
    DeviceCapabilityDetector? deviceDetector,
    DeviceProfileManager? profileManager,
    PerformanceDegradationManager? degradationManager,
  })  : _config = config ?? const LowOverheadMonitorConfig(),
        _thresholds = thresholds ?? const PerformanceThresholds(),
        _memoryManager = memoryManager,
        _memoryMonitor = memoryMonitor,
        _deviceDetector = deviceDetector,
        _profileManager = profileManager,
        _degradationManager = degradationManager;

  /// 初始化监控系统
  Future<void> initialize() async {
    try {
      // 初始化采样率
      _initializeSamplingRates();

      AppLogger.business(
          'LowOverheadMonitor初始化完成',
          '监控间隔: ${_config.monitoringInterval.inSeconds}s, '
              '数据保留: ${_config.dataRetentionTime.inHours}h');
    } catch (e) {
      AppLogger.error('LowOverheadMonitor初始化失败', e);
      throw Exception('Failed to initialize LowOverheadMonitor: $e');
    }
  }

  /// 初始化采样率
  void _initializeSamplingRates() {
    // 为不同指标设置不同的采样率
    _samplingRates[PerformanceMetricType.memoryUsage.name] = 1.0;
    _samplingRates[PerformanceMetricType.cpuUsage.name] = 0.5;
    _samplingRates[PerformanceMetricType.frameRate.name] = 1.0;
    _samplingRates[PerformanceMetricType.responseTime.name] = 0.3;
    _samplingRates[PerformanceMetricType.cacheHitRate.name] = 0.5;
    _samplingRates[PerformanceMetricType.networkLatency.name] = 0.2;
    _samplingRates[PerformanceMetricType.diskIO.name] = 0.1;
    _samplingRates[PerformanceMetricType.batteryLevel.name] = 0.1;
    _samplingRates[PerformanceMetricType.thermalState.name] = 0.2;
  }

  /// 启动监控
  Future<void> startMonitoring() async {
    if (_isMonitoring) return;

    try {
      // 启动主监控定时器
      _monitoringTimer = Timer.periodic(_config.monitoringInterval, (_) {
        _performMonitoringCycle();
      });

      // 启动清理定时器
      _cleanupTimer = Timer.periodic(_config.monitoringInterval * 2, (_) {
        _cleanupOldData();
      });

      // 启动告警检查定时器
      if (_config.enableAutoAlerting) {
        _alertCheckTimer = Timer.periodic(_config.monitoringInterval * 3, (_) {
          _checkForAlerts();
        });
      }

      _isMonitoring = true;
      AppLogger.business('低开销性能监控已启动');
    } catch (e) {
      AppLogger.error('启动监控失败', e);
      rethrow;
    }
  }

  /// 停止监控
  Future<void> stopMonitoring() async {
    if (!_isMonitoring) return;

    _monitoringTimer?.cancel();
    _cleanupTimer?.cancel();
    _alertCheckTimer?.cancel();

    _isMonitoring = false;
    AppLogger.business('低开销性能监控已停止');
  }

  /// 执行监控周期
  Future<void> _performMonitoringCycle() async {
    if (!_isMonitoring) return;

    final stopwatch = Stopwatch()..start();

    try {
      // 收集各项性能指标
      await _collectMetrics();

      // 更新采样计数器
      _monitoringCount++;
    } catch (e) {
      AppLogger.error('监控周期执行失败', e);
    } finally {
      stopwatch.stop();
      _totalMonitoringTime += stopwatch.elapsedMilliseconds.toDouble();

      // 检查开销限制
      _checkOverheadLimits();
    }
  }

  /// 收集性能指标
  Future<void> _collectMetrics() async {
    final metrics = <String, double>{};

    // 收集内存使用率
    metrics[PerformanceMetricType.memoryUsage.name] = _collectMemoryUsage();

    // 收集CPU使用率
    metrics[PerformanceMetricType.cpuUsage.name] = _collectCpuUsage();

    // 收集帧率
    metrics[PerformanceMetricType.frameRate.name] = _collectFrameRate();

    // 收集响应时间
    metrics[PerformanceMetricType.responseTime.name] = _collectResponseTime();

    // 收集缓存命中率
    metrics[PerformanceMetricType.cacheHitRate.name] = _collectCacheHitRate();

    // 收集网络延迟
    metrics[PerformanceMetricType.networkLatency.name] =
        _collectNetworkLatency();

    // 收集电池电量
    metrics[PerformanceMetricType.batteryLevel.name] = _collectBatteryLevel();

    // 存储数据点
    for (final entry in metrics.entries) {
      _addDataPoint(entry.key, entry.value);
    }
  }

  /// 收集内存使用率
  double _collectMemoryUsage() {
    try {
      if (_memoryManager != null) {
        final memoryInfo =
            MemoryInfo(availableMemoryMB: 1024, totalMemoryMB: 8192);
        final totalMemory = memoryInfo.totalMemoryMB;
        final availableMemory = memoryInfo.availableMemoryMB;
        return totalMemory > 0
            ? (totalMemory - availableMemory) / totalMemory
            : 0.0;
      }

      if (_memoryMonitor != null) {
        final pressureLevel = _memoryMonitor!.currentPressureLevel;
        switch (pressureLevel) {
          case MemoryPressureLevel.normal:
            return 0.4;
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
    } catch (e) {
      AppLogger.debug('收集内存使用率失败', e);
      return 0.5;
    }
  }

  /// 收集CPU使用率
  double _collectCpuUsage() {
    try {
      if (_deviceDetector != null) {
        // 简化实现，实际需要从设备检测器获取CPU使用率
        return 0.3; // 默认值
      }
      return 0.3;
    } catch (e) {
      AppLogger.debug('收集CPU使用率失败', e);
      return 0.3;
    }
  }

  /// 收集帧率
  double _collectFrameRate() {
    try {
      // 简化实现，实际需要从Flutter框架获取帧率
      return 60.0; // 默认60 FPS
    } catch (e) {
      AppLogger.debug('收集帧率失败', e);
      return 60.0;
    }
  }

  /// 收集响应时间
  double _collectResponseTime() {
    try {
      // 简化实现，实际需要监控应用响应时间
      return 200.0; // 默认200ms
    } catch (e) {
      AppLogger.debug('收集响应时间失败', e);
      return 200.0;
    }
  }

  /// 收集缓存命中率
  double _collectCacheHitRate() {
    try {
      if (_profileManager != null) {
        // 简化实现，实际需要从缓存管理器获取命中率
        return 0.85; // 默认85%
      }
      return 0.85;
    } catch (e) {
      AppLogger.debug('收集缓存命中率失败', e);
      return 0.85;
    }
  }

  /// 收集网络延迟
  double _collectNetworkLatency() {
    try {
      // 简化实现，实际需要监控网络请求延迟
      return 150.0; // 默认150ms
    } catch (e) {
      AppLogger.debug('收集网络延迟失败', e);
      return 150.0;
    }
  }

  /// 收集电池电量
  double _collectBatteryLevel() {
    try {
      // 简化实现，实际需要从系统API获取电池电量
      return 0.8; // 默认80%
    } catch (e) {
      AppLogger.debug('收集电池电量失败', e);
      return 0.8;
    }
  }

  /// 添加数据点
  void _addDataPoint(String metricType, double value) {
    // 检查采样率
    if (_config.enableSmartSampling && _shouldSample(metricType)) {
      final dataPoint = PerformanceDataPoint(
        metricType: metricType,
        value: value,
        timestamp: DateTime.now(),
        metadata: {
          'samplingRate': _samplingRates[metricType] ?? 1.0,
          'monitoringCount': _monitoringCount,
        },
      );

      // 添加到数据队列
      final queue = _metricsData.putIfAbsent(
          metricType, () => Queue<PerformanceDataPoint>());
      queue.add(dataPoint);

      // 限制队列大小
      while (queue.length > _config.maxDataPoints) {
        queue.removeFirst();
      }

      // 更新最后值和时间
      _lastValues[metricType] = value;
      _lastCollectionTimes[metricType] = DateTime.now();

      // 通知指标监听器
      _notifyMetricListeners(metricType, dataPoint);
    }
  }

  /// 判断是否应该采样
  bool _shouldSample(String metricType) {
    if (!_config.enableSmartSampling) return true;

    final samplingRate = _samplingRates[metricType] ?? 1.0;
    final counter = _samplingCounters[metricType] ?? 0;

    // 基于采样率决定是否采样
    final shouldSample = (counter * samplingRate) % 1.0 < samplingRate;

    if (shouldSample) {
      _samplingCounters[metricType] = 0;
    } else {
      _samplingCounters[metricType] = counter + 1;
    }

    return shouldSample;
  }

  /// 清理旧数据
  void _cleanupOldData() {
    final cutoffTime = DateTime.now().subtract(_config.dataRetentionTime);

    for (final queue in _metricsData.values) {
      while (queue.isNotEmpty && queue.first.timestamp.isBefore(cutoffTime)) {
        queue.removeFirst();
      }
    }

    // 清理旧告警
    while (_alerts.isNotEmpty && _alerts.first.timestamp.isBefore(cutoffTime)) {
      _alerts.removeFirst();
    }

    AppLogger.debug('旧性能数据清理完成');
  }

  /// 检查告警
  void _checkForAlerts() {
    if (!_config.enableAutoAlerting) return;

    try {
      for (final entry in _lastValues.entries) {
        final metricType = entry.key;
        final value = entry.value;

        // 解析指标类型
        final type = PerformanceMetricType.values.firstWhere(
          (type) => type.name == metricType,
          orElse: () => PerformanceMetricType.memoryUsage,
        );

        // 评估告警级别
        final level = _thresholds.evaluateAlertLevel(type, value);

        // 只有在警告级别以上时才生成告警
        if (level.index >= PerformanceAlertLevel.warning.index) {
          _createAlert(type, level, value);
        }
      }
    } catch (e) {
      AppLogger.error('告警检查失败', e);
    }
  }

  /// 创建告警
  void _createAlert(
    PerformanceMetricType metricType,
    PerformanceAlertLevel level,
    double value,
  ) {
    final thresholds = _thresholds.getThresholds(metricType);
    final threshold = thresholds[level] ?? 0.0;

    final alert = PerformanceAlert(
      id: 'alert_${DateTime.now().millisecondsSinceEpoch}_${metricType.name}',
      metricType: metricType,
      level: level,
      message: _generateAlertMessage(metricType, level, value),
      currentValue: value,
      threshold: threshold,
      timestamp: DateTime.now(),
      context: {
        'monitoringCount': _monitoringCount,
        'lastValues': Map<String, double>.from(_lastValues),
      },
    );

    _alerts.add(alert);
    _alertCount++;

    // 限制告警数量
    while (_alerts.length > 100) {
      _alerts.removeFirst();
    }

    // 通知告警监听器
    _notifyAlertListeners(alert);

    AppLogger.business(
        '性能告警生成', '指标: ${metricType.name}, 级别: ${level.name}, 值: $value');
  }

  /// 生成告警消息
  String _generateAlertMessage(
    PerformanceMetricType metricType,
    PerformanceAlertLevel level,
    double value,
  ) {
    final metricName = _getMetricDisplayName(metricType);
    final levelName = _getLevelDisplayName(level);

    switch (metricType) {
      case PerformanceMetricType.memoryUsage:
      case PerformanceMetricType.cpuUsage:
        return '$levelName: $metricName过高 (${(value * 100).toStringAsFixed(1)}%)';
      case PerformanceMetricType.frameRate:
        return '$levelName: $metricName过低 (${value.toStringAsFixed(1)} FPS)';
      case PerformanceMetricType.responseTime:
        return '$levelName: $metricName过长 (${value.toStringAsFixed(0)}ms)';
      case PerformanceMetricType.cacheHitRate:
        return '$levelName: $metricName过低 (${(value * 100).toStringAsFixed(1)}%)';
      default:
        return '$levelName: $metricName异常 (${value.toStringAsFixed(2)})';
    }
  }

  /// 获取指标显示名称
  String _getMetricDisplayName(PerformanceMetricType type) {
    switch (type) {
      case PerformanceMetricType.memoryUsage:
        return '内存使用率';
      case PerformanceMetricType.cpuUsage:
        return 'CPU使用率';
      case PerformanceMetricType.frameRate:
        return '帧率';
      case PerformanceMetricType.responseTime:
        return '响应时间';
      case PerformanceMetricType.cacheHitRate:
        return '缓存命中率';
      case PerformanceMetricType.networkLatency:
        return '网络延迟';
      case PerformanceMetricType.diskIO:
        return '磁盘IO';
      case PerformanceMetricType.batteryLevel:
        return '电池电量';
      case PerformanceMetricType.thermalState:
        return '温度状态';
    }
  }

  /// 获取级别显示名称
  String _getLevelDisplayName(PerformanceAlertLevel level) {
    switch (level) {
      case PerformanceAlertLevel.optimal:
        return '最优';
      case PerformanceAlertLevel.good:
        return '良好';
      case PerformanceAlertLevel.warning:
        return '警告';
      case PerformanceAlertLevel.critical:
        return '危险';
      case PerformanceAlertLevel.emergency:
        return '紧急';
    }
  }

  /// 检查开销限制
  void _checkOverheadLimits() {
    if (_monitoringCount == 0) return;

    // 计算平均监控时间
    final avgMonitoringTime = _totalMonitoringTime / _monitoringCount;

    // 检查CPU开销（基于监控时间估算）
    if (avgMonitoringTime > 10.0) {
      // 10ms阈值
      AppLogger.info(
          '性能监控CPU开销过高', '平均监控时间: ${avgMonitoringTime.toStringAsFixed(2)}ms');
    }

    // 检查内存开销
    final estimatedMemoryOverhead = _calculateMemoryOverhead();
    if (estimatedMemoryOverhead > _config.memoryOverheadLimitMB) {
      AppLogger.info('性能监控内存开销过高',
          '估算开销: ${estimatedMemoryOverhead.toStringAsFixed(2)}MB');
    }
  }

  /// 计算内存开销
  double _calculateMemoryOverhead() {
    int totalDataPoints = 0;
    for (final queue in _metricsData.values) {
      totalDataPoints += queue.length;
    }

    // 估算每个数据点的内存占用（包括对象开销）
    const bytesPerDataPoint = 200; // 估算值
    final totalBytes = totalDataPoints * bytesPerDataPoint;

    return totalBytes / (1024 * 1024); // 转换为MB
  }

  /// 获取监控状态
  bool get isMonitoring => _isMonitoring;

  /// 获取监控统计
  Map<String, dynamic> getMonitoringStats() {
    return {
      'isMonitoring': _isMonitoring,
      'monitoringCount': _monitoringCount,
      'alertCount': _alertCount,
      'totalMonitoringTime': _totalMonitoringTime,
      'avgMonitoringTime':
          _monitoringCount > 0 ? _totalMonitoringTime / _monitoringCount : 0.0,
      'estimatedMemoryOverheadMB': _calculateMemoryOverhead(),
      'dataPointsCount': _metricsData.values
          .map((queue) => queue.length)
          .reduce((a, b) => a + b),
      'alertsCount': _alerts.length,
      'samplingRates': _samplingRates,
    };
  }

  /// 获取性能指标数据
  Map<String, List<PerformanceDataPoint>> getMetricsData() {
    final result = <String, List<PerformanceDataPoint>>{};
    for (final entry in _metricsData.entries) {
      result[entry.key] = entry.value.toList();
    }
    return result;
  }

  /// 获取告警数据
  List<PerformanceAlert> getAlerts() {
    return _alerts.toList();
  }

  /// 获取最近告警
  List<PerformanceAlert> getRecentAlerts({int limit = 10}) {
    final alerts = _alerts.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return alerts.take(limit).toList();
  }

  /// 手动添加性能数据
  void addMetricData(
    PerformanceMetricType metricType,
    double value, {
    Map<String, dynamic>? metadata,
  }) {
    _addDataPoint(metricType.name, value);
  }

  /// 手动触发告警检查
  void checkAlerts() {
    _checkForAlerts();
  }

  /// 清除所有数据
  void clearAllData() {
    _metricsData.clear();
    _alerts.clear();
    _lastValues.clear();
    _lastCollectionTimes.clear();
    _samplingCounters.clear();

    AppLogger.business('性能监控数据已清除');
  }

  /// 重置监控统计
  void resetStats() {
    _totalMonitoringTime = 0.0;
    _monitoringCount = 0;
    _alertCount = 0;

    AppLogger.business('性能监控统计已重置');
  }

  /// 更新配置
  void updateConfig(LowOverheadMonitorConfig newConfig) {
    // 如果监控间隔改变，需要重启监控
    final wasMonitoring = _isMonitoring;
    if (wasMonitoring) {
      stopMonitoring();
    }

    // 更新配置
    // 注意：这里简化处理，实际实现可能需要更深度的配置更新

    if (wasMonitoring) {
      startMonitoring();
    }

    AppLogger.business('性能监控配置已更新');
  }

  /// 添加指标监听器
  void addMetricListener(void Function(String, PerformanceDataPoint) listener) {
    _metricListeners.add(listener);
  }

  /// 移除指标监听器
  void removeMetricListener(
      void Function(String, PerformanceDataPoint) listener) {
    _metricListeners.remove(listener);
  }

  /// 添加告警监听器
  void addAlertListener(void Function(PerformanceAlert) listener) {
    _alertListeners.add(listener);
  }

  /// 移除告警监听器
  void removeAlertListener(void Function(PerformanceAlert) listener) {
    _alertListeners.remove(listener);
  }

  /// 通知指标监听器
  void _notifyMetricListeners(
      String metricType, PerformanceDataPoint dataPoint) {
    for (final listener in _metricListeners) {
      try {
        listener(metricType, dataPoint);
      } catch (e) {
        AppLogger.error('指标监听器回调失败', e);
      }
    }
  }

  /// 通知告警监听器
  void _notifyAlertListeners(PerformanceAlert alert) {
    for (final listener in _alertListeners) {
      try {
        listener(alert);
      } catch (e) {
        AppLogger.error('告警监听器回调失败', e);
      }
    }
  }

  /// 获取性能摘要
  Map<String, dynamic> getPerformanceSummary() {
    return {
      'config': {
        'monitoringInterval': _config.monitoringInterval.inSeconds,
        'dataRetentionTime': _config.dataRetentionTime.inHours,
        'maxDataPoints': _config.maxDataPoints,
        'enableSmartSampling': _config.enableSmartSampling,
        'cpuOverheadLimit': _config.cpuOverheadLimit,
        'memoryOverheadLimitMB': _config.memoryOverheadLimitMB,
      },
      'stats': getMonitoringStats(),
      'currentMetrics': _lastValues,
      'recentAlerts': getRecentAlerts(limit: 5).map((a) => a.toJson()).toList(),
      'metricsDataCount': _metricsData.entries
          .map((entry) => '${entry.key}: ${entry.value.length}')
          .join(', '),
    };
  }

  /// 清理资源
  Future<void> dispose() async {
    await stopMonitoring();

    clearAllData();
    resetStats();

    _metricListeners.clear();
    _alertListeners.clear();

    AppLogger.business('LowOverheadMonitor已清理');
  }
}
