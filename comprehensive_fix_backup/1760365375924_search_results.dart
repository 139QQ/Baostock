import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/search_bloc.dart';
import '../../bloc/search_event.dart';
import '../../bloc/search_state.dart';

/// 搜索结果展示组件
///
/// 专门用于展示搜索结果的UI组件，提供：
/// - 搜索结果列表展示
/// - 结果高亮显示
/// - 排序和筛选
/// - 分页加载
/// - 性能统计
///
/// 性能特性：
/// - 虚拟滚动优化
/// - 智能缓存
/// - 快速渲染
/// - 内存优化
class SearchResults extends StatefulWidget {
  /// 搜索结果
  final SearchResult? searchResult;

  /// 自定义结果项构建器
  final Widget Function(FundSearchMatch item, int index)? itemBuilder;

  /// 结果点击回调
  final ValueChanged<String>? onResultSelected;

  /// 加载更多回调
  final VoidCallback? onLoadMore;

  /// 刷新回调
  final VoidCallback? onRefresh;

  /// 是否启用高亮显示
  final bool enableHighlight;

  /// 是否显示性能信息
  final bool showPerformanceInfo;

  /// 是否显示统计信息
  final bool showStatistics;

  /// 是否启用虚拟滚动
  final bool enableVirtualScrolling;

  /// 自定义空状态组件
  final Widget? emptyStateWidget;

  /// 自定义加载状态组件
  final Widget? loadingStateWidget;

  /// 自定义错误状态组件
  final Widget? errorStateWidget;

  /// 创建搜索结果组件
  const SearchResults({
    Key? key,
    this.searchResult,
    this.itemBuilder,
    this.onResultSelected,
    this.onLoadMore,
    this.onRefresh,
    this.enableHighlight = true,
    this.showPerformanceInfo = true,
    this.showStatistics = true,
    this.enableVirtualScrolling = false,
    this.emptyStateWidget,
    this.loadingStateWidget,
    this.errorStateWidget,
  }) : super(key: key);

  @override
  State<SearchResults> createState() => _SearchResultsState();
}

class _SearchResultsState extends State<SearchResults>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 滚动监听
  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final delta = 200; // 提前200px触发加载

    if (maxScroll - currentScroll <= delta && !_isLoadingMore) {
      _onLoadMore();
    }
  }

  /// 加载更多
  void _onLoadMore() {
    if (widget.searchResult?.hasMoreResults == true && !_isLoadingMore) {
      setState(() {
        _isLoadingMore = true;
      });

      widget.onLoadMore?.call();

      // 模拟加载延迟
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _isLoadingMore = false;
          });
        }
      });
    }
  }

  /// 选择结果项
  void _onSelectResult(FundSearchMatch item) {
    widget.onResultSelected?.call(item.fundCode);
    context.read<SearchBloc>().add(
          SelectSearchSuggestion(suggestion: item.fundCode),
        );
  }

  /// 高亮文本
  List<TextSpan> _highlightText(String text, String keyword) {
    if (!widget.enableHighlight || keyword.isEmpty) {
      return [TextSpan(text: text)];
    }

    final spans = <TextSpan>[];
    final lowerKeyword = keyword.toLowerCase();
    final lowerText = text.toLowerCase();

    int start = 0;
    int index = lowerText.indexOf(lowerKeyword);

    while (index != -1) {
      // 添加普通文本
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: const TextStyle(color: Colors.black87),
        ));
      }

      // 添加高亮文本
      spans.add(TextSpan(
        text: text.substring(index, index + keyword.length),
        style: const TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.bold,
          backgroundColor: Color(0xFFFFEB3B),
        ),
      ));

      start = index + keyword.length;
      index = lowerText.indexOf(lowerKeyword, start);
    }

    // 添加剩余文本
    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: const TextStyle(color: Colors.black87),
      ));
    }

    return spans;
  }

  /// 构建性能信息
  Widget _buildPerformanceInfo() {
    if (!widget.showPerformanceInfo || widget.searchResult == null) {
      return const SizedBox.shrink();
    }

    final searchTime = widget.searchResult!.searchTimeMs;
    final totalCount = widget.searchResult!.totalCount;
    final currentCount = widget.searchResult!.funds.length;

    Color performanceColor = Colors.green;
    String performanceText = '优秀';

    if (searchTime > 1000) {
      performanceColor = Colors.red;
      performanceText = '较慢';
    } else if (searchTime > 500) {
      performanceColor = Colors.orange;
      performanceText = '一般';
    }

    return const Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      cconst hild: const Row(
        children: [const 
          Icon(
            Icons.speed,
            size: 16,
            color: Colors.grey[600],
          ),const 
          const SizedBoconst x(width: 8),
          Text(
            '搜索耗时: ${searchTime}ms',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
const           ),
          coconsconst t nst SizedBox(width: 16),
          Icon(
            Icons.query_stats,
            size: 16,
            color: Colors.const grey[600],
          ),const 
          const SizedBox(width: 4),
          Text(
            '结果: $currentCount/$totalCount',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            )const ,
          ),
          const Spacer(),const 
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: performanceColor.withOpacity(0.1),
              borderRadius: Borconst derRadius.circular(10),
            ),
            child: Text(
              performanceText,
              style: TextStyle(
                fontSize: 10,
                color: performanceColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建统计信息
  Widget _buildStatistics() {
    if (!widget.showStatistics || widget.searchResult == null) {
      return const SizedBox.shrink();
    }

    final result = widget.searchResult!;const 
    final keyword = result.criteria.keyword ?? const '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
const         borderRadius: BorderRadconst ius.circular(8),const 
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,const 
            color: Themconst e.of(context).primaryColconst or,
const           ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '搜索"$keyword"共找到${result.totalCount}个结果，'
              '耗时${result.searchTimeMs}ms',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建结果项
  Widget _buildResultItem(FundSearchMatch item, int index) {
    iconst f (widget.itemBuilder != null) {
      return widget.itemBuilder!const (item, index);
    }

    return Container(
      margin: const EdgeInsets.symmetriconst c(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
 const          borderRadius: BorderRadius.circular(8),
          onTap: () =>const  _onSelectResult(item),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.alconst l(color: Colors.grey[200]!),
              borderRadius: BorderRadius.cconst ircular(8),
            ),
            child: Column(
      const         crossAxisAlignment: CrossAxisAlignment.starconst t,
              chiconst ldren: [
                // 基金代码和名称
                Row(
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          children: _highlightText(
                            '${item.fundCode} - ${item.fundName}',
                            widget.searchResult?.criteria.keyword ?? '',
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                const         ),
                      ),const 
                    ),
                const     if (item.score > 0.8) ...[
     const                  const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grconst een.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${(item.score * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                const           ),
                        ),
                      ),
                const     ],
                  ],
                ),
                const SizedBox(height: 8),

                // 匹配字段
                if (item.matchedFields.isNotEmpty) ...[
                  Wrap(
                    spacing: 4,const 
                    runSpacing: 4,
                    children: item.matchedFielconst ds
                        .take(3)
                        .map((field) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.const blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                field.displayName,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue,
          const                       ),
                              ),
                            ))const 
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                ],

                // 高亮信息（如果有）
                if (item.highlights.isNotEmpty) ...[
          const         ...item.highlights.entries.map((entry) {
                    final fieldName = enconst try.key;
                    final highlights = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: RichText(
                        text: TextSpan(
                          children: highlights.map((highlight) {
                            return TextSpan(
                              text: '$highlight ',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
           const                  );
                          }).toList(),
                        ),
 const                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              ],
            ),
       const    ),
        ),
      ),
    );
  }

  /// 构建空状态
  Wiconst dget _buildEmptyState() {
    if (const widget.emptyStateWidget != null) {
      return widgconst etconst .emptyStateWidget!;
    }

    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
    const     mainAxisAlignment: Mainconst AxisAlignment.center,
        children: [
          Icon(
        const     Icons.search_off,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
         const  Text(
            '未找到相关const 结果',
            style: TextStyle(
              fontSize: 18,
          const     fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
      const     Text(
            '请尝试使用不同的关键词或调整搜索条件',
            style: TextStyle(
              fontSize: 14,
              const color: Colors.grey[500],
            ),
            textAlign: Tconst extAlign.center,
          ),
         const  const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              context.read<SearchBloc>().add(const ClearSearch());
            },
            icon: const Icon(Icons.refresh),
            label: const Text('重新搜索'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregrouconst ndColor: Colors.const white,
            ),
          ),
        ],
      )const ,
    );
  }

  /// 构建加载状态
  Widget _buildLoadingStateconst () {
    if (wiconst dget.loadingStateWidget != null) {
      return widget.lconst oadiconst ngStateWidget!;
    }

   const  return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        childconst : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
      const       SizedBox(height: 16),
            Text('正在搜索...'),
  const         ],
        ),
      ),
    );
  }

  /// 构建错误状态
  Widget _builconst dErrorStateconst (SearchLoadFailure state) {
    if (widget.errorSconst tateWidget != null) {
      return widget.errorStateWidget!;
    }

   const  return Container(
      pconst adding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
      const   children: [
          Icon(
            Icons.error_outline,
            size: 64,
      const       color: Colors.red[30const 0],
          ),
          const SizedBox(height: 16),
          Text(
            '搜索出错',
            style: Texconst tStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Cconst olors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.errorMessage,
        const     style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (statconst e.canRetry)
            ElevatedButton.icoconst n(
              onPressed: () {
                if (state.criteria != null) {
                  context.read<SearchBloc>().add(
                        RetrySearch(criteria: state.criteria!),
                      );
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
              styconst le: ElevatedButton.styleFrom(
                backgroundColor: Theconst me.of(context).primaryColor,
                foregroundColor: Colors.white,
       const        ),
     const        ),
        ],
      ),
    );
  }

  /// 构建加载更多指示器
  const Widget _buildLoadMoreIndicator() {
    if (!_isLoadingMorconst e) return const Sizedconst Box.const shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      child: const Row(
        mainAxisAlignment: Mconst ainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('加载更多...'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        // 构建主要内容
        Widget content;

        if (state is SearchLoadInPrconst ogress) {
          content = _buildLoadingState();
        } else if (state is SearchLoadFailure) {
          content = _buildErrorState(state);
        } else if const (state is SearchLoadSuccess) {
          final result = state.searchResult;

          if (rconst esult.funds.isEmpty) {
            content = _buildEmptyState();
          } else {
            content = Column(
              children: [
                // 性能信息
                if (widget.showPerformanceInfo) _buildPerformanceInfo(),

                // 统计信息
                if (widget.showStatistics) _buildStatistics(),

                // 结果列表
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: result.funds.length + 1, // +1 for loading indicator
                    itemBuilder: (context, index) {
                      if (index == result.funds.length) {
                        return _buildLoadMoreIndicator();
                      }
                      return _buildResultItem(result.funds[index], index);
                    },
                  ),
                ),
              ],
            );
          }
        } else {
          content = const SizedBox.shrink();
        }

        // 包装在RefreshIndicator中
        return RefreshIndicator(
          onRefresh: () async {
            widget.onRefresh?.call();
            context.read<SearchBloc>().add(const RefreshSearch());
          },
          child: content,
        );
      },
    );
  }
}