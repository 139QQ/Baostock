import 'package:flutter/material.dart';
import 'models/user_adapter.dart';

/// Web端紧凑导航栏
///
/// 适用于中等屏幕尺寸的Web端导航栏
/// 保留核心功能的同时提供更紧凑的布局
class WebCompactNavigationBar extends StatefulWidget {
  /// 当前登录用户
  final NavigationUser user;

  /// 登出回调函数
  final VoidCallback onLogout;

  /// 导航回调函数
  final Function(int) onNavigate;

  /// 当前选中的页面索引
  final int selectedIndex;

  /// 首选尺寸
  static Size get preferredSize => const Size.fromHeight(64);

  const WebCompactNavigationBar({
    super.key,
    required this.user,
    required this.onLogout,
    required this.onNavigate,
    required this.selectedIndex,
  });

  @override
  State<WebCompactNavigationBar> createState() =>
      _WebCompactNavigationBarState();
}

class _WebCompactNavigationBarState extends State<WebCompactNavigationBar> {
  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      label: '概览',
      index: 0,
    ),
    NavigationItem(
      icon: Icons.filter_alt_outlined,
      selectedIcon: Icons.filter_alt,
      label: '筛选',
      index: 1,
    ),
    NavigationItem(
      icon: Icons.star_outline,
      selectedIcon: Icons.star,
      label: '自选',
      index: 2,
    ),
    NavigationItem(
      icon: Icons.analytics_outlined,
      selectedIcon: Icons.analytics,
      label: '分析',
      index: 3,
    ),
    NavigationItem(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: '设置',
      index: 4,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: WebCompactNavigationBar.preferredSize.height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            // 紧凑版品牌Logo
            _buildCompactBrandLogo(),
            const SizedBox(width: 24),

            // 紧凑导航菜单
            Expanded(
              child: _buildCompactNavigation(),
            ),

            const SizedBox(width: 16),

            // 紧凑搜索框
            _buildCompactSearch(),
            const SizedBox(width: 16),

            // 紧凑用户菜单
            _buildCompactUserMenu(),
          ],
        ),
      ),
    );
  }

  /// 构建紧凑品牌Logo
  Widget _buildCompactBrandLogo() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => widget.onNavigate(0),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.trending_up,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '基速基金',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建紧凑导航菜单
  Widget _buildCompactNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _navigationItems.map((item) {
        final isSelected = widget.selectedIndex == item.index;
        return Expanded(
          child: _buildCompactNavItem(item, isSelected),
        );
      }).toList(),
    );
  }

  /// 构建紧凑导航项
  Widget _buildCompactNavItem(NavigationItem item, bool isSelected) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => widget.onNavigate(item.index),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isSelected
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : Colors.transparent,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? item.selectedIcon : item.icon,
                size: 18,
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
      ),
    );
  }

  /// 构建紧凑搜索框
  Widget _buildCompactSearch() {
    return Container(
      width: 200,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(
            Icons.search,
            size: 16,
            color: Colors.grey[500],
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: '搜索...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF9CA3AF),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1E293B),
              ),
              onSubmitted: (query) {
                if (query.trim().isNotEmpty) {
                  debugPrint('Web紧凑搜索: $query');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 构建紧凑用户菜单
  Widget _buildCompactUserMenu() {
    return PopupMenuButton<String>(
      offset: const Offset(0, 8),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
        ),
        child: widget.user.avatarUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  widget.user.avatarUrl!,
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                ),
              )
            : Icon(
                Icons.person,
                size: 18,
                color: Theme.of(context).primaryColor,
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
            widget.onLogout();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              const Icon(Icons.person_outline, size: 18),
              const SizedBox(width: 8),
              Text(
                '个人资料',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'settings',
          child: Row(
            children: [
              const Icon(Icons.settings_outlined, size: 18),
              const SizedBox(width: 8),
              Text(
                '系统设置',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface,
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
                size: 18,
                color: Colors.red[600],
              ),
              const SizedBox(width: 8),
              Text(
                '退出登录',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.red[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 导航项数据模型（与扩展导航栏保持一致）
class NavigationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int index;

  NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.index,
  });
}
