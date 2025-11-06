import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/user_adapter.dart';

/// 移动端抽屉式菜单
///
/// 提供移动端的侧边导航菜单，包含：
/// - 用户信息显示
/// - 主要功能导航
/// - 快捷操作入口
/// - 设置和登出选项
class MobileDrawerMenu extends StatefulWidget {
  /// 当前登录用户
  final NavigationUser user;

  /// 登出回调函数
  final VoidCallback onLogout;

  /// 关闭抽屉回调函数
  final VoidCallback onClose;

  /// 导航回调函数
  final Function(int) onNavigate;

  const MobileDrawerMenu({
    super.key,
    required this.user,
    required this.onLogout,
    required this.onClose,
    required this.onNavigate,
  });

  @override
  State<MobileDrawerMenu> createState() => _MobileDrawerMenuState();
}

class _MobileDrawerMenuState extends State<MobileDrawerMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final List<DrawerMenuItem> _menuItems = [
    DrawerMenuItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      title: '市场概览',
      subtitle: '查看市场动态和热门基金',
      index: 0,
      color: Colors.blue,
    ),
    DrawerMenuItem(
      icon: Icons.filter_alt_outlined,
      activeIcon: Icons.filter_alt,
      title: '基金筛选',
      subtitle: '筛选和搜索基金产品',
      index: 1,
      color: Colors.green,
    ),
    DrawerMenuItem(
      icon: Icons.star_outline,
      activeIcon: Icons.star,
      title: '自选基金',
      subtitle: '管理关注的基金',
      index: 2,
      color: Colors.orange,
    ),
    DrawerMenuItem(
      icon: Icons.analytics_outlined,
      activeIcon: Icons.analytics,
      title: '持仓分析',
      subtitle: '分析投资组合表现',
      index: 3,
      color: Colors.purple,
    ),
  ];

  final List<DrawerQuickAction> _quickActions = [
    DrawerQuickAction(
      icon: Icons.qr_code_scanner,
      title: '扫一扫',
      subtitle: '扫描基金二维码',
      color: Colors.indigo,
      onTap: () => debugPrint('扫码功能'),
    ),
    DrawerQuickAction(
      icon: Icons.calculate,
      title: '收益计算',
      subtitle: '计算投资收益',
      color: Colors.teal,
      onTap: () => debugPrint('收益计算'),
    ),
    DrawerQuickAction(
      icon: Icons.compare_arrows,
      title: '基金对比',
      subtitle: '对比多只基金',
      color: Colors.red,
      onTap: () => debugPrint('基金对比'),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: -50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 280,
      backgroundColor: Colors.grey[50],
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.grey[50]!,
            ],
          ),
        ),
        child: Column(
          children: [
            // 用户信息头部
            _buildUserHeader(),

            // 主要菜单项
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // 导航菜单
                  _buildMenuSection(),
                  const SizedBox(height: 16),
                  // 快捷操作
                  _buildQuickActionsSection(),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // 底部设置区域
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  /// 构建用户信息头部
  Widget _buildUserHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 用户头像和信息
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  // TODO: 打开用户资料编辑
                  debugPrint('编辑用户资料');
                },
                child: Stack(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: widget.user.avatarUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: Image.network(
                                widget.user.avatarUrl!,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.person,
                                    size: 30,
                                    color: Colors.white.withOpacity(0.8),
                                  );
                                },
                              ),
                            )
                          : Icon(
                              Icons.person,
                              size: 30,
                              color: Colors.white.withOpacity(0.8),
                            ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Theme.of(context).primaryColor,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.edit,
                          size: 12,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.user.displayText,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '移动端用户',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'VIP会员',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建菜单部分
  Widget _buildMenuSection() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: _menuItems.map((item) {
                  return _buildMenuItem(item);
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建菜单项
  Widget _buildMenuItem(DrawerMenuItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onClose();
          widget.onNavigate(item.index);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item.icon,
                  size: 20,
                  color: item.color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建快捷操作部分
  Widget _buildQuickActionsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '快捷操作',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          ..._quickActions.map(_buildQuickActionItem),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// 构建快捷操作项
  Widget _buildQuickActionItem(DrawerQuickAction action) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onClose();
          action.onTap();
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: action.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  action.icon,
                  size: 18,
                  color: action.color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      action.subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建底部设置区域
  Widget _buildBottomSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildBottomItem(
            icon: Icons.settings_outlined,
            title: '系统设置',
            onTap: () {
              widget.onClose();
              widget.onNavigate(4);
            },
          ),
          _buildBottomItem(
            icon: Icons.help_outline,
            title: '帮助与反馈',
            onTap: () {
              widget.onClose();
              debugPrint('打开帮助页面');
            },
          ),
          _buildBottomItem(
            icon: Icons.info_outline,
            title: '关于我们',
            onTap: () {
              widget.onClose();
              debugPrint('打开关于页面');
            },
          ),
          const Divider(height: 1),
          _buildBottomItem(
            icon: Icons.logout,
            title: '退出登录',
            textColor: Colors.red[600],
            iconColor: Colors.red[600],
            onTap: _showLogoutDialog,
          ),
        ],
      ),
    );
  }

  /// 构建底部项
  Widget _buildBottomItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: iconColor ?? Colors.grey[600],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textColor ?? const Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 显示登出确认对话框
  void _showLogoutDialog() {
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
              style: TextStyle(color: Colors.grey[600]),
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

/// 抽屉菜单项数据模型
class DrawerMenuItem {
  final IconData icon;
  final IconData activeIcon;
  final String title;
  final String subtitle;
  final int index;
  final Color color;

  DrawerMenuItem({
    required this.icon,
    required this.activeIcon,
    required this.title,
    required this.subtitle,
    required this.index,
    required this.color,
  });
}

/// 抽屉快捷操作数据模型
class DrawerQuickAction {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  DrawerQuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}
