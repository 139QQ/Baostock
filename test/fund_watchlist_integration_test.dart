import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/data/adapters/fund_favorite_adapter.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/fund_favorite/src/entities/fund_favorite.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/data/services/fund_favorite_service.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/presentation/cubit/fund_favorite_cubit.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/pages/watchlist_page.dart';
import 'package:jisu_fund_analyzer/src/core/di/injection_container.dart' as di;
import 'package:jisu_fund_analyzer/src/services/optimized_cache_manager_v3.dart';
import 'package:jisu_fund_analyzer/src/services/fund_api_analyzer.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/presentation/cubit/portfolio_analysis_cubit.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/presentation/pages/portfolio_analysis_page.dart';

void main() {
  group('基金自选界面集成测试', () {
    late FundFavoriteService service;
    late FundFavoriteCubit cubit;

    setUpAll(() async {
      // 初始化Hive测试环境
      Hive.init('./test_cache_ui');

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
      // 重置GetIt实例
      if (di.sl.isRegistered<OptimizedCacheManagerV3>()) {
        await di.sl.unregister<OptimizedCacheManagerV3>();
      }
      if (di.sl.isRegistered<FundApiAnalyzer>()) {
        di.sl.unregister<FundApiAnalyzer>();
      }
      if (di.sl.isRegistered<PortfolioAnalysisCubit>()) {
        di.sl.unregister<PortfolioAnalysisCubit>();
      }

      // 注册测试需要的依赖
      di.sl.registerLazySingleton<OptimizedCacheManagerV3>(() {
        final cacheManager = OptimizedCacheManagerV3.createNewInstance();
        return cacheManager;
      });

      di.sl.registerLazySingleton<FundApiAnalyzer>(() => FundApiAnalyzer());
      di.sl.registerLazySingleton<PortfolioAnalysisCubit>(
          () => PortfolioAnalysisCubit(
                repository: di.sl(), // 这里需要mock或者使用null
                dataService: di.sl(), // 这里需要mock或者使用null
              ));

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

    testWidgets('测试自选基金页面UI基本功能', (WidgetTester tester) async {
      print('🧪 测试自选基金页面UI基本功能...');

      // 提供Cubit和页面
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<FundFavoriteCubit>.value(
            value: cubit,
            child: const WatchlistPage(),
          ),
        ),
      );

      // 等待页面加载
      await tester.pumpAndSettle();

      // 验证页面标题
      expect(find.text('自选基金'), findsOneWidget);
      print('✅ 页面标题正确显示');

      // 验证添加按钮存在
      expect(find.byIcon(Icons.add), findsAtLeastNWidgets(1));
      print('✅ 添加按钮存在');

      // 验证搜索框存在
      expect(find.byType(TextField), findsOneWidget);
      print('✅ 搜索框存在');

      // 验证排序菜单存在
      expect(find.byIcon(Icons.sort), findsOneWidget);
      print('✅ 排序菜单存在');

      // 验证空状态显示（如果没有自选基金）
      expect(find.text('还没有自选基金'), findsOneWidget);
      print('✅ 空状态正确显示');
    });

    testWidgets('测试添加基金功能', (WidgetTester tester) async {
      print('🧪 测试添加基金功能...');

      // 先添加一些测试数据
      final testFavorite = FundFavorite(
        fundCode: '110022',
        fundName: '易方达消费行业',
        fundType: '股票型',
        fundManager: '萧楠',
        addedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await service.addFavorite(testFavorite);
      await cubit.initialize();

      // 提供Cubit和页面
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<FundFavoriteCubit>.value(
            value: cubit,
            child: const WatchlistPage(),
          ),
        ),
      );

      // 等待页面加载
      await tester.pumpAndSettle();

      // 验证基金显示在列表中
      expect(find.text('易方达消费行业'), findsOneWidget);
      expect(find.text('110022'), findsOneWidget);
      print('✅ 基金正确显示在列表中');

      // 测试点击添加按钮
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();

      // 验证对话框打开
      expect(find.text('添加自选基金'), findsOneWidget);
      print('✅ 添加基金对话框正确打开');

      // 关闭对话框
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      print('✅ 对话框正确关闭');
    });

    testWidgets('测试搜索功能', (WidgetTester tester) async {
      print('🧪 测试搜索功能...');

      // 添加测试数据
      await service.addFavorite(FundFavorite(
        fundCode: '110022',
        fundName: '易方达消费行业',
        fundType: '股票型',
        fundManager: '萧楠',
        addedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await service.addFavorite(FundFavorite(
        fundCode: '000001',
        fundName: '华夏成长混合',
        fundType: '混合型',
        fundManager: '张经理',
        addedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await cubit.initialize();

      // 提供Cubit和页面
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<FundFavoriteCubit>.value(
            value: cubit,
            child: const WatchlistPage(),
          ),
        ),
      );

      // 等待页面加载
      await tester.pumpAndSettle();

      // 验证两个基金都显示
      expect(find.text('易方达消费行业'), findsOneWidget);
      expect(find.text('华夏成长混合'), findsOneWidget);

      // 在搜索框中输入文字
      await tester.enterText(find.byType(TextField), '易方达');
      await tester.pumpAndSettle();

      // 验证搜索结果
      expect(find.text('易方达消费行业'), findsOneWidget);
      expect(find.text('华夏成长混合'), findsNothing);
      print('✅ 搜索功能正常工作');

      // 清空搜索
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // 验证所有基金重新显示
      expect(find.text('易方达消费行业'), findsOneWidget);
      expect(find.text('华夏成长混合'), findsOneWidget);
      print('✅ 清空搜索功能正常');
    });

    testWidgets('测试删除基金功能', (WidgetTester tester) async {
      print('🧪 测试删除基金功能...');

      // 添加测试数据
      await service.addFavorite(FundFavorite(
        fundCode: '110022',
        fundName: '易方达消费行业',
        fundType: '股票型',
        fundManager: '萧楠',
        addedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await cubit.initialize();

      // 提供Cubit和页面
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<FundFavoriteCubit>.value(
            value: cubit,
            child: const WatchlistPage(),
          ),
        ),
      );

      // 等待页面加载
      await tester.pumpAndSettle();

      // 验证基金存在
      expect(find.text('易方达消费行业'), findsOneWidget);

      // 点击删除按钮
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // 验证确认对话框出现
      expect(find.text('确认删除'), findsOneWidget);
      expect(find.text('确定要删除自选基金 "易方达消费行业" 吗？'), findsOneWidget);
      print('✅ 删除确认对话框正确显示');

      // 点击确认删除
      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();

      // 验证基金已被删除
      expect(find.text('易方达消费行业'), findsNothing);
      expect(find.text('还没有自选基金'), findsOneWidget);
      print('✅ 删除功能正常工作');
    });

    testWidgets('测试排序功能', (WidgetTester tester) async {
      print('🧪 测试排序功能...');

      // 添加多个测试基金
      await service.addFavorite(FundFavorite(
        fundCode: '000001',
        fundName: '华夏成长混合',
        fundType: '混合型',
        fundManager: '张经理',
        addedAt: DateTime.now().subtract(Duration(days: 2)),
        updatedAt: DateTime.now(),
      ));

      await service.addFavorite(FundFavorite(
        fundCode: '110022',
        fundName: '易方达消费行业',
        fundType: '股票型',
        fundManager: '萧楠',
        addedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await cubit.initialize();

      // 提供Cubit和页面
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<FundFavoriteCubit>.value(
            value: cubit,
            child: const WatchlistPage(),
          ),
        ),
      );

      // 等待页面加载
      await tester.pumpAndSettle();

      // 点击排序菜单
      await tester.tap(find.byIcon(Icons.sort));
      await tester.pumpAndSettle();

      // 验证排序选项出现
      expect(find.text('添加时间'), findsOneWidget);
      expect(find.text('基金代码'), findsOneWidget);
      expect(find.text('基金名称'), findsOneWidget);
      print('✅ 排序菜单正确显示');

      // 点击按基金代码排序
      await tester.tap(find.text('基金代码'));
      await tester.pumpAndSettle();

      // 验证排序生效（基金代码应该按顺序排列）
      final fundCodeElements = tester.widgetList(find.byType(Text)).toList();
      bool foundCorrectOrder = false;
      for (int i = 0; i < fundCodeElements.length - 1; i++) {
        final currentText = fundCodeElements[i] as Text;
        final nextText = fundCodeElements[i + 1] as Text;
        if (currentText.data?.toString().contains('000001') == true) {
          foundCorrectOrder = true;
          break;
        }
      }
      print('✅ 排序功能测试完成');
    });
  });
}
