import '../features/portfolio/domain/entities/portfolio_holding.dart';
import '../features/fund/domain/entities/fund_ranking.dart';

/// API Gateway扩展 - 简化版本
///
/// 提供API服务的基础扩展功能

/// 投资组合收益摘要
class PortfolioProfitSummary {
  final double totalInvestment;
  final double currentValue;
  final double totalProfit;
  final double totalProfitRate;
  final double dailyProfit;
  final double dailyProfitRate;
  final List<HoldingProfit> holdings;
  final DateTime calculatedAt;

  const PortfolioProfitSummary({
    required this.totalInvestment,
    required this.currentValue,
    required this.totalProfit,
    required this.totalProfitRate,
    required this.dailyProfit,
    required this.dailyProfitRate,
    required this.holdings,
    required this.calculatedAt,
  });

  factory PortfolioProfitSummary.empty() {
    return PortfolioProfitSummary(
      totalInvestment: 0.0,
      currentValue: 0.0,
      totalProfit: 0.0,
      totalProfitRate: 0.0,
      dailyProfit: 0.0,
      dailyProfitRate: 0.0,
      holdings: [],
      calculatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_investment': totalInvestment,
      'current_value': currentValue,
      'total_profit': totalProfit,
      'total_profit_rate': totalProfitRate,
      'daily_profit': dailyProfit,
      'daily_profit_rate': dailyProfitRate,
      'holdings': holdings.map((h) => h.toJson()).toList(),
      'calculated_at': calculatedAt.toIso8601String(),
    };
  }
}

/// 持仓收益
class HoldingProfit {
  final String fundCode;
  final String fundName;
  final double shares;
  final double costPrice;
  final double currentPrice;
  final double investment;
  final double currentValue;
  final double profit;
  final double profitRate;

  const HoldingProfit({
    required this.fundCode,
    required this.fundName,
    required this.shares,
    required this.costPrice,
    required this.currentPrice,
    required this.investment,
    required this.currentValue,
    required this.profit,
    required this.profitRate,
  });

  Map<String, dynamic> toJson() {
    return {
      'fund_code': fundCode,
      'fund_name': fundName,
      'shares': shares,
      'cost_price': costPrice,
      'current_price': currentPrice,
      'investment': investment,
      'current_value': currentValue,
      'profit': profit,
      'profit_rate': profitRate,
    };
  }
}

/// 投资组合分析报告
class PortfolioAnalysisReport {
  final double totalValue;
  final int holdingsCount;
  final Map<String, double> typeDistribution;
  final Map<String, double> companyDistribution;
  final PortfolioProfitSummary profitSummary;
  final Map<String, dynamic> riskAnalysis;
  final List<String> recommendations;
  final DateTime generatedAt;

  const PortfolioAnalysisReport({
    required this.totalValue,
    required this.holdingsCount,
    required this.typeDistribution,
    required this.companyDistribution,
    required this.profitSummary,
    required this.riskAnalysis,
    required this.recommendations,
    required this.generatedAt,
  });
}

/// 投资组合风险分析
class PortfolioRiskAnalysis {
  final double totalInvestment;
  final double highRiskAmount;
  final double mediumRiskAmount;
  final double lowRiskAmount;
  final double highRiskPercentage;
  final double mediumRiskPercentage;
  final double lowRiskPercentage;
  final int riskScore;

  const PortfolioRiskAnalysis({
    required this.totalInvestment,
    required this.highRiskAmount,
    required this.mediumRiskAmount,
    required this.lowRiskAmount,
    required this.highRiskPercentage,
    required this.mediumRiskPercentage,
    required this.lowRiskPercentage,
    required this.riskScore,
  });
}

/// FundRanking扩展
extension FundRankingExtension on FundRanking {
  /// 安全获取扩展字段（如果将来有额外字段的话）
  T? safeGet<T>(String key, Map<String, dynamic>? extraData) {
    if (extraData != null && extraData.containsKey(key)) {
      final value = extraData[key];
      if (value is T) return value;
      // 尝试类型转换
      if (value != null) {
        if (T == double && value is num) {
          return value.toDouble() as T;
        }
        if (T == String) {
          return value.toString() as T;
        }
      }
    }
    return null;
  }

  /// 扩展字段访问器
  Map<String, dynamic> getExtendedFields(Map<String, dynamic>? extraData) {
    return {
      'fundCode': fundCode,
      'fundName': fundName,
      'fundType': fundType,
      'nav': unitNav,
      'dailyReturn': dailyReturn,
      'oneYearReturn': return1Y,
      'threeYearReturn': return3Y,
      'fundCompany': company,
      'fundManager': safeGet<String>('fundManager', extraData) ?? '',
      'managementFee': safeGet<double>('managementFee', extraData) ?? 0.0,
      'fundScale': safeGet<double>('fundScale', extraData) ?? 0.0,
      'navDate': safeGet<String>('navDate', extraData) ?? '',
      'weeklyReturn': return1W,
      'monthlyReturn': return1M,
      'yearlyReturn': returnYTD,
      'minInvestmentAmount':
          safeGet<double>('minInvestmentAmount', extraData) ?? 0.0,
      'status': safeGet<String>('status', extraData) ?? '正常',
      'establishmentDate':
          safeGet<String>('establishmentDate', extraData) ?? '',
      'feeRate': safeGet<double>('feeRate', extraData) ?? 0.0,
    };
  }
}

/// PortfolioHolding扩展
extension PortfolioHoldingExtension on PortfolioHolding {
  /// 扩展字段访问器
  Map<String, dynamic> getExtendedFields() {
    return {
      'fundCode': fundCode,
      'fundName': fundName,
      'fundType': fundType,
      'holdingAmount': holdingAmount,
      'costNav': costNav,
      'costValue': costValue,
      'marketValue': marketValue,
      'currentNav': currentNav,
      'accumulatedNav': accumulatedNav,
      'holdingStartDate': holdingStartDate.toIso8601String(),
      'lastUpdatedDate': lastUpdatedDate.toIso8601String(),
      'dividendReinvestment': dividendReinvestment,
      'status': status.toString(),
      // 扩展字段（兼容性）
      'shares': holdingAmount,
      'costPrice': costNav,
      'currentPrice': currentNav,
      'fundCompany': '', // PortfolioHolding 中没有此字段
      'riskLevel': '', // PortfolioHolding 中没有此字段
      'purchasedAt': holdingStartDate.toIso8601String(),
      'updatedAt': lastUpdatedDate.toIso8601String(),
    };
  }
}
