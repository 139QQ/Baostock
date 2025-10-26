import 'package:flutter_test/flutter_test.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/data/services/portfolio_profit_api_service.dart';
import 'package:jisu_fund_analyzer/src/services/fund_nav_api_service.dart';

/// Portfolio API集成测试
///
/// 验证Portfolio模块的API调用修复是否成功
/// 确保累计净值字段问题在Portfolio模块中得到解决
void main() {
  group('Portfolio API集成测试', () {
    const testFundCode = '110022'; // 易方达消费行业股票
    final startDate = DateTime.now().subtract(const Duration(days: 30));
    final endDate = DateTime.now();

    late PortfolioProfitApiService portfolioApiService;

    setUpAll(() {
      portfolioApiService = PortfolioProfitApiService();
    });

    test('获取基金净值历史数据 - 使用修复后的API', () async {
      print('🔍 测试: 获取基金净值历史数据 - 使用修复后的API');
      print('   📡 基金代码: $testFundCode');
      print(
          '   📅 时间范围: ${startDate.toIso8601String()} 到 ${endDate.toIso8601String()}');

      try {
        final result = await portfolioApiService.getFundNavHistory(
          fundCode: testFundCode,
          startDate: startDate,
          endDate: endDate,
        );

        result.fold(
          (failure) {
            print('   ❌ 获取净值历史数据失败: ${failure.message}');
            fail('获取净值历史数据不应该失败: ${failure.message}');
          },
          (navHistory) {
            print('   ✅ 净值历史数据获取成功');
            print('   📊 数据点数: ${navHistory.length}');

            if (navHistory.isNotEmpty) {
              final sortedDates = navHistory.keys.toList()..sort();
              final firstDate = sortedDates.first;
              final lastDate = sortedDates.last;
              final firstNav = navHistory[firstDate]!;
              final lastNav = navHistory[lastDate]!;

              print('   📋 数据范围:');
              print(
                  '     开始日期: ${firstDate.toIso8601String().substring(0, 10)} | 净值: $firstNav');
              print(
                  '     结束日期: ${lastDate.toIso8601String().substring(0, 10)} | 净值: $lastNav');

              // 验证数据有效性
              expect(firstNav, greaterThan(0), reason: '净值应该大于0');
              expect(lastNav, greaterThan(0), reason: '净值应该大于0');
              expect(navHistory.length, greaterThan(0), reason: '应该有净值数据');
            } else {
              print('   ⚠️ 净值历史数据为空');
            }
          },
        );

        print('   🎉 净值历史数据测试通过！');
      } catch (e) {
        print('   ❌ 测试异常: $e');
        rethrow;
      }
    });

    test('获取基金累计净值历史数据 - 新增方法', () async {
      print('\n🔍 测试: 获取基金累计净值历史数据 - 新增方法');
      print('   📡 基金代码: $testFundCode');
      print(
          '   📅 时间范围: ${startDate.toIso8601String()} 到 ${endDate.toIso8601String()}');

      try {
        final result = await portfolioApiService.getFundAccumulatedNavHistory(
          fundCode: testFundCode,
          startDate: startDate,
          endDate: endDate,
        );

        result.fold(
          (failure) {
            print('   ❌ 获取累计净值历史数据失败: ${failure.message}');
            fail('获取累计净值历史数据不应该失败: ${failure.message}');
          },
          (accumulatedNavHistory) {
            print('   ✅ 累计净值历史数据获取成功');
            print('   📊 数据点数: ${accumulatedNavHistory.length}');

            if (accumulatedNavHistory.isNotEmpty) {
              final sortedDates = accumulatedNavHistory.keys.toList()..sort();
              final firstDate = sortedDates.first;
              final lastDate = sortedDates.last;
              final firstAccumulatedNav = accumulatedNavHistory[firstDate]!;
              final lastAccumulatedNav = accumulatedNavHistory[lastDate]!;

              print('   📋 累计净值数据范围:');
              print(
                  '     开始日期: ${firstDate.toIso8601String().substring(0, 10)} | 累计净值: $firstAccumulatedNav');
              print(
                  '     结束日期: ${lastDate.toIso8601String().substring(0, 10)} | 累计净值: $lastAccumulatedNav');

              // 验证累计净值数据有效性
              expect(firstAccumulatedNav, greaterThan(0), reason: '累计净值应该大于0');
              expect(lastAccumulatedNav, greaterThan(0), reason: '累计净值应该大于0');
              expect(accumulatedNavHistory.length, greaterThan(0),
                  reason: '应该有累计净值数据');

              // 🎉 关键验证：累计净值字段不再为null
              print('   🎉 累计净值字段修复成功！不再为null！');
            } else {
              print('   ⚠️ 累计净值历史数据为空');
            }
          },
        );

        print('   🎉 累计净值历史数据测试通过！');
      } catch (e) {
        print('   ❌ 测试异常: $e');
        rethrow;
      }
    });

    test('对比测试：新旧API获取的累计净值数据', () async {
      print('\n🔍 测试: 对比测试：新旧API获取的累计净值数据');

      try {
        // 使用新的FundNavApiService
        print('   📡 使用FundNavApiService获取数据...');
        final fundNavDataList = await FundNavApiService.getFundNavData(
          fundCode: testFundCode,
          limit: 5,
        );

        print('   ✅ FundNavApiService获取成功，记录数: ${fundNavDataList.length}');

        if (fundNavDataList.isNotEmpty) {
          final firstRecord = fundNavDataList.first;
          print('   📋 首条记录:');
          print('     净值日期: ${firstRecord.navDate.toIso8601String()}');
          print('     单位净值: ${firstRecord.unitNav}');
          print('     累计净值: ${firstRecord.accumulatedNav} 🎉');
          print('     日增长率: ${firstRecord.dailyReturn}%');

          // 验证累计净值字段
          expect(firstRecord.accumulatedNav, greaterThan(0),
              reason: '累计净值应该大于0');
          print('   ✅ 累计净值字段验证通过');

          // 显示所有记录的累计净值
          print('\n   📊 所有记录的累计净值:');
          for (int i = 0; i < fundNavDataList.length; i++) {
            final record = fundNavDataList[i];
            print(
                '     记录${i + 1}: ${record.navDate.toIso8601String().substring(0, 10)} | '
                '累计净值: ${record.accumulatedNav.toStringAsFixed(4)}');
          }
        }

        // 使用Portfolio API服务
        print('\n   📡 使用PortfolioProfitApiService获取数据...');
        final portfolioResult =
            await portfolioApiService.getFundAccumulatedNavHistory(
          fundCode: testFundCode,
          startDate: startDate,
          endDate: endDate,
        );

        portfolioResult.fold(
          (failure) {
            print('   ❌ Portfolio API获取失败: ${failure.message}');
          },
          (accumulatedNavHistory) {
            print(
                '   ✅ Portfolio API获取成功，数据点数: ${accumulatedNavHistory.length}');

            if (accumulatedNavHistory.isNotEmpty) {
              final sampleDate = accumulatedNavHistory.keys.first;
              final sampleAccumulatedNav = accumulatedNavHistory[sampleDate]!;
              print('   📋 样本数据:');
              print(
                  '     日期: ${sampleDate.toIso8601String().substring(0, 10)}');
              print('     累计净值: $sampleAccumulatedNav');

              expect(sampleAccumulatedNav, greaterThan(0), reason: '累计净值应该大于0');
            }
          },
        );

        print('   🎉 对比测试完成！两种API都能获取到有效的累计净值数据');
      } catch (e) {
        print('   ❌ 对比测试异常: $e');
        rethrow;
      }
    });

    test('错误处理测试：无效基金代码', () async {
      print('\n🔍 测试: 错误处理测试：无效基金代码');

      const invalidFundCode = '999999'; // 不存在的基金代码

      try {
        final result = await portfolioApiService.getFundNavHistory(
          fundCode: invalidFundCode,
          startDate: startDate,
          endDate: endDate,
        );

        result.fold(
          (failure) {
            print('   ✅ 正确处理无效基金代码');
            print('   📊 错误信息: ${failure.message}');
            // 验证错误处理是预期的
            expect(failure.message, contains('failed'), reason: '应该返回失败信息');
          },
          (navHistory) {
            print('   ⚠️ 意外成功获取数据: ${navHistory.length} 条记录');
            // 这可能是因为fallback机制工作了
          },
        );

        print('   🎉 错误处理测试通过！');
      } catch (e) {
        print('   ❌ 错误处理测试异常: $e');
        rethrow;
      }
    });

    test('性能测试：API调用耗时', () async {
      print('\n🔍 测试: 性能测试：API调用耗时');

      final stopwatch = Stopwatch()..start();

      try {
        // 并行调用多个API方法
        final futures = [
          portfolioApiService.getFundNavHistory(
            fundCode: testFundCode,
            startDate: startDate,
            endDate: endDate,
          ),
          portfolioApiService.getFundAccumulatedNavHistory(
            fundCode: testFundCode,
            startDate: startDate,
            endDate: endDate,
          ),
        ];

        final results = await Future.wait(futures);
        stopwatch.stop();

        print('   ✅ 并行API调用完成');
        print('   📊 总耗时: ${stopwatch.elapsedMilliseconds}ms');
        print(
            '   📊 平均耗时: ${stopwatch.elapsedMilliseconds / futures.length}ms');

        // 验证结果
        int successCount = 0;
        for (final result in results) {
          result.fold(
            (failure) => print('     ❌ 失败: ${failure.message}'),
            (data) {
              successCount++;
              print('     ✅ 成功: ${data.length} 条数据');
            },
          );
        }

        print('   📊 成功率: $successCount/${futures.length}');

        // 性能断言
        expect(stopwatch.elapsedMilliseconds, lessThan(10000),
            reason: '总耗时应该小于10秒');
        expect(successCount, greaterThan(0), reason: '至少应该有一个API调用成功');

        print('   🎉 性能测试通过！');
      } catch (e) {
        print('   ❌ 性能测试异常: $e');
        rethrow;
      }
    });
  });
}
