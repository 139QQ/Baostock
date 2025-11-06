import 'dart:async';
import 'dart:developer' as developer;

import '../../../features/fund/domain/entities/fund.dart';
import '../../../features/fund/domain/entities/fund_search_criteria.dart';
import '../../../features/fund/domain/entities/fund_ranking.dart';
import '../interfaces/i_unified_data_source.dart';
import '../interfaces/i_data_router.dart';
import '../interfaces/i_data_consistency_manager.dart';
import '../../cache/interfaces/i_unified_cache_service.dart';
import '../../network/interfaces/i_intelligent_data_source_switcher.dart';

/// 统一数据源管理器实现
///
/// 整合本地缓存、远程API和实时数据流，提供统一的数据访问接口
/// 支持智能路由、故障转移和性能优化
class UnifiedDataSourceManager implements IUnifiedDataSource {
  // ========================================================================
  // 核心依赖组件
  // ========================================================================

  final ILocalDataSource _localDataSource;
  final IRemoteDataSource _remoteDataSource;
  final IDataRouter _dataRouter;
  final IDataConsistencyManager _consistencyManager;
  final IUnifiedCacheService _cacheService;
  final IIntelligentDataSourceSwitcher _dataSourceSwitcher;

  // ========================================================================
  // 配置和状态
  // ========================================================================

  final UnifiedDataSourceConfig _config;
  bool _isInitialized = false;

  // 性能监控
  final Map<String, List<Duration>> _performanceMetrics = {};
  final Map<String, int> _requestCounts = {};
  Timer? _metricsCleanupTimer;

  // 请求追踪
  final Map<String, DateTime> _activeRequests = {};
  int _requestIdCounter = 0;

  // ========================================================================
  // 构造函数和初始化
  // ========================================================================

  UnifiedDataSourceManager({
    required ILocalDataSource localDataSource,
    required IRemoteDataSource remoteDataSource,
    required IDataRouter dataRouter,
    required IDataConsistencyManager consistencyManager,
    required IUnifiedCacheService cacheService,
    required IIntelligentDataSourceSwitcher dataSourceSwitcher,
    UnifiedDataSourceConfig? config,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _dataRouter = dataRouter,
        _consistencyManager = consistencyManager,
        _cacheService = cacheService,
        _dataSourceSwitcher = dataSourceSwitcher,
        _config = config ?? UnifiedDataSourceConfig.defaultConfig();

  /// 初始化统一数据源管理器
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      developer.log('🔄 初始化统一数据源管理器...', name: 'UnifiedDataSourceManager');

      // 1. 初始化各个组件
      await _initializeComponents();

      // 2. 设置组件间协调
      await _setupComponentCoordination();

      // 3. 启动性能监控
      _startPerformanceMonitoring();

      _isInitialized = true;
      developer.log('✅ 统一数据源管理器初始化完成', name: 'UnifiedDataSourceManager');
    } catch (e) {
      developer.log('❌ 统一数据源管理器初始化失败: $e',
          name: 'UnifiedDataSourceManager', level: 1000);
      rethrow;
    }
  }

  /// 检查管理器是否已初始化
  bool get isInitialized => _isInitialized;

  /// 初始化各个组件
  Future<void> _initializeComponents() async {
    // 初始化缓存服务
    if (!_cacheService.isInitialized) {
      await _cacheService.initialize();
    }

    // 初始化数据源切换器
    await _dataSourceSwitcher.initialize();

    // 初始化数据路由器
    await _dataRouter.initialize();

    // 初始化一致性管理器
    await _consistencyManager.initialize();

    developer.log('✅ 所有组件初始化完成', name: 'UnifiedDataSourceManager');
  }

  /// 设置组件间协调
  Future<void> _setupComponentCoordination() async {
    // 设置数据源切换事件监听
    _dataSourceSwitcher.onDataSourceSwitched.listen(_handleDataSourceSwitched);

    // 一致性管理器事件监听已禁用（接口中未定义事件流）

    developer.log('✅ 组件协调关系设置完成', name: 'UnifiedDataSourceManager');
  }

  /// 启动性能监控
  void _startPerformanceMonitoring() {
    _metricsCleanupTimer = Timer.periodic(
      _config.metricsCleanupInterval,
      (_) => _cleanupOldMetrics(),
    );
  }

  // ========================================================================
  // 核心数据访问接口实现
  // ========================================================================

  @override
  Future<List<Fund>> getFunds({
    FundSearchCriteria? criteria,
    bool forceRefresh = false,
    Duration? timeout,
  }) async {
    _ensureInitialized();

    final requestId = _generateRequestId('getFunds');
    final stopwatch = Stopwatch()..start();

    try {
      developer.log('📊 开始获取基金列表 [请求ID: $requestId]',
          name: 'UnifiedDataSourceManager');
      _activeRequests[requestId] = DateTime.now();

      // 1. 数据源路由决策
      final operation = DataOperation(
        type: OperationType.read,
        parameters: {'criteria': criteria?.toJson()},
        priority: RequestPriority.normal,
        expectedDataSize: 1000, // 预期返回约1000条数据
      );

      final selectedSource = await _dataRouter.selectBestDataSource(
        operation,
        criteria: SelectionCriteria(
          performance: PerformanceRequirements(
            maxResponseTime: timeout?.inMilliseconds.toDouble() ?? 5000.0,
            minThroughput: 10.0,
            expectedConcurrency: 1,
          ),
          reliability: const ReliabilityRequirements(
            minAvailability: 0.99,
            maxErrorRate: 0.01,
            requiresConsistency: true,
          ),
          freshness: FreshnessRequirements(
            maxDataAge:
                forceRefresh ? Duration.zero : _config.defaultMaxDataAge,
            requiresRealTime: false,
            updateFrequency: UpdateFrequency.perHour,
          ),
        ),
        context: RequestContext(
          requestId: requestId,
          source: RequestSource.desktop,
          priority: RequestPriority.normal,
          timeout: timeout ?? _config.defaultTimeout,
        ),
      );

      developer.log(
          '🎯 选择数据源: ${selectedSource.dataSource.name} [原因: ${selectedSource.reason}]',
          name: 'UnifiedDataSourceManager');

      // 2. 尝试从缓存获取
      List<Fund>? funds;
      if (!forceRefresh &&
          selectedSource.dataSource.type != DataSourceType.remoteApi) {
        funds = await _tryGetFromCache('funds', criteria);
        if (funds != null) {
          _recordMetrics('getFunds_cache', stopwatch.elapsed);
          return funds;
        }
      }

      // 3. 从选定的数据源获取
      funds = await _fetchFromSelectedSource<List<Fund>>(
        selectedSource,
        operation,
        () => _fetchFundsFromSource(criteria, selectedSource.dataSource),
        requestId,
      );

      // 4. 缓存结果
      if (funds.isNotEmpty) {
        await _cacheData('funds', criteria, funds);
      }

      // 5. 记录性能指标
      _recordMetrics('getFunds', stopwatch.elapsed);
      _recordRequestCount('getFunds');

      developer.log('✅ 基金列表获取完成: ${funds.length}条 [请求ID: $requestId]',
          name: 'UnifiedDataSourceManager');

      return funds;
    } catch (e) {
      developer.log('❌ 获取基金列表失败 [请求ID: $requestId]: $e',
          name: 'UnifiedDataSourceManager', level: 1000);
      _recordMetrics('getFunds_error', stopwatch.elapsed);

      // 尝试故障转移
      return await _performFailover<List<Fund>>(
        'getFunds',
        () => getFunds(
            criteria: criteria, forceRefresh: forceRefresh, timeout: timeout),
        requestId,
      );
    } finally {
      _activeRequests.remove(requestId);
      stopwatch.stop();
    }
  }

  @override
  Future<List<Fund>> searchFunds(
    FundSearchCriteria criteria, {
    bool useCache = true,
  }) async {
    _ensureInitialized();

    final requestId = _generateRequestId('searchFunds');
    final stopwatch = Stopwatch()..start();

    try {
      developer.log('🔍 开始搜索基金 [请求ID: $requestId]',
          name: 'UnifiedDataSourceManager');
      _activeRequests[requestId] = DateTime.now();

      // 1. 生成搜索缓存键
      final cacheKey = _generateSearchCacheKey(criteria);

      // 2. 尝试从缓存获取
      if (useCache) {
        final cachedResults = await _cacheService.get<List<Fund>>(cacheKey);
        if (cachedResults != null) {
          _recordMetrics('searchFunds_cache', stopwatch.elapsed);
          return cachedResults;
        }
      }

      // 3. 数据源路由决策
      final operation = DataOperation(
        type: OperationType.search,
        parameters: criteria.toJson(),
        priority: RequestPriority.normal,
        expectedDataSize: 500, // 搜索结果预期较小
      );

      final selectedSource = await _dataRouter.selectBestDataSource(operation);

      // 4. 执行搜索
      final results = await _fetchFromSelectedSource<List<Fund>>(
        selectedSource,
        operation,
        () => _searchFundsFromSource(criteria, selectedSource.dataSource),
        requestId,
      );

      // 5. 缓存搜索结果
      if (results.isNotEmpty && useCache) {
        await _cacheService.put(cacheKey, results,
            config: CacheConfig(ttl: _config.searchCacheTTL));
      }

      _recordMetrics('searchFunds', stopwatch.elapsed);
      _recordRequestCount('searchFunds');

      developer.log('✅ 基金搜索完成: ${results.length}条结果 [请求ID: $requestId]',
          name: 'UnifiedDataSourceManager');

      return results;
    } catch (e) {
      developer.log('❌ 基金搜索失败 [请求ID: $requestId]: $e',
          name: 'UnifiedDataSourceManager', level: 1000);
      _recordMetrics('searchFunds_error', stopwatch.elapsed);
      rethrow;
    } finally {
      _activeRequests.remove(requestId);
      stopwatch.stop();
    }
  }

  @override
  Future<PaginatedRankingResult> getFundRankings(
    RankingCriteria criteria, {
    int page = 1,
    int pageSize = 20,
  }) async {
    _ensureInitialized();

    final requestId = _generateRequestId('getFundRankings');
    final stopwatch = Stopwatch()..start();

    try {
      developer.log('🏆 开始获取基金排行榜 [请求ID: $requestId]',
          name: 'UnifiedDataSourceManager');
      _activeRequests[requestId] = DateTime.now();

      // 1. 生成缓存键
      final cacheKey = _generateRankingCacheKey(criteria, page, pageSize);

      // 2. 尝试从缓存获取
      final cachedRankings =
          await _cacheService.get<PaginatedRankingResult>(cacheKey);
      if (cachedRankings != null) {
        _recordMetrics('getFundRankings_cache', stopwatch.elapsed);
        return cachedRankings;
      }

      // 3. 数据源路由决策
      final operation = DataOperation(
        type: OperationType.read,
        parameters: {
          'criteria': criteria.toJson(),
          'page': page,
          'pageSize': pageSize,
        },
        priority: RequestPriority.normal,
        expectedDataSize: pageSize,
      );

      final selectedSource = await _dataRouter.selectBestDataSource(operation);

      // 4. 获取排行榜数据
      final rankings = await _fetchFromSelectedSource<PaginatedRankingResult>(
        selectedSource,
        operation,
        () => _fetchRankingsFromSource(
            criteria, page, pageSize, selectedSource.dataSource),
        requestId,
      );

      // 5. 缓存结果
      await _cacheService.put(cacheKey, rankings,
          config: CacheConfig(ttl: _config.rankingCacheTTL));

      _recordMetrics('getFundRankings', stopwatch.elapsed);
      _recordRequestCount('getFundRankings');

      developer.log('✅ 基金排行榜获取完成 [请求ID: $requestId]',
          name: 'UnifiedDataSourceManager');

      return rankings;
    } catch (e) {
      developer.log('❌ 获取基金排行榜失败 [请求ID: $requestId]: $e',
          name: 'UnifiedDataSourceManager', level: 1000);
      _recordMetrics('getFundRankings_error', stopwatch.elapsed);
      rethrow;
    } finally {
      _activeRequests.remove(requestId);
      stopwatch.stop();
    }
  }

  @override
  Future<List<Fund>> getBatchFunds(
    List<String> fundCodes, {
    List<String>? fields,
  }) async {
    _ensureInitialized();

    final requestId = _generateRequestId('getBatchFunds');
    final stopwatch = Stopwatch()..start();

    try {
      developer.log('📦 开始批量获取基金数据: ${fundCodes.length}只 [请求ID: $requestId]',
          name: 'UnifiedDataSourceManager');
      _activeRequests[requestId] = DateTime.now();

      final results = <String, Fund>{};
      final codesToFetch = <String>[];

      // 1. 批量检查缓存
      for (final code in fundCodes) {
        final cacheKey = 'fund_detail_${code}_${fields?.join(',') ?? 'all'}';
        final cachedFund = await _cacheService.get<Fund>(cacheKey);
        if (cachedFund != null) {
          results[code] = cachedFund;
        } else {
          codesToFetch.add(code);
        }
      }

      developer.log(
          '📊 缓存命中: ${results.length}/${fundCodes.length}只基金 [请求ID: $requestId]',
          name: 'UnifiedDataSourceManager');

      // 2. 批量获取未缓存的基金
      if (codesToFetch.isNotEmpty) {
        final batchResults =
            await _fetchBatchFundsFromSource(codesToFetch, fields);
        results.addAll(batchResults);

        // 3. 缓存新获取的基金
        for (final entry in batchResults.entries) {
          final cacheKey =
              'fund_detail_${entry.key}_${fields?.join(',') ?? 'all'}';
          await _cacheService.put(cacheKey, entry.value,
              config: CacheConfig(ttl: _config.fundDetailCacheTTL));
        }
      }

      _recordMetrics('getBatchFunds', stopwatch.elapsed);
      _recordRequestCount('getBatchFunds');

      developer.log(
          '✅ 批量获取完成: ${results.length}/${fundCodes.length}只基金 [请求ID: $requestId]',
          name: 'UnifiedDataSourceManager');

      return fundCodes
          .map((code) => results[code])
          .where((fund) => fund != null)
          .cast<Fund>()
          .toList();
    } catch (e) {
      developer.log('❌ 批量获取基金数据失败 [请求ID: $requestId]: $e',
          name: 'UnifiedDataSourceManager', level: 1000);
      _recordMetrics('getBatchFunds_error', stopwatch.elapsed);
      rethrow;
    } finally {
      _activeRequests.remove(requestId);
      stopwatch.stop();
    }
  }

  // ========================================================================
  // 实时数据流接口实现
  // ========================================================================

  @override
  Stream<FundData> getRealTimeData(
    String fundCode, {
    List<String>? fields,
  }) {
    _ensureInitialized();

    developer.log('📡 开始实时数据流: $fundCode', name: 'UnifiedDataSourceManager');

    // TODO: 实现WebSocket或SSE连接
    // 这里返回一个模拟的流
    return Stream.periodic(
      const Duration(seconds: 5),
      (count) => FundData(
        fundCode: fundCode,
        fields: {
          'timestamp': DateTime.now().toIso8601String(),
          'mockData': true,
          'updateCount': count,
        },
        timestamp: DateTime.now(),
        version: '1.0.0',
      ),
    );
  }

  @override
  Stream<List<FundData>> getBatchRealTimeData(List<String> fundCodes) {
    _ensureInitialized();

    developer.log('📡 开始批量实时数据流: ${fundCodes.length}只基金',
        name: 'UnifiedDataSourceManager');

    // TODO: 实现批量实时数据流
    return Stream.periodic(
      const Duration(seconds: 10),
      (count) => fundCodes
          .map((code) => FundData(
                fundCode: code,
                fields: {
                  'timestamp': DateTime.now().toIso8601String(),
                  'mockData': true,
                  'updateCount': count,
                },
                timestamp: DateTime.now(),
                version: '1.0.0',
              ))
          .toList(),
    );
  }

  // ========================================================================
  // 缓存管理接口实现
  // ========================================================================

  @override
  Future<void> preloadData(
    List<String> fundCodes, {
    PreloadPriority priority = PreloadPriority.normal,
  }) async {
    _ensureInitialized();

    developer.log('🚀 开始预加载数据: ${fundCodes.length}只基金 [优先级: $priority]',
        name: 'UnifiedDataSourceManager');

    try {
      // 根据优先级确定并发数
      final concurrency = _getConcurrencyForPriority(priority);

      // 分批处理
      for (int i = 0; i < fundCodes.length; i += concurrency) {
        final batch = fundCodes.skip(i).take(concurrency).toList();

        await Future.wait(
          batch.map((code) => _preloadSingleFund(code)),
          eagerError: false, // 不因为单个失败而影响整体
        );
      }

      developer.log('✅ 预加载完成', name: 'UnifiedDataSourceManager');
    } catch (e) {
      developer.log('❌ 预加载失败: $e',
          name: 'UnifiedDataSourceManager', level: 1000);
    }
  }

  @override
  Future<void> performSmartWarmup() async {
    _ensureInitialized();

    developer.log('🔥 开始智能预热缓存', name: 'UnifiedDataSourceManager');

    try {
      // 1. 获取热门基金
      final popularFunds = await _getPopularFunds();

      // 2. 预加载热门基金
      await preloadData(popularFunds, priority: PreloadPriority.high);

      // 3. 预加载排行榜数据
      await _preloadRankingData();

      // 4. 预加载筛选选项
      await _preloadFilterOptions();

      developer.log('✅ 智能预热完成', name: 'UnifiedDataSourceManager');
    } catch (e) {
      developer.log('❌ 智能预热失败: $e',
          name: 'UnifiedDataSourceManager', level: 1000);
    }
  }

  @override
  Future<void> clearCache({String? pattern}) async {
    _ensureInitialized();

    try {
      if (pattern != null) {
        await _cacheService.removeByPattern(pattern);
        developer.log('🧹 清除匹配模式的缓存: $pattern',
            name: 'UnifiedDataSourceManager');
      } else {
        await _cacheService.clear();
        developer.log('🧹 清除所有缓存', name: 'UnifiedDataSourceManager');
      }
    } catch (e) {
      developer.log('❌ 清除缓存失败: $e',
          name: 'UnifiedDataSourceManager', level: 1000);
      rethrow;
    }
  }

  @override
  Future<CacheStatistics> getCacheStatistics() async {
    _ensureInitialized();

    try {
      final stats = await _cacheService.getStatistics();

      return CacheStatistics(
        totalCount: stats.totalCount,
        validCount: stats.validCount,
        expiredCount: stats.expiredCount,
        totalSize: stats.totalSize,
        compressedSavings: stats.compressedSavings,
        hitRate: stats.hitRate,
        missRate: stats.missRate,
        averageResponseTime: stats.averageResponseTime,
        tagCounts: stats.tagCounts,
        priorityCounts: stats.priorityCounts,
      );
    } catch (e) {
      developer.log('❌ 获取缓存统计失败: $e',
          name: 'UnifiedDataSourceManager', level: 1000);
      rethrow;
    }
  }

  // ========================================================================
  // 数据同步接口实现
  // ========================================================================

  @override
  Future<DataSyncResult> syncData({
    DataSyncType syncType = DataSyncType.incremental,
    bool forceFullSync = false,
  }) async {
    _ensureInitialized();

    final requestId = _generateRequestId('syncData');
    final stopwatch = Stopwatch()..start();

    try {
      developer.log(
          '🔄 开始数据同步 [类型: $syncType, 强制全量: $forceFullSync] [请求ID: $requestId]',
          name: 'UnifiedDataSourceManager');

      final effectiveSyncType = forceFullSync ? DataSyncType.full : syncType;

      // 执行同步
      final result = await _consistencyManager.performIncrementalSync(
        syncScope: _mapSyncTypeToScope(effectiveSyncType),
        syncDirection: SyncDirection.bidirectional,
      );

      // 转换为统一同步结果格式
      final syncResult = DataSyncResult(
        success: result.success,
        syncedItemCount: result.changes.length,
        addedItemCount: result.changes
            .where((c) => c.changeType == ChangeType.added)
            .length,
        updatedItemCount: result.changes
            .where((c) => c.changeType == ChangeType.updated)
            .length,
        deletedItemCount: result.changes
            .where((c) => c.changeType == ChangeType.deleted)
            .length,
        duration: stopwatch.elapsed,
        error: result.error,
        timestamp: DateTime.now(),
      );

      developer.log('✅ 数据同步完成 [请求ID: $requestId]',
          name: 'UnifiedDataSourceManager');

      return syncResult;
    } catch (e) {
      developer.log('❌ 数据同步失败 [请求ID: $requestId]: $e',
          name: 'UnifiedDataSourceManager', level: 1000);

      return DataSyncResult(
        success: false,
        syncedItemCount: 0,
        addedItemCount: 0,
        updatedItemCount: 0,
        deletedItemCount: 0,
        duration: stopwatch.elapsed,
        error: e.toString(),
        timestamp: DateTime.now(),
      );
    } finally {
      stopwatch.stop();
    }
  }

  @override
  Future<DataConsistencyReport> validateDataConsistency() async {
    _ensureInitialized();

    try {
      developer.log('🔍 开始数据一致性验证', name: 'UnifiedDataSourceManager');

      final validationResult =
          await _consistencyManager.validateDataConsistency();

      final report = DataConsistencyReport(
        isConsistent: validationResult.isValid,
        inconsistentItemCount: validationResult.inconsistentItemsCount,
        totalItemCount: validationResult.totalItemsChecked,
        inconsistentFundCodes: validationResult.inconsistencies
            .map((item) => '${item.itemType}:${item.itemId}')
            .toList(),
        recommendedActions:
            _mapInconsistenciesToActions(validationResult.inconsistencies),
        checkTime: validationResult.validationTime,
      );

      developer.log('✅ 数据一致性验证完成', name: 'UnifiedDataSourceManager');

      return report;
    } catch (e) {
      developer.log('❌ 数据一致性验证失败: $e',
          name: 'UnifiedDataSourceManager', level: 1000);
      rethrow;
    }
  }

  @override
  Future<IncrementalSyncResult> performIncrementalSync({
    DateTime? since,
    String? lastVersion,
  }) async {
    _ensureInitialized();

    try {
      developer.log('🔄 开始增量同步', name: 'UnifiedDataSourceManager');

      final result = await _consistencyManager.performIncrementalSync(
        lastSyncTime: since,
      );

      return result;
    } catch (e) {
      developer.log('❌ 增量同步失败: $e',
          name: 'UnifiedDataSourceManager', level: 1000);
      rethrow;
    }
  }

  // ========================================================================
  // 健康检查和监控接口实现
  // ========================================================================

  @override
  Future<DataSourceHealthReport> getHealthReport() async {
    _ensureInitialized();

    try {
      // 1. 获取各组件健康状态
      final cacheStats = await _cacheService.getStatistics();
      final routerHealth = await _dataRouter.getRouteHealthReport();
      final consistencyMetrics =
          await _consistencyManager.getConsistencyMetrics();
      final dataSourceStatus = _dataSourceSwitcher.getStatusReport();

      // 2. 检查组件健康状态
      final componentHealth = <String, ComponentHealth>{
        'cache': ComponentHealth(
          componentName: '缓存服务',
          isHealthy: cacheStats.hitRate > 0.3,
          responseTime: cacheStats.averageResponseTime,
          lastSuccessTime: DateTime.now(),
          errorCount: 0,
        ),
        'router': ComponentHealth(
          componentName: '数据路由器',
          isHealthy: routerHealth.isHealthy,
          responseTime: routerHealth.performance.averageRoutingTime,
          lastSuccessTime: DateTime.now(),
          errorCount: routerHealth.issues.length,
        ),
        'consistency': ComponentHealth(
          componentName: '一致性管理器',
          isHealthy: consistencyMetrics.overallConsistencyRate > 0.9,
          responseTime: consistencyMetrics.averageResolutionTime.inMilliseconds
              .toDouble(),
          lastSuccessTime: DateTime.now(),
          errorCount: consistencyMetrics.conflictDetectionCount,
        ),
        'dataSource': ComponentHealth(
          componentName: '数据源',
          isHealthy: dataSourceStatus.currentSource.healthStatus ==
              HealthStatus.healthy,
          responseTime: dataSourceStatus.averageResponseTime,
          lastSuccessTime: DateTime.now(),
          errorCount: dataSourceStatus.errorCount,
        ),
      };

      // 3. 检查活跃连接
      final activeConnections = _activeRequests.length;

      // 4. 收集健康问题
      final issues = <HealthIssue>[];

      for (final entry in componentHealth.entries) {
        if (!entry.value.isHealthy) {
          issues.add(HealthIssue(
            severity: IssueSeverity.warning,
            description: '${entry.value.componentName} 状态不健康',
            affectedComponent: entry.key,
            suggestedSolution: '检查 ${entry.value.componentName} 配置和运行状态',
          ));
        }
      }

      if (activeConnections > _config.maxActiveConnections) {
        issues.add(HealthIssue(
          severity: IssueSeverity.warning,
          description: '活跃连接数过多: $activeConnections',
          affectedComponent: 'connection',
          suggestedSolution: '检查并发控制配置',
        ));
      }

      final isHealthy =
          issues.every((issue) => issue.severity != IssueSeverity.critical);

      return DataSourceHealthReport(
        isHealthy: isHealthy,
        componentHealth: componentHealth,
        activeConnections: activeConnections,
        lastCheckTime: DateTime.now(),
        issues: issues,
      );
    } catch (e) {
      developer.log('❌ 获取健康报告失败: $e',
          name: 'UnifiedDataSourceManager', level: 1000);
      rethrow;
    }
  }

  @override
  Future<DataSourceMetrics> getPerformanceMetrics() async {
    _ensureInitialized();

    try {
      final cacheStats = await _cacheService.getStatistics();
      final routeStats = await _dataRouter.getRouteStatistics();

      return DataSourceMetrics(
        averageResponseTime: _calculateAverageResponseTime(),
        successRate: _calculateSuccessRate(),
        requestsPerSecond: _calculateRequestsPerSecond(),
        cacheHitRate: cacheStats.hitRate,
        dataTransferVolume: 0, // TODO: 实现数据传输量统计
        activeConnections: _activeRequests.length,
        errorCount: _requestCounts['errors'] ?? 0,
      );
    } catch (e) {
      developer.log('❌ 获取性能指标失败: $e',
          name: 'UnifiedDataSourceManager', level: 1000);
      rethrow;
    }
  }

  @override
  Future<SelfCheckResult> performSelfCheck() async {
    _ensureInitialized();

    final stopwatch = Stopwatch()..start();

    try {
      developer.log('🔍 开始自检', name: 'UnifiedDataSourceManager');

      final checkResults = <String, CheckItemResult>{};
      double totalScore = 0.0;
      int checkCount = 0;

      // 1. 缓存服务检查
      try {
        final cacheStats = await _cacheService.getStatistics();
        final cacheScore = cacheStats.hitRate * 100;
        checkResults['cache'] = CheckItemResult(
          itemName: '缓存服务',
          passed: cacheScore > 30,
          score: cacheScore,
          details: '命中率: ${(cacheStats.hitRate * 100).toStringAsFixed(1)}%',
        );
        totalScore += cacheScore;
        checkCount++;
      } catch (e) {
        checkResults['cache'] = CheckItemResult(
          itemName: '缓存服务',
          passed: false,
          score: 0,
          details: '检查失败: $e',
        );
      }

      // 2. 数据路由器检查
      try {
        final routerHealth = await _dataRouter.getRouteHealthReport();
        final routerScore = routerHealth.isHealthy ? 100.0 : 50.0;
        checkResults['router'] = CheckItemResult(
          itemName: '数据路由器',
          passed: routerHealth.isHealthy,
          score: routerScore,
          details: routerHealth.isHealthy
              ? '运行正常'
              : '存在 ${routerHealth.issues.length} 个问题',
        );
        totalScore += routerScore;
        checkCount++;
      } catch (e) {
        checkResults['router'] = CheckItemResult(
          itemName: '数据路由器',
          passed: false,
          score: 0,
          details: '检查失败: $e',
        );
      }

      // 3. 数据一致性检查
      try {
        final consistencyReport = await validateDataConsistency();
        final consistencyScore = consistencyReport.consistencyPercentage * 100;
        checkResults['consistency'] = CheckItemResult(
          itemName: '数据一致性',
          passed: consistencyReport.isConsistent,
          score: consistencyScore,
          details:
              '一致性率: ${(consistencyReport.consistencyPercentage * 100).toStringAsFixed(1)}%',
        );
        totalScore += consistencyScore;
        checkCount++;
      } catch (e) {
        checkResults['consistency'] = CheckItemResult(
          itemName: '数据一致性',
          passed: false,
          score: 0,
          details: '检查失败: $e',
        );
      }

      final overallScore = checkCount > 0 ? totalScore / checkCount : 0.0;
      final passed = overallScore >= 70 &&
          checkResults.values.every((result) => result.passed);

      stopwatch.stop();

      return SelfCheckResult(
        passed: passed,
        checkResults: checkResults,
        overallScore: overallScore,
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      developer.log('❌ 自检失败: $e',
          name: 'UnifiedDataSourceManager', level: 1000);
      return SelfCheckResult(
        passed: false,
        checkResults: {},
        overallScore: 0.0,
        duration: stopwatch.elapsed,
      );
    }
  }

  // ========================================================================
  // 私有辅助方法
  // ========================================================================

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
          'UnifiedDataSourceManager not initialized. Call initialize() first.');
    }
  }

  String _generateRequestId(String operation) {
    return '${operation}_${++_requestIdCounter}_${DateTime.now().millisecondsSinceEpoch}';
  }

  String _generateSearchCacheKey(FundSearchCriteria criteria) {
    final parts = [
      'search',
      criteria.keyword ?? '',
      criteria.fundTypes?.join(',') ?? '',
      criteria.companies?.join(',') ?? '',
      criteria.minReturn?.toString() ?? '',
      criteria.maxReturn?.toString() ?? '',
    ];
    return parts.join('|');
  }

  String _generateRankingCacheKey(
      RankingCriteria criteria, int page, int pageSize) {
    final parts = [
      'ranking',
      criteria.rankingType.name,
      criteria.rankingPeriod.name,
      criteria.fundType ?? '',
      criteria.company ?? '',
      page.toString(),
      pageSize.toString(),
    ];
    return parts.join('|');
  }

  Future<T?> _tryGetFromCache<T>(String prefix, dynamic criteria) async {
    try {
      final cacheKey = '${prefix}_${criteria.hashCode}';
      return await _cacheService.get<T>(cacheKey);
    } catch (e) {
      developer.log('⚠️ 缓存读取失败: $e', name: 'UnifiedDataSourceManager');
      return null;
    }
  }

  Future<void> _cacheData<T>(String prefix, dynamic criteria, T data) async {
    try {
      final cacheKey = '${prefix}_${criteria.hashCode}';
      await _cacheService.put(cacheKey, data,
          config: CacheConfig(ttl: _config.defaultCacheTTL));
    } catch (e) {
      developer.log('⚠️ 缓存写入失败: $e', name: 'UnifiedDataSourceManager');
    }
  }

  Future<T> _fetchFromSelectedSource<T>(
    SelectedDataSource selectedSource,
    DataOperation operation,
    Future<T> Function() fetchFunction,
    String requestId,
  ) async {
    try {
      return await fetchFunction();
    } catch (e) {
      developer.log('⚠️ 数据源 ${selectedSource.dataSource.name} 请求失败，尝试故障转移: $e',
          name: 'UnifiedDataSourceManager');

      // 尝试故障转移到其他数据源
      final failoverResult = await _dataRouter.handleDataSourceFailure(
        selectedSource.dataSource,
        error: e,
        context: RequestContext(
          requestId: requestId,
          source: RequestSource.desktop,
          priority: operation.priority,
          timeout: _config.defaultTimeout,
        ),
      );

      if (failoverResult.success && failoverResult.targetSource != null) {
        developer.log('🔄 故障转移到: ${failoverResult.targetSource!.name}',
            name: 'UnifiedDataSourceManager');
        // 重新从新的数据源获取数据
        return await fetchFunction();
      } else {
        rethrow;
      }
    }
  }

  Future<T> _performFailover<T>(String operation,
      Future<T> Function() retryFunction, String requestId) async {
    try {
      developer.log('🔄 执行故障转移重试 [操作: $operation] [请求ID: $requestId]',
          name: 'UnifiedDataSourceManager');
      return await retryFunction();
    } catch (e) {
      developer.log('❌ 故障转移也失败了: $e',
          name: 'UnifiedDataSourceManager', level: 1000);
      rethrow;
    }
  }

  void _recordMetrics(String operation, Duration duration) {
    _performanceMetrics.putIfAbsent(operation, () => []).add(duration);

    // 限制每个操作最多保留1000个记录
    if (_performanceMetrics[operation]!.length > 1000) {
      _performanceMetrics[operation] =
          _performanceMetrics[operation]!.skip(500).toList();
    }
  }

  void _recordRequestCount(String operation) {
    _requestCounts[operation] = (_requestCounts[operation] ?? 0) + 1;
  }

  void _cleanupOldMetrics() {
    final cutoffTime = DateTime.now().subtract(_config.metricsRetentionPeriod);

    for (final entry in _performanceMetrics.entries) {
      // 这里应该基于时间清理，简化实现基于数量清理
      if (entry.value.length > 500) {
        _performanceMetrics[entry.key] = entry.value.skip(250).toList();
      }
    }
  }

  double _calculateAverageResponseTime() {
    if (_performanceMetrics.isEmpty) return 0.0;

    final allDurations =
        _performanceMetrics.values.expand((durations) => durations).toList();
    if (allDurations.isEmpty) return 0.0;

    final totalMs = allDurations.fold<int>(
        0, (sum, duration) => sum + duration.inMilliseconds);
    return totalMs / allDurations.length;
  }

  double _calculateSuccessRate() {
    final totalRequests =
        _requestCounts.values.fold<int>(0, (sum, count) => sum + count);
    final errorRequests = _requestCounts['errors'] ?? 0;

    if (totalRequests == 0) return 1.0;
    return (totalRequests - errorRequests) / totalRequests;
  }

  double _calculateRequestsPerSecond() {
    // 简化实现，基于最近的请求计数估算
    final recentRequests =
        _requestCounts.values.fold<int>(0, (sum, count) => sum + count);
    return recentRequests / 60.0; // 假设是1分钟内的请求
  }

  int _getConcurrencyForPriority(PreloadPriority priority) {
    switch (priority) {
      case PreloadPriority.urgent:
        return _config.maxConcurrency;
      case PreloadPriority.high:
        return (_config.maxConcurrency * 0.75).round();
      case PreloadPriority.normal:
        return (_config.maxConcurrency * 0.5).round();
      case PreloadPriority.low:
        return (_config.maxConcurrency * 0.25).round();
    }
  }

  Future<void> _preloadSingleFund(String fundCode) async {
    try {
      // 预加载基金详情
      await getBatchFunds([fundCode]);
    } catch (e) {
      developer.log('⚠️ 预加载基金 $fundCode 失败: $e',
          name: 'UnifiedDataSourceManager');
    }
  }

  Future<List<String>> _getPopularFunds() async {
    // TODO: 实现获取热门基金的逻辑
    // 这里返回一些热门基金代码作为示例
    return ['000001', '110022', '161725', '000002', '110011'];
  }

  Future<void> _preloadRankingData() async {
    try {
      // 预加载各种类型的排行榜
      final rankingTypes = [
        RankingType.byType,
        RankingType.byCompany,
        RankingType.overall
      ];
      final fundTypes = ['股票型', '混合型', '债券型'];

      for (final rankingType in rankingTypes) {
        for (final fundType in fundTypes) {
          final criteria = RankingCriteria(
            rankingType: rankingType,
            rankingPeriod: RankingPeriod.daily,
            fundType: fundType,
          );
          await getFundRankings(criteria, page: 1, pageSize: 20);
        }
      }
    } catch (e) {
      developer.log('⚠️ 预加载排行榜数据失败: $e', name: 'UnifiedDataSourceManager');
    }
  }

  Future<void> _preloadFilterOptions() async {
    // TODO: 实现预加载筛选选项
  }

  SyncScope _mapSyncTypeToScope(DataSyncType syncType) {
    switch (syncType) {
      case DataSyncType.full:
        return SyncScope.all;
      case DataSyncType.incremental:
        return SyncScope.incremental;
      case DataSyncType.selective:
        return SyncScope.selective;
    }
  }

  List<RecommendedAction> _mapInconsistenciesToActions(
      List<InconsistencyDetail> inconsistencies) {
    return inconsistencies.map((inconsistency) {
      ActionType actionType;
      ActionPriority priority;

      switch (inconsistency.inconsistencyType) {
        case InconsistencyType.valueMismatch:
          actionType = ActionType.refreshCache;
          priority = inconsistency.severity == Severity.critical
              ? ActionPriority.high
              : ActionPriority.medium;
          break;
        case InconsistencyType.missingData:
          actionType = ActionType.resync;
          priority = ActionPriority.high;
          break;
        case InconsistencyType.versionConflict:
          actionType = ActionType.repairData;
          priority = ActionPriority.medium;
          break;
        default:
          actionType = ActionType.refreshCache;
          priority = ActionPriority.low;
      }

      return RecommendedAction(
        type: actionType,
        description:
            '修复 ${inconsistency.itemType}:${inconsistency.itemId} 的 ${inconsistency.inconsistencyType}',
        affectedFundCodes: [
          '${inconsistency.itemType}:${inconsistency.itemId}'
        ],
        priority: priority,
      );
    }).toList();
  }

  // 事件处理器
  void _handleDataSourceSwitched(DataSourceSwitchedEvent event) {
    developer.log(
        '🔄 数据源已切换: ${event.oldSource.name} -> ${event.newSource.name}',
        name: 'UnifiedDataSourceManager');
  }

  void _handleConflictDetected(DataConflict conflict) {
    developer.log('⚠️ 检测到数据冲突: ${conflict.conflictId}',
        name: 'UnifiedDataSourceManager');
  }

  void _handleSyncCompleted(SyncCompletedEvent event) {
    developer.log('✅ 数据同步完成: ${event.syncResult.syncedItemCount} 项',
        name: 'UnifiedDataSourceManager');
  }

  // 数据源特定方法（需要根据实际的数据源实现来调整）
  Future<List<Fund>> _fetchFundsFromSource(
      FundSearchCriteria? criteria, DataSource dataSource) async {
    // TODO: 根据dataSource类型调用相应的数据获取方法
    if (dataSource.type == DataSourceType.localCache) {
      return await _localDataSource.getCachedFundList();
    } else {
      return await _remoteDataSource.getFundList();
    }
  }

  Future<List<Fund>> _searchFundsFromSource(
      FundSearchCriteria criteria, DataSource dataSource) async {
    // TODO: 实现搜索逻辑
    return [];
  }

  Future<PaginatedRankingResult> _fetchRankingsFromSource(
    RankingCriteria criteria,
    int page,
    int pageSize,
    DataSource dataSource,
  ) async {
    // TODO: 实现排行榜获取逻辑
    return PaginatedRankingResult(
      rankings: const [],
      totalCount: 0,
      currentPage: page,
      pageSize: pageSize,
      totalPages: 0,
      hasNextPage: false,
      hasPreviousPage: false,
      hasMore: false,
    );
  }

  Future<Map<String, Fund>> _fetchBatchFundsFromSource(
    List<String> fundCodes,
    List<String>? fields,
  ) async {
    // TODO: 实现批量获取逻辑
    return {};
  }

  /// 获取配置
  UnifiedDataSourceConfig get config => _config;

  /// 释放资源
  Future<void> dispose() async {
    try {
      developer.log('🔒 开始释放统一数据源管理器资源...', name: 'UnifiedDataSourceManager');

      _metricsCleanupTimer?.cancel();
      _activeRequests.clear();
      _performanceMetrics.clear();
      _requestCounts.clear();

      _isInitialized = false;
      developer.log('✅ 统一数据源管理器资源释放完成', name: 'UnifiedDataSourceManager');
    } catch (e) {
      developer.log('❌ 释放统一数据源管理器资源失败: $e',
          name: 'UnifiedDataSourceManager', level: 1000);
    }
  }
}

// ========================================================================
// 配置和辅助类
// ========================================================================

/// 统一数据源管理器配置
class UnifiedDataSourceConfig {
  final Duration defaultTimeout;
  final Duration defaultCacheTTL;
  final Duration searchCacheTTL;
  final Duration rankingCacheTTL;
  final Duration fundDetailCacheTTL;
  final Duration defaultMaxDataAge;
  final int maxConcurrency;
  final int maxActiveConnections;
  final Duration metricsCleanupInterval;
  final Duration metricsRetentionPeriod;

  const UnifiedDataSourceConfig({
    this.defaultTimeout = const Duration(seconds: 30),
    this.defaultCacheTTL = const Duration(minutes: 15),
    this.searchCacheTTL = const Duration(minutes: 10),
    this.rankingCacheTTL = const Duration(minutes: 5),
    this.fundDetailCacheTTL = const Duration(minutes: 30),
    this.defaultMaxDataAge = const Duration(minutes: 10),
    this.maxConcurrency = 10,
    this.maxActiveConnections = 100,
    this.metricsCleanupInterval = const Duration(hours: 1),
    this.metricsRetentionPeriod = const Duration(days: 7),
  });

  factory UnifiedDataSourceConfig.defaultConfig() =>
      const UnifiedDataSourceConfig();

  factory UnifiedDataSourceConfig.development() =>
      const UnifiedDataSourceConfig(
        defaultTimeout: Duration(seconds: 10),
        defaultCacheTTL: Duration(minutes: 5),
        searchCacheTTL: Duration(minutes: 3),
        rankingCacheTTL: Duration(minutes: 2),
        fundDetailCacheTTL: Duration(minutes: 10),
        defaultMaxDataAge: Duration(minutes: 5),
        maxConcurrency: 5,
        maxActiveConnections: 50,
        metricsCleanupInterval: Duration(minutes: 30),
        metricsRetentionPeriod: Duration(hours: 6),
      );

  factory UnifiedDataSourceConfig.production() => const UnifiedDataSourceConfig(
        defaultTimeout: Duration(seconds: 60),
        defaultCacheTTL: Duration(hours: 1),
        searchCacheTTL: Duration(minutes: 30),
        rankingCacheTTL: Duration(minutes: 15),
        fundDetailCacheTTL: Duration(hours: 2),
        defaultMaxDataAge: Duration(minutes: 30),
        maxConcurrency: 20,
        maxActiveConnections: 200,
        metricsCleanupInterval: Duration(hours: 2),
        metricsRetentionPeriod: Duration(days: 30),
      );
}

/// 占位符类（需要根据实际实现定义）
abstract class ILocalDataSource {
  Future<List<Fund>> getCachedFundList();
}

abstract class IRemoteDataSource {
  Future<List<Fund>> getFundList();
}

/// 同步完成事件
class SyncCompletedEvent {
  final dynamic syncResult;

  SyncCompletedEvent({required this.syncResult});
}
