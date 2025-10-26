import 'dart:async';
import 'dart:isolate';
import 'dart:math' as math;
import 'package:logger/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'intelligent_cache_manager.dart';
import '../models/fund_info.dart';

/// 预加载优先级枚举
enum PreloadPriority {
  level1, // 核心：用户自选 + 热门榜单
  level2, // 高频：基础信息 + 核心索引
  level3, // 关联：关联数据
  level4, // 低频：历史净值 + 财报
}

/// 预加载触发类型
enum PreloadTrigger {
  startup, // 启动时
  behavior, // 行为触发
  scheduled, // 定时触发
  conditional, // 条件触发
}

/// 智能预加载管理器
///
/// 实现4级智能预加载策略：
/// 1级（核心）：用户自选基金 + 热门基金榜单
/// 2级（高频）：全量基金基础信息 + 核心索引
/// 3级（关联）：基金关联数据（同经理/同类型）
/// 4级（低频）：历史净值明细 + 深度财报
class SmartPreloadingManager {
  static final SmartPreloadingManager _instance =
      SmartPreloadingManager._internal();
  factory SmartPreloadingManager() => _instance;
  SmartPreloadingManager._internal();

  final Logger _logger = Logger();

  // 服务依赖
  late final IntelligentCacheManager _cacheManager;
  late final SharedPreferences _prefs;
  late final Connectivity _connectivity;
  late final Battery _battery;

  // 状态管理
  bool _isInitialized = false;
  bool _isRunning = false;
  final Map<PreloadPriority, Set<PreloadTask>> _activeTasks = {};
  final Map<String, DateTime> _lastPreloadTimes = {};

  // 定时器管理
  Timer? _hourlyTimer;
  Timer? _dailyTimer;
  Timer? _memoryCleanupTimer;

  // LRU缓存管理
  final Map<String, CacheItem> _memoryCache = {};
  final int _maxMemoryItems = 1000; // 增加到1000以支持更多缓存项
  final List<String> _lruQueue = [];

  // 预加载配置
  static const Duration _hourlyInterval = Duration(hours: 1);
  static const Duration _dailyInterval = Duration(days: 1);
  static const Duration _memoryCleanupInterval = Duration(minutes: 30);
  static const double _lowBatteryThreshold = 0.3;
  static const int _maxConcurrentTasks = 3;

  /// 初始化预加载管理器
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.i('🚀 初始化智能预加载管理器...');

      // 初始化服务依赖
      _cacheManager = IntelligentCacheManager();
      await _cacheManager.initialize();

      _prefs = await SharedPreferences.getInstance();
      _connectivity = Connectivity();
      _battery = Battery();

      // 加载用户自选基金
      await _loadUserFavoriteFunds();

      // 启动定时器
      _startScheduledTimers();

      _isInitialized = true;
      _isRunning = true;

      _logger.i('✅ 智能预加载管理器初始化完成');

      // 启动初始预加载
      await _performStartupPreload();
    } catch (e) {
      _logger.e('❌ 智能预加载管理器初始化失败: $e');
      rethrow;
    }
  }

  /// 执行启动期预加载（1级+2级核心数据）
  Future<void> _performStartupPreload() async {
    _logger.i('🎯 执行启动期预加载...');

    try {
      // 1级预加载：用户自选基金 + 热门基金榜单
      await _preloadLevel1Data();

      // 等待首页渲染完成后，在后台执行2级预加载
      await Future.delayed(const Duration(milliseconds: 500));
      unawaited(_preloadLevel2Data());
    } catch (e) {
      _logger.e('❌ 启动期预加载失败: $e');
    }
  }

  /// 1级预加载：用户自选基金 + 热门基金榜单
  Future<void> _preloadLevel1Data() async {
    if (!_canExecutePreload(PreloadPriority.level1)) return;

    _logger.i('📊 预加载1级数据：用户自选 + 热门榜单');

    final task = PreloadTask(
      id: 'level1_startup',
      priority: PreloadPriority.level1,
      trigger: PreloadTrigger.startup,
      startTime: DateTime.now(),
    );

    _addTask(task);

    try {
      // 加载用户自选基金（从本地缓存，<100ms）
      final favoriteFunds = await _loadUserFavoriteFundsFromCache();
      if (favoriteFunds.isNotEmpty) {
        _updateMemoryCache(
            'user_favorites', favoriteFunds, PreloadPriority.level1);
        _logger.d('✅ 用户自选基金加载完成: ${favoriteFunds.length} 只');
      }

      // 加载热门基金榜单（Top50预计算列表）
      final hotFunds = await _loadHotFundsFromCache();
      if (hotFunds.isNotEmpty) {
        _updateMemoryCache('hot_funds', hotFunds, PreloadPriority.level1);
        _logger.d('✅ 热门基金榜单加载完成: ${hotFunds.length} 只');
      }

      _markTaskCompleted(task);
      _recordPreloadTime('level1_startup');
    } catch (e) {
      _markTaskFailed(task, e.toString());
      _logger.e('❌ 1级数据预加载失败: $e');
    }
  }

  /// 2级预加载：全量基金基础信息 + 核心索引
  Future<void> _preloadLevel2Data() async {
    if (!_canExecutePreload(PreloadPriority.level2)) return;

    _logger.i('🔍 预加载2级数据：基础信息 + 核心索引');

    final task = PreloadTask(
      id: 'level2_startup',
      priority: PreloadPriority.level2,
      trigger: PreloadTrigger.startup,
      startTime: DateTime.now(),
    );

    _addTask(task);

    try {
      // 在Isolate中执行，避免阻塞UI
      final receivePort = ReceivePort();
      await Isolate.spawn(_preloadLevel2DataInIsolate, receivePort.sendPort);

      final completer = Completer<void>();
      receivePort.listen((message) {
        if (message == 'completed') {
          completer.complete();
        } else if (message is String && message.startsWith('error:')) {
          completer.completeError(Exception(message.substring(6)));
        }
      });

      await completer.future;

      _markTaskCompleted(task);
      _recordPreloadTime('level2_startup');
      _logger.d('✅ 2级数据预加载完成');
    } catch (e) {
      _markTaskFailed(task, e.toString());
      _logger.e('❌ 2级数据预加载失败: $e');
    }
  }

  /// 行为触发预加载（3级关联数据）
  Future<void> triggerBehaviorPreload(String fundCode) async {
    if (!_canExecutePreload(PreloadPriority.level3)) return;

    _logger.i('🔗 触发行为预加载：基金关联数据 - $fundCode');

    final task = PreloadTask(
      id: 'level3_behavior_$fundCode',
      priority: PreloadPriority.level3,
      trigger: PreloadTrigger.behavior,
      startTime: DateTime.now(),
    );

    _addTask(task);

    try {
      // 预加载同基金经理的其他基金
      final sameManagerFunds = await _preloadSameManagerFunds(fundCode);
      if (sameManagerFunds.isNotEmpty) {
        _updateMemoryCache(
            'same_manager_$fundCode', sameManagerFunds, PreloadPriority.level3);
      }

      // 预加载同类型基金的Top10
      final sameTypeFunds = await _preloadSameTypeFunds(fundCode);
      if (sameTypeFunds.isNotEmpty) {
        _updateMemoryCache(
            'same_type_$fundCode', sameTypeFunds, PreloadPriority.level3);
      }

      // 预加载该基金的近30天净值走势
      final recentNavData = await _preloadRecentNavData(fundCode);
      if (recentNavData.isNotEmpty) {
        _updateMemoryCache(
            'recent_nav_$fundCode', recentNavData, PreloadPriority.level3);
      }

      _markTaskCompleted(task);
      _recordPreloadTime('level3_behavior_$fundCode');
      _logger.d('✅ 3级关联数据预加载完成: $fundCode');
    } catch (e) {
      _markTaskFailed(task, e.toString());
      _logger.e('❌ 3级关联数据预加载失败: $e');
    }
  }

  /// 条件触发预加载（4级低频数据）
  Future<void> triggerConditionalPreload() async {
    if (!_canExecutePreload(PreloadPriority.level4)) return;

    // 检查条件：WiFi + 电量 > 30%
    final connectivityResult = await _connectivity.checkConnectivity();
    final batteryLevel = await _battery.batteryLevel;

    if (connectivityResult != ConnectivityResult.wifi ||
        batteryLevel / 100 < _lowBatteryThreshold) {
      _logger.d('⚠️ 条件不满足，跳过4级数据预加载');
      return;
    }

    _logger.i('📅 触发条件预加载：低频数据');

    final task = PreloadTask(
      id: 'level4_conditional',
      priority: PreloadPriority.level4,
      trigger: PreloadTrigger.conditional,
      startTime: DateTime.now(),
    );

    _addTask(task);

    try {
      // 预加载用户持仓基金的季度财报摘要
      final positionFunds = await _getUserPositionFunds();
      for (final fund in positionFunds) {
        // 移除数量限制
        final reportSummary = await _preloadFundReportSummary(fund.code);
        if (reportSummary.isNotEmpty) {
          _updateMemoryCache('report_summary_${fund.code}', reportSummary,
              PreloadPriority.level4);
        }
      }

      _markTaskCompleted(task);
      _recordPreloadTime('level4_conditional');
      _logger.d('✅ 4级低频数据预加载完成');
    } catch (e) {
      _markTaskFailed(task, e.toString());
      _logger.e('❌ 4级低频数据预加载失败: $e');
    }
  }

  /// 定时预加载（每日凌晨3点）
  Future<void> _performScheduledPreload() async {
    _logger.i('⏰ 执行定时预加载...');

    try {
      // 预加载近7天热门基金的历史净值明细
      final hotFunds = await _getHotFundsLast7Days();
      for (final fund in hotFunds) {
        // 移除数量限制
        final navHistory = await _preloadNavHistory(fund.code, 7);
        if (navHistory.isNotEmpty) {
          _updateMemoryCache(
              'nav_history_${fund.code}', navHistory, PreloadPriority.level4);
        }
      }

      _recordPreloadTime('scheduled_daily');
      _logger.d('✅ 定时预加载完成');
    } catch (e) {
      _logger.e('❌ 定时预加载失败: $e');
    }
  }

  /// 增量预加载（分页加载历史数据）
  Future<List<Map<String, dynamic>>> loadIncrementalHistoryData(
    String fundCode, {
    int days = 30,
    int offset = 0,
  }) async {
    final cacheKey = 'nav_history_incremental_${fundCode}_${offset}';

    // 检查缓存
    final cached = _getFromMemoryCache(cacheKey);
    if (cached != null) {
      return List<Map<String, dynamic>>.from(cached);
    }

    _logger.i('📈 增量加载历史数据: $fundCode, 偏移: $offset, 天数: $days');

    try {
      // 模拟API调用
      final historyData = await _fetchNavHistoryFromAPI(fundCode, days, offset);

      // 缓存结果
      _updateMemoryCache(cacheKey, historyData, PreloadPriority.level4);

      return historyData;
    } catch (e) {
      _logger.e('❌ 增量加载历史数据失败: $e');
      return [];
    }
  }

  /// 内存管理：LRU缓存淘汰
  void _manageMemoryUsage() {
    final totalMemory = _estimateMemoryUsage();
    final maxMemory = 200 * 1024 * 1024; // 200MB

    if (totalMemory > maxMemory) {
      _logger.d('🧹 内存使用超限，执行LRU淘汰...');

      // 淘汰3级以下低频数据
      final itemsToRemove = <String>[];
      for (final entry in _memoryCache.entries) {
        if (entry.value.priority.index >= PreloadPriority.level3.index) {
          itemsToRemove.add(entry.key);
        }
      }

      for (final key in itemsToRemove.take(itemsToRemove.length ~/ 2)) {
        _memoryCache.remove(key);
        _lruQueue.remove(key);
      }

      _logger.d('🧹 淘汰了 ${itemsToRemove.length} 个缓存项');
    }
  }

  /// 获取预加载统计信息
  PreloadingStatistics getStatistics() {
    final totalTasks =
        _activeTasks.values.fold(0, (sum, tasks) => sum + tasks.length);
    final completedTasks = _activeTasks.values.fold(
        0, (sum, tasks) => sum + tasks.where((t) => t.isCompleted).length);
    final failedTasks = _activeTasks.values
        .fold(0, (sum, tasks) => sum + tasks.where((t) => t.isFailed).length);

    return PreloadingStatistics(
      isRunning: _isRunning,
      totalActiveTasks: totalTasks,
      completedTasks: completedTasks,
      failedTasks: failedTasks,
      memoryCacheSize: _memoryCache.length,
      memoryUsageMB: _estimateMemoryUsage() / (1024 * 1024),
      lastPreloadTimes: Map.from(_lastPreloadTimes),
      lruQueueSize: _lruQueue.length,
    );
  }

  // ========== 私有方法 ==========

  /// 启动定时器
  void _startScheduledTimers() {
    // 每小时定时器（更新热门榜单）
    _hourlyTimer = Timer.periodic(_hourlyInterval, (_) {
      unawaited(_preloadLevel1Data());
    });

    // 每日定时器（凌晨3点预加载历史数据）
    _dailyTimer = Timer.periodic(_dailyInterval, (_) {
      final now = DateTime.now();
      if (now.hour == 3 && now.minute < 5) {
        unawaited(_performScheduledPreload());
      }
    });

    // 内存清理定时器
    _memoryCleanupTimer = Timer.periodic(_memoryCleanupInterval, (_) {
      _manageMemoryUsage();
    });
  }

  /// 检查是否可以执行预加载
  bool _canExecutePreload(PreloadPriority priority) {
    if (!_isRunning) return false;

    // 检查并发任务数量
    final currentTasks = _activeTasks[priority]?.length ?? 0;
    if (currentTasks >= _maxConcurrentTasks) {
      return false;
    }

    // 检查网络条件
    // 注意：这里简化了网络检查逻辑
    return true;
  }

  /// 添加预加载任务
  void _addTask(PreloadTask task) {
    _activeTasks.putIfAbsent(task.priority, () => <PreloadTask>{}).add(task);
  }

  /// 标记任务完成
  void _markTaskCompleted(PreloadTask task) {
    task.isCompleted = true;
    _activeTasks[task.priority]?.remove(task);
  }

  /// 标记任务失败
  void _markTaskFailed(PreloadTask task, String error) {
    task.isFailed = true;
    task.error = error;
    _activeTasks[task.priority]?.remove(task);
  }

  /// 记录预加载时间
  void _recordPreloadTime(String taskId) {
    _lastPreloadTimes[taskId] = DateTime.now();
  }

  /// 更新内存缓存（LRU策略）
  void _updateMemoryCache(String key, dynamic data, PreloadPriority priority) {
    // 如果缓存已存在，更新LRU队列
    if (_memoryCache.containsKey(key)) {
      _lruQueue.remove(key);
    } else if (_memoryCache.length >= _maxMemoryItems) {
      // 淘汰最久未使用的项
      final oldestKey = _lruQueue.removeAt(0);
      _memoryCache.remove(oldestKey);
    }

    _memoryCache[key] =
        CacheItem(data: data, priority: priority, lastAccess: DateTime.now());
    _lruQueue.add(key);
  }

  /// 从内存缓存获取数据
  dynamic _getFromMemoryCache(String key) {
    final item = _memoryCache[key];
    if (item != null) {
      // 更新访问时间
      item.lastAccess = DateTime.now();
      _lruQueue.remove(key);
      _lruQueue.add(key);
      return item.data;
    }
    return null;
  }

  /// 估算内存使用量
  int _estimateMemoryUsage() {
    // 简化估算：每个缓存项平均1KB
    return _memoryCache.length * 1024;
  }

  /// 加载用户自选基金
  Future<List<String>> _loadUserFavoriteFunds() async {
    try {
      final favorites = _prefs.getStringList('user_favorite_funds') ?? [];
      return favorites;
    } catch (e) {
      _logger.e('❌ 加载用户自选基金失败: $e');
      return [];
    }
  }

  /// 从缓存加载用户自选基金
  Future<List<FundInfo>> _loadUserFavoriteFundsFromCache() async {
    // 这里应该从本地缓存或数据库加载
    // 暂时返回模拟数据
    final favoriteCodes = await _loadUserFavoriteFunds();
    return favoriteCodes
        .map((code) => FundInfo(
              code: code,
              name: '自选基金$code',
              type: '混合型',
              pinyinAbbr: 'zxjj$code',
              pinyinFull: 'zixuanjijin$code',
            ))
        .toList();
  }

  /// 加载热门基金
  Future<List<FundInfo>> _loadHotFundsFromCache() async {
    // 这里应该从缓存或预计算结果加载
    // 暂时返回模拟数据
    return List.generate(
        50,
        (index) => FundInfo(
              code: '${(index + 1).toString().padLeft(6, '0')}',
              name: '热门基金${index + 1}',
              type: '股票型',
              pinyinAbbr: 'rmjj${index + 1}',
              pinyinFull: 'remenjijin${index + 1}',
            ));
  }

  /// 预加载同基金经理基金
  Future<List<FundInfo>> _preloadSameManagerFunds(String fundCode) async {
    // 模拟实现
    return List.generate(
        5,
        (index) => FundInfo(
              code: '${(1000 + index).toString().padLeft(6, '0')}',
              name: '同经理基金${index + 1}',
              type: '混合型',
              pinyinAbbr: 'tjljj${index + 1}',
              pinyinFull: 'tongjinglijiin${index + 1}',
            ));
  }

  /// 预加载同类型基金
  Future<List<FundInfo>> _preloadSameTypeFunds(String fundCode) async {
    // 模拟实现
    return List.generate(
        10,
        (index) => FundInfo(
              code: '${(2000 + index).toString().padLeft(6, '0')}',
              name: '同类型基金${index + 1}',
              type: '股票型',
              pinyinAbbr: 'tlxjj${index + 1}',
              pinyinFull: 'tongleixingjiin${index + 1}',
            ));
  }

  /// 预加载近期净值数据
  Future<List<Map<String, dynamic>>> _preloadRecentNavData(
      String fundCode) async {
    // 模拟实现
    return List.generate(30, (index) {
      final date = DateTime.now().subtract(Duration(days: 29 - index));
      return {
        'date': date.toIso8601String(),
        'nav': (1.0 + math.Random().nextDouble() * 0.2).toStringAsFixed(4),
        'change': (math.Random().nextDouble() * 0.04 - 0.02).toStringAsFixed(4),
      };
    });
  }

  /// 预加载基金财报摘要
  Future<Map<String, dynamic>> _preloadFundReportSummary(
      String fundCode) async {
    // 模拟实现
    return {
      'fund_code': fundCode,
      'quarter': '2024Q3',
      'total_assets': '50.23亿',
      'net_growth': '12.5%',
      'top_holdings': ['股票A', '股票B', '股票C'],
    };
  }

  /// 获取用户持仓基金
  Future<List<FundInfo>> _getUserPositionFunds() async {
    // 模拟实现
    return List.generate(
        3,
        (index) => FundInfo(
              code: '${(3000 + index).toString().padLeft(6, '0')}',
              name: '持仓基金${index + 1}',
              type: '债券型',
              pinyinAbbr: 'ccjj${index + 1}',
              pinyinFull: 'chicangjijin${index + 1}',
            ));
  }

  /// 获取近7天热门基金
  Future<List<FundInfo>> _getHotFundsLast7Days() async {
    // 模拟实现
    return List.generate(
        20,
        (index) => FundInfo(
              code: '${(4000 + index).toString().padLeft(6, '0')}',
              name: '7日热门基金${index + 1}',
              type: '指数型',
              pinyinAbbr: 'rqrmtop${index + 1}',
              pinyinFull: 'rireqingremen${index + 1}',
            ));
  }

  /// 预加载净值历史
  Future<List<Map<String, dynamic>>> _preloadNavHistory(
      String fundCode, int days) async {
    // 模拟实现
    return List.generate(days, (index) {
      final date = DateTime.now().subtract(Duration(days: days - 1 - index));
      return {
        'date': date.toIso8601String(),
        'nav': (1.0 + math.Random().nextDouble() * 0.3).toStringAsFixed(4),
        'accumulated':
            (1.0 + math.Random().nextDouble() * 0.5).toStringAsFixed(4),
      };
    });
  }

  /// 从API获取净值历史
  Future<List<Map<String, dynamic>>> _fetchNavHistoryFromAPI(
      String fundCode, int days, int offset) async {
    // 这里应该调用实际的API
    // 暂时返回模拟数据
    return List.generate(days, (index) {
      final date =
          DateTime.now().subtract(Duration(days: offset + days - 1 - index));
      return {
        'date': date.toIso8601String(),
        'nav': (1.0 + math.Random().nextDouble() * 0.2).toStringAsFixed(4),
        'change': (math.Random().nextDouble() * 0.04 - 0.02).toStringAsFixed(4),
      };
    });
  }

  /// 停止预加载管理器
  Future<void> stop() async {
    if (!_isRunning) return;

    _isRunning = false;

    // 取消所有定时器
    _hourlyTimer?.cancel();
    _dailyTimer?.cancel();
    _memoryCleanupTimer?.cancel();

    // 清理所有活动任务
    for (final tasks in _activeTasks.values) {
      for (final task in tasks) {
        task.cancel();
      }
    }
    _activeTasks.clear();

    // 清理缓存
    _memoryCache.clear();
    _lruQueue.clear();

    _logger.i('🔚 智能预加载管理器已停止');
  }

  /// 非等待执行
  void unawaited(Future<void> future) {
    // 忽略结果，避免警告
  }

  /// Isolate中的2级数据预加载
  static void _preloadLevel2DataInIsolate(SendPort sendPort) {
    try {
      // 在Isolate中执行预加载逻辑
      // 这里应该包含实际的预加载代码

      // 模拟耗时操作
      Future.delayed(const Duration(seconds: 2));

      sendPort.send('completed');
    } catch (e) {
      sendPort.send('error: $e');
    }
  }
}

/// 预加载任务
class PreloadTask {
  final String id;
  final PreloadPriority priority;
  final PreloadTrigger trigger;
  final DateTime startTime;
  bool isCompleted = false;
  bool isFailed = false;
  String? error;

  PreloadTask({
    required this.id,
    required this.priority,
    required this.trigger,
    required this.startTime,
  });

  void cancel() {
    isFailed = true;
    error = 'Task cancelled';
  }
}

/// 缓存项
class CacheItem {
  final dynamic data;
  final PreloadPriority priority;
  DateTime lastAccess;

  CacheItem({
    required this.data,
    required this.priority,
    required this.lastAccess,
  });
}

/// 预加载统计信息
class PreloadingStatistics {
  final bool isRunning;
  final int totalActiveTasks;
  final int completedTasks;
  final int failedTasks;
  final int memoryCacheSize;
  final double memoryUsageMB;
  final Map<String, DateTime> lastPreloadTimes;
  final int lruQueueSize;

  PreloadingStatistics({
    required this.isRunning,
    required this.totalActiveTasks,
    required this.completedTasks,
    required this.failedTasks,
    required this.memoryCacheSize,
    required this.memoryUsageMB,
    required this.lastPreloadTimes,
    required this.lruQueueSize,
  });

  @override
  String toString() {
    return '''
PreloadingStatistics:
  运行状态: ${isRunning ? '运行中' : '已停止'}
  活动任务: $totalActiveTasks
  已完成任务: $completedTasks
  失败任务: $failedTasks
  内存缓存: $memoryCacheSize 项
  内存使用: ${memoryUsageMB.toStringAsFixed(1)}MB
  LRU队列: $lruQueueSize 项
  最后预加载: ${lastPreloadTimes.length} 个记录
    ''';
  }
}
