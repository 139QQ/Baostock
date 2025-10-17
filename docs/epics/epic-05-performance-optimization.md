# Epic 5: 性能优化

## 史诗概述
对Flutter基金分析应用进行全面的性能优化，包括页面加载优化、图片和数据缓存、内存管理以及错误处理机制的完善。通过系统化的性能优化，确保应用在各种设备和网络环境下都能提供流畅的用户体验。

## 史诗目标
- 实现页面加载时间优化，确保首屏加载时间<3秒，后续页面加载<1秒
- 构建高效的图片和数据缓存系统，减少网络请求，提升响应速度
- 优化内存使用，防止内存泄漏，确保长时间运行稳定性
- 完善错误处理和降级机制，提升应用的容错能力
- 建立性能监控体系，实时跟踪和优化应用性能指标

## 功能范围

### 1. 页面加载优化
**启动性能优化:**
```dart
// 应用启动优化
void main() async {
  // 1. 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 2. 并行初始化多个服务
  await Future.wait([
    _initializeServices(),
    _preloadEssentialData(),
    _setupErrorHandling(),
  ]);

  // 3. 启动应用
  runApp(MyApp());
}

// 服务初始化优化
Future<void> _initializeServices() async {
  // 并行初始化核心服务
  await Future.wait([
    Hive.initFlutter(),
    SharedPreferences.getInstance(),
    _initializeFirebase(),
    _setupDependencyInjection(),
  ]);
}

// 路由懒加载优化
class AppRouter {
  static final GoRouter router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/fund/rankings',
        // 使用懒加载减少初始包大小
        builder: (context, state) => DeferredWidget(
          future: _loadFundRankingPage(),
          placeholder: const LoadingWidget(),
        ),
      ),
      GoRoute(
        path: '/fund/details/:code',
        builder: (context, state) {
          final code = state.pathParameters['code']!;
          return DeferredWidget(
            future: _loadFundDetailPage(),
            placeholder: const LoadingWidget(),
            // 预传递参数，减少页面加载时间
            params: {'fundCode': code},
          );
        },
      ),
    ],
  );

  // 异步加载页面组件
  static Future<Widget> _loadFundRankingPage() async {
    await Future.delayed(Duration.zero); // 让出事件循环
    return FundRankingPage();
  }
}
```

**组件渲染优化:**
```dart
// 虚拟滚动优化
class VirtualScrollList extends StatelessWidget {
  final List<FundRanking> items;
  final Widget Function(BuildContext, int) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      // 预加载优化
      cacheExtent: 200.0,
      // 根据内容动态计算item高度
      itemExtent: 120.0,
      // 减少重建次数
      addAutomaticKeepAlives: true,
      // 优化内存使用
      addRepaintBoundaries: true,
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _OptimizedListItem(
          key: ValueKey(items[index].fundCode),
          child: itemBuilder(context, index),
        );
      },
    );
  }
}

// 优化列表项组件
class _OptimizedListItem extends StatefulWidget {
  final Widget child;

  const _OptimizedListItem({Key? key, required this.child}) : super(key: key);

  @override
  __OptimizedListItemState createState() => __OptimizedListItemState();
}

class __OptimizedListItemState extends State<_OptimizedListItem>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // 保持状态，减少重建

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用
    return widget.child;
  }
}

// 图片懒加载优化
class OptimizedImageWidget extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      // 缓存网络图片
      cacheWidth: width?.toInt(),
      cacheHeight: height?.toInt(),
      // 加载指示器
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      // 错误处理
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: Icon(
            Icons.broken_image,
            color: Colors.grey[400],
            size: 32,
          ),
        );
      },
      // 内存优化
      fit: BoxFit.cover,
      filterQuality: FilterQuality.low,
    );
  }
}
```

**骨架屏优化:**
```dart
// 骨架屏组件
class SkeletonWidget extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonWidget({
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: borderRadius ?? BorderRadius.circular(4),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: borderRadius ?? BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

// 基金排行骨架屏
class FundRankingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    SkeletonWidget(width: 32, height: 32, borderRadius: BorderRadius.circular(16)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonWidget(width: double.infinity, height: 16),
                          SizedBox(height: 8),
                          SkeletonWidget(width: 120, height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SkeletonWidget(width: 80, height: 24),
                    SkeletonWidget(width: 60, height: 16),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

### 2. 图片和数据缓存
**智能缓存策略:**
```dart
// 统一缓存管理器
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  // 内存缓存
  final Map<String, CacheEntry> _memoryCache = {};

  // 磁盘缓存
  late Box<dynamic> _diskCache;

  // 缓存配置
  static const int _maxMemoryCacheSize = 100;
  static const Duration _defaultCacheDuration = Duration(minutes: 15);

  // 初始化缓存
  Future<void> initialize() async {
    _diskCache = await Hive.openBox('app_cache');
  }

  // 获取缓存
  Future<T?> get<T>(String key, {Duration? maxAge}) async {
    final now = DateTime.now();

    // 1. 检查内存缓存
    if (_memoryCache.containsKey(key)) {
      final entry = _memoryCache[key]!;
      if (entry.isValid(now, maxAge ?? _defaultCacheDuration)) {
        return entry.data as T;
      } else {
        _memoryCache.remove(key);
      }
    }

    // 2. 检查磁盘缓存
    final diskData = _diskCache.get(key);
    if (diskData != null) {
      try {
        final entry = CacheEntry.fromJson(diskData);
        if (entry.isValid(now, maxAge ?? _defaultCacheDuration)) {
          // 恢复到内存缓存
          _memoryCache[key] = entry;
          _ensureMemoryCacheSize();
          return entry.data as T;
        } else {
          await _diskCache.delete(key);
        }
      } catch (e) {
        // 缓存数据损坏，删除
        await _diskCache.delete(key);
      }
    }

    return null;
  }

  // 设置缓存
  Future<void> set<T>(String key, T data, {Duration? maxAge}) async {
    final entry = CacheEntry(
      data: data,
      timestamp: DateTime.now(),
      maxAge: maxAge ?? _defaultCacheDuration,
    );

    // 保存到内存缓存
    _memoryCache[key] = entry;
    _ensureMemoryCacheSize();

    // 保存到磁盘缓存
    await _diskCache.put(key, entry.toJson());
  }

  // 确保内存缓存大小
  void _ensureMemoryCacheSize() {
    if (_memoryCache.length > _maxMemoryCacheSize) {
      // LRU淘汰策略
      final sortedEntries = _memoryCache.entries.toList()
        ..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));

      final toRemove = sortedEntries.take(_memoryCache.length - _maxMemoryCacheSize);
      for (final entry in toRemove) {
        _memoryCache.remove(entry.key);
      }
    }
  }

  // 清理过期缓存
  Future<void> cleanup() async {
    final now = DateTime.now();

    // 清理内存缓存
    final expiredKeys = _memoryCache.entries
        .where((entry) => !entry.value.isValid(now))
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredKeys) {
      _memoryCache.remove(key);
    }

    // 清理磁盘缓存
    final diskKeys = _diskCache.keys.toList();
    for (final key in diskKeys) {
      try {
        final data = _diskCache.get(key);
        if (data != null) {
          final entry = CacheEntry.fromJson(data);
          if (!entry.isValid(now)) {
            await _diskCache.delete(key);
          }
        }
      } catch (e) {
        await _diskCache.delete(key);
      }
    }
  }
}

// 缓存条目
class CacheEntry {
  final dynamic data;
  final DateTime timestamp;
  final Duration maxAge;

  CacheEntry({
    required this.data,
    required this.timestamp,
    required this.maxAge,
  });

  bool isValid([DateTime? currentTime]) {
    final now = currentTime ?? DateTime.now();
    return now.isBefore(timestamp.add(maxAge));
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'maxAge': maxAge.inMilliseconds,
    };
  }

  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    return CacheEntry(
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),
      maxAge: Duration(milliseconds: json['maxAge']),
    );
  }
}
```

**图片缓存优化:**
```dart
// 高级图片缓存管理器
class ImageCacheManager {
  static final ImageCacheManager _instance = ImageCacheManager._internal();
  factory ImageCacheManager() => _instance;
  ImageCacheManager._internal();

  final Map<String, ImageStreamCompleter> _cache = {};
  final Map<String, int> _accessCount = {};

  // 缓存配置
  static const int _maxCacheSize = 50; // 最多缓存50张图片
  static const Duration _cacheDuration = Duration(hours: 24);

  // 获取图片
  ImageStreamCompleter getImage(String url, {Map<String, String>? headers}) {
    if (_cache.containsKey(url)) {
      _accessCount[url] = (_accessCount[url] ?? 0) + 1;
      return _cache[url]!;
    }

    // 创建新的图片加载器
    final completer = _createImageCompleter(url, headers);

    // 添加到缓存
    _cache[url] = completer;
    _accessCount[url] = 1;

    // 确保缓存大小
    _ensureCacheSize();

    return completer;
  }

  ImageStreamCompleter _createImageCompleter(String url, Map<String, String>? headers) {
    final completer = ImageStreamCompleter();

    // 异步加载图片
    _loadImage(url, headers).then((imageInfo) {
      completer.setImage(imageInfo);
    }).catchError((error) {
      completer.setError(error);
    });

    return completer;
  }

  Future<ImageInfo> _loadImage(String url, Map<String, String>? headers) async {
    // 1. 尝试从磁盘缓存加载
    final cachedImage = await _loadFromDiskCache(url);
    if (cachedImage != null) {
      return cachedImage;
    }

    // 2. 从网络加载
    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      final Uint8List bytes = response.bodyBytes;

      // 3. 解码图片
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();

      final imageInfo = ImageInfo(
        image: frame.image,
        scale: 1.0,
      );

      // 4. 保存到磁盘缓存
      await _saveToDiskCache(url, bytes);

      return imageInfo;
    } else {
      throw Exception('Failed to load image: ${response.statusCode}');
    }
  }

  void _ensureCacheSize() {
    if (_cache.length > _maxCacheSize) {
      // LRU淘汰策略
      final sortedEntries = _accessCount.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));

      final toRemove = sortedEntries.take(_cache.length - _maxCacheSize);

      for (final entry in toRemove) {
        _cache.remove(entry.key);
        _accessCount.remove(entry.key);
      }
    }
  }

  // 清理过期缓存
  void clearExpiredCache() {
    final keysToRemove = <String>[];

    for (final entry in _cache.entries) {
      // 检查图片是否还在使用
      if (entry.value.hasListeners) {
        continue;
      }

      // 检查访问频率
      final accessCount = _accessCount[entry.key] ?? 0;
      if (accessCount < 2) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      _cache.remove(key);
      _accessCount.remove(key);
    }
  }
}
```

**数据预加载策略:**
```dart
// 智能数据预加载服务
class DataPreloadService {
  static final DataPreloadService _instance = DataPreloadService._internal();
  factory DataPreloadService() => _instance;
  DataPreloadService._internal();

  final CacheManager _cacheManager = CacheManager();
  final Set<String> _preloadingKeys = {};

  // 预加载基金排行数据
  Future<void> preloadFundRankings() async {
    const categories = ['股票型', '混合型', '债券型', '货币型'];
    const periods = ['1M', '3M', '6M', '1Y', '3Y'];

    for (final category in categories) {
      for (final period in periods) {
        final cacheKey = 'fund_rankings_${category}_${period}';

        // 避免重复预加载
        if (_preloadingKeys.contains(cacheKey)) continue;

        _preloadingKeys.add(cacheKey);

        // 异步预加载，不阻塞主线程
        _preloadFundRankingsData(category, period).then((_) {
          _preloadingKeys.remove(cacheKey);
        }).catchError((error) {
          _preloadingKeys.remove(cacheKey);
          print('预加载失败: $cacheKey, 错误: $error');
        });
      }
    }
  }

  Future<void> _preloadFundRankingsData(String category, String period) async {
    try {
      final cacheKey = 'fund_rankings_${category}_${period}';

      // 检查是否已缓存
      final cachedData = await _cacheManager.get<List<FundRanking>>(cacheKey);
      if (cachedData != null) {
        return;
      }

      // 加载数据
      final rankings = await _fetchFundRankings(category, period);

      // 缓存数据
      await _cacheManager.set(cacheKey, rankings, maxAge: Duration(minutes: 15));

      print('预加载完成: $cacheKey');
    } catch (e) {
      throw Exception('预加载基金排行数据失败: $e');
    }
  }

  // 基于用户行为的智能预加载
  void startSmartPreloading(BuildContext context) {
    // 监听页面切换
    final routeObserver = RouteObserver<PageRoute>();

    // 监听用户行为
    final userBehaviorTracker = UserBehaviorTracker();

    userBehaviorTracker.behaviorStream.listen((behavior) {
      // 基于用户行为预测需要预加载的数据
      _predictAndPreloadData(behavior);
    });
  }

  void _predictAndPreloadData(UserBehavior behavior) {
    // 1. 如果用户经常查看某类基金，预加载相关数据
    if (behavior.mostViewedCategories.isNotEmpty) {
      for (final category in behavior.mostViewedCategories.take(3)) {
        preloadFundDataForCategory(category);
      }
    }

    // 2. 如果用户有关注基金，预加载详情数据
    if (behavior.watchedFunds.isNotEmpty) {
      for (final fundCode in behavior.watchedFunds.take(5)) {
        preloadFundDetailData(fundCode);
      }
    }

    // 3. 预加载用户可能感兴趣的数据
    if (behavior.searchHistory.isNotEmpty) {
      final recentSearches = behavior.searchHistory.take(3);
      for (final searchTerm in recentSearches) {
        preloadSearchResults(searchTerm);
      }
    }
  }
}
```

### 3. 内存管理
**内存监控和优化:**
```dart
// 内存管理器
class MemoryManager {
  static final MemoryManager _instance = MemoryManager._internal();
  factory MemoryManager() => _instance;
  MemoryManager._internal();

  Timer? _cleanupTimer;
  final StreamController<MemoryInfo> _memoryStreamController = StreamController.broadcast();

  // 内存阈值配置
  static const int _warningThresholdMB = 200;
  static const int _criticalThresholdMB = 300;
  static const Duration _cleanupInterval = Duration(minutes: 5);

  // 初始化内存管理
  void initialize() {
    // 启动定期清理
    _cleanupTimer = Timer.periodic(_cleanupInterval, (_) {
      _performMemoryCleanup();
    });

    // 监听内存警告
    if (Platform.isIOS) {
      _setupiOSMemoryWarnings();
    } else if (Platform.isAndroid) {
      _setupAndroidMemoryWarnings();
    }
  }

  // 获取当前内存使用情况
  Future<MemoryInfo> getMemoryInfo() async {
    final currentRSS = await _getCurrentRSS();
    final totalRAM = await _getTotalRAM();

    return MemoryInfo(
      currentRSS: currentRSS,
      totalRAM: totalRAM,
      usagePercentage: (currentRSS / totalRAM) * 100,
      timestamp: DateTime.now(),
    );
  }

  // 执行内存清理
  Future<void> _performMemoryCleanup() async {
    final memoryInfo = await getMemoryInfo();

    // 发布内存信息
    _memoryStreamController.add(memoryInfo);

    // 检查是否需要清理
    if (memoryInfo.currentRSS > _warningThresholdMB * 1024 * 1024) {
      await _cleanupMemory();
    }

    // 严重内存警告
    if (memoryInfo.currentRSS > _criticalThresholdMB * 1024 * 1024) {
      await _emergencyCleanup();
    }
  }

  // 常规内存清理
  Future<void> _cleanupMemory() async {
    print('执行内存清理...');

    // 1. 清理图片缓存
    ImageCacheManager().clearExpiredCache();

    // 2. 清理数据缓存
    await CacheManager().cleanup();

    // 3. 触发垃圾回收
    if (kDebugMode) {
      print('建议执行垃圾回收');
    }

    // 4. 清理BLoC状态
    _cleanupBlocStates();

    // 5. 清理定时器
    _cleanupTimers();
  }

  // 紧急内存清理
  Future<void> _emergencyCleanup() async {
    print('执行紧急内存清理...');

    // 1. 清空所有缓存
    await _clearAllCaches();

    // 2. 释放非必要资源
    await _releaseNonEssentialResources();

    // 3. 通知监听者
    _memoryStreamController.add(MemoryEmergencyEvent(
      timestamp: DateTime.now(),
      message: '执行紧急内存清理',
    ));
  }

  // 清理BLoC状态
  void _cleanupBlocStates() {
    // 通知各个BLoC清理状态
    // 这里可以通过事件总线或状态管理器来通知
  }

  // 清理定时器
  void _cleanupTimers() {
    // 清理非必要的定时器
    // 保留核心的定时器如内存管理、数据同步等
  }

  // 获取当前RSS内存使用
  Future<int> _getCurrentRSS() async {
    if (Platform.isAndroid || Platform.isIOS) {
      // 使用平台通道获取内存信息
      try {
        final result = await MethodChannel('memory_info')
            .invokeMethod('getCurrentRSS');
        return result as int;
      } catch (e) {
        print('获取内存信息失败: $e');
        return 0;
      }
    }
    return 0;
  }

  // 获取总内存
  Future<int> _getTotalRAM() async {
    // 实现获取总内存的逻辑
    return 4 * 1024 * 1024 * 1024; // 默认4GB
  }

  void dispose() {
    _cleanupTimer?.cancel();
    _memoryStreamController.close();
  }
}

// 内存信息
class MemoryInfo {
  final int currentRSS;
  final int totalRAM;
  final double usagePercentage;
  final DateTime timestamp;

  MemoryInfo({
    required this.currentRSS,
    required this.totalRAM,
    required this.usagePercentage,
    required this.timestamp,
  });
}

// 内存紧急事件
class MemoryEmergencyEvent extends MemoryInfo {
  final String message;

  MemoryEmergencyEvent({
    required DateTime timestamp,
    required this.message,
  }) : super(
    currentRSS: 0,
    totalRAM: 0,
    usagePercentage: 0,
    timestamp: timestamp,
  );
}
```

**内存泄漏检测:**
```dart
// 内存泄漏检测器
class MemoryLeakDetector {
  static final MemoryLeakDetector _instance = MemoryLeakDetector._internal();
  factory MemoryLeakDetector() => _instance;
  MemoryLeakDetector._internal();

  final Map<String, WeakReference<dynamic>> _trackedObjects = {};
  final Map<String, DateTime> _objectCreationTime = {};
  Timer? _detectionTimer;

  // 开始内存泄漏检测
  void startDetection() {
    _detectionTimer = Timer.periodic(Duration(minutes: 1), (_) {
      _detectMemoryLeaks();
    });
  }

  // 跟踪对象
  void trackObject(String id, dynamic object) {
    _trackedObjects[id] = WeakReference(object);
    _objectCreationTime[id] = DateTime.now();
  }

  // 停止跟踪对象
  void untrackObject(String id) {
    _trackedObjects.remove(id);
    _objectCreationTime.remove(id);
  }

  // 检测内存泄漏
  void _detectMemoryLeaks() {
    final now = DateTime.now();
    final leakedObjects = <String>[];

    for (final entry in _trackedObjects.entries) {
      final id = entry.key;
      final weakRef = entry.value;
      final creationTime = _objectCreationTime[id];

      if (weakRef.target != null && creationTime != null) {
        final age = now.difference(creationTime);

        // 如果对象存活时间超过阈值，可能是内存泄漏
        if (age > Duration(minutes: 10)) {
          leakedObjects.add(id);

          if (kDebugMode) {
            print('检测到可能的内存泄漏: $id, 存活时间: ${age.inMinutes}分钟');
          }
        }
      }
    }

    if (leakedObjects.isNotEmpty) {
      _reportMemoryLeaks(leakedObjects);
    }
  }

  void _reportMemoryLeaks(List<String> leakedObjects) {
    // 报告内存泄漏
    // 可以发送到远程日志服务或显示在调试界面

    if (kDebugMode) {
      print('内存泄漏报告: ${leakedObjects.length}个对象可能泄漏');
      for (final id in leakedObjects) {
        print('- $id');
      }
    }
  }

  void dispose() {
    _detectionTimer?.cancel();
    _trackedObjects.clear();
    _objectCreationTime.clear();
  }
}

// 弱引用包装器
class WeakReference<T> {
  Expando<T> _expando = Expando<T>();

  WeakReference(T object) {
    _expando[this] = object;
  }

  T? get target => _expando[this];
}
```

### 4. 错误处理和降级机制
**统一的错误处理:**
```dart
// 错误分类和处理
class AppError implements Exception {
  final String message;
  final ErrorType type;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppError({
    required this.message,
    required this.type,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'AppError: $type - $message';
}

enum ErrorType {
  network,
  server,
  authentication,
  authorization,
  validation,
  notFound,
  timeout,
  rateLimit,
  unknown,
}

// 错误处理器
class ErrorHandler {
  static AppError handleError(dynamic error) {
    if (error is AppError) {
      return error;
    }

    // 网络错误
    if (error is SocketException) {
      return AppError(
        message: '网络连接失败，请检查网络设置',
        type: ErrorType.network,
        originalError: error,
      );
    }

    // 超时错误
    if (error is TimeoutException) {
      return AppError(
        message: '请求超时，请稍后重试',
        type: ErrorType.timeout,
        originalError: error,
      );
    }

    // HTTP错误
    if (error is DioException) {
      return _handleDioError(error);
    }

    // 数据解析错误
    if (error is FormatException || error is TypeError) {
      return AppError(
        message: '数据格式错误',
        type: ErrorType.validation,
        originalError: error,
      );
    }

    // 未知错误
    return AppError(
      message: '发生未知错误，请稍后重试',
      type: ErrorType.unknown,
      originalError: error,
    );
  }

  static AppError _handleDioError(DioException error) {
    final statusCode = error.response?.statusCode;

    switch (statusCode) {
      case 400:
        return AppError(
          message: '请求参数错误',
          type: ErrorType.validation,
          originalError: error,
        );
      case 401:
        return AppError(
          message: '身份验证失败，请重新登录',
          type: ErrorType.authentication,
          originalError: error,
        );
      case 403:
        return AppError(
          message: '没有权限访问此资源',
          type: ErrorType.authorization,
          originalError: error,
        );
      case 404:
        return AppError(
          message: '请求的资源不存在',
          type: ErrorType.notFound,
          originalError: error,
        );
      case 429:
        return AppError(
          message: '请求过于频繁，请稍后重试',
          type: ErrorType.rateLimit,
          originalError: error,
        );
      case 500:
      case 502:
      case 503:
        return AppError(
          message: '服务器错误，请稍后重试',
          type: ErrorType.server,
          originalError: error,
        );
      default:
        return AppError(
          message: '网络请求失败',
          type: ErrorType.network,
          originalError: error,
        );
    }
  }
}
```

**降级策略实现:**
```dart
// 降级策略管理器
class FallbackManager {
  static final FallbackManager _instance = FallbackManager._internal();
  factory FallbackManager() => _instance;
  FallbackManager._internal();

  final Map<String, FallbackStrategy> _strategies = {};

  // 注册降级策略
  void registerStrategy(String key, FallbackStrategy strategy) {
    _strategies[key] = strategy;
  }

  // 执行带降级策略的操作
  Future<T> executeWithFallback<T>(
    String strategyKey,
    Future<T> Function() primaryOperation,
  ) async {
    final strategy = _strategies[strategyKey];
    if (strategy == null) {
      // 没有降级策略，直接执行主操作
      return await primaryOperation();
    }

    return await strategy.execute(primaryOperation);
  }
}

// 降级策略抽象类
abstract class FallbackStrategy {
  Future<T> execute<T>(Future<T> Function() primaryOperation);
}

// API降级策略
class ApiFallbackStrategy implements FallbackStrategy {
  final Future<dynamic> Function()? fallbackOperation;
  final dynamic Function()? mockOperation;

  ApiFallbackStrategy({
    this.fallbackOperation,
    this.mockOperation,
  });

  @override
  Future<T> execute<T>(Future<T> Function() primaryOperation) async {
    try {
      // 1. 尝试主操作
      return await primaryOperation();
    } catch (e) {
      print('主操作失败: $e');

      // 2. 尝试降级操作
      if (fallbackOperation != null) {
        try {
          return await fallbackOperation!() as T;
        } catch (fallbackError) {
          print('降级操作失败: $fallbackError');
        }
      }

      // 3. 使用模拟数据
      if (mockOperation != null) {
        try {
          return mockOperation!() as T;
        } catch (mockError) {
          print('模拟数据失败: $mockError');
        }
      }

      // 4. 抛出原始错误
      throw e;
    }
  }
}

// 缓存降级策略
class CacheFallbackStrategy implements FallbackStrategy {
  final CacheManager cacheManager;
  final String cacheKey;
  final Duration cacheDuration;

  CacheFallbackStrategy({
    required this.cacheManager,
    required this.cacheKey,
    required this.cacheDuration,
  });

  @override
  Future<T> execute<T>(Future<T> Function() primaryOperation) async {
    try {
      // 1. 尝试从缓存获取
      final cachedData = await cacheManager.get<T>(cacheKey, maxAge: cacheDuration);
      if (cachedData != null) {
        return cachedData;
      }

      // 2. 执行主操作
      final result = await primaryOperation();

      // 3. 缓存结果
      await cacheManager.set(cacheKey, result, maxAge: cacheDuration);

      return result;
    } catch (e) {
      // 4. 如果主操作失败，尝试获取过期缓存
      final expiredData = await cacheManager.get<T>(cacheKey);
      if (expiredData != null) {
        print('使用过期缓存数据: $cacheKey');
        return expiredData;
      }

      // 5. 抛出错误
      throw e;
    }
  }
}
```

**应用级降级机制:**
```dart
// 应用降级管理器
class AppDegradationManager {
  static final AppDegradationManager _instance = AppDegradationManager._internal();
  factory AppDegradationManager() => _instance;
  AppDegradationManager._internal();

  AppDegradationLevel _currentLevel = AppDegradationLevel.normal;
  final StreamController<AppDegradationLevel> _degradationStream = StreamController.broadcast();

  // 降级级别
  enum AppDegradationLevel {
    normal,      // 正常模式
    minimal,     // 最小功能模式
    emergency,   // 紧急模式
    offline,     // 离线模式
  }

  // 设置降级级别
  void setDegradationLevel(AppDegradationLevel level) {
    if (_currentLevel != level) {
      _currentLevel = level;
      _degradationStream.add(level);
      _applyDegradationLevel(level);
    }
  }

  // 应用降级级别
  void _applyDegradationLevel(AppDegradationLevel level) {
    switch (level) {
      case AppDegradationLevel.normal:
        _enableAllFeatures();
        break;
      case AppDegradationLevel.minimal:
        _enableMinimalFeatures();
        break;
      case AppDegradationLevel.emergency:
        _enableEmergencyFeatures();
        break;
      case AppDegradationLevel.offline:
        _enableOfflineFeatures();
        break;
    }
  }

  void _enableMinimalFeatures() {
    // 只启用核心功能
    // 禁用非必要的动画和视觉效果
    // 减少数据加载频率
    // 简化UI组件
  }

  void _enableEmergencyFeatures() {
    // 只显示静态内容
    // 禁用所有网络请求
    // 只使用本地缓存数据
    // 显示紧急模式提示
  }

  void _enableOfflineFeatures() {
    // 启用离线模式
    // 只使用本地数据
    // 禁用实时更新
    // 提供离线提示
  }

  void _enableAllFeatures() {
    // 启用所有功能
    // 恢复正常UI
    // 恢复网络请求
    // 清除降级状态
  }

  // 自动降级检测
  void startAutoDegradationDetection() {
    // 监听网络状态
    Connectivity().onConnectivityChanged.listen((result) {
      if (result == ConnectivityResult.none) {
        setDegradationLevel(AppDegradationLevel.offline);
      } else {
        setDegradationLevel(AppDegradationLevel.normal);
      }
    });

    // 监听内存使用
    MemoryManager().getMemoryStream().listen((memoryInfo) {
      if (memoryInfo is MemoryEmergencyEvent) {
        setDegradationLevel(AppDegradationLevel.emergency);
      } else if (memoryInfo.usagePercentage > 80) {
        setDegradationLevel(AppDegradationLevel.minimal);
      } else {
        setDegradationLevel(AppDegradationLevel.normal);
      }
    });
  }

  Stream<AppDegradationLevel> get degradationStream => _degradationStream.stream;

  AppDegradationLevel get currentLevel => _currentLevel;

  void dispose() {
    _degradationStream.close();
  }
}
```

## 验收标准

### 性能指标
- [ ] 应用冷启动时间 < 3秒
- [ ] 页面切换响应时间 < 500ms
- [ ] 数据加载时间 < 1秒（有缓存）
- [ ] 内存使用峰值 < 200MB
- [ ] 帧率稳定在 60fps

### 缓存效果
- [ ] 缓存命中率 > 80%
- [ ] 网络请求减少 > 60%
- [ ] 重复数据加载时间 < 100ms

### 稳定性指标
- [ ] 崩溃率 < 0.1%
- [ ] 内存泄漏检测通过
- [ ] 长时间运行稳定性测试通过
- [ ] 降级机制正常工作

## 开发时间估算

### 工作量评估
- **页面加载优化**: 32小时
- **缓存系统实现**: 40小时
- **内存管理优化**: 32小时
- **错误处理和降级**: 24小时
- **性能监控实现**: 24小时
- **测试和调优**: 24小时

**总计: 176小时（约22个工作日）**

## 依赖关系

### 前置依赖
- Epic 1: 基础架构搭建完成
- Epic 2: 数据层架构完成
- Epic 3: 核心功能模块完成
- 性能测试环境搭建完成

### 后续影响
- 提升用户体验和满意度
- 降低应用崩溃率
- 提高用户留存率
- 为后续功能扩展奠定基础

## 风险评估

### 技术风险
| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| 缓存一致性问题 | 中 | 中 | 设计合理的缓存失效策略 |
| 内存优化过度 | 低 | 中 | 平衡性能和功能完整性 |
| 降级机制复杂 | 中 | 中 | 采用渐进式降级策略 |

### 性能风险
| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| 优化效果不明显 | 中 | 中 | 建立基准测试，持续优化 |
| 引入新的性能问题 | 低 | 高 | 充分测试，渐进式部署 |

## 资源需求

### 人员配置
- **Flutter性能专家**: 2人
- **后端性能工程师**: 1人
- **测试工程师**: 1人（兼职）
- **运维工程师**: 1人（兼职）

### 技术资源
- 性能分析工具
- 压力测试工具
- 内存分析工具
- 网络分析工具

## 交付物

### 代码交付
- 页面加载优化代码
- 缓存系统实现代码
- 内存管理优化代码
- 错误处理和降级机制代码

### 文档交付
- 性能优化指南
- 缓存策略文档
- 内存管理最佳实践
- 性能监控报告

### 测试交付
- 性能基准测试报告
- 压力测试报告
- 内存泄漏检测报告
- 用户体验测试报告

---

**史诗负责人:** 性能架构师
**预计开始时间:** 2026-01-26
**预计完成时间:** 2026-02-25
**优先级:** P1（高）
**状态:** 待开始
**依赖史诗:** Epic 1, Epic 2, Epic 3