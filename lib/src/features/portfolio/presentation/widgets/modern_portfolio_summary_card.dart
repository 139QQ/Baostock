import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens/app_colors.dart';
import '../../../../core/theme/widgets/gradient_container.dart';
import '../../domain/entities/portfolio_summary.dart';

/// 现代化投资组合汇总卡片
///
/// 展示投资组合的关键指标和状态，包含：
/// - 总资产和收益展示
/// - 风险等级评估
/// - 收益率趋势指示
/// - 现代化动画效果
/// - 响应式设计
class ModernPortfolioSummaryCard extends StatefulWidget {
  /// 投资组合汇总数据
  final PortfolioSummary? summary;

  /// 点击回调
  final VoidCallback? onTap;

  /// 刷新回调
  final VoidCallback? onRefresh;

  /// 是否启用动画效果
  final bool enableAnimation;

  /// 创建现代化投资组合汇总卡片
  const ModernPortfolioSummaryCard({
    super.key,
    this.summary,
    this.onTap,
    this.onRefresh,
    this.enableAnimation = true,
  });

  @override
  State<ModernPortfolioSummaryCard> createState() =>
      _ModernPortfolioSummaryCardState();
}

class _ModernPortfolioSummaryCardState extends State<ModernPortfolioSummaryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();

    if (widget.enableAnimation) {
      _animationController.forward();
    }
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
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
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: child,
            ),
          );
        },
        child: cardContent,
      );
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: cardContent,
    );
  }

  /// 构建卡片内容
  Widget _buildCardContent() {
    final summary = widget.summary;
    final totalAssets = summary?.totalAssets ?? 0.0;
    final totalProfit = summary?.totalReturnAmount ?? 0.0;
    final profitRate = summary?.totalReturnRate ?? 0.0;
    final riskLevel = _getRiskLevel(totalAssets, totalProfit);
    final isPositive = totalProfit >= 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            isPositive
                ? const Color(0xFF233997).withOpacity(0.95)
                : const Color(0xFFDC2626).withOpacity(0.95),
            isPositive
                ? const Color(0xFF5E7CFF).withOpacity(0.85)
                : const Color(0xFFEF4444).withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: isPositive
                ? const Color(0xFF233997).withOpacity(0.3)
                : const Color(0xFFDC2626).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 背景装饰
          _buildBackgroundDecoration(),

          // 主要内容
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildAssetsDisplay(totalAssets, totalProfit, profitRate),
                const SizedBox(height: 24),
                _buildProgressIndicators(profitRate),
                const SizedBox(height: 24),
                _buildRiskAssessment(riskLevel),
                const SizedBox(height: 20),
                _buildActionButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建背景装饰
  Widget _buildBackgroundDecoration() {
    return Positioned(
      top: -50,
      right: -50,
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.1),
        ),
      ),
    );
  }

  /// 构建头部
  Widget _buildHeader() {
    return Row(
      children: [
        GradientContainer(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.2),
              Colors.white.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          padding: const EdgeInsets.all(12),
          child: const Icon(
            Icons.account_balance_wallet,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '投资组合总览',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '智能分析您的投资表现',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (widget.onRefresh != null)
          GestureDetector(
            onTap: widget.onRefresh,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withOpacity(0.2),
              ),
              child: const Icon(
                Icons.refresh,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
      ],
    );
  }

  /// 构建资产显示
  Widget _buildAssetsDisplay(
      double totalAssets, double totalProfit, double profitRate) {
    final isPositive = totalProfit >= 0;

    return GradientContainer(
      gradient: LinearGradient(
        colors: [
          Colors.white.withOpacity(0.15),
          Colors.white.withOpacity(0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '总资产',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '¥${totalAssets.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '总收益',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.trending_up : Icons.trending_down,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${isPositive ? '+' : ''}¥${totalProfit.abs().toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
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
          const SizedBox(height: 16),
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withOpacity(0.2),
            ),
            child: Center(
              child: Text(
                '总收益率: ${isPositive ? '+' : ''}${profitRate.toStringAsFixed(2)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建进度指示器
  Widget _buildProgressIndicators(double profitRate) {
    return Column(
      children: [
        _buildProgressIndicator(
          '收益率',
          profitRate.clamp(-50.0, 50.0),
          '收益率进度',
          profitRate > 0 ? FinancialColors.positive : FinancialColors.negative,
        ),
        const SizedBox(height: 16),
        _buildProgressIndicator(
          '风险控制',
          _getRiskScore(profitRate),
          '风险评分',
          _getRiskScoreColor(profitRate),
        ),
      ],
    );
  }

  /// 构建进度指示器单个
  Widget _buildProgressIndicator(
      String label, double value, String description, Color color) {
    final displayValue = value.abs().clamp(0.0, 100.0);
    final progress = widget.enableAnimation ? _progressAnimation.value : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${displayValue.toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Colors.white.withOpacity(0.2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: displayValue / 100 * progress,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建风险评估
  Widget _buildRiskAssessment(String riskLevel) {
    return GradientContainer(
      gradient: LinearGradient(
        colors: [
          Colors.white.withOpacity(0.1),
          Colors.transparent,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            _getRiskIcon(riskLevel),
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '风险等级',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  riskLevel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white.withOpacity(0.2),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 1,
              ),
            ),
            child: const Center(
              child: Text(
                '查看详情',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 获取风险等级
  String _getRiskLevel(double totalAssets, double totalProfit) {
    final profitRate =
        totalAssets > 0 ? (totalProfit / totalAssets * 100) : 0.0;

    if (profitRate > 20) return '高风险高收益';
    if (profitRate > 10) return '中高风险';
    if (profitRate > 0) return '中等风险';
    if (profitRate > -10) return '中低风险';
    return '高风险低收益';
  }

  /// 获取风险评分 (0-100)
  double _getRiskScore(double profitRate) {
    if (profitRate > 20) return 80.0; // 高收益但风险也高
    if (profitRate > 10) return 60.0; // 中等风险
    if (profitRate > 0) return 40.0; // 低风险
    if (profitRate > -10) return 30.0; // 中低风险
    return 90.0; // 亏损严重，风险极高
  }

  /// 获取风险评分颜色
  Color _getRiskScoreColor(double profitRate) {
    if (profitRate > 20) return Colors.orange;
    if (profitRate > 10) return Colors.yellow;
    if (profitRate > 0) return Colors.green;
    if (profitRate > -10) return Colors.blue;
    return Colors.red;
  }

  /// 获取风险图标
  IconData _getRiskIcon(String riskLevel) {
    if (riskLevel.contains('高')) return Icons.warning_rounded;
    if (riskLevel.contains('中')) return Icons.info_rounded;
    return Icons.check_circle_rounded;
  }
}
