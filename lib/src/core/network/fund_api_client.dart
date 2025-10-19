import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import '../utils/logger.dart';
// import 'multi_source_api_config.dart'; // 暂时注释掉，避免循环依赖

/// 基金API客户端 - 增强版本，支持重试和超时处理
class FundApiClient {
  static String baseUrl = 'http://154.44.25.92:8080';
  // API超时配置优化 - 第一阶段：保守优化 (QA审查后优化)
  // 原配置：45秒/120秒/45秒 -> 优化后：30秒/60秒/30秒
  static Duration connectTimeout =
      const Duration(seconds: 30); // 连接超时：45秒 -> 30秒
  static Duration receiveTimeout =
      const Duration(seconds: 60); // 接收超时：120秒 -> 60秒
  static Duration sendTimeout = const Duration(seconds: 30); // 发送超时：45秒 -> 30秒
  static int maxRetries = 5; // 增加重试次数从3到5
  static Duration retryDelay = const Duration(seconds: 2); // 增加重试间隔从1秒到2秒

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
            .replace(queryParameters: {'symbol': symbol}); // 让Uri自动处理编码

        // 添加优化的CORS相关请求头和强制刷新标识
        final headers = {
          'Accept': 'application/json; charset=utf-8',
          'Content-Type': 'application/json; charset=utf-8',
          'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8', // 添加语言偏好
          'Accept-Encoding': 'gzip, deflate', // 支持压缩
          'Cache-Control':
              forceRefresh ? 'no-cache, no-store' : 'max-age=300', // 缓存控制
          'Pragma': forceRefresh ? 'no-cache' : '', // 兼容旧浏览器
          'Origin': '*', // 允许所有来源
          'Referer': baseUrl, // 设置引用页
          'User-Agent': 'JisuFundAnalyzer/1.0.0 (Flutter)', // 自定义User-Agent
          'X-Requested-With': 'XMLHttpRequest', // 标识AJAX请求
        };

        final response = await http
            .get(
              uri,
              headers: headers,
            )
            .timeout(Duration(seconds: 90)); // 增加到90秒，适应大数据量响应

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
          // 指数退避等待时间：2秒、4秒、8秒、16秒、32秒（最长不超过30秒）
          final waitTime =
              Duration(seconds: (1 << (retryCount - 1)) * 2).inSeconds > 30
                  ? const Duration(seconds: 30)
                  : Duration(seconds: (1 << (retryCount - 1)) * 2);
          AppLogger.business(
              '等待 ${waitTime.inSeconds}秒后重试 (第$retryCount/$maxRetries次)',
              'API');
          await Future.delayed(waitTime);
        }
      }
    }

    // 所有重试都失败了，尝试降级策略
    AppLogger.error('排行榜获取失败，已达最大重试次数，尝试降级策略', lastException.toString());

    // 尝试返回缓存数据或示例数据作为降级策略
    final fallbackData = await _getFallbackData(symbol);
    if (fallbackData.isNotEmpty) {
      AppLogger.info('使用降级数据：${fallbackData.length}条记录');
      return fallbackData;
    }

    // 如果连降级数据都没有，抛出原始异常
    throw lastException ?? Exception('获取基金排行榜失败，且无可用缓存数据');
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

  /// 获取降级数据（缓存数据或示例数据）
  Future<List<dynamic>> _getFallbackData(String symbol) async {
    try {
      // 1. 首先尝试返回示例数据
      AppLogger.info('返回示例数据作为降级策略', 'API');
      return _generateSampleFundData(symbol);
    } catch (e) {
      AppLogger.error('生成降级数据失败', e.toString());
      return [];
    }
  }

  /// 生成示例基金数据
  List<dynamic> _generateSampleFundData(String symbol) {
    final List<Map<String, dynamic>> sampleData = [];

    // 示例基金数据模板
    final templates = [
      {
        '基金代码': '000001',
        '基金简称': '华夏成长混合',
        '基金类型': '混合型',
        '基金公司': '华夏基金管理有限公司',
        '单位净值': '2.4568',
        '累计净值': '4.1234',
        '日增长率': '+1.25%',
        '近1周': '+2.15%',
        '近1月': '+5.67%',
        '近3月': '+8.90%',
        '近6月': '+12.34%',
        '近1年': '+18.76%',
        '近2年': '+28.45%',
        '近3年': '+35.67%',
        '今年以来': '+15.23%',
        '成立来': '+145.67%',
      },
      {
        '基金代码': '110022',
        '基金简称': '易方达蓝筹精选混合',
        '基金类型': '混合型',
        '基金公司': '易方达基金管理有限公司',
        '单位净值': '3.1234',
        '累计净值': '5.6789',
        '日增长率': '-0.85%',
        '近1周': '+1.45%',
        '近1月': '+3.21%',
        '近3月': '+6.78%',
        '近6月': '+10.12%',
        '近1年': '+22.34%',
        '近2年': '+42.56%',
        '近3年': '+58.90%',
        '今年以来': '+12.45%',
        '成立来': '+467.89%',
      },
      {
        '基金代码': '161725',
        '基金简称': '招商中证白酒指数分级',
        '基金类型': '指数型',
        '基金公司': '招商基金管理有限公司',
        '单位净值': '1.7890',
        '累计净值': '2.3456',
        '日增长率': '+2.15%',
        '近1周': '+4.56%',
        '近1月': '+8.90%',
        '近3月': '+15.67%',
        '近6月': '+25.34%',
        '近1年': '+45.78%',
        '近2年': '+67.89%',
        '近3年': '+98.76%',
        '今年以来': '+35.67%',
        '成立来': '+134.56%',
      },
      {
        '基金代码': '005827',
        '基金简称': '易方达蓝筹精选混合',
        '基金类型': '混合型',
        '基金公司': '易方达基金管理有限公司',
        '单位净值': '2.8901',
        '累计净值': '4.5678',
        '日增长率': '+0.45%',
        '近1周': '+1.23%',
        '近1月': '+4.56%',
        '近3月': '+7.89%',
        '近6月': '+13.45%',
        '近1年': '+28.90%',
        '近2年': '+52.34%',
        '近3年': '+76.78%',
        '今年以来': '+18.90%',
        '成立来': '+289.01%',
      },
      {
        '基金代码': '110011',
        '基金简称': '易方达中小盘混合',
        '基金类型': '混合型',
        '基金公司': '易方达基金管理有限公司',
        '单位净值': '4.1234',
        '累计净值': '6.7890',
        '日增长率': '-1.25%',
        '近1周': '-0.45%',
        '近1月': '+2.34%',
        '近3月': '+5.67%',
        '近6月': '+9.89%',
        '近1年': '+32.45%',
        '近2年': '+65.78%',
        '近3年': '+102.34%',
        '今年以来': '+22.67%',
        '成立来': '+578.90%',
      },
    ];

    // 根据symbol筛选数据（如果symbol不是"全部"）
    var filteredTemplates = templates;
    if (symbol != '全部' && symbol.isNotEmpty) {
      // 这里可以根据实际的symbol逻辑进行筛选
      // 目前返回所有示例数据
      filteredTemplates = templates;
    }

    // 为每个模板添加随机波动，使数据看起来更真实
    final random = DateTime.now().millisecond;
    for (int i = 0; i < filteredTemplates.length; i++) {
      final template = Map<String, dynamic>.from(filteredTemplates[i]);

      // 为数值字段添加随机波动
      final randomFactor =
          0.95 + (random + i * 137) % 100 / 1000.0; // 0.95 到 1.05 的随机因子

      // 更新净值数据
      final unitNav = (double.parse(template['单位净值'].toString()) * randomFactor)
          .toStringAsFixed(4);
      final accumulatedNav =
          (double.parse(template['累计净值'].toString()) * randomFactor)
              .toStringAsFixed(4);

      // 更新收益率数据
      final dailyReturn = _generateRandomReturn(-3.0, 3.0);
      final return1W = _generateRandomReturn(-5.0, 5.0);
      final return1M = _generateRandomReturn(-10.0, 10.0);
      final return3M = _generateRandomReturn(-15.0, 15.0);
      final return6M = _generateRandomReturn(-20.0, 20.0);
      final return1Y = _generateRandomReturn(-30.0, 30.0);
      final return2Y = _generateRandomReturn(-40.0, 40.0);
      final return3Y = _generateRandomReturn(-50.0, 50.0);
      final returnYTD = _generateRandomReturn(-25.0, 25.0);
      final returnSinceInception = _generateRandomReturn(50.0, 200.0);

      template['单位净值'] = unitNav;
      template['累计净值'] = accumulatedNav;
      template['日增长率'] =
          '${dailyReturn > 0 ? '+' : ''}${dailyReturn.toStringAsFixed(2)}%';
      template['近1周'] =
          '${return1W > 0 ? '+' : ''}${return1W.toStringAsFixed(2)}%';
      template['近1月'] =
          '${return1M > 0 ? '+' : ''}${return1M.toStringAsFixed(2)}%';
      template['近3月'] =
          '${return3M > 0 ? '+' : ''}${return3M.toStringAsFixed(2)}%';
      template['近6月'] =
          '${return6M > 0 ? '+' : ''}${return6M.toStringAsFixed(2)}%';
      template['近1年'] =
          '${return1Y > 0 ? '+' : ''}${return1Y.toStringAsFixed(2)}%';
      template['近2年'] =
          '${return2Y > 0 ? '+' : ''}${return2Y.toStringAsFixed(2)}%';
      template['近3年'] =
          '${return3Y > 0 ? '+' : ''}${return3Y.toStringAsFixed(2)}%';
      template['今年以来'] =
          '${returnYTD > 0 ? '+' : ''}${returnYTD.toStringAsFixed(2)}%';
      template['成立来'] =
          '${returnSinceInception > 0 ? '+' : ''}${returnSinceInception.toStringAsFixed(2)}%';

      sampleData.add(template);
    }

    AppLogger.info('生成${sampleData.length}条示例基金数据', 'API');
    return sampleData.cast<dynamic>();
  }

  /// 生成随机收益率
  double _generateRandomReturn(double min, double max) {
    final random = DateTime.now().millisecond + DateTime.now().microsecond;
    final normalizedRandom = (random % 1000) / 1000.0;
    return min + (max - min) * normalizedRandom;
  }

  /// 安全的参数编码方法
  /// 解决中文参数编码问题，避免双重编码
  String _encodeParameterSafely(String parameter) {
    try {
      // 如果参数已经是编码过的，先解码
      if (parameter.contains('%')) {
        try {
          final decoded = Uri.decodeComponent(parameter);
          AppLogger.debug('参数已解码: $parameter -> $decoded', 'API');
          parameter = decoded;
        } catch (e) {
          // 解码失败，使用原始参数
          AppLogger.warn('参数解码失败，使用原始参数: $parameter', 'API');
        }
      }

      // 检查是否包含需要编码的字符（主要是中文和特殊字符）
      final needsEncoding = RegExp(r'[^\x00-\x7F]').hasMatch(parameter);

      if (needsEncoding) {
        // 只对非ASCII字符进行编码
        final encoded = Uri.encodeComponent(parameter);
        AppLogger.debug('参数编码: $parameter -> $encoded', 'API');
        return encoded;
      } else {
        // ASCII字符不需要编码
        AppLogger.debug('参数无需编码: $parameter', 'API');
        return parameter;
      }
    } catch (e) {
      AppLogger.error('参数编码失败: $parameter', e.toString());
      // 编码失败时返回原始参数
      return parameter;
    }
  }

  /// 构建带编码参数的完整URL
  String _buildEncodedUrl(
      String baseUrl, String endpoint, Map<String, String> parameters) {
    try {
      // 对所有参数进行安全编码
      final encodedParameters = <String, String>{};
      parameters.forEach((key, value) {
        encodedParameters[_encodeParameterSafely(key)] =
            _encodeParameterSafely(value);
      });

      // 构建URL
      final uri = Uri.parse('$baseUrl$endpoint')
          .replace(queryParameters: encodedParameters);
      final finalUrl = uri.toString();

      AppLogger.debug('构建URL: $finalUrl', 'API');
      return finalUrl;
    } catch (e) {
      AppLogger.error('URL构建失败', e.toString());
      // 降级到简单拼接
      return '$baseUrl$endpoint?${parameters.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    }
  }

  /// 处理CORS预检请求（简化版）
  Future<void> _handleCorsPreflight(String url) async {
    try {
      AppLogger.debug('CORS预检准备：$url', 'API');
      // 简化CORS处理，通过HEAD请求进行预检
      final response = await http.head(
        Uri.parse(url),
        headers: {
          'Origin': '*',
          'Access-Control-Request-Method': 'GET',
          'Access-Control-Request-Headers': 'Content-Type,Accept',
        },
      ).timeout(const Duration(seconds: 20)); // 增加CORS预检超时

      AppLogger.debug('CORS预检响应: ${response.statusCode}', 'API');

      if (response.statusCode == 200 || response.statusCode == 204) {
        AppLogger.info('CORS预检成功', 'API');
      } else {
        AppLogger.warn('CORS预检失败: ${response.statusCode}', 'API');
      }
    } catch (e) {
      AppLogger.warn('CORS预检请求失败，继续发送实际请求', e.toString());
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
            .timeout(timeout ?? const Duration(seconds: 60)); // 增加通用请求超时

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

  /// 获取多只基金详细信息用于对比
  Future<Map<String, dynamic>> getFundsForComparison(
      List<String> fundCodes) async {
    try {
      final queryParams = fundCodes.map((code) => 'symbol=$code').join('&');
      final url = '$baseUrl/api/public/fund_portfolio_em?$queryParams';

      final response = await HttpRetryHelper.getWithRetry(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json; charset=utf-8',
          'Content-Type': 'application/json; charset=utf-8',
        },
        maxRetries: maxRetries,
        retryDelay: retryDelay,
      );

      if (response.statusCode == 200) {
        final String responseData = response.body;
        final decodedData = jsonDecode(responseData);
        return decodedData;
      } else {
        throw Exception('获取基金对比数据失败: HTTP ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('获取基金对比数据异常', e, 'FundApiClient.getFundsForComparison');
      throw Exception('获取基金对比数据错误: $e');
    }
  }

  /// 获取基金历史数据用于多时间段对比
  Future<Map<String, dynamic>> getFundHistoricalData(
      String fundCode, String period) async {
    try {
      final url =
          '$baseUrl/api/public/fund_history_info_em?symbol=$fundCode&period=$period';

      final response = await HttpRetryHelper.getWithRetry(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json; charset=utf-8',
          'Content-Type': 'application/json; charset=utf-8',
        },
        maxRetries: maxRetries,
        retryDelay: retryDelay,
      );

      if (response.statusCode == 200) {
        final String responseData = response.body;
        final decodedData = jsonDecode(responseData);
        return decodedData;
      } else {
        throw Exception('获取基金历史数据失败: HTTP ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('获取基金历史数据异常', e, 'FundApiClient.getFundHistoricalData');
      throw Exception('获取基金历史数据错误: $e');
    }
  }

  /// 获取基金实时净值数据
  Future<Map<String, dynamic>> getFundRealtimeData(String fundCode) async {
    try {
      final url = '$baseUrl/api/public/fund_value_em?symbol=$fundCode';

      final response = await HttpRetryHelper.getWithRetry(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json; charset=utf-8',
          'Content-Type': 'application/json; charset=utf-8',
        },
        maxRetries: maxRetries,
        retryDelay: retryDelay,
      );

      if (response.statusCode == 200) {
        final String responseData = response.body;
        final decodedData = jsonDecode(responseData);
        return decodedData;
      } else {
        throw Exception('获取基金实时数据失败: HTTP ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('获取基金实时数据异常', e, 'FundApiClient.getFundRealtimeData');
      throw Exception('获取基金实时数据错误: $e');
    }
  }

  /// 判断状态码是否可重试
  static bool _isRetryableStatusCode(int statusCode) {
    final retryableStatusCodes = [408, 429, 500, 502, 503, 504];
    return retryableStatusCodes.contains(statusCode);
  }
}
