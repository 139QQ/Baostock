import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/user.dart';
import '../../../home/presentation/pages/dashboard_page.dart';
import '../../../fund/presentation/fund_exploration/presentation/pages/fund_exploration_page.dart';
import '../../../fund/presentation/pages/watchlist_page.dart';
import '../../../portfolio/presentation/widgets/portfolio_manager.dart';
import '../../../portfolio/presentation/cubit/portfolio_analysis_cubit.dart';
import '../../../alerts/presentation/pages/alerts_page.dart';
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
            width: 100, // 匹配NavigationRail的minWidth
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
      case 3: // Portfolio Management - 使用全局已提供的PortfolioAnalysisCubit和FundFavoriteCubit
        return BlocProvider<PortfolioAnalysisCubit>.value(
          value: sl<PortfolioAnalysisCubit>(),
          child: const PortfolioManager(),
        );
      case 4: // Settings
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
      minWidth: 100,
      leading: null,
      trailing: null,
      groupAlignment: -0.85,
      destinations: [
        _buildDestination(
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          label: '概览',
          tooltip: '市场概览',
        ),
        _buildDestination(
          icon: Icons.filter_alt_outlined,
          selectedIcon: Icons.filter_alt,
          label: '筛选',
          tooltip: '基金筛选',
        ),
        _buildDestination(
          icon: Icons.star_outline,
          selectedIcon: Icons.star,
          label: '自选',
          tooltip: '自选基金',
          isHighlighted: true,
        ),
        _buildDestination(
          icon: Icons.analytics_outlined,
          selectedIcon: Icons.analytics,
          label: '分析',
          tooltip: '持仓分析',
          isHighlighted: true,
        ),
        _buildDestination(
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings,
          label: '设置',
          tooltip: '系统设置',
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
}
