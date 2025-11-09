import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:decimal/decimal.dart';

import '../../../../core/network/hybrid/data_type.dart';
import '../../../../core/network/hybrid/hybrid_data_manager.dart';
import '../../../../core/network/hybrid/data_fetch_strategy.dart';
import '../../../../core/network/polling/polling_manager.dart';
import '../../../../core/cache/unified_hive_cache_manager.dart';
import '../../../../core/utils/logger.dart';
import '../../models/fund_nav_data.dart';
import 'nav_change_detector.dart';
import 'nav_data_validator.dart';
import 'multi_source_data_validator.dart' as validator;
import '../cache/fund_nav_cache_manager.dart';
import '../monitors/nav_latency_monitor.dart';
import '../strategies/intelligent_cache_strategy.dart' as strategy;

/// 基金净值准实时数据管理器
///
/// 基于HybridDataManager扩展，专门处理基金净值数据的准实时获取、缓存和变化检测
/// 支持批量轮询、智能缓存和多源数据验证
class FundNavDataManager {
  /// 单例实例
  static final FundNavDataManager _instance = FundNavDataManager._internal();

  factory FundNavDataManager() => _instance;

  FundNavDataManager._internal() {
    _initialize();
  }

  /// 混合数据管理器引用
  late final HybridDataManager _hybridDataManager;

  /// 轮询管理器引用
  late final PollingManager _pollingManager;

  /// 统一Hive缓存管理器引用
  late final UnifiedHiveCacheManager _cacheManager;

  /// 净值变化检测器
  late final NavChangeDetector _changeDetector;

  /// 净值数据验证器
  late final NavDataValidator _dataValidator;

  /// 多源数据验证器
  late final validator.MultiSourceDataValidator _multiSourceValidator;

  /// 基金净值缓存管理器
  late final FundNavCacheManager _navCacheManager;

  /// 压缩优化器 (暂时未使用)
  // late final NavDataCompressionOptimizer _compressionOptimizer;

  /// 延迟监控器
  late final NavLatencyMonitor _latencyMonitor;

  /// 智能缓存策略管理器
  late final strategy.IntelligentCacheStrategy _cacheStrategy;

  /// 跟踪的基金代码集合
  final Set<String> _trackedFundCodes = {};

  /// 基金净值数据流控制器
  final Map<String, StreamController<FundNavData>> _navControllers = {};

  /// 批量轮询任务ID
  String? _batchPollingTaskId;

  /// 轮询是否启用
  bool _pollingEnabled = true;

  /// 当前轮询间隔
  Duration _pollingInterval = const Duration(seconds: 30);

  /// 性能监控
  final Queue<Duration> _recentLatencies = Queue<Duration>();

  /// 延迟阈值，超过此值将触发频率调整
  static const Duration _latencyThreshold = Duration(seconds: 30);

  /// 数据流控制器 (全局净值更新事件)
  final StreamController<FundNavUpdateEvent> _updateController =
      StreamController<FundNavUpdateEvent>.broadcast();

  /// 状态流控制器
  final StreamController<FundNavManagerState> _stateController =
      StreamController<FundNavManagerState>.broadcast();

  /// 管理器状态
  FundNavManagerState _state = FundNavManagerState.idle;

  /// 初始化管理器
  Future<void> _initialize() async {
    try {
      _updateState(FundNavManagerState.initializing);

      // 获取依赖服务实例
      _hybridDataManager = HybridDataManager();
      _pollingManager = PollingManager();
      _cacheManager = UnifiedHiveCacheManager.instance;
      _changeDetector = NavChangeDetector();
      _dataValidator = NavDataValidator();
      _multiSourceValidator = validator.MultiSourceDataValidator();
      // _compressionOptimizer = NavDataCompressionOptimizer();
      _latencyMonitor = NavLatencyMonitor();
      _cacheStrategy = strategy.IntelligentCacheStrategy();
      _navCacheManager = FundNavCacheManager();

      // 初始化缓存管理器（如果需要）
      await _cacheManager.initialize();

      // 启动清理定时器
      _startCleanupTimer();

      _updateState(FundNavManagerState.ready);
      AppLogger.info('FundNavDataManager initialized successfully');
    } catch (e) {
      _updateState(FundNavManagerState.error);
      AppLogger.error('Failed to initialize FundNavDataManager', e);
      rethrow;
    }
  }

  /// 获取管理器状态
  FundNavManagerState get state => _state;

  /// 状态变化流
  Stream<FundNavManagerState> get stateStream => _stateController.stream;

  /// 净值更新事件流
  Stream<FundNavUpdateEvent> get updateStream => _updateController.stream;

  /// 更新管理器状态
  void _updateState(FundNavManagerState newState) {
    if (_state != newState) {
      final oldState = _state;
      _state = newState;
      _stateController.add(newState);
      AppLogger.info(
          'FundNavDataManager state changed: ${oldState.name} → ${newState.name}');
    }
  }

  /// 添加基金代码到跟踪列表
  Future<void> addFundCode(String fundCode) async {
    if (_trackedFundCodes.contains(fundCode)) {
      AppLogger.debug('Fund code $fundCode already tracked');
      return;
    }

    _trackedFundCodes.add(fundCode);
    _navControllers[fundCode] =
        StreamController<FundNavData>.broadcast();

    // 注册智能缓存策略
    _cacheStrategy.registerFundStrategy(fundCode, strategy.CacheStrategy.balanced);

    AppLogger.info('Added fund code to tracking: $fundCode');

    // 如果这是第一个基金代码，启动批量轮询
    if (_trackedFundCodes.length == 1) {
      await _startBatchPolling();
    }
  }

  /// 从跟踪列表移除基金代码
  Future<void> removeFundCode(String fundCode) async {
    if (!_trackedFundCodes.contains(fundCode)) {
      return;
    }

    _trackedFundCodes.remove(fundCode);

    // 关闭数据流控制器
    final controller = _navControllers.remove(fundCode);
    controller?.close();

    // 清理缓存
    await _navCacheManager.clearCacheForFund(fundCode);

    AppLogger.info('Removed fund code from tracking: $fundCode');

    // 如果没有跟踪的基金代码，停止批量轮询
    if (_trackedFundCodes.isEmpty) {
      await _stopBatchPolling();
    }
  }

  /// 获取跟踪的基金代码列表
  Set<String> get trackedFundCodes => Set.unmodifiable(_trackedFundCodes);

  /// 获取指定基金的净值数据流
  Stream<FundNavData>? getNavDataStream(String fundCode) {
    return _navControllers[fundCode]?.stream;
  }

  /// 启动批量轮询
  Future<void> _startBatchPolling() async {
    if (!_pollingEnabled || _trackedFundCodes.isEmpty) {
      return;
    }

    try {
      _updateState(FundNavManagerState.polling);

      // 移除现有的批量轮询任务
      if (_batchPollingTaskId != null) {
        _pollingManager.removeTask(_batchPollingTaskId!);
      }

      // 创建批量轮询任务
      _batchPollingTaskId = 'batch_fund_nav_${DateTime.now().millisecondsSinceEpoch}';

      final pollingTask = PollingTask(
        dataType: DataType.fundNetValue,
        interval: _pollingInterval,
        parameters: {
          'codes': _trackedFundCodes.toList(),
          'batch': true,
          'max_batch_size': 50, // 每批最多50只基金
          'fields': ['nav', 'nav_date', 'accumulated_nav', 'change_rate'],
        },
        maxRetries: 3,
        timeout: const Duration(seconds: 45),
      );

      // 设置轮询数据监听
      _pollingManager.getDataStream(DataType.fundNetValue)?.listen(
        (dataItem) => _processBatchNavData(dataItem),
        onError: (error) {
          AppLogger.error('Batch NAV polling error', error);
          _handlePollingError(error);
        },
      );

      _pollingManager.addTask(pollingTask);
      AppLogger.info('Started batch NAV polling for ${_trackedFundCodes.length} funds');
    } catch (e) {
      _updateState(FundNavManagerState.error);
      AppLogger.error('Failed to start batch NAV polling', e);
    }
  }

  /// 停止批量轮询
  Future<void> _stopBatchPolling() async {
    if (_batchPollingTaskId != null) {
      _pollingManager.removeTask(_batchPollingTaskId!);
      _batchPollingTaskId = null;
      AppLogger.info('Stopped batch NAV polling');
    }
    _updateState(FundNavManagerState.ready);
  }

  /// 处理批量净值数据
  Future<void> _processBatchNavData(DataItem dataItem) async {
    final stopwatch = Stopwatch()..start();

    try {
      final data = dataItem.data as Map<String, dynamic>;
      final fundList = data['funds'] as List<dynamic>? ?? [];

      for (final fundData in fundList) {
        await _processSingleFundNav(fundData);
      }

      stopwatch.stop();
      _recordLatency(stopwatch.elapsed);

      AppLogger.debug(
          'Processed batch NAV data for ${fundList.length} funds in ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      AppLogger.error('Failed to process batch NAV data', e);
    }
  }

  /// 处理单个基金净值数据
  Future<void> _processSingleFundNav(Map<String, dynamic> fundData) async {
    final fundCode = fundData['code'] as String?;
    if (fundCode == null || !_trackedFundCodes.contains(fundCode)) {
      return;
    }

    final operationId = _latencyMonitor.startOperation('process_single_fund_nav', {
      'fundCode': fundCode,
      'dataSize': fundData.length,
    });

    try {
      // 解析净值数据
      final parseId = _latencyMonitor.startOperation('parse_nav_data', {'fundCode': fundCode});
      final navData = _parseNavData(fundData);
      _latencyMonitor.endOperation(parseId);

      if (navData == null) {
        _latencyMonitor.recordError('process_single_fund_nav', 'Failed to parse NAV data', context: {'fundCode': fundCode});
        AppLogger.warn('Failed to parse NAV data for fund $fundCode');
        return;
      }

      // 基础数据验证
      final validationId = _latencyMonitor.startOperation('validate_nav_data', {'fundCode': fundCode});
      final validationResult = await _dataValidator.validateNavData(navData);
      _latencyMonitor.endOperation(validationId);

      if (!validationResult.isValid) {
        _latencyMonitor.recordError('process_single_fund_nav', 'NAV data validation failed', context: {
          'fundCode': fundCode,
          'errors': validationResult.errors,
        });
        AppLogger.warn(
            'NAV data validation failed for fund $fundCode: ${validationResult.errors}');
        return;
      }

      // 多源数据验证 (异步执行，不阻塞主要流程)
      _performMultiSourceValidation(navData).catchError((e) {
        _latencyMonitor.recordError('multi_source_validation', e.toString(), context: {'fundCode': fundCode});
        AppLogger.warn('Multi-source validation failed for fund $fundCode: $e');
      });

      // 获取前一个净值数据用于变化检测
      final cacheId = _latencyMonitor.startOperation('get_cached_nav_data', {'fundCode': fundCode});
      final previousNav = await _navCacheManager.getNavData(fundCode);
      _latencyMonitor.endOperation(cacheId);

      if (previousNav != null) {
        _latencyMonitor.recordCacheHit('l1_cache', fundCode, Duration.zero);
      } else {
        _latencyMonitor.recordCacheMiss('l1_cache', fundCode, Duration.zero);
      }

      // 缓存新数据
      final storeId = _latencyMonitor.startOperation('cache_nav_data', {'fundCode': fundCode});
      await _cacheNavData(fundCode, navData);
      _latencyMonitor.endOperation(storeId);

      // 更新智能缓存策略（异步执行，不阻塞主要流程）
      _cacheStrategy.analyzeAndUpdateStrategy(fundCode, navData: navData).catchError((e) {
        AppLogger.warn('智能缓存策略更新失败: $fundCode - $e');
      });

      // 检测变化
      final detectId = _latencyMonitor.startOperation('detect_change', {'fundCode': fundCode});
      final changeInfo = previousNav != null
          ? _changeDetector.detectChange(previousNav, navData)
          : null;
      _latencyMonitor.endOperation(detectId);

      // 发送数据到流
      final controller = _navControllers[fundCode];
      controller?.add(navData);

      // 如果有变化，发送更新事件
      if (changeInfo != null && changeInfo.hasChange) {
        _updateController.add(FundNavUpdateEvent(
          fundCode: fundCode,
          currentNav: navData,
          previousNav: previousNav,
          changeInfo: changeInfo,
          timestamp: DateTime.now(),
        ));

        _latencyMonitor.recordMetric('nav_changes_detected', 1, tags: {
          'changeType': changeInfo.changeType.name,
          'fundCode': fundCode,
        });

        AppLogger.info(
            'NAV change detected for fund $fundCode: ${changeInfo.changeType.name} (${changeInfo.changePercentage.toStringAsFixed(2)}%)');
      }

      // 异步存储到Hive缓存 (L2)
      final hiveStoreId = _latencyMonitor.startOperation('store_to_hive_cache', {'fundCode': fundCode});
      _storeToHiveCache(navData).then((_) {
        _latencyMonitor.endOperation(hiveStoreId);
      }).catchError((e) {
        _latencyMonitor.endOperation(hiveStoreId, success: false);
        _latencyMonitor.recordError('store_to_hive_cache', e.toString(), context: {'fundCode': fundCode});
        AppLogger.warn('Failed to store NAV data to Hive cache', e);
      });

      _latencyMonitor.endOperation(operationId, success: true);
    } catch (e) {
      _latencyMonitor.endOperation(operationId, success: false);
      _latencyMonitor.recordError('process_single_fund_nav', e.toString(), context: {'fundCode': fundCode});
      AppLogger.error('Failed to process single fund NAV data', e);
    }
  }

  /// 解析净值数据
  FundNavData? _parseNavData(Map<String, dynamic> fundData) {
    try {
      final fundCode = fundData['code'] as String?;
      final nav = fundData['nav'] as String?;
      final navDate = fundData['nav_date'] as String?;
      final accumulatedNav = fundData['accumulated_nav'] as String?;
      final changeRate = fundData['change_rate'] as String?;

      if (fundCode == null || nav == null || navDate == null) {
        return null;
      }

      return FundNavData(
        fundCode: fundCode,
        nav: Decimal.tryParse(nav) ?? Decimal.zero,
        navDate: DateTime.tryParse(navDate) ?? DateTime.now(),
        accumulatedNav: Decimal.tryParse(accumulatedNav ?? '0') ?? Decimal.zero,
        changeRate: Decimal.tryParse(changeRate ?? '0') ?? Decimal.zero,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      AppLogger.error('Failed to parse NAV data', e);
      return null;
    }
  }

  /// 缓存净值数据
  Future<void> _cacheNavData(String fundCode, FundNavData navData) async {
    try {
      // 1. 存储到专用净值缓存管理器
      await _navCacheManager.storeNavData(navData);

      // 2. 存储到统一缓存管理器的专用NAV方法
      await _cacheManager.storeNavData(
        fundCode,
        navData.toJson(),
        expiration: const Duration(hours: 2),
      );

      AppLogger.debug('NAV数据已缓存到L1和L2: $fundCode');
    } catch (e) {
      AppLogger.error('Failed to cache NAV data for fund $fundCode', e);
    }
  }

  /// 存储到Hive缓存
  Future<bool> _storeToHiveCache(FundNavData navData) async {
    try {
      final cacheItem = DataItem(
        dataType: DataType.fundNetValue,
        data: navData.toJson(),
        timestamp: navData.timestamp,
        quality: DataQualityLevel.good,
        source: DataSource.httpPolling,
        id: 'nav_${navData.fundCode}_${navData.timestamp.millisecondsSinceEpoch}',
      );

      return await _hybridDataManager.storeData(cacheItem);
    } catch (e) {
      AppLogger.error('Failed to store NAV data to Hive cache', e);
      return false;
    }
  }

  /// 从缓存获取净值数据
  Future<FundNavData?> getCachedNavData(String fundCode) async {
    try {
      // 1. 首先从专用净值缓存管理器获取
      final navData = await _navCacheManager.getNavData(fundCode);
      if (navData != null) {
        return navData;
      }

      // 2. 从统一缓存管理器获取
      final cachedData = _cacheManager.getNavData(fundCode);
      if (cachedData != null) {
        return FundNavData.fromJson(cachedData);
      }

      return null;
    } catch (e) {
      AppLogger.error('Failed to get cached NAV data for fund $fundCode', e);
      return null;
    }
  }

  /// 批量获取缓存净值数据
  Future<Map<String, FundNavData>> getBatchCachedNavData(List<String> fundCodes) async {
    try {
      final results = <String, FundNavData>{};

      // 1. 首先从专用净值缓存管理器批量获取
      final navResults = await _navCacheManager.getBatchNavData(fundCodes);
      results.addAll(navResults);

      // 2. 对于未命中的基金，从统一缓存管理器获取
      final missingCodes = fundCodes.where((code) => !results.containsKey(code)).toList();
      if (missingCodes.isNotEmpty) {
        final batchResults = _cacheManager.getBatchNavData(missingCodes);
        for (final entry in batchResults.entries) {
          if (entry.value != null) {
            results[entry.key] = FundNavData.fromJson(entry.value!);
          }
        }
      }

      AppLogger.debug('批量NAV缓存查询: ${results.length}/${fundCodes.length} 命中');
      return results;
    } catch (e) {
      AppLogger.error('Failed to get batch cached NAV data', e);
      return {};
    }
  }

  /// 获取历史净值数据
  Future<List<FundNavData>> getHistoricalNavData(
    String fundCode, {
    int limit = 30,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // 1. 首先从专用净值缓存管理器获取
      final historicalData = await _navCacheManager.getHistoricalNavData(
        fundCode,
        limit: limit,
        startDate: startDate,
        endDate: endDate,
      );

      if (historicalData.isNotEmpty) {
        return historicalData;
      }

      // 2. 从统一缓存管理器获取
      final historicalRecords = await _cacheManager.getHistoricalNavData(
        fundCode,
        limit: limit,
        startDate: startDate,
        endDate: endDate,
      );

      return historicalRecords
          .map((record) => FundNavData.fromJson(record))
          .toList();
    } catch (e) {
      AppLogger.error('Failed to get historical NAV data for fund $fundCode', e);
      return [];
    }
  }

  /// 存储历史净值数据
  Future<bool> storeHistoricalNavData(String fundCode, List<FundNavData> navDataList) async {
    try {
      // 1. 存储到专用净值缓存管理器
      final success1 = await _navCacheManager.storeHistoricalNavData(fundCode, navDataList);

      // 2. 存储到统一缓存管理器
      final historicalJson = navDataList.map((data) => data.toJson()).toList();
      await _cacheManager.storeNavData(
        fundCode,
        {}, // 当前净值数据（空）
        storeHistorical: true,
        historicalData: historicalJson,
      );

      return success1;
    } catch (e) {
      AppLogger.error('Failed to store historical NAV data for fund $fundCode', e);
      return false;
    }
  }

  /// 记录延迟
  void _recordLatency(Duration latency) {
    _recentLatencies.add(latency);

    // 只保留最近的100个记录
    while (_recentLatencies.length > 100) {
      _recentLatencies.removeFirst();
    }

    // 如果延迟过高，调整轮询频率
    if (latency > _latencyThreshold) {
      _adjustPollingFrequency();
    }
  }

  /// 调整轮询频率
  void _adjustPollingFrequency() {
    if (_recentLatencies.length < 5) return;

    final avgLatency = _recentLatencies.fold<int>(
        0, (sum, duration) => sum + duration.inMilliseconds) /
        _recentLatencies.length;

    // 如果平均延迟超过阈值，增加轮询间隔
    if (avgLatency > _latencyThreshold.inMilliseconds &&
        _pollingInterval.inSeconds < 120) {

      _pollingInterval = Duration(
        seconds: math.min(120, _pollingInterval.inSeconds + 15),
      );

      AppLogger.info(
          'Adjusted polling frequency to ${_pollingInterval.inSeconds}s due to high latency (${avgLatency.round()}ms avg)');

      // 重新启动轮询任务以应用新频率
      if (_batchPollingTaskId != null) {
        _restartBatchPolling();
      }
    }
  }

  /// 重新启动批量轮询
  Future<void> _restartBatchPolling() async {
    await _stopBatchPolling();
    await Future.delayed(const Duration(seconds: 1));
    await _startBatchPolling();
  }

  /// 处理轮询错误
  void _handlePollingError(dynamic error) {
    _updateState(FundNavManagerState.error);
    AppLogger.error('NAV polling error occurred', error);

    // 简单的重试机制
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_state == FundNavManagerState.error && _trackedFundCodes.isNotEmpty) {
        _restartBatchPolling();
        timer.cancel();
      }
    });
  }

  /// 启动轮询
  Future<void> startPolling() async {
    _pollingEnabled = true;
    if (_trackedFundCodes.isNotEmpty) {
      await _startBatchPolling();
    }
    AppLogger.info('NAV polling started');
  }

  /// 停止轮询
  Future<void> stopPolling() async {
    _pollingEnabled = false;
    await _stopBatchPolling();
    AppLogger.info('NAV polling stopped');
  }

  /// 设置轮询间隔
  Future<void> setPollingInterval(Duration interval) async {
    _pollingInterval = interval;

    if (_batchPollingTaskId != null) {
      await _restartBatchPolling();
    }

    AppLogger.info('NAV polling interval set to ${interval.inSeconds}s');
  }

  /// 获取性能指标
  Map<String, dynamic> getPerformanceMetrics() {
    if (_recentLatencies.isEmpty) {
      return {
        'averageLatency': 0,
        'maxLatency': 0,
        'minLatency': 0,
        'requestCount': 0,
        'trackedFunds': _trackedFundCodes.length,
        'cacheStatistics': _navCacheManager.statistics.toJson(),
        'pollingInterval': _pollingInterval.inSeconds,
        'pollingEnabled': _pollingEnabled,
      };
    }

    final latencies = _recentLatencies.map((d) => d.inMilliseconds).toList();
    latencies.sort();

    return {
      'averageLatency': latencies.fold<int>(0, (sum, ms) => sum + ms) / latencies.length,
      'maxLatency': latencies.last,
      'minLatency': latencies.first,
      'requestCount': _recentLatencies.length,
      'trackedFunds': _trackedFundCodes.length,
      'cacheStatistics': _navCacheManager.statistics.toJson(),
      'cacheHealthStatus': _navCacheManager.getCacheHealthStatus(),
      'pollingInterval': _pollingInterval.inSeconds,
      'pollingEnabled': _pollingEnabled,
    };
  }

  /// 启动清理定时器
  void _startCleanupTimer() {
    Timer.periodic(const Duration(minutes: 10), (_) {
      _cleanupExpiredCache();
    });
  }

  /// 清理过期缓存
  Future<void> _cleanupExpiredCache() async {
    // 缓存清理现在由FundNavCacheManager处理
    AppLogger.debug('Cache cleanup delegated to FundNavCacheManager');
  }

  /// 执行多源数据验证
  Future<void> _performMultiSourceValidation(FundNavData navData) async {
    try {
      AppLogger.debug('Starting multi-source validation for fund ${navData.fundCode}');

      final validationResult = await _multiSourceValidator.validateNavData(navData);

      if (!validationResult.isValid) {
        AppLogger.warn(
            'Multi-source validation failed for fund ${navData.fundCode}: confidence=${(validationResult.confidenceScore * 100).toStringAsFixed(1)}%');

        // 如果置信度过低，可以考虑重新获取数据或发出警告
        if (validationResult.confidenceScore < 0.5) {
          await _handleLowConfidenceData(navData, validationResult);
        }
      } else {
        AppLogger.debug(
            'Multi-source validation passed for fund ${navData.fundCode}: confidence=${(validationResult.confidenceScore * 100).toStringAsFixed(1)}%');
      }

      // 记录验证结果（可以用于后续分析）
      _recordValidationResult(navData.fundCode, validationResult);
    } catch (e) {
      AppLogger.error('Multi-source validation error for fund ${navData.fundCode}', e);
    }
  }

  /// 处理低置信度数据
  Future<void> _handleLowConfidenceData(
    FundNavData navData,
    validator.MultiSourceValidationResult validationResult,
  ) async {
    AppLogger.warn(
        'Low confidence data detected for fund ${navData.fundCode}: ${(validationResult.confidenceScore * 100).toStringAsFixed(1)}%');

    // 检查异常类型并采取相应措施
    for (final anomaly in validationResult.anomalyDetection.anomalies) {
      switch (anomaly.type) {
        case validator.AnomalyType.dataConflict:
          AppLogger.warn('Data conflict detected: ${anomaly.description}');
          // 可以考虑暂停更新或标记数据为可疑
          break;
        case validator.AnomalyType.unusualChange:
          AppLogger.info('Unusual change detected: ${anomaly.description}');
          // 可以增加监控频率
          break;
        case validator.AnomalyType.unreasonableValue:
          AppLogger.error('Unreasonable value detected', anomaly.description);
          // 可以考虑丢弃该数据
          break;
        case validator.AnomalyType.dataError:
          AppLogger.error('Data error detected', anomaly.description);
          // 立即报告错误
          break;
      }
    }

    // 发送低置信度事件
    final previousNav = await _navCacheManager.getNavData(navData.fundCode);
    _updateController.add(FundNavUpdateEvent(
      fundCode: navData.fundCode,
      currentNav: navData,
      previousNav: previousNav,
      changeInfo: NavChangeInfo(
        changeType: NavChangeType.flat,
        changeAmount: Decimal.zero,
        changeRate: Decimal.zero,
        changePercentage: Decimal.zero,
        isSignificant: false,
        isLargeChange: false,
        isVolatile: false,
        changeIntensity: 0.0,
        trend: null,
        anomalyInfo: const NavAnomalyInfo(
        isAnomaly: false,
        anomalyType: null,
        severity: AnomalySeverity.none,
        confidence: 0.0,
        description: '无异常',
      ),
        description: '无变化',
        previousNav: previousNav ?? navData,
        currentNav: navData,
        detectionTime: DateTime.now(),
      ),
      timestamp: DateTime.now(),
    ));
  }

  /// 记录验证结果
  void _recordValidationResult(
    String fundCode,
    validator.MultiSourceValidationResult validationResult,
  ) {
    // 这里可以记录验证结果到数据库或日志系统
    // 用于后续分析和优化
    AppLogger.debug(
        'Validation result recorded for fund $fundCode: confidence=${(validationResult.confidenceScore * 100).toStringAsFixed(1)}%, anomalies=${validationResult.anomalyDetection.anomalyCount}');
  }

  /// 释放资源
  Future<void> dispose() async {
    await stopPolling();

    _stateController.close();
    _updateController.close();

    for (final controller in _navControllers.values) {
      controller.close();
    }

    _navControllers.clear();
    _trackedFundCodes.clear();
    _recentLatencies.clear();

    // 释放缓存管理器
    await _navCacheManager.dispose();

    AppLogger.info('FundNavDataManager disposed');
  }
}

/// 基金净值管理器状态
enum FundNavManagerState {
  idle('空闲'),
  initializing('初始化中'),
  ready('就绪'),
  polling('轮询中'),
  error('错误');

  const FundNavManagerState(this.description);
  final String description;
}

/// 基金净值更新事件
class FundNavUpdateEvent {
  /// 基金代码
  final String fundCode;

  /// 当前净值数据
  final FundNavData currentNav;

  /// 前一个净值数据
  final FundNavData? previousNav;

  /// 变化信息
  final NavChangeInfo changeInfo;

  /// 更新时间戳
  final DateTime timestamp;

  const FundNavUpdateEvent({
    required this.fundCode,
    required this.currentNav,
    this.previousNav,
    required this.changeInfo,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'FundNavUpdateEvent(fundCode: $fundCode, changeType: ${changeInfo.changeType}, changePercentage: ${changeInfo.changePercentage.toStringAsFixed(2)}%)';
  }
}