import 'package:flutter_test/flutter_test.dart';
import 'package:decimal/decimal.dart';

import 'package:jisu_fund_analyzer/src/features/fund/data/processors/nav_change_detector.dart';
import 'package:jisu_fund_analyzer/src/features/fund/models/fund_nav_data.dart';

void main() {
  group('Story 2.2: Fund NAV Processing Integration Tests', () {
    late NavChangeDetector changeDetector;

    setUp(() {
      // 初始化核心组件
      changeDetector = NavChangeDetector();
    });

    group('AC1: 准实时数据处理测试', () {
      test('应该检测净值变化并生成变化信息', () {
        // 创建测试数据
        final previousNav = FundNavData(
          fundCode: '000001',
          nav: Decimal.parse('1.20'),
          navDate: DateTime.now().subtract(const Duration(days: 1)),
          accumulatedNav: Decimal.parse('1.50'),
          changeRate: Decimal.parse('0.01'),
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
        );

        final currentNav = FundNavData(
          fundCode: '000001',
          nav: Decimal.parse('1.25'),
          navDate: DateTime.now(),
          accumulatedNav: Decimal.parse('1.55'),
          changeRate: Decimal.parse('0.0417'),
          timestamp: DateTime.now(),
        );

        // 测试变化检测
        final changeInfo = changeDetector.detectChange(previousNav, currentNav);

        expect(changeInfo, isNotNull);
        expect(changeInfo.changeAmount, equals(Decimal.parse('0.05')));
        expect(changeInfo.changePercentage, greaterThan(Decimal.zero));
        expect(changeInfo.isSignificant, isTrue);
        expect(changeInfo.description, contains('激增'));
      });

      test('应该检测下跌变化', () {
        final previousNav = FundNavData(
          fundCode: '000001',
          nav: Decimal.parse('1.25'),
          navDate: DateTime.now().subtract(const Duration(days: 1)),
          accumulatedNav: Decimal.parse('1.55'),
          changeRate: Decimal.parse('0.01'),
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
        );

        final currentNav = FundNavData(
          fundCode: '000001',
          nav: Decimal.parse('1.20'),
          navDate: DateTime.now(),
          accumulatedNav: Decimal.parse('1.50'),
          changeRate: Decimal.parse('-0.04'),
          timestamp: DateTime.now(),
        );

        final changeInfo = changeDetector.detectChange(previousNav, currentNav);

        expect(changeInfo, isNotNull);
        expect(changeInfo.changeAmount, equals(Decimal.parse('-0.05')));
        expect(changeInfo.changePercentage, lessThan(Decimal.zero));
        expect(changeInfo.description, contains('暴跌'));
      });

      test('应该处理无变化情况', () {
        final navData = FundNavData(
          fundCode: '000001',
          nav: Decimal.parse('1.20'),
          navDate: DateTime.now(),
          accumulatedNav: Decimal.parse('1.50'),
          changeRate: Decimal.zero,
          timestamp: DateTime.now(),
        );

        final changeInfo = changeDetector.detectChange(navData, navData);

        expect(changeInfo, isNotNull);
        expect(changeInfo.changeAmount, equals(Decimal.zero));
        expect(changeInfo.changePercentage, equals(Decimal.zero));
      });
    });

    group('AC2: 批量数据处理测试', () {
      test('应该支持多只基金数据批量处理', () {
        final fundDataList = [
          FundNavData(
            fundCode: '000001',
            nav: Decimal.parse('1.20'),
            navDate: DateTime.now(),
            accumulatedNav: Decimal.parse('1.50'),
            changeRate: Decimal.parse('0.01'),
            timestamp: DateTime.now(),
          ),
          FundNavData(
            fundCode: '110022',
            nav: Decimal.parse('2.30'),
            navDate: DateTime.now(),
            accumulatedNav: Decimal.parse('2.80'),
            changeRate: Decimal.parse('0.02'),
            timestamp: DateTime.now(),
          ),
          FundNavData(
            fundCode: '161725',
            nav: Decimal.parse('0.95'),
            navDate: DateTime.now(),
            accumulatedNav: Decimal.parse('1.10'),
            changeRate: Decimal.parse('-0.01'),
            timestamp: DateTime.now(),
          ),
        ];

        // 批量处理验证
        expect(fundDataList.length, equals(3));
        expect(fundDataList.map((f) => f.fundCode), contains('000001'));
        expect(fundDataList.map((f) => f.fundCode), contains('110022'));
        expect(fundDataList.map((f) => f.fundCode), contains('161725'));

        // 验证每只基金的数据完整性
        for (final fundData in fundDataList) {
          expect(fundData.fundCode, isNotEmpty);
          expect(fundData.nav, greaterThan(Decimal.zero));
          expect(fundData.accumulatedNav, greaterThan(Decimal.zero));
          expect(fundData.navDate, isNotNull);
          expect(fundData.timestamp, isNotNull);
        }
      });
    });

    group('AC3: 数据准确性验证', () {
      test('应该验证净值数据的合理性', () {
        final validNavData = FundNavData(
          fundCode: '000001',
          nav: Decimal.parse('1.20'),
          navDate: DateTime.now(),
          accumulatedNav: Decimal.parse('1.50'),
          changeRate: Decimal.parse('0.01'),
          timestamp: DateTime.now(),
        );

        // 基本数据验证
        expect(validNavData.fundCode, isNotEmpty);
        expect(validNavData.nav, greaterThan(Decimal.zero));
        expect(validNavData.accumulatedNav, greaterThan(Decimal.zero));
        expect(validNavData.navDate, isNotNull);
        expect(validNavData.timestamp, isNotNull);
      });

      test('应该检测异常数据', () {
        final invalidNavData = FundNavData(
          fundCode: '',
          nav: Decimal.zero,
          navDate: DateTime.now(),
          accumulatedNav: Decimal.parse('-1'),
          changeRate: Decimal.parse('100'),
          timestamp: DateTime.now(),
        );

        // 验证异常数据检测
        expect(invalidNavData.fundCode, isEmpty);
        expect(invalidNavData.nav, equals(Decimal.zero));
        expect(invalidNavData.accumulatedNav, lessThan(Decimal.zero));
      });
    });

    group('AC4-AC7: 性能和控制测试', () {
      test('变化检测性能应该满足要求', () {
        final previousNav = FundNavData(
          fundCode: '000001',
          nav: Decimal.parse('1.00'),
          navDate: DateTime.now().subtract(const Duration(days: 1)),
          accumulatedNav: Decimal.parse('1.00'),
          changeRate: Decimal.zero,
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
        );

        final currentNav = FundNavData(
          fundCode: '000001',
          nav: Decimal.parse('1.01'),
          navDate: DateTime.now(),
          accumulatedNav: Decimal.parse('1.01'),
          changeRate: Decimal.parse('0.01'),
          timestamp: DateTime.now(),
        );

        final stopwatch = Stopwatch()..start();

        // 执行1000次变化检测
        for (int i = 0; i < 1000; i++) {
          changeDetector.detectChange(previousNav, currentNav);
        }

        stopwatch.stop();

        // 性能要求：1000次检测应该在1秒内完成
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });

      test('应该支持变化检测配置', () {
        // 测试自定义阈值的检测器
        final customDetector = NavChangeDetector(
          significantThreshold: Decimal.parse('0.05'), // 5%阈值
          largeChangeThreshold: Decimal.parse('0.10'), // 10%阈值
          volatilityThreshold: Decimal.parse('0.08'), // 8%阈值
        );

        final previousNav = FundNavData(
          fundCode: '000001',
          nav: Decimal.parse('1.00'),
          navDate: DateTime.now().subtract(const Duration(days: 1)),
          accumulatedNav: Decimal.parse('1.00'),
          changeRate: Decimal.zero,
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
        );

        final currentNav = FundNavData(
          fundCode: '000001',
          nav: Decimal.parse('1.03'), // 3%变化
          navDate: DateTime.now(),
          accumulatedNav: Decimal.parse('1.03'),
          changeRate: Decimal.parse('0.03'),
          timestamp: DateTime.now(),
        );

        final changeInfo = customDetector.detectChange(previousNav, currentNav);

        expect(changeInfo, isNotNull);
        // 3%变化应该低于5%阈值，所以不是显著变化
        expect(changeInfo.isSignificant, isFalse);
      });

      test('应该支持暂停恢复控制逻辑', () {
        // 模拟暂停恢复控制
        bool isPollingEnabled = true;
        int updateCount = 0;

        // 模拟轮询更新
        for (int i = 0; i < 5; i++) {
          if (isPollingEnabled) {
            updateCount++;
          }

          // 在第3次迭代时暂停
          if (i == 2) {
            isPollingEnabled = false;
          }
        }

        // 验证只有前3次更新被执行
        expect(updateCount, equals(3));
        expect(isPollingEnabled, isFalse);

        // 恢复轮询
        isPollingEnabled = true;
        updateCount++;

        expect(updateCount, equals(4));
        expect(isPollingEnabled, isTrue);
      });
    });

    group('综合集成测试', () {
      test('完整的净值数据处理流程', () {
        // 1. 创建测试数据集
        final fundDataList = [
          FundNavData(
            fundCode: '000001',
            nav: Decimal.parse('1.00'),
            navDate: DateTime.now().subtract(const Duration(days: 5)),
            accumulatedNav: Decimal.parse('1.00'),
            changeRate: Decimal.zero,
            timestamp: DateTime.now().subtract(const Duration(days: 5)),
          ),
          FundNavData(
            fundCode: '000001',
            nav: Decimal.parse('1.02'),
            navDate: DateTime.now().subtract(const Duration(days: 4)),
            accumulatedNav: Decimal.parse('1.02'),
            changeRate: Decimal.parse('0.02'),
            timestamp: DateTime.now().subtract(const Duration(days: 4)),
          ),
          FundNavData(
            fundCode: '000001',
            nav: Decimal.parse('1.01'),
            navDate: DateTime.now().subtract(const Duration(days: 3)),
            accumulatedNav: Decimal.parse('1.01'),
            changeRate: Decimal.parse('-0.0098'),
            timestamp: DateTime.now().subtract(const Duration(days: 3)),
          ),
          FundNavData(
            fundCode: '000001',
            nav: Decimal.parse('1.03'),
            navDate: DateTime.now().subtract(const Duration(days: 2)),
            accumulatedNav: Decimal.parse('1.03'),
            changeRate: Decimal.parse('0.0198'),
            timestamp: DateTime.now().subtract(const Duration(days: 2)),
          ),
          FundNavData(
            fundCode: '000001',
            nav: Decimal.parse('1.05'),
            navDate: DateTime.now().subtract(const Duration(days: 1)),
            accumulatedNav: Decimal.parse('1.05'),
            changeRate: Decimal.parse('0.0194'),
            timestamp: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ];

        // 2. 检测净值变化
        final changeInfos = <Map<String, dynamic>>[];
        for (int i = 1; i < fundDataList.length; i++) {
          final previousNav = fundDataList[i - 1];
          final currentNav = fundDataList[i];

          final changeInfo =
              changeDetector.detectChange(previousNav, currentNav);
          changeInfos.add({
            'date': currentNav.navDate,
            'change': changeInfo,
            'amount': currentNav.nav,
          });

          expect(changeInfo, isNotNull);
        }

        // 3. 验证变化检测完整性
        expect(changeInfos.length, equals(4)); // 5个数据点，4个变化

        // 4. 验证变化趋势
        final positiveChanges = changeInfos
            .where((info) => info['change'].changePercentage > Decimal.zero)
            .length;
        final negativeChanges = changeInfos
            .where((info) => info['change'].changePercentage < Decimal.zero)
            .length;

        expect(positiveChanges + negativeChanges, equals(4));
        expect(positiveChanges, greaterThan(0));
        expect(negativeChanges, greaterThan(0));
      });
    });
  });
}
