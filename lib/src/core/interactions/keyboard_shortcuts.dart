import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 键盘快捷键系统
/// 提供全局和上下文相关的键盘快捷键支持
class KeyboardShortcuts {
  static final Map<String, Map<String, ShortcutAction>> _shortcuts = {};
  static final Map<String, ShortcutAction> _globalShortcuts = {};
  static final Set<LogicalKeySet> _registeredKeys = {};

  static ShortcutAction? _lastTriggeredAction;
  static DateTime? _lastTriggerTime;

  /// 初始化键盘快捷键系统
  static void initialize() {
    // 注册默认快捷键
    registerDefaultShortcuts();

    // 监听键盘事件
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  /// 注册默认快捷键
  static void registerDefaultShortcuts() {
    // 全局快捷键
    registerGlobalShortcut(
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF),
      ShortcutAction(
        id: 'search_funds',
        label: '搜索基金',
        description: '打开基金搜索框',
        category: ShortcutCategory.navigation,
        onPressed: () => _handleSearchFunds(),
      ),
    );

    registerGlobalShortcut(
      LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.home),
      ShortcutAction(
        id: 'home_page',
        label: '返回主页',
        description: '导航到主页',
        category: ShortcutCategory.navigation,
        onPressed: () => _handleNavigateToHome(),
      ),
    );

    registerGlobalShortcut(
      LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.keyP),
      ShortcutAction(
        id: 'portfolio',
        label: '投资组合',
        description: '打开投资组合页面',
        category: ShortcutCategory.navigation,
        onPressed: () => _handleNavigateToPortfolio(),
      ),
    );

    registerGlobalShortcut(
      LogicalKeySet(LogicalKeyboardKey.f5),
      ShortcutAction(
        id: 'refresh',
        label: '刷新',
        description: '刷新当前页面数据',
        category: ShortcutCategory.action,
        onPressed: () => _handleRefresh(),
      ),
    );

    registerGlobalShortcut(
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.f5),
      ShortcutAction(
        id: 'force_refresh',
        label: '强制刷新',
        description: '强制刷新当前页面数据（清除缓存）',
        category: ShortcutCategory.action,
        onPressed: () => _handleForceRefresh(),
      ),
    );

    registerGlobalShortcut(
      LogicalKeySet(LogicalKeyboardKey.f11),
      ShortcutAction(
        id: 'fullscreen',
        label: '全屏切换',
        description: '切换全屏模式',
        category: ShortcutCategory.view,
        onPressed: () => _handleToggleFullscreen(),
      ),
    );

    registerGlobalShortcut(
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.comma),
      ShortcutAction(
        id: 'settings',
        label: '设置',
        description: '打开设置页面',
        category: ShortcutCategory.navigation,
        onPressed: () => _handleOpenSettings(),
      ),
    );

    // 基金相关快捷键
    registerContextShortcut(
      'fund_list',
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyA),
      ShortcutAction(
        id: 'select_all_funds',
        label: '全选基金',
        description: '选择当前列表中的所有基金',
        category: ShortcutCategory.selection,
        onPressed: () => _handleSelectAllFunds(),
      ),
    );

    registerContextShortcut(
      'fund_list',
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyC),
      ShortcutAction(
        id: 'add_to_comparison',
        label: '添加到对比',
        description: '将选中的基金添加到对比列表',
        category: ShortcutCategory.action,
        onPressed: () => _handleAddToComparison(),
      ),
    );

    registerContextShortcut(
      'fund_list',
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF),
      ShortcutAction(
        id: 'add_to_favorites',
        label: '添加到收藏',
        description: '将选中的基金添加到收藏夹',
        category: ShortcutCategory.action,
        onPressed: () => _handleAddToFavorites(),
      ),
    );

    registerContextShortcut(
      'fund_list',
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyE),
      ShortcutAction(
        id: 'export_data',
        label: '导出数据',
        description: '导出当前基金列表数据',
        category: ShortcutCategory.action,
        onPressed: () => _handleExportData(),
      ),
    );

    registerContextShortcut(
      'fund_list',
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyG),
      ShortcutAction(
        id: 'toggle_grid_view',
        label: '切换网格视图',
        description: '在列表和网格视图之间切换',
        category: ShortcutCategory.view,
        onPressed: () => _handleToggleGridView(),
      ),
    );

    registerContextShortcut(
      'fund_list',
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyL),
      ShortcutAction(
        id: 'toggle_list_view',
        label: '切换列表视图',
        description: '在列表和网格视图之间切换',
        category: ShortcutCategory.view,
        onPressed: () => _handleToggleListView(),
      ),
    );

    registerContextShortcut(
      'fund_list',
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.equal),
      ShortcutAction(
        id: 'zoom_in',
        label: '放大',
        description: '放大基金卡片视图',
        category: ShortcutCategory.view,
        onPressed: () => _handleZoomIn(),
      ),
    );

    registerContextShortcut(
      'fund_list',
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.minus),
      ShortcutAction(
        id: 'zoom_out',
        label: '缩小',
        description: '缩小基金卡片视图',
        category: ShortcutCategory.view,
        onPressed: () => _handleZoomOut(),
      ),
    );

    // 基金详情页快捷键
    registerContextShortcut(
      'fund_detail',
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyR),
      ShortcutAction(
        id: 'refresh_fund_detail',
        label: '刷新基金详情',
        description: '刷新当前基金的详细数据',
        category: ShortcutCategory.action,
        onPressed: () => _handleRefreshFundDetail(),
      ),
    );

    registerContextShortcut(
      'fund_detail',
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyB),
      ShortcutAction(
        id: 'back_to_list',
        label: '返回列表',
        description: '返回到基金列表',
        category: ShortcutCategory.navigation,
        onPressed: () => _handleBackToList(),
      ),
    );
  }

  /// 注册全局快捷键
  static void registerGlobalShortcut(
      LogicalKeySet keySet, ShortcutAction action) {
    _globalShortcuts[_keySetToString(keySet)] = action;
    _registeredKeys.add(keySet);
  }

  /// 注册上下文相关快捷键
  static void registerContextShortcut(
      String context, LogicalKeySet keySet, ShortcutAction action) {
    final contextShortcuts =
        _shortcuts.putIfAbsent(context, () => <String, ShortcutAction>{});
    contextShortcuts[_keySetToString(keySet)] = action;
    _registeredKeys.add(keySet);
  }

  /// 获取当前上下文的快捷键
  static Map<String, ShortcutAction> getContextShortcuts(String context) {
    final result = <String, ShortcutAction>{};

    // 添加全局快捷键
    result.addAll(_globalShortcuts);

    // 添加上下文特定快捷键
    if (_shortcuts.containsKey(context)) {
      result.addAll(_shortcuts[context]!);
    }

    return result;
  }

  /// 触发快捷键动作
  static bool triggerShortcut(String actionId, {String? context}) {
    // 首先查找上下文特定快捷键
    ShortcutAction? action = (context != null &&
            _shortcuts.containsKey(context))
        ? _shortcuts[context]!.values.where((a) => a.id == actionId).firstOrNull
        : null;

    // 如果没找到，查找全局快捷键
    action ??=
        _globalShortcuts.values.where((a) => a.id == actionId).firstOrNull;

    if (action != null) {
      _executeAction(action);
      return true;
    }

    return false;
  }

  /// 显示快捷键帮助
  static void showShortcutHelp(BuildContext context, {String? currentContext}) {
    showDialog(
      context: context,
      builder: (context) => _ShortcutHelpDialog(
        currentContext: currentContext,
      ),
    );
  }

  /// 处理键盘事件
  static bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final keys = HardwareKeyboard.instance.logicalKeysPressed;
      final keySet = LogicalKeySet.fromSet(keys);

      final keyString = _keySetToString(keySet);

      // 查找匹配的快捷键
      final action = _globalShortcuts[keyString];
      if (action != null) {
        _executeAction(action);
        return true;
      }
    }

    return false;
  }

  /// 执行快捷键动作
  static void _executeAction(ShortcutAction action) {
    // 防止重复触发
    final now = DateTime.now();
    if (_lastTriggeredAction?.id == action.id &&
        _lastTriggerTime != null &&
        now.difference(_lastTriggerTime!).inMilliseconds < 100) {
      return;
    }

    _lastTriggeredAction = action;
    _lastTriggerTime = now;

    try {
      action.onPressed?.call();
    } catch (e) {
      print('快捷键执行失败: ${action.id} - $e');
    }
  }

  /// 将LogicalKeySet转换为字符串
  static String _keySetToString(LogicalKeySet keySet) {
    final keys = keySet.keys.map((key) => key.keyLabel).join('+');
    return keys;
  }

  // 默认快捷键处理方法
  static void _handleSearchFunds() {
    // 实现搜索基金逻辑
  }

  static void _handleNavigateToHome() {
    // 实现导航到主页逻辑
  }

  static void _handleNavigateToPortfolio() {
    // 实现导航到投资组合逻辑
  }

  static void _handleRefresh() {
    // 实现刷新逻辑
  }

  static void _handleForceRefresh() {
    // 实现强制刷新逻辑
  }

  static void _handleToggleFullscreen() {
    // 实现全屏切换逻辑
  }

  static void _handleOpenSettings() {
    // 实现打开设置逻辑
  }

  static void _handleSelectAllFunds() {
    // 实现全选基金逻辑
  }

  static void _handleAddToComparison() {
    // 实现添加到对比逻辑
  }

  static void _handleAddToFavorites() {
    // 实现添加到收藏逻辑
  }

  static void _handleExportData() {
    // 实现导出数据逻辑
  }

  static void _handleToggleGridView() {
    // 实现切换网格视图逻辑
  }

  static void _handleToggleListView() {
    // 实现切换列表视图逻辑
  }

  static void _handleZoomIn() {
    // 实现放大逻辑
  }

  static void _handleZoomOut() {
    // 实现缩小逻辑
  }

  static void _handleRefreshFundDetail() {
    // 实现刷新基金详情逻辑
  }

  static void _handleBackToList() {
    // 实现返回列表逻辑
  }

  /// 清理资源
  static void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _shortcuts.clear();
    _globalShortcuts.clear();
    _registeredKeys.clear();
  }
}

/// 快捷键动作
class ShortcutAction {
  final String id;
  final String label;
  final String description;
  final ShortcutCategory category;
  final VoidCallback? onPressed;
  final bool isEnabled;

  const ShortcutAction({
    required this.id,
    required this.label,
    required this.description,
    required this.category,
    this.onPressed,
    this.isEnabled = true,
  });

  ShortcutAction copyWith({
    String? id,
    String? label,
    String? description,
    ShortcutCategory? category,
    VoidCallback? onPressed,
    bool? isEnabled,
  }) {
    return ShortcutAction(
      id: id ?? this.id,
      label: label ?? this.label,
      description: description ?? this.description,
      category: category ?? this.category,
      onPressed: onPressed ?? this.onPressed,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

/// 快捷键类别
enum ShortcutCategory {
  navigation('导航'),
  action('操作'),
  view('视图'),
  selection('选择'),
  edit('编辑'),
  window('窗口'),
  help('帮助');

  const ShortcutCategory(this.displayName);
  final String displayName;
}

/// 快捷键帮助对话框
class _ShortcutHelpDialog extends StatelessWidget {
  final String? currentContext;

  const _ShortcutHelpDialog({
    this.currentContext,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.keyboard, size: 24),
                const SizedBox(width: 12),
                Text(
                  '键盘快捷键',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (currentContext != null) ...[
              Text(
                '当前页面快捷键',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _buildShortcutList(context, currentContext!),
              const SizedBox(height: 16),
            ],
            Text(
              '全局快捷键',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildShortcutList(context, null),
            const SizedBox(height: 16),
            Text(
              '提示：按 F1 可随时显示此帮助',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcutList(BuildContext context, String? contextName) {
    final shortcuts = contextName != null
        ? KeyboardShortcuts.getContextShortcuts(contextName)
        : KeyboardShortcuts._globalShortcuts;

    final groupedShortcuts = <ShortcutCategory, List<ShortcutAction>>{};

    for (final action in shortcuts.values) {
      groupedShortcuts.putIfAbsent(action.category, () => []).add(action);
    }

    return Expanded(
      child: ListView.builder(
        itemCount: groupedShortcuts.keys.length,
        itemBuilder: (context, index) {
          final category = groupedShortcuts.keys.elementAt(index);
          final actions = groupedShortcuts[category]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category.displayName,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              ...actions.map((action) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 200,
                          child: Text(
                            action.label,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            action.description,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }
}

/// 快捷键提示组件
class ShortcutTooltip extends StatelessWidget {
  final String shortcut;
  final Widget child;

  const ShortcutTooltip({
    super.key,
    required this.shortcut,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: shortcut,
      child: child,
    );
  }
}

/// 快捷键指示器组件
class ShortcutIndicator extends StatelessWidget {
  final String shortcut;
  final bool isActive;

  const ShortcutIndicator({
    super.key,
    required this.shortcut,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isActive
              ? Theme.of(context).primaryColor.withOpacity(0.3)
              : Colors.grey[300]!,
        ),
      ),
      child: Text(
        shortcut,
        style: TextStyle(
          fontSize: 10,
          color: isActive ? Theme.of(context).primaryColor : Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
