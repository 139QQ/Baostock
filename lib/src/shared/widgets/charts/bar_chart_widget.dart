/// 柱状图组件
///
/// 专用于基金收益率对比、资产配置等数据展示的柱状图组件
/// 支持单系列/多系列数据、动态颜色、分组显示和触摸交互
library bar_chart_widget;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'base_chart_widget.dart';
import 'models/chart_data.dart';
import 'chart_config_manager.dart';
import 'chart_di_container.dart';

/// 柱状图组件
///
/// 用于展示基金收益率对比、不同时间段业绩表现等分类数据
/// 支持分组柱状图、堆叠柱状图、渐变色彩和触摸交互
class BarChartWidget extends BaseChartWidget {
  const BarChartWidget({
    super.key,
    required super.config,
    this.dataSeries = const [],
    this.onBarTap,
    this.showGradient = true,
    this.barWidth = 16.0,
    this.borderRadius = 4.0,
    this.groupSpacing = 16.0,
    this.alignment = BarChartAlignment.spaceAround,
    this.maxBarWidth = 100.0,
    this.animationDuration = const Duration(milliseconds: 800),
    super.onInteraction,
    super.enableAnimation,
    super.customTheme,
  });

  /// 数据系列列表
  final List<ChartDataSeries> dataSeries;

  /// 柱子点击回调
  final Function(ChartPoint dataPoint, int seriesIndex, int barIndex)? onBarTap;

  /// 是否显示渐变色
  final bool showGradient;

  /// 柱子宽度
  final double barWidth;

  /// 圆角半径
  final double borderRadius;

  /// 组间距
  final double groupSpacing;

  /// 对齐方式
  final BarChartAlignment alignment;

  /// 最大柱子宽度
  final double maxBarWidth;

  /// 动画持续时间
  final Duration animationDuration;

  @override
  State<BarChartWidget> createState() => _BarChartWidgetState();
}

class _BarChartWidgetState extends BaseChartWidgetState<BarChartWidget> {
  late IChartConfigManager _configManager;
  List<BarChartGroupData> _chartGroups = [];

  @override
  void initState() {
    super.initState();
    _configManager = ChartDIContainer.get<IChartConfigManager>();
  }

  @override
  Future<void> initializeChart() async {
    // 基础初始化在父类中完成
    await _buildChartGroups();
    if (mounted) {
      setChartState(ChartState.ready);
    }
  }

  @override
  Future<void> reloadChart() async {
    await _buildChartGroups();
    if (mounted) {
      setChartState(ChartState.ready);
    }
  }

  /// 构建图表组数据
  Future<void> _buildChartGroups() async {
    if (widget.dataSeries.isEmpty) {
      _chartGroups = [];
      return;
    }

    // 获取所有X轴位置的索引
    final allXValues = widget.dataSeries
        .expand((series) => series.data.map((point) => point.x))
        .toSet()
        .toList()
      ..sort();

    _chartGroups = allXValues.asMap().entries.map((entry) {
      final xIndex = entry.key;
      final xValue = entry.value;

      // 为每个X位置创建柱状图组
      final bars = <BarChartRodData>[];

      for (int seriesIndex = 0;
          seriesIndex < widget.dataSeries.length;
          seriesIndex++) {
        final series = widget.dataSeries[seriesIndex];

        // 查找对应X值的数据点
        final dataPoint = series.data.firstWhere(
          (point) => point.x == xValue,
          orElse: () => ChartPoint(x: xValue, y: 0),
        );

        final color = series.color ?? theme.getColorForIndex(seriesIndex);

        if (widget.showGradient && series.gradient != null) {
          bars.add(ChartConfigManager.createGradientBar(
            y: dataPoint.y,
            width: widget.barWidth,
            colors: series.gradient!.colors,
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(widget.borderRadius)),
          ));
        } else {
          bars.add(ChartConfigManager.createSolidBar(
            y: dataPoint.y,
            width: widget.barWidth,
            color: color,
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(widget.borderRadius)),
          ));
        }
      }

      return BarChartGroupData(
        x: xIndex.toInt(),
        barRods: bars,
        barsSpace: widget.groupSpacing / widget.dataSeries.length,
      );
    }).toList();
  }

  @override
  Widget buildChart(BuildContext context) {
    if (widget.dataSeries.isEmpty) {
      return _buildEmptyChart(context);
    }

    final barChartData = _buildBarChartData();

    return BarChart(
      barChartData,
    );
  }

  /// 构建空图表
  Widget _buildEmptyChart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart,
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

  /// 构建柱状图数据
  BarChartData _buildBarChartData() {
    return _configManager.getBarChartData(widget.config, theme).copyWith(
          barGroups: _chartGroups,
          barTouchData: _buildTouchData(),
          minY: _calculateMinY(),
          maxY: _calculateMaxY(),
          alignment: widget.alignment,
          groupsSpace: widget.groupSpacing,
        );
  }

  /// 构建触摸数据
  BarTouchData _buildTouchData() {
    return _configManager.getBarTouchData(widget.config, theme).copyWith(
      touchCallback: (FlTouchEvent event, barTouchResponse) {
        if (event is FlTapUpEvent &&
            barTouchResponse != null &&
            barTouchResponse.spot != null) {
          final touchedSpot = barTouchResponse.spot!;
          final groupIndex = touchedSpot.touchedBarGroupIndex;
          final rodIndex = touchedSpot.touchedRodDataIndex;

          if (groupIndex >= 0 &&
              groupIndex < _chartGroups.length &&
              rodIndex >= 0 &&
              rodIndex < widget.dataSeries.length) {
            // 获取所有X值以找到对应的实际X坐标
            final allXValues = widget.dataSeries
                .expand((series) => series.data.map((point) => point.x))
                .toSet()
                .toList()
              ..sort();

            if (groupIndex < allXValues.length) {
              final xValue = allXValues[groupIndex];
              final series = widget.dataSeries[rodIndex];
              final dataPoint = series.data.firstWhere(
                (point) => point.x == xValue,
                orElse: () => ChartPoint(x: xValue, y: 0),
              );

              _onBarTapped(dataPoint, rodIndex, groupIndex);
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
    // 如果最小值大于0，从0开始显示
    return minY > 0 ? 0.0 : minY - (minY.abs() * 0.1);
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
    return maxY + (maxY.abs() * 0.1);
  }

  /// 处理柱子点击
  void _onBarTapped(ChartPoint dataPoint, int seriesIndex, int groupIndex) {
    widget.onBarTap?.call(dataPoint, seriesIndex, groupIndex);

    final event = ChartInteractionEvent(
      type: ChartInteractionType.tap,
      dataPoint: dataPoint,
      seriesIndex: seriesIndex,
      pointIndex: groupIndex,
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
    if (event.dataPoint != null) {
      // 显示点击的数据点信息
      _showDataPointDialog(event.dataPoint!);
    }
  }

  /// 处理长按事件
  void _handleLongPress(ChartInteractionEvent event) {
    // 可以添加自定义的长按处理逻辑
  }

  /// 显示数据点对话框
  void _showDataPointDialog(ChartPoint dataPoint) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('数据详情'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('X值: ${dataPoint.x.toStringAsFixed(2)}'),
            Text('Y值: ${dataPoint.y.toStringAsFixed(2)}'),
            if (dataPoint.label != null) Text('标签: ${dataPoint.label!}'),
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

  @override
  void onConfigUpdated(ChartConfig oldConfig, ChartConfig newConfig) {
    // 配置更新时重新构建图表
    if (mounted) {
      _buildChartGroups();
    }
  }

  @override
  void cleanupChart() {
    _chartGroups.clear();
  }

  @override
  Map<String, dynamic> getChartDataStats() {
    if (widget.dataSeries.isEmpty) {
      return {
        'seriesCount': 0,
        'totalDataPoints': 0,
        'totalGroups': 0,
        'dataRanges': [],
      };
    }

    final allXValues = widget.dataSeries
        .expand((series) => series.data.map((point) => point.x))
        .toSet()
        .length;

    final stats = <String, dynamic>{
      'seriesCount': widget.dataSeries.length,
      'totalDataPoints': widget.dataSeries.fold<int>(
        0,
        (sum, series) => sum + series.data.length,
      ),
      'totalGroups': allXValues,
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
      'chartType': 'bar',
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
                'gradient':
                    series.gradient?.colors.map((c) => c.value).toList(),
              })
          .toList(),
      'showGradient': widget.showGradient,
      'barWidth': widget.barWidth,
      'borderRadius': widget.borderRadius,
      'groupSpacing': widget.groupSpacing,
      'alignment': widget.alignment.toString(),
      'maxBarWidth': widget.maxBarWidth,
      'stats': getChartDataStats(),
    };
  }
}

/// 柱状图样式配置
class BarChartStyle {
  const BarChartStyle({
    this.showGradient = true,
    this.barWidth = 16.0,
    this.borderRadius = 4.0,
    this.groupSpacing = 16.0,
    this.maxBarWidth = 100.0,
    this.alignment = BarChartAlignment.spaceAround,
    this.animationDuration = const Duration(milliseconds: 800),
  });

  final bool showGradient;
  final double barWidth;
  final double borderRadius;
  final double groupSpacing;
  final double maxBarWidth;
  final BarChartAlignment alignment;
  final Duration animationDuration;

  /// 创建金融数据专用的样式
  static BarChartStyle financial({
    bool showGradient = true,
    double barWidth = 20.0,
  }) {
    return const BarChartStyle(
      showGradient: true,
      barWidth: 20.0,
      borderRadius: 6.0,
      groupSpacing: 12.0,
      maxBarWidth: 80.0,
      alignment: BarChartAlignment.spaceAround,
      animationDuration: Duration(milliseconds: 1000),
    );
  }

  /// 创建简约样式
  static BarChartStyle minimal() {
    return const BarChartStyle(
      showGradient: false,
      barWidth: 12.0,
      borderRadius: 2.0,
      groupSpacing: 8.0,
      maxBarWidth: 60.0,
      alignment: BarChartAlignment.center,
      animationDuration: Duration(milliseconds: 500),
    );
  }

  /// 创建演示样式
  static BarChartStyle presentation() {
    return const BarChartStyle(
      showGradient: true,
      barWidth: 24.0,
      borderRadius: 8.0,
      groupSpacing: 20.0,
      maxBarWidth: 120.0,
      alignment: BarChartAlignment.spaceAround,
      animationDuration: Duration(milliseconds: 1200),
    );
  }
}
