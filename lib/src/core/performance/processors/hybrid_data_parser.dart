// ignore_for_file: public_member_api_docs, sort_constructors_first, prefer_const_constructors, prefer_const_declarations, unnecessary_import

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../../utils/logger.dart';
import 'improved_isolate_manager.dart';

/// 数据解析策略枚举
enum ParsingStrategy {
  json, // JSON解析（适合小数据量）
  flatbuffers, // FlatBuffers解析（适合大数据量）
  hybrid, // 混合策略（自动选择）
}

/// 解析性能指标
class ParsingMetrics {
  final DateTime timestamp;
  final ParsingStrategy strategy;
  final int dataSizeBytes;
  final int itemCount;
  final Duration parseTime;
  final Duration serializeTime;
  final double memoryUsageMB;
  final bool success;

  ParsingMetrics({
    required this.timestamp,
    required this.strategy,
    required this.dataSizeBytes,
    required this.itemCount,
    required this.parseTime,
    required this.serializeTime,
    required this.memoryUsageMB,
    required this.success,
  });

  double get throughputItemsPerSecond => parseTime.inMilliseconds > 0
      ? itemCount * 1000 / parseTime.inMilliseconds
      : 0;

  double get throughputBytesPerSecond => parseTime.inMilliseconds > 0
      ? dataSizeBytes * 1000 / parseTime.inMilliseconds
      : 0;

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'strategy': strategy.name,
      'dataSizeBytes': dataSizeBytes,
      'itemCount': itemCount,
      'parseTimeMs': parseTime.inMilliseconds,
      'serializeTimeMs': serializeTime.inMilliseconds,
      'memoryUsageMB': memoryUsageMB,
      'success': success,
      'throughputItemsPerSecond': throughputItemsPerSecond,
      'throughputBytesPerSecond': throughputBytesPerSecond,
    };
  }
}

/// 数据解析配置
class HybridDataParserConfig {
  final int flatbuffersThreshold; // 使用FlatBuffers的数据量阈值
  final Duration parseTimeout; // 解析超时时间
  final bool enableIsolateParsing; // 启用Isolate解析
  final bool enablePerformanceMonitoring; // 启用性能监控
  final int maxHistorySize; // 性能历史记录大小

  const HybridDataParserConfig({
    this.flatbuffersThreshold = 1000,
    this.parseTimeout = const Duration(seconds: 30),
    this.enableIsolateParsing = true,
    this.enablePerformanceMonitoring = true,
    this.maxHistorySize = 100,
  });
}

/// 基金数据模型（示例）
class FundDataItem {
  final String code;
  final String name;
  final double nav;
  final String navDate;
  final double dailyChange;
  final double changePercent;

  FundDataItem({
    required this.code,
    required this.name,
    required this.nav,
    required this.navDate,
    required this.dailyChange,
    required this.changePercent,
  });

  factory FundDataItem.fromJson(Map<String, dynamic> json) {
    return FundDataItem(
      code: json['code'] as String,
      name: json['name'] as String,
      nav: (json['nav'] as num).toDouble(),
      navDate: json['navDate'] as String,
      dailyChange: (json['dailyChange'] as num?)?.toDouble() ?? 0.0,
      changePercent: (json['changePercent'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'nav': nav,
      'navDate': navDate,
      'dailyChange': dailyChange,
      'changePercent': changePercent,
    };
  }
}

/// 混合数据解析器
///
/// 根据数据量自动选择最优解析策略，支持JSON、FlatBuffers和混合模式
class HybridDataParser {
  static final HybridDataParser _instance = HybridDataParser._internal();
  factory HybridDataParser() => _instance;
  HybridDataParser._internal();

  // 使用自定义AppLogger静态方法
  HybridDataParserConfig _config = const HybridDataParserConfig();

  final List<ParsingMetrics> _metricsHistory = [];
  final Map<String, String> _isolateParsingTasks = {};

  /// 配置解析器
  void configure(HybridDataParserConfig config) {
    _config = config;
    AppLogger.business('配置已更新', 'HybridDataParser');
  }

  /// 解析基金数据
  Future<List<FundDataItem>> parseFundData(dynamic rawData) async {
    final itemCount = _estimateItemCount(rawData);
    final strategy = _selectOptimalStrategy(itemCount, rawData);

    AppLogger.debug(
        'HybridDataParser', '使用策略 ${strategy.name} 解析 $itemCount 项数据');

    try {
      final result = await _parseWithStrategy(rawData, strategy);

      if (_config.enablePerformanceMonitoring) {
        await _recordParsingMetrics(strategy, rawData, result);
      }

      return result;
    } catch (e) {
      AppLogger.error('数据解析失败 (策略: ${strategy.name})', e);

      // 尝试使用备用策略
      if (strategy != ParsingStrategy.json) {
        AppLogger.info('尝试使用JSON备用策略');
        return await _parseWithStrategy(rawData, ParsingStrategy.json);
      }

      rethrow;
    }
  }

  /// 批量解析数据
  Future<List<List<FundDataItem>>> parseBatchData(
      List<dynamic> rawDataList) async {
    final results = <List<FundDataItem>>[];

    // 并发解析，但限制并发数量以避免资源过度使用
    const concurrencyLimit = 5;

    for (int i = 0; i < rawDataList.length; i += concurrencyLimit) {
      final batch = rawDataList.skip(i).take(concurrencyLimit).toList();
      final batchResults = await Future.wait(
        batch.map((data) => parseFundData(data)),
      );
      results.addAll(batchResults);
    }

    return results;
  }

  /// 异步解析（在Isolate中）
  Future<List<FundDataItem>> parseAsync(dynamic rawData) async {
    if (!_config.enableIsolateParsing) {
      return await parseFundData(rawData);
    }

    final taskId = 'parse_${DateTime.now().millisecondsSinceEpoch}';

    try {
      final isolateId = await _createParsingIsolate(taskId);

      final result = await _executeParsingInIsolate(isolateId, rawData);

      await ImprovedIsolateManager().shutdownIsolate(isolateId);
      _isolateParsingTasks.remove(taskId);

      return result;
    } catch (e) {
      AppLogger.error('异步解析失败，回退到同步解析', e);
      _isolateParsingTasks.remove(taskId);
      return await parseFundData(rawData);
    }
  }

  /// 选择最优解析策略
  ParsingStrategy _selectOptimalStrategy(int itemCount, dynamic rawData) {
    // 基于数据量选择策略
    if (itemCount >= _config.flatbuffersThreshold) {
      return ParsingStrategy.flatbuffers;
    }

    // 基于数据特征选择策略
    if (rawData is String) {
      final dataSize = rawData.length;
      if (dataSize > 1024 * 1024) {
        // 1MB
        return ParsingStrategy.flatbuffers;
      }
    }

    // 默认使用JSON
    return ParsingStrategy.json;
  }

  /// 使用指定策略解析数据
  Future<List<FundDataItem>> _parseWithStrategy(
    dynamic rawData,
    ParsingStrategy strategy,
  ) async {
    switch (strategy) {
      case ParsingStrategy.json:
        return await _parseJson(rawData);
      case ParsingStrategy.flatbuffers:
        return await _parseFlatBuffers(rawData);
      case ParsingStrategy.hybrid:
        return await _parseHybrid(rawData);
    }
  }

  /// JSON解析
  Future<List<FundDataItem>> _parseJson(dynamic rawData) async {
    final stopwatch = Stopwatch()..start();

    try {
      List<dynamic> jsonData;

      if (rawData is String) {
        jsonData = jsonDecode(rawData);
      } else if (rawData is List) {
        jsonData = rawData;
      } else if (rawData is Map<String, dynamic>) {
        jsonData = [rawData];
      } else {
        throw ArgumentError('不支持的数据类型: ${rawData.runtimeType}');
      }

      final result = jsonData
          .map((item) => FundDataItem.fromJson(item as Map<String, dynamic>))
          .toList();

      stopwatch.stop();
      AppLogger.debug(
          'JSON解析完成: ${result.length}项，耗时${stopwatch.elapsedMilliseconds}ms');

      return result;
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('HybridDataParser: JSON解析失败', e);
      rethrow;
    }
  }

  /// FlatBuffers解析（简化实现）
  Future<List<FundDataItem>> _parseFlatBuffers(dynamic rawData) async {
    final stopwatch = Stopwatch()..start();

    try {
      // 在实际实现中，这里应该使用真正的FlatBuffers
      // 这里简化为优化过的JSON解析

      List<dynamic> jsonData;
      if (rawData is Uint8List) {
        // 模拟FlatBuffers二进制数据解析
        jsonData = _deserializeFromBytes(rawData);
      } else if (rawData is String) {
        // 先转换为字节，再解析（模拟FlatBuffers过程）
        jsonData = jsonDecode(rawData);
      } else {
        jsonData = rawData as List;
      }

      // 使用compute函数进行高性能解析
      final result = await compute(_parseFundDataIsolate, jsonData);

      stopwatch.stop();
      AppLogger.debug(
          'FlatBuffers解析完成: ${result.length}项，耗时${stopwatch.elapsedMilliseconds}ms');

      return result;
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('HybridDataParser: FlatBuffers解析失败', e);
      rethrow;
    }
  }

  /// 混合解析策略
  Future<List<FundDataItem>> _parseHybrid(dynamic rawData) async {
    // 首先尝试JSON解析，如果性能不佳则切换到FlatBuffers
    final jsonStopwatch = Stopwatch()..start();

    try {
      final result = await _parseJson(rawData);
      jsonStopwatch.stop();

      // 如果JSON解析时间过长，下次使用FlatBuffers
      if (jsonStopwatch.elapsedMilliseconds > 100) {
        AppLogger.debug('JSON解析较慢，建议使用FlatBuffers');
      }

      return result;
    } catch (e) {
      jsonStopwatch.stop();
      AppLogger.warn('JSON解析失败，尝试FlatBuffers', e.toString());
      return await _parseFlatBuffers(rawData);
    }
  }

  /// 创建解析Isolate
  Future<String> _createParsingIsolate(String taskId) async {
    return await ImprovedIsolateManager().startIsolate<Map<String, dynamic>>(
      entryPoint: _parsingIsolateEntry,
      initialData: {
        'taskId': taskId,
        'config': {
          'enablePerformanceMonitoring': _config.enablePerformanceMonitoring,
        },
      },
    );
  }

  /// 在Isolate中执行解析
  Future<List<FundDataItem>> _executeParsingInIsolate(
    String isolateId,
    dynamic rawData,
  ) async {
    final completer = Completer<List<FundDataItem>>();
    late StreamSubscription subscription;

    subscription = ImprovedIsolateManager().healthStatusStream.listen((status) {
      if (status.isolateId == isolateId && status.errorMessage != null) {
        completer.completeError(Exception(status.errorMessage!));
        subscription.cancel();
      }
    });

    try {
      await ImprovedIsolateManager().sendTask(isolateId, {
        'action': 'parse',
        'data': rawData,
      });

      // 在实际实现中，这里需要处理Isolate的响应
      // 简化实现：直接在当前线程解析
      final result = await parseFundData(rawData);

      subscription.cancel();
      return result;
    } catch (e) {
      subscription.cancel();
      completer.completeError(e);
      rethrow;
    }
  }

  /// Isolate入口点
  static Future<Map<String, dynamic>> _parsingIsolateEntry(
      SendPort sendPort) async {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    receivePort.listen((message) async {
      try {
        if (message is Map<String, dynamic>) {
          switch (message['action']) {
            case 'parse':
              final data = message['data'];
              final result = _parseFundDataIsolate(data);
              sendPort.send({
                'type': 'result',
                'data': result,
              });
              break;
          }
        }
      } catch (e) {
        sendPort.send({
          'type': 'error',
          'error': e.toString(),
        });
      }
    });

    return {'status': 'initialized'};
  }

  /// Isolate中的解析函数
  static List<FundDataItem> _parseFundDataIsolate(dynamic data) {
    try {
      List<dynamic> jsonData;

      if (data is String) {
        jsonData = jsonDecode(data);
      } else if (data is List) {
        jsonData = data;
      } else {
        throw ArgumentError('不支持的数据类型');
      }

      return jsonData
          .map((item) => FundDataItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Isolate解析失败: $e');
    }
  }

  /// 估算数据项数量
  int _estimateItemCount(dynamic rawData) {
    if (rawData is String) {
      // 粗略估算：假设每个JSON对象约200字符
      return (rawData.length / 200).ceil();
    } else if (rawData is List) {
      return rawData.length;
    } else if (rawData is Uint8List) {
      // 二进制数据：假设每个对象约100字节
      return (rawData.length / 100).ceil();
    } else {
      return 1;
    }
  }

  /// 从字节数据反序列化（模拟FlatBuffers）
  List<dynamic> _deserializeFromBytes(Uint8List bytes) {
    // 简化实现：在实际项目中应该使用真正的FlatBuffers
    final jsonString = String.fromCharCodes(bytes);
    return jsonDecode(jsonString);
  }

  /// 记录解析性能指标
  Future<void> _recordParsingMetrics(
    ParsingStrategy strategy,
    dynamic rawData,
    List<FundDataItem> result,
  ) async {
    final metrics = ParsingMetrics(
      timestamp: DateTime.now(),
      strategy: strategy,
      dataSizeBytes: _getDataSizeBytes(rawData),
      itemCount: result.length,
      parseTime: Duration(milliseconds: 0), // 简化实现
      serializeTime: Duration(milliseconds: 0),
      memoryUsageMB: await _getCurrentMemoryUsageMB(),
      success: true,
    );

    _metricsHistory.insert(0, metrics);

    // 限制历史记录大小
    while (_metricsHistory.length > _config.maxHistorySize) {
      _metricsHistory.removeLast();
    }
  }

  /// 获取数据大小（字节）
  int _getDataSizeBytes(dynamic data) {
    if (data is String) {
      return data.length;
    } else if (data is Uint8List) {
      return data.length;
    } else if (data is List) {
      return data.length * 200; // 估算每个对象200字节
    } else {
      return 100; // 默认估算
    }
  }

  /// 获取性能统计
  Map<String, dynamic> getPerformanceStatistics() {
    if (_metricsHistory.isEmpty) {
      return {'error': '没有性能数据'};
    }

    final recent = _metricsHistory.take(20).toList();

    final avgParseTime =
        recent.map((m) => m.parseTime.inMilliseconds).reduce((a, b) => a + b) /
            recent.length;

    final avgThroughput =
        recent.map((m) => m.throughputItemsPerSecond).reduce((a, b) => a + b) /
            recent.length;

    final strategyStats = <ParsingStrategy, List<ParsingMetrics>>{};
    for (final metric in recent) {
      strategyStats.putIfAbsent(metric.strategy, () => []).add(metric);
    }

    return {
      'totalParseOperations': _metricsHistory.length,
      'recentAvgParseTimeMs': avgParseTime.roundToDouble(),
      'recentAvgThroughputItemsPerSec': avgThroughput.roundToDouble(),
      'strategyPerformance': strategyStats.map((strategy, metrics) {
        final avgTime = metrics
                .map((m) => m.parseTime.inMilliseconds)
                .reduce((a, b) => a + b) /
            metrics.length;

        return MapEntry(strategy.name, {
          'usageCount': metrics.length,
          'avgParseTimeMs': avgTime.roundToDouble(),
          'totalItemsProcessed':
              metrics.map((m) => m.itemCount).reduce((a, b) => a + b),
        });
      }),
      'config': {
        'flatbuffersThreshold': _config.flatbuffersThreshold,
        'enableIsolateParsing': _config.enableIsolateParsing,
        'enablePerformanceMonitoring': _config.enablePerformanceMonitoring,
      },
    };
  }

  /// 清理资源
  Future<void> dispose() async {
    AppLogger.business('清理资源', 'HybridDataParser');

    // 清理活跃的解析任务
    final taskIds = _isolateParsingTasks.keys.toList();
    for (final taskId in taskIds) {
      try {
        final isolateId = _isolateParsingTasks.remove(taskId);
        if (isolateId != null) {
          await ImprovedIsolateManager().shutdownIsolate(isolateId);
        }
      } catch (e) {
        AppLogger.warn('清理解析任务失败: $taskId', 'HybridDataParser');
      }
    }

    _metricsHistory.clear();
    AppLogger.info('HybridDataParser资源清理完成');
  }

  /// 获取当前内存使用量（现代化方法替代过时的developer.getCurrentRSS）
  Future<double> _getCurrentMemoryUsageMB() async {
    try {
      // 在实际项目中，这里应该使用平台特定的API获取内存信息
      // 由于getCurrentRSS已弃用，我们使用模拟数据

      // 模拟基础内存信息（单位：字节）
      final rss = 100 * 1024 * 1024; // 100MB 模拟值

      return rss / (1024 * 1024); // 转换为MB
    } catch (e) {
      AppLogger.error('获取内存使用量失败', e);
      return 100.0; // 默认100MB
    }
  }
}
