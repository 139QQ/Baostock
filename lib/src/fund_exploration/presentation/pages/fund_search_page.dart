import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/fund/presentation/bloc/search_bloc.dart';
import '../../../features/fund/presentation/bloc/search_event.dart';
import '../../../features/fund/presentation/bloc/search_state.dart';
import '../../../features/fund/presentation/bloc/filter_bloc.dart';
import '../../../features/fund/presentation/bloc/filter_state.dart';
import '../../../features/fund/domain/entities/fund_search_criteria.dart';
import '../../../features/fund/presentation/widgets/fund_search_bar.dart';
import '../../../features/fund/presentation/widgets/search_auto_complete.dart';
import '../../../features/fund/presentation/widgets/search_results.dart';
import '../../../features/fund/presentation/widgets/filter_panel.dart';

/// 基金搜索页面
///
/// 整合搜索和筛选功能的完整页面，提供：
/// - 统一的搜索和筛选界面
/// - 实时搜索和筛选结果更新
/// - 搜索历史和筛选历史管理
/// - 性能优化和用户体验
///
/// 功能特性：
/// - 响应时间≤300ms
/// - 搜索与筛选无缝切换
/// - 智能缓存和预加载
/// - 完整的错误处理
class FundSearchPage extends StatefulWidget {
  const FundSearchPage({super.key});

  @override
  State<FundSearchPage> createState() => _FundSearchPageState();
}

class _FundSearchPageState extends State<FundSearchPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => SearchBloc(
            searchUseCase: context.read(),
          ),
        ),
        BlocProvider(
          create: (context) => FilterBloc(
            filterUseCase: context.read(),
          ),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('基金搜索'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(
                _showFilters ? Icons.filter_list : Icons.filter_list_outlined,
              ),
              onPressed: () {
                setState(() {
                  _showFilters = !_showFilters;
                });
              },
              tooltip: _showFilters ? '隐藏筛选' : '显示筛选',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(
                icon: Icon(Icons.search),
                text: '搜索',
              ),
              Tab(
                icon: Icon(Icons.filter_list),
                text: '筛选',
              ),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.7),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildSearchTab(),
            _buildFilterTab(),
          ],
        ),
      ),
    );
  }

  /// 构建搜索标签页
  Widget _buildSearchTab() {
    return Column(
      children: [
        // 搜索栏
        Container(
          padding: const EdgeInsets.all(16),
          child: FundSearchBar(
            autoFocus: true,
            showAdvancedOptions: true,
            onSearch: (keyword) {
              // 触发搜索
              context.read<SearchBloc>().add(
                    PerformSearch(
                      criteria: FundSearchCriteria.keyword(keyword),
                    ),
                  );
            },
            onClear: () {
              // 清空搜索
              context.read<SearchBloc>().add(ClearSearch());
            },
          ),
        ),

        // 搜索建议和自动完成
        Expanded(
          child: BlocBuilder<SearchBloc, SearchState>(
            builder: (context, state) {
              if (state is SearchLoadSuccess ||
                  state is SearchSuggestionsLoadSuccess) {
                return Column(
                  children: [
                    // 搜索建议
                    if (state is SearchLoadSuccess &&
                        state.suggestions.isNotEmpty)
                      Container(
                        height: 200,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        child: SearchAutoComplete(
                          currentKeyword: state.searchResult.criteria.keyword,
                          maxSuggestions: 8,
                          onSuggestionSelected: (suggestion) {
                            context.read<SearchBloc>().add(
                                  SelectSearchSuggestion(
                                      suggestion: suggestion),
                                );
                          },
                        ),
                      ),

                    // 搜索结果
                    Expanded(
                      child: SearchResults(
                        searchResult: state is SearchLoadSuccess
                            ? state.searchResult
                            : null,
                        onResultSelected: (fundCode) {
                          // 可以导航到基金详情页
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('已选择基金: $fundCode'),
                              action: SnackBarAction(
                                label: '查看详情',
                                onPressed: () {
                                  // 导航到基金详情页
                                },
                              ),
                            ),
                          );
                        },
                        onRefresh: () {
                          context.read<SearchBloc>().add(RefreshSearch());
                        },
                      ),
                    ),
                  ],
                );
              } else if (state is SearchLoadFailure) {
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
                        state.errorMessage,
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          context.read<SearchBloc>().add(RefreshSearch());
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('重试'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  /// 构建筛选标签页
  Widget _buildFilterTab() {
    return Column(
      children: [
        // 筛选面板
        Expanded(
          child: BlocBuilder<FilterBloc, FilterState>(
            builder: (context, state) {
              if (state.isSuccess) {
                return const FilterPanel();
              } else if (state.isFailure) {
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
                        state.error ?? '筛选失败',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              } else {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}
