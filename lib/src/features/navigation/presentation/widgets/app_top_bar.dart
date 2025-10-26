import 'package:flutter/material.dart';
import '../../../fund/domain/entities/fund_search_criteria.dart';
import '../../../fund/presentation/widgets/advanced_search_filter.dart';

/// 应用顶部栏
///
/// 提供全局搜索功能和快速操作按钮
/// 支持智能搜索建议、历史记录和热门搜索
class AppTopBar extends StatefulWidget implements PreferredSizeWidget {
  const AppTopBar({super.key});

  @override
  State<AppTopBar> createState() => _AppTopBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _AppTopBarState extends State<AppTopBar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;
  List<String> _searchSuggestions = [];
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.removeListener(_onFocusChange);
    _searchFocusNode.dispose();
    _hideSearchOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (_searchFocusNode.hasFocus && _searchController.text.isNotEmpty) {
      _showSearchOverlay();
    } else {
      _hideSearchOverlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          Image.asset(
            'assets/images/app_icon.png',
            width: 32,
            height: 32,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.analytics, color: Colors.blue);
            },
          ),
          const SizedBox(width: 12),
          const Text('基速基金分析器'),
        ],
      ),
      elevation: 1,
      backgroundColor: Theme.of(context).colorScheme.surface,
      actions: [
        // 全局搜索框
        _buildGlobalSearchField(),
        const SizedBox(width: 16),

        // 快速操作按钮
        _buildQuickActions(),
      ],
    );
  }

  /// 构建全局搜索框
  Widget _buildGlobalSearchField() {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        width: 320,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          decoration: InputDecoration(
            hintText: '搜索基金代码、名称...',
            hintStyle: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            prefixIcon: Container(
              padding: const EdgeInsets.all(8),
              child: _isSearching
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.search,
                      size: 18,
                      color: Colors.grey[600],
                    ),
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: _clearSearch,
                    color: Colors.grey[600],
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
          ),
          style: const TextStyle(fontSize: 14),
          onChanged: _onSearchChanged,
          onSubmitted: _onSearchSubmitted,
          onTap: _onSearchTapped,
        ),
      ),
    );
  }

  /// 构建快速操作按钮
  Widget _buildQuickActions() {
    return Row(
      children: [
        // 刷新按钮
        IconButton(
          icon: const Icon(Icons.refresh, size: 20),
          onPressed: _handleRefresh,
          tooltip: '刷新数据',
          iconSize: 20,
        ),

        // 设置按钮
        IconButton(
          icon: const Icon(Icons.settings, size: 20),
          onPressed: _handleSettings,
          tooltip: '设置',
          iconSize: 20,
        ),

        // 关于按钮
        IconButton(
          icon: const Icon(Icons.info_outline, size: 20),
          onPressed: _handleAbout,
          tooltip: '关于',
          iconSize: 20,
        ),
      ],
    );
  }

  /// 搜索内容变化
  void _onSearchChanged(String value) {
    setState(() {
      _isSearching = value.trim().isNotEmpty;
    });

    if (value.trim().isEmpty) {
      _hideSearchOverlay();
      return;
    }

    // 防抖搜索建议
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_searchController.text == value) {
        _generateSearchSuggestions(value.trim());
      }
    });
  }

  /// 搜索提交
  void _onSearchSubmitted(String value) {
    if (value.trim().isEmpty) return;

    final query = value.trim();
    _performGlobalSearch(query);
    _hideSearchOverlay();
    _searchFocusNode.unfocus();
  }

  /// 搜索框获得焦点
  void _onSearchTapped() {
    if (_searchController.text.isNotEmpty) {
      _showSearchOverlay();
    }
  }

  /// 生成搜索建议
  void _generateSearchSuggestions(String query) {
    final suggestions = <String>[];

    // 模拟搜索建议（实际应用中可以从搜索历史或热门搜索中获取）
    final mockSuggestions = [
      if (query.contains('易') || query.contains('y')) '易方达蓝筹精选',
      if (query.contains('华') || query.contains('h')) '华夏成长混合',
      if (query.contains('南') || query.contains('n')) '南方稳健增长',
      if (query.contains('嘉') || query.contains('j')) '嘉实沪深300',
      if (query.startsWith('00') || query.startsWith('11'))
        query.substring(0, 6),
    ];

    for (final suggestion in mockSuggestions) {
      if (suggestion.toLowerCase().contains(query.toLowerCase())) {
        suggestions.add(suggestion);
        if (suggestions.length >= 5) break;
      }
    }

    setState(() {
      _searchSuggestions = suggestions;
    });

    if (suggestions.isNotEmpty) {
      _showSearchOverlay();
    } else {
      _hideSearchOverlay();
    }
  }

  /// 显示搜索覆盖层
  void _showSearchOverlay() {
    _hideSearchOverlay(); // 先隐藏旧的覆盖层

    _overlayEntry = OverlayEntry(
      builder: (context) => _buildSearchOverlay(),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  /// 隐藏搜索覆盖层
  void _hideSearchOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// 构建搜索覆盖层
  Widget _buildSearchOverlay() {
    return CompositedTransformFollower(
      link: _layerLink,
      showWhenUnlinked: false,
      offset: const Offset(0, 48),
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 320,
          constraints: const BoxConstraints(maxHeight: 300),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 搜索建议标题
              if (_searchSuggestions.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '搜索建议',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

              // 搜索建议列表
              if (_searchSuggestions.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchSuggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = _searchSuggestions[index];
                    return _buildSuggestionItem(suggestion);
                  },
                ),

              // 搜索选项
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSearchOption(
                      icon: Icons.history,
                      label: '搜索历史',
                      onTap: _showSearchHistory,
                    ),
                    _buildSearchOption(
                      icon: Icons.trending_up,
                      label: '热门搜索',
                      onTap: _showPopularSearches,
                    ),
                    _buildSearchOption(
                      icon: Icons.explore,
                      label: '高级搜索',
                      onTap: _showAdvancedSearch,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建建议项
  Widget _buildSuggestionItem(String suggestion) {
    return ListTile(
      dense: true,
      leading: Icon(
        Icons.search,
        size: 16,
        color: Colors.grey[600],
      ),
      title: Text(
        suggestion,
        style: const TextStyle(fontSize: 14),
      ),
      onTap: () => _selectSuggestion(suggestion),
    );
  }

  /// 构建搜索选项
  Widget _buildSearchOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        _hideSearchOverlay();
        onTap();
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 选择搜索建议
  void _selectSuggestion(String suggestion) {
    _searchController.text = suggestion;
    _onSearchSubmitted(suggestion);
  }

  /// 清空搜索
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _searchSuggestions.clear();
    });
    _hideSearchOverlay();
    _searchFocusNode.unfocus();
  }

  /// 执行全局搜索
  void _performGlobalSearch(String query) {
    // 导航到搜索页面并传递搜索参数
    // 这里需要根据实际的路由结构实现
    debugPrint('执行全局搜索: $query');
    // TODO: 实现全局搜索导航逻辑
  }

  /// 显示搜索历史
  void _showSearchHistory() {
    // TODO: 实现搜索历史对话框
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('搜索历史功能开发中')),
    );
  }

  /// 显示热门搜索
  void _showPopularSearches() {
    // TODO: 实现热门搜索对话框
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('热门搜索功能开发中')),
    );
  }

  /// 显示高级搜索
  void _showAdvancedSearch() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          height: 700,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 对话框标题
              Row(
                children: [
                  Icon(
                    Icons.tune,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '高级搜索筛选',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),

              // 高级筛选组件
              Expanded(
                child: AdvancedSearchFilter(
                  initialCriteria:
                      _createSearchCriteria(_searchController.text),
                  onFilterChanged: (criteria) {
                    // 更新搜索条件
                    _applyAdvancedFilter(criteria);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 创建搜索条件
  FundSearchCriteria _createSearchCriteria(String keyword) {
    return FundSearchCriteria(
      keyword: keyword.trim().isEmpty ? null : keyword.trim(),
      searchType: SearchType.mixed,
      fuzzySearch: true,
      enablePinyinSearch: true,
      limit: 50,
    );
  }

  /// 应用高级筛选条件
  void _applyAdvancedFilter(FundSearchCriteria criteria) {
    // 执行搜索
    _performGlobalSearch(criteria.keyword ?? '');

    // 显示筛选应用提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('已应用筛选条件'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: '查看结果',
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  /// 处理刷新
  void _handleRefresh() {
    // TODO: 实现全局数据刷新
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('数据刷新中...')),
    );
  }

  /// 处理设置
  void _handleSettings() {
    // TODO: 打开设置页面
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('设置页面开发中')),
    );
  }

  /// 处理关于
  void _handleAbout() {
    showAboutDialog(
      context: context,
      applicationName: '基速基金分析器',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.analytics),
      children: [
        const Text('专业的基金数据分析和投资管理工具'),
        const SizedBox(height: 16),
        const Text('数据来源：http://154.44.25.92:8080'),
        const Text('基于 AKShare API 构建'),
      ],
    );
  }
}
