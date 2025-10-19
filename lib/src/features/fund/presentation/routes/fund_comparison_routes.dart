import 'package:flutter/material.dart';
import '../../domain/entities/multi_dimensional_comparison_criteria.dart';
import '../../domain/entities/fund_ranking.dart';
import '../pages/fund_comparison_page.dart';

/// 基金对比路由配置
class FundComparisonRoutes {
  static const String comparisonPage = '/fund/comparison';

  /// 跳转到基金对比页面
  static Future<void> navigateToComparison(
    BuildContext context, {
    required List<FundRanking> availableFunds,
    MultiDimensionalComparisonCriteria? initialCriteria,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FundComparisonPage(
          availableFunds: availableFunds,
          initialCriteria: initialCriteria,
        ),
        settings: const RouteSettings(name: comparisonPage),
      ),
    );
  }

  /// 跳转到基金对比页面（替换当前页面）
  static Future<void> navigateToComparisonReplace(
    BuildContext context, {
    required List<FundRanking> availableFunds,
    MultiDimensionalComparisonCriteria? initialCriteria,
  }) {
    return Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => FundComparisonPage(
          availableFunds: availableFunds,
          initialCriteria: initialCriteria,
        ),
        settings: const RouteSettings(name: comparisonPage),
      ),
    );
  }

  /// 跳转到基金对比页面（清除所有历史记录）
  static Future<void> navigateToComparisonClearStack(
    BuildContext context, {
    required List<FundRanking> availableFunds,
    MultiDimensionalComparisonCriteria? initialCriteria,
  }) {
    return Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => FundComparisonPage(
          availableFunds: availableFunds,
          initialCriteria: initialCriteria,
        ),
        settings: const RouteSettings(name: comparisonPage),
      ),
      (route) => false,
    );
  }
}

/// 基金对比页面参数
class FundComparisonPageParams {
  /// 可选基金列表
  final List<FundRanking> availableFunds;

  /// 初始对比条件
  final MultiDimensionalComparisonCriteria? initialCriteria;

  /// 页面标题
  final String? title;

  /// 是否显示返回按钮
  final bool showBackButton;

  const FundComparisonPageParams({
    required this.availableFunds,
    this.initialCriteria,
    this.title,
    this.showBackButton = true,
  });
}
