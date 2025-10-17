/// 基金数据模型转换工具
///
/// 提供Fund和FundRanking模型之间的相互转换功能
/// 统一数据模型使用FundRanking作为主要数据结构
library fund_converter;

import '../entities/fund.dart';
import '../entities/fund_ranking.dart';

/// Fund模型转换扩展
extension FundToRankingExtension on Fund {
  /// 将Fund对象转换为FundRanking对象
  FundRanking toFundRanking({
    RankingType rankingType = RankingType.overall,
    RankingPeriod rankingPeriod = RankingPeriod.oneYear,
    int? rankingPosition,
    int? totalCount,
    DateTime? rankingDate,
  }) {
    return FundRanking(
      fundCode: code,
      fundName: name,
      fundType: type,
      company: company,
      rankingPosition: rankingPosition ?? this.rankingPosition,
      totalCount: totalCount ?? this.totalCount,
      unitNav: unitNav,
      accumulatedNav: accumulatedNav,
      dailyReturn: dailyReturn,
      return1W: return1W,
      return1M: return1M,
      return3M: return3M,
      return6M: return6M,
      return1Y: return1Y,
      return2Y: return2Y,
      return3Y: return3Y,
      returnYTD: returnYTD,
      returnSinceInception: returnSinceInception,
      rankingDate: rankingDate ?? lastUpdate,
      previousPosition: null, // Fund模型中没有此信息
      positionChange: null, // Fund模型中没有此信息
      rankingType: rankingType,
      rankingPeriod: rankingPeriod,
    );
  }
}

/// FundRanking模型转换扩展
extension FundRankingToFundExtension on FundRanking {
  /// 将FundRanking对象转换为Fund对象
  Fund toFund() {
    return Fund(
      code: fundCode,
      name: fundName,
      type: fundType,
      company: company,
      manager: '', // FundRanking中没有基金经理信息
      unitNav: unitNav,
      accumulatedNav: accumulatedNav,
      dailyReturn: dailyReturn,
      return1W: return1W,
      return1M: return1M,
      return3M: return3M,
      return6M: return6M,
      return1Y: return1Y,
      return2Y: return2Y,
      return3Y: return3Y,
      returnYTD: returnYTD,
      returnSinceInception: returnSinceInception,
      scale: 0.0, // FundRanking中没有规模信息
      riskLevel: '', // FundRanking中没有风险等级信息
      status: 'active',
      date: rankingDate.toIso8601String(),
      fee: 0.0, // FundRanking中没有手续费信息
      rankingPosition: rankingPosition,
      totalCount: totalCount,
      currentPrice: unitNav, // 假设当前价格等于单位净值
      dailyChange: 0.0, // FundRanking中没有此信息
      dailyChangePercent: dailyReturn, // 假设日涨跌幅等于日增长率
      lastUpdate: rankingDate,
    );
  }
}

/// Fund转换工具类
class FundConverter {
  /// 批量将Fund列表转换为FundRanking列表
  static List<FundRanking> convertFundsToRankings(
    List<Fund> funds, {
    RankingType rankingType = RankingType.overall,
    RankingPeriod rankingPeriod = RankingPeriod.oneYear,
    int startRankingPosition = 1,
  }) {
    return funds.map((fund) {
      return fund.toFundRanking(
        rankingType: rankingType,
        rankingPeriod: rankingPeriod,
        rankingPosition: startRankingPosition + funds.indexOf(fund),
        totalCount: funds.length,
      );
    }).toList();
  }

  /// 批量将FundRanking列表转换为Fund列表
  static List<Fund> convertRankingsToFunds(List<FundRanking> rankings) {
    return rankings.map((ranking) => ranking.toFund()).toList();
  }

  /// 从JSON创建Fund对象（兼容性方法）
  static Fund fundFromJson(Map<String, dynamic> json) {
    // 首先尝试作为FundRanking解析
    try {
      final ranking = FundRanking.fromJson(json);
      return ranking.toFund();
    } catch (e) {
      // 如果解析失败，尝试作为Fund解析
      return Fund.fromJson(json);
    }
  }

  /// 将Fund对象转换为JSON（兼容性方法）
  static Map<String, dynamic> fundToJson(Fund fund) {
    // 统一转换为FundRanking格式的JSON
    final ranking = fund.toFundRanking();
    return ranking.toJson();
  }

  /// 检查数据是否为FundRanking格式
  static bool isFundRankingJson(Map<String, dynamic> json) {
    // 检查是否包含FundRanking特有的字段
    return json.containsKey('fundCode') ||
           json.containsKey('fundName') ||
           json.containsKey('rankingPosition') ||
           json.containsKey('rankingType') ||
           json.containsKey('rankingPeriod');
  }

  /// 智能转换：根据JSON格式自动选择转换方式
  static Fund smartFundFromJson(Map<String, dynamic> json) {
    if (isFundRankingJson(json)) {
      final ranking = FundRanking.fromJson(json);
      return ranking.toFund();
    } else {
      return Fund.fromJson(json);
    }
  }

  /// 获取转换统计信息
  static Map<String, dynamic> getConversionStats({
    List<Fund>? funds,
    List<FundRanking>? rankings,
  }) {
    final stats = <String, dynamic>{};

    if (funds != null) {
      stats['fundCount'] = funds.length;
      stats['fundTypeDistribution'] = _getFundTypeDistribution(funds);
      stats['fundCompanyDistribution'] = _getFundCompanyDistribution(funds);
    }

    if (rankings != null) {
      stats['rankingCount'] = rankings.length;
      stats['rankingTypeDistribution'] = _getRankingTypeDistribution(rankings);
      stats['rankingPeriodDistribution'] = _getRankingPeriodDistribution(rankings);
    }

    return stats;
  }

  /// 获取基金类型分布统计
  static Map<String, int> _getFundTypeDistribution(List<Fund> funds) {
    final distribution = <String, int>{};
    for (final fund in funds) {
      distribution[fund.type] = (distribution[fund.type] ?? 0) + 1;
    }
    return distribution;
  }

  /// 获取基金公司分布统计
  static Map<String, int> _getFundCompanyDistribution(List<Fund> funds) {
    final distribution = <String, int>{};
    for (final fund in funds) {
      distribution[fund.company] = (distribution[fund.company] ?? 0) + 1;
    }
    return distribution;
  }

  /// 获取排行榜类型分布统计
  static Map<String, int> _getRankingTypeDistribution(List<FundRanking> rankings) {
    final distribution = <String, int>{};
    for (final ranking in rankings) {
      distribution[ranking.rankingType.name] = (distribution[ranking.rankingType.name] ?? 0) + 1;
    }
    return distribution;
  }

  /// 获取排行榜时间段分布统计
  static Map<String, int> _getRankingPeriodDistribution(List<FundRanking> rankings) {
    final distribution = <String, int>{};
    for (final ranking in rankings) {
      distribution[ranking.rankingPeriod.name] = (distribution[ranking.rankingPeriod.name] ?? 0) + 1;
    }
    return distribution;
  }

  /// 数据验证：检查转换后的数据完整性
  static Map<String, dynamic> validateConversion(Fund original, FundRanking converted) {
    final validation = <String, dynamic>{
      'isValid': true,
      'errors': <String>[],
      'warnings': <String>[],
    };

    // 检查关键字段是否匹配
    if (original.code != converted.fundCode) {
      validation['errors'].add('基金代码不匹配: ${original.code} -> ${converted.fundCode}');
      validation['isValid'] = false;
    }

    if (original.name != converted.fundName) {
      validation['errors'].add('基金名称不匹配: ${original.name} -> ${converted.fundName}');
      validation['isValid'] = false;
    }

    // 检查数值字段的精度
    if ((original.unitNav - converted.unitNav).abs() > 0.0001) {
      validation['warnings'].add('单位净值精度差异: ${original.unitNav} -> ${converted.unitNav}');
    }

    if ((original.dailyReturn - converted.dailyReturn).abs() > 0.0001) {
      validation['warnings'].add('日收益率精度差异: ${original.dailyReturn} -> ${converted.dailyReturn}');
    }

    // 检查是否有数据丢失
    if (original.manager.isNotEmpty) {
      validation['warnings'].add('基金经理信息丢失: ${original.manager}');
    }

    if (original.scale > 0) {
      validation['warnings'].add('基金规模信息丢失: ${original.scale}');
    }

    return validation;
  }
}