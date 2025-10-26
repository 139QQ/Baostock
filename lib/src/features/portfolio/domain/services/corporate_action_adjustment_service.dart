import '../entities/fund_corporate_action.dart';
import '../services/portfolio_profit_calculation_engine.dart';

/// 公司行为调整服务
///
/// 处理基金分红、拆分、合并等公司行为对收益计算的影响
class CorporateActionAdjustmentService {
  /// 处理分红调整
  double adjustForDividend({
    required double baseReturn,
    required double dividendRate,
  }) {
    return baseReturn + dividendRate;
  }

  /// 处理拆分调整
  double adjustForSplit({
    required double baseReturn,
    required double splitRatio,
    required bool isForwardSplit,
  }) {
    if (isForwardSplit) {
      return baseReturn * (1 - splitRatio);
    } else {
      return baseReturn * (1 + splitRatio);
    }
  }

  /// 处理合并调整
  double adjustForMerger({
    required double weightedReturn1,
    required double weightedReturn2,
    required double weight1,
    required double weight2,
  }) {
    final totalWeight = weight1 + weight2;
    if (totalWeight == 0) return 0.0;
    return (weightedReturn1 * weight1 + weightedReturn2 * weight2) /
        totalWeight;
  }

  /// 处理所有公司行为
  CorporateActionResult processCorporateActions({
    required Map<DateTime, double> navHistory,
    required List<FundCorporateAction> corporateActions,
  }) {
    var adjustedHistory = Map<DateTime, double>.from(navHistory);
    var totalAdjustmentFactor = 1.0;
    final processedActions = <FundCorporateAction>[];

    for (final action in corporateActions) {
      if (action.isDividend && action.dividendPerUnit != null) {
        // 处理分红
        totalAdjustmentFactor *= (1 + action.dividendPerUnit! / 100);
        processedActions.add(action);
      } else if (action.isSplit && action.splitRatio != null) {
        // 处理拆分
        totalAdjustmentFactor *= action.splitRatio!;
        processedActions.add(action);
      }
    }

    // 应用调整因子
    for (final date in adjustedHistory.keys) {
      adjustedHistory[date] = adjustedHistory[date]! * totalAdjustmentFactor;
    }

    return CorporateActionResult(
      adjustedNavHistory: adjustedHistory,
      processedActions: processedActions,
      adjustmentFactor: totalAdjustmentFactor,
      description: 'Processed ${processedActions.length} corporate actions',
    );
  }
}
