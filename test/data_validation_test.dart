import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';

import 'package:jisu_fund_analyzer/src/features/fund/shared/services/data_validation_service.dart';
import 'package:jisu_fund_analyzer/src/features/fund/shared/services/fund_data_service.dart';
import 'package:jisu_fund_analyzer/src/features/fund/shared/models/fund_ranking.dart';
import 'package:jisu_fund_analyzer/src/core/cache/hive_cache_manager.dart';

/// 数据验证服务测试
void main() {
  // 初始化测试环境
  TestWidgetsFlutterBinding.ensureInitialized();
  group('数据验证功能测试', () {
    late DataValidationService validationService;
    late FundDataService fundDataService;
    late HiveCacheManager cacheManager;

    setUpAll(() async {
      // 初始化测试环境
      cacheManager = HiveCacheManager.instance;
      fundDataService = FundDataService(cacheManager: cacheManager);
      validationService = DataValidationService(
        cacheManager: cacheManager,
        fundDataService: fundDataService,
      );
    });

    test('应该能够正常创建DataValidationService实例', () {
      expect(validationService, isNotNull);
    });

    test('应该能够验证有效的基金数据', () async {
      // 创建有效的基金数据
      final validFunds = [
        FundRanking(
          fundCode: '005827',
          fundName: '易方达蓝筹精选混合',
          fundType: '混合型',
          rank: 1,
          nav: 1.525,
          dailyReturn: 0.015,
          oneYearReturn: 0.25,
          threeYearReturn: 0.45,
          fundSize: 50.25,
          updateDate: DateTime.now().subtract(const Duration(days: 1)),
          fundCompany: '易方达基金',
          fundManager: '张三',
        ),
        FundRanking(
          fundCode: '110022',
          fundName: '易方达消费行业股票',
          fundType: '股票型',
          rank: 2,
          nav: 2.125,
          dailyReturn: 0.012,
          oneYearReturn: 0.35,
          threeYearReturn: 0.65,
          fundSize: 120.5,
          updateDate: DateTime.now().subtract(const Duration(days: 2)),
          fundCompany: '易方达基金',
          fundManager: '萧楠',
        ),
      ];

      // 验证数据
      final result = await validationService.validateFundRankings(
        validFunds,
        strategy: ConsistencyCheckStrategy.standard,
      );

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
      expect(result.warnings, isEmpty);
    });

    test('应该能够检测数据为空的情况', () async {
      final emptyFunds = <FundRanking>[];

      final result = await validationService.validateFundRankings(
        emptyFunds,
        strategy: ConsistencyCheckStrategy.standard,
      );

      expect(result.isValid, isFalse);
      expect(result.errors, contains('数据为空'));
    });

    test('应该能够检测必填字段缺失的情况', () async {
      final invalidFunds = [
        FundRanking(
          fundCode: '', // 缺失基金代码
          fundName: '测试基金',
          fundType: '混合型',
          rank: 1,
          nav: 1.0,
          dailyReturn: 0.01,
          oneYearReturn: 0.15,
          threeYearReturn: 0.25,
          fundSize: 10.0,
          updateDate: DateTime.now(),
          fundCompany: '测试公司',
          fundManager: '测试经理',
        ),
        FundRanking(
          fundCode: 'TEST001',
          fundName: '', // 缺失基金名称
          fundType: '股票型',
          rank: 2,
          nav: 0.5, // 异常净值
          dailyReturn: 0.01,
          oneYearReturn: 0.15,
          threeYearReturn: 0.25,
          fundSize: 10.0,
          updateDate: DateTime.now(),
          fundCompany: '测试公司',
          fundManager: '测试经理',
        ),
      ];

      final result = await validationService.validateFundRankings(
        invalidFunds,
        strategy: ConsistencyCheckStrategy.standard,
      );

      expect(result.isValid, isFalse);
      expect(result.errors.length, greaterThan(1));
      expect(result.errors.any((e) => e.contains('基金代码为空')), isTrue);
      expect(result.errors.any((e) => e.contains('基金名称为空')), isTrue);
      expect(result.errors.any((e) => e.contains('净值异常')), isTrue);
    });

    test('应该能够检测重复的基金代码', () async {
      final duplicateFunds = [
        FundRanking(
          fundCode: 'DUPLICATE001',
          fundName: '基金A',
          fundType: '混合型',
          rank: 1,
          nav: 1.0,
          dailyReturn: 0.01,
          oneYearReturn: 0.15,
          threeYearReturn: 0.25,
          fundSize: 10.0,
          updateDate: DateTime.now(),
          fundCompany: '公司A',
          fundManager: '经理A',
        ),
        FundRanking(
          fundCode: 'DUPLICATE001', // 重复的基金代码
          fundName: '基金B',
          fundType: '股票型',
          rank: 2,
          nav: 1.2,
          dailyReturn: 0.02,
          oneYearReturn: 0.25,
          threeYearReturn: 0.35,
          fundSize: 20.0,
          updateDate: DateTime.now(),
          fundCompany: '公司B',
          fundManager: '经理B',
        ),
      ];

      final result = await validationService.validateFundRankings(
        duplicateFunds,
        strategy: ConsistencyCheckStrategy.standard,
      );

      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('重复的基金代码')), isTrue);
      expect(result.errors.any((e) => e.contains('DUPLICATE001')), isTrue);
    });

    test('应该能够检测异常的收益率', () async {
      final abnormalFunds = [
        FundRanking(
          fundCode: 'ABNORMAL001',
          fundName: '异常基金',
          fundType: '混合型',
          rank: 1,
          nav: 1.0,
          dailyReturn: 5.0, // 异常高的日收益率
          oneYearReturn: 15.0, // 异常高的年收益率
          threeYearReturn: 30.0, // 异常高的三年收益率
          fundSize: 10.0,
          updateDate: DateTime.now(),
          fundCompany: '测试公司',
          fundManager: '测试经理',
        ),
      ];

      final result = await validationService.validateFundRankings(
        abnormalFunds,
        strategy: ConsistencyCheckStrategy.standard,
      );

      expect(result.isValid, isTrue); // 收益率异常只产生警告，不导致验证失败
      expect(result.warnings.length, greaterThan(0));
      expect(result.warnings.any((e) => e.contains('日收益率异常')), isTrue);
      expect(result.warnings.any((e) => e.contains('年收益率异常')), isTrue);
    });

    test('应该能够修复损坏的数据', () async {
      final corruptedFunds = [
        FundRanking(
          fundCode: '', // 损坏：基金代码为空
          fundName: '', // 损坏：基金名称为空
          fundType: '', // 损坏：基金类型为空
          rank: -1, // 损坏：无效排名
          nav: 0.0, // 损坏：无效净值
          dailyReturn: 0.0,
          oneYearReturn: 0.0,
          threeYearReturn: 0.0,
          fundSize: 0.0, // 损坏：无效规模
          updateDate: DateTime.fromMillisecondsSinceEpoch(0), // 损坏：无效日期
          fundCompany: '', // 损坏：公司为空
          fundManager: '', // 损坏：经理为空
        ),
      ];

      final repairedData =
          await validationService.repairCorruptedData(corruptedFunds);

      expect(repairedData, isNotNull);
      expect(repairedData!.length, 1);

      final repairedFund = repairedData.first;
      expect(repairedFund.fundCode, isNotEmpty);
      expect(repairedFund.fundName, isNotEmpty);
      expect(repairedFund.fundType, isNotEmpty);
      expect(repairedFund.rank, greaterThan(0));
      expect(repairedFund.nav, greaterThan(0));
      expect(repairedFund.fundSize, greaterThan(0));
      expect(repairedFund.updateDate, isNotNull);
      expect(repairedFund.fundCompany, isNotEmpty);
      expect(repairedFund.fundManager, isNotEmpty);
    });

    test('应该能够获取数据质量统计信息', () {
      final stats = validationService.getDataQualityStatistics();

      expect(stats, isA<Map<String, dynamic>>());
      expect(stats.containsKey('totalValidations'), isTrue);
      expect(stats.containsKey('successRate'), isTrue);
      expect(stats.containsKey('averageErrors'), isTrue);
      expect(stats.containsKey('averageWarnings'), isTrue);
    });

    test('应该能够获取验证历史记录', () {
      final history = validationService.getValidationHistory(limit: 5);

      expect(history, isA<List<DataValidationResult>>());
      expect(history.length, lessThanOrEqualTo(5));
    });

    test('应该能够清空验证历史记录', () {
      validationService.clearValidationHistory();
      final history = validationService.getValidationHistory();
      expect(history, isEmpty);
    });

    test('快速检查策略应该比标准检查策略更宽松', () async {
      final fundsWithWarnings = [
        FundRanking(
          fundCode: 'WARNING001',
          fundName: '警告基金',
          fundType: '混合型',
          rank: 1,
          nav: 1.0,
          dailyReturn: 3.0, // 高收益率，会产生警告
          oneYearReturn: 0.15,
          threeYearReturn: 0.25,
          fundSize: 10.0,
          updateDate:
              DateTime.now().subtract(const Duration(days: 10)), // 较旧的日期
          fundCompany: '测试公司',
          fundManager: '测试经理',
        ),
      ];

      // 快速检查应该通过（因为只检查基本结构）
      final quickResult = await validationService.validateFundRankings(
        fundsWithWarnings,
        strategy: ConsistencyCheckStrategy.quick,
      );
      expect(quickResult.isValid, isTrue);

      // 标准检查也应该通过，但会有警告
      final standardResult = await validationService.validateFundRankings(
        fundsWithWarnings,
        strategy: ConsistencyCheckStrategy.standard,
      );
      expect(standardResult.isValid, isTrue);
      expect(standardResult.hasWarnings, isTrue);
    });

    test('应该能够正确处理DataValidationResult的创建', () {
      // 测试成功结果
      final successResult = DataValidationResult.success();
      expect(successResult.isValid, isTrue);
      expect(successResult.hasErrors, isFalse);
      expect(successResult.hasWarnings, isFalse);
      expect(successResult.severityDescription, '数据验证通过');

      // 测试失败结果
      final failureResult = DataValidationResult.failure(['错误1', '错误2']);
      expect(failureResult.isValid, isFalse);
      expect(failureResult.hasErrors, isTrue);
      expect(failureResult.hasWarnings, isFalse);
      expect(failureResult.severityDescription, '数据验证失败');

      // 测试警告结果
      final warningResult = DataValidationResult.warning(['警告1', '警告2']);
      expect(warningResult.isValid, isTrue);
      expect(warningResult.hasErrors, isFalse);
      expect(warningResult.hasWarnings, isTrue);
      expect(warningResult.severityDescription, '数据存在警告');
    });

    test('应该能够正确格式化DataValidationResult的字符串表示', () {
      final result = DataValidationResult.failure(['测试错误'], warnings: ['测试警告']);
      final resultString = result.toString();

      expect(resultString, contains('DataValidationResult'));
      expect(resultString, contains('isValid: false'));
      expect(resultString, contains('hasErrors: true'));
      expect(resultString, contains('hasWarnings: true'));
      expect(resultString, contains('测试错误'));
      expect(resultString, contains('测试警告'));
    });
  });

  group('FundDataService集成测试', () {
    late FundDataService fundDataService;

    setUpAll(() async {
      fundDataService = FundDataService();
    });

    test('应该能够获取数据质量统计信息', () {
      final stats = fundDataService.getDataQualityStats();

      expect(stats, isA<Map<String, dynamic>>());
      expect(stats.containsKey('totalValidations'), isTrue);
      expect(stats.containsKey('successRate'), isTrue);
    });

    test('应该能够获取验证历史记录', () {
      final history = fundDataService.getValidationHistory(limit: 5);

      expect(history, isA<List<DataValidationResult>>());
      expect(history.length, lessThanOrEqualTo(5));
    });

    test('应该能够验证当前缓存数据', () async {
      final result = await fundDataService.validateCurrentData();

      expect(result, isA<DataValidationResult>());
      // 如果没有缓存数据，应该返回成功结果
      expect(result.isValid, isTrue);
    });

    test('应该能够验证并修复所有缓存', () async {
      final results = await fundDataService.validateAndRepairAllCaches();

      expect(results, isA<Map<String, dynamic>>());
      // 应该包含结果或错误信息
      expect(results.isNotEmpty, isTrue);
    });

    test('应该能够验证数据一致性', () async {
      final testFunds = [
        FundRanking(
          fundCode: 'CONSISTENCY001',
          fundName: '一致性测试基金',
          fundType: '混合型',
          rank: 1,
          nav: 1.5,
          dailyReturn: 0.02,
          oneYearReturn: 0.25,
          threeYearReturn: 0.45,
          fundSize: 50.0,
          updateDate: DateTime.now(),
          fundCompany: '测试公司',
          fundManager: '测试经理',
        ),
      ];

      final result = await fundDataService.validateDataConsistency(testFunds);

      expect(result, isA<DataValidationResult>());
      expect(result.isValid, isTrue);
    });

    test('应该能够修复数据', () async {
      final corruptedFunds = [
        FundRanking(
          fundCode: '', // 损坏的基金代码
          fundName: '损坏基金',
          fundType: '混合型',
          rank: 1,
          nav: 1.0,
          dailyReturn: 0.01,
          oneYearReturn: 0.15,
          threeYearReturn: 0.25,
          fundSize: 10.0,
          updateDate: DateTime.now(),
          fundCompany: '测试公司',
          fundManager: '测试经理',
        ),
      ];

      final repairedData = await fundDataService.repairData(corruptedFunds);

      expect(repairedData, isNotNull);
      if (repairedData != null) {
        expect(repairedData.length, 1);
        expect(repairedData.first.fundCode, isNotEmpty);
      }
    });
  });
}
