import 'package:flutter/material.dart';
import 'package:decimal/decimal.dart';
import 'dart:math' as math;

import '../../models/market_index_data.dart';
import '../../models/index_change_data.dart';

/// 指数变化指示器
///
/// 显示指数变化的可视化组件，包括涨跌颜色、百分比和动画效果
class IndexChangeIndicator extends StatefulWidget {
  final MarketIndexData indexData;
  final IndexChangeData? changeData;
  final IndexChangeIndicatorStyle style;
  final VoidCallback? onTap;

  const IndexChangeIndicator({
    Key? key,
    required this.indexData,
    this.changeData,
    this.style = IndexChangeIndicatorStyle.compact,
    this.onTap,
  }) : super(key: key);

  @override
  State<IndexChangeIndicator> createState() => _IndexChangeIndicatorState();
}

class _IndexChangeIndicatorState extends State<IndexChangeIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  @override
  void didUpdateWidget(IndexChangeIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 如果数据发生变化，重新播放动画
    if (oldWidget.indexData.currentValue != widget.indexData.currentValue ||
        oldWidget.changeData?.isSignificant !=
            widget.changeData?.isSignificant) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return GestureDetector(
          onTap: widget.onTap,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: _buildIndicator(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIndicator() {
    switch (widget.style) {
      case IndexChangeIndicatorStyle.compact:
        return _buildCompactIndicator();
      case IndexChangeIndicatorStyle.detailed:
        return _buildDetailedIndicator();
      case IndexChangeIndicatorStyle.minimal:
        return _buildMinimalIndicator();
      case IndexChangeIndicatorStyle.card:
        return _buildCardIndicator();
    }
  }

  /// 紧凑风格指示器
  Widget _buildCompactIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: _getBorderColor(),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getTrendIcon(),
            size: 16,
            color: _getTextColor(),
          ),
          const SizedBox(width: 4),
          Text(
            _formatPercentage(widget.indexData.changePercentage),
            style: TextStyle(
              color: _getTextColor(),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// 详细风格指示器
  Widget _buildDetailedIndicator() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(8),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                _getTrendIcon(),
                size: 20,
                color: _getTextColor(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.indexData.name,
                      style: TextStyle(
                        color: _getTextColor(),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '当前: ${widget.indexData.currentValue.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: _getTextColor().withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildChangeInfo(
                  '涨跌', widget.indexData.changeAmount.toStringAsFixed(2)),
              _buildChangeInfo(
                  '涨跌幅', _formatPercentage(widget.indexData.changePercentage)),
              if (widget.changeData?.isSignificant == true)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '显著',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          if (widget.changeData?.technicalSignals.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            _buildTechnicalSignals(),
          ],
        ],
      ),
    );
  }

  /// 极简风格指示器
  Widget _buildMinimalIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _getTrendIcon(),
          size: 12,
          color: _getTextColor(),
        ),
        const SizedBox(width: 2),
        Text(
          _formatPercentage(widget.indexData.changePercentage),
          style: TextStyle(
            color: _getTextColor(),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 卡片风格指示器
  Widget _buildCardIndicator() {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _getGradientColors(),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getTrendIcon(),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.indexData.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.indexData.currentValue.toStringAsFixed(2),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCardInfo(
                    '涨跌', widget.indexData.changeAmount.toStringAsFixed(2)),
                _buildCardInfo('涨跌幅',
                    _formatPercentage(widget.indexData.changePercentage)),
                _buildCardInfo('成交量', _formatVolume(widget.indexData.volume)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建变化信息
  Widget _buildChangeInfo(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: _getTextColor().withOpacity(0.6),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: _getTextColor(),
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  /// 构建卡片信息
  Widget _buildCardInfo(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// 构建技术信号
  Widget _buildTechnicalSignals() {
    final signals = widget.changeData!.technicalSignals.take(3).toList();

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: signals
          .map((signal) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getSignalColor(signal.type).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getSignalColor(signal.type).withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  signal.type.description,
                  style: TextStyle(
                    color: _getSignalColor(signal.type),
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ))
          .toList(),
    );
  }

  /// 获取趋势图标
  IconData _getTrendIcon() {
    if (widget.indexData.isRising) {
      return Icons.trending_up;
    } else if (widget.indexData.isFalling) {
      return Icons.trending_down;
    } else {
      return Icons.trending_flat;
    }
  }

  /// 获取背景颜色
  Color _getBackgroundColor() {
    if (widget.indexData.isRising) {
      return Colors.red.withOpacity(0.1);
    } else if (widget.indexData.isFalling) {
      return Colors.green.withOpacity(0.1);
    } else {
      return Colors.grey.withOpacity(0.1);
    }
  }

  /// 获取边框颜色
  Color _getBorderColor() {
    if (widget.indexData.isRising) {
      return Colors.red.withOpacity(0.3);
    } else if (widget.indexData.isFalling) {
      return Colors.green.withOpacity(0.3);
    } else {
      return Colors.grey.withOpacity(0.3);
    }
  }

  /// 获取文字颜色
  Color _getTextColor() {
    if (widget.indexData.isRising) {
      return Colors.red[700]!;
    } else if (widget.indexData.isFalling) {
      return Colors.green[700]!;
    } else {
      return Colors.grey[700]!;
    }
  }

  /// 获取渐变颜色
  List<Color> _getGradientColors() {
    if (widget.indexData.isRising) {
      return [Colors.red[400]!, Colors.red[600]!];
    } else if (widget.indexData.isFalling) {
      return [Colors.green[400]!, Colors.green[600]!];
    } else {
      return [Colors.grey[400]!, Colors.grey[600]!];
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
      case SignalType.breakdown:
        return Colors.purple;
      case SignalType.trendReversal:
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  /// 格式化百分比
  String _formatPercentage(Decimal percentage) {
    final value = percentage.toDouble();
    if (value >= 0) {
      return '+${value.toStringAsFixed(2)}%';
    } else {
      return '${value.toStringAsFixed(2)}%';
    }
  }

  /// 格式化成交量
  String _formatVolume(int volume) {
    if (volume >= 100000000) {
      return '${(volume / 100000000).toStringAsFixed(1)}亿';
    } else if (volume >= 10000) {
      return '${(volume / 10000).toStringAsFixed(1)}万';
    } else {
      return volume.toString();
    }
  }
}

/// 指数变化指示器风格
enum IndexChangeIndicatorStyle {
  /// 紧凑风格
  compact,

  /// 详细风格
  detailed,

  /// 极简风格
  minimal,

  /// 卡片风格
  card,
}

/// 指数变化指示器扩展功能
class IndexChangeIndicatorExtensions {
  /// 创建闪烁动画
  static Widget withBlink({
    required Widget child,
    required bool shouldBlink,
    Duration duration = const Duration(milliseconds: 800),
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1.0, end: 0.3),
      duration: duration,
      builder: (context, value, child) {
        return Opacity(
          opacity: shouldBlink ? value : 1.0,
          child: child,
        );
      },
      child: child,
    );
  }

  /// 创建脉冲效果
  static Widget withPulse({
    required Widget child,
    required bool shouldPulse,
    Duration duration = const Duration(milliseconds: 1000),
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1.0, end: 1.1),
      duration: duration,
      builder: (context, value, child) {
        return Transform.scale(
          scale: shouldPulse ? value : 1.0,
          child: child,
        );
      },
      child: child,
    );
  }

  /// 创建震动效果
  static Widget withShake({
    required Widget child,
    required bool shouldShake,
    Duration duration = const Duration(milliseconds: 500),
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      builder: (context, value, child) {
        final offset = shouldShake
            ? Offset(math.sin(value * math.pi * 4) * 5, 0)
            : Offset.zero;
        return Transform.translate(
          offset: offset,
          child: child,
        );
      },
      child: child,
    );
  }
}
