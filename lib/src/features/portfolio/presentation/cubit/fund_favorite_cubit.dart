import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/fund_favorite/src/entities/fund_favorite.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/fund_favorite/src/entities/fund_favorite_list.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/data/services/fund_favorite_service.dart';

/// 自选基金管理事件
abstract class FundFavoriteEvent extends Equatable {
  const FundFavoriteEvent();

  @override
  List<Object?> get props => [];
}

/// 初始化事件
class InitializeFavorites extends FundFavoriteEvent {}

/// 加载所有自选基金
class LoadAllFavorites extends FundFavoriteEvent {}

/// 根据基金代码获取自选基金
class GetFavoriteByCode extends FundFavoriteEvent {
  final String fundCode;

  const GetFavoriteByCode(this.fundCode);

  @override
  List<Object?> get props => [fundCode];
}

/// 添加自选基金
class AddFavorite extends FundFavoriteEvent {
  final FundFavorite favorite;

  const AddFavorite(this.favorite);

  @override
  List<Object?> get props => [favorite];
}

/// 更新自选基金
class UpdateFavorite extends FundFavoriteEvent {
  final FundFavorite favorite;

  const UpdateFavorite(this.favorite);

  @override
  List<Object?> get props => [favorite];
}

/// 删除自选基金
class RemoveFavorite extends FundFavoriteEvent {
  final String fundCode;

  const RemoveFavorite(this.fundCode);

  @override
  List<Object?> get props => [fundCode];
}

/// 批量删除自选基金
class RemoveMultipleFavorites extends FundFavoriteEvent {
  final List<String> fundCodes;

  const RemoveMultipleFavorites(this.fundCodes);

  @override
  List<Object?> get props => [fundCodes];
}

/// 搜索自选基金
class SearchFavorites extends FundFavoriteEvent {
  final String query;

  const SearchFavorites(this.query);

  @override
  List<Object?> get props => [query];
}

/// 排序自选基金
class SortFavorites extends FundFavoriteEvent {
  final FundFavoriteSortType sortType;
  final FundFavoriteSortDirection direction;

  const SortFavorites(this.sortType, this.direction);

  @override
  List<Object?> get props => [sortType, direction];
}

/// 更新基金行情数据
class UpdateMarketData extends FundFavoriteEvent {
  final String fundCode;
  final double? currentNav;
  final double? dailyChange;
  final double? previousNav;

  const UpdateMarketData(
    this.fundCode, {
    this.currentNav,
    this.dailyChange,
    this.previousNav,
  });

  @override
  List<Object?> get props => [fundCode, currentNav, dailyChange, previousNav];
}

/// 检查是否已收藏
class CheckIsFavorite extends FundFavoriteEvent {
  final String fundCode;

  const CheckIsFavorite(this.fundCode);

  @override
  List<Object?> get props => [fundCode];
}

/// 清空所有自选基金
class ClearAllFavorites extends FundFavoriteEvent {}

/// 获取基金列表
class LoadFavoriteLists extends FundFavoriteEvent {}

/// 创建基金列表
class CreateFavoriteList extends FundFavoriteEvent {
  final FundFavoriteList list;

  const CreateFavoriteList(this.list);

  @override
  List<Object?> get props => [list];
}

/// 更新基金列表
class UpdateFavoriteList extends FundFavoriteEvent {
  final FundFavoriteList list;

  const UpdateFavoriteList(this.list);

  @override
  List<Object?> get props => [list];
}

/// 删除基金列表
class DeleteFavoriteList extends FundFavoriteEvent {
  final String listId;

  const DeleteFavoriteList(this.listId);

  @override
  List<Object?> get props => [listId];
}

/// 切换收藏状态
class ToggleFavorite extends FundFavoriteEvent {
  final FundFavorite favorite;

  const ToggleFavorite(this.favorite);

  @override
  List<Object?> get props => [favorite];
}

/// 自选基金管理状态
abstract class FundFavoriteState extends Equatable {
  const FundFavoriteState();

  @override
  List<Object?> get props => [];
}

/// 初始状态
class FundFavoriteInitial extends FundFavoriteState {}

/// 加载中状态
class FundFavoriteLoading extends FundFavoriteState {}

/// 数据加载完成状态
class FundFavoriteLoaded extends FundFavoriteState {
  /// 所有自选基金
  final List<FundFavorite> favorites;

  /// 搜索结果
  final List<FundFavorite> searchResults;

  /// 当前搜索查询
  final String searchQuery;

  /// 当前排序类型
  final FundFavoriteSortType currentSortType;

  /// 当前排序方向
  final FundFavoriteSortDirection currentSortDirection;

  /// 是否已收藏的基金缓存
  final Map<String, bool> favoriteStatusCache;

  /// 基金列表
  final List<FundFavoriteList> favoriteLists;

  /// 当前操作的基金代码
  final String? operatingFundCode;

  /// 最后操作结果消息
  final String? lastMessage;

  const FundFavoriteLoaded({
    this.favorites = const [],
    this.searchResults = const [],
    this.searchQuery = '',
    this.currentSortType = FundFavoriteSortType.addTime,
    this.currentSortDirection = FundFavoriteSortDirection.descending,
    this.favoriteStatusCache = const {},
    this.favoriteLists = const [],
    this.operatingFundCode,
    this.lastMessage,
  });

  /// 获取显示的基金列表（根据搜索状态）
  List<FundFavorite> get displayFavorites {
    return searchQuery.isEmpty ? favorites : searchResults;
  }

  /// 获取基金数量
  int get favoriteCount => favorites.length;

  /// 检查是否已收藏
  bool isFavorite(String fundCode) {
    return favoriteStatusCache[fundCode] ?? false;
  }

  /// 根据基金代码获取基金
  FundFavorite? getFavoriteByCode(String fundCode) {
    try {
      return favorites.firstWhere((f) => f.fundCode == fundCode);
    } catch (e) {
      return null;
    }
  }

  FundFavoriteLoaded copyWith({
    List<FundFavorite>? favorites,
    List<FundFavorite>? searchResults,
    String? searchQuery,
    FundFavoriteSortType? currentSortType,
    FundFavoriteSortDirection? currentSortDirection,
    Map<String, bool>? favoriteStatusCache,
    List<FundFavoriteList>? favoriteLists,
    String? operatingFundCode,
    String? lastMessage,
  }) {
    return FundFavoriteLoaded(
      favorites: favorites ?? this.favorites,
      searchResults: searchResults ?? this.searchResults,
      searchQuery: searchQuery ?? this.searchQuery,
      currentSortType: currentSortType ?? this.currentSortType,
      currentSortDirection: currentSortDirection ?? this.currentSortDirection,
      favoriteStatusCache: favoriteStatusCache ?? this.favoriteStatusCache,
      favoriteLists: favoriteLists ?? this.favoriteLists,
      operatingFundCode: operatingFundCode,
      lastMessage: lastMessage,
    );
  }

  @override
  List<Object?> get props => [
        favorites,
        searchResults,
        searchQuery,
        currentSortType,
        currentSortDirection,
        favoriteStatusCache,
        favoriteLists,
        operatingFundCode,
        lastMessage,
      ];
}

/// 错误状态
class FundFavoriteError extends FundFavoriteState {
  final String error;

  const FundFavoriteError(this.error);

  @override
  List<Object?> get props => [error];
}

/// 操作成功状态
class FundFavoriteOperationSuccess extends FundFavoriteState {
  final String message;
  final FundFavoriteLoaded previousState;

  const FundFavoriteOperationSuccess(this.message, this.previousState);

  @override
  List<Object?> get props => [message, previousState];
}

/// 单个基金信息状态
class FundFavoriteDetail extends FundFavoriteState {
  final FundFavorite? favorite;
  final bool isFavorite;

  const FundFavoriteDetail(this.favorite, this.isFavorite);

  @override
  List<Object?> get props => [favorite, isFavorite];
}

/// 自选基金管理Cubit
class FundFavoriteCubit extends Cubit<FundFavoriteState> {
  final FundFavoriteService _service;

  FundFavoriteCubit(this._service) : super(FundFavoriteInitial());

  /// 初始化
  Future<void> initialize() async {
    emit(FundFavoriteLoading());
    try {
      await _service.initialize();
      await loadAllFavorites();
      await loadFavoriteLists();
    } catch (e) {
      emit(FundFavoriteError('初始化失败: $e'));
    }
  }

  /// 加载所有自选基金
  Future<void> loadAllFavorites() async {
    try {
      final favorites = await _service.getAllFavorites();

      if (state is FundFavoriteLoaded) {
        final currentState = state as FundFavoriteLoaded;
        final updatedCache =
            Map<String, bool>.from(currentState.favoriteStatusCache);

        // 更新收藏状态缓存
        for (final favorite in favorites) {
          updatedCache[favorite.fundCode] = true;
        }

        emit(currentState.copyWith(
          favorites: favorites,
          searchResults: favorites,
          favoriteStatusCache: updatedCache,
          lastMessage: '已加载${favorites.length}只自选基金',
        ));
      } else {
        emit(FundFavoriteLoaded(
          favorites: favorites,
          searchResults: favorites,
          favoriteStatusCache: {for (var f in favorites) f.fundCode: true},
          lastMessage: '已加载${favorites.length}只自选基金',
        ));
      }
    } catch (e) {
      emit(FundFavoriteError('加载自选基金失败: $e'));
    }
  }

  /// 根据基金代码获取自选基金
  Future<void> getFavoriteByCode(String fundCode) async {
    if (state is FundFavoriteLoaded) {
      final currentState = state as FundFavoriteLoaded;
      final favorite = currentState.getFavoriteByCode(fundCode);
      emit(FundFavoriteDetail(favorite, favorite != null));
    } else {
      try {
        final favorite = await _service.getFavoriteByCode(fundCode);
        emit(FundFavoriteDetail(favorite, favorite != null));
      } catch (e) {
        emit(FundFavoriteError('获取自选基金失败: $e'));
      }
    }
  }

  /// 添加自选基金
  Future<void> addFavorite(FundFavorite favorite) async {
    try {
      if (state is! FundFavoriteLoaded) {
        emit(FundFavoriteError('请先初始化'));
        return;
      }

      final currentState = state as FundFavoriteLoaded;

      // 检查是否已存在
      if (currentState.isFavorite(favorite.fundCode)) {
        emit(FundFavoriteOperationSuccess(
          '基金${favorite.fundName}已在自选中',
          currentState.copyWith(lastMessage: '基金已存在'),
        ));
        return;
      }

      await _service.addFavorite(favorite);

      final updatedFavorites = [...currentState.favorites, favorite];
      final updatedCache =
          Map<String, bool>.from(currentState.favoriteStatusCache);
      updatedCache[favorite.fundCode] = true;

      emit(currentState.copyWith(
        favorites: updatedFavorites,
        searchResults: currentState.searchQuery.isEmpty
            ? updatedFavorites
            : _searchInList(currentState.searchQuery, updatedFavorites),
        favoriteStatusCache: updatedCache,
        lastMessage: '已添加${favorite.fundName}到自选',
      ));
    } catch (e) {
      emit(FundFavoriteError('添加自选基金失败: $e'));
    }
  }

  /// 更新自选基金
  Future<void> updateFavorite(FundFavorite favorite) async {
    try {
      if (state is! FundFavoriteLoaded) {
        emit(FundFavoriteError('请先初始化'));
        return;
      }

      final currentState = state as FundFavoriteLoaded;
      await _service.updateFavorite(favorite);

      final updatedFavorites = currentState.favorites.map((f) {
        return f.fundCode == favorite.fundCode ? favorite : f;
      }).toList();

      emit(currentState.copyWith(
        favorites: updatedFavorites,
        searchResults: currentState.searchQuery.isEmpty
            ? updatedFavorites
            : _searchInList(currentState.searchQuery, updatedFavorites),
        lastMessage: '已更新${favorite.fundName}',
      ));
    } catch (e) {
      emit(FundFavoriteError('更新自选基金失败: $e'));
    }
  }

  /// 删除自选基金
  Future<void> removeFavorite(String fundCode) async {
    try {
      if (state is! FundFavoriteLoaded) {
        emit(FundFavoriteError('请先初始化'));
        return;
      }

      final currentState = state as FundFavoriteLoaded;
      await _service.removeFavorite(fundCode);

      final favorite = currentState.getFavoriteByCode(fundCode);
      final updatedFavorites =
          currentState.favorites.where((f) => f.fundCode != fundCode).toList();

      final updatedCache =
          Map<String, bool>.from(currentState.favoriteStatusCache);
      updatedCache[fundCode] = false;

      emit(currentState.copyWith(
        favorites: updatedFavorites,
        searchResults: currentState.searchQuery.isEmpty
            ? updatedFavorites
            : _searchInList(currentState.searchQuery, updatedFavorites),
        favoriteStatusCache: updatedCache,
        lastMessage: '已移除${favorite?.fundName ?? fundCode}',
      ));
    } catch (e) {
      emit(FundFavoriteError('删除自选基金失败: $e'));
    }
  }

  /// 批量删除自选基金
  Future<void> removeMultipleFavorites(List<String> fundCodes) async {
    try {
      if (state is! FundFavoriteLoaded) {
        emit(FundFavoriteError('请先初始化'));
        return;
      }

      final currentState = state as FundFavoriteLoaded;
      await _service.removeFavorites(fundCodes);

      final updatedFavorites = currentState.favorites
          .where((f) => !fundCodes.contains(f.fundCode))
          .toList();

      final updatedCache =
          Map<String, bool>.from(currentState.favoriteStatusCache);
      for (final code in fundCodes) {
        updatedCache[code] = false;
      }

      emit(currentState.copyWith(
        favorites: updatedFavorites,
        searchResults: currentState.searchQuery.isEmpty
            ? updatedFavorites
            : _searchInList(currentState.searchQuery, updatedFavorites),
        favoriteStatusCache: updatedCache,
        lastMessage: '已移除${fundCodes.length}只基金',
      ));
    } catch (e) {
      emit(FundFavoriteError('批量删除失败: $e'));
    }
  }

  /// 搜索自选基金
  Future<void> searchFavorites(String query) async {
    if (state is! FundFavoriteLoaded) {
      emit(FundFavoriteError('请先初始化'));
      return;
    }

    final currentState = state as FundFavoriteLoaded;
    final searchResults = query.isEmpty
        ? currentState.favorites
        : _searchInList(query, currentState.favorites);

    emit(currentState.copyWith(
      searchQuery: query,
      searchResults: searchResults,
      lastMessage: query.isEmpty
          ? '显示全部${currentState.favorites.length}只基金'
          : '找到${searchResults.length}只相关基金',
    ));
  }

  /// 排序自选基金
  Future<void> sortFavorites(
    FundFavoriteSortType sortType,
    FundFavoriteSortDirection direction,
  ) async {
    if (state is! FundFavoriteLoaded) {
      emit(FundFavoriteError('请先初始化'));
      return;
    }

    try {
      final sortedFavorites = await _service.getSortedFavorites(
        sortType: sortType,
        direction: direction,
      );

      final currentState = state as FundFavoriteLoaded;
      emit(currentState.copyWith(
        favorites: sortedFavorites,
        searchResults: currentState.searchQuery.isEmpty
            ? sortedFavorites
            : _searchInList(currentState.searchQuery, sortedFavorites),
        currentSortType: sortType,
        currentSortDirection: direction,
        lastMessage:
            '已按${_getSortTypeName(sortType)}${direction == FundFavoriteSortDirection.ascending ? '升序' : '降序'}排序',
      ));
    } catch (e) {
      emit(FundFavoriteError('排序失败: $e'));
    }
  }

  /// 更新行情数据
  Future<void> updateMarketData(
    String fundCode, {
    double? currentNav,
    double? dailyChange,
    double? previousNav,
  }) async {
    if (state is! FundFavoriteLoaded) return;

    try {
      await _service.updateMarketData(
        fundCode,
        currentNav: currentNav,
        dailyChange: dailyChange,
        previousNav: previousNav,
      );

      final currentState = state as FundFavoriteLoaded;
      final favorite = currentState.getFavoriteByCode(fundCode);
      if (favorite != null) {
        final updatedFavorite = favorite.updateMarketData(
          currentNav: currentNav,
          dailyChange: dailyChange,
          previousNav: previousNav,
        );

        final updatedFavorites = currentState.favorites.map((f) {
          return f.fundCode == fundCode ? updatedFavorite : f;
        }).toList();

        emit(currentState.copyWith(
          favorites: updatedFavorites,
          searchResults: currentState.searchQuery.isEmpty
              ? updatedFavorites
              : _searchInList(currentState.searchQuery, updatedFavorites),
        ));
      }
    } catch (e) {
      // 静默处理错误，避免影响用户体验
      print('Failed to update market data: $e');
    }
  }

  /// 检查是否已收藏
  Future<void> checkIsFavorite(String fundCode) async {
    try {
      final isFavorite = await _service.isFavorite(fundCode);

      if (state is FundFavoriteLoaded) {
        final currentState = state as FundFavoriteLoaded;
        final updatedCache =
            Map<String, bool>.from(currentState.favoriteStatusCache);
        updatedCache[fundCode] = isFavorite;

        emit(currentState.copyWith(
          favoriteStatusCache: updatedCache,
        ));
      } else {
        emit(FundFavoriteDetail(null, isFavorite));
      }
    } catch (e) {
      emit(FundFavoriteError('检查收藏状态失败: $e'));
    }
  }

  /// 切换收藏状态
  Future<void> toggleFavorite(FundFavorite favorite) async {
    if (state is! FundFavoriteLoaded) {
      emit(FundFavoriteError('请先初始化'));
      return;
    }

    final currentState = state as FundFavoriteLoaded;
    if (currentState.isFavorite(favorite.fundCode)) {
      await removeFavorite(favorite.fundCode);
    } else {
      await addFavorite(favorite);
    }
  }

  /// 清空所有自选基金
  Future<void> clearAllFavorites() async {
    try {
      if (state is! FundFavoriteLoaded) {
        emit(FundFavoriteError('请先初始化'));
        return;
      }

      await _service.clearAllFavorites();

      final currentState = state as FundFavoriteLoaded;
      emit(currentState.copyWith(
        favorites: [],
        searchResults: [],
        favoriteStatusCache: {},
        lastMessage: '已清空所有自选基金',
      ));
    } catch (e) {
      emit(FundFavoriteError('清空失败: $e'));
    }
  }

  /// 加载基金列表
  Future<void> loadFavoriteLists() async {
    try {
      final lists = await _service.getAllLists();

      if (state is FundFavoriteLoaded) {
        final currentState = state as FundFavoriteLoaded;
        emit(currentState.copyWith(
          favoriteLists: lists,
        ));
      }
    } catch (e) {
      emit(FundFavoriteError('加载基金列表失败: $e'));
    }
  }

  /// 创建基金列表
  Future<void> createFavoriteList(FundFavoriteList list) async {
    try {
      await _service.createList(list);
      await loadFavoriteLists();

      if (state is FundFavoriteLoaded) {
        final currentState = state as FundFavoriteLoaded;
        emit(currentState.copyWith(
          lastMessage: '已创建列表: ${list.name}',
        ));
      }
    } catch (e) {
      emit(FundFavoriteError('创建列表失败: $e'));
    }
  }

  /// 更新基金列表
  Future<void> updateFavoriteList(FundFavoriteList list) async {
    try {
      await _service.updateList(list);
      await loadFavoriteLists();

      if (state is FundFavoriteLoaded) {
        final currentState = state as FundFavoriteLoaded;
        emit(currentState.copyWith(
          lastMessage: '已更新列表: ${list.name}',
        ));
      }
    } catch (e) {
      emit(FundFavoriteError('更新列表失败: $e'));
    }
  }

  /// 删除基金列表
  Future<void> deleteFavoriteList(String listId) async {
    try {
      await _service.deleteList(listId);
      await loadFavoriteLists();

      if (state is FundFavoriteLoaded) {
        final currentState = state as FundFavoriteLoaded;
        emit(currentState.copyWith(
          lastMessage: '已删除列表',
        ));
      }
    } catch (e) {
      emit(FundFavoriteError('删除列表失败: $e'));
    }
  }

  /// 刷新数据
  Future<void> refresh() async {
    emit(FundFavoriteLoading());
    await loadAllFavorites();
    await loadFavoriteLists();
  }

  /// 清除消息
  void clearMessage() {
    if (state is FundFavoriteLoaded) {
      final currentState = state as FundFavoriteLoaded;
      emit(currentState.copyWith(lastMessage: null));
    }
  }

  /// 在列表中搜索
  List<FundFavorite> _searchInList(String query, List<FundFavorite> favorites) {
    final lowerQuery = query.toLowerCase();
    return favorites.where((favorite) {
      return favorite.fundCode.toLowerCase().contains(lowerQuery) ||
          favorite.fundName.toLowerCase().contains(lowerQuery) ||
          favorite.fundType.toLowerCase().contains(lowerQuery) ||
          (favorite.notes?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  /// 获取排序类型名称
  String _getSortTypeName(FundFavoriteSortType sortType) {
    switch (sortType) {
      case FundFavoriteSortType.addTime:
        return '添加时间';
      case FundFavoriteSortType.fundCode:
        return '基金代码';
      case FundFavoriteSortType.fundName:
        return '基金名称';
      case FundFavoriteSortType.currentNav:
        return '当前净值';
      case FundFavoriteSortType.dailyChange:
        return '日涨跌幅';
      case FundFavoriteSortType.fundScale:
        return '基金规模';
      case FundFavoriteSortType.custom:
        return '自定义排序';
    }
  }

  @override
  Future<void> close() {
    // 清理资源
    return super.close();
  }
}
