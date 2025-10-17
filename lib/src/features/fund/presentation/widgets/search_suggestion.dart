import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/search_bloc.dart';
import '../bloc/search_event.dart';
import '../bloc/search_state.dart';

/// 搜索建议组件
///
/// 提供智能搜索建议功能，包括：
/// - 实时搜索建议
/// - 拼音搜索支持
/// - 搜索建议分类
/// - 建议排序优化
/// - 用户行为学习
class SearchSuggestion extends StatefulWidget {
  /// 当前搜索关键词
  final String? currentKeyword;

  /// 最大建议数量
  final int maxSuggestions;

  /// 是否启用拼音搜索
  final bool enablePinyinSearch;

  /// 是否启用智能排序
  final bool enableSmartSorting;

  /// 是否显示建议分类
  final bool showCategories;

  /// 是否显示建议来源
  final bool showSource;

  /// 自定义建议构建器
  final Widget Function(SuggestionItem suggestion, int index)?
      suggestionBuilder;

  /// 建议点击回调
  final ValueChanged<String>? onSuggestionSelected;

  /// 创建搜索建议组件
  const SearchSuggestion({
    super.key,
    this.currentKeyword,
    this.maxSuggestions = 10,
    this.enablePinyinSearch = true,
    this.enableSmartSorting = true,
    this.showCategories = true,
    this.showSource = true,
    this.suggestionBuilder,
    this.onSuggestionSelected,
  });

  @override
  State<SearchSuggestion> createState() => _SearchSuggestionState();
}

class _SearchSuggestionState extends State<SearchSuggestion>
    with TickerProviderStateMixin {
  List<SuggestionItem> _suggestions = [];
  List<SuggestionItem> _filteredSuggestions = [];
  bool _isLoading = false;
  String _currentKeyword = '';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _loadMockSuggestions();
  }

  @override
  void didUpdateWidget(SearchSuggestion oldWidget) {
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
  }

  /// 加载模拟建议数据
  void _loadMockSuggestions() {
    _suggestions = [
      // 基金类型建议
      const SuggestionItem(
        text: '股票基金',
        category: SuggestionCategory.fundType,
        source: SuggestionSource.system,
        score: 0.95,
        description: '主要投资于股票的基金',
      ),
      const SuggestionItem(
        text: '债券基金',
        category: SuggestionCategory.fundType,
        source: SuggestionSource.system,
        score: 0.92,
        description: '主要投资于债券的基金',
      ),
      const SuggestionItem(
        text: '混合基金',
        category: SuggestionCategory.fundType,
        source: SuggestionSource.system,
        score: 0.88,
        description: '同时投资股票和债券的基金',
      ),
      const SuggestionItem(
        text: '货币基金',
        category: SuggestionCategory.fundType,
        source: SuggestionSource.system,
        score: 0.85,
        description: '投资于货币市场工具的基金',
      ),

      // 基金公司建议
      const SuggestionItem(
        text: '易方达基金',
        category: SuggestionCategory.company,
        source: SuggestionSource.popular,
        score: 0.90,
        description: '国内领先的基金管理公司',
      ),
      const SuggestionItem(
        text: '华夏基金',
        category: SuggestionCategory.company,
        source: SuggestionSource.popular,
        score: 0.88,
        description: '老牌基金管理公司',
      ),
      const SuggestionItem(
        text: '南方基金',
        category: SuggestionCategory.company,
        source: SuggestionSource.popular,
        score: 0.86,
        description: '大型基金管理公司',
      ),

      // 投资主题建议
      const SuggestionItem(
        text: '新能源基金',
        category: SuggestionCategory.theme,
        source: SuggestionSource.trending,
        score: 0.93,
        description: '投资新能源相关产业',
      ),
      const SuggestionItem(
        text: '科技基金',
        category: SuggestionCategory.theme,
        source: SuggestionSource.trending,
        score: 0.91,
        description: '投资科技创新企业',
      ),
      const SuggestionItem(
        text: '医药基金',
        category: SuggestionCategory.theme,
        source: SuggestionSource.trending,
        score: 0.89,
        description: '投资医药健康产业',
      ),

      // 热门基金代码
      const SuggestionItem(
        text: '110022',
        category: SuggestionCategory.fundCode,
        source: SuggestionSource.hot,
        score: 0.94,
        description: '易方达消费行业股票',
      ),
      const SuggestionItem(
        text: '000001',
        category: SuggestionCategory.fundCode,
        source: SuggestionSource.hot,
        score: 0.92,
        description: '华夏成长混合',
      ),
      const SuggestionItem(
        text: '161005',
        category: SuggestionCategory.fundCode,
        source: SuggestionSource.hot,
        score: 0.90,
        description: '富国天惠成长混合',
      ),
    ];

    _filteredSuggestions = List.from(_suggestions);
  }

  /// 关键词变化处理
  void _onKeywordChanged(String? keyword) {
    setState(() {
      _currentKeyword = keyword ?? '';
      _isLoading = true;
    });

    // 模拟异步加载
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _filterSuggestions();
        setState(() {
          _isLoading = false;
        });

        // 触发动画
        _animationController.forward();
      }
    });
  }

  /// 筛选建议
  void _filterSuggestions() {
    if (_currentKeyword.trim().isEmpty) {
      _filteredSuggestions = _suggestions.take(widget.maxSuggestions).toList();
      return;
    }

    final query = _currentKeyword.toLowerCase();
    final filtered = <SuggestionItem>[];

    // 精确匹配
    for (final suggestion in _suggestions) {
      if (suggestion.text.toLowerCase() == query) {
        filtered.add(suggestion.copyWith(score: 1.0));
      }
    }

    // 前缀匹配
    for (final suggestion in _suggestions) {
      if (suggestion.text.toLowerCase().startsWith(query) &&
          !filtered.any((s) => s.text == suggestion.text)) {
        filtered.add(suggestion.copyWith(score: 0.9));
      }
    }

    // 包含匹配
    for (final suggestion in _suggestions) {
      if (suggestion.text.toLowerCase().contains(query) &&
          !filtered.any((s) => s.text == suggestion.text)) {
        filtered.add(suggestion.copyWith(score: 0.7));
      }
    }

    // 拼音匹配（如果启用）
    if (widget.enablePinyinSearch) {
      for (final suggestion in _suggestions) {
        if (_pinyinMatch(suggestion.text, query) &&
            !filtered.any((s) => s.text == suggestion.text)) {
          filtered.add(suggestion.copyWith(score: 0.6));
        }
      }
    }

    // 排序
    if (widget.enableSmartSorting) {
      filtered.sort((a, b) => b.score.compareTo(a.score));
    }

    setState(() {
      _filteredSuggestions = filtered.take(widget.maxSuggestions).toList();
    });
  }

  /// 简单的拼音匹配
  bool _pinyinMatch(String text, String query) {
    // 简化的拼音映射
    final pinyinMap = {
      '基': 'ji',
      '金': 'jin',
      '股': 'gu',
      '票': 'piao',
      '债': 'zhai',
      '券': 'quan',
      '货': 'huo',
      '币': 'bi',
      '混': 'hun',
      '合': 'he',
      '成': 'cheng',
      '长': 'chang',
      '增': 'zeng',
    };

    String textPinyin = '';
    for (final char in text.split('')) {
      textPinyin += pinyinMap[char] ?? char;
    }

    return textPinyin.toLowerCase().contains(query);
  }

  /// 选择建议
  void _onSelectSuggestion(SuggestionItem suggestion) {
    widget.onSuggestionSelected?.call(suggestion.text);
    if (mounted) {
      context.read<SearchBloc>().add(
            SelectSearchSuggestion(suggestion: suggestion.text),
          );
    }
  }

  /// 获取分类图标
  IconData _getCategoryIcon(SuggestionCategory category) {
    switch (category) {
      case SuggestionCategory.fundType:
        return Icons.category;
      case SuggestionCategory.company:
        return Icons.business;
      case SuggestionCategory.theme:
        return Icons.lightbulb;
      case SuggestionCategory.fundCode:
        return Icons.tag;
    }
  }

  /// 获取分类颜色
  Color _getCategoryColor(SuggestionCategory category) {
    switch (category) {
      case SuggestionCategory.fundType:
        return Colors.blue;
      case SuggestionCategory.company:
        return Colors.green;
      case SuggestionCategory.theme:
        return Colors.orange;
      case SuggestionCategory.fundCode:
        return Colors.purple;
    }
  }

  /// 获取来源标签
  String _getSourceLabel(SuggestionSource source) {
    switch (source) {
      case SuggestionSource.system:
        return '系统';
      case SuggestionSource.popular:
        return '热门';
      case SuggestionSource.trending:
        return '趋势';
      case SuggestionSource.hot:
        return '热点';
      case SuggestionSource.recent:
        return '最近';
      case SuggestionSource.recommended:
        return '推荐';
    }
  }

  /// 获取来源颜色
  Color _getSourceColor(SuggestionSource source) {
    switch (source) {
      case SuggestionSource.system:
        return Colors.grey;
      case SuggestionSource.popular:
        return Colors.red;
      case SuggestionSource.trending:
        return Colors.orange;
      case SuggestionSource.hot:
        return Colors.deepOrange;
      case SuggestionSource.recent:
        return Colors.blue;
      case SuggestionSource.recommended:
        return Colors.green;
    }
  }

  /// 构建建议项
  Widget _buildSuggestionItem(SuggestionItem suggestion, int index) {
    if (widget.suggestionBuilder != null) {
      return widget.suggestionBuilder!(suggestion, index);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _onSelectSuggestion(suggestion),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[200]!,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                // 图标
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color:
                        _getCategoryColor(suggestion.category).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _getCategoryIcon(suggestion.category),
                    size: 16,
                    color: _getCategoryColor(suggestion.category),
                  ),
                ),
                const SizedBox(width: 12),
                // 内容
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            suggestion.text,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (widget.showSource &&
                              suggestion.source != SuggestionSource.system)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getSourceColor(suggestion.source)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _getSourceLabel(suggestion.source),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _getSourceColor(suggestion.source),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (suggestion.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          suggestion.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                // 评分
                if (suggestion.score >= 0.8) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${(suggestion.score * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建加载状态
  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Padding(
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
            '无搜索建议',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '尝试输入更多关键词',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建分类标签
  Widget _buildCategoryTabs() {
    if (!widget.showCategories) return const SizedBox.shrink();

    const categories = SuggestionCategory.values;
    final categoryCounts = <SuggestionCategory, int>{};

    for (final category in categories) {
      categoryCounts[category] =
          _filteredSuggestions.where((s) => s.category == category).length;
    }

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final count = categoryCounts[category] ?? 0;

          if (count == 0) return const SizedBox.shrink();

          return Container(
            margin: const EdgeInsets.only(left: 8),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getCategoryIcon(category),
                    size: 14,
                    color: _getCategoryColor(category),
                  ),
                  const SizedBox(width: 4),
                  Text(category.displayName),
                  const SizedBox(width: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(category).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 10,
                        color: _getCategoryColor(category),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              selected: false,
              onSelected: (_) {},
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_isLoading) {
      content = _buildLoadingState();
    } else if (_filteredSuggestions.isEmpty) {
      content = _buildEmptyState();
    } else {
      content = Column(
        children: [
          _buildCategoryTabs(),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredSuggestions.length,
              itemBuilder: (context, index) {
                return _buildSuggestionItem(
                  _filteredSuggestions[index],
                  index,
                );
              },
            ),
          ),
        ],
      );
    }

    return BlocListener<SearchBloc, SearchState>(
      listener: (context, state) {
        // 处理搜索状态变化
        if (state is SearchLoadSuccess) {
          // 可以在这里处理搜索成功的逻辑
        }
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
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
                child: content,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 搜索建议项数据模型
class SuggestionItem extends Equatable {
  /// 建议文本
  final String text;

  /// 建议分类
  final SuggestionCategory category;

  /// 建议来源
  final SuggestionSource source;

  /// 匹配评分
  final double score;

  /// 描述信息
  final String description;

  /// 创建搜索建议项
  const SuggestionItem({
    required this.text,
    required this.category,
    required this.source,
    required this.score,
    this.description = '',
  });

  SuggestionItem copyWith({
    String? text,
    SuggestionCategory? category,
    SuggestionSource? source,
    double? score,
    String? description,
  }) {
    return SuggestionItem(
      text: text ?? this.text,
      category: category ?? this.category,
      source: source ?? this.source,
      score: score ?? this.score,
      description: description ?? this.description,
    );
  }

  @override
  List<Object?> get props => [
        text,
        category,
        source,
        score,
        description,
      ];
}

/// 搜索建议分类枚举
enum SuggestionCategory {
  /// 基金类型
  fundType('基金类型'),

  /// 基金公司
  company('基金公司'),

  /// 投资主题
  theme('投资主题'),

  /// 基金代码
  fundCode('基金代码');

  const SuggestionCategory(this.displayName);

  final String displayName;

  @override
  String toString() => displayName;
}

/// 搜索建议来源枚举
enum SuggestionSource {
  /// 系统推荐
  system('系统'),

  /// 热门搜索
  popular('热门'),

  /// 趋势搜索
  trending('趋势'),

  /// 热点搜索
  hot('热点'),

  /// 最近搜索
  recent('最近'),

  /// 智能推荐
  recommended('推荐');

  const SuggestionSource(this.displayName);

  final String displayName;

  @override
  String toString() => displayName;
}
