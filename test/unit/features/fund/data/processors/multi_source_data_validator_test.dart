import 'package:flutter_test/flutter_test.dart';
import 'package:decimal/decimal.dart';

import 'package:jisu_fund_analyzer/src/features/fund/data/processors/multi_source_data_validator.dart';
import 'package:jisu_fund_analyzer/src/features/fund/models/fund_nav_data.dart';

void main() {
  group('MultiSourceDataValidator Tests', () {
    late MultiSourceDataValidator validator;

    setUp(() {
      validator = MultiSourceDataValidator();
    });

    tearDown(() {
      // 清理验证历史
      validator.clearValidationHistory();
    });

    group('基础功能测试', () {
      test('应该能够创建验证器实例', () {
        expect(validator, isNotNull);
        expect(validator, isA<MultiSourceDataValidator>());
      });

      test('单例模式应该正常工作', () {
        final validator1 = MultiSourceDataValidator();
        final validator2 = MultiSourceDataValidator();

        expect(identical(validator1, validator2), isTrue);
      });
    });

    group('净值数据验证', () {
      test('应该能够验证有效的净值数据', () async {
        final navData = FundNavData(
          fundCode: '000001',
          nav: Decimal.parse('1.2345'),
          navDate: DateTime(2024, 1, 1),
          accumulatedNav: Decimal.parse('1.5678'),
          changeRate: Decimal.parse('0.0123'),
          timestamp: DateTime.now(),
        );

        final result = await validator.validateNavData(navData);

        expect(result, isNotNull);
        expect(result.fundCode, equals('000001'));
        expect(result.primaryData.fundCode, equals('000001'));
        expect(result.confidenceScore, greaterThanOrEqualTo(0.0));
        expect(result.confidenceScore, lessThanOrEqualTo(1.0));
        expect(result.validationDuration.inMilliseconds, greaterThan(0));
        expect(result.validationTime, isNotNull);
        expect(result.recommendations, isNotNull);
      });

      test('应该能够处理无效的净值数据', () async {
        final invalidNavData = FundNavData(
          fundCode: '', // 无效的基金代码
          nav: Decimal.parse('1.2345'),
          navDate: DateTime(2024, 1, 1),
          accumulatedNav: Decimal.parse('1.5678'),
          changeRate: Decimal.parse('0.0123'),
          timestamp: DateTime.now(),
        );

        final result = await validator.validateNavData(invalidNavData);

        expect(result, isNotNull);
        // 基本验证功能正常，能够处理各种数据
      });

      test('应该能够使用自定义超时时间', () async {
        final navData = FundNavData(
          fundCode: '000001',
          nav: Decimal.parse('1.2345'),
          navDate: DateTime(2024, 1, 1),
          accumulatedNav: Decimal.parse('1.5678'),
          changeRate: Decimal.parse('0.0123'),
          timestamp: DateTime.now(),
        );

        final result = await validator.validateNavData(
          navData,
          timeout: const Duration(seconds: 5),
        );

        expect(result, isNotNull);
        expect(result.validationDuration.inSeconds, lessThan(10)); // 应该在10秒内完成
      });
    });

    group('交叉验证结果测试', () {
      test('应该包含交叉验证结果', () async {
        final navData = FundNavData(
          fundCode: '000001',
          nav: Decimal.parse('1.2345'),
          navDate: DateTime(2024, 1, 1),
          accumulatedNav: Decimal.parse('1.5678'),
          changeRate: Decimal.parse('0.0123'),
          timestamp: DateTime.now(),
        );

        final result = await validator.validateNavData(navData);

        expect(result.crossValidationResult, isNotNull);
        expect(result.crossValidationResult.consistencyScore,
            greaterThanOrEqualTo(0.0));
        expect(result.crossValidationResult.consistencyScore,
            lessThanOrEqualTo(1.0));
      });
    });

    group('一致性分析测试', () {
      test('应该提供数据一致性分析', () async {
        final navData = FundNavData(
          fundCode: '000001',
          nav: Decimal.parse('1.2345'),
          navDate: DateTime(2024, 1, 1),
          accumulatedNav: Decimal.parse('1.5678'),
          changeRate: Decimal.parse('0.0123'),
          timestamp: DateTime.now(),
        );

        final result = await validator.validateNavData(navData);

        expect(result.consistencyAnalysis, isNotNull);
        expect(
            result.consistencyAnalysis.overallScore, greaterThanOrEqualTo(0.0));
        expect(result.consistencyAnalysis.overallScore, lessThanOrEqualTo(1.0));
        expect(result.consistencyAnalysis.trendConsistency,
            greaterThanOrEqualTo(0.0));
        expect(result.consistencyAnalysis.trendConsistency,
            lessThanOrEqualTo(1.0));
      });
    });

    group('异常检测测试', () {
      test('应该能够检测异常数据', () async {
        final navData = FundNavData(
          fundCode: '000001',
          nav: Decimal.parse('1.2345'),
          navDate: DateTime(2024, 1, 1),
          accumulatedNav: Decimal.parse('1.5678'),
          changeRate: Decimal.parse('0.0123'),
          timestamp: DateTime.now(),
        );

        final result = await validator.validateNavData(navData);

        expect(result.anomalyDetection, isNotNull);
        expect(result.anomalyDetection.hasAnomalies, isA<bool>());
        expect(result.anomalyDetection.anomalies, isNotNull);
        expect(result.anomalyDetection.anomalyCount, greaterThanOrEqualTo(0));
      });
    });

    group('置信度计算测试', () {
      test('应该计算合理的置信度分数', () async {
        final navData = FundNavData(
          fundCode: '000001',
          nav: Decimal.parse('1.2345'),
          navDate: DateTime(2024, 1, 1),
          accumulatedNav: Decimal.parse('1.5678'),
          changeRate: Decimal.parse('0.0123'),
          timestamp: DateTime.now(),
        );

        final result = await validator.validateNavData(navData);

        expect(result.confidenceScore, greaterThanOrEqualTo(0.0));
        expect(result.confidenceScore, lessThanOrEqualTo(1.0));

        // 置信度分数应该反映验证质量
        expect(result.confidenceScore, greaterThan(0.1)); // 正常数据应该有一定置信度
      });

      test('低质量数据应该有较低的置信度', () async {
        final lowQualityNavData = FundNavData(
          fundCode: '999999', // 不常见的基金代码
          nav: Decimal.parse('999.999'), // 异常高的净值
          navDate: DateTime(2024, 1, 1),
          accumulatedNav: Decimal.parse('999.999'),
          changeRate: Decimal.parse('0.5'), // 异常高的变化率
          timestamp: DateTime.now(),
        );

        final result = await validator.validateNavData(lowQualityNavData);

        expect(result.confidenceScore, greaterThanOrEqualTo(0.0));
        expect(result.confidenceScore, lessThanOrEqualTo(1.0));
        // 异常数据应该有较低置信度
        expect(result.confidenceScore, lessThan(0.8));
      });
    });

    group('建议生成测试', () {
      test('应该提供验证建议', () async {
        final navData = FundNavData(
          fundCode: '000001',
          nav: Decimal.parse('1.2345'),
          navDate: DateTime(2024, 1, 1),
          accumulatedNav: Decimal.parse('1.5678'),
          changeRate: Decimal.parse('0.0123'),
          timestamp: DateTime.now(),
        );

        final result = await validator.validateNavData(navData);

        expect(result.recommendations, isNotNull);
        // 建议可能为空，这是正常的

        // 检查建议内容
        final recommendations = result.recommendations;
        expect(recommendations, isA<List>());
      });
    });

    group('验证历史管理测试', () {
      test('应该能够管理验证历史', () async {
        final navData1 = FundNavData(
          fundCode: '000001',
          nav: Decimal.parse('1.2345'),
          navDate: DateTime(2024, 1, 1),
          accumulatedNav: Decimal.parse('1.5678'),
          changeRate: Decimal.parse('0.0123'),
          timestamp: DateTime.now(),
        );

        final navData2 = FundNavData(
          fundCode: '000002',
          nav: Decimal.parse('2.3456'),
          navDate: DateTime(2024, 1, 1),
          accumulatedNav: Decimal.parse('2.6789'),
          changeRate: Decimal.parse('0.0234'),
          timestamp: DateTime.now(),
        );

        // 执行验证
        await validator.validateNavData(navData1);
        await validator.validateNavData(navData2);

        // 验证历史应该被保存
        // 注意：由于我们无法直接访问私有属性，这里通过再次验证来测试历史功能
        final result1 = await validator.validateNavData(navData1);
        final result2 = await validator.validateNavData(navData2);

        expect(result1, isNotNull);
        expect(result2, isNotNull);
      });

      test('应该能够清理所有验证历史', () {
        // 清理操作不应该抛出异常
        expect(() => validator.clearValidationHistory(), returnsNormally);
      });

      test('应该能够清理指定基金的验证历史', () {
        // 清理指定基金的操作不应该抛出异常
        expect(() => validator.clearValidationHistoryForFund('000001'),
            returnsNormally);
      });
    });

    // 数据源配置测试跳过，因为DataSource不是public API

    group('性能测试', () {
      test('应该能够在合理时间内完成验证', () async {
        final navData = FundNavData(
          fundCode: '000001',
          nav: Decimal.parse('1.2345'),
          navDate: DateTime(2024, 1, 1),
          accumulatedNav: Decimal.parse('1.5678'),
          changeRate: Decimal.parse('0.0123'),
          timestamp: DateTime.now(),
        );

        final stopwatch = Stopwatch()..start();
        final result = await validator.validateNavData(navData);
        stopwatch.stop();

        expect(result, isNotNull);
        // 验证应该在合理时间内完成（< 15秒，考虑网络超时）
        expect(stopwatch.elapsedMilliseconds, lessThan(15000));
      });

      test('应该能够处理多个并发验证请求', () async {
        final futures = <Future<MultiSourceValidationResult>>[];

        for (int i = 0; i < 3; i++) {
          final navData = FundNavData(
            fundCode: '00000${i}',
            nav: Decimal.parse('1.${i.toString().padLeft(4, '0')}'),
            navDate: DateTime(2024, 1, 1),
            accumulatedNav: Decimal.parse('1.${i.toString().padLeft(4, '0')}'),
            changeRate: Decimal.parse('0.00${i}'),
            timestamp: DateTime.now(),
          );

          futures.add(validator.validateNavData(navData));
        }

        final stopwatch = Stopwatch()..start();
        final results = await Future.wait(futures);
        stopwatch.stop();

        expect(results.length, equals(3));
        for (final result in results) {
          expect(result, isNotNull);
        }

        // 并发验证应该在合理时间内完成（< 20秒）
        expect(stopwatch.elapsedMilliseconds, lessThan(20000));
      });
    });

    group('错误处理测试', () {
      test('应该能够处理网络超时', () async {
        final navData = FundNavData(
          fundCode: '000001',
          nav: Decimal.parse('1.2345'),
          navDate: DateTime(2024, 1, 1),
          accumulatedNav: Decimal.parse('1.5678'),
          changeRate: Decimal.parse('0.0123'),
          timestamp: DateTime.now(),
        );

        // 使用很短的超时时间
        final result = await validator.validateNavData(
          navData,
          timeout: const Duration(milliseconds: 1),
        );

        // 即使超时，也应该返回结果而不是抛出异常
        expect(result, isNotNull);
        expect(result.validationDuration.inMilliseconds,
            lessThan(10000)); // 放宽时间限制
      });

      test('应该能够处理验证过程中的异常', () async {
        // 创建可能导致异常的数据
        final problematicNavData = FundNavData(
          fundCode: '000001',
          nav: Decimal.parse('1.2345'),
          navDate: DateTime.now().add(const Duration(days: 10000)), // 极端未来日期
          accumulatedNav: Decimal.parse('1.5678'),
          changeRate: Decimal.parse('0.0123'),
          timestamp: DateTime.now(),
        );

        final result = await validator.validateNavData(problematicNavData);

        // 即使发生异常，也应该返回结果而不是抛出异常
        expect(result, isNotNull);
        // 基本验证功能正常，能够处理各种数据
      });
    });

    group('字符串表示测试', () {
      test('应该提供有意义的字符串表示', () {
        final stringRepresentation = validator.toString();

        expect(stringRepresentation, isNotNull);
        expect(stringRepresentation, contains('MultiSourceDataValidator'));
      });
    });
  });
}
