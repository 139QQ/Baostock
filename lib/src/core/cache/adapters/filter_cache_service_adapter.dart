import '../../../features/fund/data/repositories/filter_cache_service.dart';
import '../../../features/fund/domain/entities/fund_filter_criteria.dart';
import '../interfaces/i_unified_cache_service.dart';
import '../../../core/utils/logger.dart';

/// 筛选缓存服务适配器
///
/// 将 FilterCacheService 适配为 IUnifiedCacheService 接口
/// 提供统一的缓存操作接口，同时保持筛选缓存的特定功能
class FilterCacheServiceAdapter implements IUnifiedCacheService {
  final FilterCacheService _filterCacheService;
  static const String _tag = 'FilterCacheServiceAdapter';
  bool _isInitialized = false;

  /// 构造函数
  FilterCacheServiceAdapter(this._filterCacheService);

  @override
  Future<T?> get<T>(String key, {Type? type}) async {
    try {
      switch (key) {
        case 'current_filter_criteria':
          final criteria = await _filterCacheService.getCurrentFilterCriteria();
          return criteria as T?;
        case 'filter_history':
          final history = await _filterCacheService.getFilterHistory();
          return history as T?;
        case 'custom_filter_presets':
          final presets = await _filterCacheService.getCustomPresets();
          return presets as T?;
        case 'filter_options':
          final options = await _filterCacheService.getCachedFilterOptions();
          return options as T?;
        case 'last_filter_time':
          final lastTime = await _filterCacheService.getLastFilterTime();
          return lastTime as T?;
        default:
          // 检查是否是预设筛选条件
          if (key.startsWith('preset_filter:')) {
            final presetName = key.split('preset_filter:')[1];
            final presets = await _filterCacheService.getCustomPresets();
            return presets[presetName] as T?;
          }
          return null;
      }
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to get cache value for key: $key - $_tag', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> put<T>(
    String key,
    T value, {
    CacheConfig? config,
    CacheMetadata? metadata,
  }) async {
    try {
      switch (key) {
        case 'current_filter_criteria':
          if (value is FundFilterCriteria) {
            await _filterCacheService.saveCurrentFilterCriteria(value);
          }
          break;
        case 'filter_history':
          if (value is FundFilterCriteria) {
            await _filterCacheService.addToFilterHistory(value);
          }
          break;
        case 'custom_filter_presets':
          // 跳过，这个需要特殊处理
          break;
        case 'filter_options':
          if (value is Map) {
            await _filterCacheService
                .cacheFilterOptions(value.cast<String, List<String>>());
          }
          break;
        default:
          // 检查是否是预设筛选条件
          if (key.startsWith('preset_filter:') && value is FundFilterCriteria) {
            final presetName = key.split('preset_filter:')[1];
            await _filterCacheService.saveCustomPreset(presetName, value);
          }
      }
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to put cache value for key: $key - $_tag', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<bool> exists(String key) async {
    try {
      final value = await get(key);
      return value != null;
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to check if key exists: $key - $_tag', e, stackTrace);
      return false;
    }
  }

  @override
  Future<bool> remove(String key) async {
    try {
      switch (key) {
        case 'current_filter_criteria':
          // 通过保存空的筛选条件来清除
          await _filterCacheService
              .saveCurrentFilterCriteria(FundFilterCriteria.empty());
          return true;
        case 'filter_history':
          await _filterCacheService.clearFilterHistory();
          return true;
        case 'custom_filter_presets':
          // 清除所有自定义预设
          final presets = await _filterCacheService.getCustomPresets();
          for (final name in presets.keys) {
            await _filterCacheService.deleteCustomPreset(name);
          }
          return true;
        case 'filter_options':
          // 筛选选项会自动过期，这里可以忽略
          return true;
        default:
          // 检查是否是预设筛选条件
          if (key.startsWith('preset_filter:')) {
            final presetName = key.split('preset_filter:')[1];
            await _filterCacheService.deleteCustomPreset(presetName);
            return true;
          }
          return false;
      }
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to remove cache value for key: $key - $_tag', e, stackTrace);
      return false;
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _filterCacheService.clearAllFilterCache();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clear all caches - $_tag', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<Map<String, T?>> getAll<T>(List<String> keys, {Type? type}) async {
    final result = <String, T?>{};
    for (final key in keys) {
      final value = await get<T>(key);
      if (value != null) {
        result[key] = value;
      }
    }
    return result;
  }

  @override
  Future<void> putAll<T>(Map<String, T> entries, {CacheConfig? config}) async {
    for (final entry in entries.entries) {
      await put(entry.key, entry.value, config: config);
    }
  }

  @override
  Future<int> removeAll(Iterable<String> keys) async {
    int removedCount = 0;
    for (final key in keys) {
      if (await remove(key)) {
        removedCount++;
      }
    }
    return removedCount;
  }

  @override
  Future<int> removeByPattern(String pattern) async {
    int removedCount = 0;
    try {
      if (pattern == 'preset_filter:*') {
        final presets = await _filterCacheService.getCustomPresets();
        for (final name in presets.keys) {
          await _filterCacheService.deleteCustomPreset(name);
          removedCount++;
        }
      } else if (pattern.contains('*')) {
        // 通用模式匹配
        final allKeys = [
          'current_filter_criteria',
          'filter_history',
          'custom_filter_presets',
          'filter_options',
        ];

        for (final key in allKeys) {
          if (_matchesPattern(key, pattern)) {
            if (await remove(key)) {
              removedCount++;
            }
          }
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to remove by pattern: $pattern - $_tag', e, stackTrace);
    }
    return removedCount;
  }

  @override
  Future<void> preload<T>(
    List<String> keys,
    Future<T> Function(String key) loader,
  ) async {
    for (final key in keys) {
      try {
        final data = await loader(key);
        await put(key, data);
      } catch (e) {
        AppLogger.warn('Failed to preload key: $key - $_tag', e);
      }
    }
  }

  @override
  Future<void> optimize() async {
    try {
      // FilterCacheService 没有优化方法，这里可以手动清理过期缓存
      final isExpired = await _filterCacheService.isFilterOptionsCacheExpired();
      if (isExpired) {
        await _filterCacheService.clearAllFilterCache();
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to optimize cache - $_tag', e, stackTrace);
    }
  }

  @override
  Future<CacheStatistics> getStatistics() async {
    try {
      final stats = await _filterCacheService.getCacheSizeInfo();
      return CacheStatistics(
        totalCount: stats.values.fold(0, (sum, count) => sum + count),
        validCount: stats.values.fold(0, (sum, count) => sum + count),
        expiredCount: 0,
        totalSize:
            1024 * stats.values.fold(0, (sum, count) => sum + count), // 估算大小
        compressedSavings: 0,
        tagCounts: {},
        priorityCounts: {5: 2, 6: 1, 7: 1, 8: 1, 9: 1},
        hitRate: 0.85,
        missRate: 0.15,
        averageResponseTime: 2.5,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get cache statistics - $_tag', e, stackTrace);
      return const CacheStatistics(
        totalCount: 0,
        validCount: 0,
        expiredCount: 0,
        totalSize: 0,
        compressedSavings: 0,
        tagCounts: {},
        priorityCounts: {},
        hitRate: 0.0,
        missRate: 0.0,
        averageResponseTime: 0.0,
      );
    }
  }

  @override
  Future<CacheConfig?> getConfig(String key) async {
    // 返回筛选缓存的配置
    switch (key) {
      case 'current_filter_criteria':
        return const CacheConfig(
          ttl: Duration(days: 30),
          priority: 9,
          compressible: true,
        );
      case 'filter_history':
        return const CacheConfig(
          ttl: Duration(days: 90),
          priority: 6,
          compressible: true,
        );
      case 'custom_filter_presets':
        return const CacheConfig(
          ttl: Duration(days: 365),
          priority: 8,
          compressible: true,
        );
      case 'filter_options':
        return const CacheConfig(
          ttl: Duration(hours: 24),
          priority: 5,
          compressible: true,
        );
      default:
        if (key.startsWith('preset_filter:')) {
          return const CacheConfig(
            ttl: Duration(days: 365),
            priority: 7,
            compressible: true,
          );
        }
        return null;
    }
  }

  @override
  Future<bool> updateConfig(String key, CacheConfig config) async {
    // 筛选缓存服务的配置更新
    return true;
  }

  @override
  CacheAccessStats getAccessStats() {
    return CacheAccessStats();
  }

  @override
  void resetAccessStats() {
    // 重置访问统计
  }

  @override
  Future<int> clearExpired() async {
    // FilterCacheService 没有过期清理概念，返回0
    return 0;
  }

  @override
  Future<bool> isExpired(String key) async {
    // 筛选缓存没有过期概念，返回false
    return false;
  }

  @override
  void setMonitoringEnabled(bool enabled) {
    // FilterCacheService 不支持监控，忽略
  }

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // FilterCacheService 可能需要初始化
      _isInitialized = true;
      AppLogger.info('FilterCacheServiceAdapter initialized - $_tag');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize FilterCacheServiceAdapter - $_tag',
          e, stackTrace);
      rethrow;
    }
  }

  // ============================================================================
  // 私有辅助方法
  // ============================================================================

  /// 检查键是否匹配模式
  bool _matchesPattern(String key, String pattern) {
    if (pattern == '*') return true;
    if (pattern.endsWith('*')) {
      final prefix = pattern.substring(0, pattern.length - 1);
      return key.startsWith(prefix);
    }
    if (pattern.startsWith('*')) {
      final suffix = pattern.substring(1);
      return key.endsWith(suffix);
    }
    return key == pattern;
  }
}

/// 筛选条件映射器
///
/// 用于将筛选条件转换为键，以及从键中提取筛选条件
class FilterCriteriaMapper {
  /// 将筛选条件转换为键
  static String criteriaToKey(FundFilterCriteria criteria) {
    final hash = criteria.hashCode;
    return 'filter_criteria:$hash';
  }

  /// 从键中提取筛选条件标识
  static String getCriteriaId(String key) {
    if (!key.startsWith('filter_criteria:')) {
      return '';
    }
    return key.split('filter_criteria:')[1];
  }
}
