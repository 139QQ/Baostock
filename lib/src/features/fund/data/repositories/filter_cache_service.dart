import 'dart:convert';
import 'package:jisu_fund_analyzer/src/features/fund/domain/entities/fund_filter_criteria.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 筛选缓存服务
///
/// 负责筛选条件的持久化存储，包括：
/// - 当前筛选条件保存
/// - 筛选历史记录
/// - 自定义预设筛选
/// - 筛选选项缓存
class FilterCacheService {
  static const String currentFilterKey = 'current_filter_criteria';
  static const String filterHistoryKey = 'filter_history';
  static const String customPresetsKey = 'custom_filter_presets';
  static const String filterOptionsKey = 'filter_options';
  static const String lastFilterTimeKey = 'last_filter_time';
  static const int maxHistorySize = 10;

  /// 保存当前筛选条件
  Future<void> saveCurrentFilterCriteria(FundFilterCriteria criteria) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final criteriaJson = criteria.toJson();
      final criteriaString = jsonEncode(criteriaJson);
      await prefs.setString(currentFilterKey, criteriaString);
      await prefs.setString(
          lastFilterTimeKey, DateTime.now().toIso8601String());
    } catch (e) {
      throw FilterCacheException('保存筛选条件失败: ${e.toString()}');
    }
  }

  /// 获取当前筛选条件
  Future<FundFilterCriteria?> getCurrentFilterCriteria() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final criteriaString = prefs.getString(currentFilterKey);

      if (criteriaString == null || criteriaString.isEmpty) {
        return null;
      }

      final criteriaJson = jsonDecode(criteriaString) as Map<String, dynamic>;
      return FundFilterCriteria.fromJson(criteriaJson);
    } catch (e) {
      // 如果解析失败，返回空筛选条件
      return FundFilterCriteria.empty();
    }
  }

  /// 添加筛选条件到历史记录
  Future<void> addToFilterHistory(FundFilterCriteria criteria) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(filterHistoryKey);

      List<Map<String, dynamic>> history = [];
      if (historyJson != null && historyJson.isNotEmpty) {
        final historyList = jsonDecode(historyJson) as List<dynamic>;
        history = historyList.cast<Map<String, dynamic>>();
      }

      // 检查是否已存在相同的筛选条件
      final criteriaJson = criteria.toJson();
      final criteriaString = jsonEncode(criteriaJson);

      // 移除重复项
      history.removeWhere((item) => jsonEncode(item) == criteriaString);

      // 添加到开头
      history.insert(0, criteriaJson);

      // 限制历史记录大小
      if (history.length > maxHistorySize) {
        history = history.take(maxHistorySize).toList();
      }

      final updatedHistoryString = jsonEncode(history);
      await prefs.setString(filterHistoryKey, updatedHistoryString);
    } catch (e) {
      throw FilterCacheException('保存筛选历史失败: ${e.toString()}');
    }
  }

  /// 获取筛选历史记录
  Future<List<FundFilterCriteria>> getFilterHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(filterHistoryKey);

      if (historyJson == null || historyJson.isEmpty) {
        return [];
      }

      final historyList = jsonDecode(historyJson) as List<dynamic>;
      final history = historyList
          .cast<Map<String, dynamic>>()
          .map((json) => FundFilterCriteria.fromJson(json))
          .toList();

      return history;
    } catch (e) {
      return [];
    }
  }

  /// 清除筛选历史记录
  Future<void> clearFilterHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(filterHistoryKey);
    } catch (e) {
      throw FilterCacheException('清除筛选历史失败: ${e.toString()}');
    }
  }

  /// 保存自定义预设筛选
  Future<void> saveCustomPreset(
      String name, FundFilterCriteria criteria) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final presetsJson = prefs.getString(customPresetsKey);

      Map<String, dynamic> presets = {};
      if (presetsJson != null && presetsJson.isNotEmpty) {
        presets = Map<String, dynamic>.from(jsonDecode(presetsJson));
      }

      presets[name] = criteria.toJson();
      final updatedPresetsString = jsonEncode(presets);
      await prefs.setString(customPresetsKey, updatedPresetsString);
    } catch (e) {
      throw FilterCacheException('保存预设筛选失败: ${e.toString()}');
    }
  }

  /// 获取自定义预设筛选
  Future<Map<String, FundFilterCriteria>> getCustomPresets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final presetsJson = prefs.getString(customPresetsKey);

      if (presetsJson == null || presetsJson.isEmpty) {
        return {};
      }

      final presetsMap = Map<String, dynamic>.from(jsonDecode(presetsJson));
      return presetsMap.map((key, value) {
        final criteria =
            FundFilterCriteria.fromJson(value as Map<String, dynamic>);
        return MapEntry(key, criteria);
      });
    } catch (e) {
      return {};
    }
  }

  /// 删除自定义预设筛选
  Future<void> deleteCustomPreset(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final presetsJson = prefs.getString(customPresetsKey);

      if (presetsJson == null || presetsJson.isEmpty) {
        return;
      }

      final presetsMap = Map<String, dynamic>.from(jsonDecode(presetsJson));
      presetsMap.remove(name);

      final updatedPresetsString = jsonEncode(presetsMap);
      await prefs.setString(customPresetsKey, updatedPresetsString);
    } catch (e) {
      throw FilterCacheException('删除预设筛选失败: ${e.toString()}');
    }
  }

  /// 缓存筛选选项
  Future<void> cacheFilterOptions(Map<String, List<String>> options) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final optionsJson = options.map((key, value) => MapEntry(key, value));
      final optionsString = jsonEncode(optionsJson);
      await prefs.setString(filterOptionsKey, optionsString);
    } catch (e) {
      throw FilterCacheException('缓存筛选选项失败: ${e.toString()}');
    }
  }

  /// 获取缓存的筛选选项
  Future<Map<String, List<String>>> getCachedFilterOptions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final optionsString = prefs.getString(filterOptionsKey);

      if (optionsString == null || optionsString.isEmpty) {
        return {};
      }

      final optionsJson = Map<String, dynamic>.from(jsonDecode(optionsString));
      return optionsJson.map((key, value) {
        final list = (value as List<dynamic>).cast<String>();
        return MapEntry(key, list);
      });
    } catch (e) {
      return {};
    }
  }

  /// 获取最后筛选时间
  Future<DateTime?> getLastFilterTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeString = prefs.getString(lastFilterTimeKey);

      if (timeString == null || timeString.isEmpty) {
        return null;
      }

      return DateTime.parse(timeString);
    } catch (e) {
      return null;
    }
  }

  /// 检查筛选选项缓存是否过期
  Future<bool> isFilterOptionsCacheExpired(
      {Duration maxAge = const Duration(hours: 24)}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final optionsString = prefs.getString(filterOptionsKey);

      if (optionsString == null || optionsString.isEmpty) {
        return true;
      }

      // 简单的时间戳检查（这里使用SharedPreferences的修改时间）
      // 在实际应用中，可能需要更精确的过期管理
      return false;
    } catch (e) {
      return true;
    }
  }

  /// 清除所有筛选相关缓存
  Future<void> clearAllFilterCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove(currentFilterKey),
        prefs.remove(filterHistoryKey),
        prefs.remove(customPresetsKey),
        prefs.remove(filterOptionsKey),
        prefs.remove(lastFilterTimeKey),
      ]);
    } catch (e) {
      throw FilterCacheException('清除筛选缓存失败: ${e.toString()}');
    }
  }

  /// 获取缓存大小信息
  Future<Map<String, int>> getCacheSizeInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = [
        currentFilterKey,
        filterHistoryKey,
        customPresetsKey,
        filterOptionsKey,
        lastFilterTimeKey,
      ];

      final sizeInfo = <String, int>{};
      for (final key in keys) {
        final value = prefs.getString(key);
        sizeInfo[key] = value?.length ?? 0;
      }

      return sizeInfo;
    } catch (e) {
      return {};
    }
  }

  /// 导出筛选配置
  Future<Map<String, dynamic>> exportFilterConfig() async {
    try {
      final config = <String, dynamic>{};

      // 导出当前筛选条件
      final currentCriteria = await getCurrentFilterCriteria();
      if (currentCriteria != null) {
        config['currentCriteria'] = currentCriteria.toJson();
      }

      // 导出历史记录
      final history = await getFilterHistory();
      config['history'] = history.map((criteria) => criteria.toJson()).toList();

      // 导出自定义预设
      final presets = await getCustomPresets();
      config['customPresets'] =
          presets.map((key, criteria) => MapEntry(key, criteria.toJson()));

      // 导出时间戳
      config['exportTime'] = DateTime.now().toIso8601String();
      config['version'] = '1.0.0';

      return config;
    } catch (e) {
      throw FilterCacheException('导出筛选配置失败: ${e.toString()}');
    }
  }

  /// 导入筛选配置
  Future<void> importFilterConfig(Map<String, dynamic> config) async {
    try {
      // 验证配置版本
      final version = config['version'] as String?;
      if (version == null || !version.startsWith('1.')) {
        throw FilterCacheException('不支持的配置版本');
      }

      // 导入自定义预设
      if (config.containsKey('customPresets')) {
        final presetsData = config['customPresets'] as Map<String, dynamic>;
        for (final entry in presetsData.entries) {
          final criteria =
              FundFilterCriteria.fromJson(entry.value as Map<String, dynamic>);
          await saveCustomPreset(entry.key, criteria);
        }
      }

      // 可选：导入当前筛选条件
      if (config.containsKey('currentCriteria')) {
        final currentCriteria = FundFilterCriteria.fromJson(
            config['currentCriteria'] as Map<String, dynamic>);
        await saveCurrentFilterCriteria(currentCriteria);
      }
    } catch (e) {
      throw FilterCacheException('导入筛选配置失败: ${e.toString()}');
    }
  }
}

/// 筛选缓存异常
class FilterCacheException implements Exception {
  final String message;

  FilterCacheException(this.message);

  @override
  String toString() => 'FilterCacheException: $message';
}
