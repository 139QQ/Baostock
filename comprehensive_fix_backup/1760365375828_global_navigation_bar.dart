import 'package:flutter/material.dart';

/// 全局导航栏组件
///
/// 提供应用核心功能的快速访问入口，包含：
/// - 品牌Logo
/// - 主要功能导航
/// - 用户设置入口
/// - 搜索功能
class GlobalNavigationBar extends StatelessWidget
    implements PreferredSizeWidget {
  const GlobalNavigationBar({super.key});

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
            offset: Offset(0, 2),
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
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            // 品牌Logo
            _buildBrandLogo(),
            SizedBox(width: 32),

            // 主导航菜单
            _buildMainNavigation(),

            Spacer(),

            // 搜索框
            _buildSearchBox(),
            SizedBox(width: 16),

            // 用户设置
            _buildUserSettings(),
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
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
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
        _buildNavItem('基金筛选', Icons.filter_alt, onTap: () {}),
        const SizedBox(width: 24),
        _buildNavItem('持仓分析', Icons.pie_chart, onTap: () {}),
        const SizedBox(width: 24),
        _buildNavItem('行情预警', Icons.notifications, onTap: () {}),
        const SizedBox(width: 24),
        _buildNavItem('数据中心', Icons.storage, onTap: () {}),
      ],
    );
  }

  Widget _buildNavItem(String label, IconData icon, {VoidCallback? onTap}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                color: Color(0xFF64748B),
              ),
              SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
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
        color: Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 12),
          Icon(
            Icons.search,
            size: 16,
            color: Color(0xFF94A3B8),
          ),
          SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: '搜索基金代码或名称...',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserSettings() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {},
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.person_outline,
            size: 18,
            color: Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
