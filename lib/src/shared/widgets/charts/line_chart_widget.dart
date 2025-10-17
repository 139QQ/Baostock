/// 折线图组件
///
/// 专用于基金净值走势图展示的折线图组件
/// 支持多数据系列、触摸交互、动画效果和响应式设计
library line_chart_widget;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'base_chart_widget.dart';
import 'models/chart_data.dart';
import 'chart_theme_manager.dart';
import 'chart_config_manager.dart';

/// 折线图组件
///
/// 用于展示基金净值走势、收益率变化等时间序列数据
/// 支持多数据系列对比、触摸交互和动态主题切换
class LineChartWidget extends BaseChartWidget {
  const LineChartWidget({
    super.key,
    required super.config,
    this.dataSeries = const [],
    this.onDataPointTap,
    this.showGradient = true,
    this.showDots = true,
    this.isCurved = true,
    this.lineWidth = 2.0,
    this.animationDuration = const Duration(milliseconds: 800),
    super.onInteraction,
    super.enableAnimation,
    super.customTheme,
  });

  /// 数据系列列表
  final List<ChartDataSeries> dataSeries;

  /// 数据点点击回调
  final Function(ChartPoint dataPoint, int seriesIndex)? onDataPointTap;

  /// 是否显示渐变色
  final bool showGradient;

  /// 是否显示数据点
  final bool showDots;

  /// 是否使用曲线
  final bool isCurved;

  /// 线条宽度
  final double lineWidth;

  /// 动画持续时间
  final Duration animationDuration;

  @override
  State<LineChartWidget> createState() => _LineChartWidgetState();
}

class _LineChartWidgetState extends BaseChartWidgetState<LineChartWidget> {
  late IChartConfigManager _configManager;
  List<LineChartBarData> _chartBars = [];

  @override
  void initState() {
    super.initState();
    _configManager = ChartDIContainer.get<IChartConfigManager>();
  }

  @override
  Future<void> initializeChart() async {
    // 基础初始化在父类中完成
    await _buildChartBars();
    if (mounted) {
      setChartState(ChartState.ready);
    }
  }

  @override
  Future<void> reloadChart() async {
    await _buildChartBars();
    if (mounted) {
      setChartState(ChartState.ready);
    }
  }

  /// 构建图表数据条
  Future<void> _buildChartBars() async {
    if (widget.dataSeries.isEmpty) {
      _chartBars = [];
      return;
    }

    _chartBars = widget.dataSeries.asMap().entries.map((entry) {
      final index = entry.key;
      final series = entry.value;

      final spots =
          series.data.map((point) => FlSpot(point.x, point.y)).toList();
      final color = series.color ?? theme.getColorForIndex(index);

      if (widget.showGradient && series.gradient != null) {
        return ChartConfigManager.createGradientLine(
          spots: spots,
          colors: series.gradient!.colors,
          isCurved: widget.isCurved,
          color: color,
          strokeWidth: widget.lineWidth,
          showDots: widget.showDots,
        );
      } else {
        return ChartConfigManager.createSolidLine(
          spots: spots,
          color: color,
          isCurved: widget.isCurved,
          strokeWidth: widget.lineWidth,
          showDots: widget.showDots,
        );
      }
    }).toList();
  }

  @override
  Widget buildChart(BuildContext context) {
    if (widget.dataSeries.isEmpty) {
      return _buildEmptyChart(context);
    }

    final lineChartData = _buildLineChartData();

    return LineChart(
      lineChartData,
      duration: widget.animationDuration,
    );
  }

  /// 构建空图表
  Widget _buildEmptyChart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            size: 64,
            color: theme.textColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无数据',
            style: theme.titleStyle.copyWith(
              color: theme.textColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请添加数据系列以显示图表',
            style: theme.legendStyle.copyWith(
              color: theme.textColor.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建折线图数据
  LineChartData _buildLineChartData() {
    return _configManager.getLineChartData(widget.config, theme).copyWith(
          lineBarsData: _chartBars,
          lineTouchData: _buildTouchData(),
          minY: _calculateMinY(),
          maxY: _calculateMaxY(),
        );
  }

  /// 构建触摸数据
  LineTouchData _buildTouchData() {
    return _configManager.getLineTouchData(widget.config, theme).copyWith(
      touchCallback: (FlTouchEvent event, lineTouchResponse) {
        if (event is FlTapUpEvent && lineTouchResponse != null) {
          final touchedSpot = lineTouchResponse.lineBarSpots?.firstOrNull;
          if (touchedSpot != null) {
            final seriesIndex = _chartBars.indexOf(touchedSpot.bar);
            if (seriesIndex >= 0 && seriesIndex < widget.dataSeries.length) {
              final dataPoint =
                  widget.dataSeries[seriesIndex].data[touchedSpot.spotIndex];
              _onDataPointTapped(dataPoint, seriesIndex);
            }
          }
        }
      },
    );
  }

  /// 计算最小Y值
  double _calculateMinY() {
    if (widget.dataSeries.isEmpty) return 0.0;

    final allYValues = widget.dataSeries
        .expand((series) => series.data.map((point) => point.y))
        .toList();

    if (allYValues.isEmpty) return 0.0;

    final minY = allYValues.reduce((a, b) => a < b ? a : b);
    // 添加10%的边距
    return minY - (minY * 0.1);
  }

  /// 计算最大Y值
  double _calculateMaxY() {
    if (widget.dataSeries.isEmpty) return 100.0;

    final allYValues = widget.dataSeries
        .expand((series) => series.data.map((point) => point.y))
        .toList();

    if (allYValues.isEmpty) return 100.0;

    final maxY = allYValues.reduce((a, b) => a > b ? a : b);
    // 添加10%的边距
    return maxY + (maxY * 0.1);
  }

  /// 处理数据点点击
  void _onDataPointTapped(ChartPoint dataPoint, int seriesIndex) {
    widget.onDataPointTap?.call(dataPoint, seriesIndex);

    final event = ChartInteractionEvent(
      type: ChartInteractionType.tap,
      dataPoint: dataPoint,
      seriesIndex: seriesIndex,
      pointIndex: widget.dataSeries[seriesIndex].data.indexOf(dataPoint),
    );

    triggerInteraction(event);
  }

  @override
  void onInteraction(ChartInteractionEvent event) {
    // 处理交互事件
    switch (event.type) {
      case ChartInteractionType.tap:
        _handleTap(event);
        break;
      case ChartInteractionType.longPress:
        _handleLongPress(event);
        break;
      default:
        break;
    }
  }

  /// 处理点击事件
  void _handleTap(ChartInteractionEvent event) {
    // 可以添加自定义的点击处理逻辑
  }

  /// 处理长按事件
  void _handleLongPress(ChartInteractionEvent event) {
    // 可以添加自定义的长按处理逻辑
  }

  @override
  void onConfigUpdated(ChartConfig oldConfig, ChartConfig newConfig) {
    // 配置更新时重新构建图表
    if (mounted) {
      _buildChartBars();
    }
  }

  @override
  void cleanupChart() {
    _chartBars.clear();
  }

  @override
  Map<String, dynamic> getChartDataStats() {
    if (widget.dataSeries.isEmpty) {
      return {
        'seriesCount': 0,
        'totalDataPoints': 0,
        'dataRanges': [],
      };
    }

    final stats = <String, dynamic>{
      'seriesCount': widget.dataSeries.length,
      'totalDataPoints': widget.dataSeries.fold<int>(
        0,
        (sum, series) => sum + series.data.length,
      ),
      'dataRanges': widget.dataSeries
          .map((series) => {
                'name': series.name,
                'yRange': series.yRange,
                'xRange': series.xRange,
                'dataPointCount': series.data.length,
              })
          .toList(),
    };

    return stats;
  }

  @override
  Map<String, dynamic> exportChartData() {
    final baseData = super.exportChartData();

    return {
      ...baseData,
      'chartType': 'line',
      'dataSeries': widget.dataSeries
          .map((series) => {
                'name': series.name,
                'data': series.data
                    .map((point) => {
                          'x': point.x,
                          'y': point.y,
                          'label': point.label,
                        })
                    .toList(),
                'color': series.color?.value,
                'showDots': series.showDots,
                'showArea': series.showArea,
                'lineWidth': series.lineWidth,
              })
          .toList(),
      'showGradient': widget.showGradient,
      'showDots': widget.showDots,
      'isCurved': widget.isCurved,
      'lineWidth': widget.lineWidth,
      'stats': getChartDataStats(),
    };
  }
}

/// 折线图样式配置
class LineChartStyle {
  const LineChartStyle({
    this.showGradient = true,
    this.showDots = true,
    this.isCurved = true,
    this.lineWidth = 2.0,
    this.dotRadius = 3.0,
    this.showArea = false,
    this.areaOpacity = 0.3,
    this.animationDuration = const Duration(milliseconds: 800),
  });

  final bool showGradient;
  final bool showDots;
  final bool isCurved;
  final double lineWidth;
  final double dotRadius;
  final bool showArea;
  final double areaOpacity;
  final Duration animationDuration;

  /// 创建金融数据专用的样式
  static LineChartStyle financial({
    bool showGradient = true,
    bool showDots = false,
  }) {
    return LineChartStyle(
      showGradient: showGradient,
      showDots: showDots,
      isCurved: true,
      lineWidth: 2.5,
      dotRadius: 2.0,
      showArea: true,
      areaOpacity: 0.2,
      animationDuration: const Duration(milliseconds: 1000),
    );
  }

  /// 创建简约样式
  static LineChartStyle minimal() {
    return LineChartStyle(
      showGradient: false,
      showDots: true,
      isCurved: false,
      lineWidth: 1.5,
      dotRadius: 2.5,
      showArea: false,
      areaOpacity: 0.0,
      animationDuration: const Duration(milliseconds: 500),
    );
  }

  /// 创建演示样式
  static LineChartStyle presentation() {
    return LineChartStyle(
      showGradient: true,
      showDots: true,
      isCurved: true,
      lineWidth: 3.0,
      dotRadius: 4.0,
      showArea: true,
      areaOpacity: 0.4,
      animationDuration: const Duration(milliseconds: 1200),
    );
  }
}
