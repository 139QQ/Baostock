import 'package:flutter/material.dart';

import '../widgets/enhanced_market_real.dart';
import '../widgets/today_market_overview.dart';
import '../widgets/hot_sectors_widget.dart';
import '../../../../core/constants/app_design_constants.dart';

/// 优化版市场概览页面
///
/// 集成所有增强功能的完整首页，包括：
/// - 全局导航栏
/// - 增强市场指数展示
/// - 可视化行情统计
/// - 热门板块展示
/// - 响应式布局
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignConstants.colorBackground,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 主内容区域
            Padding(
              padding: const EdgeInsets.all(AppDesignConstants.spacingXXL),
              child: Column(
                children: [
                  // 市场指数区域
                  EnhancedMarketReal(),
                  SizedBox(height: AppDesignConstants.spacingXXL),

                  // 新布局：今日行情组件（完整功能）
                  TodayMarketOverview(),

                  SizedBox(height: AppDesignConstants.spacingXXL),

                  // 响应式布局：热门板块 + 今日关注基金
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // 根据屏幕宽度决定布局方式
                      if (constraints.maxWidth <
                          AppDesignConstants.breakpointTablet) {
                        // 移动端：垂直堆叠
                        return Column(
                          children: [
                            const HotSectorsWidget(
                              title: '热门板块',
                              maxItems: 6,
                              showHeader: true,
                            ),
                            const SizedBox(
                                height: AppDesignConstants.spacingXXL),
                            _buildFeaturedFunds(),
                          ],
                        );
                      } else {
                        // 平板和桌面端：水平并排
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 左侧：热门板块组件
                            const Expanded(
                              flex: 2,
                              child: HotSectorsWidget(
                                title: '热门板块',
                                maxItems: 8,
                                showHeader: true,
                              ),
                            ),
                            const SizedBox(
                                width: AppDesignConstants.spacingXXL),

                            // 右侧：今日关注基金
                            Expanded(
                              flex: 3,
                              child: _buildFeaturedFunds(),
                            ),
                          ],
                        );
                      }
                    },
                  ),

                  SizedBox(height: AppDesignConstants.spacingXXXL),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 今日关注基金区域
  Widget _buildFeaturedFunds() {
    return Container(
      padding: EdgeInsets.all(AppDesignConstants.cardPaddingLarge),
      decoration: BoxDecoration(
        color: AppDesignConstants.colorCardBackground,
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
          Row(
            children: [
              Text(
                '今日关注',
                style: TextStyle(
                  fontSize: AppDesignConstants.fontSizeLarge,
                  fontWeight: AppDesignConstants.fontWeightSemibold,
                  color: AppDesignConstants.colorTextPrimary,
                ),
              ),
              SizedBox(width: AppDesignConstants.spacingSM),
              Icon(
                Icons.star,
                size: 16,
                color: Color(0xFFFFB400),
              ),
            ],
          ),
          SizedBox(height: AppDesignConstants.spacingLG),

          // 基金列表
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 6,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: AppDesignConstants.spacingLG),
              itemBuilder: (context, index) => _buildFundCard(index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFundCard(int index) {
    final funds = [
      {
        'name': '华夏成长混合',
        'code': '000001',
        'change': '+1.25%',
        'value': '1.234'
      },
      {
        'name': '易方达蓝筹精选',
        'code': '005827',
        'change': '+2.34%',
        'value': '2.156'
      },
      {
        'name': '富国天惠成长',
        'code': '161005',
        'change': '-0.85%',
        'value': '3.421'
      },
      {
        'name': '景顺长城新兴成长',
        'code': '260108',
        'change': '+1.78%',
        'value': '2.890'
      },
      {
        'name': '汇添富价值精选',
        'code': '519069',
        'change': '+0.56%',
        'value': '4.123'
      },
      {
        'name': '博时主题行业',
        'code': '160505',
        'change': '-1.12%',
        'value': '1.876'
      },
    ];

    final fund = funds[index];
    final isPositive = fund['change']!.startsWith('+');

    return Container(
      width: 160,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive
              ? [
                  Color(0xFFE8F5E8),
                  Color(0xFFF0F9F0),
                ]
              : [
                  Color(0xFFFFEBEE),
                  Color(0xFFFFF3F3),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDesignConstants.radiusLarge),
        border: Border.all(
          color: isPositive
              ? AppDesignConstants.colorDown.withOpacity(0.2)
              : AppDesignConstants.colorUp.withOpacity(0.2),
          width: AppDesignConstants.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fund['name']!,
            style: TextStyle(
              fontSize: AppDesignConstants.fontSizeMedium,
              fontWeight: AppDesignConstants.fontWeightSemibold,
              color: AppDesignConstants.colorTextPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: AppDesignConstants.spacingXS),
          Text(
            fund['code']!,
            style: TextStyle(
              fontSize: AppDesignConstants.fontSizeSmall,
              color: AppDesignConstants.colorTextSecondary,
            ),
          ),
          Spacer(),
          Row(
            children: [
              Text(
                fund['value']!,
                style: TextStyle(
                  fontSize: AppDesignConstants.fontSizeData,
                  fontWeight: AppDesignConstants.fontWeightBold,
                  color: AppDesignConstants.colorTextPrimary,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isPositive
                      ? AppDesignConstants.colorDown.withOpacity(0.1)
                      : AppDesignConstants.colorUp.withOpacity(0.1),
                  borderRadius:
                      BorderRadius.circular(AppDesignConstants.radiusSmall),
                ),
                child: Text(
                  fund['change']!,
                  style: TextStyle(
                    fontSize: AppDesignConstants.fontSizeSmall,
                    fontWeight: AppDesignConstants.fontWeightSemibold,
                    color: isPositive
                        ? AppDesignConstants.colorDown
                        : AppDesignConstants.colorUp,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
