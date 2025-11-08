import 'dart:async';
import '../../../features/fund/domain/entities/fund.dart';
import '../../../features/fund/domain/entities/fund_search_criteria.dart';
import '../../../features/fund/domain/entities/fund_ranking.dart';
import '../../cache/interfaces/i_unified_cache_service.dart';

/// 统一数据源接口
///
/// 提供统一的数据访问抽象，整合本地缓存、远程API和实时数据流
/// 支持智能路由、故障转移和性能优化
abstract class IUnifiedDataSource {
  // ===== 核心数据访问接口 =====

  /// 获取基金列表
  ///
  /// [criteria] 搜索和筛选条件
  /// [forceRefresh] 是否强制刷新缓存
  /// [timeout] 请求超时时间
  ///
  /// 返回符合条件的基金列表
  Future<List<Fund>> getFunds({
    FundSearchCriteria? criteria,
    bool forceRefresh = false,
    Duration? timeout,
  });

  /// 搜索基金
  ///
  /// [criteria] 搜索条件
  /// [useCache] 是否使用缓存
  ///
  /// 返回搜索结果
  Future<List<Fund>> searchFunds(
    FundSearchCriteria criteria, {
    bool useCache = true,
  });

  /// 获取基金排行榜
  ///
  /// [criteria] 排行榜筛选条件
  /// [page] 页码
  /// [pageSize] 每页大小
  ///
  /// 返回分页的排行榜结果
  Future<PaginatedRankingResult> getFundRankings(
    RankingCriteria criteria, {
    int page = 1,
    int pageSize = 20,
  });

  /// 批量获取基金详情
  ///
  /// [fundCodes] 基金代码列表
  /// [fields] 需要的字段列表（为空则获取全部字段）
  ///
  /// 返回基金详情列表
  Future<List<Fund>> getBatchFunds(
    List<String> fundCodes, {
    List<String>? fields,
  });

  // ===== 实时数据流接口 =====

  /// 获取实时数据流
  ///
  /// [fundCode] 基金代码
  /// [fields] 需要的字段列表
  ///
  /// 返回实时数据流
  Stream<FundData> getRealTimeData(
    String fundCode, {
    List<String>? fields,
  });

  /// 获取批量实时数据流
  ///
  /// [fundCodes] 基金代码列表
  ///
  /// 返回多个基金的实时数据流
  Stream<List<FundData>> getBatchRealTimeData(List<String> fundCodes);

  // ===== 缓存管理接口 =====

  /// 预加载数据
  ///
  /// [fundCodes] 需要预加载的基金代码列表
  /// [priority] 预加载优先级
  ///
  /// 异步预加载指定的基金数据
  Future<void> preloadData(
    List<String> fundCodes, {
    PreloadPriority priority = PreloadPriority.normal,
  });

  /// 智能预热缓存
  ///
  /// 根据用户使用模式智能预热常用数据
  Future<void> performSmartWarmup();

  /// 清除指定缓存
  ///
  /// [pattern] 缓存模式，支持通配符
  Future<void> clearCache({String? pattern});

  /// 获取缓存统计信息
  Future<CacheStatistics> getCacheStatistics();

  // ===== 数据同步接口 =====

  /// 执行数据同步
  ///
  /// [syncType] 同步类型
  /// [forceFullSync] 是否强制全量同步
  ///
  /// 返回同步结果
  Future<DataSyncResult> syncData({
    DataSyncType syncType = DataSyncType.incremental,
    bool forceFullSync = false,
  });

  /// 验证数据一致性
  ///
  /// 检查本地数据与远程数据的一致性
  Future<DataConsistencyReport> validateDataConsistency();

  /// 执行增量同步
  ///
  /// 基于时间戳或版本号进行增量同步
  Future<IncrementalSyncResult> performIncrementalSync({
    DateTime? since,
    String? lastVersion,
  });

  // ===== 健康检查和监控接口 =====

  /// 获取数据源健康状态
  Future<DataSourceHealthReport> getHealthReport();

  /// 获取性能指标
  Future<DataSourceMetrics> getPerformanceMetrics();

  /// 执行数据源自检
  Future<SelfCheckResult> performSelfCheck();
}

/// 数据同步类型
enum DataSyncType {
  /// 增量同步
  incremental,

  /// 全量同步
  full,

  /// 选择性同步
  selective,
}

/// 预加载优先级
enum PreloadPriority {
  /// 低优先级
  low,

  /// 普通优先级
  normal,

  /// 高优先级
  high,

  /// 紧急优先级
  urgent,
}

/// 缓存统计信息
class CacheStatistics {
  /// 总缓存项数量
  final int totalCount;

  /// 有效缓存项数量
  final int validCount;

  /// 过期缓存项数量
  final int expiredCount;

  /// 总缓存大小（字节）
  final int totalSize;

  /// 压缩节省的空间（字节）
  final int compressedSavings;

  /// 缓存命中率
  final double hitRate;

  /// 缓存未命中率
  final double missRate;

  /// 平均响应时间（毫秒）
  final double averageResponseTime;

  /// 按标签统计的缓存项数量
  final Map<String, int> tagCounts;

  /// 按优先级统计的缓存项数量
  final Map<int, int> priorityCounts;

  const CacheStatistics({
    required this.totalCount,
    required this.validCount,
    required this.expiredCount,
    required this.totalSize,
    required this.compressedSavings,
    required this.hitRate,
    required this.missRate,
    required this.averageResponseTime,
    required this.tagCounts,
    required this.priorityCounts,
  });

  /// 缓存使用率
  double get utilizationRate => totalCount > 0 ? validCount / totalCount : 0.0;

  /// 缓存效率分数
  double get efficiencyScore => (hitRate + utilizationRate) / 2;
}

/// 数据同步结果
class DataSyncResult {
  /// 同步是否成功
  final bool success;

  /// 同步的数据项数量
  final int syncedItemCount;

  /// 新增数据项数量
  final int addedItemCount;

  /// 更新数据项数量
  final int updatedItemCount;

  /// 删除数据项数量
  final int deletedItemCount;

  /// 同步耗时
  final Duration duration;

  /// 错误信息
  final String? error;

  /// 同步时间戳
  final DateTime timestamp;

  const DataSyncResult({
    required this.success,
    required this.syncedItemCount,
    required this.addedItemCount,
    required this.updatedItemCount,
    required this.deletedItemCount,
    required this.duration,
    this.error,
    required this.timestamp,
  });
}

/// 数据一致性报告
class DataConsistencyReport {
  /// 是否一致
  final bool isConsistent;

  /// 不一致项数量
  final int inconsistentItemCount;

  /// 总检查项数量
  final int totalItemCount;

  /// 不一致的基金代码列表
  final List<String> inconsistentFundCodes;

  /// 建议的修复操作
  final List<RecommendedAction> recommendedActions;

  /// 检查时间
  final DateTime checkTime;

  const DataConsistencyReport({
    required this.isConsistent,
    required this.inconsistentItemCount,
    required this.totalItemCount,
    required this.inconsistentFundCodes,
    required this.recommendedActions,
    required this.checkTime,
  });

  /// 一致性百分比
  double get consistencyPercentage => totalItemCount > 0
      ? (totalItemCount - inconsistentItemCount) / totalItemCount
      : 1.0;
}

/// 推荐操作
class RecommendedAction {
  /// 操作类型
  final ActionType type;

  /// 操作描述
  final String description;

  /// 影响的基金代码
  final List<String> affectedFundCodes;

  /// 优先级
  final ActionPriority priority;

  const RecommendedAction({
    required this.type,
    required this.description,
    required this.affectedFundCodes,
    required this.priority,
  });
}

/// 操作类型
enum ActionType {
  /// 刷新缓存
  refreshCache,

  /// 重新同步
  resync,

  /// 修复数据
  repairData,

  /// 删除损坏数据
  deleteCorruptedData,
}

/// 操作优先级
enum ActionPriority {
  /// 低优先级
  low,

  /// 中优先级
  medium,

  /// 高优先级
  high,

  /// 紧急
  critical,
}

/// 增量同步结果
class IncrementalSyncResult {
  /// 同步是否成功
  final bool success;

  /// 同步的变更项
  final List<DataChange> changes;

  /// 同步耗时
  final Duration duration;

  /// 下一版本标识
  final String? nextVersion;

  /// 错误信息
  final String? error;

  const IncrementalSyncResult({
    required this.success,
    required this.changes,
    required this.duration,
    this.nextVersion,
    this.error,
  });
}

/// 数据变更项
class DataChange {
  /// 变更类型
  final ChangeType changeType;

  /// 基金代码
  final String fundCode;

  /// 变更时间
  final DateTime changeTime;

  /// 变更的字段列表
  final List<String> changedFields;

  /// 旧值（可选）
  final Map<String, dynamic>? oldValue;

  /// 新值（可选）
  final Map<String, dynamic>? newValue;

  const DataChange({
    required this.changeType,
    required this.fundCode,
    required this.changeTime,
    required this.changedFields,
    this.oldValue,
    this.newValue,
  });
}

/// 变更类型
enum ChangeType {
  /// 新增
  added,

  /// 更新
  updated,

  /// 删除
  deleted,
}

/// 数据源健康报告
class DataSourceHealthReport {
  /// 整体健康状态
  final bool isHealthy;

  /// 各组件健康状态
  final Map<String, ComponentHealth> componentHealth;

  /// 活跃连接数
  final int activeConnections;

  /// 最后检查时间
  final DateTime lastCheckTime;

  /// 发现的问题
  final List<HealthIssue> issues;

  const DataSourceHealthReport({
    required this.isHealthy,
    required this.componentHealth,
    required this.activeConnections,
    required this.lastCheckTime,
    required this.issues,
  });
}

/// 组件健康状态
class ComponentHealth {
  /// 组件名称
  final String componentName;

  /// 是否健康
  final bool isHealthy;

  /// 响应时间（毫秒）
  final double responseTime;

  /// 最后成功时间
  final DateTime lastSuccessTime;

  /// 错误计数
  final int errorCount;

  const ComponentHealth({
    required this.componentName,
    required this.isHealthy,
    required this.responseTime,
    required this.lastSuccessTime,
    required this.errorCount,
  });
}

/// 健康问题
class HealthIssue {
  /// 问题级别
  final IssueSeverity severity;

  /// 问题描述
  final String description;

  /// 影响的组件
  final String affectedComponent;

  /// 建议解决方案
  final String suggestedSolution;

  const HealthIssue({
    required this.severity,
    required this.description,
    required this.affectedComponent,
    required this.suggestedSolution,
  });
}

/// 问题严重程度
enum IssueSeverity {
  /// 信息
  info,

  /// 警告
  warning,

  /// 错误
  error,

  /// 严重错误
  critical,
}

/// 数据源性能指标
class DataSourceMetrics {
  /// 平均响应时间（毫秒）
  final double averageResponseTime;

  /// 请求成功率
  final double successRate;

  /// 每秒请求数
  final double requestsPerSecond;

  /// 缓存命中率
  final double cacheHitRate;

  /// 数据传输量（字节）
  final int dataTransferVolume;

  /// 活跃连接数
  final int activeConnections;

  /// 错误计数
  final int errorCount;

  const DataSourceMetrics({
    required this.averageResponseTime,
    required this.successRate,
    required this.requestsPerSecond,
    required this.cacheHitRate,
    required this.dataTransferVolume,
    required this.activeConnections,
    required this.errorCount,
  });
}

/// 自检结果
class SelfCheckResult {
  /// 自检是否通过
  final bool passed;

  /// 检查项目结果
  final Map<String, CheckItemResult> checkResults;

  /// 总体评分
  final double overallScore;

  /// 检查耗时
  final Duration duration;

  const SelfCheckResult({
    required this.passed,
    required this.checkResults,
    required this.overallScore,
    required this.duration,
  });
}

/// 检查项结果
class CheckItemResult {
  /// 检查项名称
  final String itemName;

  /// 是否通过
  final bool passed;

  /// 得分
  final double score;

  /// 详细信息
  final String details;

  const CheckItemResult({
    required this.itemName,
    required this.passed,
    required this.score,
    required this.details,
  });
}

/// 实时数据项
class FundData {
  /// 基金代码
  final String fundCode;

  /// 数据字段
  final Map<String, dynamic> fields;

  /// 数据时间戳
  final DateTime timestamp;

  /// 数据版本
  final String version;

  const FundData({
    required this.fundCode,
    required this.fields,
    required this.timestamp,
    required this.version,
  });
}
