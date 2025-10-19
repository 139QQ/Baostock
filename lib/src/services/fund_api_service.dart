import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;

/// 基金数据API服务
class FundApiService {
  static const String baseUrl = 'http://154.44.25.92:8080';

  /// 基金类型映射
  static const Map<String, String> fundTypeMap = {
    '全部': 'all',
    '股票型': 'equity',
    '混合型': 'hybrid',
    '债券型': 'bond',
    '指数型': 'index',
    'QDII': 'qdii',
    'FOF': 'fof',
  };

  /// 获取基金排行数据
  static Future<List<FundRankingData>> getFundRanking({
    String symbol = '全部',
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/public/fund_open_fund_rank_em');

      // 创建HTTP客户端，配置更长的超时时间和重试
      final client = http.Client();

      // 根据API文档尝试GET请求，参数通过查询字符串传递
      final response = await client.get(
        url.replace(queryParameters: {
          'symbol': symbol,
        }),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
          'Accept-Charset': 'utf-8',
          'User-Agent': 'Flutter-App/1.0',
          'Connection': 'keep-alive',
        },
      ).timeout(const Duration(seconds: 60)); // 增加超时时间到60秒

      client.close();

      AppLogger.info('API响应状态码', {'statusCode': response.statusCode});
      AppLogger.debug('API响应内容预览', {
        'content':
            response.body.substring(0, math.min(200, response.body.length))
      });

      if (response.statusCode == 200) {
        // 确保响应体使用UTF-8编码
        String responseBody;
        try {
          responseBody = utf8.decode(response.body.codeUnits);
        } catch (e) {
          AppLogger.warn('UTF-8解码失败，使用原始响应体', {'error': e.toString()});
          responseBody = response.body;
        }

        final dynamic responseData = jsonDecode(responseBody);
        AppLogger.debug(
            '成功解析响应数据', {'type': responseData.runtimeType.toString()});
        return _parseFundRankingData(responseData);
      } else {
        AppLogger.info('GET请求失败，尝试POST请求', {'statusCode': response.statusCode});
        // 如果GET失败，尝试POST请求
        return await _tryPostRequest(symbol);
      }
    } catch (e) {
      AppLogger.error('网络请求异常', {'error': e.toString()});
      throw Exception('获取基金数据失败: $e');
    }
  }

  /// 尝试POST请求
  static Future<List<FundRankingData>> _tryPostRequest(String symbol) async {
    try {
      final url = Uri.parse('$baseUrl/api/public/fund_open_fund_rank_em');
      final client = http.Client();

      final response = await client
          .post(
            url,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json; charset=utf-8',
              'Accept-Charset': 'utf-8',
              'User-Agent': 'Flutter-App/1.0',
              'Connection': 'keep-alive',
            },
            body: jsonEncode({
              'symbol': symbol,
            }),
          )
          .timeout(const Duration(seconds: 60));

      client.close();

      print('POST请求状态码: ${response.statusCode}');

      if (response.statusCode == 200) {
        // 确保响应体使用UTF-8编码
        String responseBody;
        try {
          responseBody = utf8.decode(response.body.codeUnits);
        } catch (e) {
          print('POST请求UTF-8解码失败，使用原始响应体: $e');
          responseBody = response.body;
        }

        final dynamic responseData = jsonDecode(responseBody);
        print('POST请求成功，解析数据');
        return _parseFundRankingData(responseData);
      } else {
        throw Exception('API请求失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('POST请求异常: $e');
      throw Exception('POST请求失败: $e');
    }
  }

  /// 解析基金排行数据
  static List<FundRankingData> _parseFundRankingData(dynamic responseData) {
    try {
      List<dynamic> rawData;

      // 处理不同的数据格式
      if (responseData is List) {
        rawData = responseData;
      } else if (responseData is Map<String, dynamic>) {
        rawData = responseData['data'] ?? responseData['result'] ?? [];
      } else {
        throw Exception('无法识别的数据格式: ${responseData.runtimeType}');
      }

      print('API返回数据条数: ${rawData.length}');

      return rawData.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;

        // 如果item已经是Map<String, dynamic>，直接使用；否则转换
        Map<String, dynamic> fundData;
        if (item is Map<String, dynamic>) {
          fundData = item;
        } else if (item is Map) {
          fundData = Map<String, dynamic>.from(item);
        } else {
          throw Exception('基金数据格式错误: ${item.runtimeType}');
        }

        return FundRankingData(
          fundCode: _fixEncoding(fundData['基金代码']?.toString() ??
              fundData['fundCode']?.toString() ??
              ''),
          fundName: _fixEncoding(fundData['基金简称']?.toString() ??
              fundData['fundName']?.toString() ??
              ''),
          fundType: _extractFundType(_fixEncoding(
              fundData['基金简称']?.toString() ??
                  fundData['fundName']?.toString() ??
                  '')),
          company: _extractCompany(_fixEncoding(fundData['基金简称']?.toString() ??
              fundData['fundName']?.toString() ??
              '')),
          rankingPosition: index + 1,
          unitNav: _parseDouble(fundData['单位净值']) ??
              _parseDouble(fundData['unitNav']) ??
              0.0,
          accumulatedNav: _parseDouble(fundData['累计净值']) ??
              _parseDouble(fundData['accumulatedNav']) ??
              0.0,
          dailyReturn: _parseDouble(fundData['日增长率']) ??
              _parseDouble(fundData['dailyReturn']) ??
              0.0,
          return1W: _parseDouble(fundData['近1周']) ??
              _parseDouble(fundData['return1W']) ??
              0.0,
          return1M: _parseDouble(fundData['近1月']) ??
              _parseDouble(fundData['return1M']) ??
              0.0,
          return3M: _parseDouble(fundData['近3月']) ??
              _parseDouble(fundData['return3M']) ??
              0.0,
          return6M: _parseDouble(fundData['近6月']) ??
              _parseDouble(fundData['return6M']) ??
              0.0,
          return1Y: _parseDouble(fundData['近1年']) ??
              _parseDouble(fundData['return1Y']) ??
              0.0,
          date: _fixEncoding(fundData['日期']?.toString() ??
              fundData['date']?.toString() ??
              DateTime.now().toIso8601String().substring(0, 10)),
          fee: _parseDouble(fundData['手续费']) ??
              _parseDouble(fundData['fee']) ??
              0.0,
        );
      }).toList();
    } catch (e) {
      throw Exception('解析基金数据失败: $e');
    }
  }

  /// 从基金名称中提取基金类型
  static String _extractFundType(String fundName) {
    if (fundName.contains('股票')) return '股票型';
    if (fundName.contains('混合')) return '混合型';
    if (fundName.contains('债券')) return '债券型';
    if (fundName.contains('指数')) return '指数型';
    if (fundName.contains('QDII')) return 'QDII';
    if (fundName.contains('FOF')) return 'FOF';
    return '其他';
  }

  /// 从基金名称中提取基金公司
  static String _extractCompany(String fundName) {
    // 常见基金公司名称提取
    final companies = [
      '易方达',
      '华夏',
      '南方',
      '嘉实',
      '博时',
      '广发',
      '汇添富',
      '富国',
      '招商',
      '中银',
      '工银瑞信',
      '建信',
      '银华',
      '交银施罗德',
      '华安',
      '国泰',
      '鹏华',
      '兴全',
      '中欧',
      '上投摩根',
      '华宝',
      '景顺长城'
    ];

    for (final company in companies) {
      if (fundName.contains(company)) {
        return company + '基金';
      }
    }

    return '其他公司';
  }

  /// 修复字符编码问题
  static String _fixEncoding(String text) {
    if (text.isEmpty) return text;

    try {
      // 尝试修复常见的UTF-8编码问题
      final bytes = latin1.encode(text);
      return utf8.decode(bytes);
    } catch (e) {
      // 如果修复失败，返回原始文本
      return text;
    }
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

  /// 获取基金排行榜（带缓存）
  static Future<List<FundRankingData>> getFundRankingWithCache({
    String symbol = '全部',
    Duration cacheTimeout = const Duration(minutes: 5),
  }) async {
    // 这里可以实现缓存逻辑
    // 暂时直接调用API
    return getFundRanking(symbol: symbol);
  }
}

/// 基金排名数据模型
class FundRankingData {
  final String fundCode;
  final String fundName;
  final String fundType;
  final String company;
  final int rankingPosition;
  final double unitNav;
  final double accumulatedNav;
  final double dailyReturn;
  final double return1W;
  final double return1M;
  final double return3M;
  final double return6M;
  final double return1Y;
  final String date;
  final double fee;

  FundRankingData({
    required this.fundCode,
    required this.fundName,
    required this.fundType,
    required this.company,
    required this.rankingPosition,
    required this.unitNav,
    required this.accumulatedNav,
    required this.dailyReturn,
    required this.return1W,
    required this.return1M,
    required this.return3M,
    required this.return6M,
    required this.return1Y,
    required this.date,
    required this.fee,
  });

  /// 从JSON创建对象
  factory FundRankingData.fromJson(Map<String, dynamic> json) {
    return FundRankingData(
      fundCode: json['fundCode'] ?? '',
      fundName: json['fundName'] ?? '',
      fundType: json['fundType'] ?? '',
      company: json['company'] ?? '',
      rankingPosition: json['rankingPosition'] ?? 0,
      unitNav: (json['unitNav'] ?? 0).toDouble(),
      accumulatedNav: (json['accumulatedNav'] ?? 0).toDouble(),
      dailyReturn: (json['dailyReturn'] ?? 0).toDouble(),
      return1W: (json['return1W'] ?? 0).toDouble(),
      return1M: (json['return1M'] ?? 0).toDouble(),
      return3M: (json['return3M'] ?? 0).toDouble(),
      return6M: (json['return6M'] ?? 0).toDouble(),
      return1Y: (json['return1Y'] ?? 0).toDouble(),
      date: json['date'] ?? '',
      fee: (json['fee'] ?? 0).toDouble(),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'fundCode': fundCode,
      'fundName': fundName,
      'fundType': fundType,
      'company': company,
      'rankingPosition': rankingPosition,
      'unitNav': unitNav,
      'accumulatedNav': accumulatedNav,
      'dailyReturn': dailyReturn,
      'return1W': return1W,
      'return1M': return1M,
      'return3M': return3M,
      'return6M': return6M,
      'return1Y': return1Y,
      'date': date,
      'fee': fee,
    };
  }

  /// 复制对象并更新部分字段
  FundRankingData copyWith({
    String? fundCode,
    String? fundName,
    String? fundType,
    String? company,
    int? rankingPosition,
    double? unitNav,
    double? accumulatedNav,
    double? dailyReturn,
    double? return1W,
    double? return1M,
    double? return3M,
    double? return6M,
    double? return1Y,
    String? date,
    double? fee,
  }) {
    return FundRankingData(
      fundCode: fundCode ?? this.fundCode,
      fundName: fundName ?? this.fundName,
      fundType: fundType ?? this.fundType,
      company: company ?? this.company,
      rankingPosition: rankingPosition ?? this.rankingPosition,
      unitNav: unitNav ?? this.unitNav,
      accumulatedNav: accumulatedNav ?? this.accumulatedNav,
      dailyReturn: dailyReturn ?? this.dailyReturn,
      return1W: return1W ?? this.return1W,
      return1M: return1M ?? this.return1M,
      return3M: return3M ?? this.return3M,
      return6M: return6M ?? this.return6M,
      return1Y: return1Y ?? this.return1Y,
      date: date ?? this.date,
      fee: fee ?? this.fee,
    );
  }

  @override
  String toString() {
    return 'FundRankingData{fundCode: $fundCode, fundName: $fundName, fundType: $fundType, rankingPosition: $rankingPosition}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FundRankingData && other.fundCode == fundCode;
  }

  @override
  int get hashCode => fundCode.hashCode;
}
