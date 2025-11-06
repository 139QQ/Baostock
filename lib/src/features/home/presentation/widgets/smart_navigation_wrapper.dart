import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../../auth/domain/entities/user.dart';
import '../../../navigation/presentation/pages/navigation_shell.dart';
import 'config/navigation_config.dart';
// import '../../fund/presentation/fund_exploration/presentation/cubit/fund_exploration_cubit.dart';
// import '../../portfolio/presentation/cubit/portfolio_analysis_cubit.dart';
// import '../../portfolio/presentation/cubit/fund_favorite_cubit.dart';
// import '../../portfolio/presentation/widgets/portfolio_manager.dart';
// import '../../fund/presentation/fund_exploration/presentation/pages/fund_exploration_page.dart';
// import '../../fund/presentation/pages/watchlist_page.dart';
// import '../../alerts/presentation/pages/alerts_page.dart';
// import '../../settings/presentation/pages/settings_page.dart';
// import '../../home/presentation/pages/dashboard_page.dart';

/// 智能导航包装器
///
/// 作为应用和智能导航选择器之间的桥梁，管理页面状态和导航逻辑
/// 支持多平台导航和传统导航的无缝切换
class SmartNavigationWrapper extends StatefulWidget {
  /// 当前登录用户
  final User user;

  /// 登出回调函数
  final VoidCallback onLogout;

  /// 是否启用增强调试模式
  final bool enableEnhancedDebug;

  const SmartNavigationWrapper({
    super.key,
    required this.user,
    required this.onLogout,
    this.enableEnhancedDebug = true,
  });

  @override
  State<SmartNavigationWrapper> createState() => _SmartNavigationWrapperState();
}

class _SmartNavigationWrapperState extends State<SmartNavigationWrapper>
    with TickerProviderStateMixin {
  late AnimationController _pageTransitionController;
  late Animation<double> _pageTransitionAnimation;

  int _currentPageIndex = 0;
  bool _isLayoutMinimalist = false;

  // 页面控制器，用于管理页面状态
  // final Map<int, GlobalKey> _pageKeys = {}; // 暂时注释，待页面集成后启用
  // Map<int, Widget> _pages = {}; // 暂时注释，待页面集成后启用

  @override
  void initState() {
    super.initState();

    // 初始化页面切换动画
    _pageTransitionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pageTransitionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pageTransitionController,
      curve: Curves.easeInOut,
    ));

    // 初始化页面映射
    _initializePages();

    // 播放初始动画
    _pageTransitionController.forward();

    debugPrint('🧭 SmartNavigationWrapper: 初始化完成');
    debugPrint('🧭 SmartNavigationWrapper: 当前页面索引: $_currentPageIndex');
    debugPrint('🧭 SmartNavigationWrapper: 极简布局: $_isLayoutMinimalist');
  }

  @override
  void dispose() {
    _pageTransitionController.dispose();
    super.dispose();
  }

  /// 初始化页面映射
  void _initializePages() {
    // TODO: 待页面类创建后启用
    // _pages = {
    //   0: _buildPageWithKey(0, const DashboardPage()),
    //   1: _buildPageWithKey(1, const FundExplorationPage()),
    //   2: _buildPageWithKey(2, const WatchlistPage()),
    //   3: _buildPageWithKey(3, _buildPortfolioPage()),
    //   4: _buildPageWithKey(4, const SettingsPage()),
    // };

    // 临时使用占位符页面
    // _pages = {
    //   0: _buildPageWithKey(0, _buildPlaceholderPage('市场概览')),
    //   1: _buildPageWithKey(1, _buildPlaceholderPage('基金筛选')),
    //   2: _buildPageWithKey(2, _buildPlaceholderPage('自选基金')),
    //   3: _buildPageWithKey(3, _buildPlaceholderPage('持仓分析')),
    //   4: _buildPageWithKey(4, _buildPlaceholderPage('设置')),
    // };
  }

  /// 为页面创建唯一Key
  // Widget _buildPageWithKey(int index, Widget page) {
  //   final key = GlobalKey();
  //   _pageKeys[index] = key;
  //   return KeyedSubtree(
  //     key: ValueKey('page_$index'),
  //     child: page,
  //   );
  // }

  /// 构建持仓分析页面
  // Widget _buildPortfolioPage() {
  //   return BlocProvider<PortfolioAnalysisCubit>.value(
  //     value: context.read<PortfolioAnalysisCubit>(),
  //     child: const PortfolioManager(),
  //   );
  // }

  /// 构建占位符页面
  // Widget _buildPlaceholderPage(String title) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: Text(title),
  //       centerTitle: true,
  //     ),
  //     body: Center(
  //       child: Column(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           Icon(
  //             Icons.build_circle_outlined,
  //             size: 64,
  //             color: Colors.grey[400],
  //           ),
  //           const SizedBox(height: 16),
  //           Text(
  //             title,
  //             style: Theme.of(context).textTheme.headlineSmall,
  //           ),
  //           const SizedBox(height: 8),
  //           Text(
  //             '页面开发中...',
  //             style: TextStyle(
  //               color: Colors.grey[600],
  //               fontSize: 16,
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  /// 处理页面导航
  void _handlePageNavigation(int index) {
    if (index == _currentPageIndex) return;

    debugPrint(
        '🧭 SmartNavigationWrapper: 从页面 $_currentPageIndex 导航到页面 $index');

    // 播放页面切换动画
    _pageTransitionController.reset();
    _pageTransitionController.forward();

    setState(() {
      _currentPageIndex = index;
    });

    // 可以在这里添加页面切换的额外逻辑
    _onPageChanged(index);
  }

  /// 页面切换回调
  void _onPageChanged(int newIndex) {
    // 发送页面切换事件（如果需要）
    debugPrint('🧭 SmartNavigationWrapper: 页面已切换到 $newIndex');

    // 可以在这里添加页面分析、日志记录等功能
    switch (newIndex) {
      case 0:
        debugPrint('📊 用户访问市场概览页面');
        break;
      case 1:
        debugPrint('🔍 用户访问基金筛选页面');
        break;
      case 2:
        debugPrint('⭐ 用户访问自选基金页面');
        break;
      case 3:
        debugPrint('📈 用户访问持仓分析页面');
        break;
      case 4:
        debugPrint('⚙️ 用户访问设置页面');
        break;
    }
  }

  /// 处理布局切换
  void _handleLayoutToggle() {
    setState(() {
      _isLayoutMinimalist = !_isLayoutMinimalist;
    });

    debugPrint(
        '🧭 SmartNavigationWrapper: 布局切换为${_isLayoutMinimalist ? '极简' : '标准'}模式');

    // 调试模式下不显示SnackBar，避免ScaffoldMessenger错误
    debugPrint('🧭 已切换到${_isLayoutMinimalist ? '极简' : '标准'}布局模式');
  }

  /// 获取当前页面
  // Widget get _currentPage {
  //   return _pages[_currentPageIndex] ?? _pages[0]!;
  // }

  @override
  Widget build(BuildContext context) {
    // final config = NavigationConfig.instance; // 暂时注释，待集成后启用

    return FadeTransition(
      opacity: _pageTransitionAnimation,
      child: widget.enableEnhancedDebug && kDebugMode
          ? _buildEnhancedNavigation(context)
          : _buildStandardNavigation(context),
    );
  }

  /// 构建标准导航（生产模式）
  Widget _buildStandardNavigation(BuildContext context) {
    // 直接使用NavigationShell来显示页面内容
    return NavigationShell(
      user: widget.user,
      onLogout: widget.onLogout,
    );
  }

  /// 构建增强导航（调试模式）
  Widget _buildEnhancedNavigation(BuildContext context) {
    return Stack(
      children: [
        // 主要页面内容
        NavigationShell(
          user: widget.user,
          onLogout: widget.onLogout,
        ),

        // 调试信息面板
        if (widget.enableEnhancedDebug && kDebugMode) _buildDebugPanel(context),
      ],
    );
  }

  /// 判断是否应该显示布局切换按钮
  bool _shouldShowLayoutToggle() {
    // 只在基金筛选页面显示布局切换
    return _currentPageIndex == 1;
  }

  /// 获取导航状态信息（用于调试）
  Map<String, dynamic> getNavigationState() {
    final config = NavigationConfig.instance;

    return {
      'currentPageIndex': _currentPageIndex,
      'currentMode': config.getCurrentNavigationMode().toString(),
      'isLayoutMinimalist': _isLayoutMinimalist,
      'showLayoutToggle': _shouldShowLayoutToggle(),
      'enableMultiPlatform': config.enableMultiPlatformNavigation,
      'useResponsiveNavigation': config.useResponsiveNavigation,
      'platform': kIsWeb ? 'Web' : 'Native',
      'debugMode': kDebugMode,
    };
  }

  /// 打印导航状态（调试用）
  void printNavigationState() {
    final state = getNavigationState();
    debugPrint('🧭 SmartNavigationWrapper 当前状态:');
    state.forEach((key, value) {
      debugPrint('  $key: $value');
    });
  }

  /// 构建调试信息面板
  Widget _buildDebugPanel(BuildContext context) {
    final config = NavigationConfig.instance;
    final mode = config.getCurrentNavigationMode();

    return Positioned(
      top: kIsWeb ? 80 : 120, // Web平台有顶部导航栏
      right: 16,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题
            Row(
              children: [
                const Icon(
                  Icons.settings_suggest,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Text(
                  '🧭 导航调试',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    config.printConfigSummary();
                  },
                  child: const Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 当前状态信息
            _buildInfoRow('当前页面', _getPageName(_currentPageIndex)),
            _buildInfoRow('导航模式', mode.displayName),
            _buildInfoRow('运行平台', kIsWeb ? 'Web' : 'Native'),
            _buildInfoRow('调试模式', kDebugMode ? '是' : '否'),
          ],
        ),
      ),
    );
  }

  /// 构建信息行
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 9,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 获取页面名称
  String _getPageName(int index) {
    switch (index) {
      case 0:
        return '市场概览';
      case 1:
        return '基金筛选';
      case 2:
        return '自选基金';
      case 3:
        return '持仓分析';
      case 4:
        return '系统设置';
      default:
        return '未知页面';
    }
  }
}

/// 简化版导航包装器（用于生产环境）
class SimpleNavigationWrapper extends StatelessWidget {
  /// 当前登录用户
  final User user;

  /// 登出回调函数
  final VoidCallback onLogout;

  const SimpleNavigationWrapper({
    super.key,
    required this.user,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationShell(
      user: user,
      onLogout: onLogout,
    );
  }
}

/// 导航包装器工厂
///
/// 根据配置自动选择合适的导航包装器
class NavigationWrapperFactory {
  /// 创建导航包装器
  static Widget createWrapper({
    required User user,
    required VoidCallback onLogout,
    bool enableEnhancedDebug = true,
  }) {
    final config = NavigationConfig.instance;
    final mode = config.getCurrentNavigationMode();

    debugPrint('🧭 NavigationWrapperFactory: 创建导航包装器');
    debugPrint('🧭 NavigationWrapperFactory: 使用模式: ${mode.displayName}');

    // 如果启用了多平台导航且不是传统模式
    if (config.enableMultiPlatformNavigation &&
        mode != MultiPlatformNavigationMode.legacy) {
      return SmartNavigationWrapper(
        user: user,
        onLogout: onLogout,
        enableEnhancedDebug: enableEnhancedDebug && kDebugMode,
      );
    }

    // 否则使用简化版导航包装器（传统模式）
    return SimpleNavigationWrapper(
      user: user,
      onLogout: onLogout,
    );
  }

  /// 强制创建特定类型的包装器
  static Widget createSpecificWrapper({
    required User user,
    required VoidCallback onLogout,
    required NavigationWrapperType type,
    bool enableEnhancedDebug = true,
  }) {
    debugPrint('🧭 NavigationWrapperFactory: 强制创建 ${type.name} 包装器');

    switch (type) {
      case NavigationWrapperType.smart:
        return SmartNavigationWrapper(
          user: user,
          onLogout: onLogout,
          enableEnhancedDebug: enableEnhancedDebug && kDebugMode,
        );
      case NavigationWrapperType.simple:
        return SimpleNavigationWrapper(
          user: user,
          onLogout: onLogout,
        );
    }
  }
}

/// 导航包装器类型枚举
enum NavigationWrapperType {
  /// 智能导航包装器（支持多平台）
  smart,

  /// 简单导航包装器（传统导航）
  simple,
}

/// 导航包装器类型扩展方法
extension NavigationWrapperTypeExtension on NavigationWrapperType {
  /// 获取类型名称
  String get name {
    switch (this) {
      case NavigationWrapperType.smart:
        return '智能导航';
      case NavigationWrapperType.simple:
        return '简单导航';
    }
  }

  /// 获取类型描述
  String get description {
    switch (this) {
      case NavigationWrapperType.smart:
        return '支持多平台响应式导航的智能包装器';
      case NavigationWrapperType.simple:
        return '传统导航模式的简化包装器';
    }
  }
}
