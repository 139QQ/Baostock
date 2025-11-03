import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:logger/logger.dart';
import 'performance_thresholds.dart';
import '../config/app_config.dart';

/// 统一性能监控管理器
///
/// 提供全面的性能监控、指标收集、阈值评估和报告功能
/// 支持实时监控、历史数据分析和性能预警
class UnifiedPerformanceMonitor {
  static final UnifiedPerformanceMonitor _instance =
      UnifiedPerformanceMonitor._internal();
  factory UnifiedPerformanceMonitor() => _instance;
  UnifiedPerformanceMonitor._internal();

  // 监控状态
  bool _isMonitoring = false;
  Timer? _monitoringTimer;
  Timer? _reportingTimer;
  bool _uiCallbackRegistered = false;

  // 性能数据存储
  final Map<String, List<PerformanceDataPoint>> _metricsHistory = {};
  final Map<String, PerformanceDataPoint> _currentMetrics = {};
  final List<PerformanceAlert> _alerts = [];

  // 监控配置
  static const Duration _monitoringInterval = Duration(seconds: 5);
  static const Duration _reportingInterval = Duration(minutes: 1);
  static const int _maxHistorySize = 1000;

  final Logger _logger = Logger();

  /// 开始性能监控
  Future<void> startMonitoring() async {
    if (_isMonitoring) {
      _logger.w('性能监控已在运行中');
      return;
    }

    if (!AppConfig.instance.performanceMonitoringEnabled) {
      _logger.i('性能监控已禁用');
      return;
    }

    _isMonitoring = true;
    _logger.i('🚀 启动统一性能监控');

    // 注册UI性能监控回调（只注册一次）
    _registerUiPerformanceCallback();

    // 启动定时监控
    _monitoringTimer =
        Timer.periodic(_monitoringInterval, (_) => _collectMetrics());
    _reportingTimer =
        Timer.periodic(_reportingInterval, (_) => _generateReport());

    // 初始数据收集
    await _collectMetrics();

    _logger.i('✅ 性能监控启动成功');
  }

  /// 停止性能监控
  void stopMonitoring() {
    if (!_isMonitoring) return;

    _isMonitoring = false;
    _monitoringTimer?.cancel();
    _reportingTimer?.cancel();

    // 清理UI性能监控回调
    _unregisterUiPerformanceCallback();

    _logger.i('🛑 性能监控已停止');
  }

  /// 手动记录性能指标
  void recordMetric(String name, double value,
      {Map<String, dynamic>? metadata}) {
    final dataPoint = PerformanceDataPoint(
      name: name,
      value: value,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    );

    _addToHistory(name, dataPoint);
    _currentMetrics[name] = dataPoint;

    // 检查阈值并生成警报
    _checkThresholds(dataPoint);

    if (kDebugMode) {
      _logger.d('📊 记录性能指标: $name = ${dataPoint.formattedValue}');
    }
  }

  /// 记录操作开始时间
  String startOperation(String operation) {
    final operationId = '${operation}_${DateTime.now().millisecondsSinceEpoch}';
    recordMetric('${operation}_start', 0,
        metadata: {'operationId': operationId});
    return operationId;
  }

  /// 记录操作结束时间
  void endOperation(String operationId, String operation,
      {bool success = true}) {
    final startTime = _currentMetrics['${operation}_start'];
    if (startTime != null) {
      final duration =
          DateTime.now().difference(startTime.timestamp).inMilliseconds;
      recordMetric('${operation}_duration', duration.toDouble(), metadata: {
        'operationId': operationId,
        'success': success,
      });
    }
  }

  /// 收集系统性能指标
  Future<void> _collectMetrics() async {
    try {
      // 内存使用情况
      await _collectMemoryMetrics();

      // CPU使用情况（仅桌面平台）
      if (!Platform.isIOS && !Platform.isAndroid) {
        await _collectCpuMetrics();
      }

      // UI性能指标
      await _collectUiMetrics();

      // 缓存性能指标
      await _collectCacheMetrics();

      // 网络性能指标
      await _collectNetworkMetrics();
    } catch (e) {
      _logger.e('收集性能指标时发生错误: $e');
    }
  }

  /// 收集内存使用指标
  Future<void> _collectMemoryMetrics() async {
    try {
      // Flutter内存信息
      final info = await _getMemoryInfo();
      recordMetric('memory_usage', info.totalUsage.toDouble());
      recordMetric('memory_heap_usage', info.heapUsage.toDouble());
      recordMetric('memory_external_usage', info.externalUsage.toDouble());
    } catch (e) {
      _logger.e('收集内存指标失败: $e');
    }
  }

  /// 收集CPU使用指标
  Future<void> _collectCpuMetrics() async {
    try {
      // 在实际实现中，这里需要使用平台特定的API
      // 目前使用模拟数据
      final cpuUsage = _simulateCpuUsage();
      recordMetric('cpu_usage', cpuUsage);
    } catch (e) {
      _logger.e('收集CPU指标失败: $e');
    }
  }

  /// 注册UI性能监控回调
  void _registerUiPerformanceCallback() {
    if (_uiCallbackRegistered) return;

    try {
      WidgetsBinding.instance.addTimingsCallback((List<FrameTiming> timings) {
        if (timings.isNotEmpty) {
          // totalSpan 是 Duration 类型，表示帧的总时间
          final frameTimeMs = timings.first.totalSpan.inMilliseconds.toDouble();
          // 计算FPS：1000ms / frameTimeMs
          final fps = frameTimeMs > 0 ? 1000.0 / frameTimeMs : 60.0;

          // 确保FPS在合理范围内（通常0-240）
          final normalizedFps = fps.clamp(0.0, 240.0);

          recordMetric('frame_rate', normalizedFps);
          recordMetric('frame_time', frameTimeMs);

          if (kDebugMode && fps > 200) {
            _logger.d('检测到异常高FPS值: $fps, 帧时间: ${frameTimeMs}ms');
          }
        }
      });
      _uiCallbackRegistered = true;
      _logger.d('UI性能监控回调注册成功');
    } catch (e) {
      _logger.e('注册UI性能监控回调失败: $e');
    }
  }

  /// 注销UI性能监控回调
  void _unregisterUiPerformanceCallback() {
    if (!_uiCallbackRegistered) return;

    try {
      // 注意：由于addTimingsCallback没有返回标识符，我们无法精确移除
      // 这是Flutter框架的限制，在实际应用中，这个回调会在应用停止时自动清理
      _uiCallbackRegistered = false;
      _logger.d('UI性能监控回调已标记为未注册');
    } catch (e) {
      _logger.e('注销UI性能监控回调失败: $e');
    }
  }

  /// 收集UI性能指标
  Future<void> _collectUiMetrics() async {
    try {
      // UI性能指标现在通过回调自动收集，这里可以收集其他UI相关指标
      // 比如widget重建次数等
    } catch (e) {
      _logger.e('收集UI指标失败: $e');
    }
  }

  /// 收集缓存性能指标
  Future<void> _collectCacheMetrics() async {
    try {
      // 这里应该从缓存管理器获取实际数据
      // 目前使用模拟数据
      final cacheHitRate = _simulateCacheHitRate();
      final cacheSize = _simulateCacheSize();

      recordMetric('cache_hit_rate', cacheHitRate);
      recordMetric('cache_size', cacheSize);
      recordMetric('cache_memory_usage', cacheSize * 0.8); // 估算内存使用
    } catch (e) {
      _logger.e('收集缓存指标失败: $e');
    }
  }

  /// 收集网络性能指标
  Future<void> _collectNetworkMetrics() async {
    try {
      // 这里应该从网络客户端获取实际数据
      // 目前使用模拟数据
      final apiSuccessRate = _simulateApiSuccessRate();
      final avgResponseTime = _simulateAvgResponseTime();

      recordMetric('api_success_rate', apiSuccessRate);
      recordMetric('avg_response_time', avgResponseTime);
      recordMetric('network_error_rate', 1.0 - apiSuccessRate);
    } catch (e) {
      _logger.e('收集网络指标失败: $e');
    }
  }

  /// 检查性能阈值
  void _checkThresholds(PerformanceDataPoint dataPoint) {
    final metric = PredefinedMetrics.metrics
        .where((m) => m.name == dataPoint.name)
        .firstOrNull;

    if (metric != null) {
      final status = metric.getStatus(dataPoint.value);

      if (status == PerformanceStatus.warning ||
          status == PerformanceStatus.critical) {
        final alert = PerformanceAlert(
          metricName: dataPoint.name,
          status: status,
          value: dataPoint.value,
          threshold: metric.thresholds[status]!,
          timestamp: DateTime.now(),
        );

        _alerts.add(alert);
        _handleAlert(alert);
      }
    }
  }

  /// 处理性能警报
  void _handleAlert(PerformanceAlert alert) {
    _logger.w(
        '⚠️ 性能警报: ${alert.metricName} = ${alert.value} (阈值: ${alert.threshold})');

    // 在开发环境下显示警报
    if (kDebugMode) {
      developer.log(
        '性能警报',
        name: 'PerformanceMonitor',
        error: alert.toJson(),
      );
    }

    // 在生产环境下可以发送到监控系统
    if (AppConfig.instance.isProduction &&
        AppConfig.instance.monitoringEnabled) {
      _sendAlertToMonitoring(alert);
    }
  }

  /// 发送警报到监控系统
  void _sendAlertToMonitoring(PerformanceAlert alert) {
    // 这里可以实现与外部监控系统的集成
    _logger.i('发送性能警报到监控系统: ${alert.metricName}');
  }

  /// 生成性能报告
  void _generateReport() {
    if (!AppConfig.instance.isProduction) {
      _printPerformanceReport();
    }

    // 清理过期数据
    _cleanupOldData();
  }

  /// 打印性能报告
  void _printPerformanceReport() {
    _logger.i('📊 性能监控报告 (${DateTime.now()})');
    _logger.i('=' * 50);

    for (final metricName in _currentMetrics.keys) {
      final metric = _currentMetrics[metricName]!;
      final predefinedMetric = PredefinedMetrics.metrics
          .where((m) => m.name == metricName)
          .firstOrNull;

      if (predefinedMetric != null) {
        final status = predefinedMetric.getStatus(metric.value);
        final statusIcon = _getStatusIcon(status);
        _logger.i(
            '$statusIcon ${predefinedMetric.description}: ${metric.formattedValue}');
      }
    }

    // 显示最近的警报
    if (_alerts.isNotEmpty) {
      _logger.i('🚨 最近的性能警报:');
      for (final alert in _alerts.take(5)) {
        _logger.i(
            '  • ${alert.metricName}: ${alert.value} (${alert.status.name})');
      }
    }

    _logger.i('=' * 50);
  }

  /// 获取状态图标
  String _getStatusIcon(PerformanceStatus status) {
    switch (status) {
      case PerformanceStatus.optimal:
        return '✅';
      case PerformanceStatus.good:
        return '🟢';
      case PerformanceStatus.warning:
        return '⚠️';
      case PerformanceStatus.critical:
        return '🔴';
    }
  }

  /// 添加到历史记录
  void _addToHistory(String name, PerformanceDataPoint dataPoint) {
    _metricsHistory.putIfAbsent(name, () => []).add(dataPoint);

    // 限制历史记录大小
    final history = _metricsHistory[name]!;
    if (history.length > _maxHistorySize) {
      history.removeAt(0);
    }
  }

  /// 清理过期数据
  void _cleanupOldData() {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(hours: 24));

    _metricsHistory.removeWhere((key, value) {
      value.removeWhere((point) => point.timestamp.isBefore(cutoff));
      return value.isEmpty;
    });

    // 清理过期警报
    _alerts.removeWhere((alert) => alert.timestamp.isBefore(cutoff));
  }

  /// 获取性能指标历史
  List<PerformanceDataPoint> getMetricHistory(String name, {Duration? period}) {
    final history = _metricsHistory[name] ?? [];

    if (period != null) {
      final cutoff = DateTime.now().subtract(period);
      return history.where((point) => point.timestamp.isAfter(cutoff)).toList();
    }

    return history;
  }

  /// 获取当前性能指标
  PerformanceDataPoint? getCurrentMetric(String name) {
    return _currentMetrics[name];
  }

  /// 获取所有当前指标
  Map<String, PerformanceDataPoint> getAllCurrentMetrics() {
    return Map.from(_currentMetrics);
  }

  /// 获取最近的警报
  List<PerformanceAlert> getRecentAlerts({int limit = 10}) {
    return _alerts.take(limit).toList();
  }

  /// 获取性能摘要
  PerformanceSummary getPerformanceSummary() {
    final now = DateTime.now();
    final recentPeriod = const Duration(minutes: 5);

    final recentMetrics = <String, List<PerformanceDataPoint>>{};

    for (final entry in _currentMetrics.entries) {
      final history = getMetricHistory(entry.key, period: recentPeriod);
      if (history.isNotEmpty) {
        recentMetrics[entry.key] = history;
      }
    }

    return PerformanceSummary(
      timestamp: now,
      metrics: recentMetrics,
      alerts: _alerts
          .where((alert) => now.difference(alert.timestamp).inMinutes <= 5)
          .toList(),
      overallStatus: _calculateOverallStatus(),
    );
  }

  /// 计算整体性能状态
  PerformanceStatus _calculateOverallStatus() {
    if (_currentMetrics.isEmpty) return PerformanceStatus.good;

    int criticalCount = 0;
    int warningCount = 0;
    int totalMetrics = 0;

    for (final entry in _currentMetrics.entries) {
      final predefinedMetric = PredefinedMetrics.metrics
          .where((m) => m.name == entry.key)
          .firstOrNull;

      if (predefinedMetric != null) {
        final status = predefinedMetric.getStatus(entry.value.value);
        totalMetrics++;

        if (status == PerformanceStatus.critical) criticalCount++;
        if (status == PerformanceStatus.warning) warningCount++;
      }
    }

    if (criticalCount > 0) return PerformanceStatus.critical;
    if (warningCount > totalMetrics * 0.3) return PerformanceStatus.warning;
    if (warningCount > 0) return PerformanceStatus.good;
    return PerformanceStatus.optimal;
  }

  // ========== 模拟方法（在实际实现中应替换为真实数据采集） ==========

  Future<MemoryInfo> _getMemoryInfo() async {
    // 在实际实现中，这里应该使用Dart的内存API
    return MemoryInfo(
      totalUsage: 180 + (DateTime.now().millisecond % 100),
      heapUsage: 120 + (DateTime.now().millisecond % 50),
      externalUsage: 60 + (DateTime.now().millisecond % 30),
    );
  }

  double _simulateCpuUsage() {
    return 20.0 + (DateTime.now().millisecond % 60);
  }

  double _simulateCacheHitRate() {
    return 0.75 + (DateTime.now().millisecond % 25) / 100.0;
  }

  double _simulateCacheSize() {
    return 80.0 + (DateTime.now().millisecond % 40);
  }

  double _simulateApiSuccessRate() {
    return 0.92 + (DateTime.now().millisecond % 8) / 100.0;
  }

  double _simulateAvgResponseTime() {
    return 250.0 + (DateTime.now().millisecond % 200);
  }

  /// 重置所有监控数据
  void reset() {
    _metricsHistory.clear();
    _currentMetrics.clear();
    _alerts.clear();
    _logger.i('性能监控数据已重置');
  }
}

/// 内存信息
class MemoryInfo {
  final int totalUsage;
  final int heapUsage;
  final int externalUsage;

  MemoryInfo({
    required this.totalUsage,
    required this.heapUsage,
    required this.externalUsage,
  });
}

/// 性能数据点
class PerformanceDataPoint {
  final String name;
  final double value;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  PerformanceDataPoint({
    required this.name,
    required this.value,
    required this.timestamp,
    required this.metadata,
  });

  String get formattedValue {
    final metric =
        PredefinedMetrics.metrics.where((m) => m.name == name).firstOrNull;

    return metric?.formatValue(value) ?? value.toStringAsFixed(2);
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'value': value,
        'timestamp': timestamp.toIso8601String(),
        'metadata': metadata,
      };
}

/// 性能警报
class PerformanceAlert {
  final String metricName;
  final PerformanceStatus status;
  final double value;
  final double threshold;
  final DateTime timestamp;

  PerformanceAlert({
    required this.metricName,
    required this.status,
    required this.value,
    required this.threshold,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'metricName': metricName,
        'status': status.name,
        'value': value,
        'threshold': threshold,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// 性能摘要
class PerformanceSummary {
  final DateTime timestamp;
  final Map<String, List<PerformanceDataPoint>> metrics;
  final List<PerformanceAlert> alerts;
  final PerformanceStatus overallStatus;

  PerformanceSummary({
    required this.timestamp,
    required this.metrics,
    required this.alerts,
    required this.overallStatus,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'metrics': metrics.map((key, value) =>
            MapEntry(key, value.map((v) => v.toJson()).toList())),
        'alerts': alerts.map((a) => a.toJson()).toList(),
        'overallStatus': overallStatus.name,
      };
}
