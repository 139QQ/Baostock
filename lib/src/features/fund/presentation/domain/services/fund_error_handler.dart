import 'dart:async';

import '../../../../../core/utils/logger.dart';

/// 基金错误处理工具类
///
/// 统一处理基金相关的错误，提供错误分类、用户友好的错误消息和恢复建议
class FundErrorHandler {
  // 错误类型分类
  static const Map<String, FundErrorType> _errorTypeMap = {
    'SocketException': FundErrorType.networkTimeout,
    'TimeoutException': FundErrorType.networkTimeout,
    'ConnectionException': FundErrorType.networkConnection,
    'HttpException': FundErrorType.networkError,
    'FormatException': FundErrorType.dataParsing,
    'RangeError': FundErrorType.dataValidation,
    'StateError': FundErrorType.stateError,
    'Exception': FundErrorType.unknown,
  };

  // 网络错误关键词
  static const List<String> _networkErrorKeywords = [
    'connection refused',
    'connection timeout',
    'network is unreachable',
    'no internet connection',
    'host not found',
    'socket exception',
    'connection error',
  ];

  // 数据解析错误关键词
  static const List<String> _parsingErrorKeywords = [
    'format exception',
    'type',
    'subtype',
    'json',
    'utf-8',
    'encoding',
    'invalid data',
    'malformed',
  ];

  // 参数错误关键词
  static const List<String> _parameterErrorKeywords = [
    'null',
    'invalid',
    'missing',
    'required',
    'parameter',
    'argument',
  ];

  // 业务逻辑错误关键词
  static const List<String> _businessErrorKeywords = [
    'unauthorized',
    'forbidden',
    'access denied',
    'quota exceeded',
    'rate limit',
    'service unavailable',
    'internal server error',
    'bad gateway',
  ];

  /// 分析错误类型
  static FundErrorType analyzeError(dynamic error) {
    final errorString = error.toString();

    // 首先尝试通过异常类型匹配
    final errorType = error.runtimeType.toString();
    if (_errorTypeMap.containsKey(errorType)) {
      return _errorTypeMap[errorType]!;
    }

    final errorStringLower = errorString.toLowerCase();

    // 网络错误
    if (_isNetworkError(errorStringLower)) {
      return FundErrorType.networkError;
    }

    // 超时错误
    if (_isTimeoutError(errorStringLower)) {
      return FundErrorType.networkTimeout;
    }

    // 连接错误
    if (_isConnectionError(errorStringLower)) {
      return FundErrorType.networkConnection;
    }

    // 数据解析错误
    if (_isParsingError(errorStringLower)) {
      return FundErrorType.dataParsing;
    }

    // 数据验证错误
    if (_isValidationError(errorStringLower)) {
      return FundErrorType.dataValidation;
    }

    // 参数错误
    if (_isParameterError(errorStringLower)) {
      return FundErrorType.parameterError;
    }

    // 业务逻辑错误
    if (_isBusinessError(errorStringLower)) {
      return FundErrorType.businessError;
    }

    // 状态错误
    if (_isStateError(errorStringLower)) {
      return FundErrorType.stateError;
    }

    // 未知错误
    return FundErrorType.unknown;
  }

  /// 创建错误结果
  static FundErrorResult createErrorResult(
    dynamic error, {
    String? operation,
    Map<String, dynamic>? context,
  }) {
    final errorType = analyzeError(error);
    final userMessage = _generateUserFriendlyMessage(error, errorType);
    final technicalMessage = error.toString();
    final recoveryActions = _generateRecoveryActions(errorType, operation);
    final timestamp = DateTime.now();

    AppLogger.error('💥 基金错误处理', technicalMessage, StackTrace.current);

    return FundErrorResult(
      type: errorType,
      userMessage: userMessage,
      technicalMessage: technicalMessage,
      operation: operation,
      context: context,
      recoveryActions: recoveryActions,
      timestamp: timestamp,
      isRetryable: _isRetryableError(errorType),
    );
  }

  /// 创建网络错误结果
  static FundErrorResult createNetworkError(
    dynamic error, {
    String? operation,
    String? url,
    int? statusCode,
    Duration? timeout,
  }) {
    final context = <String, dynamic>{
      'url': url,
      'statusCode': statusCode,
      'timeout': timeout?.inSeconds,
    };

    return createErrorResult(
      error,
      operation: operation ?? '网络请求',
      context: context,
    );
  }

  /// 创建数据解析错误结果
  static FundErrorResult createParsingError(
    dynamic error, {
    String? operation,
    String? dataType,
    dynamic rawData,
  }) {
    final context = <String, dynamic>{
      'dataType': dataType,
      'rawData': rawData?.runtimeType.toString(),
      'rawDataLength': rawData?.toString().length,
    };

    return createErrorResult(
      error,
      operation: operation ?? '数据解析',
      context: context,
    );
  }

  /// 创建业务错误结果
  static FundErrorResult createBusinessError(
    dynamic error, {
    String? operation,
    int? statusCode,
    Map<String, dynamic>? responseData,
  }) {
    final context = <String, dynamic>{
      'statusCode': statusCode,
      'responseData': responseData?.toString(),
    };

    return createErrorResult(
      error,
      operation: operation ?? '业务操作',
      context: context,
    );
  }

  /// 生成用户友好的错误消息
  static String _generateUserFriendlyMessage(
      dynamic error, FundErrorType type) {
    switch (type) {
      case FundErrorType.networkTimeout:
        return '网络连接超时，请检查网络连接后重试';

      case FundErrorType.networkConnection:
        return '网络连接失败，请检查网络设置';

      case FundErrorType.networkError:
        return '网络请求失败，请稍后重试';

      case FundErrorType.dataParsing:
        return '数据格式错误，正在尝试修复...';

      case FundErrorType.dataValidation:
        return '数据验证失败，部分信息可能不准确';

      case FundErrorType.parameterError:
        return '请求参数错误，请重试';

      case FundErrorType.businessError:
        return '服务暂时不可用，请稍后重试';

      case FundErrorType.stateError:
        return '应用状态异常，请重启应用';

      case FundErrorType.unknown:
      default:
        return '操作失败，请重试或联系技术支持';
    }
  }

  /// 生成恢复建议
  static List<String> _generateRecoveryActions(
      FundErrorType type, String? operation) {
    final actions = <String>[];

    switch (type) {
      case FundErrorType.networkTimeout:
        actions.addAll([
          '检查网络连接是否正常',
          '尝试切换到更稳定的网络环境',
          '稍等片刻后重试',
        ]);
        break;

      case FundErrorType.networkConnection:
        actions.addAll([
          '检查设备网络连接',
          '尝试重启路由器',
          '切换WiFi或移动数据',
        ]);
        break;

      case FundErrorType.networkError:
        actions.addAll([
          '稍后重试操作',
          '检查网络稳定性',
          '确认API服务是否可用',
        ]);
        break;

      case FundErrorType.dataParsing:
        actions.addAll([
          '正在尝试自动修复数据格式',
          '如持续失败，请手动检查数据源',
          '联系技术支持协助',
        ]);
        break;

      case FundErrorType.dataValidation:
        actions.addAll([
          '正在使用默认值修复数据',
          '部分信息可能不准确',
          '稍后重试获取完整数据',
        ]);
        break;

      case FundErrorType.parameterError:
        actions.addAll([
          '检查请求参数是否正确',
          '重新填写相关信息',
          '刷新页面重试',
        ]);
        break;

      case FundErrorType.businessError:
        actions.addAll([
          '稍等片刻后重试',
          '检查操作权限',
          '联系管理员确认',
        ]);
        break;

      case FundErrorType.stateError:
        actions.addAll([
          '重启应用',
          '清理应用缓存',
          '如持续失败请联系技术支持',
        ]);
        break;

      default:
        actions.addAll([
          '刷新页面重试',
          '重启应用',
          '联系技术支持',
        ]);
    }

    // 添加操作相关的建议
    if (operation != null) {
      actions.add('重新尝试$operation操作');
    }

    return actions;
  }

  /// 判断是否为网络错误
  static bool _isNetworkError(String errorString) {
    return _networkErrorKeywords
        .any((keyword) => errorString.contains(keyword));
  }

  /// 判断是否为超时错误
  static bool _isTimeoutError(String errorString) {
    return errorString.contains('timeout') ||
        errorString.contains('time out') ||
        errorString.contains('deadline') ||
        errorString.contains('请求超时');
  }

  /// 判断是否为连接错误
  static bool _isConnectionError(String errorString) {
    return errorString.contains('connection') ||
        errorString.contains('连接') ||
        errorString.contains('refused') ||
        errorString.contains('unreachable');
  }

  /// 判断是否为解析错误
  static bool _isParsingError(String errorString) {
    return _parsingErrorKeywords
        .any((keyword) => errorString.contains(keyword));
  }

  /// 判断是否为验证错误
  static bool _isValidationError(String errorString) {
    return errorString.contains('validation') ||
        errorString.contains('invalid') ||
        errorString.contains('constraint');
  }

  /// 判断是否为参数错误
  static bool _isParameterError(String errorString) {
    return _parameterErrorKeywords
        .any((keyword) => errorString.contains(keyword));
  }

  /// 判断是否为业务错误
  static bool _isBusinessError(String errorString) {
    return _businessErrorKeywords
        .any((keyword) => errorString.contains(keyword));
  }

  /// 判断是否为状态错误
  static bool _isStateError(String errorString) {
    return errorString.contains('state') ||
        errorString.contains('mount') ||
        errorString.contains('disposed');
  }

  /// 判断错误是否可重试
  static bool _isRetryableError(FundErrorType type) {
    switch (type) {
      case FundErrorType.networkTimeout:
      case FundErrorType.networkConnection:
      case FundErrorType.networkError:
      case FundErrorType.dataParsing:
      case FundErrorType.dataValidation:
      case FundErrorType.parameterError:
      case FundErrorType.businessError:
        return true;
      case FundErrorType.stateError:
      case FundErrorType.unknown:
      default:
        return false;
    }
  }

  /// 记录错误统计
  static void logErrorStatistics(FundErrorResult error) {
    // 这里可以实现错误统计功能
    // 例如：记录到文件、发送到监控系统等
    AppLogger.info('📊 错误统计', '${error.type.toString()} - ${error.operation}');
  }

  /// 获取错误严重程度
  static ErrorSeverity getErrorSeverity(FundErrorType type) {
    switch (type) {
      case FundErrorType.networkTimeout:
      case FundErrorType.networkConnection:
        return ErrorSeverity.high;
      case FundErrorType.networkError:
      case FundErrorType.dataParsing:
        return ErrorSeverity.medium;
      case FundErrorType.dataValidation:
      case FundErrorType.parameterError:
        return ErrorSeverity.low;
      case FundErrorType.businessError:
      case FundErrorType.stateError:
        return ErrorSeverity.high;
      case FundErrorType.unknown:
      default:
        return ErrorSeverity.medium;
    }
  }
}

/// 基金错误类型枚举
enum FundErrorType {
  networkTimeout, // 网络超时
  networkConnection, // 网络连接
  networkError, // 网络错误
  dataParsing, // 数据解析
  dataValidation, // 数据验证
  parameterError, // 参数错误
  businessError, // 业务错误
  stateError, // 状态错误
  unknown, // 未知错误
}

/// 基金错误结果
class FundErrorResult {
  final FundErrorType type;
  final String userMessage;
  final String technicalMessage;
  final String? operation;
  final Map<String, dynamic>? context;
  final List<String> recoveryActions;
  final DateTime timestamp;
  final bool isRetryable;

  const FundErrorResult({
    required this.type,
    required this.userMessage,
    required this.technicalMessage,
    this.operation,
    this.context,
    required this.recoveryActions,
    required this.timestamp,
    required this.isRetryable,
  });

  /// 是否为关键错误
  bool get isCritical =>
      FundErrorHandler.getErrorSeverity(type) == ErrorSeverity.high;

  /// 获取错误摘要
  String get summary => '$type: $userMessage';

  @override
  String toString() {
    return 'FundErrorResult(type: $type, message: $userMessage, timestamp: $timestamp)';
  }
}

/// 错误严重程度枚举
enum ErrorSeverity {
  low, // 低严重度
  medium, // 中等严重度
  high, // 高严重度
}

const ErrorSeverity low = ErrorSeverity.low;
const ErrorSeverity medium = ErrorSeverity.medium;
const ErrorSeverity high = ErrorSeverity.high;

/// 错误恢复策略
class ErrorRecoveryStrategy {
  static const Duration defaultRetryDelay = Duration(seconds: 2);
  static const int maxRetryAttempts = 3;
  static const Duration exponentialBackoffBase = Duration(seconds: 1);

  /// 计算重试延迟
  static Duration calculateRetryDelay(int attempt) {
    return Duration(
      milliseconds:
          (exponentialBackoffBase.inMilliseconds * (1 << (attempt - 1))).clamp(
        defaultRetryDelay.inMilliseconds,
        const Duration(seconds: 30).inMilliseconds,
      ),
    );
  }

  /// 判断是否应该重试
  static bool shouldRetry(FundErrorResult error, int attempt) {
    return error.isRetryable && attempt < maxRetryAttempts;
  }

  /// 执行重试逻辑
  static Future<T> executeWithRetry<T>(
    Future<T> Function() operation,
    Future<T> Function(dynamic)? onRetry,
    String? operationName,
  ) async {
    int attempt = 0;
    dynamic lastError;

    while (attempt < ErrorRecoveryStrategy.maxRetryAttempts) {
      try {
        AppLogger.info('🔄 尝试执行操作: $operationName (第${attempt + 1}次)');
        return await operation();
      } catch (error) {
        lastError = error;
        attempt++;

        final errorResult = FundErrorHandler.createErrorResult(
          error,
          operation: operationName,
        );

        if (!ErrorRecoveryStrategy.shouldRetry(errorResult, attempt)) {
          AppLogger.error(
              '❌ 重试次数已达上限，停止重试', 'Max retries exceeded', StackTrace.current);
          rethrow;
        }

        final delay = ErrorRecoveryStrategy.calculateRetryDelay(attempt);
        AppLogger.warn(
            '⚠️ 操作失败，${delay.inSeconds}秒后重试: ${errorResult.userMessage}');

        await Future.delayed(delay);

        if (onRetry != null) {
          await onRetry(error);
        }
      }
    }

    AppLogger.error('❌ 重试失败，抛出最后的错误', 'Retry failed', StackTrace.current);
    throw lastError;
  }
}
