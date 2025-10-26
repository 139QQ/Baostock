import 'package:jisu_fund_analyzer/src/features/portfolio/domain/fund_favorite/src/entities/fund_favorite.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/entities/portfolio_holding.dart';
import '../../../../core/utils/logger.dart';

/// 自选基金到持仓数据转换服务
///
/// 提供将自选基金转换为持仓数据的核心功能，支持：
/// - 批量转换自选基金为持仓
/// - 智能填充基金基本信息
/// - 估算默认持仓参数
/// - 用户确认和调整机制
class FavoriteToHoldingService {
  static const String _tag = 'FavoriteToHoldingService';

  /// 将单个自选基金转换为持仓数据模板
  ///
  /// [favorite] 自选基金数据
  /// [defaultAmount] 默认持有份额（可选）
  /// [estimateCost] 是否估算成本（基于最新净值）
  PortfolioHolding convertFavoriteToHolding(
    FundFavorite favorite, {
    double? defaultAmount,
    bool estimateCost = true,
  }) {
    AppLogger.debug(
        'Converting favorite to holding: ${favorite.fundCode}', _tag);

    final now = DateTime.now();
    final amount = defaultAmount ?? 1000.0; // 默认1000份
    final costNav = estimateCost && favorite.currentNav != null
        ? favorite.currentNav!
        : 1.0; // 默认成本净值

    return PortfolioHolding(
      fundCode: favorite.fundCode,
      fundName: favorite.fundName,
      fundType: favorite.fundType,
      holdingAmount: amount,
      costNav: costNav,
      costValue: amount * costNav,
      marketValue: amount * (favorite.currentNav ?? costNav),
      currentNav: favorite.currentNav ?? 0.0,
      accumulatedNav: favorite.currentNav ?? 0.0, // 简化处理
      holdingStartDate: now,
      lastUpdatedDate: now,
      dividendReinvestment: false, // 默认不分红再投资
      status: HoldingStatus.active,
    );
  }

  /// 批量转换自选基金列表
  ///
  /// [favorites] 自选基金列表
  /// [selectedCodes] 选中的基金代码（为空则转换全部）
  /// [defaultAmount] 默认持有份额
  /// [estimateCost] 是否估算成本
  List<PortfolioHolding> batchConvertFavorites(
    List<FundFavorite> favorites, {
    List<String>? selectedCodes,
    double? defaultAmount,
    bool estimateCost = true,
  }) {
    AppLogger.info(
        'Batch converting ${favorites.length} favorites to holdings', _tag);

    final targetFavorites = selectedCodes != null
        ? favorites.where((f) => selectedCodes.contains(f.fundCode)).toList()
        : favorites;

    if (targetFavorites.isEmpty) {
      AppLogger.warn('No favorites to convert', _tag);
      return [];
    }

    final holdings = targetFavorites.map((favorite) {
      return convertFavoriteToHolding(
        favorite,
        defaultAmount: defaultAmount,
        estimateCost: estimateCost,
      );
    }).toList();

    AppLogger.info(
        'Successfully converted ${holdings.length} favorites to holdings',
        _tag);
    return holdings;
  }

  /// 估算建议的持有份额
  ///
  /// 基于基金类型和当前净值给出合理的持有建议
  double estimateSuggestedAmount(FundFavorite favorite) {
    final currentNav = favorite.currentNav;
    if (currentNav == null || currentNav <= 0) {
      return 1000.0; // 默认1000份
    }

    // 根据基金类型建议不同的投资金额
    double suggestedInvestment;
    switch (favorite.fundType.toLowerCase()) {
      case '货币型':
        suggestedInvestment = 10000.0; // 货币基金建议投资1万元
        break;
      case '债券型':
        suggestedInvestment = 5000.0; // 债券基金建议投资5千元
        break;
      case '股票型':
      case '混合型':
        suggestedInvestment = 3000.0; // 股票/混合基金建议投资3千元
        break;
      case '指数型':
        suggestedInvestment = 2000.0; // 指数基金建议投资2千元
        break;
      default:
        suggestedInvestment = 2000.0; // 其他类型默认2千元
    }

    return suggestedInvestment / currentNav;
  }

  /// 验证转换结果的合理性
  ///
  /// [holding] 转换后的持仓数据
  /// 返回验证结果和错误信息
  ({bool isValid, List<String> errors}) validateHolding(
      PortfolioHolding holding) {
    final errors = <String>[];

    // 验证基金代码
    if (holding.fundCode.isEmpty) {
      errors.add('基金代码不能为空');
    }

    // 验证持有份额
    if (holding.holdingAmount <= 0) {
      errors.add('持有份额必须大于0');
    }

    // 验证成本净值
    if (holding.costNav <= 0) {
      errors.add('成本净值必须大于0');
    }

    // 验证当前净值
    if (holding.currentNav < 0) {
      errors.add('当前净值不能为负数');
    }

    // 验证日期逻辑
    if (holding.lastUpdatedDate.isBefore(holding.holdingStartDate)) {
      errors.add('更新日期不能早于持有开始日期');
    }

    return (
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  /// 生成持仓转换摘要
  ///
  /// 用于用户确认转换操作的摘要信息
  String generateConversionSummary(List<PortfolioHolding> holdings) {
    if (holdings.isEmpty) {
      return '没有需要转换的基金';
    }

    final totalCost = holdings.fold<double>(0, (sum, h) => sum + h.costValue);
    final totalShares =
        holdings.fold<double>(0, (sum, h) => sum + h.holdingAmount);

    final fundTypes = <String, int>{};
    for (final holding in holdings) {
      fundTypes[holding.fundType] = (fundTypes[holding.fundType] ?? 0) + 1;
    }

    final buffer = StringBuffer();
    buffer.writeln('📊 持仓转换摘要');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('基金数量: ${holdings.length} 只');
    buffer.writeln('总份额: ${totalShares.toStringAsFixed(0)} 份');
    buffer.writeln('总成本: ¥${totalCost.toStringAsFixed(2)}');
    buffer.writeln('');

    buffer.writeln('基金类型分布:');
    fundTypes.forEach((type, count) {
      buffer.writeln('  • $type: $count 只');
    });

    buffer.writeln('');
    buffer.writeln('⚠️  请确认以上信息无误后确认转换');

    return buffer.toString();
  }
}
