import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../../features/fund/domain/entities/fund.dart';
import '../../../features/fund/domain/entities/fund_filter_criteria.dart';
import '../../../features/fund/domain/entities/fund_search_criteria.dart';
import '../../../features/fund/domain/entities/fund_ranking.dart';
import '../../cache/unified_cache_manager.dart';
import '../../cache/interfaces/i_unified_cache_service.dart';
import '../../network/intelligent_data_source_switcher.dart';
import '../../../features/fund/presentation/fund_exploration/domain/data/services/data_sync_manager.dart';
import '../../../features/fund/presentation/fund_exploration/domain/data/services/smart_cache_manager.dart';
import '../../../features/fund/presentation/fund_exploration/domain/data/services/optimized_fund_service.dart';
import '../../../features/fund/data/services/intelligent_preload_service.dart';

/// 数据层协调器
///
/// 整合所有数据管理组件，提供统一的数据访问接口
/// 负责协调各个组件间的协作和数据流
class DataLayerCoordinator {
  // 核心组件依赖
  final UnifiedCacheManager _cacheManager;
  final IntelligentDataSourceSwitcher _dataSourceSwitcher;
  final DataSyncManager _syncManager;
  final SmartCacheManager _smartCacheManager;
  final OptimizedFundService _fundService;
  final IntelligentPreloadService _preloadService;

  // 状态管理
  bool _isInitialized = false;

  /// 获取初始化状态（测试用）
  bool get isInitialized => _isInitialized;

  /// 获取初始化状态（公开访问，用于测试）
  bool get isInitializedPublic => _isInitialized;
  final Map<String, StreamController> _eventControllers = {};
  Timer? _healthCheckTimer;

  // 配置
  final DataLayerConfig _config;

  /// 单例实例
  static DataLayerCoordinator? _instance;
  static DataLayerCoordinator get instance {
    _instance ??= DataLayerCoordinator._create();
    return _instance!;
  }

  DataLayerCoordinator._({
    required UnifiedCacheManager cacheManager,
    required IntelligentDataSourceSwitcher dataSourceSwitcher,
    required DataSyncManager syncManager,
    required SmartCacheManager smartCacheManager,
    required OptimizedFundService fundService,
    required IntelligentPreloadService preloadService,
    DataLayerConfig? config,
  })  : _cacheManager = cacheManager,
        _dataSourceSwitcher = dataSourceSwitcher,
        _syncManager = syncManager,
        _smartCacheManager = smartCacheManager,
        _fundService = fundService,
        _preloadService = preloadService,
        _config = config ?? DataLayerConfig.defaultConfig();

  /// 创建协调器实例
  factory DataLayerCoordinator._create() {
    // 这里需要实际的依赖注入
    // 为了演示，使用默认构造
    throw UnimplementedError(
        'DataLayerCoordinator requires dependency injection');
  }

  /// 使用依赖注入创建
  factory DataLayerCoordinator.withDependencies({
    required UnifiedCacheManager cacheManager,
    required IntelligentDataSourceSwitcher dataSourceSwitcher,
    required DataSyncManager syncManager,
    required SmartCacheManager smartCacheManager,
    required OptimizedFundService fundService,
    required IntelligentPreloadService preloadService,
    DataLayerConfig? config,
  }) {
    return DataLayerCoordinator._(
      cacheManager: cacheManager,
      dataSourceSwitcher: dataSourceSwitcher,
      syncManager: syncManager,
      smartCacheManager: smartCacheManager,
      fundService: fundService,
      preloadService: preloadService,
      config: config,
    );
  }

  // ========================================================================
  // 初始化和生命周期管理
  // ========================================================================

  /// 初始化数据层协调器
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🔄 开始初始化数据层协调器...');

      // 1. 初始化各个组件
      await _initializeComponents();

      // 2. 设置组件间的协作关系
      await _setupComponentCoordination();

      // 3. 启动健康检查
      _startHealthCheck();

      // 4. 预热缓存
      await _performWarmup();

      _isInitialized = true;
      debugPrint('✅ 数据层协调器初始化完成');
    } catch (e) {
      debugPrint('❌ 数据层协调器初始化失败: $e');
      rethrow;
    }
  }

  /// 初始化各个组件
  Future<void> _initializeComponents() async {
    debugPrint('🔧 初始化数据层组件...');

    // 初始化缓存管理器
    if (!_cacheManager.isInitialized) {
      await _cacheManager.initialize();
    }

    // 初始化数据源切换器
    await _dataSourceSwitcher.initialize();

    // 初始化同步管理器
    await _syncManager.initialize();

    // 初始化智能缓存管理器
    await _smartCacheManager.initialize();

    // 初始化预加载服务
    await _preloadService.start();

    debugPrint('✅ 数据层组件初始化完成');
  }

  /// 设置组件间的协作关系
  Future<void> _setupComponentCoordination() async {
    debugPrint('🔗 设置组件协作关系...');

    // 设置数据源切换器事件监听
    _dataSourceSwitcher.events.listen(_handleDataSourceEvent);

    // 设置同步管理器状态监听
    // （这里需要根据实际的DataSyncManager实现来调整）

    debugPrint('✅ 组件协作关系设置完成');
  }

  /// 启动健康检查
  void _startHealthCheck() {
    _healthCheckTimer = Timer.periodic(_config.healthCheckInterval, (_) {
      _performHealthCheck();
    });
    debugPrint('💓 健康检查已启动');
  }

  /// 执行健康检查
  Future<void> _performHealthCheck() async {
    try {
      final healthReport = await getHealthReport();

      if (!healthReport.isHealthy) {
        debugPrint('⚠️ 数据层健康检查发现问题: ${healthReport.issues}');
        await _handleHealthIssues(healthReport.issues);
      }
    } catch (e) {
      debugPrint('❌ 健康检查执行失败: $e');
    }
  }

  /// 执行预热
  Future<void> _performWarmup() async {
    if (!_config.enableWarmup) return;

    try {
      debugPrint('🔥 开始数据层预热...');

      // 并行执行各种预热任务
      final warmupTasks = [
        _smartCacheManager.warmupCache(),
        _preloadService.preloadCommonData(),
      ];

      await Future.wait(warmupTasks);
      debugPrint('✅ 数据层预热完成');
    } catch (e) {
      debugPrint('⚠️ 数据层预热部分失败: $e');
    }
  }

  // ========================================================================
  // 统一数据访问接口
  // ========================================================================

  /// 获取基金列表
  Future<List<Fund>> getFunds({
    FundFilterCriteria? criteria,
    bool forceRefresh = false,
    Duration? timeout,
  }) async {
    _ensureInitialized();

    final operationStart = DateTime.now();
    String operationId = _generateOperationId('getFunds');

    try {
      debugPrint('📊 开始获取基金列表 [操作ID: $operationId]');

      // 1. 检查缓存（除非强制刷新）
      if (!forceRefresh) {
        final cacheKey = _generateCacheKey('funds', criteria);
        final cachedFunds = await _cacheManager.get<List<Fund>>(cacheKey);
        if (cachedFunds != null) {
          debugPrint('🎯 缓存命中: 基金列表 [操作ID: $operationId]');
          _recordOperationSuccess(operationId, operationStart);
          return cachedFunds;
        }
      }

      // 2. 从数据源获取
      debugPrint('🌐 从数据源获取基金列表 [操作ID: $operationId]');
      final funds = await _dataSourceSwitcher.executeRequest(
        (dio) async {
          // 这里应该调用实际的API
          // 暂时使用现有服务
          final fundDtos = await _fundService.getFundBasicInfo();
          return fundDtos.map((dto) => _convertDtoToFund(dto)).toList();
        },
        operationName: 'getFunds',
        timeout: timeout,
      );

      // 3. 缓存结果
      if (funds.isNotEmpty) {
        final cacheKey = _generateCacheKey('funds', criteria);
        await _cacheManager.put(cacheKey, funds);
        debugPrint('💾 基金列表已缓存 [操作ID: $operationId]');
      }

      debugPrint('✅ 基金列表获取完成: ${funds.length}条 [操作ID: $operationId]');
      _recordOperationSuccess(operationId, operationStart);
      return funds;
    } catch (e) {
      debugPrint('❌ 获取基金列表失败 [操作ID: $operationId]: $e');
      _recordOperationFailure(operationId, operationStart, e);
      rethrow;
    }
  }

  /// 搜索基金
  Future<List<Fund>> searchFunds(
    FundSearchCriteria criteria, {
    bool forceRefresh = false,
  }) async {
    _ensureInitialized();

    final operationStart = DateTime.now();
    String operationId = _generateOperationId('searchFunds');

    try {
      debugPrint('🔍 开始搜索基金 [操作ID: $operationId]');

      // 1. 生成搜索缓存键
      final cacheKey = _generateSearchCacheKey(criteria);

      // 2. 检查缓存
      if (!forceRefresh) {
        final cachedResults = await _cacheManager.get<List<Fund>>(cacheKey);
        if (cachedResults != null) {
          debugPrint('🎯 搜索缓存命中 [操作ID: $operationId]');
          _recordOperationSuccess(operationId, operationStart);
          return cachedResults;
        }
      }

      // 3. 记录搜索行为（用于预加载优化）
      _preloadService.recordFilterUsage(_convertSearchToFilter(criteria));

      // 4. 执行搜索
      debugPrint('🔍 执行基金搜索 [操作ID: $operationId]');
      final results = await _performSearch(criteria);

      // 5. 缓存搜索结果
      if (results.isNotEmpty) {
        await _cacheManager.put(cacheKey, results);
        debugPrint('💾 搜索结果已缓存 [操作ID: $operationId]');
      }

      debugPrint('✅ 基金搜索完成: ${results.length}条结果 [操作ID: $operationId]');
      _recordOperationSuccess(operationId, operationStart);
      return results;
    } catch (e) {
      debugPrint('❌ 基金搜索失败 [操作ID: $operationId]: $e');
      _recordOperationFailure(operationId, operationStart, e);
      rethrow;
    }
  }

  /// 获取基金排行榜
  Future<PaginatedRankingResult> getFundRankings(
    RankingCriteria criteria, {
    bool forceRefresh = false,
  }) async {
    _ensureInitialized();

    final operationStart = DateTime.now();
    String operationId = _generateOperationId('getFundRankings');

    try {
      debugPrint('🏆 开始获取基金排行榜 [操作ID: $operationId]');

      // 1. 生成缓存键
      final cacheKey = _generateRankingCacheKey(criteria);

      // 2. 检查缓存
      if (!forceRefresh) {
        final cachedRankings =
            await _cacheManager.get<PaginatedRankingResult>(cacheKey);
        if (cachedRankings != null) {
          debugPrint('🎯 排行榜缓存命中 [操作ID: $operationId]');
          _recordOperationSuccess(operationId, operationStart);
          return cachedRankings;
        }
      }

      // 3. 获取排行榜数据
      debugPrint('🏆 获取排行榜数据 [操作ID: $operationId]');
      final rankings = await _performRankingQuery(criteria);

      // 4. 缓存结果
      await _cacheManager.put(cacheKey, rankings);
      debugPrint('💾 排行榜数据已缓存 [操作ID: $operationId]');

      debugPrint('✅ 基金排行榜获取完成 [操作ID: $operationId]');
      _recordOperationSuccess(operationId, operationStart);
      return rankings;
    } catch (e) {
      debugPrint('❌ 获取基金排行榜失败 [操作ID: $operationId]: $e');
      _recordOperationFailure(operationId, operationStart, e);
      rethrow;
    }
  }

  /// 批量获取基金数据
  Future<Map<String, Fund>> getBatchFunds(
    List<String> fundCodes, {
    bool forceRefresh = false,
  }) async {
    _ensureInitialized();

    final operationStart = DateTime.now();
    String operationId = _generateOperationId('getBatchFunds');

    try {
      debugPrint('📦 开始批量获取基金数据 [操作ID: $operationId]');

      final results = <String, Fund>{};
      final codesToFetch = <String>[];

      // 1. 检查缓存
      if (!forceRefresh) {
        for (final code in fundCodes) {
          final cacheKey = 'fund_detail_$code';
          final cachedFund = await _cacheManager.get<Fund>(cacheKey);
          if (cachedFund != null) {
            results[code] = cachedFund;
          } else {
            codesToFetch.add(code);
          }
        }
      } else {
        codesToFetch.addAll(fundCodes);
      }

      // 2. 批量获取未缓存的基金
      if (codesToFetch.isNotEmpty) {
        debugPrint(
            '🌐 批量获取未缓存的基金: ${codesToFetch.length}只 [操作ID: $operationId]');

        // 这里可以实现真正的批量API调用
        for (final code in codesToFetch) {
          try {
            final fund = await _getSingleFundDetail(code);
            if (fund != null) {
              results[code] = fund;
              // 缓存单个基金
              await _cacheManager.put('fund_detail_$code', fund);
            }
          } catch (e) {
            debugPrint('⚠️ 获取基金 $code 详情失败: $e');
          }
        }
      }

      debugPrint(
          '✅ 批量获取完成: ${results.length}/${fundCodes.length}只基金 [操作ID: $operationId]');
      _recordOperationSuccess(operationId, operationStart);
      return results;
    } catch (e) {
      debugPrint('❌ 批量获取基金数据失败 [操作ID: $operationId]: $e');
      _recordOperationFailure(operationId, operationStart, e);
      rethrow;
    }
  }

  // ========================================================================
  // 缓存和同步管理
  // ========================================================================

  /// 刷新缓存
  Future<bool> refreshCache({FundFilterCriteria? criteria}) async {
    _ensureInitialized();

    try {
      debugPrint('🔄 开始刷新缓存...');

      // 1. 清除相关缓存
      if (criteria != null) {
        final cacheKey = _generateCacheKey('funds', criteria);
        await _cacheManager.remove(cacheKey);
      } else {
        // 清除所有基金相关缓存
        await _cacheManager.removeByPattern('funds_*');
        await _cacheManager.removeByPattern('fund_detail_*');
        await _cacheManager.removeByPattern('search_*');
        await _cacheManager.removeByPattern('ranking_*');
      }

      // 2. 强制同步数据
      final syncResults = await _syncManager.forceSyncAll();

      // 3. 预热常用数据
      if (_config.enableWarmupAfterRefresh) {
        await _performWarmup();
      }

      final success = syncResults.values.every((result) => result);
      debugPrint('${success ? '✅' : '⚠️'} 缓存刷新完成');
      return success;
    } catch (e) {
      debugPrint('❌ 缓存刷新失败: $e');
      return false;
    }
  }

  /// 清空所有缓存
  Future<void> clearAllCache() async {
    _ensureInitialized();

    try {
      debugPrint('🧹 开始清空所有缓存...');

      await _cacheManager.clear();
      await _smartCacheManager.clearAll();

      debugPrint('✅ 所有缓存已清空');
    } catch (e) {
      debugPrint('❌ 清空缓存失败: $e');
      rethrow;
    }
  }

  // ========================================================================
  // 监控和状态查询
  // ========================================================================

  /// 获取健康报告
  Future<DataLayerHealthReport> getHealthReport() async {
    final cacheStats = await _cacheManager.getStatistics();
    final syncStats = _syncManager.getSyncStats();
    final dataSourceStatus = _dataSourceSwitcher.getStatusReport();

    final issues = <String>[];

    // 检查缓存健康状态
    if (cacheStats.hitRate < 0.5) {
      issues.add('缓存命中率过低: ${(cacheStats.hitRate * 100).toStringAsFixed(1)}%');
    }

    // 检查同步健康状态
    final failedSyncs = syncStats['failedSyncs'] as int;
    if (failedSyncs > 0) {
      issues.add('存在失败的同步任务: $failedSyncs个');
    }

    // 检查数据源健康状态
    if (!dataSourceStatus.currentSource.isHealthy) {
      issues.add('当前数据源不健康: ${dataSourceStatus.currentSource.name}');
    }

    return DataLayerHealthReport(
      isHealthy: issues.isEmpty,
      issues: issues,
      cacheStatistics: cacheStats,
      syncStatistics: syncStats,
      dataSourceStatus: dataSourceStatus,
      timestamp: DateTime.now(),
    );
  }

  /// 获取性能指标
  Future<DataLayerPerformanceMetrics> getPerformanceMetrics() async {
    final cacheStats = await _cacheManager.getStatistics();
    final smartCacheStats = _smartCacheManager.getCacheStats();

    return DataLayerPerformanceMetrics(
      cacheHitRate: cacheStats.hitRate,
      cacheMissRate: cacheStats.missRate,
      averageResponseTime: cacheStats.averageResponseTime,
      smartCacheHitRate: smartCacheStats['hitRate'] as double,
      memoryCacheSize: smartCacheStats['memoryCacheSize'] as int,
      timestamp: DateTime.now(),
    );
  }

  /// 获取事件流
  Stream<T> getEventStream<T>(String eventType) {
    _eventControllers.putIfAbsent(
      eventType,
      () => StreamController<T>.broadcast(),
    );
    return _eventControllers[eventType]!.stream.cast<T>();
  }

  // ========================================================================
  // 私有辅助方法
  // ========================================================================

  /// 确保已初始化
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
          'DataLayerCoordinator not initialized. Call initialize() first.');
    }
  }

  /// 生成操作ID
  String _generateOperationId(String operation) {
    return '${operation}_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// 生成缓存键
  String _generateCacheKey(String prefix, dynamic criteria) {
    if (criteria == null) return prefix;

    // 根据criteria生成唯一的键
    final criteriaHash = criteria.hashCode.toString();
    return '${prefix}_$criteriaHash';
  }

  /// 生成搜索缓存键
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

  /// 生成排行榜缓存键
  String _generateRankingCacheKey(RankingCriteria criteria) {
    final parts = [
      'ranking',
      criteria.rankingType.name,
      criteria.rankingPeriod.name,
      criteria.fundType ?? '',
      criteria.company ?? '',
      criteria.page.toString(),
      criteria.pageSize.toString(),
    ];
    return parts.join('|');
  }

  /// 处理数据源事件
  void _handleDataSourceEvent(DataSourceEvent event) {
    debugPrint('📡 数据源事件: ${event.runtimeType}');

    if (event is DataSourceSwitchedEvent) {
      // 广播数据源切换事件
      final controller = _eventControllers['dataSourceSwitched'];
      if (controller != null && !controller.isClosed) {
        controller.add(event);
      }
    }
  }

  /// 处理健康问题
  Future<void> _handleHealthIssues(List<String> issues) async {
    for (final issue in issues) {
      debugPrint('🔧 处理健康问题: $issue');

      // 根据具体问题采取相应措施
      if (issue.contains('缓存命中率过低')) {
        await _cacheManager.optimize();
      } else if (issue.contains('同步任务失败')) {
        await _syncManager.forceSyncAll();
      } else if (issue.contains('数据源不健康')) {
        // 数据源切换器会自动处理不健康的数据源
      }
    }
  }

  /// 执行搜索
  Future<List<Fund>> _performSearch(FundSearchCriteria criteria) async {
    // 这里应该实现实际的搜索逻辑
    // 暂时返回空列表
    return [];
  }

  /// 执行排行榜查询
  Future<PaginatedRankingResult> _performRankingQuery(
      RankingCriteria criteria) async {
    // 这里应该实现实际的排行榜查询逻辑
    // 暂时返回空结果
    return PaginatedRankingResult(
      rankings: const [],
      totalCount: 0,
      currentPage: criteria.page,
      pageSize: criteria.pageSize,
      totalPages: 0,
      hasNextPage: false,
      hasPreviousPage: false,
      hasMore: false,
    );
  }

  /// 获取单只基金详情
  Future<Fund?> _getSingleFundDetail(String fundCode) async {
    // 这里应该实现获取单只基金详情的逻辑
    return null;
  }

  /// DTO转换为Fund实体
  Fund _convertDtoToFund(dynamic dto) {
    // 这里应该实现DTO到Fund的转换
    return Fund(
      code: dto.fundCode ?? '',
      name: dto.fundName ?? '',
      type: dto.fundType ?? '',
      company: dto.fundCompany ?? '',
      lastUpdate: DateTime.now(),
    );
  }

  /// 搜索条件转换为筛选条件
  FundFilterCriteria _convertSearchToFilter(FundSearchCriteria searchCriteria) {
    return FundFilterCriteria(
      fundTypes: searchCriteria.fundTypes,
      companies: searchCriteria.companies,
    );
  }

  /// 记录操作成功
  void _recordOperationSuccess(String operationId, DateTime startTime) {
    final duration = DateTime.now().difference(startTime);
    debugPrint('✅ 操作成功 [操作ID: $operationId] 耗时: ${duration.inMilliseconds}ms');
  }

  /// 记录操作失败
  void _recordOperationFailure(
      String operationId, DateTime startTime, dynamic error) {
    final duration = DateTime.now().difference(startTime);
    debugPrint(
        '❌ 操作失败 [操作ID: $operationId] 耗时: ${duration.inMilliseconds}ms 错误: $error');
  }

  /// 释放资源
  Future<void> dispose() async {
    try {
      debugPrint('🔒 开始释放数据层协调器资源...');

      _healthCheckTimer?.cancel();

      for (final controller in _eventControllers.values) {
        await controller.close();
      }
      _eventControllers.clear();

      _preloadService.stop();
      _syncManager.dispose();
      await _smartCacheManager.dispose();
      await _cacheManager.close();
      _dataSourceSwitcher.dispose();

      _isInitialized = false;
      debugPrint('✅ 数据层协调器资源释放完成');
    } catch (e) {
      debugPrint('❌ 释放数据层协调器资源失败: $e');
    }
  }
}

// ========================================================================
// 配置和数据类
// ========================================================================

/// 数据层配置
class DataLayerConfig {
  final Duration healthCheckInterval;
  final bool enableWarmup;
  final bool enableWarmupAfterRefresh;
  final int maxConcurrentOperations;
  final Duration operationTimeout;

  const DataLayerConfig({
    this.healthCheckInterval = const Duration(minutes: 5),
    this.enableWarmup = true,
    this.enableWarmupAfterRefresh = true,
    this.maxConcurrentOperations = 10,
    this.operationTimeout = const Duration(seconds: 30),
  });

  factory DataLayerConfig.defaultConfig() => const DataLayerConfig();

  factory DataLayerConfig.development() => const DataLayerConfig(
        healthCheckInterval: Duration(minutes: 1),
        enableWarmup: false,
        enableWarmupAfterRefresh: false,
        maxConcurrentOperations: 5,
        operationTimeout: Duration(seconds: 10),
      );

  factory DataLayerConfig.production() => const DataLayerConfig(
        healthCheckInterval: Duration(minutes: 10),
        enableWarmup: true,
        enableWarmupAfterRefresh: true,
        maxConcurrentOperations: 20,
        operationTimeout: Duration(seconds: 60),
      );
}

/// 数据层健康报告
class DataLayerHealthReport {
  final bool isHealthy;
  final List<String> issues;
  final CacheStatistics cacheStatistics;
  final Map<String, dynamic> syncStatistics;
  final dynamic dataSourceStatus;
  final DateTime timestamp;

  const DataLayerHealthReport({
    required this.isHealthy,
    required this.issues,
    required this.cacheStatistics,
    required this.syncStatistics,
    required this.dataSourceStatus,
    required this.timestamp,
  });
}

/// 数据层性能指标
class DataLayerPerformanceMetrics {
  final double cacheHitRate;
  final double cacheMissRate;
  final double averageResponseTime;
  final double smartCacheHitRate;
  final int memoryCacheSize;
  final DateTime timestamp;

  const DataLayerPerformanceMetrics({
    required this.cacheHitRate,
    required this.cacheMissRate,
    required this.averageResponseTime,
    required this.smartCacheHitRate,
    required this.memoryCacheSize,
    required this.timestamp,
  });
}
