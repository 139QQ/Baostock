import 'dart:async';

import 'package:hive/hive.dart';

import '../../domain/entities/fund_search_criteria.dart';
import '../../domain/entities/fund.dart';
import '../../../../core/utils/logger.dart';

/// 搜索缓存服务
///
/// 专门管理搜索相关数据缓存的服务，提供：
/// - 搜索结果缓存
/// - 搜索历史记录
/// - 搜索建议缓存
/// - 热门搜索缓存
/// - 性能统计缓存
///
/// 缓存策略：
/// - 搜索结果缓存15分钟
/// - 搜索建议缓存30分钟
/// - 搜索历史永久保存
/// - 热门搜索缓存24小时
/// - 性能统计实时更新
class SearchCacheService {
  static String searchResultsBoxName = 'search_results_cache';
  static String searchHistoryBoxName = 'search_history_cache';
  static String searchSuggestionsBoxName = 'search_suggestions_cache';
  static String popularSearchesBoxName = 'popular_searches_cache';
  static String searchStatsBoxName = 'search_stats_cache';

  late Box<Map<String, dynamic>> _searchResultsBox;
  late Box<String> _searchHistoryBox;
  late Box<Map<String, dynamic>> _searchSuggestionsBox;
  late Box<Map<String, dynamic>> _popularSearchesBox;
  late Box<Map<String, dynamic>> _searchStatsBox;

  /// 搜索结果缓存时间（15分钟）
  static Duration searchResultsCacheDuration = const Duration(minutes: 15);

  /// 搜索建议缓存时间（30分钟）
  static Duration searchSuggestionsCacheDuration = const Duration(minutes: 30);

  /// 热门搜索缓存时间（24小时）
  static Duration popularSearchesCacheDuration = const Duration(hours: 24);

  /// 最大搜索历史记录数量
  static int maxSearchHistoryCount = 100;

  /// 最大热门搜索数量
  static int maxPopularSearchesCount = 10;

  /// 初始化缓存服务
  Future<void> initialize() async {
    try {
      // 打开或创建缓存Box
      if (!Hive.isBoxOpen(searchResultsBoxName)) {
        _searchResultsBox = await Hive.openBox<Map<String, dynamic>>(
          searchResultsBoxName,
        );
      } else {
        _searchResultsBox = Hive.box<Map<String, dynamic>>(
          searchResultsBoxName,
        );
      }

      if (!Hive.isBoxOpen(searchHistoryBoxName)) {
        _searchHistoryBox = await Hive.openBox<String>(searchHistoryBoxName);
      } else {
        _searchHistoryBox = Hive.box<String>(searchHistoryBoxName);
      }

      if (!Hive.isBoxOpen(searchSuggestionsBoxName)) {
        _searchSuggestionsBox = await Hive.openBox<Map<String, dynamic>>(
          searchSuggestionsBoxName,
        );
      } else {
        _searchSuggestionsBox = Hive.box<Map<String, dynamic>>(
          searchSuggestionsBoxName,
        );
      }

      if (!Hive.isBoxOpen(popularSearchesBoxName)) {
        _popularSearchesBox = await Hive.openBox<Map<String, dynamic>>(
          popularSearchesBoxName,
        );
      } else {
        _popularSearchesBox = Hive.box<Map<String, dynamic>>(
          popularSearchesBoxName,
        );
      }

      if (!Hive.isBoxOpen(searchStatsBoxName)) {
        _searchStatsBox = await Hive.openBox<Map<String, dynamic>>(
          searchStatsBoxName,
        );
      } else {
        _searchStatsBox = Hive.box<Map<String, dynamic>>(searchStatsBoxName);
      }

      // 清理过期缓存
      await _cleanExpiredCache();
    } catch (e) {
      AppLogger.error('搜索缓存服务初始化失败', e);
    }
  }

  /// 缓存搜索结果
  Future<void> cacheSearchResults(
    FundSearchCriteria criteria,
    List<Fund> results,
  ) async {
    try {
      final cacheKey = criteria.cacheKey;
      final cacheData = {
        'criteria': criteria.toJson(),
        'results': results.map((fund) => fund.toJson()).toList(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'totalCount': results.length,
      };

      await _searchResultsBox.put(cacheKey, cacheData);
    } catch (e) {
      AppLogger.error('缓存搜索结果失败', e);
    }
  }

  /// 获取缓存的搜索结果
  Future<List<Fund>?> getCachedSearchResults(
    FundSearchCriteria criteria,
  ) async {
    try {
      final cacheKey = criteria.cacheKey;
      final cacheData = _searchResultsBox.get(cacheKey);

      if (cacheData == null) return null;

      // 检查缓存是否过期
      final timestamp = cacheData['timestamp'] as int;
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (DateTime.now().difference(cacheTime) > searchResultsCacheDuration) {
        // 缓存过期，删除并返回null
        await _searchResultsBox.delete(cacheKey);
        return null;
      }

      // 解析缓存数据
      final resultsJson = cacheData['results'] as List<dynamic>;
      return resultsJson
          .map((json) => Fund.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.error('获取缓存搜索结果失败', e);
      return null;
    }
  }

  /// 保存搜索历史
  Future<bool> saveSearchHistory(String keyword) async {
    try {
      if (keyword.trim().isEmpty) return false;

      // 移除已存在的相同关键词
      final existingKeywords = _searchHistoryBox.values.toList();
      for (final existingKeyword in existingKeywords) {
        if (existingKeyword == keyword) {
          await _searchHistoryBox.delete(existingKeyword);
          break;
        }
      }

      // 添加到开头
      await _searchHistoryBox.add(keyword);

      // 限制历史记录数量
      final allKeywords = _searchHistoryBox.values.toList();
      if (allKeywords.length > maxSearchHistoryCount) {
        final toDelete = allKeywords.sublist(maxSearchHistoryCount);
        for (final keywordToDelete in toDelete) {
          await _searchHistoryBox.delete(keywordToDelete);
        }
      }

      return true;
    } catch (e) {
      AppLogger.error('保存搜索历史失败', e);
      return false;
    }
  }

  /// 获取搜索历史
  Future<List<String>> getSearchHistory({int limit = 50}) async {
    try {
      final allHistory = _searchHistoryBox.values.toList().reversed.toList();
      return allHistory.take(limit).toList();
    } catch (e) {
      AppLogger.error('获取搜索历史失败', e);
      return [];
    }
  }

  /// 删除搜索历史
  Future<bool> deleteSearchHistory(String keyword) async {
    try {
      final allHistory = _searchHistoryBox.values.toList();
      for (final existingKeyword in allHistory) {
        if (existingKeyword == keyword) {
          await _searchHistoryBox.delete(existingKeyword);
          return true;
        }
      }
      return false;
    } catch (e) {
      AppLogger.error('删除搜索历史失败', e);
      return false;
    }
  }

  /// 清空搜索历史
  Future<bool> clearSearchHistory() async {
    try {
      await _searchHistoryBox.clear();
      return true;
    } catch (e) {
      AppLogger.error('清空搜索历史失败', e);
      return false;
    }
  }

  /// 缓存搜索建议
  Future<void> cacheSearchSuggestions(
    String keyword,
    List<String> suggestions,
  ) async {
    try {
      final cacheData = {
        'keyword': keyword,
        'suggestions': suggestions,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await _searchSuggestionsBox.put(keyword, cacheData);
    } catch (e) {
      AppLogger.error('缓存搜索建议失败', e);
    }
  }

  /// 获取缓存的搜索建议
  Future<List<String>?> getCachedSearchSuggestions(String keyword) async {
    try {
      final cacheData = _searchSuggestionsBox.get(keyword);

      if (cacheData == null) return null;

      // 检查缓存是否过期
      final timestamp = cacheData['timestamp'] as int;
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (DateTime.now().difference(cacheTime) >
          searchSuggestionsCacheDuration) {
        // 缓存过期，删除并返回null
        await _searchSuggestionsBox.delete(keyword);
        return null;
      }

      final suggestions = cacheData['suggestions'] as List<dynamic>;
      return suggestions.map((s) => s.toString()).toList();
    } catch (e) {
      AppLogger.error('获取缓存搜索建议失败', e);
      return null;
    }
  }

  /// 缓存热门搜索
  Future<void> cachePopularSearches(List<String> popularSearches) async {
    try {
      final cacheData = {
        'searches': popularSearches.take(maxPopularSearchesCount).toList(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await _popularSearchesBox.put('popular', cacheData);
    } catch (e) {
      AppLogger.error('缓存热门搜索失败', e);
    }
  }

  /// 获取缓存的热门搜索
  Future<List<String>> getPopularSearches() async {
    try {
      final cacheData = _popularSearchesBox.get('popular');

      if (cacheData == null) return [];

      // 检查缓存是否过期
      final timestamp = cacheData['timestamp'] as int;
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (DateTime.now().difference(cacheTime) > popularSearchesCacheDuration) {
        // 缓存过期，删除并返回空列表
        await _popularSearchesBox.delete('popular');
        return [];
      }

      final searches = cacheData['searches'] as List<dynamic>;
      return searches.map((s) => s.toString()).toList();
    } catch (e) {
      AppLogger.error('获取热门搜索失败', e);
      return [];
    }
  }

  /// 保存搜索统计
  Future<void> saveSearchStatistics(Map<String, dynamic> statistics) async {
    try {
      await _searchStatsBox.put('stats', {
        ...statistics,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      AppLogger.error('保存搜索统计失败', e);
    }
  }

  /// 获取搜索统计
  Future<Map<String, dynamic>> getSearchStatistics() async {
    try {
      final statsData = _searchStatsBox.get('stats');

      if (statsData == null) {
        return _getDefaultStatistics();
      }

      return Map<String, dynamic>.from(statsData);
    } catch (e) {
      AppLogger.error('获取搜索统计失败', e);
      return _getDefaultStatistics();
    }
  }

  /// 获取默认统计信息
  Map<String, dynamic> _getDefaultStatistics() {
    return {
      'averageSearchTime': 0,
      'maxSearchTime': 0,
      'minSearchTime': 0,
      'totalSearches': 0,
      'cacheSize': _searchResultsBox.length,
      'historyCount': _searchHistoryBox.length,
      'lastUpdated': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// 清空搜索缓存
  Future<void> clearSearchCache() async {
    try {
      await Future.wait([
        _searchResultsBox.clear(),
        _searchSuggestionsBox.clear(),
        _popularSearchesBox.clear(),
      ]);
    } catch (e) {
      AppLogger.error('清空搜索缓存失败', e);
    }
  }

  /// 清理过期缓存
  Future<void> _cleanExpiredCache() async {
    try {
      final now = DateTime.now();

      // 清理过期的搜索结果缓存
      final searchResultsKeys = _searchResultsBox.keys.toList();
      for (final key in searchResultsKeys) {
        final cacheData = _searchResultsBox.get(key);
        if (cacheData != null) {
          final timestamp = cacheData['timestamp'] as int;
          final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
          if (now.difference(cacheTime) > searchResultsCacheDuration) {
            await _searchResultsBox.delete(key);
          }
        }
      }

      // 清理过期的搜索建议缓存
      final suggestionKeys = _searchSuggestionsBox.keys.toList();
      for (final key in suggestionKeys) {
        final cacheData = _searchSuggestionsBox.get(key);
        if (cacheData != null) {
          final timestamp = cacheData['timestamp'] as int;
          final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
          if (now.difference(cacheTime) > searchSuggestionsCacheDuration) {
            await _searchSuggestionsBox.delete(key);
          }
        }
      }

      // 清理过期的热门搜索缓存
      final popularData = _popularSearchesBox.get('popular');
      if (popularData != null) {
        final timestamp = popularData['timestamp'] as int;
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        if (now.difference(cacheTime) > popularSearchesCacheDuration) {
          await _popularSearchesBox.delete('popular');
        }
      }
    } catch (e) {
      AppLogger.error('清理过期缓存失败', e);
    }
  }

  /// 获取缓存统计信息
  Map<String, dynamic> getCacheStatistics() {
    return {
      'searchResultsCacheSize': _searchResultsBox.length,
      'searchHistoryCount': _searchHistoryBox.length,
      'searchSuggestionsCacheSize': _searchSuggestionsBox.length,
      'popularSearchesCached': _popularSearchesBox.containsKey('popular'),
      'statisticsCached': _searchStatsBox.containsKey('stats'),
    };
  }

  /// 关闭缓存服务
  Future<void> close() async {
    try {
      await Future.wait([
        _searchResultsBox.close(),
        _searchHistoryBox.close(),
        _searchSuggestionsBox.close(),
        _popularSearchesBox.close(),
        _searchStatsBox.close(),
      ]);
    } catch (e) {
      AppLogger.error('关闭搜索缓存服务失败', e);
    }
  }
}
