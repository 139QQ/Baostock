import 'dart:async';
import 'package:flutter/foundation.dart';
import '../utils/logger.dart';
import 'data_type.dart';
import 'data_fetch_strategy.dart';
import 'hybrid_data_manager.dart';

/// 实时数据服务抽象接口
///
/// 定义了实时数据获取的标准接口，支持多种实现方式
/// 为未来WebSocket扩展和当前HTTP轮询提供统一的抽象层
abstract class RealtimeDataService {
  /// 服务名称
  String get name;

  /// 服务版本
  String get version;

  /// 当前服务状态
  ServiceState get state;

  /// 支持的数据类型
  List<DataType> get supportedDataTypes;

  /// 状态变化流
  Stream<ServiceState> get stateStream;

  /// 数据更新流
  Stream<DataItem> get dataStream;

  /// 连接质量指标
  Stream<ConnectionQuality> get qualityStream;

  /// 启动服务
  Future<void> start();

  /// 停止服务
  Future<void> stop();

  /// 获取单个数据项
  Future<DataItem?> getData(DataType type, {Map<String, dynamic>? parameters});

  /// 获取数据流
  Stream<DataItem> getDataStream(DataType type,
      {Map<String, dynamic>? parameters});

  /// 更新服务配置
  void updateConfig(RealtimeServiceConfig config);

  /// 获取服务健康状态
  Future<Map<String, dynamic>> getHealthStatus();

  /// 获取服务性能指标
  Map<String, dynamic> getPerformanceMetrics();

  /// 检查服务是否支持指定数据类型
  bool supportsDataType(DataType type);
}

/// 服务状态枚举
enum ServiceState {
  idle('空闲'),
  initializing('初始化中'),
  connecting('连接中'),
  connected('已连接'),
  disconnecting('断开中'),
  disconnected('已断开'),
  reconnecting('重连中'),
  error('错误'),
  maintenance('维护中');

  const ServiceState(this.description);
  final String description;

  /// 检查是否为活动状态
  bool get isActive {
    switch (this) {
      case ServiceState.connected:
      case ServiceState.connecting:
      case ServiceState.reconnecting:
        return true;
      default:
        return false;
    }
  }

  /// 检查是否为健康状态
  bool get isHealthy {
    switch (this) {
      case ServiceState.connected:
      case ServiceState.idle:
      case ServiceState.initializing:
        return true;
      default:
        return false;
    }
  }
}

/// 连接质量指标
class ConnectionQuality {
  /// 连接状态
  final bool isConnected;

  /// 延迟 (毫秒)
  final int latency;

  /// 丢包率 (0-1)
  final double packetLoss;

  /// 带宽使用情况 (0-1)
  final double bandwidthUsage;

  /// 信号强度 (0-4)
  final int signalStrength;

  /// 质量评分 (0-100)
  final int score;

  /// 最后更新时间
  final DateTime lastUpdated;

  const ConnectionQuality({
    required this.isConnected,
    required this.latency,
    this.packetLoss = 0.0,
    this.bandwidthUsage = 0.0,
    this.signalStrength = 0,
    required this.score,
    required this.lastUpdated,
  });

  /// 质量等级
  QualityLevel get qualityLevel {
    if (score >= 90) return QualityLevel.excellent;
    if (score >= 75) return QualityLevel.good;
    if (score >= 50) return QualityLevel.fair;
    if (score >= 25) return QualityLevel.poor;
    return QualityLevel.terrible;
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'isConnected': isConnected,
      'latency': latency,
      'packetLoss': packetLoss,
      'bandwidthUsage': bandwidthUsage,
      'signalStrength': signalStrength,
      'score': score,
      'qualityLevel': qualityLevel.name,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

/// 质量等级
enum QualityLevel {
  excellent('优秀'),
  good('良好'),
  fair('一般'),
  poor('较差'),
  terrible('很差');

  const QualityLevel(this.description);
  final String description;
}

/// 实时服务配置
class RealtimeServiceConfig {
  /// 自动重连
  final bool autoReconnect;

  /// 最大重连次数
  final int maxReconnectAttempts;

  /// 重连间隔
  final Duration reconnectInterval;

  /// 心跳间隔
  final Duration heartbeatInterval;

  /// 连接超时
  final Duration connectionTimeout;

  /// 数据更新频率
  final Map<DataType, Duration> updateFrequencies;

  /// 缓存设置
  final CacheConfig cacheConfig;

  /// 性能设置
  final PerformanceConfig performanceConfig;

  const RealtimeServiceConfig({
    this.autoReconnect = true,
    this.maxReconnectAttempts = 5,
    this.reconnectInterval = const Duration(seconds: 5),
    this.heartbeatInterval = const Duration(seconds: 30),
    this.connectionTimeout = const Duration(seconds: 10),
    this.updateFrequencies = const {},
    this.cacheConfig = const CacheConfig(),
    this.performanceConfig = const PerformanceConfig(),
  });

  /// 获取指定数据类型的更新频率
  Duration getUpdateFrequency(DataType type) {
    return updateFrequencies[type] ?? type.defaultUpdateInterval;
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'autoReconnect': autoReconnect,
      'maxReconnectAttempts': maxReconnectAttempts,
      'reconnectInterval': reconnectInterval.inSeconds,
      'heartbeatInterval': heartbeatInterval.inSeconds,
      'connectionTimeout': connectionTimeout.inSeconds,
      'updateFrequencies': updateFrequencies.map(
        (key, value) => MapEntry(key.code, value.inSeconds),
      ),
      'cacheConfig': cacheConfig.toJson(),
      'performanceConfig': performanceConfig.toJson(),
    };
  }

  /// 从JSON创建配置
  factory RealtimeServiceConfig.fromJson(Map<String, dynamic> json) {
    return RealtimeServiceConfig(
      autoReconnect: json['autoReconnect'] as bool? ?? true,
      maxReconnectAttempts: json['maxReconnectAttempts'] as int? ?? 5,
      reconnectInterval:
          Duration(seconds: json['reconnectInterval'] as int? ?? 5),
      heartbeatInterval:
          Duration(seconds: json['heartbeatInterval'] as int? ?? 30),
      connectionTimeout:
          Duration(seconds: json['connectionTimeout'] as int? ?? 10),
      updateFrequencies:
          (json['updateFrequencies'] as Map<String, dynamic>? ?? {})
              .map((key, value) {
        final dataType = DataType.fromCode(key);
        if (dataType != null) {
          return MapEntry(dataType, Duration(seconds: value as int));
        }
        return MapEntry(DataType.fundNetValue, Duration(seconds: value as int));
      }),
      cacheConfig: CacheConfig.fromJson(
          json['cacheConfig'] as Map<String, dynamic>? ?? {}),
      performanceConfig: PerformanceConfig.fromJson(
          json['performanceConfig'] as Map<String, dynamic>? ?? {}),
    );
  }
}

/// 缓存配置
class CacheConfig {
  /// 是否启用缓存
  final bool enabled;

  /// 最大缓存大小
  final int maxSize;

  /// 缓存过期时间
  final Duration defaultExpiration;

  /// 不同数据类型的缓存策略
  final Map<DataType, CacheStrategy> strategies;

  const CacheConfig({
    this.enabled = true,
    this.maxSize = 1000,
    this.defaultExpiration = const Duration(minutes: 15),
    this.strategies = const {},
  });

  /// 获取指定数据类型的缓存策略
  CacheStrategy getStrategy(DataType type) {
    return strategies[type] ?? CacheStrategy.memory;
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'maxSize': maxSize,
      'defaultExpiration': defaultExpiration.inSeconds,
      'strategies': strategies.map(
        (key, value) => MapEntry(key.code, value.name),
      ),
    };
  }

  /// 从JSON创建配置
  factory CacheConfig.fromJson(Map<String, dynamic> json) {
    return CacheConfig(
      enabled: json['enabled'] as bool? ?? true,
      maxSize: json['maxSize'] as int? ?? 1000,
      defaultExpiration:
          Duration(seconds: json['defaultExpiration'] as int? ?? 900),
      strategies:
          (json['strategies'] as Map<String, dynamic>? ?? {}).map((key, value) {
        final dataType = DataType.fromCode(key);
        if (dataType != null) {
          final strategy = CacheStrategy.values.firstWhere(
              (s) => s.name == value,
              orElse: () => CacheStrategy.memory);
          return MapEntry(dataType, strategy);
        }
        return MapEntry(DataType.fundNetValue, CacheStrategy.memory);
      }),
    );
  }
}

/// 缓存策略
enum CacheStrategy {
  memory,
  disk,
  hybrid,
  none;
}

/// 性能配置
class PerformanceConfig {
  /// 最大并发请求数
  final int maxConcurrentRequests;

  /// 请求队列大小
  final int requestQueueSize;

  /// 是否启用压缩
  final bool enableCompression;

  /// 批量请求大小
  final int batchSize;

  /// 性能监控间隔
  final Duration monitoringInterval;

  const PerformanceConfig({
    this.maxConcurrentRequests = 10,
    this.requestQueueSize = 100,
    this.enableCompression = true,
    this.batchSize = 50,
    this.monitoringInterval = const Duration(minutes: 1),
  });

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'maxConcurrentRequests': maxConcurrentRequests,
      'requestQueueSize': requestQueueSize,
      'enableCompression': enableCompression,
      'batchSize': batchSize,
      'monitoringInterval': monitoringInterval.inSeconds,
    };
  }

  /// 从JSON创建配置
  factory PerformanceConfig.fromJson(Map<String, dynamic> json) {
    return PerformanceConfig(
      maxConcurrentRequests: json['maxConcurrentRequests'] as int? ?? 10,
      requestQueueSize: json['requestQueueSize'] as int? ?? 100,
      enableCompression: json['enableCompression'] as bool? ?? true,
      batchSize: json['batchSize'] as int? ?? 50,
      monitoringInterval:
          Duration(seconds: json['monitoringInterval'] as int? ?? 60),
    );
  }
}

/// 基础实时数据服务实现
abstract class BaseRealtimeDataService implements RealtimeDataService {
  /// 服务状态
  ServiceState _state = ServiceState.idle;

  /// 状态流控制器
  final StreamController<ServiceState> _stateController =
      StreamController<ServiceState>.broadcast();

  /// 数据流控制器
  final StreamController<DataItem> _dataController =
      StreamController<DataItem>.broadcast();

  /// 质量流控制器
  final StreamController<ConnectionQuality> _qualityController =
      StreamController<ConnectionQuality>.broadcast();

  /// 服务配置
  RealtimeServiceConfig _config;

  /// 性能指标
  final Map<String, dynamic> _performanceMetrics = {};

  /// 错误计数器
  int _errorCount = 0;

  /// 最后错误时间
  DateTime? _lastErrorTime;

  /// 启动时间
  DateTime? _startTime;

  BaseRealtimeDataService(this._config);

  @override
  ServiceState get state => _state;

  @override
  Stream<ServiceState> get stateStream => _stateController.stream;

  @override
  Stream<DataItem> get dataStream => _dataController.stream;

  @override
  Stream<ConnectionQuality> get qualityStream => _qualityController.stream;

  @override
  void updateConfig(RealtimeServiceConfig config) {
    _config = config;
    AppLogger.info('Updated $name configuration');
  }

  /// 更新服务状态
  void _updateState(ServiceState newState) {
    if (_state != newState) {
      final oldState = _state;
      _state = newState;
      _stateController.add(newState);
      AppLogger.info(
          '$name state changed: ${oldState.name} → ${newState.name}');

      if (newState == ServiceState.connected && _startTime == null) {
        _startTime = DateTime.now();
      }
    }
  }

  /// 记录错误
  void _recordError(String error) {
    _errorCount++;
    _lastErrorTime = DateTime.now();
    AppLogger.error('$name error: $error');

    if (_state.isHealthy) {
      _updateState(ServiceState.error);
    }
  }

  /// 发送数据项
  void _emitDataItem(DataItem dataItem) {
    if (!_dataController.isClosed) {
      _dataController.add(dataItem);
    }
  }

  /// 发送连接质量更新
  void _emitConnectionQuality(ConnectionQuality quality) {
    if (!_qualityController.isClosed) {
      _qualityController.add(quality);
    }
  }

  @override
  Map<String, dynamic> getPerformanceMetrics() {
    final uptime = _startTime != null
        ? DateTime.now().difference(_startTime!)
        : Duration.zero;

    return {
      'uptime': uptime.inSeconds,
      'errorCount': _errorCount,
      'lastErrorTime': _lastErrorTime?.toIso8601String(),
      'state': _state.name,
      'supportedDataTypes': supportedDataTypes.map((t) => t.code).toList(),
      ..._performanceMetrics,
    };
  }

  @override
  Future<Map<String, dynamic>> getHealthStatus() async {
    return {
      'service': name,
      'version': version,
      'state': _state.name,
      'isHealthy': _state.isHealthy,
      'isActive': _state.isActive,
      'errorCount': _errorCount,
      'lastErrorTime': _lastErrorTime?.toIso8601String(),
      'supportedDataTypes': supportedDataTypes.map((t) => t.code).toList(),
      'performance': getPerformanceMetrics(),
    };
  }

  @override
  bool supportsDataType(DataType type) {
    return supportedDataTypes.contains(type);
  }

  /// 释放资源
  void dispose() {
    _updateState(ServiceState.disconnected);
    _stateController.close();
    _dataController.close();
    _qualityController.close();
  }
}
