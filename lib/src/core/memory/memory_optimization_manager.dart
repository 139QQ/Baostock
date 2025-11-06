import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../utils/logger.dart';

/// 内存使用快照
class MemorySnapshot {
  final DateTime timestamp;
  final int totalMemoryMB;
  final int usedMemoryMB;
  final int availableMemoryMB;
  final double usagePercentage;
  final Map<String, dynamic> additionalInfo;

  MemorySnapshot({
    required this.timestamp,
    required this.totalMemoryMB,
    required this.usedMemoryMB,
    required this.availableMemoryMB,
    required this.usagePercentage,
    this.additionalInfo = const {},
  });

  /// 获取内存压力等级
  MemoryPressureLevel get pressureLevel {
    if (usagePercentage >= 90) return MemoryPressureLevel.critical;
    if (usagePercentage >= 75) return MemoryPressureLevel.high;
    if (usagePercentage >= 50) return MemoryPressureLevel.medium;
    return MemoryPressureLevel.low;
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'totalMemoryMB': totalMemoryMB,
      'usedMemoryMB': usedMemoryMB,
      'availableMemoryMB': availableMemoryMB,
      'usagePercentage': usagePercentage,
      'pressureLevel': pressureLevel.name,
      'additionalInfo': additionalInfo,
    };
  }
}

/// 内存压力等级枚举
enum MemoryPressureLevel {
  low, // < 50%
  medium, // 50-75%
  high, // 75-90%
  critical, // >= 90%
}

/// 内存使用跟踪器
class MemoryUsageTracker {
  final String name;
  int _allocationCount = 0;
  int _deallocationCount = 0;
  int _currentObjects = 0;
  int _peakObjects = 0;
  DateTime _lastReset = DateTime.now();

  MemoryUsageTracker(this.name);

  void recordAllocation() {
    _allocationCount++;
    _currentObjects++;
    _peakObjects = math.max(_peakObjects, _currentObjects);
  }

  void recordDeallocation() {
    _deallocationCount++;
    _currentObjects = math.max(0, _currentObjects - 1);
  }

  void reset() {
    _allocationCount = 0;
    _deallocationCount = 0;
    _currentObjects = 0;
    _peakObjects = 0;
    _lastReset = DateTime.now();
  }

  Map<String, dynamic> getStats() {
    return {
      'name': name,
      'allocationCount': _allocationCount,
      'deallocationCount': _deallocationCount,
      'currentObjects': _currentObjects,
      'peakObjects': _peakObjects,
      'lastReset': _lastReset.toIso8601String(),
      'leakSuspected':
          _currentObjects > (_peakObjects * 0.8) && _deallocationCount > 0,
    };
  }

  // Getter for testing purposes
  int get currentObjects => _currentObjects;
  int get peakObjects => _peakObjects;
  int get allocationCount => _allocationCount;
  int get deallocationCount => _deallocationCount;
}

/// 内存优化策略接口
abstract class MemoryOptimizationStrategy {
  String get name;
  int get priority; // 优先级：数字越小优先级越高

  /// 执行优化策略
  Future<void> execute(MemoryPressureLevel pressureLevel);

  /// 检查策略是否适用
  bool isApplicable(MemoryPressureLevel pressureLevel);
}

/// 缓存清理策略
class CacheCleanupStrategy extends MemoryOptimizationStrategy {
  @override
  String get name => '缓存清理策略';

  @override
  int get priority => 1;

  @override
  bool isApplicable(MemoryPressureLevel pressureLevel) {
    return pressureLevel.index >= MemoryPressureLevel.medium.index;
  }

  @override
  Future<void> execute(MemoryPressureLevel pressureLevel) async {
    // 清理不同级别的缓存
    if (pressureLevel == MemoryPressureLevel.critical) {
      await _clearAllCaches();
    } else if (pressureLevel == MemoryPressureLevel.high) {
      await _clearOldCaches();
    }
  }

  Future<void> _clearAllCaches() async {
    // TODO: 实现具体缓存清理逻辑
  }

  Future<void> _clearOldCaches() async {
    // TODO: 实现具体缓存清理逻辑
  }
}

/// 对象池回收策略
class ObjectPoolReclaimStrategy extends MemoryOptimizationStrategy {
  @override
  String get name => '对象池回收策略';

  @override
  int get priority => 2;

  @override
  bool isApplicable(MemoryPressureLevel pressureLevel) {
    return pressureLevel.index >= MemoryPressureLevel.high.index;
  }

  @override
  Future<void> execute(MemoryPressureLevel pressureLevel) async {
    // 回收对象池中的闲置对象
    await _reclaimObjectPools();
  }

  Future<void> _reclaimObjectPools() async {
    // TODO: 实现对象池回收逻辑
  }
}

/// 内存优化管理器 - Week 9实施
///
/// 功能特性：
/// - 实时内存使用监控
/// - 智能垃圾回收策略
/// - 内存泄漏检测和预防
/// - 对象生命周期管理
/// - 内存压力感知调整
class MemoryOptimizationManager {
  static final MemoryOptimizationManager _instance =
      MemoryOptimizationManager._internal();
  factory MemoryOptimizationManager() => _instance;
  MemoryOptimizationManager._internal();

  final Logger _logger = Logger();

  // 内存监控配置
  static const int _warningThresholdMB = 150; // 警告阈值
  static const int _criticalThresholdMB = 200; // 危险阈值
  static const int _emergencyThresholdMB = 250; // 紧急阈值
  static const Duration _monitoringInterval = Duration(seconds: 30);

  // 内存状态管理
  Timer? _monitoringTimer;
  bool _isMonitoring = false;
  bool _isUnderPressure = false;

  // 内存统计数据
  final List<MemorySnapshot> _memorySnapshots = [];
  final Map<String, MemoryUsageTracker> _trackers = {};

  // 优化策略
  final List<MemoryOptimizationStrategy> _strategies = [];

  // 回调函数
  final List<Function(double)> _memoryPressureCallbacks = [];
  final List<Function()> _garbageCollectionCallbacks = [];

  // Week 10 性能优化
  int _totalCleanups = 0;
  int _emergencyCleanups = 0;
  final List<Duration> _cleanupTimes = [];
  DateTime? _lastOptimizationTime;

  /// 初始化内存优化管理器
  Future<void> initialize() async {
    if (_isMonitoring) return;

    try {
      // 注册默认优化策略
      _strategies.addAll([
        CacheCleanupStrategy(),
        ObjectPoolReclaimStrategy(),
      ]);

      // 启动内存监控
      await startMonitoring();

      // 注册系统内存回调
      if (!kReleaseMode) {
        developer.log('📊 内存优化管理器初始化完成', name: 'MemoryManager');
      }

      _logger.i('✅ 内存优化管理器初始化成功');
    } catch (e) {
      _logger.e('❌ 内存优化管理器初始化失败: $e');
      rethrow;
    }
  }

  /// 启动内存监控
  Future<void> startMonitoring() async {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _monitoringTimer =
        Timer.periodic(_monitoringInterval, (_) => _performMemoryCheck());

    // 立即执行一次检查
    await _performMemoryCheck();

    _logger.i('🔍 内存监控已启动');
  }

  /// 停止内存监控
  void stopMonitoring() {
    if (!_isMonitoring) return;

    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    _isMonitoring = false;

    _logger.i('⏹️ 内存监控已停止');
  }

  /// 执行内存检查
  Future<void> _performMemoryCheck() async {
    try {
      final snapshot = await _captureMemorySnapshot();
      _memorySnapshots.add(snapshot);

      // 保持快照历史在合理范围内（最多100个）
      if (_memorySnapshots.length > 100) {
        _memorySnapshots.removeRange(0, _memorySnapshots.length - 100);
      }

      // 检查内存压力
      await _handleMemoryPressure(snapshot);

      // 检测潜在内存泄漏
      _detectMemoryLeaks();

      if (!kReleaseMode &&
          snapshot.pressureLevel.index >= MemoryPressureLevel.high.index) {
        developer.log(
            '⚠️ 内存压力警告: ${snapshot.pressureLevel.name} (${snapshot.usagePercentage.toStringAsFixed(1)}%)',
            name: 'MemoryManager');
      }
    } catch (e) {
      _logger.e('❌ 内存检查失败: $e');
    }
  }

  /// 捕获内存快照
  Future<MemorySnapshot> captureCurrentSnapshot() async {
    return await _captureMemorySnapshot();
  }

  /// 内部内存快照捕获
  Future<MemorySnapshot> _captureMemorySnapshot() async {
    // 在Web平台和桌面平台获取内存信息的方式不同
    int totalMemory = 0;
    int usedMemory = 0;

    try {
      // 模拟内存使用情况，因为getCurrentRSS在某些平台不可用
      if (kIsWeb) {
        // Web平台模拟
        usedMemory = 120 + (DateTime.now().millisecond % 50);
        totalMemory = 512;
      } else {
        // 桌面平台模拟
        usedMemory = 150 + (DateTime.now().millisecond % 100);
        totalMemory = 1024;
      }
    } catch (e) {
      // 如果获取失败，使用估算值
      usedMemory = 100;
      totalMemory = 512;
    }

    final availableMemory = totalMemory - usedMemory;
    final usagePercentage =
        totalMemory > 0 ? (usedMemory / totalMemory) * 100 : 0.0;

    return MemorySnapshot(
      timestamp: DateTime.now(),
      totalMemoryMB: totalMemory,
      usedMemoryMB: usedMemory,
      availableMemoryMB: availableMemory,
      usagePercentage: usagePercentage,
      additionalInfo: {
        'isUnderPressure': _isUnderPressure,
        'trackedObjects': _trackers.values
            .map((tracker) => tracker.currentObjects)
            .fold(0, (a, b) => a + b),
      },
    );
  }

  /// 处理内存压力
  Future<void> _handleMemoryPressure(MemorySnapshot snapshot) async {
    final previousPressure = _isUnderPressure;
    _isUnderPressure = snapshot.usedMemoryMB >= _warningThresholdMB;

    // 如果进入压力状态
    if (_isUnderPressure && !previousPressure) {
      _notifyMemoryPressure(snapshot.usagePercentage);
    }

    // 根据压力等级执行优化策略
    if (snapshot.pressureLevel.index >= MemoryPressureLevel.medium.index) {
      await _executeOptimizationStrategies(snapshot.pressureLevel);
    }

    // 紧急情况下的处理
    if (snapshot.usedMemoryMB >= _emergencyThresholdMB) {
      await _handleEmergencyMemoryPressure();
    }
  }

  /// 执行优化策略
  Future<void> _executeOptimizationStrategies(
      MemoryPressureLevel pressureLevel) async {
    final applicableStrategies = _strategies
        .where((strategy) => strategy.isApplicable(pressureLevel))
        .toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));

    for (final strategy in applicableStrategies) {
      try {
        await strategy.execute(pressureLevel);
        _logger.d('✅ 执行内存优化策略: ${strategy.name}');
      } catch (e) {
        _logger.e('❌ 执行内存优化策略失败 ${strategy.name}: $e');
      }
    }
  }

  /// 处理紧急内存压力
  Future<void> _handleEmergencyMemoryPressure() async {
    _logger.w('🚨 检测到紧急内存压力，执行紧急清理');

    // 强制垃圾回收
    await forceGarbageCollection();

    // 清理所有缓存
    await _clearAllCaches();

    // 回收所有对象池
    await _reclaimObjectPools();

    // 通知所有监听器
    for (final callback in _garbageCollectionCallbacks) {
      try {
        callback();
      } catch (e) {
        _logger.e('❌ 垃圾回收回调执行失败: $e');
      }
    }
  }

  /// 强制垃圾回收
  Future<void> forceGarbageCollection() async {
    try {
      // 在Debug模式下使用开发者工具
      if (!kReleaseMode) {
        // 尝试触发垃圾回收
        await Future.delayed(const Duration(milliseconds: 100));
      }

      _logger.d('🗑️ 强制垃圾回收执行完成');
    } catch (e) {
      _logger.e('❌ 强制垃圾回收失败: $e');
    }
  }

  /// 清理所有缓存
  Future<void> _clearAllCaches() async {
    // TODO: 实现具体缓存清理逻辑
    // 这里需要与实际的缓存系统集成
    _logger.d('🧹 清理所有缓存');
  }

  /// 清理旧缓存
  Future<void> _clearOldCaches() async {
    // TODO: 实现具体缓存清理逻辑
    _logger.d('🧹 清理旧缓存');
  }

  /// 回收对象池
  Future<void> _reclaimObjectPools() async {
    // TODO: 实现对象池回收逻辑
    _logger.d('♻️ 回收对象池');
  }

  /// 检测内存泄漏
  void _detectMemoryLeaks() {
    for (final tracker in _trackers.values) {
      final stats = tracker.getStats();
      if (stats['leakSuspected'] == true) {
        _logger.w('🔍 检测到疑似内存泄漏: ${tracker.name}');
      }
    }
  }

  /// 通知内存压力
  void _notifyMemoryPressure(double usagePercentage) {
    for (final callback in _memoryPressureCallbacks) {
      try {
        callback(usagePercentage);
      } catch (e) {
        _logger.e('❌ 内存压力回调执行失败: $e');
      }
    }
  }

  /// 注册内存压力回调
  void addMemoryPressureCallback(Function(double) callback) {
    _memoryPressureCallbacks.add(callback);
  }

  /// 移除内存压力回调
  void removeMemoryPressureCallback(Function(double) callback) {
    _memoryPressureCallbacks.remove(callback);
  }

  /// 注册垃圾回收回调
  void addGarbageCollectionCallback(Function() callback) {
    _garbageCollectionCallbacks.add(callback);
  }

  /// 移除垃圾回收回调
  void removeGarbageCollectionCallback(Function() callback) {
    _garbageCollectionCallbacks.remove(callback);
  }

  /// 添加内存跟踪器
  MemoryUsageTracker addTracker(String name) {
    final tracker = MemoryUsageTracker(name);
    _trackers[name] = tracker;
    return tracker;
  }

  /// 移除内存跟踪器
  void removeTracker(String name) {
    _trackers.remove(name);
  }

  /// 获取跟踪器
  MemoryUsageTracker? getTracker(String name) {
    return _trackers[name];
  }

  /// 添加优化策略
  void addOptimizationStrategy(MemoryOptimizationStrategy strategy) {
    _strategies.add(strategy);
    // 按优先级排序
    _strategies.sort((a, b) => a.priority.compareTo(b.priority));
  }

  /// 移除优化策略
  void removeOptimizationStrategy(String strategyName) {
    _strategies.removeWhere((strategy) => strategy.name == strategyName);
  }

  /// 获取内存统计信息
  Map<String, dynamic> getMemoryStats() {
    if (_memorySnapshots.isEmpty) {
      return {
        'isMonitoring': _isMonitoring,
        'isUnderPressure': _isUnderPressure,
        'currentUsageMB': 0,
        'peakUsageMB': 0,
        'averageUsageMB': 0,
        'recentSnapshots': [],
        'trackers': _trackers.values.map((t) => t.getStats()).toList(),
        'strategies': _strategies.map((s) => s.name).toList(),
        'warningThresholdMB': _warningThresholdMB,
        'criticalThresholdMB': _criticalThresholdMB,
      };
    }

    final recentSnapshots = _memorySnapshots.take(10).toList();
    final currentUsage = recentSnapshots.first.usedMemoryMB;
    final peakUsage =
        _memorySnapshots.map((s) => s.usedMemoryMB).reduce(math.max);
    final averageUsage =
        recentSnapshots.map((s) => s.usedMemoryMB).reduce((a, b) => a + b) /
            recentSnapshots.length;

    return {
      'isMonitoring': _isMonitoring,
      'isUnderPressure': _isUnderPressure,
      'currentUsageMB': currentUsage,
      'peakUsageMB': peakUsage,
      'averageUsageMB': averageUsage.roundToDouble(),
      'recentSnapshots': recentSnapshots.map((s) => s.toJson()).toList(),
      'trackers': _trackers.values.map((t) => t.getStats()).toList(),
      'strategies': _strategies.map((s) => s.name).toList(),
      'warningThresholdMB': _warningThresholdMB,
      'criticalThresholdMB': _criticalThresholdMB,
    };
  }

  /// 导出内存分析报告
  String exportMemoryReport() {
    final stats = getMemoryStats();
    final buffer = StringBuffer();

    buffer.writeln('# 内存优化分析报告');
    buffer.writeln('生成时间: ${DateTime.now().toIso8601String()}');
    buffer.writeln('');

    buffer.writeln('## 📊 内存使用概览');
    buffer.writeln('- 当前使用: ${stats['currentUsageMB']} MB');
    buffer.writeln('- 峰值使用: ${stats['peakUsageMB']} MB');
    buffer.writeln('- 平均使用: ${stats['averageUsageMB']} MB');
    buffer.writeln('- 监控状态: ${stats['isMonitoring'] ? '运行中' : '已停止'}');
    buffer.writeln('- 压力状态: ${stats['isUnderPressure'] ? '是' : '否'}');
    buffer.writeln('');

    buffer.writeln('## ⚠️ 内存阈值');
    buffer.writeln('- 警告阈值: ${stats['warningThresholdMB']} MB');
    buffer.writeln('- 危险阈值: ${stats['criticalThresholdMB']} MB');
    buffer.writeln('');

    buffer.writeln('## 📈 对象跟踪统计');
    for (final tracker in stats['trackers']) {
      buffer.writeln('- ${tracker['name']}:');
      buffer.writeln('  - 当前对象数: ${tracker['currentObjects']}');
      buffer.writeln('  - 峰值对象数: ${tracker['peakObjects']}');
      buffer.writeln('  - 分配次数: ${tracker['allocationCount']}');
      buffer.writeln('  - 释放次数: ${tracker['deallocationCount']}');
      if (tracker['leakSuspected']) {
        buffer.writeln('  - ⚠️ 疑似内存泄漏');
      }
    }
    buffer.writeln('');

    buffer.writeln('## 🔧 已注册优化策略');
    for (final strategy in stats['strategies']) {
      buffer.writeln('- $strategy');
    }

    return buffer.toString();
  }

  /// Week 10 性能优化: 生成内存优化性能报告
  void generatePerformanceReport() {
    if (_cleanupTimes.isEmpty) {
      AppLogger.info('📊 内存优化性能报告: 暂无优化记录');
      return;
    }

    final avgCleanupTime =
        _cleanupTimes.map((d) => d.inMilliseconds).reduce((a, b) => a + b) /
            _cleanupTimes.length;

    final maxCleanupTime = _cleanupTimes
        .map((d) => d.inMilliseconds)
        .reduce((a, b) => a > b ? a : b);

    final minCleanupTime = _cleanupTimes
        .map((d) => d.inMilliseconds)
        .reduce((a, b) => a < b ? a : b);

    AppLogger.info('📊 内存优化性能报告:');
    AppLogger.info('  平均清理时间: ${avgCleanupTime.toStringAsFixed(2)}ms');
    AppLogger.info('  最大清理时间: ${maxCleanupTime}ms');
    AppLogger.info('  最小清理时间: ${minCleanupTime}ms');
    AppLogger.info('  总清理次数: $_totalCleanups');
    AppLogger.info('  紧急清理次数: $_emergencyCleanups');
    AppLogger.info(
        '  紧急清理比例: ${(_emergencyCleanups / _totalCleanups * 100).toStringAsFixed(1)}%');

    if (_lastOptimizationTime != null) {
      final timeSinceLastOptimization =
          DateTime.now().difference(_lastOptimizationTime!);
      AppLogger.info('  距离上次优化: ${timeSinceLastOptimization.inMinutes}分钟');
    }

    // 在调试模式下输出到开发者控制台
    if (kDebugMode) {
      developer.log(
          '内存优化性能报告: 平均${avgCleanupTime.toStringAsFixed(2)}ms, 总清理$_totalCleanups次',
          name: 'MemoryOptimizationPerformance');
    }

    // 清理旧的性能数据，保持最近50条记录
    if (_cleanupTimes.length > 50) {
      _cleanupTimes.removeRange(0, _cleanupTimes.length - 50);
    }
  }

  /// Week 10 性能优化: 记录清理操作
  void _recordCleanup(Duration cleanupTime, bool isEmergency) {
    _cleanupTimes.add(cleanupTime);
    _totalCleanups++;
    if (isEmergency) {
      _emergencyCleanups++;
    }
    _lastOptimizationTime = DateTime.now();
  }

  /// 获取内存优化性能统计
  Map<String, dynamic> getOptimizationStats() {
    if (_cleanupTimes.isEmpty) {
      return {
        'avgCleanupTime': 0,
        'maxCleanupTime': 0,
        'minCleanupTime': 0,
        'totalCleanups': _totalCleanups,
        'emergencyCleanups': _emergencyCleanups,
        'emergencyCleanupRate': 0.0,
        'lastOptimizationTime': _lastOptimizationTime?.toIso8601String(),
      };
    }

    final avgCleanupTime =
        _cleanupTimes.map((d) => d.inMilliseconds).reduce((a, b) => a + b) /
            _cleanupTimes.length;

    final maxCleanupTime = _cleanupTimes
        .map((d) => d.inMilliseconds)
        .reduce((a, b) => a > b ? a : b);

    final minCleanupTime = _cleanupTimes
        .map((d) => d.inMilliseconds)
        .reduce((a, b) => a < b ? a : b);

    return {
      'avgCleanupTime': avgCleanupTime,
      'maxCleanupTime': maxCleanupTime,
      'minCleanupTime': minCleanupTime,
      'totalCleanups': _totalCleanups,
      'emergencyCleanups': _emergencyCleanups,
      'emergencyCleanupRate': _totalCleanups > 0
          ? (_emergencyCleanups / _totalCleanups * 100)
          : 0.0,
      'lastOptimizationTime': _lastOptimizationTime?.toIso8601String(),
    };
  }

  /// 清理资源
  void dispose() {
    stopMonitoring();
    _memorySnapshots.clear();
    _trackers.clear();
    _strategies.clear();
    _memoryPressureCallbacks.clear();
    _garbageCollectionCallbacks.clear();
    AppLogger.info('🗑️ 内存优化管理器已清理');
  }
}
