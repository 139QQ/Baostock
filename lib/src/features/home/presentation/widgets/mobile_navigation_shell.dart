import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'mobile_drawer_menu.dart';
import 'models/user_adapter.dart';

/// 移动端导航外壳
///
/// 为移动平台优化的导航组件，包含：
/// - 底部标签栏导航
/// - 抽屉式菜单
/// - 小屏幕优化显示
/// - 触摸友好的交互设计
class MobileNavigationShell extends StatefulWidget {
  /// 当前登录用户
  final NavigationUser user;

  /// 登出回调函数
  final VoidCallback onLogout;

  /// 当前选中的页面索引
  final int selectedIndex;

  const MobileNavigationShell({
    super.key,
    required this.user,
    required this.onLogout,
    required this.selectedIndex,
  });

  @override
  State<MobileNavigationShell> createState() => _MobileNavigationShellState();
}

class _MobileNavigationShellState extends State<MobileNavigationShell>
    with TickerProviderStateMixin {
  late AnimationController _bottomNavController;
  late AnimationController _fabController;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isFabExpanded = false;

  final List<BottomNavItem> _bottomNavItems = [
    BottomNavItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: '概览',
      index: 0,
    ),
    BottomNavItem(
      icon: Icons.filter_alt_outlined,
      activeIcon: Icons.filter_alt,
      label: '筛选',
      index: 1,
    ),
    BottomNavItem(
      icon: Icons.add_circle_outline,
      activeIcon: Icons.add_circle,
      label: '快捷',
      index: -1, // 特殊项，触发FAB功能
      isFab: true,
    ),
    BottomNavItem(
      icon: Icons.star_outline,
      activeIcon: Icons.star,
      label: '自选',
      index: 2,
    ),
    BottomNavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: '我的',
      index: 3,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bottomNavController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _bottomNavController.forward();
  }

  @override
  void dispose() {
    _bottomNavController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: Colors.grey[50],
      // 移动端应用栏
      appBar: _buildMobileAppBar(isSmallScreen),
      // 侧边抽屉菜单
      drawer: MobileDrawerMenu(
        user: widget.user,
        onLogout: widget.onLogout,
        onClose: () => _scaffoldKey.currentState?.closeDrawer(),
        onNavigate: (index) {
          _scaffoldKey.currentState?.closeDrawer();
          _navigateToPage(index);
        },
      ),
      // 主要内容区域
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            // 内容区域
            Expanded(
              child: _buildCurrentPage(),
            ),
            // 底部安全区域
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
      // 浮动操作按钮
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // 底部导航栏
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// 构建移动端应用栏
  PreferredSizeWidget _buildMobileAppBar(bool isSmallScreen) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Color(0xFF1E293B)),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.trending_up,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            '基速基金',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
      actions: [
        // 搜索按钮
        IconButton(
          icon: const Icon(Icons.search, color: Color(0xFF1E293B)),
          onPressed: _showMobileSearch,
        ),
        // 通知按钮
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined,
                  color: Color(0xFF1E293B)),
              onPressed: _showNotifications,
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  /// 构建当前页面
  Widget _buildCurrentPage() {
    // 根据选中索引返回对应页面
    switch (widget.selectedIndex) {
      case 0:
        return const Center(
          child: Text('市场概览页面 - 移动端', style: TextStyle(fontSize: 16)),
        );
      case 1:
        return const Center(
          child: Text('基金筛选页面 - 移动端', style: TextStyle(fontSize: 16)),
        );
      case 2:
        return const Center(
          child: Text('自选基金页面 - 移动端', style: TextStyle(fontSize: 16)),
        );
      case 3:
        return const Center(
          child: Text('个人中心页面 - 移动端', style: TextStyle(fontSize: 16)),
        );
      default:
        return const Center(
          child: Text('未知页面', style: TextStyle(fontSize: 16)),
        );
    }
  }

  /// 构建底部导航栏
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 65,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _bottomNavItems.map((item) {
              if (item.isFab) {
                return const SizedBox(width: 56); // FAB 占位空间
              }
              return _buildBottomNavItem(item);
            }).toList(),
          ),
        ),
      ),
    );
  }

  /// 构建底部导航项
  Widget _buildBottomNavItem(BottomNavItem item) {
    final isSelected = widget.selectedIndex == item.index;

    return GestureDetector(
      onTap: () => _navigateToPage(item.index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? item.activeIcon : item.icon,
              size: 24,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey[600],
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建浮动操作按钮
  Widget _buildFloatingActionButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 快捷操作菜单
        if (_isFabExpanded)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                _buildFabAction('扫一扫', Icons.qr_code_scanner, _scanQRCode),
                const SizedBox(height: 12),
                _buildFabAction('快速搜索', Icons.search, _quickSearch),
                const SizedBox(height: 12),
                _buildFabAction('添加自选', Icons.add, _addToFavorites),
              ],
            ),
          ),
        // 主FAB按钮
        FloatingActionButton(
          onPressed: _toggleFab,
          backgroundColor: Theme.of(context).primaryColor,
          elevation: 6,
          child: AnimatedRotation(
            turns: _isFabExpanded ? 0.45 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建FAB操作项
  Widget _buildFabAction(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        _toggleFab();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 切换FAB状态
  void _toggleFab() {
    setState(() {
      _isFabExpanded = !_isFabExpanded;
    });
  }

  /// 导航到指定页面
  void _navigateToPage(int index) {
    if (index == widget.selectedIndex) return;

    setState(() {
      // 更新选中索引（实际项目中应该通过状态管理来处理）
    });

    HapticFeedback.lightImpact(); // 触觉反馈
  }

  /// 显示移动端搜索
  void _showMobileSearch() {
    showSearch(
      context: context,
      delegate: MobileSearchDelegate(),
    );
  }

  /// 显示通知
  void _showNotifications() {
    // TODO: 实现通知页面
    debugPrint('显示通知页面');
  }

  /// 扫码功能
  void _scanQRCode() {
    // TODO: 实现扫码功能
    debugPrint('扫码功能');
  }

  /// 快速搜索
  void _quickSearch() {
    _showMobileSearch();
  }

  /// 添加到自选
  void _addToFavorites() {
    // TODO: 实现添加到自选功能
    debugPrint('添加到自选');
  }
}

/// 底部导航项数据模型
class BottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final bool isFab;

  BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    this.isFab = false,
  });
}

/// 移动端搜索委托
class MobileSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // TODO: 实现搜索结果
    return Center(
      child: Text('搜索结果: $query'),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // TODO: 实现搜索建议
    final suggestions = [
      '易方达蓝筹精选',
      '汇添富价值精选',
      '富国天惠成长',
    ];

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = suggestions[index];
        return ListTile(
          leading: const Icon(Icons.history),
          title: Text(suggestion),
          onTap: () {
            query = suggestion;
            showResults(context);
          },
        );
      },
    );
  }
}
