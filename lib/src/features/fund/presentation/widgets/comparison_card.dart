import 'package:flutter/material.dart';
import '../../domain/entities/comparison_result.dart';

/// 基金对比卡片组件
///
/// 用于滑块式对比界面，单只基金一个卡片
class ComparisonCard extends StatefulWidget {
  /// 对比数据
  final FundComparisonData comparisonData;

  /// 排名
  final int ranking;

  /// 总基金数量
  final int totalFunds;

  /// 点击回调
  final VoidCallback? onTap;

  /// 详情回调
  final VoidCallback? onDetail;

  /// 收藏回调
  final VoidCallback? onFavorite;

  /// 对比回调
  final VoidCallback? onCompare;

  /// 是否已收藏
  final bool isFavorite;

  /// 是否在对比中
  final bool isInComparison;

  const ComparisonCard({
    super.key,
    required this.comparisonData,
    required this.ranking,
    required this.totalFunds,
    this.onTap,
    this.onDetail,
    this.onFavorite,
    this.onCompare,
    this.isFavorite = false,
    this.isInComparison = false,
  });

  @override
  State<ComparisonCard> createState() => _ComparisonCardState();
}

class _ComparisonCardState extends State<ComparisonCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _handleTapDown(),
      onTapUp: (_) => _handleTapUp(),
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Card(
              elevation: 8,
              shadowColor: Colors.black.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: _getRankingColor().withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      _getRankingColor().withOpacity(0.05),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 顶部基本信息
                    _buildHeaderSection(),

                    // 中部关键指标
                    Expanded(child: _buildMetricsSection()),

                    // 底部操作按钮
                    _buildActionSection(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getRankingColor().withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 排名和收藏
          Row(
            children: [
              _buildRankingBadge(),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.comparisonData.fundName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E40AF),
                            fontSize: 14,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${widget.comparisonData.fundCode} • ${widget.comparisonData.fundType}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ),
              _buildFavoriteButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankingBadge() {
    final color = _getRankingColor();
    final icon = _getRankingIcon();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 12,
          ),
          const SizedBox(width: 3),
          Text(
            '#${widget.ranking}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return GestureDetector(
      onTap: widget.onFavorite,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: widget.isFavorite ? Colors.red.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          widget.isFavorite ? Icons.favorite : Icons.favorite_border,
          color: widget.isFavorite ? Colors.red.shade500 : Colors.grey.shade500,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildMetricsSection() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 收益率指标
          _buildReturnMetric(),
          const SizedBox(height: 12),

          // 风险等级指标
          _buildRiskMetric(),
          const SizedBox(height: 12),

          // 手续费指标
          _buildFeeMetric(),
          const SizedBox(height: 12),

          // 夏普比率指标
          _buildSharpeMetric(),
        ],
      ),
    );
  }

  Widget _buildReturnMetric() {
    final returnValue = widget.comparisonData.totalReturn;
    final isPositive = returnValue >= 0;
    final returnPercentage = (returnValue * 100).toStringAsFixed(2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              isPositive ? Icons.trending_up : Icons.trending_down,
              color: isPositive ? Colors.green : Colors.red,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              '收益率',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            Text(
              '$returnPercentage%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isPositive ? Colors.green : Colors.red,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: (returnValue + 1).clamp(0.0, 2.0) / 2.0, // normalize to 0-1
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(
            isPositive ? Colors.green : Colors.red,
          ),
          borderRadius: BorderRadius.circular(4),
          minHeight: 6,
        ),
      ],
    );
  }

  Widget _buildRiskMetric() {
    final riskLevel = widget.comparisonData.volatility;
    final riskColor = _getRiskColor(riskLevel);
    final riskText = _getRiskText(riskLevel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              Icons.warning,
              color: riskColor,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              '风险等级',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            Text(
              riskText,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: riskColor,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: List.generate(5, (index) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 2),
                height: 6,
                decoration: BoxDecoration(
                  color: index < (riskLevel * 2).clamp(0.0, 5.0)
                      ? riskColor
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFeeMetric() {
    // 使用最大回撤作为费用指标展示
    final maxDrawdown = widget.comparisonData.maxDrawdown;
    final drawdownText = (maxDrawdown * 100).toStringAsFixed(2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(
              Icons.account_balance,
              color: Colors.orange,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              '最大回撤',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            Text(
              '$drawdownText%',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.2),
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: maxDrawdown.clamp(0.0, 0.5) * 2, // normalize to 0-1
            child: Container(
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSharpeMetric() {
    final sharpeRatio = widget.comparisonData.sharpeRatio;
    final sharpeText = sharpeRatio.toStringAsFixed(2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(
              Icons.pie_chart,
              color: Colors.purple,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              '夏普比率',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            Text(
              sharpeText,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.purple,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.2),
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor:
                (sharpeRatio.clamp(-2.0, 4.0) + 2.0) / 6.0, // normalize to 0-1
            child: Container(
              decoration: BoxDecoration(
                color: Colors.purple,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: widget.onDetail,
              icon: const Icon(Icons.info_outline, size: 14),
              label: const Text('详情', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 6),
                minimumSize: Size.zero,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: widget.onCompare,
              icon: const Icon(Icons.compare_arrows, size: 14),
              label: const Text('对比', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isInComparison
                    ? Colors.grey.shade400
                    : Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 6),
                minimumSize: Size.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankingColor() {
    if (widget.ranking <= 3) return Colors.amber;
    if (widget.ranking <= 10) return Colors.blue;
    return Colors.grey;
  }

  IconData _getRankingIcon() {
    if (widget.ranking == 1) return Icons.looks_one;
    if (widget.ranking == 2) return Icons.looks_two;
    if (widget.ranking == 3) return Icons.looks_3;
    if (widget.ranking <= 10) return Icons.star;
    return Icons.info;
  }

  Color _getRiskColor(double riskLevel) {
    if (riskLevel <= 0.15) return Colors.green;
    if (riskLevel <= 0.25) return Colors.orange;
    return Colors.red;
  }

  String _getRiskText(double riskLevel) {
    if (riskLevel <= 0.15) return '低风险';
    if (riskLevel <= 0.25) return '中风险';
    return '高风险';
  }

  void _handleTapDown() {
    _animationController.forward();
  }

  void _handleTapUp() {
    _animationController.reverse();
  }

  void _handleTapCancel() {
    _animationController.reverse();
  }
}
