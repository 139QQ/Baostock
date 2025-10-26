import 'package:jisu_fund_analyzer/src/features/portfolio/domain/fund_favorite/src/entities/fund_favorite.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/entities/portfolio_holding.dart';
import 'package:jisu_fund_analyzer/src/core/utils/logger.dart';
import 'favorite_to_holding_service.dart';

/// 自选基金与持仓数据联动服务
///
/// 提供自选基金和持仓分析之间的数据同步、转换和管理功能：
/// - 批量导入自选基金到持仓
/// - 数据状态同步
/// - 冲突检测和解决
/// - 操作历史记录
class PortfolioFavoriteSyncService {
  static const String _tag = 'PortfolioFavoriteSyncService';
  static final FavoriteToHoldingService _converter = FavoriteToHoldingService();

  /// 检测自选基金与持仓数据的一致性
  ///
  /// [favorites] 自选基金列表
  /// [holdings] 持仓数据列表
  /// 返回一致性报告
  SyncConsistencyReport checkConsistency(
    List<FundFavorite> favorites,
    List<PortfolioHolding> holdings,
  ) {
    AppLogger.info(
        'Checking consistency between ${favorites.length} favorites and ${holdings.length} holdings',
        _tag);

    final favoriteCodes = favorites.map((f) => f.fundCode).toSet();
    final holdingCodes = holdings.map((h) => h.fundCode).toSet();

    // 计算交集和差集
    final commonCodes = favoriteCodes.intersection(holdingCodes);
    final onlyInFavorites = favoriteCodes.difference(holdingCodes);
    final onlyInHoldings = holdingCodes.difference(favoriteCodes);

    // 检测数据不一致
    final List<DataInconsistency> inconsistencies = [];

    for (final code in commonCodes) {
      final favorite = favorites.firstWhere((f) => f.fundCode == code);
      final holding = holdings.firstWhere((h) => h.fundCode == code);

      // 检查基本信息是否一致
      if (favorite.fundName != holding.fundName ||
          favorite.fundType != holding.fundType) {
        inconsistencies.add(DataInconsistency(
          fundCode: code,
          type: InconsistencyType.basicInfoMismatch,
          favoriteData: '${favorite.fundName} (${favorite.fundType})',
          holdingData: '${holding.fundName} (${holding.fundType})',
        ));
      }

      // 检查净值数据是否差异过大
      if (favorite.currentNav != null && holding.currentNav > 0) {
        final diff = (favorite.currentNav! - holding.currentNav).abs();
        final diffPercent = diff / favorite.currentNav!;
        if (diffPercent > 0.01) {
          // 差异超过1%
          inconsistencies.add(DataInconsistency(
            fundCode: code,
            type: InconsistencyType.navValueMismatch,
            favoriteData: '净值: ${favorite.currentNav!.toStringAsFixed(4)}',
            holdingData: '净值: ${holding.currentNav.toStringAsFixed(4)}',
            severity: InconsistencySeverity.warning,
          ));
        }
      }
    }

    return SyncConsistencyReport(
      totalFavorites: favorites.length,
      totalHoldings: holdings.length,
      commonCount: commonCodes.length,
      onlyInFavorites: onlyInFavorites.toList(),
      onlyInHoldings: onlyInHoldings.toList(),
      inconsistencies: inconsistencies,
      isConsistent: inconsistencies.isEmpty &&
          onlyInFavorites.isEmpty &&
          onlyInHoldings.isEmpty,
    );
  }

  /// 同步自选基金到持仓
  ///
  /// [favorites] 要同步的自选基金列表
  /// [existingHoldings] 现有持仓数据
  /// [syncOptions] 同步选项
  /// 返回同步结果
  Future<SyncResult> syncFavoritesToHoldings(
    List<FundFavorite> favorites,
    List<PortfolioHolding> existingHoldings,
    SyncOptions syncOptions,
  ) async {
    AppLogger.info(
        'Starting sync of ${favorites.length} favorites to holdings', _tag);

    try {
      // 1. 分析现有数据
      final consistencyReport = checkConsistency(favorites, existingHoldings);

      // 2. 生成同步计划
      final syncPlan = _generateSyncPlan(
          favorites, existingHoldings, consistencyReport, syncOptions);

      // 3. 执行同步操作
      final List<PortfolioHolding> updatedHoldings = [];
      final List<SyncOperation> operations = [];

      // 处理新增的持仓
      for (final favorite in syncPlan.toAdd) {
        final holding = _converter.convertFavoriteToHolding(
          favorite,
          defaultAmount: syncOptions.defaultAmount,
          estimateCost: syncOptions.useCurrentNavAsCost,
        );

        updatedHoldings.add(holding);
        operations.add(SyncOperation(
          type: SyncOperationType.add,
          fundCode: favorite.fundCode,
          description: '添加新持仓: ${favorite.fundName}',
        ));
      }

      // 处理更新的持仓
      for (final update in syncPlan.toUpdate) {
        updatedHoldings.add(update.updatedHolding);
        operations.add(SyncOperation(
          type: SyncOperationType.update,
          fundCode: update.favorite.fundCode,
          description: '更新持仓信息: ${update.favorite.fundName}',
        ));
      }

      // 保留现有持仓（如果选择保留）
      if (syncOptions.keepExistingHoldings) {
        final codesToKeep = existingHoldings
            .where((h) => !syncPlan.toRemove.contains(h.fundCode))
            .map((h) => h.fundCode)
            .toSet();

        final preservedHoldings = existingHoldings
            .where((h) => codesToKeep.contains(h.fundCode))
            .toList();

        updatedHoldings.addAll(preservedHoldings);
      }

      // 4. 生成同步报告
      final result = SyncResult(
        success: true,
        operations: operations,
        updatedHoldings: updatedHoldings,
        addedCount: syncPlan.toAdd.length,
        updatedCount: syncPlan.toUpdate.length,
        removedCount: syncPlan.toRemove.length,
        totalCount: updatedHoldings.length,
        syncDuration: DateTime.now(),
      );

      AppLogger.info('Sync completed: ${result.summary}', _tag);
      return result;
    } catch (e) {
      AppLogger.error('Sync failed', e, null);
      return SyncResult(
        success: false,
        operations: [],
        updatedHoldings: existingHoldings,
        addedCount: 0,
        updatedCount: 0,
        removedCount: 0,
        totalCount: existingHoldings.length,
        syncDuration: DateTime.now(),
        errorMessage: e.toString(),
      );
    }
  }

  /// 生成同步计划
  SyncPlan _generateSyncPlan(
    List<FundFavorite> favorites,
    List<PortfolioHolding> existingHoldings,
    SyncConsistencyReport consistencyReport,
    SyncOptions options,
  ) {
    final favoriteMap = {for (var f in favorites) f.fundCode: f};
    final holdingMap = {for (var h in existingHoldings) h.fundCode: h};

    final List<FundFavorite> toAdd = [];
    final List<HoldingsUpdate> toUpdate = [];
    final List<String> toRemove = [];

    // 处理只在自选中存在的基金（需要添加到持仓）
    for (final code in consistencyReport.onlyInFavorites) {
      toAdd.add(favoriteMap[code]!);
    }

    // 处理共同存在的基金（检查是否需要更新）
    final commonCodes =
        favoriteMap.keys.toSet().intersection(holdingMap.keys.toSet());

    for (final code in commonCodes) {
      final favorite = favoriteMap[code]!;
      final holding = holdingMap[code]!;

      // 检查是否需要更新
      bool needsUpdate = false;
      PortfolioHolding? updatedHolding;

      // 基本信息检查
      if (favorite.fundName != holding.fundName ||
          favorite.fundType != holding.fundType) {
        needsUpdate = true;
        updatedHolding = holding.copyWith(
          fundName: favorite.fundName,
          fundType: favorite.fundType,
          lastUpdatedDate: DateTime.now(),
        );
      }

      // 净值数据更新（如果有新的净值数据）
      if (favorite.currentNav != null &&
          favorite.currentNav != holding.currentNav) {
        needsUpdate = true;
        updatedHolding = (updatedHolding ?? holding).copyWith(
          currentNav: favorite.currentNav,
          marketValue: holding.holdingAmount * favorite.currentNav!,
          lastUpdatedDate: DateTime.now(),
        );
      }

      if (needsUpdate && updatedHolding != null) {
        toUpdate.add(HoldingsUpdate(
          favorite: favorite,
          existingHolding: holding,
          updatedHolding: updatedHolding,
        ));
      }
    }

    // 处理只在持仓中存在的基金（根据选项决定是否移除）
    if (!options.keepExistingHoldings) {
      toRemove.addAll(consistencyReport.onlyInHoldings);
    }

    return SyncPlan(
      toAdd: toAdd,
      toUpdate: toUpdate,
      toRemove: toRemove,
    );
  }

  /// 验证同步操作的可行性
  ValidationResult validateSyncOperation(
    List<FundFavorite> favorites,
    List<PortfolioHolding> existingHoldings,
    SyncOptions options,
  ) {
    final issues = <ValidationIssue>[];
    final warnings = <ValidationIssue>[];

    // 检查数据完整性
    if (favorites.isEmpty) {
      warnings.add(const ValidationIssue(
        type: ValidationIssueType.emptyData,
        message: '没有自选基金数据',
        severity: ValidationSeverity.warning,
      ));
    }

    // 检查持有份额设置
    if (options.defaultAmount <= 0) {
      issues.add(const ValidationIssue(
        type: ValidationIssueType.invalidAmount,
        message: '默认持有份额必须大于0',
        severity: ValidationSeverity.error,
      ));
    }

    // 检查自选基金数据质量
    for (final favorite in favorites) {
      if (favorite.fundCode.isEmpty || favorite.fundName.isEmpty) {
        issues.add(ValidationIssue(
          type: ValidationIssueType.incompleteData,
          message: '基金 ${favorite.fundCode} 数据不完整',
          severity: ValidationSeverity.error,
        ));
      }

      if (favorite.currentNav != null && favorite.currentNav! <= 0) {
        warnings.add(ValidationIssue(
          type: ValidationIssueType.invalidNav,
          message: '基金 ${favorite.fundCode} 当前净值异常: ${favorite.currentNav}',
          severity: ValidationSeverity.warning,
        ));
      }
    }

    // 检查重复数据
    final duplicateCodes = <String>{};
    for (final favorite in favorites) {
      if (duplicateCodes.contains(favorite.fundCode)) {
        issues.add(ValidationIssue(
          type: ValidationIssueType.duplicateData,
          message: '重复的基金代码: ${favorite.fundCode}',
          severity: ValidationSeverity.error,
        ));
      }
      duplicateCodes.add(favorite.fundCode);
    }

    return ValidationResult(
      isValid: issues.isEmpty,
      issues: issues,
      warnings: warnings,
      canProceed: issues.isEmpty,
    );
  }
}

/// 数据同步选项
class SyncOptions {
  final double defaultAmount;
  final bool useCurrentNavAsCost;
  final bool keepExistingHoldings;
  final bool updateBasicInfo;
  final bool updateNavData;

  const SyncOptions({
    this.defaultAmount = 1000.0,
    this.useCurrentNavAsCost = true,
    this.keepExistingHoldings = true,
    this.updateBasicInfo = true,
    this.updateNavData = true,
  });
}

/// 同步一致性报告
class SyncConsistencyReport {
  final int totalFavorites;
  final int totalHoldings;
  final int commonCount;
  final List<String> onlyInFavorites;
  final List<String> onlyInHoldings;
  final List<DataInconsistency> inconsistencies;
  final bool isConsistent;

  const SyncConsistencyReport({
    required this.totalFavorites,
    required this.totalHoldings,
    required this.commonCount,
    required this.onlyInFavorites,
    required this.onlyInHoldings,
    required this.inconsistencies,
    required this.isConsistent,
  });

  String get summary {
    return '自选: $totalFavorites, 持仓: $totalHoldings, 共同: $commonCount, '
        '仅自选: ${onlyInFavorites.length}, 仅持仓: ${onlyInHoldings.length}, '
        '不一致: ${inconsistencies.length}';
  }
}

/// 数据不一致信息
class DataInconsistency {
  final String fundCode;
  final InconsistencyType type;
  final String favoriteData;
  final String holdingData;
  final InconsistencySeverity severity;

  const DataInconsistency({
    required this.fundCode,
    required this.type,
    required this.favoriteData,
    required this.holdingData,
    this.severity = InconsistencySeverity.error,
  });
}

/// 不一致类型
enum InconsistencyType {
  basicInfoMismatch,
  navValueMismatch,
  holdingAmountMismatch,
}

/// 不一致严重程度
enum InconsistencySeverity {
  info,
  warning,
  error,
}

/// 同步计划
class SyncPlan {
  final List<FundFavorite> toAdd;
  final List<HoldingsUpdate> toUpdate;
  final List<String> toRemove;

  const SyncPlan({
    required this.toAdd,
    required this.toUpdate,
    required this.toRemove,
  });
}

/// 持仓更新信息
class HoldingsUpdate {
  final FundFavorite favorite;
  final PortfolioHolding existingHolding;
  final PortfolioHolding updatedHolding;

  const HoldingsUpdate({
    required this.favorite,
    required this.existingHolding,
    required this.updatedHolding,
  });
}

/// 同步结果
class SyncResult {
  final bool success;
  final List<SyncOperation> operations;
  final List<PortfolioHolding> updatedHoldings;
  final int addedCount;
  final int updatedCount;
  final int removedCount;
  final int totalCount;
  final String? errorMessage;
  final DateTime syncDuration;

  const SyncResult({
    required this.success,
    required this.operations,
    required this.updatedHoldings,
    required this.addedCount,
    required this.updatedCount,
    required this.removedCount,
    required this.totalCount,
    required this.syncDuration,
    this.errorMessage,
  });

  String get summary {
    if (success) {
      return '同步成功: 添加 $addedCount, 更新 $updatedCount, 移除 $removedCount, 总计 $totalCount';
    } else {
      return '同步失败: $errorMessage';
    }
  }
}

/// 同步操作记录
class SyncOperation {
  final SyncOperationType type;
  final String fundCode;
  final String description;
  final DateTime timestamp;

  SyncOperation({
    required this.type,
    required this.fundCode,
    required this.description,
  }) : timestamp = DateTime.now();
}

/// 同步操作类型
enum SyncOperationType {
  add,
  update,
  remove,
}

/// 验证结果
class ValidationResult {
  final bool isValid;
  final List<ValidationIssue> issues;
  final List<ValidationIssue> warnings;
  final bool canProceed;

  const ValidationResult({
    required this.isValid,
    required this.issues,
    required this.warnings,
    required this.canProceed,
  });
}

/// 验证问题
class ValidationIssue {
  final ValidationIssueType type;
  final String message;
  final ValidationSeverity severity;

  const ValidationIssue({
    required this.type,
    required this.message,
    required this.severity,
  });
}

/// 验证问题类型
enum ValidationIssueType {
  emptyData,
  incompleteData,
  duplicateData,
  invalidAmount,
  invalidNav,
}

/// 验证严重程度
enum ValidationSeverity {
  info,
  warning,
  error,
}
