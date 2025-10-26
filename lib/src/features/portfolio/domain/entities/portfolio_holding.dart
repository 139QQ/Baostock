import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'portfolio_holding.g.dart';

/// 用户持仓数据实体
///
/// 表示用户在特定时间点的基金持仓信息，用于收益计算
@JsonSerializable()
class PortfolioHolding extends Equatable {
  /// 基金代码
  final String fundCode;

  /// 基金名称
  final String fundName;

  /// 基金类型
  final String fundType;

  /// 持有份额
  final double holdingAmount;

  /// 持有成本（单位净值）
  final double costNav;

  /// 持有成本金额
  final double costValue;

  /// 当前市值
  final double marketValue;

  /// 当前单位净值
  final double currentNav;

  /// 累计单位净值
  final double accumulatedNav;

  /// 持仓开始日期
  final DateTime holdingStartDate;

  /// 最后更新日期
  final DateTime lastUpdatedDate;

  /// 分红再投资标识
  final bool dividendReinvestment;

  /// 持仓状态
  final HoldingStatus status;

  /// 备注
  final String? notes;

  const PortfolioHolding({
    required this.fundCode,
    required this.fundName,
    required this.fundType,
    required this.holdingAmount,
    required this.costNav,
    required this.costValue,
    required this.marketValue,
    required this.currentNav,
    required this.accumulatedNav,
    required this.holdingStartDate,
    required this.lastUpdatedDate,
    this.dividendReinvestment = true,
    this.status = HoldingStatus.active,
    this.notes,
  });

  /// 从JSON创建PortfolioHolding实例
  factory PortfolioHolding.fromJson(Map<String, dynamic> json) =>
      _$PortfolioHoldingFromJson(json);

  /// 转换为JSON
  Map<String, dynamic> toJson() => _$PortfolioHoldingToJson(this);

  /// 创建副本并更新指定字段
  PortfolioHolding copyWith({
    String? fundCode,
    String? fundName,
    String? fundType,
    double? holdingAmount,
    double? costNav,
    double? costValue,
    double? marketValue,
    double? currentNav,
    double? accumulatedNav,
    DateTime? holdingStartDate,
    DateTime? lastUpdatedDate,
    bool? dividendReinvestment,
    HoldingStatus? status,
    String? notes,
  }) {
    return PortfolioHolding(
      fundCode: fundCode ?? this.fundCode,
      fundName: fundName ?? this.fundName,
      fundType: fundType ?? this.fundType,
      holdingAmount: holdingAmount ?? this.holdingAmount,
      costNav: costNav ?? this.costNav,
      costValue: costValue ?? this.costValue,
      marketValue: marketValue ?? this.marketValue,
      currentNav: currentNav ?? this.currentNav,
      accumulatedNav: accumulatedNav ?? this.accumulatedNav,
      holdingStartDate: holdingStartDate ?? this.holdingStartDate,
      lastUpdatedDate: lastUpdatedDate ?? this.lastUpdatedDate,
      dividendReinvestment: dividendReinvestment ?? this.dividendReinvestment,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  /// 计算当前收益率（基于当前净值vs成本净值）
  double get currentReturnRate {
    if (costNav == 0) return 0.0;
    return (currentNav - costNav) / costNav;
  }

  /// 计算当前收益金额
  double get currentReturnAmount {
    return marketValue - costValue;
  }

  /// 计算当前收益率百分比
  double get currentReturnPercentage => currentReturnRate * 100;

  /// 计算累计收益率（基于累计净值vs成本净值）
  double get accumulatedReturnRate {
    if (costNav == 0) return 0.0;
    return (accumulatedNav - costNav) / costNav;
  }

  /// 计算累计收益金额
  double get accumulatedReturnAmount {
    return holdingAmount * (accumulatedNav - costNav);
  }

  /// 计算累计收益率百分比
  double get accumulatedReturnPercentage => accumulatedReturnRate * 100;

  /// 计算持仓权重（基于当前市值）
  double calculateWeight(double totalMarketValue) {
    if (totalMarketValue == 0) return 0.0;
    return marketValue / totalMarketValue;
  }

  /// 计算持仓天数
  int get holdingDays {
    return DateTime.now().difference(holdingStartDate).inDays;
  }

  /// 是否为盈利持仓
  bool get isProfitable => currentReturnAmount > 0;

  /// 是否为亏损持仓
  bool get isLoss => currentReturnAmount < 0;

  /// 是否为长期持仓（超过1年）
  bool get isLongTerm => holdingDays > 365;

  /// 获取收益率描述
  String get returnDescription {
    final rate = currentReturnPercentage;
    final sign = rate >= 0 ? '+' : '';
    return '$sign${rate.toStringAsFixed(2)}%';
  }

  /// 获取收益金额描述
  String get amountDescription {
    final amount = currentReturnAmount;
    final sign = amount >= 0 ? '+' : '';
    return '$sign¥${amount.abs().toStringAsFixed(2)}';
  }

  /// 验证数据有效性
  bool isValid() {
    return fundCode.isNotEmpty &&
        fundName.isNotEmpty &&
        holdingAmount > 0 &&
        costNav > 0 &&
        costValue > 0 &&
        marketValue >= 0 &&
        currentNav > 0 &&
        accumulatedNav > 0;
  }

  /// 将整数转换为double（用于JSON序列化）
  static double _toDoubleFromInt(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  List<Object?> get props => [
        fundCode,
        fundName,
        fundType,
        holdingAmount,
        costNav,
        costValue,
        marketValue,
        currentNav,
        accumulatedNav,
        holdingStartDate,
        lastUpdatedDate,
        dividendReinvestment,
        status,
        notes,
      ];

  @override
  String toString() {
    return 'PortfolioHolding{'
        'fundCode: $fundCode, '
        'fundName: $fundName, '
        'holdingAmount: $holdingAmount, '
        'currentReturn: ${returnDescription}, '
        'status: $status'
        '}';
  }
}

/// 持仓状态枚举
enum HoldingStatus {
  @JsonValue('active')
  active, // 活跃持仓
  @JsonValue('sold')
  sold, // 已卖出
  @JsonValue('suspended')
  suspended, // 暂停
  @JsonValue('liquidated')
  liquidated, // 清盘
}

/// 持仓操作类型
enum HoldingOperation {
  buy, // 买入
  sell, // 卖出
  add, // 增持
  reduce, // 减持
  transfer, // 转换
}

/// 持仓变更记录
@immutable
class HoldingTransaction extends Equatable {
  /// 交易ID
  final String transactionId;

  /// 基金代码
  final String fundCode;

  /// 操作类型
  final HoldingOperation operation;

  /// 交易份额
  final double amount;

  /// 交易净值
  final double nav;

  /// 交易金额
  final double value;

  /// 交易日期
  final DateTime transactionDate;

  /// 手续费
  final double fee;

  /// 备注
  final String? notes;

  const HoldingTransaction({
    required this.transactionId,
    required this.fundCode,
    required this.operation,
    required this.amount,
    required this.nav,
    required this.value,
    required this.transactionDate,
    this.fee = 0.0,
    this.notes,
  });

  @override
  List<Object?> get props => [
        transactionId,
        fundCode,
        operation,
        amount,
        nav,
        value,
        transactionDate,
        fee,
        notes,
      ];

  @override
  String toString() {
    return 'HoldingTransaction{'
        'fundCode: $fundCode, '
        'operation: $operation, '
        'amount: $amount, '
        'value: ¥$value, '
        'date: ${transactionDate.toIso8601String()}'
        '}';
  }
}
