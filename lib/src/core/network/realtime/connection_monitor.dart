import 'dart:async';
import 'dart:math';
import '../utils/logger.dart';

// ignore_for_file: sort_constructors_first, public_member_api_docs
/// 连接质量监控器
///
/// 监控WebSocket连接的各项质量指标，包括延迟、丢包率、稳定性等
/// 提供实时的质量评估和报告功能
class ConnectionMonitor {
  /// 监控配置
  final ConnectionMonitorConfig config;

  /// 延迟历史记录
  final List<double> _latencyHistory = [];

  /// 消息发送时间戳记录（用于计算RTT）
  final Map<String, DateTime> _pendingMessages = {};

  /// 连接事件记录
  final List<ConnectionEvent> _connectionEvents = [];

  /// 质量指标定时器
  Timer? _metricsTimer;

  /// 监控开始时间
  DateTime? _monitorStartTime;

  /// 最后一次质量评估时间
  DateTime _lastQualityAssessment = DateTime.now();

  /// 当前质量等级
  ConnectionQuality _currentQuality = ConnectionQuality.excellent;

  /// 连接质量流控制器
  final StreamController<ConnectionQualityReport> _qualityController =
      StreamController<ConnectionQualityReport>.broadcast();

  /// 构造函数
  ConnectionMonitor({
    required this.config,
  });

  /// 获取连接质量流
  Stream<ConnectionQualityReport> get qualityStream =>
      _qualityController.stream;

  /// 获取当前质量等级
  ConnectionQuality get currentQuality => _currentQuality;

  /// 获取延迟历史
  List<double> get latencyHistory => List.unmodifiable(_latencyHistory);

  /// 获取连接事件历史
  List<ConnectionEvent> get connectionEvents =>
      List.unmodifiable(_connectionEvents);

  /// 开始监控
  void startMonitoring() {
    _monitorStartTime = DateTime.now();
    _startMetricsCollection();
    AppLogger.info('连接质量监控已启动');
  }

  /// 停止监控
  void stopMonitoring() {
    _metricsTimer?.cancel();
    _clearPendingMessages();
    AppLogger.info('连接质量监控已停止');
  }

  /// 记录消息发送
  void recordMessageSent(String messageId) {
    _pendingMessages[messageId] = DateTime.now();
  }

  /// 记录消息接收
  void recordMessageReceived(String messageId) {
    final sendTime = _pendingMessages.remove(messageId);
    if (sendTime != null) {
      final latency =
          DateTime.now().difference(sendTime).inMilliseconds.toDouble();
      _recordLatency(latency);
    }
  }

  /// 记录连接事件
  void recordConnectionEvent(
    ConnectionEventType type, {
    String? description,
    Map<String, dynamic>? details,
  }) {
    final event = ConnectionEvent(
      type: type,
      timestamp: DateTime.now(),
      description: description,
      details: details ?? {},
    );

    _connectionEvents.add(event);

    // 保持事件历史在合理范围内
    if (_connectionEvents.length > config.maxEventHistory) {
      _connectionEvents.removeRange(
          0, _connectionEvents.length - config.maxEventHistory);
    }

    // 评估连接质量
    _assessConnectionQuality();

    AppLogger.debug('记录连接事件', '$type: ${description ?? ""}');
  }

  /// 记录延迟
  void _recordLatency(double latency) {
    _latencyHistory.add(latency);

    // 保持延迟历史在合理范围内
    if (_latencyHistory.length > config.maxLatencyHistory) {
      _latencyHistory.removeRange(
          0, _latencyHistory.length - config.maxLatencyHistory);
    }

    // 触发质量评估
    _assessConnectionQuality();
  }

  /// 开始指标收集
  void _startMetricsCollection() {
    _metricsTimer?.cancel();
    _metricsTimer = Timer.periodic(config.metricsCollectionInterval, (_) {
      _collectMetrics();
    });
  }

  /// 收集指标
  void _collectMetrics() {
    final report = _generateQualityReport();
    _qualityController.add(report);
    _lastQualityAssessment = DateTime.now();
  }

  /// 评估连接质量
  void _assessConnectionQuality() {
    final newQuality = _calculateQuality();

    if (newQuality != _currentQuality) {
      final oldQuality = _currentQuality;
      _currentQuality = newQuality;

      AppLogger.info('连接质量变化', '$oldQuality -> $newQuality');

      // 立即发送质量报告
      final report = _generateQualityReport();
      _qualityController.add(report);
    }
  }

  /// 计算连接质量
  ConnectionQuality _calculateQuality() {
    if (_latencyHistory.isEmpty) {
      return ConnectionQuality.unknown;
    }

    double score = 100.0;

    // 延迟评分 (40% 权重)
    final avgLatency = _calculateAverageLatency();
    if (avgLatency > 1000) {
      score -= 40;
    } else if (avgLatency > 500) {
      score -= 25;
    } else if (avgLatency > 200) {
      score -= 10;
    } else if (avgLatency > 100) {
      score -= 5;
    }

    // 延迟稳定性评分 (20% 权重)
    final latencyStability = _calculateLatencyStability();
    score -= (1.0 - latencyStability) * 20;

    // 连接稳定性评分 (30% 权重)
    final connectionStability = _calculateConnectionStability();
    score -= (1.0 - connectionStability) * 30;

    // 丢包率评分 (10% 权重)
    final packetLoss = _calculatePacketLossRate();
    score -= packetLoss * 10;

    // 根据评分确定质量等级
    if (score >= 90) return ConnectionQuality.excellent;
    if (score >= 75) return ConnectionQuality.good;
    if (score >= 60) return ConnectionQuality.fair;
    if (score >= 40) return ConnectionQuality.poor;
    return ConnectionQuality.terrible;
  }

  /// 计算平均延迟
  double _calculateAverageLatency() {
    if (_latencyHistory.isEmpty) return 0.0;

    final sum = _latencyHistory.reduce((a, b) => a + b);
    return sum / _latencyHistory.length;
  }

  /// 计算延迟稳定性 (0-1, 1表示完全稳定)
  double _calculateLatencyStability() {
    if (_latencyHistory.length < 2) return 1.0;

    final avg = _calculateAverageLatency();
    final variance = _latencyHistory
            .map((latency) => pow(latency - avg, 2))
            .reduce((a, b) => a + b) /
        _latencyHistory.length;

    final standardDeviation = sqrt(variance);

    // 稳定性 = 1 - (标准差 / 平均值)
    if (avg == 0) return 1.0;
    return max(0.0, 1.0 - (standardDeviation / avg));
  }

  /// 计算连接稳定性 (0-1, 1表示完全稳定)
  double _calculateConnectionStability() {
    if (_connectionEvents.isEmpty) return 1.0;

    final now = DateTime.now();
    final recentEvents = _connectionEvents.where((event) =>
        now.difference(event.timestamp).inMinutes <=
        config.stabilityWindowMinutes);

    if (recentEvents.isEmpty) return 1.0;

    // 计算断开连接事件的比例
    final disconnectionEvents = recentEvents.where((event) =>
        event.type == ConnectionEventType.disconnected ||
        event.type == ConnectionEventType.error);

    final stabilityScore =
        1.0 - (disconnectionEvents.length / recentEvents.length);
    return stabilityScore.clamp(0.0, 1.0);
  }

  /// 计算丢包率 (0-1)
  double _calculatePacketLossRate() {
    final recentEvents = _connectionEvents
        .where((event) => event.type == ConnectionEventType.messageLost);

    if (_connectionEvents.isEmpty) return 0.0;

    return recentEvents.length / _connectionEvents.length;
  }

  /// 生成质量报告
  ConnectionQualityReport _generateQualityReport() {
    final now = DateTime.now();
    final avgLatency = _calculateAverageLatency();
    final latencyStability = _calculateLatencyStability();
    final connectionStability = _calculateConnectionStability();
    final packetLossRate = _calculatePacketLossRate();

    return ConnectionQualityReport(
      timestamp: now,
      quality: _currentQuality,
      averageLatency: avgLatency,
      latencyStability: latencyStability,
      connectionStability: connectionStability,
      packetLossRate: packetLossRate,
      totalMessages: _connectionEvents
          .where((e) => e.type == ConnectionEventType.messageReceived)
          .length,
      totalDisconnections: _connectionEvents
          .where((e) => e.type == ConnectionEventType.disconnected)
          .length,
      totalErrors: _connectionEvents
          .where((e) => e.type == ConnectionEventType.error)
          .length,
      uptime: _monitorStartTime != null
          ? now.difference(_monitorStartTime!)
          : Duration.zero,
    );
  }

  /// 清理待处理消息
  void _clearPendingMessages() {
    final now = DateTime.now();
    _pendingMessages.removeWhere((id, timestamp) {
      final age = now.difference(timestamp);
      if (age > const Duration(minutes: 5)) {
        recordConnectionEvent(
          ConnectionEventType.messageLost,
          description: '消息超时: $id',
          details: {'age': age.inMilliseconds},
        );
        return true;
      }
      return false;
    });
  }

  /// 获取监控统计信息
  Map<String, dynamic> getMonitoringStats() {
    return {
      'startTime': _monitorStartTime?.toIso8601String(),
      'lastAssessment': _lastQualityAssessment.toIso8601String(),
      'currentQuality': _currentQuality.toString(),
      'latencyCount': _latencyHistory.length,
      'eventCount': _connectionEvents.length,
      'pendingMessages': _pendingMessages.length,
      'averageLatency': _calculateAverageLatency(),
      'latencyStability': _calculateLatencyStability(),
      'connectionStability': _calculateConnectionStability(),
      'packetLossRate': _calculatePacketLossRate(),
      'uptime': _monitorStartTime != null
          ? DateTime.now().difference(_monitorStartTime!).inMilliseconds
          : 0,
    };
  }

  /// 重置监控数据
  void reset() {
    _latencyHistory.clear();
    _pendingMessages.clear();
    _connectionEvents.clear();
    _monitorStartTime = DateTime.now();
    _lastQualityAssessment = DateTime.now();
    _currentQuality = ConnectionQuality.unknown;

    AppLogger.info('连接质量监控数据已重置');
  }

  /// 销毁监控器
  void dispose() {
    stopMonitoring();
    _qualityController.close();
    AppLogger.info('连接质量监控器已销毁');
  }
}

/// 连接监控配置
class ConnectionMonitorConfig {
  /// 指标收集间隔
  final Duration metricsCollectionInterval;

  /// 延迟历史最大长度
  final int maxLatencyHistory;

  /// 事件历史最大长度
  final int maxEventHistory;

  /// 稳定性评估时间窗口（分钟）
  final int stabilityWindowMinutes;

  const ConnectionMonitorConfig({
    this.metricsCollectionInterval = const Duration(seconds: 5),
    this.maxLatencyHistory = 100,
    this.maxEventHistory = 200,
    this.stabilityWindowMinutes = 10,
  });
}

/// 连接质量枚举
enum ConnectionQuality {
  /// 优秀
  excellent,

  /// 良好
  good,

  /// 一般
  fair,

  /// 较差
  poor,

  /// 很差
  terrible,

  /// 未知
  unknown,
}

/// 连接事件类型
enum ConnectionEventType {
  /// 连接建立
  connected,

  /// 连接断开
  disconnected,

  /// 连接错误
  error,

  /// 消息发送
  messageSent,

  /// 消息接收
  messageReceived,

  /// 消息丢失
  messageLost,

  /// 重连开始
  reconnectStarted,

  /// 重连成功
  reconnectSucceeded,

  /// 重连失败
  reconnectFailed,
}

/// 连接事件
class ConnectionEvent {
  final ConnectionEventType type;
  final DateTime timestamp;
  final String? description;
  final Map<String, dynamic> details;

  const ConnectionEvent({
    required this.type,
    required this.timestamp,
    this.description,
    required this.details,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'timestamp': timestamp.toIso8601String(),
      'description': description,
      'details': details,
    };
  }

  @override
  String toString() {
    return 'ConnectionEvent(type: $type, timestamp: $timestamp, description: $description)';
  }
}

/// 连接质量报告
class ConnectionQualityReport {
  final DateTime timestamp;
  final ConnectionQuality quality;
  final double averageLatency;
  final double latencyStability;
  final double connectionStability;
  final double packetLossRate;
  final int totalMessages;
  final int totalDisconnections;
  final int totalErrors;
  final Duration uptime;

  const ConnectionQualityReport({
    required this.timestamp,
    required this.quality,
    required this.averageLatency,
    required this.latencyStability,
    required this.connectionStability,
    required this.packetLossRate,
    required this.totalMessages,
    required this.totalDisconnections,
    required this.totalErrors,
    required this.uptime,
  });

  /// 获取质量描述
  String get qualityDescription {
    switch (quality) {
      case ConnectionQuality.excellent:
        return '优秀';
      case ConnectionQuality.good:
        return '良好';
      case ConnectionQuality.fair:
        return '一般';
      case ConnectionQuality.poor:
        return '较差';
      case ConnectionQuality.terrible:
        return '很差';
      case ConnectionQuality.unknown:
        return '未知';
    }
  }

  /// 获取质量评分 (0-100)
  double get qualityScore {
    switch (quality) {
      case ConnectionQuality.excellent:
        return 90.0;
      case ConnectionQuality.good:
        return 75.0;
      case ConnectionQuality.fair:
        return 60.0;
      case ConnectionQuality.poor:
        return 40.0;
      case ConnectionQuality.terrible:
        return 20.0;
      case ConnectionQuality.unknown:
        return 0.0;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'quality': quality.toString(),
      'qualityDescription': qualityDescription,
      'qualityScore': qualityScore,
      'averageLatency': averageLatency,
      'latencyStability': latencyStability,
      'connectionStability': connectionStability,
      'packetLossRate': packetLossRate,
      'totalMessages': totalMessages,
      'totalDisconnections': totalDisconnections,
      'totalErrors': totalErrors,
      'uptime': uptime.inMilliseconds,
    };
  }

  @override
  String toString() {
    return 'ConnectionQualityReport('
        'quality: $quality, '
        'avgLatency: ${averageLatency.toStringAsFixed(1)}ms, '
        'messages: $totalMessages, '
        'disconnections: $totalDisconnections, '
        'errors: $totalErrors'
        ')';
  }
}
