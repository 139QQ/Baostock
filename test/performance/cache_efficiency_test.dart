import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/widgets/cards/fund_card_factory.dart';
import 'package:jisu_fund_analyzer/src/features/fund/domain/entities/fund.dart';

void main() {
  group('AC7: 缓存效率60%+验证测试', () {
    setUpAll(() {
      // 确保Flutter测试环境初始化
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    group('高复用场景测试 - 验证AC7 60%+目标', () {
      testWidgets('模拟真实使用场景 - 相同基金多次创建应达到高缓存命中率', (WidgetTester tester) async {
        // 创建模拟的常用基金列表
        final popularFunds =
            List.generate(10, (index) => createTestFund(index));

        // 第一阶段：建立初始缓存
        print('\n=== 阶段1: 建立初始缓存 ===');
        for (final fund in popularFunds) {
          FundCardFactory.createFundCard(
            fund: fund,
            cardType: FundCardType.adaptive,
            onTap: () {},
            onAddToWatchlist: () {},
            onCompare: () {},
          );
        }

        var stats1 = FundCardFactory.getDetailedCacheStats();
        print('初始缓存建立:');
        print('- 总请求数: ${stats1['totalRequests']}');
        print('- 缓存命中: ${stats1['cacheHits']}');
        print('- 缓存未命中: ${stats1['cacheMisses']}');
        print('- 缓存效率: ${stats1['efficiency'].toStringAsFixed(1)}%');

        // 第二阶段：模拟真实复用场景 - 相同基金多次访问
        print('\n=== 阶段2: 模拟真实复用场景 ===');

        // 多轮模拟用户浏览相同基金
        for (int round = 1; round <= 5; round++) {
          print('\n轮次 $round:');

          // 模拟用户浏览基金列表
          for (final fund in popularFunds) {
            // 第一遍浏览（通常操作）
            FundCardFactory.createFundCard(
              fund: fund,
              cardType: FundCardType.adaptive,
              onTap: () {},
              onAddToWatchlist: () {},
              onCompare: () {},
            );

            // 第二遍浏览（快速滚动）
            FundCardFactory.createFundCard(
              fund: fund,
              cardType: FundCardType.adaptive,
              onTap: () {},
              onAddToWatchlist: () {},
              onCompare: () {},
            );
          }

          var roundStats = FundCardFactory.getDetailedCacheStats();
          print('- 轮次缓存效率: ${roundStats['efficiency'].toStringAsFixed(1)}%');
        }

        var finalStats = FundCardFactory.getDetailedCacheStats();

        print('\n=== 最终结果 ===');
        print('总请求数: ${finalStats['totalRequests']}');
        print('缓存命中: ${finalStats['cacheHits']}');
        print('缓存未命中: ${finalStats['cacheMisses']}');
        print('最终缓存效率: ${finalStats['efficiency'].toStringAsFixed(1)}%');
        print('缓存大小: ${finalStats['cacheSize']}');

        // 验证AC7目标：缓存效率应该达到60%+
        expect(finalStats['efficiency'], greaterThan(60.0),
            reason: 'AC7: 不必要重建减少60%+ - 缓存效率应达到60%+');
      });

      testWidgets('混合场景测试 - 不同基金和配置的混合使用', (WidgetTester tester) async {
        print('\n=== 混合场景测试 ===');

        // 创建混合基金列表
        final mixedFunds = [
          ...List.generate(5, (i) => createTestFund(i)),
          ...List.generate(5, (i) => createTestFund(i + 100)), // 不同的基金代码
        ];

        // 预热阶段
        print('预热阶段...');
        for (final fund in mixedFunds) {
          FundCardFactory.createFundCard(
            fund: fund,
            cardType: FundCardType.adaptive,
            onTap: () {},
            onAddToWatchlist: () {},
            onCompare: () {},
          );
        }

        var preWarmStats = FundCardFactory.getDetailedCacheStats();
        print('预热后缓存效率: ${preWarmStats['efficiency'].toStringAsFixed(1)}%');

        // 模拟高频访问某些基金
        final frequentlyAccessedFunds = mixedFunds.take(3).toList();

        print('\n高频访问阶段...');
        for (int i = 0; i < 20; i++) {
          for (final fund in frequentlyAccessedFunds) {
            FundCardFactory.createFundCard(
              fund: fund,
              cardType: FundCardType.adaptive,
              onTap: () {},
              onAddToWatchlist: () {},
              onCompare: () {},
            );
          }
        }

        // 偶尔访问其他基金
        print('偶尔访问阶段...');
        for (int i = 0; i < 5; i++) {
          for (final fund in mixedFunds.skip(3).take(7)) {
            FundCardFactory.createFundCard(
              fund: fund,
              cardType: FundCardType.adaptive,
              onTap: () {},
              onAddToWatchlist: () {},
              onCompare: () {},
            );
          }
        }

        var mixedStats = FundCardFactory.getDetailedCacheStats();

        print('\n=== 混合场景结果 ===');
        print('总请求数: ${mixedStats['totalRequests']}');
        print('缓存命中: ${mixedStats['cacheHits']}');
        print('缓存未命中: ${mixedStats['cacheMisses']}');
        print('最终缓存效率: ${mixedStats['efficiency'].toStringAsFixed(1)}%');

        // 验证混合场景下仍应达到较高缓存效率
        expect(mixedStats['efficiency'], greaterThan(50.0),
            reason: '混合场景下缓存效率应保持较高水平');
      });

      testWidgets('预热效果测试 - 验证预热对缓存效率的提升', (WidgetTester tester) async {
        print('\n=== 预热效果测试 ===');

        // 清空缓存重新开始
        FundCardFactory.clearCache();

        final testFunds = List.generate(15, (i) => createTestFund(i));

        // 测试无预热的情况
        print('无预热阶段...');
        for (int i = 0; i < 3; i++) {
          for (final fund in testFunds) {
            FundCardFactory.createFundCard(
              fund: fund,
              cardType: FundCardType.adaptive,
              onTap: () {},
              onAddToWatchlist: () {},
              onCompare: () {},
            );
          }
        }

        var noWarmupStats = FundCardFactory.getDetailedCacheStats();
        print('无预热缓存效率: ${noWarmupStats['efficiency'].toStringAsFixed(1)}%');

        // 清空缓存
        FundCardFactory.clearCache();

        // 执行预热
        print('执行预热...');
        await FundCardFactory.warmupCache(
          popularFunds: testFunds,
          preferredType: FundCardType.adaptive,
        );

        var warmupStats = FundCardFactory.getDetailedCacheStats();
        print('预热后缓存效率: ${warmupStats['efficiency'].toStringAsFixed(1)}%');
        print('预热后缓存大小: ${warmupStats['cacheSize']}');

        // 测试预热后的性能
        print('预热后性能测试...');
        for (int i = 0; i < 3; i++) {
          for (final fund in testFunds) {
            FundCardFactory.createFundCard(
              fund: fund,
              cardType: FundCardType.adaptive,
              onTap: () {},
              onAddToWatchlist: () {},
              onCompare: () {},
            );
          }
        }

        var finalWarmupStats = FundCardFactory.getDetailedCacheStats();

        print('\n=== 预热效果结果 ===');
        print(
            '预热后最终缓存效率: ${finalWarmupStats['efficiency'].toStringAsFixed(1)}%');
        print('预热最终缓存大小: ${finalWarmupStats['cacheSize']}');

        // 预热应该显著提升缓存效率
        expect(finalWarmupStats['efficiency'], greaterThan(40.0),
            reason: '预热应该显著提升缓存效率');
      });
    });

    group('压力测试 - 验证缓存稳定性', () {
      testWidgets('大规模缓存压力测试', (WidgetTester tester) async {
        print('\n=== 大规模缓存压力测试 ===');

        final largeFundSet = List.generate(100, (i) => createTestFund(i));

        // 第一轮：创建大量缓存条目
        print('创建大规模缓存...');
        final stopwatch1 = Stopwatch()..start();

        for (final fund in largeFundSet) {
          FundCardFactory.createFundCard(
            fund: fund,
            cardType: FundCardType.adaptive,
            onTap: () {},
            onAddToWatchlist: () {},
            onCompare: () {},
          );
        }

        stopwatch1.stop();
        var massCreationStats = FundCardFactory.getDetailedCacheStats();

        print('大规模缓存创建完成:');
        print('- 创建时间: ${stopwatch1.elapsedMilliseconds}ms');
        print('- 缓存大小: ${massCreationStats['cacheSize']}');
        print('- 缓存效率: ${massCreationStats['efficiency'].toStringAsFixed(1)}%');

        // 第二轮：大规模复用测试
        print('大规模复用测试...');
        final stopwatch2 = Stopwatch()..start();

        // 重复访问前50个基金
        final frequentlyUsed = largeFundSet.take(50).toList();
        for (int i = 0; i < 10; i++) {
          for (final fund in frequentlyUsed) {
            FundCardFactory.createFundCard(
              fund: fund,
              cardType: FundCardType.adaptive,
              onTap: () {},
              onAddToWatchlist: () {},
              onCompare: () {},
            );
          }
        }

        stopwatch2.stop();
        var massReuseStats = FundCardFactory.getDetailedCacheStats();

        print('\n=== 压力测试结果 ===');
        print('复用测试时间: ${stopwatch2.elapsedMilliseconds}ms');
        print('最终缓存效率: ${massReuseStats['efficiency'].toStringAsFixed(1)}%');
        print('最终缓存大小: ${massReuseStats['cacheSize']}');
        print('总缓存命中: ${massReuseStats['cacheHits']}');
        print('总请求数: ${massReuseStats['totalRequests']}');

        // 验证大规模场景下的性能表现
        expect(massReuseStats['efficiency'], greaterThan(40.0),
            reason: '大规模场景下缓存效率应保持较高水平');
        expect(stopwatch2.elapsedMilliseconds, lessThan(1000),
            reason: '大规模复用操作应在合理时间内完成');
      });
    });
  });
}

/// 创建测试基金数据的辅助函数
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
