import 'package:flutter/material.dart';
import '../../../alerts/presentation/widgets/notification_test_widget.dart';

/// 简化版市场概览页面
///
/// 临时简化版本，避免复杂依赖导致的问题
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
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;
    final orientation = MediaQuery.of(context).orientation;

    // 响应式配置
    final headerPadding = isMobile
        ? const EdgeInsets.all(16.0)
        : (isTablet ? const EdgeInsets.all(20.0) : const EdgeInsets.all(24.0));

    final contentPadding = isMobile
        ? const EdgeInsets.all(12.0)
        : (isTablet ? const EdgeInsets.all(16.0) : const EdgeInsets.all(20.0));

    final crossAxisCount = isMobile
        ? (orientation == Orientation.portrait ? 2 : 3)
        : (isTablet ? 3 : 4);

    final childAspectRatio = isMobile ? 1.1 : (isTablet ? 1.2 : 1.3);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 响应式顶部欢迎区域
            Container(
              width: double.infinity,
              padding: headerPadding,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.1),
                    Theme.of(context).primaryColor.withOpacity(0.05),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '欢迎回来',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 20 : 24,
                        ),
                  ),
                  SizedBox(height: isMobile ? 6 : 8),
                  Text(
                    '基速基金分析器',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).textTheme.titleLarge?.color,
                          fontSize: isMobile ? 18 : 22,
                        ),
                  ),
                  SizedBox(height: isMobile ? 12 : 16),
                  Text(
                    '专业的基金量化分析平台',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                          fontSize: isMobile ? 14 : 16,
                        ),
                  ),
                ],
              ),
            ),

            // 响应式功能卡片区域
            Padding(
              padding: contentPadding,
              child: Column(
                children: [
                  // 响应式功能卡片网格
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: isMobile ? 12 : 16,
                        mainAxisSpacing: isMobile ? 12 : 16,
                        childAspectRatio: childAspectRatio,
                        children: [
                          _buildFeatureCard(
                            context,
                            Icons.trending_up,
                            '基金排行',
                            '查看基金排行榜',
                            Colors.blue,
                          ),
                          _buildFeatureCard(
                            context,
                            Icons.star_border,
                            '自选基金',
                            '管理我的自选基金',
                            Colors.orange,
                          ),
                          _buildFeatureCard(
                            context,
                            Icons.pie_chart,
                            '投资组合',
                            '分析投资组合表现',
                            Colors.green,
                          ),
                          _buildFeatureCard(
                            context,
                            Icons.notifications_active,
                            '推送测试',
                            '测试推送通知功能',
                            Colors.purple,
                          ),
                          _buildFeatureCard(
                            context,
                            Icons.settings,
                            '系统设置',
                            '个性化应用设置',
                            Colors.grey,
                          ),
                        ],
                      );
                    },
                  ),

                  SizedBox(height: isMobile ? 16 : 24),

                  // 市场概览卡片
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.show_chart,
                                color: Theme.of(context).primaryColor,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '市场概览',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildMarketMetric(
                                  context,
                                  '上证指数',
                                  '3,245.67',
                                  '+1.23%',
                                  Colors.green,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildMarketMetric(
                                  context,
                                  '深证成指',
                                  '10,234.56',
                                  '-0.45%',
                                  Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 底部提示信息
                  Card(
                    elevation: 2,
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '数据每5分钟自动更新，点击顶部导航栏切换不同功能页面',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isSmallScreen = screenWidth < 400;

    // 响应式配置
    final iconSize = isSmallScreen ? 36 : (isMobile ? 42 : 48);
    final cardPadding =
        EdgeInsets.all(isSmallScreen ? 12 : (isMobile ? 14 : 16));
    final titleFontSize = isSmallScreen ? 14 : (isMobile ? 16 : 18);
    final subtitleFontSize = isSmallScreen ? 11 : 12;
    final spacing = SizedBox(height: isSmallScreen ? 8 : 12);
    final smallSpacing = SizedBox(height: isSmallScreen ? 3 : 4);

    return Card(
      elevation: isMobile ? 2 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
      ),
      child: InkWell(
        onTap: () {
          if (title == '推送测试') {
            // 导航到通知测试页面
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const NotificationTestWidget(),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$title 功能开发中')),
            );
          }
        },
        borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
        child: Padding(
          padding: cardPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: iconSize.toDouble(),
                color: color,
              ),
              spacing,
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: titleFontSize.toDouble(),
                    ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              smallSpacing,
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontSize: subtitleFontSize.toDouble(),
                    ),
                textAlign: TextAlign.center,
                maxLines: isSmallScreen ? 1 : 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarketMetric(
    BuildContext context,
    String name,
    String value,
    String change,
    Color changeColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                change.startsWith('+')
                    ? Icons.trending_up
                    : Icons.trending_down,
                size: 16,
                color: changeColor,
              ),
              const SizedBox(width: 4),
              Text(
                change,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: changeColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
