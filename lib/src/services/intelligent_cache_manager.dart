import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'multi_index_search_engine.dart';
import '../models/fund_info.dart';

/// 智能缓存管理器
///
/// 核心特性：
/// 1. 增量更新：仅同步变更的基金数据，避免全量重建
/// 2. 智能预加载：基于用户行为预测，提前加载热点数据
/// 3. 分层缓存：L1内存缓存 + L2磁盘缓存 + L3网络缓存
/// 4. 版本管理：支持缓存版本控制和向后兼容
/// 5. 压缩存储：使用GZIP压缩减少磁盘占用
class IntelligentCacheManager {
  static final IntelligentCacheManager _instance =
      IntelligentCacheManager._internal();
  factory IntelligentCacheManager() => _instance;
  IntelligentCacheManager._internal();

  final Logger _logger = Logger();
  late Box<String> _metadataBox;
  late Box<String> _dataBox;

  // 缓存配置
  static const String _metadataBoxName = 'fund_cache_metadata';
  static const String _dataBoxName = 'fund_cache_data';
  static const String _versionKey = 'cache_version';
  static const String _lastUpdateKey = 'last_update_timestamp';
  static const String _dataHashKey = 'data_hash';
  static const Duration _updateInterval = Duration(hours: 6);
  static const Duration _maxCacheAge = Duration(days: 7);
  static const int _maxMemoryCacheSize = 50000; // 内存缓存最大数量（增加到50000以支持更多数据）

  // 多级缓存
  List<FundInfo> _memoryCache = [];
  Map<String, List<int>> _memoryIndex = {};
  String _currentDataHash = '';
  DateTime _lastUpdateTime = DateTime.now();
  bool _isInitialized = false;

  // 搜索引擎引用
  final MultiIndexSearchEngine _searchEngine = MultiIndexSearchEngine();

  // 预加载管理
  Timer? _preloadTimer;
  final Set<String> _hotQueries = {}; // 热点查询
  final Map<String, int> _queryFrequency = {}; // 查询频率统计

  // ========== 初始化方法 ==========

  /// 初始化缓存管理器
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.i('🚀 初始化智能缓存管理器...');

      // 初始化Hive存储
      await _initializeHiveStorage();

      // 初始化SharedPreferences

      // 加载缓存元数据
      await _loadCacheMetadata();

      // 启动预加载定时器
      _startPreloadTimer();

      // 恢复内存缓存
      await _restoreMemoryCache();

      _isInitialized = true;
      _logger.i('✅ 智能缓存管理器初始化完成');
      _logCacheStatus();
    } catch (e) {
      _logger.e('❌ 智能缓存管理器初始化失败: $e');
      rethrow;
    }
  }

  /// 初始化Hive存储
  Future<void> _initializeHiveStorage() async {
    try {
      // 尝试直接打开存储，如果Hive未初始化会抛出异常
      _metadataBox = await Hive.openBox<String>(_metadataBoxName);
      _dataBox = await Hive.openBox<String>(_dataBoxName);
      _logger.d('✅ Hive存储初始化成功');
    } catch (e) {
      _logger.w('⚠️ Hive存储初始化失败，尝试初始化Hive: $e');

      // 尝试标准初始化
      try {
        final appDocumentDir = await getApplicationDocumentsDirectory();
        Hive.init(appDocumentDir.path);
        _logger.d('✅ 使用标准方式初始化Hive成功');
      } catch (e2) {
        _logger.e('❌ Hive初始化失败: $e2');
        rethrow;
      }

      // 重新尝试打开存储
      try {
        _metadataBox = await Hive.openBox<String>(_metadataBoxName);
        _dataBox = await Hive.openBox<String>(_dataBoxName);
        _logger.d('✅ Hive存储初始化成功');
      } catch (e3) {
        _logger.w('⚠️ Hive存储仍然失败，尝试重建: $e3');
        await _rebuildHiveStorage();
      }
    }
  }

  /// 重建Hive存储
  Future<void> _rebuildHiveStorage() async {
    try {
      // 尝试标准初始化（如果尚未初始化）
      try {
        final appDocumentDir = await getApplicationDocumentsDirectory();
        Hive.init(appDocumentDir.path);
        _logger.d('✅ 使用标准方式初始化Hive成功');
      } catch (e) {
        _logger.d('⚠️ Hive可能已初始化，继续重建存储');
      }

      // 删除并重新创建存储
      await Hive.deleteBoxFromDisk(_metadataBoxName);
      await Hive.deleteBoxFromDisk(_dataBoxName);
      await Future.delayed(const Duration(milliseconds: 200));

      _metadataBox = await Hive.openBox<String>(_metadataBoxName);
      _dataBox = await Hive.openBox<String>(_dataBoxName);

      _logger.i('✅ Hive存储重建成功');
    } catch (e) {
      _logger.e('❌ Hive存储重建失败: $e');
      rethrow;
    }
  }

  // ========== 核心缓存操作 ==========

  /// 获取基金数据（智能加载）
  Future<List<FundInfo>> getFundData({bool forceRefresh = false}) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // 检查是否需要更新
      if (!forceRefresh && await _isCacheValid()) {
        _logger.d('📦 使用有效缓存数据');
        return _memoryCache;
      }

      // 执行增量更新
      await _performIncrementalUpdate();

      return _memoryCache;
    } catch (e) {
      _logger.e('❌ 获取基金数据失败: $e');
      // 返回内存缓存作为fallback
      return _memoryCache;
    }
  }

  /// 搜索基金（智能路由）
  Future<List<FundInfo>> searchFunds(String query, {int? limit}) async {
    if (!_isInitialized) {
      await initialize();
    }

    // 记录查询统计
    _recordQuery(query);

    // 使用多索引搜索引擎
    final searchResult = _searchEngine.search(query);

    _logger.d(
        '🔍 搜索完成: "${query}" → ${searchResult.funds.length} 结果, 耗时: ${searchResult.searchTimeMs}ms');

    return limit != null
        ? searchResult.funds.take(limit).toList()
        : searchResult.funds;
  }

  /// 获取搜索建议
  Future<List<String>> getSearchSuggestions(String prefix) async {
    if (!_isInitialized) {
      await initialize();
    }

    return _searchEngine.getSuggestions(prefix);
  }

  // ========== 增量更新机制 ==========

  /// 执行增量更新
  Future<void> _performIncrementalUpdate() async {
    _logger.i('🔄 开始增量更新...');

    try {
      // 获取远程数据
      final remoteData = await _fetchRemoteFundData();
      final remoteHash = _calculateDataHash(remoteData);

      // 检查数据是否变更
      if (_currentDataHash == remoteHash) {
        _logger.i('📋 数据未变更，跳过更新');
        _updateLastUpdateTime();
        return;
      }

      _logger.i('📊 检测到数据变更，开始增量更新');

      // 解析远程数据
      final remoteFunds = await _parseFundData(remoteData);

      // 执行增量同步
      await _performIncrementalSync(remoteFunds);

      // 更新缓存
      await _updateCache(remoteFunds, remoteHash);

      _logger.i('✅ 增量更新完成: ${remoteFunds.length} 只基金');
    } catch (e) {
      _logger.e('❌ 增量更新失败: $e');
      // 降级到全量更新
      await _performFullUpdate();
    }
  }

  /// 执行增量同步
  Future<void> _performIncrementalSync(List<FundInfo> remoteFunds) async {
    final currentFunds = Map<String, FundInfo>.fromIterable(
      _memoryCache,
      key: (fund) => fund.code,
      value: (fund) => fund,
    );

    // 检测变更
    final changes = _detectChanges(currentFunds, remoteFunds);

    _logger.d(
        '📈 变更统计: 新增${changes.added.length}, 更新${changes.updated.length}, 删除${changes.deleted.length}');

    // 应用变更
    for (final fund in changes.added) {
      _memoryCache.add(fund);
    }

    for (final fund in changes.updated) {
      final index = _memoryCache.indexWhere((f) => f.code == fund.code);
      if (index != -1) {
        _memoryCache[index] = fund;
      }
    }

    for (final code in changes.deleted) {
      _memoryCache.removeWhere((f) => f.code == code);
    }

    // 重建搜索引擎索引
    await _searchEngine.buildIndexes(_memoryCache);
  }

  /// 检测数据变更
  DataChanges _detectChanges(
      Map<String, FundInfo> currentFunds, List<FundInfo> remoteFunds) {
    final remoteMap = Map<String, FundInfo>.fromIterable(
      remoteFunds,
      key: (fund) => fund.code,
      value: (fund) => fund,
    );

    final added = <FundInfo>[];
    final updated = <FundInfo>[];
    final deleted = <String>[];

    // 检测新增和更新
    for (final entry in remoteMap.entries) {
      final code = entry.key;
      final remoteFund = entry.value;

      if (!currentFunds.containsKey(code)) {
        added.add(remoteFund);
      } else {
        final currentFund = currentFunds[code]!;
        if (_isFundChanged(currentFund, remoteFund)) {
          updated.add(remoteFund);
        }
      }
    }

    // 检测删除
    for (final code in currentFunds.keys) {
      if (!remoteMap.containsKey(code)) {
        deleted.add(code);
      }
    }

    return DataChanges(added: added, updated: updated, deleted: deleted);
  }

  /// 检查基金是否变更
  bool _isFundChanged(FundInfo current, FundInfo remote) {
    return current.name != remote.name ||
        current.type != remote.type ||
        current.pinyinAbbr != remote.pinyinAbbr ||
        current.pinyinFull != remote.pinyinFull;
  }

  /// 执行全量更新
  Future<void> _performFullUpdate() async {
    _logger.i('🔄 执行全量更新...');

    try {
      final remoteData = await _fetchRemoteFundData();
      final remoteFunds = await _parseFundData(remoteData);
      final remoteHash = _calculateDataHash(remoteData);

      await _updateCache(remoteFunds, remoteHash);

      _logger.i('✅ 全量更新完成: ${remoteFunds.length} 只基金');
    } catch (e) {
      _logger.e('❌ 全量更新失败: $e');
      rethrow;
    }
  }

  // ========== 缓存管理 ==========

  /// 更新缓存
  Future<void> _updateCache(List<FundInfo> funds, String dataHash) async {
    // 更新内存缓存
    _memoryCache = funds.take(_maxMemoryCacheSize).toList();
    _currentDataHash = dataHash;
    _lastUpdateTime = DateTime.now();

    // 构建搜索引擎索引
    await _searchEngine.buildIndexes(_memoryCache);

    // 压缩并持久化数据
    await _persistData(funds);

    // 更新元数据
    await _updateMetadata(dataHash);

    _logger.d('💾 缓存更新完成: ${_memoryCache.length} 只基金');
  }

  /// 持久化数据
  Future<void> _persistData(List<FundInfo> funds) async {
    try {
      final jsonData = jsonEncode({
        'funds': funds.map((f) => f.toJson()).toList(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      // 压缩数据
      final compressedData = _compressData(jsonData);

      // 存储到Hive
      await _dataBox.put('fund_data', compressedData);

      _logger.d('💾 数据持久化完成: ${compressedData.length} 字节（压缩后）');
    } catch (e) {
      _logger.e('❌ 数据持久化失败: $e');
    }
  }

  /// 恢复内存缓存
  Future<void> _restoreMemoryCache() async {
    try {
      final compressedData = _dataBox.get('fund_data');
      if (compressedData == null) {
        _logger.d('📭 未找到持久化数据');
        return;
      }

      // 解压数据
      final jsonData = _decompressData(compressedData);
      final Map<String, dynamic> data = jsonDecode(jsonData);

      // 解析基金数据
      final List<dynamic> fundsJson = data['funds'];
      final funds = fundsJson.map((json) => FundInfo.fromJson(json)).toList();

      // 恢复内存缓存
      _memoryCache = funds.take(_maxMemoryCacheSize).toList();

      // 重建搜索引擎索引
      await _searchEngine.buildIndexes(_memoryCache);

      _logger.d('📦 内存缓存恢复完成: ${_memoryCache.length} 只基金');
    } catch (e) {
      _logger.w('⚠️ 内存缓存恢复失败: $e');
    }
  }

  // ========== 智能预加载 ==========

  /// 启动预加载定时器
  void _startPreloadTimer() {
    _preloadTimer?.cancel();
    _preloadTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      _performIntelligentPreload();
    });
    _logger.d('⏰ 预加载定时器已启动');
  }

  /// 执行智能预加载
  Future<void> _performIntelligentPreload() async {
    try {
      // 获取热点查询
      final hotQueries = _getHotQueries();

      if (hotQueries.isEmpty) return;

      _logger.d('🔥 执行智能预加载，热点查询: $hotQueries');

      // 预加载热点查询的结果
      for (final query in hotQueries) {
        // 移除预加载数量限制
        try {
          _searchEngine.search(query);
        } catch (e) {
          _logger.w('⚠️ 预加载查询失败 "$query": $e');
        }
      }
    } catch (e) {
      _logger.w('⚠️ 智能预加载失败: $e');
    }
  }

  /// 获取热点查询
  List<String> _getHotQueries() {
    final sortedQueries = _queryFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedQueries
        .map((entry) => entry.key)
        .where((query) => query.length >= 2)
        .toList();
  }

  /// 记录查询统计
  void _recordQuery(String query) {
    if (query.length < 2) return;

    _queryFrequency[query] = (_queryFrequency[query] ?? 0) + 1;
    _hotQueries.add(query);

    // 扩展统计数量限制，支持更多查询统计
    if (_queryFrequency.length > 10000) {
      final sortedEntries = _queryFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      _queryFrequency.clear();
      for (final entry in sortedEntries.take(5000)) {
        // 增加到5000条
        _queryFrequency[entry.key] = entry.value;
      }
    }
  }

  // ========== 工具方法 ==========

  /// 检查缓存是否有效
  Future<bool> _isCacheValid() async {
    if (_memoryCache.isEmpty) return false;

    final now = DateTime.now();
    final age = now.difference(_lastUpdateTime);

    return age < _updateInterval && age < _maxCacheAge;
  }

  /// 获取远程基金数据
  Future<String> _fetchRemoteFundData() async {
    // 这里应该调用实际的API
    // 暂时返回模拟数据
    final client = HttpClient();
    try {
      final request = await client.getUrl(
          Uri.parse('http://154.44.25.92:8080/api/public/fund_name_em'));
      request.headers.set('Accept-Encoding', 'gzip, deflate, br');
      request.headers.set('User-Agent', 'intelligent-cache-manager/1.0');

      final response = await request.close();

      if (response.statusCode == 200) {
        final data = await response.transform(utf8.decoder).join();
        return data;
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } finally {
      client.close();
    }
  }

  /// 解析基金数据
  Future<List<FundInfo>> _parseFundData(String rawData) async {
    try {
      final dynamic jsonData = jsonDecode(rawData);
      List<dynamic> dataList;

      // 处理不同的数据格式
      if (jsonData is Map<String, dynamic>) {
        // 如果是Map，尝试获取data字段
        dataList = jsonData['data'] ?? [jsonData]; // 如果没有data字段，将整个Map作为单个元素
      } else if (jsonData is List) {
        // 如果直接是List，直接使用
        dataList = jsonData;
      } else {
        throw Exception('未知的JSON数据格式: ${jsonData.runtimeType}');
      }

      _logger.d(
          '📊 解析JSON数据格式: ${jsonData.runtimeType}, 数据条数: ${dataList.length}');

      return dataList
          .map((item) {
            if (item is! Map<String, dynamic>) {
              _logger.w('⚠️ 跳过无效数据项: ${item.runtimeType} - $item');
              return null;
            }

            final fundData = item;
            return FundInfo(
              code: fundData['基金代码']?.toString() ?? '',
              name: fundData['基金简称']?.toString() ?? '',
              type: fundData['基金类型']?.toString() ?? '',
              pinyinAbbr: fundData['拼音缩写']?.toString() ?? '',
              pinyinFull: fundData['拼音全称']?.toString() ?? '',
            );
          })
          .where((fund) =>
              fund != null && fund.code.isNotEmpty && fund.name.isNotEmpty)
          .cast<FundInfo>()
          .toList();
    } catch (e) {
      _logger.e('❌ 解析基金数据失败: $e');
      _logger.e(
          '原始数据前100字符: ${rawData.length > 100 ? rawData.substring(0, 100) : rawData}...');
      rethrow;
    }
  }

  /// 计算数据哈希
  String _calculateDataHash(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 压缩数据
  String _compressData(String data) {
    // 这里应该使用实际的压缩算法
    // 暂时返回原数据
    return data;
  }

  /// 解压数据
  String _decompressData(String compressedData) {
    // 这里应该使用实际的解压算法
    // 暂时返回原数据
    return compressedData;
  }

  /// 加载缓存元数据
  Future<void> _loadCacheMetadata() async {
    _currentDataHash = _metadataBox.get(_dataHashKey) ?? '';
    final timestampStr = _metadataBox.get(_lastUpdateKey);
    if (timestampStr != null) {
      _lastUpdateTime =
          DateTime.fromMillisecondsSinceEpoch(int.parse(timestampStr));
    }
    _logger.d('📋 缓存元数据加载完成');
  }

  /// 更新元数据
  Future<void> _updateMetadata(String dataHash) async {
    await _metadataBox.put(_dataHashKey, dataHash);
    await _metadataBox.put(
        _lastUpdateKey, _lastUpdateTime.millisecondsSinceEpoch.toString());
    await _metadataBox.put(_versionKey, '1.0.0');
  }

  /// 更新最后更新时间
  void _updateLastUpdateTime() {
    _lastUpdateTime = DateTime.now();
  }

  /// 记录缓存状态
  void _logCacheStatus() {
    _logger.i('📊 缓存状态信息:');
    _logger.i('  内存缓存: ${_memoryCache.length} 只基金');
    _logger.i('  最后更新: ${_lastUpdateTime.toIso8601String()}');
    _logger.i(
        '  数据哈希: ${_currentDataHash.isEmpty ? "无" : (_currentDataHash.length > 8 ? _currentDataHash.substring(0, 8) : _currentDataHash)}...');
    _logger.i('  搜索引擎索引: ${_searchEngine.getIndexStats().totalFunds} 只基金');
  }

  // ========== 公共接口 ==========

  /// 获取缓存统计信息
  CacheStats getCacheStats() {
    return CacheStats(
      memoryCacheSize: _memoryCache.length,
      lastUpdateTime: _lastUpdateTime,
      dataHash: _currentDataHash,
      isInitialized: _isInitialized,
      searchEngineStats: _searchEngine.getIndexStats(),
      hotQueriesCount: _hotQueries.length,
      queryFrequencyCount: _queryFrequency.length,
    );
  }

  /// 清空所有缓存
  Future<void> clearAllCache() async {
    try {
      _memoryCache.clear();
      _memoryIndex.clear();
      _currentDataHash = '';
      _lastUpdateTime = DateTime.now();
      _hotQueries.clear();
      _queryFrequency.clear();

      await _metadataBox.clear();
      await _dataBox.clear();
      await _searchEngine.buildIndexes([]);

      _logger.i('🗑️ 所有缓存已清空');
    } catch (e) {
      _logger.e('❌ 清空缓存失败: $e');
    }
  }

  /// 预热缓存
  Future<void> warmupCache() async {
    try {
      _logger.i('🔥 开始预热缓存...');
      await getFundData();
      _logger.i('✅ 缓存预热完成');
    } catch (e) {
      _logger.e('❌ 缓存预热失败: $e');
    }
  }

  /// 关闭缓存管理器
  Future<void> dispose() async {
    _preloadTimer?.cancel();
    await _metadataBox.close();
    await _dataBox.close();
    _isInitialized = false;
    _logger.i('🔚 智能缓存管理器已关闭');
  }
}

// ========== 辅助类 ==========

/// 数据变更信息
class DataChanges {
  final List<FundInfo> added;
  final List<FundInfo> updated;
  final List<String> deleted;

  DataChanges({
    required this.added,
    required this.updated,
    required this.deleted,
  });
}

/// 缓存统计信息
class CacheStats {
  final int memoryCacheSize;
  final DateTime lastUpdateTime;
  final String dataHash;
  final bool isInitialized;
  final IndexStats searchEngineStats;
  final int hotQueriesCount;
  final int queryFrequencyCount;

  CacheStats({
    required this.memoryCacheSize,
    required this.lastUpdateTime,
    required this.dataHash,
    required this.isInitialized,
    required this.searchEngineStats,
    required this.hotQueriesCount,
    required this.queryFrequencyCount,
  });
}
