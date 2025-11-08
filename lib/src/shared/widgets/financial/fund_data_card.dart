import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/performance/performance_detector.dart';
import '../../../core/theme/app_theme.dart' hide PerformanceLevel;
import '../../../core/theme/design_tokens/app_colors.dart';
import '../../../core/theme/design_tokens/app_spacing.dart';
import '../../../core/theme/design_tokens/app_typography.dart';
import '../../../features/fund/domain/entities/fund.dart';

/// 基金数据卡片组件
///
/// 基于UX设计规范的专业基金数据展示卡片
/// 支持标准/紧凑/详细三种显示模式
class FundDataCard extends StatefulWidget {
  final Fund fund;
  final FundDataCardMode mode;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onCompare;
  final bool isFavorite;
  final bool isSelected;
  final EdgeInsets? margin;
  final bool showShadow;
  final Animation<double>? animation;

  const FundDataCard({
    Key? key,
    required this.fund,
    this.mode = FundDataCardMode.standard,
    this.onTap,
    this.onFavorite,
    this.onCompare,
    this.isFavorite = false,
    this.isSelected = false,
    this.margin,
    this.showShadow = true,
    this.animation,
  }) : super(key: key);

  @override
  State<FundDataCard> createState() => _FundDataCardState();
}

class _FundDataCardState extends State<FundDataCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  // 性能监控相关
  PerformanceLevel _currentPerformanceLevel = PerformanceLevel.good;
  bool _enableAdvancedAnimations = true;
  bool _enableGlassmorphism = true;
  late StreamSubscription<PerformanceResult> _performanceSubscription;

  @override
  void initState() {
    super.initState();
    _initializePerformanceMonitoring();
    _initializeAnimations();
    _animationController.forward();
  }

  void _initializePerformanceMonitoring() {
    // 获取当前性能等级
    _currentPerformanceLevel = PerformanceAdaptiveManager.instance.currentLevel;
    _adaptToPerformanceLevel(_currentPerformanceLevel);

    // 监听性能变化
    _performanceSubscription = SmartPerformanceDetector.instance
        .detectPerformance()
        .asStream()
        .listen((result) {
      if (result.level != _currentPerformanceLevel && mounted) {
        setState(() {
          _currentPerformanceLevel = result.level;
          _adaptToPerformanceLevel(result.level);
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

    if (widget.animation != null) {
      _scaleAnimation = widget.animation!;
      _opacityAnimation = widget.animation!;
    } else {
      final curve =
          _enableAdvancedAnimations ? Curves.easeInOut : Curves.linear;

      _scaleAnimation = Tween<double>(
        begin: _enableAdvancedAnimations ? 0.95 : 1.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: curve,
      ));

      _opacityAnimation = Tween<double>(
        begin: _enableAdvancedAnimations ? 0.0 : 1.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ));
    }
  }

  void _adaptToPerformanceLevel(PerformanceLevel level) {
    switch (level) {
      case PerformanceLevel.excellent:
        _enableAdvancedAnimations = true;
        _enableGlassmorphism = true;
        break;
      case PerformanceLevel.good:
        _enableAdvancedAnimations = true;
        _enableGlassmorphism = true;
        break;
      case PerformanceLevel.fair:
        _enableAdvancedAnimations = true;
        _enableGlassmorphism = false;
        break;
      case PerformanceLevel.poor:
        _enableAdvancedAnimations = false;
        _enableGlassmorphism = false;
        break;
    }
  }

  int _getAdaptiveAnimationDuration() {
    return PerformanceAdaptiveManager.instance
        .getAdaptiveAnimationDuration(Duration(milliseconds: 300))
        .inMilliseconds;
  }

  @override
  void dispose() {
    if (widget.animation == null) {
      _animationController.dispose();
    }
    _performanceSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: widget.animation ?? _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: _buildCard(context, isDark),
          ),
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, bool isDark) {
    return Container(
      margin: widget.margin ?? EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(BorderRadiusTokens.card),
          child: AnimatedContainer(
            duration: Duration(milliseconds: _getAdaptiveAnimationDuration()),
            curve: _enableAdvancedAnimations ? Curves.easeInOut : Curves.linear,
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? (isDark ? BaseColors.primary900 : BaseColors.primary50)
                  : Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(BorderRadiusTokens.card),
              border: Border.all(
                color: widget.isSelected
                    ? BaseColors.primary500
                    : (isDark
                        ? NeutralColors.neutral700
                        : NeutralColors.neutral200),
                width: widget.isSelected ? 2.0 : 1.0,
              ),
              boxShadow: widget.showShadow ? _getAdaptiveShadow(isDark) : null,
            ),
            child: Stack(
              children: [
                Padding(
                  padding: _getPadding(),
                  child: _buildContent(),
                ),
                // 性能指示器
                if (_shouldShowPerformanceIndicator())
                  Positioned(
                    top: 4,
                    right: 4,
                    child: _buildPerformanceIndicator(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<BoxShadow> _getAdaptiveShadow(bool isDark) {
    if (!_enableAdvancedAnimations ||
        _currentPerformanceLevel == PerformanceLevel.poor) {
      return [];
    }

    switch (_currentPerformanceLevel) {
      case PerformanceLevel.excellent:
        return isDark ? _darkEnhancedShadow : _lightEnhancedShadow;
      case PerformanceLevel.good:
        return isDark ? _darkShadow : _lightShadow;
      case PerformanceLevel.fair:
        return isDark ? _darkSimpleShadow : _lightSimpleShadow;
      case PerformanceLevel.poor:
        return [];
    }
  }

  bool _shouldShowPerformanceIndicator() {
    return _currentPerformanceLevel == PerformanceLevel.poor ||
        _currentPerformanceLevel == PerformanceLevel.fair;
  }

  Widget _buildPerformanceIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: _getPerformanceLevelColor(_currentPerformanceLevel)
            .withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _getPerformanceIcon(),
        size: 12,
        color: Colors.white,
      ),
    );
  }

  Color _getPerformanceLevelColor(PerformanceLevel level) {
    switch (level) {
      case PerformanceLevel.excellent:
        return SemanticColors.success500;
      case PerformanceLevel.good:
        return BaseColors.primary500;
      case PerformanceLevel.fair:
        return SemanticColors.warning500;
      case PerformanceLevel.poor:
        return SemanticColors.error500;
    }
  }

  IconData _getPerformanceIcon() {
    switch (_currentPerformanceLevel) {
      case PerformanceLevel.excellent:
        return Icons.speed;
      case PerformanceLevel.good:
        return Icons.check_circle;
      case PerformanceLevel.fair:
        return Icons.info;
      case PerformanceLevel.poor:
        return Icons.warning;
    }
  }

  Widget _buildContent() {
    switch (widget.mode) {
      case FundDataCardMode.compact:
        return _buildCompactLayout();
      case FundDataCardMode.detailed:
        return _buildDetailedLayout();
      case FundDataCardMode.standard:
      default:
        return _buildStandardLayout();
    }
  }

  Widget _buildStandardLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 头部：基金代码和操作按钮
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.fund.code,
                    style: AppTextStyles.h6.copyWith(
                      color: BaseColors.primary500,
                      fontFamily: FontFamilies.numbers,
                    ),
                  ),
                  const SizedBox(height: ComponentSpacing.paddingXS),
                  Text(
                    widget.fund.name,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: NeutralColors.neutral600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFavoriteButton(),
                const SizedBox(width: ComponentSpacing.paddingSM),
                _buildCompareButton(),
              ],
            ),
          ],
        ),
        const SizedBox(height: ComponentSpacing.paddingMD),

        // 中部：核心数据
        Row(
          children: [
            Expanded(
              child: _buildPriceDisplay(),
            ),
            const SizedBox(width: ComponentSpacing.paddingMD),
            Expanded(
              child: _buildReturnDisplay(),
            ),
          ],
        ),
        const SizedBox(height: ComponentSpacing.paddingMD),

        // 底部：风险等级
        _buildRiskLevel(),
      ],
    );
  }

  Widget _buildCompactLayout() {
    return Row(
      children: [
        // 基金信息
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.fund.code,
                style: AppTextStyles.body.copyWith(
                  color: BaseColors.primary500,
                  fontFamily: FontFamilies.numbers,
                  fontWeight: FontWeights.semiBold,
                ),
              ),
              const SizedBox(height: ComponentSpacing.paddingXS),
              Text(
                widget.fund.name,
                style: AppTextStyles.caption.copyWith(
                  color: NeutralColors.neutral500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // 收益率
        Expanded(
          child: _buildReturnDisplay(compact: true),
        ),

        // 操作按钮
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFavoriteButton(compact: true),
            const SizedBox(width: ComponentSpacing.paddingXS),
            _buildCompareButton(compact: true),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailedLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 头部
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.fund.code,
                        style: AppTextStyles.h5.copyWith(
                          color: BaseColors.primary500,
                          fontFamily: FontFamilies.numbers,
                        ),
                      ),
                      const SizedBox(width: ComponentSpacing.paddingSM),
                      _buildRiskLevel(),
                    ],
                  ),
                  const SizedBox(height: ComponentSpacing.paddingXS),
                  Text(
                    widget.fund.name,
                    style: AppTextStyles.body.copyWith(
                      color: NeutralColors.neutral700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFavoriteButton(),
                const SizedBox(width: ComponentSpacing.paddingSM),
                _buildCompareButton(),
              ],
            ),
          ],
        ),
        const SizedBox(height: ComponentSpacing.paddingLG),

        // 详细数据行
        Row(
          children: [
            Expanded(
                child: _buildDetailedInfoItem(
                    '净值', widget.fund.unitNav.toStringAsFixed(4))),
            Expanded(child: _buildDetailedInfoItem('涨跌', _getChangePercent())),
            Expanded(child: _buildDetailedInfoItem('日收益', _getDailyReturn())),
          ],
        ),
        const SizedBox(height: ComponentSpacing.paddingMD),

        Row(
          children: [
            Expanded(child: _buildDetailedInfoItem('成立时间', widget.fund.date)),
            Expanded(
                child: _buildDetailedInfoItem(
                    '基金规模', _formatAssets(widget.fund.scale))),
            Expanded(
                child: _buildDetailedInfoItem('基金经理', widget.fund.manager)),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '净值',
          style: AppTextStyles.caption.copyWith(
            color: NeutralColors.neutral500,
          ),
        ),
        const SizedBox(height: ComponentSpacing.paddingXS),
        Text(
          widget.fund.unitNav.toStringAsFixed(4),
          style: AppTextStyles.priceMedium.copyWith(
            color: NeutralColors.neutral900,
            fontFamily: FontFamilies.numbers,
          ),
        ),
      ],
    );
  }

  Widget _buildReturnDisplay({bool compact = false}) {
    final returnPercent = widget.fund.dailyReturn;
    final isPositive = returnPercent > 0;
    final isNegative = returnPercent < 0;

    return Column(
      crossAxisAlignment:
          compact ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          '日收益',
          style: AppTextStyles.caption.copyWith(
            color: NeutralColors.neutral500,
          ),
        ),
        const SizedBox(height: ComponentSpacing.paddingXS),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!compact && isPositive) ...[
              Icon(
                Icons.arrow_upward,
                size: 16,
                color: FinancialColors.positive,
              ),
              const SizedBox(width: 2),
            ] else if (!compact && isNegative) ...[
              Icon(
                Icons.arrow_downward,
                size: 16,
                color: FinancialColors.negative,
              ),
              const SizedBox(width: 2),
            ],
            Text(
              '${isPositive ? '+' : ''}${returnPercent.toStringAsFixed(2)}%',
              style: (compact ? AppTextStyles.body : AppTextStyles.priceSmall)
                  .copyWith(
                color: isPositive
                    ? FinancialColors.positive
                    : isNegative
                        ? FinancialColors.negative
                        : FinancialColors.neutral,
                fontFamily: FontFamilies.numbers,
                fontWeight: FontWeights.semiBold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRiskLevel() {
    final riskLevel = _getRiskLevel();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ComponentSpacing.paddingSM,
        vertical: ComponentSpacing.paddingXS,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [riskLevel.startColor, riskLevel.endColor],
        ),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.xs),
      ),
      child: Text(
        riskLevel.label,
        style: AppTextStyles.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeights.medium,
        ),
      ),
    );
  }

  Widget _buildFavoriteButton({bool compact = false}) {
    return InkWell(
      onTap: widget.onFavorite,
      borderRadius: BorderRadius.circular(BorderRadiusTokens.full),
      child: Container(
        padding: EdgeInsets.all(
            compact ? ComponentSpacing.paddingXS : ComponentSpacing.paddingSM),
        child: Icon(
          widget.isFavorite ? Icons.favorite : Icons.favorite_border,
          size: compact ? 16 : 20,
          color: widget.isFavorite
              ? FinancialColors.positive
              : NeutralColors.neutral400,
        ),
      ),
    );
  }

  Widget _buildCompareButton({bool compact = false}) {
    return InkWell(
      onTap: widget.onCompare,
      borderRadius: BorderRadius.circular(BorderRadiusTokens.full),
      child: Container(
        padding: EdgeInsets.all(
            compact ? ComponentSpacing.paddingXS : ComponentSpacing.paddingSM),
        child: Icon(
          Icons.compare_arrows,
          size: compact ? 16 : 20,
          color: widget.isSelected
              ? BaseColors.primary500
              : NeutralColors.neutral400,
        ),
      ),
    );
  }

  Widget _buildDetailedInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: NeutralColors.neutral500,
          ),
        ),
        const SizedBox(height: ComponentSpacing.paddingXS),
        Text(
          value,
          style: AppTextStyles.body.copyWith(
            color: NeutralColors.neutral800,
            fontWeight: FontWeights.medium,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  EdgeInsets _getPadding() {
    switch (widget.mode) {
      case FundDataCardMode.compact:
        return const EdgeInsets.all(ComponentSpacing.paddingMD);
      case FundDataCardMode.detailed:
        return const EdgeInsets.all(ComponentSpacing.paddingLG);
      case FundDataCardMode.standard:
      default:
        return const EdgeInsets.all(ComponentSpacing.paddingMD);
    }
  }

  RiskLevelInfo _getRiskLevel() {
    // 根据基金类型或风险等级返回风险信息
    // 这里需要根据实际的基金数据结构调整
    if (widget.fund.type.contains('股票') || widget.fund.type.contains('混合')) {
      return RiskLevelInfo(
        label: '中高风险',
        startColor: RiskColors.mediumRiskStart,
        endColor: RiskColors.mediumRiskEnd,
      );
    } else if (widget.fund.type.contains('债券')) {
      return RiskLevelInfo(
        label: '中低风险',
        startColor: RiskColors.lowRiskStart,
        endColor: RiskColors.lowRiskEnd,
      );
    } else {
      return RiskLevelInfo(
        label: '低风险',
        startColor: RiskColors.lowRiskStart,
        endColor: RiskColors.lowRiskEnd,
      );
    }
  }

  String _getChangePercent() {
    return '${widget.fund.dailyReturn > 0 ? '+' : ''}${widget.fund.dailyReturn.toStringAsFixed(2)}%';
  }

  String _getDailyReturn() {
    return '${widget.fund.dailyReturn > 0 ? '+' : ''}${widget.fund.dailyReturn.toStringAsFixed(4)}';
  }

  String _formatAssets(double assets) {
    if (assets >= 100000000) {
      return '${(assets / 100000000).toStringAsFixed(1)}亿';
    } else if (assets >= 10000) {
      return '${(assets / 10000).toStringAsFixed(1)}万';
    } else {
      return assets.toStringAsFixed(0);
    }
  }

  static const List<BoxShadow> _lightShadow = [
    BoxShadow(
      color: Color(0x0F000000),
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -1,
    ),
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: -1,
    ),
  ];

  static const List<BoxShadow> _darkShadow = [
    BoxShadow(
      color: Color(0x29000000),
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -1,
    ),
  ];

  // 增强阴影 (高性能设备)
  static const List<BoxShadow> _lightEnhancedShadow = [
    BoxShadow(
      color: Color(0x15000000),
      offset: Offset(0, 8),
      blurRadius: 12,
      spreadRadius: -2,
    ),
    BoxShadow(
      color: Color(0x1F000000),
      offset: Offset(0, 4),
      blurRadius: 8,
      spreadRadius: -1,
    ),
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 1),
      blurRadius: 3,
    ),
  ];

  static const List<BoxShadow> _darkEnhancedShadow = [
    BoxShadow(
      color: Color(0x3D000000),
      offset: Offset(0, 8),
      blurRadius: 12,
      spreadRadius: -2,
    ),
    BoxShadow(
      color: Color(0x29000000),
      offset: Offset(0, 4),
      blurRadius: 8,
      spreadRadius: -1,
    ),
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 1),
      blurRadius: 3,
    ),
  ];

  // 简单阴影 (中等性能设备)
  static const List<BoxShadow> _lightSimpleShadow = [
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 2),
      blurRadius: 4,
    ),
  ];

  static const List<BoxShadow> _darkSimpleShadow = [
    BoxShadow(
      color: Color(0x1F000000),
      offset: Offset(0, 2),
      blurRadius: 4,
    ),
  ];
}

/// 基金数据卡片显示模式
enum FundDataCardMode {
  /// 标准模式：显示基本信息
  standard,

  /// 紧凑模式：适用于列表视图
  compact,

  /// 详细模式：显示完整信息
  detailed,
}

/// 风险等级信息
class RiskLevelInfo {
  final String label;
  final Color startColor;
  final Color endColor;

  const RiskLevelInfo({
    required this.label,
    required this.startColor,
    required this.endColor,
  });
}
