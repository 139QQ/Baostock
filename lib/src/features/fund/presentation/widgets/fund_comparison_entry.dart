import 'package:flutter/material.dart';
import '../../domain/entities/multi_dimensional_comparison_criteria.dart';
import '../../domain/entities/fund_ranking.dart';
import '../routes/fund_comparison_routes.dart';

/// 基金对比入口组件
///
/// 提供快速启动基金对比功能的按钮或卡片
class FundComparisonEntry extends StatelessWidget {
  /// 可选基金列表
  final List<FundRanking> availableFunds;

  /// 预选基金代码
  final List<String>? preselectedFunds;

  /// 入口类型
  final FundComparisonEntryType entryType;

  /// 点击回调
  final VoidCallback? onTap;

  /// 自定义标题
  final String? title;

  /// 自定义描述
  final String? description;

  /// 自定义图标
  final IconData? icon;

  const FundComparisonEntry({
    super.key,
    required this.availableFunds,
    this.preselectedFunds,
    this.entryType = FundComparisonEntryType.button,
    this.onTap,
    this.title,
    this.description,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    switch (entryType) {
      case FundComparisonEntryType.button:
        return _buildButtonEntry(context);
      case FundComparisonEntryType.card:
        return _buildCardEntry(context);
      case FundComparisonEntryType.floatingActionButton:
        return _buildFloatingActionEntry(context);
      case FundComparisonEntryType.listTile:
        return _buildListTileEntry(context);
      default:
        return _buildButtonEntry(context);
    }
  }

  Widget _buildButtonEntry(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _navigateToComparison(context),
      icon: Icon(icon ?? Icons.compare_arrows),
      label: Text(title ?? '基金对比'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildCardEntry(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToComparison(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon ?? Icons.compare_arrows,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title ?? '基金多维对比',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        if (description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            description!,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
              if (preselectedFunds != null && preselectedFunds!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: Colors.green.shade600,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '已选择 ${preselectedFunds!.length} 只基金',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionEntry(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _navigateToComparison(context),
      icon: Icon(icon ?? Icons.compare_arrows),
      label: Text(title ?? '对比'),
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
    );
  }

  Widget _buildListTileEntry(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
        child: Icon(
          icon ?? Icons.compare_arrows,
          color: Theme.of(context).primaryColor,
        ),
      ),
      title: Text(title ?? '基金对比'),
      subtitle: description != null ? Text(description!) : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _navigateToComparison(context),
    );
  }

  void _navigateToComparison(BuildContext context) {
    // 创建初始对比条件
    MultiDimensionalComparisonCriteria? initialCriteria;

    if (preselectedFunds != null && preselectedFunds!.isNotEmpty) {
      initialCriteria = MultiDimensionalComparisonCriteria(
        fundCodes: preselectedFunds!,
        periods: const [
          RankingPeriod.oneMonth,
          RankingPeriod.threeMonths,
          RankingPeriod.sixMonths,
        ],
        metric: ComparisonMetric.totalReturn,
        includeStatistics: true,
        sortBy: ComparisonSortBy.fundCode,
      );
    }

    // 调用点击回调
    onTap?.call();

    // 导航到对比页面
    FundComparisonRoutes.navigateToComparison(
      context,
      availableFunds: availableFunds,
      initialCriteria: initialCriteria,
    );
  }
}

/// 基金对比入口类型
enum FundComparisonEntryType {
  /// 按钮
  button,

  /// 卡片
  card,

  /// 浮动操作按钮
  floatingActionButton,

  /// 列表项
  listTile,
}

/// 快速创建对比入口的工厂方法
class FundComparisonEntryFactory {
  /// 创建主要对比按钮
  static Widget createPrimaryButton({
    required List<FundRanking> availableFunds,
    List<String>? preselectedFunds,
    VoidCallback? onTap,
  }) {
    return FundComparisonEntry(
      availableFunds: availableFunds,
      preselectedFunds: preselectedFunds,
      entryType: FundComparisonEntryType.button,
      onTap: onTap,
      title: '开始对比',
      icon: Icons.compare,
    );
  }

  /// 创建功能卡片
  static Widget createFeatureCard({
    required List<FundRanking> availableFunds,
    List<String>? preselectedFunds,
    VoidCallback? onTap,
  }) {
    return FundComparisonEntry(
      availableFunds: availableFunds,
      preselectedFunds: preselectedFunds,
      entryType: FundComparisonEntryType.card,
      onTap: onTap,
      title: '基金多维对比分析',
      description: '深度分析基金表现，发现投资机会',
      icon: Icons.analytics,
    );
  }

  /// 创建浮动操作按钮
  static Widget createFloatingAction({
    required List<FundRanking> availableFunds,
    VoidCallback? onTap,
  }) {
    return FundComparisonEntry(
      availableFunds: availableFunds,
      entryType: FundComparisonEntryType.floatingActionButton,
      onTap: onTap,
      title: '对比',
      icon: Icons.compare_arrows,
    );
  }

  /// 创建菜单列表项
  static Widget createMenuListTile({
    required List<FundRanking> availableFunds,
    VoidCallback? onTap,
  }) {
    return FundComparisonEntry(
      availableFunds: availableFunds,
      entryType: FundComparisonEntryType.listTile,
      onTap: onTap,
      title: '基金对比',
      description: '多只基金综合对比分析',
      icon: Icons.compare,
    );
  }
}
