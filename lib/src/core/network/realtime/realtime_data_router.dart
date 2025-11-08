import 'dart:async';
import '../hybrid/data_type.dart';
import '../utils/logger.dart';
import 'realtime_data_service.dart';

// ignore_for_file: directives_ordering, sort_constructors_first, public_member_api_docs, library_private_types_in_public_api

/// 实时数据路由器
///
/// 负责管理和路由实时数据，根据数据类型将数据分发给相应的处理器
class RealtimeDataRouter {
  /// 单例实例
  static final RealtimeDataRouter _instance = RealtimeDataRouter._internal();

  factory RealtimeDataRouter() => _instance;

  RealtimeDataRouter._internal() {
    _initialize();
  }

  /// 数据处理器映射
  final Map<DataType, List<RealtimeDataHandler>> _handlers = {};

  /// 服务映射
  final Map<DataType, List<RealtimeDataService>> _services = {};

  /// 路由统计
  final Map<DataType, _RoutingStats> _routingStats = {};

  /// 全局数据流
  final StreamController<RealtimeDataEvent> _globalDataController =
      StreamController<RealtimeDataEvent>.broadcast();

  /// 是否已初始化
  bool _isInitialized = false;

  /// 初始化路由器
  void _initialize() {
    if (_isInitialized) return;

    // 初始化统计信息
    for (final dataType in DataType.values) {
      _routingStats[dataType] = _RoutingStats(dataType);
    }

    _isInitialized = true;
    AppLogger.info('RealtimeDataRouter: 初始化完成');
  }

  /// 注册数据处理器
  void registerHandler(DataType dataType, RealtimeDataHandler handler) {
    _handlers.putIfAbsent(dataType, () => []).add(handler);
    AppLogger.debug(
        'RealtimeDataRouter: 注册处理器', '${dataType.name} -> ${handler.name}');
  }

  /// 取消注册数据处理器
  void unregisterHandler(DataType dataType, RealtimeDataHandler handler) {
    _handlers[dataType]?.remove(handler);
    if (_handlers[dataType]?.isEmpty ?? true) {
      _handlers.remove(dataType);
    }
    AppLogger.debug(
        'RealtimeDataRouter: 取消注册处理器', '${dataType.name} -> ${handler.name}');
  }

  /// 注册服务
  void registerService(DataType dataType, RealtimeDataService service) {
    _services.putIfAbsent(dataType, () => []).add(service);

    // 订阅服务的数据流
    service.dataStream.listen((event) {
      routeData(event);
    });

    AppLogger.debug(
        'RealtimeDataRouter: 注册服务', '${dataType.name} -> ${service.name}');
  }

  /// 取消注册服务
  void unregisterService(DataType dataType, RealtimeDataService service) {
    _services[dataType]?.remove(service);
    if (_services[dataType]?.isEmpty ?? true) {
      _services.remove(dataType);
    }
    AppLogger.debug(
        'RealtimeDataRouter: 取消注册服务', '${dataType.name} -> ${service.name}');
  }

  /// 路由数据事件
  Future<void> routeData(RealtimeDataEvent event) async {
    try {
      final stats = _routingStats[event.dataType];
      stats?.recordEvent();

      // 发送到全局数据流
      if (!_globalDataController.isClosed) {
        _globalDataController.add(event);
      }

      // 获取该数据类型的所有处理器
      final handlers = _handlers[event.dataType] ?? [];
      if (handlers.isEmpty) {
        AppLogger.warn('RealtimeDataRouter: 没有处理器处理数据类型', event.dataType.name);
        stats?.recordNoHandler();
        return;
      }

      stats?.recordHandlerCount(handlers.length);

      // 并行处理数据
      final futures = handlers.map((handler) => _handleData(handler, event));
      await Future.wait(futures);

      AppLogger.debug('RealtimeDataRouter: 数据路由完成',
          '${event.dataType.name} -> ${handlers.length}个处理器');
    } catch (e) {
      AppLogger.error('RealtimeDataRouter: 数据路由失败', e);
      final stats = _routingStats[event.dataType];
      stats?.recordError();
    }
  }

  /// 处理单个数据事件
  Future<void> _handleData(
      RealtimeDataHandler handler, RealtimeDataEvent event) async {
    try {
      await handler.handle(event);
    } catch (e) {
      AppLogger.error('RealtimeDataRouter: 处理器处理失败',
          '${handler.name}: ${event.dataType.name}: $e');
    }
  }

  /// 获取全局数据流
  Stream<RealtimeDataEvent> get globalDataStream =>
      _globalDataController.stream;

  /// 获取特定数据类型的数据流
  Stream<RealtimeDataEvent> getDataTypeStream(DataType dataType) {
    return globalDataStream.where((event) => event.dataType == dataType);
  }

  /// 获取路由统计信息
  Map<DataType, _RoutingStats> getRoutingStats() {
    return Map.unmodifiable(_routingStats);
  }

  /// 获取处理器信息
  Map<DataType, List<String>> getHandlerInfo() {
    return _handlers.map((dataType, handlers) => MapEntry(
          dataType,
          handlers.map((handler) => handler.name).toList(),
        ));
  }

  /// 获取服务信息
  Map<DataType, List<String>> getServiceInfo() {
    return _services.map((dataType, services) => MapEntry(
          dataType,
          services.map((service) => service.name).toList(),
        ));
  }

  /// 选择最佳服务
  RealtimeDataService? selectBestService(DataType dataType) {
    final services = _services[dataType] ?? [];
    if (services.isEmpty) return null;

    // 简单策略：选择第一个已连接的服务
    for (final service in services) {
      if (service.state == RealtimeServiceState.connected) {
        return service;
      }
    }

    // 如果没有已连接的服务，返回第一个可用的服务
    return services.first;
  }

  /// 获取路由健康状态
  Map<String, dynamic> getHealthStatus() {
    return {
      'initialized': _isInitialized,
      'totalDataTypes': DataType.values.length,
      'registeredDataTypes': _handlers.keys.length,
      'totalHandlers':
          _handlers.values.fold(0, (sum, handlers) => sum + handlers.length),
      'totalServices':
          _services.values.fold(0, (sum, services) => sum + services.length),
      'routingStats': _routingStats.map((dataType, stats) => MapEntry(
            dataType.name,
            stats.toJson(),
          )),
    };
  }

  /// 清理资源
  Future<void> dispose() async {
    await _globalDataController.close();
    _handlers.clear();
    _services.clear();
    _routingStats.clear();
    _isInitialized = false;
    AppLogger.info('RealtimeDataRouter: 资源清理完成');
  }
}

/// 实时数据处理器接口
abstract class RealtimeDataHandler {
  /// 处理器名称
  String get name;

  /// 支持的数据类型
  Set<DataType> get supportedDataTypes;

  /// 处理数据事件
  Future<void> handle(RealtimeDataEvent event);

  /// 获取处理器健康状态
  Future<Map<String, dynamic>> getHealthStatus();
}

/// 路由统计信息
class _RoutingStats {
  final DataType dataType;
  int totalEvents = 0;
  int noHandlerCount = 0;
  int errorCount = 0;
  int totalHandlerCount = 0;
  DateTime? lastEventTime;

  _RoutingStats(this.dataType);

  void recordEvent() {
    totalEvents++;
    lastEventTime = DateTime.now();
  }

  void recordNoHandler() {
    noHandlerCount++;
  }

  void recordError() {
    errorCount++;
  }

  void recordHandlerCount(int count) {
    totalHandlerCount += count;
  }

  double get averageHandlersPerEvent =>
      totalEvents > 0 ? totalHandlerCount / totalEvents : 0.0;
  double get errorRate => totalEvents > 0 ? errorCount / totalEvents : 0.0;

  Map<String, dynamic> toJson() {
    return {
      'dataType': dataType.name,
      'totalEvents': totalEvents,
      'noHandlerCount': noHandlerCount,
      'errorCount': errorCount,
      'totalHandlerCount': totalHandlerCount,
      'averageHandlersPerEvent': averageHandlersPerEvent,
      'errorRate': errorRate,
      'lastEventTime': lastEventTime?.toIso8601String(),
    };
  }
}

/// 示例数据处理器：日志处理器
class LoggingRealtimeHandler extends RealtimeDataHandler {
  @override
  String get name => 'LoggingRealtimeHandler';

  @override
  Set<DataType> get supportedDataTypes => {
        DataType.fundRanking,
        DataType.etfSpotData,
        DataType.lofSpotData,
        DataType.marketIndex,
      };

  @override
  Future<void> handle(RealtimeDataEvent event) async {
    AppLogger.info('LoggingRealtimeHandler: 处理实时数据',
        '${event.dataType.name}: ${event.eventType.name}');
  }

  @override
  Future<Map<String, dynamic>> getHealthStatus() async {
    return {
      'name': name,
      'status': 'healthy',
      'supportedDataTypes': supportedDataTypes.map((t) => t.name).toList(),
    };
  }
}

/// 示例数据处理器：缓存处理器
class CacheRealtimeHandler extends RealtimeDataHandler {
  @override
  String get name => 'CacheRealtimeHandler';

  @override
  Set<DataType> get supportedDataTypes => {
        DataType.fundRanking,
        DataType.etfSpotData,
        DataType.lofSpotData,
        DataType.marketIndex,
        DataType.fundNetValue,
      };

  int _processedCount = 0;
  DateTime? _lastProcessedTime;

  @override
  Future<void> handle(RealtimeDataEvent event) async {
    // 这里可以更新缓存数据
    _processedCount++;
    _lastProcessedTime = DateTime.now();

    AppLogger.debug('CacheRealtimeHandler: 更新缓存',
        '${event.dataType.name} (总计: $_processedCount)');
  }

  @override
  Future<Map<String, dynamic>> getHealthStatus() async {
    return {
      'name': name,
      'status': 'healthy',
      'processedCount': _processedCount,
      'lastProcessedTime': _lastProcessedTime?.toIso8601String(),
      'supportedDataTypes': supportedDataTypes.map((t) => t.name).toList(),
    };
  }
}
