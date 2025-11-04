import 'package:flutter/material.dart';

import '../../../auth/domain/entities/user.dart';

/// 全局导航栏组件
///
/// 提供应用核心功能的快速访问入口，包含：
/// - 品牌Logo
/// - 主要功能导航
/// - 用户信息显示
/// - 搜索功能
/// - 登出功能
/// - 布局切换功能
class GlobalNavigationBar extends StatelessWidget
    implements PreferredSizeWidget {
  /// 当前登录用户
  final User user;

  /// 登出回调函数
  final VoidCallback onLogout;

  /// 是否显示布局切换按钮
  final bool showLayoutToggle;

  /// 布局切换回调函数
  final VoidCallback? onToggleLayout;

  /// 当前是否为极简布局
  final bool isMinimalistLayout;

  const GlobalNavigationBar({
    super.key,
    required this.user,
    required this.onLogout,
    this.showLayoutToggle = false,
    this.onToggleLayout,
    this.isMinimalistLayout = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: preferredSize.height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            // 品牌Logo
            _buildBrandLogo(),
            const SizedBox(width: 32),

            // 主导航菜单
            _buildMainNavigation(),

            const Spacer(),

            // 搜索框
            _buildSearchBox(),
            const SizedBox(width: 16),

            // 布局切换按钮（可选）
            if (showLayoutToggle) ...[
              _buildLayoutToggle(),
              const SizedBox(width: 16),
            ],

            // 用户信息
            _buildUserInfo(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandLogo() {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          child: const Icon(
            Icons.trending_up,
            color: Colors.white,
            size: 20,
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
    );
  }

  Widget _buildMainNavigation() {
    return Row(
      children: [
        _buildNavItem('基金筛选', const IconData(0xe3a9)),
        const SizedBox(width: 24),
        _buildNavItem('持仓分析', const IconData(0xe254)),
        const SizedBox(width: 24),
        _buildNavItem('行情预警', const IconData(0xe7f7)),
        const SizedBox(width: 24),
        _buildNavItem('数据中心', const IconData(0xe1db)),
      ],
    );
  }

  Widget _buildNavItem(String label, IconData icon) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.transparent,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: const Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      width: 300,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(
            Icons.search,
            size: 16,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: '搜索基金代码或名称...',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF475569),
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
        color: isMinimalistLayout
            ? const Color(0xFF2E7D32)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isMinimalistLayout
              ? const Color(0xFF2E7D32)
              : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggleLayout,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isMinimalistLayout ? Icons.view_compact : Icons.view_agenda,
                  size: 16,
                  color: isMinimalistLayout
                      ? Colors.white
                      : const Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Text(
                  isMinimalistLayout ? '极简' : '传统',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isMinimalistLayout
                        ? Colors.white
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建用户信息区域
  Widget _buildUserInfo(BuildContext context) {
    return PopupMenuButton<String>(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 用户头像
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              backgroundImage:
                  user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
              child: user.avatarUrl == null
                  ? Icon(
                      Icons.person,
                      size: 18,
                      color: Theme.of(context).primaryColor,
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            // 用户名称
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  '已登录',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ],
        ),
      ),
      onSelected: (value) {
        switch (value) {
          case 'profile':
            // 打开用户资料页面
            break;
          case 'settings':
            // 打开设置页面
            break;
          case 'logout':
            _showLogoutDialog(context);
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
                  fontSize: 14,
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
                  fontSize: 14,
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
                color: Colors.red.withOpacity(0.8),
              ),
              const SizedBox(width: 8),
              Text(
                '退出登录',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 显示登出确认对话框
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('您确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '取消',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.8),
              foregroundColor: Colors.white,
            ),
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }
}
