import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jisu_fund_analyzer/src/core/utils/logger.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/widgets/fund_card_theme.dart';

/// 基金用户偏好服务
///
/// 管理用户的收藏基金、显示偏好等设置
class FundUserPreferences {
  static const String _favoritesKey = 'fund_favorites';
  static const String _displayPreferencesKey = 'fund_display_preferences';
  static const String _lastViewedKey = 'fund_last_viewed';
  static const String _searchHistoryKey = 'fund_search_history';
  static const String _filterPreferencesKey = 'fund_filter_preferences';

  static SharedPreferences? _prefs;
  static bool _isInitialized = false;

  /// 初始化偏好设置
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
      AppLogger.info('✅ 基金用户偏好设置初始化成功');
    } catch (e) {
      AppLogger.error('❌ 基金用户偏好设置初始化失败', e.toString());
      _isInitialized = false;
    }
  }

  /// 确保已初始化
  static Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  // ========== 收藏功能 ==========

  /// 获取收藏的基金代码列表
  static Future<Set<String>> getFavoriteFunds() async {
    await _ensureInitialized();
    try {
      final favoritesJson = _prefs?.getString(_favoritesKey) ?? '[]';
      final List<dynamic> favoritesList = jsonDecode(favoritesJson);
      return favoritesList.cast<String>().toSet();
    } catch (e) {
      AppLogger.error('❌ 获取收藏基金失败', e.toString());
      return <String>{};
    }
  }

  /// 添加收藏基金
  static Future<bool> addFavoriteFund(String fundCode) async {
    await _ensureInitialized();
    try {
      final favorites = await getFavoriteFunds();
      if (favorites.contains(fundCode)) {
        return false; // 已收藏
      }

      favorites.add(fundCode);
      final success = await _prefs?.setString(
          _favoritesKey, jsonEncode(favorites.toList()));

      if (success == true) {
        AppLogger.info('💖 添加收藏基金: $fundCode');
        await _recordFavoriteAction(fundCode, 'add');
      }

      return success ?? false;
    } catch (e) {
      AppLogger.error('❌ 添加收藏基金失败', e.toString());
      return false;
    }
  }

  /// 移除收藏基金
  static Future<bool> removeFavoriteFund(String fundCode) async {
    await _ensureInitialized();
    try {
      final favorites = await getFavoriteFunds();
      if (!favorites.contains(fundCode)) {
        return false; // 未收藏
      }

      favorites.remove(fundCode);
      final success = await _prefs?.setString(
          _favoritesKey, jsonEncode(favorites.toList()));

      if (success == true) {
        AppLogger.info('💔 移除收藏基金: $fundCode');
        await _recordFavoriteAction(fundCode, 'remove');
      }

      return success ?? false;
    } catch (e) {
      AppLogger.error('❌ 移除收藏基金失败', e.toString());
      return false;
    }
  }

  /// 切换收藏状态
  static Future<bool> toggleFavoriteFund(String fundCode) async {
    final favorites = await getFavoriteFunds();
    if (favorites.contains(fundCode)) {
      return await removeFavoriteFund(fundCode);
    } else {
      return await addFavoriteFund(fundCode);
    }
  }

  /// 批量添加收藏基金
  static Future<bool> addFavoriteFunds(List<String> fundCodes) async {
    await _ensureInitialized();
    try {
      final favorites = await getFavoriteFunds();
      final newFavorites = Set<String>.from(favorites);
      newFavorites.addAll(fundCodes);

      final success = await _prefs?.setString(
          _favoritesKey, jsonEncode(newFavorites.toList()));

      if (success == true) {
        AppLogger.info('💖 批量添加收藏基金: ${fundCodes.length}个');
        for (final fundCode in fundCodes) {
          await _recordFavoriteAction(fundCode, 'add');
        }
      }

      return success ?? false;
    } catch (e) {
      AppLogger.error('❌ 批量添加收藏基金失败', e.toString());
      return false;
    }
  }

  /// 检查基金是否已收藏
  static Future<bool> isFavoriteFund(String fundCode) async {
    final favorites = await getFavoriteFunds();
    return favorites.contains(fundCode);
  }

  /// 获取收藏基金数量
  static Future<int> getFavoriteCount() async {
    final favorites = await getFavoriteFunds();
    return favorites.length;
  }

  /// 清空所有收藏
  static Future<bool> clearAllFavorites() async {
    await _ensureInitialized();
    try {
      final success = await _prefs?.remove(_favoritesKey);
      AppLogger.info('🗑️ 清空所有收藏基金');
      return success ?? false;
    } catch (e) {
      AppLogger.error('❌ 清空收藏基金失败', e.toString());
      return false;
    }
  }

  // ========== 显示偏好 ==========

  /// 获取显示偏好设置
  static Future<FundDisplayPreferences> getDisplayPreferences() async {
    await _ensureInitialized();
    try {
      final prefsJson = _prefs?.getString(_displayPreferencesKey) ?? '{}';
      final Map<String, dynamic> prefsMap = jsonDecode(prefsJson);

      return FundDisplayPreferences.fromJson(prefsMap);
    } catch (e) {
      AppLogger.error('❌ 获取显示偏好失败', e.toString());
      return FundDisplayPreferences.defaultPreferences();
    }
  }

  /// 保存显示偏好设置
  static Future<bool> saveDisplayPreferences(
      FundDisplayPreferences preferences) async {
    await _ensureInitialized();
    try {
      final success = await _prefs?.setString(
        _displayPreferencesKey,
        jsonEncode(preferences.toJson()),
      );
      AppLogger.info('💾 保存显示偏好设置');
      return success ?? false;
    } catch (e) {
      AppLogger.error('❌ 保存显示偏好失败', e.toString());
      return false;
    }
  }

  /// 更新显示偏好中的单个设置
  static Future<bool> updateDisplayPreference<T>(String key, T value) async {
    final prefs = await getDisplayPreferences();
    final updatedPrefs = prefs.copyWithField(key, value);
    return await saveDisplayPreferences(updatedPrefs);
  }

  // ========== 最近查看 ==========

  /// 获取最近查看的基金
  static Future<List<String>> getRecentlyViewedFunds() async {
    await _ensureInitialized();
    try {
      final viewedJson = _prefs?.getString(_lastViewedKey) ?? '[]';
      final List<dynamic> viewedList = jsonDecode(viewedJson);
      return viewedList.cast<String>();
    } catch (e) {
      AppLogger.error('❌ 获取最近查看基金失败', e.toString());
      return <String>[];
    }
  }

  /// 添加最近查看的基金
  static Future<bool> addRecentlyViewedFund(String fundCode) async {
    await _ensureInitialized();
    try {
      var viewed = await getRecentlyViewedFunds();

      // 移除已存在的，然后添加到开头
      viewed.remove(fundCode);
      viewed.insert(0, fundCode);

      // 限制最多保存50个
      if (viewed.length > 50) {
        viewed = viewed.take(50).toList();
      }

      final success =
          await _prefs?.setString(_lastViewedKey, jsonEncode(viewed));
      if (success == true) {
        AppLogger.info('👁 添加最近查看基金: $fundCode');
      }
      return success ?? false;
    } catch (e) {
      AppLogger.error('❌ 添加最近查看基金失败', e.toString());
      return false;
    }
  }

  /// 清空最近查看记录
  static Future<bool> clearRecentlyViewedFunds() async {
    await _ensureInitialized();
    try {
      final success = await _prefs?.remove(_lastViewedKey);
      AppLogger.info('🗑️ 清空最近查看记录');
      return success ?? false;
    } catch (e) {
      AppLogger.error('❌ 清空最近查看记录失败', e.toString());
      return false;
    }
  }

  // ========== 搜索历史 ==========

  /// 获取搜索历史
  static Future<List<String>> getSearchHistory() async {
    await _ensureInitialized();
    try {
      final historyJson = _prefs?.getString(_searchHistoryKey) ?? '[]';
      final List<dynamic> historyList = jsonDecode(historyJson);
      return historyList.cast<String>();
    } catch (e) {
      AppLogger.error('❌ 获取搜索历史失败', e.toString());
      return <String>[];
    }
  }

  /// 添加搜索历史
  static Future<bool> addSearchHistory(String query) async {
    await _ensureInitialized();
    try {
      if (query.trim().isEmpty) return false;

      var history = await getSearchHistory();

      // 移除已存在的，然后添加到开头
      history.remove(query);
      history.insert(0, query);

      // 限制最多保存20个
      if (history.length > 20) {
        history = history.take(20).toList();
      }

      final success =
          await _prefs?.setString(_searchHistoryKey, jsonEncode(history));
      if (success == true) {
        AppLogger.info('🔍 添加搜索历史: $query');
      }
      return success ?? false;
    } catch (e) {
      AppLogger.error('❌ 添加搜索历史失败', e.toString());
      return false;
    }
  }

  /// 清空搜索历史
  static Future<bool> clearSearchHistory() async {
    await _ensureInitialized();
    try {
      final success = await _prefs?.remove(_searchHistoryKey);
      AppLogger.info('🗑️ 清空搜索历史');
      return success ?? false;
    } catch (e) {
      AppLogger.error('❌ 清空搜索历史失败', e.toString());
      return false;
    }
  }

  // ========== 过滤偏好 ==========

  /// 获取过滤偏好设置
  static Future<FundFilterPreferences> getFilterPreferences() async {
    await _ensureInitialized();
    try {
      final filterJson = _prefs?.getString(_filterPreferencesKey) ?? '{}';
      final Map<String, dynamic> filterMap = jsonDecode(filterJson);

      return FundFilterPreferences.fromJson(filterMap);
    } catch (e) {
      AppLogger.error('❌ 获取过滤偏好失败', e.toString());
      return FundFilterPreferences.defaultPreferences();
    }
  }

  /// 保存过滤偏好设置
  static Future<bool> saveFilterPreferences(
      FundFilterPreferences preferences) async {
    await _ensureInitialized();
    try {
      final success = await _prefs?.setString(
        _filterPreferencesKey,
        jsonEncode(preferences.toJson()),
      );
      AppLogger.info('💾 保存过滤偏好设置');
      return success ?? false;
    } catch (e) {
      AppLogger.error('❌ 保存过滤偏好失败', e.toString());
      return false;
    }
  }

  // ========== 统计和分析 ==========

  /// 获取用户行为统计
  static Future<Map<String, dynamic>> getUserStatistics() async {
    final favorites = await getFavoriteFunds();
    final viewed = await getRecentlyViewedFunds();
    final history = await getSearchHistory();

    return {
      'favoriteCount': favorites.length,
      'viewedCount': viewed.length,
      'searchCount': history.length,
      'lastActivity': await _getLastActivityTime(),
      'totalActions': await _getTotalActionCount(),
    };
  }

  /// 获取最后活动时间
  static Future<DateTime?> _getLastActivityTime() async {
    try {
      final timestamp = _prefs?.getInt('last_activity_timestamp');
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    } catch (e) {
      AppLogger.error('❌ 获取最后活动时间失败', e.toString());
    }
    return null;
  }

  /// 更新最后活动时间
  static Future<void> _updateLastActivityTime() async {
    await _ensureInitialized();
    try {
      await _prefs?.setInt(
          'last_activity_timestamp', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      AppLogger.error('❌ 更新最后活动时间失败', e.toString());
    }
  }

  /// 获取总操作次数
  static Future<int> _getTotalActionCount() async {
    await _ensureInitialized();
    try {
      return _prefs?.getInt('total_action_count') ?? 0;
    } catch (e) {
      AppLogger.error('❌ 获取总操作次数失败', e.toString());
      return 0;
    }
  }

  /// 增加操作计数
  static Future<void> _incrementActionCount() async {
    await _ensureInitialized();
    try {
      final current = await _getTotalActionCount();
      await _prefs?.setInt('total_action_count', current + 1);
      await _updateLastActivityTime();
    } catch (e) {
      AppLogger.error('❌ 增加操作计数失败', e.toString());
    }
  }

  /// 记录收藏操作
  static Future<void> _recordFavoriteAction(
      String fundCode, String action) async {
    await _incrementActionCount();
    // 这里可以添加更详细的收藏操作记录
    AppLogger.info('💾 收藏操作记录: $action - $fundCode');
  }

  /// 导出用户偏好数据
  static Future<Map<String, dynamic>> exportUserData() async {
    return {
      'favorites': (await getFavoriteFunds()).toList(),
      'displayPreferences': (await getDisplayPreferences()).toJson(),
      'recentlyViewed': await getRecentlyViewedFunds(),
      'searchHistory': await getSearchHistory(),
      'filterPreferences': (await getFilterPreferences()).toJson(),
      'statistics': await getUserStatistics(),
      'exportTime': DateTime.now().toIso8601String(),
    };
  }

  /// 导入用户偏好数据
  static Future<bool> importUserData(Map<String, dynamic> data) async {
    try {
      // 导入收藏基金
      if (data.containsKey('favorites')) {
        final favorites = List<String>.from(data['favorites']);
        await addFavoriteFunds(favorites);
      }

      // 导入显示偏好
      if (data.containsKey('displayPreferences')) {
        final prefs =
            FundDisplayPreferences.fromJson(data['displayPreferences']);
        await saveDisplayPreferences(prefs);
      }

      // 导入过滤偏好
      if (data.containsKey('filterPreferences')) {
        final prefs = FundFilterPreferences.fromJson(data['filterPreferences']);
        await saveFilterPreferences(prefs);
      }

      AppLogger.info('✅ 用户偏好数据导入成功');
      return true;
    } catch (e) {
      AppLogger.error('❌ 用户偏好数据导入失败', e.toString());
      return false;
    }
  }

  /// 清空所有用户数据
  static Future<bool> clearAllUserData() async {
    try {
      await clearAllFavorites();
      await clearRecentlyViewedFunds();
      await clearSearchHistory();

      final success1 = await _prefs?.remove(_displayPreferencesKey);
      final success2 = await _prefs?.remove(_filterPreferencesKey);

      AppLogger.info('🗑️ 清空所有用户数据');
      return (success1 ?? false) && (success2 ?? false);
    } catch (e) {
      AppLogger.error('❌ 清空用户数据失败', e.toString());
      return false;
    }
  }

  /// 重置为默认设置
  static Future<bool> resetToDefaults() async {
    try {
      await saveDisplayPreferences(FundDisplayPreferences.defaultPreferences());
      await saveFilterPreferences(FundFilterPreferences.defaultPreferences());

      AppLogger.info('🔄 重置为默认设置');
      return true;
    } catch (e) {
      AppLogger.error('❌ 重置默认设置失败', e.toString());
      return false;
    }
  }
}

/// 基金显示偏好设置
class FundDisplayPreferences {
  final bool showRankingBadge;
  final bool showCompanyInfo;
  final bool showFundType;
  final bool showReturnRates;
  final bool showNavInfo;
  final String defaultSortBy;
  final String defaultSortOrder;
  final int itemsPerPage;
  final FundCardSize cardSize;
  final bool enableAnimations;
  final bool showTrendIndicators;
  final bool enableAutoRefresh;
  final Duration autoRefreshInterval;

  const FundDisplayPreferences({
    this.showRankingBadge = true,
    this.showCompanyInfo = true,
    this.showFundType = true,
    this.showReturnRates = true,
    this.showNavInfo = false,
    this.defaultSortBy = 'return1Y',
    this.defaultSortOrder = 'desc',
    this.itemsPerPage = 20,
    this.cardSize = FundCardSize.normal,
    this.enableAnimations = true,
    this.showTrendIndicators = true,
    this.enableAutoRefresh = false,
    this.autoRefreshInterval = const Duration(minutes: 5),
  });

  static FundDisplayPreferences defaultPreferences() {
    return const FundDisplayPreferences();
  }

  FundDisplayPreferences copyWith({
    bool? showRankingBadge,
    bool? showCompanyInfo,
    bool? showFundType,
    bool? showReturnRates,
    bool? showNavInfo,
    String? defaultSortBy,
    String? defaultSortOrder,
    int? itemsPerPage,
    FundCardSize? cardSize,
    bool? enableAnimations,
    bool? showTrendIndicators,
    bool? enableAutoRefresh,
    Duration? autoRefreshInterval,
  }) {
    return FundDisplayPreferences(
      showRankingBadge: showRankingBadge ?? this.showRankingBadge,
      showCompanyInfo: showCompanyInfo ?? this.showCompanyInfo,
      showFundType: showFundType ?? this.showFundType,
      showReturnRates: showReturnRates ?? this.showReturnRates,
      showNavInfo: showNavInfo ?? this.showNavInfo,
      defaultSortBy: defaultSortBy ?? this.defaultSortBy,
      defaultSortOrder: defaultSortOrder ?? this.defaultSortOrder,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      cardSize: cardSize ?? this.cardSize,
      enableAnimations: enableAnimations ?? this.enableAnimations,
      showTrendIndicators: showTrendIndicators ?? this.showTrendIndicators,
      enableAutoRefresh: enableAutoRefresh ?? this.enableAutoRefresh,
      autoRefreshInterval: autoRefreshInterval ?? this.autoRefreshInterval,
    );
  }

  /// 根据字段名和值复制并更新字段
  FundDisplayPreferences copyWithField(String key, dynamic value) {
    switch (key) {
      case 'showRankingBadge':
        return copyWith(showRankingBadge: value as bool?);
      case 'showCompanyInfo':
        return copyWith(showCompanyInfo: value as bool?);
      case 'showFundType':
        return copyWith(showFundType: value as bool?);
      case 'showReturnRates':
        return copyWith(showReturnRates: value as bool?);
      case 'showNavInfo':
        return copyWith(showNavInfo: value as bool?);
      case 'defaultSortBy':
        return copyWith(defaultSortBy: value as String?);
      case 'defaultSortOrder':
        return copyWith(defaultSortOrder: value as String?);
      case 'itemsPerPage':
        return copyWith(itemsPerPage: value as int?);
      case 'cardSize':
        return copyWith(cardSize: value as FundCardSize?);
      case 'enableAnimations':
        return copyWith(enableAnimations: value as bool?);
      case 'showTrendIndicators':
        return copyWith(showTrendIndicators: value as bool?);
      case 'enableAutoRefresh':
        return copyWith(enableAutoRefresh: value as bool?);
      case 'autoRefreshInterval':
        return copyWith(autoRefreshInterval: value as Duration?);
      default:
        return this;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'showRankingBadge': showRankingBadge,
      'showCompanyInfo': showCompanyInfo,
      'showFundType': showFundType,
      'showReturnRates': showReturnRates,
      'showNavInfo': showNavInfo,
      'defaultSortBy': defaultSortBy,
      'defaultSortOrder': defaultSortOrder,
      'itemsPerPage': itemsPerPage,
      'cardSize': cardSize.index,
      'enableAnimations': enableAnimations,
      'showTrendIndicators': showTrendIndicators,
      'enableAutoRefresh': enableAutoRefresh,
      'autoRefreshInterval': autoRefreshInterval.inSeconds,
    };
  }

  static FundDisplayPreferences fromJson(Map<String, dynamic> json) {
    return FundDisplayPreferences(
      showRankingBadge: json['showRankingBadge'] ?? true,
      showCompanyInfo: json['showCompanyInfo'] ?? true,
      showFundType: json['showFundType'] ?? true,
      showReturnRates: json['showReturnRates'] ?? true,
      showNavInfo: json['showNavInfo'] ?? false,
      defaultSortBy: json['defaultSortBy'] ?? 'return1Y',
      defaultSortOrder: json['defaultSortOrder'] ?? 'desc',
      itemsPerPage: json['itemsPerPage'] ?? 20,
      cardSize: FundCardSize.values.elementAt(
        json['cardSize'] ?? 1,
      ),
      enableAnimations: json['enableAnimations'] ?? true,
      showTrendIndicators: json['showTrendIndicators'] ?? true,
      enableAutoRefresh: json['enableAutoRefresh'] ?? false,
      autoRefreshInterval: Duration(
        seconds: json['autoRefreshInterval'] ?? 300,
      ),
    );
  }
}

/// 基金过滤偏好设置
class FundFilterPreferences {
  final List<String> favoriteFundTypes;
  final List<String> excludedFundTypes;
  final List<String> favoriteCompanies;
  final List<String> excludedCompanies;
  final double minReturnRate;
  final double maxReturnRate;
  final double minFundScale;
  final String riskLevel;
  final List<String> investmentRegions;

  const FundFilterPreferences({
    this.favoriteFundTypes = const [],
    this.excludedFundTypes = const [],
    this.favoriteCompanies = const [],
    this.excludedCompanies = const [],
    this.minReturnRate = -100.0,
    this.maxReturnRate = 100.0,
    this.minFundScale = 0.0,
    this.riskLevel = 'all',
    this.investmentRegions = const [],
  });

  static FundFilterPreferences defaultPreferences() {
    return const FundFilterPreferences();
  }

  Map<String, dynamic> toJson() {
    return {
      'favoriteFundTypes': favoriteFundTypes,
      'excludedFundTypes': excludedFundTypes,
      'favoriteCompanies': favoriteCompanies,
      'excludedCompanies': excludedCompanies,
      'minReturnRate': minReturnRate,
      'maxReturnRate': maxReturnRate,
      'minFundScale': minFundScale,
      'riskLevel': riskLevel,
      'investmentRegions': investmentRegions,
    };
  }

  static FundFilterPreferences fromJson(Map<String, dynamic> json) {
    return FundFilterPreferences(
      favoriteFundTypes: List<String>.from(json['favoriteFundTypes'] ?? []),
      excludedFundTypes: List<String>.from(json['excludedFundTypes'] ?? []),
      favoriteCompanies: List<String>.from(json['favoriteCompanies'] ?? []),
      excludedCompanies: List<String>.from(json['excludedCompanies'] ?? []),
      minReturnRate: (json['minReturnRate'] ?? -100.0).toDouble(),
      maxReturnRate: (json['maxReturnRate'] ?? 100.0).toDouble(),
      minFundScale: (json['minFundScale'] ?? 0.0).toDouble(),
      riskLevel: json['riskLevel'] ?? 'all',
      investmentRegions: List<String>.from(json['investmentRegions'] ?? []),
    );
  }
}
