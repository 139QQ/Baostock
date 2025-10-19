import '../entities/multi_dimensional_comparison_criteria.dart';
import '../entities/comparison_result.dart';

/// 基金对比Repository接口
///
/// 定义基金对比相关的数据访问方法
abstract class FundComparisonRepository {
  /// 获取多维度对比结果
  ///
  /// [criteria] 对比条件
  /// [forceRefresh] 是否强制刷新缓存
  /// 返回对比结果
  Future<ComparisonResult> getMultiDimensionalComparison(
    MultiDimensionalComparisonCriteria criteria, {
    bool forceRefresh = false,
  });

  /// 获取基金历史数据用于对比计算
  ///
  /// [fundCode] 基金代码
  /// [periods] 时间段列表
  /// 返回基金历史数据
  Future<Map<RankingPeriod, double>> getFundHistoricalReturns(
    String fundCode,
    List<RankingPeriod> periods,
  );

  /// 计算基金间相关性
  ///
  /// [fundCodes] 基金代码列表
  /// [period] 时间段
  /// 返回相关性矩阵
  Future<Map<String, Map<String, double>>> calculateCorrelationMatrix(
    List<String> fundCodes,
    RankingPeriod period,
  );

  /// 获取同类平均数据
  ///
  /// [fundType] 基金类型
  /// [period] 时间段
  /// 返回同类平均收益率
  Future<double> getCategoryAverageReturn(
    String fundType,
    RankingPeriod period,
  );

  /// 获取基准数据
  ///
  /// [benchmarkCode] 基准代码
  /// [period] 时间段
  /// 返回基准收益率
  Future<double> getBenchmarkReturn(
    String benchmarkCode,
    RankingPeriod period,
  );

  /// 保存对比配置
  ///
  /// [criteria] 对比条件
  /// [name] 配置名称
  /// 返回保存结果
  Future<bool> saveComparisonConfiguration(
    MultiDimensionalComparisonCriteria criteria,
    String name,
  );

  /// 获取保存的对比配置列表
  ///
  /// 返回配置列表
  Future<List<SavedComparisonConfiguration>> getSavedConfigurations();

  /// 删除保存的对比配置
  ///
  /// [configurationId] 配置ID
  /// 返回删除结果
  Future<bool> deleteConfiguration(String configurationId);

  /// 缓存对比结果
  ///
  /// [result] 对比结果
  /// 缓存结果供后续使用
  Future<void> cacheComparisonResult(ComparisonResult result);

  /// 从缓存获取对比结果
  ///
  /// [criteria] 对比条件
  /// 返回缓存的对比结果（如果存在）
  Future<ComparisonResult?> getCachedComparisonResult(
    MultiDimensionalComparisonCriteria criteria,
  );

  /// 清理过期缓存
  ///
  /// 清理超过指定时间的缓存数据
  Future<void> clearExpiredCache();
}

/// 保存的对比配置实体类
class SavedComparisonConfiguration {
  final String id;
  final String name;
  final MultiDimensionalComparisonCriteria criteria;
  final DateTime createdAt;
  final DateTime lastUsed;

  const SavedComparisonConfiguration({
    required this.id,
    required this.name,
    required this.criteria,
    required this.createdAt,
    required this.lastUsed,
  });
}
