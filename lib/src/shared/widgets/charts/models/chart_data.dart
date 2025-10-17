/// 图表数据模型
///
/// 提供图表组件的通用数据结构，支持不同类型的图表展示
/// 包含折线图、柱状图、饼图等所需的基础数据格式
library chart_data;

import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

/// 图表类型枚举
enum ChartType {
  line,
  bar,
  pie,
  scatter,
  radar,
}

/// 图表数据点
///
/// 表示图表中的单个数据点，包含坐标和可选的标签信息
class ChartPoint extends Equatable {
  const ChartPoint({
    required this.x,
    required this.y,
    this.label,
    this.color,
  });

  final double x;
  final double y;
  final String? label;
  final Color? color;

  @override
  List<Object?> get props => [x, y, label, color];

  @override
  String toString() => 'ChartPoint(x: $x, y: $y, label: $label)';

  /// 创建数据点的副本，可以覆盖特定属性
  ChartPoint copyWith({
    double? x,
    double? y,
    String? label,
    Color? color,
  }) {
    return ChartPoint(
      x: x ?? this.x,
      y: y ?? this.y,
      label: label ?? this.label,
      color: color ?? this.color,
    );
  }
}

/// 图表数据系列
///
/// 表示图表中的一个数据系列，包含多个数据点和系列样式信息
class ChartDataSeries extends Equatable {
  const ChartDataSeries({
    required this.data,
    required this.name,
    this.color,
    this.gradient,
    this.showDots = true,
    this.showArea = false,
    this.lineWidth = 2.0,
  });

  final List<ChartPoint> data;
  final String name;
  final Color? color;
  final Gradient? gradient;
  final bool showDots;
  final bool showArea;
  final double lineWidth;

  @override
  List<Object?> get props => [
        data,
        name,
        color,
        gradient,
        showDots,
        showArea,
        lineWidth,
      ];

  @override
  String toString() =>
      'ChartDataSeries(name: $name, dataPoints: ${data.length})';

  /// 获取数据点的Y值范围
  ({double min, double max}) get yRange {
    if (data.isEmpty) return (min: 0.0, max: 0.0);

    final yValues = data.map((point) => point.y).toList();
    final minY = yValues.reduce((a, b) => a < b ? a : b);
    final maxY = yValues.reduce((a, b) => a > b ? a : b);

    return (min: minY, max: maxY);
  }

  /// 获取数据点的X值范围
  ({double min, double max}) get xRange {
    if (data.isEmpty) return (min: 0.0, max: 0.0);

    final xValues = data.map((point) => point.x).toList();
    final minX = xValues.reduce((a, b) => a < b ? a : b);
    final maxX = xValues.reduce((a, b) => a > b ? a : b);

    return (min: minX, max: maxX);
  }
}

/// 饼图数据项
///
/// 专用于饼图的数据结构，包含值、标签和样式信息
class PieChartDataItem extends Equatable {
  const PieChartDataItem({
    required this.value,
    required this.label,
    this.color,
    this.description,
  });

  final double value;
  final String label;
  final Color? color;
  final String? description;

  @override
  List<Object?> get props => [value, label, color, description];

  /// 计算百分比
  double calculatePercentage(double total) {
    if (total == 0) return 0.0;
    return (value / total) * 100;
  }

  @override
  String toString() => 'PieChartDataItem(label: $label, value: $value)';
}

/// 图表配置
///
/// 包含图表的整体配置信息，如标题、尺寸、交互设置等
class ChartConfig extends Equatable {
  const ChartConfig({
    this.title,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = const EdgeInsets.all(8.0),
    this.backgroundColor,
    this.showGrid = true,
    this.showLegend = true,
    this.showTooltip = true,
    this.enableZoom = true,
    this.enablePan = true,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  final String? title;
  final double? width;
  final double? height;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final Color? backgroundColor;
  final bool showGrid;
  final bool showLegend;
  final bool showTooltip;
  final bool enableZoom;
  final bool enablePan;
  final Duration animationDuration;

  @override
  List<Object?> get props => [
        title,
        width,
        height,
        padding,
        margin,
        backgroundColor,
        showGrid,
        showLegend,
        showTooltip,
        enableZoom,
        enablePan,
        animationDuration,
      ];

  /// 创建配置的副本
  ChartConfig copyWith({
    String? title,
    double? width,
    double? height,
    EdgeInsets? padding,
    EdgeInsets? margin,
    Color? backgroundColor,
    bool? showGrid,
    bool? showLegend,
    bool? showTooltip,
    bool? enableZoom,
    bool? enablePan,
    Duration? animationDuration,
  }) {
    return ChartConfig(
      title: title ?? this.title,
      width: width ?? this.width,
      height: height ?? this.height,
      padding: padding ?? this.padding,
      margin: margin ?? this.margin,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      showGrid: showGrid ?? this.showGrid,
      showLegend: showLegend ?? this.showLegend,
      showTooltip: showTooltip ?? this.showTooltip,
      enableZoom: enableZoom ?? this.enableZoom,
      enablePan: enablePan ?? this.enablePan,
      animationDuration: animationDuration ?? this.animationDuration,
    );
  }
}

/// 图表交互事件
///
/// 定义图表中的用户交互事件类型
enum ChartInteractionType {
  tap,
  longPress,
  doubleTap,
  panStart,
  panUpdate,
  panEnd,
  scaleStart,
  scaleUpdate,
  scaleEnd,
}

/// 图表交互事件数据
///
/// 包含交互事件的详细信息
class ChartInteractionEvent extends Equatable {
  const ChartInteractionEvent({
    required this.type,
    this.position,
    this.dataPoint,
    this.seriesIndex,
    this.pointIndex,
    this.scaleFactor,
  });

  final ChartInteractionType type;
  final Offset? position;
  final ChartPoint? dataPoint;
  final int? seriesIndex;
  final int? pointIndex;
  final double? scaleFactor;

  @override
  List<Object?> get props => [
        type,
        position,
        dataPoint,
        seriesIndex,
        pointIndex,
        scaleFactor,
      ];

  @override
  String toString() =>
      'ChartInteractionEvent(type: $type, position: $position)';
}
