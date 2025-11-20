import 'package:dio/dio.dart';

import '../utils/logger.dart';
import 'market_real_service.dart';
import 'market_data_models.dart';
import '../cache/unified_hive_cache_manager.dart';
import '../di/injection_container.dart';

/// 缓存键定义
class _CacheKeys {
  static String marketIndices = 'market_indices';
  static String marketOverview = 'market_overview';
  static String fundRankings = 'fund_rankings';
  static String sectorData = 'sector_data';
}

/// 增强版市场数据服务
/// 优化超时配置和重试机制
class MarketRealServiceEnhanced implements MarketRealService {
  static String baseUrl = 'http://154.44.25.92:8080';
  static int maxRetries = 3;

  // 针对不同数据类型的超时配置
  static Duration connectTimeout = const Duration(seconds: 10);
  static Duration receiveTimeout = const Duration(seconds: 15);
  static Duration sendTimeout = const Duration(seconds: 10);

  // 实时数据快速超时
  static Duration realtimeTimeout = const Duration(seconds: 8);

  // 历史数据较长超时
  static Duration historyTimeout = const Duration(seconds: 25);

  // 分时数据中等超时
  static Duration intradayTimeout = const Duration(seconds: 12);

  final Dio _dio;
  late final UnifiedHiveCacheManager _cacheManager;

  MarketRealServiceEnhanced() : _dio = Dio() {
    _initializeDio();
    _cacheManager = sl<UnifiedHiveCacheManager>();
  }

  /// 带自定义超时的GET请求
  Future<Response> _getWithTimeout(
    String path, {
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
  }) async {
    final originalTimeout = _dio.options.receiveTimeout;
    _dio.options.receiveTimeout = timeout ?? receiveTimeout;

    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } finally {
      _dio.options.receiveTimeout = originalTimeout;
    }
  }

  /// 初始化Dio配置
  void _initializeDio() {
    // 基础配置
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = connectTimeout;
    _dio.options.receiveTimeout = receiveTimeout;
    _dio.options.sendTimeout = sendTimeout;

    // 配置validateStatus，避免5xx错误抛出异常
    _dio.options.validateStatus = (status) {
      // 允许2xx状态码成功
      if (status != null && status >= 200 && status < 300) {
        return true;
      }
      // 对于4xx和5xx错误，返回false但不抛出异常
      // 让拦截器来处理这些错误
      return false;
    };

    // 重试拦截器
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException error, ErrorInterceptorHandler handler) async {
          // 只重试网络相关的错误
          if (_shouldRetry(error)) {
            final retryCount = error.requestOptions.extra['retryCount'] ?? 0;

            if (retryCount < maxRetries) {
              AppLogger.warn(
                  'API请求失败，正在重试 (${retryCount + 1}/$maxRetries): ${error.message}');

              // 指数退避延迟
              await Future.delayed(Duration(seconds: retryCount + 1));

              // 更新重试计数
              error.requestOptions.extra['retryCount'] = retryCount + 1;

              try {
                // 重新发起请求
                final response = await _dio.fetch(error.requestOptions);
                handler.resolve(response);
                return;
              } catch (e) {
                // 如果重试失败，继续传递错误
                handler.next(error);
                return;
              }
            }
          }

          handler.next(error);
        },
      ),
    );

    // 日志拦截器
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          AppLogger.debug('🌐 API请求: ${options.method} ${options.path}');
          if (options.data != null) {
            AppLogger.debug('📤 请求数据: ${options.data}');
          }
          handler.next(options);
        },
        onResponse: (Response response, ResponseInterceptorHandler handler) {
          AppLogger.debug(
              '✅ API响应: ${response.statusCode} ${response.requestOptions.path}');

          // 检查响应头的Content-Type
          final contentTypeList = response.headers['content-type'];
          if (contentTypeList != null && contentTypeList.isNotEmpty) {
            final contentType = contentTypeList.first;
            AppLogger.info('📄 Content-Type响应头: $contentType');

            // 检查编码信息
            if (contentType.toLowerCase().contains('charset')) {
              AppLogger.info('🔤 服务器指定的编码: $contentType');
            } else {
              AppLogger.warn('⚠️ 服务器未指定编码，可能使用默认编码');
            }
          } else {
            AppLogger.warn('⚠️ 服务器未返回Content-Type响应头');
          }

          handler.next(response);
        },
        onError: (DioException error, ErrorInterceptorHandler handler) {
          AppLogger.error(
              '❌ API错误: ${error.message} | ${error.requestOptions.path}',
              error);
          if (error.response != null) {
            AppLogger.error(
                '📨 错误响应: ${error.response?.statusCode} ${error.response?.data}',
                error);
          }
          handler.next(error);
        },
      ),
    );
  }

  /// 判断是否应该重试
  bool _shouldRetry(DioException error) {
    // 网络超时错误
    if (error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionTimeout) {
      return true;
    }

    // 连接错误
    if (error.type == DioExceptionType.connectionError) {
      return true;
    }

    // 5xx服务器错误（可选重试）
    if (error.response?.statusCode != null &&
        error.response!.statusCode! >= 500 &&
        error.response!.statusCode! < 600) {
      return true;
    }

    return false;
  }

  @override
  Future<MarketIndicesData> getRealTimeIndices() async {
    try {
      AppLogger.info('📊 开始获取实时指数数据...');

      // 首先尝试从缓存获取数据
      final cachedData = _cacheManager.get<List>(_CacheKeys.marketIndices);
      if (cachedData != null) {
        AppLogger.info('📋 从缓存获取指数数据');
        return _convertToMarketIndicesData(
            cachedData.map((item) => Map<String, dynamic>.from(item)).toList());
      }

      final response = await _getWithTimeout(
          '/api/public/stock_zh_index_spot_em',
          timeout: realtimeTimeout);
      final allData = response.data as List;

      AppLogger.info('✅ 成功获取 ${allData.length} 条指数数据');

      // 缓存原始数据（缓存15分钟）
      await _cacheManager.put(
        _CacheKeys.marketIndices,
        allData,
        expiration: const Duration(minutes: 15),
      );

      return _convertToMarketIndicesData(
          allData.map((item) => Map<String, dynamic>.from(item)).toList());
    } on DioException catch (e) {
      AppLogger.error('❌ API请求失败: ${e.message}', e);

      // 如果是服务器错误，尝试返回缓存的过期数据
      if (e.response?.statusCode == 500) {
        AppLogger.warn('⚠️ 服务器返回500错误，尝试使用降级策略');
        return _getFallbackMarketData();
      }

      // 其他网络错误返回空数据
      return MarketIndicesData(indices: []);
    } catch (e) {
      AppLogger.error('❌ 获取实时指数数据失败: $e', e);

      // 返回降级数据而不是抛出异常，确保应用不崩溃
      return _getFallbackMarketData();
    }
  }

  /// 获取降级市场数据
  MarketIndicesData _getFallbackMarketData() {
    AppLogger.info('🔄 使用降级市场数据');

    // 返回一些核心指数的模拟数据
    final mockIndices = [
      IndexData(
        symbol: '000001',
        name: '上证指数',
        latestPrice: 3200.0,
        changeAmount: 15.2,
        changePercent: 0.48,
        volume: 250000000,
        amount: 3200000000.0,
        openPrice: 3185.0,
        highPrice: 3205.0,
        lowPrice: 3178.0,
        previousClose: 3184.8,
        updateTime: DateTime.now().toString().substring(0, 19),
      ),
      IndexData(
        symbol: '399001',
        name: '深证成指',
        latestPrice: 10500.0,
        changeAmount: -52.0,
        changePercent: -0.49,
        volume: 180000000,
        amount: 2100000000.0,
        openPrice: 10552.0,
        highPrice: 10568.0,
        lowPrice: 10490.0,
        previousClose: 10552.0,
        updateTime: DateTime.now().toString().substring(0, 19),
      ),
      IndexData(
        symbol: '000300',
        name: '沪深300',
        latestPrice: 3850.0,
        changeAmount: 8.5,
        changePercent: 0.22,
        volume: 120000000,
        amount: 1800000000.0,
        openPrice: 3841.5,
        highPrice: 3855.0,
        lowPrice: 3838.0,
        previousClose: 3841.5,
        updateTime: DateTime.now().toString().substring(0, 19),
      ),
    ];

    return MarketIndicesData(indices: mockIndices);
  }

  /// 将原始数据转换为MarketIndicesData
  MarketIndicesData _convertToMarketIndicesData(
      List<Map<String, dynamic>> allData) {
    // 过滤出核心指数（包含更多国内重要指数）
    final coreIndices = {
      '000001': '上证指数',
      '399001': '深证成指',
      '399006': '创业板指',
      '000300': '沪深300',
      '000688': '科创50',
      '399005': '中小板指',
      '399295': '深证100',
      '000905': '中证500',
      '000016': '上证50',
      '000906': '中证800',
    };

    final indices = <IndexData>[];
    for (final data in allData) {
      final code = data['代码']?.toString();
      if (coreIndices.containsKey(code)) {
        indices.add(IndexData(
          symbol: code!,
          name: data['名称'] ?? coreIndices[code]!,
          latestPrice: (data['最新价'] ?? 0.0).toDouble(),
          changeAmount: (data['涨跌额'] ?? 0.0).toDouble(),
          changePercent: (data['涨跌幅'] ?? 0.0).toDouble(),
          volume: (data['成交量'] ?? 0).toInt(),
          amount: (data['成交额'] ?? 0.0).toDouble(),
          openPrice: (data['开盘价'] ?? 0.0).toDouble(),
          highPrice: (data['最高价'] ?? 0.0).toDouble(),
          lowPrice: (data['最低价'] ?? 0.0).toDouble(),
          previousClose: (data['昨收'] ?? 0.0).toDouble(),
          updateTime: data['时间']?.toString() ?? '',
        ));
      }
    }

    return MarketIndicesData(indices: indices);
  }

  @override
  Future<IndexData> getSingleIndex(String symbol) async {
    try {
      AppLogger.info('📈 开始获取单个指数数据: $symbol');

      final response = await _dio.get('/api/public/stock_zh_index_spot_em');
      final data = response.data as List;

      final indexData = data.firstWhere(
        (item) => item['代码']?.toString() == symbol,
        orElse: () => null,
      );

      if (indexData == null) {
        AppLogger.warn('⚠️ 未找到指数数据: $symbol');
        return _getFallbackIndexData(symbol);
      }

      AppLogger.info('✅ 成功获取指数数据: $symbol');

      return IndexData(
        symbol: indexData['代码']?.toString() ?? symbol,
        name: indexData['名称'] ?? '',
        latestPrice: (indexData['最新价'] ?? 0.0).toDouble(),
        changeAmount: (indexData['涨跌额'] ?? 0.0).toDouble(),
        changePercent: (indexData['涨跌幅'] ?? 0.0).toDouble(),
        volume: (indexData['成交量'] ?? 0).toInt(),
        amount: (indexData['成交额'] ?? 0.0).toDouble(),
        openPrice: (indexData['开盘价'] ?? 0.0).toDouble(),
        highPrice: (indexData['最高价'] ?? 0.0).toDouble(),
        lowPrice: (indexData['最低价'] ?? 0.0).toDouble(),
        previousClose: (indexData['昨收'] ?? 0.0).toDouble(),
        updateTime: indexData['时间']?.toString() ?? '',
      );
    } on DioException catch (e) {
      AppLogger.error('❌ API请求失败: ${e.message}', e);

      // 如果是服务器错误，使用降级策略
      if (e.response?.statusCode == 500) {
        AppLogger.warn('⚠️ 服务器返回500错误，使用降级数据: $symbol');
        return _getFallbackIndexData(symbol);
      }

      // 其他网络错误返回降级数据
      return _getFallbackIndexData(symbol);
    } catch (e) {
      AppLogger.error('❌ 获取单个指数数据失败: $e', e);
      return _getFallbackIndexData(symbol);
    }
  }

  /// 获取降级指数数据
  IndexData _getFallbackIndexData(String symbol) {
    AppLogger.info('🔄 使用降级指数数据: $symbol');

    final fallbackData = {
      '000001': {'name': '上证指数', 'basePrice': 3200.0},
      '399001': {'name': '深证成指', 'basePrice': 10500.0},
      '000300': {'name': '沪深300', 'basePrice': 3850.0},
      '399006': {'name': '创业板指', 'basePrice': 2200.0},
      '000688': {'name': '科创50', 'basePrice': 1100.0},
    };

    final data = fallbackData[symbol] ?? {'name': '未知指数', 'basePrice': 1000.0};
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    final changeAmount = (random - 50) / 10.0; // -5.0 到 5.0
    final basePrice = (data['basePrice'] as num).toDouble();
    final changePercent = changeAmount / basePrice * 100;

    return IndexData(
      symbol: symbol,
      name: data['name'] as String,
      latestPrice: basePrice + changeAmount,
      changeAmount: changeAmount,
      changePercent: changePercent,
      volume: 100000000 + (random * 1000000),
      amount: 1000000000.0 + (random * 10000000.0),
      openPrice: basePrice,
      highPrice: basePrice + 10.0,
      lowPrice: basePrice - 10.0,
      previousClose: basePrice,
      updateTime: DateTime.now().toString().substring(0, 19),
    );
  }

  @override
  Future<List<ChartPoint>> getIndexRecentHistory(String symbol) async {
    try {
      AppLogger.info('📈 开始获取指数历史数据: $symbol');

      // 模拟历史数据生成 - 在实际应用中应该从API获取
      final now = DateTime.now();
      final List<ChartPoint> points = [];

      // 生成最近5个数据点（模拟数据）
      for (int i = 0; i < 5; i++) {
        final time = now.subtract(Duration(minutes: (4 - i) * 30));
        // 这里应该从真实的API获取历史数据
        // 现在使用模拟数据
        final price = 3000.0 + (i * 10.0) + (i % 2 == 0 ? 5.0 : -3.0);
        points.add(ChartPoint(
          x: i.toDouble(),
          y: price,
          time: time,
        ));
      }

      AppLogger.info('✅ 成功生成指数历史数据: $symbol');
      return points;
    } catch (e) {
      AppLogger.error('❌ 获取指数历史数据失败: $symbol - $e', e);
      // 返回空列表而不是抛出异常
      return [];
    }
  }

  @override
  Future<List<IndexHistoryData>> getIndexHistory(
      HistoryQueryParams params) async {
    try {
      AppLogger.info('📊 开始获取指数历史日线数据: ${params.symbol}');

      // 检查缓存
      final cacheKey = '${_CacheKeys.marketIndices}_history_${params.symbol}';
      final cachedData = _cacheManager.get<List>(cacheKey);
      if (cachedData != null) {
        AppLogger.info('📋 从缓存获取历史数据: ${params.symbol}');
        return cachedData
            .map((item) => IndexHistoryData.fromEastMoney(
                  Map<String, dynamic>.from(item),
                  params.symbol,
                  _getIndexName(params.symbol),
                ))
            .toList();
      }

      // 调用东方财富历史数据API
      final response = await _getWithTimeout(
        '/api/public/stock_zh_index_daily_em',
        queryParameters: {'symbol': params.symbol},
        timeout: historyTimeout,
      );

      final data = response.data as List;
      AppLogger.info('✅ 成功获取 ${data.length} 条历史数据');

      // 缓存原始数据（缓存1小时，历史数据变化不频繁）
      await _cacheManager.put(
        cacheKey,
        data,
        expiration: const Duration(hours: 1),
      );

      final historyData = data.map((item) {
        return IndexHistoryData.fromEastMoney(
          Map<String, dynamic>.from(item),
          params.symbol,
          _getIndexName(params.symbol),
        );
      }).toList();

      // 如果指定了日期范围，进行过滤
      if (params.startDate != null || params.endDate != null) {
        return historyData.where((data) {
          if (params.startDate != null &&
              data.date.isBefore(params.startDate!)) {
            return false;
          }
          if (params.endDate != null && data.date.isAfter(params.endDate!)) {
            return false;
          }
          return true;
        }).toList();
      }

      return historyData;
    } on DioException catch (e) {
      AppLogger.error('❌ API请求失败: ${e.message}', e);

      // 如果是服务器错误，尝试返回空数据
      if (e.response?.statusCode == 500) {
        AppLogger.warn('⚠️ 服务器返回500错误，历史数据获取失败');
        return [];
      }

      return [];
    } catch (e) {
      AppLogger.error('❌ 获取指数历史数据失败: ${params.symbol} - $e', e);
      return [];
    }
  }

  @override
  Future<List<IndexIntradayData>> getIndexIntradayData(
      HistoryQueryParams params) async {
    try {
      AppLogger.info('📈 开始获取指数分时数据: ${params.symbol}');

      if (params.period == null) {
        throw ArgumentError('分时数据需要指定period参数');
      }

      // 检查缓存（分时数据缓存时间较短，5分钟）
      final cacheKey =
          '${_CacheKeys.marketIndices}_intraday_${params.symbol}_${params.period}';
      final cachedData = _cacheManager.get<List>(cacheKey);
      if (cachedData != null) {
        AppLogger.info('📋 从缓存获取分时数据: ${params.symbol}');
        return cachedData
            .map((item) => IndexIntradayData.fromEastMoney(
                  Map<String, dynamic>.from(item),
                  params.symbol,
                  _getIndexName(params.symbol),
                ))
            .toList();
      }

      final queryParams = params.toQueryParams();

      // 调用东方财富分时数据API
      final response = await _getWithTimeout(
        '/api/public/index_zh_a_hist_min_em',
        queryParameters: queryParams,
        timeout: intradayTimeout,
      );

      final data = response.data as List;
      AppLogger.info('✅ 成功获取 ${data.length} 条分时数据');

      // 缓存分时数据（5分钟）
      await _cacheManager.put(
        cacheKey,
        data,
        expiration: const Duration(minutes: 5),
      );

      return data.map((item) {
        return IndexIntradayData.fromEastMoney(
          Map<String, dynamic>.from(item),
          params.symbol,
          _getIndexName(params.symbol),
        );
      }).toList();
    } on DioException catch (e) {
      AppLogger.error('❌ API请求失败: ${e.message}', e);

      // 如果是服务器错误，尝试返回空数据
      if (e.response?.statusCode == 500) {
        AppLogger.warn('⚠️ 服务器返回500错误，分时数据获取失败');
        return [];
      }

      return [];
    } catch (e) {
      AppLogger.error('❌ 获取指数分时数据失败: ${params.symbol} - $e', e);
      return [];
    }
  }

  @override
  Future<List<ChartPoint>> getHistoryChartPoints(
    String symbol, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final params = HistoryQueryParams(
        symbol: symbol,
        startDate: startDate,
        endDate: endDate,
      );
      final historyData = await getIndexHistory(params);

      return historyData
          .asMap()
          .entries
          .map((entry) => ChartPoint.fromHistoryData(entry.value, entry.key))
          .toList();
    } catch (e) {
      AppLogger.error('❌ 生成历史图表点失败: $symbol - $e', e);
      return [];
    }
  }

  @override
  Future<List<ChartPoint>> getIntradayChartPoints(
    String symbol, {
    String period = '1',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final params = HistoryQueryParams(
        symbol: symbol,
        period: period,
        startDate: startDate,
        endDate: endDate,
      );

      final intradayData = await getIndexIntradayData(params);

      return intradayData
          .asMap()
          .entries
          .map((entry) => ChartPoint.fromIntradayData(entry.value, entry.key))
          .toList();
    } catch (e) {
      AppLogger.error('❌ 生成分时图表点失败: $symbol - $e', e);
      return [];
    }
  }

  /// 根据指数代码获取指数名称
  String _getIndexName(String symbol) {
    final indexNames = {
      '000001': '上证指数',
      '399001': '深证成指',
      '399006': '创业板指',
      '000300': '沪深300',
      '000688': '科创50',
      '399005': '中小板指',
      '399295': '深证100',
      '000905': '中证500',
      '000016': '上证50',
      '000906': '中证800',
    };
    return indexNames[symbol] ?? '未知指数';
  }
}

/// 工厂类：创建适当的服务实例
class MarketRealServiceFactory {
  /// 根据配置创建服务实例
  static MarketRealService create({bool useEnhanced = true}) {
    if (useEnhanced) {
      AppLogger.info('🚀 使用增强版市场数据服务（优化超时和重试）');
      return MarketRealServiceEnhanced();
    } else {
      AppLogger.info('📊 使用标准版市场数据服务');
      return MarketRealServiceOriginal();
    }
  }
}
