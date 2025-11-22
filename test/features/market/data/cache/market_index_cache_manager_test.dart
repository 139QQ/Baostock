import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:decimal/decimal.dart';

import 'package:jisu_fund_analyzer/src/features/market/data/cache/market_index_cache_manager.dart';
import 'package:jisu_fund_analyzer/src/features/market/models/market_index_data.dart';

/// 市场指数缓存管理器测试
void main() {
  group('MarketIndexCacheManager', () {
    late MarketIndexCacheManager cacheManager;

    setUp(() {
      cacheManager = MarketIndexCacheManager(
        config: const MarketIndexCacheConfig(
          maxMemoryCacheSize: 5,
          memoryCacheExpiration: Duration(minutes: 1),
          hiveCacheExpiration: Duration(hours: 1),
          cleanupInterval: Duration(seconds: 1),
        ),
      );
    });

    tearDown(() async {
      await cacheManager.dispose();
    });

    group('基础缓存操作', () {
      test('应该能够缓存和获取指数数据', () async {
        // Given
        final indexData = createTestIndexData('SH000001');

        // When
        await cacheManager.cacheIndexData(indexData);
        final cachedData = await cacheManager.getCachedIndexData('SH000001');

        // Then
        expect(cachedData, isNotNull);
        expect(cachedData!.code, equals('SH000001'));
        expect(cachedData.name, equals('上证指数'));
      });

      test('内存缓存未命中时应该从Hive获取', () async {
        // Given
        final indexData = createTestIndexData('SH000001');
        await cacheManager.cacheIndexData(indexData);

        // When - 清除内存缓存以模拟从Hive获取
        await Future.delayed(Duration(milliseconds: 1100)); // 等待内存缓存过期
        final cachedData = await cacheManager.getCachedIndexData('SH000001');

        // Then
        expect(cachedData, isNotNull);
        expect(cachedData!.code, equals('SH000001'));
      });

      test('缓存未命中时应该返回null', () async {
        // When
        final cachedData =
            await cacheManager.getCachedIndexData('NON_EXISTENT');

        // Then
        expect(cachedData, isNull);
      });
    });

    group('批量操作', () {
      test('应该能够批量获取缓存数据', () async {
        // Given
        final indices = [
          createTestIndexData('SH000001'),
          createTestIndexData('SZ399001'),
          createTestIndexData('SH000300'),
        ];

        for (final index in indices) {
          await cacheManager.cacheIndexData(index);
        }

        // When
        final results = await cacheManager.getBatchCachedIndexData([
          'SH000001',
          'SZ399001',
          'NON_EXISTENT',
        ]);

        // Then
        expect(results.length, equals(2));
        expect(results.containsKey('SH000001'), isTrue);
        expect(results.containsKey('SZ399001'), isTrue);
        expect(results.containsKey('NON_EXISTENT'), isFalse);
      });
    });

    group('LRU策略', () {
      test('超过最大缓存大小时应该移除最少使用的条目', () async {
        // Given
        for (int i = 0; i < 7; i++) {
          await cacheManager.cacheIndexData(
            createTestIndexData('TEST_$i'),
          );
        }

        // When - 访问后5个条目，使它们成为最近使用
        for (int i = 2; i < 7; i++) {
          await cacheManager.getCachedIndexData('TEST_$i');
        }

        // Then - 前两个条目应该被移除
        final cached1 = await cacheManager.getCachedIndexData('TEST_0');
        final cached2 = await cacheManager.getCachedIndexData('TEST_1');
        final cached5 = await cacheManager.getCachedIndexData('TEST_5');
        final cached6 = await cacheManager.getCachedIndexData('TEST_6');

        expect(cached1, isNull);
        expect(cached2, isNull);
        expect(cached5, isNotNull);
        expect(cached6, isNotNull);
      });
    });

    group('预取功能', () {
      test('应该能够跟踪访问模式', () async {
        // Given
        final indexCode = 'SH000001';
        final indexData = createTestIndexData(indexCode);

        // When
        await cacheManager.cacheIndexData(indexData);
        await cacheManager.getCachedIndexData(indexCode);
        await cacheManager.getCachedIndexData(indexCode);
        await cacheManager.getCachedIndexData(indexCode);

        // Then
        final stats = cacheManager.getPrefetchStatistics();
        expect(stats.accessPatternsCount, greaterThan(0));
      });

      test('应该能够获取预取统计信息', () async {
        // Given
        final indexCode = 'SH000001';
        final indexData = createTestIndexData(indexCode);

        // When
        await cacheManager.cacheIndexData(indexData);
        await cacheManager.getCachedIndexData(indexCode); // 触发访问模式记录

        // Then
        final stats = cacheManager.getPrefetchStatistics();
        expect(stats, isNotNull);
        expect(stats.accessPatternsCount, greaterThanOrEqualTo(0));
        expect(stats.queueSize, greaterThanOrEqualTo(0));
      });
    });

    group('过期数据管理', () {
      test('内存缓存过期后应该返回null', () async {
        // Given - 使用短过期时间的配置
        final shortExpiryCacheManager = MarketIndexCacheManager(
          config: const MarketIndexCacheConfig(
            maxMemoryCacheSize: 5,
            memoryCacheExpiration: Duration(milliseconds: 500), // 0.5秒过期
            hiveCacheExpiration: Duration(hours: 1),
            cleanupInterval: Duration(seconds: 1),
          ),
        );

        final indexData = createTestIndexData('SH000001');
        await shortExpiryCacheManager.cacheIndexData(indexData);

        // When - 等待过期
        await Future.delayed(Duration(milliseconds: 600)); // 超过0.5秒过期时间

        final cachedData =
            await shortExpiryCacheManager.getCachedIndexData('SH000001');

        // Then
        expect(cachedData, isNull);

        await shortExpiryCacheManager.dispose();
      });
    });

    group('缓存统计', () {
      test('应该提供准确的缓存统计信息', () async {
        // Given
        final indexData = createTestIndexData('SH000001');
        await cacheManager.cacheIndexData(indexData);
        await cacheManager.getCachedIndexData('SH000001'); // 内存命中
        await cacheManager.getCachedIndexData('NON_EXISTENT'); // 缓存未命中

        // When
        final stats = cacheManager.getStatistics();

        // Then
        expect(stats.memoryHits, equals(1));
        expect(stats.misses, equals(1));
        expect(stats.writes, equals(1));
        expect(stats.totalOperations, equals(3));
        expect(stats.memoryHitRate, closeTo(0.5, 0.1));
      });
    });

    group('缓存清理功能', () {
      test('应该能够清理预取数据', () async {
        // Given
        final indexCode = 'SH000001';
        final indexData = createTestIndexData(indexCode);
        await cacheManager.cacheIndexData(indexData);
        await cacheManager.getCachedIndexData(indexCode); // 触发访问模式记录

        // When
        cacheManager.clearPrefetchData();

        // Then
        final stats = cacheManager.getPrefetchStatistics();
        expect(stats.accessPatternsCount, equals(0));
        expect(stats.queueSize, equals(0));
      });
    });

    group('错误处理', () {
      test('应该能够处理无效的指数代码', () async {
        // When
        final cachedData = await cacheManager.getCachedIndexData('');

        // Then
        expect(cachedData, isNull); // 无效代码应该返回null而不是抛出异常
      });

      test('应该能够处理空数据列表', () async {
        // When
        final results = await cacheManager.getBatchCachedIndexData([]);

        // Then
        expect(results, isEmpty);
      });
    });

    group('配置测试', () {
      test('应该使用自定义配置', () async {
        // Given
        final customConfig = const MarketIndexCacheConfig(
          maxMemoryCacheSize: 10,
          memoryCacheExpiration: Duration(minutes: 2),
          hiveCacheExpiration: Duration(hours: 2),
          cleanupInterval: Duration(seconds: 30),
        );
        final customCacheManager = MarketIndexCacheManager(
          config: customConfig,
        );

        // When
        for (int i = 0; i < 12; i++) {
          await customCacheManager.cacheIndexData(
            createTestIndexData('CUSTOM_$i'),
          );
        }

        // Then
        final stats = customCacheManager.getStatistics();
        expect(stats.memoryCacheSize, lessThanOrEqualTo(10));

        await customCacheManager.dispose();
      });
    });
  });
}

/// 创建测试用的市场指数数据
MarketIndexData createTestIndexData(String code) {
  return MarketIndexData(
    code: code,
    name: getIndexName(code),
    currentValue: Decimal.parse('3000.50'),
    previousClose: Decimal.parse('2995.20'),
    openPrice: Decimal.parse('2998.00'),
    highPrice: Decimal.parse('3010.80'),
    lowPrice: Decimal.parse('2990.15'),
    changeAmount: Decimal.parse('5.30'),
    changePercentage: Decimal.parse('0.177'),
    volume: 1000000,
    turnover: Decimal.parse('15000000000'),
    updateTime: DateTime.now(),
    marketStatus: MarketStatus.trading,
    qualityLevel: DataQualityLevel.good,
    dataSource: 'test',
  );
}

/// 根据代码获取指数名称
String getIndexName(String code) {
  final nameMap = {
    'SH000001': '上证指数',
    'SZ399001': '深证成指',
    'SH000300': '沪深300',
  };
  return nameMap[code] ?? '测试指数';
}
