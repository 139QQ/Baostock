import 'dart:async';
import 'package:dio/dio.dart';
import '../fund_api_client.dart';
import '../utils/logger.dart';
import 'hybrid_data_manager.dart';
import 'data_type.dart';
import 'data_fetch_strategy.dart';

/// 基金API适配器
///
/// 在现有FundApiClient和混合数据管理器之间提供桥梁
/// 确保混合数据获取不会与现有的HTTP API调用冲突
class FundApiAdapter {
  /// 单例实例
  static final FundApiAdapter _instance = FundApiAdapter._internal();

  factory FundApiAdapter() => _instance;

  FundApiAdapter._internal() {
    _initialize();
  }

  /// 混合数据管理器引用
  late final HybridDataManager _hybridDataManager;

  /// Dio实例引用（来自FundApiClient）
  late final Dio _dio;

  /// 是否已初始化
  bool _isInitialized = false;

  /// API调用统计
  final Map<String, ApiCallStats> _apiStats = {};

  /// 适配器配置
  late final FundApiAdapterConfig _config;

  /// 初始化适配器
  Future<void> _initialize() async {
    if (_isInitialized) return;

    try {
      AppLogger.info('FundApiAdapter: 初始化基金API适配器');

      // 获取Dio实例
      _dio = FundApiClient.dio;

      // 获取混合数据管理器实例
      _hybridDataManager = HybridDataManager();

      // 初始化配置
      _config = FundApiAdapterConfig.defaultConfig();

      // 初始化API统计
      _initializeApiStats();

      _isInitialized = true;
      AppLogger.info('FundApiAdapter: 初始化完成');
    } catch (e) {
      AppLogger.error('FundApiAdapter: 初始化失败: $e');
      rethrow;
    }
  }

  /// 初始化API统计
  void _initializeApiStats() {
    for (final endpoint in _commonEndpoints) {
      _apiStats[endpoint] = ApiCallStats(endpoint);
    }
  }

  /// 常用端点列表
  static const List<String> _commonEndpoints = [
    '/api/public/fund_open_fund_rank_em',
    '/api/public/fund_etf_spot_em',
    '/api/public/fund_lof_spot_em',
  ];

  /// 执行GET请求（适配器方法）
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? headers,
    bool useHybridCache = false,
    DataType? dataType,
  }) async {
    if (!_isInitialized) {
      await _initialize();
    }

    final startTime = DateTime.now();
    String? error;

    try {
      AppLogger.debug('FundApiAdapter: GET请求', endpoint);

      // 如果启用混合缓存，尝试从混合数据管理器获取数据
      if (useHybridCache && dataType != null) {
        try {
          final cachedData =
              await _hybridDataManager.getCachedData(dataType, endpoint);
          if (cachedData != null) {
            AppLogger.debug('FundApiAdapter: 使用混合缓存数据', endpoint);
            _updateApiStats(
                endpoint, true, DateTime.now().difference(startTime));
            return cachedData.data;
          }
        } catch (e) {
          AppLogger.warn('FundApiAdapter: 混合缓存获取失败，使用API', e);
          // 继续使用API
        }
      }

      // 执行标准API调用
      final response = await _dio.get(
        endpoint,
        options: Options(headers: headers),
      );

      final data = response.data as Map<String, dynamic>;

      // 如果成功获取数据且启用混合缓存，存储到混合数据管理器
      if (useHybridCache && dataType != null && data.isNotEmpty) {
        try {
          final dataItem = DataItem(
            dataType: dataType,
            dataKey: _generateDataKey(endpoint, {}),
            data: data,
            timestamp: DateTime.now(),
            quality: DataQualityLevel.good,
            source: DataSource.http,
            id: '${dataType.code}_${DateTime.now().millisecondsSinceEpoch}',
          );
          await _hybridDataManager.storeData(dataItem);
          AppLogger.debug('FundApiAdapter: 数据已存储到混合缓存', endpoint);
        } catch (e) {
          AppLogger.warn('FundApiAdapter: 混合缓存存储失败', e);
          // 不影响主要功能
        }
      }

      _updateApiStats(endpoint, true, DateTime.now().difference(startTime));
      AppLogger.debug('FundApiAdapter: GET请求成功', endpoint);
      return data;
    } catch (e) {
      error = e.toString();
      _updateApiStats(
          endpoint, false, DateTime.now().difference(startTime), error);

      AppLogger.error('FundApiAdapter: GET请求失败: $endpoint', e);

      // 如果是网络错误且启用混合缓存，尝试从混合数据管理器获取缓存数据
      if (useHybridCache && dataType != null && _isNetworkError(e)) {
        try {
          final cachedData =
              await _hybridDataManager.getCachedData(dataType, 'default');
          if (cachedData != null) {
            AppLogger.info('FundApiAdapter: 网络错误，使用缓存数据', endpoint);
            return cachedData.data;
          }
        } catch (cacheError) {
          AppLogger.warn('FundApiAdapter: 缓存数据获取也失败', cacheError);
        }
      }

      rethrow;
    }
  }

  /// 执行POST请求（适配器方法）
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, String>? headers,
  }) async {
    if (!_isInitialized) {
      await _initialize();
    }

    final startTime = DateTime.now();
    String? error;

    try {
      AppLogger.debug('FundApiAdapter: POST请求', endpoint);

      final response = await _dio.post(
        endpoint,
        data: data,
        options: Options(headers: headers),
      );

      final responseData = response.data as Map<String, dynamic>;

      _updateApiStats(endpoint, true, DateTime.now().difference(startTime));
      AppLogger.debug('FundApiAdapter: POST请求成功', endpoint);
      return responseData;
    } catch (e) {
      error = e.toString();
      _updateApiStats(
          endpoint, false, DateTime.now().difference(startTime), error);

      AppLogger.error('FundApiAdapter: POST请求失败: $endpoint', e);
      rethrow;
    }
  }

  /// 检查是否为网络错误
  bool _isNetworkError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return true;
        default:
          return false;
      }
    }
    return false;
  }

  /// 生成数据键
  String _generateDataKey(String endpoint, Map<String, dynamic> params) {
    final buffer = StringBuffer();
    buffer.write(endpoint);
    if (params.isNotEmpty) {
      final sortedKeys = params.keys.toList()..sort();
      buffer.write('?');
      for (int i = 0; i < sortedKeys.length; i++) {
        if (i > 0) buffer.write('&');
        buffer.write('${sortedKeys[i]}=${params[sortedKeys[i]]}');
      }
    }
    return buffer.toString();
  }

  /// 更新API调用统计
  void _updateApiStats(String endpoint, bool success, Duration duration,
      [String? error]) {
    final stats = _apiStats[endpoint];
    if (stats != null) {
      stats.recordCall(success, duration, error);
    }
  }

  /// 获取API调用统计
  Map<String, ApiCallStats> getApiStats() {
    return Map.unmodifiable(_apiStats);
  }

  /// 清理过期的API统计
  void cleanupApiStats({Duration olderThan = const Duration(hours: 24)}) {
    final cutoff = DateTime.now().subtract(olderThan);

    for (final stats in _apiStats.values) {
      stats.cleanupOldCalls(cutoff);
    }

    AppLogger.debug('FundApiAdapter: API统计清理完成');
  }

  /// 获取适配器健康状态
  Map<String, dynamic> getHealthStatus() {
    return {
      'initialized': _isInitialized,
      'totalEndpoints': _apiStats.length,
      'totalCalls':
          _apiStats.values.fold(0, (sum, stats) => sum + stats.totalCalls),
      'successRate': _calculateOverallSuccessRate(),
      'averageResponseTime': _calculateOverallAverageResponseTime(),
      'recentErrors': _getRecentErrors(),
    };
  }

  /// 计算总体成功率
  double _calculateOverallSuccessRate() {
    int totalCalls = 0;
    int successCalls = 0;

    for (final stats in _apiStats.values) {
      totalCalls += stats.totalCalls;
      successCalls += stats.successCalls;
    }

    return totalCalls > 0 ? successCalls / totalCalls : 0.0;
  }

  /// 计算总体平均响应时间
  Duration _calculateOverallAverageResponseTime() {
    int totalCalls = 0;
    int totalMs = 0;

    for (final stats in _apiStats.values) {
      totalCalls += stats.totalCalls;
      totalMs += stats.totalResponseTimeMs;
    }

    return totalCalls > 0
        ? Duration(milliseconds: totalMs ~/ totalCalls)
        : Duration.zero;
  }

  /// 获取最近的错误
  List<String> _getRecentErrors({int maxErrors = 10}) {
    final allErrors = <String>[];

    for (final stats in _apiStats.values) {
      allErrors.addAll(stats.recentErrors);
    }

    allErrors.sort((a, b) => b.compareTo(a)); // 最新的在前
    return allErrors.take(maxErrors).toList();
  }

  /// 检查API兼容性
  Future<ApiCompatibilityReport> checkApiCompatibility() async {
    final report = ApiCompatibilityReport();

    try {
      // 检查常用端点是否可用
      for (final endpoint in _commonEndpoints) {
        try {
          final startTime = DateTime.now();
          await get(endpoint);
          final duration = DateTime.now().difference(startTime);

          report.addEndpointResult(endpoint, true, duration, null);
        } catch (e) {
          report.addEndpointResult(
              endpoint, false, Duration.zero, e.toString());
        }
      }

      // 检查Dio配置兼容性
      report.checkDioConfiguration(_dio);
    } catch (e) {
      report.overallStatus = 'error';
      report.errorMessage = e.toString();
    }

    return report;
  }

  /// 释放资源
  Future<void> dispose() async {
    _apiStats.clear();
    _isInitialized = false;
    AppLogger.info('FundApiAdapter: 资源已释放');
  }
}

/// API调用统计
class ApiCallStats {
  final String endpoint;
  int totalCalls = 0;
  int successCalls = 0;
  int totalResponseTimeMs = 0;
  final List<ApiCallRecord> _recentCalls = [];
  static const int _maxRecentCalls = 100;

  ApiCallStats(this.endpoint);

  void recordCall(bool success, Duration duration, [String? error]) {
    totalCalls++;
    if (success) {
      successCalls++;
    }
    totalResponseTimeMs += duration.inMilliseconds;

    _recentCalls.add(ApiCallRecord(
      timestamp: DateTime.now(),
      success: success,
      duration: duration,
      error: error,
    ));

    // 保持最近调用记录在限制范围内
    while (_recentCalls.length > _maxRecentCalls) {
      _recentCalls.removeAt(0);
    }
  }

  /// 清理旧的调用记录
  void cleanupOldCalls(DateTime cutoff) {
    _recentCalls.removeWhere((record) => record.timestamp.isBefore(cutoff));
  }

  /// 成功率
  double get successRate => totalCalls > 0 ? successCalls / totalCalls : 0.0;

  /// 平均响应时间
  Duration get averageResponseTime => totalCalls > 0
      ? Duration(milliseconds: totalResponseTimeMs ~/ totalCalls)
      : Duration.zero;

  /// 最近的错误
  List<String> get recentErrors {
    return _recentCalls
        .where((record) => !record.success && record.error != null)
        .map((record) =>
            '[${record.timestamp.toIso8601String()}] ${record.error}')
        .toList();
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'endpoint': endpoint,
      'totalCalls': totalCalls,
      'successCalls': successCalls,
      'successRate': successRate,
      'averageResponseTimeMs': averageResponseTime.inMilliseconds,
      'recentErrorCount': recentErrors.length,
    };
  }
}

/// API调用记录
class ApiCallRecord {
  final DateTime timestamp;
  final bool success;
  final Duration duration;
  final String? error;

  ApiCallRecord({
    required this.timestamp,
    required this.success,
    required this.duration,
    this.error,
  });
}

/// 基金API适配器配置
class FundApiAdapterConfig {
  /// 是否启用混合缓存
  final bool enableHybridCache;

  /// 缓存超时时间
  final Duration cacheTimeout;

  /// 最大重试次数
  final int maxRetries;

  /// 是否启用详细日志
  final bool enableDetailedLogging;

  const FundApiAdapterConfig({
    this.enableHybridCache = true,
    this.cacheTimeout = const Duration(minutes: 5),
    this.maxRetries = 3,
    this.enableDetailedLogging = false,
  });

  /// 创建默认配置
  factory FundApiAdapterConfig.defaultConfig() {
    return const FundApiAdapterConfig();
  }
}

/// API兼容性报告
class ApiCompatibilityReport {
  String overallStatus = 'unknown';
  String? errorMessage;
  final List<EndpointCompatibility> endpointResults = [];
  Map<String, dynamic>? dioConfiguration;

  void addEndpointResult(
      String endpoint, bool success, Duration responseTime, String? error) {
    endpointResults.add(EndpointCompatibility(
      endpoint: endpoint,
      success: success,
      responseTime: responseTime,
      error: error,
    ));
  }

  void checkDioConfiguration(Dio dio) {
    dioConfiguration = {
      'baseUrl': dio.options.baseUrl,
      'connectTimeout': dio.options.connectTimeout?.inMilliseconds,
      'receiveTimeout': dio.options.receiveTimeout?.inMilliseconds,
      'headers': dio.options.headers,
      'interceptorsCount': dio.interceptors.length,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'overallStatus': overallStatus,
      'errorMessage': errorMessage,
      'endpointCount': endpointResults.length,
      'successfulEndpoints': endpointResults.where((e) => e.success).length,
      'endpointResults': endpointResults.map((e) => e.toJson()).toList(),
      'dioConfiguration': dioConfiguration,
    };
  }
}

/// 端点兼容性
class EndpointCompatibility {
  final String endpoint;
  final bool success;
  final Duration responseTime;
  final String? error;

  EndpointCompatibility({
    required this.endpoint,
    required this.success,
    required this.responseTime,
    this.error,
  });

  Map<String, dynamic> toJson() {
    return {
      'endpoint': endpoint,
      'success': success,
      'responseTimeMs': responseTime.inMilliseconds,
      'error': error,
    };
  }
}
