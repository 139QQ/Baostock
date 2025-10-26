import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/entities/portfolio_holding.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/entities/portfolio_profit_metrics.dart';

/// 收益趋势图表组件
///
/// 提供交互式的收益趋势可视化：
/// - 支持多时间段切换
/// - 显示累计收益和日收益率
/// - 支持基准比较
/// - 交互式数据点查看
class ProfitTrendChart extends StatefulWidget {
  final List<PortfolioHolding>? holdings;
  final PortfolioProfitMetrics? metrics;
  final VoidCallback? onExportData;
  final bool isLoading;

  const ProfitTrendChart({
    super.key,
    this.holdings,
    this.metrics,
    this.onExportData,
    this.isLoading = false,
  });

  @override
  State<ProfitTrendChart> createState() => _ProfitTrendChartState();
}

class _ProfitTrendChartState extends State<ProfitTrendChart>
    with TickerProviderStateMixin {
  TimePeriod _selectedPeriod = TimePeriod.oneYear;
  ChartType _selectedChartType = ChartType.cumulative;
  List<FlSpot> _cumulativeData = [];
  List<FlSpot> _dailyReturnData = [];
  List<FlSpot> _benchmarkData = [];
  bool _showBenchmark = true;

  @override
  void initState() {
    super.initState();
    _generateMockData();
  }

  void _generateMockData() {
    // 生成模拟数据用于演示
    final days = _selectedPeriod.days;
    final now = DateTime.now();

    _cumulativeData.clear();
    _dailyReturnData.clear();
    _benchmarkData.clear();

    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: days - i));
      final x = i.toDouble();

      // 模拟累计收益曲线
      final cumulativeReturn = 0.15 * (i / days) + 0.02 * math.sin(i * 0.1);
      _cumulativeData.add(FlSpot(x, cumulativeReturn));

      // 模拟日收益率
      final dailyReturn = 0.001 +
          0.005 * math.sin(i * 0.2) +
          (math.Random().nextDouble() - 0.5) * 0.002;
      _dailyReturnData.add(FlSpot(x, dailyReturn));

      // 模拟基准数据
      final benchmarkReturn = 0.12 * (i / days) + 0.01 * math.sin(i * 0.15);
      _benchmarkData.add(FlSpot(x, benchmarkReturn));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 图表控制栏
        _buildChartControls(),
        const SizedBox(height: 16),

        // 图表主体
        Expanded(
          child: _buildChart(),
        ),

        const SizedBox(height: 16),

        // 图例和统计信息
        _buildChartLegend(),
      ],
    );
  }

  Widget _buildChartControls() {
    return Row(
      children: [
        // 时间段选择器
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: TimePeriod.values.map((period) {
                final isSelected = _selectedPeriod == period;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(period.displayName),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedPeriod = period;
                          _generateMockData();
                        });
                      }
                    },
                    backgroundColor: isSelected
                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                        : null,
                    selectedColor: Theme.of(context).primaryColor,
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // 图表类型选择器
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('图表类型: ', style: TextStyle(color: Colors.grey[600])),
            PopupMenuButton<ChartType>(
              initialValue: _selectedChartType,
              onSelected: (type) {
                setState(() {
                  _selectedChartType = type;
                });
              },
              itemBuilder: (context) => ChartType.values.map((type) {
                return PopupMenuItem<ChartType>(
                  value: type,
                  child: Row(
                    children: [
                      Icon(type.icon, size: 16),
                      const SizedBox(width: 8),
                      Text(type.displayName),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        const SizedBox(width: 16),

        // 基准比较开关
        Switch(
          value: _showBenchmark,
          onChanged: (value) {
            setState(() {
              _showBenchmark = value;
            });
          },
          activeColor: Theme.of(context).primaryColor,
        ),
        Text('基准比较', style: TextStyle(color: Colors.grey[600])),

        const SizedBox(width: 16),

        // 导出按钮
        IconButton(
          onPressed: widget.onExportData,
          icon: const Icon(Icons.download),
          tooltip: '导出数据',
        ),
      ],
    );
  }

  Widget _buildChart() {
    if (widget.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: _selectedChartType == ChartType.cumulative
          ? _buildCumulativeChart()
          : _buildDailyReturnChart(),
    );
  }

  Widget _buildCumulativeChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey[300]!,
              strokeWidth: 1,
            );
          },
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[300]!,
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        titlesData: FlTitlesData(
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 0.05,
              getTitlesWidget: (value, meta) {
                final text = '${(value * 100).toInt()}%';
                return Text(
                  text,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: _getInterval(),
              getTitlesWidget: (value, meta) {
                final date = DateTime.now().subtract(
                  Duration(
                      days: (_selectedPeriod.days - value.toInt()).round()),
                );
                final text = '${date.month}/${date.day}';
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 0.05,
              getTitlesWidget: (value, meta) {
                final text = '${(value * 100).toInt()}%';
                return Text(
                  text,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[200]!),
        ),
        lineBarsData: [
          // 投资组合累计收益
          LineChartBarData(
            spots: _cumulativeData,
            isCurved: true,
            color: Theme.of(context).primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Theme.of(context).primaryColor,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).primaryColor.withOpacity(0.1),
            ),
          ),
          // 基准累计收益
          if (_showBenchmark)
            LineChartBarData(
              spots: _benchmarkData,
              isCurved: true,
              color: Colors.grey,
              barWidth: 2,
              isStrokeCapRound: true,
              dashArray: [5, 5],
              dotData: FlDotData(show: false),
            ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.black87,
            tooltipRoundedRadius: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final value = spot.y;
                final date = DateTime.now().subtract(
                  Duration(
                      days: (_selectedPeriod.days - spot.x.toInt()).round()),
                );
                return LineTooltipItem(
                  '${date.month}/${date.day}\n收益: ${(value * 100).toStringAsFixed(2)}%',
                  TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
          touchCallback: (FlTouchEvent event, lineTouchResponse) {
            // 处理触摸事件
          },
        ),
        minY: -0.1,
        maxY: 0.3,
      ),
    );
  }

  Widget _buildDailyReturnChart() {
    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            if (value == 0) {
              return FlLine(
                color: Colors.grey[400]!,
                strokeWidth: 2,
              );
            }
            return FlLine(
              color: Colors.grey[300]!,
              strokeWidth: 1,
              dashArray: [3, 3],
            );
          },
        ),
        titlesData: FlTitlesData(
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 0.02,
              getTitlesWidget: (value, meta) {
                final text = '${(value * 100).toStringAsFixed(1)}%';
                return Text(
                  text,
                  style: TextStyle(
                    color: _getReturnColor(value),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: _getInterval() * 2,
              getTitlesWidget: (value, meta) {
                final date = DateTime.now().subtract(
                  Duration(
                      days: (_selectedPeriod.days - value.toInt()).round()),
                );
                final text = '${date.month}/${date.day}';
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 0.02,
              getTitlesWidget: (value, meta) {
                final text = '${(value * 100).toStringAsFixed(1)}%';
                return Text(
                  text,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[200]!),
        ),
        barGroups: _dailyReturnData.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            showingTooltipIndicators: _selectedPeriod.days <= 90 ? [0] : null,
            barRods: [
              BarChartRodData(
                toY: entry.value.y,
                color: _getReturnColor(entry.value.y),
                width: _getBarWidth(),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                  bottom: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.black87,
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final value = rod.toY;
              final date = DateTime.now().subtract(
                Duration(
                    days: (_selectedPeriod.days - group.x.toInt()).round()),
              );
              return BarTooltipItem(
                '${date.month}/${date.day}\n收益率: ${(value * 100).toStringAsFixed(2)}%',
                TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        minY: -0.05,
        maxY: 0.05,
      ),
    );
  }

  Widget _buildChartLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildLegendItem(
            '投资组合',
            Theme.of(context).primaryColor,
            isLine: _selectedChartType == ChartType.cumulative,
          ),
          if (_showBenchmark) ...[
            const SizedBox(width: 24),
            _buildLegendItem(
              '基准指数',
              Colors.grey,
              isLine: true,
              isDashed: true,
            ),
          ],
          const Spacer(),
          if (widget.metrics != null) ...[
            _buildStatItem('总收益',
                '${(widget.metrics!.totalReturnPercentage).toStringAsFixed(2)}%'),
            const SizedBox(width: 16),
            _buildStatItem('年化收益',
                '${(widget.metrics!.annualizedReturn * 100).toStringAsFixed(2)}%'),
            const SizedBox(width: 16),
            _buildStatItem('日收益',
                '${(widget.metrics!.dailyReturn * 100).toStringAsFixed(2)}%'),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color,
      {bool isLine = true, bool isDashed = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.grey[900],
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  double _getInterval() {
    switch (_selectedPeriod) {
      case TimePeriod.oneMonth:
        return 7.0;
      case TimePeriod.threeMonths:
        return 15.0;
      case TimePeriod.sixMonths:
        return 30.0;
      case TimePeriod.oneYear:
        return 60.0;
      case TimePeriod.threeYears:
        return 90.0;
      case TimePeriod.all:
        return 120.0;
    }
  }

  double _getBarWidth() {
    final totalBars = _selectedPeriod.days.toDouble();
    if (totalBars <= 0) return 8.0;
    return (MediaQuery.of(context).size.width - 100) / totalBars - 2;
  }

  Color _getReturnColor(double value) {
    if (value > 0.02) return Colors.green;
    if (value > 0) return Colors.lightGreen;
    if (value > -0.01) return Colors.orange;
    return Colors.red;
  }
}

/// 时间段枚举
enum TimePeriod {
  oneMonth('1个月', 30),
  threeMonths('3个月', 90),
  sixMonths('6个月', 180),
  oneYear('1年', 365),
  threeYears('3年', 1095),
  all('全部', 0);

  const TimePeriod(this.displayName, this.days);

  final String displayName;
  final int days;
}

/// 图表类型枚举
enum ChartType {
  cumulative('累计收益', Icons.trending_up),
  dailyReturn('日收益率', Icons.bar_chart);

  const ChartType(this.displayName, this.icon);

  final String displayName;
  final IconData icon;
}
