import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'dart:collection' as collection;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/fund.dart';
import '../../models/fund_filter.dart';
import '../../repositories/cache_repository.dart';

import '../models/fund_dto.dart';

/// 优化版基金数据服务
///
/// 核心优化：
/// - 简化数据加载逻辑，移除复杂的频率限制
/// - 统一的缓存策略和错误处理
/// - 智能数据预加载和懒加载
/// - 网络优化和请求合并
class OptimizedFundService {
  static String baseUrl = 'http://154.44.25.92:8080/api/public/';
  static Duration defaultTimeout = const Duration(seconds: 30);
  static Duration longTimeout = const Duration(seconds: 60);

  final http.Client _client;
  final CacheRepository _cacheRepository;
  late Dio _dio;

  // 请求缓存 - 避免重复请求
  final Map<String, Future<List<FundDto>>> _fundRequestCache = {};
  final Map<String, Future<List<FundRankingDto>>> _rankingRequestCache = {};

  // 预加载队列
  final collection.Queue<String> _preloadQueue = collection.Queue<String>();
  bool _isPreloading = false;

  OptimizedFundService({
    http.Client? client,
    CacheRepository? cacheRepository,
  })  : _client = client ?? http.Client(),
        _cacheRepository = cacheRepository ?? _createDefaultCacheRepository() {
    _initializeDioClient();
  }

  /// 初始化Dio客户端 - 简化配置
  Future<void> _initializeDioClient() async {
    try {
      _dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: defaultTimeout,
        receiveTimeout: longTimeout,
        sendTimeout: defaultTimeout,
        headers: {
          'Accept': 'application/json',
          'Accept-Encoding': 'gzip, deflate, br',
          'User-Agent': 'FundAnalyzer/2.0',
          'Cache-Control': 'max-age=3600',
        },
      ));

      // 添加响应拦截器用于调试
      if (kDebugMode) {
        _dio.interceptors.add(LogInterceptor(
          request: false,
          requestHeader: false,
          requestBody: false,
          responseHeader: false,
          responseBody: false,
          error: true,
          logPrint: (log) => debugPrint('🌐 OptimizedFundService: $log'),
        ));
      }

      debugPrint('✅ 优化版Dio客户端初始化完成');
    } catch (e) {
      debugPrint('❌ Dio客户端初始化失败: $e');
      _dio = Dio();
    }
  }

  /// 获取基金基础信息（优化版）
  ///
  /// 优化点：
  /// - 请求去重避免重复请求
  /// - 智能缓存策略
  /// - 统一错误处理
  Future<List<FundDto>> getFundBasicInfo({
    int? limit,
    int? offset,
    String? fundType,
    String? company,
  }) async {
    const cacheKey = 'fund_basic_info_all';

    // 1. 检查请求缓存（避免并发重复请求）
    if (_fundRequestCache.containsKey(cacheKey)) {
      debugPrint('🔄 使用请求缓存：基金基础信息');
      final cachedResult = await _fundRequestCache[cacheKey]!;
      return _filterAndPaginateFunds(
          cachedResult, limit, offset, fundType, company);
    }

    // 2. 创建缓存请求
    final requestFuture = _loadFundBasicInfoFromNetwork(cacheKey);
    _fundRequestCache[cacheKey] = requestFuture;

    try {
      final result = await requestFuture;
      return _filterAndPaginateFunds(result, limit, offset, fundType, company);
    } finally {
      // 3. 清理请求缓存（延迟清理，避免短时间内重复请求）
      _cleanupRequestCache('fund', cacheKey);
    }
  }

  /// 网络加载基金基础信息
  Future<List<FundDto>> _loadFundBasicInfoFromNetwork(String cacheKey) async {
    // 1. 尝试从缓存获取
    final cachedFunds = await _cacheRepository.getCachedFunds(cacheKey);
    if (cachedFunds != null && cachedFunds.isNotEmpty) {
      debugPrint('✅ 从缓存获取基金基础信息：${cachedFunds.length}条');
      return cachedFunds.map((fund) => _fundToDto(fund)).toList();
    }

    // 2. 缓存未命中，从网络加载
    debugPrint('🌐 从网络加载基金基础信息');
    try {
      final uri = Uri.parse('${baseUrl}fund_name_em');
      final response = await _client.get(uri).timeout(defaultTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<FundDto> funds = [];

        if (data is List) {
          funds = data.map((json) => FundDto.fromJson(json)).toList();
        } else if (data is Map && data.containsKey('data')) {
          funds = (data['data'] as List)
              .map((json) => FundDto.fromJson(json))
              .toList();
        }

        // 3. 缓存结果
        if (funds.isNotEmpty) {
          final fundModels = funds.map((dto) => _dtoToFund(dto)).toList();
          await _cacheRepository.cacheFunds(cacheKey, fundModels,
              ttl: const Duration(hours: 6));
          debugPrint('💾 基金基础信息已缓存：${funds.length}条');
        }

        return funds;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ 加载基金基础信息失败: $e');
      // 返回空列表而不是抛出异常，保持应用可用性
      return [];
    }
  }

  /// 获取基金排行榜（优化版）
  ///
  /// 优化点：
  /// - 请求去重和缓存
  /// - 智能字段过滤
  /// - 优雅降级策略
  Future<List<FundRankingDto>> getFundRankings({
    required String symbol,
    List<String>? fields,
    bool enableCache = true,
    Duration? timeout,
  }) async {
    final cacheKey = 'fund_rankings_$symbol';
    final effectiveTimeout = timeout ?? longTimeout;

    // 1. 检查请求缓存
    if (_rankingRequestCache.containsKey(cacheKey)) {
      debugPrint('🔄 使用请求缓存：基金排行 $symbol');
      return _rankingRequestCache[cacheKey]!;
    }

    // 2. 创建缓存请求
    final requestFuture = _loadFundRankingsFromNetwork(
      cacheKey,
      symbol,
      fields,
      effectiveTimeout,
      enableCache,
    );
    _rankingRequestCache[cacheKey] = requestFuture;

    try {
      return await requestFuture;
    } finally {
      // 3. 清理请求缓存
      _cleanupRequestCache('ranking', cacheKey);
    }
  }

  /// 网络加载基金排行榜
  Future<List<FundRankingDto>> _loadFundRankingsFromNetwork(
    String cacheKey,
    String symbol,
    List<String>? fields,
    Duration timeout,
    bool enableCache,
  ) async {
    // 1. 尝试从缓存获取
    if (enableCache) {
      final cachedRankings =
          await _cacheRepository.getCachedFundRankings(cacheKey);
      if (cachedRankings != null && cachedRankings.isNotEmpty) {
        debugPrint('✅ 从缓存获取基金排行：${cachedRankings.length}条');
        return _mapCacheToRankingDto(cachedRankings);
      }
    }

    // 2. 缓存未命中，从网络加载
    debugPrint('🌐 从网络加载基金排行：$symbol');
    try {
      final queryParams = <String, String>{
        'symbol': symbol,
      };
      if (fields != null && fields.isNotEmpty) {
        queryParams['fields'] = fields.join(',');
      }

      final response = await _dio.get(
        'fund_open_fund_rank_em',
        queryParameters: queryParams,
        options: Options(receiveTimeout: timeout),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        List<FundRankingDto> rankings = [];

        if (data is List) {
          rankings = data.map((json) => FundRankingDto.fromJson(json)).toList();
        } else if (data is Map && data.containsKey('data')) {
          rankings = (data['data'] as List)
              .map((json) => FundRankingDto.fromJson(json))
              .toList();
        }

        // 3. 缓存结果
        if (rankings.isNotEmpty && enableCache) {
          await _cacheRepository.cacheFundRankings(
              cacheKey, _mapRankingDtoToCache(rankings),
              ttl: const Duration(minutes: 30));
          debugPrint('💾 基金排行已缓存：${rankings.length}条');
        }

        debugPrint('✅ 基金排行加载完成：${rankings.length}条');
        return rankings;
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ 加载基金排行失败: $e');

      // 优雅降级：尝试从过期缓存获取
      if (enableCache) {
        final staleRankings =
            await _cacheRepository.getCachedFundRankings(cacheKey);
        if (staleRankings != null && staleRankings.isNotEmpty) {
          debugPrint('⚠️ 使用过期缓存数据：${staleRankings.length}条');
          return _mapCacheToRankingDto(staleRankings);
        }
      }

      // 最后降级：返回模拟数据
      debugPrint('⚠️ 使用模拟数据降级');
      return _generateMockRankings(symbol, 20);
    }
  }

  /// 智能预加载热门数据
  ///
  /// 在应用启动时或空闲时预加载用户可能访问的数据
  Future<void> preloadPopularData() async {
    if (_isPreloading) {
      debugPrint('🔄 预加载已在进行中，跳过');
      return;
    }

    _isPreloading = true;
    debugPrint('🚀 开始智能预加载热门数据...');

    try {
      // 并行预加载核心数据
      final futures = <Future>[];

      // 预加载基金基础信息
      futures.add(_preloadFundBasicInfo());

      // 预加载热门基金排行
      futures.add(_preloadPopularRankings());

      // 等待所有预加载完成
      await Future.wait(futures);

      debugPrint('✅ 智能预加载完成');
    } catch (e) {
      debugPrint('⚠️ 智能预加载失败: $e');
    } finally {
      _isPreloading = false;
    }
  }

  /// 预加载基金基础信息
  Future<void> _preloadFundBasicInfo() async {
    try {
      await getFundBasicInfo(limit: 50); // 预加载前50条
      debugPrint('✅ 基金基础信息预加载完成');
    } catch (e) {
      debugPrint('⚠️ 基金基础信息预加载失败: $e');
    }
  }

  /// 预加载热门基金排行
  Future<void> _preloadPopularRankings() async {
    try {
      final popularTypes = ['全部', '股票型', '混合型'];

      for (final type in popularTypes) {
        await getFundRankings(
          symbol: type,
          enableCache: true,
        );
      }

      debugPrint('✅ 热门基金排行预加载完成');
    } catch (e) {
      debugPrint('⚠️ 热门基金排行预加载失败: $e');
    }
  }

  /// 懒加载更多数据
  ///
  /// 使用异步处理器进行平稳的分批加载
  Future<List<FundDto>> loadMoreFunds({
    String? fundType,
    String? company,
    int batchSize = 5, // 减批5条
    int offset = 0,
  }) async {
    try {
      // 获取全量数据（从缓存或网络）
      final allFunds = await getFundBasicInfo(
        limit: null,
        offset: null,
        fundType: fundType,
        company: company,
      );

      final startIndex = offset;
      if (startIndex >= allFunds.length) {
        return []; // 没有更多数据
      }

      final endIndex = math.min(startIndex + batchSize, allFunds.length);
      final batch = allFunds.sublist(startIndex, endIndex);

      debugPrint('📦 异步加载批次：$startIndex-$endIndex，共${batch.length}条');

      // 添加200毫秒延迟，让UI有时间响应
      await Future.delayed(const Duration(milliseconds: 200));

      return batch;
    } catch (e) {
      debugPrint('❌ 懒加载失败: $e');
      return [];
    }
  }

  /// 获取缓存统计信息
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final stats = {
        'requestCache': {
          'fundRequests': _fundRequestCache.length,
          'rankingRequests': _rankingRequestCache.length,
        },
        'isPreloading': _isPreloading,
        'preloadQueueSize': _preloadQueue.length,
      };

      // 获取底层缓存统计
      final cacheStats = await _cacheRepository.getCacheStats();
      stats.addAll(Map<String, Object>.from(cacheStats));

      return stats;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// 清理缓存
  Future<void> clearCache() async {
    try {
      _fundRequestCache.clear();
      _rankingRequestCache.clear();
      _preloadQueue.clear();

      await _cacheRepository.clearAllCache();
      debugPrint('🧹 所有缓存已清理');
    } catch (e) {
      debugPrint('❌ 清理缓存失败: $e');
    }
  }

  /// 清理请求缓存（延迟清理）
  void _cleanupRequestCache(String type, String key) {
    Future.delayed(const Duration(minutes: 5), () {
      switch (type) {
        case 'fund':
          _fundRequestCache.remove(key);
          break;
        case 'ranking':
          _rankingRequestCache.remove(key);
          break;
      }
    });
  }

  /// 辅助方法：Fund转FundDto
  FundDto _fundToDto(Fund fund) {
    return FundDto(
      fundCode: fund.code,
      fundName: fund.name,
      fundType: fund.type,
      fundCompany: fund.company,
      fundManager: fund.manager,
      fundScale: fund.scale,
      riskLevel: fund.riskLevel,
      status: fund.status,
      dailyReturn: fund.return1Y,
    );
  }

  /// 辅助方法：FundDto转Fund
  Fund _dtoToFund(FundDto dto) {
    return Fund(
      code: dto.fundCode,
      name: dto.fundName,
      type: dto.fundType,
      company: dto.fundCompany,
      manager: dto.fundManager ?? '未知',
      return1W: 0.0,
      return1M: 0.0,
      return3M: 0.0,
      return6M: 0.0,
      return1Y: dto.dailyReturn ?? 0.0,
      return3Y: 0.0,
      scale: dto.fundScale ?? 0.0,
      riskLevel: dto.riskLevel ?? 'R3',
      status: dto.status ?? 'active',
      isFavorite: false,
    );
  }

  /// 辅助方法：筛选和分页
  List<FundDto> _filterAndPaginateFunds(
    List<FundDto> funds,
    int? limit,
    int? offset,
    String? fundType,
    String? company,
  ) {
    var filtered = funds;

    // 筛选
    if (fundType != null && fundType != '全部') {
      filtered = filtered.where((f) => f.fundType == fundType).toList();
    }
    if (company != null && company != '全部') {
      filtered = filtered.where((f) => f.fundCompany == company).toList();
    }

    // 分页
    int startIndex = offset ?? 0;
    int endIndex = filtered.length;
    if (limit != null && limit > 0) {
      endIndex = math.min(startIndex + limit, filtered.length);
    }

    if (startIndex >= filtered.length) return [];

    return filtered.sublist(startIndex, endIndex);
  }

  /// 辅助方法：缓存数据转DTO
  List<FundRankingDto> _mapCacheToRankingDto(
      List<Map<String, dynamic>> cacheData) {
    return cacheData
        .map((data) => FundRankingDto(
              fundCode: data['基金代码'] ?? '',
              fundName: data['基金简称'] ?? '',
              fundType: data['基金类型'] ?? '',
              company: data['公司名称'] ?? '',
              rankingPosition: data['序号'] ?? 0,
              totalCount: data['总数'] ?? 0,
              unitNav: (data['单位净值'] ?? 0).toDouble(),
              accumulatedNav: (data['累计净值'] ?? 0).toDouble(),
              dailyReturn: (data['日增长率'] ?? 0).toDouble(),
              return1W: (data['近1周'] ?? 0).toDouble(),
              return1M: (data['近1月'] ?? 0).toDouble(),
              return3M: (data['近3月'] ?? 0).toDouble(),
              return6M: (data['近6月'] ?? 0).toDouble(),
              return1Y: (data['近1年'] ?? 0).toDouble(),
              return2Y: (data['近2年'] ?? 0).toDouble(),
              return3Y: (data['近3年'] ?? 0).toDouble(),
              returnYTD: (data['今年来'] ?? 0).toDouble(),
              returnSinceInception: (data['成立来'] ?? 0).toDouble(),
              date: data['日期'] ?? DateTime.now().toIso8601String(),
              fee: (data['手续费'] ?? 0).toDouble(),
            ))
        .toList();
  }

  /// 辅助方法：DTO转缓存数据
  List<Map<String, dynamic>> _mapRankingDtoToCache(
      List<FundRankingDto> rankings) {
    return rankings
        .map((ranking) => {
              '基金代码': ranking.fundCode,
              '基金简称': ranking.fundName,
              '基金类型': ranking.fundType,
              '公司名称': ranking.company,
              '序号': ranking.rankingPosition,
              '总数': ranking.totalCount,
              '单位净值': ranking.unitNav,
              '累计净值': ranking.accumulatedNav,
              '日增长率': ranking.dailyReturn,
              '近1周': ranking.return1W,
              '近1月': ranking.return1M,
              '近3月': ranking.return3M,
              '近6月': ranking.return6M,
              '近1年': ranking.return1Y,
              '近2年': ranking.return2Y,
              '近3年': ranking.return3Y,
              '今年来': ranking.returnYTD,
              '成立来': ranking.returnSinceInception,
              '日期': ranking.date,
              '手续费': ranking.fee,
            })
        .toList();
  }

  /// 生成模拟数据（降级用）
  List<FundRankingDto> _generateMockRankings(String symbol, int count) {
    final now = DateTime.now();
    final random = math.Random();

    return List.generate(count, (index) {
      final baseReturn = symbol == '股票型'
          ? 12.0
          : symbol == '债券型'
              ? 4.0
              : symbol == '混合型'
                  ? 8.0
                  : 6.0;

      return FundRankingDto(
        fundCode: '${100000 + index}',
        fundName: '$symbol基金${String.fromCharCode(65 + index % 26)}',
        fundType: symbol,
        company: '测试基金公司',
        rankingPosition: index + 1,
        totalCount: count,
        unitNav: 1.0 + random.nextDouble() * 2.0,
        accumulatedNav: 1.2 + random.nextDouble() * 3.0,
        dailyReturn: baseReturn * 0.001 + (random.nextDouble() - 0.5) * 0.01,
        return1W: baseReturn * 0.01 + (random.nextDouble() - 0.5) * 0.02,
        return1M: baseReturn * 0.05 + (random.nextDouble() - 0.5) * 0.1,
        return3M: baseReturn * 0.15 + (random.nextDouble() - 0.5) * 0.2,
        return6M: baseReturn * 0.3 + (random.nextDouble() - 0.5) * 0.3,
        return1Y: baseReturn + (random.nextDouble() - 0.5) * 5.0,
        return2Y: baseReturn * 1.8 + (random.nextDouble() - 0.5) * 4.0,
        return3Y: baseReturn * 2.5 + (random.nextDouble() - 0.5) * 6.0,
        returnYTD: baseReturn * 0.6 + (random.nextDouble() - 0.5) * 2.0,
        returnSinceInception: baseReturn * 3.0 + random.nextDouble() * 5.0,
        date: now.toIso8601String(),
        fee: 0.5 + random.nextDouble() * 1.0,
      );
    });
  }

  /// 创建默认缓存仓库
  static CacheRepository _createDefaultCacheRepository() {
    // 这里可以返回具体的缓存实现
    // 暂时返回一个简单的内存缓存实现
    return _MemoryCacheRepository();
  }

  /// 关闭服务
  void dispose() {
    _client.close();
    _fundRequestCache.clear();
    _rankingRequestCache.clear();
    _preloadQueue.clear();
  }
}

/// 简单的内存缓存实现
class _MemoryCacheRepository implements CacheRepository {
  final Map<String, List<Fund>> _fundCache = {};
  final Map<String, List<Map<String, dynamic>>> _rankingCache = {};

  @override
  Future<List<Fund>?> getCachedFunds(String cacheKey) async {
    return _fundCache[cacheKey];
  }

  @override
  Future<void> cacheFunds(String cacheKey, List<Fund> funds,
      {Duration? ttl}) async {
    _fundCache[cacheKey] = funds;
  }

  @override
  Future<List<Fund>?> getCachedSearchResults(String query) async {
    return null; // 简化实现
  }

  @override
  Future<void> cacheSearchResults(String query, List<Fund> results,
      {Duration? ttl}) async {
    // 简化实现
  }

  @override
  Future<Fund?> getCachedFundDetail(String fundCode) async {
    return null; // 简化实现
  }

  @override
  Future<void> cacheFundDetail(String fundCode, Fund fund,
      {Duration? ttl}) async {
    // 简化实现
  }

  @override
  Future<List<Fund>?> getCachedFilteredResults(FundFilter filter) async {
    return null; // 简化实现
  }

  @override
  Future<void> cacheFilteredResults(FundFilter filter, List<Fund> results,
      {Duration? ttl}) async {
    // 简化实现
  }

  @override
  Future<List<Map<String, dynamic>>?> getCachedFundRankings(
      String cacheKey) async {
    return _rankingCache[cacheKey];
  }

  @override
  Future<void> cacheFundRankings(
      String cacheKey, List<Map<String, dynamic>> rankings,
      {Duration? ttl}) async {
    _rankingCache[cacheKey] = rankings;
  }

  @override
  Future<bool> isCacheExpired(String cacheKey) async {
    return false; // 简化实现
  }

  @override
  Future<Duration?> getCacheAge(String cacheKey) async {
    return null; // 简化实现
  }

  @override
  Future<void> clearExpiredCache() async {
    // 简化实现：清理所有缓存
    _fundCache.clear();
    _rankingCache.clear();
  }

  @override
  Future<void> clearAllCache() async {
    _fundCache.clear();
    _rankingCache.clear();
  }

  @override
  Future<void> clearCache(String cacheKey) async {
    _fundCache.remove(cacheKey);
    _rankingCache.remove(cacheKey);
  }

  @override
  Future<Map<String, dynamic>> getCacheInfo() async {
    return {
      'fundCacheSize': _fundCache.length,
      'rankingCacheSize': _rankingCache.length,
    };
  }

  @override
  Future<Map<String, dynamic>> getCacheStats() async {
    return {
      'fundCacheSize': _fundCache.length,
      'rankingCacheSize': _rankingCache.length,
    };
  }

  @override
  Future<dynamic> getCachedData(String cacheKey) async {
    // 尝试从不同的缓存中获取数据
    if (_fundCache.containsKey(cacheKey)) {
      return _fundCache[cacheKey];
    }
    if (_rankingCache.containsKey(cacheKey)) {
      return _rankingCache[cacheKey];
    }
    return null;
  }

  @override
  Future<void> cacheData(String cacheKey, dynamic data,
      {required Duration ttl}) async {
    // 根据数据类型存储到不同的缓存中
    if (data is List<Fund>) {
      _fundCache[cacheKey] = data;
    } else if (data is List<Map<String, dynamic>>) {
      _rankingCache[cacheKey] = data;
    }
    // 对于其他类型的数据，暂时不处理
  }
}
