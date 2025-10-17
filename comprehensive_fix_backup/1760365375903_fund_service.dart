import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:jisu_fund_analyzer/src/core/di/hive_injection_container.dart';
import 'package:jisu_fund_analyzer/src/core/network/fund_api_client.dart';
import '../../repositories/cache_repository.dart';

import '../models/fund_dto.dart';

/// 基金数据服务类
///
/// 统一管理所有基金相关的API调用，包括：
/// - 基金基本信息
/// - 基金排行榜
/// - 基金净值历史
/// - 基金经理信息
/// - 基金持仓信息
/// - 基金实时估值
class FundService {
  final CacheRepository _cacheRepository;

  // 请求超时时间 - 进一步减少超时时间
  static const Duration _defaultTimeout = Duration(seconds: 10);
  static const Duration _rankingTimeout = Duration(seconds: 8); // 排行榜专用更短超时

  // API基础URL
  static const String _baseUrl = 'http://154.44.25.92:8080';

  FundService({
    FundApiClient? apiClient,
    CacheRepository? cacheRepository,
  }) : _cacheRepository =
            cacheRepository ?? HiveInjectionContainer.sl<CacheRepository>();

  /// 获取基金基本信息列表
  Future<List<FundDto>> getFundBasicInfo({
    int limit = 20,
    int offset = 0,
    String? fundType,
    String? company,
    Duration timeout = _defaultTimeout,
  }) async {
    try {
      debugPrint('🔄 FundService: 获取基金基本信息，limit=$limit, offset=$offset');

      // 构建缓存key
      final cacheKey =
          'fund_basic_info_${limit}_${offset}_${fundType ?? 'all'}_${company ?? 'all'}';

      // 尝试从缓存获取
      final cachedData = await _cacheRepository.getCachedData(cacheKey);
      if (cachedData != null) {
        debugPrint('✅ FundService: 从缓存获取基金基本信息');
        return _parseFundBasicInfoFromJson(cachedData);
      }

      // 从API获取数据
      final uri = Uri.parse('$_baseUrl/api/public/fund_name_em');

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // 缓存数据
        await _cacheRepository.cacheData(cacheKey, data,
            ttl: const Duration(minutes: 30));

        debugPrint('✅ FundService: 获取基金基本信息成功，共 ${data.length} 条');
        return _parseFundBasicInfoFromJson(data);
      } else {
        throw Exception('获取基金基本信息失败: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ FundService: 获取基金基本信息失败: $e');

      // 返回模拟数据作为降级方案
      return _getMockFundBasicInfo(limit);
    }
  }

  /// 获取基金排行榜
  Future<List<FundRankingDto>> getFundRankings({
    String symbol = '全部',
    bool enableCache = true,
    Duration timeout = _rankingTimeout, // 使用排行榜专用超时时间
    required int pageSize,
  }) async {
    try {
      debugPrint('🔄 FundService: 获取基金排行榜，symbol=$symbol');

      // 构建缓存key
      final cacheKey = 'fund_rankings_${symbol}';

      // 如果启用缓存，先尝试从缓存获取
      if (enableCache) {
        final cachedData = await _cacheRepository.getCachedData(cacheKey);
        if (cachedData != null) {
          debugPrint('✅ FundService: 从缓存获取基金排行榜');
          return await _parseFundRankingsFromJson(cachedData);
        }
      }

      // 从API获取数据
      // 确保URL编码正确处理中文字符
      final uri = Uri(
        scheme: 'http',
        host: '154.44.25.92',
        port: 8080,
        path: 'api/public/fund_open_fund_rank_em',
        queryParameters: {'symbol': symbol},
      );

      // 使用更短的超时时间和连接超时
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json; charset=utf-8',
          'Connection': 'keep-alive',
          'User-Agent': 'jisu-fund-analyzer/1.0',
        },
      ).timeout(timeout, onTimeout: () {
        // 超时时抛出更明确的异常
        throw TimeoutException('基金排行榜请求超时: ${timeout.inSeconds}秒', timeout);
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // 缓存数据
        if (enableCache && data.isNotEmpty) {
          await _cacheRepository.cacheData(cacheKey, data,
              ttl: const Duration(minutes: 15));
        }

        debugPrint('✅ FundService: 获取基金排行榜成功，共 ${data.length} 条');
        return await _parseFundRankingsFromJson(data);
      } else {
        throw Exception('获取基金排行榜失败: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ FundService: 获取基金排行榜失败: $e');

      // 重新构建缓存key，确保在错误处理中可用
      final cacheKey = 'fund_rankings_${symbol}';

      // 更智能的错误处理
      if (e is TimeoutException) {
        debugPrint('⏰ 超时错误，使用缓存降级策略');
        // 尝试获取缓存数据作为降级（不管是否过期）
        final cachedData = await _cacheRepository.getCachedData(cacheKey);
        if (cachedData != null) {
          debugPrint('✅ 使用缓存数据作为超时降级方案');
          return await _parseFundRankingsFromJson(cachedData);
        }
      } else if (e.toString().contains('Connection') ||
          e.toString().contains('Network')) {
        debugPrint('🌐 网络连接错误，检查缓存可用性');
        final cachedData = await _cacheRepository.getCachedData(cacheKey);
        if (cachedData != null) {
          debugPrint('✅ 网络错误，使用缓存数据');
          return await _parseFundRankingsFromJson(cachedData);
        }
      }

      // 返回模拟数据作为最后降级方案
      debugPrint('🔄 使用模拟数据作为最终降级方案');
      return _getMockFundRankings(pageSize > 0 ? pageSize : 50);
    }
  }

  /// 获取基金净值历史
  Future<List<FundNavDto>> getFundNavHistory({
    required String fundCode,
    String indicator = '单位净值走势',
    Duration timeout = _defaultTimeout,
  }) async {
    try {
      debugPrint(
          '🔄 FundService: 获取基金净值历史，fundCode=$fundCode, indicator=$indicator');

      // 构建缓存key
      final cacheKey = 'fund_nav_history_${fundCode}_$indicator';

      // 尝试从缓存获取
      final cachedData = await _cacheRepository.getCachedData(cacheKey);
      if (cachedData != null) {
        debugPrint('✅ FundService: 从缓存获取基金净值历史');
        return _parseFundNavHistoryFromJson(cachedData);
      }

      // 从API获取数据
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/api/public/fund_open_fund_info_em?symbol=$fundCode&indicator=$indicator'),
        headers: {'Accept': 'application/json'},
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // 缓存数据
        await _cacheRepository.cacheData(cacheKey, data,
            ttl: const Duration(hours: 2));

        debugPrint('✅ FundService: 获取基金净值历史成功，共 ${data.length} 条');
        return _parseFundNavHistoryFromJson(data);
      } else {
        throw Exception('获取基金净值历史失败: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ FundService: 获取基金净值历史失败: $e');

      // 返回模拟数据作为降级方案
      return _getMockFundNavHistory(fundCode);
    }
  }

  /// 获取热门基金
  Future<List<FundDto>> getHotFunds({
    int limit = 10,
    Duration timeout = _defaultTimeout,
  }) async {
    try {
      debugPrint('🔄 FundService: 获取热门基金，limit=$limit');

      // 构建缓存key
      final cacheKey = 'hot_funds_$limit';

      // 尝试从缓存获取
      final cachedData = await _cacheRepository.getCachedData(cacheKey);
      if (cachedData != null) {
        debugPrint('✅ FundService: 从缓存获取热门基金');
        return _parseFundBasicInfoFromJson(cachedData);
      }

      // 从API获取数据
      final uri = Uri.parse('$_baseUrl/api/public/fund_name_em');

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // 获取前limit条数据作为热门基金
        final hotFundsData = data.take(limit).toList();

        // 缓存数据
        await _cacheRepository.cacheData(cacheKey, hotFundsData,
            ttl: const Duration(minutes: 30));

        debugPrint('✅ FundService: 获取热门基金成功，共 ${hotFundsData.length} 条');
        return _parseFundBasicInfoFromJson(hotFundsData);
      } else {
        throw Exception('获取热门基金失败: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ FundService: 获取热门基金失败: $e');

      // 返回模拟数据作为降级方案
      return _getMockHotFunds(limit);
    }
  }

  /// 搜索基金
  Future<List<FundDto>> searchFunds({
    required String query,
    int limit = 20,
    Duration timeout = _defaultTimeout,
  }) async {
    try {
      debugPrint('🔄 FundService: 搜索基金，query=$query, limit=$limit');

      if (query.isEmpty) {
        return [];
      }

      // 构建缓存key
      final cacheKey = 'fund_search_${query}_$limit';

      // 尝试从缓存获取
      final cachedData = await _cacheRepository.getCachedData(cacheKey);
      if (cachedData != null) {
        debugPrint('✅ FundService: 从缓存获取搜索结果');
        return _parseFundBasicInfoFromJson(cachedData);
      }

      // 从API获取数据
      final uri = Uri.parse('$_baseUrl/api/public/fund_name_em');

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // 搜索过滤
        final searchResults = data
            .where((item) {
              final name = (item['基金简称'] ?? '').toString().toLowerCase();
              final code = (item['基金代码'] ?? '').toString().toLowerCase();
              final company = (item['管理公司'] ?? '').toString().toLowerCase();
              final queryLower = query.toLowerCase();

              return name.contains(queryLower) ||
                  code.contains(queryLower) ||
                  company.contains(queryLower);
            })
            .take(limit)
            .toList();

        // 缓存数据
        if (searchResults.isNotEmpty) {
          await _cacheRepository.cacheData(cacheKey, searchResults,
              ttl: const Duration(minutes: 15));
        }

        debugPrint('✅ FundService: 搜索基金成功，共 ${searchResults.length} 条');
        return _parseFundBasicInfoFromJson(searchResults);
      } else {
        throw Exception('搜索基金失败: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ FundService: 搜索基金失败: $e');

      // 返回空列表
      return [];
    }
  }

  /// 获取基金持仓信息
  Future<List<FundHoldingDto>> getFundHoldings({
    required String fundCode,
    required String year,
    Duration timeout = _defaultTimeout,
  }) async {
    try {
      debugPrint('🔄 FundService: 获取基金持仓，fundCode=$fundCode, year=$year');

      // 构建缓存key
      final cacheKey = 'fund_holdings_${fundCode}_$year';

      // 尝试从缓存获取
      final cachedData = await _cacheRepository.getCachedData(cacheKey);
      if (cachedData != null) {
        debugPrint('✅ FundService: 从缓存获取基金持仓');
        return _parseFundHoldingsFromJson(cachedData);
      }

      // 注意：这里使用一个假设的API端点
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/api/public/fund_portfolio_em?symbol=$fundCode&year=$year'),
        headers: {'Accept': 'application/json'},
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // 缓存数据
        await _cacheRepository.cacheData(cacheKey, data,
            ttl: const Duration(hours: 6));

        debugPrint('✅ FundService: 获取基金持仓成功，共 ${data.length} 条');
        return _parseFundHoldingsFromJson(data);
      } else {
        throw Exception('获取基金持仓失败: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ FundService: 获取基金持仓失败: $e');

      // 返回模拟数据作为降级方案
      return _getMockFundHoldings(fundCode);
    }
  }

  /// 获取基金实时估值
  Future<List<FundEstimateDto>> getFundValueEstimation({
    required String symbol,
    Duration timeout = _defaultTimeout,
  }) async {
    try {
      debugPrint('🔄 FundService: 获取基金估值，symbol=$symbol');

      // 构建缓存key
      final cacheKey = 'fund_estimate_$symbol';

      // 尝试从缓存获取
      final cachedData = await _cacheRepository.getCachedData(cacheKey);
      if (cachedData != null) {
        debugPrint('✅ FundService: 从缓存获取基金估值');
        return _parseFundEstimatesFromJson(cachedData);
      }

      // 注意：这里使用一个假设的API端点
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/api/public/fund_value_estimation_em?symbol=$symbol'),
        headers: {'Accept': 'application/json'},
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // 缓存数据
        await _cacheRepository.cacheData(cacheKey, data,
            ttl: const Duration(minutes: 5));

        debugPrint('✅ FundService: 获取基金估值成功，共 ${data.length} 条');
        return _parseFundEstimatesFromJson(data);
      } else {
        throw Exception('获取基金估值失败: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ FundService: 获取基金估值失败: $e');

      // 返回模拟数据作为降级方案
      return _getMockFundEstimates(symbol);
    }
  }

  /// 解析基金基本信息JSON数据
  List<FundDto> _parseFundBasicInfoFromJson(List<dynamic> data) {
    return data.map((item) => FundDto.fromJson(item)).toList();
  }

  /// 解析基金排行榜JSON数据（异步分批处理大数据量）
  Future<List<FundRankingDto>> _parseFundRankingsFromJson(
      List<dynamic> data) async {
    if (data.isEmpty) return [];

    // 如果数据量较小，直接同步处理
    if (data.length <= 500) {
      return data.map((item) => FundRankingDto.fromJson(item)).toList();
    }

    // 大数据量使用异步分批处理
    debugPrint('🚀 开始异步分批处理 ${data.length} 条基金排行榜数据');

    final results = <FundRankingDto>[];
    final batchSize = 100;
    final totalItems = data.length;

    // 分批处理数据，让出控制权避免UI卡死
    for (int i = 0; i < totalItems; i += batchSize) {
      final batchEnd = (i + batchSize).clamp(0, totalItems);
      final batchData = data.sublist(i, batchEnd);

      // 处理当前批次
      for (final item in batchData) {
        try {
          final fundRanking = FundRankingDto.fromJson(item);
          results.add(fundRanking);
        } catch (e) {
          // 静默处理单个数据错误，避免整个批次失败
          if (kDebugMode) debugPrint('⚠️ 处理单条基金数据失败: $e');
        }
      }

      // 每处理1000条或最后一批时输出进度
      final processedCount = (i + batchSize).clamp(0, totalItems);
      if (processedCount % 1000 == 0 || processedCount == totalItems) {
        debugPrint(
            '📊 异步处理进度: $processedCount/$totalItems (${(processedCount / totalItems * 100).toStringAsFixed(1)}%)');
      }

      // 让出控制权，避免UI卡死（除了最后一批）
      if (i + batchSize < totalItems) {
        await Future.delayed(const Duration(milliseconds: 200)); // 每批次延迟200毫秒
      }
    }

    debugPrint('✅ 异步处理完成，成功解析 ${results.length} 条基金数据');
    return results;
  }

  /// 解析基金净值历史JSON数据
  List<FundNavDto> _parseFundNavHistoryFromJson(List<dynamic> data) {
    return data.map((item) => FundNavDto.fromJson(item)).toList();
  }

  /// 解析基金持仓JSON数据
  List<FundHoldingDto> _parseFundHoldingsFromJson(List<dynamic> data) {
    return data.map((item) => FundHoldingDto.fromJson(item)).toList();
  }

  /// 解析基金估值JSON数据
  List<FundEstimateDto> _parseFundEstimatesFromJson(List<dynamic> data) {
    return data.map((item) => FundEstimateDto.fromJson(item)).toList();
  }

  // 模拟数据方法
  List<FundDto> _getMockFundBasicInfo(int limit) {
    return List.generate(
        limit,
        (index) => FundDto(
              fundCode: '100${(index + 1).toString().padLeft(5, '0')}',
              fundName: '模拟基金${index + 1}',
              fundType: index % 3 == 0
                  ? '股票型'
                  : index % 3 == 1
                      ? '债券型'
                      : '混合型',
              fundCompany: index % 5 == 0
                  ? '易方达基金'
                  : index % 5 == 1
                      ? '华夏基金'
                      : index % 5 == 2
                          ? '南方基金'
                          : index % 5 == 3
                              ? '嘉实基金'
                              : '博时基金',
              fundManager: '基金经理${index + 1}',
              fundScale: (50.0 + index * 12.5) % 500.0,
              riskLevel: index % 5 == 0
                  ? 'R1'
                  : index % 5 == 1
                      ? 'R2'
                      : index % 5 == 2
                          ? 'R3'
                          : index % 5 == 3
                              ? 'R4'
                              : 'R5',
              status: 'active',
              unitNav: (1.0 + index * 0.1) % 5.0,
              accumulatedNav: (1.5 + index * 0.15) % 6.0,
              dailyReturn: (index % 10 - 5) * 0.5,
              establishDate: DateTime.now()
                  .subtract(Duration(days: (index + 1) * 365))
                  .toIso8601String(),
            ));
  }

  List<FundRankingDto> _getMockFundRankings(int pageSize) {
    return List.generate(
        pageSize,
        (index) => FundRankingDto(
              fundCode: '100${(index + 1).toString().padLeft(5, '0')}',
              fundName: '排行基金${index + 1}',
              fundType: index % 3 == 0
                  ? '股票型'
                  : index % 3 == 1
                      ? '债券型'
                      : '混合型',
              company: index % 5 == 0
                  ? '易方达基金'
                  : index % 5 == 1
                      ? '华夏基金'
                      : index % 5 == 2
                          ? '南方基金'
                          : index % 5 == 3
                              ? '嘉实基金'
                              : '博时基金',
              rankingPosition: index + 1,
              totalCount: 1000,
              unitNav: (1.0 + index * 0.1) % 5.0,
              accumulatedNav: (1.5 + index * 0.15) % 6.0,
              dailyReturn: (index % 10 - 5) * 0.5,
              return1W: (0.5 + index * 0.3) % 5.0,
              return1M: (2.0 + index * 0.8) % 10.0,
              return3M: (5.0 + index * 1.2) % 20.0,
              return6M: (8.0 + index * 1.8) % 30.0,
              return1Y: (15.0 + index * 2.5) % 50.0,
              return2Y: (25.0 + index * 3.0) % 60.0,
              return3Y: (35.0 + index * 3.5) % 80.0,
              returnYTD: (12.0 + index * 2.2) % 40.0,
              returnSinceInception: (60.0 + index * 5.5) % 150.0,
              date: DateTime.now().toString().substring(0, 10),
              fee: 1.5,
            ));
  }

  List<FundDto> _getMockHotFunds(int limit) {
    return List.generate(
        limit,
        (index) => FundDto(
              fundCode: '00${(index + 1).toString().padLeft(6, '0')}',
              fundName: '热门基金${index + 1}',
              fundType: index % 3 == 0
                  ? '股票型'
                  : index % 3 == 1
                      ? '债券型'
                      : '混合型',
              fundCompany: index % 5 == 0
                  ? '易方达基金'
                  : index % 5 == 1
                      ? '华夏基金'
                      : index % 5 == 2
                          ? '南方基金'
                          : index % 5 == 3
                              ? '嘉实基金'
                              : '博时基金',
              fundManager: '明星基金经理${index + 1}',
              fundScale: (100.0 + index * 25.0) % 800.0,
              riskLevel: index % 5 == 0
                  ? 'R1'
                  : index % 5 == 1
                      ? 'R2'
                      : index % 5 == 2
                          ? 'R3'
                          : index % 5 == 3
                              ? 'R4'
                              : 'R5',
              status: 'active',
              unitNav: (2.0 + index * 0.2) % 6.0,
              accumulatedNav: (2.8 + index * 0.3) % 8.0,
              dailyReturn: (index % 8 - 4) * 0.8,
              establishDate: DateTime.now()
                  .subtract(Duration(days: (index + 1) * 400))
                  .toIso8601String(),
            ));
  }

  List<FundNavDto> _getMockFundNavHistory(String fundCode) {
    final now = DateTime.now();
    return List.generate(30, (index) {
      final date = now.subtract(Duration(days: 29 - index));
      final baseNav = 2.0 + index * 0.01;
      final randomChange = (index % 7 - 3) * 0.01;

      return FundNavDto(
        fundCode: fundCode,
        navDate: date.toIso8601String().split('T')[0],
        unitNav: baseNav + randomChange,
        accumulatedNav: baseNav + randomChange + 0.5,
        dailyReturn: index > 0
            ? ((baseNav + randomChange) - (2.0 + (index - 1) * 0.01)) /
                (2.0 + (index - 1) * 0.01) *
                100
            : 0,
        totalNetAssets: 200.0 + index * 2.5,
        subscriptionStatus: '开放',
        redemptionStatus: '开放',
      );
    });
  }

  List<FundHoldingDto> _getMockFundHoldings(String fundCode) {
    return [
      FundHoldingDto(
        fundCode: fundCode,
        reportDate: '2024-06-30',
        holdingType: 'stock',
        stockCode: '000001',
        stockName: '平安银行',
        holdingQuantity: 1000000,
        holdingValue: 15000000,
        holdingPercentage: 8.5,
        marketValue: 15000000,
        sector: '金融',
      ),
      FundHoldingDto(
        fundCode: fundCode,
        reportDate: '2024-06-30',
        holdingType: 'stock',
        stockCode: '000002',
        stockName: '万科A',
        holdingQuantity: 800000,
        holdingValue: 12000000,
        holdingPercentage: 6.8,
        marketValue: 12000000,
        sector: '房地产',
      ),
      FundHoldingDto(
        fundCode: fundCode,
        reportDate: '2024-06-30',
        holdingType: 'stock',
        stockCode: '600036',
        stockName: '招商银行',
        holdingQuantity: 600000,
        holdingValue: 18000000,
        holdingPercentage: 10.2,
        marketValue: 18000000,
        sector: '金融',
      ),
    ];
  }

  List<FundEstimateDto> _getMockFundEstimates(String symbol) {
    return [
      FundEstimateDto(
        fundCode: symbol,
        estimateValue: 2.3456,
        estimateReturn: 0.85,
        estimateTime: '14:30:00',
        previousNav: 2.3278,
        previousNavDate: DateTime.now()
            .subtract(const Duration(days: 1))
            .toString()
            .split(' ')[0],
      ),
    ];
  }

  /// 释放资源
  void dispose() {
    // 清理资源
    debugPrint('FundService: 资源已释放');
  }
}
