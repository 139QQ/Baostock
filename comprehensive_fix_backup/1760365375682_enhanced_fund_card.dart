import 'package:flutter/material.dart';
import 'fund_card.dart';
import '../../domain/models/fund.dart';

/// 增强的基金卡片组件
///
/// 集成加载动画、错误处理和智能状态管理
class EnhancedFundCard extends StatefulWidget {
  final Fund? fund;
  final bool showComparisonCheckbox;
  final bool showQuickActions;
  final bool isSelected;
  final bool compactMode;
  final bool isLoading;
  final String? error;
  final VoidCallback? onTap;
  final Function(bool)? onSelectionChanged;
  final VoidCallback? onAddToWatchlist;
  final VoidCallback? onCompare;
  final VoidCallback? onShare;
  final VoidCallback? onRetry;
  final Duration? timeout;

  const EnhancedFundCard({
    super.key,
    this.fund,
    this.showComparisonCheckbox = false,
    this.showQuickActions = true,
    this.isSelected = false,
    this.compactMode = false,
    this.isLoading = false,
    this.error,
    this.onTap,
    this.onSelectionChanged,
    this.onAddToWatchlist,
    this.onCompare,
    this.onShare,
    this.onRetry,
    this.timeout = const Duration(seconds: 25),
  });

  @override
  State<EnhancedFundCard> createState() => _EnhancedFundCardState();
}

class _EnhancedFundCardState extends State<EnhancedFundCard>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _fadeController;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _shimmerAnimation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    if (widget.isLoading) {
      _shimmerController.repeat();
    } else {
      _fadeController.forward();
    }
  }

  @override
  void didUpdateWidget(EnhancedFundCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isLoading != widget.isLoading) {
      if (widget.isLoading) {
        _shimmerController.repeat();
        _fadeController.reverse();
      } else {
        _shimmerController.stop();
        _shimmerController.reset();
        _fadeController.forward();
      }
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildLoadingCard();
    }

    if (widget.error != null) {
      return _buildErrorCard();
    }

    if (widget.fund == null) {
      return _buildEmptyCard();
    }

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: FundCard(
            fund: widget.fund!,
            showComparisonCheckbox: widget.showComparisonCheckbox,
            showQuickActions: widget.showQuickActions,
            isSelected: widget.isSelected,
            compactMode: widget.compactMode,
            onTap: widget.onTap,
            onSelectionChanged: widget.onSelectionChanged,
            onAddToWatchlist: widget.onAddToWatchlist,
            onCompare: widget.onCompare,
            onShare: widget.onShare,
          ),
        );
      },
    );
  }

  Widget _buildLoadingCard() {
    if (widget.compactMode) {
      return _buildCompactLoadingCard();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      height: 160,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 背景骨架屏
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 头部信息骨架
                Row(
                  children: [
                    // 复选框占位符
                    if (widget.showComparisonCheckbox)
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    if (widget.showComparisonCheckbox) const SizedBox(width: 8),

                    // 基金名称占位符
                    Expanded(
                      child: _buildShimmerContainer(
                        width: double.infinity,
                        height: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 基金类型和代码占位符
                Row(
                  children: [
                    _buildShimmerContainer(width: 60, height: 12),
                    const SizedBox(width: 8),
                    _buildShimmerContainer(width: 80, height: 12),
                  ],
                ),
                const SizedBox(height: 16),

                // 基金经理和规模占位符
                Row(
                  children: [
                    _buildShimmerContainer(width: 100, height: 14),
                    const Spacer(),
                    _buildShimmerContainer(width: 60, height: 14),
                  ],
                ),
                const SizedBox(height: 12),

                // 收益率占位符
                Row(
                  children: [
                    _buildShimmerContainer(width: 40, height: 20),
                    const SizedBox(width: 8),
                    _buildShimmerContainer(width: 80, height: 12),
                  ],
                ),
                const SizedBox(height: 16),

                // 操作按钮占位符
                Row(
                  children: [
                    Expanded(
                        child: _buildShimmerContainer(
                            width: double.infinity, height: 32)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _buildShimmerContainer(
                            width: double.infinity, height: 32)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _buildShimmerContainer(
                            width: double.infinity, height: 32)),
                  ],
                ),
              ],
            ),
          ),

          // 闪烁效果覆盖层
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _shimmerAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment(-1.0 + _shimmerAnimation.value, 0.0),
                      end: Alignment(1.0 + _shimmerAnimation.value, 0.0),
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.3),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactLoadingCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      height: 72,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // 复选框占位符
                if (widget.showComparisonCheckbox)
                  _buildShimmerContainer(width: 20, height: 20),
                if (widget.showComparisonCheckbox) const SizedBox(width: 12),

                // 内容占位符
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildShimmerContainer(
                          width: double.infinity, height: 14),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildShimmerContainer(width: 60, height: 10),
                          const SizedBox(width: 12),
                          _buildShimmerContainer(width: 40, height: 10),
                          const Spacer(),
                          _buildShimmerContainer(width: 50, height: 12),
                        ],
                      ),
                    ],
                  ),
                ),

                // 更多按钮占位符
                _buildShimmerContainer(width: 24, height: 24),
              ],
            ),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _shimmerAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      begin: Alignment(-1.0 + _shimmerAnimation.value, 0.0),
                      end: Alignment(1.0 + _shimmerAnimation.value, 0.0),
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.3),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerContainer(
      {required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[600], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '数据加载失败',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[800],
                  ),
                ),
              ),
            ],
          ),
          if (widget.error != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.error!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.red[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onRetry,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('重试'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: BorderSide(color: Colors.red[300]!),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton(
                  onPressed: () {
                    // 可以在这里添加忽略错误的逻辑
                  },
                  child: const Text('忽略'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '暂无基金数据',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 基金卡片列表加载包装器
///
/// 为基金卡片列表提供统一的加载状态管理
class FundCardListLoader extends StatefulWidget {
  final List<EnhancedFundCard> children;
  final bool isLoading;
  final bool hasError;
  final String? error;
  final VoidCallback? onRetry;
  final String? loadingText;
  final int shimmerCount;

  const FundCardListLoader({
    super.key,
    required this.children,
    this.isLoading = false,
    this.hasError = false,
    this.error,
    this.onRetry,
    this.loadingText,
    this.shimmerCount = 5,
  });

  @override
  State<FundCardListLoader> createState() => _FundCardListLoaderState();
}

class _FundCardListLoaderState extends State<FundCardListLoader> {
  @override
  Widget build(BuildContext context) {
    if (widget.hasError) {
      return _buildErrorState();
    }

    if (widget.isLoading && widget.children.isEmpty) {
      return _buildLoadingState();
    }

    return Column(
      children: [
        // 加载指示器
        if (widget.isLoading && widget.children.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.loadingText ?? '正在加载更多基金数据...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // 基金卡片列表
        ...widget.children,

        // 底部加载更多指示器
        if (widget.isLoading && widget.children.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.grey[600]!,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '正在加载...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        // 加载提示
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.loadingText ?? '正在加载基金数据...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // 骨架屏占位符
        ...List.generate(
          widget.shimmerCount,
          (index) => EnhancedFundCard(
            isLoading: true,
            compactMode: index % 3 == 0, // 交替显示紧凑和标准模式
            showComparisonCheckbox: index % 2 == 0,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[600],
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            '数据加载失败',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red[800],
            ),
          ),
          if (widget.error != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.error!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.red[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: widget.onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('重新加载'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
