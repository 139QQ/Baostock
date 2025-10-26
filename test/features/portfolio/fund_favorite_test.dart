import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/data/services/fund_favorite_service.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/data/adapters/fund_favorite_adapter.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/fund_favorite/src/entities/fund_favorite.dart';

void main() {
  group('自选基金功能测试', () {
    late FundFavoriteService service;

    setUpAll(() async {
      // 初始化Hive测试环境
      Hive.init('test_fund_favorite');

      // 注册适配器
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
      if (!Hive.isAdapterRegistered(16)) {
        Hive.registerAdapter(SyncConfigurationAdapter());
      }
      if (!Hive.isAdapterRegistered(17)) {
        Hive.registerAdapter(ListStatisticsAdapter());
      }
    });

    setUp(() async {
      // 初始化服务
      service = FundFavoriteService();
      await service.initialize();
    });

    tearDown(() async {
      // 清理测试数据
      await service.clearAllFavorites();
      await service.dispose();
    });

    tearDownAll(() async {
      await Hive.deleteFromDisk();
    });

    test('应该能够初始化服务', () async {
      expect(service, isNotNull);
    });

    test('应该能够添加自选基金', () async {
      // 创建测试基金
      final favorite = FundFavorite(
        fundCode: '000001',
        fundName: '华夏成长混合',
        fundType: '混合型',
        fundManager: '华夏基金',
        addedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        notes: '测试基金',
      );

      // 添加基金
      await service.addFavorite(favorite);

      // 验证添加成功
      final isFavorite = await service.isFavorite('000001');
      expect(isFavorite, isTrue);

      // 验证能够获取基金
      final retrievedFavorite = await service.getFavoriteByCode('000001');
      expect(retrievedFavorite, isNotNull);
      expect(retrievedFavorite!.fundCode, equals('000001'));
      expect(retrievedFavorite.fundName, equals('华夏成长混合'));
    });

    test('应该能够获取所有自选基金', () async {
      // 添加多个测试基金
      final favorites = [
        FundFavorite(
          fundCode: '000001',
          fundName: '华夏成长混合',
          fundType: '混合型',
          fundManager: '华夏基金',
          addedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        FundFavorite(
          fundCode: '000002',
          fundName: '华夏回报混合',
          fundType: '混合型',
          fundManager: '华夏基金',
          addedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      for (final favorite in favorites) {
        await service.addFavorite(favorite);
      }

      // 获取所有基金
      final allFavorites = await service.getAllFavorites();
      expect(allFavorites.length, equals(2));
      expect(allFavorites.map((f) => f.fundCode), contains('000001'));
      expect(allFavorites.map((f) => f.fundCode), contains('000002'));
    });

    test('应该能够更新自选基金', () async {
      // 创建测试基金
      final favorite = FundFavorite(
        fundCode: '000001',
        fundName: '华夏成长混合',
        fundType: '混合型',
        fundManager: '华夏基金',
        addedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await service.addFavorite(favorite);

      // 更新基金信息
      final updatedFavorite = favorite.copyWith(
        fundName: '华夏成长混合A',
        notes: '更新后的备注',
        updatedAt: DateTime.now(),
      );

      await service.updateFavorite(updatedFavorite);

      // 验证更新成功
      final retrieved = await service.getFavoriteByCode('000001');
      expect(retrieved!.fundName, equals('华夏成长混合A'));
      expect(retrieved.notes, equals('更新后的备注'));
    });

    test('应该能够删除自选基金', () async {
      // 创建测试基金
      final favorite = FundFavorite(
        fundCode: '000001',
        fundName: '华夏成长混合',
        fundType: '混合型',
        fundManager: '华夏基金',
        addedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await service.addFavorite(favorite);

      // 验证基金已添加
      expect(await service.isFavorite('000001'), isTrue);

      // 删除基金
      await service.removeFavorite('000001');

      // 验证基金已删除
      expect(await service.isFavorite('000001'), isFalse);
      final retrieved = await service.getFavoriteByCode('000001');
      expect(retrieved, isNull);
    });

    test('应该能够搜索自选基金', () async {
      // 添加多个测试基金
      final favorites = [
        FundFavorite(
          fundCode: '000001',
          fundName: '华夏成长混合',
          fundType: '混合型',
          fundManager: '华夏基金',
          addedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        FundFavorite(
          fundCode: '110022',
          fundName: '易方达消费行业',
          fundType: '股票型',
          fundManager: '易方达基金',
          addedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      for (final favorite in favorites) {
        await service.addFavorite(favorite);
      }

      // 搜索测试
      final searchResults1 = await service.searchFavorites('华夏');
      expect(searchResults1.length, equals(1));
      expect(searchResults1.first.fundCode, equals('000001'));

      final searchResults2 = await service.searchFavorites('易方达');
      expect(searchResults2.length, equals(1));
      expect(searchResults2.first.fundCode, equals('110022'));

      final searchResults3 = await service.searchFavorites('消费');
      expect(searchResults3.length, equals(1));
      expect(searchResults3.first.fundCode, equals('110022'));
    });

    test('应该能够排序自选基金', () async {
      // 添加多个测试基金
      final now = DateTime.now();
      final favorites = [
        FundFavorite(
          fundCode: '000001',
          fundName: '华夏成长混合',
          fundType: '混合型',
          fundManager: '华夏基金',
          addedAt: now.subtract(const Duration(days: 2)),
          updatedAt: now,
          currentNav: 1.2500,
          dailyChange: 2.5,
        ),
        FundFavorite(
          fundCode: '110022',
          fundName: '易方达消费行业',
          fundType: '股票型',
          fundManager: '易方达基金',
          addedAt: now.subtract(const Duration(days: 1)),
          updatedAt: now,
          currentNav: 2.3500,
          dailyChange: -1.2,
        ),
        FundFavorite(
          fundCode: '161725',
          fundName: '招商中证白酒',
          fundType: '指数型',
          fundManager: '招商基金',
          addedAt: now,
          updatedAt: now,
          currentNav: 0.8500,
          dailyChange: 3.8,
        ),
      ];

      for (final favorite in favorites) {
        await service.addFavorite(favorite);
      }

      // 按添加时间降序排序
      final sortedByTime = await service.getSortedFavorites(
        sortType: FundFavoriteSortType.addTime,
        direction: FundFavoriteSortDirection.descending,
      );
      expect(sortedByTime[0].fundCode, equals('161725'));
      expect(sortedByTime[1].fundCode, equals('110022'));
      expect(sortedByTime[2].fundCode, equals('000001'));

      // 按日涨跌幅降序排序
      final sortedByChange = await service.getSortedFavorites(
        sortType: FundFavoriteSortType.dailyChange,
        direction: FundFavoriteSortDirection.descending,
      );
      expect(sortedByChange[0].fundCode, equals('161725')); // 3.8%
      expect(sortedByChange[1].fundCode, equals('000001')); // 2.5%
      expect(sortedByChange[2].fundCode, equals('110022')); // -1.2%
    });

    test('应该能够更新市场数据', () async {
      // 创建测试基金
      final favorite = FundFavorite(
        fundCode: '000001',
        fundName: '华夏成长混合',
        fundType: '混合型',
        fundManager: '华夏基金',
        addedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await service.addFavorite(favorite);

      // 更新市场数据
      await service.updateMarketData(
        '000001',
        currentNav: 1.3500,
        dailyChange: 2.5,
        previousNav: 1.3171,
      );

      // 验证数据更新
      final updated = await service.getFavoriteByCode('000001');
      expect(updated!.currentNav, equals(1.3500));
      expect(updated.dailyChange, equals(2.5));
      expect(updated.previousNav, equals(1.3171));
    });

    test('应该能够清空所有自选基金', () async {
      // 添加多个测试基金
      final favorites = [
        FundFavorite(
          fundCode: '000001',
          fundName: '华夏成长混合',
          fundType: '混合型',
          fundManager: '华夏基金',
          addedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        FundFavorite(
          fundCode: '110022',
          fundName: '易方达消费行业',
          fundType: '股票型',
          fundManager: '易方达基金',
          addedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      for (final favorite in favorites) {
        await service.addFavorite(favorite);
      }

      // 验证基金已添加
      expect(await service.getFavoriteCount(), equals(2));

      // 清空所有基金
      await service.clearAllFavorites();

      // 验证已清空
      expect(await service.getFavoriteCount(), equals(0));
      final allFavorites = await service.getAllFavorites();
      expect(allFavorites, isEmpty);
    });

    test('应该正确处理重复添加', () async {
      // 创建测试基金
      final favorite = FundFavorite(
        fundCode: '000001',
        fundName: '华夏成长混合',
        fundType: '混合型',
        fundManager: '华夏基金',
        addedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 添加基金
      await service.addFavorite(favorite);

      // 再次添加相同基金（应该覆盖）
      final updatedFavorite = favorite.copyWith(
        fundName: '华夏成长混合A',
        updatedAt: DateTime.now(),
      );

      await service.addFavorite(updatedFavorite);

      // 验证只有一只基金且信息已更新
      final count = await service.getFavoriteCount();
      expect(count, equals(1));

      final retrieved = await service.getFavoriteByCode('000001');
      expect(retrieved!.fundName, equals('华夏成长混合A'));
    });

    test('应该能够获取存储统计信息', () async {
      // 添加一些测试数据
      final favorite = FundFavorite(
        fundCode: '000001',
        fundName: '华夏成长混合',
        fundType: '混合型',
        fundManager: '华夏基金',
        addedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await service.addFavorite(favorite);

      // 获取统计信息
      final stats = await service.getStorageStats();
      expect(stats['favoriteCount'], equals(1));
      expect(stats['isInitialized'], isTrue);
      expect(stats['favoriteBoxSize'], equals(1));
    });
  });
}
