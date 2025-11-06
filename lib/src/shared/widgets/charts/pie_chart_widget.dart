/// 饼图组件
///
/// 专用于展示资产配置、行业分布等占比数据的可视化组件
/// 支持交互式扇区选择、百分比标签、图例显示等功能
library pie_chart_widget;

import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'base_chart_widget.dart';
import 'models/chart_data.dart';
import 'chart_theme_manager.dart';

/// 饼图扇区数据
class PieChartSector {
  const PieChartSector({
    required this.item,
    required this.startAngle,
    required this.sweepAngle,
    required this.percentage,
  });

  final PieChartDataItem item;
  final double startAngle;
  final double sweepAngle;
  final double percentage;

  /// 获取扇区中心角度
  double get centerAngle => startAngle + sweepAngle / 2;

  /// 检查点是否在扇区内（支持环形图）
  bool containsPoint(Offset point, Offset center, double radius,
      [double innerRadius = 0]) {
    final dx = point.dx - center.dx;
    final dy = point.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    // 检查距离是否在有效范围内（对于环形图）
    if (distance > radius || distance < innerRadius) return false;

    double angle = math.atan2(dy, dx);
    angle = angle < 0 ? angle + 2 * math.pi : angle;

    double start = startAngle;
    double end = startAngle + sweepAngle;

    // 标准化角度到 0-2π 范围
    while (start < 0) {
      start += 2 * math.pi;
    }
    while (end < 0) {
      end += 2 * math.pi;
    }
    while (angle < 0) {
      angle += 2 * math.pi;
    }

    if (start <= end) {
      return angle >= start && angle <= end;
    } else {
      return angle >= start || angle <= end;
    }
  }
}

/// 饼图组件
///
/// 支持以下功能：
/// - 交互式扇区选择和高亮
/// - 百分比标签显示
/// - 图例显示和交互
/// - 响应式设计
/// - 动画效果
class PieChartWidget extends BaseChartWidget {
  const PieChartWidget({
    super.key,
    required this.data,
    required super.config,
    this.onSectorSelected,
    this.onSectorHovered,
    this.showPercentageLabels = true,
    this.showLegend = true,
    this.legendPosition = LegendPosition.right,
    this.sectorSpacing = 2.0,
    this.innerRadius = 0.0,
    this.enableInteraction = true,
    this.selectedSectorIndex,
    super.onInteraction,
    super.enableAnimation = true,
    super.customTheme,
  });

  /// 饼图数据
  final List<PieChartDataItem> data;

  /// 扇区选择回调
  final Function(int index, PieChartDataItem item)? onSectorSelected;

  /// 扇区悬停回调
  final Function(int index, PieChartDataItem item)? onSectorHovered;

  /// 是否显示百分比标签
  final bool showPercentageLabels;

  /// 是否显示图例
  final bool showLegend;

  /// 图例位置
  final LegendPosition legendPosition;

  /// 扇区间距（度数）
  final double sectorSpacing;

  /// 内半径（用于创建环形图）
  final double innerRadius;

  /// 是否启用交互
  final bool enableInteraction;

  /// 当前选中的扇区索引
  final int? selectedSectorIndex;

  @override
  State<PieChartWidget> createState() => _PieChartWidgetState();
}

/// 图例位置枚举
enum LegendPosition {
  top,
  right,
  bottom,
  left,
}

class _PieChartWidgetState extends BaseChartWidgetState<PieChartWidget> {
  late List<PieChartSector> _sectors;
  int? _hoveredSectorIndex;
  int? _selectedSectorIndex;
  final Map<int, double> _sectorAnimations = {};

  @override
  void initState() {
    super.initState();
    _selectedSectorIndex = widget.selectedSectorIndex;
  }

  @override
  void onConfigUpdated(ChartConfig oldConfig, ChartConfig newConfig) {
    if (oldConfig != newConfig) {
      _calculateSectors();
    }
  }

  @override
  Future<void> initializeChart() async {
    _calculateSectors();
    _startProgressiveAnimation();
  }

  /// 开始渐进式动画
  Future<void> _startProgressiveAnimation() async {
    if (!widget.enableAnimation) return;

    for (int i = 0; i < _sectors.length; i++) {
      await Future.delayed(const Duration(milliseconds: 150)); // 每个扇区间隔

      if (mounted) {
        setState(() {
          _sectorAnimations[i] = 1.0;
        });
      }
    }
  }

  @override
  Future<void> reloadChart() async {
    _calculateSectors();
  }

  @override
  Widget buildChart(BuildContext context) {
    if (widget.data.isEmpty) {
      return _buildEmptyChart(context);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return _buildPieChartWithLegend(context, constraints);
      },
    );
  }

  @override
  void onInteraction(ChartInteractionEvent event) {
    switch (event.type) {
      case ChartInteractionType.tap:
        _handleTap(event.position);
        break;
      default:
        break;
    }
  }

  @override
  void cleanupChart() {
    _sectors.clear();
    _sectorAnimations.clear();
  }

  /// 计算扇区数据
  void _calculateSectors() {
    if (widget.data.isEmpty) {
      _sectors = [];
      return;
    }

    final total = widget.data.fold(0.0, (sum, item) => sum + item.value);
    if (total == 0) {
      _sectors = [];
      return;
    }

    _sectors = [];
    double currentAngle = -math.pi / 2; // 从顶部开始

    for (int i = 0; i < widget.data.length; i++) {
      final item = widget.data[i];
      final percentage = item.calculatePercentage(total);
      final sweepAngle = (percentage / 100) * 2 * math.pi;

      // 减去扇区间距
      final adjustedSweepAngle =
          math.max(0, sweepAngle - _degreesToRadians(widget.sectorSpacing));

      _sectors.add(PieChartSector(
        item: item,
        startAngle: currentAngle,
        sweepAngle: adjustedSweepAngle.toDouble(),
        percentage: percentage,
      ));

      // 为动画初始化扇区动画值
      _sectorAnimations[i] = 0.0;

      currentAngle += sweepAngle + _degreesToRadians(widget.sectorSpacing);
    }
  }

  /// 构建空图表显示
  Widget _buildEmptyChart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pie_chart_outline,
            size: 64,
            color: theme.textColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无数据',
            style: theme.legendStyle.copyWith(
              color: theme.textColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请添加数据以显示饼图',
            style: theme.legendStyle.copyWith(
              color: theme.textColor.withOpacity(0.3),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建带图例的饼图
  Widget _buildPieChartWithLegend(
      BuildContext context, BoxConstraints constraints) {
    switch (widget.legendPosition) {
      case LegendPosition.top:
      case LegendPosition.bottom:
        return Column(
          children: [
            if (widget.legendPosition == LegendPosition.top) ...[
              _buildLegend(),
              const SizedBox(height: 16),
            ],
            Expanded(child: _buildPieChart(context, constraints)),
            if (widget.legendPosition == LegendPosition.bottom) ...[
              const SizedBox(height: 16),
              _buildLegend(),
            ],
          ],
        );
      case LegendPosition.left:
      case LegendPosition.right:
        return Row(
          children: [
            if (widget.legendPosition == LegendPosition.left) ...[
              _buildLegend(),
              const SizedBox(width: 16),
            ],
            Expanded(child: _buildPieChart(context, constraints)),
            if (widget.legendPosition == LegendPosition.right) ...[
              const SizedBox(width: 16),
              _buildLegend(),
            ],
          ],
        );
    }
  }

  /// 构建饼图主体
  Widget _buildPieChart(BuildContext context, BoxConstraints constraints) {
    final size = _calculatePieSize(constraints);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    return SizedBox(
      width: size.width,
      height: size.height,
      child: MouseRegion(
        cursor: widget.enableInteraction
            ? SystemMouseCursors.click
            : MouseCursor.defer,
        child: GestureDetector(
          onTapUp: widget.enableInteraction
              ? (details) {
                  final localPosition = details.localPosition;
                  _handleTap(localPosition);
                }
              : null,
          child: CustomPaint(
            painter: _PieChartPainter(
              sectors: _sectors,
              center: center,
              radius: radius,
              innerRadius: radius * widget.innerRadius,
              theme: theme,
              hoveredIndex: _hoveredSectorIndex,
              selectedIndex: _selectedSectorIndex,
              showLabels: widget.showPercentageLabels,
              animationValue: animation.value,
              sectorAnimations: _sectorAnimations,
            ),
            size: Size(size.width, size.height),
          ),
        ),
      ),
    );
  }

  /// 构建图例
  Widget _buildLegend() {
    if (!widget.showLegend || widget.data.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 200), // 限制最大高度
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(8), // 减少内边距
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '图例',
                  style: theme.titleStyle.copyWith(fontSize: 12), // 减小字体
                ),
                const SizedBox(height: 4), // 减少间距
                ...widget.data.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isSelected = index == _selectedSectorIndex;
                  final isHovered = index == _hoveredSectorIndex;

                  return _buildLegendItem(index, item, isSelected, isHovered);
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建图例项
  Widget _buildLegendItem(
      int index, PieChartDataItem item, bool isSelected, bool isHovered) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: isSelected
            ? theme.primaryColor.withOpacity(0.15)
            : (isHovered ? Colors.grey.withOpacity(0.1) : null),
        border: isSelected
            ? Border.all(color: theme.primaryColor.withOpacity(0.3), width: 1)
            : null,
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _handleLegendTap(index),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? 12 : 10,
                height: isSelected ? 12 : 10,
                decoration: BoxDecoration(
                  color: item.color ?? theme.primaryColor,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(
                          color: theme.primaryColor,
                          width: 2,
                        )
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              color: (item.color ?? theme.primaryColor)
                                  .withOpacity(0.3),
                              blurRadius: 4)
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  item.label,
                  style: theme.legendStyle.copyWith(
                    color: isSelected ? theme.primaryColor : theme.textColor,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: isSelected ? 11 : 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_sectors[index].percentage.toStringAsFixed(1) ?? 0.0}%',
                style: theme.legendStyle.copyWith(
                  color: isSelected
                      ? theme.primaryColor
                      : theme.textColor.withOpacity(0.8),
                  fontSize: isSelected ? 11 : 10,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 计算饼图尺寸
  Size _calculatePieSize(BoxConstraints constraints) {
    double width = constraints.maxWidth;
    double height = constraints.maxHeight;

    // 根据图例位置调整尺寸
    if (widget.showLegend) {
      switch (widget.legendPosition) {
        case LegendPosition.left:
        case LegendPosition.right:
          width *= 0.7;
          break;
        case LegendPosition.top:
        case LegendPosition.bottom:
          height *= 0.8;
          break;
      }
    }

    final size = math.min(width, height);
    return Size(size, size);
  }

  /// 处理点击事件
  void _handleTap(Offset? position) {
    if (position == null) return;

    final size = context.size;
    if (size == null) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final innerRadius = radius * widget.innerRadius;

    for (int i = 0; i < _sectors.length; i++) {
      final sector = _sectors[i];
      if (sector.containsPoint(position, center, radius, innerRadius)) {
        _selectSector(i);
        break;
      }
    }
  }

  /// 处理悬停事件
  void _handleHover(Offset position) {
    final size = context.size;
    if (size == null) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final innerRadius = radius * widget.innerRadius;

    int? newHoveredIndex;
    for (int i = 0; i < _sectors.length; i++) {
      final sector = _sectors[i];
      if (sector.containsPoint(position, center, radius, innerRadius)) {
        newHoveredIndex = i;
        break;
      }
    }

    if (newHoveredIndex != _hoveredSectorIndex) {
      setState(() {
        _hoveredSectorIndex = newHoveredIndex;
      });

      if (newHoveredIndex != null) {
        widget.onSectorHovered
            ?.call(newHoveredIndex, widget.data[newHoveredIndex]);
      }
    }
  }

  /// 处理图例点击
  void _handleLegendTap(int index) {
    _selectSector(index);
  }

  /// 选择扇区
  void _selectSector(int index) {
    setState(() {
      _selectedSectorIndex = _selectedSectorIndex == index ? null : index;
    });

    widget.onSectorSelected?.call(index, widget.data[index]);
    triggerInteraction(ChartInteractionEvent(
      type: ChartInteractionType.tap,
      seriesIndex: index,
      dataPoint: ChartPoint(
        x: _sectors[index].centerAngle,
        y: _sectors[index].percentage,
      ),
    ));
  }

  /// 度数转弧度
  double _degreesToRadians(num degrees) {
    return degrees.toDouble() * math.pi / 180;
  }
}

/// 饼图画笔
class _PieChartPainter extends CustomPainter {
  const _PieChartPainter({
    required this.sectors,
    required this.center,
    required this.radius,
    required this.innerRadius,
    required this.theme,
    this.hoveredIndex,
    this.selectedIndex,
    this.showLabels = true,
    this.animationValue = 1.0,
    this.sectorAnimations = const {},
  });

  final List<PieChartSector> sectors;
  final Offset center;
  final double radius;
  final double innerRadius;
  final ChartTheme theme;
  final int? hoveredIndex;
  final int? selectedIndex;
  final bool showLabels;
  final double animationValue;
  final Map<int, double> sectorAnimations;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    for (int i = 0; i < sectors.length; i++) {
      final sector = sectors[i];
      final isSelected = i == selectedIndex;
      final isHovered = i == hoveredIndex;

      // 计算动画值：结合整体动画和单个扇区动画
      final sectorAnimationValue = sectorAnimations[i] ?? 0.0;
      final combinedAnimationValue = animationValue * sectorAnimationValue;

      // 如果扇区动画值为0，跳过绘制
      if (combinedAnimationValue == 0) continue;

      // 计算动画偏移
      final hoverOffset = isHovered ? 10.0 : 0.0;
      final selectOffset = isSelected ? 15.0 : 0.0;
      final totalOffset = (hoverOffset + selectOffset) * combinedAnimationValue;

      // 计算偏移后的中心点
      final angle = sector.centerAngle;
      final offsetCenter = Offset(
        center.dx + math.cos(angle) * totalOffset,
        center.dy + math.sin(angle) * totalOffset,
      );

      // 绘制扇区（带动画缩放效果）
      _drawSector(canvas, paint, sector, offsetCenter, isSelected, isHovered,
          animationScale: combinedAnimationValue);

      // 绘制标签（带动画）
      if (showLabels && combinedAnimationValue > 0.5) {
        _drawLabel(canvas, sector, offsetCenter,
            animationScale: combinedAnimationValue);
      }
    }
  }

  /// 绘制扇区
  void _drawSector(
    Canvas canvas,
    Paint paint,
    PieChartSector sector,
    Offset offsetCenter,
    bool isSelected,
    bool isHovered, {
    double animationScale = 1.0,
  }) {
    final color = sector.item.color ?? theme.primaryColor;

    // 设置颜色和透明度（包含动画）
    final opacity =
        animationScale * (isHovered ? 0.9 : (isSelected ? 0.95 : 0.8));
    paint.color = color.withOpacity(opacity);

    // 绘制扇区路径
    final path = Path();
    final startAngle = sector.startAngle;
    final sweepAngle = sector.sweepAngle * animationScale; // 动画缩放角度

    if (innerRadius > 0) {
      // 绘制环形扇区
      // 外圆弧
      path.addArc(
        Rect.fromCircle(center: offsetCenter, radius: radius * animationScale),
        startAngle,
        sweepAngle,
      );
      // 连接到内圆
      path.lineTo(
        offsetCenter.dx +
            math.cos(startAngle + sweepAngle) * innerRadius * animationScale,
        offsetCenter.dy +
            math.sin(startAngle + sweepAngle) * innerRadius * animationScale,
      );
      // 内圆弧（反向）
      path.addArc(
        Rect.fromCircle(
            center: offsetCenter, radius: innerRadius * animationScale),
        startAngle + sweepAngle,
        -sweepAngle,
      );
      // 连接到起点
      path.lineTo(
        offsetCenter.dx + math.cos(startAngle) * radius * animationScale,
        offsetCenter.dy + math.sin(startAngle) * radius * animationScale,
      );
      path.close();
    } else {
      // 绘制实心扇区
      path.moveTo(offsetCenter.dx, offsetCenter.dy);
      path.arcTo(
        Rect.fromCircle(center: offsetCenter, radius: radius * animationScale),
        startAngle,
        sweepAngle,
        false,
      );
      path.close();
    }

    canvas.drawPath(path, paint);

    // 绘制边框
    if (isSelected || isHovered) {
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = isSelected ? 3.0 : 2.0;
      paint.color = theme.textColor.withOpacity(0.3);
      canvas.drawPath(path, paint);
      paint.style = PaintingStyle.fill;
    }
  }

  /// 绘制标签
  void _drawLabel(
    Canvas canvas,
    PieChartSector sector,
    Offset offsetCenter, {
    double animationScale = 1.0,
  }) {
    if (sector.percentage < 5) return; // 太小的扇区不显示标签

    // 计算标签位置：对于环形图，标签应该在扇区的中间位置
    final labelRadius = innerRadius > 0
        ? (innerRadius + radius) / 2 // 环形图：使用内外半径的平均值
        : radius * 0.7; // 普通饼图：使用半径的70%

    final angle = sector.centerAngle;
    final labelPosition = Offset(
      offsetCenter.dx + math.cos(angle) * labelRadius * animationScale,
      offsetCenter.dy + math.sin(angle) * labelRadius * animationScale,
    );

    // 计算标签透明度
    final labelOpacity = (animationScale - 0.5) * 2.0; // 从0.5开始显示到完全显示
    if (labelOpacity <= 0) return;

    final textPainter = TextPainter(
      text: TextSpan(
        text: '${sector.percentage.toStringAsFixed(1)}%',
        style: theme.legendStyle.copyWith(
          color: Colors.white.withOpacity(labelOpacity),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    final textOffset = Offset(
      labelPosition.dx - textPainter.width / 2,
      labelPosition.dy - textPainter.height / 2,
    );

    // 绘制文字背景
    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final backgroundRect = Rect.fromLTWH(
      textOffset.dx - 4,
      textOffset.dy - 2,
      textPainter.width + 8,
      textPainter.height + 4,
    );

    final backgroundPath = Path()
      ..addRRect(
          RRect.fromRectAndRadius(backgroundRect, const Radius.circular(4)));
    canvas.drawPath(backgroundPath, backgroundPaint);

    // 绘制文字
    textPainter.paint(canvas, textOffset);
  }

  @override
  bool shouldRepaint(_PieChartPainter oldDelegate) {
    return oldDelegate.sectors != sectors ||
        oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.sectorAnimations != sectorAnimations;
  }
}
