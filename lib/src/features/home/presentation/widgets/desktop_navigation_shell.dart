import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../../auth/domain/entities/user.dart';
import '../../../navigation/presentation/pages/navigation_shell.dart';
import 'models/user_adapter.dart';
import 'config/navigation_config.dart';

/// 桌面端导航组件
///
/// 集成现有的NavigationShell到多平台导航系统
/// 为桌面端（Windows）提供优化的导航体验
class DesktopNavigationShell extends StatelessWidget {
  /// 当前登录用户
  final User user;

  /// 登出回调函数
  final VoidCallback onLogout;

  /// 当前选中的页面索引
  final int selectedIndex;

  /// 页面导航回调
  final Function(int) onNavigate;

  /// 是否显示布局切换按钮
  final bool showLayoutToggle;

  /// 布局切换回调
  final VoidCallback? onToggleLayout;

  /// 是否为极简布局
  final bool isMinimalistLayout;

  /// 是否启用调试模式
  final bool enableDebugMode;

  const DesktopNavigationShell({
    super.key,
    required this.user,
    required this.onLogout,
    required this.selectedIndex,
    required this.onNavigate,
    this.showLayoutToggle = false,
    this.onToggleLayout,
    this.isMinimalistLayout = false,
    this.enableDebugMode = false,
  });

  @override
  Widget build(BuildContext context) {
    // 桌面端直接使用现有的NavigationShell
    // NavigationShell已经包含了完整的桌面端导航逻辑
    return NavigationShell(
      user: user,
      onLogout: onLogout,
    );
  }

  /// 获取导航状态信息（用于调试）
  Map<String, dynamic> getNavigationState() {
    final config = NavigationConfig.instance;

    return {
      'platform': 'Desktop',
      'selectedIndex': selectedIndex,
      'showLayoutToggle': showLayoutToggle,
      'isMinimalistLayout': isMinimalistLayout,
      'enableDebugMode': enableDebugMode,
      'navigationMode': config.getCurrentNavigationMode().toString(),
      'useMultiPlatformNavigation': config.enableMultiPlatformNavigation,
    };
  }

  /// 打印导航状态（调试用）
  void printNavigationState() {
    if (kDebugMode && enableDebugMode) {
      final state = getNavigationState();
      debugPrint('🖥️ DesktopNavigationShell 状态:');
      state.forEach((key, value) {
        debugPrint('  $key: $value');
      });
    }
  }
}

/// 增强版桌面端导航组件
///
/// 提供更多桌面端特有功能和调试选项
class EnhancedDesktopNavigationShell extends StatefulWidget {
  /// 当前登录用户
  final User user;

  /// 登出回调函数
  final VoidCallback onLogout;

  /// 当前选中的页面索引
  final int selectedIndex;

  /// 页面导航回调
  final Function(int) onNavigate;

  /// 是否显示布局切换按钮
  final bool showLayoutToggle;

  /// 布局切换回调
  final VoidCallback? onToggleLayout;

  /// 是否为极简布局
  final bool isMinimalistLayout;

  /// 是否启用调试模式
  final bool enableDebugMode;

  const EnhancedDesktopNavigationShell({
    super.key,
    required this.user,
    required this.onLogout,
    required this.selectedIndex,
    required this.onNavigate,
    this.showLayoutToggle = false,
    this.onToggleLayout,
    this.isMinimalistLayout = false,
    this.enableDebugMode = true,
  });

  @override
  State<EnhancedDesktopNavigationShell> createState() =>
      _EnhancedDesktopNavigationShellState();
}

class _EnhancedDesktopNavigationShellState
    extends State<EnhancedDesktopNavigationShell> {
  bool _showDebugPanel = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 主导航区域
          Expanded(
            child: NavigationShell(
              user: widget.user,
              onLogout: widget.onLogout,
            ),
          ),

          // 调试面板（仅在调试模式下显示）
          if (widget.enableDebugMode && kDebugMode)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _showDebugPanel ? 300 : 0,
              child: _showDebugPanel
                  ? _buildDebugPanel()
                  : const SizedBox.shrink(),
            ),
        ],
      ),

      // 调试模式切换按钮
      floatingActionButton: widget.enableDebugMode && kDebugMode
          ? FloatingActionButton(
              mini: true,
              onPressed: () {
                setState(() {
                  _showDebugPanel = !_showDebugPanel;
                });
              },
              tooltip: '切换调试面板',
              child: Icon(
                _showDebugPanel ? Icons.bug_report : Icons.bug_report_outlined,
              ),
            )
          : null,
    );
  }

  /// 构建调试面板
  Widget _buildDebugPanel() {
    final config = NavigationConfig.instance;
    final navigationUser = UserAdapter.fromAuthUser(widget.user);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          left: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 调试面板标题
            const Row(
              children: [
                Icon(Icons.bug_report, size: 20),
                SizedBox(width: 8),
                Text(
                  '桌面端调试面板',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(),

            // 导航状态信息
            _buildDebugSection('导航状态', [
              _buildDebugItem('平台', 'Desktop'),
              _buildDebugItem('选中页面', '${widget.selectedIndex}'),
              _buildDebugItem('极简布局', widget.isMinimalistLayout ? '是' : '否'),
              _buildDebugItem('显示布局切换', widget.showLayoutToggle ? '是' : '否'),
            ]),

            // 配置信息
            _buildDebugSection('配置信息', [
              _buildDebugItem(
                  '导航模式', config.getCurrentNavigationMode().displayName),
              _buildDebugItem(
                  '多平台导航', config.enableMultiPlatformNavigation ? '启用' : '禁用'),
              _buildDebugItem(
                  '响应式导航', config.useResponsiveNavigation ? '启用' : '禁用'),
            ]),

            // 用户信息
            _buildDebugSection('用户信息', [
              _buildDebugItem('用户名', navigationUser.displayText),
              _buildDebugItem('用户级别', navigationUser.level ?? '标准'),
              _buildDebugItem(
                  'VIP状态', navigationUser.level == 'VIP' ? '是' : '否'),
            ]),

            // 操作按钮
            const Spacer(),
            _buildDebugSection('操作', [
              ElevatedButton.icon(
                onPressed: () {
                  _printNavigationState();
                },
                icon: const Icon(Icons.print, size: 16),
                label: const Text('打印状态'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(32),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  config.printConfigSummary();
                },
                icon: const Icon(Icons.settings, size: 16),
                label: const Text('配置摘要'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(32),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  /// 构建调试分组
  Widget _buildDebugSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          ...children,
        ],
      ),
    );
  }

  /// 构建调试项
  Widget _buildDebugItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// 打印导航状态（调试用）
  void _printNavigationState() {
    if (kDebugMode && widget.enableDebugMode) {
      final config = NavigationConfig.instance;

      debugPrint('🖥️ EnhancedDesktopNavigationShell 状态:');
      debugPrint('  用户: ${widget.user.displayName}');
      debugPrint('  选中页面: ${widget.selectedIndex}');
      debugPrint('  极简布局: ${widget.isMinimalistLayout}');
      debugPrint('  导航模式: ${config.getCurrentNavigationMode().displayName}');
      debugPrint('  多平台导航: ${config.enableMultiPlatformNavigation}');
    }
  }
}
