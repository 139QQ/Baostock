import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:hive/hive.dart';

import 'package:jisu_fund_analyzer/src/services/unified_portfolio_service.dart';
import 'package:jisu_fund_analyzer/src/core/cache/interfaces/cache_service.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/entities/portfolio_holding.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/data/services/portfolio_profit_api_service.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/data/services/portfolio_profit_cache_service.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/services/portfolio_profit_calculation_engine.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/data/services/fund_favorite_service.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/entities/fund_corporate_action.dart';

import 'unified_portfolio_service_test.mocks.dart';

@GenerateMocks([
  CacheService,
  PortfolioProfitApiService,
  PortfolioProfitCacheService,
  PortfolioProfitCalculationEngine,
  FundFavoriteService,
  Box,
])
void main() {
  group('UnifiedPortfolioService - Story R.2 测试套件', () {
    late UnifiedPortfolioService service;
    late MockCacheService mockCacheService;
    late MockPortfolioProfitApiService mockProfitApiService;
    late MockPortfolioProfitCacheService mockProfitCacheService;
    late MockPortfolioProfitCalculationEngine mockCalculationEngine;
    late MockFundFavoriteService mockFavoriteService;
    late MockBox<Map> mockBox;

    setUp(() async {
      mockCacheService = MockCacheService();
      mockProfitApiService = MockPortfolioProfitApiService();
      mockProfitCacheService = MockPortfolioProfitCacheService();
      mockCalculationEngine = MockPortfolioProfitCalculationEngine();
      mockFavoriteService = MockFundFavoriteService();
      mockBox = MockBox<Map>();

      service = UnifiedPortfolioService(
        cacheService: mockCacheService,
        profitApiService: mockProfitApiService,
        profitCacheService: mockProfitCacheService,
        calculationEngine: mockCalculationEngine,
        favoriteService: mockFavoriteService,
      );

      // 设置默认的mock行为
      when(mockCacheService.get(any, any)).thenAnswer((_) async => null);
      when(mockCacheService.set(any, any, any)).thenAnswer((_) async => true);
      when(mockBox.values).thenReturn([]);
      when(mockBox.clear()).thenAnswer((_) async => 0);
      when(mockBox.put(any, any)).thenAnswer((_) async => 0);
      when(mockBox.delete(any)).thenAnswer((_) async => 0);
    });

    group('投资组合持仓管理测试', () {
      test('应该成功获取用户持仓', () async {
        final mockHoldings = [
          PortfolioHolding(
            userId: 'test-user',
            fundCode: '000001',
            fundName: '华夏成长混合',
            shares: 1000.0,
            averageCost: 1.2345,
            currentPrice: 1.3456,
            marketValue: 1345.60,
            totalCost: 1234.50,
            profit: 111.10,
            profitRate: 0.09,
            purchaseDate: DateTime(2024, 1, 1),
            lastUpdated: DateTime.now(),
          ),
        ];

        when(mockProfitApiService.getUserHoldings(any))
            .thenAnswer((_) async => Right(mockHoldings));

        final result = await service.getUserHoldings('test-user');

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected success but got failure'),
          (holdings) {
            expect(holdings.length, equals(1));
            expect(holdings.first.fundCode, equals('000001'));
            expect(holdings.first.shares, equals(1000.0));
          },
        );
        verify(mockProfitApiService.getUserHoldings('test-user')).called(1);
      });

      test('应该处理获取持仓失败的情况', () async {
        final failure = NetworkFailure('API error');
        when(mockProfitApiService.getUserHoldings(any))
            .thenAnswer((_) async => Left(failure));

        final result = await service.getUserHoldings('test-user');

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, equals(failure)),
          (holdings) => fail('Expected failure but got success'),
        );
      });

      test('应该添加新的持仓', () async {
        final newHolding = PortfolioHolding(
          userId: 'test-user',
          fundCode: '000002',
          fundName: '嘉实沪深300',
          shares: 500.0,
          averageCost: 2.3456,
          currentPrice: 2.4567,
          marketValue: 1228.35,
          totalCost: 1172.80,
          profit: 55.55,
          profitRate: 0.047,
          purchaseDate: DateTime(2024, 1, 15),
          lastUpdated: DateTime.now(),
        );

        when(mockBox.put(any, any)).thenAnswer((_) async => 0);

        final result = await service.addHolding(newHolding);

        expect(result, isTrue);
        verify(mockBox.put(any, any)).called(1);
      });

      test('应该更新现有持仓', () async {
        final existingHolding = PortfolioHolding(
          userId: 'test-user',
          fundCode: '000001',
          fundName: '华夏成长混合',
          shares: 1500.0, // 增加持仓数量
          averageCost: 1.2345,
          currentPrice: 1.3456,
          marketValue: 2018.40,
          totalCost: 1851.75,
          profit: 166.65,
          profitRate: 0.09,
          purchaseDate: DateTime(2024, 1, 1),
          lastUpdated: DateTime.now(),
        );

        when(mockBox.put(any, any)).thenAnswer((_) async => 0);

        final result = await service.updateHolding(existingHolding);

        expect(result, isTrue);
        verify(mockBox.put(any, any)).called(1);
      });

      test('应该删除持仓', () async {
        final fundCode = '000001';
        final userId = 'test-user';

        when(mockBox.delete(any)).thenAnswer((_) async => 0);

        final result = await service.removeHolding(userId, fundCode);

        expect(result, isTrue);
        verify(mockBox.delete(any)).called(1);
      });

      test('应该清空用户所有持仓', () async {
        final userId = 'test-user';

        when(mockBox.clear()).thenAnswer((_) async => 3);

        final result = await service.clearAllHoldings(userId);

        expect(result, equals(3));
        verify(mockBox.clear()).called(1);
      });
    });

    group('收益计算测试', () {
      test('应该正确计算总收益', () async {
        final mockHoldings = [
          PortfolioHolding(
            userId: 'test-user',
            fundCode: '000001',
            fundName: '华夏成长混合',
            shares: 1000.0,
            averageCost: 1.2345,
            currentPrice: 1.3456,
            marketValue: 1345.60,
            totalCost: 1234.50,
            profit: 111.10,
            profitRate: 0.09,
            purchaseDate: DateTime(2024, 1, 1),
            lastUpdated: DateTime.now(),
          ),
          PortfolioHolding(
            userId: 'test-user',
            fundCode: '000002',
            fundName: '嘉实沪深300',
            shares: 500.0,
            averageCost: 2.3456,
            currentPrice: 2.4567,
            marketValue: 1228.35,
            totalCost: 1172.80,
            profit: 55.55,
            profitRate: 0.047,
            purchaseDate: DateTime(2024, 1, 15),
            lastUpdated: DateTime.now(),
          ),
        ];

        when(mockProfitApiService.getUserHoldings(any))
            .thenAnswer((_) async => Right(mockHoldings));

        final result = await service.calculateTotalProfit('test-user');

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected success but got failure'),
          (totalProfit) {
            expect(totalProfit, equals(166.65)); // 111.10 + 55.55
          },
        );
      });

      test('应该正确计算总收益率', () async {
        final mockHoldings = [
          PortfolioHolding(
            userId: 'test-user',
            fundCode: '000001',
            fundName: '华夏成长混合',
            shares: 1000.0,
            averageCost: 1.2345,
            currentPrice: 1.3456,
            marketValue: 1345.60,
            totalCost: 1234.50,
            profit: 111.10,
            profitRate: 0.09,
            purchaseDate: DateTime(2024, 1, 1),
            lastUpdated: DateTime.now(),
          ),
        ];

        when(mockProfitApiService.getUserHoldings(any))
            .thenAnswer((_) async => Right(mockHoldings));

        final result = await service.calculateTotalProfitRate('test-user');

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected success but got failure'),
          (profitRate) {
            expect(profitRate, closeTo(0.09, 0.001));
          },
        );
      });

      test('应该处理收益计算失败的情况', () async {
        final failure = NetworkFailure('Calculation error');
        when(mockProfitApiService.getUserHoldings(any))
            .thenAnswer((_) async => Left(failure));

        final result = await service.calculateTotalProfit('test-user');

        expect(result.isLeft(), isTrue);
      });
    });

    group('投资组合分析测试', () {
      test('应该生成投资组合分析报告', () async {
        final mockHoldings = [
          PortfolioHolding(
            userId: 'test-user',
            fundCode: '000001',
            fundName: '华夏成长混合',
            shares: 1000.0,
            averageCost: 1.2345,
            currentPrice: 1.3456,
            marketValue: 1345.60,
            totalCost: 1234.50,
            profit: 111.10,
            profitRate: 0.09,
            purchaseDate: DateTime(2024, 1, 1),
            lastUpdated: DateTime.now(),
          ),
        ];

        when(mockProfitApiService.getUserHoldings(any))
            .thenAnswer((_) async => Right(mockHoldings));

        final result = await service.generatePortfolioAnalysis('test-user');

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected success but got failure'),
          (analysis) {
            expect(analysis.totalHoldings, equals(1));
            expect(analysis.totalMarketValue, equals(1345.60));
            expect(analysis.totalCost, equals(1234.50));
            expect(analysis.totalProfit, equals(111.10));
            expect(analysis.totalProfitRate, closeTo(0.09, 0.001));
          },
        );
      });

      test('应该分析资产配置', () async {
        final mockHoldings = [
          PortfolioHolding(
            userId: 'test-user',
            fundCode: '000001',
            fundName: '华夏成长混合',
            shares: 1000.0,
            averageCost: 1.2345,
            currentPrice: 1.3456,
            marketValue: 1345.60,
            totalCost: 1234.50,
            profit: 111.10,
            profitRate: 0.09,
            purchaseDate: DateTime(2024, 1, 1),
            lastUpdated: DateTime.now(),
          ),
          PortfolioHolding(
            userId: 'test-user',
            fundCode: '000002',
            fundName: '嘉实沪深300',
            shares: 500.0,
            averageCost: 2.3456,
            currentPrice: 2.4567,
            marketValue: 1228.35,
            totalCost: 1172.80,
            profit: 55.55,
            profitRate: 0.047,
            purchaseDate: DateTime(2024, 1, 15),
            lastUpdated: DateTime.now(),
          ),
        ];

        when(mockProfitApiService.getUserHoldings(any))
            .thenAnswer((_) async => Right(mockHoldings));

        final result = await service.analyzeAssetAllocation('test-user');

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected success but got failure'),
          (allocation) {
            expect(allocation.totalAssets, equals(2));
            expect(allocation.totalValue, equals(2573.95));
            expect(allocation.allocations.length, equals(2));
          },
        );
      });
    });

    group('收藏功能集成测试', () {
      test('应该将持仓添加到收藏', () async {
        final fundCode = '000001';

        when(mockFavoriteService.addToFavorites(any))
            .thenAnswer((_) async => true);

        final result = await service.addToFavorites('test-user', fundCode);

        expect(result, isTrue);
        verify(mockFavoriteService.addToFavorites(fundCode)).called(1);
      });

      test('应该从收藏中移除持仓', () async {
        final fundCode = '000001';

        when(mockFavoriteService.removeFromFavorites(any))
            .thenAnswer((_) async => true);

        final result = await service.removeFromFavorites('test-user', fundCode);

        expect(result, isTrue);
        verify(mockFavoriteService.removeFromFavorites(fundCode)).called(1);
      });

      test('应该获取用户的收藏列表', () async {
        final mockFavorites = ['000001', '000002', '000003'];

        when(mockFavoriteService.getFavoriteList())
            .thenAnswer((_) async => mockFavorites);

        final result = await service.getFavoriteList('test-user');

        expect(result, equals(mockFavorites));
        verify(mockFavoriteService.getFavoriteList()).called(1);
      });
    });

    group('缓存管理测试', () {
      test('应该缓存持仓数据', () async {
        final mockHoldings = [
          PortfolioHolding(
            userId: 'test-user',
            fundCode: '000001',
            fundName: '华夏成长混合',
            shares: 1000.0,
            averageCost: 1.2345,
            currentPrice: 1.3456,
            marketValue: 1345.60,
            totalCost: 1234.50,
            profit: 111.10,
            profitRate: 0.09,
            purchaseDate: DateTime(2024, 1, 1),
            lastUpdated: DateTime.now(),
          ),
        ];

        when(mockCacheService.set(any, any, any)).thenAnswer((_) async => true);

        final result = await service.cacheHoldings('test-user', mockHoldings);

        expect(result, isTrue);
        verify(mockCacheService.set(any, any, any)).called(1);
      });

      test('应该从缓存获取持仓数据', () async {
        final cachedHoldings = [
          PortfolioHolding(
            userId: 'test-user',
            fundCode: '000001',
            fundName: '华夏成长混合',
            shares: 1000.0,
            averageCost: 1.2345,
            currentPrice: 1.3456,
            marketValue: 1345.60,
            totalCost: 1234.50,
            profit: 111.10,
            profitRate: 0.09,
            purchaseDate: DateTime(2024, 1, 1),
            lastUpdated: DateTime.now(),
          ),
        ];

        when(mockCacheService.get(any, any))
            .thenAnswer((_) async => cachedHoldings);

        final result = await service.getCachedHoldings('test-user');

        expect(result, isNotNull);
        expect(result!.length, equals(1));
        expect(result.first.fundCode, equals('000001'));
        verify(mockCacheService.get(any, any)).called(1);
      });

      test('应该清理缓存', () async {
        when(mockCacheService.clear(any)).thenAnswer((_) async => true);

        final result = await service.clearCache('test-user');

        expect(result, isTrue);
        verify(mockCacheService.clear(any)).called(1);
      });
    });

    group('性能测试', () {
      test('应该能处理大量持仓数据', () async {
        final largeHoldingsList = List.generate(
            1000,
            (index) => PortfolioHolding(
                  userId: 'test-user',
                  fundCode: '${(index + 1).toString().padLeft(6, '0')}',
                  fundName: '测试基金${index + 1}',
                  shares: (index + 1) * 100.0,
                  averageCost: 1.0 + (index * 0.001),
                  currentPrice: 1.1 + (index * 0.001),
                  marketValue: (index + 1) * 110.0,
                  totalCost: (index + 1) * 100.0,
                  profit: (index + 1) * 10.0,
                  profitRate: 0.1,
                  purchaseDate: DateTime(2024, 1, 1),
                  lastUpdated: DateTime.now(),
                ));

        when(mockProfitApiService.getUserHoldings(any))
            .thenAnswer((_) async => Right(largeHoldingsList));

        final stopwatch = Stopwatch()..start();
        final result = await service.calculateTotalProfit('test-user');
        stopwatch.stop();

        expect(result.isRight(), isTrue);
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // 应该在1秒内完成
      });

      test('应该支持并发操作', () async {
        final futures = [
          service.getUserHoldings('user1'),
          service.getUserHoldings('user2'),
          service.getUserHoldings('user3'),
        ];

        final mockHoldings = [
          PortfolioHolding(
            userId: 'test-user',
            fundCode: '000001',
            fundName: '华夏成长混合',
            shares: 1000.0,
            averageCost: 1.2345,
            currentPrice: 1.3456,
            marketValue: 1345.60,
            totalCost: 1234.50,
            profit: 111.10,
            profitRate: 0.09,
            purchaseDate: DateTime(2024, 1, 1),
            lastUpdated: DateTime.now(),
          ),
        ];

        when(mockProfitApiService.getUserHoldings(any))
            .thenAnswer((_) async => Right(mockHoldings));

        final results = await Future.wait(futures);

        expect(results.length, equals(3));
        for (final result in results) {
          expect(result.isRight(), isTrue);
        }
        verify(mockProfitApiService.getUserHoldings(any)).called(3);
      });
    });

    group('错误处理测试', () {
      test('应该处理网络错误', () async {
        final networkFailure = NetworkFailure('Network error');
        when(mockProfitApiService.getUserHoldings(any))
            .thenAnswer((_) async => Left(networkFailure));

        final result = await service.getUserHoldings('test-user');

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, equals(networkFailure)),
          (holdings) => fail('Expected failure but got success'),
        );
      });

      test('应该处理数据解析错误', () async {
        final parseFailure = DataParsingFailure('Invalid data format');
        when(mockProfitApiService.getUserHoldings(any))
            .thenAnswer((_) async => Left(parseFailure));

        final result = await service.getUserHoldings('test-user');

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, equals(parseFailure)),
          (holdings) => fail('Expected failure but got success'),
        );
      });

      test('应该处理缓存错误', () async {
        when(mockCacheService.get(any, any))
            .thenThrow(Exception('Cache error'));

        final result = await service.getCachedHoldings('test-user');

        expect(result, isNull);
      });
    });

    group('数据验证测试', () {
      test('应该验证持仓数据格式', () {
        final validHolding = PortfolioHolding(
          userId: 'test-user',
          fundCode: '000001',
          fundName: '华夏成长混合',
          shares: 1000.0,
          averageCost: 1.2345,
          currentPrice: 1.3456,
          marketValue: 1345.60,
          totalCost: 1234.50,
          profit: 111.10,
          profitRate: 0.09,
          purchaseDate: DateTime(2024, 1, 1),
          lastUpdated: DateTime.now(),
        );

        expect(service.validateHolding(validHolding), isTrue);
      });

      test('应该拒绝无效的持仓数据', () {
        final invalidHolding = PortfolioHolding(
          userId: '', // 无效的用户ID
          fundCode: '000001',
          fundName: '华夏成长混合',
          shares: -100.0, // 无效的份额数量
          averageCost: 1.2345,
          currentPrice: 1.3456,
          marketValue: 1345.60,
          totalCost: 1234.50,
          profit: 111.10,
          profitRate: 0.09,
          purchaseDate: DateTime(2024, 1, 1),
          lastUpdated: DateTime.now(),
        );

        expect(service.validateHolding(invalidHolding), isFalse);
      });
    });

    tearDown(() {
      // 清理资源
    });
  });
}
