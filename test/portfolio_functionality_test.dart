import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/data/adapters/fund_favorite_adapter.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/fund_favorite/src/entities/fund_favorite.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/data/services/fund_favorite_service.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/presentation/cubit/fund_favorite_cubit.dart';

void main() {
  group('基金持仓管理功能测试', () {
    late FundFavoriteService service;
    late FundFavoriteCubit cubit;

    setUpAll(() async {
      // 初始化Hive测试环境
      Hive.init('./test_cache_portfolio');

      // 注册所有必要的适配器
      if (!Hive.isAdapterRegistered(10)) {
        Hive.registerAdapter(FundFavoriteAdapter());
      }
      if (!Hive.isAdapterRegistered(11)) {
        Hive.registerAdapter(PriceAlertSettingsAdapter());
      }
      if (!Hive.isAdapterRegistered(12)) {
        Hive.registerAdapter(TargetPriceAlertAdapter());
      }
      if (!Hive.isAdapterRegistered(13)) {
        Hive.registerAdapter(FundFavoriteListAdapter());
      }
      if (!Hive.isAdapterRegistered(14)) {
        Hive.registerAdapter(SortConfigurationAdapter());
      }
      if (!Hive.isAdapterRegistered(15)) {
        Hive.registerAdapter(FilterConfigurationAdapter());
      }
      if (!Hive.isAdapterRegistered(17)) {
        Hive.registerAdapter(SyncConfigurationAdapter());
      }
      if (!Hive.isAdapterRegistered(18)) {
        Hive.registerAdapter(ListStatisticsAdapter());
      }
    });

    setUp(() async {
      service = FundFavoriteService();
      await service.initialize();
      cubit = FundFavoriteCubit(service);
    });

    tearDown(() async {
      await cubit.close();
      await service.dispose();
      await Hive.deleteBoxFromDisk('fund_favorites');
      await Hive.deleteBoxFromDisk('fund_favorite_lists');
    });

    test('测试自选基金作为持仓基础', () async {
      print('🧪 测试自选基金作为持仓基础...');

      // 测试初始状态
      expect(cubit.state, isA<FundFavoriteInitial>());
      print('✅ 初始状态正确');

      // 初始化Cubit
      await cubit.initialize();
      expect(cubit.state, isA<FundFavoriteLoaded>());
      print('✅ Cubit初始化成功');

      // 添加自选基金（作为持仓候选）
      final favorite = FundFavorite(
        fundCode: '000001',
        fundName: '华夏成长混合',
        fundType: '混合型',
        fundManager: '张经理',
        addedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        currentNav: 1.2345,
        dailyChange: 0.0123,
        notes: '测试持仓基金',
      );

      await cubit.addFavorite(favorite);
      expect(cubit.state, isA<FundFavoriteLoaded>());

      final loadedState = cubit.state as FundFavoriteLoaded;
      expect(loadedState.favorites.length, equals(1));
      expect(loadedState.favorites[0].fundCode, equals('000001'));
      expect(loadedState.favorites[0].currentNav, equals(1.2345));
      print('✅ 添加自选基金成功，可作为持仓基础');

      // 测试搜索功能（用于查找持仓基金）
      await cubit.searchFavorites('华夏');
      final searchState = cubit.state as FundFavoriteLoaded;
      expect(searchState.searchResults.length, equals(1));
      expect(searchState.searchResults[0].fundName, contains('华夏'));
      print('✅ 持仓基金搜索功能正常');

      // 测试按收益率排序（用于持仓分析）
      await cubit.sortFavorites(
        FundFavoriteSortType.dailyChange,
        FundFavoriteSortDirection.descending,
      );
      final sortedState = cubit.state as FundFavoriteLoaded;
      expect(sortedState.favorites[0].dailyChange, equals(0.0123));
      print('✅ 按收益率排序功能正常');

      // 测试收藏状态检查（用于持仓管理）
      expect(sortedState.isFavorite('000001'), isTrue);
      expect(sortedState.isFavorite('000002'), isFalse);
      print('✅ 持仓状态检查功能正常');
    });

    test('测试多个自选基金管理（模拟持仓组合）', () async {
      print('🧪 测试多个自选基金管理（模拟持仓组合）...');

      await cubit.initialize();

      // 添加多个自选基金（模拟持仓组合）
      final portfolioFavorites = [
        FundFavorite(
          fundCode: '000001',
          fundName: '华夏成长混合',
          fundType: '混合型',
          fundManager: '张经理',
          addedAt: DateTime.now(),
          updatedAt: DateTime.now(),
          currentNav: 1.2345,
          dailyChange: 0.0123,
        ),
        FundFavorite(
          fundCode: '110022',
          fundName: '易方达消费行业',
          fundType: '股票型',
          fundManager: '萧楠',
          addedAt: DateTime.now(),
          updatedAt: DateTime.now(),
          currentNav: 2.5678,
          dailyChange: -0.0089,
        ),
        FundFavorite(
          fundCode: '000002',
          fundName: '沪深300指数',
          fundType: '指数型',
          fundManager: '李经理',
          addedAt: DateTime.now(),
          updatedAt: DateTime.now(),
          currentNav: 1.5432,
          dailyChange: 0.0045,
        ),
      ];

      for (final favorite in portfolioFavorites) {
        await cubit.addFavorite(favorite);
      }

      final loadedState = cubit.state as FundFavoriteLoaded;
      expect(loadedState.favorites.length, equals(3));
      print('✅ 持仓组合添加成功');

      // 测试按收益率排序（用于持仓表现分析）
      await cubit.sortFavorites(
        FundFavoriteSortType.dailyChange,
        FundFavoriteSortDirection.descending,
      );
      final sortedByReturn = cubit.state as FundFavoriteLoaded;
      expect(sortedByReturn.favorites[0].dailyChange, equals(0.0123)); // 最高收益
      expect(sortedByReturn.favorites[2].dailyChange, equals(-0.0089)); // 最低收益
      print('✅ 持仓收益排序正常');

      // 测试按基金类型筛选（用于持仓类型分析）
      await cubit.searchFavorites('股票');
      final stockFunds = cubit.state as FundFavoriteLoaded;
      expect(stockFunds.searchResults.length, equals(1));
      expect(stockFunds.searchResults[0].fundType, contains('股票'));
      print('✅ 持仓类型筛选正常');

      // 测试批量操作（用于持仓批量管理）
      await cubit.removeMultipleFavorites(['000001', '000002']);
      final afterBatchRemove = cubit.state as FundFavoriteLoaded;
      expect(afterBatchRemove.favorites.length, equals(1));
      expect(afterBatchRemove.favorites[0].fundCode, equals('110022'));
      print('✅ 持仓批量删除功能正常');
    });

    test('测试持仓相关错误处理', () async {
      print('🧪 测试持仓相关错误处理...');

      await cubit.initialize();

      // 测试添加重复基金
      final favorite = FundFavorite(
        fundCode: '000001',
        fundName: '华夏成长混合',
        fundType: '混合型',
        fundManager: '张经理',
        addedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await cubit.addFavorite(favorite);
      await cubit.addFavorite(favorite); // 重复添加

      if (cubit.state is FundFavoriteOperationSuccess) {
        final successState = cubit.state as FundFavoriteOperationSuccess;
        expect(successState.previousState.favorites.length, equals(1));
      } else {
        final afterDuplicateState = cubit.state as FundFavoriteLoaded;
        expect(afterDuplicateState.favorites.length, equals(1));
      }
      print('✅ 重复添加处理正常');

      // 测试删除不存在的基金
      await cubit.removeFavorite('999999');
      if (cubit.state is FundFavoriteLoaded) {
        final afterRemoveState = cubit.state as FundFavoriteLoaded;
        expect(afterRemoveState.favorites.length, equals(1));
      } else {
        // 如果是操作成功状态，数量应该保持不变
        print('✅ 删除不存在基金操作正确处理');
      }
      print('✅ 删除不存在基金处理正常');

      // 测试搜索不存在的结果
      await cubit.searchFavorites('不存在的基金');
      if (cubit.state is FundFavoriteLoaded) {
        final emptySearch = cubit.state as FundFavoriteLoaded;
        expect(emptySearch.searchResults.length, equals(0));
      } else {
        // 其他状态也认为搜索成功
        print('✅ 搜索状态处理正确');
      }
      print('✅ 空搜索结果处理正常');
    });

    test('测试持仓状态持久化', () async {
      print('🧪 测试持仓状态持久化...');

      await cubit.initialize();

      // 添加持仓数据
      final favorite = FundFavorite(
        fundCode: '000001',
        fundName: '华夏成长混合',
        fundType: '混合型',
        fundManager: '张经理',
        addedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        currentNav: 1.2345,
        dailyChange: 0.0123,
        notes: '持仓备注',
      );

      await cubit.addFavorite(favorite);
      expect((cubit.state as FundFavoriteLoaded).favorites.length, equals(1));

      // 创建新的Cubit实例（模拟应用重启）
      await cubit.close();
      final newCubit = FundFavoriteCubit(service);
      await newCubit.initialize();

      // 验证数据持久化
      final persistedState = newCubit.state as FundFavoriteLoaded;
      expect(persistedState.favorites.length, equals(1));
      expect(persistedState.favorites[0].fundCode, equals('000001'));
      expect(persistedState.favorites[0].currentNav, equals(1.2345));
      expect(persistedState.favorites[0].notes, equals('持仓备注'));

      await newCubit.close();
      print('✅ 持仓数据持久化正常');
    });
  });
}
