import '../entities/fund.dart';
import '../entities/fund_filter_criteria.dart';
import '../entities/fund_search_criteria.dart';
import '../entities/fund_ranking.dart';
import '../entities/ranking_statistics.dart';
import '../entities/hot_ranking_type.dart';

abstract class FundRepository {
  Future<List<Fund>> getFundList();
  Future<List<Fund>> getFunds();
  Future<List<Fund>> getFundRankings(String symbol);

  /// 根据排行榜条件获取排行榜数据
  Future<PaginatedRankingResult> getFundRankingsByCriteria(
    RankingCriteria criteria, {
    bool forceRefresh = false,
  });

  /// 获取基金排名历史
  Future<List<FundRanking>> getFundRankingHistory(
    String fundCode,
    RankingPeriod period, {
    int days = 30,
  });

  /// 搜索排行榜
  Future<PaginatedRankingResult> searchRankings(
    String query,
    RankingCriteria criteria,
  );

  /// 获取排行榜统计信息
  Future<RankingStatistics> getRankingStatistics(RankingCriteria criteria);

  /// 获取收藏基金排行榜
  Future<PaginatedRankingResult> getFavoriteFundsRankings(
    List<String> fundCodes,
    RankingCriteria criteria,
  );

  /// 保存收藏基金
  Future<bool> saveFavoriteFunds(Set<String> fundCodes);

  /// 获取收藏基金
  Future<Set<String>> getFavoriteFunds();

  /// 获取热门排行榜类型
  Future<List<HotRankingType>> getHotRankingTypes();

  /// 获取多只基金的排行榜数据用于对比
  Future<List<FundRanking>> getFundsForComparison(
    List<String> fundCodes,
    List<RankingPeriod> periods,
  );

  /// 批量获取基金历史数据
  Future<Map<String, Map<RankingPeriod, FundRanking>>>
      getBatchFundHistoricalData(
    List<String> fundCodes,
    List<RankingPeriod> periods,
  );

  /// 获取基金类型列表
  Future<List<String>> getFundTypes();

  /// 获取基金公司列表
  Future<List<String>> getFundCompanies();

  /// 刷新排行榜缓存
  Future<bool> refreshRankingCache({
    RankingType? rankingType,
    RankingPeriod? period,
  });

  /// 清空排行榜缓存
  Future<void> clearRankingCache();

  /// 获取排行榜更新时间
  Future<DateTime?> getRankingUpdateTime({
    RankingType? rankingType,
    RankingPeriod? period,
  });

  /// 根据筛选条件获取基金列表
  ///
  /// [criteria] 筛选条件，如果为null或空则返回所有基金
  /// 返回符合条件的基金列表
  Future<List<Fund>> getFilteredFunds(FundFilterCriteria criteria);

  /// 获取筛选结果的基金数量
  ///
  /// [criteria] 筛选条件
  /// 返回符合条件的基金总数
  Future<int> getFilteredFundsCount(FundFilterCriteria criteria);

  /// 获取可用的筛选选项
  ///
  /// [type] 筛选类型
  /// 返回该类型的所有可用选项
  Future<List<String>> getFilterOptions(FilterType type);

  // ===== 搜索功能 =====

  /// 根据搜索条件搜索基金
  ///
  /// [criteria] 搜索条件
  /// 返回搜索结果列表
  Future<List<Fund>> searchFunds(FundSearchCriteria criteria);

  /// 获取搜索建议
  ///
  /// [keyword] 搜索关键词
  /// [limit] 建议数量限制
  /// 返回搜索建议列表
  Future<List<String>> getSearchSuggestions(String keyword, {int limit = 10});

  /// 获取搜索历史记录
  ///
  /// [limit] 历史记录数量限制
  /// 返回搜索历史列表
  Future<List<String>> getSearchHistory({int limit = 50});

  /// 保存搜索历史记录
  ///
  /// [keyword] 搜索关键词
  /// 保存成功返回true
  Future<bool> saveSearchHistory(String keyword);

  /// 删除搜索历史记录
  ///
  /// [keyword] 要删除的关键词
  /// 删除成功返回true
  Future<bool> deleteSearchHistory(String keyword);

  /// 清空搜索历史记录
  ///
  /// 清空成功返回true
  Future<bool> clearSearchHistory();

  /// 获取热门搜索关键词
  ///
  /// [limit] 热门关键词数量限制
  /// 返回热门搜索关键词列表
  Future<List<String>> getPopularSearches({int limit = 10});

  /// 预加载搜索缓存
  ///
  /// 预加载常用的搜索结果以提升性能
  Future<void> preloadSearchCache();

  /// 清空搜索缓存
  ///
  /// 清空所有搜索相关的缓存数据
  Future<void> clearSearchCache();

  /// 获取搜索性能统计
  ///
  /// 返回搜索性能统计数据
  Future<Map<String, dynamic>> getSearchStatistics();
}
