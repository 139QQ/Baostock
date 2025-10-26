import 'package:flutter_test/flutter_test.dart';

import 'package:jisu_fund_analyzer/src/features/portfolio/domain/entities/portfolio_holding.dart';

void main() {
  group('PortfolioHolding Tests', () {
    final testHolding = PortfolioHolding(
      fundCode: '000001',
      fundName: '华夏成长混合',
      fundType: '混合型',
      holdingAmount: 1000.0,
      costNav: 1.2,
      costValue: 1200.0,
      marketValue: 1500.0,
      currentNav: 1.5,
      accumulatedNav: 1.8,
      holdingStartDate: DateTime.parse('2023-01-01T00:00:00.000Z'),
      lastUpdatedDate: DateTime.parse('2023-12-01T00:00:00.000Z'),
      status: HoldingStatus.active,
    );

    group('Constructor Tests', () {
      test('should create PortfolioHolding with required fields', () {
        // Act
        final holding = PortfolioHolding(
          fundCode: '000001',
          fundName: '华夏成长混合',
          fundType: '混合型',
          holdingAmount: 1000.0,
          costNav: 1.2,
          costValue: 1200.0,
          marketValue: 1500.0,
          currentNav: 1.5,
          accumulatedNav: 1.8,
          holdingStartDate: DateTime.parse('2023-01-01'),
          lastUpdatedDate: DateTime.parse('2023-12-01'),
        );

        // Assert
        expect(holding.fundCode, '000001');
        expect(holding.fundName, '华夏成长混合');
        expect(holding.fundType, '混合型');
        expect(holding.holdingAmount, 1000.0);
        expect(holding.costNav, 1.2);
        expect(holding.costValue, 1200.0);
        expect(holding.marketValue, 1500.0);
        expect(holding.currentNav, 1.5);
        expect(holding.accumulatedNav, 1.8);
        expect(holding.status, HoldingStatus.active);
        expect(holding.dividendReinvestment, isTrue); // 默认值
      });

      test('should create PortfolioHolding with all fields', () {
        // Act
        final holding = PortfolioHolding(
          fundCode: '000001',
          fundName: '华夏成长混合',
          fundType: '混合型',
          holdingAmount: 1000.0,
          costNav: 1.2,
          costValue: 1200.0,
          marketValue: 1500.0,
          currentNav: 1.5,
          accumulatedNav: 1.8,
          holdingStartDate: DateTime.parse('2023-01-01'),
          lastUpdatedDate: DateTime.parse('2023-12-01'),
          dividendReinvestment: false,
          status: HoldingStatus.sold,
          notes: '测试备注',
        );

        // Assert
        expect(holding.dividendReinvestment, isFalse);
        expect(holding.status, HoldingStatus.sold);
        expect(holding.notes, '测试备注');
      });
    });

    group('CopyWith Tests', () {
      test('should create copy with updated fields', () {
        // Act
        final updatedHolding = testHolding.copyWith(
          marketValue: 1600.0,
          currentNav: 1.6,
          notes: '更新备注',
        );

        // Assert
        expect(updatedHolding.fundCode, testHolding.fundCode); // 未更改
        expect(updatedHolding.fundName, testHolding.fundName); // 未更改
        expect(updatedHolding.marketValue, 1600.0); // 已更改
        expect(updatedHolding.currentNav, 1.6); // 已更改
        expect(updatedHolding.notes, '更新备注'); // 已更改
      });

      test('should create copy with null values', () {
        // Act
        final updatedHolding = testHolding.copyWith(notes: null);

        // Assert
        expect(updatedHolding.notes, isNull);
      });

      test('should handle all field updates', () {
        // Act
        final updatedHolding = testHolding.copyWith(
          fundCode: '110022',
          fundName: '易方达消费行业',
          fundType: '股票型',
          holdingAmount: 2000.0,
          costNav: 1.3,
          costValue: 2600.0,
          marketValue: 3200.0,
          currentNav: 1.6,
          accumulatedNav: 2.0,
          holdingStartDate: DateTime.parse('2023-02-01'),
          lastUpdatedDate: DateTime.parse('2023-12-02'),
          dividendReinvestment: false,
          status: HoldingStatus.sold,
          notes: '完全更新',
        );

        // Assert
        expect(updatedHolding.fundCode, '110022');
        expect(updatedHolding.fundName, '易方达消费行业');
        expect(updatedHolding.fundType, '股票型');
        expect(updatedHolding.holdingAmount, 2000.0);
        expect(updatedHolding.costNav, 1.3);
        expect(updatedHolding.costValue, 2600.0);
        expect(updatedHolding.marketValue, 3200.0);
        expect(updatedHolding.currentNav, 1.6);
        expect(updatedHolding.accumulatedNav, 2.0);
        expect(updatedHolding.holdingStartDate, DateTime.parse('2023-02-01'));
        expect(updatedHolding.lastUpdatedDate, DateTime.parse('2023-12-02'));
        expect(updatedHolding.dividendReinvestment, isFalse);
        expect(updatedHolding.status, HoldingStatus.sold);
        expect(updatedHolding.notes, '完全更新');
      });
    });

    group('Return Rate Calculations', () {
      test('should calculate current return rate correctly', () {
        // Arrange
        final holding = PortfolioHolding(
          fundCode: '000001',
          fundName: '测试基金',
          fundType: '混合型',
          holdingAmount: 1000.0,
          costNav: 1.0,
          costValue: 1000.0,
          marketValue: 1200.0,
          currentNav: 1.2,
          accumulatedNav: 1.5,
          holdingStartDate: DateTime.parse('2023-01-01'),
          lastUpdatedDate: DateTime.parse('2023-12-01'),
        );

        // Act & Assert
        expect(holding.currentReturnRate,
            closeTo(0.2, 0.01)); // (1.2 - 1.0) / 1.0 = 0.2
      });

      test('should calculate current return rate for loss', () {
        // Arrange
        final holding = PortfolioHolding(
          fundCode: '000001',
          fundName: '测试基金',
          fundType: '混合型',
          holdingAmount: 1000.0,
          costNav: 1.5,
          costValue: 1500.0,
          marketValue: 1200.0,
          currentNav: 1.2,
          accumulatedNav: 1.3,
          holdingStartDate: DateTime.parse('2023-01-01'),
          lastUpdatedDate: DateTime.parse('2023-12-01'),
        );

        // Act & Assert
        expect(holding.currentReturnRate, -0.2); // (1.2 - 1.5) / 1.5 = -0.2
      });

      test('should handle zero cost nav', () {
        // Arrange
        final holding = PortfolioHolding(
          fundCode: '000001',
          fundName: '测试基金',
          fundType: '混合型',
          holdingAmount: 1000.0,
          costNav: 0.0, // 异常情况
          costValue: 0.0,
          marketValue: 1200.0,
          currentNav: 1.2,
          accumulatedNav: 1.5,
          holdingStartDate: DateTime.parse('2023-01-01'),
          lastUpdatedDate: DateTime.parse('2023-12-01'),
        );

        // Act & Assert
        expect(holding.currentReturnRate, 0.0); // 避免除零错误
      });

      test('should calculate accumulated return rate correctly', () {
        // Arrange
        final holding = PortfolioHolding(
          fundCode: '000001',
          fundName: '测试基金',
          fundType: '混合型',
          holdingAmount: 1000.0,
          costNav: 1.0,
          costValue: 1000.0,
          marketValue: 1500.0,
          currentNav: 1.5,
          accumulatedNav: 2.0,
          holdingStartDate: DateTime.parse('2023-01-01'),
          lastUpdatedDate: DateTime.parse('2023-12-01'),
        );

        // Act & Assert
        expect(holding.accumulatedReturnRate, 1.0); // (2.0 - 1.0) / 1.0 = 1.0
      });
    });

    group('Return Amount Calculations', () {
      test('should calculate current return amount correctly', () {
        // Act & Assert
        expect(testHolding.currentReturnAmount, 300.0); // 1500.0 - 1200.0
      });

      test('should calculate current return percentage correctly', () {
        // Act & Assert
        expect(testHolding.currentReturnPercentage,
            25.0); // (1.5 - 1.2) / 1.2 * 100 = 25%
      });

      test('should calculate accumulated return amount correctly', () {
        // Act & Assert
        expect(testHolding.accumulatedReturnAmount,
            closeTo(600.0, 0.01)); // 1000.0 * (1.8 - 1.2) = 600.0
      });

      test('should calculate accumulated return percentage correctly', () {
        // Act & Assert
        expect(testHolding.accumulatedReturnPercentage,
            closeTo(50.0, 0.01)); // (1.8 - 1.2) / 1.2 * 100 = 50%
      });
    });

    group('Weight Calculation', () {
      test('should calculate holding weight correctly', () {
        // Arrange
        final totalMarketValue = 5000.0;

        // Act
        final weight = testHolding.calculateWeight(totalMarketValue);

        // Assert
        expect(weight, 0.3); // 1500.0 / 5000.0 = 0.3
      });

      test('should handle zero total market value', () {
        // Arrange
        final totalMarketValue = 0.0;

        // Act
        final weight = testHolding.calculateWeight(totalMarketValue);

        // Assert
        expect(weight, 0.0); // 避免除零错误
      });

      test('should calculate weight for entire portfolio', () {
        // Arrange
        final totalMarketValue = 1500.0; // 与持仓市值相同

        // Act
        final weight = testHolding.calculateWeight(totalMarketValue);

        // Assert
        expect(weight, 1.0); // 1500.0 / 1500.0 = 1.0
      });
    });

    group('Holding Days Calculation', () {
      test('should calculate holding days correctly', () {
        // Act & Assert
        expect(testHolding.holdingDays, 334); // 2023年1月1日到2023年12月1日大约334天
      });

      test('should calculate holding days for recent holding', () {
        // Arrange
        final recentHolding = PortfolioHolding(
          fundCode: '000001',
          fundName: '测试基金',
          fundType: '混合型',
          holdingAmount: 1000.0,
          costNav: 1.0,
          costValue: 1000.0,
          marketValue: 1000.0,
          currentNav: 1.0,
          accumulatedNav: 1.0,
          holdingStartDate: DateTime.now().subtract(const Duration(days: 5)),
          lastUpdatedDate: DateTime.now(),
        );

        // Act & Assert
        expect(recentHolding.holdingDays, 5);
      });
    });

    group('Status Properties', () {
      test('should identify profitable holding correctly', () {
        // Act & Assert
        expect(testHolding.isProfitable, isTrue); // 市值 > 成本
      });

      test('should identify loss holding correctly', () {
        // Arrange
        final lossHolding = PortfolioHolding(
          fundCode: '000001',
          fundName: '测试基金',
          fundType: '混合型',
          holdingAmount: 1000.0,
          costNav: 1.5,
          costValue: 1500.0,
          marketValue: 1200.0, // 亏损
          currentNav: 1.2,
          accumulatedNav: 1.3,
          holdingStartDate: DateTime.parse('2023-01-01'),
          lastUpdatedDate: DateTime.parse('2023-12-01'),
        );

        // Act & Assert
        expect(lossHolding.isLoss, isTrue);
        expect(lossHolding.isProfitable, isFalse);
      });

      test('should identify breakeven holding correctly', () {
        // Arrange
        final breakevenHolding = PortfolioHolding(
          fundCode: '000001',
          fundName: '测试基金',
          fundType: '混合型',
          holdingAmount: 1000.0,
          costNav: 1.2,
          costValue: 1200.0,
          marketValue: 1200.0, // 盈亏平衡
          currentNav: 1.2,
          accumulatedNav: 1.2,
          holdingStartDate: DateTime.parse('2023-01-01'),
          lastUpdatedDate: DateTime.parse('2023-12-01'),
        );

        // Act & Assert
        expect(breakevenHolding.isProfitable, isFalse);
        expect(breakevenHolding.isLoss, isFalse);
      });

      test('should identify long term holding correctly', () {
        // Arrange
        final longTermHolding = PortfolioHolding(
          fundCode: '000001',
          fundName: '测试基金',
          fundType: '混合型',
          holdingAmount: 1000.0,
          costNav: 1.0,
          costValue: 1000.0,
          marketValue: 1000.0,
          currentNav: 1.0,
          accumulatedNav: 1.0,
          holdingStartDate:
              DateTime.now().subtract(const Duration(days: 400)), // 超过1年
          lastUpdatedDate: DateTime.now(),
        );

        // Act & Assert
        expect(longTermHolding.isLongTerm, isTrue);
      });

      test('should identify short term holding correctly', () {
        // Act & Assert - testHolding 持有334天，不足1年
        expect(testHolding.isLongTerm, isFalse);
      });
    });

    group('Description Properties', () {
      test('should generate return description correctly for profit', () {
        // Arrange
        final profitHolding = PortfolioHolding(
          fundCode: '000001',
          fundName: '测试基金',
          fundType: '混合型',
          holdingAmount: 1000.0,
          costNav: 1.0,
          costValue: 1000.0,
          marketValue: 1200.0,
          currentNav: 1.2,
          accumulatedNav: 1.2,
          holdingStartDate: DateTime.parse('2023-01-01'),
          lastUpdatedDate: DateTime.parse('2023-12-01'),
        );

        // Act & Assert
        expect(profitHolding.returnDescription, '+20.00%');
      });

      test('should generate return description correctly for loss', () {
        // Arrange
        final lossHolding = PortfolioHolding(
          fundCode: '000001',
          fundName: '测试基金',
          fundType: '混合型',
          holdingAmount: 1000.0,
          costNav: 1.5,
          costValue: 1500.0,
          marketValue: 1200.0,
          currentNav: 1.2,
          accumulatedNav: 1.2,
          holdingStartDate: DateTime.parse('2023-01-01'),
          lastUpdatedDate: DateTime.parse('2023-12-01'),
        );

        // Act & Assert
        expect(lossHolding.returnDescription, '-20.00%');
      });

      test('should generate amount description correctly for profit', () {
        // Act & Assert
        expect(testHolding.amountDescription, '+¥300.00');
      });

      test('should generate amount description correctly for loss', () {
        // Arrange
        final lossHolding = PortfolioHolding(
          fundCode: '000001',
          fundName: '测试基金',
          fundType: '混合型',
          holdingAmount: 1000.0,
          costNav: 1.5,
          costValue: 1500.0,
          marketValue: 1200.0,
          currentNav: 1.2,
          accumulatedNav: 1.2,
          holdingStartDate: DateTime.parse('2023-01-01'),
          lastUpdatedDate: DateTime.parse('2023-12-01'),
        );

        // Act & Assert
        expect(lossHolding.amountDescription, '-¥300.00');
      });
    });

    group('Validation Tests', () {
      test('should validate correct holding data', () {
        // Act & Assert
        expect(testHolding.isValid(), isTrue);
      });

      test('should invalidate holding with empty fund code', () {
        // Arrange
        final invalidHolding = testHolding.copyWith(fundCode: '');

        // Act & Assert
        expect(invalidHolding.isValid(), isFalse);
      });

      test('should invalidate holding with empty fund name', () {
        // Arrange
        final invalidHolding = testHolding.copyWith(fundName: '');

        // Act & Assert
        expect(invalidHolding.isValid(), isFalse);
      });

      test('should invalidate holding with zero holding amount', () {
        // Arrange
        final invalidHolding = testHolding.copyWith(holdingAmount: 0.0);

        // Act & Assert
        expect(invalidHolding.isValid(), isFalse);
      });

      test('should invalidate holding with negative cost nav', () {
        // Arrange
        final invalidHolding = testHolding.copyWith(costNav: -1.0);

        // Act & Assert
        expect(invalidHolding.isValid(), isFalse);
      });

      test('should invalidate holding with negative market value', () {
        // Arrange
        final invalidHolding = testHolding.copyWith(marketValue: -100.0);

        // Act & Assert
        expect(invalidHolding.isValid(), isFalse);
      });
    });

    group('JSON Serialization Tests', () {
      test('should serialize to JSON correctly', () {
        // Act
        final json = testHolding.toJson();

        // Assert
        expect(json['fundCode'], '000001');
        expect(json['fundName'], '华夏成长混合');
        expect(json['fundType'], '混合型');
        expect(json['holdingAmount'], 1000.0);
        expect(json['costNav'], 1.2);
        expect(json['costValue'], 1200.0);
        expect(json['marketValue'], 1500.0);
        expect(json['currentNav'], 1.5);
        expect(json['accumulatedNav'], 1.8);
        expect(json['status'], 'active');
      });

      test('should deserialize from JSON correctly', () {
        // Arrange
        final json = {
          'fundCode': '110022',
          'fundName': '易方达消费行业',
          'fundType': '股票型',
          'holdingAmount': 2000.0,
          'costNav': 1.3,
          'costValue': 2600.0,
          'marketValue': 3200.0,
          'currentNav': 1.6,
          'accumulatedNav': 2.0,
          'holdingStartDate': '2023-02-01T00:00:00.000Z',
          'lastUpdatedDate': '2023-12-02T00:00:00.000Z',
          'dividendReinvestment': false,
          'status': 'active',
        };

        // Act
        final holding = PortfolioHolding.fromJson(json);

        // Assert
        expect(holding.fundCode, '110022');
        expect(holding.fundName, '易方达消费行业');
        expect(holding.fundType, '股票型');
        expect(holding.holdingAmount, 2000.0);
        expect(holding.costNav, 1.3);
        expect(holding.costValue, 2600.0);
        expect(holding.marketValue, 3200.0);
        expect(holding.currentNav, 1.6);
        expect(holding.accumulatedNav, 2.0);
        expect(holding.dividendReinvestment, isFalse);
        expect(holding.status, HoldingStatus.active);
      });
    });

    group('Equality Tests', () {
      test('should be equal when all properties match', () {
        // Arrange
        final holding1 = testHolding;
        final holding2 = PortfolioHolding(
          fundCode: '000001',
          fundName: '华夏成长混合',
          fundType: '混合型',
          holdingAmount: 1000.0,
          costNav: 1.2,
          costValue: 1200.0,
          marketValue: 1500.0,
          currentNav: 1.5,
          accumulatedNav: 1.8,
          holdingStartDate: DateTime.parse('2023-01-01'),
          lastUpdatedDate: DateTime.parse('2023-12-01'),
          status: HoldingStatus.active,
        );

        // Act & Assert
        expect(holding1, equals(holding2));
        expect(holding1.hashCode, equals(holding2.hashCode));
      });

      test('should not be equal when properties differ', () {
        // Arrange
        final holding1 = testHolding;
        final holding2 = testHolding.copyWith(marketValue: 1600.0);

        // Act & Assert
        expect(holding1, isNot(equals(holding2)));
      });
    });

    group('ToString Tests', () {
      test('should generate meaningful string representation', () {
        // Act
        final result = testHolding.toString();

        // Assert
        expect(result, contains('000001'));
        expect(result, contains('华夏成长混合'));
        expect(result, contains('currentReturn'));
      });
    });
  });

  group('HoldingStatus Tests', () {
    test('should have correct enum values', () {
      expect('active', 'active');
      expect('sold', 'sold');
      expect('suspended', 'suspended');
      expect('liquidated', 'liquidated');
    });
  });

  group('HoldingOperation Tests', () {
    test('should have correct operation types', () {
      expect(HoldingOperation.buy, isA<HoldingOperation>());
      expect(HoldingOperation.sell, isA<HoldingOperation>());
      expect(HoldingOperation.add, isA<HoldingOperation>());
      expect(HoldingOperation.reduce, isA<HoldingOperation>());
      expect(HoldingOperation.transfer, isA<HoldingOperation>());
    });
  });

  group('HoldingTransaction Tests', () {
    test('should create transaction with required fields', () {
      // Arrange
      final transaction = HoldingTransaction(
        transactionId: 'tx_001',
        fundCode: '000001',
        operation: HoldingOperation.buy,
        amount: 1000.0,
        nav: 1.2,
        value: 1200.0,
        transactionDate: DateTime.parse('2023-12-01T00:00:00.000Z'),
      );

      // Assert
      expect(transaction.transactionId, 'tx_001');
      expect(transaction.fundCode, '000001');
      expect(transaction.operation, HoldingOperation.buy);
      expect(transaction.amount, 1000.0);
      expect(transaction.nav, 1.2);
      expect(transaction.value, 1200.0);
      expect(transaction.fee, 0.0); // 默认值
      expect(transaction.notes, isNull); // 默认值
    });

    test('should create transaction with all fields', () {
      // Arrange
      final transaction = HoldingTransaction(
        transactionId: 'tx_002',
        fundCode: '110022',
        operation: HoldingOperation.sell,
        amount: 500.0,
        nav: 1.5,
        value: 750.0,
        transactionDate: DateTime.parse('2023-12-02T00:00:00.000Z'),
        fee: 5.0,
        notes: '卖出操作',
      );

      // Assert
      expect(transaction.fee, 5.0);
      expect(transaction.notes, '卖出操作');
    });

    test('should generate meaningful string representation', () {
      // Arrange
      final transaction = HoldingTransaction(
        transactionId: 'tx_001',
        fundCode: '000001',
        operation: HoldingOperation.buy,
        amount: 1000.0,
        nav: 1.2,
        value: 1200.0,
        transactionDate: DateTime.parse('2023-12-01T00:00:00.000Z'),
      );

      // Act
      final result = transaction.toString();

      // Assert
      expect(result, contains('000001'));
      expect(result, contains('buy'));
      expect(result, contains('¥1200.0'));
    });
  });
}
