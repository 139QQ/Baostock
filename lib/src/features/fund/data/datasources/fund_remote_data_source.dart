import '../../../../core/network/fund_api_client.dart';
import 'dart:io';
import 'dart:async';
import '../../presentation/fund_exploration/domain/models/fund.dart'
    as exploration_fund;
import '../../domain/entities/fund.dart';

abstract class FundRemoteDataSource {
  Future<List<Fund>> getFundList();
  Future<List<Fund>> getFundRankings(String symbol,
      {bool forceRefresh = false});
}

class FundRemoteDataSourceImpl implements FundRemoteDataSource {
  final FundApiClient apiClient;

  FundRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<Fund>> getFundList() async {
    try {
      final response = await FundApiClient.searchFunds('', limit: 100);
      final dataList = response['data'] as List<dynamic>? ?? [];
      return dataList
          .map((json) =>
              _convertToFundEntity(exploration_fund.Fund.fromJson(json)))
          .toList();
    } catch (e) {
      throw Exception('获取基金列表失败: $e');
    }
  }

  @override
  Future<List<Fund>> getFundRankings(String symbol,
      {bool forceRefresh = false}) async {
    try {
      final response = await FundApiClient.getFundRanking(symbol: "全部");
      final dataList = response['data'] as List<dynamic>? ?? [];
      return dataList
          .map((json) =>
              _convertToFundEntity(exploration_fund.Fund.fromJson(json)))
          .toList();
    } catch (e) {
      // 根据错误类型提供更详细的错误信息
      if (e is ArgumentError) {
        throw Exception('请求参数错误: ${e.message}');
      } else if (e is SocketException) {
        throw Exception('网络连接失败，请检查网络设置');
      } else if (e is TimeoutException) {
        throw Exception('请求超时，请检查网络连接后重试');
      } else if (e is HttpException) {
        throw Exception('HTTP请求失败: ${e.message}');
      } else {
        throw Exception('获取基金排名失败: $e');
      }
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
