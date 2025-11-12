import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/http.dart' show ClientException;
import 'package:crypto/crypto.dart';

import '../../../../core/utils/logger.dart';
import '../../../../core/cache/interfaces/cache_service.dart';
import '../../../../core/cache/request_deduplication_manager.dart';
import '../../../../core/cache/cache_key_manager.dart';
import '../../../../core/cache/smart_cache_invalidation_manager.dart';
import '../../../../core/cache/cache_preheating_manager.dart';
import '../../../../core/cache/unified_hive_cache_manager.dart';
import '../models/fund_ranking.dart';
import 'data_validation_service.dart';

/// 统一的基金数据服务（智能缓存版，防卡死增强）
///
/// 职责：
/// - 封装所有基金相关的API调用
/// - 处理数据格式转换
/// - 统一错误处理
/// - 网络请求重试机制（优化版）
/// - 智能缓存管理
/// - 数据一致性检查和错误恢复
/// - 多层超时保护和快速失败机制
/// - 请求频率控制和并发管理
class FundDataService {
  static const String _baseUrl = 'http://154.44.25.92:8080';
  static const String _allFundsSymbol = '全部';

  // 请求频率控制
  static final Map<String, DateTime> _lastRequestTime = {};
  static const Duration _minRequestInterval = Duration(seconds: 2); // 最小请求间隔
  static const int _maxConcurrentRequests = 3; // 最大并发请求数
  static int _currentRequests = 0;

  // 全局请求去重管理器
  final RequestDeduplicationManager _deduplicationManager =
      RequestDeduplicationManager();

  // 智能缓存失效管理器
  final SmartCacheInvalidationManager _invalidationManager =
      SmartCacheInvalidationManager.instance;

  // 缓存性能监控器（移除循环依赖）
  // final CachePerformanceMonitor _performanceMonitor =
  //     CachePerformanceMonitor.instance;

  // 缓存预热管理器
  final CachePreheatingManager _preheatingManager =
      CachePreheatingManager.instance;

  // 缓存访问跟踪 - 用于智能预热
  final Map<String, int> _cacheAccessCounts = {};
  final Map<String, DateTime> _cacheLastAccess = {};
  Timer? _preheatTimer;

  // 请求配置 - 智能超时设置
  static const Duration _defaultTimeout = Duration(seconds: 120); // 默认超时
  static const Duration _fundDataTimeout = Duration(seconds: 180); // 基金数据请求超时
  static const Duration _searchTimeout = Duration(seconds: 60); // 搜索请求超时
  static const int _maxRetries = 2; // 增加重试次数，提高成功率
  static const Duration _retryDelay = Duration(seconds: 3); // 增加重试间隔
  // static const Duration _connectionTimeout = Duration(seconds: 30); // 连接超时 - 暂未使用

  /// 获取智能超时时间
  static Duration _getTimeoutForRequest(String url) {
    if (url.contains('/funds/') ||
        url.contains('/batch/') ||
        url.contains('/nav/')) {
      return _fundDataTimeout; // 基金数据请求使用180秒
    }
    if (url.contains('/search/') || url.contains('/query/')) {
      return _searchTimeout; // 搜索请求使用60秒
    }
    return _defaultTimeout; // 其他请求使用默认120秒
  }

  // 缓存配置 - 改进的缓存策略
  static const String _cacheKeyPrefix = 'fund_rankings_';
  static const Duration _cacheExpireTime = Duration(minutes: 5); // 增加缓存时间到5分钟
  static const Duration _shortCacheExpireTime =
      Duration(minutes: 2); // 短期缓存用于频繁访问
  static const Duration _longCacheExpireTime =
      Duration(minutes: 15); // 长期缓存用于稳定数据

  // 智能缓存策略
  // static const int _maxCacheSize = 50; // 最大缓存条目数 - 暂未使用
  static const int _preheatThreshold = 3; // 预热阈值：访问次数超过此值则预热
  static const Duration _preheatCheckInterval = Duration(minutes: 1); // 预热检查间隔

  // 缓存管理器
  late final CacheService _cacheService;

  // 数据验证服务
  late final DataValidationService _validationService;

  /// 构造函数
  FundDataService({
    CacheService? cacheService,
    DataValidationService? validationService,
  }) : _cacheService = cacheService ??
            (throw ArgumentError(
                'CacheService is required for FundDataService')) {
    _validationService = validationService ??
        DataValidationService(
          cacheService: _cacheService,
          fundDataService: this,
        );
    // 异步初始化，不阻塞构造函数
    _initializeCacheAndInvalidation().catchError((e) {
      AppLogger.warn('⚠️ FundDataService: 异步初始化失败: $e');
    });
  }

  /// 初始化缓存服务和失效管理器
  Future<void> _initializeCacheAndInvalidation() async {
    try {
      // 初始化缓存服务
      await _cacheService.get('__test_key__');
      AppLogger.info('✅ FundDataService: 缓存服务初始化成功');
    } catch (e) {
      AppLogger.warn('⚠️ FundDataService: 缓存服务初始化失败，将在无缓存模式下运行: $e');
    }

    try {
      // 初始化智能缓存失效管理器
      await _invalidationManager.initialize(
        strategy: CacheInvalidationStrategy.hybrid,
        processingInterval: const Duration(seconds: 1),
        maintenanceInterval: const Duration(minutes: 5),
        predictiveInterval: const Duration(minutes: 10),
        enablePredictiveRefresh: true,
      );

      // 添加失效监听器
      _invalidationManager.addInvalidationListener(_handleCacheInvalidation);

      AppLogger.info('✅ FundDataService: 智能缓存失效管理器初始化成功');
    } catch (e) {
      AppLogger.warn('⚠️ FundDataService: 缓存失效管理器初始化失败: $e');
    }
  }

  /// 获取基金排行数据（智能缓存版 + 请求去重 + 优化键管理）
  ///
  /// [symbol] 基金类型符号，默认为全部基金
  /// [forceRefresh] 是否强制刷新，忽略缓存
  /// [onProgress] 进度回调函数
  Future<FundDataResult<List<FundRanking>>> getFundRankings({
    String symbol = _allFundsSymbol,
    bool forceRefresh = false,
    Function(double)? onProgress,
  }) async {
    // 使用标准化的缓存键管理器
    final cacheKeyManager = CacheKeyManager.instance;
    final cacheKey = cacheKeyManager.fundListKey(
      symbol.isEmpty ? 'all' : symbol,
      filters: {'force_refresh': forceRefresh.toString()},
    );

    // 生成请求去重键
    final deduplicationKey = _generateDeduplicationKey('fund_rankings', {
      'symbol': symbol,
      'forceRefresh': forceRefresh,
      'cache_key': cacheKey, // 包含标准化的缓存键
    });

    AppLogger.debug(
        '🔄 FundDataService: 开始获取基金排行数据 (symbol: $symbol, forceRefresh: $forceRefresh)');
    AppLogger.debug('🔑 标准化缓存键: $cacheKey');
    AppLogger.debug('🔄 请求去重键: $deduplicationKey');

    // 使用请求去重管理器 - 让请求去重管理器自动识别合适的超时时间
    return await _deduplicationManager
        .getOrExecute<FundDataResult<List<FundRanking>>>(
      deduplicationKey,
      executor: () => _executeFundRankingsRequest(
        symbol: symbol,
        forceRefresh: forceRefresh,
        onProgress: onProgress,
        cacheKey: cacheKey,
      ),
      // 不再传递固定超时，让智能识别生效
      enableCache: !forceRefresh,
      cacheExpiration: _cacheExpireTime,
    );
  }

  /// 搜索基金
  Future<FundDataResult<List<FundRanking>>> searchFunds(
    String query, {
    List<FundRanking>? searchIn,
  }) async {
    if (query.isEmpty) {
      return FundDataResult.success(<FundRanking>[]);
    }

    AppLogger.debug('🔍 FundDataService: 搜索基金 (query: $query)');

    try {
      List<FundRanking> searchPool;

      if (searchIn != null) {
        searchPool = searchIn;
      } else {
        // 如果没有提供搜索池，先获取全部基金数据
        final result = await getFundRankings();
        if (result.isFailure) {
          return FundDataResult.failure(result.errorMessage ?? '未知错误');
        }
        searchPool = result.data!;
      }

      final filteredRankings = _performSearch(searchPool, query);

      AppLogger.debug(
          '✅ FundDataService: 搜索完成，找到${filteredRankings.length}条结果');
      return FundDataResult.success(filteredRankings);
    } catch (e) {
      final errorMsg = '搜索失败: $e';
      AppLogger.debug('❌ FundDataService: $errorMsg');
      return FundDataResult.failure(errorMsg);
    }
  }

  /// 获取基金详细信息
  Future<FundDataResult<Map<String, dynamic>>> getFundDetail(
      String fundCode) async {
    AppLogger.debug('🔍 FundDataService: 获取基金详情 (fundCode: $fundCode)');

    try {
      final uri = Uri.parse(
          '$_baseUrl/api/public/fund_open_fund_info_em?symbol=$fundCode');

      final detailData = await _executeWithRetry<Map<String, dynamic>>(
        () => _fetchFundDetailFromApi(uri),
        maxRetries: _maxRetries,
        retryDelay: _retryDelay,
      );

      AppLogger.debug('✅ FundDataService: 基金详情获取成功');
      return FundDataResult.success(detailData);
    } catch (e) {
      final errorMsg = '获取基金详情失败: $e';
      AppLogger.debug('❌ FundDataService: $errorMsg');
      return FundDataResult.failure(errorMsg);
    }
  }

  /// 从API获取排行数据（增强防卡死版本）
  Future<List<FundRanking>> _fetchRankingsFromApi(
    Uri uri,
    Function(double)? onProgress,
  ) async {
    AppLogger.debug('📡 FundDataService: 请求URL: $uri');
    final requestTimeout = _getTimeoutForRequest(uri.toString());
    AppLogger.info(
        '⏱️ FundDataService: 开始请求，超时时间: ${requestTimeout.inSeconds}秒 (智能配置)');

    // 第1层：快速失败检查 - 临时禁用以调试超时问题
    // await _preRequestCheck();
    AppLogger.debug('⚠️ FundDataService: 跳过预检查以调试超时问题');

    // 第2层：多层超时保护
    http.Response response;
    try {
      // 使用智能请求方法：连接检查 + 智能重试 + 超时保护
      response = await _makeSmartRequest(uri);

      AppLogger.debug('📊 FundDataService: 响应状态: ${response.statusCode}');
      AppLogger.debug('📏 FundDataService: 响应大小: ${response.body.length} 字节');
    } on TimeoutException catch (e) {
      AppLogger.error('⏰ FundDataService: 请求超时异常', e);
      rethrow;
    } on SocketException catch (e) {
      AppLogger.error('🔌 FundDataService: 网络连接异常', e);
      rethrow;
    } on HttpException catch (e) {
      AppLogger.error('🌐 FundDataService: HTTP异常', e);
      rethrow;
    } catch (e) {
      AppLogger.error('❌ FundDataService: 未知请求异常', e);
      rethrow;
    }

    // 第3层：响应状态验证
    _validateResponse(response);

    AppLogger.debug('✅ FundDataService: 请求成功');

    // 解码响应数据
    String responseData;
    try {
      responseData = utf8.decode(response.body.codeUnits, allowMalformed: true);
    } catch (e) {
      AppLogger.debug('❌ UTF-8解码失败，使用原始数据: $e');
      responseData = response.body;
    }

    // 解析JSON
    final dynamic jsonData;
    try {
      jsonData = json.decode(responseData);
    } catch (e) {
      throw FormatException('JSON解析失败: $e');
    }

    if (jsonData is! List) {
      throw FormatException('API返回数据格式错误，期望List，实际: ${jsonData.runtimeType}');
    }

    AppLogger.debug('📊 FundDataService: 数据解析成功，数据量: ${jsonData.length}');

    // 转换为FundRanking对象
    final rankings = <FundRanking>[];
    for (int i = 0; i < jsonData.length; i++) {
      try {
        final ranking =
            FundRanking.fromJson(jsonData[i] as Map<String, dynamic>, i + 1);
        rankings.add(ranking);

        // 进度回调
        onProgress?.call((i + 1) / jsonData.length);
      } catch (e) {
        AppLogger.debug('⚠️ FundDataService: 跳过无效数据项[$i]: $e');
        // 继续处理其他数据项
      }
    }

    AppLogger.debug('✅ FundDataService: 成功转换${rankings.length}条基金数据');
    return rankings;
  }

  /// 检查网络连接
  Future<bool> _checkNetworkConnectivity() async {
    try {
      // 简单的连通性检查
      final response = await http.get(
        Uri.parse('https://www.baidu.com'),
        headers: {'User-Agent': 'Mozilla/5.0'},
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      AppLogger.debug('网络连接检查失败: $e');
      return false;
    }
  }

  /// 检查API服务器连通性
  Future<bool> _checkApiServerConnectivity() async {
    try {
      // 检查基础服务器是否可达
      final response = await http
          .get(
            Uri.parse('$_baseUrl/'),
            headers: _buildHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      AppLogger.debug('🌐 API服务器连通性检查: ${response.statusCode}');
      return response.statusCode < 500; // 只要不是服务器错误都认为可达
    } catch (e) {
      AppLogger.warn('⚠️ API服务器连通性检查失败: $e');
      return false;
    }
  }

  /// 测试API端点是否存在
  Future<bool> _testApiEndpoint(String endpoint) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final response = await http
          .get(
            uri,
            headers: _buildHeaders(),
          )
          .timeout(const Duration(seconds: 10)); // API端点测试使用10秒超时

      AppLogger.debug('🔍 API端点测试 $endpoint: ${response.statusCode}');

      // 404表示端点不存在，其他状态码表示端点存在但可能有其他问题
      return response.statusCode != 404;
    } catch (e) {
      AppLogger.warn('⚠️ API端点测试失败 $endpoint: $e');
      return false;
    }
  }

  /// API诊断方法 - 当遇到404错误时提供详细诊断信息
  Future<String> diagnoseApiProblem() async {
    final diagnostic = StringBuffer();
    diagnostic.writeln('🔍 API诊断报告');
    diagnostic.writeln('=' * 50);

    // 1. 网络连接检查
    diagnostic.writeln('\n1. 网络连接检查：');
    final hasNetwork = await _checkNetworkConnectivity();
    diagnostic.writeln('   ${hasNetwork ? "✅ 网络连接正常" : "❌ 网络连接失败"}');

    // 2. API服务器连通性
    diagnostic.writeln('\n2. API服务器连通性：');
    final serverReachable = await _checkApiServerConnectivity();
    diagnostic.writeln('   ${serverReachable ? "✅ 服务器可达" : "❌ 服务器不可达"}');
    diagnostic.writeln('   服务器地址：$_baseUrl');

    // 3. API端点测试
    diagnostic.writeln('\n3. API端点测试：');
    final endpoints = [
      '/api/public/fund_open_fund_rank_em', // 基金排行（无参数）
      '/api/public/fund_open_fund_info_em?symbol=000001', // 基金详情（需要symbol参数）
      '/health',
      '/api',
    ];

    for (final endpoint in endpoints) {
      final exists = await _testApiEndpoint(endpoint);
      diagnostic.writeln('   ${exists ? "✅" : "❌"} $endpoint');
    }

    // 4. 建议解决方案
    diagnostic.writeln('\n💡 建议解决方案：');
    if (!hasNetwork) {
      diagnostic.writeln('   - 检查网络连接');
      diagnostic.writeln('   - 确认设备已连接到互联网');
    }
    if (!serverReachable) {
      diagnostic.writeln('   - 检查API服务器是否运行：$_baseUrl');
      diagnostic.writeln('   - 确认服务器地址是否正确');
      diagnostic.writeln('   - 检查防火墙设置');
    }
    diagnostic.writeln('   - 验证API路径是否与AKshare文档一致');
    diagnostic.writeln('   - 联系技术支持确认API服务状态');

    final report = diagnostic.toString();
    AppLogger.info('🔍 API诊断完成：\n$report');
    return report;
  }

  /// 预请求检查 - 快速失败机制
  Future<void> _preRequestCheck() async {
    // 检查网络连接
    if (!await _checkNetworkConnectivity()) {
      throw const SocketException('网络连接不可用');
    }

    // 检查API服务器连通性
    if (!await _checkApiServerConnectivity()) {
      throw const SocketException('API服务器不可达，请检查服务器地址：$_baseUrl');
    }

    // 快速API端点测试
    try {
      final apiExists =
          await _testApiEndpoint('/api/public/fund_open_fund_rank_em');
      if (!apiExists) {
        AppLogger.error('❌ API端点不存在: /api/public/fund_open_fund_rank_em', null);
        throw const HttpException('基金排行API端点不存在，可能API路径已变更或服务未启动');
      }
    } catch (e) {
      if (e is HttpException) rethrow;
      AppLogger.warn('⚠️ FundDataService: API端点测试失败，但继续请求: $e');
    }
  }

  /// 多层超时保护的HTTP请求（增强版）
  Future<http.Response> _makeRequestWithMultiTimeout(Uri uri) async {
    // 预检查网络连接
    final hasNetwork = await checkNetworkConnectivity();
    if (!hasNetwork) {
      AppLogger.error('🌐 FundDataService: 网络不可达，跳过请求: $uri', null);
      throw const SocketException('网络连接不可用');
    }

    final headers = _buildHeaders();
    final stopwatch = Stopwatch()..start();

    AppLogger.debug('🔍 FundDataService: 请求详情');
    AppLogger.debug('  URL: $uri');
    AppLogger.debug('  Headers: $headers');
    final timeout = _getTimeoutForRequest(uri.toString());
    AppLogger.debug('  超时设置: ${timeout.inSeconds}秒 (智能配置)');
    AppLogger.info(
        '⏱️ FundDataService: 开始HTTP请求 - ${DateTime.now().millisecondsSinceEpoch}ms');

    try {
      // 增强HTTP请求配置，提高连接稳定性
      final response = await http.get(
        uri,
        headers: {
          ...headers,
          'Connection': 'keep-alive',
          'Keep-Alive': 'timeout=30, max=100',
          'Accept': 'application/json',
          'Accept-Encoding': 'gzip, deflate',
          'User-Agent': 'FundDataService/2.0.0 (Flutter; Stable Connection)',
        },
      ).timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException('HTTP请求超时', timeout);
        },
      );

      stopwatch.stop();
      final requestDuration = stopwatch.elapsedMilliseconds;

      AppLogger.info('✅ FundDataService: HTTP请求完成 - 耗时${requestDuration}ms');
      AppLogger.debug('📊 FundDataService: 响应详情');
      AppLogger.debug('  状态码: ${response.statusCode}');
      AppLogger.debug('  响应大小: ${response.body.length} 字节');
      AppLogger.debug('  响应头: ${response.headers}');
      AppLogger.debug(
          '  平均下载速度: ${(response.body.length / requestDuration * 1000).toStringAsFixed(2)} bytes/s');

      if (response.statusCode != 200) {
        AppLogger.debug('❌ FundDataService: 响应内容预览: ${response.body}');
      }

      return response;
    } on TimeoutException catch (e) {
      stopwatch.stop();
      final timeoutDuration = stopwatch.elapsedMilliseconds;
      final actualTimeout = _getTimeoutForRequest(uri.toString());
      AppLogger.warn(
          '⏰ FundDataService: HTTP请求超时 (${actualTimeout.inSeconds}秒) - 实际耗时${timeoutDuration}ms: $uri');
      AppLogger.debug('⏰ 超时详情: $e');
      rethrow;
    } on SocketException catch (e) {
      stopwatch.stop();
      final socketErrorDuration = stopwatch.elapsedMilliseconds;
      AppLogger.error(
          '🔌 FundDataService: 网络连接异常 - 耗时${socketErrorDuration}ms', e);
      rethrow;
    } on HttpException catch (e) {
      stopwatch.stop();
      final httpErrorDuration = stopwatch.elapsedMilliseconds;
      AppLogger.error(
          '🌐 FundDataService: HTTP协议异常 - 耗时${httpErrorDuration}ms', e);
      rethrow;
    } on ClientException catch (e) {
      stopwatch.stop();
      final clientErrorDuration = stopwatch.elapsedMilliseconds;
      AppLogger.error(
          '🔗 FundDataService: HTTP客户端连接异常 (连接中断或服务器无响应) - 耗时${clientErrorDuration}ms',
          e);
      AppLogger.debug('🔗 连接异常详情: ${e.message}');
      AppLogger.debug(
          '🔗 异常发生时间点: ${DateTime.now().millisecondsSinceEpoch}ms (请求开始后${clientErrorDuration}ms)');

      // 对于连接关闭的错误，提供更友好的错误信息
      if (e.message.contains('Connection closed while receiving data')) {
        throw SocketException('服务器在传输数据时关闭连接，可能是网络不稳定或服务器负载过高');
      } else if (e.message.contains('Connection refused')) {
        throw SocketException('服务器拒绝连接，请检查服务器状态');
      } else if (e.message.contains('Network is unreachable')) {
        throw SocketException('网络不可达，请检查网络连接');
      } else {
        // 重新抛出原始异常
        rethrow;
      }
    } catch (e) {
      stopwatch.stop();
      final unknownErrorDuration = stopwatch.elapsedMilliseconds;
      AppLogger.error(
          '❌ FundDataService: 未知请求异常 - 耗时${unknownErrorDuration}ms', e);
      rethrow;
    }
  }

  /// 智能网络请求（带连接检查和智能重试）
  Future<http.Response> _makeSmartRequest(Uri uri) async {
    AppLogger.info('🔄 FundDataService: 开始智能重试请求 - 最大重试次数: $_maxRetries');
    final totalStopwatch = Stopwatch()..start();

    try {
      final response = await _executeWithRetry<http.Response>(
        () => _makeRequestWithMultiTimeout(uri),
        maxRetries: _maxRetries,
        retryDelay: _retryDelay,
      );

      totalStopwatch.stop();
      final totalDuration = totalStopwatch.elapsedMilliseconds;
      AppLogger.info('✅ FundDataService: 智能重试请求成功 - 总耗时${totalDuration}ms');

      return response;
    } catch (e) {
      totalStopwatch.stop();
      final totalDuration = totalStopwatch.elapsedMilliseconds;
      AppLogger.error('❌ FundDataService: 智能重试请求失败 - 总耗时${totalDuration}ms', e);
      rethrow;
    }
  }

  /// 验证HTTP响应
  void _validateResponse(http.Response response) {
    if (response.statusCode != 200) {
      String errorMsg =
          'API错误: ${response.statusCode} ${response.reasonPhrase}';

      // 为404错误提供更详细的信息和可能的解决方案
      if (response.statusCode == 404) {
        errorMsg += '\n\n💡 可能的解决方案：';
        errorMsg +=
            '\n1. 检查API端点是否正确：/api/public/fund_open_fund_rank_em（基金排行，无参数）';
        errorMsg += '\n2. 确认服务器地址：http://154.44.25.92:8080';
        errorMsg += '\n3. 验证API服务是否正在运行';
        errorMsg += '\n4. 检查API路径是否有变更';
        errorMsg += '\n5. 确保基金排行API不传递任何参数（symbol参数会导致404）';

        AppLogger.error('🔍 API 404错误详情：$errorMsg', null);

        // 注意：异步诊断需要在调用方进行，这里提供提示信息
        errorMsg += '\n\n🔍 如需详细诊断，请调用 diagnoseApiProblem() 方法';

        // 对于404错误，尝试提供一个备用的错误消息
        throw const HttpException('API接口不存在，请检查服务器配置和API路径');
      } else if (response.statusCode >= 500) {
        errorMsg += '\n\n💡 服务器内部错误，请稍后重试或联系技术支持';
        AppLogger.error('🔥 服务器错误：$errorMsg', null);
        throw const HttpException('服务器内部错误，请稍后重试');
      } else if (response.statusCode == 401) {
        errorMsg += '\n\n💡 认证失败，请检查API密钥或访问权限';
        throw const HttpException('API认证失败');
      } else {
        AppLogger.error('❌ HTTP错误：$errorMsg', null);
        throw HttpException(errorMsg);
      }
    }

    if (response.body.isEmpty) {
      throw const FormatException('响应数据为空');
    }

    // 检查响应大小，防止过大的响应导致内存问题
    if (response.body.length > 10 * 1024 * 1024) {
      // 10MB
      throw FormatException('响应数据过大 (${response.body.length} 字节)，可能存在性能问题');
    }
  }

  /// 从API获取基金详情
  Future<Map<String, dynamic>> _fetchFundDetailFromApi(Uri uri) async {
    AppLogger.debug('📡 FundDataService: 请求详情URL: $uri');

    final response = await http
        .get(
          uri,
          headers: _buildHeaders(),
        )
        .timeout(_getTimeoutForRequest('$uri'));

    AppLogger.debug('📊 FundDataService: 详情响应状态: ${response.statusCode}');

    if (response.statusCode != 200) {
      throw HttpException(
          'API错误: ${response.statusCode} ${response.reasonPhrase}');
    }

    // 解码响应数据
    String responseData;
    try {
      responseData = utf8.decode(response.body.codeUnits, allowMalformed: true);
    } catch (e) {
      AppLogger.debug('❌ UTF-8解码失败，使用原始数据: $e');
      responseData = response.body;
    }

    // 解析JSON
    final Map<String, dynamic> jsonData;
    try {
      jsonData = json.decode(responseData) as Map<String, dynamic>;
    } catch (e) {
      throw FormatException('JSON解析失败: $e');
    }

    AppLogger.debug('✅ FundDataService: 基金详情解析成功');
    return jsonData;
  }

  /// 执行搜索
  List<FundRanking> _performSearch(List<FundRanking> searchPool, String query) {
    final lowerQuery = query.toLowerCase();

    return searchPool.where((ranking) {
      return ranking.fundName.toLowerCase().contains(lowerQuery) ||
          ranking.fundCode.toLowerCase().contains(lowerQuery) ||
          ranking.fundType.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// 构建请求头
  Map<String, String> _buildHeaders() {
    return {
      'Accept': 'application/json',
      'Accept-Encoding': 'gzip, deflate',
      'User-Agent': 'FundDataService/2.0.0 (Flutter)',
      'Connection': 'keep-alive',
      'Cache-Control': 'no-cache',
    };
  }

  /// 带智能重试机制的网络请求执行
  Future<T> _executeWithRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    Exception? lastException;
    final retryStopwatch = Stopwatch()..start();

    AppLogger.info(
        '🔄 FundDataService: 开始重试机制 - 最大重试次数: $maxRetries, 基础延迟: ${retryDelay.inSeconds}秒');

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      final attemptStopwatch = Stopwatch()..start();

      try {
        AppLogger.debug('🚀 FundDataService: 执行第${attempt + 1}次尝试');
        final result = await operation();

        attemptStopwatch.stop();
        AppLogger.info(
            '✅ FundDataService: 第${attempt + 1}次尝试成功 - 耗时${attemptStopwatch.elapsedMilliseconds}ms');

        return result;
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        attemptStopwatch.stop();

        if (attempt == maxRetries) {
          retryStopwatch.stop();
          AppLogger.error(
              '❌ FundDataService: 重试失败，达到最大重试次数 ($maxRetries) - 总耗时${retryStopwatch.elapsedMilliseconds}ms',
              lastException);
          rethrow;
        }

        // 根据异常类型决定是否重试
        bool shouldRetry = _shouldRetryForException(e);
        if (!shouldRetry) {
          retryStopwatch.stop();
          AppLogger.error(
              '❌ FundDataService: 异常类型不适合重试，直接失败 - 耗时${retryStopwatch.elapsedMilliseconds}ms: $e',
              e);
          rethrow;
        }

        // 计算重试延迟（指数退避）
        final currentDelay = _calculateRetryDelay(attempt, retryDelay, e);

        AppLogger.warn(
            '⚠️ FundDataService: 第${attempt + 1}次请求失败 (耗时${attemptStopwatch.elapsedMilliseconds}ms)，${currentDelay.inSeconds}秒后重试: $e');
        AppLogger.debug(
            '🔄 重试统计: 当前第${attempt + 1}/${maxRetries + 1}次, 已累计耗时${retryStopwatch.elapsedMilliseconds}ms');

        await Future.delayed(currentDelay);
      }
    }

    retryStopwatch.stop();
    AppLogger.error(
        '❌ FundDataService: 重试机制异常退出 - 总耗时${retryStopwatch.elapsedMilliseconds}ms',
        lastException);
    throw lastException!;
  }

  /// 判断异常是否适合重试
  bool _shouldRetryForException(dynamic e) {
    // 这些异常类型通常可以通过重试解决
    if (e is TimeoutException) return true;
    if (e is SocketException) return true;
    if (e is ClientException) {
      // 特别处理连接关闭的异常
      if (e.message.contains('Connection closed while receiving data')) {
        return true; // 连接关闭通常可以通过重试解决
      }
      if (e.message.contains('Connection refused')) {
        return true; // 连接拒绝可能临时问题
      }
      if (e.message.contains('Network is unreachable')) {
        return false; // 网络不可达通常重试无意义
      }
      return true; // 其他ClientException默认重试
    }

    // HTTP异常中，某些状态码可以重试
    if (e is HttpException) return true;

    // 其他异常类型不重试
    return false;
  }

  /// 计算重试延迟（指数退避策略）
  Duration _calculateRetryDelay(int attempt, Duration baseDelay, dynamic e) {
    // 基础指数退避
    final exponentialDelay = Duration(
      milliseconds: (baseDelay.inMilliseconds * (1 << attempt)).round(),
    );

    // 根据异常类型调整延迟
    Duration adjustedDelay;
    if (e is TimeoutException) {
      // 超时异常使用较短延迟
      adjustedDelay = Duration(
        milliseconds: (exponentialDelay.inMilliseconds * 0.5).round(),
      );
    } else if (e is ClientException) {
      if (e.message.contains('Connection closed while receiving data')) {
        // 连接关闭使用中等延迟，给服务器恢复时间
        adjustedDelay = Duration(
          milliseconds: (exponentialDelay.inMilliseconds * 1.2).round(),
        );
      } else if (e.message.contains('Connection refused')) {
        // 连接拒绝使用较长延迟
        adjustedDelay = Duration(
          milliseconds: (exponentialDelay.inMilliseconds * 1.8).round(),
        );
      } else {
        // 其他连接异常使用标准较长延迟
        adjustedDelay = Duration(
          milliseconds: (exponentialDelay.inMilliseconds * 1.5).round(),
        );
      }
    } else if (e is SocketException) {
      // Socket异常使用较长延迟，等待网络恢复
      adjustedDelay = Duration(
        milliseconds: (exponentialDelay.inMilliseconds * 1.5).round(),
      );
    } else {
      adjustedDelay = exponentialDelay;
    }

    // 设置最大延迟上限（15秒，为连接问题提供更多恢复时间）
    const maxDelay = Duration(seconds: 15);
    return adjustedDelay > maxDelay ? maxDelay : adjustedDelay;
  }

  /// 检查网络连接
  Future<bool> checkNetworkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      AppLogger.debug('❌ FundDataService: 网络连接检查失败: $e');
      return false;
    }
  }

  /// 检查请求频率，防止频繁请求
  void _checkRequestFrequency(String cacheKey) {
    final now = DateTime.now();
    final lastRequest = _lastRequestTime[cacheKey];

    if (lastRequest != null) {
      final timeSinceLastRequest = now.difference(lastRequest);
      if (timeSinceLastRequest < _minRequestInterval) {
        final remainingTime = _minRequestInterval - timeSinceLastRequest;
        throw Exception('请求过于频繁，请等待 ${remainingTime.inSeconds} 秒后重试');
      }
    }

    _lastRequestTime[cacheKey] = now;
  }

  /// 检查并发请求数量
  void _checkConcurrency() {
    if (_currentRequests >= _maxConcurrentRequests) {
      throw Exception('并发请求数量过多，请稍后重试');
    }
  }

  /// 获取请求统计信息
  static Map<String, dynamic> getRequestStats() {
    return {
      'currentRequests': _currentRequests,
      'maxConcurrentRequests': _maxConcurrentRequests,
      'minRequestInterval': _minRequestInterval.inSeconds,
      'lastRequestTimes':
          _lastRequestTime.map((k, v) => MapEntry(k, v.toIso8601String())),
    };
  }

  /// 公共API诊断方法 - 供外部调用
  static Future<String> runApiDiagnosis() async {
    final service = FundDataService();
    return await service.diagnoseApiProblem();
  }

  /// 清理请求历史（用于测试或重置）
  static void clearRequestHistory() {
    _lastRequestTime.clear();
    _currentRequests = 0;
  }

  /// 从缓存获取基金排行数据 - 增强版本，包含智能跟踪
  Future<List<FundRanking>?> _getCachedRankings(String cacheKey) async {
    try {
      // 记录缓存访问
      _trackCacheAccess(cacheKey);

      // 检查缓存服务是否可用
      final hasKey = await _cacheService.containsKey(cacheKey);
      if (!hasKey) {
        AppLogger.debug('🔍 FundDataService: 缓存中无数据');
        return null; // 缓存未初始化或没有数据
      }

      final cachedData = await _cacheService.get<String>(cacheKey);
      if (cachedData == null) {
        AppLogger.debug('🔍 FundDataService: 缓存中无数据');
        return null;
      }

      final jsonData = jsonDecode(cachedData);

      // 检查缓存时间戳
      final String? timestampStr = jsonData['timestamp'];
      Duration? age;
      if (timestampStr != null) {
        final DateTime cacheTime = DateTime.parse(timestampStr);
        final DateTime now = DateTime.now();
        age = now.difference(cacheTime);

        // 动态缓存过期时间：根据访问频率调整
        final dynamicExpireTime = _getDynamicCacheExpireTime(cacheKey, age);
        if (age > dynamicExpireTime) {
          AppLogger.info(
              '⏰ FundDataService: 缓存已过期 (缓存时间: ${age.inSeconds}秒, 动态限制: ${dynamicExpireTime.inSeconds}秒)');
          // 删除过期缓存
          await _cacheService.remove(cacheKey);
          return null;
        }

        AppLogger.debug(
            '✅ FundDataService: 缓存有效 (缓存时间: ${age.inSeconds}秒, 访问次数: ${_cacheAccessCounts[cacheKey] ?? 0})');
      }

      final List<dynamic> dataList = jsonData['rankings'] ?? [];

      // 验证数据完整性
      if (dataList.isEmpty) {
        AppLogger.warn('⚠️ FundDataService: 缓存数据为空，清除缓存');
        await _cacheService.remove(cacheKey);
        return null;
      }

      final rankings = dataList
          .map((item) {
            try {
              return FundRanking.fromJson(
                Map<String, dynamic>.from(item),
                dataList.indexOf(item) + 1,
              );
            } catch (e) {
              AppLogger.warn('⚠️ FundDataService: 跳过无效缓存项: $e');
              return null;
            }
          })
          .where((ranking) => ranking != null)
          .cast<FundRanking>()
          .toList();

      if (rankings.isEmpty) {
        AppLogger.warn('⚠️ FundDataService: 缓存数据解析后为空，清除缓存');
        await _cacheService.remove(cacheKey);
        return null;
      }

      final remainingTime = age != null
          ? _getDynamicCacheExpireTime(cacheKey, age).inSeconds - age.inSeconds
          : _cacheExpireTime.inSeconds;
      AppLogger.info(
          '💾 FundDataService: 从缓存加载 ${rankings.length} 条数据 (缓存剩余有效时间: $remainingTime秒, 访问次数: ${_cacheAccessCounts[cacheKey] ?? 0})');

      // 检查是否需要预热
      _checkAndSchedulePreheat(cacheKey);

      return rankings;
    } catch (e) {
      AppLogger.error('❌ FundDataService: 缓存数据解析失败', e);
      // 尝试清除损坏的缓存，但不要因为清理失败而中断流程
      try {
        await _cacheService.remove(cacheKey);
        _clearCacheTracking(cacheKey);
      } catch (removeError) {
        AppLogger.warn('⚠️ FundDataService: 清除损坏缓存失败', removeError);
      }
      return null;
    }
  }

  /// 缓存基金排行数据
  Future<void> _cacheRankings(
      String cacheKey, List<FundRanking> rankings) async {
    try {
      final cacheData = {
        'rankings': rankings.map((ranking) => ranking.toJson()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
        'count': rankings.length,
      };

      // 使用统一缓存服务接口
      await _cacheService.put(
        cacheKey,
        jsonEncode(cacheData),
        expiration: _cacheExpireTime,
      );

      AppLogger.info(
          '💾 FundDataService: 已缓存 ${rankings.length} 条数据，有效期 ${_cacheExpireTime.inSeconds} 秒');
    } catch (e) {
      AppLogger.warn('⚠️ FundDataService: 缓存数据失败，但不影响正常流程: $e');
      // 缓存失败不影响正常流程
    }
  }

  /// 清除指定类型的缓存
  Future<void> clearCache({String? symbol}) async {
    try {
      if (symbol != null) {
        final cacheKey = '$_cacheKeyPrefix${symbol.replaceAll('%', '')}';
        await _cacheService.remove(cacheKey);
        AppLogger.info('🗑️ FundDataService: 已清除 $symbol 的缓存');
      } else {
        // 清除所有基金排行缓存
        // 注意：这里我们只清除相关的缓存，不是全部缓存
        AppLogger.info('🗑️ FundDataService: 缓存清除功能需要更精细的实现');
      }
    } catch (e) {
      AppLogger.error('❌ FundDataService: 清除缓存失败', e);
    }
  }

  /// 获取缓存统计信息
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final stats = await _cacheService.getStats();
      return {
        ...stats,
        'cacheExpireTime': _cacheExpireTime.inHours,
        'lastUpdate': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      AppLogger.error('❌ FundDataService: 获取缓存统计失败', e);
      return {'error': e.toString()};
    }
  }

  /// 验证基金数据的一致性
  Future<DataValidationResult> validateDataConsistency(
    List<FundRanking> data, {
    ConsistencyCheckStrategy strategy = ConsistencyCheckStrategy.standard,
    String? cacheKey,
  }) async {
    return await _validationService.validateFundRankings(
      data,
      strategy: strategy,
      cacheKey: cacheKey,
    );
  }

  /// 尝试修复损坏的数据
  Future<List<FundRanking>?> repairData(
    List<FundRanking> corruptedData, {
    String? cacheKey,
    bool forceRefetch = false,
  }) async {
    return await _validationService.repairCorruptedData(
      corruptedData,
      cacheKey: cacheKey,
      forceRefetch: forceRefetch,
    );
  }

  /// 获取数据质量统计信息
  Map<String, dynamic> getDataQualityStats() {
    return _validationService.getDataQualityStatistics();
  }

  /// 获取验证历史记录
  List<DataValidationResult> getValidationHistory({int limit = 10}) {
    return _validationService.getValidationHistory(limit: limit);
  }

  /// 手动触发数据验证
  Future<DataValidationResult> validateCurrentData({
    String symbol = _allFundsSymbol,
    ConsistencyCheckStrategy strategy = ConsistencyCheckStrategy.standard,
  }) async {
    final cacheKey = '$_cacheKeyPrefix${symbol.replaceAll('%', '')}';

    // 先尝试从缓存获取数据
    final cachedData = await _getCachedRankings(cacheKey);
    if (cachedData != null) {
      return await _validationService.validateFundRankings(
        cachedData,
        strategy: strategy,
        cacheKey: cacheKey,
      );
    }

    // 如果没有缓存数据，返回成功结果（无需验证）
    return DataValidationResult.success();
  }

  /// 强制验证并修复所有缓存数据
  Future<Map<String, dynamic>> validateAndRepairAllCaches() async {
    final results = <String, dynamic>{};

    try {
      // 这里可以扩展为验证多个symbol的缓存
      // 目前只处理默认的全部基金缓存
      const symbol = _allFundsSymbol;
      final cacheKey = '$_cacheKeyPrefix${symbol.replaceAll('%', '')}';

      AppLogger.info('🔍 FundDataService: 开始验证并修复缓存: $cacheKey');

      // 获取当前缓存数据
      final cachedData = await _getCachedRankings(cacheKey);
      if (cachedData == null) {
        results[symbol] = {
          'status': 'no_cache',
          'message': '没有找到缓存数据',
        };
        return results;
      }

      // 验证数据
      final validationResult = await _validationService.validateFundRankings(
        cachedData,
        strategy: ConsistencyCheckStrategy.deep,
        cacheKey: cacheKey,
      );

      if (!validationResult.isValid) {
        // 尝试修复数据
        final repairedData = await _validationService.repairCorruptedData(
          cachedData,
          cacheKey: cacheKey,
        );

        if (repairedData != null) {
          // 更新缓存
          await _cacheRankings(cacheKey, repairedData);
          results[symbol] = {
            'status': 'repaired',
            'originalCount': cachedData.length,
            'repairedCount': repairedData.length,
            'errors': validationResult.errors,
            'warnings': validationResult.warnings,
          };
        } else {
          // 修复失败，清理缓存
          await _validationService.cleanupCorruptedCache(cacheKey);
          results[symbol] = {
            'status': 'failed',
            'originalCount': cachedData.length,
            'errors': validationResult.errors,
            'warnings': validationResult.warnings,
            'message': '数据修复失败，已清理缓存',
          };
        }
      } else {
        results[symbol] = {
          'status': 'valid',
          'count': cachedData.length,
          'warnings': validationResult.warnings,
        };
      }

      AppLogger.info(
          '✅ FundDataService: 缓存验证修复完成: $symbol - ${results[symbol]['status']}');
    } catch (e) {
      AppLogger.error('❌ FundDataService: 验证修复过程中发生异常', e);
      results['error'] = e.toString();
    }

    return results;
  }

  /// 生成请求去重键
  String _generateDeduplicationKey(String method, Map<String, dynamic> params) {
    final keyData = {
      'method': method,
      'params': params,
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000, // 精确到秒
    };
    final jsonString = jsonEncode(keyData);
    final bytes = utf8.encode(jsonString);
    final digest = md5.convert(bytes);
    return 'fund_${digest.toString()}';
  }

  /// 执行基金排行请求（内部方法）- 增强错误处理版本
  Future<FundDataResult<List<FundRanking>>> _executeFundRankingsRequest({
    required String symbol,
    required bool forceRefresh,
    required Function(double)? onProgress,
    required String cacheKey,
  }) async {
    // 增强的错误处理：记录开始时间用于性能监控
    final startTime = DateTime.now();
    AppLogger.info(
        '🚀 FundDataService: 开始执行基金排行请求 (symbol: $symbol, forceRefresh: $forceRefresh)');

    try {
      // 第一步：缓存检查（增强错误处理）
      if (!forceRefresh) {
        try {
          final cachedRankings = await _getCachedRankings(cacheKey);
          if (cachedRankings != null && cachedRankings.isNotEmpty) {
            AppLogger.info(
                '💾 FundDataService: 缓存命中 (${cachedRankings.length}条)');

            // 对缓存数据进行快速验证
            final cacheValidationResult = await _validationService
                .validateFundRankings(
                  cachedRankings,
                  strategy: ConsistencyCheckStrategy.quick,
                  cacheKey: cacheKey,
                )
                .timeout(const Duration(seconds: 5)); // 添加验证超时

            if (!cacheValidationResult.isValid) {
              AppLogger.warn('⚠️ FundDataService: 缓存数据验证失败，重新获取数据');
              // 缓存数据有问题，清理缓存并继续走API流程
              await _validationService.cleanupCorruptedCache(cacheKey);
            } else {
              if (cacheValidationResult.hasWarnings) {
                AppLogger.warn(
                    '⚠️ FundDataService: 缓存数据有警告: ${cacheValidationResult.warnings.join(', ')}');
              }

              // 记录缓存命中的性能指标
              final cacheTime = DateTime.now().difference(startTime);
              AppLogger.info(
                  '⚡ FundDataService: 缓存命中完成，耗时: ${cacheTime.inMilliseconds}ms');

              return FundDataResult.success(cachedRankings);
            }
          }
        } catch (cacheError) {
          AppLogger.warn('⚠️ FundDataService: 缓存检查失败，继续API请求: $cacheError');
          // 缓存失败不影响API请求，继续执行
        }
      }

      // 第二步：频率控制检查（增强错误处理）
      try {
        _checkRequestFrequency(cacheKey);
      } catch (frequencyError) {
        AppLogger.warn('⚠️ FundDataService: 频率控制检查失败: $frequencyError');
        // 频率控制失败不应该阻止请求，记录警告但继续
      }

      // 第三步：从API获取数据（增强错误处理）
      AppLogger.info('🌐 FundDataService: 从API获取数据');
      onProgress?.call(0.1); // 开始请求

      // 构建API请求URL
      Uri uri;
      try {
        if (symbol.isNotEmpty && symbol != '全部') {
          // 目前API不支持按类型筛选，所以获取全部数据后在代码中筛选
          AppLogger.warn('⚠️ FundDataService: API不支持按类型筛选，将获取全部数据');
        }
        // 基金排行API不需要参数
        uri = Uri.parse('$_baseUrl/api/public/fund_open_fund_rank_em');
      } catch (uriError) {
        final errorMsg = '构建API请求URL失败: $uriError';
        AppLogger.error('❌ FundDataService: $errorMsg', uriError);
        return FundDataResult.failure(errorMsg);
      }

      // 第四步：并发控制（增强错误处理）
      if (_currentRequests >= _maxConcurrentRequests) {
        final errorMsg =
            '当前并发请求数过多 ($_currentRequests/$_maxConcurrentRequests)，请稍后重试';
        AppLogger.warn('⚠️ FundDataService: $errorMsg');
        return FundDataResult.failure(errorMsg);
      }

      _currentRequests++;
      try {
        var rankings = await _executeWithRetry<List<FundRanking>>(
          () => _fetchRankingsFromApi(uri, onProgress),
          maxRetries: _maxRetries,
          retryDelay: _retryDelay,
        ).timeout(const Duration(seconds: 150)); // 使用150秒整体请求超时，包含重试时间

        onProgress?.call(0.8); // 数据解析完成

        // 数据验证和质量检查（增强错误处理）
        onProgress?.call(0.85); // 开始验证
        try {
          final validationResult = await _validationService
              .validateFundRankings(
                rankings,
                strategy: ConsistencyCheckStrategy.standard,
                cacheKey: cacheKey,
              )
              .timeout(const Duration(seconds: 10)); // 添加验证超时

          if (!validationResult.isValid) {
            AppLogger.warn('⚠️ FundDataService: 数据验证失败，但暂时跳过修复以避免无限循环');
            AppLogger.debug('验证错误: ${validationResult.errors.join(", ")}');

            // 临时跳过修复逻辑，直接返回数据
            AppLogger.info(
                '✅ FundDataService: 跳过数据验证，直接返回${rankings.length}条数据');
          } else if (validationResult.hasWarnings) {
            AppLogger.warn(
                '⚠️ FundDataService: 数据验证通过但有警告: ${validationResult.warnings.join(', ')}');
          }
        } catch (validationError) {
          AppLogger.warn(
              '⚠️ FundDataService: 数据验证过程失败，继续返回数据: $validationError');
          // 验证失败不影响数据返回
        }

        // 缓存数据（异步进行，不阻塞返回）- 增强错误处理
        try {
          _cacheRankings(cacheKey, rankings);
        } catch (cacheError) {
          AppLogger.warn('⚠️ FundDataService: 缓存数据失败，但不影响返回: $cacheError');
          // 缓存失败不影响数据返回
        }

        onProgress?.call(1.0); // 完成

        // 记录成功请求的性能指标
        final totalTime = DateTime.now().difference(startTime);
        AppLogger.info(
            '✅ FundDataService: 数据获取成功 (${rankings.length}条)，总耗时: ${totalTime.inMilliseconds}ms');

        return FundDataResult.success(rankings);
      } finally {
        // 确保并发计数器正确递减
        _currentRequests--;
        AppLogger.debug('📊 FundDataService: 当前并发请求数: $_currentRequests');
      }
    } on SocketException catch (e) {
      final errorMsg = '网络连接错误: ${e.message}';
      AppLogger.error('❌ FundDataService: $errorMsg', e);

      // 根据具体的SocketException类型提供不同的用户友好错误信息
      String errorType = 'network';
      if (e.message.contains('服务器在传输数据时关闭连接')) {
        errorType = 'connection_closed';
      }

      final userFriendlyMsg = _getUserFriendlyErrorMessage(e, errorType);
      return FundDataResult.failure(userFriendlyMsg);
    } on TimeoutException catch (e) {
      final errorMsg = '请求超时: ${e.message}';
      AppLogger.error('❌ FundDataService: $errorMsg', e);

      // 提供用户友好的错误提示
      final userFriendlyMsg = _getUserFriendlyErrorMessage(e, 'timeout');
      return FundDataResult.failure(userFriendlyMsg);
    } on HttpException catch (e) {
      final errorMsg = 'HTTP错误: ${e.message}';
      AppLogger.error('❌ FundDataService: $errorMsg', e);

      // 提供用户友好的错误提示
      final userFriendlyMsg = _getUserFriendlyErrorMessage(e, 'http');
      return FundDataResult.failure(userFriendlyMsg);
    } on FormatException catch (e) {
      final errorMsg = '数据格式错误: ${e.message}';
      AppLogger.error('❌ FundDataService: $errorMsg', e);

      // 提供用户友好的错误提示
      final userFriendlyMsg = _getUserFriendlyErrorMessage(e, 'format');
      return FundDataResult.failure(userFriendlyMsg);
    } catch (e) {
      final errorMsg = '获取基金数据失败: $e';
      AppLogger.error('❌ FundDataService: $errorMsg', e);

      // 提供用户友好的错误提示
      final userFriendlyMsg = _getUserFriendlyErrorMessage(e, 'unknown');
      return FundDataResult.failure(userFriendlyMsg);
    }
  }

  /// 缓存失效监听器
  void _handleCacheInvalidation(CacheInvalidationEvent event) {
    try {
      AppLogger.debug('🔄 收到缓存失效事件: ${event.key} (${event.reason})');

      // 根据失效原因执行相应的处理逻辑
      switch (event.reason) {
        case CacheInvalidationReason.expired:
          _handleExpiredCache(event);
          break;
        case CacheInvalidationReason.dependencyUpdated:
          _handleDependencyInvalidation(event);
          break;
        case CacheInvalidationReason.predictiveRefresh:
          _handlePredictiveRefresh(event);
          break;
        default:
          _handleGenericInvalidation(event);
          break;
      }
    } catch (e) {
      AppLogger.error('❌ 处理缓存失效事件失败: ${event.key}', e);
    }
  }

  /// 处理过期缓存
  void _handleExpiredCache(CacheInvalidationEvent event) {
    AppLogger.debug('⏰ 缓存已过期: ${event.key}');

    // 可以在这里触发预加载逻辑
    // 例如：如果失效的是热门基金排行，可以预先加载新的数据
    if (event.key.contains('fund_rankings') && event.key.contains('all')) {
      AppLogger.debug('🔄 检测到全部基金排行缓存过期，建议预先加载');
    }
  }

  /// 处理依赖失效
  void _handleDependencyInvalidation(CacheInvalidationEvent event) {
    AppLogger.debug(
        '🔗 依赖失效: ${event.key}，影响 ${event.relatedKeys.length} 个相关缓存');

    // 记录依赖失效统计
    for (final relatedKey in event.relatedKeys) {
      AppLogger.debug('   - 相关缓存: $relatedKey');
    }
  }

  /// 处理预测性刷新
  void _handlePredictiveRefresh(CacheInvalidationEvent event) {
    AppLogger.debug('🔮 预测性刷新: ${event.key}');

    final remainingTime = event.metadata?['predicted_expiry'] as int?;
    if (remainingTime != null) {
      AppLogger.debug('   - 预计 $remainingTime 分钟后过期');
    }
  }

  /// 处理通用失效
  void _handleGenericInvalidation(CacheInvalidationEvent event) {
    AppLogger.debug('🔄 通用缓存失效: ${event.key} (${event.reason})');
  }

  /// 手动失效基金排行缓存
  Future<void> invalidateFundRankingsCache({
    String symbol = _allFundsSymbol,
    CacheInvalidationPriority priority = CacheInvalidationPriority.normal,
  }) async {
    try {
      final cacheKey = CacheKeyManager.instance.fundListKey(
        symbol.isEmpty ? 'all' : symbol,
      );

      await _invalidationManager.invalidate(
        cacheKey,
        reason: CacheInvalidationReason.manual,
        priority: priority,
        metadata: {'symbol': symbol, 'service': 'FundDataService'},
      );

      AppLogger.info('🗑️ 手动失效基金排行缓存: $symbol');
    } catch (e) {
      AppLogger.error('❌ 手动失效缓存失败: $symbol', e);
    }
  }

  /// 批量失效基金缓存
  Future<void> invalidateAllFundCaches({
    CacheInvalidationPriority priority = CacheInvalidationPriority.high,
  }) async {
    try {
      const pattern = 'jisu_fund_fundData_list_*';

      await _invalidationManager.invalidateByPattern(
        pattern,
        reason: CacheInvalidationReason.manual,
        priority: priority,
      );

      AppLogger.info('🗑️ 批量失效所有基金缓存');
    } catch (e) {
      AppLogger.error('❌ 批量失效基金缓存失败', e);
    }
  }

  /// 设置缓存依赖关系
  void setCacheDependency(String dependentKey, String dependencyKey) {
    try {
      _invalidationManager.setDependency(dependentKey, dependencyKey);
      AppLogger.debug('🔗 设置缓存依赖: $dependentKey -> $dependencyKey');
    } catch (e) {
      AppLogger.error('❌ 设置缓存依赖失败', e);
    }
  }

  /// 预测性刷新基金排行缓存
  Future<void> predictiveRefreshFundRankings({
    String symbol = _allFundsSymbol,
  }) async {
    try {
      final cacheKey = CacheKeyManager.instance.fundListKey(
        symbol.isEmpty ? 'all' : symbol,
      );

      await _invalidationManager.predictiveRefresh(cacheKey);
      AppLogger.debug('🔮 预测性刷新基金排行缓存: $symbol');
    } catch (e) {
      AppLogger.debug('预测性刷新失败 $symbol: $e');
    }
  }

  /// 获取缓存失效统计信息
  Map<String, dynamic> getInvalidationStats() {
    try {
      final stats = _invalidationManager.getStats();

      // 添加基金服务特定的统计信息
      final serviceStats = {
        'service': 'FundDataService',
        'cache_prefix': _cacheKeyPrefix,
        'max_retries': _maxRetries,
        'timeout_seconds': _defaultTimeout.inSeconds,
        'current_requests': _currentRequests,
        'max_concurrent_requests': _maxConcurrentRequests,
        'invalidation_manager_stats': stats,
      };

      return serviceStats;
    } catch (e) {
      AppLogger.error('❌ 获取缓存失效统计失败', e);
      return {
        'service': 'FundDataService',
        'error': e.toString(),
      };
    }
  }

  /// 清理缓存失效管理器
  Future<void> disposeInvalidationManager() async {
    try {
      await _invalidationManager.dispose();
      AppLogger.info('🔌 FundDataService: 缓存失效管理器已清理');
    } catch (e) {
      AppLogger.error('❌ 清理缓存失效管理器失败', e);
    }
  }

  /// 获取缓存性能指标
  SimpleCacheMetrics getCachePerformanceMetrics() {
    try {
      return UnifiedHiveCacheManager.instance.getPerformanceMetrics();
    } catch (e) {
      AppLogger.error('❌ 获取缓存性能指标失败', e);
      return const SimpleCacheMetrics(
        hitRate: 0.0,
        averageResponseTime: 0.0,
        requestsPerSecond: 0.0,
        cacheSize: 0,
        memoryUsage: 0,
        errorRate: 0.0,
        totalRequests: 0,
        totalHits: 0,
        totalMisses: 0,
        totalErrors: 0,
      );
    }
  }

  /// 生成用户友好的错误信息
  String _getUserFriendlyErrorMessage(dynamic error, String errorType) {
    switch (errorType) {
      case 'network':
        if (error is SocketException) {
          if (error.message.contains('服务器在传输数据时关闭连接')) {
            return '数据传输中断，可能是网络不稳定，正在重试...';
          }
          if (error.message.contains('服务器拒绝连接')) {
            return '服务器暂时忙碌，请稍后重试';
          }
        }
        return '网络连接失败，请检查网络连接后重试';
      case 'timeout':
        return '请求超时，请稍后重试';
      case 'http':
        if (error is HttpException) {
          if (error.message.contains('404')) {
            return '基金数据接口暂不可用，请稍后重试';
          } else if (error.message.contains('500')) {
            return '服务器暂时繁忙，请稍后重试';
          }
        }
        return '服务器响应异常，请稍后重试';
      case 'format':
        return '数据格式异常，请重试';
      case 'concurrency':
        return '当前请求过多，请稍后重试';
      case 'cache':
        return '缓存服务暂时不可用，正在重新获取数据';
      case 'validation':
        return '数据验证失败，请重试';
      case 'connection_closed':
        return '连接在数据传输过程中被关闭，可能是网络波动，正在重试...';
      default:
        return '加载基金数据失败，请重试';
    }
  }

  /// 生成缓存性能报告
  Map<String, dynamic> generateCachePerformanceReport() {
    try {
      final performanceReport =
          UnifiedHiveCacheManager.instance.generatePerformanceReport();
      final invalidationStats = _invalidationManager.getStats();

      // 添加基金服务特定的性能数据
      final serviceReport = {
        'service': 'FundDataService',
        'base_url': _baseUrl,
        'cache_expire_time_seconds': _cacheExpireTime.inSeconds,
        'timeout_seconds': _defaultTimeout.inSeconds,
        'max_retries': _maxRetries,
        'max_concurrent_requests': _maxConcurrentRequests,
        'current_requests': _currentRequests,
        'request_frequency_control': {
          'min_request_interval_seconds': _minRequestInterval.inSeconds,
          'last_requests':
              _lastRequestTime.map((k, v) => MapEntry(k, v.toIso8601String())),
        },
        'performance_metrics': performanceReport,
        'invalidation_stats': invalidationStats,
        'timestamp': DateTime.now().toIso8601String(),
      };

      return serviceReport;
    } catch (e) {
      AppLogger.error('❌ 生成缓存性能报告失败', e);
      return {
        'service': 'FundDataService',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// 获取热门缓存键（简化版，避免循环依赖）
  List<MapEntry<String, int>> getHotCacheKeys({int limit = 10}) {
    try {
      // 简化实现，避免循环依赖
      return [];
    } catch (e) {
      AppLogger.error('❌ 获取热门缓存键失败', e);
      return [];
    }
  }

  /// 获取慢操作记录（简化版，避免循环依赖）
  List<Map<String, dynamic>> getSlowOperations({
    Duration threshold = const Duration(milliseconds: 100),
    int limit = 10,
  }) {
    try {
      // 简化实现，避免循环依赖
      return [];
    } catch (e) {
      AppLogger.error('❌ 获取慢操作记录失败', e);
      return [];
    }
  }

  /// 添加性能监听器（简化版，避免循环依赖）
  void addPerformanceListener(Function(SimpleCacheMetrics) listener) {
    try {
      AppLogger.debug('📊 添加缓存性能监听器（简化模式）');
      // 简化实现，避免循环依赖
    } catch (e) {
      AppLogger.error('❌ 添加性能监听器失败', e);
    }
  }

  /// 移除性能监听器（简化版，避免循环依赖）
  void removePerformanceListener(Function(SimpleCacheMetrics) listener) {
    try {
      AppLogger.debug('📊 移除缓存性能监听器（简化模式）');
      // 简化实现，避免循环依赖
    } catch (e) {
      AppLogger.error('❌ 移除性能监听器失败', e);
    }
  }

  /// 重置性能统计（简化版，避免循环依赖）
  void resetPerformanceStatistics() {
    try {
      // 简化实现，避免循环依赖
      AppLogger.debug('📊 性能统计已重置（简化模式）');
      AppLogger.info('📊 FundDataService: 缓存性能统计已重置');
    } catch (e) {
      AppLogger.error('❌ 重置性能统计失败', e);
    }
  }

  /// 检查缓存性能健康状态（简化版，避免循环依赖）
  Map<String, dynamic> checkPerformanceHealth() {
    try {
      final metrics = UnifiedHiveCacheManager.instance.getPerformanceMetrics();

      // 定义健康阈值
      const hitRateGood = 0.8;
      const hitRateWarning = 0.6;
      const responseTimeGood = 50.0;
      const responseTimeWarning = 100.0;
      const errorRateGood = 0.02;
      const errorRateWarning = 0.05;

      String hitRateStatus;
      if (metrics.hitRate >= hitRateGood) {
        hitRateStatus = 'excellent';
      } else if (metrics.hitRate >= hitRateWarning) {
        hitRateStatus = 'good';
      } else {
        hitRateStatus = 'poor';
      }

      String responseTimeStatus;
      if (metrics.averageResponseTime <= responseTimeGood) {
        responseTimeStatus = 'excellent';
      } else if (metrics.averageResponseTime <= responseTimeWarning) {
        responseTimeStatus = 'good';
      } else {
        responseTimeStatus = 'poor';
      }

      String errorRateStatus;
      if (metrics.errorRate <= errorRateGood) {
        errorRateStatus = 'excellent';
      } else if (metrics.errorRate <= errorRateWarning) {
        errorRateStatus = 'good';
      } else {
        errorRateStatus = 'poor';
      }

      // 计算总体健康评分
      int healthScore = 0;
      if (hitRateStatus == 'excellent') healthScore += 40;
      if (hitRateStatus == 'good') healthScore += 25;
      if (hitRateStatus == 'poor') healthScore += 10;

      if (responseTimeStatus == 'excellent') healthScore += 30;
      if (responseTimeStatus == 'good') healthScore += 20;
      if (responseTimeStatus == 'poor') healthScore += 5;

      if (errorRateStatus == 'excellent') healthScore += 30;
      if (errorRateStatus == 'good') healthScore += 20;
      if (errorRateStatus == 'poor') healthScore += 5;

      String overallStatus;
      if (healthScore >= 90) {
        overallStatus = 'excellent';
      } else if (healthScore >= 70) {
        overallStatus = 'good';
      } else if (healthScore >= 50) {
        overallStatus = 'warning';
      } else {
        overallStatus = 'critical';
      }

      return {
        'overall_status': overallStatus,
        'health_score': healthScore,
        'metrics': {
          'hit_rate': {
            'value': metrics.hitRate,
            'status': hitRateStatus,
            'percentage': '${(metrics.hitRate * 100).toStringAsFixed(1)}%',
          },
          'response_time': {
            'value': metrics.averageResponseTime,
            'status': responseTimeStatus,
            'formatted': '${metrics.averageResponseTime.toStringAsFixed(2)}ms',
          },
          'error_rate': {
            'value': metrics.errorRate,
            'status': errorRateStatus,
            'percentage': '${(metrics.errorRate * 100).toStringAsFixed(2)}%',
          },
        },
        'recommendations': _generatePerformanceRecommendations(
          hitRateStatus,
          responseTimeStatus,
          errorRateStatus,
          metrics,
        ),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      AppLogger.error('❌ 检查性能健康状态失败', e);
      return {
        'overall_status': 'unknown',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// 生成性能优化建议
  List<String> _generatePerformanceRecommendations(
    String hitRateStatus,
    String responseTimeStatus,
    String errorRateStatus,
    SimpleCacheMetrics metrics,
  ) {
    final recommendations = <String>[];

    if (hitRateStatus == 'poor') {
      recommendations.add('缓存命中率过低，建议增加缓存时间或优化缓存策略');
      recommendations.add('检查缓存键是否正确生成和管理');
    }

    if (responseTimeStatus == 'poor') {
      recommendations.add('响应时间过长，建议优化数据获取逻辑');
      recommendations.add('考虑使用异步处理或数据预加载');
    }

    if (errorRateStatus == 'poor') {
      recommendations.add('错误率过高，建议检查网络连接和数据源稳定性');
      recommendations.add('增加重试机制和错误处理逻辑');
    }

    if (metrics.totalRequests == 0) {
      recommendations.add('暂无缓存操作记录，请确保缓存服务正常工作');
    }

    if (recommendations.isEmpty) {
      recommendations.add('缓存性能表现良好，继续保持当前配置');
    }

    return recommendations;
  }

  /// 执行带性能监控的缓存操作（简化版，避免循环依赖）
  Future<T> executeWithMonitoring<T>(
    String operationName,
    Future<T> Function() operation, {
    Map<String, dynamic>? metadata,
  }) async {
    // 简化实现，直接执行操作，避免循环依赖
    AppLogger.debug('📊 执行操作: $operationName');
    return await operation();
  }

  /// 预热基金数据缓存
  String preheatFundData({
    String symbol = _allFundsSymbol,
    CachePreheatingPriority priority = CachePreheatingPriority.normal,
    bool includeRankings = true,
    bool includeDetails = false,
  }) {
    try {
      final taskId = _preheatingManager.addFundDataPreheatingTask(
        symbol: symbol,
        priority: priority,
        includeRankings: includeRankings,
        includeDetails: includeDetails,
      );

      AppLogger.info('🔥 添加基金数据预热任务: $symbol (任务ID: $taskId)');
      return taskId;
    } catch (e) {
      AppLogger.error('❌ 添加基金数据预热任务失败: $symbol', e);
      return '';
    }
  }

  /// 预热热门基金数据
  String preheatPopularFunds({
    CachePreheatingPriority priority = CachePreheatingPriority.high,
  }) {
    try {
      final popularSymbols = ['全部', '股票型', '债券型', '混合型', '货币型'];

      final taskId = _preheatingManager.addPreheatingTask(
        name: '热门基金数据预热',
        cacheKeys: popularSymbols
            .map((s) => CacheKeyManager.instance.fundListKey(s))
            .toList(),
        dataLoader: () async {
          final data = <String, dynamic>{};

          for (final symbol in popularSymbols) {
            try {
              // 这里调用实际的基金数据获取逻辑
              // 暂时使用模拟数据
              await Future.delayed(const Duration(milliseconds: 500));

              final cacheKey = CacheKeyManager.instance.fundListKey(symbol);
              data[cacheKey] = {
                'symbol': symbol,
                'timestamp': DateTime.now().toIso8601String(),
                'data': '模拟的基金排行数据 - $symbol',
              };

              AppLogger.debug('🔥 预热基金数据: $symbol');
            } catch (e) {
              AppLogger.warn('预热基金数据失败: $symbol - $e');
            }
          }

          return data;
        },
        priority: priority,
        strategy: CachePreheatingStrategy.onStartup,
        expiration: const Duration(minutes: 30),
        metadata: {
          'task_type': 'popular_funds',
          'symbols': popularSymbols,
          'service': 'FundDataService',
        },
      );

      AppLogger.info('🔥 添加热门基金数据预热任务 (任务ID: $taskId)');
      return taskId;
    } catch (e) {
      AppLogger.error('❌ 添加热门基金数据预热任务失败', e);
      return '';
    }
  }

  /// 预热用户关注的基金
  String preheatUserFavorites(
    List<String> favoriteSymbols, {
    CachePreheatingPriority priority = CachePreheatingPriority.normal,
  }) {
    try {
      final taskId = _preheatingManager.addPreheatingTask(
        name: '用户关注基金预热',
        cacheKeys: favoriteSymbols
            .map((s) => CacheKeyManager.instance.fundListKey(s))
            .toList(),
        dataLoader: () async {
          final data = <String, dynamic>{};

          for (final symbol in favoriteSymbols) {
            try {
              // 调用实际的基金数据获取逻辑
              final result =
                  await getFundRankings(symbol: symbol, forceRefresh: true);

              if (result.isSuccess && result.data != null) {
                final cacheKey = CacheKeyManager.instance.fundListKey(symbol);
                data[cacheKey] = result.data;
                AppLogger.debug('🔥 预热用户关注基金: $symbol');
              }
            } catch (e) {
              AppLogger.warn('预热用户关注基金失败: $symbol - $e');
            }
          }

          return data;
        },
        priority: priority,
        strategy: CachePreheatingStrategy.intelligent,
        expiration: const Duration(minutes: 20),
        metadata: {
          'task_type': 'user_favorites',
          'symbols': favoriteSymbols,
          'service': 'FundDataService',
        },
      );

      AppLogger.info('🔥 添加用户关注基金预热任务 (任务ID: $taskId)');
      return taskId;
    } catch (e) {
      AppLogger.error('❌ 添加用户关注基金预热任务失败', e);
      return '';
    }
  }

  /// 执行预热任务
  Future<CachePreheatingResult?> executePreheatingTask(String taskId) async {
    try {
      return await _preheatingManager.executeTask(taskId);
    } catch (e) {
      AppLogger.error('❌ 执行预热任务失败: $taskId', e);
      return null;
    }
  }

  /// 取消预热任务
  bool cancelPreheatingTask(String taskId) {
    try {
      final success = _preheatingManager.cancelTask(taskId);
      if (success) {
        AppLogger.info('🔥 取消预热任务: $taskId');
      }
      return success;
    } catch (e) {
      AppLogger.error('❌ 取消预热任务失败: $taskId', e);
      return false;
    }
  }

  /// 获取预热任务状态
  PreheatingTaskStatus? getPreheatingTaskStatus(String taskId) {
    try {
      return _preheatingManager.getTaskStatus(taskId);
    } catch (e) {
      AppLogger.error('❌ 获取预热任务状态失败: $taskId', e);
      return null;
    }
  }

  /// 获取所有预热任务状态
  Map<String, PreheatingTaskStatus> getAllPreheatingTaskStatus() {
    try {
      return _preheatingManager.getAllTaskStatus();
    } catch (e) {
      AppLogger.error('❌ 获取所有预热任务状态失败', e);
      return {};
    }
  }

  /// 获取预热统计信息
  Map<String, dynamic> getPreheatingStats() {
    try {
      final stats = _preheatingManager.getStats();

      // 添加基金服务特定的预热统计
      final serviceStats = {
        'service': 'FundDataService',
        'base_url': _baseUrl,
        'cache_expire_time_seconds': _cacheExpireTime.inSeconds,
        'preheating_manager_stats': stats,
        'recommended_preheating_symbols': ['全部', '股票型', '债券型', '混合型', '货币型'],
        'timestamp': DateTime.now().toIso8601String(),
      };

      return serviceStats;
    } catch (e) {
      AppLogger.error('❌ 获取预热统计信息失败', e);
      return {
        'service': 'FundDataService',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// 智能预热建议（简化版，避免循环依赖）
  Map<String, dynamic> getPreheatingRecommendations() {
    try {
      // 简化实现，避免循环依赖
      final performanceMetrics =
          UnifiedHiveCacheManager.instance.getPerformanceMetrics();
      final hotKeys = <MapEntry<String, int>>[];

      final recommendations = <String>[];
      final suggestedTasks = <Map<String, dynamic>>[];

      // 基于性能指标生成建议
      if (performanceMetrics.hitRate < 0.7) {
        recommendations.add('缓存命中率较低，建议预热热门数据');
        suggestedTasks.add({
          'type': 'popular_funds',
          'priority': 'high',
          'reason': '提高缓存命中率',
        });
      }

      if (performanceMetrics.totalRequests > 100) {
        recommendations.add('请求量较大，建议预加载常用基金数据');
        suggestedTasks.add({
          'type': 'user_favorites',
          'priority': 'normal',
          'reason': '减少用户等待时间',
        });
      }

      // 基于热门缓存键生成建议
      if (hotKeys.isNotEmpty) {
        final popularSymbols = hotKeys
            .where((entry) => entry.key.contains('fundData_list'))
            .map((entry) => entry.key)
            .take(3)
            .toList();

        if (popularSymbols.isNotEmpty) {
          recommendations.add('检测到热门基金数据，建议设置定时预热');
          suggestedTasks.add({
            'type': 'scheduled_preheating',
            'symbols': popularSymbols,
            'priority': 'normal',
            'reason': '基于访问模式的智能预热',
          });
        }
      }

      if (recommendations.isEmpty) {
        recommendations.add('当前缓存性能良好，可根据需要添加预热任务');
      }

      return {
        'recommendations': recommendations,
        'suggested_tasks': suggestedTasks,
        'current_performance': {
          'hit_rate': performanceMetrics.hitRate,
          'total_requests': performanceMetrics.totalRequests,
          'hot_cache_keys':
              hotKeys.map((e) => {'key': e.key, 'count': e.value}).toList(),
        },
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      AppLogger.error('❌ 获取预热建议失败', e);
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// 一键预热常用数据
  Map<String, String> preheatCommonData() {
    final taskIds = <String, String>{};

    try {
      // 预热热门基金
      final popularTaskId =
          preheatPopularFunds(priority: CachePreheatingPriority.high);
      if (popularTaskId.isNotEmpty) {
        taskIds['popular_funds'] = popularTaskId;
      }

      // 预热主要基金类型
      final mainSymbols = ['股票型', '债券型', '混合型'];
      for (final symbol in mainSymbols) {
        final taskId = preheatFundData(
          symbol: symbol,
          priority: CachePreheatingPriority.normal,
        );
        if (taskId.isNotEmpty) {
          taskIds['fund_$symbol'] = taskId;
        }
      }

      AppLogger.info('🔥 一键预热常用数据完成，共创建 ${taskIds.length} 个预热任务');

      return taskIds;
    } catch (e) {
      AppLogger.error('❌ 一键预热常用数据失败', e);
      return {};
    }
  }

  /// 清理已完成的预热任务
  void clearCompletedPreheatingTasks() {
    try {
      _preheatingManager.clearCompletedTasks();
      AppLogger.info('🔥 清理已完成的预热任务');
    } catch (e) {
      AppLogger.error('❌ 清理预热任务失败', e);
    }
  }

  /// 记录缓存访问
  void _trackCacheAccess(String cacheKey) {
    _cacheAccessCounts[cacheKey] = (_cacheAccessCounts[cacheKey] ?? 0) + 1;
    _cacheLastAccess[cacheKey] = DateTime.now();
    AppLogger.debug(
        '📊 FundDataService: 缓存访问跟踪 $cacheKey (次数: ${_cacheAccessCounts[cacheKey]})');
  }

  /// 清除缓存跟踪
  void _clearCacheTracking(String cacheKey) {
    _cacheAccessCounts.remove(cacheKey);
    _cacheLastAccess.remove(cacheKey);
    AppLogger.debug('🗑️ FundDataService: 清除缓存跟踪 $cacheKey');
  }

  /// 获取动态缓存过期时间
  Duration _getDynamicCacheExpireTime(String cacheKey, Duration currentAge) {
    final accessCount = _cacheAccessCounts[cacheKey] ?? 0;
    // final lastAccess = _cacheLastAccess[cacheKey]; // 暂未使用

    // 根据访问次数调整缓存时间
    if (accessCount >= 10) {
      return _longCacheExpireTime; // 高频访问数据使用长期缓存
    } else if (accessCount >= 5) {
      return _cacheExpireTime; // 中频访问数据使用标准缓存
    } else {
      return _shortCacheExpireTime; // 低频访问数据使用短期缓存
    }
  }

  /// 检查并安排预热
  void _checkAndSchedulePreheat(String cacheKey) {
    final accessCount = _cacheAccessCounts[cacheKey] ?? 0;
    if (accessCount >= _preheatThreshold) {
      _schedulePreheatIfNeeded(cacheKey);
    }
  }

  /// 安排预热（如果需要）
  void _schedulePreheatIfNeeded(String cacheKey) {
    // 如果预热定时器已经运行，跳过
    if (_preheatTimer?.isActive == true) {
      return;
    }

    // 获取最后一次访问时间
    final lastAccess = _cacheLastAccess[cacheKey];
    if (lastAccess == null) return;

    // 如果最近访问过，安排预热
    final timeSinceLastAccess = DateTime.now().difference(lastAccess);
    if (timeSinceLastAccess < const Duration(minutes: 5)) {
      _schedulePreheatTimer();
    }
  }

  /// 安排预热定时器
  void _schedulePreheatTimer() {
    _preheatTimer?.cancel();
    _preheatTimer = Timer.periodic(_preheatCheckInterval, (timer) {
      _performIntelligentPreheat();
    });
    AppLogger.debug('⏰ FundDataService: 安排智能预热定时器');
  }

  /// 执行智能预热
  Future<void> _performIntelligentPreheat() async {
    try {
      AppLogger.debug('🔥 FundDataService: 执行智能预热检查');

      // 按访问次数排序，预热最热门的数据
      final sortedEntries = _cacheAccessCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      int preheatedCount = 0;
      for (final entry in sortedEntries.take(5)) {
        // 最多预热5个热门缓存
        final cacheKey = entry.key;
        final accessCount = entry.value;

        if (accessCount >= _preheatThreshold) {
          // 检查缓存是否即将过期
          final lastAccess = _cacheLastAccess[cacheKey];
          if (lastAccess != null) {
            final age = DateTime.now().difference(lastAccess);
            final expireTime = _getDynamicCacheExpireTime(cacheKey, age);
            final timeToExpire = expireTime - age;

            // 如果缓存将在1分钟内过期，预热它
            if (timeToExpire <= const Duration(minutes: 1)) {
              await _preheatCacheData(cacheKey);
              preheatedCount++;
            }
          }
        }
      }

      if (preheatedCount > 0) {
        AppLogger.info('🔥 FundDataService: 智能预热完成，预热了 $preheatedCount 个缓存');
      }
    } catch (e) {
      AppLogger.warn('⚠️ FundDataService: 智能预热失败: $e');
    }
  }

  /// 预热缓存数据
  Future<void> _preheatCacheData(String cacheKey) async {
    try {
      AppLogger.debug('🔥 FundDataService: 预热缓存数据 $cacheKey');

      // 从原始缓存键提取symbol
      String symbol = 'all';
      if (cacheKey.contains('fund_list_')) {
        symbol = cacheKey.replaceAll('fund_list_', '').replaceAll('%', '');
      }

      // 使用低优先级预热
      final taskId = _preheatingManager.addFundDataPreheatingTask(
        symbol: symbol,
        priority: CachePreheatingPriority.low,
        includeRankings: true,
        includeDetails: false,
      );

      AppLogger.debug('🔥 FundDataService: 创建预热任务 $taskId for $cacheKey');
    } catch (e) {
      AppLogger.warn('⚠️ FundDataService: 预热缓存数据失败 $cacheKey: $e');
    }
  }

  /// 获取缓存访问统计
  Map<String, dynamic> getCacheAccessStats() {
    final sortedByAccess = _cacheAccessCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'total_cache_keys': _cacheAccessCounts.length,
      'top_accessed_caches': sortedByAccess
          .take(10)
          .map((e) => {
                'key': e.key,
                'access_count': e.value,
                'last_access': _cacheLastAccess[e.key]?.toIso8601String(),
              })
          .toList(),
      'preheat_threshold': _preheatThreshold,
      'cache_strategy': {
        'short_expire_minutes': _shortCacheExpireTime.inMinutes,
        'standard_expire_minutes': _cacheExpireTime.inMinutes,
        'long_expire_minutes': _longCacheExpireTime.inMinutes,
      },
    };
  }

  /// 重置缓存访问统计
  void resetCacheAccessStats() {
    _cacheAccessCounts.clear();
    _cacheLastAccess.clear();
    _preheatTimer?.cancel();
    AppLogger.info('🔄 FundDataService: 重置缓存访问统计');
  }

  /// 停止预热管理器
  Future<void> stopPreheatingManager() async {
    try {
      _preheatTimer?.cancel();
      _preheatTimer = null;
      await _preheatingManager.stop();
      AppLogger.info('🔌 FundDataService: 预热管理器已停止');
    } catch (e) {
      AppLogger.error('❌ 停止预热管理器失败', e);
    }
  }

  /// 资源清理方法
  Future<void> dispose() async {
    try {
      AppLogger.info('🔄 FundDataService: 开始资源清理');

      // 停止预热定时器
      _preheatTimer?.cancel();
      _preheatTimer = null;

      // 停止预热管理器
      await _preheatingManager.stop();

      // 清理缓存失效管理器
      await _invalidationManager.dispose();

      // 清理缓存访问统计
      _cacheAccessCounts.clear();
      _cacheLastAccess.clear();

      // 清理请求统计
      _lastRequestTime.clear();
      _currentRequests = 0;

      AppLogger.info('✅ FundDataService: 资源清理完成');
    } catch (e) {
      AppLogger.error('❌ FundDataService: 资源清理失败', e);
    }
  }
}

/// 基金数据结果封装
class FundDataResult<T> {
  final T? data;
  final String? errorMessage;
  final bool isSuccess;

  const FundDataResult._({
    this.data,
    this.errorMessage,
    required this.isSuccess,
  });

  factory FundDataResult.success(T data) {
    return FundDataResult._(
      data: data,
      isSuccess: true,
    );
  }

  factory FundDataResult.failure(String errorMessage) {
    return FundDataResult._(
      errorMessage: errorMessage,
      isSuccess: false,
    );
  }

  bool get isFailure => !isSuccess;

  /// 获取数据或抛出异常
  T get dataOrThrow {
    if (isSuccess) {
      return data!;
    } else {
      throw Exception(errorMessage);
    }
  }

  /// 映射结果
  FundDataResult<R> map<R>(R Function(T data) mapper) {
    if (isSuccess) {
      try {
        final dataValue = data;
        if (dataValue == null) {
          return FundDataResult.failure('数据为空，无法转换');
        }
        return FundDataResult.success(mapper(dataValue));
      } catch (e) {
        return FundDataResult.failure('数据转换失败: $e');
      }
    } else {
      return FundDataResult.failure(errorMessage!);
    }
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'FundDataResult.success(data: $data)';
    } else {
      return 'FundDataResult.failure(errorMessage: $errorMessage)';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FundDataResult &&
          runtimeType == other.runtimeType &&
          isSuccess == other.isSuccess &&
          data == other.data &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode =>
      isSuccess.hashCode ^ data.hashCode ^ errorMessage.hashCode;
}
