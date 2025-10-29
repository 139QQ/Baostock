import '../models/fund_ranking.dart';
import '../../presentation/fund_exploration/domain/models/fund.dart'
    as exploration_fund;

/// FundRanking 到 Fund 的转换扩展
extension FundRankingToFundExtension on FundRanking {
  /// 转换为 Fund 模型
  exploration_fund.Fund toFund() {
    return exploration_fund.Fund(
      code: fundCode,
      name: fundName,
      type: shortType,
      company: fundCompany,
      manager: '--', // FundRanking 中没有此信息
      return1W: 0.0, // FundRanking 中没有此信息
      return1M: 0.0, // FundRanking 中没有此信息
      return3M: 0.0, // FundRanking 中没有此信息
      return6M: 0.0, // FundRanking 中没有此信息
      return1Y: oneYearReturn,
      return3Y: threeYearReturn,
      returnYTD: null, // FundRanking 中没有此信息
      returnSinceInception: null, // FundRanking 中没有此信息
      scale: fundSize,
      riskLevel: getRiskLevel().displayName,
      status: '--', // FundRanking 中没有此信息
      unitNav: null, // FundRanking 中没有此信息
      accumulatedNav: null, // FundRanking 中没有此信息
      dailyReturn: dailyReturn,
      establishDate: null, // FundRanking 中没有此信息
      managementFee: null, // FundRanking 中没有此信息
      custodyFee: null, // FundRanking 中没有此信息
      purchaseFee: null, // FundRanking 中没有此信息
      redemptionFee: null, // FundRanking 中没有此信息
      minimumInvestment: null, // FundRanking 中没有此信息
      performanceBenchmark: null, // FundRanking 中没有此信息
    );
  }
}

/// FundRanking 列表转换扩展
extension FundRankingListExtension on List<FundRanking> {
  /// 转换为 Fund 列表
  List<exploration_fund.Fund> toFundList() {
    return map((ranking) => ranking.toFund()).toList();
  }
}
