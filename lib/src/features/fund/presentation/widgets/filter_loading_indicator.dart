import 'package:flutter/material.dart';

/// 筛选加载指示器组件
///
/// 提供优雅的筛选加载状态指示，包含动画效果和加载提示
class FilterLoadingIndicator extends StatefulWidget {
  /// 是否显示加载状态
  final bool isLoading;

  /// 加载文本
  final String? loadingText;

  /// 是否显示缓存状态
  final bool isFromCache;

  /// 加载进度（可选）
  final double? progress;

  /// 子组件
  final Widget? child;

  const FilterLoadingIndicator({
    super.key,
    required this.isLoading,
    this.loadingText,
    this.isFromCache = false,
    this.progress,
    this.child,
  });

  @override
  State<FilterLoadingIndicator> createState() => _FilterLoadingIndicatorState();
}

class _FilterLoadingIndicatorState extends State<FilterLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

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

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    if (widget.isLoading) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(FilterLoadingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Stack(
      children: [
        // 子组件
        if (widget.child != null)
          AnimatedOpacity(
            opacity: widget.isLoading ? 0.3 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: widget.child!,
          ),

        // 加载指示器
        if (widget.isLoading)
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: colors.surface.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 主加载指示器
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // 背景圆环
                                SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation(
                                      colors.outline.withOpacity(0.3),
                                    ),
                                  ),
                                ),
                                // 进度圆环
                                if (widget.progress != null)
                                  SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      value: widget.progress,
                                      valueColor: AlwaysStoppedAnimation(
                                          colors.primary),
                                    ),
                                  )
                                else
                                  SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation(
                                          colors.primary),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 加载文本
                          Text(
                            widget.loadingText ?? '筛选中...',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // 缓存状态指示
                          if (widget.isFromCache)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: colors.secondary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: colors.secondary.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.flash_on,
                                    size: 16,
                                    color: colors.secondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '来自缓存',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colors.secondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

/// 筛选结果动画指示器
class FilterResultAnimation extends StatefulWidget {
  /// 是否显示结果
  final bool showResults;

  /// 结果数量
  final int resultCount;

  /// 总数量
  final int totalCount;

  /// 子组件
  final Widget child;

  const FilterResultAnimation({
    super.key,
    required this.showResults,
    required this.resultCount,
    required this.totalCount,
    required this.child,
  });

  @override
  State<FilterResultAnimation> createState() => _FilterResultAnimationState();
}

class _FilterResultAnimationState extends State<FilterResultAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 0.3,
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
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    if (widget.showResults) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(FilterResultAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.showResults != oldWidget.showResults) {
      if (widget.showResults) {
        _animationController.forward(from: 0.0);
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showResults) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _slideAnimation,
            child: Column(
              children: [
                // 结果统计动画
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .shadow
                            .withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '筛选完成',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            Text(
                              '找到 ${widget.resultCount} 只符合条件的基金',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer
                                        .withOpacity(0.8),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${widget.resultCount}/${widget.totalCount}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 子组件
                widget.child,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 筛选错误指示器
class FilterErrorIndicator extends StatefulWidget {
  /// 错误信息
  final String error;

  /// 重试回调
  final VoidCallback? onRetry;

  /// 是否显示
  final bool isVisible;

  const FilterErrorIndicator({
    super.key,
    required this.error,
    this.onRetry,
    this.isVisible = true,
  });

  @override
  State<FilterErrorIndicator> createState() => _FilterErrorIndicatorState();
}

class _FilterErrorIndicatorState extends State<FilterErrorIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticInOut,
    ));

    if (widget.isVisible) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(FilterErrorIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isVisible != oldWidget.isVisible && widget.isVisible) {
      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            _shakeAnimation.value * 5 * (1.0 - _shakeAnimation.value) * 2,
            0,
          ),
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.errorContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colors.error.withOpacity(0.3),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: colors.error,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '筛选出错',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colors.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.error,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onErrorContainer.withOpacity(0.8),
                  ),
                ),
                if (widget.onRetry != null) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: widget.onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('重试'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.error,
                        foregroundColor: colors.onError,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
