import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:jisu_fund_analyzer/src/features/fund/domain/entities/fund.dart';
import 'package:jisu_fund_analyzer/src/features/fund/domain/entities/fund_filter_criteria.dart';
import 'package:jisu_fund_analyzer/src/features/fund/domain/usecases/fund_filter_usecase.dart';
import 'package:jisu_fund_analyzer/src/features/fund/domain/repositories/fund_repository.dart';
import 'dart:math';

import 'user_experience_test.mocks.dart';

@GenerateMocks([FundRepository])
void main() {
  group('用户体验流畅度测试', () {
    late List<Fund> testDataset;
    late FundFilterUseCase filterUseCase;
    late MockFundRepository mockRepository;

    setUpAll(() async {
      testDataset = _generateTestDataset(1500);
      mockRepository = MockFundRepository();
      // 设置 mock repository 的行为
      when(mockRepository.getFundList()).thenAnswer((_) async => testDataset);
      when(mockRepository.getFilteredFundsCount(any))
          .thenAnswer((_) async => testDataset.length);
      filterUseCase = FundFilterUseCase(mockRepository);
    });

    test('响应时间感知测试', () async {
      // 定义响应时间感知阈值
      const instantThreshold = 50; // 50ms内感觉即时
      const fastThreshold = 100; // 100ms内感觉快速
      const acceptableThreshold = 200; // 200ms内感觉可接受
      const slowThreshold = 300; // 300ms为性能要求上限

      final operations = [
        UserOperation(
            '简单筛选', () => const FundFilterCriteria(fundTypes: ['股票型'])),
        UserOperation(
            '类型+公司筛选',
            () => const FundFilterCriteria(
                  fundTypes: ['股票型', '混合型'],
                  companies: ['华夏基金', '易方达基金'],
                )),
        UserOperation(
            '类型+范围筛选',
            () => const FundFilterCriteria(
                  fundTypes: ['股票型'],
                  scaleRange: RangeValue(min: 10.0, max: 100.0),
                  returnRange: RangeValue(min: 5.0, max: 20.0),
                )),
        UserOperation(
            '复杂多条件筛选',
            () => const FundFilterCriteria(
                  fundTypes: ['股票型', '混合型'],
                  scaleRange: RangeValue(min: 5.0, max: 200.0),
                  returnRange: RangeValue(min: 0.0, max: 30.0),
                  riskLevels: ['中风险', '高风险'],
                  sortBy: 'return1Y',
                  sortDirection: SortDirection.desc,
                )),
        UserOperation(
            '分页筛选（第5页）',
            () => const FundFilterCriteria(
                  fundTypes: ['股票型'],
                  pageSize: 20,
                  page: 5,
                )),
      ];

      final results = <UserExperienceResult>[];

      for (final operation in operations) {
        // 重复测试取平均值
        final times = <int>[];

        for (int i = 0; i < 5; i++) {
          final stopwatch = Stopwatch()..start();
          await filterUseCase.execute(operation.criteriaBuilder());
          stopwatch.stop();
          times.add(stopwatch.elapsedMilliseconds);
        }

        final avgTime = times.reduce((a, b) => a + b) / times.length;
        final minTime = times.reduce(min);
        final maxTime = times.reduce(max);

        // 确定感知等级
        PerceptionLevel perception;
        if (avgTime <= instantThreshold) {
          perception = PerceptionLevel.instant;
        } else if (avgTime <= fastThreshold) {
          perception = PerceptionLevel.fast;
        } else if (avgTime <= acceptableThreshold) {
          perception = PerceptionLevel.acceptable;
        } else if (avgTime <= slowThreshold) {
          perception = PerceptionLevel.slow;
        } else {
          perception = PerceptionLevel.unacceptable;
        }

        results.add(UserExperienceResult(
          name: operation.name,
          avgTime: avgTime,
          minTime: minTime,
          maxTime: maxTime,
          perception: perception,
        ));

        // 验证性能要求
        expect(avgTime, lessThanOrEqualTo(slowThreshold),
            reason:
                '${operation.name} 应在${slowThreshold}ms内完成，实际: ${avgTime.toStringAsFixed(2)}ms');
      }

      // 分析用户体验质量
      final instantOperations =
          results.where((r) => r.perception == PerceptionLevel.instant).length;
      final fastOperations =
          results.where((r) => r.perception == PerceptionLevel.fast).length;
      final acceptableOperations = results
          .where((r) => r.perception == PerceptionLevel.acceptable)
          .length;
      final slowOperations =
          results.where((r) => r.perception == PerceptionLevel.slow).length;

      final goodExperienceRatio =
          (instantOperations + fastOperations) / results.length;

      // 验证用户体验质量
      expect(goodExperienceRatio, greaterThanOrEqualTo(0.6),
          reason: '60%的操作应该感觉快速或即时');

      print('=== 响应时间感知测试结果 ===');
      print('总操作数: ${results.length}');
      print(
          '即时响应: $instantOperations 个 (${(instantOperations / results.length * 100).toStringAsFixed(1)}%)');
      print(
          '快速响应: $fastOperations 个 (${(fastOperations / results.length * 100).toStringAsFixed(1)}%)');
      print(
          '可接受响应: $acceptableOperations 个 (${(acceptableOperations / results.length * 100).toStringAsFixed(1)}%)');
      print(
          '缓慢响应: $slowOperations 个 (${(slowOperations / results.length * 100).toStringAsFixed(1)}%)');
      print('良好体验比例: ${(goodExperienceRatio * 100).toStringAsFixed(1)}%');

      for (final result in results) {
        final perceptionEmoji = _getPerceptionEmoji(result.perception);
        print(
            '$perceptionEmoji ${result.name}: ${result.avgTime.toStringAsFixed(2)}ms (${result.perception.toString()})');
      }
    });

    test('连续操作流畅度测试', () async {
      // 模拟用户连续快速操作
      final operationSequence = [
        () => const FundFilterCriteria(fundTypes: ['股票型']),
        () => const FundFilterCriteria(fundTypes: ['混合型']),
        () => const FundFilterCriteria(fundTypes: ['股票型', '混合型']),
        () => const FundFilterCriteria(
            fundTypes: ['股票型'], scaleRange: RangeValue(min: 10.0, max: 100.0)),
        () => const FundFilterCriteria(
            fundTypes: ['股票型'], returnRange: RangeValue(min: 5.0, max: 20.0)),
        () => const FundFilterCriteria(
            fundTypes: ['混合型'], scaleRange: RangeValue(min: 20.0, max: 200.0)),
        () => const FundFilterCriteria(
            fundTypes: ['股票型', '混合型'],
            scaleRange: RangeValue(min: 10.0, max: 200.0)),
        () => const FundFilterCriteria(
            fundTypes: ['股票型'], returnRange: RangeValue(min: 0.0, max: 30.0)),
        () => const FundFilterCriteria(fundTypes: ['混合型'], riskLevels: ['中风险']),
      ];

      final sequenceResults = <SequenceOperationResult>[];
      const userThinkTime = Duration(milliseconds: 50); // 模拟用户操作间隔

      for (int i = 0; i < operationSequence.length; i++) {
        final operation = operationSequence[i];

        final stopwatch = Stopwatch()..start();
        final result = await filterUseCase.execute(operation());
        stopwatch.stop();

        sequenceResults.add(SequenceOperationResult(
          step: i + 1,
          responseTime: stopwatch.elapsedMilliseconds,
          resultCount: result.funds.length,
          isSmooth: stopwatch.elapsedMilliseconds <= 150, // 150ms内感觉流畅
        ));

        // 模拟用户操作间隔
        await Future.delayed(userThinkTime);
      }

      // 分析连续操作流畅度
      final smoothOperations = sequenceResults.where((r) => r.isSmooth).length;
      final smoothnessRatio = smoothOperations / sequenceResults.length;
      final avgResponseTime =
          sequenceResults.map((r) => r.responseTime).reduce((a, b) => a + b) /
              sequenceResults.length;
      final maxResponseTime =
          sequenceResults.map((r) => r.responseTime).reduce(max);

      // 验证流畅度要求
      expect(smoothnessRatio, greaterThanOrEqualTo(0.7),
          reason: '70%的操作应该在150ms内完成以感觉流畅');
      expect(avgResponseTime, lessThanOrEqualTo(150),
          reason: '连续操作平均响应时间应≤150ms');
      expect(maxResponseTime, lessThanOrEqualTo(300),
          reason: '连续操作最大响应时间应≤300ms');

      // 计算操作稳定性（响应时间变异系数）
      final responseTimes = sequenceResults.map((r) => r.responseTime).toList();
      final meanTime =
          responseTimes.reduce((a, b) => a + b) / responseTimes.length;
      final variance = responseTimes
              .map((t) => (t - meanTime) * (t - meanTime))
              .reduce((a, b) => a + b) /
          responseTimes.length;
      final stdDev = sqrt(variance);
      final coefficientOfVariation = stdDev / meanTime;

      // 验证稳定性
      expect(coefficientOfVariation, lessThanOrEqualTo(0.5),
          reason: '响应时间变异系数应≤0.5以保证稳定性');

      print('=== 连续操作流畅度测试结果 ===');
      print('总步数: ${sequenceResults.length}');
      print('流畅操作: $smoothOperations 个');
      print('流畅度比例: ${(smoothnessRatio * 100).toStringAsFixed(1)}%');
      print('平均响应时间: ${avgResponseTime.toStringAsFixed(2)}ms');
      print('最大响应时间: ${maxResponseTime}ms');
      print('变异系数: ${(coefficientOfVariation * 100).toStringAsFixed(1)}%');

      for (final result in sequenceResults) {
        final smoothness = result.isSmooth ? '✅ 流畅' : '⏱️ 缓慢';
        print('步骤${result.step}: ${result.responseTime}ms ($smoothness)');
      }
    });

    test('渐进式筛选体验测试', () async {
      // 模拟用户逐步添加筛选条件的场景
      final progressiveSteps = [
        ProgressiveStep('初始状态', () => const FundFilterCriteria()),
        ProgressiveStep(
            '选择基金类型', () => const FundFilterCriteria(fundTypes: ['股票型'])),
        ProgressiveStep(
            '添加规模筛选',
            () => const FundFilterCriteria(
                  fundTypes: ['股票型'],
                  scaleRange: RangeValue(min: 10.0, max: 100.0),
                )),
        ProgressiveStep(
            '添加收益率筛选',
            () => const FundFilterCriteria(
                  fundTypes: ['股票型'],
                  scaleRange: RangeValue(min: 10.0, max: 100.0),
                  returnRange: RangeValue(min: 5.0, max: 20.0),
                )),
        ProgressiveStep(
            '添加风险等级',
            () => const FundFilterCriteria(
                  fundTypes: ['股票型'],
                  scaleRange: RangeValue(min: 10.0, max: 100.0),
                  returnRange: RangeValue(min: 5.0, max: 20.0),
                  riskLevels: ['中风险', '高风险'],
                )),
        ProgressiveStep(
            '添加排序',
            () => const FundFilterCriteria(
                  fundTypes: ['股票型'],
                  scaleRange: RangeValue(min: 10.0, max: 100.0),
                  returnRange: RangeValue(min: 5.0, max: 20.0),
                  riskLevels: ['中风险', '高风险'],
                  sortBy: 'return1Y',
                  sortDirection: SortDirection.desc,
                )),
      ];

      final progressiveResults = <ProgressiveResult>[];

      for (int i = 0; i < progressiveSteps.length; i++) {
        final step = progressiveSteps[i];

        final stopwatch = Stopwatch()..start();
        final result = await filterUseCase.execute(step.criteriaBuilder());
        stopwatch.stop();

        progressiveResults.add(ProgressiveResult(
          stepName: step.name,
          stepNumber: i + 1,
          responseTime: stopwatch.elapsedMilliseconds,
          resultCount: result.funds.length,
          isAcceptable: stopwatch.elapsedMilliseconds <= 200,
        ));

        // 验证渐进式操作的响应时间
        expect(stopwatch.elapsedMilliseconds, lessThanOrEqualTo(300),
            reason: '渐进式步骤"${step.name}"应在300ms内完成');
      }

      // 分析渐进式体验
      final acceptableSteps =
          progressiveResults.where((r) => r.isAcceptable).length;
      final acceptabilityRatio = acceptableSteps / progressiveResults.length;

      // 验证渐进式体验质量
      expect(acceptabilityRatio, greaterThanOrEqualTo(0.8),
          reason: '80%的渐进式步骤应在200ms内完成');

      // 分析复杂度增长对性能的影响
      final complexityImpact = <int, double>{};
      for (int i = 1; i < progressiveResults.length; i++) {
        final currentTime = progressiveResults[i].responseTime;
        final baseTime = progressiveResults[0].responseTime;
        final impactFactor = currentTime / baseTime;
        complexityImpact[i] = impactFactor;
      }

      // 验证复杂度影响合理性
      final maxImpactFactor = complexityImpact.values.reduce(max);
      expect(maxImpactFactor, lessThanOrEqualTo(3.0),
          reason: '最复杂步骤的响应时间不应超过初始状态的3倍');

      print('=== 渐进式筛选体验测试结果 ===');
      print('总步骤数: ${progressiveResults.length}');
      print('可接受步骤: $acceptableSteps 个');
      print('可接受比例: ${(acceptabilityRatio * 100).toStringAsFixed(1)}%');
      print('最大复杂度影响: ${maxImpactFactor.toStringAsFixed(2)}x');

      for (final result in progressiveResults) {
        final acceptability = result.isAcceptable ? '✅' : '⏱️';
        print(
            '$acceptability ${result.stepName}: ${result.responseTime}ms (${result.resultCount}个结果)');
      }
    });

    test('错误处理和恢复体验测试', () async {
      // 测试异常情况下的用户体验
      final errorScenarios = [
        ErrorScenario(
          '空筛选条件',
          () => const FundFilterCriteria(),
          '应该优雅处理空条件',
        ),
        ErrorScenario(
          '无匹配结果',
          () => const FundFilterCriteria(
            fundTypes: ['不存在的基金类型'],
            companies: ['不存在的公司'],
          ),
          '应该返回空结果而不是错误',
        ),
        ErrorScenario(
          '极端范围值',
          () => const FundFilterCriteria(
            scaleRange: RangeValue(min: -100.0, max: 0.0),
            returnRange: RangeValue(min: 1000.0, max: 2000.0),
          ),
          '应该处理极端值',
        ),
        ErrorScenario(
          '超大页码',
          () => const FundFilterCriteria(
            fundTypes: ['股票型'],
            pageSize: 20,
            page: 9999,
          ),
          '应该处理超大页码',
        ),
      ];

      final errorResults = <ErrorHandlingResult>[];

      for (final scenario in errorScenarios) {
        try {
          final stopwatch = Stopwatch()..start();
          final result =
              await filterUseCase.execute(scenario.criteriaBuilder());
          stopwatch.stop();

          errorResults.add(ErrorHandlingResult(
            scenarioName: scenario.name,
            completed: true,
            responseTime: stopwatch.elapsedMilliseconds,
            hasError: false,
            errorMessage: null,
            expectationMet: true,
          ));

          // 验证错误场景也能在合理时间内完成
          expect(stopwatch.elapsedMilliseconds, lessThanOrEqualTo(500),
              reason: '错误场景"${scenario.name}"也应在500ms内完成');
        } catch (e) {
          errorResults.add(ErrorHandlingResult(
            scenarioName: scenario.name,
            completed: false,
            responseTime: -1,
            hasError: true,
            errorMessage: e.toString(),
            expectationMet: false,
          ));

          // 错误处理不应该是未捕获的异常
          fail('错误场景"${scenario.name}"抛出了未捕获的异常: $e');
        }
      }

      // 分析错误处理质量
      final successfulScenarios = errorResults.where((r) => r.completed).length;
      final successRate = successfulScenarios / errorScenarios.length;

      // 验证错误处理质量
      expect(successRate, greaterThanOrEqualTo(0.9),
          reason: '90%以上的错误场景应该优雅处理');

      print('=== 错误处理和恢复体验测试结果 ===');
      print('总场景数: ${errorScenarios.length}');
      print('成功处理: $successfulScenarios 个');
      print('成功率: ${(successRate * 100).toStringAsFixed(1)}%');

      for (final result in errorResults) {
        final status = result.completed ? '✅ 成功' : '❌ 失败';
        print('$status ${result.scenarioName}: ${result.responseTime}ms');
        if (result.errorMessage != null) {
          print('   错误: ${result.errorMessage}');
        }
      }
    });

    test('用户满意度评分测试', () async {
      // 基于多项指标计算用户满意度评分
      final testScenarios = [
        SatisfactionScenario(
            '日常筛选', () => const FundFilterCriteria(fundTypes: ['股票型'])),
        SatisfactionScenario(
            '中等复杂筛选',
            () => const FundFilterCriteria(
                  fundTypes: ['股票型', '混合型'],
                  scaleRange: RangeValue(min: 10.0, max: 100.0),
                )),
        SatisfactionScenario(
            '复杂筛选',
            () => const FundFilterCriteria(
                  fundTypes: ['股票型', '混合型'],
                  companies: ['华夏基金', '易方达基金'],
                  scaleRange: RangeValue(min: 5.0, max: 200.0),
                  returnRange: RangeValue(min: 0.0, max: 30.0),
                  riskLevels: ['中风险', '高风险'],
                  sortBy: 'return1Y',
                  sortDirection: SortDirection.desc,
                )),
      ];

      final satisfactionResults = <SatisfactionResult>[];

      for (final scenario in testScenarios) {
        final measurements = <int>[];

        // 多次测量取平均值
        for (int i = 0; i < 10; i++) {
          final stopwatch = Stopwatch()..start();
          final result =
              await filterUseCase.execute(scenario.criteriaBuilder());
          stopwatch.stop();
          measurements.add(stopwatch.elapsedMilliseconds);
        }

        final avgTime =
            measurements.reduce((a, b) => a + b) / measurements.length;
        final consistency = _calculateConsistency(measurements);
        final reliability = _calculateReliability(measurements);

        // 计算满意度评分（0-5分）
        final score =
            _calculateSatisfactionScore(avgTime, consistency, reliability);

        satisfactionResults.add(SatisfactionResult(
          scenarioName: scenario.name,
          avgResponseTime: avgTime,
          consistency: consistency,
          reliability: reliability,
          score: score,
        ));

        // 验证满意度评分
        expect(score, greaterThanOrEqualTo(3.0),
            reason: '${scenario.name}的满意度评分应≥3.0');
      }

      // 分析总体满意度
      final avgScore =
          satisfactionResults.map((r) => r.score).reduce((a, b) => a + b) /
              satisfactionResults.length;
      final minScore = satisfactionResults.map((r) => r.score).reduce(min);

      // 验证总体满意度
      expect(avgScore, greaterThanOrEqualTo(4.0), reason: '平均满意度评分应≥4.0');
      expect(minScore, greaterThanOrEqualTo(3.5), reason: '最低满意度评分应≥3.5');

      print('=== 用户满意度评分测试结果 ===');
      print('平均满意度评分: ${avgScore.toStringAsFixed(2)}/5.0');
      print('最低满意度评分: ${minScore.toStringAsFixed(2)}/5.0');

      for (final result in satisfactionResults) {
        final stars = '⭐' * result.score.round();
        print(
            '$stars ${result.scenarioName}: ${result.score.toStringAsFixed(2)}/5.0');
        print('   响应时间: ${result.avgResponseTime.toStringAsFixed(2)}ms');
        print('   一致性: ${(result.consistency * 100).toStringAsFixed(1)}%');
        print('   可靠性: ${(result.reliability * 100).toStringAsFixed(1)}%');
        print('');
      }
    });
  });
}

/// 生成测试数据集
List<Fund> _generateTestDataset(int count) {
  final funds = <Fund>[];
  final fundTypes = ['股票型', '混合型', '债券型', '货币型', '指数型'];
  final companies = ['华夏基金', '易方达基金', '嘉实基金', '南方基金', '博时基金'];
  final riskLevels = ['低风险', '中低风险', '中风险', '中高风险', '高风险'];

  for (int i = 0; i < count; i++) {
    final typeIndex = i % fundTypes.length;
    final companyIndex = (i * 2) % companies.length;
    final riskIndex = (i * 3) % riskLevels.length;

    funds.add(Fund(
      code: 'FN${(i + 1).toString().padLeft(6, '0')}',
      name: '测试基金${i + 1}',
      type: fundTypes[typeIndex],
      company: companies[companyIndex],
      scale: 10.0 + (i % 200) * 0.5,
      date: '${2018 + (i % 7)}-${((i % 12) + 1).toString().padLeft(2, '0')}-01',
      return1Y: -20.0 + (i % 80),
      return3Y: -15.0 + (i % 60),
      dailyReturn: -3.0 + (i % 10) * 0.5,
      riskLevel: riskLevels[riskIndex],
      status: i % 20 == 0 ? '暂停' : '正常',
      lastUpdate: DateTime.now().subtract(Duration(days: i % 365)),
    ));
  }

  return funds;
}

/// 计算一致性（响应时间的稳定性）
double _calculateConsistency(List<int> measurements) {
  if (measurements.isEmpty) return 0.0;

  final mean = measurements.reduce((a, b) => a + b) / measurements.length;
  final variance =
      measurements.map((m) => (m - mean) * (m - mean)).reduce((a, b) => a + b) /
          measurements.length;
  final stdDev = sqrt(variance);

  // 一致性 = 1 - (标准差 / 平均值)，值越接近1越好
  return mean > 0 ? (1 - stdDev / mean).clamp(0.0, 1.0) : 0.0;
}

/// 计算可靠性（在要求时间内完成的比例）
double _calculateReliability(List<int> measurements) {
  if (measurements.isEmpty) return 0.0;

  const threshold = 300; // 300ms阈值
  final reliableCount = measurements.where((m) => m <= threshold).length;

  return reliableCount / measurements.length;
}

/// 计算满意度评分（0-5分）
double _calculateSatisfactionScore(
    double avgTime, double consistency, double reliability) {
  // 响应时间评分（0-2分）
  double timeScore;
  if (avgTime <= 50) {
    timeScore = 2.0;
  } else if (avgTime <= 100) {
    timeScore = 1.5;
  } else if (avgTime <= 200) {
    timeScore = 1.0;
  } else if (avgTime <= 300) {
    timeScore = 0.5;
  } else {
    timeScore = 0.0;
  }

  // 一致性评分（0-1.5分）
  final consistencyScore = consistency * 1.5;

  // 可靠性评分（0-1.5分）
  final reliabilityScore = reliability * 1.5;

  return (timeScore + consistencyScore + reliabilityScore).clamp(0.0, 5.0);
}

/// 获取感知等级的emoji
String _getPerceptionEmoji(PerceptionLevel perception) {
  switch (perception) {
    case PerceptionLevel.instant:
      return '⚡';
    case PerceptionLevel.fast:
      return '🚀';
    case PerceptionLevel.acceptable:
      return '✅';
    case PerceptionLevel.slow:
      return '⏱️';
    case PerceptionLevel.unacceptable:
      return '❌';
  }
}

// 辅助类定义
class UserOperation {
  final String name;
  final FundFilterCriteria Function() criteriaBuilder;

  UserOperation(this.name, this.criteriaBuilder);
}

class UserExperienceResult {
  final String name;
  final double avgTime;
  final int minTime;
  final int maxTime;
  final PerceptionLevel perception;

  UserExperienceResult({
    required this.name,
    required this.avgTime,
    required this.minTime,
    required this.maxTime,
    required this.perception,
  });
}

enum PerceptionLevel {
  instant,
  fast,
  acceptable,
  slow,
  unacceptable,
}

class SequenceOperationResult {
  final int step;
  final int responseTime;
  final int resultCount;
  final bool isSmooth;

  SequenceOperationResult({
    required this.step,
    required this.responseTime,
    required this.resultCount,
    required this.isSmooth,
  });
}

class ProgressiveStep {
  final String name;
  final FundFilterCriteria Function() criteriaBuilder;

  ProgressiveStep(this.name, this.criteriaBuilder);
}

class ProgressiveResult {
  final String stepName;
  final int stepNumber;
  final int responseTime;
  final int resultCount;
  final bool isAcceptable;

  ProgressiveResult({
    required this.stepName,
    required this.stepNumber,
    required this.responseTime,
    required this.resultCount,
    required this.isAcceptable,
  });
}

class ErrorScenario {
  final String name;
  final FundFilterCriteria Function() criteriaBuilder;
  final String expectation;

  ErrorScenario(this.name, this.criteriaBuilder, this.expectation);
}

class ErrorHandlingResult {
  final String scenarioName;
  final bool completed;
  final int responseTime;
  final bool hasError;
  final String? errorMessage;
  final bool expectationMet;

  ErrorHandlingResult({
    required this.scenarioName,
    required this.completed,
    required this.responseTime,
    required this.hasError,
    this.errorMessage,
    required this.expectationMet,
  });
}

class SatisfactionScenario {
  final String name;
  final FundFilterCriteria Function() criteriaBuilder;

  SatisfactionScenario(this.name, this.criteriaBuilder);
}

class SatisfactionResult {
  final String scenarioName;
  final double avgResponseTime;
  final double consistency;
  final double reliability;
  final double score;

  SatisfactionResult({
    required this.scenarioName,
    required this.avgResponseTime,
    required this.consistency,
    required this.reliability,
    required this.score,
  });
}
