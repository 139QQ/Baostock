import 'package:flutter/material.dart';

/// 基金搜索栏组�?
///
/// 功能特性：
/// - 支持基金名称、代码、基金经理、基金公司搜�?
/// - 实时搜索建议
/// - 搜索历史记录
/// - 高级筛选入�?
class FundSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSearch;
  final VoidCallback onAdvancedFilter;
  final List<String>? searchHistory;
  final Function(String)? onSearchHistorySelected;

  const FundSearchBar({
    super.key,
    required this.controller,
    required this.onSearch,
    required this.onAdvancedFilter,
    this.searchHistory,
    this.onSearchHistorySelected,
  });

  @override
  State<FundSearchBar> createState() => _FundSearchBarState();
}

class _FundSearchBarState extends State<FundSearchBar> {
  final FocusNode _focusNode = FocusNode();
  bool _showSuggestions = false;
  List<String> _suggestions = [];
  bool _isSearching = false;

  // 模拟搜索建议数据
  static const List<String> _mockSuggestions = [
    '易方达蓝筹精选混合',
    '易方达中小盘混合',
    '张坤',
    '易方达基金',
    '富国天惠成长混合',
    '朱少醒',
    '富国基金',
    '景顺长城新兴成长混合',
    '刘彦春',
    '景顺长城基金',
    '中证白酒指数',
    '中证消费指数',
    '科技ETF',
    '新能源车ETF',
    '医药ETF',
  ];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      _showSuggestions =
          _focusNode.hasFocus && widget.controller.text.isNotEmpty;
    });
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    if (text.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    // 生成搜索建议
    _generateSuggestions(text);

    setState(() {
      _showSuggestions = _focusNode.hasFocus;
    });
  }

  void _generateSuggestions(String query) {
    if (query.length < 2) {
      _suggestions = [];
      return;
    }

    // 智能搜索建议生成
    final suggestions = <String>[];

    // 1. 历史搜索记录匹配
    if (widget.searchHistory != null) {
      final historyMatches = widget.searchHistory!
          .where((item) => item.toLowerCase().contains(query.toLowerCase()))
          .take(3)
          .toList();
      suggestions.addAll(historyMatches);
    }

    // 2. 基金名称和代码匹�?
    final fundMatches = _mockSuggestions
        .where((item) => item.toLowerCase().contains(query.toLowerCase()))
        .take(5)
        .toList();
    suggestions.addAll(fundMatches);

    // 3. 拼音首字母匹�?
    final pinyinMatches = _mockSuggestions
        .where((item) => _matchPinyin(item, query))
        .take(2)
        .toList();
    suggestions.addAll(pinyinMatches);

    // 去重并限制数�?
    _suggestions = suggestions.toSet().take(8).toList();
  }

  bool _matchPinyin(String text, String query) {
    // 简化的拼音匹配逻辑
    // 实际项目中可以使用拼音库
    final pinyinMap = {
      '易方达': 'yfd',
      '蓝筹': 'lc',
      '精选': 'jx',
      '混合': 'hh',
      '中小盘': 'zxp',
      '张坤': 'zk',
      '富国': 'fg',
      '天惠': 'th',
      '成长': 'cz',
      '朱少醒': 'zsx',
      '景顺': 'js',
      '长城': 'cc',
      '新兴': 'xx',
      '刘彦春': 'lyc',
    };

    for (final entry in pinyinMap.entries) {
      if (text.contains(entry.key) &&
          entry.value.startsWith(query.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  void _handleSearch(String query) {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _showSuggestions = false;
    });

    // 延迟执行搜索，优化用户体�?
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        widget.onSearch(query.trim());
      }
    });
  }

  void _handleSuggestionTap(String suggestion) {
    widget.controller.text = suggestion;
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );

    _handleSearch(suggestion);

    // 通知父组件选择了历史搜�?
    if (widget.searchHistory?.contains(suggestion) == true) {
      widget.onSearchHistorySelected?.call(suggestion);
    }
  }

  void _clearSearch() {
    widget.controller.clear();
    _focusNode.unfocus();
    setState(() {
      _suggestions = [];
      _showSuggestions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Stack(
        children: [
          // 搜索输入�?
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // 搜索图标
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child:
                      Icon(Icons.search, color: Colors.grey.shade600, size: 20),
                ),

                // 搜索输入�?
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: '搜索基金名称、代码、基金经理、基金公司',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      suffixIcon: widget.controller.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: _clearSearch,
                            )
                          : null,
                    ),
                    style: const TextStyle(fontSize: 14),
                    textInputAction: TextInputAction.search,
                    onSubmitted: _handleSearch,
                    onTap: () {
                      setState(() {
                        _showSuggestions = widget.controller.text.isNotEmpty;
                      });
                    },
                  ),
                ),

                // 加载指示�?
                if (_isSearching)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),

                // 分割�?
                Container(
                  width: 1,
                  height: 24,
                  color: Colors.grey.shade300,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),

                // 高级筛选按�?
                IconButton(
                  icon: Icon(
                    Icons.filter_list,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                  onPressed: widget.onAdvancedFilter,
                  tooltip: '高级筛选',
                ),
              ],
            ),
          ),

          // 搜索建议下拉�?
          if (_showSuggestions && _suggestions.isNotEmpty)
            Positioned(
              top: 52,
              left: 0,
              right: 0,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 搜索建议标题
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '搜索建议',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 建议列表
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: _suggestions.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            color: Colors.grey.shade200,
                          ),
                          itemBuilder: (context, index) {
                            final suggestion = _suggestions[index];
                            return ListTile(
                              dense: true,
                              leading: Icon(
                                Icons.search,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              title: Text(
                                suggestion,
                                style: const TextStyle(fontSize: 14),
                              ),
                              trailing:
                                  widget.searchHistory?.contains(suggestion) ==
                                          true
                                      ? Icon(
                                          Icons.history,
                                          size: 16,
                                          color: Colors.grey.shade400,
                                        )
                                      : null,
                              onTap: () => _handleSuggestionTap(suggestion),
                            );
                          },
                        ),
                      ),

                      // 关闭建议按钮
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _showSuggestions = false;
                            });
                            _focusNode.unfocus();
                          },
                          child: Text(
                            '关闭建议',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
