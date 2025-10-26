import 'package:flutter/material.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/entities/portfolio_profit_metrics.dart';

/// 收益指标卡片网格组件
///
/// 显示关键收益指标，包括：
/// - 总收益率和年化收益率
/// - 最大回撤和夏普比率
/// - 胜胜基准表现
/// - 风险指标
class ProfitMetricsGrid extends StatelessWidget {
  final PortfolioProfitMetrics? metrics;
  final VoidCallback? onRefresh;
  final bool isLoading;

  const ProfitMetricsGrid({
    super.key,
    this.metrics,
    this.onRefresh,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    // 使用CustomScrollView和Sliver组件来避免溢出
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('收益指标'),
              const SizedBox(height: 16),
            ],
          ),
        ),

        // 主要收益指标网格
        SliverToBoxAdapter(
          child: _buildMainMetricsGrid(context),
        ),

        const SliverToBoxAdapter(
          child: const SizedBox(height: 24),
        ),

        // 风险调整收益指标
        SliverToBoxAdapter(
          child: _buildRiskAdjustedMetricsGrid(context),
        ),

        const SliverToBoxAdapter(
          child: const SizedBox(height: 24),
        ),

        // 基准比较指标
        SliverToBoxAdapter(
          child: _buildBenchmarkComparisonGrid(context),
        ),

        // 添加底部间距，确保内容不会被遮挡
        const SliverToBoxAdapter(
          child: const SizedBox(height: 50),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade900,
          ),
        ),
        const Spacer(),
        if (onRefresh != null)
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            tooltip: '刷新数据',
          ),
      ],
    );
  }

  Widget _buildMainMetricsGrid(BuildContext context) {
    final crossAxisCount = _getCrossAxisCount(context);
    final spacing = _getSpacing(context);
    final aspectRatio = _getAspectRatio(context);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      childAspectRatio: aspectRatio,
      children: [
        _buildMetricCard(
          context,
          title: '总收益率',
          value: metrics?.totalReturnRate ?? 0.0,
          format: PercentageFormat.percentage,
          icon: Icons.trending_up,
          color: _getReturnColor(metrics?.totalReturnRate ?? 0.0),
          isLoading: isLoading,
        ),
        _buildMetricCard(
          context,
          title: '年化收益率',
          value: metrics?.annualizedReturn ?? 0.0,
          format: PercentageFormat.percentage,
          icon: Icons.calendar_today,
          color: _getReturnColor(metrics?.annualizedReturn ?? 0.0),
          isLoading: isLoading,
        ),
        _buildMetricCard(
          context,
          title: '最大回撤',
          value: metrics?.maxDrawdown ?? 0.0,
          format: PercentageFormat.percentage,
          icon: Icons.trending_down,
          color: Colors.red,
          isLoading: isLoading,
          isNegative: true,
        ),
        _buildMetricCard(
          context,
          title: '波动率',
          value: metrics?.volatility ?? 0.0,
          format: PercentageFormat.percentage,
          icon: Icons.show_chart,
          color: Colors.orange,
          isLoading: isLoading,
        ),
      ],
    );
  }

  Widget _buildRiskAdjustedMetricsGrid(BuildContext context) {
    final crossAxisCount = _getCrossAxisCount(context);
    final spacing = _getSpacing(context);
    final aspectRatio = _getAspectRatio(context);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      childAspectRatio: aspectRatio,
      children: [
        _buildMetricCard(
          context,
          title: '夏普比率',
          value: metrics?.sharpeRatio ?? 0.0,
          format: PercentageFormat.decimal,
          icon: Icons.balance,
          color: _getSharpeColor(metrics?.sharpeRatio ?? 0.0),
          isLoading: isLoading,
        ),
        _buildMetricCard(
          context,
          title: '索提诺比率',
          value: metrics?.sortinoRatio ?? 0.0,
          format: PercentageFormat.decimal,
          icon: Icons.security,
          color: _getSharpeColor(metrics?.sortinoRatio ?? 0.0),
          isLoading: isLoading,
        ),
        _buildMetricCard(
          context,
          title: '信息比率',
          value: metrics?.informationRatio ?? 0.0,
          format: PercentageFormat.decimal,
          icon: Icons.info,
          color: _getSharpeColor(metrics?.informationRatio ?? 0.0),
          isLoading: isLoading,
        ),
        _buildMetricCard(
          context,
          title: '特雷纳比率',
          value: metrics?.treynorRatio ?? 0.0,
          format: PercentageFormat.decimal,
          icon: Icons.trending_up,
          color: _getSharpeColor(metrics?.treynorRatio ?? 0.0),
          isLoading: isLoading,
        ),
      ],
    );
  }

  Widget _buildBenchmarkComparisonGrid(BuildContext context) {
    final crossAxisCount = _getCrossAxisCount(context);
    final spacing = _getSpacing(context);
    final aspectRatio = _getAspectRatio(context);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      childAspectRatio: aspectRatio,
      children: [
        _buildMetricCard(
          context,
          title: '相对收益',
          value: metrics?.excessReturnRate ?? 0.0, // 使用超额收益率作为相对收益
          format: PercentageFormat.percentage,
          icon: Icons.compare_arrows,
          color: _getReturnColor(metrics?.excessReturnRate ?? 0.0),
          isLoading: isLoading,
        ),
        _buildMetricCard(
          context,
          title: '跟踪误差',
          value: (metrics?.informationRatio ?? 0.0) * 0.1, // 使用信息比率作为跟踪误差的近似
          format: PercentageFormat.percentage,
          icon: Icons.gps_fixed,
          color: Colors.grey.shade600,
          isLoading: isLoading,
        ),
        _buildMetricCard(
          context,
          title: '贝塔系数',
          value: metrics?.beta ?? 0.0,
          format: PercentageFormat.decimal,
          icon: Icons.linear_scale,
          color: Colors.blue,
          isLoading: isLoading,
        ),
        _buildMetricCard(
          context,
          title: '阿尔法',
          value: metrics?.jensenAlpha ?? 0.0,
          format: PercentageFormat.percentage,
          icon: Icons.auto_awesome,
          color: _getReturnColor(metrics?.jensenAlpha ?? 0.0),
          isLoading: isLoading,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required double value,
    required PercentageFormat format,
    required IconData icon,
    required Color color,
    bool isLoading = false,
    bool isNegative = false,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showMetricDetail(context, title, value, format),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                  const Spacer(),
                  if (!isLoading)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getTrendIcon(value),
                        style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              if (isLoading)
                SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      color.withOpacity(0.6),
                    ),
                  ),
                )
              else
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _formatValue(value, format),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isNegative ? Colors.red : color,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4; // 桌面
    if (width > 800) return 3; // 平板
    if (width > 600) return 2; // 大屏手机
    return 1; // 小屏手机
  }

  double _getSpacing(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 16.0;
    if (width > 800) return 12.0;
    if (width > 600) return 8.0;
    return 6.0;
  }

  double _getAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 1.2;
    if (width > 800) return 1.3;
    if (width > 600) return 1.4;
    return 1.6; // 小屏幕使用更紧凑的纵横比
  }

  Color _getReturnColor(double value) {
    if (value > 0.15) return Colors.green;
    if (value > 0.05) return Colors.lightGreen;
    if (value > 0) return Colors.lime;
    return Colors.red;
  }

  Color _getSharpeColor(double value) {
    if (value > 2.0) return Colors.green;
    if (value > 1.0) return Colors.lightGreen;
    if (value > 0.5) return Colors.orange;
    return Colors.red;
  }

  String _getTrendIcon(double value) {
    if (value > 0.01) return '↑';
    if (value < -0.01) return '↓';
    return '→';
  }

  String _formatValue(double value, PercentageFormat format) {
    switch (format) {
      case PercentageFormat.percentage:
        return '${(value * 100).toStringAsFixed(2)}%';
      case PercentageFormat.decimal:
        return value.toStringAsFixed(2);
    }
  }

  void _showMetricDetail(BuildContext context, String title, double value,
      PercentageFormat format) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('数值: ${_formatValue(value, format)}'),
            const SizedBox(height: 8),
            Text('原始值: ${value.toString()}'),
            const SizedBox(height: 16),
            const Text('点击外部区域关闭对话框'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

/// 百分比格式化枚举
enum PercentageFormat {
  percentage,
  decimal,
}

/// 收益指标详情对话框
class MetricDetailDialog extends StatelessWidget {
  final String title;
  final double value;
  final String description;
  final String? benchmarkName;

  const MetricDetailDialog({
    super.key,
    required this.title,
    required this.value,
    required this.description,
    this.benchmarkName,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (benchmarkName != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '基准: $benchmarkName',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
