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
import 'frequency_adjuster.dart';

/// 轮询任务配置
class PollingTask {
  /// 数据类型
  final DataType dataType;

  /// 轮询间隔
  Duration interval;

  /// 是否启用
  bool enabled;

  /// 轮询参数
  final Map<String, dynamic> parameters;

  /// 最大重试次数
  final int maxRetries;

  /// 超时时间
  final Duration timeout;

  /// 最后一次执行时间
  DateTime lastExecutionTime;

  /// 下次执行时间
  DateTime nextExecutionTime;

  /// 执行次数
  int executionCount;

  /// 成功次数
  int successCount;

  /// 失败次数
  int failureCount;

  /// 最后错误信息
  String? lastError;

  /// 任务唯一标识符
  final String id;

  PollingTask({
    required this.dataType,
    required this.interval,
    this.enabled = true,
    this.parameters = const {},
    this.maxRetries = 3,
    this.timeout = const Duration(seconds: 30),
  })  : lastExecutionTime = DateTime.now(),
        nextExecutionTime = DateTime.now().add(interval),
        executionCount = 0,
        successCount = 0,
        failureCount = 0,
        id =
            'polling_${dataType.code}_${DateTime.now().millisecondsSinceEpoch}';

  /// 计算成功率
  double get successRate {
    if (executionCount == 0) return 0.0;
    return successCount / executionCount;
  }

  /// 是否需要执行
  bool get shouldExecute =>
      enabled && DateTime.now().isAfter(nextExecutionTime);

  /// 重置统计信息
  void resetStats() {
    executionCount = 0;
    successCount = 0;
    failureCount = 0;
    lastError = null;
  }

  /// 记录执行成功
  void recordSuccess() {
    lastExecutionTime = DateTime.now();
    nextExecutionTime = lastExecutionTime.add(interval);
    executionCount++;
    successCount++;
    lastError = null;
  }

  /// 记录执行失败
  void recordFailure(String error) {
    lastExecutionTime = DateTime.now();
    nextExecutionTime = lastExecutionTime.add(interval);
    executionCount++;
    failureCount++;
    lastError = error;
  }

  /// 计算下次执行时间 (考虑重试逻辑)
  DateTime calculateNextExecutionTime({bool retry = false}) {
    if (retry && failureCount < maxRetries) {
      // 重试时使用较短间隔
      return DateTime.now()
          .add(Duration(seconds: math.min(30, interval.inSeconds ~/ 4)));
    }
    return DateTime.now().add(interval);
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dataType': dataType.code,
      'interval': interval.inSeconds,
      'enabled': enabled,
      'parameters': parameters,
      'maxRetries': maxRetries,
      'timeout': timeout.inSeconds,
      'lastExecutionTime': lastExecutionTime.toIso8601String(),
      'nextExecutionTime': nextExecutionTime.toIso8601String(),
      'executionCount': executionCount,
      'successCount': successCount,
      'failureCount': failureCount,
      'successRate': successRate,
      'lastError': lastError,
    };
  }
}

/// 轮询管理器状态
enum PollingManagerState {
  idle('空闲'),
  starting('启动中'),
  running('运行中'),
  stopping('停止中'),
  stopped('已停止'),
  error('错误');

  const PollingManagerState(this.description);
  final String description;
}

/// HTTP轮询管理器
///
/// 负责管理多种数据类型的HTTP轮询任务，支持智能频率调整和错误重试机制
class PollingManager {
  /// 单例实例
  static final PollingManager _instance = PollingManager._internal();

  factory PollingManager() => _instance;

  PollingManager._internal() {
    _initialize();
  }

  /// 轮询任务列表
  final Map<String, PollingTask> _tasks = {};

  /// 轮询定时器
  Timer? _schedulerTimer;

  /// Dio客户端
  late final Dio _dio;

  /// 管理器状态
  PollingManagerState _state = PollingManagerState.idle;

  /// 数据流控制器
  final Map<DataType, StreamController<DataItem>> _dataControllers = {};

  /// 状态流控制器
  final StreamController<PollingManagerState> _stateController =
      StreamController<PollingManagerState>.broadcast();

  /// 活跃度跟踪器
  final ActivityTracker _activityTracker = ActivityTracker();

  /// 频率调整器
  final FrequencyAdjuster _frequencyAdjuster = FrequencyAdjuster();

  /// 轮询统计信息
  final Map<DataType, PollingStatistics> _statistics = {};

  /// 初始化管理器
  Future<void> _initialize() async {
    try {
      _updateState(PollingManagerState.starting);

      // 初始化Dio客户端
      _initializeDio();

      // 设置默认轮询任务
      _setupDefaultTasks();

      _updateState(PollingManagerState.idle);
      AppLogger.info('PollingManager initialized successfully');
    } catch (e) {
      _updateState(PollingManagerState.error);
      AppLogger.error('Failed to initialize PollingManager: $e');
      rethrow;
    }
  }

  /// 初始化Dio客户端
  void _initializeDio() {
    _dio = Dio(BaseOptions(
      baseUrl: FundApiClient.baseUrl,
      connectTimeout: FundApiClient.connectTimeout,
      receiveTimeout: FundApiClient.receiveTimeout,
      sendTimeout: FundApiClient.sendTimeout,
      validateStatus: (status) =>
          status != null && status >= 200 && status < 300,
      responseType: ResponseType.plain,
      contentType: 'application/json; charset=utf-8',
    ));

    // 添加拦截器
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        AppLogger.network(options.method, '${options.baseUrl}${options.path}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        AppLogger.debug(
            'Polling response: ${response.statusCode} for ${response.requestOptions.path}');
        handler.next(response);
      },
      onError: (error, handler) {
        AppLogger.warning('Polling error: ${error.message}');
        handler.next(error);
      },
    ));
  }

  /// 设置默认轮询任务
  void _setupDefaultTasks() {
    // 基金净值 - 使用批量轮询策略，30秒间隔 (支持准实时更新)
    addTask(PollingTask(
      dataType: DataType.fundNetValue,
      interval: const Duration(seconds: 30),
      parameters: {
        'batch': true,
        'max_batch_size': 50,
        'strategy': 'batch_fund_nav_polling',
      },
    ));

    // 基金基础信息 - 6小时
    addTask(PollingTask(
      dataType: DataType.fundBasicInfo,
      interval: const Duration(hours: 6),
    ));

    // 市场交易数据 - 5分钟
    addTask(PollingTask(
      dataType: DataType.marketTradingData,
      interval: const Duration(minutes: 5),
    ));

    // 数据质量监控 - 1分钟
    addTask(PollingTask(
      dataType: DataType.dataQualityMetrics,
      interval: const Duration(minutes: 1),
    ));
  }

  /// 获取管理器状态
  PollingManagerState get state => _state;

  /// 状态变化流
  Stream<PollingManagerState> get stateStream => _stateController.stream;

  /// 更新管理器状态
  void _updateState(PollingManagerState newState) {
    if (_state != newState) {
      final oldState = _state;
      _state = newState;
      _stateController.add(newState);
      AppLogger.info(
          'PollingManager state changed: ${oldState.name} → ${newState.name}');
    }
  }

  /// 添加轮询任务
  void addTask(PollingTask task) {
    _tasks[task.id] = task;

    // 初始化数据流控制器
    if (!_dataControllers.containsKey(task.dataType)) {
      _dataControllers[task.dataType] = StreamController<DataItem>.broadcast();
    }

    // 初始化统计信息
    if (!_statistics.containsKey(task.dataType)) {
      _statistics[task.dataType] = PollingStatistics();
    }

    AppLogger.info(
        'Added polling task for ${task.dataType.code} with interval ${task.interval.inSeconds}s');
  }

  /// 移除轮询任务
  void removeTask(String taskId) {
    final task = _tasks.remove(taskId);
    if (task != null) {
      AppLogger.info('Removed polling task for ${task.dataType.code}');
    }
  }

  /// 根据数据类型移除任务
  void removeTasksByDataType(DataType dataType) {
    final tasksToRemove =
        _tasks.values.where((task) => task.dataType == dataType).toList();

    for (final task in tasksToRemove) {
      removeTask(task.id);
    }
  }

  /// 获取指定数据类型的轮询任务
  List<PollingTask> getTasksByDataType(DataType dataType) {
    return _tasks.values.where((task) => task.dataType == dataType).toList();
  }

  /// 获取数据流
  Stream<DataItem>? getDataStream(DataType dataType) {
    return _dataControllers[dataType]?.stream;
  }

  /// 启动轮询管理器
  Future<void> start() async {
    if (_state == PollingManagerState.running) {
      return;
    }

    _updateState(PollingManagerState.starting);

    try {
      // 启动调度器定时器
      _startScheduler();

      _updateState(PollingManagerState.running);
      AppLogger.info('PollingManager started successfully');
    } catch (e) {
      _updateState(PollingManagerState.error);
      AppLogger.error('Failed to start PollingManager: $e');
      rethrow;
    }
  }

  /// 停止轮询管理器
  Future<void> stop() async {
    if (_state == PollingManagerState.stopped) {
      return;
    }

    _updateState(PollingManagerState.stopping);

    try {
      // 停止调度器定时器
      _schedulerTimer?.cancel();
      _schedulerTimer = null;

      _updateState(PollingManagerState.stopped);
      AppLogger.info('PollingManager stopped successfully');
    } catch (e) {
      _updateState(PollingManagerState.error);
      AppLogger.error('Failed to stop PollingManager: $e');
      rethrow;
    }
  }

  /// 启动调度器
  void _startScheduler() {
    _schedulerTimer?.cancel();
    _schedulerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _scheduleTasks();
    });
  }

  /// 调度轮询任务
  Future<void> _scheduleTasks() async {
    final tasksToExecute =
        _tasks.values.where((task) => task.shouldExecute).toList();

    if (tasksToExecute.isEmpty) {
      return;
    }

    // 并行执行任务，但限制并发数
    final semaphore = _Semaphore(5); // 最多同时执行5个任务
    final futures = tasksToExecute.map((task) async {
      await semaphore.acquire();
      try {
        await _executeTask(task);
      } finally {
        semaphore.release();
      }
    });

    await Future.wait(futures);
  }

  /// 执行单个轮询任务
  Future<void> _executeTask(PollingTask task) async {
    final stopwatch = Stopwatch()..start();

    try {
      AppLogger.debug('Executing polling task for ${task.dataType.code}');

      // 检查是否为批量轮询任务
      if (task.parameters['batch'] == true &&
          task.dataType == DataType.fundNetValue) {
        await _executeBatchPollingTask(task, stopwatch);
      } else {
        await _executeRegularPollingTask(task, stopwatch);
      }

      AppLogger.debug(
          'Successfully executed polling task for ${task.dataType.code} in ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      stopwatch.stop();

      // 记录执行失败
      task.recordFailure(e.toString());

      // 更新活跃度跟踪
      _activityTracker.recordActivity(task.dataType, false, stopwatch.elapsed);

      // 更新统计信息
      _updateStatistics(task.dataType, false, stopwatch.elapsed);

      AppLogger.error(
          'Failed to execute polling task for ${task.dataType.code}: $e');

      // 如果失败次数过多，调整频率
      if (task.failureCount >= task.maxRetries) {
        _frequencyAdjuster.adjustFrequencyForFailures(task);
      }
    }
  }

  /// 执行常规轮询任务
  Future<void> _executeRegularPollingTask(
      PollingTask task, Stopwatch stopwatch) async {
    // 执行HTTP请求
    final response = await _dio.get(
      task.dataType.apiEndpoint,
      queryParameters: task.parameters,
    );

    stopwatch.stop();

    // 解析响应数据
    final data = _parseResponse(response, task.dataType);

    // 创建数据项
    final dataItem = DataItem(
      dataType: task.dataType,
      data: data,
      timestamp: DateTime.now(),
      quality: _assessDataQuality(response, stopwatch.elapsed),
      source: DataSource.httpPolling,
      id: 'polling_${task.id}_${DateTime.now().millisecondsSinceEpoch}',
    );

    // 发送到数据流
    _dataControllers[task.dataType]?.add(dataItem);

    // 记录执行成功
    task.recordSuccess();

    // 更新活跃度跟踪
    _activityTracker.recordActivity(task.dataType, true, stopwatch.elapsed);

    // 更新频率调整器
    _frequencyAdjuster.updateDataChange(task.dataType, data);

    // 更新统计信息
    _updateStatistics(task.dataType, true, stopwatch.elapsed);
  }

  /// 执行批量轮询任务
  Future<void> _executeBatchPollingTask(
      PollingTask task, Stopwatch stopwatch) async {
    final maxBatchSize = task.parameters['max_batch_size'] as int? ?? 50;
    final codes = task.parameters['codes'] as List<String>? ?? [];

    if (codes.isEmpty) {
      AppLogger.warning('Batch polling task has no fund codes');
      return;
    }

    // 将基金代码分批
    final batches = <List<String>>[];
    for (int i = 0; i < codes.length; i += maxBatchSize) {
      final batch = codes.skip(i).take(maxBatchSize).toList();
      batches.add(batch);
    }

    AppLogger.debug(
        'Executing batch polling for ${codes.length} funds in ${batches.length} batches');

    final results = <dynamic>[];
    int successCount = 0;
    int errorCount = 0;

    // 并发执行批次，但限制并发数
    final semaphore = _Semaphore(3); // 最多3个并发批次
    final futures = batches.map((batch) async {
      await semaphore.acquire();
      try {
        final result = await _pollSingleBatch(batch, task.parameters);
        if (result['success'] == true) {
          successCount++;
        } else {
          errorCount++;
        }
        return result;
      } finally {
        semaphore.release();
      }
    });

    final batchResults = await Future.wait(futures);

    // 合并结果
    for (final result in batchResults) {
      if (result['funds'] != null) {
        results.addAll(result['funds'] as List<dynamic>);
      }
    }

    stopwatch.stop();

    // 创建批量数据项
    final batchData = {
      'funds': results,
      'batch_count': batches.length,
      'success_count': successCount,
      'error_count': errorCount,
      'total_funds': codes.length,
      'found_funds': results.length,
    };

    final dataItem = DataItem(
      dataType: task.dataType,
      data: batchData,
      timestamp: DateTime.now(),
      quality: _assessBatchDataQuality(batchData),
      source: DataSource.httpPolling,
      id: 'batch_polling_${task.id}_${DateTime.now().millisecondsSinceEpoch}',
    );

    // 发送到数据流
    _dataControllers[task.dataType]?.add(dataItem);

    // 记录执行成功
    task.recordSuccess();

    // 更新活跃度跟踪
    _activityTracker.recordActivity(task.dataType, true, stopwatch.elapsed);

    // 更新频率调整器
    _frequencyAdjuster.updateDataChange(task.dataType, batchData);

    // 更新统计信息
    _updateStatistics(task.dataType, true, stopwatch.elapsed);

    AppLogger.info(
        'Batch polling completed: $successCount/${batches.length} batches successful, ${results.length}/${codes.length} funds retrieved');
  }

  /// 轮询单个批次
  Future<Map<String, dynamic>> _pollSingleBatch(
    List<String> fundCodes,
    Map<String, dynamic> baseParameters,
  ) async {
    try {
      final parameters = Map<String, dynamic>.from(baseParameters);
      parameters['codes'] = fundCodes.join(',');
      parameters.remove('max_batch_size'); // 移除不相关的参数

      final response = await _dio.get(
        '/api/fund/nav/batch', // 使用专门的批量API端点
        queryParameters: parameters,
      );

      final data = _parseResponse(response, DataType.fundNetValue);

      return {
        'success': true,
        'funds': data['funds'] ?? [],
        'batch_codes': fundCodes,
      };
    } catch (e) {
      AppLogger.error('Failed to poll batch ${fundCodes.join(', ')}: $e');
      return {
        'success': false,
        'error': e.toString(),
        'batch_codes': fundCodes,
      };
    }
  }

  /// 评估批量数据质量
  DataQualityLevel _assessBatchDataQuality(Map<String, dynamic> batchData) {
    final totalFunds = batchData['total_funds'] as int? ?? 0;
    final foundFunds = batchData['found_funds'] as int? ?? 0;
    final successCount = batchData['success_count'] as int? ?? 0;
    final batchCount = batchData['batch_count'] as int? ?? 1;

    if (totalFunds == 0) return DataQualityLevel.unknown;

    final successRate = successCount / batchCount;
    final completionRate = foundFunds / totalFunds;

    if (successRate >= 0.9 && completionRate >= 0.9) {
      return DataQualityLevel.excellent;
    } else if (successRate >= 0.7 && completionRate >= 0.7) {
      return DataQualityLevel.good;
    } else if (successRate >= 0.5 && completionRate >= 0.5) {
      return DataQualityLevel.fair;
    } else {
      return DataQualityLevel.poor;
    }
  }

  /// 解析响应数据
  dynamic _parseResponse(Response response, DataType dataType) {
    try {
      if (response.data is String) {
        return jsonDecode(response.data as String);
      }
      return response.data;
    } catch (e) {
      AppLogger.warning('Failed to parse response for ${dataType.code}: $e');
      return response.data; // 返回原始数据
    }
  }

  /// 评估数据质量
  DataQualityLevel _assessDataQuality(Response response, Duration latency) {
    // 基于响应时间和状态码评估数据质量
    final statusCode = response.statusCode ?? 0;
    final latencyMs = latency.inMilliseconds;

    if (statusCode >= 200 && statusCode < 300) {
      if (latencyMs < 1000) {
        return DataQualityLevel.excellent;
      } else if (latencyMs < 3000) {
        return DataQualityLevel.good;
      } else if (latencyMs < 10000) {
        return DataQualityLevel.fair;
      } else {
        return DataQualityLevel.poor;
      }
    } else {
      return DataQualityLevel.unknown;
    }
  }

  /// 更新统计信息
  void _updateStatistics(DataType dataType, bool success, Duration latency) {
    final stats = _statistics[dataType];
    if (stats != null) {
      stats.recordExecution(success, latency);
    }
  }

  /// 获取轮询统计信息
  Map<String, dynamic> getStatistics() {
    return {
      'state': _state.name,
      'totalTasks': _tasks.length,
      'enabledTasks': _tasks.values.where((task) => task.enabled).length,
      'tasks': _tasks.values.map((task) => task.toJson()).toList(),
      'statistics': _statistics.map(
        (key, value) => MapEntry(key.code, value.toJson()),
      ),
      'activityTracker': _activityTracker.getReport(),
      'frequencyAdjuster': _frequencyAdjuster.getConfig(),
    };
  }

  /// 获取指定数据类型的统计信息
  PollingStatistics? getStatisticsForType(DataType dataType) {
    return _statistics[dataType];
  }

  /// 调整任务频率
  void adjustTaskFrequency(String taskId, Duration newInterval) {
    final task = _tasks[taskId];
    if (task != null) {
      task.interval = newInterval;
      AppLogger.info(
          'Adjusted frequency for ${task.dataType.code} to ${newInterval.inSeconds}s');
    }
  }

  /// 启用/禁用任务
  void setTaskEnabled(String taskId, bool enabled) {
    final task = _tasks[taskId];
    if (task != null) {
      task.enabled = enabled;
      AppLogger.info(
          '${enabled ? "Enabled" : "Disabled"} polling task for ${task.dataType.code}');
    }
  }

  /// 释放资源
  void dispose() {
    stop();
    _stateController.close();

    for (final controller in _dataControllers.values) {
      controller.close();
    }
    _dataControllers.clear();
    _tasks.clear();
    _statistics.clear();
  }
}

/// 信号量实现，用于限制并发数
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

/// 轮询统计信息
class PollingStatistics {
  /// 总执行次数
  int totalExecutions = 0;

  /// 成功次数
  int successCount = 0;

  /// 失败次数
  int failureCount = 0;

  /// 总延迟
  int totalLatencyMs = 0;

  /// 最小延迟
  int minLatencyMs = 0;

  /// 最大延迟
  int maxLatencyMs = 0;

  /// 最后执行时间
  DateTime? lastExecutionTime;

  /// 记录执行
  void recordExecution(bool success, Duration latency) {
    totalExecutions++;
    final latencyMs = latency.inMilliseconds;

    totalLatencyMs += latencyMs;
    minLatencyMs =
        minLatencyMs == 0 ? latencyMs : math.min(minLatencyMs, latencyMs);
    maxLatencyMs = math.max(maxLatencyMs, latencyMs);
    lastExecutionTime = DateTime.now();

    if (success) {
      successCount++;
    } else {
      failureCount++;
    }
  }

  /// 获取成功率
  double get successRate {
    if (totalExecutions == 0) return 0.0;
    return successCount / totalExecutions;
  }

  /// 获取平均延迟
  double get averageLatencyMs {
    if (totalExecutions == 0) return 0.0;
    return totalLatencyMs / totalExecutions;
  }

  /// 重置统计信息
  void reset() {
    totalExecutions = 0;
    successCount = 0;
    failureCount = 0;
    totalLatencyMs = 0;
    minLatencyMs = 0;
    maxLatencyMs = 0;
    lastExecutionTime = null;
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'totalExecutions': totalExecutions,
      'successCount': successCount,
      'failureCount': failureCount,
      'successRate': successRate,
      'averageLatencyMs': averageLatencyMs.round(),
      'minLatencyMs': minLatencyMs,
      'maxLatencyMs': maxLatencyMs,
      'lastExecutionTime': lastExecutionTime?.toIso8601String(),
    };
  }
}
