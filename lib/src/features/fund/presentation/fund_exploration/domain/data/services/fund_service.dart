import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

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
  // 请求超时时间
  static Duration defaultTimeout = const Duration(seconds: 30);
  static Duration rankingTimeout = const Duration(seconds: 60);

  // API基础URL
  static String baseUrl = 'http://154.44.25.92:8080';

  /// 获取基金基本信息列表
  Future<List<FundDto>> getFundBasicInfo({
    int limit = 20,
    int offset = 0,
    String? fundType,
    String? company,
    Duration? timeout,
  }) async {
    try {
      debugPrint('🔄 FundService: 获取基金基本信息，limit=$limit, offset=$offset');

      // 缓存key（暂时不使用，预留后续缓存功能）
      // final cacheKey = 'fund_basic_info_${limit}_${offset}_${fundType ?? 'all'}_${company ?? 'all'}';

      // 从API获取数据
      final uri = Uri.parse('$baseUrl/api/public/fund_name_em');

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(timeout ?? defaultTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;

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
    Duration? timeout,
    required int pageSize,
  }) async {
    try {
      debugPrint('🔄 FundService: 获取基金排行榜，symbol=$symbol');

      // 从API获取数据
      final uri = Uri(
        scheme: 'http',
        host: '154.44.25.92',
        port: 8080,
        path: 'api/public/fund_open_fund_rank_em',
        queryParameters: {'symbol': symbol},
      );

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json; charset=utf-8',
          'Connection': 'keep-alive',
          'User-Agent': 'baostock-analyzer/1.0',
        },
      ).timeout(timeout ?? rankingTimeout, onTimeout: () {
        final actualTimeout = timeout ?? rankingTimeout;
        throw TimeoutException(
            '基金排行榜请求超时: ${actualTimeout.inSeconds}秒', actualTimeout);
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;

        debugPrint('✅ FundService: 获取基金排行榜成功，共 ${data.length} 条');
        return await _parseFundRankingsFromJson(data);
      } else {
        throw Exception('获取基金排行榜失败: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ FundService: 获取基金排行榜失败: $e');

      // 返回模拟数据作为最后降级方案
      debugPrint('🔄 使用模拟数据作为最终降级方案');
      return _getMockFundRankings(pageSize > 0 ? pageSize : 50);
    }
  }

  /// 获取基金净值历史
  Future<List<FundNavDto>> getFundNavHistory({
    required String fundCode,
    String indicator = '单位净值走势',
    Duration? timeout,
  }) async {
    try {
      debugPrint(
          '🔄 FundService: 获取基金净值历史，fundCode=$fundCode, indicator=$indicator');

      // 从API获取数据
      final response = await http.get(
        Uri.parse(
            '$baseUrl/api/public/fund_open_fund_info_em?symbol=$fundCode&indicator=$indicator'),
        headers: {'Accept': 'application/json'},
      ).timeout(timeout ?? defaultTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;

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
    Duration? timeout,
  }) async {
    try {
      debugPrint('🔄 FundService: 获取热门基金，limit=$limit');

      // 从API获取数据
      final uri = Uri.parse('$baseUrl/api/public/fund_name_em');

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json; charset=utf-8',
          'Connection': 'keep-alive',
          'User-Agent': 'baostock-analyzer/1.0',
        },
      ).timeout(timeout ?? rankingTimeout); // 使用更长的超时时间

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;

        // 获取前limit条数据作为热门基金
        final hotFundsData = data.take(limit).toList();

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
    Duration? timeout,
  }) async {
    try {
      debugPrint('🔄 FundService: 搜索基金，query=$query, limit=$limit');

      if (query.isEmpty) {
        return [];
      }

      // 从API获取数据
      final uri = Uri.parse('$baseUrl/api/public/fund_name_em');

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(timeout ?? defaultTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;

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

  /// 解析基金基本信息JSON数据
  List<FundDto> _parseFundBasicInfoFromJson(List<dynamic> data) {
    return data.map((item) {
      try {
        return FundDto(
          fundCode: item['基金代码']?.toString() ?? '',
          fundName: item['基金简称']?.toString() ?? '',
          fundType: item['基金类型']?.toString() ?? '',
          fundCompany: item['管理公司']?.toString() ?? '',
          fundManager: item['基金经理']?.toString() ?? '',
          fundScale: _parseDouble(item['基金规模']) ?? 0.0,
          riskLevel: item['风险等级']?.toString() ?? 'R3',
          status: item['基金状态']?.toString() ?? 'active',
          unitNav: _parseDouble(item['单位净值']) ?? 0.0,
          accumulatedNav: _parseDouble(item['累计净值']) ?? 0.0,
          dailyReturn: _parseDouble(item['日增长率']) ?? 0.0,
          establishDate: item['成立日期']?.toString() ?? '',
        );
      } catch (e) {
        debugPrint('⚠️ 解析基金数据失败: $e');
        return _getMockFundBasicInfo(1).first;
      }
    }).toList();
  }

  /// 解析基金排行榜JSON数据
  Future<List<FundRankingDto>> _parseFundRankingsFromJson(
      List<dynamic> data) async {
    if (data.isEmpty) return [];

    debugPrint('🚀 开始处理 ${data.length} 条基金排行榜数据');

    final results = <FundRankingDto>[];

    for (final item in data) {
      try {
        final fundRanking = FundRankingDto(
          fundCode: item['基金代码']?.toString() ?? '',
          fundName: item['基金简称']?.toString() ?? '',
          fundType: item['基金类型']?.toString() ?? '',
          company: item['基金公司']?.toString() ?? '',
          rankingPosition: _parseInt(item['排名']) ?? 1,
          totalCount: data.length,
          unitNav: _parseDouble(item['单位净值']) ?? 0.0,
          accumulatedNav: _parseDouble(item['累计净值']) ?? 0.0,
          dailyReturn: _parseDouble(item['日增长率']) ?? 0.0,
          return1W: _parseDouble(item['近1周']) ?? 0.0,
          return1M: _parseDouble(item['近1月']) ?? 0.0,
          return3M: _parseDouble(item['近3月']) ?? 0.0,
          return6M: _parseDouble(item['近6月']) ?? 0.0,
          return1Y: _parseDouble(item['近1年']) ?? 0.0,
          return2Y: _parseDouble(item['近2年']) ?? 0.0,
          return3Y: _parseDouble(item['近3年']) ?? 0.0,
          returnYTD: _parseDouble(item['今年来']) ?? 0.0,
          returnSinceInception: _parseDouble(item['成立来']) ?? 0.0,
          date: item['日期']?.toString() ??
              DateTime.now().toString().substring(0, 10),
          fee: _parseDouble(item['手续费']) ?? 0.0,
        );
        results.add(fundRanking);
      } catch (e) {
        debugPrint('⚠️ 处理单条基金数据失败: $e');
      }
    }

    debugPrint('✅ 处理完成，成功解析 ${results.length} 条基金数据');
    return results;
  }

  /// 解析基金净值历史JSON数据
  List<FundNavDto> _parseFundNavHistoryFromJson(List<dynamic> data) {
    return data.map((item) {
      return FundNavDto(
        fundCode: item['基金代码']?.toString() ?? '',
        navDate: item['净值日期']?.toString() ?? '',
        unitNav: _parseDouble(item['单位净值']) ?? 0.0,
        accumulatedNav: _parseDouble(item['累计净值']) ?? 0.0,
        dailyReturn: _parseDouble(item['日增长率']) ?? 0.0,
        totalNetAssets: _parseDouble(item['资产净值']) ?? 0.0,
        subscriptionStatus: item['申购状态']?.toString() ?? '开放',
        redemptionStatus: item['赎回状态']?.toString() ?? '开放',
      );
    }).toList();
  }

  /// 解析double值
  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final cleanValue =
          value.toString().replaceAll('%', '').replaceAll(',', '');
      return double.tryParse(cleanValue);
    }
    return null;
  }

  /// 解析int值
  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
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

  /// 释放资源
  void dispose() {
    debugPrint('FundService: 资源已释放');
  }
}
