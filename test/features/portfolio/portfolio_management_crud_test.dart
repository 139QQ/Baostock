import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/entities/portfolio_holding.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/presentation/cubit/portfolio_analysis_cubit.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/data/services/portfolio_data_service.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/data/repositories/portfolio_profit_repository_impl.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/data/services/portfolio_profit_api_service.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/data/services/portfolio_profit_cache_service.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/services/portfolio_profit_calculation_engine.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/data/adapters/portfolio_holding_adapter.dart';

void main() {
  group('持仓管理增删改查测试', () {
    late PortfolioDataService portfolioDataService;
    late PortfolioAnalysisCubit portfolioCubit;
    late String testUserId;

    setUpAll(() async {
      // 初始化Hive测试环境
      Hive.init('test_portfolio_crud');

      // 注册适配器
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(PortfolioHoldingAdapter());
      }
    });

    setUp(() async {
      // 创建唯一的测试用户ID
      testUserId = 'test_user_${DateTime.now().millisecondsSinceEpoch}';

      // 初始化服务
      portfolioDataService = PortfolioDataService();

      // 初始化缓存服务
      final cacheService = PortfolioProfitCacheService.defaultService();
      await cacheService.initialize();

      // 创建Cubit实例
      final repository = PortfolioProfitRepositoryImpl(
        apiService: PortfolioProfitApiService(),
        cacheService: cacheService,
        calculationEngine: PortfolioProfitCalculationEngine(),
      );

      portfolioCubit = PortfolioAnalysisCubit(
        repository: repository,
        dataService: portfolioDataService,
      );
    });

    tearDown(() async {
      // 清理测试数据
      await portfolioDataService.clearAllHoldings(testUserId);
      portfolioCubit.close();
    });

    tearDownAll(() async {
      await Hive.deleteFromDisk();
    });

    group('数据服务层 CRUD 测试', () {
      test('应该能够创建和读取持仓（增查）', () async {
        // 创建测试持仓
        final testHolding = PortfolioHolding(
          fundCode: '000001',
          fundName: '华夏成长混合',
          fundType: '混合型',
          holdingAmount: 1000.0,
          costNav: 1.2500,
          costValue: 1250.0,
          marketValue: 1350.0,
          currentNav: 1.3500,
          accumulatedNav: 2.4500,
          holdingStartDate: DateTime.now().subtract(const Duration(days: 30)),
          lastUpdatedDate: DateTime.now(),
          dividendReinvestment: true,
          status: HoldingStatus.active,
          notes: '测试持仓',
        );

        // 测试创建持仓
        final addResult = await portfolioDataService.addOrUpdateHolding(
            testUserId, testHolding);
        expect(addResult.isRight(), isTrue);

        addResult.fold(
          (failure) => fail('创建持仓失败: ${failure.message}'),
          (addedHolding) {
            expect(addedHolding.fundCode, testHolding.fundCode);
            expect(addedHolding.fundName, testHolding.fundName);
          },
        );

        // 测试读取持仓
        final readResult =
            await portfolioDataService.getUserHoldings(testUserId);
        expect(readResult.isRight(), isTrue);

        readResult.fold(
          (failure) => fail('读取持仓失败: ${failure.message}'),
          (holdings) {
            expect(holdings.length, 1);
            expect(holdings.first.fundCode, testHolding.fundCode);
            expect(holdings.first.fundName, testHolding.fundName);
            expect(holdings.first.holdingAmount, testHolding.holdingAmount);
          },
        );
      });

      test('应该能够更新持仓（改查）', () async {
        // 先创建一个持仓
        final originalHolding = PortfolioHolding(
          fundCode: '000002',
          fundName: '易方达消费行业股票',
          fundType: '股票型',
          holdingAmount: 500.0,
          costNav: 2.1500,
          costValue: 1075.0,
          marketValue: 1180.0,
          currentNav: 2.3600,
          accumulatedNav: 3.5600,
          holdingStartDate: DateTime.now().subtract(const Duration(days: 60)),
          lastUpdatedDate: DateTime.now(),
          dividendReinvestment: false,
          status: HoldingStatus.active,
        );

        await portfolioDataService.addOrUpdateHolding(
            testUserId, originalHolding);

        // 更新持仓
        final updatedHolding = PortfolioHolding(
          fundCode: '000002',
          fundName: '易方达消费行业股票（更新）',
          fundType: '股票型',
          holdingAmount: 600.0, // 更新持有份额
          costNav: 2.1500,
          costValue: 1290.0, // 重新计算成本价值
          marketValue: 1416.0, // 重新计算市值
          currentNav: 2.3600,
          accumulatedNav: 3.5600,
          holdingStartDate: originalHolding.holdingStartDate,
          lastUpdatedDate: DateTime.now(),
          dividendReinvestment: true, // 更新分红再投资设置
          status: HoldingStatus.active,
        );

        // 测试更新持仓
        final updateResult = await portfolioDataService.addOrUpdateHolding(
            testUserId, updatedHolding);
        expect(updateResult.isRight(), isTrue);

        // 验证更新结果
        final readResult =
            await portfolioDataService.getUserHoldings(testUserId);
        expect(readResult.isRight(), isTrue);

        readResult.fold(
          (failure) => fail('读取持仓失败: ${failure.message}'),
          (holdings) {
            expect(holdings.length, 1); // 仍然只有一个持仓
            final holding = holdings.first;
            expect(holding.fundCode, updatedHolding.fundCode);
            expect(holding.fundName, updatedHolding.fundName);
            expect(holding.holdingAmount, updatedHolding.holdingAmount);
            expect(holding.dividendReinvestment,
                updatedHolding.dividendReinvestment);
            expect(
                holding.lastUpdatedDate
                    .isAfter(originalHolding.lastUpdatedDate),
                isTrue);
          },
        );
      });

      test('应该能够删除持仓（删查）', () async {
        // 创建多个持仓
        final holding1 = PortfolioHolding(
          fundCode: '000003',
          fundName: '中国可转债债券',
          fundType: '债券型',
          holdingAmount: 2000.0,
          costNav: 1.0500,
          costValue: 2100.0,
          marketValue: 2150.0,
          currentNav: 1.0750,
          accumulatedNav: 1.4500,
          holdingStartDate: DateTime.now().subtract(const Duration(days: 90)),
          lastUpdatedDate: DateTime.now(),
          dividendReinvestment: false,
          status: HoldingStatus.active,
        );

        final holding2 = PortfolioHolding(
          fundCode: '110022',
          fundName: '易方达消费行业股票',
          fundType: '股票型',
          holdingAmount: 800.0,
          costNav: 2.1500,
          costValue: 1720.0,
          marketValue: 1888.0,
          currentNav: 2.3600,
          accumulatedNav: 3.5600,
          holdingStartDate: DateTime.now().subtract(const Duration(days: 45)),
          lastUpdatedDate: DateTime.now(),
          dividendReinvestment: true,
          status: HoldingStatus.active,
        );

        // 添加持仓
        await portfolioDataService.addOrUpdateHolding(testUserId, holding1);
        await portfolioDataService.addOrUpdateHolding(testUserId, holding2);

        // 验证有两个持仓
        var readResult = await portfolioDataService.getUserHoldings(testUserId);
        expect(readResult.isRight(), isTrue);
        readResult.fold(
          (failure) => fail('读取持仓失败: ${failure.message}'),
          (holdings) => expect(holdings.length, 2),
        );

        // 删除一个持仓
        final deleteResult =
            await portfolioDataService.deleteHolding(testUserId, '000003');
        expect(deleteResult.isRight(), isTrue);
        deleteResult.fold(
          (failure) => fail('删除持仓失败: ${failure.message}'),
          (success) => expect(success, isTrue),
        );

        // 验证只剩一个持仓
        readResult = await portfolioDataService.getUserHoldings(testUserId);
        expect(readResult.isRight(), isTrue);
        readResult.fold(
          (failure) => fail('读取持仓失败: ${failure.message}'),
          (holdings) {
            expect(holdings.length, 1);
            expect(holdings.first.fundCode, '110022');
          },
        );
      });

      test('应该能够处理重复添加相同基金代码', () async {
        final holding = PortfolioHolding(
          fundCode: '000004',
          fundName: '嘉实沪深300ETF联接',
          fundType: '指数型',
          holdingAmount: 1500.0,
          costNav: 1.8000,
          costValue: 2700.0,
          marketValue: 2790.0,
          currentNav: 1.8600,
          accumulatedNav: 2.1000,
          holdingStartDate: DateTime.now().subtract(const Duration(days: 15)),
          lastUpdatedDate: DateTime.now(),
          dividendReinvestment: true,
          status: HoldingStatus.active,
        );

        // 第一次添加
        final result1 =
            await portfolioDataService.addOrUpdateHolding(testUserId, holding);
        expect(result1.isRight(), isTrue);

        // 第二次添加相同基金代码
        final updatedHolding = PortfolioHolding(
          fundCode: '000004',
          fundName: '嘉实沪深300ETF联接（更新）',
          fundType: '指数型',
          holdingAmount: 2000.0, // 更新份额
          costNav: 1.8000,
          costValue: 3600.0, // 重新计算
          marketValue: 3720.0, // 重新计算
          currentNav: 1.8600,
          accumulatedNav: 2.1000,
          holdingStartDate: holding.holdingStartDate,
          lastUpdatedDate: DateTime.now(),
          dividendReinvestment: false, // 更新分红设置
          status: HoldingStatus.active,
        );

        final result2 = await portfolioDataService.addOrUpdateHolding(
            testUserId, updatedHolding);
        expect(result2.isRight(), isTrue);

        // 验证只有一个持仓且是更新后的数据
        final readResult =
            await portfolioDataService.getUserHoldings(testUserId);
        expect(readResult.isRight(), isTrue);
        readResult.fold(
          (failure) => fail('读取持仓失败: ${failure.message}'),
          (holdings) {
            expect(holdings.length, 1);
            final finalHolding = holdings.first;
            expect(finalHolding.fundName, '嘉实沪深300ETF联接（更新）');
            expect(finalHolding.holdingAmount, 2000.0);
            expect(finalHolding.dividendReinvestment, false);
          },
        );
      });

      test('应该能够清空所有持仓', () async {
        // 创建多个持仓
        final holdings = [
          PortfolioHolding(
            fundCode: '000005',
            fundName: '华夏回报混合A',
            fundType: '混合型',
            holdingAmount: 1000.0,
            costNav: 3.2000,
            costValue: 3200.0,
            marketValue: 3350.0,
            currentNav: 3.3500,
            accumulatedNav: 4.8000,
            holdingStartDate:
                DateTime.now().subtract(const Duration(days: 120)),
            lastUpdatedDate: DateTime.now(),
            dividendReinvestment: true,
            status: HoldingStatus.active,
          ),
          PortfolioHolding(
            fundCode: '000006',
            fundName: '富国天惠成长混合',
            fundType: '混合型',
            holdingAmount: 800.0,
            costNav: 2.9000,
            costValue: 2320.0,
            marketValue: 2416.0,
            currentNav: 3.0200,
            accumulatedNav: 5.1000,
            holdingStartDate: DateTime.now().subtract(const Duration(days: 80)),
            lastUpdatedDate: DateTime.now(),
            dividendReinvestment: false,
            status: HoldingStatus.active,
          ),
        ];

        // 添加持仓
        for (final holding in holdings) {
          await portfolioDataService.addOrUpdateHolding(testUserId, holding);
        }

        // 验证有持仓
        var readResult = await portfolioDataService.getUserHoldings(testUserId);
        expect(readResult.isRight(), isTrue);
        readResult.fold(
          (failure) => fail('读取持仓失败: ${failure.message}'),
          (holdings) => expect(holdings.length, 2),
        );

        // 清空所有持仓
        final clearResult =
            await portfolioDataService.clearAllHoldings(testUserId);
        expect(clearResult.isRight(), isTrue);
        clearResult.fold(
          (failure) => fail('清空持仓失败: ${failure.message}'),
          (success) => expect(success, isTrue),
        );

        // 验证没有持仓了
        readResult = await portfolioDataService.getUserHoldings(testUserId);
        expect(readResult.isRight(), isTrue);
        readResult.fold(
          (failure) => fail('读取持仓失败: ${failure.message}'),
          (holdings) => expect(holdings.isEmpty, isTrue),
        );
      });
    });

    group('Cubit层 CRUD 测试', () {
      test('应该能够通过Cubit添加持仓', () async {
        final testHolding = PortfolioHolding(
          fundCode: '000007',
          fundName: '兴全合润混合',
          fundType: '混合型',
          holdingAmount: 1200.0,
          costNav: 2.5000,
          costValue: 3000.0,
          marketValue: 3180.0,
          currentNav: 2.6500,
          accumulatedNav: 3.9000,
          holdingStartDate: DateTime.now().subtract(const Duration(days: 25)),
          lastUpdatedDate: DateTime.now(),
          dividendReinvestment: true,
          status: HoldingStatus.active,
        );

        // 通过Cubit添加持仓
        final success = await portfolioCubit.addDefaultUserHolding(testHolding);
        expect(success, isTrue);

        // 验证持仓已添加
        final readResult =
            await portfolioDataService.getUserHoldings(testUserId);
        expect(readResult.isRight(), isTrue);
        readResult.fold(
          (failure) => fail('读取持仓失败: ${failure.message}'),
          (holdings) {
            expect(holdings.length, 1);
            expect(holdings.first.fundCode, testHolding.fundCode);
          },
        );
      });

      test('应该能够通过Cubit更新持仓', () async {
        // 先添加一个持仓
        final originalHolding = PortfolioHolding(
          fundCode: '000008',
          fundName: '中欧新蓝筹混合A',
          fundType: '混合型',
          holdingAmount: 1000.0,
          costNav: 1.8000,
          costValue: 1800.0,
          marketValue: 1920.0,
          currentNav: 1.9200,
          accumulatedNav: 2.6000,
          holdingStartDate: DateTime.now().subtract(const Duration(days: 40)),
          lastUpdatedDate: DateTime.now(),
          dividendReinvestment: false,
          status: HoldingStatus.active,
        );

        await portfolioCubit.addDefaultUserHolding(originalHolding);

        // 更新持仓
        final updatedHolding = PortfolioHolding(
          fundCode: '000008',
          fundName: '中欧新蓝筹混合A（更新）',
          fundType: '混合型',
          holdingAmount: 1500.0, // 更新份额
          costNav: 1.8000,
          costValue: 2700.0, // 重新计算
          marketValue: 2880.0, // 重新计算
          currentNav: 1.9200,
          accumulatedNav: 2.6000,
          holdingStartDate: originalHolding.holdingStartDate,
          lastUpdatedDate: DateTime.now(),
          dividendReinvestment: true, // 更新分红设置
          status: HoldingStatus.active,
        );

        // 通过Cubit更新持仓
        final success =
            await portfolioCubit.updateDefaultUserHolding(updatedHolding);
        expect(success, isTrue);

        // 验证持仓已更新
        final readResult =
            await portfolioDataService.getUserHoldings(testUserId);
        expect(readResult.isRight(), isTrue);
        readResult.fold(
          (failure) => fail('读取持仓失败: ${failure.message}'),
          (holdings) {
            expect(holdings.length, 1);
            final holding = holdings.first;
            expect(holding.fundName, '中欧新蓝筹混合A（更新）');
            expect(holding.holdingAmount, 1500.0);
            expect(holding.dividendReinvestment, true);
          },
        );
      });

      test('应该能够通过Cubit删除持仓', () async {
        // 添加多个持仓
        final holding1 = PortfolioHolding(
          fundCode: '000009',
          fundName: '汇添富价值精选混合',
          fundType: '混合型',
          holdingAmount: 800.0,
          costNav: 2.1000,
          costValue: 1680.0,
          marketValue: 1768.0,
          currentNav: 2.2100,
          accumulatedNav: 3.2000,
          holdingStartDate: DateTime.now().subtract(const Duration(days: 35)),
          lastUpdatedDate: DateTime.now(),
          dividendReinvestment: false,
          status: HoldingStatus.active,
        );

        final holding2 = PortfolioHolding(
          fundCode: '000010',
          fundName: '广发稳健增长混合',
          fundType: '混合型',
          holdingAmount: 600.0,
          costNav: 1.6000,
          costValue: 960.0,
          marketValue: 996.0,
          currentNav: 1.6600,
          accumulatedNav: 2.4000,
          holdingStartDate: DateTime.now().subtract(const Duration(days: 20)),
          lastUpdatedDate: DateTime.now(),
          dividendReinvestment: true,
          status: HoldingStatus.active,
        );

        await portfolioCubit.addDefaultUserHolding(holding1);
        await portfolioCubit.addDefaultUserHolding(holding2);

        // 通过Cubit删除持仓
        final success = await portfolioCubit.deleteDefaultUserHolding('000009');
        expect(success, isTrue);

        // 验证持仓已删除
        final readResult =
            await portfolioDataService.getUserHoldings(testUserId);
        expect(readResult.isRight(), isTrue);
        readResult.fold(
          (failure) => fail('读取持仓失败: ${failure.message}'),
          (holdings) {
            expect(holdings.length, 1);
            expect(holdings.first.fundCode, '000010');
          },
        );
      });

      test('应该能够获取持仓数量', () async {
        // 初始数量应该为0
        var count = await portfolioCubit.getDefaultUserHoldingsCount();
        expect(count, 0);

        // 添加持仓
        final holding = PortfolioHolding(
          fundCode: '000011',
          fundName: '交银施罗德精选混合',
          fundType: '混合型',
          holdingAmount: 700.0,
          costNav: 1.9000,
          costValue: 1330.0,
          marketValue: 1407.0,
          currentNav: 2.0100,
          accumulatedNav: 2.8000,
          holdingStartDate: DateTime.now().subtract(const Duration(days: 15)),
          lastUpdatedDate: DateTime.now(),
          dividendReinvestment: false,
          status: HoldingStatus.active,
        );

        await portfolioCubit.addDefaultUserHolding(holding);

        // 数量应该为1
        count = await portfolioCubit.getDefaultUserHoldingsCount();
        expect(count, 1);
      });
    });

    group('边界情况和错误处理测试', () {
      test('应该能够处理删除不存在的持仓', () async {
        final success = await portfolioCubit.deleteDefaultUserHolding('999999');
        expect(success, isFalse); // 应该返回false而不是抛出异常
      });

      test('应该能够处理空用户的持仓查询', () async {
        final readResult =
            await portfolioDataService.getUserHoldings('non_existent_user');
        expect(readResult.isRight(), isTrue);
        readResult.fold(
          (failure) => fail('不应该返回错误'),
          (holdings) => expect(holdings.isEmpty, isTrue),
        );
      });

      test('应该能够处理清空空用户的持仓', () async {
        final success = await portfolioCubit.clearDefaultUserHoldings();
        expect(success, isTrue); // 清空空持仓应该返回true
      });

      test('应该能够处理导入空持仓列表', () async {
        final success = await portfolioCubit.importDefaultUserHoldings([]);
        expect(success, isTrue);

        // 验证没有持仓
        final readResult =
            await portfolioDataService.getUserHoldings(testUserId);
        expect(readResult.isRight(), isTrue);
        readResult.fold(
          (failure) => fail('读取持仓失败: ${failure.message}'),
          (holdings) => expect(holdings.isEmpty, isTrue),
        );
      });

      test('应该能够处理大量持仓数据', () async {
        // 创建大量持仓数据
        final holdings = <PortfolioHolding>[];
        for (int i = 0; i < 50; i++) {
          holdings.add(PortfolioHolding(
            fundCode: 'TEST${i.toString().padLeft(6, '0')}',
            fundName: '测试基金$i',
            fundType: '混合型',
            holdingAmount: 1000.0 + i * 10,
            costNav: 1.0 + i * 0.01,
            costValue: (1000.0 + i * 10) * (1.0 + i * 0.01),
            marketValue: 0.0,
            currentNav: 1.0 + i * 0.01,
            accumulatedNav: 0.0,
            holdingStartDate: DateTime.now().subtract(Duration(days: 30 + i)),
            lastUpdatedDate: DateTime.now(),
            dividendReinvestment: i % 2 == 0,
            status: HoldingStatus.active,
          ));
        }

        // 导入大量持仓
        final success =
            await portfolioCubit.importDefaultUserHoldings(holdings);
        expect(success, isTrue);

        // 验证所有持仓都已导入
        final count = await portfolioCubit.getDefaultUserHoldingsCount();
        expect(count, 50);

        // 验证数据完整性
        final readResult =
            await portfolioDataService.getUserHoldings(testUserId);
        expect(readResult.isRight(), isTrue);
        readResult.fold(
          (failure) => fail('读取持仓失败: ${failure.message}'),
          (holdings) {
            expect(holdings.length, 50);
            // 验证第一个和最后一个持仓
            expect(holdings.first.fundCode, 'TEST000000');
            expect(holdings.last.fundCode, 'TEST000049');
            expect(holdings.first.holdingAmount, 1000.0);
            expect(holdings.last.holdingAmount, 1490.0);
          },
        );
      });
    });
  });
}
