import '../interfaces/i_unified_cache_service.dart';
import '../unified_hive_cache_manager.dart';
import 'unified_cache_adapter.dart';
import '../../../core/utils/logger.dart';

/// 缓存适配器工厂
///
/// 负责创建和管理各种缓存适配器，提供统一的适配器创建接口
class CacheAdapterFactory {
  static const String _tag = 'CacheAdapterFactory';
  static final Map<String, IUnifiedCacheService> _adapterCache = {};

  /// 创建统一缓存适配器
  ///
  /// 将 UnifiedHiveCacheManager 适配为 IUnifiedCacheService
  static IUnifiedCacheService createUnifiedCacheAdapter(
    UnifiedHiveCacheManager manager,
  ) {
    final key = 'unified_${manager.hashCode}';

    if (_adapterCache.containsKey(key)) {
      return _adapterCache[key]!;
    }

    final adapter = UnifiedCacheAdapter(manager);
    _adapterCache[key] = adapter;

    AppLogger.info(
        'Created UnifiedCacheAdapter for manager: ${manager.runtimeType} - $_tag');
    return adapter;
  }

  /// 根据类型创建适配器
  ///
  /// [service] 缓存服务实例
  /// [adapterType] 适配器类型，如果不指定则自动推断
  static IUnifiedCacheService createAdapter(
    dynamic service, {
    CacheAdapterType? adapterType,
  }) {
    // 自动推断适配器类型
    adapterType ??= _inferAdapterType(service);

    switch (adapterType) {
      case CacheAdapterType.unifiedHive:
        return createUnifiedCacheAdapter(service as UnifiedHiveCacheManager);
      default:
        throw ArgumentError('Unsupported adapter type: $adapterType');
    }
  }

  /// 创建适配器链
  ///
  /// 创建多层缓存适配器链，提供缓存分层功能
  static IUnifiedCacheService createAdapterChain(
    List<CacheLayerConfig> layerConfigs,
  ) {
    if (layerConfigs.isEmpty) {
      throw ArgumentError('Layer configs cannot be empty');
    }

    // 创建第一层适配器
    IUnifiedCacheService currentAdapter = createAdapter(
      layerConfigs.first.service,
      adapterType: layerConfigs.first.type,
    );

    // 创建后续层适配器
    for (int i = 1; i < layerConfigs.length; i++) {
      final config = layerConfigs[i];
      final nextAdapter = createAdapter(
        config.service,
        adapterType: config.type,
      );

      // 创建分层适配器
      currentAdapter = LayeredCacheAdapter(
        primary: currentAdapter,
        secondary: nextAdapter,
        strategy: config.strategy,
      );
    }

    AppLogger.info(
        'Created adapter chain with ${layerConfigs.length} layers - $_tag');
    return currentAdapter;
  }

  /// 获取所有已创建的适配器
  static Map<String, IUnifiedCacheService> getAllAdapters() {
    return Map.unmodifiable(_adapterCache);
  }

  /// 清理适配器缓存
  static void clearAdapterCache() {
    _adapterCache.clear();
    AppLogger.info('Cleared adapter cache - $_tag');
  }

  /// 移除特定适配器
  static bool removeAdapter(String key) {
    final removed = _adapterCache.remove(key);
    if (removed != null) {
      AppLogger.info('Removed adapter: $key - $_tag');
      return true;
    }
    return false;
  }

  /// 获取适配器统计信息
  static Map<String, dynamic> getAdapterStatistics() {
    final stats = <String, dynamic>{
      'totalAdapters': _adapterCache.length,
      'adapterTypes': <String, int>{},
      'memoryUsage': 0,
    };

    for (final entry in _adapterCache.entries) {
      final adapter = entry.value;
      final type = adapter.runtimeType.toString();
      stats['adapterTypes'][type] = (stats['adapterTypes'][type] ?? 0) + 1;
    }

    return stats;
  }

  // ============================================================================
  // 私有方法
  // ============================================================================

  /// 推断适配器类型
  static CacheAdapterType _inferAdapterType(dynamic service) {
    if (service is UnifiedHiveCacheManager) {
      return CacheAdapterType.unifiedHive;
    } else {
      throw ArgumentError(
          'Cannot infer adapter type for service: ${service.runtimeType}');
    }
  }
}

/// 缓存适配器类型
enum CacheAdapterType {
  unifiedHive,
}

/// 缓存层配置
class CacheLayerConfig {
  final dynamic service;
  final CacheAdapterType type;
  final CacheLayerStrategy strategy;

  const CacheLayerConfig({
    required this.service,
    required this.type,
    this.strategy = CacheLayerStrategy.writeThrough,
  });
}

/// 缓存层策略
enum CacheLayerStrategy {
  writeThrough, // 写透：同时写入所有层
  writeBack, // 写回：先写入上层，异步写入下层
  writeAround, // 写绕：直接写入下层
  cacheAside, // 旁路缓存：应用程序管理缓存
}

/// 分层缓存适配器
///
/// 提供多层缓存功能
class LayeredCacheAdapter implements IUnifiedCacheService {
  final IUnifiedCacheService primary;
  final IUnifiedCacheService secondary;
  final CacheLayerStrategy strategy;

  LayeredCacheAdapter({
    required this.primary,
    required this.secondary,
    this.strategy = CacheLayerStrategy.writeThrough,
  });

  @override
  Future<T?> get<T>(String key, {Type? type}) async {
    // 先从主缓存获取
    final value = await primary.get<T>(key);

    if (value != null) {
      return value;
    }

    // 主缓存未命中，从次缓存获取
    final secondaryValue = await secondary.get<T>(key);

    if (secondaryValue != null) {
      // 将值写入主缓存（如果策略支持）
      if (strategy == CacheLayerStrategy.cacheAside) {
        await primary.put(key, secondaryValue);
      }
    }

    return secondaryValue;
  }

  @override
  Future<void> put<T>(
    String key,
    T value, {
    CacheConfig? config,
    CacheMetadata? metadata,
  }) async {
    switch (strategy) {
      case CacheLayerStrategy.writeThrough:
        // 同时写入所有层
        await Future.wait([
          primary.put(key, value, config: config),
          secondary.put(key, value, config: config),
        ]);
        break;
      case CacheLayerStrategy.writeBack:
        // 先写入主缓存，异步写入次缓存
        await primary.put(key, value, config: config);
        Future.delayed(const Duration(milliseconds: 100), () {
          secondary.put(key, value, config: config);
        });
        break;
      case CacheLayerStrategy.writeAround:
        // 直接写入次缓存
        await secondary.put(key, value, config: config);
        break;
      case CacheLayerStrategy.cacheAside:
        // 只写入主缓存
        await primary.put(key, value, config: config);
        break;
    }
  }

  @override
  Future<bool> exists(String key) async {
    final primaryExists = await primary.exists(key);
    if (primaryExists) return true;

    return await secondary.exists(key);
  }

  @override
  Future<bool> remove(String key) async {
    // 从所有层删除
    await Future.wait([
      primary.remove(key),
      secondary.remove(key),
    ]);
    return true;
  }

  @override
  Future<void> clear() async {
    // 清空所有层
    await Future.wait([
      primary.clear(),
      secondary.clear(),
    ]);
  }

  @override
  Future<Map<String, T?>> getAll<T>(List<String> keys, {Type? type}) async {
    final result = <String, T?>{};

    // 先从主缓存获取
    final primaryResults = await primary.getAll<T>(keys);
    result.addAll(primaryResults);

    // 获取未命中的键
    final missingKeys = keys.where((key) => !result.containsKey(key)).toList();

    if (missingKeys.isNotEmpty) {
      // 从次缓存获取缺失的数据
      final secondaryResults = await secondary.getAll<T>(missingKeys);
      result.addAll(secondaryResults);

      // 将缺失的数据写入主缓存（如果策略支持）
      if (strategy == CacheLayerStrategy.cacheAside) {
        for (final entry in secondaryResults.entries) {
          if (entry.value != null) {
            primary.put(entry.key, entry.value);
          }
        }
      }
    }

    return result;
  }

  @override
  Future<void> putAll<T>(Map<String, T> entries, {CacheConfig? config}) async {
    switch (strategy) {
      case CacheLayerStrategy.writeThrough:
        await Future.wait([
          primary.putAll(entries, config: config),
          secondary.putAll(entries, config: config),
        ]);
        break;
      case CacheLayerStrategy.writeBack:
        await primary.putAll(entries, config: config);
        Future.delayed(const Duration(milliseconds: 100), () {
          secondary.putAll(entries, config: config);
        });
        break;
      case CacheLayerStrategy.writeAround:
        await secondary.putAll(entries, config: config);
        break;
      case CacheLayerStrategy.cacheAside:
        await primary.putAll(entries, config: config);
        break;
    }
  }

  @override
  Future<int> removeAll(Iterable<String> keys) async {
    await Future.wait([
      primary.removeAll(keys),
      secondary.removeAll(keys),
    ]);
    return keys.length;
  }

  @override
  Future<int> removeByPattern(String pattern) async {
    final primaryResult = await primary.removeByPattern(pattern);
    final secondaryResult = await secondary.removeByPattern(pattern);
    return primaryResult + secondaryResult;
  }

  @override
  Future<void> preload<T>(
    List<String> keys,
    Future<T> Function(String key) loader,
  ) async {
    // 只在主缓存中预加载
    await primary.preload<T>(keys, loader);
  }

  @override
  Future<void> optimize() async {
    // 优化所有层
    await Future.wait([
      primary.optimize(),
      secondary.optimize(),
    ]);
  }

  @override
  Future<CacheStatistics> getStatistics() async {
    final primaryStats = await primary.getStatistics();
    final secondaryStats = await secondary.getStatistics();

    return CacheStatistics(
      totalCount: primaryStats.totalCount + secondaryStats.totalCount,
      validCount: primaryStats.validCount + secondaryStats.validCount,
      expiredCount: primaryStats.expiredCount + secondaryStats.expiredCount,
      totalSize: primaryStats.totalSize + secondaryStats.totalSize,
      compressedSavings:
          primaryStats.compressedSavings + secondaryStats.compressedSavings,
      tagCounts: _mergeMaps(primaryStats.tagCounts, secondaryStats.tagCounts),
      priorityCounts: _mergeIntMaps(
          primaryStats.priorityCounts, secondaryStats.priorityCounts),
      hitRate: (primaryStats.hitRate + secondaryStats.hitRate) / 2,
      missRate: (primaryStats.missRate + secondaryStats.missRate) / 2,
      averageResponseTime: (primaryStats.averageResponseTime +
              secondaryStats.averageResponseTime) /
          2,
    );
  }

  /// 合并两个Map
  Map<String, int> _mergeMaps(Map<String, int> map1, Map<String, int> map2) {
    final result = <String, int>{};
    result.addAll(map1);
    map2.forEach((key, value) {
      result[key] = (result[key] ?? 0) + value;
    });
    return result;
  }

  /// 合并两个int类型的Map
  Map<int, int> _mergeIntMaps(Map<int, int> map1, Map<int, int> map2) {
    final result = <int, int>{};
    result.addAll(map1);
    map2.forEach((key, value) {
      result[key] = (result[key] ?? 0) + value;
    });
    return result;
  }

  @override
  Future<CacheConfig?> getConfig(String key) async {
    final primaryConfig = await primary.getConfig(key);
    final secondaryConfig = await secondary.getConfig(key);
    return primaryConfig ?? secondaryConfig;
  }

  @override
  Future<bool> updateConfig(String key, CacheConfig config) async {
    final results = await Future.wait([
      primary.updateConfig(key, config),
      secondary.updateConfig(key, config),
    ]);
    return results.any((result) => result);
  }

  @override
  CacheAccessStats getAccessStats() {
    final primaryStats = primary.getAccessStats();
    final secondaryStats = secondary.getAccessStats();

    final stats = CacheAccessStats();
    stats.totalAccesses =
        primaryStats.totalAccesses + secondaryStats.totalAccesses;
    stats.hits = primaryStats.hits + secondaryStats.hits;
    stats.misses = primaryStats.misses + secondaryStats.misses;
    stats.totalResponseTime =
        primaryStats.totalResponseTime + secondaryStats.totalResponseTime;

    return stats;
  }

  @override
  void resetAccessStats() {
    primary.resetAccessStats();
    secondary.resetAccessStats();
  }

  @override
  Future<int> clearExpired() async {
    // 清空所有层的过期缓存
    final results = await Future.wait([
      primary.clearExpired(),
      secondary.clearExpired(),
    ]);
    int totalCount = 0;
    for (final count in results) {
      totalCount += count;
    }
    return totalCount;
  }

  @override
  Future<bool> isExpired(String key) async {
    // 检查任一层是否过期
    final primaryExpired = await primary.isExpired(key);
    if (primaryExpired) return true;

    return await secondary.isExpired(key);
  }

  @override
  void setMonitoringEnabled(bool enabled) {
    // 同时启用/禁用所有层的监控
    primary.setMonitoringEnabled(enabled);
    secondary.setMonitoringEnabled(enabled);
  }
}
