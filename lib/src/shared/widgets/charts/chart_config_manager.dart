/// 图表配置管理器
///
/// 负责管理 fl_chart 的基础配置、依赖注入和全局设置
/// 提供统一的图表配置接口，确保所有图表使用一致的配置
library chart_config_manager;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'models/chart_data.dart';
import 'chart_theme_manager.dart';

/// 图表配置管理器接口
abstract class IChartConfigManager {
  LineChartData getLineChartData(ChartConfig config, ChartTheme theme);
  BarChartData getBarChartData(ChartConfig config, ChartTheme theme);
  PieChartData getPieChartData(ChartConfig config, ChartTheme theme);

  /// 获取默认的线图触摸数据
  LineTouchData getLineTouchData(ChartConfig config, ChartTheme theme);

  /// 获取默认的柱状图触摸数据
  BarTouchData getBarTouchData(ChartConfig config, ChartTheme theme);

  /// 获取默认的饼图触摸数据
  PieTouchData getPieTouchData(ChartConfig config, ChartTheme theme);

  /// 获取网格数据
  FlGridData getGridData(ChartConfig config, ChartTheme theme);

  /// 获取标题数据
  FlTitlesData getTitlesData(ChartConfig config, ChartTheme theme);

  /// 获取边框数据
  FlBorderData getBorderData(ChartConfig config, ChartTheme theme);
}

/// 图表配置管理器实现
class ChartConfigManager implements IChartConfigManager {
  static ChartConfigManager get instance =>
      GetIt.instance<ChartConfigManager>();

  @override
  LineChartData getLineChartData(ChartConfig config, ChartTheme theme) {
    return LineChartData(
      gridData: getGridData(config, theme),
      titlesData: getTitlesData(config, theme),
      borderData: getBorderData(config, theme),
      lineBarsData: [],
      lineTouchData: getLineTouchData(config, theme),
      backgroundColor: config.backgroundColor ?? theme.backgroundColor,
      minY: null,
      maxY: null,
      clipData: FlClipData.all(),
    );
  }

  @override
  BarChartData getBarChartData(ChartConfig config, ChartTheme theme) {
    return BarChartData(
      gridData: getGridData(config, theme),
      titlesData: getTitlesData(config, theme),
      borderData: getBorderData(config, theme),
      barGroups: [],
      barTouchData: getBarTouchData(config, theme),
      alignment: BarChartAlignment.spaceAround,
      maxY: null,
      minY: null,
      groupsSpace: 16,
    );
  }

  @override
  PieChartData getPieChartData(ChartConfig config, ChartTheme theme) {
    return PieChartData(
      pieTouchData: getPieTouchData(config, theme),
      sectionsSpace: 2,
      centerSpaceRadius: 60,
      sections: [],
      startDegreeOffset: -90,
    );
  }

  @override
  LineTouchData getLineTouchData(ChartConfig config, ChartTheme theme) {
    if (!config.showTooltip) {
      return LineTouchData(enabled: false);
    }

    return LineTouchData(
      enabled: true,
      touchTooltipData: LineTouchTooltipData(
        tooltipBgColor: theme.primaryColor.withOpacity(0.9),
        tooltipRoundedRadius: 8,
        tooltipPadding: const EdgeInsets.all(8),
        tooltipMargin: 8,
        getTooltipItems: (spots) {
          return spots.map((spot) {
            return LineTooltipItem(
              '${spot.y.toStringAsFixed(2)}',
              theme.tooltipStyle.copyWith(
                color: Colors.white,
              ),
            );
          }).toList();
        },
      ),
      handleBuiltInTouches: true,
      touchSpotThreshold: 10,
    );
  }

  @override
  BarTouchData getBarTouchData(ChartConfig config, ChartTheme theme) {
    if (!config.showTooltip) {
      return BarTouchData(enabled: false);
    }

    return BarTouchData(
      enabled: true,
      touchTooltipData: BarTouchTooltipData(
        tooltipBgColor: theme.primaryColor.withOpacity(0.9),
        tooltipRoundedRadius: 8,
        tooltipPadding: const EdgeInsets.all(8),
        tooltipMargin: 8,
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          return BarTooltipItem(
            '${rod.toY.toStringAsFixed(2)}',
            theme.tooltipStyle.copyWith(
              color: Colors.white,
            ),
          );
        },
      ),
      touchExtraThreshold: const EdgeInsets.all(10),
    );
  }

  @override
  PieTouchData getPieTouchData(ChartConfig config, ChartTheme theme) {
    if (!config.showTooltip) {
      return PieTouchData(enabled: false);
    }

    return PieTouchData(
      enabled: true,
      touchCallback: (FlTouchEvent event, pieTouchResponse) {
        // 触摸回调处理
      },
    );
  }

  @override
  FlGridData getGridData(ChartConfig config, ChartTheme theme) {
    if (!config.showGrid) {
      return FlGridData(show: false);
    }

    return FlGridData(
      show: true,
      drawHorizontalLine: true,
      drawVerticalLine: true,
      horizontalInterval: 20,
      verticalInterval: 1,
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: theme.gridColor,
          strokeWidth: 1,
          dashArray: [5, 5],
        );
      },
      getDrawingVerticalLine: (value) {
        return FlLine(
          color: theme.gridColor,
          strokeWidth: 1,
          dashArray: [5, 5],
        );
      },
    );
  }

  @override
  FlTitlesData getTitlesData(ChartConfig config, ChartTheme theme) {
    return FlTitlesData(
      show: true,
      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: 1,
          getTitlesWidget: (value, meta) {
            return SideTitleWidget(
              axisSide: meta.axisSide,
              child: Text(
                value.toInt().toString(),
                style: theme.legendStyle.copyWith(
                  fontSize: 10,
                ),
              ),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 42,
          interval: 20,
          getTitlesWidget: (value, meta) {
            return SideTitleWidget(
              axisSide: meta.axisSide,
              child: Text(
                value.toInt().toString(),
                style: theme.legendStyle.copyWith(
                  fontSize: 10,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  FlBorderData getBorderData(ChartConfig config, ChartTheme theme) {
    return FlBorderData(
      show: true,
      border: Border.all(
        color: theme.gridColor.withOpacity(0.5),
        width: 1,
      ),
    );
  }

  /// 创建渐变色条
  static BarChartRodData createGradientBar({
    required double y,
    required double width,
    required List<Color> colors,
    BorderRadius? borderRadius,
  }) {
    return BarChartRodData(
      toY: y,
      width: width,
      borderRadius:
          borderRadius ?? const BorderRadius.vertical(top: Radius.circular(4)),
      gradient: LinearGradient(
        colors: colors,
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      ),
    );
  }

  /// 创建纯色条
  static BarChartRodData createSolidBar({
    required double y,
    required double width,
    required Color color,
    BorderRadius? borderRadius,
  }) {
    return BarChartRodData(
      toY: y,
      width: width,
      borderRadius:
          borderRadius ?? const BorderRadius.vertical(top: Radius.circular(4)),
      color: color,
    );
  }

  /// 创建渐变线
  static LineChartBarData createGradientLine({
    required List<FlSpot> spots,
    required List<Color> colors,
    bool isCurved = true,
    Color? color,
    double strokeWidth = 2,
    bool showDots = true,
  }) {
    return LineChartBarData(
      spots: spots,
      isCurved: isCurved,
      gradient: LinearGradient(
        colors: colors,
      ),
      barWidth: strokeWidth,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: showDots,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 3,
            color: color ?? colors.first,
            strokeWidth: 1,
            strokeColor: Colors.white,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: colors.map((color) => color.withOpacity(0.3)).toList(),
        ),
      ),
    );
  }

  /// 创建纯色线
  static LineChartBarData createSolidLine({
    required List<FlSpot> spots,
    required Color color,
    bool isCurved = true,
    double strokeWidth = 2,
    bool showDots = true,
  }) {
    return LineChartBarData(
      spots: spots,
      isCurved: isCurved,
      color: color,
      barWidth: strokeWidth,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: showDots,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 3,
            color: color,
            strokeWidth: 1,
            strokeColor: Colors.white,
          );
        },
      ),
      belowBarData: null,
    );
  }

  /// 创建饼图部分
  static PieChartSectionData createPieSection({
    required double value,
    required Color color,
    String? title,
    double radius = 60,
    double? titleStyleFontSize,
    FontWeight? titleStyleWeight,
    Color? titleStyleColor,
    BorderSide? borderSide,
  }) {
    return PieChartSectionData(
      color: color,
      value: value,
      title: title,
      radius: radius,
      titleStyle: TextStyle(
        fontSize: titleStyleFontSize ?? 12,
        fontWeight: titleStyleWeight ?? FontWeight.w600,
        color: titleStyleColor ?? Colors.white,
      ),
      borderSide: borderSide,
    );
  }
}
