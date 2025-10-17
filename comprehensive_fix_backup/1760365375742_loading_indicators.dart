import 'package:flutter/material.dart';

/// 现代化加载状态指示器
///
/// 包含多种加载状态的视觉反馈：
/// - 初始加载
/// - 分批加载
/// - 下拉刷新
/// - 错误状态
/// - 空状态
class ModernLoadingIndicators {
  /// 全屏加载指示器
  static Widget fullScreenLoading({
    String message = '加载中...',
    double progress = 0.0,
    bool showProgress = false,
  }) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 主加载动画
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 外圈动画
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.blue.shade600,
                      ),
                    ),
                  ),
                  // 内圈动画
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.purple.shade400,
                      ),
                    ),
                  ),
                  // 中心图标
                  Icon(
                    Icons.account_balance,
                    size: 24,
                    color: Colors.blue.shade600,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 加载文本
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),

            // 进度条（可选）
            if (showProgress)
              Container(
                width: 200,
                margin: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.blue.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(progress * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 列表内加载指示器
  static Widget listLoading({
    String message = '加载更多数据...',
    bool showSpinner = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSpinner)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.blue.shade600,
                ),
              ),
            ),
          if (showSpinner) const SizedBox(width: 12),
          Flexible(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 下拉刷新指示器
  static Widget pullToRefresh({
    double pullDistance = 0.0,
    double refreshTrigger = 80.0,
    bool isRefreshing = false,
  }) {
    final progress = (pullDistance / refreshTrigger).clamp(0.0, 1.0);

    return Container(
      height: 60,
      alignment: Alignment.center,
      child: isRefreshing
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Transform.rotate(
              angle: progress * 3.14159,
              child: Icon(
                Icons.refresh,
                color: Colors.grey.shade600,
                size: 24,
              ),
            ),
    );
  }

  /// 错误状态指示器
  static Widget errorState({
    required String message,
    required VoidCallback onRetry,
    String? details,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 错误图标
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              Icons.error_outline,
              size: 40,
              color: Colors.red.shade400,
            ),
          ),
          const SizedBox(height: 20),

          // 错误标题
          Text(
            '加载失败',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),

          // 错误信息
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),

          // 详细信息（可选）
          if (details != null) ...[
            const SizedBox(height: 8),
            Text(
              details,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
          const SizedBox(height: 24),

          // 重试按钮
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('重试'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 空状态指示器
  static Widget emptyState({
    String message = '暂无数据',
    String? subMessage,
    IconData? icon,
    Widget? action,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 空状态图标
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              icon ?? Icons.inbox_outlined,
              size: 50,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),

          // 空状态文本
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          if (subMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              subMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],

          // 操作按钮（可选）
          if (action != null) ...[
            const SizedBox(height: 24),
            action,
          ],
        ],
      ),
    );
  }
}

/// 骨架屏加载器
class FundCardSkeleton extends StatelessWidget {
  final bool showAvatar;
  final int lines;
  final double height;

  const FundCardSkeleton({
    super.key,
    this.showAvatar = true,
    this.lines = 3,
    this.height = 80.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 排名骨架
          if (showAvatar)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          if (showAvatar) const SizedBox(width: 12),

          // 内容骨架
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSkeletonLine(width: double.infinity, height: 16),
                const SizedBox(height: 8),
                _buildSkeletonLine(width: 120, height: 12),
                const SizedBox(height: 4),
                _buildSkeletonLine(width: 80, height: 12),
              ],
            ),
          ),

          // 右侧信息骨架
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildSkeletonLine(width: 60, height: 16),
              const SizedBox(height: 8),
              _buildSkeletonLine(width: 40, height: 12),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLine({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// 骨架屏列表
class FundListSkeleton extends StatelessWidget {
  final int itemCount;
  final bool showAvatar;
  final double height;

  const FundListSkeleton({
    super.key,
    this.itemCount = 5,
    this.showAvatar = true,
    this.height = 80.0,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => FundCardSkeleton(
        showAvatar: showAvatar,
        height: height,
      ),
    );
  }
}

/// 智能加载管理器
class SmartLoadingManager extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final bool isEmpty;
  final String? emptyMessage;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final Widget? emptyWidget;

  const SmartLoadingManager({
    super.key,
    required this.child,
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage,
    this.onRetry,
    this.isEmpty = false,
    this.emptyMessage,
    this.loadingWidget,
    this.errorWidget,
    this.emptyWidget,
  });

  @override
  State<SmartLoadingManager> createState() => _SmartLoadingManagerState();
}

class _SmartLoadingManagerState extends State<SmartLoadingManager>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(SmartLoadingManager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isLoading && widget.isLoading != oldWidget.isLoading) {
      _animationController.forward();
    } else if (widget.isLoading && widget.isLoading != oldWidget.isLoading) {
      _animationController.reset();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 加载状态
    if (widget.isLoading) {
      return widget.loadingWidget ??
          ModernLoadingIndicators.fullScreenLoading();
    }

    // 错误状态
    if (widget.hasError) {
      return widget.errorWidget ??
          ModernLoadingIndicators.errorState(
            message: widget.errorMessage ?? '加载失败',
            onRetry: widget.onRetry ?? () {},
          );
    }

    // 空状态
    if (widget.isEmpty) {
      return widget.emptyWidget ??
          ModernLoadingIndicators.emptyState(
            message: widget.emptyMessage ?? '暂无数据',
          );
    }

    // 正常内容
    return FadeTransition(
      opacity: _fadeAnimation,
      child: widget.child,
    );
  }
}

/// 自定义进度指示器
class CustomCircularProgressIndicator extends StatefulWidget {
  final double progress;
  final Color? color;
  final Color? backgroundColor;
  final double strokeWidth;
  final Widget? child;

  const CustomCircularProgressIndicator({
    super.key,
    required this.progress,
    this.color,
    this.backgroundColor,
    this.strokeWidth = 6.0,
    this.child,
  });

  @override
  State<CustomCircularProgressIndicator> createState() =>
      _CustomCircularProgressIndicatorState();
}

class _CustomCircularProgressIndicatorState
    extends State<CustomCircularProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(CustomCircularProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress != oldWidget.progress) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ));
      _controller.forward(from: _animation.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 背景圆环
          SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: widget.strokeWidth,
              backgroundColor: widget.backgroundColor ?? Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.backgroundColor ?? Colors.grey.shade200,
              ),
            ),
          ),
          // 进度圆环
          SizedBox(
            width: 120,
            height: 120,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CircularProgressIndicator(
                  value: _animation.value,
                  strokeWidth: widget.strokeWidth,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.color ?? Colors.blue.shade600,
                  ),
                );
              },
            ),
          ),
          // 中心内容
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }
}
