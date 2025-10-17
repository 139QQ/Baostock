import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../domain/data/services/fund_service.dart';

import '../widgets/fund_search_bar.dart';
import '../widgets/fund_filter_panel.dart';
import '../widgets/hot_funds_section.dart';
import '../widgets/fund_ranking_wrapper_simple.dart';
import '../widgets/market_dynamics_section.dart';
import '../widgets/fund_comparison_tool.dart';
import '../widgets/investment_calculator.dart';
import '../widgets/fund_card.dart';
import '../../domain/models/fund.dart';
import '../../domain/models/fund_filter.dart';
import '../cubit/fund_exploration_cubit.dart';

/// 窗口大小变化观察者
class _WindowSizeObserver extends WidgetsBindingObserver {
  final VoidCallback? onSizeChanged;

  _WindowSizeObserver({this.onSizeChanged});

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    onSizeChanged?.call();
  }
}

/// 基金探索页面 - 用户发现和筛选基金的核心界面
///
/// 主要功能：
/// - 基金搜索和高级筛选
/// - 热门基金推荐展示
/// - 基金排行榜查看
/// - 市场动态信息
/// - 基金对比分析工具
/// - 定投收益计算器
class FundExplorationPage extends StatelessWidget {
  const FundExplorationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        try {
          return GetIt.instance.get<FundExplorationCubit>();
        } catch (e) {
          // 如果获取失败，创建新的实例
          return FundExplorationCubit(
            fundService: FundService(),
          );
        }
      },
      child: const _FundExplorationPageContent(),
    );
  }
}

class _FundExplorationPageContent extends StatefulWidget {
  const _FundExplorationPageContent();

  @override
  State<_FundExplorationPageContent> createState() =>
      _FundExplorationPageContentState();
}

class _FundExplorationPageContentState
    extends State<_FundExplorationPageContent> {
  // 搜索控制器
  final TextEditingController _searchController = TextEditingController();

  // 筛选条件
  final FundFilter _currentFilter = const FundFilter();
  bool _showFilterPanel = false;

  // 视图模式
  bool _isGridView = true;

  // 对比模式
  bool _comparisonMode = false;
  final Set<String> _selectedFunds = {};

  // 窗口大小监听
  VoidCallback? _windowSizeChangeCallback;

  @override
  void initState() {
    super.initState();
    // 延迟初始化，确保Bloc已经创建
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<FundExplorationCubit>().initialize();
      }
    });

    // 监听窗口大小变化
    _windowSizeChangeCallback = () {
      if (mounted) {
        setState(() {}); // 重新构建以响应窗口大小变化
      }
    };

    WidgetsBinding.instance.addObserver(_buildObserver());
  }

  @override
  void dispose() {
    _searchController.dispose();
    WidgetsBinding.instance.removeObserver(_buildObserver());
    super.dispose();
  }

  // 创建窗口大小变化监听器
  _WindowSizeObserver _buildObserver() {
    return _WindowSizeObserver(
      onSizeChanged: _windowSizeChangeCallback,
    );
  }

  /// 处理搜索
  void _handleSearch(String query) {
    context.read<FundExplorationCubit>().searchFunds(query);
  }

  /// 处理筛选条件变化
  void _handleFilterChanged(FundFilter filter) {
    setState(() {
      _showFilterPanel = false;
    });

    context.read<FundExplorationCubit>().applyFilters(filter);
  }

  /// 切换对比模式
  void _toggleComparisonMode() {
    setState(() {
      _comparisonMode = !_comparisonMode;
      if (!_comparisonMode) {
        _selectedFunds.clear();
        context.read<FundExplorationCubit>().clearComparison();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            // 顶部搜索和筛选区域 - 独立监听状态
            BlocBuilder<FundExplorationCubit, FundExplorationState>(
              builder: (context, state) => _buildTopSection(state),
            ),

            // 对比模式工具栏 - 独立监听对比状态
            BlocBuilder<FundExplorationCubit, FundExplorationState>(
              buildWhen: (previous, current) {
                return previous.comparisonFunds != current.comparisonFunds;
              },
              builder: (context, state) {
                if (_comparisonMode && state.comparisonFunds.isNotEmpty) {
                  return _buildComparisonToolbar(state);
                }
                return const SizedBox.shrink();
              },
            ),

            // 主要内容区域 - 优化状态监听
            Expanded(
              child: BlocBuilder<FundExplorationCubit, FundExplorationState>(
                buildWhen: (previous, current) {
                  // 只在关键状态变化时重建
                  return previous.isLoading != current.isLoading ||
                      previous.errorMessage != current.errorMessage ||
                      previous.activeView != current.activeView;
                },
                builder: (context, state) {
                  if (state.isLoading && state.funds.isEmpty) {
                    return _buildLoadingWidget();
                  }
                  if (state.errorMessage != null && state.funds.isEmpty) {
                    return _buildErrorWidget(state.errorMessage!);
                  }
                  return _buildContentSection(state);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建顶部区域
  Widget _buildTopSection(FundExplorationState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 响应式搜索栏布局
          if (constraints.maxWidth < 600) {
            return _buildCompactTopSection(state);
          } else if (constraints.maxWidth < 900) {
            return _buildMediumTopSection(state);
          } else {
            return _buildFullTopSection(state);
          }
        },
      ),
    );
  }

  /// 完整顶部区域（桌面端）
  Widget _buildFullTopSection(FundExplorationState state) {
    return Column(
      children: [
        // 搜索栏和主要控制
        Row(
          children: [
            // 搜索栏
            Expanded(
              flex: 2,
              child: FundSearchBar(
                controller: _searchController,
                onSearch: _handleSearch,
                onAdvancedFilter: () {
                  setState(() {
                    _showFilterPanel = !_showFilterPanel;
                  });
                },
              ),
            ),

            const SizedBox(width: 16),

            // 排序选择器
            _buildSortSelector(state),

            const SizedBox(width: 16),

            // 视图模式切换
            _buildViewModeToggle(),

            const SizedBox(width: 16),

            // 对比模式切换
            _buildComparisonToggle(),
          ],
        ),

        // 筛选面板
        if (_showFilterPanel) ...[
          const SizedBox(height: 16),
          FundFilterPanel(
            filters: _currentFilter,
            onFiltersChanged: _handleFilterChanged,
          ),
        ],
      ],
    );
  }

  /// 中等顶部区域（平板端）
  Widget _buildMediumTopSection(FundExplorationState state) {
    return Column(
      children: [
        // 第一行：搜索栏
        Row(
          children: [
            // 搜索栏
            Expanded(
              child: FundSearchBar(
                controller: _searchController,
                onSearch: _handleSearch,
                onAdvancedFilter: () {
                  setState(() {
                    _showFilterPanel = !_showFilterPanel;
                  });
                },
              ),
            ),

            const SizedBox(width: 12),

            // 筛选按钮
            IconButton(
              onPressed: () {
                setState(() {
                  _showFilterPanel = !_showFilterPanel;
                });
              },
              icon: Icon(
                _showFilterPanel ? Icons.filter_list_off : Icons.filter_list,
                color: _showFilterPanel ? const Color(0xFF1E40AF) : Colors.grey,
              ),
              tooltip: '筛选',
            ),
          ],
        ),

        const SizedBox(height: 12),

        // 第二行：控制按钮
        Row(
          children: [
            // 排序选择器
            Expanded(
              flex: 1,
              child: _buildSortSelector(state),
            ),

            const SizedBox(width: 12),

            // 视图模式切换
            _buildViewModeToggle(),

            const SizedBox(width: 12),

            // 对比模式切换
            _buildComparisonToggle(),
          ],
        ),

        // 筛选面板
        if (_showFilterPanel) ...[
          const SizedBox(height: 16),
          FundFilterPanel(
            filters: _currentFilter,
            onFiltersChanged: _handleFilterChanged,
          ),
        ],
      ],
    );
  }

  /// 紧凑顶部区域（移动端）
  Widget _buildCompactTopSection(FundExplorationState state) {
    return Column(
      children: [
        // 搜索栏
        Row(
          children: [
            // 搜索栏
            Expanded(
              child: FundSearchBar(
                controller: _searchController,
                onSearch: _handleSearch,
                onAdvancedFilter: () {
                  setState(() {
                    _showFilterPanel = !_showFilterPanel;
                  });
                },
              ),
            ),

            const SizedBox(width: 8),

            // 筛选按钮
            IconButton(
              onPressed: () {
                setState(() {
                  _showFilterPanel = !_showFilterPanel;
                });
              },
              icon: Icon(
                _showFilterPanel ? Icons.filter_list_off : Icons.filter_list,
                color: _showFilterPanel ? const Color(0xFF1E40AF) : Colors.grey,
              ),
              tooltip: '筛选',
            ),
          ],
        ),

        const SizedBox(height: 8),

        // 控制按钮行
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // 排序选择器（紧凑版）
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: DropdownButton<String>(
                  value: state.sortBy,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.sort, size: 14),
                  isDense: true,
                  items:
                      ['return1Y', 'return3Y', 'scale', 'name'].map((option) {
                    final labels = {
                      'return1Y': '近1年',
                      'return3Y': '近3年',
                      'scale': '规模',
                      'name': '名称',
                    };
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(labels[option] ?? option,
                          style: const TextStyle(fontSize: 12)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      context.read<FundExplorationCubit>().updateSortBy(value);
                    }
                  },
                ),
              ),

              const SizedBox(width: 8),

              // 视图模式切换（紧凑版）
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.grid_view,
                      color:
                          _isGridView ? const Color(0xFF1E40AF) : Colors.grey,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _isGridView = true),
                    tooltip: '网格视图',
                    padding: const EdgeInsets.all(4),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.list,
                      color:
                          !_isGridView ? const Color(0xFF1E40AF) : Colors.grey,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _isGridView = false),
                    tooltip: '列表视图',
                    padding: const EdgeInsets.all(4),
                  ),
                ],
              ),

              const SizedBox(width: 8),

              // 对比模式切换（紧凑版）
              ElevatedButton.icon(
                onPressed: _toggleComparisonMode,
                icon: Icon(
                    _comparisonMode ? Icons.check_circle : Icons.compare_arrows,
                    size: 16),
                label: Text(_comparisonMode ? '退出' : '对比',
                    style: const TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _comparisonMode ? const Color(0xFF1E40AF) : Colors.grey,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                ),
              ),
            ],
          ),
        ),

        // 筛选面板
        if (_showFilterPanel) ...[
          const SizedBox(height: 12),
          FundFilterPanel(
            filters: _currentFilter,
            onFiltersChanged: _handleFilterChanged,
          ),
        ],
      ],
    );
  }

  /// 构建排序选择器
  Widget _buildSortSelector(FundExplorationState state) {
    final sortOptions = ['return1Y', 'return3Y', 'scale', 'name'];
    final sortLabels = {
      'return1Y': '近1年收益',
      'return3Y': '近3年收益',
      'scale': '基金规模',
      'name': '基金名称',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: state.sortBy,
        underline: const SizedBox(),
        icon: const Icon(Icons.sort, size: 16),
        items: sortOptions.map((option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(sortLabels[option] ?? option,
                style: const TextStyle(fontSize: 14)),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            context.read<FundExplorationCubit>().updateSortBy(value);
          }
        },
      ),
    );
  }

  /// 构建视图模式切换
  Widget _buildViewModeToggle() {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            Icons.grid_view,
            color: _isGridView ? const Color(0xFF1E40AF) : Colors.grey,
          ),
          onPressed: () => setState(() => _isGridView = true),
          tooltip: '网格视图',
        ),
        IconButton(
          icon: Icon(
            Icons.list,
            color: !_isGridView ? const Color(0xFF1E40AF) : Colors.grey,
          ),
          onPressed: () => setState(() => _isGridView = false),
          tooltip: '列表视图',
        ),
      ],
    );
  }

  /// 构建对比模式切换
  Widget _buildComparisonToggle() {
    return ElevatedButton.icon(
      onPressed: _toggleComparisonMode,
      icon: Icon(_comparisonMode ? Icons.check_circle : Icons.compare_arrows),
      label: Text(_comparisonMode ? '退出对比' : '对比模式'),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            _comparisonMode ? const Color(0xFF1E40AF) : Colors.grey,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// 构建内容区域
  Widget _buildContentSection(FundExplorationState state) {
    // 根据状态显示不同的内容
    switch (state.activeView) {
      case FundExplorationView.search:
        return _buildSearchResults(state);
      case FundExplorationView.filtered:
        return _buildFilteredResults(state);
      case FundExplorationView.comparison:
        return _buildComparisonView(state);
      case FundExplorationView.all:
        return _buildDefaultLayout(state);
      case FundExplorationView.hot:
        return _buildDefaultLayout(state);
      case FundExplorationView.ranking:
        return _buildDefaultLayout(state);
    }
  }

  /// 构建默认布局
  Widget _buildDefaultLayout(FundExplorationState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 响应式布局 - 优化断点设置
        if (constraints.maxWidth > 1400) {
          return _buildDesktopLayout();
        } else if (constraints.maxWidth > 1024) {
          return _buildDesktopLayout();
        } else if (constraints.maxWidth > 768) {
          return _buildTabletLayout();
        } else if (constraints.maxWidth > 480) {
          return _buildMobileLayout();
        } else {
          return _buildCompactLayout(); // 超小屏布局
        }
      },
    );
  }

  /// 构建搜索结果视图
  Widget _buildSearchResults(FundExplorationState state) {
    if (state.searchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '未找到相关基金',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              '请尝试其他关键词',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return _buildFundGrid(state.searchResults, state);
  }

  /// 构建筛选结果视图
  Widget _buildFilteredResults(FundExplorationState state) {
    if (state.filteredFunds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.filter_list, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '没有符合筛选条件的基金',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              '请调整筛选条件',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _showFilterPanel = false;
                });
                // context
                //     .read<FundExplorationCubit>()
                //     .switchView(FundExplorationView.all);
              },
              child: const Text('重置筛选'),
            ),
          ],
        ),
      );
    }

    return _buildFundGrid(state.filteredFunds, state);
  }

  /// 构建对比视图
  Widget _buildComparisonView(FundExplorationState state) {
    if (state.comparisonFunds.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.compare_arrows, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '请选择要对比的基金',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              '点击基金卡片上的对比按钮添加基金',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '基金对比分析',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: state.comparisonFunds.length,
                  itemBuilder: (context, index) {
                    final fund = state.comparisonFunds[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(fund.name),
                        subtitle: Text('${fund.code} · ${fund.manager}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${fund.return1Y.toStringAsFixed(2)}%',
                              style: TextStyle(
                                color: Fund.getReturnColor(fund.return1Y),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () {
                                context
                                    .read<FundExplorationCubit>()
                                    .removeFromComparison(fund);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      context.read<FundExplorationCubit>().clearComparison();
                    },
                    child: const Text('清空对比'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/fund-comparison',
                        arguments:
                            state.comparisonFunds.map((f) => f.code).toList(),
                      );
                    },
                    child: const Text('开始详细对比'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建基金网格
  Widget _buildFundGrid(List<Fund> funds, FundExplorationState state) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _isGridView ? 2 : 1,
        childAspectRatio: _isGridView ? 1.2 : 3.0,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: funds.length,
      itemBuilder: (context, index) {
        final fund = funds[index];
        return FundCard(
          fund: fund,
          showComparisonCheckbox: _comparisonMode,
          isSelected: state.comparisonFunds.contains(fund),
          onSelectionChanged: (selected) {
            if (selected) {
              context.read<FundExplorationCubit>().addToComparison(fund);
            } else {
              context.read<FundExplorationCubit>().removeFromComparison(fund);
            }
          },
          onTap: () {
            Navigator.pushNamed(
              context,
              '/fund-detail',
              arguments: fund.code,
            );
          },
          compactMode: !_isGridView,
        );
      },
    );
  }

  /// 桌面端布局
  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左侧分类导航
        Expanded(
          flex: 0,
          child: SizedBox(
            width: 240,
            child: _buildLeftNavigation(),
          ),
        ),

        const SizedBox(width: 16),

        // 中间主要内容 - 修复约束冲突
        Expanded(
          flex: 1,
          child: Column(
            children: [
              // 热门基金推荐
              Expanded(
                flex: 1,
                child: HotFundsSection(),
              ),
              SizedBox(height: 16),

              // 基金排行榜 - 使用独立状态管理
              Expanded(
                flex: 1,
                child: FundRankingWrapperSimple(),
              ),
              SizedBox(height: 16),

              // 市场动态
              Expanded(
                flex: 1,
                child: MarketDynamicsSection(),
              ),
            ],
          ),
        ),

        const SizedBox(width: 16),

        // 右侧工具栏
        Expanded(
          flex: 0,
          child: SizedBox(
            width: 320,
            child: _buildRightTools(),
          ),
        ),
      ],
    );
  }

  /// 平板端布局
  Widget _buildTabletLayout() {
    // 平板端使用可折叠的工具栏
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左侧导航
        Flexible(
          flex: 1,
          child: _buildLeftNavigation(),
        ),

        const SizedBox(width: 16),

        // 中间主要内容 - 修复平板端约束
        const Flexible(
          flex: 3,
          child: Column(
            children: [
              Expanded(child: HotFundsSection()),
              SizedBox(height: 16),
              // 基金排行榜 - 使用独立状态管理
              Expanded(child: FundRankingWrapperSimple()),
              SizedBox(height: 16),
              Expanded(child: MarketDynamicsSection()),
            ],
          ),
        ),

        const SizedBox(width: 16),

        // 右侧工具栏（可折叠）
        Flexible(
          flex: 1,
          child: _buildCollapsibleRightTools(),
        ),
      ],
    );
  }

  /// 手机端布局 - 修复约束冲突问题
  Widget _buildMobileLayout() {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 分类导航（横向滚动）
            SizedBox(
              height: 60,
              child: _buildHorizontalNavigation(),
            ),
            const SizedBox(height: 8),

            // 主要内容 - 使用Expanded避免约束冲突
            const Expanded(
              child: SingleChildScrollView(
                physics: ClampingScrollPhysics(),
                child: Column(
                  children: [
                    HotFundsSection(),
                    SizedBox(height: 16),
                    // 基金排行榜 - 使用独立状态管理
                    FundRankingWrapperSimple(),
                    SizedBox(height: 16),
                    MarketDynamicsSection(),
                    SizedBox(height: 80), // 为底部工具栏预留空间
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // 底部工具栏
      bottomNavigationBar: _buildMobileBottomTools(),
    );
  }

  /// 超小屏布局（极小窗口）
  Widget _buildCompactLayout() {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 分类导航（紧凑版）
            SizedBox(
              height: 50,
              child: _buildCompactHorizontalNavigation(),
            ),
            const SizedBox(height: 4),

            // 主要内容 - 垂直滚动
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  children: [
                    // 热门基金（紧凑版）
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: HotFundsSection(),
                    ),
                    const SizedBox(height: 8),
                    // 基金排行榜（紧凑版）
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: FundRankingWrapperSimple(),
                    ),
                    const SizedBox(height: 8),
                    // 市场动态（紧凑版）
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: MarketDynamicsSection(),
                    ),
                    const SizedBox(height: 80), // 为底部工具栏预留空间
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // 底部工具栏（紧凑版）
      bottomNavigationBar: _buildCompactBottomTools(),
    );
  }

  /// 构建紧凑横向导航
  Widget _buildCompactHorizontalNavigation() {
    final categories = ['全部', '股票', '债券', '混合', '指数'];

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: FilterChip(
            label: Text(
              categories[index],
              style: const TextStyle(fontSize: 11),
            ),
            selected: index == 0,
            onSelected: (selected) {
              // 处理分类选择
            },
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
        );
      },
    );
  }

  /// 构建紧凑底部工具栏
  Widget _buildCompactBottomTools() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 基金对比工具按钮
          TextButton.icon(
            onPressed: () {
              _showComparisonDialog(context);
            },
            icon: const Icon(Icons.compare_arrows, size: 18),
            label: const Text('对比', style: TextStyle(fontSize: 10)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
            ),
          ),

          // 定投计算器按钮
          TextButton.icon(
            onPressed: () {
              _showCalculatorDialog(context);
            },
            icon: const Icon(Icons.calculate, size: 18),
            label: const Text('计算', style: TextStyle(fontSize: 10)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
            ),
          ),

          // 更多工具按钮
          TextButton.icon(
            onPressed: () {
              _showMoreToolsMenu(context);
            },
            icon: const Icon(Icons.more_horiz, size: 18),
            label: const Text('更多', style: TextStyle(fontSize: 10)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建左侧导航
  Widget _buildLeftNavigation() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题部分使用Flexible避免溢出
            Flexible(
              child: Text(
                '基金分类',
                style: TextStyle(
                  fontSize: 16, // 减小字体避免溢出
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8), // 减小间距

            // 使用Expanded和ListView来避免溢出
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildNavigationSection('基金类型', const [
                      '全部基金',
                      '股票型基金',
                      '债券型基金',
                      '混合型基金',
                      '货币型基金',
                      '指数型基金',
                      'QDII基金',
                    ]),
                    const SizedBox(height: 16), // 减小间距
                    _buildNavigationSection('投资策略', const [
                      '主动管理',
                      '被动指数',
                      '行业主题',
                      '量化投资',
                      '价值投资',
                      '成长投资',
                    ]),
                    const SizedBox(height: 16), // 减小间距
                    _buildNavigationSection('热门主题', const [
                      '科技成长',
                      '消费升级',
                      '医疗健康',
                      '新能源',
                      'ESG投资',
                      '国企改革',
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建横向导航
  Widget _buildHorizontalNavigation() {
    final categories = ['全部', '股票型', '债券型', '混合型', '指数型', 'QDII'];

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(categories[index]),
            selected: index == 0,
            onSelected: (selected) {
              // 处理分类选择
            },
          ),
        );
      },
    );
  }

  /// 构建导航部分
  Widget _buildNavigationSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: TextButton(
                onPressed: () {
                  // 处理导航点击
                },
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                ),
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            )),
      ],
    );
  }

  /// 构建右侧工具栏
  Widget _buildRightTools() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          // 基金对比工具
          FundComparisonTool(),
          SizedBox(height: 16),

          // 定投计算器
          InvestmentCalculator(),
        ],
      ),
    );
  }

  /// 构建可折叠的右侧工具栏（用于平板端）
  Widget _buildCollapsibleRightTools() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '工具箱',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // 基金对比工具
              const FundComparisonTool(),
              const SizedBox(height: 16),

              // 定投计算器
              const InvestmentCalculator(),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建移动端底部工具栏
  Widget _buildMobileBottomTools() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 基金对比工具按钮
          TextButton.icon(
            onPressed: () {
              // 显示基金对比对话框
              _showComparisonDialog(context);
            },
            icon: const Icon(Icons.compare_arrows, size: 20),
            label: const Text('对比', style: TextStyle(fontSize: 12)),
          ),

          // 定投计算器按钮
          TextButton.icon(
            onPressed: () {
              // 显示定投计算器对话框
              _showCalculatorDialog(context);
            },
            icon: const Icon(Icons.calculate, size: 20),
            label: const Text('计算', style: TextStyle(fontSize: 12)),
          ),

          // 更多工具按钮
          TextButton.icon(
            onPressed: () {
              // 显示更多工具菜单
              _showMoreToolsMenu(context);
            },
            icon: const Icon(Icons.more_horiz, size: 20),
            label: const Text('更多', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  /// 显示基金对比对话框
  void _showComparisonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('基金对比'),
        content: const SingleChildScrollView(
          child: FundComparisonTool(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 显示定投计算器对话框
  void _showCalculatorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('定投计算器'),
        content: const SingleChildScrollView(
          child: InvestmentCalculator(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 显示更多工具菜单
  void _showMoreToolsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.compare_arrows),
              title: const Text('基金对比'),
              onTap: () {
                Navigator.pop(context);
                _showComparisonDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calculate),
              title: const Text('定投计算器'),
              onTap: () {
                Navigator.pop(context);
                _showCalculatorDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('收益分析'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 显示收益分析
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 构建对比工具栏
  Widget _buildComparisonToolbar(FundExplorationState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            '已选择 ${state.comparisonFunds.length} 只基金',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              context.read<FundExplorationCubit>().clearComparison();
            },
            child: const Text('清空选择'),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () {
              if (state.comparisonFunds.isNotEmpty) {
                Navigator.pushNamed(
                  context,
                  '/fund-comparison',
                  arguments: state.comparisonFunds.map((f) => f.code).toList(),
                );
              }
            },
            icon: const Icon(Icons.analytics),
            label: const Text('开始对比分析'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E40AF),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建加载组件
  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('正在加载基金数据...'),
        ],
      ),
    );
  }

  /// 构建错误组件
  Widget _buildErrorWidget(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            errorMessage,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<FundExplorationCubit>().initialize();
            },
            child: const Text('重新加载'),
          ),
        ],
      ),
    );
  }
}
