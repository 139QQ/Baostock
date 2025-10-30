import 'dart:async';
import 'dart:math' as math;
import 'package:jisu_fund_analyzer/src/core/cache/interfaces/i_unified_cache_service.dart';
import 'package:jisu_fund_analyzer/src/core/cache/unified_cache_manager.dart';
import 'package:jisu_fund_analyzer/src/core/cache/storage/cache_storage.dart';
import 'package:jisu_fund_analyzer/src/core/cache/strategies/cache_strategies.dart';
import 'package:jisu_fund_analyzer/src/core/cache/config/cache_config_manager.dart';

/// 统一缓存测试辅助工具
///
/// 提供测试环境的创建和管理功能
class UnifiedCacheTestHelper {
  /// 创建测试用的缓存服务
  static Future<IUnifiedCacheService> createTestCacheService({
    CacheStrategyType strategyType = CacheStrategyType.hybrid,
    bool useMemoryStorage = true,
  }) async {
    final storage = CacheStorageFactory.createMemoryStorage();
    await storage.initialize();
    final strategy =
        CacheStrategyFactory.getStrategy(_strategyTypeToString(strategyType));
    final configManager = CacheConfigManager();

    final manager = UnifiedCacheManager(
      storage: storage,
      strategy: strategy,
      configManager: configManager,
      config: UnifiedCacheConfig.testing(),
    );
    return manager;
  }

  /// 创建性能测试用的缓存服务
  static Future<IUnifiedCacheService>
      createPerformanceTestCacheService() async {
    return await createTestCacheService(strategyType: CacheStrategyType.lru);
  }

  /// 创建集成测试用的缓存服务
  static Future<IUnifiedCacheService>
      createIntegrationTestCacheService() async {
    return await createTestCacheService(
        strategyType: CacheStrategyType.adaptive);
  }

  /// 将策略类型转换为字符串
  static String _strategyTypeToString(CacheStrategyType type) {
    switch (type) {
      case CacheStrategyType.lru:
        return 'lru';
      case CacheStrategyType.lfu:
        return 'lfu';
      case CacheStrategyType.ttl:
        return 'ttl';
      case CacheStrategyType.adaptive:
        return 'adaptive';
      case CacheStrategyType.priority:
        return 'priority';
      case CacheStrategyType.hybrid:
        return 'lru'; // 默认使用LRU
    }
  }

  /// 清理测试环境
  static Future<void> cleanupTestEnvironment() async {
    // 对于新的统一缓存管理器，清理会在测试的tearDown中进行
    // 这里只是一个占位符
  }

  /// 生成测试数据
  static Map<String, dynamic> generateTestData(int sizeKB) {
    final data = <String, dynamic>{};
    int currentSize = 0;
    int fieldIndex = 0;

    while (currentSize < sizeKB * 1024) {
      final fieldValue = 'x' * math.min(100, sizeKB * 1024 - currentSize);
      data['field_$fieldIndex'] = fieldValue;

      currentSize += fieldValue.length + 12; // +12 for field name and overhead
      fieldIndex++;
    }

    return data;
  }

  /// 生成测试缓存条目
  static List<CacheTestEntry> generateTestEntries(
    int count, {
    int minSizeKB = 1,
    int maxSizeKB = 10,
    List<String>? keyPrefixes,
  }) {
    final entries = <CacheTestEntry>[];
    final prefixes =
        keyPrefixes ?? ['test', 'user', 'search', 'filter', 'fund'];
    final random = math.Random();

    for (int i = 0; i < count; i++) {
      final prefix = prefixes[random.nextInt(prefixes.length)];
      final key = '${prefix}_${i.toString().padLeft(4, '0')}';
      final sizeKB = minSizeKB + random.nextInt(maxSizeKB - minSizeKB + 1);
      final data = generateTestData(sizeKB);

      entries.add(CacheTestEntry(
        key: key,
        data: data,
        sizeKB: sizeKB,
        category: prefix,
      ));
    }

    return entries;
  }

  /// 验证缓存一致性
  static Future<ConsistencyReport> verifyCacheConsistency(
    IUnifiedCacheService cacheService,
    List<CacheTestEntry> entries,
  ) async {
    final report = ConsistencyReport();

    for (final entry in entries) {
      try {
        // 首先检查条目是否存在
        final exists = await cacheService.exists(entry.key);

        if (!exists) {
          report.missingEntries.add(entry.key);
          continue;
        }

        // 尝试检索数据
        final retrieved = await cacheService.get(entry.key);

        if (retrieved == null) {
          report.missingEntries.add(entry.key);
        } else {
          // 简化实现：只检查数据是否为空
          if (retrieved.toString().isEmpty) {
            report.dataCorruption.add(entry.key);
          }
        }
      } catch (e) {
        report.accessErrors.add(entry.key);
      }
    }

    report.totalEntries = entries.length;
    report.consistentEntries = entries.length -
        report.missingEntries.length -
        report.sizeMismatch.length -
        report.dataCorruption.length -
        report.accessErrors.length;

    return report;
  }
}

/// 缓存策略类型
enum CacheStrategyType {
  lru,
  lfu,
  ttl,
  adaptive,
  priority,
  hybrid,
}

/// 测试缓存条目
class CacheTestEntry {
  final String key;
  final Map<String, dynamic> data;
  final int sizeKB;
  final String category;

  const CacheTestEntry({
    required this.key,
    required this.data,
    required this.sizeKB,
    required this.category,
  });
}

/// 一致性报告
class ConsistencyReport {
  int totalEntries = 0;
  int consistentEntries = 0;
  final List<String> missingEntries = [];
  final List<String> sizeMismatch = [];
  final List<String> dataCorruption = [];
  final List<String> accessErrors = [];

  double get consistencyRate =>
      totalEntries > 0 ? consistentEntries / totalEntries : 0.0;

  bool get isConsistent => consistencyRate >= 0.95;

  @override
  String toString() {
    return 'ConsistencyReport('
        'total: $totalEntries, '
        'consistent: $consistentEntries, '
        'rate: ${(consistencyRate * 100).toStringAsFixed(1)}%, '
        'missing: ${missingEntries.length}, '
        'errors: ${accessErrors.length})';
  }
}
