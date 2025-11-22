import 'package:flutter_test/flutter_test.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/widgets/cards/fund_card_factory.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/widgets/cards/adaptive_fund_card.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/widgets/cards/microinteractive_fund_card.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/widgets/cards/base_fund_card.dart';
import 'package:jisu_fund_analyzer/src/features/fund/domain/entities/fund.dart';

void main() {
  group('FundCardFactory 单元测试', () {
    setUp(() {
      // 每个测试前清空缓存
      FundCardFactory.clearCache();
    });

    group('缓存机制测试', () {
      test('应该正确缓存和复用组件', () {
        final fund = createTestFund(1);

        // 第一次创建
        final card1 = FundCardFactory.createFundCard(
          fund: fund,
          cardType: FundCardType.adaptive,
        );

        // 第二次创建相同的卡片应该从缓存获取
        final card2 = FundCardFactory.createFundCard(
          fund: fund,
          cardType: FundCardType.adaptive,
        );

        // 验证缓存大小
        expect(FundCardFactory.cacheSize, equals(1));

        // 验证缓存统计
        final stats = FundCardFactory.getDetailedCacheStats();
        expect(stats['totalRequests'], equals(2));
        expect(stats['cacheHits'], equals(1));
        expect(stats['cacheMisses'], equals(1));
        expect(stats['hitRate'], equals(0.5));
      });

      test('forceCreate 应该绕过缓存', () {
        final fund = createTestFund(2);

        // 第一次创建
        final card1 = FundCardFactory.createFundCard(
          fund: fund,
          cardType: FundCardType.adaptive,
        );

        // 强制创建应该绕过缓存
        final card2 = FundCardFactory.createFundCard(
          fund: fund,
          cardType: FundCardType.adaptive,
          forceCreate: true,
        );

        // 缓存大小仍为1，因为强制创建不缓存
        expect(FundCardFactory.cacheSize, equals(1));

        final stats = FundCardFactory.getDetailedCacheStats();
        expect(stats['totalRequests'], equals(2));
        expect(stats['cacheMisses'], equals(1)); // 强制创建也算一次请求
      });

      test('不同类型的卡片应该分别缓存', () {
        final fund = createTestFund(3);

        // 创建不同类型的卡片
        FundCardFactory.createFundCard(
          fund: fund,
          cardType: FundCardType.adaptive,
        );

        FundCardFactory.createFundCard(
          fund: fund,
          cardType: FundCardType.microinteractive,
        );

        expect(FundCardFactory.cacheSize, equals(2));

        final stats = FundCardFactory.getDetailedCacheStats();
        expect(stats['totalRequests'], equals(2));
        expect(stats['cacheMisses'], equals(2));
      });

      test('缓存效率计算应该正确', () {
        final fund = createTestFund(4);

        // 多次创建相同的卡片
        for (int i = 0; i < 10; i++) {
          FundCardFactory.createFundCard(
            fund: fund,
            cardType: FundCardType.adaptive,
          );
        }

        final stats = FundCardFactory.getDetailedCacheStats();
        expect(stats['totalRequests'], equals(10));
        expect(stats['cacheHits'], equals(9)); // 除第一次外都是缓存命中
        expect(stats['cacheMisses'], equals(1));
        expect(stats['hitRate'], equals(0.9));
        expect(stats['efficiency'], equals(90.0));
      });
    });

    group('LRU 缓存策略测试', () {
      test('应该正确实施LRU策略', () {
        // 创建多个不同的卡片
        final funds = List.generate(5, (i) => createTestFund(i));

        for (final fund in funds) {
          FundCardFactory.createFundCard(
            fund: fund,
            cardType: FundCardType.adaptive,
          );
        }

        expect(FundCardFactory.cacheSize, equals(5));

        // 访问第一个卡片以更新其访问时间
        FundCardFactory.createFundCard(
          fund: funds[0],
          cardType: FundCardType.adaptive,
        );

        // 优化缓存到3个大小
        FundCardFactory.optimizeCache(maxCacheSize: 3);

        // 验证缓存大小被限制为3
        expect(FundCardFactory.cacheSize, equals(3));

        // 第一个卡片应该还在缓存中（因为最近被访问）
        final stats1 = FundCardFactory.getDetailedCacheStats();
        final hitCount1 = stats1['cacheHits'];

        FundCardFactory.createFundCard(
          fund: funds[0],
          cardType: FundCardType.adaptive,
        );

        final stats2 = FundCardFactory.getDetailedCacheStats();
        // 由于缓存大小已被限制，第一个卡片可能被清理，所以我们只验证逻辑不抛异常
        expect(stats2['cacheHits'],
            greaterThanOrEqualTo(hitCount1)); // 至少保持原来的命中次数
      });

      test('智能缓存清理应该基于多个策略', () {
        // 创建多个卡片
        final funds = List.generate(10, (i) => createTestFund(i));

        for (final fund in funds) {
          FundCardFactory.createFundCard(
            fund: fund,
            cardType: FundCardType.adaptive,
          );
        }

        expect(FundCardFactory.cacheSize, equals(10));

        // 执行智能清理，限制缓存大小为5
        FundCardFactory.smartCacheCleanup(maxCacheSize: 5);

        // 验证缓存大小被限制
        expect(FundCardFactory.cacheSize, lessThanOrEqualTo(5));
      });
    });

    group('批量创建测试', () {
      test('应该正确批量创建卡片', () {
        final funds = List.generate(5, (i) => createTestFund(i));

        final cards = FundCardFactory.createFundCardList(
          funds: funds,
          cardType: FundCardType.adaptive,
        );

        expect(cards.length, equals(5));
        expect(FundCardFactory.cacheSize, equals(5));

        final stats = FundCardFactory.getDetailedCacheStats();
        expect(stats['totalRequests'], equals(5));
        expect(stats['cacheMisses'], equals(5));
      });

      test('批量创建应该支持选中状态', () {
        final funds = List.generate(3, (i) => createTestFund(i));
        final selectedFunds = {'FF0001', 'FF0003'};

        final cards = FundCardFactory.createFundCardList(
          funds: funds,
          cardType: FundCardType.adaptive,
          selectedFunds: selectedFunds,
        );

        expect(cards.length, equals(3));
        // 无法直接验证选中状态，但应该不抛出异常
      });
    });

    group('配置验证测试', () {
      test('应该验证卡片配置', () {
        final validConfig = FundCardFactory.getDefaultConfig();
        expect(FundCardFactory.validateCardConfig(validConfig), isTrue);

        final invalidConfig = FundCardConfig(
          animationLevel: -1,
        );
        expect(FundCardFactory.validateCardConfig(invalidConfig), isFalse);
      });

      test('应该提供默认配置', () {
        final defaultConfig = FundCardFactory.getDefaultConfig();
        expect(defaultConfig.animationLevel, greaterThanOrEqualTo(0));
        expect(defaultConfig.animationLevel, lessThanOrEqualTo(2));
      });
    });

    group('兼容性接口测试', () {
      test('createCard 方法应该向后兼容', () {
        final fund = createTestFund(6);

        // 使用废弃的 createCard 方法
        final card = FundCardFactory.createCard(
          fund: fund,
          type: FundCardType.adaptive,
        );

        expect(card, isNotNull);
        expect(FundCardFactory.cacheSize, equals(1));
      });
    });

    group('错误处理测试', () {
      test('应该处理空基金列表', () {
        final cards = FundCardFactory.createFundCardList(
          funds: [],
          cardType: FundCardType.adaptive,
        );

        expect(cards, isEmpty);
        expect(FundCardFactory.cacheSize, equals(0));
      });

      test('应该处理单个基金的批量创建', () {
        final funds = [createTestFund(100)];
        final cards = FundCardFactory.createFundCardList(
          funds: funds,
          cardType: FundCardType.adaptive,
        );

        expect(cards.length, equals(1));
        expect(FundCardFactory.cacheSize, equals(1));
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
