import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../domain/entities/multi_dimensional_comparison_criteria.dart';
import '../../../../core/utils/logger.dart';

/// 对比错误类型
enum ComparisonErrorType {
  /// 网络错误
  network,

  /// 数据解析错误
  dataParsing,

  /// API错误
  apiError,

  /// 缓存错误
  cacheError,

  /// 验证错误
  validation,

  /// 超时错误
  timeout,

  /// 未知错误
  unknown,
}

/// 对比错误信息
class ComparisonError {
  final ComparisonErrorType type;
  final String message;
  final String? details;
  final DateTime timestamp;
  final int? statusCode;
  final Map<String, dynamic>? context;

  ComparisonError({
    required this.type,
    required this.message,
    this.details,
    DateTime? timestamp,
    this.statusCode,
    this.context,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return 'ComparisonError{type: $type, message: $message, statusCode: $statusCode}';
  }
}

/// 错误处理策略
enum ErrorHandlingStrategy {
  /// 立即失败
  failFast,

  /// 重试指定次数
  retry,

  /// 使用缓存数据
  useCache,

  /// 降级处理
  fallback,
}

/// 重试配置
class RetryConfig {
  final int maxRetries;
  final Duration initialDelay;
  final Duration maxDelay;
  final double backoffMultiplier;
  final Set<ComparisonErrorType> retryableErrors;

  const RetryConfig({
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.backoffMultiplier = 2.0,
    this.retryableErrors = const {
      ComparisonErrorType.network,
      ComparisonErrorType.timeout,
      ComparisonErrorType.apiError,
    },
  });
}

/// 基金对比错误处理器
///
/// 提供统一的错误处理、重试和降级机制
class ComparisonErrorHandler {
  static const String _tag = 'ComparisonErrorHandler';
  static const RetryConfig _defaultRetryConfig = RetryConfig();

  /// 处理错误并决定处理策略
  static ErrorHandlingStrategy determineErrorHandlingStrategy(
    ComparisonError error, {
    RetryConfig? retryConfig,
  }) {
    final config = retryConfig ?? _defaultRetryConfig;

    // 如果错误类型可重试且未达到最大重试次数
    if (config.retryableErrors.contains(error.type)) {
      return ErrorHandlingStrategy.retry;
    }

    // 根据错误类型决定策略
    switch (error.type) {
      case ComparisonErrorType.network:
      case ComparisonErrorType.timeout:
        return ErrorHandlingStrategy.useCache;
      case ComparisonErrorType.dataParsing:
        return ErrorHandlingStrategy.fallback;
      case ComparisonErrorType.cacheError:
        return ErrorHandlingStrategy.failFast;
      case ComparisonErrorType.validation:
        return ErrorHandlingStrategy.failFast;
      case ComparisonErrorType.apiError:
        return error.statusCode != null && error.statusCode! >= 500
            ? ErrorHandlingStrategy.retry
            : ErrorHandlingStrategy.fallback;
      case ComparisonErrorType.unknown:
        return ErrorHandlingStrategy.useCache;
    }
  }

  /// 执行带错误处理的操作
  static Future<T> executeWithErrorHandling<T>(
    Future<T> Function() operation,
    T? fallbackValue, {
    MultiDimensionalComparisonCriteria? criteria,
    RetryConfig? retryConfig,
    void Function(ComparisonError)? onError,
    void Function(String)? onRetry,
    bool enableLogging = true,
  }) async {
    final config = retryConfig ?? _defaultRetryConfig;
    int attemptCount = 0;
    ComparisonError? lastError;

    while (attemptCount <= config.maxRetries) {
      try {
        if (enableLogging && attemptCount > 0) {
          AppLogger.info(_tag, '重试操作，第 ${attemptCount + 1} 次尝试');
        }

        final result = await operation();

        if (attemptCount > 0 && enableLogging) {
          AppLogger.info(_tag, '操作在第 ${attemptCount + 1} 次尝试后成功');
        }

        return result;
      } catch (e) {
        attemptCount++;
        lastError = _convertToComparisonError(e, criteria);

        if (enableLogging) {
          AppLogger.warn(
            '$_tag: 操作失败 (尝试 $attemptCount/${config.maxRetries + 1}): ${lastError.message}',
            lastError,
          );
        }

        // 调用错误回调
        onError?.call(lastError);

        // 如果达到最大重试次数，停止重试
        if (attemptCount > config.maxRetries) {
          break;
        }

        // 调用重试回调
        onRetry?.call(
            '第 $attemptCount 次重试，延迟 ${_getRetryDelay(attemptCount - 1, config).inSeconds} 秒');

        // 等待重试延迟
        await Future.delayed(_getRetryDelay(attemptCount - 1, config));
      }
    }

    // 所有重试都失败，尝试降级处理
    if (fallbackValue != null) {
      if (enableLogging) {
        AppLogger.warn(_tag, '所有重试失败，使用降级值');
      }
      return fallbackValue;
    }

    // 抛出最后的错误
    if (enableLogging) {
      AppLogger.error('$_tag: 操作最终失败', lastError ?? Exception('未知错误'));
    }
    throw lastError ?? Exception('操作失败，未知错误');
  }

  /// 执行带超时的操作
  static Future<T> executeWithTimeout<T>(
    Future<T> Function() operation,
    Duration timeout, {
    T? fallbackValue,
    String? timeoutMessage,
  }) async {
    try {
      return await operation().timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException(
            timeoutMessage ?? '操作超时 (${timeout.inSeconds}秒)',
            timeout,
          );
        },
      );
    } on TimeoutException catch (e) {
      final error = ComparisonError(
        type: ComparisonErrorType.timeout,
        message: e.message ?? '操作超时',
        details: '超时时间: ${e.duration}',
      );

      if (fallbackValue != null) {
        AppLogger.warn(_tag, '操作超时，使用降级值: ${error.message}');
        return fallbackValue;
      }

      throw error;
    }
  }

  /// 验证输入参数
  static ComparisonError? validateInput(
    MultiDimensionalComparisonCriteria criteria,
  ) {
    final validationError = criteria.getValidationError();
    if (validationError != null) {
      return ComparisonError(
        type: ComparisonErrorType.validation,
        message: validationError,
        context: {
          'fundCodes': criteria.fundCodes,
          'periods': criteria.periods.map((p) => p.name).toList(),
        },
      );
    }
    return null;
  }

  /// 解析API错误响应
  static ComparisonError parseApiError(
    dynamic response,
    int? statusCode,
  ) {
    String message = 'API请求失败';
    String? details;

    try {
      if (response is Map<String, dynamic>) {
        message = response['message'] ?? response['error'] ?? message;
        details = response['details']?.toString();
      } else if (response is String) {
        message = response;
      }
    } catch (e) {
      AppLogger.warn(_tag, '解析API错误响应失败: $e');
    }

    ComparisonErrorType errorType;
    if (statusCode != null) {
      if (statusCode >= 500) {
        errorType = ComparisonErrorType.apiError;
      } else if (statusCode == 401 || statusCode == 403) {
        errorType = ComparisonErrorType.apiError;
      } else if (statusCode == 404) {
        errorType = ComparisonErrorType.apiError;
      } else if (statusCode >= 400) {
        errorType = ComparisonErrorType.validation;
      } else {
        errorType = ComparisonErrorType.unknown;
      }
    } else {
      errorType = ComparisonErrorType.apiError;
    }

    return ComparisonError(
      type: errorType,
      message: message,
      details: details,
      statusCode: statusCode,
    );
  }

  /// 获取用户友好的错误消息
  static String getUserFriendlyMessage(ComparisonError error) {
    switch (error.type) {
      case ComparisonErrorType.network:
        return '网络连接异常，请检查网络设置后重试';
      case ComparisonErrorType.timeout:
        return '请求超时，请稍后重试';
      case ComparisonErrorType.apiError:
        if (error.statusCode == 401) {
          return '身份验证失败，请重新登录';
        } else if (error.statusCode == 403) {
          return '权限不足，无法访问此功能';
        } else if (error.statusCode == 404) {
          return '请求的资源不存在';
        } else if (error.statusCode != null && error.statusCode! >= 500) {
          return '服务器暂时不可用，请稍后重试';
        }
        return '服务暂时异常，请稍后重试';
      case ComparisonErrorType.dataParsing:
        return '数据解析失败，请尝试刷新页面';
      case ComparisonErrorType.cacheError:
        return '缓存数据异常，正在重新获取';
      case ComparisonErrorType.validation:
        return error.message;
      case ComparisonErrorType.unknown:
        return '发生未知错误，请稍后重试';
    }
  }

  /// 将异常转换为ComparisonError
  static ComparisonError _convertToComparisonError(
    dynamic exception,
    MultiDimensionalComparisonCriteria? criteria,
  ) {
    if (exception is ComparisonError) {
      return exception;
    }

    String message = '未知错误';
    ComparisonErrorType type = ComparisonErrorType.unknown;
    int? statusCode;

    if (exception is TimeoutException) {
      type = ComparisonErrorType.timeout;
      message = '操作超时';
    } else if (exception is SocketException) {
      type = ComparisonErrorType.network;
      message = '网络连接异常';
    } else if (exception is FormatException) {
      type = ComparisonErrorType.dataParsing;
      message = '数据格式错误';
    } else if (exception is Exception) {
      message = exception.toString();

      // 尝试从错误消息中提取HTTP状态码
      final statusCodeMatch = RegExp(r'HTTP\s+(\d+)').firstMatch(message);
      if (statusCodeMatch != null) {
        statusCode = int.tryParse(statusCodeMatch.group(1) ?? '');
        if (statusCode != null) {
          type = ComparisonErrorType.apiError;
        }
      }
    }

    return ComparisonError(
      type: type,
      message: message,
      details: exception.toString(),
      statusCode: statusCode,
      context: criteria != null
          ? {
              'fundCodes': criteria.fundCodes,
              'periods': criteria.periods.map((p) => p.name).toList(),
            }
          : null,
    );
  }

  /// 计算重试延迟（指数退避）
  static Duration _getRetryDelay(int attempt, RetryConfig config) {
    final delay = config.initialDelay * pow(config.backoffMultiplier, attempt);

    return Duration(
        milliseconds: min(
      delay.inMilliseconds,
      config.maxDelay.inMilliseconds,
    ).toInt());
  }

  /// 记录错误统计
  static void recordErrorStatistics(ComparisonError error) {
    // 这里可以实现错误统计逻辑
    // 例如：发送到分析服务、本地记录等
    if (kDebugMode) {
      AppLogger.debug(
          _tag, 'Error statistics: ${error.type} - ${error.message}');
    }
  }
}
