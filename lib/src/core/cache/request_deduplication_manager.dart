import 'dart:async';
import '../utils/logger.dart';

/// 请求去重管理器
///
/// 防止相同请求的重复执行，提升系统性能
/// 支持基于请求参数的智能去重
class RequestDeduplicationManager {
  static final RequestDeduplicationManager _instance =
      RequestDeduplicationManager._internal();
  factory RequestDeduplicationManager() => _instance;
  RequestDeduplicationManager._internal();

  // 存储正在进行的请求
  final Map<String, _PendingRequest> _pendingRequests = {};

  // 请求统计
  final _RequestStats _stats = _RequestStats();

  // 清理定时器
  Timer? _cleanupTimer;

  /// 获取或执行请求
  ///
  /// 如果相同请求正在进行，则等待其完成
  /// 否则执行新请求并缓存结果
  Future<T> getOrExecute<T>(
    String requestKey, {
    required Future<T> Function() executor,
    Duration? timeout,
    bool enableCache = true,
    Duration? cacheExpiration,
  }) async {
    final effectiveKey = _normalizeKey(requestKey);
    // 设置更合理的默认超时时间，并限制最大超时时间
    const defaultTimeout = Duration(seconds: 5);
    const maxTimeout = Duration(seconds: 30);
    final userTimeout = timeout ?? defaultTimeout;
    final effectiveTimeout =
        userTimeout > maxTimeout ? maxTimeout : userTimeout;

    // 检查是否有相同请求正在进行
    if (_pendingRequests.containsKey(effectiveKey)) {
      _stats.recordDeduplication(effectiveKey);
      AppLogger.debug('🔄 请求去重: 等待现有请求完成 [$effectiveKey]');

      try {
        return await _pendingRequests[effectiveKey]!
            .future
            .timeout(effectiveTimeout);
      } on TimeoutException catch (e) {
        AppLogger.warn(
            '⏰ 请求去重等待超时: $effectiveKey (${effectiveTimeout.inSeconds}秒)', e);
        _stats.recordTimeout(effectiveKey);
        // 超时后移除旧请求，继续执行新请求
        _pendingRequests.remove(effectiveKey);
        rethrow;
      } catch (e) {
        AppLogger.warn('⚠️ 请求去重等待失败: $effectiveKey', e);
        // 其他错误也移除旧请求
        _pendingRequests.remove(effectiveKey);
        rethrow;
      }
    }

    // 创建新的请求Completer
    final completer = Completer<T>();
    final pendingRequest = _PendingRequest<T>(
      completer: completer,
      startTime: DateTime.now(),
      enableCache: enableCache,
      cacheExpiration: cacheExpiration,
    );

    _pendingRequests[effectiveKey] = pendingRequest;
    _stats.recordRequest(effectiveKey);

    AppLogger.debug('🚀 执行新请求: [$effectiveKey]');

    try {
      // 执行请求并添加超时警告
      final result = await _executeWithTimeoutWarning<T>(
        executor: executor,
        timeout: effectiveTimeout,
        requestKey: effectiveKey,
      );

      // 缓存结果（如果启用）
      if (enableCache) {
        await _cacheResult(effectiveKey, result, cacheExpiration);
      }

      // 完成请求
      if (!completer.isCompleted) {
        completer.complete(result);
      }

      _stats.recordSuccess(effectiveKey);
      AppLogger.debug(
          '✅ 请求完成: [$effectiveKey] (${pendingRequest.duration.inMilliseconds}ms)');

      return result;
    } catch (e, stackTrace) {
      _stats.recordError(effectiveKey, e);

      // 根据异常类型进行不同的处理
      if (e is TimeoutException) {
        AppLogger.warn(
            '⏰ 请求超时: [$effectiveKey] (${effectiveTimeout.inSeconds}秒)', e);
        _stats.recordTimeout(effectiveKey);
      } else {
        AppLogger.error('❌ 请求失败: [$effectiveKey]', e, stackTrace);
      }

      if (!completer.isCompleted) {
        completer.completeError(e, stackTrace);
      }

      rethrow;
    } finally {
      // 清理待处理请求
      _pendingRequests.remove(effectiveKey);
    }
  }

  /// 检查请求是否正在进行
  bool isRequestPending(String requestKey) {
    final effectiveKey = _normalizeKey(requestKey);
    return _pendingRequests.containsKey(effectiveKey);
  }

  /// 取消指定请求
  Future<bool> cancelRequest(String requestKey) async {
    final effectiveKey = _normalizeKey(requestKey);
    final pendingRequest = _pendingRequests[effectiveKey];

    if (pendingRequest != null && !pendingRequest.completer.isCompleted) {
      pendingRequest.completer.completeError(
        TimeoutException('请求被取消', Duration.zero),
      );
      _pendingRequests.remove(effectiveKey);
      _stats.recordCancellation(effectiveKey);
      AppLogger.debug('🛑 请求已取消: [$effectiveKey]');
      return true;
    }

    return false;
  }

  /// 清理所有待处理请求
  Future<void> cancelAllRequests() async {
    final keys = _pendingRequests.keys.toList();
    for (final key in keys) {
      await cancelRequest(key);
    }
    AppLogger.info('🧹 已清理所有待处理请求');
  }

  /// 获取待处理请求数量
  int get pendingRequestCount => _pendingRequests.length;

  /// 获取请求统计信息
  RequestStats getStats() => _stats.getSnapshot();

  /// 标准化请求键
  String _normalizeKey(String requestKey) {
    // 移除多余空格并转换为小写
    return requestKey.trim().toLowerCase();
  }

  /// 带超时警告的请求执行
  Future<T> _executeWithTimeoutWarning<T>({
    required Future<T> Function() executor,
    required Duration timeout,
    required String requestKey,
  }) async {
    final warningThreshold = Duration(
      milliseconds: (timeout.inMilliseconds * 0.6).round(), // 提前到60%时警告
    );

    Timer? warningTimer;
    Timer? timeoutTimer;
    Timer? forceTimeoutTimer;
    Completer<T>? timeoutCompleter;
    Future<T>? executorFuture;

    try {
      // 设置警告定时器
      warningTimer = Timer(warningThreshold, () {
        final remaining = timeout - warningThreshold;
        AppLogger.warn('⚠️ 请求执行时间过长: [$requestKey] '
            '剩余时间: ${remaining.inSeconds}秒 (已执行${warningThreshold.inSeconds}秒)');
      });

      // 创建带超时控制的Future
      timeoutCompleter = Completer<T>();

      // 执行请求并保存Future引用
      executorFuture = executor();

      // 设置主超时定时器
      timeoutTimer = Timer(timeout, () {
        if (timeoutCompleter != null && !timeoutCompleter.isCompleted) {
          AppLogger.warn('⏰ 请求主超时触发: [$requestKey] (${timeout.inSeconds}秒)');
          timeoutCompleter.completeError(
            TimeoutException('请求执行超时: [$requestKey]', timeout),
            StackTrace.current,
          );
        }
      });

      // 设置强制超时定时器（比主超时稍长）
      final forceTimeout =
          Duration(milliseconds: timeout.inMilliseconds + 2000);
      forceTimeoutTimer = Timer(forceTimeout, () {
        if (timeoutCompleter != null && !timeoutCompleter.isCompleted) {
          AppLogger.error(
              '💥 强制超时触发: [$requestKey] (${forceTimeout.inSeconds}秒)',
              'TimeoutException');
          timeoutCompleter.completeError(
            TimeoutException('请求强制超时: [$requestKey]', forceTimeout),
            StackTrace.current,
          );
        }
      });

      // 处理执行结果
      executorFuture.then((result) {
        if (timeoutCompleter != null && !timeoutCompleter.isCompleted) {
          timeoutCompleter.complete(result);
        }
      }).catchError((error, stackTrace) {
        if (timeoutCompleter != null && !timeoutCompleter.isCompleted) {
          timeoutCompleter.completeError(error, stackTrace);
        }
      });

      return await timeoutCompleter.future;
    } catch (e) {
      // 如果已经创建Completer但未完成，标记为错误
      if (timeoutCompleter != null && !timeoutCompleter.isCompleted) {
        timeoutCompleter.completeError(e);
      }
      rethrow;
    } finally {
      // 清理所有定时器
      warningTimer?.cancel();
      timeoutTimer?.cancel();
      forceTimeoutTimer?.cancel();

      // 确保清理资源
      if (timeoutCompleter != null && !timeoutCompleter.isCompleted) {
        timeoutCompleter.completeError(
          TimeoutException('请求被意外中断: [$requestKey]', timeout),
          StackTrace.current,
        );
      }
    }
  }

  /// 缓存结果（简化实现）
  Future<void> _cacheResult<T>(
      String key, T result, Duration? expiration) async {
    // 这里可以集成到UnifiedHiveCacheManager
    // 目前只做日志记录
    AppLogger.debug(
        '💾 缓存结果: [$key] (过期时间: ${expiration?.inSeconds ?? '永久'}秒)');
  }

  /// 启动清理任务
  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    // 更频繁的清理，每30秒检查一次
    _cleanupTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _cleanupExpiredRequests();
    });
  }

  /// 清理过期请求
  void _cleanupExpiredRequests() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _pendingRequests.entries) {
      final request = entry.value;
      final duration = now.difference(request.startTime);

      // 清理运行超过2分钟的请求，并记录警告
      if (duration > const Duration(minutes: 2)) {
        expiredKeys.add(entry.key);
        AppLogger.warn(
            '🚨 发现长时间运行的请求: [${entry.key}] (运行${duration.inSeconds}秒)');
      }
    }

    for (final key in expiredKeys) {
      final pendingRequest = _pendingRequests[key];
      if (pendingRequest != null && !pendingRequest.completer.isCompleted) {
        // 强制完成长时间运行的请求
        pendingRequest.completer.completeError(
          TimeoutException('请求因运行时间过长被自动清理: [$key]', Duration.zero),
          StackTrace.current,
        );
        _pendingRequests.remove(key);
        _stats.recordCancellation(key);
        AppLogger.warn('🛑 自动清理长时间运行的请求: [$key]');
      }
    }

    if (expiredKeys.isNotEmpty) {
      AppLogger.info('🧹 清理了 ${expiredKeys.length} 个长时间运行的请求');
    }
  }

  /// 初始化
  void initialize() {
    _startCleanupTimer();
    AppLogger.info('🚀 RequestDeduplicationManager 已初始化');
  }

  /// 销毁
  void dispose() {
    _cleanupTimer?.cancel();
    cancelAllRequests();
    AppLogger.info('🔚 RequestDeduplicationManager 已销毁');
  }
}

/// 待处理请求信息
class _PendingRequest<T> {
  final Completer<T> completer;
  final DateTime startTime;
  final bool enableCache;
  final Duration? cacheExpiration;

  _PendingRequest({
    required this.completer,
    required this.startTime,
    required this.enableCache,
    this.cacheExpiration,
  });

  /// 获取请求执行时长
  Duration get duration => DateTime.now().difference(startTime);

  /// 获取Future对象
  Future<T> get future => completer.future;
}

/// 请求统计信息
class _RequestStats {
  int _totalRequests = 0;
  int _successfulRequests = 0;
  int _failedRequests = 0;
  int _duplicateRequests = 0;
  int _cancelledRequests = 0;
  int _timeoutRequests = 0;
  final Map<String, int> _requestCounts = {};
  final List<_RequestRecord> _recentRequests = [];

  void recordRequest(String key) {
    _totalRequests++;
    _requestCounts[key] = (_requestCounts[key] ?? 0) + 1;
    _recentRequests.add(_RequestRecord(key, DateTime.now(), 'start'));
    _trimRecentRequests();
  }

  void recordSuccess(String key) {
    _successfulRequests++;
    _recentRequests.add(_RequestRecord(key, DateTime.now(), 'success'));
    _trimRecentRequests();
  }

  void recordError(String key, dynamic error) {
    _failedRequests++;
    _recentRequests.add(_RequestRecord(key, DateTime.now(), 'error'));
    _trimRecentRequests();
  }

  void recordDeduplication(String key) {
    _duplicateRequests++;
    _recentRequests.add(_RequestRecord(key, DateTime.now(), 'duplicate'));
    _trimRecentRequests();
  }

  void recordCancellation(String key) {
    _cancelledRequests++;
    _recentRequests.add(_RequestRecord(key, DateTime.now(), 'cancelled'));
    _trimRecentRequests();
  }

  void recordTimeout(String key) {
    _timeoutRequests++;
    _recentRequests.add(_RequestRecord(key, DateTime.now(), 'timeout'));
    _trimRecentRequests();
  }

  void _trimRecentRequests() {
    // 只保留最近100条记录
    if (_recentRequests.length > 100) {
      _recentRequests.removeRange(0, _recentRequests.length - 100);
    }
  }

  RequestStats getSnapshot() {
    return RequestStats(
      totalRequests: _totalRequests,
      successfulRequests: _successfulRequests,
      failedRequests: _failedRequests,
      duplicateRequests: _duplicateRequests,
      cancelledRequests: _cancelledRequests,
      timeoutRequests: _timeoutRequests,
      successRate:
          _totalRequests > 0 ? _successfulRequests / _totalRequests : 0.0,
      duplicateRate:
          _totalRequests > 0 ? _duplicateRequests / _totalRequests : 0.0,
      timeoutRate: _totalRequests > 0 ? _timeoutRequests / _totalRequests : 0.0,
      topRequestedKeys: Map.fromEntries(
        _requestCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value))
          ..take(10),
      ),
      recentRequests: List<RequestRecord>.from(_recentRequests),
    );
  }
}

/// 请求记录
class RequestRecord {
  final String key;
  final DateTime timestamp;
  final String status;

  const RequestRecord(this.key, this.timestamp, this.status);
}

/// 内部请求记录（私有使用）
class _RequestRecord extends RequestRecord {
  _RequestRecord(super.key, super.timestamp, super.status);
}

/// 请求统计快照
class RequestStats {
  final int totalRequests;
  final int successfulRequests;
  final int failedRequests;
  final int duplicateRequests;
  final int cancelledRequests;
  final int timeoutRequests;
  final double successRate;
  final double duplicateRate;
  final double timeoutRate;
  final Map<String, int> topRequestedKeys;
  final List<RequestRecord> recentRequests;

  RequestStats({
    required this.totalRequests,
    required this.successfulRequests,
    required this.failedRequests,
    required this.duplicateRequests,
    required this.cancelledRequests,
    required this.timeoutRequests,
    required this.successRate,
    required this.duplicateRate,
    required this.timeoutRate,
    required this.topRequestedKeys,
    required this.recentRequests,
  });

  @override
  String toString() {
    return 'RequestStats('
        'total: $totalRequests, '
        'success: $successfulRequests, '
        'failed: $failedRequests, '
        'duplicate: $duplicateRequests, '
        'cancelled: $cancelledRequests, '
        'timeout: $timeoutRequests, '
        'successRate: ${(successRate * 100).toStringAsFixed(1)}%, '
        'duplicateRate: ${(duplicateRate * 100).toStringAsFixed(1)}%, '
        'timeoutRate: ${(timeoutRate * 100).toStringAsFixed(1)}%'
        ')';
  }
}
