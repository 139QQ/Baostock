import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 导航管理器
///
/// 提供统一的导航状态管理和页面跳转逻辑
/// 支持全局搜索、深度链接、导航历史等功能
class NavigationManager extends ChangeNotifier {
  static NavigationManager? _instance;
  static NavigationManager get instance {
    _instance ??= NavigationManager._();
    return _instance!;
  }

  NavigationManager._() {
    debugPrint('🚀 NavigationManager: 初始化导航管理器');
  }

  int _currentIndex = 0;
  String? _pendingSearchQuery;
  final List<int> _navigationHistory = [];
  bool _canGoBack = false;

  // Getters
  int get currentIndex => _currentIndex;
  String? get pendingSearchQuery => _pendingSearchQuery;
  bool get canGoBack => _canGoBack;
  List<int> get navigationHistory => List.unmodifiable(_navigationHistory);

  /// 导航到指定页面
  void navigateToPage(int index, {bool addToHistory = true}) {
    if (index < 0 || index > 6) return; // 允许7个页面（0-6）

    debugPrint('📍 NavigationManager: 导航到页面 $index (${_getPageName(index)})');

    if (addToHistory && _currentIndex != index) {
      _navigationHistory.add(_currentIndex);
      _canGoBack = true;
    }

    _currentIndex = index;
    notifyListeners();

    // 如果有待处理的搜索查询，清除它
    if (_pendingSearchQuery != null) {
      _pendingSearchQuery = null;
    }
  }

  /// 带搜索参数的导航
  void navigateWithSearch(String query) {
    debugPrint('🔍 NavigationManager: 使用搜索参数导航: "$query"');
    _pendingSearchQuery = query;
    navigateToPage(1); // 导航到基金筛选页面
  }

  /// 返回上一页
  void goBack() {
    if (_navigationHistory.isEmpty) {
      debugPrint('⚠️ NavigationManager: 没有导航历史可返回');
      return;
    }

    final previousIndex = _navigationHistory.removeLast();
    debugPrint(
        '⬅️ NavigationManager: 返回到页面 $previousIndex (${_getPageName(previousIndex)})');

    _currentIndex = previousIndex;
    _canGoBack = _navigationHistory.isNotEmpty;
    notifyListeners();
  }

  /// 清除导航历史
  void clearHistory() {
    debugPrint('🗑️ NavigationManager: 清除导航历史');
    _navigationHistory.clear();
    _canGoBack = false;
    notifyListeners();
  }

  /// 重置到首页
  void resetToHome() {
    debugPrint('🏠 NavigationManager: 重置到首页');
    _currentIndex = 0;
    _navigationHistory.clear();
    _canGoBack = false;
    _pendingSearchQuery = null;
    notifyListeners();
  }

  /// 获取页面名称
  String _getPageName(int index) {
    switch (index) {
      case 0:
        return '市场概览';
      case 1:
        return '市场指数';
      case 2:
        return '基金筛选';
      case 3:
        return '自选基金';
      case 4:
        return '持仓分析';
      case 5:
        return '推送通知';
      case 6:
        return '系统设置';
      default:
        return '未知页面';
    }
  }

  /// 获取当前页面信息
  NavigationInfo get currentNavigationInfo {
    return NavigationInfo(
      index: _currentIndex,
      name: _getPageName(_currentIndex),
      hasSearchQuery: _pendingSearchQuery != null,
      searchQuery: _pendingSearchQuery,
    );
  }

  /// 获取导航统计信息
  NavigationStats get stats {
    return NavigationStats(
      currentPageIndex: _currentIndex,
      currentPageName: _getPageName(_currentIndex),
      historyLength: _navigationHistory.length,
      canGoBack: _canGoBack,
      hasPendingSearch: _pendingSearchQuery != null,
    );
  }

  @override
  void dispose() {
    debugPrint('🗑️ NavigationManager: 释放导航管理器');
    super.dispose();
  }
}

/// 导航信息
class NavigationInfo {
  final int index;
  final String name;
  final bool hasSearchQuery;
  final String? searchQuery;

  const NavigationInfo({
    required this.index,
    required this.name,
    required this.hasSearchQuery,
    this.searchQuery,
  });

  @override
  String toString() {
    return 'NavigationInfo(index: $index, name: $name, hasSearch: $hasSearchQuery, query: $searchQuery)';
  }
}

/// 导航统计信息
class NavigationStats {
  final int currentPageIndex;
  final String currentPageName;
  final int historyLength;
  final bool canGoBack;
  final bool hasPendingSearch;

  const NavigationStats({
    required this.currentPageIndex,
    required this.currentPageName,
    required this.historyLength,
    required this.canGoBack,
    required this.hasPendingSearch,
  });

  @override
  String toString() {
    return 'NavigationStats(current: $currentPageName ($currentPageIndex), history: $historyLength, canGoBack: $canGoBack, hasSearch: $hasPendingSearch)';
  }
}
