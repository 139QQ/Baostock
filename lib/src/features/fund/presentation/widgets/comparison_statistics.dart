import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../domain/entities/comparison_result.dart';
import '../../domain/entities/fund_ranking.dart';

/// 对比统计信息组件
///
/// 展示基金对比的各种统计分析和图表
class ComparisonStatistics extends StatefulWidget {
  /// 对比结果数据
  final ComparisonResult comparisonResult;

  /// 图表类型
  final StatisticsChartType chartType;

  const ComparisonStatistics({
    super.key,
    required this.comparisonResult,
    this.chartType = StatisticsChartType.bar,
  });

  @override
  State<ComparisonStatistics> createState() => _ComparisonStatisticsState();
}

class _ComparisonStatisticsState extends State<ComparisonStatistics>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.comparisonResult.hasError ||
        widget.comparisonResult.fundData.isEmpty) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题区域
              Row(
                children: [
                  const Icon(
                    Icons.analytics,
                    color: Color(0xFF1E40AF),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '统计分析',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  // 图表类型切换
                  PopupMenuButton<StatisticsChartType>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (type) {
                      setState(() {
                        // 这里可以更新图表类型
                      });
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: StatisticsChartType.bar,
                        child: Row(
                          children: [
                            Icon(Icons.bar_chart),
                            SizedBox(width: 8),
                            Text('柱状图'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: StatisticsChartType.line,
                        child: Row(
                          children: [
                            Icon(Icons.line_chart),
                            SizedBox(width: 8),
                            Text('折线图'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: StatisticsChartType.pie,
                        child: Row(
                          children: [
                            Icon(Icons.pie_chart),
                            SizedBox(width: 8),
                            Text('饼图'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 统计指标卡片
              _buildStatisticsCards(),
              const SizedBox(height: 16),

              // 图表区域
              _buildChart(),
              const SizedBox(height: 16),

              // 详细分析
              _buildDetailedAnalysis(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsCards() {
    final stats = widget.comparisonResult.statistics;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildStatCard(
          '平均收益率',
          '${(stats.averageReturn * 100).toStringAsFixed(2)}%',
          Icons.trending_up,
          stats.averageReturn >= 0 ? Colors.green : Colors.red,
        ),
        _buildStatCard(
          '最高收益率',
          '${(stats.maxReturn * 100).toStringAsFixed(2)}%',
          Icons.arrow_upward,
          Colors.green,
        ),
        _buildStatCard(
          '最低收益率',
          '${(stats.minReturn * 100).toStringAsFixed(2)}%',
          Icons.arrow_downward,
          Colors.red,
        ),
        _buildStatCard(
          '平均波动率',
          '${(stats.averageVolatility * 100).toStringAsFixed(2)}%',
          Icons.show_chart,
          Colors.orange,
        ),
        _buildStatCard(
          '平均夏普比率',
          stats.averageSharpeRatio.toStringAsFixed(2),
          Icons.speed,
          Colors.purple,
        ),
        _buildStatCard(
          '收益标准差',
          '${(stats.returnStdDev * 100).toStringAsFixed(2)}%',
          Icons.scatter_plot,
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: _buildChartContent(),
    );
  }

  Widget _buildChartContent() {
    switch (widget.chartType) {
      case StatisticsChartType.bar:
        return _buildBarChart();
      case StatisticsChartType.line:
        return _buildLineChart();
      case StatisticsChartType.pie:
        return _buildPieChart();
      default:
        return _buildBarChart();
    }
  }

  Widget _buildBarChart() {
    final fundData = _getUniqueFundData();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxYValue(),
        minY: _getMinYValue(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.white,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final fund = fundData[group.x.toInt()];
              return BarTooltipItem(
                text:
                    '${fund.fundName}\n${(fund.totalReturn * 100).toStringAsFixed(2)}%',
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= fundData.length)
                  return const Text('');
                final fund = fundData[index];
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    fund.fundCode,
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                final percentage = (value / 100).toStringAsFixed(1);
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text('$percentage%'),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: fundData.asMap().entries.map((entry) {
          final index = entry.key;
          final fund = entry.value;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: fund.totalReturn * 100,
                color: fund.totalReturn >= 0 ? Colors.green : Colors.red,
                width: 20,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                  bottom: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLineChart() {
    final periods = widget.comparisonResult.criteria.periods;
    final fundDataMap = <String, List<FlSpot>>{};

    // 为每只基金创建数据点
    for (final fund in widget.comparisonResult.fundData) {
      fundDataMap.putIfAbsent(fund.fundCode, []);
      fundDataMap[fund.fundCode]!.add(FlSpot(
        periods.indexOf(fund.period).toDouble(),
        fund.totalReturn * 100,
      ));
    }

    return LineChart(
      LineChartData(
        lineBarsData: fundDataMap.entries.map((entry) {
          final fundCode = entry.key;
          final spots = entry.value;
          final fund = widget.comparisonResult.getFundData(fundCode);

          return LineChartBarData(
            spots: spots,
            isCurved: true,
            color: _getFundColor(fundCode),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: _getFundColor(fundCode).withOpacity(0.2),
            ),
          );
        }).toList(),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= periods.length) return const Text('');
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(_getPeriodDisplayName(periods[index])),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text('${value.toInt()}%'),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 10,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            );
          },
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    final fundData = _getUniqueFundData();

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 60,
        sections: fundData.asMap().entries.map((entry) {
          final index = entry.key;
          final fund = entry.value;
          final value = fund.totalReturn.abs();

          return PieChartSectionData(
            color: _getFundColor(fund.fundCode),
            value: value,
            title: '${fund.fundCode}\n${(value * 100).toStringAsFixed(1)}%',
            radius: 80,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            valueStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDetailedAnalysis() {
    final stats = widget.comparisonResult.statistics;

    return ExpansionTile(
      title: Text(
        '详细分析',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
      leading: const Icon(Icons.insights),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAnalysisItem(
                '风险评估',
                _getRiskLevel(stats.averageVolatility),
                _getRiskDescription(stats.averageVolatility),
              ),
              const SizedBox(height: 12),
              _buildAnalysisItem(
                '收益表现',
                _getPerformanceLevel(stats.averageReturn),
                _getPerformanceDescription(stats.averageReturn),
              ),
              const SizedBox(height: 12),
              _buildAnalysisItem(
                '风险调整后收益',
                _getSharpeLevel(stats.averageSharpeRatio),
                _getSharpeDescription(stats.averageSharpeRatio),
              ),
              const SizedBox(height: 12),
              _buildAnalysisItem(
                '分散度',
                _getDiversificationLevel(stats.returnStdDev),
                _getDiversificationDescription(stats.returnStdDev),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisItem(String title, String level, String description) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getLevelColor(level),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  level,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  List<FundComparisonData> _getUniqueFundData() {
    final fundMap = <String, FundComparisonData>{};

    for (final data in widget.comparisonResult.fundData) {
      if (!fundMap.containsKey(data.fundCode)) {
        fundMap[data.fundCode] = data;
      }
    }

    return fundMap.values.toList();
  }

  double _getMaxYValue() {
    final data = _getUniqueFundData();
    if (data.isEmpty) return 100;

    final maxValue =
        data.map((d) => d.totalReturn * 100).reduce((a, b) => a > b ? a : b);

    return maxValue * 1.2; // 增加20%的空间
  }

  double _getMinYValue() {
    final data = _getUniqueFundData();
    if (data.isEmpty) return -100;

    final minValue =
        data.map((d) => d.totalReturn * 100).reduce((a, b) => a < b ? a : b);

    return minValue * 1.2; // 增加20%的空间
  }

  Color _getFundColor(String fundCode) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
    ];

    final index = fundCode.hashCode.abs() % colors.length;
    return colors[index];
  }

  String _getPeriodDisplayName(RankingPeriod period) {
    switch (period) {
      case RankingPeriod.oneMonth:
        return '1月';
      case RankingPeriod.threeMonths:
        return '3月';
      case RankingPeriod.sixMonths:
        return '6月';
      case RankingPeriod.oneYear:
        return '1年';
      case RankingPeriod.threeYears:
        return '3年';
      default:
        return period.name;
    }
  }

  String _getRiskLevel(double volatility) {
    if (volatility < 0.10) return '低风险';
    if (volatility < 0.20) return '中等风险';
    return '高风险';
  }

  String _getRiskDescription(double volatility) {
    if (volatility < 0.10) {
      return '基金价格波动较小，适合稳健型投资者';
    } else if (volatility < 0.20) {
      return '基金价格波动适中，适合平衡型投资者';
    } else {
      return '基金价格波动较大，适合激进型投资者';
    }
  }

  String _getPerformanceLevel(double returnValue) {
    if (returnValue < 0) return '亏损';
    if (returnValue < 0.05) return '低收益';
    if (returnValue < 0.15) return '中等收益';
    return '高收益';
  }

  String _getPerformanceDescription(double returnValue) {
    if (returnValue < 0) {
      return '投资出现亏损，需要关注风险控制';
    } else if (returnValue < 0.05) {
      return '收益较低，可能需要更长的投资周期';
    } else if (returnValue < 0.15) {
      return '收益表现良好，符合市场平均水平';
    } else {
      return '收益表现优秀，超越了市场平均水平';
    }
  }

  String _getSharpeLevel(double sharpeRatio) {
    if (sharpeRatio < 0) return '较差';
    if (sharpeRatio < 0.5) return '一般';
    if (sharpeRatio < 1.0) return '良好';
    return '优秀';
  }

  String _getSharpeDescription(double sharpeRatio) {
    if (sharpeRatio < 0) {
      return '风险调整后收益为负，投资效率不佳';
    } else if (sharpeRatio < 0.5) {
      return '每承担1单位风险获得的超额收益较低';
    } else if (sharpeRatio < 1.0) {
      return '风险调整后收益表现良好';
    } else {
      return '每承担1单位风险获得的超额收益较高';
    }
  }

  String _getDiversificationLevel(double stdDev) {
    if (stdDev < 0.05) return '高度集中';
    if (stdDev < 0.10) return '中度分散';
    return '高度分散';
  }

  String _getDiversificationDescription(double stdDev) {
    if (stdDev < 0.05) {
      return '基金表现高度相关，分散化效果有限';
    } else if (stdDev < 0.10) {
      return '基金表现存在一定相关性，分散化效果适中';
    } else {
      return '基金表现相关性较低，分散化效果良好';
    }
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case '低风险':
      case '高收益':
      case '优秀':
        return Colors.green;
      case '中等风险':
      case '中等收益':
      case '良好':
        return Colors.blue;
      case '高风险':
      case '低收益':
      case '较差':
        return Colors.red;
      case '高度集中':
        return Colors.red;
      case '中度分散':
        return Colors.blue;
      case '高度分散':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

/// 统计图表类型枚举
enum StatisticsChartType {
  bar, // 柱状图
  line, // 折线图
  pie, // 饼图
}
