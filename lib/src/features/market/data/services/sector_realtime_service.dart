import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/utils/logger.dart';

/// 板块实时数据服务
///
/// 提供行业板块和概念板块的实时行情数据获取功能
/// 支持单个和批量数据获取
class SectorRealtimeService {
  /// API基础URL
  static const String _baseUrl = 'http://154.44.25.92:8080/api/public';

  /// 获取行业板块实时行情数据
  ///
  /// [symbol] 行业板块代码，如 "煤炭开采"
  ///
  /// 返回包含以下字段的字典列表：
  /// - 序号: 板块排序
  /// - 代码: 板块代码
  /// - 名称: 板块名称
  /// - 最新价: 最新价格
  /// - 涨跌额: 价格涨跌金额
  /// - 涨跌幅: 价格涨跌百分比
  /// - 成交量: 成交量
  /// - 成交额: 成交金额
  /// - 领涨股票: 涨幅最大的股票
  /// - 领涨股票-涨跌幅: 领涨股票的涨跌幅
  /// - 换手率: 换手率
  /// - 量比: 量比
  /// - 上涨家数: 上涨股票数量
  /// - 下跌家数: 下跌股票数量
  /// - 平盘家数: 平盘股票数量
  /// - 市场: 市场类型
  static Future<List<Map<String, dynamic>>> getIndustrySpotData(
      String symbol) async {
    try {
      if (symbol.isEmpty) {
        AppLogger.business('行业板块代码不能为空');
        return [];
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/stock_board_industry_spot_em?symbol=$symbol'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          final result = List<Map<String, dynamic>>.from(data);
          AppLogger.business('成功获取行业板块数据: $symbol, 共${result.length}条记录');
          return result;
        } else {
          AppLogger.business('行业板块数据格式错误: 期望List，实际${data.runtimeType}');
        }
      } else {
        AppLogger.business('获取行业板块数据失败: HTTP ${response.statusCode}');
      }
      return [];
    } catch (e) {
      AppLogger.business('获取行业板块实时数据失败: $e');
      return [];
    }
  }

  /// 获取概念板块实时行情数据
  ///
  /// [symbol] 概念板块代码，如 "国产操作系统"
  ///
  /// 返回包含以下字段的字典列表：
  /// - 序号: 板块排序
  /// - 代码: 板块代码
  /// - 名称: 板块名称
  /// - 最新价: 最新价格
  /// - 涨跌额: 价格涨跌金额
  /// - 涨跌幅: 价格涨跌百分比
  /// - 成交量: 成交量
  /// - 成交额: 成交金额
  /// - 领涨股票: 涨幅最大的股票
  /// - 领涨股票-涨跌幅: 领涨股票的涨跌幅
  /// - 换手率: 换手率
  /// - 量比: 量比
  /// - 上涨家数: 上涨股票数量
  /// - 下跌家数: 下跌股票数量
  /// - 平盘家数: 平盘股票数量
  /// - 市场: 市场类型
  static Future<List<Map<String, dynamic>>> getConceptSpotData(
      String symbol) async {
    try {
      if (symbol.isEmpty) {
        AppLogger.business('概念板块代码不能为空');
        return [];
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/stock_board_concept_spot_em?symbol=$symbol'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          final result = List<Map<String, dynamic>>.from(data);
          AppLogger.business('成功获取概念板块数据: $symbol, 共${result.length}条记录');
          return result;
        } else {
          AppLogger.business('概念板块数据格式错误: 期望List，实际${data.runtimeType}');
        }
      } else {
        AppLogger.business('获取概念板块数据失败: HTTP ${response.statusCode}');
      }
      return [];
    } catch (e) {
      AppLogger.business('获取概念板块实时数据失败: $e');
      return [];
    }
  }

  /// 批量获取多个板块实时数据
  ///
  /// [industrySymbols] 行业板块代码列表，如 ["煤炭开采", "钢铁"]
  /// [conceptSymbols] 概念板块代码列表，如 ["国产操作系统", "人工智能"]
  ///
  /// 返回包含所有板块数据的字典，键为板块类型和代码的组合：
  /// - "industry_煤炭开采": 行业板块数据
  /// - "concept_国产操作系统": 概念板块数据
  ///
  /// 注意：此方法会并行请求所有数据，可能会增加服务器负载
  static Future<Map<String, List<Map<String, dynamic>>>> getBatchSectorData(
    List<String> industrySymbols,
    List<String> conceptSymbols,
  ) async {
    final Map<String, List<Map<String, dynamic>>> result = {};

    try {
      if (industrySymbols.isEmpty && conceptSymbols.isEmpty) {
        AppLogger.business('批量获取板块数据时未提供任何板块代码');
        return result;
      }

      // 并行获取所有数据
      final futures = <Future>[];

      // 获取行业板块数据
      for (final symbol in industrySymbols) {
        if (symbol.isNotEmpty) {
          futures.add(getIndustrySpotData(symbol).then((data) {
            result['industry_$symbol'] = data;
          }).catchError((e) {
            AppLogger.business('获取行业板块数据失败: $symbol, 错误: $e');
            result['industry_$symbol'] = [];
          }));
        }
      }

      // 获取概念板块数据
      for (final symbol in conceptSymbols) {
        if (symbol.isNotEmpty) {
          futures.add(getConceptSpotData(symbol).then((data) {
            result['concept_$symbol'] = data;
          }).catchError((e) {
            AppLogger.business('获取概念板块数据失败: $symbol, 错误: $e');
            result['concept_$symbol'] = [];
          }));
        }
      }

      await Future.wait(futures);

      final successCount =
          result.values.where((data) => data.isNotEmpty).length;
      final totalCount = industrySymbols.length + conceptSymbols.length;
      AppLogger.business('批量获取板块数据完成: 成功$successCount/$totalCount个板块');

      return result;
    } catch (e) {
      AppLogger.business('批量获取板块数据失败: $e');
      return result;
    }
  }
}
