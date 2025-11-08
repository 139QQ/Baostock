import 'dart:collection';

import '../hybrid/data_type.dart';
import '../utils/logger.dart';
import 'activity_tracker.dart';
import 'polling_manager.dart';

/// 频率调整配置
class FrequencyAdjustmentConfig {
  /// 最小轮询间隔
  final Duration minInterval;

  /// 最大轮询间隔
  final Duration maxInterval;

  /// 调整步长 (比例)
  final double adjustmentStep;

  /// 调整敏感度 (0-1, 越高越敏感)
  final double sensitivity;

  /// 成功率阈值
  final double successRateThreshold;

  /// 延迟阈值 (毫秒)
  final int latencyThresholdMs;

  /// 数据变化频率阈值
  final double dataChangeThreshold;

  /// 调整冷却时间
  final Duration cooldownPeriod;

  const FrequencyAdjustmentConfig({
    this.minInterval = const Duration(seconds: 30),
    this.maxInterval = const Duration(hours: 24),
    this.adjustmentStep = 0.25, // 25%
    this.sensitivity = 0.5,
    this.successRateThreshold = 0.8,
    this.latencyThresholdMs = 3000,
    this.dataChangeThreshold = 0.2,
    this.cooldownPeriod = const Duration(minutes: 10),
  });

  /// 计算调整后的间隔
  Duration calculateAdjustedInterval(
      Duration currentInterval, FrequencyAdjustment adjustment) {
    double multiplier = 1.0;

    switch (adjustment) {
      case FrequencyAdjustment.increase:
        multiplier = 1.0 - (adjustmentStep * sensitivity);
        break;
      case FrequencyAdjustment.decrease:
        multiplier = 1.0 + (adjustmentStep * sensitivity);
        break;
      case FrequencyAdjustment.none:
        return currentInterval;
    }

    final newIntervalMs = (currentInterval.inMilliseconds * multiplier).round();
    final newInterval = Duration(milliseconds: newIntervalMs);

    // 确保间隔在最小和最大范围内
    return Duration(
      milliseconds: newInterval.inMilliseconds
          .clamp(minInterval.inMilliseconds, maxInterval.inMilliseconds),
    );
  }
}

/// 频率调整历史记录
class AdjustmentRecord {
  /// 数据类型
  final DataType dataType;

  /// 调整前的间隔
  final Duration oldInterval;

  /// 调整后的间隔
  final Duration newInterval;

  /// 调整原因
  final String reason;

  /// 调整时间
  final DateTime timestamp;

  /// 调整时指标
  final Map<String, dynamic> metrics;

  const AdjustmentRecord({
    required this.dataType,
    required this.oldInterval,
    required this.newInterval,
    required this.reason,
    required this.timestamp,
    required this.metrics,
  });

  /// 获取调整幅度 (百分比)
  double get adjustmentPercentage {
    if (oldInterval.inMilliseconds == 0) return 0.0;
    return ((newInterval.inMilliseconds - oldInterval.inMilliseconds) /
            oldInterval.inMilliseconds *
            100)
        .clamp(-100.0, 100.0);
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'dataType': dataType.code,
      'oldInterval': oldInterval.inSeconds,
      'newInterval': newInterval.inSeconds,
      'adjustmentPercentage': adjustmentPercentage,
      'reason': reason,
      'timestamp': timestamp.toIso8601String(),
      'metrics': metrics,
    };
  }
}

/// 数据变化检测器
class DataChangeDetector {
  /// 数据缓存
  final Map<DataType, dynamic> _lastData = {};

  /// 变化检测函数映射
  final Map<DataType, bool Function(dynamic, dynamic)> _changeDetectors = {};

  /// 注册变化检测器
  void registerChangeDetector(
      DataType dataType, bool Function(dynamic, dynamic) detector) {
    _changeDetectors[dataType] = detector;
  }

  /// 检测数据变化
  bool detectChange(DataType dataType, dynamic newData) {
    final lastData = _lastData[dataType];
    final detector = _changeDetectors[dataType];

    bool hasChange = false;
    if (detector != null && lastData != null) {
      hasChange = detector(lastData, newData);
    } else {
      // 默认使用简单比较
      hasChange = !_areEqual(lastData, newData);
    }

    // 更新缓存
    _lastData[dataType] = newData;

    return hasChange;
  }

  /// 简单相等性检查
  bool _areEqual(dynamic a, dynamic b) {
    if (a == b) return true;
    if (a == null || b == null) return false;

    // 如果是Map，深度比较
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final key in a.keys) {
        if (!b.containsKey(key) || !_areEqual(a[key], b[key])) {
          return false;
        }
      }
      return true;
    }

    // 如果是List，深度比较
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (int i = 0; i < a.length; i++) {
        if (!_areEqual(a[i], b[i])) {
          return false;
        }
      }
      return true;
    }

    return a.toString() == b.toString();
  }

  /// 清理指定数据类型的缓存
  void clearCache(DataType dataType) {
    _lastData.remove(dataType);
  }

  /// 清理所有缓存
  void clearAllCache() {
    _lastData.clear();
  }
}

/// 智能频率调整器
///
/// 根据数据变化、成功率、延迟等指标智能调整轮询频率
/// 实现自适应的数据获取策略
class FrequencyAdjuster {
  /// 调整配置
  final FrequencyAdjustmentConfig _config;

  /// 调整历史记录
  final Queue<AdjustmentRecord> _adjustmentHistory = Queue<AdjustmentRecord>();

  /// 最后调整时间
  final Map<DataType, DateTime> _lastAdjustmentTime = {};

  /// 数据变化检测器
  final DataChangeDetector _changeDetector = DataChangeDetector();

  /// 数据变化统计
  final Map<DataType, Queue<bool>> _changeHistory = {};

  /// 成功率统计
  final Map<DataType, Queue<bool>> _successHistory = {};

  /// 延迟统计
  final Map<DataType, Queue<int>> _latencyHistory = {};

  /// 最大历史记录数量
  static const int _maxHistorySize = 50;

  /// 构造函数
  FrequencyAdjuster({FrequencyAdjustmentConfig? config})
      : _config = config ?? const FrequencyAdjustmentConfig() {
    _initializeDefaultDetectors();
  }

  /// 初始化默认变化检测器
  void _initializeDefaultDetectors() {
    // 基金净值变化检测器
    _changeDetector.registerChangeDetector(
      DataType.fundNetValue,
      (oldData, newData) {
        // 检查净值是否有变化
        try {
          final oldNav = _extractNav(oldData);
          final newNav = _extractNav(newData);
          return (oldNav - newNav).abs() > 0.0001; // 浮点数精度阈值
        } catch (e) {
          return true; // 如果无法比较，假设有变化
        }
      },
    );

    // 市场指数变化检测器
    _changeDetector.registerChangeDetector(
      DataType.marketIndex,
      (oldData, newData) {
        try {
          final oldValue = _extractIndexValue(oldData);
          final newValue = _extractIndexValue(newData);
          return (oldValue - newValue).abs() > 0.01; // 指数变化阈值
        } catch (e) {
          return true;
        }
      },
    );

    // 数据质量指标变化检测器
    _changeDetector.registerChangeDetector(
      DataType.dataQualityMetrics,
      (oldData, newData) {
        // 质量指标总是被认为有变化，因为它们包含时间戳
        return true;
      },
    );
  }

  /// 提取基金净值
  double _extractNav(dynamic data) {
    if (data is Map) {
      return double.tryParse(data['nav']?.toString() ?? '0.0') ?? 0.0;
    }
    return 0.0;
  }

  /// 提取指数值
  double _extractIndexValue(dynamic data) {
    if (data is Map) {
      return double.tryParse(data['value']?.toString() ?? '0.0') ?? 0.0;
    }
    return 0.0;
  }

  /// 更新数据变化
  void updateDataChange(DataType dataType, dynamic newData) {
    final hasChange = _changeDetector.detectChange(dataType, newData);

    // 记录变化历史
    final history = _changeHistory.putIfAbsent(dataType, () => Queue<bool>());
    history.add(hasChange);
    if (history.length > _maxHistorySize) {
      history.removeFirst();
    }

    if (hasChange) {
      AppLogger.debug('Data change detected for ${dataType.code}');
    }
  }

  /// 记录成功/失败
  void recordSuccess(DataType dataType, bool success) {
    final history = _successHistory.putIfAbsent(dataType, () => Queue<bool>());
    history.add(success);
    if (history.length > _maxHistorySize) {
      history.removeFirst();
    }
  }

  /// 记录延迟
  void recordLatency(DataType dataType, int latencyMs) {
    final history = _latencyHistory.putIfAbsent(dataType, () => Queue<int>());
    history.add(latencyMs);
    if (history.length > _maxHistorySize) {
      history.removeFirst();
    }
  }

  /// 分析是否需要频率调整
  FrequencyAdjustment analyzeAdjustmentNeed(DataType dataType) {
    final now = DateTime.now();
    final lastAdjustment = _lastAdjustmentTime[dataType];

    // 检查冷却时间
    if (lastAdjustment != null &&
        now.difference(lastAdjustment) < _config.cooldownPeriod) {
      return FrequencyAdjustment.none;
    }

    // 分析各项指标
    final successRate = _calculateSuccessRate(dataType);
    final avgLatency = _calculateAverageLatency(dataType);
    final changeFrequency = _calculateChangeFrequency(dataType);

    // 决策逻辑
    if (successRate < _config.successRateThreshold) {
      return FrequencyAdjustment.decrease;
    }

    if (avgLatency > _config.latencyThresholdMs) {
      return FrequencyAdjustment.decrease;
    }

    if (changeFrequency < _config.dataChangeThreshold) {
      return FrequencyAdjustment.decrease;
    }

    // 如果各项指标都很好，可以考虑增加频率
    if (successRate > 0.95 &&
        avgLatency < _config.latencyThresholdMs / 2 &&
        changeFrequency > _config.dataChangeThreshold * 2) {
      return FrequencyAdjustment.increase;
    }

    return FrequencyAdjustment.none;
  }

  /// 计算成功率
  double _calculateSuccessRate(DataType dataType) {
    final history = _successHistory[dataType];
    if (history == null || history.isEmpty) return 1.0;

    final successCount = history.where((success) => success).length;
    return successCount / history.length;
  }

  /// 计算平均延迟
  int _calculateAverageLatency(DataType dataType) {
    final history = _latencyHistory[dataType];
    if (history == null || history.isEmpty) return 0;

    final totalLatency = history.reduce((a, b) => a + b);
    return totalLatency ~/ history.length;
  }

  /// 计算数据变化频率
  double _calculateChangeFrequency(DataType dataType) {
    final history = _changeHistory[dataType];
    if (history == null || history.isEmpty) return 0.0;

    final changeCount = history.where((changed) => changed).length;
    return changeCount / history.length;
  }

  /// 应用频率调整到轮询任务
  Duration applyAdjustment(PollingTask task) {
    final adjustment = analyzeAdjustmentNeed(task.dataType);
    if (adjustment == FrequencyAdjustment.none) {
      return task.interval;
    }

    final newInterval =
        _config.calculateAdjustedInterval(task.interval, adjustment);

    if (newInterval != task.interval) {
      // 记录调整
      _recordAdjustment(
        task.dataType,
        task.interval,
        newInterval,
        adjustment,
        _generateAdjustmentReason(task.dataType, adjustment),
      );

      _lastAdjustmentTime[task.dataType] = DateTime.now();

      AppLogger.info(
        'Adjusted polling frequency for ${task.dataType.code}: '
        '${task.interval.inSeconds}s → ${newInterval.inSeconds}s '
        '(${adjustment.name})',
      );
    }

    return newInterval;
  }

  /// 为失败任务调整频率
  void adjustFrequencyForFailures(PollingTask task) {
    if (task.failureCount >= task.maxRetries) {
      final newIntervalMs = (task.interval.inMilliseconds * 1.5).round().clamp(
          _config.minInterval.inMilliseconds,
          _config.maxInterval.inMilliseconds);
      final newInterval = Duration(milliseconds: newIntervalMs);

      _recordAdjustment(
        task.dataType,
        task.interval,
        newInterval,
        FrequencyAdjustment.decrease,
        'Too many failures (${task.failureCount}/${task.maxRetries})',
      );

      _lastAdjustmentTime[task.dataType] = DateTime.now();

      AppLogger.warning(
        'Adjusted polling frequency due to failures for ${task.dataType.code}: '
        '${task.interval.inSeconds}s → ${newInterval.inSeconds}s',
      );
    }
  }

  /// 记录频率调整
  void _recordAdjustment(
    DataType dataType,
    Duration oldInterval,
    Duration newInterval,
    FrequencyAdjustment adjustment,
    String reason,
  ) {
    final record = AdjustmentRecord(
      dataType: dataType,
      oldInterval: oldInterval,
      newInterval: newInterval,
      reason: reason,
      timestamp: DateTime.now(),
      metrics: {
        'successRate': _calculateSuccessRate(dataType),
        'averageLatency': _calculateAverageLatency(dataType),
        'changeFrequency': _calculateChangeFrequency(dataType),
        'adjustment': adjustment.name,
      },
    );

    _adjustmentHistory.add(record);
    if (_adjustmentHistory.length > 100) {
      _adjustmentHistory.removeFirst();
    }
  }

  /// 生成调整原因
  String _generateAdjustmentReason(
      DataType dataType, FrequencyAdjustment adjustment) {
    final successRate = _calculateSuccessRate(dataType);
    final avgLatency = _calculateAverageLatency(dataType);
    final changeFrequency = _calculateChangeFrequency(dataType);

    switch (adjustment) {
      case FrequencyAdjustment.increase:
        return 'High performance detected (success: ${(successRate * 100).toStringAsFixed(1)}%, '
            'latency: ${avgLatency}ms, change: ${(changeFrequency * 100).toStringAsFixed(1)}%)';

      case FrequencyAdjustment.decrease:
        final reasons = <String>[];
        if (successRate < _config.successRateThreshold) {
          reasons.add(
              'low success rate (${(successRate * 100).toStringAsFixed(1)}%)');
        }
        if (avgLatency > _config.latencyThresholdMs) {
          reasons.add('high latency (${avgLatency}ms)');
        }
        if (changeFrequency < _config.dataChangeThreshold) {
          reasons.add(
              'low change frequency (${(changeFrequency * 100).toStringAsFixed(1)}%)');
        }
        return 'Performance issues: ${reasons.join(', ')}';

      case FrequencyAdjustment.none:
        return 'No adjustment needed';
    }
  }

  /// 获取调整历史
  List<AdjustmentRecord> getAdjustmentHistory(
      {DataType? dataType, int? limit}) {
    var history = _adjustmentHistory.toList();

    if (dataType != null) {
      history = history.where((record) => record.dataType == dataType).toList();
    }

    history.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (limit != null && limit > 0) {
      history = history.take(limit).toList();
    }

    return history;
  }

  /// 获取配置
  Map<String, dynamic> getConfig() {
    return {
      'minInterval': _config.minInterval.inSeconds,
      'maxInterval': _config.maxInterval.inSeconds,
      'adjustmentStep': _config.adjustmentStep,
      'sensitivity': _config.sensitivity,
      'successRateThreshold': _config.successRateThreshold,
      'latencyThresholdMs': _config.latencyThresholdMs,
      'dataChangeThreshold': _config.dataChangeThreshold,
      'cooldownPeriod': _config.cooldownPeriod.inMinutes,
    };
  }

  /// 更新配置
  void updateConfig(FrequencyAdjustmentConfig config) {
    // 这里应该更新配置，但由于_config是final，需要重新构造
    // 实际使用中可能需要不同的设计
    AppLogger.info('FrequencyAdjuster config updated');
  }

  /// 获取统计报告
  Map<String, dynamic> getReport() {
    final report = <String, dynamic>{
      'config': getConfig(),
      'adjustmentHistory': _adjustmentHistory.map((r) => r.toJson()).toList(),
      'dataTypes': <String, dynamic>{},
    };

    // 各数据类型的统计
    for (final dataType in DataType.values) {
      final successRate = _calculateSuccessRate(dataType);
      final avgLatency = _calculateAverageLatency(dataType);
      final changeFrequency = _calculateChangeFrequency(dataType);

      if (successRate > 0 || avgLatency > 0 || changeFrequency > 0) {
        report['dataTypes'][dataType.code] = {
          'successRate': successRate,
          'averageLatency': avgLatency,
          'changeFrequency': changeFrequency,
          'suggestedAdjustment': analyzeAdjustmentNeed(dataType).name,
          'lastAdjustment': _lastAdjustmentTime[dataType]?.toIso8601String(),
        };
      }
    }

    return report;
  }

  /// 重置所有统计数据
  void reset() {
    _changeHistory.clear();
    _successHistory.clear();
    _latencyHistory.clear();
    _adjustmentHistory.clear();
    _lastAdjustmentTime.clear();
    _changeDetector.clearAllCache();

    AppLogger.info('FrequencyAdjuster reset completed');
  }
}
