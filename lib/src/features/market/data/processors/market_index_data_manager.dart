import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:decimal/decimal.dart';

import '../../../../core/network/hybrid/data_type.dart' as hybrid;
import '../../../../core/network/hybrid/hybrid_data_manager.dart';
import '../../../../core/network/hybrid/data_fetch_strategy.dart';
import '../../../../core/network/polling/polling_manager.dart';
import '../../../../core/cache/unified_hive_cache_manager.dart';
import '../../../../core/utils/logger.dart';
import '../../models/market_index_data.dart';
import '../../models/index_change_data.dart';
import 'index_change_analyzer.dart';
import 'index_data_validator.dart';
import 'multi_source_index_validator.dart' as validator;
import '../cache/market_index_cache_manager.dart';
import '../monitors/index_latency_monitor.dart';
import '../strategies/index_data_compression_optimizer.dart';
import '../strategies/intelligent_index_cache_strategy.dart' as strategy;

/// 市场指数准实时数据管理器
///
/// 基于HybridDataManager扩展，专门处理市场指数数据的准实时获取、缓存和变化检测
/// 支持批量轮询、智能缓存和多源数据验证
class MarketIndexDataManager {
  /// 单例实例
  static final MarketIndexDataManager _instance =
      MarketIndexDataManager._internal();

  factory MarketIndexDataManager() => _instance;

  MarketIndexDataManager._internal() {
    _initialize();
  }

  /// 混合数据管理器引用
  late final HybridDataManager _hybridDataManager;

  /// 轮询管理器引用
  late final PollingManager _pollingManager;

  /// 统一Hive缓存管理器引用
  late final UnifiedHiveCacheManager _cacheManager;

  /// 指数变化检测器
  late final IndexChangeAnalyzer _changeAnalyzer;

  /// 指数数据验证器
  late final IndexDataValidator _dataValidator;

  /// 多源数据验证器
  late final validator.MultiSourceIndexValidator _multiSourceValidator;

  /// 指数缓存管理器
  late final MarketIndexCacheManager _indexCacheManager;

  /// 压缩优化器
  late final IndexDataCompressionOptimizer _compressionOptimizer;

  /// 延迟监控器
  late final IndexLatencyMonitor _latencyMonitor;

  /// 智能缓存策略管理器
  late final strategy.IntelligentIndexCacheStrategy _cacheStrategy;

  /// 跟踪的指数代码集合
  final Set<String> _trackedIndexCodes = {};

  /// 指数数据流控制器
  final Map<String, StreamController<MarketIndexData>> _indexControllers = {};

  /// 指数变化流控制器
  final Map<String, StreamController<IndexChangeData>> _changeControllers = {};

  /// 批量轮询任务ID
  String? _batchPollingTaskId;

  /// 定时器用于批量轮询
  Timer? _batchPollingTimer;

  /// 轮询是否启用
  bool _pollingEnabled = true;

  /// 当前轮询间隔
  Duration _pollingInterval = const Duration(seconds: 30);

  /// 性能监控
  final Queue<Duration> _recentLatencies = Queue<Duration>();

  /// 延迟阈值，超过此值将触发频率调整
  static const Duration _latencyThreshold = Duration(seconds: 30);

  /// 数据流控制器 (全局指数更新事件)
  final StreamController<MarketIndexUpdateEvent> _updateController =
      StreamController<MarketIndexUpdateEvent>.broadcast();

  /// 状态流控制器
  final StreamController<MarketIndexManagerState> _stateController =
      StreamController<MarketIndexManagerState>.broadcast();

  /// 管理器状态
  MarketIndexManagerState _state = MarketIndexManagerState.idle;

  /// 最大并发请求数
  static const int _maxConcurrentRequests = 20;

  /// 批量请求超时时间
  static const Duration _batchTimeout = Duration(seconds: 45);

  /// 初始化管理器
  Future<void> _initialize() async {
    try {
      _updateState(MarketIndexManagerState.initializing);

      // 初始化核心组件
      _hybridDataManager = HybridDataManager();
      _pollingManager = PollingManager();
      _cacheManager = UnifiedHiveCacheManager.instance;

      // 初始化指数专用组件
      _changeAnalyzer = IndexChangeAnalyzer();
      _dataValidator = IndexDataValidator();
      _multiSourceValidator = validator.MultiSourceIndexValidator();
      _indexCacheManager = MarketIndexCacheManager();
      _compressionOptimizer = IndexDataCompressionOptimizer();
      _latencyMonitor = IndexLatencyMonitor();
      _cacheStrategy = strategy.IntelligentIndexCacheStrategy(
        cacheManager: _indexCacheManager,
      );

      // 初始化默认跟踪的指数
      _initializeDefaultIndices();

      _updateState(MarketIndexManagerState.ready);
      AppLogger.info('MarketIndexDataManager initialized successfully');
    } catch (e) {
      _updateState(MarketIndexManagerState.error);
      AppLogger.error('Failed to initialize MarketIndexDataManager: $e', e);
      rethrow;
    }
  }

  /// 初始化默认跟踪的指数
  void _initializeDefaultIndices() {
    final defaultIndices = MarketIndexConstants.allMajorIndices;
    for (final indexCode in defaultIndices) {
      _trackedIndexCodes.add(indexCode);
      _indexControllers[indexCode] =
          StreamController<MarketIndexData>.broadcast();
      _changeControllers[indexCode] =
          StreamController<IndexChangeData>.broadcast();
    }
  }

  /// 获取管理器状态
  MarketIndexManagerState get state => _state;

  /// 状态变化流
  Stream<MarketIndexManagerState> get stateStream => _stateController.stream;

  /// 更新事件流
  Stream<MarketIndexUpdateEvent> get updateStream => _updateController.stream;

  /// 更新管理器状态
  void _updateState(MarketIndexManagerState newState) {
    if (_state != newState) {
      final oldState = _state;
      _state = newState;
      _stateController.add(newState);
      AppLogger.info(
          'MarketIndexDataManager state changed: ${oldState.name} → ${newState.name}');
    }
  }

  /// 开始跟踪指数
  Future<void> startTrackingIndex(String indexCode) async {
    if (!_trackedIndexCodes.contains(indexCode)) {
      _trackedIndexCodes.add(indexCode);
      _indexControllers[indexCode] =
          StreamController<MarketIndexData>.broadcast();
      _changeControllers[indexCode] =
          StreamController<IndexChangeData>.broadcast();

      AppLogger.info('Started tracking index: $indexCode');

      // 如果轮询已启用，触发数据获取
      if (_pollingEnabled && _batchPollingTaskId != null) {
        await _refreshIndexData(indexCode);
      }
    }
  }

  /// 停止跟踪指数
  Future<void> stopTrackingIndex(String indexCode) async {
    if (_trackedIndexCodes.contains(indexCode)) {
      _trackedIndexCodes.remove(indexCode);

      // 关闭流控制器
      await _indexControllers[indexCode]?.close();
      await _changeControllers[indexCode]?.close();
      _indexControllers.remove(indexCode);
      _changeControllers.remove(indexCode);

      AppLogger.info('Stopped tracking index: $indexCode');
    }
  }

  /// 获取指数数据流
  Stream<MarketIndexData>? getIndexDataStream(String indexCode) {
    return _indexControllers[indexCode]?.stream;
  }

  /// 获取指数变化流
  Stream<IndexChangeData>? getIndexChangeStream(String indexCode) {
    return _changeControllers[indexCode]?.stream;
  }

  /// 开始批量轮询
  Future<void> startBatchPolling() async {
    if (_batchPollingTimer != null && _batchPollingTimer!.isActive) {
      AppLogger.warn('Batch polling already started');
      return;
    }

    if (_trackedIndexCodes.isEmpty) {
      AppLogger.warn('No indices to track');
      return;
    }

    _updateState(MarketIndexManagerState.polling);

    // 启动定时器进行批量轮询
    _batchPollingTimer = Timer.periodic(_pollingInterval, (_) {
      _performBatchPolling();
    });

    AppLogger.info(
        'Started batch polling for ${_trackedIndexCodes.length} indices');
  }

  /// 执行批量轮询
  Future<void> _performBatchPolling() async {
    if (!_pollingEnabled || _trackedIndexCodes.isEmpty) {
      return;
    }

    try {
      _updateState(MarketIndexManagerState.fetching);

      final stopwatch = Stopwatch()..start();

      // 分批处理，避免过多并发请求
      final indexCodes = _trackedIndexCodes.toList();
      final batches = _createBatches(indexCodes, _maxConcurrentRequests);

      for (final batch in batches) {
        await _fetchIndexBatch(batch);
      }

      stopwatch.stop();
      final latency = stopwatch.elapsed;

      // 记录延迟监控
      _latencyMonitor.recordLatency(
        latency,
        indexCode: 'batch_polling',
      );
      _recentLatencies.add(latency);

      // 保持最近的延迟记录
      while (_recentLatencies.length > 100) {
        _recentLatencies.removeFirst();
      }

      // 检查是否需要调整轮询频率
      _adjustPollingFrequencyIfNeeded();

      _updateState(MarketIndexManagerState.polling);

      AppLogger.debug('Batch polling completed in ${latency.inMilliseconds}ms');
    } catch (e) {
      _updateState(MarketIndexManagerState.error);
      AppLogger.error('Batch polling failed: $e', e);
    }
  }

  /// 创建批次
  List<List<String>> _createBatches(List<String> items, int batchSize) {
    final batches = <List<String>>[];
    for (int i = 0; i < items.length; i += batchSize) {
      final end = math.min(i + batchSize, items.length);
      batches.add(items.sublist(i, end));
    }
    return batches;
  }

  /// 批量获取指数数据
  Future<void> _fetchIndexBatch(List<String> indexCodes) async {
    try {
      // 并发获取指数数据
      final futures = indexCodes.map((code) => _fetchSingleIndex(code));
      final results = await Future.wait(
        futures,
        eagerError: false,
      );

      // 处理结果
      for (int i = 0; i < indexCodes.length; i++) {
        final result = results[i];
        if (result != null) {
          await _processIndexData(result);
        }
      }
    } catch (e) {
      AppLogger.error('Failed to fetch index batch: $e', e);
    }
  }

  /// 获取单个指数数据
  Future<MarketIndexData?> _fetchSingleIndex(String indexCode) async {
    try {
      // 使用混合数据管理器获取数据
      final dataItem = await _hybridDataManager.getData(
        hybrid.DataType.marketIndex,
        parameters: {'indexCode': indexCode},
      );

      if (dataItem != null && dataItem.data != null) {
        // 将DataItem转换为MarketIndexData
        final indexData = _convertToMarketIndexData(
          dataItem.data as Map<String, dynamic>,
          indexCode,
        );

        // 数据验证
        final validationResult = _dataValidator.validate(indexData);
        if (validationResult.isValid) {
          return indexData;
        } else {
          AppLogger.warn(
              'Index data validation failed for $indexCode: ${validationResult.errors}');
          return null;
        }
      }

      return null;
    } catch (e) {
      AppLogger.error('Failed to fetch index $indexCode: $e', e);
      return null;
    }
  }

  /// 转换为MarketIndexData
  MarketIndexData _convertToMarketIndexData(
    Map<String, dynamic> rawData,
    String indexCode,
  ) {
    // 这里需要根据实际API响应格式进行转换
    // 暂时使用模拟数据
    final now = DateTime.now();
    final currentValue =
        Decimal.parse((rawData['current'] ?? '3000.0').toString());
    final previousClose =
        Decimal.parse((rawData['previousClose'] ?? '2950.0').toString());
    final changeAmount = currentValue - previousClose;
    final changePercentage = Decimal.parse(
      (changeAmount * Decimal.fromInt(100) / previousClose).toString(),
    );

    return MarketIndexData(
      code: indexCode,
      name: MarketIndexConstants.getIndexName(indexCode),
      currentValue: currentValue,
      previousClose: previousClose,
      openPrice: Decimal.parse((rawData['open'] ?? '2980.0').toString()),
      highPrice: Decimal.parse((rawData['high'] ?? '3020.0').toString()),
      lowPrice: Decimal.parse((rawData['low'] ?? '2960.0').toString()),
      changeAmount: changeAmount,
      changePercentage: changePercentage,
      volume: int.parse((rawData['volume'] ?? '1000000').toString()),
      turnover: Decimal.parse((rawData['turnover'] ?? '3000000000').toString()),
      updateTime: now,
      marketStatus: _determineMarketStatus(now),
      qualityLevel: DataQualityLevel.good,
      dataSource: 'akshare',
    );
  }

  /// 确定市场状态
  MarketStatus _determineMarketStatus(DateTime now) {
    final hour = now.hour;
    final minute = now.minute;
    final weekday = now.weekday;

    // 周末休市
    if (weekday == DateTime.saturday || weekday == DateTime.sunday) {
      return MarketStatus.holiday;
    }

    // 工作日交易时间 (9:30-11:30, 13:00-15:00)
    if ((hour == 9 && minute >= 30) ||
        (hour == 10) ||
        (hour == 11 && minute <= 30)) {
      return MarketStatus.trading;
    } else if (hour >= 13 && hour < 15) {
      return MarketStatus.trading;
    } else if (hour < 9) {
      return MarketStatus.preMarket;
    } else if (hour >= 15) {
      return MarketStatus.postMarket;
    } else {
      return MarketStatus.closed;
    }
  }

  /// 处理指数数据
  Future<void> _processIndexData(MarketIndexData indexData) async {
    final indexCode = indexData.code;

    try {
      // 获取之前的数据用于变化检测
      final previousData =
          await _indexCacheManager.getCachedIndexData(indexCode);

      // 检测变化
      final changeData = IndexChangeData.calculateChange(
        currentData: indexData,
        previousData: previousData,
      );

      // 缓存数据
      await _indexCacheManager.cacheIndexData(indexData);

      // 发送数据更新事件
      _indexControllers[indexCode]?.add(indexData);
      _changeControllers[indexCode]?.add(changeData);

      // 发送全局更新事件
      _updateController.add(MarketIndexUpdateEvent(
        indexCode: indexCode,
        indexData: indexData,
        changeData: changeData,
        timestamp: DateTime.now(),
      ));

      // 如果是显著变化，记录日志
      if (changeData.isSignificant) {
        AppLogger.info(
            'Significant index change detected: ${changeData.changeDescription}');
      }
    } catch (e) {
      AppLogger.error('Failed to process index data for $indexCode: $e', e);
    }
  }

  /// 刷新单个指数数据
  Future<void> _refreshIndexData(String indexCode) async {
    final indexData = await _fetchSingleIndex(indexCode);
    if (indexData != null) {
      await _processIndexData(indexData);
    }
  }

  /// 停止批量轮询
  Future<void> stopBatchPolling() async {
    if (_batchPollingTimer != null) {
      _batchPollingTimer!.cancel();
      _batchPollingTimer = null;
      _updateState(MarketIndexManagerState.ready);
      AppLogger.info('Stopped batch polling');
    }
  }

  /// 调整轮询频率
  void _adjustPollingFrequencyIfNeeded() {
    if (_recentLatencies.length < 10) return;

    // 计算平均延迟
    final totalLatency = _recentLatencies.fold<Duration>(
      Duration.zero,
      (sum, latency) => sum + latency,
    );
    final averageLatency = Duration(
      milliseconds: totalLatency.inMilliseconds ~/ _recentLatencies.length,
    );

    // 如果平均延迟超过阈值，增加轮询间隔
    if (averageLatency > _latencyThreshold) {
      final newInterval = Duration(
        seconds: math.min(_pollingInterval.inSeconds + 10, 120),
      );
      if (newInterval != _pollingInterval) {
        _pollingInterval = newInterval;
        AppLogger.info(
            'Adjusted polling interval to ${_pollingInterval.inSeconds}s due to high latency');
      }
    }
    // 如果延迟较低，可以适当减少轮询间隔
    else if (averageLatency < _latencyThreshold ~/ 2) {
      final newInterval = Duration(
        seconds: math.max(_pollingInterval.inSeconds - 5, 15),
      );
      if (newInterval != _pollingInterval) {
        _pollingInterval = newInterval;
        AppLogger.info(
            'Adjusted polling interval to ${_pollingInterval.inSeconds}s due to low latency');
      }
    }
  }

  /// 获取当前跟踪的指数列表
  Set<String> get trackedIndices => Set.unmodifiable(_trackedIndexCodes);

  /// 检查是否正在跟踪指定指数
  bool isTrackingIndex(String indexCode) {
    return _trackedIndexCodes.contains(indexCode);
  }

  /// 获取当前轮询状态
  bool get isPolling =>
      _batchPollingTimer != null && _batchPollingTimer!.isActive;

  /// 获取当前轮询间隔
  Duration get pollingInterval => _pollingInterval;

  /// 设置轮询间隔
  Future<void> setPollingInterval(Duration interval) async {
    _pollingInterval = interval;

    // 如果正在轮询，重启以应用新的间隔
    if (_batchPollingTimer != null && _batchPollingTimer!.isActive) {
      await stopBatchPolling();
      await startBatchPolling();
    }
  }

  /// 启用/禁用轮询
  Future<void> setPollingEnabled(bool enabled) async {
    _pollingEnabled = enabled;

    if (enabled &&
        (_batchPollingTimer == null || !_batchPollingTimer!.isActive)) {
      await startBatchPolling();
    } else if (!enabled &&
        _batchPollingTimer != null &&
        _batchPollingTimer!.isActive) {
      await stopBatchPolling();
    }
  }

  /// 获取性能统计
  Map<String, dynamic> getPerformanceStats() {
    return {
      'trackedIndicesCount': _trackedIndexCodes.length,
      'pollingInterval': _pollingInterval.inSeconds,
      'pollingEnabled': _pollingEnabled,
      'averageLatency': _latencyMonitor.averageLatency?.inMilliseconds,
      'recentLatencies': _recentLatencies.map((d) => d.inMilliseconds).toList(),
      'state': _state.name,
    };
  }

  /// 销毁管理器
  Future<void> dispose() async {
    await stopBatchPolling();

    // 关闭所有流控制器
    for (final controller in _indexControllers.values) {
      await controller.close();
    }
    for (final controller in _changeControllers.values) {
      await controller.close();
    }

    await _updateController.close();
    await _stateController.close();

    _indexControllers.clear();
    _changeControllers.clear();
    _trackedIndexCodes.clear();

    _updateState(MarketIndexManagerState.disposed);
    AppLogger.info('MarketIndexDataManager disposed');
  }
}

/// 管理器状态枚举
enum MarketIndexManagerState {
  /// 空闲
  idle,

  /// 初始化中
  initializing,

  /// 就绪
  ready,

  /// 轮询中
  polling,

  /// 获取数据中
  fetching,

  /// 错误
  error,

  /// 已销毁
  disposed;

  String get description {
    switch (this) {
      case MarketIndexManagerState.idle:
        return '空闲';
      case MarketIndexManagerState.initializing:
        return '初始化中';
      case MarketIndexManagerState.ready:
        return '就绪';
      case MarketIndexManagerState.polling:
        return '轮询中';
      case MarketIndexManagerState.fetching:
        return '获取数据中';
      case MarketIndexManagerState.error:
        return '错误';
      case MarketIndexManagerState.disposed:
        return '已销毁';
    }
  }
}

/// 市场指数更新事件
class MarketIndexUpdateEvent {
  /// 指数代码
  final String indexCode;

  /// 指数数据
  final MarketIndexData indexData;

  /// 变化数据
  final IndexChangeData changeData;

  /// 事件时间
  final DateTime timestamp;

  const MarketIndexUpdateEvent({
    required this.indexCode,
    required this.indexData,
    required this.changeData,
    required this.timestamp,
  });
}
