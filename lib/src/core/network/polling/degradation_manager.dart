import 'dart:async';
import 'dart:collection';

import '../utils/logger.dart';

/// 数据源降级策略
enum DegradationStrategy {
  /// 立即降级 - 检测到问题立即切换到备用源
  immediate,

  /// 延迟降级 - 等待确认后再切换
  delayed,

  /// 渐进降级 - 逐步降低数据质量而不是切换源
  gradual,

  /// 手动降级 - 需要用户确认
  manual,
}

/// 数据源优先级
enum DataSourcePriority {
  /// 实时数据源（WebSocket等）
  realtime,

  /// 准实时数据源（HTTP轮询等）
  quasiRealtime,

  /// 缓存数据源（本地缓存）
  cached,

  /// 离线数据源（预装数据）
  offline,
}

/// 数据源类型
enum DataSourceType {
  /// WebSocket实时连接
  websocket,

  /// HTTP轮询
  httpPolling,

  /// HTTP按需请求
  httpOnDemand,

  /// 本地缓存
  localCache,

  /// 预装数据
  bundledData,
}

/// 数据源定义
class DataSourceDefinition {
  /// 数据源ID
  final String id;

  /// 数据源名称
  final String name;

  /// 数据源类型
  final DataSourceType type;

  /// 数据源优先级
  final DataSourcePriority priority;

  /// 降级策略
  final DegradationStrategy strategy;

  /// 最大重试次数
  final int maxRetries;

  /// 降级阈值（连续失败次数）
  final int degradationThreshold;

  /// 恢复阈值（连续成功次数）
  final int recoveryThreshold;

  /// 是否为主要数据源
  final bool isPrimary;

  /// 额外配置
  final Map<String, dynamic> config;

  const DataSourceDefinition({
    required this.id,
    required this.name,
    required this.type,
    required this.priority,
    this.strategy = DegradationStrategy.delayed,
    this.maxRetries = 3,
    this.degradationThreshold = 3,
    this.recoveryThreshold = 2,
    this.isPrimary = false,
    this.config = const {},
  });

  /// 获取优先级数值（用于排序）
  int get priorityValue {
    switch (priority) {
      case DataSourcePriority.realtime:
        return 4;
      case DataSourcePriority.quasiRealtime:
        return 3;
      case DataSourcePriority.cached:
        return 2;
      case DataSourcePriority.offline:
        return 1;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'priority': priority.name,
      'strategy': strategy.name,
      'maxRetries': maxRetries,
      'degradationThreshold': degradationThreshold,
      'recoveryThreshold': recoveryThreshold,
      'isPrimary': isPrimary,
      'config': config,
    };
  }
}

/// 数据源状态
class DataSourceState {
  /// 数据源定义
  final DataSourceDefinition definition;

  /// 是否可用
  bool isAvailable;

  /// 当前激活状态
  bool isActive;

  /// 连续成功次数
  int consecutiveSuccesses;

  /// 连续失败次数
  int consecutiveFailures;

  /// 总成功率
  double successRate;

  /// 最后成功时间
  DateTime? lastSuccessTime;

  /// 最后失败时间
  DateTime? lastFailureTime;

  /// 当前重试次数
  int currentRetryCount;

  /// 是否正在降级
  bool isDegraded;

  /// 降级开始时间
  DateTime? degradationStartTime;

  /// 额外状态信息
  final Map<String, dynamic> metadata;

  DataSourceState({
    required this.definition,
    this.isAvailable = true,
    this.isActive = false,
    this.consecutiveSuccesses = 0,
    this.consecutiveFailures = 0,
    this.successRate = 1.0,
    this.lastSuccessTime,
    this.lastFailureTime,
    this.currentRetryCount = 0,
    this.isDegraded = false,
    this.degradationStartTime,
    this.metadata = const {},
  });

  /// 更新成功状态
  void updateSuccess() {
    consecutiveSuccesses++;
    consecutiveFailures = 0;
    lastSuccessTime = DateTime.now();
    currentRetryCount = 0;

    // 更新成功率
    final totalAttempts = consecutiveSuccesses + consecutiveFailures;
    if (totalAttempts > 0) {
      successRate = consecutiveSuccesses / totalAttempts;
    }

    // 检查是否可以恢复
    if (isDegraded && consecutiveSuccesses >= definition.recoveryThreshold) {
      isDegraded = false;
      degradationStartTime = null;
      AppLogger.info('数据源恢复', '${definition.id} 已从降级状态恢复');
    }
  }

  /// 更新失败状态
  void updateFailure() {
    consecutiveFailures++;
    consecutiveSuccesses = 0;
    lastFailureTime = DateTime.now();

    // 更新成功率
    final totalAttempts = consecutiveSuccesses + consecutiveFailures;
    if (totalAttempts > 0) {
      successRate = consecutiveSuccesses / totalAttempts;
    }

    // 检查是否需要降级
    if (!isDegraded && consecutiveFailures >= definition.degradationThreshold) {
      isDegraded = true;
      degradationStartTime = DateTime.now();
      AppLogger.warn(
          '数据源降级', '${definition.id} 已降级，连续失败 ${consecutiveFailures} 次');
    }

    // 更新重试次数
    if (currentRetryCount < definition.maxRetries) {
      currentRetryCount++;
    }
  }

  /// 重置状态
  void reset() {
    consecutiveSuccesses = 0;
    consecutiveFailures = 0;
    currentRetryCount = 0;
    isDegraded = false;
    degradationStartTime = null;
    successRate = 1.0;
    isAvailable = true;
  }

  /// 是否可以重试
  bool get canRetry => currentRetryCount < definition.maxRetries;

  /// 是否需要立即降级
  bool get needsImmediateDegradation =>
      consecutiveFailures >= definition.degradationThreshold &&
      definition.strategy == DegradationStrategy.immediate;

  Map<String, dynamic> toJson() {
    return {
      'definition': definition.toJson(),
      'isAvailable': isAvailable,
      'isActive': isActive,
      'consecutiveSuccesses': consecutiveSuccesses,
      'consecutiveFailures': consecutiveFailures,
      'successRate': successRate,
      'lastSuccessTime': lastSuccessTime?.toIso8601String(),
      'lastFailureTime': lastFailureTime?.toIso8601String(),
      'currentRetryCount': currentRetryCount,
      'isDegraded': isDegraded,
      'degradationStartTime': degradationStartTime?.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// 降级事件
class DegradationEvent {
  /// 事件类型
  final DegradationEventType type;

  /// 数据源ID
  final String sourceId;

  /// 事件描述
  final String description;

  /// 事件时间戳
  final DateTime timestamp;

  /// 事件数据
  final Map<String, dynamic> data;

  const DegradationEvent({
    required this.type,
    required this.sourceId,
    required this.description,
    required this.timestamp,
    this.data = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'sourceId': sourceId,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
    };
  }
}

/// 降级事件类型
enum DegradationEventType {
  /// 开始降级
  degradationStarted,

  /// 结束降级
  degradationEnded,

  /// 切换数据源
  sourceSwitched,

  /// 数据源恢复
  sourceRecovered,

  /// 重试失败
  retryFailed,

  /// 手动干预
  manualIntervention,
}

/// 降级管理器配置
class DegradationManagerConfig {
  /// 是否启用自动降级
  final bool enableAutoDegradation;

  /// 降级检测间隔
  final Duration checkInterval;

  /// 最大事件历史记录数
  final int maxEventHistory;

  /// 是否启用详细日志
  final bool enableDetailedLogging;

  const DegradationManagerConfig({
    this.enableAutoDegradation = true,
    this.checkInterval = const Duration(seconds: 10),
    this.maxEventHistory = 100,
    this.enableDetailedLogging = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'enableAutoDegradation': enableAutoDegradation,
      'checkInterval': checkInterval.inMilliseconds,
      'maxEventHistory': maxEventHistory,
      'enableDetailedLogging': enableDetailedLogging,
    };
  }
}

/// 降级管理器
///
/// 负责监控数据源状态，执行降级策略，管理数据源切换
/// 支持多种降级策略和智能恢复机制
class DegradationManager {
  /// 配置
  final DegradationManagerConfig config;

  /// 数据源定义列表
  final List<DataSourceDefinition> dataSourceDefinitions;

  /// 数据源状态映射
  final Map<String, DataSourceState> _dataSourceStates = {};

  /// 当前激活的数据源
  String? _currentActiveSource;

  /// 降级事件历史
  final Queue<DegradationEvent> _eventHistory = Queue<DegradationEvent>();

  /// 检测定时器
  Timer? _checkTimer;

  /// 事件流控制器
  final StreamController<DegradationEvent> _eventController =
      StreamController<DegradationEvent>.broadcast();

  /// 活动数据源变更流控制器
  final StreamController<String?> _activeSourceController =
      StreamController<String?>.broadcast();

  /// 是否正在运行
  bool _isRunning = false;

  DegradationManager({
    required this.config,
    required this.dataSourceDefinitions,
  }) {
    _initializeDataSources();
  }

  /// 初始化数据源状态
  void _initializeDataSources() {
    for (final definition in dataSourceDefinitions) {
      _dataSourceStates[definition.id] = DataSourceState(
        definition: definition,
        isActive: definition.isPrimary, // 主要数据源默认激活
      );

      if (definition.isPrimary) {
        _currentActiveSource = definition.id;
      }
    }

    // 如果没有主要数据源，选择优先级最高的
    if (_currentActiveSource == null && dataSourceDefinitions.isNotEmpty) {
      final sortedSources = dataSourceDefinitions
        ..sort((a, b) => b.priorityValue.compareTo(a.priorityValue));
      _currentActiveSource = sortedSources.first.id;
      _dataSourceStates[_currentActiveSource]?.isActive = true;
    }

    AppLogger.info('降级管理器初始化完成',
        '数据源数量: ${dataSourceDefinitions.length}, 激活源: $_currentActiveSource');
  }

  /// 获取事件流
  Stream<DegradationEvent> get eventStream => _eventController.stream;

  /// 获取活动数据源变更流
  Stream<String?> get activeSourceStream => _activeSourceController.stream;

  /// 当前活动数据源
  String? get currentActiveSource => _currentActiveSource;

  /// 是否正在运行
  bool get isRunning => _isRunning;

  /// 获取所有数据源状态
  Map<String, DataSourceState> get dataSourceStates =>
      Map.unmodifiable(_dataSourceStates);

  /// 获取特定数据源状态
  DataSourceState? getDataSourceState(String sourceId) {
    return _dataSourceStates[sourceId];
  }

  /// 获取事件历史
  List<DegradationEvent> get eventHistory => _eventHistory.toList();

  /// 启动降级管理器
  void start() {
    if (_isRunning) {
      AppLogger.warn('降级管理器已在运行中');
      return;
    }

    _isRunning = true;

    // 启动定时检查
    _checkTimer = Timer.periodic(config.checkInterval, (_) {
      _performHealthCheck();
    });

    // 立即执行一次检查
    _performHealthCheck();

    AppLogger.info('降级管理器已启动');
  }

  /// 停止降级管理器
  void stop() {
    if (!_isRunning) return;

    _isRunning = false;
    _checkTimer?.cancel();
    _checkTimer = null;

    AppLogger.info('降级管理器已停止');
  }

  /// 执行健康检查
  void _performHealthCheck() {
    if (!config.enableAutoDegradation) return;

    for (final sourceId in _dataSourceStates.keys) {
      final state = _dataSourceStates[sourceId]!;
      _checkDataSourceHealth(sourceId, state);
    }

    // 检查是否需要切换数据源
    _checkSourceSwitching();
  }

  /// 检查单个数据源健康状态
  void _checkDataSourceHealth(String sourceId, DataSourceState state) {
    // 检查降级条件
    if (state.needsImmediateDegradation && state.isActive) {
      _triggerDegradation(sourceId);
    }

    // 检查恢复条件
    if (state.isDegraded &&
        state.consecutiveSuccesses >= state.definition.recoveryThreshold) {
      _attemptRecovery(sourceId);
    }

    // 检查重试条件
    if (state.isDegraded && state.canRetry) {
      _scheduleRetry(sourceId);
    }
  }

  /// 触发降级
  void _triggerDegradation(String sourceId) {
    final state = _dataSourceStates[sourceId]!;
    state.isDegraded = true;
    state.degradationStartTime = DateTime.now();

    final event = DegradationEvent(
      type: DegradationEventType.degradationStarted,
      sourceId: sourceId,
      description: '数据源 ${state.definition.name} 开始降级',
      timestamp: DateTime.now(),
      data: {
        'consecutiveFailures': state.consecutiveFailures,
        'threshold': state.definition.degradationThreshold,
        'strategy': state.definition.strategy.name,
      },
    );

    _addEvent(event);

    if (config.enableDetailedLogging) {
      AppLogger.warn('触发降级', event.description);
    }
  }

  /// 尝试恢复
  void _attemptRecovery(String sourceId) {
    final state = _dataSourceStates[sourceId]!;
    state.isDegraded = false;
    state.degradationStartTime = null;

    final event = DegradationEvent(
      type: DegradationEventType.sourceRecovered,
      sourceId: sourceId,
      description: '数据源 ${state.definition.name} 已恢复',
      timestamp: DateTime.now(),
      data: {
        'consecutiveSuccesses': state.consecutiveSuccesses,
        'successRate': state.successRate,
      },
    );

    _addEvent(event);

    if (config.enableDetailedLogging) {
      AppLogger.info('数据源恢复', event.description);
    }

    // 检查是否可以切换回更高优先级的数据源
    _checkForBetterSource();
  }

  /// 安排重试
  void _scheduleRetry(String sourceId) {
    // 这里可以实现重试逻辑
    // 实际的重试需要与具体的数据源实现配合
    AppLogger.debug('安排重试', '数据源: $sourceId');
  }

  /// 检查数据源切换
  void _checkSourceSwitching() {
    if (_currentActiveSource == null) return;

    final currentState = _dataSourceStates[_currentActiveSource]!;

    // 如果当前源不可用，寻找替代源
    if (!currentState.isAvailable || currentState.isDegraded) {
      final alternativeSource = _findBestAlternativeSource();
      if (alternativeSource != null) {
        _switchToSource(alternativeSource);
      }
    }
  }

  /// 寻找最佳替代数据源
  String? _findBestAlternativeSource() {
    final availableSources = _dataSourceStates.entries
        .where((entry) =>
            entry.value.isAvailable &&
            !entry.value.isDegraded &&
            entry.key != _currentActiveSource)
        .toList();

    if (availableSources.isEmpty) return null;

    // 按优先级排序
    availableSources.sort((a, b) => b.value.definition.priorityValue
        .compareTo(a.value.definition.priorityValue));

    return availableSources.first.key;
  }

  /// 切换到指定数据源
  void _switchToSource(String newSourceId) {
    final oldSourceId = _currentActiveSource;

    // 停用旧数据源
    if (oldSourceId != null) {
      _dataSourceStates[oldSourceId]?.isActive = false;
    }

    // 激活新数据源
    _dataSourceStates[newSourceId]?.isActive = true;
    _currentActiveSource = newSourceId;

    final event = DegradationEvent(
      type: DegradationEventType.sourceSwitched,
      sourceId: newSourceId,
      description: '数据源从 $oldSourceId 切换到 $newSourceId',
      timestamp: DateTime.now(),
      data: {
        'oldSource': oldSourceId,
        'newSource': newSourceId,
        'newSourceType': _dataSourceStates[newSourceId]?.definition.type.name,
      },
    );

    _addEvent(event);

    // 通知活动源变更
    if (!_activeSourceController.isClosed) {
      _activeSourceController.add(newSourceId);
    }

    AppLogger.warn('数据源切换', event.description);
  }

  /// 检查是否有更好的数据源可以切换
  void _checkForBetterSource() {
    if (_currentActiveSource == null) return;

    final currentSource = _dataSourceStates[_currentActiveSource]!;
    final currentPriority = currentSource.definition.priorityValue;

    // 寻找更高优先级的可用数据源
    final betterSources = _dataSourceStates.entries
        .where((entry) =>
            entry.value.isAvailable &&
            !entry.value.isDegraded &&
            entry.value.definition.priorityValue > currentPriority &&
            entry.key != _currentActiveSource)
        .toList();

    if (betterSources.isNotEmpty) {
      // 选择优先级最高的
      betterSources.sort((a, b) => b.value.definition.priorityValue
          .compareTo(a.value.definition.priorityValue));
      _switchToSource(betterSources.first.key);
    }
  }

  /// 添加事件
  void _addEvent(DegradationEvent event) {
    _eventHistory.add(event);

    // 保持事件历史在限制范围内
    while (_eventHistory.length > config.maxEventHistory) {
      _eventHistory.removeFirst();
    }

    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  /// 手动报告数据源成功
  void reportSuccess(String sourceId) {
    final state = _dataSourceStates[sourceId];
    if (state != null) {
      state.updateSuccess();
    }
  }

  /// 手动报告数据源失败
  void reportFailure(String sourceId, {String? reason}) {
    final state = _dataSourceStates[sourceId];
    if (state != null) {
      state.updateFailure();

      final event = DegradationEvent(
        type: DegradationEventType.retryFailed,
        sourceId: sourceId,
        description: reason ?? '数据源 ${state.definition.name} 报告失败',
        timestamp: DateTime.now(),
        data: {
          'consecutiveFailures': state.consecutiveFailures,
          'isDegraded': state.isDegraded,
        },
      );

      _addEvent(event);
    }
  }

  /// 手动切换数据源
  bool switchToSource(String sourceId) {
    final state = _dataSourceStates[sourceId];
    if (state == null || !state.isAvailable || state.isDegraded) {
      AppLogger.warn('无法切换到指定数据源', '源: $sourceId, 状态: ${state?.isAvailable}');
      return false;
    }

    _switchToSource(sourceId);

    final event = DegradationEvent(
      type: DegradationEventType.manualIntervention,
      sourceId: sourceId,
      description: '手动切换到数据源 ${state.definition.name}',
      timestamp: DateTime.now(),
    );

    _addEvent(event);

    return true;
  }

  /// 重置数据源状态
  void resetDataSource(String sourceId) {
    final state = _dataSourceStates[sourceId];
    if (state != null) {
      state.reset();
      AppLogger.info('重置数据源状态', '源: $sourceId');
    }
  }

  /// 获取降级统计信息
  Map<String, dynamic> getDegradationStats() {
    final now = DateTime.now();
    final last24Hours = now.subtract(const Duration(hours: 24));

    final recentEvents = _eventHistory
        .where((event) => event.timestamp.isAfter(last24Hours))
        .toList();

    final degradationEvents = recentEvents
        .where((event) => event.type == DegradationEventType.degradationStarted)
        .length;

    final recoveryEvents = recentEvents
        .where((event) => event.type == DegradationEventType.sourceRecovered)
        .length;

    final switchEvents = recentEvents
        .where((event) => event.type == DegradationEventType.sourceSwitched)
        .length;

    return {
      'isRunning': _isRunning,
      'config': config.toJson(),
      'currentActiveSource': _currentActiveSource,
      'totalDataSources': _dataSourceStates.length,
      'availableDataSources':
          _dataSourceStates.values.where((state) => state.isAvailable).length,
      'degradedDataSources':
          _dataSourceStates.values.where((state) => state.isDegraded).length,
      'eventsLast24Hours': {
        'total': recentEvents.length,
        'degradations': degradationEvents,
        'recoveries': recoveryEvents,
        'switches': switchEvents,
      },
      'dataSources': _dataSourceStates.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    };
  }

  /// 销毁降级管理器
  void dispose() {
    stop();

    _eventController.close();
    _activeSourceController.close();
    _eventHistory.clear();

    AppLogger.info('降级管理器已销毁');
  }
}
