import 'dart:convert';
import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:hive/hive.dart';
import '../../domain/entities/portfolio_holding.dart';
import '../../domain/repositories/portfolio_profit_repository.dart';
import '../../../../core/utils/logger.dart';

/// 持仓数据服务
///
/// 管理用户持仓数据的持久化存储
class PortfolioDataService {
  static const String _portfolioBoxName = 'user_portfolio_data';
  static const String _defaultUserId = 'default_user';

  /// 获取用户持仓列表
  Future<Either<Failure, List<PortfolioHolding>>> getUserHoldings(
      String userId) async {
    try {
      AppLogger.info('Getting user holdings for user: $userId');

      // 添加快速路径检查 - 优化空数据响应
      final quickCheck = await _quickEmptyCheck(userId);
      if (quickCheck != null) {
        AppLogger.info(
            'Quick check result for user $userId: ${quickCheck.fold((l) => 'error', (r) => 'empty data')}');
        return quickCheck;
      }

      // 添加超时保护，防止Hive操作卡住
      const timeout = Duration(seconds: 15); // 增加超时时间，避免频繁超时

      try {
        final result = await _getHoldingsFromStorage(userId).timeout(timeout);
        return result;
      } on TimeoutException {
        AppLogger.error('Hive operation timed out', TimeoutException);
        return const Left(CacheFailure('数据访问超时，请稍后重试'));
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get user holdings', e, stackTrace);

      // 如果是超时异常，返回更友好的错误信息
      String errorMessage = '获取持仓数据失败';
      if (e.toString().contains('timeout') || e.toString().contains('超时')) {
        errorMessage = '数据访问超时，请稍后重试';
      } else if (e.toString().contains('FileSystemException')) {
        errorMessage = '文件系统错误，请检查存储权限';
      } else if (e.toString().contains('Hive')) {
        errorMessage = '本地数据库访问失败，请重启应用';
      } else {
        errorMessage = '获取持仓数据失败: ${e.toString()}';
      }

      return Left(CacheFailure(errorMessage));
    }
  }

  /// 快速空数据检查 - 避免不必要的Hive操作
  Future<Either<Failure, List<PortfolioHolding>>?> _quickEmptyCheck(
      String userId) async {
    try {
      // 检查Hive是否已初始化
      if (!Hive.isAdapterRegistered(0)) {
        AppLogger.debug('Hive adapters not registered, skipping quick check');
        return null;
      }

      // 快速检查存储盒子是否存在且包含数据
      final holdingsKey = '${userId}_holdings';

      // 如果盒子未打开，快速打开
      if (!Hive.isBoxOpen(_portfolioBoxName)) {
        await Hive.openBox(_portfolioBoxName);
      }

      final box = Hive.box(_portfolioBoxName);

      // 快速检查是否存在该键
      if (!box.containsKey(holdingsKey)) {
        AppLogger.info('Quick check: No holdings key found for user $userId');
        return const Right([]); // 直接返回空数据
      }

      // 获取数据但不立即解析
      final rawData = box.get(holdingsKey);

      if (rawData == null || rawData.toString().isEmpty) {
        AppLogger.info('Quick check: Empty data found for user $userId');
        return const Right([]); // 返回空数据
      }

      // 如果数据看起来有内容，让主逻辑处理
      return null;
    } catch (e) {
      AppLogger.debug('Quick check failed, falling back to main logic: $e');
      return null; // 快速检查失败，让主逻辑处理
    }
  }

  /// 从存储中获取持仓数据的实际逻辑
  Future<Either<Failure, List<PortfolioHolding>>> _getHoldingsFromStorage(
      String userId) async {
    try {
      // 确保缓存盒子已打开
      if (!Hive.isBoxOpen(_portfolioBoxName)) {
        await Hive.openBox(_portfolioBoxName);
      }

      final box = Hive.box(_portfolioBoxName);
      final holdingsKey = '${userId}_holdings';

      // 添加重试机制，提高数据访问可靠性
      int retryCount = 0;
      const maxRetries = 3;

      while (retryCount < maxRetries) {
        try {
          // 尝试从本地存储获取
          final holdingsJson = box.get(holdingsKey);
          AppLogger.debug('Raw holdings JSON for $userId: $holdingsJson');

          if (holdingsJson != null && holdingsJson.isNotEmpty) {
            final holdings = _parseHoldingsFromJson(holdingsJson);
            AppLogger.info(
                'Retrieved ${holdings.length} holdings from local storage');

            // 验证解析后的数据
            for (final holding in holdings) {
              AppLogger.debug(
                  'Parsed holding: ${holding.fundCode} - ${holding.fundName}');
            }

            return Right(holdings);
          }

          // 如果没有数据，返回空列表而不是模拟数据
          AppLogger.info('No holdings found for user: $userId');
          return const Right([]);
        } catch (e) {
          retryCount++;
          if (retryCount < maxRetries) {
            AppLogger.warn(
                'Storage access failed, retrying ($retryCount/$maxRetries): ${e.toString()}');
            await Future.delayed(Duration(milliseconds: 200 * retryCount));
          } else {
            AppLogger.error(
                'Failed to get holdings from storage after $maxRetries retries',
                e);
            return Left(CacheFailure('存储访问失败: ${e.toString()}'));
          }
        }
      }

      // 如果重试次数用尽仍未返回，这里应该永远不会到达，但为了安全起见
      return const Left(CacheFailure('存储访问失败：重试次数耗尽'));
    } catch (e, stackTrace) {
      AppLogger.error(
          'Critical error in _getHoldingsFromStorage', e, stackTrace);
      return Left(CacheFailure('存储访问失败: ${e.toString()}'));
    }
  }

  /// 添加或更新持仓
  Future<Either<Failure, PortfolioHolding>> addOrUpdateHolding(
      String userId, PortfolioHolding holding) async {
    try {
      AppLogger.info(
          'Adding/updating holding: ${holding.fundCode} for user: $userId');

      // 确保缓存盒子已打开
      if (!Hive.isBoxOpen(_portfolioBoxName)) {
        await Hive.openBox(_portfolioBoxName);
      }

      final box = Hive.box(_portfolioBoxName);
      final holdingsKey = '${userId}_holdings';

      // 获取现有持仓
      final existingHoldingsJson = box.get(holdingsKey);
      List<PortfolioHolding> holdings = existingHoldingsJson != null
          ? _parseHoldingsFromJson(existingHoldingsJson)
          : [];

      // 检查是否已存在相同基金代码的持仓
      final existingIndex =
          holdings.indexWhere((h) => h.fundCode == holding.fundCode);

      final updatedHolding = holding.copyWith(lastUpdatedDate: DateTime.now());

      if (existingIndex >= 0) {
        // 更新现有持仓
        holdings[existingIndex] = updatedHolding;
        AppLogger.info('Updated existing holding: ${holding.fundCode}');
      } else {
        // 添加新持仓
        holdings.add(updatedHolding);
        AppLogger.info('Added new holding: ${holding.fundCode}');
      }

      // 保存到本地存储
      await box.put(holdingsKey, _holdingsToJson(holdings));

      AppLogger.info('Successfully saved holding: ${holding.fundCode}');
      return Right(updatedHolding);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to add/update holding', e, stackTrace);
      return Left(CacheFailure('添加/更新持仓失败: ${e.toString()}'));
    }
  }

  /// 删除持仓
  Future<Either<Failure, bool>> deleteHolding(
      String userId, String fundCode) async {
    try {
      AppLogger.info('Deleting holding: $fundCode for user: $userId');

      // 确保缓存盒子已打开
      if (!Hive.isBoxOpen(_portfolioBoxName)) {
        await Hive.openBox(_portfolioBoxName);
      }

      final box = Hive.box(_portfolioBoxName);
      final holdingsKey = '${userId}_holdings';

      // 获取现有持仓
      final existingHoldingsJson = box.get(holdingsKey);
      if (existingHoldingsJson == null) {
        AppLogger.warn('No holdings found for user: $userId');
        return const Right(true); // 没有持仓也算删除成功
      }

      final holdings = _parseHoldingsFromJson(existingHoldingsJson);
      final initialCount = holdings.length;

      // 移除指定基金代码的持仓
      holdings.removeWhere((h) => h.fundCode == fundCode);

      if (holdings.length < initialCount) {
        // 保存更新后的持仓列表
        await box.put(holdingsKey, _holdingsToJson(holdings));
        AppLogger.info('Successfully deleted holding: $fundCode');
        return const Right(true);
      } else {
        AppLogger.warn('Holding not found for deletion: $fundCode');
        return const Right(false);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete holding', e, stackTrace);
      return Left(CacheFailure('删除持仓失败: ${e.toString()}'));
    }
  }

  /// 获取持仓数量
  Future<Either<Failure, int>> getHoldingsCount(String userId) async {
    try {
      final result = await getUserHoldings(userId);
      return result.fold(
        (failure) => Left(failure),
        (holdings) => Right(holdings.length),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get holdings count', e, stackTrace);
      return Left(CacheFailure('获取持仓数量失败: ${e.toString()}'));
    }
  }

  /// 清空用户所有持仓
  Future<Either<Failure, bool>> clearAllHoldings(String userId) async {
    try {
      AppLogger.info('Clearing all holdings for user: $userId');

      // 确保缓存盒子已打开
      if (!Hive.isBoxOpen(_portfolioBoxName)) {
        await Hive.openBox(_portfolioBoxName);
      }

      final box = Hive.box(_portfolioBoxName);
      final holdingsKey = '${userId}_holdings';

      await box.delete(holdingsKey);

      AppLogger.info('Successfully cleared all holdings for user: $userId');
      return const Right(true);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clear holdings', e, stackTrace);
      return Left(CacheFailure('清空持仓失败: ${e.toString()}'));
    }
  }

  /// 导入持仓数据
  Future<Either<Failure, List<PortfolioHolding>>> importHoldings(
      String userId, List<PortfolioHolding> holdings) async {
    try {
      AppLogger.info('Importing ${holdings.length} holdings for user: $userId');

      // 确保缓存盒子已打开
      if (!Hive.isBoxOpen(_portfolioBoxName)) {
        await Hive.openBox(_portfolioBoxName);
      }

      final box = Hive.box(_portfolioBoxName);
      final holdingsKey = '${userId}_holdings';

      // 保存导入的持仓数据
      await box.put(holdingsKey, _holdingsToJson(holdings));

      AppLogger.info('Successfully imported ${holdings.length} holdings');
      return Right(holdings);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to import holdings', e, stackTrace);
      return Left(CacheFailure('导入持仓失败: ${e.toString()}'));
    }
  }

  /// 优化的持仓列表转换为JSON - 提高性能
  String _holdingsToJson(List<PortfolioHolding> holdings) {
    // 优化：使用预分配容量的列表，减少内存重分配
    final holdingsJson = <Map<String, dynamic>>[];

    for (final holding in holdings) {
      holdingsJson.add({
        'fundCode': holding.fundCode,
        'fundName': holding.fundName,
        'fundType': holding.fundType,
        'holdingAmount': holding.holdingAmount,
        'costNav': holding.costNav,
        'costValue': holding.costValue,
        'marketValue': holding.marketValue,
        'currentNav': holding.currentNav,
        'accumulatedNav': holding.accumulatedNav,
        'holdingStartDate': holding.holdingStartDate.toIso8601String(),
        'lastUpdatedDate': holding.lastUpdatedDate.toIso8601String(),
        'dividendReinvestment': holding.dividendReinvestment,
        'status': holding.status.index,
        'notes': holding.notes,
      });
    }

    return json.encode(holdingsJson);
  }

  /// 从JSON解析持仓列表
  List<PortfolioHolding> _parseHoldingsFromJson(String holdingsJson) {
    try {
      AppLogger.debug('Parsing holdings JSON: $holdingsJson');
      final List<dynamic> holdingsList = json.decode(holdingsJson);

      return holdingsList.map((holdingJson) {
        try {
          final Map<String, dynamic> data = holdingJson as Map<String, dynamic>;

          // 安全解析日期字段
          DateTime holdingStartDate;
          DateTime lastUpdatedDate;

          try {
            holdingStartDate =
                DateTime.parse(data['holdingStartDate'] as String);
          } catch (e) {
            AppLogger.warn(
                'Failed to parse holdingStartDate for ${data['fundCode']}: ${data['holdingStartDate']}');
            holdingStartDate = DateTime.now(); // 使用默认值
          }

          try {
            lastUpdatedDate = DateTime.parse(data['lastUpdatedDate'] as String);
          } catch (e) {
            AppLogger.warn(
                'Failed to parse lastUpdatedDate for ${data['fundCode']}: ${data['lastUpdatedDate']}');
            lastUpdatedDate = DateTime.now(); // 使用默认值
          }

          // 安全解析状态枚举
          HoldingStatus status;
          try {
            final statusIndex = data['status'] as int?;
            status = statusIndex != null
                ? HoldingStatus.values[statusIndex]
                : HoldingStatus.active;
          } catch (e) {
            AppLogger.warn(
                'Failed to parse status for ${data['fundCode']}: ${data['status']}');
            status = HoldingStatus.active; // 使用默认值
          }

          return PortfolioHolding(
            fundCode: data['fundCode'] as String? ?? '',
            fundName: data['fundName'] as String? ?? '',
            fundType: data['fundType'] as String? ?? '',
            holdingAmount: (data['holdingAmount'] as num?)?.toDouble() ?? 0.0,
            costNav: (data['costNav'] as num?)?.toDouble() ?? 0.0,
            costValue: (data['costValue'] as num?)?.toDouble() ?? 0.0,
            marketValue: (data['marketValue'] as num?)?.toDouble() ?? 0.0,
            currentNav: (data['currentNav'] as num?)?.toDouble() ?? 0.0,
            accumulatedNav: (data['accumulatedNav'] as num?)?.toDouble() ?? 0.0,
            holdingStartDate: holdingStartDate,
            lastUpdatedDate: lastUpdatedDate,
            dividendReinvestment: data['dividendReinvestment'] as bool? ?? true,
            status: status,
            notes: data['notes'] as String?,
          );
        } catch (e, stackTrace) {
          AppLogger.error('Failed to parse individual holding: $holdingJson', e,
              stackTrace);
          // 返回一个空的持仓对象而不是崩溃
          return PortfolioHolding(
            fundCode: '',
            fundName: '解析错误',
            fundType: '错误',
            holdingAmount: 0.0,
            costNav: 0.0,
            costValue: 0.0,
            marketValue: 0.0,
            currentNav: 0.0,
            accumulatedNav: 0.0,
            holdingStartDate: DateTime.now(),
            lastUpdatedDate: DateTime.now(),
            dividendReinvestment: true,
            status: HoldingStatus.active,
          );
        }
      }).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to parse holdings from JSON', e, stackTrace);
      AppLogger.error(
          'Holdings JSON that failed to parse: $holdingsJson', e, stackTrace);
      return [];
    }
  }

  /// 获取默认用户ID的持仓（为了兼容现有代码）
  Future<Either<Failure, List<PortfolioHolding>>>
      getDefaultUserHoldings() async {
    return getUserHoldings(_defaultUserId);
  }

  /// 为默认用户添加持仓（为了兼容现有代码）
  Future<Either<Failure, PortfolioHolding>> addDefaultUserHolding(
      PortfolioHolding holding) async {
    return addOrUpdateHolding(_defaultUserId, holding);
  }

  /// 从默认用户删除持仓（为了兼容现有代码）
  Future<Either<Failure, bool>> deleteDefaultUserHolding(
      String fundCode) async {
    return deleteHolding(_defaultUserId, fundCode);
  }
}
