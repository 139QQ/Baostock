/// 基础图表组件抽象类
///
/// 为所有图表组件提供通用的基础功能，包括：
/// - 主题管理
/// - 交互处理
/// - 响应式布局
/// - 动画支持
/// - 生命周期管理
library base_chart_widget;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'models/chart_data.dart';
import 'chart_theme_manager.dart';

/// 图表组件状态
enum ChartState {
  idle, // 空闲状态
  loading, // 加载中
  ready, // 就绪状态
  error, // 错误状态
  animating, // 动画中
}

/// 基础图表组件抽象类
///
/// 所有具体图表组件都应该继承此类，实现通用的图表功能
abstract class BaseChartWidget extends StatefulWidget {
  const BaseChartWidget({
    super.key,
    required this.config,
    this.onInteraction,
    this.enableAnimation = true,
    this.customTheme,
  });

  /// 图表配置
  final ChartConfig config;

  /// 交互事件回调
  final Function(ChartInteractionEvent)? onInteraction;

  /// 是否启用动画
  final bool enableAnimation;

  /// 自定义主题（如果为null，则使用全局主题）
  final ChartTheme? customTheme;

  @override
  State<BaseChartWidget> createState() => _BaseChartWidgetState();
}

/// 基础图表组件状态实现
class _BaseChartWidgetState extends BaseChartWidgetState<BaseChartWidget> {
  @override
  Future<void> initializeChart() async {
    // 默认实现
  }

  @override
  Future<void> reloadChart() async {
    // 默认实现
  }

  @override
  Widget buildChart(BuildContext context) {
    return const SizedBox.shrink();
  }

  @override
  void onConfigUpdated(ChartConfig oldConfig, ChartConfig newConfig) {
    // 默认实现
  }

  @override
  void onInteraction(ChartInteractionEvent event) {
    // 默认实现
  }

  @override
  void cleanupChart() {
    // 默认实现
  }
}

/// 基础图表组件状态类
///
/// 提供所有图表组件的通用状态管理
abstract class BaseChartWidgetState<T extends BaseChartWidget> extends State<T>
    with TickerProviderStateMixin {
  late ChartTheme _theme;
  ChartState _chartState = ChartState.idle;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _animation;

  /// 获取当前主题
  ChartTheme get theme => _theme;

  /// 获取当前图表状态
  ChartState get chartState => _chartState;

  /// 获取错误信息
  String? get errorMessage => _errorMessage;

  /// 获取动画控制器
  AnimationController get animationController => _animationController;

  /// 获取动画值
  Animation<double> get animation => _animation;

  @override
  void initState() {
    super.initState();
    _initializeTheme();
    _initializeAnimation();
    _initializeChart();
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.customTheme != oldWidget.customTheme) {
      _initializeTheme();
    }
    _onConfigChanged(oldWidget.config, widget.config);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cleanupChart();
    super.dispose();
  }

  /// 初始化主题
  void _initializeTheme() {
    _theme = widget.customTheme ?? ChartThemeManager.instance.currentTheme;
    ChartThemeManager.instance.addListener(_onThemeChanged);
  }

  /// 初始化动画
  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: widget.config.animationDuration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  /// 主题变化回调
  void _onThemeChanged() {
    if (mounted && widget.customTheme == null) {
      setState(() {
        _theme = ChartThemeManager.instance.currentTheme;
      });
    }
  }

  /// 配置变化回调
  void _onConfigChanged(ChartConfig oldConfig, ChartConfig newConfig) {
    if (oldConfig.animationDuration != newConfig.animationDuration) {
      _animationController.duration = newConfig.animationDuration;
    }
    _onConfigUpdated(oldConfig, newConfig);
  }

  /// 设置图表状态
  void setChartState(ChartState state, {String? errorMessage}) {
    if (mounted) {
      setState(() {
        _chartState = state;
        _errorMessage = errorMessage;
      });
    }
  }

  /// 触发交互事件
  void triggerInteraction(ChartInteractionEvent event) {
    widget.onInteraction?.call(event);
    _onInteraction(event);
  }

  /// 开始动画
  Future<void> startAnimation() async {
    if (widget.enableAnimation && mounted) {
      setChartState(ChartState.animating);
      await _animationController.forward();
      if (mounted) {
        setChartState(ChartState.ready);
      }
    }
  }

  /// 重置动画
  void resetAnimation() {
    _animationController.reset();
  }

  /// 获取响应式尺寸
  Size getResponsiveSize(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    double? width = widget.config.width;
    double? height = widget.config.height;

    // 如果没有指定宽度，使用响应式宽度
    width ??= _getResponsiveWidth(screenWidth);

    // 如果没有指定高度，使用响应式高度
    height ??= ChartThemeManager.instance.getResponsiveChartHeight(context);

    return Size(width, height);
  }

  /// 获取响应式宽度
  double _getResponsiveWidth(double screenWidth) {
    if (screenWidth < 600) {
      return screenWidth - 32; // 移动端：减去边距
    } else if (screenWidth < 1200) {
      return (screenWidth * 0.8).clamp(400, 800); // 平板
    } else {
      return (screenWidth * 0.6).clamp(600, 1200); // 桌面端
    }
  }

  /// 获取响应式内边距
  EdgeInsets getResponsivePadding(BuildContext context) {
    return ChartThemeManager.instance.getResponsivePadding(context);
  }

  /// 构建加载指示器
  Widget buildLoadingIndicator(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: _theme.primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            '加载图表数据中...',
            style: _theme.legendStyle.copyWith(
              color: _theme.textColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建错误提示
  Widget buildErrorWidget(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: _theme.textColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '图表加载失败',
            style: _theme.titleStyle.copyWith(
              color: _theme.textColor.withOpacity(0.7),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: _theme.legendStyle.copyWith(
                color: _theme.textColor.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _retryLoading,
            style: ElevatedButton.styleFrom(
              backgroundColor: _theme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  /// 构建图表容器
  Widget buildChartContainer(BuildContext context, Widget child) {
    final responsiveSize = getResponsiveSize(context);
    final responsivePadding = getResponsivePadding(context);

    return Container(
      width: responsiveSize.width,
      height: responsiveSize.height,
      margin: widget.config.margin,
      padding: responsivePadding,
      decoration: BoxDecoration(
        color: widget.config.backgroundColor ?? _theme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.config.title != null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                widget.config.title!,
                style: _theme.titleStyle,
              ),
            ),
          ],
          Expanded(child: child),
        ],
      ),
    );
  }

  /// 重试加载
  void _retryLoading() {
    setChartState(ChartState.loading);
    _reloadChart();
  }

  @override
  Widget build(BuildContext context) {
    return buildChartContainer(
      context,
      _buildChartContent(context),
    );
  }

  /// 构建图表内容
  Widget _buildChartContent(BuildContext context) {
    switch (_chartState) {
      case ChartState.loading:
        return buildLoadingIndicator(context);
      case ChartState.error:
        return buildErrorWidget(context);
      case ChartState.idle:
      case ChartState.ready:
      case ChartState.animating:
        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Opacity(
              opacity: widget.enableAnimation ? _animation.value : 1.0,
              child: Transform.scale(
                scale: widget.enableAnimation
                    ? 0.8 + (_animation.value * 0.2)
                    : 1.0,
                child: buildChart(context),
              ),
            );
          },
        );
    }
  }

  // 抽象方法 - 子类必须实现

  /// 初始化图表
  void _initializeChart() {
    setChartState(ChartState.loading);
    initializeChart().then((_) {
      if (mounted) {
        setChartState(ChartState.ready);
        startAnimation();
      }
    }).catchError((error) {
      setChartState(ChartState.error, errorMessage: error.toString());
    });
  }

  /// 子类实现的初始化方法
  Future<void> initializeChart();

  /// 重新加载图表
  void _reloadChart() {
    reloadChart().then((_) {
      if (mounted) {
        setChartState(ChartState.ready);
        startAnimation();
      }
    }).catchError((error) {
      setChartState(ChartState.error, errorMessage: error.toString());
    });
  }

  /// 子类实现的重新加载方法
  Future<void> reloadChart();

  /// 构建具体图表
  Widget buildChart(BuildContext context);

  /// 配置更新回调
  void _onConfigUpdated(ChartConfig oldConfig, ChartConfig newConfig) {
    onConfigUpdated(oldConfig, newConfig);
  }

  /// 子类实现的配置更新方法
  void onConfigUpdated(ChartConfig oldConfig, ChartConfig newConfig);

  /// 交互事件处理
  void _onInteraction(ChartInteractionEvent event) {
    onInteraction(event);
  }

  /// 子类实现的交互处理方法
  void onInteraction(ChartInteractionEvent event);

  /// 清理资源
  void _cleanupChart() {
    cleanupChart();
  }

  /// 子类实现的清理方法
  void cleanupChart();

  /// 处理键盘事件
  KeyEventResult handleKeyEvent(FocusNode node, KeyEvent event) {
    return KeyEventResult.ignored;
  }

  /// 处理鼠标事件
  void handleMouseEvent(PointerEvent event) {
    // 默认实现为空，子类可以重写
  }

  /// 获取图表数据的统计信息
  Map<String, dynamic> getChartDataStats() {
    return {};
  }

  /// 导出图表数据
  Map<String, dynamic> exportChartData() {
    return {
      'config': widget.config,
      'theme': _theme,
      'stats': getChartDataStats(),
    };
  }
}
