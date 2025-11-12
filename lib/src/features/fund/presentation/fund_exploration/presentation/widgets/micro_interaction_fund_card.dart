import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/models/fund_ranking.dart';

/// 微动交互基金卡片
///
/// 带有细腻的动画效果、触觉反馈和手势操作
class MicroInteractionFundCard extends StatefulWidget {
  final FundRanking fundRanking;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onCompareToggle;

  const MicroInteractionFundCard({
    super.key,
    required this.fundRanking,
    this.onTap,
    this.onFavoriteToggle,
    this.onCompareToggle,
  });

  @override
  State<MicroInteractionFundCard> createState() =>
      _MicroInteractionFundCardState();
}

class _MicroInteractionFundCardState extends State<MicroInteractionFundCard>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late AnimationController _slideController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isPressed = false;
  bool _isHovered = false;
  bool _isFavorite = false;
  bool _isComparing = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.elasticOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.05, 0.0),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotationController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
    _scaleController.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    _scaleController.reverse();
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _scaleController.reverse();
  }

  void _handleLongPress() {
    _rotationController.forward().then((_) {
      _rotationController.reverse();
    });
    HapticFeedback.mediumImpact();
    // TODO: 显示详细信息
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    _slideController.forward().then((_) {
      _slideController.reverse();
    });
    HapticFeedback.selectionClick();
    widget.onFavoriteToggle?.call();
  }

  void _toggleCompare() {
    setState(() {
      _isComparing = !_isComparing;
    });
    HapticFeedback.selectionClick();
    widget.onCompareToggle?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _slideAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.translate(
            offset: _slideAnimation.value * (_isFavorite ? 10 : 0),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onLongPress: _handleLongPress,
        child: MouseRegion(
          onEnter: (_) {
            setState(() {
              _isHovered = true;
            });
          },
          onExit: (_) {
            setState(() {
              _isHovered = false;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  _getCardColor().withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_isHovered ? 0.15 : 0.08),
                  blurRadius: _isHovered ? 20 : 10,
                  offset: Offset(0, _isHovered ? 8 : 4),
                ),
                if (_isPressed)
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 2),
                  ),
              ],
              border: Border.all(
                color: _getCardColor().withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                // 背景装饰
                _buildBackgroundDecoration(),

                // 主要内容
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 头部区域
                      _buildHeader(),
                      const SizedBox(height: 16),

                      // 基金名称
                      _buildFundName(),
                      const SizedBox(height: 8),

                      // 基金类型
                      _buildFundType(),
                      const Spacer(),

                      // 收益率显示
                      _buildReturnRate(),
                      const SizedBox(height: 12),

                      // 底部操作栏
                      _buildActionButtons(),
                    ],
                  ),
                ),

                // 热门标签
                if (widget.fundRanking.isHot) _buildHotTag(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundDecoration() {
    return Positioned(
      top: -20,
      right: -20,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _isHovered ? 0.1 : 0.05,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getCardColor(),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // 基金公司logo占位符
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _getCardColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.account_balance_rounded,
            color: _getCardColor(),
            size: 16,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            widget.fundRanking.fundCompany,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // 排名标识
        if (widget.fundRanking.rank <= 10)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber[400]!,
                  Colors.amber[600]!,
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'TOP${widget.fundRanking.rank}',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFundName() {
    return Text(
      widget.fundRanking.fundName,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
        letterSpacing: -0.2,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildFundType() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getCardColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        widget.fundRanking.shortType,
        style: TextStyle(
          fontSize: 11,
          color: _getCardColor(),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildReturnRate() {
    final returnRate = widget.fundRanking.oneYearReturn;
    final isPositive = returnRate >= 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive
              ? [
                  Colors.green[50]!,
                  Colors.green[100]!,
                ]
              : [
                  Colors.red[50]!,
                  Colors.red[100]!,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPositive ? Colors.green[200]! : Colors.red[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '近1年收益',
            style: TextStyle(
              fontSize: 11,
              color: isPositive ? Colors.green[700] : Colors.red[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isPositive
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: isPositive ? Colors.green[600] : Colors.red[600],
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${isPositive ? '+' : ''}${returnRate.toStringAsFixed(2)}%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isPositive ? Colors.green[700] : Colors.red[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // 收藏按钮
        Expanded(
          child: _buildActionButton(
            icon: _isFavorite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            label: '收藏',
            isActive: _isFavorite,
            onTap: _toggleFavorite,
            activeColor: Colors.red,
          ),
        ),
        const SizedBox(width: 8),
        // 对比按钮
        Expanded(
          child: _buildActionButton(
            icon: _isComparing
                ? Icons.compare_arrows_rounded
                : Icons.compare_arrows_outlined,
            label: '对比',
            isActive: _isComparing,
            onTap: _toggleCompare,
            activeColor: Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        // 详情按钮
        Expanded(
          child: _buildActionButton(
            icon: Icons.info_outline_rounded,
            label: '详情',
            isActive: false,
            onTap: () {
              HapticFeedback.lightImpact();
              // TODO: 导航到详情页
            },
            activeColor: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required Color activeColor,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? activeColor.withOpacity(0.1) : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isActive ? activeColor.withOpacity(0.3) : Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: isActive ? activeColor : Colors.grey[600],
                  size: 18,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isActive ? activeColor : Colors.grey[600],
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHotTag() {
    return Positioned(
      top: 8,
      right: 8,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.red[400]!,
              Colors.red[600]!,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department_rounded,
              color: Colors.white,
              size: 12,
            ),
            SizedBox(width: 2),
            Text(
              '热门',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCardColor() {
    // 根据基金类型返回不同的主题色
    final type = widget.fundRanking.fundType.toLowerCase();

    if (type.contains('股票')) return Colors.blue[600]!;
    if (type.contains('债券')) return Colors.green[600]!;
    if (type.contains('混合')) return Colors.purple[600]!;
    if (type.contains('货币')) return Colors.orange[600]!;
    if (type.contains('指数')) return Colors.cyan[600]!;

    return Colors.indigo[600]!;
  }
}
