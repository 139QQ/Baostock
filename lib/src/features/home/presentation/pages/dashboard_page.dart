import 'package:flutter/material.dart';
import '../../../alerts/presentation/widgets/notification_test_widget.dart';
import '../../../../core/theme/widgets/modern_brand_logo.dart';
import '../../../../core/theme/widgets/modern_ui_components.dart';
import '../../../../core/theme/widgets/gradient_container.dart';
import '../../../../core/theme/design_tokens/app_colors.dart';

/// 现代化Dashboard页面
///
/// 采用现代FinTech设计风格的市场概览页面
class DashboardPage extends StatefulWidget {
  /// 创建市场概览页面
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;
    final orientation = MediaQuery.of(context).orientation;

    // 响应式配置
    final headerPadding = isMobile
        ? const EdgeInsets.all(20.0)
        : (isTablet ? const EdgeInsets.all(24.0) : const EdgeInsets.all(32.0));

    final contentPadding = isMobile
        ? const EdgeInsets.all(16.0)
        : (isTablet ? const EdgeInsets.all(20.0) : const EdgeInsets.all(24.0));

    final crossAxisCount = isMobile
        ? (orientation == Orientation.portrait ? 2 : 3)
        : (isTablet ? 3 : 4);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 现代化顶部欢迎区域
            GradientContainer.primary(
              padding: headerPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GradientText(
                              '欢迎回来',
                              style: TextStyle(
                                fontSize: isMobile ? 24 : 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '基速基金量化分析平台',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white70,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '现代金融科技 · 智能分析 · 实时监控',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white60,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      ModernBrandLogo(
                        size: 48,
                        showText: false,
                        animated: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 现代化数据展示区域
            Padding(
              padding: contentPadding,
              child: Column(
                children: [
                  // 市场数据展示
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.2,
                        children: [
                          ModernMarketDataDisplay(
                            indexName: '上证指数',
                            currentValue: '3,245.67',
                            changeValue: '+40.12',
                            changePercent: '+1.23%',
                          ),
                          ModernMarketDataDisplay(
                            indexName: '深证成指',
                            currentValue: '10,234.56',
                            changeValue: '-46.23',
                            changePercent: '-0.45%',
                          ),
                          ModernMarketDataDisplay(
                            indexName: '创业板指',
                            currentValue: '2,156.89',
                            changeValue: '+28.47',
                            changePercent: '+1.34%',
                          ),
                          ModernMarketDataDisplay(
                            indexName: '沪深300',
                            currentValue: '4,567.23',
                            changeValue: '+15.67',
                            changePercent: '+0.34%',
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // 现代化数据卡片网格
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: isMobile ? 2 : 3,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.1,
                        children: [
                          ModernDataCard(
                            title: '总资产',
                            value: '¥1,234,567.89',
                            changeValue: '+2.34%',
                            icon: Icons.account_balance_wallet,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('资产详情功能开发中')),
                              );
                            },
                          ),
                          ModernDataCard(
                            title: '今日收益',
                            value: '+¥5,678.23',
                            changeValue: '+4.67%',
                            icon: Icons.trending_up,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('收益详情功能开发中')),
                              );
                            },
                          ),
                          ModernDataCard(
                            title: '基金数量',
                            value: '156',
                            changeValue: '+3',
                            icon: Icons.pie_chart,
                            onTap: () {
                              Navigator.of(context)
                                  .pushNamed('/fund-exploration');
                            },
                          ),
                          ModernDataCard(
                            title: '监控指标',
                            value: '12',
                            changeValue: '正常',
                            icon: Icons.analytics,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('监控详情功能开发中')),
                              );
                            },
                          ),
                          ModernDataCard(
                            title: '推送通知',
                            value: '8',
                            changeValue: '待处理',
                            icon: Icons.notifications,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const NotificationTestWidget(),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // 现代化按钮区域
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.psychology, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          ModernButton(
                            text: '智能分析',
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('智能分析功能即将上线')),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lightbulb, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          ModernButton(
                            text: '投资建议',
                            gradient: FinancialGradients.successGradient,
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('投资建议功能即将上线')),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
