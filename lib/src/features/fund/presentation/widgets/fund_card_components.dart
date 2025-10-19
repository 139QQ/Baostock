import 'package:flutter/material.dart';

import '../../domain/entities/fund_ranking.dart';
import 'fund_card_theme.dart';

/// 基金卡片头部组件
///
/// 负责显示排名、基金基本信息和收藏按钮
class FundCardHeader extends StatefulWidget {
  final FundRanking fund;
  final int position;
  final bool isFavorite;
  final FundCardSize cardSize;
  final Color? themeColor;
  final VoidCallback? onTap;
  final Function(bool)? onFavorite;

  const FundCardHeader({
    super.key,
    required this.fund,
    required this.position,
    required this.isFavorite,
    this.cardSize = FundCardSize.normal,
    this.themeColor,
    this.onTap,
    this.onFavorite,
  });

  @override
  State<FundCardHeader> createState() => _FundCardHeaderState();
}

class _FundCardHeaderState extends State<FundCardHeader>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  bool get wantKeepAlive => true;

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

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: FundCardAnimationConfig.mediumDuration,
      vsync: this,
    );

    _scaleAnimation =
        FundCardAnimationConfig.createScaleAnimation(_animationController);
    _fadeAnimation =
        FundCardAnimationConfig.createFadeAnimation(_animationController);
  }

  void _startAnimation() {
    Future.delayed(Duration(milliseconds: widget.position * 50), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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

  Widget _buildCard() {
    return Card(
      margin: FundCardTheme.cardMargin,
      elevation: FundCardTheme.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FundCardTheme.cardBorderRadius),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(FundCardTheme.cardBorderRadius),
        child: Container(
          decoration: FundCardTheme.getCardDecoration(context, widget.position),
          padding: FundCardTheme.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 顶部信息行
              _buildTopRow(),
              const SizedBox(height: 8),

              // 基金名称
              _buildFundName(),
              const SizedBox(height: 8),

              // 收益率信息
              _buildReturnInfo(),
              const SizedBox(height: 8),

              // 底部信息行
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
        // 排名徽章
        _buildRankingBadge(),

        const SizedBox(width: 12),

        // 基金信息
        Expanded(
          child: _buildFundInfo(),
        ),

        // 收藏按钮
        _buildFavoriteButton(),
      ],
    );
  }

  /// 构建排名徽章
  Widget _buildRankingBadge() {
    final isTopThree = widget.position <= 3;
    final badgeColor = FundCardTheme.rankingBadgeColors[widget.position] ??
        FundCardTheme.defaultBadgeColor;

    return Container(
      width: FundCardTheme.badgeSize,
      height: FundCardTheme.badgeSize,
      decoration: FundCardTheme.getBadgeDecoration(badgeColor),
      child: Center(
        child: isTopThree
            ? Icon(
                Icons.emoji_events,
                color: Colors.white,
                size: FundCardTheme.badgeIconSize,
              )
            : Text(
                widget.position.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  /// 构建基金信息
  Widget _buildFundInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 基金名称
        Text(
          widget.fund.fundName,
          style: FundCardTheme.fundNameStyle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 4),

        // 基金代码和类型标签
        _buildFundTags(),
      ],
    );
  }

  /// 构建基金标签
  Widget _buildFundTags() {
    return Row(
      children: [
        // 基金代码标签
        _buildTag(
          widget.fund.fundCode,
          FundCardTheme.fundCodeStyle,
        ),

        const SizedBox(width: 6),

        // 基金类型标签
        if (widget.fund.fundType.isNotEmpty)
          _buildTag(
            widget.fund.fundType,
            FundCardTheme.fundTypeStyle,
          ),
      ],
    );
  }

  /// 构建标签
  Widget _buildTag(String text, TextStyle style) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: FundCardTheme.getTagContainerDecoration(),
      child: Text(
        text,
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// 构建收藏按钮
  Widget _buildFavoriteButton() {
    return IconButton(
      onPressed: _toggleFavorite,
      icon: Icon(
        widget.isFavorite ? Icons.favorite : Icons.favorite_border,
        color: widget.isFavorite ? Colors.red : Colors.white,
        size: FundCardTheme.favoriteIconSize,
      ),
      splashRadius: FundCardTheme.favoriteSplashRadius,
      constraints: const BoxConstraints(
        minWidth: FundCardTheme.favoriteButtonSize,
        minHeight: FundCardTheme.favoriteButtonSize,
      ),
      tooltip: widget.isFavorite ? '取消收藏' : '添加收藏',
    );
  }

  /// 构建基金名称
  Widget _buildFundName() {
    return Text(
      widget.fund.fundName,
      style: FundCardTheme.fundNameStyle,
      maxLines: widget.cardSize == FundCardSize.expanded ? 2 : 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// 构建收益率信息
  Widget _buildReturnInfo() {
    return Container(
      padding: FundCardTheme.returnContainerPadding,
      decoration: FundCardTheme.getReturnContainerDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildReturnItem('日收益', widget.fund.dailyReturn),
          _buildReturnItem('近1月', widget.fund.return1M),
          _buildReturnItem('近1年', widget.fund.return1Y),
        ],
      ),
    );
  }

  /// 构建收益率项
  Widget _buildReturnItem(String label, double value) {
    final color = _getReturnColor(value);
    final displayValue = value.abs().toStringAsFixed(2);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: FundCardTheme.returnLabelStyle,
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (value > 0)
              Icon(
                Icons.arrow_upward,
                size: FundCardTheme.returnIconSize,
                color: color,
              )
            else if (value < 0)
              Icon(
                Icons.arrow_downward,
                size: FundCardTheme.returnIconSize,
                color: color,
              )
            else
              const SizedBox(width: FundCardTheme.returnIconSize),
            Text(
              '$displayValue%',
              style: FundCardTheme.returnValueStyle.copyWith(color: color),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建底部信息行
  Widget _buildBottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 基金公司
        Expanded(
          child: Text(
            widget.fund.company,
            style: FundCardTheme.companyStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // 详情按钮
        TextButton.icon(
          onPressed: widget.onTap,
          icon: const Icon(
            Icons.info_outline,
            size: 14,
            color: Colors.white,
          ),
          label: const Text(
            '详情',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  /// 获取收益率颜色
  Color _getReturnColor(double value) {
    if (value > 0) {
      return FundCardTheme.positiveReturnColor;
    } else if (value < 0) {
      return FundCardTheme.negativeReturnColor;
    } else {
      return FundCardTheme.neutralReturnColor;
    }
  }

  /// 切换收藏状态
  void _toggleFavorite() {
    widget.onFavorite?.call(!widget.isFavorite);
  }
}

/// 基金卡片状态指示器组件
class FundCardStatusIndicator extends StatelessWidget {
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final bool fromCache;
  final DateTime? lastUpdateTime;

  const FundCardStatusIndicator({
    super.key,
    required this.isLoading,
    this.hasError = false,
    this.errorMessage,
    this.fromCache = false,
    this.lastUpdateTime,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingIndicator();
    }

    if (hasError) {
      return _buildErrorIndicator();
    }

    if (fromCache || lastUpdateTime != null) {
      return _buildCacheIndicator();
    }

    return const SizedBox.shrink();
  }

  Widget _buildLoadingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          '加载中...',
          style: TextStyle(
            fontSize: 12,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FundCardTheme.errorIcon,
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            errorMessage ?? '加载失败',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.red,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCacheIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.cached,
          size: 14,
          color: Colors.orange[600],
        ),
        const SizedBox(width: 4),
        Text(
          fromCache ? '缓存数据' : '已更新',
          style: TextStyle(
            fontSize: 10,
            color: Colors.orange[600],
          ),
        ),
        if (lastUpdateTime != null) ...[
          const SizedBox(width: 4),
          Text(
            _formatTime(lastUpdateTime!),
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else {
      return '${difference.inDays}天前';
    }
  }
}

/// 基金卡片加载骨架屏
class FundCardSkeleton extends StatelessWidget {
  final FundCardSize cardSize;

  const FundCardSkeleton({
    super.key,
    this.cardSize = FundCardSize.normal,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: FundCardTheme.cardMargin,
      elevation: FundCardTheme.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FundCardTheme.cardBorderRadius),
      ),
      child: Container(
        padding: FundCardTheme.cardPadding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(FundCardTheme.cardBorderRadius),
          color: Colors.grey[100],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶部信息行
            Row(
              children: [
                _buildSkeletonBadge(),
                const SizedBox(width: 12),
                Expanded(child: _buildSkeletonText()),
                _buildSkeletonButton(),
              ],
            ),
            const SizedBox(height: 8),

            // 基金名称
            _buildSkeletonText(widthPercentage: 0.8),
            const SizedBox(height: 4),

            // 标签行
            Row(
              children: [
                _buildSkeletonTag(),
                const SizedBox(width: 6),
                _buildSkeletonTag(),
              ],
            ),
            const SizedBox(height: 8),

            // 收益率信息
            _buildSkeletonReturnInfo(),
            const SizedBox(height: 8),

            // 底部信息行
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSkeletonText(widthPercentage: 0.6),
                _buildSkeletonButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonBadge() {
    return Container(
      width: FundCardTheme.badgeSize,
      height: FundCardTheme.badgeSize,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(FundCardTheme.badgeSize / 2),
      ),
    );
  }

  Widget _buildSkeletonText({double widthPercentage = 0.5}) {
    return Container(
      height: 12,
      width: widthPercentage * 100,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildSkeletonTag() {
    return Container(
      height: 16,
      width: 60,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildSkeletonButton() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildSkeletonReturnInfo() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSkeletonText(widthPercentage: 0.2),
          _buildSkeletonText(widthPercentage: 0.2),
          _buildSkeletonText(widthPercentage: 0.2),
        ],
      ),
    );
  }
}
