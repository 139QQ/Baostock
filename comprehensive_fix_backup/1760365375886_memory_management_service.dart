import 'dart:async';
import 'dart:math' as math;
import '../datasources/fund_local_data_source.dart';

/// 内存管理服务
///
/// 提供以下功能：
/// - 内存使用监控
/// - 智能垃圾回收
/// - 缓存大小管理
/// - 内存泄漏检测
class MemoryManagementService {
  final FundLocalDataSource _localDataSource;

  // 内存监控配置
  final int maxMemoryUsageMB;
  final int warningThresholdMB;
  final Duration gcInterval;
  final int maxCacheItems;

  // 状态管理
  Timer? _gcTimer;
  bool _isMonitoring = false;
  int _currentMemoryUsageMB = 0;

  // 内存统计
  final Map<String, int> _cacheItemCounts = {};
  final List<MemorySnapshot> _memorySnapshots = [];
  final Map<String, DateTime> _lastAccessTimes = {};

  // 性能指标
  final Map<String, dynamic> _performanceMetrics = {};

  MemoryManagementService(
    this._localDataSource, {
    this.maxMemoryUsageMB = 150,
    this.warningThresholdMB = 120,
    this.gcInterval = const Duration(minutes: 2),
    this.maxCacheItems = 1000,
  });

  /// 启动内存监控
  void startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _gcTimer = Timer.periodic(gcInterval, (_) => _performMemoryCheck());

    // 初始内存检查
    _performMemoryCheck();

    _recordPerformance('monitoring_started');
  }

  /// 停止内存监控
  void stopMonitoring() {
    if (!_isMonitoring) return;

    _isMonitoring = false;
    _gcTimer?.cancel();
    _gcTimer = null;

    _recordPerformance('monitoring_stopped');
  }

  /// 获取当前内存使用情况
  MemoryStatus getCurrentMemoryStatus() {
    return MemoryStatus(
      currentUsageMB: _currentMemoryUsageMB,
      maxUsageMB: maxMemoryUsageMB,
      warningThresholdMB: warningThresholdMB,
      isWarning: _currentMemoryUsageMB > warningThresholdMB,
      isCritical: _currentMemoryUsageMB > maxMemoryUsageMB,
      cacheItemCount: _cacheItemCounts.values.fold(0, (a, b) => a + b),
      lastGcTime: _performanceMetrics['last_gc_time'],
      totalGcCount: _performanceMetrics['total_gc_count'] ?? 0,
    );
  }

  /// 手动触发垃圾回收
  Future<void> forceGarbageCollection() async {
    try {
      final startTime = DateTime.now();

      // 清理过期缓存
      await _cleanupExpiredCache();

      // 清理最少使用的缓存项
      await _cleanupLeastUsedCache();

      // 触发Dart的垃圾回收
      await _triggerNativeGC();

      final endTime = DateTime.now();
      _performanceMetrics['last_gc_time'] = endTime;
      _performanceMetrics['total_gc_count'] =
          (_performanceMetrics['total_gc_count'] ?? 0) + 1;

      _recordPerformance(
          'manual_gc', endTime.difference(startTime).inMilliseconds);

      // 更新内存使用情况
      await _updateMemoryUsage();
    } catch (e) {
      _recordPerformance('gc_error');
    }
  }

  /// 预加载内存检查
  Future<void> preloadMemoryCheck() async {
    try {
      // 检查缓存大小
      final cacheSize = await _localDataSource.getCacheSizeInfo();
      _updateCacheStatistics(cacheSize);

      // 检查内存使用
      await _updateMemoryUsage();

      // 如果内存使用过高，触发清理
      if (_currentMemoryUsageMB > warningThresholdMB) {
        await forceGarbageCollection();
      }
    } catch (e) {
      _recordPerformance('preload_check_error');
    }
  }

  /// 优化缓存策略
  Future<void> optimizeCacheStrategy() async {
    try {
      // 分析缓存访问模式
      final accessPattern = _analyzeAccessPattern();

      // 根据访问模式调整缓存策略
      await _adjustCacheStrategy(accessPattern);

      // 清理低效缓存
      await _cleanupInefficientCache();

      _recordPerformance('cache_optimized');
    } catch (e) {
      _recordPerformance('cache_optimization_error');
    }
  }

  /// 记录缓存项访问
  void recordCacheAccess(String cacheKey) {
    _lastAccessTimes[cacheKey] = DateTime.now();

    // 限制访问记录数量
    if (_lastAccessTimes.length > maxCacheItems * 2) {
      final sortedKeys = _lastAccessTimes.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));

      // 保留最近的一半
      final toKeep = sortedKeys.skip(sortedKeys.length ~/ 2);
      _lastAccessTimes.clear();
      for (final entry in toKeep) {
        _lastAccessTimes[entry.key] = entry.value;
      }
    }
  }

  /// 检测内存泄漏
  MemoryLeakDetection detectMemoryLeaks() {
    final snapshots = _memorySnapshots.take(10).toList();

    if (snapshots.length < 3) {
      return const MemoryLeakDetection(
        hasLeak: false,
        leakRate: 0.0,
        suspectedLeaks: [],
        recommendation: '需要更多数据进行内存泄漏分析',
      );
    }

    // 分析内存使用趋势
    final recentSnapshots = snapshots.take(5).toList();
    final olderSnapshots = snapshots.skip(5).take(5).toList();

    if (recentSnapshots.isEmpty || olderSnapshots.isEmpty) {
      return const MemoryLeakDetection(
        hasLeak: false,
        leakRate: 0.0,
        suspectedLeaks: [],
        recommendation: '数据不足，无法进行准确的内存泄漏分析',
      );
    }

    final recentAvg =
        recentSnapshots.map((s) => s.memoryUsageMB).reduce((a, b) => a + b) /
            recentSnapshots.length;
    final olderAvg =
        olderSnapshots.map((s) => s.memoryUsageMB).reduce((a, b) => a + b) /
            olderSnapshots.length;

    final leakRate =
        ((recentAvg - olderAvg) / olderAvg * 100).clamp(0.0, 100.0);

    final suspectedLeaks = <String>[];
    if (leakRate > 20.0) {
      suspectedLeaks.add('缓存数据持续增长');
    }
    if (leakRate > 50.0) {
      suspectedLeaks.add('可能存在严重的内存泄漏');
    }

    return MemoryLeakDetection(
      hasLeak: leakRate > 10.0,
      leakRate: leakRate,
      suspectedLeaks: suspectedLeaks,
      recommendation: _getLeakRecommendation(leakRate),
    );
  }

  /// 获取内存统计信息
  Map<String, dynamic> getMemoryStatistics() {
    return {
      'current_usage_mb': _currentMemoryUsageMB,
      'max_usage_mb': maxMemoryUsageMB,
      'warning_threshold_mb': warningThresholdMB,
      'cache_item_counts': _cacheItemCounts,
      'total_cache_items': _cacheItemCounts.values.fold(0, (a, b) => a + b),
      'last_access_times_count': _lastAccessTimes.length,
      'memory_snapshots_count': _memorySnapshots.length,
      'performance_metrics': _performanceMetrics,
      'is_monitoring': _isMonitoring,
    };
  }

  /// 清理所有统计数据
  void clearStatistics() {
    _cacheItemCounts.clear();
    _memorySnapshots.clear();
    _lastAccessTimes.clear();
    _performanceMetrics.clear();
    _currentMemoryUsageMB = 0;
  }

  /// 执行内存检查
  Future<void> _performMemoryCheck() async {
    try {
      await _updateMemoryUsage();
      _recordMemorySnapshot();

      // 检查是否需要垃圾回收
      if (_currentMemoryUsageMB > warningThresholdMB) {
        await forceGarbageCollection();
      }

      // 检查缓存大小
      final totalCacheItems = _cacheItemCounts.values.fold(0, (a, b) => a + b);
      if (totalCacheItems > maxCacheItems) {
        await _cleanupCache();
      }

      _recordPerformance('memory_check_completed');
    } catch (e) {
      _recordPerformance('memory_check_error');
    }
  }

  /// 更新内存使用情况
  Future<void> _updateMemoryUsage() async {
    try {
      // 简化的内存使用估算
      // 实际应用中可以使用更精确的内存监控

      // 计算缓存数据大小
      final cacheInfo = await _localDataSource.getCacheSizeInfo();
      int cacheDataSize = 0;
      for (final size in cacheInfo.values) {
        cacheDataSize += size;
      }

      // 估算其他内存使用
      final otherMemoryEstimate = _cacheItemCounts.length * 1024; // 每个缓存项约1KB
      const systemOverhead = 50 * 1024 * 1024; // 系统开销约50MB

      final totalEstimate =
          cacheDataSize + otherMemoryEstimate + systemOverhead;
      _currentMemoryUsageMB = (totalEstimate / (1024 * 1024)).round();
    } catch (e) {
      _recordPerformance('memory_update_error');
      // 使用默认值
      _currentMemoryUsageMB =
          math.min(_currentMemoryUsageMB + 10, maxMemoryUsageMB);
    }
  }

  /// 记录内存快照
  void _recordMemorySnapshot() {
    final snapshot = MemorySnapshot(
      timestamp: DateTime.now(),
      memoryUsageMB: _currentMemoryUsageMB,
      cacheItemCount: _cacheItemCounts.values.fold(0, (a, b) => a + b),
    );

    _memorySnapshots.add(snapshot);

    // 限制快照数量
    if (_memorySnapshots.length > 50) {
      _memorySnapshots.removeRange(0, _memorySnapshots.length - 50);
    }
  }

  /// 清理过期缓存
  Future<void> _cleanupExpiredCache() async {
    try {
      await _localDataSource.clearExpiredCache();
      _recordPerformance('expired_cache_cleaned');
    } catch (e) {
      _recordPerformance('expired_cache_cleanup_error');
    }
  }

  /// 清理最少使用的缓存
  Future<void> _cleanupLeastUsedCache() async {
    try {
      final now = DateTime.now();
      final expiredKeys = <String>[];

      for (final entry in _lastAccessTimes.entries) {
        if (now.difference(entry.value).inHours > 24) {
          expiredKeys.add(entry.key);
        }
      }

      // 移除过期项，但保留最近使用的部分
      if (expiredKeys.length > 10) {
        expiredKeys.removeRange(0, expiredKeys.length - 10);
      }

      for (final key in expiredKeys) {
        _lastAccessTimes.remove(key);
        // 这里可以添加实际的缓存删除逻辑
      }

      _recordPerformance('least_used_cache_cleaned', expiredKeys.length);
    } catch (e) {
      _recordPerformance('least_used_cache_cleanup_error');
    }
  }

  /// 触发原生垃圾回收
  Future<void> _triggerNativeGC() async {
    // 在Dart中，我们无法直接触发GC
    // 但可以通过创建和销毁对象来建议GC

    // 创建临时对象
    final tempData = List.generate(1000, (index) => 'temp_data_$index');

    // 立即销毁
    tempData.clear();

    // 等待一小段时间
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// 清理缓存
  Future<void> _cleanupCache() async {
    try {
      // 移除最旧的缓存项
      final sortedAccessTimes = _lastAccessTimes.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));

      final toRemove = sortedAccessTimes.take(sortedAccessTimes.length ~/ 4);

      for (final entry in toRemove) {
        _lastAccessTimes.remove(entry.key);
      }

      _recordPerformance('cache_cleanup', toRemove.length);
    } catch (e) {
      _recordPerformance('cache_cleanup_error');
    }
  }

  /// 更新缓存统计
  void _updateCacheStatistics(Map<String, int> cacheInfo) {
    _cacheItemCounts.clear();
    _cacheItemCounts.addAll(cacheInfo);
  }

  /// 分析访问模式
  Map<String, dynamic> _analyzeAccessPattern() {
    if (_lastAccessTimes.isEmpty) {
      return {'pattern': 'no_data'};
    }

    final now = DateTime.now();
    final recentAccess = _lastAccessTimes.values
        .where((time) => now.difference(time).inHours < 1)
        .length;

    final totalAccess = _lastAccessTimes.length;
    final accessFrequency = totalAccess > 0 ? recentAccess / totalAccess : 0.0;

    return {
      'pattern': accessFrequency > 0.5 ? 'high_frequency' : 'low_frequency',
      'recent_access_count': recentAccess,
      'total_access_count': totalAccess,
      'access_frequency': accessFrequency,
    };
  }

  /// 调整缓存策略
  Future<void> _adjustCacheStrategy(Map<String, dynamic> accessPattern) async {
    final pattern = accessPattern['pattern'] as String;

    switch (pattern) {
      case 'high_frequency':
        // 高频访问，增加缓存时间
        _recordPerformance('cache_strategy_adjusted_to_high_frequency');
        break;
      case 'low_frequency':
        // 低频访问，减少缓存时间
        _recordPerformance('cache_strategy_adjusted_to_low_frequency');
        break;
      default:
        _recordPerformance('cache_strategy_no_adjustment_needed');
    }
  }

  /// 清理低效缓存
  Future<void> _cleanupInefficientCache() async {
    try {
      final now = DateTime.now();
      final inefficientKeys = <String>[];

      // 找出长期未访问的缓存项
      for (final entry in _lastAccessTimes.entries) {
        if (now.difference(entry.value).inDays > 7) {
          inefficientKeys.add(entry.key);
        }
      }

      // 清理低效缓存项
      for (final key in inefficientKeys) {
        _lastAccessTimes.remove(key);
      }

      _recordPerformance('inefficient_cache_cleaned', inefficientKeys.length);
    } catch (e) {
      _recordPerformance('inefficient_cache_cleanup_error');
    }
  }

  /// 获取内存泄漏建议
  String _getLeakRecommendation(double leakRate) {
    if (leakRate < 10.0) {
      return '内存使用正常，继续监控';
    } else if (leakRate < 30.0) {
      return '建议检查缓存策略，考虑减少缓存大小';
    } else if (leakRate < 50.0) {
      return '内存增长较快，建议立即检查代码中的内存泄漏问题';
    } else {
      return '存在严重内存泄漏，需要立即修复并重启应用';
    }
  }

  /// 记录性能指标
  void _recordPerformance(String operation, [dynamic value]) {
    _performanceMetrics[
            '${operation}_${DateTime.now().millisecondsSinceEpoch}'] =
        value ?? true;

    // 限制性能指标数量
    if (_performanceMetrics.length > 500) {
      final keys = _performanceMetrics.keys.toList()..sort();
      final toRemove = keys.take(_performanceMetrics.length - 400);
      for (final key in toRemove) {
        _performanceMetrics.remove(key);
      }
    }
  }
}

/// 内存状态
class MemoryStatus {
  final int currentUsageMB;
  final int maxUsageMB;
  final int warningThresholdMB;
  final bool isWarning;
  final bool isCritical;
  final int cacheItemCount;
  final DateTime? lastGcTime;
  final int totalGcCount;

  const MemoryStatus({
    required this.currentUsageMB,
    required this.maxUsageMB,
    required this.warningThresholdMB,
    required this.isWarning,
    required this.isCritical,
    required this.cacheItemCount,
    this.lastGcTime,
    required this.totalGcCount,
  });

  @override
  String toString() {
    return 'MemoryStatus(usage: ${currentUsageMB}MB, max: ${maxUsageMB}MB, cacheItems: $cacheItemCount, gcCount: $totalGcCount)';
  }
}

/// 内存快照
class MemorySnapshot {
  final DateTime timestamp;
  final int memoryUsageMB;
  final int cacheItemCount;

  const MemorySnapshot({
    required this.timestamp,
    required this.memoryUsageMB,
    required this.cacheItemCount,
  });
}

/// 内存泄漏检测结果
class MemoryLeakDetection {
  final bool hasLeak;
  final double leakRate;
  final List<String> suspectedLeaks;
  final String recommendation;

  const MemoryLeakDetection({
    required this.hasLeak,
    required this.leakRate,
    required this.suspectedLeaks,
    required this.recommendation,
  });

  @override
  String toString() {
    return 'MemoryLeakDetection(hasLeak: $hasLeak, rate: ${leakRate.toStringAsFixed(1)}%, recommendations: $recommendation)';
  }
}
