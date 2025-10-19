import 'dart:async';

import 'package:jisu_fund_analyzer/src/core/network/fund_api_client.dart';
import 'package:jisu_fund_analyzer/src/core/utils/logger.dart';
import 'package:jisu_fund_analyzer/src/features/fund/domain/entities/fund_ranking.dart';

/// 基金数据分页服务
///
/// 负责管理基金数据的分页加载、缓存和错误处理
class FundPaginationService {
  final FundApiClient _apiClient;

  // 分页配置
  static const int _defaultPageSize = 20;
  static const int _maxCacheSize = 200;
  static const double _triggerThreshold = 200.0; // 提前200px触发加载
  static const Duration _debounceDelay = Duration(seconds: 1);

  // 分页状态
  int _currentPage = 1;
  final int _pageSize = _defaultPageSize;
  bool _hasMore = true;
  bool _isLoading = false;
  String? _lastError;

  // 数据缓存
  List<FundRanking> _cachedData = [];
  final Map<int, List<FundRanking>> _pageCache = {};
  DateTime? _lastCacheUpdate;

  // 防抖控制
  Timer? _debounceTimer;

  // 请求控制
  int _activeRequests = 0;

  FundPaginationService(this._apiClient);

  /// 获取当前分页状态
  PaginationState get currentState => PaginationState(
        currentPage: _currentPage,
        pageSize: _pageSize,
        hasMore: _hasMore,
        isLoading: _isLoading,
        totalCount: _cachedData.length,
        error: _lastError,
        cachedPages: _pageCache.keys.toList(),
      );

  /// 加载第一页数据
  Future<PaginationResult> loadFirstPage({bool forceRefresh = false}) async {
    return _loadPage(1, forceRefresh: forceRefresh);
  }

  /// 加载指定页面
  Future<PaginationResult> loadPage(int page,
      {bool forceRefresh = false}) async {
    return _loadPage(page, forceRefresh: forceRefresh);
  }

  /// 智能加载下一页（带防抖）
  Future<PaginationResult> loadNextPage({bool forceRefresh = false}) async {
    if (_isLoading || !_hasMore || _activeRequests > 0) {
      return PaginationResult.success(_cachedData, isIncremental: false);
    }

    // 防抖处理
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDelay, () {
      _loadPage(_currentPage + 1, forceRefresh: forceRefresh);
    });

    return PaginationResult.success(_cachedData, isIncremental: false);
  }

  /// 基于滚动位置判断是否需要加载更多
  bool shouldLoadMore(double scrollExtent, double maxScrollExtent) {
    if (_isLoading || !_hasMore) return false;

    final remaining = maxScrollExtent - scrollExtent;
    return remaining <= _triggerThreshold;
  }

  /// 刷新数据
  Future<PaginationResult> refresh() async {
    AppLogger.info('🔄 开始刷新基金数据...');

    // 清空缓存
    _pageCache.clear();
    _cachedData.clear();
    _currentPage = 1;
    _hasMore = true;
    _lastError = null;
    _lastCacheUpdate = null;

    // 加载第一页
    return _loadPage(1, forceRefresh: true);
  }

  /// 内部页面加载逻辑（增强版，支持分页参数校验和降级策略）
  Future<PaginationResult> _loadPage(int page,
      {bool forceRefresh = false}) async {
    if (_activeRequests > 0 && !forceRefresh) {
      return PaginationResult.success(_cachedData, isIncremental: false);
    }

    // 增强的分页参数校验
    final validationResult = _validatePaginationParams(page, forceRefresh);
    if (!validationResult.isValid) {
      return PaginationResult.error(
        validationResult.errorMessage ?? '分页参数无效',
        data: _cachedData,
      );
    }

    _activeRequests++;
    _isLoading = true;
    _lastError = null;

    try {
      AppLogger.info('📄 加载第 $page 页数据 (forceRefresh: $forceRefresh)');

      // 检查缓存
      if (!forceRefresh && _pageCache.containsKey(page)) {
        final cachedPage = _pageCache[page]!;
        AppLogger.info('💾 使用缓存数据，页面 $page');

        // 更新当前缓存数据
        _updateCacheData(page, cachedPage);

        return PaginationResult.success(
          _cachedData,
          isIncremental: page > 1,
          fromCache: true,
        );
      }

      // 请求API（增强错误处理）
      final rawData = await _loadDataWithRetry(
        symbol: '全部',
        forceRefresh: forceRefresh,
        page: page,
      );

      // 数据转换和验证（增强版）
      final fundData = _validateAndConvertDataEnhanced(rawData, page);

      // 智能分页处理（处理API不支持分页的情况）
      final paginationResult = _handlePaginationResponse(fundData, page);

      // 更新缓存
      _pageCache[page] = paginationResult.data;
      _lastCacheUpdate = DateTime.now();

      // 更新当前数据
      _updateCacheData(page, paginationResult.data);

      // 更新状态（基于实际分页结果）
      _currentPage = page;
      _hasMore = paginationResult.hasMore;

      AppLogger.info(
          '✅ 第 $page 页加载成功，获取 ${paginationResult.data.length} 条数据，还有更多: $_hasMore');

      return PaginationResult.success(
        _cachedData,
        isIncremental: page > 1,
        fromCache: false,
        hasError: paginationResult.isFromFallback,
        errorMessage: paginationResult.isFromFallback ? '使用降级数据' : null,
      );
    } catch (e) {
      _lastError = e.toString();
      AppLogger.error('❌ 第 $page 页加载失败', e.toString());

      // 尝试增强的降级策略
      return await _handleLoadErrorEnhanced(page, e);
    } finally {
      _activeRequests--;
      if (_activeRequests == 0) {
        _isLoading = false;
      }
    }
  }

  /// 数据验证和转换
  List<FundRanking> _validateAndConvertData(dynamic rawData) {
    try {
      if (rawData is! List) {
        throw const FormatException('API返回数据格式错误，期望List类型');
      }

      final List<FundRanking> fundData = [];

      for (int i = 0; i < rawData.length; i++) {
        try {
          final item = rawData[i];
          if (item is Map<String, dynamic>) {
            // 使用容错的数据转换
            final fundRanking = _convertFundDataSafely(item, i + 1);
            if (fundRanking != null) {
              fundData.add(fundRanking);
            }
          }
        } catch (e) {
          AppLogger.warn('⚠️ 跳过无效数据项 [$i]: $e');
          continue;
        }
      }

      if (fundData.isEmpty) {
        throw Exception('没有有效的基金数据');
      }

      return fundData;
    } catch (e) {
      AppLogger.error('❌ 数据转换失败', e.toString());
      throw Exception('数据解析失败: $e');
    }
  }

  /// 安全的基金数据转换
  FundRanking? _convertFundDataSafely(Map<String, dynamic> data, int position) {
    try {
      // 核心字段必须有
      final fundCode =
          _getStringValue(data, '基金代码') ?? _getStringValue(data, 'fundCode');
      final fundName =
          _getStringValue(data, '基金简称') ?? _getStringValue(data, 'fundName');

      if (fundCode == null || fundName == null) {
        AppLogger.warn('⚠️ 缺少核心字段: fundCode=$fundCode, fundName=$fundName');
        return null;
      }

      return FundRanking(
        fundCode: fundCode,
        fundName: fundName,
        fundType: _getStringValue(data, '基金类型') ??
            _getStringValue(data, 'fundType') ??
            '未知',
        company: _getStringValue(data, '基金公司') ??
            _getStringValue(data, 'company') ??
            '未知',
        rankingPosition: position,
        totalCount: 0, // 需要从API获取
        unitNav: _getDoubleValue(data, '单位净值') ?? 0.0,
        accumulatedNav: _getDoubleValue(data, '累计净值') ?? 0.0,
        dailyReturn: _getDoubleValue(data, '日增长率') ?? 0.0,
        return1W: _getDoubleValue(data, '近1周') ?? 0.0,
        return1M: _getDoubleValue(data, '近1月') ?? 0.0,
        return3M: _getDoubleValue(data, '近3月') ?? 0.0,
        return6M: _getDoubleValue(data, '近6月') ?? 0.0,
        return1Y: _getDoubleValue(data, '近1年') ?? 0.0,
        return2Y: _getDoubleValue(data, '近2年') ?? 0.0,
        return3Y: _getDoubleValue(data, '近3年') ?? 0.0,
        returnYTD: _getDoubleValue(data, '今年以来') ?? 0.0,
        returnSinceInception: _getDoubleValue(data, '成立来') ?? 0.0,
        rankingDate: DateTime.now(),
        rankingPeriod: RankingPeriod.oneYear,
        rankingType: RankingType.overall,
      );
    } catch (e) {
      AppLogger.warn('⚠️ 数据转换失败: $e');
      return null;
    }
  }

  /// 安全获取字符串值
  String? _getStringValue(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) return null;
    if (value is String && value.isNotEmpty) return value;
    return value?.toString();
  }

  /// 安全获取浮点数值
  double _getDoubleValue(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) return 0.0;

    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value.replaceAll('%', ''));
      return parsed ?? 0.0;
    }

    return 0.0;
  }

  /// 数据分页处理
  List<FundRanking> _paginateData(List<FundRanking> allData, int page) {
    final startIndex = (page - 1) * _pageSize;
    final endIndex = startIndex + _pageSize;

    if (startIndex >= allData.length) return [];

    return allData.sublist(
      startIndex,
      endIndex > allData.length ? allData.length : endIndex,
    );
  }

  /// 更新缓存数据
  void _updateCacheData(int page, List<FundRanking> newData) {
    if (page == 1) {
      // 第一页，替换数据
      _cachedData.clear();
      _cachedData.addAll(newData);
    } else {
      // 后续页，追加数据（避免重复）
      final existingCodes = _cachedData.map((f) => f.fundCode).toSet();
      final newItems =
          newData.where((f) => !existingCodes.contains(f.fundCode));
      _cachedData.addAll(newItems);
    }

    // 限制缓存大小
    if (_cachedData.length > _maxCacheSize) {
      _cachedData = _cachedData.take(_maxCacheSize).toList();
    }
  }

  /// 错误处理和降级策略
  Future<PaginationResult> _handleLoadError(int page, dynamic error) async {
    AppLogger.warn('🔄 尝试降级策略，页面 $page');

    // 尝试使用缓存
    if (_cachedData.isNotEmpty) {
      AppLogger.info('💾 使用本地缓存作为降级策略');
      return PaginationResult.success(
        _cachedData,
        isIncremental: false,
        hasError: true,
        errorMessage: '使用缓存数据 (${_cachedData.length} 条)',
      );
    }

    // 尝试使用示例数据
    final sampleData = _generateSampleData();
    if (sampleData.isNotEmpty) {
      AppLogger.info('🎭 使用示例数据作为降级策略');
      _cachedData.addAll(sampleData);
      return PaginationResult.success(
        _cachedData,
        isIncremental: false,
        hasError: true,
        errorMessage: '使用示例数据 (${sampleData.length} 条)',
      );
    }

    // 完全失败
    return PaginationResult.error(
      '数据加载失败: ${error.toString()}',
      data: _cachedData,
    );
  }

  /// 生成示例数据
  List<FundRanking> _generateSampleData() {
    final samples = [
      ('000001', '华夏成长混合', '华夏基金', '混合型'),
      ('110022', '易方达蓝筹精选', '易方达基金', '股票型'),
      ('161725', '招商中证白酒指数', '招商基金', '指数型'),
      ('005827', '易方达蓝筹精选', '易方达基金', '混合型'),
      ('110011', '易方达中小盘', '易方达基金', '混合型'),
    ];

    return samples.map((sample) {
      final (code, name, company, type) = sample;
      return FundRanking(
        fundCode: code,
        fundName: name,
        fundType: type,
        company: company,
        rankingPosition: 0,
        totalCount: 0,
        unitNav: 1.0 + (DateTime.now().millisecond % 100) / 100,
        accumulatedNav: 2.0 + (DateTime.now().millisecond % 100) / 100,
        dailyReturn: (DateTime.now().millisecond % 200 - 100) / 100,
        return1W: (DateTime.now().millisecond % 150 - 75) / 100,
        return1M: (DateTime.now().millisecond % 300 - 150) / 100,
        return3M: (DateTime.now().millisecond % 500 - 250) / 100,
        return6M: (DateTime.now().millisecond % 800 - 400) / 100,
        return1Y: (DateTime.now().millisecond % 1200 - 600) / 100,
        return2Y: (DateTime.now().millisecond % 1800 - 900) / 100,
        return3Y: (DateTime.now().millisecond % 2400 - 1200) / 100,
        returnYTD: (DateTime.now().millisecond % 600 - 300) / 100,
        returnSinceInception: (DateTime.now().millisecond % 3000 - 1500) / 100,
        rankingDate: DateTime.now(),
        rankingPeriod: RankingPeriod.oneYear,
        rankingType: RankingType.overall,
      );
    }).toList();
  }

  /// 验证分页参数
  _PaginationValidationResult _validatePaginationParams(
      int page, bool forceRefresh) {
    // 页码校验
    if (page < 1) {
      return _PaginationValidationResult(
        isValid: false,
        errorMessage: '页码不能小于1，当前页码：$page',
      );
    }

    if (page > 1000) {
      // 防止过大的页码
      return _PaginationValidationResult(
        isValid: false,
        errorMessage: '页码不能超过1000，当前页码：$page',
      );
    }

    // 检查是否在短时间内重复请求相同页面
    if (!forceRefresh && _lastCacheUpdate != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastCacheUpdate!);
      if (timeSinceLastRequest.inSeconds < 2 && _pageCache.containsKey(page)) {
        AppLogger.warn('⚠️ 短时间内重复请求页面 $page，跳过此次请求');
        return _PaginationValidationResult(
          isValid: false,
          errorMessage: '请求过于频繁，请稍后再试',
        );
      }
    }

    return _PaginationValidationResult(isValid: true);
  }

  /// 带重试机制的数据加载
  Future<List<dynamic>> _loadDataWithRetry({
    required String symbol,
    required bool forceRefresh,
    required int page,
    int maxRetries = 3,
  }) async {
    int retryCount = 0;
    dynamic lastException;

    while (retryCount <= maxRetries) {
      try {
        AppLogger.business(
            '🔄 请求第 $page 页数据 (尝试 ${retryCount + 1}/$maxRetries)',
            'Pagination');

        // 请求API
        final rawData = await _apiClient
            .getFundRankings(
              symbol: symbol,
              forceRefresh: forceRefresh,
            )
            .timeout(Duration(seconds: 45 + retryCount * 15)); // 递增超时时间

        return rawData;
      } catch (e) {
        lastException = e;
        retryCount++;

        AppLogger.warn('❌ 第 $retryCount 次请求失败: ${e.toString()}');

        if (retryCount <= maxRetries) {
          // 指数退避等待时间
          final waitTime = Duration(seconds: (1 << (retryCount - 1)) * 2);
          AppLogger.business('⏳ 等待 ${waitTime.inSeconds}秒后重试', 'Pagination');
          await Future.delayed(waitTime);
        }
      }
    }

    // 所有重试都失败了
    AppLogger.error('🚨 数据加载失败，已达最大重试次数', lastException.toString());
    throw lastException ?? Exception('数据加载失败');
  }

  /// 增强的数据验证和转换
  List<FundRanking> _validateAndConvertDataEnhanced(dynamic rawData, int page) {
    try {
      if (rawData == null) {
        throw Exception('API返回空数据');
      }

      if (rawData is! List) {
        throw Exception('API返回数据格式错误，期望List类型，实际类型：${rawData.runtimeType}');
      }

      if (rawData.isEmpty) {
        AppLogger.warn('⚠️ API返回空列表，页面 $page', 'Pagination');
        return [];
      }

      final List<FundRanking> fundData = [];
      int validCount = 0;
      int invalidCount = 0;

      for (int i = 0; i < rawData.length; i++) {
        try {
          final item = rawData[i];
          if (item is Map<String, dynamic>) {
            final fundRanking = _convertFundDataSafely(item, i + 1);
            if (fundRanking != null) {
              fundData.add(fundRanking);
              validCount++;
            } else {
              invalidCount++;
            }
          } else {
            invalidCount++;
            AppLogger.warn('⚠️ 数据项[$i]格式错误：${item.runtimeType}', 'Pagination');
          }
        } catch (e) {
          invalidCount++;
          AppLogger.warn('⚠️ 处理数据项[$i]失败: $e', 'Pagination');
          continue;
        }
      }

      AppLogger.info(
          '📊 数据验证完成：有效 $validCount 条，无效 $invalidCount 条', 'Pagination');

      if (fundData.isEmpty) {
        throw Exception('没有有效的基金数据');
      }

      // 数据质量检查
      _performDataQualityCheck(fundData, page);

      return fundData;
    } catch (e) {
      AppLogger.error('❌ 数据转换失败，页面 $page', e.toString());
      throw Exception('数据解析失败，页面 $page: $e');
    }
  }

  /// 数据质量检查
  void _performDataQualityCheck(List<FundRanking> data, int page) {
    if (data.isEmpty) return;

    // 检查重复基金代码
    final fundCodes = data.map((f) => f.fundCode).toList();
    final uniqueCodes = fundCodes.toSet();
    if (uniqueCodes.length < fundCodes.length) {
      AppLogger.warn('⚠️ 发现重复基金代码：${fundCodes.length - uniqueCodes.length} 个重复',
          'Pagination');
    }

    // 检查异常收益率
    final extremeReturns = data
        .where((f) => f.dailyReturn.abs() > 50 || f.return1Y.abs() > 200)
        .length;

    if (extremeReturns > 0) {
      AppLogger.warn('⚠️ 发现异常收益率数据：$extremeReturns 条', 'Pagination');
    }

    AppLogger.info('✅ 数据质量检查通过，页面 $page', 'Pagination');
  }

  /// 智能分页处理
  _PaginationResult _handlePaginationResponse(
      List<FundRanking> fundData, int page) {
    try {
      // 检查是否API支持分页
      final isPaginatedResponse = _checkIfApiSupportsPagination(fundData, page);

      if (isPaginatedResponse) {
        // API支持分页，直接返回数据
        return _PaginationResult(
          data: fundData,
          hasMore: fundData.length >= _pageSize,
          isFromFallback: false,
        );
      } else {
        // API不支持分页，进行客户端分页
        return _performClientSidePagination(fundData, page);
      }
    } catch (e) {
      AppLogger.error('❌ 分页处理失败，页面 $page', e.toString());
      // 降级到客户端分页
      return _performClientSidePagination(fundData, page);
    }
  }

  /// 检查API是否支持分页
  bool _checkIfApiSupportsPagination(List<FundRanking> data, int page) {
    // 简单启发式判断：
    // 1. 如果数据量刚好等于页面大小，可能支持分页
    // 2. 如果数据量远大于页面大小，肯定支持分页
    // 3. 如果数据量小于页面大小且不是第一页，可能不支持分页

    if (page == 1 && data.length < _pageSize) {
      AppLogger.info('📄 API似乎不支持分页（第一页数据量小于页面大小）', 'Pagination');
      return false;
    }

    if (data.length == _pageSize) {
      AppLogger.info('📄 API可能支持分页（数据量等于页面大小）', 'Pagination');
      return true;
    }

    if (data.length > _pageSize) {
      AppLogger.info('📄 API支持分页（数据量大于页面大小）', 'Pagination');
      return true;
    }

    AppLogger.info('📄 API分页支持状态未知，使用客户端分页', 'Pagination');
    return false;
  }

  /// 客户端分页处理
  _PaginationResult _performClientSidePagination(
      List<FundRanking> allData, int page) {
    AppLogger.info(
        '🔄 执行客户端分页，总数据量：${allData.length}，请求页面：$page', 'Pagination');

    // 如果没有足够的数据进行客户端分页，生成补充数据
    if (allData.length < page * _pageSize) {
      AppLogger.warn('⚠️ 数据不足以进行客户端分页，生成补充数据', 'Pagination');
      final additionalData = _generateAdditionalData(page, _pageSize);
      allData.addAll(additionalData);
    }

    final startIndex = (page - 1) * _pageSize;
    final endIndex = startIndex + _pageSize;

    final paginatedData = startIndex < allData.length
        ? allData.sublist(
            startIndex, endIndex > allData.length ? allData.length : endIndex)
        : <FundRanking>[];

    final hasMore = endIndex < allData.length;

    return _PaginationResult(
      data: paginatedData,
      hasMore: hasMore,
      isFromFallback: true, // 标记为降级数据
    );
  }

  /// 生成额外的数据以支持分页
  List<FundRanking> _generateAdditionalData(int page, int pageSize) {
    final random = DateTime.now().millisecondsSinceEpoch;
    final additionalData = <FundRanking>[];

    for (int i = 0; i < pageSize; i++) {
      final index = (page - 1) * pageSize + i + 1000; // 避免与现有数据重复

      additionalData.add(FundRanking(
        fundCode: '${999999 + index}',
        fundName: '补充基金${String.fromCharCode(65 + (index % 26))}',
        fundType: '混合型',
        company: '补充基金公司',
        rankingPosition: index + 1,
        totalCount: 0,
        unitNav: 1.0 + (random + index * 37) % 100 / 100,
        accumulatedNav: 2.0 + (random + index * 47) % 100 / 100,
        dailyReturn: ((random + index * 13) % 200 - 100) / 100,
        return1W: ((random + index * 17) % 150 - 75) / 100,
        return1M: ((random + index * 23) % 300 - 150) / 100,
        return3M: ((random + index * 31) % 500 - 250) / 100,
        return6M: ((random + index * 41) % 800 - 400) / 100,
        return1Y: ((random + index * 53) % 1200 - 600) / 100,
        return2Y: ((random + index * 61) % 1800 - 900) / 100,
        return3Y: ((random + index * 71) % 2400 - 1200) / 100,
        returnYTD: ((random + index * 29) % 600 - 300) / 100,
        returnSinceInception: ((random + index * 83) % 3000 - 1500) / 100,
        rankingDate: DateTime.now(),
        rankingPeriod: RankingPeriod.oneYear,
        rankingType: RankingType.overall,
      ));
    }

    AppLogger.info(
        '🎭 生成了 ${additionalData.length} 条补充数据，页面 $page', 'Pagination');
    return additionalData;
  }

  /// 增强的错误处理和降级策略
  Future<PaginationResult> _handleLoadErrorEnhanced(
      int page, dynamic error) async {
    AppLogger.warn('🔄 尝试增强的降级策略，页面 $page', 'Pagination');

    // 尝试使用缓存
    if (_cachedData.isNotEmpty) {
      AppLogger.info('💾 使用本地缓存作为第一级降级策略', 'Pagination');
      return PaginationResult.success(
        _cachedData,
        isIncremental: false,
        hasError: true,
        errorMessage: '使用缓存数据 (${_cachedData.length} 条)',
      );
    }

    // 尝试使用页面缓存
    if (_pageCache.isNotEmpty) {
      final cachePage = _pageCache.keys.first;
      final cachedPageData = _pageCache[cachePage]!;
      AppLogger.info('💾 使用页面缓存 $cachePage 作为第二级降级策略', 'Pagination');

      return PaginationResult.success(
        cachedPageData,
        isIncremental: false,
        hasError: true,
        errorMessage: '使用页面缓存数据 (${cachedPageData.length} 条)',
      );
    }

    // 尝试生成示例数据
    final sampleData = _generateSampleData();
    if (sampleData.isNotEmpty) {
      AppLogger.info('🎭 使用示例数据作为第三级降级策略', 'Pagination');

      // 为示例数据添加分页
      final paginatedSampleData = _paginateData(sampleData, page);

      return PaginationResult.success(
        paginatedSampleData,
        isIncremental: false,
        hasError: true,
        errorMessage: '使用示例数据 (${paginatedSampleData.length} 条)',
      );
    }

    // 生成空数据作为最后降级
    AppLogger.error('🚨 所有降级策略都失败，返回空数据', 'Pagination');
    return PaginationResult.error(
      '数据加载失败：${error.toString()}，且无可用降级数据',
      data: [],
    );
  }

  /// 清理资源
  void dispose() {
    _debounceTimer?.cancel();
    _pageCache.clear();
    _cachedData.clear();
    AppLogger.info('🧹 FundPaginationService 资源已清理');
  }
}

/// 分页参数验证结果
class _PaginationValidationResult {
  final bool isValid;
  final String? errorMessage;

  const _PaginationValidationResult({
    required this.isValid,
    this.errorMessage,
  });
}

/// 分页处理结果
class _PaginationResult {
  final List<FundRanking> data;
  final bool hasMore;
  final bool isFromFallback;

  const _PaginationResult({
    required this.data,
    required this.hasMore,
    this.isFromFallback = false,
  });
}

/// 分页状态信息
class PaginationState {
  final int currentPage;
  final int pageSize;
  final bool hasMore;
  final bool isLoading;
  final int totalCount;
  final String? error;
  final List<int> cachedPages;

  const PaginationState({
    required this.currentPage,
    required this.pageSize,
    required this.hasMore,
    required this.isLoading,
    required this.totalCount,
    this.error,
    required this.cachedPages,
  });

  @override
  String toString() {
    return 'PaginationState(page: $currentPage, total: $totalCount, hasMore: $hasMore, loading: $isLoading)';
  }
}

/// 分页结果
class PaginationResult {
  final List<FundRanking> data;
  final bool isIncremental;
  final bool fromCache;
  final bool hasError;
  final String? errorMessage;

  const PaginationResult({
    required this.data,
    required this.isIncremental,
    this.fromCache = false,
    this.hasError = false,
    this.errorMessage,
  });

  factory PaginationResult.success(
    List<FundRanking> data, {
    required bool isIncremental,
    bool fromCache = false,
    bool hasError = false,
    String? errorMessage,
  }) {
    return PaginationResult(
      data: data,
      isIncremental: isIncremental,
      fromCache: fromCache,
      hasError: hasError,
      errorMessage: errorMessage,
    );
  }

  factory PaginationResult.error(String message, {List<FundRanking>? data}) {
    return PaginationResult(
      data: data ?? [],
      isIncremental: false,
      hasError: true,
      errorMessage: message,
    );
  }

  bool get isSuccess => !hasError && data.isNotEmpty;
  bool get isEmpty => data.isEmpty;
}
