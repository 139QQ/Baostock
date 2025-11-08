import 'dart:async';
import 'data_type.dart';
import '../realtime/websocket_models.dart';

/// 数据项模型
class DataItem {
  /// 数据类型
  final DataType dataType;

  /// 数据内容
  final dynamic data;

  /// 时间戳
  final DateTime timestamp;

  /// 数据质量级别
  final DataQualityLevel quality;

  /// 数据来源
  final DataSource source;

  /// 数据唯一标识符
  final String id;

  /// 数据键 (用于缓存)
  final String dataKey;

  /// 缓存过期时间
  final DateTime? expiresAt;

  /// 元数据
  final Map<String, dynamic>? metadata;

  const DataItem({
    required this.dataType,
    required this.data,
    required this.timestamp,
    required this.quality,
    required this.source,
    required this.id,
    this.dataKey = 'default',
    this.expiresAt,
    this.metadata,
  });

  /// 检查数据是否过期
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// 获取数据年龄
  Duration get age => DateTime.now().difference(timestamp);

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'dataType': dataType.code,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'quality': quality.name,
      'source': source.name,
      'id': id,
      'dataKey': dataKey,
      'expiresAt': expiresAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// 从JSON创建数据项
  factory DataItem.fromJson(Map<String, dynamic> json) {
    final dataType = DataType.fromCode(json['dataType'] as String);
    if (dataType == null) {
      throw ArgumentError('Unknown data type: ${json['dataType']}');
    }

    return DataItem(
      dataType: dataType,
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp'] as String),
      quality: DataQualityLevel.values.firstWhere(
        (level) => level.name == json['quality'],
        orElse: () => DataQualityLevel.unknown,
      ),
      source: DataSource.values.firstWhere(
        (source) => source.name == json['source'],
        orElse: () => DataSource.unknown,
      ),
      id: json['id'] as String,
      dataKey: json['dataKey'] as String? ?? 'default',
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

/// 数据来源枚举
enum DataSource {
  websocket,
  httpPolling,
  httpOnDemand,
  http,
  cache,
  unknown;

  String get description {
    switch (this) {
      case DataSource.websocket:
        return 'WebSocket实时数据';
      case DataSource.httpPolling:
        return 'HTTP轮询数据';
      case DataSource.httpOnDemand:
        return 'HTTP按需请求';
      case DataSource.http:
        return 'HTTP请求数据';
      case DataSource.cache:
        return '缓存数据';
      case DataSource.unknown:
        return '未知来源';
    }
  }
}

/// 数据获取策略结果
class FetchResult {
  /// 是否成功
  final bool success;

  /// 数据项 (如果成功)
  final DataItem? dataItem;

  /// 错误信息 (如果失败)
  final String? errorMessage;

  /// 重试建议
  final bool shouldRetry;

  /// 等待重试时间
  final Duration? retryDelay;

  /// 数据质量指标
  final Map<String, dynamic>? qualityMetrics;

  const FetchResult.success(this.dataItem, {this.qualityMetrics})
      : success = true,
        errorMessage = null,
        shouldRetry = false,
        retryDelay = null;

  const FetchResult.failure(
    this.errorMessage, {
    this.shouldRetry = true,
    this.retryDelay = const Duration(seconds: 5),
    this.qualityMetrics,
  })  : success = false,
        dataItem = null;
}

/// 数据获取策略抽象接口
abstract class DataFetchStrategy {
  /// 策略名称
  String get name;

  /// 策略优先级
  int get priority;

  /// 支持的数据类型
  List<DataType> get supportedDataTypes;

  /// 当前是否可用
  bool isAvailable();

  /// 策略是否支持指定数据类型
  bool supportsDataType(DataType type) {
    return supportedDataTypes.contains(type);
  }

  /// 获取数据流
  Stream<DataItem> getDataStream(DataType type,
      {Map<String, dynamic>? parameters});

  /// 单次获取数据
  Future<FetchResult> fetchData(DataType type,
      {Map<String, dynamic>? parameters});

  /// 获取策略健康状态
  Future<Map<String, dynamic>> getHealthStatus();

  /// 启动策略
  Future<void> start();

  /// 停止策略
  Future<void> stop();

  /// 获取默认轮询间隔 (如果适用)
  Duration? getDefaultPollingInterval(DataType type) {
    return null;
  }

  /// 获取策略配置信息
  Map<String, dynamic> getConfig();
}

/// 策略状态枚举
enum StrategyState {
  idle('空闲'),
  starting('启动中'),
  running('运行中'),
  stopping('停止中'),
  stopped('已停止'),
  error('错误');

  const StrategyState(this.description);
  final String description;
}

/// 基础数据获取策略实现
abstract class BaseDataFetchStrategy implements DataFetchStrategy {
  /// 策略状态
  StrategyState _state = StrategyState.idle;

  /// 错误计数器
  int _errorCount = 0;

  /// 最后错误时间
  DateTime? _lastErrorTime;

  /// 健康检查计时器
  Timer? _healthCheckTimer;

  @override
  StrategyState get state => _state;

  @override
  bool isAvailable() {
    return _state == StrategyState.running;
  }

  /// 更新策略状态
  void _updateState(StrategyState newState) {
    _state = newState;
  }

  /// 记录错误
  void _recordError(String error) {
    _errorCount++;
    _lastErrorTime = DateTime.now();
    _updateState(StrategyState.error);
  }

  /// 清除错误状态
  void _clearError() {
    _errorCount = 0;
    _lastErrorTime = null;
    if (_state == StrategyState.error) {
      _updateState(StrategyState.running);
    }
  }

  /// 启动健康检查
  void _startHealthCheck(Duration interval) {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(interval, (_) async {
      try {
        final healthStatus = await getHealthStatus();
        if (healthStatus['healthy'] == true) {
          _clearError();
        }
      } catch (e) {
        _recordError('Health check failed: $e');
      }
    });
  }

  /// 停止健康检查
  void _stopHealthCheck() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
  }

  @override
  Future<void> start() async {
    if (_state == StrategyState.running) return;

    _updateState(StrategyState.starting);
    try {
      await onStart();
      _updateState(StrategyState.running);
      _startHealthCheck(const Duration(minutes: 1));
    } catch (e) {
      _recordError('Failed to start strategy: $e');
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    if (_state == StrategyState.stopped) return;

    _updateState(StrategyState.stopping);
    try {
      await onStop();
      _stopHealthCheck();
      _updateState(StrategyState.stopped);
    } catch (e) {
      _recordError('Failed to stop strategy: $e');
      rethrow;
    }
  }

  /// 子类实现的启动逻辑
  Future<void> onStart();

  /// 子类实现的停止逻辑
  Future<void> onStop();

  @override
  Future<Map<String, dynamic>> getHealthStatus() async {
    return {
      'strategy': name,
      'state': _state.name,
      'isAvailable': isAvailable(),
      'errorCount': _errorCount,
      'lastErrorTime': _lastErrorTime?.toIso8601String(),
      'priority': priority,
      'supportedDataTypes': supportedDataTypes.map((t) => t.code).toList(),
    };
  }

  @override
  Map<String, dynamic> getConfig() {
    return {
      'name': name,
      'priority': priority,
      'state': _state.name,
      'supportedDataTypes': supportedDataTypes.map((t) => t.code).toList(),
    };
  }
}
