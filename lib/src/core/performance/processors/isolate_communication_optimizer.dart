// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import '../../utils/logger.dart';
import 'memory_mapped_file_handler.dart';
import 'improved_isolate_manager.dart';

/// 通信策略枚举
enum CommunicationStrategy {
  direct, // 直接消息传递（小数据）
  sharedMemory, // 共享内存（中等数据）
  fileTransfer, // 文件传输（大数据）
  hybrid, // 混合策略（自动选择）
}

/// 消息类型
enum MessageType {
  command, // 命令消息
  data, // 数据消息
  response, // 响应消息
  error, // 错误消息
  heartbeat, // 心跳消息
}

/// 通信消息
class IsolateMessage {
  final String messageId;
  final MessageType type;
  final String? command;
  final dynamic data;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  IsolateMessage({
    required this.messageId,
    required this.type,
    this.command,
    this.data,
    this.metadata,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'type': type.name,
      'command': command,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
      // 注意：data字段可能包含不能序列化的内容，需要特殊处理
    };
  }

  factory IsolateMessage.fromJson(Map<String, dynamic> json) {
    return IsolateMessage(
      messageId: json['messageId'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.data,
      ),
      command: json['command'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// 通信性能指标
class CommunicationMetrics {
  final DateTime timestamp;
  final String sourceIsolateId;
  final String targetIsolateId;
  final CommunicationStrategy strategy;
  final int dataSizeBytes;
  final Duration sendTime;
  final Duration receiveTime;
  final bool success;
  final String? errorMessage;

  CommunicationMetrics({
    required this.timestamp,
    required this.sourceIsolateId,
    required this.targetIsolateId,
    required this.strategy,
    required this.dataSizeBytes,
    required this.sendTime,
    required this.receiveTime,
    required this.success,
    this.errorMessage,
  });

  Duration get totalTime => sendTime + receiveTime;

  double get throughputMBps => totalTime.inMilliseconds > 0
      ? (dataSizeBytes / (1024 * 1024)) / (totalTime.inMilliseconds / 1000)
      : 0;

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'sourceIsolateId': sourceIsolateId,
      'targetIsolateId': targetIsolateId,
      'strategy': strategy.name,
      'dataSizeBytes': dataSizeBytes,
      'sendTimeMs': sendTime.inMilliseconds,
      'receiveTimeMs': receiveTime.inMilliseconds,
      'totalTimeMs': totalTime.inMilliseconds,
      'throughputMBps': throughputMBps,
      'success': success,
      'errorMessage': errorMessage,
    };
  }
}

/// 通信配置
class IsolateCommunicationConfig {
  final int directThreshold; // 直接传递阈值（字节）
  final int sharedMemoryThreshold; // 共享内存阈值（字节）
  final Duration communicationTimeout; // 通信超时时间
  final int maxRetries; // 最大重试次数
  final bool enablePerformanceMonitoring; // 启用性能监控
  final bool enableCompression; // 启用压缩
  final int maxMetricsHistory; // 最大指标历史数量

  const IsolateCommunicationConfig({
    this.directThreshold = 64 * 1024, // 64KB
    this.sharedMemoryThreshold = 1024 * 1024, // 1MB
    this.communicationTimeout = const Duration(seconds: 30),
    this.maxRetries = 3,
    this.enablePerformanceMonitoring = true,
    this.enableCompression = false,
    this.maxMetricsHistory = 1000,
  });
}

/// Isolate通信优化器
///
/// 优化Isolate间的数据传输，减少序列化开销，提高通信效率
class IsolateCommunicationOptimizer {
  static final IsolateCommunicationOptimizer _instance =
      IsolateCommunicationOptimizer._internal();
  factory IsolateCommunicationOptimizer() => _instance;
  IsolateCommunicationOptimizer._internal();

  // 使用AppLogger静态方法
  IsolateCommunicationConfig _config = const IsolateCommunicationConfig();

  final Map<String, SendPort> _isolatePorts = {};
  final Map<String, Completer<dynamic>> _pendingResponses = {};
  final Map<String, Timer> _responseTimeouts = {};
  final List<CommunicationMetrics> _metricsHistory = [];

  final StreamController<IsolateMessage> _messageController =
      StreamController<IsolateMessage>.broadcast();
  Stream<IsolateMessage> get messageStream => _messageController.stream;

  /// 配置通信优化器
  void configure(IsolateCommunicationConfig config) {
    _config = config;
    AppLogger.info('IsolateCommunicationOptimizer配置已更新');
  }

  /// 启动通信优化器
  void start() {
    AppLogger.info('启动IsolateCommunicationOptimizer');

    // 监听Isolate管理器的健康状态变化
    ImprovedIsolateManager()
        .healthStatusStream
        .listen(_handleIsolateHealthChange);
  }

  /// 停止通信优化器
  Future<void> stop() async {
    AppLogger.info('停止IsolateCommunicationOptimizer');

    // 清理待响应
    final responseIds = _pendingResponses.keys.toList();
    for (final responseId in responseIds) {
      _responseTimeouts[responseId]?.cancel();
      _pendingResponses[responseId]?.completeError(Exception('通信优化器已停止'));
      _pendingResponses.remove(responseId);
      _responseTimeouts.remove(responseId);
    }

    await _messageController.close();
    _isolatePorts.clear();
    _metricsHistory.clear();

    AppLogger.info('IsolateCommunicationOptimizer已停止');
  }

  /// 注册Isolate通信端口
  void registerIsolate(String isolateId, SendPort sendPort) {
    _isolatePorts[isolateId] = sendPort;
    AppLogger.debug('注册Isolate通信端口: $isolateId');
  }

  /// 注销Isolate通信端口
  void unregisterIsolate(String isolateId) {
    _isolatePorts.remove(isolateId);
    AppLogger.debug('注销Isolate通信端口: $isolateId');

    // 清理该Isolate的待响应
    final responseIds = _pendingResponses.keys
        .where((id) => id.startsWith('${isolateId}_'))
        .toList();

    for (final responseId in responseIds) {
      _responseTimeouts[responseId]?.cancel();
      _pendingResponses[responseId]?.completeError(Exception('Isolate已断开连接'));
      _pendingResponses.remove(responseId);
      _responseTimeouts.remove(responseId);
    }
  }

  /// 发送消息到Isolate
  Future<dynamic> sendMessage(
    String targetIsolateId,
    MessageType type, {
    String? command,
    dynamic data,
    Map<String, dynamic>? metadata,
    bool expectResponse = true,
  }) async {
    final sendPort = _isolatePorts[targetIsolateId];
    if (sendPort == null) {
      throw StateError('Isolate通信端口不存在: $targetIsolateId');
    }

    final messageId =
        '${targetIsolateId}_${DateTime.now().millisecondsSinceEpoch}_${_pendingResponses.length}';
    final message = IsolateMessage(
      messageId: messageId,
      type: type,
      command: command,
      data: data,
      metadata: metadata,
    );

    if (expectResponse) {
      final completer = Completer<dynamic>();
      _pendingResponses[messageId] = completer;

      // 设置超时
      _responseTimeouts[messageId] = Timer(
        _config.communicationTimeout,
        () {
          _pendingResponses.remove(messageId)?.completeError(
                TimeoutException('Isolate通信超时: $targetIsolateId'),
              );
          _pendingResponses.remove(messageId);
          _responseTimeouts.remove(messageId);
        },
      );

      // 发送消息
      await _sendOptimizedMessage(targetIsolateId, sendPort, message);

      return await completer.future;
    } else {
      // 不需要响应
      await _sendOptimizedMessage(targetIsolateId, sendPort, message);
      return null;
    }
  }

  /// 广播消息到所有Isolate
  Future<void> broadcastMessage(
    MessageType type, {
    String? command,
    dynamic data,
    Map<String, dynamic>? metadata,
  }) async {
    final isolateIds = _isolatePorts.keys.toList();

    final futures = isolateIds.map((isolateId) => sendMessage(isolateId, type,
        command: command,
        data: data,
        metadata: metadata,
        expectResponse: false));

    await Future.wait(futures);
    AppLogger.debug('广播消息到 ${isolateIds.length} 个Isolate');
  }

  /// 处理接收到的消息
  Future<void> handleReceivedMessage(
      String sourceIsolateId, dynamic messageData) async {
    try {
      final message = await _parseReceivedMessage(sourceIsolateId, messageData);

      // 发送到消息流
      _messageController.add(message);

      // 处理响应消息
      if (message.type == MessageType.response) {
        _handleResponseMessage(message);
      }

      AppLogger.debug(
          '处理Isolate消息: ${sourceIsolateId} -> ${message.type.name}');
    } catch (e) {
      AppLogger.error('处理Isolate消息失败: $sourceIsolateId', e);
    }
  }

  /// 优化消息发送
  Future<void> _sendOptimizedMessage(
    String targetIsolateId,
    SendPort sendPort,
    IsolateMessage message,
  ) async {
    final stopwatch = Stopwatch()..start();

    try {
      final dataSize = _calculateDataSize(message);
      final strategy = _selectCommunicationStrategy(dataSize);

      AppLogger.debug(
          '发送消息到 $targetIsolateId (策略: ${strategy.name}, 大小: ${dataSize}字节)');

      switch (strategy) {
        case CommunicationStrategy.direct:
          await _sendDirectMessage(sendPort, message);
          break;
        case CommunicationStrategy.sharedMemory:
          await _sendSharedMemoryMessage(targetIsolateId, message);
          break;
        case CommunicationStrategy.fileTransfer:
          await _sendFileTransferMessage(targetIsolateId, message);
          break;
        case CommunicationStrategy.hybrid:
          await _sendHybridMessage(targetIsolateId, sendPort, message);
          break;
      }

      stopwatch.stop();

      if (_config.enablePerformanceMonitoring) {
        _recordCommunicationMetrics(
          sourceIsolateId: 'main',
          targetIsolateId: targetIsolateId,
          strategy: strategy,
          dataSizeBytes: dataSize,
          sendTime: stopwatch.elapsed,
          receiveTime: Duration.zero, // 发送时无法测量接收时间
          success: true,
        );
      }
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('发送消息失败: $targetIsolateId', e);

      if (_config.enablePerformanceMonitoring) {
        _recordCommunicationMetrics(
          sourceIsolateId: 'main',
          targetIsolateId: targetIsolateId,
          strategy: CommunicationStrategy.direct, // 默认策略
          dataSizeBytes: _calculateDataSize(message),
          sendTime: stopwatch.elapsed,
          receiveTime: Duration.zero,
          success: false,
          errorMessage: e.toString(),
        );
      }

      rethrow;
    }
  }

  /// 直接消息传递
  Future<void> _sendDirectMessage(
      SendPort sendPort, IsolateMessage message) async {
    // 对于小数据，直接序列化发送
    final serializedMessage = _serializeMessage(message);
    sendPort.send(serializedMessage);
  }

  /// 共享内存消息
  Future<void> _sendSharedMemoryMessage(
      String targetIsolateId, IsolateMessage message) async {
    // 创建共享内存区域
    final dataSize = _calculateDataSize(message);
    final sharedMemory =
        await MemoryMappedFileHandler().createSharedMemory(dataSize);

    try {
      // 将数据写入共享内存
      final sharedData = await _serializeMessageToBytes(message);
      final sharedMemoryHandler = MemoryMappedFileHandler();
      final memoryData =
          await sharedMemoryHandler.accessSharedMemory(sharedMemory.memoryId);

      // 复制数据到共享内存
      memoryData.setRange(0, sharedData.length, sharedData);

      // 发送共享内存信息
      final metadata = {
        'sharedMemoryId': sharedMemory.memoryId,
        'dataSize': sharedData.length,
        'originalMessageId': message.messageId,
        'originalType': message.type.name,
        'originalCommand': message.command,
        'originalMetadata': message.metadata,
      };

      final sharedMessage = IsolateMessage(
        messageId: message.messageId,
        type: MessageType.data,
        command: 'shared_memory',
        data: null,
        metadata: metadata,
      );

      final sendPort = _isolatePorts[targetIsolateId];
      if (sendPort != null) {
        await _sendDirectMessage(sendPort, sharedMessage);
      }
    } catch (e) {
      // 清理共享内存
      await MemoryMappedFileHandler().deleteFile(sharedMemory.memoryId);
      rethrow;
    }
  }

  /// 文件传输消息
  Future<void> _sendFileTransferMessage(
      String targetIsolateId, IsolateMessage message) async {
    // 对于大数据，使用文件传输
    final serializedData = await _serializeMessageToBytes(message);

    final fileId = await MemoryMappedFileHandler().createMemoryMappedFile(
      'isolate_message_${message.messageId}',
      serializedData,
      customId: message.messageId,
    );

    final metadata = {
      'fileId': fileId,
      'dataSize': serializedData.length,
      'originalType': message.type.name,
      'originalCommand': message.command,
      'originalMetadata': message.metadata,
    };

    final fileMessage = IsolateMessage(
      messageId: message.messageId,
      type: MessageType.data,
      command: 'file_transfer',
      data: null,
      metadata: metadata,
    );

    final sendPort = _isolatePorts[targetIsolateId];
    if (sendPort != null) {
      await _sendDirectMessage(sendPort, fileMessage);
    }
  }

  /// 混合策略消息
  Future<void> _sendHybridMessage(
    String targetIsolateId,
    SendPort sendPort,
    IsolateMessage message,
  ) async {
    // 根据数据内容特征选择策略
    final data = message.data;

    if (data is Uint8List && data.length > _config.sharedMemoryThreshold) {
      await _sendFileTransferMessage(targetIsolateId, message);
    } else if (_isLargeObject(data)) {
      await _sendSharedMemoryMessage(targetIsolateId, message);
    } else {
      await _sendDirectMessage(sendPort, message);
    }
  }

  /// 选择通信策略
  CommunicationStrategy _selectCommunicationStrategy(int dataSizeBytes) {
    if (dataSizeBytes <= _config.directThreshold) {
      return CommunicationStrategy.direct;
    } else if (dataSizeBytes <= _config.sharedMemoryThreshold) {
      return CommunicationStrategy.sharedMemory;
    } else {
      return CommunicationStrategy.fileTransfer;
    }
  }

  /// 计算数据大小
  int _calculateDataSize(IsolateMessage message) {
    try {
      final serialized = _serializeMessage(message);
      return serialized.toString().length;
    } catch (e) {
      // 如果序列化失败，估算大小
      return 1024; // 1KB默认估算
    }
  }

  /// 判断是否为大对象
  bool _isLargeObject(dynamic data) {
    if (data == null) return false;
    if (data is List) return data.length > 1000;
    if (data is Map) return data.length > 100;
    if (data is String) return data.length > 10000;
    return false;
  }

  /// 序列化消息
  dynamic _serializeMessage(IsolateMessage message) {
    return message.toJson();
  }

  /// 将消息序列化为字节
  Future<Uint8List> _serializeMessageToBytes(IsolateMessage message) async {
    final jsonStr = jsonEncode(message.toJson());
    return Uint8List.fromList(jsonStr.codeUnits);
  }

  /// 解析接收到的消息
  Future<IsolateMessage> _parseReceivedMessage(
      String sourceIsolateId, dynamic messageData) async {
    try {
      if (messageData is Map<String, dynamic>) {
        return IsolateMessage.fromJson(messageData);
      } else {
        // 处理共享内存或文件传输消息
        return await _parseSpecialMessage(sourceIsolateId, messageData);
      }
    } catch (e) {
      AppLogger.error('解析消息失败: $sourceIsolateId', e);
      throw FormatException('无法解析消息: $e');
    }
  }

  /// 解析特殊消息（共享内存、文件传输）
  Future<IsolateMessage> _parseSpecialMessage(
      String sourceIsolateId, dynamic messageData) async {
    if (messageData is Map<String, dynamic>) {
      final command = messageData['command'] as String?;
      final metadata = messageData['metadata'] as Map<String, dynamic>?;

      if (command == 'shared_memory' && metadata != null) {
        // 处理共享内存消息
        return await _parseSharedMemoryMessage(sourceIsolateId, metadata);
      } else if (command == 'file_transfer' && metadata != null) {
        // 处理文件传输消息
        return _parseFileTransferMessage(sourceIsolateId, metadata);
      }
    }

    // 默认处理
    return IsolateMessage(
      messageId: '${sourceIsolateId}_${DateTime.now().millisecondsSinceEpoch}',
      type: MessageType.data,
      data: messageData,
    );
  }

  /// 解析共享内存消息
  Future<IsolateMessage> _parseSharedMemoryMessage(
      String sourceIsolateId, Map<String, dynamic> metadata) async {
    try {
      final sharedMemoryId = metadata['sharedMemoryId'] as String;
      final dataSize = metadata['dataSize'] as int;

      // 从共享内存读取数据
      final memoryData =
          await MemoryMappedFileHandler().accessSharedMemory(sharedMemoryId);
      final jsonString =
          String.fromCharCodes(memoryData.take(dataSize).toList());
      final messageJson = jsonDecode(jsonString) as Map<String, dynamic>;

      return IsolateMessage.fromJson(messageJson);
    } catch (e) {
      AppLogger.error('解析共享内存消息失败: $sourceIsolateId', e);
      rethrow;
    }
  }

  /// 解析文件传输消息
  IsolateMessage _parseFileTransferMessage(
      String sourceIsolateId, Map<String, dynamic> metadata) {
    try {
      final fileId = metadata['fileId'] as String;

      // 从文件读取数据
      final fileData = MemoryMappedFileHandler().readMemoryMappedFile(fileId);
      final jsonString = String.fromCharCodes(fileData as Iterable<int>);
      final messageJson = jsonDecode(jsonString) as Map<String, dynamic>;

      return IsolateMessage.fromJson(messageJson);
    } catch (e) {
      AppLogger.error('解析文件传输消息失败: $sourceIsolateId', e);
      rethrow;
    }
  }

  /// 处理响应消息
  void _handleResponseMessage(IsolateMessage message) {
    final completer = _pendingResponses.remove(message.messageId);
    if (completer != null) {
      _responseTimeouts.remove(message.messageId)?.cancel();
      completer.complete(message.data);
    }
  }

  /// 处理Isolate健康状态变化
  void _handleIsolateHealthChange(dynamic healthStatus) {
    // 可以根据健康状态调整通信策略
    AppLogger.debug('Isolate健康状态变化: ${healthStatus.runtimeType}');
  }

  /// 记录通信指标
  void _recordCommunicationMetrics({
    required String sourceIsolateId,
    required String targetIsolateId,
    required CommunicationStrategy strategy,
    required int dataSizeBytes,
    required Duration sendTime,
    required Duration receiveTime,
    required bool success,
    String? errorMessage,
  }) {
    final metrics = CommunicationMetrics(
      timestamp: DateTime.now(),
      sourceIsolateId: sourceIsolateId,
      targetIsolateId: targetIsolateId,
      strategy: strategy,
      dataSizeBytes: dataSizeBytes,
      sendTime: sendTime,
      receiveTime: receiveTime,
      success: success,
      errorMessage: errorMessage,
    );

    _metricsHistory.insert(0, metrics);

    // 限制历史记录大小
    while (_metricsHistory.length > _config.maxMetricsHistory) {
      _metricsHistory.removeLast();
    }
  }

  /// 获取通信统计信息
  Map<String, dynamic> getStatistics() {
    if (_metricsHistory.isEmpty) {
      return {'error': '没有通信数据'};
    }

    final recent = _metricsHistory.take(100).toList();
    final successful = recent.where((m) => m.success).length;
    final total = recent.length;

    final strategyStats = <CommunicationStrategy, List<CommunicationMetrics>>{};
    for (final metric in recent) {
      strategyStats.putIfAbsent(metric.strategy, () => []).add(metric);
    }

    final avgSendTime =
        recent.map((m) => m.sendTime.inMilliseconds).reduce((a, b) => a + b) /
            recent.length;

    final totalDataSize =
        recent.map((m) => m.dataSizeBytes).fold(0, (a, b) => a + b);

    return {
      'registeredIsolates': _isolatePorts.length,
      'pendingResponses': _pendingResponses.length,
      'totalCommunications': _metricsHistory.length,
      'recentSuccessRate': total > 0 ? (successful / total * 100).round() : 0,
      'recentAvgSendTimeMs': avgSendTime.roundToDouble(),
      'recentTotalDataSizeMB':
          (totalDataSize / (1024 * 1024)).toStringAsFixed(2),
      'strategyUsage': strategyStats.map((strategy, metrics) {
        final avgThroughput =
            metrics.map((m) => m.throughputMBps).reduce((a, b) => a + b) /
                metrics.length;

        return MapEntry(strategy.name, {
          'usageCount': metrics.length,
          'avgThroughputMBps': avgThroughput.toStringAsFixed(2),
          'totalDataSizeMB':
              (metrics.map((m) => m.dataSizeBytes).fold(0, (a, b) => a + b) /
                      (1024 * 1024))
                  .toStringAsFixed(2),
        });
      }),
      'config': {
        'directThreshold': _config.directThreshold,
        'sharedMemoryThreshold': _config.sharedMemoryThreshold,
        'communicationTimeout': _config.communicationTimeout.inSeconds,
        'enablePerformanceMonitoring': _config.enablePerformanceMonitoring,
      },
    };
  }

  /// 清理资源
  Future<void> dispose() async {
    await stop();
  }
}

/// Isolate通信辅助类
class IsolateCommunicationHelper {
  static final IsolateCommunicationHelper _instance =
      IsolateCommunicationHelper._internal();
  factory IsolateCommunicationHelper() => _instance;
  IsolateCommunicationHelper._internal();

  final IsolateCommunicationOptimizer _optimizer =
      IsolateCommunicationOptimizer();

  /// 发送命令并等待响应
  Future<T> sendCommandAndWaitResponse<T>(
    String targetIsolateId,
    String command, {
    dynamic data,
    Map<String, dynamic>? metadata,
    Duration? timeout,
  }) async {
    final response = await _optimizer.sendMessage(
      targetIsolateId,
      MessageType.command,
      command: command,
      data: data,
      metadata: metadata,
      expectResponse: true,
    );

    if (response is T) {
      return response;
    } else {
      throw StateError('响应类型不匹配: 期望 $T，实际 ${response.runtimeType}');
    }
  }

  /// 发送数据（不等待响应）
  Future<void> sendData(
    String targetIsolateId,
    dynamic data, {
    Map<String, dynamic>? metadata,
  }) async {
    await _optimizer.sendMessage(
      targetIsolateId,
      MessageType.data,
      data: data,
      metadata: metadata,
      expectResponse: false,
    );
  }
}
