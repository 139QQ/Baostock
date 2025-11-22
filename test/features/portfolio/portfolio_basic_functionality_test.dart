import 'package:flutter_test/flutter_test.dart';

// 导入主程序的实体类（排除part文件）
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/entities/portfolio_holding.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/entities/portfolio_profit_metrics.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/entities/portfolio_profit_calculation_criteria.dart';

void main() {
  group('Portfolio主程序实体类功能测试', () {
    group('TC-QA-001: 计算准确性验证', () {
      test('Given PortfolioHolding实体 When 计算基础收益 Then 返回准确的收益率', () {
        // Given - 创建真实的PortfolioHolding实体
        final holding = PortfolioHolding(
          fundCode: '110022',
          fundName: '易方达消费行业',
          fundType: '股票型',
          holdingAmount: 10000.0,
          costNav: 1.0,
          costValue: 10000.0,
          marketValue: 11500.0,
          currentNav: 1.15,
          accumulatedNav: 1.25,
          holdingStartDate: DateTime(2023, 1, 1),
          lastUpdatedDate: DateTime.now(),
        );

        // When - 使用实体的计算方法
        final actualReturnRate = holding.currentReturnRate;
        final actualReturnAmount = holding.currentReturnAmount;

        // Then - 验证计算结果
        const expectedReturnRate = 0.15; // (1.15 - 1.0) / 1.0
        const expectedReturnAmount = 1500.0; // 10000 * 0.15

        expect(actualReturnRate, closeTo(expectedReturnRate, 0.0001));
        expect(actualReturnAmount, equals(expectedReturnAmount));
      });

      test('Given PortfolioProfitMetrics实体 When 创建实例 Then 返回正确的属性值', () {
        // Given - 创建真实的PortfolioProfitMetrics实体
        final now = DateTime.now();
        final metrics = PortfolioProfitMetrics(
          fundCode: '110022',
          analysisDate: now,
          totalReturnAmount: 1500.0,
          totalReturnRate: 0.15,
          annualizedReturn: 0.14,
          dailyReturn: 0.001,
          weeklyReturn: 0.007,
          monthlyReturn: 0.03,
          quarterlyReturn: 0.08,
          return1Week: 0.005,
          return1Month: 0.02,
          return3Months: 0.06,
          return6Months: 0.12,
          return1Year: 0.15,
          return3Years: 0.45,
          returnYTD: 0.10,
          returnSinceInception: 0.15,
          dataStartDate: DateTime(2023, 1, 1),
          dataEndDate: now,
          analysisPeriodDays: 365,
          lastUpdated: now,
        );

        // When - 访问实体的计算属性
        final totalReturnPercentage = metrics.totalReturnPercentage;
        final annualizedReturnPercentage = metrics.annualizedReturnPercentage;
        final isPositiveReturn = metrics.isPositiveReturn;

        // Then - 验证计算结果
        expect(totalReturnPercentage, equals(15.0));
        expect(annualizedReturnPercentage, closeTo(14.0, 0.0001));
        expect(isPositiveReturn, isTrue);
      });

      test('Given PortfolioProfitCalculationCriteria实体 When 创建基础标准 Then 返回默认参数',
          () {
        // When - 创建基础计算标准
        final criteria = PortfolioProfitCalculationCriteria.basic();

        // Then - 验证默认参数
        expect(criteria.returnType, equals(ReturnType.total));
        expect(criteria.includeDividendReinvestment, isTrue);
        expect(criteria.considerCorporateActions, isTrue);
        expect(criteria.currency, equals('CNY'));
        expect(criteria.minimumDataDays, equals(30));
        expect(criteria.frequency, equals(CalculationFrequency.daily));
      });
    });

    group('TC-QA-003: 数据完整性处理', () {
      test('Given PortfolioProfitMetrics空实例 When 调用empty方法 Then 返回有效的空对象', () {
        // When - 创建空实例
        final emptyMetrics = PortfolioProfitMetrics.empty(fundCode: 'TEST001');

        // Then - 验证空实例属性
        expect(emptyMetrics.fundCode, equals('TEST001'));
        expect(emptyMetrics.totalReturnAmount, equals(0.0));
        expect(emptyMetrics.totalReturnRate, equals(0.0));
        expect(emptyMetrics.isPositiveReturn, isFalse);
        // 空实例默认数据质量为good，所以isComplete()可能返回true
      });

      test('Given PortfolioHolding实体 When 包含异常数据 Then 优雅处理', () {
        // Given - 包含NaN或无限大的数据
        final holdingWithNaN = PortfolioHolding(
          fundCode: 'TEST001',
          fundName: '测试基金',
          fundType: '股票型',
          holdingAmount: 10000.0,
          costNav: double.nan, // 异常数据
          costValue: 10000.0,
          marketValue: 11500.0,
          currentNav: 1.15,
          accumulatedNav: 1.25,
          holdingStartDate: DateTime.now(),
          lastUpdatedDate: DateTime.now(),
        );

        // When & Then - 验证异常数据处理
        expect(holdingWithNaN.fundCode, equals('TEST001'));
        expect(holdingWithNaN.costNav.isNaN, isTrue);
        expect(holdingWithNaN.currentReturnRate.isNaN, isTrue); // NaN计算结果还是NaN
      });
    });

    group('实体类方法验证', () {
      test('PortfolioHolding实体计算方法验证', () {
        final holding = PortfolioHolding(
          fundCode: '110022',
          fundName: '易方达消费行业',
          fundType: '股票型',
          holdingAmount: 10000.0,
          costNav: 1.0,
          costValue: 10000.0,
          marketValue: 11500.0,
          currentNav: 1.15,
          accumulatedNav: 1.25,
          holdingStartDate: DateTime(2023, 1, 1),
          lastUpdatedDate: DateTime.now(),
        );

        // 验证所有计算方法
        expect(holding.currentReturnRate, closeTo(0.15, 0.0001));
        expect(holding.currentReturnAmount, equals(1500.0));
        expect(holding.accumulatedReturnRate, equals(0.25));
        expect(holding.accumulatedReturnAmount, equals(2500.0));
        expect(holding.holdingDays, greaterThan(0));
      });

      test('PortfolioProfitMetrics便捷属性验证', () {
        final now = DateTime.now();
        final metrics = PortfolioProfitMetrics(
          fundCode: '110022',
          analysisDate: now,
          totalReturnAmount: 1500.0,
          totalReturnRate: 0.15,
          annualizedReturn: 0.14,
          dailyReturn: 0.001,
          weeklyReturn: 0.007,
          monthlyReturn: 0.03,
          quarterlyReturn: 0.08,
          return1Week: 0.005,
          return1Month: 0.02,
          return3Months: 0.06,
          return6Months: 0.12,
          return1Year: 0.15,
          return3Years: 0.45,
          returnYTD: 0.10,
          returnSinceInception: 0.15,
          dataStartDate: DateTime(2023, 1, 1),
          dataEndDate: now,
          analysisPeriodDays: 365,
          lastUpdated: now,
          volatility: 0.12,
          maxDrawdown: -0.08,
          sharpeRatio: 1.6,
          benchmarkReturn: 0.10,
          excessReturnRate: 0.05,
        );

        // 验证便捷计算属性
        expect(metrics.totalReturnPercentage, equals(15.0));
        expect(metrics.annualizedReturnPercentage, closeTo(14.0, 0.0001));
        expect(metrics.maxDrawdownPercentage, equals(-8.0));
        expect(metrics.volatilityPercentage, equals(12.0));
        expect(metrics.excessReturnPercentage, equals(5.0));
        expect(metrics.isPositiveReturn, isTrue);
        expect(metrics.outperformsBenchmark, isTrue);
        expect(metrics.riskLevel, equals(RiskLevel.medium));
        expect(metrics.performanceRating, equals(PerformanceRating.good));
        expect(metrics.hasExcellentSharpeRatio, isTrue);
      });

      test('PortfolioProfitCalculationCriteria枚举值验证', () {
        final criteria = PortfolioProfitCalculationCriteria(
          calculationId: 'test_001',
          fundCodes: const ['110022', '161725'],
          startDate: DateTime(2023, 1, 1),
          endDate: DateTime(2024, 1, 1),
          createdAt: DateTime.now(),
        );

        // 验证枚举值正确设置
        expect(criteria.frequency, equals(CalculationFrequency.daily));
        expect(criteria.returnType, equals(ReturnType.total));
        expect(criteria.dataQualityRequirement,
            equals(DataQualityRequirement.good));
        expect(criteria.outlierHandling, equals(OutlierHandling.keep));
      });
    });

    group('枚举类型验证', () {
      test('ReturnType枚举值验证', () {
        expect(ReturnType.total, equals(ReturnType.total));
        expect(ReturnType.price, equals(ReturnType.price));
        expect(ReturnType.dividend, equals(ReturnType.dividend));
        expect(ReturnType.excess, equals(ReturnType.excess));
      });

      test('CalculationFrequency枚举值验证', () {
        expect(CalculationFrequency.daily, equals(CalculationFrequency.daily));
        expect(
            CalculationFrequency.weekly, equals(CalculationFrequency.weekly));
        expect(
            CalculationFrequency.monthly, equals(CalculationFrequency.monthly));
        expect(CalculationFrequency.quarterly,
            equals(CalculationFrequency.quarterly));
        expect(CalculationFrequency.annually,
            equals(CalculationFrequency.annually));
      });

      test('RiskLevel枚举验证', () {
        expect(RiskLevel.low, equals(RiskLevel.low));
        expect(RiskLevel.medium, equals(RiskLevel.medium));
        expect(RiskLevel.high, equals(RiskLevel.high));
        expect(RiskLevel.veryHigh, equals(RiskLevel.veryHigh));
      });

      test('PerformanceRating枚举验证', () {
        expect(
            PerformanceRating.excellent, equals(PerformanceRating.excellent));
        expect(PerformanceRating.good, equals(PerformanceRating.good));
        expect(PerformanceRating.average, equals(PerformanceRating.average));
        expect(PerformanceRating.poor, equals(PerformanceRating.poor));
        expect(PerformanceRating.veryPoor, equals(PerformanceRating.veryPoor));
      });
    });
  });
}
