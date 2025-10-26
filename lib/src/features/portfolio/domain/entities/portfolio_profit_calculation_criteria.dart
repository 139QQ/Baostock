import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'portfolio_profit_calculation_criteria.g.dart';

/// 组合收益计算标准实体
///
/// 定义收益计算的各种参数和标准
@JsonSerializable()
class PortfolioProfitCalculationCriteria extends Equatable {
  /// 计算ID
  final String calculationId;

  /// 基金代码列表
  final List<String> fundCodes;

  /// 计算开始日期
  final DateTime startDate;

  /// 计算结束日期
  final DateTime endDate;

  /// 基准指数代码
  final String? benchmarkCode;

  /// 计算频率
  final CalculationFrequency frequency;

  /// 收益类型
  final ReturnType returnType;

  /// 是否包含分红再投资
  final bool includeDividendReinvestment;

  /// 是否考虑公司行为
  final bool considerCorporateActions;

  /// 风险调整方法
  final RiskAdjustmentMethod riskAdjustmentMethod;

  /// 波动率计算方法
  final VolatilityCalculationMethod volatilityMethod;

  /// 基准比较方法
  final BenchmarkComparisonMethod benchmarkComparisonMethod;

  /// 时间加权收益率计算方法
  final TimeWeightedReturnMethod timeWeightedReturnMethod;

  /// 货币币种
  final String currency;

  /// 数据质量要求
  final DataQualityRequirement dataQualityRequirement;

  /// 最少数据天数要求
  final int minimumDataDays;

  /// 缺失数据处理方式
  final MissingDataHandling missingDataHandling;

  /// 异常值处理方式
  final OutlierHandling outlierHandling;

  /// 是否包含税费计算
  final bool includeTaxAndFees;

  /// 税率
  final double taxRate;

  /// 交易费率
  final double transactionFeeRate;

  /// 计算精度要求
  final CalculationPrecision precision;

  /// 创建时间
  final DateTime createdAt;

  /// 备注
  final String? notes;

  const PortfolioProfitCalculationCriteria({
    required this.calculationId,
    required this.fundCodes,
    required this.startDate,
    required this.endDate,
    this.benchmarkCode,
    this.frequency = CalculationFrequency.daily,
    this.returnType = ReturnType.total,
    this.includeDividendReinvestment = true,
    this.considerCorporateActions = true,
    this.riskAdjustmentMethod = RiskAdjustmentMethod.standard,
    this.volatilityMethod = VolatilityCalculationMethod.standard,
    this.benchmarkComparisonMethod = BenchmarkComparisonMethod.absolute,
    this.timeWeightedReturnMethod = TimeWeightedReturnMethod.approximate,
    this.currency = 'CNY',
    this.dataQualityRequirement = DataQualityRequirement.good,
    this.minimumDataDays = 30,
    this.missingDataHandling = MissingDataHandling.interpolation,
    this.outlierHandling = OutlierHandling.keep,
    this.includeTaxAndFees = false,
    this.taxRate = 0.0,
    this.transactionFeeRate = 0.0,
    this.precision = CalculationPrecision.high,
    required this.createdAt,
    this.notes,
  });

  /// 从JSON创建PortfolioProfitCalculationCriteria实例
  factory PortfolioProfitCalculationCriteria.fromJson(
          Map<String, dynamic> json) =>
      _$PortfolioProfitCalculationCriteriaFromJson(json);

  /// 转换为JSON
  Map<String, dynamic> toJson() =>
      _$PortfolioProfitCalculationCriteriaToJson(this);

  /// 创建副本并更新指定字段
  PortfolioProfitCalculationCriteria copyWith({
    String? calculationId,
    List<String>? fundCodes,
    DateTime? startDate,
    DateTime? endDate,
    String? benchmarkCode,
    CalculationFrequency? frequency,
    ReturnType? returnType,
    bool? includeDividendReinvestment,
    bool? considerCorporateActions,
    RiskAdjustmentMethod? riskAdjustmentMethod,
    VolatilityCalculationMethod? volatilityMethod,
    BenchmarkComparisonMethod? benchmarkComparisonMethod,
    TimeWeightedReturnMethod? timeWeightedReturnMethod,
    String? currency,
    DataQualityRequirement? dataQualityRequirement,
    int? minimumDataDays,
    MissingDataHandling? missingDataHandling,
    OutlierHandling? outlierHandling,
    bool? includeTaxAndFees,
    double? taxRate,
    double? transactionFeeRate,
    CalculationPrecision? precision,
    DateTime? createdAt,
    String? notes,
  }) {
    return PortfolioProfitCalculationCriteria(
      calculationId: calculationId ?? this.calculationId,
      fundCodes: fundCodes ?? this.fundCodes,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      benchmarkCode: benchmarkCode ?? this.benchmarkCode,
      frequency: frequency ?? this.frequency,
      returnType: returnType ?? this.returnType,
      includeDividendReinvestment:
          includeDividendReinvestment ?? this.includeDividendReinvestment,
      considerCorporateActions:
          considerCorporateActions ?? this.considerCorporateActions,
      riskAdjustmentMethod: riskAdjustmentMethod ?? this.riskAdjustmentMethod,
      volatilityMethod: volatilityMethod ?? this.volatilityMethod,
      benchmarkComparisonMethod:
          benchmarkComparisonMethod ?? this.benchmarkComparisonMethod,
      timeWeightedReturnMethod:
          timeWeightedReturnMethod ?? this.timeWeightedReturnMethod,
      currency: currency ?? this.currency,
      dataQualityRequirement:
          dataQualityRequirement ?? this.dataQualityRequirement,
      minimumDataDays: minimumDataDays ?? this.minimumDataDays,
      missingDataHandling: missingDataHandling ?? this.missingDataHandling,
      outlierHandling: outlierHandling ?? this.outlierHandling,
      includeTaxAndFees: includeTaxAndFees ?? this.includeTaxAndFees,
      taxRate: taxRate ?? this.taxRate,
      transactionFeeRate: transactionFeeRate ?? this.transactionFeeRate,
      precision: precision ?? this.precision,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }

  /// 计算天数
  int get calculationDays {
    return endDate.difference(startDate).inDays;
  }

  /// 是否为长期计算（超过1年）
  bool get isLongTermCalculation => calculationDays > 365;

  /// 是否为短期计算（少于1个月）
  bool get isShortTermCalculation => calculationDays < 30;

  /// 是否包含基准比较
  bool get includesBenchmarkComparison => benchmarkCode != null;

  /// 获取计算频率描述
  String get frequencyDescription {
    switch (frequency) {
      case CalculationFrequency.daily:
        return '每日';
      case CalculationFrequency.weekly:
        return '每周';
      case CalculationFrequency.monthly:
        return '每月';
      case CalculationFrequency.quarterly:
        return '每季度';
      case CalculationFrequency.annually:
        return '每年';
    }
  }

  /// 获取收益类型描述
  String get returnTypeDescription {
    switch (returnType) {
      case ReturnType.price:
        return '价格收益';
      case ReturnType.dividend:
        return '分红收益';
      case ReturnType.total:
        return '总收益';
      case ReturnType.excess:
        return '超额收益';
    }
  }

  /// 获取风险调整方法描述
  String get riskAdjustmentDescription {
    switch (riskAdjustmentMethod) {
      case RiskAdjustmentMethod.standard:
        return '标准风险调整';
      case RiskAdjustmentMethod.exponential:
        return '指数风险调整';
      case RiskAdjustmentMethod.weighted:
        return '加权风险调整';
    }
  }

  /// 获取数据质量要求描述
  String get dataQualityDescription {
    switch (dataQualityRequirement) {
      case DataQualityRequirement.excellent:
        return '优秀';
      case DataQualityRequirement.good:
        return '良好';
      case DataQualityRequirement.fair:
        return '一般';
      case DataQualityRequirement.poor:
        return '较差';
    }
  }

  /// 获取精度要求描述
  String get precisionDescription {
    switch (precision) {
      case CalculationPrecision.low:
        return '低精度（4位小数）';
      case CalculationPrecision.medium:
        return '中等精度（6位小数）';
      case CalculationPrecision.high:
        return '高精度（8位小数）';
      case CalculationPrecision.veryHigh:
        return '极高精度（12位小数）';
    }
  }

  /// 验证计算标准是否有效
  bool isValid() {
    return calculationId.isNotEmpty &&
        fundCodes.isNotEmpty &&
        startDate.isBefore(endDate) &&
        calculationDays >= minimumDataDays &&
        taxRate >= 0 &&
        taxRate <= 1 &&
        transactionFeeRate >= 0 &&
        transactionFeeRate <= 1;
  }

  /// 获取计算配置摘要
  String get calculationSummary {
    final buffer = StringBuffer();
    buffer.writeln('计算标准摘要:');
    buffer.writeln('- 基金数量: ${fundCodes.length}');
    buffer.writeln('- 计算期间: ${calculationDays}天');
    buffer.writeln('- 计算频率: $frequencyDescription');
    buffer.writeln('- 收益类型: $returnTypeDescription');
    buffer.writeln('- 分红再投资: ${includeDividendReinvestment ? '包含' : '不包含'}');
    buffer.writeln('- 公司行为: ${considerCorporateActions ? '考虑' : '不考虑'}');
    if (includesBenchmarkComparison) {
      buffer.writeln('- 基准指数: $benchmarkCode');
    }
    buffer.writeln('- 数据质量: $dataQualityDescription');
    buffer.writeln('- 计算精度: $precisionDescription');

    return buffer.toString();
  }

  @override
  List<Object?> get props => [
        calculationId,
        fundCodes,
        startDate,
        endDate,
        benchmarkCode,
        frequency,
        returnType,
        includeDividendReinvestment,
        considerCorporateActions,
        riskAdjustmentMethod,
        volatilityMethod,
        benchmarkComparisonMethod,
        timeWeightedReturnMethod,
        currency,
        dataQualityRequirement,
        minimumDataDays,
        missingDataHandling,
        outlierHandling,
        includeTaxAndFees,
        taxRate,
        transactionFeeRate,
        precision,
        createdAt,
        notes,
      ];

  /// 创建基础计算标准
  factory PortfolioProfitCalculationCriteria.basic() {
    final now = DateTime.now();
    return PortfolioProfitCalculationCriteria(
      calculationId: 'basic_${now.millisecondsSinceEpoch}',
      fundCodes: [],
      startDate: now.subtract(const Duration(days: 365)),
      endDate: now,
      frequency: CalculationFrequency.daily,
      returnType: ReturnType.total,
      includeDividendReinvestment: true,
      considerCorporateActions: true,
      riskAdjustmentMethod: RiskAdjustmentMethod.standard,
      volatilityMethod: VolatilityCalculationMethod.standard,
      benchmarkComparisonMethod: BenchmarkComparisonMethod.absolute,
      timeWeightedReturnMethod: TimeWeightedReturnMethod.approximate,
      currency: 'CNY',
      dataQualityRequirement: DataQualityRequirement.good,
      minimumDataDays: 30,
      missingDataHandling: MissingDataHandling.interpolation,
      outlierHandling: OutlierHandling.keep,
      includeTaxAndFees: false,
      taxRate: 0.0,
      transactionFeeRate: 0.0,
      precision: CalculationPrecision.high,
      createdAt: now,
    );
  }

  @override
  String toString() {
    return 'PortfolioProfitCalculationCriteria{'
        'calculationId: $calculationId, '
        'funds: ${fundCodes.length}, '
        'period: ${calculationDays}days, '
        'frequency: $frequency, '
        'returnType: $returnType, '
        'benchmark: $benchmarkCode'
        '}';
  }
}

/// 计算频率枚举
enum CalculationFrequency {
  @JsonValue('daily')
  daily, // 每日
  @JsonValue('weekly')
  weekly, // 每周
  @JsonValue('monthly')
  monthly, // 每月
  @JsonValue('quarterly')
  quarterly, // 每季度
  @JsonValue('annually')
  annually, // 每年
}

/// 收益类型枚举
enum ReturnType {
  @JsonValue('price')
  price, // 价格收益
  @JsonValue('dividend')
  dividend, // 分红收益
  @JsonValue('total')
  total, // 总收益
  @JsonValue('excess')
  excess, // 超额收益
}

/// 风险调整方法枚举
enum RiskAdjustmentMethod {
  @JsonValue('standard')
  standard, // 标准方法
  @JsonValue('exponential')
  exponential, // 指数方法
  @JsonValue('weighted')
  weighted, // 加权方法
}

/// 波动率计算方法枚举
enum VolatilityCalculationMethod {
  @JsonValue('standard')
  standard, // 标准差
  @JsonValue('exponential')
  exponential, // 指数加权移动平均
  @JsonValue('parkinson')
  parkinson, // Parkinson方法
  @JsonValue('garman_klass')
  garmanKlass, // Garman-Klass方法
}

/// 基准比较方法枚举
enum BenchmarkComparisonMethod {
  @JsonValue('absolute')
  absolute, // 绝对比较
  @JsonValue('relative')
  relative, // 相对比较
  @JsonValue('tracking_error')
  trackingError, // 跟踪误差
  @JsonValue('correlation')
  correlation, // 相关性
}

/// 时间加权收益率计算方法枚举
enum TimeWeightedReturnMethod {
  @JsonValue('exact')
  exact, // 精确方法
  @JsonValue('approximate')
  approximate, // 近似方法
  @JsonValue('modified_dietz')
  modifiedDietz, // 修正Dietz方法
}

/// 数据质量要求枚举
enum DataQualityRequirement {
  @JsonValue('excellent')
  excellent, // 优秀
  @JsonValue('good')
  good, // 良好
  @JsonValue('fair')
  fair, // 一般
  @JsonValue('poor')
  poor, // 较差
}

/// 缺失数据处理方式枚举
enum MissingDataHandling {
  @JsonValue('interpolation')
  interpolation, // 插值
  @JsonValue('forward_fill')
  forwardFill, // 前向填充
  @JsonValue('backward_fill')
  backwardFill, // 后向填充
  @JsonValue('skip')
  skip, // 跳过
  @JsonValue('zero')
  zero, // 零值
}

/// 异常值处理方式枚举
enum OutlierHandling {
  @JsonValue('keep')
  keep, // 保留
  @JsonValue('remove')
  remove, // 移除
  @JsonValue('cap')
  cap, // 封顶
  @JsonValue('winsorize')
  winsorize, // 缩尾处理
}

/// 计算精度枚举
enum CalculationPrecision {
  @JsonValue('low')
  low, // 低精度（4位小数）
  @JsonValue('medium')
  medium, // 中等精度（6位小数）
  @JsonValue('high')
  high, // 高精度（8位小数）
  @JsonValue('very_high')
  veryHigh, // 极高精度（12位小数）
}

/// 计算结果元数据
@immutable
class CalculationMetadata extends Equatable {
  /// 计算开始时间
  final DateTime startTime;

  /// 计算结束时间
  final DateTime endTime;

  /// 计算耗时（毫秒）
  final int durationMs;

  /// 数据源版本
  final String dataSourceVersion;

  /// 算法版本
  final String algorithmVersion;

  /// 处理的数据点数量
  final int dataPointsProcessed;

  /// 缺失数据点数量
  final int missingDataPoints;

  /// 异常数据点数量
  final int outlierDataPoints;

  /// 计算状态
  final CalculationStatus status;

  /// 错误信息
  final String? errorMessage;

  /// 警告信息
  final List<String> warnings;

  const CalculationMetadata({
    required this.startTime,
    required this.endTime,
    required this.durationMs,
    required this.dataSourceVersion,
    required this.algorithmVersion,
    required this.dataPointsProcessed,
    required this.missingDataPoints,
    required this.outlierDataPoints,
    required this.status,
    this.errorMessage,
    this.warnings = const [],
  });

  /// 计算成功率
  double get successRate {
    final total = dataPointsProcessed + missingDataPoints;
    return total == 0 ? 0.0 : dataPointsProcessed / total;
  }

  /// 数据质量评分
  double get dataQualityScore {
    final missingRatio =
        missingDataPoints / (dataPointsProcessed + missingDataPoints);
    final outlierRatio = outlierDataPoints / dataPointsProcessed;
    return (1.0 - missingRatio - outlierRatio * 0.5).clamp(0.0, 1.0);
  }

  /// 是否有警告
  bool get hasWarnings => warnings.isNotEmpty;

  /// 是否有错误
  bool get hasError => errorMessage != null;

  @override
  List<Object?> get props => [
        startTime,
        endTime,
        durationMs,
        dataSourceVersion,
        algorithmVersion,
        dataPointsProcessed,
        missingDataPoints,
        outlierDataPoints,
        status,
        errorMessage,
        warnings,
      ];

  @override
  String toString() {
    return 'CalculationMetadata{'
        'duration: ${durationMs}ms, '
        'dataPoints: $dataPointsProcessed, '
        'successRate: ${(successRate * 100).toStringAsFixed(1)}%, '
        'qualityScore: ${(dataQualityScore * 100).toStringAsFixed(1)}%, '
        'status: $status'
        '}';
  }
}

/// 计算状态枚举
enum CalculationStatus {
  @JsonValue('pending')
  pending, // 待计算
  @JsonValue('running')
  running, // 计算中
  @JsonValue('completed')
  completed, // 已完成
  @JsonValue('failed')
  failed, // 失败
  @JsonValue('cancelled')
  cancelled, // 已取消
}
