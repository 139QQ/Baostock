import 'package:hive/hive.dart';
import 'dart:convert';

import '../utils/logger.dart';
import '../utils/encoding_helper.dart';

/// 市场数据缓存管理器
/// 提供本地缓存功能，确保离线时也能显示数据
class MarketCacheManager {
  static String cacheBoxName = 'market_cache';
  static Duration cacheValidity = const Duration(minutes: 15); // 缓存15分钟

  static MarketCacheManager? _instance;
  static MarketCacheManager get instance =>
      _instance ??= MarketCacheManager._internal();

  MarketCacheManager._internal();

  Box? _cacheBox;
  bool _isInitialized = false;

  /// 初始化缓存
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _cacheBox = await Hive.openBox(cacheBoxName);
      _isInitialized = true;
      AppLogger.info('📦 市场数据缓存管理器初始化成功');
    } catch (e) {
      AppLogger.error('❌ 缓存初始化失败: $e', e);
      _isInitialized = false;
    }
  }

  /// 获取缓存数据
  T? getCachedData<T>(String key) {
    if (!_isInitialized || _cacheBox == null) return null;

    try {
      final cached = _cacheBox!.get(key);
      if (cached == null) return null;

      final cacheData = Map<String, dynamic>.from(cached);
      final timestamp = DateTime.parse(cacheData['timestamp']);
      final now = DateTime.now();

      // 检查缓存是否过期
      if (now.difference(timestamp) > cacheValidity) {
        AppLogger.debug('⏰ 缓存数据已过期: $key');
        _cacheBox!.delete(key);
        return null;
      }

      // 检查缓存编码信息
      final encoding = cacheData['encoding'] ?? 'unknown';
      AppLogger.debug('🔤 缓存编码格式: $encoding');

      // 获取原始数据字符串
      final dataString = cacheData['data'] as String;
      AppLogger.debug('📋 从缓存获取数据: $key (长度: ${dataString.length})');

      // 验证是否包含中文字符
      final hasChinese = RegExp(r'[\u4e00-\u9fff]').hasMatch(dataString);
      if (hasChinese) {
        AppLogger.debug('🈳 缓存数据包含中文字符');
      }

      // 解析数据
      dynamic parsedData;
      if (T == String) {
        parsedData = dataString; // 如果期望返回String类型，直接返回
      } else {
        try {
          // 使用编码辅助工具进行安全解析
          parsedData = EncodingHelper.safeJsonDecode(dataString);
          if (parsedData == null) {
            AppLogger.warn('⚠️ 使用安全解析失败，尝试标准解析');
            parsedData = jsonDecode(dataString);
          }
        } catch (e) {
          AppLogger.error('❌ 缓存数据JSON解析失败: $e', e);
          return null;
        }
      }

      AppLogger.debug('✅ 缓存数据解析成功: $key');
      return parsedData as T?;
    } catch (e) {
      AppLogger.error('❌ 缓存读取失败: $e', e);
      return null;
    }
  }

  /// 设置缓存数据
  Future<void> setCachedData<T>(String key, T data) async {
    if (!_isInitialized || _cacheBox == null) return;

    try {
      // 将数据序列化为JSON字符串，确保UTF-8编码
      String dataJson;
      if (data is String) {
        dataJson = data;
      } else {
        dataJson = jsonEncode(data);
      }

      // 验证是否包含中文字符
      final hasChinese = RegExp(r'[\u4e00-\u9fff]').hasMatch(dataJson);
      if (hasChinese) {
        AppLogger.debug('🈳 缓存数据包含中文字符，确保UTF-8编码');
      }

      final cacheData = {
        'data': dataJson,
        'dataType': data.runtimeType.toString(),
        'timestamp': DateTime.now().toIso8601String(),
        'encoding': 'utf-8',
      };

      await _cacheBox!.put(key, cacheData);
      AppLogger.debug('💾 数据已缓存: $key (编码: UTF-8)');
    } catch (e) {
      AppLogger.error('❌ 缓存写入失败: $e', e);
    }
  }

  /// 清除特定缓存
  Future<void> clearCache(String key) async {
    if (!_isInitialized || _cacheBox == null) return;

    try {
      await _cacheBox!.delete(key);
      AppLogger.debug('🗑️ 缓存已清除: $key');
    } catch (e) {
      AppLogger.error('❌ 缓存清除失败: $e', e);
    }
  }

  /// 清除所有缓存
  Future<void> clearAllCache() async {
    if (!_isInitialized || _cacheBox == null) return;

    try {
      await _cacheBox!.clear();
      AppLogger.info('🧹 所有缓存已清除');
    } catch (e) {
      AppLogger.error('❌ 缓存清空失败: $e', e);
    }
  }

  /// 获取缓存统计信息
  Map<String, dynamic> getCacheStats() {
    if (!_isInitialized || _cacheBox == null) {
      return {'initialized': false, 'count': 0};
    }

    final keys = _cacheBox!.keys.toList();
    final expiredCount = keys.where((key) {
      final cached = _cacheBox!.get(key);
      if (cached == null) return false;

      try {
        final cacheData = Map<String, dynamic>.from(cached);
        final timestamp = DateTime.parse(cacheData['timestamp']);
        final now = DateTime.now();
        return now.difference(timestamp) > cacheValidity;
      } catch (e) {
        return true; // 解析失败认为已过期
      }
    }).length;

    return {
      'initialized': true,
      'totalKeys': keys.length,
      'expiredKeys': expiredCount,
      'validKeys': keys.length - expiredCount,
    };
  }
}

/// 缓存键定义
class CacheKeys {
  static String marketIndices = 'market_indices';
  static String marketOverview = 'market_overview';
  static String fundRankings = 'fund_rankings';
  static String sectorData = 'sector_data';

  /// 生成基金排行缓存键
  static String fundRankingKey(String symbol, int page, int pageSize) {
    return 'fund_ranking_$symbol$page$pageSize';
  }

  /// 生成指数数据缓存键
  static String indexDataKey(String symbol) {
    return 'index_data_$symbol';
  }
}
