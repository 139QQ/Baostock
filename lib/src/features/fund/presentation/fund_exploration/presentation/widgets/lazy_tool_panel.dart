import 'package:flutter/material.dart';

/// 懒加载工具面板
///
/// 实现工具组件的按需加载，提升性能
class LazyToolPanel extends StatefulWidget {
  /// 面板ID
  final String panelId;

  /// 面板标题
  final String title;

  /// 面板图标
  final IconData icon;

  /// 是否展开
  final bool isExpanded;

  /// 展开状态变化回调
  final Function(bool isExpanded) onExpansionChanged;

  /// 构建器函数，仅在需要时调用
  final Widget Function() builder;

  /// 占位符组件
  final Widget? placeholder;

  /// 加载指示器
  final Widget? loadingIndicator;

  /// 是否启用懒加载
  final bool enableLazyLoading;

  /// 预加载延迟（毫秒）
  final int preloadDelay;

  const LazyToolPanel({
    super.key,
    required this.panelId,
    required this.title,
    required this.icon,
    required this.isExpanded,
    required this.onExpansionChanged,
    required this.builder,
    this.placeholder,
    this.loadingIndicator,
    this.enableLazyLoading = true,
    this.preloadDelay = 100,
  });

  @override
  State<LazyToolPanel> createState() => _LazyToolPanelState();
}

class _LazyToolPanelState extends State<LazyToolPanel>
    with AutomaticKeepAliveClientMixin {
  bool _isLoaded = false;
  bool _isLoading = false;
  Widget? _cachedWidget;

  @override
  bool get wantKeepAlive => _isLoaded && widget.isExpanded;

  @override
  void initState() {
    super.initState();

    // 如果初始状态是展开的，预加载组件
    if (widget.isExpanded && !widget.enableLazyLoading) {
      _loadWidget();
    }
  }

  @override
  void didUpdateWidget(LazyToolPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 当面板从折叠变为展开时，加载组件
    if (!oldWidget.isExpanded && widget.isExpanded && !_isLoaded) {
      _loadWidget();
    }
  }

  /// 加载组件
  Future<void> _loadWidget() async {
    if (_isLoaded || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 模拟加载延迟
      if (widget.enableLazyLoading) {
        await Future.delayed(Duration(milliseconds: widget.preloadDelay));
      }

      // 构建组件
      final builtWidget = widget.builder();

      setState(() {
        _cachedWidget = builtWidget;
        _isLoaded = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // 显示错误状态
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载工具面板失败: $e')),
        );
      }
    }
  }

  /// 预加载组件
  void preload() {
    if (!_isLoaded && !_isLoading) {
      _loadWidget();
    }
  }

  /// 卸载组件以释放内存
  void unload() {
    if (_isLoaded && !widget.isExpanded) {
      setState(() {
        _isLoaded = false;
        _cachedWidget = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          key: ValueKey(widget.panelId),
          initiallyExpanded: widget.isExpanded,
          onExpansionChanged: (expanded) {
            widget.onExpansionChanged(expanded);

            // 展开时加载组件
            if (expanded && !_isLoaded) {
              _loadWidget();
            }

            // 折叠时考虑卸载组件（可选）
            if (!expanded && _isLoaded) {
              // 可以选择是否卸载以节省内存
              // unload();
            }
          },
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              widget.icon,
              color: const Color(0xFF1E40AF),
              size: 20,
            ),
          ),
          title: Text(
            widget.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          trailing: AnimatedRotation(
            turns: widget.isExpanded ? 0.5 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: const Icon(
              Icons.expand_more,
              color: Color(0xFF6B7280),
            ),
          ),
          childrenPadding: const EdgeInsets.all(16),
          expandedAlignment: Alignment.topCenter,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // 内容区域
            _buildContent(),
          ],
        ),
      ),
    );
  }

  /// 构建内容区域
  Widget _buildContent() {
    if (_isLoading) {
      return widget.loadingIndicator ?? _buildDefaultLoadingIndicator();
    }

    if (_isLoaded && _cachedWidget != null) {
      return _cachedWidget!;
    }

    return widget.placeholder ?? _buildDefaultPlaceholder();
  }

  /// 构建默认加载指示器
  Widget _buildDefaultLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: const Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            '正在加载...',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建默认占位符
  Widget _buildDefaultPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.hourglass_empty,
            color: Colors.grey[400],
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            '点击展开${widget.title}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '按需加载以提升性能',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// 智能工具面板管理器
class SmartToolPanelManager {
  static final Map<String, DateTime> _lastAccessTime = {};
  static final Map<String, bool> _preloadCache = {};
  static const Duration _preloadThreshold = Duration(minutes: 5);

  /// 记录面板访问时间
  static void recordAccess(String panelId) {
    _lastAccessTime[panelId] = DateTime.now();
  }

  /// 检查是否应该预加载面板
  static bool shouldPreload(String panelId) {
    final lastTime = _lastAccessTime[panelId];
    if (lastTime == null) return false;

    final timeSinceLastAccess = DateTime.now().difference(lastTime);
    return timeSinceLastAccess < _preloadThreshold;
  }

  /// 设置预加载缓存
  static void setPreloadCache(String panelId, bool shouldCache) {
    _preloadCache[panelId] = shouldCache;
  }

  /// 检查预加载缓存
  static bool getPreloadCache(String panelId) {
    return _preloadCache[panelId] ?? false;
  }

  /// 清理过期缓存
  static void cleanupExpiredCache() {
    final now = DateTime.now();
    _lastAccessTime.removeWhere((panelId, lastTime) {
      return now.difference(lastTime) > _preloadThreshold;
    });
  }

  /// 获取访问统计
  static Map<String, DateTime> getAccessStats() {
    return Map.from(_lastAccessTime);
  }

  /// 重置所有缓存
  static void resetAllCache() {
    _lastAccessTime.clear();
    _preloadCache.clear();
  }
}

/// 性能优化的工具面板容器
class OptimizedToolPanelContainer extends StatefulWidget {
  final Widget child;

  const OptimizedToolPanelContainer({
    super.key,
    required this.child,
  });

  @override
  State<OptimizedToolPanelContainer> createState() =>
      _OptimizedToolPanelContainerState();
}

class _OptimizedToolPanelContainerState
    extends State<OptimizedToolPanelContainer>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // 使用 RepaintBoundary 减少重绘范围
    return RepaintBoundary(
      child: widget.child,
    );
  }
}
