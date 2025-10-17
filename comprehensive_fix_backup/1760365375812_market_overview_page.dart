import 'package:flutter/material.dart';

import '../widgets/market_today_overview.dart';
import '../widgets/hot_sectors_widget.dart';
import '../widgets/enhanced_market_real.dart';

/// 市场行情总览页面
/// 整合今日行情、热门板块和核心指数展示
class MarketOverviewPage extends StatelessWidget {
  const MarketOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 核心指数区域
            const EnhancedMarketReal(),
            const SizedBox(height: 24),

            // 今日行情和热门板块区域（横向网格布局）
            LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 800;

                if (isSmallScreen) {
                  // 小屏幕：垂直布局
                  return const Column(
                    children: [
                      MarketTodayOverview(),
                      SizedBox(height: 24),
                      HotSectorsWidget(
                        title: '热门板块',
                        maxItems: 10,
                        showHeader: true,
                      ),
                    ],
                  );
                } else {
                  // 大屏幕：横向网格布局
                  return const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: MarketTodayOverview(),
                      ),
                      SizedBox(width: 24),
                      Expanded(
                        flex: 2,
                        child: HotSectorsWidget(
                          title: '热门板块',
                          maxItems: 10,
                          showHeader: true,
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
