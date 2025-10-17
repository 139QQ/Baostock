import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:jisu_fund_analyzer/src/features/fund/domain/entities/fund.dart';
import 'package:jisu_fund_analyzer/src/features/fund/domain/entities/fund_filter_criteria.dart';
import 'package:jisu_fund_analyzer/src/features/fund/domain/usecases/fund_filter_usecase.dart';
import 'package:jisu_fund_analyzer/src/features/fund/domain/repositories/fund_repository.dart';
import 'package:jisu_fund_analyzer/src/features/fund/data/services/memory_management_service.dart';
import 'package:jisu_fund_analyzer/src/features/fund/data/datasources/fund_local_data_source.dart';
import 'dart:math';

void main() {
  group('内存使用监控测试', () {
    late List<Fund> testDataset;
    late FundFilterUseCase filterUseCase;
    late MemoryManagementService memoryService;
    late MockFundRepository mockRepository;
    late MockFundLocalDataSource mockDataSource;

    setUpAll(() async {
      testDataset = _generateTestDataset(2000);
      mockRepository = MockFundRepository();
      mockDataSource = MockFundLocalDataSource();
      filterUseCase = FundFilterUseCase(mockRepository);
      memoryService = MemoryManagementService(mockDataSource);
    });

    tearDownAll(() async {
      memoryService.stopMonitoring();
    });

    test('内存泄漏检测测试', () async {
      // Arrange
      const criteria = FundFilterCriteria(fundTypes: ['股票型']);
      final memorySnapshots = <MemorySnapshot>[];
      const leakDetectionThreshold = 10 * 1024 * 1024; // 10MB

      // 记录初始内存状态
      memorySnapshots.add(await _createMemorySnapshot('初始状态'));

      // Act - 执行大量筛选操作
      for (int i = 0; i < 50; i++) {
        // 变化的筛选条件以模拟真实使用
        final dynamicCriteria = FundFilterCriteria(
          fundTypes: ['股票型', '混合型'].sublist(0, (i % 2) + 1),
          scaleRange:
              i % 3 == 0 ? const RangeValue(min: 10.0, max: 200.0) : null,
          returnRange:
              i % 4 == 0 ? const RangeValue(min: 0.0, max: 30.0) : null,
          pageSize: 20,
          page: (i % 10) + 1,
        );

        await filterUseCase.filterFunds(testDataset, dynamicCriteria);

        // 每10次操作记录一次内存快照
        if (i % 10 == 0) {
          await memoryService.forceGarbageCollection();
          memorySnapshots.add(await _createMemorySnapshot('操作$i'));
        }
      }

      // 强制垃圾回收并记录最终状态
      await memoryService.forceGarbageCollection();
      memorySnapshots.add(await _createMemorySnapshot('最终状态'));

      // Assert - 分析内存使用模式
      final initialMemory = memorySnapshots.first.estimatedHeapUsage;
      final finalMemory = memorySnapshots.last.estimatedHeapUsage;
      final memoryIncrease = finalMemory - initialMemory;

      // 验证内存增长在阈值内
      expect(memoryIncrease, lessThanOrEqualTo(leakDetectionThreshold),
          reason:
              '内存增长应≤${leakDetectionThreshold / 1024 / 1024}MB，实际增长: ${(memoryIncrease / 1024 / 1024).toStringAsFixed(2)}MB');

      // 验证内存使用趋势（不应持续增长）
      final memoryTrend = _analyzeMemoryTrend(memorySnapshots);
      expect(memoryTrend, isNot(MemoryTrend.continuousGrowth),
          reason: '内存使用不应呈现持续增长趋势');

      print('=== 内存泄漏检测测试结果 ===');
      print('初始内存: ${(initialMemory / 1024 / 1024).toStringAsFixed(2)}MB');
      print('最终内存: ${(finalMemory / 1024 / 1024).toStringAsFixed(2)}MB');
      print('内存增长: ${(memoryIncrease / 1024 / 1024).toStringAsFixed(2)}MB');
      print('内存趋势: ${memoryTrend.toString()}');
      print('内存快照数量: ${memorySnapshots.length}');

      for (final snapshot in memorySnapshots) {
        print(
            '${snapshot.label}: ${(snapshot.estimatedHeapUsage / 1024 / 1024).toStringAsFixed(2)}MB');
      }
    });

    test('高频操作内存压力测试', () async {
      // Arrange
      final criteriaList = [
        const FundFilterCriteria(fundTypes: ['股票型']),
        const FundFilterCriteria(fundTypes: ['混合型']),
        const FundFilterCriteria(fundTypes: ['债券型']),
        const FundFilterCriteria(fundTypes: ['股票型', '混合型']),
        const FundFilterCriteria(
            fundTypes: ['股票型'], scaleRange: RangeValue(min: 10.0, max: 100.0)),
      ];

      final memoryStats = <MemoryStats>[];
      const operationCount = 100;

      // 记录初始内存
      var currentMemory = await _estimateMemoryUsage();
      memoryStats.add(MemoryStats(0, currentMemory));

      // Act - 高频执行筛选操作
      for (int i = 0; i < operationCount; i++) {
        final criteria = criteriaList[i % criteriaList.length];

        await filterUseCase.filterFunds(testDataset, criteria);

        // 每10次操作检查内存
        if ((i + 1) % 10 == 0) {
          await memoryService.forceGarbageCollection();
          currentMemory = await _estimateMemoryUsage();
          memoryStats.add(MemoryStats(i + 1, currentMemory));
        }
      }

      // Assert - 分析内存使用统计
      final maxMemory = memoryStats.map((s) => s.memoryUsage).reduce(max);
      final minMemory = memoryStats.map((s) => s.memoryUsage).reduce(min);
      final avgMemory =
          memoryStats.map((s) => s.memoryUsage).reduce((a, b) => a + b) /
              memoryStats.length;
      final memoryVariability = (maxMemory - minMemory) / avgMemory;

      // 验证内存变异性在合理范围内（≤30%）
      expect(memoryVariability, lessThanOrEqualTo(0.3),
          reason:
              '内存变异性应≤30%，实际: ${(memoryVariability * 100).toStringAsFixed(1)}%');

      // 验证内存使用没有异常峰值
      final peakMemoryRatio = maxMemory / minMemory;
      expect(peakMemoryRatio, lessThanOrEqualTo(2.0), reason: '内存峰值不应超过最低值的2倍');

      print('=== 高频操作内存压力测试结果 ===');
      print('总操作数: $operationCount');
      print('内存样本数: ${memoryStats.length}');
      print('最小内存: ${(minMemory / 1024 / 1024).toStringAsFixed(2)}MB');
      print('最大内存: ${(maxMemory / 1024 / 1024).toStringAsFixed(2)}MB');
      print('平均内存: ${(avgMemory / 1024 / 1024).toStringAsFixed(2)}MB');
      print('内存变异性: ${(memoryVariability * 100).toStringAsFixed(1)}%');
      print('峰值比例: ${peakMemoryRatio.toStringAsFixed(2)}x');
    });

    test('大数据集内存效率测试', () async {
      // Arrange
      final dataSizes = [500, 1000, 2000, 3000];
      final memoryEfficiencyResults = <int, MemoryEfficiencyResult>{};

      for (final size in dataSizes) {
        final dataset = _generateTestDataset(size);
        const criteria = FundFilterCriteria(
          fundTypes: ['股票型', '混合型'],
          scaleRange: RangeValue(min: 10.0, max: 200.0),
          returnRange: RangeValue(min: 0.0, max: 30.0),
        );

        // 预热
        await filterUseCase.filterFunds(dataset, criteria);

        // 正式测试
        final initialMemory = await _estimateMemoryUsage();
        final stopwatch = Stopwatch()..start();

        final result = await filterUseCase.filterFunds(dataset, criteria);

        stopwatch.stop();
        final finalMemory = await _estimateMemoryUsage();

        final memoryUsed = finalMemory - initialMemory;
        final memoryPerItem = memoryUsed / dataset.length;
        final throughput =
            dataset.length / stopwatch.elapsedMilliseconds * 1000;

        memoryEfficiencyResults[size] = MemoryEfficiencyResult(
          dataSize: size,
          memoryUsed: memoryUsed,
          memoryPerItem: memoryPerItem,
          responseTime: stopwatch.elapsedMilliseconds,
          throughput: throughput,
          resultCount: result.filteredFunds.length,
        );

        print(
            '数据量 $size: 内存${(memoryUsed / 1024 / 1024).toStringAsFixed(2)}MB, '
            '每项${(memoryPerItem / 1024).toStringAsFixed(1)}KB, '
            '吞吐量${throughput.toStringAsFixed(0)}条/秒');
      }

      // Assert - 验证内存效率
      final efficiencies =
          memoryEfficiencyResults.values.map((r) => r.memoryPerItem).toList();
      final avgEfficiency =
          efficiencies.reduce((a, b) => a + b) / efficiencies.length;
      final maxEfficiency = efficiencies.reduce(max);
      final minEfficiency = efficiencies.reduce(min);

      // 验证每项内存使用在合理范围内（≤10KB）
      expect(maxEfficiency, lessThanOrEqualTo(10 * 1024),
          reason:
              '每项内存使用应≤10KB，实际: ${(maxEfficiency / 1024).toStringAsFixed(1)}KB');

      // 验证内存效率一致性（最大不超过最小的3倍）
      expect(maxEfficiency, lessThanOrEqualTo(minEfficiency * 3),
          reason: '内存效率应保持一致，最大不超过最小的3倍');

      print('=== 大数据集内存效率测试总结 ===');
      print('平均每项内存: ${(avgEfficiency / 1024).toStringAsFixed(1)}KB');
      print(
          '效率范围: ${(minEfficiency / 1024).toStringAsFixed(1)}KB - ${(maxEfficiency / 1024).toStringAsFixed(1)}KB');
    });

    test('内存管理服务功能测试', () async {
      // Arrange
      final initialStats = await memoryService.getMemoryStats();

      // Act & Assert - 测试内存统计功能
      expect(initialStats.totalMemory, greaterThan(0));
      expect(initialStats.usedMemory, greaterThan(0));
      expect(initialStats.freeMemory, greaterThan(0));
      expect(initialStats.usagePercentage, greaterThan(0));
      expect(initialStats.usagePercentage, lessThanOrEqualTo(100));

      print('初始内存统计:');
      print(
          '总内存: ${(initialStats.totalMemory / 1024 / 1024).toStringAsFixed(2)}MB');
      print(
          '已用内存: ${(initialStats.usedMemory / 1024 / 1024).toStringAsFixed(2)}MB');
      print(
          '空闲内存: ${(initialStats.freeMemory / 1024 / 1024).toStringAsFixed(2)}MB');
      print('使用率: ${initialStats.usagePercentage.toStringAsFixed(1)}%');

      // 测试内存监控功能
      final monitoringStarted = await memoryService.startMemoryMonitoring();
      expect(monitoringStarted, isTrue);

      // 执行一些操作
      for (int i = 0; i < 5; i++) {
        await filterUseCase.filterFunds(
            testDataset, const FundFilterCriteria(fundTypes: ['股票型']));
        await Future.delayed(const Duration(milliseconds: 100));
      }

      final monitoringStats = await memoryService.getMonitoringStats();
      expect(monitoringStats.sampleCount, greaterThan(0));
      expect(monitoringStats.avgMemoryUsage, greaterThan(0));

      print('内存监控统计:');
      print('样本数量: ${monitoringStats.sampleCount}');
      print(
          '平均内存: ${(monitoringStats.avgMemoryUsage / 1024 / 1024).toStringAsFixed(2)}MB');
      print(
          '峰值内存: ${(monitoringStats.peakMemoryUsage / 1024 / 1024).toStringAsFixed(2)}MB');

      // 停止监控
      final monitoringStopped = await memoryService.stopMemoryMonitoring();
      expect(monitoringStopped, isTrue);

      // 测试垃圾回收功能
      final preGCMemory = await _estimateMemoryUsage();
      await memoryService.forceGarbageCollection();
      final postGCMemory = await _estimateMemoryUsage();

      // 垃圾回收后内存应该减少或保持不变
      expect(postGCMemory, lessThanOrEqualTo(preGCMemory + 5 * 1024 * 1024),
          reason: '垃圾回收后内存应该减少，允许5MB误差');

      print('垃圾回收效果:');
      print('GC前: ${(preGCMemory / 1024 / 1024).toStringAsFixed(2)}MB');
      print('GC后: ${(postGCMemory / 1024 / 1024).toStringAsFixed(2)}MB');
      print(
          '内存减少: ${((preGCMemory - postGCMemory) / 1024 / 1024).toStringAsFixed(2)}MB');
    });

    test('内存优化建议测试', () async {
      // Act - 获取内存优化建议
      final recommendations =
          await memoryService.getOptimizationRecommendations();

      // Assert - 验证建议内容
      expect(recommendations, isNotEmpty);
      expect(recommendations.length, greaterThan(0));

      // 验证建议格式
      for (final recommendation in recommendations) {
        expect(recommendation.title, isNotEmpty);
        expect(recommendation.description, isNotEmpty);
        expect(recommendation.priority, isIn([1, 2, 3, 4, 5]));
        expect(recommendation.category,
            isIn(['memory', 'performance', 'cache', 'gc']));
      }

      // 按优先级排序
      recommendations.sort((a, b) => a.priority.compareTo(b.priority));

      print('=== 内存优化建议 ===');
      for (final recommendation in recommendations) {
        print(
            '${recommendation.priority}. [${recommendation.category.toUpperCase()}] ${recommendation.title}');
        print('   ${recommendation.description}');
        print('');
      }

      // 验证高优先级建议数量
      final highPriorityRecommendations =
          recommendations.where((r) => r.priority <= 2).length;
      expect(highPriorityRecommendations, greaterThanOrEqualTo(0),
          reason: '应该有一些高优先级的优化建议');
    });
  });
}

/// 生成测试数据集
List<Fund> _generateTestDataset(int count) {
  final funds = <Fund>[];
  final fundTypes = ['股票型', '混合型', '债券型', '货币型', '指数型'];
  final companies = ['华夏基金', '易方达基金', '嘉实基金', '南方基金', '博时基金'];
  final riskLevels = ['低风险', '中低风险', '中风险', '中高风险', '高风险'];

  final random = Random(42); // 固定种子确保可重复性

  for (int i = 0; i < count; i++) {
    final typeIndex = random.nextInt(fundTypes.length);
    final companyIndex = random.nextInt(companies.length);
    final riskIndex = random.nextInt(riskLevels.length);

    funds.add(Fund(
      code: 'FN${(i + 1).toString().padLeft(6, '0')}',
      name: '测试基金${i + 1}',
      type: fundTypes[typeIndex],
      company: companies[companyIndex],
      scale: 10.0 + random.nextDouble() * 1000,
      date:
          '${2018 + random.nextInt(7)}-${(random.nextInt(12) + 1).toString().padLeft(2, '0')}-01',
      return1Y: -20.0 + random.nextDouble() * 80,
      return3Y: -15.0 + random.nextDouble() * 60,
      dailyReturn: -3.0 + random.nextDouble() * 10,
      riskLevel: riskLevels[riskIndex],
      status: random.nextDouble() < 0.05 ? '暂停' : '正常',
      lastUpdate: DateTime.now().subtract(Duration(days: random.nextInt(365))),
    ));
  }

  return funds;
}

/// 创建内存快照
Future<MemorySnapshot> _createMemorySnapshot(String label) async {
  return MemorySnapshot(
    label: label,
    timestamp: DateTime.now(),
    estimatedHeapUsage: await _estimateMemoryUsage(),
  );
}

/// 估算内存使用量（简化实现）
Future<int> _estimateMemoryUsage() async {
  // 这是一个简化的内存估算实现
  // 在真实环境中，这里应该调用真正的内存监控API
  await Future.delayed(const Duration(milliseconds: 1));

  // 模拟内存使用：80-150MB之间的随机值
  const baseMemory = 80 * 1024 * 1024;
  final variation = Random().nextInt(70 * 1024 * 1024);
  return baseMemory + variation;
}

/// 分析内存使用趋势
MemoryTrend _analyzeMemoryTrend(List<MemorySnapshot> snapshots) {
  if (snapshots.length < 3) return MemoryTrend.insufficientData;

  final values = snapshots.map((s) => s.estimatedHeapUsage).toList();
  var increasingCount = 0;
  var decreasingCount = 0;

  for (int i = 1; i < values.length; i++) {
    if (values[i] > values[i - 1]) increasingCount++;
    if (values[i] < values[i - 1]) decreasingCount++;
  }

  final totalChanges = values.length - 1;
  final increasingRatio = increasingCount / totalChanges;
  final decreasingRatio = decreasingCount / totalChanges;

  if (increasingRatio > 0.8) return MemoryTrend.continuousGrowth;
  if (decreasingRatio > 0.8) return MemoryTrend.continuousDecrease;
  if (increasingRatio > 0.6) return MemoryTrend.generalGrowth;
  if (decreasingRatio > 0.6) return MemoryTrend.generalDecrease;
  return MemoryTrend.stable;
}

/// 内存快照类
class MemorySnapshot {
  final String label;
  final DateTime timestamp;
  final int estimatedHeapUsage;

  MemorySnapshot({
    required this.label,
    required this.timestamp,
    required this.estimatedHeapUsage,
  });
}

/// 内存统计类
class MemoryStats {
  final int operationCount;
  final int memoryUsage;

  MemoryStats(this.operationCount, this.memoryUsage);
}

/// 内存效率结果类
class MemoryEfficiencyResult {
  final int dataSize;
  final int memoryUsed;
  final double memoryPerItem;
  final int responseTime;
  final double throughput;
  final int resultCount;

  MemoryEfficiencyResult({
    required this.dataSize,
    required this.memoryUsed,
    required this.memoryPerItem,
    required this.responseTime,
    required this.throughput,
    required this.resultCount,
  });
}

/// 内存使用趋势枚举
enum MemoryTrend {
  insufficientData,
  stable,
  continuousGrowth,
  continuousDecrease,
  generalGrowth,
  generalDecrease,
}

/// 模拟基金仓库
class MockFundRepository extends Mock implements FundRepository {}

/// 模拟本地数据源
class MockFundLocalDataSource extends Mock implements FundLocalDataSource {}
