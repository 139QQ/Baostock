import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import '../../features/fund/domain/entities/fund.dart';

/// 右键菜单系统
/// 提供智能上下文感知的右键菜单功能
class ContextMenuSystem {
  static OverlayEntry? _currentMenu;
  static final Map<String, List<ContextMenuAction>> _contextMenus = {};

  /// 注册上下文菜单
  static void registerContextMenu(
      String context, List<ContextMenuAction> actions) {
    _contextMenus[context] = actions;
  }

  /// 显示右键菜单
  static void showContextMenu(
    BuildContext context,
    Offset position, {
    String contextType = 'default',
    Map<String, dynamic>? data,
    List<ContextMenuAction>? additionalActions,
  }) {
    // 关闭现有菜单
    hideContextMenu();

    final actions = <ContextMenuAction>[];

    // 添加上下文特定菜单项
    if (_contextMenus.containsKey(contextType)) {
      actions.addAll(_contextMenus[contextType]!);
    }

    // 添加额外菜单项
    if (additionalActions != null) {
      actions.addAll(additionalActions);
    }

    // 如果没有菜单项，不显示菜单
    if (actions.isEmpty) return;

    // 根据上下文数据过滤和启用/禁用菜单项
    final filteredActions = actions
        .map((action) {
          final bool enabled = action.isEnabled?.call(data) ?? true;
          return action.copyWith(enabled: enabled);
        })
        .where((action) => action.isVisible?.call(data) ?? true)
        .toList();

    if (filteredActions.isEmpty) return;

    // 创建菜单
    _currentMenu = OverlayEntry(
      builder: (context) => _ContextMenuOverlay(
        position: position,
        actions: filteredActions,
        data: data,
        onDismiss: hideContextMenu,
      ),
    );

    Overlay.of(context).insert(_currentMenu!);
  }

  /// 隐藏右键菜单
  static void hideContextMenu() {
    _currentMenu?.remove();
    _currentMenu = null;
  }

  /// 检查菜单是否正在显示
  static bool isMenuShowing() => _currentMenu != null;
}

/// 右键菜单动作
class ContextMenuAction {
  final String? label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final String? shortcut;
  final bool Function(Map<String, dynamic>? data)? isEnabled;
  final bool Function(Map<String, dynamic>? data)? isVisible;
  final List<ContextMenuAction>? subActions;
  final bool isSeparator;
  final String? tooltip;

  const ContextMenuAction({
    this.label,
    this.icon,
    this.onPressed,
    this.shortcut,
    this.isEnabled,
    this.isVisible,
    this.subActions,
    this.isSeparator = false,
    this.tooltip,
  }) : assert(isSeparator ? label == null : label != null,
            'label is required when isSeparator is false');

  ContextMenuAction copyWith({
    String? label,
    IconData? icon,
    VoidCallback? onPressed,
    String? shortcut,
    bool Function(Map<String, dynamic>? data)? isEnabled,
    bool Function(Map<String, dynamic>? data)? isVisible,
    List<ContextMenuAction>? subActions,
    bool? isSeparator,
    String? tooltip,
    bool? enabled,
  }) {
    return ContextMenuAction(
      label: label ?? this.label,
      icon: icon ?? this.icon,
      onPressed: onPressed ?? this.onPressed,
      shortcut: shortcut ?? this.shortcut,
      isEnabled: enabled != null ? (_) => enabled : isEnabled,
      isVisible: isVisible,
      subActions: subActions ?? this.subActions,
      isSeparator: isSeparator ?? this.isSeparator,
      tooltip: tooltip ?? this.tooltip,
    );
  }
}

/// 右键菜单覆盖层
class _ContextMenuOverlay extends StatefulWidget {
  final Offset position;
  final List<ContextMenuAction> actions;
  final Map<String, dynamic>? data;
  final VoidCallback onDismiss;

  const _ContextMenuOverlay({
    required this.position,
    required this.actions,
    this.data,
    required this.onDismiss,
  });

  @override
  State<_ContextMenuOverlay> createState() => _ContextMenuOverlayState();
}

class _ContextMenuOverlayState extends State<_ContextMenuOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();

    // 监听全局点击事件来关闭菜单
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GestureBinding.instance.pointerRouter
          .addGlobalRoute(_handleGlobalPointerEvent);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    GestureBinding.instance.pointerRouter
        .removeGlobalRoute(_handleGlobalPointerEvent);
    super.dispose();
  }

  void _handleGlobalPointerEvent(PointerEvent event) {
    if (event is PointerDownEvent) {
      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final localPosition = renderBox.globalToLocal(event.position);
        final size = renderBox.size;
        final rect = Offset.zero & size;

        // 如果点击在菜单外部，关闭菜单
        if (!rect.contains(localPosition)) {
          widget.onDismiss();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: widget.onDismiss,
        child: AnimatedBuilder(
          animation: Listenable.merge([_scaleAnimation, _fadeAnimation]),
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                alignment: Alignment.topLeft,
                child: _ContextMenuWidget(
                  position: widget.position,
                  actions: widget.actions,
                  data: widget.data,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 右键菜单Widget
class _ContextMenuWidget extends StatelessWidget {
  final Offset position;
  final List<ContextMenuAction> actions;
  final Map<String, dynamic>? data;

  const _ContextMenuWidget({
    required this.position,
    required this.actions,
    this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 250,
          maxHeight: MediaQuery.of(context).size.height - position.dy - 10,
        ),
        child: Card(
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _buildMenuItems(),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMenuItems() {
    final items = <Widget>[];

    for (int i = 0; i < actions.length; i++) {
      final action = actions[i];

      if (action.isSeparator) {
        if (items.isNotEmpty) {
          items.add(Divider(height: 1, color: Colors.grey[300]));
        }
      } else {
        final bool enabled = action.isEnabled?.call(data) ?? true;

        items.add(
          _ContextMenuItem(
            label: action.label ?? '',
            icon: action.icon,
            shortcut: action.shortcut,
            tooltip: action.tooltip,
            enabled: enabled,
            onPressed: enabled ? action.onPressed : null,
            subActions: action.subActions,
            data: data,
          ),
        );

        // 添加分隔符（除了最后一个项目）
        if (i < actions.length - 1 && !actions[i + 1].isSeparator) {
          items.add(Divider(height: 1, color: Colors.grey[300]));
        }
      }
    }

    return items;
  }
}

/// 右键菜单项Widget
class _ContextMenuItem extends StatefulWidget {
  final String label;
  final IconData? icon;
  final String? shortcut;
  final String? tooltip;
  final bool enabled;
  final VoidCallback? onPressed;
  final List<ContextMenuAction>? subActions;
  final Map<String, dynamic>? data;

  const _ContextMenuItem({
    required this.label,
    this.icon,
    this.shortcut,
    this.tooltip,
    this.enabled = true,
    this.onPressed,
    this.subActions,
    this.data,
  });

  @override
  State<_ContextMenuItem> createState() => _ContextMenuItemState();
}

class _ContextMenuItemState extends State<_ContextMenuItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation;

  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: Theme.of(context).primaryColor.withOpacity(0.1),
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onHoverChanged(bool isHovering) {
    setState(() {
      _isHovering = isHovering;
    });
    if (isHovering) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return Material(
          color: _isHovering ? _colorAnimation.value : Colors.transparent,
          child: InkWell(
            onTap: widget.enabled ? widget.onPressed : null,
            child: MouseRegion(
              onEnter: (_) => _onHoverChanged(true),
              onExit: (_) => _onHoverChanged(false),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        size: 16,
                        color: widget.enabled
                            ? (_isHovering
                                ? Theme.of(context).primaryColor
                                : Colors.grey[700])
                            : Colors.grey[400],
                      ),
                      const SizedBox(width: 12),
                    ] else
                      const SizedBox(width: 28),
                    Expanded(
                      child: Text(
                        widget.label,
                        style: TextStyle(
                          color: widget.enabled
                              ? Colors.black87
                              : Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (widget.shortcut != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        widget.shortcut!,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (widget.subActions != null &&
                        widget.subActions!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 基金专用上下文菜单
class FundContextMenu {
  static void initialize() {
    // 注册基金卡片上下文菜单
    ContextMenuSystem.registerContextMenu('fund_card', [
      ContextMenuAction(
        label: '查看详情',
        icon: Icons.info_outline,
        shortcut: 'Enter',
        onPressed: () => _handleViewDetails(),
      ),
      ContextMenuAction(
        label: '加入对比',
        icon: Icons.compare_arrows,
        shortcut: 'C',
        onPressed: () => _handleAddToComparison(),
      ),
      ContextMenuAction(
        label: '添加收藏',
        icon: Icons.favorite_border,
        shortcut: 'F',
        onPressed: () => _handleAddToFavorites(),
        isEnabled: (data) => !(data?['isFavorite'] ?? false),
      ),
      ContextMenuAction(
        label: '取消收藏',
        icon: Icons.favorite,
        shortcut: 'F',
        onPressed: () => _handleRemoveFromFavorites(),
        isEnabled: (data) => data?['isFavorite'] ?? false,
      ),
      const ContextMenuAction(isSeparator: true),
      ContextMenuAction(
        label: '复制基金代码',
        icon: Icons.copy,
        shortcut: 'Ctrl+C',
        onPressed: () => _handleCopyFundCode(),
      ),
      ContextMenuAction(
        label: '复制基金名称',
        icon: Icons.copy,
        shortcut: 'Ctrl+Shift+C',
        onPressed: () => _handleCopyFundName(),
      ),
      const ContextMenuAction(isSeparator: true),
      ContextMenuAction(
        label: '分享基金',
        icon: Icons.share,
        shortcut: 'Ctrl+S',
        onPressed: () => _handleShareFund(),
      ),
      ContextMenuAction(
        label: '设置为自选',
        icon: Icons.star_outline,
        onPressed: () => _handleSetAsDefault(),
        isVisible: (data) => !(data?['isDefault'] ?? false),
      ),
    ]);
  }

  static void _handleViewDetails() {
    // 实现查看详情逻辑
  }

  static void _handleAddToComparison() {
    // 实现添加到对比逻辑
  }

  static void _handleAddToFavorites() {
    // 实现添加收藏逻辑
  }

  static void _handleRemoveFromFavorites() {
    // 实现取消收藏逻辑
  }

  static void _handleCopyFundCode() {
    // 实现复制基金代码逻辑
  }

  static void _handleCopyFundName() {
    // 实现复制基金名称逻辑
  }

  static void _handleShareFund() {
    // 实现分享基金逻辑
  }

  static void _handleSetAsDefault() {
    // 实现设置为自选逻辑
  }
}

/// 智能右键菜单管理器
class SmartContextMenuManager {
  static void showFundContextMenu(
    BuildContext context,
    Offset position,
    Fund fund, {
    bool isFavorite = false,
    bool isDefault = false,
    VoidCallback? onViewDetails,
    VoidCallback? onAddToComparison,
    VoidCallback? onAddToFavorites,
    VoidCallback? onRemoveFromFavorites,
    VoidCallback? onShare,
  }) {
    final additionalActions = [
      ContextMenuAction(
        label: '查看详情',
        icon: Icons.info_outline,
        shortcut: 'Enter',
        onPressed: onViewDetails,
      ),
      ContextMenuAction(
        label: '加入对比',
        icon: Icons.compare_arrows,
        shortcut: 'C',
        onPressed: onAddToComparison,
      ),
      if (!isFavorite)
        ContextMenuAction(
          label: '添加收藏',
          icon: Icons.favorite_border,
          shortcut: 'F',
          onPressed: onAddToFavorites,
        )
      else
        ContextMenuAction(
          label: '取消收藏',
          icon: Icons.favorite,
          shortcut: 'F',
          onPressed: onRemoveFromFavorites,
        ),
      const ContextMenuAction(isSeparator: true),
      ContextMenuAction(
        label: '复制基金代码',
        icon: Icons.copy,
        shortcut: 'Ctrl+C',
        onPressed: () {
          Clipboard.setData(ClipboardData(text: fund.code));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('基金代码已复制: ${fund.code}')),
          );
        },
      ),
      ContextMenuAction(
        label: '复制基金名称',
        icon: Icons.copy,
        shortcut: 'Ctrl+Shift+C',
        onPressed: () {
          Clipboard.setData(ClipboardData(text: fund.name));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('基金名称已复制: ${fund.name}')),
          );
        },
      ),
      const ContextMenuAction(isSeparator: true),
      ContextMenuAction(
        label: '分享基金',
        icon: Icons.share,
        shortcut: 'Ctrl+S',
        onPressed: onShare,
      ),
      if (!isDefault)
        ContextMenuAction(
          label: '设置为自选',
          icon: Icons.star_outline,
          onPressed: () {
            // 实现设置为自选逻辑
          },
        ),
    ];

    ContextMenuSystem.showContextMenu(
      context,
      position,
      contextType: 'fund_card',
      data: {
        'fund': fund,
        'isFavorite': isFavorite,
        'isDefault': isDefault,
      },
      additionalActions: additionalActions,
    );
  }
}
