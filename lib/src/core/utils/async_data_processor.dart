import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/foundation.dart';

/// Isolate数据处理消息类型
enum IsolateMessage {
  // 请求消息
  processBatch,
  shutdown,

  // 响应消息
  batchResult,
  error,
  shutdownComplete,
}

/// Isolate数据传输对象
class IsolateDataPacket {
  final IsolateMessage type;
  final dynamic data;
  final dynamic sendPort; // 改为dynamic以支持SendPort和ReceivePort
  final int? batchIndex;

  IsolateDataPacket({
    required this.type,
    this.data,
    this.sendPort,
    this.batchIndex,
  });
}

/// Isolate配置
class IsolateConfig {
  final int batchSize;
  final Duration batchDelay;
  final bool enableLogging;

  IsolateConfig({
    this.batchSize = 20, // 进一步减小批次大小
    this.batchDelay = const Duration(milliseconds: 200), // 每批延迟200毫秒
    this.enableLogging = kDebugMode,
  });
}

/// 异步数据处理器 - 支持手动创建Isolate处理超大量数据
class AsyncDataProcessor {
  static Isolate? _isolate;
  static ReceivePort? _receivePort;
  static SendPort? _sendPort;
  static bool _isolateInitialized = false;
  static final Map<int, Completer<List<dynamic>>> _pendingBatches = {};

  /// 初始化Isolate
  static Future<void> initializeIsolate() async {
    if (_isolateInitialized) return;

    try {
      _receivePort = ReceivePort();
      _isolate = await Isolate.spawn(_isolateMain, _receivePort!.sendPort);
      _sendPort = _receivePort!.sendPort;

      // 监听来自Isolate的消息
      _receivePort!.listen(_handleIsolateMessage);

      _isolateInitialized = true;
      debugPrint('✅ Isolate 初始化成功');
    } catch (e) {
      debugPrint('❌ Isolate 初始化失败: $e');
      rethrow;
    }
  }

  /// 关闭Isolate
  static Future<void> shutdownIsolate() async {
    if (!_isolateInitialized) return;

    try {
      _sendPort!.send(IsolateDataPacket(type: IsolateMessage.shutdown));

      // 等待关闭确认
      await _receivePort!.firstWhere(
          (message) => message.type == IsolateMessage.shutdownComplete);

      _isolate?.kill(priority: Isolate.immediate);
      _isolate = null;
      _sendPort = null;
      _receivePort = null;
      _isolateInitialized = false;
      _pendingBatches.clear();

      debugPrint('✅ Isolate 已关闭');
    } catch (e) {
      debugPrint('❌ 关闭Isolate失败: $e');
    }
  }

  /// 异步分批处理超大量数据
  static Future<List<T>> processMassiveData<T>(
    List<dynamic> rawData,
    T Function(Map<String, dynamic>) fromJson, {
    IsolateConfig? config,
    Function(int processed, int total)? onProgress,
  }) async {
    if (rawData.isEmpty) return [];

    final effectiveConfig = config ?? IsolateConfig();

    // 如果数据量较小，直接在主线程处理
    if (rawData.length <= 5000) {
      return await _processInMainThread(
          rawData, fromJson, effectiveConfig, onProgress);
    }

    // 大数据量使用Isolate处理
    await initializeIsolate();

    debugPrint('🚀 开始在Isolate中处理 ${rawData.length} 条数据');

    final results = <T>[];
    final totalBatches = (rawData.length / effectiveConfig.batchSize).ceil();

    // 分批发送数据到Isolate
    for (int i = 0; i < totalBatches; i++) {
      final batchStart = i * effectiveConfig.batchSize;
      final batchEnd =
          (batchStart + effectiveConfig.batchSize).clamp(0, rawData.length);
      final batchData = rawData.sublist(batchStart, batchEnd);

      final completer = Completer<List<T>>();
      _pendingBatches[i] = completer;

      // 发送批次到Isolate
      _sendPort!.send(IsolateDataPacket(
        type: IsolateMessage.processBatch,
        data: {
          'batchIndex': i,
          'data': batchData,
          'fromJsonType': fromJson.toString(),
        },
        batchIndex: i,
      ));

      // 报告进度
      final processedCount = (i + 1) * effectiveConfig.batchSize;
      onProgress?.call(
        processedCount.clamp(0, rawData.length),
        rawData.length,
      );

      // 批次间延迟，避免 overwhelming the Isolate
      if (i < totalBatches - 1) {
        await Future.delayed(effectiveConfig.batchDelay);
      }
    }

    // 收集所有批次结果
    for (int i = 0; i < totalBatches; i++) {
      final batchResult = await _pendingBatches[i]!.future;
      results.addAll(batchResult.cast<T>());
    }

    debugPrint('✅ Isolate处理完成，共处理 ${results.length} 条数据');
    return results;
  }

  /// 在主线程处理数据（用于小数据量）
  static Future<List<T>> _processInMainThread<T>(
    List<dynamic> rawData,
    T Function(Map<String, dynamic>) fromJson,
    IsolateConfig config,
    Function(int processed, int total)? onProgress,
  ) async {
    debugPrint('📦 在主线程处理 ${rawData.length} 条数据');

    final results = <T>[];
    final totalItems = rawData.length;

    for (int i = 0; i < totalItems; i += config.batchSize) {
      final batchEnd = (i + config.batchSize).clamp(0, totalItems);
      final batchData = rawData.sublist(i, batchEnd);

      // 处理当前批次
      for (final item in batchData) {
        if (item is Map<String, dynamic>) {
          try {
            final result = fromJson(item);
            results.add(result);
          } catch (e) {
            if (config.enableLogging) {
              debugPrint('⚠️ 处理单条数据失败: $e');
            }
          }
        }
      }

      // 报告进度
      final processedCount = (i + config.batchSize).clamp(0, totalItems);
      onProgress?.call(processedCount, totalItems);

      // 让出控制权
      if (i + config.batchSize < totalItems) {
        await Future.delayed(config.batchDelay);
      }
    }

    return results;
  }

  /// 处理来自Isolate的消息
  static void _handleIsolateMessage(dynamic message) {
    try {
      final packet = message as IsolateDataPacket;

      switch (packet.type) {
        case IsolateMessage.batchResult:
          final batchIndex = packet.batchIndex!;
          final resultData = packet.data as List<dynamic>;

          final completer = _pendingBatches[batchIndex];
          if (completer != null) {
            completer.complete(resultData);
            _pendingBatches.remove(batchIndex);
          }
          break;

        case IsolateMessage.error:
          debugPrint('❌ Isolate处理错误: ${packet.data}');
          final batchIndex = packet.batchIndex!;
          final completer = _pendingBatches[batchIndex];
          if (completer != null) {
            completer.complete([]);
            _pendingBatches.remove(batchIndex);
          }
          break;

        case IsolateMessage.shutdownComplete:
          debugPrint('📴 Isolate关闭确认');
          break;

        default:
          debugPrint('⚠️ 未知消息类型: ${packet.type}');
      }
    } catch (e) {
      debugPrint('❌ 处理Isolate消息失败: $e');
    }
  }

  /// Isolate主函数
  static void _isolateMain(SendPort mainSendPort) {
    final receivePort = ReceivePort();
    mainSendPort.send(IsolateDataPacket(
      type: IsolateMessage.batchResult,
      sendPort: receivePort,
    ));

    receivePort.listen((message) async {
      try {
        final packet = message as IsolateDataPacket;

        switch (packet.type) {
          case IsolateMessage.processBatch:
            await _processBatchInIsolate(packet, mainSendPort);
            break;

          case IsolateMessage.shutdown:
            mainSendPort.send(IsolateDataPacket(
              type: IsolateMessage.shutdownComplete,
            ));
            break;

          default:
            mainSendPort.send(IsolateDataPacket(
              type: IsolateMessage.error,
              data: '未知消息类型: ${packet.type}',
            ));
        }
      } catch (e) {
        mainSendPort.send(IsolateDataPacket(
          type: IsolateMessage.error,
          data: e.toString(),
        ));
      }
    });
  }

  /// 在Isolate中处理批次数据
  static Future<void> _processBatchInIsolate(
    IsolateDataPacket packet,
    SendPort mainSendPort,
  ) async {
    try {
      final batchData = packet.data as Map<String, dynamic>;
      final batchIndex = batchData['batchIndex'] as int;
      final dataList = batchData['data'] as List<dynamic>;

      debugPrint('🔄 Isolate处理批次 $batchIndex (${dataList.length} 条数据)');

      final results = <dynamic>[];

      // 处理批次中的每条数据
      for (final item in dataList) {
        if (item is Map<String, dynamic>) {
          try {
            // 这里需要根据实际类型动态解析
            // 由于Dart的限制，我们使用JSON序列化来传递函数
            final resultJson = jsonEncode(item);
            results.add(resultJson);
          } catch (e) {
            debugPrint('⚠️ Isolate中处理单条数据失败: $e');
          }
        }
      }

      // 发送结果回主线程
      mainSendPort.send(IsolateDataPacket(
        type: IsolateMessage.batchResult,
        data: results,
        batchIndex: batchIndex,
      ));
    } catch (e) {
      debugPrint('❌ Isolate批次处理失败: $e');
      mainSendPort.send(IsolateDataPacket(
        type: IsolateMessage.error,
        data: e.toString(),
        batchIndex: packet.batchIndex,
      ));
    }
  }

  /// 获取Isolate状态
  static bool get isIsolateInitialized => _isolateInitialized;

  /// 获取待处理批次数量
  static int get pendingBatchesCount => _pendingBatches.length;
}

/// 专为基金数据设计的Isolate处理器
class FundDataIsolateProcessor {
  /// 使用Isolate处理大量基金数据
  static Future<List<Map<String, dynamic>>> processFundData(
    List<dynamic> rawData, {
    int batchSize = 10, // 更小的批次大小
    Duration batchDelay = const Duration(milliseconds: 200), // 每批延迟200毫秒
    bool enableLogging = true,
  }) async {
    debugPrint('🚀 开始使用Isolate处理基金数据 (${rawData.length} 条)');

    final config = IsolateConfig(
      batchSize: batchSize,
      batchDelay: batchDelay,
      enableLogging: enableLogging,
    );

    // 由于泛型限制，我们返回Map数据，让调用方转换
    final results =
        await AsyncDataProcessor.processMassiveData<Map<String, dynamic>>(
      rawData,
      (json) => json, // 直接返回Map，不做类型转换
      config: config,
      onProgress: (processed, total) {
        // 进一步降低日志输出频率，每批都输出
        if (enableLogging && processed % batchSize == 0) {
          debugPrint(
              '📊 Isolate处理进度: $processed/$total (${(processed / total * 100).toStringAsFixed(1)}%)');
        }
      },
    );

    debugPrint('✅ Isolate基金数据处理完成');
    return results;
  }

  /// 关闭基金数据Isolate
  static Future<void> shutdown() async {
    await AsyncDataProcessor.shutdownIsolate();
  }
}

/// 性能监控器
class IsolatePerformanceMonitor {
  static final Map<String, Stopwatch> _timers = {};

  /// 开始计时
  static void startTimer(String name) {
    _timers[name] = Stopwatch()..start();
  }

  /// 结束计时并返回耗时
  static int endTimer(String name) {
    final stopwatch = _timers[name];
    if (stopwatch != null) {
      stopwatch.stop();
      final elapsed = stopwatch.elapsedMilliseconds;
      _timers.remove(name);
      return elapsed;
    }
    return 0;
  }

  /// 获取所有计时结果
  static Map<String, int> getAllTimers() {
    return Map.fromEntries(
      _timers.entries.map((entry) {
        entry.value.stop();
        return MapEntry(entry.key, entry.value.elapsedMilliseconds);
      }),
    );
  }

  /// 清除所有计时器
  static void clearAllTimers() {
    _timers.clear();
  }
}
