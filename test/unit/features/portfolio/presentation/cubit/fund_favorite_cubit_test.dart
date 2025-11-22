import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:jisu_fund_analyzer/src/features/portfolio/presentation/cubit/fund_favorite_cubit.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/presentation/cubit/fund_favorite_cubit.dart'
    as cubit;
import 'package:jisu_fund_analyzer/src/features/portfolio/data/services/fund_favorite_service.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/fund_favorite/src/entities/fund_favorite.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/fund_favorite/src/entities/fund_favorite_list.dart';

import 'fund_favorite_cubit_test.mocks.dart';

@GenerateMocks([FundFavoriteService])
void main() {
  group('FundFavoriteCubit Tests', () {
    late MockFundFavoriteService mockService;
    late FundFavoriteCubit favoriteCubit;

    setUp(() {
      mockService = MockFundFavoriteService();
      favoriteCubit = FundFavoriteCubit(mockService);
    });

    tearDown(() {
      favoriteCubit.close();
    });

    group('Initialization', () {
      test('should start with FundFavoriteInitial state', () {
        // Assert
        expect(favoriteCubit.state, isA<cubit.FundFavoriteInitial>());
      });

      test('should initialize successfully and load favorites', () async {
        // Arrange
        final testFavorites = [
          createTestFundFavorite('000001', '华夏成长', '混合型'),
          createTestFundFavorite('110022', '易方达消费', '股票型'),
        ];

        when(mockService.initialize()).thenAnswer((_) async {});
        when(mockService.getAllFavorites())
            .thenAnswer((_) async => testFavorites);
        when(mockService.getAllLists()).thenAnswer((_) async => []);

        // Act
        await favoriteCubit.initialize();

        // Assert
        expect(favoriteCubit.state, isA<cubit.FundFavoriteLoaded>());
        final loadedState = favoriteCubit.state as cubit.FundFavoriteLoaded;
        expect(loadedState.favorites, hasLength(2));
        expect(loadedState.favorites[0].fundCode, '000001');
        expect(loadedState.favorites[1].fundCode, '110022');
        expect(loadedState.lastMessage, '已加载2只自选基金');

        verify(mockService.initialize()).called(1);
        verify(mockService.getAllFavorites()).called(1);
        verify(mockService.getAllLists()).called(1);
      });

      test('should emit error state when initialization fails', () async {
        // Arrange
        when(mockService.initialize()).thenThrow(Exception('初始化失败'));

        // Act
        await favoriteCubit.initialize();

        // Assert
        expect(favoriteCubit.state, isA<cubit.FundFavoriteError>());
        final errorState = favoriteCubit.state as cubit.FundFavoriteError;
        expect(errorState.error, contains('初始化失败'));

        verify(mockService.initialize()).called(1);
        verifyNever(mockService.getAllFavorites());
      });
    });

    group('Load All Favorites', () {
      test('should load favorites successfully', () async {
        // Arrange
        final testFavorites = [
          createTestFundFavorite('000001', '华夏成长', '混合型'),
        ];

        when(mockService.getAllFavorites())
            .thenAnswer((_) async => testFavorites);

        // Act
        await favoriteCubit.loadAllFavorites();

        // Assert
        expect(favoriteCubit.state, isA<cubit.FundFavoriteLoaded>());
        final loadedState = favoriteCubit.state as cubit.FundFavoriteLoaded;
        expect(loadedState.favorites, hasLength(1));
        expect(loadedState.favoriteStatusCache['000001'], isTrue);

        verify(mockService.getAllFavorites()).called(1);
      });

      test('should handle empty favorites list', () async {
        // Arrange
        when(mockService.getAllFavorites()).thenAnswer((_) async => []);

        // Act
        await favoriteCubit.loadAllFavorites();

        // Assert
        expect(favoriteCubit.state, isA<cubit.FundFavoriteLoaded>());
        final loadedState = favoriteCubit.state as cubit.FundFavoriteLoaded;
        expect(loadedState.favorites, isEmpty);
        expect(loadedState.favoriteStatusCache, isEmpty);

        verify(mockService.getAllFavorites()).called(1);
      });

      test('should handle load favorites error', () async {
        // Arrange
        when(mockService.getAllFavorites()).thenThrow(Exception('加载失败'));

        // Act
        await favoriteCubit.loadAllFavorites();

        // Assert
        expect(favoriteCubit.state, isA<cubit.FundFavoriteError>());
        final errorState = favoriteCubit.state as cubit.FundFavoriteError;
        expect(errorState.error, contains('加载自选基金失败'));

        verify(mockService.getAllFavorites()).called(1);
      });
    });

    group('Add Favorite', () {
      test('should add favorite successfully', () async {
        // Arrange
        final existingFavorites = [
          createTestFundFavorite('000001', '华夏成长', '混合型'),
        ];
        final newFavorite = createTestFundFavorite('110022', '易方达消费', '股票型');

        favoriteCubit.emit(cubit.FundFavoriteLoaded(
          favorites: existingFavorites,
          searchResults: existingFavorites,
          favoriteStatusCache: const {'000001': true},
        ));

        when(mockService.addFavorite(any)).thenAnswer((_) async {});

        // Act
        await favoriteCubit.addFavorite(newFavorite);

        // Assert
        expect(favoriteCubit.state, isA<cubit.FundFavoriteLoaded>());
        final loadedState = favoriteCubit.state as cubit.FundFavoriteLoaded;
        expect(loadedState.favorites, hasLength(2));
        expect(loadedState.favoriteStatusCache['110022'], isTrue);
        expect(loadedState.lastMessage, '已添加易方达消费到自选');

        verify(mockService.addFavorite(newFavorite)).called(1);
      });

      test('should not add duplicate favorite', () async {
        // Arrange
        final existingFavorite =
            createTestFundFavorite('000001', '华夏成长', '混合型');
        final duplicateFavorite =
            createTestFundFavorite('000001', '华夏成长', '混合型');

        favoriteCubit.emit(cubit.FundFavoriteLoaded(
          favorites: [existingFavorite],
          searchResults: [existingFavorite],
          favoriteStatusCache: const {'000001': true},
        ));

        // Act
        await favoriteCubit.addFavorite(duplicateFavorite);

        // Assert
        expect(favoriteCubit.state, isA<cubit.FundFavoriteOperationSuccess>());
        final successState =
            favoriteCubit.state as cubit.FundFavoriteOperationSuccess;
        expect(successState.message, '基金华夏成长已在自选中');

        verifyNever(mockService.addFavorite(any));
      });

      test('should handle add favorite error', () async {
        // Arrange
        final newFavorite = createTestFundFavorite('110022', '易方达消费', '股票型');

        favoriteCubit.emit(const cubit.FundFavoriteLoaded(
          favorites: [],
          searchResults: [],
          favoriteStatusCache: {},
        ));

        when(mockService.addFavorite(any)).thenThrow(Exception('添加失败'));

        // Act
        await favoriteCubit.addFavorite(newFavorite);

        // Assert
        expect(favoriteCubit.state, isA<cubit.FundFavoriteError>());
        final errorState = favoriteCubit.state as cubit.FundFavoriteError;
        expect(errorState.error, contains('添加自选基金失败'));

        verify(mockService.addFavorite(newFavorite)).called(1);
      });
    });

    group('Update Favorite', () {
      test('should update favorite successfully', () async {
        // Arrange
        final originalFavorite =
            createTestFundFavorite('000001', '华夏成长', '混合型');
        final updatedFavorite =
            createTestFundFavorite('000001', '华夏成长混合', '混合型');

        favoriteCubit.emit(cubit.FundFavoriteLoaded(
          favorites: [originalFavorite],
          searchResults: [originalFavorite],
          favoriteStatusCache: const {'000001': true},
        ));

        when(mockService.updateFavorite(any)).thenAnswer((_) async {});

        // Act
        await favoriteCubit.updateFavorite(updatedFavorite);

        // Assert
        expect(favoriteCubit.state, isA<cubit.FundFavoriteLoaded>());
        final loadedState = favoriteCubit.state as cubit.FundFavoriteLoaded;
        expect(loadedState.favorites, hasLength(1));
        expect(loadedState.favorites[0].fundName, '华夏成长混合');
        expect(loadedState.lastMessage, '已更新华夏成长混合');

        verify(mockService.updateFavorite(updatedFavorite)).called(1);
      });

      test('should handle update favorite error', () async {
        // Arrange
        final originalFavorite =
            createTestFundFavorite('000001', '华夏成长', '混合型');
        final updatedFavorite =
            createTestFundFavorite('000001', '华夏成长混合', '混合型');

        favoriteCubit.emit(cubit.FundFavoriteLoaded(
          favorites: [originalFavorite],
          searchResults: [originalFavorite],
          favoriteStatusCache: const {'000001': true},
        ));

        when(mockService.updateFavorite(any)).thenThrow(Exception('更新失败'));

        // Act
        await favoriteCubit.updateFavorite(updatedFavorite);

        // Assert
        expect(favoriteCubit.state, isA<cubit.FundFavoriteError>());
        final errorState = favoriteCubit.state as cubit.FundFavoriteError;
        expect(errorState.error, contains('更新自选基金失败'));

        verify(mockService.updateFavorite(updatedFavorite)).called(1);
      });
    });

    group('Remove Favorite', () {
      test('should remove favorite successfully', () async {
        // Arrange
        final favorite1 = createTestFundFavorite('000001', '华夏成长', '混合型');
        final favorite2 = createTestFundFavorite('110022', '易方达消费', '股票型');

        favoriteCubit.emit(cubit.FundFavoriteLoaded(
          favorites: [favorite1, favorite2],
          searchResults: [favorite1, favorite2],
          favoriteStatusCache: const {'000001': true, '110022': true},
        ));

        when(mockService.removeFavorite('000001')).thenAnswer((_) async {});

        // Act
        await favoriteCubit.removeFavorite('000001');

        // Assert
        expect(favoriteCubit.state, isA<cubit.FundFavoriteLoaded>());
        final loadedState = favoriteCubit.state as cubit.FundFavoriteLoaded;
        expect(loadedState.favorites, hasLength(1));
        expect(loadedState.favorites[0].fundCode, '110022');
        expect(loadedState.favoriteStatusCache['000001'], isFalse);
        expect(loadedState.lastMessage, '已移除华夏成长');

        verify(mockService.removeFavorite('000001')).called(1);
      });

      test('should handle remove favorite error', () async {
        // Arrange
        final favorite = createTestFundFavorite('000001', '华夏成长', '混合型');

        favoriteCubit.emit(cubit.FundFavoriteLoaded(
          favorites: [favorite],
          searchResults: [favorite],
          favoriteStatusCache: const {'000001': true},
        ));

        when(mockService.removeFavorite('000001')).thenThrow(Exception('删除失败'));

        // Act
        await favoriteCubit.removeFavorite('000001');

        // Assert
        expect(favoriteCubit.state, isA<cubit.FundFavoriteError>());
        final errorState = favoriteCubit.state as cubit.FundFavoriteError;
        expect(errorState.error, contains('删除自选基金失败'));

        verify(mockService.removeFavorite('000001')).called(1);
      });
    });

    group('Search Favorites', () {
      test('should search favorites by fund code', () async {
        // Arrange
        final favorites = [
          createTestFundFavorite('000001', '华夏成长', '混合型'),
          createTestFundFavorite('110022', '易方达消费', '股票型'),
        ];

        favoriteCubit.emit(cubit.FundFavoriteLoaded(
          favorites: favorites,
          searchResults: favorites,
          favoriteStatusCache: const {'000001': true, '110022': true},
        ));

        // Act
        await favoriteCubit.searchFavorites('000001');

        // Assert
        expect(favoriteCubit.state, isA<cubit.FundFavoriteLoaded>());
        final loadedState = favoriteCubit.state as cubit.FundFavoriteLoaded;
        expect(loadedState.searchResults, hasLength(1));
        expect(loadedState.searchResults[0].fundCode, '000001');
        expect(loadedState.searchQuery, '000001');
        expect(loadedState.lastMessage, '找到1只相关基金');
      });

      test('should search favorites by fund name', () async {
        // Arrange
        final favorites = [
          createTestFundFavorite('000001', '华夏成长', '混合型'),
          createTestFundFavorite('110022', '易方达消费', '股票型'),
        ];

        favoriteCubit.emit(cubit.FundFavoriteLoaded(
          favorites: favorites,
          searchResults: favorites,
          favoriteStatusCache: const {'000001': true, '110022': true},
        ));

        // Act
        await favoriteCubit.searchFavorites('华夏');

        // Assert
        expect(favoriteCubit.state, isA<cubit.FundFavoriteLoaded>());
        final loadedState = favoriteCubit.state as cubit.FundFavoriteLoaded;
        expect(loadedState.searchResults, hasLength(1));
        expect(loadedState.searchResults[0].fundName, contains('华夏'));
      });

      test('should clear search and show all favorites', () async {
        // Arrange
        final favorites = [
          createTestFundFavorite('000001', '华夏成长', '混合型'),
          createTestFundFavorite('110022', '易方达消费', '股票型'),
        ];

        favoriteCubit.emit(cubit.FundFavoriteLoaded(
          favorites: favorites,
          searchResults: [favorites[0]], // 搜索结果只有第一个
          searchQuery: '华夏',
          favoriteStatusCache: const {'000001': true, '110022': true},
        ));

        // Act
        await favoriteCubit.searchFavorites('');

        // Assert
        expect(favoriteCubit.state, isA<cubit.FundFavoriteLoaded>());
        final loadedState = favoriteCubit.state as cubit.FundFavoriteLoaded;
        expect(loadedState.searchResults, hasLength(2));
        expect(loadedState.searchQuery, '');
        expect(loadedState.lastMessage, '显示全部2只基金');
      });

      test('should return empty results for non-matching search', () async {
        // Arrange
        final favorites = [
          createTestFundFavorite('000001', '华夏成长', '混合型'),
          createTestFundFavorite('110022', '易方达消费', '股票型'),
        ];

        favoriteCubit.emit(cubit.FundFavoriteLoaded(
          favorites: favorites,
          searchResults: favorites,
          favoriteStatusCache: const {'000001': true, '110022': true},
        ));

        // Act
        await favoriteCubit.searchFavorites('不存在的基金');

        // Assert
        expect(favoriteCubit.state, isA<cubit.FundFavoriteLoaded>());
        final loadedState = favoriteCubit.state as cubit.FundFavoriteLoaded;
        expect(loadedState.searchResults, isEmpty);
        expect(loadedState.lastMessage, '找到0只相关基金');
      });
    });

    group('Sort Favorites', () {
      test('should sort favorites by fund code ascending', () async {
        // Arrange
        final favorites = [
          createTestFundFavorite('110022', '易方达消费', '股票型'),
          createTestFundFavorite('000001', '华夏成长', '混合型'),
        ];

        final sortedFavorites = [
          createTestFundFavorite('000001', '华夏成长', '混合型'),
          createTestFundFavorite('110022', '易方达消费', '股票型'),
        ];

        favoriteCubit.emit(cubit.FundFavoriteLoaded(
          favorites: favorites,
          searchResults: favorites,
          favoriteStatusCache: const {'000001': true, '110022': true},
        ));

        when(mockService.getSortedFavorites(
          sortType: FundFavoriteSortType.fundCode,
          direction: FundFavoriteSortDirection.ascending,
        )).thenAnswer((_) async => sortedFavorites);

        // Act
        await favoriteCubit.sortFavorites(
          FundFavoriteSortType.fundCode,
          FundFavoriteSortDirection.ascending,
        );

        // Assert
        expect(favoriteCubit.state, isA<cubit.FundFavoriteLoaded>());
        final loadedState = favoriteCubit.state as cubit.FundFavoriteLoaded;
        expect(loadedState.favorites[0].fundCode, '000001');
        expect(loadedState.favorites[1].fundCode, '110022');
        expect(loadedState.currentSortType, FundFavoriteSortType.fundCode);
        expect(loadedState.currentSortDirection,
            FundFavoriteSortDirection.ascending);

        verify(mockService.getSortedFavorites(
          sortType: FundFavoriteSortType.fundCode,
          direction: FundFavoriteSortDirection.ascending,
        )).called(1);
      });

      test('should handle sort favorites error', () async {
        // Arrange
        final favorites = [
          createTestFundFavorite('000001', '华夏成长', '混合型'),
        ];

        favoriteCubit.emit(cubit.FundFavoriteLoaded(
          favorites: favorites,
          searchResults: favorites,
          favoriteStatusCache: const {'000001': true},
        ));

        when(mockService.getSortedFavorites(
          sortType: anyNamed('sortType'),
          direction: anyNamed('direction'),
        )).thenThrow(Exception('排序失败'));

        // Act
        await favoriteCubit.sortFavorites(
          FundFavoriteSortType.fundCode,
          FundFavoriteSortDirection.ascending,
        );

        // Assert
        expect(favoriteCubit.state, isA<cubit.FundFavoriteError>());
        final errorState = favoriteCubit.state as cubit.FundFavoriteError;
        expect(errorState.error, contains('排序失败'));
      });
    });

    group('Update Market Data', () {
      test('should update market data successfully', () async {
        // Arrange
        var favorite = createTestFundFavorite('000001', '华夏成长', '混合型');
        favorite = favorite.copyWith(
          currentNav: 1.0,
          dailyChange: 0.0,
        );

        favoriteCubit.emit(cubit.FundFavoriteLoaded(
          favorites: [favorite],
          searchResults: [favorite],
          favoriteStatusCache: const {'000001': true},
        ));

        when(mockService.updateMarketData(
          '000001',
          currentNav: 1.5,
          dailyChange: 2.5,
          previousNav: 1.2,
        )).thenAnswer((_) async {});

        // Act
        await favoriteCubit.updateMarketData(
          '000001',
          currentNav: 1.5,
          dailyChange: 2.5,
          previousNav: 1.2,
        );

        // Assert
        expect(favoriteCubit.state, isA<cubit.FundFavoriteLoaded>());
        final loadedState = favoriteCubit.state as cubit.FundFavoriteLoaded;
        expect(loadedState.favorites[0].currentNav, 1.5);
        expect(loadedState.favorites[0].dailyChange, 2.5);
        expect(loadedState.favorites[0].previousNav, 1.2);

        verify(mockService.updateMarketData(
          '000001',
          currentNav: 1.5,
          dailyChange: 2.5,
          previousNav: 1.2,
        )).called(1);
      });

      test('should handle market data update error silently', () async {
        // Arrange
        final favorite = createTestFundFavorite('000001', '华夏成长', '混合型');

        favoriteCubit.emit(cubit.FundFavoriteLoaded(
          favorites: [favorite],
          searchResults: [favorite],
          favoriteStatusCache: const {'000001': true},
        ));

        when(mockService.updateMarketData(
          any,
          currentNav: anyNamed('currentNav'),
          dailyChange: anyNamed('dailyChange'),
          previousNav: anyNamed('previousNav'),
        )).thenThrow(Exception('更新失败'));

        // Act
        await favoriteCubit.updateMarketData(
          '000001',
          currentNav: 1.5,
          dailyChange: 2.5,
        );

        // Assert - 状态不应该改变，错误应该被静默处理
        expect(favoriteCubit.state, isA<cubit.FundFavoriteLoaded>());
        expect(favoriteCubit.state, isNot(isA<cubit.FundFavoriteError>()));
      });
    });

    group('Check Is Favorite', () {
      test('should check favorite status successfully', () async {
        // Arrange
        when(mockService.isFavorite('000001')).thenAnswer((_) async => true);

        // Act
        await favoriteCubit.checkIsFavorite('000001');

        // Assert
        expect(favoriteCubit.state, isA<cubit.FundFavoriteDetail>());
        final detailState = favoriteCubit.state as cubit.FundFavoriteDetail;
        expect(detailState.isFavorite, isTrue);

        verify(mockService.isFavorite('000001')).called(1);
      });

      test('should handle check favorite status error', () async {
        // Arrange
        when(mockService.isFavorite('000001')).thenThrow(Exception('检查失败'));

        // Act
        await favoriteCubit.checkIsFavorite('000001');

        // Assert
        expect(favoriteCubit.state, isA<cubit.FundFavoriteError>());
        final errorState = favoriteCubit.state as cubit.FundFavoriteError;
        expect(errorState.error, contains('检查收藏状态失败'));

        verify(mockService.isFavorite('000001')).called(1);
      });
    });

    group('Toggle Favorite', () {
      test('should add favorite when not exists', () async {
        // Arrange
        final favorite = createTestFundFavorite('000001', '华夏成长', '混合型');

        favoriteCubit.emit(const cubit.FundFavoriteLoaded(
          favorites: [],
          searchResults: [],
          favoriteStatusCache: {},
        ));

        when(mockService.addFavorite(any)).thenAnswer((_) async {});

        // Act
        await favoriteCubit.toggleFavorite(favorite);

        // Assert
        verify(mockService.addFavorite(favorite)).called(1);
        verifyNever(mockService.removeFavorite(any));
      });

      test('should remove favorite when exists', () async {
        // Arrange
        final favorite = createTestFundFavorite('000001', '华夏成长', '混合型');

        favoriteCubit.emit(cubit.FundFavoriteLoaded(
          favorites: [favorite],
          searchResults: [favorite],
          favoriteStatusCache: const {'000001': true},
        ));

        when(mockService.removeFavorite('000001')).thenAnswer((_) async {});

        // Act
        await favoriteCubit.toggleFavorite(favorite);

        // Assert
        verify(mockService.removeFavorite('000001')).called(1);
        verifyNever(mockService.addFavorite(any));
      });
    });

    group('Clear All Favorites', () {
      test('should clear all favorites successfully', () async {
        // Arrange
        final favorites = [
          createTestFundFavorite('000001', '华夏成长', '混合型'),
          createTestFundFavorite('110022', '易方达消费', '股票型'),
        ];

        favoriteCubit.emit(cubit.FundFavoriteLoaded(
          favorites: favorites,
          searchResults: favorites,
          favoriteStatusCache: const {'000001': true, '110022': true},
        ));

        when(mockService.clearAllFavorites()).thenAnswer((_) async {});

        // Act
        await favoriteCubit.clearAllFavorites();

        // Assert
        expect(favoriteCubit.state, isA<cubit.FundFavoriteLoaded>());
        final loadedState = favoriteCubit.state as cubit.FundFavoriteLoaded;
        expect(loadedState.favorites, isEmpty);
        expect(loadedState.searchResults, isEmpty);
        expect(loadedState.favoriteStatusCache, isEmpty);
        expect(loadedState.lastMessage, '已清空所有自选基金');

        verify(mockService.clearAllFavorites()).called(1);
      });

      test('should handle clear all favorites error', () async {
        // Arrange
        favoriteCubit.emit(cubit.FundFavoriteLoaded(
          favorites: [createTestFundFavorite('000001', '华夏成长', '混合型')],
          searchResults: [createTestFundFavorite('000001', '华夏成长', '混合型')],
          favoriteStatusCache: const {'000001': true},
        ));

        when(mockService.clearAllFavorites()).thenThrow(Exception('清空失败'));

        // Act
        await favoriteCubit.clearAllFavorites();

        // Assert
        expect(favoriteCubit.state, isA<cubit.FundFavoriteError>());
        final errorState = favoriteCubit.state as cubit.FundFavoriteError;
        expect(errorState.error, contains('清空失败'));

        verify(mockService.clearAllFavorites()).called(1);
      });
    });

    group('Refresh', () {
      test('should refresh data successfully', () async {
        // Arrange
        final favorites = [
          createTestFundFavorite('000001', '华夏成长', '混合型'),
        ];

        when(mockService.getAllFavorites()).thenAnswer((_) async => favorites);
        when(mockService.getAllLists()).thenAnswer((_) async => []);

        // Act
        await favoriteCubit.refresh();

        // Assert
        expect(favoriteCubit.state, isA<cubit.FundFavoriteLoaded>());
        final loadedState = favoriteCubit.state as cubit.FundFavoriteLoaded;
        expect(loadedState.favorites, hasLength(1));

        verify(mockService.getAllFavorites()).called(1);
        verify(mockService.getAllLists()).called(1);
      });
    });

    group('Clear Message', () {
      test('should clear last message', () {
        // Arrange
        favoriteCubit.emit(const cubit.FundFavoriteLoaded(
          favorites: [],
          searchResults: [],
          favoriteStatusCache: {},
          lastMessage: '测试消息',
        ));

        // Act
        favoriteCubit.clearMessage();

        // Assert
        expect(favoriteCubit.state, isA<cubit.FundFavoriteLoaded>());
        final loadedState = favoriteCubit.state as cubit.FundFavoriteLoaded;
        expect(loadedState.lastMessage, isNull);
      });
    });

    group('Fund Favorite Lists', () {
      test('should create favorite list successfully', () async {
        // Arrange
        final newList = FundFavoriteList(
          id: '1',
          name: '测试列表',
          description: '测试描述',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          fundCount: 1,
        );

        favoriteCubit.emit(const cubit.FundFavoriteLoaded(
          favorites: [],
          searchResults: [],
          favoriteStatusCache: {},
        ));

        when(mockService.createList(newList)).thenAnswer((_) async {});
        when(mockService.getAllLists()).thenAnswer((_) async => [newList]);

        // Act
        await favoriteCubit.createFavoriteList(newList);

        // Assert
        expect(favoriteCubit.state, isA<cubit.FundFavoriteLoaded>());
        final loadedState = favoriteCubit.state as cubit.FundFavoriteLoaded;
        expect(loadedState.lastMessage, '已创建列表: 测试列表');

        verify(mockService.createList(newList)).called(1);
        verify(mockService.getAllLists()).called(1);
      });

      test('should update favorite list successfully', () async {
        // Arrange
        final updatedList = FundFavoriteList(
          id: '1',
          name: '更新列表',
          description: '更新描述',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          fundCount: 2,
        );

        favoriteCubit.emit(const cubit.FundFavoriteLoaded(
          favorites: [],
          searchResults: [],
          favoriteStatusCache: {},
        ));

        when(mockService.updateList(updatedList)).thenAnswer((_) async {});
        when(mockService.getAllLists()).thenAnswer((_) async => [updatedList]);

        // Act
        await favoriteCubit.updateFavoriteList(updatedList);

        // Assert
        expect(favoriteCubit.state, isA<cubit.FundFavoriteLoaded>());
        final loadedState = favoriteCubit.state as cubit.FundFavoriteLoaded;
        expect(loadedState.lastMessage, '已更新列表: 更新列表');

        verify(mockService.updateList(updatedList)).called(1);
        verify(mockService.getAllLists()).called(1);
      });

      test('should delete favorite list successfully', () async {
        // Arrange
        favoriteCubit.emit(const cubit.FundFavoriteLoaded(
          favorites: [],
          searchResults: [],
          favoriteStatusCache: {},
        ));

        when(mockService.deleteList('1')).thenAnswer((_) async {});
        when(mockService.getAllLists()).thenAnswer((_) async => []);

        // Act
        await favoriteCubit.deleteFavoriteList('1');

        // Assert
        expect(favoriteCubit.state, isA<cubit.FundFavoriteLoaded>());
        final loadedState = favoriteCubit.state as cubit.FundFavoriteLoaded;
        expect(loadedState.lastMessage, '已删除列表');

        verify(mockService.deleteList('1')).called(1);
        verify(mockService.getAllLists()).called(1);
      });
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
