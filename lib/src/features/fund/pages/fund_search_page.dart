import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/fund_search_bloc.dart';
import '../../../services/high_performance_fund_service.dart';
import '../../../services/fund_analysis_service.dart';
import '../widgets/fund_search_widget.dart';
import '../widgets/fund_recommendation_widget.dart';
import '../widgets/search_history_widget.dart';

/// 基金搜索页面
class FundSearchPage extends StatelessWidget {
  const FundSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('基金搜索'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
      ),
      body: BlocProvider(
        create: (context) => FundSearchBloc(
          fundService: HighPerformanceFundService(),
          analysisService: FundAnalysisService(),
        )
          ..add(LoadSearchHistory())
          ..add(LoadPopularSearches()),
        child: const FundSearchView(),
      ),
    );
  }
}

/// 基金搜索视图
class FundSearchView extends StatefulWidget {
  const FundSearchView({super.key});

  @override
  State<FundSearchView> createState() => _FundSearchViewState();
}

class _FundSearchViewState extends State<FundSearchView> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FundSearchBloc, FundSearchState>(
      builder: (context, state) {
        return Column(
          children: [
            // 搜索栏
            _buildSearchBar(context, state),

            // 内容区域
            Expanded(
              child: _buildContent(context, state),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar(BuildContext context, FundSearchState state) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 搜索输入框
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            autofocus: true,
            decoration: InputDecoration(
              hintText: '搜索基金代码、名称或类型',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _searchFocusNode.unfocus();
                        context.read<FundSearchBloc>().add(ClearSearch());
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) {
              setState(() {});
            },
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                context.read<FundSearchBloc>().add(SearchFunds(value.trim()));
              }
            },
          ),

          const SizedBox(height: 12),

          // 快速筛选标签
          _buildQuickFilters(context),
        ],
      ),
    );
  }

  Widget _buildQuickFilters(BuildContext context) {
    final filters = [
      {'label': '全部', 'type': '全部'},
      {'label': '股票型', 'type': '股票型'},
      {'label': '混合型', 'type': '混合型'},
      {'label': '债券型', 'type': '债券型'},
      {'label': '指数型', 'type': '指数型'},
      {'label': 'QDII', 'type': 'QDII'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: filters.map((filter) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter['label'] as String),
              selected: false,
              onSelected: (selected) {
                if (selected) {
                  context.read<FundSearchBloc>().add(
                        FilterFunds(fundType: filter['type'] as String),
                      );
                }
              },
              backgroundColor: Colors.grey[200],
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              labelStyle: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 12,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent(BuildContext context, FundSearchState state) {
    if (state is FundSearchLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state is FundSearchError) {
      return _buildErrorState(context, state);
    }

    if (state is FundSearchEmpty) {
      return _buildEmptyState(context, state);
    }

    if (state is FundSearchLoaded) {
      if (state.funds.isEmpty && state.query.isEmpty) {
        return _buildInitialState(context, state);
      } else {
        return FundSearchWidget(funds: state.funds);
      }
    }

    return _buildInitialState(context, null);
  }

  Widget _buildInitialState(BuildContext context, FundSearchState? state) {
    final bloc = context.read<FundSearchBloc>();

    // 获取搜索历史，从当前状态中获取
    final searchHistory =
        state is FundSearchLoaded ? state.searchHistory : <String>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 搜索历史
          if (searchHistory.isNotEmpty) ...[
            SearchHistoryWidget(
              history: searchHistory,
              onSearch: (query) {
                _searchController.text = query;
                bloc.add(SearchFunds(query));
              },
              onClear: () {
                bloc.add(ClearSearchHistory());
              },
            ),
            const SizedBox(height: 24),
          ],

          // 热门搜索
          Text(
            '热门搜索',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          _buildPopularSearches(context, bloc),

          const SizedBox(height: 24),

          // 推荐基金
          Text(
            '推荐基金',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          const FundRecommendationWidget(),
        ],
      ),
    );
  }

  Widget _buildPopularSearches(BuildContext context, FundSearchBloc bloc) {
    final currentState = bloc.state;
    final popularSearches = currentState is FundSearchLoaded
        ? currentState.popularSearches
        : [
            '易方达',
            '华夏',
            '南方',
            '嘉实',
            '广发',
            '汇添富',
            '富国',
            '招商',
            '股票型',
            '混合型',
          ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: popularSearches.map((search) {
        return ActionChip(
          label: Text(search),
          onPressed: () {
            _searchController.text = search;
            bloc.add(SearchFunds(search));
          },
          backgroundColor: Colors.grey[100],
          labelStyle: TextStyle(
            color: Theme.of(context).primaryColor,
            fontSize: 12,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildErrorState(BuildContext context, FundSearchError state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            '搜索出错了',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            state.message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              if (state.query.isNotEmpty) {
                context.read<FundSearchBloc>().add(SearchFunds(state.query));
              } else {
                _searchController.clear();
                context.read<FundSearchBloc>().add(ClearSearch());
              }
            },
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, FundSearchEmpty state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '未找到相关基金',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '试试其他关键词或查看推荐基金',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              _searchController.clear();
              context.read<FundSearchBloc>().add(ClearSearch());
            },
            child: const Text('查看推荐'),
          ),
        ],
      ),
    );
  }
}
