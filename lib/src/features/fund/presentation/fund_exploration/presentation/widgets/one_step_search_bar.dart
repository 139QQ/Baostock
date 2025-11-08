import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../bloc/fund_search_bloc.dart';

/// 一步搜索体验组件
/// 实现边输入边加载的模糊搜索功能
/// 支持实时建议、搜索历史和智能提示
class OneStepSearchBar extends StatefulWidget {
  // ignore: public_member_api_docs
  const OneStepSearchBar({
    super.key,
    this.initialQuery,
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.onClear,
    this.autofocus = false,
    this.showSuggestions = true,
    this.maxSuggestions = 8,
    this.debounceDelay = const Duration(milliseconds: 300),
  });

  /// 初始搜索查询
  final String? initialQuery;

  /// 搜索内容变化回调
  final Function(String)? onSearchChanged;

  /// 搜索提交回调
  final Function(String)? onSearchSubmitted;

  /// 清除搜索回调
  final VoidCallback? onClear;

  /// 是否自动聚焦
  final bool autofocus;

  /// 是否显示建议
  final bool showSuggestions;

  /// 最大建议数量
  final int maxSuggestions;

  /// 防抖延迟时间
  final Duration debounceDelay;

  @override
  State<OneStepSearchBar> createState() => _OneStepSearchBarState();
}

class _OneStepSearchBarState extends State<OneStepSearchBar>
    with TickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isFocused = false;
  bool _isSearching = false;
  List<String> _searchHistory = [];
  List<String> _suggestions = [];
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery ?? '');
    _focusNode = FocusNode();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _focusNode.addListener(_onFocusChanged);
    _controller.addListener(_onTextChanged);

    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    final isFocused = _focusNode.hasFocus;
    if (isFocused != _isFocused) {
      setState(() {
        _isFocused = isFocused;
      });
      if (isFocused) {
        _animationController.forward();
        _loadSearchHistory();
      } else {
        _animationController.reverse();
      }
    }
  }

  void _onTextChanged() {
    final text = _controller.text;

    // 防抖处理
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceDelay, () {
      _performSearch(text);
    });

    widget.onSearchChanged?.call(text);
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _suggestions = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    // 触发搜索Bloc
    context.read<FundSearchBloc>().add(
          SearchFunds(query),
        );

    // 生成搜索建议（模拟）
    _generateSuggestions(query);
  }

  void _generateSuggestions(String query) {
    // 这里应该调用实际的搜索建议API
    // 现在使用模拟数据
    final mockSuggestions = [
      '$query - 混合型基金',
      '$query - 股票型基金',
      '$query - 债券型基金',
      '$query精选',
      '易方达$query',
      '汇添富$query',
      '富国$query',
      '华夏$query',
    ];

    setState(() {
      _suggestions = mockSuggestions.take(widget.maxSuggestions).toList();
      _isSearching = false;
    });
  }

  void _loadSearchHistory() {
    // 从本地存储加载搜索历史
    // 现在使用模拟数据
    setState(() {
      _searchHistory = [
        '易方达蓝筹精选',
        '汇添富价值精选',
        '富国天惠成长',
        '兴全合润混合',
        '华夏回报混合',
      ];
    });
  }

  void _addToHistory(String query) {
    if (query.trim().isEmpty) return;

    setState(() {
      _searchHistory.remove(query);
      _searchHistory.insert(0, query);
      _searchHistory = _searchHistory.take(10).toList();
    });

    // 保存到本地存储
    // TODO: 实现本地存储逻辑
  }

  void _clearSearch() {
    _controller.clear();
    widget.onClear?.call();
    _focusNode.unfocus();
    setState(() {
      _suggestions = [];
    });
  }

  void _submitSearch(String query) {
    if (query.trim().isEmpty) return;

    _addToHistory(query);
    widget.onSearchSubmitted?.call(query);
    _focusNode.unfocus();
  }

  void _selectSuggestion(String suggestion) {
    _controller.text = suggestion;
    _submitSearch(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 搜索输入框
        _buildSearchInput(),

        // 搜索建议和历史的下拉面板
        if (_isFocused &&
            (_suggestions.isNotEmpty || _searchHistory.isNotEmpty))
          _buildSuggestionsPanel(),
      ],
    );
  }

  Widget _buildSearchInput() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: _isFocused
              ? const Color(0xFF007bff)
              : Colors.grey.withOpacity(0.2),
          width: _isFocused ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // 搜索图标
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _isSearching
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF007bff),
                      ),
                    ),
                  )
                : Icon(
                    Icons.search,
                    color:
                        _isFocused ? const Color(0xFF007bff) : Colors.grey[600],
                    size: 20,
                  ),
          ),

          // 输入框
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1a1a1a),
              ),
              decoration: InputDecoration(
                hintText: '搜索基金名称、代码或基金经理...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 0,
                  vertical: 16,
                ),
              ),
              onSubmitted: _submitSearch,
              textInputAction: TextInputAction.search,
            ),
          ),

          // 清除按钮
          if (_controller.text.isNotEmpty)
            GestureDetector(
              onTap: _clearSearch,
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),

          // 搜索按钮
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _submitSearch(_controller.text),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF007bff),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate(target: _isFocused ? 1 : 0).scaleXY(
          begin: 1.0,
          end: 1.02,
          duration: 200.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildSuggestionsPanel() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 搜索建议
              if (_suggestions.isNotEmpty) ...[
                _buildSectionHeader('搜索建议'),
                ..._suggestions.map(
                  (suggestion) =>
                      _buildSuggestionItem(suggestion, isSuggestion: true),
                ),
              ],

              // 搜索历史
              if (_searchHistory.isNotEmpty) ...[
                _buildSectionHeader('搜索历史'),
                ..._searchHistory.map(
                  (history) =>
                      _buildSuggestionItem(history, isSuggestion: false),
                ),
                _buildClearHistoryButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF666666),
            ),
          ),
          const Spacer(),
          if (title == '搜索历史')
            GestureDetector(
              onTap: () {
                setState(() {
                  _searchHistory.clear();
                });
              },
              child: Text(
                '清除',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF007bff),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(String text, {required bool isSuggestion}) {
    return GestureDetector(
      onTap: () => _selectSuggestion(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              isSuggestion ? Icons.search : Icons.history,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1a1a1a),
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClearHistoryButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _searchHistory.clear();
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
        ),
        child: Center(
          child: Text(
            '清除所有搜索历史',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFd32f2f),
            ),
          ),
        ),
      ),
    );
  }
}

/// 搜索结果过滤器
class SearchFilter {
  /// 创建搜索过滤器
  const SearchFilter({
    required this.query,
    this.fundType,
    this.riskLevel,
    this.sortBy,
    this.minReturn,
    this.maxReturn,
  });

  /// 搜索查询
  final String query;

  /// 基金类型
  final String? fundType;

  /// 风险等级
  final String? riskLevel;

  /// 排序方式
  final String? sortBy;

  /// 最小收益率
  final double? minReturn;

  /// 最大收益率
  final double? maxReturn;

  /// 复制过滤器
  SearchFilter copyWith({
    String? query,
    String? fundType,
    String? riskLevel,
    String? sortBy,
    double? minReturn,
    double? maxReturn,
  }) {
    return SearchFilter(
      query: query ?? this.query,
      fundType: fundType ?? this.fundType,
      riskLevel: riskLevel ?? this.riskLevel,
      sortBy: sortBy ?? this.sortBy,
      minReturn: minReturn ?? this.minReturn,
      maxReturn: maxReturn ?? this.maxReturn,
    );
  }

  /// 检查过滤器是否为空
  bool get isEmpty =>
      query.trim().isEmpty &&
      fundType == null &&
      riskLevel == null &&
      minReturn == null &&
      maxReturn == null;
}
