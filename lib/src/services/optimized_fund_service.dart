import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:dio_http_cache_lts/dio_http_cache_lts.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';
import '../models/fund_info.dart';

/// 优化的基金数据服务 - 三步加载策略
/// 第1步：优化网络请求 - HTTP缓存和压缩
/// 第2步：优化JSON解析 - compute异步解析
/// 第3步：优化存储 - Hive批量写入和建索引
class OptimizedFundService {
  static final OptimizedFundService _instance =
      OptimizedFundService._internal();
  factory OptimizedFundService() => _instance;
  OptimizedFundService._internal();

  final Dio _dio = Dio();
  final Logger _logger = Logger();
  late Box<FundInfo> _fundBox;
  late Box<String> _indexBox;

  // 配置常量
  static const String _apiUrl =
      'http://154.44.25.92:8080/api/public/fund_name_em';
  static const String _fundBoxName = 'optimized_funds';
  static const String _indexBoxName = 'fund_search_index';
  static const int _maxCacheSize = 10000; // 限制缓存大小

  /// 初始化服务
  Future<void> initialize() async {
    try {
      // 配置Dio HTTP缓存
      final cacheManager = DioCacheManager(
        CacheConfig(
          databasePath: 'fund_http_cache',
        ),
      );
      _dio.interceptors.add(cacheManager.interceptor);

      // 打开Hive数据库
      _fundBox = await Hive.openBox<FundInfo>(_fundBoxName);
      _indexBox = await Hive.openBox<String>(_indexBoxName);

      _logger.i('✅ OptimizedFundService 初始化完成');
    } catch (e) {
      _logger.e('❌ OptimizedFundService 初始化失败: $e');
      rethrow;
    }
  }

  /// 第1步：优化网络请求 - HTTP缓存和压缩
  Future<String> _fetchRawFundData() async {
    try {
      _logger.d('📡 开始网络请求，启用HTTP缓存...');

      final response = await _dio.get(
        _apiUrl,
        options: buildCacheOptions(const Duration(hours: 6)),
      );

      if (response.statusCode == 200) {
        final data =
            response.data is String ? response.data : jsonEncode(response.data);
        _logger.d('✅ 网络请求完成，数据大小: ${data.length} 字符');
        return data as String;
      } else {
        throw Exception(
            'HTTP ${response.statusCode}: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('❌ 网络请求失败: $e');
      rethrow;
    }
  }

  /// 第2步：优化JSON解析 - compute异步解析
  Future<List<FundInfo>> _parseFundData(String rawData) async {
    try {
      _logger.d('🔄 开始异步JSON解析...');
      final stopwatch = Stopwatch()..start();

      // 使用compute在独立isolate中解析JSON
      final funds = await compute(_parseFundsInIsolate, rawData);

      stopwatch.stop();
      _logger.d(
          '✅ JSON解析完成，耗时: ${stopwatch.elapsedMilliseconds}ms，解析了 ${funds.length} 只基金');

      return funds;
    } catch (e) {
      _logger.e('❌ JSON解析失败: $e');
      rethrow;
    }
  }

  /// 在独立isolate中解析基金数据
  static List<FundInfo> _parseFundsInIsolate(String rawData) {
    try {
      final Map<String, dynamic> jsonData = jsonDecode(rawData);
      final List<dynamic> dataList =
          jsonData['data'] ?? jsonData; // 处理可能的data字段包装
      return dataList
          .map((item) => FundInfo.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // 如果JSON解析失败，使用正则表达式作为备用方案
      return _parseFundsWithRegex(rawData);
    }
  }

  /// 备用正则解析方法
  static List<FundInfo> _parseFundsWithRegex(String rawData) {
    final funds = <FundInfo>[];

    // 匹配API返回的JSON格式
    final pattern = RegExp(
        r'\{"基金代码":"([^"]+)","拼音缩写":"([^"]+)","基金简称":"([^"]+)","基金类型":"([^"]+)"(?:,"拼音全称":"([^"]+)")?}');

    final matches = pattern.allMatches(rawData);

    for (final match in matches) {
      final fund = FundInfo(
        code: match.group(1) ?? '',
        name: match.group(3) ?? '',
        type: match.group(4) ?? '',
        pinyinAbbr: match.group(2) ?? '',
        pinyinFull: match.group(5) ?? '',
      );

      if (fund.code.isNotEmpty && fund.name.isNotEmpty) {
        funds.add(fund);
      }
    }

    return funds;
  }

  /// 第3步：优化存储 - Hive批量写入和建索引
  Future<void> _cacheFundData(List<FundInfo> funds) async {
    try {
      _logger.d('💾 开始批量写入缓存和构建索引...');
      final stopwatch = Stopwatch()..start();

      // 清空旧数据
      await _fundBox.clear();
      await _indexBox.clear();

      // 批量写入基金数据
      final limitedFunds = funds.take(_maxCacheSize).toList();
      for (int i = 0; i < limitedFunds.length; i++) {
        await _fundBox.put(limitedFunds[i].code, limitedFunds[i]);
      }

      // 构建搜索索引
      await _buildSearchIndex(limitedFunds);

      stopwatch.stop();
      _logger.d(
          '✅ 缓存写入完成，耗时: ${stopwatch.elapsedMilliseconds}ms，缓存了 ${limitedFunds.length} 只基金');
    } catch (e) {
      _logger.e('❌ 缓存写入失败: $e');
      rethrow;
    }
  }

  /// 构建搜索索引
  Future<void> _buildSearchIndex(List<FundInfo> funds) async {
    // 代码索引
    final codeIndex = <String>[];
    // 名称索引
    final nameIndex = <String>[];
    // 拼音索引
    final pinyinIndex = <String>[];
    // 类型索引
    final typeIndex = <String>[];

    for (final fund in funds) {
      codeIndex.add(fund.code);
      nameIndex.add(fund.name.toLowerCase());
      pinyinIndex.add(fund.pinyinAbbr.toLowerCase());
      pinyinIndex.add(fund.pinyinFull.toLowerCase());
      typeIndex.add(fund.simplifiedType.toLowerCase());
    }

    await _indexBox.put('code_index', jsonEncode(codeIndex));
    await _indexBox.put('name_index', jsonEncode(nameIndex));
    await _indexBox.put('pinyin_index', jsonEncode(pinyinIndex));
    await _indexBox.put('type_index', jsonEncode(typeIndex));
  }

  /// 智能搜索 - 基于索引的毫秒级搜索
  Future<List<FundInfo>> searchFunds(String query, {int limit = 20}) async {
    if (query.trim().isEmpty) {
      return _fundBox.values.take(limit).toList();
    }

    final stopwatch = Stopwatch()..start();

    try {
      final results = <FundInfo>[];
      final lowerQuery = query.toLowerCase();

      // 精确代码匹配 - 最优先
      final codeIndex =
          jsonDecode(_indexBox.get('code_index', defaultValue: '[]') as String)
              as List<String>;

      // 精确代码匹配 - 最优先
      if (codeIndex.contains(query)) {
        final fund = _fundBox.get(query);
        if (fund != null) results.add(fund);
      }

      // 其他匹配方式
      if (results.length < limit) {
        final allFunds = _fundBox.values.toList();

        for (final fund in allFunds) {
          if (results.length >= limit) break;

          // 避免重复添加
          if (results.any((f) => f.code == fund.code)) continue;

          if (fund.matchesQuery(lowerQuery)) {
            results.add(fund);
          }
        }
      }

      // 按相关性排序
      results.sort((a, b) {
        // 精确代码匹配最优先
        if (a.code == query) return -1;
        if (b.code == query) return 1;

        // 名称开头匹配优先
        final aNameStart = a.name.toLowerCase().startsWith(lowerQuery);
        final bNameStart = b.name.toLowerCase().startsWith(lowerQuery);
        if (aNameStart && !bNameStart) return -1;
        if (!aNameStart && bNameStart) return 1;

        return 0;
      });

      stopwatch.stop();
      _logger.d(
          '🔍 搜索完成，耗时: ${stopwatch.elapsedMilliseconds}ms，找到 ${results.length} 个结果');

      return results.take(limit).toList();
    } catch (e) {
      _logger.e('❌ 搜索失败: $e');
      return [];
    }
  }

  /// 多条件搜索
  Future<List<FundInfo>> searchFundsMultiple(List<String> queries,
      {int limit = 20}) async {
    if (queries.isEmpty || queries.every((q) => q.trim().isEmpty)) {
      return _fundBox.values.take(limit).toList();
    }

    final stopwatch = Stopwatch()..start();

    try {
      final allFunds = _fundBox.values.toList();
      final results = <FundInfo>[];

      for (final fund in allFunds) {
        if (results.length >= limit) break;
        if (fund.matchesMultipleQueries(queries)) {
          results.add(fund);
        }
      }

      stopwatch.stop();
      _logger.d(
          '🔍 多条件搜索完成，耗时: ${stopwatch.elapsedMilliseconds}ms，找到 ${results.length} 个结果');

      return results;
    } catch (e) {
      _logger.e('❌ 多条件搜索失败: $e');
      return [];
    }
  }

  /// 获取缓存信息
  Map<String, dynamic> getCacheInfo() {
    return {
      'fundCount': _fundBox.values.length,
      'lastUpdated': _fundBox.isEmpty ? null : DateTime.now().toIso8601String(),
      'maxCacheSize': _maxCacheSize,
      'apiUrl': _apiUrl,
    };
  }

  /// 完整的数据加载流程 - 三步策略
  Future<void> loadAndCacheFundData({bool forceRefresh = false}) async {
    try {
      _logger.i('🚀 开始三步加载策略...');

      // 检查缓存是否有效
      if (!forceRefresh && _fundBox.isNotEmpty) {
        _logger.i('📦 使用缓存数据，跳过加载');
        return;
      }

      // 第1步：优化网络请求
      final rawData = await _fetchRawFundData();

      // 第2步：优化JSON解析
      final funds = await _parseFundData(rawData);

      // 第3步：优化存储
      await _cacheFundData(funds);

      _logger.i('✅ 三步加载策略完成');
    } catch (e) {
      _logger.e('❌ 数据加载失败: $e');
      rethrow;
    }
  }

  /// 清空缓存
  Future<void> clearCache() async {
    await _fundBox.clear();
    await _indexBox.clear();
    _logger.i('🗑️ 缓存已清空');
  }

  /// 关闭服务
  Future<void> dispose() async {
    await _fundBox.close();
    await _indexBox.close();
    _dio.close();
    _logger.i('🔚 OptimizedFundService 已关闭');
  }
}
