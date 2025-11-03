import 'dart:async';
import 'package:logger/logger.dart';

import 'i_unified_search_service.dart';
import '../../features/fund/shared/services/search_service.dart';
import '../enhanced_fund_search_service.dart';
import '../../features/fund/shared/models/fund_ranking.dart';
import '../../models/fund_info.dart';

/// 统一搜索服务实现
///
/// 智能整合现有的SearchService和EnhancedFundSearchService，
/// 根据查询复杂度和选项自动选择最适合的搜索引擎。
class UnifiedSearchService implements IUnifiedSearchService {
  static final UnifiedSearchService _instance =
      UnifiedSearchService._internal();
  factory UnifiedSearchService() => _instance;
  UnifiedSearchService._internal();

  final Logger _logger = Logger();

  // 核心服务组件
  late final SearchService _basicSearchService;
  late final EnhancedFundSearchService _enhancedSearchService;

  // 服务状态
  bool _isInitialized = false;
  bool _hasBasicData = false;
  bool _hasEnhancedData = false;

  /// 初始化统一搜索服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.i('🚀 初始化统一搜索服务...');

      // 初始化核心服务
      _basicSearchService = SearchService();
      _enhancedSearchService = EnhancedFundSearchService();

      // 初始化增强搜索服务
      await _enhancedSearchService.initialize();

      _isInitialized = true;
      _logger.i('✅ 统一搜索服务初始化完成');
    } catch (e, stackTrace) {
      _logger.e('❌ 统一搜索服务初始化失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<UnifiedSearchResult> search(String query,
      {UnifiedSearchOptions? options}) async {
    if (!_isInitialized) {
      await initialize();
    }

    final searchOptions = options ?? const UnifiedSearchOptions();
    final stopwatch = Stopwatch()..start();

    try {
      _logger.d(
          '🔍 执行统一搜索: "$query" (增强功能: ${searchOptions.useEnhancedFeatures})');

      // 智能路由：根据查询复杂度和服务可用性选择搜索引擎
      if (_shouldUseEnhancedSearch(query, searchOptions)) {
        return await _performEnhancedSearch(query, searchOptions);
      } else {
        return await _performBasicSearch(query, searchOptions);
      }
    } catch (e, stackTrace) {
      _logger.e('❌ 搜索失败: "$query"', error: e, stackTrace: stackTrace);
      return UnifiedSearchResult.error(
        query: query,
        error: e.toString(),
        searchTimeMs: stopwatch.elapsedMilliseconds,
      );
    } finally {
      stopwatch.stop();
    }
  }

  @override
  Future<List<String>> getSuggestions(String prefix, {int limit = 10}) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // 优先使用增强搜索服务的建议功能
      if (_hasEnhancedData) {
        return await _enhancedSearchService.getSmartSearchSuggestions(
          prefix,
          maxSuggestions: limit,
        );
      } else {
        // 回退到基础搜索服务的建议功能
        // SearchService有getSearchSuggestions方法（同步方法）
        return _basicSearchService.getSearchSuggestions(prefix, limit: limit);
      }
    } catch (e) {
      _logger.w('⚠️ 获取搜索建议失败: $e');
      return [];
    }
  }

  @override
  Future<void> buildIndexes(
      {List<FundRanking>? funds, List<FundInfo>? fundInfos}) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      _logger.i('📚 构建搜索索引...');

      // 构建基础搜索索引
      if (funds != null && funds.isNotEmpty) {
        _logger.d('构建基础搜索索引 (${funds.length}条数据)');
        _basicSearchService.buildIndex(funds);
        _hasBasicData = true;
      }

      // 构建增强搜索索引
      if (fundInfos != null && fundInfos.isNotEmpty) {
        _logger.d('构建增强搜索索引 (${fundInfos.length}条数据)');
        // EnhancedFundSearchService通过refreshFundData来重建索引
        // 它会自动从数据源获取FundInfo数据并构建索引
        await _enhancedSearchService.refreshFundData(forceRefresh: true);
        _hasEnhancedData = true;
      }

      _logger.i('✅ 搜索索引构建完成');
      _logger.d('索引状态: 基础搜索=$_hasBasicData, 增强搜索=$_hasEnhancedData');
    } catch (e, stackTrace) {
      _logger.e('❌ 搜索索引构建失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  void clearSearchHistory() {
    try {
      _basicSearchService.clearSearchHistory();
      _logger.d('🗑️ 搜索历史已清除');
    } catch (e) {
      _logger.w('⚠️ 清除搜索历史失败: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await Future.wait([
        Future(() => _basicSearchService.clearCache()),
        _enhancedSearchService.clearAllData(),
      ]);
      _logger.d('🗑️ 搜索缓存已清除');
    } catch (e) {
      _logger.w('⚠️ 清除搜索缓存失败: $e');
    }
  }

  @override
  Future<UnifiedSearchStatistics> getStatistics() async {
    try {
      final enhancedStats =
          await _enhancedSearchService.getEnhancedPerformanceReport();

      return UnifiedSearchStatistics(
        isInitialized: _isInitialized,
        cacheStats: {
          'memoryCacheSize':
              enhancedStats.statistics.cacheStats.memoryCacheSize,
          'lastUpdateTime': enhancedStats.statistics.cacheStats.lastUpdateTime
              .toIso8601String(),
          'hotQueriesCount':
              enhancedStats.statistics.cacheStats.hotQueriesCount,
          'queryFrequencyCount':
              enhancedStats.statistics.cacheStats.queryFrequencyCount,
          'isInitialized': enhancedStats.statistics.cacheStats.isInitialized,
        },
        searchEngineStats: {
          'totalFunds': enhancedStats.statistics.searchEngineStats.totalFunds,
          'hashTableSize':
              enhancedStats.statistics.searchEngineStats.hashTableSize,
          'prefixTreeNodes':
              enhancedStats.statistics.searchEngineStats.prefixTreeNodes,
          'invertedIndexEntries':
              enhancedStats.statistics.searchEngineStats.invertedIndexEntries,
          'memoryEstimateMB':
              enhancedStats.statistics.searchEngineStats.memoryEstimateMB,
          'isBuilt': enhancedStats.statistics.searchEngineStats.isBuilt,
        },
        preloadingStats: {
          'isRunning': enhancedStats.statistics.preloadingStats.isRunning,
          'totalActiveTasks':
              enhancedStats.statistics.preloadingStats.totalActiveTasks,
          'completedTasks':
              enhancedStats.statistics.preloadingStats.completedTasks,
          'failedTasks': enhancedStats.statistics.preloadingStats.failedTasks,
          'memoryCacheSize':
              enhancedStats.statistics.preloadingStats.memoryCacheSize,
          'memoryUsageMB':
              enhancedStats.statistics.preloadingStats.memoryUsageMB,
          'lruQueueSize': enhancedStats.statistics.preloadingStats.lruQueueSize,
        },
      );
    } catch (e) {
      _logger.w('⚠️ 获取搜索统计信息失败: $e');
      return UnifiedSearchStatistics.empty();
    }
  }

  /// 判断是否应该使用增强搜索
  bool _shouldUseEnhancedSearch(String query, UnifiedSearchOptions options) {
    // 如果明确要求使用增强功能
    if (options.useEnhancedFeatures) {
      return _hasEnhancedData;
    }

    // 如果增强服务不可用，使用基础搜索
    if (!_hasEnhancedData) {
      return false;
    }

    // 智能判断：复杂查询使用增强搜索
    return _isComplexQuery(query, options);
  }

  /// 判断查询复杂度
  bool _isComplexQuery(String query, UnifiedSearchOptions options) {
    // 1. 明确要求使用增强功能
    if (options.useEnhancedFeatures) {
      _logger.d('🎯 智能路由: 用户明确要求增强功能');
      return true;
    }

    // 2. 查询长度判断
    if (query.length > 15) {
      _logger.d('🎯 智能路由: 长查询使用增强搜索 (${query.length}字符)');
      return true;
    }

    // 3. 多词查询判断（包含空格或特殊分隔符）
    if (query.contains(' ') || query.contains(',') || query.contains('，')) {
      _logger.d('🎯 智能路由: 多词查询使用增强搜索');
      return true;
    }

    // 4. 特殊字符判断
    if (RegExp(r'[^\w\u4e00-\u9fff]').hasMatch(query)) {
      _logger.d('🎯 智能路由: 包含特殊字符使用增强搜索');
      return true;
    }

    // 5. 基金代码精确匹配判断（6位数字）
    if (RegExp(r'^\d{6}$').hasMatch(query)) {
      _logger.d('🎯 智能路由: 基金代码精确匹配使用基础搜索');
      return false;
    }

    // 6. 基金类型关键词判断
    final fundTypeKeywords = [
      '股票',
      '债券',
      '混合',
      '货币',
      '指数',
      'qdii',
      'etf',
      'lof'
    ];
    if (fundTypeKeywords.any(
        (keyword) => query.toLowerCase().contains(keyword.toLowerCase()))) {
      _logger.d('🎯 智能路由: 包含基金类型关键词使用增强搜索');
      return true;
    }

    // 7. 投资策略关键词判断
    final strategyKeywords = ['价值', '成长', '平衡', '稳健', '激进', '保本', '定投'];
    if (strategyKeywords.any(
        (keyword) => query.toLowerCase().contains(keyword.toLowerCase()))) {
      _logger.d('🎯 智能路由: 包含投资策略关键词使用增强搜索');
      return true;
    }

    // 8. 增强功能选项判断
    if (options.enableBehaviorPreload || options.enableIncrementalLoad) {
      _logger.d('🎯 智能路由: 启用了增强功能选项');
      return true;
    }

    // 9. 模糊搜索阈值判断
    if (options.fuzzyThreshold < 0.8) {
      _logger.d('🎯 智能路由: 低模糊阈值使用增强搜索');
      return true;
    }

    // 10. 查询结果数量要求判断
    if (options.limit > 50) {
      _logger.d('🎯 智能路由: 大量结果要求使用增强搜索');
      return true;
    }

    // 默认使用基础搜索
    _logger.d('🎯 智能路由: 默认使用基础搜索');
    return false;
  }

  /// 执行基础搜索
  Future<UnifiedSearchResult> _performBasicSearch(
      String query, UnifiedSearchOptions options) async {
    final result = await _basicSearchService.search(
      query,
      options: options.toBasicSearchOptions(),
    );

    _logger.d(
        '📊 基础搜索完成: ${result.results.length}个结果 (${result.searchTime.inMilliseconds}ms)');

    return UnifiedSearchResult.fromBasic(result);
  }

  /// 执行增强搜索
  Future<UnifiedSearchResult> _performEnhancedSearch(
      String query, UnifiedSearchOptions options) async {
    final result = await _enhancedSearchService.searchFunds(
      query,
      options: options.toEnhancedSearchOptions(),
    );

    _logger
        .d('📊 增强搜索完成: ${result.funds.length}个结果 (${result.searchTimeMs}ms)');

    return UnifiedSearchResult.fromEnhanced(result);
  }

  /// 服务健康检查
  Future<bool> healthCheck() async {
    try {
      await getStatistics();
      return _isInitialized && (_hasBasicData || _hasEnhancedData);
    } catch (e) {
      _logger.e('❌ 服务健康检查失败: $e');
      return false;
    }
  }

  /// 获取服务配置信息
  Map<String, dynamic> getServiceConfig() {
    return {
      'isInitialized': _isInitialized,
      'hasBasicData': _hasBasicData,
      'hasEnhancedData': _hasEnhancedData,
      'services': {
        'basicSearch': 'SearchService',
        'enhancedSearch': 'EnhancedFundSearchService',
      },
    };
  }
}
