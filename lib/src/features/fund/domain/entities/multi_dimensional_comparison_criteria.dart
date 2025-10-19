import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'fund_ranking.dart';

part 'multi_dimensional_comparison_criteria.g.dart';

/// 多维度对比条件实体类
///
/// 定义基金对比的所有配置参数，包括基金选择、时间段等
@JsonSerializable()
class MultiDimensionalComparisonCriteria extends Equatable {
  /// 对比的基金代码列表（2-5个基金）
  final List<String> fundCodes;

  /// 对比的时间段列表
  final List<RankingPeriod> periods;

  /// 对比指标类型
  final ComparisonMetric metric;

  /// 是否包含统计信息
  final bool includeStatistics;

  /// 排序方式
  final ComparisonSortBy sortBy;

  /// 创建时间
  final DateTime createdAt;

  /// 对比名称（可选）
  final String? name;

  MultiDimensionalComparisonCriteria({
    required this.fundCodes,
    required this.periods,
    this.metric = ComparisonMetric.totalReturn,
    this.includeStatistics = true,
    this.sortBy = ComparisonSortBy.fundCode,
    DateTime? createdAt,
    this.name,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 从JSON创建实例
  factory MultiDimensionalComparisonCriteria.fromJson(
          Map<String, dynamic> json) =>
      _$MultiDimensionalComparisonCriteriaFromJson(json);

  /// 转换为JSON
  Map<String, dynamic> toJson() =>
      _$MultiDimensionalComparisonCriteriaToJson(this);

  /// 创建副本并修改指定属性
  MultiDimensionalComparisonCriteria copyWith({
    List<String>? fundCodes,
    List<RankingPeriod>? periods,
    ComparisonMetric? metric,
    bool? includeStatistics,
    ComparisonSortBy? sortBy,
    String? name,
  }) {
    return MultiDimensionalComparisonCriteria(
      fundCodes: fundCodes ?? this.fundCodes,
      periods: periods ?? this.periods,
      metric: metric ?? this.metric,
      includeStatistics: includeStatistics ?? this.includeStatistics,
      sortBy: sortBy ?? this.sortBy,
      createdAt: createdAt,
      name: name ?? this.name,
    );
  }

  /// 验证条件是否有效
  bool isValid() {
    return _validateFundCodes() == null &&
        _validatePeriods() == null &&
        _validateName() == null;
  }

  /// 获取验证错误信息
  String? getValidationError() {
    return _validateFundCodes() ?? _validatePeriods() ?? _validateName();
  }

  /// 验证基金代码
  String? _validateFundCodes() {
    if (fundCodes.length < 2) {
      return '至少需要选择2个基金进行对比';
    }
    if (fundCodes.length > 5) {
      return '最多只能选择5个基金进行对比';
    }

    // 验证每个基金代码格式
    for (final fundCode in fundCodes) {
      if (!_isValidFundCode(fundCode)) {
        return '基金代码格式不正确: $fundCode（应为6位数字）';
      }
    }

    // 检查重复的基金代码
    final uniqueCodes = fundCodes.toSet();
    if (uniqueCodes.length != fundCodes.length) {
      return '不能选择重复的基金代码';
    }

    return null;
  }

  /// 验证时间段
  String? _validatePeriods() {
    if (periods.isEmpty) {
      return '至少需要选择一个时间段';
    }
    if (periods.length > 5) {
      return '最多只能选择5个时间段';
    }

    // 检查重复的时间段
    final uniquePeriods = periods.toSet();
    if (uniquePeriods.length != periods.length) {
      return '不能选择重复的时间段';
    }

    return null;
  }

  /// 验证名称
  String? _validateName() {
    if (name != null && name!.isNotEmpty) {
      if (name!.length > 50) {
        return '对比名称不能超过50个字符';
      }
      // 检查是否包含特殊字符
      if (RegExp(r'[<>"\\&]').hasMatch(name!)) {
        return '对比名称不能包含特殊字符: < > " &';
      }
    }
    return null;
  }

  /// 验证基金代码格式（6位数字）
  bool _isValidFundCode(String fundCode) {
    return RegExp(r'^\d{6}$').hasMatch(fundCode);
  }

  @override
  List<Object?> get props => [
        fundCodes,
        periods,
        metric,
        includeStatistics,
        sortBy,
        createdAt,
        name,
      ];

  @override
  String toString() {
    return 'MultiDimensionalComparisonCriteria('
        'fundCodes: $fundCodes, '
        'periods: $periods, '
        'metric: $metric, '
        'name: $name)';
  }
}

/// 对比指标枚举
enum ComparisonMetric {
  @JsonValue('total_return')
  totalReturn, // 累计收益率

  @JsonValue('annualized_return')
  annualizedReturn, // 年化收益率

  @JsonValue('volatility')
  volatility, // 波动率

  @JsonValue('sharpe_ratio')
  sharpeRatio, // 夏普比率

  @JsonValue('max_drawdown')
  maxDrawdown, // 最大回撤
}

/// 对比排序方式枚举
enum ComparisonSortBy {
  @JsonValue('fund_code')
  fundCode, // 按基金代码排序

  @JsonValue('total_return')
  totalReturn, // 按累计收益率排序

  @JsonValue('recent_performance')
  recentPerformance, // 按近期表现排序

  @JsonValue('volatility')
  volatility, // 按波动率排序

  @JsonValue('custom')
  custom, // 自定义排序
}
