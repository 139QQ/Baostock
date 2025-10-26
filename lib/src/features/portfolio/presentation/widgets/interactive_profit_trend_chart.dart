import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/entities/portfolio_holding.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/entities/portfolio_profit_metrics.dart';

/// 交互式收益趋势图表组件
///
/// 按照文档规范实现交互式图表区域：
/// - 主图表：组合净值曲线 + 基准对比线
/// - 副图1：日收益率柱状图
/// - 副图2：累计收益率对比图
/// - 图例和控制工具栏
class InteractiveProfitTrendChart extends StatefulWidget {
  final List<PortfolioHolding>? holdings;
  final PortfolioProfitMetrics? metrics;
  final VoidCallback? onExportData;
  final bool isLoading;
  final String? selectedPeriod;
  final String? selectedReturnType;

  const InteractiveProfitTrendChart({
    super.key,
    this.holdings,
    this.metrics,
    this.onExportData,
    this.isLoading = false,
    this.selectedPeriod,
    this.selectedReturnType,
  });

  @override
  State<InteractiveProfitTrendChart> createState() =>
      _InteractiveProfitTrendChartState();
}

class _InteractiveProfitTrendChartState
    extends State<InteractiveProfitTrendChart> with TickerProviderStateMixin {
  // 图表数据
  List<FlSpot> _cumulativeData = [];
  List<FlSpot> _dailyReturnData = [];
  List<FlSpot> _benchmarkData = [];
  List<FlSpot> _comparisonData = [];

  // 图表控制状态
  bool _showBenchmark = true;
  bool _showComparison = true;
  final bool _showGridLines = true;
  final bool _showDataPoints = true;
  double _zoomLevel = 1.0;

  // 动画控制
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _generateChartData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 450,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: widget.isLoading ? _buildLoadingState() : _buildChartContent(),
    );
  }

  /// 构建加载状态
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            '加载图表数据...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建图表内容
  Widget _buildChartContent() {
    return Column(
      children: [
        // 图例和控制栏
        _buildLegendAndControls(),
        const SizedBox(height: 16),

        // 主图表区域
        Expanded(
          flex: 3,
          child: _buildMainChart(),
        ),

        const SizedBox(height: 16),

        // 副图区域
        Expanded(
          flex: 1,
          child: _buildSubCharts(),
        ),
      ],
    );
  }

  /// 构建图例和控制栏
  Widget _buildLegendAndControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // 图例
          Expanded(
            child: Wrap(
              spacing: 16,
              children: [
                _buildLegendItem('组合净值', Colors.blue[700]!),
                if (_showBenchmark) ...[
                  _buildLegendItem('沪深300', Colors.red[600]!),
                ],
                if (_showComparison) ...[
                  _buildLegendItem('同类平均', Colors.green[600]!),
                ],
              ],
            ),
          ),

          // 控制按钮
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 基准对比开关
              _buildToggleSwitch(
                '基准对比',
                _showBenchmark,
                (value) {
                  setState(() {
                    _showBenchmark = value;
                  });
                },
              ),
              const SizedBox(width: 12),

              // 同类对比开关
              _buildToggleSwitch(
                '同类对比',
                _showComparison,
                (value) {
                  setState(() {
                    _showComparison = value;
                  });
                },
              ),
              const SizedBox(width: 12),

              // 缩放控制
              _buildZoomControls(),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建图例项
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 构建切换开关
  Widget _buildToggleSwitch(
      String label, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(width: 6),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Theme.of(context).primaryColor,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }

  /// 构建缩放控制
  Widget _buildZoomControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: _zoomOut,
          icon: const Icon(Icons.zoom_out, size: 18),
          tooltip: '缩小',
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
        ),
        IconButton(
          onPressed: _resetZoom,
          icon: const Icon(Icons.zoom_out_map, size: 18),
          tooltip: '重置',
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
        ),
        IconButton(
          onPressed: _zoomIn,
          icon: const Icon(Icons.zoom_in, size: 18),
          tooltip: '放大',
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
        ),
      ],
    );
  }

  /// 构建主图表
  Widget _buildMainChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: _showGridLines ? _buildGridData() : null,
          titlesData: _buildMainTitlesData(),
          borderData: FlBorderData(show: true),
          minX: _getMinX(),
          maxX: _getMaxX(),
          minY: _getMinY(),
          maxY: _getMaxY(),
          lineBarsData: _buildMainLineBarsData(),
          lineTouchData: _buildLineTouchData(),
        ),
      ),
    );
  }

  /// 构建副图区域
  Widget _buildSubCharts() {
    return Row(
      children: [
        // 日收益率柱状图
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '日收益率',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: BarChart(
                    BarChartData(
                      barGroups: _buildDailyReturnBarGroups(),
                      titlesData: _buildSubTitlesData('日收益率'),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(show: false),
                      barTouchData: _buildBarTouchData(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 累计收益率对比图
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '累计收益率对比',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: _buildSubTitlesData('累计收益率'),
                      borderData: FlBorderData(show: false),
                      minX: _getMinX(),
                      maxX: _getMaxX(),
                      minY: _getComparisonMinY(),
                      maxY: _getComparisonMaxY(),
                      lineBarsData: _buildComparisonLineBarsData(),
                      lineTouchData: _buildLineTouchData(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 生成图表数据
  void _generateChartData() {
    if (widget.holdings == null || widget.holdings!.isEmpty) return;

    final days = _getDaysFromPeriod();
    final now = DateTime.now();

    // 生成模拟数据
    _cumulativeData = [];
    _dailyReturnData = [];
    _benchmarkData = [];
    _comparisonData = [];

    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: days - i));
      final x = date.millisecondsSinceEpoch.toDouble();

      // 模拟组合净值曲线
      final cumulativeValue =
          100000 * (1 + math.Random().nextDouble() * 0.2 - 0.05);
      _cumulativeData.add(FlSpot(x, cumulativeValue));

      // 模拟日收益率
      final dailyReturn =
          (math.Random().nextDouble() - 0.5) * 0.04; // -2% to +2%
      _dailyReturnData.add(FlSpot(x, dailyReturn * 100));

      // 模拟基准数据
      final benchmarkValue =
          100000 * (1 + math.Random().nextDouble() * 0.15 - 0.03);
      _benchmarkData.add(FlSpot(x, benchmarkValue));

      // 模拟同类平均数据
      final comparisonValue =
          100000 * (1 + math.Random().nextDouble() * 0.18 - 0.02);
      _comparisonData.add(FlSpot(x, comparisonValue));
    }

    // 按时间排序
    _cumulativeData.sort((a, b) => a.x.compareTo(b.x));
    _dailyReturnData.sort((a, b) => a.x.compareTo(b.x));
    _benchmarkData.sort((a, b) => a.x.compareTo(b.x));
    _comparisonData.sort((a, b) => a.x.compareTo(b.x));
  }

  /// 从时间周期获取天数
  int _getDaysFromPeriod() {
    switch (widget.selectedPeriod) {
      case '3日':
        return 3;
      case '1周':
        return 7;
      case '1月':
        return 30;
      case '3月':
        return 90;
      case '6月':
        return 180;
      case '1年':
        return 365;
      case '3年':
        return 1095;
      case '今年来':
        return DateTime.now()
            .difference(DateTime(DateTime.now().year, 1, 1))
            .inDays;
      case '成立来':
        return 365 * 3; // 假设成立3年
      default:
        return 30;
    }
  }

  /// 获取最小X值
  double _getMinX() {
    if (_cumulativeData.isEmpty) return 0;
    return _cumulativeData.first.x;
  }

  /// 获取最大X值
  double _getMaxX() {
    if (_cumulativeData.isEmpty) return 0;
    return _cumulativeData.last.x;
  }

  /// 获取最小Y值
  double _getMinY() {
    final allY = <double>[];
    allY.addAll(_cumulativeData.map((spot) => spot.y));
    if (_showBenchmark) allY.addAll(_benchmarkData.map((spot) => spot.y));
    return allY.isEmpty ? 0 : allY.reduce(math.min) * 0.98;
  }

  /// 获取最大Y值
  double _getMaxY() {
    final allY = <double>[];
    allY.addAll(_cumulativeData.map((spot) => spot.y));
    if (_showBenchmark) allY.addAll(_benchmarkData.map((spot) => spot.y));
    return allY.isEmpty ? 100 : allY.reduce(math.max) * 1.02;
  }

  /// 获取对比图最小Y值
  double _getComparisonMinY() {
    final allY = <double>[];
    allY.addAll(_cumulativeData.map((spot) => spot.y));
    if (_showComparison) allY.addAll(_comparisonData.map((spot) => spot.y));
    return allY.isEmpty ? 0 : allY.reduce(math.min) * 0.98;
  }

  /// 获取对比图最大Y值
  double _getComparisonMaxY() {
    final allY = <double>[];
    allY.addAll(_cumulativeData.map((spot) => spot.y));
    if (_showComparison) allY.addAll(_comparisonData.map((spot) => spot.y));
    return allY.isEmpty ? 100 : allY.reduce(math.max) * 1.02;
  }

  /// 构建网格数据
  FlGridData _buildGridData() {
    return FlGridData(
      show: true,
      drawVerticalLine: true,
      getDrawingVerticalLine: (value) {
        return FlLine(
          color: Colors.grey[300]!,
          strokeWidth: 0.5,
        );
      },
      drawHorizontalLine: true,
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: Colors.grey[300]!,
          strokeWidth: 0.5,
        );
      },
    );
  }

  /// 构建主图表标题数据
  FlTitlesData _buildMainTitlesData() {
    return FlTitlesData(
      show: true,
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: _calculateYInterval(),
          getTitlesWidget: (value, meta) {
            return Text(
              _formatCurrency(value),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.right,
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: _calculateXInterval(),
          getTitlesWidget: (value, meta) {
            final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
            return Text(
              '${date.month}/${date.day}',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            );
          },
        ),
      ),
      topTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            return Text(
              '净值 (元)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            );
          },
        ),
      ),
    );
  }

  /// 构建副图表标题数据
  FlTitlesData _buildSubTitlesData(String title) {
    return FlTitlesData(
      show: true,
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            if (title == '日收益率') {
              return Text(
                '${value.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.right,
              );
            } else {
              return Text(
                _formatCurrency(value),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.right,
              );
            }
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      topTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
    );
  }

  /// 构建主线图数据
  List<LineChartBarData> _buildMainLineBarsData() {
    final lines = <LineChartBarData>[];

    // 组合净值线
    lines.add(
      LineChartBarData(
        spots: _cumulativeData,
        isCurved: true,
        color: Colors.blue[700]!,
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: _showDataPoints ? _buildDotData(Colors.blue[700]!) : null,
        belowBarData: BarAreaData(
          show: true,
          color: Colors.blue[700]!.withOpacity(0.1),
        ),
      ),
    );

    // 基准线
    if (_showBenchmark && _benchmarkData.isNotEmpty) {
      lines.add(
        LineChartBarData(
          spots: _benchmarkData,
          isCurved: true,
          color: Colors.red[600]!,
          barWidth: 2,
          isStrokeCapRound: true,
          dashArray: [8, 4],
          dotData: null,
        ),
      );
    }

    return lines;
  }

  /// 构建对比图线数据
  List<LineChartBarData> _buildComparisonLineBarsData() {
    final lines = <LineChartBarData>[];

    // 组合净值线
    lines.add(
      LineChartBarData(
        spots: _cumulativeData,
        isCurved: true,
        color: Colors.blue[700]!,
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: null,
        belowBarData: BarAreaData(
          show: true,
          color: Colors.blue[700]!.withOpacity(0.05),
        ),
      ),
    );

    // 同类平均线
    if (_showComparison && _comparisonData.isNotEmpty) {
      lines.add(
        LineChartBarData(
          spots: _comparisonData,
          isCurved: true,
          color: Colors.green[600]!,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: null,
          belowBarData: BarAreaData(
            show: true,
            color: Colors.green[600]!.withOpacity(0.05),
          ),
        ),
      );
    }

    return lines;
  }

  /// 构建日收益率柱状图组
  List<BarChartGroupData> _buildDailyReturnBarGroups() {
    return _dailyReturnData.asMap().entries.map((entry) {
      final index = entry.key;
      final spot = entry.value;
      final color = _getDailyReturnColor(spot.y);

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: spot.y,
            color: color,
            width: 4,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(2),
              bottom: Radius.circular(2),
            ),
          ),
        ],
      );
    }).toList();
  }

  /// 构建点数据
  FlDotData _buildDotData(Color color) {
    return FlDotData(
      getDotPainter: (spot, percent, barData, index) {
        return FlDotCirclePainter(
          radius: 4,
          color: color,
          strokeWidth: 2,
          strokeColor: Colors.white,
        );
      },
    );
  }

  /// 构建触摸数据
  LineTouchData _buildLineTouchData() {
    return LineTouchData(
      touchTooltipData: LineTouchTooltipData(
        tooltipBgColor: Colors.black87,
        tooltipRoundedRadius: 6,
        getTooltipItems: (touchedSpots) {
          return touchedSpots.map((spot) {
            final value = spot.y;

            return LineTooltipItem(
              _formatCurrency(value),
              const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            );
          }).toList();
        },
      ),
      handleBuiltInTouches: true,
    );
  }

  /// 构建柱状图触摸数据
  BarTouchData _buildBarTouchData() {
    return BarTouchData(
      touchTooltipData: BarTouchTooltipData(
        tooltipBgColor: Colors.black87,
        tooltipRoundedRadius: 6,
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          final value = rod.toY;
          return BarTooltipItem(
            '${value.toStringAsFixed(2)}%',
            const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          );
        },
      ),
    );
  }

  /// 计算Y轴间隔
  double _calculateYInterval() {
    final range = _getMaxY() - _getMinY();
    return math.pow(10, (math.log(range) / math.log(10)).floor()) / 5;
  }

  /// 计算X轴间隔
  double _calculateXInterval() {
    final range = _getMaxX() - _getMinX();
    final days = range / (1000 * 60 * 60 * 24); // 转换为天数
    return math.max(1, (days / 5).ceil()) * 1000 * 60 * 60 * 24;
  }

  /// 获取日收益率颜色
  Color _getDailyReturnColor(double value) {
    if (value > 2.0) {
      return Colors.red[600]!;
    } else if (value > 0.0) {
      return Colors.green[600]!;
    } else if (value > -2.0) {
      return Colors.red[400]!;
    } else {
      return Colors.red[800]!;
    }
  }

  /// 格式化货币显示
  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '${(value / 10000).toStringAsFixed(0)}万';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}千';
    } else {
      return '¥${value.toStringAsFixed(0)}';
    }
  }

  /// 缩小
  void _zoomOut() {
    setState(() {
      _zoomLevel = math.max(0.5, _zoomLevel - 0.25);
    });
  }

  /// 重置缩放
  void _resetZoom() {
    setState(() {
      _zoomLevel = 1.0;
    });
  }

  /// 放大
  void _zoomIn() {
    setState(() {
      _zoomLevel = math.min(3.0, _zoomLevel + 0.25);
    });
  }
}
