import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/widgets/modern_ui_components.dart';
import '../../../../core/theme/design_tokens/app_colors.dart';
import '../../../../core/theme/widgets/gradient_container.dart';
import 'notification_test_widget.dart';

/// 现代化推送通知页面
///
/// 提供价格提醒设置和管理功能，包含：
/// - 现代化通知测试界面
/// - 智能行情预警设置
/// - 实时通知状态监控
/// - 个性化通知偏好
/// - 响应式交互设计
class ModernAlertsPage extends StatefulWidget {
  const ModernAlertsPage({super.key});

  @override
  State<ModernAlertsPage> createState() => _ModernAlertsPageState();
}

class _ModernAlertsPageState extends State<ModernAlertsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // 通知状态
  bool _notificationsEnabled = true;
  bool _priceAlertsEnabled = true;
  bool _volumeAlertsEnabled = false;
  bool _newsAlertsEnabled = true;
  int _activeAlertsCount = 12;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initAnimations();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF233997).withOpacity(0.95),
              const Color(0xFF5E7CFF).withOpacity(0.85),
              Colors.grey[50]!,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildModernAppBar(),
              _buildNotificationStatusCard(),
              _buildTabBar(),
              Expanded(child: _buildTabBarView()),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建现代化AppBar
  Widget _buildModernAppBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withOpacity(0.1),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const GradientText(
                      '推送通知',
                      gradient: LinearGradient(
                        colors: [Colors.white, Color(0xFFE8F4FF)],
                      ),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '实时市场行情提醒，不错过任何投资机会',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white.withOpacity(0.15),
                ),
                child: Stack(
                  children: [
                    const Icon(
                      Icons.notifications_active_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    if (_activeAlertsCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.red,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              _activeAlertsCount > 99
                                  ? '99+'
                                  : '$_activeAlertsCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建通知状态卡片
  Widget _buildNotificationStatusCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.95),
            Colors.white.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '通知设置',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    _notificationsEnabled
                        ? Icons.notifications_active
                        : Icons.notifications_off,
                    key: ValueKey(_notificationsEnabled),
                    color: _notificationsEnabled
                        ? FinancialColors.positive
                        : Colors.grey,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildNotificationToggle(
                    '价格预警',
                    _priceAlertsEnabled,
                    (value) => setState(() => _priceAlertsEnabled = value),
                    Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildNotificationToggle(
                    '成交量提醒',
                    _volumeAlertsEnabled,
                    (value) => setState(() => _volumeAlertsEnabled = value),
                    Icons.bar_chart,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildNotificationToggle(
                    '新闻推送',
                    _newsAlertsEnabled,
                    (value) => setState(() => _newsAlertsEnabled = value),
                    Icons.article,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0);
  }

  /// 构建通知开关
  Widget _buildNotificationToggle(
      String title, bool value, ValueChanged<bool> onChanged, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: value
            ? FinancialColors.positive.withOpacity(0.1)
            : Colors.grey[100],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: value ? FinancialColors.positive : Colors.grey[600],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: value ? FinancialColors.positive : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40,
            height: 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: value ? FinancialColors.positive : Colors.grey[300],
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建TabBar
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.1),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: FinancialGradients.primaryGradient,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.7),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 13,
        ),
        tabs: const [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.notifications_outlined, size: 18),
                SizedBox(width: 6),
                Text('通知测试'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.price_change_outlined, size: 18),
                SizedBox(width: 6),
                Text('行情预警'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history, size: 18),
                SizedBox(width: 6),
                Text('历史记录'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建TabBarView
  Widget _buildTabBarView() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.95),
      ),
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationTestTab(),
          _buildPriceAlertsTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  /// 通知测试Tab
  Widget _buildNotificationTestTab() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: const NotificationTestWidget(),
          ),
        );
      },
    );
  }

  /// 行情预警Tab
  Widget _buildPriceAlertsTab() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuickAlertCard(),
                  const SizedBox(height: 20),
                  _buildActiveAlertsList(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 历史记录Tab
  Widget _buildHistoryTab() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildNotificationHistory(),
            ),
          ),
        );
      },
    );
  }

  /// 构建快速预警卡片
  Widget _buildQuickAlertCard() {
    return GradientContainer(
      gradient: LinearGradient(
        colors: [
          FinancialGradients.successGradient.colors.first.withOpacity(0.1),
          FinancialGradients.successGradient.colors.last.withOpacity(0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: FinancialGradients.successGradient,
                ),
                child: const Icon(
                  Icons.flash_on,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '快速预警',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      '设置基金价格预警，自动提醒涨跌变化',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ModernButton(
                  text: '添加预警',
                  gradient: FinancialGradients.successGradient,
                  onPressed: () => _showAddAlertDialog(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ModernButton(
                  text: '批量管理',
                  gradient: FinancialGradients.techGradient,
                  onPressed: () => _showBatchManageDialog(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建活跃预警列表
  Widget _buildActiveAlertsList() {
    final alerts = _getMockActiveAlerts();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '活跃预警',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            Text(
              '${alerts.length} 个预警',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...alerts.map((alert) => _buildAlertItem(alert)).toList(),
      ],
    );
  }

  /// 构建预警项目
  Widget _buildAlertItem(Map<String, dynamic> alert) {
    final isTriggered = alert['isTriggered'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isTriggered
              ? FinancialColors.negative.withOpacity(0.3)
              : Colors.grey[200]!,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: isTriggered
                    ? FinancialColors.negative
                    : FinancialColors.positive,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert['fundName'] as String,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '当前: ${alert['currentPrice']} ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        alert['targetPrice'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isTriggered
                              ? FinancialColors.negative
                              : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isTriggered
                    ? FinancialColors.negative.withOpacity(0.1)
                    : Colors.grey[100],
              ),
              child: Text(
                isTriggered ? '已触发' : '监控中',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color:
                      isTriggered ? FinancialColors.negative : Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建通知历史
  Widget _buildNotificationHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '通知历史',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: 10,
            itemBuilder: (context, index) {
              return _buildHistoryItem(index);
            },
          ),
        ),
      ],
    );
  }

  /// 构建历史项目
  Widget _buildHistoryItem(int index) {
    final histories = _getMockHistories();
    final history = histories[index % histories.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  history['title'] as String,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  history['time'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              history['content'] as String,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 模拟活跃预警数据
  List<Map<String, dynamic>> _getMockActiveAlerts() {
    return [
      {
        'fundName': '易方达消费行业',
        'fundCode': '110022',
        'currentPrice': '2.85',
        'targetPrice': '3.00',
        'isTriggered': false,
      },
      {
        'fundName': '招商中证白酒',
        'fundCode': '161725',
        'currentPrice': '1.52',
        'targetPrice': '1.50',
        'isTriggered': true,
      },
      {
        'fundName': '易方达蓝筹精选',
        'fundCode': '005827',
        'currentPrice': '4.25',
        'targetPrice': '4.50',
        'isTriggered': false,
      },
    ];
  }

  /// 模拟历史数据
  List<Map<String, dynamic>> _getMockHistories() {
    return [
      {
        'title': '价格预警触发',
        'content': '易方达消费行业上涨至目标价3.00，涨幅5.26%',
        'time': '10:30',
      },
      {
        'title': '成交量提醒',
        'content': '沪深300成交量突破5亿，市场活跃度提升',
        'time': '14:20',
      },
      {
        'title': '新闻推送',
        'content': '央行发布降准消息，金融板块普遍上涨',
        'time': '09:15',
      },
    ];
  }

  /// 显示添加预警对话框
  void _showAddAlertDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加价格预警'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: '基金代码',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: '目标价格',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _activeAlertsCount++);
              Navigator.pop(context);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  /// 显示批量管理对话框
  void _showBatchManageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('批量管理'),
        content: const Text('批量管理所有预警功能'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}
