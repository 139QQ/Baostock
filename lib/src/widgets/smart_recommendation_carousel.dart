import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/smart_recommendation_service.dart';
import '../features/fund/shared/models/fund_ranking.dart';

/// 智能推荐轮播组件
///
/// 在首页顶部展示推荐基金，支持：
/// - 自动轮播播放
/// - 手动滑动控制
/// - 动态指示器
/// - 一键收藏和对比功能
/// - 响应式布局适配
class SmartRecommendationCarousel extends StatefulWidget {
  final List<RecommendationItem> recommendations;
  final RecommendationStrategy strategy;
  final ValueChanged<String>? onFundTap; // 基金点击回调
  final ValueChanged<String>? onFavorite; // 收藏回调
  final ValueChanged<String>? onCompare; // 对比回调
  final bool autoPlay; // 是否自动播放
  final Duration autoPlayInterval; // 自动播放间隔
  final double height; // 轮播高度

  const SmartRecommendationCarousel({
    super.key,
    required this.recommendations,
    required this.strategy,
    this.onFundTap,
    this.onFavorite,
    this.onCompare,
    this.autoPlay = true,
    this.autoPlayInterval = const Duration(seconds: 3),
    this.height = 180.0,
  });

  @override
  State<SmartRecommendationCarousel> createState() =>
      _SmartRecommendationCarouselState();
}

class _SmartRecommendationCarouselState
    extends State<SmartRecommendationCarousel> with TickerProviderStateMixin {
  late PageController _pageController;
  Timer? _autoPlayTimer; // 改为nullable
  int _currentPage = 0;
  bool _isUserInteracting = false;

  // 动画控制器
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeAnimations();
    _startAutoPlay();
  }

  void _initializeControllers() {
    _pageController = PageController(
      viewportFraction: 0.9, // 显示部分前后页面
      initialPage: 0,
    );
  }

  void _initializeAnimations() {
    // 淡入淡出动画
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    // 滑动动画
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // 启动动画
    _fadeController.forward();
    _slideController.forward();
  }

  void _startAutoPlay() {
    if (!widget.autoPlay || widget.recommendations.length <= 1) return;

    _autoPlayTimer = Timer.periodic(widget.autoPlayInterval, (timer) {
      if (!_isUserInteracting && mounted) {
        _nextPage();
      }
    });
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
  }

  void _nextPage() {
    if (widget.recommendations.isEmpty) return;

    final nextPage = (_currentPage + 1) % widget.recommendations.length;
    _animateToPage(nextPage);
  }

  void _previousPage() {
    if (widget.recommendations.isEmpty) return;

    final previousPage = _currentPage == 0
        ? widget.recommendations.length - 1
        : _currentPage - 1;
    _animateToPage(previousPage);
  }

  void _animateToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _stopAutoPlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.recommendations.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // 轮播主体
        _buildCarousel(),
        const SizedBox(height: 12),
        // 指示器
        _buildIndicator(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey[100]!,
            Colors.grey[200]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 8),
            Text(
              '暂无推荐基金',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarousel() {
    return SizedBox(
      height: widget.height,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollStartNotification) {
            _isUserInteracting = true;
          } else if (notification is ScrollEndNotification) {
            _isUserInteracting = false;
          }
          return false;
        },
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },
          itemCount: widget.recommendations.length,
          itemBuilder: (context, index) {
            return _buildRecommendationCard(
              widget.recommendations[index],
              index == _currentPage,
            );
          },
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(RecommendationItem item, bool isCurrent) {
    final fund = item.fund;
    final isPositive = item.isPositiveReturn;

    return AnimatedBuilder(
      animation: Listenable.merge([_fadeAnimation, _slideAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: isCurrent ? 1.0 : 0.95,
          child: Opacity(
            opacity: isCurrent ? 1.0 : 0.7,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isPositive
                      ? [
                          const Color(0xFFE8F5E8),
                          const Color(0xFFF0F9F0),
                        ]
                      : [
                          const Color(0xFFFFEBEE),
                          const Color(0xFFFFF3F3),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isPositive
                      ? Colors.green.withOpacity(0.3)
                      : Colors.red.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: (isPositive ? Colors.green : Colors.red)
                              .withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => widget.onFundTap?.call(fund.fundCode),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 顶部标签和策略
                        _buildTopSection(item, isPositive),
                        const SizedBox(height: 8),

                        // 基金信息
                        Expanded(
                          child: _buildFundInfo(item, isCurrent),
                        ),

                        const SizedBox(height: 12),

                        // 底部操作区
                        _buildActionSection(fund, isPositive),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopSection(RecommendationItem item, bool isPositive) {
    return Row(
      children: [
        // 策略标签
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isPositive
                ? Colors.green.withOpacity(0.2)
                : Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getStrategyDisplayName(item.strategy),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isPositive ? Colors.green[700] : Colors.red[700],
            ),
          ),
        ),

        const Spacer(),

        // 推荐分数
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star,
                size: 12,
                color: Colors.amber,
              ),
              const SizedBox(width: 2),
              Text(
                item.score.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFundInfo(RecommendationItem item, bool isCurrent) {
    final fund = item.fund;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 基金名称
        Text(
          fund.fundName,
          style: TextStyle(
            fontSize: isCurrent ? 16 : 15,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
            height: 1.2,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 4),

        // 基金代码
        Text(
          fund.fundCode,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),

        const Spacer(),

        // 推荐理由
        Text(
          item.reason,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[700],
            height: 1.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildActionSection(FundRanking fund, bool isPositive) {
    return Row(
      children: [
        // 收益率显示
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isPositive
                ? Colors.green.withOpacity(0.15)
                : Colors.red.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _formatReturnRate(fund.dailyReturn),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isPositive ? Colors.green[700] : Colors.red[700],
            ),
          ),
        ),

        const Spacer(),

        // 操作按钮
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionButton(
              icon: Icons.favorite_border,
              onTap: () => widget.onFavorite?.call(fund.fundCode),
              tooltip: '添加收藏',
            ),
            const SizedBox(width: 8),
            _buildActionButton(
              icon: Icons.compare_arrows,
              onTap: () => widget.onCompare?.call(fund.fundCode),
              tooltip: '加入对比',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              icon,
              size: 16,
              color: Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIndicator() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 上一页按钮
          if (widget.recommendations.length > 1)
            GestureDetector(
              onTap: _previousPage,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: Icon(
                  Icons.chevron_left,
                  size: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),

          const SizedBox(width: 8),

          // 指示器
          ...List.generate(
            widget.recommendations.length,
            (index) => _buildIndicatorDot(index),
          ),

          const SizedBox(width: 8),

          // 下一页按钮
          if (widget.recommendations.length > 1)
            GestureDetector(
              onTap: _nextPage,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIndicatorDot(int index) {
    final isCurrent = index == _currentPage;

    return GestureDetector(
      onTap: () => _animateToPage(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: isCurrent ? 24 : 8,
        height: 8,
        decoration: BoxDecoration(
          color: isCurrent
              ? Theme.of(context).primaryColor
              : Colors.grey.withOpacity(0.3),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  String _getStrategyDisplayName(RecommendationStrategy strategy) {
    switch (strategy) {
      case RecommendationStrategy.highReturn:
        return '高收益';
      case RecommendationStrategy.stable:
        return '稳健';
      case RecommendationStrategy.balanced:
        return '平衡';
      case RecommendationStrategy.trending:
        return '热门';
      case RecommendationStrategy.personalized:
        return '个性';
    }
  }

  String _formatReturnRate(double rate) {
    if (rate > 0) {
      return '+${rate.toStringAsFixed(2)}%';
    } else {
      return '${rate.toStringAsFixed(2)}%';
    }
  }
}

/// 推荐轮播管理器
class RecommendationCarouselManager {
  static RecommendationCarouselManager? _instance;
  static RecommendationCarouselManager get instance {
    _instance ??= RecommendationCarouselManager._();
    return _instance!;
  }

  RecommendationCarouselManager._();

  final Map<String, List<RecommendationItem>> _cache = {};
  final Map<String, DateTime> _lastUpdate = {};
  static const Duration _cacheExpireTime = Duration(minutes: 5);

  /// 获取缓存推荐
  List<RecommendationItem>? getCachedRecommendations(String strategyKey) {
    final lastUpdate = _lastUpdate[strategyKey];
    if (lastUpdate != null &&
        DateTime.now().difference(lastUpdate) < _cacheExpireTime) {
      return _cache[strategyKey];
    }
    return null;
  }

  /// 缓存推荐
  void cacheRecommendations(
      String strategyKey, List<RecommendationItem> recommendations) {
    _cache[strategyKey] = recommendations;
    _lastUpdate[strategyKey] = DateTime.now();
  }

  /// 清除缓存
  void clearCache({String? strategyKey}) {
    if (strategyKey != null) {
      _cache.remove(strategyKey);
      _lastUpdate.remove(strategyKey);
    } else {
      _cache.clear();
      _lastUpdate.clear();
    }
  }

  /// 检查缓存状态
  bool isCacheValid(String strategyKey) {
    final lastUpdate = _lastUpdate[strategyKey];
    return lastUpdate != null &&
        DateTime.now().difference(lastUpdate) < _cacheExpireTime;
  }

  /// 获取缓存统计
  Map<String, dynamic> getCacheStats() {
    return {
      'cached_strategies': _cache.keys.toList(),
      'total_cached_items':
          _cache.values.fold(0, (sum, items) => sum + items.length),
      'last_updates':
          _lastUpdate.map((k, v) => MapEntry(k, v.toIso8601String())),
      'cache_expire_minutes': _cacheExpireTime.inMinutes,
    };
  }
}
