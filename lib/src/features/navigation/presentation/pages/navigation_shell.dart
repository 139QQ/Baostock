import 'package:flutter/material.dart';

import '../../../auth/domain/entities/user.dart';
import '../../../home/presentation/pages/dashboard_page.dart';
import '../../../fund/presentation/fund_exploration/presentation/pages/fund_exploration_page.dart';
import '../../../fund/presentation/pages/watchlist_page.dart';
import '../../../portfolio/presentation/pages/portfolio_analysis_page.dart';
import '../../../alerts/presentation/pages/alerts_page.dart';
import '../../../data_center/presentation/pages/data_center_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../home/presentation/widgets/global_navigation_bar.dart';

/// 增强版导航外壳组件
///
/// 集成全局导航栏和左侧导航栏，提供完整的导航体验
/// 支持响应式布局和悬停效果
class NavigationShell extends StatefulWidget {
  /// 当前登录用户
  final User user;

  /// 登出回调函数
  final VoidCallback onLogout;

  const NavigationShell({
    super.key,
    required this.user,
    required this.onLogout,
  });

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const FundExplorationPage(), // 移除占位符，直接使用实际页面
    const WatchlistPage(),
    PortfolioAnalysisPage(), // 持仓分析
    const AlertsPage(), // 行情预警
    const DataCenterPage(), // 数据中心
    const SettingsPage(), // 系统设置
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GlobalNavigationBar(
        user: widget.user,
        onLogout: widget.onLogout,
      ),
      body: Row(
        children: [
          _buildEnhancedNavigationRail(),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _buildCurrentPage(),
          ),
        ],
      ),
    );
  }

  /// 构建当前页面
  Widget _buildCurrentPage() {
    return _pages[_selectedIndex];
  }

  Widget _buildEnhancedNavigationRail() {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() => _selectedIndex = index);
      },
      labelType: NavigationRailLabelType.all,
      backgroundColor: const Color(0xFFF8FAFC),
      elevation: null,
      extended: false,
      leading: const SizedBox(height: 16),
      trailing: const SizedBox(height: 16),
      destinations: [
        _buildDestination(
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          label: '市场概览',
          tooltip: '查看市场实时数据',
        ),
        _buildDestination(
          icon: Icons.filter_alt_outlined,
          selectedIcon: Icons.filter_alt,
          label: '基金筛选',
          tooltip: '智能筛选基金',
        ),
        _buildDestination(
          icon: Icons.star_outline,
          selectedIcon: Icons.star,
          label: '自选基金',
          tooltip: '管理关注基金',
        ),
        _buildDestination(
          icon: Icons.analytics_outlined,
          selectedIcon: Icons.analytics,
          label: '持仓分析',
          tooltip: '分析投资组合',
        ),
        _buildDestination(
          icon: Icons.notifications_outlined,
          selectedIcon: Icons.notifications,
          label: '行情预警',
          tooltip: '设置价格提醒',
        ),
        _buildDestination(
          icon: Icons.data_usage_outlined,
          selectedIcon: Icons.data_usage,
          label: '数据中心',
          tooltip: '查看深度数据',
        ),
        _buildDestination(
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings,
          label: '系统设置',
          tooltip: '配置应用参数',
        ),
      ],
    );
  }

  NavigationRailDestination _buildDestination({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required String tooltip,
  }) {
    return NavigationRailDestination(
      icon: Tooltip(
        message: tooltip,
        child: Icon(icon, size: 22),
      ),
      selectedIcon: Tooltip(
        message: tooltip,
        child: Icon(selectedIcon, size: 22),
      ),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
