import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math' as math;

import 'package:dio/dio.dart';

import '../fund_api_client.dart';
import '../hybrid/data_fetch_strategy.dart';
import '../hybrid/data_type.dart';
import '../utils/logger.dart';
import 'activity_tracker.dart';

/// 批量基金净值轮询策略
///
/// 专门优化用于批量获取基金净值数据的轮询策略
/// 支持智能分批、并发控制、错误恢复和性能监控
class BatchFundNavPollingStrategy extends DataFetchStrategy {
  /// 策略名称
  static const String strategyName = 'batch_fund_nav_polling';

  /// 单次批量请求最大基金数量
  static const int _maxBatchSize = 50;

  /// 并发请求数量限制
  static const int _maxConcurrentRequests = 3;

  /// 请求超时时间
  static const Duration _requestTimeout = Duration(seconds: 45);

  /// 失败重试最大次数
  static const int _maxRetries = 3;

  /// Dio客户端
  late final Dio _dio;

  /// 活跃度跟踪器
  final ActivityTracker _activityTracker = ActivityTracker();

  /// 当前跟踪的基金代码
  final Set<String> _trackedFundCodes = {};

  /// 基金代码分批
  final List<List<String>> _fundBatches = [];

  /// 轮询定时器
  Timer? _pollingTimer;

  /// 轮询间隔
  Duration _pollingInterval = const Duration(seconds: 30);

  /// 是否启用轮询
  bool _isEnabled = false;

  /// 策略状态
  BatchPollingState _state = BatchPollingState.idle;

  /// 性能统计
  final BatchPollingStatistics _statistics = BatchPollingStatistics();

  /// 错误计数器
  final Map<String, int> _errorCounters = {};

  /// 数据流控制器
  final StreamController<DataItem> _dataController =
      StreamController<DataItem>.broadcast();

  /// 状态流控制器
  final StreamController<BatchPollingState> _stateController =
      StreamController<BatchPollingState>.broadcast();

  /// 批量请求信号量
  final _Semaphore _semaphore = _Semaphore(_maxConcurrentRequests);

  /// 创建批量基金净值轮询策略
  BatchFundNavPollingStrategy({
    Duration pollingInterval = const Duration(seconds: 30),
  }) : _pollingInterval = pollingInterval;

  @override
  String get name => strategyName;

  @override
  List<DataType> get supportedDataTypes => [DataType.fundNetValue];

  @override
  int get priority => 80; // 高优先级

  @override

  /// 获取状态流
  /// 获取状态流
  Stream<BatchPollingState> get stateStream => _stateController.stream;

  /// 获取数据流
  Stream<DataItem> get dataStream => _dataController.stream;

  /// 当前是否可用
  @override
  bool isAvailable() {
    return _state == BatchPollingState.ready ||
        _state == BatchPollingState.running;
  }

  /// 获取指定类型的数据流
  @override
  Stream<DataItem> getDataStream(DataType type,
      {Map<String, dynamic>? parameters}) {
    if (type != DataType.fundNetValue) {
      return Stream.empty();
    }
    return _dataController.stream;
  }

  /// 获取策略配置信息
  @override
  Map<String, dynamic> getConfig() {
    return {
      'strategy': name,
      'maxBatchSize': _maxBatchSize,
      'maxConcurrentRequests': _maxConcurrentRequests,
      'requestTimeout': _requestTimeout.inSeconds,
      'maxRetries': _maxRetries,
      'pollingInterval': _pollingInterval.inSeconds,
      'isEnabled': _isEnabled,
      'state': _state.name,
      'trackedFunds': _trackedFundCodes.length,
    };
  }

  /// 获取当前状态
  BatchPollingState get state => _state;

  /// 获取性能统计
  BatchPollingStatistics get statistics => _statistics;

  /// 初始化策略
  Future<void> initialize() async {
    try {
      _updateState(BatchPollingState.initializing);

      // 初始化Dio客户端
      _initializeDio();

      _updateState(BatchPollingState.ready);
      AppLogger.info('BatchFundNavPollingStrategy initialized successfully');
    } catch (e) {
      _updateState(BatchPollingState.error);
      AppLogger.error('Failed to initialize BatchFundNavPollingStrategy: $e');
      rethrow;
    }
  }

  /// 初始化Dio客户端
  void _initializeDio() {
    _dio = Dio(BaseOptions(
      baseUrl: FundApiClient.baseUrl,
      connectTimeout: FundApiClient.connectTimeout,
      receiveTimeout: _requestTimeout,
      sendTimeout: FundApiClient.sendTimeout,
      validateStatus: (status) =>
          status != null && status >= 200 && status < 300,
      responseType: ResponseType.plain,
      contentType: 'application/json; charset=utf-8',
    ));

    // 添加拦截器
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        AppLogger.network(
            'BATCH', '${options.method} ${options.baseUrl}${options.path}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        AppLogger.debug(
            'Batch NAV response: ${response.statusCode} for ${response.requestOptions.path}');
        handler.next(response);
      },
      onError: (error, handler) {
        AppLogger.warning('Batch NAV polling error: ${error.message}');
        handler.next(error);
      },
    ));
  }

  /// 启动策略
  @override
  Future<void> start() async {
    if (_isEnabled) {
      AppLogger.debug('BatchFundNavPollingStrategy already started');
      return;
    }

    try {
      _updateState(BatchPollingState.starting);

      // 启动轮询定时器
      _startPollingTimer();

      _isEnabled = true;
      _updateState(BatchPollingState.running);
      AppLogger.info('BatchFundNavPollingStrategy started');
    } catch (e) {
      _updateState(BatchPollingState.error);
      AppLogger.error('Failed to start BatchFundNavPollingStrategy: $e');
      rethrow;
    }
  }

  /// 停止策略
  @override
  Future<void> stop() async {
    if (!_isEnabled) {
      return;
    }

    try {
      _updateState(BatchPollingState.stopping);

      // 停止轮询定时器
      _pollingTimer?.cancel();
      _pollingTimer = null;

      _isEnabled = false;
      _updateState(BatchPollingState.stopped);
      AppLogger.info('BatchFundNavPollingStrategy stopped');
    } catch (e) {
      _updateState(BatchPollingState.error);
      AppLogger.error('Failed to stop BatchFundNavPollingStrategy: $e');
    }
  }

  /// 更新基金代码列表
  Future<void> updateFundCodes(List<String> fundCodes) async {
    final newCodes = Set<String>.from(fundCodes);
    final oldCodes = Set<String>.from(_trackedFundCodes);

    // 检查是否有变化
    if (newCodes.difference(oldCodes).isEmpty &&
        oldCodes.difference(newCodes).isEmpty) {
      return; // 没有变化
    }

    _trackedFundCodes.clear();
    _trackedFundCodes.addAll(newCodes);

    // 重新分批
    _rebatchFunds();

    AppLogger.info(
        'Updated fund codes: ${_trackedFundCodes.length} funds, ${_fundBatches.length} batches');

    // 如果正在运行，重新启动轮询
    if (_isEnabled) {
      await _restartPolling();
    }
  }

  /// 重新分批基金代码
  void _rebatchFunds() {
    _fundBatches.clear();

    if (_trackedFundCodes.isEmpty) {
      return;
    }

    final fundList = _trackedFundCodes.toList();
    fundList.sort(); // 排序确保一致性

    for (int i = 0; i < fundList.length; i += _maxBatchSize) {
      final batch = fundList.skip(i).take(_maxBatchSize).toList();
      _fundBatches.add(batch);
    }
  }

  /// 启动轮询定时器
  void _startPollingTimer() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      _executeBatchPolling();
    });
  }

  /// 重新启动轮询
  Future<void> _restartPolling() async {
    _pollingTimer?.cancel();
    await Future.delayed(const Duration(seconds: 1));
    _startPollingTimer();
  }

  /// 执行批量轮询
  Future<void> _executeBatchPolling() async {
    if (_fundBatches.isEmpty || _state != BatchPollingState.running) {
      return;
    }

    final stopwatch = Stopwatch()..start();
    _statistics.recordPollingStart();

    try {
      AppLogger.debug(
          'Starting batch polling for ${_fundBatches.length} batches');

      // 并发执行所有批次
      final futures = _fundBatches.map((batch) => _pollSingleBatch(batch));
      final results = await Future.wait(futures);

      stopwatch.stop();

      // 统计结果
      int successCount = 0;
      int errorCount = 0;
      int totalFunds = 0;

      for (final result in results) {
        if (result.success) {
          successCount++;
          totalFunds += result.fundCount!;
        } else {
          errorCount++;
          AppLogger.error('Batch polling failed: ${result.errorMessage}');
        }
      }

      // 更新统计信息
      _statistics.recordPollingComplete(
        success: successCount,
        error: errorCount,
        totalFunds: totalFunds,
        duration: stopwatch.elapsed,
      );

      // 更新活跃度跟踪
      _activityTracker.recordActivity(
          DataType.fundNetValue, true, stopwatch.elapsed);

      AppLogger.info(
          'Batch polling completed: $successCount/${_fundBatches.length} batches, $totalFunds funds in ${stopwatch.elapsedMilliseconds}ms');

      // 动态调整轮询频率
      _adjustPollingFrequency();
    } catch (e) {
      stopwatch.stop();

      _statistics.recordPollingComplete(
        success: 0,
        error: _fundBatches.length,
        totalFunds: 0,
        duration: stopwatch.elapsed,
      );

      _activityTracker.recordActivity(
          DataType.fundNetValue, false, stopwatch.elapsed);

      AppLogger.error('Batch polling error: $e');
    }
  }

  /// 轮询单个批次
  Future<BatchPollingResult> _pollSingleBatch(List<String> fundCodes) async {
    if (fundCodes.isEmpty) {
      return const BatchPollingResult.success(fundCount: 0, data: {});
    }

    await _semaphore.acquire();

    try {
      AppLogger.debug('Polling batch: ${fundCodes.join(', ')}');

      // 构建请求参数
      final queryParams = {
        'codes': fundCodes.join(','),
        'fields': 'nav,nav_date,accumulated_nav,change_rate',
        'batch': 'true',
      };

      // 执行HTTP请求
      final response = await _dio.get(
        '/api/fund/nav/batch',
        queryParameters: queryParams,
      );

      // 解析响应
      final responseData = _parseBatchResponse(response, fundCodes);

      // 处理数据
      await _processBatchData(responseData);

      return BatchPollingResult.success(
        fundCount: fundCodes.length,
        data: responseData,
      );
    } catch (e) {
      AppLogger.error('Failed to poll batch ${fundCodes.join(', ')}: $e');

      // 记录错误
      for (final code in fundCodes) {
        _errorCounters[code] = (_errorCounters[code] ?? 0) + 1;
      }

      return BatchPollingResult.failure(
        errorMessage: e.toString(),
        fundCount: fundCodes.length,
      );
    } finally {
      _semaphore.release();
    }
  }

  /// 解析批量响应
  Map<String, dynamic> _parseBatchResponse(
      Response response, List<String> requestedCodes) {
    try {
      if (response.data is String) {
        final jsonData = jsonDecode(response.data as String);
        return _validateAndCleanBatchData(jsonData, requestedCodes);
      } else {
        return _validateAndCleanBatchData(response.data, requestedCodes);
      }
    } catch (e) {
      AppLogger.warning('Failed to parse batch response: $e');
      return {'funds': <dynamic>[]};
    }
  }

  /// 验证和清理批量数据
  Map<String, dynamic> _validateAndCleanBatchData(
    Map<String, dynamic> data,
    List<String> requestedCodes,
  ) {
    final funds = <dynamic>[];
    final foundCodes = <String>{};

    try {
      final fundList = data['funds'] as List<dynamic>? ?? [];

      for (final fundData in fundList) {
        if (fundData is Map<String, dynamic>) {
          final code = fundData['code'] as String?;
          if (code != null && requestedCodes.contains(code)) {
            funds.add(fundData);
            foundCodes.add(code);
          }
        }
      }

      // 记录缺失的基金代码
      final missingCodes =
          requestedCodes.where((code) => !foundCodes.contains(code));
      if (missingCodes.isNotEmpty) {
        AppLogger.warning('Missing data for funds: ${missingCodes.join(', ')}');
      }

      return {
        'funds': funds,
        'requested_count': requestedCodes.length,
        'found_count': funds.length,
        'missing_codes': missingCodes.toList(),
      };
    } catch (e) {
      AppLogger.error('Error validating batch data: $e');
      return {'funds': <dynamic>[]};
    }
  }

  /// 处理批量数据
  Future<void> _processBatchData(Map<String, dynamic> batchData) async {
    try {
      final funds = batchData['funds'] as List<dynamic>? ?? [];

      // 创建数据项并发送到流
      final dataItem = DataItem(
        dataType: DataType.fundNetValue,
        data: batchData,
        timestamp: DateTime.now(),
        quality: _assessBatchDataQuality(batchData),
        source: DataSource.httpPolling,
        id: 'batch_nav_${DateTime.now().millisecondsSinceEpoch}',
      );

      _dataController.add(dataItem);

      AppLogger.debug('Processed batch data: ${funds.length} funds');
    } catch (e) {
      AppLogger.error('Failed to process batch data: $e');
    }
  }

  /// 评估批量数据质量
  DataQualityLevel _assessBatchDataQuality(Map<String, dynamic> batchData) {
    final requestedCount = batchData['requested_count'] as int? ?? 0;
    final foundCount = batchData['found_count'] as int? ?? 0;

    if (requestedCount == 0) return DataQualityLevel.unknown;

    final completionRate = foundCount / requestedCount;

    if (completionRate >= 0.95) {
      return DataQualityLevel.excellent;
    } else if (completionRate >= 0.80) {
      return DataQualityLevel.good;
    } else if (completionRate >= 0.60) {
      return DataQualityLevel.fair;
    } else {
      return DataQualityLevel.poor;
    }
  }

  /// 动态调整轮询频率
  void _adjustPollingFrequency() {
    final recentStats = _statistics.getRecentStats();
    if (recentStats == null) return;

    final errorRate = recentStats.errorRate;
    final avgLatency = recentStats.averageLatency;

    Duration newInterval = _pollingInterval;

    // 基于错误率调整
    if (errorRate > 0.3) {
      // 错误率过高，增加轮询间隔
      newInterval = Duration(
        seconds: math.min(300, _pollingInterval.inSeconds + 30),
      );
    } else if (errorRate < 0.05 && avgLatency < 5000) {
      // 错误率低且延迟小，可以减少轮询间隔
      newInterval = Duration(
        seconds: math.max(15, _pollingInterval.inSeconds - 5),
      );
    }

    // 基于延迟调整
    if (avgLatency > 30000) {
      // 延迟过高，增加间隔
      newInterval = Duration(
        seconds: math.min(300, newInterval.inSeconds + 15),
      );
    }

    if (newInterval != _pollingInterval) {
      _pollingInterval = newInterval;
      _restartPolling();
      AppLogger.info(
          'Adjusted polling interval to ${newInterval.inSeconds}s based on performance');
    }
  }

  /// 设置轮询间隔
  Future<void> setPollingInterval(Duration interval) async {
    if (interval.inSeconds < 10) {
      AppLogger.warning('Polling interval too short, using minimum 10s');
      interval = const Duration(seconds: 10);
    } else if (interval.inSeconds > 300) {
      AppLogger.warning('Polling interval too long, using maximum 300s');
      interval = const Duration(seconds: 300);
    }

    _pollingInterval = interval;

    if (_isEnabled) {
      await _restartPolling();
    }

    AppLogger.info('Polling interval set to ${interval.inSeconds}s');
  }

  /// 获取错误统计
  Map<String, int> getErrorCounters() {
    return Map.unmodifiable(_errorCounters);
  }

  /// 清理错误计数器
  void clearErrorCounters() {
    _errorCounters.clear();
  }

  /// 更新状态
  void _updateState(BatchPollingState newState) {
    if (_state != newState) {
      final oldState = _state;
      _state = newState;
      _stateController.add(newState);
      AppLogger.debug(
          'BatchFundNavPollingStrategy state: ${oldState.name} → ${newState.name}');
    }
  }

  /// 获取健康状态
  @override
  Future<Map<String, dynamic>> getHealthStatus() async {
    final recentStats = _statistics.getRecentStats();

    return {
      'strategy': name,
      'state': _state.name,
      'enabled': _isEnabled,
      'trackedFunds': _trackedFundCodes.length,
      'batchCount': _fundBatches.length,
      'pollingInterval': _pollingInterval.inSeconds,
      'recentStats': recentStats?.toJson(),
      'errorCounters': _errorCounters,
      'overallHealth': _calculateHealthStatus(recentStats),
    };
  }

  /// 计算健康状态
  double _calculateHealthStatus(PollingStats? recentStats) {
    if (recentStats == null) return 0.5;

    var healthScore = 1.0;

    // 基于错误率
    healthScore -= recentStats.errorRate * 2;

    // 基于成功率
    healthScore += recentStats.successRate * 0.5;

    // 基于延迟
    if (recentStats.averageLatency > 30000) {
      healthScore -= 0.3;
    } else if (recentStats.averageLatency > 10000) {
      healthScore -= 0.1;
    }

    return healthScore.clamp(0.0, 1.0);
  }

  /// 执行数据获取
  @override
  Future<FetchResult> fetchData(
    DataType type, {
    Map<String, dynamic>? parameters,
  }) async {
    if (type != DataType.fundNetValue) {
      return const FetchResult.failure(
          'Unsupported data type for batch NAV polling');
    }

    try {
      // 获取最新的一批数据
      if (_trackedFundCodes.isEmpty) {
        return const FetchResult.failure(
            'No fund codes configured for polling');
      }

      // 触发轮询并等待结果
      final completer = Completer<BatchPollingResult>();
      late StreamSubscription subscription;

      subscription = dataStream.listen(
        (dataItem) {
          subscription.cancel();
          completer.complete(
              const BatchPollingResult.success(fundCount: 0, data: {}));
        },
        onError: (error) {
          subscription.cancel();
          completer.complete(BatchPollingResult.failure(
              errorMessage: error.toString(), fundCount: 0));
        },
      );

      // 执行轮询
      await _executeBatchPolling();

      // 等待结果 (最多等待轮询间隔时间)
      final timeout = _pollingInterval + const Duration(seconds: 10);
      final result = await completer.future.timeout(timeout);

      if (result.success) {
        final dataItem = DataItem(
          dataType: DataType.fundNetValue,
          data: result.data,
          timestamp: DateTime.now(),
          quality: DataQualityLevel.good,
          source: DataSource.httpPolling,
          id: 'fetch_${DateTime.now().millisecondsSinceEpoch}',
        );

        return FetchResult.success(dataItem);
      } else {
        return FetchResult.failure(result.errorMessage ?? 'Unknown error');
      }
    } catch (e) {
      return FetchResult.failure(e.toString());
    }
  }

  /// 释放资源
  Future<void> dispose() async {
    await stop();

    _dataController.close();
    _stateController.close();

    _trackedFundCodes.clear();
    _fundBatches.clear();
    _errorCounters.clear();
    _statistics.reset();

    AppLogger.info('BatchFundNavPollingStrategy disposed');
  }
}

/// 批量轮询状态
enum BatchPollingState {
  idle('空闲'),
  initializing('初始化中'),
  ready('就绪'),
  starting('启动中'),
  running('运行中'),
  stopping('停止中'),
  stopped('已停止'),
  error('错误');

  const BatchPollingState(this.description);
  final String description;
}

/// 批量轮询结果
class BatchPollingResult {
  final bool success;
  final String? errorMessage;
  final int? fundCount;
  final Map<String, dynamic>? data;

  const BatchPollingResult._({
    required this.success,
    this.errorMessage,
    this.fundCount,
    this.data,
  });

  const BatchPollingResult.success({
    required int fundCount,
    required Map<String, dynamic> data,
  }) : this._(
          success: true,
          fundCount: fundCount,
          data: data,
        );

  const BatchPollingResult.failure({
    required String errorMessage,
    required int fundCount,
  }) : this._(
          success: false,
          errorMessage: errorMessage,
          fundCount: fundCount,
        );
}

/// 批量轮询统计
class BatchPollingStatistics {
  int totalPollings = 0;
  int successPollings = 0;
  int errorPollings = 0;
  int totalFunds = 0;
  int totalLatencyMs = 0;
  final Queue<PollingRecord> _recentRecords = Queue<PollingRecord>();

  /// 记录轮询开始
  void recordPollingStart() {
    totalPollings++;
  }

  /// 记录轮询完成
  void recordPollingComplete({
    required int success,
    required int error,
    required int totalFunds,
    required Duration duration,
  }) {
    successPollings += success;
    errorPollings += error;
    this.totalFunds += totalFunds;
    totalLatencyMs += duration.inMilliseconds;

    // 添加到最近记录
    _recentRecords.add(PollingRecord(
      timestamp: DateTime.now(),
      success: success,
      error: error,
      totalFunds: totalFunds,
      duration: duration,
    ));

    // 保持最近20条记录
    while (_recentRecords.length > 20) {
      _recentRecords.removeFirst();
    }
  }

  /// 获取成功率
  double get successRate {
    if (totalPollings == 0) return 0.0;
    return successPollings / totalPollings;
  }

  /// 获取错误率
  double get errorRate {
    if (totalPollings == 0) return 0.0;
    return errorPollings / totalPollings;
  }

  /// 获取平均延迟
  double get averageLatency {
    if (totalPollings == 0) return 0.0;
    return totalLatencyMs / totalPollings;
  }

  /// 获取平均每轮询的基金数量
  double get averageFundsPerPolling {
    if (totalPollings == 0) return 0.0;
    return totalFunds / totalPollings;
  }

  /// 获取最近统计
  PollingStats? getRecentStats() {
    if (_recentRecords.isEmpty) return null;

    final recent = _recentRecords.take(10).toList();
    final success = recent.fold(0, (sum, r) => sum + r.success);
    final error = recent.fold(0, (sum, r) => sum + r.error);
    final totalFunds = recent.fold(0, (sum, r) => sum + r.totalFunds);
    final totalLatency =
        recent.fold(0, (sum, r) => sum + r.duration.inMilliseconds);

    return PollingStats(
      successRate: success / recent.length,
      errorRate: error / recent.length,
      averageLatency: totalLatency / recent.length,
      averageFundsPerPolling: totalFunds / recent.length,
    );
  }

  /// 重置统计
  void reset() {
    totalPollings = 0;
    successPollings = 0;
    errorPollings = 0;
    totalFunds = 0;
    totalLatencyMs = 0;
    _recentRecords.clear();
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'totalPollings': totalPollings,
      'successPollings': successPollings,
      'errorPollings': errorPollings,
      'successRate': successRate,
      'errorRate': errorRate,
      'totalFunds': totalFunds,
      'averageLatency': averageLatency.round(),
      'averageFundsPerPolling': averageFundsPerPolling.round(),
      'recentStats': getRecentStats()?.toJson(),
    };
  }
}

/// 轮询记录
class PollingRecord {
  final DateTime timestamp;
  final int success;
  final int error;
  final int totalFunds;
  final Duration duration;

  const PollingRecord({
    required this.timestamp,
    required this.success,
    required this.error,
    required this.totalFunds,
    required this.duration,
  });
}

/// 轮询统计
class PollingStats {
  final double successRate;
  final double errorRate;
  final double averageLatency;
  final double averageFundsPerPolling;

  const PollingStats({
    required this.successRate,
    required this.errorRate,
    required this.averageLatency,
    required this.averageFundsPerPolling,
  });

  Map<String, dynamic> toJson() {
    return {
      'successRate': successRate,
      'errorRate': errorRate,
      'averageLatency': averageLatency.round(),
      'averageFundsPerPolling': averageFundsPerPolling.round(),
    };
  }
}

/// 简单信号量实现
class _Semaphore {
  final int maxCount;
  int _currentCount;
  final Queue<Completer<void>> _waitQueue = Queue<Completer<void>>();

  _Semaphore(this.maxCount) : _currentCount = maxCount;

  Future<void> acquire() async {
    if (_currentCount > 0) {
      _currentCount--;
      return;
    }

    final completer = Completer<void>();
    _waitQueue.add(completer);
    return completer.future;
  }

  void release() {
    if (_waitQueue.isNotEmpty) {
      final completer = _waitQueue.removeFirst();
      completer.complete();
    } else {
      _currentCount++;
    }
  }
}
