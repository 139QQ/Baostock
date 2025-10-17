import 'package:flutter/material.dart';

/// 基金筛选芯片组件
///
/// 用于显示单个筛选条件选项，支持选中/未选中状态切换。
/// 支持多种显示样式和交互方式。
class FundFilterChip extends StatelessWidget {
  /// 芯片标签
  final String label;

  /// 是否选中
  final bool selected;

  /// 选中状态回调
  final ValueChanged<bool>? onSelected;

  /// 选中时的背景色
  final Color? selectedColor;

  /// 未选中时的背景色
  final Color? backgroundColor;

  /// 标签文本样式
  final TextStyle? labelStyle;

  /// 选中时的标签文本样式
  final TextStyle? selectedLabelStyle;

  /// 边框样式
  final BoxBorder? side;

  /// 选中时的边框样式
  final BoxBorder? selectedSide;

  /// 圆角半径
  final BorderRadius? borderRadius;

  /// 内边距
  final EdgeInsetsGeometry? padding;

  /// 芯片高度
  final double? height;

  /// 是否显示删除图标
  final bool showDeleteIcon;

  /// 删除图标回调
  final VoidCallback? onDelete;

  /// 是否禁用
  final bool disabled;

  /// 前缀图标
  final Widget? prefixIcon;

  /// 后缀图标
  final Widget? suffixIcon;

  /// 自定义选中状态指示器
  final Widget? selectedIndicator;

  /// 芯片样式
  final FilterChipStyle style;

  const FundFilterChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onSelected,
    this.selectedColor,
    this.backgroundColor,
    this.labelStyle,
    this.selectedLabelStyle,
    this.side,
    this.selectedSide,
    this.borderRadius,
    this.padding,
    this.height,
    this.showDeleteIcon = false,
    this.onDelete,
    this.disabled = false,
    this.prefixIcon,
    this.suffixIcon,
    this.selectedIndicator,
    this.style = FilterChipStyle.standard,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // 根据样式确定默认值
    final defaultSelectedColor = style == FilterChipStyle.outline
        ? colors.primary.withOpacity(0.1)
        : colors.primary;

    final defaultBackgroundColor = style == FilterChipStyle.outline
        ? Colors.transparent
        : colors.surfaceVariant.withOpacity(0.5);

    final defaultSide = style == FilterChipStyle.outline
        ? Border.all(color: colors.outline.withOpacity(0.5))
        : null;

    final defaultSelectedSide = style == FilterChipStyle.outline
        ? Border.all(color: colors.primary, width: 1.5)
        : null;

    final chip = InkWell(
      onTap: disabled
          ? null
          : () {
              onSelected?.call(!selected);
            },
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: height ?? 36,
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? (selectedColor ?? defaultSelectedColor)
              : (backgroundColor ?? defaultBackgroundColor),
          borderRadius: borderRadius ?? BorderRadius.circular(8),
          border: selected
              ? (selectedSide ?? defaultSelectedSide)
              : (side ?? defaultSide),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (prefixIcon != null) ...[
              prefixIcon!,
              const SizedBox(width: 6),
            ],

            // 选中的指示器
            if (selectedIndicator != null && selected) ...[
              selectedIndicator!,
              const SizedBox(width: 6),
            ] else if (selected && style == FilterChipStyle.standard) ...[
              Icon(
                Icons.check_circle,
                size: 14,
                color: colors.primary,
              ),
              const SizedBox(width: 6),
            ],

            // 标签文本
            Text(
              label,
              style: (selected ? selectedLabelStyle : labelStyle) ??
                  TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    color: selected ? colors.primary : colors.onSurface,
                  ),
            ),

            if (suffixIcon != null) ...[
              const SizedBox(width: 6),
              suffixIcon!,
            ],

            // 删除图标
            if (showDeleteIcon && selected) ...[
              const SizedBox(width: 6),
              InkWell(
                onTap: disabled ? null : onDelete,
                borderRadius: BorderRadius.circular(12),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: colors.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (disabled) {
      return Opacity(
        opacity: 0.5,
        child: chip,
      );
    }

    return chip;
  }

  /// 创建基金类型的筛选芯片
  factory FundFilterChip.fundType({
    required String fundType,
    bool selected = false,
    ValueChanged<bool>? onSelected,
    Color? color,
  }) {
    return FundFilterChip(
      label: fundType,
      selected: selected,
      onSelected: onSelected,
      selectedColor: color?.withOpacity(0.2),
      selectedSide: Border.all(color: color ?? Colors.blue, width: 1),
      style: FilterChipStyle.outline,
    );
  }

  /// 创建风险等级的筛选芯片
  factory FundFilterChip.riskLevel({
    required String level,
    required String name,
    bool selected = false,
    ValueChanged<bool>? onSelected,
    Color? color,
  }) {
    return FundFilterChip(
      label: '$level $name',
      selected: selected,
      onSelected: onSelected,
      selectedColor: color?.withOpacity(0.2),
      selectedSide: Border.all(color: color ?? Colors.orange, width: 1),
      style: FilterChipStyle.outline,
      labelStyle: const TextStyle(fontSize: 12),
    );
  }

  /// 创建管理公司的筛选芯片
  factory FundFilterChip.company({
    required String companyName,
    bool selected = false,
    ValueChanged<bool>? onSelected,
  }) {
    return FundFilterChip(
      label: companyName,
      selected: selected,
      onSelected: onSelected,
      style: FilterChipStyle.standard,
      labelStyle: const TextStyle(fontSize: 12),
    );
  }

  /// 创建已选筛选条件的标签芯片
  factory FundFilterChip.selectedTag({
    required String label,
    required VoidCallback onDelete,
    Color? color,
  }) {
    return FundFilterChip(
      label: label,
      selected: true,
      showDeleteIcon: true,
      onDelete: onDelete,
      selectedColor: color?.withOpacity(0.2),
      selectedSide: Border.all(color: color ?? Colors.grey),
      style: FilterChipStyle.outline,
      labelStyle: TextStyle(
        fontSize: 12,
        color: color?.withOpacity(0.8) ?? Colors.grey.shade700,
      ),
    );
  }
}

/// 筛选芯片样式枚举
enum FilterChipStyle {
  /// 标准样式（填充背景）
  standard,

  /// 轮廓样式（透明背景，有边框）
  outline,

  /// 自定义样式
  custom,
}

/// 预设的颜色主题
class FundFilterChipColors {
  /// 股票型基金颜色
  static const stockType = Color(0xFF3B82F6);

  /// 债券型基金颜色
  static const bondType = Color(0xFF10B981);

  /// 混合型基金颜色
  static const hybridType = Color(0xFFF59E0B);

  /// 货币型基金颜色
  static const moneyType = Color(0xFF8B5CF6);

  /// 指数型基金颜色
  static const indexType = Color(0xFF06B6D4);

  /// QDII基金颜色
  static const qdiiType = Color(0xFFEC4899);

  /// FOF基金颜色
  static const fofType = Color(0xFF84CC16);

  /// 风险等级颜色
  static const riskLevel1 = Color(0xFF10B981); // 低风险
  static const riskLevel2 = Color(0xFF84CC16); // 中低风险
  static const riskLevel3 = Color(0xFFF59E0B); // 中等风险
  static const riskLevel4 = Color(0xFFF97316); // 中高风险
  static const riskLevel5 = Color(0xFFEF4444); // 高风险
}
