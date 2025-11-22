import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/widgets/cards/fund_card_factory.dart';
import 'package:jisu_fund_analyzer/src/features/fund/domain/entities/fund.dart';

void main() {
  group('AC7缓存效率专项验证', () {
    setUp(() {
      // 每个测试前清空缓存
      FundCardFactory.clearCache();
    });

    test('AC7目标验证：缓存效率应达到60%+', () async {
      print('\n=== AC7 缓存效率专项验证 ===');

      final testFunds = List.generate(10, (index) => createTestFund(index));

      // 阶段1: 预热缓存
      print('阶段1: 执行缓存预热...');
      await FundCardFactory.warmupCache(
        popularFunds: testFunds,
        preferredType: FundCardType.adaptive,
      );

      var warmupStats = FundCardFactory.getDetailedCacheStats();
      print('预热后缓存效率: ${warmupStats['efficiency'].toStringAsFixed(1)}%');

      // 阶段2: 模拟高频使用场景
      print('\n阶段2: 模拟高频使用场景...');

      // 多轮访问相同基金，模拟真实用户行为
      for (int round = 1; round <= 5; round++) {
        print('轮次 $round:');

        for (final fund in testFunds) {
          FundCardFactory.createCard(
            fund: fund,
            type: FundCardType.adaptive,
            onTap: () {},
            onAddToWatchlist: () {},
            onCompare: () {},
          );
        }

        var roundStats = FundCardFactory.getDetailedCacheStats();
        print('  轮次缓存效率: ${roundStats['efficiency'].toStringAsFixed(1)}%');
      }

      // 阶段3: 验证最终结果
      var finalStats = FundCardFactory.getDetailedCacheStats();

      print('\n=== AC7 最终验证结果 ===');
      print('总请求数: ${finalStats['totalRequests']}');
      print('缓存命中: ${finalStats['cacheHits']}');
      print('缓存未命中: ${finalStats['cacheMisses']}');
      print('最终缓存效率: ${finalStats['efficiency'].toStringAsFixed(1)}%');
      print('缓存大小: ${finalStats['cacheSize']}');

      // 验证AC7目标：缓存效率应该达到60%+
      expect(finalStats['efficiency'], greaterThan(60.0),
          reason: 'AC7: 不必要重建减少60%+ - 缓存效率应达到60%+');

      print(
          '\n✅ AC7验证成功: 缓存效率${finalStats['efficiency'].toStringAsFixed(1)}% > 60%');
    });

    test('激进缓存策略验证', () {
      print('\n=== 激进缓存策略验证 ===');

      final testFund = createTestFund(1);

      // 第一次创建 (缓存未命中)
      FundCardFactory.createCard(
        fund: testFund,
        type: FundCardType.adaptive,
      );

      var stats1 = FundCardFactory.getDetailedCacheStats();
      print('首次创建后 - 缓存效率: ${stats1['efficiency'].toStringAsFixed(1)}%');

      // 后续多次创建 (应该全部缓存命中)
      for (int i = 0; i < 10; i++) {
        FundCardFactory.createCard(
          fund: testFund,
          type: FundCardType.adaptive,
        );
      }

      var finalStats = FundCardFactory.getDetailedCacheStats();
      print('最终缓存效率: ${finalStats['efficiency'].toStringAsFixed(1)}%');
      print('缓存命中率: ${(finalStats['hitRate'] * 100).toStringAsFixed(1)}%');

      // 验证激进缓存策略的有效性
      expect(finalStats['efficiency'], greaterThan(80.0),
          reason: '激进缓存策略应该实现80%+的缓存效率');

      print('\n✅ 激进缓存策略验证成功: ${finalStats['efficiency'].toStringAsFixed(1)}%');
    });
  });
}

// 创建测试基金数据的辅助函数
Fund createTestFund(int index) {
  return Fund(
    code: 'FF${index.toString().padLeft(4, '0')}',
    name: '测试基金$index',
    type: index % 2 == 0 ? '股票型' : '债券型',
    company: '测试基金公司${index % 5}',
    manager: '测试基金经理${index % 3}',
    unitNav: 1.2345 + (index * 0.001),
    accumulatedNav: 1.2345 + (index * 0.001),
    dailyReturn: (index % 10 - 5) * 0.01,
    return1W: (index % 10 - 5) * 0.02,
    return1M: (index % 10 - 5) * 0.05,
    return3M: (index % 10 - 5) * 0.1,
    return6M: (index % 10 - 5) * 0.15,
    return1Y: (index % 20 - 10) * 0.1,
    return2Y: (index % 20 - 10) * 0.12,
    return3Y: (index % 20 - 10) * 0.14,
    returnYTD: (index % 10 - 5) * 0.08,
    returnSinceInception: (index % 20 - 10) * 0.2,
    scale: (10 + index * 5).toDouble(),
    riskLevel: ['低风险', '中风险', '高风险'][index % 3],
    status: '正常',
    date: '2024-01-01',
    fee: 1.5 + (index % 3) * 0.5,
    rankingPosition: index + 1,
    totalCount: 100,
    currentPrice: 1.2345 + (index * 0.001),
    dailyChange: (index % 10 - 5) * 0.001,
    dailyChangePercent: (index % 10 - 5) * 0.1,
    lastUpdate: DateTime.now().subtract(Duration(days: index % 30)),
  );
}
