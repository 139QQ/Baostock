import 'dart:async';

/// 数据一致性管理器接口
///
/// 负责维护多数据源之间的数据一致性，处理冲突检测和解决
/// 支持版本控制、增量同步和数据验证
abstract class IDataConsistencyManager {
  // ===== 生命周期管理接口 =====

  /// 初始化一致性管理器
  Future<void> initialize();

  /// 释放资源
  Future<void> dispose();

  // ===== 一致性验证接口 =====

  /// 验证数据一致性
  ///
  /// [validationScope] 验证范围
  /// [dataSourceIds] 要验证的数据源ID列表
  ///
  /// 返回一致性验证结果
  Future<ConsistencyValidationResult> validateDataConsistency({
    ValidationScope validationScope = ValidationScope.full,
    List<String>? dataSourceIds,
  });

  /// 执行增量一致性检查
  ///
  /// [lastCheckTime] 上次检查时间
  /// [changeTypes] 要检查的变更类型
  ///
  /// 返回增量检查结果
  Future<IncrementalConsistencyResult> performIncrementalConsistencyCheck({
    DateTime? lastCheckTime,
    List<ChangeType>? changeTypes,
  });

  /// 验证特定数据项的一致性
  Future<ItemConsistencyResult> validateItemConsistency(
    String itemType,
    String itemId,
  );

  /// 批量验证数据项一致性
  Future<List<ItemConsistencyResult>> validateItemsConsistencyBatch(
    List<ItemReference> items,
  );

  // ===== 冲突检测和解决接口 =====

  /// 检测数据冲突
  ///
  /// [dataSources] 要检查的数据源列表
  /// [conflictDetectionStrategy] 冲突检测策略
  ///
  /// 返回检测到的冲突列表
  Future<List<DataConflict>> detectConflicts(
    List<DataSource> dataSources, {
    ConflictDetectionStrategy conflictDetectionStrategy =
        ConflictDetectionStrategy.timestampBased,
  });

  /// 解决数据冲突
  ///
  /// [conflict] 要解决的冲突
  /// [resolutionStrategy] 解决策略
  ///
  /// 返回冲突解决结果
  Future<ConflictResolutionResult> resolveConflict(
    DataConflict conflict, {
    ConflictResolutionStrategy resolutionStrategy =
        ConflictResolutionStrategy.auto,
  });

  /// 批量解决冲突
  Future<List<ConflictResolutionResult>> resolveConflictsBatch(
    List<DataConflict> conflicts, {
    ConflictResolutionStrategy resolutionStrategy =
        ConflictResolutionStrategy.auto,
  });

  /// 预览冲突解决方案
  Future<ConflictResolutionPreview> previewConflictResolution(
    DataConflict conflict,
    ConflictResolutionStrategy strategy,
  );

  // ===== 版本控制接口 =====

  /// 创建数据版本
  ///
  /// [dataItems] 要版本化的数据项
  /// [metadata] 版本元数据
  ///
  /// 返回创建的版本信息
  Future<DataVersion> createVersion(
    List<DataItem> dataItems, {
    VersionMetadata? metadata,
  });

  /// 获取数据版本历史
  Future<List<DataVersion>> getVersionHistory(
    String itemType,
    String itemId, {
    int? limit,
    DateTime? startTime,
    DateTime? endTime,
  });

  /// 回滚到指定版本
  Future<VersionRollbackResult> rollbackToVersion(
    String itemType,
    String itemId,
    String versionId,
  );

  /// 比较数据版本
  Future<VersionComparisonResult> compareVersions(
    String itemType,
    String itemId,
    String versionId1,
    String versionId2,
  );

  /// 合并数据版本
  Future<VersionMergeResult> mergeVersions(
    String itemType,
    String itemId,
    List<String> versionIds, {
    MergeStrategy mergeStrategy = MergeStrategy.latestWins,
  });

  // ===== 增量同步接口 =====

  /// 执行增量同步
  ///
  /// [syncScope] 同步范围
  /// [syncDirection] 同步方向
  /// [lastSyncTime] 上次同步时间
  ///
  /// 返回同步结果
  Future<IncrementalSyncResult> performIncrementalSync({
    SyncScope syncScope = SyncScope.all,
    SyncDirection syncDirection = SyncDirection.bidirectional,
    DateTime? lastSyncTime,
  });

  /// 获取同步状态
  Future<SyncStatus> getSyncStatus({
    String? dataSourceId,
  });

  /// 暂停同步
  Future<void> pauseSync({
    String? dataSourceId,
  });

  /// 恢复同步
  Future<void> resumeSync({
    String? dataSourceId,
  });

  /// 强制同步
  Future<ForceSyncResult> forceSync({
    List<String>? dataSourceIds,
    SyncScope syncScope = SyncScope.all,
  });

  // ===== 数据完整性验证接口 =====

  /// 验证数据完整性
  ///
  /// [integrityCheckType] 完整性检查类型
  /// [dataScope] 数据范围
  ///
  /// 返回完整性验证结果
  Future<IntegrityValidationResult> validateDataIntegrity({
    IntegrityCheckType integrityCheckType = IntegrityCheckType.comprehensive,
    DataScope? dataScope,
  });

  /// 修复数据完整性问题
  Future<IntegrityRepairResult> repairIntegrityIssues(
    List<IntegrityIssue> issues,
  );

  /// 获取数据完整性报告
  Future<IntegrityReport> getIntegrityReport({
    ReportScope scope = ReportScope.full,
  });

  // ===== 监控和报告接口 =====

  /// 获取一致性监控指标
  Future<ConsistencyMetrics> getConsistencyMetrics({
    MetricsPeriod period = MetricsPeriod.last24Hours,
  });

  /// 生成一致性报告
  Future<ConsistencyReport> generateConsistencyReport({
    ReportType reportType = ReportType.summary,
    DateTime? startTime,
    DateTime? endTime,
  });

  /// 获取一致性趋势
  Future<List<ConsistencyTrendPoint>> getConsistencyTrend({
    TrendPeriod period = TrendPeriod.last7Days,
    TrendMetric metric = TrendMetric.consistencyRate,
  });

  /// 配置一致性规则
  Future<void> configureConsistencyRules(
    List<ConsistencyRule> rules,
  );

  /// 获取一致性规则
  Future<List<ConsistencyRule>> getConsistencyRules();

  // ===== 断线缓存和恢复接口 =====

  /// 记录数据变更（用于断线期间缓存）
  ///
  /// [dataType] 数据类型
  /// [dataKey] 数据键
  /// [data] 数据内容
  /// [sourceId] 数据源ID
  /// [changeType] 变更类型
  /// [previousData] 变更前的数据
  /// [metadata] 变更元数据
  Future<void> recordDataChange({
    required String dataType,
    required String dataKey,
    required Map<String, dynamic> data,
    required String sourceId,
    String changeType = 'update',
    Map<String, dynamic>? previousData,
    Map<String, dynamic>? metadata,
  });

  /// 获取断线期间缓存的数据变更
  ///
  /// [since] 起始时间
  /// [dataType] 数据类型过滤
  /// [sourceId] 数据源过滤
  ///
  /// 返回缓存的变更记录列表
  Future<List<OfflineDataChange>> getCachedChanges({
    DateTime? since,
    String? dataType,
    String? sourceId,
  });

  /// 清理过期的缓存数据
  ///
  /// [olderThan] 清理多久之前的数据
  Future<void> cleanupExpiredCache({Duration? olderThan});

  /// 同步缓存的变更到远程数据源
  ///
  /// [sourceId] 目标数据源ID
  /// [changeIds] 要同步的变更ID列表，为空则同步所有
  ///
  /// 返回同步结果
  Future<OfflineSyncResult> syncCachedChanges({
    String? sourceId,
    List<String>? changeIds,
  });

  /// 检测数据冲突（本地缓存 vs 远程数据）
  ///
  /// [dataKey] 数据键
  /// [localData] 本地缓存数据
  /// [remoteData] 远程数据
  /// [remoteChecksum] 远程数据校验和
  ///
  /// 返回是否存在冲突
  bool detectDataConflict(
    String dataKey,
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
    String remoteChecksum,
  );

  /// 解决数据冲突
  ///
  /// [dataKey] 数据键
  /// [strategy] 解决策略
  /// [resolvedData] 解决后的数据
  Future<void> resolveDataConflict({
    required String dataKey,
    required ConflictResolutionStrategy strategy,
    Map<String, dynamic>? resolvedData,
  });

  /// 获取缓存统计信息
  Future<OfflineCacheStats> getCacheStats();

  /// 获取离线同步状态
  Future<OfflineSyncStatus> getOfflineSyncStatus();
}

/// 一致性验证结果
class ConsistencyValidationResult {
  /// 验证是否通过
  final bool isValid;

  /// 验证的数据项总数
  final int totalItemsChecked;

  /// 一致的数据项数量
  final int consistentItemsCount;

  /// 不一致的数据项数量
  final int inconsistentItemsCount;

  /// 不一致项的详细信息
  final List<InconsistencyDetail> inconsistencies;

  /// 验证耗时
  final Duration validationDuration;

  /// 验证时间戳
  final DateTime validationTime;

  const ConsistencyValidationResult({
    required this.isValid,
    required this.totalItemsChecked,
    required this.consistentItemsCount,
    required this.inconsistentItemsCount,
    required this.inconsistencies,
    required this.validationDuration,
    required this.validationTime,
  });

  /// 一致性率
  double get consistencyRate =>
      totalItemsChecked > 0 ? consistentItemsCount / totalItemsChecked : 1.0;
}

/// 验证范围
enum ValidationScope {
  /// 完整验证
  full,

  /// 增量验证
  incremental,

  /// 选择性验证
  selective,
}

/// 不一致详情
class InconsistencyDetail {
  /// 数据项类型
  final String itemType;

  /// 数据项ID
  final String itemId;

  /// 不一致的数据源
  final Map<String, dynamic> inconsistentData;

  /// 不一致类型
  final InconsistencyType inconsistencyType;

  /// 严重程度
  final Severity severity;

  /// 发现时间
  final DateTime detectedTime;

  const InconsistencyDetail({
    required this.itemType,
    required this.itemId,
    required this.inconsistentData,
    required this.inconsistencyType,
    required this.severity,
    required this.detectedTime,
  });
}

/// 不一致类型
enum InconsistencyType {
  /// 数据值不同
  valueMismatch,

  /// 数据缺失
  missingData,

  /// 数据格式不匹配
  formatMismatch,

  /// 版本冲突
  versionConflict,

  /// 时间戳不同步
  timestampMismatch,
}

/// 严重程度
enum Severity {
  /// 低
  low,

  /// 中
  medium,

  /// 高
  high,

  /// 严重
  critical,
}

/// 增量一致性检查结果
class IncrementalConsistencyResult {
  /// 检查是否成功
  final bool success;

  /// 发现的新变更
  final List<DataChange> newChanges;

  /// 检测到的冲突
  final List<DataConflict> detectedConflicts;

  /// 检查的数据源数量
  final int dataSourceCount;

  /// 检查耗时
  final Duration checkDuration;

  const IncrementalConsistencyResult({
    required this.success,
    required this.newChanges,
    required this.detectedConflicts,
    required this.dataSourceCount,
    required this.checkDuration,
  });
}

/// 数据项一致性结果
class ItemConsistencyResult {
  /// 数据项引用
  final ItemReference itemReference;

  /// 是否一致
  final bool isConsistent;

  /// 各数据源的数据状态
  final Map<String, DataStatus> dataSourceStatus;

  /// 发现的差异
  final List<DataDifference> differences;

  const ItemConsistencyResult({
    required this.itemReference,
    required this.isConsistent,
    required this.dataSourceStatus,
    required this.differences,
  });
}

/// 数据项引用
class ItemReference {
  /// 数据项类型
  final String itemType;

  /// 数据项ID
  final String itemId;

  const ItemReference({
    required this.itemType,
    required this.itemId,
  });
}

/// 数据状态
class DataStatus {
  /// 数据源ID
  final String dataSourceId;

  /// 是否存在数据
  final bool hasData;

  /// 数据版本
  final String? version;

  /// 最后更新时间
  final DateTime? lastUpdated;

  /// 数据完整性
  final bool isComplete;

  const DataStatus({
    required this.dataSourceId,
    required this.hasData,
    this.version,
    this.lastUpdated,
    required this.isComplete,
  });
}

/// 数据差异
class DataDifference {
  /// 差异字段
  final String field;

  /// 数据源1的值
  final dynamic value1;

  /// 数据源2的值
  final dynamic value2;

  /// 差异类型
  final DifferenceType differenceType;

  const DataDifference({
    required this.field,
    this.value1,
    this.value2,
    required this.differenceType,
  });
}

/// 差异类型
enum DifferenceType {
  /// 值不同
  valueDifference,

  /// 类型不同
  typeDifference,

  /// 一方缺失
  missingInOne,
}

/// 数据冲突
class DataConflict {
  /// 冲突ID
  final String conflictId;

  /// 冲突的数据项
  final ItemReference itemReference;

  /// 冲突的数据源
  final List<ConflictDataSource> conflictingSources;

  /// 冲突类型
  final ConflictType conflictType;

  /// 冲突描述
  final String description;

  /// 严重程度
  final Severity severity;

  /// 发现时间
  final DateTime detectedTime;

  /// 冲突状态
  final ConflictStatus status;

  const DataConflict({
    required this.conflictId,
    required this.itemReference,
    required this.conflictingSources,
    required this.conflictType,
    required this.description,
    required this.severity,
    required this.detectedTime,
    required this.status,
  });
}

/// 冲突数据源
class ConflictDataSource {
  /// 数据源ID
  final String dataSourceId;

  /// 数据值
  final dynamic dataValue;

  /// 数据版本
  final String version;

  /// 最后更新时间
  final DateTime lastUpdated;

  const ConflictDataSource({
    required this.dataSourceId,
    required this.dataValue,
    required this.version,
    required this.lastUpdated,
  });
}

/// 冲突类型
enum ConflictType {
  /// 值冲突
  valueConflict,

  /// 版本冲突
  versionConflict,

  /// 格式冲突
  formatConflict,

  /// 结构冲突
  structureConflict,
}

/// 冲突状态
enum ConflictStatus {
  /// 待处理
  pending,

  /// 解决中
  resolving,

  /// 已解决
  resolved,

  /// 已忽略
  ignored,
}

/// 冲突检测策略
enum ConflictDetectionStrategy {
  /// 基于时间戳
  timestampBased,

  /// 基于版本号
  versionBased,

  /// 基于内容哈希
  contentHashBased,

  /// 基于业务规则
  businessRuleBased,
}

/// 冲突解决结果
class ConflictResolutionResult {
  /// 冲突ID
  final String conflictId;

  /// 解决是否成功
  final bool success;

  /// 解决策略
  final ConflictResolutionStrategy usedStrategy;

  /// 解决后的值
  final dynamic resolvedValue;

  /// 解决时间
  final DateTime resolutionTime;

  /// 解决耗时
  final Duration resolutionDuration;

  /// 解决操作日志
  final List<ResolutionAction> resolutionActions;

  const ConflictResolutionResult({
    required this.conflictId,
    required this.success,
    required this.usedStrategy,
    this.resolvedValue,
    required this.resolutionTime,
    required this.resolutionDuration,
    required this.resolutionActions,
  });
}

/// 冲突解决策略
enum ConflictResolutionStrategy {
  /// 自动解决
  auto,

  /// 手动解决
  manual,

  /// 最新版本获胜
  latestWins,

  /// 最旧版本获胜
  earliestWins,

  /// 合并解决
  merge,

  /// 用户选择
  userChoice,
}

/// 解决操作
class ResolutionAction {
  /// 操作类型
  final ActionType type;

  /// 操作描述
  final String description;

  /// 操作时间
  final DateTime timestamp;

  /// 操作结果
  final dynamic result;

  const ResolutionAction({
    required this.type,
    required this.description,
    required this.timestamp,
    this.result,
  });
}

/// 冲突解决预览
class ConflictResolutionPreview {
  /// 冲突信息
  final DataConflict conflict;

  /// 解决策略
  final ConflictResolutionStrategy strategy;

  /// 预期结果
  final dynamic expectedOutcome;

  /// 影响分析
  final ImpactAnalysis impactAnalysis;

  const ConflictResolutionPreview({
    required this.conflict,
    required this.strategy,
    required this.expectedOutcome,
    required this.impactAnalysis,
  });
}

/// 影响分析
class ImpactAnalysis {
  /// 影响的数据源数量
  final int affectedDataSources;

  /// 影响的用户数量
  final int affectedUsers;

  /// 影响的功能模块
  final List<String> affectedModules;

  /// 预期的性能影响
  final PerformanceImpact performanceImpact;

  const ImpactAnalysis({
    required this.affectedDataSources,
    required this.affectedUsers,
    required this.affectedModules,
    required this.performanceImpact,
  });
}

/// 性能影响
class PerformanceImpact {
  /// 响应时间影响
  final double responseTimeImpact;

  /// 吞吐量影响
  final double throughputImpact;

  /// 资源使用影响
  final double resourceUsageImpact;

  const PerformanceImpact({
    required this.responseTimeImpact,
    required this.throughputImpact,
    required this.resourceUsageImpact,
  });
}

/// 数据版本
class DataVersion {
  /// 版本ID
  final String versionId;

  /// 数据项类型
  final String itemType;

  /// 数据项ID
  final String itemId;

  /// 版本号
  final int versionNumber;

  /// 版本数据
  final Map<String, dynamic> versionData;

  /// 创建时间
  final DateTime createdAt;

  /// 创建者
  final String createdBy;

  /// 版本元数据
  final VersionMetadata metadata;

  /// 父版本ID
  final String? parentVersionId;

  /// 变更日志
  final List<VersionChangeLog> changeLog;

  const DataVersion({
    required this.versionId,
    required this.itemType,
    required this.itemId,
    required this.versionNumber,
    required this.versionData,
    required this.createdAt,
    required this.createdBy,
    required this.metadata,
    this.parentVersionId,
    required this.changeLog,
  });
}

/// 版本元数据
class VersionMetadata {
  /// 版本标签
  final List<String> tags;

  /// 版本描述
  final String description;

  /// 版本类型
  final VersionType versionType;

  /// 是否为主要版本
  final bool isMajor;

  /// 自定义属性
  final Map<String, dynamic> customAttributes;

  const VersionMetadata({
    required this.tags,
    required this.description,
    required this.versionType,
    required this.isMajor,
    required this.customAttributes,
  });
}

/// 版本类型
enum VersionType {
  /// 自动版本
  automatic,

  /// 手动版本
  manual,

  /// 快照版本
  snapshot,

  /// 合并版本
  merge,
}

/// 版本变更日志
class VersionChangeLog {
  /// 变更类型
  final ChangeType changeType;

  /// 变更字段
  final String field;

  /// 旧值
  final dynamic oldValue;

  /// 新值
  final dynamic newValue;

  /// 变更原因
  final String reason;

  const VersionChangeLog({
    required this.changeType,
    required this.field,
    this.oldValue,
    this.newValue,
    required this.reason,
  });
}

/// 数据项
class DataItem {
  /// 数据项类型
  final String itemType;

  /// 数据项ID
  final String itemId;

  /// 数据内容
  final Map<String, dynamic> data;

  /// 当前版本
  final String currentVersion;

  /// 最后更新时间
  final DateTime lastUpdated;

  const DataItem({
    required this.itemType,
    required this.itemId,
    required this.data,
    required this.currentVersion,
    required this.lastUpdated,
  });
}

/// 版本回滚结果
class VersionRollbackResult {
  /// 回滚是否成功
  final bool success;

  /// 原版本ID
  final String originalVersionId;

  /// 目标版本ID
  final String targetVersionId;

  /// 回滚时间
  final DateTime rollbackTime;

  /// 回滚耗时
  final Duration rollbackDuration;

  /// 回滚影响的数据项
  final List<ItemReference> affectedItems;

  /// 错误信息
  final String? error;

  const VersionRollbackResult({
    required this.success,
    required this.originalVersionId,
    required this.targetVersionId,
    required this.rollbackTime,
    required this.rollbackDuration,
    required this.affectedItems,
    this.error,
  });
}

/// 版本比较结果
class VersionComparisonResult {
  /// 版本1信息
  final DataVersion version1;

  /// 版本2信息
  final DataVersion version2;

  /// 差异列表
  final List<VersionDifference> differences;

  /// 相似度评分
  final double similarityScore;

  /// 比较时间
  final DateTime comparisonTime;

  const VersionComparisonResult({
    required this.version1,
    required this.version2,
    required this.differences,
    required this.similarityScore,
    required this.comparisonTime,
  });
}

/// 版本差异
class VersionDifference {
  /// 差异字段
  final String field;

  /// 版本1的值
  final dynamic value1;

  /// 版本2的值
  final dynamic value2;

  /// 差异类型
  final VersionDifferenceType differenceType;

  const VersionDifference({
    required this.field,
    this.value1,
    this.value2,
    required this.differenceType,
  });
}

/// 版本差异类型
enum VersionDifferenceType {
  /// 值差异
  valueDifference,

  /// 结构差异
  structureDifference,

  /// 新增字段
  addedField,

  /// 删除字段
  removedField,
}

/// 版本合并结果
class VersionMergeResult {
  /// 合并是否成功
  final bool success;

  /// 合并的版本列表
  final List<DataVersion> mergedVersions;

  /// 合并后的版本
  final DataVersion mergedVersion;

  /// 合并冲突
  final List<MergeConflict> mergeConflicts;

  /// 合并策略
  final MergeStrategy mergeStrategy;

  /// 合并时间
  final DateTime mergeTime;

  const VersionMergeResult({
    required this.success,
    required this.mergedVersions,
    required this.mergedVersion,
    required this.mergeConflicts,
    required this.mergeStrategy,
    required this.mergeTime,
  });
}

/// 合并冲突
class MergeConflict {
  /// 冲突字段
  final String field;

  /// 冲突的值列表
  final List<dynamic> conflictingValues;

  /// 冲突解决方式
  final MergeConflictResolution resolution;

  const MergeConflict({
    required this.field,
    required this.conflictingValues,
    required this.resolution,
  });
}

/// 合并冲突解决
class MergeConflictResolution {
  /// 解决方式
  final ConflictResolutionStrategy strategy;

  /// 最终值
  final dynamic finalValue;

  /// 解决描述
  final String description;

  const MergeConflictResolution({
    required this.strategy,
    required this.finalValue,
    required this.description,
  });
}

/// 合并策略
enum MergeStrategy {
  /// 最新版本获胜
  latestWins,

  /// 最旧版本获胜
  earliestWins,

  /// 合并所有变更
  mergeAll,

  /// 保留冲突
  keepConflicts,

  /// 用户选择
  userChoice,
}

/// 同步范围
enum SyncScope {
  /// 全部同步
  all,

  /// 选择性同步
  selective,

  /// 增量同步
  incremental,
}

/// 同步方向
enum SyncDirection {
  /// 单向同步
  unidirectional,

  /// 双向同步
  bidirectional,
}

/// 同步状态
class SyncStatus {
  /// 数据源ID
  final String? dataSourceId;

  /// 同步状态
  final SyncState state;

  /// 最后同步时间
  final DateTime? lastSyncTime;

  /// 待同步变更数量
  final int pendingChangesCount;

  /// 同步进度
  final double progress;

  /// 错误信息
  final String? error;

  const SyncStatus({
    this.dataSourceId,
    required this.state,
    this.lastSyncTime,
    required this.pendingChangesCount,
    required this.progress,
    this.error,
  });
}

/// 同步状态
enum SyncState {
  /// 运行中
  running,

  /// 已暂停
  paused,

  /// 已停止
  stopped,

  /// 错误
  error,

  /// 完成
  completed,
}

/// 强制同步结果
class ForceSyncResult {
  /// 同步是否成功
  final bool success;

  /// 同步的数据源数量
  final int syncedDataSourcesCount;

  /// 同步的数据项数量
  final int syncedItemsCount;

  /// 同步耗时
  final Duration syncDuration;

  /// 同步时间戳
  final DateTime syncTime;

  /// 错误信息
  final String? error;

  const ForceSyncResult({
    required this.success,
    required this.syncedDataSourcesCount,
    required this.syncedItemsCount,
    required this.syncDuration,
    required this.syncTime,
    this.error,
  });
}

/// 完整性检查类型
enum IntegrityCheckType {
  /// 完整检查
  comprehensive,

  /// 快速检查
  quick,

  /// 深度检查
  deep,

  /// 选择性检查
  selective,
}

/// 数据范围
class DataScope {
  /// 数据项类型
  final List<String> itemTypes;

  /// 数据源ID列表
  final List<String>? dataSourceIds;

  /// 时间范围
  final TimeRange? timeRange;

  /// 数据数量限制
  final int? limit;

  const DataScope({
    required this.itemTypes,
    this.dataSourceIds,
    this.timeRange,
    this.limit,
  });
}

/// 时间范围
class TimeRange {
  /// 开始时间
  final DateTime startTime;

  /// 结束时间
  final DateTime endTime;

  const TimeRange({
    required this.startTime,
    required this.endTime,
  });
}

/// 完整性验证结果
class IntegrityValidationResult {
  /// 验证是否通过
  final bool isValid;

  /// 检查的数据项总数
  final int totalItemsChecked;

  /// 完整的数据项数量
  final int intactItemsCount;

  /// 损坏的数据项数量
  final int corruptedItemsCount;

  /// 发现的完整性问题
  final List<IntegrityIssue> issues;

  /// 验证耗时
  final Duration validationDuration;

  const IntegrityValidationResult({
    required this.isValid,
    required this.totalItemsChecked,
    required this.intactItemsCount,
    required this.corruptedItemsCount,
    required this.issues,
    required this.validationDuration,
  });

  /// 完整性率
  double get integrityRate =>
      totalItemsChecked > 0 ? intactItemsCount / totalItemsChecked : 1.0;
}

/// 完整性问题
class IntegrityIssue {
  /// 问题ID
  final String issueId;

  /// 数据项引用
  final ItemReference itemReference;

  /// 问题类型
  final IntegrityIssueType issueType;

  /// 问题描述
  final String description;

  /// 严重程度
  final Severity severity;

  /// 发现时间
  final DateTime detectedTime;

  /// 修复建议
  final String repairSuggestion;

  const IntegrityIssue({
    required this.issueId,
    required this.itemReference,
    required this.issueType,
    required this.description,
    required this.severity,
    required this.detectedTime,
    required this.repairSuggestion,
  });
}

/// 完整性问题类型
enum IntegrityIssueType {
  /// 数据损坏
  dataCorruption,

  /// 引用完整性问题
  referenceIntegrity,

  /// 约束违反
  constraintViolation,

  /// 格式错误
  formatError,
}

/// 完整性修复结果
class IntegrityRepairResult {
  /// 修复是否成功
  final bool success;

  /// 修复的问题数量
  final int repairedIssuesCount;

  /// 修复失败的问题数量
  final int failedRepairsCount;

  /// 修复耗时
  final Duration repairDuration;

  /// 修复结果详情
  final List<IssueRepairResult> repairResults;

  const IntegrityRepairResult({
    required this.success,
    required this.repairedIssuesCount,
    required this.failedRepairsCount,
    required this.repairDuration,
    required this.repairResults,
  });
}

/// 问题修复结果
class IssueRepairResult {
  /// 问题ID
  final String issueId;

  /// 修复是否成功
  final bool success;

  /// 修复方法
  final RepairMethod repairMethod;

  /// 修复时间
  final DateTime repairTime;

  /// 错误信息
  final String? error;

  const IssueRepairResult({
    required this.issueId,
    required this.success,
    required this.repairMethod,
    required this.repairTime,
    this.error,
  });
}

/// 修复方法
enum RepairMethod {
  /// 数据恢复
  dataRecovery,

  /// 重新同步
  resynchronization,

  /// 数据重建
  dataReconstruction,

  /// 引用修复
  referenceRepair,
}

/// 完整性报告
class IntegrityReport {
  /// 报告ID
  final String reportId;

  /// 报告范围
  final ReportScope scope;

  /// 报告生成时间
  final DateTime generatedAt;

  /// 整体完整性评分
  final double overallIntegrityScore;

  /// 按数据源分组的完整性统计
  final Map<String, SourceIntegrityStats> sourceStats;

  /// 完整性问题趋势
  final List<IntegrityTrendPoint> trendPoints;

  /// 建议的改进措施
  final List<ImprovementRecommendation> recommendations;

  const IntegrityReport({
    required this.reportId,
    required this.scope,
    required this.generatedAt,
    required this.overallIntegrityScore,
    required this.sourceStats,
    required this.trendPoints,
    required this.recommendations,
  });
}

/// 报告范围
enum ReportScope {
  /// 完整报告
  full,

  /// 摘要报告
  summary,

  /// 按数据源
  byDataSource,

  /// 按数据类型
  byDataType,
}

/// 数据源完整性统计
class SourceIntegrityStats {
  /// 数据源ID
  final String dataSourceId;

  /// 检查的数据项总数
  final int totalItems;

  /// 完整的数据项数量
  final int intactItems;

  /// 损坏的数据项数量
  final int corruptedItems;

  /// 完整性率
  final double integrityRate;

  const SourceIntegrityStats({
    required this.dataSourceId,
    required this.totalItems,
    required this.intactItems,
    required this.corruptedItems,
    required this.integrityRate,
  });
}

/// 完整性趋势点
class IntegrityTrendPoint {
  /// 时间戳
  final DateTime timestamp;

  /// 完整性率
  final double integrityRate;

  /// 问题数量
  final int issueCount;

  const IntegrityTrendPoint({
    required this.timestamp,
    required this.integrityRate,
    required this.issueCount,
  });
}

/// 改进建议
class ImprovementRecommendation {
  /// 建议类型
  final RecommendationType type;

  /// 建议标题
  final String title;

  /// 建议描述
  final String description;

  /// 优先级
  final Priority priority;

  /// 预期效果
  final ExpectedEffect expectedEffect;

  const ImprovementRecommendation({
    required this.type,
    required this.title,
    required this.description,
    required this.priority,
    required this.expectedEffect,
  });
}

/// 预期效果
class ExpectedEffect {
  /// 完整性提升
  final double integrityImprovement;

  /// 性能影响
  final double performanceImpact;

  /// 实施复杂度
  final ImplementationComplexity complexity;

  const ExpectedEffect({
    required this.integrityImprovement,
    required this.performanceImpact,
    required this.complexity,
  });
}

/// 实施复杂度
enum ImplementationComplexity {
  /// 简单
  simple,

  /// 中等
  medium,

  /// 复杂
  complex,
}

/// 优先级
enum Priority {
  /// 低优先级
  low,

  /// 中优先级
  medium,

  /// 高优先级
  high,

  /// 紧急
  urgent,
}

/// 一致性指标
class ConsistencyMetrics {
  /// 指标周期
  final MetricsPeriod period;

  /// 整体一致性率
  final double overallConsistencyRate;

  /// 按数据源的一致性率
  final Map<String, double> sourceConsistencyRates;

  /// 按数据类型的一致性率
  final Map<String, double> typeConsistencyRates;

  /// 冲突检测数量
  final int conflictDetectionCount;

  /// 冲突解决数量
  final int conflictResolutionCount;

  /// 平均解决时间
  final Duration averageResolutionTime;

  const ConsistencyMetrics({
    required this.period,
    required this.overallConsistencyRate,
    required this.sourceConsistencyRates,
    required this.typeConsistencyRates,
    required this.conflictDetectionCount,
    required this.conflictResolutionCount,
    required this.averageResolutionTime,
  });
}

/// 指标周期
enum MetricsPeriod {
  /// 最后一小时
  lastHour,

  /// 过去24小时
  last24Hours,

  /// 过去7天
  last7Days,

  /// 过去30天
  last30Days,
}

/// 一致性报告
class ConsistencyReport {
  /// 报告ID
  final String reportId;

  /// 报告类型
  final ReportType reportType;

  /// 报告时间范围
  final TimeRange timeRange;

  /// 生成时间
  final DateTime generatedAt;

  /// 一致性摘要
  final ConsistencySummary summary;

  /// 详细指标
  final ConsistencyMetrics metrics;

  /// 冲突分析
  final ConflictAnalysis conflictAnalysis;

  /// 趋势分析
  final TrendAnalysis trendAnalysis;

  const ConsistencyReport({
    required this.reportId,
    required this.reportType,
    required this.timeRange,
    required this.generatedAt,
    required this.summary,
    required this.metrics,
    required this.conflictAnalysis,
    required this.trendAnalysis,
  });
}

/// 报告类型
enum ReportType {
  /// 摘要报告
  summary,

  /// 详细报告
  detailed,

  /// 趋势报告
  trend,

  /// 对比报告
  comparison,
}

/// 一致性摘要
class ConsistencySummary {
  /// 整体状态
  final OverallStatus overallStatus;

  /// 一致性率
  final double consistencyRate;

  /// 活跃冲突数量
  final int activeConflictsCount;

  /// 今日解决的冲突数量
  final int resolvedConflictsToday;

  /// 数据同步状态
  final SyncStatus syncStatus;

  const ConsistencySummary({
    required this.overallStatus,
    required this.consistencyRate,
    required this.activeConflictsCount,
    required this.resolvedConflictsToday,
    required this.syncStatus,
  });
}

/// 整体状态
enum OverallStatus {
  /// 优秀
  excellent,

  /// 良好
  good,

  /// 一般
  fair,

  /// 差
  poor,
}

/// 冲突分析
class ConflictAnalysis {
  /// 冲突类型分布
  final Map<ConflictType, int> conflictTypeDistribution;

  /// 冲突严重程度分布
  final Map<Severity, int> conflictSeverityDistribution;

  /// 高频冲突数据项
  final List<ItemReference> frequentConflictItems;

  /// 冲突解决时间分析
  final ResolutionTimeAnalysis resolutionTimeAnalysis;

  const ConflictAnalysis({
    required this.conflictTypeDistribution,
    required this.conflictSeverityDistribution,
    required this.frequentConflictItems,
    required this.resolutionTimeAnalysis,
  });
}

/// 解决时间分析
class ResolutionTimeAnalysis {
  /// 平均解决时间
  final Duration averageResolutionTime;

  /// 中位数解决时间
  final Duration medianResolutionTime;

  /// 最长解决时间
  final Duration longestResolutionTime;

  /// 最短解决时间
  final Duration shortestResolutionTime;

  const ResolutionTimeAnalysis({
    required this.averageResolutionTime,
    required this.medianResolutionTime,
    required this.longestResolutionTime,
    required this.shortestResolutionTime,
  });
}

/// 趋势分析
class TrendAnalysis {
  /// 一致性率趋势
  final List<TrendPoint> consistencyRateTrend;

  /// 冲突数量趋势
  final List<TrendPoint> conflictCountTrend;

  /// 同步性能趋势
  final List<TrendPoint> syncPerformanceTrend;

  const TrendAnalysis({
    required this.consistencyRateTrend,
    required this.conflictCountTrend,
    required this.syncPerformanceTrend,
  });
}

/// 趋势点
class TrendPoint {
  /// 时间戳
  final DateTime timestamp;

  /// 数值
  final double value;

  /// 标签
  final String? label;

  const TrendPoint({
    required this.timestamp,
    required this.value,
    this.label,
  });
}

/// 趋势周期
enum TrendPeriod {
  /// 过去7天
  last7Days,

  /// 过去30天
  last30Days,

  /// 过去90天
  last90Days,
}

/// 趋势指标
enum TrendMetric {
  /// 一致性率
  consistencyRate,

  /// 冲突数量
  conflictCount,

  /// 解决时间
  resolutionTime,

  /// 同步性能
  syncPerformance,
}

/// 一致性规则
class ConsistencyRule {
  /// 规则ID
  final String ruleId;

  /// 规则名称
  final String name;

  /// 规则描述
  final String description;

  /// 规则类型
  final RuleType type;

  /// 规则条件
  final RuleCondition condition;

  /// 规则动作
  final RuleAction action;

  /// 规则优先级
  final int priority;

  /// 是否启用
  final bool isEnabled;

  const ConsistencyRule({
    required this.ruleId,
    required this.name,
    required this.description,
    required this.type,
    required this.condition,
    required this.action,
    required this.priority,
    required this.isEnabled,
  });
}

/// 规则类型
enum RuleType {
  /// 验证规则
  validation,

  /// 冲突解决规则
  conflictResolution,

  /// 同步规则
  synchronization,

  /// 告警规则
  alerting,
}

/// 规则条件
class RuleCondition {
  /// 条件表达式
  final String expression;

  /// 条件参数
  final Map<String, dynamic> parameters;

  const RuleCondition({
    required this.expression,
    required this.parameters,
  });
}

/// 规则动作
class RuleAction {
  /// 动作类型
  final ActionType type;

  /// 动作参数
  final Map<String, dynamic> parameters;

  const RuleAction({
    required this.type,
    required this.parameters,
  });
}

/// 一致性趋势点
class ConsistencyTrendPoint {
  /// 时间戳
  final DateTime timestamp;

  /// 一致性率
  final double consistencyRate;

  /// 冲突数量
  final int conflictCount;

  /// 活跃数据源数量
  final int activeDataSources;

  const ConsistencyTrendPoint({
    required this.timestamp,
    required this.consistencyRate,
    required this.conflictCount,
    required this.activeDataSources,
  });
}

/// 改进建议类型
enum RecommendationType {
  /// 性能优化
  performance,

  /// 可靠性提升
  reliability,

  /// 成本降低
  cost,

  /// 功能增强
  feature,

  /// 数据质量
  dataQuality,

  /// 同步优化
  synchronization,
}

// ===== 离线缓存相关数据类 =====

/// 离线数据变更记录
class OfflineDataChange {
  /// 变更ID
  final String changeId;

  /// 数据类型
  final String dataType;

  /// 数据键
  final String dataKey;

  /// 变更类型
  final String changeType;

  /// 变更前的数据
  final Map<String, dynamic>? previousData;

  /// 变更后的数据
  Map<String, dynamic>? newData;

  /// 变更时间戳
  final DateTime timestamp;

  /// 数据源ID
  final String sourceId;

  /// 数据版本
  final int version;

  /// 数据校验和
  String? checksum;

  /// 变更元数据
  final Map<String, dynamic> metadata;

  /// 是否已同步
  bool isSynced;

  /// 同步失败次数
  int syncFailureCount;

  /// 最后同步时间
  DateTime? lastSyncTime;

  /// 同步错误信息
  String? syncError;

  OfflineDataChange({
    required this.changeId,
    required this.dataType,
    required this.dataKey,
    required this.changeType,
    this.previousData,
    this.newData,
    required this.timestamp,
    required this.sourceId,
    required this.version,
    this.checksum,
    this.metadata = const {},
    this.isSynced = false,
    this.syncFailureCount = 0,
    this.lastSyncTime,
    this.syncError,
  });

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'changeId': changeId,
      'dataType': dataType,
      'dataKey': dataKey,
      'changeType': changeType,
      'previousData': previousData,
      'newData': newData,
      'timestamp': timestamp.toIso8601String(),
      'sourceId': sourceId,
      'version': version,
      'checksum': checksum,
      'metadata': metadata,
      'isSynced': isSynced,
      'syncFailureCount': syncFailureCount,
      'lastSyncTime': lastSyncTime?.toIso8601String(),
      'syncError': syncError,
    };
  }

  /// 从JSON创建
  factory OfflineDataChange.fromJson(Map<String, dynamic> json) {
    return OfflineDataChange(
      changeId: json['changeId'] as String,
      dataType: json['dataType'] as String,
      dataKey: json['dataKey'] as String,
      changeType: json['changeType'] as String,
      previousData: json['previousData'] as Map<String, dynamic>?,
      newData: json['newData'] as Map<String, dynamic>?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      sourceId: json['sourceId'] as String,
      version: json['version'] as int,
      checksum: json['checksum'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      isSynced: json['isSynced'] as bool? ?? false,
      syncFailureCount: json['syncFailureCount'] as int? ?? 0,
      lastSyncTime: json['lastSyncTime'] != null
          ? DateTime.parse(json['lastSyncTime'] as String)
          : null,
      syncError: json['syncError'] as String?,
    );
  }

  /// 标记为已同步
  void markAsSynced() {
    isSynced = true;
    syncFailureCount = 0;
    syncError = null;
    lastSyncTime = DateTime.now();
  }

  /// 标记同步失败
  void markSyncFailed(String error) {
    syncFailureCount++;
    syncError = error;
  }

  /// 是否可以重试同步
  bool get canRetrySync => syncFailureCount < 3;
}

/// 离线同步结果
class OfflineSyncResult {
  /// 同步是否成功
  final bool success;

  /// 同步的变更数量
  final int syncedChangesCount;

  /// 失败的变更数量
  final int failedChangesCount;

  /// 跳过的变更数量
  final int skippedChangesCount;

  /// 同步耗时
  final Duration syncDuration;

  /// 同步时间
  final DateTime syncTime;

  /// 冲突数量
  final int conflictCount;

  /// 解决的冲突数量
  final int resolvedConflictsCount;

  /// 详细结果
  final List<OfflineSyncItemResult> itemResults;

  /// 错误信息
  final String? error;

  const OfflineSyncResult({
    required this.success,
    required this.syncedChangesCount,
    required this.failedChangesCount,
    required this.skippedChangesCount,
    required this.syncDuration,
    required this.syncTime,
    required this.conflictCount,
    required this.resolvedConflictsCount,
    required this.itemResults,
    this.error,
  });

  /// 总变更数量
  int get totalChangesCount =>
      syncedChangesCount + failedChangesCount + skippedChangesCount;

  /// 同步成功率
  double get syncSuccessRate =>
      totalChangesCount > 0 ? syncedChangesCount / totalChangesCount : 0.0;

  /// 冲突解决率
  double get conflictResolutionRate =>
      conflictCount > 0 ? resolvedConflictsCount / conflictCount : 1.0;
}

/// 离线同步单项结果
class OfflineSyncItemResult {
  /// 变更ID
  final String changeId;

  /// 数据键
  final String dataKey;

  /// 同步是否成功
  final bool success;

  /// 同步耗时
  final Duration syncDuration;

  /// 错误信息
  final String? error;

  /// 是否检测到冲突
  final bool hasConflict;

  /// 冲突解决策略
  final ConflictResolutionStrategy? conflictResolutionStrategy;

  /// 冲突是否已解决
  final bool conflictResolved;

  const OfflineSyncItemResult({
    required this.changeId,
    required this.dataKey,
    required this.success,
    required this.syncDuration,
    this.error,
    this.hasConflict = false,
    this.conflictResolutionStrategy,
    this.conflictResolved = false,
  });
}

/// 离线缓存统计信息
class OfflineCacheStats {
  /// 缓存的变更总数
  final int totalChangesCount;

  /// 已同步的变更数量
  final int syncedChangesCount;

  /// 待同步的变更数量
  final int pendingChangesCount;

  /// 失败的变更数量
  final int failedChangesCount;

  /// 缓存大小（字节）
  final int cacheSizeBytes;

  /// 最早变更时间
  final DateTime? earliestChangeTime;

  /// 最晚变更时间
  final DateTime? latestChangeTime;

  /// 按数据类型分组的统计
  final Map<String, int> changesByDataType;

  /// 按数据源分组的统计
  final Map<String, int> changesByDataSource;

  /// 冲突数量
  final int conflictCount;

  /// 过期变更数量
  final int expiredChangesCount;

  const OfflineCacheStats({
    required this.totalChangesCount,
    required this.syncedChangesCount,
    required this.pendingChangesCount,
    required this.failedChangesCount,
    required this.cacheSizeBytes,
    this.earliestChangeTime,
    this.latestChangeTime,
    required this.changesByDataType,
    required this.changesByDataSource,
    required this.conflictCount,
    required this.expiredChangesCount,
  });

  /// 缓存使用率
  double get cacheUtilizationRate => totalChangesCount > 0
      ? (syncedChangesCount + pendingChangesCount) / totalChangesCount
      : 0.0;

  /// 同步成功率
  double get syncSuccessRate =>
      totalChangesCount > 0 ? syncedChangesCount / totalChangesCount : 0.0;
}

/// 离线同步状态
class OfflineSyncStatus {
  /// 是否正在同步
  final bool isSyncing;

  /// 同步进度 (0.0 - 1.0)
  final double progress;

  /// 当前同步的变更ID
  final String? currentChangeId;

  /// 预计剩余时间
  final Duration? estimatedRemainingTime;

  /// 同步开始时间
  final DateTime? syncStartTime;

  /// 最后同步时间
  final DateTime? lastSyncTime;

  /// 同步错误
  final String? syncError;

  /// 自动同步是否启用
  final bool autoSyncEnabled;

  /// 下次自动同步时间
  final DateTime? nextAutoSyncTime;

  const OfflineSyncStatus({
    required this.isSyncing,
    required this.progress,
    this.currentChangeId,
    this.estimatedRemainingTime,
    this.syncStartTime,
    this.lastSyncTime,
    this.syncError,
    required this.autoSyncEnabled,
    this.nextAutoSyncTime,
  });
}

// ===== 基础数据类型定义 =====

/// 数据源
class DataSource {
  /// 数据源ID
  final String id;

  /// 数据源名称
  final String name;

  /// 数据源类型
  final DataSourceType type;

  /// 健康状态
  final HealthStatus healthStatus;

  /// 连接配置
  final Map<String, dynamic> connectionConfig;

  /// 创建时间
  final DateTime createdAt;

  /// 最后更新时间
  final DateTime lastUpdated;

  const DataSource({
    required this.id,
    required this.name,
    required this.type,
    this.healthStatus = HealthStatus.healthy,
    required this.connectionConfig,
    required this.createdAt,
    required this.lastUpdated,
  });
}

/// 数据源类型
enum DataSourceType {
  /// 本地缓存
  localCache,

  /// 远程API
  remoteAPI,

  /// 数据库
  database,

  /// 文件系统
  fileSystem,

  /// 实时流
  realtime,
}

/// 健康状态
enum HealthStatus {
  /// 健康
  healthy,

  /// 警告
  warning,

  /// 错误
  error,

  /// 离线
  offline,
}

/// 增量同步结果
class IncrementalSyncResult {
  /// 同步是否成功
  final bool success;

  /// 变更列表
  final List<DataChange> changes;

  /// 同步耗时
  final Duration duration;

  /// 错误信息
  final String? error;

  const IncrementalSyncResult({
    required this.success,
    required this.changes,
    required this.duration,
    this.error,
  });
}

/// 数据变更
class DataChange {
  /// 变更ID
  final String id;

  /// 变更类型
  final ChangeType changeType;

  /// 数据项类型
  final String itemType;

  /// 数据项ID
  final String itemId;

  /// 变更时间
  final DateTime timestamp;

  /// 变更内容
  final Map<String, dynamic>? changeData;

  const DataChange({
    required this.id,
    required this.changeType,
    required this.itemType,
    required this.itemId,
    required this.timestamp,
    this.changeData,
  });
}

/// 变更类型
enum ChangeType {
  /// 创建
  create,

  /// 更新
  update,

  /// 删除
  delete,
}

/// 动作类型
enum ActionType {
  /// 刷新缓存
  refreshCache,

  /// 重新同步
  resync,

  /// 数据回滚
  rollback,

  /// 数据合并
  merge,

  /// 告警通知
  alert,

  /// 日志记录
  log,

  /// 数据验证
  validate,

  /// 自动修复
  autoRepair,
}
