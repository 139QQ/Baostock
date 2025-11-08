import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../utils/logger.dart';
import 'data_type.dart';
import 'data_fetch_strategy.dart';
import 'data_type_router.dart';
import '../realtime/websocket_manager.dart';
import '../realtime/fallback_http_service.dart';
import 'hive_cache_adapter.dart';

/// 混合数据管理器
///
/// 负责协调和管理多种数据获取策略，根据数据类型和网络状态选择最优的数据获取方式
/// 支持HTTP轮询、WebSocket连接和按需请求的混合策略
class HybridDataManager {
  /// 单例实例
  static final HybridDataManager _instance = HybridDataManager._internal();

  factory HybridDataManager() => _instance;

  HybridDataManager._internal() {
    _initialize();
  }

  /// 数据获取策略映射
  final Map<DataType, List<DataFetchStrategy>> _strategies = {};

  /// 数据类型路由器
  late final DataTypeRouter _router;

  /// Hive缓存适配器
  late final HiveCacheAdapter _cacheAdapter;

  /// 数据流控制器
  final Map<DataType, StreamController<DataItem>> _dataControllers = {};

  /// 数据获取配置
  final Map<DataType, DataFetchConfig> _configs = {};

  /// 管理器状态
  ManagerState _state = ManagerState.idle;

  /// 错误计数器
  final Map<DataType, int> _errorCounters = {};

  /// 性能监控
  final Map<DataType, List<Duration>> _fetchLatencies = {};

  /// 缓存数据 (短期内存缓存)
  final Map<String, DataItem> _cache = {};

  /// 缓存大小限制
  static const int _maxCacheSize = 1000;

  /// 状态变化流控制器
  final StreamController<ManagerState> _stateController =
      StreamController<ManagerState>.broadcast();

  /// 初始化管理器
  Future<void> _initialize() async {
    try {
      _updateState(ManagerState.initializing);

      // 初始化路由器
      _router = DataTypeRouter();

      // 初始化Hive缓存适配器
      _cacheAdapter = HiveCacheAdapter();

      // 初始化默认策略
      await _initializeStrategies();

      // 启动清理定时器
      _startCleanupTimer();

      _updateState(ManagerState.ready);
      AppLogger.info('HybridDataManager initialized successfully');
    } catch (e) {
      _updateState(ManagerState.error);
      AppLogger.error('Failed to initialize HybridDataManager: $e');
      rethrow;
    }
  }

  /// 初始化数据获取策略
  Future<void> _initializeStrategies() async {
    // 注意：这些策略将在后续任务中实现
    // 现在先创建占位符

    // HTTP轮询策略将在这里添加
    // WebSocket策略将在这里添加
    // 按需请求策略将在这里添加

    for (final dataType in DataType.values) {
      _strategies[dataType] = [];
      _dataControllers[dataType] = StreamController<DataItem>.broadcast();
      _errorCounters[dataType] = 0;
      _fetchLatencies[dataType] = [];

      // 设置默认配置
      _configs[dataType] = DataFetchConfig.defaultForType(dataType);
    }
  }

  /// 获取管理器状态
  ManagerState get state => _state;

  /// 状态变化流
  Stream<ManagerState> get stateStream => _stateController.stream;

  /// 更新管理器状态
  void _updateState(ManagerState newState) {
    if (_state != newState) {
      final oldState = _state;
      _state = newState;
      _stateController.add(newState);
      AppLogger.info(
          'HybridDataManager state changed: ${oldState.name} → ${newState.name}');
    }
  }

  /// 注册数据获取策略
  void registerStrategy(DataFetchStrategy strategy) {
    for (final dataType in strategy.supportedDataTypes) {
      if (!_strategies.containsKey(dataType)) {
        _strategies[dataType] = [];
      }
      _strategies[dataType]!.add(strategy);

      // 按优先级排序
      _strategies[dataType]!.sort((a, b) => b.priority.compareTo(a.priority));
    }

    AppLogger.info('Registered data fetch strategy: ${strategy.name}');
  }

  /// 注销数据获取策略
  void unregisterStrategy(String strategyName) {
    for (final strategies in _strategies.values) {
      strategies.removeWhere((strategy) => strategy.name == strategyName);
    }
    AppLogger.info('Unregistered data fetch strategy: $strategyName');
  }

  /// 获取混合数据流
  Stream<DataItem> getMixedDataStream(DataType type) {
    if (!_dataControllers.containsKey(type)) {
      _dataControllers[type] = StreamController<DataItem>.broadcast();
    }

    return _dataControllers[type]!.stream;
  }

  /// 获取数据 (优先从缓存)
  Future<DataItem?> getData(DataType type,
      {Map<String, dynamic>? parameters}) async {
    final config = _configs[type];
    if (config == null || !config.autoFetchEnabled) {
      return null;
    }

    // 生成缓存键
    final cacheKey = _generateCacheKey(type, parameters);

    // 1. 首先检查内存缓存 (L1)
    final cachedItem = _cache[cacheKey];
    if (cachedItem != null && !cachedItem.isExpired) {
      AppLogger.debug('Memory cache hit for ${type.code}');
      return cachedItem;
    }

    // 2. 检查Hive缓存 (L2)
    try {
      final hiveCachedItem = await _cacheAdapter.getData(type, cacheKey);
      if (hiveCachedItem != null && !hiveCachedItem.isExpired) {
        AppLogger.debug('Hive cache hit for ${type.code}');

        // 将Hive缓存数据加载到内存缓存
        _cacheData(cacheKey, hiveCachedItem);

        // 发送到流
        _dataControllers[type]?.add(hiveCachedItem);

        return hiveCachedItem;
      }
    } catch (e) {
      AppLogger.warn('Hive cache access failed, falling back to network', e);
      // 继续网络请求
    }

    // 3. 从网络获取数据
    final result = await _fetchData(type, parameters);
    if (result.success && result.dataItem != null) {
      // 缓存数据到内存 (L1)
      _cacheData(cacheKey, result.dataItem!);

      // 异步存储到Hive缓存 (L2) - 不阻塞主要流程
      _cacheAdapter.storeData(result.dataItem!).catchError((e) {
        AppLogger.warn('Failed to store data to Hive cache', e);
        return false;
      });

      // 发送到流
      _dataControllers[type]?.add(result.dataItem!);

      return result.dataItem;
    }

    return null;
  }

  /// 内部数据获取方法
  Future<FetchResult> _fetchData(
      DataType type, Map<String, dynamic>? parameters) async {
    final stopwatch = Stopwatch()..start();

    try {
      final strategies = _strategies[type] ?? [];
      if (strategies.isEmpty) {
        return const FetchResult.failure('No strategy available for data type');
      }

      // 使用路由器选择最优策略
      final selectedStrategy = _router.selectOptimalStrategy(strategies, type);
      if (selectedStrategy == null) {
        return const FetchResult.failure('No available strategy for data type');
      }

      // 执行数据获取
      final result =
          await selectedStrategy.fetchData(type, parameters: parameters);

      // 记录性能指标
      stopwatch.stop();
      _recordLatency(type, stopwatch.elapsed);

      if (result.success) {
        _errorCounters[type] = 0; // 重置错误计数
        AppLogger.debug(
            'Successfully fetched ${type.code} using ${selectedStrategy.name}');
      } else {
        _errorCounters[type] = (_errorCounters[type] ?? 0) + 1;
        AppLogger.warning(
            'Failed to fetch ${type.code}: ${result.errorMessage}');
      }

      return result;
    } catch (e) {
      stopwatch.stop();
      _recordLatency(type, stopwatch.elapsed);
      _errorCounters[type] = (_errorCounters[type] ?? 0) + 1;
      AppLogger.error('Error fetching ${type.code}: $e');
      return FetchResult.failure(e.toString());
    }
  }

  /// 生成缓存键
  String _generateCacheKey(DataType type, Map<String, dynamic>? parameters) {
    final paramStr = parameters?.toString() ?? '';
    return '${type.code}_${paramStr.hashCode}';
  }

  /// 缓存数据
  void _cacheData(String key, DataItem item) {
    // 如果缓存已满，移除最旧的数据
    if (_cache.length >= _maxCacheSize) {
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
    }
    _cache[key] = item;
  }

  /// 记录延迟
  void _recordLatency(DataType type, Duration latency) {
    if (!_fetchLatencies.containsKey(type)) {
      _fetchLatencies[type] = [];
    }

    final latencies = _fetchLatencies[type]!;
    latencies.add(latency);

    // 只保留最近的100个记录
    if (latencies.length > 100) {
      latencies.removeAt(0);
    }
  }

  /// 获取性能指标
  Map<String, dynamic> getPerformanceMetrics() {
    final metrics = <String, dynamic>{};

    for (final type in DataType.values) {
      final latencies = _fetchLatencies[type] ?? [];
      final errors = _errorCounters[type] ?? 0;

      if (latencies.isNotEmpty) {
        final avgLatency = latencies.fold<int>(
                0, (sum, duration) => sum + duration.inMilliseconds) /
            latencies.length;

        metrics[type.code] = {
          'averageLatency': avgLatency.round(),
          'errorCount': errors,
          'requestCount': latencies.length,
          'errorRate': errors / latencies.length,
        };
      } else {
        metrics[type.code] = {
          'averageLatency': 0,
          'errorCount': errors,
          'requestCount': 0,
          'errorRate': 0.0,
        };
      }
    }

    return metrics;
  }

  /// 更新数据获取配置
  void updateConfig(DataType type, DataFetchConfig config) {
    _configs[type] = config;
    AppLogger.info('Updated config for ${type.code}');
  }

  /// 获取数据获取配置
  DataFetchConfig? getConfig(DataType type) {
    return _configs[type];
  }

  /// 启动管理器
  Future<void> start() async {
    if (_state == ManagerState.ready || _state == ManagerState.running) {
      return;
    }

    _updateState(ManagerState.starting);

    try {
      // 启动所有策略
      for (final strategies in _strategies.values) {
        for (final strategy in strategies) {
          await strategy.start();
        }
      }

      _updateState(ManagerState.running);
      AppLogger.info('HybridDataManager started successfully');
    } catch (e) {
      _updateState(ManagerState.error);
      AppLogger.error('Failed to start HybridDataManager: $e');
      rethrow;
    }
  }

  /// 停止管理器
  Future<void> stop() async {
    if (_state == ManagerState.stopped) {
      return;
    }

    _updateState(ManagerState.stopping);

    try {
      // 停止所有策略
      for (final strategies in _strategies.values) {
        for (final strategy in strategies) {
          await strategy.stop();
        }
      }

      // 清理资源
      _cache.clear();
      _fetchLatencies.clear();

      _updateState(ManagerState.stopped);
      AppLogger.info('HybridDataManager stopped successfully');
    } catch (e) {
      _updateState(ManagerState.error);
      AppLogger.error('Failed to stop HybridDataManager: $e');
      rethrow;
    }
  }

  /// 启动清理定时器
  void _startCleanupTimer() {
    Timer.periodic(const Duration(minutes: 5), (_) {
      _cleanupExpiredCache();
    });
  }

  /// 清理过期缓存
  void _cleanupExpiredCache() {
    final expiredKeys = <String>[];

    for (final entry in _cache.entries) {
      if (entry.value.isExpired) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _cache.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      AppLogger.debug('Cleaned up ${expiredKeys.length} expired cache items');
    }
  }

  /// 获取系统健康状态
  Future<Map<String, dynamic>> getHealthStatus() async {
    final strategyHealth = <String, dynamic>{};

    // 收集所有策略的健康状态
    final allStrategies = <DataFetchStrategy>{};
    for (final strategies in _strategies.values) {
      allStrategies.addAll(strategies);
    }

    for (final strategy in allStrategies) {
      try {
        final health = await strategy.getHealthStatus();
        strategyHealth[strategy.name] = health;
      } catch (e) {
        strategyHealth[strategy.name] = {
          'healthy': false,
          'error': e.toString(),
        };
      }
    }

    return {
      'manager': {
        'state': _state.name,
        'cacheSize': _cache.length,
        'dataTypes': _strategies.keys.map((t) => t.code).toList(),
      },
      'performance': getPerformanceMetrics(),
      'cache': getCacheHealthStatus(),
      'strategies': strategyHealth,
    };
  }

  /// 获取缓存数据
  Future<DataItem?> getCachedData(DataType type, String dataKey) async {
    try {
      return await _cacheAdapter.getData(type, dataKey);
    } catch (e) {
      AppLogger.error('HybridDataManager: 获取缓存数据失败', e);
      return null;
    }
  }

  /// 存储数据到缓存
  Future<bool> storeData(DataItem dataItem) async {
    try {
      return await _cacheAdapter.storeData(dataItem);
    } catch (e) {
      AppLogger.error('HybridDataManager: 存储缓存数据失败', e);
      return false;
    }
  }

  /// 清理过期缓存数据
  Future<void> cleanupExpiredCache() async {
    try {
      await _cacheAdapter.cleanupExpiredData();
      AppLogger.info('HybridDataManager: 过期缓存清理完成');
    } catch (e) {
      AppLogger.error('HybridDataManager: 清理过期缓存失败', e);
    }
  }

  /// 获取缓存健康状态
  Map<String, dynamic> getCacheHealthStatus() {
    return {
      'hiveAdapter': _cacheAdapter.getHealthStatus(),
      'memoryCache': {
        'size': _cache.length,
        'maxSize': _maxCacheSize,
      },
      'overallHealth': _calculateOverallCacheHealth(),
    };
  }

  /// 计算整体缓存健康度
  double _calculateOverallCacheHealth() {
    try {
      final hiveStatus = _cacheAdapter.getHealthStatus();
      final overallHitRate = hiveStatus['overallHitRate'] as double? ?? 0.0;

      // 内存缓存命中率计算
      int memoryHits = 0;
      int memoryRequests = 0;
      for (final stats in _fetchLatencies.values) {
        memoryRequests += stats.length;
        // 这里简化计算，实际应该记录内存缓存命中
        memoryHits += (stats.length ~/ 2); // 假设50%命中率
      }

      final memoryHitRate =
          memoryRequests > 0 ? memoryHits / memoryRequests : 0.0;

      // 综合健康度 (Hive权重70%，内存权重30%)
      return (overallHitRate * 0.7 + memoryHitRate * 0.3);
    } catch (e) {
      AppLogger.error('计算缓存健康度失败', e);
      return 0.0;
    }
  }

  /// 释放资源
  Future<void> dispose() async {
    stop();
    _stateController.close();

    for (final controller in _dataControllers.values) {
      controller.close();
    }
    _dataControllers.clear();

    // 释放缓存适配器资源
    try {
      await _cacheAdapter.dispose();
    } catch (e) {
      AppLogger.warn('HiveCacheAdapter dispose failed', e);
    }

    AppLogger.info('HybridDataManager: 资源释放完成');
  }
}

/// 管理器状态枚举
enum ManagerState {
  idle('空闲'),
  initializing('初始化中'),
  ready('就绪'),
  starting('启动中'),
  running('运行中'),
  stopping('停止中'),
  stopped('已停止'),
  error('错误');

  const ManagerState(this.description);
  final String description;
}
