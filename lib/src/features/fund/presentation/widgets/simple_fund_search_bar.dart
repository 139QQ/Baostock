import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../fund_exploration/presentation/cubit/fund_exploration_cubit.dart';

/// 简化的基金搜索栏组件
///
/// 使用统一的FundExplorationCubit状态管理
/// 提供基本的搜索功能
class SimpleFundSearchBar extends StatefulWidget {
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

  /// 是否显示清除按钮
  final bool showClearButton;

  /// 自定义样式
  final BoxDecoration? decoration;

  /// 自定义高度
  final double? height;

  /// 自定义内容内边距
  final EdgeInsets? contentPadding;

  const SimpleFundSearchBar({
    super.key,
    this.searchText,
    this.placeholder = '搜索基金代码或名称...',
    this.onSearch,
    this.onClear,
    this.onFocusChanged,
    this.autoFocus = false,
    this.showClearButton = true,
    this.decoration,
    this.height = 48,
    this.contentPadding,
  });

  @override
  State<SimpleFundSearchBar> createState() => _SimpleFundSearchBarState();
}

class _SimpleFundSearchBarState extends State<SimpleFundSearchBar> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.searchText ?? '');
    _focusNode = FocusNode();

    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(SimpleFundSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchText != oldWidget.searchText) {
      _controller.text = widget.searchText ?? '';
    }
  }

  /// 执行搜索
  void _performSearch(String query) {
    // 取消之前的防抖定时器
    _searchDebounce?.cancel();

    if (query.trim().isEmpty) {
      // 清除搜索
      context.read<FundExplorationCubit>().searchFunds('');
      widget.onSearch?.call('');
      return;
    }

    // 防抖搜索 - 300ms后执行
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      context.read<FundExplorationCubit>().searchFunds(query.trim());
      widget.onSearch?.call(query.trim());
    });
  }

  /// 清除搜索
  void _clearSearch() {
    _controller.clear();
    _performSearch('');
    widget.onClear?.call();
  }

  /// 处理文本变化
  void _onChanged(String value) {
    _performSearch(value);
  }

  /// 处理提交
  void _onSubmitted(String value) {
    _performSearch(value);
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: widget.height,
      decoration: widget.decoration ??
          BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        autofocus: widget.autoFocus,
        textInputAction: TextInputAction.search,
        style: theme.textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: widget.placeholder,
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 16,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.search,
              color: theme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
          ),
          suffixIcon: widget.showClearButton
              ? _controller.text.isNotEmpty
                  ? _buildClearButton()
                  : null
              : null,
          border: InputBorder.none,
          contentPadding: widget.contentPadding ??
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: _onChanged,
        onSubmitted: _onSubmitted,
        onTap: () => _focusNode.requestFocus(),
      ),
    );
  }

  /// 构建清除按钮
  Widget _buildClearButton() {
    return GestureDetector(
      onTap: _clearSearch,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        child: Icon(
          Icons.close,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 20,
        ),
      ),
    );
  }
}
