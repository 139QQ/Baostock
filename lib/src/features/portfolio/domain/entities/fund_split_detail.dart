import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'fund_split_detail.g.dart';

/// 基金拆分详情实体
///
/// 包含基金拆分的详细信息
@JsonSerializable()
class FundSplitDetail extends Equatable {
  /// 基金代码
  final String fundCode;

  /// 基金名称
  final String fundName;

  /// 年份
  final int year;

  /// 拆分折算日
  final DateTime splitDate;

  /// 拆分类型
  final String splitType;

  /// 拆分折算比例
  final double splitRatio;

  /// 拆分前净值
  final double navBeforeSplit;

  /// 拆分后净值
  final double navAfterSplit;

  /// 拆分前份额
  final double sharesBeforeSplit;

  /// 拆分后份额
  final double sharesAfterSplit;

  /// 权益登记日
  final DateTime recordDate;

  /// 拆分执行日
  final DateTime executionDate;

  /// 拆分原因
  final String? splitReason;

  /// 状态
  final SplitStatus status;

  /// 备注
  final String? notes;

  const FundSplitDetail({
    required this.fundCode,
    required this.fundName,
    required this.year,
    required this.splitDate,
    required this.splitType,
    required this.splitRatio,
    required this.navBeforeSplit,
    required this.navAfterSplit,
    this.sharesBeforeSplit = 0.0,
    this.sharesAfterSplit = 0.0,
    required this.recordDate,
    required this.executionDate,
    this.splitReason,
    this.status = SplitStatus.pending,
    this.notes,
  });

  /// 从JSON创建FundSplitDetail实例
  factory FundSplitDetail.fromJson(Map<String, dynamic> json) =>
      _$FundSplitDetailFromJson(json);

  /// 转换为JSON
  Map<String, dynamic> toJson() => _$FundSplitDetailToJson(this);

  /// 创建副本并更新指定字段
  FundSplitDetail copyWith({
    String? fundCode,
    String? fundName,
    int? year,
    DateTime? splitDate,
    String? splitType,
    double? splitRatio,
    double? navBeforeSplit,
    double? navAfterSplit,
    double? sharesBeforeSplit,
    double? sharesAfterSplit,
    DateTime? recordDate,
    DateTime? executionDate,
    String? splitReason,
    SplitStatus? status,
    String? notes,
  }) {
    return FundSplitDetail(
      fundCode: fundCode ?? this.fundCode,
      fundName: fundName ?? this.fundName,
      year: year ?? this.year,
      splitDate: splitDate ?? this.splitDate,
      splitType: splitType ?? this.splitType,
      splitRatio: splitRatio ?? this.splitRatio,
      navBeforeSplit: navBeforeSplit ?? this.navBeforeSplit,
      navAfterSplit: navAfterSplit ?? this.navAfterSplit,
      sharesBeforeSplit: sharesBeforeSplit ?? this.sharesBeforeSplit,
      sharesAfterSplit: sharesAfterSplit ?? this.sharesAfterSplit,
      recordDate: recordDate ?? this.recordDate,
      executionDate: executionDate ?? this.executionDate,
      splitReason: splitReason ?? this.splitReason,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  /// 是否为已执行的拆分
  bool get isExecuted => status == SplitStatus.executed;

  /// 是否为待执行的拆分
  bool get isPending => status == SplitStatus.pending;

  /// 是否为拆分（拆分比例>1）
  bool get isSplit => splitRatio > 1.0;

  /// 是否为合并（拆分比例<1）
  bool get isMerge => splitRatio < 1.0;

  /// 获取拆分描述
  String get splitDescription {
    if (isSplit) {
      return '1拆${splitRatio.toStringAsFixed(2)}';
    } else if (isMerge) {
      final ratio = 1.0 / splitRatio;
      return '${ratio.toStringAsFixed(2)}并1';
    }
    return '无拆分';
  }

  /// 计算拆分后的份额
  double calculateSharesAfterSplit(double shares) {
    return shares * splitRatio;
  }

  /// 计算拆分后的净值
  double calculateNavAfterSplit(double nav) {
    return nav / splitRatio;
  }

  /// 验证拆分计算是否正确
  bool validateSplitCalculation() {
    // 拆分前总价值 = 拆分后总价值
    final valueBefore = sharesBeforeSplit * navBeforeSplit;
    final valueAfter = sharesAfterSplit * navAfterSplit;
    return (valueBefore - valueAfter).abs() < 0.01; // 允许1分钱误差
  }

  /// 计算距离拆分执行日的天数
  int get daysUntilExecution {
    final now = DateTime.now();
    return executionDate.difference(now).inDays;
  }

  /// 是否即将执行（7天内）
  bool get isImminent => daysUntilExecution <= 7 && daysUntilExecution >= 0;

  /// 是否已过期
  bool get isExpired => daysUntilExecution < 0;

  /// 获取状态描述
  String get statusDescription {
    switch (status) {
      case SplitStatus.pending:
        return '待执行';
      case SplitStatus.executed:
        return '已执行';
      case SplitStatus.cancelled:
        return '已取消';
      case SplitStatus.postponed:
        return '已延期';
    }
  }

  /// 验证数据完整性
  bool isValid() {
    return fundCode.isNotEmpty &&
        fundName.isNotEmpty &&
        splitRatio > 0 &&
        navBeforeSplit > 0 &&
        navAfterSplit > 0;
  }

  @override
  List<Object?> get props => [
        fundCode,
        fundName,
        year,
        splitDate,
        splitType,
        splitRatio,
        navBeforeSplit,
        navAfterSplit,
        sharesBeforeSplit,
        sharesAfterSplit,
        recordDate,
        executionDate,
        splitReason,
        status,
        notes,
      ];

  @override
  String toString() {
    return 'FundSplitDetail{'
        'fundCode: $fundCode, '
        'splitDescription: $splitDescription, '
        'status: $statusDescription, '
        'executionDate: ${executionDate.toIso8601String()}'
        '}';
  }
}

/// 拆分状态枚举
enum SplitStatus {
  @JsonValue('pending')
  pending, // 待执行
  @JsonValue('executed')
  executed, // 已执行
  @JsonValue('cancelled')
  cancelled, // 已取消
  @JsonValue('postponed')
  postponed, // 已延期
}

/// 基金同类排名数据实体
@JsonSerializable()
class FundRankingData extends Equatable {
  /// 基金代码
  final String fundCode;

  /// 基金名称
  final String fundName;

  /// 基金类型
  final String fundType;

  /// 报告日期
  final DateTime reportDate;

  /// 当前排名
  final int currentRanking;

  /// 总基金数
  final int totalFunds;

  /// 排名百分比
  final double rankingPercentage;

  /// 上期排名
  final int? previousRanking;

  /// 排名变化
  final int? rankingChange;

  /// 排名变化方向
  final RankingChangeDirection? changeDirection;

  /// 收益率
  final double returnRate;

  /// 同类平均收益率
  final double categoryAverageReturn;

  /// 超越同类平均收益
  final double excessReturn;

  /// 评级
  final String? rating;

  /// 星级
  final int? starRating;

  /// 成立时间
  final DateTime? inceptionDate;

  /// 基金规模
  final double? fundSize;

  /// 管理人
  final String? manager;

  const FundRankingData({
    required this.fundCode,
    required this.fundName,
    required this.fundType,
    required this.reportDate,
    required this.currentRanking,
    required this.totalFunds,
    required this.rankingPercentage,
    this.previousRanking,
    this.rankingChange,
    this.changeDirection,
    required this.returnRate,
    required this.categoryAverageReturn,
    required this.excessReturn,
    this.rating,
    this.starRating,
    this.inceptionDate,
    this.fundSize,
    this.manager,
  });

  /// 从JSON创建FundRankingData实例
  factory FundRankingData.fromJson(Map<String, dynamic> json) =>
      _$FundRankingDataFromJson(json);

  /// 转换为JSON
  Map<String, dynamic> toJson() => _$FundRankingDataToJson(this);

  /// 创建副本并更新指定字段
  FundRankingData copyWith({
    String? fundCode,
    String? fundName,
    String? fundType,
    DateTime? reportDate,
    int? currentRanking,
    int? totalFunds,
    double? rankingPercentage,
    int? previousRanking,
    int? rankingChange,
    RankingChangeDirection? changeDirection,
    double? returnRate,
    double? categoryAverageReturn,
    double? excessReturn,
    String? rating,
    int? starRating,
    DateTime? inceptionDate,
    double? fundSize,
    String? manager,
  }) {
    return FundRankingData(
      fundCode: fundCode ?? this.fundCode,
      fundName: fundName ?? this.fundName,
      fundType: fundType ?? this.fundType,
      reportDate: reportDate ?? this.reportDate,
      currentRanking: currentRanking ?? this.currentRanking,
      totalFunds: totalFunds ?? this.totalFunds,
      rankingPercentage: rankingPercentage ?? this.rankingPercentage,
      previousRanking: previousRanking ?? this.previousRanking,
      rankingChange: rankingChange ?? this.rankingChange,
      changeDirection: changeDirection ?? this.changeDirection,
      returnRate: returnRate ?? this.returnRate,
      categoryAverageReturn:
          categoryAverageReturn ?? this.categoryAverageReturn,
      excessReturn: excessReturn ?? this.excessReturn,
      rating: rating ?? this.rating,
      starRating: starRating ?? this.starRating,
      inceptionDate: inceptionDate ?? this.inceptionDate,
      fundSize: fundSize ?? this.fundSize,
      manager: manager ?? this.manager,
    );
  }

  /// 获取排名描述
  String get rankingDescription => '$currentRanking/$totalFunds';

  /// 获取排名等级
  RankingLevel get rankingLevel {
    final percentile = rankingPercentage;
    if (percentile <= 10) return RankingLevel.top10;
    if (percentile <= 20) return RankingLevel.top20;
    if (percentile <= 30) return RankingLevel.top30;
    if (percentile <= 50) return RankingLevel.median;
    if (percentile <= 70) return RankingLevel.aboveMedian;
    if (percentile <= 90) return RankingLevel.belowMedian;
    return RankingLevel.bottom10;
  }

  /// 是否为优秀排名（前20%）
  bool get isExcellentRanking => rankingPercentage <= 20;

  /// 是否为良好排名（前30%）
  bool get isGoodRanking => rankingPercentage <= 30;

  /// 是否为中等排名（前50%）
  bool get isAverageRanking => rankingPercentage <= 50;

  /// 是否跑赢同类平均
  bool get outperformsCategory => excessReturn > 0;

  /// 获取星级描述
  String get starRatingDescription {
    if (starRating == null) return 'N/A';
    return '${'★' * starRating!}${'☆' * (5 - starRating!)}';
  }

  /// 获取收益率描述
  String get returnDescription {
    final rate = returnRate * 100;
    final sign = rate >= 0 ? '+' : '';
    return '$sign${rate.toStringAsFixed(2)}%';
  }

  /// 获取超额收益描述
  String get excessReturnDescription {
    final excess = excessReturn * 100;
    final sign = excess >= 0 ? '+' : '';
    return '$sign${excess.toStringAsFixed(2)}%';
  }

  /// 计算基金成立年限
  int get fundAgeYears {
    if (inceptionDate == null) return 0;
    return DateTime.now().difference(inceptionDate!).inDays ~/ 365;
  }

  /// 验证数据完整性
  bool isValid() {
    return fundCode.isNotEmpty &&
        fundName.isNotEmpty &&
        currentRanking > 0 &&
        totalFunds > 0 &&
        rankingPercentage >= 0 &&
        rankingPercentage <= 100;
  }

  @override
  List<Object?> get props => [
        fundCode,
        fundName,
        fundType,
        reportDate,
        currentRanking,
        totalFunds,
        rankingPercentage,
        previousRanking,
        rankingChange,
        changeDirection,
        returnRate,
        categoryAverageReturn,
        excessReturn,
        rating,
        starRating,
        inceptionDate,
        fundSize,
        manager,
      ];

  @override
  String toString() {
    return 'FundRankingData{'
        'fundCode: $fundCode, '
        'ranking: $rankingDescription, '
        'level: $rankingLevel, '
        'return: $returnDescription, '
        'excess: $excessReturnDescription, '
        'rating: $starRatingDescription'
        '}';
  }
}

/// 排名变化方向枚举
enum RankingChangeDirection {
  up, // 上升
  down, // 下降
  stable, // 稳定
}

/// 排名等级枚举
enum RankingLevel {
  top10, // 前10%
  top20, // 前20%
  top30, // 前30%
  median, // 中位数
  aboveMedian, // 高于中位数
  belowMedian, // 低于中位数
  bottom10, // 后10%
}
