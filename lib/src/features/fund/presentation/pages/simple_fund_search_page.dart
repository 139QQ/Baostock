import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../fund_exploration/presentation/cubit/fund_exploration_cubit.dart';
import '../widgets/simple_fund_search_bar.dart';
import '../widgets/simple_search_results.dart';
import '../widgets/simple_filter_panel.dart';

/// 简化的基金搜索页面
///
/// 使用统一的FundExplorationCubit状态管理
/// 整合搜索栏、筛选面板和结果展示
class SimpleFundSearchPage extends StatefulWidget {
  /// 页面标题
  final String? title;

  /// 初始搜索关键词
  final String? initialQuery;

  /// 是否显示筛选面板
  final bool showFilterPanel;

  /// 自定义空状态组件
  final Widget? emptyWidget;

  /// 基金选择回调
  final Function(String fundCode, String fundName)? onFundSelected;

  const SimpleFundSearchPage({
    super.key,
    this.title,
    this.initialQuery,
    this.showFilterPanel = true,
    this.emptyWidget,
    this.onFundSelected,
  });

  @override
  State<SimpleFundSearchPage> createState() => _SimpleFundSearchPageState();
}

class _SimpleFundSearchPageState extends State<SimpleFundSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();

    // 设置初始搜索关键词
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _currentQuery = widget.initialQuery!;
      _searchController.text = _currentQuery;

      // 延迟执行搜索，确保Cubit已初始化
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch(_currentQuery);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 执行搜索
  void _performSearch(String query) {
    setState(() {
      _currentQuery = query;
    });

    if (query.trim().isNotEmpty) {
      context.read<FundExplorationCubit>().searchFunds(query.trim());
    } else {
      context.read<FundExplorationCubit>().searchFunds('');
    }
  }

  /// 处理基金选择
  void _onFundSelected(String fundCode, String fundName) {
    widget.onFundSelected?.call(fundCode, fundName);

    // 如果没有提供回调，默认导航到基金详情页
    if (widget.onFundSelected == null) {
      // TODO: 导航到基金详情页
      // Navigator.of(context).pushNamed('/fund/detail', arguments: {'code': fundCode, 'name': fundName});
    }
  }

  /// 刷新数据
  void _refreshData() {
    if (_currentQuery.isNotEmpty) {
      context.read<FundExplorationCubit>().searchFunds(_currentQuery);
    } else {
      context.read<FundExplorationCubit>().loadFundRankings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // 搜索栏
          Container(
            padding: const EdgeInsets.all(16),
            child: SimpleFundSearchBar(
              searchText: _currentQuery,
              onSearch: _performSearch,
              autoFocus: widget.initialQuery == null,
            ),
          ),

          // 筛选面板
          if (widget.showFilterPanel) ...[
            const SimpleFilterPanel(),
            const SizedBox(height: 8),
          ],

          // 搜索结果
          Expanded(
            child: SimpleSearchResults(
              query: _currentQuery,
              onFundSelected: _onFundSelected,
              emptyWidget: widget.emptyWidget,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshData,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  /// 构建应用栏
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(widget.title ?? '基金搜索'),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        // 搜索历史按钮
        IconButton(
          icon: const Icon(Icons.history),
          onPressed: _showSearchHistory,
          tooltip: '搜索历史',
        ),
        // 筛选按钮
        if (widget.showFilterPanel)
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: '高级筛选',
          ),
      ],
    );
  }

  /// 显示搜索历史
  void _showSearchHistory() {
    final cubit = context.read<FundExplorationCubit>();
    final searchHistory = cubit.state.searchHistory;

    if (searchHistory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无搜索历史')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history),
                const SizedBox(width: 8),
                const Text(
                  '搜索历史',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    cubit.clearSearchHistory();
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('搜索历史已清空')),
                    );
                  },
                  child: const Text('清空'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...searchHistory.map((query) => ListTile(
                  leading: const Icon(Icons.search),
                  title: Text(query),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.of(context).pop();
                    _searchController.text = query;
                    _performSearch(query);
                  },
                )),
          ],
        ),
      ),
    );
  }

  /// 显示筛选对话框
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('高级筛选'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // TODO: 添加高级筛选选项
              ListTile(
                leading: Icon(Icons.sort),
                title: Text('排序方式'),
                subtitle: Text('按收益率排序'),
              ),
              ListTile(
                leading: Icon(Icons.filter_list),
                title: Text('基金类型'),
                subtitle: Text('全部类型'),
              ),
              ListTile(
                leading: Icon(Icons.account_balance),
                title: Text('基金公司'),
                subtitle: Text('全部公司'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: 应用筛选条件
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('筛选功能开发中')),
              );
            },
            child: const Text('应用'),
          ),
        ],
      ),
    );
  }
}
