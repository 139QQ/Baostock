import 'dart:async';
import 'package:hive/hive.dart';
import 'package:jisu_fund_analyzer/src/core/error/exceptions.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/fund_favorite/src/entities/fund_favorite.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/fund_favorite/src/entities/fund_favorite_list.dart';

/// 自选基金本地存储服务
///
/// 提供自选基金和基金列表的本地存储功能：
/// - 自选基金的增删改查操作
/// - 基金列表管理
/// - 排序和筛选功能
/// - 数据持久化和缓存
class FundFavoriteService {
  static const String _favoritesBoxName = 'fund_favorites';
  static const String _listsBoxName = 'fund_favorite_lists';
  static const String _defaultListId = 'default_favorites';

  Box<FundFavorite>? _favoritesBox;
  Box<FundFavoriteList>? _listsBox;
  bool _isInitialized = false;
  static bool _isInitializing = false; // 防止并发初始化

  /// 初始化服务 - 添加并发控制
  Future<void> initialize() async {
    // 防止并发初始化
    if (_isInitialized) {
      print('✅ FundFavoriteService 已初始化，跳过');
      return;
    }

    if (_isInitializing) {
      print('⏳ FundFavoriteService 正在初始化中，等待完成...');
      // 等待初始化完成，最多等待10秒
      int waitCount = 0;
      while (_isInitializing && waitCount < 100) {
        await Future.delayed(Duration(milliseconds: 100));
        waitCount++;
      }

      if (_isInitialized) {
        print('✅ FundFavoriteService 初始化完成');
        return;
      } else {
        print('❌ FundFavoriteService 初始化超时');
        return;
      }
    }

    try {
      _isInitializing = true;
      print('🔄 开始初始化 FundFavoriteService');
      // 适配器已在injection_container中注册，这里不需要重复注册
      // 直接初始化Hive boxes

      // 尝试打开存储盒，如果失败则清除缓存重试
      try {
        print('📁 尝试打开Hive存储盒');
        _favoritesBox = await Hive.openBox<FundFavorite>(_favoritesBoxName)
            .timeout(Duration(seconds: 10));
        _listsBox = await Hive.openBox<FundFavoriteList>(_listsBoxName)
            .timeout(Duration(seconds: 10));
        print('✅ Hive存储盒打开成功');
      } on TimeoutException {
        print('❌ Hive存储盒打开超时');
        throw CacheException('Hive存储盒打开超时，请检查磁盘空间');
      } catch (e) {
        // 如果打开失败，可能是缓存损坏，清除后重试
        print('⚠️ 缓存可能损坏，正在清除并重新初始化: $e');

        try {
          await Hive.deleteBoxFromDisk(_favoritesBoxName);
          await Hive.deleteBoxFromDisk(_listsBoxName);
          print('🗑️ 缓存文件删除完成');
        } catch (deleteError) {
          print('⚠️ 删除缓存文件失败: $deleteError');
        }

        // 重新打开存储盒
        print('🔄 重新打开存储盒');
        try {
          _favoritesBox = await Hive.openBox<FundFavorite>(_favoritesBoxName)
              .timeout(Duration(seconds: 10));
          _listsBox = await Hive.openBox<FundFavoriteList>(_listsBoxName)
              .timeout(Duration(seconds: 10));
          print('✅ 存储盒重新打开成功');
        } on TimeoutException {
          print('❌ 存储盒重新打开超时');
          throw CacheException('存储盒重新打开超时');
        } catch (retryError) {
          print('❌ 存储盒重新打开失败: $retryError');
          throw CacheException('存储盒重新打开失败: $retryError');
        }
      }

      // 创建默认列表（如果不存在）
      await _createDefaultListIfNeeded();
      print('✅ 默认列表创建完成');

      _isInitialized = true;
      _isInitializing = false;
      print('✅ FundFavoriteService 初始化成功');
    } catch (e) {
      _isInitializing = false;
      print('❌ FundFavoriteService 初始化失败: $e');
      throw CacheException('Failed to initialize FundFavoriteService: $e');
    }
  }

  /// 重置缓存（用于修复损坏的数据）
  Future<void> resetCache() async {
    try {
      print('🔄 开始重置自选基金缓存');

      // 关闭当前存储盒
      await _favoritesBox?.close();
      await _listsBox?.close();

      // 删除缓存文件
      await Hive.deleteBoxFromDisk(_favoritesBoxName);
      await Hive.deleteBoxFromDisk(_listsBoxName);

      // 重新初始化
      _isInitialized = false;
      await initialize();

      print('✅ 自选基金缓存重置成功');
    } catch (e) {
      print('❌ 重置缓存失败: $e');
      throw CacheException('Failed to reset cache: $e');
    }
  }

  /// 创建默认自选列表
  Future<void> _createDefaultListIfNeeded() async {
    if (_listsBox == null) throw CacheException('Service not initialized');

    if (!_listsBox!.containsKey(_defaultListId)) {
      final now = DateTime.now();
      final defaultList = FundFavoriteList(
        id: _defaultListId,
        name: '我的自选',
        description: '默认自选基金列表',
        createdAt: now,
        updatedAt: now,
        isDefault: true,
        isEnabled: true,
      );

      await _listsBox!.put(_defaultListId, defaultList);
    }
  }

  /// 确保已初始化
  void _ensureInitialized() {
    if (!_isInitialized) {
      print('❌ FundFavoriteService 未初始化');
      throw CacheException('FundFavoriteService not initialized');
    }
    if (_favoritesBox == null) {
      print('❌ _favoritesBox 为空');
      throw CacheException('_favoritesBox is null');
    }
    if (_listsBox == null) {
      print('❌ _listsBox 为空');
      throw CacheException('_listsBox is null');
    }
    if (!Hive.isBoxOpen(_favoritesBoxName)) {
      print('❌ $_favoritesBoxName 盒子未打开');
      throw CacheException('$_favoritesBoxName box is not open');
    }
    if (!Hive.isBoxOpen(_listsBoxName)) {
      print('❌ $_listsBoxName 盒子未打开');
      throw CacheException('$_listsBoxName box is not open');
    }
    print('✅ FundFavoriteService 初始化检查通过');
  }

  // ==================== 自选基金操作 ====================

  /// 获取所有自选基金
  Future<List<FundFavorite>> getAllFavorites() async {
    _ensureInitialized();

    try {
      final favorites = _favoritesBox!.values.toList();
      return favorites;
    } catch (e) {
      throw CacheException('Failed to get all favorites: $e');
    }
  }

  /// 根据基金代码获取自选基金
  Future<FundFavorite?> getFavoriteByCode(String fundCode) async {
    _ensureInitialized();

    try {
      // 使用基金代码作为key查找
      return _favoritesBox!.get(fundCode);
    } catch (e) {
      throw CacheException('Failed to get favorite by code: $e');
    }
  }

  /// 添加自选基金
  Future<void> addFavorite(FundFavorite favorite) async {
    try {
      _ensureInitialized();
      print('🔄 正在添加自选基金: ${favorite.fundCode} - ${favorite.fundName}');

      // 检查是否已存在
      if (_favoritesBox!.containsKey(favorite.fundCode)) {
        print('⚠️ 基金 ${favorite.fundCode} 已存在于自选中');
        throw CacheException('基金已在自选中');
      }

      // 添加到存储
      await _favoritesBox!.put(favorite.fundCode, favorite);
      print('✅ 成功添加基金到Hive存储: ${favorite.fundCode}');

      // 更新默认列表的基金数量
      await _updateListFundCount(_defaultListId);
      print('✅ 更新列表基金数量完成');

      // 验证添加是否成功
      final added = _favoritesBox!.get(favorite.fundCode);
      if (added != null) {
        print('✅ 验证成功：基金已添加到存储');
      } else {
        throw CacheException('添加验证失败：基金未找到');
      }
    } catch (e) {
      print('❌ 添加自选基金失败: $e');
      print('❌ 错误详情: ${e.runtimeType}');
      if (e is HiveError) {
        print('❌ Hive错误: ${e.message}');
      }
      throw CacheException('添加自选基金失败: $e');
    }
  }

  /// 更新自选基金
  Future<void> updateFavorite(FundFavorite favorite) async {
    _ensureInitialized();

    try {
      await _favoritesBox!.put(favorite.fundCode, favorite);
    } catch (e) {
      throw CacheException('Failed to update favorite: $e');
    }
  }

  /// 删除自选基金
  Future<void> removeFavorite(String fundCode) async {
    _ensureInitialized();

    try {
      await _favoritesBox!.delete(fundCode);

      // 更新默认列表的基金数量
      await _updateListFundCount(_defaultListId);
    } catch (e) {
      throw CacheException('Failed to remove favorite: $e');
    }
  }

  /// 批量删除自选基金
  Future<void> removeFavorites(List<String> fundCodes) async {
    _ensureInitialized();

    try {
      for (final code in fundCodes) {
        await _favoritesBox!.delete(code);
      }

      // 更新默认列表的基金数量
      await _updateListFundCount(_defaultListId);
    } catch (e) {
      throw CacheException('Failed to remove favorites: $e');
    }
  }

  /// 检查基金是否已收藏
  Future<bool> isFavorite(String fundCode) async {
    _ensureInitialized();

    try {
      return _favoritesBox!.containsKey(fundCode);
    } catch (e) {
      throw CacheException('Failed to check if favorite exists: $e');
    }
  }

  /// 获取自选基金数量
  Future<int> getFavoriteCount() async {
    _ensureInitialized();

    try {
      return _favoritesBox!.length;
    } catch (e) {
      throw CacheException('Failed to get favorite count: $e');
    }
  }

  /// 搜索自选基金
  Future<List<FundFavorite>> searchFavorites(String query) async {
    _ensureInitialized();

    try {
      final allFavorites = _favoritesBox!.values.toList();
      final lowerQuery = query.toLowerCase();

      return allFavorites.where((favorite) {
        return favorite.fundCode.toLowerCase().contains(lowerQuery) ||
            favorite.fundName.toLowerCase().contains(lowerQuery) ||
            favorite.fundType.toLowerCase().contains(lowerQuery) ||
            (favorite.notes?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    } catch (e) {
      throw CacheException('Failed to search favorites: $e');
    }
  }

  /// 获取排序后的自选基金
  Future<List<FundFavorite>> getSortedFavorites({
    FundFavoriteSortType sortType = FundFavoriteSortType.addTime,
    FundFavoriteSortDirection direction = FundFavoriteSortDirection.descending,
  }) async {
    _ensureInitialized();

    try {
      final favorites = _favoritesBox!.values.toList();

      switch (sortType) {
        case FundFavoriteSortType.addTime:
          favorites.sort((a, b) => a.addedAt.compareTo(b.addedAt));
          break;
        case FundFavoriteSortType.fundCode:
          favorites.sort((a, b) => a.fundCode.compareTo(b.fundCode));
          break;
        case FundFavoriteSortType.fundName:
          favorites.sort((a, b) => a.fundName.compareTo(b.fundName));
          break;
        case FundFavoriteSortType.currentNav:
          favorites.sort((a, b) {
            if (a.currentNav == null && b.currentNav == null) return 0;
            if (a.currentNav == null) return 1;
            if (b.currentNav == null) return -1;
            return a.currentNav!.compareTo(b.currentNav!);
          });
          break;
        case FundFavoriteSortType.dailyChange:
          favorites.sort((a, b) {
            if (a.dailyChange == null && b.dailyChange == null) return 0;
            if (a.dailyChange == null) return 1;
            if (b.dailyChange == null) return -1;
            return a.dailyChange!.compareTo(b.dailyChange!);
          });
          break;
        case FundFavoriteSortType.fundScale:
          favorites.sort((a, b) {
            if (a.fundScale == null && b.fundScale == null) return 0;
            if (a.fundScale == null) return 1;
            if (b.fundScale == null) return -1;
            return a.fundScale!.compareTo(b.fundScale!);
          });
          break;
        case FundFavoriteSortType.custom:
          favorites.sort((a, b) => a.sortWeight.compareTo(b.sortWeight));
          break;
      }

      // 根据方向决定是否反转列表
      if (direction == FundFavoriteSortDirection.ascending) {
        return favorites;
      } else {
        return favorites.reversed.toList();
      }
    } catch (e) {
      throw CacheException('Failed to get sorted favorites: $e');
    }
  }

  /// 更新自选基金的实时行情数据
  Future<void> updateMarketData(
    String fundCode, {
    double? currentNav,
    double? dailyChange,
    double? previousNav,
  }) async {
    _ensureInitialized();

    try {
      final favorite = await getFavoriteByCode(fundCode);
      if (favorite != null) {
        final updatedFavorite = favorite.updateMarketData(
          currentNav: currentNav,
          dailyChange: dailyChange,
          previousNav: previousNav,
        );
        await updateFavorite(updatedFavorite);
      }
    } catch (e) {
      throw CacheException('Failed to update market data: $e');
    }
  }

  /// 更新自选基金的排序权重
  Future<void> updateSortWeight(String fundCode, double weight) async {
    _ensureInitialized();

    try {
      final favorite = await getFavoriteByCode(fundCode);
      if (favorite != null) {
        final updatedFavorite = favorite.updateSortWeight(weight);
        await updateFavorite(updatedFavorite);
      }
    } catch (e) {
      throw CacheException('Failed to update sort weight: $e');
    }
  }

  /// 清空所有自选基金
  Future<void> clearAllFavorites() async {
    _ensureInitialized();

    try {
      await _favoritesBox!.clear();
      await _updateListFundCount(_defaultListId);
    } catch (e) {
      throw CacheException('Failed to clear all favorites: $e');
    }
  }

  // ==================== 基金列表操作 ====================

  /// 获取所有基金列表
  Future<List<FundFavoriteList>> getAllLists() async {
    _ensureInitialized();

    try {
      return _listsBox!.values.toList();
    } catch (e) {
      throw CacheException('Failed to get all lists: $e');
    }
  }

  /// 根据ID获取基金列表
  Future<FundFavoriteList?> getListById(String listId) async {
    _ensureInitialized();

    try {
      return _listsBox!.get(listId);
    } catch (e) {
      throw CacheException('Failed to get list by ID: $e');
    }
  }

  /// 创建基金列表
  Future<void> createList(FundFavoriteList list) async {
    _ensureInitialized();

    try {
      await _listsBox!.put(list.id, list);
    } catch (e) {
      throw CacheException('Failed to create list: $e');
    }
  }

  /// 更新基金列表
  Future<void> updateList(FundFavoriteList list) async {
    _ensureInitialized();

    try {
      await _listsBox!.put(list.id, list);
    } catch (e) {
      throw CacheException('Failed to update list: $e');
    }
  }

  /// 删除基金列表
  Future<void> deleteList(String listId) async {
    _ensureInitialized();

    try {
      // 不能删除默认列表
      if (listId == _defaultListId) {
        throw CacheException('Cannot delete default list');
      }

      await _listsBox!.delete(listId);
    } catch (e) {
      throw CacheException('Failed to delete list: $e');
    }
  }

  /// 获取默认列表
  Future<FundFavoriteList> getDefaultList() async {
    _ensureInitialized();

    try {
      final defaultList = await getListById(_defaultListId);
      if (defaultList == null) {
        throw CacheException('Default list not found');
      }
      return defaultList;
    } catch (e) {
      throw CacheException('Failed to get default list: $e');
    }
  }

  /// 更新列表的基金数量
  Future<void> _updateListFundCount(String listId) async {
    try {
      final list = await getListById(listId);
      if (list != null) {
        final count = await getFavoriteCount();
        final updatedList = list.updateFundCount(count);
        await updateList(updatedList);
      }
    } catch (e) {
      // 静默处理错误，避免影响主要操作
      print('Warning: Failed to update list fund count: $e');
    }
  }

  // ==================== 数据维护操作 ====================

  /// 清理过期数据
  Future<void> cleanupExpiredData() async {
    _ensureInitialized();

    try {
      // 可以在这里实现数据清理逻辑
      // 例如：删除超过一定时间未更新的数据
      final now = DateTime.now();
      final cutoffDate = now.subtract(const Duration(days: 90));

      final favorites = _favoritesBox!.values.toList();
      for (final favorite in favorites) {
        if (favorite.updatedAt.isBefore(cutoffDate)) {
          // 可以选择删除或标记为过期
          // await _favoritesBox!.delete(favorite.fundCode);
        }
      }
    } catch (e) {
      throw CacheException('Failed to cleanup expired data: $e');
    }
  }

  /// 获取存储统计信息
  Future<Map<String, dynamic>> getStorageStats() async {
    _ensureInitialized();

    try {
      return {
        'favoriteCount': _favoritesBox!.length,
        'listCount': _listsBox!.length,
        'favoriteBoxSize': _favoritesBox!.length,
        'listBoxSize': _listsBox!.length,
        'isInitialized': _isInitialized,
      };
    } catch (e) {
      throw CacheException('Failed to get storage stats: $e');
    }
  }

  /// 关闭服务
  Future<void> dispose() async {
    try {
      await _favoritesBox?.close();
      await _listsBox?.close();
      _favoritesBox = null;
      _listsBox = null;
      _isInitialized = false;
    } catch (e) {
      throw CacheException('Failed to dispose FundFavoriteService: $e');
    }
  }
}
