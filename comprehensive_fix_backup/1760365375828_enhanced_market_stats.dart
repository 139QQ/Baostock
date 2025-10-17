import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/constants/app_design_constants.dart';

/// 增强版市场行情统计组件
///
/// 将传统的数字展示升级为可视化的柱状图+动态数字
/// - 使用百分比柱状图直观展示涨跌比例
/// - 添加动画效果增强数据变化感知
/// - 集成涨停跌停数据
class EnhancedMarketStats extends StatefulWidget {
  const EnhancedMarketStats({super.key});

  @override
  State<EnhancedMarketStats> createState() => _EnhancedMarketStatsState();
}

class _EnhancedMarketStatsState extends State<EnhancedMarketStats>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _upAnimation;
  late Animation<double> _downAnimation;
  late Animation<double> _limitUpAnimation;

  // 模拟数据
  final int upStocks = 2156;
  final int downStocks = 1843;
  final int limitUpStocks = 45;
  final int limitDownStocks = 12;
  final int totalStocks = 5000;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _upAnimation = Tween<double>(begin: 0, end: upStocks / totalStocks)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _downAnimation = Tween<double>(begin: 0, end: downStocks / totalStocks)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _limitUpAnimation = Tween<double>(
            begin: 0, end: limitUpStocks / totalStocks)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final upPercent = (upStocks / totalStocks * 100).toStringAsFixed(1);
    final downPercent = (downStocks / totalStocks * 100).toStringAsFixed(1);
    final limitUpPercent =
        (limitUpStocks / totalStocks * 100).toStringAsFixed(2);

    return Container(
      padding: EdgeInsets.all(AppDesignConstants.cardPaddingLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDesignConstants.radiusLarge),
        border: Border.all(
          color: AppDesignConstants.borderColor,
          width: AppDesignConstants.borderWidth,
        ),
        boxShadow: AppDesignConstants.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '今日行情',
            style: TextStyle(
              fontSize: AppDesignConstants.fontSizeLarge,
              fontWeight: AppDesignConstants.fontWeightBold,
              color: AppDesignConstants.colorTextPrimary,
            ),
          ),
          SizedBox(height: AppDesignConstants.spacingXXL),

          // 涨跌统计卡片
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  label: '上涨',
                  count: upStocks,
                  percentage: upPercent,
                  color: AppDesignConstants.colorUp,
                  animation: _upAnimation,
                  icon: Icons.trending_up,
                ),
              ),
              SizedBox(width: AppDesignConstants.spacingLG),
              Expanded(
                child: _buildStatCard(
                  label: '下跌',
                  count: downStocks,
                  percentage: downPercent,
                  color: AppDesignConstants.colorDown,
                  animation: _downAnimation,
                  icon: Icons.trending_down,
                ),
              ),
              SizedBox(width: AppDesignConstants.spacingLG),
              Expanded(
                child: _buildStatCard(
                  label: '涨停',
                  count: limitUpStocks,
                  percentage: limitUpPercent,
                  color: Color(0xFFFF9800), // 涨停保持橙色特殊处理
                  animation: _limitUpAnimation,
                  icon: Icons.arrow_upward,
                ),
              ),
            ],
          ),

          SizedBox(height: AppDesignConstants.spacingXXL),

          // 百分比柱状图
          Text(
            '涨跌分布',
            style: TextStyle(
              fontSize: AppDesignConstants.fontSizeMedium,
              fontWeight: AppDesignConstants.fontWeightSemibold,
              color: AppDesignConstants.colorTextSecondary,
            ),
          ),
          SizedBox(height: AppDesignConstants.spacingMD),

          _buildPercentageBar(),

          SizedBox(height: AppDesignConstants.spacingMD),

          // 涨跌比例文字说明
          _buildStatsSummary(),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required int count,
    required String percentage,
    required Color color,
    required Animation<double> animation,
    required IconData icon,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppDesignConstants.radiusLarge),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: color),
                  SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppDesignConstants.colorTextPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: AppDesignConstants.fontSizeDataLarge,
                  fontWeight: AppDesignConstants.fontWeightBold,
                  color: AppDesignConstants.colorTextPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: AppDesignConstants.fontSizeMedium,
                  fontWeight: AppDesignConstants.fontWeightSemibold,
                  color: color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPercentageBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppDesignConstants.colorBackground,
        borderRadius: BorderRadius.circular(AppDesignConstants.radiusXLarge),
      ),
      child: Row(
        children: [
          // 上涨部分
          Expanded(
            flex: upStocks,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppDesignConstants.colorUp,
                    AppDesignConstants.colorUp
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(AppDesignConstants.radiusXLarge),
                ),
              ),
              child: Center(
                child: Text(
                  '${(upStocks / totalStocks * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: AppDesignConstants.fontSizeHelper,
                    fontWeight: AppDesignConstants.fontWeightBold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          // 下跌部分
          Expanded(
            flex: downStocks,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppDesignConstants.colorDown,
                    AppDesignConstants.colorDown
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.horizontal(
                  right: Radius.circular(AppDesignConstants.radiusXLarge),
                ),
              ),
              child: Center(
                child: Text(
                  '${(downStocks / totalStocks * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: AppDesignConstants.fontSizeHelper,
                    fontWeight: AppDesignConstants.fontWeightBold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSummary() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '总股票数: $totalStocks',
          style: const TextStyle(
            fontSize: AppDesignConstants.fontSizeMedium,
            color: AppDesignConstants.colorTextSecondary,
          ),
        ),
        Text(
          '平盘: ${totalStocks - upStocks - downStocks}',
          style: const TextStyle(
            fontSize: AppDesignConstants.fontSizeMedium,
            color: AppDesignConstants.colorTextSecondary,
          ),
        ),
      ],
    );
  }
}
