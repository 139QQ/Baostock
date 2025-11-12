import 'package:flutter/material.dart';

import '../widgets/notification_test_widget.dart';

/// 行情预警页面
///
/// 提供价格提醒设置和管理功能：
/// - 价格预警设置
/// - 涨跌幅度提醒
/// - 成交量预警
/// - 预警历史记录
/// - 通知测试功能
class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('推送通知'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.notifications_outlined),
              text: '通知测试',
            ),
            Tab(
              icon: Icon(Icons.price_change_outlined),
              text: '行情预警',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          // 通知测试页面
          NotificationTestWidget(),
          // 行情预警页面
          _PriceAlertsTab(),
        ],
      ),
    );
  }
}

/// 价格预警标签页
class _PriceAlertsTab extends StatelessWidget {
  const _PriceAlertsTab();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 功能说明卡片
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        '行情预警功能',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    '即将推出以下功能：',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 8),
                  _FeatureItem(
                    icon: Icons.trending_up,
                    title: '价格预警',
                    description: '设置基金价格上限和下限提醒',
                  ),
                  _FeatureItem(
                    icon: Icons.percent,
                    title: '涨跌幅度提醒',
                    description: '当涨跌幅超过设定值时通知',
                  ),
                  _FeatureItem(
                    icon: Icons.bar_chart,
                    title: '成交量预警',
                    description: '异常成交量变化提醒',
                  ),
                  _FeatureItem(
                    icon: Icons.history,
                    title: '预警历史',
                    description: '查看历史预警记录',
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          // 占位提示
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.construction,
                    size: 64,
                    color: Color(0xFFBDBDBD), // Colors.grey[400]
                  ),
                  SizedBox(height: 16),
                  Text(
                    '行情预警功能开发中...',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF757575), // Colors.grey[600]
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '敬请期待后续版本更新',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9E9E9E), // Colors.grey[500]
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 功能项组件
class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF757575), // Colors.grey[600]
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
