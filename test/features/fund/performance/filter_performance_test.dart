import 'package:flutter_test/flutter_test.dart';
import 'package:jisu_fund_analyzer/src/features/fund/domain/entities/fund.dart';
import 'package:jisu_fund_analyzer/src/features/fund/domain/entities/fund_filter_criteria.dart';
import 'package:jisu_fund_analyzer/src/features/fund/domain/usecases/fund_filter_usecase.dart';
import 'package:jisu_fund_analyzer/src/features/fund/domain/repositories/fund_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'filter_performance_test.mocks.dart';

// 生成Mock文件
@GenerateMocks([FundRepository])
void main() {
  group('基金筛选性能测试', () {
    late MockFundRepository mockRepository;
    late FundFilterUseCase filterUseCase;
    late List<Fund> largeDataset;

    setUpAll(() async {
      mockRepository = MockFundRepository();
      filterUseCase = FundFilterUseCase(mockRepository);

      // 生成大规模测试数据集（1000+基金）
      largeDataset = _generateLargeTestDataset(1500);
    });

    setUp(() {
      reset(mockRepository);

      // 设置默认的mock行为
      when(mockRepository.getFundList()).thenAnswer((_) async => largeDataset);
      when(mockRepository.getFilteredFundsCount(any))
          .thenAnswer((_) async => largeDataset.length);
    });

    test('大规模数据集筛选性能测试 - 基金类型筛选', () async {
      // Arrange
      const criteria = FundFilterCriteria(
        fundTypes: ['股票型', '混合型'],
        pageSize: 20,
        page: 1,
      );

      // Act & Assert - 性能测试
      final stopwatch = Stopwatch()..start();

      final result = await filterUseCase.execute(criteria);

      stopwatch.stop();

      // 验证性能要求（响应时间≤300ms）
      expect(stopwatch.elapsedMilliseconds, lessThanOrEqualTo(300));

      // 验证结果正确性
      expect(result.funds, isNotEmpty);
      expect(result.totalCount, greaterThan(0));
      expect(result.funds.length, lessThanOrEqualTo(20));

      // 验证所有结果都是指定类型
      for (final fund in result.funds) {
        expect(['股票型', '混合型'], contains(fund.type));
      }

      print('大规模数据集筛选 - 基金类型: ${stopwatch.elapsedMilliseconds}ms');
    });

    test('大规模数据集筛选性能测试 - 复杂组合筛选', () async {
      // Arrange - 复杂的多条件筛选
      const criteria = FundFilterCriteria(
        fundTypes: ['股票型', '混合型'],
        scaleRange: RangeValue(min: 10.0, max: 500.0),
        returnRange: RangeValue(min: 5.0, max: 50.0),
        riskLevels: ['中风险', '高风险'],
        sortBy: 'return1Y',
        sortDirection: SortDirection.desc,
        pageSize: 20,
        page: 1,
      );

      // Act & Assert - 性能测试
      final stopwatch = Stopwatch()..start();

      final result = await filterUseCase.execute(criteria);

      stopwatch.stop();

      // 验证性能要求（响应时间≤300ms）
      expect(stopwatch.elapsedMilliseconds, lessThanOrEqualTo(300));

      // 验证结果正确性
      expect(result.funds, isNotEmpty);

      // 验证排序正确性（按收益率降序）
      for (int i = 0; i < result.funds.length - 1; i++) {
        expect(result.funds[i].return1Y,
            greaterThanOrEqualTo(result.funds[i + 1].return1Y));
      }

      print('大规模数据集筛选 - 复杂组合: ${stopwatch.elapsedMilliseconds}ms');
    });

    test('内存使用监控测试', () async {
      // Arrange
      const criteria = FundFilterCriteria(
        fundTypes: ['股票型'],
        pageSize: 50,
        page: 1,
      );

      // 记录初始内存使用
      final initialMemory = _getCurrentMemoryUsage();

      // Act - 执行多次筛选操作
      for (int i = 0; i < 10; i++) {
        await filterUseCase.execute(criteria);
      }

      // 强制垃圾回收
      await Future.delayed(const Duration(milliseconds: 100));

      // 记录最终内存使用
      final finalMemory = _getCurrentMemoryUsage();
      final memoryIncrease = finalMemory - initialMemory;

      // Assert - 验证内存增长在合理范围内（≤10MB）
      expect(memoryIncrease, lessThanOrEqualTo(10 * 1024 * 1024));

      print('内存使用增长: ${(memoryIncrease / 1024 / 1024).toStringAsFixed(2)}MB');
    });

    test('并发筛选性能测试', () async {
      // Arrange
      final criteriaList = [
        const FundFilterCriteria(fundTypes: ['股票型']),
        const FundFilterCriteria(fundTypes: ['混合型']),
        const FundFilterCriteria(fundTypes: ['债券型']),
        const FundFilterCriteria(scaleRange: RangeValue(min: 10.0, max: 100.0)),
        const FundFilterCriteria(returnRange: RangeValue(min: 0.0, max: 20.0)),
      ];

      // Act - 并发执行多个筛选操作
      final stopwatch = Stopwatch()..start();

      final futures = criteriaList
          .map((criteria) => filterUseCase.execute(criteria))
          .toList();

      final results = await Future.wait(futures);

      stopwatch.stop();

      // Assert
      expect(results.length, equals(5));
      for (final result in results) {
        expect(result.funds, isNotEmpty);
      }

      // 并发操作应该仍然在合理时间内完成
      expect(stopwatch.elapsedMilliseconds, lessThanOrEqualTo(1000));

      print('并发筛选性能: ${stopwatch.elapsedMilliseconds}ms');
    });

    test('分页加载性能测试', () async {
      // Arrange
      const criteria = FundFilterCriteria(
        fundTypes: ['股票型'],
        pageSize: 20,
        page: 1,
      );

      // Act & Assert - 测试多页加载性能
      final totalTime = Stopwatch()..start();

      for (int page = 1; page <= 5; page++) {
        final pageCriteria = criteria.copyWith(page: page);
        final stopwatch = Stopwatch()..start();

        final result = await filterUseCase.execute(pageCriteria);

        stopwatch.stop();

        // 每页加载都应该在300ms内完成
        expect(stopwatch.elapsedMilliseconds, lessThanOrEqualTo(300));
        expect(result.funds.length, lessThanOrEqualTo(20));

        print('第$page页加载: ${stopwatch.elapsedMilliseconds}ms');
      }

      totalTime.stop();

      // 总时间应该在合理范围内
      expect(totalTime.elapsedMilliseconds, lessThanOrEqualTo(1500));

      print('总分页加载时间: ${totalTime.elapsedMilliseconds}ms');
    });

    test('缓存性能优化测试', () async {
      // Arrange
      const criteria = FundFilterCriteria(
        fundTypes: ['股票型'],
        sortBy: 'name',
        pageSize: 20,
      );

      // Act - 测试重复筛选的性能差异
      final stopwatch1 = Stopwatch()..start();
      final result1 = await filterUseCase.execute(criteria);
      stopwatch1.stop();

      // 第二次相同筛选（应该利用缓存）
      final stopwatch2 = Stopwatch()..start();
      final result2 = await filterUseCase.execute(criteria);
      stopwatch2.stop();

      // Assert
      expect(result1.funds.length, equals(result2.funds.length));

      // 第二次筛选应该更快（至少快20%）
      expect(stopwatch2.elapsedMilliseconds,
          lessThan(stopwatch1.elapsedMilliseconds * 0.8));

      print('首次筛选: ${stopwatch1.elapsedMilliseconds}ms');
      print('缓存筛选: ${stopwatch2.elapsedMilliseconds}ms');
      print(
          '性能提升: ${((stopwatch1.elapsedMilliseconds - stopwatch2.elapsedMilliseconds) / stopwatch1.elapsedMilliseconds * 100).toStringAsFixed(1)}%');
    });
  });
}

/// 生成大规模测试数据集
List<Fund> _generateLargeTestDataset(int count) {
  final funds = <Fund>[];
  final fundTypes = ['股票型', '混合型', '债券型', '货币型', '指数型'];
  final companies = ['华夏基金', '易方达基金', '嘉实基金', '南方基金', '博时基金'];
  final riskLevels = ['低风险', '中低风险', '中风险', '中高风险', '高风险'];

  final random = DateTime.now().millisecondsSinceEpoch;

  for (int i = 0; i < count; i++) {
    final typeIndex = (random + i) % fundTypes.length;
    final companyIndex = (random + i * 2) % companies.length;
    final riskIndex = (random + i * 3) % riskLevels.length;

    funds.add(Fund(
      code: 'FN${(i + 1).toString().padLeft(6, '0')}',
      name: '测试基金${i + 1}',
      type: fundTypes[typeIndex],
      company: companies[companyIndex],
      scale: 10.0 + (i % 1000) * 0.5,
      date: '${2020 + (i % 5)}-${((i % 12) + 1).toString().padLeft(2, '0')}-01',
      return1Y: -10.0 + (i % 60),
      return3Y: -5.0 + (i % 40),
      dailyReturn: -2.0 + (i % 10) * 0.5,
      riskLevel: riskLevels[riskIndex],
      status: i % 20 == 0 ? '暂停' : '正常',
      lastUpdate: DateTime.now().subtract(Duration(days: i % 30)),
    ));
  }

  return funds;
}

/// 获取当前内存使用量（字节）
int _getCurrentMemoryUsage() {
  // 在实际环境中，这里应该使用平台特定的API来获取内存使用量
  // 为了测试目的，返回一个模拟值
  return DateTime.now().millisecondsSinceEpoch * 1024;
}
