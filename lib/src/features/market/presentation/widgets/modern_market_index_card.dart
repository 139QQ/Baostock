import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/widgets/gradient_container.dart';
import '../../../../core/theme/widgets/modern_data_display.dart';
import '../../../../core/theme/widgets/modern_ui_components.dart';
import '../../../../core/theme/design_tokens/app_colors.dart';
import '../../models/market_index_data.dart';
import 'index_change_indicator.dart';

/// 现代化市场指数卡片组件
///
/// 采用现代FinTech设计风格的市场指数展示卡片，包含：
/// - 渐变背景和毛玻璃效果
/// - 动态数据展示
/// - 平滑的动画交互
/// - 现代化的视觉层次
class ModernMarketIndexCard extends StatefulWidget {
  final MarketIndexData indexData;
  final VoidCallback? onTap;
  final MarketIndexCardStyle style;
  final bool enableAnimation;
  final Duration? animationDuration;

  const ModernMarketIndexCard({
    super.key,
    required this.indexData,
    this.onTap,
    this.style = MarketIndexCardStyle.normal,
    this.enableAnimation = true,
    this.animationDuration,
  });

  @override
  State<ModernMarketIndexCard> createState() => _ModernMarketIndexCardState();
}

class _ModernMarketIndexCardState extends State<ModernMarketIndexCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Color> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    if (!widget.enableAnimation) return;

    _animationController = AnimationController(
      duration: widget.animationDuration ?? const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _slideAnimation = Tween<double>(
      begin: 0.3,
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

    _colorAnimation = ColorTween(
      begin: Colors.white,
      end: _getCardBackgroundColor(),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    )) as Animation<Color>;

    _animationController.forward();
  }

  @override
  void dispose() {
    if (widget.enableAnimation) {
      _animationController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget cardContent = _buildCardContent(context);

    if (widget.enableAnimation) {
      return AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.translate(
              offset: Offset(0, (1 - _slideAnimation.value) * 20),
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: child,
              ),
            ),
          );
        },
        child: cardContent,
      );
    }

    return cardContent;
  }

  /// 构建卡片内容
  Widget _buildCardContent(BuildContext context) {
    final isCompact = widget.style == MarketIndexCardStyle.compact;

    return Container(
      margin: EdgeInsets.only(
        bottom: isCompact ? 8 : 16,
        left: 16,
        right: 16,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(isCompact ? 16 : 20),
          child: Container(
            padding: EdgeInsets.all(isCompact ? 16 : 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isCompact ? 16 : 20),
              gradient: _buildCardGradient(),
              boxShadow: [
                BoxShadow(
                  color: _getShadowColor().withOpacity(0.2),
                  blurRadius: isCompact ? 12 : 20,
                  offset: Offset(0, isCompact ? 6 : 10),
                ),
                if (widget.enableAnimation)
                  BoxShadow(
                    color: _getHighlightColor()
                        .withOpacity(0.4 * _animationController.value),
                    blurRadius: isCompact ? 8 : 12,
                    offset: Offset(0, 4),
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 顶部状态栏
                _buildStatusBar(context),

                const SizedBox(height: 16),

                // 指数信息
                _buildIndexInfo(context),

                if (!isCompact) ...[
                  const SizedBox(height: 20),
                  _buildMarketStats(context),
                ],

                const SizedBox(height: 12),

                // 价格和变化信息
                _buildPriceInfo(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建状态栏
  Widget _buildStatusBar(BuildContext context) {
    return Row(
      children: [
        // 指数图标和类型
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: _buildIconGradient(),
            boxShadow: [
              BoxShadow(
                color: _getCardBackgroundColor().withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            _getMarketIcon(),
            color: Colors.white,
            size: 20,
          ),
        ),

        const SizedBox(width: 12),

        // 指数名称和状态
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.indexData.name,
                      style: TextStyle(
                        fontSize: widget.style == MarketIndexCardStyle.compact
                            ? 16
                            : 18,
                        fontWeight: FontWeight.bold,
                        color: _getTextColor(),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // 市场状态标签
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: _getStatusColor().withOpacity(0.2),
                    ),
                    child: Text(
                      _getStatusText(),
                      style: TextStyle(
                        fontSize: 10,
                        color: _getStatusColor(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                widget.indexData.code,
                style: TextStyle(
                  fontSize: 12,
                  color: _getTextColor().withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建指数信息
  Widget _buildIndexInfo(BuildContext context) {
    final isCompact = widget.style == MarketIndexCardStyle.compact;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.15),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 实时状态指示器
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: widget.indexData.isRising
                  ? FinancialColors.positive
                  : widget.indexData.isFalling
                      ? FinancialColors.negative
                      : FinancialColors.neutral,
            ),
          ),

          if (widget.indexData.isRising) ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                Icons.trending_up_rounded,
                color: FinancialColors.positive,
                size: 16,
              ),
            ),
          ] else if (widget.indexData.isFalling) ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                Icons.trending_down_rounded,
                color: FinancialColors.negative,
                size: 16,
              ),
            ),
          ] else ...[
            Icon(
              Icons.trending_flat_rounded,
              color: FinancialColors.neutral,
              size: 16,
            ),
          ],

          const SizedBox(width: 8),

          // 数据质量指示器
          if (widget.indexData.qualityLevel != DataQualityLevel.excellent) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: _getQualityColor().withOpacity(0.2),
              ),
              child: Text(
                _getQualityText(),
                style: TextStyle(
                  fontSize: 10,
                  color: _getQualityColor(),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  /// 构建市场统计信息
  Widget _buildMarketStats(BuildContext context) {
    return Row(
      children: [
        // 开盘价
        _buildStatItem(
          context,
          '开盘',
          _formatDecimal(widget.indexData.openPrice),
          Icons.candlestick_chart_outlined,
        ),

        const SizedBox(width: 16),

        // 最高价
        _buildStatItem(
          context,
          '最高',
          _formatDecimal(widget.indexData.highPrice),
          Icons.arrow_upward_rounded,
        ),

        const SizedBox(width: 16),

        // 最低价
        _buildStatItem(
          context,
          '最低',
          _formatDecimal(widget.indexData.lowPrice),
          Icons.arrow_downward_rounded,
        ),

        const SizedBox(width: 16),

        // 成交量
        _buildStatItem(
          context,
          '成交量',
          _formatVolume(widget.indexData.volume),
          Icons.bar_chart_rounded,
        ),
      ],
    );
  }

  /// 构建统计项
  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withOpacity(0.1),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: Colors.white.withOpacity(0.8),
              size: 16,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建价格信息
  Widget _buildPriceInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '当前值',
          style: TextStyle(
            fontSize: 12,
            color: _getTextColor().withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            AnimatedNumberDisplay(
              value: widget.indexData.currentValue.toDouble(),
              isCurrency: true,
              decimalPlaces: 2,
              style: TextStyle(
                fontSize:
                    widget.style == MarketIndexCardStyle.compact ? 20 : 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              duration:
                  Duration(milliseconds: widget.enableAnimation ? 800 : 0),
              positiveColor: Colors.white,
              negativeColor: Colors.white,
              neutralColor: Colors.white,
            ),

            const SizedBox(width: 16),

            // 变化指示器
            IndexChangeIndicator(
              indexData: widget.indexData,
              style: widget.style == MarketIndexCardStyle.compact
                  ? IndexChangeIndicatorStyle.compact
                  : IndexChangeIndicatorStyle.detailed,
            ),
          ],
        ),
      ],
    );
  }

  /// 构建卡片渐变背景
  LinearGradient _buildCardGradient() {
    if (widget.indexData.isRising) {
      return FinancialGradients.upTrendGradient;
    } else if (widget.indexData.isFalling) {
      return FinancialGradients.downTrendGradient;
    }

    return const LinearGradient(
      colors: [Colors.grey, Colors.blueGrey],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// 构建图标渐变
  LinearGradient _buildIconGradient() {
    if (widget.indexData.isRising) {
      return const LinearGradient(
        colors: [Colors.red, Colors.orange],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (widget.indexData.isFalling) {
      return const LinearGradient(
        colors: [Colors.green, Colors.teal],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    return const LinearGradient(
      colors: [Colors.grey, Colors.blueGrey],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// 获取市场图标
  IconData _getMarketIcon() {
    final code = widget.indexData.code;

    if (code.contains('SH') || code.contains('000')) {
      return Icons.trending_up; // 上证指数
    } else if (code.contains('SZ') || code.contains('399')) {
      return Icons.show_chart; // 深证指数
    } else if (code.contains('HSI')) {
      return Icons.public; // 恒生指数
    } else if (code.contains('DJ') || code.contains('IXIC')) {
      return Icons.language; // 美股指数
    } else if (code.contains('000300')) {
      return Icons.equalizer_rounded; // 沪深300
    } else if (code.contains('000905')) {
      return Icons.equalizer_rounded; // 中证500
    } else if (code.contains('000016')) {
      return Icons.vpn_key_rounded; // 上证50
    }

    return Icons.analytics_rounded; // 默认图标
  }

  /// 获取卡片背景色
  Color _getCardBackgroundColor() {
    return widget.indexData.isRising
        ? FinancialColors.positive.withOpacity(0.05)
        : widget.indexData.isFalling
            ? FinancialColors.negative.withOpacity(0.05)
            : FinancialColors.neutral.withOpacity(0.05);
  }

  /// 获取阴影颜色
  Color _getShadowColor() {
    return widget.indexData.isRising
        ? FinancialColors.positive
        : widget.indexData.isFalling
            ? FinancialColors.negative
            : FinancialColors.neutral;
  }

  /// 获取高亮颜色
  Color _getHighlightColor() {
    return widget.indexData.isRising
        ? Colors.red
        : widget.indexData.isFalling
            ? Colors.green
            : Colors.blue;
  }

  /// 获取文本颜色
  Color _getTextColor() {
    return widget.indexData.isRising
        ? Colors.red
        : widget.indexData.isFalling
            ? Colors.green
            : Colors.blue;
  }

  /// 获取状态文本
  String _getStatusText() {
    switch (widget.indexData.marketStatus) {
      case MarketStatus.trading:
        return '交易中';
      case MarketStatus.preMarket:
        return '盘前';
      case MarketStatus.postMarket:
        return '盘后';
      case MarketStatus.closed:
        return '休市';
      case MarketStatus.holiday:
        return '节假日';
      case MarketStatus.unknown:
        return '未知';
    }
  }

  /// 获取状态颜色
  Color _getStatusColor() {
    switch (widget.indexData.marketStatus) {
      case MarketStatus.trading:
        return Colors.green;
      case MarketStatus.preMarket:
        return Colors.orange;
      case MarketStatus.postMarket:
        return Colors.purple;
      case MarketStatus.closed:
        return Colors.grey;
      case MarketStatus.holiday:
        return Colors.blue;
      case MarketStatus.unknown:
        return Colors.grey;
    }
  }

  /// 获取数据质量文本
  String _getQualityText() {
    switch (widget.indexData.qualityLevel) {
      case DataQualityLevel.excellent:
        return '优秀';
      case DataQualityLevel.good:
        return '良好';
      case DataQualityLevel.fair:
        return '一般';
      case DataQualityLevel.poor:
        return '较差';
      case DataQualityLevel.unknown:
        return '未知';
    }
  }

  /// 获取数据质量颜色
  Color _getQualityColor() {
    switch (widget.indexData.qualityLevel) {
      case DataQualityLevel.excellent:
        return Colors.green;
      case DataQualityLevel.good:
        return Colors.blue;
      case DataQualityLevel.fair:
        return Colors.orange;
      case DataQualityLevel.poor:
        return Colors.red;
      case DataQualityLevel.unknown:
        return Colors.grey;
    }
  }

  /// 格式化Decimal
  String _formatDecimal(Decimal value) {
    return value.toStringAsFixed(2);
  }

  /// 格式化成交量
  String _formatVolume(int volume) {
    if (volume >= 100000000) {
      return '${(volume / 100000000).toStringAsFixed(1)}亿';
    } else if (volume >= 10000) {
      return '${(volume / 10000).toStringAsFixed(1)}万';
    }
    return volume.toString();
  }
}

/// 现代化市场指数卡片样式
enum MarketIndexCardStyle {
  /// 紧凑样式
  compact,

  /// 标准样式
  normal,

  /// 详细样式
  detailed,
}
