import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'fund_corporate_action.g.dart';

/// 基金公司行为实体
///
/// 包含基金的分红、拆分、合并等公司行为信息
@JsonSerializable()
class FundCorporateAction extends Equatable {
  /// 基金代码
  final String fundCode;

  /// 基金名称
  final String fundName;

  /// 行为类型
  final CorporateActionType actionType;

  /// 公告日期
  final DateTime announcementDate;

  /// 权益登记日
  final DateTime recordDate;

  /// 除权除息日
  final DateTime exDate;

  /// 派发日/执行日
  final DateTime paymentDate;

  /// 年份
  final int year;

  /// 分红方案（每份分红金额）
  final double? dividendPerUnit;

  /// 分红金额（元）
  final double? dividendAmount;

  /// 拆分类型
  final String? splitType;

  /// 拆分比例
  final double? splitRatio;

  /// 调整前净值
  final double? navBeforeAdjustment;

  /// 调整后净值
  final double? navAfterAdjustment;

  /// 调整因子
  final double? adjustmentFactor;

  /// 状态
  final CorporateActionStatus status;

  /// 备注
  final String? notes;

  const FundCorporateAction({
    required this.fundCode,
    required this.fundName,
    required this.actionType,
    required this.announcementDate,
    required this.recordDate,
    required this.exDate,
    required this.paymentDate,
    required this.year,
    this.dividendPerUnit,
    this.dividendAmount,
    this.splitType,
    this.splitRatio,
    this.navBeforeAdjustment,
    this.navAfterAdjustment,
    this.adjustmentFactor,
    this.status = CorporateActionStatus.pending,
    this.notes,
  });

  /// 从JSON创建FundCorporateAction实例
  factory FundCorporateAction.fromJson(Map<String, dynamic> json) =>
      _$FundCorporateActionFromJson(json);

  /// 转换为JSON
  Map<String, dynamic> toJson() => _$FundCorporateActionToJson(this);

  /// 创建副本并更新指定字段
  FundCorporateAction copyWith({
    String? fundCode,
    String? fundName,
    CorporateActionType? actionType,
    DateTime? announcementDate,
    DateTime? recordDate,
    DateTime? exDate,
    DateTime? paymentDate,
    int? year,
    double? dividendPerUnit,
    double? dividendAmount,
    String? splitType,
    double? splitRatio,
    double? navBeforeAdjustment,
    double? navAfterAdjustment,
    double? adjustmentFactor,
    CorporateActionStatus? status,
    String? notes,
  }) {
    return FundCorporateAction(
      fundCode: fundCode ?? this.fundCode,
      fundName: fundName ?? this.fundName,
      actionType: actionType ?? this.actionType,
      announcementDate: announcementDate ?? this.announcementDate,
      recordDate: recordDate ?? this.recordDate,
      exDate: exDate ?? this.exDate,
      paymentDate: paymentDate ?? this.paymentDate,
      year: year ?? this.year,
      dividendPerUnit: dividendPerUnit ?? this.dividendPerUnit,
      dividendAmount: dividendAmount ?? this.dividendAmount,
      splitType: splitType ?? this.splitType,
      splitRatio: splitRatio ?? this.splitRatio,
      navBeforeAdjustment: navBeforeAdjustment ?? this.navBeforeAdjustment,
      navAfterAdjustment: navAfterAdjustment ?? this.navAfterAdjustment,
      adjustmentFactor: adjustmentFactor ?? this.adjustmentFactor,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  /// 是否为分红行为
  bool get isDividend => actionType == CorporateActionType.dividend;

  /// 是否为拆分行为
  bool get isSplit => actionType == CorporateActionType.split;

  /// 是否为已执行状态
  bool get isExecuted => status == CorporateActionStatus.executed;

  /// 是否为待执行状态
  bool get isPending => status == CorporateActionStatus.pending;

  /// 获取行为描述
  String get actionDescription {
    switch (actionType) {
      case CorporateActionType.dividend:
        final amount = dividendPerUnit ?? 0.0;
        return '每份分红¥${amount.toStringAsFixed(4)}';
      case CorporateActionType.split:
        final ratio = splitRatio ?? 0.0;
        return '拆分比例${ratio.toStringAsFixed(2)}:1';
      case CorporateActionType.merge:
        return '基金合并';
      case CorporateActionType.conversion:
        return '基金转换';
      case CorporateActionType.liquidation:
        return '基金清盘';
    }
  }

  /// 获取中文状态描述
  String get statusDescription {
    switch (status) {
      case CorporateActionStatus.pending:
        return '待执行';
      case CorporateActionStatus.executed:
        return '已执行';
      case CorporateActionStatus.cancelled:
        return '已取消';
      case CorporateActionStatus.postponed:
        return '已延期';
    }
  }

  /// 计算距离执行日的天数
  int get daysUntilExecution {
    final now = DateTime.now();
    return paymentDate.difference(now).inDays;
  }

  /// 是否即将执行（7天内）
  bool get isImminent => daysUntilExecution <= 7 && daysUntilExecution >= 0;

  /// 是否已过期
  bool get isExpired => daysUntilExecution < 0;

  /// 验证数据完整性
  bool isValid() {
    return fundCode.isNotEmpty &&
        fundName.isNotEmpty &&
        dividendPerUnit != null &&
        dividendPerUnit! > 0;
  }

  @override
  List<Object?> get props => [
        fundCode,
        fundName,
        actionType,
        announcementDate,
        recordDate,
        exDate,
        paymentDate,
        year,
        dividendPerUnit,
        dividendAmount,
        splitType,
        splitRatio,
        navBeforeAdjustment,
        navAfterAdjustment,
        adjustmentFactor,
        status,
        notes,
      ];

  @override
  String toString() {
    return 'FundCorporateAction{'
        'fundCode: $fundCode, '
        'actionType: $actionType, '
        'description: $actionDescription, '
        'status: $statusDescription, '
        'paymentDate: ${paymentDate.toIso8601String()}'
        '}';
  }
}

/// 公司行为类型枚举
enum CorporateActionType {
  @JsonValue('dividend')
  dividend, // 分红
  @JsonValue('split')
  split, // 拆分
  @JsonValue('merge')
  merge, // 合并
  @JsonValue('conversion')
  conversion, // 转换
  @JsonValue('liquidation')
  liquidation, // 清盘
}

/// 公司行为状态枚举
enum CorporateActionStatus {
  @JsonValue('pending')
  pending, // 待执行
  @JsonValue('executed')
  executed, // 已执行
  @JsonValue('cancelled')
  cancelled, // 已取消
  @JsonValue('postponed')
  postponed, // 已延期
}

/// 分红再投资计算结果
@immutable
class DividendReinvestmentResult extends Equatable {
  /// 原有持有份额
  final double originalShares;

  /// 分红金额
  final double dividendAmount;

  /// 再投资价格（除息日净值）
  final double reinvestmentPrice;

  /// 再投资获得的新份额
  final double reinvestedShares;

  /// 再投资后总份额
  final double totalSharesAfterReinvestment;

  /// 再投资日期
  final DateTime reinvestmentDate;

  /// 交易费用
  final double transactionFee;

  const DividendReinvestmentResult({
    required this.originalShares,
    required this.dividendAmount,
    required this.reinvestmentPrice,
    required this.reinvestedShares,
    required this.totalSharesAfterReinvestment,
    required this.reinvestmentDate,
    this.transactionFee = 0.0,
  });

  /// 再投资收益率提升
  double get yieldEnhancement {
    if (originalShares == 0) return 0.0;
    return (totalSharesAfterReinvestment - originalShares) / originalShares;
  }

  /// 再投资收益率提升百分比
  double get yieldEnhancementPercentage => yieldEnhancement * 100;

  /// 净再投资份额（扣除费用后）
  double get netReinvestedShares {
    return dividendAmount / reinvestmentPrice * (1 - transactionFee / 100);
  }

  @override
  List<Object?> get props => [
        originalShares,
        dividendAmount,
        reinvestmentPrice,
        reinvestedShares,
        totalSharesAfterReinvestment,
        reinvestmentDate,
        transactionFee,
      ];

  @override
  String toString() {
    return 'DividendReinvestmentResult{'
        'originalShares: $originalShares, '
        'dividendAmount: ¥${dividendAmount.toStringAsFixed(2)}, '
        'reinvestedShares: ${reinvestedShares.toStringAsFixed(2)}, '
        'yieldEnhancement: ${yieldEnhancementPercentage.toStringAsFixed(2)}%'
        '}';
  }
}

/// 基金拆分调整结果
@immutable
class FundSplitAdjustmentResult extends Equatable {
  /// 拆分前持有份额
  final double sharesBeforeSplit;

  /// 拆分比例（例如：2表示1拆2）
  final double splitRatio;

  /// 拆分后持有份额
  final double sharesAfterSplit;

  /// 拆分前净值
  final double navBeforeSplit;

  /// 拆分后净值
  final double navAfterSplit;

  /// 拆分日期
  final DateTime splitDate;

  /// 拆分类型
  final String splitType;

  const FundSplitAdjustmentResult({
    required this.sharesBeforeSplit,
    required this.splitRatio,
    required this.sharesAfterSplit,
    required this.navBeforeSplit,
    required this.navAfterSplit,
    required this.splitDate,
    required this.splitType,
  });

  /// 验证拆分计算是否正确（份额*净值应该保持不变）
  bool get isCalculationCorrect {
    final valueBefore = sharesBeforeSplit * navBeforeSplit;
    final valueAfter = sharesAfterSplit * navAfterSplit;
    return (valueBefore - valueAfter).abs() < 0.01; // 允许1分钱误差
  }

  /// 获取拆分描述
  String get splitDescription {
    return '$splitType: ${splitRatio.toStringAsFixed(2)}:1';
  }

  @override
  List<Object?> get props => [
        sharesBeforeSplit,
        splitRatio,
        sharesAfterSplit,
        navBeforeSplit,
        navAfterSplit,
        splitDate,
        splitType,
      ];

  @override
  String toString() {
    return 'FundSplitAdjustmentResult{'
        'splitDescription: $splitDescription, '
        'sharesBefore: ${sharesBeforeSplit.toStringAsFixed(2)}, '
        'sharesAfter: ${sharesAfterSplit.toStringAsFixed(2)}, '
        'navBefore: ${navBeforeSplit.toStringAsFixed(4)}, '
        'navAfter: ${navAfterSplit.toStringAsFixed(4)}'
        '}';
  }
}
