import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../../../../core/utils/logger.dart';
import '../../../../core/cache/interfaces/cache_service.dart';
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

  // 请求配置 - 120秒超时设置
  static const Duration _timeout = Duration(seconds: 120); // 设置120秒超时，确保数据加载完成
  static const int _maxRetries = 2; // 增加重试次数，提高成功率
  static const Duration _retryDelay = Duration(seconds: 3); // 增加重试间隔
  static const Duration _connectionTimeout = Duration(seconds: 30); // 连接超时
  static const Duration _fastFailTimeout = Duration(seconds: 10); // 快速失败超时

  // 缓存配置
  static const String _cacheKeyPrefix = 'fund_rankings_';
  static const Duration _cacheExpireTime = Duration(seconds: 120); // 120秒缓存

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
          cacheService: _cacheService!,
          fundDataService: this,
        );
    _initializeCache();
  }

  /// 初始化缓存服务
  Future<void> _initializeCache() async {
    try {
      // 统一缓存服务通常不需要显式初始化
      // 验证缓存服务是否可用
      await _cacheService.get('__test_key__');
      AppLogger.info('✅ FundDataService: 缓存服务初始化成功');
    } catch (e) {
      AppLogger.warn('⚠️ FundDataService: 缓存服务初始化失败，将在无缓存模式下运行: $e');
      // 缓存初始化失败不影响服务使用，只是每次都要从API获取
      // 这种情况下_getCachedRankings将总是返回null
    }
  }

  /// 获取基金排行数据（智能缓存版）
  ///
  /// [symbol] 基金类型符号，默认为全部基金
  /// [forceRefresh] 是否强制刷新，忽略缓存
  /// [onProgress] 进度回调函数
  Future<FundDataResult<List<FundRanking>>> getFundRankings({
    String symbol = _allFundsSymbol,
    bool forceRefresh = false,
    Function(double)? onProgress,
  }) async {
    final cacheKey = '$_cacheKeyPrefix${symbol.replaceAll('%', '')}';

    AppLogger.debug(
        '🔄 FundDataService: 开始获取基金排行数据 (symbol: $symbol, forceRefresh: $forceRefresh)');

    try {
      // 第一步：检查缓存（除非强制刷新）
      if (!forceRefresh) {
        final cachedRankings = await _getCachedRankings(cacheKey);
        if (cachedRankings != null) {
          AppLogger.info(
              '💾 FundDataService: 缓存命中 (${cachedRankings.length}条)');

          // 对缓存数据进行快速验证
          final cacheValidationResult =
              await _validationService.validateFundRankings(
            cachedRankings,
            strategy: ConsistencyCheckStrategy.quick,
            cacheKey: cacheKey,
          );

          if (!cacheValidationResult.isValid) {
            AppLogger.warn('⚠️ FundDataService: 缓存数据验证失败，重新获取数据');
            // 缓存数据有问题，清理缓存并继续走API流程
            await _validationService.cleanupCorruptedCache(cacheKey);
          } else {
            if (cacheValidationResult.hasWarnings) {
              AppLogger.warn(
                  '⚠️ FundDataService: 缓存数据有警告: ${cacheValidationResult.warnings.join(', ')}');
            }
            return FundDataResult.success(cachedRankings);
          }
        }
      }

      // 第二步：频率控制检查
      _checkRequestFrequency(cacheKey);

      // 第三步：从API获取数据
      AppLogger.info('🌐 FundDataService: 从API获取数据');
      onProgress?.call(0.1); // 开始请求

      // 构建API请求URL，正确处理中文参数的URL编码
      Uri uri;
      if (symbol.isNotEmpty && symbol != '全部') {
        // 对非"全部"参数进行URL编码
        final encodedSymbol = Uri.encodeComponent(symbol);
        uri = Uri.parse(
            '$_baseUrl/api/public/fund_open_fund_rank_em?symbol=$encodedSymbol');
      } else {
        // 对于"全部"参数，也进行URL编码
        final encodedSymbol = Uri.encodeComponent('全部');
        uri = Uri.parse(
            '$_baseUrl/api/public/fund_open_fund_rank_em?symbol=$encodedSymbol');
      }

      // 第四步：并发控制
      _currentRequests++;
      try {
        var rankings = await _executeWithRetry<List<FundRanking>>(
          () => _fetchRankingsFromApi(uri, onProgress),
          maxRetries: _maxRetries,
          retryDelay: _retryDelay,
        );

        onProgress?.call(0.8); // 数据解析完成

        // 第三步：数据验证和质量检查
        onProgress?.call(0.85); // 开始验证
        final validationResult = await _validationService.validateFundRankings(
          rankings,
          strategy: ConsistencyCheckStrategy.standard,
          cacheKey: cacheKey,
        );

        if (!validationResult.isValid) {
          AppLogger.warn('⚠️ FundDataService: 数据验证失败，尝试修复数据');

          // 尝试修复数据
          final repairedData = await _validationService.repairCorruptedData(
            rankings,
            cacheKey: cacheKey,
          );

          if (repairedData != null) {
            rankings = repairedData;
            AppLogger.info('✅ FundDataService: 数据修复成功 (${rankings.length}条)');
          } else {
            AppLogger.error('❌ FundDataService: 数据修复失败，清理损坏的缓存', null);
            await _validationService.cleanupCorruptedCache(cacheKey);

            // 返回原始数据但标记验证失败
            return FundDataResult.success(rankings);
          }
        } else if (validationResult.hasWarnings) {
          AppLogger.warn(
              '⚠️ FundDataService: 数据验证通过但有警告: ${validationResult.warnings.join(', ')}');
        }

        // 第四步：缓存数据（异步进行，不阻塞返回）
        _cacheRankings(cacheKey, rankings);

        onProgress?.call(1.0); // 完成

        AppLogger.debug('✅ FundDataService: 数据获取成功 (${rankings.length}条)');
        return FundDataResult.success(rankings);
      } finally {
        // 确保并发计数器正确递减
        _currentRequests--;
        AppLogger.debug('📊 FundDataService: 当前并发请求数: $_currentRequests');
      }
    } on SocketException catch (e) {
      final errorMsg = '网络连接错误: ${e.message}';
      AppLogger.debug('❌ FundDataService: $errorMsg');
      return FundDataResult.failure(errorMsg);
    } on TimeoutException catch (e) {
      final errorMsg = '请求超时: ${e.message}';
      AppLogger.debug('❌ FundDataService: $errorMsg');
      return FundDataResult.failure(errorMsg);
    } catch (e) {
      final errorMsg = '获取基金数据失败: $e';
      AppLogger.debug('❌ FundDataService: $errorMsg');
      return FundDataResult.failure(errorMsg);
    }
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
    AppLogger.info('⏱️ FundDataService: 开始请求，超时时间: ${_timeout.inSeconds}秒');

    // 第1层：快速失败检查
    await _preRequestCheck();

    // 第2层：多层超时保护
    http.Response response;
    try {
      // 使用竞速超时机制：快速失败 + 正常超时
      response = await _makeRequestWithMultiTimeout(uri);

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

    // 第4层：数据处理安全检查
    if (response.body.length > 5 * 1024 * 1024) {
      // 5MB限制
      throw FormatException('响应数据过大，可能导致内存溢出');
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
          .timeout(const Duration(seconds: 120)); // 修改为120秒超时

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
      '/api/public/fund_open_fund_rank_em',
      '/api/public/fund_open_fund_info_em',
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
      throw SocketException('网络连接不可用');
    }

    // 检查API服务器连通性
    if (!await _checkApiServerConnectivity()) {
      throw SocketException('API服务器不可达，请检查服务器地址：$_baseUrl');
    }

    // 快速API端点测试
    try {
      final apiExists =
          await _testApiEndpoint('/api/public/fund_open_fund_rank_em');
      if (!apiExists) {
        AppLogger.error('❌ API端点不存在: /api/public/fund_open_fund_rank_em', null);
        throw HttpException('基金排行API端点不存在，可能API路径已变更或服务未启动');
      }
    } catch (e) {
      if (e is HttpException) rethrow;
      AppLogger.warn('⚠️ FundDataService: API端点测试失败，但继续请求: $e');
    }
  }

  /// 多层超时保护的HTTP请求
  Future<http.Response> _makeRequestWithMultiTimeout(Uri uri) async {
    return await http
        .get(
      uri,
      headers: _buildHeaders(),
    )
        .timeout(
      _timeout,
      onTimeout: () {
        AppLogger.warn(
            '⏰ FundDataService: HTTP请求超时 (${_timeout.inSeconds}秒): $uri');
        throw TimeoutException('HTTP请求超时', _timeout);
      },
    );
  }

  /// 验证HTTP响应
  void _validateResponse(http.Response response) {
    if (response.statusCode != 200) {
      String errorMsg =
          'API错误: ${response.statusCode} ${response.reasonPhrase}';

      // 为404错误提供更详细的信息和可能的解决方案
      if (response.statusCode == 404) {
        errorMsg += '\n\n💡 可能的解决方案：';
        errorMsg += '\n1. 检查API端点是否正确：/api/public/fund_open_fund_rank_em';
        errorMsg += '\n2. 确认服务器地址：http://154.44.25.92:8080';
        errorMsg += '\n3. 验证API服务是否正在运行';
        errorMsg += '\n4. 检查API路径是否有变更';

        AppLogger.error('🔍 API 404错误详情：$errorMsg', null);

        // 注意：异步诊断需要在调用方进行，这里提供提示信息
        errorMsg += '\n\n🔍 如需详细诊断，请调用 diagnoseApiProblem() 方法';

        // 对于404错误，尝试提供一个备用的错误消息
        throw HttpException('API接口不存在，请检查服务器配置和API路径');
      } else if (response.statusCode >= 500) {
        errorMsg += '\n\n💡 服务器内部错误，请稍后重试或联系技术支持';
        AppLogger.error('🔥 服务器错误：$errorMsg', null);
        throw HttpException('服务器内部错误，请稍后重试');
      } else if (response.statusCode == 401) {
        errorMsg += '\n\n💡 认证失败，请检查API密钥或访问权限';
        throw HttpException('API认证失败');
      } else {
        AppLogger.error('❌ HTTP错误：$errorMsg', null);
        throw HttpException(errorMsg);
      }
    }

    if (response.body.isEmpty) {
      throw FormatException('响应数据为空');
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
        .timeout(_timeout);

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
      'Accept': 'application/json; charset=utf-8',
      'Accept-Charset': 'utf-8',
      'Accept-Encoding': 'gzip, deflate', // 启用压缩
      'User-Agent': 'FundDataService/2.0.0 (Flutter)',
      'Connection': 'keep-alive',
      'Keep-Alive': 'timeout=300, max=1000', // 长连接保持
      'Cache-Control': 'max-age=0, no-cache', // 禁用缓存确保获取最新数据
      'Pragma': 'no-cache',
      'X-Requested-With': 'FundDataService', // 标识请求来源
    };
  }

  /// 带重试机制的网络请求执行
  Future<T> _executeWithRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    Exception? lastException;

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await operation();
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());

        if (attempt == maxRetries) {
          AppLogger.debug('❌ FundDataService: 重试失败，达到最大重试次数 ($maxRetries)');
          rethrow;
        }

        AppLogger.debug(
            '⚠️ FundDataService: 第${attempt + 1}次请求失败，${retryDelay.inSeconds}秒后重试: $e');
        await Future.delayed(retryDelay);
      }
    }

    throw lastException!;
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

  /// 从缓存获取基金排行数据
  Future<List<FundRanking>?> _getCachedRankings(String cacheKey) async {
    try {
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

        if (age > _cacheExpireTime) {
          AppLogger.info(
              '⏰ FundDataService: 缓存已过期 (缓存时间: ${age.inSeconds}秒, 限制: ${_cacheExpireTime.inSeconds}秒)');
          // 删除过期缓存
          await _cacheService.remove(cacheKey);
          return null;
        }

        AppLogger.debug('✅ FundDataService: 缓存有效 (缓存时间: ${age.inSeconds}秒)');
      }

      final List<dynamic> dataList = jsonData['rankings'] ?? [];

      final rankings = dataList.map((item) {
        return FundRanking.fromJson(
          Map<String, dynamic>.from(item),
          dataList.indexOf(item) + 1,
        );
      }).toList();

      final remainingTime = age != null
          ? _cacheExpireTime.inSeconds - age.inSeconds
          : _cacheExpireTime.inSeconds;
      AppLogger.info(
          '💾 FundDataService: 从缓存加载 ${rankings.length} 条数据 (缓存剩余有效时间: $remainingTime秒)');
      return rankings;
    } catch (e) {
      AppLogger.error('❌ FundDataService: 缓存数据解析失败', e);
      // 尝试清除损坏的缓存，但不要因为清理失败而中断流程
      try {
        await _cacheService.remove(cacheKey);
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
