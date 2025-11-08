import 'dart:async';
import 'dart:math';
import '../utils/logger.dart';
import 'data_type.dart';
import 'data_fetch_strategy.dart';
import '../realtime/connection_monitor.dart';

/// 路由决策上下文
class RoutingContext {
  /// 当前数据类型
  final DataType dataType;

  /// 可用策略列表
  final List<DataFetchStrategy> availableStrategies;

  /// 网络连接状态
  final NetworkStatus networkStatus;

  /// 用户配置偏好
  final FetchStrategyPreference userPreference;

  /// 数据紧急程度
  final DataUrgency urgency;

  /// 负载情况 (0-1, 1为满负载)
  final double systemLoad;

  /// 历史性能数据
  final Map<String, StrategyPerformance> performanceHistory;

  const RoutingContext({
    required this.dataType,
    required this.availableStrategies,
    required this.networkStatus,
    this.userPreference = FetchStrategyPreference.auto,
    this.urgency = DataUrgency.normal,
    this.systemLoad = 0.0,
    this.performanceHistory = const {},
  });

  /// 检查是否有可用的WebSocket策略
  bool get hasWebSocketStrategy {
    return availableStrategies
        .any((s) => s.name.contains('WebSocket') || s.priority >= 90);
  }

  /// 检查是否有可用的HTTP轮询策略
  bool get hasHttpPollingStrategy {
    return availableStrategies
        .any((s) => s.name.contains('Polling') || s.priority >= 50);
  }

  /// 检查网络是否适合实时数据
  bool get networkSuitableForRealtime {
    return networkStatus.isConnected &&
        networkStatus.latency.inMilliseconds < 1000 &&
        !networkStatus.isMetered;
  }
}

/// 策略性能指标
class StrategyPerformance {
  /// 策略名称
  final String strategyName;

  /// 成功率 (0-1)
  final double successRate;

  /// 平均延迟 (毫秒)
  final double averageLatency;

  /// 最后使用时间
  final DateTime lastUsedTime;

  /// 总使用次数
  final int totalUsage;

  /// 最后错误信息
  final String? lastError;

  /// 错误率 (0-1)
  final double errorRate;

  const StrategyPerformance({
    required this.strategyName,
    required this.successRate,
    required this.averageLatency,
    required this.lastUsedTime,
    required this.totalUsage,
    this.lastError,
    this.errorRate = 0.0,
  });

  /// 计算策略得分 (越高越好)
  double calculateScore() {
    final now = DateTime.now();
    final timeSinceLastUse = now.difference(lastUsedTime).inMinutes;

    // 基础得分基于成功率
    double score = successRate * 100;

    // 延迟惩罚 (延迟越低得分越高)
    score -= min(averageLatency / 10, 30);

    // 错误率惩罚
    score -= errorRate * 50;

    // 最近使用奖励
    if (timeSinceLastUse < 10) {
      score += 10;
    }

    // 避免一直使用的策略得分过高
    if (totalUsage > 100 && timeSinceLastUse < 1) {
      score -= 5;
    }

    return max(score, 0);
  }
}

/// 数据紧急程度
enum DataUrgency {
  low('低'),
  normal('正常'),
  high('高'),
  critical('紧急');

  const DataUrgency(this.description);
  final String description;

  /// 获取紧急程度权重
  double get weight {
    switch (this) {
      case DataUrgency.low:
        return 0.5;
      case DataUrgency.normal:
        return 1.0;
      case DataUrgency.high:
        return 1.5;
      case DataUrgency.critical:
        return 2.0;
    }
  }
}

/// 网络状态
class NetworkStatus {
  final bool isConnected;
  final Duration latency;
  final bool isMetered;
  final NetworkType type;
  final int signalStrength; // 0-4

  const NetworkStatus({
    required this.isConnected,
    required this.latency,
    this.isMetered = false,
    this.type = NetworkType.unknown,
    this.signalStrength = 0,
  });

  factory NetworkStatus.disconnected() {
    return const NetworkStatus(
      isConnected: false,
      latency: Duration.zero,
    );
  }

  /// 网络是否适合实时连接
  bool get networkSuitableForRealtime {
    if (!isConnected) return false;

    // 延迟要求：小于500ms
    if (latency.inMilliseconds > 500) return false;

    // 计量连接不适合实时数据
    if (isMetered) return false;

    // WiFi 和以太网最适合
    if (type == NetworkType.wifi || type == NetworkType.ethernet) {
      return true;
    }

    // 移动网络需要信号强度
    if (type == NetworkType.mobile && signalStrength >= 2) {
      return true;
    }

    return false;
  }
}

/// 网络类型
enum NetworkType {
  wifi,
  mobile,
  ethernet,
  unknown;

  String get description {
    switch (this) {
      case NetworkType.wifi:
        return 'WiFi';
      case NetworkType.mobile:
        return '移动网络';
      case NetworkType.ethernet:
        return '以太网';
      case NetworkType.unknown:
        return '未知';
    }
  }
}

/// 数据类型路由器
///
/// 负责根据数据类型、网络状态、用户偏好等因素智能选择最优的数据获取策略
class DataTypeRouter {
  /// 策略性能缓存
  final Map<String, StrategyPerformance> _performanceCache = {};

  /// 网络状态监控
  NetworkStatus _currentNetworkStatus = const NetworkStatus(
    isConnected: true,
    latency: Duration(milliseconds: 100),
  );

  /// 路由决策统计
  final Map<String, int> _routingStats = {};

  /// 构造函数
  DataTypeRouter() {
    _initializeNetworkMonitoring();
  }

  /// 初始化网络状态监控
  void _initializeNetworkMonitoring() {
    // 这里应该集成到现有的网络监控中
    // 暂时使用默认值
    Timer.periodic(const Duration(seconds: 30), (_) {
      _updateNetworkStatus();
    });
  }

  /// 更新网络状态
  Future<void> _updateNetworkStatus() async {
    try {
      // 这里应该调用实际的网络状态检测
      // 暂时模拟网络状态
      final random = Random();
      final latency = Duration(milliseconds: 50 + random.nextInt(200));

      _currentNetworkStatus = NetworkStatus(
        isConnected: true,
        latency: latency,
        isMetered: random.nextBool(),
        type: NetworkType.wifi,
        signalStrength: random.nextInt(5),
      );
    } catch (e) {
      AppLogger.warning('Failed to update network status: $e');
    }
  }

  /// 选择最优策略
  DataFetchStrategy? selectOptimalStrategy(
    List<DataFetchStrategy> strategies,
    DataType dataType, {
    FetchStrategyPreference userPreference = FetchStrategyPreference.auto,
    DataUrgency urgency = DataUrgency.normal,
    Map<String, dynamic>? additionalContext,
  }) {
    if (strategies.isEmpty) {
      AppLogger.warning('No strategies available for ${dataType.code}');
      return null;
    }

    // 过滤可用策略
    final availableStrategies =
        strategies.where((s) => s.isAvailable()).toList();
    if (availableStrategies.isEmpty) {
      AppLogger.warning('No available strategies for ${dataType.code}');
      return null;
    }

    // 创建路由上下文
    final context = RoutingContext(
      dataType: dataType,
      availableStrategies: availableStrategies,
      networkStatus: _currentNetworkStatus,
      userPreference: userPreference,
      urgency: urgency,
      systemLoad: _calculateSystemLoad(),
      performanceHistory: _performanceCache,
    );

    // 根据数据类型和上下文选择策略
    final selectedStrategy = _makeRoutingDecision(context);

    // 记录路由决策
    if (selectedStrategy != null) {
      _recordRoutingDecision(selectedStrategy.name, context);
      AppLogger.debug(
          'Selected strategy ${selectedStrategy.name} for ${dataType.code}');
    }

    return selectedStrategy;
  }

  /// 计算系统负载
  double _calculateSystemLoad() {
    // 这里应该实现实际的系统负载计算
    // 暂时返回模拟值
    return Random().nextDouble() * 0.8;
  }

  /// 做出路由决策
  DataFetchStrategy? _makeRoutingDecision(RoutingContext context) {
    final dataType = context.dataType;
    final strategies = context.availableStrategies;

    // 1. 根据用户偏好进行初步筛选
    DataFetchStrategy? preferredStrategy;
    if (context.userPreference != FetchStrategyPreference.auto) {
      preferredStrategy =
          _filterByUserPreference(strategies, context.userPreference);
      if (preferredStrategy != null) {
        return preferredStrategy;
      }
    }

    // 2. 根据数据类型特性选择策略
    switch (dataType.priority) {
      case DataPriority.critical:
        return _selectStrategyForCriticalData(context);

      case DataPriority.high:
        return _selectStrategyForHighPriorityData(context);

      case DataPriority.medium:
        return _selectStrategyForMediumPriorityData(context);

      case DataPriority.low:
        return _selectStrategyForLowPriorityData(context);
    }
  }

  /// 根据用户偏好筛选策略
  DataFetchStrategy? _filterByUserPreference(
    List<DataFetchStrategy> strategies,
    FetchStrategyPreference preference,
  ) {
    switch (preference) {
      case FetchStrategyPreference.websocket:
        return strategies
            .where((s) => s.name.contains('WebSocket') && s.priority >= 90)
            .firstOrNull;

      case FetchStrategyPreference.httpPolling:
        return strategies
            .where((s) => s.name.contains('Polling') && s.priority >= 50)
            .firstOrNull;

      case FetchStrategyPreference.httpOnDemand:
        return strategies
            .where((s) => s.name.contains('OnDemand') && s.priority >= 30)
            .firstOrNull;

      case FetchStrategyPreference.auto:
      default:
        return null;
    }
  }

  /// 为关键数据选择策略
  DataFetchStrategy? _selectStrategyForCriticalData(RoutingContext context) {
    // 关键数据优先选择最可靠的策略

    // 1. 如果网络适合实时数据且有WebSocket策略，优先使用
    if (context.networkSuitableForRealtime && context.hasWebSocketStrategy) {
      return context.availableStrategies
          .where((s) => s.name.contains('WebSocket'))
          .reduce((a, b) => a.priority > b.priority ? a : b);
    }

    // 2. 否则选择最高优先级的HTTP策略
    final httpStrategies = context.availableStrategies
        .where((s) => s.name.contains('HTTP') || s.name.contains('Polling'))
        .toList();

    if (httpStrategies.isNotEmpty) {
      return httpStrategies.reduce((a, b) => a.priority > b.priority ? a : b);
    }

    // 3. 最后选择任何可用策略
    return context.availableStrategies
        .reduce((a, b) => a.priority > b.priority ? a : b);
  }

  /// 为高优先级数据选择策略
  DataFetchStrategy? _selectStrategyForHighPriorityData(
      RoutingContext context) {
    // 高优先级数据倾向使用实时策略

    final candidates = <DataFetchStrategy>[];

    // 添加WebSocket策略
    if (context.networkSuitableForRealtime && context.hasWebSocketStrategy) {
      candidates.addAll(context.availableStrategies
          .where((s) => s.name.contains('WebSocket')));
    }

    // 添加高频HTTP轮询策略
    final pollingStrategies = context.availableStrategies
        .where((s) => s.name.contains('Polling') && s.priority >= 60);
    candidates.addAll(pollingStrategies);

    if (candidates.isNotEmpty) {
      // 根据性能历史选择最佳策略
      return _selectBestByPerformance(candidates);
    }

    // 如果没有合适的策略，返回最高优先级的
    return context.availableStrategies
        .reduce((a, b) => a.priority > b.priority ? a : b);
  }

  /// 为中等优先级数据选择策略
  DataFetchStrategy? _selectStrategyForMediumPriorityData(
      RoutingContext context) {
    // 中等优先级数据平衡性能和资源使用

    // 优先选择HTTP轮询策略
    final pollingStrategies = context.availableStrategies
        .where((s) => s.name.contains('Polling'))
        .toList();

    if (pollingStrategies.isNotEmpty) {
      return _selectBestByPerformance(pollingStrategies);
    }

    // 其次选择按需请求策略
    final onDemandStrategies = context.availableStrategies
        .where((s) => s.name.contains('OnDemand'))
        .toList();

    if (onDemandStrategies.isNotEmpty) {
      return onDemandStrategies
          .reduce((a, b) => a.priority > b.priority ? a : b);
    }

    return context.availableStrategies.firstOrNull;
  }

  /// 为低优先级数据选择策略
  DataFetchStrategy? _selectStrategyForLowPriorityData(RoutingContext context) {
    // 低优先级数据优先使用资源消耗最少的策略

    // 优先选择按需请求策略
    final onDemandStrategies = context.availableStrategies
        .where((s) => s.name.contains('OnDemand'))
        .toList();

    if (onDemandStrategies.isNotEmpty) {
      return onDemandStrategies
          .reduce((a, b) => a.priority > b.priority ? a : b);
    }

    // 其次选择低频轮询策略
    final lowFrequencyStrategies =
        context.availableStrategies.where((s) => s.priority <= 60).toList();

    if (lowFrequencyStrategies.isNotEmpty) {
      return lowFrequencyStrategies
          .reduce((a, b) => a.priority > b.priority ? a : b);
    }

    return context.availableStrategies.firstOrNull;
  }

  /// 根据性能历史选择最佳策略
  DataFetchStrategy _selectBestByPerformance(
      List<DataFetchStrategy> strategies) {
    if (strategies.length == 1) {
      return strategies.first;
    }

    // 计算每个策略的综合得分
    DataFetchStrategy? bestStrategy;
    double bestScore = -1;

    for (final strategy in strategies) {
      final performance = _performanceCache[strategy.name];
      double score = strategy.priority.toDouble();

      if (performance != null) {
        // 加上性能得分
        score += performance.calculateScore() / 10;
      }

      // 考虑网络条件
      if (strategy.name.contains('WebSocket') &&
          !_currentNetworkStatus.networkSuitableForRealtime) {
        score -= 50; // 网络不适合WebSocket时大幅降分
      }

      if (score > bestScore) {
        bestScore = score;
        bestStrategy = strategy;
      }
    }

    return bestStrategy ?? strategies.first;
  }

  /// 记录路由决策
  void _recordRoutingDecision(String strategyName, RoutingContext context) {
    final key = '${context.dataType.code}_$strategyName';
    _routingStats[key] = (_routingStats[key] ?? 0) + 1;
  }

  /// 更新策略性能数据
  void updateStrategyPerformance(
    String strategyName,
    bool success,
    Duration latency, {
    String? error,
  }) {
    final existing = _performanceCache[strategyName];
    final now = DateTime.now();

    if (existing == null) {
      _performanceCache[strategyName] = StrategyPerformance(
        strategyName: strategyName,
        successRate: success ? 1.0 : 0.0,
        averageLatency: latency.inMilliseconds.toDouble(),
        lastUsedTime: now,
        totalUsage: 1,
        lastError: error,
        errorRate: success ? 0.0 : 1.0,
      );
    } else {
      // 更新现有性能数据
      final newTotalUsage = existing.totalUsage + 1;
      final newSuccessCount = success
          ? (existing.successRate * existing.totalUsage + 1)
          : (existing.successRate * existing.totalUsage);

      final newSuccessRate = newSuccessCount / newTotalUsage;
      final newErrorRate = success
          ? (existing.errorRate * existing.totalUsage) / newTotalUsage
          : (existing.errorRate * existing.totalUsage + 1) / newTotalUsage;

      final newAverageLatency = (existing.averageLatency * existing.totalUsage +
              latency.inMilliseconds) /
          newTotalUsage;

      _performanceCache[strategyName] = StrategyPerformance(
        strategyName: strategyName,
        successRate: newSuccessRate,
        averageLatency: newAverageLatency,
        lastUsedTime: now,
        totalUsage: newTotalUsage,
        lastError: error,
        errorRate: newErrorRate,
      );
    }
  }

  /// 获取路由统计信息
  Map<String, dynamic> getRoutingStats() {
    return {
      'routingDecisions': _routingStats,
      'strategyPerformance': _performanceCache.map(
        (key, value) => MapEntry(key, {
          'successRate': value.successRate,
          'averageLatency': value.averageLatency,
          'totalUsage': value.totalUsage,
          'errorRate': value.errorRate,
          'lastUsedTime': value.lastUsedTime.toIso8601String(),
          'score': value.calculateScore(),
        }),
      ),
      'networkStatus': {
        'isConnected': _currentNetworkStatus.isConnected,
        'latency': _currentNetworkStatus.latency.inMilliseconds,
        'type': _currentNetworkStatus.type.name,
        'signalStrength': _currentNetworkStatus.signalStrength,
      },
    };
  }

  /// 清理过期的性能数据
  void cleanupPerformanceData() {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));

    _performanceCache.removeWhere((key, value) {
      return value.lastUsedTime.isBefore(cutoff);
    });
  }
}
