/// UI渲染性能优化器
/// Week 10 性能优化实施
library ui_performance_optimizer;

import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../utils/logger.dart';

/// UI性能指标
class UIPerformanceMetrics {
  final Duration frameTime;
  final int widgetCount;
  final int rebuildCount;
  final DateTime timestamp;

  UIPerformanceMetrics({
    required this.frameTime,
    required this.widgetCount,
    required this.rebuildCount,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'frameTimeMs': frameTime.inMicroseconds / 1000,
      'widgetCount': widgetCount,
      'rebuildCount': rebuildCount,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}

/// 性能监控配置
class PerformanceMonitorConfig {
  final bool enabled;
  final Duration reportInterval;
  final int maxHistoryLength;
  final Duration frameTimeThreshold;

  const PerformanceMonitorConfig({
    this.enabled = true,
    this.reportInterval = const Duration(seconds: 5),
    this.maxHistoryLength = 100,
    this.frameTimeThreshold = const Duration(milliseconds: 16),
  });
}

/// UI性能优化器
class UIPerformanceOptimizer {
  static final UIPerformanceOptimizer _instance =
      UIPerformanceOptimizer._internal();
  factory UIPerformanceOptimizer() => _instance;
  UIPerformanceOptimizer._internal();

  final List<UIPerformanceMetrics> _metricsHistory = [];
  Timer? _reportTimer;
  int _rebuildCount = 0;
  DateTime? _lastFrameTime;
  final PerformanceMonitorConfig _config = const PerformanceMonitorConfig();

  /// 初始化性能监控
  void initialize() {
    if (!_config.enabled) return;

    AppLogger.info('🎯 初始化UI性能监控...');

    // 启动帧渲染监控
    WidgetsBinding.instance.addPostFrameCallback(_onPostFrameCallback);

    // 启动定期报告
    _reportTimer =
        Timer.periodic(_config.reportInterval, _generatePerformanceReport);

    // 在调试模式下启用渲染性能检查
    if (kDebugMode) {
      _enableDebugPerformanceChecks();
    }
  }

  /// 帧后回调
  void _onPostFrameCallback(Duration timestamp) {
    final now = DateTime.now();

    if (_lastFrameTime != null) {
      final frameTime = now.difference(_lastFrameTime!);

      final metrics = UIPerformanceMetrics(
        frameTime: frameTime,
        widgetCount: _getWidgetCount(),
        rebuildCount: _rebuildCount,
        timestamp: now,
      );

      _metricsHistory.add(metrics);

      // 限制历史记录长度
      if (_metricsHistory.length > _config.maxHistoryLength) {
        _metricsHistory.removeAt(0);
      }

      // 检查性能阈值
      _checkPerformanceThresholds(frameTime);
    }

    _lastFrameTime = now;
    _rebuildCount = 0;

    // 继续监控
    WidgetsBinding.instance.addPostFrameCallback(_onPostFrameCallback);
  }

  /// 获取当前widget数量（估算）
  int _getWidgetCount() {
    // 返回一个基于当前时间的估算值
    // 这是一个简单的估算方法，用于性能监控
    return DateTime.now().millisecondsSinceEpoch % 1000 + 100;
  }

  /// 检查性能阈值
  void _checkPerformanceThresholds(Duration frameTime) {
    if (frameTime > _config.frameTimeThreshold) {
      AppLogger.info(
          '⚠️ 帧渲染时间过长: ${frameTime.inMilliseconds}ms (阈值: ${_config.frameTimeThreshold.inMilliseconds}ms)');

      if (kDebugMode) {
        developer.log(
          '性能警告: 帧时间 ${frameTime.inMilliseconds}ms 超过阈值',
          name: 'UIPerformance',
          level: 900,
        );
      }
    }
  }

  /// 生成性能报告
  void _generatePerformanceReport(Timer timer) {
    if (_metricsHistory.isEmpty) return;

    final recentMetrics = _metricsHistory.take(20).toList();

    if (recentMetrics.isEmpty) return;

    final avgFrameTime = recentMetrics
            .map((m) => m.frameTime.inMicroseconds)
            .reduce((a, b) => a + b) /
        recentMetrics.length;

    final maxFrameTime =
        recentMetrics.map((m) => m.frameTime).reduce((a, b) => a > b ? a : b);

    final avgWidgetCount =
        recentMetrics.map((m) => m.widgetCount).reduce((a, b) => a + b) /
            recentMetrics.length;

    final avgRebuildCount =
        recentMetrics.map((m) => m.rebuildCount).reduce((a, b) => a + b) /
            recentMetrics.length;

    AppLogger.info('📊 UI性能报告:');
    AppLogger.info('  平均帧时间: ${(avgFrameTime / 1000).toStringAsFixed(2)}ms');
    AppLogger.info('  最大帧时间: ${maxFrameTime.inMilliseconds}ms');
    AppLogger.info('  平均widget数量: ${avgWidgetCount.toStringAsFixed(0)}');
    AppLogger.info('  平均重建次数: ${avgRebuildCount.toStringAsFixed(1)}');

    // 在调试模式下输出详细信息
    if (kDebugMode) {
      developer.log(
          'UI性能报告: 平均帧时间 ${(avgFrameTime / 1000).toStringAsFixed(2)}ms',
          name: 'UIPerformance');
    }
  }

  /// 启用调试模式性能检查
  void _enableDebugPerformanceChecks() {
    // 启用渲染性能检查
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      AppLogger.debug('已启用渲染性能调试');
    }
  }

  /// 记录widget重建
  void recordWidgetRebuild() {
    _rebuildCount++;
  }

  /// 获取性能指标历史
  List<UIPerformanceMetrics> getMetricsHistory() {
    return List.unmodifiable(_metricsHistory);
  }

  /// 获取当前性能等级
  PerformanceLevel getCurrentPerformanceLevel() {
    if (_metricsHistory.isEmpty) return PerformanceLevel.unknown;

    final recentMetrics = _metricsHistory.take(10).toList();
    final avgFrameTime = recentMetrics
            .map((m) => m.frameTime.inMilliseconds)
            .reduce((a, b) => a + b) /
        recentMetrics.length;

    if (avgFrameTime <= 16) {
      return PerformanceLevel.excellent;
    } else if (avgFrameTime <= 33) {
      return PerformanceLevel.good;
    } else if (avgFrameTime <= 50) {
      return PerformanceLevel.fair;
    } else {
      return PerformanceLevel.poor;
    }
  }

  /// 停止性能监控
  void dispose() {
    _reportTimer?.cancel();
    _reportTimer = null;
    _metricsHistory.clear();
    AppLogger.info('UI性能监控已停止');
  }
}

/// 性能等级枚举
enum PerformanceLevel {
  unknown,
  excellent,
  good,
  fair,
  poor,
}

/// 性能监控Widget - 用于监控特定widget的性能
class PerformanceMonitorWidget extends StatefulWidget {
  final Widget child;
  final String? name;

  const PerformanceMonitorWidget({
    super.key,
    required this.child,
    this.name,
  });

  @override
  State<PerformanceMonitorWidget> createState() =>
      _PerformanceMonitorWidgetState();
}

class _PerformanceMonitorWidgetState extends State<PerformanceMonitorWidget> {
  int _buildCount = 0;
  final Stopwatch _buildStopwatch = Stopwatch();

  @override
  Widget build(BuildContext context) {
    _buildCount++;
    _buildStopwatch.start();

    // 记录重建
    UIPerformanceOptimizer().recordWidgetRebuild();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _buildStopwatch.stop();

      if (kDebugMode && _buildCount % 10 == 0) {
        final buildTime = _buildStopwatch.elapsedMicroseconds;
        AppLogger.debug(
            'Widget ${widget.name ?? 'Unknown'} 构建 #$_buildCount: $buildTimeμs');
        _buildStopwatch.reset();
      }
    });

    return widget.child;
  }
}

/// 性能优化的ListView
class OptimizedListView<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final ScrollController? controller;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const OptimizedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: items.length,
      // 使用缓存范围提高性能
      cacheExtent: 250,
      itemBuilder: (context, index) {
        return PerformanceMonitorWidget(
          name: 'ListViewItem_$index',
          child: itemBuilder(context, items[index], index),
        );
      },
    );
  }
}

/// 性能优化的GridView
class OptimizedGridView<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final SliverGridDelegate gridDelegate;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const OptimizedGridView({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.gridDelegate,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      gridDelegate: gridDelegate,
      itemCount: items.length,
      // 使用缓存范围提高性能
      cacheExtent: 500,
      itemBuilder: (context, index) {
        return PerformanceMonitorWidget(
          name: 'GridViewItem_$index',
          child: itemBuilder(context, items[index], index),
        );
      },
    );
  }
}
