import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/performance/performance_detector.dart';

// 临时定义缺失的常量，实际应该从主题系统导入
class BaseSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
}

class BorderRadiusTokens {
  static const double sm = 4.0;
  static const double full = 50.0;
}

class FontWeights {
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
}

class AppTextStyles {
  static const TextStyle bodySmall =
      TextStyle(fontSize: 14, fontWeight: FontWeight.w400);
  static const TextStyle body =
      TextStyle(fontSize: 16, fontWeight: FontWeight.w400);
  static const TextStyle caption =
      TextStyle(fontSize: 12, fontWeight: FontWeight.w400);
}

class NeutralColors {
  static const Color neutral500 = Color(0xFF9E9E9E);
  static const Color neutral600 = Color(0xFF757575);
}

class FinancialColors {
  static const Color positive = Color(0xFF4CAF50);
  static const Color negative = Color(0xFFF44336);
  static const Color neutral = Color(0xFF9E9E9E);
}

class FontFamilies {
  static const String numbers = 'monospace';
}

class AnimationCurves {
  static const Curve easeOutCubic = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve easeOut = Curves.easeOut;
}

/// 收益率指示器组件
///
/// 基于UX设计规范的金融数据专用收益率展示组件
/// 支持多种显示样式和动画效果
class ReturnIndicator extends StatefulWidget {
  /// 收益率数值
  final double value;

  /// 前一个数值
  final double? previousValue;

  /// 显示样式
  final ReturnIndicatorStyle style;

  /// 是否显示趋势
  final bool showTrend;

  /// 是否显示百分比
  final bool showPercentage;

  /// 是否启用动画
  final bool animate;

  /// 前缀文本
  final String? prefix;

  /// 后缀文本
  final String? suffix;

  /// 小数位数
  final int? decimalPlaces;

  /// 文本样式
  final TextStyle? textStyle;

  /// 是否启用实时更新
  final bool enableRealTimeUpdate;

  /// 更新间隔
  final Duration updateInterval;

  /// 实时数据流
  final Stream<double>? realTimeDataStream;

  /// 创建收益率指示器
  const ReturnIndicator({
    super.key,
    required this.value,
    this.previousValue,
    this.style = ReturnIndicatorStyle.standard,
    this.showTrend = true,
    this.showPercentage = true,
    this.animate = true,
    this.prefix,
    this.suffix,
    this.decimalPlaces,
    this.textStyle,
    this.enableRealTimeUpdate = false,
    this.updateInterval = const Duration(seconds: 5),
    this.realTimeDataStream,
  });

  @override
  State<ReturnIndicator> createState() => _ReturnIndicatorState();
}

class _ReturnIndicatorState extends State<ReturnIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _valueAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _trendAnimation;

  // 实时数据更新相关
  double _currentValue = 0.0;
  double _previousValue = 0.0;
  Timer? _updateTimer;
  StreamSubscription<double>? _dataStreamSubscription;

  // 性能监控相关
  PerformanceLevel _currentPerformanceLevel = PerformanceLevel.good;
  StreamSubscription<PerformanceResult>? _performanceSubscription;
  bool _enableAdvancedAnimations = true;

  @override
  void initState() {
    super.initState();
    _initializeValues();
    _initializePerformanceMonitoring();
    _initializeAnimations();
    _setupRealTimeUpdates();

    if (widget.animate) {
      _animationController.forward();
    }
  }

  void _initializeValues() {
    _currentValue = widget.value;
    _previousValue = widget.previousValue ?? widget.value;
  }

  void _initializePerformanceMonitoring() {
    _currentPerformanceLevel = PerformanceAdaptiveManager.instance.currentLevel;
    _enableAdvancedAnimations =
        _currentPerformanceLevel != PerformanceLevel.poor;

    _performanceSubscription = SmartPerformanceDetector.instance
        .detectPerformance()
        .asStream()
        .listen((result) {
      if (result.level != _currentPerformanceLevel && mounted) {
        setState(() {
          _currentPerformanceLevel = result.level;
          _enableAdvancedAnimations = result.level != PerformanceLevel.poor;
        });
      }
    });
  }

  void _initializeAnimations() {
    final duration = _getAdaptiveAnimationDuration();
    _animationController = AnimationController(
      duration: Duration(milliseconds: duration),
      vsync: this,
    );

    if (widget.animate) {
      _valueAnimation = Tween<double>(
        begin: _previousValue,
        end: _currentValue,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: _enableAdvancedAnimations
            ? AnimationCurves.easeOutCubic
            : Curves.linear,
      ));

      final startColor = _getColorForValue(_previousValue);
      final endColor = _getColorForValue(_currentValue);
      _colorAnimation = ColorTween(
        begin: startColor,
        end: endColor,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: AnimationCurves.easeInOut,
      ));

      _trendAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.5, 1.0, curve: AnimationCurves.easeOut),
      ));
    }
  }

  void _setupRealTimeUpdates() {
    if (!widget.enableRealTimeUpdate) return;

    if (widget.realTimeDataStream != null) {
      _dataStreamSubscription = widget.realTimeDataStream!.listen(_onNewValue);
    } else {
      _updateTimer = Timer.periodic(widget.updateInterval, (_) {
        _simulateRealTimeUpdate();
      });
    }
  }

  void _onNewValue(double newValue) {
    if (!mounted) return;

    setState(() {
      _previousValue = _currentValue;
      _currentValue = newValue;
    });

    if (widget.animate && _enableAdvancedAnimations) {
      _restartAnimation();
    }
  }

  void _simulateRealTimeUpdate() {
    final random = DateTime.now().millisecond % 100;
    final change = (random - 50) / 1000; // -0.05 到 0.05 的变化
    final newValue = (_currentValue + change).clamp(-100.0, 100.0);
    _onNewValue(newValue);
  }

  void _restartAnimation() {
    _animationController.reset();
    _initializeAnimations();
    _animationController.forward();
  }

  int _getAdaptiveAnimationDuration() {
    if (!_enableAdvancedAnimations) return 0;

    return PerformanceAdaptiveManager.instance
        .getAdaptiveAnimationDuration(Duration(milliseconds: 300))
        .inMilliseconds;
  }

  @override
  void dispose() {
    if (widget.animate) {
      _animationController.dispose();
    }
    _updateTimer?.cancel();
    _dataStreamSubscription?.cancel();
    _performanceSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return _buildStaticContent();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return _buildAnimatedContent();
      },
    );
  }

  Widget _buildStaticContent() {
    return _buildContent(
      value: widget.value,
      color: _getColorForValue(widget.value),
      trendOpacity: 1.0,
    );
  }

  Widget _buildAnimatedContent() {
    return _buildContent(
      value: _valueAnimation.value,
      color: _colorAnimation.value,
      trendOpacity: _trendAnimation.value,
    );
  }

  Widget _buildContent({
    required double value,
    required Color? color,
    required double trendOpacity,
  }) {
    switch (widget.style) {
      case ReturnIndicatorStyle.compact:
        return _buildCompactStyle(value, color, trendOpacity);
      case ReturnIndicatorStyle.card:
        return _buildCardStyle(value, color, trendOpacity);
      case ReturnIndicatorStyle.badge:
        return _buildBadgeStyle(value, color, trendOpacity);
      case ReturnIndicatorStyle.standard:
        return _buildStandardStyle(value, color, trendOpacity);
    }
  }

  Widget _buildStandardStyle(double value, Color? color, double trendOpacity) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showTrend) ...[
          _buildTrendIcon(value, color, trendOpacity),
          const SizedBox(width: BaseSpacing.xs),
        ],
        Flexible(
          child: _buildValueText(value, color),
        ),
      ],
    );
  }

  Widget _buildCompactStyle(double value, Color? color, double trendOpacity) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showTrend && value != 0) ...[
          _buildTrendIcon(value, color, trendOpacity, size: 12),
          const SizedBox(width: 2),
        ],
        _buildValueText(value, color, compact: true),
      ],
    );
  }

  Widget _buildCardStyle(double value, Color? color, double trendOpacity) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BaseSpacing.sm,
        vertical: BaseSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color?.withOpacity(0.1) ?? Colors.transparent,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: Border.all(
          color: color ?? Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showTrend) ...[
            _buildTrendIcon(value, color, trendOpacity),
            const SizedBox(width: BaseSpacing.xs),
          ],
          _buildValueText(value, color),
        ],
      ),
    );
  }

  Widget _buildBadgeStyle(double value, Color? color, double trendOpacity) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BaseSpacing.sm,
        vertical: BaseSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color ?? NeutralColors.neutral500,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showTrend && value != 0) ...[
            Icon(
              value > 0 ? Icons.arrow_upward : Icons.arrow_downward,
              size: 12,
              color: Colors.white,
            ),
            const SizedBox(width: 2),
          ],
          _buildValueText(
            value,
            Colors.white,
            compact: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendIcon(double value, Color? color, double opacity,
      {double? size}) {
    if (value == 0) {
      return SizedBox.shrink();
    }

    final iconSize = size ?? 16.0;
    final iconColor = color ?? _getColorForValue(value);

    return Opacity(
      opacity: opacity,
      child: Icon(
        value > 0 ? Icons.arrow_upward : Icons.arrow_downward,
        size: iconSize,
        color: iconColor,
      ),
    );
  }

  Widget _buildValueText(double value, Color? color, {bool compact = false}) {
    final formattedValue = _formatValue(value);
    final defaultStyle = compact
        ? (widget.textStyle ?? AppTextStyles.bodySmall)
        : (widget.textStyle ?? AppTextStyles.body);

    return Text.rich(
      TextSpan(
        children: [
          if (widget.prefix != null)
            TextSpan(
              text: widget.prefix,
              style: defaultStyle.copyWith(color: color),
            ),
          TextSpan(
            text: formattedValue,
            style: defaultStyle.copyWith(
              color: color,
              fontFamily: FontFamilies.numbers,
              fontWeight: compact ? FontWeights.medium : FontWeights.semiBold,
            ),
          ),
          if (widget.showPercentage)
            TextSpan(
              text: '%',
              style: defaultStyle.copyWith(
                color: color,
                fontWeight: compact ? FontWeights.medium : FontWeights.semiBold,
              ),
            ),
          if (widget.suffix != null)
            TextSpan(
              text: widget.suffix,
              style: defaultStyle.copyWith(color: color),
            ),
        ],
      ),
    );
  }

  String _formatValue(double value) {
    final places = widget.decimalPlaces ?? (value.abs() < 1 ? 4 : 2);
    var formatted = value.abs().toStringAsFixed(places);

    // 移除尾随的零
    if (formatted.contains('.')) {
      formatted = formatted.replaceAll(RegExp(r'0+$'), '');
      formatted = formatted.replaceAll(RegExp(r'\.$'), '');
    }

    return '${value >= 0 ? '' : '-'}$formatted';
  }

  Color _getColorForValue(double value) {
    if (value > 0) {
      return FinancialColors.positive;
    } else if (value < 0) {
      return FinancialColors.negative;
    } else {
      return FinancialColors.neutral;
    }
  }
}

/// 收益率指示器样式
enum ReturnIndicatorStyle {
  /// 标准样式：图标 + 数值
  standard,

  /// 紧凑样式：适用于小空间
  compact,

  /// 卡片样式：带背景和边框
  card,

  /// 徽章样式：圆角背景
  badge,
}

/// 收益率变化指示器
///
/// 显示收益率变化的专用组件，支持历史对比
class ReturnChangeIndicator extends StatelessWidget {
  /// 当前值
  final double currentValue;

  /// 前一个值
  final double previousValue;

  /// 是否显示变化
  final bool showChange;

  /// 显示样式
  final ReturnIndicatorStyle style;

  /// 文本样式
  final TextStyle? textStyle;

  /// 创建收益率变化指示器
  const ReturnChangeIndicator({
    super.key,
    required this.currentValue,
    required this.previousValue,
    this.showChange = true,
    this.style = ReturnIndicatorStyle.standard,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final change = currentValue - previousValue;
    final changePercent =
        previousValue != 0 ? (change / previousValue.abs()) * 100 : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 当前值
        ReturnIndicator(
          value: currentValue,
          style: style,
          showTrend: false,
          textStyle: textStyle,
        ),

        if (showChange) ...[
          const SizedBox(height: BaseSpacing.xs),
          // 变化值
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                change > 0 ? Icons.trending_up : Icons.trending_down,
                size: 12,
                color: change > 0
                    ? FinancialColors.positive
                    : FinancialColors.negative,
              ),
              const SizedBox(width: 4),
              Text(
                '${change > 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
                style: (textStyle ?? AppTextStyles.caption).copyWith(
                  color: change > 0
                      ? FinancialColors.positive
                      : FinancialColors.negative,
                  fontWeight: FontWeights.medium,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// 多时期收益率指示器
///
/// 显示多个时期收益率的组件
class MultiPeriodReturnIndicator extends StatelessWidget {
  /// 收益率数据
  final Map<String, double> returns;

  /// 时间周期列表
  final List<String> periods;

  /// 是否显示标签
  final bool showLabels;

  /// 对齐方式
  final CrossAxisAlignment alignment;

  /// 创建多时期收益率指示器
  const MultiPeriodReturnIndicator({
    super.key,
    required this.returns,
    this.periods = const ['日', '周', '月', '季', '年'],
    this.showLabels = true,
    this.alignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      children: periods.map((period) {
        final value = returns[period];
        if (value == null) return SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: BaseSpacing.xs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showLabels) ...[
                SizedBox(
                  width: 24,
                  child: Text(
                    period,
                    style: AppTextStyles.caption.copyWith(
                      color: NeutralColors.neutral600,
                    ),
                  ),
                ),
                const SizedBox(width: BaseSpacing.sm),
              ],
              ReturnIndicator(
                value: value,
                style: ReturnIndicatorStyle.compact,
                showTrend: true,
                showPercentage: true,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
