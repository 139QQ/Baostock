import 'dart:async';
import '../interfaces/i_unified_data_source.dart';

/// 数据路由器接口
///
/// 负责智能选择最佳数据源，处理故障转移，优化数据访问性能
/// 支持基于质量、性能、可用性的多维度路由决策
abstract class IDataRouter {
  // ===== 生命周期管理接口 =====

  /// 初始化数据路由器
  Future<void> initialize();

  /// 释放资源
  Future<void> dispose();

  // ===== 数据源选择接口 =====

  /// 选择最佳数据源
  ///
  /// [operation] 操作类型
  /// [criteria] 选择条件
  /// [context] 请求上下文
  ///
  /// 返回最适合的数据源
  Future<SelectedDataSource> selectBestDataSource(
    DataOperation operation, {
    SelectionCriteria? criteria,
    RequestContext? context,
  });

  /// 批量选择数据源
  ///
  /// [operations] 操作列表
  ///
  /// 返回操作到数据源的映射关系
  Future<Map<DataOperation, SelectedDataSource>> selectDataSourcesBatch(
    List<DataOperation> operations,
  );

  /// 预选择数据源
  ///
  /// 为即将到来的操作预先选择和准备数据源
  Future<List<PreselectedSource>> preselectDataSources(
    List<DataOperation> upcomingOperations,
  );

  // ===== 数据质量评估接口 =====

  /// 评估数据源质量
  ///
  /// [dataSource] 要评估的数据源
  /// [evaluationType] 评估类型
  ///
  /// 返回质量评估结果
  Future<DataSourceQuality> evaluateDataSourceQuality(
    DataSource dataSource, {
    QualityEvaluationType evaluationType = QualityEvaluationType.comprehensive,
  });

  /// 批量评估数据源质量
  Future<List<DataSourceQuality>> evaluateDataSourcesBatch(
    List<DataSource> dataSources,
  );

  /// 获取数据源质量历史
  Future<List<QualityHistoryPoint>> getQualityHistory(
    DataSource dataSource, {
    DateTime? startTime,
    DateTime? endTime,
  });

  // ===== 故障转移接口 =====

  /// 处理数据源故障
  ///
  /// [failedDataSource] 失败的数据源
  /// [error] 错误信息
  /// [context] 请求上下文
  ///
  /// 返回故障转移结果
  Future<FailoverResult> handleDataSourceFailure(
    DataSource failedDataSource, {
    required Object error,
    RequestContext? context,
  });

  /// 执行故障转移
  ///
  /// [request] 原始请求
  /// [alternativeSources] 备选数据源列表
  ///
  /// 返回转移后的响应结果
  Future<FailoverResponse> performFailover(
    DataRequest request,
    List<DataSource> alternativeSources,
  );

  /// 验证故障转移策略
  Future<FailoverValidationResult> validateFailoverStrategy(
    FailoverStrategy strategy,
  );

  // ===== 路由优化接口 =====

  /// 优化路由策略
  ///
  /// 基于历史数据和性能指标优化路由决策
  Future<RouteOptimizationResult> optimizeRoutingStrategy({
    OptimizationScope scope = OptimizationScope.global,
  });

  /// 获取路由统计信息
  Future<RouteStatistics> getRouteStatistics({
    StatisticsPeriod period = StatisticsPeriod.last24Hours,
  });

  /// 重置路由学习数据
  Future<void> resetRouteLearning();

  // ===== 监控和诊断接口 =====

  /// 获取路由健康状态
  Future<RouteHealthReport> getRouteHealthReport();

  /// 执行路由诊断
  Future<RouteDiagnosticResult> performRouteDiagnostics(
    DataOperation operation,
  );

  /// 获取路由建议
  Future<List<RouteRecommendation>> getRouteRecommendations({
    RecommendationType type = RecommendationType.performance,
  });
}

/// 数据源选择结果
class SelectedDataSource {
  /// 选中的数据源
  final DataSource dataSource;

  /// 选择原因
  final SelectionReason reason;

  /// 预期性能指标
  final ExpectedPerformance expectedPerformance;

  /// 置信度
  final double confidence;

  /// 选择时间戳
  final DateTime selectionTime;

  const SelectedDataSource({
    required this.dataSource,
    required this.reason,
    required this.expectedPerformance,
    required this.confidence,
    required this.selectionTime,
  });
}

/// 选择条件
class SelectionCriteria {
  /// 性能要求
  final PerformanceRequirements? performance;

  /// 可靠性要求
  final ReliabilityRequirements? reliability;

  /// 成本限制
  final CostConstraints? cost;

  /// 地理位置
  final GeographicConstraints? geography;

  /// 数据新鲜度要求
  final FreshnessRequirements? freshness;

  const SelectionCriteria({
    this.performance,
    this.reliability,
    this.cost,
    this.geography,
    this.freshness,
  });
}

/// 性能要求
class PerformanceRequirements {
  /// 最大响应时间（毫秒）
  final double maxResponseTime;

  /// 最小吞吐量（请求/秒）
  final double minThroughput;

  /// 期望并发连接数
  final int expectedConcurrency;

  const PerformanceRequirements({
    required this.maxResponseTime,
    required this.minThroughput,
    required this.expectedConcurrency,
  });
}

/// 可靠性要求
class ReliabilityRequirements {
  /// 最小可用性（百分比）
  final double minAvailability;

  /// 最大错误率（百分比）
  final double maxErrorRate;

  /// 是否需要数据一致性保证
  final bool requiresConsistency;

  const ReliabilityRequirements({
    required this.minAvailability,
    required this.maxErrorRate,
    required this.requiresConsistency,
  });
}

/// 成本限制
class CostConstraints {
  /// 最大请求成本
  final double maxCostPerRequest;

  /// 每日成本限制
  final double maxDailyCost;

  /// 成本优先级
  final CostPriority costPriority;

  const CostConstraints({
    required this.maxCostPerRequest,
    required this.maxDailyCost,
    required this.costPriority,
  });
}

/// 成本优先级
enum CostPriority {
  /// 低优先级
  low,

  /// 中等优先级
  medium,

  /// 高优先级
  high,
}

/// 地理位置限制
class GeographicConstraints {
  /// 优选区域
  final List<String> preferredRegions;

  /// 禁止区域
  final List<String> forbiddenRegions;

  /// 延迟要求
  final LatencyRequirements latency;

  const GeographicConstraints({
    required this.preferredRegions,
    required this.forbiddenRegions,
    required this.latency,
  });
}

/// 延迟要求
class LatencyRequirements {
  /// 最大延迟（毫秒）
  final double maxLatency;

  /// 延迟类型
  final LatencyType latencyType;

  const LatencyRequirements({
    required this.maxLatency,
    required this.latencyType,
  });
}

/// 延迟类型
enum LatencyType {
  /// 单向延迟
  oneWay,

  /// 往返延迟
  roundTrip,
}

/// 数据新鲜度要求
class FreshnessRequirements {
  /// 最大数据年龄
  final Duration maxDataAge;

  /// 是否需要实时数据
  final bool requiresRealTime;

  /// 更新频率要求
  final UpdateFrequency updateFrequency;

  const FreshnessRequirements({
    required this.maxDataAge,
    required this.requiresRealTime,
    required this.updateFrequency,
  });
}

/// 更新频率
enum UpdateFrequency {
  /// 实时
  realTime,

  /// 每分钟
  perMinute,

  /// 每小时
  perHour,

  /// 每天
  daily,
}

/// 请求上下文
class RequestContext {
  /// 请求ID
  final String requestId;

  /// 用户ID
  final String? userId;

  /// 会话ID
  final String? sessionId;

  /// 请求来源
  final RequestSource source;

  /// 优先级
  final RequestPriority priority;

  /// 超时时间
  final Duration timeout;

  /// 重试次数
  final int retryCount;

  const RequestContext({
    required this.requestId,
    this.userId,
    this.sessionId,
    required this.source,
    required this.priority,
    required this.timeout,
    this.retryCount = 0,
  });
}

/// 请求来源
enum RequestSource {
  /// 移动应用
  mobile,

  /// Web应用
  web,

  /// 桌面应用
  desktop,

  /// API调用
  api,

  /// 后台任务
  background,
}

/// 请求优先级
enum RequestPriority {
  /// 低优先级
  low,

  /// 普通优先级
  normal,

  /// 高优先级
  high,

  /// 紧急优先级
  urgent,
}

/// 选择原因
enum SelectionReason {
  /// 最佳性能
  bestPerformance,

  /// 最高可靠性
  highestReliability,

  /// 最低成本
  lowestCost,

  /// 最近地理位置
  closestGeography,

  /// 最新数据
  freshestData,

  /// 负载均衡
  loadBalancing,

  /// 故障转移
  failover,
}

/// 预期性能
class ExpectedPerformance {
  /// 响应时间（毫秒）
  final double responseTime;

  /// 成功率
  final double successRate;

  /// 数据质量评分
  final double dataQualityScore;

  /// 成本预估
  final double estimatedCost;

  const ExpectedPerformance({
    required this.responseTime,
    required this.successRate,
    required this.dataQualityScore,
    required this.estimatedCost,
  });
}

/// 预选择数据源
class PreselectedSource {
  /// 数据源
  final DataSource dataSource;

  /// 预期使用的操作
  final List<DataOperation> operations;

  /// 预热状态
  final WarmupStatus warmupStatus;

  const PreselectedSource({
    required this.dataSource,
    required this.operations,
    required this.warmupStatus,
  });
}

/// 预热状态
enum WarmupStatus {
  /// 未预热
  notWarmed,

  /// 预热中
  warming,

  /// 已预热
  warmed,

  /// 预热失败
  warmupFailed,
}

/// 数据源
class DataSource {
  /// 数据源ID
  final String id;

  /// 数据源名称
  final String name;

  /// 数据源类型
  final DataSourceType type;

  /// 数据源URL
  final String url;

  /// 数据源配置
  final Map<String, dynamic> configuration;

  /// 健康状态
  final HealthStatus healthStatus;

  /// 当前负载
  final double currentLoad;

  /// 最大容量
  final double maxCapacity;

  const DataSource({
    required this.id,
    required this.name,
    required this.type,
    required this.url,
    required this.configuration,
    required this.healthStatus,
    required this.currentLoad,
    required this.maxCapacity,
  });
}

/// 数据源类型
enum DataSourceType {
  /// 本地缓存
  localCache,

  /// 远程API
  remoteApi,

  /// 数据库
  database,

  /// 消息队列
  messageQueue,

  /// 文件系统
  fileSystem,
}

/// 健康状态
enum HealthStatus {
  /// 健康
  healthy,

  /// 警告
  warning,

  /// 不健康
  unhealthy,

  /// 未知
  unknown,
}

/// 数据操作
class DataOperation {
  /// 操作类型
  final OperationType type;

  /// 操作参数
  final Map<String, dynamic> parameters;

  /// 优先级
  final RequestPriority priority;

  /// 预期数据大小
  final int expectedDataSize;

  const DataOperation({
    required this.type,
    required this.parameters,
    required this.priority,
    required this.expectedDataSize,
  });
}

/// 操作类型
enum OperationType {
  /// 读取操作
  read,

  /// 写入操作
  write,

  /// 搜索操作
  search,

  /// 流式操作
  stream,

  /// 批量操作
  batch,
}

/// 数据源质量评估结果
class DataSourceQuality {
  /// 数据源
  final DataSource dataSource;

  /// 总体质量评分
  final double overallScore;

  /// 性能评分
  final double performanceScore;

  /// 可靠性评分
  final double reliabilityScore;

  /// 数据质量评分
  final double dataQualityScore;

  /// 成本评分
  final double costScore;

  /// 评估时间
  final DateTime evaluationTime;

  /// 详细指标
  final Map<String, dynamic> detailedMetrics;

  const DataSourceQuality({
    required this.dataSource,
    required this.overallScore,
    required this.performanceScore,
    required this.reliabilityScore,
    required this.dataQualityScore,
    required this.costScore,
    required this.evaluationTime,
    required this.detailedMetrics,
  });
}

/// 质量评估类型
enum QualityEvaluationType {
  /// 快速评估
  quick,

  /// 全面评估
  comprehensive,

  /// 性能专项评估
  performance,

  /// 可靠性专项评估
  reliability,
}

/// 质量历史点
class QualityHistoryPoint {
  /// 时间戳
  final DateTime timestamp;

  /// 质量评分
  final double qualityScore;

  /// 响应时间
  final double responseTime;

  /// 成功率
  final double successRate;

  const QualityHistoryPoint({
    required this.timestamp,
    required this.qualityScore,
    required this.responseTime,
    required this.successRate,
  });
}

/// 故障转移结果
class FailoverResult {
  /// 转移是否成功
  final bool success;

  /// 原始数据源
  final DataSource originalSource;

  /// 目标数据源
  final DataSource? targetSource;

  /// 转移耗时
  final Duration failoverDuration;

  /// 转移原因
  final String reason;

  /// 错误信息
  final String? error;

  const FailoverResult({
    required this.success,
    required this.originalSource,
    this.targetSource,
    required this.failoverDuration,
    required this.reason,
    this.error,
  });
}

/// 数据请求
class DataRequest {
  /// 请求ID
  final String requestId;

  /// 操作类型
  final DataOperation operation;

  /// 请求参数
  final Map<String, dynamic> parameters;

  /// 上下文
  final RequestContext? context;

  const DataRequest({
    required this.requestId,
    required this.operation,
    required this.parameters,
    this.context,
  });
}

/// 故障转移响应
class FailoverResponse {
  /// 响应是否成功
  final bool success;

  /// 响应数据
  final dynamic data;

  /// 使用的数据源
  final DataSource usedSource;

  /// 转移次数
  final int failoverCount;

  /// 总耗时
  final Duration totalDuration;

  /// 响应元数据
  final Map<String, dynamic> metadata;

  const FailoverResponse({
    required this.success,
    this.data,
    required this.usedSource,
    required this.failoverCount,
    required this.totalDuration,
    required this.metadata,
  });
}

/// 故障转移策略
class FailoverStrategy {
  /// 策略名称
  final String name;

  /// 最大重试次数
  final int maxRetries;

  /// 重试间隔
  final Duration retryInterval;

  /// 超时时间
  final Duration timeout;

  /// 备选数据源列表
  final List<DataSource> alternativeSources;

  const FailoverStrategy({
    required this.name,
    required this.maxRetries,
    required this.retryInterval,
    required this.timeout,
    required this.alternativeSources,
  });
}

/// 故障转移验证结果
class FailoverValidationResult {
  /// 验证是否通过
  final bool isValid;

  /// 验证结果
  final List<ValidationIssue> issues;

  /// 建议改进
  final List<String> recommendations;

  const FailoverValidationResult({
    required this.isValid,
    required this.issues,
    required this.recommendations,
  });
}

/// 验证问题
class ValidationIssue {
  /// 问题类型
  final IssueType type;

  /// 问题描述
  final String description;

  /// 严重程度
  final IssueSeverity severity;

  const ValidationIssue({
    required this.type,
    required this.description,
    required this.severity,
  });
}

/// 问题类型
enum IssueType {
  /// 配置问题
  configuration,

  /// 性能问题
  performance,

  /// 可用性问题
  availability,

  /// 成本问题
  cost,
}

/// 路由优化结果
class RouteOptimizationResult {
  /// 优化是否成功
  final bool success;

  /// 优化前性能
  final PerformanceMetrics before;

  /// 优化后性能
  final PerformanceMetrics after;

  /// 应用的优化策略
  final List<OptimizationStrategy> appliedStrategies;

  const RouteOptimizationResult({
    required this.success,
    required this.before,
    required this.after,
    required this.appliedStrategies,
  });
}

/// 性能指标
class PerformanceMetrics {
  /// 平均响应时间
  final double averageResponseTime;

  /// 吞吐量
  final double throughput;

  /// 错误率
  final double errorRate;

  /// 资源利用率
  final double resourceUtilization;

  const PerformanceMetrics({
    required this.averageResponseTime,
    required this.throughput,
    required this.errorRate,
    required this.resourceUtilization,
  });
}

/// 优化策略
class OptimizationStrategy {
  /// 策略名称
  final String name;

  /// 策略类型
  final OptimizationType type;

  /// 应用效果
  final double impact;

  const OptimizationStrategy({
    required this.name,
    required this.type,
    required this.impact,
  });
}

/// 优化类型
enum OptimizationType {
  /// 缓存优化
  cache,

  /// 负载均衡
  loadBalancing,

  /// 数据源选择
  sourceSelection,

  /// 请求合并
  requestBatching,
}

/// 优化范围
enum OptimizationScope {
  /// 全局优化
  global,

  /// 区域优化
  regional,

  /// 数据源优化
  dataSource,

  /// 操作优化
  operation,
}

/// 路由统计信息
class RouteStatistics {
  /// 统计周期
  final StatisticsPeriod period;

  /// 总请求数
  final int totalRequests;

  /// 成功请求数
  final int successfulRequests;

  /// 故障转移次数
  final int failoverCount;

  /// 平均响应时间
  final double averageResponseTime;

  /// 数据源使用分布
  final Map<String, int> sourceUsageDistribution;

  const RouteStatistics({
    required this.period,
    required this.totalRequests,
    required this.successfulRequests,
    required this.failoverCount,
    required this.averageResponseTime,
    required this.sourceUsageDistribution,
  });
}

/// 统计周期
enum StatisticsPeriod {
  /// 最后一小时
  lastHour,

  /// 过去24小时
  last24Hours,

  /// 过去7天
  last7Days,

  /// 过去30天
  last30Days,
}

/// 路由健康报告
class RouteHealthReport {
  /// 整体健康状态
  final bool isHealthy;

  /// 数据源健康状态
  final Map<String, DataSourceHealth> sourceHealth;

  /// 路由性能指标
  final RoutePerformanceMetrics performance;

  /// 发现的问题
  final List<RouteHealthIssue> issues;

  const RouteHealthReport({
    required this.isHealthy,
    required this.sourceHealth,
    required this.performance,
    required this.issues,
  });
}

/// 数据源健康状态
class DataSourceHealth {
  /// 数据源ID
  final String dataSourceId;

  /// 健康状态
  final HealthStatus status;

  /// 响应时间
  final double responseTime;

  /// 成功率
  final double successRate;

  /// 最后检查时间
  final DateTime lastCheckTime;

  const DataSourceHealth({
    required this.dataSourceId,
    required this.status,
    required this.responseTime,
    required this.successRate,
    required this.lastCheckTime,
  });
}

/// 路由性能指标
class RoutePerformanceMetrics {
  /// 平均路由时间
  final double averageRoutingTime;

  /// 路由成功率
  final double routingSuccessRate;

  /// 故障转移成功率
  final double failoverSuccessRate;

  const RoutePerformanceMetrics({
    required this.averageRoutingTime,
    required this.routingSuccessRate,
    required this.failoverSuccessRate,
  });
}

/// 路由健康问题
class RouteHealthIssue {
  /// 问题类型
  final RouteIssueType type;

  /// 问题描述
  final String description;

  /// 影响的数据源
  final List<String> affectedSources;

  /// 建议措施
  final String recommendedAction;

  const RouteHealthIssue({
    required this.type,
    required this.description,
    required this.affectedSources,
    required this.recommendedAction,
  });
}

/// 路由问题类型
enum RouteIssueType {
  /// 数据源故障
  sourceFailure,

  /// 性能下降
  performanceDegradation,

  /// 负载过高
  highLoad,

  /// 配置错误
  configurationError,
}

/// 路由诊断结果
class RouteDiagnosticResult {
  /// 诊断的操作
  final DataOperation operation;

  /// 诊断结果
  final DiagnosticStatus status;

  /// 推荐数据源
  final List<DataSource> recommendedSources;

  /// 性能预测
  final List<PerformancePrediction> predictions;

  const RouteDiagnosticResult({
    required this.operation,
    required this.status,
    required this.recommendedSources,
    required this.predictions,
  });
}

/// 诊断状态
enum DiagnosticStatus {
  /// 正常
  normal,

  /// 警告
  warning,

  /// 错误
  error,
}

/// 性能预测
class PerformancePrediction {
  /// 数据源
  final DataSource dataSource;

  /// 预测响应时间
  final double predictedResponseTime;

  /// 预测成功率
  final double predictedSuccessRate;

  /// 置信度
  final double confidence;

  const PerformancePrediction({
    required this.dataSource,
    required this.predictedResponseTime,
    required this.predictedSuccessRate,
    required this.confidence,
  });
}

/// 路由建议
class RouteRecommendation {
  /// 建议类型
  final RecommendationType type;

  /// 建议标题
  final String title;

  /// 建议描述
  final String description;

  /// 预期收益
  final ExpectedBenefit expectedBenefit;

  /// 实施难度
  final ImplementationDifficulty difficulty;

  const RouteRecommendation({
    required this.type,
    required this.title,
    required this.description,
    required this.expectedBenefit,
    required this.difficulty,
  });
}

/// 建议类型
enum RecommendationType {
  /// 性能优化
  performance,

  /// 可靠性提升
  reliability,

  /// 成本降低
  cost,

  /// 功能增强
  feature,
}

/// 预期收益
class ExpectedBenefit {
  /// 性能提升百分比
  final double performanceImprovement;

  /// 成本降低百分比
  final double costReduction;

  /// 可靠性提升
  final double reliabilityImprovement;

  const ExpectedBenefit({
    required this.performanceImprovement,
    required this.costReduction,
    required this.reliabilityImprovement,
  });
}

/// 实施难度
enum ImplementationDifficulty {
  /// 简单
  easy,

  /// 中等
  medium,

  /// 困难
  hard,
}
