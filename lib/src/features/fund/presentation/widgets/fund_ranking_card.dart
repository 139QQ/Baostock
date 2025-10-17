import 'package:flutter/material.dart';

import '../../domain/entities/fund_ranking.dart';

/// 基金排行榜卡片组件
///
/// 显示单个基金的排行榜信息，包括：
/// - 排名位置和变化
/// - 基金基本信息
/// - 收益率数据
/// - 操作按钮（收藏、详情）
class FundRankingCard extends StatefulWidget {
  /// 排行榜数据
  final FundRanking ranking;

  /// 排名位置
  final int position;

  /// 点击回调
  final VoidCallback? onTap;

  /// 收藏回调
  final Function(bool)? onFavorite;

  /// 动画延迟
  final Duration? animationDelay;

  /// 是否显示收藏按钮
  final bool showFavoriteButton;

  /// 是否显示详情按钮
  final bool showDetailButton;

  const FundRankingCard({
    super.key,
    required this.ranking,
    required this.position,
    this.onTap,
    this.onFavorite,
    this.animationDelay,
    this.showFavoriteButton = true,
    this.showDetailButton = true,
  });

  @override
  State<FundRankingCard> createState() => _FundRankingCardState();
}

class _FundRankingCardState extends State<FundRankingCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 初始化动画
  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.95,
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
  }

  /// 开始动画
  void _startAnimation() {
    final delay = widget.animationDelay ?? Duration.zero;
    Future.delayed(delay, () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: _buildCard(),
          ),
        );
      },
    );
  }

  /// 构建卡片
  Widget _buildCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: _getCardGradient(),
          ),
          child: Column(
            children: [
              // 顶部信息行
              _buildTopRow(),
              const SizedBox(height: 12),

              // 收益率信息
              _buildReturnInfo(),

              const SizedBox(height: 12),

              // 底部操作行
              _buildBottomRow(),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建顶部信息行
  Widget _buildTopRow() {
    return Row(
      children: [
        // 排名位置
        _buildRankingBadge(),

        const SizedBox(width: 12),

        // 基金信息
        Expanded(
          child: _buildFundInfo(),
        ),

        // 收藏按钮
        if (widget.showFavoriteButton) _buildFavoriteButton(),
      ],
    );
  }

  /// 构建排名徽章
  Widget _buildRankingBadge() {
    final isTopThree = widget.position <= 3;
    final badgeColor = _getRankingBadgeColor(widget.position);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: isTopThree
            ? const Icon(
                Icons.emoji_events,
                color: Colors.white,
                size: 20,
              )
            : Text(
                widget.position.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  /// 获取排名徽章颜色
  Color _getRankingBadgeColor(int position) {
    if (position == 1) {
      return const Color(0xFFFFD700); // 金色
    } else if (position == 2) {
      return const Color(0xFFC0C0C0); // 银色
    } else if (position == 3) {
      return const Color(0xFFCD7F32); // 铜色
    } else if (position <= 10) {
      return Colors.blue; // 前10名蓝色
    } else {
      return Colors.grey; // 其他灰色
    }
  }

  /// 构建基金信息
  Widget _buildFundInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 基金名称
        Text(
          widget.ranking.fundName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 4),

        // 基金代码和类型
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                widget.ranking.fundCode,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                widget.ranking.fundType,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建收藏按钮
  Widget _buildFavoriteButton() {
    return IconButton(
      onPressed: _toggleFavorite,
      icon: Icon(
        _isFavorite ? Icons.favorite : Icons.favorite_border,
        color: _isFavorite ? Colors.red : Colors.white,
      ),
      splashRadius: 20,
    );
  }

  /// 构建收益率信息
  Widget _buildReturnInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildReturnItem('日收益', widget.ranking.dailyReturn),
          _buildReturnItem('近1月', widget.ranking.return1M),
          _buildReturnItem('近1年', widget.ranking.return1Y),
        ],
      ),
    );
  }

  /// 构建收益率项
  Widget _buildReturnItem(String label, double value) {
    final color = _getReturnColor(value);

    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (value > 0)
              const Icon(
                Icons.arrow_upward,
                size: 12,
                color: Colors.white,
              )
            else if (value < 0)
              const Icon(
                Icons.arrow_downward,
                size: 12,
                color: Colors.white,
              ),
            Text(
              '${value.abs().toStringAsFixed(2)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建底部操作行
  Widget _buildBottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 基金公司
        Expanded(
          child: Text(
            widget.ranking.company,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // 详情按钮
        if (widget.showDetailButton)
          TextButton.icon(
            onPressed: widget.onTap,
            icon: const Icon(
              Icons.info_outline,
              size: 16,
              color: Colors.white,
            ),
            label: const Text(
              '详情',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
      ],
    );
  }

  /// 获取卡片渐变色
  LinearGradient _getCardGradient() {
    final rank = widget.position;

    if (rank == 1) {
      // 金色渐变
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
      );
    } else if (rank == 2) {
      // 银色渐变
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFC0C0C0), Color(0xFF808080)],
      );
    } else if (rank == 3) {
      // 铜色渐变
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFCD7F32), Color(0xFF8B4513)],
      );
    } else if (rank <= 10) {
      // 前10名蓝色渐变
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Theme.of(context).colorScheme.primary,
          Theme.of(context).colorScheme.primary.withOpacity(0.7),
        ],
      );
    } else {
      // 其他灰色渐变
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.grey, Colors.grey],
      );
    }
  }

  /// 获取收益率颜色
  Color _getReturnColor(double value) {
    if (value > 0) {
      return const Color(0xFF4CAF50); // 绿色
    } else if (value < 0) {
      return const Color(0xFFF44336); // 红色
    } else {
      return Colors.white; // 白色
    }
  }

  /// 切换收藏状态
  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    widget.onFavorite?.call(_isFavorite);
  }
}
