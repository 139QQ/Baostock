import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/data/adapters/fund_favorite_adapter.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/fund_favorite/src/entities/fund_favorite.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/fund_favorite/src/entities/fund_favorite_list.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/data/services/fund_favorite_service.dart';
import 'package:jisu_fund_analyzer/src/core/error/exceptions.dart';

void main() {
  group('基金自选功能问题诊断测试', () {
    late FundFavoriteService service;

    setUp(() async {
      // 初始化Hive测试环境
      Hive.init('./test_cache');

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

      service = FundFavoriteService();
      await service.initialize();
    });

    tearDown(() async {
      await service.dispose();
      await Hive.deleteBoxFromDisk('fund_favorites');
      await Hive.deleteBoxFromDisk('fund_favorite_lists');
    });

    test('测试1: 基本添加和检索功能', () async {
      print('🧪 测试基本添加和检索功能...');

      final favorite = FundFavorite(
        fundCode: '000001',
        fundName: '华夏成长混合',
        fundType: '混合型',
        fundManager: '张经理',
        addedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 添加基金
      await service.addFavorite(favorite);

      // 检索基金
      final retrieved = await service.getFavoriteByCode('000001');
      expect(retrieved, isNotNull);
      expect(retrieved!.fundCode, equals('000001'));
      expect(retrieved.fundName, equals('华夏成长混合'));

      print('✅ 基本添加和检索功能正常');
    });

    test('测试2: 重复添加检测', () async {
      print('🧪 测试重复添加检测...');

      final favorite = FundFavorite(
        fundCode: '000002',
        fundName: '沪深300指数',
        fundType: '指数型',
        fundManager: '李经理',
        addedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 第一次添加应该成功
      await service.addFavorite(favorite);

      // 第二次添加应该抛出异常
      try {
        await service.addFavorite(favorite);
        fail('应该抛出异常，但没有');
      } catch (e) {
        expect(e, isA<CacheException>());
        print('✅ 重复添加检测正常');
      }
    });

    test('测试3: 排序功能', () async {
      print('🧪 测试排序功能...');

      // 添加多个基金
      final funds = [
        FundFavorite(
          fundCode: '000003',
          fundName: '易方达蓝筹',
          fundType: '股票型',
          fundManager: '王经理',
          addedAt: DateTime.now().subtract(Duration(days: 2)),
          updatedAt: DateTime.now(),
        ),
        FundFavorite(
          fundCode: '000004',
          fundName: '嘉实稳健',
          fundType: '债券型',
          fundManager: '赵经理',
          addedAt: DateTime.now().subtract(Duration(days: 1)),
          updatedAt: DateTime.now(),
        ),
        FundFavorite(
          fundCode: '000005',
          fundName: '南方积极',
          fundType: '混合型',
          fundManager: '刘经理',
          addedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      for (final fund in funds) {
        await service.addFavorite(fund);
      }

      // 测试按添加时间排序（降序）
      final sortedByTime = await service.getSortedFavorites(
        sortType: FundFavoriteSortType.addTime,
        direction: FundFavoriteSortDirection.descending,
      );

      expect(sortedByTime.length, equals(3));
      expect(sortedByTime[0].fundCode, equals('000005')); // 最近的
      expect(sortedByTime[2].fundCode, equals('000003')); // 最老的

      print('✅ 排序功能正常');
    });

    test('测试4: 搜索功能', () async {
      print('🧪 测试搜索功能...');

      // 添加测试数据
      await service.addFavorite(FundFavorite(
        fundCode: '000006',
        fundName: '科技创新混合',
        fundType: '混合型',
        fundManager: '陈经理',
        addedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await service.addFavorite(FundFavorite(
        fundCode: '000007',
        fundName: '消费升级股票',
        fundType: '股票型',
        fundManager: '周经理',
        addedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      // 搜索测试
      final searchResults = await service.searchFavorites('科技');
      expect(searchResults.length, equals(1));
      expect(searchResults[0].fundName, contains('科技'));

      final searchResults2 = await service.searchFavorites('股票');
      expect(searchResults2.length, equals(1));
      expect(searchResults2[0].fundType, contains('股票'));

      print('✅ 搜索功能正常');
    });

    test('测试5: 删除功能', () async {
      print('🧪 测试删除功能...');

      final favorite = FundFavorite(
        fundCode: '000008',
        fundName: '医药健康基金',
        fundType: '股票型',
        fundManager: '吴经理',
        addedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 添加基金
      await service.addFavorite(favorite);
      expect(await service.getFavoriteByCode('000008'), isNotNull);

      // 删除基金
      await service.removeFavorite('000008');
      expect(await service.getFavoriteByCode('000008'), isNull);

      print('✅ 删除功能正常');
    });

    test('测试6: 数据持久化验证', () async {
      print('🧪 测试数据持久化验证...');

      final favorite = FundFavorite(
        fundCode: '000009',
        fundName: '新能源主题',
        fundType: '股票型',
        fundManager: '郑经理',
        addedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        notes: '测试备注',
        currentNav: 1.2345,
        dailyChange: 0.05,
      );

      // 添加数据
      await service.addFavorite(favorite);

      // 创建新的服务实例（模拟应用重启）
      await service.dispose();
      final newService = FundFavoriteService();
      await newService.initialize();

      // 验证数据是否持久化
      final persisted = await newService.getFavoriteByCode('000009');
      expect(persisted, isNotNull);
      expect(persisted!.fundCode, equals('000009'));
      expect(persisted.fundName, equals('新能源主题'));
      expect(persisted.notes, equals('测试备注'));
      expect(persisted.currentNav, equals(1.2345));
      expect(persisted.dailyChange, equals(0.05));

      await newService.dispose();
      print('✅ 数据持久化验证正常');
    });
  });
}
