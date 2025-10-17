import '../../../../core/network/fund_api_client.dart';
import '../../presentation/fund_exploration/domain/models/fund.dart'
    as exploration_fund;
import '../../domain/entities/fund.dart';

abstract class FundRemoteDataSource {
  Future<List<Fund>> getFundList();
  Future<List<Fund>> getFundRankings(String symbol);
}

class FundRemoteDataSourceImpl implements FundRemoteDataSource {
  final FundApiClient apiClient;

  FundRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<Fund>> getFundList() async {
    try {
      final response = await apiClient.getFundList();
      return response
          .map((json) =>
              _convertToFundEntity(exploration_fund.Fund.fromJson(json)))
          .toList();
    } catch (e) {
      throw Exception('获取基金列表失败: $e');
    }
  }

  @override
  Future<List<Fund>> getFundRankings(String symbol) async {
    try {
      final response = await apiClient.getFundRankings(symbol: symbol);
      return response
          .map((json) =>
              _convertToFundEntity(exploration_fund.Fund.fromJson(json)))
          .toList();
    } catch (e) {
      throw Exception('获取基金排名失败: $e');
    }
  }

  /// 将exploration模块的Fund转换为fund模块的Fund实体
  Fund _convertToFundEntity(exploration_fund.Fund explorationFund) {
    return Fund(
      code: explorationFund.code,
      name: explorationFund.name,
      type: explorationFund.type,
      company: explorationFund.company,
      manager: explorationFund.manager,
      unitNav: explorationFund.unitNav ?? 0.0,
      accumulatedNav: explorationFund.accumulatedNav ?? 0.0,
      dailyReturn: explorationFund.dailyReturn ?? 0.0,
      return1W: explorationFund.return1W,
      return1M: explorationFund.return1M,
      return3M: explorationFund.return3M,
      return6M: explorationFund.return6M,
      return1Y: explorationFund.return1Y,
      return2Y: 0.0, // explorationFund模型中没有此字段
      return3Y: explorationFund.return3Y,
      returnYTD: explorationFund.returnYTD ?? 0.0,
      returnSinceInception: explorationFund.returnSinceInception ?? 0.0,
      scale: explorationFund.scale,
      riskLevel: explorationFund.riskLevel,
      status: explorationFund.status,
      date: '', // explorationFund模型中没有此字段
      fee: 0.0, // explorationFund模型中没有此字段
      rankingPosition: 0, // explorationFund模型中没有此字段
      totalCount: 0, // explorationFund模型中没有此字段
      currentPrice: 0.0, // explorationFund模型中没有此字段
      dailyChange: 0.0, // explorationFund模型中没有此字段
      dailyChangePercent: 0.0, // explorationFund模型中没有此字段
      lastUpdate: DateTime.now(),
    );
  }
}
