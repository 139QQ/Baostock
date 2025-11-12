import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../models/market_index_data.dart';
import '../../models/index_change_data.dart';

/// 指数趋势图表
///
/// 显示指数历史价格趋势和变化分析的图表组件
class IndexTrendChart extends StatefulWidget {
  final List<MarketIndexData> historicalData;
  final List<IndexChangeData>? changeData;
  final String indexCode;
  final String indexName;
  final IndexTrendChartStyle style;
  final Duration? timeRange;
  final bool showTechnicalSignals;
  final bool showVolumeBars;
  final Function(DateTime)? onTimeRangeSelected;

  const IndexTrendChart({
    Key? key,
    required this.historicalData,
    this.changeData,
    required this.indexCode,
    required this.indexName,
    this.style = IndexTrendChartStyle.line,
    this.timeRange,
    this.showTechnicalSignals = true,
    this.showVolumeBars = false,
    this.onTimeRangeSelected,
  }) : super(key: key);

  @override
  State<IndexTrendChart> createState() => _IndexTrendChartState();
}

class _IndexTrendChartState extends State<IndexTrendChart>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  ChartTimeRange _currentTimeRange = ChartTimeRange.day1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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

    // 设置初始时间范围
    if (widget.timeRange != null) {
      _currentTimeRange = _determineTimeRange(widget.timeRange!);
    }

    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;

    setState(() {
      _currentTimeRange = ChartTimeRange.values[_tabController.index];
    });

    // 重新播放动画
    _animationController.reset();
    _animationController.forward();
  }

  ChartTimeRange _determineTimeRange(Duration duration) {
    if (duration.inDays >= 30) {
      return ChartTimeRange.month1;
    } else if (duration.inDays >= 7) {
      return ChartTimeRange.week1;
    } else if (duration.inHours >= 24) {
      return ChartTimeRange.day1;
    } else {
      return ChartTimeRange.hour1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildTabBar(),
        Expanded(
          child: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: _buildChart(),
              );
            },
          ),
        ),
        if (widget.showTechnicalSignals) _buildTechnicalSignals(),
      ],
    );
  }

  /// 构建头部
  Widget _buildHeader() {
    final latestData =
        widget.historicalData.isNotEmpty ? widget.historicalData.last : null;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.indexName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.indexCode,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                if (latestData != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        latestData.currentValue.toStringAsFixed(2),
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _getChangeColor(latestData),
                                ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _formatChange(latestData),
                        style: TextStyle(
                          color: _getChangeColor(latestData),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (widget.onTimeRangeSelected != null)
            IconButton(
              onPressed: () => _showTimeRangePicker(),
              icon: const Icon(Icons.date_range),
              tooltip: '选择时间范围',
            ),
        ],
      ),
    );
  }

  /// 构建标签栏
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(8),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        tabs: const [
          Tab(text: '1小时'),
          Tab(text: '1天'),
          Tab(text: '1周'),
          Tab(text: '1月'),
        ],
      ),
    );
  }

  /// 构建图表
  Widget _buildChart() {
    final filteredData =
        _filterDataByTimeRange(widget.historicalData, _currentTimeRange);

    if (filteredData.isEmpty) {
      return const Center(
        child: Text('暂无数据'),
      );
    }

    switch (widget.style) {
      case IndexTrendChartStyle.line:
        return _buildLineChart(filteredData);
      case IndexTrendChartStyle.candlestick:
        return _buildCandlestickChart(filteredData);
      case IndexTrendChartStyle.area:
        return _buildAreaChart(filteredData);
    }
  }

  /// 构建折线图
  Widget _buildLineChart(List<MarketIndexData> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: _buildGridData(),
          titlesData: _buildTitlesData(data),
          borderData: _buildBorderData(),
          lineBarsData: [
            _buildMainLine(data),
            if (_shouldShowAverageLine()) _buildAverageLine(data),
          ],
          lineTouchData: _buildLineTouchData(),
          minX: data.first.updateTime.millisecondsSinceEpoch.toDouble(),
          maxX: data.last.updateTime.millisecondsSinceEpoch.toDouble(),
          minY: _calculateMinY(data),
          maxY: _calculateMaxY(data),
        ),
      ),
    );
  }

  /// 构建面积图
  Widget _buildAreaChart(List<MarketIndexData> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: _buildGridData(),
          titlesData: _buildTitlesData(data),
          borderData: _buildBorderData(),
          lineBarsData: [
            _buildMainArea(data),
          ],
          lineTouchData: _buildLineTouchData(),
          minX: data.first.updateTime.millisecondsSinceEpoch.toDouble(),
          maxX: data.last.updateTime.millisecondsSinceEpoch.toDouble(),
          minY: _calculateMinY(data),
          maxY: _calculateMaxY(data),
        ),
      ),
    );
  }

  /// 构建K线图
  Widget _buildCandlestickChart(List<MarketIndexData> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: CustomPaint(
        painter: CandlestickPainter(
          data: data,
          context: context,
        ),
        child: Container(),
      ),
    );
  }

  /// 构建技术信号
  Widget _buildTechnicalSignals() {
    if (widget.changeData == null || widget.changeData!.isEmpty) {
      return const SizedBox.shrink();
    }

    final recentSignals = widget.changeData!
        .where((change) => change.technicalSignals.isNotEmpty)
        .take(5)
        .toList();

    if (recentSignals.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '技术信号',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          ...recentSignals.map((change) => _buildSignalItem(change)),
        ],
      ),
    );
  }

  /// 构建信号项
  Widget _buildSignalItem(IndexChangeData change) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            _getSignalIcon(change.technicalSignals.first.type),
            size: 16,
            color: _getSignalColor(change.technicalSignals.first.type),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              change.changeDescription,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Text(
            _formatTime(change.changeTime),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  /// 构建网格数据
  FlGridData _buildGridData() {
    return FlGridData(
      show: true,
      drawVerticalLine: true,
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: Colors.grey[300]!,
          strokeWidth: 1,
        );
      },
      getDrawingVerticalLine: (value) {
        return FlLine(
          color: Colors.grey[300]!,
          strokeWidth: 1,
        );
      },
    );
  }

  /// 构建标题数据
  FlTitlesData _buildTitlesData(List<MarketIndexData> data) {
    return FlTitlesData(
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
          interval: _calculateTimeInterval(data),
          getTitlesWidget: (value, meta) {
            final time = DateTime.fromMillisecondsSinceEpoch(value.toInt());
            return SideTitleWidget(
              axisSide: meta.axisSide,
              child: Text(
                _formatTimeAxis(time),
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 60,
          getTitlesWidget: (value, meta) {
            return SideTitleWidget(
              axisSide: meta.axisSide,
              child: Text(
                value.toStringAsFixed(0),
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 构建边框数据
  FlBorderData _buildBorderData() {
    return FlBorderData(
      show: true,
      border: Border.all(color: Colors.grey[300]!),
    );
  }

  /// 构建主线
  LineChartBarData _buildMainLine(List<MarketIndexData> data) {
    final spots = data.asMap().entries.map((entry) {
      return FlSpot(
        entry.value.updateTime.millisecondsSinceEpoch.toDouble(),
        entry.value.currentValue.toDouble(),
      );
    }).toList();

    final isPositive = data.last.isRising;
    final lineColor = isPositive ? Colors.red[600]! : Colors.green[600]!;

    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: lineColor,
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 2,
            color: lineColor,
            strokeWidth: 1,
            strokeColor: Colors.white,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        color: lineColor.withOpacity(0.1),
      ),
    );
  }

  /// 构建主面积
  LineChartBarData _buildMainArea(List<MarketIndexData> data) {
    final spots = data.asMap().entries.map((entry) {
      return FlSpot(
        entry.value.updateTime.millisecondsSinceEpoch.toDouble(),
        entry.value.currentValue.toDouble(),
      );
    }).toList();

    final isPositive = data.last.isRising;
    final lineColor = isPositive ? Colors.red[600]! : Colors.green[600]!;

    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: lineColor,
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: lineColor.withOpacity(0.3),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withOpacity(0.4),
            lineColor.withOpacity(0.1),
          ],
        ),
      ),
    );
  }

  /// 构建平均线
  LineChartBarData _buildAverageLine(List<MarketIndexData> data) {
    if (data.isEmpty) return LineChartBarData();

    final average =
        data.map((d) => d.currentValue.toDouble()).reduce((a, b) => a + b) /
            data.length;

    final spots = data
        .map((d) => FlSpot(
              d.updateTime.millisecondsSinceEpoch.toDouble(),
              average,
            ))
        .toList();

    return LineChartBarData(
      spots: spots,
      isCurved: false,
      color: Colors.blue,
      barWidth: 1,
      isStrokeCapRound: true,
      dotData: FlDotData(show: false),
      dashArray: [5, 5],
    );
  }

  /// 构建触摸数据
  LineTouchData _buildLineTouchData() {
    return LineTouchData(
      touchTooltipData: LineTouchTooltipData(
        tooltipBgColor: Colors.blueGrey[800],
        tooltipRoundedRadius: 8,
        getTooltipItems: (touchedSpots) {
          return touchedSpots.map((spot) {
            final time = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
            return LineTooltipItem(
              '${_formatTimeAxis(time)}\n${spot.y.toStringAsFixed(2)}',
              const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            );
          }).toList();
        },
      ),
      handleBuiltInTouches: true,
    );
  }

  /// 过滤时间范围数据
  List<MarketIndexData> _filterDataByTimeRange(
    List<MarketIndexData> data,
    ChartTimeRange range,
  ) {
    final now = DateTime.now();
    DateTime startTime;

    switch (range) {
      case ChartTimeRange.hour1:
        startTime = now.subtract(const Duration(hours: 1));
        break;
      case ChartTimeRange.day1:
        startTime = now.subtract(const Duration(days: 1));
        break;
      case ChartTimeRange.week1:
        startTime = now.subtract(const Duration(days: 7));
        break;
      case ChartTimeRange.month1:
        startTime = now.subtract(const Duration(days: 30));
        break;
    }

    return data.where((d) => d.updateTime.isAfter(startTime)).toList();
  }

  /// 计算最小Y值
  double _calculateMinY(List<MarketIndexData> data) {
    final values = data.map((d) => d.currentValue.toDouble()).toList();
    final minValue = values.reduce(math.min);
    return minValue - (minValue * 0.02); // 2% padding
  }

  /// 计算最大Y值
  double _calculateMaxY(List<MarketIndexData> data) {
    final values = data.map((d) => d.currentValue.toDouble()).toList();
    final maxValue = values.reduce(math.max);
    return maxValue + (maxValue * 0.02); // 2% padding
  }

  /// 计算时间间隔
  double _calculateTimeInterval(List<MarketIndexData> data) {
    if (data.isEmpty) return 1.0;

    final duration = data.last.updateTime.difference(data.first.updateTime);
    return duration.inMilliseconds.toDouble() / 5.0; // 5个刻度
  }

  /// 是否显示平均线
  bool _shouldShowAverageLine() {
    return widget.style == IndexTrendChartStyle.line;
  }

  /// 获取变化颜色
  Color _getChangeColor(MarketIndexData data) {
    if (data.isRising) return Colors.red[600]!;
    if (data.isFalling) return Colors.green[600]!;
    return Colors.grey[600]!;
  }

  /// 格式化变化
  String _formatChange(MarketIndexData data) {
    final change = data.changePercentage.toDouble();
    final sign = change >= 0 ? '+' : '';
    return '$sign${change.toStringAsFixed(2)}%';
  }

  /// 格式化时间
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// 格式化时间轴
  String _formatTimeAxis(DateTime time) {
    switch (_currentTimeRange) {
      case ChartTimeRange.hour1:
        return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
      case ChartTimeRange.day1:
        return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
      case ChartTimeRange.week1:
        return '${time.month}/${time.day}';
      case ChartTimeRange.month1:
        return '${time.month}/${time.day}';
    }
  }

  /// 获取信号图标
  IconData _getSignalIcon(SignalType type) {
    switch (type) {
      case SignalType.largeMove:
        return Icons.trending_up;
      case SignalType.volumeAnomaly:
        return Icons.bar_chart;
      case SignalType.breakout:
        return Icons.arrow_upward;
      case SignalType.breakdown:
        return Icons.arrow_downward;
      case SignalType.trendReversal:
        return Icons.swap_horiz;
      case SignalType.supportTest:
        return Icons.support;
      case SignalType.resistanceTest:
        return Icons.block;
    }
  }

  /// 获取信号颜色
  Color _getSignalColor(SignalType type) {
    switch (type) {
      case SignalType.largeMove:
        return Colors.orange;
      case SignalType.volumeAnomaly:
        return Colors.blue;
      case SignalType.breakout:
        return Colors.green;
      case SignalType.breakdown:
        return Colors.red;
      case SignalType.trendReversal:
        return Colors.purple;
      case SignalType.supportTest:
        return Colors.teal;
      case SignalType.resistanceTest:
        return Colors.indigo;
    }
  }

  /// 显示时间范围选择器
  void _showTimeRangePicker() {
    showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    ).then((range) {
      if (range != null && widget.onTimeRangeSelected != null) {
        widget.onTimeRangeSelected!(range.start);
      }
    });
  }
}

/// 图表时间范围
enum ChartTimeRange {
  hour1,
  day1,
  week1,
  month1,
}

/// 图表样式
enum IndexTrendChartStyle {
  line,
  candlestick,
  area,
}

/// K线图画笔
class CandlestickPainter extends CustomPainter {
  final List<MarketIndexData> data;
  final BuildContext context;

  CandlestickPainter({
    required this.data,
    required this.context,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 1.0;

    if (data.isEmpty) return;

    final width = size.width;
    const height = 400.0; // 固定高度
    const padding = 40.0;

    final chartWidth = width - 2 * padding;
    final chartHeight = height - 2 * padding;

    // 计算价格范围
    final prices = data.map((d) => d.currentValue.toDouble()).toList();
    final minPrice = prices.reduce(math.min);
    final maxPrice = prices.reduce(math.max);
    final priceRange = maxPrice - minPrice;

    final candleWidth = chartWidth / data.length * 0.6;

    // 绘制K线
    for (int i = 0; i < data.length; i++) {
      final candle = data[i];
      final x = padding + (i / (data.length - 1)) * chartWidth;

      // 计算价格位置
      final openY = padding +
          (1 - (candle.openPrice.toDouble() - minPrice) / priceRange) *
              chartHeight;
      final closeY = padding +
          (1 - (candle.currentValue.toDouble() - minPrice) / priceRange) *
              chartHeight;
      final highY = padding +
          (1 - (candle.highPrice.toDouble() - minPrice) / priceRange) *
              chartHeight;
      final lowY = padding +
          (1 - (candle.lowPrice.toDouble() - minPrice) / priceRange) *
              chartHeight;

      // 设置颜色
      final isRising = candle.currentValue > candle.previousClose;
      paint.color = isRising ? Colors.red : Colors.green;

      // 绘制影线
      canvas.drawLine(
        Offset(x, highY),
        Offset(x, lowY),
        paint,
      );

      // 绘制实体
      final bodyTop = math.min(openY, closeY);
      final bodyHeight = (closeY - openY).abs();

      canvas.drawRect(
        Rect.fromLTWH(
          x - candleWidth / 2,
          bodyTop,
          candleWidth,
          bodyHeight,
        ),
        paint,
      );
    }

    // 绘制坐标轴
    _drawAxes(canvas, size, padding, minPrice, maxPrice);
  }

  void _drawAxes(Canvas canvas, Size size, double padding, double minPrice,
      double maxPrice) {
    final axisPaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1.0;

    // Y轴
    canvas.drawLine(
      Offset(padding, padding),
      Offset(padding, size.height - padding),
      axisPaint,
    );

    // X轴
    canvas.drawLine(
      Offset(padding, size.height - padding),
      Offset(size.width - padding, size.height - padding),
      axisPaint,
    );

    // Y轴刻度
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final priceStep = (maxPrice - minPrice) / 5;
    for (int i = 0; i <= 5; i++) {
      final price = minPrice + i * priceStep;
      final y = size.height - padding - (i / 5) * (size.height - 2 * padding);

      textPainter.text = TextSpan(
        text: price.toStringAsFixed(0),
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(padding - 5 - textPainter.width, y - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CandlestickPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}
