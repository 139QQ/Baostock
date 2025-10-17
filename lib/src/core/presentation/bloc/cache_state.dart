part of 'cache_bloc.dart';

/// 缓存状态枚举
enum CacheStatus {
  initial, // 初始状态
  loading, // 加载中
  initialized, // 已初始化
  dataStored, // 数据已存储
  dataRetrieved, // 数据已获取
  dataRemoved, // 数据已移除
  cleared, // 已清空
  clearing, // 清空中
  expiredCleared, // 过期数据已清理
  statisticsReady, // 统计信息已准备
  monitoring, // 监控中
  policyUpdated, // 策略已更新
  error, // 错误状态
}

/// 缓存操作类型枚举
enum CacheOperation {
  store, // 存储
  retrieve, // 获取
  remove, // 移除
  clearAll, // 清空所有
  clearExpired, // 清理过期
}

/// 缓存策略枚举
enum CachePolicy {
  aggressive, // 激进策略：大量缓存，长期保存
  balanced, // 平衡策略：适中的缓存大小和过期时间
  conservative, // 保守策略：最小缓存，快速过期
  custom, // 自定义策略
}

/// 缓存状态类
class CacheState extends Equatable {
  /// 当前状态
  final CacheStatus status;

  /// 最后操作
  final CacheOperation? lastOperation;

  /// 最后操作的键
  final String? lastOperationKey;

  /// 最后操作结果
  final dynamic lastOperationResult;

  /// 缓存命中次数
  final int cacheHits;

  /// 缓存未命中次数
  final int cacheMisses;

  /// 缓存命中率
  final double hitRate;

  /// 缓存统计信息
  final Map<String, dynamic> statistics;

  /// 最后更新时间
  final DateTime? lastUpdated;

  /// 错误信息
  final String? errorMessage;

  /// 是否正在监控
  final bool isMonitoring;

  /// 缓存策略
  final CachePolicy? cachePolicy;

  const CacheState({
    this.status = CacheStatus.initial,
    this.lastOperation,
    this.lastOperationKey,
    this.lastOperationResult,
    this.cacheHits = 0,
    this.cacheMisses = 0,
    this.hitRate = 0.0,
    this.statistics = const {},
    this.lastUpdated,
    this.errorMessage,
    this.isMonitoring = false,
    this.cachePolicy,
  });

  /// 初始状态
  factory CacheState.initial() {
    return const CacheState(
      status: CacheStatus.initial,
    );
  }

  /// 加载状态
  factory CacheState.loading() {
    return CacheState(
      status: CacheStatus.loading,
      lastUpdated: DateTime.now(),
    );
  }

  /// 创建副本
  CacheState copyWith({
    CacheStatus? status,
    CacheOperation? lastOperation,
    String? lastOperationKey,
    dynamic lastOperationResult,
    int? cacheHits,
    int? cacheMisses,
    double? hitRate,
    Map<String, dynamic>? statistics,
    DateTime? lastUpdated,
    String? errorMessage,
    bool? isMonitoring,
    CachePolicy? cachePolicy,
    bool clearError = false,
  }) {
    return CacheState(
      status: status ?? this.status,
      lastOperation: lastOperation ?? this.lastOperation,
      lastOperationKey: lastOperationKey ?? this.lastOperationKey,
      lastOperationResult: lastOperationResult ?? this.lastOperationResult,
      cacheHits: cacheHits ?? this.cacheHits,
      cacheMisses: cacheMisses ?? this.cacheMisses,
      hitRate: hitRate ?? this.hitRate,
      statistics: statistics ?? this.statistics,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isMonitoring: isMonitoring ?? this.isMonitoring,
      cachePolicy: cachePolicy ?? this.cachePolicy,
    );
  }

  /// 是否为错误状态
  bool get isError => status == CacheStatus.error;

  /// 是否为加载状态
  bool get isLoading =>
      status == CacheStatus.loading || status == CacheStatus.clearing;

  /// 是否已初始化
  bool get isInitialized => status == CacheStatus.initialized;

  /// 是否有数据
  bool get hasData => (statistics['size'] ?? 0) > 0;

  /// 获取缓存大小
  int get cacheSize => statistics['size'] ?? 0;

  /// 获取总操作次数
  int get totalOperations => cacheHits + cacheMisses;

  /// 是否为健康状态
  bool get isHealthy => !isError && hitRate > 0.3;

  /// 获取状态描述
  String get statusDescription {
    switch (status) {
      case CacheStatus.initial:
        return '初始状态';
      case CacheStatus.loading:
        return '加载中';
      case CacheStatus.initialized:
        return '已初始化';
      case CacheStatus.dataStored:
        return '数据已存储';
      case CacheStatus.dataRetrieved:
        return '数据已获取';
      case CacheStatus.dataRemoved:
        return '数据已移除';
      case CacheStatus.cleared:
        return '已清空';
      case CacheStatus.clearing:
        return '清空中';
      case CacheStatus.expiredCleared:
        return '过期数据已清理';
      case CacheStatus.statisticsReady:
        return '统计信息已准备';
      case CacheStatus.monitoring:
        return '监控中';
      case CacheStatus.policyUpdated:
        return '策略已更新';
      case CacheStatus.error:
        return '错误状态';
    }
  }

  /// 获取操作描述
  String get operationDescription {
    if (lastOperation == null) return '无操作';

    switch (lastOperation!) {
      case CacheOperation.store:
        return '存储数据';
      case CacheOperation.retrieve:
        return '获取数据';
      case CacheOperation.remove:
        return '移除数据';
      case CacheOperation.clearAll:
        return '清空所有';
      case CacheOperation.clearExpired:
        return '清理过期';
    }
  }

  /// 获取性能评级
  String get performanceRating {
    if (hitRate >= 0.8) return '优秀';
    if (hitRate >= 0.6) return '良好';
    if (hitRate >= 0.4) return '一般';
    if (hitRate >= 0.2) return '较差';
    return '很差';
  }

  /// 获取建议操作
  List<String> get recommendations {
    final recommendations = <String>[];

    if (hitRate < 0.3) {
      recommendations.add('缓存命中率过低，建议检查缓存策略');
    }

    if (cacheSize > 1000) {
      recommendations.add('缓存项数量过多，建议定期清理');
    }

    if (isError) {
      recommendations.add('缓存系统存在错误，请检查错误信息');
    }

    if (!isInitialized) {
      recommendations.add('缓存未初始化，请执行初始化操作');
    }

    if (totalOperations > 1000 && hitRate < 0.5) {
      recommendations.add('操作频繁但命中率低，建议优化缓存键设计');
    }

    return recommendations;
  }

  @override
  List<Object?> get props => [
        status,
        lastOperation,
        lastOperationKey,
        lastOperationResult,
        cacheHits,
        cacheMisses,
        hitRate,
        statistics,
        lastUpdated,
        errorMessage,
        isMonitoring,
        cachePolicy,
      ];

  @override
  String toString() {
    return 'CacheState{'
        'status: $status, '
        'hits: $cacheHits, '
        'misses: $cacheMisses, '
        'hitRate: ${(hitRate * 100).toStringAsFixed(1)}%, '
        'cacheSize: $cacheSize, '
        'isHealthy: $isHealthy'
        '}';
  }
}
