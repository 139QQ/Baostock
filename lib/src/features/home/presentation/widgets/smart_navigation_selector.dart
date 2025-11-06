import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'responsive_navigation_bar.dart';
import 'config/navigation_config.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../navigation/presentation/pages/navigation_shell.dart';

/// 智能导航选择器
///
/// 根据配置和平台自动选择最合适的导航组件
/// 提供无缝的多平台导航体验
class SmartNavigationSelector extends StatelessWidget {
  /// 当前登录用户
  final User user;

  /// 登出回调函数
  final VoidCallback onLogout;

  /// 当前选中的页面索引
  final int selectedIndex;

  /// 页面导航回调函数
  final Function(int) onNavigate;

  /// 是否显示布局切换按钮
  final bool showLayoutToggle;

  /// 布局切换回调函数
  final VoidCallback? onToggleLayout;

  /// 当前是否为极简布局
  final bool isMinimalistLayout;

  const SmartNavigationSelector({
    super.key,
    required this.user,
    required this.onLogout,
    required this.selectedIndex,
    required this.onNavigate,
    this.showLayoutToggle = false,
    this.onToggleLayout,
    this.isMinimalistLayout = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = NavigationConfig.instance;
    final mode = config.getCurrentNavigationMode();

    debugPrint('🧭 SmartNavigationSelector: 使用导航模式: ${mode.displayName}');

    switch (mode) {
      case MultiPlatformNavigationMode.auto:
        return _buildAutoNavigation(context);
      case MultiPlatformNavigationMode.legacy:
        return _buildLegacyNavigation();
      case MultiPlatformNavigationMode.web:
        return _buildWebNavigation();
      case MultiPlatformNavigationMode.mobile:
        return _buildMobileNavigation();
      case MultiPlatformNavigationMode.desktop:
        return _buildLegacyNavigation(); // 桌面端暂时使用传统导航
    }
  }

  /// 自动选择导航模式
  Widget _buildAutoNavigation(BuildContext context) {
    final config = NavigationConfig.instance;

    if (config.shouldUseWebNavigation(context)) {
      return _buildWebNavigation();
    } else if (config.shouldUseMobileNavigation(context)) {
      return _buildMobileNavigation();
    } else {
      return _buildLegacyNavigation();
    }
  }

  /// 构建传统导航（现有的NavigationShell）
  Widget _buildLegacyNavigation() {
    return NavigationShell(
      user: user,
      onLogout: onLogout,
    );
  }

  /// 构建Web导航
  Widget _buildWebNavigation() {
    return ResponsiveNavigationBar(
      userName: user.displayName.isNotEmpty
          ? user.displayName
          : user.displayText, // 使用显示名称或脱敏手机号
      onLogout: onLogout,
      onNavigate: onNavigate,
      selectedIndex: selectedIndex,
      showLayoutToggle: showLayoutToggle,
      onToggleLayout: onToggleLayout,
      isMinimalistLayout: isMinimalistLayout,
    );
  }

  /// 构建移动端导航
  Widget _buildMobileNavigation() {
    return ResponsiveNavigationBar(
      userName: user.displayName.isNotEmpty
          ? user.displayName
          : user.displayText, // 使用显示名称或脱敏手机号
      onLogout: onLogout,
      onNavigate: onNavigate,
      selectedIndex: selectedIndex,
      showLayoutToggle: false, // 移动端不显示布局切换
      onToggleLayout: null,
      isMinimalistLayout: false,
    );
  }

  /// 创建调试信息面板（仅在调试模式下显示）
  Widget _buildDebugPanel(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    final config = NavigationConfig.instance;
    final mode = config.getCurrentNavigationMode();

    return Positioned(
      top: 80,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🧭 导航调试信息',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '模式: ${mode.displayName}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
            const Text(
              '平台: ${kIsWeb ? 'Web' : 'Native'}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
            Text(
              '多平台: ${config.enableMultiPlatformNavigation ? '启用' : '禁用'}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDebugButton('传统',
                    () => _switchMode(MultiPlatformNavigationMode.legacy)),
                const SizedBox(width: 4),
                _buildDebugButton(
                    'Web', () => _switchMode(MultiPlatformNavigationMode.web)),
                const SizedBox(width: 4),
                _buildDebugButton('移动',
                    () => _switchMode(MultiPlatformNavigationMode.mobile)),
                const SizedBox(width: 4),
                _buildDebugButton(
                    '自动', () => _switchMode(MultiPlatformNavigationMode.auto)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建调试按钮
  Widget _buildDebugButton(String label, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 8,
          ),
        ),
      ),
    );
  }

  /// 切换导航模式（仅调试模式）
  void _switchMode(MultiPlatformNavigationMode mode) {
    if (kDebugMode) {
      NavigationConfig.instance.updateConfig(
        forcedNavigationMode:
            mode == MultiPlatformNavigationMode.auto ? null : mode,
      );
      debugPrint('🧭 调试模式: 切换到 ${mode.displayName} 导航');
    }
  }
}

/// 增强版智能导航选择器（包含调试功能）
class EnhancedSmartNavigationSelector extends StatefulWidget {
  /// 当前登录用户
  final User user;

  /// 登出回调函数
  final VoidCallback onLogout;

  /// 当前选中的页面索引
  final int selectedIndex;

  /// 页面导航回调函数
  final Function(int) onNavigate;

  /// 是否显示布局切换按钮
  final bool showLayoutToggle;

  /// 布局切换回调函数
  final VoidCallback? onToggleLayout;

  /// 当前是否为极简布局
  final bool isMinimalistLayout;

  /// 是否启用调试模式
  final bool enableDebugMode;

  const EnhancedSmartNavigationSelector({
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
  State<EnhancedSmartNavigationSelector> createState() =>
      _EnhancedSmartNavigationSelectorState();
}

class _EnhancedSmartNavigationSelectorState
    extends State<EnhancedSmartNavigationSelector> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 主要导航组件
        SmartNavigationSelector(
          user: widget.user,
          onLogout: widget.onLogout,
          selectedIndex: widget.selectedIndex,
          onNavigate: widget.onNavigate,
          showLayoutToggle: widget.showLayoutToggle,
          onToggleLayout: widget.onToggleLayout,
          isMinimalistLayout: widget.isMinimalistLayout,
        ),

        // 调试信息面板
        if (widget.enableDebugMode && kDebugMode) _buildDebugPanel(context),
      ],
    );
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
            _buildInfoRow('当前模式', mode.displayName),
            _buildInfoRow('运行平台', kIsWeb ? 'Web' : 'Native'),
            _buildInfoRow('调试模式', kDebugMode ? '是' : '否'),
            _buildInfoRow(
                '多平台导航', config.enableMultiPlatformNavigation ? '启用' : '禁用'),
            _buildInfoRow(
                '响应式导航', config.useResponsiveNavigation ? '启用' : '禁用'),

            const SizedBox(height: 12),

            // 模式切换按钮
            const Text(
              '快速切换:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                _buildDebugButton('传统',
                    () => _switchMode(MultiPlatformNavigationMode.legacy)),
                _buildDebugButton(
                    'Web', () => _switchMode(MultiPlatformNavigationMode.web)),
                _buildDebugButton('移动',
                    () => _switchMode(MultiPlatformNavigationMode.mobile)),
                _buildDebugButton(
                    '自动', () => _switchMode(MultiPlatformNavigationMode.auto)),
              ],
            ),

            const SizedBox(height: 8),

            // 重置按钮
            Center(
              child: GestureDetector(
                onTap: () {
                  config.resetToDefaults();
                  // 调试模式下不显示SnackBar，避免ScaffoldMessenger错误
                  debugPrint('🧭 导航配置已重置为默认值');
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '重置配置',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ),
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

  /// 构建调试按钮
  Widget _buildDebugButton(String label, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// 切换导航模式
  void _switchMode(MultiPlatformNavigationMode mode) {
    NavigationConfig.instance.updateConfig(
      forcedNavigationMode:
          mode == MultiPlatformNavigationMode.auto ? null : mode,
    );

    // 调试模式下不显示SnackBar，避免ScaffoldMessenger错误
    debugPrint('🧭 已切换到 ${mode.displayName} 导航模式');

    debugPrint('🧭 调试模式: 切换到 ${mode.displayName} 导航');
  }
}
