import 'package:dio/dio.dart';

import '../utils/logger.dart';
import 'market_data_models.dart';
import 'market_real_service_enhanced.dart';

/// 市场数据服务接口
abstract class MarketRealService {
  /// 获取所有沪深指数实时行情数据
  Future<MarketIndicesData> getRealTimeIndices();

  /// 获取单个指数数据
  Future<IndexData> getSingleIndex(String symbol);

  /// 获取指数近期历史数据
  Future<List<ChartPoint>> getIndexRecentHistory(String symbol);
}

/// 基于东方财富网的真实市场数据服务
/// 接口: stock_zh_index_spot_em
/// 地址: https://quote.eastmoney.com/center/gridlist.html#index_sz
class MarketRealServiceOriginal implements MarketRealService {
  static String baseUrl = 'http://154.44.25.92:8080';
  final Dio _dio;

  MarketRealServiceOriginal() : _dio = Dio() {
    _dio.options.baseUrl = baseUrl;
    // 优化超时配置 - 增加到30秒以处理网络延迟
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(seconds: 30);

    // 添加基础的错误处理
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException error, ErrorInterceptorHandler handler) {
          AppLogger.error(
              'API请求错误: ${error.message} | ${error.requestOptions.path}',
              error);
          if (error.type == DioExceptionType.receiveTimeout) {
            AppLogger.error('❌ 接收数据超时 - 建议检查网络连接或稍后重试', error);
          } else if (error.type == DioExceptionType.connectionTimeout) {
            AppLogger.error('❌ 连接超时 - 服务器响应缓慢', error);
          } else if (error.type == DioExceptionType.connectionError) {
            AppLogger.error('❌ 网络连接错误 - 请检查网络状态', error);
          }
          handler.next(error);
        },
      ),
    );
  }

  @override
  Future<MarketIndicesData> getRealTimeIndices() async {
    try {
      AppLogger.info('📊 开始获取实时指数数据...');

      final response = await _dio.get('/api/public/stock_zh_index_spot_em');
      final allData = response.data as List;

      AppLogger.info('✅ 成功获取 ${allData.length} 条指数数据');

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
    } catch (e) {
      AppLogger.error('❌ 获取实时指数数据失败: $e', e);

      // 返回空数据而不是抛出异常，确保应用不崩溃
      if (e is DioException && e.type == DioExceptionType.receiveTimeout) {
        AppLogger.warn('⚠️ 数据接收超时，返回空数据');
      }

      return MarketIndicesData(indices: []);
    }
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
        throw Exception('未找到代码为 $symbol 的指数数据');
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
    } catch (e) {
      AppLogger.error('❌ 获取单个指数数据失败: $symbol - $e', e);
      rethrow;
    }
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
}

/// 兼容原有代码 - 保持向后兼容
// ignore: non_constant_identifier_names
final MarketRealService marketRealService = MarketRealServiceFactory.create();
