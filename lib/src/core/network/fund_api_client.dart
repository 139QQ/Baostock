import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import '../utils/logger.dart';

/// 基金API客户端 - 增强版本，支持重试和超时处理
class FundApiClient {
  static String baseUrl = 'http://154.44.25.92:8080';
  static Duration connectTimeout = const Duration(seconds: 15);
  static Duration receiveTimeout = const Duration(seconds: 30);
  static Duration sendTimeout = const Duration(seconds: 15);
  static int maxRetries = 3;
  static Duration retryDelay = const Duration(seconds: 1);

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
    _dio.interceptors.add(
      // 添加重试拦截器
      RetryInterceptor(
        dio: _dio,
        options: RetryOptions(
          retries: maxRetries,
          retryInterval: retryDelay,
        ),
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          AppLogger.network(
              options.method, 'http://154.44.25.92:8080${options.path}');
          handler.next(options);
        },
        onResponse: (Response response, ResponseInterceptorHandler handler) {
          AppLogger.network('RESPONSE', response.requestOptions.path,
              statusCode: response.statusCode);

          // 检查响应头的Content-Type
          final contentTypeList = response.headers['content-type'];
          if (contentTypeList != null && contentTypeList.isNotEmpty) {
            final contentType = contentTypeList.first;
            AppLogger.debug('Content-Type响应头: $contentType', 'API');

            // 检查编码信息
            if (contentType.toLowerCase().contains('charset')) {
              AppLogger.debug('服务器编码: $contentType', 'API');
            } else {
              AppLogger.warn('服务器未指定编码，可能使用默认编码');
            }
          } else {
            AppLogger.warn('服务器未返回Content-Type响应头');
          }

          handler.next(response);
        },
        onError: (DioException error, ErrorInterceptorHandler handler) async {
          AppLogger.network('ERROR', error.requestOptions.path,
              responseData: error.message);
          if (error.response != null) {
            AppLogger.error(
                'API错误响应: ${error.response?.statusCode}, Data: ${error.response?.data}',
                error.toString(),
                error.stackTrace);
          }

          // 500错误处理
          if (error.response?.statusCode == 500) {
            // 直接处理500错误，不重试
            handler.resolve(Response(
              requestOptions: error.requestOptions,
              statusCode: 500,
              data: [],
            ));
            return;
          }
          handler.next(error);
        },
      ),
    );
  }

  /// 获取基金基本信息列表
  Future<List<dynamic>> getFundList() async {
    try {
      final response = await HttpRetryHelper.getWithRetry(
        Uri.parse('$baseUrl/api/public/fund_name_em'),
        headers: {
          'Accept': 'application/json; charset=utf-8',
          'Content-Type': 'application/json; charset=utf-8',
        },
        maxRetries: maxRetries,
        retryDelay: retryDelay,
      );

      if (response.statusCode == 200) {
        // 手动处理UTF-8编码解析
        final String responseData = response.body;
        AppLogger.debug('FundList响应数据: ${responseData.length}字符', 'API');

        // 强制使用UTF-8解码
        final List<dynamic> decodedData = json.decode(responseData);
        AppLogger.business('FundList数据解析成功: ${decodedData.length}条', 'API');

        return decodedData;
      } else {
        throw Exception('获取基金列表失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('获取基金列表错误: $e');
    }
  }

  /// 获取基金排行 - 使用http包进行真正的UTF-8解码，增强错误处理和重试机制
  Future<List<dynamic>> getFundRankings(
      {String symbol = '全部', bool forceRefresh = false}) async {
    AppLogger.business('开始获取基金排行榜${forceRefresh ? '(强制刷新)' : ''}', 'API');
    AppLogger.debug('请求参数: symbol=$symbol', 'API');

    // 使用智能重试机制获取数据
    return await _getFundRankingsWithRetry(symbol,
        maxRetries: 3, forceRefresh: forceRefresh);
  }

  /// 带智能重试机制的基金排行榜获取
  Future<List<dynamic>> _getFundRankingsWithRetry(String symbol,
      {int maxRetries = 3, bool forceRefresh = false}) async {
    int retryCount = 0;
    dynamic lastException;

    while (retryCount <= maxRetries) {
      try {
        AppLogger.business(
            '获取基金排行榜 (尝试 ${retryCount + 1}/${maxRetries + 1}): symbol=$symbol',
            'API');

        // 构建正确的API端点 - 使用Uri自动处理编码，避免双重编码
        final uri = Uri.parse('$baseUrl/api/public/fund_open_fund_rank_em')
            .replace(queryParameters: {'symbol': symbol});

        // 添加CORS相关请求头和强制刷新标识
        final headers = {
          'Accept': 'application/json; charset=utf-8',
          'Content-Type': 'application/json; charset=utf-8',
          'Origin': 'http://localhost:5000', // 前端域名，根据实际环境配置
          'Access-Control-Request-Method': 'GET',
          'Access-Control-Request-Headers': 'Content-Type,Accept',
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        };

        // 如果是强制刷新，添加缓存控制头
        if (forceRefresh) {
          headers['Cache-Control'] = 'no-cache';
          headers['Pragma'] = 'no-cache';
        }

        final response = await http
            .get(
              uri,
              headers: headers,
            )
            .timeout(const Duration(seconds: 60)); // 60秒超时配置

        AppLogger.debug('响应状态码: ${response.statusCode}', 'API');
        AppLogger.debug('响应头: ${response.headers}', 'API');

        if (response.statusCode == 200) {
          AppLogger.debug('响应数据长度: ${response.bodyBytes.length}字节', 'API');

          // 检查响应内容类型
          final contentType = response.headers['content-type'] ?? '';
          if (contentType.isNotEmpty &&
              !contentType.toLowerCase().contains('json')) {
            AppLogger.warn('服务器返回非JSON内容: $contentType', 'API');
          }

          // 强制用UTF-8解码原始字节数据，解决中文乱码问题
          final String responseData = utf8.decode(response.bodyBytes);
          AppLogger.debug('UTF-8解码完成，数据长度: ${responseData.length}字符', 'API');

          // 检查返回的数据是否为空
          if (responseData.trim().isEmpty) {
            AppLogger.warn('服务器返回空数据', 'API');
            return [];
          }

          final List<dynamic> decodedData = json.decode(responseData);
          AppLogger.business('数据解码成功: ${decodedData.length}条', 'API');

          return decodedData;
        } else if (response.statusCode == 500) {
          AppLogger.warn('服务器返回500错误，返回空数据');
          return [];
        } else if (response.statusCode == 400) {
          final String responseData = utf8.decode(response.bodyBytes);
          AppLogger.error('请求参数错误 (400): $responseData', 'API');
          throw ArgumentError('请求参数错误: $responseData');
        } else if (response.statusCode == 403) {
          AppLogger.error('访问被拒绝 (403)，可能是CORS或权限问题', 'API');
          throw Exception('访问被拒绝，请检查CORS配置或联系管理员');
        } else if (response.statusCode == 404) {
          AppLogger.error('API端点不存在 (404)', 'API');
          throw Exception('请求的API端点不存在');
        } else {
          final String responseData = response.body.isNotEmpty
              ? utf8.decode(response.bodyBytes)
              : '无响应内容';
          AppLogger.error(
              'HTTP错误 ${response.statusCode}: $responseData', 'API');
          throw HttpException('HTTP ${response.statusCode}: $responseData',
              statusCode: response.statusCode, response: responseData);
        }
      } catch (e) {
        lastException = e;
        retryCount++;

        // 记录详细错误信息
        AppLogger.warn('排行榜获取失败 (尝试 $retryCount): ${e.toString()}');

        // 如果还有重试机会，等待后重试
        if (retryCount <= maxRetries) {
          // 指数退避等待时间：1秒、2秒、4秒
          final waitTime = Duration(seconds: (1 << (retryCount - 1)));
          AppLogger.business('等待 ${waitTime.inSeconds}秒后重试', 'API');
          await Future.delayed(waitTime);
        }
      }
    }

    // 所有重试都失败了
    AppLogger.error('排行榜获取失败，已达最大重试次数', lastException.toString());
    throw lastException ?? Exception('获取基金排行榜失败');
  }

  /// 获取基金实时行情
  Future<List<dynamic>> getFundDaily() async {
    try {
      final response = await HttpRetryHelper.getWithRetry(
        Uri.parse('$baseUrl/api/public/fund_open_fund_daily_em'),
        headers: {
          'Accept': 'application/json; charset=utf-8',
          'Content-Type': 'application/json; charset=utf-8',
        },
        maxRetries: maxRetries,
        retryDelay: retryDelay,
      );

      if (response.statusCode == 200) {
        // 手动处理UTF-8编码解析
        final String responseData = response.body;
        AppLogger.debug('FundDaily响应数据: ${responseData.length}字符', 'API');

        // 强制使用UTF-8解码
        final List<dynamic> decodedData = json.decode(responseData);
        AppLogger.business('FundDaily数据解析成功: ${decodedData.length}条', 'API');

        return decodedData;
      } else {
        throw Exception('获取基金实时行情失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('获取基金实时行情错误: $e');
    }
  }

  /// 获取ETF实时行情
  Future<List<dynamic>> getEtfSpot() async {
    try {
      final response = await HttpRetryHelper.getWithRetry(
        Uri.parse('$baseUrl/api/public/fund_etf_spot_em'),
        headers: {
          'Accept': 'application/json; charset=utf-8',
          'Content-Type': 'application/json; charset=utf-8',
        },
        maxRetries: maxRetries,
        retryDelay: retryDelay,
      );

      if (response.statusCode == 200) {
        // 手动处理UTF-8编码解析
        final String responseData = response.body;
        AppLogger.debug('EtfSpot响应数据: ${responseData.length}字符', 'API');

        // 强制使用UTF-8解码
        final List<dynamic> decodedData = json.decode(responseData);
        AppLogger.business('EtfSpot数据解析成功: ${decodedData.length}条', 'API');

        return decodedData;
      } else {
        throw Exception('获取ETF实时行情失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('获取ETF实时行情错误: $e');
    }
  }

  /// 获取基金申购状态
  Future<List<dynamic>> getFundPurchaseStatus() async {
    try {
      final response = await HttpRetryHelper.getWithRetry(
        Uri.parse('$baseUrl/api/public/fund_purchase_em'),
        headers: {
          'Accept': 'application/json; charset=utf-8',
          'Content-Type': 'application/json; charset=utf-8',
        },
        maxRetries: maxRetries,
        retryDelay: retryDelay,
      );

      if (response.statusCode == 200) {
        // 手动处理UTF-8编码解析
        final String responseData = response.body;
        AppLogger.debug('FundPurchase响应数据: ${responseData.length}字符', 'API');

        // 强制使用UTF-8解码
        final List<dynamic> decodedData = json.decode(responseData);
        AppLogger.business('FundPurchase数据解析成功: ${decodedData.length}条', 'API');

        return decodedData;
      } else {
        throw Exception('获取基金申购状态失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('获取基金申购状态错误: $e');
    }
  }

  /// 获取基金经理信息
  Future<List<dynamic>> getFundManagers() async {
    try {
      final response = await HttpRetryHelper.getWithRetry(
        Uri.parse('$baseUrl/api/public/fund_manager_em'),
        headers: {
          'Accept': 'application/json; charset=utf-8',
          'Content-Type': 'application/json; charset=utf-8',
        },
        maxRetries: maxRetries,
        retryDelay: retryDelay,
      );

      if (response.statusCode == 200) {
        // 手动处理UTF-8编码解析
        final String responseData = response.body;
        AppLogger.debug('FundManagers响应数据: ${responseData.length}字符', 'API');

        // 强制使用UTF-8解码
        final List<dynamic> decodedData = json.decode(responseData);
        AppLogger.business('FundManagers数据解析成功: ${decodedData.length}条', 'API');

        return decodedData;
      } else {
        throw Exception('获取基金经理信息失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('获取基金经理信息错误: $e');
    }
  }
}

/// 重试配置选项
class RetryOptions {
  final int retries;
  final Duration retryInterval;
  final List<int>? retryableStatusCodes;

  RetryOptions({
    required this.retries,
    required this.retryInterval,
    this.retryableStatusCodes,
  });
}

/// 重试拦截器
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final RetryOptions options;

  RetryInterceptor({
    required this.dio,
    required this.options,
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final extra = err.requestOptions.extra;
    final retryCount = extra['retryCount'] ?? 0;

    // 检查是否应该重试
    if (_shouldRetry(err, retryCount)) {
      AppLogger.warn('网络请求失败，准备第${retryCount + 1}次重试', 'RetryInterceptor');

      // 增加重试计数
      extra['retryCount'] = retryCount + 1;

      // 等待重试间隔
      await Future.delayed(options.retryInterval);

      try {
        // 克隆请求选项
        final cloneReq = err.requestOptions;

        // 重新发起请求
        final response = await dio.fetch(cloneReq);

        AppLogger.business('重试成功', 'RetryInterceptor');
        handler.resolve(response);
        return;
      } catch (e) {
        AppLogger.error('重试失败: ${e.toString()}', e, null);
      }
    }

    // 如果不重试或重试次数用尽，继续错误处理
    handler.next(err);
  }

  /// 判断是否应该重试
  bool _shouldRetry(DioException err, int retryCount) {
    // 超过最大重试次数
    if (retryCount >= options.retries) {
      return false;
    }

    // 检查错误类型
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return true;
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        // 检查状态码是否可重试
        final statusCode = err.response?.statusCode;
        if (statusCode != null) {
          // 默认可重试的状态码
          final defaultRetryableCodes = [408, 429, 500, 502, 503, 504];
          final retryableCodes =
              options.retryableStatusCodes ?? defaultRetryableCodes;
          return retryableCodes.contains(statusCode);
        }
        return false;
      default:
        return false;
    }
  }
}

/// 自定义HTTP异常类
class HttpException implements Exception {
  final String message;
  final int? statusCode;
  final String? response;

  HttpException(this.message, {this.statusCode, this.response});

  @override
  String toString() =>
      'HttpException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

/// 带重试机制的HTTP请求方法
class HttpRetryHelper {
  /// 带重试的GET请求
  static Future<http.Response> getWithRetry(
    Uri url, {
    Map<String, String>? headers,
    Duration? timeout,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
  }) async {
    int retryCount = 0;
    dynamic lastException;

    while (retryCount <= maxRetries) {
      try {
        final response = await http
            .get(
              url,
              headers: headers,
            )
            .timeout(timeout ?? const Duration(seconds: 25));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        } else if (_isRetryableStatusCode(response.statusCode)) {
          throw http.ClientException('HTTP ${response.statusCode}');
        } else {
          return response; // 非可重试状态码，直接返回
        }
      } catch (e) {
        lastException = e;
        retryCount++;

        if (retryCount <= maxRetries) {
          AppLogger.warn(
              'HTTP请求失败，第$retryCount次重试: ${e.toString()}', 'HttpRetryHelper');
          await Future.delayed(retryDelay);
        }
      }
    }

    AppLogger.error('HTTP请求重试失败，已达最大重试次数: ${lastException.toString()}',
        lastException, null);
    throw lastException ?? Exception('Unknown HTTP error');
  }

  /// 判断状态码是否可重试
  static bool _isRetryableStatusCode(int statusCode) {
    final retryableStatusCodes = [408, 429, 500, 502, 503, 504];
    return retryableStatusCodes.contains(statusCode);
  }
}
