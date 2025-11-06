/// 缓存管理组件
///
/// 提供缓存管理相关的辅助组件，包括：
/// - 内存管理器
/// - 并发控制器
/// - 维护调度器
library cache_management;

import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import '../interfaces/i_unified_cache_service.dart';

// ============================================================================
// 内存管理器
// ============================================================================

/// 内存管理器
///
/// 负责监控和管理缓存系统的内存使用
class MemoryManager {
  static const int _maxMemoryBytes = 100 * 1024 * 1024; // 100MB
  static const int _warningThresholdBytes = 80 * 1024 * 1024; // 80MB
  static const int _criticalThresholdBytes = 95 * 1024 * 1024; // 95MB

  int _currentMemoryUsage = 0;
  final Queue<MemoryUsageRecord> _usageHistory = Queue();
  Timer? _monitoringTimer;
  Function(double)? _memoryPressureCallback;

  /// 启动内存监控
  void start(Function(double) onMemoryPressure) {
    _memoryPressureCallback = onMemoryPressure;
    _monitoringTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkMemoryPressure();
    });
  }

  /// 停止内存监控
  void stop() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    _memoryPressureCallback = null;
  }

  /// 记录存储操作
  void recordStorage(int bytes) {
    _currentMemoryUsage += bytes;
    _addUsageRecord();
    _checkMemoryPressure();
  }

  /// 记录删除操作
  void recordDeletion(int bytes) {
    _currentMemoryUsage = math.max(0, _currentMemoryUsage - bytes);
    _addUsageRecord();
  }

  /// 获取当前内存使用量
  int getCurrentMemoryUsage() => _currentMemoryUsage;

  /// 获取内存使用率
  double getMemoryUsageRatio() {
    return _currentMemoryUsage / _maxMemoryBytes;
  }

  /// 检查内存压力
  Future<void> checkMemoryPressure() async {
    await _checkMemoryPressure();
  }

  /// 触发内存清理
  Future<void> triggerCleanup(int requiredBytes) async {
    if (_currentMemoryUsage + requiredBytes <= _maxMemoryBytes) {
      return; // 无需清理
    }

    final bytesToFree = (_currentMemoryUsage + requiredBytes) - _maxMemoryBytes;
    await _performMemoryCleanup(bytesToFree);
  }

  /// 优化内存使用
  Future<void> optimize() async {
    // 1. 清理使用历史
    while (_usageHistory.length > 100) {
      _usageHistory.removeFirst();
    }

    // 2. 如果内存使用过高，执行清理
    if (getMemoryUsageRatio() > 0.8) {
      await _performMemoryCleanup((_currentMemoryUsage * 0.2).round());
    }
  }

  /// 重置统计信息
  void reset() {
    _currentMemoryUsage = 0;
    _usageHistory.clear();
  }

  void _addUsageRecord() {
    final record = MemoryUsageRecord(
      timestamp: DateTime.now(),
      memoryUsage: _currentMemoryUsage,
    );

    _usageHistory.add(record);

    // 保持历史记录在合理范围内
    if (_usageHistory.length > 1000) {
      _usageHistory.removeFirst();
    }
  }

  Future<void> _checkMemoryPressure() async {
    final ratio = getMemoryUsageRatio();

    if (ratio > 0.95) {
      // 严重内存压力
      _memoryPressureCallback?.call(ratio);
      await _performAggressiveCleanup();
    } else if (ratio > 0.8) {
      // 中等内存压力
      _memoryPressureCallback?.call(ratio);
      await _performModerateCleanup();
    }
  }

  Future<void> _performMemoryCleanup(int bytesToFree) async {
    // 这里应该调用缓存管理器的清理方法
    // 为了避免循环依赖，这里只是记录清理需求
    print('Need to free $bytesToFree bytes of memory');
  }

  Future<void> _performModerateCleanup() async {
    // 中等清理策略
    final bytesToFree = (_currentMemoryUsage * 0.15).round();
    await _performMemoryCleanup(bytesToFree);
  }

  Future<void> _performAggressiveCleanup() async {
    // 激进清理策略
    final bytesToFree = (_currentMemoryUsage * 0.3).round();
    await _performMemoryCleanup(bytesToFree);
  }
}

/// 内存使用记录
class MemoryUsageRecord {
  final DateTime timestamp;
  final int memoryUsage;

  const MemoryUsageRecord({
    required this.timestamp,
    required this.memoryUsage,
  });
}

// ============================================================================
// 并发控制器
// ============================================================================

/// 缓存并发控制器
///
/// 管理缓存操作的并发执行，防止资源竞争
class CacheConcurrencyController {
  final int _maxConcurrentOperations;
  final Semaphore _semaphore;
  final Map<String, Queue<Completer>> _keyLocks = {};
  bool _monitoringEnabled = true;

  CacheConcurrencyController({
    int maxConcurrentOperations = 100,
  })  : _maxConcurrentOperations = maxConcurrentOperations,
        _semaphore = Semaphore(maxConcurrentOperations);

  /// 执行缓存操作
  Future<T> execute<T>(
    Future<T> Function() operation, {
    required CacheOperationType operationType,
    String? key,
    List<String>? keys,
  }) async {
    // 1. 获取全局信号量
    await _semaphore.acquire();

    try {
      // 2. 如果有键级锁，获取键锁
      if (key != null) {
        await _acquireKeyLock(key);
      } else if (keys != null && keys.isNotEmpty) {
        for (final k in keys) {
          await _acquireKeyLock(k);
        }
      }

      // 3. 执行操作
      final result = await operation();
      return result;
    } finally {
      // 4. 释放资源
      if (key != null) {
        _releaseKeyLock(key);
      } else if (keys != null && keys.isNotEmpty) {
        for (final k in keys) {
          _releaseKeyLock(k);
        }
      }

      _semaphore.release();
    }
  }

  /// 获取键级锁
  Future<void> _acquireKeyLock(String key) async {
    final completer = Completer<void>();
    final lockQueue = _keyLocks.putIfAbsent(key, () => Queue());
    lockQueue.add(completer);

    // 如果是第一个等待者，立即完成
    if (lockQueue.length == 1) {
      completer.complete();
    }

    await completer.future;
  }

  /// 释放键级锁
  void _releaseKeyLock(String key) {
    final lockQueue = _keyLocks[key];
    if (lockQueue == null || lockQueue.isEmpty) return;

    // 移除第一个等待者
    lockQueue.removeFirst();

    // 完成下一个等待者
    if (lockQueue.isNotEmpty) {
      lockQueue.first.complete();
    }

    // 如果队列为空，清理键锁
    if (lockQueue.isEmpty) {
      _keyLocks.remove(key);
    }
  }

  /// 设置监控启用状态
  void setMonitoringEnabled(bool enabled) {
    _monitoringEnabled = enabled;
  }

  /// 获取并发统计
  ConcurrencyStats getStats() {
    return ConcurrencyStats(
      currentAvailablePermits: _semaphore.availablePermits,
      maxPermits: _maxConcurrentOperations,
      activeKeyLocks: _keyLocks.length,
      queuedOperations: _keyLocks.values
          .map((queue) => queue.length)
          .fold(0, (sum, count) => sum + count),
    );
  }
}

/// 信号量实现
class Semaphore {
  final int maxPermits;
  int _availablePermits;
  final Queue<Completer<void>> _waitQueue = Queue();

  Semaphore(this.maxPermits) : _availablePermits = maxPermits;

  int get availablePermits => _availablePermits;

  Future<void> acquire() async {
    if (_availablePermits > 0) {
      _availablePermits--;
      return;
    }

    final completer = Completer<void>();
    _waitQueue.add(completer);
    return completer.future;
  }

  void release() {
    if (_waitQueue.isNotEmpty) {
      final completer = _waitQueue.removeFirst();
      completer.complete();
    } else {
      _availablePermits = math.min(_availablePermits + 1, maxPermits);
    }
  }
}

/// 并发统计
class ConcurrencyStats {
  final int currentAvailablePermits;
  final int maxPermits;
  final int activeKeyLocks;
  final int queuedOperations;

  const ConcurrencyStats({
    required this.currentAvailablePermits,
    required this.maxPermits,
    required this.activeKeyLocks,
    required this.queuedOperations,
  });

  double get utilizationRate => 1.0 - (currentAvailablePermits / maxPermits);

  @override
  String toString() {
    return 'ConcurrencyStats(permits: $currentAvailablePermits/$maxPermits, '
        'keyLocks: $activeKeyLocks, queued: $queuedOperations, '
        'utilization: ${(utilizationRate * 100).toStringAsFixed(1)}%)';
  }
}

/// 缓存操作类型
enum CacheOperationType {
  get,
  put,
  batchGet,
  batchPut,
  exists,
  isExpired,
  remove,
  batchRemove,
  patternRemove,
  clear,
  clearExpired,
  updateConfig,
  preload,
  optimize,
}

// ============================================================================
// 维护调度器
// ============================================================================

/// 缓存维护调度器
///
/// 负责调度定期的缓存维护任务
class CacheMaintenanceScheduler {
  Timer? _timer;
  Duration _interval = const Duration(minutes: 5);
  Function()? _maintenanceCallback;

  /// 启动维护调度器
  void start(Function() maintenanceCallback, {Duration? interval}) {
    _maintenanceCallback = maintenanceCallback;
    if (interval != null) {
      _interval = interval;
    }

    _timer = Timer.periodic(_interval, (_) {
      _performMaintenance();
    });
  }

  /// 停止维护调度器
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// 设置维护间隔
  void setInterval(Duration interval) {
    _interval = interval;
    if (_timer != null) {
      stop();
      start(_maintenanceCallback!);
    }
  }

  /// 手动触发维护
  void triggerMaintenance() {
    _performMaintenance();
  }

  void _performMaintenance() {
    try {
      _maintenanceCallback?.call();
    } catch (e) {
      print('Maintenance task failed: $e');
    }
  }
}

// ============================================================================
// 缓存优化器
// ============================================================================

/// 缓存优化器
///
/// 提供各种缓存优化功能
class CacheOptimizer {
  final CacheMetricsCollector _metricsCollector;

  CacheOptimizer(this._metricsCollector);

  /// 执行全面优化
  Future<OptimizationResult> performFullOptimization() async {
    final result = OptimizationResult();

    try {
      // 1. 清理过期缓存
      final expiredCleanup = await _cleanupExpiredCache();
      result.expiredItemsRemoved = expiredCleanup;

      // 2. 优化缓存策略
      final strategyOptimization = await _optimizeCacheStrategies();
      result.strategyOptimizations = strategyOptimization;

      // 3. 压缩缓存数据
      final compressionOptimization = await _optimizeCompression();
      result.compressionSavings = compressionOptimization;

      // 4. 重新组织缓存结构
      final reorganization = await _reorganizeCache();
      result.itemsReorganized = reorganization;

      result.success = true;
    } catch (e) {
      result.success = false;
      result.error = e.toString();
    }

    return result;
  }

  /// 清理过期缓存
  Future<int> _cleanupExpiredCache() async {
    // 这里需要实际的缓存管理器引用
    // 为了避免循环依赖，使用接口
    return 0; // 简化实现
  }

  /// 优化缓存策略
  Future<int> _optimizeCacheStrategies() async {
    final metrics = _metricsCollector.getLatestMetrics();
    int optimizations = 0;

    // 分析命中率低的数据
    final accessPatterns = _metricsCollector.accessPatterns;
    for (final entry in accessPatterns.entries) {
      if (entry.value.hitRate < 0.3) {
        // 建议调整这些数据的缓存策略
        optimizations++;
      }
    }

    return optimizations;
  }

  /// 优化压缩
  Future<int> _optimizeCompression() async {
    final metrics = _metricsCollector.getLatestMetrics();
    int savings = 0;

    // 分析未压缩的大数据
    final sizePatterns = _metricsCollector.sizePatterns;
    for (final entry in sizePatterns.entries) {
      if (entry.value.averageSize > 10240 && !entry.value.compressed) {
        // >10KB 且未压缩
        // 建议压缩这些数据
        savings += (entry.value.averageSize * 0.3).round(); // 假设30%压缩率
      }
    }

    return savings;
  }

  /// 重新组织缓存
  Future<int> _reorganizeCache() async {
    // 重新组织缓存以提高访问效率
    return 0; // 简化实现
  }
}

/// 优化结果
class OptimizationResult {
  bool success = false;
  String? error;
  int expiredItemsRemoved = 0;
  int strategyOptimizations = 0;
  int compressionSavings = 0;
  int itemsReorganized = 0;
  Duration? executionTime;

  @override
  String toString() {
    if (!success) {
      return 'OptimizationResult(failed: $error)';
    }

    return 'OptimizationResult('
        'expired: $expiredItemsRemoved, '
        'strategies: $strategyOptimizations, '
        'compression: ${compressionSavings}B, '
        'reorganized: $itemsReorganized, '
        'time: ${executionTime?.inMilliseconds ?? 0}ms)';
  }
}

// ============================================================================
// 缓存指标收集器
// ============================================================================

/// 缓存指标收集器
///
/// 收集和分析缓存性能指标
class CacheMetricsCollector {
  final Queue<CacheMetricsSnapshot> _snapshots = Queue();
  final Map<String, AccessPattern> _accessPatterns = {};
  final Map<String, SizePattern> _sizePatterns = {};

  /// 收集指标快照
  void collectSnapshot(
      CacheStatistics stats, Map<String, dynamic> additionalData) {
    final snapshot = CacheMetricsSnapshot(
      timestamp: DateTime.now(),
      statistics: stats,
      additionalData: additionalData,
    );

    _snapshots.add(snapshot);
    _maintainSnapshotLimit();
    _analyzeSnapshot(snapshot);
  }

  /// 记录访问模式
  void recordAccess(String key, bool hit, int responseTime) {
    final pattern = _accessPatterns.putIfAbsent(
      _extractPattern(key),
      () => AccessPattern(),
    );

    pattern.recordAccess(hit, responseTime);
  }

  /// 记录大小模式
  void recordSize(String key, int size, bool compressed) {
    final pattern = _sizePatterns.putIfAbsent(
      _extractPattern(key),
      () => SizePattern(),
    );

    pattern.recordSize(size, compressed);
  }

  /// 获取最新指标
  CacheMetricsSnapshot? getLatestMetrics() {
    return _snapshots.isNotEmpty ? _snapshots.last : null;
  }

  /// 获取访问模式
  Map<String, AccessPattern> get accessPatterns =>
      Map.unmodifiable(_accessPatterns);

  /// 获取大小模式
  Map<String, SizePattern> get sizePatterns => Map.unmodifiable(_sizePatterns);

  /// 获取性能趋势
  List<CacheMetricsSnapshot> getPerformanceTrend({Duration? period}) {
    if (period == null) {
      return _snapshots.toList();
    }

    final cutoff = DateTime.now().subtract(period);
    return _snapshots
        .where((snapshot) => snapshot.timestamp.isAfter(cutoff))
        .toList();
  }

  void _maintainSnapshotLimit() {
    while (_snapshots.length > 1000) {
      _snapshots.removeFirst();
    }
  }

  void _analyzeSnapshot(CacheMetricsSnapshot snapshot) {
    // 分析快照并提取模式
    final additionalData = snapshot.additionalData;

    if (additionalData.containsKey('operation_details')) {
      // 分析操作详情
    }
  }

  String _extractPattern(String key) {
    // 简化的模式提取
    if (key.startsWith('search_')) return 'search_*';
    if (key.startsWith('filter_')) return 'filter_*';
    if (key.startsWith('user_')) return 'user_*';
    if (key.startsWith('fund_')) return 'fund_*';
    return 'other_*';
  }
}

/// 缓存指标快照
class CacheMetricsSnapshot {
  final DateTime timestamp;
  final CacheStatistics statistics;
  final Map<String, dynamic> additionalData;

  const CacheMetricsSnapshot({
    required this.timestamp,
    required this.statistics,
    required this.additionalData,
  });
}

/// 访问模式
class AccessPattern {
  int totalAccesses = 0;
  int hits = 0;
  int totalResponseTime = 0;
  final List<int> responseTimes = [];

  void recordAccess(bool hit, int responseTime) {
    totalAccesses++;
    if (hit) hits++;
    totalResponseTime += responseTime;
    responseTimes.add(responseTime);

    // 保持响应时间列表在合理范围内
    if (responseTimes.length > 1000) {
      responseTimes.removeRange(0, responseTimes.length - 1000);
    }
  }

  double get hitRate => totalAccesses > 0 ? hits / totalAccesses : 0.0;
  double get averageResponseTime =>
      totalAccesses > 0 ? totalResponseTime / totalAccesses : 0.0;

  double get p95ResponseTime {
    if (responseTimes.isEmpty) return 0.0;
    final sorted = List<int>.from(responseTimes)..sort();
    final index = (sorted.length * 0.95).floor().clamp(0, sorted.length - 1);
    return sorted[index].toDouble();
  }
}

/// 大小模式
class SizePattern {
  final List<int> sizes = [];
  int compressedCount = 0;
  int totalCount = 0;

  void recordSize(int size, bool compressed) {
    sizes.add(size);
    if (compressed) compressedCount++;
    totalCount++;

    // 保持大小列表在合理范围内
    if (sizes.length > 1000) {
      sizes.removeRange(0, sizes.length - 1000);
    }
  }

  double get averageSize =>
      sizes.isNotEmpty ? sizes.reduce((a, b) => a + b) / sizes.length : 0.0;

  double get compressionRatio =>
      totalCount > 0 ? compressedCount / totalCount : 0.0;

  bool get compressed => compressedCount > 0;
}
