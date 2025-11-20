import 'package:flutter/foundation.dart';
import '../coordinators/data_layer_coordinator.dart';
import '../../cache/unified_cache_manager.dart';
import '../../cache/config/cache_config_manager.dart';
import '../../cache/strategies/cache_strategies.dart';
import '../../cache/storage/cache_storage.dart';
import '../../network/intelligent_data_source_switcher.dart';
import '../../../features/fund/presentation/fund_exploration/domain/data/services/data_sync_manager.dart';
import '../../../features/fund/presentation/fund_exploration/domain/data/services/smart_cache_manager.dart';
import '../../../features/fund/presentation/fund_exploration/domain/data/services/optimized_fund_service.dart';
import '../../../features/fund/data/services/intelligent_preload_service.dart';
import '../../../features/fund/domain/repositories/fund_repository.dart';
import '../../../features/fund/domain/usecases/optimized_fund_filter_usecase.dart';
import '../../../features/fund/data/datasources/fund_local_data_source.dart';
import '../../../features/fund/domain/entities/fund.dart';
import '../../../features/fund/domain/entities/fund_filter_criteria.dart';
import '../../../features/fund/domain/entities/fund_search_criteria.dart';
import '../../../features/fund/domain/entities/fund_ranking.dart';
import '../../../features/fund/domain/entities/ranking_statistics.dart';
import '../../../features/fund/domain/entities/hot_ranking_type.dart';

/// 数据层集成配置
///
/// 提供数据层组件的依赖注入和配置管理
/// 支持不同环境的配置和组件组装
class DataLayerIntegration {
  static DataLayerCoordinator? _coordinator;
  static bool _isConfigured = false;

  /// 配置数据层（开发环境）
  static Future<DataLayerCoordinator> configureForDevelopment() async {
    return await _configure(
      environment: 'development',
      cacheConfig: UnifiedCacheConfig.development(),
      dataLayerConfig: DataLayerConfig.development(),
    );
  }

  /// 配置数据层（生产环境）
  static Future<DataLayerCoordinator> configureForProduction() async {
    return await _configure(
      environment: 'production',
      cacheConfig: UnifiedCacheConfig.production(),
      dataLayerConfig: DataLayerConfig.production(),
    );
  }

  /// 配置数据层（测试环境）
  static Future<DataLayerCoordinator> configureForTesting() async {
    return await _configure(
      environment: 'testing',
      cacheConfig: UnifiedCacheConfig.testing(),
      dataLayerConfig: DataLayerConfig.development(),
    );
  }

  /// 获取已配置的协调器
  static DataLayerCoordinator get coordinator {
    if (_coordinator == null || !_isConfigured) {
      throw StateError('DataLayer not configured. Call configureFor*() first.');
    }
    return _coordinator!;
  }

  /// 重置配置（主要用于测试）
  static Future<void> reset() async {
    if (_coordinator != null) {
      await _coordinator!.dispose();
      _coordinator = null;
    }
    _isConfigured = false;
  }

  /// 内部配置方法
  static Future<DataLayerCoordinator> _configure({
    required String environment,
    required UnifiedCacheConfig cacheConfig,
    required DataLayerConfig dataLayerConfig,
  }) async {
    if (_isConfigured && _coordinator != null) {
      return _coordinator!;
    }

    try {
      debugPrint('🔧 开始配置数据层 [$environment]...');

      // 1. 创建缓存组件
      final cacheComponents =
          await _createCacheComponents(cacheConfig, environment);

      // 2. 创建数据源组件
      final dataSourceComponents =
          await _createDataSourceComponents(environment);

      // 3. 创建服务组件
      final serviceComponents = await _createServiceComponents(
        cacheComponents['unified'] as UnifiedCacheManager,
        cacheComponents['smart'] as SmartCacheManager,
      );

      // 4. 创建数据层协调器
      _coordinator = DataLayerCoordinator.withDependencies(
        cacheManager: cacheComponents['unified'] as UnifiedCacheManager,
        dataSourceSwitcher:
            dataSourceComponents['switcher'] as IntelligentDataSourceSwitcher,
        syncManager: serviceComponents['sync'] as DataSyncManager,
        smartCacheManager: cacheComponents['smart'] as SmartCacheManager,
        fundService: serviceComponents['fund'] as OptimizedFundService,
        preloadService:
            serviceComponents['preload'] as IntelligentPreloadService,
        config: dataLayerConfig,
      );

      // 5. 初始化协调器
      await _coordinator!.initialize();

      _isConfigured = true;
      debugPrint('✅ 数据层配置完成 [$environment]');
      return _coordinator!;
    } catch (e) {
      debugPrint('❌ 数据层配置失败 [$environment]: $e');
      rethrow;
    }
  }

  /// 创建缓存组件
  static Future<Map<String, dynamic>> _createCacheComponents(
      UnifiedCacheConfig config, String environment) async {
    debugPrint('🔧 创建缓存组件...');

    // 1. 创建缓存存储，根据环境决定是否启用测试模式
    final storage = HiveCacheStorage(testMode: environment == 'testing');

    // 2. 创建缓存策略
    final strategy = LRUCacheStrategy();

    // 3. 创建配置管理器
    final configManager = CacheConfigManager();

    // 4. 创建统一缓存管理器
    final unifiedCacheManager = UnifiedCacheManager(
      storage: storage,
      strategy: strategy,
      configManager: configManager,
      config: config,
    );

    // 5. 创建智能缓存管理器
    final smartCacheManager = SmartCacheManager();

    return {
      'unified': unifiedCacheManager,
      'smart': smartCacheManager,
      'storage': storage,
      'strategy': strategy,
      'config': configManager,
    };
  }

  /// 创建数据源组件
  static Future<Map<String, dynamic>> _createDataSourceComponents(
      String environment) async {
    debugPrint('🔧 创建数据源组件...');

    // 创建数据源切换器
    final switcher = IntelligentDataSourceSwitcher();

    return {
      'switcher': switcher,
    };
  }

  /// 创建服务组件
  static Future<Map<String, dynamic>> _createServiceComponents(
    UnifiedCacheManager unifiedCacheManager,
    SmartCacheManager smartCacheManager,
  ) async {
    debugPrint('🔧 创建服务组件...');

    // 1. 创建优化基金服务
    final fundService = OptimizedFundService();

    // 2. 创建智能预加载服务
    // 注意：这里使用占位符实现，实际使用时需要注入真实的依赖
    final preloadService = IntelligentPreloadService(
      MockFundRepository(), // Mock实现
      MockFundLocalDataSource(), // Mock实现
      MockOptimizedFundFilterUseCase(), // Mock实现
    );

    // 3. 创建数据同步管理器
    final syncManager = DataSyncManager(
      fundService: fundService,
      cacheManager: smartCacheManager,
    );

    return {
      'fund': fundService,
      'preload': preloadService,
      'sync': syncManager,
    };
  }

  /// 获取数据层状态
  static DataLayerStatus getStatus() {
    if (!_isConfigured || _coordinator == null) {
      return const DataLayerStatus(
        isConfigured: false,
        isInitialized: false,
        environment: 'unknown',
        lastConfigured: null,
        components: {},
      );
    }

    return DataLayerStatus(
      isConfigured: _isConfigured,
      isInitialized: _coordinator!.isInitialized,
      environment: 'configured', // 可以从配置中获取
      lastConfigured: DateTime.now(),
      components: {
        'cacheManager': true,
        'dataSourceSwitcher': true,
        'syncManager': true,
        'smartCacheManager': true,
        'fundService': true,
        'preloadService': true,
      },
    );
  }

  /// 执行数据层健康检查
  static Future<DataLayerHealthReport> performHealthCheck() async {
    if (!_isConfigured || _coordinator == null) {
      throw StateError('DataLayer not configured');
    }

    return await _coordinator!.getHealthReport();
  }

  /// 获取性能指标
  static Future<DataLayerPerformanceMetrics> getPerformanceMetrics() async {
    if (!_isConfigured || _coordinator == null) {
      throw StateError('DataLayer not configured');
    }

    return await _coordinator!.getPerformanceMetrics();
  }

  /// 刷新数据层
  static Future<bool> refreshDataLayer({FundFilterCriteria? criteria}) async {
    if (!_isConfigured || _coordinator == null) {
      return false;
    }

    return await _coordinator!.refreshCache(criteria: criteria);
  }

  /// 清空数据层缓存
  static Future<void> clearDataLayerCache() async {
    if (_isConfigured && _coordinator != null) {
      await _coordinator!.clearAllCache();
    }
  }

  /// 释放数据层资源
  static Future<void> dispose() async {
    if (_coordinator != null) {
      await _coordinator!.dispose();
      _coordinator = null;
    }
    _isConfigured = false;
  }
}

/// 数据层状态
class DataLayerStatus {
  final bool isConfigured;
  final bool isInitialized;
  final String environment;
  final DateTime? lastConfigured;
  final Map<String, bool> components;

  const DataLayerStatus({
    required this.isConfigured,
    required this.isInitialized,
    required this.environment,
    this.lastConfigured,
    required this.components,
  });

  /// 是否所有组件都正常运行
  bool get allComponentsHealthy =>
      components.values.every((healthy) => healthy);

  /// 获取不健康的组件列表
  List<String> get unhealthyComponents {
    return components.entries
        .where((entry) => !entry.value)
        .map((entry) => entry.key)
        .toList();
  }
}

/// 数据层配置构建器
class DataLayerConfigBuilder {
  UnifiedCacheConfig? _cacheConfig;
  DataLayerConfig? _dataLayerConfig;
  String _environment = 'development';
  bool _enableMonitoring = true;
  bool _enableDebugLogging = false;

  /// 设置环境
  DataLayerConfigBuilder setEnvironment(String environment) {
    _environment = environment;
    return this;
  }

  /// 设置缓存配置
  DataLayerConfigBuilder setCacheConfig(UnifiedCacheConfig config) {
    _cacheConfig = config;
    return this;
  }

  /// 设置数据层配置
  DataLayerConfigBuilder setDataLayerConfig(DataLayerConfig config) {
    _dataLayerConfig = config;
    return this;
  }

  /// 启用/禁用监控
  DataLayerConfigBuilder setMonitoringEnabled(bool enabled) {
    _enableMonitoring = enabled;
    return this;
  }

  /// 启用/禁用调试日志
  DataLayerConfigBuilder setDebugLoggingEnabled(bool enabled) {
    _enableDebugLogging = enabled;
    return this;
  }

  /// 构建配置
  Future<DataLayerCoordinator> build() async {
    // 根据环境设置默认配置
    final cacheConfig = _cacheConfig ?? _getDefaultCacheConfig();
    final dataLayerConfig = _dataLayerConfig ?? _getDefaultDataLayerConfig();

    // 应用调试设置
    if (_enableDebugLogging) {
      debugPrint('🐛 数据层调试模式已启用');
    }

    // 配置数据层
    final coordinator = await DataLayerIntegration._configure(
      environment: _environment,
      cacheConfig: cacheConfig,
      dataLayerConfig: dataLayerConfig,
    );

    // 应用监控设置
    if (_enableMonitoring) {
      debugPrint('📊 数据层监控已启用');
    }

    return coordinator;
  }

  /// 获取默认缓存配置
  UnifiedCacheConfig _getDefaultCacheConfig() {
    switch (_environment) {
      case 'production':
        return UnifiedCacheConfig.production();
      case 'testing':
        return UnifiedCacheConfig.testing();
      case 'development':
      default:
        return UnifiedCacheConfig.development();
    }
  }

  /// 获取默认数据层配置
  DataLayerConfig _getDefaultDataLayerConfig() {
    switch (_environment) {
      case 'production':
        return DataLayerConfig.production();
      case 'testing':
        return DataLayerConfig.development();
      case 'development':
      default:
        return DataLayerConfig.development();
    }
  }
}

/// 数据层工厂
class DataLayerFactory {
  /// 创建开发环境数据层
  static Future<DataLayerCoordinator> createDevelopment() async {
    return await DataLayerConfigBuilder()
        .setEnvironment('development')
        .setDebugLoggingEnabled(true)
        .setMonitoringEnabled(true)
        .build();
  }

  /// 创建生产环境数据层
  static Future<DataLayerCoordinator> createProduction() async {
    return await DataLayerConfigBuilder()
        .setEnvironment('production')
        .setDebugLoggingEnabled(false)
        .setMonitoringEnabled(true)
        .build();
  }

  /// 创建测试环境数据层
  static Future<DataLayerCoordinator> createTesting() async {
    return await DataLayerConfigBuilder()
        .setEnvironment('testing')
        .setDebugLoggingEnabled(true)
        .setMonitoringEnabled(false)
        .build();
  }

  /// 创建自定义数据层
  static Future<DataLayerCoordinator> createCustom({
    required String environment,
    UnifiedCacheConfig? cacheConfig,
    DataLayerConfig? dataLayerConfig,
    bool enableMonitoring = true,
    bool enableDebugLogging = false,
  }) async {
    return await DataLayerConfigBuilder()
        .setEnvironment(environment)
        .setCacheConfig(cacheConfig ?? UnifiedCacheConfig.defaultConfig())
        .setDataLayerConfig(dataLayerConfig ?? DataLayerConfig.defaultConfig())
        .setMonitoringEnabled(enableMonitoring)
        .setDebugLoggingEnabled(enableDebugLogging)
        .build();
  }
}

// ============================================================================
// Mock类定义（仅用于开发环境）
// ============================================================================

/// Mock基金仓储实现
class MockFundRepository implements FundRepository {
  @override
  Future<List<Fund>> getFundList() async => [];

  @override
  Future<List<Fund>> getFunds() async => [];

  @override
  Future<List<Fund>> getFundRankings(String symbol) async => [];

  @override
  Future<PaginatedRankingResult> getFundRankingsByCriteria(
    RankingCriteria criteria, {
    bool forceRefresh = false,
  }) async {
    return const PaginatedRankingResult(
      rankings: [],
      currentPage: 1,
      pageSize: 20,
      totalCount: 0,
      totalPages: 0,
      hasNextPage: false,
      hasPreviousPage: false,
      hasMore: false,
    );
  }

  @override
  Future<List<FundRanking>> getFundRankingHistory(
    String fundCode,
    RankingPeriod period, {
    int days = 30,
  }) async =>
      [];

  @override
  Future<PaginatedRankingResult> searchRankings(
    String query,
    RankingCriteria criteria,
  ) async {
    return const PaginatedRankingResult(
      rankings: [],
      currentPage: 1,
      pageSize: 20,
      totalCount: 0,
      totalPages: 0,
      hasNextPage: false,
      hasPreviousPage: false,
      hasMore: false,
    );
  }

  @override
  Future<RankingStatistics> getRankingStatistics(
      RankingCriteria criteria) async {
    return RankingStatistics(
      totalFunds: 0,
      averageReturn: 0.0,
      volatilityIndex: 0.0,
      sharpeRatio: 0.0,
      maxDrawdown: 0.0,
      positiveReturnRate: 0.0,
      averageRiskLevel: 0.0,
      updateTime: DateTime.now(),
    );
  }

  @override
  Future<PaginatedRankingResult> getFavoriteFundsRankings(
    List<String> fundCodes,
    RankingCriteria criteria,
  ) async {
    return const PaginatedRankingResult(
      rankings: [],
      currentPage: 1,
      pageSize: 20,
      totalCount: 0,
      totalPages: 0,
      hasNextPage: false,
      hasPreviousPage: false,
      hasMore: false,
    );
  }

  @override
  Future<bool> saveFavoriteFunds(Set<String> fundCodes) async => true;

  @override
  Future<Set<String>> getFavoriteFunds() async => {};

  @override
  Future<List<HotRankingType>> getHotRankingTypes() async => [];

  @override
  Future<List<FundRanking>> getFundsForComparison(
    List<String> fundCodes,
    List<RankingPeriod> periods,
  ) async =>
      [];

  @override
  Future<Map<String, Map<RankingPeriod, FundRanking>>>
      getBatchFundHistoricalData(
    List<String> fundCodes,
    List<RankingPeriod> periods,
  ) async =>
          {};

  @override
  Future<List<String>> getFundTypes() async => [];

  @override
  Future<List<String>> getFundCompanies() async => [];

  @override
  Future<bool> refreshRankingCache({
    RankingType? rankingType,
    RankingPeriod? period,
  }) async =>
      true;

  @override
  Future<void> clearRankingCache() async {}

  @override
  Future<DateTime?> getRankingUpdateTime({
    RankingType? rankingType,
    RankingPeriod? period,
  }) async =>
      null;

  @override
  Future<List<Fund>> getFilteredFunds(FundFilterCriteria criteria) async => [];

  @override
  Future<int> getFilteredFundsCount(FundFilterCriteria criteria) async => 0;

  @override
  Future<List<String>> getFilterOptions(FilterType type) async => [];

  @override
  Future<List<Fund>> searchFunds(FundSearchCriteria criteria) async => [];

  @override
  Future<List<String>> getSearchSuggestions(String keyword,
          {int limit = 10}) async =>
      [];

  @override
  Future<List<String>> getSearchHistory({int limit = 50}) async => [];

  @override
  Future<bool> saveSearchHistory(String keyword) async => true;

  @override
  Future<bool> deleteSearchHistory(String keyword) async => true;

  @override
  Future<bool> clearSearchHistory() async => true;

  @override
  Future<List<String>> getPopularSearches({int limit = 10}) async => [];

  @override
  Future<void> preloadSearchCache() async {}

  @override
  Future<void> clearSearchCache() async {}

  @override
  Future<Map<String, dynamic>> getSearchStatistics() async => {};
}

/// Mock本地数据源实现
class MockFundLocalDataSource implements FundLocalDataSource {
  @override
  Future<List<Fund>> getCachedFundList() async => [];

  @override
  Future<void> cacheFundList(List<Fund> funds) async {}

  @override
  Future<List<Fund>> getCachedFilteredFunds(
          FundFilterCriteria criteria) async =>
      [];

  @override
  Future<void> cacheFilteredFunds(
      FundFilterCriteria criteria, List<Fund> funds) async {}

  @override
  Future<int?> getCachedFilteredFundsCount(FundFilterCriteria criteria) async =>
      0;

  @override
  Future<void> cacheFilteredFundsCount(
      FundFilterCriteria criteria, int count) async {}

  @override
  Future<List<String>?> getCachedFilterOptions(FilterType type) async => [];

  @override
  Future<void> cacheFilterOptions(
      FilterType type, List<String> options) async {}

  @override
  Future<void> clearExpiredCache() async {}

  @override
  Future<bool> isCacheValid(
          {Duration maxAge = const Duration(minutes: 15)}) async =>
      false;

  @override
  Future<Map<String, int>> getCacheSizeInfo() async => {};

  @override
  Future<PaginatedRankingResult?> getCachedRankings(
          RankingCriteria criteria) async =>
      null;

  @override
  Future<void> cacheRankings(
      RankingCriteria criteria, PaginatedRankingResult result) async {}

  @override
  Future<DateTime?> getRankingUpdateTime(
          RankingType? rankingType, RankingPeriod? period) async =>
      null;

  @override
  Future<bool> saveFavoriteFunds(Set<String> fundCodes) async => true;

  @override
  Future<Set<String>> getFavoriteFunds() async => {};

  @override
  Future<void> clearRankingCache() async {}
}

/// Mock优化的基金筛选用例实现
class MockOptimizedFundFilterUseCase implements OptimizedFundFilterUseCase {
  @override
  int get batchSize => 500;

  @override
  int get maxConcurrentFilters => 4;

  @override
  int get maxMemoryUsageMB => 100;

  @override
  Duration get timeout => const Duration(seconds: 10);

  @override
  Future<FundFilterResult> execute(
    FundFilterCriteria criteria, {
    bool forceRefresh = false,
  }) async {
    return FundFilterResult(
      funds: [],
      totalCount: 0,
      hasMore: false,
      criteria: criteria,
    );
  }

  @override
  Future<void> clearPerformanceMetrics() async {}

  @override
  Map<String, dynamic> getPerformanceMetrics() => {};

  @override
  Future<List<Fund>> parallelFilter(
    List<Fund> funds,
    FundFilterCriteria criteria,
  ) async =>
      [];

  @override
  Future<void> preloadCommonFilters(List<FilterPresetType> presetTypes) async {}
}
