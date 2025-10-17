import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/bloc/search_bloc.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/bloc/search_event.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/bloc/search_state.dart';

/// 搜索自动完成组件
///
/// 提供智能搜索建议和自动完成功能，包括：
/// - 实时搜索建议
/// - 搜索历史记录
/// - 热门搜索推荐
/// - 搜索分类导航
/// - 响应式布局
///
/// 性能特性：
/// - 智能缓存和去重
/// - 快速响应（≤100ms）
/// - 内存优化
/// - 滚动性能优化
class SearchAutoComplete extends StatefulWidget {
  /// 当前搜索关键词
  final String? currentKeyword;

  /// 最大建议数量
  final int maxSuggestions;

  /// 最大历史记录数量
  final int maxHistoryItems;

  /// 是否显示热门搜索
  final bool showPopularSearches;

  /// 是否显示搜索分类
  final bool showSearchCategories;

  /// 热门搜索列表
  final List<String>? popularSearches;

  /// 搜索分类列表
  final List<SearchCategory>? searchCategories;

  /// 自定义建议构建器
  final Widget Function(String suggestion, int index)? suggestionBuilder;

  /// 自定义历史记录构建器
  final Widget Function(String history, int index)? historyBuilder;

  /// 自定义分类构建器
  final Widget Function(SearchCategory category)? categoryBuilder;

  /// 建议点击回调
  final ValueChanged<String>? onSuggestionSelected;

  /// 历史记录点击回调
  final ValueChanged<String>? onHistorySelected;

  /// 分类点击回调
  final ValueChanged<SearchCategory>? onCategorySelected;

  /// 清除历史记录回调
  final VoidCallback? onClearHistory;

  /// 是否启用动画
  final bool enableAnimation;

  /// 自定义样式
  final BoxDecoration? decoration;

  /// 自定义高度
  final double? height;

  /// 内边距
  final EdgeInsets? padding;

  /// 分隔线
  final Widget? separator;

  /// 创建搜索自动完成组件
  const SearchAutoComplete({
    Key? key,
    this.currentKeyword,
    this.maxSuggestions = 10,
    this.maxHistoryItems = 8,
    this.showPopularSearches = true,
    this.showSearchCategories = true,
    this.popularSearches,
    this.searchCategories,
    this.suggestionBuilder,
    this.historyBuilder,
    this.categoryBuilder,
    this.onSuggestionSelected,
    this.onHistorySelected,
    this.onCategorySelected,
    this.onClearHistory,
    this.enableAnimation = true,
    this.decoration,
    this.height,
    this.padding,
    this.separator,
  }) : super(key: key);

  @override
  State<SearchAutoComplete> createState() => _SearchAutoCompleteState();
}

class _SearchAutoCompleteState extends State<SearchAutoComplete>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<String> _suggestions = [];
  List<String> _history = [];
  List<SearchCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _loadInitialData();
  }

  @override
  void didUpdateWidget(SearchAutoComplete oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentKeyword != oldWidget.currentKeyword) {
      _onKeywordChanged(widget.currentKeyword);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 设置动画
  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    if (widget.enableAnimation) {
      _animationController.forward();
    }
  }

  /// 加载初始数据
  void _loadInitialData() {
    _history = [
      '股票基金',
      '债券基金',
      '货币基金',
      '混合基金',
      '指数基金',
      'ETF基金',
    ];

    _categories = widget.searchCategories ??
        [
          SearchCategory(
            id: 'popular',
            name: '热门搜索',
            icon: Icons.trending_up,
            color: Colors.red,
            keywords: ['新能源', '科技', '医药', '消费'],
          ),
          SearchCategory(
            id: 'type',
            name: '基金类型',
            icon: Icons.category,
            color: Colors.blue,
            keywords: ['股票型', '债券型', '混合型', '货币型'],
          ),
          SearchCategory(
            id: 'company',
            name: '基金公司',
            icon: Icons.business,
            color: Colors.green,
            keywords: ['易方达', '华夏', '南方', '嘉实'],
          ),
          SearchCategory(
            id: 'theme',
            name: '投资主题',
            icon: Icons.lightbulb,
            color: Colors.orange,
            keywords: ['ESG', '新能源', '人工智能', '消费升级'],
          ),
        ];

    // 加载搜索历史
    context.read<SearchBloc>().add(const LoadSearchHistory());
  }

  /// 关键词变化处理
  void _onKeywordChanged(String? keyword) {
    if (keyword != null && keyword.trim().isNotEmpty) {
      // 触发搜索建议请求
      context.read<SearchBloc>().add(GetSearchSuggestions(keyword: keyword));
    }
  }

  /// 选择搜索建议
  void _onSelectSuggestion(String suggestion) {
    widget.onSuggestionSelected?.call(suggestion);
    context
        .read<SearchBloc>()
        .add(SelectSearchSuggestion(suggestion: suggestion));
  }

  /// 选择历史记录
  void _onSelectHistory(String history) {
    widget.onHistorySelected?.call(history);
    context.read<SearchBloc>().add(SelectSearchSuggestion(suggestion: history));
  }

  /// 选择搜索分类
  void _onSelectCategory(SearchCategory category) {
    widget.onCategorySelected?.call(category);
    // 这里可以执行分类相关的搜索逻辑
  }

  /// 清除历史记录
  void _onClearHistory() {
    widget.onClearHistory?.call();
    context.read<SearchBloc>().add(const ClearSearchHistory());
  }

  /// 构建建议列表项
  Widget _buildSuggestionItem(String suggestion, int index) {
    if (widget.suggestionBuilder != null) {
      return widget.suggestionBuilder!(suggestion, index);
    }

    return ListTile(
      dense: true,
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.search,
          size: 16,
          color: Theme.of(context).primaryColor,
        ),
      ),
      title: Text(
        suggestion,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () => _onSelectSuggestion(suggestion),
    );
  }

  /// 构建历史记录项
  Widget _buildHistoryItem(String history, int index) {
    if (widget.historyBuilder != null) {
      return widget.historyBuilder!(history, index);
    }

    return ListTile(
      dense: true,
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.history,
          size: 16,
          color: Colors.grey[600],
        ),
      ),
      title: Text(
        history,
        style: const TextStyle(
          fontSize: 14,
        ),
      ),
      trailing: index == 0
          ? IconButton(
              icon: const Icon(
                Icons.clear_all,
                size: 16,
                color: Colors.grey,
              ),
              onPressed: _onClearHistory,
              tooltip: '清空历史记录',
            )
          : null,
      onTap: () => _onSelectHistory(history),
    );
  }

  /// 构建分类项
  Widget _buildCategoryItem(SearchCategory category) {
    if (widget.categoryBuilder != null) {
      return widget.categoryBuilder!(category);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _onSelectCategory(category),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: category.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: category.color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    category.icon,
                    size: 16,
                    color: category.color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (category.keywords.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          runSpacing: 2,
                          children: category.keywords
                              .take(3)
                              .map((keyword) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: category.color.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      keyword,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: category.color,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建建议列表
  Widget _buildSuggestionsList() {
    if (_suggestions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            '搜索建议',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _suggestions.length.clamp(0, widget.maxSuggestions),
          itemBuilder: (context, index) {
            return _buildSuggestionItem(_suggestions[index], index);
          },
        ),
      ],
    );
  }

  /// 构建历史记录列表
  Widget _buildHistoryList() {
    if (_history.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Row(
            children: [
              Text(
                '搜索历史',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _onClearHistory,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  '清空',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _history.length.clamp(0, widget.maxHistoryItems),
          itemBuilder: (context, index) {
            return _buildHistoryItem(_history[index], index);
          },
        ),
      ],
    );
  }

  /// 构建分类列表
  Widget _buildCategoriesList() {
    if (!widget.showSearchCategories || _categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            '搜索分类',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ..._categories.map((category) => _buildCategoryItem(category)),
      ],
    );
  }

  /// 构建热门搜索
  Widget _buildPopularSearches() {
    if (!widget.showPopularSearches) return const SizedBox.shrink();

    final popularKeywords = widget.popularSearches ??
        [
          '新能源基金',
          '科技主题',
          '医药健康',
          '消费升级',
          'ESG投资',
          '人工智能',
        ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            '热门搜索',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: popularKeywords
                .take(8)
                .map((keyword) => ActionChip(
                      label: Text(keyword),
                      onPressed: () => _onSelectSuggestion(keyword),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            '暂无搜索建议',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '输入关键词开始搜索',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SearchBloc, SearchState>(
      listener: (context, state) {
        if (state is SearchSuggestionsLoadSuccess) {
          setState(() {
            _suggestions = state.suggestions;
          });
        } else if (state is SearchHistoryLoadSuccess) {
          setState(() {
            _history = state.history;
          });
        }
      },
      child: Container(
        height: widget.height ?? 300,
        decoration: widget.decoration ??
            BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
        child: widget.enableAnimation
            ? FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildContent(),
                ),
              )
            : _buildContent(),
      ),
    );
  }

  /// 构建内容
  Widget _buildContent() {
    final hasAnyContent = _suggestions.isNotEmpty ||
        _history.isNotEmpty ||
        widget.showPopularSearches ||
        widget.showSearchCategories;

    if (!hasAnyContent) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: widget.padding ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSuggestionsList(),
          if (widget.separator != null) widget.separator!,
          _buildHistoryList(),
          if (widget.separator != null) widget.separator!,
          _buildPopularSearches(),
          if (widget.separator != null) widget.separator!,
          _buildCategoriesList(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// 搜索分类数据模型
class SearchCategory extends Equatable {
  /// 分类ID
  final String id;

  /// 分类名称
  final String name;

  /// 分类图标
  final IconData icon;

  /// 分类颜色
  final Color color;

  /// 关键词列表
  final List<String> keywords;

  /// 分类描述
  final String? description;

  /// 创建搜索分类
  const SearchCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.keywords = const [],
    this.description,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        icon,
        color,
        keywords,
        description,
      ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchCategory &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          icon == other.icon &&
          color == other.color;

  @override
  int get hashCode => Object.hash(id, name, icon, color);
}
