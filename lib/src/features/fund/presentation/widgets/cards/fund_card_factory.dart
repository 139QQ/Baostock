import 'package:flutter/material.dart';

import '../../../../../core/performance/performance_detector.dart';
import '../../../domain/entities/fund.dart';
import 'adaptive_fund_card.dart';
import 'base_fund_card.dart';
import 'microinteractive_fund_card.dart';

/// 基金卡片工厂类
///
/// 统一管理所有基金卡片组件的创建，提供：
/// - 智能组件选择算法
/// - 性能自适应配置
/// - 统一的创建接口
/// - 高效组件缓存和复用
class FundCardFactory {
  static final Map<String, _CacheEntry> _cardCache = {};
  static final Map<String, FundCardConfig> _configCache = {};

  // 缓存统计
  static int _totalRequests = 0;
  static int _cacheHits = 0;
  static int _cacheMisses = 0;

  // LRU访问时间跟踪
  static final Map<String, DateTime> _accessTimes = {};

  // 激进缓存策略
  static final Map<String, int> _accessFrequency = {};
  static final Set<String> _highAccessCache = {};
  static final Map<String, int> _cardUsagePattern = {};

  // 缓存优化参数
  static const int _highAccessThreshold = 3;
  static const int _maxCacheSize = 200;
  static const Duration _cacheExpirationTime = Duration(minutes: 30);

  /// 创建基金卡片
  ///
  /// 根据设备性能和用户偏好自动选择最适合的卡片类型
  static Widget createFundCard({
    required Fund fund,
    required FundCardType cardType,
    bool showComparisonCheckbox = false,
    bool showQuickActions = true,
    bool isSelected = false,
    bool compactMode = false,
    VoidCallback? onTap,
    Function(bool)? onSelectionChanged,
    VoidCallback? onAddToWatchlist,
    VoidCallback? onCompare,
    VoidCallback? onShare,
    Function()? onSwipeLeft,
    Function()? onSwipeRight,
    FundCardConfig? config,
    PerformanceLevelSimple? performanceLevel,
    bool forceCreate = false,
  }) {
    // 生成简化的缓存键 - 激进策略只关注核心参数
    final coreCacheKey = _generateSimplifiedCacheKey(fund, cardType);

    // 先尝试匹配核心缓存键（忽略回调函数等动态参数）
    if (!forceCreate && _cardCache.containsKey(coreCacheKey)) {
      _totalRequests++;
      _cacheHits++;
      _updateAccessStatistics(coreCacheKey);
      return _cardCache[coreCacheKey]!.widget;
    }

    // 如果核心缓存未命中，尝试完整缓存键
    final fullCacheKey = _generateCacheKey(fund, cardType, config);
    if (!forceCreate && _cardCache.containsKey(fullCacheKey)) {
      _totalRequests++;
      _cacheHits++;
      _updateAccessStatistics(fullCacheKey);
      return _cardCache[fullCacheKey]!.widget;
    }

    _totalRequests++;
    _cacheMisses++;

    // 创建新卡片
    Widget card;

    switch (cardType) {
      case FundCardType.adaptive:
        card = AdaptiveFundCard(
          key: ValueKey('adaptive_${fund.code}'),
          fund: fund,
          showComparisonCheckbox: showComparisonCheckbox,
          showQuickActions: showQuickActions,
          isSelected: isSelected,
          compactMode: compactMode,
          onTap: onTap,
          onSelectionChanged: onSelectionChanged,
          onAddToWatchlist: onAddToWatchlist,
          onCompare: onCompare,
          onShare: onShare,
          onSwipeLeft: onSwipeLeft,
          onSwipeRight: onSwipeRight,
          performanceLevel: performanceLevel ?? PerformanceLevelSimple.medium,
          enablePerformanceMonitoring:
              config?.enablePerformanceMonitoring ?? true,
          enableAccessibility: config?.enableAccessibility ?? true,
        );
        break;

      case FundCardType.microinteractive:
        card = MicrointeractiveFundCard(
          key: ValueKey('micro_${fund.code}'),
          fund: fund,
          showComparisonCheckbox: showComparisonCheckbox,
          showQuickActions: showQuickActions,
          isSelected: isSelected,
          compactMode: compactMode,
          onTap: onTap,
          onSelectionChanged: onSelectionChanged,
          onAddToWatchlist: onAddToWatchlist,
          onCompare: onCompare,
          onShare: onShare,
          onSwipeLeft: onSwipeLeft,
          onSwipeRight: onSwipeRight,
          performanceLevel: performanceLevel ?? PerformanceLevelSimple.medium,
          enablePerformanceMonitoring:
              config?.enablePerformanceMonitoring ?? true,
          enableAccessibility: config?.enableAccessibility ?? true,
          enableSwipeGestures: true,
          enableHapticFeedback: config?.enableGestureFeedback ?? true,
          enableRippleEffects: config?.animationLevel == 2,
        );
        break;
    }

    // 缓存卡片 - 优先使用简化键提高复用率
    final finalCacheKey = coreCacheKey; // 使用简化键提高复用率

    final cacheEntry = _CacheEntry(
      widget: card,
      createdAt: DateTime.now(),
      lastAccessedAt: DateTime.now(),
      accessCount: 1,
    );

    _cardCache[finalCacheKey] = cacheEntry;
    _accessTimes[finalCacheKey] = DateTime.now();
    _updateAccessStatistics(finalCacheKey);

    return card;
  }

  /// 智能创建基金卡片
  ///
  /// 根据设备性能自动选择最适合的卡片类型
  static Future<Widget> createSmartFundCard({
    required Fund fund,
    bool showComparisonCheckbox = false,
    bool showQuickActions = true,
    bool isSelected = false,
    bool compactMode = false,
    VoidCallback? onTap,
    Function(bool)? onSelectionChanged,
    VoidCallback? onAddToWatchlist,
    VoidCallback? onCompare,
    VoidCallback? onShare,
    Function()? onSwipeLeft,
    Function()? onSwipeRight,
    FundCardConfig? config,
  }) async {
    final performanceDetector = SmartPerformanceDetector.instance;
    final performanceResult = await performanceDetector.detectPerformance();
    final performanceLevelSimple =
        _convertToSimpleLevel(performanceResult.level);
    final recommendedType =
        _getRecommendedCardType(performanceLevelSimple, config);

    return createFundCard(
      fund: fund,
      cardType: recommendedType,
      showComparisonCheckbox: showComparisonCheckbox,
      showQuickActions: showQuickActions,
      isSelected: isSelected,
      compactMode: compactMode,
      onTap: onTap,
      onSelectionChanged: onSelectionChanged,
      onAddToWatchlist: onAddToWatchlist,
      onCompare: onCompare,
      onShare: onShare,
      onSwipeLeft: onSwipeLeft,
      onSwipeRight: onSwipeRight,
      config: config,
      performanceLevel: performanceLevelSimple,
    );
  }

  /// 批量创建基金卡片
  ///
  /// 优化性能，支持懒加载和复用
  static List<Widget> createFundCardList({
    required List<Fund> funds,
    required FundCardType cardType,
    bool showComparisonCheckbox = false,
    bool showQuickActions = true,
    Set<String>? selectedFunds,
    Map<String, VoidCallback>? onTapCallbacks,
    Map<String, Function(bool)>? onSelectionCallbacks,
    Map<String, VoidCallback>? onWatchlistCallbacks,
    Map<String, VoidCallback>? onCompareCallbacks,
    FundCardConfig? config,
    bool enableCaching = true,
  }) {
    final cards = <Widget>[];
    final effectiveConfig = config ?? FundCardFactory.getDefaultConfig();

    for (int i = 0; i < funds.length; i++) {
      final fund = funds[i];
      final isSelected = selectedFunds?.contains(fund.code) ?? false;

      final card = createFundCard(
        fund: fund,
        cardType: cardType,
        showComparisonCheckbox: showComparisonCheckbox,
        showQuickActions: showQuickActions,
        isSelected: isSelected,
        onTap: onTapCallbacks?[fund.code],
        onSelectionChanged: onSelectionCallbacks?[fund.code],
        onAddToWatchlist: onWatchlistCallbacks?[fund.code],
        onCompare: onCompareCallbacks?[fund.code],
        config: effectiveConfig,
      );

      cards.add(card);
    }

    return cards;
  }

  /// 将详细的性能级别转换为简化级别
  static PerformanceLevelSimple _convertToSimpleLevel(
      PerformanceLevel performanceLevel) {
    switch (performanceLevel) {
      case PerformanceLevel.excellent:
      case PerformanceLevel.good:
        return PerformanceLevelSimple.high;
      case PerformanceLevel.fair:
        return PerformanceLevelSimple.medium;
      case PerformanceLevel.poor:
        return PerformanceLevelSimple.low;
    }
  }

  /// 获取推荐的卡片类型
  static FundCardType _getRecommendedCardType(
    PerformanceLevelSimple performanceLevel,
    FundCardConfig? config,
  ) {
    final animationLevel = config?.animationLevel ?? 1;

    // 如果用户明确禁用动画，返回自适应卡片（基础版）
    if (animationLevel == 0) {
      return FundCardType.adaptive;
    }

    // 根据设备性能推荐卡片类型
    switch (performanceLevel) {
      case PerformanceLevelSimple.high:
        return FundCardType.microinteractive;
      case PerformanceLevelSimple.medium:
        return FundCardType.adaptive;
      case PerformanceLevelSimple.low:
        return FundCardType.adaptive;
    }
  }

  /// 生成简化缓存键 - 激进策略
  static String _generateSimplifiedCacheKey(Fund fund, FundCardType cardType) {
    // 只包含核心不变的参数，忽略回调函数等动态参数
    return '${fund.code}_${cardType.name}_core';
  }

  /// 生成完整缓存键
  static String _generateCacheKey(
      Fund fund, FundCardType cardType, FundCardConfig? config) {
    final configHash = config?.hashCode ?? 0;
    return '${fund.code}_${cardType.name}_full_$configHash';
  }

  /// 更新访问统计 - 激进策略
  static void _updateAccessStatistics(String cacheKey) {
    final now = DateTime.now();
    _accessTimes[cacheKey] = now;

    // 更新访问频率
    _accessFrequency[cacheKey] = (_accessFrequency[cacheKey] ?? 0) + 1;

    // 标记高频访问
    if (_accessFrequency[cacheKey]! >= _highAccessThreshold) {
      _highAccessCache.add(cacheKey);
    }

    // 更新缓存条目
    final entry = _cardCache[cacheKey];
    if (entry != null) {
      entry.updateAccess();
    }

    // 定期清理过期缓存和优化缓存策略
    _performPeriodicOptimization();
  }

  /// 执行定期优化 - 激进策略
  static void _performPeriodicOptimization() {
    // 每100次请求执行一次优化
    if (_totalRequests % 100 == 0) {
      _optimizeAggressiveCache();
    }
  }

  /// 激进缓存优化策略
  static void _optimizeAggressiveCache() {
    final now = DateTime.now();
    final keysToRemove = <String>[];

    // 清理过期缓存
    for (final entry in _cardCache.entries) {
      final key = entry.key;
      final cacheEntry = entry.value;

      // 清理超过过期时间的缓存
      if (now.difference(cacheEntry.createdAt) > _cacheExpirationTime) {
        keysToRemove.add(key);
        continue;
      }

      // 保护高频访问的缓存，清理低频缓存
      if (!_highAccessCache.contains(key) &&
          cacheEntry.accessCount < 2 &&
          now.difference(cacheEntry.lastAccessedAt).inMinutes > 5) {
        keysToRemove.add(key);
      }
    }

    // 如果缓存仍然过大，优先保留高频访问的
    if (_cardCache.length - keysToRemove.length > _maxCacheSize) {
      final sortedEntries = _cardCache.entries
          .where((e) => !_highAccessCache.contains(e.key))
          .toList()
        ..sort(
            (a, b) => a.value.lastAccessedAt.compareTo(b.value.lastAccessedAt));

      final excessToRemove =
          _cardCache.length - keysToRemove.length - _maxCacheSize;
      for (int i = 0; i < excessToRemove && i < sortedEntries.length; i++) {
        keysToRemove.add(sortedEntries[i].key);
      }
    }

    // 清理标识的缓存
    for (final key in keysToRemove) {
      _cardCache.remove(key);
      _accessTimes.remove(key);
      _accessFrequency.remove(key);
      _highAccessCache.remove(key);
    }
  }

  /// 清理缓存
  static void clearCache() {
    _cardCache.clear();
    _configCache.clear();
    _accessTimes.clear();
    _accessFrequency.clear();
    _highAccessCache.clear();
    _cardUsagePattern.clear();
    _totalRequests = 0;
    _cacheHits = 0;
    _cacheMisses = 0;
  }

  /// 清理特定基金的缓存
  static void clearFundCache(String fundCode) {
    final keysToRemove =
        _cardCache.keys.where((key) => key.startsWith('${fundCode}_')).toList();

    for (final key in keysToRemove) {
      _cardCache.remove(key);
      _accessTimes.remove(key);
    }
  }

  /// 获取缓存统计信息
  static Map<String, dynamic> getCacheStats() {
    return {
      'totalCachedCards': _cardCache.length,
      'totalCachedConfigs': _configCache.length,
      'memoryUsageEstimate': _cardCache.length * 1024, // 粗略估算
    };
  }

  /// 更新访问时间
  static void _updateAccessTime(String cacheKey) {
    _accessTimes[cacheKey] = DateTime.now();
    final entry = _cardCache[cacheKey];
    if (entry != null) {
      entry.updateAccess();
    }
  }

  /// 获取缓存大小 (向后兼容接口)
  static int get cacheSize => _cardCache.length;

  /// 获取缓存效率 (真实统计数据)
  static double getCacheEfficiency() {
    if (_totalRequests == 0) return 0.0;
    return (_cacheHits / _totalRequests) * 100;
  }

  /// 获取缓存命中率
  static double get cacheHitRate {
    if (_totalRequests == 0) return 0.0;
    return _cacheHits / _totalRequests;
  }

  /// 获取缓存统计信息
  static Map<String, dynamic> getDetailedCacheStats() {
    return {
      'totalRequests': _totalRequests,
      'cacheHits': _cacheHits,
      'cacheMisses': _cacheMisses,
      'hitRate': cacheHitRate,
      'efficiency': getCacheEfficiency(),
      'cacheSize': _cardCache.length,
      'configCacheSize': _configCache.length,
      'memoryUsageEstimate': _cardCache.length * 1024, // 粗略估算
    };
  }

  /// 预热缓存 - 激进策略
  ///
  /// 预先创建常用卡片以提升用户体验和缓存命中率
  static Future<void> warmupCache({
    required List<Fund> popularFunds,
    FundCardType preferredType = FundCardType.adaptive,
    FundCardConfig? config,
  }) async {
    for (final fund in popularFunds.take(20)) {
      // 增加预热数量
      // 多次访问同一卡片以触发高频缓存保护
      for (int i = 0; i < 3; i++) {
        createFundCard(
          fund: fund,
          cardType: preferredType,
          config: config,
        );
      }
    }
  }

  /// 批量预热缓存 - 智能策略
  static Future<void> batchWarmupCache({
    required List<Fund> funds,
    Map<FundCardType, FundCardConfig?>? configs,
  }) async {
    final cardTypes = FundCardType.values;

    for (final fund in funds.take(15)) {
      for (final cardType in cardTypes) {
        final config = configs?[cardType];

        // 为每种卡片类型创建缓存
        createFundCard(
          fund: fund,
          cardType: cardType,
          config: config,
        );

        // 触发高频访问
        for (int i = 0; i < 2; i++) {
          final simplifiedKey = _generateSimplifiedCacheKey(fund, cardType);
          if (_cardCache.containsKey(simplifiedKey)) {
            _updateAccessStatistics(simplifiedKey);
          }
        }
      }
    }
  }

  /// 优化缓存大小
  ///
  /// 当缓存过大时，清理最少使用的卡片 (真正的LRU实现)
  static void optimizeCache({int maxCacheSize = 100}) {
    if (_cardCache.length <= maxCacheSize) return;

    // 按最后访问时间排序，移除最久未使用的缓存
    final sortedEntries = _accessTimes.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final itemsToRemove = _cardCache.length - maxCacheSize;

    for (int i = 0; i < itemsToRemove; i++) {
      final keyToRemove = sortedEntries[i].key;
      _cardCache.remove(keyToRemove);
      _accessTimes.remove(keyToRemove);
    }
  }

  /// 智能缓存清理
  ///
  /// 基于多个策略的智能缓存清理
  static void smartCacheCleanup({
    int maxCacheSize = 100,
    Duration maxAge = const Duration(hours: 1),
    int maxAccessAgeMinutes = 30,
  }) {
    final keysToRemove = <String>[];
    final now = DateTime.now();

    for (final entry in _cardCache.entries) {
      final cacheEntry = entry.value;
      final key = entry.key;

      // 策略1: 超过最大缓存大小
      if (_cardCache.length > maxCacheSize) {
        // 策略2: 缓存过旧
        if (cacheEntry.ageInMs > maxAge.inMilliseconds) {
          keysToRemove.add(key);
          continue;
        }

        // 策略3: 长时间未访问
        if (cacheEntry.lastAccessAgeInMs > maxAccessAgeMinutes * 60 * 1000) {
          keysToRemove.add(key);
          continue;
        }

        // 策略4: 访问频率低的缓存
        if (cacheEntry.accessCount < 2 &&
            cacheEntry.ageInMs > Duration(minutes: 15).inMilliseconds) {
          keysToRemove.add(key);
        }
      }
    }

    // 如果缓存仍然太大，使用LRU策略
    if (_cardCache.length - keysToRemove.length > maxCacheSize) {
      optimizeCache(maxCacheSize: maxCacheSize);
    } else {
      // 清理标识的缓存
      for (final key in keysToRemove) {
        _cardCache.remove(key);
        _accessTimes.remove(key);
      }
    }
  }

  /// 验证卡片配置
  static bool validateCardConfig(FundCardConfig config) {
    return config.animationLevel >= 0 &&
        config.animationLevel <= 2 &&
        config.animationDuration.inMilliseconds > 0;
  }

  /// 获取默认配置
  static FundCardConfig getDefaultConfig() {
    return FundCardConfig.defaultConfig;
  }

  /// 获取性能优化配置
  static FundCardConfig getPerformanceConfig() {
    return FundCardConfig.highPerformance;
  }

  /// 获取增强体验配置
  static FundCardConfig getEnhancedConfig() {
    return FundCardConfig.enhanced;
  }

  /// 兼容性接口 - 简化的卡片创建方法
  ///
  /// 为向后兼容而提供的简化接口，映射到完整功能
  @Deprecated('使用 createFundCard 方法以获得完整功能')
  static Widget createCard({
    required Fund fund,
    required FundCardType type,
    VoidCallback? onTap,
    VoidCallback? onAddToWatchlist,
    VoidCallback? onCompare,
    FundCardConfig? config,
  }) {
    return createFundCard(
      fund: fund,
      cardType: type,
      onTap: onTap,
      onAddToWatchlist: onAddToWatchlist,
      onCompare: onCompare,
      config: config,
    );
  }
}

/// 基金卡片类型枚举
enum FundCardType {
  /// 自适应卡片：根据设备性能自动调整动画效果
  adaptive,

  /// 微交互卡片：提供丰富的手势操作和视觉反馈
  microinteractive,
}

/// 卡片创建结果
///
/// 封装卡片创建过程的详细信息，包括创建的组件、配置和性能数据
class CardCreationResult {
  /// 创建卡片创建结果实例
  const CardCreationResult({
    required this.card,
    required this.actualType,
    required this.config,
    required this.creationTime,
    required this.fromCache,
  });

  /// 创建的基金卡片组件
  final Widget card;

  /// 实际使用的卡片类型
  final FundCardType actualType;

  /// 使用的配置参数
  final FundCardConfig config;

  /// 创建耗时
  final Duration creationTime;

  /// 是否来自缓存
  final bool fromCache;

  @override
  String toString() {
    return 'CardCreationResult('
        'type: $actualType, '
        'config: $config, '
        'creationTime: ${creationTime.inMilliseconds}ms, '
        'fromCache: $fromCache'
        ')';
  }
}

/// 缓存条目
///
/// 用于跟踪缓存的详细信息和LRU策略
class _CacheEntry {
  final Widget widget;
  final DateTime createdAt;
  DateTime lastAccessedAt;
  int accessCount;

  _CacheEntry({
    required this.widget,
    required this.createdAt,
    required this.lastAccessedAt,
    required this.accessCount,
  });

  /// 更新访问信息
  void updateAccess() {
    lastAccessedAt = DateTime.now();
    accessCount++;
  }

  /// 获取缓存年龄（毫秒）
  int get ageInMs => DateTime.now().difference(createdAt).inMilliseconds;

  /// 获取最后访问间隔（毫秒）
  int get lastAccessAgeInMs =>
      DateTime.now().difference(lastAccessedAt).inMilliseconds;
}
