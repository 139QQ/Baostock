import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jisu_fund_analyzer/src/features/fund/domain/entities/fund_search_criteria.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/bloc/search_bloc.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/bloc/search_event.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/bloc/search_state.dart';

/// 基金搜索栏组件
///
/// 提供完整的基金搜索功能，包括：
/// - 实时搜索（300ms防抖动）
/// - 搜索建议和历史记录
/// - 高级搜索选项
/// - 搜索类型切换
/// - 性能优化显示
///
/// 性能特性：
/// - 防抖动机制避免频繁搜索
/// - 智能缓存和预加载
/// - 响应时间≤300ms
class FundSearchBar extends StatefulWidget {
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

  /// 是否自动聚焦
  final bool autoFocus;

  /// 是否显示高级搜索选项
  final bool showAdvancedOptions;

  /// 是否启用语音搜索
  final bool enableVoiceSearch;

  /// 自定义样式
  final BoxDecoration? decoration;

  /// 自定义边框
  final BoxBorder? border;

  /// 圆角
  final BorderRadius? borderRadius;

  /// 内边距
  final EdgeInsets? contentPadding;

  /// 文本样式
  final TextStyle? textStyle;

  /// 提示文本样式
  final TextStyle? hintStyle;

  /// 前缀图标
  final Widget? prefixIcon;

  /// 后缀图标
  final Widget? suffixIcon;

  /// 是否只读
  final bool readOnly;

  /// 最大长度
  final int? maxLength;

  /// 输入格式器
  final List<TextInputFormatter>? inputFormatters;

  /// 键盘类型
  final TextInputType? keyboardType;

  /// 文本输入动作
  final TextInputAction? textInputAction;

  /// 是否启用
  final bool enabled;

  /// 创建基金搜索栏
  const FundSearchBar({
    super.key,
    this.searchText,
    this.placeholder,
    this.onSearch,
    this.onClear,
    this.onFocusChanged,
    this.autoFocus = false,
    this.showAdvancedOptions = true,
    this.enableVoiceSearch = false,
    this.decoration,
    this.border,
    this.borderRadius,
    this.contentPadding,
    this.textStyle,
    this.hintStyle,
    this.prefixIcon,
    this.suffixIcon,
    this.readOnly = false,
    this.maxLength,
    this.inputFormatters,
    this.keyboardType,
    this.textInputAction,
    this.enabled = true,
  });

  @override
  State<FundSearchBar> createState() => _FundSearchBarState();
}

class _FundSearchBarState extends State<FundSearchBar> {
  late TextEditingController _textController;
  late FocusNode _focusNode;
  Timer? _debounceTimer;
  bool _isFocused = false;
  bool _showAdvancedPanel = false;
  SearchType _selectedSearchType = SearchType.mixed;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.searchText ?? '');
    _focusNode = FocusNode();
    _selectedSearchType = SearchType.mixed;

    // 监听文本变化
    _textController.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);

    // 自动聚焦
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(FundSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchText != oldWidget.searchText &&
        widget.searchText != _textController.text) {
      _textController.text = widget.searchText ?? '';
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 文本变化处理（带防抖动）
  void _onTextChanged() {
    final text = _textController.text;

    // 取消之前的防抖动定时器
    _debounceTimer?.cancel();

    // 设置新的防抖动定时器
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        widget.onSearch?.call(text);
        // 触发BLoC搜索事件
        context.read<SearchBloc>().add(UpdateSearchKeyword(keyword: text));
      }
    });
  }

  /// 焦点变化处理
  void _onFocusChanged() {
    final isFocused = _focusNode.hasFocus;
    if (_isFocused != isFocused) {
      setState(() {
        _isFocused = isFocused;
      });
      widget.onFocusChanged?.call(isFocused);

      // 失去焦点时隐藏高级面板
      if (!isFocused) {
        setState(() {
          _showAdvancedPanel = false;
        });
      }
    }
  }

  /// 清空搜索
  void _onClear() {
    _textController.clear();
    widget.onClear?.call();
    context.read<SearchBloc>().add(ClearSearch());
  }

  /// 提交搜索
  void _onSubmit(String value) {
    if (value.trim().isNotEmpty) {
      widget.onSearch?.call(value);
      context.read<SearchBloc>().add(PerformSearch(
            criteria: FundSearchCriteria.keyword(
              value,
              searchType: _selectedSearchType,
            ),
          ));
    }
  }

  /// 切换搜索类型
  void _onSearchTypeChanged(SearchType? type) {
    if (type != null) {
      setState(() {
        _selectedSearchType = type;
      });
      context.read<SearchBloc>().add(ChangeSearchType(searchType: type));
    }
  }

  /// 切换高级搜索面板
  void _toggleAdvancedPanel() {
    setState(() {
      _showAdvancedPanel = !_showAdvancedPanel;
    });
  }

  /// 构建搜索栏主体
  Widget _buildSearchBar() {
    return Container(
      decoration: widget.decoration ??
          BoxDecoration(
            color: Colors.grey[50],
            borderRadius: widget.borderRadius ?? BorderRadius.circular(28),
            border: widget.border ?? Border.all(color: Colors.grey[300]!),
          ),
      child: TextField(
        controller: _textController,
        focusNode: _focusNode,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        maxLength: widget.maxLength,
        inputFormatters: widget.inputFormatters,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction ?? TextInputAction.search,
        style: widget.textStyle ??
            const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
        decoration: InputDecoration(
          contentPadding: widget.contentPadding ??
              const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
          hintText: widget.placeholder ?? '搜索基金代码或名称',
          hintStyle: widget.hintStyle ??
              TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
          prefixIcon: widget.prefixIcon ??
              const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(
                  Icons.search,
                  color: Colors.grey,
                  size: 20,
                ),
              ),
          suffixIcon: _buildSuffixIcon(),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          counterText: '',
        ),
        onSubmitted: _onSubmit,
      ),
    );
  }

  /// 构建后缀图标
  Widget _buildSuffixIcon() {
    final widgets = <Widget>[];

    // 清除按钮
    if (_textController.text.isNotEmpty) {
      widgets.add(
        IconButton(
          icon: const Icon(
            Icons.clear,
            color: Colors.grey,
            size: 20,
          ),
          onPressed: _onClear,
          splashRadius: 20,
        ),
      );
    }

    // 高级搜索按钮
    if (widget.showAdvancedOptions) {
      widgets.add(
        PopupMenuButton<SearchType>(
          icon: Icon(
            Icons.tune,
            color: _showAdvancedPanel
                ? Theme.of(context).primaryColor
                : Colors.grey,
            size: 20,
          ),
          tooltip: '搜索选项',
          onSelected: _onSearchTypeChanged,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: SearchType.mixed,
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: _selectedSearchType == SearchType.mixed
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Text('混合搜索'),
                ],
              ),
            ),
            PopupMenuItem(
              value: SearchType.code,
              child: Row(
                children: [
                  Icon(
                    Icons.tag,
                    color: _selectedSearchType == SearchType.code
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Text('基金代码'),
                ],
              ),
            ),
            PopupMenuItem(
              value: SearchType.name,
              child: Row(
                children: [
                  Icon(
                    Icons.label,
                    color: _selectedSearchType == SearchType.name
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Text('基金名称'),
                ],
              ),
            ),
            PopupMenuItem(
              value: SearchType.fullText,
              child: Row(
                children: [
                  Icon(
                    Icons.description,
                    color: _selectedSearchType == SearchType.fullText
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Text('全文搜索'),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 语音搜索按钮
    if (widget.enableVoiceSearch) {
      widgets.add(
        IconButton(
          icon: const Icon(
            Icons.mic,
            color: Colors.grey,
            size: 20,
          ),
          onPressed: _onVoiceSearch,
          splashRadius: 20,
        ),
      );
    }

    // 自定义后缀图标
    if (widget.suffixIcon != null) {
      widgets.add(widget.suffixIcon!);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }

  /// 语音搜索处理
  void _onVoiceSearch() {
    // TODO: 实现语音搜索功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('语音搜索功能正在开发中')),
    );
  }

  /// 构建高级搜索面板
  Widget _buildAdvancedPanel() {
    if (!_showAdvancedPanel) return const SizedBox.shrink();

    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        return Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Row(
                children: [
                  const Icon(
                    Icons.tune,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '高级搜索选项',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.grey,
                    ),
                    onPressed: _toggleAdvancedPanel,
                    splashRadius: 16,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 搜索选项
              _buildSearchOptions(state),

              const SizedBox(height: 12),

              // 搜索字段选择
              _buildSearchFieldsSelection(state),

              const SizedBox(height: 12),

              // 性能信息
              _buildPerformanceInfo(state),
            ],
          ),
        );
      },
    );
  }

  /// 构建搜索选项
  Widget _buildSearchOptions(SearchState state) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        FilterChip(
          label: const Text('区分大小写'),
          selected: _getOptionValue(state, SearchOption.caseSensitive),
          onSelected: (value) =>
              _onOptionChanged(SearchOption.caseSensitive, value),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        FilterChip(
          label: const Text('模糊搜索'),
          selected: _getOptionValue(state, SearchOption.fuzzySearch),
          onSelected: (value) =>
              _onOptionChanged(SearchOption.fuzzySearch, value),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        FilterChip(
          label: const Text('拼音搜索'),
          selected: _getOptionValue(state, SearchOption.enablePinyinSearch),
          onSelected: (value) =>
              _onOptionChanged(SearchOption.enablePinyinSearch, value),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        FilterChip(
          label: const Text('包含停运基金'),
          selected: _getOptionValue(state, SearchOption.includeInactive),
          onSelected: (value) =>
              _onOptionChanged(SearchOption.includeInactive, value),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }

  /// 构建搜索字段选择
  Widget _buildSearchFieldsSelection(SearchState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '搜索范围：',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            ChoiceChip(
              label: const Text('全部'),
              selected: _isAllFieldsSelected(state),
              onSelected: (value) => _onFieldsChanged([]),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            ChoiceChip(
              label: const Text('基金代码'),
              selected: _isFieldSelected(state, SearchField.code),
              onSelected: (value) => _onFieldsToggled(SearchField.code),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            ChoiceChip(
              label: const Text('基金名称'),
              selected: _isFieldSelected(state, SearchField.name),
              onSelected: (value) => _onFieldsToggled(SearchField.name),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            ChoiceChip(
              label: const Text('基金类型'),
              selected: _isFieldSelected(state, SearchField.type),
              onSelected: (value) => _onFieldsToggled(SearchField.type),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ],
    );
  }

  /// 构建性能信息
  Widget _buildPerformanceInfo(SearchState state) {
    if (state is! SearchLoadSuccess) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.speed,
            size: 14,
            color: Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            state.performanceSummary,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// 获取选项值
  bool _getOptionValue(SearchState state, SearchOption option) {
    if (state is SearchLoadSuccess) {
      final criteria = state.searchResult.criteria;
      switch (option) {
        case SearchOption.caseSensitive:
          return criteria.caseSensitive;
        case SearchOption.fuzzySearch:
          return criteria.fuzzySearch;
        case SearchOption.enablePinyinSearch:
          return criteria.enablePinyinSearch;
        case SearchOption.includeInactive:
          return criteria.includeInactive;
      }
    }
    return false;
  }

  /// 选项变化处理
  void _onOptionChanged(SearchOption option, bool value) {
    context
        .read<SearchBloc>()
        .add(ToggleSearchOption(option: option, value: value));
  }

  /// 检查是否选择所有字段
  bool _isAllFieldsSelected(SearchState state) {
    if (state is SearchLoadSuccess) {
      return state.searchResult.criteria.searchFields.isEmpty ||
          state.searchResult.criteria.searchFields.contains(SearchField.all);
    }
    return true;
  }

  /// 检查字段是否被选择
  bool _isFieldSelected(SearchState state, SearchField field) {
    if (state is SearchLoadSuccess) {
      return state.searchResult.criteria.searchFields.contains(field);
    }
    return false;
  }

  /// 字段变化处理
  void _onFieldsChanged(List<SearchField> fields) {
    context.read<SearchBloc>().add(SetSearchFields(searchFields: fields));
  }

  /// 字段切换处理
  void _onFieldsToggled(SearchField field) {
    if (mounted) {
      final state = context.read<SearchBloc>().state;
      if (state is SearchLoadSuccess) {
        final currentFields = List<SearchField>.from(
          state.searchResult.criteria.searchFields,
        );

        if (currentFields.contains(field)) {
          currentFields.remove(field);
        } else {
          currentFields.add(field);
        }

        _onFieldsChanged(currentFields);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSearchBar(),
        _buildAdvancedPanel(),
      ],
    );
  }
}
