import '../../features/fund/shared/services/search_service.dart';
import '../enhanced_fund_search_service.dart';
import '../../features/fund/shared/models/fund_ranking.dart';
import '../../models/fund_info.dart';

/// 统一搜索服务接口
///
/// 整合现有的SearchService和EnhancedFundSearchService，
/// 提供统一的搜索入口和智能路由功能。
abstract class IUnifiedSearchService {
  /// 统一搜索入口
  ///
  /// [query] 搜索查询字符串
  /// [options] 搜索选项，支持基础和增强搜索选项
  /// 返回统一搜索结果，包含基础或增强结果
  Future<UnifiedSearchResult> search(String query,
      {UnifiedSearchOptions? options});

  /// 获取搜索建议
  ///
  /// [prefix] 搜索前缀
  /// [limit] 建议数量限制
  /// 返回搜索建议列表
  Future<List<String>> getSuggestions(String prefix, {int limit = 10});

  /// 构建搜索索引
  ///
  /// [funds] 基金排行榜数据，用于基础搜索
  /// [fundInfos] 基金详细信息，用于增强搜索
  Future<void> buildIndexes(
      {List<FundRanking>? funds, List<FundInfo>? fundInfos});

  /// 清除搜索历史
  void clearSearchHistory();

  /// 清除缓存
  Future<void> clearCache();

  /// 获取搜索统计信息
  Future<UnifiedSearchStatistics> getStatistics();
}

/// 统一搜索选项
///
/// 支持基础搜索选项和增强搜索选项的自动转换
class UnifiedSearchOptions {
  final bool exactMatch;
  final bool useCache;
  final bool cacheResults;
  final double fuzzyThreshold;
  final int limit;
  final String sortBy;
  final String sortOrder;
  final bool enableFuzzy;
  final bool enablePinyin;
  final bool enableBehaviorPreload;
  final bool enableIncrementalLoad;
  final bool useEnhancedFeatures;

  const UnifiedSearchOptions({
    this.exactMatch = false,
    this.useCache = true,
    this.cacheResults = true,
    this.fuzzyThreshold = 0.6,
    this.limit = 100,
    this.sortBy = 'relevance',
    this.sortOrder = 'desc',
    this.enableFuzzy = true,
    this.enablePinyin = true,
    this.enableBehaviorPreload = true,
    this.enableIncrementalLoad = true,
    this.useEnhancedFeatures = false, // 默认使用基础搜索
  });

  /// 创建基础搜索选项
  SearchOptions toBasicSearchOptions() {
    return SearchOptions(
      exactMatch: exactMatch,
      useCache: useCache,
      cacheResults: cacheResults,
      fuzzyThreshold: fuzzyThreshold,
      limit: limit,
      sortBy: _mapToBasicSortBy(sortBy),
    );
  }

  /// 创建增强搜索选项
  EnhancedSearchOptions toEnhancedSearchOptions() {
    return EnhancedSearchOptions(
      maxResults: limit,
      minResults: _calculateMinResults(),
      sortBy: sortBy,
      sortOrder: sortOrder,
      enableFuzzy: enableFuzzy,
      enablePinyin: enablePinyin,
      enableBehaviorPreload: enableBehaviorPreload,
      enableIncrementalLoad: enableIncrementalLoad,
    );
  }

  /// 计算最小结果数量
  int _calculateMinResults() {
    if (limit <= 10) return 3;
    if (limit <= 20) return 5;
    if (limit <= 50) return 10;
    return limit ~/ 5;
  }

  /// 映射排序方式
  SearchSortBy _mapToBasicSortBy(String sortBy) {
    switch (sortBy.toLowerCase()) {
      case 'return1y':
      case 'return_1y':
      case '近1年收益':
        return SearchSortBy.return1Y;
      case 'return3y':
      case 'return_3y':
      case '近3年收益':
        return SearchSortBy.return3Y;
      case 'fundsize':
      case 'fund_size':
      case '基金规模':
        return SearchSortBy.fundSize;
      case 'fundname':
      case 'fund_name':
      case '基金名称':
        return SearchSortBy.fundName;
      case 'fundcode':
      case 'fund_code':
      case '基金代码':
        return SearchSortBy.fundCode;
      case 'relevance':
      case '相关性':
      default:
        return SearchSortBy.relevance;
    }
  }
}

/// 统一搜索结果
///
/// 封装基础搜索结果和增强搜索结果
class UnifiedSearchResult {
  final String query;
  final List<FundRanking> basicResults;
  final List<FundInfo> enhancedResults;
  final int searchTimeMs;
  final int totalFound;
  final bool fromCache;
  final bool useEnhancedEngine;
  final String? error;
  final Map<String, dynamic> metadata;

  const UnifiedSearchResult._({
    required this.query,
    required this.basicResults,
    required this.enhancedResults,
    required this.searchTimeMs,
    required this.totalFound,
    required this.fromCache,
    required this.useEnhancedEngine,
    this.error,
    this.metadata = const {},
  });

  /// 创建基础搜索结果
  factory UnifiedSearchResult.fromBasic(SearchResult result) {
    return UnifiedSearchResult._(
      query: result.query,
      basicResults: result.results,
      enhancedResults: [],
      searchTimeMs: result.searchTime.inMilliseconds,
      totalFound: result.results.length,
      fromCache: result.fromCache,
      useEnhancedEngine: false,
    );
  }

  /// 创建增强搜索结果
  factory UnifiedSearchResult.fromEnhanced(EnhancedSearchResult result) {
    return UnifiedSearchResult._(
      query: result.query,
      basicResults: [],
      enhancedResults: result.funds,
      searchTimeMs: result.searchTimeMs,
      totalFound: result.totalFound,
      fromCache: result.metadata['fromCache'] ?? false,
      useEnhancedEngine: true,
      metadata: result.metadata,
    );
  }

  /// 创建错误结果
  factory UnifiedSearchResult.error({
    required String query,
    required String error,
    int searchTimeMs = 0,
  }) {
    return UnifiedSearchResult._(
      query: query,
      basicResults: [],
      enhancedResults: [],
      searchTimeMs: searchTimeMs,
      totalFound: 0,
      fromCache: false,
      useEnhancedEngine: false,
      error: error,
    );
  }

  /// 获取有效结果（优先返回增强结果）
  List<dynamic> get results =>
      enhancedResults.isNotEmpty ? enhancedResults : basicResults;

  /// 是否成功
  bool get isSuccess => error == null;
}

/// 统一搜索统计信息
class UnifiedSearchStatistics {
  final bool isInitialized;
  final Map<String, dynamic> cacheStats;
  final Map<String, dynamic> searchEngineStats;
  final Map<String, dynamic> preloadingStats;

  const UnifiedSearchStatistics({
    required this.isInitialized,
    required this.cacheStats,
    required this.searchEngineStats,
    required this.preloadingStats,
  });

  factory UnifiedSearchStatistics.empty() {
    return const UnifiedSearchStatistics(
      isInitialized: false,
      cacheStats: {},
      searchEngineStats: {},
      preloadingStats: {},
    );
  }
}
