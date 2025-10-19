import 'dart:io';
import 'package:flutter/foundation.dart';

import 'logger.dart';

/// 测试和优化日志配置
///
/// 提供专门的日志配置用于测试和生产环境优化
/// 包含结构化日志、性能监控、错误追踪等功能
class TestLoggerConfig {
  static const String _logFileName = 'fund_ranking_test.log';
  static const int _maxLogFileSize = 10 * 1024 * 1024; // 10MB
  static const int _maxLogFiles = 5;

  static TestLoggerConfig? _instance;
  static TestLoggerConfig get instance =>
      _instance ??= TestLoggerConfig._internal();
  TestLoggerConfig._internal();

  bool _isInitialized = false;
  late File _logFile;
  final List<String> _logBuffer = [];
  Timer? _flushTimer;

  /// 初始化测试日志配置
  Future<void> initialize({
    LogLevel level = LogLevel.debug,
    bool enableConsoleOutput = true,
    bool enableFileOutput = true,
    bool enableStructuredLogging = true,
    bool enablePerformanceMonitoring = true,
  }) async {
    if (_isInitialized) return;

    try {
      // 配置基础日志器
      await AppLogger.initialize(
        level: level,
        enableConsoleOutput: enableConsoleOutput,
        enableFileOutput: false, // 我们自己管理文件输出
      );

      if (enableFileOutput) {
        await _initializeFileLogging();
      }

      // 设置结构化日志
      if (enableStructuredLogging) {
        _setupStructuredLogging();
      }

      // 设置性能监控
      if (enablePerformanceMonitoring) {
        _setupPerformanceMonitoring();
      }

      // 启动定时刷新
      _startPeriodicFlush();

      _isInitialized = true;

      AppLogger.info('📋 测试日志配置初始化完成', {
        'level': level.toString(),
        'console': enableConsoleOutput,
        'file': enableFileOutput,
        'structured': enableStructuredLogging,
        'performance': enablePerformanceMonitoring,
      });
    } catch (e) {
      debugPrint('❌ 测试日志配置初始化失败: $e');
      // 降级到基础配置
      await AppLogger.initialize(level: level);
      _isInitialized = true;
    }
  }

  /// 初始化文件日志
  Future<void> _initializeFileLogging() async {
    try {
      final logDir = Directory('logs');
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      _logFile = File('${logDir.path}/$_logFileName');

      // 检查并轮转日志文件
      await _rotateLogFilesIfNeeded();

      AppLogger.info('📁 文件日志初始化成功: ${_logFile.path}');
    } catch (e) {
      AppLogger.error('❌ 文件日志初始化失败', e.toString());
    }
  }

  /// 设置结构化日志
  void _setupStructuredLogging() {
    // 为关键操作添加结构化日志
    AppLogger.addCustomHandler('structured',
        (level, message, context, error, stackTrace) {
      final structuredLog = {
        'timestamp': DateTime.now().toIso8601String(),
        'level': level.toString(),
        'message': message,
        'context': context,
        'error': error?.toString(),
        'stackTrace': stackTrace?.toString(),
        'buildMode': kDebugMode ? 'debug' : 'release',
        'platform': Platform.operatingSystem,
      };

      _addToBuffer(_formatStructuredLog(structuredLog));
    });
  }

  /// 设置性能监控
  void _setupPerformanceMonitoring() {
    AppLogger.addCustomHandler('performance',
        (level, message, context, error, stackTrace) {
      if (level == LogLevel.debug &&
          message.contains('耗时') &&
          context != null) {
        final performanceData = {
          'timestamp': DateTime.now().toIso8601String(),
          'operation': context['operation'] ?? 'unknown',
          'duration': context['duration'] ?? 0,
          'status': context['status'] ?? 'completed',
          'details': context,
        };

        _addToBuffer(_formatPerformanceLog(performanceData));
      }
    });
  }

  /// 添加到缓冲区
  void _addToBuffer(String logMessage) {
    _logBuffer.add(logMessage);

    // 如果缓冲区过大，立即刷新
    if (_logBuffer.length > 100) {
      _flushBuffer();
    }
  }

  /// 启动定时刷新
  void _startPeriodicFlush() {
    _flushTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _flushBuffer();
    });
  }

  /// 刷新缓冲区到文件
  void _flushBuffer() {
    if (_logBuffer.isEmpty) return;

    try {
      if (!_logFile.existsSync()) {
        _logFile.createSync(recursive: true);
      }

      final content = _logBuffer.join('\n') + '\n';
      _logFile.writeAsStringSync(content, mode: FileMode.append);
      _logBuffer.clear();
    } catch (e) {
      debugPrint('❌ 日志缓冲区刷新失败: $e');
    }
  }

  /// 格式化结构化日志
  String _formatStructuredLog(Map<String, dynamic> log) {
    return 'STRUCTURED: ${log.entries.map((e) => '${e.key}=${e.value}').join(' ')}';
  }

  /// 格式化性能日志
  String _formatPerformanceLog(Map<String, dynamic> log) {
    return 'PERFORMANCE: [${log['operation']}] ${log['duration']}ms (${log['status']})';
  }

  /// 检查并轮转日志文件
  Future<void> _rotateLogFilesIfNeeded() async {
    try {
      if (!_logFile.existsSync()) return;

      final fileSize = await _logFile.length();
      if (fileSize < _maxLogFileSize) return;

      AppLogger.info('🔄 开始轮转日志文件');

      // 删除最旧的日志文件
      for (int i = _maxLogFiles - 1; i >= 1; i--) {
        final oldFile = File('${_logFile.path}.$i');
        if (oldFile.existsSync()) {
          await oldFile.delete();
        }
      }

      // 重命名现有日志文件
      for (int i = _maxLogFiles - 1; i >= 1; i--) {
        final currentFile =
            i == 1 ? _logFile : File('${_logFile.path}.${i - 1}');
        final newFile = File('${_logFile.path}.$i');

        if (currentFile.existsSync()) {
          await currentFile.rename(newFile.path);
        }
      }

      AppLogger.info('✅ 日志文件轮转完成');
    } catch (e) {
      AppLogger.error('❌ 日志文件轮转失败', e.toString());
    }
  }

  /// 记录测试开始
  void logTestStart(String testName, {Map<String, dynamic>? parameters}) {
    final context = <String, dynamic>{
      'testName': testName,
      'phase': 'start',
      'timestamp': DateTime.now().toIso8601String(),
      if (parameters != null) ...parameters,
    };

    AppLogger.info('🧪 测试开始: $testName', context);
  }

  /// 记录测试完成
  void logTestComplete(
    String testName, {
    bool success = true,
    Duration? duration,
    Map<String, dynamic>? results,
    String? error,
  }) {
    final context = <String, dynamic>{
      'testName': testName,
      'phase': 'complete',
      'success': success,
      'timestamp': DateTime.now().toIso8601String(),
      if (duration != null) 'duration': duration.inMilliseconds,
      if (results != null) ...results,
      if (error != null) 'error': error,
    };

    final message = success
        ? '✅ 测试完成: $testName (${duration?.inMilliseconds ?? 0}ms)'
        : '❌ 测试失败: $testName - $error';

    if (success) {
      AppLogger.info(message, context);
    } else {
      AppLogger.error(message, error);
    }
  }

  /// 记录性能指标
  void logPerformanceMetric(
    String operation,
    Duration duration, {
    String status = 'completed',
    Map<String, dynamic>? details,
  }) {
    final context = <String, dynamic>{
      'operation': operation,
      'duration': duration.inMilliseconds,
      'status': status,
      'timestamp': DateTime.now().toIso8601String(),
      if (details != null) ...details,
    };

    AppLogger.debug(
        '📊 性能指标: $operation ${duration.inMilliseconds}ms', context);
  }

  /// 记录网络请求
  void logNetworkRequest(
    String method,
    String url, {
    int? statusCode,
    Duration? duration,
    Map<String, dynamic>? requestHeaders,
    Map<String, dynamic>? responseHeaders,
    dynamic error,
  }) {
    final context = <String, dynamic>{
      'method': method,
      'url': url,
      'timestamp': DateTime.now().toIso8601String(),
      if (statusCode != null) 'statusCode': statusCode,
      if (duration != null) 'duration': duration.inMilliseconds,
      if (requestHeaders != null) 'requestHeaders': requestHeaders,
      if (responseHeaders != null) 'responseHeaders': responseHeaders,
      if (error != null) 'error': error.toString(),
    };

    final message = statusCode != null
        ? '🌐 $method $url → $statusCode (${duration?.inMilliseconds ?? 0}ms)'
        : '🌐 $method $url (${duration?.inMilliseconds ?? 0}ms)';

    if (error != null) {
      AppLogger.error(message, error.toString(), context);
    } else {
      AppLogger.debug(message, context);
    }
  }

  /// 记录缓存操作
  void logCacheOperation(
    String operation,
    String key, {
    bool? hit,
    int? dataSize,
    Duration? duration,
  }) {
    final context = <String, dynamic>{
      'operation': operation,
      'key': key,
      'timestamp': DateTime.now().toIso8601String(),
      if (hit != null) 'hit': hit,
      if (dataSize != null) 'dataSize': dataSize,
      if (duration != null) 'duration': duration.inMilliseconds,
    };

    final hitStatus = hit == true ? 'HIT' : (hit == false ? 'MISS' : 'N/A');
    final message = '💾 缓存 $operation: $key [$hitStatus]';

    AppLogger.debug(message, context);
  }

  /// 记录重试操作
  void logRetryOperation(
    String operation,
    int attempt,
    int maxAttempts, {
    Duration? delay,
    String? error,
  }) {
    final context = <String, dynamic>{
      'operation': operation,
      'attempt': attempt,
      'maxAttempts': maxAttempts,
      'timestamp': DateTime.now().toIso8601String(),
      if (delay != null) 'delay': delay.inMilliseconds,
      if (error != null) 'error': error,
    };

    final message = error != null
        ? '🔄 重试 $operation: $attempt/$maxAttempts 失败 - $error'
        : '🔄 重试 $operation: $attempt/$maxAttempts';

    if (error != null) {
      AppLogger.warn(message, context);
    } else {
      AppLogger.debug(message, context);
    }
  }

  /// 记录数据质量检查
  void logDataQualityCheck(
    String source,
    int totalCount,
    int validCount,
    int invalidCount, {
    Map<String, dynamic>? details,
  }) {
    final context = <String, dynamic>{
      'source': source,
      'totalCount': totalCount,
      'validCount': validCount,
      'invalidCount': invalidCount,
      'validityRate': totalCount > 0 ? (validCount / totalCount * 100) : 0,
      'timestamp': DateTime.now().toIso8601String(),
      if (details != null) ...details,
    };

    final validityRate = totalCount > 0 ? (validCount / totalCount * 100) : 0;
    final message =
        '📊 数据质量检查: $source - 有效 $validCount/$totalCount (${validityRate.toStringAsFixed(1)}%)';

    if (validityRate < 90) {
      AppLogger.warn(message, context);
    } else {
      AppLogger.info(message, context);
    }
  }

  /// 生成测试报告摘要
  Future<void> generateTestSummary(Map<String, dynamic> testResults) async {
    final summary = {
      'timestamp': DateTime.now().toIso8601String(),
      'environment': kDebugMode ? 'development' : 'production',
      'platform': Platform.operatingSystem,
      'testResults': testResults,
    };

    AppLogger.info('📋 测试摘要报告', summary);

    // 写入单独的摘要文件
    try {
      final summaryFile = File(
          'logs/test_summary_${DateTime.now().millisecondsSinceEpoch}.json');
      await summaryFile.writeAsString(_formatJson(summary));
      AppLogger.info('📄 测试摘要已保存: ${summaryFile.path}');
    } catch (e) {
      AppLogger.warn('⚠️ 测试摘要保存失败', e.toString());
    }
  }

  /// 简单的JSON格式化
  String _formatJson(Map<String, dynamic> data) {
    String buffer = '';
    _formatJsonBuffer(data, buffer, 0);
    return buffer;
  }

  void _formatJsonBuffer(dynamic data, String buffer, int indent) {
    if (data is Map<String, dynamic>) {
      buffer += '{\n';
      final entries = data.entries.toList();
      for (int i = 0; i < entries.length; i++) {
        final entry = entries[i];
        buffer += '  ' * (indent + 1) + '"${entry.key}": ';
        _formatJsonBuffer(entry.value, buffer, indent + 1);
        buffer += i < entries.length - 1 ? ',\n' : '\n';
      }
      buffer += '  ' * indent + '}';
    } else if (data is List) {
      buffer += '[\n';
      for (int i = 0; i < data.length; i++) {
        buffer += '  ' * (indent + 1);
        _formatJsonBuffer(data[i], buffer, indent + 1);
        buffer += i < data.length - 1 ? ',\n' : '\n';
      }
      buffer += '  ' * indent + ']';
    } else if (data is String) {
      buffer += '"$data"';
    } else {
      buffer += data.toString();
    }
  }

  /// 获取日志统计信息
  Map<String, dynamic> getLogStatistics() {
    return {
      'initialized': _isInitialized,
      'bufferSize': _logBuffer.length,
      'logFilePath': _logFile.path,
      'maxLogFileSize': _maxLogFileSize,
      'maxLogFiles': _maxLogFiles,
    };
  }

  /// 清理资源
  Future<void> dispose() async {
    try {
      // 刷新缓冲区
      _flushBuffer();

      // 停止定时器
      _flushTimer?.cancel();

      // 清理缓冲区
      _logBuffer.clear();

      AppLogger.info('🧹 测试日志配置已清理');
    } catch (e) {
      debugPrint('❌ 测试日志配置清理失败: $e');
    }
  }
}

/// 扩展AppLogger以支持自定义处理器
extension AppLoggerExtensions on AppLogger {
  static void addCustomHandler(
      String name,
      Function(LogLevel, String, Map<String, dynamic>?, dynamic, StackTrace?)
          handler) {
    // 这里可以扩展AppLogger以支持自定义处理器
    // 实际实现中需要修改AppLogger类来支持这个功能
  }
}
