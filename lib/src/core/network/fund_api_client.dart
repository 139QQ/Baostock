import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import '../utils/logger.dart';
import '../config/app_config.dart';
// import 'multi_source_api_config.dart'; // 暂时注释掉，避免循环依赖

/// 基金API客户端 - 增强版本，支持重试和超时处理
class FundApiClient {
  // 从环境配置获取API配置
  static String get baseUrl => AppConfig.instance.apiBaseUrl;
  static Duration get connectTimeout =>
      Duration(seconds: AppConfig.instance.apiConnectTimeout);
  static Duration get receiveTimeout =>
      Duration(seconds: AppConfig.instance.apiReceiveTimeout);
  static Duration get sendTimeout =>
      Duration(seconds: AppConfig.instance.apiSendTimeout);
  static int get maxRetries => AppConfig.instance.apiMaxRetries;
  static Duration get retryDelay =>
      Duration(seconds: AppConfig.instance.apiRetryDelay);

  // Dio实例，用于更好的错误处理
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: connectTimeout,
    receiveTimeout: receiveTimeout,
    sendTimeout: sendTimeout,
    validateStatus: (status) {
      // 允许2xx状态码成功
      if (status != null && status >= 200 && status < 300) {
        return true;
      }
      // 对于4xx和5xx错误，返回false但不抛出异常
      return false;
    },
    // 强制指定UTF-8编码
    responseType: ResponseType.plain,
    contentType: 'application/json; charset=utf-8',
  ));

  // 初始化Dio拦截器
  static void _initializeDio() {
    // 暂时移除RetryInterceptor，避免依赖问题
    // TODO: 修复循环依赖后重新启用

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          AppLogger.network(
              options.method, 'http://154.44.25.92:8080${options.path}');
          handler.next(options);
        },
        onResponse: (Response response, ResponseInterceptorHandler handler) {
          AppLogger.debug('API Response',
              '${response.statusCode} - ${response.requestOptions.path}');
          handler.next(response);
        },
        onError: (DioException error, ErrorInterceptorHandler handler) {
          AppLogger.error('API Error', error.error, error.stackTrace);
          handler.next(error);
        },
      ),
    );
  }

  // 静态初始化
  static void initialize() {
    _initializeDio();
  }

  /// 公共Dio访问器（用于需要特殊处理的请求）
  static Dio get dio => _dio;

  /// 构建完整URL
  static String _buildUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }

  /// 解析响应数据，处理编码问题
  static dynamic _parseResponse(http.Response response) {
    try {
      if (response.body.isEmpty) {
        return {};
      }

      // 首先尝试直接解析JSON
      try {
        return jsonDecode(response.body);
      } catch (e) {
        // 如果直接解析失败，尝试UTF-8修复解码
        AppLogger.info('Direct JSON decode failed, trying UTF-8 fix');

        try {
          final bytes = response.bodyBytes;
          final fixedResponse = utf8.decode(bytes);
          final data = jsonDecode(fixedResponse);
          AppLogger.debug('UTF-8 fix successful');
          return data;
        } catch (utf8Error) {
          AppLogger.warn('UTF-8 fix also failed', utf8Error);
          throw Exception('响应解析失败: 原始错误=$e, UTF-8修复错误=$utf8Error');
        }
      }
    } catch (e) {
      AppLogger.warn('Response parse error', e);
      throw Exception('响应解析失败: $e');
    }
  }

  /// 处理HTTP错误响应
  static Exception _handleHttpError(http.Response response) {
    final statusCode = response.statusCode;
    final message =
        response.body.isNotEmpty ? response.body : 'HTTP错误: $statusCode';

    switch (statusCode) {
      case 400:
        return Exception('请求参数错误: $message');
      case 401:
        return Exception('未授权访问: $message');
      case 403:
        return Exception('禁止访问: $message');
      case 404:
        return Exception('资源未找到: $message');
      case 429:
        return Exception('请求频率过高: $message');
      case 500:
        return Exception('服务器内部错误: $message');
      case 502:
        return Exception('网关错误: $message');
      case 503:
        return Exception('服务不可用: $message');
      case 504:
        return Exception('网关超时: $message');
      default:
        return Exception('HTTP错误 $statusCode: $message');
    }
  }

  /// GET请求
  static Future<Map<String, dynamic>> get(String endpoint,
      {Map<String, String>? headers}) async {
    try {
      final url = _buildUrl(endpoint);
      AppLogger.network('GET', url);

      final response = await HttpRetryHelper.getWithRetry(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json; charset=utf-8',
          'Content-Type': 'application/json; charset=utf-8',
          ...?headers,
        },
        maxRetries: maxRetries,
        retryDelay: retryDelay,
      );

      if (response.statusCode == 200) {
        final data = _parseResponse(response);
        AppLogger.debug('GET Success', '$endpoint - ${data.keys.length} keys');
        return data;
      } else {
        throw _handleHttpError(response);
      }
    } catch (e) {
      AppLogger.error('GET请求失败', e);
      rethrow;
    }
  }

  /// POST请求
  static Future<Map<String, dynamic>> post(String endpoint,
      {Map<String, dynamic>? data, Map<String, String>? headers}) async {
    try {
      final url = _buildUrl(endpoint);
      AppLogger.network('POST', url);

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Accept': 'application/json; charset=utf-8',
              'Content-Type': 'application/json; charset=utf-8',
              ...?headers,
            },
            body: data != null ? jsonEncode(data) : null,
          )
          .timeout(receiveTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = _parseResponse(response);
        AppLogger.debug(
            'POST Success', '$endpoint - ${responseData.keys.length} keys');
        return responseData;
      } else {
        throw _handleHttpError(response);
      }
    } catch (e) {
      AppLogger.error('POST请求失败', e);
      rethrow;
    }
  }

  /// 获取基金排行榜数据
  static Future<Map<String, dynamic>> getFundRanking(
      {String symbol = "全部"}) async {
    try {
      final endpoint = '/api/public/fund_open_fund_rank_em?symbol=$symbol';
      return await get(endpoint);
    } catch (e) {
      AppLogger.error('获取基金排行榜失败', e);
      rethrow;
    }
  }

  /// 获取基金基本信息
  static Future<Map<String, dynamic>> getFundInfo(String fundCode) async {
    try {
      final endpoint =
          '/api/public/fund_open_fund_info_em?symbol=$fundCode&indicator=单位净值走势';
      return await get(endpoint);
    } catch (e) {
      AppLogger.error('获取基金基本信息失败', e);
      rethrow;
    }
  }

  /// 获取基金历史数据
  static Future<Map<String, dynamic>> getFundHistory(String fundCode,
      {String period = "成立来"}) async {
    try {
      final endpoint =
          '/api/public/fund_open_fund_info_em?symbol=$fundCode&indicator=累计收益率走势&period=$period';
      return await get(endpoint);
    } catch (e) {
      AppLogger.error('获取基金历史数据失败', e);
      rethrow;
    }
  }

  /// 获取基金累计净值数据
  ///
  /// 专门用于获取累计净值数据，解决累计净值字段为null的问题
  static Future<Map<String, dynamic>> getFundAccumulatedNavHistory(
      String fundCode) async {
    try {
      // 使用累计净值走势接口获取累计净值数据
      final endpoint =
          '/api/public/fund_open_fund_info_em?symbol=$fundCode&indicator=累计净值走势';
      return await get(endpoint);
    } catch (e) {
      AppLogger.error('获取基金累计净值数据失败', e);
      rethrow;
    }
  }

  /// 获取基金持仓数据
  static Future<Map<String, dynamic>> getFundPortfolio(String fundCode,
      {String? date}) async {
    try {
      final currentDate = date ?? DateTime.now().year.toString();
      final endpoint =
          '/api/public/fund_portfolio_hold_em?symbol=$fundCode&date=$currentDate';
      return await get(endpoint);
    } catch (e) {
      AppLogger.error('获取基金持仓数据失败', e);
      rethrow;
    }
  }

  /// 获取多只基金详细信息用于对比
  static Future<Map<String, dynamic>> getFundsForComparison(
      List<String> fundCodes) async {
    try {
      // 基金对比需要分别获取每只基金的信息，然后合并结果
      // 这里暂时返回第一个基金的信息，实际应用中需要合并多个基金数据
      if (fundCodes.isEmpty) {
        return {};
      }
      final firstFundCode = fundCodes.first;
      final endpoint =
          '/api/public/fund_open_fund_info_em?symbol=$firstFundCode&indicator=单位净值走势';
      return await get(endpoint);
    } catch (e) {
      AppLogger.error('获取基金对比数据失败', e);
      rethrow;
    }
  }

  /// 获取基金历史数据用于多时间段对比
  static Future<Map<String, dynamic>> getFundHistoricalData(String fundCode,
      {String period = "成立来"}) async {
    try {
      final endpoint =
          '/api/public/fund_open_fund_info_em?symbol=$fundCode&indicator=累计净值走势&period=$period';
      return await get(endpoint);
    } catch (e) {
      AppLogger.error('获取基金历史数据失败', e);
      rethrow;
    }
  }

  /// 搜索基金
  static Future<Map<String, dynamic>> searchFunds(String keyword,
      {int limit = 20}) async {
    try {
      // 基金搜索功能需要先获取所有基金列表，然后在客户端进行过滤
      // 因为API文档中没有提供专门的搜索接口
      const endpoint = '/api/public/fund_name_em';
      return await get(endpoint);
    } catch (e) {
      AppLogger.error('搜索基金失败', e);
      rethrow;
    }
  }

  /// 获取基金公司列表
  static Future<Map<String, dynamic>> getFundCompanies() async {
    try {
      const endpoint = '/api/public/fund_aum_em';
      return await get(endpoint);
    } catch (e) {
      AppLogger.error('获取基金公司列表失败', e);
      rethrow;
    }
  }

  /// 获取基金类型列表
  static Future<Map<String, dynamic>> getFundTypes() async {
    try {
      // 使用基金排行接口获取不同类型的基金
      // 该接口支持按基金类型筛选: "全部", "股票型", "混合型", "债券型", "指数型", "QDII", "FOF"
      const endpoint = '/api/public/fund_open_fund_rank_em?symbol=全部';
      return await get(endpoint);
    } catch (e) {
      AppLogger.error('获取基金类型列表失败', e);
      rethrow;
    }
  }

  /// 获取指定类型的基金列表
  static Future<Map<String, dynamic>> getFundsByType(String fundType) async {
    try {
      // 支持的类型: "全部", "股票型", "混合型", "债券型", "指数型", "QDII", "FOF"
      final endpoint = '/api/public/fund_open_fund_rank_em?symbol=$fundType';
      return await get(endpoint);
    } catch (e) {
      AppLogger.error('获取指定类型基金列表失败', e);
      rethrow;
    }
  }

  /// 获取货币型基金实时数据
  static Future<Map<String, dynamic>> getMoneyFundsDaily() async {
    try {
      const endpoint = '/api/public/fund_money_fund_daily_em';
      return await get(endpoint);
    } catch (e) {
      AppLogger.error('获取货币型基金实时数据失败', e);
      rethrow;
    }
  }

  /// 获取指数型基金信息
  static Future<Map<String, dynamic>> getIndexFunds(
      {String symbol = "全部", String indicator = "全部"}) async {
    try {
      // symbol选项: "全部", "沪深指数", "行业主题", "大盘指数", "中盘指数", "小盘指数", "股票指数", "债券指数"
      // indicator选项: "全部", "被动指数型", "增强指数型"
      final endpoint =
          '/api/public/fund_info_index_em?symbol=$symbol&indicator=$indicator';
      return await get(endpoint);
    } catch (e) {
      AppLogger.error('获取指数型基金信息失败', e);
      rethrow;
    }
  }

  /// 获取ETF基金分类信息
  static Future<Map<String, dynamic>> getEtfCategory(String symbol) async {
    try {
      // symbol选项: "封闭式基金", "ETF基金", "LOF基金"
      final endpoint = '/api/public/fund_etf_category_sina?symbol=$symbol';
      return await get(endpoint);
    } catch (e) {
      AppLogger.error('获取ETF基金分类信息失败', e);
      rethrow;
    }
  }

  /// 获取基金估值数据（按类型）
  static Future<Map<String, dynamic>> getFundValueEstimation(
      {String symbol = "全部"}) async {
    try {
      // symbol选项: '全部', '股票型', '混合型', '债券型', '指数型', 'QDII', 'ETF联接', 'LOF', '场内交易基金'
      final endpoint = '/api/public/fund_value_estimation_em?symbol=$symbol';
      return await get(endpoint);
    } catch (e) {
      AppLogger.error('获取基金估值数据失败', e);
      rethrow;
    }
  }

  /// 健康检查
  static Future<bool> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/health'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      AppLogger.warn('健康检查失败', e);
      return false;
    }
  }

  /// 判断状态码是否可重试
  static bool _isRetryableStatusCode(int statusCode) {
    final retryableStatusCodes = [408, 429, 500, 502, 503, 504];
    return retryableStatusCodes.contains(statusCode);
  }
}

/// HTTP重试辅助类
class HttpRetryHelper {
  static Future<http.Response> getWithRetry(
    Uri url, {
    Map<String, String>? headers,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
  }) async {
    Exception? lastException;

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await http
            .get(url, headers: headers)
            .timeout(const Duration(seconds: 120));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        }

        // 检查是否应该重试
        if (!FundApiClient._isRetryableStatusCode(response.statusCode)) {
          return response;
        }

        lastException =
            Exception('HTTP ${response.statusCode}: ${response.body}');
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());

        if (attempt == maxRetries) {
          break;
        }

        // 等待后重试
        await Future.delayed(retryDelay * (attempt + 1));
      }
    }

    throw lastException ?? Exception('Unknown HTTP error');
  }
}
