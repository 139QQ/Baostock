import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../di/unified_injection_container.dart';
import '../presentation/bloc/cache_bloc.dart';
import '../../features/fund/domain/entities/fund_ranking.dart';

/// API调用结果
class ApiResult<T> {
  final T? data;
  final String? error;
  final bool isSuccess;
  final int statusCode;
  final Duration responseTime;
  final DateTime timestamp;
  final Map<String, String> headers;

  const ApiResult({
    this.data,
    this.error,
    required this.isSuccess,
    required this.statusCode,
    required this.responseTime,
    required this.timestamp,
    this.headers = const {},
  });

  factory ApiResult.success({
    required T data,
    required int statusCode,
    required Duration responseTime,
    Map<String, String>? headers,
  }) {
    return ApiResult<T>(
      data: data,
      isSuccess: true,
      statusCode: statusCode,
      responseTime: responseTime,
      timestamp: DateTime.now(),
      headers: headers ?? const {},
    );
  }

  factory ApiResult.failure({
    required String error,
    required int statusCode,
    required Duration responseTime,
    Map<String, String>? headers,
  }) {
    return ApiResult<T>(
      error: error,
      isSuccess: false,
      statusCode: statusCode,
      responseTime: responseTime,
      timestamp: DateTime.now(),
      headers: headers ?? const {},
    );
  }

  @override
  String toString() {
    return 'ApiResult{isSuccess: $isSuccess, statusCode: $statusCode, responseTime: ${responseTime.inMilliseconds}ms}';
  }
}

/// API请求配置
class ApiRequestConfig {
  final String url;
  final String method;
  final Map<String, String>? headers;
  final Map<String, dynamic>? body;
  final Duration? timeout;
  final int? maxRetries;
  final Duration? retryDelay;
  final bool enableCache;
  final Duration? cacheExpiration;
  final String? cacheKey;

  const ApiRequestConfig({
    required this.url,
    this.method = 'GET',
    this.headers,
    this.body,
    this.timeout = const Duration(seconds: 30),
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
    this.enableCache = true,
    this.cacheExpiration = const Duration(minutes: 15),
    this.cacheKey,
  });

  ApiRequestConfig copyWith({
    String? url,
    String? method,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    Duration? timeout,
    int? maxRetries,
    Duration? retryDelay,
    bool? enableCache,
    Duration? cacheExpiration,
    String? cacheKey,
  }) {
    return ApiRequestConfig(
      url: url ?? this.url,
      method: method ?? this.method,
      headers: headers ?? this.headers,
      body: body ?? this.body,
      timeout: timeout ?? this.timeout,
      maxRetries: maxRetries ?? this.maxRetries,
      retryDelay: retryDelay ?? this.retryDelay,
      enableCache: enableCache ?? this.enableCache,
      cacheExpiration: cacheExpiration ?? this.cacheExpiration,
      cacheKey: cacheKey ?? this.cacheKey,
    );
  }
}

/// API调用统计
class ApiStatistics {
  final int totalRequests;
  final int successfulRequests;
  final int failedRequests;
  final double averageResponseTime;
  final double cacheHitRate;
  final Map<int, int> statusCodeDistribution;
  final DateTime lastUpdated;

  const ApiStatistics({
    required this.totalRequests,
    required this.successfulRequests,
    required this.failedRequests,
    required this.averageResponseTime,
    required this.cacheHitRate,
    required this.statusCodeDistribution,
    required this.lastUpdated,
  });

  double get successRate {
    if (totalRequests == 0) return 0.0;
    return successfulRequests / totalRequests;
  }
}

/// 优化的API服务
///
/// 提供统一的API调用接口，包含缓存、重试、监控等功能
class OptimizedApiService {
  final http.Client _httpClient;
  final CacheBloc _cacheBloc;
  final Map<String, dynamic> _statistics;
  final StreamController<ApiStatistics> _statisticsController;

  OptimizedApiService({
    http.Client? httpClient,
    CacheBloc? cacheBloc,
  })  : _httpClient = httpClient ?? UnifiedInjectionContainer.httpClient,
        _cacheBloc = cacheBloc ?? UnifiedInjectionContainer.cacheBloc,
        _statistics = <String, dynamic>{},
        _statisticsController = StreamController<ApiStatistics>.broadcast();

  /// 发起API请求
  Future<ApiResult<T>> request<T>(
    ApiRequestConfig config, {
    T Function(dynamic data)? fromJson,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      // 1. 检查缓存
      if (config.enableCache) {
        final cachedResult = await _getCachedData<T>(config);
        if (cachedResult != null) {
          _updateStatistics(true, stopwatch.elapsed, true);
          return cachedResult;
        }
      }

      // 2. 执行HTTP请求
      final result = await _executeHttpRequest<T>(
        config,
        fromJson: fromJson,
        stopwatch: stopwatch,
      );

      // 3. 缓存结果
      if (result.isSuccess && config.enableCache) {
        await _cacheData(config, result);
      }

      // 4. 更新统计
      _updateStatistics(result.isSuccess, stopwatch.elapsed, false);

      return result;
    } catch (e) {
      stopwatch.stop();
      _updateStatistics(false, stopwatch.elapsed, false);

      return ApiResult.failure(
        error: e.toString(),
        statusCode: 0,
        responseTime: stopwatch.elapsed,
      );
    }
  }

  /// 执行HTTP请求
  Future<ApiResult<T>> _executeHttpRequest<T>(
    ApiRequestConfig config, {
    T Function(dynamic data)? fromJson,
    required Stopwatch stopwatch,
  }) async {
    int retryCount = 0;
    dynamic lastError;

    while (retryCount <= (config.maxRetries ?? 3)) {
      try {
        final request = http.Request(
          config.method,
          Uri.parse(config.url),
        );

        // 设置请求头
        final defaultHeaders = {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'Baostock-Flutter/1.0',
        };

        request.headers.addAll(defaultHeaders);
        if (config.headers != null) {
          request.headers.addAll(config.headers!);
        }

        // 设置请求体
        if (config.body != null) {
          request.body = jsonEncode(config.body);
        }

        // 发送请求
        final response = await _httpClient.send(request).timeout(
          config.timeout ?? const Duration(seconds: 30),
        );

        // 读取响应体
        final responseBody = await response.stream.bytesToString();
        stopwatch.stop();

        // 处理响应
        if (response.statusCode >= 200 && response.statusCode < 300) {
          dynamic responseData;

          if (responseBody.isNotEmpty) {
            try {
              responseData = jsonDecode(responseBody);
            } catch (e) {
              debugPrint('JSON解析失败: $e');
              responseData = responseBody;
            }
          }

          final data = fromJson != null ? fromJson(responseData) : responseData;

          return ApiResult.success(
            data: data,
            statusCode: response.statusCode,
            responseTime: stopwatch.elapsed,
            headers: response.headers.cast<String, String>(),
          );
        } else {
          return ApiResult.failure(
            error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
            statusCode: response.statusCode,
            responseTime: stopwatch.elapsed,
            headers: response.headers.cast<String, String>(),
          );
        }
      } catch (e) {
        lastError = e;
        retryCount++;

        if (retryCount <= (config.maxRetries ?? 3)) {
          debugPrint('API请求失败，正在重试 ($retryCount/${config.maxRetries}): $e');
          await Future.delayed(config.retryDelay ?? const Duration(seconds: 1));
        }
      }
    }

    return ApiResult.failure(
      error: '请求失败，已重试 ${config.maxRetries} 次: $lastError',
      statusCode: 0,
      responseTime: stopwatch.elapsed,
    );
  }

  /// 获取缓存数据
  Future<ApiResult<T>?> _getCachedData<T>(ApiRequestConfig config) async {
    try {
      final cacheKey = config.cacheKey ?? _generateCacheKey(config);

      _cacheBloc.add(GetCacheData<String>(
        key: cacheKey,
        type: String,
      ));

      // 等待缓存结果
      await for (final state in _cacheBloc.stream) {
        if (state.status == CacheStatus.dataRetrieved &&
            state.lastOperationKey == cacheKey) {

          final cachedData = state.lastOperationResult;
          if (cachedData != null) {
            try {
              final data = jsonDecode(cachedData);
              return ApiResult.success(
                data: data,
                statusCode: 200,
                responseTime: Duration.zero,
                headers: {'cached': 'true'},
              );
            } catch (e) {
              debugPrint('缓存数据解析失败: $e');
            }
          }
          break;
        } else if (state.status == CacheStatus.error) {
          break;
        }
      }
    } catch (e) {
      debugPrint('获取缓存数据失败: $e');
    }

    return null;
  }

  /// 缓存数据
  Future<void> _cacheData<T>(ApiRequestConfig config, ApiResult<T> result) async {
    try {
      if (result.data != null) {
        final cacheKey = config.cacheKey ?? _generateCacheKey(config);
        final jsonData = jsonEncode(result.data);

        _cacheBloc.add(StoreCacheData<String>(
          key: cacheKey,
          value: jsonData,
          expiration: config.cacheExpiration,
        ));
      }
    } catch (e) {
      debugPrint('缓存数据失败: $e');
    }
  }

  /// 生成缓存键
  String _generateCacheKey(ApiRequestConfig config) {
    final keyParts = [
      config.method,
      config.url,
      jsonEncode(config.body ?? {}),
    ];
    return 'api_cache_${keyParts.join('_').hashCode}';
  }

  /// 更新统计信息
  void _updateStatistics(bool isSuccess, Duration responseTime, bool fromCache) {
    _statistics['totalRequests'] = (_statistics['totalRequests'] ?? 0) + 1;

    if (isSuccess) {
      _statistics['successfulRequests'] = (_statistics['successfulRequests'] ?? 0) + 1;
    } else {
      _statistics['failedRequests'] = (_statistics['failedRequests'] ?? 0) + 1;
    }

    // 更新平均响应时间
    final totalTime = (_statistics['totalResponseTime'] ?? 0) + responseTime.inMilliseconds;
    _statistics['totalResponseTime'] = totalTime;
    final totalRequests = _statistics['totalRequests'] as int;
    _statistics['averageResponseTime'] = totalTime / totalRequests;

    // 更新缓存命中率
    if (fromCache) {
      _statistics['cacheHits'] = (_statistics['cacheHits'] ?? 0) + 1;
    } else {
      _statistics['cacheMisses'] = (_statistics['cacheMisses'] ?? 0) + 1;
    }

    final cacheHits = _statistics['cacheHits'] ?? 0;
    final cacheMisses = _statistics['cacheMisses'] ?? 0;
    final totalCacheRequests = cacheHits + cacheMisses;
    _statistics['cacheHitRate'] = totalCacheRequests > 0 ? cacheHits / totalCacheRequests : 0.0;

    // 发送统计更新
    _statisticsController.add(_getStatistics());
  }

  /// 获取统计信息
  ApiStatistics get _getStatistics {
    return ApiStatistics(
      totalRequests: _statistics['totalRequests'] ?? 0,
      successfulRequests: _statistics['successfulRequests'] ?? 0,
      failedRequests: _statistics['failedRequests'] ?? 0,
      averageResponseTime: _statistics['averageResponseTime'] ?? 0.0,
      cacheHitRate: _statistics['cacheHitRate'] ?? 0.0,
      statusCodeDistribution: _statistics['statusCodeDistribution'] ?? {},
      lastUpdated: DateTime.now(),
    );
  }

  /// 获取统计信息流
  Stream<ApiStatistics> get statisticsStream => _statisticsController.stream;

  /// GET请求
  Future<ApiResult<T>> get<T>(
    String url, {
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
    Duration? timeout,
    bool enableCache = true,
    Duration? cacheExpiration,
  }) {
    return request<T>(
      ApiRequestConfig(
        url: url,
        method: 'GET',
        headers: headers,
        timeout: timeout,
        enableCache: enableCache,
        cacheExpiration: cacheExpiration,
      ),
      fromJson: fromJson,
    );
  }

  /// POST请求
  Future<ApiResult<T>> post<T>(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    T Function(dynamic)? fromJson,
    Duration? timeout,
    bool enableCache = false,
    Duration? cacheExpiration,
  }) {
    return request<T>(
      ApiRequestConfig(
        url: url,
        method: 'POST',
        headers: headers,
        body: body,
        timeout: timeout,
        enableCache: enableCache,
        cacheExpiration: cacheExpiration,
      ),
      fromJson: fromJson,
    );
  }

  /// PUT请求
  Future<ApiResult<T>> put<T>(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    T Function(dynamic)? fromJson,
    Duration? timeout,
    bool enableCache = false,
    Duration? cacheExpiration,
  }) {
    return request<T>(
      ApiRequestConfig(
        url: url,
        method: 'PUT',
        headers: headers,
        body: body,
        timeout: timeout,
        enableCache: enableCache,
        cacheExpiration: cacheExpiration,
      ),
      fromJson: fromJson,
    );
  }

  /// DELETE请求
  Future<ApiResult<T>> delete<T>(
    String url, {
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
    Duration? timeout,
    bool enableCache = false,
  }) {
    return request<T>(
      ApiRequestConfig(
        url: url,
        method: 'DELETE',
        headers: headers,
        timeout: timeout,
        enableCache: enableCache,
      ),
      fromJson: fromJson,
    );
  }

  /// 清理资源
  void dispose() {
    _statisticsController.close();
  }
}