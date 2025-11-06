/// 缓存策略实现
///
/// 提供多种缓存策略实现，包括：
/// - LRU (最近最少使用)
/// - LFU (最少使用频率)
/// - TTL (时间过期)
/// - Adaptive (自适应)
/// - PriorityBased (基于优先级)
library cache_strategies;

import 'dart:async';
import 'dart:math' as math;
import '../interfaces/i_unified_cache_service.dart';

// ============================================================================
// LRU 缓存策略
// ============================================================================

/// LRU (Least Recently Used) 缓存策略
///
/// 基于最近访问时间的缓存淘汰策略，优先淘汰最久未访问的数据
class LRUCacheStrategy implements ICacheStrategy {
  @override
  DateTime calculateExpiry(
    String key,
    dynamic data,
    CacheConfig config,
  ) {
    // LRU策略主要基于访问时间，不过期时间由配置决定
    return DateTime.now().add(config.ttl ?? const Duration(hours: 24));
  }

  @override
  double calculatePriority(
    String key,
    dynamic data,
    CacheMetadata? metadata,
    int accessCount,
    DateTime lastAccess,
  ) {
    if (metadata == null) return 0.0;

    // 基于最后访问时间计算优先级
    final now = DateTime.now();
    final timeSinceLastAccess = now.difference(lastAccess).inMilliseconds;

    // 距离现在越近，优先级越高
    final timePriority = 1000000.0 / (timeSinceLastAccess + 1);

    // 结合基础优先级和访问频率
    final frequencyPriority = accessCount * 100.0;
    // 基于访问次数计算基础优先级，代替配置的priority
    final basePriority = metadata.accessCount.toDouble() * 1000.0;

    return basePriority + timePriority + frequencyPriority;
  }

  @override
  bool shouldEvict(
    String key,
    dynamic data,
    CacheConfig config,
    double memoryPressure,
  ) {
    // LRU策略不主动淘汰，由缓存管理器根据优先级淘汰
    return false;
  }

  @override
  String get strategyName => 'LRU';
}

// ============================================================================
// LFU 缓存策略
// ============================================================================

/// LFU (Least Frequently Used) 缓存策略
///
/// 基于访问频率的缓存淘汰策略，优先淘汰访问次数最少的数据
class LFUCacheStrategy implements ICacheStrategy {
  @override
  DateTime calculateExpiry(
    String key,
    dynamic data,
    CacheConfig config,
  ) {
    return DateTime.now().add(config.ttl ?? const Duration(hours: 12));
  }

  @override
  double calculatePriority(
    String key,
    dynamic data,
    CacheMetadata? metadata,
    int accessCount,
    DateTime lastAccess,
  ) {
    if (metadata == null) return 0.0;

    // LFU主要基于访问频率
    final frequencyPriority = accessCount * 10000.0;

    // 考虑时间的衰减因子（访问时间越久远，权重越低）
    final now = DateTime.now();
    final daysSinceLastAccess = now.difference(lastAccess).inDays;
    final timeDecayFactor =
        daysSinceLastAccess > 0 ? 1.0 / (daysSinceLastAccess + 1) : 1.0;

    // 基于访问次数和大小计算基础优先级
    final basePriority =
        metadata.accessCount.toDouble() * 1000.0 / (metadata.size / 1024 + 1);

    return basePriority + (frequencyPriority * timeDecayFactor);
  }

  @override
  bool shouldEvict(
    String key,
    dynamic data,
    CacheConfig config,
    double memoryPressure,
  ) {
    // LFU策略不主动淘汰
    return false;
  }

  @override
  String get strategyName => 'LFU';
}

// ============================================================================
// TTL 缓存策略
// ============================================================================

/// TTL (Time To Live) 缓存策略
///
/// 严格基于时间的缓存策略，过期即淘汰
class TTLCacheStrategy implements ICacheStrategy {
  @override
  DateTime calculateExpiry(
    String key,
    dynamic data,
    CacheConfig config,
  ) {
    final ttl = config.ttl ?? const Duration(hours: 1);
    return DateTime.now().add(ttl);
  }

  @override
  double calculatePriority(
    String key,
    dynamic data,
    CacheMetadata? metadata,
    int accessCount,
    DateTime lastAccess,
  ) {
    if (metadata == null) return 0.0;

    // TTL策略主要基于创建时间和访问时间
    final now = DateTime.now();
    final age = now.difference(metadata.createdAt);
    final timeSinceLastAccess = now.difference(metadata.lastAccessedAt);

    // 基于数据年龄计算优先级（越新创建的优先级越高）
    final agePriority =
        math.max(0.0, (86400000 - age.inMilliseconds) * 0.001); // 24小时为基准

    // 基于最后访问时间计算优先级
    final accessPriority = math.max(
        0.0, (3600000 - timeSinceLastAccess.inMilliseconds) * 0.001); // 1小时为基准

    // 基于数据大小和访问次数计算基础优先级
    final basePriority =
        (metadata.accessCount.toDouble() * 100.0) / (metadata.size / 1024 + 1);

    return basePriority + agePriority + accessPriority;
  }

  @override
  bool shouldEvict(
    String key,
    dynamic data,
    CacheConfig config,
    double memoryPressure,
  ) {
    // TTL策略依赖过期时间，不主动淘汰
    return false;
  }

  @override
  String get strategyName => 'TTL';
}

// ============================================================================
// Adaptive 缓存策略
// ============================================================================

/// Adaptive (自适应) 缓存策略
///
/// 根据访问模式和内存压力动态调整的智能缓存策略
class AdaptiveCacheStrategy implements ICacheStrategy {
  // 访问模式分析窗口
  static const int _analysisWindowSize = 100;

  // 访问历史记录
  final List<_AccessRecord> _accessHistory = [];

  // 统计信息
  _PatternStats _patternStats = const _PatternStats();

  @override
  DateTime calculateExpiry(
    String key,
    dynamic data,
    CacheConfig config,
  ) {
    final baseTtl = config.ttl ?? const Duration(hours: 2);

    // 根据访问模式动态调整TTL
    final patternMultiplier = _calculatePatternMultiplier(key);
    final adjustedTtl = Duration(
      milliseconds: (baseTtl.inMilliseconds * patternMultiplier).round(),
    );

    return DateTime.now().add(adjustedTtl);
  }

  @override
  double calculatePriority(
    String key,
    dynamic data,
    CacheMetadata? metadata,
    int accessCount,
    DateTime lastAccess,
  ) {
    if (metadata == null) return 0.0;

    // 综合多种因素计算优先级
    final timePriority = _calculateTimePriority(lastAccess);
    final frequencyPriority = _calculateFrequencyPriority(accessCount);
    final patternPriority = _calculatePatternPriority(key);
    // 基于元数据的多个属性计算自适应基础优先级
    final basePriority = _calculateAdaptiveBasePriority(metadata);

    return basePriority + timePriority + frequencyPriority + patternPriority;
  }

  @override
  bool shouldEvict(
    String key,
    dynamic data,
    CacheConfig config,
    double memoryPressure,
  ) {
    // 在高内存压力下，主动淘汰低优先级缓存
    if (memoryPressure > 0.8) {
      final priority = calculatePriority(key, data, null, 0, DateTime.now());
      return priority < 500.0; // 优先级阈值
    }

    return false;
  }

  @override
  String get strategyName => 'Adaptive';

  /// 记录访问以分析模式
  void recordAccess(String key) {
    final record = _AccessRecord(
      key: key,
      timestamp: DateTime.now(),
    );

    _accessHistory.add(record);

    // 维护窗口大小
    if (_accessHistory.length > _analysisWindowSize) {
      _accessHistory.removeAt(0);
    }

    // 更新模式统计
    _updatePatternStats();
  }

  /// 计算时间优先级
  double _calculateTimePriority(DateTime lastAccess) {
    final now = DateTime.now();
    final minutesSinceAccess = now.difference(lastAccess).inMinutes;

    // 时间越近，优先级越高
    return 10000.0 / (minutesSinceAccess + 1);
  }

  /// 计算频率优先级
  double _calculateFrequencyPriority(int accessCount) {
    // 访问次数越多，优先级越高，但有上限
    return (accessCount * 1000.0).clamp(0.0, 10000.0);
  }

  /// 计算自适应基础优先级
  double _calculateAdaptiveBasePriority(CacheMetadata metadata) {
    // 基于多个因素动态计算基础优先级
    final accessFactor = metadata.accessCount.toDouble();
    final sizeFactor = 1024.0 / (metadata.size + 1.0); // 小数据优先
    final timeFactor = _calculateTimeDecay(metadata.lastAccessedAt);

    return accessFactor * sizeFactor * timeFactor * 1000.0;
  }

  /// 计算时间衰减
  double _calculateTimeDecay(DateTime lastAccess) {
    final now = DateTime.now();
    final hoursSinceAccess = now.difference(lastAccess).inHours;

    // 时间衰减函数，最近访问的项有更高的权重
    return math.max(0.1, 1.0 / (1.0 + hoursSinceAccess / 24.0));
  }

  /// 计算模式优先级
  double _calculatePatternPriority(String key) {
    // 根据键的模式调整优先级
    if (_isSearchKey(key)) {
      return _patternStats.searchPatternBonus;
    } else if (_isFilterKey(key)) {
      return _patternStats.filterPatternBonus;
    } else if (_isUserDataKey(key)) {
      return _patternStats.userDataPatternBonus;
    }

    return 0.0;
  }

  /// 计算模式倍数
  double _calculatePatternMultiplier(String key) {
    if (_isSearchKey(key)) {
      // 搜索缓存根据查询复杂度调整
      return _getSearchComplexityMultiplier(key);
    } else if (_isFilterKey(key)) {
      // 筛选缓存相对稳定
      return 1.2;
    } else if (_isUserDataKey(key)) {
      // 用户数据缓存时间较长
      return 1.5;
    }

    return 1.0;
  }

  /// 判断是否为搜索键
  bool _isSearchKey(String key) {
    return key.startsWith('search_') || key.contains('query');
  }

  /// 判断是否为筛选键
  bool _isFilterKey(String key) {
    return key.startsWith('filter_') || key.contains('criteria');
  }

  /// 判断是否为用户数据键
  bool _isUserDataKey(String key) {
    return key.startsWith('user_') || key.startsWith('profile_');
  }

  /// 获取搜索复杂度倍数
  double _getSearchComplexityMultiplier(String key) {
    // 根据搜索关键词长度判断复杂度
    final complexity = key.length;

    if (complexity < 10) return 0.5; // 简单搜索，缓存时间短
    if (complexity < 20) return 1.0; // 中等搜索，标准缓存时间
    if (complexity < 50) return 1.5; // 复杂搜索，缓存时间长
    return 2.0; // 非常复杂的搜索，缓存时间很长
  }

  /// 更新模式统计
  void _updatePatternStats() {
    if (_accessHistory.isEmpty) return;

    final recentAccesses = _accessHistory.take(50).toList();
    final searchCount = recentAccesses.where((r) => _isSearchKey(r.key)).length;
    final filterCount = recentAccesses.where((r) => _isFilterKey(r.key)).length;
    final userDataCount =
        recentAccesses.where((r) => _isUserDataKey(r.key)).length;

    final total = recentAccesses.length;

    _patternStats = _PatternStats(
      searchPatternBonus: (searchCount / total * 2000.0).clamp(0.0, 2000.0),
      filterPatternBonus: (filterCount / total * 1500.0).clamp(0.0, 1500.0),
      userDataPatternBonus: (userDataCount / total * 2500.0).clamp(0.0, 2500.0),
    );
  }
}

// ============================================================================
// PriorityBased 缓存策略
// ============================================================================

/// PriorityBased (基于优先级) 缓存策略
///
/// 严格基于配置优先级的缓存策略
class PriorityBasedCacheStrategy implements ICacheStrategy {
  @override
  DateTime calculateExpiry(
    String key,
    dynamic data,
    CacheConfig config,
  ) {
    // 根据优先级调整TTL
    final baseTtl = config.ttl ?? const Duration(hours: 1);
    final priorityMultiplier = _getPriorityMultiplier(config.priority);

    final adjustedTtl = Duration(
      milliseconds: (baseTtl.inMilliseconds * priorityMultiplier).round(),
    );

    return DateTime.now().add(adjustedTtl);
  }

  @override
  double calculatePriority(
    String key,
    dynamic data,
    CacheMetadata? metadata,
    int accessCount,
    DateTime lastAccess,
  ) {
    // 基于元数据计算优先级，主要考虑访问频率和数据大小
    if (metadata == null) return 0.0;
    final accessPriority = metadata.accessCount.toDouble() * 10000.0;
    final sizePenalty = (metadata.size / 1024).clamp(0.0, 100.0); // KB为单位的惩罚
    return accessPriority / (1.0 + sizePenalty);
  }

  @override
  bool shouldEvict(
    String key,
    dynamic data,
    CacheConfig config,
    double memoryPressure,
  ) {
    // 低优先级缓存在高内存压力下主动淘汰
    if (memoryPressure > 0.7 && config.priority < 3) {
      return true;
    }

    if (memoryPressure > 0.9 && config.priority < 5) {
      return true;
    }

    return false;
  }

  @override
  String get strategyName => 'PriorityBased';

  /// 获取优先级倍数
  double _getPriorityMultiplier(int priority) {
    switch (priority) {
      case 0:
        return 0.1; // 最低优先级，缓存时间很短
      case 1:
        return 0.3;
      case 2:
        return 0.5;
      case 3:
        return 0.8;
      case 4:
        return 1.0; // 标准优先级
      case 5:
        return 1.2;
      case 6:
        return 1.5;
      case 7:
        return 2.0;
      case 8:
        return 3.0;
      case 9:
        return 5.0; // 高优先级，缓存时间长
      case 10:
        return 10.0; // 最高优先级，缓存时间很长
      default:
        return 1.0;
    }
  }
}

// ============================================================================
// Hybrid 缓存策略
// ============================================================================

/// Hybrid (混合) 缓存策略
///
/// 结合多种策略优点的混合缓存策略
class HybridCacheStrategy implements ICacheStrategy {
  final LRUCacheStrategy _lruStrategy = LRUCacheStrategy();
  final AdaptiveCacheStrategy _adaptiveStrategy = AdaptiveCacheStrategy();
  final PriorityBasedCacheStrategy _priorityStrategy =
      PriorityBasedCacheStrategy();

  @override
  DateTime calculateExpiry(
    String key,
    dynamic data,
    CacheConfig config,
  ) {
    // 混合策略：取各策略的中间值
    final lruExpiry = _lruStrategy.calculateExpiry(key, data, config);
    final adaptiveExpiry = _adaptiveStrategy.calculateExpiry(key, data, config);
    final priorityExpiry = _priorityStrategy.calculateExpiry(key, data, config);

    final lruMs = lruExpiry.millisecondsSinceEpoch;
    final adaptiveMs = adaptiveExpiry.millisecondsSinceEpoch;
    final priorityMs = priorityExpiry.millisecondsSinceEpoch;

    // 取中间值
    final expiryMs = [lruMs, adaptiveMs, priorityMs]..sort();
    final middleMs = expiryMs[1];

    return DateTime.fromMillisecondsSinceEpoch(middleMs);
  }

  @override
  double calculatePriority(
    String key,
    dynamic data,
    CacheMetadata? metadata,
    int accessCount,
    DateTime lastAccess,
  ) {
    // 加权平均计算优先级
    final lruPriority = _lruStrategy.calculatePriority(
      key,
      data,
      metadata,
      accessCount,
      lastAccess,
    );
    final adaptivePriority = _adaptiveStrategy.calculatePriority(
      key,
      data,
      metadata,
      accessCount,
      lastAccess,
    );
    final priorityBasedPriority = _priorityStrategy.calculatePriority(
      key,
      data,
      metadata,
      accessCount,
      lastAccess,
    );

    // 权重分配：LRU 30%, Adaptive 40%, Priority 30%
    return (lruPriority * 0.3) +
        (adaptivePriority * 0.4) +
        (priorityBasedPriority * 0.3);
  }

  @override
  bool shouldEvict(
    String key,
    dynamic data,
    CacheConfig config,
    double memoryPressure,
  ) {
    // 综合各策略的淘汰决策
    final lruShouldEvict =
        _lruStrategy.shouldEvict(key, data, config, memoryPressure);
    final adaptiveShouldEvict =
        _adaptiveStrategy.shouldEvict(key, data, config, memoryPressure);
    final priorityShouldEvict =
        _priorityStrategy.shouldEvict(key, data, config, memoryPressure);

    // 任一策略建议淘汰则淘汰
    return lruShouldEvict || adaptiveShouldEvict || priorityShouldEvict;
  }

  @override
  String get strategyName => 'Hybrid';
}

// ============================================================================
// 辅助类定义
// ============================================================================

/// 访问记录（内部使用）
class _AccessRecord {
  final String key;
  final DateTime timestamp;

  const _AccessRecord({
    required this.key,
    required this.timestamp,
  });
}

/// 模式统计信息（内部使用）
class _PatternStats {
  final double searchPatternBonus;
  final double filterPatternBonus;
  final double userDataPatternBonus;

  const _PatternStats({
    this.searchPatternBonus = 0.0,
    this.filterPatternBonus = 0.0,
    this.userDataPatternBonus = 0.0,
  });
}

// ============================================================================
// 策略工厂
// ============================================================================

/// 缓存策略工厂
///
/// 提供策略实例的创建和管理
class CacheStrategyFactory {
  static final Map<String, ICacheStrategy> _strategies = {};

  /// 获取策略实例
  static ICacheStrategy getStrategy(String name) {
    return _strategies.putIfAbsent(name, () => _createStrategy(name));
  }

  /// 创建策略实例
  static ICacheStrategy _createStrategy(String name) {
    switch (name.toLowerCase()) {
      case 'lru':
        return LRUCacheStrategy();
      case 'lfu':
        return LFUCacheStrategy();
      case 'ttl':
        return TTLCacheStrategy();
      case 'adaptive':
        return AdaptiveCacheStrategy();
      case 'priority':
      case 'prioritybased':
        return PriorityBasedCacheStrategy();
      case 'hybrid':
        return HybridCacheStrategy();
      default:
        throw ArgumentError('Unknown cache strategy: $name');
    }
  }

  /// 获取所有可用策略名称
  static List<String> getAvailableStrategies() {
    return [
      'lru',
      'lfu',
      'ttl',
      'adaptive',
      'priority',
      'hybrid',
    ];
  }

  /// 注册自定义策略
  static void registerStrategy(String name, ICacheStrategy strategy) {
    _strategies[name] = strategy;
  }

  /// 预热策略缓存
  static void warmupStrategies() {
    for (final name in getAvailableStrategies()) {
      getStrategy(name);
    }
  }

  // 增强功能方法

  /// 获取策略性能统计
  static StrategyPerformanceStats? getPerformanceStats(String name) {
    return EnhancedCacheStrategyFactory.getPerformanceStats(name);
  }

  /// 获取推荐策略
  static String getRecommendedStrategy({
    required CacheWorkloadType workloadType,
    required CachePerformanceGoal performanceGoal,
    Map<String, dynamic>? constraints,
  }) {
    return EnhancedCacheStrategyFactory.getRecommendedStrategy(
      workloadType: workloadType,
      performanceGoal: performanceGoal,
      constraints: constraints,
    );
  }
}

// ============================================================================
// 增强策略工厂和相关类
// ============================================================================

/// 策略描述符
class StrategyDescriptor {
  final String name;
  final String displayName;
  final String description;
  final ICacheStrategy Function(Map<String, dynamic>) factory;
  final StrategyCategory category;
  final List<CacheWorkloadType> suitableWorkloads;
  final Map<String, double> performanceCharacteristics;

  const StrategyDescriptor({
    required this.name,
    required this.displayName,
    required this.description,
    required this.factory,
    required this.category,
    required this.suitableWorkloads,
    required this.performanceCharacteristics,
  });
}

/// 策略类别
enum StrategyCategory {
  basic,
  advanced,
  composite,
  custom,
}

/// 缓存工作负载类型
enum CacheWorkloadType {
  readHeavy,
  writeHeavy,
  mixed,
  patternBased,
}

/// 缓存性能目标
enum CachePerformanceGoal {
  hitRate,
  responseTime,
  memoryEfficiency,
}

/// 组合类型
enum CompositionType {
  weighted, // 加权平均
  chained, // 链式调用
  conditional, // 条件选择
  adaptive, // 自适应选择
}

/// 策略性能监控器
class StrategyPerformanceMonitor {
  final Map<String, StrategyPerformanceData> _performanceData = {};
  Timer? _monitoringTimer;

  void start() {
    _monitoringTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _updatePerformanceMetrics();
    });
  }

  void stop() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
  }

  void registerStrategy(String name, ICacheStrategy strategy) {
    _performanceData[name] = StrategyPerformanceData(
      name: name,
      strategy: strategy,
      startTime: DateTime.now(),
    );
  }

  void recordOperation(
      String strategyName, String operation, int responseTime, bool success) {
    final data = _performanceData[strategyName];
    if (data != null) {
      data.recordOperation(operation, responseTime, success);
    }
  }

  StrategyPerformanceStats? getStats(String strategyName) {
    final data = _performanceData[strategyName];
    if (data == null) return null;

    return data.calculateStats();
  }

  Map<String, StrategyPerformanceStats> getAllStats() {
    final stats = <String, StrategyPerformanceStats>{};
    for (final entry in _performanceData.entries) {
      final statsData = entry.value.calculateStats();
      if (statsData != null) {
        stats[entry.key] = statsData;
      }
    }
    return stats;
  }

  void switchStrategy(String fromName, String toName) {
    print('Switching from $fromName to $toName');
  }

  void _updatePerformanceMetrics() {
    for (final data in _performanceData.values) {
      data.updateMetrics();
    }
  }
}

/// 策略性能数据
class StrategyPerformanceData {
  final String name;
  final ICacheStrategy strategy;
  final DateTime startTime;

  int totalOperations = 0;
  int successfulOperations = 0;
  int totalResponseTime = 0;
  int totalHits = 0;
  int totalMisses = 0;
  int totalSize = 0;
  int evictions = 0;

  StrategyPerformanceData({
    required this.name,
    required this.strategy,
    required this.startTime,
  });

  void recordOperation(String operation, int responseTime, bool success) {
    totalOperations++;
    if (success) {
      successfulOperations++;
    }
    totalResponseTime += responseTime;

    if (operation == 'get') {
      if (responseTime < 100) {
        totalHits++;
      } else {
        totalMisses++;
      }
    }
  }

  void recordStorage(int size) {
    totalSize += size;
  }

  void recordEviction() {
    evictions++;
  }

  StrategyPerformanceStats? calculateStats() {
    if (totalOperations == 0) return null;

    return StrategyPerformanceStats(
      name: name,
      hitRate: totalHits / (totalHits + totalMisses),
      averageResponseTime: totalResponseTime / totalOperations,
      memoryEfficiency:
          totalSize > 0 ? 1.0 - (evictions / totalOperations) : 1.0,
      totalOperations: totalOperations,
      successRate: successfulOperations / totalOperations,
      uptime: DateTime.now().difference(startTime),
    );
  }

  void updateMetrics() {
    // 定期更新指标
  }
}

/// 策略性能统计
class StrategyPerformanceStats {
  final String name;
  final double hitRate;
  final double averageResponseTime;
  final double memoryEfficiency;
  final int totalOperations;
  final double successRate;
  final Duration uptime;

  const StrategyPerformanceStats({
    required this.name,
    required this.hitRate,
    required this.averageResponseTime,
    required this.memoryEfficiency,
    required this.totalOperations,
    required this.successRate,
    required this.uptime,
  });
}

/// 策略切换结果
class StrategySwitchResult {
  final String fromStrategy;
  final String toStrategy;
  final DateTime startTime;
  DateTime? endTime;
  bool success = false;
  String? error;

  StrategySwitchResult({
    required this.fromStrategy,
    required this.toStrategy,
    required this.startTime,
  });

  Duration? get executionTime => endTime?.difference(startTime);
}

/// 增强缓存策略工厂
///
/// 提供完整的策略生命周期管理
class EnhancedCacheStrategyFactory {
  static final EnhancedCacheStrategyFactory _instance =
      EnhancedCacheStrategyFactory._internal();
  factory EnhancedCacheStrategyFactory() => _instance;
  EnhancedCacheStrategyFactory._internal();

  // 策略注册表
  final Map<String, StrategyDescriptor> _registeredStrategies = {};
  final Map<String, ICacheStrategy> _strategyInstances = {};

  // 性能监控
  final StrategyPerformanceMonitor _performanceMonitor =
      StrategyPerformanceMonitor();

  /// 初始化工厂
  void initialize() {
    _registerBuiltInStrategies();
    _performanceMonitor.start();
  }

  /// 获取策略性能统计
  static StrategyPerformanceStats? getPerformanceStats(String name) {
    final instance = EnhancedCacheStrategyFactory();
    if (!instance._performanceMonitor._performanceData.containsKey(name)) {
      return null;
    }
    return instance._performanceMonitor.getStats(name);
  }

  /// 获取推荐策略
  static String getRecommendedStrategy({
    required CacheWorkloadType workloadType,
    required CachePerformanceGoal performanceGoal,
    Map<String, dynamic>? constraints,
  }) {
    // 基于工作负载类型和性能目标推荐策略
    switch (workloadType) {
      case CacheWorkloadType.readHeavy:
        switch (performanceGoal) {
          case CachePerformanceGoal.hitRate:
            return 'adaptive';
          case CachePerformanceGoal.responseTime:
            return 'lru';
          case CachePerformanceGoal.memoryEfficiency:
            return 'lfu';
        }
      case CacheWorkloadType.writeHeavy:
        return 'ttl';
      case CacheWorkloadType.mixed:
        switch (performanceGoal) {
          case CachePerformanceGoal.hitRate:
            return 'hybrid';
          case CachePerformanceGoal.responseTime:
            return 'priority';
          case CachePerformanceGoal.memoryEfficiency:
            return 'adaptive';
        }
      case CacheWorkloadType.patternBased:
        return 'adaptive';
    }
  }

  void _registerBuiltInStrategies() {
    // 注册基础策略描述符
    _registeredStrategies['lru'] = StrategyDescriptor(
      name: 'lru',
      displayName: 'LRU (Least Recently Used)',
      description: '基于最近访问时间的缓存淘汰策略',
      factory: (params) => LRUCacheStrategy(),
      category: StrategyCategory.basic,
      suitableWorkloads: [CacheWorkloadType.readHeavy, CacheWorkloadType.mixed],
      performanceCharacteristics: {
        'hitRate': 0.7,
        'responseTime': 50,
        'memoryEfficiency': 0.6,
        'complexity': 1,
      },
    );

    _registeredStrategies['lfu'] = StrategyDescriptor(
      name: 'lfu',
      displayName: 'LFU (Least Frequently Used)',
      description: '基于访问频率的缓存淘汰策略',
      factory: (params) => LFUCacheStrategy(),
      category: StrategyCategory.basic,
      suitableWorkloads: [CacheWorkloadType.patternBased],
      performanceCharacteristics: {
        'hitRate': 0.75,
        'responseTime': 60,
        'memoryEfficiency': 0.8,
        'complexity': 2,
      },
    );

    _registeredStrategies['ttl'] = StrategyDescriptor(
      name: 'ttl',
      displayName: 'TTL (Time To Live)',
      description: '基于时间的缓存过期策略',
      factory: (params) => TTLCacheStrategy(),
      category: StrategyCategory.basic,
      suitableWorkloads: [CacheWorkloadType.writeHeavy],
      performanceCharacteristics: {
        'hitRate': 0.6,
        'responseTime': 30,
        'memoryEfficiency': 0.9,
        'complexity': 1,
      },
    );

    _registeredStrategies['adaptive'] = StrategyDescriptor(
      name: 'adaptive',
      displayName: 'Adaptive Strategy',
      description: '自适应学习缓存策略',
      factory: (params) => AdaptiveCacheStrategy(),
      category: StrategyCategory.advanced,
      suitableWorkloads: [
        CacheWorkloadType.patternBased,
        CacheWorkloadType.mixed
      ],
      performanceCharacteristics: {
        'hitRate': 0.85,
        'responseTime': 70,
        'memoryEfficiency': 0.7,
        'complexity': 4,
      },
    );

    _registeredStrategies['priority'] = StrategyDescriptor(
      name: 'priority',
      displayName: 'Priority-Based Strategy',
      description: '基于优先级的缓存策略',
      factory: (params) => PriorityBasedCacheStrategy(),
      category: StrategyCategory.basic,
      suitableWorkloads: [CacheWorkloadType.mixed],
      performanceCharacteristics: {
        'hitRate': 0.65,
        'responseTime': 40,
        'memoryEfficiency': 0.5,
        'complexity': 2,
      },
    );

    _registeredStrategies['hybrid'] = StrategyDescriptor(
      name: 'hybrid',
      displayName: 'Hybrid Strategy',
      description: '混合多种策略的综合缓存策略',
      factory: (params) => HybridCacheStrategy(),
      category: StrategyCategory.composite,
      suitableWorkloads: [CacheWorkloadType.mixed],
      performanceCharacteristics: {
        'hitRate': 0.8,
        'responseTime': 65,
        'memoryEfficiency': 0.65,
        'complexity': 3,
      },
    );
  }
}
