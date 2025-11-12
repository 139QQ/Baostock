import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 智能搜索栏
///
/// 支持基金、板块、概念搜索，带有微动交互效果
class IntelligentSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<bool>? onFocusChanged;
  final VoidCallback? onFilterTap;

  const IntelligentSearchBar({
    super.key,
    required this.controller,
    this.onSearchChanged,
    this.onFocusChanged,
    this.onFilterTap,
  });

  @override
  State<IntelligentSearchBar> createState() => _IntelligentSearchBarState();
}

class _IntelligentSearchBarState extends State<IntelligentSearchBar>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;

  bool _isFocused = false;
  bool _isSearching = false;
  Timer? _searchTimer;
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupSearchListener();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    _shimmerController.repeat();
  }

  void _setupSearchListener() {
    widget.controller.addListener(_onSearchTextChanged);
  }

  void _onSearchTextChanged() {
    final query = widget.controller.text.trim();

    // 防抖搜索
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 300), () {
      if (query.isNotEmpty) {
        _performSearch(query);
      } else {
        setState(() {
          _suggestions.clear();
        });
      }
    });

    widget.onSearchChanged?.call(query);
  }

  void _performSearch(String query) {
    setState(() {
      _isSearching = true;
    });

    // 模拟搜索延迟
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _suggestions = _generateSuggestions(query);
        });
      }
    });
  }

  List<String> _generateSuggestions(String query) {
    // 模拟智能建议
    final allSuggestions = [
      '易方达蓝筹精选混合',
      '汇添富价值精选混合',
      '富国天惠成长混合',
      '新能源主题基金',
      '科技创新板块',
      '医疗健康概念',
      '消费升级主题',
      '5G通信基金',
      '半导体芯片基金',
      '环保产业基金',
    ];

    return allSuggestions
        .where((suggestion) =>
            suggestion.toLowerCase().contains(query.toLowerCase()))
        .take(5)
        .toList();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    widget.controller.removeListener(_onSearchTextChanged);
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 搜索栏主体
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isFocused ? _pulseAnimation.value : 1.0,
              child: child,
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: TextField(
              controller: widget.controller,
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _isFocused = true;
                });
                widget.onFocusChanged?.call(true);
              },
              onTapOutside: (event) {
                setState(() {
                  _isFocused = false;
                });
                widget.onFocusChanged?.call(false);
              },
              decoration: InputDecoration(
                hintText: '搜索基金、板块或概念...',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
                prefixIcon: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    _isSearching ? Icons.search_rounded : Icons.search_outlined,
                    color: _isFocused ? Colors.blue[600] : Colors.grey[400],
                    size: 24,
                  ),
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 清除按钮
                    if (widget.controller.text.isNotEmpty)
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: _isFocused ? 1.0 : 0.0,
                        child: IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                          onPressed: () {
                            widget.controller.clear();
                            setState(() {
                              _suggestions.clear();
                            });
                            HapticFeedback.lightImpact();
                          },
                        ),
                      ),
                    // 筛选按钮
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 4),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            widget.onFilterTap?.call();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _isFocused
                                  ? Colors.blue[50]
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.tune_rounded,
                              color: _isFocused
                                  ? Colors.blue[600]
                                  : Colors.grey[600],
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                filled: true,
                fillColor: _isFocused ? Colors.white : Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: Colors.grey[200]!,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: Colors.blue[400]!,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        ),

        // 搜索建议
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _suggestions.isNotEmpty
              ? _buildSuggestions()
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildSuggestions() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 建议标题
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              '智能建议',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          // 建议列表
          ..._suggestions.asMap().entries.map((entry) {
            final index = entry.key;
            final suggestion = entry.value;
            return _buildSuggestionItem(suggestion, index);
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(String suggestion, int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 100 + index * 50),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticFeedback.selectionClick();
            widget.controller.text = suggestion;
            setState(() {
              _suggestions.clear();
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 16,
                  color: Colors.grey[400],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    suggestion,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
