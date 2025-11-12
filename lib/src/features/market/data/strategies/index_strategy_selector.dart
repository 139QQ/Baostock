import 'dart:async';
import 'dart:math' as math;

import '../../../../core/network/hybrid/data_fetch_strategy.dart';
import '../../../../core/utils/logger.dart';
import '../../models/market_index_data.dart';
import 'websocket_index_strategy.dart';

/// 指数策略选择器
///
/// 负责在不同数据获取策略之间进行智能选择和切换
class IndexStrategySelector {
  /// 可用的策略列表
  final List<DataFetchStrategy> _availableStrategies;

  /// 当前活跃策略
  DataFetchStrategy? _activeStrategy;

  /// 策略选择配置
  final StrategySelectionConfig _config;

  /// 策略性能统计
  final Map<String, StrategyPerformanceMetrics> _performanceMetrics = {};

  /// 策略健康状态
  final Map<String, StrategyHealthStatus> _healthStatus = {};

  /// 自动切换定时器
  Timer? _autoSwitchTimer;

  /// 策略切换历史
  final List<StrategySwitchRecord> _switchHistory = [];

  /// 构造函数
  IndexStrategySelector({
    List<DataFetchStrategy>? availableStrategies,
    StrategySelectionConfig? config,
  })  : _availableStrategies = availableStrategies ?? const [],
        _config = config ?? const StrategySelectionConfig() {
    _initializePerformanceMetrics();
    _startAutoSwitching();
  }

  /// 获取默认策略列表
  List<DataFetchStrategy> _getDefaultStrategies() {
    // 这里应该返回实际可用的策略
    // 暂时返回空列表，需要在实际使用时注入真实策略
    return [];
  }

  /// 初始化性能指标
  void _initializePerformanceMetrics() {
    for (final strategy in _availableStrategies) {
      _performanceMetrics[strategy.name] = StrategyPerformanceMetrics(
        strategyName: strategy.name,
        successRate: 0.0,
        averageLatency: Duration.zero,
        errorCount: 0,
        requestCount: 0,
        lastUsed: DateTime.now(),
      );

      _healthStatus[strategy.name] = StrategyHealthStatus(
        strategyName: strategy.name,
        isHealthy: true,
        lastHealthCheck: DateTime.now(),
        consecutiveFailures: 0,
        issues: [],
      );
    }
  }

  /// 启动自动切换
  void _startAutoSwitching() {
    _autoSwitchTimer?.cancel();
    _autoSwitchTimer = Timer.periodic(_config.autoSwitchInterval, (_) {
      _evaluateAndSwitchIfNeeded();
    });
  }

  /// 选择最佳策略
  DataFetchStrategy? selectBestStrategy({
    required String dataType,
    Map<String, dynamic>? parameters,
    StrategySelectionCriteria? criteria,
  }) {
    criteria ??= _config.defaultCriteria;

    // 过滤可用策略
    final availableForDataType = _availableStrategies
        .where((strategy) => strategy.supportedDataTypes
            .any((type) => type.toString() == dataType))
        .toList();

    if (availableForDataType.isEmpty) {
      AppLogger.warn('No available strategies for data type: $dataType');
      return null;
    }

    // 评估策略
    final evaluations = availableForDataType.map((strategy) {
      final score = _evaluateStrategy(
          strategy, criteria ?? const StrategySelectionCriteria());
      return _createStrategyEvaluation(strategy, score);
    }).toList();

    // 按分数排序
    evaluations.sort((a, b) => b.score.compareTo(a.score));

    final bestStrategy = evaluations.first.strategy;

    // 如果最佳策略与当前不同，执行切换
    if (_activeStrategy?.name != bestStrategy.name) {
      _switchToStrategy(bestStrategy);
    }

    return bestStrategy;
  }

  /// 评估策略
  double _evaluateStrategy(
      DataFetchStrategy strategy, StrategySelectionCriteria criteria) {
    double score = 0.0;

    final metrics = _performanceMetrics[strategy.name];
    final health = _healthStatus[strategy.name];

    if (metrics == null || health == null) {
      return 0.0;
    }

    // 成功率权重
    score += metrics.successRate * criteria.successRateWeight;

    // 延迟权重 (延迟越低分数越高)
    final latencyScore =
        1.0 / (1.0 + metrics.averageLatency.inMilliseconds / 1000.0);
    score += latencyScore * criteria.latencyWeight;

    // 健康状态权重
    final healthScore = health.isHealthy ? 1.0 : 0.0;
    score += healthScore * criteria.healthWeight;

    // 优先级权重
    score += strategy.priority / 100.0 * criteria.priorityWeight;

    // 最近使用权重 (最近使用过的策略有轻微惩罚)
    final timeSinceLastUsed = DateTime.now().difference(metrics.lastUsed);
    final recencyScore = math.min(timeSinceLastUsed.inMinutes / 60.0, 1.0);
    score += recencyScore * criteria.recencyWeight;

    // 错误率权重 (错误率越低分数越高)
    final errorRate = metrics.requestCount > 0
        ? metrics.errorCount / metrics.requestCount
        : 0.0;
    final reliabilityScore = 1.0 - errorRate;
    score += reliabilityScore * criteria.reliabilityWeight;

    return score;
  }

  /// 切换到指定策略
  void _switchToStrategy(DataFetchStrategy newStrategy) {
    final oldStrategy = _activeStrategy;
    _activeStrategy = newStrategy;

    // 记录切换历史
    final switchRecord = StrategySwitchRecord(
      fromStrategy: oldStrategy?.name,
      toStrategy: newStrategy.name,
      timestamp: DateTime.now(),
      reason: 'Auto-selection based on performance metrics',
    );

    _switchHistory.add(switchRecord);

    // 保持历史记录在合理范围内
    while (_switchHistory.length > _config.maxSwitchHistory) {
      _switchHistory.removeAt(0);
    }

    AppLogger.info(
        'Switched strategy: ${oldStrategy?.name} → ${newStrategy.name}');

    // 更新策略使用时间
    _performanceMetrics[newStrategy.name]?.updateLastUsed();
  }

  /// 手动切换策略
  bool switchToStrategy(String strategyName) {
    final strategy = _availableStrategies.firstWhere(
      (s) => s.name == strategyName,
      orElse: () => throw ArgumentError('Strategy not found: $strategyName'),
    );

    final healthStatus = _healthStatus[strategyName];
    if (healthStatus == null || !healthStatus.isHealthy) {
      AppLogger.warn('Cannot switch to unhealthy strategy: $strategyName');
      return false;
    }

    _switchToStrategy(strategy);
    return true;
  }

  /// 记录策略使用结果
  void recordStrategyUsage({
    required String strategyName,
    required bool success,
    required Duration latency,
    String? errorMessage,
  }) {
    final metrics = _performanceMetrics[strategyName];
    if (metrics != null) {
      metrics.recordUsage(success, latency, errorMessage);
    }

    final health = _healthStatus[strategyName];
    if (health != null) {
      health.recordUsage(success, errorMessage);
    }

    // 如果当前策略性能不佳，触发重新评估
    if (_activeStrategy?.name == strategyName && !success) {
      _evaluateAndSwitchIfNeeded();
    }
  }

  /// 评估并切换策略（如果需要）
  void _evaluateAndSwitchIfNeeded() {
    if (_activeStrategy == null) return;

    final metrics = _performanceMetrics[_activeStrategy!.name];
    final health = _healthStatus[_activeStrategy!.name];

    if (metrics == null || health == null) return;

    // 检查是否需要切换
    bool shouldSwitch = false;
    String switchReason = '';

    // 成功率过低
    if (metrics.successRate < _config.minSuccessRate) {
      shouldSwitch = true;
      switchReason = 'Success rate too low: ${metrics.successRate}';
    }

    // 延迟过高
    if (metrics.averageLatency > _config.maxAcceptableLatency) {
      shouldSwitch = true;
      switchReason =
          'Latency too high: ${metrics.averageLatency.inMilliseconds}ms';
    }

    // 健康状态不佳
    if (!health.isHealthy) {
      shouldSwitch = true;
      switchReason = 'Strategy unhealthy: ${health.issues.join(', ')}';
    }

    // 连续失败次数过多
    if (health.consecutiveFailures >= _config.maxConsecutiveFailures) {
      shouldSwitch = true;
      switchReason =
          'Too many consecutive failures: ${health.consecutiveFailures}';
    }

    if (shouldSwitch) {
      AppLogger.info('Strategy performance degraded, switching: $switchReason');

      // 选择新的最佳策略
      final newStrategy = selectBestStrategy(
        dataType: 'market_index', // 根据实际需要调整
        criteria: _config.fallbackCriteria,
      );

      if (newStrategy != null) {
        final switchRecord = StrategySwitchRecord(
          fromStrategy: _activeStrategy!.name,
          toStrategy: newStrategy.name,
          timestamp: DateTime.now(),
          reason: switchReason,
        );

        _switchHistory.add(switchRecord);
        _activeStrategy = newStrategy;
      }
    }
  }

  /// 获取当前策略
  DataFetchStrategy? get activeStrategy => _activeStrategy;

  /// 获取策略性能指标
  StrategyPerformanceMetrics? getPerformanceMetrics(String strategyName) {
    return _performanceMetrics[strategyName];
  }

  /// 获取策略健康状态
  StrategyHealthStatus? getHealthStatus(String strategyName) {
    return _healthStatus[strategyName];
  }

  /// 获取所有策略的性能指标
  Map<String, StrategyPerformanceMetrics> getAllPerformanceMetrics() {
    return Map.unmodifiable(_performanceMetrics);
  }

  /// 获取所有策略的健康状态
  Map<String, StrategyHealthStatus> getAllHealthStatus() {
    return Map.unmodifiable(_healthStatus);
  }

  /// 获取切换历史
  List<StrategySwitchRecord> getSwitchHistory() {
    return List.unmodifiable(_switchHistory);
  }

  /// 生成策略报告
  StrategyReport generateReport() {
    final now = DateTime.now();
    final recentSwitches = _switchHistory
        .where((record) =>
            now.difference(record.timestamp) <= _config.reportPeriod)
        .toList();

    return StrategyReport(
      timestamp: now,
      activeStrategy: _activeStrategy?.name,
      totalSwitches: _switchHistory.length,
      recentSwitches: recentSwitches,
      performanceMetrics: Map.unmodifiable(_performanceMetrics),
      healthStatus: Map.unmodifiable(_healthStatus),
      recommendations: _generateRecommendations(),
    );
  }

  /// 生成建议
  List<String> _generateRecommendations() {
    final recommendations = <String>[];

    // 分析性能指标
    for (final entry in _performanceMetrics.entries) {
      final metrics = entry.value;
      final health = _healthStatus[entry.key];

      if (metrics.successRate < 0.9) {
        recommendations.add(
            '策略 ${metrics.strategyName} 成功率偏低 (${(metrics.successRate * 100).toStringAsFixed(1)}%)');
      }

      if (metrics.averageLatency.inMilliseconds > 5000) {
        recommendations.add(
            '策略 ${metrics.strategyName} 延迟过高 (${metrics.averageLatency.inMilliseconds}ms)');
      }

      if (health != null && !health.isHealthy) {
        recommendations.add('策略 ${health.strategyName} 健康状况不佳');
      }
    }

    if (recommendations.isEmpty) {
      recommendations.add('所有策略运行良好，无需调整');
    }

    return recommendations;
  }

  /// 重置所有指标
  void resetMetrics() {
    for (final metrics in _performanceMetrics.values) {
      metrics.reset();
    }

    for (final health in _healthStatus.values) {
      health.reset();
    }

    _switchHistory.clear();
    AppLogger.info('All strategy metrics reset');
  }

  /// 创建策略评估结果
  StrategyEvaluation _createStrategyEvaluation(
      DataFetchStrategy strategy, double score) {
    return StrategyEvaluation(strategy, score);
  }

  /// 销毁选择器
  void dispose() {
    _autoSwitchTimer?.cancel();
    AppLogger.info('IndexStrategySelector disposed');
  }

  @override
  String toString() {
    return 'IndexStrategySelector(active: ${_activeStrategy?.name}, available: ${_availableStrategies.length})';
  }
}

/// 策略选择配置
class StrategySelectionConfig {
  final Duration autoSwitchInterval;
  final double minSuccessRate;
  final Duration maxAcceptableLatency;
  final int maxConsecutiveFailures;
  final int maxSwitchHistory;
  final Duration reportPeriod;
  final StrategySelectionCriteria defaultCriteria;
  final StrategySelectionCriteria fallbackCriteria;

  const StrategySelectionConfig({
    this.autoSwitchInterval = const Duration(minutes: 5),
    this.minSuccessRate = 0.8,
    this.maxAcceptableLatency = const Duration(seconds: 10),
    this.maxConsecutiveFailures = 3,
    this.maxSwitchHistory = 100,
    this.reportPeriod = const Duration(hours: 1),
    this.defaultCriteria = const StrategySelectionCriteria(),
    this.fallbackCriteria = const StrategySelectionCriteria(
      successRateWeight: 0.5,
      latencyWeight: 0.3,
      healthWeight: 0.2,
    ),
  });
}

/// 策略选择标准
class StrategySelectionCriteria {
  final double successRateWeight;
  final double latencyWeight;
  final double healthWeight;
  final double priorityWeight;
  final double recencyWeight;
  final double reliabilityWeight;

  const StrategySelectionCriteria({
    this.successRateWeight = 0.4,
    this.latencyWeight = 0.3,
    this.healthWeight = 0.2,
    this.priorityWeight = 0.05,
    this.recencyWeight = 0.03,
    this.reliabilityWeight = 0.02,
  });

  /// 验证权重总和
  bool get isValid {
    final total = successRateWeight +
        latencyWeight +
        healthWeight +
        priorityWeight +
        recencyWeight +
        reliabilityWeight;
    return (total - 1.0).abs() < 0.01; // 允许浮点误差
  }
}

/// 策略性能指标
class StrategyPerformanceMetrics {
  final String strategyName;
  double successRate;
  Duration averageLatency;
  int errorCount;
  int requestCount;
  DateTime lastUsed;

  StrategyPerformanceMetrics({
    required this.strategyName,
    required this.successRate,
    required this.averageLatency,
    required this.errorCount,
    required this.requestCount,
    required this.lastUsed,
  });

  /// 记录使用结果
  void recordUsage(bool success, Duration latency, String? errorMessage) {
    requestCount++;
    if (!success) {
      errorCount++;
    }

    // 更新平均延迟
    if (averageLatency == Duration.zero) {
      averageLatency = latency;
    } else {
      final totalLatency = averageLatency.inMilliseconds * (requestCount - 1) +
          latency.inMilliseconds;
      averageLatency = Duration(milliseconds: totalLatency ~/ requestCount);
    }

    // 更新成功率
    successRate = (requestCount - errorCount) / requestCount;
    lastUsed = DateTime.now();
  }

  /// 更新最后使用时间
  void updateLastUsed() {
    lastUsed = DateTime.now();
  }

  /// 重置指标
  void reset() {
    successRate = 0.0;
    averageLatency = Duration.zero;
    errorCount = 0;
    requestCount = 0;
    lastUsed = DateTime.now();
  }

  @override
  String toString() {
    return 'StrategyMetrics($strategyName: success=${(successRate * 100).toStringAsFixed(1)}%, latency=${averageLatency.inMilliseconds}ms)';
  }
}

/// 策略健康状态
class StrategyHealthStatus {
  final String strategyName;
  bool isHealthy;
  DateTime lastHealthCheck;
  int consecutiveFailures;
  List<String> issues;

  StrategyHealthStatus({
    required this.strategyName,
    required this.isHealthy,
    required this.lastHealthCheck,
    required this.consecutiveFailures,
    required this.issues,
  });

  /// 记录使用结果
  void recordUsage(bool success, String? errorMessage) {
    lastHealthCheck = DateTime.now();

    if (success) {
      consecutiveFailures = 0;
      if (!isHealthy) {
        isHealthy = true;
        issues.clear();
      }
    } else {
      consecutiveFailures++;
      if (consecutiveFailures >= 3) {
        isHealthy = false;
        if (errorMessage != null && !issues.contains(errorMessage)) {
          issues.add(errorMessage);
        }
      }
    }

    // 保持问题列表在合理范围内
    while (issues.length > 10) {
      issues.removeAt(0);
    }
  }

  /// 重置健康状态
  void reset() {
    isHealthy = true;
    lastHealthCheck = DateTime.now();
    consecutiveFailures = 0;
    issues.clear();
  }

  @override
  String toString() {
    return 'StrategyHealth($strategyName: healthy=$isHealthy, failures=$consecutiveFailures)';
  }
}

/// 策略切换记录
class StrategySwitchRecord {
  final String? fromStrategy;
  final String toStrategy;
  final DateTime timestamp;
  final String reason;

  const StrategySwitchRecord({
    this.fromStrategy,
    required this.toStrategy,
    required this.timestamp,
    required this.reason,
  });

  @override
  String toString() {
    return 'Switch($timestamp): $fromStrategy → $toStrategy ($reason)';
  }
}

/// 策略评估结果
class StrategyEvaluation {
  final DataFetchStrategy strategy;
  final double score;

  const StrategyEvaluation(this.strategy, this.score);
}

/// 策略报告
class StrategyReport {
  final DateTime timestamp;
  final String? activeStrategy;
  final int totalSwitches;
  final List<StrategySwitchRecord> recentSwitches;
  final Map<String, StrategyPerformanceMetrics> performanceMetrics;
  final Map<String, StrategyHealthStatus> healthStatus;
  final List<String> recommendations;

  const StrategyReport({
    required this.timestamp,
    this.activeStrategy,
    required this.totalSwitches,
    required this.recentSwitches,
    required this.performanceMetrics,
    required this.healthStatus,
    required this.recommendations,
  });

  @override
  String toString() {
    return 'StrategyReport(active: $activeStrategy, switches: $totalSwitches, recommendations: ${recommendations.length})';
  }
}
