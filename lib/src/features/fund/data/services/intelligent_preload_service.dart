import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/fund.dart';
import '../../domain/entities/fund_filter_criteria.dart';
import '../../domain/repositories/fund_repository.dart';
import '../../domain/usecases/optimized_fund_filter_usecase.dart';
import '../datasources/fund_local_data_source.dart';

/// 智能预加载服务
///
/// 提供以下功能：
/// - 基于用户行为的预测性预加载
/// - 常用筛选组合的预加载
/// - 筛选结果的增量更新
/// - 内存使用优化
class IntelligentPreloadService {
  final FundRepository _repository;
  final FundLocalDataSource _localDataSource;
  final OptimizedFundFilterUseCase _filterUseCase;

  // 预加载配置
  final Duration preloadInterval;
  final int maxPreloadItems;
  final Duration maxCacheAge;

  // 状态管理
  bool _isRunning = false;
  Timer? _preloadTimer;
  final Map<String, PreloadTask> _activeTasks = {};
  final Map<String, DateTime> _lastPreloadTimes = {};

  // 用户行为分析
  final Map<String, int> _filterUsageCount = {};
  final Map<String, DateTime> _filterLastUsed = {};
  final List<String> _recentFilters = [];

  // 性能监控
  final Map<String, dynamic> _performanceStats = {};

  IntelligentPreloadService(
    this._repository,
    this._localDataSource,
    this._filterUseCase, {
    this.preloadInterval = const Duration(minutes: 5),
    this.maxPreloadItems = 50,
    this.maxCacheAge = const Duration(hours: 1),
  });

  /// 启动智能预加载服务
  Future<void> start() async {
    if (_isRunning) return;

    _isRunning = true;
    _preloadTimer = Timer.periodic(preloadInterval, (_) => _performPreload());

    // 初始预加载常用数据
    await _preloadCommonData();

    _recordPerformance('service_started');
  }

  /// 停止智能预加载服务
  void stop() {
    if (!_isRunning) return;

    _isRunning = false;
    _preloadTimer?.cancel();
    _preloadTimer = null;

    // 取消所有活动任务
    for (final task in _activeTasks.values) {
      task.cancel();
    }
    _activeTasks.clear();

    _recordPerformance('service_stopped');
  }

  /// 记录筛选使用情况
  void recordFilterUsage(FundFilterCriteria criteria) {
    final filterKey = _generateFilterKey(criteria);

    // 更新使用计数
    _filterUsageCount[filterKey] = (_filterUsageCount[filterKey] ?? 0) + 1;
    _filterLastUsed[filterKey] = DateTime.now();

    // 维护最近使用的筛选列表
    _recentFilters.remove(filterKey);
    _recentFilters.insert(0, filterKey);
    if (_recentFilters.length > 20) {
      _recentFilters.removeLast();
    }

    // 触发即时预加载
    _triggerImmediatePreload(criteria);
  }

  /// 预加载指定的筛选条件
  Future<void> preloadFilter(FundFilterCriteria criteria) async {
    final filterKey = _generateFilterKey(criteria);

    if (_activeTasks.containsKey(filterKey)) {
      return; // 任务已在进行中
    }

    final task = PreloadTask(
      criteria: criteria,
      startTime: DateTime.now(),
      onCancel: () => _activeTasks.remove(filterKey),
    );

    _activeTasks[filterKey] = task;

    try {
      await _executePreloadTask(task);
      _lastPreloadTimes[filterKey] = DateTime.now();
      _recordPerformance('preload_success');
    } catch (e) {
      _recordPerformance('preload_error');
      // 预加载失败不影响主流程
    } finally {
      _activeTasks.remove(filterKey);
    }
  }

  /// 预加载热门筛选组合
  Future<void> preloadPopularFilters() async {
    final popularFilters = _getPopularFilters();

    final futures = <Future<void>>[];
    for (final criteria in popularFilters) {
      futures.add(preloadFilter(criteria));

      // 限制并发数量
      if (futures.length >= 3) {
        await Future.wait(futures.take(3));
        futures.removeRange(0, 3);
      }
    }

    await Future.wait(futures);
    _recordPerformance('preload_popular_filters');
  }

  /// 预加载用户可能感兴趣的筛选
  Future<void> preloadUserInterestFilters() async {
    final interestFilters = _generateInterestFilters();

    final futures = <Future<void>>[];
    for (final criteria in interestFilters) {
      futures.add(preloadFilter(criteria));

      if (futures.length >= 2) {
        await Future.wait(futures.take(2));
        futures.removeRange(0, 2);
      }
    }

    await Future.wait(futures);
    _recordPerformance('preload_interest_filters');
  }

  /// 增量更新筛选结果
  Future<void> incrementalUpdateFilter(FundFilterCriteria criteria) async {
    try {
      // 检查是否有缓存的筛选结果
      final cachedResults =
          await _localDataSource.getCachedFilteredFunds(criteria);
      if (cachedResults.isEmpty) {
        // 没有缓存，执行完整预加载
        await preloadFilter(criteria);
        return;
      }

      // 获取最新的基金数据
      final latestFunds = await _repository.getFundList();

      // 计算需要更新的差异
      final updatedResults =
          _calculateIncrementalUpdate(cachedResults, latestFunds, criteria);

      // 更新缓存
      if (updatedResults.isNotEmpty) {
        await _localDataSource.cacheFilteredFunds(criteria, updatedResults);
        _recordPerformance('incremental_update');
      }
    } catch (e) {
      _recordPerformance('incremental_update_error');
    }
  }

  /// 获取预加载统计信息
  Map<String, dynamic> getPreloadStatistics() {
    return {
      'is_running': _isRunning,
      'active_tasks': _activeTasks.length,
      'total_filters_analyzed': _filterUsageCount.length,
      'recent_filters_count': _recentFilters.length,
      'performance_stats': _performanceStats,
      'last_preload_times': Map<String, String>.fromEntries(
        _lastPreloadTimes.entries
            .map((e) => MapEntry(e.key, e.value.toIso8601String())),
      ),
      'cache_size': _getCacheSize(),
    };
  }

  /// 清理过期的预加载数据
  Future<void> cleanupExpiredData() async {
    try {
      await _localDataSource.clearExpiredCache();

      // 清理过期的性能统计
      final now = DateTime.now();
      final expiredKeys = <String>[];

      for (final entry in _performanceStats.entries) {
        if (entry.value is DateTime) {
          final timestamp = entry.value as DateTime;
          if (now.difference(timestamp) > maxCacheAge) {
            expiredKeys.add(entry.key);
          }
        }
      }

      for (final key in expiredKeys) {
        _performanceStats.remove(key);
      }

      // 清理过期的使用记录
      final expiredFilterKeys = <String>[];
      for (final entry in _filterLastUsed.entries) {
        if (now.difference(entry.value) > maxCacheAge) {
          expiredFilterKeys.add(entry.key);
        }
      }

      for (final key in expiredFilterKeys) {
        _filterLastUsed.remove(key);
        _filterUsageCount.remove(key);
      }

      _recordPerformance('cleanup_completed');
    } catch (e) {
      _recordPerformance('cleanup_error');
    }
  }

  /// 执行定期预加载
  Future<void> _performPreload() async {
    if (!_isRunning || _activeTasks.length >= 3) {
      return; // 避免过度预加载
    }

    try {
      // 预加载热门筛选
      await preloadPopularFilters();

      // 预加载用户可能感兴趣的筛选
      await preloadUserInterestFilters();

      // 清理过期数据
      await cleanupExpiredData();

      _recordPerformance('periodic_preload');
    } catch (e) {
      _recordPerformance('periodic_preload_error');
    }
  }

  /// 预加载常用数据（公共接口）
  Future<void> preloadCommonData() async {
    await _preloadCommonData();
  }

  /// 预加载常用数据
  Future<void> _preloadCommonData() async {
    try {
      // 预加载基金列表
      await _repository.getFundList();

      // 预加载筛选选项
      for (final type in FilterType.values) {
        await _repository.getFilterOptions(type);
      }

      _recordPerformance('common_data_preloaded');
    } catch (e) {
      _recordPerformance('common_data_preload_error');
    }
  }

  /// 触发即时预加载
  void _triggerImmediatePreload(FundFilterCriteria criteria) {
    // 基于当前筛选条件预测用户可能的其他筛选
    final relatedFilters = _generateRelatedFilters(criteria);

    for (final relatedCriteria in relatedFilters) {
      if (_activeTasks.length < 2) {
        // 限制即时预加载的数量
        preloadFilter(relatedCriteria);
      }
    }
  }

  /// 执行预加载任务
  Future<void> _executePreloadTask(PreloadTask task) async {
    try {
      final stopwatch = Stopwatch()..start();

      // 执行筛选
      await _filterUseCase.execute(task.criteria);

      // 记录性能
      _recordPerformance(
          'preload_task_duration', stopwatch.elapsedMilliseconds);

      // 检查是否超时
      if (stopwatch.elapsed > const Duration(seconds: 30)) {
        task.cancel();
        _recordPerformance('preload_task_timeout');
      }
    } catch (e) {
      if (!task.isCancelled) {
        rethrow;
      }
    }
  }

  /// 获取热门筛选
  List<FundFilterCriteria> _getPopularFilters() {
    final popularKeys = _filterUsageCount.entries
        .where((e) => e.value >= 3) // 至少使用3次
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topKeys = popularKeys.take(5);

    return topKeys
        .map((e) => _parseFilterKey(e.key))
        .where((c) => c != null)
        .cast<FundFilterCriteria>()
        .toList();
  }

  /// 生成用户兴趣筛选
  List<FundFilterCriteria> _generateInterestFilters() {
    final interestFilters = <FundFilterCriteria>[];

    // 基于最近使用的筛选生成兴趣筛选
    for (final filterKey in _recentFilters.take(3)) {
      final criteria = _parseFilterKey(filterKey);
      if (criteria != null) {
        // 生成变体筛选
        interestFilters.addAll(_generateFilterVariants(criteria));
      }
    }

    return interestFilters.take(5).toList();
  }

  /// 生成筛选变体
  List<FundFilterCriteria> _generateFilterVariants(
      FundFilterCriteria original) {
    final variants = <FundFilterCriteria>[];

    // 基金类型变体
    if (original.fundTypes?.isNotEmpty == true) {
      for (final type in ['股票型', '债券型', '混合型']) {
        if (!original.fundTypes!.contains(type)) {
          final variant = original.copyWith(
            fundTypes: [...(original.fundTypes ?? []), type],
            page: 1,
          );
          variants.add(variant);
        }
      }
    }

    // 风险等级变体
    if (original.riskLevels?.isNotEmpty == true) {
      for (final risk in ['R1', 'R2', 'R3']) {
        if (!original.riskLevels!.contains(risk)) {
          final variant = original.copyWith(
            riskLevels: [...(original.riskLevels ?? []), risk],
            page: 1,
          );
          variants.add(variant);
        }
      }
    }

    return variants;
  }

  /// 生成相关筛选
  List<FundFilterCriteria> _generateRelatedFilters(
      FundFilterCriteria criteria) {
    final relatedFilters = <FundFilterCriteria>[];

    // 基于基金类型生成相关筛选
    if (criteria.fundTypes?.isNotEmpty == true) {
      final popularCompanies = ['易方达', '华夏', '嘉实', '南方'];
      for (final company in popularCompanies.take(2)) {
        final related = criteria.copyWith(
          companies: [company],
          page: 1,
        );
        relatedFilters.add(related);
      }
    }

    return relatedFilters;
  }

  /// 计算增量更新
  List<Fund> _calculateIncrementalUpdate(
    List<Fund> cachedResults,
    List<Fund> latestFunds,
    FundFilterCriteria criteria,
  ) {
    // 简化的增量更新实现
    // 实际应用中可以使用更复杂的差异算法

    final cachedCodes = cachedResults.map((f) => f.code).toSet();

    // 找出新增的基金
    final newFunds =
        latestFunds.where((f) => !cachedCodes.contains(f.code)).toList();

    // 应用筛选条件
    return newFunds
        .where((fund) => _matchesFilterCriteria(fund, criteria))
        .toList();
  }

  /// 检查基金是否匹配筛选条件
  bool _matchesFilterCriteria(Fund fund, FundFilterCriteria criteria) {
    if (criteria.fundTypes?.isNotEmpty == true) {
      if (!criteria.fundTypes!.contains(fund.type)) return false;
    }
    if (criteria.companies?.isNotEmpty == true) {
      if (!criteria.companies!.contains(fund.company)) return false;
    }
    if (criteria.scaleRange != null) {
      if (!criteria.scaleRange!.contains(fund.scale)) return false;
    }
    if (criteria.riskLevels?.isNotEmpty == true) {
      if (!criteria.riskLevels!.contains(fund.riskLevel)) return false;
    }
    if (criteria.returnRange != null) {
      if (!criteria.returnRange!.contains(fund.return1Y)) return false;
    }
    return true;
  }

  /// 生成筛选键
  String _generateFilterKey(FundFilterCriteria criteria) {
    final parts = [
      criteria.fundTypes?.join(',') ?? '',
      criteria.companies?.join(',') ?? '',
      criteria.scaleRange?.toString() ?? '',
      criteria.riskLevels?.join(',') ?? '',
      criteria.returnRange?.toString() ?? '',
      criteria.sortBy ?? '',
      criteria.sortDirection?.name ?? '',
    ];
    return parts.where((p) => p.isNotEmpty).join('|');
  }

  /// 解析筛选键
  FundFilterCriteria? _parseFilterKey(String key) {
    try {
      final parts = key.split('|');
      if (parts.isEmpty) return null;

      final fundTypes = parts[0].isNotEmpty ? parts[0].split(',') : null;
      final companies =
          parts.length > 1 && parts[1].isNotEmpty ? parts[1].split(',') : null;

      return FundFilterCriteria(
        fundTypes: fundTypes,
        companies: companies,
        pageSize: 20,
      );
    } catch (_) {
      return null;
    }
  }

  /// 获取缓存大小
  int _getCacheSize() {
    return _activeTasks.length +
        _recentFilters.length +
        _performanceStats.length;
  }

  /// 记录性能统计
  void _recordPerformance(String operation, [dynamic value]) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _performanceStats['${operation}_$timestamp'] = value ?? true;

    // 限制性能统计数量
    if (_performanceStats.length > 1000) {
      final keys = _performanceStats.keys.toList()..sort();
      final toRemove = keys.take(_performanceStats.length - 800);
      for (final key in toRemove) {
        _performanceStats.remove(key);
      }
    }
  }

  /// 非等待执行
  void unawaited(Future<void> future) {
    // 忽略结果，避免警告
  }
}

/// 预加载任务
class PreloadTask {
  final FundFilterCriteria criteria;
  final DateTime startTime;
  final VoidCallback onCancel;
  bool _isCancelled = false;

  PreloadTask({
    required this.criteria,
    required this.startTime,
    required this.onCancel,
  });

  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
    onCancel();
  }
}
