import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/widgets/gradient_container.dart';
import '../../../../core/theme/design_tokens/app_colors.dart';
import '../../models/market_index_data.dart';

/// 现代化指数趋势图表组件
///
/// 展示市场指数的历史价格趋势，包含：
/// - 现代化图表设计
/// - 智能数据缩放
/// - 平滑的动画效果
/// - 交互式工具提示
class ModernIndexTrendChart extends StatefulWidget {
  /// 历史数据列表
  final List<Map<String, dynamic>> historicalData;

  /// 指数代码
  final String indexCode;

  /// 指数名称
  final String indexName;

  /// 指数数据（用于判断涨跌状态）
  final MarketIndexData indexData;

  /// 动画持续时间
  final Duration? animationDuration;

  /// 是否显示成交量
  final bool showVolume;

  /// 是否启用工具提示
  final bool enableTooltip;

  /// 是否启用缩放
  final bool enableZoom;

  const ModernIndexTrendChart({
    super.key,
    required this.historicalData,
    required this.indexCode,
    required this.indexName,
    required this.indexData,
    this.animationDuration,
    this.showVolume = true,
    this.enableTooltip = true,
    this.enableZoom = true,
  });

  @override
  State<ModernIndexTrendChart> createState() => _ModernIndexTrendChartState();
}

class _ModernIndexTrendChartState extends State<ModernIndexTrendChart>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _volumeAnimation;
  late Animation<double> _fadeAnimation;

  List<FlSpot> priceSpots = [];
  List<FlSpot> volumeSpots = [];
  double minY = 0;
  double maxY = 0;
  double maxVolume = 0;

  @override
  void initState() {
    super.initState();
    _processData();
    _initAnimations();
  }

  void _processData() {
    if (widget.historicalData.isEmpty) return;

    // 处理价格数据
    priceSpots = widget.historicalData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final price = (data['close'] as num).toDouble();
      return FlSpot(index.toDouble(), price);
    }).toList();

    // 计算价格范围
    final prices = priceSpots.map((spot) => spot.y).toList();
    minY =
        prices.isEmpty ? 0 : (prices.reduce((a, b) => a < b ? a : b) * 0.995);
    maxY =
        prices.isEmpty ? 0 : (prices.reduce((a, b) => a > b ? a : b) * 1.005);

    // 处理成交量数据（如果可用）
    if (widget.showVolume) {
      volumeSpots = widget.historicalData.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        final volume = (data['volume'] as num?)?.toDouble() ?? 0;
        return FlSpot(index.toDouble(), volume);
      }).toList();

      final volumes = volumeSpots.map((spot) => spot.y).toList();
      maxVolume = volumes.isEmpty ? 0 : volumes.reduce((a, b) => a > b ? a : b);
    }
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: widget.animationDuration ?? const Duration(milliseconds: 1200),
      vsync: this,
    );

    _volumeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (priceSpots.isEmpty) {
      return _buildEmptyState(context);
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Column(
            children: [
              // 图表标题和统计信息
              _buildChartHeader(context),

              const SizedBox(height: 16),

              // 主图表区域
              Expanded(
                child: GradientContainer.primary(
                  borderRadius: BorderRadius.circular(16),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // 价格图表
                      Expanded(
                        flex: widget.showVolume ? 3 : 4,
                        child: _buildPriceChart(context),
                      ),

                      // 成交量图表（如果启用）
                      if (widget.showVolume) ...[
                        const SizedBox(height: 16),
                        Expanded(
                          flex: 1,
                          child: _buildVolumeChart(context),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF6B7280), Color(0xFF9CA3AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无历史数据',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '等待数据加载...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建图表标题
  Widget _buildChartHeader(BuildContext context) {
    final now = DateTime.now();
    final startTime = widget.historicalData.isNotEmpty
        ? DateTime.tryParse(widget.historicalData.first['date'] as String) ??
            now
        : now;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 指数名称和代码
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.indexName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: NeutralColors.neutral800,
                  ),
                ),
                Text(
                  widget.indexCode,
                  style: TextStyle(
                    fontSize: 14,
                    color: NeutralColors.neutral600,
                  ),
                ),
              ],
            ),
          ),

          // 统计信息
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '数据周期',
                style: TextStyle(
                  fontSize: 12,
                  color: NeutralColors.neutral600,
                ),
              ),
              Text(
                _formatDateRange(startTime, now),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: NeutralColors.neutral800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建价格图表
  Widget _buildPriceChart(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.9),
      ),
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: _calculatePriceInterval(),
              getDrawingHorizontalLine: (value) => FlLine(
                color: NeutralColors.neutral200,
                strokeWidth: 1,
              ),
              getDrawingVerticalLine: (value) => FlLine(
                color: Colors.transparent,
              ),
            ),
            titlesData: FlTitlesData(
              rightTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: _calculatePriceInterval(),
                  reservedSize: 60,
                  getTitlesWidget: (value, meta) {
                    final text = _formatPrice(value);
                    return Text(
                      text,
                      style: TextStyle(
                        color: NeutralColors.neutral600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.right,
                    );
                  },
                ),
              ),
              topTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: _calculateTimeInterval(),
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    final text = _formatTime(value);
                    return Text(
                      text,
                      style: TextStyle(
                        color: NeutralColors.neutral600,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    );
                  },
                ),
              ),
              bottomTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: _calculatePriceInterval(),
                  reservedSize: 60,
                  getTitlesWidget: (value, meta) {
                    final text = _formatPrice(value);
                    return Text(
                      text,
                      style: TextStyle(
                        color: NeutralColors.neutral600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.left,
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: false,
            ),
            minX: 0,
            maxX: (priceSpots.length - 1).toDouble(),
            minY: minY,
            maxY: maxY,
            lineBarsData: [
              LineChartBarData(
                spots: priceSpots,
                isCurved: true,
                color: widget.indexData.isRising
                    ? FinancialColors.positive
                    : FinancialColors.negative,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: widget.enableTooltip ? 4 : 2,
                      color: Colors.white,
                      strokeColor: widget.indexData.isRising
                          ? FinancialColors.positive
                          : FinancialColors.negative,
                      strokeWidth: 2,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: _getAreaGradient(),
                ),
              ),
            ],
            lineTouchData: widget.enableTooltip
                ? LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: Colors.black87,
                      tooltipRoundedRadius: 8,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final value = spot.y;
                          return LineTooltipItem(
                            '¥${value.toStringAsFixed(2)}',
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  /// 构建成交量图表
  Widget _buildVolumeChart(BuildContext context) {
    if (volumeSpots.isEmpty) return const SizedBox();

    // 转换为BarChartGroupData列表
    final List<BarChartGroupData> barGroups =
        volumeSpots.asMap().entries.map((entry) {
      final index = entry.key;
      final spot = entry.value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: _volumeAnimation.value * spot.y,
            color: _getVolumeColor(spot.y / maxVolume),
            width: 8,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(2),
              bottom: Radius.circular(2),
            ),
          ),
        ],
      );
    }).toList();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[50],
      ),
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BarChart(
          BarChartData(
            barGroups: barGroups,
            gridData: FlGridData(
              show: false,
            ),
            titlesData: FlTitlesData(
              show: false,
            ),
            borderData: FlBorderData(
              show: false,
            ),
            barTouchData: widget.enableTooltip
                ? BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final volume = rod.toY;
                        return BarTooltipItem(
                          '成交量: ${_formatVolume(volume)}',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  )
                : null,
            maxY: maxVolume * 1.1,
          ),
        ),
      ),
    );
  }

  /// 获取线条颜色
  Color _getLineColor() {
    if (widget.indexData.isRising) {
      return FinancialColors.positive;
    } else if (widget.indexData.isFalling) {
      return FinancialColors.negative;
    }
    return FinancialColors.neutral;
  }

  /// 获取区域渐变
  LinearGradient _getAreaGradient() {
    final lineColor = _getLineColor();
    return LinearGradient(
      colors: [
        lineColor.withOpacity(0.3),
        lineColor.withOpacity(0.1),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  /// 获取成交量颜色
  Color _getVolumeColor(double ratio) {
    if (ratio > 0.8) {
      return FinancialColors.negative;
    } else if (ratio > 0.5) {
      return Colors.orange; // 替代 FinancialColors.warning
    } else {
      return FinancialColors.positive;
    }
  }

  /// 计算价格间隔
  double _calculatePriceInterval() {
    final range = maxY - minY;
    if (range <= 100) return 20;
    if (range <= 500) return 50;
    if (range <= 1000) return 100;
    if (range <= 5000) return 200;
    return 500;
  }

  /// 计算时间间隔
  double _calculateTimeInterval() {
    final dataLength = priceSpots.length;
    if (dataLength <= 10) return 2;
    if (dataLength <= 30) return 5;
    if (dataLength <= 100) return 10;
    return 20;
  }

  /// 格式化价格
  String _formatPrice(double value) {
    if (value >= 10000) {
      return '${(value / 10000).toStringAsFixed(2)}万';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(2);
  }

  /// 格式化时间
  String _formatTime(double value) {
    final index = value.toInt();
    if (index < priceSpots.length && widget.historicalData.isNotEmpty) {
      final date = widget.historicalData[index]['date'] as String?;
      if (date != null) {
        try {
          final dateTime = DateTime.parse(date);
          return DateFormat('MM/dd HH:mm').format(dateTime);
        } catch (e) {
          return 'T${index.toString()}';
        }
      }
    }
    return 'T${index.toString()}';
  }

  /// 格式化成交量
  String _formatVolume(double volume) {
    if (volume >= 100000000) {
      return '${(volume / 100000000).toStringAsFixed(1)}亿';
    } else if (volume >= 10000) {
      return '${(volume / 10000).toStringAsFixed(1)}万';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}k';
    }
    return volume.toStringAsFixed(0);
  }

  /// 格式化日期范围
  String _formatDateRange(DateTime start, DateTime end) {
    final startFormat = DateFormat('MM/dd');
    final endFormat = DateFormat('MM/dd');
    return '${startFormat.format(start)} - ${endFormat.format(end)}';
  }
}
