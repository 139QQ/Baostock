import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/state/tool_panel/tool_panel_cubit.dart';
import '../../domain/models/fund_filter.dart';
import 'fund_filter_panel.dart';
import 'fund_comparison_tool.dart';
import 'investment_calculator.dart';
import 'lazy_tool_panel.dart';

/// 可折叠工具面板容器组件
///
/// 集成基金筛选、对比、计算等工具到统一的折叠面板中
/// 支持面板状态记忆、个性化定制和响应式布局
class ToolPanelContainer extends StatefulWidget {
  /// 是否显示折叠面板标题栏
  final bool showHeader;

  /// 初始展开状态（可选）
  final Map<String, bool>? initialExpandedState;

  /// 自定义面板配置
  final ToolPanelConfig? config;

  /// 面板状态变化回调
  final Function(String panelId, bool isExpanded)? onPanelStateChanged;

  const ToolPanelContainer({
    super.key,
    this.showHeader = true,
    this.initialExpandedState,
    this.config,
    this.onPanelStateChanged,
  });

  @override
  State<ToolPanelContainer> createState() => _ToolPanelContainerState();
}

class _ToolPanelContainerState extends State<ToolPanelContainer>
    with TickerProviderStateMixin {
  late ToolPanelCubit _toolPanelCubit;
  late AnimationController _headerAnimationController;
  late Animation<double> _headerAnimation;

  @override
  void initState() {
    super.initState();
    // 尝试从context获取ToolPanelCubit，如果没有则创建新实例
    try {
      _toolPanelCubit = context.read<ToolPanelCubit>();
    } catch (e) {
      _toolPanelCubit = ToolPanelCubit();
    }
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _headerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeInOut,
    ));

    // 延迟初始化面板状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePanelStates();
    });

    _headerAnimationController.forward();
  }

  /// 初始化面板状态
  Future<void> _initializePanelStates() async {
    await _toolPanelCubit.loadPanelStates();

    // 如果有初始状态，应用它
    if (widget.initialExpandedState != null) {
      _toolPanelCubit.updateMultiplePanelStates(widget.initialExpandedState!);
    }
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();

    // 只有在我们自己创建了ToolPanelCubit实例时才关闭它
    try {
      context.read<ToolPanelCubit>();
      // 如果能成功读取，说明这个Cubit是由外部提供的，不需要关闭
    } catch (e) {
      // 如果读取失败，说明是我们自己创建的实例，需要关闭
      _toolPanelCubit.close();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config ?? ToolPanelConfig.defaultConfig;

    return Card(
      elevation: config.elevation,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(config.borderRadius),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题栏
          if (widget.showHeader) ...[
            _buildHeader(config),
            const SizedBox(height: 8),
          ],

          // 工具面板内容
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight:
                    MediaQuery.of(context).size.height * 0.5, // 进一步减少高度限制
                minHeight: 150,
              ),
              child: _buildToolPanels(config),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建标题栏
  Widget _buildHeader(ToolPanelConfig config) {
    return FadeTransition(
      opacity: _headerAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: config.headerGradient,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(config.borderRadius),
            topRight: Radius.circular(config.borderRadius),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.build_circle_outlined,
              color: config.headerIconColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                config.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: config.headerTextColor,
                ),
              ),
            ),

            // 快捷操作按钮
            _buildQuickActions(config),
          ],
        ),
      ),
    );
  }

  /// 构建快捷操作按钮
  Widget _buildQuickActions(ToolPanelConfig config) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 展开全部按钮
        IconButton(
          onPressed: () => _expandAllPanels(),
          icon: Icon(
            Icons.unfold_more,
            color: config.headerIconColor,
            size: 20,
          ),
          tooltip: '展开全部',
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          padding: EdgeInsets.zero,
        ),

        // 折叠全部按钮
        IconButton(
          onPressed: () => _collapseAllPanels(),
          icon: Icon(
            Icons.unfold_less,
            color: config.headerIconColor,
            size: 20,
          ),
          tooltip: '折叠全部',
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          padding: EdgeInsets.zero,
        ),

        // 设置按钮
        if (config.showSettingsButton)
          IconButton(
            onPressed: () => _showSettingsDialog(),
            icon: Icon(
              Icons.settings_outlined,
              color: config.headerIconColor,
              size: 20,
            ),
            tooltip: '面板设置',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
      ],
    );
  }

  /// 构建工具面板
  Widget _buildToolPanels(ToolPanelConfig config) {
    return BlocBuilder<ToolPanelCubit, ToolPanelState>(
      builder: (context, state) {
        return OptimizedToolPanelContainer(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight:
                  MediaQuery.of(context).size.height * 0.6, // 减少最大高度限制，防止溢出
              minHeight: 200, // 设置最小高度
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min, // 使用最小尺寸
                crossAxisAlignment: CrossAxisAlignment.start, // 避免居中对齐可能造成的溢出
                children: [
                  // 筛选器面板
                  if (config.showFilterPanel)
                    _buildLazyExpansionPanel(
                      id: 'filter',
                      title: '基金筛选',
                      icon: Icons.filter_list,
                      builder: () => FundFilterPanel(
                        filters: FundFilter(),
                        onFiltersChanged: (filter) {},
                      ),
                      isExpanded: state.isPanelExpanded('filter'),
                      config: config,
                    ),

                  // 对比工具面板
                  if (config.showComparisonPanel)
                    _buildLazyExpansionPanel(
                      id: 'comparison',
                      title: '基金对比',
                      icon: Icons.compare_arrows,
                      builder: () => const FundComparisonTool(),
                      isExpanded: state.isPanelExpanded('comparison'),
                      config: config,
                    ),

                  // 计算器面板
                  if (config.showCalculatorPanel)
                    _buildLazyExpansionPanel(
                      id: 'calculator',
                      title: '投资计算器',
                      icon: Icons.calculate,
                      builder: () => const InvestmentCalculator(),
                      isExpanded: state.isPanelExpanded('calculator'),
                      config: config,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建懒加载折叠面板
  Widget _buildLazyExpansionPanel({
    required String id,
    required String title,
    required IconData icon,
    required Widget Function() builder,
    required bool isExpanded,
    required ToolPanelConfig config,
  }) {
    return LazyToolPanel(
      panelId: id,
      title: title,
      icon: icon,
      isExpanded: isExpanded,
      onExpansionChanged: (expanded) {
        _toolPanelCubit.setPanelExpanded(id, expanded);
        widget.onPanelStateChanged?.call(id, expanded);

        // 记录访问时间用于智能预加载
        SmartToolPanelManager.recordAccess(id);
      },
      builder: builder,
      enableLazyLoading: config.enableLazyLoading,
      preloadDelay: config.preloadDelay,
      placeholder: _buildCustomPlaceholder(title, icon),
      loadingIndicator: _buildCustomLoadingIndicator(),
    );
  }

  /// 展开所有面板
  void _expandAllPanels() {
    _toolPanelCubit.expandAllPanels();
  }

  /// 折叠所有面板
  void _collapseAllPanels() {
    _toolPanelCubit.collapseAllPanels();
  }

  /// 显示设置对话框
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('工具面板设置'),
        content: _buildSettingsContent(),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('设置已保存')),
              );
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// 构建自定义占位符
  Widget _buildCustomPlaceholder(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.grey[400],
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            '点击展开$title',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '智能加载以提升性能',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建自定义加载指示器
  Widget _buildCustomLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(0xFF1E40AF),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '正在加载...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建设置内容
  Widget _buildSettingsContent() {
    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: const Text('显示筛选器'),
              value: true, // 从状态中获取
              onChanged: (value) {
                setState(() {});
                // 更新配置
              },
            ),
            CheckboxListTile(
              title: const Text('显示对比工具'),
              value: true, // 从状态中获取
              onChanged: (value) {
                setState(() {});
                // 更新配置
              },
            ),
            CheckboxListTile(
              title: const Text('显示计算器'),
              value: true, // 从状态中获取
              onChanged: (value) {
                setState(() {});
                // 更新配置
              },
            ),
          ],
        );
      },
    );
  }
}

/// 工具面板配置类
class ToolPanelConfig {
  /// 标题
  final String title;

  /// 阴影强度
  final double elevation;

  /// 边框圆角
  final double borderRadius;

  /// 头部渐变色
  final Gradient? headerGradient;

  /// 头部图标颜色
  final Color headerIconColor;

  /// 头部文字颜色
  final Color headerTextColor;

  /// 面板背景色
  final Color panelBackgroundColor;

  /// 面板边框颜色
  final Color panelBorderColor;

  /// 面板边框圆角
  final double panelBorderRadius;

  /// 图标背景色
  final Color iconBackgroundColor;

  /// 图标颜色
  final Color iconColor;

  /// 标题颜色
  final Color titleColor;

  /// 尾部图标颜色
  final Color trailingIconColor;

  /// 操作按钮颜色
  final Color actionButtonColor;

  /// 主要操作按钮颜色
  final Color primaryActionButtonColor;

  /// 是否显示设置按钮
  final bool showSettingsButton;

  /// 是否显示面板操作栏
  final bool showPanelActions;

  /// 是否显示筛选器面板
  final bool showFilterPanel;

  /// 是否显示对比面板
  final bool showComparisonPanel;

  /// 是否显示计算器面板
  final bool showCalculatorPanel;

  /// 是否启用懒加载
  final bool enableLazyLoading;

  /// 预加载延迟（毫秒）
  final int preloadDelay;

  const ToolPanelConfig({
    required this.title,
    this.elevation = 4.0,
    this.borderRadius = 12.0,
    this.headerGradient,
    this.headerIconColor = const Color(0xFF1E40AF),
    this.headerTextColor = Colors.white,
    this.panelBackgroundColor = Colors.white,
    this.panelBorderColor = const Color(0xFFE5E7EB),
    this.panelBorderRadius = 8.0,
    this.iconBackgroundColor = const Color(0xFFEFF6FF),
    this.iconColor = const Color(0xFF1E40AF),
    this.titleColor = const Color(0xFF1F2937),
    this.trailingIconColor = const Color(0xFF6B7280),
    this.actionButtonColor = const Color(0xFF6B7280),
    this.primaryActionButtonColor = const Color(0xFF1E40AF),
    this.showSettingsButton = true,
    this.showPanelActions = true,
    this.showFilterPanel = true,
    this.showComparisonPanel = true,
    this.showCalculatorPanel = true,
    this.enableLazyLoading = true,
    this.preloadDelay = 100,
  });

  /// 默认配置
  static const ToolPanelConfig defaultConfig = ToolPanelConfig(
    title: '投资工具箱',
    headerGradient: LinearGradient(
      colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    enableLazyLoading: true,
    preloadDelay: 100,
  );

  /// 紧凑配置（用于小屏幕）
  static const ToolPanelConfig compactConfig = ToolPanelConfig(
    title: '工具',
    elevation: 2.0,
    borderRadius: 8.0,
    headerTextColor: Color(0xFF1F2937),
    showSettingsButton: false,
    showPanelActions: false,
    enableLazyLoading: true,
    preloadDelay: 50,
  );

  /// 高性能配置（用于低端设备）
  static const ToolPanelConfig performanceConfig = ToolPanelConfig(
    title: '工具',
    elevation: 1.0,
    borderRadius: 6.0,
    headerTextColor: Color(0xFF1F2937),
    showSettingsButton: false,
    showPanelActions: false,
    enableLazyLoading: true,
    preloadDelay: 200,
  );
}
