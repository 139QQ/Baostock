import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:jisu_fund_analyzer/src/features/fund/presentation/pages/watchlist_page.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/presentation/cubit/fund_favorite_cubit.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/presentation/cubit/fund_favorite_cubit.dart'
    as cubit;
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/fund_favorite/src/entities/fund_favorite.dart';

import 'watchlist_page_test.mocks.dart';

@GenerateMocks([FundFavoriteCubit])
void main() {
  group('WatchlistPage Tests', () {
    late MockFundFavoriteCubit mockCubit;

    setUp(() {
      mockCubit = MockFundFavoriteCubit();
    });

    Widget createWidgetUnderTest() {
      return MaterialApp(
        home: BlocProvider<FundFavoriteCubit>(
          create: (_) => mockCubit,
          child: const WatchlistPage(),
        ),
      );
    }

    testWidgets('should display loading state initially',
        (WidgetTester tester) async {
      // Arrange
      when(mockCubit.state).thenReturn(cubit.FundFavoriteLoading());
      when(mockCubit.stream)
          .thenAnswer((_) => Stream.value(cubit.FundFavoriteLoading()));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('加载中...'), findsOneWidget);
    });

    testWidgets('should display empty state when no favorites',
        (WidgetTester tester) async {
      // Arrange
      const emptyState = cubit.FundFavoriteLoaded(
        favorites: [],
        searchResults: [],
        favoriteStatusCache: {},
      );
      when(mockCubit.state).thenReturn(emptyState);
      when(mockCubit.stream).thenAnswer((_) => Stream.value(emptyState));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('暂无自选基金'), findsOneWidget);
      expect(find.text('点击下方按钮添加您关注的基金'), findsOneWidget);
      expect(find.byIcon(Icons.star_outline), findsOneWidget);
    });

    testWidgets('should display favorite list when data loaded',
        (WidgetTester tester) async {
      // Arrange
      final testFavorites = [
        createTestFundFavorite('000001', '华夏成长混合', '混合型'),
        createTestFundFavorite('110022', '易方达消费行业', '股票型'),
      ];

      final loadedState = cubit.FundFavoriteLoaded(
        favorites: testFavorites,
        searchResults: testFavorites,
        favoriteStatusCache: const {'000001': true, '110022': true},
        lastMessage: '已加载2只自选基金',
      );
      when(mockCubit.state).thenReturn(loadedState);
      when(mockCubit.stream).thenAnswer((_) => Stream.value(loadedState));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('000001'), findsOneWidget);
      expect(find.text('华夏成长混合'), findsOneWidget);
      expect(find.text('110022'), findsOneWidget);
      expect(find.text('易方达消费行业'), findsOneWidget);
      expect(find.text('已加载2只自选基金'), findsOneWidget);
    });

    testWidgets('should display search results when searching',
        (WidgetTester tester) async {
      // Arrange
      final allFavorites = [
        createTestFundFavorite('000001', '华夏成长混合', '混合型'),
        createTestFundFavorite('110022', '易方达消费行业', '股票型'),
      ];

      final searchResults = [allFavorites[0]]; // 只找到第一个

      final searchState = cubit.FundFavoriteLoaded(
        favorites: allFavorites,
        searchResults: searchResults,
        searchQuery: '华夏',
        favoriteStatusCache: const {'000001': true, '110022': true},
      );
      when(mockCubit.state).thenReturn(searchState);
      when(mockCubit.stream).thenAnswer((_) => Stream.value(searchState));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('000001'), findsOneWidget);
      expect(find.text('华夏成长混合'), findsOneWidget);
      expect(find.text('110022'), findsNothing); // 不在搜索结果中
      expect(find.text('找到1只相关基金'), findsOneWidget);
    });

    testWidgets('should display error state when error occurs',
        (WidgetTester tester) async {
      // Arrange
      const errorState = cubit.FundFavoriteError('网络连接失败');
      when(mockCubit.state).thenReturn(errorState);
      when(mockCubit.stream).thenAnswer((_) => Stream.value(errorState));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('出错了'), findsOneWidget);
      expect(find.text('网络连接失败'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('重试'), findsOneWidget);
    });

    testWidgets('should show add favorite dialog when FAB is tapped',
        (WidgetTester tester) async {
      // Arrange
      const loadedState = cubit.FundFavoriteLoaded(
        favorites: [],
        searchResults: [],
        favoriteStatusCache: {},
      );
      when(mockCubit.state).thenReturn(loadedState);
      when(mockCubit.stream).thenAnswer((_) => Stream.value(loadedState));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('添加自选基金'), findsOneWidget);
      expect(find.text('基金代码 *'), findsOneWidget);
      expect(find.text('基金名称 *'), findsOneWidget);
    });

    testWidgets('should show sort dialog when sort menu is selected',
        (WidgetTester tester) async {
      // Arrange
      const loadedState = cubit.FundFavoriteLoaded(
        favorites: [],
        searchResults: [],
        favoriteStatusCache: {},
      );
      when(mockCubit.state).thenReturn(loadedState);
      when(mockCubit.stream).thenAnswer((_) => Stream.value(loadedState));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('排序方式'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('排序方式'), findsOneWidget);
      expect(find.text('添加时间'), findsOneWidget);
      expect(find.text('基金代码'), findsOneWidget);
    });

    testWidgets('should show clear all confirmation dialog',
        (WidgetTester tester) async {
      // Arrange
      final loadedState = cubit.FundFavoriteLoaded(
        favorites: [createTestFundFavorite('000001', '华夏成长', '混合型')],
        searchResults: [createTestFundFavorite('000001', '华夏成长', '混合型')],
        favoriteStatusCache: const {'000001': true},
      );
      when(mockCubit.state).thenReturn(loadedState);
      when(mockCubit.stream).thenAnswer((_) => Stream.value(loadedState));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('清空全部'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('确认清空'), findsOneWidget);
      expect(find.text('确定要清空所有自选基金吗？此操作不可恢复。'), findsOneWidget);
      expect(find.text('清空全部'), findsOneWidget);
    });

    testWidgets('should trigger refresh when refresh is selected',
        (WidgetTester tester) async {
      // Arrange
      const loadedState = cubit.FundFavoriteLoaded(
        favorites: [],
        searchResults: [],
        favoriteStatusCache: {},
      );
      when(mockCubit.state).thenReturn(loadedState);
      when(mockCubit.stream).thenAnswer((_) => Stream.value(loadedState));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('刷新数据'));
      await tester.pump();

      // Assert
      verify(mockCubit.refresh()).called(1);
    });

    testWidgets('should show filter chips and trigger search',
        (WidgetTester tester) async {
      // Arrange
      final loadedState = cubit.FundFavoriteLoaded(
        favorites: [
          createTestFundFavorite('000001', '华夏成长', '混合型', dailyChange: 2.5),
          createTestFundFavorite('110022', '易方达消费', '股票型', dailyChange: -1.2),
        ],
        searchResults: const [],
        favoriteStatusCache: const {'000001': true, '110022': true},
      );
      when(mockCubit.state).thenReturn(loadedState);
      when(mockCubit.stream).thenAnswer((_) => Stream.value(loadedState));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // 测试涨幅榜筛选
      await tester.tap(find.text('涨幅榜'));
      await tester.pump();

      // Assert
      verify(mockCubit.sortFavorites(
        FundFavoriteSortType.dailyChange,
        FundFavoriteSortDirection.descending,
      )).called(1);
    });

    testWidgets('should show fund operation menu and handle actions',
        (WidgetTester tester) async {
      // Arrange
      final testFavorite = createTestFundFavorite('000001', '华夏成长', '混合型');
      final loadedState = cubit.FundFavoriteLoaded(
        favorites: [testFavorite],
        searchResults: [testFavorite],
        favoriteStatusCache: const {'000001': true},
      );
      when(mockCubit.state).thenReturn(loadedState);
      when(mockCubit.stream).thenAnswer((_) => Stream.value(loadedState));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('编辑'), findsOneWidget);
      expect(find.text('添加到持仓'), findsOneWidget);
      expect(find.text('移除'), findsOneWidget);
    });

    testWidgets('should add favorite successfully',
        (WidgetTester tester) async {
      // Arrange
      const loadedState = cubit.FundFavoriteLoaded(
        favorites: [],
        searchResults: [],
        favoriteStatusCache: {},
      );
      when(mockCubit.state).thenReturn(loadedState);
      when(mockCubit.stream).thenAnswer((_) => Stream.value(loadedState));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // 填写表单
      await tester.enterText(
          find.byKey(const Key('fund_code_field')), '000001');
      await tester.enterText(
          find.byKey(const Key('fund_name_field')), '华夏成长混合');
      await tester.tap(find.text('添加基金'));
      await tester.pumpAndSettle();

      // Assert
      verify(mockCubit.addFavorite(any)).called(1);
    });

    testWidgets('should validate form input correctly',
        (WidgetTester tester) async {
      // Arrange
      const loadedState = cubit.FundFavoriteLoaded(
        favorites: [],
        searchResults: [],
        favoriteStatusCache: {},
      );
      when(mockCubit.state).thenReturn(loadedState);
      when(mockCubit.stream).thenAnswer((_) => Stream.value(loadedState));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // 不填写任何内容直接提交
      await tester.tap(find.text('添加基金'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('请输入6位基金代码'), findsOneWidget);
      expect(find.text('请输入基金名称'), findsOneWidget);
    });

    testWidgets('should handle search functionality',
        (WidgetTester tester) async {
      // Arrange
      final loadedState = cubit.FundFavoriteLoaded(
        favorites: [createTestFundFavorite('000001', '华夏成长', '混合型')],
        searchResults: const [],
        favoriteStatusCache: const {'000001': true},
      );
      when(mockCubit.state).thenReturn(loadedState);
      when(mockCubit.stream).thenAnswer((_) => Stream.value(loadedState));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '华夏');
      await tester.pump();

      // Assert
      verify(mockCubit.searchFavorites('华夏')).called(1);
    });

    testWidgets('should remove favorite with confirmation',
        (WidgetTester tester) async {
      // Arrange
      final testFavorite = createTestFundFavorite('000001', '华夏成长', '混合型');
      final loadedState = cubit.FundFavoriteLoaded(
        favorites: [testFavorite],
        searchResults: [testFavorite],
        favoriteStatusCache: const {'000001': true},
      );
      when(mockCubit.state).thenReturn(loadedState);
      when(mockCubit.stream).thenAnswer((_) => Stream.value(loadedState));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('移除'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('移除'));
      await tester.pump();

      // Assert
      verify(mockCubit.removeFavorite('000001')).called(1);
    });
  });

  group('WatchlistPage Widget Tests', () {
    testWidgets('should display correct fund type colors',
        (WidgetTester tester) async {
      // 测试不同基金类型的颜色显示
      final testCases = [
        ('股票型', Colors.red),
        ('债券型', Colors.blue),
        ('混合型', Colors.orange),
        ('货币型', Colors.green),
        ('指数型', Colors.purple),
      ];

      for (final testCase in testCases) {
        final favorite = createTestFundFavorite('000001', '测试基金', testCase.$1);
        final loadedState = cubit.FundFavoriteLoaded(
          favorites: [favorite],
          searchResults: [favorite],
          favoriteStatusCache: const {'000001': true},
        );

        final mockCubit = MockFundFavoriteCubit();
        when(mockCubit.state).thenReturn(loadedState);
        when(mockCubit.stream).thenAnswer((_) => Stream.value(loadedState));

        await tester.pumpWidget(MaterialApp(
          home: BlocProvider<FundFavoriteCubit>(
            create: (_) => mockCubit,
            child: const WatchlistPage(),
          ),
        ));
        await tester.pumpAndSettle();

        // 验证基金类型标签的颜色
        final fundTypeChip = tester.widget<Container>(find.descendant(
          of: find.byType(Card),
          matching: find.byType(Container),
        ));

        expect(fundTypeChip.decoration, isA<BoxDecoration>());
        final decoration = fundTypeChip.decoration as BoxDecoration;
        expect(decoration.color, testCase.$2.withOpacity(0.1));

        await tester.pumpWidget(Container()); // 清理
      }
    });

    testWidgets('should handle operation success messages',
        (WidgetTester tester) async {
      // 测试操作成功消息的显示
      final testFavorite = createTestFundFavorite('000001', '华夏成长', '混合型');
      final baseState = cubit.FundFavoriteLoaded(
        favorites: [testFavorite],
        searchResults: [testFavorite],
        favoriteStatusCache: const {'000001': true},
      );

      final mockCubit = MockFundFavoriteCubit();
      when(mockCubit.state).thenReturn(baseState);
      when(mockCubit.stream).thenAnswer((_) => Stream.value(
            cubit.FundFavoriteOperationSuccess('已添加华夏成长到自选', baseState),
          ));

      await tester.pumpWidget(MaterialApp(
        home: BlocProvider<FundFavoriteCubit>(
          create: (_) => mockCubit,
          child: const WatchlistPage(),
        ),
      ));
      await tester.pumpAndSettle();

      // 等待SnackBar显示
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('已添加华夏成长到自选'), findsOneWidget);
    });
  });
}

// 测试辅助函数
FundFavorite createTestFundFavorite(
  String code,
  String name,
  String type, {
  double? currentNav,
  double? dailyChange,
}) {
  return FundFavorite(
    fundCode: code,
    fundName: name,
    fundType: type,
    fundManager: '测试基金公司',
    addedAt: DateTime.now().subtract(const Duration(days: 1)),
    updatedAt: DateTime.now(),
    currentNav: currentNav ?? 1.2345,
    dailyChange: dailyChange ?? 1.23,
    notes: '测试备注',
  );
}
