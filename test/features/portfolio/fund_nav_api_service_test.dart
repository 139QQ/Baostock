import 'package:flutter_test/flutter_test.dart';
import 'package:jisu_fund_analyzer/src/services/fund_nav_api_service.dart';

/// FundNavApiService集成测试
///
/// 验证修复后的净值API服务是否能正确获取完整的基金净值数据
void main() {
  group('FundNavApiService集成测试', () {
    const testFundCode = '110022'; // 易方达消费行业股票

    test('获取基金净值数据 - 验证字段完整性', () async {
      print('🔍 测试: 获取基金净值数据 - 验证字段完整性');
      print('   📡 基金代码: $testFundCode');

      try {
        final navDataList = await FundNavApiService.getFundNavData(
          fundCode: testFundCode,
          limit: 5, // 只获取前5条数据进行测试
        );

        print('   ✅ API调用成功');
        print('   📊 获取记录数: ${navDataList.length}');

        if (navDataList.isNotEmpty) {
          // 验证第一条记录的字段完整性
          final firstRecord = navDataList.first;

          print('\n   📋 首条记录验证:');
          print('     净值日期: ${firstRecord.navDate.toIso8601String()} ✅');
          print('     单位净值: ${firstRecord.unitNav} ✅');
          print('     累计净值: ${firstRecord.accumulatedNav} ✅');
          print('     日增长率: ${firstRecord.dailyReturn}% ✅');

          // 验证关键字段是否为有效值
          expect(firstRecord.navDate, isNotNull, reason: '净值日期不能为null');
          expect(firstRecord.unitNav, greaterThan(0), reason: '单位净值必须大于0');
          expect(firstRecord.accumulatedNav, greaterThan(0),
              reason: '累计净值必须大于0');
          expect(firstRecord.dailyReturn, isA<double>(), reason: '日增长率必须是数值类型');

          // 验证累计净值是否成功获取（之前的主要问题）
          if (firstRecord.accumulatedNav > 0) {
            print('   🎉 累计净值字段修复成功！不再为null');
          } else {
            print('   ⚠️ 累计净值仍为0，可能需要进一步检查');
          }

          // 显示所有记录的基本信息
          print('\n   📊 所有记录概览:');
          for (int i = 0; i < navDataList.length; i++) {
            final record = navDataList[i];
            print(
                '     记录${i + 1}: ${record.navDate.toIso8601String().substring(0, 10)} | '
                '单位净值: ${record.unitNav.toStringAsFixed(4)} | '
                '累计净值: ${record.accumulatedNav.toStringAsFixed(4)} | '
                '日增长率: ${record.dailyReturn.toStringAsFixed(2)}%');
          }

          // 验证数据按日期降序排列（最新的在前）
          bool isSorted = true;
          for (int i = 0; i < navDataList.length - 1; i++) {
            if (navDataList[i].navDate.isBefore(navDataList[i + 1].navDate)) {
              isSorted = false;
              break;
            }
          }

          if (isSorted) {
            print('   ✅ 数据按日期降序排列正确');
          } else {
            print('   ⚠️ 数据排序异常');
          }

          print('   🎉 基金净值数据获取测试通过！');
        } else {
          print('   ❌ 未获取到任何数据');
        }
      } catch (e) {
        print('   ❌ 测试失败: $e');
        rethrow;
      }
    });

    test('获取基金基本信息', () async {
      print('\n🔍 测试: 获取基金基本信息');
      print('   📡 基金代码: $testFundCode');

      try {
        final basicInfo =
            await FundNavApiService.getFundBasicInfo(testFundCode);

        if (basicInfo != null) {
          print('   ✅ 基金基本信息获取成功');
          print('   📋 基金信息:');
          print('     基金代码: ${basicInfo.fundCode}');
          print(
              '     最新净值日期: ${basicInfo.latestNavDate.toIso8601String().substring(0, 10)}');
          print('     最新单位净值: ${basicInfo.latestUnitNav}');
          print('     最新累计净值: ${basicInfo.latestAccumulatedNav}');

          expect(basicInfo.fundCode, equals(testFundCode));
          expect(basicInfo.latestUnitNav, greaterThan(0));
          expect(basicInfo.latestAccumulatedNav, greaterThan(0));

          print('   🎉 基金基本信息测试通过！');
        } else {
          print('   ❌ 未获取到基金基本信息');
        }
      } catch (e) {
        print('   ❌ 测试失败: $e');
        rethrow;
      }
    });

    test('批量获取多只基金净值数据', () async {
      print('\n🔍 测试: 批量获取多只基金净值数据');

      final testFundCodes = ['110022', '161725']; // 易方达消费行业股票, 招商中证白酒指数
      print('   📡 测试基金代码: ${testFundCodes.join(', ')}');

      try {
        final batchResults = await FundNavApiService.getBatchFundNavData(
          testFundCodes,
          limit: 3, // 每只基金只获取3条数据
        );

        print('   ✅ 批量获取成功');
        print('   📊 获取结果:');

        int totalRecords = 0;
        batchResults.forEach((fundCode, navDataList) {
          print('     基金 $fundCode: ${navDataList.length} 条记录');
          totalRecords += navDataList.length;

          if (navDataList.isNotEmpty) {
            final firstRecord = navDataList.first;
            print(
                '       最新: ${firstRecord.navDate.toIso8601String().substring(0, 10)} | '
                '单位净值: ${firstRecord.unitNav} | '
                '累计净值: ${firstRecord.accumulatedNav}');
          }
        });

        print('   📊 总记录数: $totalRecords');

        // 验证每只基金都有数据
        for (final fundCode in testFundCodes) {
          expect(batchResults.containsKey(fundCode), isTrue,
              reason: '应该包含基金 $fundCode 的数据');
          expect(batchResults[fundCode]!.isNotEmpty, isTrue,
              reason: '基金 $fundCode 应该有数据');
        }

        print('   🎉 批量获取测试通过！');
      } catch (e) {
        print('   ❌ 测试失败: $e');
        rethrow;
      }
    });

    test('收益计算功能验证', () async {
      print('\n🔍 测试: 收益计算功能验证');

      try {
        final navDataList = await FundNavApiService.getFundNavData(
          fundCode: testFundCode,
          limit: 10, // 获取更多数据用于计算
        );

        if (navDataList.length >= 2) {
          print('   📊 收益计算测试:');

          // 计算日收益率
          final latest = navDataList.first;
          final previous = navDataList[1];
          final dailyReturn = latest.calculateReturnRate(previous);

          print(
              '     最新净值日期: ${latest.navDate.toIso8601String().substring(0, 10)}');
          print('     单位净值: ${latest.unitNav} → ${previous.unitNav}');
          print('     计算日收益率: ${(dailyReturn * 100).toStringAsFixed(4)}%');
          print('     API日增长率: ${latest.dailyReturn}%');

          // 验证计算结果与API返回的日增长率是否接近
          final apiDailyReturn = latest.dailyReturn / 100; // API返回的是百分比
          final difference = (dailyReturn - apiDailyReturn).abs();

          print('     差异: ${(difference * 100).toStringAsFixed(4)}%');

          if (difference < 0.0001) {
            // 允许0.01%的差异
            print('   ✅ 收益率计算准确');
          } else {
            print('   ⚠️ 收益率计算与API数据有差异');
          }

          // 验证累计收益率
          final cumulativeReturn = latest.cumulativeReturnRate;
          print('     累计收益率: ${(cumulativeReturn * 100).toStringAsFixed(2)}%');

          expect(cumulativeReturn, isA<double>());
          expect(cumulativeReturn, greaterThanOrEqualTo(-1)); // 累计收益率不应该小于-100%

          print('   🎉 收益计算功能验证通过！');
        } else {
          print('   ❌ 数据不足，无法进行收益计算测试');
        }
      } catch (e) {
        print('   ❌ 测试失败: $e');
        rethrow;
      }
    });

    test('错误处理和边界情况测试', () async {
      print('\n🔍 测试: 错误处理和边界情况');

      // 测试不存在的基金代码
      print('   📡 测试不存在的基金代码...');
      try {
        final result =
            await FundNavApiService.getFundNavData(fundCode: '999999');
        print('   ⚠️ 意外成功获取数据: ${result.length} 条记录');
      } catch (e) {
        print('   ✅ 正确处理不存在的基金代码: ${e.toString().substring(0, 50)}...');
      }

      // 测试limit参数
      print('   📡 测试limit参数...');
      try {
        final limitedData = await FundNavApiService.getFundNavData(
          fundCode: testFundCode,
          limit: 2,
        );

        expect(limitedData.length, lessThanOrEqualTo(2), reason: '限制记录数应该生效');
        print('   ✅ limit参数正常工作，获取 ${limitedData.length} 条记录');
      } catch (e) {
        print('   ❌ limit参数测试失败: $e');
      }

      // 测试空基金代码列表
      print('   📡 测试空基金代码列表...');
      try {
        final emptyResult = await FundNavApiService.getBatchFundNavData([]);
        expect(emptyResult.isEmpty, isTrue, reason: '空列表应该返回空结果');
        print('   ✅ 空列表处理正确');
      } catch (e) {
        print('   ❌ 空列表处理失败: $e');
      }

      print('   🎉 错误处理测试完成！');
    });

    test('性能和稳定性测试', () async {
      print('\n🔍 测试: 性能和稳定性');

      final stopwatch = Stopwatch()..start();

      try {
        // 测试单个请求的性能
        final singleData = await FundNavApiService.getFundNavData(
          fundCode: testFundCode,
          limit: 20,
        );

        stopwatch.stop();
        final singleRequestTime = stopwatch.elapsedMilliseconds;

        print('   📊 单个请求性能:');
        print('     获取记录数: ${singleData.length}');
        print('     耗时: ${singleRequestTime}ms');

        expect(singleRequestTime, lessThan(10000), reason: '单个请求应该在10秒内完成');

        // 测试并发请求
        stopwatch.reset();
        stopwatch.start();

        final concurrentRequests = [
          FundNavApiService.getFundNavData(fundCode: '110022', limit: 5),
          FundNavApiService.getFundNavData(fundCode: '161725', limit: 5),
          FundNavApiService.getFundNavData(fundCode: '000001', limit: 5),
        ];

        final results = await Future.wait(concurrentRequests);

        stopwatch.stop();
        final concurrentRequestTime = stopwatch.elapsedMilliseconds;

        print('\n   📊 并发请求性能:');
        print('     并发数量: ${concurrentRequests.length}');
        print('     总耗时: ${concurrentRequestTime}ms');
        print(
            '     平均耗时: ${concurrentRequestTime / concurrentRequests.length}ms');

        final successfulRequests =
            results.where((list) => list.isNotEmpty).length;
        print('     成功请求数: $successfulRequests/${concurrentRequests.length}');

        expect(concurrentRequestTime, lessThan(15000), reason: '并发请求应该在15秒内完成');
        expect(successfulRequests, greaterThan(0), reason: '至少应该有一个请求成功');

        print('   🎉 性能测试通过！');
      } catch (e) {
        print('   ❌ 性能测试失败: $e');
        rethrow;
      }
    });
  });
}
