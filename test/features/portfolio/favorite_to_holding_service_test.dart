import 'package:flutter_test/flutter_test.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/fund_favorite/src/entities/fund_favorite.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/entities/portfolio_holding.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/services/favorite_to_holding_service.dart';

void main() {
  group('FavoriteToHoldingService Tests', () {
    late FavoriteToHoldingService service;
    late FundFavorite testFavorite;

    setUp(() {
      service = FavoriteToHoldingService();
      testFavorite = FundFavorite(
        fundCode: '000001',
        fundName: '华夏成长混合',
        fundType: '混合型',
        fundManager: '华夏基金',
        addedAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
        currentNav: 2.3456,
        dailyChange: 1.23,
        previousNav: 2.3171,
      );
    });

    group('convertFavoriteToHolding', () {
      test('应该正确转换自选基金为持仓数据', () {
        // Act
        final holding = service.convertFavoriteToHolding(testFavorite);

        // Assert
        expect(holding.fundCode, equals('000001'));
        expect(holding.fundName, equals('华夏成长混合'));
        expect(holding.fundType, equals('混合型'));
        expect(holding.holdingAmount, equals(1000.0)); // 默认值
        expect(holding.costNav, equals(2.3456)); // 使用当前净值
        expect(holding.costValue, equals(2345.60)); // 1000 * 2.3456
        expect(holding.marketValue, equals(2345.60)); // 1000 * 2.3456
        expect(holding.currentNav, equals(2.3456));
        expect(holding.status, equals(HoldingStatus.active));
      });

      test('应该使用自定义持有份额', () {
        // Arrange
        const customAmount = 2000.0;

        // Act
        final holding = service.convertFavoriteToHolding(
          testFavorite,
          defaultAmount: customAmount,
        );

        // Assert
        expect(holding.holdingAmount, equals(customAmount));
        expect(holding.costValue, equals(4691.20)); // 2000 * 2.3456
        expect(holding.marketValue, equals(4691.20));
      });

      test('应该处理没有净值数据的情况', () {
        // Arrange
        final favoriteWithoutNav = FundFavorite(
          fundCode: '000002',
          fundName: '测试基金无净值',
          fundType: '股票型',
          fundManager: '测试公司',
          addedAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now(),
          currentNav: null, // 明确设为null
          dailyChange: null,
          previousNav: null,
        );

        // Act
        final holding = service.convertFavoriteToHolding(favoriteWithoutNav);

        // Assert
        expect(holding.currentNav, equals(0.0));
        expect(holding.costNav, equals(1.0)); // 默认成本净值
        expect(holding.costValue, equals(1000.0)); // 1000 * 1.0
        expect(holding.marketValue, equals(1000.0)); // 使用默认成本净值
      });

      test('应该不使用当前净值作为成本', () {
        // Act
        final holding = service.convertFavoriteToHolding(
          testFavorite,
          estimateCost: false,
        );

        // Assert
        expect(holding.costNav, equals(1.0)); // 默认成本净值
        expect(holding.costValue, equals(1000.0)); // 1000 * 1.0
        expect(holding.marketValue, equals(2345.60)); // 仍使用当前净值
      });
    });

    group('batchConvertFavorites', () {
      test('应该批量转换所有自选基金', () {
        // Arrange
        final favorites = [
          testFavorite,
          FundFavorite(
            fundCode: '000002',
            fundName: '易方达平稳增长',
            fundType: '债券型',
            fundManager: '易方达基金',
            addedAt: DateTime.now().subtract(const Duration(days: 20)),
            updatedAt: DateTime.now(),
            currentNav: 1.1234,
            dailyChange: 0.15,
            previousNav: 1.1217,
          ),
        ];

        // Act
        final holdings = service.batchConvertFavorites(favorites);

        // Assert
        expect(holdings.length, equals(2));
        expect(holdings[0].fundCode, equals('000001'));
        expect(holdings[1].fundCode, equals('000002'));
      });

      test('应该只转换选中的基金', () {
        // Arrange
        final favorites = [
          testFavorite,
          FundFavorite(
            fundCode: '000003',
            fundName: '嘉实沪深300',
            fundType: '指数型',
            fundManager: '嘉实基金',
            addedAt: DateTime.now().subtract(const Duration(days: 10)),
            updatedAt: DateTime.now(),
            currentNav: 1.5678,
            dailyChange: -0.5,
            previousNav: 1.5756,
          ),
        ];
        final selectedCodes = ['000001'];

        // Act
        final holdings = service.batchConvertFavorites(
          favorites,
          selectedCodes: selectedCodes,
        );

        // Assert
        expect(holdings.length, equals(1));
        expect(holdings[0].fundCode, equals('000001'));
      });

      test('应该处理空列表', () {
        // Act
        final holdings = service.batchConvertFavorites([]);

        // Assert
        expect(holdings.isEmpty, isTrue);
      });

      test('应该处理没有匹配的选中代码', () {
        // Arrange
        final favorites = [testFavorite];
        final selectedCodes = ['999999']; // 不存在的代码

        // Act
        final holdings = service.batchConvertFavorites(
          favorites,
          selectedCodes: selectedCodes,
        );

        // Assert
        expect(holdings.isEmpty, isTrue);
      });
    });

    group('estimateSuggestedAmount', () {
      test('应该为不同基金类型提供建议份额', () {
        // Arrange & Act & Assert
        // 货币型基金
        final moneyFund =
            testFavorite.copyWith(fundType: '货币型', currentNav: 1.0);
        expect(service.estimateSuggestedAmount(moneyFund), equals(10000.0));

        // 债券型基金
        final bondFund =
            testFavorite.copyWith(fundType: '债券型', currentNav: 1.2);
        expect(service.estimateSuggestedAmount(bondFund),
            closeTo(4166.67, 0.01)); // 5000 / 1.2

        // 股票型基金
        final stockFund =
            testFavorite.copyWith(fundType: '股票型', currentNav: 3.5);
        expect(service.estimateSuggestedAmount(stockFund),
            closeTo(857.14, 0.01)); // 3000 / 3.5

        // 混合型基金
        final mixedFund =
            testFavorite.copyWith(fundType: '混合型', currentNav: 2.1);
        expect(service.estimateSuggestedAmount(mixedFund),
            closeTo(1428.57, 0.01)); // 3000 / 2.1

        // 指数型基金
        final indexFund =
            testFavorite.copyWith(fundType: '指数型', currentNav: 1.8);
        expect(service.estimateSuggestedAmount(indexFund),
            closeTo(1111.11, 0.01)); // 2000 / 1.8
      });

      test('应该处理没有净值数据的情况', () {
        // Arrange
        final favoriteWithoutNav = FundFavorite(
          fundCode: '000003',
          fundName: '测试基金无净值2',
          fundType: '股票型',
          fundManager: '测试公司',
          addedAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now(),
          currentNav: null, // 明确设为null
          dailyChange: null,
          previousNav: null,
        );

        // Act
        final amount = service.estimateSuggestedAmount(favoriteWithoutNav);

        // Assert
        expect(amount, equals(1000.0)); // 默认值
      });

      test('应该处理零净值或负净值的情况', () {
        // Arrange
        final favoriteWithZeroNav = testFavorite.copyWith(currentNav: 0.0);

        // Act
        final amount = service.estimateSuggestedAmount(favoriteWithZeroNav);

        // Assert
        expect(amount, equals(1000.0)); // 默认值
      });
    });

    group('validateHolding', () {
      test('应该验证有效的持仓数据', () {
        // Arrange
        final validHolding = service.convertFavoriteToHolding(testFavorite);

        // Act
        final result = service.validateHolding(validHolding);

        // Assert
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('应该检测无效的基金代码', () {
        // Arrange
        final invalidHolding = service
            .convertFavoriteToHolding(testFavorite)
            .copyWith(fundCode: '');

        // Act
        final result = service.validateHolding(invalidHolding);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.errors, contains('基金代码不能为空'));
      });

      test('应该检测无效的持有份额', () {
        // Arrange
        final invalidHolding = service
            .convertFavoriteToHolding(testFavorite)
            .copyWith(holdingAmount: 0.0);

        // Act
        final result = service.validateHolding(invalidHolding);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.errors, contains('持有份额必须大于0'));
      });

      test('应该检测无效的成本净值', () {
        // Arrange
        final invalidHolding = service
            .convertFavoriteToHolding(testFavorite)
            .copyWith(costNav: -1.0);

        // Act
        final result = service.validateHolding(invalidHolding);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.errors, contains('成本净值必须大于0'));
      });

      test('应该检测负的当前净值', () {
        // Arrange
        final invalidHolding = service
            .convertFavoriteToHolding(testFavorite)
            .copyWith(currentNav: -1.0);

        // Act
        final result = service.validateHolding(invalidHolding);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.errors, contains('当前净值不能为负数'));
      });

      test('应该检测日期逻辑错误', () {
        // Arrange
        final pastDate = DateTime.now().subtract(const Duration(days: 1));
        final futureDate = DateTime.now().add(const Duration(days: 1));
        final invalidHolding =
            service.convertFavoriteToHolding(testFavorite).copyWith(
                  holdingStartDate: futureDate,
                  lastUpdatedDate: pastDate,
                );

        // Act
        final result = service.validateHolding(invalidHolding);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.errors, contains('更新日期不能早于持有开始日期'));
      });
    });

    group('generateConversionSummary', () {
      test('应该生成正确的转换摘要', () {
        // Arrange
        final holdings = [
          service.convertFavoriteToHolding(testFavorite),
          service.convertFavoriteToHolding(
            testFavorite.copyWith(
              fundCode: '000002',
              fundType: '债券型',
            ),
          ),
        ];

        // Act
        final summary = service.generateConversionSummary(holdings);

        // Assert
        expect(summary, contains('基金数量: 2 只'));
        expect(summary, contains('总份额: 2000 份')); // 1000 + 1000
        expect(summary, contains('混合型: 1 只'));
        expect(summary, contains('债券型: 1 只'));
        expect(summary, contains('请确认以上信息无误后确认转换'));
      });

      test('应该处理空持仓列表', () {
        // Act
        final summary = service.generateConversionSummary([]);

        // Assert
        expect(summary, equals('没有需要转换的基金'));
      });
    });
  });
}
