import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/logger.dart';

/// Hive缓存管理器
///
/// 负责管理所有Hive缓存相关的操作，包括：
/// - 缓存初始化
/// - 数据存储和读取
/// - 缓存清理
/// - 缓存过期管理
class HiveCacheManager {
  static const String _fundBoxName = 'funds_cache';
  static const String _rankingBoxName = 'rankings_cache';
  static const String _searchBoxName = 'search_cache';
  static const String _settingsBoxName = 'settings_cache';

  // 缓存过期时间（毫秒）
  static const int _defaultCacheDuration = 30 * 60 * 1000; // 30分钟
  static const int _searchCacheDuration = 15 * 60 * 1000; // 15分钟

  // Hive盒子实例
  Box? _fundBox;
  Box? _rankingBox;
  Box? _searchBox;
  Box? _settingsBox;

  /// 初始化Hive缓存
  static Future<void> init() async {
    try {
      // 在Web环境下，Hive会自动使用内存存储
      if (kIsWeb) {
        // Web环境，Hive默认使用内存存储
        developer.log('Web环境使用Hive内存存储', name: 'HiveCacheManager');
      } else {
        // 获取应用文档目录，避免使用系统目录
        final appDocDir = await getApplicationDocumentsDirectory();
        final hiveDir = Directory('${appDocDir.path}/jisu_fund_analyzer/hive');

        // 确保目录存在
        if (!await hiveDir.exists()) {
          await hiveDir.create(recursive: true);
        }

        // 初始化Hive到自定义目录
        Hive.init(hiveDir.path);
      }

      // 注册自定义适配器
      _registerAdapters();

      // 打开所有缓存盒子
      await Future.wait([
        Hive.openBox(_fundBoxName),
        Hive.openBox(_rankingBoxName),
        Hive.openBox(_searchBoxName),
        Hive.openBox(_settingsBoxName),
      ]);

      developer.log('Hive缓存初始化成功', name: 'HiveCacheManager');
    } catch (e) {
      // 如果初始化失败，使用简化的初始化方案
      try {
        developer.log('Hive自定义目录初始化失败，使用默认初始化: $e', name: 'HiveCacheManager');

        if (kIsWeb) {
          // Web环境，Hive默认使用内存存储，不需要显式初始化
          developer.log('Web环境跳过Hive.init()调用', name: 'HiveCacheManager');
        } else {
          // 使用默认目录
          final appDocDir = await getApplicationDocumentsDirectory();
          Hive.init(appDocDir.path);
          developer.log('使用默认目录初始化Hive: ${appDocDir.path}',
              name: 'HiveCacheManager');
        }

        // 打开所有缓存盒子
        await Future.wait([
          Hive.openBox(_fundBoxName),
          Hive.openBox(_rankingBoxName),
          Hive.openBox(_searchBoxName),
          Hive.openBox(_settingsBoxName),
        ]);

        developer.log('Hive默认初始化成功', name: 'HiveCacheManager');
      } catch (fallbackError) {
        // 如果连默认初始化都失败，则禁用缓存功能
        developer.log('Hive初始化完全失败，禁用缓存功能: $fallbackError',
            name: 'HiveCacheManager');
        throw Exception('Hive初始化失败: $fallbackError');
      }
    }
  }

  /// 注册自定义类型适配器
  static void _registerAdapters() {
    // 这里可以注册自定义类型的适配器
    // Hive.registerAdapter(FundAdapter());
    // Hive.registerAdapter(FundRankingAdapter());
  }

  /// 获取缓存管理器实例
  static HiveCacheManager get instance => HiveCacheManager._internal();
  HiveCacheManager._internal();

  /// 获取基金缓存盒子
  Box get fundBox {
    _fundBox ??= Hive.box(_fundBoxName);
    return _fundBox!;
  }

  /// 获取排行榜缓存盒子
  Box get rankingBox {
    _rankingBox ??= Hive.box(_rankingBoxName);
    return _rankingBox!;
  }

  /// 获取搜索缓存盒子
  Box get searchBox {
    _searchBox ??= Hive.box(_searchBoxName);
    return _searchBox!;
  }

  /// 获取设置缓存盒子
  Box get settingsBox {
    _settingsBox ??= Hive.box(_settingsBoxName);
    return _settingsBox!;
  }

  /// 缓存基金数据 - 支持大数据量分页缓存
  Future<void> cacheFunds(String key, List<dynamic> funds,
      {int? duration, int? pageSize}) async {
    final cacheDuration = duration ?? _defaultCacheDuration;
    final effectivePageSize = pageSize ?? 100; // 默认每页100条

    // 如果数据量小于等于分页大小，直接缓存
    if (funds.length <= effectivePageSize) {
      final cacheData = {
        'data': funds,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'duration': cacheDuration,
        'isPaginated': false,
      };

      final jsonString = jsonEncode(cacheData);
      await fundBox.put(key, jsonString);
      AppLogger.database('缓存基金数据', _fundBoxName, '${funds.length} 条记录');
      return;
    }

    // 大数据量分页缓存
    AppLogger.database('分页缓存基金数据', _fundBoxName,
        '${funds.length} 条记录，每页 $effectivePageSize 条');

    final totalPages = (funds.length / effectivePageSize).ceil();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // 缓存分页元数据
    final metadata = {
      'totalItems': funds.length,
      'pageSize': effectivePageSize,
      'totalPages': totalPages,
      'timestamp': timestamp,
      'duration': cacheDuration,
      'isPaginated': true,
    };
    await fundBox.put('${key}_meta', jsonEncode(metadata));

    // 分页缓存数据
    for (int page = 0; page < totalPages; page++) {
      final startIndex = page * effectivePageSize;
      final endIndex = (startIndex + effectivePageSize).clamp(0, funds.length);
      final pageData = funds.sublist(startIndex, endIndex);

      final pageCacheData = {
        'data': pageData,
        'pageNumber': page,
        'timestamp': timestamp,
        'duration': cacheDuration,
        'isPaginated': true,
      };

      final pageKey = '${key}_page_$page';
      await fundBox.put(pageKey, jsonEncode(pageCacheData));
    }

    AppLogger.database(
        '分页缓存完成', _fundBoxName, '$totalPages 页，共 ${funds.length} 条记录');
  }

  /// 获取缓存的基金数据 - 支持分页读取
  List<dynamic>? getCachedFunds(String key, {int? limit, int? offset}) {
    try {
      // 首先检查是否有分页元数据
      final metadataData = fundBox.get('${key}_meta');
      if (metadataData != null) {
        // 分页缓存模式
        return _getPaginatedFunds(key, metadataData,
            limit: limit, offset: offset);
      }

      // 普通缓存模式
      final cachedData = fundBox.get(key);
      if (cachedData == null) return null;

      String jsonString = cachedData as String;

      // 检查是否包含乱码字符，如果有则尝试修复
      if (jsonString.contains(RegExp(r'[Ã¥Ã§ÃÂÂ]'))) {
        try {
          // 尝试修复编码问题
          final bytes = latin1.encode(jsonString);
          jsonString = utf8.decode(bytes);
        } catch (e) {
          AppLogger.warn('缓存编码修复失败', e);
        }
      }

      final decoded = jsonDecode(jsonString);
      final timestamp = decoded['timestamp'] as int;
      final duration = decoded['duration'] as int;
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      // 检查缓存是否过期
      if (currentTime - timestamp > duration) {
        // 缓存过期，删除数据
        fundBox.delete(key);
        return null;
      }

      List<dynamic> data = decoded['data'] as List<dynamic>;

      // 应用分页参数
      if (limit != null || offset != null) {
        final start = offset ?? 0;
        if (start >= data.length) return [];

        final end =
            limit != null ? (start + limit).clamp(0, data.length) : data.length;
        data = data.sublist(start, end);
      }

      return data;
    } catch (e) {
      // 缓存数据损坏，删除并返回null
      AppLogger.error('缓存读取失败', e);
      fundBox.delete(key);
      return null;
    }
  }

  /// 获取分页缓存的基金数据
  List<dynamic>? _getPaginatedFunds(String key, dynamic metadataData,
      {int? limit, int? offset}) {
    try {
      String metadataString = metadataData as String;

      // 修复编码问题
      if (metadataString.contains(RegExp(r'[Ã¥Ã§ÃÂÂ]'))) {
        try {
          final bytes = latin1.encode(metadataString);
          metadataString = utf8.decode(bytes);
        } catch (e) {
          AppLogger.warn('分页元数据编码修复失败', e);
        }
      }

      final metadata = jsonDecode(metadataString);
      final timestamp = metadata['timestamp'] as int;
      final duration = metadata['duration'] as int;
      final totalPages = metadata['totalPages'] as int;
      final totalItems = metadata['totalItems'] as int;
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      // 检查缓存是否过期
      if (currentTime - timestamp > duration) {
        // 清理所有分页数据
        _clearPaginatedCache(key, totalPages);
        return null;
      }

      // 计算需要读取的页面范围
      final startOffset = offset ?? 0;
      final endOffset = limit != null ? startOffset + limit : totalItems;

      if (startOffset >= totalItems) return [];

      final pageSize = metadata['pageSize'] as int;
      final startPage = (startOffset / pageSize).floor();
      final endPage =
          ((endOffset - 1) / pageSize).floor().clamp(0, totalPages - 1);

      List<dynamic> result = [];

      // 读取所需页面
      for (int page = startPage; page <= endPage; page++) {
        final pageKey = '${key}_page_$page';
        final pageData = fundBox.get(pageKey);

        if (pageData == null) {
          AppLogger.warn('分页数据缺失', pageKey);
          continue;
        }

        String pageString = pageData as String;

        // 修复编码问题
        if (pageString.contains(RegExp(r'[Ã¥Ã§ÃÂÂ]'))) {
          try {
            final bytes = latin1.encode(pageString);
            pageString = utf8.decode(bytes);
          } catch (e) {
            AppLogger.warn('分页数据编码修复失败', e);
          }
        }

        final pageDecoded = jsonDecode(pageString);
        final pageItems = pageDecoded['data'] as List<dynamic>;

        // 计算在当前页面中的起始和结束位置
        final pageStartIndex = page == startPage ? (startOffset % pageSize) : 0;
        final pageEndIndex = page == endPage
            ? ((endOffset % pageSize).clamp(0, pageSize))
            : pageSize;

        if (pageStartIndex < pageItems.length) {
          final itemsToAdd = pageItems.sublist(
              pageStartIndex, pageEndIndex.clamp(0, pageItems.length));
          result.addAll(itemsToAdd);
        }
      }

      AppLogger.database('读取分页缓存', _fundBoxName,
          '第${startPage + 1}-${endPage + 1}页，返回 ${result.length} 条记录');
      return result;
    } catch (e) {
      AppLogger.error('分页缓存读取失败', e);
      return null;
    }
  }

  /// 清理分页缓存
  Future<void> _clearPaginatedCache(String key, int totalPages) async {
    try {
      // 清理元数据
      await fundBox.delete('${key}_meta');

      // 清理所有页面数据
      for (int page = 0; page < totalPages; page++) {
        await fundBox.delete('${key}_page_$page');
      }

      AppLogger.database('清理过期分页缓存', _fundBoxName, key);
    } catch (e) {
      AppLogger.error('清理分页缓存失败', e);
    }
  }

  /// 缓存排行榜数据
  Future<void> cacheRankings(String key, List<dynamic> rankings,
      {int? duration}) async {
    final cacheData = {
      'data': rankings,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'duration': duration ?? _defaultCacheDuration,
    };

    // 使用UTF-8编码确保中文字符正确存储
    final jsonString = jsonEncode(cacheData);
    await rankingBox.put(key, jsonString);
  }

  /// 获取缓存的排行榜数据
  List<dynamic>? getCachedRankings(String key) {
    try {
      final cachedData = rankingBox.get(key);
      if (cachedData == null) return null;

      String jsonString = cachedData as String;

      // 检查是否包含乱码字符，如果有则尝试修复
      if (jsonString.contains(RegExp(r'[Ã¥Ã§ÃÂÂ]'))) {
        try {
          // 尝试修复编码问题
          final bytes = latin1.encode(jsonString);
          jsonString = utf8.decode(bytes);
        } catch (e) {
          AppLogger.warn('排行榜缓存编码修复失败', e);
        }
      }

      final decoded = jsonDecode(jsonString);
      final timestamp = decoded['timestamp'] as int;
      final duration = decoded['duration'] as int;
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      // 检查缓存是否过期
      if (currentTime - timestamp > duration) {
        rankingBox.delete(key);
        return null;
      }

      return decoded['data'] as List<dynamic>;
    } catch (e) {
      AppLogger.error('排行榜缓存读取失败', e);
      rankingBox.delete(key);
      return null;
    }
  }

  /// 缓存搜索结果
  Future<void> cacheSearchResults(String query, List<dynamic> results) async {
    final cacheData = {
      'data': results,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'duration': _searchCacheDuration,
    };

    await searchBox.put(query.toLowerCase(), jsonEncode(cacheData));
  }

  /// 获取缓存的搜索结果
  List<dynamic>? getCachedSearchResults(String query) {
    try {
      final cachedData = searchBox.get(query.toLowerCase());
      if (cachedData == null) return null;

      final decoded = jsonDecode(cachedData as String);
      final timestamp = decoded['timestamp'] as int;
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      // 检查缓存是否过期
      if (currentTime - timestamp > _searchCacheDuration) {
        searchBox.delete(query.toLowerCase());
        return null;
      }

      return decoded['data'] as List<dynamic>;
    } catch (e) {
      searchBox.delete(query.toLowerCase());
      return null;
    }
  }

  /// 缓存基金详情
  Future<void> cacheFundDetail(
      String fundCode, Map<String, dynamic> detail) async {
    final cacheData = {
      'data': detail,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'duration': _defaultCacheDuration,
    };

    await fundBox.put('detail_$fundCode', jsonEncode(cacheData));
  }

  /// 获取缓存的基金详情
  Map<String, dynamic>? getCachedFundDetail(String fundCode) {
    try {
      final cachedData = fundBox.get('detail_$fundCode');
      if (cachedData == null) return null;

      final decoded = jsonDecode(cachedData as String);
      final timestamp = decoded['timestamp'] as int;
      final duration = decoded['duration'] as int;
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      // 检查缓存是否过期
      if (currentTime - timestamp > duration) {
        fundBox.delete('detail_$fundCode');
        return null;
      }

      return decoded['data'] as Map<String, dynamic>;
    } catch (e) {
      fundBox.delete('detail_$fundCode');
      return null;
    }
  }

  /// 清理所有缓存
  Future<void> clearAllCache() async {
    await Future.wait([
      fundBox.clear(),
      rankingBox.clear(),
      searchBox.clear(),
    ]);
    AppLogger.database('清理所有缓存', 'cache_manager', '完成');
  }

  /// 清理过期缓存 - 优化版本，支持大数据量
  Future<void> clearExpiredCache({int batchSize = 50}) async {
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    AppLogger.database('开始清理过期缓存', 'cache_manager', '批次大小: $batchSize');

    // 批量清理基金缓存
    await _batchClearExpiredCache(fundBox, currentTime,
        hasDuration: true, batchSize: batchSize, cacheName: '基金缓存');

    // 批量清理排行榜缓存
    await _batchClearExpiredCache(rankingBox, currentTime,
        hasDuration: true, batchSize: batchSize, cacheName: '排行榜缓存');

    // 批量清理搜索缓存
    await _batchClearExpiredCache(searchBox, currentTime,
        hasDuration: false, batchSize: batchSize, cacheName: '搜索缓存');

    AppLogger.business('过期缓存清理完成', 'HiveCacheManager');
  }

  /// 批量清理过期缓存的辅助方法
  Future<void> _batchClearExpiredCache(
    Box box,
    int currentTime, {
    required bool hasDuration,
    required int batchSize,
    required String cacheName,
  }) async {
    try {
      final keys = box.keys.toList();
      final totalKeys = keys.length;

      if (totalKeys == 0) {
        AppLogger.debug('$cacheName: 无数据需要清理');
        return;
      }

      AppLogger.database('开始清理缓存', cacheName, '$totalKeys 条记录');

      List<String> keysToDelete = [];
      int processedCount = 0;

      // 分批处理
      for (int i = 0; i < keys.length; i += batchSize) {
        final batch = keys.skip(i).take(batchSize).toList();

        for (final key in batch) {
          try {
            final cachedData = box.get(key);
            if (cachedData != null) {
              final decoded = jsonDecode(cachedData as String);
              final timestamp = decoded['timestamp'] as int;
              int duration = hasDuration
                  ? decoded['duration'] as int
                  : _searchCacheDuration;

              if (currentTime - timestamp > duration) {
                keysToDelete.add(key as String);
              }
            } else {
              // 数据为空，标记删除
              keysToDelete.add(key as String);
            }
          } catch (e) {
            // 数据损坏，标记删除
            keysToDelete.add(key as String);
          }
          processedCount++;
        }

        // 批量删除
        if (keysToDelete.isNotEmpty) {
          await _batchDelete(box, keysToDelete);
          AppLogger.database('批量删除过期记录', cacheName, '${keysToDelete.length} 条');
          keysToDelete.clear();
        }

        // 显示进度
        if (processedCount % 200 == 0 || processedCount == totalKeys) {
          AppLogger.debug('清理进度: $processedCount/$totalKeys 条记录', cacheName);

          // 让出控制权，避免卡死
          await Future.delayed(const Duration(milliseconds: 200)); // 每批次延迟200毫秒
        }
      }

      AppLogger.database('清理完成', cacheName, '共处理 $processedCount 条记录');
    } catch (e) {
      AppLogger.error('$cacheName 清理失败', e);
    }
  }

  /// 批量删除键值对
  Future<void> _batchDelete(Box box, List<String> keys) async {
    try {
      // 使用事务批量删除
      final deleteFuture = keys.map((key) => box.delete(key));
      await Future.wait(deleteFuture);
    } catch (e) {
      AppLogger.error('批量删除失败', e);
      // 如果批量删除失败，尝试逐个删除
      for (final key in keys) {
        try {
          await box.delete(key);
        } catch (e) {
          AppLogger.error('删除键失败: key: $key', e);
        }
      }
    }
  }

  /// 获取缓存统计信息 - 支持分页缓存统计
  Map<String, dynamic> getCacheStats() {
    // 统计普通缓存和分页缓存
    int fundPaginatedPages = 0;
    int fundPaginatedItems = 0;
    int fundRegularItems = 0;

    final fundKeys = fundBox.keys.toList();
    Set<String> paginatedKeys = {};

    // 查找分页缓存元数据
    for (final key in fundKeys) {
      final keyStr = key.toString();
      if (keyStr.endsWith('_meta')) {
        final baseKey = keyStr.substring(0, keyStr.length - 5);
        paginatedKeys.add(baseKey);
      }
    }

    // 统计分页缓存
    for (final baseKey in paginatedKeys) {
      try {
        final metadata = fundBox.get('${baseKey}_meta');
        if (metadata != null) {
          final decoded = jsonDecode(metadata as String);
          fundPaginatedItems += decoded['totalItems'] as int;
          fundPaginatedPages += decoded['totalPages'] as int;
        }
      } catch (e) {
        AppLogger.warn('统计分页缓存失败', e);
      }
    }

    // 统计普通缓存
    for (final key in fundKeys) {
      final keyStr = key.toString();
      bool isPaginated = false;

      // 检查是否为分页缓存相关
      for (final baseKey in paginatedKeys) {
        if (keyStr.startsWith('${baseKey}_')) {
          isPaginated = true;
          break;
        }
      }

      if (!isPaginated) {
        try {
          final data = fundBox.get(key);
          if (data != null) {
            final decoded = jsonDecode(data as String);
            if (decoded['data'] is List) {
              fundRegularItems += (decoded['data'] as List).length;
            }
          }
        } catch (e) {
          // 忽略统计数据错误
        }
      }
    }

    return {
      'fundCacheCount': fundBox.length,
      'fundRegularItems': fundRegularItems,
      'fundPaginatedPages': fundPaginatedPages,
      'fundPaginatedItems': fundPaginatedItems,
      'fundTotalItems': fundRegularItems + fundPaginatedItems,
      'rankingCacheCount': rankingBox.length,
      'searchCacheCount': searchBox.length,
      'settingsCacheCount': settingsBox.length,
      'totalCacheSize': fundBox.length +
          rankingBox.length +
          searchBox.length +
          settingsBox.length,
    };
  }

  /// 关闭缓存管理器
  Future<void> dispose() async {
    await Future.wait([
      if (_fundBox?.isOpen == true) _fundBox!.close(),
      if (_rankingBox?.isOpen == true) _rankingBox!.close(),
      if (_searchBox?.isOpen == true) _searchBox!.close(),
      if (_settingsBox?.isOpen == true) _settingsBox!.close(),
    ]);
  }
}
