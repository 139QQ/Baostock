import 'package:flutter/material.dart';

import '../../domain/entities/fund_ranking.dart';
import 'glassmorphism_card.dart';
import '../../../../core/theme/app_theme.dart';

/// 优化版基金排行榜卡片组件
///
/// 优化点：
/// - 移除复杂动画，提升性能
/// - 使用缓存的颜色和样式
/// - 简化布局结构
/// - 优化内存使用
/// - 支持懒加载和回收利用
class OptimizedFundRankingCard extends StatelessWidget {
  /// 排行榜数据
  final FundRanking ranking;

  /// 排名位置
  final int position;

  /// 点击回调
  final VoidCallback? onTap;

  /// 收藏状态
  final bool isFavorite;

  /// 收藏回调
  final Function(bool)? onFavorite;

  /// 是否显示收藏按钮
  final bool showFavoriteButton;

  /// 是否显示详情按钮
  final bool showDetailButton;

  /// 是否启用毛玻璃效果
  final bool enableGlassmorphism;

  /// 毛玻璃配置（如果为null则使用默认配置）
  final GlassmorphismConfig? glassmorphismConfig;

  /// 卡片颜色缓存
  static final Map<int, Color> _badgeColorCache = {};
  static final Map<int, LinearGradient> _gradientCache = {};

  const OptimizedFundRankingCard({
    super.key,
    required this.ranking,
    required this.position,
    this.onTap,
    this.isFavorite = false,
    this.onFavorite,
    this.showFavoriteButton = true,
    this.showDetailButton = true,
    this.enableGlassmorphism = true, // 默认启用毛玻璃效果
    this.glassmorphismConfig,
  });

  /// 获取排名徽章颜色（缓存优化）
  Color _getRankingBadgeColor(int position) {
    return _badgeColorCache.putIfAbsent(position, () {
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
    });
  }

  /// 获取卡片渐变色（缓存优化）
  LinearGradient _getCardGradient(BuildContext context, int position) {
    return _gradientCache.putIfAbsent(position, () {
      if (position == 1) {
        // 金色渐变
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        );
      } else if (position == 2) {
        // 银色渐变
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFC0C0C0), Color(0xFF808080)],
        );
      } else if (position == 3) {
        // 铜色渐变
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFCD7F32), Color(0xFF8B4513)],
        );
      } else if (position <= 10) {
        // 前10名主题色渐变
        final theme = Theme.of(context);
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.7)],
        );
      } else {
        // 其他灰色渐变
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF757575), Color(0xFF616161)],
        );
      }
    });
  }

  /// 获取卡片渐变色（不需要BuildContext）
  LinearGradient _getCardGradientFromPosition(int position) {
    return _gradientCache.putIfAbsent(position, () {
      if (position == 1) {
        // 金色渐变
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        );
      } else if (position == 2) {
        // 银色渐变
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFC0C0C0), Color(0xFF808080)],
        );
      } else if (position == 3) {
        // 铜色渐变
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFCD7F32), Color(0xFF8B4513)],
        );
      } else if (position <= 10) {
        // 前10名蓝色渐变
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
        );
      } else {
        // 其他灰色渐变
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF757575), Color(0xFF616161)],
        );
      }
    });
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

  @override
  Widget build(BuildContext context) {
    final cardContent = _buildCardContent();

    // 如果启用毛玻璃效果
    if (enableGlassmorphism) {
      final config = glassmorphismConfig ?? AppTheme.defaultGlassmorphismConfig;

      return GlassmorphismCard(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        blur: config.blur,
        opacity: config.opacity,
        borderRadius: config.borderRadius,
        borderWidth: config.borderWidth,
        borderColor: config.borderColor,
        backgroundColor: config.backgroundColor,
        enablePerformanceOptimization: config.enablePerformanceOptimization,
        child: cardContent,
      );
    }

    // 传统卡片样式
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: cardContent,
    );
  }

  /// 构建卡片内容
  Widget _buildCardContent() {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: _getCardGradientFromPosition(position),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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

        // 基金代码和类型标签
        Expanded(
          child: _buildFundTags(),
        ),

        // 收藏按钮
        if (showFavoriteButton) _buildFavoriteButton(),
      ],
    );
  }

  /// 构建排名徽章
  Widget _buildRankingBadge() {
    final isTopThree = position <= 3;
    final badgeColor = _getRankingBadgeColor(position);

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: isTopThree
            ? const Icon(
                Icons.emoji_events,
                color: Colors.white,
                size: 18,
              )
            : Text(
                position.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  /// 构建基金标签
  Widget _buildFundTags() {
    return Row(
      children: [
        // 基金代码标签
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            ranking.fundCode,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        const SizedBox(width: 6),

        // 基金类型标签
        if (ranking.fundType.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              ranking.fundType,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  /// 构建基金名称
  Widget _buildFundName() {
    return Text(
      ranking.fundName,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        height: 1.2,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// 构建收益率信息
  Widget _buildReturnInfo() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildReturnItem('日收益', ranking.dailyReturn),
          _buildReturnItem('近1月', ranking.return1M),
          _buildReturnItem('近1年', ranking.return1Y),
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
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (value > 0)
              Icon(
                Icons.arrow_upward,
                size: 10,
                color: color,
              )
            else if (value < 0)
              Icon(
                Icons.arrow_downward,
                size: 10,
                color: color,
              )
            else
              const SizedBox(width: 10),
            Text(
              '$displayValue%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
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
            ranking.company,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // 详情按钮
        if (showDetailButton)
          TextButton.icon(
            onPressed: onTap,
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

  /// 构建收藏按钮
  Widget _buildFavoriteButton() {
    return IconButton(
      onPressed: () => onFavorite?.call(!isFavorite),
      icon: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        color: isFavorite ? Colors.red : Colors.white,
        size: 20,
      ),
      splashRadius: 18,
      constraints: const BoxConstraints(
        minWidth: 36,
        minHeight: 36,
      ),
    );
  }

  /// 清理缓存（在内存压力大时调用）
  static void clearCache() {
    _badgeColorCache.clear();
    _gradientCache.clear();
  }
}
