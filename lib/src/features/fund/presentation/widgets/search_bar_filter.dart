import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 基金搜索栏组件
///
/// 支持基金代码、基金名称、基金公司等多种搜索方式。
/// 提供搜索建议、历史记录、快捷搜索等功能。
class SearchBarFilter extends StatefulWidget {
  /// 当前搜索文本
  final String? searchText;

  /// 占位符文本
  final String? placeholder;

  /// 搜索回调
  final ValueChanged<String>? onSearch;

  /// 清除回调
  final VoidCallback? onClear;

  /// 焦点变化回调
  final ValueChanged<bool>? onFocusChanged;

  /// 搜索建议列表
  final List<String>? suggestions;

  /// 搜索建议点击回调
  final ValueChanged<String>? onSuggestionSelected;

  /// 搜索历史列表
  final List<String>? history;

  /// 历史记录点击回调
  final ValueChanged<String>? onHistorySelected;

  /// 清除历史记录回调
  final VoidCallback? onClearHistory;

  /// 是否显示搜索按钮
  final bool showSearchButton;

  /// 是否显示清除按钮
  final bool showClearButton;

  /// 是否自动搜索
  final bool autoSearch;

  /// 自动搜索延迟时间
  final Duration autoSearchDelay;

  /// 输入框样式
  final InputDecoration? decoration;

  /// 是否启用
  final bool enabled;

  /// 最大输入长度
  final int? maxLength;

  /// 输入格式化
  final List<TextInputFormatter>? inputFormatters;

  /// 键盘类型
  final TextInputType keyboardType;

  /// 文本大写
  final TextCapitalization textCapitalization;

  /// 搜索模式
  final SearchMode searchMode;

  /// 快捷筛选选项
  final List<QuickFilterOption>? quickFilters;

  /// 快捷筛选回调
  final ValueChanged<String>? onQuickFilterSelected;

  const SearchBarFilter({
    super.key,
    this.searchText,
    this.placeholder = '搜索基金代码、名称或公司',
    this.onSearch,
    this.onClear,
    this.onFocusChanged,
    this.suggestions,
    this.onSuggestionSelected,
    this.history,
    this.onHistorySelected,
    this.onClearHistory,
    this.showSearchButton = true,
    this.showClearButton = true,
    this.autoSearch = true,
    this.autoSearchDelay = const Duration(milliseconds: 500),
    this.decoration,
    this.enabled = true,
    this.maxLength,
    this.inputFormatters,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.searchMode = SearchMode.keyword,
    this.quickFilters,
    this.onQuickFilterSelected,
  });

  @override
  State<SearchBarFilter> createState() => _SearchBarFilterState();
}

class _SearchBarFilterState extends State<SearchBarFilter> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  Timer? _autoSearchTimer;
  bool _hasFocus = false;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.searchText ?? '');
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChanged);
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(SearchBarFilter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchText != oldWidget.searchText &&
        widget.searchText != _controller.text) {
      _controller.text = widget.searchText ?? '';
    }
  }

  @override
  void dispose() {
    _autoSearchTimer?.cancel();
    _removeOverlay();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    final hasFocus = _focusNode.hasFocus;
    if (hasFocus != _hasFocus) {
      setState(() {
        _hasFocus = hasFocus;
      });
      widget.onFocusChanged?.call(hasFocus);

      if (hasFocus) {
        _showOverlay();
      } else {
        _removeOverlay();
      }
    }
  }

  void _onTextChanged() {
    final text = _controller.text;

    // 自动搜索
    if (widget.autoSearch && widget.onSearch != null) {
      _autoSearchTimer?.cancel();
      _autoSearchTimer = Timer(widget.autoSearchDelay, () {
        widget.onSearch!(text);
      });
    }

    // 更新覆盖层内容
    if (_hasFocus) {
      _updateOverlay();
    }
  }

  void _onSearchSubmitted(String text) {
    _autoSearchTimer?.cancel();
    widget.onSearch?.call(text);
    _focusNode.unfocus();
  }

  void _onClear() {
    _controller.clear();
    widget.onClear?.call();
    if (!widget.autoSearch) {
      widget.onSearch?.call('');
    }
  }

  void _onSuggestionSelected(String suggestion) {
    _controller.text = suggestion;
    widget.onSuggestionSelected?.call(suggestion);
    _onSearchSubmitted(suggestion);
  }

  void _onHistorySelected(String history) {
    _controller.text = history;
    widget.onHistorySelected?.call(history);
    _onSearchSubmitted(history);
  }

  void _onQuickFilterSelected(String filter) {
    _controller.text = filter;
    widget.onQuickFilterSelected?.call(filter);
    _onSearchSubmitted(filter);
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => _buildOverlay(),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _updateOverlay() {
    _overlayEntry?.markNeedsBuild();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildOverlay() {
    return Positioned(
      top: 60, // 根据实际位置调整
      left: 16,
      right: 16,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 300),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: _buildOverlayContent(),
        ),
      ),
    );
  }

  Widget _buildOverlayContent() {
    final text = _controller.text.trim();
    final hasText = text.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 快捷筛选
        if (widget.quickFilters != null && !hasText) ...[
          _buildQuickFilters(),
          const Divider(height: 1),
        ],

        // 搜索建议
        if (hasText && widget.suggestions?.isNotEmpty == true) ...[
          _buildSuggestions(),
          const Divider(height: 1),
        ],

        // 搜索历史
        if (!hasText && widget.history?.isNotEmpty == true) ...[
          _buildHistory(),
        ],
      ],
    );
  }

  Widget _buildQuickFilters() {
    return ListView.separated(
      shrinkWrap: true,
      itemCount: widget.quickFilters!.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final filter = widget.quickFilters![index];
        return ListTile(
          dense: true,
          leading: Icon(
            filter.icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(
            filter.label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          onTap: () => _onQuickFilterSelected(filter.value),
        );
      },
    );
  }

  Widget _buildSuggestions() {
    final text = _controller.text.trim();
    final suggestions = widget.suggestions!
        .where((s) => s.toLowerCase().contains(text.toLowerCase()))
        .take(10)
        .toList();

    if (suggestions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('暂无建议'),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: suggestions.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final suggestion = suggestions[index];
        return ListTile(
          dense: true,
          leading: const Icon(Icons.search, size: 20),
          title: RichText(
            text: _buildHighlightedText(suggestion, text),
          ),
          onTap: () => _onSuggestionSelected(suggestion),
        );
      },
    );
  }

  Widget _buildHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.history, size: 16),
              const SizedBox(width: 8),
              Text(
                '搜索历史',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const Spacer(),
              if (widget.onClearHistory != null)
                TextButton(
                  onPressed: widget.onClearHistory,
                  child: const Text('清除'),
                ),
            ],
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          itemCount: widget.history!.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            return ListTile(
              dense: true,
              leading: const Icon(Icons.history, size: 20),
              title: Text(widget.history![index]),
              trailing: IconButton(
                icon: const Icon(Icons.keyboard_arrow_up, size: 20),
                onPressed: () => _onHistorySelected(widget.history![index]),
              ),
              onTap: () => _onHistorySelected(widget.history![index]),
            );
          },
        ),
      ],
    );
  }

  TextSpan _buildHighlightedText(String text, String highlight) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium!;
    final highlightedStyle = style.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w600,
    );

    if (highlight.isEmpty) {
      return TextSpan(text: text, style: style);
    }

    final List<TextSpan> spans = [];
    int start = 0;
    final lowerText = text.toLowerCase();
    final lowerHighlight = highlight.toLowerCase();

    while (true) {
      final index = lowerText.indexOf(lowerHighlight, start);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start), style: style));
        break;
      }

      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index), style: style));
      }

      spans.add(TextSpan(
        text: text.substring(index, index + highlight.length),
        style: highlightedStyle,
      ));

      start = index + highlight.length;
    }

    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      children: [
        // 搜索栏
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  _hasFocus ? colors.primary : colors.outline.withOpacity(0.3),
              width: _hasFocus ? 2 : 1,
            ),
            boxShadow: _hasFocus
                ? [
                    BoxShadow(
                      color: colors.primary.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            maxLength: widget.maxLength,
            inputFormatters: widget.inputFormatters,
            keyboardType: widget.keyboardType,
            textCapitalization: widget.textCapitalization,
            decoration: widget.decoration?.copyWith(
                  hintText: widget.placeholder,
                  prefixIcon:
                      widget.showSearchButton ? const Icon(Icons.search) : null,
                  suffixIcon: _buildSuffixIcon(),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ) ??
                InputDecoration(
                  hintText: widget.placeholder,
                  prefixIcon:
                      widget.showSearchButton ? const Icon(Icons.search) : null,
                  suffixIcon: _buildSuffixIcon(),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
            onSubmitted: _onSearchSubmitted,
          ),
        ),

        // 搜索模式切换
        if (widget.searchMode != SearchMode.keyword) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              _buildSearchModeChip(SearchMode.keyword, '关键词'),
              const SizedBox(width: 8),
              _buildSearchModeChip(SearchMode.exact, '精确匹配'),
              const SizedBox(width: 8),
              _buildSearchModeChip(SearchMode.fuzzy, '模糊搜索'),
            ],
          ),
        ],
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    final hasText = _controller.text.isNotEmpty;

    if (!hasText && widget.showClearButton) {
      return null;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasText && widget.showClearButton)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _onClear,
            tooltip: '清除',
          ),
      ],
    );
  }

  Widget _buildSearchModeChip(SearchMode mode, String label) {
    final isSelected = widget.searchMode == mode;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          // 这里可以添加搜索模式切换的逻辑
        }
      },
      selectedColor: colors.primary.withOpacity(0.1),
      backgroundColor: colors.surfaceVariant.withOpacity(0.5),
      labelStyle: TextStyle(
        color: isSelected ? colors.primary : colors.onSurface,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(
          color: isSelected ? colors.primary : colors.outline,
        ),
      ),
    );
  }
}

/// 搜索模式枚举
enum SearchMode {
  /// 关键词搜索
  keyword,

  /// 精确匹配
  exact,

  /// 模糊搜索
  fuzzy,
}

/// 快捷筛选选项
class QuickFilterOption {
  final String label;
  final String value;
  final IconData icon;
  final String? description;

  QuickFilterOption({
    required this.label,
    required this.value,
    required this.icon,
    this.description,
  });
}
