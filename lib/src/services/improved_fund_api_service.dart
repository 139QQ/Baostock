import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;

/// 简单的日志工具类
class _Logger {
  static void info(String message) {
    print('INFO: $message');
  }

  static void error(String message, {Map<String, dynamic>? param}) {
    print('ERROR: $message');
    if (param != null) {
      print('ERROR PARAMS: $param');
    }
  }

  static void warn(String message) {
    print('WARNING: $message');
  }
}

/// 改进版基金数据API服务
/// 支持完整的UTF-8编码处理和时间参数
class ImprovedFundApiService {
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

  /// 获取基金排行数据（改进版）
  /// 使用与demo相同的请求方式，支持UTF-8编码
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
      ).timeout(const Duration(seconds: 120)); // 设置超时时间到120秒

      client.close();

      _Logger.info('API响应状态码: ${response.statusCode}');
      print(
          'API响应内容: ${response.body.substring(0, math.min(200, response.body.length))}...');

      if (response.statusCode == 200) {
        return _parseResponseWithEncoding(response.body);
      } else {
        _Logger.error('GET请求失败，状态码: ${response.statusCode}，尝试POST请求');
        // 如果GET失败，尝试POST请求
        return await _tryPostRequest(symbol);
      }
    } catch (e) {
      _Logger.error('网络请求异常:', param: {'error': e});
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
          .timeout(const Duration(seconds: 120));

      client.close();

      _Logger.info('POST请求状态码: ${response.statusCode}');

      if (response.statusCode == 200) {
        return _parseResponseWithEncoding(response.body);
      } else {
        throw Exception('API请求失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _Logger.error('POST请求异常:', param: {'error': e});
      throw Exception('POST请求失败: $e');
    }
  }

  /// 解析响应并处理编码问题
  static List<FundRankingData> _parseResponseWithEncoding(String responseBody) {
    try {
      _Logger.info('开始解析响应数据...');

      // 尝试多种编码方式
      String decodedBody = _fixEncoding(responseBody);

      // 如果第一次修复失败，尝试其他方法
      if (decodedBody == responseBody) {
        decodedBody = _tryMultipleEncodingFixes(responseBody);
      }

      _Logger.info('编码修复完成，开始JSON解析...');

      final dynamic responseData = jsonDecode(decodedBody);
      _Logger.info('成功解析响应数据，类型: ${responseData.runtimeType}');

      return _parseFundRankingData(responseData);
    } catch (e) {
      _Logger.error('解析响应数据失败:', param: {'error': e});
      print(
          '原始响应体前200字符: ${responseBody.substring(0, math.min(200, responseBody.length))}');
      throw Exception('解析基金数据失败: $e');
    }
  }

  /// 多重编码修复方法
  static String _tryMultipleEncodingFixes(String text) {
    if (text.isEmpty) return text;

    // 方法1：Latin1到UTF-8
    try {
      final bytes = latin1.encode(text);
      return utf8.decode(bytes);
    } catch (e) {
      _Logger.error('Latin1到UTF-8修复失败:', param: {'error': e});
    }

    // 方法2：直接解码为UTF-8
    try {
      final bytes = text.codeUnits;
      return utf8.decode(bytes, allowMalformed: true);
    } catch (e) {
      _Logger.error('直接UTF-8解码失败:', param: {'error': e});
    }

    // 方法3：处理常见的编码问题
    try {
      return text
          .replaceAll('åºå·', '序号')
          .replaceAll('åºéåä»£ç ', '基金代码')
          .replaceAll('åºéç®ç§°', '基金简称')
          .replaceAll('æ¥æ', '日期')
          .replaceAll('åä½åå¼', '单位净值')
          .replaceAll('ç´¯è®¡åå¼', '累计净值')
          .replaceAll('æ¥å¢é¿ç', '日增长率')
          .replaceAll('è¿1å¨', '近1周')
          .replaceAll('è¿1æ', '近1月')
          .replaceAll('è¿3æ', '近3月')
          .replaceAll('è¿6æ', '近6月')
          .replaceAll('è¿1å¹´', '近1年')
          .replaceAll('æç»è´¹', '手续费');
    } catch (e) {
      _Logger.error('常见编码问题修复失败:', param: {'error': e});
    }

    // 如果所有方法都失败，返回原始文本
    return text;
  }

  /// 修复字符编码问题（基础方法）
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

  /// 解析基金排行数据
  static List<FundRankingData> _parseFundRankingData(dynamic responseData) {
    try {
      List<dynamic> rawData;

      // 处理不同的数据格式
      if (responseData is List) {
        rawData = responseData;
      } else if (responseData is Map<String, dynamic>) {
        rawData = responseData['data'] ??
            responseData['result'] ??
            responseData['list'] ??
            [];
      } else {
        throw Exception('无法识别的数据格式: ${responseData.runtimeType}');
      }

      _Logger.info('API返回数据条数: ${rawData.length}');

      if (rawData.isEmpty) {
        _Logger.warn('警告: API返回空数据');
        return [];
      }

      final result = rawData.asMap().entries.map((entry) {
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

        // 打印第一个数据项的结构用于调试
        if (index == 0) {
          _Logger.info('第一个数据项的键: ${fundData.keys.toList()}');
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
              _getCurrentDate()),
          fee: _parseDouble(fundData['手续费']) ??
              _parseDouble(fundData['fee']) ??
              0.0,
        );
      }).toList();

      _Logger.info('成功解析 ${result.length} 条基金数据');

      // 打印第一条数据用于验证
      if (result.isNotEmpty) {
        _Logger.info('第一条数据示例: ${result.first}');
      }

      return result;
    } catch (e) {
      _Logger.error('解析基金数据详细错误:', param: {'error': e});
      throw Exception('解析基金数据失败: $e');
    }
  }

  /// 获取当前日期字符串
  static String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
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
      '景顺长城',
      '天弘',
      '前海开源',
      '中邮',
      '华泰柏瑞',
      '嘉合',
      '平安',
      '中融'
    ];

    for (final company in companies) {
      if (fundName.contains(company)) {
        return '$company基金';
      }
    }

    return '其他公司';
  }

  /// 解析double值
  static double? _parseDouble(dynamic value) {
    if (value == null || value == '' || value == '--') return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final cleaned = value.replaceAll('%', '').replaceAll('--', '0').trim();
      if (cleaned.isEmpty) return null;
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

/// 基金排名数据模型（与原版保持兼容）
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
    return 'FundRankingData{fundCode: $fundCode, fundName: $fundName, fundType: $fundType, company: $company, rankingPosition: $rankingPosition, unitNav: $unitNav, dailyReturn: $dailyReturn}%';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FundRankingData && other.fundCode == fundCode;
  }

  @override
  int get hashCode => fundCode.hashCode;
}
