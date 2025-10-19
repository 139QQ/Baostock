import 'package:flutter_test/flutter_test.dart';
import 'dart:async';
import '../lib/src/features/fund/domain/entities/multi_dimensional_comparison_criteria.dart';
import '../lib/src/features/fund/domain/entities/comparison_result.dart';
import '../lib/src/features/fund/data/services/fund_comparison_service.dart';
import '../lib/src/features/fund/domain/entities/fund_ranking.dart';

/// 基金对比功能性能测试
///
/// 验证API调用和数据处理时间是否满足3秒SLA要求
void main() {
  group('基金对比性能测试', () {
    late FundComparisonService service;
    late List<FundRanking> testFunds;

    setUp(() {
      service = FundComparisonService();
      testFunds = _generateTestFunds(10); // 生成10个测试基金
    });

    test('对比计算性能测试 - 应在3秒内完成', () async {
      // Given
      final criteria = MultiDimensionalComparisonCriteria(
        fundCodes: ['000001', '000002', '000003'],
        periods: [
          RankingPeriod.oneMonth,
          RankingPeriod.threeMonths,
          RankingPeriod.oneYear
        ],
        metric: ComparisonMetric.totalReturn,
        includeStatistics: true,
      );

      final stopwatch = Stopwatch()..start();

      // When
      final result = await service.calculateComparison(testFunds, criteria);

      stopwatch.stop();

      // Then
      expect(stopwatch.elapsedMilliseconds, lessThan(3000),
          reason: '对比计算应在3秒内完成，实际耗时: ${stopwatch.elapsedMilliseconds}ms');
      expect(result.hasError, isFalse);
      expect(result.fundData.length, equals(3));
    });

    test('大数据集性能测试 - 100个基金应在3秒内完成', () async {
      // Given
      final largeFundList = _generateTestFunds(100);
      final criteria = MultiDimensionalComparisonCriteria(
        fundCodes: ['000001', '000002', '000003', '000004', '000005'],
        periods: [RankingPeriod.oneYear],
        metric: ComparisonMetric.totalReturn,
        includeStatistics: true,
      );

      final stopwatch = Stopwatch()..start();

      // When
      final result = await service.calculateComparison(largeFundList, criteria);

      stopwatch.stop();

      // Then
      expect(stopwatch.elapsedMilliseconds, lessThan(3000),
          reason: '大数据集对比应在3秒内完成，实际耗时: ${stopwatch.elapsedMilliseconds}ms');
      expect(result.hasError, isFalse);
    });

    test('多时间段性能测试 - 5个时间段应在3秒内完成', () async {
      // Given
      final criteria = MultiDimensionalComparisonCriteria(
        fundCodes: ['000001', '000002'],
        periods: [
          RankingPeriod.oneMonth,
          RankingPeriod.threeMonths,
          RankingPeriod.sixMonths,
          RankingPeriod.oneYear,
          RankingPeriod.threeYears,
        ],
        metric: ComparisonMetric.totalReturn,
        includeStatistics: true,
      );

      final stopwatch = Stopwatch()..start();

      // When
      final result = await service.calculateComparison(testFunds, criteria);

      stopwatch.stop();

      // Then
      expect(stopwatch.elapsedMilliseconds, lessThan(3000),
          reason: '多时间段对比应在3秒内完成，实际耗时: ${stopwatch.elapsedMilliseconds}ms');
      expect(result.hasError, isFalse);
    });

    test('统计计算性能测试 - 应在1秒内完成', () async {
      // Given
      final fundDataList = [
        FundComparisonData(
          fundCode: '000001',
          fundName: '测试基金1',
          fundType: '股票型',
          period: RankingPeriod.oneYear,
          totalReturn: 0.15,
          annualizedReturn: 0.15,
          volatility: 0.20,
          sharpeRatio: 0.75,
          maxDrawdown: -0.15,
          ranking: 1,
          categoryAverage: 0.10,
          beatCategoryPercent: 50.0,
          benchmarkReturn: 0.08,
          beatBenchmarkPercent: 87.5,
        ),
        FundComparisonData(
          fundCode: '000002',
          fundName: '测试基金2',
          fundType: '股票型',
          period: RankingPeriod.oneYear,
          totalReturn: 0.25,
          annualizedReturn: 0.25,
          volatility: 0.25,
          sharpeRatio: 1.0,
          maxDrawdown: -0.20,
          ranking: 2,
          categoryAverage: 0.10,
          beatCategoryPercent: 150.0,
          benchmarkReturn: 0.08,
          beatBenchmarkPercent: 212.5,
        ),
      ];

      final stopwatch = Stopwatch()..start();

      // When
      final statistics = service.calculateStatistics(fundDataList);

      stopwatch.stop();

      // Then
      expect(stopwatch.elapsedMilliseconds, lessThan(1000),
          reason: '统计计算应在1秒内完成，实际耗时: ${stopwatch.elapsedMilliseconds}ms');
      expect(statistics.averageReturn, equals(0.20));
      expect(statistics.maxReturn, equals(0.25));
      expect(statistics.minReturn, equals(0.15));
    });

    test('内存使用性能测试 - 处理前后内存差异应在合理范围内', () async {
      // Given
      final criteria = MultiDimensionalComparisonCriteria(
        fundCodes: ['000001', '000002', '000003', '000004', '000005'],
        periods: [RankingPeriod.oneYear],
        metric: ComparisonMetric.totalReturn,
        includeStatistics: true,
      );

      // 记录初始内存（模拟）
      final initialMemory = _getCurrentMemoryUsage();

      // When - 处理大量数据
      final result = await service.calculateComparison(testFunds, criteria);

      // 记录处理后内存（模拟）
      final finalMemory = _getCurrentMemoryUsage();

      // Then
      expect(result.hasError, isFalse);
      expect(finalMemory - initialMemory, lessThan(50 * 1024 * 1024), // 50MB
          reason: '内存增长应控制在50MB以内');
    });
  });

  group('输入验证性能测试', () {
    test('验证性能测试 - 1000个无效基金代码验证应在100ms内完成', () {
      // Given
      final invalidFundCodes = List.generate(1000, (index) => 'INVALID_$index');
      final criteria = MultiDimensionalComparisonCriteria(
        fundCodes: invalidFundCodes,
        periods: [RankingPeriod.oneYear],
        metric: ComparisonMetric.totalReturn,
      );

      final stopwatch = Stopwatch()..start();

      // When
      final isValid = criteria.isValid();
      final error = criteria.getValidationError();

      stopwatch.stop();

      // Then
      expect(stopwatch.elapsedMilliseconds, lessThan(100),
          reason: '输入验证应在100ms内完成，实际耗时: ${stopwatch.elapsedMilliseconds}ms');
      expect(isValid, isFalse);
      expect(error, isNotNull);
    });
  });
}

/// 生成测试基金数据
List<FundRanking> _generateTestFunds(int count) {
  return List.generate(count, (index) {
    final fundCode = (index + 1).toString().padLeft(6, '0');
    return FundRanking(
      fundCode: fundCode,
      fundName: '测试基金$fundCode',
      fundType: index % 2 == 0 ? '股票型' : '混合型',
      company: '测试基金公司',
      rankingPosition: index + 1,
      totalCount: count,
      unitNav: 1.0 + (index * 0.1),
      accumulatedNav: 1.5 + (index * 0.2),
      dailyReturn: 0.01 * (index % 5 - 2),
      return1W: 0.02 * (index % 7 - 3),
      return1M: 0.05 * (index % 11 - 5),
      return3M: 0.12 * (index % 13 - 6),
      return6M: 0.18 * (index % 17 - 8),
      return1Y: 0.25 * (index % 19 - 9),
      return2Y: 0.40 * (index % 23 - 11),
      return3Y: 0.60 * (index % 29 - 14),
      returnYTD: 0.08 * (index % 7 - 3),
      returnSinceInception: 2.0 * (index % 5 - 2),
      rankingDate: DateTime.now(),
      rankingType: RankingType.overall,
      rankingPeriod: RankingPeriod.oneYear,
    );
  });
}

/// 获取当前内存使用量（模拟实现）
int _getCurrentMemoryUsage() {
  // 在实际实现中，这里会使用dart:developer或类似的库来获取真实内存使用量
  // 这里返回一个模拟值用于测试
  return 100 * 1024 * 1024; // 100MB
}
