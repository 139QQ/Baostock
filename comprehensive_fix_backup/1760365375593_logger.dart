import 'package:flutter/foundation.dart';

/// 应用日志工具类
/// 提供统一的日志管理，支持多级别日志输出和配置
class AppLogger {
  /// 是否启用信息级别日志（生产环境可关闭）
  static bool enableInfoLogging = kDebugMode;

  /// 是否启用调试级别日志（生产环境可关闭）
  static bool enableDebugLogging = kDebugMode;

  /// 是否启用警告级别日志
  static bool enableWarnLogging = true;

  /// 是否启用错误级别日志（生产环境必须开启）
  static bool enableErrorLogging = true;

  /// 调试级别日志
  /// 仅在调试模式下输出
  static void debug(String message, [dynamic data]) {
    if (enableDebugLogging && kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      // ignore: avoid_print
      print('🐛 DEBUG [$timestamp] $message ${data != null ? '- $data' : ''}');
    }
  }

  /// 信息级别日志
  /// 在调试模式下始终输出，生产环境可配置
  static void info(String message, [dynamic data]) {
    if (enableInfoLogging) {
      final timestamp = DateTime.now().toIso8601String();
      // ignore: avoid_print
      print('ℹ️ INFO [$timestamp] $message ${data != null ? '- $data' : ''}');
    }
  }

  /// 警告级别日志
  /// 在调试和生产环境都输出
  static void warn(String message, [dynamic data]) {
    if (enableWarnLogging) {
      final timestamp = DateTime.now().toIso8601String();
      // ignore: avoid_print
      print('⚠️ WARN [$timestamp] $message ${data != null ? '- $data' : ''}');
    }
  }

  /// 错误级别日志
  /// 在调试和生产环境都输出，生产环境会报告到错误监控服务
  static void error(String message, dynamic error, [StackTrace? stackTrace]) {
    if (enableErrorLogging) {
      final timestamp = DateTime.now().toIso8601String();
      // ignore: avoid_print
      print('❌ ERROR [$timestamp] $message - $error');

      if (stackTrace != null) {
        // ignore: avoid_print
        print('📍 StackTrace: $stackTrace');
      }

      // 生产环境错误报告
      if (!kDebugMode) {
        ErrorReportingService.report(error, stackTrace, message);
      }
    }
  }

  /// 网络请求日志
  /// 专门用于记录HTTP请求和响应
  static void network(
    String method,
    String url, {
    int? statusCode,
    dynamic requestData,
    dynamic responseData,
    int? responseTime,
  }) {
    if (enableDebugLogging && kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      final status = statusCode != null ? '[$statusCode]' : '';
      final time = responseTime != null ? '(${responseTime}ms)' : '';

      // ignore: avoid_print
      print('🌐 NETWORK [$timestamp] $method $url $status $time');

      if (requestData != null) {
        // ignore: avoid_print
        print('📤 Request: $requestData');
      }

      if (responseData != null) {
        // ignore: avoid_print
        print('📥 Response: $responseData');
      }
    }
  }

  /// 数据库操作日志
  /// 专门用于记录数据库查询和操作
  static void database(String operation, String table, [dynamic data]) {
    if (enableDebugLogging && kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      // ignore: avoid_print
      print(
          '💾 DATABASE [$timestamp] $operation on $table ${data != null ? '- $data' : ''}');
    }
  }

  /// 性能监控日志
  /// 专门用于记录性能相关指标
  static void performance(String operation, int durationMs, [String? details]) {
    if (enableDebugLogging && kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      // ignore: avoid_print
      print(
          '⏱️ PERFORMANCE [$timestamp] $operation took ${durationMs}ms ${details != null ? '- $details' : ''}');
    }
  }

  /// UI事件日志
  /// 专门用于记录用户界面交互事件
  static void ui(String event, [String? widget, dynamic data]) {
    if (enableDebugLogging && kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      final widgetInfo = widget != null ? '[$widget] ' : '';
      // ignore: avoid_print
      print(
          '🎨 UI [$timestamp] $widgetInfo$event ${data != null ? '- $data' : ''}');
    }
  }

  /// 业务逻辑日志
  /// 专门用于记录业务逻辑和状态变化
  static void business(String action, [String? context, dynamic data]) {
    if (enableInfoLogging) {
      final timestamp = DateTime.now().toIso8601String();
      final contextInfo = context != null ? '[$context] ' : '';
      // ignore: avoid_print
      print(
          '💼 BUSINESS [$timestamp] $contextInfo$action ${data != null ? '- $data' : ''}');
    }
  }

  /// 设置日志级别
  /// 允许动态调整不同级别日志的开关
  static void setLogLevel({
    bool? debug,
    bool? info,
    bool? warn,
    bool? error,
  }) {
    if (debug != null) enableDebugLogging = debug;
    if (info != null) enableInfoLogging = info;
    if (warn != null) enableWarnLogging = warn;
    if (error != null) enableErrorLogging = error;

    print(
        'Logger configuration updated - debug: $enableDebugLogging, info: $enableInfoLogging, warn: $enableWarnLogging, error: $enableErrorLogging');
  }

  /// 清除日志输出
  /// 在调试模式下清除控制台输出
  static void clear() {
    if (kDebugMode) {
      // ignore: avoid_print
      print('\x1B[2J\x1B[0;0H'); // 清除控制台
    }
  }
}

/// 错误监控服务接口
/// 用于集成第三方错误监控服务（如Sentry、Firebase Crashlytics等）
class ErrorReportingService {
  /// 报告错误到监控服务
  static void report(dynamic error, StackTrace? stackTrace, [String? context]) {
    // TODO: 集成具体的错误监控服务
    // 例如：Sentry.captureException(error, stackTrace: stackTrace);
    // 或者：FirebaseCrashlytics.instance.recordError(error, stackTrace);

    // 临时实现：记录到本地日志
    final timestamp = DateTime.now().toIso8601String();
    // ignore: avoid_print
    print('📤 ERROR REPORT [$timestamp] $error');
    if (stackTrace != null) {
      // ignore: avoid_print
      print('📍 StackTrace: $stackTrace');
    }
    if (context != null) {
      // ignore: avoid_print
      print('📝 Context: $context');
    }
  }

  /// 记录用户上下文信息
  static void setUserContext(String userId, [Map<String, dynamic>? extra]) {
    // TODO: 设置用户上下文到监控服务
    // 例如：Sentry.configureScope((scope) => scope.setUser(User(id: userId)));

    print('User context set - userId: $userId, extra: $extra');
  }

  /// 记录面包屑导航
  static void recordBreadcrumb(String message, [String? category]) {
    // TODO: 记录面包屑到监控服务
    // 例如：Sentry.addBreadcrumb(Breadcrumb(message: message, category: category));

    print('Breadcrumb recorded - message: $message, category: $category');
  }
}
