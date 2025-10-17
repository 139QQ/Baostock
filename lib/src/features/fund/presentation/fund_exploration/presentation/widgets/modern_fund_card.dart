import 'package:flutter/material.dart';
import '../../domain/models/fund.dart';

/// 现代化基金卡片组件
///
/// 特点：
/// - 卡片式设计，视觉层次清晰
/// - 重要信息突出显示
/// - 现代美观的UI设计
/// - 支持多种显示模式
/// - 丰富的交互效果
class ModernFundCard extends StatefulWidget {
  final FundRanking fund;
  final int ranking;
  final String selectedPeriod;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onDetails;
  final bool isFavorite;
  final CardDisplayMode displayMode;

  const ModernFundCard({
    super.key,
    required this.fund,
    required this.ranking,
    this.selectedPeriod = '近1月',
    this.onTap,
    this.onFavorite,
    this.onDetails,
    this.isFavorite = false,
    this.displayMode = CardDisplayMode.compact,
  });

  @override
  State<ModernFundCard> createState() => _ModernFundCardState();
}

class _ModernFundCardState extends State<ModernFundCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
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

  void _onHoverChanged(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
    if (isHovered) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  double _getReturnForPeriod() {
    switch (widget.selectedPeriod) {
      case '日增长率':
        return widget.fund.dailyReturn;
      case '近1周':
        return widget.fund.return1W;
      case '近1月':
        return widget.fund.return1M;
      case '近3月':
        return widget.fund.return3M;
      case '近6月':
        return widget.fund.return6M;
      case '近1年':
        return widget.fund.return1Y;
      case '近2年':
        return widget.fund.return2Y;
      case '近3年':
        return widget.fund.return3Y;
      case '今年来':
        return widget.fund.returnYTD;
      case '成立来':
        return widget.fund.returnSinceInception;
      default:
        return widget.fund.return1Y;
    }
  }

  Color _getReturnColor(double returnValue) {
    if (returnValue > 0) {
      return const Color(0xFF10B981); // 绿色 - 上涨
    } else if (returnValue < 0) {
      return const Color(0xFFEF4444); // 红色 - 下跌
    } else {
      return const Color(0xFF6B7280); // 灰色 - 平盘
    }
  }

  Color _getFundTypeColor(String type) {
    switch (type) {
      case '股票型':
        return const Color(0xFFEF4444);
      case '债券型':
        return const Color(0xFF10B981);
      case '混合型':
        return const Color(0xFFF59E0B);
      case '货币型':
        return const Color(0xFF3B82F6);
      case '指数型':
        return const Color(0xFF8B5CF6);
      case 'QDII':
        return const Color(0xFFEC4899);
      default:
        return Colors.grey;
    }
  }

  Widget _buildRankingBadge() {
    final isTopThree = widget.ranking <= 3;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: isTopThree
            ? LinearGradient(
                colors: [
                  _getRankingColor(widget.ranking),
                  _getRankingColor(widget.ranking).withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isTopThree ? null : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        boxShadow: isTopThree
            ? [
                BoxShadow(
                  color: _getRankingColor(widget.ranking).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          widget.ranking.toString(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isTopThree ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Color _getRankingColor(int ranking) {
    switch (ranking) {
      case 1:
        return const Color(0xFFFFD700); // 金色
      case 2:
        return const Color(0xFFC0C0C0); // 银色
      case 3:
        return const Color(0xFFCD7F32); // 铜色
      default:
        return Colors.grey;
    }
  }

  Widget _buildFundInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 基金名称
        Text(
          widget.fund.fundName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
            height: 1.2,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),

        // 基金代码和类型
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                widget.fund.fundCode,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getFundTypeColor(widget.fund.fundType).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                widget.fund.fundType,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _getFundTypeColor(widget.fund.fundType),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReturnSection() {
    final returnValue = _getReturnForPeriod();
    final returnColor = _getReturnColor(returnValue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 收益率
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                returnColor.withOpacity(0.1),
                returnColor.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: returnColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Text(
            '${returnValue.toStringAsFixed(2)}%',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: returnColor,
            ),
          ),
        ),
        const SizedBox(height: 4),

        // 时间周期
        Text(
          widget.selectedPeriod,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildNavSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '单位净值',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.fund.unitNav.toStringAsFixed(4),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  /// 紧凑版基金信息
  Widget _buildCompactFundInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 基金名称 - 更紧凑的样式，更小字体
        Text(
          widget.fund.fundName,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
            height: 1.0,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 1),

        // 基金代码 - 只显示代码，去掉类型标签
        Text(
          widget.fund.fundCode,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  /// 紧凑版收益率显示
  Widget _buildCompactReturnSection() {
    final returnValue = _getReturnForPeriod();
    final returnColor = _getReturnColor(returnValue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 收益率 - 更紧凑，更小字体
        Text(
          '${returnValue.toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: returnColor,
          ),
        ),
        const SizedBox(height: 1),
        // 时间周期 - 更小的字体
        Text(
          _getCompactPeriodText(widget.selectedPeriod),
          style: TextStyle(
            fontSize: 8,
            color: Colors.grey.shade500,
          ),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }

  /// 紧凑版操作按钮
  Widget _buildCompactActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 收藏按钮 - 更小
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onFavorite,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: widget.isFavorite
                    ? Colors.red.shade50
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: widget.isFavorite
                      ? Colors.red.shade200
                      : Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: Icon(
                widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                size: 10,
                color: widget.isFavorite
                    ? Colors.red.shade500
                    : Colors.grey.shade600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 获取紧凑版期间文本
  String _getCompactPeriodText(String period) {
    switch (period) {
      case '日增长率':
        return '日';
      case '近1周':
        return '1W';
      case '近1月':
        return '1M';
      case '近3月':
        return '3M';
      case '近6月':
        return '6M';
      case '近1年':
        return '1Y';
      case '近2年':
        return '2Y';
      case '近3年':
        return '3Y';
      case '今年来':
        return 'YTD';
      case '成立来':
        return '总';
      default:
        return '1M';
    }
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 收藏按钮
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onFavorite,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: widget.isFavorite
                    ? Colors.red.shade50
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: widget.isFavorite
                      ? Colors.red.shade200
                      : Colors.grey.shade200,
                ),
              ),
              child: Icon(
                widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                size: 18,
                color: widget.isFavorite
                    ? Colors.red.shade500
                    : Colors.grey.shade600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // 详情按钮
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onDetails,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Icon(
                Icons.info_outline,
                size: 18,
                color: Colors.blue.shade600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHoverChanged(true),
      onExit: (_) => _onHoverChanged(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _isHovered
                          ? Colors.black.withOpacity(0.15)
                          : Colors.black.withOpacity(0.08),
                      blurRadius: _isHovered ? 12 : 6,
                      offset: Offset(0, _isHovered ? 4 : 2),
                    ),
                  ],
                  border: Border.all(
                    color: _isHovered
                        ? Colors.blue.shade200
                        : Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      // 排名徽章 - 缩小尺寸
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _getRankingColor(widget.ranking),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          widget.ranking.toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // 基金信息 - 使用Expanded占用剩余空间
                      Expanded(
                        child: _buildCompactFundInfo(),
                      ),
                      const SizedBox(width: 6),

                      // 收益率 - 紧凑显示
                      _buildCompactReturnSection(),
                      const SizedBox(width: 6),

                      // 操作按钮 - 缩小
                      _buildCompactActionButtons(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 卡片显示模式
enum CardDisplayMode {
  compact, // 紧凑模式
  normal, // 正常模式
  detailed, // 详细模式
}

/// 现代化基金卡片列表组件
class ModernFundCardList extends StatelessWidget {
  final List<FundRanking> funds;
  final String selectedPeriod;
  final Function(FundRanking, int)? onFundTap;
  final Function(FundRanking, int)? onFundFavorite;
  final Function(FundRanking, int)? onFundDetails;
  final Set<String> favoriteFunds;
  final CardDisplayMode displayMode;

  const ModernFundCardList({
    super.key,
    required this.funds,
    this.selectedPeriod = '近1月',
    this.onFundTap,
    this.onFundFavorite,
    this.onFundDetails,
    this.favoriteFunds = const {},
    this.displayMode = CardDisplayMode.compact,
  });

  @override
  Widget build(BuildContext context) {
    if (funds.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: funds.length,
      itemBuilder: (context, index) {
        final fund = funds[index];
        return ModernFundCard(
          fund: fund,
          ranking: index + 1,
          selectedPeriod: selectedPeriod,
          onTap: () => onFundTap?.call(fund, index + 1),
          onFavorite: () => onFundFavorite?.call(fund, index + 1),
          onDetails: () => onFundDetails?.call(fund, index + 1),
          isFavorite: favoriteFunds.contains(fund.fundCode),
          displayMode: displayMode,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 300,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              Icons.inbox_outlined,
              size: 40,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无基金数据',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请检查网络连接或稍后再试',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
