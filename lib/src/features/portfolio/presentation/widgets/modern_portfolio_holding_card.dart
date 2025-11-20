import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens/app_colors.dart';
import '../../../../core/theme/widgets/gradient_container.dart';
import '../../../../core/theme/widgets/modern_ui_components.dart';
import '../../domain/entities/portfolio_holding.dart';

/// 现代化持仓卡片组件
///
/// 展示单个基金持仓的详细信息，包含：
/// - 基金基本信息展示
/// - 收益率和价值显示
/// - 涨跌状态指示
/// - 现代化动画效果
/// - 交互式操作按钮
class ModernPortfolioHoldingCard extends StatefulWidget {
  /// 持仓数据
  final PortfolioHolding holding;

  /// 点击回调
  final VoidCallback? onTap;

  /// 卖出回调
  final VoidCallback? onSell;

  /// 加仓回调
  final VoidCallback? onBuyMore;

  /// 是否启用动画效果
  final bool enableAnimation;

  /// 创建现代化持仓卡片
  const ModernPortfolioHoldingCard({
    super.key,
    required this.holding,
    this.onTap,
    this.onSell,
    this.onBuyMore,
    this.enableAnimation = true,
  });

  @override
  State<ModernPortfolioHoldingCard> createState() =>
      _ModernPortfolioHoldingCardState();
}

class _ModernPortfolioHoldingCardState extends State<ModernPortfolioHoldingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.enableAnimation) {
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
    Widget cardContent = _buildCardContent();

    if (widget.enableAnimation) {
      cardContent = AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: child,
            ),
          );
        },
        child: cardContent,
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: cardContent,
    );
  }

  /// 构建卡片内容
  Widget _buildCardContent() {
    final profitRate = widget.holding.costValue > 0
        ? ((widget.holding.marketValue - widget.holding.costValue) /
            widget.holding.costValue *
            100)
        : 0.0;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: _isHovered
              ? LinearGradient(
                  colors: [
                    _getCardColor().withOpacity(0.8),
                    _getCardColor().withOpacity(0.4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    _getCardColor().withOpacity(0.6),
                    Colors.white,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          boxShadow: [
            if (_isHovered)
              BoxShadow(
                color: _getCardColor().withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: _getCardColor().withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFundHeader(),
              const SizedBox(height: 16),
              _buildValueSection(profitRate),
              const SizedBox(height: 16),
              _buildHoldingDetails(),
              const SizedBox(height: 16),
              _buildActionButtons(profitRate),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建基金头部信息
  Widget _buildFundHeader() {
    return Row(
      children: [
        // 基金图标/渐变圆圈
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: _isPositive
                ? FinancialGradients.upTrendGradient
                : FinancialGradients.downTrendGradient,
          ),
          child: Center(
            child: Text(
              widget.holding.fundCode.substring(0, 2),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.holding.fundName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: _getCardColor().withOpacity(0.2),
                    ),
                    child: Text(
                      widget.holding.fundCode,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getCardColor(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isPositive ? Icons.trending_up : Icons.trending_down,
                    size: 16,
                    color: _isPositive
                        ? FinancialColors.positive
                        : FinancialColors.negative,
                  ),
                ],
              ),
            ],
          ),
        ),
        // 收益率徽章
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: _isPositive
                ? FinancialGradients.upTrendGradient
                : FinancialGradients.downTrendGradient,
          ),
          child: Column(
            children: [
              Text(
                '${(_isPositive ? '+' : '')}${widget.holding.currentReturnPercentage.toStringAsFixed(2)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '日收益',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建价值部分
  Widget _buildValueSection(double profitRate) {
    return GradientContainer(
      gradient: LinearGradient(
        colors: [
          _isPositive
              ? FinancialColors.positive.withOpacity(0.1)
              : FinancialColors.negative.withOpacity(0.1),
          Colors.transparent,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '持仓市值',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  GradientText(
                    '¥${widget.holding.marketValue.toStringAsFixed(2)}',
                    gradient: _isPositive
                        ? FinancialGradients.upTrendGradient
                        : FinancialGradients.neutralGradient,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '总收益率',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  GradientText(
                    '${(profitRate > 0 ? '+' : '')}${profitRate.toStringAsFixed(2)}%',
                    gradient: profitRate > 0
                        ? FinancialGradients.upTrendGradient
                        : FinancialGradients.downTrendGradient,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建持仓详情
  Widget _buildHoldingDetails() {
    return Row(
      children: [
        Expanded(
          child: _buildDetailItem(
            '持仓份额',
            widget.holding.holdingAmount.toStringAsFixed(2),
            Icons.account_balance_wallet_outlined,
          ),
        ),
        Container(
          width: 1,
          height: 40,
          color: Colors.grey[300],
        ),
        Expanded(
          child: _buildDetailItem(
            '成本价',
            '¥${widget.holding.costNav.toStringAsFixed(4)}',
            Icons.paid_outlined,
          ),
        ),
        Container(
          width: 1,
          height: 40,
          color: Colors.grey[300],
        ),
        Expanded(
          child: _buildDetailItem(
            '当前价',
            '¥${widget.holding.currentNav.toStringAsFixed(4)}',
            Icons.trending_up_outlined,
          ),
        ),
      ],
    );
  }

  /// 构建详情项目
  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons(double profitRate) {
    return Row(
      children: [
        Expanded(
          child: ModernButton(
            text: '加仓',
            gradient: FinancialGradients.successGradient,
            onPressed: widget.onBuyMore,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ModernButton(
            text: '减仓',
            gradient: FinancialGradients.downTrendGradient,
            onPressed: widget.onSell,
          ),
        ),
        const SizedBox(width: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[100],
          ),
          child: IconButton(
            onPressed: () {
              // 显示详细信息
              _showHoldingDetails();
            },
            icon: Icon(
              Icons.info_outline,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  /// 获取卡片颜色
  Color _getCardColor() {
    final profitRate = widget.holding.costValue > 0
        ? ((widget.holding.marketValue - widget.holding.costValue) /
            widget.holding.costValue *
            100)
        : 0.0;

    if (profitRate > 5) return FinancialColors.positive;
    if (profitRate < -5) return FinancialColors.negative;
    return FinancialColors.neutral;
  }

  /// 判断是否盈利
  bool get _isPositive => widget.holding.marketValue > widget.holding.costValue;

  /// 显示持仓详情
  void _showHoldingDetails() {
    showDialog(
      context: context,
      builder: (context) => _buildHoldingDetailsDialog(),
    );
  }

  /// 构建持仓详情对话框
  Widget _buildHoldingDetailsDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const GradientText(
                  '持仓详情',
                  gradient: FinancialGradients.primaryGradient,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildDetailGrid(),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ModernButton(
                    text: '查看详细',
                    gradient: FinancialGradients.primaryGradient,
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onTap?.call();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建详情网格
  Widget _buildDetailGrid() {
    return Column(
      children: [
        _buildDetailRow('基金名称', widget.holding.fundName),
        _buildDetailRow('基金代码', widget.holding.fundCode),
        _buildDetailRow(
            '持仓份额', widget.holding.holdingAmount.toStringAsFixed(2)),
        _buildDetailRow('成本价', '¥${widget.holding.costNav.toStringAsFixed(4)}'),
        _buildDetailRow(
            '当前价', '¥${widget.holding.currentNav.toStringAsFixed(4)}'),
        _buildDetailRow(
            '成本价值', '¥${widget.holding.costValue.toStringAsFixed(2)}'),
        _buildDetailRow(
            '当前市值', '¥${widget.holding.marketValue.toStringAsFixed(2)}'),
        _buildDetailRow('收益率',
            '${widget.holding.currentReturnPercentage.toStringAsFixed(2)}%'),
      ],
    );
  }

  /// 构建详情行
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }
}
