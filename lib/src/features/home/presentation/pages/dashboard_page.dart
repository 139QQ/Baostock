import 'package:flutter/material.dart';

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 主内容区域
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // 市场指数区域
                  _buildMarketIndexSection(),
                  const SizedBox(height: 24),

                  // 今日行情组件（完整功能）
                  _buildTodayMarketOverview(),
                  const SizedBox(height: 24),

                  // 响应式布局：热门板块 + 今日关注基金
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // 根据屏幕宽度决定布局方式
                      if (constraints.maxWidth < 768) {
                        // 移动端：垂直堆叠
                        return Column(
                          children: [
                            _buildHotSectorsWidget(),
                            const SizedBox(height: 24),
                            _buildFeaturedFunds(),
                          ],
                        );
                      } else {
                        // 平板和桌面端：水平并排
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 左侧：热门板块组件
                            Expanded(
                              flex: 2,
                              child: _buildHotSectorsWidget(),
                            ),
                            const SizedBox(width: 24),

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

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 市场指数区域
  Widget _buildMarketIndexSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '市场指数',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildIndexCard('上证指数', '3,087.53', '+0.82%', true),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildIndexCard('深证成指', '9,876.32', '-0.45%', false),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildIndexCard('创业板指', '1,923.45', '+1.23%', true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIndexCard(
      String name, String value, String change, bool isPositive) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPositive
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            change,
            style: TextStyle(
              fontSize: 12,
              color: isPositive ? Colors.green : Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 今日行情概览
  Widget _buildTodayMarketOverview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '今日行情',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMarketStat('上涨家数', '2,156', Colors.green),
              const SizedBox(width: 16),
              _buildMarketStat('下跌家数', '1,823', Colors.red),
              const SizedBox(width: 16),
              _buildMarketStat('平盘家数', '234', Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMarketStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 热门板块组件
  Widget _buildHotSectorsWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '热门板块',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSectorChip('新能源', '+3.45%', true),
              _buildSectorChip('半导体', '+2.78%', true),
              _buildSectorChip('医药', '-1.23%', false),
              _buildSectorChip('消费', '+0.89%', true),
              _buildSectorChip('金融', '-0.56%', false),
              _buildSectorChip('地产', '+1.67%', true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectorChip(String name, String change, bool isPositive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPositive
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            change,
            style: TextStyle(
              fontSize: 10,
              color: isPositive ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 今日关注基金区域
  Widget _buildFeaturedFunds() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                '今日关注',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.star,
                size: 16,
                color: Color(0xFFFFB400),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 基金列表
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 6,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive
              ? [
                  const Color(0xFFE8F5E8),
                  const Color(0xFFF0F9F0),
                ]
              : [
                  const Color(0xFFFFEBEE),
                  const Color(0xFFFFF3F3),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPositive
              ? Colors.green.withOpacity(0.2)
              : Colors.red.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fund['name']!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            fund['code']!,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Text(
                fund['value']!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isPositive
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  fund['change']!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isPositive ? Colors.green : Colors.red,
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
