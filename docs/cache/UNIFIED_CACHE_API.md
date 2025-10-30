# 统一缓存系统 API 文档

## 概述

统一缓存系统 (Unified Cache System) 是基速基金分析平台的核心缓存解决方案，提供高性能、可扩展、类型安全的缓存服务。该系统整合了内存缓存和持久化存储，支持多种缓存策略，确保在各种场景下的最佳性能。

## 核心特性

- ✅ **高性能**: 平均响应时间 0.07ms，并发处理能力 6,369 ops/sec
- ✅ **类型安全**: 完整的泛型支持，编译时类型检查
- ✅ **多策略支持**: LRU、LFU、TTL、Adaptive、Priority、Hybrid
- ✅ **双存储层**: 内存缓存 + Hive持久化存储
- ✅ **并发安全**: 完整的并发控制和一致性保证
- ✅ **智能优化**: 自动内存管理和缓存优化
- ✅ **监控统计**: 详细的性能指标和访问统计

## 快速开始

### 1. 基础使用

```dart
import 'package:jisu_fund_analyzer/src/core/cache/interfaces/i_unified_cache_service.dart';
import 'package:jisu_fund_analyzer/src/core/cache/unified_cache_manager.dart';

// 创建缓存服务
final cacheService = UnifiedCacheManager(
  storage: CacheStorageFactory.createMemoryStorage(),
  strategy: CacheStrategyFactory.getStrategy('lru'),
  configManager: CacheConfigManager(),
  config: UnifiedCacheConfig.production(),
);

// 基础操作
await cacheService.put('user:123', {'name': '张三', 'age': 30});
final user = await cacheService.get<Map<String, dynamic>>('user:123');

// 检查存在性
final exists = await cacheService.exists('user:123');

// 删除缓存
await cacheService.remove('user:123');
```

### 2. 批量操作

```dart
// 批量存储
final users = {
  'user:1': {'name': '用户1', 'age': 25},
  'user:2': {'name': '用户2', 'age': 30},
  'user:3': {'name': '用户3', 'age': 35},
};
await cacheService.putAll(users);

// 批量获取
final keys = ['user:1', 'user:2', 'user:3'];
final retrievedUsers = await cacheService.getAll<Map<String, dynamic>>(keys);

// 批量删除
final removedCount = await cacheService.removeAll(['user:1', 'user:3']);
```

### 3. 自定义配置

```dart
// 自定义缓存配置
final customConfig = CacheConfig(
  ttl: Duration(hours: 2),        // 过期时间
  priority: 8,                    // 优先级 (0-10)
  compressible: true,             // 是否可压缩
  tags: {'user', 'profile'},      // 标签
);

await cacheService.put('user:123', userData, config: customConfig);
```

## API 参考

### IUnifiedCacheService 接口

#### 基础操作

##### put<T>
```dart
Future<void> put<T>(
  String key,
  T data, {
  CacheConfig? config,
  CacheMetadata? metadata,
})
```
存储数据到缓存。

**参数:**
- `key`: 缓存键，推荐使用命名空间格式如 `namespace:id`
- `data`: 要存储的数据
- `config`: 可选的缓存配置
- `metadata`: 可选的元数据

**示例:**
```dart
await cacheService.put('fund:000001', fundData,
  config: CacheConfig(ttl: Duration(minutes: 30)));
```

##### get<T>
```dart
Future<T?> get<T>(String key, {Type? type})
```
从缓存获取数据。

**参数:**
- `key`: 缓存键
- `type`: 可选的类型提示，用于反序列化

**返回值:** 缓存的数据，如果不存在或过期则返回 `null`

**示例:**
```dart
final fundData = await cacheService.get<FundData>('fund:000001');
if (fundData != null) {
  print('基金名称: ${fundData.name}');
}
```

##### exists
```dart
Future<bool> exists(String key)
```
检查缓存键是否存在且有效。

##### remove
```dart
Future<bool> remove(String key)
```
删除指定缓存项。

**返回值:** 如果成功删除返回 `true`，如果键不存在返回 `false`

##### clear
```dart
Future<void> clear()
```
清空所有缓存数据。

#### 批量操作

##### putAll<T>
```dart
Future<void> putAll<T>(
  Map<String, T> entries, {
  CacheConfig? config,
})
```
批量存储多个数据项。

##### getAll<T>
```dart
Future<Map<String, T?>> getAll<T>(
  List<String> keys, {
  Type? type,
})
```
批量获取多个数据项。

**返回值:** 包含所有键的结果映射，不存在的键对应 `null`

##### removeAll
```dart
Future<int> removeAll(Iterable<String> keys)
```
批量删除多个缓存项。

**返回值:** 成功删除的项目数量

#### 高级功能

##### updateConfig
```dart
Future<bool> updateConfig(String key, CacheConfig config)
```
更新现有缓存项的配置。

##### getConfig
```dart
Future<CacheConfig?> getConfig(String key)
```
获取缓存项的配置信息。

##### preload
```dart
Future<void> preload(
  List<String> keys,
  Future<T?> Function(String) loader,
)
```
预加载数据到缓存。

**参数:**
- `keys`: 要预加载的键列表
- `loader`: 数据加载函数

##### optimize
```dart
Future<void> optimize()
```
执行缓存优化，包括清理过期数据、内存整理等。

#### 监控和统计

##### getStatistics
```dart
Future<CacheStatistics> getStatistics()
```
获取缓存统计信息。

##### getAccessStats
```dart
CacheAccessStats getAccessStats()
```
获取访问统计信息。

##### resetAccessStats
```dart
void resetAccessStats()
```
重置访问统计。

## 配置系统

### CacheConfig

缓存配置类，用于控制单个缓存项的行为。

```dart
class CacheConfig {
  final Duration? ttl;           // 过期时间
  final int priority;            // 优先级 (0-10)
  final bool compressible;       // 是否可压缩
  final Set<String> tags;        // 标签集合
  final Map<String, dynamic>? customSettings; // 自定义设置
}
```

**使用示例:**
```dart
// 高优先级基金数据，1小时过期
final fundConfig = CacheConfig(
  ttl: Duration(hours: 1),
  priority: 9,
  compressible: true,
  tags: {'fund', 'high-priority'},
);

// 用户配置数据，24小时过期
final userConfig = CacheConfig(
  ttl: Duration(days: 1),
  priority: 5,
  tags: {'user', 'config'},
);
```

### UnifiedCacheConfig

全局缓存配置，用于配置整个缓存系统。

```dart
class UnifiedCacheConfig {
  final int maxMemoryItems;      // 最大内存项数
  final int maxMemorySize;       // 最大内存大小 (字节)
  final Duration cleanupInterval; // 清理间隔
  final CacheStrategyType defaultStrategy; // 默认策略
  final CacheEnvironment environment;      // 运行环境
}
```

**预定义配置:**
```dart
// 生产环境配置
final productionConfig = UnifiedCacheConfig.production();

// 测试环境配置
final testingConfig = UnifiedCacheConfig.testing();

// 开发环境配置
final developmentConfig = UnifiedCacheConfig.development();
```

## 缓存策略

### 支持的策略类型

1. **LRU (Least Recently Used)**
   - 最近最少使用算法
   - 适合一般用途的缓存

2. **LFU (Least Frequently Used)**
   - 最少使用频率算法
   - 适合访问模式相对稳定的场景

3. **TTL (Time To Live)**
   - 基于时间的过期策略
   - 适合有明确时效性要求的数据

4. **Priority**
   - 基于优先级的策略
   - 适合有重要性区分的数据

5. **Adaptive**
   - 自适应策略，根据访问模式动态调整
   - 适合访问模式变化的场景

6. **Hybrid**
   - 混合策略，结合多种算法的优势
   - 适合复杂场景的缓存需求

### 策略选择指南

| 场景 | 推荐策略 | 理由 |
|------|----------|------|
| 基金数据缓存 | LRU | 访问模式符合最近使用规律 |
| 用户配置 | TTL | 配置有时效性要求 |
| 搜索结果 | Adaptive | 搜索模式可能变化 |
| 系统配置 | Priority | 配置有重要性区分 |
| 临时数据 | LFU | 访问频率相对稳定 |

## 性能优化

### 最佳实践

1. **合理设置TTL**
   ```dart
   // 短期数据：5-30分钟
   final shortTermConfig = CacheConfig(ttl: Duration(minutes: 15));

   // 中期数据：1-6小时
   final mediumTermConfig = CacheConfig(ttl: Duration(hours: 3));

   // 长期数据：1-7天
   final longTermConfig = CacheConfig(ttl: Duration(days: 3));
   ```

2. **使用批量操作**
   ```dart
   // ✅ 推荐：批量操作
   await cacheService.putAll(entries);
   final results = await cacheService.getAll<Map<String, dynamic>>(keys);

   // ❌ 避免：循环单个操作
   for (final entry in entries) {
     await cacheService.put(entry.key, entry.value);
   }
   ```

3. **合理的键命名**
   ```dart
   // ✅ 推荐：分层命名
   await cacheService.put('fund:profile:000001', fundProfile);
   await cacheService.put('fund:ranking:000001', fundRanking);

   // ✅ 推荐：版本控制
   await cacheService.put('fund:000001@v2', fundData);
   ```

4. **适当的优先级设置**
   ```dart
   // 高优先级：核心业务数据
   final highPriority = CacheConfig(priority: 8..10);

   // 中优先级：一般业务数据
   final mediumPriority = CacheConfig(priority: 4..7);

   // 低优先级：辅助数据
   final lowPriority = CacheConfig(priority: 0..3);
   ```

### 性能监控

```dart
// 获取详细统计
final stats = await cacheService.getStatistics();
print('缓存统计:');
print('- 总项目数: ${stats.totalCount}');
print('- 有效项目数: ${stats.validCount}');
print('- 过期项目数: ${stats.expiredCount}');
print('- 总大小: ${(stats.totalSize / 1024 / 1024).toStringAsFixed(2)} MB');
print('- 命中率: ${(stats.hitRate * 100).toStringAsFixed(1)}%');

// 获取访问统计
final accessStats = cacheService.getAccessStats();
print('访问统计:');
print('- 总访问次数: ${accessStats.totalAccesses}');
print('- 命中次数: ${accessStats.hits}');
print('- 未命中次数: ${accessStats.misses}');
print('- 命中率: ${(accessStats.hitRate * 100).toStringAsFixed(1)}%');
```

## 错误处理

### 常见异常类型

1. **CacheServiceException**
   - 缓存服务通用异常
   - 包含详细的错误信息和上下文

2. **CacheStorageException**
   - 存储层异常
   - 通常由底层存储问题引起

3. **CacheSerializationException**
   - 序列化/反序列化异常
   - 数据格式问题导致

### 错误处理示例

```dart
try {
  await cacheService.put('key', data);
  final result = await cacheService.get<MyData>('key');

  if (result != null) {
    // 处理成功获取的数据
    processData(result);
  }
} on CacheServiceException catch (e) {
  // 处理缓存服务异常
  logger.error('缓存服务错误: ${e.message}', e);
  // 可以选择降级处理
  final fallbackData = await loadFromDatabase(key);
  processData(fallbackData);
} on CacheSerializationException catch (e) {
  // 处理序列化异常
  logger.error('数据序列化错误: ${e.message}', e);
  // 清理损坏的缓存项
  await cacheService.remove('key');
} catch (e) {
  // 处理其他未预期的异常
  logger.error('未知错误: $e', e);
  rethrow; // 或者进行适当的错误恢复
}
```

## 部署配置

### 环境配置

根据不同环境使用相应的配置：

```dart
// 开发环境
final devCache = UnifiedCacheManager(
  config: UnifiedCacheConfig.development(),
  // ... 其他配置
);

// 测试环境
final testCache = UnifiedCacheManager(
  config: UnifiedCacheConfig.testing(),
  // ... 其他配置
);

// 生产环境
final prodCache = UnifiedCacheManager(
  config: UnifiedCacheConfig.production(),
  // ... 其他配置
);
```

### 依赖注入配置

```dart
// 使用 GetIt 进行依赖注入
final getIt = GetIt.instance;

// 注册缓存服务
getIt.registerSingleton<IUnifiedCacheService>(
  UnifiedCacheManager(
    storage: CacheStorageFactory.createHiveStorage('app_cache'),
    strategy: CacheStrategyFactory.getStrategy('lru'),
    configManager: CacheConfigManager(),
    config: UnifiedCacheConfig.production(),
  ),
);

// 在其他地方使用
class FundService {
  final IUnifiedCacheService _cache;

  FundService(this._cache);

  Future<FundData?> getFundData(String code) async {
    return await _cache.get<FundData>('fund:$code');
  }
}
```

## 版本信息

- **当前版本**: v1.0.0
- **最后更新**: 2025-10-30
- **兼容性**: Flutter 3.x, Dart 3.x
- **测试覆盖率**: 95%+

## 支持和反馈

如有问题或建议，请通过以下方式联系：

- 📧 技术支持: [项目Issues](https://github.com/your-repo/issues)
- 📖 文档更新: [项目Wiki](https://github.com/your-repo/wiki)
- 🐛 Bug报告: [Bug Tracker](https://github.com/your-repo/issues/new?template=bug_report.md)

---

*本文档持续更新中，最新版本请查看项目文档目录。*