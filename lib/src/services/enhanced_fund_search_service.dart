import 'dart:async';
import 'package:logger/logger.dart';
import 'multi_index_search_engine.dart';
import 'intelligent_cache_manager.dart';
import 'search_performance_optimizer.dart';
import 'smart_preloading_manager.dart';
import '../models/fund_info.dart';

/// 增强基金搜索服务
///
/// 整合多索引搜索引擎、智能缓存管理器、性能优化器和智能预加载管理器，
/// 提供完整的智能搜索体验。
///
/// 核心特性：
/// 1. 4级智能预加载策略
/// 2. 多索引组合搜索
/// 3. 智能缓存管理
/// 4. 实时性能监控
/// 5. LRU内存管理
/// 6. 增量数据加载
class EnhancedFundSearchService {
  static final EnhancedFundSearchService _instance =
      EnhancedFundSearchService._internal();
  factory EnhancedFundSearchService() => _instance;
  EnhancedFundSearchService._internal();

  final Logger _logger = Logger();

  // 核心服务组件
  late final MultiIndexSearchEngine _searchEngine;
  late final IntelligentCacheManager _cacheManager;
  late final SearchPerformanceOptimizer _performanceOptimizer;
  late final SmartPreloadingManager _preloadingManager;

  // 服务状态
  bool _isInitialized = false;

  /// 初始化增强搜索服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.i('🚀 初始化增强基金搜索服务...');

      // 初始化核心组件
      _searchEngine = MultiIndexSearchEngine();
      _cacheManager = IntelligentCacheManager();
      _performanceOptimizer = SearchPerformanceOptimizer();
      _preloadingManager = SmartPreloadingManager();

      // 初始化各个组件
      await _cacheManager.initialize();
      await _preloadingManager.initialize();

      // 启动性能监控
      await _performanceOptimizer.startMonitoring();

      _isInitialized = true;
      _logger.i('✅ 增强基金搜索服务初始化完成');
      _logServiceStatus();
    } catch (e) {
      _logger.e('❌ 增强基金搜索服务初始化失败: $e');
      rethrow;
    }
  }

  /// 智能搜索（主要接口）
  Future<EnhancedSearchResult> searchFunds(String query,
      {EnhancedSearchOptions? options}) async {
    if (!_isInitialized) {
      await initialize();
    }

    final searchOptions = options ?? const EnhancedSearchOptions();
    final stopwatch = Stopwatch()..start();

    try {
      // 记录搜索行为（用于智能预加载）
      _recordSearchBehavior(query);

      // 执行搜索
      SearchResult result;

      // 优先使用多索引搜索引擎
      if (_searchEngine.getIndexStats().isBuilt) {
        result = _searchEngine.search(query,
            options: searchOptions.toSearchOptions());
      } else {
        // 降级到缓存管理器搜索
        final funds = await _cacheManager.searchFunds(query,
            limit: searchOptions.maxResults);
        result = SearchResult(
          query: query,
          funds: funds,
          searchTimeMs: stopwatch.elapsedMilliseconds,
          totalFound: funds.length,
          indexUsed: 'cache_manager_fallback',
        );
      }

      // 检查是否需要触发关联数据预加载
      if (searchOptions.enableBehaviorPreload && result.funds.isNotEmpty) {
        final topFund = result.funds.first;
        unawaited(_preloadingManager.triggerBehaviorPreload(topFund.code));
      }

      // 包装为增强搜索结果
      final enhancedResult = EnhancedSearchResult.fromSearchResult(result);

      stopwatch.stop();
      _logger.d(
          '🔍 智能搜索完成: "$query" → ${result.funds.length} 结果, 耗时: ${stopwatch.elapsedMilliseconds}ms');

      return enhancedResult;
    } catch (e) {
      _logger.e('❌ 智能搜索失败: $e');
      return EnhancedSearchResult.empty(error: e.toString());
    }
  }

  /// 多条件智能搜索
  Future<EnhancedSearchResult> multiCriteriaSearch(
      MultiCriteriaCriteria criteria) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      _logger.d('🔍 多条件智能搜索: ${criteria.toString()}');

      final result = _searchEngine.multiCriteriaSearch(criteria);
      final enhancedResult = EnhancedSearchResult.fromSearchResult(result);

      // 如果结果不为空，触发相关预加载
      if (enhancedResult.funds.isNotEmpty &&
          criteria.fundTypes.isNotEmpty == true) {
        unawaited(_preloadingManager.triggerConditionalPreload());
      }

      return enhancedResult;
    } catch (e) {
      _logger.e('❌ 多条件搜索失败: $e');
      return EnhancedSearchResult.empty(error: e.toString());
    }
  }

  /// 获取智能搜索建议
  Future<List<String>> getSmartSearchSuggestions(String prefix,
      {int maxSuggestions = 10}) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // 从搜索引擎获取基础建议
      final suggestions = _searchEngine.getSuggestions(prefix,
          maxSuggestions: maxSuggestions ~/ 2);

      // 添加热门搜索建议
      final hotSuggestions =
          await _getHotSearchSuggestions(maxSuggestions ~/ 2);

      // 合并并去重
      final allSuggestions = <String>{}
        ..addAll(suggestions)
        ..addAll(hotSuggestions);

      return allSuggestions.take(maxSuggestions).toList();
    } catch (e) {
      _logger.e('❌ 获取搜索建议失败: $e');
      return [];
    }
  }

  /// 预加载搜索缓存
  Future<void> warmupSearchCache() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      _logger.i('🔥 预热智能搜索缓存...');

      // 预热缓存管理器
      await _cacheManager.warmupCache();

      // 预热搜索引擎（使用热点查询）
      final hotQueries = await _getHotQueries();
      for (final query in hotQueries.take(10)) {
        _searchEngine.search(query);
      }

      // 触发条件预加载（如果满足条件）
      await _preloadingManager.triggerConditionalPreload();

      _logger.i('✅ 智能搜索缓存预热完成');
    } catch (e) {
      _logger.e('❌ 智能搜索缓存预热失败: $e');
    }
  }

  /// 刷新基金数据
  Future<void> refreshFundData({bool forceRefresh = true}) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      _logger.i('🔄 刷新智能搜索数据...');

      // 强制刷新缓存数据
      await _cacheManager.getFundData(forceRefresh: forceRefresh);

      // 重新构建搜索索引
      final funds = await _cacheManager.getFundData();
      await _searchEngine.buildIndexes(funds);

      // 重新初始化预加载管理器
      await _preloadingManager.initialize();

      _logger.i('✅ 智能搜索数据刷新完成');
    } catch (e) {
      _logger.e('❌ 智能搜索数据刷新失败: $e');
      rethrow;
    }
  }

  /// 获取增强搜索统计信息
  EnhancedSearchStatistics getEnhancedSearchStatistics() {
    if (!_isInitialized) {
      return EnhancedSearchStatistics.empty();
    }

    final cacheStats = _cacheManager.getCacheStats();
    final indexStats = _searchEngine.getIndexStats();
    final preloadStats = _preloadingManager.getStatistics();

    return EnhancedSearchStatistics(
      cacheStats: cacheStats,
      searchEngineStats: indexStats,
      preloadingStats: preloadStats,
      isInitialized: _isInitialized,
    );
  }

  /// 获取性能报告
  Future<EnhancedPerformanceReport> getEnhancedPerformanceReport() async {
    if (!_isInitialized) {
      await initialize();
    }

    final performanceReport =
        await _performanceOptimizer.generatePerformanceReport();
    final statistics = getEnhancedSearchStatistics();

    return EnhancedPerformanceReport(
      performanceReport: performanceReport,
      statistics: statistics,
      generatedAt: DateTime.now(),
    );
  }

  /// 诊断性能问题
  Future<List<EnhancedPerformanceIssue>>
      diagnoseEnhancedPerformanceIssues() async {
    if (!_isInitialized) {
      await initialize();
    }

    final issues = <EnhancedPerformanceIssue>[];

    // 基础性能问题诊断
    final basicIssues = await _performanceOptimizer.diagnosePerformanceIssues();
    issues.addAll(basicIssues
        .map((issue) => EnhancedPerformanceIssue.fromBasicIssue(issue)));

    // 预加载系统诊断
    final preloadStats = _preloadingManager.getStatistics();
    if (preloadStats.memoryUsageMB > 150) {
      issues.add(EnhancedPerformanceIssue(
        type: EnhancedPerformanceIssueType.highMemoryUsage,
        severity: Severity.medium,
        description:
            '预加载系统内存使用过高: ${preloadStats.memoryUsageMB.toStringAsFixed(1)}MB',
        suggestion: '建议调整预加载策略，增加LRU清理频率',
      ));
    }

    if (preloadStats.failedTasks > preloadStats.completedTasks * 0.1) {
      issues.add(EnhancedPerformanceIssue(
        type: EnhancedPerformanceIssueType.preloadFailures,
        severity: Severity.high,
        description:
            '预加载任务失败率过高: ${preloadStats.failedTasks}/${preloadStats.totalActiveTasks}',
        suggestion: '检查网络连接和API可用性，优化预加载重试机制',
      ));
    }

    return issues;
  }

  /// 增量加载基金历史数据
  Future<List<Map<String, dynamic>>> loadIncrementalHistoryData(
    String fundCode, {
    int days = 30,
    int offset = 0,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    return await _preloadingManager.loadIncrementalHistoryData(
      fundCode,
      days: days,
      offset: offset,
    );
  }

  /// 触发行为预加载
  Future<void> triggerBehaviorPreload(String fundCode) async {
    if (!_isInitialized) {
      await initialize();
    }

    await _preloadingManager.triggerBehaviorPreload(fundCode);
  }

  /// 获取服务健康状态
  EnhancedServiceHealthStatus getEnhancedServiceHealthStatus() {
    if (!_isInitialized) {
      return EnhancedServiceHealthStatus.uninitialized();
    }

    final cacheStats = _cacheManager.getCacheStats();
    final indexStats = _searchEngine.getIndexStats();
    final preloadStats = _preloadingManager.getStatistics();

    // 检查关键指标
    bool isHealthy = true;
    List<String> issues = [];

    if (cacheStats.memoryCacheSize == 0) {
      isHealthy = false;
      issues.add('内存缓存为空');
    }

    if (!indexStats.isBuilt) {
      isHealthy = false;
      issues.add('搜索引擎索引未构建');
    }

    if (indexStats.totalFunds == 0) {
      isHealthy = false;
      issues.add('基金数据为空');
    }

    if (indexStats.memoryEstimateMB > 200) {
      issues.add('搜索引擎内存使用较高');
    }

    if (!preloadStats.isRunning) {
      issues.add('智能预加载管理器未运行');
    }

    if (preloadStats.memoryUsageMB > 200) {
      issues.add('预加载系统内存使用较高');
    }

    return isHealthy
        ? EnhancedServiceHealthStatus.healthy()
        : EnhancedServiceHealthStatus.unhealthy(issues);
  }

  /// 清空所有缓存和索引
  Future<void> clearAllData() async {
    try {
      _logger.i('🗑️ 清空所有增强搜索数据...');

      // 清空缓存
      await _cacheManager.clearAllCache();

      // 清空搜索引擎索引
      await _searchEngine.buildIndexes([]);

      // 停止并重启预加载管理器
      await _preloadingManager.stop();
      await _preloadingManager.initialize();

      _logger.i('✅ 所有增强搜索数据已清空');
    } catch (e) {
      _logger.e('❌ 清空增强搜索数据失败: $e');
    }
  }

  // ========== 私有方法 ==========

  /// 记录搜索行为
  void _recordSearchBehavior(String query) {
    // 这里可以记录用户搜索行为，用于优化预加载策略
    // 例如：记录搜索频率、搜索模式等
  }

  /// 获取热门搜索建议
  Future<List<String>> _getHotSearchSuggestions(int limit) async {
    // 这里可以从预加载管理器或本地缓存获取热门搜索
    // 暂时返回模拟数据
    return [
      '新能源',
      '医疗健康',
      '消费升级',
      '科技创新',
      '大盘蓝筹',
      '债券基金',
      '货币基金',
      'QDII基金',
    ].take(limit).toList();
  }

  /// 获取热点查询
  Future<List<String>> _getHotQueries() async {
    // 这里可以从预加载管理器获取热点查询
    // 暂时返回模拟数据
    return [
      '易方达',
      '华夏',
      '股票型',
      '债券型',
      '混合型',
    ];
  }

  /// 记录服务状态
  void _logServiceStatus() {
    final cacheStats = _cacheManager.getCacheStats();
    final indexStats = _searchEngine.getIndexStats();
    final preloadStats = _preloadingManager.getStatistics();

    _logger.i('📊 增强搜索服务状态:');
    _logger.i('  缓存状态: ${cacheStats.memoryCacheSize} 只基金');
    _logger.i('  索引状态: ${indexStats.totalFunds} 只基金');
    _logger.i('  内存使用: ${indexStats.memoryEstimateMB.toStringAsFixed(1)}MB');
    _logger.i('  预加载状态: ${preloadStats.isRunning ? '运行中' : '已停止'}');
    _logger.i('  预加载任务: ${preloadStats.totalActiveTasks} 个活动任务');
  }

  /// 关闭增强搜索服务
  Future<void> dispose() async {
    try {
      _logger.i('🔚 关闭增强搜索服务...');

      // 停止性能监控
      _performanceOptimizer.stopMonitoring();

      // 关闭各个组件
      await _preloadingManager.stop();
      await _cacheManager.dispose();
      await _performanceOptimizer.dispose();

      _isInitialized = false;

      _logger.i('✅ 增强搜索服务已关闭');
    } catch (e) {
      _logger.e('❌ 关闭增强搜索服务失败: $e');
    }
  }
}

// ========== 辅助数据类 ==========

/// 增强搜索选项
class EnhancedSearchOptions {
  final int maxResults;
  final int minResults;
  final String sortBy;
  final String sortOrder;
  final bool enableFuzzy;
  final bool enablePinyin;
  final bool enableBehaviorPreload;
  final bool enableIncrementalLoad;

  const EnhancedSearchOptions({
    this.maxResults = 20,
    this.minResults = 5,
    this.sortBy = 'relevance',
    this.sortOrder = 'desc',
    this.enableFuzzy = true,
    this.enablePinyin = true,
    this.enableBehaviorPreload = true,
    this.enableIncrementalLoad = true,
  });

  /// 转换为基础搜索选项
  SearchOptions toSearchOptions() {
    return SearchOptions(
      maxResults: maxResults,
      minResults: minResults,
      sortBy: sortBy,
      sortOrder: sortOrder,
      enableFuzzy: enableFuzzy,
      enablePinyin: enablePinyin,
    );
  }
}

/// 增强搜索结果
class EnhancedSearchResult {
  final String query;
  final List<FundInfo> funds;
  final int searchTimeMs;
  final int totalFound;
  final String indexUsed;
  final String? error;
  final bool hasPreloadedData;
  final Map<String, dynamic> metadata;

  EnhancedSearchResult({
    required this.query,
    required this.funds,
    required this.searchTimeMs,
    required this.totalFound,
    required this.indexUsed,
    this.error,
    this.hasPreloadedData = false,
    this.metadata = const {},
  });

  factory EnhancedSearchResult.fromSearchResult(SearchResult result) {
    return EnhancedSearchResult(
      query: result.query,
      funds: result.funds,
      searchTimeMs: result.searchTimeMs,
      totalFound: result.totalFound,
      indexUsed: result.indexUsed,
      error: result.error,
      metadata: {},
    );
  }

  factory EnhancedSearchResult.empty({String? error}) {
    return EnhancedSearchResult(
      query: '',
      funds: [],
      searchTimeMs: 0,
      totalFound: 0,
      indexUsed: 'none',
      error: error,
    );
  }
}

/// 增强搜索统计信息
class EnhancedSearchStatistics {
  final CacheStats cacheStats;
  final IndexStats searchEngineStats;
  final PreloadingStatistics preloadingStats;
  final bool isInitialized;

  EnhancedSearchStatistics({
    required this.cacheStats,
    required this.searchEngineStats,
    required this.preloadingStats,
    required this.isInitialized,
  });

  factory EnhancedSearchStatistics.empty() {
    return EnhancedSearchStatistics(
      cacheStats: CacheStats(
        memoryCacheSize: 0,
        lastUpdateTime: DateTime.now(),
        hotQueriesCount: 0,
        queryFrequencyCount: 0,
        dataHash: '',
        isInitialized: false,
        searchEngineStats: IndexStats.empty(),
      ),
      searchEngineStats: IndexStats.empty(),
      preloadingStats: PreloadingStatistics(
        isRunning: false,
        totalActiveTasks: 0,
        completedTasks: 0,
        failedTasks: 0,
        memoryCacheSize: 0,
        memoryUsageMB: 0.0,
        lastPreloadTimes: {},
        lruQueueSize: 0,
      ),
      isInitialized: false,
    );
  }

  @override
  String toString() {
    return '''
EnhancedSearchStatistics:
  初始化状态: ${isInitialized ? '已初始化' : '未初始化'}

  缓存统计:
    - 内存缓存: ${cacheStats.memoryCacheSize} 只基金
    - 最后更新: ${cacheStats.lastUpdateTime.toIso8601String()}
    - 热点查询: ${cacheStats.hotQueriesCount}

  搜索引擎统计:
    - 总基金数: ${searchEngineStats.totalFunds}
    - 内存使用: ${searchEngineStats.memoryEstimateMB.toStringAsFixed(1)}MB
    - 索引状态: ${searchEngineStats.isBuilt ? '已构建' : '未构建'}

  预加载统计:
    - 运行状态: ${preloadingStats.isRunning ? '运行中' : '已停止'}
    - 活动任务: ${preloadingStats.totalActiveTasks}
    - 内存缓存: ${preloadingStats.memoryCacheSize} 项
    - 内存使用: ${preloadingStats.memoryUsageMB.toStringAsFixed(1)}MB
    ''';
  }
}

/// 增强性能报告
class EnhancedPerformanceReport {
  final PerformanceReport performanceReport;
  final EnhancedSearchStatistics statistics;
  final DateTime generatedAt;

  EnhancedPerformanceReport({
    required this.performanceReport,
    required this.statistics,
    required this.generatedAt,
  });
}

/// 增强性能问题
class EnhancedPerformanceIssue {
  final EnhancedPerformanceIssueType type;
  final Severity severity;
  final String description;
  final String suggestion;

  EnhancedPerformanceIssue({
    required this.type,
    required this.severity,
    required this.description,
    required this.suggestion,
  });

  factory EnhancedPerformanceIssue.fromBasicIssue(PerformanceIssue basicIssue) {
    return EnhancedPerformanceIssue(
      type: _mapBasicIssueType(basicIssue.type),
      severity: basicIssue.severity,
      description: basicIssue.description,
      suggestion: basicIssue.suggestion,
    );
  }

  static EnhancedPerformanceIssueType _mapBasicIssueType(
      PerformanceIssueType basicType) {
    switch (basicType) {
      case PerformanceIssueType.slowSearch:
        return EnhancedPerformanceIssueType.slowSearch;
      case PerformanceIssueType.highMemoryUsage:
        return EnhancedPerformanceIssueType.highMemoryUsage;
      case PerformanceIssueType.lowCacheHitRate:
        return EnhancedPerformanceIssueType.lowCacheHitRate;
      case PerformanceIssueType.indexCorruption:
        return EnhancedPerformanceIssueType.indexCorruption;
      default:
        return EnhancedPerformanceIssueType.unknown;
    }
  }

  @override
  String toString() {
    return '[$severity] $type: $description (Suggestion: $suggestion)';
  }
}

/// 增强服务健康状态
class EnhancedServiceHealthStatus {
  final EnhancedHealthStatus status;
  final List<String> issues;
  final String? error;

  EnhancedServiceHealthStatus._(this.status, this.issues, this.error);

  factory EnhancedServiceHealthStatus.healthy() =>
      EnhancedServiceHealthStatus._(EnhancedHealthStatus.healthy, [], null);
  factory EnhancedServiceHealthStatus.uninitialized() =>
      EnhancedServiceHealthStatus._(
          EnhancedHealthStatus.uninitialized, [], null);
  factory EnhancedServiceHealthStatus.unhealthy(List<String> issues) =>
      EnhancedServiceHealthStatus._(
          EnhancedHealthStatus.unhealthy, issues, null);
  factory EnhancedServiceHealthStatus.error(String error) =>
      EnhancedServiceHealthStatus._(EnhancedHealthStatus.error, [], error);

  bool get isHealthy => status == EnhancedHealthStatus.healthy;
  bool get isUnhealthy => status == EnhancedHealthStatus.unhealthy;
  bool get hasError => status == EnhancedHealthStatus.error;

  @override
  String toString() {
    switch (status) {
      case EnhancedHealthStatus.healthy:
        return 'Healthy';
      case EnhancedHealthStatus.uninitialized:
        return 'Uninitialized';
      case EnhancedHealthStatus.unhealthy:
        return 'Unhealthy: ${issues.join(', ')}';
      case EnhancedHealthStatus.error:
        return 'Error: $error';
    }
  }
}

/// 枚举定义
enum EnhancedPerformanceIssueType {
  slowSearch,
  highMemoryUsage,
  lowCacheHitRate,
  indexCorruption,
  preloadFailures,
  networkTimeout,
  unknown,
}

enum EnhancedHealthStatus {
  healthy,
  uninitialized,
  unhealthy,
  error,
}
