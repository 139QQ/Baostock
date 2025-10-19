/// 图表数据服务
///
/// 专门负责为图表组件提供真实基金数据的服务
/// 将API响应转换为图表组件所需的数据格式
library chart_data_service;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:jisu_fund_analyzer/src/core/network/fund_api_client.dart';
import '../models/chart_data.dart';

/// 图表数据服务类
///
/// 提供以下功能：
/// - 获取基金净值走势数据并转换为图表格式
/// - 获取基金收益率对比数据
/// - 获取基金排行榜数据并转换为图表格式
/// - 提供多种时间维度的数据视图
class ChartDataService {
  static const String _baseUrl = 'http://154.44.25.92:8080';
  static const Duration _defaultTimeout = Duration(seconds: 30);

  /// 获取基金净值走势图数据
  ///
  /// [fundCode] 基金代码，如"009209"
  /// [timeRange] 时间范围：1月, 3月, 6月, 1年, 3年, 成立来
  /// [indicator] 指标类型：单位净值走势, 累计净值走势, 累计收益率走势, 同类排名走势, 同类排名百分比
  ///
  /// 注意：基金数据遵循T+1披露规则
  /// - 常规开放式基金：T+1日披露（交易日收盘后计算，当晚或次日更新）
  /// - QDII基金：T+2日披露
  /// - FOF基金：T+3日披露
  /// - 查询时间早于披露节点时，数据可能不完整或显示为空
  Future<List<ChartDataSeries>> getFundNavChartSeries({
    required String fundCode,
    String timeRange = '1年',
    String indicator = '单位净值走势',
  }) async {
    try {
      debugPrint(
          '🔄 ChartDataService: 获取基金净值走势数据，fundCode=$fundCode, timeRange=$timeRange, indicator=$indicator');

      // 使用fund_open_fund_info_em接口获取历史净值数据
      final response = await http
          .get(
            Uri.parse(
                '$_baseUrl/api/public/fund_open_fund_info_em?symbol=$fundCode&indicator=$indicator&period=$timeRange'),
          )
          .timeout(_defaultTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        debugPrint('✅ ChartDataService: 获取基金净值数据成功，共 ${data.length} 条');

        // 打印API返回的原始数据，用于调试和字段对比
        debugPrint('🔍 ChartDataService API返回原始数据:');
        if (data.isNotEmpty) {
          final firstItem = data.first as Map<String, dynamic>;
          debugPrint('第一条数据: $firstItem');
          debugPrint('原始字段: ${firstItem.keys.toList()}');

          // 解码字段名
          final decodedFirst = _decodeFieldNames(firstItem);
          debugPrint('解码字段: ${decodedFirst.keys.toList()}');
        }

        return _parseNavDataToChartSeries(data, fundCode, indicator);
      } else {
        throw Exception('获取基金净值数据失败: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ ChartDataService: 获取基金净值数据失败: $e');

      // 返回模拟数据作为降级方案
      return _getMockNavChartSeries(fundCode, indicator);
    }
  }

  /// 获取多只基金净值对比数据
  ///
  /// [fundCodes] 基金代码列表
  /// [timeRange] 时间范围
  /// [indicator] 指标类型
  Future<List<ChartDataSeries>> getFundsComparisonChartSeries({
    required List<String> fundCodes,
    String timeRange = '1Y',
    String indicator = '单位净值走势',
  }) async {
    try {
      debugPrint('🔄 ChartDataService: 获取基金对比数据，fundCodes=$fundCodes');

      final allSeries = <ChartDataSeries>[];

      // 并发获取多只基金数据
      final futures = fundCodes.map((fundCode) async {
        final seriesList = await getFundNavChartSeries(
          fundCode: fundCode,
          timeRange: timeRange,
          indicator: indicator,
        );
        return seriesList.isNotEmpty ? seriesList.first : null;
      }).toList();

      final results = await Future.wait(futures);

      for (final series in results) {
        if (series != null) {
          allSeries.add(series);
        }
      }

      debugPrint('✅ ChartDataService: 获取基金对比数据成功，共 ${allSeries.length} 只基金');
      return allSeries;
    } catch (e) {
      debugPrint('❌ ChartDataService: 获取基金对比数据失败: $e');

      // 返回模拟数据
      return _getMockComparisonChartSeries(fundCodes);
    }
  }

  /// 获取基金排行榜图表数据
  ///
  /// [symbol] 基金类型：全部, 股票型, 混合型, 债券型, 指数型, QDII, ETF
  /// [topN] 取前N只基金
  /// [indicator] 排序指标：近1月, 近3月, 近6月, 近1年, 今年来
  Future<List<ChartDataSeries>> getFundRankingChartSeries({
    String symbol = '全部',
    int topN = 10,
    String indicator = '近1年',
  }) async {
    try {
      debugPrint('🔄 ChartDataService: 获取基金排行榜数据，symbol=$symbol, topN=$topN');

      final response = await FundApiClient.getFundRanking('overall', '1Y');
      final data = response['data'] as List<dynamic>? ?? [];

      if (data.isNotEmpty) {
        // 取前N只基金
        final topFunds = data.take(topN).toList();
        debugPrint('✅ ChartDataService: 获取基金排行榜成功，共 ${topFunds.length} 只基金');

        return _parseRankingDataToChartSeries(topFunds, indicator);
      } else {
        throw Exception('获取基金排行榜数据为空');
      }
    } catch (e) {
      debugPrint('❌ ChartDataService: 获取基金排行榜数据失败: $e');

      // 返回模拟数据
      return _getMockRankingChartSeries(topN, indicator);
    }
  }

  /// 获取基金收益率分布图数据
  ///
  /// [symbol] 基金类型
  /// [indicator] 收益率指标
  Future<List<ChartDataSeries>> getFundReturnDistributionChartSeries({
    String symbol = '全部',
    String indicator = '近1年',
  }) async {
    try {
      debugPrint('🔄 ChartDataService: 获取基金收益率分布数据，symbol=$symbol');

      final response = await FundApiClient.getFundRanking('overall', '1Y');
      final data = response['data'] as List<dynamic>? ?? [];

      if (data.isNotEmpty) {
        debugPrint('✅ ChartDataService: 获取基金收益率分布成功，共 ${data.length} 只基金');

        return _parseReturnDistributionToChartSeries(data, indicator);
      } else {
        throw Exception('获取基金收益率分布数据为空');
      }
    } catch (e) {
      debugPrint('❌ ChartDataService: 获取基金收益率分布数据失败: $e');

      // 返回模拟数据
      return _getMockReturnDistributionChartSeries(indicator);
    }
  }

  /// 解析净值数据为图表系列
  List<ChartDataSeries> _parseNavDataToChartSeries(
    List<dynamic> data,
    String fundCode,
    String indicator,
  ) {
    if (data.isEmpty) return [];

    final chartPoints = <ChartPoint>[];
    String fundName = '基金$fundCode';

    for (int i = 0; i < data.length; i++) {
      final item = data[i];

      try {
        // 解码UTF-8字段名
        final decodedItem = _decodeFieldNames(item as Map<String, dynamic>);

        // 根据指标精确匹配解码后的字段
        String navDate = '';
        double navValue = 0.0;

        // 【修改后】根据不同指标，精确匹配接口返回的字段，使用解码后的字段名
        if (indicator == '单位净值走势') {
          navDate = decodedItem['净值日期']?.toString() ?? '';
          navValue = _parseDouble(decodedItem['单位净值']) ?? 0.0;
        } else if (indicator == '累计净值走势') {
          navDate = decodedItem['净值日期']?.toString() ?? '';
          navValue = _parseDouble(decodedItem['累计净值']) ?? 0.0;
        } else if (indicator.contains('收益率')) {
          // 使用单位净值走势中的日增长率字段
          navDate = decodedItem['净值日期']?.toString() ?? '';
          navValue = _parseDouble(decodedItem['日增长率']) ?? 0.0;
        } else if (indicator.contains('排名')) {
          navDate = decodedItem['报告日期']?.toString() ?? '';
          // 修复同类排名百分比的字段名
          navValue = _parseDouble(decodedItem['同类型排名-每日近3月收益排名百分比']) ?? 0.0;
        } else if (indicator.contains('分红') || indicator.contains('送配')) {
          // 分红送配详情处理
          navDate = decodedItem['权益登记日']?.toString() ??
              decodedItem['除权除息日']?.toString() ??
              decodedItem['净值日期']?.toString() ??
              '';
          navValue = _parseDouble(decodedItem['每份分红']) ??
              _parseDouble(decodedItem['分红金额']) ??
              _parseDouble(decodedItem.values.first) ??
              0.0;
        } else if (indicator.contains('拆分')) {
          // 拆分详情处理
          navDate = decodedItem['拆分基准日']?.toString() ??
              decodedItem['除权日']?.toString() ??
              decodedItem['净值日期']?.toString() ??
              '';
          navValue = _parseDouble(decodedItem['拆分比例']) ??
              _parseDouble(decodedItem['拆分倍数']) ??
              _parseDouble(decodedItem.values.first) ??
              0.0;
        } else {
          // 默认使用单位净值
          navDate = decodedItem['净值日期']?.toString() ?? '';
          navValue = _parseDouble(decodedItem['单位净值']) ?? 0.0;
        }

        // 解析日期，只保留日期部分
        String displayDate = navDate;
        if (navDate.contains('T')) {
          displayDate = navDate.split('T')[0];
        }

        double xValue = i.toDouble(); // 使用索引作为X轴

        chartPoints.add(ChartPoint(
          x: xValue,
          y: navValue,
          label: '$displayDate\n$indicator: ${navValue.toStringAsFixed(4)}',
        ));
      } catch (e) {
        debugPrint('⚠️ 解析净值数据失败: $e');
      }
    }

    // 如果没有真实数据，生成模拟数据
    if (chartPoints.isEmpty) {
      debugPrint('⚠️ ChartDataService: 未获取到有效数据，可能原因：');
      debugPrint('  - 基金数据遵循T+1披露规则，当前时间早于披露节点');
      debugPrint('  - 基金代码不存在或已退市');
      debugPrint('  - API服务器暂时不可用');
      debugPrint('  - 网络连接问题');
      return _getMockNavChartSeries(fundCode, indicator);
    }

    // 确定颜色
    final color = _getFundColor(fundCode);

    return [
      ChartDataSeries(
        data: chartPoints,
        name: '$fundName ($indicator)',
        color: color,
        showDots: chartPoints.length <= 30, // 数据点少时显示点
        showArea: indicator.contains('累计'), // 累计净值显示区域
        lineWidth: indicator.contains('累计') ? 2.5 : 2.0,
      ),
    ];
  }

  /// 解析排行榜数据为图表系列
  List<ChartDataSeries> _parseRankingDataToChartSeries(
    List<dynamic> data,
    String indicator,
  ) {
    if (data.isEmpty) return [];

    final chartPoints = <ChartPoint>[];

    for (int i = 0; i < data.length; i++) {
      final item = data[i];

      try {
        final fundName = item['基金简称']?.toString() ?? '未知基金';
        final returnValue = _parseDouble(item[indicator]) ?? 0.0;

        chartPoints.add(ChartPoint(
          x: i.toDouble(),
          y: returnValue,
          label: '$fundName\n$indicator: ${returnValue.toStringAsFixed(2)}%',
        ));
      } catch (e) {
        debugPrint('⚠️ 解析排行榜数据失败: $e');
      }
    }

    return [
      ChartDataSeries(
        data: chartPoints,
        name: '基金排行榜 ($indicator)',
        color: Colors.blue,
        showDots: true,
        showArea: false,
        lineWidth: 2.0,
      ),
    ];
  }

  /// 解析收益率分布数据为图表系列
  List<ChartDataSeries> _parseReturnDistributionToChartSeries(
    List<dynamic> data,
    String indicator,
  ) {
    if (data.isEmpty) return [];

    // 统计不同收益率区间的基金数量
    final Map<String, int> distribution = {};

    for (final item in data) {
      try {
        final returnValue = _parseDouble(item[indicator]) ?? 0.0;
        final range = _getReturnRange(returnValue);
        distribution[range] = (distribution[range] ?? 0) + 1;
      } catch (e) {
        debugPrint('⚠️ 解析收益率分布数据失败: $e');
      }
    }

    final chartPoints = <ChartPoint>[];
    final sortedRanges = distribution.keys.toList()..sort();

    for (int i = 0; i < sortedRanges.length; i++) {
      final range = sortedRanges[i];
      final count = distribution[range] ?? 0;

      chartPoints.add(ChartPoint(
        x: i.toDouble(),
        y: count.toDouble(),
        label: '$range\n$count只基金',
      ));
    }

    return [
      ChartDataSeries(
        data: chartPoints,
        name: '基金收益率分布 ($indicator)',
        color: Colors.green,
        showDots: true,
        showArea: true,
        lineWidth: 2.0,
      ),
    ];
  }

  /// 获取收益率区间
  String _getReturnRange(double returnValue) {
    if (returnValue < -20) return '< -20%';
    if (returnValue < -10) return '-20% ~ -10%';
    if (returnValue < -5) return '-10% ~ -5%';
    if (returnValue < 0) return '-5% ~ 0%';
    if (returnValue < 5) return '0% ~ 5%';
    if (returnValue < 10) return '5% ~ 10%';
    if (returnValue < 20) return '10% ~ 20%';
    return '> 20%';
  }

  /// 获取基金颜色
  Color _getFundColor(String fundCode) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.cyan,
      Colors.indigo,
      Colors.pink,
    ];

    final hashCode = fundCode.hashCode;
    return colors[hashCode.abs() % colors.length];
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

  // 模拟数据方法
  List<ChartDataSeries> _getMockNavChartSeries(
      String fundCode, String indicator) {
    final now = DateTime.now();
    final chartPoints = <ChartPoint>[];

    // 生成过去一年的模拟净值数据
    for (int i = 0; i < 252; i++) {
      // 252个交易日
      final date = now.subtract(Duration(days: 251 - i));
      final baseNav = 2.0 + (i * 0.002);
      final randomChange = (i % 7 - 3) * 0.01;
      final nav = baseNav + randomChange;

      chartPoints.add(ChartPoint(
        x: i.toDouble(),
        y: nav,
        label:
            '${date.toString().substring(0, 10)}\n净值: ${nav.toStringAsFixed(4)}',
      ));
    }

    return [
      ChartDataSeries(
        data: chartPoints,
        name: '模拟基金$fundCode ($indicator)',
        color: _getFundColor(fundCode),
        showDots: false,
        showArea: indicator.contains('累计'),
        lineWidth: 2.0,
      ),
    ];
  }

  List<ChartDataSeries> _getMockComparisonChartSeries(List<String> fundCodes) {
    return fundCodes.map((fundCode) {
      return _getMockNavChartSeries(fundCode, '单位净值走势').first;
    }).toList();
  }

  List<ChartDataSeries> _getMockRankingChartSeries(int topN, String indicator) {
    final chartPoints = <ChartPoint>[];

    for (int i = 0; i < topN; i++) {
      final returnValue = 5.0 + (i * 2.5) + (i % 3 * 1.5);

      chartPoints.add(ChartPoint(
        x: i.toDouble(),
        y: returnValue,
        label: '模拟基金${i + 1}\n$indicator: ${returnValue.toStringAsFixed(2)}%',
      ));
    }

    return [
      ChartDataSeries(
        data: chartPoints,
        name: '模拟基金排行榜 ($indicator)',
        color: Colors.blue,
        showDots: true,
        showArea: false,
        lineWidth: 2.0,
      ),
    ];
  }

  List<ChartDataSeries> _getMockReturnDistributionChartSeries(
      String indicator) {
    final chartPoints = <ChartPoint>[];
    final ranges = [
      '< -10%',
      '-10% ~ -5%',
      '-5% ~ 0%',
      '0% ~ 5%',
      '5% ~ 10%',
      '> 10%'
    ];
    final counts = [5, 12, 28, 45, 32, 18];

    for (int i = 0; i < ranges.length; i++) {
      chartPoints.add(ChartPoint(
        x: i.toDouble(),
        y: counts[i].toDouble(),
        label: '${ranges[i]}\n${counts[i]}只基金',
      ));
    }

    return [
      ChartDataSeries(
        data: chartPoints,
        name: '模拟收益率分布 ($indicator)',
        color: Colors.green,
        showDots: true,
        showArea: true,
        lineWidth: 2.0,
      ),
    ];
  }

  /// 解码UTF-8编码的字段名
  Map<String, dynamic> _decodeFieldNames(Map<String, dynamic> originalMap) {
    final decodedMap = <String, dynamic>{};

    for (final entry in originalMap.entries) {
      try {
        // 解码UTF-8字段名
        final bytes = entry.key.codeUnits;
        final decodedKey = utf8.decode(bytes);
        decodedMap[decodedKey] = entry.value;
      } catch (e) {
        // 如果解码失败，保持原始键名
        decodedMap[entry.key] = entry.value;
        debugPrint('⚠️ ChartDataService 字段解码失败: ${entry.key} -> $e');
      }
    }

    return decodedMap;
  }

  /// 释放资源
  void dispose() {
    debugPrint('ChartDataService: 资源已释放');
  }
}
