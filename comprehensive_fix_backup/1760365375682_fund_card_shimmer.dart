import 'dart:async';
import 'package:flutter/material.dart';

/// 基金卡片加载动画组件
///
/// 提供优雅的骨架屏加载效果，模拟基金卡片的布局结构
class FundCardShimmer extends StatefulWidget {
  final double? height;
  final double? width;
  final EdgeInsets? margin;

  const FundCardShimmer({
    super.key,
    this.height = 120,
    this.width,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
  });

  @override
  State<FundCardShimmer> createState() => _FundCardShimmerState();
}

class _FundCardShimmerState extends State<FundCardShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _shimmerAnimation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: widget.margin,
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 基金图标/代码占位符
            _buildShimmerContainer(
              width: 50,
              height: 50,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(width: 12),

            // 基金信息区域
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 基金名称占位符
                  _buildShimmerContainer(
                    width: double.infinity,
                    height: 16,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 6),

                  // 基金代码和类型占位符
                  _buildShimmerContainer(
                    width: 120,
                    height: 12,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  const SizedBox(height: 8),

                  // 基金公司占位符
                  _buildShimmerContainer(
                    width: 80,
                    height: 10,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // 收益率区域
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 日收益率占位符
                _buildShimmerContainer(
                  width: 60,
                  height: 18,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 4),

                // 累计收益率占位符
                _buildShimmerContainer(
                  width: 50,
                  height: 12,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerContainer({
    required double width,
    required double height,
    BorderRadius? borderRadius,
  }) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: borderRadius ?? BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + _shimmerAnimation.value, 0.0),
              end: Alignment(1.0 + _shimmerAnimation.value, 0.0),
              colors: [
                Colors.grey[300]!,
                Colors.grey[100]!,
                Colors.grey[300]!,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// 基金卡片加载状态管理器
///
/// 管理基金卡片的加载状态，提供智能的加载动画控制
class FundCardLoadingManager {
  static final FundCardLoadingManager _instance =
      FundCardLoadingManager._internal();
  factory FundCardLoadingManager() => _instance;
  FundCardLoadingManager._internal();

  final Map<String, bool> _loadingStates = {};
  final Map<String, DateTime> _loadingStartTimes = {};

  /// 标记基金卡片开始加载
  void startLoading(String fundCode) {
    _loadingStates[fundCode] = true;
    _loadingStartTimes[fundCode] = DateTime.now();
  }

  /// 标记基金卡片加载完成
  void finishLoading(String fundCode) {
    _loadingStates[fundCode] = false;
    _loadingStartTimes.remove(fundCode);
  }

  /// 检查基金卡片是否正在加载
  bool isLoading(String fundCode) {
    return _loadingStates[fundCode] ?? false;
  }

  /// 获取加载持续时间
  Duration? getLoadingDuration(String fundCode) {
    final startTime = _loadingStartTimes[fundCode];
    if (startTime == null) return null;
    return DateTime.now().difference(startTime);
  }

  /// 清理已完成的加载状态
  void cleanup() {
    final now = DateTime.now();
    _loadingStartTimes.removeWhere((fundCode, startTime) {
      if (now.difference(startTime).inMinutes > 5) {
        _loadingStates.remove(fundCode);
        return true;
      }
      return false;
    });
  }

  /// 获取当前加载中的基金数量
  int get loadingCount =>
      _loadingStates.values.where((loading) => loading).length;

  /// 清除所有加载状态
  void clearAll() {
    _loadingStates.clear();
    _loadingStartTimes.clear();
  }
}

/// 基金卡片智能加载包装器
///
/// 自动管理基金卡片的加载状态和动画显示
class SmartFundCardLoader extends StatefulWidget {
  final String fundCode;
  final Widget child;
  final Widget? loadingWidget;
  final Duration? timeout;
  final VoidCallback? onTimeout;
  final VoidCallback? onLoadComplete;

  const SmartFundCardLoader({
    super.key,
    required this.fundCode,
    required this.child,
    this.loadingWidget,
    this.timeout,
    this.onTimeout,
    this.onLoadComplete,
  });

  @override
  State<SmartFundCardLoader> createState() => _SmartFundCardLoaderState();
}

class _SmartFundCardLoaderState extends State<SmartFundCardLoader> {
  bool _isLoading = true;
  bool _isTimedOut = false;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _startLoading();
  }

  @override
  void didUpdateWidget(SmartFundCardLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fundCode != widget.fundCode) {
      _restartLoading();
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    FundCardLoadingManager().finishLoading(widget.fundCode);
    super.dispose();
  }

  void _startLoading() {
    setState(() {
      _isLoading = true;
      _isTimedOut = false;
    });

    FundCardLoadingManager().startLoading(widget.fundCode);

    // 设置超时计时器
    final timeout = widget.timeout ?? const Duration(seconds: 25);
    _timeoutTimer = Timer(timeout, () {
      if (mounted) {
        setState(() {
          _isTimedOut = true;
          _isLoading = false;
        });
        widget.onTimeout?.call();
      }
    });
  }

  void _restartLoading() {
    _timeoutTimer?.cancel();
    FundCardLoadingManager().finishLoading(widget.fundCode);
    _startLoading();
  }

  void _finishLoading() {
    _timeoutTimer?.cancel();
    if (mounted && _isLoading) {
      setState(() {
        _isLoading = false;
      });
      FundCardLoadingManager().finishLoading(widget.fundCode);
      widget.onLoadComplete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && !_isTimedOut) {
      return widget.loadingWidget ?? const FundCardShimmer();
    }

    if (_isTimedOut) {
      return _buildTimeoutWidget();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: widget.child,
    );
  }

  Widget _buildTimeoutWidget() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time, color: Colors.orange[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '加载超时',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '基金 ${widget.fundCode} 数据加载时间过长',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[600],
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _restartLoading,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }
}

/// 基金卡片加载状态指示器
///
/// 显示整体的加载进度和状态
class FundCardLoadingIndicator extends StatefulWidget {
  final int totalCards;
  final int loadedCards;
  final bool isLoading;

  const FundCardLoadingIndicator({
    super.key,
    required this.totalCards,
    required this.loadedCards,
    required this.isLoading,
  });

  @override
  State<FundCardLoadingIndicator> createState() =>
      _FundCardLoadingIndicatorState();
}

class _FundCardLoadingIndicatorState extends State<FundCardLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void didUpdateWidget(FundCardLoadingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loadedCards != widget.loadedCards) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading && widget.loadedCards >= widget.totalCards) {
      return const SizedBox.shrink();
    }

    final progress =
        widget.totalCards > 0 ? widget.loadedCards / widget.totalCards : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.isLoading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                  ),
                ),
              if (widget.isLoading) const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.isLoading ? '正在加载基金数据...' : '加载完成',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue[800],
                  ),
                ),
              ),
              Text(
                '${widget.loadedCards}/${widget.totalCards}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: progress * _progressAnimation.value,
                backgroundColor: Colors.blue[100],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
              );
            },
          ),
        ],
      ),
    );
  }
}
