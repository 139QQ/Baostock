// ignore_for_file: directives_ordering, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../../core/navigation/navigation_manager.dart';
import '../../../../core/di/di_initializer.dart';
import '../../../alerts/presentation/pages/alerts_page.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../fund/presentation/fund_exploration/presentation/pages/fund_exploration_page.dart';
import '../../../fund/presentation/fund_exploration/presentation/pages/minimalist_fund_exploration_page.dart';
import '../../../fund/presentation/pages/watchlist_page.dart';
import '../../../home/presentation/pages/dashboard_page.dart';
import '../../../home/presentation/widgets/config/navigation_config.dart';
import '../../../home/presentation/widgets/global_navigation_bar.dart';
import '../../../market/presentation/pages/market_index_page.dart';
import '../../../portfolio/presentation/cubit/portfolio_analysis_cubit.dart';
import '../../../portfolio/presentation/widgets/portfolio_manager.dart';
import '../../../settings/presentation/pages/settings_page.dart';

/// 导航外壳组件
///
/// 仅提供顶部导航栏，不包含左侧导航栏
/// 支持极简布局切换和响应式布局
class NavigationShell extends StatefulWidget {
  /// 当前登录用户
  final User user;

  /// 登出回调函数
  final VoidCallback onLogout;

  @override
  State<NavigationShell> createState() => _NavigationShellState();

  /// 创建导航外壳组件
  const NavigationShell({
    super.key,
    required this.user,
    required this.onLogout,
  });
}

class _NavigationShellState extends State<NavigationShell> {
  late final NavigationManager _navigationManager;
  bool _useMinimalistLayout = true; // 默认使用极简布局
  late final NavigationConfig _navigationConfig;

  @override
  void initState() {
    super.initState();
    _navigationManager = sl<NavigationManager>();
    _navigationConfig = NavigationConfig.instance;
    // 监听导航状态变化
    _navigationManager.addListener(_onNavigationChanged);
  }

  @override
  void dispose() {
    _navigationManager.removeListener(_onNavigationChanged);
    super.dispose();
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

  /// 导航到持仓分析页面
  void navigateToPortfolio() {
    navigateToPage(3); // 持仓分析是索引3
  }

  /// 获取当前选中索引
  int get _selectedIndex => _navigationManager.currentIndex;

  @override
  Widget build(BuildContext context) {
    // 检查是否应该使用移动端导航
    final shouldUseMobileNav = _shouldUseMobileNavigation(context);

    debugPrint(
        '🏗️ NavigationShell: 平台检测 - isWeb: $kIsWeb, shouldUseMobileNav: $shouldUseMobileNav');

    if (shouldUseMobileNav) {
      // 移动端使用底部导航栏
      return Scaffold(
        appBar: _buildMobileAppBar(context),
        body: _buildCurrentPage(),
        bottomNavigationBar: _buildMobileBottomNavigation(),
        floatingActionButton: _buildFloatingActionButton(),
      );
    } else {
      // 桌面端使用顶部导航栏
      return Scaffold(
        appBar: GlobalNavigationBar(
          user: widget.user,
          onLogout: widget.onLogout,
          showLayoutToggle: _selectedIndex == 1, // 只在基金探索页面显示切换按钮
          onToggleLayout: () {
            setState(() {
              _useMinimalistLayout = !_useMinimalistLayout;
            });
          },
          isMinimalistLayout: _useMinimalistLayout,
          onNavigate: navigateToPage,
          selectedIndex: _selectedIndex,
        ),
        body: _buildCurrentPage(),
      );
    }
  }

  /// 判断是否应该使用移动端导航
  bool _shouldUseMobileNavigation(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final orientation = MediaQuery.of(context).orientation;

    debugPrint(
        '🏗️ NavigationShell: 屏幕分析 - 宽度: ${screenWidth}px, 高度: ${screenHeight}px, 方向: ${orientation.name}');

    // 1. 检查平台 - 非Web平台优先使用移动端导航
    if (!kIsWeb) {
      // 响应式优化：根据屏幕尺寸调整导航模式
      if (screenWidth >= 1200) {
        debugPrint('🏗️ NavigationShell: 检测到大屏幕非Web设备，使用桌面端导航');
        return false;
      } else {
        debugPrint('🏗️ NavigationShell: 检测到中小屏幕非Web设备，使用移动端导航');
        return true;
      }
    }

    // 2. 检查导航配置
    if (_navigationConfig.shouldUseMobileNavigation(context)) {
      debugPrint('🏗️ NavigationShell: 导航配置指定使用移动端导航');
      return true;
    }

    // 3. 增强的响应式断点检测
    if (orientation == Orientation.portrait) {
      // 竖屏模式
      if (screenWidth < 768) {
        debugPrint(
            '🏗️ NavigationShell: 竖屏模式，屏幕宽度${screenWidth}px < 768px，使用移动端导航');
        return true;
      } else if (screenWidth < 1024) {
        debugPrint('🏗️ NavigationShell: 竖屏模式，中等屏幕${screenWidth}px，使用混合导航');
        return screenHeight < 800; // 高度较低时使用移动端导航
      } else {
        debugPrint('🏗️ NavigationShell: 竖屏模式，大屏幕${screenWidth}px，使用桌面端导航');
        return false;
      }
    } else {
      // 横屏模式
      if (screenWidth < 900) {
        debugPrint(
            '🏗️ NavigationShell: 横屏模式，屏幕宽度${screenWidth}px < 900px，使用移动端导航');
        return true;
      } else if (screenWidth < 1400) {
        debugPrint('🏗️ NavigationShell: 横屏模式，中等屏幕${screenWidth}px，使用混合导航');
        return screenHeight < 600; // 高度较低时使用移动端导航
      } else {
        debugPrint('🏗️ NavigationShell: 横屏模式，大屏幕${screenWidth}px，使用桌面端导航');
        return false;
      }
    }
  }

  /// 构建移动端AppBar（简化版）
  PreferredSizeWidget? _buildMobileAppBar(BuildContext context) {
    // 只在需要显示标题和用户信息时才显示AppBar
    if (_selectedIndex == 0 || _selectedIndex == 6) {
      return AppBar(
        title: _getMobilePageTitle(),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 1,
        centerTitle: true,
        actions: [
          if (_selectedIndex == 6) // 设置页面
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _showMobileLogoutDialog(context),
            ),
        ],
      );
    }
    return null; // 其他页面不显示AppBar，给更多空间显示内容
  }

  /// 获取移动端页面标题
  Text _getMobilePageTitle() {
    switch (_selectedIndex) {
      case 0:
        return const Text('基速基金',
            style: TextStyle(fontWeight: FontWeight.bold));
      case 1:
        return const Text('市场指数',
            style: TextStyle(fontWeight: FontWeight.bold));
      case 2:
        return const Text('基金筛选',
            style: TextStyle(fontWeight: FontWeight.bold));
      case 3:
        return const Text('自选基金',
            style: TextStyle(fontWeight: FontWeight.bold));
      case 4:
        return const Text('持仓分析',
            style: TextStyle(fontWeight: FontWeight.bold));
      case 5:
        return const Text('推送通知',
            style: TextStyle(fontWeight: FontWeight.bold));
      case 6:
        return const Text('系统设置',
            style: TextStyle(fontWeight: FontWeight.bold));
      default:
        return const Text('基速基金',
            style: TextStyle(fontWeight: FontWeight.bold));
    }
  }

  /// 构建移动端底部导航栏
  Widget _buildMobileBottomNavigation() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final isMediumScreen = screenWidth < 600;

    // 响应式调整图标和文字大小
    final iconSize = isSmallScreen ? 20.0 : (isMediumScreen ? 22.0 : 24.0);
    final fontSize = isSmallScreen ? 10.0 : 11.0;

    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: navigateToPage,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor:
          Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      selectedFontSize: fontSize,
      unselectedFontSize: fontSize,
      selectedLabelStyle:
          TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: fontSize),
      iconSize: iconSize,
      items: _buildBottomNavItems(screenWidth),
      elevation: 8,
    );
  }

  /// 根据屏幕宽度构建底部导航项
  List<BottomNavigationBarItem> _buildBottomNavItems(double screenWidth) {
    final isSmallScreen = screenWidth < 400;

    // 小屏幕时可以隐藏部分标签，只显示图标
    final showLabels = !isSmallScreen;

    return [
      BottomNavigationBarItem(
        icon: const Icon(Icons.home_outlined),
        activeIcon: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.home),
        ),
        label: showLabels ? '首页' : '',
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.trending_up_outlined),
        activeIcon: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.trending_up),
        ),
        label: showLabels ? '市场' : '',
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.search_outlined),
        activeIcon: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.search),
        ),
        label: showLabels ? '基金' : '',
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.star_outline),
        activeIcon: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.star),
        ),
        label: showLabels ? '自选' : '',
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.settings_outlined),
        activeIcon: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.settings),
        ),
        label: showLabels ? '设置' : '',
      ),
    ];
  }

  /// 构建浮动操作按钮（用于快速访问持仓分析等功能）
  Widget? _buildFloatingActionButton() {
    // 在自选基金页面显示持仓分析按钮
    if (_selectedIndex == 3) {
      return FloatingActionButton(
        onPressed: navigateToPortfolio,
        tooltip: '持仓分析',
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.analytics, color: Colors.white),
      );
    }
    return null;
  }

  /// 显示移动端登出对话框
  void _showMobileLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('您确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
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

  /// 构建当前页面（修复黑屏问题）
  Widget _buildCurrentPage() {
    debugPrint('🏗️ NavigationShell: 构建页面索引 $_selectedIndex');

    try {
      switch (_selectedIndex) {
        case 0: // Dashboard
          debugPrint('🏗️ NavigationShell: 显示DashboardPage');
          return const DashboardPage();
        case 1: // Market Index (Story 2.3)
          debugPrint('🏗️ NavigationShell: 显示MarketIndexPage');
          return const MarketIndexPage();
        case 2: // Fund Exploration
          debugPrint('🏗️ NavigationShell: 显示FundExplorationPage');
          return _useMinimalistLayout
              ? const MinimalistFundExplorationPage()
              : const FundExplorationPage();
        case 3: // Watchlist
          debugPrint('🏗️ NavigationShell: 显示WatchlistPage');
          return const WatchlistPage();
        case 4: // Portfolio Management
          debugPrint('🏗️ NavigationShell: 显示PortfolioManager');
          return BlocProvider<PortfolioAnalysisCubit>.value(
            value: sl<PortfolioAnalysisCubit>(),
            child: const PortfolioManager(),
          );
        case 5: // Push Notifications (Alerts)
          debugPrint('🏗️ NavigationShell: 显示AlertsPage');
          return const AlertsPage();
        case 6: // Settings
          debugPrint('🏗️ NavigationShell: 显示SettingsPage');
          return const SettingsPage();
        default:
          debugPrint('🏗️ NavigationShell: 默认显示DashboardPage');
          return const DashboardPage();
      }
    } catch (e, stackTrace) {
      debugPrint('❌ NavigationShell: 页面构建失败: $e');
      debugPrint('❌ NavigationShell: 堆栈跟踪: $stackTrace');

      // 如果页面构建失败，显示一个简单的错误页面
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                '页面加载中...',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '页面索引: $_selectedIndex',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  debugPrint('🔄 用户点击了重试按钮');
                  setState(() {});
                },
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }
  }
}
