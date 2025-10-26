import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/user.dart';
import '../../../home/presentation/pages/dashboard_page.dart';
import '../../../fund/presentation/fund_exploration/presentation/pages/fund_exploration_page.dart';
import '../../../fund/presentation/pages/watchlist_page.dart';
import '../../../portfolio/presentation/pages/portfolio_analysis_page.dart';
import '../../../alerts/presentation/pages/alerts_page.dart';
import '../../../data_center/presentation/pages/data_center_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../home/presentation/widgets/global_navigation_bar.dart';
import '../../../../core/di/injection_container.dart';

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

  /// 导航到指定页面
  void navigateToPage(int index) {
    const int pageCount =
        7; // Dashboard, Fund Exploration, Watchlist, Portfolio Analysis, Alerts, Data Center, Settings
    if (mounted && index >= 0 && index < pageCount) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  /// 导航到持仓分析页面
  void navigateToPortfolio() {
    navigateToPage(3); // 持仓分析是索引3
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GlobalNavigationBar(
        user: widget.user,
        onLogout: widget.onLogout,
      ),
      body: Row(
        children: [
          SizedBox(
            width: 90, // 匹配NavigationRail的minWidth
            child: _buildEnhancedNavigationRail(),
          ),
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
    switch (_selectedIndex) {
      case 0: // Dashboard
        return const DashboardPage();
      case 1: // Fund Exploration
        return const FundExplorationPage();
      case 2: // Watchlist
        return const WatchlistPage();
      case 3: // Portfolio Analysis - 使用全局已提供的PortfolioAnalysisCubit和FundFavoriteCubit
        return const PortfolioAnalysisPage();
      case 4: // Alerts
        return const AlertsPage();
      case 5: // Data Center
        return const Scaffold(
          body: Center(
            child: Text('数据中心 - 开发中'),
          ),
        );
      case 6: // Settings
        return const SettingsPage();
      default:
        return const DashboardPage();
    }
  }

  Widget _buildEnhancedNavigationRail() {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() => _selectedIndex = index);
      },
      labelType: NavigationRailLabelType.all,
      backgroundColor: const Color(0xFFF8FAFC),
      elevation: 1,
      extended: false,
      minWidth: 90, // 增加最小宽度
      // 移除leading以节省空间，或者使用更紧凑的leading
      leading: null,
      trailing: null, // 移除trailing组件以节省空间，防止溢出
      groupAlignment: -0.85, // 调整垂直对齐
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
          label: '🌟 自选基金',
          tooltip: '管理关注基金',
          isHighlighted: true, // 标记为高亮路由
        ),
        _buildDestination(
          icon: Icons.analytics_outlined,
          selectedIcon: Icons.analytics,
          label: '📊 持仓分析',
          tooltip: '分析投资组合',
          isHighlighted: true, // 标记为高亮路由
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
    bool isHighlighted = false,
  }) {
    final fontWeight = isHighlighted ? FontWeight.bold : FontWeight.w400;
    // 进一步减小字体大小以防止溢出
    final fontSize = isHighlighted ? 8.5 : 7.5;

    return NavigationRailDestination(
      icon: Tooltip(
        message: tooltip,
        child: Icon(
          icon,
          size: isHighlighted ? 16 : 14, // 减小图标尺寸
          color: isHighlighted ? Theme.of(context).primaryColor : null,
        ),
      ),
      selectedIcon: Tooltip(
        message: tooltip,
        child: Icon(
          selectedIcon,
          size: isHighlighted ? 18 : 16, // 减小选中图标尺寸
        ),
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// 获取当前页面的图标
  IconData _getCurrentPageIcon() {
    switch (_selectedIndex) {
      case 0:
        return Icons.dashboard;
      case 1:
        return Icons.filter_alt;
      case 2:
        return Icons.star; // 🌟 自选基金
      case 3:
        return Icons.analytics; // 📊 持仓分析
      case 4:
        return Icons.notifications;
      case 5:
        return Icons.data_usage;
      case 6:
        return Icons.settings;
      default:
        return Icons.dashboard;
    }
  }

  /// 获取当前页面的名称
  String _getCurrentPageName() {
    switch (_selectedIndex) {
      case 0:
        return '市场概览';
      case 1:
        return '基金筛选';
      case 2:
        return '🌟自选基金';
      case 3:
        return '📊持仓分析';
      case 4:
        return '行情预警';
      case 5:
        return '数据中心';
      case 6:
        return '系统设置';
      default:
        return '未知';
    }
  }
}
