import 'dart:async';
import 'package:flutter/foundation.dart';

import 'performance_models.dart';

/// 性能监控工具
///
/// 用于监控数据加载和缓存性能
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Map<String, PerformanceMetrics> _metrics = {};
  final List<PerformanceEvent> _events = [];
  Timer? _reportingTimer;

  /// 开始性能监控
  void startMonitoring() {
    debugPrint('📊 开始性能监控...');

    _reportingTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _generateReport();
    });
  }

  /// 停止性能监控
  void stopMonitoring() {
    _reportingTimer?.cancel();
    debugPrint('📊 性能监控已停止');
  }

  /// 记录操作开始
  String startOperation(String operation) {
    final id = '${operation}_${DateTime.now().millisecondsSinceEpoch}';
    _events.add(PerformanceEvent(
      type: 'start',
      operation: operation,
      duration: 0,
      metadata: {'id': id},
    ));
    return id;
  }

  /// 记录操作完成
  void endOperation(
    String operationId,
    String operation, {
    bool cached = false,
    bool error = false,
    Map<String, dynamic>? metadata,
  }) {
    final startEvent = _events.lastWhere(
      (event) => event.metadata['id'] == operationId,
      orElse: () => PerformanceEvent(
        type: 'start',
        operation: operation,
        duration: 0,
        metadata: {'id': operationId},
      ),
    );

    final duration =
        DateTime.now().difference(startEvent.timestamp).inMilliseconds;

    // 记录到指标
    final metrics =
        _metrics.putIfAbsent(operation, () => PerformanceMetrics(operation));
    metrics.recordCall(duration, cached: cached, error: error);

    // 记录事件
    _events.add(PerformanceEvent(
      type: error ? 'error' : (cached ? 'cached' : 'complete'),
      operation: operation,
      duration: duration,
      metadata: {
        'id': operationId,
        'cached': cached,
        'error': error,
        ...?metadata,
      },
    ));

    if (kDebugMode) {
      final status = error ? '❌' : (cached ? '💾' : '🌐');
      debugPrint(
          '$status $operation: ${duration}ms${cached ? ' (缓存)' : ''}${error ? ' (错误)' : ''}');
    }
  }

  /// 获取性能指标
  Map<String, PerformanceMetrics> getMetrics() {
    return Map.from(_metrics);
  }

  /// 获取操作指标
  PerformanceMetrics? getOperationMetrics(String operation) {
    return _metrics[operation];
  }

  /// 生成性能报告
  void _generateReport() {
    if (_metrics.isEmpty) {
      debugPrint('📊 暂无性能数据');
      return;
    }

    debugPrint('\n📊 ========== 性能监控报告 ==========');
    debugPrint('📅 报告时间: ${DateTime.now()}');
    debugPrint('📊 监控的操作数: ${_metrics.length}');

    for (final metrics in _metrics.values) {
      debugPrint('\n🔍 ${metrics.operation}:');
      debugPrint('  📞 调用次数: ${metrics.totalCalls}');
      debugPrint('  ⏱️  平均耗时: ${metrics.averageTime.toStringAsFixed(2)}ms');
      debugPrint('  📈 时间范围: ${metrics.minTime}ms - ${metrics.maxTime}ms');
      debugPrint(
          '  💾 缓存命中率: ${(metrics.cacheHitRate * 100).toStringAsFixed(1)}%');
      debugPrint('  ❌ 错误率: ${(metrics.errorRate * 100).toStringAsFixed(1)}%');
    }

    // 计算整体性能
    final totalCalls = _metrics.values.fold(0, (sum, m) => sum + m.totalCalls);
    final totalTime = _metrics.values.fold(0, (sum, m) => sum + m.totalTime);
    final totalCacheHits =
        _metrics.values.fold(0, (sum, m) => sum + m.cacheHits);
    final totalErrors = _metrics.values.fold(0, (sum, m) => sum + m.errors);

    debugPrint('\n📊 整体性能:');
    debugPrint('  📞 总调用次数: $totalCalls');
    debugPrint('  ⏱️  总耗时: ${totalTime}ms');
    debugPrint(
        '  💾 整体缓存命中率: ${totalCalls > 0 ? ((totalCacheHits / totalCalls) * 100).toStringAsFixed(1) : 0}%');
    debugPrint(
        '  ❌ 整体错误率: ${totalCalls > 0 ? ((totalErrors / totalCalls) * 100).toStringAsFixed(1) : 0}%');

    // 性能建议
    _generateRecommendations();

    debugPrint('=====================================\n');
  }

  /// 生成性能建议
  void _generateRecommendations() {
    final recommendations = <String>[];

    for (final metrics in _metrics.values) {
      // 检查缓存命中率
      if (metrics.cacheHitRate < 0.3 && metrics.totalCalls > 5) {
        recommendations.add(
            '💡 ${metrics.operation} 缓存命中率较低 (${(metrics.cacheHitRate * 100).toStringAsFixed(1)}%)，考虑优化缓存策略');
      }

      // 检查平均响应时间
      if (metrics.averageTime > 1000) {
        recommendations.add(
            '⚠️ ${metrics.operation} 平均响应时间较长 (${metrics.averageTime.toStringAsFixed(0)}ms)，考虑优化或增加缓存');
      }

      // 检查错误率
      if (metrics.errorRate > 0.1) {
        recommendations.add(
            '🚨 ${metrics.operation} 错误率较高 (${(metrics.errorRate * 100).toStringAsFixed(1)}%)，需要检查错误处理');
      }

      // 检查调用频率
      if (metrics.totalCalls > 100) {
        recommendations.add(
            '📈 ${metrics.operation} 调用频率很高 (${metrics.totalCalls}次)，确保有有效的缓存策略');
      }
    }

    if (recommendations.isNotEmpty) {
      debugPrint('\n💡 性能优化建议:');
      for (final recommendation in recommendations) {
        debugPrint('  $recommendation');
      }
    } else {
      debugPrint('\n✅ 当前性能表现良好，无特别建议');
    }
  }

  /// 重置所有指标
  void reset() {
    _metrics.clear();
    _events.clear();
    debugPrint('📊 性能指标已重置');
  }

  /// 导出性能数据
  Map<String, dynamic> exportData() {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'metrics': _metrics.map((k, v) => MapEntry(k, v.toJson())),
      'summary': {
        'totalOperations': _metrics.length,
        'totalCalls': _metrics.values.fold(0, (sum, m) => sum + m.totalCalls),
        'totalTime': _metrics.values.fold(0, (sum, m) => sum + m.totalTime),
        'averageCacheHitRate': _metrics.values.isEmpty
            ? 0.0
            : (_metrics.values.fold(0, (sum, m) => sum + m.cacheHits) /
                _metrics.values.fold(0, (sum, m) => sum + m.totalCalls)),
        'averageErrorRate': _metrics.values.isEmpty
            ? 0.0
            : (_metrics.values.fold(0, (sum, m) => sum + m.errors) /
                _metrics.values.fold(0, (sum, m) => sum + m.totalCalls)),
      },
    };
  }
}

/// 性能监控装饰器
class MonitoredOperation {
  final String operation;
  final PerformanceMonitor _monitor = PerformanceMonitor();

  MonitoredOperation(this.operation);

  /// 执行被监控的操作
  Future<T> execute<T>(
    Future<T> Function() operationFunction, {
    Map<String, dynamic>? metadata,
  }) async {
    final id = _monitor.startOperation(operation);

    try {
      final result = await operationFunction();
      _monitor.endOperation(id, operation, metadata: metadata);
      return result;
    } catch (e) {
      _monitor.endOperation(id, operation, error: true, metadata: {
        'error': e.toString(),
        ...?metadata,
      });
      rethrow;
    }
  }

  /// 执行缓存命中的操作
  Future<T> executeCached<T>(
    Future<T> Function() operationFunction, {
    Map<String, dynamic>? metadata,
  }) async {
    final id = _monitor.startOperation(operation);

    try {
      final result = await operationFunction();
      _monitor.endOperation(id, operation, cached: true, metadata: metadata);
      return result;
    } catch (e) {
      _monitor
          .endOperation(id, operation, error: true, cached: true, metadata: {
        'error': e.toString(),
        ...?metadata,
      });
      rethrow;
    }
  }
}
