import 'package:dartz/dartz.dart';
import '../entities/portfolio_holding.dart';
import '../entities/portfolio_profit_metrics.dart';
import '../entities/portfolio_summary.dart';
import '../entities/portfolio_profit_calculation_criteria.dart';
import '../entities/fund_corporate_action.dart';
import '../entities/fund_split_detail.dart';

/// 组合收益数据仓库接口
///
/// 定义组合收益计算相关的数据访问方法
abstract class PortfolioProfitRepository {
  /// 获取用户持仓列表
  ///
  /// [userId] - 用户ID
  /// 返回用户的持仓列表或错误信息
  Future<Either<Failure, List<PortfolioHolding>>> getUserHoldings(
      String userId);

  /// 获取基金净值历史数据
  ///
  /// [fundCode] - 基金代码
  /// [startDate] - 开始日期
  /// [endDate] - 结束日期
  /// 返回净值历史数据或错误信息
  Future<Either<Failure, Map<DateTime, double>>> getFundNavHistory({
    required String fundCode,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// 获取基准指数历史数据
  ///
  /// [benchmarkCode] - 基准指数代码
  /// [startDate] - 开始日期
  /// [endDate] - 结束日期
  /// 返回基准指数历史数据或错误信息
  Future<Either<Failure, Map<DateTime, double>>> getBenchmarkHistory({
    required String benchmarkCode,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// 获取基金分红历史数据
  ///
  /// [fundCode] - 基金代码
  /// [startDate] - 开始日期
  /// [endDate] - 结束日期
  /// 返回分红历史数据或错误信息
  Future<Either<Failure, List<FundCorporateAction>>> getFundDividendHistory({
    required String fundCode,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// 获取基金拆分历史数据
  ///
  /// [fundCode] - 基金代码
  /// [startDate] - 开始日期
  /// [endDate] - 结束日期
  /// 返回拆分历史数据或错误信息
  Future<Either<Failure, List<FundSplitDetail>>> getFundSplitHistory({
    required String fundCode,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// 计算单个基金收益指标
  ///
  /// [holding] - 持仓数据
  /// [criteria] - 计算标准
  /// 返回收益指标或错误信息
  Future<Either<Failure, PortfolioProfitMetrics>> calculateFundProfitMetrics({
    required PortfolioHolding holding,
    required PortfolioProfitCalculationCriteria criteria,
  });

  /// 计算组合汇总收益
  ///
  /// [holdings] - 持仓列表
  /// [criteria] - 计算标准
  /// 返回组合汇总数据或错误信息
  Future<Either<Failure, PortfolioSummary>> calculatePortfolioSummary({
    required List<PortfolioHolding> holdings,
    required PortfolioProfitCalculationCriteria criteria,
  });

  /// 批量计算多个基金收益指标
  ///
  /// [holdings] - 持仓列表
  /// [criteria] - 计算标准
  /// 返回收益指标映射或错误信息
  Future<Either<Failure, Map<String, PortfolioProfitMetrics>>>
      calculateBatchProfitMetrics({
    required List<PortfolioHolding> holdings,
    required PortfolioProfitCalculationCriteria criteria,
  });

  /// 计算多维度收益对比
  ///
  /// [holdings] - 持仓列表
  /// [frequencies] - 计算频率列表
  /// [baseCriteria] - 基础计算标准
  /// 返回多维度对比结果或错误信息
  Future<Either<Failure, Map<String, PortfolioProfitMetrics>>>
      calculateMultiDimensionalComparison({
    required List<PortfolioHolding> holdings,
    required List<CalculationFrequency> frequencies,
    PortfolioProfitCalculationCriteria? baseCriteria,
  });

  /// 获取收益计算缓存
  ///
  /// [cacheKey] - 缓存键
  /// 返回缓存的收益指标或错误信息
  Future<Either<Failure, PortfolioProfitMetrics?>> getCachedProfitMetrics(
      String cacheKey);

  /// 缓存收益计算结果
  ///
  /// [cacheKey] - 缓存键
  /// [metrics] - 收益指标
  /// [expiryDuration] - 过期时间
  /// 返回缓存操作结果或错误信息
  Future<Either<Failure, void>> cacheProfitMetrics({
    required String cacheKey,
    required PortfolioProfitMetrics metrics,
    required Duration expiryDuration,
  });

  /// 清除过期缓存
  ///
  /// 返回清除操作结果或错误信息
  Future<Either<Failure, void>> clearExpiredCache();

  /// 验证计算标准有效性
  ///
  /// [criteria] - 计算标准
  /// 返回验证结果或错误信息
  Future<Either<Failure, bool>> validateCalculationCriteria(
      PortfolioProfitCalculationCriteria criteria);

  /// 获取支持的基准指数列表
  ///
  /// 返回基准指数列表或错误信息
  Future<Either<Failure, List<BenchmarkIndex>>> getSupportedBenchmarkIndices();

  /// 获取数据质量报告
  ///
  /// [fundCode] - 基金代码
  /// [startDate] - 开始日期
  /// [endDate] - 结束日期
  /// 返回数据质量报告或错误信息
  Future<Either<Failure, DataQualityReport>> getDataQualityReport({
    required String fundCode,
    required DateTime startDate,
    required DateTime endDate,
  });
}

/// 基准指数信息
class BenchmarkIndex {
  final String code;
  final String name;
  final String description;
  final BenchmarkType type;
  final String exchange;
  final bool isActive;

  const BenchmarkIndex({
    required this.code,
    required this.name,
    required this.description,
    required this.type,
    required this.exchange,
    this.isActive = true,
  });

  factory BenchmarkIndex.fromJson(Map<String, dynamic> json) {
    return BenchmarkIndex(
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      type: BenchmarkType.values.firstWhere(
        (e) => e.toString() == 'BenchmarkType.${json['type']}',
        orElse: () => BenchmarkType.stock,
      ),
      exchange: json['exchange'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'description': description,
      'type': type.toString().split('.').last,
      'exchange': exchange,
      'isActive': isActive,
    };
  }

  @override
  String toString() {
    return 'BenchmarkIndex{code: $code, name: $name, type: $type}';
  }
}

/// 基准指数类型
enum BenchmarkType {
  stock, // 股票指数
  bond, // 债券指数
  commodity, // 商品指数
  currency, // 货币指数
  mixed, // 混合指数
}

/// 数据质量报告
class DataQualityReport {
  final String fundCode;
  final DateTime startDate;
  final DateTime endDate;
  final int totalDays;
  final int availableDataPoints;
  final int missingDataPoints;
  final DataQuality quality;
  final List<String> issues;
  final Map<String, int> dataPointCounts;
  final DateTime reportGeneratedAt;

  const DataQualityReport({
    required this.fundCode,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.availableDataPoints,
    required this.missingDataPoints,
    required this.quality,
    required this.issues,
    required this.dataPointCounts,
    required this.reportGeneratedAt,
  });

  /// 数据完整率
  double get completenessRatio {
    return totalDays > 0 ? availableDataPoints / totalDays : 0.0;
  }

  /// 数据完整率百分比
  double get completenessPercentage => completenessRatio * 100;

  /// 是否有数据质量问题
  bool get hasIssues => issues.isNotEmpty;

  /// 数据质量等级描述
  String get qualityDescription {
    switch (quality) {
      case DataQuality.excellent:
        return '优秀';
      case DataQuality.good:
        return '良好';
      case DataQuality.fair:
        return '一般';
      case DataQuality.poor:
        return '较差';
    }
  }

  factory DataQualityReport.fromJson(Map<String, dynamic> json) {
    return DataQualityReport(
      fundCode: json['fundCode'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      totalDays: json['totalDays'] as int,
      availableDataPoints: json['availableDataPoints'] as int,
      missingDataPoints: json['missingDataPoints'] as int,
      quality: DataQuality.values.firstWhere(
        (e) => e.toString() == 'DataQuality.${json['quality']}',
        orElse: () => DataQuality.poor,
      ),
      issues: (json['issues'] as List<dynamic>).cast<String>(),
      dataPointCounts: Map<String, int>.from(json['dataPointCounts'] as Map),
      reportGeneratedAt: DateTime.parse(json['reportGeneratedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fundCode': fundCode,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'totalDays': totalDays,
      'availableDataPoints': availableDataPoints,
      'missingDataPoints': missingDataPoints,
      'quality': quality.toString().split('.').last,
      'issues': issues,
      'dataPointCounts': dataPointCounts,
      'reportGeneratedAt': reportGeneratedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'DataQualityReport{'
        'fundCode: $fundCode, '
        'completeness: ${completenessPercentage.toStringAsFixed(1)}%, '
        'quality: $qualityDescription, '
        'issues: ${issues.length}'
        '}';
  }
}

/// 失败类型
abstract class Failure {
  final String message;
  final String? code;
  final dynamic originalError;

  const Failure(this.message, {this.code, this.originalError});

  @override
  String toString() {
    return 'Failure{message: $message, code: $code}';
  }
}

/// 网络错误
class NetworkFailure extends Failure {
  const NetworkFailure(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

/// 数据解析错误
class DataParsingFailure extends Failure {
  const DataParsingFailure(String message,
      {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

/// 缓存错误
class CacheFailure extends Failure {
  const CacheFailure(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

/// 计算错误
class CalculationFailure extends Failure {
  const CalculationFailure(String message,
      {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

/// 验证错误
class ValidationFailure extends Failure {
  const ValidationFailure(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

/// 数据质量错误
class DataQualityFailure extends Failure {
  const DataQualityFailure(String message,
      {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

/// 权限错误
class PermissionFailure extends Failure {
  const PermissionFailure(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

/// 未知错误
class UnknownFailure extends Failure {
  const UnknownFailure(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}
