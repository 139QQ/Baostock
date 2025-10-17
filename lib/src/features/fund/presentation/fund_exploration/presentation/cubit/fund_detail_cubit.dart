import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/data/services/fund_service.dart';
import '../../domain/models/fund_holding.dart';
import '../../domain/models/fund.dart';

part 'fund_detail_state.dart';

/// 基金详情状态管理器
///
/// 负责管理基金详情页面的数据加载和状态
class FundDetailCubit extends Cubit<FundDetailState> {
  final FundService _fundService;

  FundDetailCubit({FundService? fundService})
      : _fundService = fundService ?? FundService(),
        super(const FundDetailState());

  /// 加载基金详情数据
  Future<void> loadFundDetail(String fundCode) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      // 并行加载多个数据源
      final results = await Future.wait([
        _loadFundBasicInfo(fundCode),
        _loadFundNavHistory(fundCode),
        _loadFundRanking(fundCode),
        _loadFundManager(fundCode),
        _loadFundHoldings(fundCode),
        _loadFundEstimate(fundCode),
      ]);

      emit(state.copyWith(
        isLoading: false,
        fund: results[0] as Fund,
        navHistory: results[1] as List<FundNav>,
        fundRanking: results[2] as FundRanking?,
        fundManager: results[3] as FundManager?,
        fundHoldings: results[4] as List<FundHolding>,
        fundEstimate: results[5] as FundEstimate?,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: '加载基金详情失败: ${e.toString()}',
      ));
    }
  }

  /// 加载基金基本信息
  Future<Fund> _loadFundBasicInfo(String fundCode) async {
    try {
      final fundsDto = await _fundService.getFundBasicInfo(
        limit: 1,
        offset: 0,
      );

      if (fundsDto.isNotEmpty) {
        return fundsDto.first.toDomainModel();
      }

      // 返回模拟数据作为后备
      return _getMockFund(fundCode);
    } catch (e) {
      // 返回模拟数据
      return _getMockFund(fundCode);
    }
  }

  /// 加载基金净值历史
  Future<List<FundNav>> _loadFundNavHistory(String fundCode) async {
    try {
      // 根据AKShare文档，fund_open_fund_info_em接口需要fundCode和indicator参数
      final navHistoryDto = await _fundService.getFundNavHistory(
        fundCode: fundCode,
        indicator: '单位净值走势', // 获取单位净值走势
      );

      return navHistoryDto
          .map((dto) => FundNav(
                fundCode: dto.fundCode,
                navDate: dto.navDate,
                unitNav: dto.unitNav,
                accumulatedNav: dto.accumulatedNav,
                dailyReturn: dto.dailyReturn,
                totalNetAssets: dto.totalNetAssets,
                subscriptionStatus: dto.subscriptionStatus,
                redemptionStatus: dto.redemptionStatus,
              ))
          .toList();
    } catch (e) {
      // 返回模拟数据
      return _getMockNavHistory(fundCode);
    }
  }

  /// 加载基金排名
  Future<FundRanking?> _loadFundRanking(String fundCode) async {
    try {
      // 根据AKShare文档，fund_open_fund_rank_em接口需要symbol参数
      // 注意：接口只支持symbol参数，limit需要在客户端处理
      final rankingsDto = await _fundService.getFundRankings(
        symbol: '全部', // 获取全部基金排行
        pageSize: 100, // 客户端分页大小
        timeout: const Duration(seconds: 45), // 设置超时时间
      );

      // 客户端限制返回数量并查找指定基金
      final limitedRankings = rankingsDto.take(100).toList();
      final fundRankingDto = limitedRankings.firstWhere(
        (dto) => dto.fundCode == fundCode,
        orElse: () => limitedRankings.first,
      );

      return fundRankingDto.toDomainModel();
    } catch (e) {
      // 返回模拟排名数据
      return _getMockFundRanking(fundCode);
    }
  }

  /// 加载基金经理信息
  Future<FundManager?> _loadFundManager(String fundCode) async {
    try {
      // 注意：这里需要根据实际业务逻辑获取基金经理代码
      // 暂时使用模拟数据
      return _getMockFundManager(fundCode);
    } catch (e) {
      return _getMockFundManager(fundCode);
    }
  }

  /// 加载基金持仓
  Future<List<FundHolding>> _loadFundHoldings(String fundCode) async {
    try {
      // 暂时返回模拟数据，等待API接口实现
      return _getMockFundHoldings(fundCode);
    } catch (e) {
      // 返回模拟持仓数据
      return _getMockFundHoldings(fundCode);
    }
  }

  /// 加载基金实时估值
  /// 注意：该接口在当前AKShare版本中不存在，使用净值估算数据替代
  Future<FundEstimate?> _loadFundEstimate(String fundCode) async {
    try {
      // 暂时返回模拟数据，等待API接口实现
      return _getMockFundEstimate(fundCode);
    } catch (e) {
      // 返回模拟估值数据
      return _getMockFundEstimate(fundCode);
    }
  }

  /// 切换收藏状态
  void toggleFavorite() {
    if (state.fund != null) {
      final updatedFund = state.fund!.copyWith(
        isFavorite: !state.fund!.isFavorite,
      );
      emit(state.copyWith(fund: updatedFund));
    }
  }

  /// 刷新数据
  Future<void> refreshData() async {
    if (state.fund != null) {
      await loadFundDetail(state.fund!.code);
    }
  }

  // 模拟数据方法
  Fund _getMockFund(String fundCode) {
    return Fund(
      code: fundCode,
      name: '易方达蓝筹精选混合',
      type: '混合型',
      company: '易方达基金',
      manager: '张坤',
      return1Y: 22.34,
      return3Y: 45.67,
      return1M: 8.92,
      return1W: 2.15,
      return3M: 15.67,
      return6M: 28.45,
      returnYTD: 18.76,
      returnSinceInception: 156.78,
      scale: 234.56,
      riskLevel: 'R3',
      status: 'active',
      unitNav: 2.3456,
      accumulatedNav: 2.8456,
      dailyReturn: 1.23,
      establishDate: DateTime(2015, 5, 28),
      managementFee: 1.5,
      custodyFee: 0.25,
      purchaseFee: 1.2,
      redemptionFee: 0.5,
      minimumInvestment: 1000,
      performanceBenchmark: '沪深300指数收益率×80%+中债综合指数收益率×20%',
      investmentTarget: '通过精选具有长期竞争优势的蓝筹股票，追求基金资产的长期稳健增值',
      investmentScope: '具有良好流动性的金融工具，包括股票、债券、货币市场工具等',
      currency: 'CNY',
      listingDate: DateTime(2015, 6, 1),
      isFavorite: false,
    );
  }

  List<FundNav> _getMockNavHistory(String fundCode) {
    final List<FundNav> navHistory = [];
    final now = DateTime.now();

    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: 29 - i));
      final baseNav = 2.3 + i * 0.01;
      final randomChange = (i % 7 - 3) * 0.01;
      final unitNav = baseNav + randomChange;

      navHistory.add(FundNav(
        fundCode: fundCode,
        navDate: date.toIso8601String().split('T')[0],
        unitNav: unitNav,
        accumulatedNav: unitNav + 0.5,
        dailyReturn:
            i > 0 ? ((unitNav - (baseNav - 0.01)) / (baseNav - 0.01)) * 100 : 0,
        totalNetAssets: 234.56,
        subscriptionStatus: '开放',
        redemptionStatus: '开放',
      ));
    }

    return navHistory;
  }

  FundRanking? _getMockFundRanking(String fundCode) {
    return FundRanking(
      fundCode: fundCode,
      fundName: '易方达蓝筹精选混合',
      fundType: '混合型',
      company: '易方达基金',
      rankingPosition: 15,
      totalCount: 1000,
      unitNav: 2.5467,
      accumulatedNav: 2.7832,
      dailyReturn: 0.98,
      return1W: 2.15,
      return1M: 8.92,
      return3M: 15.67,
      return6M: 28.45,
      return1Y: 22.34,
      return2Y: 35.67,
      return3Y: 45.67,
      returnYTD: 18.76,
      returnSinceInception: 156.78,
      date: DateTime.now().toString().substring(0, 10),
      fee: 1.5,
    );
  }

  FundManager? _getMockFundManager(String fundCode) {
    return FundManager(
      managerCode: '001',
      managerName: '张坤',
      avatarUrl: null,
      educationBackground: '清华大学经济学硕士',
      professionalExperience: '拥有15年证券从业经验，专注于消费和制造行业的投资研究',
      manageStartDate: DateTime(2015, 5, 28),
      totalManageDuration: 8,
      currentFundCount: 3,
      totalAssetUnderManagement: 500.0,
      averageReturnRate: 18.5,
      bestFundPerformance: 25.6,
      riskAdjustedReturn: 15.2,
    );
  }

  List<FundHolding> _getMockFundHoldings(String fundCode) {
    return [
      FundHolding(
        fundCode: fundCode,
        reportDate: '2024-06-30',
        holdingType: 'stock',
        stockCode: '000858',
        stockName: '五粮液',
        holdingQuantity: 1000000,
        holdingValue: 150000000,
        holdingPercentage: 9.5,
        marketValue: 150000000,
        sector: '食品饮料',
      ),
      FundHolding(
        fundCode: fundCode,
        reportDate: '2024-06-30',
        holdingType: 'stock',
        stockCode: '000568',
        stockName: '泸州老窖',
        holdingQuantity: 800000,
        holdingValue: 120000000,
        holdingPercentage: 7.6,
        marketValue: 120000000,
        sector: '食品饮料',
      ),
      FundHolding(
        fundCode: fundCode,
        reportDate: '2024-06-30',
        holdingType: 'stock',
        stockCode: '600519',
        stockName: '贵州茅台',
        holdingQuantity: 50000,
        holdingValue: 90000000,
        holdingPercentage: 5.7,
        marketValue: 90000000,
        sector: '食品饮料',
      ),
    ];
  }

  FundEstimate? _getMockFundEstimate(String fundCode) {
    return FundEstimate(
      fundCode: fundCode,
      estimateValue: 2.3478,
      estimateReturn: 0.85,
      estimateTime: '14:30:00',
      previousNav: 2.3278,
      previousNavDate: DateTime.now()
          .subtract(const Duration(days: 1))
          .toString()
          .split(' ')[0],
    );
  }

  @override
  Future<void> close() {
    _fundService.dispose();
    return super.close();
  }
}
