import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/services.dart';

import '../../utils/logger.dart';

/// 内存泄漏检测结果
class MemoryLeakDetectionResult {
  final bool hasLeak;
  final double leakScore; // 0-100，越高越可能泄漏
  final String description;
  final Map<String, dynamic> details;
  final DateTime detectionTime;
  final List<String> recommendations;

  MemoryLeakDetectionResult({
    required this.hasLeak,
    required this.leakScore,
    required this.description,
    required this.details,
    required this.detectionTime,
    this.recommendations = const [],
  });
}

/// 内存快照
class MemorySnapshotExtended {
  final DateTime timestamp;
  final int totalMemoryMB;
  final int usedMemoryMB;
  final int heapUsedMB;
  final int heapCapacityMB;
  final int externalMemoryMB;
  final double cpuUsage;
  final int activeObjects;
  final int gcCount;
  final Map<String, int> objectCounts;

  MemorySnapshotExtended({
    required this.timestamp,
    required this.totalMemoryMB,
    required this.usedMemoryMB,
    required this.heapUsedMB,
    required this.heapCapacityMB,
    required this.externalMemoryMB,
    required this.cpuUsage,
    required this.activeObjects,
    required this.gcCount,
    required this.objectCounts,
  });

  double get memoryUsagePercentage =>
      totalMemoryMB > 0 ? usedMemoryMB / totalMemoryMB : 0;
  double get heapUsagePercentage =>
      heapCapacityMB > 0 ? heapUsedMB / heapCapacityMB : 0;

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'totalMemoryMB': totalMemoryMB,
      'usedMemoryMB': usedMemoryMB,
      'heapUsedMB': heapUsedMB,
      'heapCapacityMB': heapCapacityMB,
      'externalMemoryMB': externalMemoryMB,
      'cpuUsage': cpuUsage,
      'activeObjects': activeObjects,
      'gcCount': gcCount,
      'memoryUsagePercentage': memoryUsagePercentage,
      'heapUsagePercentage': heapUsagePercentage,
      'objectCounts': objectCounts,
    };
  }
}

/// 内存泄漏检测配置
class MemoryLeakDetectorConfig {
  final Duration detectionInterval;
  final int snapshotHistorySize;
  final double leakThresholdScore;
  final int consecutiveLeakDetections;
  final bool enableDetailedTracking;
  final bool enableAutoGc;
  final Duration autoGcInterval;

  const MemoryLeakDetectorConfig({
    this.detectionInterval = const Duration(minutes: 5),
    this.snapshotHistorySize = 24, // 24个快照 = 2小时历史
    this.leakThresholdScore = 70.0,
    this.consecutiveLeakDetections = 3,
    this.enableDetailedTracking = true,
    this.enableAutoGc = false,
    this.autoGcInterval = const Duration(minutes: 15),
  });
}

/// 内存泄漏检测器
///
/// 监控应用内存使用模式，检测可能的内存泄漏并提供缓解建议
class MemoryLeakDetector {
  static final MemoryLeakDetector _instance = MemoryLeakDetector._internal();
  factory MemoryLeakDetector() => _instance;
  MemoryLeakDetector._internal();

  // 使用自定义AppLogger静态方法
  MemoryLeakDetectorConfig _config = const MemoryLeakDetectorConfig();

  final List<MemorySnapshotExtended> _snapshots = [];
  Timer? _detectionTimer;
  Timer? _autoGcTimer;
  int _consecutiveLeakCount = 0;
  DateTime? _lastGcTime;

  final StreamController<MemoryLeakDetectionResult> _leakDetectionController =
      StreamController<MemoryLeakDetectionResult>.broadcast();
  Stream<MemoryLeakDetectionResult> get leakDetectionStream =>
      _leakDetectionController.stream;

  /// 配置检测器
  void configure(MemoryLeakDetectorConfig config) {
    _config = config;
    AppLogger.business('配置已更新', 'MemoryLeakDetector');

    // 重启定时器
    if (_detectionTimer != null) {
      _detectionTimer!.cancel();
      _detectionTimer = null;
    }

    if (_autoGcTimer != null) {
      _autoGcTimer!.cancel();
      _autoGcTimer = null;
    }

    _startDetection();
  }

  /// 启动检测器
  void start() {
    if (_detectionTimer != null) return;

    AppLogger.business('启动检测器', 'MemoryLeakDetector');
    _startDetection();
  }

  /// 停止检测器
  Future<void> stop() async {
    AppLogger.business('停止检测器', 'MemoryLeakDetector');

    _detectionTimer?.cancel();
    _detectionTimer = null;

    _autoGcTimer?.cancel();
    _autoGcTimer = null;

    await _leakDetectionController.close();
  }

  /// 手动执行内存泄漏检测
  Future<MemoryLeakDetectionResult> detectLeak() async {
    final snapshot = await _captureMemorySnapshot();
    _addSnapshot(snapshot);
    return _analyzeForLeaks(snapshot);
  }

  /// 强制垃圾回收
  Future<void> forceGarbageCollection() async {
    AppLogger.business('执行强制垃圾回收', 'MemoryLeakDetector');
    _lastGcTime = DateTime.now();

    // 使用现代的GC触发方式
    try {
      // 尝试使用新的GC API（如果可用）
      await SystemChannels.platform.invokeMethod('System.gc');
    } catch (e) {
      // 如果新API不可用，则等待一段时间让系统自然GC
      AppLogger.debug('GC API不可用，使用自然回收方式');
    }

    // 短暂等待GC完成
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// 获取当前内存快照
  Future<MemorySnapshotExtended> getCurrentSnapshot() async {
    return await _captureMemorySnapshot();
  }

  /// 获取历史快照
  List<MemorySnapshotExtended> getSnapshotHistory() {
    return List.unmodifiable(_snapshots);
  }

  /// 获取内存泄漏计数
  int get leakCount => _consecutiveLeakCount;

  /// 检查是否正在监控
  bool get isMonitoring => _detectionTimer?.isActive ?? false;

  /// 获取内存使用趋势
  Map<String, dynamic> getMemoryTrends() {
    if (_snapshots.length < 2) {
      return {'error': '快照数据不足'};
    }

    final recent = _snapshots.take(10).toList(); // 最近10个快照
    final older = _snapshots.skip(10).take(10).toList(); // 之前10个快照

    if (older.isEmpty) {
      return {'error': '历史数据不足'};
    }

    // 计算趋势
    final recentAvg =
        recent.map((s) => s.usedMemoryMB).reduce((a, b) => a + b) /
            recent.length;
    final olderAvg =
        older.map((s) => s.usedMemoryMB).reduce((a, b) => a + b) / older.length;

    final trend = recentAvg - olderAvg;
    final trendPercentage = olderAvg > 0 ? (trend / olderAvg) * 100 : 0;

    return {
      'trendMB': trend.roundToDouble(),
      'trendPercentage': trendPercentage.roundToDouble(),
      'recentAverage': recentAvg.roundToDouble(),
      'olderAverage': olderAvg.roundToDouble(),
      'snapshotCount': _snapshots.length,
      'isIncreasing': trend > 0,
      'severity': trend > 50
          ? 'high'
          : trend > 20
              ? 'medium'
              : 'low',
    };
  }

  /// 启动检测
  void _startDetection() {
    // 启动内存泄漏检测定时器
    _detectionTimer = Timer.periodic(
      _config.detectionInterval,
      (timer) async {
        await _performDetection();
      },
    );

    // 启动自动GC定时器
    if (_config.enableAutoGc) {
      _autoGcTimer = Timer.periodic(
        _config.autoGcInterval,
        (timer) async {
          await forceGarbageCollection();
        },
      );
    }

    AppLogger.business('内存泄漏检测已启动', 'MemoryLeakDetector');
  }

  /// 执行检测
  Future<void> _performDetection() async {
    try {
      final snapshot = await _captureMemorySnapshot();
      _addSnapshot(snapshot);

      final result = _analyzeForLeaks(snapshot);

      if (result.hasLeak) {
        _consecutiveLeakCount++;
        AppLogger.warn(
            '检测到潜在内存泄漏: ${result.description} (分数: ${result.leakScore})');

        _leakDetectionController.add(result);

        // 连续检测到泄漏时的处理
        if (_consecutiveLeakCount >= _config.consecutiveLeakDetections) {
          await _handleConsecutiveLeaks(result);
        }
      } else {
        _consecutiveLeakCount = 0;
      }
    } catch (e) {
      AppLogger.error('内存泄漏检测失败', e);
    }
  }

  /// 处理连续泄漏检测
  Future<void> _handleConsecutiveLeaks(MemoryLeakDetectionResult result) async {
    AppLogger.error('连续检测到内存泄漏 (${_consecutiveLeakCount}次)，执行紧急处理', null,
        StackTrace.current);

    // 执行强制GC
    await forceGarbageCollection();

    // 可以在这里添加更多紧急处理逻辑
    // 例如：通知用户、重启应用、记录详细诊断信息等

    // 重置计数器，避免重复处理
    _consecutiveLeakCount = 0;
  }

  /// 捕获内存快照
  Future<MemorySnapshotExtended> _captureMemorySnapshot() async {
    try {
      // 获取基础内存信息 - 使用现代化方法
      int rss;
      try {
        // 尝试使用新的内存信息获取方式
        final info = await _getMemoryInfo();
        rss = info['rss'] ?? 100 * 1024 * 1024; // 默认100MB
      } catch (e) {
        // 如果获取失败，使用默认值
        rss = 100 * 1024 * 1024; // 100MB
      }
      final totalMemory = 4096; // 假设4GB总内存，实际应该从系统获取

      // 模拟获取更详细的内存信息
      final heapUsed = rss ~/ (1024 * 1024);
      final heapCapacity = (heapUsed * 1.2).round(); // 假设堆容量比使用量大20%
      final externalMemory = math.max(0, heapUsed - heapCapacity);

      // 模拟GC计数和对象计数
      final gcCount = _simulateGcCount();
      final activeObjects = _simulateActiveObjectCount();

      // 模拟对象类型计数
      final objectCounts = _simulateObjectCounts();

      return MemorySnapshotExtended(
        timestamp: DateTime.now(),
        totalMemoryMB: totalMemory,
        usedMemoryMB: rss ~/ (1024 * 1024),
        heapUsedMB: heapUsed,
        heapCapacityMB: heapCapacity,
        externalMemoryMB: externalMemory,
        cpuUsage: _simulateCpuUsage(),
        activeObjects: activeObjects,
        gcCount: gcCount,
        objectCounts: objectCounts,
      );
    } catch (e) {
      AppLogger.error('MemoryLeakDetector: 捕获内存快照失败', e, StackTrace.current);
      // 返回默认快照
      return MemorySnapshotExtended(
        timestamp: DateTime.now(),
        totalMemoryMB: 4096,
        usedMemoryMB: 0,
        heapUsedMB: 0,
        heapCapacityMB: 0,
        externalMemoryMB: 0,
        cpuUsage: 0.0,
        activeObjects: 0,
        gcCount: 0,
        objectCounts: {},
      );
    }
  }

  /// 添加快照到历史记录
  void _addSnapshot(MemorySnapshotExtended snapshot) {
    _snapshots.insert(0, snapshot);

    // 限制历史记录大小
    while (_snapshots.length > _config.snapshotHistorySize) {
      _snapshots.removeLast();
    }
  }

  /// 分析内存泄漏
  MemoryLeakDetectionResult _analyzeForLeaks(
      MemorySnapshotExtended currentSnapshot) {
    final analysis = <String, dynamic>{};
    final recommendations = <String>[];
    double leakScore = 0.0;
    String description = '正常';

    // 1. 检查内存使用率
    if (currentSnapshot.memoryUsagePercentage > 0.9) {
      leakScore += 30;
      recommendations.add('内存使用率过高 (>90%)');
    } else if (currentSnapshot.memoryUsagePercentage > 0.8) {
      leakScore += 20;
      recommendations.add('内存使用率较高 (>80%)');
    }

    // 2. 检查堆内存使用率
    if (currentSnapshot.heapUsagePercentage > 0.95) {
      leakScore += 25;
      recommendations.add('堆内存使用率过高 (>95%)');
    }

    // 3. 检查外部内存
    if (currentSnapshot.externalMemoryMB > 500) {
      leakScore += 15;
      recommendations.add('外部内存使用过多 (>500MB)');
    }

    // 4. 分析内存增长趋势
    if (_snapshots.length >= 5) {
      final recentTrend = _analyzeGrowthTrend();
      if (recentTrend > 50) {
        // 50MB增长
        leakScore += 20;
        recommendations.add('内存持续快速增长');
      } else if (recentTrend > 20) {
        leakScore += 10;
        recommendations.add('内存有增长趋势');
      }
      analysis['recentGrowthTrendMB'] = recentTrend;
    }

    // 5. 检查对象数量异常
    if (_config.enableDetailedTracking && _snapshots.length >= 2) {
      final objectGrowth = _analyzeObjectGrowth();
      if (objectGrowth.isNotEmpty) {
        leakScore += 15;
        recommendations.add('检测到对象数量异常增长');
        analysis['objectGrowth'] = objectGrowth;
      }
    }

    // 6. 检查GC频率
    final gcFrequency = _analyzeGcFrequency();
    if (gcFrequency > 10) {
      // 每分钟超过10次GC
      leakScore += 10;
      recommendations.add('GC频率过高');
    }
    analysis['gcFrequencyPerMinute'] = gcFrequency;

    // 判断是否存在泄漏
    final hasLeak = leakScore >= _config.leakThresholdScore;

    if (hasLeak) {
      description = '检测到潜在内存泄漏';
      if (leakScore >= 80) {
        description += ' (严重)';
      } else if (leakScore >= 60) {
        description += ' (中等)';
      } else {
        description += ' (轻微)';
      }
    }

    analysis['currentSnapshot'] = currentSnapshot.toJson();
    analysis['leakScoreBreakdown'] = {
      'memoryUsage': (leakScore >= 30)
          ? 30
          : (leakScore >= 20)
              ? 20
              : 0,
      'heapUsage':
          (leakScore >= 55 && !recommendations.contains('内存使用率过高')) ? 25 : 0,
      'externalMemory':
          (leakScore >= 70 && !recommendations.contains('内存使用率过高')) ? 15 : 0,
      'growthTrend':
          (leakScore >= 75 && recommendations.contains('内存持续快速增长')) ? 20 : 0,
      'objectGrowth':
          (leakScore >= 85 && recommendations.contains('检测到对象数量异常增长')) ? 15 : 0,
      'gcFrequency':
          (leakScore >= 90 && recommendations.contains('GC频率过高')) ? 10 : 0,
    };

    return MemoryLeakDetectionResult(
      hasLeak: hasLeak,
      leakScore: math.min(100, leakScore),
      description: description,
      details: analysis,
      detectionTime: DateTime.now(),
      recommendations: recommendations,
    );
  }

  /// 分析内存增长趋势
  double _analyzeGrowthTrend() {
    if (_snapshots.length < 3) return 0.0;

    // 计算最近3个快照的平均增长
    final recent = _snapshots.take(3).toList();
    if (recent.length < 3) return 0.0;

    final oldest = recent.last;
    final newest = recent.first;

    return (newest.usedMemoryMB - oldest.usedMemoryMB).toDouble();
  }

  /// 分析对象增长
  Map<String, int> _analyzeObjectGrowth() {
    if (_snapshots.length < 2) return {};

    final current = _snapshots.first;
    final previous = _snapshots[1];

    final growth = <String, int>{};

    for (final entry in current.objectCounts.entries) {
      final objectType = entry.key;
      final currentCount = entry.value;
      final previousCount = previous.objectCounts[objectType] ?? 0;

      if (currentCount > previousCount * 1.5) {
        // 增长超过50%
        growth[objectType] = currentCount - previousCount;
      }
    }

    return growth;
  }

  /// 分析GC频率
  double _analyzeGcFrequency() {
    if (_snapshots.length < 2) return 0.0;

    final current = _snapshots.first;
    final previous = _snapshots.last;

    final timeDiffMinutes =
        current.timestamp.difference(previous.timestamp).inMinutes;
    final gcDiff = current.gcCount - previous.gcCount;

    return timeDiffMinutes > 0 ? gcDiff / timeDiffMinutes : 0.0;
  }

  // 模拟方法（在实际应用中应该从系统获取真实数据）
  int _simulateGcCount() {
    return math.Random().nextInt(100) + 10;
  }

  int _simulateActiveObjectCount() {
    return math.Random().nextInt(10000) + 1000;
  }

  double _simulateCpuUsage() {
    return math.Random().nextDouble() * 100;
  }

  Map<String, int> _simulateObjectCounts() {
    return {
      'String': math.Random().nextInt(5000) + 1000,
      'List': math.Random().nextInt(2000) + 500,
      'Map': math.Random().nextInt(1000) + 200,
      'Timer': math.Random().nextInt(100) + 10,
      'StreamSubscription': math.Random().nextInt(50) + 5,
      'Isolate': math.Random().nextInt(10) + 1,
    };
  }

  /// 获取检测器统计信息
  Map<String, dynamic> getStatistics() {
    return {
      'isRunning': _detectionTimer != null,
      'snapshotCount': _snapshots.length,
      'consecutiveLeakCount': _consecutiveLeakCount,
      'lastGcTime': _lastGcTime?.toIso8601String(),
      'config': {
        'detectionInterval': _config.detectionInterval.inMinutes,
        'snapshotHistorySize': _config.snapshotHistorySize,
        'leakThresholdScore': _config.leakThresholdScore,
        'consecutiveLeakDetections': _config.consecutiveLeakDetections,
        'enableDetailedTracking': _config.enableDetailedTracking,
        'enableAutoGc': _config.enableAutoGc,
      },
      'memoryTrends': getMemoryTrends(),
    };
  }

  /// 获取内存信息（现代化方法）
  Future<Map<String, int>> _getMemoryInfo() async {
    try {
      // 在实际项目中，这里应该使用平台特定的API获取内存信息
      // 由于getCurrentRSS已弃用，我们使用模拟数据

      // 模拟基础内存信息（单位：字节）
      return {
        'rss': 100 * 1024 * 1024, // 100MB
        'totalMemory': 4 * 1024 * 1024 * 1024, // 4GB
      };
    } catch (e) {
      AppLogger.error('MemoryLeakDetector: 获取内存信息失败', e, StackTrace.current);
      return {
        'rss': 100 * 1024 * 1024, // 默认100MB
      };
    }
  }
}
