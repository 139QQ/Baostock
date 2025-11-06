import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/user.dart';
import '../../../home/presentation/pages/dashboard_page.dart';
import '../../../fund/presentation/fund_exploration/presentation/pages/fund_exploration_page.dart';
import '../../../fund/presentation/fund_exploration/presentation/pages/minimalist_fund_exploration_page.dart';
import '../../../fund/presentation/pages/watchlist_page.dart';
import '../../../portfolio/presentation/widgets/portfolio_manager.dart';
import '../../../portfolio/presentation/cubit/portfolio_analysis_cubit.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../home/presentation/widgets/global_navigation_bar.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/navigation/navigation_manager.dart';

/// 导航外壳组件
///
/// 仅提供顶部导航栏，不包含左侧导航栏
/// 支持极简布局切换和响应式布局
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
  late final NavigationManager _navigationManager;
  bool _useMinimalistLayout = true; // 默认使用极简布局

  @override
  void initState() {
    super.initState();
    _navigationManager = sl<NavigationManager>();
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
    // 只保留顶部导航栏，移除左侧导航栏
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

  /// 构建当前页面（修复黑屏问题）
  Widget _buildCurrentPage() {
    debugPrint('🏗️ NavigationShell: 构建页面索引 $_selectedIndex');

    try {
      switch (_selectedIndex) {
        case 0: // Dashboard
          debugPrint('🏗️ NavigationShell: 显示DashboardPage');
          return const DashboardPage();
        case 1: // Fund Exploration
          debugPrint('🏗️ NavigationShell: 显示FundExplorationPage');
          return _useMinimalistLayout
              ? const MinimalistFundExplorationPage()
              : const FundExplorationPage();
        case 2: // Watchlist
          debugPrint('🏗️ NavigationShell: 显示WatchlistPage');
          return const WatchlistPage();
        case 3: // Portfolio Management
          debugPrint('🏗️ NavigationShell: 显示PortfolioManager');
          return BlocProvider<PortfolioAnalysisCubit>.value(
            value: sl<PortfolioAnalysisCubit>(),
            child: const PortfolioManager(),
          );
        case 4: // Settings
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
