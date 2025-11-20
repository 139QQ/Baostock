import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';

import '../core/utils/logger.dart';
import 'security/security_middleware.dart';

/// API响应结果封装
class ApiResponse<T> {
  final T? data;
  final String? errorMessage;
  final bool isSuccess;
  final int? statusCode;

  const ApiResponse._({
    this.data,
    this.errorMessage,
    required this.isSuccess,
    this.statusCode,
  });

  factory ApiResponse.success(T data, {int? statusCode}) {
    return ApiResponse._(
      data: data,
      isSuccess: true,
      statusCode: statusCode,
    );
  }

  factory ApiResponse.failure(String errorMessage, {int? statusCode}) {
    return ApiResponse._(
      errorMessage: errorMessage,
      isSuccess: false,
      statusCode: statusCode,
    );
  }

  bool get isFailure => !isSuccess;

  T get dataOrThrow {
    if (isSuccess) {
      return data!;
    } else {
      throw Exception(errorMessage);
    }
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'ApiResponse.success(data: $data, statusCode: $statusCode)';
    } else {
      return 'ApiResponse.failure(errorMessage: $errorMessage, statusCode: $statusCode)';
    }
  }
}

/// 统一API服务 - 简化版本
///
/// 功能特性：
/// 1. 提供统一的HTTP请求接口
/// 2. 支持GET、POST、PUT、DELETE方法
/// 3. 集成安全中间件
/// 4. 统一错误处理和日志记录
class UnifiedApiService {
  static const String _baseUrl = 'http://154.44.25.92:8080';
  static const Duration _defaultTimeout = Duration(seconds: 30);
  static const Duration _connectTimeout = Duration(seconds: 10);
  static const Duration _receiveTimeout = Duration(seconds: 120);
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  // 核心组件
  final Dio _dio = Dio();
  final Map<String, dynamic> _requestStats = {};
  int _requestCount = 0;

  /// 单例模式
  static final UnifiedApiService _instance = UnifiedApiService._internal();
  factory UnifiedApiService() => _instance;
  UnifiedApiService._internal() {
    _initializeDio();
  }

  /// 初始化Dio配置
  void _initializeDio() {
    _dio.options = BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: _connectTimeout,
      receiveTimeout: _receiveTimeout,
      sendTimeout: _defaultTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Accept-Encoding': 'gzip, deflate, br',
        'User-Agent': 'UnifiedApiService/1.0.0',
        'Connection': 'keep-alive',
      },
    );

    // 添加安全中间件
    _dio.interceptors.add(SecurityMiddleware.createInterceptor(
      enableSignatureVerification: true,
      enableRateLimiting: true,
      enableInputValidation: true,
    ));

    // 添加日志拦截器
    _dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
      logPrint: (object) {
        AppLogger.debug('API: $object');
      },
    ));

    AppLogger.info('✅ UnifiedApiService: Dio初始化完成');
  }

  /// GET请求
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _handleRequest<T>(
      () =>
          _dio.get<T>(path, queryParameters: queryParameters, options: options),
      'GET',
      path,
    );
  }

  /// POST请求
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _handleRequest<T>(
      () => _dio.post<T>(path,
          data: data, queryParameters: queryParameters, options: options),
      'POST',
      path,
    );
  }

  /// PUT请求
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _handleRequest<T>(
      () => _dio.put<T>(path,
          data: data, queryParameters: queryParameters, options: options),
      'PUT',
      path,
    );
  }

  /// DELETE请求
  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _handleRequest<T>(
      () => _dio.delete<T>(path,
          data: data, queryParameters: queryParameters, options: options),
      'DELETE',
      path,
    );
  }

  /// 处理HTTP请求
  Future<ApiResponse<T>> _handleRequest<T>(
    Future<Response<T>> Function() requestFunction,
    String method,
    String path,
  ) async {
    final startTime = DateTime.now();
    _requestCount++;

    try {
      AppLogger.debug('🌐 $requestFunction: $method $path');

      final response = await requestFunction();

      final duration = DateTime.now().difference(startTime);
      _updateStats(method, path, response.statusCode!, duration, true);

      AppLogger.info(
          '✅ $method $path - ${response.statusCode!} (${duration.inMilliseconds}ms)');

      return ApiResponse.success(response.data!,
          statusCode: response.statusCode);
    } on DioException catch (e) {
      final duration = DateTime.now().difference(startTime);
      _updateStats(method, path, e.response?.statusCode ?? 0, duration, false);

      String errorMessage = _handleDioException(e);
      AppLogger.error('❌ $method $path - $errorMessage', e);

      return ApiResponse.failure(errorMessage,
          statusCode: e.response?.statusCode);
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      _updateStats(method, path, 0, duration, false);

      final errorMessage = e.toString();
      AppLogger.error('❌ $method $path - 未知错误: $errorMessage', e);

      return ApiResponse.failure(errorMessage);
    }
  }

  /// 处理Dio异常
  String _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return '连接超时';
      case DioExceptionType.sendTimeout:
        return '发送超时';
      case DioExceptionType.receiveTimeout:
        return '接收超时';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode != null) {
          if (statusCode >= 500) {
            return '服务器错误 ($statusCode)';
          } else if (statusCode >= 400) {
            return '客户端错误 ($statusCode)';
          } else {
            return 'HTTP错误 ($statusCode)';
          }
        }
        return '响应错误';
      case DioExceptionType.cancel:
        return '请求被取消';
      case DioExceptionType.connectionError:
        return '连接错误';
      case DioExceptionType.badCertificate:
        return '证书错误';
      case DioExceptionType.unknown:
      default:
        return '未知错误: ${e.message}';
    }
  }

  /// 更新请求统计
  void _updateStats(String method, String path, int statusCode,
      Duration duration, bool success) {
    final key = '$method:$path';
    if (!_requestStats.containsKey(key)) {
      _requestStats[key] = {
        'count': 0,
        'successCount': 0,
        'errorCount': 0,
        'totalDuration': 0,
        'avgDuration': 0.0,
        'lastStatus': statusCode,
        'lastAccess': DateTime.now().toIso8601String(),
      };
    }

    final stats = _requestStats[key] as Map<String, dynamic>;
    stats['count'] = (stats['count'] as int) + 1;
    stats['totalDuration'] =
        (stats['totalDuration'] as int) + duration.inMilliseconds;
    stats['avgDuration'] = stats['totalDuration'] / stats['count'];
    stats['lastStatus'] = statusCode;
    stats['lastAccess'] = DateTime.now().toIso8601String();

    if (success) {
      stats['successCount'] = (stats['successCount'] as int) + 1;
    } else {
      stats['errorCount'] = (stats['errorCount'] as int) + 1;
    }
  }

  /// 获取请求统计信息
  Map<String, dynamic> getRequestStats() {
    final totalStats = {
      'totalRequests': _requestCount,
      'endpoints': _requestStats.length,
      'stats': _requestStats,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // 计算总体成功率
    if (_requestStats.isNotEmpty) {
      int totalSuccess = 0;
      int totalRequests = 0;

      for (final stats in _requestStats.values) {
        totalSuccess += stats['successCount'] as int;
        totalRequests += stats['count'] as int;
      }

      totalStats['successRate'] = totalRequests > 0
          ? (totalSuccess / totalRequests * 100).toStringAsFixed(2) + '%'
          : '0.0%';
    }

    return totalStats;
  }

  /// 清除统计信息
  void clearStats() {
    _requestStats.clear();
    _requestCount = 0;
    AppLogger.info('📊 请求统计信息已清除');
  }

  /// 健康检查
  Future<bool> healthCheck() async {
    try {
      final response = await get<Map<String, dynamic>>(
        '/health',
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      return response.isSuccess;
    } catch (e) {
      AppLogger.error('❌ 健康检查失败', e);
      return false;
    }
  }

  /// 获取服务状态
  Map<String, dynamic> getServiceStatus() {
    return {
      'service': 'UnifiedApiService',
      'baseUrl': _baseUrl,
      'totalRequests': _requestCount,
      'endpointsCount': _requestStats.length,
      'healthCheck': '使用healthCheck()方法检查',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// 清理资源
  void dispose() {
    _dio.close();
    _requestStats.clear();
    AppLogger.info('🔌 UnifiedApiService: 资源清理完成');
  }
}
