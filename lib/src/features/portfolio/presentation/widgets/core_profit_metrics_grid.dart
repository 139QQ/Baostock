import 'package:flutter/material.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/entities/portfolio_profit_metrics.dart';

/// 核心收益指标卡片网格组件
///
/// 按照文档规范实现3x2网格布局的收益指标展示：
/// - 总收益率 + 胜率对比
/// - 年化收益率 + 排名
/// - 最大回撤 + 回撤期数
/// - 夏普比率 + 风险等级
/// - 波动率 + 同类排名
/// - Beta值 + Alpha值
class CoreProfitMetricsGrid extends StatelessWidget {
  final PortfolioProfitMetrics? metrics;
  final bool isLoading;
  final VoidCallback? onRefresh;

  const CoreProfitMetricsGrid({
    super.key,
    this.metrics,
    this.isLoading = false,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    // 使用响应式布局
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount =
            _getResponsiveCrossAxisCount(constraints.maxWidth);
        final aspectRatio = _getResponsiveAspectRatio(constraints.maxWidth);
        final spacing = _getResponsiveSpacing(constraints.maxWidth);

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: aspectRatio,
          children: [
            // 第一行：总收益率、年化收益率、最大回撤
            _buildMetricCard(
              context,
              title: '总收益率',
              value: metrics?.totalReturnRate ?? 0.0,
              subtitle: '相比基准',
              subtitleValue: metrics?.excessReturnRate ?? 0.0,
              format: MetricFormat.percentage,
              icon: Icons.trending_up,
              color: _getProfitColor(metrics?.totalReturnRate ?? 0.0),
              isLoading: isLoading,
              isLarge: true,
            ),
            _buildMetricCard(
              context,
              title: '年化收益率',
              value: metrics?.annualizedReturn ?? 0.0,
              subtitle: '同类排名',
              subtitleValue: (metrics?.fundRanking ?? 0).toDouble(),
              format: MetricFormat.percentage,
              icon: Icons.calendar_today,
              color: _getProfitColor(metrics?.annualizedReturn ?? 0.0),
              isLoading: isLoading,
              isLarge: true,
            ),
            _buildMetricCard(
              context,
              title: '最大回撤',
              value: metrics?.maxDrawdown ?? 0.0,
              subtitle: '回撤期数',
              subtitleValue: (metrics?.maxDrawdownDuration ?? 0).toDouble(),
              format: MetricFormat.percentage,
              icon: Icons.trending_down,
              color: Colors.red,
              isLoading: isLoading,
              isLarge: true,
              isNegative: true,
            ),

            // 第二行：夏普比率、波动率、Beta值
            _buildMetricCard(
              context,
              title: '夏普比率',
              value: metrics?.sharpeRatio ?? 0.0,
              subtitle: '风险等级',
              subtitleValue: _getRiskLevelValue(metrics?.riskLevel),
              format: MetricFormat.decimal,
              icon: Icons.speed,
              color: _getSharpeColor(metrics?.sharpeRatio ?? 0.0),
              isLoading: isLoading,
              isLarge: true,
            ),
            _buildMetricCard(
              context,
              title: '波动率',
              value: metrics?.volatility ?? 0.0,
              subtitle: '同类排名',
              subtitleValue: (metrics?.fundRanking ?? 0).toDouble(),
              format: MetricFormat.percentage,
              icon: Icons.show_chart,
              color: Colors.orange,
              isLoading: isLoading,
              isLarge: true,
            ),
            _buildMetricCard(
              context,
              title: 'Beta值',
              value: metrics?.beta ?? 0.0,
              subtitle: 'Alpha值',
              subtitleValue: metrics?.jensenAlpha ?? 0.0,
              format: MetricFormat.decimal,
              icon: Icons.compare_arrows,
              color: Colors.purple,
              isLoading: isLoading,
              isLarge: true,
            ),
          ],
        );
      },
    );
  }

  /// 构建指标卡片
  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required double value,
    String? subtitle,
    double? subtitleValue,
    required MetricFormat format,
    required IconData icon,
    required Color color,
    required bool isLoading,
    bool isNegative = false,
    bool isLarge = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isLarge ? 16.0 : 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 标题和图标
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: isLarge ? 24 : 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: isLarge ? 16 : 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onRefresh != null)
                  IconButton(
                    onPressed: onRefresh,
                    icon: Icon(
                      Icons.refresh,
                      size: isLarge ? 18 : 16,
                      color: Colors.grey[600],
                    ),
                    tooltip: '刷新数据',
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: isLarge ? 32 : 28,
                      minHeight: isLarge ? 32 : 28,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // 主要数值
            if (isLoading)
              Expanded(
                child: Center(
                  child: Container(
                    width: 20,
                    height: 20,
                    padding: const EdgeInsets.all(2),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  ),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 主要指标值
                  _buildFormattedValue(
                    value,
                    format,
                    color,
                    isNegative,
                    isLarge,
                  ),
                  const SizedBox(height: 4),

                  // 副标题
                  if (subtitle != null && subtitleValue != null) ...[
                    Row(
                      children: [
                        Text(
                          '$subtitle: ',
                          style: TextStyle(
                            fontSize: isLarge ? 12 : 10,
                            color: Colors.grey[600],
                          ),
                        ),
                        Expanded(
                          child: _buildFormattedSubtitle(
                            subtitleValue,
                            subtitle,
                            isLarge,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// 构建格式化的数值显示
  Widget _buildFormattedValue(
    double value,
    MetricFormat format,
    Color color,
    bool isNegative,
    bool isLarge,
  ) {
    String formattedValue;
    TextStyle textStyle;

    switch (format) {
      case MetricFormat.percentage:
        formattedValue =
            '${isNegative ? '-' : '+'}${(value * 100).toStringAsFixed(2)}%';
        break;
      case MetricFormat.decimal:
        formattedValue = value.toStringAsFixed(2);
        break;
      case MetricFormat.currency:
        formattedValue = '¥${value.abs().toStringAsFixed(2)}';
        break;
    }

    textStyle = TextStyle(
      fontSize: isLarge ? 24 : 20,
      fontWeight: FontWeight.bold,
      color: color,
    );

    return Text(formattedValue, style: textStyle);
  }

  /// 构建格式化的副标题显示
  Widget _buildFormattedSubtitle(
    double? value,
    String label,
    bool isLarge,
  ) {
    String formattedValue;

    // 根据标签类型格式化
    if (label.contains('排名')) {
      formattedValue =
          (value != null && value > 0) ? '${value.toInt()}名' : '暂无排名';
    } else if (label.contains('期')) {
      formattedValue = value != null ? '${value.toInt()}期' : '0期';
    } else if (label.contains('等级')) {
      formattedValue = _getRiskLevel(value ?? 0.0);
    } else {
      formattedValue = value?.toStringAsFixed(2) ?? '0.00';
    }

    return Text(
      formattedValue,
      style: TextStyle(
        fontSize: isLarge ? 12 : 10,
        fontWeight: FontWeight.w600,
        color: Colors.grey[700],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// 获取风险等级文本
  String _getRiskLevel(double value) {
    if (value <= 1) return '低风险';
    if (value <= 2) return '中风险';
    if (value <= 3) return '高风险';
    return '极高风险';
  }

  /// 获取风险等级数值
  double _getRiskLevelValue(RiskLevel? riskLevel) {
    switch (riskLevel) {
      case RiskLevel.low:
        return 1.0;
      case RiskLevel.medium:
        return 2.0;
      case RiskLevel.high:
        return 3.0;
      case RiskLevel.veryHigh:
        return 4.0;
      case null:
        return 0.0;
    }
  }

  /// 获取收益颜色
  Color _getProfitColor(double value) {
    if (value > 0) {
      return Colors.green[600]!;
    } else if (value < 0) {
      return Colors.red[600]!;
    }
    return Colors.grey[600]!;
  }

  /// 获取夏普比率颜色
  Color _getSharpeColor(double value) {
    if (value >= 2.0) {
      return Colors.green[600]!;
    } else if (value >= 1.0) {
      return Colors.orange[600]!;
    } else if (value >= 0.5) {
      return Colors.deepOrange[600]!;
    }
    return Colors.red[600]!;
  }

  /// 获取响应式列数
  int _getResponsiveCrossAxisCount(double maxWidth) {
    if (maxWidth > 1200) {
      return 3; // 桌面端：3列
    } else if (maxWidth > 800) {
      return 2; // 平板端：2列
    } else {
      return 2; // 手机端：2列
    }
  }

  /// 获取响应式宽高比
  double _getResponsiveAspectRatio(double maxWidth) {
    if (maxWidth > 1200) {
      return 1.2; // 桌面端
    } else if (maxWidth > 800) {
      return 1.1; // 平板端
    } else {
      return 1.0; // 手机端
    }
  }

  /// 获取响应式间距
  double _getResponsiveSpacing(double maxWidth) {
    if (maxWidth > 1200) {
      return 16.0; // 桌面端
    } else if (maxWidth > 800) {
      return 12.0; // 平板端
    } else {
      return 8.0; // 手机端
    }
  }
}

/// 指标格式化枚举
enum MetricFormat {
  percentage,
  decimal,
  currency,
}
