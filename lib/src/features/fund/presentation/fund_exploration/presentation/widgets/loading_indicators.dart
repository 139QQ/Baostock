import 'package:flutter/material.dart';

/// 现代化加载状态指示器组件�?
///
/// 提供多种类型的加载指示器和状态反馈组件，包括�?
/// - 基础圆形进度指示�?
/// - 全屏加载指示�?
/// - 列表内加载指示器
/// - 骨架屏加载效�?
/// - 错误和空状态指示器
/// - 智能加载管理�?
/// - 自定义进度指示器
/// - 脉冲动画加载�?
///
/// 所有组件都支持主题适配和自定义样式配置

/// 基础加载指示器类型枚�?
enum LoadingType {
  circular,    // 圆形进度指示�?
  linear,      // 线性进度指示器
  pulse,       // 脉冲动画
  dots,        // 点状动画
  skeleton,    // 骨架�?
}

/// 加载指示器尺寸枚�?
enum LoadingSize {
  small,       // 小尺�?(24px)
  medium,      // 中等尺寸 (48px)
  large,       // 大尺�?(72px)
  extraLarge,  // 超大尺寸 (96px)
}

/// 现代化加载指示器主类
class ModernLoadingIndicators {
  /// 全屏加载指示�?
  ///
  /// [message] 加载提示文本
  /// [progress] 进度�?(0.0 - 1.0)
  /// [showProgress] 是否显示进度�?
  /// [type] 加载指示器类�?
  /// [size] 加载指示器尺�?
  static Widget fullScreenLoading({
    String message = '加载�?..',
    double progress = 0.0,
    bool showProgress = false,
    LoadingType type = LoadingType.circular,
    LoadingSize size = LoadingSize.large,
    Color? color,
  }) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 主加载动�?
            _buildLoadingIndicator(
              type: type,
              size: size,
              color: color ?? Colors.blue.shade600,
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
            if (showProgress) ...[
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
                        color ?? Colors.blue.shade600,
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
          ],
        ),
      ),
    );
  }

  /// 列表内加载指示器
  ///
  /// [message] 加载提示文本
  /// [showSpinner] 是否显示旋转动画
  /// [type] 加载指示器类�?
  static Widget listLoading({
    String message = '加载更多数据...',
    bool showSpinner = true,
    LoadingType type = LoadingType.circular,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSpinner)
            _buildLoadingIndicator(
              type: type,
              size: LoadingSize.small,
              color: color ?? Colors.blue.shade600,
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

  /// 下拉刷新指示�?
  ///
  /// [pullDistance] 拉动距离
  /// [refreshTrigger] 触发刷新的距�?
  /// [isRefreshing] 是否正在刷新
  static Widget pullToRefresh({
    double pullDistance = 0.0,
    double refreshTrigger = 80.0,
    bool isRefreshing = false,
    Color? color,
  }) {
    final progress = (pullDistance / refreshTrigger).clamp(0.0, 1.0);

    return Container(
      height: 60,
      alignment: Alignment.center,
      child: isRefreshing
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  color ?? Colors.blue.shade600,
                ),
              ),
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
  ///
  /// [message] 错误信息
  /// [onRetry] 重试回调
  /// [details] 详细错误信息
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
  ///
  /// [message] 空状态提示文�?
  /// [subMessage] 副标题文�?
  /// [icon] 自定义图�?
  /// [action] 操作按钮
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
          // 空状态图�?
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

          // 空状态文�?
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

  /// 构建不同类型的加载指示器
  static Widget _buildLoadingIndicator({
    required LoadingType type,
    required LoadingSize size,
    required Color color,
  }) {
    final dimension = _getLoadingSize(size);

    switch (type) {
      case LoadingType.circular:
        return SizedBox(
          width: dimension,
          height: dimension,
          child: CircularProgressIndicator(
            strokeWidth: dimension / 8,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        );
      case LoadingType.linear:
        return SizedBox(
          width: dimension * 2,
          height: 4,
          child: LinearProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        );
      case LoadingType.pulse:
        return PulseLoadingIndicator(
          size: dimension,
          color: color,
        );
      case LoadingType.dots:
        return DotsLoadingIndicator(
          size: dimension,
          color: color,
        );
      case LoadingType.skeleton:
        return SkeletonLoadingIndicator(
          width: dimension * 2,
          height: dimension,
          color: color,
        );
    }
  }

  /// 获取加载指示器尺�?
  static double _getLoadingSize(LoadingSize size) {
    switch (size) {
      case LoadingSize.small:
        return 24;
      case LoadingSize.medium:
        return 48;
      case LoadingSize.large:
        return 72;
      case LoadingSize.extraLarge:
        return 96;
    }
  }
}

/// 脉冲动画加载�?
class PulseLoadingIndicator extends StatefulWidget {
  final double size;
  final Color color;

  const PulseLoadingIndicator({
    super.key,
    required this.size,
    required this.color,
  });

  @override
  State<PulseLoadingIndicator> createState() => _PulseLoadingIndicatorState();
}

class _PulseLoadingIndicatorState extends State<PulseLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.3,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 点状动画加载�?
class DotsLoadingIndicator extends StatefulWidget {
  final double size;
  final Color color;

  const DotsLoadingIndicator({
    super.key,
    required this.size,
    required this.color,
  });

  @override
  State<DotsLoadingIndicator> createState() => _DotsLoadingIndicatorState();
}

class _DotsLoadingIndicatorState extends State<DotsLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _animations = List.generate(3, (index) {
      return Tween<double>(
        begin: 0.3,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Interval(
          index * 0.2,
          0.6 + index * 0.2,
          curve: Curves.easeInOut,
        ),
      ));
    });

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Padding(
              padding: EdgeInsets.only(right: index < 2 ? widget.size / 4 : 0),
              child: Transform.scale(
                scale: _animations[index].value,
                child: Container(
                  width: widget.size / 3,
                  height: widget.size / 3,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

/// 骨架屏加载指示器
class SkeletonLoadingIndicator extends StatefulWidget {
  final double width;
  final double height;
  final Color color;

  const SkeletonLoadingIndicator({
    super.key,
    required this.width,
    required this.height,
    required this.color,
  });

  @override
  State<SkeletonLoadingIndicator> createState() => _SkeletonLoadingIndicatorState();
}

class _SkeletonLoadingIndicatorState extends State<SkeletonLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade200,
      ),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Stack(
            children: [
              // 背景�?
              Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade200,
                ),
              ),
              // 光效�?
              Positioned(
                left: (_animation.value - 1) * widget.width,
                top: 0,
                child: Container(
                  width: widget.width * 0.3,
                  height: widget.height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        widget.color.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 基金卡片骨架�?
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
    return SkeletonLoadingIndicator(
      width: width,
      height: height,
      color: Colors.grey.shade300,
    );
  }
}

/// 基金列表骨架�?
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

/// 智能加载管理�?
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
    // 加载状�?
    if (widget.isLoading) {
      return widget.loadingWidget ??
          ModernLoadingIndicators.fullScreenLoading();
    }

    // 错误状�?
    if (widget.hasError) {
      return widget.errorWidget ??
          ModernLoadingIndicators.errorState(
            message: widget.errorMessage ?? '加载失败',
            onRetry: widget.onRetry ?? () {},
          );
    }

    // 空状�?
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

/// 自定义圆形进度指示器
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

/// 带文字说明的加载组件
class LoadingWithText extends StatelessWidget {
  final String text;
  final LoadingType type;
  final LoadingSize size;
  final Color? color;
  final CrossAxisAlignment alignment;

  const LoadingWithText({
    super.key,
    required this.text,
    this.type = LoadingType.circular,
    this.size = LoadingSize.medium,
    this.color,
    this.alignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        ModernLoadingIndicators._buildLoadingIndicator(
          type: type,
          size: size,
          color: color ?? Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 12),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
          textAlign: alignment == CrossAxisAlignment.center
              ? TextAlign.center
              : TextAlign.left,
        ),
      ],
    );
  }
}

/// 可配置的加载指示器容�?
class ConfigurableLoadingIndicator extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final BoxShadow? shadow;
  final double? width;
  final double? height;

  const ConfigurableLoadingIndicator({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.borderRadius,
    this.shadow,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        boxShadow: [
          shadow ?? BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
