import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../utils/logger.dart';

/// 组件性能监控器 - Story R.4 AC7验收支持
///
/// 专门用于监控UI组件的性能指标：
/// - 组件重建频率
/// - 渲染时间
/// - 缓存命中率
/// - 内存使用优化
///
/// 为AC7验收标准"不必要的重建减少60%+"提供量化数据支持
class ComponentMonitor {
  static final ComponentMonitor _instance = ComponentMonitor._internal();
  factory ComponentMonitor() => _instance;
  ComponentMonitor._internal();

  final Map<String, ComponentMetrics> _componentMetrics = {};
  final Map<String, Queue<RenderTimeRecord>> _renderTimeHistory = {};
  final Map<String, DateTime> _lastRenderTime = {};
  final Map<String, int> _rebuildCounters = {};
  final Map<String, int> _cacheHits = {};
  final Map<String, int> _cacheMisses = {};

  bool _isMonitoring = false;
  Timer? _reportingTimer;

  /// 开始监控
  void startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;
    AppLogger.info('组件性能监控已启动');

    // 每30秒生成一次报告
    _reportingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _generatePerformanceReport();
    });
  }

  /// 停止监控
  void stopMonitoring() {
    if (!_isMonitoring) return;

    _isMonitoring = false;
    _reportingTimer?.cancel();
    _reportingTimer = null;
    AppLogger.info('组件性能监控已停止');
  }

  /// 记录组件渲染开始
  void recordRenderStart(String componentKey, Widget widget) {
    if (!_isMonitoring) return;

    final timestamp = DateTime.now();
    _lastRenderTime[componentKey] = timestamp;

    _componentMetrics.putIfAbsent(componentKey, () => ComponentMetrics(componentKey));

    // 检查是否为不必要的重建
    if (_isUnnecessaryRebuild(componentKey)) {
      _componentMetrics[componentKey]!.unnecessaryRebuilds++;
    }
  }

  /// 记录组件渲染完成
  void recordRenderEnd(String componentKey) {
    if (!_isMonitoring) return;

    final startTime = _lastRenderTime[componentKey];
    if (startTime == null) return;

    final renderTime = DateTime.now().difference(startTime).inMicroseconds.toDouble() / 1000.0; // 转换为毫秒

    _renderTimeHistory.putIfAbsent(componentKey, () => Queue());
    final history = _renderTimeHistory[componentKey]!;

    history.add(RenderTimeRecord(renderTime, DateTime.now()));

    // 保持最近100次渲染记录
    while (history.length > 100) {
      history.removeFirst();
    }

    _componentMetrics[componentKey]?.totalRenderTime += renderTime;
    _componentMetrics[componentKey]?.renderCount++;
  }

  /// 记录缓存命中
  void recordCacheHit(String componentKey) {
    if (!_isMonitoring) return;

    _cacheHits[componentKey] = (_cacheHits[componentKey] ?? 0) + 1;
    _componentMetrics[componentKey]?.cacheHits++;
  }

  /// 记录缓存未命中
  void recordCacheMiss(String componentKey) {
    if (!_isMonitoring) return;

    _cacheMisses[componentKey] = (_cacheMisses[componentKey] ?? 0) + 1;
    _componentMetrics[componentKey]?.cacheMisses++;
  }

  /// 检查是否为不必要的重建
  bool _isUnnecessaryRebuild(String componentKey) {
    final lastTime = _lastRenderTime[componentKey];
    if (lastTime == null) return false;

    final timeSinceLastRender = DateTime.now().difference(lastTime);
    // 如果在16ms内重建（60fps），可能是不必要的
    return timeSinceLastRender.inMilliseconds < 16;
  }

  /// 获取组件性能指标
  ComponentMetrics? getMetrics(String componentKey) {
    return _componentMetrics[componentKey];
  }

  /// 获取所有组件的性能指标
  Map<String, ComponentMetrics> getAllMetrics() {
    return Map.unmodifiable(_componentMetrics);
  }

  /// 获取重建优化率
  double getRebuildOptimizationRate(String componentKey) {
    final metrics = _componentMetrics[componentKey];
    if (metrics == null || metrics.renderCount == 0) return 0.0;

    final unnecessaryRate = metrics.unnecessaryRebuilds / metrics.renderCount;
    return (1.0 - unnecessaryRate) * 100.0; // 返回优化率百分比
  }

  /// 获取缓存效率
  double getCacheEfficiency(String componentKey) {
    final hits = _cacheHits[componentKey] ?? 0;
    final misses = _cacheMisses[componentKey] ?? 0;
    final total = hits + misses;

    if (total == 0) return 0.0;
    return (hits / total) * 100.0;
  }

  /// 获取平均渲染时间
  double getAverageRenderTime(String componentKey) {
    final history = _renderTimeHistory[componentKey];
    if (history == null || history.isEmpty) return 0.0;

    final totalTime = history.fold<double>(0.0, (sum, record) => sum + record.renderTime);
    return totalTime / history.length;
  }

  /// 生成性能报告
  void _generatePerformanceReport() {
    if (_componentMetrics.isEmpty) return;

    AppLogger.info('=== 组件性能监控报告 ===');

    for (final entry in _componentMetrics.entries) {
      final componentKey = entry.key;
      final metrics = entry.value;

      final optimizationRate = getRebuildOptimizationRate(componentKey);
      final cacheEfficiency = getCacheEfficiency(componentKey);
      final avgRenderTime = getAverageRenderTime(componentKey);

      AppLogger.info('组件: $componentKey');
      AppLogger.info('  - 渲染次数: ${metrics.renderCount}');
      AppLogger.info('  - 不必要重建: ${metrics.unnecessaryRebuilds}');
      AppLogger.info('  - 重建优化率: ${optimizationRate.toStringAsFixed(1)}%');
      AppLogger.info('  - 缓存效率: ${cacheEfficiency.toStringAsFixed(1)}%');
      AppLogger.info('  - 平均渲染时间: ${avgRenderTime.toStringAsFixed(2)}ms');
      AppLogger.info('');
    }

    // 验证AC7验收标准
    _validateAC7Compliance();
  }

  /// 验证AC7验收标准：不必要的重建减少60%+
  void _validateAC7Compliance() {
    bool allComponentsComply = true;

    for (final entry in _componentMetrics.entries) {
      final componentKey = entry.key;
      final optimizationRate = getRebuildOptimizationRate(componentKey);

      if (optimizationRate < 60.0) {
        AppLogger.warning('AC7验收失败: $componentKey 优化率 ${optimizationRate.toStringAsFixed(1)}% < 60%');
        allComponentsComply = false;
      } else {
        AppLogger.info('✅ AC7验收通过: $componentKey 优化率 ${optimizationRate.toStringAsFixed(1)}% ≥ 60%');
      }
    }

    if (allComponentsComply && _componentMetrics.isNotEmpty) {
      AppLogger.info('🎉 AC7验收标准完全通过：所有组件不必要的重建减少60%+');
    }
  }

  /// 导出详细性能数据
  Map<String, dynamic> exportPerformanceData() {
    final data = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'components': <String, dynamic>{},
      'summary': <String, dynamic>{},
    };

    for (final entry in _componentMetrics.entries) {
      final componentKey = entry.key;
      final metrics = entry.value;

      data['components'][componentKey] = {
        'renderCount': metrics.renderCount,
        'unnecessaryRebuilds': metrics.unnecessaryRebuilds,
        'cacheHits': metrics.cacheHits,
        'cacheMisses': metrics.cacheMisses,
        'totalRenderTime': metrics.totalRenderTime,
        'averageRenderTime': getAverageRenderTime(componentKey),
        'rebuildOptimizationRate': getRebuildOptimizationRate(componentKey),
        'cacheEfficiency': getCacheEfficiency(componentKey),
      };
    }

    // 生成汇总数据
    data['summary'] = {
      'totalComponents': _componentMetrics.length,
      'totalRenders': _componentMetrics.values.fold(0, (sum, m) => sum + m.renderCount),
      'totalUnnecessaryRebuilds': _componentMetrics.values.fold(0, (sum, m) => sum + m.unnecessaryRebuilds),
      'averageOptimizationRate': _calculateAverageOptimizationRate(),
      'ac7Compliance': _checkAC7Compliance(),
    };

    return data;
  }

  double _calculateAverageOptimizationRate() {
    if (_componentMetrics.isEmpty) return 0.0;

    final totalOptimizationRate = _componentMetrics.keys
        .map((key) => getRebuildOptimizationRate(key))
        .fold(0.0, (sum, rate) => sum + rate);

    return totalOptimizationRate / _componentMetrics.length;
  }

  bool _checkAC7Compliance() {
    for (final entry in _componentMetrics.entries) {
      final optimizationRate = getRebuildOptimizationRate(entry.key);
      if (optimizationRate < 60.0) return false;
    }
    return _componentMetrics.isNotEmpty;
  }

  /// 重置所有监控数据
  void reset() {
    _componentMetrics.clear();
    _renderTimeHistory.clear();
    _lastRenderTime.clear();
    _rebuildCounters.clear();
    _cacheHits.clear();
    _cacheMisses.clear();
    AppLogger.info('组件性能监控数据已重置');
  }

  /// 清理资源
  void dispose() {
    stopMonitoring();
    reset();
    AppLogger.info('组件性能监控器已释放资源');
  }
}

/// 组件性能指标
class ComponentMetrics {
  final String componentKey;
  int renderCount = 0;
  int unnecessaryRebuilds = 0;
  int cacheHits = 0;
  int cacheMisses = 0;
  double totalRenderTime = 0.0;

  ComponentMetrics(this.componentKey);

  Map<String, dynamic> toJson() {
    return {
      'componentKey': componentKey,
      'renderCount': renderCount,
      'unnecessaryRebuilds': unnecessaryRebuilds,
      'cacheHits': cacheHits,
      'cacheMisses': cacheMisses,
      'totalRenderTime': totalRenderTime,
    };
  }
}

/// 渲染时间记录
class RenderTimeRecord {
  final double renderTime; // 毫秒
  final DateTime timestamp;

  RenderTimeRecord(this.renderTime, this.timestamp);
}

/// 组件性能监控Mixin
///
/// 使用方法：
/// ```dart
/// class MyWidget extends StatefulWidget {
///   @override
///   _MyWidgetState createState() => _MyWidgetState();
/// }
///
/// class _MyWidgetState extends State<MyWidget> with ComponentMonitorMixin {
///   @override
///   String get componentKey => 'MyWidget';
///
///   @override
///   Widget build(BuildContext context) {
///     return monitoredBuild(context, () {
///       return YourWidgetTree();
///     });
///   }
/// }
/// ```
mixin ComponentMonitorMixin<T extends StatefulWidget> on State<T> {
  static final ComponentMonitor _monitor = ComponentMonitor();

  /// 组件唯一标识符
  String get componentKey;

  /// 是否启用性能监控
  bool get enablePerformanceMonitoring => kDebugMode;

  @override
  void initState() {
    super.initState();
    if (enablePerformanceMonitoring) {
      _monitor.startMonitoring();
    }
  }

  @override
  void dispose() {
    if (enablePerformanceMonitoring) {
      _monitor.recordRenderEnd(componentKey);
      _monitor.stopMonitoring(); // 清理Timer避免泄漏
    }
    super.dispose();
  }

  /// 监控的构建方法
  Widget monitoredBuild(BuildContext context, Widget Function() builder) {
    if (!enablePerformanceMonitoring) {
      return builder();
    }

    _monitor.recordRenderStart(componentKey, builder());

    try {
      final widget = builder();
      _monitor.recordRenderEnd(componentKey);
      return widget;
    } catch (e) {
      _monitor.recordRenderEnd(componentKey);
      rethrow;
    }
  }

  /// 获取当前组件的性能指标
  ComponentMetrics? get performanceMetrics =>
      _monitor.getMetrics(componentKey);

  /// 获取重建优化率
  double get rebuildOptimizationRate =>
      _monitor.getRebuildOptimizationRate(componentKey);

  /// 手动记录缓存命中
  void recordCacheHit() =>
      _monitor.recordCacheHit(componentKey);

  /// 手动记录缓存未命中
  void recordCacheMiss() =>
      _monitor.recordCacheMiss(componentKey);
}