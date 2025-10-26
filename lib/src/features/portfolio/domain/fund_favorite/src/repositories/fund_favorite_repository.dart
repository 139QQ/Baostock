import '../entities/fund_favorite.dart';
import '../entities/fund_favorite_list.dart';
import 'package:dartz/dartz.dart';

/// 自选基金仓库接口
///
/// 定义自选基金数据操作的抽象接口，支持本地和远程数据操作
abstract class FundFavoriteRepository {
  /// 获取所有自选基金列表
  Future<Either<Exception, List<FundFavoriteList>>> getFavoriteLists();

  /// 根据ID获取自选基金列表
  Future<Either<Exception, FundFavoriteList?>> getFavoriteListById(String id);

  /// 创建新的自选基金列表
  Future<Either<Exception, FundFavoriteList>> createFavoriteList(
      FundFavoriteList list);

  /// 更新自选基金列表
  Future<Either<Exception, FundFavoriteList>> updateFavoriteList(
      FundFavoriteList list);

  /// 删除自选基金列表
  Future<Either<Exception, void>> deleteFavoriteList(String id);

  /// 获取列表中的所有基金
  Future<Either<Exception, List<FundFavorite>>> getFavoritesInList(
      String listId);

  /// 添加基金到自选列表
  Future<Either<Exception, FundFavorite>> addFavoriteToList(
      String listId, FundFavorite favorite);

  /// 从自选列表中移除基金
  Future<Either<Exception, void>> removeFavoriteFromList(
      String listId, String fundCode);

  /// 更新自选基金信息
  Future<Either<Exception, FundFavorite>> updateFavorite(FundFavorite favorite);

  /// 批量更新基金数据
  Future<Either<Exception, List<FundFavorite>>> batchUpdateFavorites(
      List<FundFavorite> favorites);

  /// 搜索自选基金
  Future<Either<Exception, List<FundFavorite>>> searchFavorites(String query,
      {String? listId});

  /// 根据排序条件获取基金
  Future<Either<Exception, List<FundFavorite>>> getFavoritesSorted(
    String listId,
    FundFavoriteSortType sortType,
    FundFavoriteSortDirection direction,
  );

  /// 同步数据到云端
  Future<Either<Exception, bool>> syncToCloud(String listId);

  /// 从云端同步数据
  Future<Either<Exception, FundFavoriteList>> syncFromCloud(String cloudId);

  /// 导出自选基金数据
  Future<Either<Exception, Map<String, dynamic>>> exportFavorites(
      String listId);

  /// 导入自选基金数据
  Future<Either<Exception, FundFavoriteList>> importFavorites(
      Map<String, dynamic> data);

  /// 获取所有自选基金（不区分列表）
  Future<Either<Exception, List<FundFavorite>>> getAllFavorites();

  /// 根据基金代码获取自选基金
  Future<Either<Exception, FundFavorite?>> getFavoriteByCode(String fundCode);

  /// 检查基金是否已在自选中
  Future<Either<Exception, bool>> isFavorite(String fundCode, {String? listId});

  /// 获取默认自选列表
  Future<Either<Exception, FundFavoriteList?>> getDefaultFavoriteList();

  /// 设置默认自选列表
  Future<Either<Exception, void>> setDefaultFavoriteList(String listId);

  /// 清空无效数据（如已删除的基金）
  Future<Either<Exception, void>> cleanupInvalidData();

  /// 获取统计信息
  Future<Either<Exception, Map<String, dynamic>>> getStatistics();
}
