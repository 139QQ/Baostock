import 'dart:convert';
import 'package:hive/hive.dart';
import '../../domain/entities/fund.dart';
import '../../domain/entities/fund_filter_criteria.dart';
import '../../domain/entities/fund_ranking.dart';

/// 基金本地数据源抽象类
abstract class FundLocalDataSource {
  /// 获取缓存的基金列表
  Future<List<Fund>> getCachedFundList();

  /// 缓存基金列表
  Future<void> cacheFundList(List<Fund> funds);

  /// 获取缓存的筛选结果
  Future<List<Fund>> getCachedFilteredFunds(FundFilterCriteria criteria);

  /// 缓存筛选结果
  Future<void> cacheFilteredFunds(
      FundFilterCriteria criteria, List<Fund> funds);

  /// 获取筛选结果总数
  Future<int?> getCachedFilteredFundsCount(FundFilterCriteria criteria);

  /// 缓存筛选结果总数
  Future<void> cacheFilteredFundsCount(FundFilterCriteria criteria, int count);

  /// 获取筛选选项缓存
  Future<List<String>?> getCachedFilterOptions(FilterType type);

  /// 缓存筛选选项
  Future<void> cacheFilterOptions(FilterType type, List<String> options);

  /// 清除过期缓存
  Future<void> clearExpiredCache();

  /// 检查缓存是否有效
  Future<bool> isCacheValid({Duration maxAge = const Duration(minutes: 15)});

  /// 获取缓存大小信息
  Future<Map<String, int>> getCacheSizeInfo();

  // ===== 排行榜缓存功能 =====

  /// 获取缓存的排行榜数据
  Future<PaginatedRankingResult?> getCachedRankings(RankingCriteria criteria);

  /// 缓存排行榜数据
  Future<void> cacheRankings(
      RankingCriteria criteria, PaginatedRankingResult result);

  /// 获取排行榜更新时间
  Future<DateTime?> getRankingUpdateTime(
      RankingType? rankingType, RankingPeriod? period);

  /// 保存收藏基金列表
  Future<bool> saveFavoriteFunds(Set<String> fundCodes);

  /// 获取收藏基金列表
  Future<Set<String>> getFavoriteFunds();

  /// 清空排行榜缓存
  Future<void> clearRankingCache();
}

/// 基金本地数据源实现类
class FundLocalDataSourceImpl implements FundLocalDataSource {
  static const String _fundListKey = 'cached_fund_list';
  static const String _fundListTimestampKey = 'fund_list_timestamp';
  static const String _filteredResultsPrefix = 'filtered_results_';
  static const String _filterOptionsPrefix = 'filter_options_';
  static const String _filterCountPrefix = 'filter_count_';
  static const String _cacheInfoKey = 'cache_info';
  static const String _rankingsPrefix = 'rankings_';
  static const String _favoriteFundsKey = 'favorite_funds';
  static const String _rankingUpdateTimePrefix = 'ranking_update_time_';

  final Box _cacheBox;

  FundLocalDataSourceImpl(this._cacheBox);

  @override
  Future<List<Fund>> getCachedFundList() async {
    try {
      final cachedData = _cacheBox.get(_fundListKey);
      if (cachedData == null || cachedData.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(cachedData);
      return jsonList
          .map((json) => Fund.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('获取缓存基金列表失败: $e');
    }
  }

  @override
  Future<void> cacheFundList(List<Fund> funds) async {
    try {
      final jsonList = funds.map((fund) => fund.toJson()).toList();
      final jsonString = jsonEncode(jsonList);

      await _cacheBox.put(_fundListKey, jsonString);
      await _cacheBox.put(
          _fundListTimestampKey, DateTime.now().toIso8601String());

      // 更新缓存信息
      await _updateCacheInfo('fund_list', jsonString.length);
    } catch (e) {
      throw Exception('缓存基金列表失败: $e');
    }
  }

  @override
  Future<List<Fund>> getCachedFilteredFunds(FundFilterCriteria criteria) async {
    try {
      final cacheKey = _generateFilterCacheKey(criteria);
      final cachedData = _cacheBox.get(cacheKey);

      if (cachedData == null || cachedData.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(cachedData);
      return jsonList
          .map((json) => Fund.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('获取缓存筛选结果失败: $e');
    }
  }

  @override
  Future<void> cacheFilteredFunds(
      FundFilterCriteria criteria, List<Fund> funds) async {
    try {
      final cacheKey = _generateFilterCacheKey(criteria);
      final jsonList = funds.map((fund) => fund.toJson()).toList();
      final jsonString = jsonEncode(jsonList);

      await _cacheBox.put(cacheKey, jsonString);
      await _updateCacheInfo(cacheKey, jsonString.length);
    } catch (e) {
      throw Exception('缓存筛选结果失败: $e');
    }
  }

  @override
  Future<int?> getCachedFilteredFundsCount(FundFilterCriteria criteria) async {
    try {
      final cacheKey = _generateFilterCountKey(criteria);
      final cachedCount = _cacheBox.get(cacheKey);

      if (cachedCount == null || cachedCount.isEmpty) {
        return null;
      }

      return int.tryParse(cachedCount);
    } catch (e) {
      throw Exception('获取缓存筛选结果数量失败: $e');
    }
  }

  @override
  Future<void> cacheFilteredFundsCount(
      FundFilterCriteria criteria, int count) async {
    try {
      final cacheKey = _generateFilterCountKey(criteria);
      await _cacheBox.put(cacheKey, count.toString());
      await _updateCacheInfo(cacheKey, count.toString().length);
    } catch (e) {
      throw Exception('缓存筛选结果数量失败: $e');
    }
  }

  @override
  Future<List<String>?> getCachedFilterOptions(FilterType type) async {
    try {
      final cacheKey = _generateFilterOptionsKey(type);
      final cachedData = _cacheBox.get(cacheKey);

      if (cachedData == null || cachedData.isEmpty) {
        return null;
      }

      final List<dynamic> jsonList = jsonDecode(cachedData);
      return jsonList.cast<String>();
    } catch (e) {
      throw Exception('获取缓存筛选选项失败: $e');
    }
  }

  @override
  Future<void> cacheFilterOptions(FilterType type, List<String> options) async {
    try {
      final cacheKey = _generateFilterOptionsKey(type);
      final jsonString = jsonEncode(options);

      await _cacheBox.put(cacheKey, jsonString);
      await _updateCacheInfo(cacheKey, jsonString.length);
    } catch (e) {
      throw Exception('缓存筛选选项失败: $e');
    }
  }

  @override
  Future<void> clearExpiredCache() async {
    try {
      final now = DateTime.now();
      const maxAge = Duration(minutes: 15);
      final cutoffTime = now.subtract(maxAge);

      // 获取基金列表时间戳
      final fundListTimestampStr = _cacheBox.get(_fundListTimestampKey);
      if (fundListTimestampStr != null) {
        final fundListTimestamp = DateTime.tryParse(fundListTimestampStr);
        if (fundListTimestamp != null &&
            fundListTimestamp.isBefore(cutoffTime)) {
          await _cacheBox.delete(_fundListKey);
          await _cacheBox.delete(_fundListTimestampKey);
        }
      }

      // 清除过期的筛选结果缓存
      final keysToDelete = <String>[];
      for (final key in _cacheBox.keys) {
        if (key.startsWith(_filteredResultsPrefix)) {
          // 检查是否过期（简化实现，实际可以基于时间戳）
          final timestampStr = _cacheBox.get('${key}_timestamp');
          if (timestampStr != null) {
            final timestamp = DateTime.tryParse(timestampStr);
            if (timestamp != null && timestamp.isBefore(cutoffTime)) {
              keysToDelete.add(key);
              keysToDelete.add('${key}_timestamp');
            }
          }
        }
      }

      for (final key in keysToDelete) {
        await _cacheBox.delete(key);
      }
    } catch (e) {
      throw Exception('清除过期缓存失败: $e');
    }
  }

  @override
  Future<bool> isCacheValid(
      {Duration maxAge = const Duration(minutes: 15)}) async {
    try {
      final timestampStr = _cacheBox.get(_fundListTimestampKey);
      if (timestampStr == null || timestampStr.isEmpty) {
        return false;
      }

      final timestamp = DateTime.tryParse(timestampStr);
      if (timestamp == null) {
        return false;
      }

      final cutoffTime = DateTime.now().subtract(maxAge);
      return timestamp.isAfter(cutoffTime);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Map<String, int>> getCacheSizeInfo() async {
    try {
      final cacheInfoStr = _cacheBox.get(_cacheInfoKey);
      if (cacheInfoStr == null || cacheInfoStr.isEmpty) {
        return {};
      }

      final Map<String, dynamic> cacheInfo = jsonDecode(cacheInfoStr);
      return cacheInfo
          .map((key, value) => MapEntry(key, (value as num).toInt()));
    } catch (e) {
      return {};
    }
  }

  /// 生成筛选结果缓存键
  String _generateFilterCacheKey(FundFilterCriteria criteria) {
    final keyParts = [
      _filteredResultsPrefix,
      criteria.fundTypes?.join(',') ?? '',
      criteria.companies?.join(',') ?? '',
      criteria.scaleRange?.toString() ?? '',
      criteria.establishmentDateRange?.toString() ?? '',
      criteria.riskLevels?.join(',') ?? '',
      criteria.returnRange?.toString() ?? '',
      criteria.statuses?.join(',') ?? '',
      criteria.sortBy ?? '',
      criteria.sortDirection?.name ?? '',
      criteria.page.toString(),
      criteria.pageSize.toString(),
    ];
    return keyParts.join('|');
  }

  /// 生成筛选数量缓存键
  String _generateFilterCountKey(FundFilterCriteria criteria) {
    final cacheKey = _generateFilterCacheKey(criteria);
    return '$_filterCountPrefix${cacheKey.substring(_filteredResultsPrefix.length)}';
  }

  /// 生成筛选选项缓存键
  String _generateFilterOptionsKey(FilterType type) {
    return '$_filterOptionsPrefix${type.name}';
  }

  /// 更新缓存信息
  Future<void> _updateCacheInfo(String key, int size) async {
    try {
      final cacheInfoStr = _cacheBox.get(_cacheInfoKey);
      Map<String, dynamic> cacheInfo = {};

      if (cacheInfoStr != null && cacheInfoStr.isNotEmpty) {
        cacheInfo = jsonDecode(cacheInfoStr);
      }

      cacheInfo[key] = size;
      cacheInfo['last_updated'] = DateTime.now().toIso8601String();

      await _cacheBox.put(_cacheInfoKey, jsonEncode(cacheInfo));
    } catch (e) {
      // 忽略缓存信息更新错误，不影响主流程
    }
  }

  /// 清除所有缓存
  Future<void> clearAllCache() async {
    try {
      final keysToDelete = <String>[];

      for (final key in _cacheBox.keys) {
        if (key.startsWith(_filteredResultsPrefix) ||
            key.startsWith(_filterOptionsPrefix) ||
            key.startsWith(_filterCountPrefix) ||
            key.startsWith(_rankingsPrefix) ||
            key == _fundListKey ||
            key == _fundListTimestampKey ||
            key == _cacheInfoKey ||
            key == _favoriteFundsKey ||
            key.startsWith(_rankingUpdateTimePrefix)) {
          keysToDelete.add(key);
        }
      }

      for (final key in keysToDelete) {
        await _cacheBox.delete(key);
      }
    } catch (e) {
      throw Exception('清除所有缓存失败: $e');
    }
  }

  // ===== 排行榜缓存功能实现 =====

  @override
  Future<PaginatedRankingResult?> getCachedRankings(
      RankingCriteria criteria) async {
    try {
      final cacheKey = _generateRankingsCacheKey(criteria);
      final cachedData = _cacheBox.get(cacheKey);

      if (cachedData == null || cachedData.isEmpty) {
        return null;
      }

      final Map<String, dynamic> jsonMap = jsonDecode(cachedData);
      return PaginatedRankingResult.fromJson(jsonMap);
    } catch (e) {
      throw Exception('获取缓存排行榜失败: $e');
    }
  }

  @override
  Future<void> cacheRankings(
      RankingCriteria criteria, PaginatedRankingResult result) async {
    try {
      final cacheKey = _generateRankingsCacheKey(criteria);
      final jsonString = jsonEncode(result.toJson());

      await _cacheBox.put(cacheKey, jsonString);
      await _updateCacheInfo(cacheKey, jsonString.length);
    } catch (e) {
      throw Exception('缓存排行榜失败: $e');
    }
  }

  @override
  Future<DateTime?> getRankingUpdateTime(
      RankingType? rankingType, RankingPeriod? period) async {
    try {
      final cacheKey = _generateRankingUpdateTimeKey(rankingType, period);
      final timeStr = _cacheBox.get(cacheKey);

      if (timeStr == null || timeStr.isEmpty) {
        return null;
      }

      return DateTime.tryParse(timeStr);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> saveFavoriteFunds(Set<String> fundCodes) async {
    try {
      final jsonString = jsonEncode(fundCodes.toList());
      await _cacheBox.put(_favoriteFundsKey, jsonString);
      await _updateCacheInfo(_favoriteFundsKey, jsonString.length);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Set<String>> getFavoriteFunds() async {
    try {
      final cachedData = _cacheBox.get(_favoriteFundsKey);

      if (cachedData == null || cachedData.isEmpty) {
        return {};
      }

      final List<dynamic> jsonList = jsonDecode(cachedData);
      return jsonList.cast<String>().toSet();
    } catch (e) {
      return {};
    }
  }

  @override
  Future<void> clearRankingCache() async {
    try {
      final keysToDelete = <String>[];

      for (final key in _cacheBox.keys) {
        if (key.startsWith(_rankingsPrefix) ||
            key.startsWith(_rankingUpdateTimePrefix)) {
          keysToDelete.add(key);
        }
      }

      for (final key in keysToDelete) {
        await _cacheBox.delete(key);
      }
    } catch (e) {
      throw Exception('清空排行榜缓存失败: $e');
    }
  }

  /// 生成排行榜缓存键
  String _generateRankingsCacheKey(RankingCriteria criteria) {
    final keyParts = [
      _rankingsPrefix,
      criteria.rankingType.name,
      criteria.rankingPeriod.name,
      criteria.fundType ?? '',
      criteria.company ?? '',
      criteria.sortBy.name,
      criteria.page.toString(),
      criteria.pageSize.toString(),
    ];
    return keyParts.join('|');
  }

  /// 生成排行榜更新时间缓存键
  String _generateRankingUpdateTimeKey(
      RankingType? rankingType, RankingPeriod? period) {
    final keyParts = [
      _rankingUpdateTimePrefix,
      rankingType?.name ?? 'overall',
      period?.name ?? 'oneMonth',
    ];
    return keyParts.join('|');
  }
}
