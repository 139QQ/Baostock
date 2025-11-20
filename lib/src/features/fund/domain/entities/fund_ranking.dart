import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/material.dart';

part 'fund_ranking.g.dart';

/// 基金排行榜实体类
///
/// 包含基金在不同时间段的排行信息，支持多维度排行展示
@JsonSerializable()
class FundRanking extends Equatable {
  /// 基金代码
  final String fundCode;

  /// 基金名称
  final String fundName;

  /// 基金类型
  final String fundType;

  /// 基金公司
  final String company;

  /// 当前排名位置
  final int rankingPosition;

  /// 总基金数量
  final int totalCount;

  /// 单位净值
  final double unitNav;

  /// 累计净值
  final double accumulatedNav;

  /// 日增长率
  final double dailyReturn;

  /// 近1周收益率
  final double return1W;

  /// 近1月收益率
  final double return1M;

  /// 近3月收益率
  final double return3M;

  /// 近6月收益率
  final double return6M;

  /// 近1年收益率
  final double return1Y;

  /// 近2年收益率
  final double return2Y;

  /// 近3年收益率
  final double return3Y;

  /// 今年来收益率
  final double returnYTD;

  /// 成立来收益率
  final double returnSinceInception;

  /// 排名日期
  final DateTime rankingDate;

  /// 上次排名位置（用于计算排名变化）
  final int? previousPosition;

  /// 排名变化
  final double? positionChange;

  /// 排行榜类型
  final RankingType rankingType;

  /// 排行榜时间段
  final RankingPeriod rankingPeriod;

  const FundRanking({
    required this.fundCode,
    required this.fundName,
    required this.fundType,
    required this.company,
    required this.rankingPosition,
    required this.totalCount,
    required this.unitNav,
    required this.accumulatedNav,
    required this.dailyReturn,
    required this.return1W,
    required this.return1M,
    required this.return3M,
    required this.return6M,
    required this.return1Y,
    required this.return2Y,
    required this.return3Y,
    required this.returnYTD,
    required this.returnSinceInception,
    required this.rankingDate,
    this.previousPosition,
    this.positionChange,
    required this.rankingType,
    required this.rankingPeriod,
  });

  /// 从JSON创建FundRanking实例
  factory FundRanking.fromJson(Map<String, dynamic> json) =>
      _$FundRankingFromJson(json);

  get oneYearReturn => null;

  /// 转换为JSON
  Map<String, dynamic> toJson() => _$FundRankingToJson(this);

  /// 创建副本并更新指定字段
  FundRanking copyWith({
    String? fundCode,
    String? fundName,
    String? fundType,
    String? company,
    int? rankingPosition,
    int? totalCount,
    double? unitNav,
    double? accumulatedNav,
    double? dailyReturn,
    double? return1W,
    double? return1M,
    double? return3M,
    double? return6M,
    double? return1Y,
    double? return2Y,
    double? return3Y,
    double? returnYTD,
    double? returnSinceInception,
    DateTime? rankingDate,
    int? previousPosition,
    double? positionChange,
    RankingType? rankingType,
    RankingPeriod? rankingPeriod,
  }) {
    return FundRanking(
      fundCode: fundCode ?? this.fundCode,
      fundName: fundName ?? this.fundName,
      fundType: fundType ?? this.fundType,
      company: company ?? this.company,
      rankingPosition: rankingPosition ?? this.rankingPosition,
      totalCount: totalCount ?? this.totalCount,
      unitNav: unitNav ?? this.unitNav,
      accumulatedNav: accumulatedNav ?? this.accumulatedNav,
      dailyReturn: dailyReturn ?? this.dailyReturn,
      return1W: return1W ?? this.return1W,
      return1M: return1M ?? this.return1M,
      return3M: return3M ?? this.return3M,
      return6M: return6M ?? this.return6M,
      return1Y: return1Y ?? this.return1Y,
      return2Y: return2Y ?? this.return2Y,
      return3Y: return3Y ?? this.return3Y,
      returnYTD: returnYTD ?? this.returnYTD,
      returnSinceInception: returnSinceInception ?? this.returnSinceInception,
      rankingDate: rankingDate ?? this.rankingDate,
      previousPosition: previousPosition ?? this.previousPosition,
      positionChange: positionChange ?? this.positionChange,
      rankingType: rankingType ?? this.rankingType,
      rankingPeriod: rankingPeriod ?? this.rankingPeriod,
    );
  }

  /// 获取排名百分比
  double get rankingPercentage {
    if (totalCount == 0) return 0.0;
    return (rankingPosition / totalCount) * 100;
  }

  /// 是否有排名变化数据
  bool get hasPositionChange =>
      previousPosition != null && positionChange != null;

  /// 获取排名变化方向
  RankingChangeDirection get changeDirection {
    if (!hasPositionChange) return RankingChangeDirection.noChange;

    if (positionChange! > 0) {
      return RankingChangeDirection.up;
    } else if (positionChange! < 0) {
      return RankingChangeDirection.down;
    } else {
      return RankingChangeDirection.noChange;
    }
  }

  /// 获取排名变化描述
  String get changeDescription {
    if (!hasPositionChange) return '';

    final absChange = positionChange!.abs();
    if (changeDirection == RankingChangeDirection.up) {
      return '↑$absChange';
    } else if (changeDirection == RankingChangeDirection.down) {
      return '↓$absChange';
    } else {
      return '-';
    }
  }

  /// 根据排名获取颜色
  static Color getRankingColor(int position) {
    if (position == 1) return const Color(0xFFFFD700); // 金色
    if (position == 2) return const Color(0xFFC0C0C0); // 银色
    if (position == 3) return const Color(0xFFCD7F32); // 铜色
    if (position <= 10) return const Color(0xFF1E40AF); // 前10名蓝色
    return const Color(0xFF6B7280); // 其他灰色
  }

  /// 根据排名获取徽章颜色
  static Color getRankingBadgeColor(int position) {
    if (position == 1) return const Color(0xFFFFD700); // 金色
    if (position == 2) return const Color(0xFFC0C0C0); // 银色
    if (position == 3) return const Color(0xFFCD7F32); // 铜色
    return const Color(0xFF1E40AF); // 其他蓝色
  }

  @override
  List<Object?> get props => [
        fundCode,
        fundName,
        fundType,
        company,
        rankingPosition,
        totalCount,
        unitNav,
        accumulatedNav,
        dailyReturn,
        return1W,
        return1M,
        return3M,
        return6M,
        return1Y,
        return2Y,
        return3Y,
        returnYTD,
        returnSinceInception,
        rankingDate,
        previousPosition,
        positionChange,
        rankingType,
        rankingPeriod,
      ];

  @override
  String toString() {
    return 'FundRanking{'
        'fundCode: $fundCode, '
        'fundName: $fundName, '
        'rankingPosition: $rankingPosition, '
        'rankingType: $rankingType, '
        'rankingPeriod: $rankingPeriod'
        '}';
  }
}

/// 排行榜类型枚举
enum RankingType {
  @JsonValue('overall')
  overall, // 总排行榜
  @JsonValue('by_type')
  byType, // 按基金类型排行
  @JsonValue('by_company')
  byCompany, // 按基金公司排行
  @JsonValue('by_period')
  byPeriod, // 按时间段排行
}

/// 排行榜时间段枚举
enum RankingPeriod {
  @JsonValue('daily')
  daily, // 日排行
  @JsonValue('1W')
  oneWeek, // 近1周
  @JsonValue('1M')
  oneMonth, // 近1月
  @JsonValue('3M')
  threeMonths, // 近3月
  @JsonValue('6M')
  sixMonths, // 近6月
  @JsonValue('1Y')
  oneYear, // 近1年
  @JsonValue('2Y')
  twoYears, // 近2年
  @JsonValue('3Y')
  threeYears, // 近3年
  @JsonValue('YTD')
  ytd, // 今年来
  @JsonValue('inception')
  sinceInception, // 成立来
}

/// 排名变化方向枚举
enum RankingChangeDirection {
  up, // 上升
  down, // 下降
  noChange, // 无变化
}

/// 排行榜查询条件
class RankingCriteria extends Equatable {
  /// 排行榜类型
  final RankingType rankingType;

  /// 排行榜时间段
  final RankingPeriod rankingPeriod;

  /// 基金类型筛选（可选）
  final String? fundType;

  /// 基金公司筛选（可选）
  final String? company;

  /// 排序方式
  final RankingSortBy sortBy;

  /// 页码
  final int page;

  /// 每页数量
  final int pageSize;

  const RankingCriteria({
    required this.rankingType,
    required this.rankingPeriod,
    this.fundType,
    this.company,
    this.sortBy = RankingSortBy.returnRate,
    this.page = 1,
    this.pageSize = 20,
  });

  /// 创建副本
  RankingCriteria copyWith({
    RankingType? rankingType,
    RankingPeriod? rankingPeriod,
    String? fundType,
    String? company,
    RankingSortBy? sortBy,
    int? page,
    int? pageSize,
  }) {
    return RankingCriteria(
      rankingType: rankingType ?? this.rankingType,
      rankingPeriod: rankingPeriod ?? this.rankingPeriod,
      fundType: fundType ?? this.fundType,
      company: company ?? this.company,
      sortBy: sortBy ?? this.sortBy,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  @override
  List<Object?> get props => [
        rankingType,
        rankingPeriod,
        fundType,
        company,
        sortBy,
        page,
        pageSize,
      ];

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'rankingType': rankingType.name,
      'rankingPeriod': rankingPeriod.name,
      'fundType': fundType,
      'company': company,
      'sortBy': sortBy.name,
      'page': page,
      'pageSize': pageSize,
    };
  }

  @override
  String toString() {
    return 'RankingCriteria{'
        'rankingType: $rankingType, '
        'rankingPeriod: $rankingPeriod, '
        'fundType: $fundType, '
        'company: $company, '
        'sortBy: $sortBy, '
        'page: $page, '
        'pageSize: $pageSize'
        '}';
  }
}

/// 排行榜排序方式枚举
enum RankingSortBy {
  @JsonValue('return_rate')
  returnRate, // 收益率
  @JsonValue('unit_nav')
  unitNav, // 单位净值
  @JsonValue('accumulated_nav')
  accumulatedNav, // 累计净值
  @JsonValue('daily_return')
  dailyReturn, // 日增长率
  @JsonValue('ranking_position')
  rankingPosition, // 排名位置
}

/// 分页排行榜结果
@JsonSerializable()
class PaginatedRankingResult extends Equatable {
  /// 排行榜数据列表
  final List<FundRanking> rankings;

  /// 当前页码
  final int currentPage;

  /// 每页数量
  final int pageSize;

  /// 总数据量
  final int totalCount;

  /// 总页数
  final int totalPages;

  /// 是否有下一页
  final bool hasNextPage;

  /// 是否有上一页
  final bool hasPreviousPage;

  /// 是否有更多数据（兼容性字段）
  final bool hasMore;

  const PaginatedRankingResult({
    required this.rankings,
    required this.currentPage,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
    this.hasMore = false,
  });

  /// 从JSON创建PaginatedRankingResult实例
  factory PaginatedRankingResult.fromJson(Map<String, dynamic> json) =>
      _$PaginatedRankingResultFromJson(json);

  /// 转换为JSON
  Map<String, dynamic> toJson() => _$PaginatedRankingResultToJson(this);

  @override
  List<Object?> get props => [
        rankings,
        currentPage,
        pageSize,
        totalCount,
        totalPages,
        hasNextPage,
        hasPreviousPage,
        hasMore,
      ];

  @override
  String toString() {
    return 'PaginatedRankingResult{'
        'rankings: ${rankings.length}, '
        'currentPage: $currentPage, '
        'totalCount: $totalCount, '
        'totalPages: $totalPages'
        '}';
  }
}
