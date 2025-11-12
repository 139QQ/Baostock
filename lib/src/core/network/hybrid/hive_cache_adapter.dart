import 'dart:async';
import 'dart:convert';
import '../../cache/unified_hive_cache_manager.dart';
import '../utils/logger.dart';
import 'data_type.dart';
import 'hybrid_data_manager.dart';
import 'data_fetch_strategy.dart';

/// Hive缓存适配器
///
/// 在混合数据管理器和现有Hive缓存系统之间提供桥梁
/// 确保分层数据与缓存数据的一致性
class HiveCacheAdapter {
  /// 单例实例
  static final HiveCacheAdapter _instance = HiveCacheAdapter._internal();

  factory HiveCacheAdapter() => _instance;

  HiveCacheAdapter._internal() {
    _initialize();
  }

  /// 缓存管理器引用
  UnifiedHiveCacheManager? _cacheManager;

  /// 是否已初始化
  bool _isInitialized = false;

  /// 是否正在初始化
  bool _isInitializing = false;

  /// 数据类型缓存前缀映射
  static const Map<DataType, String> _cachePrefixMap = {
    DataType.fundRanking: 'hybrid_fund_ranking',
    DataType.etfSpotData: 'hybrid_etf_spot',
    DataType.lofSpotData: 'hybrid_lof_spot',
    DataType.fundProfile: 'hybrid_fund_profile',
    DataType.marketIndex: 'hybrid_market_index',
    DataType.connectionStatus: 'hybrid_connection_status',
    DataType.fundNetValue: 'hybrid_fund_net_value',
    DataType.portfolioData: 'hybrid_portfolio_data',
    DataType.userPreferences: 'hybrid_user_preferences',
    DataType.unknown: 'hybrid_unknown',
  };

  /// 缓存TTL配置（按数据类型）
  static const Map<DataType, Duration> _cacheTtlMap = {
    DataType.fundRanking: Duration(minutes: 2), // 基金排行榜：2分钟
    DataType.etfSpotData: Duration(seconds: 30), // ETF数据：30秒
    DataType.lofSpotData: Duration(seconds: 30), // LOF数据：30秒
    DataType.fundProfile: Duration(hours: 24), // 基金档案：24小时
    DataType.marketIndex: Duration(minutes: 1), // 市场指数：1分钟
    DataType.connectionStatus: Duration(minutes: 5), // 连接状态：5分钟
    DataType.fundNetValue: Duration(minutes: 5), // 基金净值：5分钟
    DataType.portfolioData: Duration(minutes: 10), // 投资组合：10分钟
    DataType.userPreferences: Duration(days: 30), // 用户偏好：30天
    DataType.unknown: Duration(minutes: 1), // 未知类型：1分钟
  };

  /// 缓存统计
  final Map<DataType, _CacheTypeStats> _typeStats = {};

  /// 初始化适配器
  Future<void> _initialize() async {
    if (_isInitialized) return;

    // 使用互斥锁防止并发初始化
    if (_isInitializing) {
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
      return;
    }

    _isInitializing = true;

    try {
      AppLogger.info('HiveCacheAdapter: 初始化Hive缓存适配器');

      // 确保缓存管理器实例已初始化
      _cacheManager = UnifiedHiveCacheManager.instance;
      if (!_cacheManager!.isInitialized) {
        await _cacheManager!.initialize();
      }

      // 初始化统计信息
      _typeStats.clear();
      for (final dataType in DataType.values) {
        _typeStats[dataType] = _CacheTypeStats(dataType);
      }

      _isInitialized = true;
      _isInitializing = false;
      AppLogger.info('HiveCacheAdapter: 初始化完成');
    } catch (e) {
      _isInitializing = false;
      AppLogger.error('HiveCacheAdapter: 初始化失败', e);
      rethrow;
    }
  }

  /// 存储混合数据到Hive缓存
  Future<bool> storeData(DataItem dataItem) async {
    if (!_isInitialized) {
      await _initialize();
    }

    try {
      // 避免重复生成缓存键前缀，直接使用dataItem.dataKey
      final cacheKey = dataItem.dataKey.startsWith('hybrid_')
          ? dataItem.dataKey
          : _generateCacheKey(dataItem.dataType, dataItem.dataKey);
      final ttl = _getCacheTtl(dataItem.dataType);

      // 序列化数据
      final serializedData = _serializeDataItem(dataItem);

      // 存储到Hive缓存
      if (_cacheManager == null) {
        throw StateError('HiveCacheAdapter: 缓存管理器未初始化');
      }
      await _cacheManager!.put(
        cacheKey,
        serializedData,
        expiration: ttl,
      );

      // 更新统计信息
      _updateTypeStats(dataItem.dataType, true);

      AppLogger.debug('HiveCacheAdapter: 数据存储成功',
          '${dataItem.dataType.name}:${dataItem.dataKey}');

      return true;
    } catch (e) {
      _updateTypeStats(dataItem.dataType, false);
      AppLogger.error('HiveCacheAdapter: 存储数据失败', e);
      return false;
    }
  }

  /// 从Hive缓存获取混合数据
  Future<DataItem?> getData(DataType dataType, String dataKey) async {
    if (!_isInitialized) {
      await _initialize();
    }

    try {
      // 避免重复生成缓存键前缀，直接使用传入的dataKey
      final cacheKey = dataKey.startsWith('hybrid_')
          ? dataKey
          : _generateCacheKey(dataType, dataKey);

      // 从Hive缓存获取数据
      if (_cacheManager == null) {
        throw StateError('HiveCacheAdapter: 缓存管理器未初始化');
      }
      final cachedData = await _cacheManager!.get(cacheKey);

      if (cachedData == null) {
        _updateTypeStats(dataType, false, isHit: false);
        AppLogger.debug('HiveCacheAdapter: 缓存未命中', cacheKey);
        return null;
      }

      // 反序列化数据
      final dataItem = _deserializeDataItem(cachedData as Map<String, dynamic>);

      if (dataItem != null) {
        _updateTypeStats(dataType, true, isHit: true);
        AppLogger.debug('HiveCacheAdapter: 缓存命中', cacheKey);
      } else {
        _updateTypeStats(dataType, false, isHit: false);
        AppLogger.warn('HiveCacheAdapter: 数据反序列化失败', cacheKey);
      }

      return dataItem;
    } catch (e) {
      _updateTypeStats(dataType, false, isHit: false);
      AppLogger.error('HiveCacheAdapter: 获取数据失败', e);
      return null;
    }
  }

  /// 批量存储数据
  Future<Map<String, bool>> batchStoreData(List<DataItem> dataItems) async {
    final results = <String, bool>{};

    // 并行存储以提高性能
    final futures = dataItems.map((item) async {
      final success = await storeData(item);
      results[item.dataKey] = success;
    });

    await Future.wait(futures);

    AppLogger.info('HiveCacheAdapter: 批量存储完成',
        '${results.values.where((v) => v).length}/${dataItems.length} 成功');

    return results;
  }

  /// 批量获取数据
  Future<Map<String, DataItem?>> batchGetData(
      Map<DataType, List<String>> requests) async {
    final results = <String, DataItem?>{};

    // 并行获取以提高性能
    final futures = <Future<void>>[];

    for (final entry in requests.entries) {
      final dataType = entry.key;
      final dataKeys = entry.value;

      for (final dataKey in dataKeys) {
        futures.add((dataKey, dataType) async {
          final dataItem = await getData(dataType, dataKey);
          results[dataKey] = dataItem;
        }(dataKey, dataType));
      }
    }

    await Future.wait(futures);

    AppLogger.info('HiveCacheAdapter: 批量获取完成',
        '${results.values.where((v) => v != null).length}/${results.length} 成功');

    return results;
  }

  /// 删除特定数据
  Future<bool> removeData(DataType dataType, String dataKey) async {
    if (!_isInitialized) {
      await _initialize();
    }

    try {
      // 避免重复生成缓存键前缀，直接使用传入的dataKey
      final cacheKey = dataKey.startsWith('hybrid_')
          ? dataKey
          : _generateCacheKey(dataType, dataKey);
      if (_cacheManager == null) {
        throw StateError('HiveCacheAdapter: 缓存管理器未初始化');
      }
      await _cacheManager!.remove(cacheKey);

      AppLogger.debug('HiveCacheAdapter: 数据删除成功', cacheKey);
      return true;
    } catch (e) {
      AppLogger.error('HiveCacheAdapter: 删除数据失败', e);
      return false;
    }
  }

  /// 清空指定数据类型的缓存
  Future<bool> clearDataTypeCache(DataType dataType) async {
    try {
      // 获取该数据类型的所有缓存键
      final cacheKeys = await _getDataTypeCacheKeys(dataType);

      if (cacheKeys.isEmpty) {
        AppLogger.debug('HiveCacheAdapter: 无需清空缓存', '数据类型: ${dataType.name}');
        return true;
      }

      // 批量删除
      if (_cacheManager == null) {
        throw StateError('HiveCacheAdapter: 缓存管理器未初始化');
      }
      for (final key in cacheKeys) {
        await _cacheManager!.remove(key);
      }

      AppLogger.info('HiveCacheAdapter: 缓存清空完成',
          '${dataType.name}: ${cacheKeys.length} 项');

      return true;
    } catch (e) {
      AppLogger.error('HiveCacheAdapter: 清空缓存失败', e);
      return false;
    }
  }

  /// 检查数据是否存在
  Future<bool> hasData(DataType dataType, String dataKey) async {
    if (!_isInitialized) {
      await _initialize();
    }

    try {
      // 避免重复生成缓存键前缀，直接使用传入的dataKey
      final cacheKey = dataKey.startsWith('hybrid_')
          ? dataKey
          : _generateCacheKey(dataType, dataKey);
      if (_cacheManager == null) {
        throw StateError('HiveCacheAdapter: 缓存管理器未初始化');
      }
      return await _cacheManager!.containsKey(cacheKey);
    } catch (e) {
      AppLogger.error('HiveCacheAdapter: 检查数据存在性失败', e);
      return false;
    }
  }

  /// 获取缓存统计信息
  Map<DataType, _CacheTypeStats> getTypeStats() {
    return Map.unmodifiable(_typeStats);
  }

  /// 获取适配器健康状态
  Future<Map<String, dynamic>> getHealthStatus() async {
    return {
      'initialized': _isInitialized,
      'totalDataTypeCount': DataType.values.length,
      'activeDataTypeCount':
          _typeStats.values.where((stats) => stats.totalRequests > 0).length,
      'overallHitRate': _calculateOverallHitRate(),
      'totalRequests':
          _typeStats.values.fold(0, (sum, stats) => sum + stats.totalRequests),
      'totalHits': _typeStats.values.fold(0, (sum, stats) => sum + stats.hits),
      'cacheManagerStatus': await _getCacheManagerStatus(),
    };
  }

  /// 生成缓存键
  String _generateCacheKey(DataType dataType, String dataKey) {
    final prefix =
        _cachePrefixMap[dataType] ?? _cachePrefixMap[DataType.unknown]!;
    return '${prefix}_$dataKey';
  }

  /// 获取缓存TTL
  Duration _getCacheTtl(DataType dataType) {
    return _cacheTtlMap[dataType] ?? _cacheTtlMap[DataType.unknown]!;
  }

  /// 序列化数据项
  Map<String, dynamic> _serializeDataItem(DataItem dataItem) {
    return {
      'dataType': dataItem.dataType.name,
      'dataKey': dataItem.dataKey,
      'data': dataItem.data,
      'timestamp': dataItem.timestamp.toIso8601String(),
      'source': dataItem.source.name,
      'quality': dataItem.quality.name,
      'metadata': dataItem.metadata,
    };
  }

  /// 反序列化数据项
  DataItem? _deserializeDataItem(Map<String, dynamic> serializedData) {
    try {
      return DataItem(
        id: serializedData['id'] as String? ??
            '${serializedData['dataType']}_${DateTime.now().millisecondsSinceEpoch}',
        dataType: DataType.values.firstWhere(
          (type) => type.name == serializedData['dataType'],
          orElse: () => DataType.unknown,
        ),
        dataKey: serializedData['dataKey'] as String,
        data: serializedData['data'] as Map<String, dynamic>,
        timestamp: DateTime.parse(serializedData['timestamp'] as String),
        source: DataSource.values.firstWhere(
          (source) => source.name == serializedData['source'],
          orElse: () => DataSource.unknown,
        ),
        quality: DataQualityLevel.values.firstWhere(
          (quality) => quality.name == serializedData['quality'],
          orElse: () => DataQualityLevel.unknown,
        ),
        metadata: serializedData['metadata'] as Map<String, dynamic>?,
      );
    } catch (e) {
      AppLogger.error('HiveCacheAdapter: 反序列化失败', e);
      return null;
    }
  }

  /// 生成元数据
  Map<String, dynamic> _generateMetadata(DataItem dataItem) {
    return {
      'dataType': dataItem.dataType.name,
      'source': dataItem.source.name,
      'quality': dataItem.quality.name,
      'version': '1.0',
      'adapter': 'HiveCacheAdapter',
    };
  }

  /// 更新类型统计
  void _updateTypeStats(DataType dataType, bool success, {bool isHit = false}) {
    final stats = _typeStats[dataType];
    if (stats != null) {
      stats.recordRequest(success: success, hit: isHit);
    }
  }

  /// 计算整体命中率
  double _calculateOverallHitRate() {
    int totalRequests = 0;
    int totalHits = 0;

    for (final stats in _typeStats.values) {
      totalRequests += stats.totalRequests;
      totalHits += stats.hits;
    }

    return totalRequests > 0 ? totalHits / totalRequests : 0.0;
  }

  /// 获取缓存管理器状态
  Future<Map<String, dynamic>> _getCacheManagerStatus() async {
    try {
      if (_cacheManager == null) {
        return {'error': '缓存管理器未初始化'};
      }
      final stats = await _cacheManager!.getStats();
      return {
        'size': _cacheManager!.size,
        'stats': stats,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// 获取数据类型的所有缓存键
  Future<List<String>> _getDataTypeCacheKeys(DataType dataType) async {
    try {
      final prefix =
          _cachePrefixMap[dataType] ?? _cachePrefixMap[DataType.unknown]!;

      // 这里需要根据实际的缓存管理器实现来获取键列表
      // 暂时返回空列表，需要在实际使用时实现
      AppLogger.warn('HiveCacheAdapter: _getDataTypeCacheKeys 需要实现');
      return [];
    } catch (e) {
      AppLogger.error('HiveCacheAdapter: 获取缓存键失败', e);
      return [];
    }
  }

  /// 清理过期数据
  Future<void> cleanupExpiredData() async {
    try {
      AppLogger.info('HiveCacheAdapter: 开始清理过期数据');

      // 遍历所有数据类型，检查和清理过期数据
      for (final dataType in DataType.values) {
        final cacheKeys = await _getDataTypeCacheKeys(dataType);

        for (final cacheKey in cacheKeys) {
          try {
            // 获取缓存项并检查是否过期
            if (_cacheManager == null) {
              throw StateError('HiveCacheAdapter: 缓存管理器未初始化');
            }
            final cacheItem = await _cacheManager!.get(cacheKey);
            if (cacheItem != null) {
              // 简单的过期检查逻辑
              // 这里可以根据实际需求实现更复杂的检查
            }
          } catch (e) {
            AppLogger.warn('HiveCacheAdapter: 清理缓存项失败', '$cacheKey: $e');
          }
        }
      }

      AppLogger.info('HiveCacheAdapter: 过期数据清理完成');
    } catch (e) {
      AppLogger.error('HiveCacheAdapter: 清理过期数据失败', e);
    }
  }

  /// 释放资源
  Future<void> dispose() async {
    _typeStats.clear();
    _cacheManager = null;
    _isInitialized = false;
    AppLogger.info('HiveCacheAdapter: 资源已释放');
  }
}

/// 缓存类型统计
class _CacheTypeStats {
  final DataType dataType;
  int totalRequests = 0;
  int successes = 0;
  int failures = 0;
  int hits = 0;
  int misses = 0;

  _CacheTypeStats(this.dataType);

  void recordRequest({required bool success, required bool hit}) {
    totalRequests++;
    if (success) {
      successes++;
    } else {
      failures++;
    }
    if (hit) {
      hits++;
    } else {
      misses++;
    }
  }

  double get successRate => totalRequests > 0 ? successes / totalRequests : 0.0;
  double get hitRate => totalRequests > 0 ? hits / totalRequests : 0.0;

  Map<String, dynamic> toJson() {
    return {
      'dataType': dataType.name,
      'totalRequests': totalRequests,
      'successes': successes,
      'failures': failures,
      'hits': hits,
      'misses': misses,
      'successRate': successRate,
      'hitRate': hitRate,
    };
  }
}
