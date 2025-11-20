import 'package:flutter/material.dart';
import '../design_tokens/app_colors.dart';

/// 现代化按钮组件
class ModernButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Gradient? gradient;
  final Color? color;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final TextStyle? textStyle;

  const ModernButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.gradient,
    this.color,
    this.width,
    this.height,
    this.borderRadius,
    this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height ?? 48,
      decoration: BoxDecoration(
        gradient: gradient ?? FinancialGradients.buttonGradient,
        color: color,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: BaseColors.primary600.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          child: Center(
            child: Text(
              text,
              style: textStyle ??
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 现代化数据卡片组件 - 简化版
class ModernDataCard extends StatelessWidget {
  final String title;
  final String value;
  final String? changeValue;
  final IconData? icon;
  final VoidCallback? onTap;

  const ModernDataCard({
    Key? key,
    required this.title,
    required this.value,
    this.changeValue,
    this.icon,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: FinancialGradients.primaryGradient,
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        color: NeutralColors.neutral600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: NeutralColors.neutral900,
                ),
              ),
              if (changeValue != null) ...[
                const SizedBox(height: 8),
                Text(
                  changeValue!,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: changeValue!.startsWith('+')
                        ? FinancialColors.positive
                        : changeValue!.startsWith('-')
                            ? FinancialColors.negative
                            : FinancialColors.neutral,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 现代化市场数据展示组件
class ModernMarketDataDisplay extends StatelessWidget {
  final String indexName;
  final String currentValue;
  final String changeValue;
  final String changePercent;

  const ModernMarketDataDisplay({
    Key? key,
    required this.indexName,
    required this.currentValue,
    required this.changeValue,
    required this.changePercent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isPositive = !changePercent.startsWith('-');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            BaseColors.primary50,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: BaseColors.primary200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: BaseColors.primary600.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            indexName,
            style: TextStyle(
              fontSize: 12,
              color: NeutralColors.neutral600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            currentValue,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: NeutralColors.neutral900,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                size: 16,
                color: isPositive
                    ? FinancialColors.positive
                    : FinancialColors.negative,
              ),
              const SizedBox(width: 4),
              Text(
                '$changeValue ($changePercent)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isPositive
                      ? FinancialColors.positive
                      : FinancialColors.negative,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
