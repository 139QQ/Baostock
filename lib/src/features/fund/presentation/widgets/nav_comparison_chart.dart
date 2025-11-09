import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:decimal/decimal.dart';

import '../../data/processors/fund_nav_data_manager.dart';
import '../../models/fund_nav_data.dart';

/// 历史净值对比图表
///
/// 显示基金净值的历史变化趋势和对比信息
/// 支持多种图表类型和自定义配置
class NavComparisonChart extends StatefulWidget {
  /// 基金代码
  final String fundCode;

  /// 基金名称
  final String fundName;

  /// 历史数据
  final List<FundNavData> historicalData;

  /// 图表类型
  final NavChartType chartType;

  /// 图表样式
  final NavChartStyle style;

  /// 时间范围
  final ChartTimeRange timeRange;

  /// 是否显示网格线
  final bool showGrid;

  /// 是否显示数据点
  final bool showDataPoints;

  /// 是否显示工具提示
  final bool showTooltip;

  /// 自定义颜色
  final Color? primaryColor;

  /// 自定义背景颜色
  final Color? backgroundColor;

  /// 高度
  final double height;

  /// 数据更新回调
  final Function(List<FundNavData>)? onDataUpdate;

  const NavComparisonChart({
    Key? key,
    required this.fundCode,
    required this.fundName,
    required this.historicalData,
    this.chartType = NavChartType.line,
    this.style = NavChartStyle.modern,
    this.timeRange = ChartTimeRange.oneMonth,
    this.showGrid = true,
    this.showDataPoints = true,
    this.showTooltip = true,
    this.primaryColor,
    this.backgroundColor,
    this.height = 200,
    this.onDataUpdate,
  }) : super(key: key);

  @override
  State<NavComparisonChart> createState() => _NavComparisonChartState();
}

class _NavComparisonChartState extends State<NavComparisonChart> {
  final FundNavDataManager _navManager = FundNavDataManager();
  List<FundNavData> _chartData = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeChart();
  }

  @override
  void didUpdateWidget(NavComparisonChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.historicalData != oldWidget.historicalData) {
      _updateChartData(widget.historicalData);
    }
  }

  /// 初始化图表
  void _initializeChart() {
    _updateChartData(widget.historicalData);

    // 如果数据为空，尝试获取历史数据
    if (_chartData.isEmpty) {
      _loadHistoricalData();
    }
  }

  /// 更新图表数据
  void _updateChartData(List<FundNavData> data) {
    setState(() {
      _chartData = _processChartData(data);
      _errorMessage = null;
    });

    widget.onDataUpdate?.call(_chartData);
  }

  /// 处理图表数据
  List<FundNavData> _processChartData(List<FundNavData> data) {
    if (data.isEmpty) return [];

    // 按时间排序
    final sortedData = List<FundNavData>.from(data);
    sortedData.sort((a, b) => a.navDate.compareTo(b.navDate));

    // 根据时间范围过滤数据
    final now = DateTime.now();
    final cutoffDate = _getCutoffDate(now, widget.timeRange);

    final filteredData = sortedData
        .where((data) => data.navDate.isAfter(cutoffDate))
        .toList();

    // 限制数据点数量
    final maxDataPoints = _getMaxDataPoints(widget.timeRange);
    if (filteredData.length > maxDataPoints) {
      return _sampleData(filteredData, maxDataPoints);
    }

    return filteredData;
  }

  /// 获取截止日期
  DateTime _getCutoffDate(DateTime now, ChartTimeRange range) {
    switch (range) {
      case ChartTimeRange.oneWeek:
        return now.subtract(const Duration(days: 7));
      case ChartTimeRange.oneMonth:
        return now.subtract(const Duration(days: 30));
      case ChartTimeRange.threeMonths:
        return now.subtract(const Duration(days: 90));
      case ChartTimeRange.sixMonths:
        return now.subtract(const Duration(days: 180));
      case ChartTimeRange.oneYear:
        return now.subtract(const Duration(days: 365));
      case ChartTimeRange.all:
        return DateTime(2000); // 足够早的日期
    }
  }

  /// 获取最大数据点数
  int _getMaxDataPoints(ChartTimeRange range) {
    switch (range) {
      case ChartTimeRange.oneWeek:
        return 7;
      case ChartTimeRange.oneMonth:
        return 30;
      case ChartTimeRange.threeMonths:
        return 45;
      case ChartTimeRange.sixMonths:
        return 60;
      case ChartTimeRange.oneYear:
        return 90;
      case ChartTimeRange.all:
        return 100;
    }
  }

  /// 数据采样
  List<FundNavData> _sampleData(List<FundNavData> data, int maxPoints) {
    if (data.length <= maxPoints) return data;

    final step = data.length / maxPoints;
    final sampledData = <FundNavData>[];

    for (int i = 0; i < maxPoints; i++) {
      final index = (i * step).round();
      if (index < data.length) {
        sampledData.add(data[index]);
      }
    }

    // 确保包含最新的数据点
    if (sampledData.last != data.last) {
      sampledData.add(data.last);
    }

    return sampledData;
  }

  /// 加载历史数据
  Future<void> _loadHistoricalData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final historicalData = await _navManager.getHistoricalNavData(
        widget.fundCode,
        limit: _getMaxDataPoints(widget.timeRange),
      );

      if (mounted) {
        _updateChartData(historicalData);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '加载历史数据失败: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 获取主色调
  Color get _primaryColor => widget.primaryColor ?? Colors.blue;

  /// 获取背景色
  Color get _backgroundColor => widget.backgroundColor ?? Colors.grey.shade50;

  /// 构建折线图
  Widget _buildLineChart() {
    if (_chartData.isEmpty) {
      return _buildEmptyChart();
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: widget.showGrid,
          drawVerticalLine: true,
          horizontalInterval: _calculateHorizontalInterval(),
          verticalInterval: _calculateVerticalInterval(),
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
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: _calculateLabelInterval(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= _chartData.length) {
                  return const Text('');
                }
                final date = _chartData[index].navDate;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _formatDate(date),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: _calculateHorizontalInterval(),
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(3),
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
        maxX: (_chartData.length - 1).toDouble(),
        minY: _calculateMinY(),
        maxY: _calculateMaxY(),
        lineBarsData: [
          LineChartBarData(
            spots: _createLineSpots(),
            isCurved: true,
            color: _primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: widget.showDataPoints,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: _primaryColor,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: _primaryColor.withOpacity(0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: widget.showTooltip
              ? LineTouchTooltipData(
                  tooltipBgColor: Colors.black87,
                  tooltipRoundedRadius: 8,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final index = spot.x.toInt();
                      if (index < 0 || index >= _chartData.length) {
                        return null;
                      }
                      final data = _chartData[index];
                      return LineTooltipItem(
                        '净值: ${data.navFormatted}\n日期: ${_formatDate(data.navDate)}',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        children: [
                          if (data.changeRate != Decimal.zero)
                            TextSpan(
                              text: '变化: ${data.changePercentageFormatted}',
                              style: TextStyle(
                                color: data.isUp ? Colors.green.shade300 : Colors.red.shade300,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      );
                    }).toList();
                  })
              : null,
        ),
      ),
    );
  }

  /// 构建柱状图
  Widget _buildBarChart() {
    if (_chartData.isEmpty) {
      return _buildEmptyChart();
    }

    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: widget.showGrid,
          drawVerticalLine: false,
          horizontalInterval: _calculateHorizontalInterval(),
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: _calculateLabelInterval(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= _chartData.length) {
                  return const Text('');
                }
                final date = _chartData[index].navDate;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: RotatedBox(
                    quarterTurns: -1,
                    child: Text(
                      _formatDate(date, short: true),
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: _calculateHorizontalInterval(),
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(3),
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
        barGroups: _createBarGroups(),
        barTouchData: BarTouchData(
          touchTooltipData: widget.showTooltip
              ? BarTouchTooltipData(
                  tooltipBgColor: Colors.black87,
                  tooltipRoundedRadius: 8,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final index = group.x.toInt();
                    if (index < 0 || index >= _chartData.length) {
                      return null;
                    }
                    final data = _chartData[index];
                    return BarTooltipItem(
                      '净值: ${data.navFormatted}\n日期: ${_formatDate(data.navDate)}',
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  })
              : null,
        ),
      ),
    );
  }

  /// 构建面积图
  Widget _buildAreaChart() {
    return _buildLineChart(); // 面积图基于折线图，只是配置不同
  }

  /// 构建空图表
  Widget _buildEmptyChart() {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              '暂无历史数据',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.fundName,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建加载中状态
  Widget _buildLoadingState() {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// 构建错误状态
  Widget _buildErrorState() {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              '加载失败',
              style: TextStyle(
                fontSize: 14,
                color: Colors.red.shade600,
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 4),
              Text(
                _errorMessage!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadHistoricalData,
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  /// 创建折线图数据点
  List<FlSpot> _createLineSpots() {
    return _chartData
        .asMap()
        .entries
        .map((entry) => FlSpot(
              entry.key.toDouble(),
              entry.value.nav.toDouble(),
            ))
        .toList();
  }

  /// 创建柱状图数据组
  List<BarChartGroupData> _createBarGroups() {
    return _chartData
        .asMap()
        .entries
        .map((entry) => BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.nav.toDouble(),
                  color: _primaryColor,
                  width: 8,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            ))
        .toList();
  }

  /// 计算水平间隔
  double _calculateHorizontalInterval() {
    if (_chartData.isEmpty) return 0.1;

    final values = _chartData.map((data) => data.nav.toDouble()).toList();
    final minVal = values.reduce(math.min);
    final maxVal = values.reduce(math.max);
    final range = maxVal - minVal;

    if (range <= 0) return 0.1;

    // 大约5-10个网格线
    return (range / 6).ceilToDouble();
  }

  /// 计算垂直间隔
  double _calculateVerticalInterval() {
    final maxIndex = _chartData.length - 1;
    if (maxIndex <= 0) return 1;

    // 大约显示5-10个标签
    return (maxIndex / 6).ceilToDouble().clamp(1.0, double.infinity);
  }

  /// 计算标签间隔
  double _calculateLabelInterval() {
    final maxIndex = _chartData.length - 1;
    if (maxIndex <= 0) return 1;

    // 大约显示5-8个标签
    return (maxIndex / 6).ceilToDouble().clamp(1.0, double.infinity);
  }

  /// 计算最小Y值
  double _calculateMinY() {
    if (_chartData.isEmpty) return 0.0;

    final values = _chartData.map((data) => data.nav.toDouble()).toList();
    final minVal = values.reduce(math.min);
    final maxVal = values.reduce(math.max);
    final range = maxVal - minVal;

    // 为底部留出10%的空间
    return (minVal - range * 0.1).clamp(0.0, double.infinity);
  }

  /// 计算最大Y值
  double _calculateMaxY() {
    if (_chartData.isEmpty) return 1.0;

    final values = _chartData.map((data) => data.nav.toDouble()).toList();
    final maxVal = values.reduce(math.max);
    final minVal = values.reduce(math.min);
    final range = maxVal - minVal;

    // 为顶部留出10%的空间
    return maxVal + range * 0.1;
  }

  /// 格式化日期
  String _formatDate(DateTime date, {bool short = false}) {
    if (short) {
      return '${date.month}/${date.day}';
    }
    return '${date.month}/${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    Widget chart;
    switch (widget.chartType) {
      case NavChartType.line:
        chart = _buildLineChart();
        break;
      case NavChartType.bar:
        chart = _buildBarChart();
        break;
      case NavChartType.area:
        chart = _buildAreaChart();
        break;
    }

    return Container(
      height: widget.height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.fundName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '近${widget.timeRange.label}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: chart),
        ],
      ),
    );
  }
}

/// 净值图表类型
enum NavChartType {
  /// 折线图
  line,

  /// 柱状图
  bar,

  /// 面积图
  area,
}

/// 净值图表样式
enum NavChartStyle {
  /// 现代风格
  modern,

  /// 简约风格
  minimal,

  /// 详细风格
  detailed,
}

/// 时间范围
enum ChartTimeRange {
  /// 一周
  oneWeek,

  /// 一个月
  oneMonth,

  /// 三个月
  threeMonths,

  /// 六个月
  sixMonths,

  /// 一年
  oneYear,

  /// 全部
  all,
}

/// 获取时间范围标签
extension ChartTimeRangeExtension on ChartTimeRange {
  String get label {
    switch (this) {
      case ChartTimeRange.oneWeek:
        return '一周';
      case ChartTimeRange.oneMonth:
        return '一月';
      case ChartTimeRange.threeMonths:
        return '三月';
      case ChartTimeRange.sixMonths:
        return '六月';
      case ChartTimeRange.oneYear:
        return '一年';
      case ChartTimeRange.all:
        return '全部';
    }
  }
}

