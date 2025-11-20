import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../managers/advanced_memory_manager.dart';
import '../../utils/logger.dart';

/// 内存压力预警级别
enum MemoryPressureAlertLevel {
  info, // 信息 (60-70%)
  warning, // 警告 (70-80%)
  critical, // 危险 (80-90%)
  emergency, // 紧急 (>90%)
}

/// 内存压力预警
class MemoryPressureAlert {
  final MemoryPressureAlertLevel level;
  final double memoryUsagePercent;
  final int availableMemoryMB;
  final int usedMemoryMB;
  final DateTime timestamp;
  final String message;
  final Map<String, dynamic> details;
  final List<String> recommendations;

  MemoryPressureAlert({
    required this.level,
    required this.memoryUsagePercent,
    required this.availableMemoryMB,
    required this.usedMemoryMB,
    required this.timestamp,
    required this.message,
    required this.details,
    this.recommendations = const [],
  });
}

/// 内存压力趋势分析
class MemoryPressureTrend {
  final List<double> memoryUsageHistory;
  final List<DateTime> timestamps;
  final double trend; // 正值表示上升趋势，负值表示下降趋势
  final MemoryPressureAlertLevel predictedNextLevel;
  final double confidence; // 预测置信度 0-1

  MemoryPressureTrend({
    required this.memoryUsageHistory,
    required this.timestamps,
    required this.trend,
    required this.predictedNextLevel,
    required this.confidence,
  });
}

/// 内存压力监控器配置
class MemoryPressureMonitorConfig {
  /// 监控检查间隔
  final Duration monitoringInterval;

  /// 历史数据保留时间
  final Duration historyRetentionPeriod;

  /// 趋势分析所需的最少数据点
  final int minDataPointsForTrend;

  /// 预警冷却时间（同一级别预警的最小间隔）
  final Duration alertCooldown;

  /// 自动触发内存优化的阈值
  final double autoOptimizationThreshold;

  /// 预警准确性目标
  final double alertAccuracyTarget;

  const MemoryPressureMonitorConfig({
    this.monitoringInterval = const Duration(seconds: 5),
    this.historyRetentionPeriod = const Duration(hours: 1),
    this.minDataPointsForTrend = 12, // 12个数据点用于趋势分析
    this.alertCooldown = const Duration(minutes: 2),
    this.autoOptimizationThreshold = 0.85,
    this.alertAccuracyTarget = 0.90,
  });
}

/// 内存压力监控器
///
/// 实现内存压力检测和预警系统
class MemoryPressureMonitor {
  final MemoryPressureMonitorConfig _config;
  final AdvancedMemoryManager _memoryManager;

  final StreamController<MemoryPressureAlert> _alertController =
      StreamController<MemoryPressureAlert>.broadcast();

  Timer? _monitoringTimer;
  final List<double> _memoryUsageHistory = [];
  final List<DateTime> _timestamps = [];
  final Map<MemoryPressureAlertLevel, DateTime> _lastAlertTimes = {};

  final List<MemoryPressureAlert> _alertHistory = [];
  final List<MemoryPressureTrend> _trendHistory = [];

  int _totalAlerts = 0;
  int _accuratePredictions = 0;

  MemoryPressureMonitor({
    required AdvancedMemoryManager memoryManager,
    MemoryPressureMonitorConfig? config,
  })  : _memoryManager = memoryManager,
        _config = config ?? MemoryPressureMonitorConfig();

  /// 内存压力预警流
  Stream<MemoryPressureAlert> get alertStream => _alertController.stream;

  /// 当前内存压力级别
  MemoryPressureLevel get currentPressureLevel =>
      _memoryManager.currentPressureLevel;

  /// 启动内存压力监控
  Future<void> start() async {
    AppLogger.business('启动MemoryPressureMonitor');

    // 初始数据收集
    await _collectMemoryData();

    // 启动定期监控
    _startMonitoring();
  }

  /// 停止内存压力监控
  Future<void> stop() async {
    AppLogger.business('停止MemoryPressureMonitor');

    _monitoringTimer?.cancel();
    _monitoringTimer = null;

    await _alertController.close();
  }

  /// 手动触发内存压力检测
  Future<MemoryPressureAlert?> checkMemoryPressure() async {
    await _collectMemoryData();
    return await _analyzeAndAlert();
  }

  /// 获取当前内存压力级别
  MemoryPressureAlertLevel getCurrentPressureLevel() {
    if (_memoryUsageHistory.isEmpty) {
      return MemoryPressureAlertLevel.info;
    }

    final currentUsage = _memoryUsageHistory.last;
    return _getAlertLevel(currentUsage);
  }

  /// 获取内存压力趋势
  MemoryPressureTrend? getCurrentTrend() {
    if (_memoryUsageHistory.length < _config.minDataPointsForTrend) {
      return null;
    }

    return _analyzeTrend();
  }

  /// 获取监控统计信息
  Map<String, dynamic> getMonitoringStats() {
    return {
      'totalAlerts': _totalAlerts,
      'accuratePredictions': _accuratePredictions,
      'accuracyRate':
          _totalAlerts > 0 ? _accuratePredictions / _totalAlerts : 0.0,
      'dataPointsCollected': _memoryUsageHistory.length,
      'historyRetention': _getHistoryRetentionStats(),
      'recentAlerts': _alertHistory
          .where((alert) =>
              DateTime.now().difference(alert.timestamp).inMinutes <= 30)
          .length,
      'currentPressureLevel': getCurrentPressureLevel().toString(),
      'lastAnalysisTime':
          _timestamps.isNotEmpty ? _timestamps.last.toIso8601String() : null,
    };
  }

  /// 启动监控
  void _startMonitoring() {
    _monitoringTimer = Timer.periodic(
      _config.monitoringInterval,
      (_) => _performMonitoringCycle(),
    );
  }

  /// 执行监控周期
  Future<void> _performMonitoringCycle() async {
    try {
      await _collectMemoryData();
      await _analyzeAndAlert();
      await _cleanupOldData();
    } catch (e) {
      AppLogger.error('内存压力监控周期失败', e);
    }
  }

  /// 收集内存数据
  Future<void> _collectMemoryData() async {
    final memoryInfo = await _getMemoryInfo();
    final used = memoryInfo['used'] ?? 0;
    final total = memoryInfo['total'] ?? 1;
    final usagePercent = used / total;

    _memoryUsageHistory.add(usagePercent);
    _timestamps.add(DateTime.now());

    // 限制历史数据长度
    final maxDataPoints = (_config.historyRetentionPeriod.inMilliseconds /
            _config.monitoringInterval.inMilliseconds)
        .ceil();

    while (_memoryUsageHistory.length > maxDataPoints) {
      _memoryUsageHistory.removeAt(0);
      _timestamps.removeAt(0);
    }
  }

  /// 分析并发送预警
  Future<MemoryPressureAlert?> _analyzeAndAlert() async {
    if (_memoryUsageHistory.isEmpty) return null;

    final currentUsage = _memoryUsageHistory.last;
    final alertLevel = _getAlertLevel(currentUsage);

    // 检查预警冷却时间
    if (!_shouldSendAlert(alertLevel)) {
      return null;
    }

    // 生成预警
    final alert = await _generateAlert(alertLevel, currentUsage);

    // 发送预警
    _alertController.add(alert);
    _alertHistory.add(alert);
    _lastAlertTimes[alertLevel] = DateTime.now();
    _totalAlerts++;

    AppLogger.warn(alert.message);

    // 自动触发优化
    if (currentUsage >= _config.autoOptimizationThreshold) {
      await _triggerAutoOptimization(alert);
    }

    return alert;
  }

  /// 判断是否应该发送预警
  bool _shouldSendAlert(MemoryPressureAlertLevel level) {
    final lastAlertTime = _lastAlertTimes[level];
    if (lastAlertTime == null) return true;

    final timeSinceLastAlert = DateTime.now().difference(lastAlertTime);
    return timeSinceLastAlert >= _config.alertCooldown;
  }

  /// 生成预警
  Future<MemoryPressureAlert> _generateAlert(
    MemoryPressureAlertLevel level,
    double memoryUsagePercent,
  ) async {
    final memoryInfo = await _getMemoryInfo();
    final trend = _analyzeTrend();

    return MemoryPressureAlert(
      level: level,
      memoryUsagePercent: memoryUsagePercent * 100,
      availableMemoryMB:
          ((memoryInfo['total']! - memoryInfo['used']!) ~/ (1024 * 1024)),
      usedMemoryMB: (memoryInfo['used']! ~/ (1024 * 1024)),
      timestamp: DateTime.now(),
      message: _generateAlertMessage(level, memoryUsagePercent, trend),
      details: await _generateAlertDetails(memoryUsagePercent, trend),
      recommendations:
          _generateRecommendations(level, memoryUsagePercent, trend),
    );
  }

  /// 生成预警消息
  String _generateAlertMessage(
    MemoryPressureAlertLevel level,
    double memoryUsagePercent,
    MemoryPressureTrend? trend,
  ) {
    final usageText = (memoryUsagePercent * 100).toStringAsFixed(1);
    final trendText =
        trend != null ? (trend.trend > 0 ? ' (上升中)' : ' (下降中)') : '';

    switch (level) {
      case MemoryPressureAlertLevel.info:
        return '内存使用信息: ${usageText}%$trendText';
      case MemoryPressureAlertLevel.warning:
        return '内存使用警告: ${usageText}%$trendText - 建议清理缓存';
      case MemoryPressureAlertLevel.critical:
        return '内存使用危险: ${usageText}%$trendText - 正在自动优化';
      case MemoryPressureAlertLevel.emergency:
        return '内存使用紧急: ${usageText}%$trendText - 强制清理中';
    }
  }

  /// 生成预警详情
  Future<Map<String, dynamic>> _generateAlertDetails(
    double memoryUsagePercent,
    MemoryPressureTrend? trend,
  ) async {
    return {
      'memoryUsagePercent': memoryUsagePercent * 100,
      'trend': trend?.trend,
      'predictedNextLevel': trend?.predictedNextLevel.toString(),
      'confidence': trend?.confidence,
      'dataPointsAnalyzed': _memoryUsageHistory.length,
      'monitoringDuration': _getMonitoringDuration(),
      'systemInfo': await _getSystemInfo(),
    };
  }

  /// 生成建议
  List<String> _generateRecommendations(
    MemoryPressureAlertLevel level,
    double memoryUsagePercent,
    MemoryPressureTrend? trend,
  ) {
    final recommendations = <String>[];

    switch (level) {
      case MemoryPressureAlertLevel.info:
        recommendations.add('继续监控内存使用情况');
        break;

      case MemoryPressureAlertLevel.warning:
        recommendations.add('清理不必要的缓存');
        recommendations.add('关闭未使用的功能');
        if (trend != null && trend.trend > 0) {
          recommendations.add('注意内存使用上升趋势');
        }
        break;

      case MemoryPressureAlertLevel.critical:
        recommendations.add('立即清理所有缓存');
        recommendations.add('强制垃圾回收');
        recommendations.add('考虑降低缓存大小');
        recommendations.add('暂停非关键功能');
        break;

      case MemoryPressureAlertLevel.emergency:
        recommendations.add('强制清理所有内存');
        recommendations.add('立即停止非关键操作');
        recommendations.add('重启应用（如果持续）');
        recommendations.add('检查内存泄漏');
        break;
    }

    return recommendations;
  }

  /// 分析内存压力趋势
  MemoryPressureTrend? _analyzeTrend() {
    if (_memoryUsageHistory.length < _config.minDataPointsForTrend) {
      return null;
    }

    // 使用线性回归分析趋势
    final n = _memoryUsageHistory.length;
    final xValues = List.generate(n, (i) => i.toDouble());
    final yValues = _memoryUsageHistory;

    // 计算线性回归斜率
    final sumX = xValues.reduce((a, b) => a + b);
    final sumY = yValues.reduce((a, b) => a + b);
    final sumXY = List.generate(n, (i) => xValues[i] * yValues[i])
        .reduce((a, b) => a + b);
    final sumXX = List.generate(n, (i) => xValues[i] * xValues[i])
        .reduce((a, b) => a + b);

    final slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);

    // 预测下一个值
    final currentValue = yValues.last;
    final predictedValue = currentValue + slope;

    final predictedLevel = _getAlertLevel(predictedValue);

    // 计算置信度（基于历史准确性）
    final confidence = _calculatePredictionConfidence();

    return MemoryPressureTrend(
      memoryUsageHistory: List.from(yValues),
      timestamps: List.from(_timestamps),
      trend: slope,
      predictedNextLevel: predictedLevel,
      confidence: confidence,
    );
  }

  /// 计算预测置信度
  double _calculatePredictionConfidence() {
    if (_alertHistory.length < 10) return 0.5;

    // 简化的置信度计算，基于历史预警的准确性
    return (_accuratePredictions / _totalAlerts).clamp(0.0, 1.0);
  }

  /// 获取预警级别
  MemoryPressureAlertLevel _getAlertLevel(double memoryUsagePercent) {
    if (memoryUsagePercent >= 0.90) {
      return MemoryPressureAlertLevel.emergency;
    } else if (memoryUsagePercent >= 0.80) {
      return MemoryPressureAlertLevel.critical;
    } else if (memoryUsagePercent >= 0.70) {
      return MemoryPressureAlertLevel.warning;
    } else {
      return MemoryPressureAlertLevel.info;
    }
  }

  /// 触发自动优化
  Future<void> _triggerAutoOptimization(MemoryPressureAlert alert) async {
    AppLogger.business('触发自动内存优化', '级别: ${alert.level}');

    try {
      switch (alert.level) {
        case MemoryPressureAlertLevel.warning:
          await _memoryManager.performLRUEviction();
          break;

        case MemoryPressureAlertLevel.critical:
          await _memoryManager.performLRUEviction(threshold: 0.6);
          await _memoryManager.forceGarbageCollection();
          break;

        case MemoryPressureAlertLevel.emergency:
          _memoryManager.clear();
          await _memoryManager.forceGarbageCollection();
          break;

        case MemoryPressureAlertLevel.info:
          // 不执行自动操作
          break;
      }
    } catch (e) {
      AppLogger.error('自动内存优化失败', e);
    }
  }

  /// 清理旧数据
  Future<void> _cleanupOldData() async {
    final cutoffTime = DateTime.now().subtract(_config.historyRetentionPeriod);

    // 找到需要保留的起始索引
    int startIndex = 0;
    for (int i = 0; i < _timestamps.length; i++) {
      if (!_timestamps[i].isBefore(cutoffTime)) {
        startIndex = i;
        break;
      }
      startIndex = i + 1; // 如果所有时间都早于截止时间
    }

    // 移除旧数据
    if (startIndex > 0) {
      _memoryUsageHistory.removeRange(0, startIndex);
      _timestamps.removeRange(0, startIndex);
    }

    _alertHistory.removeWhere((alert) => alert.timestamp.isBefore(cutoffTime));
    _trendHistory
        .removeWhere((trend) => trend.timestamps.last.isBefore(cutoffTime));
  }

  /// 获取内存信息
  Future<Map<String, int>> _getMemoryInfo() async {
    try {
      if (Platform.isIOS || Platform.isAndroid) {
        final result = await SystemChannels.platform.invokeMethod('System.gc');
        return {
          'total': 1024 * 1024 * 1024, // 1GB 默认值
          'used': result['memory'] ?? 512 * 1024 * 1024,
        };
      } else {
        return {
          'total': 1024 * 1024 * 1024,
          'used': 512 * 1024 * 1024,
        };
      }
    } catch (e) {
      return {
        'total': 1024 * 1024 * 1024,
        'used': 512 * 1024 * 1024,
      };
    }
  }

  /// 获取系统信息
  Future<Map<String, dynamic>> _getSystemInfo() async {
    return {
      'platform': Platform.operatingSystem,
      'isDebugMode': kDebugMode,
      'currentTimestamp': DateTime.now().toIso8601String(),
    };
  }

  /// 获取监控持续时间
  Duration _getMonitoringDuration() {
    if (_timestamps.isEmpty) return Duration.zero;
    return DateTime.now().difference(_timestamps.first);
  }

  /// 获取历史数据保留统计
  Map<String, dynamic> _getHistoryRetentionStats() {
    return {
      'maxDataPoints': (_config.historyRetentionPeriod.inMilliseconds /
              _config.monitoringInterval.inMilliseconds)
          .ceil(),
      'currentDataPoints': _memoryUsageHistory.length,
      'retentionRate': _memoryUsageHistory.isEmpty
          ? 1.0
          : _memoryUsageHistory.length /
              ((_config.historyRetentionPeriod.inMilliseconds /
                      _config.monitoringInterval.inMilliseconds)
                  .ceil()),
    };
  }
}
