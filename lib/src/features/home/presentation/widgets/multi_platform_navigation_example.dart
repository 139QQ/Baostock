import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'responsive_navigation_bar.dart';
import '../../../auth/domain/entities/user.dart';

/// 多平台导航示例
///
/// 展示如何使用响应式导航栏来支持多平台
/// 包括Web端、桌面端和移动端的不同布局
class MultiPlatformNavigationExample extends StatefulWidget {
  const MultiPlatformNavigationExample({super.key});

  @override
  State<MultiPlatformNavigationExample> createState() =>
      _MultiPlatformNavigationExampleState();
}

class _MultiPlatformNavigationExampleState
    extends State<MultiPlatformNavigationExample> {
  int _currentIndex = 0;
  static final User _currentUser = User.testUser(
    id: 'demo_user_001',
    phoneNumber: '13800138000',
    email: 'demo@jisu-fund.com',
    displayName: '演示用户',
  );

  final List<NavigationPage> _pages = [
    NavigationPage(
      title: '市场概览',
      icon: Icons.dashboard,
      description: '查看市场动态和热门基金信息',
    ),
    NavigationPage(
      title: '基金筛选',
      icon: Icons.filter_alt,
      description: '使用强大的筛选工具找到理想基金',
    ),
    NavigationPage(
      title: '自选基金',
      icon: Icons.star,
      description: '管理您关注的自选基金列表',
    ),
    NavigationPage(
      title: '持仓分析',
      icon: Icons.analytics,
      description: '深度分析您的投资组合表现',
    ),
    NavigationPage(
      title: '系统设置',
      icon: Icons.settings,
      description: '个性化设置和应用偏好配置',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 平台检测信息
          _buildPlatformInfo(),
          // 响应式导航栏
          Expanded(
            child: ResponsiveNavigationBar(
              userName: _currentUser.displayName.isNotEmpty
                  ? _currentUser.displayName
                  : _currentUser.displayText,
              onLogout: _handleLogout,
              onNavigate: _handleNavigation,
              selectedIndex: _currentIndex,
              showLayoutToggle: true,
              onToggleLayout: _handleLayoutToggle,
              isMinimalistLayout: false,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建平台信息显示
  Widget _buildPlatformInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(
          bottom: BorderSide(color: Colors.blue[100]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.devices,
                color: Colors.blue[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '多平台导航演示',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildPlatformDetails(),
        ],
      ),
    );
  }

  /// 构建平台详细信息
  Widget _buildPlatformDetails() {
    final platform = _getPlatformName();
    final screenSize = _getScreenSizeType();
    const isWeb = kIsWeb;

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _buildInfoChip('平台', platform),
        _buildInfoChip('屏幕尺寸', screenSize),
        _buildInfoChip('Web环境', isWeb ? '是' : '否'),
        _buildInfoChip('当前页面', _pages[_currentIndex].title),
      ],
    );
  }

  /// 构建信息芯片
  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 获取平台名称
  String _getPlatformName() {
    if (kIsWeb) return 'Web';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'Android';
      case TargetPlatform.iOS:
        return 'iOS';
      case TargetPlatform.windows:
        return 'Windows';
      case TargetPlatform.macOS:
        return 'macOS';
      case TargetPlatform.linux:
        return 'Linux';
      default:
        return '未知';
    }
  }

  /// 获取屏幕尺寸类型
  String _getScreenSizeType() {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return '桌面';
    if (width >= 768) return '平板';
    return '手机';
  }

  /// 处理导航
  void _handleNavigation(int index) {
    setState(() {
      _currentIndex = index;
    });

    // 显示页面切换信息
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('切换到: ${_pages[index].title}'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 处理登出
  void _handleLogout() {
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已退出登录')),
              );
            },
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }

  /// 处理布局切换
  void _handleLayoutToggle() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('布局切换功能 - 演示模式'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}

/// 导航页面数据模型
class NavigationPage {
  final String title;
  final IconData icon;
  final String description;

  NavigationPage({
    required this.title,
    required this.icon,
    required this.description,
  });
}
