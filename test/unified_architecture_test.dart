import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:jisu_fund_analyzer/src/core/di/injection_container.dart';
import 'package:jisu_fund_analyzer/src/features/fund/shared/services/fund_data_service.dart';
import 'package:jisu_fund_analyzer/src/features/fund/shared/services/search_service.dart';
import 'package:jisu_fund_analyzer/src/features/fund/shared/models/fund_ranking.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/fund_exploration/presentation/cubit/fund_exploration_cubit.dart';

void main() {
  group('统一架构测试', () {
    late FundExplorationCubit cubit;
    late FundDataService fundDataService;
    late SearchService searchService;

    setUpAll(() async {
      // 初始化依赖注入
      await initDependencies();

      // 获取服务实例
      fundDataService = sl<FundDataService>();
      searchService = sl<SearchService>();
    });

    setUp(() {
      // 为每个测试创建新的Cubit实例，禁用自动初始化
      cubit = FundExplorationCubit(
        fundDataService: fundDataService,
        searchService: searchService,
        autoInitialize: false, // 测试时禁用自动初始化
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('Cubit初始化状态测试', () {
      expect(cubit.state.status, FundExplorationStatus.initial);
      expect(cubit.state.fundRankings, isEmpty);
      expect(cubit.state.searchResults, isEmpty);
      expect(cubit.state.searchHistory, isEmpty);
      expect(cubit.state.isLoading, false);
      expect(cubit.state.errorMessage, null);
    });

    test('搜索功能测试', () {
      // 测试搜索状态更新
      cubit.searchFunds('易方达');

      expect(cubit.state.searchQuery, '易方达');
      expect(cubit.state.status, FundExplorationStatus.searching);
      // 注意：搜索状态下isLoading默认为false，只有loading状态为true
      expect(cubit.state.isLoading, false);
    });

    test('空搜索测试', () {
      // 测试空搜索状态重置
      cubit.searchFunds('');

      expect(cubit.state.searchQuery, '');
      // 注意：空搜索应该直接显示加载数据
    });

    test('搜索历史功能测试', () {
      // 初始状态应该没有搜索历史
      expect(cubit.state.searchHistory, isEmpty);

      // 清空搜索历史
      cubit.clearSearchHistory();
      expect(cubit.state.searchHistory, isEmpty);
    });

    test('状态复制功能测试', () {
      final originalState = cubit.state;

      // 使用copyWith创建新状态
      final newState = originalState.copyWith(
        isLoading: true,
        searchQuery: '测试搜索',
      );

      expect(newState.isLoading, true);
      expect(newState.searchQuery, '测试搜索');
      expect(newState.status, originalState.status);
      expect(newState.fundRankings, originalState.fundRankings);
    });

    test('展开状态切换测试', () {
      const fundCode = '005827';

      // 初始状态应该没有展开的基金
      expect(cubit.state.expandedFunds.contains(fundCode), false);

      // 切换展开状态
      cubit.toggleFundExpanded(fundCode);
      expect(cubit.state.expandedFunds.contains(fundCode), true);

      // 再次切换
      cubit.toggleFundExpanded(fundCode);
      expect(cubit.state.expandedFunds.contains(fundCode), false);
    });

    test('错误清除功能测试', () {
      // 测试Cubit的clearError方法
      final initialState = cubit.state;

      // 模拟错误状态
      final errorState = initialState.copyWith(
        status: FundExplorationStatus.error,
        errorMessage: '测试错误',
      );

      // 使用emit来设置错误状态
      cubit.emit(errorState);
      expect(cubit.state.errorMessage, '测试错误');

      // 清除错误
      cubit.clearError();
      expect(cubit.state.errorMessage, null);
      // 注意：clearError方法只清除errorMessage，不改变status
    });

    test('推荐基金获取测试', () {
      // 测试空状态下的推荐基金获取
      final recommendations = cubit.getRecommendedFunds(limit: 5);
      expect(recommendations, isEmpty);
    });

    test('统计信息获取测试', () {
      // 测试空状态下的统计信息
      final stats = cubit.getStatistics();
      expect(stats.totalFunds, 0);
      expect(stats.averageReturn, 0.0);
      expect(stats.bestPerformingFund, null);
      expect(stats.worstPerformingFund, null);
    });

    test('状态描述功能测试', () {
      // 测试各种状态的描述 - 由于禁用自动初始化，初始状态应为initial
      expect(cubit.state.statusDescription, '准备加载数据');

      final loadingState = cubit.state.copyWith(
        status: FundExplorationStatus.loading,
      );
      expect(loadingState.statusDescription, '加载数据中...');

      final errorState = cubit.state.copyWith(
        status: FundExplorationStatus.error,
        errorMessage: '网络错误',
      );
      expect(errorState.statusDescription, '加载失败');
    });

    test('数据统计功能测试', () {
      // 测试空状态的数据统计
      expect(cubit.state.dataStatistics, '显示 0 条数据');

      final stateWithData = cubit.state.copyWith(
        status: FundExplorationStatus.searched, // 需要设置正确状态
        searchResults: [
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
            updateDate: DateTime.parse('2024-01-01'),
            fundCompany: '易方达基金',
            fundManager: '张三',
          ),
        ],
        searchQuery: '易方达',
      );
      expect(stateWithData.dataStatistics, '显示 1 条数据 (搜索: "易方达")');
    });

    test('当前数据获取逻辑测试', () {
      // 测试不同状态下的数据获取逻辑

      // 初始状态
      expect(cubit.state.currentData, isEmpty);

      // 搜索状态
      final searchState = cubit.state.copyWith(
        status: FundExplorationStatus.searched,
        searchResults: [
          FundRanking(
            fundCode: '110022',
            fundName: '易方达消费行业股票',
            fundType: '股票型',
            rank: 1,
            nav: 2.125,
            dailyReturn: 0.012,
            oneYearReturn: 0.35,
            threeYearReturn: 0.65,
            fundSize: 120.5,
            updateDate: DateTime.parse('2024-01-01'),
            fundCompany: '易方达基金',
            fundManager: '萧楠',
          ),
        ],
      );
      expect(searchState.currentData.length, 1);
      expect(searchState.currentData.first.fundName, '易方达消费行业股票');
    });
  });

  group('服务层测试', () {
    test('SearchService初始化测试', () {
      final service = SearchService();
      expect(service, isNotNull);
    });

    test('FundDataService初始化测试', () {
      final service = FundDataService();
      expect(service, isNotNull);
    });
  });

  group('数据模型测试', () {
    test('FundRanking模型测试', () {
      final fund = FundRanking(
        fundCode: '005827',
        fundName: '易方达蓝筹精选混合',
        fundType: '混合型',
        rank: 1,
        nav: 1.525,
        dailyReturn: 0.015,
        oneYearReturn: 0.25,
        threeYearReturn: 0.45,
        fundSize: 50.25,
        updateDate: DateTime.parse('2024-01-01'),
        fundCompany: '易方达基金',
        fundManager: '张三',
      );

      expect(fund.fundCode, '005827');
      expect(fund.fundName, '易方达蓝筹精选混合');
      expect(fund.oneYearReturn, 0.25);
      expect(fund.fundSize, 50.25);

      // 测试格式化方法
      expect(fund.formatReturn(0.25), '+0.25%');
      expect(fund.formatReturn(-0.15), '-0.15%');
      expect(fund.formatFundSize(), '50.25');
    });
  });
}
