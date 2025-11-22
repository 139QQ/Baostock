import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/user.dart';
import '../../../../core/navigation/navigation_manager.dart';
import '../../../../core/navigation/responsive_navigation_adapter.dart';
import '../../../../core/di/di_initializer.dart';
import '../../../home/presentation/pages/dashboard_page.dart';
import '../../../fund/presentation/fund_exploration/presentation/pages/fund_exploration_page.dart';
import '../../../fund/presentation/fund_exploration/presentation/pages/minimalist_fund_exploration_page.dart';
import '../../../fund/presentation/pages/watchlist_page.dart';
import '../../../portfolio/presentation/widgets/portfolio_manager.dart';
import '../../../portfolio/presentation/cubit/portfolio_analysis_cubit.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../home/presentation/widgets/global_navigation_bar.dart';

/// 响应式导航外壳组件
///
/// 根据屏幕尺寸和平台自动调整导航布局
/// 支持桌面端、Web端和移动端的不同导航模式
class ResponsiveNavigationShell extends StatefulWidget {
  /// 当前登录用户
  final User user;

  /// 登出回调函数
  final VoidCallback onLogout;

  const ResponsiveNavigationShell({
    super.key,
    required this.user,
    required this.onLogout,
  });

  @override
  State<ResponsiveNavigationShell> createState() =>
      _ResponsiveNavigationShellState();
}

class _ResponsiveNavigationShellState extends State<ResponsiveNavigationShell> {
  late final NavigationManager _navigationManager;
  late NavigationConfig _config;

  @override
  void initState() {
    super.initState();
    _navigationManager = sl<NavigationManager>();
    _navigationManager.addListener(_onNavigationChanged);

    // 初始化导航配置
    _config = ResponsiveNavigationAdapter.getNavigationConfig(context);
  }

  @override
  void dispose() {
    _navigationManager.removeListener(_onNavigationChanged);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 当依赖变化时（如屏幕尺寸变化），更新导航配置
    _config = ResponsiveNavigationAdapter.getNavigationConfig(context);
  }

  /// 导航状态变化回调
  void _onNavigationChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  /// 导航到指定页面
  void navigateToPage(int index) {
    _navigationManager.navigateToPage(index);
  }

  /// 获取当前选中索引
  int get _selectedIndex => _navigationManager.currentIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _config.showAppBar ? _buildAppBar() : null,
      body: _buildBody(),
      bottomNavigationBar:
          _config.showBottomBar ? _buildBottomNavigationBar() : null,
      drawer: ResponsiveNavigationAdapter.shouldUseDrawer(_config)
          ? _buildDrawer()
          : null,
    );
  }

  /// 构建应用栏
  PreferredSizeWidget _buildAppBar() {
    if (_config.type == NavigationType.mobile) {
      // 移动端使用简化的应用栏
      return AppBar(
        title: const Text('基速基金'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 1,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
          PopupMenuButton<String>(
            onSelected: _handleUserMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined),
                    SizedBox(width: 8),
                    Text('设置'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('退出', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      // 桌面端使用全局导航栏
      return GlobalNavigationBar(
        user: widget.user,
        onLogout: widget.onLogout,
        showLayoutToggle: _config.useMinimalistLayout && _selectedIndex == 1,
        onToggleLayout: () {
          setState(() {
            // 极简布局切换逻辑可以在这里实现
          });
        },
        isMinimalistLayout: _config.useMinimalistLayout,
        onNavigate: navigateToPage,
        selectedIndex: _selectedIndex,
      );
    }
  }

  /// 构建主体内容
  Widget _buildBody() {
    if (ResponsiveNavigationAdapter.shouldUseDrawer(_config)) {
      // 移动端或抽屉模式
      return _buildCurrentPage();
    } else {
      // 桌面端布局
      return Row(
        children: [
          if (_config.railWidth > 0)
            SizedBox(
              width: _config.railWidth,
              child: _buildNavigationRail(),
            ),
          Expanded(
            child: Container(
              padding: ResponsiveNavigationAdapter.getContentPadding(_config),
              child: _buildCurrentPage(),
            ),
          ),
        ],
      );
    }
  }

  /// 构建导航栏
  Widget _buildNavigationRail() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: NavigationRail(
        selectedIndex: _selectedIndex,
        onDestinationSelected: navigateToPage,
        labelType: ResponsiveNavigationAdapter.getRailLabelType(_config),
        backgroundColor: Colors.transparent,
        elevation: 0,
        extended: _config.railExtended,
        minWidth: _config.railWidth,
        groupAlignment: -0.85,
        destinations: [
          _buildDestination(
              Icons.dashboard_outlined, Icons.dashboard, '概览', '市场概览'),
          _buildDestination(
              Icons.filter_alt_outlined, Icons.filter_alt, '筛选', '基金筛选'),
          _buildDestination(Icons.star_outline, Icons.star, '自选', '自选基金',
              isHighlighted: true),
          _buildDestination(
              Icons.analytics_outlined, Icons.analytics, '分析', '持仓分析',
              isHighlighted: true),
          _buildDestination(
              Icons.settings_outlined, Icons.settings, '设置', '系统设置'),
        ],
      ),
    );
  }

  /// 构建导航目标
  NavigationRailDestination _buildDestination(
    IconData icon,
    IconData selectedIcon,
    String label,
    String tooltip, {
    bool isHighlighted = false,
  }) {
    return NavigationRailDestination(
      icon: Tooltip(message: tooltip, child: Icon(icon, size: 16)),
      selectedIcon:
          Tooltip(message: tooltip, child: Icon(selectedIcon, size: 18)),
      label: Text(
        label,
        style: TextStyle(
          fontSize: _config.type == NavigationType.mobile ? 12 : 8,
          fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// 构建底部导航栏（移动端）
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: navigateToPage,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: '概览',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.filter_alt_outlined),
          activeIcon: Icon(Icons.filter_alt),
          label: '筛选',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.star_outline),
          activeIcon: Icon(Icons.star),
          label: '自选',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics_outlined),
          activeIcon: Icon(Icons.analytics),
          label: '分析',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          activeIcon: Icon(Icons.settings),
          label: '设置',
        ),
      ],
    );
  }

  /// 构建抽屉菜单（移动端）
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(widget.user.displayText),
            accountEmail: const Text('已登录'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: widget.user.avatarUrl != null
                  ? ClipOval(
                      child: Image.network(
                        widget.user.avatarUrl!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.person, color: Colors.white),
                      ),
                    )
                  : const Icon(Icons.person, color: Colors.white, size: 30),
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('市场概览'),
            selected: _selectedIndex == 0,
            onTap: () {
              Navigator.pop(context);
              navigateToPage(0);
            },
          ),
          ListTile(
            leading: const Icon(Icons.filter_alt_outlined),
            title: const Text('基金筛选'),
            selected: _selectedIndex == 1,
            onTap: () {
              Navigator.pop(context);
              navigateToPage(1);
            },
          ),
          ListTile(
            leading: const Icon(Icons.star_outline),
            title: const Text('自选基金'),
            selected: _selectedIndex == 2,
            onTap: () {
              Navigator.pop(context);
              navigateToPage(2);
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics_outlined),
            title: const Text('持仓分析'),
            selected: _selectedIndex == 3,
            onTap: () {
              Navigator.pop(context);
              navigateToPage(3);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('系统设置'),
            selected: _selectedIndex == 4,
            onTap: () {
              Navigator.pop(context);
              navigateToPage(4);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('退出登录', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showLogoutDialog();
            },
          ),
        ],
      ),
    );
  }

  /// 构建当前页面
  Widget _buildCurrentPage() {
    final maxWidth = ResponsiveNavigationAdapter.getMaxContentWidth(_config);
    final pageContent = _getPageContent();

    if (maxWidth != null) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: pageContent,
        ),
      );
    }

    return pageContent;
  }

  /// 获取页面内容
  Widget _getPageContent() {
    switch (_selectedIndex) {
      case 0:
        return const DashboardPage();
      case 1:
        if (_config.useMinimalistLayout) {
          return const MinimalistFundExplorationPage();
        } else {
          return const FundExplorationPage();
        }
      case 2:
        return const WatchlistPage();
      case 3:
        return BlocProvider<PortfolioAnalysisCubit>.value(
          value: sl<PortfolioAnalysisCubit>(),
          child: const PortfolioManager(),
        );
      case 4:
        return const SettingsPage();
      default:
        return const DashboardPage();
    }
  }

  /// 显示搜索对话框
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('搜索基金'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: '输入基金代码或名称...',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (query) {
            Navigator.pop(context);
            if (query.trim().isNotEmpty) {
              _navigationManager.navigateWithSearch(query.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  /// 处理用户菜单操作
  void _handleUserMenuAction(String action) {
    switch (action) {
      case 'settings':
        navigateToPage(4);
        break;
      case 'logout':
        _showLogoutDialog();
        break;
    }
  }

  /// 显示退出确认对话框
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('您确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }
}
