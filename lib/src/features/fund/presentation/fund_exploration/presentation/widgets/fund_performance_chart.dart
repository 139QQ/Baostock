import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../cubit/fund_detail_cubit.dart';

/// 基金业绩图表组件
///
/// 展示基金的历史净值走势和收益率变�?
/// 支持多种时间周期切换和图表类型选择
class FundPerformanceChart extends StatefulWidget {
  final List<FundNav> navData;
  final double? currentNav;
  final double? currentReturn;

  const FundPerformanceChart({
    super.key,
    required this.navData,
    this.currentNav,
    this.currentReturn,
  });

  @override
  State<FundPerformanceChart> createState() => _FundPerformanceChartState();
}

class _FundPerformanceChartState extends State<FundPerformanceChart> {
  String _selectedTimeRange = '1�?;
  String _selectedChartType = '净值走�?;
  int _touchedIndex = -1;

  // 时间周期选项
  static List String> final _timeRanges = ['1�?, '3�?, '6�?, '1�?, '3�?, '成立�?];

  // 图表类型选项
  static List String> final _chartTypes = ['净值走�?, '收益�?, '回撤分析'];

  @override
  Widget build(BuildContext context) {
    final filteredData = _filterDataByTimeRange();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题和控制选项
            Row(
              children: [
                const Text(
                  '业绩走势',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),

                // 图表类型选择
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedChartType,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.arrow_drop_down, size: 16),
                    items: _chartTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type, style: const TextStyle(fontSize: 12)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedChartType = value;
                        });
                      }
                    },
                  ),
                ),

                const SizedBox(width: 8),

                // 时间周期选择
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedTimeRange,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.arrow_drop_down, size: 16),
                    items: _timeRanges.map((range) {
                      return DropdownMenuItem<String>(
                        value: range,
                        child: Text(range, style: const TextStyle(fontSize: 12)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedTimeRange = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 关键指标展示
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricCard(
                  '当前净�?,
                  widget.currentNav?.toStringAsFixed(4) ?? '--',
                  Colors.blue,
                ),
                _buildMetricCard(
                  '阶段收益',
                  '${widget.currentReturn?.toStringAsFixed(2) ?? '--'}%',
                  widget.currentReturn != null && widget.currentReturn! > 0
                      ? Colors.red
                      : Colors.green,
                ),
                _buildMetricCard(
                  '数据点数',
                  '${filteredData.length}',
                  Colors.grey,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 图表区域
            SizedBox(
              height: 300,
              child: _buildChart(filteredData),
            ),

            const SizedBox(height: 16),

            // 图表说明
            Text(
              _getChartDescription(),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建指标卡片
  Widget _buildMetricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建图表
  Widget _buildChart(List<FundNav> data) {
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              '暂无数据',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    switch (_selectedChartType) {
      case '净值走�?:
        return _buildNavLineChart(data);
      case '收益�?:
        return _buildReturnLineChart(data);
      case '回撤分析':
        return _buildDrawdownChart(data);
      default:
        return _buildNavLineChart(data);
    }
  }

  /// 构建净值走势图
  Widget _buildNavLineChart(List<FundNav> data) {
    final spots = data.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final nav = entry.value.unitNav;
      return FlSpot(index, nav);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 0.1,
          verticalInterval: 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 5,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  final date = DateTime.parse(data[index].navDate);
                  return Text(
                    '${date.month}/${date.day}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 0.1,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300),
        ),
        minX: 0,
        maxX: spots.length.toDouble() - 1,
        minY: data.map((e) => e.unitNav).reduce((a, b) => a < b ? a : b) * 0.995,
        maxY: data.map((e) => e.unitNav).reduce((a, b) => a > b ? a : b) * 1.005,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade400,
                Colors.blue.shade600,
              ],
            ),
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                // 当触摸到该点时显示更大的圆点
                if (index == _touchedIndex) {
                  return FlDotCirclePainter(
                    radius: 6,
                    color: Colors.red,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                }
                // 默认显示小圆�?
                return FlDotCirclePainter(
                  radius: 2,
                  color: Colors.blue.shade600,
                  strokeWidth: 0,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade400.withOpacity(0.3),
                  Colors.blue.shade600.withOpacity(0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
            if (event is FlTapUpEvent) {
              setState(() {
                _touchedIndex = touchResponse?.lineBarSpots?.first.spotIndex ?? -1;
              });
            }
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final index = barSpot.spotIndex;
                if (index >= 0 && index < data.length) {
                  final navData = data[index];
                  return LineTooltipItem(
                    '日期: ${navData.navDate}\n净�? ${navData.unitNav.toStringAsFixed(4)}',
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  );
                }
                return null;
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  /// 构建收益率图
  Widget _buildReturnLineChart(List<FundNav> data) {
    if (data.length < 2) return _buildNavLineChart(data);

    final baseNav = data.first.unitNav;
    final spots = data.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final nav = entry.value.unitNav;
      final returnRate = ((nav - baseNav) / baseNav) * 100;
      return FlSpot(index, returnRate);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 2,
          verticalInterval: 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 5,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  final date = DateTime.parse(data[index].navDate);
                  return Text(
                    '${date.month}/${date.day}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 2,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300),
        ),
        minX: 0,
        maxX: spots.length.toDouble() - 1,
        minY: spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 1,
        maxY: spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 1,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: LinearGradient(
              colors: spots.last.y >= 0
                  ? [Colors.red.shade400, Colors.red.shade600]
                  : [Colors.green.shade400, Colors.green.shade600],
            ),
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: spots.last.y >= 0
                    ? [
                        Colors.red.shade400.withOpacity(0.3),
                        Colors.red.shade600.withOpacity(0.1),
                      ]
                    : [
                        Colors.green.shade400.withOpacity(0.3),
                        Colors.green.shade600.withOpacity(0.1),
                      ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final index = barSpot.spotIndex;
                if (index >= 0 && index < data.length) {
                  final navData = data[index];
                  final returnRate = barSpot.y;
                  return LineTooltipItem(
                    '日期: ${navData.navDate}\n收益�? ${returnRate.toStringAsFixed(2)}%',
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  );
                }
                return null;
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  /// 构建回撤分析�?
  Widget _buildDrawdownChart(List<FundNav> data) {
    if (data.length < 2) return _buildNavLineChart(data);

    // 计算回撤数据
    final drawdownData = _calculateDrawdown(data);
    final spots = drawdownData.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final drawdown = entry.value;
      return FlSpot(index, drawdown);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 1,
          verticalInterval: 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 5,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  final date = DateTime.parse(data[index].navDate);
                  return Text(
                    '${date.month}/${date.day}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300),
        ),
        minX: 0,
        maxX: spots.length.toDouble() - 1,
        minY: spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 0.5,
        maxY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.red,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.red.withOpacity(0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final index = barSpot.spotIndex;
                if (index >= 0 && index < data.length) {
                  final navData = data[index];
                  final drawdown = barSpot.y;
                  return LineTooltipItem(
                    '日期: ${navData.navDate}\n回撤: ${drawdown.toStringAsFixed(2)}%',
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  );
                }
                return null;
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  /// 根据时间范围过滤数据
  List<FundNav> _filterDataByTimeRange() {
    if (widget.navData.isEmpty) return [];

    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedTimeRange) {
      case '1�?:
        startDate = now.subtract(const Duration(days: 30));
        break;
      case '3�?:
        startDate = now.subtract(const Duration(days: 90));
        break;
      case '6�?:
        startDate = now.subtract(const Duration(days: 180));
        break;
      case '1�?:
        startDate = now.subtract(const Duration(days: 365));
        break;
      case '3�?:
        startDate = now.subtract(const Duration(days: 1095));
        break;
      case '成立�?:
        return widget.navData;
      default:
        startDate = now.subtract(const Duration(days: 365));
    }

    return widget.navData.where((nav) {
      final navDate = DateTime.parse(nav.navDate);
      return navDate.isAfter(startDate) || navDate.isAtSameMomentAs(startDate);
    }).toList();
  }

  /// 计算回撤数据
  List<double> _calculateDrawdown(List<FundNav> data) {
    final drawdowns = <double>[];
    double peak = data.first.unitNav;

    for (int i = 0; i < data.length; i++) {
      final currentNav = data[i].unitNav;

      if (currentNav > peak) {
        peak = currentNav;
      }

      final drawdown = ((currentNav - peak) / peak) * 100;
      drawdowns.add(drawdown);
    }

    return drawdowns;
  }

  /// 获取图表说明
  String _getChartDescription() {
    switch (_selectedChartType) {
      case '净值走�?:
        return '展示基金单位净值的历史变化趋势，反映基金资产的实际价值变�?;
      case '收益�?:
        return '展示基金相对于期初的累计收益率变化，便于观察投资效果';
      case '回撤分析':
        return '展示基金从历史高点下跌的幅度，反映基金的风险控制能力';
      default:
        return '基金业绩走势�?;
    }
  }
}
