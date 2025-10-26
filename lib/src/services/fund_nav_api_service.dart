import 'dart:convert';
import 'package:http/http.dart' as http;

/// 基金净值数据API服务
///
/// 专门用于获取收益计算引擎所需的净值数据
/// 解决累计净值字段为null的问题，使用正确的API接口
class FundNavApiService {
  static const String baseUrl = 'http://154.44.25.92:8080/api/public';

  /// 简单的日志工具
  static void _log(String message, {String? level = 'INFO'}) {
    print('[$level] FundNavApiService: $message');
  }

  /// UTF-8解码修复方法 - 解决中文字段乱码问题
  ///
  /// 通过测试发现，服务器使用UTF-8编码，但Dart的http包有时不能正确识别
  /// 需要手动进行UTF-8解码
  static String _fixUtf8Encoding(http.Response response) {
    try {
      final bytes = response.bodyBytes;
      return utf8.decode(bytes);
    } catch (e) {
      _log('UTF-8解码失败，使用原始响应体: $e', level: 'WARN');
      return response.body;
    }
  }

  /// 获取基金净值数据 - 使用正确的API接口
  ///
  /// 根据测试验证，使用以下策略：
  /// 1. 主要数据源: indicator=单位净值走势 (获取净值日期, 单位净值, 日增长率)
  /// 2. 补充数据源: indicator=累计净值走势 (获取累计净值)
  /// 3. 组合两个API的数据，确保字段完整性
  static Future<List<FundNavData>> getFundNavData({
    required String fundCode,
    int? limit,
  }) async {
    _log('开始获取基金净值数据', level: 'INFO');
    _log('基金代码: $fundCode');

    try {
      // 并行获取两个API的数据
      final futures = await Future.wait([
        _getUnitNavData(fundCode, limit),
        _getAccumulatedNavData(fundCode, limit),
      ]);

      final unitNavData = futures[0];
      final accumulatedNavData = futures[1];

      // 合并数据
      final mergedData = _mergeNavData(unitNavData, accumulatedNavData);

      _log('成功获取净值数据，记录数: ${mergedData.length}', level: 'INFO');
      return mergedData;
    } catch (e) {
      _log('获取基金净值数据失败: $e', level: 'ERROR');
      throw Exception('获取基金净值数据失败: $e');
    }
  }

  /// 获取单位净值数据 (主要数据源)
  ///
  /// API: fund_open_fund_info_em?symbol=基金代码&indicator=单位净值走势
  /// 返回字段: 净值日期, 单位净值, 日增长率 (累计净值字段为null)
  static Future<List<Map<String, dynamic>>> _getUnitNavData(
      String fundCode, int? limit) async {
    final url =
        '$baseUrl/fund_open_fund_info_em?symbol=$fundCode&indicator=单位净值走势';
    _log('获取单位净值数据: $url');

    try {
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final fixedResponse = _fixUtf8Encoding(response);
        final data = jsonDecode(fixedResponse);

        if (data is List) {
          _log('单位净值数据获取成功，记录数: ${data.length}');

          // 应用限制
          if (limit != null && data.length > limit) {
            return List<Map<String, dynamic>>.from(data
                .take(limit)
                .map((item) => Map<String, dynamic>.from(item)));
          }

          return List<Map<String, dynamic>>.from(
              data.map((item) => Map<String, dynamic>.from(item)));
        } else {
          throw Exception('单位净值数据格式错误: 期望List，实际${data.runtimeType}');
        }
      } else {
        throw Exception('单位净值API请求失败: ${response.statusCode}');
      }
    } catch (e) {
      _log('获取单位净值数据异常: $e', level: 'ERROR');
      rethrow;
    }
  }

  /// 获取累计净值数据 (补充数据源)
  ///
  /// API: fund_open_fund_info_em?symbol=基金代码&indicator=累计净值走势
  /// 返回字段: 净值日期, 累计净值
  static Future<List<Map<String, dynamic>>> _getAccumulatedNavData(
      String fundCode, int? limit) async {
    final url =
        '$baseUrl/fund_open_fund_info_em?symbol=$fundCode&indicator=累计净值走势';
    _log('获取累计净值数据: $url');

    try {
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final fixedResponse = _fixUtf8Encoding(response);
        final data = jsonDecode(fixedResponse);

        if (data is List) {
          _log('累计净值数据获取成功，记录数: ${data.length}');

          // 应用限制
          if (limit != null && data.length > limit) {
            return List<Map<String, dynamic>>.from(data
                .take(limit)
                .map((item) => Map<String, dynamic>.from(item)));
          }

          return List<Map<String, dynamic>>.from(
              data.map((item) => Map<String, dynamic>.from(item)));
        } else {
          throw Exception('累计净值数据格式错误: 期望List，实际${data.runtimeType}');
        }
      } else {
        throw Exception('累计净值API请求失败: ${response.statusCode}');
      }
    } catch (e) {
      _log('获取累计净值数据异常: $e', level: 'ERROR');
      rethrow;
    }
  }

  /// 合并两个API的净值数据
  ///
  /// 策略：
  /// 1. 以单位净值数据为基础（包含更多字段）
  /// 2. 用累计净值数据补充累计净值字段
  /// 3. 按净值日期进行匹配
  static List<FundNavData> _mergeNavData(
    List<Map<String, dynamic>> unitNavData,
    List<Map<String, dynamic>> accumulatedNavData,
  ) {
    _log('开始合并净值数据');
    _log('单位净值数据记录数: ${unitNavData.length}');
    _log('累计净值数据记录数: ${accumulatedNavData.length}');

    // 创建日期到累计净值的映射
    final Map<String, double> accumulatedNavMap = {};
    for (final item in accumulatedNavData) {
      final date = item['净值日期']?.toString();
      final accumulatedNav = _parseDouble(item['累计净值']);

      if (date != null && accumulatedNav != null) {
        accumulatedNavMap[date] = accumulatedNav;
      }
    }

    // 合并数据
    final List<FundNavData> mergedData = [];

    for (final unitNavItem in unitNavData) {
      try {
        final dateStr = unitNavItem['净值日期']?.toString() ?? '';
        final unitNav = _parseDouble(unitNavItem['单位净值']) ?? 0.0;
        final dailyReturn = _parseDouble(unitNavItem['日增长率']) ?? 0.0;

        // 从累计净值数据中获取累计净值，如果没有则使用0.0
        final accumulatedNav = accumulatedNavMap[dateStr] ?? 0.0;

        // 解析日期
        DateTime? navDate;
        try {
          navDate = DateTime.parse(dateStr);
        } catch (e) {
          _log('日期解析失败: $dateStr', level: 'WARN');
          continue;
        }

        final fundNavData = FundNavData(
          navDate: navDate,
          unitNav: unitNav,
          accumulatedNav: accumulatedNav,
          dailyReturn: dailyReturn,
        );

        mergedData.add(fundNavData);
      } catch (e) {
        _log('合并单条记录失败: $e', level: 'WARN');
        continue;
      }
    }

    // 按日期排序（最新的在前）
    mergedData.sort((a, b) => b.navDate.compareTo(a.navDate));

    _log('数据合并完成，最终记录数: ${mergedData.length}');
    return mergedData;
  }

  /// 解析double值
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final cleaned = value.replaceAll('%', '').replaceAll('--', '0').trim();
      return double.tryParse(cleaned);
    }
    return null;
  }

  /// 获取基金基本信息
  static Future<FundBasicInfo?> getFundBasicInfo(String fundCode) async {
    _log('获取基金基本信息: $fundCode');

    try {
      // 可以从单位净值数据的第一条记录获取基本信息
      final navData = await getFundNavData(fundCode: fundCode, limit: 1);

      if (navData.isNotEmpty) {
        // 这里可以扩展获取更多基金信息，如基金名称、类型等
        return FundBasicInfo(
          fundCode: fundCode,
          latestNavDate: navData.first.navDate,
          latestUnitNav: navData.first.unitNav,
          latestAccumulatedNav: navData.first.accumulatedNav,
        );
      }

      return null;
    } catch (e) {
      _log('获取基金基本信息失败: $e', level: 'ERROR');
      return null;
    }
  }

  /// 批量获取多只基金的净值数据
  static Future<Map<String, List<FundNavData>>> getBatchFundNavData(
    List<String> fundCodes, {
    int? limit,
  }) async {
    _log('批量获取基金净值数据，基金数量: ${fundCodes.length}');

    // 并行获取多只基金的数据
    final futures = fundCodes.map((fundCode) async {
      try {
        final navData = await getFundNavData(fundCode: fundCode, limit: limit);
        return MapEntry(fundCode, navData);
      } catch (e) {
        _log('获取基金 $fundCode 数据失败: $e', level: 'ERROR');
        return MapEntry(fundCode, <FundNavData>[]);
      }
    });

    final Map<String, List<FundNavData>> batchResults =
        Map.fromEntries(await Future.wait(futures));

    _log(
        '批量获取完成，成功基金数量: ${batchResults.values.where((list) => list.isNotEmpty).length}');
    return batchResults;
  }
}

/// 基金净值数据模型
class FundNavData {
  final DateTime navDate;
  final double unitNav;
  final double accumulatedNav;
  final double dailyReturn;

  const FundNavData({
    required this.navDate,
    required this.unitNav,
    required this.accumulatedNav,
    required this.dailyReturn,
  });

  /// 从JSON创建对象
  factory FundNavData.fromJson(Map<String, dynamic> json) {
    return FundNavData(
      navDate: DateTime.parse(json['navDate'] ?? json['净值日期']),
      unitNav: (json['unitNav'] ?? json['单位净值'] ?? 0).toDouble(),
      accumulatedNav: (json['accumulatedNav'] ?? json['累计净值'] ?? 0).toDouble(),
      dailyReturn: (json['dailyReturn'] ?? json['日增长率'] ?? 0).toDouble(),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'navDate': navDate.toIso8601String(),
      'unitNav': unitNav,
      'accumulatedNav': accumulatedNav,
      'dailyReturn': dailyReturn,
    };
  }

  /// 转换为中文JSON（用于API响应）
  Map<String, dynamic> toChineseJson() {
    return {
      '净值日期': navDate.toIso8601String(),
      '单位净值': unitNav,
      '累计净值': accumulatedNav,
      '日增长率': dailyReturn,
    };
  }

  /// 计算与另一条记录的收益率
  double calculateReturnRate(FundNavData other) {
    if (unitNav == 0) return 0.0;
    return (unitNav - other.unitNav) / other.unitNav;
  }

  /// 计算累计收益率
  double get cumulativeReturnRate {
    if (accumulatedNav == 0) return 0.0;
    return (accumulatedNav - 1.0) / 1.0; // 假设初始净值为1.0
  }

  @override
  String toString() {
    return 'FundNavData{date: ${navDate.toIso8601String().substring(0, 10)}, unitNav: $unitNav, accumulatedNav: $accumulatedNav, dailyReturn: ${dailyReturn.toStringAsFixed(2)}%}';
  }
}

/// 基金基本信息模型
class FundBasicInfo {
  final String fundCode;
  final DateTime latestNavDate;
  final double latestUnitNav;
  final double latestAccumulatedNav;

  const FundBasicInfo({
    required this.fundCode,
    required this.latestNavDate,
    required this.latestUnitNav,
    required this.latestAccumulatedNav,
  });

  @override
  String toString() {
    return 'FundBasicInfo{fundCode: $fundCode, latestNavDate: ${latestNavDate.toIso8601String().substring(0, 10)}, latestUnitNav: $latestUnitNav, latestAccumulatedNav: $latestAccumulatedNav}';
  }
}
