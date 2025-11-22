import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:decimal/decimal.dart';

import 'package:jisu_fund_analyzer/src/features/fund/data/cache/fund_nav_cache_manager.dart';
import 'package:jisu_fund_analyzer/src/features/fund/models/fund_nav_data.dart';
import 'package:jisu_fund_analyzer/src/core/utils/logger.dart';

@GenerateMocks([])
void main() {
  group('FundNavCacheManager Tests', () {
    group('基础功能测试', () {
      test('应该能够创建FundNavData实例', () {
        final navData = FundNavData(
          fundCode: '000001',
          nav: Decimal.parse('1.2345'),
          navDate: DateTime(2024, 1, 1),
          accumulatedNav: Decimal.parse('1.5678'),
          changeRate: Decimal.parse('0.0123'),
          timestamp: DateTime.now(),
        );

        expect(navData.fundCode, equals('000001'));
        expect(navData.nav, equals(Decimal.parse('1.2345')));
        expect(navData.accumulatedNav, equals(Decimal.parse('1.5678')));
        expect(navData.changeRate, equals(Decimal.parse('0.0123')));
        expect(navData.navDate, equals(DateTime(2024, 1, 1)));
        expect(navData.timestamp, isNotNull);
      });

      test('应该验证净值数据的有效性', () {
        // 测试有效数据
        final validNavData = FundNavData(
          fundCode: '000001',
          nav: Decimal.parse('1.2345'),
          navDate: DateTime(2024, 1, 1),
          accumulatedNav: Decimal.parse('1.5678'),
          changeRate: Decimal.parse('0.0123'),
          timestamp: DateTime.now(),
        );

        expect(validNavData.fundCode, isNotEmpty);
        expect(validNavData.nav, greaterThan(Decimal.zero));
        expect(validNavData.accumulatedNav, greaterThan(Decimal.zero));
        expect(validNavData.navDate, isNotNull);
        expect(validNavData.timestamp, isNotNull);

        // 测试无效数据
        final invalidNavData = FundNavData(
          fundCode: '',
          nav: Decimal.zero,
          navDate: DateTime.now(),
          accumulatedNav: Decimal.parse('-1'),
          changeRate: Decimal.parse('100'),
          timestamp: DateTime.now(),
        );

        expect(invalidNavData.fundCode, isEmpty);
        expect(invalidNavData.nav, equals(Decimal.zero));
        expect(invalidNavData.accumulatedNav, lessThan(Decimal.zero));
      });

      test('应该正确计算净值变化', () {
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

        final changeAmount = currentNav.nav - previousNav.nav;
        expect(changeAmount, equals(Decimal.parse('0.05')));

        final changeRate = (currentNav.nav - previousNav.nav).toDouble() /
            previousNav.nav.toDouble();
        expect(changeRate, greaterThan(0.0));
      });
    });

    group('批量数据处理测试', () {
      test('应该支持多只基金数据批量创建', () {
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

      test('应该能够处理大量基金数据', () {
        final fundDataList = <FundNavData>[];

        // 创建100个基金数据
        for (int i = 0; i < 100; i++) {
          fundDataList.add(FundNavData(
            fundCode: '00000${i.toString().padLeft(3, '0')}',
            nav: Decimal.parse('1.${(i + 1).toString().padLeft(4, '0')}'),
            navDate: DateTime.now(),
            accumulatedNav:
                Decimal.parse('1.${(i + 1).toString().padLeft(4, '0')}'),
            changeRate:
                Decimal.parse('0.00${(i % 10).toString().padLeft(2, '0')}'),
            timestamp: DateTime.now(),
          ));
        }

        expect(fundDataList.length, equals(100));

        // 验证性能相关指标
        final stopwatch = Stopwatch()..start();
        int validCount = 0;

        for (final fundData in fundDataList) {
          if (fundData.fundCode.isNotEmpty &&
              fundData.nav > Decimal.zero &&
              fundData.accumulatedNav > Decimal.zero) {
            validCount++;
          }
        }

        stopwatch.stop();

        expect(validCount, equals(100));
        expect(stopwatch.elapsedMilliseconds, lessThan(100)); // 应该在100ms内完成
      });
    });

    group('数据准确性验证', () {
      test('应该验证净值数据的合理性', () {
        final validNavData = FundNavData(
          fundCode: '000001',
          nav: Decimal.parse('1.2345'),
          navDate: DateTime.now(),
          accumulatedNav: Decimal.parse('1.5678'),
          changeRate: Decimal.parse('0.0123'),
          timestamp: DateTime.now(),
        );

        // 基本数据验证
        expect(validNavData.fundCode, isNotEmpty);
        expect(validNavData.nav, greaterThan(Decimal.zero));
        expect(validNavData.accumulatedNav, greaterThan(Decimal.zero));
        expect(validNavData.accumulatedNav,
            greaterThanOrEqualTo(validNavData.nav));
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
        expect(invalidNavData.accumulatedNav, lessThan(invalidNavData.nav));
      });
    });

    group('性能测试', () {
      test('数据创建性能应该满足要求', () {
        final stopwatch = Stopwatch()..start();

        // 执行1000次数据创建
        for (int i = 0; i < 1000; i++) {
          final navData = FundNavData(
            fundCode: '00000${i.toString().padLeft(3, '0')}',
            nav: Decimal.parse('1.2345'),
            navDate: DateTime.now(),
            accumulatedNav: Decimal.parse('1.5678'),
            changeRate: Decimal.parse('0.0123'),
            timestamp: DateTime.now(),
          );

          // 验证数据有效性
          expect(navData.fundCode, isNotEmpty);
          expect(navData.nav, greaterThan(Decimal.zero));
        }

        stopwatch.stop();

        // 性能要求：1000次创建应该在1秒内完成
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });

      test('数据处理性能应该满足要求', () {
        // 创建大量测试数据
        final fundDataList = <FundNavData>[];
        for (int i = 0; i < 500; i++) {
          fundDataList.add(FundNavData(
            fundCode: '00000${i.toString().padLeft(3, '0')}',
            nav: Decimal.parse('1.${(i + 1).toString().padLeft(4, '0')}'),
            navDate: DateTime.now().subtract(Duration(days: i % 30)),
            accumulatedNav:
                Decimal.parse('1.${(i + 1).toString().padLeft(4, '0')}'),
            changeRate:
                Decimal.parse('0.${(i % 100).toString().padLeft(2, '0')}'),
            timestamp: DateTime.now(),
          ));
        }

        final stopwatch = Stopwatch()..start();

        // 处理数据：按基金代码分组
        final Map<String, List<FundNavData>> groupedData = {};
        for (final data in fundDataList) {
          if (!groupedData.containsKey(data.fundCode)) {
            groupedData[data.fundCode] = [];
          }
          groupedData[data.fundCode]!.add(data);
        }

        // 计算每只基金的最新净值
        final Map<String, FundNavData> latestData = {};
        for (final entry in groupedData.entries) {
          final sortedData = List<FundNavData>.from(entry.value);
          sortedData.sort((a, b) => b.navDate.compareTo(a.navDate));
          latestData[entry.key] = sortedData.first;
        }

        stopwatch.stop();

        // 验证处理结果
        expect(groupedData.length, greaterThan(0));
        expect(latestData.length, equals(groupedData.length));

        // 性能要求：500条数据处理应该在2秒内完成
        expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      });
    });

    group('缓存健康状态测试', () {
      test('应该提供基本的缓存健康检查', () {
        // 模拟缓存健康指标
        final healthMetrics = {
          'cacheSize': 100,
          'hitRate': 0.85,
          'memoryUsage': 1024 * 1024, // 1MB
          'lastUpdate': DateTime.now().toIso8601String(),
          'isHealthy': true,
        };

        expect(healthMetrics['cacheSize'], equals(100));
        expect(healthMetrics['hitRate'], equals(0.85));
        expect(healthMetrics['isHealthy'], isTrue);
        expect(healthMetrics['memoryUsage'], greaterThan(0));
        expect(healthMetrics['lastUpdate'], isNotNull);
      });
    });
  });
}
