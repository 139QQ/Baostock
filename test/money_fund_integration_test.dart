import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

// 导入主程序的类和服务
import '../lib/src/core/di/injection_container.dart';
import '../lib/src/features/fund/presentation/fund_exploration/presentation/cubit/fund_exploration_cubit.dart';
import '../lib/src/features/fund/shared/services/money_fund_service.dart';
import '../lib/src/features/fund/shared/models/money_fund.dart';
import '../lib/src/core/network/api_service.dart';
import 'package:dio/dio.dart';

/// 货币基金集成测试
/// 测试MoneyFundService和FundExplorationCubit的集成功能

void main() {
  group('货币基金集成测试', () {
    late MoneyFundService moneyFundService;
    late FundExplorationCubit fundExplorationCubit;
    late ApiService apiService;

    setUpAll(() async {
      // 初始化依赖注入
      await initDependencies();

      // 获取服务实例
      moneyFundService = sl<MoneyFundService>();
      apiService = sl<ApiService>();

      // 创建独立的Cubit实例用于测试
      fundExplorationCubit = FundExplorationCubit(
        fundDataService: sl(),
        searchService: sl(),
        moneyFundService: moneyFundService,
        autoInitialize: false, // 手动初始化以便测试
      );
    });

    tearDownAll(() async {
      await fundExplorationCubit.close();
      await sl.reset();
    });

    test('测试MoneyFundService基本功能', () async {
      print('🧪 测试MoneyFundService基本功能...');

      // 1. 测试获取货币基金列表
      print('\n📊 测试获取货币基金列表...');
      final fundsResult = await moneyFundService.getMoneyFunds();

      expect(fundsResult.isSuccess, isTrue, reason: '应该成功获取货币基金列表');
      expect(fundsResult.data, isNotNull, reason: '返回的数据不应为空');
      expect(fundsResult.data!.isNotEmpty, isTrue, reason: '货币基金列表不应为空');

      final funds = fundsResult.data!;
      print('✅ 获取到 ${funds.length} 只货币基金');

      // 验证第一只基金的数据完整性
      if (funds.isNotEmpty) {
        final firstFund = funds.first;
        print('\n📋 验证第一只基金数据:');
        print('   基金代码: ${firstFund.fundCode}');
        print('   基金名称: ${firstFund.fundName}');
        print('   万份收益: ${firstFund.formattedDailyIncome}');
        print('   7日年化: ${firstFund.formattedSevenDayYield}');
        print('   数据日期: ${firstFund.dataDate}');

        expect(firstFund.fundCode, isNotEmpty, reason: '基金代码不应为空');
        expect(firstFund.fundName, isNotEmpty, reason: '基金名称不应为空');
        expect(firstFund.dataDate, isNotEmpty, reason: '数据日期不应为空');
      }

      // 2. 测试搜索功能
      print('\n🔍 测试搜索功能...');
      final searchResult =
          await moneyFundService.searchMoneyFunds('华夏', limit: 5);

      expect(searchResult.isSuccess, isTrue, reason: '搜索应该成功');
      expect(searchResult.data, isNotNull, reason: '搜索结果不应为空');

      if (searchResult.data!.isNotEmpty) {
        print('✅ 搜索"华夏"找到 ${searchResult.data!.length} 只基金');
        for (final fund in searchResult.data!.take(3)) {
          print('   • ${fund.fundCode} - ${fund.fundName}');
        }
      }

      // 3. 测试获取高收益基金
      print('\n🏆 测试获取高收益基金...');
      final topYieldResult =
          await moneyFundService.getTopYieldMoneyFunds(count: 5);

      expect(topYieldResult.isSuccess, isTrue, reason: '获取高收益基金应该成功');
      expect(topYieldResult.data, isNotNull, reason: '高收益基金数据不应为空');

      if (topYieldResult.data!.isNotEmpty) {
        print('✅ 获取到收益最高的 ${topYieldResult.data!.length} 只基金:');
        for (int i = 0; i < topYieldResult.data!.length; i++) {
          final fund = topYieldResult.data![i];
          print(
              '   ${i + 1}. ${fund.fundCode} - ${fund.fundName}: ${fund.formattedSevenDayYield}');
        }
      }

      // 4. 测试统计数据
      print('\n📈 测试获取统计数据...');
      final statsResult = await moneyFundService.getMoneyFundStatistics();

      expect(statsResult.isSuccess, isTrue, reason: '获取统计数据应该成功');
      expect(statsResult.data, isNotNull, reason: '统计数据不应为空');

      if (statsResult.data != null) {
        final stats = statsResult.data!;
        print('✅ 货币基金统计数据:');
        print('   总基金数量: ${stats['totalFunds']}');
        print('   平均7日年化: ${stats['avgSevenDayYield']}%');
        print('   最高7日年化: ${stats['maxSevenDayYield']}%');
        print('   最低7日年化: ${stats['minSevenDayYield']}%');
        print('   平均万份收益: ${stats['avgDailyIncome']}');
        print('   数据日期: ${stats['dataDate']}');

        expect(stats['totalFunds'], isA<int>(), reason: '总基金数量应为整数');
        expect(stats['avgSevenDayYield'], isA<double>(), reason: '平均收益率应为数字');
      }

      print('\n🎉 MoneyFundService所有功能测试通过！');
    });

    test('测试FundExplorationCubit货币基金功能', () async {
      print('🧪 测试FundExplorationCubit货币基金功能...');

      // 监听状态变化
      final emittedStates = <FundExplorationState>[];
      final subscription = fundExplorationCubit.stream.listen((state) {
        emittedStates.add(state);
        print('📊 状态变化: ${state.status}, 货币基金数量: ${state.moneyFunds.length}');
      });

      try {
        // 1. 测试加载货币基金
        print('\n🔄 测试加载货币基金...');
        fundExplorationCubit.loadMoneyFunds();

        // 等待状态更新
        await Future.delayed(const Duration(seconds: 3));

        // 验证加载状态
        final loadingStates =
            emittedStates.where((s) => s.isMoneyFundsLoading).toList();
        expect(loadingStates.isNotEmpty, isTrue, reason: '应该有加载状态');

        // 验证最终状态
        final finalState = fundExplorationCubit.state;
        expect(finalState.moneyFunds.isNotEmpty, isTrue, reason: '应该加载到货币基金数据');
        expect(finalState.isMoneyFundsLoading, isFalse, reason: '加载应该完成');
        expect(finalState.moneyFundsError, isNull, reason: '不应该有错误');

        print('✅ 成功加载 ${finalState.moneyFunds.length} 只货币基金');

        // 2. 测试切换到货币基金视图
        print('\n🔄 测试切换到货币基金视图...');
        fundExplorationCubit.switchToMoneyFundsView();
        await Future.delayed(const Duration(milliseconds: 100));

        final switchedState = fundExplorationCubit.state;
        expect(switchedState.activeView, FundExplorationView.moneyFunds,
            reason: '应该切换到货币基金视图');

        print('✅ 成功切换到货币基金视图');

        // 3. 测试搜索货币基金
        print('\n🔍 测试搜索货币基金...');
        fundExplorationCubit.searchMoneyFunds('现金');

        // 等待搜索完成
        await Future.delayed(const Duration(seconds: 2));

        final searchState = fundExplorationCubit.state;
        expect(searchState.searchQuery, equals('现金'), reason: '搜索查询应该设置');

        if (searchState.moneyFundSearchResults.isNotEmpty) {
          print('✅ 搜索"现金"找到 ${searchState.moneyFundSearchResults.length} 只基金');
          for (final fund in searchState.moneyFundSearchResults.take(3)) {
            print('   • ${fund.fundCode} - ${fund.fundName}');
          }
        }

        // 4. 测试清除搜索
        print('\n🗑️ 测试清除搜索...');
        fundExplorationCubit.clearMoneyFundSearch();
        await Future.delayed(const Duration(milliseconds: 100));

        final clearedState = fundExplorationCubit.state;
        expect(clearedState.searchQuery, isEmpty, reason: '搜索查询应该被清除');
        expect(clearedState.moneyFundSearchResults, isEmpty,
            reason: '搜索结果应该被清除');

        print('✅ 搜索已清除');

        // 5. 测试获取高收益基金
        print('\n🏆 测试获取高收益基金...');
        fundExplorationCubit.loadTopYieldMoneyFunds(count: 10);
        await Future.delayed(const Duration(seconds: 2));

        final topYieldState = fundExplorationCubit.state;
        expect(topYieldState.moneyFunds.isNotEmpty, isTrue,
            reason: '应该加载到高收益基金');

        // 验证排序（应该按收益率降序排列）
        final sortedYields =
            topYieldState.moneyFunds.map((f) => f.sevenDayYield).toList();
        for (int i = 1; i < sortedYields.length; i++) {
          expect(sortedYields[i - 1] >= sortedYields[i], isTrue,
              reason: '收益率应该按降序排列');
        }

        print('✅ 成功获取高收益基金排行');

        // 6. 测试获取统计数据
        print('\n📈 测试获取统计数据...');
        final stats = await fundExplorationCubit.getMoneyFundStatistics();
        expect(stats, isNotNull, reason: '统计数据不应为空');

        if (stats != null) {
          print('✅ 获取到统计数据:');
          print('   总基金数量: ${stats['totalFunds']}');
          print('   平均7日年化: ${stats['avgSevenDayYield']}%');
        }

        print('\n🎉 FundExplorationCubit货币基金功能测试通过！');
      } finally {
        await subscription.cancel();
      }
    });

    test('测试MoneyFund模型解析能力', () async {
      print('🧪 测试MoneyFund模型解析能力...');

      // 获取API原始数据
      final rawData = await apiService.getMoneyFundDaily();
      expect(rawData, isA<List>(), reason: 'API应返回列表数据');
      expect(rawData, isNotEmpty, reason: 'API数据不应为空');

      print('📊 获取到 ${rawData.length} 条原始数据');

      // 测试解析多条数据
      int successCount = 0;
      int errorCount = 0;

      for (int i = 0; i < 5.clamp(0, rawData.length); i++) {
        try {
          final fundData = rawData[i] as Map<String, dynamic>;
          final moneyFund = MoneyFund.fromJson(fundData);

          print('\n📋 货币基金 ${i + 1} 解析结果:');
          print('   基金代码: ${moneyFund.fundCode}');
          print('   基金名称: ${moneyFund.fundName}');
          print('   万份收益: ${moneyFund.formattedDailyIncome}');
          print('   7日年化: ${moneyFund.formattedSevenDayYield}');
          print('   数据日期: ${moneyFund.dataDate}');

          // 验证关键字段
          expect(moneyFund.fundCode, isNotEmpty, reason: '基金代码不应为空');
          expect(moneyFund.fundName, isNotEmpty, reason: '基金名称不应为空');
          expect(moneyFund.dataDate, isNotEmpty, reason: '数据日期不应为空');

          successCount++;
        } catch (e) {
          errorCount++;
          print('❌ 基金 ${i + 1} 解析失败: $e');
        }
      }

      print('\n📊 解析结果统计:');
      print('   成功解析: $successCount');
      print('   解析失败: $errorCount');
      print('   成功率: ${(successCount / 5 * 100).toStringAsFixed(1)}%');

      expect(successCount, greaterThan(3), reason: '成功率应该大于60%');

      print('\n🎉 MoneyFund模型解析能力测试通过！');
    });

    test('测试完整集成流程', () async {
      print('🧪 测试完整集成流程...');

      // 模拟用户操作流程：
      // 1. 用户进入基金排行页面
      // 2. 切换到货币基金tab
      // 3. 查看货币基金列表
      // 4. 搜索特定基金
      // 5. 查看高收益基金
      // 6. 切换回其他视图

      print('\n📱 步骤1: 初始化应用...');
      await fundExplorationCubit.loadFundRankings();
      await Future.delayed(const Duration(seconds: 2));

      print('\n📱 步骤2: 切换到货币基金视图...');
      fundExplorationCubit.switchToMoneyFundsView();
      await Future.delayed(const Duration(seconds: 2));

      expect(fundExplorationCubit.state.activeView,
          FundExplorationView.moneyFunds);
      expect(fundExplorationCubit.state.moneyFunds.isNotEmpty, isTrue);
      print(
          '✅ 货币基金视图加载完成，共 ${fundExplorationCubit.state.moneyFunds.length} 只基金');

      print('\n📱 步骤3: 搜索"余额宝"...');
      fundExplorationCubit.searchMoneyFunds('余额宝');
      await Future.delayed(const Duration(seconds: 2));

      if (fundExplorationCubit.state.moneyFundSearchResults.isNotEmpty) {
        print(
            '✅ 搜索完成，找到 ${fundExplorationCubit.state.moneyFundSearchResults.length} 只相关基金');
      } else {
        print('⚠️ 未找到"余额宝"相关基金（这是正常的）');
      }

      print('\n📱 步骤4: 查看高收益基金...');
      fundExplorationCubit.loadTopYieldMoneyFunds(count: 5);
      await Future.delayed(const Duration(seconds: 2));

      expect(fundExplorationCubit.state.moneyFunds.isNotEmpty, isTrue);

      final topFunds = fundExplorationCubit.state.moneyFunds.take(3).toList();
      print('✅ 高收益基金排行:');
      for (int i = 0; i < topFunds.length; i++) {
        final fund = topFunds[i];
        print(
            '   ${i + 1}. ${fund.fundCode} - ${fund.fundName}: ${fund.formattedSevenDayYield}');
      }

      print('\n📱 步骤5: 切换回综合排行...');
      fundExplorationCubit.switchToRankingView();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(
          fundExplorationCubit.state.activeView, FundExplorationView.ranking);
      print('✅ 已切换回综合排行视图');

      print('\n🎉 完整集成流程测试通过！');
      print('📊 集成测试总结:');
      print('   ✅ MoneyFundService 功能正常');
      print('   ✅ FundExplorationCubit 状态管理正常');
      print('   ✅ MoneyFund 模型解析正常');
      print('   ✅ UI交互流程正常');
      print('   ✅ 货币基金功能已成功集成到现有基金排行系统');
    });
  });
}
