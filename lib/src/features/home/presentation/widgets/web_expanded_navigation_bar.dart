import 'package:flutter/material.dart';
import 'models/user_adapter.dart';

/// Web端扩展式导航栏
///
/// 为Web平台优化的导航栏，具有以下特性：
/// - 水平扩展式布局
/// - 大屏幕优化显示
/// - 鼠标悬停效果
/// - 响应式菜单项
class WebExpandedNavigationBar extends StatefulWidget {
  /// 当前登录用户
  final NavigationUser user;

  /// 登出回调函数
  final VoidCallback onLogout;

  /// 导航回调函数
  final Function(int) onNavigate;

  /// 当前选中的页面索引
  final int selectedIndex;

  /// 是否显示布局切换按钮
  final bool showLayoutToggle;

  /// 布局切换回调函数
  final VoidCallback? onToggleLayout;

  /// 当前是否为极简布局
  final bool isMinimalistLayout;

  /// 首选尺寸
  static Size get preferredSize => const Size.fromHeight(72);

  const WebExpandedNavigationBar({
    super.key,
    required this.user,
    required this.onLogout,
    required this.onNavigate,
    required this.selectedIndex,
    this.showLayoutToggle = false,
    this.onToggleLayout,
    this.isMinimalistLayout = false,
  });

  @override
  State<WebExpandedNavigationBar> createState() =>
      _WebExpandedNavigationBarState();
}

class _WebExpandedNavigationBarState extends State<WebExpandedNavigationBar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isSearchExpanded = false;

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      label: '市场概览',
      tooltip: '查看市场概览和实时数据',
      index: 0,
    ),
    NavigationItem(
      icon: Icons.filter_alt_outlined,
      selectedIcon: Icons.filter_alt,
      label: '基金筛选',
      tooltip: '筛选和搜索基金产品',
      index: 1,
    ),
    NavigationItem(
      icon: Icons.star_outline,
      selectedIcon: Icons.star,
      label: '自选基金',
      tooltip: '管理自选基金列表',
      index: 2,
    ),
    NavigationItem(
      icon: Icons.analytics_outlined,
      selectedIcon: Icons.analytics,
      label: '持仓分析',
      tooltip: '分析投资组合表现',
      index: 3,
    ),
    NavigationItem(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: '系统设置',
      tooltip: '系统设置和偏好配置',
      index: 4,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      height: WebExpandedNavigationBar.preferredSize.height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth > 1400 ? 48 : 24,
            vertical: 12,
          ),
          child: Row(
            children: [
              // 品牌Logo区域
              _buildBrandLogo(),
              const SizedBox(width: 48),

              // 主导航菜单 - 水平扩展式布局
              Expanded(
                child: _buildExpandedNavigation(),
              ),

              const SizedBox(width: 32),

              // 搜索区域
              _buildSearchArea(),
              const SizedBox(width: 24),

              // 布局切换按钮（可选）
              if (widget.showLayoutToggle) ...[
                _buildLayoutToggle(),
                const SizedBox(width: 16),
              ],

              // 用户区域
              _buildUserArea(),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建品牌Logo
  Widget _buildBrandLogo() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => widget.onNavigate(0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.trending_up,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '基速基金',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '专业基金分析平台',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建扩展式导航菜单
  Widget _buildExpandedNavigation() {
    return Row(
      children: _navigationItems.map((item) {
        final isSelected = widget.selectedIndex == item.index;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _buildExpandedNavItem(item, isSelected),
        );
      }).toList(),
    );
  }

  /// 构建扩展式导航项
  Widget _buildExpandedNavItem(NavigationItem item, bool isSelected) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => widget.onNavigate(item.index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : Colors.transparent,
            border: isSelected
                ? Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? item.selectedIcon : item.icon,
                size: 20,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建搜索区域
  Widget _buildSearchArea() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _isSearchExpanded ? 400 : 280,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(
            Icons.search,
            size: 18,
            color: Colors.grey[500],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onTap: () => setState(() => _isSearchExpanded = true),
              onSubmitted: (query) {
                if (query.trim().isNotEmpty) {
                  _performWebSearch(query.trim());
                }
              },
              decoration: InputDecoration(
                hintText: '搜索基金代码、名称或基金经理...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          if (_isSearchExpanded)
            GestureDetector(
              onTap: () => setState(() => _isSearchExpanded = false),
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: Colors.grey[500],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建布局切换按钮
  Widget _buildLayoutToggle() {
    return Container(
      decoration: BoxDecoration(
        color: widget.isMinimalistLayout
            ? const Color(0xFF2E7D32)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.isMinimalistLayout
              ? const Color(0xFF2E7D32)
              : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onToggleLayout,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.isMinimalistLayout
                      ? Icons.view_compact
                      : Icons.view_agenda,
                  size: 18,
                  color: widget.isMinimalistLayout
                      ? Colors.white
                      : Colors.grey[700],
                ),
                const SizedBox(width: 8),
                Text(
                  widget.isMinimalistLayout ? '极简视图' : '标准视图',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: widget.isMinimalistLayout
                        ? Colors.white
                        : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建用户区域
  Widget _buildUserArea() {
    return _buildUserMenu();
  }

  /// 构建用户菜单
  Widget _buildUserMenu() {
    return PopupMenuButton<String>(
      offset: const Offset(0, 8),
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              backgroundImage: widget.user.avatarUrl != null
                  ? NetworkImage(widget.user.avatarUrl!)
                  : null,
              child: widget.user.avatarUrl == null
                  ? Icon(
                      Icons.person,
                      size: 20,
                      color: Theme.of(context).primaryColor,
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.user.displayText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  'Web 客户端',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
      onSelected: (value) {
        switch (value) {
          case 'profile':
            debugPrint('打开用户资料页面 - TODO: 实现用户资料页面');
            break;
          case 'settings':
            widget.onNavigate(4);
            break;
          case 'logout':
            _showWebLogoutDialog();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline, size: 20, color: Colors.grey[700]),
              const SizedBox(width: 12),
              Text(
                '个人资料',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings_outlined, size: 20, color: Colors.grey[700]),
              const SizedBox(width: 12),
              Text(
                '系统设置',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(
                Icons.logout,
                size: 20,
                color: Colors.red[600],
              ),
              const SizedBox(width: 12),
              Text(
                '退出登录',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 执行Web端搜索
  void _performWebSearch(String query) {
    debugPrint('Web端搜索: $query');
    // TODO: 实现Web端搜索逻辑
  }

  /// 显示Web端登出对话框
  void _showWebLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('确认退出'),
        content: const Text('您确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '取消',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }
}

/// 导航项数据模型
class NavigationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String tooltip;
  final int index;

  NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.tooltip,
    required this.index,
  });
}
