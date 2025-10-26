import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import '../models/fund_info.dart';

/// 基金数据快速缓存管理器V3 - 统一三步走策略
///
/// 第1步：高效请求 - Dio + gzip压缩 + 批量拉取
/// 第2步：快速解析 - compute异步解析 + 精简字段
/// 第3步：高效存储 - Hive批量写入 + 同步建索引
///
/// 优化说明：支持依赖注入使用，同时保持向后兼容的单例模式
class OptimizedCacheManagerV3 {
  static OptimizedCacheManagerV3? _instance;

  /// 获取单例实例（向后兼容）
  factory OptimizedCacheManagerV3() {
    _instance ??= OptimizedCacheManagerV3._internal();
    return _instance!;
  }

  /// 创建新实例（用于依赖注入）
  factory OptimizedCacheManagerV3.createNewInstance() =>
      OptimizedCacheManagerV3._internal();

  OptimizedCacheManagerV3._internal() {
    _logger.d('✅ OptimizedCacheManagerV3 实例已创建');
  }

  final Logger _logger = Logger();
  late Dio _dio;
  late Box<String> _fundBox;
  late Box<String> _indexBox;

  // 配置常量
  static const String _fundBoxName = 'funds_v3';
  static const String _indexBoxName = 'funds_index_v3';
  static const String _timestampKey = 'last_update_timestamp';
  static const String _dataVersionKey = 'data_version';
  static const Duration _cacheExpireTime = Duration(hours: 6);

  // 内存索引结构
  final Map<String, String> _codeToNameIndex = {};
  final Map<String, String> _nameToCodeIndex = {};
  final Map<String, List<String>> _prefixIndex = {};

  bool _isInitialized = false;
  bool _isLoading = false;

  // 缓存状态同步回调
  final List<void Function()> _syncCallbacks = [];

  /// 初始化缓存管理器
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.i('🚀 初始化快速缓存管理器V3...');

      // 初始化Dio - 第1步：高效请求
      await _initializeDio();

      // 初始化Hive存储 - 第3步：高效存储
      await _initializeHiveStorage();

      // 恢复内存索引
      await _restoreMemoryIndexes();

      _isInitialized = true;
      _logger.i('✅ 快速缓存管理器V3初始化完成');
    } catch (e) {
      _logger.e('❌ 初始化失败: $e');
      rethrow;
    }
  }

  /// 初始化Dio HTTP客户端 - 第1步核心配置
  Future<void> _initializeDio() async {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 10),
    ));

    // 启用gzip压缩 - 关键优化点1
    _dio.options.headers['Accept-Encoding'] = 'gzip, deflate, br';
    _dio.options.headers['User-Agent'] = 'fund-cache-v3/1.0';

    // 添加拦截器用于日志和性能监控
    _dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: false,
      logPrint: (obj) => _logger.d('DIO: $obj'),
    ));

    _logger.d('✅ Dio客户端初始化完成，支持gzip压缩');
  }

  /// 初始化Hive存储 - 第3步高效存储准备
  Future<void> _initializeHiveStorage() async {
    try {
      // 确保Hive已初始化
      if (!Hive.isAdapterRegistered(0)) {
        final appDocDir = await getApplicationDocumentsDirectory();
        Hive.init(appDocDir.path);
      }

      // 打开存储盒子
      _fundBox = await Hive.openBox<String>(_fundBoxName);
      _indexBox = await Hive.openBox<String>(_indexBoxName);

      _logger.d('✅ Hive存储初始化完成');
    } catch (e) {
      _logger.e('❌ Hive初始化失败: $e');
      rethrow;
    }
  }

  /// 获取基金数据 - 统一三步走入口
  Future<List<FundInfo>> getFundData({bool forceRefresh = false}) async {
    if (!_isInitialized) {
      await initialize();
    }

    // 检查缓存是否有效
    if (!forceRefresh && _isCacheValid()) {
      _logger.d('📦 使用有效缓存数据');
      return _getFundDataFromCache();
    }

    // 执行三步走策略
    return await _executeThreeStepStrategy();
  }

  /// 执行统一三步走策略
  Future<List<FundInfo>> _executeThreeStepStrategy() async {
    if (_isLoading) {
      _logger.d('⏳ 数据正在加载中，等待完成...');
      return await _waitForLoadingComplete();
    }

    _isLoading = true;
    final stopwatch = Stopwatch()..start();

    try {
      _logger.i('🚀 开始执行三步走缓存策略...');

      // 第1步：高效请求 - 一次批量拉取所有数据
      final rawData = await _step1_EfficientRequest();
      _logger.d('✅ 第1步完成：高效请求，耗时${stopwatch.elapsedMilliseconds}ms');

      // 第2步：快速解析 - compute异步解析
      final funds = await _step2_FastParse(rawData);
      _logger.d(
          '✅ 第2步完成：快速解析，基金数量${funds.length}，耗时${stopwatch.elapsedMilliseconds}ms');

      // 第3步：高效存储 - Hive批量写入 + 同步建索引
      await _step3_EfficientStorage(funds);
      _logger.d('✅ 第3步完成：高效存储，总耗时${stopwatch.elapsedMilliseconds}ms');

      _logger.i(
          '🎉 三步走策略完成！共缓存${funds.length}只基金，总耗时${stopwatch.elapsedMilliseconds}ms');
      return funds;
    } catch (e) {
      _logger.e('❌ 三步走策略执行失败: $e');
      // 降级：返回现有缓存数据
      return _getFundDataFromCache();
    } finally {
      _isLoading = false;
      stopwatch.stop();
    }
  }

  /// 第1步：高效请求 - 减少数据传输耗时
  Future<String> _step1_EfficientRequest() async {
    _logger.i('📡 第1步：执行高效请求...');

    try {
      // 使用Dio发起请求，自动处理gzip压缩
      final response = await _dio.get(
        'http://154.44.25.92:8080/api/public/fund_name_em',
        options: Options(
          responseType: ResponseType.plain,
        ),
      );

      if (response.statusCode == 200) {
        _logger.d('✅ 高效请求成功，数据大小：${response.data.length}字符');
        return response.data.toString();
      } else {
        throw Exception(
            'HTTP ${response.statusCode}: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('❌ 高效请求失败: $e');
      rethrow;
    }
  }

  /// 第2步：快速解析 - 异步处理 + 精简数据
  Future<List<FundInfo>> _step2_FastParse(String rawData) async {
    _logger.i('🔧 第2步：执行快速解析...');

    try {
      // 使用compute在独立isolate中解析JSON - 关键优化点2
      final funds = await compute(_parseFundsInIsolate, rawData);

      _logger.d('✅ 快速解析完成，解析${funds.length}只基金');
      return funds;
    } catch (e) {
      _logger.e('❌ 快速解析失败: $e');
      rethrow;
    }
  }

  /// 在isolate中解析基金数据 - 异步解析核心函数
  static List<FundInfo> _parseFundsInIsolate(String rawData) {
    try {
      final jsonData = jsonDecode(rawData);
      List<dynamic> dataList;

      // 处理不同数据格式
      if (jsonData is Map<String, dynamic>) {
        dataList = jsonData['data'] ?? [jsonData];
      } else if (jsonData is List) {
        dataList = jsonData;
      } else {
        throw Exception('未知JSON格式: ${jsonData.runtimeType}');
      }

      return dataList
          .where((item) => item is Map<String, dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .where((fundData) =>
              fundData['基金代码'] != null &&
              fundData['基金简称'] != null &&
              fundData['基金代码'].toString().isNotEmpty &&
              fundData['基金简称'].toString().isNotEmpty)
          .map((fundData) => FundInfo(
                code: fundData['基金代码'].toString(),
                name: fundData['基金简称'].toString(),
                type: fundData['基金类型']?.toString() ?? '',
                pinyinAbbr: fundData['拼音缩写']?.toString() ?? '',
                pinyinFull: fundData['拼音全称']?.toString() ?? '',
              ))
          .toList();
    } catch (e) {
      // 在isolate中无法使用logger，简单返回错误信息
      // 在静态方法中无法使用logger，注释掉日志
      // print('❌ Isolate解析失败: $e');
      return [];
    }
  }

  /// 第3步：高效存储 - 批量写入 + 同步建索引
  Future<void> _step3_EfficientStorage(List<FundInfo> funds) async {
    _logger.i('💾 第3步：执行高效存储...');

    try {
      // 清空现有数据
      await _fundBox.clear();
      await _indexBox.clear();
      _clearMemoryIndexes();

      // 批量写入Hive - 关键优化点3
      final fundMap = <String, String>{};
      for (final fund in funds) {
        fundMap[fund.code] = jsonEncode(fund.toJson());
      }
      await _fundBox.putAll(fundMap);

      // 同步构建内存索引
      _buildMemoryIndexes(funds);

      // 持久化索引元数据
      await _persistIndexMetadata();

      // 通知缓存状态变更
      _notifyCacheChanged();

      _logger.d('✅ 高效存储完成：${funds.length}只基金');
    } catch (e) {
      _logger.e('❌ 高效存储失败: $e');
      rethrow;
    }
  }

  /// 构建内存索引 - 同步建索引核心
  void _buildMemoryIndexes(List<FundInfo> funds) {
    _logger.d('🔨 构建内存索引...');

    for (final fund in funds) {
      // 代码-名称映射
      _codeToNameIndex[fund.code] = fund.name;
      _nameToCodeIndex[fund.name.toLowerCase()] = fund.code;

      // 前缀索引 - 支持快速前缀搜索
      _buildPrefixIndex(fund.name, fund.code);

      // 拼音前缀索引
      if (fund.pinyinAbbr.isNotEmpty) {
        _buildPrefixIndex(fund.pinyinAbbr, fund.code);
      }
    }

    _logger.d('✅ 内存索引构建完成');
  }

  /// 构建前缀索引
  void _buildPrefixIndex(String text, String code) {
    final lowerText = text.toLowerCase();
    for (int i = 1; i <= lowerText.length && i <= 10; i++) {
      // 限制前缀长度
      final prefix = lowerText.substring(0, i);
      _prefixIndex.putIfAbsent(prefix, () => []).add(code);
    }
  }

  /// 持久化索引元数据
  Future<void> _persistIndexMetadata() async {
    await _indexBox.put(
        _timestampKey, DateTime.now().millisecondsSinceEpoch.toString());
    await _indexBox.put(_dataVersionKey, 'v3.0');
    await _indexBox.put(
        'index_stats',
        jsonEncode({
          'total_funds': _codeToNameIndex.length,
          'prefix_entries': _prefixIndex.length,
        }));
  }

  /// 恢复内存索引
  Future<void> _restoreMemoryIndexes() async {
    try {
      final timestampStr = _indexBox.get(_timestampKey);
      if (timestampStr == null) {
        _logger.d('📭 未找到索引数据，跳过恢复');
        return;
      }

      // 从Hive恢复基金数据到内存索引
      final fundKeys = _fundBox.keys;
      for (final code in fundKeys) {
        final fundJson = _fundBox.get(code);
        if (fundJson != null) {
          try {
            final fundData = jsonDecode(fundJson) as Map<String, dynamic>;
            final name = fundData['name'] as String;

            _codeToNameIndex[code] = name;
            _nameToCodeIndex[name.toLowerCase()] = code;
            _buildPrefixIndex(name, code);
          } catch (e) {
            _logger.w('⚠️ 恢复索引失败 $code: $e');
          }
        }
      }

      _logger.d('✅ 内存索引恢复完成：${_codeToNameIndex.length}只基金');
    } catch (e) {
      _logger.w('⚠️ 内存索引恢复失败: $e');
    }
  }

  /// 从缓存获取基金数据
  List<FundInfo> _getFundDataFromCache() {
    final funds = <FundInfo>[];
    final fundKeys = _fundBox.keys.take(1000); // 限制返回数量，避免内存问题

    for (final code in fundKeys) {
      final fundJson = _fundBox.get(code);
      if (fundJson != null) {
        try {
          final fundData = jsonDecode(fundJson) as Map<String, dynamic>;
          funds.add(FundInfo.fromJson(fundData));
        } catch (e) {
          _logger.w('⚠️ 解析缓存数据失败 $code: $e');
        }
      }
    }

    return funds;
  }

  /// 检查缓存是否有效
  bool _isCacheValid() {
    // 如果未初始化，缓存无效
    if (!_isInitialized) return false;

    try {
      final timestampStr = _indexBox.get(_timestampKey);
      if (timestampStr == null) return false;

      final lastUpdate =
          DateTime.fromMillisecondsSinceEpoch(int.parse(timestampStr));
      final now = DateTime.now();
      final age = now.difference(lastUpdate);

      return age < _cacheExpireTime && _codeToNameIndex.isNotEmpty;
    } catch (e) {
      // 如果索引盒子不可用，缓存无效
      _logger.w('⚠️ 检查缓存有效性失败: $e');
      return false;
    }
  }

  /// 等待加载完成
  Future<List<FundInfo>> _waitForLoadingComplete() async {
    while (_isLoading) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    return _getFundDataFromCache();
  }

  /// 通过基金代码获取基金信息（优先从缓存）
  Future<FundInfo?> getFundByCode(String fundCode) async {
    if (!_isInitialized) {
      _logger.w('⚠️ 缓存管理器未初始化，无法获取基金信息');
      return null;
    }

    // 1. 先从内存索引查找
    if (_codeToNameIndex.containsKey(fundCode)) {
      return _getFundFromLocalCache(fundCode);
    }

    // 2. 如果内存中没有，尝试从本地缓存查找
    final fundFromCache = _getFundFromLocalCache(fundCode);
    if (fundFromCache != null) {
      // 更新内存索引
      _codeToNameIndex[fundCode] = fundFromCache.name.toLowerCase();
      _nameToCodeIndex[fundFromCache.name.toLowerCase()] = fundCode;
      return fundFromCache;
    }

    _logger.d('⚠️ 未找到基金代码: $fundCode');
    return null;
  }

  /// 从本地缓存获取基金信息
  FundInfo? _getFundFromLocalCache(String fundCode) {
    try {
      final fundJson = _fundBox.get(fundCode);
      if (fundJson != null) {
        final fundData = jsonDecode(fundJson) as Map<String, dynamic>;
        return FundInfo.fromJson(fundData);
      }
    } catch (e) {
      _logger.w('⚠️ 从本地缓存获取基金信息失败 $fundCode: $e');
    }
    return null;
  }

  /// 清空内存索引
  void _clearMemoryIndexes() {
    _codeToNameIndex.clear();
    _nameToCodeIndex.clear();
    _prefixIndex.clear();
  }

  /// 快速搜索 - 使用内存索引
  List<FundInfo> searchFunds(String query, {int limit = 30}) {
    if (!_isInitialized || query.trim().isEmpty) return [];

    final lowerQuery = query.toLowerCase();
    final results = <FundInfo>[];
    final foundCodes = <String>{};

    // 1. 精确匹配
    if (_nameToCodeIndex.containsKey(lowerQuery)) {
      final code = _nameToCodeIndex[lowerQuery]!;
      foundCodes.add(code);
    }

    // 2. 前缀匹配
    if (foundCodes.length < limit) {
      final prefixMatches = _prefixIndex[lowerQuery] ?? [];
      for (final code in prefixMatches) {
        if (foundCodes.length >= limit) break;
        foundCodes.add(code);
      }
    }

    // 3. 模糊匹配（简单包含）
    if (foundCodes.length < limit) {
      for (final entry in _nameToCodeIndex.entries) {
        if (foundCodes.length >= limit) break;
        if (entry.key.contains(lowerQuery)) {
          foundCodes.add(entry.value);
        }
      }
    }

    // 获取基金详情
    for (final code in foundCodes.take(limit)) {
      final fundJson = _fundBox.get(code);
      if (fundJson != null) {
        try {
          final fundData = jsonDecode(fundJson) as Map<String, dynamic>;
          results.add(FundInfo.fromJson(fundData));
        } catch (e) {
          _logger.w('⚠️ 搜索结果解析失败 $code: $e');
        }
      }
    }

    return results.take(limit).toList();
  }

  /// 获取搜索建议
  List<String> getSearchSuggestions(String prefix, {int maxSuggestions = 10}) {
    if (!_isInitialized || prefix.length < 2) return [];

    final lowerPrefix = prefix.toLowerCase();
    final suggestions = <String>[];

    // 从前缀索引获取建议
    final prefixMatches = _prefixIndex[lowerPrefix] ?? [];
    for (final code in prefixMatches.take(maxSuggestions)) {
      final name = _codeToNameIndex[code];
      if (name != null && !suggestions.contains(name)) {
        suggestions.add(name);
      }
    }

    return suggestions.take(maxSuggestions).toList();
  }

  /// 获取缓存统计信息
  Map<String, dynamic> getCacheStats() {
    return {
      'isInitialized': _isInitialized,
      'isLoading': _isLoading,
      'totalFunds': _codeToNameIndex.length,
      'prefixEntries': _prefixIndex.length,
      'cacheValid': _isCacheValid(),
      'version': 'v3.0',
    };
  }

  /// 清空所有缓存
  Future<void> clearAllCache() async {
    try {
      await _fundBox.clear();
      await _indexBox.clear();
      _clearMemoryIndexes();
      _logger.i('🗑️ 所有缓存已清空');
    } catch (e) {
      _logger.e('❌ 清空缓存失败: $e');
    }
  }

  /// 添加缓存状态同步回调
  void addSyncCallback(void Function() callback) {
    _syncCallbacks.add(callback);
    _logger.d('📞 已添加缓存同步回调');
  }

  /// 移除缓存状态同步回调
  void removeSyncCallback(void Function() callback) {
    _syncCallbacks.remove(callback);
    _logger.d('📞 已移除缓存同步回调');
  }

  /// 通知缓存状态变更
  void _notifyCacheChanged() {
    for (final callback in _syncCallbacks) {
      try {
        callback();
      } catch (e) {
        _logger.w('⚠️ 缓存同步回调执行失败: $e');
      }
    }
  }

  /// 关闭缓存管理器
  Future<void> dispose() async {
    try {
      await _fundBox.close();
      await _indexBox.close();
      _clearMemoryIndexes();
      _syncCallbacks.clear();
      _isInitialized = false;
      _logger.i('🔚 快速缓存管理器V3已关闭');
    } catch (e) {
      _logger.e('❌ 关闭缓存管理器失败: $e');
    }
  }
}
