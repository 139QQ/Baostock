import 'package:dio/dio.dart';

/// 使用AKShare官方API端点的网络服务
class ApiService {
  final Dio _dio;

  ApiService(this._dio);

  /// 获取基金基本信息列表
  Future<List<dynamic>> getFundList() async {
    final response = await _dio.get('/api/public/fund_name_em');
    return response.data;
  }

  /// 获取基金排行
  Future<List<dynamic>> getFundRankings(String symbol) async {
    final response = await _dio.get('/api/public/fund_open_fund_rank_em',
        queryParameters: {'symbol': symbol});
    return response.data;
  }

  /// 获取基金实时行情
  Future<List<dynamic>> getFundDaily() async {
    final response = await _dio.get('/api/public/fund_open_fund_daily_em');
    return response.data;
  }

  /// 获取ETF实时行情
  Future<List<dynamic>> getEtfSpot() async {
    final response = await _dio.get('/api/public/fund_etf_spot_em');
    return response.data;
  }

  /// 获取基金申购状态
  Future<List<dynamic>> getFundPurchaseStatus() async {
    final response = await _dio.get('/api/public/fund_purchase_em');
    return response.data;
  }

  /// 获取基金经理信息
  Future<List<dynamic>> getFundManagers() async {
    final response = await _dio.get('/api/public/fund_manager_em');
    return response.data;
  }
}
