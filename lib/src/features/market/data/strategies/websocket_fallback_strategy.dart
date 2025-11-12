import 'dart:async';

import '../../../../core/network/hybrid/data_fetch_strategy.dart';
import '../../../../core/network/hybrid/data_type.dart';
import '../../../../core/utils/logger.dart';
import 'index_strategy_selector.dart';
import 'websocket_index_strategy.dart';

/// WebSocket降级策略
///
/// 当WebSocket连接失败时自动降级到HTTP轮询策略
class WebSocketFallbackStrategy extends DataFetchStrategy {
  @override
  String get name => 'WebSocketFallbackStrategy';

  @override
  int get priority => 85; // 高优先级，但低于纯WebSocket

  @override
  List<DataType> get supportedDataTypes => [DataType.marketIndex];

  /// 重试间隔
  Duration get defaultRetryInterval => const Duration(seconds: 2);

  /// 最大重试次数
  int get maxRetries => 5;

  /// WebSocket策略
  WebSocketIndexStrategy? _websocketStrategy;

  /// HTTP轮询策略
  final DataFetchStrategy? _httpPollingStrategy;

  /// 策略选择器
  IndexStrategySelector? _strategySelector;

  /// 降级配置
  final FallbackConfig _config;

  /// 当前使用策略
  DataFetchStrategy? _currentStrategy;

  /// 降级状态
  FallbackState _fallbackState = FallbackState.none;

  /// 降级历史
  final List<FallbackRecord> _fallbackHistory = [];

  /// 重连定时器
  Timer? _reconnectTimer;

  /// 健康检查定时器
  Timer? _healthCheckTimer;

  /// 降级统计
  final FallbackStatistics _statistics = FallbackStatistics();

  /// 状态流控制器
  final StreamController<FallbackState> _stateController =
      StreamController<FallbackState>.broadcast();

  /// 创建WebSocket降级策略实例
  WebSocketFallbackStrategy({
    WebSocketIndexStrategy? websocketStrategy,
    DataFetchStrategy? httpPollingStrategy,
    IndexStrategySelector? strategySelector,
    FallbackConfig? config,
  })  : _websocketStrategy = websocketStrategy,
        _httpPollingStrategy = httpPollingStrategy,
        _strategySelector = strategySelector,
        _config = config ?? const FallbackConfig() {
    _initializeStrategies();
    _startHealthMonitoring();
  }

  /// 初始化策略
  void _initializeStrategies() {
    // 如果没有提供策略，创建默认策略
    _websocketStrategy ??= WebSocketIndexStrategy();

    if (_httpPollingStrategy == null) {
      // 这里应该创建HTTP轮询策略
      // 暂时设为null，需要在实际使用时注入
      AppLogger.warn('HTTP polling strategy not provided');
    }

    _strategySelector ??= IndexStrategySelector();

    // 初始选择WebSocket策略
    _currentStrategy = _websocketStrategy;
    _updateFallbackState(FallbackState.websocket);
  }

  /// 开始健康监控
  void _startHealthMonitoring() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(_config.healthCheckInterval, (_) {
      Future.microtask(_performHealthCheck);
    });
  }

  /// 执行健康检查
  Future<void> _performHealthCheck() async {
    if (_currentStrategy == null) return;

    final isHealthy = await _isStrategyHealthy(_currentStrategy!);

    if (!isHealthy) {
      AppLogger.warn(
          'Strategy ${_currentStrategy!.name} is unhealthy, considering fallback');
      Future.microtask(_evaluateFallback);
    }
  }

  /// 检查策略健康状态
  Future<bool> _isStrategyHealthy(DataFetchStrategy strategy) async {
    if (strategy is WebSocketIndexStrategy) {
      // 使用专门的连接健康状态方法
      final healthStatus = strategy.getConnectionHealthStatus();
      return healthStatus.isConnected && healthStatus.isHealthy;
    } else {
      // 使用基类的 Future<Map<String, dynamic>> 版本
      final healthStatusMap = await strategy.getHealthStatus();
      return healthStatusMap['healthy'] == true ||
          healthStatusMap['isHealthy'] == true;
    }

    // 对于其他策略，可以通过策略选择器获取健康状态
    if (_strategySelector != null) {
      final health = _strategySelector!.getHealthStatus(strategy.name);
      return health?.isHealthy ?? true;
    }

    return true; // 默认认为健康
  }

  /// 评估是否需要降级
  Future<void> _evaluateFallback() async {
    if (_currentStrategy == null) return;

    final currentStrategy = _currentStrategy!;
    bool shouldFallback = false;
    String fallbackReason = '';

    // WebSocket策略降级条件
    if (currentStrategy is WebSocketIndexStrategy) {
      final wsStrategy = currentStrategy;
      final healthStatus = wsStrategy.getConnectionHealthStatus();

      if (!healthStatus.isConnected) {
        shouldFallback = true;
        fallbackReason = 'WebSocket disconnected';
      } else if (!healthStatus.isHealthy) {
        shouldFallback = true;
        fallbackReason = 'WebSocket unhealthy: connection issues detected';
      }
    } else {
      // 对于其他策略，检查基类的健康状态
      final healthStatusMap = await currentStrategy.getHealthStatus();
      final isHealthy = healthStatusMap['healthy'] == true ||
          healthStatusMap['isHealthy'] == true;

      if (!isHealthy) {
        shouldFallback = true;
        fallbackReason =
            'Strategy unhealthy: ${healthStatusMap['reason'] ?? 'Unknown reason'}';
      }
    }

    // 通用降级条件
    final metrics =
        _strategySelector?.getPerformanceMetrics(currentStrategy.name);
    if (metrics != null) {
      if (metrics.successRate < _config.minSuccessRate) {
        shouldFallback = true;
        fallbackReason = 'Success rate too low: ${metrics.successRate}';
      } else if (metrics.averageLatency > _config.maxAcceptableLatency) {
        shouldFallback = true;
        fallbackReason =
            'Latency too high: ${metrics.averageLatency.inMilliseconds}ms';
      }
    }

    if (shouldFallback) {
      _performFallback(currentStrategy, fallbackReason);
    }
  }

  /// 执行降级
  void _performFallback(DataFetchStrategy fromStrategy, String reason) {
    DataFetchStrategy? targetStrategy;

    // 确定目标策略
    if (fromStrategy is WebSocketIndexStrategy &&
        _httpPollingStrategy != null) {
      targetStrategy = _httpPollingStrategy!;
    } else {
      // 通过策略选择器获取最佳备用策略
      targetStrategy = _strategySelector?.selectBestStrategy(
        dataType: 'market_index',
        criteria: _config.fallbackCriteria,
      );
    }

    if (targetStrategy == null) {
      AppLogger.error('No fallback strategy available', null);
      return;
    }

    // 记录降级
    final fallbackRecord = FallbackRecord(
      fromStrategy: fromStrategy.name,
      toStrategy: targetStrategy.name,
      timestamp: DateTime.now(),
      reason: reason,
      fallbackType: _determineFallbackType(fromStrategy, targetStrategy),
    );

    _fallbackHistory.add(fallbackRecord);
    _statistics.recordFallback(fromStrategy.name, targetStrategy.name, reason);

    // 保持历史记录在合理范围内
    while (_fallbackHistory.length > _config.maxFallbackHistory) {
      _fallbackHistory.removeAt(0);
    }

    // 切换策略
    _currentStrategy = targetStrategy;
    _updateFallbackState(_determineFallbackState(targetStrategy));

    AppLogger.info(
        'Performed fallback: ${fromStrategy.name} → ${targetStrategy.name} ($reason)');

    // 如果从WebSocket降级，安排重连
    if (fromStrategy is WebSocketIndexStrategy) {
      _scheduleWebSocketReconnect();
    }
  }

  /// 确定降级类型
  FallbackType _determineFallbackType(
      DataFetchStrategy from, DataFetchStrategy to) {
    if (from is WebSocketIndexStrategy && to.name.contains('polling')) {
      return FallbackType.websocketToPolling;
    } else if (from.name.contains('polling') && to is WebSocketIndexStrategy) {
      return FallbackType.pollingToWebsocket;
    } else {
      return FallbackType.unknown;
    }
  }

  /// 确定降级状态
  FallbackState _determineFallbackState(DataFetchStrategy strategy) {
    if (strategy is WebSocketIndexStrategy) {
      return FallbackState.websocket;
    } else if (strategy.name.contains('polling')) {
      return FallbackState.httpPolling;
    } else {
      return FallbackState.unknown;
    }
  }

  /// 更新降级状态
  void _updateFallbackState(FallbackState newState) {
    if (_fallbackState != newState) {
      final oldState = _fallbackState;
      _fallbackState = newState;
      _stateController.add(newState);

      AppLogger.info(
          'Fallback state changed: ${oldState.name} → ${newState.name}');
    }
  }

  /// 安排WebSocket重连
  void _scheduleWebSocketReconnect() {
    _reconnectTimer?.cancel();

    _reconnectTimer = Timer(_config.websocketReconnectDelay, () async {
      if (_websocketStrategy == null) return;

      AppLogger.info('Attempting to reconnect WebSocket...');

      try {
        final reconnected = await _websocketStrategy!.connect();
        if (reconnected) {
          _performUpgrade(
              _websocketStrategy!, 'WebSocket reconnected successfully');
        }
      } catch (e) {
        AppLogger.error('WebSocket reconnection failed: $e', e);
        // 安排下一次重连
        _scheduleWebSocketReconnect();
      }
    });
  }

  /// 执行升级（从降级策略恢复到原始策略）
  void _performUpgrade(DataFetchStrategy targetStrategy, String reason) {
    if (_currentStrategy == null) return;

    final upgradeRecord = FallbackRecord(
      fromStrategy: _currentStrategy!.name,
      toStrategy: targetStrategy.name,
      timestamp: DateTime.now(),
      reason: reason,
      fallbackType: _determineFallbackType(_currentStrategy!, targetStrategy),
    );

    _fallbackHistory.add(upgradeRecord);
    _statistics.recordUpgrade(
        _currentStrategy!.name, targetStrategy.name, reason);

    // 切换策略
    _currentStrategy = targetStrategy;
    _updateFallbackState(_determineFallbackState(targetStrategy));

    // 取消重连定时器
    _reconnectTimer?.cancel();

    AppLogger.info(
        'Performed upgrade: ${upgradeRecord.fromStrategy} → ${upgradeRecord.toStrategy} ($reason)');
  }

  /// 手动触发降级
  bool forceFallback({String? targetStrategyName}) {
    if (_currentStrategy == null) return false;

    DataFetchStrategy? targetStrategy;

    if (targetStrategyName != null) {
      // 查找指定策略
      if (_websocketStrategy?.name == targetStrategyName) {
        targetStrategy = _websocketStrategy!;
      } else if (_httpPollingStrategy?.name == targetStrategyName) {
        targetStrategy = _httpPollingStrategy!;
      } else {
        AppLogger.error('Target strategy not found: $targetStrategyName', null);
        return false;
      }
    } else {
      // 自动选择最佳降级策略
      targetStrategy = _strategySelector?.selectBestStrategy(
        dataType: 'market_index',
        criteria: _config.fallbackCriteria,
      );

      if (targetStrategy == null || targetStrategy == _currentStrategy) {
        AppLogger.warn('No suitable fallback strategy available');
        return false;
      }
    }

    _performFallback(_currentStrategy!, 'Manual fallback triggered');
    return true;
  }

  /// 手动触发升级
  Future<bool> forceUpgrade({String? targetStrategyName}) async {
    if (_currentStrategy == null) return false;

    DataFetchStrategy? targetStrategy;

    if (targetStrategyName != null) {
      // 查找指定策略
      if (_websocketStrategy?.name == targetStrategyName) {
        targetStrategy = _websocketStrategy!;
      } else if (_httpPollingStrategy?.name == targetStrategyName) {
        targetStrategy = _httpPollingStrategy!;
      } else {
        AppLogger.error('Target strategy not found: $targetStrategyName', null);
        return false;
      }
    } else {
      // 优先升级到WebSocket
      if (_websocketStrategy != null &&
          await _isStrategyHealthy(_websocketStrategy!)) {
        targetStrategy = _websocketStrategy!;
      } else {
        AppLogger.warn('No healthy upgrade strategy available');
        return false;
      }
    }

    if (targetStrategy == _currentStrategy) {
      AppLogger.info('Already using target strategy: ${targetStrategy.name}');
      return true;
    }

    _performUpgrade(targetStrategy, 'Manual upgrade triggered');
    return true;
  }

  /// 获取当前策略
  DataFetchStrategy? get currentStrategy => _currentStrategy;

  /// 获取降级状态
  FallbackState get fallbackState => _fallbackState;

  /// 获取降级历史
  List<FallbackRecord> get fallbackHistory =>
      List.unmodifiable(_fallbackHistory);

  /// 获取降级统计
  FallbackStatistics get statistics => _statistics;

  /// 状态流
  Stream<FallbackState> get stateStream => _stateController.stream;

  /// 获取健康报告
  Future<FallbackHealthReport> getHealthReport() async {
    final currentHealth = _currentStrategy != null
        ? await _isStrategyHealthy(_currentStrategy!)
        : false;

    final recentFallbacks = _fallbackHistory
        .where((record) =>
            DateTime.now().difference(record.timestamp) <= _config.reportPeriod)
        .toList();

    WebSocketHealthStatus? websocketHealthStatus;
    if (_websocketStrategy != null) {
      websocketHealthStatus = _websocketStrategy!.getConnectionHealthStatus();
    }
    final pollingMetrics = _httpPollingStrategy != null
        ? _strategySelector?.getPerformanceMetrics(_httpPollingStrategy!.name)
        : null;

    return FallbackHealthReport(
      timestamp: DateTime.now(),
      currentStrategy: _currentStrategy?.name,
      currentState: _fallbackState,
      isHealthy: currentHealth,
      websocketHealth: websocketHealthStatus, // 将类型转换为适当的格式
      pollingMetrics: pollingMetrics,
      recentFallbacks: recentFallbacks,
      statistics: _statistics,
      recommendations: await _generateHealthRecommendations(),
    );
  }

  /// 生成健康建议
  Future<List<String>> _generateHealthRecommendations() async {
    final recommendations = <String>[];

    // WebSocket健康建议
    final websocketHealthStatus =
        _websocketStrategy?.getConnectionHealthStatus();
    if (websocketHealthStatus != null && !websocketHealthStatus.isHealthy) {
      recommendations.add('WebSocket连接不稳定，建议检查网络连接或服务器状态');
      recommendations.add('考虑增加连接超时时间或重连频率');
    }

    // 轮询性能建议
    final pollingMetrics = _httpPollingStrategy != null
        ? _strategySelector?.getPerformanceMetrics(_httpPollingStrategy!.name)
        : null;

    if (pollingMetrics != null) {
      if (pollingMetrics.successRate < 0.9) {
        recommendations.add('HTTP轮询成功率偏低，建议检查API端点或网络稳定性');
      }
      if (pollingMetrics.averageLatency.inMilliseconds > 5000) {
        recommendations.add('HTTP轮询延迟较高，建议优化API响应或增加缓存');
      }
    }

    // 降级频率建议
    final recentFallbackCount = _fallbackHistory
        .where((record) =>
            DateTime.now().difference(record.timestamp) <=
            const Duration(hours: 1))
        .length;

    if (recentFallbackCount > _config.maxFallbacksPerHour) {
      recommendations.add('降级频率过高，建议检查网络基础设施和服务器配置');
    }

    if (recommendations.isEmpty) {
      recommendations.add('系统运行正常，无需调整');
    }

    return recommendations;
  }

  /// 销毁降级策略
  Future<void> dispose() async {
    _reconnectTimer?.cancel();
    _healthCheckTimer?.cancel();
    _stateController.close();

    await _websocketStrategy?.dispose();

    AppLogger.info('WebSocketFallbackStrategy disposed');
  }

  // 实现 DataFetchStrategy 接口要求的抽象方法

  @override
  bool isAvailable() {
    return _currentStrategy?.isAvailable() ?? false;
  }

  @override
  Stream<DataItem> getDataStream(DataType type,
      {Map<String, dynamic>? parameters}) {
    if (_currentStrategy == null) {
      return Stream.empty();
    }
    return _currentStrategy!.getDataStream(type, parameters: parameters);
  }

  @override
  Future<FetchResult> fetchData(DataType type,
      {Map<String, dynamic>? parameters}) {
    if (_currentStrategy == null) {
      return Future.value(const FetchResult.failure('No strategy available'));
    }
    return _currentStrategy!.fetchData(type, parameters: parameters);
  }

  @override
  Future<Map<String, dynamic>> getHealthStatus() async {
    final currentHealth = _currentStrategy != null
        ? await _currentStrategy!.getHealthStatus()
        : <String, dynamic>{};

    return {
      'strategy': name,
      'currentStrategy': _currentStrategy?.name,
      'fallbackState': _fallbackState.name,
      'isHealthy': isAvailable(),
      'currentStrategyHealth': currentHealth,
      'statistics': statistics.toString(),
    };
  }

  @override
  Future<void> start() async {
    AppLogger.info('Starting WebSocketFallbackStrategy...');
    if (_websocketStrategy != null) {
      await _websocketStrategy!.start();
    }
  }

  @override
  Future<void> stop() async {
    AppLogger.info('Stopping WebSocketFallbackStrategy...');
    _reconnectTimer?.cancel();
    _healthCheckTimer?.cancel();
    if (_websocketStrategy != null) {
      await _websocketStrategy!.stop();
    }
  }

  @override
  Duration? getDefaultPollingInterval(DataType type) {
    return _currentStrategy?.getDefaultPollingInterval(type);
  }

  @override
  Map<String, dynamic> getConfig() {
    return {
      'name': name,
      'priority': priority,
      'supportedDataTypes': supportedDataTypes.map((e) => e.name).toList(),
      'maxRetries': maxRetries,
      'defaultRetryInterval': defaultRetryInterval.inMilliseconds,
      'fallbackState': _fallbackState.name,
      'currentStrategy': _currentStrategy?.name,
      'config': {
        'healthCheckInterval': _config.healthCheckInterval.inMilliseconds,
        'websocketReconnectDelay':
            _config.websocketReconnectDelay.inMilliseconds,
        'minSuccessRate': _config.minSuccessRate,
        'maxAcceptableLatency': _config.maxAcceptableLatency.inMilliseconds,
        'maxFallbacksPerHour': _config.maxFallbacksPerHour,
        'maxFallbackHistory': _config.maxFallbackHistory,
      },
    };
  }

  @override
  String toString() {
    return 'WebSocketFallbackStrategy(current: ${_currentStrategy?.name}, state: $_fallbackState)';
  }
}

/// 降级状态
enum FallbackState {
  none,
  websocket,
  httpPolling,
  unknown;

  String get description {
    switch (this) {
      case FallbackState.none:
        return '无降级';
      case FallbackState.websocket:
        return 'WebSocket';
      case FallbackState.httpPolling:
        return 'HTTP轮询';
      case FallbackState.unknown:
        return '未知';
    }
  }
}

/// 降级类型
enum FallbackType {
  websocketToPolling,
  pollingToWebsocket,
  unknown;

  String get description {
    switch (this) {
      case FallbackType.websocketToPolling:
        return 'WebSocket → HTTP轮询';
      case FallbackType.pollingToWebsocket:
        return 'HTTP轮询 → WebSocket';
      case FallbackType.unknown:
        return '未知';
    }
  }
}

/// 降级记录
class FallbackRecord {
  final String fromStrategy;
  final String toStrategy;
  final DateTime timestamp;
  final String reason;
  final FallbackType fallbackType;

  const FallbackRecord({
    required this.fromStrategy,
    required this.toStrategy,
    required this.timestamp,
    required this.reason,
    required this.fallbackType,
  });

  @override
  String toString() {
    return 'Fallback($timestamp): $fromStrategy → $toStrategy (${fallbackType.description})';
  }
}

/// 降级配置
class FallbackConfig {
  final Duration healthCheckInterval;
  final Duration websocketReconnectDelay;
  final double minSuccessRate;
  final Duration maxAcceptableLatency;
  final int maxFallbacksPerHour;
  final int maxFallbackHistory;
  final Duration reportPeriod;
  final StrategySelectionCriteria fallbackCriteria;

  const FallbackConfig({
    this.healthCheckInterval = const Duration(seconds: 30),
    this.websocketReconnectDelay = const Duration(seconds: 10),
    this.minSuccessRate = 0.8,
    this.maxAcceptableLatency = const Duration(seconds: 15),
    this.maxFallbacksPerHour = 5,
    this.maxFallbackHistory = 100,
    this.reportPeriod = const Duration(hours: 1),
    this.fallbackCriteria = const StrategySelectionCriteria(
      successRateWeight: 0.6,
      latencyWeight: 0.4,
    ),
  });
}

/// 降级统计
class FallbackStatistics {
  int totalFallbacks = 0;
  int totalUpgrades = 0;
  final Map<String, int> fallbackCounts = {};
  final Map<String, int> upgradeCounts = {};
  DateTime lastFallbackTime = DateTime.now();
  DateTime lastUpgradeTime = DateTime.now();

  /// 记录降级
  void recordFallback(String fromStrategy, String toStrategy, String reason) {
    totalFallbacks++;
    fallbackCounts[toStrategy] = (fallbackCounts[toStrategy] ?? 0) + 1;
    lastFallbackTime = DateTime.now();
  }

  /// 记录升级
  void recordUpgrade(String fromStrategy, String toStrategy, String reason) {
    totalUpgrades++;
    upgradeCounts[toStrategy] = (upgradeCounts[toStrategy] ?? 0) + 1;
    lastUpgradeTime = DateTime.now();
  }

  /// 获取降级频率
  double get fallbackRatePerHour {
    // 这里需要从外部传入历史记录，暂时返回默认值
    return totalFallbacks.toDouble();
  }

  /// 获取升级频率
  double get upgradeRatePerHour {
    // 这里需要从外部传入历史记录，暂时返回默认值
    return totalUpgrades.toDouble();
  }

  @override
  String toString() {
    return 'FallbackStats(fallbacks: $totalFallbacks, upgrades: $totalUpgrades)';
  }
}

/// 降级健康报告
class FallbackHealthReport {
  final DateTime timestamp;
  final String? currentStrategy;
  final FallbackState currentState;
  final bool isHealthy;
  final WebSocketHealthStatus? websocketHealth;
  final StrategyPerformanceMetrics? pollingMetrics;
  final List<FallbackRecord> recentFallbacks;
  final FallbackStatistics statistics;
  final List<String> recommendations;

  const FallbackHealthReport({
    required this.timestamp,
    this.currentStrategy,
    required this.currentState,
    required this.isHealthy,
    this.websocketHealth,
    this.pollingMetrics,
    required this.recentFallbacks,
    required this.statistics,
    required this.recommendations,
  });

  @override
  String toString() {
    return 'FallbackHealth(current: $currentStrategy, state: $currentState, healthy: $isHealthy)';
  }
}
