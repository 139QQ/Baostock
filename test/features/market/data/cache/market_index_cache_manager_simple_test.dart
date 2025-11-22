import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:decimal/decimal.dart';

import 'package:jisu_fund_analyzer/src/features/market/data/cache/market_index_cache_manager.dart';
import 'package:jisu_fund_analyzer/src/features/market/models/market_index_data.dart';

/// 市场指数缓存管理器简化测试
void main() {
  group('MarketIndexCacheManager 简化测试', () {
    late MarketIndexCacheManager cacheManager;

    setUp(() {
      cacheManager = MarketIndexCacheManager();
    });

    tearDown(() async {
      await cacheManager.dispose();
    });

    group('基本缓存功能', () {
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
        expect(cachedData.currentValue, equals(Decimal.parse('3000.50')));
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
          'SH000300',
          'NON_EXISTENT',
        ]);

        // Then
        expect(results.length, equals(3));
        expect(results.containsKey('SH000001'), isTrue);
        expect(results.containsKey('SZ399001'), isTrue);
        expect(results.containsKey('SH000300'), isTrue);
        expect(results.containsKey('NON_EXISTENT'), isFalse);
      });
    });

    group('LRU策略', () {
      test('应该正确实施LRU策略', () async {
        // Given - 小缓存配置
        final smallCacheManager = MarketIndexCacheManager(
          config: const MarketIndexCacheConfig(
            maxMemoryCacheSize: 3,
            memoryCacheExpiration: Duration(hours: 1),
          ),
        );

        try {
          // When - 添加4个条目（超过最大值）
          await smallCacheManager
              .cacheIndexData(createTestIndexData('INDEX_1'));
          await smallCacheManager
              .cacheIndexData(createTestIndexData('INDEX_2'));
          await smallCacheManager
              .cacheIndexData(createTestIndexData('INDEX_3'));
          await smallCacheManager
              .cacheIndexData(createTestIndexData('INDEX_4'));

          // Then - 最早的条目应该被移除
          final first = await smallCacheManager.getCachedIndexData('INDEX_1');
          final second = await smallCacheManager.getCachedIndexData('INDEX_2');
          final third = await smallCacheManager.getCachedIndexData('INDEX_3');
          final fourth = await smallCacheManager.getCachedIndexData('INDEX_4');

          expect(first, isNull); // 应该被LRU移除
          expect(second, isNotNull);
          expect(third, isNotNull);
          expect(fourth, isNotNull);
        } finally {
          await smallCacheManager.dispose();
        }
      });
    });

    group('缓存统计', () {
      test('应该提供准确的缓存统计信息', () async {
        // Given
        await cacheManager.cacheIndexData(createTestIndexData('SH000001'));

        // 触发一次缓存命中
        await cacheManager.getCachedIndexData('SH000001');

        // 触发一次缓存未命中
        await cacheManager.getCachedIndexData('NON_EXISTENT');

        // When
        final stats = cacheManager.getStatistics();

        // Then
        expect(stats.memoryHits, equals(1));
        expect(stats.misses, equals(1));
        expect(stats.writes, equals(1));
        expect(stats.memoryHitRate, equals(0.5)); // 1 hit / (1 hit + 1 miss)
      });
    });

    group('预取功能', () {
      test('应该能够跟踪访问模式', () async {
        // Given
        final indexData = createTestIndexData('SH000001');

        // When - 多次访问同一个指数
        await cacheManager.cacheIndexData(indexData);
        await cacheManager.getCachedIndexData('SH000001');
        await cacheManager.getCachedIndexData('SH000001');
        await cacheManager.getCachedIndexData('SH000001');

        // Then
        final prefetchStats = cacheManager.getPrefetchStatistics();
        expect(prefetchStats.accessPatternsCount, greaterThan(0));
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
