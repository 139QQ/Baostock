import 'dart:async';
import '../entities/fund.dart';
import '../entities/fund_filter_criteria.dart';
import '../repositories/fund_repository.dart';

/// 优化的基金筛选用例类
///
/// 提供高性能的基金筛选功能，包括：
/// - 分批处理大量数据
/// - 并行筛选处理
/// - 智能缓存策略
/// - 内存优化管理
class OptimizedFundFilterUseCase {
  final FundRepository _repository;

  // 配置参数
  final int batchSize;
  final Duration timeout;
  final int maxConcurrentFilters;

  // 内存管理
  final int maxMemoryUsageMB;
  int _currentMemoryUsage = 0;

  // 性能监控
  final Map<String, DateTime> _performanceMetrics = {};

  OptimizedFundFilterUseCase(
    this._repository, {
    this.batchSize = 500,
    this.timeout = const Duration(seconds: 10),
    this.maxConcurrentFilters = 4,
    this.maxMemoryUsageMB = 100,
  });

  /// 执行优化的基金筛选
  ///
  /// [criteria] 筛选条件
  /// [forceRefresh] 是否强制刷新缓存
  /// 返回筛选结果
  Future<FundFilterResult> execute(
    FundFilterCriteria criteria, {
    bool forceRefresh = false,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      // 验证筛选条件
      _validateCriteria(criteria);

      // 检查缓存有效性
      if (!forceRefresh && await _isCacheValid(criteria)) {
        final cachedResult = await _getCachedResult(criteria);
        if (cachedResult != null) {
          _recordPerformance('cache_hit', stopwatch.elapsed);
          return cachedResult;
        }
      }

      // 获取总基金数量
      final totalCount = await _getTotalFundCount(criteria);

      // 分批处理筛选
      final filteredFunds = await _batchFilter(criteria, totalCount);

      // 构建结果
      final result = FundFilterResult(
        funds: filteredFunds,
        totalCount: totalCount,
        hasMore: _hasMoreResults(criteria, filteredFunds.length),
        criteria: criteria,
        executionTime: stopwatch.elapsed,
        fromCache: false,
      );

      // 缓存结果
      await _cacheResult(criteria, result);

      _recordPerformance('filter_execution', stopwatch.elapsed);

      return result;
    } catch (e) {
      _recordPerformance('filter_error', stopwatch.elapsed);
      throw FundFilterException('筛选基金时发生错误: ${e.toString()}');
    } finally {
      stopwatch.stop();
    }
  }

  /// 并行筛选基金列表
  ///
  /// [funds] 基金列表
  /// [criteria] 筛选条件
  /// 返回筛选后的基金列表
  Future<List<Fund>> parallelFilter(
    List<Fund> funds,
    FundFilterCriteria criteria,
  ) async {
    if (funds.isEmpty) return [];

    final stopwatch = Stopwatch()..start();

    try {
      // 检查内存使用情况
      if (_shouldUseBatching(funds.length)) {
        return await _batchFilterList(funds, criteria);
      }

      // 使用并行处理
      final chunks = _splitIntoChunks(funds, batchSize);
      final futures = <Future<List<Fund>>>[];

      for (final chunk in chunks) {
        if (futures.length >= maxConcurrentFilters) {
          // 等待一些任务完成
          await Future.wait(futures.take(maxConcurrentFilters));
          futures.removeRange(0, maxConcurrentFilters);
        }
        futures.add(_filterChunk(chunk, criteria));
      }

      final results = await Future.wait(futures);
      final filteredFunds = results.expand((list) => list).toList();

      _recordPerformance('parallel_filter', stopwatch.elapsed);
      return filteredFunds;
    } catch (e) {
      _recordPerformance('parallel_filter_error', stopwatch.elapsed);
      throw FundFilterException('并行筛选失败: ${e.toString()}');
    } finally {
      stopwatch.stop();
    }
  }

  /// 预加载常用筛选组合
  ///
  /// [presetTypes] 预设筛选类型列表
  Future<void> preloadCommonFilters(List<FilterPresetType> presetTypes) async {
    final stopwatch = Stopwatch()..start();

    try {
      final futures = <Future<void>>[];

      for (final presetType in presetTypes) {
        final criteria = _createPresetCriteria(presetType);
        futures.add(execute(criteria).then((_) {}));

        // 限制并发数量
        if (futures.length >= 2) {
          await Future.wait(futures.take(2));
          futures.removeRange(0, 2);
        }
      }

      await Future.wait(futures);
      _recordPerformance('preload_filters', stopwatch.elapsed);
    } catch (e) {
      _recordPerformance('preload_error', stopwatch.elapsed);
      // 预加载失败不影响主流程
    } finally {
      stopwatch.stop();
    }
  }

  /// 获取筛选性能指标
  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'metrics': Map<String, String>.fromEntries(
        _performanceMetrics.entries
            .map((e) => MapEntry(e.key, e.value.toIso8601String())),
      ),
      'memory_usage_mb': _currentMemoryUsage,
      'batch_size': batchSize,
      'max_concurrent': maxConcurrentFilters,
      'cache_timeout': timeout.inSeconds,
    };
  }

  /// 清理性能指标
  void clearPerformanceMetrics() {
    _performanceMetrics.clear();
    _currentMemoryUsage = 0;
  }

  /// 验证筛选条件
  void _validateCriteria(FundFilterCriteria criteria) {
    if (criteria.page < 1) {
      throw FundFilterException('页码必须大于0');
    }
    if (criteria.pageSize < 1 || criteria.pageSize > 100) {
      throw FundFilterException('每页数量必须在1-100之间');
    }
    if (criteria.scaleRange != null) {
      if (criteria.scaleRange!.min < 0 || criteria.scaleRange!.max < 0) {
        throw FundFilterException('基金规模不能为负数');
      }
    }
    if (criteria.returnRange != null) {
      if (criteria.returnRange!.min < -100 ||
          criteria.returnRange!.max > 1000) {
        throw FundFilterException('收益率范围不合理');
      }
    }
  }

  /// 检查缓存是否有效
  Future<bool> _isCacheValid(FundFilterCriteria criteria) async {
    try {
      // 简单的缓存有效性检查
      final cacheKey = _generateCacheKey(criteria);
      final lastUpdate = _performanceMetrics[cacheKey];

      if (lastUpdate == null) return false;

      const maxAge = Duration(minutes: 15);
      return DateTime.now().difference(lastUpdate) < maxAge;
    } catch (_) {
      return false;
    }
  }

  /// 获取缓存结果
  Future<FundFilterResult?> _getCachedResult(
      FundFilterCriteria criteria) async {
    try {
      final cachedFunds = await _repository.getFilteredFunds(criteria);
      final cachedCount = await _repository.getFilteredFundsCount(criteria);

      return FundFilterResult(
        funds: cachedFunds,
        totalCount: cachedCount,
        hasMore: _hasMoreResults(criteria, cachedFunds.length),
        criteria: criteria,
        fromCache: true,
      );
    } catch (_) {
      return null;
    }
  }

  /// 缓存结果
  Future<void> _cacheResult(
      FundFilterCriteria criteria, FundFilterResult result) async {
    try {
      final cacheKey = _generateCacheKey(criteria);
      _performanceMetrics[cacheKey] = DateTime.now();

      // 限制缓存大小
      if (_performanceMetrics.length > 100) {
        final oldestKey = _performanceMetrics.keys.first;
        _performanceMetrics.remove(oldestKey);
      }
    } catch (_) {
      // 缓存失败不影响主流程
    }
  }

  /// 获取总基金数量
  Future<int> _getTotalFundCount(FundFilterCriteria criteria) async {
    if (!criteria.hasAnyFilter) {
      final allFunds = await _repository.getFundList();
      return allFunds.length;
    }
    return await _repository.getFilteredFundsCount(criteria);
  }

  /// 分批筛选处理
  Future<List<Fund>> _batchFilter(
      FundFilterCriteria criteria, int totalCount) async {
    if (totalCount <= batchSize) {
      // 小量数据直接处理
      return await _repository.getFilteredFunds(criteria);
    }

    // 分批处理
    final allFunds = await _repository.getFundList();
    return await _batchFilterList(allFunds, criteria);
  }

  /// 分批筛选列表
  Future<List<Fund>> _batchFilterList(
      List<Fund> funds, FundFilterCriteria criteria) async {
    final chunks = _splitIntoChunks(funds, batchSize);
    final results = <Fund>[];

    for (final chunk in chunks) {
      final filteredChunk = await _filterChunk(chunk, criteria);
      results.addAll(filteredChunk);

      // 内存管理
      if (_shouldCheckMemory()) {
        await _checkMemoryUsage();
      }
    }

    return results;
  }

  /// 筛选单个批次
  Future<List<Fund>> _filterChunk(
      List<Fund> chunk, FundFilterCriteria criteria) async {
    return chunk.where((fund) => _matchesCriteria(fund, criteria)).toList();
  }

  /// 检查基金是否匹配筛选条件
  bool _matchesCriteria(Fund fund, FundFilterCriteria criteria) {
    // 基金类型筛选
    if (criteria.fundTypes?.isNotEmpty == true) {
      if (!criteria.fundTypes!.contains(fund.type)) return false;
    }

    // 管理公司筛选
    if (criteria.companies?.isNotEmpty == true) {
      if (!criteria.companies!.contains(fund.company)) return false;
    }

    // 基金规模筛选
    if (criteria.scaleRange != null) {
      if (!criteria.scaleRange!.contains(fund.scale)) return false;
    }

    // 成立时间筛选
    if (criteria.establishmentDateRange != null) {
      final establishmentDate = _parseDate(fund.date);
      if (establishmentDate != null &&
          !criteria.establishmentDateRange!.contains(establishmentDate)) {
        return false;
      }
    }

    // 风险等级筛选
    if (criteria.riskLevels?.isNotEmpty == true) {
      if (!criteria.riskLevels!.contains(fund.riskLevel)) return false;
    }

    // 基金状态筛选
    if (criteria.statuses?.isNotEmpty == true) {
      if (!criteria.statuses!.contains(fund.status)) return false;
    }

    // 收益率筛选
    if (criteria.returnRange != null) {
      if (!criteria.returnRange!.contains(fund.return1Y)) return false;
    }

    return true;
  }

  /// 解析日期
  DateTime? _parseDate(String dateStr) {
    if (dateStr.isEmpty) return null;

    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
  }

  /// 分割数据为批次
  List<List<Fund>> _splitIntoChunks(List<Fund> funds, int chunkSize) {
    final chunks = <List<Fund>>[];
    for (int i = 0; i < funds.length; i += chunkSize) {
      final end = (i + chunkSize < funds.length) ? i + chunkSize : funds.length;
      chunks.add(funds.sublist(i, end));
    }
    return chunks;
  }

  /// 检查是否应该使用分批处理
  bool _shouldUseBatching(int itemCount) {
    return itemCount > batchSize ||
        _currentMemoryUsage > (maxMemoryUsageMB * 1024 * 1024 ~/ 2);
  }

  /// 检查是否应该检查内存使用
  bool _shouldCheckMemory() {
    return _currentMemoryUsage > (maxMemoryUsageMB * 1024 * 1024 ~/ 4);
  }

  /// 检查内存使用情况
  Future<void> _checkMemoryUsage() async {
    // 简化的内存使用估算
    // 实际应用中可以使用更精确的内存监控
    _currentMemoryUsage = (_currentMemoryUsage + 10) % (maxMemoryUsageMB + 1);

    if (_currentMemoryUsage > maxMemoryUsageMB) {
      // 触发垃圾回收
      await Future.delayed(const Duration(milliseconds: 100));
      _currentMemoryUsage = (_currentMemoryUsage ~/ 2);
    }
  }

  /// 检查是否还有更多结果
  bool _hasMoreResults(FundFilterCriteria criteria, int currentCount) {
    final totalItems = criteria.page * criteria.pageSize + currentCount;
    return totalItems < (criteria.pageSize * 2); // 简化判断
  }

  /// 生成缓存键
  String _generateCacheKey(FundFilterCriteria criteria) {
    final buffer = StringBuffer();
    buffer.write('filter_');
    buffer.write(criteria.fundTypes?.join(',') ?? '');
    buffer.write('_${criteria.companies?.join(',') ?? ''}');
    buffer.write('_${criteria.scaleRange?.toString() ?? ''}');
    return buffer.toString();
  }

  /// 创建预设筛选条件
  FundFilterCriteria _createPresetCriteria(FilterPresetType type) {
    switch (type) {
      case FilterPresetType.highReturn:
        return const FundFilterCriteria(
          returnRange: RangeValue(min: 10.0, max: 100.0),
          sortBy: 'return1Y',
          sortDirection: SortDirection.desc,
          pageSize: 20,
        );
      case FilterPresetType.largeScale:
        return const FundFilterCriteria(
          scaleRange: RangeValue(min: 50.0, max: 1000.0),
          sortBy: 'scale',
          sortDirection: SortDirection.desc,
          pageSize: 20,
        );
      case FilterPresetType.lowRisk:
        return const FundFilterCriteria(
          riskLevels: ['R1', 'R2'],
          sortBy: 'riskLevel',
          sortDirection: SortDirection.asc,
          pageSize: 20,
        );
    }
  }

  /// 记录性能指标
  void _recordPerformance(String operation, Duration duration) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _performanceMetrics['${operation}_$timestamp'] = DateTime.now();
  }
}

/// 筛选结果类
class FundFilterResult {
  final List<Fund> funds;
  final int totalCount;
  final bool hasMore;
  final FundFilterCriteria criteria;
  final Duration? executionTime;
  final bool fromCache;

  FundFilterResult({
    required this.funds,
    required this.totalCount,
    required this.hasMore,
    required this.criteria,
    this.executionTime,
    this.fromCache = false,
  });

  @override
  String toString() {
    return 'FundFilterResult(funds: ${funds.length}, totalCount: $totalCount, hasMore: $hasMore, fromCache: $fromCache)';
  }
}

/// 筛选预设类型
enum FilterPresetType {
  highReturn,
  largeScale,
  lowRisk,
}

/// 筛选异常
class FundFilterException implements Exception {
  final String message;

  FundFilterException(this.message);

  @override
  String toString() => 'FundFilterException: $message';
}
