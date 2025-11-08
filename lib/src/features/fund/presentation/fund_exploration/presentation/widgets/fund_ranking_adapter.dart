import '../../../../../../features/fund/domain/entities/fund_ranking.dart';
import '../../../../../../features/fund/domain/entities/fund.dart';

/// FundRanking 到 Fund 的适配器
/// 将现有的排行榜数据转换为新的基金卡片组件所需的数据格式
class FundRankingAdapter {
  /// 将 FundRanking 列表转换为 Fund 列表
  static List<Fund> adaptList(List<FundRanking> rankings) {
    return rankings.map((ranking) => adaptSingle(ranking)).toList();
  }

  /// 将单个 FundRanking 转换为 Fund
  static Fund adaptSingle(FundRanking ranking) {
    return Fund(
      code: ranking.fundCode,
      name: ranking.fundName,
      type: ranking.fundType,
      company: ranking.company,
      manager: '未知', // FundRanking 中没有这个数据
      unitNav: ranking.unitNav,
      accumulatedNav: ranking.accumulatedNav,
      dailyReturn: ranking.dailyReturn,
      return1W: ranking.return1W,
      return1M: ranking.return1M,
      return3M: ranking.return3M,
      return1Y: ranking.return1Y,
      return2Y: ranking.return2Y,
      return3Y: ranking.return3Y,
      returnYTD: ranking.returnYTD,
      returnSinceInception: ranking.returnSinceInception,
      scale: 0.0, // FundRanking 中没有这个数据
      riskLevel: '中', // FundRanking 中没有这个数据
      status: 'active',
      date: ranking.rankingDate.toString().substring(0, 10),
      fee: 0.0, // FundRanking 中没有这个数据
      rankingPosition: ranking.rankingPosition,
      totalCount: ranking.totalCount,
      currentPrice: ranking.unitNav,
      dailyChange: 0.0, // FundRanking 中没有这个数据
      dailyChangePercent: ranking.dailyReturn,
      lastUpdate: ranking.rankingDate,
    );
  }

  /// 映射风险等级
  static String _mapRiskLevel(String? riskLevel) {
    if (riskLevel == null || riskLevel.isEmpty) return '中';

    switch (riskLevel.toLowerCase()) {
      case '低':
      case '低风险':
        return '低';
      case '中低':
      case '中低风险':
        return '中低';
      case '中':
      case '中风险':
        return '中';
      case '中高':
      case '中高风险':
        return '中高';
      case '高':
      case '高风险':
        return '高';
      default:
        return '中';
    }
  }

  /// 格式化基金规模
  static String _formatScale(double? scale) {
    if (scale == null || scale <= 0) return '规模未知';

    if (scale >= 10000) {
      return '${(scale / 10000).toStringAsFixed(2)}万亿元';
    } else if (scale >= 1000) {
      return '${(scale / 1000).toStringAsFixed(2)}千亿元';
    } else {
      return '${scale.toStringAsFixed(2)}亿元';
    }
  }

  /// 格式化日期
  static String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '未知';

    try {
      // 尝试解析各种日期格式
      if (dateStr.length == 8) {
        // YYYYMMDD 格式
        return '${dateStr.substring(0, 4)}-${dateStr.substring(4, 6)}-${dateStr.substring(6, 8)}';
      } else if (dateStr.contains('-')) {
        // 已经是标准格式
        return dateStr.substring(0, 10);
      } else {
        // 其他格式，返回原始值
        return dateStr;
      }
    } catch (e) {
      return dateStr;
    }
  }

  /// 获取基金类型的简短显示
  static String getShortType(String? fundType) {
    if (fundType == null || fundType.isEmpty) return '未知';

    // 提取关键词
    if (fundType.contains('股票')) return '股票型';
    if (fundType.contains('债券')) return '债券型';
    if (fundType.contains('混合')) return '混合型';
    if (fundType.contains('货币')) return '货币型';
    if (fundType.contains('指数')) return '指数型';
    if (fundType.contains('QDII')) return 'QDII';
    if (fundType.contains('FOF')) return 'FOF';

    return fundType.length > 8 ? fundType.substring(0, 8) : fundType;
  }

  /// 计算综合评分 (基于收益率和风险等级)
  static double calculateScore(FundRanking ranking) {
    double score = 50.0; // 基础分

    // 收益率评分 (40%权重)
    score += ranking.return1Y * 0.4;

    // 日收益评分 (20%权重)
    score += ranking.dailyReturn * 2.0; // 放大日收益影响

    // 基金规模调整 (10%权重) - FundRanking 中没有 scale 数据，跳过

    // 类型调整 (10%权重)
    if (ranking.fundType.contains('混合')) {
      score += 3; // 混合型基金风险收益平衡较好
    }

    return score.clamp(0.0, 100.0);
  }

  /// 判断是否为热门基金 (基于收益率和规模)
  static bool isHotFund(FundRanking ranking) {
    // 年化收益率超过8% 且 日收益为正
    if (ranking.return1Y > 8.0 && ranking.dailyReturn > 0) {
      return true;
    }

    // 近期表现优异 (月收益超过5%)
    if (ranking.return1M > 5.0) {
      return true;
    }

    return false;
  }

  /// 获取推荐标签
  static List<String> getRecommendationTags(FundRanking ranking) {
    List<String> tags = [];

    if (ranking.return1Y > 10.0) {
      tags.add('高收益');
    }

    if (ranking.dailyReturn > 1.0) {
      tags.add('今日热门');
    }

    if (ranking.fundType.contains('混合')) {
      tags.add('均衡配置');
    }

    return tags.take(3).toList(); // 最多显示3个标签
  }
}
