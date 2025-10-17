import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'optimized_fund_service.dart';
import 'smart_cache_manager.dart';
import 'cache_models.dart';

/// 数据预加载和懒加载管理器
///
/// 核心功能：
/// - 智能预加载策略
/// - 懒加载实现
/// - 数据分页管理
/// - 加载优先级管理
/// - 后台数据同步
class DataPreloadManager {
  final OptimizedFundService _fundService;
  final SmartCacheManager _cacheManager;

  // 预加载队列和状态
  final PriorityQueue<PreloadTask> _preloadQueue = PriorityQueue<PreloadTask>();
  final Map<String, PreloadTask> _activeTasks = {};
  bool _isPreloading = false;
  int _concurrentLimit = 3; // 最大并发加载数

  // 懒加载分页管理
  final Map<String, PaginationState> _paginationStates = {};

  // 后台同步
  Timer? _backgroundSyncTimer;
  Duration _syncInterval = const Duration(minutes: 15);

  DataPreloadManager({
    required OptimizedFundService fundService,
    required SmartCacheManager cacheManager,
  })  : _fundService = fundService,
        _cacheManager = cacheManager;

  /// 初始化预加载管理器
  Future<void> initialize() async {
    debugPrint('🚀 初始化数据预加载管理器...');

    // 启动后台同步定时器
    _startBackgroundSync();

    // 初始预加载
    await scheduleInitialPreload();

    debugPrint('✅ 数据预加载管理器初始化完成');
  }

  /// 调度初始预加载
  Future<void> scheduleInitialPreload() async {
    debugPrint('📋 调度初始预加载任务...');

    // 关键数据 - 最高优先级
    await addPreloadTask(
      id: 'popular_funds_critical',
      type: PreloadType.critical,
      priority: 100,
      params: {'limit': 20},
      task: () => _preloadPopularFunds(20),
    );

    await addPreloadTask(
      id: 'fund_rankings_all_critical',
      type: PreloadType.critical,
      priority: 100,
      params: {'symbol': '全部', 'pageSize': 20},
      task: () => _preloadFundRankings('全部', 20),
    );

    // 重要数据 - 高优先级
    await addPreloadTask(
      id: 'fund_rankings_stock_important',
      type: PreloadType.important,
      priority: 80,
      params: {'symbol': '股票型', 'pageSize': 15},
      task: () => _preloadFundRankings('股票型', 15),
    );

    await addPreloadTask(
      id: 'fund_rankings_hybrid_important',
      type: PreloadType.important,
      priority: 80,
      params: {'symbol': '混合型', 'pageSize': 15},
      task: () => _preloadFundRankings('混合型', 15),
    );

    // 启动预加载流程
    _startPreloading();
  }

  /// 添加预加载任务
  Future<void> addPreloadTask({
    required String id,
    required PreloadType type,
    required int priority,
    required Map<String, dynamic> params,
    required Function() task,
  }) async {
    // 检查是否已存在相同任务
    if (_activeTasks.containsKey(id) || _preloadQueue.any((t) => t.id == id)) {
      debugPrint('⚠️ 预加载任务已存在: $id');
      return;
    }

    final preloadTask = PreloadTask(
      id: id,
      type: type,
      priority: priority,
      params: params,
      task: task,
    );

    _preloadQueue.enqueue(preloadTask);
    debugPrint('📝 已添加预加载任务: $id (优先级: $priority, 类型: $type)');
  }

  /// 启动预加载流程
  void _startPreloading() {
    if (_isPreloading) return;

    _isPreloading = true;
    debugPrint('🔄 开始预加载流程...');

    _processPreloadQueue();
  }

  /// 处理预加载队列
  Future<void> _processPreloadQueue() async {
    while (_preloadQueue.isNotEmpty && _activeTasks.length < _concurrentLimit) {
      final task = _preloadQueue.dequeue();
      if (task != null) {
        _executePreloadTask(task);
      }
    }

    // 如果还有任务在队列中，继续处理
    if (_preloadQueue.isNotEmpty) {
      Timer(const Duration(milliseconds: 10), () => _processPreloadQueue());
    } else if (_activeTasks.isEmpty) {
      _isPreloading = false;
      debugPrint('✅ 预加载流程完成');
    }
  }

  /// 执行预加载任务
  Future<void> _executePreloadTask(PreloadTask task) async {
    _activeTasks[task.id] = task;
    debugPrint('🚀 执行预加载任务: ${task.id} (类型: ${task.type})');

    try {
      final stopwatch = Stopwatch()..start();
      await task.task();
      stopwatch.stop();

      debugPrint(
          '✅ 预加载任务完成: ${task.id} (耗时: ${stopwatch.elapsedMilliseconds}ms)');
    } catch (e) {
      debugPrint('❌ 预加载任务失败: ${task.id}, 错误: $e');
    } finally {
      _activeTasks.remove(task.id);

      // 继续处理队列中的任务
      _processPreloadQueue();
    }
  }

  /// 预加载热门基金
  Future<void> _preloadPopularFunds(int limit) async {
    try {
      await _fundService.getFundBasicInfo(limit: limit);
      debugPrint('✅ 预加载热门基金完成: $limit条');
    } catch (e) {
      debugPrint('❌ 预加载热门基金失败: $e');
    }
  }

  /// 预加载基金排行
  Future<void> _preloadFundRankings(String symbol, int pageSize) async {
    try {
      await _fundService.getFundRankings(
        symbol: symbol,
        enableCache: true,
      );
      debugPrint('✅ 预加载基金排行完成: $symbol');
    } catch (e) {
      debugPrint('❌ 预加载基金排行失败: $symbol, 错误: $e');
    }
  }

  /// 懒加载分页数据
  Future<List<T>> loadLazyData<T>(
    String paginationKey, {
    required Future<List<T>> Function(int page, int pageSize) dataLoader,
    int pageSize = 20,
  }) async {
    final state = _paginationStates.putIfAbsent(
      paginationKey,
      () => PaginationState(pageSize: pageSize),
    );

    if (!state.hasMore || state.isLoading) {
      debugPrint('⚠️ 无更多数据或正在加载: $paginationKey');
      return [];
    }

    state.isLoading = true;
    debugPrint('📦 懒加载数据: $paginationKey, 页码: ${state.nextPage}');

    try {
      final data = await dataLoader(state.nextPage, pageSize);

      if (data.length < pageSize) {
        state.hasMore = false;
        debugPrint('📄 已加载所有数据: $paginationKey');
      }

      state.currentPage++;
      state.loadedItems.addAll(data.map((item) => item.toString()));

      debugPrint('✅ 懒加载完成: $paginationKey, ${data.length}条数据');
      return data;
    } catch (e) {
      debugPrint('❌ 懒加载失败: $paginationKey, 错误: $e');
      return [];
    } finally {
      state.isLoading = false;
    }
  }

  /// 重置分页状态
  void resetPagination(String paginationKey) {
    _paginationStates.remove(paginationKey);
    debugPrint('🔄 重置分页状态: $paginationKey');
  }

  /// 获取分页状态
  PaginationState? getPaginationState(String paginationKey) {
    return _paginationStates[paginationKey];
  }

  /// 预测性预加载
  Future<void> predictivePreload(
      String currentDataType, Map<String, dynamic> context) async {
    debugPrint('🔮 开始预测性预加载: $currentDataType');

    // 基于当前数据类型预测用户可能访问的数据
    final predictions = _predictNextData(currentDataType, context);

    for (final prediction in predictions) {
      await addPreloadTask(
        id: 'predictive_${prediction['type']}',
        type: PreloadType.background,
        priority: 30,
        params: prediction['params'],
        task: prediction['task'],
      );
    }

    if (predictions.isNotEmpty) {
      _startPreloading();
    }
  }

  /// 预测下一个可能访问的数据
  List<Map<String, dynamic>> _predictNextData(
      String currentDataType, Map<String, dynamic> context) {
    final predictions = <Map<String, dynamic>>[];

    switch (currentDataType) {
      case 'fund_rankings':
        // 用户查看排行时，可能查看相关类型的基金
        final symbol = context['symbol'] as String? ?? '全部';
        if (symbol == '全部') {
          predictions.addAll([
            {
              'type': 'fund_rankings_stock',
              'params': {'symbol': '股票型'},
              'task': () => _preloadFundRankings('股票型', 15),
            },
            {
              'type': 'fund_rankings_hybrid',
              'params': {'symbol': '混合型'},
              'task': () => _preloadFundRankings('混合型', 15),
            },
          ]);
        }
        break;

      case 'fund_detail':
        // 用户查看基金详情时，可能查看同类型或同公司的其他基金
        final fundType = context['fundType'] as String?;
        // final company = context['company'] as String?; // 预留后续扩展

        if (fundType != null) {
          predictions.add({
            'type': 'similar_funds',
            'params': {'fundType': fundType},
            'task': () =>
                _fundService.getFundBasicInfo(fundType: fundType, limit: 10),
          });
        }
        break;
    }

    return predictions;
  }

  /// 启动后台同步
  void _startBackgroundSync() {
    debugPrint('🔄 启动后台数据同步...');

    _backgroundSyncTimer = Timer.periodic(_syncInterval, (timer) async {
      await _performBackgroundSync();
    });
  }

  /// 执行后台同步
  Future<void> _performBackgroundSync() async {
    debugPrint('🔄 执行后台数据同步...');

    try {
      // 同步关键数据
      await addPreloadTask(
        id: 'background_sync_funds',
        type: PreloadType.background,
        priority: 20,
        params: {'limit': 30},
        task: () => _preloadPopularFunds(30),
      );

      await addPreloadTask(
        id: 'background_sync_rankings',
        type: PreloadType.background,
        priority: 20,
        params: {'symbol': '全部', 'pageSize': 25},
        task: () => _preloadFundRankings('全部', 25),
      );

      _startPreloading();

      // 优化缓存
      _cacheManager.optimizeCacheSize();

      debugPrint('✅ 后台数据同步完成');
    } catch (e) {
      debugPrint('❌ 后台数据同步失败: $e');
    }
  }

  /// 手动触发数据同步
  Future<void> manualSync() async {
    debugPrint('🔄 手动触发数据同步...');

    // 取消当前的同步定时器
    _backgroundSyncTimer?.cancel();

    // 立即执行同步
    await _performBackgroundSync();

    // 重新启动定时器
    _startBackgroundSync();
  }

  /// 获取预加载统计信息
  Map<String, dynamic> getPreloadStats() {
    return {
      'isPreloading': _isPreloading,
      'queueSize': _preloadQueue.length,
      'activeTasks': _activeTasks.length,
      'concurrentLimit': _concurrentLimit,
      'paginationStates': _paginationStates.length,
      'backgroundSyncActive': _backgroundSyncTimer?.isActive ?? false,
      'syncInterval': _syncInterval.inMinutes,
      'cacheStats': _cacheManager.getCacheStats(),
    };
  }

  /// 设置并发限制
  void setConcurrentLimit(int limit) {
    _concurrentLimit = math.max(1, limit);
    debugPrint('⚙️ 设置并发限制: $_concurrentLimit');
  }

  /// 设置同步间隔
  void setSyncInterval(Duration interval) {
    _syncInterval = interval;
    debugPrint('⚙️ 设置同步间隔: ${interval.inMinutes}分钟');

    // 重启同步定时器
    _backgroundSyncTimer?.cancel();
    _startBackgroundSync();
  }

  /// 暂停预加载
  void pausePreloading() {
    _isPreloading = false;
    debugPrint('⏸️ 暂停预加载');
  }

  /// 恢复预加载
  void resumePreloading() {
    if (!_isPreloading && _preloadQueue.isNotEmpty) {
      _startPreloading();
    }
    debugPrint('▶️ 恢复预加载');
  }

  /// 清理资源
  void dispose() {
    _backgroundSyncTimer?.cancel();
    _preloadQueue.clear();
    _activeTasks.clear();
    _paginationStates.clear();
    _isPreloading = false;

    debugPrint('🔒 数据预加载管理器已释放');
  }
}

/// 优先队列实现
class PriorityQueue<T extends Comparable<T>> {
  final List<T> _items = [];

  void enqueue(T item) {
    _items.add(item);
    _heapifyUp(_items.length - 1);
  }

  T? dequeue() {
    if (_items.isEmpty) return null;

    final first = _items.first;
    final last = _items.removeLast();

    if (_items.isNotEmpty) {
      _items[0] = last;
      _heapifyDown(0);
    }

    return first;
  }

  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;
  int get length => _items.length;

  void clear() {
    _items.clear();
  }

  bool any(bool Function(T) test) {
    return _items.any(test);
  }

  void _heapifyUp(int index) {
    while (index > 0) {
      final parentIndex = (index - 1) ~/ 2;
      if (_items[parentIndex].compareTo(_items[index]) <= 0) break;

      _swap(index, parentIndex);
      index = parentIndex;
    }
  }

  void _heapifyDown(int index) {
    while (true) {
      var smallest = index;
      final leftChild = 2 * index + 1;
      final rightChild = 2 * index + 2;

      if (leftChild < _items.length &&
          _items[leftChild].compareTo(_items[smallest]) < 0) {
        smallest = leftChild;
      }

      if (rightChild < _items.length &&
          _items[rightChild].compareTo(_items[smallest]) < 0) {
        smallest = rightChild;
      }

      if (smallest == index) break;

      _swap(index, smallest);
      index = smallest;
    }
  }

  void _swap(int i, int j) {
    final temp = _items[i];
    _items[i] = _items[j];
    _items[j] = temp;
  }
}
