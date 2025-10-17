import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'async_data_processor.dart';

/// 分批数据加载配置
class BatchLoadConfig {
  final int pageSize;
  final int prefetchDistance;
  final Duration loadDelay;
  final bool enableMemoryOptimization;
  final int maxCachedPages;
  final bool enableBackgroundLoading;

  BatchLoadConfig({
    this.pageSize = 50,
    this.prefetchDistance = 20,
    this.loadDelay = const Duration(milliseconds: 100),
    this.enableMemoryOptimization = true,
    this.maxCachedPages = 10,
    this.enableBackgroundLoading = true,
  });
}

/// 分批数据加载结果
class BatchLoadResult<T> {
  final List<T> data;
  final int totalCount;
  final int currentPage;
  final bool hasMore;
  final bool isLoading;

  BatchLoadResult({
    required this.data,
    required this.totalCount,
    required this.currentPage,
    required this.hasMore,
    required this.isLoading,
  });
}

/// 加载状态
enum LoadState {
  idle,
  loading,
  error,
  complete,
}

/// 内存优化的分批数据加载器
class BatchDataLoader<T> {
  final BatchLoadConfig config;
  final Future<List<T>> Function(int page, int pageSize) dataFetcher;
  final T Function(Map<String, dynamic>) fromJson;

  // 状态管理
  LoadState _state = LoadState.idle;
  String? _errorMessage;

  // 数据缓存
  final Map<int, List<T>> _pageCache = {};
  int _totalCount = 0;
  int _currentPage = 0;
  bool _hasMore = true;

  // 性能优化
  final Set<int> _loadingPages = {};
  final List<int> _recentlyAccessedPages = [];
  Timer? _cleanupTimer;
  Timer? _prefetchTimer;

  // 事件流
  final StreamController<BatchLoadResult<T>> _dataController =
      StreamController<BatchLoadResult<T>>.broadcast();
  final StreamController<LoadState> _stateController =
      StreamController<LoadState>.broadcast();

  BatchDataLoader({
    required this.dataFetcher,
    required this.fromJson,
    BatchLoadConfig? config,
  }) : config = config ?? BatchLoadConfig() {
    _startCleanupTimer();
  }

  /// 获取数据流
  Stream<BatchLoadResult<T>> get dataStream => _dataController.stream;

  /// 获取状态流
  Stream<LoadState> get stateStream => _stateController.stream;

  /// 当前状态
  LoadState get state => _state;

  /// 错误信息
  String? get errorMessage => _errorMessage;

  /// 是否正在加载
  bool get isLoading => _state == LoadState.loading;

  /// 加载指定页面数据
  Future<BatchLoadResult<T>> loadPage(int page,
      {bool forceReload = false}) async {
    if (_state == LoadState.loading && !forceReload) {
      return _getCurrentResult();
    }

    _setState(LoadState.loading);
    _errorMessage = null;

    try {
      // 检查缓存
      if (!forceReload && _pageCache.containsKey(page)) {
        _updatePageAccess(page);
        return _getCurrentResult();
      }

      // 避免重复加载
      if (_loadingPages.contains(page)) {
        return _getCurrentResult();
      }

      _loadingPages.add(page);

      // 记录性能
      final stopwatch = Stopwatch()..start();

      // 获取原始数据
      final rawData = await dataFetcher(page, config.pageSize);

      // 使用异步处理器解析大数据
      List<T> parsedData;
      if (rawData.length > 1000 && config.enableBackgroundLoading) {
        parsedData = await AsyncDataProcessor.processMassiveData<T>(
          rawData,
          fromJson,
          config: IsolateConfig(
            batchSize: 10, // 大幅减小批次大小
            batchDelay: const Duration(milliseconds: 200), // 每批延迟200毫秒
            enableLogging: false,
          ),
        );
      } else {
        parsedData = rawData
            .map((item) => fromJson(item as Map<String, dynamic>))
            .toList();
      }

      stopwatch.stop();

      if (kDebugMode) {
        debugPrint('📦 分批加载完成 - 页面$page: ${parsedData.length}条数据，'
            '耗时${stopwatch.elapsedMilliseconds}ms');
      }

      // 更新缓存
      _pageCache[page] = parsedData;
      _updatePageAccess(page);

      // 更新状态
      if (page == 0) {
        _totalCount = parsedData.length;
        _hasMore = parsedData.length == config.pageSize;
      } else {
        _hasMore = parsedData.length == config.pageSize;
      }

      _currentPage = page;
      _loadingPages.remove(page);
      _setState(LoadState.complete);

      // 触发预加载
      if (_hasMore && config.enableBackgroundLoading) {
        _schedulePrefetch(page + 1);
      }

      return _getCurrentResult();
    } catch (e) {
      _loadingPages.remove(page);
      _errorMessage = e.toString();
      _setState(LoadState.error);

      if (kDebugMode) {
        debugPrint('❌ 分批加载失败 - 页面$page: $e');
      }

      return _getCurrentResult();
    }
  }

  /// 加载下一页
  Future<BatchLoadResult<T>> loadNextPage() async {
    if (!_hasMore) {
      return _getCurrentResult();
    }
    return loadPage(_currentPage + 1);
  }

  /// 预加载指定页面
  Future<void> prefetchPage(int page) async {
    if (_pageCache.containsKey(page) || _loadingPages.contains(page)) {
      return;
    }

    if (kDebugMode) {
      debugPrint('🚀 预加载页面: $page');
    }

    await loadPage(page);
  }

  /// 刷新当前页面
  Future<BatchLoadResult<T>> refresh() async {
    return loadPage(_currentPage, forceReload: true);
  }

  /// 获取指定范围的数据
  List<T> getDataRange(int startIndex, int endIndex) {
    final result = <T>[];

    for (int i = startIndex; i <= endIndex; i++) {
      final pageIndex = i ~/ config.pageSize;
      final itemIndex = i % config.pageSize;

      final pageData = _pageCache[pageIndex];
      if (pageData != null && itemIndex < pageData.length) {
        result.add(pageData[itemIndex]);
      } else {
        // 如果数据不存在，触发加载
        if (!_loadingPages.contains(pageIndex)) {
          loadPage(pageIndex);
        }
        break;
      }
    }

    return result;
  }

  /// 获取缓存统计信息
  Map<String, dynamic> getCacheStats() {
    final totalItems =
        _pageCache.values.fold<int>(0, (sum, page) => sum + page.length);

    return {
      'cachedPages': _pageCache.length,
      'totalCachedItems': totalItems,
      'maxCachePages': config.maxCachedPages,
      'loadingPages': _loadingPages.length,
      'currentPage': _currentPage,
      'hasMore': _hasMore,
      'totalCount': _totalCount,
    };
  }

  /// 清理缓存
  void clearCache() {
    _pageCache.clear();
    _recentlyAccessedPages.clear();

    if (kDebugMode) {
      debugPrint('🧹 数据缓存已清理');
    }
  }

  /// 释放资源
  void dispose() {
    _cleanupTimer?.cancel();
    _prefetchTimer?.cancel();
    _dataController.close();
    _stateController.close();
    clearCache();

    if (kDebugMode) {
      debugPrint('🗑️ BatchDataLoader 已释放');
    }
  }

  // 私有方法

  BatchLoadResult<T> _getCurrentResult() {
    final allData = <T>[];
    final sortedPages = _pageCache.keys.toList()..sort();

    for (final pageIndex in sortedPages) {
      allData.addAll(_pageCache[pageIndex]!);
    }

    return BatchLoadResult<T>(
      data: allData,
      totalCount: _totalCount,
      currentPage: _currentPage,
      hasMore: _hasMore,
      isLoading: _state == LoadState.loading,
    );
  }

  void _setState(LoadState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(newState);
      _dataController.add(_getCurrentResult());
    }
  }

  void _updatePageAccess(int page) {
    _recentlyAccessedPages.remove(page);
    _recentlyAccessedPages.add(page);

    // 限制缓存大小
    if (config.enableMemoryOptimization) {
      _enforceCacheLimit();
    }
  }

  void _enforceCacheLimit() {
    while (_pageCache.length > config.maxCachedPages) {
      // 移除最久未访问的页面
      final oldestPage = _recentlyAccessedPages.removeAt(0);
      _pageCache.remove(oldestPage);

      if (kDebugMode) {
        debugPrint('🗑️ 移除过期缓存页面: $oldestPage');
      }
    }
  }

  void _schedulePrefetch(int nextPage) {
    _prefetchTimer?.cancel();
    _prefetchTimer = Timer(config.loadDelay, () {
      prefetchPage(nextPage);
    });
  }

  void _startCleanupTimer() {
    if (!config.enableMemoryOptimization) return;

    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _enforceCacheLimit();
    });
  }
}

/// 基金数据专用分批加载器
class FundBatchLoader {
  static BatchDataLoader<Map<String, dynamic>> createFundRankingLoader({
    BatchLoadConfig? config,
  }) {
    return BatchDataLoader<Map<String, dynamic>>(
      dataFetcher: (page, pageSize) async {
        // 这里应该调用实际的API
        // 目前使用模拟数据
        return _generateMockFundData(page, pageSize);
      },
      fromJson: (json) => json,
      config: config ??
          BatchLoadConfig(
            pageSize: 100,
            prefetchDistance: 30,
            maxCachedPages: 15,
          ),
    );
  }

  static List<Map<String, dynamic>> _generateMockFundData(
      int page, int pageSize) {
    final random = Random();
    final startIndex = page * pageSize;

    return List.generate(pageSize, (index) {
      final fundIndex = startIndex + index;
      final fundNames = [
        '易方达蓝筹精选混合',
        '富国天惠成长混合',
        '兴全合润混合',
        '汇添富价值精选',
        '嘉实优质企业混合',
        '华夏回报混合',
        '南方绩优成长混合',
        '广发稳健增长混合',
      ];

      return {
        '基金代码': (random.nextInt(999999) + 100000).toString().padLeft(6, '0'),
        '基金简称': '${fundNames[random.nextInt(fundNames.length)]}$fundIndex',
        '基金类型': ['股票型', '债券型', '混合型', '货币型'][random.nextInt(4)],
        '基金公司': '${[
          '易方达',
          '富国',
          '兴全',
          '汇添富',
          '嘉实',
          '华夏'
        ][random.nextInt(6)]}基金管理有限公司',
        '单位净值': (random.nextDouble() * 5 + 0.5).toStringAsFixed(4),
        '累计净值': (random.nextDouble() * 10 + 1).toStringAsFixed(4),
        '日增长率': '${(random.nextDouble() * 10 - 5).toStringAsFixed(2)}%',
        '近1周': '${(random.nextDouble() * 8 - 4).toStringAsFixed(2)}%',
        '近1月': '${(random.nextDouble() * 20 - 10).toStringAsFixed(2)}%',
        '近3月': '${(random.nextDouble() * 30 - 15).toStringAsFixed(2)}%',
        '近6月': '${(random.nextDouble() * 40 - 20).toStringAsFixed(2)}%',
        '近1年': '${(random.nextDouble() * 50 - 25).toStringAsFixed(2)}%',
        '近2年': '${(random.nextDouble() * 60 - 30).toStringAsFixed(2)}%',
        '近3年': '${(random.nextDouble() * 80 - 40).toStringAsFixed(2)}%',
        '今年来': '${(random.nextDouble() * 40 - 20).toStringAsFixed(2)}%',
        '成立来': '${(random.nextDouble() * 150 - 50).toStringAsFixed(2)}%',
        '日期': DateTime.now().toString().substring(0, 10),
        '手续费': '${(random.nextDouble() * 0.5).toStringAsFixed(2)}%',
        '规模': '${(random.nextInt(900) + 100)}亿元',
        '基金经理': '基金经理${(fundIndex % 20) + 1}',
      };
    });
  }
}
