import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// 导入各个平台的导航组件
import 'web_expanded_navigation_bar.dart';
import 'web_compact_navigation_bar.dart';
import 'mobile_navigation_shell.dart';

// 导入NavigationUser类
import 'models/user_adapter.dart';

/// 响应式导航栏组件
///
/// 根据平台类型和屏幕尺寸自动适配不同的导航布局
/// 支持：Web端扩展式导航、桌面端侧边栏、移动端底部导航
class ResponsiveNavigationBar extends StatelessWidget {
  /// 当前登录用户名称 (临时使用String替代User类型)
  final String userName;

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

  const ResponsiveNavigationBar({
    super.key,
    required this.userName,
    required this.onLogout,
    required this.onNavigate,
    required this.selectedIndex,
    this.showLayoutToggle = false,
    this.onToggleLayout,
    this.isMinimalistLayout = false,
  });

  /// 检测当前平台类型
  TargetPlatform get _currentPlatform => defaultTargetPlatform;

  /// 检测是否为 Web 平台
  bool get _isWebPlatform => kIsWeb;

  /// 检测是否为移动平台
  bool get _isMobilePlatform =>
      _currentPlatform == TargetPlatform.iOS ||
      _currentPlatform == TargetPlatform.android;

  /// 获取屏幕尺寸类型
  ScreenSizeType getScreenSizeType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width >= 1200) return ScreenSizeType.desktop;
    if (width >= 768) return ScreenSizeType.tablet;
    return ScreenSizeType.mobile;
  }

  @override
  Widget build(BuildContext context) {
    final screenSizeType = getScreenSizeType(context);

    // Web 平台优先使用 Web 端布局
    if (_isWebPlatform) {
      return _buildWebNavigation(screenSizeType);
    }

    // 移动平台使用移动端布局
    if (_isMobilePlatform) {
      return _buildMobileNavigation(screenSizeType);
    }

    // 桌面平台使用桌面端布局
    return _buildDesktopNavigation(screenSizeType);
  }

  /// 构建 Web 端导航
  Widget _buildWebNavigation(ScreenSizeType screenSizeType) {
    // 创建简化的NavigationUser对象
    final navigationUser = NavigationUser(
      displayText: userName,
    );

    switch (screenSizeType) {
      case ScreenSizeType.desktop:
        return WebExpandedNavigationBar(
          user: navigationUser,
          onLogout: onLogout,
          onNavigate: onNavigate,
          selectedIndex: selectedIndex,
          showLayoutToggle: showLayoutToggle,
          onToggleLayout: onToggleLayout,
          isMinimalistLayout: isMinimalistLayout,
        );
      case ScreenSizeType.tablet:
        return WebCompactNavigationBar(
          user: navigationUser,
          onLogout: onLogout,
          onNavigate: onNavigate,
          selectedIndex: selectedIndex,
        );
      case ScreenSizeType.mobile:
        return _buildMobileNavigation(screenSizeType);
    }
  }

  /// 构建桌面端导航
  Widget _buildDesktopNavigation(ScreenSizeType screenSizeType) {
    // 桌面端导航使用简化的容器，保持与GlobalNavigationBar一致的高度
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 简化的导航菜单
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Builder(
                builder: (context) => Row(
                  children: [
                    _buildNavItem(context, '首页', 0),
                    _buildNavItem(context, '基金', 1),
                    _buildNavItem(context, '投资组合', 2),
                    _buildNavItem(context, '市场', 3),
                    _buildNavItem(context, '设置', 4),
                  ],
                ),
              ),
            ),
          ),
          // 用户信息和操作区域
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  '欢迎，$userName',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: onLogout,
                  child: const Text('退出'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建导航项
  Widget _buildNavItem(BuildContext context, String title, int index) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onNavigate(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            title,
            style: TextStyle(
              color:
                  isSelected ? Theme.of(context).primaryColor : Colors.black87,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  /// 构建移动端导航
  Widget _buildMobileNavigation(ScreenSizeType screenSizeType) {
    // 创建简化的NavigationUser对象
    final navigationUser = NavigationUser(
      displayText: userName,
    );

    return MobileNavigationShell(
      user: navigationUser,
      onLogout: onLogout,
      selectedIndex: selectedIndex,
    );
  }
}

/// 屏幕尺寸类型枚举
enum ScreenSizeType {
  desktop,
  tablet,
  mobile,
}
