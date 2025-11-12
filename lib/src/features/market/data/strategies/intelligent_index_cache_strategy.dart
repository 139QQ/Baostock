import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:decimal/decimal.dart';

import '../../../../core/utils/logger.dart';
import '../../models/market_index_data.dart';
import '../cache/market_index_cache_manager.dart';

/// 智能指数缓存策略
///
/// 根据访问模式、市场状态和数据特征动态调整缓存策略
class IntelligentIndexCacheStrategy {
  /// 缓存管理器引用
  final MarketIndexCacheManager _cacheManager;

  /// 策略配置
  final IntelligentCacheConfig _config;

  /// 访问模式分析器
  final Map<String, AccessPatternAnalyzer> _patternAnalyzers = {};

  /// 缓存策略映射
  final Map<String, CacheStrategy> _activeStrategies = {};

  /// 市场状态监控
  MarketState _currentMarketState = MarketState.closed;

  /// 性能统计
  CachePerformanceMetrics _performanceMetrics = CachePerformanceMetrics();

  /// 策略优化定时器
  Timer? _optimizationTimer;

  /// 市场状态监控定时器
  Timer? _marketStateTimer;

  /// 构造函数
  IntelligentIndexCacheStrategy({
    required MarketIndexCacheManager cacheManager,
    IntelligentCacheConfig? config,
  })  : _cacheManager = cacheManager,
        _config = config ?? const IntelligentCacheConfig() {
    _startMonitoring();
  }

  /// 开始监控
  void _startMonitoring() {
    // 启动策略优化定时器
    _optimizationTimer = Timer.periodic(_config.optimizationInterval, (_) {
      _optimizeCacheStrategies();
    });

    // 启动市场状态监控
    _marketStateTimer = Timer.periodic(_config.marketStateCheckInterval, (_) {
      _updateMarketState();
    });
  }

  /// 记录缓存访问
  void recordAccess(
    String indexCode,
    CacheAccessType accessType, {
    int? dataSize,
    Duration? accessTime,
    bool? fromCache,
  }) {
    // 初始化模式分析器
    if (!_patternAnalyzers.containsKey(indexCode)) {
      _patternAnalyzers[indexCode] = AccessPatternAnalyzer(
        indexCode: indexCode,
        config: _config.patternAnalyzerConfig,
      );
    }

    // 记录访问
    _patternAnalyzers[indexCode]?.recordAccess(
      accessType,
      dataSize: dataSize,
      accessTime: accessTime,
      fromCache: fromCache,
    );

    // 更新性能指标
    _performanceMetrics.recordAccess(
      accessType,
      dataSize: dataSize,
      accessTime: accessTime,
      fromCache: fromCache,
    );

    // 检查是否需要调整策略
    _checkStrategyAdjustment(indexCode);
  }

  /// 检查策略调整
  void _checkStrategyAdjustment(String indexCode) {
    final analyzer = _patternAnalyzers[indexCode];
    if (analyzer == null) return;

    final currentStrategy = _activeStrategies[indexCode];
    final recommendedStrategy = _recommendCacheStrategy(analyzer);

    if (recommendedStrategy != currentStrategy) {
      _applyCacheStrategy(indexCode, recommendedStrategy);
    }
  }

  /// 推荐缓存策略
  CacheStrategy _recommendCacheStrategy(AccessPatternAnalyzer analyzer) {
    final pattern = analyzer.analyzePattern();
    final indexCode = analyzer.indexCode;

    // 考虑市场状态
    final marketMultiplier = _getMarketStateMultiplier();

    // 考虑指数重要性
    final indexImportance = _getIndexImportance(indexCode);

    // 基于访问模式推荐策略
    if (pattern.accessFrequency == AccessFrequency.high &&
        pattern.accessPattern == AccessPatternType.sequential) {
      // 高频顺序访问：预加载策略
      return CacheStrategy.preload;
    } else if (pattern.accessFrequency == AccessFrequency.high &&
        pattern.accessPattern == AccessPatternType.random) {
      // 高频随机访问：保持内存缓存策略
      return CacheStrategy.keepInMemory;
    } else if (pattern.accessFrequency == AccessFrequency.medium &&
        pattern.temporalPattern == TemporalPattern.workingHours) {
      // 中频工作时间访问：智能缓存策略
      return CacheStrategy.intelligent;
    } else if (pattern.accessFrequency == AccessFrequency.low &&
        pattern.dataVolatility == DataVolatility.low) {
      // 低频稳定数据：长期缓存策略
      return CacheStrategy.longTerm;
    } else {
      // 默认策略
      return CacheStrategy.standard;
    }
  }

  /// 获取市场状态倍数
  double _getMarketStateMultiplier() {
    switch (_currentMarketState) {
      case MarketState.trading:
        return 1.5; // 交易期间提高缓存优先级
      case MarketState.preMarket:
      case MarketState.postMarket:
        return 1.2; // 盘前盘后略微提高
      case MarketState.closed:
        return 1.0; // 正常优先级
      case MarketState.holiday:
        return 0.8; // 节假日降低优先级
    }
  }

  /// 获取指数重要性
  double _getIndexImportance(String indexCode) {
    // 主要指数重要性更高
    final majorIndices = [
      MarketIndexConstants.shanghaiComposite,
      MarketIndexConstants.shenzhenComponent,
      MarketIndexConstants.chiNext,
      MarketIndexConstants.csi300,
    ];

    if (majorIndices.contains(indexCode)) {
      return 1.5;
    } else if (indexCode.startsWith('SH') || indexCode.startsWith('SZ')) {
      return 1.2; // 国内指数
    } else {
      return 1.0; // 其他指数
    }
  }

  /// 应用缓存策略
  void _applyCacheStrategy(String indexCode, CacheStrategy strategy) {
    _activeStrategies[indexCode] = strategy;

    // 根据策略调整缓存配置
    final cacheConfig = _getCacheConfigForStrategy(strategy);

    // 这里应该调用缓存管理器的配置更新方法
    // 由于MarketIndexCacheManager可能不支持动态配置调整，这里仅记录日志
    AppLogger.info('Applied cache strategy $strategy for index $indexCode');

    // 记录策略变更
    _performanceMetrics.recordStrategyChange(indexCode, strategy);
  }

  /// 获取策略对应的缓存配置
  MarketIndexCacheConfig _getCacheConfigForStrategy(CacheStrategy strategy) {
    switch (strategy) {
      case CacheStrategy.preload:
        return const MarketIndexCacheConfig(
          memoryCacheExpiration: Duration(minutes: 10),
          hiveCacheExpiration: Duration(hours: 2),
          maxMemoryCacheSize: 100,
        );

      case CacheStrategy.keepInMemory:
        return const MarketIndexCacheConfig(
          memoryCacheExpiration: Duration(minutes: 30),
          hiveCacheExpiration: Duration(hours: 6),
          maxMemoryCacheSize: 200,
        );

      case CacheStrategy.intelligent:
        return const MarketIndexCacheConfig(
          memoryCacheExpiration: Duration(minutes: 15),
          hiveCacheExpiration: Duration(hours: 12),
          maxMemoryCacheSize: 150,
        );

      case CacheStrategy.longTerm:
        return const MarketIndexCacheConfig(
          memoryCacheExpiration: Duration(minutes: 5),
          hiveCacheExpiration: Duration(days: 7),
          maxMemoryCacheSize: 50,
        );

      case CacheStrategy.standard:
      default:
        return const MarketIndexCacheConfig();
    }
  }

  /// 更新市场状态
  void _updateMarketState() {
    final now = DateTime.now();
    final newMarketState = _determineMarketState(now);

    if (newMarketState != _currentMarketState) {
      final oldState = _currentMarketState;
      _currentMarketState = newMarketState;

      AppLogger.info(
          'Market state changed: ${oldState.name} → ${newMarketState.name}');

      // 市场状态变化时重新评估策略
      _reevaluateAllStrategies();
    }
  }

  /// 确定市场状态
  MarketState _determineMarketState(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    final weekday = time.weekday;

    // 周末
    if (weekday == DateTime.saturday || weekday == DateTime.sunday) {
      return MarketState.holiday;
    }

    // 工作日交易时间
    if ((hour == 9 && minute >= 30) ||
        (hour == 10) ||
        (hour == 11 && minute <= 30)) {
      return MarketState.trading;
    } else if (hour >= 13 && hour < 15) {
      return MarketState.trading;
    } else if (hour < 9) {
      return MarketState.preMarket;
    } else if (hour >= 15 && hour < 18) {
      return MarketState.postMarket;
    } else {
      return MarketState.closed;
    }
  }

  /// 重新评估所有策略
  void _reevaluateAllStrategies() {
    for (final indexCode in _patternAnalyzers.keys) {
      _checkStrategyAdjustment(indexCode);
    }
  }

  /// 优化缓存策略
  void _optimizeCacheStrategies() {
    AppLogger.debug('Starting cache strategy optimization');

    // 分析整体性能
    final overallMetrics = _performanceMetrics.getOverallMetrics();

    // 识别性能瓶颈
    final bottlenecks = _identifyPerformanceBottlenecks(overallMetrics);

    // 应用优化建议
    for (final bottleneck in bottlenecks) {
      _applyOptimization(bottleneck);
    }

    // 清理过期数据
    _cleanupExpiredData();

    AppLogger.debug('Cache strategy optimization completed');
  }

  /// 识别性能瓶颈
  List<PerformanceBottleneck> _identifyPerformanceBottlenecks(
      CacheOverallMetrics metrics) {
    final bottlenecks = <PerformanceBottleneck>[];

    // 检查缓存命中率
    if (metrics.overallHitRate < _config.minAcceptableHitRate) {
      bottlenecks.add(PerformanceBottleneck(
        type: BottleneckType.lowHitRate,
        severity: BottleneckSeverity.high,
        description:
            '缓存命中率过低: ${(metrics.overallHitRate * 100).toStringAsFixed(1)}%',
      ));
    }

    // 检查内存使用
    if (metrics.memoryUsageRatio > _config.maxMemoryUsageRatio) {
      bottlenecks.add(PerformanceBottleneck(
        type: BottleneckType.highMemoryUsage,
        severity: BottleneckSeverity.medium,
        description:
            '内存使用率过高: ${(metrics.memoryUsageRatio * 100).toStringAsFixed(1)}%',
      ));
    }

    // 检查访问延迟
    if (metrics.averageAccessTime > _config.maxAcceptableAccessTime) {
      bottlenecks.add(PerformanceBottleneck(
        type: BottleneckType.highAccessLatency,
        severity: BottleneckSeverity.medium,
        description: '访问延迟过高: ${metrics.averageAccessTime.inMilliseconds}ms',
      ));
    }

    return bottlenecks;
  }

  /// 应用优化
  void _applyOptimization(PerformanceBottleneck bottleneck) {
    switch (bottleneck.type) {
      case BottleneckType.lowHitRate:
        _optimizeForHitRate();
        break;
      case BottleneckType.highMemoryUsage:
        _optimizeForMemoryUsage();
        break;
      case BottleneckType.highAccessLatency:
        _optimizeForAccessLatency();
        break;
    }

    AppLogger.info(
        'Applied optimization for ${bottleneck.type.name}: ${bottleneck.description}');
  }

  /// 优化命中率
  void _optimizeForHitRate() {
    // 增加热门指数的内存缓存时间
    final hotIndices = _getHotIndices();
    for (final indexCode in hotIndices) {
      _applyCacheStrategy(indexCode, CacheStrategy.keepInMemory);
    }
  }

  /// 优化内存使用
  void _optimizeForMemoryUsage() {
    // 减少冷数据的内存缓存时间
    final coldIndices = _getColdIndices();
    for (final indexCode in coldIndices) {
      _applyCacheStrategy(indexCode, CacheStrategy.longTerm);
    }
  }

  /// 优化访问延迟
  void _optimizeForAccessLatency() {
    // 预加载频繁访问的指数
    final frequentIndices = _getFrequentIndices();
    for (final indexCode in frequentIndices) {
      _applyCacheStrategy(indexCode, CacheStrategy.preload);
    }
  }

  /// 获取热门指数
  List<String> _getHotIndices() {
    return _patternAnalyzers.entries
        .where((entry) =>
            entry.value.analyzePattern().accessFrequency ==
            AccessFrequency.high)
        .map((entry) => entry.key)
        .toList();
  }

  /// 获取冷门指数
  List<String> _getColdIndices() {
    return _patternAnalyzers.entries
        .where((entry) =>
            entry.value.analyzePattern().accessFrequency == AccessFrequency.low)
        .map((entry) => entry.key)
        .toList();
  }

  /// 获取频繁访问指数
  List<String> _getFrequentIndices() {
    return _patternAnalyzers.entries
        .where((entry) =>
            entry.value.getRecentAccessCount() >
            _config.frequentAccessThreshold)
        .map((entry) => entry.key)
        .toList();
  }

  /// 清理过期数据
  void _cleanupExpiredData() {
    // 清理长时间未访问的模式分析器
    final now = DateTime.now();
    final expiredIndices = <String>[];

    for (final entry in _patternAnalyzers.entries) {
      final analyzer = entry.value;
      if (now.difference(analyzer.lastAccessTime) >
          _config.analyzerExpirationTime) {
        expiredIndices.add(entry.key);
      }
    }

    for (final indexCode in expiredIndices) {
      _patternAnalyzers.remove(indexCode);
      _activeStrategies.remove(indexCode);
    }

    if (expiredIndices.isNotEmpty) {
      AppLogger.debug('Cleaned up ${expiredIndices.length} expired analyzers');
    }
  }

  /// 获取当前策略
  CacheStrategy? getCurrentStrategy(String indexCode) {
    return _activeStrategies[indexCode];
  }

  /// 获取所有策略
  Map<String, CacheStrategy> getAllStrategies() {
    return Map.unmodifiable(_activeStrategies);
  }

  /// 获取性能指标
  CachePerformanceMetrics getPerformanceMetrics() {
    return _performanceMetrics;
  }

  /// 生成策略报告
  CacheStrategyReport generateStrategyReport() {
    final overallMetrics = _performanceMetrics.getOverallMetrics();
    final strategyDistribution = <CacheStrategy, int>{};

    // 统计策略分布
    for (final strategy in _activeStrategies.values) {
      strategyDistribution[strategy] =
          (strategyDistribution[strategy] ?? 0) + 1;
    }

    // 获取性能建议
    final recommendations = _generatePerformanceRecommendations(overallMetrics);

    return CacheStrategyReport(
      timestamp: DateTime.now(),
      marketState: _currentMarketState,
      totalTrackedIndices: _patternAnalyzers.length,
      strategyDistribution: strategyDistribution,
      overallMetrics: overallMetrics,
      recommendations: recommendations,
    );
  }

  /// 生成性能建议
  List<String> _generatePerformanceRecommendations(
      CacheOverallMetrics metrics) {
    final recommendations = <String>[];

    if (metrics.overallHitRate < 0.8) {
      recommendations.add('缓存命中率偏低，建议增加内存缓存大小或优化预加载策略');
    }

    if (metrics.memoryUsageRatio > 0.8) {
      recommendations.add('内存使用率较高，建议清理冷数据或增加内存限制');
    }

    if (metrics.averageAccessTime > Duration(milliseconds: 100)) {
      recommendations.add('访问延迟较高，建议使用更快的存储或优化数据结构');
    }

    if (recommendations.isEmpty) {
      recommendations.add('缓存性能良好，继续保持当前策略');
    }

    return recommendations;
  }

  /// 手动触发策略优化
  void triggerOptimization() {
    _optimizeCacheStrategies();
  }

  /// 重置所有策略
  void resetAllStrategies() {
    _patternAnalyzers.clear();
    _activeStrategies.clear();
    _performanceMetrics.reset();
    AppLogger.info('All cache strategies reset');
  }

  /// 重置指定指数的策略
  void resetStrategy(String indexCode) {
    _patternAnalyzers.remove(indexCode);
    _activeStrategies.remove(indexCode);
    AppLogger.info('Cache strategy reset for index: $indexCode');
  }

  /// 销毁策略管理器
  void dispose() {
    _optimizationTimer?.cancel();
    _marketStateTimer?.cancel();
    AppLogger.info('IntelligentIndexCacheStrategy disposed');
  }
}

/// 访问模式分析器
class AccessPatternAnalyzer {
  final String indexCode;
  final AccessPatternAnalyzerConfig config;
  final List<AccessRecord> accessRecords = [];
  DateTime lastAccessTime = DateTime.now();

  AccessPatternAnalyzer({
    required this.indexCode,
    required this.config,
  });

  /// 记录访问
  void recordAccess(
    CacheAccessType accessType, {
    int? dataSize,
    Duration? accessTime,
    bool? fromCache,
  }) {
    final record = AccessRecord(
      timestamp: DateTime.now(),
      accessType: accessType,
      dataSize: dataSize ?? 0,
      accessTime: accessTime ?? Duration.zero,
      fromCache: fromCache ?? false,
    );

    accessRecords.add(record);
    lastAccessTime = record.timestamp;

    // 保持记录数量在限制范围内
    while (accessRecords.length > config.maxRecords) {
      accessRecords.removeAt(0);
    }
  }

  /// 分析访问模式
  AccessPattern analyzePattern() {
    if (accessRecords.isEmpty) {
      return AccessPattern(
        accessFrequency: AccessFrequency.low,
        accessPattern: AccessPatternType.random,
        temporalPattern: TemporalPattern.irregular,
        dataVolatility: DataVolatility.unknown,
      );
    }

    // 分析访问频率
    final frequency = _analyzeAccessFrequency();

    // 分析访问模式
    final pattern = _analyzeAccessPattern();

    // 分析时间模式
    final temporal = _analyzeTemporalPattern();

    // 分析数据波动性
    final volatility = _analyzeDataVolatility();

    return AccessPattern(
      accessFrequency: frequency,
      accessPattern: pattern,
      temporalPattern: temporal,
      dataVolatility: volatility,
    );
  }

  /// 分析访问频率
  AccessFrequency _analyzeAccessFrequency() {
    final now = DateTime.now();
    final recentRecords = accessRecords
        .where((record) =>
            now.difference(record.timestamp) <= config.frequencyAnalysisWindow)
        .toList();

    final accessCount = recentRecords.length;
    final accessRate = accessCount / config.frequencyAnalysisWindow.inHours;

    if (accessRate >= 10) {
      return AccessFrequency.high;
    } else if (accessRate >= 1) {
      return AccessFrequency.medium;
    } else {
      return AccessFrequency.low;
    }
  }

  /// 分析访问模式
  AccessPatternType _analyzeAccessPattern() {
    if (accessRecords.length < 10) {
      return AccessPatternType.random;
    }

    // 简单的顺序访问检测
    int sequentialCount = 0;
    for (int i = 1; i < accessRecords.length; i++) {
      final timeDiff =
          accessRecords[i].timestamp.difference(accessRecords[i - 1].timestamp);
      if (timeDiff.inSeconds <= config.sequentialAccessThresholdSeconds) {
        sequentialCount++;
      }
    }

    final sequentialRatio = sequentialCount / (accessRecords.length - 1);

    if (sequentialRatio >= 0.7) {
      return AccessPatternType.sequential;
    } else {
      return AccessPatternType.random;
    }
  }

  /// 分析时间模式
  TemporalPattern _analyzeTemporalPattern() {
    final hourDistribution = <int, int>{};
    for (final record in accessRecords) {
      final hour = record.timestamp.hour;
      hourDistribution[hour] = (hourDistribution[hour] ?? 0) + 1;
    }

    // 检查是否主要集中在工作时间
    int workingHoursAccess = 0;
    for (int hour = 9; hour <= 15; hour++) {
      workingHoursAccess += hourDistribution[hour] ?? 0;
    }

    final totalAccess = accessRecords.length;
    final workingHoursRatio = workingHoursAccess / totalAccess;

    if (workingHoursRatio >= 0.8) {
      return TemporalPattern.workingHours;
    } else {
      return TemporalPattern.irregular;
    }
  }

  /// 分析数据波动性
  DataVolatility _analyzeDataVolatility() {
    final dataSizes =
        accessRecords.map((r) => r.dataSize).where((size) => size > 0).toList();

    if (dataSizes.length < 5) {
      return DataVolatility.unknown;
    }

    final meanSize = dataSizes.reduce((a, b) => a + b) / dataSizes.length;
    final variance = dataSizes.map((size) {
          final diff = size - meanSize;
          return diff * diff;
        }).reduce((a, b) => a + b) /
        dataSizes.length;

    final standardDeviation = math.sqrt(variance);
    final coefficientOfVariation = standardDeviation / meanSize;

    if (coefficientOfVariation <= 0.1) {
      return DataVolatility.low;
    } else if (coefficientOfVariation <= 0.3) {
      return DataVolatility.medium;
    } else {
      return DataVolatility.high;
    }
  }

  /// 获取最近访问次数
  int getRecentAccessCount() {
    final now = DateTime.now();
    return accessRecords
        .where(
            (record) => now.difference(record.timestamp) <= Duration(hours: 1))
        .length;
  }
}

/// 数据模型定义

/// 访问记录
class AccessRecord {
  final DateTime timestamp;
  final CacheAccessType accessType;
  final int dataSize;
  final Duration accessTime;
  final bool fromCache;

  const AccessRecord({
    required this.timestamp,
    required this.accessType,
    required this.dataSize,
    required this.accessTime,
    required this.fromCache,
  });
}

/// 访问模式
class AccessPattern {
  final AccessFrequency accessFrequency;
  final AccessPatternType accessPattern;
  final TemporalPattern temporalPattern;
  final DataVolatility dataVolatility;

  const AccessPattern({
    required this.accessFrequency,
    required this.accessPattern,
    required this.temporalPattern,
    required this.dataVolatility,
  });
}

/// 缓存访问类型
enum CacheAccessType {
  read,
  write,
  update,
  delete,
}

/// 访问频率
enum AccessFrequency {
  high,
  medium,
  low,
}

/// 访问模式枚举
enum AccessPatternType {
  sequential,
  random,
}

/// 时间模式
enum TemporalPattern {
  workingHours,
  offHours,
  irregular,
}

/// 数据波动性
enum DataVolatility {
  low,
  medium,
  high,
  unknown,
}

/// 缓存策略
enum CacheStrategy {
  standard,
  preload,
  keepInMemory,
  intelligent,
  longTerm,
}

/// 市场状态
enum MarketState {
  preMarket,
  trading,
  postMarket,
  closed,
  holiday,
}

/// 性能瓶颈
class PerformanceBottleneck {
  final BottleneckType type;
  final BottleneckSeverity severity;
  final String description;

  const PerformanceBottleneck({
    required this.type,
    required this.severity,
    required this.description,
  });
}

/// 瓶颈类型
enum BottleneckType {
  lowHitRate,
  highMemoryUsage,
  highAccessLatency,
}

/// 瓶颈严重程度
enum BottleneckSeverity {
  low,
  medium,
  high,
}

/// 缓存性能指标
class CachePerformanceMetrics {
  final List<PerformanceRecord> records = [];

  /// 记录访问
  void recordAccess(
    CacheAccessType accessType, {
    int? dataSize,
    Duration? accessTime,
    bool? fromCache,
  }) {
    records.add(PerformanceRecord(
      timestamp: DateTime.now(),
      accessType: accessType,
      dataSize: dataSize ?? 0,
      accessTime: accessTime ?? Duration.zero,
      fromCache: fromCache ?? false,
    ));

    // 保持记录数量
    while (records.length > 1000) {
      records.removeAt(0);
    }
  }

  /// 记录策略变更
  void recordStrategyChange(String indexCode, CacheStrategy strategy) {
    // 策略变更记录
  }

  /// 获取整体指标
  CacheOverallMetrics getOverallMetrics() {
    if (records.isEmpty) {
      return CacheOverallMetrics(
        overallHitRate: 0.0,
        memoryUsageRatio: 0.5,
        averageAccessTime: Duration.zero,
      );
    }

    final totalAccess = records.length;
    final cacheHits = records.where((r) => r.fromCache).length;
    final overallHitRate = totalAccess > 0 ? cacheHits / totalAccess : 0.0;

    final accessTimes = records.map((r) => r.accessTime).toList();
    final totalAccessTime =
        accessTimes.fold(Duration.zero, (sum, time) => sum + time);
    final averageAccessTime = Duration(
      milliseconds: totalAccessTime.inMilliseconds ~/ accessTimes.length,
    );

    return CacheOverallMetrics(
      overallHitRate: overallHitRate,
      memoryUsageRatio: 0.6, // 模拟值，实际应该从缓存管理器获取
      averageAccessTime: averageAccessTime,
    );
  }

  /// 重置指标
  void reset() {
    records.clear();
  }
}

/// 性能记录
class PerformanceRecord {
  final DateTime timestamp;
  final CacheAccessType accessType;
  final int dataSize;
  final Duration accessTime;
  final bool fromCache;

  const PerformanceRecord({
    required this.timestamp,
    required this.accessType,
    required this.dataSize,
    required this.accessTime,
    required this.fromCache,
  });
}

/// 整体性能指标
class CacheOverallMetrics {
  final double overallHitRate;
  final double memoryUsageRatio;
  final Duration averageAccessTime;

  const CacheOverallMetrics({
    required this.overallHitRate,
    required this.memoryUsageRatio,
    required this.averageAccessTime,
  });
}

/// 策略报告
class CacheStrategyReport {
  final DateTime timestamp;
  final MarketState marketState;
  final int totalTrackedIndices;
  final Map<CacheStrategy, int> strategyDistribution;
  final CacheOverallMetrics overallMetrics;
  final List<String> recommendations;

  const CacheStrategyReport({
    required this.timestamp,
    required this.marketState,
    required this.totalTrackedIndices,
    required this.strategyDistribution,
    required this.overallMetrics,
    required this.recommendations,
  });
}

/// 配置类

/// 智能缓存配置
class IntelligentCacheConfig {
  final Duration optimizationInterval;
  final Duration marketStateCheckInterval;
  final double minAcceptableHitRate;
  final double maxMemoryUsageRatio;
  final Duration maxAcceptableAccessTime;
  final int frequentAccessThreshold;
  final AccessPatternAnalyzerConfig patternAnalyzerConfig;
  final Duration analyzerExpirationTime;

  const IntelligentCacheConfig({
    this.optimizationInterval = const Duration(minutes: 5),
    this.marketStateCheckInterval = const Duration(minutes: 1),
    this.minAcceptableHitRate = 0.8,
    this.maxMemoryUsageRatio = 0.8,
    this.maxAcceptableAccessTime = const Duration(milliseconds: 100),
    this.frequentAccessThreshold = 10,
    this.patternAnalyzerConfig = const AccessPatternAnalyzerConfig(),
    this.analyzerExpirationTime = const Duration(hours: 24),
  });
}

/// 访问模式分析器配置
class AccessPatternAnalyzerConfig {
  final int maxRecords;
  final Duration frequencyAnalysisWindow;
  final int sequentialAccessThresholdSeconds;

  const AccessPatternAnalyzerConfig({
    this.maxRecords = 100,
    Duration? frequencyAnalysisWindow,
    this.sequentialAccessThresholdSeconds = 5,
  }) : frequencyAnalysisWindow =
            frequencyAnalysisWindow ?? const Duration(hours: 1);
}
