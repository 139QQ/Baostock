import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/bloc/search_bloc.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/bloc/search_event.dart';

/// 搜索历史组件
///
/// 专门管理搜索历史记录的UI组件，提供：
/// - 历史记录列表展示
/// - 历史记录搜索和筛选
/// - 历史记录管理（删除、清空）
/// - 历史记录统计分析
/// - 历史记录导出功能
///
/// 功能特性：
/// - 智能分组和排序
/// - 快速搜索和筛选
/// - 数据持久化
/// - 隐私保护
class SearchHistory extends StatefulWidget {
  /// 最大显示数量
  final int maxDisplayCount;

  /// 是否显示统计信息
  final bool showStatistics;

  /// 是否显示搜索次数
  final bool showSearchCount;

  /// 是否显示搜索时间
  final bool showSearchTime;

  /// 是否启用搜索功能
  final bool enableSearch;

  /// 是否启用分组
  final bool enableGrouping;

  /// 自定义历史记录项构建器
  final Widget Function(HistoryItem item, int index)? itemBuilder;

  /// 自定义分组构建器
  final Widget Function(String group, List<HistoryItem> items)? groupBuilder;

  /// 历史记录点击回调
  final ValueChanged<String>? onHistorySelected;

  /// 删除回调
  final Function(String keyword)? onHistoryDeleted;

  /// 清空回调
  final VoidCallback? onHistoryCleared;

  /// 创建搜索历史组件
  const SearchHistory({
    Key? key,
    this.maxDisplayCount = 20,
    this.showStatistics = true,
    this.showSearchCount = true,
    this.showSearchTime = true,
    this.enableSearch = true,
    this.enableGrouping = true,
    this.itemBuilder,
    this.groupBuilder,
    this.onHistorySelected,
    this.onHistoryDeleted,
    this.onHistoryCleared,
  }) : super(key: key);

  @override
  State<SearchHistory> createState() => _SearchHistoryState();
}

class _SearchHistoryState extends State<SearchHistory>
    with TickerProviderStateMixin {
  late TextEditingController _searchController;
  late TabController _tabController;
  List<HistoryItem> _historyItems = [];
  List<HistoryItem> _filteredItems = [];
  String _searchQuery = '';
  HistoryGroupType _currentGroupType = HistoryGroupType.all;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadMockHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /// 加载模拟历史记录数据
  void _loadMockHistory() {
    final now = DateTime.now();
    _historyItems = [
      HistoryItem(
        keyword: '股票基金',
        searchCount: 15,
        lastSearched: now.subtract(const Duration(hours: 2)),
        category: '基金类型',
      ),
      HistoryItem(
        keyword: '债券基金',
        searchCount: 12,
        lastSearched: now.subtract(const Duration(hours: 5)),
        category: '基金类型',
      ),
      HistoryItem(
        keyword: '易方达',
        searchCount: 8,
        lastSearched: now.subtract(const Duration(days: 1)),
        category: '基金公司',
      ),
      HistoryItem(
        keyword: '新能源',
        searchCount: 20,
        lastSearched: now.subtract(const Duration(days: 2)),
        category: '投资主题',
      ),
      HistoryItem(
        keyword: '医药基金',
        searchCount: 6,
        lastSearched: now.subtract(const Duration(days: 3)),
        category: '投资主题',
      ),
      HistoryItem(
        keyword: '混合基金',
        searchCount: 18,
        lastSearched: now.subtract(const Duration(days: 5)),
        category: '基金类型',
      ),
      HistoryItem(
        keyword: '华夏基金',
        searchCount: 10,
        lastSearched: now.subtract(const Duration(days: 7)),
        category: '基金公司',
      ),
      HistoryItem(
        keyword: '科技主题',
        searchCount: 14,
        lastSearched: now.subtract(const Duration(days: 10)),
        category: '投资主题',
      ),
    ];
    _filteredItems = List.from(_historyItems);
  }

  /// Tab变化处理
  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;

    setState(() {
      switch (_tabController.index) {
        case 0:
          _currentGroupType = HistoryGroupType.all;
          break;
        case 1:
          _currentGroupType = HistoryGroupType.recent;
          break;
        case 2:
          _currentGroupType = HistoryGroupType.frequent;
          break;
        case 3:
          _currentGroupType = HistoryGroupType.category;
          break;
      }
      _applyFilters();
    });
  }

  /// 搜索查询变化
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  /// 应用筛选条件
  void _applyFilters() {
    var items = List<HistoryItem>.from(_historyItems);

    // 按分组类型筛选
    if (_currentGroupType != HistoryGroupType.all) {
      switch (_currentGroupType) {
        case HistoryGroupType.recent:
          final now = DateTime.now();
          items = items
              .where((item) => item.lastSearched
                  .isAfter(now.subtract(const Duration(days: 7))))
              .toList();
          break;
        case HistoryGroupType.frequent:
          items = items.where((item) => item.searchCount >= 10).toList();
          break;
        case HistoryGroupType.category:
          items = items.where((item) => item.category.isNotEmpty).toList();
          break;
        default:
          break;
      }
    }

    // 按搜索查询筛选
    if (_searchQuery.isNotEmpty) {
      items = items
          .where((item) =>
              item.keyword.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // 排序
    items.sort((a, b) {
      switch (_currentGroupType) {
        case HistoryGroupType.recent:
          return b.lastSearched.compareTo(a.lastSearched);
        case HistoryGroupType.frequent:
          return b.searchCount.compareTo(a.searchCount);
        default:
          return b.lastSearched.compareTo(a.lastSearched);
      }
    });

    setState(() {
      _filteredItems = items.take(widget.maxDisplayCount).toList();
    });
  }

  /// 选择历史记录
  void _onSelectHistory(HistoryItem item) {
    widget.onHistorySelected?.call(item.keyword);
    context
        .read<SearchBloc>()
        .add(SelectSearchSuggestion(suggestion: item.keyword));
  }

  /// 删除历史记录
  void _onDeleteHistory(HistoryItem item) {
    setState(() {
      _historyItems.remove(item);
      _applyFilters();
    });
    widget.onHistoryDeleted?.call(item.keyword);
  }

  /// 清空历史记录
  void _onClearHistory() {
    setState(() {
      _historyItems.clear();
      _filteredItems.clear();
    });
    widget.onHistoryCleared?.call();
    context.read<SearchBloc>().add(const ClearSearchHistory());
  }

  /// 构建搜索栏
  Widget _buildSearchBar() {
    if (!widget.enableSearch) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜索历史记录...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  /// 构建Tab栏
  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: const [
        Tab(text: '全部'),
        Tab(text: '最近'),
        Tab(text: '常用'),
        Tab(text: '分类'),
      ],
      labelColor: Theme.of(context).primaryColor,
      unselectedLabelColor: Colors.grey,
      indicatorColor: Theme.of(context).primaryColor,
    );
  }

  /// 构建统计信息
  Widget _buildStatistics() {
    if (!widget.showStatistics) return const SizedBox.shrink();

    final totalSearches =
        _historyItems.fold<int>(0, (sum, item) => sum + item.searchCount);
    final uniqueKeywords = _historyItems.length;
    final avgSearches = uniqueKeywords > 0 ? totalSearches / uniqueKeywords : 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              const Text(
                '搜索统计',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('总搜索', totalSearches.toString()),
              ),
              Expanded(
                child: _buildStatItem('关键词', uniqueKeywords.toString()),
              ),
              Expanded(
                child: _buildStatItem('平均', avgSearches.toStringAsFixed(1)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建统计项
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// 构建历史记录项
  Widget _buildHistoryItem(HistoryItem item, int index) {
    if (widget.itemBuilder != null) {
      return widget.itemBuilder!(item, index);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _onSelectHistory(item),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[200]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                // 图标
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _getCategoryIcon(item.category),
                    size: 20,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 12),

                // 内容
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.keyword,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (widget.showSearchCount) ...[
                            Icon(
                              Icons.search,
                              size: 12,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${item.searchCount}次',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (widget.showSearchTime) ...[
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 2),
                            Text(
                              _formatDateTime(item.lastSearched),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // 删除按钮
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Colors.grey,
                  ),
                  onPressed: () => _onDeleteHistory(item),
                  tooltip: '删除',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 获取分类图标
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case '基金类型':
        return Icons.category;
      case '基金公司':
        return Icons.business;
      case '投资主题':
        return Icons.lightbulb;
      default:
        return Icons.search;
    }
  }

  /// 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '今天';
    } else if (difference.inDays == 1) {
      return '昨天';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}周前';
    } else {
      return '${dateTime.month}月${dateTime.day}日';
    }
  }

  /// 构建分组内容
  Widget _buildGroupedContent() {
    if (!widget.enableGrouping ||
        _currentGroupType != HistoryGroupType.category) {
      return _buildHistoryList();
    }

    final groupedItems = <String, List<HistoryItem>>{};
    for (final item in _filteredItems) {
      final category = item.category.isEmpty ? '其他' : item.category;
      groupedItems.putIfAbsent(category, () => []).add(item);
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: groupedItems.length,
      itemBuilder: (context, index) {
        final category = groupedItems.keys.elementAt(index);
        final items = groupedItems[category]!;

        if (widget.groupBuilder != null) {
          return widget.groupBuilder!(category, items);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ),
            ...items
                .map((item) => _buildHistoryItem(item, items.indexOf(item))),
          ],
        );
      },
    );
  }

  /// 构建历史记录列表
  Widget _buildHistoryList() {
    if (_filteredItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              '暂无搜索历史',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        return _buildHistoryItem(_filteredItems[index], index);
      },
    );
  }

  /// 构建操作栏
  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            '共 ${_filteredItems.length} 条记录',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const Spacer(),
          if (_historyItems.isNotEmpty)
            TextButton.icon(
              onPressed: _onClearHistory,
              icon: const Icon(Icons.delete_sweep, size: 16),
              label: const Text('清空'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        _buildTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // 全部Tab
              _buildAllTab(),
              // 最近Tab
              _buildRecentTab(),
              // 常用Tab
              _buildFrequentTab(),
              // 分类Tab
              _buildCategoryTab(),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建全部Tab
  Widget _buildAllTab() {
    return Column(
      children: [
        if (widget.showStatistics) _buildStatistics(),
        Expanded(child: _buildHistoryList()),
        _buildActionBar(),
      ],
    );
  }

  /// 构建最近Tab
  Widget _buildRecentTab() {
    return Column(
      children: [
        Expanded(child: _buildHistoryList()),
        _buildActionBar(),
      ],
    );
  }

  /// 构建常用Tab
  Widget _buildFrequentTab() {
    return Column(
      children: [
        Expanded(child: _buildHistoryList()),
        _buildActionBar(),
      ],
    );
  }

  /// 构建分类Tab
  Widget _buildCategoryTab() {
    return Column(
      children: [
        Expanded(child: _buildGroupedContent()),
        _buildActionBar(),
      ],
    );
  }
}

/// 历史记录项数据模型
class HistoryItem extends Equatable {
  /// 搜索关键词
  final String keyword;

  /// 搜索次数
  final int searchCount;

  /// 最后搜索时间
  final DateTime lastSearched;

  /// 分类
  final String category;

  /// 是否收藏
  final bool isFavorite;

  /// 创建历史记录项
  const HistoryItem({
    required this.keyword,
    required this.searchCount,
    required this.lastSearched,
    this.category = '',
    this.isFavorite = false,
  });

  @override
  List<Object?> get props => [
        keyword,
        searchCount,
        lastSearched,
        category,
        isFavorite,
      ];

  HistoryItem copyWith({
    String? keyword,
    int? searchCount,
    DateTime? lastSearched,
    String? category,
    bool? isFavorite,
  }) {
    return HistoryItem(
      keyword: keyword ?? this.keyword,
      searchCount: searchCount ?? this.searchCount,
      lastSearched: lastSearched ?? this.lastSearched,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

/// 历史记录分组类型
enum HistoryGroupType {
  /// 全部
  all,

  /// 最近搜索
  recent,

  /// 常用搜索
  frequent,

  /// 按分类
  category,
}
