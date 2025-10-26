import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/data/services/portfolio_profit_cache_service.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/data/adapters/portfolio_holding_adapter.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/entities/portfolio_holding.dart';

void main() {
  group('PortfolioProfitCacheService Tests', () {
    late PortfolioProfitCacheService cacheService;

    setUpAll(() async {
      // 初始化Hive测试环境
      Hive.init('test_cache');

      // 注册适配器
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(PortfolioHoldingAdapter());
      }
    });

    setUp(() async {
      cacheService = PortfolioProfitCacheService();
      await cacheService.initialize();
    });

    tearDown(() async {
      await cacheService.dispose();
    });

    tearDownAll(() async {
      await Hive.deleteFromDisk();
    });

    test('应该成功初始化缓存服务', () {
      expect(cacheService, isNotNull);
    });

    test('应该成功缓存和读取PortfolioHolding数据', () async {
      // 创建测试数据
      final testHolding = PortfolioHolding(
        fundCode: '000001',
        fundName: '华夏成长混合',
        fundType: '混合型',
        holdingAmount: 1000.0,
        costNav: 1.0,
        costValue: 1000.0,
        marketValue: 1200.0,
        currentNav: 1.2,
        accumulatedNav: 2.5,
        holdingStartDate: DateTime(2023, 1, 1),
        lastUpdatedDate: DateTime.now(),
        dividendReinvestment: true,
        status: HoldingStatus.active,
        notes: '测试持仓',
      );

      // 缓存数据
      await cacheService.cacheHoldings(
        'test_user',
        [testHolding],
        Duration(hours: 1),
      );

      // 读取缓存数据
      final cachedHoldings = await cacheService.getCachedHoldings('test_user');

      expect(cachedHoldings, isNotNull);
      expect(cachedHoldings!.length, 1);
      expect(cachedHoldings.first.fundCode, '000001');
      expect(cachedHoldings.first.fundName, '华夏成长混合');
      expect(cachedHoldings.first.holdingAmount, 1000.0);
    });

    test('应该在没有缓存时返回null', () async {
      final result = await cacheService.getCachedHoldings('non_existent_user');
      expect(result, isNull);
    });

    test('应该正确处理过期缓存', () async {
      final testHolding = PortfolioHolding(
        fundCode: '000002',
        fundName: '测试基金',
        fundType: '股票型',
        holdingAmount: 500.0,
        costNav: 1.0,
        costValue: 500.0,
        marketValue: 550.0,
        currentNav: 1.1,
        accumulatedNav: 1.8,
        holdingStartDate: DateTime(2023, 6, 1),
        lastUpdatedDate: DateTime.now(),
        dividendReinvestment: false,
        status: HoldingStatus.active,
      );

      // 缓存数据，设置非常短的过期时间
      await cacheService.cacheHoldings(
        'expiry_test',
        [testHolding],
        Duration(milliseconds: 10),
      );

      // 等待缓存过期
      await Future.delayed(Duration(milliseconds: 20));

      // 尝试读取过期缓存
      final cachedHoldings =
          await cacheService.getCachedHoldings('expiry_test');
      expect(cachedHoldings, isNull);
    });

    test('应该正确处理空列表缓存', () async {
      // 缓存空列表
      await cacheService.cacheHoldings(
        'empty_test',
        [],
        Duration(hours: 1),
      );

      // 读取空列表缓存
      final cachedHoldings = await cacheService.getCachedHoldings('empty_test');
      expect(cachedHoldings, isNotNull);
      expect(cachedHoldings!.isEmpty, isTrue);
    });

    test('应该正确清除过期缓存', () async {
      // 添加一些缓存项
      await cacheService.cacheHoldings(
        'clear_test_1',
        [
          PortfolioHolding(
            fundCode: '001',
            fundName: '基金1',
            fundType: '股票型',
            holdingAmount: 100.0,
            costNav: 1.0,
            costValue: 100.0,
            marketValue: 110.0,
            currentNav: 1.1,
            accumulatedNav: 1.5,
            holdingStartDate: DateTime.now(),
            lastUpdatedDate: DateTime.now(),
            dividendReinvestment: false,
            status: HoldingStatus.active,
          )
        ],
        Duration(milliseconds: 10),
      );

      await cacheService.cacheHoldings(
        'clear_test_2',
        [
          PortfolioHolding(
            fundCode: '002',
            fundName: '基金2',
            fundType: '债券型',
            holdingAmount: 200.0,
            costNav: 1.0,
            costValue: 200.0,
            marketValue: 205.0,
            currentNav: 1.025,
            accumulatedNav: 1.2,
            holdingStartDate: DateTime.now(),
            lastUpdatedDate: DateTime.now(),
            dividendReinvestment: true,
            status: HoldingStatus.active,
          )
        ],
        Duration(hours: 1),
      );

      // 等待第一个缓存项过期
      await Future.delayed(Duration(milliseconds: 20));

      // 清除过期缓存
      await cacheService.clearExpiredCache();

      // 验证结果
      final expiredHoldings =
          await cacheService.getCachedHoldings('clear_test_1');
      final validHoldings =
          await cacheService.getCachedHoldings('clear_test_2');

      expect(expiredHoldings, isNull);
      expect(validHoldings, isNotNull);
      expect(validHoldings!.length, 1);
      expect(validHoldings.first.fundCode, '002');
    });

    test('应该正确处理缓存和读取操作', () async {
      // 测试缓存服务的核心功能
      await cacheService.cacheHoldings(
        'core_test',
        [
          PortfolioHolding(
            fundCode: '003',
            fundName: '核心测试基金',
            fundType: '货币型',
            holdingAmount: 300.0,
            costNav: 1.0,
            costValue: 300.0,
            marketValue: 301.0,
            currentNav: 1.0033,
            accumulatedNav: 1.1,
            holdingStartDate: DateTime.now(),
            lastUpdatedDate: DateTime.now(),
            dividendReinvestment: false,
            status: HoldingStatus.active,
          )
        ],
        Duration(hours: 1),
      );

      // 尝试读取缓存
      final result = await cacheService.getCachedHoldings('core_test');
      expect(result, isNotNull);
      expect(result!.length, 1);
      expect(result.first.fundCode, '003');
      expect(result.first.fundName, '核心测试基金');
    });
  });
}
