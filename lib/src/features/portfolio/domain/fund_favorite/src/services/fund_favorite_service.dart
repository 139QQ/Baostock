import '../entities/fund_favorite.dart';
import '../entities/fund_favorite_list.dart';
import '../repositories/fund_favorite_repository.dart';
import 'package:dartz/dartz.dart';

/// 自选基金领域服务
///
/// 提供自选基金相关的业务逻辑和规则验证
class FundFavoriteService {
  final FundFavoriteRepository _repository;

  FundFavoriteService(this._repository);

  /// 创建新的自选基金列表
  ///
  /// 验证列表名称和配置的合法性
  Future<Either<Exception, FundFavoriteList>> createFavoriteList({
    required String name,
    String? description,
    String? iconCode,
    String? colorTheme,
    bool isDefault = false,
    List<String> tags = const [],
  }) async {
    try {
      // 验证列表名称
      if (name.trim().isEmpty) {
        return left(Exception('列表名称不能为空'));
      }

      if (name.length > 50) {
        return left(Exception('列表名称不能超过50个字符'));
      }

      // 检查是否已存在相同名称的列表
      final existingLists = await _repository.getFavoriteLists();
      final hasDuplicateName = existingLists.fold(
        (l) => false,
        (lists) => lists.any((list) => list.name == name.trim()),
      );

      if (hasDuplicateName) {
        return left(Exception('已存在相同名称的列表'));
      }

      // 创建新列表
      final now = DateTime.now();
      final newList = FundFavoriteList(
        id: _generateId(),
        name: name.trim(),
        description: description?.trim(),
        createdAt: now,
        updatedAt: now,
        isDefault: isDefault,
        iconCode: iconCode,
        colorTheme: colorTheme,
        tags: tags,
      );

      return await _repository.createFavoriteList(newList);
    } catch (e) {
      return left(Exception('创建自选列表失败: $e'));
    }
  }

  /// 添加基金到自选列表
  ///
  /// 验证基金信息和添加规则的合法性
  Future<Either<Exception, FundFavorite>> addFavoriteToList({
    required String listId,
    required String fundCode,
    required String fundName,
    required String fundType,
    required String fundManager,
    String? notes,
    double? sortWeight,
    PriceAlertSettings? priceAlerts,
  }) async {
    try {
      // 验证基金代码格式
      if (!_isValidFundCode(fundCode)) {
        return left(Exception('基金代码格式不正确'));
      }

      // 验证基金名称
      if (fundName.trim().isEmpty) {
        return left(Exception('基金名称不能为空'));
      }

      // 检查基金是否已在列表中
      final isAlreadyFavorite =
          await _repository.isFavorite(fundCode, listId: listId);
      final alreadyExists = isAlreadyFavorite.fold(
        (l) => false,
        (exists) => exists,
      );

      if (alreadyExists) {
        return left(Exception('基金已在自选列表中'));
      }

      // 验证列表是否存在
      final listResult = await _repository.getFavoriteListById(listId);
      final list = listResult.fold(
        (l) => null,
        (list) => list,
      );

      if (list == null) {
        return left(Exception('自选列表不存在'));
      }

      // 创建新的自选基金
      final now = DateTime.now();
      final favorite = FundFavorite(
        fundCode: fundCode.toUpperCase().trim(),
        fundName: fundName.trim(),
        fundType: fundType.trim(),
        fundManager: fundManager.trim(),
        addedAt: now,
        updatedAt: now,
        sortWeight: sortWeight ?? 0.0,
        notes: notes?.trim(),
        priceAlerts: priceAlerts,
      );

      final result = await _repository.addFavoriteToList(listId, favorite);

      // 更新列表基金数量
      if (result.isRight()) {
        final updatedList = list.updateFundCount(list.fundCount + 1);
        await _repository.updateFavoriteList(updatedList);
      }

      return result;
    } catch (e) {
      return left(Exception('添加基金到自选列表失败: $e'));
    }
  }

  /// 移除基金从自选列表
  Future<Either<Exception, void>> removeFavoriteFromList({
    required String listId,
    required String fundCode,
  }) async {
    try {
      // 验证基金是否在列表中
      final isFavorite = await _repository.isFavorite(fundCode, listId: listId);
      final exists = isFavorite.fold(
        (l) => false,
        (exists) => exists,
      );

      if (!exists) {
        return left(Exception('基金不在自选列表中'));
      }

      // 获取列表信息
      final listResult = await _repository.getFavoriteListById(listId);
      final list = listResult.fold(
        (l) => null,
        (list) => list,
      );

      // 执行移除操作
      final result = await _repository.removeFavoriteFromList(listId, fundCode);

      // 更新列表基金数量
      if (result.isRight() && list != null) {
        final updatedList = list.updateFundCount(list.fundCount - 1);
        await _repository.updateFavoriteList(updatedList);
      }

      return result;
    } catch (e) {
      return left(Exception('从自选列表移除基金失败: $e'));
    }
  }

  /// 更新自选基金信息
  Future<Either<Exception, FundFavorite>> updateFavorite({
    required String listId,
    required String fundCode,
    String? notes,
    double? sortWeight,
    PriceAlertSettings? priceAlerts,
  }) async {
    try {
      // 获取现有基金信息
      final existingFavorite = await _repository.getFavoriteByCode(fundCode);
      final favorite = existingFavorite.fold(
        (l) => null,
        (favorite) => favorite,
      );

      if (favorite == null) {
        return left(Exception('自选基金不存在'));
      }

      // 创建更新后的基金信息
      final updatedFavorite = favorite.copyWith(
        notes: notes?.trim(),
        sortWeight: sortWeight,
        priceAlerts: priceAlerts,
        updatedAt: DateTime.now(),
      );

      return await _repository.updateFavorite(updatedFavorite);
    } catch (e) {
      return left(Exception('更新自选基金信息失败: $e'));
    }
  }

  /// 更新基金市场数据
  Future<Either<Exception, FundFavorite>> updateMarketData({
    required String fundCode,
    double? currentNav,
    double? dailyChange,
    double? previousNav,
  }) async {
    try {
      // 获取现有基金信息
      final existingFavorite = await _repository.getFavoriteByCode(fundCode);
      final favorite = existingFavorite.fold(
        (l) => null,
        (favorite) => favorite,
      );

      if (favorite == null) {
        return left(Exception('自选基金不存在'));
      }

      // 验证市场数据的合法性
      if (currentNav != null && currentNav <= 0) {
        return left(Exception('基金净值必须大于0'));
      }

      // 更新市场数据
      final updatedFavorite = favorite.updateMarketData(
        currentNav: currentNav,
        dailyChange: dailyChange,
        previousNav: previousNav,
      );

      return await _repository.updateFavorite(updatedFavorite);
    } catch (e) {
      return left(Exception('更新基金市场数据失败: $e'));
    }
  }

  /// 批量更新基金市场数据
  Future<Either<Exception, List<FundFavorite>>> batchUpdateMarketData(
    List<Map<String, dynamic>> marketDataList,
  ) async {
    try {
      if (marketDataList.isEmpty) {
        return right([]);
      }

      final updatedFavorites = <FundFavorite>[];

      for (final data in marketDataList) {
        final fundCode = data['fundCode'] as String?;
        if (fundCode == null) continue;

        final result = await updateMarketData(
          fundCode: fundCode,
          currentNav: data['currentNav'] as double?,
          dailyChange: data['dailyChange'] as double?,
          previousNav: data['previousNav'] as double?,
        );

        result.fold(
          (error) => {}, // 跳过更新失败的基金
          (favorite) => updatedFavorites.add(favorite),
        );
      }

      return right(updatedFavorites);
    } catch (e) {
      return left(Exception('批量更新基金市场数据失败: $e'));
    }
  }

  /// 搜索自选基金
  Future<Either<Exception, List<FundFavorite>>> searchFavorites({
    required String query,
    String? listId,
    int limit = 50,
  }) async {
    try {
      if (query.trim().isEmpty) {
        return left(Exception('搜索关键词不能为空'));
      }

      if (query.length < 2) {
        return left(Exception('搜索关键词至少需要2个字符'));
      }

      return await _repository.searchFavorites(query.trim(), listId: listId);
    } catch (e) {
      return left(Exception('搜索自选基金失败: $e'));
    }
  }

  /// 获取排序后的自选基金
  Future<Either<Exception, List<FundFavorite>>> getFavoritesSorted({
    required String listId,
    required FundFavoriteSortType sortType,
    required FundFavoriteSortDirection direction,
  }) async {
    try {
      return await _repository.getFavoritesSorted(listId, sortType, direction);
    } catch (e) {
      return left(Exception('获取排序后的自选基金失败: $e'));
    }
  }

  /// 设置价格提醒
  Future<Either<Exception, FundFavorite>> setPriceAlert({
    required String fundCode,
    required double riseThreshold,
    required double fallThreshold,
    List<AlertMethod> alertMethods = const [AlertMethod.push],
  }) async {
    try {
      if (riseThreshold <= 0 || fallThreshold <= 0) {
        return left(Exception('涨跌幅阈值必须大于0'));
      }

      if (riseThreshold > 100 || fallThreshold > 100) {
        return left(Exception('涨跌幅阈值不能超过100%'));
      }

      final existingFavorite = await _repository.getFavoriteByCode(fundCode);
      final favorite = existingFavorite.fold(
        (l) => null,
        (favorite) => favorite,
      );

      if (favorite == null) {
        return left(Exception('自选基金不存在'));
      }

      final alertSettings = PriceAlertSettings(
        enabled: true,
        riseThreshold: riseThreshold,
        fallThreshold: fallThreshold,
        alertMethods: alertMethods,
      );

      final updatedFavorite = favorite.setPriceAlerts(alertSettings);
      return await _repository.updateFavorite(updatedFavorite);
    } catch (e) {
      return left(Exception('设置价格提醒失败: $e'));
    }
  }

  /// 验证基金代码格式
  bool _isValidFundCode(String fundCode) {
    final code = fundCode.trim().toUpperCase();
    if (code.isEmpty) return false;

    // 基金代码通常是6位数字
    return RegExp(r'^[A-Z0-9]{6}$').hasMatch(code);
  }

  /// 生成唯一ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + _randomString(8);
  }

  /// 生成随机字符串
  String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    String result = '';

    for (int i = 0; i < length; i++) {
      result += chars[(random + i) % chars.length];
    }

    return result;
  }

  /// 获取自选基金统计信息
  Future<Either<Exception, Map<String, dynamic>>> getFavoriteStatistics({
    String? listId,
  }) async {
    try {
      final favorites = listId != null
          ? await _repository.getFavoritesInList(listId)
          : await _repository.getAllFavorites();

      final favoriteList = favorites.fold(
        (l) => <FundFavorite>[],
        (list) => list,
      );

      if (favoriteList.isEmpty) {
        return right({
          'totalFunds': 0,
          'totalProfit': 0.0,
          'averageDailyChange': 0.0,
          'bestPerformingFund': null,
          'worstPerformingFund': null,
          'fundTypes': <String, int>{},
        });
      }

      // 计算统计信息
      double totalProfit = 0.0;
      double totalDailyChange = 0.0;
      int fundsWithData = 0;

      String? bestPerformingFund;
      String? worstPerformingFund;
      double bestPerformance = double.negativeInfinity;
      double worstPerformance = double.infinity;

      final fundTypes = <String, int>{};

      for (final favorite in favoriteList) {
        // 统计基金类型
        fundTypes[favorite.fundType] = (fundTypes[favorite.fundType] ?? 0) + 1;

        // 统计收益数据
        if (favorite.dailyChange != null) {
          totalDailyChange += favorite.dailyChange!;
          fundsWithData++;

          // 找出最好和最差表现的基金
          if (favorite.dailyChange! > bestPerformance) {
            bestPerformance = favorite.dailyChange!;
            bestPerformingFund = favorite.fundName;
          }
          if (favorite.dailyChange! < worstPerformance) {
            worstPerformance = favorite.dailyChange!;
            worstPerformingFund = favorite.fundName;
          }
        }
      }

      return right({
        'totalFunds': favoriteList.length,
        'totalProfit': totalProfit,
        'averageDailyChange':
            fundsWithData > 0 ? totalDailyChange / fundsWithData : 0.0,
        'bestPerformingFund': bestPerformingFund,
        'worstPerformingFund': worstPerformingFund,
        'fundTypes': fundTypes,
      });
    } catch (e) {
      return left(Exception('获取自选基金统计信息失败: $e'));
    }
  }
}
