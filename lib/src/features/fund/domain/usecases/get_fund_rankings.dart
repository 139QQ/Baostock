import '../entities/fund_ranking.dart';
import '../entities/ranking_statistics.dart';
import '../repositories/fund_repository.dart';

/// 获取基金排行榜用例
///
/// 负责处理基金排行榜相关的业务逻辑，包括：
/// - 根据条件获取排行榜数据
/// - 支持多种排序和筛选条件
/// - 缓存管理和性能优化
class GetFundRankings {
  final FundRepository _repository;

  GetFundRankings(this._repository);

  /// 执行获取基金排行榜操作
  ///
  /// [criteria] 排行榜查询条件
  /// [forceRefresh] 是否强制刷新缓存
  ///
  /// 返回分页的排行榜结果
  Future<PaginatedRankingResult> call(
    RankingCriteria criteria, {
    bool forceRefresh = false,
  }) async {
    try {
      // 获取排行榜数据
      final result = await _repository.getFundRankingsByCriteria(
        criteria,
        forceRefresh: forceRefresh,
      );

      return result;
    } catch (e) {
      throw GetFundRankingsException(
        '获取基金排行榜失败: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// 获取指定基金的排名历史
  ///
  /// [fundCode] 基金代码
  /// [period] 时间段
  /// [days] 获取天数
  Future<List<FundRanking>> getFundRankingHistory(
    String fundCode,
    RankingPeriod period, {
    int days = 30,
  }) async {
    try {
      return await _repository.getFundRankingHistory(
        fundCode,
        period,
        days: days,
      );
    } catch (e) {
      throw GetFundRankingsException(
        '获取基金排名历史失败: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// 获取热门排行榜（预定义的排行榜组合）
  ///
  /// [type] 热门排行榜类型
  Future<PaginatedRankingResult> getHotRankings(
    HotRankingType type, {
    int pageSize = 10,
  }) async {
    try {
      switch (type) {
        case HotRankingType.topGainers:
          // 收益率最高的基金
          return await call(
            RankingCriteria(
              rankingType: RankingType.overall,
              rankingPeriod: RankingPeriod.oneYear,
              sortBy: RankingSortBy.returnRate,
              page: 1,
              pageSize: pageSize,
            ),
          );
        case HotRankingType.topVolume:
          // 规模最大的基金
          return await call(
            RankingCriteria(
              rankingType: RankingType.overall,
              rankingPeriod: RankingPeriod.oneYear,
              sortBy: RankingSortBy.accumulatedNav,
              page: 1,
              pageSize: pageSize,
            ),
          );
        case HotRankingType.stockFunds:
          // 股票型基金排行
          return await call(
            RankingCriteria(
              rankingType: RankingType.byType,
              rankingPeriod: RankingPeriod.oneYear,
              fundType: '股票型',
              sortBy: RankingSortBy.returnRate,
              page: 1,
              pageSize: pageSize,
            ),
          );
        case HotRankingType.bondFunds:
          // 债券型基金排行
          return await call(
            RankingCriteria(
              rankingType: RankingType.byType,
              rankingPeriod: RankingPeriod.oneYear,
              fundType: '债券型',
              sortBy: RankingSortBy.returnRate,
              page: 1,
              pageSize: pageSize,
            ),
          );
        case HotRankingType.hybridFunds:
          // 混合型基金排行
          return await call(
            RankingCriteria(
              rankingType: RankingType.byType,
              rankingPeriod: RankingPeriod.oneYear,
              fundType: '混合型',
              sortBy: RankingSortBy.returnRate,
              page: 1,
              pageSize: pageSize,
            ),
          );
        case HotRankingType.moneyMarketFunds:
          // 货币型基金排行
          return await call(
            RankingCriteria(
              rankingType: RankingType.byType,
              rankingPeriod: RankingPeriod.oneYear,
              fundType: '货币型',
              sortBy: RankingSortBy.returnRate,
              page: 1,
              pageSize: pageSize,
            ),
          );
      }
    } catch (e) {
      throw GetFundRankingsException(
        '获取热门排行榜失败: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// 搜索排行榜中的基金
  ///
  /// [query] 搜索关键词
  /// [criteria] 基础查询条件
  Future<PaginatedRankingResult> searchRankings(
    String query,
    RankingCriteria criteria,
  ) async {
    try {
      return await _repository.searchRankings(query, criteria);
    } catch (e) {
      throw GetFundRankingsException(
        '搜索排行榜失败: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// 获取排行榜统计信息
  ///
  /// [criteria] 查询条件
  Future<RankingStatistics> getRankingStatistics(
    RankingCriteria criteria,
  ) async {
    try {
      return await _repository.getRankingStatistics(criteria);
    } catch (e) {
      throw GetFundRankingsException(
        '获取排行榜统计信息失败: ${e.toString()}',
        originalError: e,
      );
    }
  }
}

/// 热门排行榜类型
enum HotRankingType {
  topGainers, // 收益榜
  topVolume, // 规模榜
  stockFunds, // 股票型基金榜
  bondFunds, // 债券型基金榜
  hybridFunds, // 混合型基金榜
  moneyMarketFunds, // 货币型基金榜
}

/// 获取基金排行榜异常
class GetFundRankingsException implements Exception {
  final String message;
  final Object? originalError;

  GetFundRankingsException(this.message, {this.originalError});

  @override
  String toString() => 'GetFundRankingsException: $message';
}
