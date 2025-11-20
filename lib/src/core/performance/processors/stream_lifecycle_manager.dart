import 'dart:async';

import '../../utils/logger.dart';

/// Stream生命周期状态
enum StreamLifecycleState {
  created, // 已创建
  listening, // 正在监听
  paused, // 已暂停
  closed, // 已关闭
  error, // 错误状态
}

/// Stream订阅信息
class StreamSubscriptionInfo {
  final String subscriptionId;
  final String streamName;
  final StreamSubscription subscription;
  final StreamLifecycleState state;
  final DateTime createdAt;
  final DateTime? lastActivityAt;
  final String? debugInfo;

  StreamSubscriptionInfo({
    required this.subscriptionId,
    required this.streamName,
    required this.subscription,
    required this.state,
    required this.createdAt,
    this.lastActivityAt,
    this.debugInfo,
  });

  Duration get age => DateTime.now().difference(createdAt);

  Duration? get timeSinceLastActivity {
    if (lastActivityAt == null) return null;
    return DateTime.now().difference(lastActivityAt!);
  }

  StreamSubscriptionInfo copyWith({
    StreamLifecycleState? state,
    DateTime? lastActivityAt,
  }) {
    return StreamSubscriptionInfo(
      subscriptionId: subscriptionId,
      streamName: streamName,
      subscription: subscription,
      state: state ?? this.state,
      createdAt: createdAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      debugInfo: debugInfo,
    );
  }
}

/// Stream生命周期配置
class StreamLifecycleConfig {
  final Duration maxIdleTime;
  final Duration maxLifetime;
  final bool enableAutoCleanup;
  final bool enableHealthCheck;
  final Duration healthCheckInterval;
  final bool logWarnings;

  const StreamLifecycleConfig({
    this.maxIdleTime = const Duration(minutes: 30),
    this.maxLifetime = const Duration(hours: 24),
    this.enableAutoCleanup = true,
    this.enableHealthCheck = true,
    this.healthCheckInterval = const Duration(minutes: 5),
    this.logWarnings = true,
  });
}

/// Stream生命周期管理器
///
/// 自动管理Stream订阅的生命周期，防止内存泄漏和订阅累积
class StreamLifecycleManager {
  static final StreamLifecycleManager _instance =
      StreamLifecycleManager._internal();
  factory StreamLifecycleManager() => _instance;
  StreamLifecycleManager._internal();

  // 使用自定义AppLogger静态方法
  final Map<String, StreamSubscriptionInfo> _subscriptions = {};
  Timer? _healthCheckTimer;
  StreamLifecycleConfig _config = const StreamLifecycleConfig();

  /// 配置管理器
  void configure(StreamLifecycleConfig config) {
    _config = config;
    AppLogger.info('StreamLifecycleManager配置已更新');

    // 重启健康检查定时器
    if (_healthCheckTimer != null) {
      _healthCheckTimer!.cancel();
      _healthCheckTimer = null;
    }

    if (_config.enableHealthCheck) {
      _startHealthCheck();
    }
  }

  /// 启动管理器
  void start() {
    if (_healthCheckTimer != null) return;

    AppLogger.info('启动StreamLifecycleManager');

    if (_config.enableHealthCheck) {
      _startHealthCheck();
    }
  }

  /// 停止管理器
  Future<void> stop() async {
    AppLogger.info('停止StreamLifecycleManager');

    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;

    // 清理所有订阅
    await cleanupAll();
  }

  /// 创建并监听Stream
  String listenToStream<T>({
    required String streamName,
    required Stream<T> stream,
    required void Function(T data) onData,
    required void Function(Object error) onError,
    void Function()? onDone,
    bool? cancelOnError,
    String? debugInfo,
  }) {
    final subscriptionId =
        '${streamName}_${DateTime.now().millisecondsSinceEpoch}';

    try {
      AppLogger.debug('创建Stream订阅: $streamName ($subscriptionId)');

      final subscription = stream.listen(
        onData,
        onError: onError,
        onDone: () {
          _handleStreamDone(subscriptionId);
          onDone?.call();
        },
        cancelOnError: cancelOnError,
      );

      final info = StreamSubscriptionInfo(
        subscriptionId: subscriptionId,
        streamName: streamName,
        subscription: subscription,
        state: StreamLifecycleState.listening,
        createdAt: DateTime.now(),
        lastActivityAt: DateTime.now(),
        debugInfo: debugInfo,
      );

      _subscriptions[subscriptionId] = info;

      AppLogger.debug('Stream订阅创建成功: $subscriptionId');
      return subscriptionId;
    } catch (e) {
      AppLogger.error('创建Stream订阅失败: $streamName', e);
      rethrow;
    }
  }

  /// 暂停Stream订阅
  Future<void> pauseSubscription(String subscriptionId) async {
    final info = _subscriptions[subscriptionId];
    if (info == null) {
      AppLogger.warn('订阅不存在，无法暂停: $subscriptionId');
      return;
    }

    try {
      info.subscription.pause();
      _subscriptions[subscriptionId] = info.copyWith(
        state: StreamLifecycleState.paused,
      );

      AppLogger.debug('Stream订阅已暂停: $subscriptionId');
    } catch (e) {
      AppLogger.error('暂停Stream订阅失败: $subscriptionId', e);
    }
  }

  /// 恢复Stream订阅
  Future<void> resumeSubscription(String subscriptionId) async {
    final info = _subscriptions[subscriptionId];
    if (info == null) {
      AppLogger.warn('订阅不存在，无法恢复: $subscriptionId');
      return;
    }

    try {
      info.subscription.resume();
      _subscriptions[subscriptionId] = info.copyWith(
        state: StreamLifecycleState.listening,
        lastActivityAt: DateTime.now(),
      );

      AppLogger.debug('Stream订阅已恢复: $subscriptionId');
    } catch (e) {
      AppLogger.error('恢复Stream订阅失败: $subscriptionId', e);
    }
  }

  /// 取消Stream订阅
  Future<void> cancelSubscription(String subscriptionId) async {
    final info = _subscriptions.remove(subscriptionId);
    if (info == null) {
      AppLogger.warn('订阅不存在，无法取消: $subscriptionId');
      return;
    }

    try {
      await _cancelSubscriptionSafely(info);
      AppLogger.debug('Stream订阅已取消: $subscriptionId');
    } catch (e) {
      AppLogger.error('取消Stream订阅失败: $subscriptionId', e);
    }
  }

  /// 安全取消订阅
  Future<void> _cancelSubscriptionSafely(StreamSubscriptionInfo info) async {
    try {
      // 等待一段时间确保事件处理完成
      await Future.delayed(const Duration(milliseconds: 100));

      if (!info.subscription.isPaused) {
        await info.subscription.cancel();
      }
    } catch (e) {
      AppLogger.warn('取消订阅时发生错误: ${info.subscriptionId}', e);

      // 强制取消
      try {
        await info.subscription.cancel();
      } catch (e2) {
        AppLogger.error('强制取消订阅失败: ${info.subscriptionId}', e2);
      }
    }
  }

  /// 更新订阅活动时间
  void updateActivity(String subscriptionId) {
    final info = _subscriptions[subscriptionId];
    if (info == null) return;

    _subscriptions[subscriptionId] = info.copyWith(
      lastActivityAt: DateTime.now(),
    );
  }

  /// 获取订阅信息
  StreamSubscriptionInfo? getSubscriptionInfo(String subscriptionId) {
    return _subscriptions[subscriptionId];
  }

  /// 获取所有订阅信息
  Map<String, StreamSubscriptionInfo> getAllSubscriptions() {
    return Map.unmodifiable(_subscriptions);
  }

  /// 获取活跃订阅数量
  int get activeSubscriptionCount {
    return _subscriptions.values
        .where((info) => info.state == StreamLifecycleState.listening)
        .length;
  }

  /// 获取指定Stream名称的订阅数量
  int getSubscriptionCountForStream(String streamName) {
    return _subscriptions.values
        .where((info) => info.streamName == streamName)
        .length;
  }

  /// 清理单个订阅
  Future<void> cleanupSubscription(String subscriptionId) async {
    final info = _subscriptions[subscriptionId];
    if (info == null) return;

    final reason = _getCleanupReason(info);
    if (reason != null) {
      if (_config.logWarnings) {
        AppLogger.warn('清理订阅 $subscriptionId ($reason)');
      }
      await cancelSubscription(subscriptionId);
    }
  }

  /// 获取清理原因
  String? _getCleanupReason(StreamSubscriptionInfo info) {
    final now = DateTime.now();

    // 检查是否超过最大生命周期
    if (now.difference(info.createdAt) > _config.maxLifetime) {
      return '超过最大生命周期';
    }

    // 检查是否长时间未活动
    if (info.lastActivityAt != null &&
        now.difference(info.lastActivityAt!) > _config.maxIdleTime) {
      return '长时间未活动';
    }

    // 检查是否处于错误状态
    if (info.state == StreamLifecycleState.error) {
      return '处于错误状态';
    }

    return null;
  }

  /// 清理所有符合条件的订阅
  Future<void> cleanup() async {
    if (!_config.enableAutoCleanup) return;

    final subscriptionsToCleanup = <String>[];

    for (final entry in _subscriptions.entries) {
      final subscriptionId = entry.key;
      final info = entry.value;

      final reason = _getCleanupReason(info);
      if (reason != null) {
        subscriptionsToCleanup.add(subscriptionId);

        if (_config.logWarnings) {
          AppLogger.warn('准备清理订阅 $subscriptionId ($reason)');
        }
      }
    }

    // 并行清理订阅
    final futures = subscriptionsToCleanup.map(cancelSubscription);
    await Future.wait(futures);

    if (subscriptionsToCleanup.isNotEmpty) {
      AppLogger.info('清理了 ${subscriptionsToCleanup.length} 个订阅');
    }
  }

  /// 清理所有订阅
  Future<void> cleanupAll() async {
    AppLogger.info('清理所有Stream订阅 (${_subscriptions.length}个)');

    final subscriptionIds = _subscriptions.keys.toList();
    final futures = subscriptionIds.map(cancelSubscription);
    await Future.wait(futures);

    _subscriptions.clear();
    AppLogger.info('所有Stream订阅已清理完成');
  }

  /// 处理Stream完成事件
  void _handleStreamDone(String subscriptionId) {
    final info = _subscriptions[subscriptionId];
    if (info == null) return;

    AppLogger.debug('Stream自然完成: $subscriptionId');

    _subscriptions[subscriptionId] = info.copyWith(
      state: StreamLifecycleState.closed,
      lastActivityAt: DateTime.now(),
    );

    // 自动清理
    if (_config.enableAutoCleanup) {
      Future.delayed(const Duration(seconds: 5), () {
        cancelSubscription(subscriptionId);
      });
    }
  }

  /// 启动健康检查
  void _startHealthCheck() {
    if (_healthCheckTimer != null) return;

    _healthCheckTimer = Timer.periodic(
      _config.healthCheckInterval,
      (_) => _performHealthCheck(),
    );

    AppLogger.debug('Stream健康检查已启动');
  }

  /// 执行健康检查
  void _performHealthCheck() {
    if (_subscriptions.isEmpty) return;

    final now = DateTime.now();
    final suspiciousSubscriptions = <String>[];
    final expiredSubscriptions = <String>[];

    for (final entry in _subscriptions.entries) {
      final subscriptionId = entry.key;
      final info = entry.value;

      // 检查过期订阅
      if (now.difference(info.createdAt) > _config.maxLifetime) {
        expiredSubscriptions.add(subscriptionId);
        continue;
      }

      // 检查长时间未活动的订阅
      if (info.lastActivityAt != null &&
          now.difference(info.lastActivityAt!) > _config.maxIdleTime) {
        suspiciousSubscriptions.add(subscriptionId);
      }
    }

    // 处理过期订阅
    if (expiredSubscriptions.isNotEmpty) {
      AppLogger.warn('发现 ${expiredSubscriptions.length} 个过期订阅，正在清理');
      for (final subscriptionId in expiredSubscriptions) {
        cancelSubscription(subscriptionId);
      }
    }

    // 处理可疑订阅
    if (suspiciousSubscriptions.isNotEmpty && _config.logWarnings) {
      AppLogger.warn('发现 ${suspiciousSubscriptions.length} 个长时间未活动的订阅');
      for (final subscriptionId in suspiciousSubscriptions) {
        final info = _subscriptions[subscriptionId];
        if (info != null) {
          AppLogger.debug('可疑订阅: $subscriptionId, '
              'Stream: ${info.streamName}, '
              '创建时间: ${info.createdAt}, '
              '最后活动: ${info.lastActivityAt}');
        }
      }
    }

    // 记录统计信息
    final totalCount = _subscriptions.length;
    final activeCount = activeSubscriptionCount;

    if (totalCount > 50) {
      // 如果订阅数量过多，记录警告
      AppLogger.warn('Stream订阅数量过多: $totalCount (活跃: $activeCount)');
    }
  }

  /// 获取管理器统计信息
  Map<String, dynamic> getStatistics() {
    final now = DateTime.now();
    final streamCounts = <String, int>{};
    final stateCounts = <StreamLifecycleState, int>{};

    for (final info in _subscriptions.values) {
      // 统计每个Stream的订阅数量
      streamCounts[info.streamName] = (streamCounts[info.streamName] ?? 0) + 1;

      // 统计状态分布
      stateCounts[info.state] = (stateCounts[info.state] ?? 0) + 1;
    }

    return {
      'totalSubscriptions': _subscriptions.length,
      'activeSubscriptions': activeSubscriptionCount,
      'streamCounts': streamCounts,
      'stateDistribution': stateCounts.map((k, v) => MapEntry(k.name, v)),
      'config': {
        'maxIdleTime': _config.maxIdleTime.inMinutes,
        'maxLifetime': _config.maxLifetime.inHours,
        'autoCleanupEnabled': _config.enableAutoCleanup,
        'healthCheckEnabled': _config.enableHealthCheck,
      },
      'lastHealthCheck':
          _healthCheckTimer?.tick != null ? now.toIso8601String() : null,
    };
  }

  /// 打印订阅统计信息
  void printStatistics() {
    final stats = getStatistics();
    AppLogger.info('Stream生命周期管理器统计: $stats');
  }
}

/// Stream订阅的便捷包装器
class ManagedStreamSubscription<T> {
  final String subscriptionId;
  final StreamLifecycleManager manager;
  final StreamSubscriptionInfo info;

  ManagedStreamSubscription({
    required this.subscriptionId,
    required this.manager,
    required this.info,
  });

  /// 暂停订阅
  Future<void> pause() => manager.pauseSubscription(subscriptionId);

  /// 恢复订阅
  Future<void> resume() => manager.resumeSubscription(subscriptionId);

  /// 取消订阅
  Future<void> cancel() => manager.cancelSubscription(subscriptionId);

  /// 更新活动时间
  void updateActivity() => manager.updateActivity(subscriptionId);

  /// 获取当前状态
  StreamLifecycleState get currentState =>
      manager.getSubscriptionInfo(subscriptionId)?.state ??
      StreamLifecycleState.created;

  /// 是否活跃
  bool get isActive => currentState == StreamLifecycleState.listening;

  /// 是否已暂停
  bool get isPaused => currentState == StreamLifecycleState.paused;

  /// 是否已关闭
  bool get isClosed => currentState == StreamLifecycleState.closed;
}
