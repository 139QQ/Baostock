import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

/// 基金信息数据类
class FundInfo {
  final String code;
  final String name;
  final String type;
  final String pinyin;
  final String fullName;

  FundInfo({
    required this.code,
    required this.name,
    required this.type,
    required this.pinyin,
    required this.fullName,
  });

  /// 从JSON创建FundInfo对象
  factory FundInfo.fromJson(Map<String, dynamic> json) {
    return FundInfo(
      code: json['基金代码']?.toString() ?? '',
      name: json['基金简称']?.toString() ?? '',
      type: json['基金类型']?.toString() ?? '',
      pinyin: json['拼音缩写']?.toString() ?? '',
      fullName: json['拼音全称']?.toString() ?? '',
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      '基金代码': code,
      '基金简称': name,
      '基金类型': type,
      '拼音缩写': pinyin,
      '拼音全称': fullName,
    };
  }

  /// 获取简化的基金类型
  String get simplifiedType {
    if (type.contains('-')) {
      return type.split('-')[0];
    }
    return type;
  }
}

/// Isolate数据传递类
class CacheDataMessage {
  final List<Map<String, dynamic>> funds;
  final int batchSize;
  final int batchIndex;

  CacheDataMessage({
    required this.funds,
    required this.batchSize,
    required this.batchIndex,
  });
}

/// Isolate处理结果
class CacheResultMessage {
  final Map<String, FundInfo> fundInfos;
  final int successCount;
  final int failCount;
  final int batchIndex;

  CacheResultMessage({
    required this.fundInfos,
    required this.successCount,
    required this.failCount,
    required this.batchIndex,
  });
}

/// 基金数据缓存服务
///
/// 提供基金基本信息的缓存和搜索功能，包括：
/// - 基金名称和类型缓存
/// - 智能搜索匹配
/// - 数据自动更新机制
/// - 多线程并行处理
class FundDataCacheService {
  static FundDataCacheService? _instance;
  static FundDataCacheService get instance {
    _instance ??= FundDataCacheService._();
    return _instance!;
  }

  FundDataCacheService._();

  /// API地址
  static const String _baseUrl = 'http://154.44.25.92:8080';
  static const String _fundListEndpoint = '/api/public/fund_name_em';

  /// 缓存文件名
  static const String _cacheFileName = 'fund_data_cache.json';

  /// 缓存数据结构
  Map<String, FundInfo> _fundCache = {};
  DateTime? _lastUpdateTime;
  Duration _cacheExpiry = const Duration(hours: 24); // 24小时过期

  /// 是否正在加载数据
  bool _isLoading = false;

  /// 搜索索引 - 用于快速搜索
  Map<String, List<String>> _searchIndex = {
    'code': [], // 基金代码索引
    'name': [], // 基金名称索引
    'pinyin': [], // 拼音索引
  };

  /// 初始化缓存服务
  Future<void> initialize() async {
    await _loadCache();
    if (_isCacheExpired()) {
      await _refreshCache();
    }
  }

  /// 搜索基金（支持代码、名称、拼音搜索）- 使用索引优化
  List<FundInfo> searchFunds(String query, {int limit = 20}) {
    if (query.isEmpty) return [];

    final queryLower = query.toLowerCase();
    final results = <FundInfo>[];
    final matchedCodes = <String>{};

    // 精确匹配基金代码
    final exactMatch = _fundCache[query];
    if (exactMatch != null) {
      results.add(exactMatch);
      matchedCodes.add(exactMatch.code);
    }

    // 使用索引快速搜索
    // 代码搜索
    if (results.length < limit) {
      for (final code in _searchIndex['code']!) {
        if (results.length >= limit) break;
        if (matchedCodes.contains(code)) continue;

        if (code.contains(query)) {
          final fund = _fundCache[code];
          if (fund != null) {
            results.add(fund);
            matchedCodes.add(code);
          }
        }
      }
    }

    // 名称搜索
    if (results.length < limit) {
      for (int i = 0;
          i < _searchIndex['name']!.length && results.length < limit;
          i++) {
        final name = _searchIndex['name']![i];
        final code = _searchIndex['code']![i];

        if (matchedCodes.contains(code)) continue;
        if (name.toLowerCase().contains(queryLower)) {
          final fund = _fundCache[code];
          if (fund != null) {
            results.add(fund);
            matchedCodes.add(code);
          }
        }
      }
    }

    // 拼音搜索
    if (results.length < limit) {
      for (int i = 0;
          i < _searchIndex['pinyin']!.length && results.length < limit;
          i++) {
        final pinyin = _searchIndex['pinyin']![i];
        final code = _searchIndex['code']![i];

        if (matchedCodes.contains(code)) continue;
        if (pinyin.toLowerCase().contains(queryLower)) {
          final fund = _fundCache[code];
          if (fund != null) {
            results.add(fund);
            matchedCodes.add(code);
          }
        }
      }
    }

    return results;
  }

  /// 根据基金代码获取基金信息
  FundInfo? getFundByCode(String code) {
    return _fundCache[code];
  }

  /// 根据基金代码获取基金类型
  String getFundType(String code) {
    final fund = _fundCache[code];
    if (fund != null) {
      print('✅ 从缓存获取基金 $code 类型: ${fund.simplifiedType}');
      return fund.simplifiedType;
    }
    return '未知类型';
  }

  /// 获取缓存状态信息
  Map<String, dynamic> getCacheStatus() {
    return {
      'fundCount': _fundCache.length,
      'lastUpdateTime': _lastUpdateTime?.toIso8601String(),
      'isExpired': _isCacheExpired(),
      'isLoading': _isLoading,
    };
  }

  /// 强制刷新缓存
  Future<void> refreshCache() async {
    await _refreshCache();
  }

  /// 从文件加载缓存
  Future<void> _loadCache() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_cacheFileName');

      if (await file.exists()) {
        final content = await file.readAsString();
        final data = json.decode(content) as Map<String, dynamic>;

        _fundCache.clear();
        for (final entry in data['funds'].entries) {
          _fundCache[entry.key] = FundInfo.fromJson(entry.value);
        }

        // 加载搜索索引（如果存在）
        if (data.containsKey('searchIndex')) {
          _searchIndex = Map<String, List<String>>.from(data['searchIndex']);
          print('✅ 成功加载缓存和索引，共 ${_fundCache.length} 只基金');
        } else {
          // 兼容旧版本，构建索引
          _buildSearchIndex();
          print('✅ 成功加载缓存，共 ${_fundCache.length} 只基金（构建索引）');
        }

        _lastUpdateTime = DateTime.parse(data['lastUpdateTime']);
      }
    } catch (e) {
      print('❌ 加载缓存失败: $e');
    }
  }

  /// 构建搜索索引
  void _buildSearchIndex() {
    _searchIndex = {
      'code': [],
      'name': [],
      'pinyin': [],
    };

    for (final fund in _fundCache.values) {
      _searchIndex['code']!.add(fund.code);
      _searchIndex['name']!.add(fund.name.toLowerCase());
      _searchIndex['pinyin']!.add(fund.pinyin.toLowerCase());
    }

    print('🔍 搜索索引构建完成');
  }

  /// 保存缓存和索引到文件
  Future<void> _saveCacheWithIndex() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_cacheFileName');

      final data = {
        'funds': _fundCache.map((key, value) => MapEntry(key, value.toJson())),
        'searchIndex': _searchIndex,
        'lastUpdateTime': DateTime.now().toIso8601String(),
        'version': '2.0', // 版本号，支持索引
      };

      await file.writeAsString(json.encode(data));
      print('✅ 缓存和索引保存成功');
    } catch (e) {
      print('❌ 保存缓存和索引失败: $e');
    }
  }

  /// 从API刷新缓存 - 使用多线程处理
  Future<void> _refreshCache() async {
    if (_isLoading) return;

    _isLoading = true;

    try {
      print('🔄 开始从API获取基金数据...');
      print('📡 API地址: $_baseUrl$_fundListEndpoint');

      final response = await http.get(
        Uri.parse('$_baseUrl$_fundListEndpoint'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      print('📡 API响应状态: ${response.statusCode}');
      print('📡 API响应长度: ${response.body.length} 字符');

      if (response.statusCode == 200) {
        final List<dynamic> funds = json.decode(response.body);
        print('📊 解析到的基金数量: ${funds.length}');

        // 使用compute进行后台处理
        final result = await compute(_processFundsInBackground, {
          'funds': funds.cast<Map<String, dynamic>>(),
          'targetFund': '011120', // 要查找的特定基金
        });

        _fundCache = result['fundCache'];
        _searchIndex = result['searchIndex'];
        _lastUpdateTime = DateTime.now();

        // 保存到文件
        await _saveCacheWithIndex();

        print('✅ 缓存刷新完成，共获取 ${_fundCache.length} 只基金数据');
        print('🔍 索引构建完成，代码索引: ${_searchIndex['code']!.length} 条');

        if (result['foundTarget']) {
          print('🎯 找到基金011120: ${result['targetFundInfo']}');
        } else {
          print('❌ 未找到基金011120');
        }

        // 打印一些示例数据
        final sampleCodes = _fundCache.keys.take(5).toList();
        print('📋 前5只基金代码: ${sampleCodes.join(', ')}');
        for (final code in sampleCodes) {
          final fund = _fundCache[code]!;
          print('  - $code: ${fund.name} (${fund.simplifiedType})');
        }
      } else {
        print('❌ API请求失败，状态码: ${response.statusCode}');
        print('❌ 响应内容: ${response.body}');
      }
    } catch (e) {
      print('❌ 刷新缓存失败: $e');
    } finally {
      _isLoading = false;
    }
  }

  /// 后台处理基金数据
  static Map<String, dynamic> _processFundsInBackground(
      Map<String, dynamic> params) {
    final List<Map<String, dynamic>> funds = params['funds'];
    final String targetFund = params['targetFund'];

    final fundCache = <String, FundInfo>{};
    final searchIndex = <String, List<String>>{
      'code': [],
      'name': [],
      'pinyin': [],
    };

    int successCount = 0;
    int failCount = 0;
    bool foundTarget = false;
    String? targetFundInfo;

    print('🔄 后台处理开始，共 ${funds.length} 只基金');

    // 批量处理
    const batchSize = 500;
    final totalBatches = (funds.length / batchSize).ceil();

    for (int batch = 0; batch < totalBatches; batch++) {
      final startIndex = batch * batchSize;
      final endIndex = (startIndex + batchSize).clamp(0, funds.length);
      final batchFunds = funds.sublist(startIndex, endIndex);

      for (final fund in batchFunds) {
        try {
          final fundInfo = FundInfo.fromJson(fund);
          fundCache[fundInfo.code] = fundInfo;

          // 构建搜索索引
          searchIndex['code']!.add(fundInfo.code);
          searchIndex['name']!.add(fundInfo.name.toLowerCase());
          searchIndex['pinyin']!.add(fundInfo.pinyin.toLowerCase());

          successCount++;

          // 检查是否找到目标基金
          if (fundInfo.code == targetFund) {
            foundTarget = true;
            targetFundInfo = '${fundInfo.name} - ${fundInfo.simplifiedType}';
          }

          if (successCount <= 5) {
            print('🔍 基金 $successCount: ${fundInfo.code} - ${fundInfo.name}');
          }
        } catch (e) {
          failCount++;
          if (failCount <= 5) {
            print('⚠️ 解析基金数据失败: $e');
          }
        }
      }

      // 每处理1000只基金输出一次进度
      if ((batch + 1) % 10 == 0) {
        print('📊 处理进度: ${batch + 1}/$totalBatches 批 ($successCount 只成功)');
      }
    }

    print('📊 后台处理完成: 成功 $successCount 只, 失败 $failCount 只');

    return {
      'fundCache': fundCache,
      'searchIndex': searchIndex,
      'foundTarget': foundTarget,
      'targetFundInfo': targetFundInfo,
    };
  }

  /// 检查缓存是否过期
  bool _isCacheExpired() {
    if (_lastUpdateTime == null) return true;
    return DateTime.now().difference(_lastUpdateTime!) > _cacheExpiry;
  }

  /// 清理缓存
  Future<void> clearCache() async {
    try {
      _fundCache.clear();
      _lastUpdateTime = null;

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_cacheFileName');

      if (await file.exists()) {
        await file.delete();
        print('✅ 缓存清理完成');
      }
    } catch (e) {
      print('❌ 清理缓存失败: $e');
    }
  }
}
