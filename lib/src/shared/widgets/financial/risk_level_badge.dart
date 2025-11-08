import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens/app_colors.dart';
import '../../../core/theme/design_tokens/app_spacing.dart';
import '../../../core/theme/design_tokens/app_typography.dart';

/// 风险等级标签组件
///
/// 基于UX设计规范的三色渐变风险等级展示
/// 支持多种尺寸和样式
class RiskLevelBadge extends StatelessWidget {
  /// 风险等级
  final RiskLevel riskLevel;

  /// 标签样式
  final RiskBadgeStyle style;

  /// 标签尺寸
  final RiskBadgeSize size;

  /// 点击回调
  final VoidCallback? onTap;

  /// 是否显示工具提示
  final bool showTooltip;

  /// 自定义文本
  final String? customText;

  /// 创建风险等级标签
  const RiskLevelBadge({
    super.key,
    required this.riskLevel,
    this.style = RiskBadgeStyle.gradient,
    this.size = RiskBadgeSize.medium,
    this.onTap,
    this.showTooltip = true,
    this.customText,
  });

  @override
  Widget build(BuildContext context) {
    final badge = _buildBadge();

    if (showTooltip && onTap == null) {
      return Tooltip(
        message: _getTooltipText(),
        child: badge,
      );
    }

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_getBorderRadius()),
        child: badge,
      );
    }

    return badge;
  }

  Widget _buildBadge() {
    switch (style) {
      case RiskBadgeStyle.gradient:
        return _buildGradientBadge();
      case RiskBadgeStyle.outline:
        return _buildOutlineBadge();
      case RiskBadgeStyle.solid:
        return _buildSolidBadge();
      case RiskBadgeStyle.minimal:
        return _buildMinimalBadge();
    }
  }

  Widget _buildGradientBadge() {
    final riskInfo = _getRiskInfo();
    final padding = _getPadding();
    final borderRadius = _getBorderRadius();

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [riskInfo.startColor, riskInfo.endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: riskInfo.startColor.withOpacity(0.3),
            offset: const Offset(0, 2),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: _buildContent(Colors.white),
    );
  }

  Widget _buildOutlineBadge() {
    final riskInfo = _getRiskInfo();
    final padding = _getPadding();
    final borderRadius = _getBorderRadius();

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(
          color: riskInfo.startColor,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: _buildContent(riskInfo.startColor),
    );
  }

  Widget _buildSolidBadge() {
    final riskInfo = _getRiskInfo();
    final padding = _getPadding();
    final borderRadius = _getBorderRadius();

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: riskInfo.startColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: _buildContent(Colors.white),
    );
  }

  Widget _buildMinimalBadge() {
    final riskInfo = _getRiskInfo();
    final padding = _getPadding();

    return Container(
      padding: padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: riskInfo.startColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: BaseSpacing.xs),
          _buildContent(riskInfo.startColor, showIcon: false),
        ],
      ),
    );
  }

  Widget _buildContent(Color textColor, {bool showIcon = true}) {
    final riskInfo = _getRiskInfo();
    final textStyle = _getTextStyle(textColor);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon && style != RiskBadgeStyle.minimal) ...[
          Icon(
            riskInfo.icon,
            size: _getIconSize(),
            color: textColor,
          ),
          const SizedBox(width: BaseSpacing.xs),
        ],
        Flexible(
          child: Text(
            customText ?? riskInfo.label,
            style: textStyle,
          ),
        ),
      ],
    );
  }

  RiskInfo _getRiskInfo() {
    switch (riskLevel) {
      case RiskLevel.low:
        return RiskInfo(
          label: '低风险',
          shortLabel: '低',
          description: '预期收益较低，风险很小',
          startColor: RiskColors.lowRiskStart,
          endColor: RiskColors.lowRiskEnd,
          icon: Icons.shield,
        );
      case RiskLevel.medium:
        return RiskInfo(
          label: '中风险',
          shortLabel: '中',
          description: '预期收益适中，风险可控',
          startColor: RiskColors.mediumRiskStart,
          endColor: RiskColors.mediumRiskEnd,
          icon: Icons.security,
        );
      case RiskLevel.high:
        return RiskInfo(
          label: '高风险',
          shortLabel: '高',
          description: '预期收益较高，风险较大',
          startColor: RiskColors.highRiskStart,
          endColor: RiskColors.highRiskEnd,
          icon: Icons.warning,
        );
      case RiskLevel.veryHigh:
        return RiskInfo(
          label: '极高风险',
          shortLabel: '极高',
          description: '预期收益很高，风险极大',
          startColor: RiskColors.highRiskStart,
          endColor: RiskColors.highRiskEnd,
          icon: Icons.dangerous,
        );
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case RiskBadgeSize.small:
        return const EdgeInsets.symmetric(
          horizontal: BaseSpacing.xs,
          vertical: BaseSpacing.xs,
        );
      case RiskBadgeSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: BaseSpacing.sm,
          vertical: BaseSpacing.xs,
        );
      case RiskBadgeSize.large:
        return const EdgeInsets.symmetric(
          horizontal: BaseSpacing.md,
          vertical: BaseSpacing.sm,
        );
    }
  }

  double _getBorderRadius() {
    switch (size) {
      case RiskBadgeSize.small:
        return BorderRadiusTokens.sm;
      case RiskBadgeSize.medium:
        return BorderRadiusTokens.md;
      case RiskBadgeSize.large:
        return BorderRadiusTokens.lg;
    }
  }

  TextStyle _getTextStyle(Color textColor) {
    switch (size) {
      case RiskBadgeSize.small:
        return AppTextStyles.caption.copyWith(
          color: textColor,
          fontWeight: FontWeights.medium,
        );
      case RiskBadgeSize.medium:
        return AppTextStyles.label.copyWith(
          color: textColor,
          fontWeight: FontWeights.semiBold,
        );
      case RiskBadgeSize.large:
        return AppTextStyles.bodySmall.copyWith(
          color: textColor,
          fontWeight: FontWeights.semiBold,
        );
    }
  }

  double _getIconSize() {
    switch (size) {
      case RiskBadgeSize.small:
        return 12.0;
      case RiskBadgeSize.medium:
        return 16.0;
      case RiskBadgeSize.large:
        return 20.0;
    }
  }

  String _getTooltipText() {
    final riskInfo = _getRiskInfo();
    return '${riskInfo.label}：${riskInfo.description}';
  }
}

/// 风险等级枚举
enum RiskLevel {
  /// 低风险
  low,

  /// 中风险
  medium,

  /// 高风险
  high,

  /// 极高风险
  veryHigh,
}

/// 风险标签样式
enum RiskBadgeStyle {
  /// 渐变样式
  gradient,

  /// 描边样式
  outline,

  /// 实心样式
  solid,

  /// 极简样式
  minimal,
}

/// 风险标签尺寸
enum RiskBadgeSize {
  /// 小尺寸
  small,

  /// 中等尺寸
  medium,

  /// 大尺寸
  large,
}

/// 风险信息数据类
class RiskInfo {
  /// 风险标签
  final String label;

  /// 简短标签
  final String shortLabel;

  /// 风险描述
  final String description;

  /// 渐变起始颜色
  final Color startColor;

  /// 渐变结束颜色
  final Color endColor;

  /// 图标
  final IconData icon;

  /// 创建风险信息
  const RiskInfo({
    required this.label,
    required this.shortLabel,
    required this.description,
    required this.startColor,
    required this.endColor,
    required this.icon,
  });
}

/// 风险等级对比组件
///
/// 显示多个风险等级对比的组件
class RiskLevelComparison extends StatelessWidget {
  /// 当前风险等级
  final RiskLevel currentLevel;

  /// 是否显示描述
  final bool showDescription;

  /// 对齐方式
  final CrossAxisAlignment alignment;

  /// 创建风险等级对比组件
  const RiskLevelComparison({
    super.key,
    required this.currentLevel,
    this.showDescription = true,
    this.alignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          '风险等级',
          style: AppTextStyles.h6.copyWith(
            color: NeutralColors.neutral700,
          ),
        ),
        const SizedBox(height: BaseSpacing.md),
        ...RiskLevel.values.map((level) {
          return Padding(
            padding: const EdgeInsets.only(bottom: BaseSpacing.sm),
            child: Row(
              children: [
                RiskLevelBadge(
                  riskLevel: level,
                  size: RiskBadgeSize.small,
                  style: level == currentLevel
                      ? RiskBadgeStyle.gradient
                      : RiskBadgeStyle.outline,
                ),
                const SizedBox(width: BaseSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getRiskLabel(level),
                        style: AppTextStyles.body.copyWith(
                          color: level == currentLevel
                              ? NeutralColors.neutral900
                              : NeutralColors.neutral600,
                          fontWeight: level == currentLevel
                              ? FontWeights.semiBold
                              : FontWeights.regular,
                        ),
                      ),
                      if (showDescription)
                        Text(
                          _getRiskDescription(level),
                          style: AppTextStyles.caption.copyWith(
                            color: NeutralColors.neutral500,
                          ),
                        ),
                    ],
                  ),
                ),
                if (level == currentLevel)
                  Icon(
                    Icons.check_circle,
                    color: BaseColors.primary500,
                    size: 20,
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  String _getRiskLabel(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return '低风险 - 适合保守型投资者';
      case RiskLevel.medium:
        return '中风险 - 适合平衡型投资者';
      case RiskLevel.high:
        return '高风险 - 适合进取型投资者';
      case RiskLevel.veryHigh:
        return '极高风险 - 适合激进型投资者';
    }
  }

  String _getRiskDescription(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return '本金安全性高，预期收益相对稳定';
      case RiskLevel.medium:
        return '本金相对安全，预期收益有一定波动';
      case RiskLevel.high:
        return '本金存在一定风险，预期收益波动较大';
      case RiskLevel.veryHigh:
        return '本金风险较高，预期收益波动很大';
    }
  }
}
