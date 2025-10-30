# 统一缓存系统使用指南

## 目录

1. [快速入门](#快速入门)
2. [核心概念](#核心概念)
3. [实际应用场景](#实际应用场景)
4. [最佳实践](#最佳实践)
5. [性能调优](#性能调优)
6. [故障排查](#故障排查)
7. [迁移指南](#迁移指南)

## 快速入门

### 第一步：添加依赖

确保你的项目已经配置了必要的依赖：

```yaml
dependencies:
  flutter:
    sdk: flutter
  hive: ^2.2.3
  hive_flutter: ^1.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  hive_generator: ^2.0.0
  build_runner: ^2.3.3
```

### 第二步：初始化缓存系统

```dart
import 'package:jisu_fund_analyzer/src/core/cache/interfaces/i_unified_cache_service.dart';
import 'package:jisu_fund_analyzer/src/core/cache/unified_cache_manager.dart';
import 'package:jisu_fund_analyzer/src/core/cache/storage/cache_storage.dart';
import 'package:jisu_fund_analyzer/src/core/cache/strategies/cache_strategies.dart';
import 'package:jisu_fund_analyzer/src/core/cache/config/cache_config_manager.dart';

class CacheManager {
  static late IUnifiedCacheService _cacheService;

  static Future<void> initialize() async {
    // 创建存储层
    final storage = CacheStorageFactory.createHiveStorage('fund_analyzer_cache');
    await storage.initialize();

    // 创建缓存策略
    final strategy = CacheStrategyFactory.getStrategy('lru');

    // 创建配置管理器
    final configManager = CacheConfigManager();

    // 创建统一缓存管理器
    _cacheService = UnifiedCacheManager(
      storage: storage,
      strategy: strategy,
      configManager: configManager,
      config: UnifiedCacheConfig.production(),
    );

    print('缓存系统初始化完成');
  }

  static IUnifiedCacheService get instance => _cacheService;
}
```

### 第三步：基础使用

```dart
// 在应用启动时初始化
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CacheManager.initialize();
  runApp(MyApp());
}

// 在业务代码中使用
class FundService {
  Future<FundData?> getFundData(String code) async {
    // 尝试从缓存获取
    final cachedData = await CacheManager.instance.get<FundData>('fund:$code');

    if (cachedData != null) {
      print('从缓存获取基金数据: $code');
      return cachedData;
    }

    // 缓存未命中，从API获取
    print('从API获取基金数据: $code');
    final apiData = await fetchFundDataFromAPI(code);

    if (apiData != null) {
      // 存储到缓存，设置30分钟过期
      await CacheManager.instance.put(
        'fund:$code',
        apiData,
        config: CacheConfig(
          ttl: Duration(minutes: 30),
          priority: 8, // 高优先级
          tags: {'fund', 'data'},
        ),
      );
    }

    return apiData;
  }
}
```

## 核心概念

### 缓存键命名规范

采用分层命名策略，便于管理和维护：

```dart
// ✅ 推荐的命名格式
await cacheService.put('fund:profile:000001', fundProfile);
await cacheService.put('fund:ranking:sector:technology', sectorRanking);
await cacheService.put('user:preference:123', userPreference);
await cacheService.put('search:result:fund:name:科技', searchResults);

// ✅ 版本控制
await cacheService.put('fund:000001@v2', fundDataV2);
await cacheService.put('fund:000001@v3', fundDataV3);

// ❌ 避免的命名方式
await cacheService.put('abc', data); // 太简单
await cacheService.put('fund_data_000001', data); // 不够结构化
await cacheService.put('a_very_long_cache_key_that_is_hard_to_read', data); // 太长
```

### 缓存配置策略

根据数据特性选择合适的配置：

```dart
// 基金核心数据 - 高优先级，较长过期时间
final fundCoreConfig = CacheConfig(
  ttl: Duration(hours: 2),
  priority: 9,
  compressible: true,
  tags: {'fund', 'core', 'high-priority'},
);

// 基金实时数据 - 中等优先级，较短过期时间
final fundRealtimeConfig = CacheConfig(
  ttl: Duration(minutes: 5),
  priority: 7,
  compressible: false,
  tags: {'fund', 'realtime', 'medium-priority'},
);

// 用户偏好设置 - 低优先级，长过期时间
final userPreferenceConfig = CacheConfig(
  ttl: Duration(days: 7),
  priority: 5,
  compressible: true,
  tags: {'user', 'preference', 'low-priority'},
);

// 搜索结果 - 低优先级，短过期时间
final searchConfig = CacheConfig(
  ttl: Duration(minutes: 10),
  priority: 3,
  compressible: true,
  tags: {'search', 'temporary', 'low-priority'},
);
```

## 实际应用场景

### 场景1：基金数据缓存

```dart
class FundDataService {
  static const String _namespace = 'fund';

  /// 获取基金基本信息
  Future<FundInfo?> getFundInfo(String code) async {
    final cacheKey = '$_namespace:info:$code';

    // 尝试从缓存获取
    final cachedInfo = await CacheManager.instance.get<FundInfo>(cacheKey);
    if (cachedInfo != null) {
      return cachedInfo;
    }

    // 从API获取
    final apiInfo = await fetchFundInfoFromAPI(code);
    if (apiInfo != null) {
      // 缓存1小时
      await CacheManager.instance.put(
        cacheKey,
        apiInfo,
        config: CacheConfig(
          ttl: Duration(hours: 1),
          priority: 8,
          tags: {'fund', 'info'},
        ),
      );
    }

    return apiInfo;
  }

  /// 批量获取基金信息
  Future<Map<String, FundInfo?>> getMultipleFundInfos(List<String> codes) async {
    final cacheKeys = codes.map((code) => '$_namespace:info:$code').toList();

    // 批量从缓存获取
    final cachedResults = await CacheManager.instance.getAll<FundInfo>(cacheKeys);

    // 检查缺失的数据
    final missingCodes = <String>[];
    final results = <String, FundInfo?>{};

    for (int i = 0; i < codes.length; i++) {
      final code = codes[i];
      final cacheKey = cacheKeys[i];
      final cachedInfo = cachedResults[cacheKey];

      if (cachedInfo != null) {
        results[code] = cachedInfo;
      } else {
        missingCodes.add(code);
      }
    }

    // 批量获取缺失的数据
    if (missingCodes.isNotEmpty) {
      final apiResults = await fetchMultipleFundInfosFromAPI(missingCodes);

      // 存储到缓存
      final entriesToCache = <String, FundInfo>{};
      for (final entry in apiResults.entries) {
        final code = entry.key;
        final info = entry.value;
        final cacheKey = '$_namespace:info:$code';

        results[code] = info;
        entriesToCache[cacheKey] = info;
      }

      if (entriesToCache.isNotEmpty) {
        await CacheManager.instance.putAll(
          entriesToCache,
          config: CacheConfig(
            ttl: Duration(hours: 1),
            priority: 8,
            tags: {'fund', 'info'},
          ),
        );
      }
    }

    return results;
  }
}
```

### 场景2：用户偏好设置缓存

```dart
class UserPreferenceService {
  static const String _namespace = 'user:preference';

  /// 获取用户偏好设置
  Future<UserPreference?> getUserPreference(String userId) async {
    final cacheKey = '$_namespace:$userId';

    // 尝试从缓存获取
    final cachedPreference = await CacheManager.instance.get<UserPreference>(cacheKey);
    if (cachedPreference != null) {
      return cachedPreference;
    }

    // 从数据库获取
    final dbPreference = await fetchUserPreferenceFromDB(userId);
    if (dbPreference != null) {
      // 缓存7天
      await CacheManager.instance.put(
        cacheKey,
        dbPreference,
        config: CacheConfig(
          ttl: Duration(days: 7),
          priority: 5,
          tags: {'user', 'preference'},
        ),
      );
    }

    return dbPreference;
  }

  /// 更新用户偏好设置
  Future<void> updateUserPreference(String userId, UserPreference preference) async {
    final cacheKey = '$_namespace:$userId';

    // 更新数据库
    await updateUserPreferenceInDB(userId, preference);

    // 更新缓存
    await CacheManager.instance.put(
      cacheKey,
      preference,
      config: CacheConfig(
        ttl: Duration(days: 7),
        priority: 5,
        tags: {'user', 'preference'},
      ),
    );
  }

  /// 清除用户偏好缓存
  Future<void> clearUserPreferenceCache(String userId) async {
    final cacheKey = '$_namespace:$userId';
    await CacheManager.instance.remove(cacheKey);
  }
}
```

### 场景3：搜索结果缓存

```dart
class SearchService {
  static const String _namespace = 'search';

  /// 执行搜索
  Future<List<SearchResult>> search(String query, {int limit = 20}) async {
    final cacheKey = '$_namespace:results:${Uri.encodeComponent(query)}:$limit';

    // 尝试从缓存获取
    final cachedResults = await CacheManager.instance.get<List<SearchResult>>(cacheKey);
    if (cachedResults != null) {
      print('搜索结果来自缓存: $query');
      return cachedResults;
    }

    // 执行搜索
    print('执行搜索: $query');
    final searchResults = await performSearch(query, limit: limit);

    // 缓存10分钟
    await CacheManager.instance.put(
      cacheKey,
      searchResults,
      config: CacheConfig(
        ttl: Duration(minutes: 10),
        priority: 3,
        tags: {'search', 'results'},
      ),
    );

    return searchResults;
  }

  /// 清除搜索结果缓存
  Future<void> clearSearchCache() async {
    // 删除所有搜索相关的缓存
    await CacheManager.instance.removeByPattern('$_namespace:results:*');
  }

  /// 预加载热门搜索
  Future<void> preloadHotSearches() async {
    final hotQueries = ['基金', '股票', '科技', '医疗', '消费'];

    for (final query in hotQueries) {
      final cacheKey = '$_namespace:results:${Uri.encodeComponent(query)}:10';

      // 检查是否已缓存
      if (!await CacheManager.instance.exists(cacheKey)) {
        // 异步预加载
        CacheManager.instance.preload(
          [cacheKey],
          (key) async {
            final results = await performSearch(query, limit: 10);
            return results;
          },
        );
      }
    }
  }
}
```

## 最佳实践

### 1. 缓存策略选择

```dart
class CacheStrategySelector {
  static CacheStrategyType selectStrategy(String dataType) {
    switch (dataType) {
      case 'fund_data':
        return CacheStrategyType.lru; // 基金数据适合LRU
      case 'user_preference':
        return CacheStrategyType.ttl; // 用户偏好设置适合TTL
      case 'search_results':
        return CacheStrategyType.adaptive; // 搜索结果适合自适应
      case 'system_config':
        return CacheStrategyType.priority; // 系统配置适合优先级
      default:
        return CacheStrategyType.lru; // 默认使用LRU
    }
  }
}
```

### 2. 缓存预热策略

```dart
class CacheWarmupService {
  /// 应用启动时预热关键数据
  static Future<void> warmupCriticalData() async {
    print('开始缓存预热...');

    // 预加载热门基金数据
    await _preloadPopularFunds();

    // 预加载系统配置
    await _preloadSystemConfig();

    // 预加载用户偏好（如果有登录用户）
    await _preloadUserPreferences();

    print('缓存预热完成');
  }

  static Future<void> _preloadPopularFunds() async {
    final popularFundCodes = ['000001', '000002', '000003', '110022', '161725'];

    final entries = <String, FundInfo>{};
    for (final code in popularFundCodes) {
      final cacheKey = 'fund:info:$code';

      if (!await CacheManager.instance.exists(cacheKey)) {
        final fundInfo = await fetchFundInfoFromAPI(code);
        if (fundInfo != null) {
          entries[cacheKey] = fundInfo;
        }
      }
    }

    if (entries.isNotEmpty) {
      await CacheManager.instance.putAll(
        entries,
        config: CacheConfig(
          ttl: Duration(hours: 2),
          priority: 9,
          tags: {'fund', 'popular', 'preloaded'},
        ),
      );
    }
  }
}
```

### 3. 缓存失效管理

```dart
class CacheInvalidationService {
  /// 基于事件的缓存失效
  static Future<void> invalidateFundData(String fundCode) async {
    // 删除基金相关缓存
    await CacheManager.instance.remove('fund:info:$fundCode');
    await CacheManager.instance.remove('fund:ranking:$fundCode');
    await CacheManager.instance.remove('fund:performance:$fundCode');

    // 删除搜索结果中可能包含该基金的缓存
    await CacheManager.instance.removeByPattern('search:results:*');

    print('已清除基金 $fundCode 的相关缓存');
  }

  /// 定时清理过期缓存
  static Future<void> scheduleCleanup() async {
    Timer.periodic(Duration(hours: 1), (timer) async {
      await _performCleanup();
    });
  }

  static Future<void> _performCleanup() async {
    // 获取缓存统计
    final stats = await CacheManager.instance.getStatistics();

    // 如果过期项目过多，执行优化
    if (stats.expiredCount > stats.totalCount * 0.1) {
      await CacheManager.instance.optimize();
      print('执行了缓存优化清理');
    }
  }
}
```

### 4. 内存监控和优化

```dart
class CacheMonitorService {
  /// 监控缓存使用情况
  static Future<void> monitorCacheUsage() async {
    final stats = await CacheManager.instance.getStatistics();

    // 检查内存使用
    final memoryUsageMB = stats.totalSize / (1024 * 1024);
    if (memoryUsageMB > 50) { // 超过50MB
      print('警告：缓存内存使用过高 ${memoryUsageMB.toStringAsFixed(1)}MB');

      // 清理低优先级缓存
      await _cleanupLowPriorityCache();
    }

    // 检查命中率
    if (stats.hitRate < 0.8) { // 命中率低于80%
      print('警告：缓存命中率过低 ${(stats.hitRate * 100).toStringAsFixed(1)}%');

      // 分析访问模式，调整策略
      await _analyzeAccessPattern();
    }
  }

  static Future<void> _cleanupLowPriorityCache() async {
    // 这里需要实现根据优先级清理缓存的逻辑
    // 当前版本可能需要遍历所有缓存项并检查优先级
    await CacheManager.instance.optimize();
  }

  static Future<void> _analyzeAccessPattern() async {
    final accessStats = CacheManager.instance.getAccessStats();
    print('访问统计：${accessStats.totalAccesses}次总访问，命中率${(accessStats.hitRate * 100).toStringAsFixed(1)}%');

    // 根据访问模式建议调整缓存策略
    if (accessStats.misses > accessStats.hits) {
      print('建议：考虑增加缓存时间或预热更多数据');
    }
  }
}
```

## 性能调优

### 1. 批量操作优化

```dart
// ✅ 推荐：使用批量操作
Future<void> updateMultipleFunds(List<FundData> funds) async {
  final entries = <String, FundData>{};

  for (final fund in funds) {
    entries['fund:data:${fund.code}'] = fund;
  }

  // 一次性批量存储
  await CacheManager.instance.putAll(
    entries,
    config: CacheConfig(
      ttl: Duration(minutes: 30),
      priority: 7,
      tags: {'fund', 'batch'},
    ),
  );
}

// ❌ 避免：循环单个操作
Future<void> updateMultipleFundsBad(List<FundData> funds) async {
  for (final fund in funds) {
    await CacheManager.instance.put(
      'fund:data:${fund.code}',
      fund,
      config: CacheConfig(
        ttl: Duration(minutes: 30),
        priority: 7,
        tags: {'fund', 'batch'},
      ),
    );
  }
}
```

### 2. 异步操作优化

```dart
// ✅ 推荐：并行处理
Future<List<FundData>> getMultipleFundsData(List<String> codes) async {
  // 并行获取所有数据
  final futures = codes.map((code) => getFundData(code)).toList();
  final results = await Future.wait(futures);

  return results.where((data) => data != null).cast<FundData>().toList();
}

// ❌ 避免：串行处理
Future<List<FundData>> getMultipleFundsDataBad(List<String> codes) async {
  final results = <FundData>[];

  for (final code in codes) {
    final data = await getFundData(code);
    if (data != null) {
      results.add(data);
    }
  }

  return results;
}
```

### 3. 缓存大小优化

```dart
class CacheSizeOptimizer {
  /// 压缩大数据对象
  static Map<String, dynamic> compressData(Map<String, dynamic> data) {
    // 移除不必要的字段
    final compressed = <String, dynamic>{};

    for (final entry in data.entries) {
      if (_shouldKeepField(entry.key, entry.value)) {
        compressed[entry.key] = entry.value;
      }
    }

    return compressed;
  }

  static bool _shouldKeepField(String key, dynamic value) {
    // 跳过空值和null值
    if (value == null) return false;

    // 跳过过长的描述性字段
    if (key.contains('description') && value.toString().length > 500) {
      return false;
    }

    return true;
  }

  /// 分割大数据
  static List<Map<String, dynamic>> splitLargeData(
    Map<String, dynamic> data,
    int maxItemsPerChunk,
  ) {
    final entries = data.entries.toList();
    final chunks = <Map<String, dynamic>>[];

    for (int i = 0; i < entries.length; i += maxItemsPerChunk) {
      final end = (i + maxItemsPerChunk).clamp(0, entries.length);
      final chunk = Map<String, dynamic>.fromEntries(
        entries.sublist(i, end),
      );
      chunks.add(chunk);
    }

    return chunks;
  }
}
```

## 故障排查

### 常见问题和解决方案

#### 1. 缓存命中率低

**症状**：大部分请求都未能命中缓存

**诊断**：
```dart
final stats = await CacheManager.instance.getStatistics();
print('命中率: ${(stats.hitRate * 100).toStringAsFixed(1)}%');
print('总访问: ${CacheManager.instance.getAccessStats().totalAccesses}');
```

**解决方案**：
- 检查TTL设置是否过短
- 增加缓存预热
- 分析访问模式，调整缓存策略

#### 2. 内存使用过高

**症状**：应用内存占用持续增长

**诊断**：
```dart
final stats = await CacheManager.instance.getStatistics();
final memoryMB = stats.totalSize / (1024 * 1024);
print('缓存内存使用: ${memoryMB.toStringAsFixed(1)}MB');
```

**解决方案**：
- 减少缓存项的TTL
- 启用数据压缩
- 定期执行缓存清理

#### 3. 序列化错误

**症状**：存储或检索数据时出现异常

**诊断和解决**：
```dart
try {
  await CacheManager.instance.put('key', complexObject);
  final retrieved = await CacheManager.getInstance('key');
} on CacheSerializationException catch (e) {
  print('序列化错误: ${e.message}');

  // 尝试简化对象或使用自定义序列化
  final simplifiedData = _simplifyObject(complexObject);
  await CacheManager.instance.put('key', simplifiedData);
}
```

### 调试工具

```dart
class CacheDebugger {
  /// 打印缓存状态
  static Future<void> printCacheStatus() async {
    final stats = await CacheManager.instance.getStatistics();
    final accessStats = CacheManager.instance.getAccessStats();

    print('=== 缓存状态报告 ===');
    print('总项目数: ${stats.totalCount}');
    print('有效项目: ${stats.validCount}');
    print('过期项目: ${stats.expiredCount}');
    print('总大小: ${(stats.totalSize / 1024 / 1024).toStringAsFixed(2)}MB');
    print('命中率: ${(stats.hitRate * 100).toStringAsFixed(1)}%');
    print('总访问次数: ${accessStats.totalAccesses}');
    print('命中次数: ${accessStats.hits}');
    print('未命中次数: ${accessStats.misses}');
    print('===================');
  }

  /// 分析特定命名空间的缓存使用
  static Future<void> analyzeNamespace(String namespace) async {
    // 这里需要实现按命名空间分析缓存的逻辑
    // 当前版本可能需要通过键的模式匹配来实现
    print('分析命名空间: $namespace');
    // TODO: 实现具体的分析逻辑
  }
}
```

## 迁移指南

### 从旧缓存系统迁移

如果你之前使用了其他缓存系统，可以按照以下步骤迁移：

#### 1. 数据迁移

```dart
class CacheMigrationService {
  /// 从旧缓存系统迁移数据
  static Future<void> migrateFromOldCache() async {
    print('开始缓存迁移...');

    // 1. 获取旧缓存数据
    final oldCacheData = await _getOldCacheData();

    // 2. 转换数据格式
    final newCacheData = _convertDataFormat(oldCacheData);

    // 3. 批量存储到新缓存
    await CacheManager.instance.putAll(newCacheData);

    // 4. 验证迁移结果
    await _verifyMigration(oldCacheData.keys.toList());

    print('缓存迁移完成');
  }

  static Future<Map<String, dynamic>> _getOldCacheData() async {
    // 实现从旧缓存系统获取数据的逻辑
    return {};
  }

  static Map<String, dynamic> _convertDataFormat(Map<String, dynamic> oldData) {
    // 实现数据格式转换的逻辑
    return oldData;
  }

  static Future<void> _verifyMigration(List<String> keys) async {
    int successCount = 0;

    for (final key in keys) {
      if (await CacheManager.instance.exists(key)) {
        successCount++;
      }
    }

    print('迁移验证: $successCount/${keys.length} 项成功');
  }
}
```

#### 2. 代码迁移

```dart
// 旧代码
// await oldCache.set('fund:000001', fundData);
// final data = await oldCache.get('fund:000001');

// 新代码
await CacheManager.instance.put('fund:000001', fundData,
  config: CacheConfig(ttl: Duration(minutes: 30)));
final data = await CacheManager.instance.get<FundData>('fund:000001');
```

### 版本升级

当缓存系统版本升级时：

```dart
class CacheVersionManager {
  static const String _versionKey = 'cache_system_version';
  static const String _currentVersion = '1.0.0';

  /// 检查并处理版本升级
  static Future<void> checkAndHandleVersionUpgrade() async {
    final storedVersion = await CacheManager.instance.get<String>(_versionKey);

    if (storedVersion == null) {
      // 首次安装
      await _initializeFirstTime();
    } else if (storedVersion != _currentVersion) {
      // 版本升级
      await _handleVersionUpgrade(storedVersion, _currentVersion);
    }
  }

  static Future<void> _initializeFirstTime() async {
    await CacheManager.instance.put(_versionKey, _currentVersion);
    print('缓存系统首次初始化完成');
  }

  static Future<void> _handleVersionUpgrade(String oldVersion, String newVersion) async {
    print('缓存系统从 $oldVersion 升级到 $newVersion');

    // 执行升级逻辑
    await _performVersionUpgrade(oldVersion, newVersion);

    // 更新版本号
    await CacheManager.instance.put(_versionKey, newVersion);
    print('缓存系统升级完成');
  }

  static Future<void> _performVersionUpgrade(String oldVersion, String newVersion) async {
    // 根据版本差异执行相应的升级逻辑
    // 例如：数据格式转换、配置更新等
  }
}
```

---

## 总结

统一缓存系统为基速基金分析平台提供了强大、灵活、高性能的缓存解决方案。通过合理的使用和配置，可以显著提升应用的响应速度和用户体验。

记住以下关键点：

1. **合理选择缓存策略** - 根据数据特性选择最适合的缓存策略
2. **设置适当的TTL** - 平衡数据新鲜度和缓存效率
3. **使用批量操作** - 提高操作效率
4. **监控缓存性能** - 定期检查命中率和内存使用
5. **处理异常情况** - 实现优雅的错误处理和降级策略

如有更多问题，请参考API文档或联系技术支持团队。