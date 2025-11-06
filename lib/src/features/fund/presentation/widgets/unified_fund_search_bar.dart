import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../src/bloc/fund_search_bloc.dart';

/// 统一基金搜索栏组件
///
/// 集成统一搜索服务，提供智能路由搜索功能，包括：
/// - 自动选择搜索引擎（基础/增强）
/// - 智能搜索选项生成
/// - 实时搜索建议
/// - 搜索历史管理
/// - 性能优化显示
///
/// 新特性：
/// - 根据查询复杂度自动选择最适合的搜索引擎
/// - 提供多种搜索模式（快速/精确/全面）
/// - 智能搜索建议生成
/// - 搜索性能监控和优化
class UnifiedFundSearchBar extends StatefulWidget {
  /// 当前搜索文本
  final String? searchText;

  /// 占位符文本
  final String? placeholder;

  /// 搜索回调（兼容性接口）
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

  /// 搜索模式
  final UnifiedSearchMode searchMode;

  /// 是否显示搜索模式选择器
  final bool showSearchModeSelector;

  /// 是否显示搜索建议
  final bool showSuggestions;

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

  const UnifiedFundSearchBar({
    super.key,
    this.searchText,
    this.placeholder = '搜索基金名称、代码或关键词...',
    this.onSearch,
    this.onClear,
    this.onFocusChanged,
    this.autoFocus = false,
    this.showAdvancedOptions = true,
    this.enableVoiceSearch = false,
    this.searchMode = UnifiedSearchMode.auto,
    this.showSearchModeSelector = true,
    this.showSuggestions = true,
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
  State<UnifiedFundSearchBar> createState() => _UnifiedFundSearchBarState();
}

/// 搜索模式枚举
enum UnifiedSearchMode {
  /// 自动优化搜索（根据查询类型智能选择）
  auto,

  /// 快速搜索（优先性能）
  quick,

  /// 精确搜索（优先准确性）
  precise,

  /// 全面搜索（获取最多结果）
  comprehensive,
}

class _UnifiedFundSearchBarState extends State<UnifiedFundSearchBar> {
  late TextEditingController _textController;
  late FocusNode _focusNode;
  Timer? _debounceTimer;
  bool _isFocused = false;
  bool _showAdvancedPanel = false;
  UnifiedSearchMode _selectedSearchMode = UnifiedSearchMode.auto;
  List<String> _suggestions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.searchText ?? '');
    _focusNode = FocusNode();
    _selectedSearchMode = widget.searchMode;

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
  void didUpdateWidget(UnifiedFundSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchText != oldWidget.searchText &&
        widget.searchText != _textController.text) {
      _textController.text = widget.searchText ?? '';
    }
    if (widget.searchMode != oldWidget.searchMode) {
      _selectedSearchMode = widget.searchMode;
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

    // 触发重建以更新清除按钮显示状态
    setState(() {});

    // 清空建议（除非文本为空）
    if (text.isNotEmpty) {
      // 设置新的防抖动定时器
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          _performSearch(text);
          _loadSuggestions(text);
        }
      });
    } else {
      setState(() {
        _suggestions.clear();
      });
      // 触发清空搜索
      widget.onSearch?.call('');
      context.read<FundSearchBloc>().add(ClearSearch());
    }
  }

  /// 焦点变化处理
  void _onFocusChanged() {
    final isFocused = _focusNode.hasFocus;
    if (_isFocused != isFocused) {
      setState(() {
        _isFocused = isFocused;
      });
      widget.onFocusChanged?.call(isFocused);

      // 失去焦点时隐藏高级面板和建议
      if (!isFocused) {
        setState(() {
          _showAdvancedPanel = false;
          _suggestions.clear();
        });
      }
    }
  }

  /// 执行搜索
  void _performSearch(String query) {
    if (query.trim().isEmpty) return;

    // 兼容性回调
    widget.onSearch?.call(query);

    // 使用统一搜索服务
    switch (_selectedSearchMode) {
      case UnifiedSearchMode.auto:
        context.read<FundSearchBloc>().autoSearch(query);
        break;
      case UnifiedSearchMode.quick:
        context.read<FundSearchBloc>().quickSearch(query);
        break;
      case UnifiedSearchMode.precise:
        context.read<FundSearchBloc>().preciseSearch(query);
        break;
      case UnifiedSearchMode.comprehensive:
        context.read<FundSearchBloc>().comprehensiveSearch(query);
        break;
    }
  }

  /// 加载搜索建议
  void _loadSuggestions(String query) {
    if (widget.showSuggestions && query.isNotEmpty) {
      context.read<FundSearchBloc>().getSuggestions(query);
    }
  }

  /// 清空搜索
  void _onClear() {
    _textController.clear();
    setState(() {
      _suggestions.clear();
    });
    widget.onClear?.call();
    context.read<FundSearchBloc>().add(ClearSearch());
  }

  /// 提交搜索
  void _onSubmit(String value) {
    if (value.trim().isNotEmpty) {
      // 立即执行搜索（不等待防抖动）
      _debounceTimer?.cancel();
      _performSearch(value.trim());
    }
  }

  /// 选择搜索建议
  void _onSelectSuggestion(String suggestion) {
    _textController.text = suggestion;
    setState(() {
      _suggestions.clear();
    });
    _performSearch(suggestion);
    _focusNode.unfocus();
  }

  /// 切换搜索模式
  void _onSearchModeChanged(UnifiedSearchMode mode) {
    setState(() {
      _selectedSearchMode = mode;
    });

    // 如果当前有搜索文本，重新执行搜索
    final currentQuery = _textController.text.trim();
    if (currentQuery.isNotEmpty) {
      _performSearch(currentQuery);
    }
  }

  /// 获取搜索模式显示名称
  String _getSearchModeDisplayName(UnifiedSearchMode mode) {
    switch (mode) {
      case UnifiedSearchMode.auto:
        return '智能';
      case UnifiedSearchMode.quick:
        return '快速';
      case UnifiedSearchMode.precise:
        return '精确';
      case UnifiedSearchMode.comprehensive:
        return '全面';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FundSearchBloc, FundSearchState>(
      listener: (context, state) {
        // 处理统一搜索状态
        if (state is UnifiedSearchLoading) {
          setState(() {
            _isLoading = true;
          });
        } else if (state is UnifiedSearchLoaded ||
            state is UnifiedSearchError ||
            state is FundSearchLoaded ||
            state is FundSearchError ||
            state is FundSearchEmpty) {
          setState(() {
            _isLoading = false;
          });
        }

        // 处理搜索建议状态
        if (state is UnifiedSearchSuggestionsLoaded) {
          setState(() {
            _suggestions = state.suggestions;
          });
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 搜索模式选择器
          if (widget.showSearchModeSelector) _buildSearchModeSelector(),

          // 搜索栏主体
          Stack(
            children: [
              _buildSearchField(),
              if (_isLoading) _buildLoadingIndicator(),
            ],
          ),

          // 搜索建议列表
          if (_suggestions.isNotEmpty && _isFocused) _buildSuggestionsList(),

          // 高级搜索面板
          if (_showAdvancedPanel) _buildAdvancedPanel(),
        ],
      ),
    );
  }

  /// 构建搜索模式选择器
  Widget _buildSearchModeSelector() {
    return Container(
      height: 32,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: UnifiedSearchMode.values.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final mode = UnifiedSearchMode.values[index];
          final isSelected = _selectedSearchMode == mode;

          return GestureDetector(
            onTap: () => _onSearchModeChanged(mode),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Text(
                _getSearchModeDisplayName(mode),
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建搜索字段
  Widget _buildSearchField() {
    return Container(
      decoration: widget.decoration ??
          BoxDecoration(
            color: Colors.grey[50],
            borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
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
        style: widget.textStyle ?? const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: widget.placeholder,
          hintStyle: widget.hintStyle ??
              TextStyle(
                color: Colors.grey[500],
                fontSize: 16,
              ),
          prefixIcon: widget.prefixIcon ??
              Icon(
                Icons.search,
                color: Colors.grey[600],
              ),
          suffixIcon: _buildSuffixIcon(),
          contentPadding: widget.contentPadding ??
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: InputBorder.none,
          counterText: '',
        ),
        onSubmitted: _onSubmit,
        onTap: () {
          if (!_isFocused) {
            setState(() {
              _isFocused = true;
            });
            widget.onFocusChanged?.call(true);
          }
        },
      ),
    );
  }

  /// 构建后缀图标
  Widget _buildSuffixIcon() {
    if (_textController.text.isNotEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.enableVoiceSearch)
            IconButton(
              icon: const Icon(Icons.mic, color: Colors.grey),
              onPressed: () {
                // TODO: 实现语音搜索
              },
            ),
          if (widget.showAdvancedOptions)
            IconButton(
              icon: Icon(
                _showAdvancedPanel
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _showAdvancedPanel = !_showAdvancedPanel;
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.clear, color: Colors.grey),
            onPressed: _onClear,
          ),
        ],
      );
    } else {
      return widget.suffixIcon ?? const SizedBox.shrink();
    }
  }

  /// 构建加载指示器
  Widget _buildLoadingIndicator() {
    return const Positioned(
      right: 16,
      top: 0,
      bottom: 0,
      child: Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
          ),
        ),
      ),
    );
  }

  /// 构建搜索建议列表
  Widget _buildSuggestionsList() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(
        maxHeight: 200, // 限制最大高度避免溢出
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(), // 允许滚动但显示滚动条
        itemCount: _suggestions.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: Colors.grey[200],
        ),
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          return ListTile(
            dense: true,
            leading: const Icon(Icons.search, size: 16, color: Colors.grey),
            title: Text(suggestion),
            onTap: () => _onSelectSuggestion(suggestion),
          );
        },
      ),
    );
  }

  /// 构建高级搜索面板
  Widget _buildAdvancedPanel() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '高级搜索选项',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          // TODO: 添加高级搜索选项控件
          Text(
            '高级搜索功能正在开发中...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
