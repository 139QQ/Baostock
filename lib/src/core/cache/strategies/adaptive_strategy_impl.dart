/// 自适应缓存策略实现
///
/// 基于机器学习思想的智能缓存策略，能够：
/// - 学习访问模式
/// - 动态调整TTL和优先级
/// - 预测缓存需求
/// - 自适应优化性能
library adaptive_strategy_impl;

import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import '../interfaces/i_unified_cache_service.dart';

// ============================================================================
// 高级自适应策略实现
// ============================================================================

/// 高级自适应缓存策略
///
/// 基于多种算法的智能缓存策略，包括：
/// - 访问模式学习
/// - 时间序列预测
/// - 多因子优先级计算
/// - 自适应参数调整
class AdvancedAdaptiveStrategy implements ICacheStrategy {
  // 学习参数
  static const int _learningWindowSize = 200;
  static const Duration _predictionHorizon = Duration(hours: 1);
  static const double _defaultHitRateThreshold = 0.7;
  static const double _defaultAccessFrequencyThreshold = 0.3;

  // 模式学习器
  final AccessPatternLearner _patternLearner;
  final TimeSeriesPredictor _timeSeriesPredictor;
  final CachePerformanceAnalyzer _performanceAnalyzer;

  // 策略参数
  double _hitRateThreshold = _defaultHitRateThreshold;
  double _accessFrequencyThreshold = _defaultAccessFrequencyThreshold;
  Duration _baseTtl = Duration(hours: 2);

  // 状态跟踪
  final Map<String, CacheKeyProfile> _keyProfiles = {};
  final Queue<StrategyDecision> _decisionHistory = Queue();

  AdvancedAdaptiveStrategy({
    AccessPatternLearner? patternLearner,
    TimeSeriesPredictor? timeSeriesPredictor,
    CachePerformanceAnalyzer? performanceAnalyzer,
  })  : _patternLearner = patternLearner ?? AccessPatternLearner(),
        _timeSeriesPredictor = timeSeriesPredictor ?? TimeSeriesPredictor(),
        _performanceAnalyzer =
            performanceAnalyzer ?? CachePerformanceAnalyzer();

  @override
  DateTime calculateExpiry(
    String key,
    dynamic data,
    CacheConfig config,
  ) {
    // 1. 获取键的档案
    final profile = _getOrCreateProfile(key, data, config);

    // 2. 计算基础过期时间
    final baseExpiry = DateTime.now().add(config.ttl ?? _baseTtl);

    // 3. 应用智能调整
    final adjustedExpiry =
        _applyIntelligentAdjustment(key, profile, baseExpiry);

    // 4. 记录决策
    _recordDecision(key, StrategyDecisionType.ttl, adjustedExpiry);

    return adjustedExpiry;
  }

  @override
  double calculatePriority(
    String key,
    dynamic data,
    CacheMetadata? metadata,
    int accessCount,
    DateTime lastAccess,
  ) {
    // 1. 获取键的档案
    final profile = _keyProfiles[key];
    if (profile == null) {
      return _calculateBasePriority(data, metadata, accessCount, lastAccess);
    }

    // 2. 多因子优先级计算
    final factors = PriorityFactors(
      accessFrequency: profile.accessFrequency,
      recency: _calculateRecencyFactor(lastAccess),
      dataValue: _calculateDataValueFactor(key, data),
      accessPattern: _calculateAccessPatternFactor(profile),
      timeOfDay: _calculateTimeOfDayFactor(),
      prediction: _calculatePredictionFactor(profile),
    );

    final priority = _computeMultiFactorPriority(factors);

    // 3. 记录决策
    _recordDecision(key, StrategyDecisionType.priority, priority);

    return priority;
  }

  @override
  bool shouldEvict(
    String key,
    dynamic data,
    CacheConfig config,
    double memoryPressure,
  ) {
    final profile = _keyProfiles[key];
    if (profile == null) {
      return memoryPressure > 0.8; // 默认策略
    }

    // 综合考虑多个因素
    final evictionScore = _calculateEvictionScore(profile, memoryPressure);
    final shouldEvict = evictionScore > 0.7;

    // 记录决策
    _recordDecision(key, StrategyDecisionType.eviction, shouldEvict);

    return shouldEvict;
  }

  @override
  String get strategyName => 'AdvancedAdaptive';

  /// 记录访问事件
  void recordAccess(String key, bool hit, int responseTime) {
    _patternLearner.recordAccess(key, hit, responseTime);
    _timeSeriesPredictor.recordAccess(key);
    _performanceAnalyzer.recordAccess(key, hit, responseTime);

    // 更新键档案
    final profile = _getOrCreateProfile(key, null, null);
    profile.recordAccess(hit, responseTime);
  }

  /// 记录存储事件
  void recordStorage(String key, int size) {
    final profile = _getOrCreateProfile(key, null, null);
    profile.recordStorage(size);
  }

  /// 获取键的档案
  CacheKeyProfile? getKeyProfile(String key) {
    return _keyProfiles[key];
  }

  /// 优化策略参数
  Future<void> optimizeParameters() async {
    // 分析最近的性能表现
    final recentPerformance = _performanceAnalyzer.getRecentPerformance();

    // 调整命中率阈值
    if (recentPerformance.hitRate > 0.9) {
      _hitRateThreshold = math.min(_hitRateThreshold * 1.1, 0.95);
    } else if (recentPerformance.hitRate < 0.6) {
      _hitRateThreshold = math.max(_hitRateThreshold * 0.9, 0.4);
    }

    // 调整访问频率阈值
    if (recentPerformance.averageResponseTime > 100) {
      _accessFrequencyThreshold =
          math.max(_accessFrequencyThreshold * 0.9, 0.1);
    } else if (recentPerformance.averageResponseTime < 50) {
      _accessFrequencyThreshold =
          math.min(_accessFrequencyThreshold * 1.1, 0.5);
    }

    // 清理旧的档案
    _cleanupOldProfiles();
  }

  /// 获取策略统计信息
  AdaptiveStrategyStats getStats() {
    return AdaptiveStrategyStats(
      totalProfiles: _keyProfiles.length,
      learningWindowSize: _learningWindowSize,
      hitRateThreshold: _hitRateThreshold,
      accessFrequencyThreshold: _accessFrequencyThreshold,
      baseTtl: _baseTtl,
      decisionHistorySize: _decisionHistory.length,
    );
  }

  // ============================================================================
  // 私有方法实现
  // ============================================================================

  CacheKeyProfile _getOrCreateProfile(
      String key, dynamic data, CacheConfig? config) {
    return _keyProfiles.putIfAbsent(
      key,
      () => CacheKeyProfile(
        key: key,
        createdAt: DateTime.now(),
        initialConfig: config,
        initialDataSize: _estimateDataSize(data),
      ),
    );
  }

  int _estimateDataSize(dynamic data) {
    if (data is String) return data.length;
    if (data is Map) return data.length * 20; // 估算
    if (data is List) return data.length * 10; // 估算
    return 100; // 默认估算
  }

  DateTime _applyIntelligentAdjustment(
      String key, CacheKeyProfile profile, DateTime baseExpiry) {
    // 1. 基于访问频率调整
    final frequencyMultiplier = _calculateFrequencyMultiplier(profile);

    // 2. 基于数据价值调整
    final valueMultiplier = _calculateValueMultiplier(profile);

    // 3. 基于时间模式调整
    final timeMultiplier = _calculateTimeMultiplier(key);

    // 4. 基于预测调整
    final predictionMultiplier = _calculatePredictionMultiplier(profile);

    // 5. 计算最终调整
    final totalMultiplier = frequencyMultiplier *
        valueMultiplier *
        timeMultiplier *
        predictionMultiplier;
    final adjustedDuration = Duration(
      milliseconds: (baseExpiry.difference(DateTime.now()).inMilliseconds *
              totalMultiplier)
          .round(),
    );

    return DateTime.now().add(adjustedDuration);
  }

  double _calculateFrequencyMultiplier(CacheKeyProfile profile) {
    final frequency = profile.accessFrequency;

    if (frequency > 0.8) return 2.0; // 高频访问，延长缓存时间
    if (frequency > 0.5) return 1.5; // 中频访问
    if (frequency > 0.2) return 1.0; // 低频访问
    return 0.5; // 极低频访问，缩短缓存时间
  }

  double _calculateValueMultiplier(CacheKeyProfile profile) {
    // 基于命中率计算数据价值
    if (profile.totalAccesses < 5) return 1.0; // 数据不足，使用默认值

    final hitRate = profile.hits / profile.totalAccesses;

    if (hitRate > 0.9) return 1.5; // 高价值数据
    if (hitRate > 0.7) return 1.2; // 中等价值数据
    if (hitRate > 0.4) return 1.0; // 一般价值数据
    return 0.7; // 低价值数据
  }

  double _calculateTimeMultiplier(String key) {
    final now = DateTime.now();
    final hour = now.hour;

    // 根据时间段调整
    if (hour >= 9 && hour <= 17) {
      // 工作时间：对业务相关键延长缓存
      if (_isBusinessKey(key)) return 1.2;
      return 1.0;
    } else if (hour >= 19 && hour <= 23) {
      // 晚间高峰：对娱乐相关键延长缓存
      if (_isEntertainmentKey(key)) return 1.3;
      return 0.9;
    } else {
      // 深夜时间：普遍缩短缓存时间
      return 0.8;
    }
  }

  double _calculatePredictionMultiplier(CacheKeyProfile profile) {
    final prediction = _timeSeriesPredictor.predictNextAccess(profile.key);

    if (prediction.confidence > 0.8) {
      // 高置信度预测
      final hoursToNextAccess =
          prediction.predictedTime.difference(DateTime.now()).inHours;

      if (hoursToNextAccess < 1) return 1.5; // 即将访问，延长缓存
      if (hoursToNextAccess < 6) return 1.2; // 短期内会访问
      if (hoursToNextAccess < 24) return 1.0; // 一天内会访问
      return 0.7; // 较长时间内不会访问
    } else if (prediction.confidence > 0.5) {
      return 1.0; // 中等置信度，使用默认值
    } else {
      return 0.9; // 低置信度，略微缩短缓存
    }
  }

  double _calculateBasePriority(
    dynamic data,
    CacheMetadata? metadata,
    int accessCount,
    DateTime lastAccess,
  ) {
    // 基础优先级计算（向后兼容）
    double priority = 1000.0; // 基础分数

    // 访问次数权重
    priority += accessCount * 100.0;

    // 最近访问时间权重
    final hoursSinceAccess = DateTime.now().difference(lastAccess).inHours;
    priority += 10000.0 / (hoursSinceAccess + 1);

    // 数据大小权重（小数据优先级高）
    final size = metadata?.size ?? 100;
    priority += 100000.0 / (size + 1);

    return priority;
  }

  double _calculateRecencyFactor(DateTime lastAccess) {
    final hoursSinceAccess = DateTime.now().difference(lastAccess).inHours;
    return 1.0 / (hoursSinceAccess + 1);
  }

  double _calculateDataValueFactor(String key, dynamic data) {
    // 基于键的模式判断数据价值
    if (_isSystemKey(key)) return 1.5;
    if (_isUserKey(key)) return 1.3;
    if (_isBusinessKey(key)) return 1.2;
    return 1.0;
  }

  double _calculateAccessPatternFactor(CacheKeyProfile profile) {
    // 基于访问模式的一致性
    if (profile.accessPatternConsistency > 0.8) return 1.3;
    if (profile.accessPatternConsistency > 0.6) return 1.1;
    return 1.0;
  }

  double _calculateTimeOfDayFactor() {
    final hour = DateTime.now().hour;

    // 根据业务高峰时间调整
    if ((hour >= 9 && hour <= 11) || (hour >= 14 && hour <= 16)) {
      return 1.2; // 业务高峰
    } else if (hour >= 19 && hour <= 22) {
      return 1.1; // 用户活跃高峰
    } else {
      return 1.0; // 正常时间
    }
  }

  double _calculatePredictionFactor(CacheKeyProfile profile) {
    final prediction = _timeSeriesPredictor.predictNextAccess(profile.key);
    return prediction.confidence;
  }

  double _computeMultiFactorPriority(PriorityFactors factors) {
    // 加权计算多因子优先级
    const weights = PriorityWeights(
      accessFrequency: 0.3,
      recency: 0.25,
      dataValue: 0.2,
      accessPattern: 0.15,
      timeOfDay: 0.05,
      prediction: 0.05,
    );

    return (factors.accessFrequency * weights.accessFrequency) +
        (factors.recency * weights.recency) +
        (factors.dataValue * weights.dataValue) +
        (factors.accessPattern * weights.accessPattern) +
        (factors.timeOfDay * weights.timeOfDay) +
        (factors.prediction * weights.prediction);
  }

  double _calculateEvictionScore(
      CacheKeyProfile profile, double memoryPressure) {
    double score = 0.0;

    // 访问频率因素（低频率应该被淘汰）
    score += (1.0 - profile.accessFrequency) * 0.4;

    // 内存压力因素
    score += memoryPressure * 0.3;

    // 数据大小因素（大数据优先被淘汰）
    score +=
        (profile.averageDataSize / 10240.0).clamp(0.0, 1.0) * 0.2; // 相对于10KB

    // 最后访问时间因素
    final hoursSinceAccess =
        DateTime.now().difference(profile.lastAccessAt).inHours;
    score += (hoursSinceAccess / 24.0).clamp(0.0, 1.0) * 0.1;

    return score;
  }

  bool _isBusinessKey(String key) {
    return key.contains('fund') ||
        key.contains('market') ||
        key.contains('search');
  }

  bool _isSystemKey(String key) {
    return key.contains('config') ||
        key.contains('system') ||
        key.contains('cache');
  }

  bool _isUserKey(String key) {
    return key.contains('user') ||
        key.contains('profile') ||
        key.contains('preference');
  }

  bool _isEntertainmentKey(String key) {
    return key.contains('news') ||
        key.contains('recommendation') ||
        key.contains('popular');
  }

  void _recordDecision(String key, StrategyDecisionType type, dynamic value) {
    final decision = StrategyDecision(
      key: key,
      type: type,
      value: value,
      timestamp: DateTime.now(),
    );

    _decisionHistory.add(decision);

    // 保持历史记录在合理范围内
    if (_decisionHistory.length > 1000) {
      _decisionHistory.removeFirst();
    }
  }

  void _cleanupOldProfiles() {
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: 7)); // 清理7天未访问的档案

    final keysToRemove = <String>[];
    for (final entry in _keyProfiles.entries) {
      if (now.difference(entry.value.lastAccessAt).inDays > 7) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      _keyProfiles.remove(key);
    }
  }
}

// ============================================================================
// 支持类定义
// ============================================================================

/// 缓存键档案
class CacheKeyProfile {
  final String key;
  final DateTime createdAt;
  final CacheConfig? initialConfig;
  final int initialDataSize;

  // 访问统计
  int totalAccesses = 0;
  int hits = 0;
  int totalResponseTime = 0;
  DateTime lastAccessAt = DateTime.now();
  final Queue<DateTime> accessTimes = Queue();

  // 存储统计
  int storageCount = 0;
  int totalDataSize = 0;
  int currentDataSize = 0;

  // 模式分析
  double _accessFrequency = 0.0;
  double _accessPatternConsistency = 0.0;
  final Map<int, int> _hourlyAccessCounts = {};

  CacheKeyProfile({
    required this.key,
    required this.createdAt,
    this.initialConfig,
    required this.initialDataSize,
  }) {
    lastAccessAt = DateTime.now();
  }

  void recordAccess(bool hit, int responseTime) {
    totalAccesses++;
    if (hit) hits++;
    totalResponseTime += responseTime;
    lastAccessAt = DateTime.now();

    // 记录访问时间
    accessTimes.add(lastAccessAt);
    if (accessTimes.length > 100) {
      accessTimes.removeFirst();
    }

    // 记录小时访问次数
    final hour = lastAccessAt.hour;
    _hourlyAccessCounts[hour] = (_hourlyAccessCounts[hour] ?? 0) + 1;

    // 更新计算指标
    _updateComputedMetrics();
  }

  void recordStorage(int size) {
    storageCount++;
    totalDataSize += size;
    currentDataSize = size;
  }

  double get accessFrequency => _accessFrequency;

  double get accessPatternConsistency => _accessPatternConsistency;

  double get averageDataSize => storageCount > 0
      ? totalDataSize / storageCount
      : initialDataSize.toDouble();

  double get hitRate => totalAccesses > 0 ? hits / totalAccesses : 0.0;

  double get averageResponseTime =>
      totalAccesses > 0 ? totalResponseTime / totalAccesses : 0.0;

  void _updateComputedMetrics() {
    if (accessTimes.length < 2) return;

    // 计算访问频率（基于最近24小时）
    final now = DateTime.now();
    final dayAgo = now.subtract(Duration(days: 1));
    final recentAccesses =
        accessTimes.where((time) => time.isAfter(dayAgo)).length;
    _accessFrequency = recentAccesses / 24.0; // 每小时访问次数

    // 计算访问模式一致性
    _calculatePatternConsistency();
  }

  void _calculatePatternConsistency() {
    if (_hourlyAccessCounts.length < 3) {
      _accessPatternConsistency = 0.5; // 数据不足
      return;
    }

    // 计算小时访问次数的方差
    final values = _hourlyAccessCounts.values.toList();
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance =
        values.map((v) => math.pow(v - mean, 2)).reduce((a, b) => a + b) /
            values.length;
    final standardDeviation = math.sqrt(variance);

    // 一致性 = 1 - (标准差 / 平均值)，限制在[0,1]范围
    _accessPatternConsistency =
        (1.0 - (standardDeviation / mean)).clamp(0.0, 1.0);
  }
}

/// 优先级因子
class PriorityFactors {
  final double accessFrequency;
  final double recency;
  final double dataValue;
  final double accessPattern;
  final double timeOfDay;
  final double prediction;

  const PriorityFactors({
    required this.accessFrequency,
    required this.recency,
    required this.dataValue,
    required this.accessPattern,
    required this.timeOfDay,
    required this.prediction,
  });
}

/// 优先级权重
class PriorityWeights {
  final double accessFrequency;
  final double recency;
  final double dataValue;
  final double accessPattern;
  final double timeOfDay;
  final double prediction;

  const PriorityWeights({
    required this.accessFrequency,
    required this.recency,
    required this.dataValue,
    required this.accessPattern,
    required this.timeOfDay,
    required this.prediction,
  });
}

/// 策略决策
class StrategyDecision {
  final String key;
  final StrategyDecisionType type;
  final dynamic value;
  final DateTime timestamp;

  const StrategyDecision({
    required this.key,
    required this.type,
    required this.value,
    required this.timestamp,
  });
}

/// 策略决策类型
enum StrategyDecisionType {
  ttl,
  priority,
  eviction,
}

/// 自适应策略统计
class AdaptiveStrategyStats {
  final int totalProfiles;
  final int learningWindowSize;
  final double hitRateThreshold;
  final double accessFrequencyThreshold;
  final Duration baseTtl;
  final int decisionHistorySize;

  const AdaptiveStrategyStats({
    required this.totalProfiles,
    required this.learningWindowSize,
    required this.hitRateThreshold,
    required this.accessFrequencyThreshold,
    required this.baseTtl,
    required this.decisionHistorySize,
  });

  @override
  String toString() {
    return 'AdaptiveStrategyStats('
        'profiles: $totalProfiles, '
        'hitRateThreshold: ${(hitRateThreshold * 100).toStringAsFixed(1)}%, '
        'accessFreqThreshold: ${(accessFrequencyThreshold * 100).toStringAsFixed(1)}%, '
        'baseTtl: ${baseTtl.inHours}h, '
        'decisions: $decisionHistorySize)';
  }
}

// ============================================================================
// 支持组件
// ============================================================================

/// 访问模式学习器
class AccessPatternLearner {
  final Map<String, List<AccessEvent>> _accessHistory = {};

  void recordAccess(String key, bool hit, int responseTime) {
    final history = _accessHistory.putIfAbsent(key, () => []);
    history.add(AccessEvent(
      timestamp: DateTime.now(),
      hit: hit,
      responseTime: responseTime,
    ));

    // 保持历史记录在合理范围内
    if (history.length > 200) {
      history.removeRange(0, history.length - 200);
    }
  }

  List<AccessEvent> getAccessHistory(String key) {
    return _accessHistory[key] ?? [];
  }
}

/// 时间序列预测器
class TimeSeriesPredictor {
  final Map<String, Queue<DateTime>> _accessTimestamps = {};

  void recordAccess(String key) {
    final timestamps = _accessTimestamps.putIfAbsent(key, () => Queue());
    timestamps.add(DateTime.now());

    if (timestamps.length > 100) {
      timestamps.removeFirst();
    }
  }

  AccessPrediction predictNextAccess(String key) {
    final timestamps = _accessTimestamps[key];
    if (timestamps == null || timestamps.length < 3) {
      return AccessPrediction.confidence(0.0);
    }

    // 简单的线性预测
    final recent = timestamps.take(10).toList();
    if (recent.length < 2) {
      return AccessPrediction.confidence(0.0);
    }

    // 计算平均访问间隔
    int totalInterval = 0;
    for (int i = 1; i < recent.length; i++) {
      totalInterval += recent[i].difference(recent[i - 1]).inMilliseconds;
    }

    final avgInterval = totalInterval / (recent.length - 1);
    final nextAccess =
        recent.last.add(Duration(milliseconds: avgInterval.round()));

    // 计算置信度（基于间隔的一致性）
    final intervals = <int>[];
    for (int i = 1; i < recent.length; i++) {
      intervals.add(recent[i].difference(recent[i - 1]).inMilliseconds);
    }

    final mean = intervals.reduce((a, b) => a + b) / intervals.length;
    final variance =
        intervals.map((i) => math.pow(i - mean, 2)).reduce((a, b) => a + b) /
            intervals.length;
    final standardDeviation = math.sqrt(variance);
    final consistency = 1.0 - (standardDeviation / mean);
    final confidence = consistency.clamp(0.0, 1.0);

    return AccessPrediction(
      predictedTime: nextAccess,
      confidence: confidence,
    );
  }
}

/// 缓存性能分析器
class CachePerformanceAnalyzer {
  final Queue<PerformanceSnapshot> _snapshots = Queue();

  void recordAccess(String key, bool hit, int responseTime) {
    final snapshot = PerformanceSnapshot(
      timestamp: DateTime.now(),
      key: key,
      hit: hit,
      responseTime: responseTime,
    );

    _snapshots.add(snapshot);
    if (_snapshots.length > 1000) {
      _snapshots.removeFirst();
    }
  }

  RecentPerformance getRecentPerformance() {
    if (_snapshots.length < 10) {
      return RecentPerformance(
        hitRate: 0.5,
        averageResponseTime: 100.0,
        totalAccesses: _snapshots.length,
      );
    }

    final recent = _snapshots.take(100).toList();
    final hits = recent.where((s) => s.hit).length;
    final totalTime = recent.map((s) => s.responseTime).reduce((a, b) => a + b);

    return RecentPerformance(
      hitRate: hits / recent.length,
      averageResponseTime: totalTime / recent.length,
      totalAccesses: recent.length,
    );
  }
}

/// 访问事件
class AccessEvent {
  final DateTime timestamp;
  final bool hit;
  final int responseTime;

  const AccessEvent({
    required this.timestamp,
    required this.hit,
    required this.responseTime,
  });
}

/// 访问预测
class AccessPrediction {
  final DateTime predictedTime;
  final double confidence;

  const AccessPrediction({
    required this.predictedTime,
    required this.confidence,
  });

  factory AccessPrediction.confidence(double confidence) {
    return AccessPrediction(
      predictedTime: DateTime.now().add(Duration(hours: 1)),
      confidence: confidence,
    );
  }
}

/// 性能快照
class PerformanceSnapshot {
  final DateTime timestamp;
  final String key;
  final bool hit;
  final int responseTime;

  const PerformanceSnapshot({
    required this.timestamp,
    required this.key,
    required this.hit,
    required this.responseTime,
  });
}

/// 最近性能
class RecentPerformance {
  final double hitRate;
  final double averageResponseTime;
  final int totalAccesses;

  const RecentPerformance({
    required this.hitRate,
    required this.averageResponseTime,
    required this.totalAccesses,
  });
}
