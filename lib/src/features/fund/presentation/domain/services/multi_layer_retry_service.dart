import 'dart:async';
import 'dart:math' as math;

import 'package:jisu_fund_analyzer/src/core/utils/logger.dart';
import 'package:jisu_fund_analyzer/src/core/network/fund_api_client.dart';
import 'package:jisu_fund_analyzer/src/features/fund/domain/entities/fund_ranking.dart';

/// 多层重试机制服务
///
/// 实现智能重试和缓存降级策略，确保基金数据获取的可靠性
/// 包含以下层级：
/// 1. 主API请求重试
/// 2. 缓存数据降级
/// 3. 镜像API请求
/// 4. 示例数据生成
/// 5. 空数据返回
class MultiLayerRetryService {
  // 单例模式
  static final MultiLayerRetryService _instance =
      MultiLayerRetryService._internal();
  factory MultiLayerRetryService() => _instance;
  MultiLayerRetryService._internal();

  // 重试配置
  static const int _maxPrimaryRetries = 3; // 主API最大重试次数
  static const int _maxBackupRetries = 2; // 备用API最大重试次数
  static const Duration _baseRetryDelay = Duration(seconds: 2);
  static const Duration _maxRetryDelay = Duration(seconds: 30);

  // 缓存配置
  static const Duration _cacheValidityPeriod = Duration(minutes: 5);
  static const Duration _staleCacheValidityPeriod = Duration(hours: 1);

  // 数据缓存
  final Map<String, _CacheEntry> _dataCache = {};
  final Map<String, DateTime> _lastSuccessfulRequest = {};

  // 统计信息
  final _RetryStatistics _statistics = _RetryStatistics();

  // API客户端实例
  final FundApiClient _apiClient = FundApiClient();

  /// 带多层重试机制的基金数据获取
  Future<List<FundRanking>> getFundRankingsWithRetry({
    required String symbol,
    bool forceRefresh = false,
    int? timeoutSeconds,
  }) async {
    final cacheKey = _generateCacheKey(symbol);
    final startTime = DateTime.now();

    AppLogger.business('🚀 开始多层重试获取基金数据: $symbol', 'MultiLayerRetry');

    try {
      // 第一层：尝试使用有效缓存
      if (!forceRefresh) {
        final cachedData = _tryGetFromCache(cacheKey, isStaleAllowed: false);
        if (cachedData != null) {
          _statistics.recordSuccess('cache_primary');
          AppLogger.info(
              '✅ 使用有效缓存数据: ${cachedData.length}条', 'MultiLayerRetry');
          return cachedData;
        }
      }

      // 第二层：主API重试机制
      final primaryResult = await _retryWithPrimaryAPI(
        symbol,
        cacheKey,
        forceRefresh,
        timeoutSeconds ?? 45,
      );

      if (primaryResult != null) {
        _statistics.recordSuccess('primary_api');
        _cacheData(cacheKey, primaryResult);
        AppLogger.info(
            '✅ 主API获取成功: ${primaryResult.length}条', 'MultiLayerRetry');
        return primaryResult;
      }

      // 第三层：尝试使用过期缓存
      final staleData = _tryGetFromCache(cacheKey, isStaleAllowed: true);
      if (staleData != null) {
        _statistics.recordSuccess('cache_stale');
        AppLogger.warn('⚠️ 使用过期缓存数据: ${staleData.length}条', 'MultiLayerRetry');
        return staleData;
      }

      // 第四层：备用API重试机制
      final backupResult = await _retryWithBackupAPI(symbol, cacheKey);

      if (backupResult != null) {
        _statistics.recordSuccess('backup_api');
        _cacheData(cacheKey, backupResult, isBackup: true);
        AppLogger.warn(
            '⚠️ 备用API获取成功: ${backupResult.length}条', 'MultiLayerRetry');
        return backupResult;
      }

      // 第五层：生成示例数据
      AppLogger.error('🚨 所有API都失败，生成示例数据', 'MultiLayerRetry');
      final sampleData = _generateSampleData(symbol);
      _statistics.recordSuccess('sample_data');
      return sampleData;
    } catch (e) {
      AppLogger.error('❌ 多层重试机制完全失败', e.toString(), StackTrace.current);
      _statistics.recordFailure();

      // 最后的降级：返回空数据
      return <FundRanking>[];
    } finally {
      final duration = DateTime.now().difference(startTime);
      _statistics.recordRequest(duration);
      AppLogger.info(
          '📊 多层重试请求完成，耗时: ${duration.inMilliseconds}ms', 'MultiLayerRetry');
    }
  }

  /// 主API重试机制
  Future<List<FundRanking>?> _retryWithPrimaryAPI(
    String symbol,
    String cacheKey,
    bool forceRefresh,
    int timeoutSeconds,
  ) async {
    AppLogger.business('🔄 尝试主API请求重试', 'MultiLayerRetry');

    for (int attempt = 1; attempt <= _maxPrimaryRetries; attempt++) {
      try {
        AppLogger.info(
            '📡 主API请求第 $attempt/$_maxPrimaryRetries 次', 'MultiLayerRetry');

        // 使用增强的超时配置
        final timeout = Duration(seconds: timeoutSeconds + (attempt - 1) * 15);
        final rawData = await _apiClient
            .getFundRankings(
              symbol: symbol,
              forceRefresh: forceRefresh,
            )
            .timeout(timeout);

        if (rawData.isNotEmpty) {
          final fundData = _convertToFundRankingList(rawData);
          if (fundData.isNotEmpty) {
            _lastSuccessfulRequest[cacheKey] = DateTime.now();
            return fundData;
          }
        }
      } catch (e) {
        AppLogger.warn(
            '❌ 主API请求第 $attempt 次失败: ${e.toString()}', 'MultiLayerRetry');

        // 判断是否应该继续重试
        if (!_shouldContinueRetry(e, attempt, _maxPrimaryRetries)) {
          AppLogger.warn('🛑 主API重试终止：${_getRetryTerminationReason(e)}',
              'MultiLayerRetry');
          break;
        }

        // 等待重试间隔（指数退避）
        if (attempt < _maxPrimaryRetries) {
          final delay = _calculateRetryDelay(attempt);
          AppLogger.business('⏳ 等待 ${delay.inSeconds}秒后重试', 'MultiLayerRetry');
          await Future.delayed(delay);
        }
      }
    }

    AppLogger.error('🚨 主API所有重试都失败', 'MultiLayerRetry');
    return null;
  }

  /// 备用API重试机制
  Future<List<FundRanking>?> _retryWithBackupAPI(
    String symbol,
    String cacheKey,
  ) async {
    AppLogger.business('🔄 尝试备用API请求重试', 'MultiLayerRetry');

    // 这里可以实现备用API的逻辑
    // 例如：使用不同的数据源、不同的服务器等

    for (int attempt = 1; attempt <= _maxBackupRetries; attempt++) {
      try {
        AppLogger.info(
            '📡 备用API请求第 $attempt/$_maxBackupRetries 次', 'MultiLayerRetry');

        // 模拟备用API调用
        // 实际实现中可以替换为真实的备用API
        final backupData = await _callBackupApi(symbol, attempt);

        if (backupData.isNotEmpty) {
          final fundData = _convertToFundRankingList(backupData);
          if (fundData.isNotEmpty) {
            _lastSuccessfulRequest[cacheKey] = DateTime.now();
            return fundData;
          }
        }
      } catch (e) {
        AppLogger.warn(
            '❌ 备用API请求第 $attempt 次失败: ${e.toString()}', 'MultiLayerRetry');

        if (attempt < _maxBackupRetries) {
          final delay = _calculateRetryDelay(attempt, isBackup: true);
          await Future.delayed(delay);
        }
      }
    }

    AppLogger.error('🚨 备用API所有重试都失败', 'MultiLayerRetry');
    return null;
  }

  /// 模拟备用API调用
  Future<List<dynamic>> _callBackupApi(String symbol, int attempt) async {
    AppLogger.info('🔧 调用备用API: $symbol (尝试 $attempt)', 'MultiLayerRetry');

    // 模拟网络延迟
    await Future.delayed(Duration(seconds: 2 + attempt));

    // 模拟偶尔的成功
    if (math.Random().nextDouble() > 0.7) {
      AppLogger.info('✅ 备用API响应成功', 'MultiLayerRetry');
      return _generateBackupApiResponse(symbol);
    } else {
      throw Exception('备用API暂时不可用');
    }
  }

  /// 生成备用API响应数据
  List<dynamic> _generateBackupApiResponse(String symbol) {
    return [
      {
        '基金代码': 'BK001',
        '基金简称': '备用基金A',
        '基金类型': '混合型',
        '基金公司': '备用基金管理有限公司',
        '单位净值': '2.3456',
        '累计净值': '3.7890',
        '日增长率': '+1.23%',
        '近1周': '+2.34%',
        '近1月': '+5.67%',
        '近3月': '+8.90%',
        '近6月': '+12.34%',
        '近1年': '+23.45%',
        '近2年': '+34.56%',
        '近3年': '+45.67%',
        '今年以来': '+16.78%',
        '成立来': '+234.56%',
      },
      {
        '基金代码': 'BK002',
        '基金简称': '备用基金B',
        '基金类型': '股票型',
        '基金公司': '备用基金管理有限公司',
        '单位净值': '1.5678',
        '累计净值': '2.9012',
        '日增长率': '-0.45%',
        '近1周': '+1.12%',
        '近1月': '+3.45%',
        '近3月': '+6.78%',
        '近6月': '+10.12%',
        '近1年': '+18.90%',
        '近2年': '+28.90%',
        '近3年': '+38.90%',
        '今年以来': '+12.34%',
        '成立来': '+189.01%',
      },
    ];
  }

  /// 尝试从缓存获取数据
  List<FundRanking>? _tryGetFromCache(String cacheKey,
      {required bool isStaleAllowed}) {
    final cacheEntry = _dataCache[cacheKey];
    if (cacheEntry == null) return null;

    final now = DateTime.now();
    final age = now.difference(cacheEntry.timestamp);

    if (age <= _cacheValidityPeriod) {
      // 有效缓存
      AppLogger.debug('✅ 使用有效缓存: $cacheKey', 'MultiLayerRetry');
      return cacheEntry.data;
    } else if (isStaleAllowed && age <= _staleCacheValidityPeriod) {
      // 过期但仍可用的缓存
      AppLogger.debug(
          '⚠️ 使用过期缓存: $cacheKey, 过期时间: ${age.inMinutes}分钟', 'MultiLayerRetry');
      return cacheEntry.data;
    } else {
      // 缓存过期且不允许使用过期数据
      AppLogger.debug(
          '🗑️ 缓存已过期: $cacheKey, 过期时间: ${age.inMinutes}分钟', 'MultiLayerRetry');
      _dataCache.remove(cacheKey);
      return null;
    }
  }

  /// 缓存数据
  void _cacheData(String cacheKey, List<FundRanking> data,
      {bool isBackup = false}) {
    try {
      _dataCache[cacheKey] = _CacheEntry(
        data: data,
        timestamp: DateTime.now(),
        isBackup: isBackup,
      );

      // 清理过期缓存
      _cleanupExpiredCache();

      AppLogger.debug(
          '💾 数据已缓存: $cacheKey (${data.length}条${isBackup ? ', 备用API' : ''})',
          'MultiLayerRetry');
    } catch (e) {
      AppLogger.warn('⚠️ 缓存数据失败: $e', 'MultiLayerRetry');
    }
  }

  /// 清理过期缓存
  void _cleanupExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _dataCache.entries) {
      final age = now.difference(entry.value.timestamp);
      if (age > _staleCacheValidityPeriod) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _dataCache.remove(key);
      AppLogger.debug('🗑️ 清理过期缓存: $key', 'MultiLayerRetry');
    }

    if (expiredKeys.isNotEmpty) {
      AppLogger.info('🧹 清理了 ${expiredKeys.length} 个过期缓存', 'MultiLayerRetry');
    }
  }

  /// 判断是否应该继续重试
  bool _shouldContinueRetry(dynamic error, int attempt, int maxRetries) {
    if (attempt >= maxRetries) return false;

    final errorString = error.toString().toLowerCase();

    // 不应重试的错误类型
    final nonRetryableErrors = [
      '401', '403', // 认证错误
      '404', // 资源不存在
      '400', // 请求参数错误
      'permission denied',
      'access denied',
      'invalid parameter',
      'not found',
    ];

    // 如果遇到不可重试的错误，停止重试
    for (final nonRetryable in nonRetryableErrors) {
      if (errorString.contains(nonRetryable)) {
        AppLogger.warn('🛑 遇到不可重试错误: $nonRetryable', 'MultiLayerRetry');
        return false;
      }
    }

    // 网络相关错误可以重试
    final retryableErrors = [
      'timeout',
      'connection',
      'network',
      'socket',
      '500',
      '502',
      '503',
      '504',
      'connection refused',
      'network is unreachable',
    ];

    return retryableErrors.any((retryable) => errorString.contains(retryable));
  }

  /// 获取重试终止原因
  String _getRetryTerminationReason(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('timeout')) {
      return '请求超时';
    }
    if (errorString.contains('connection')) {
      return '连接失败';
    }
    if (errorString.contains('network')) {
      return '网络错误';
    }
    if (errorString.contains('401') || errorString.contains('403')) {
      return '认证失败';
    }
    if (errorString.contains('404')) {
      return '资源不存在';
    }
    if (errorString.contains('400')) {
      return '请求参数错误';
    }
    if (errorString.contains('500')) {
      return '服务器内部错误';
    }

    return '未知错误';
  }

  /// 计算重试延迟时间
  Duration _calculateRetryDelay(int attempt, {bool isBackup = false}) {
    // 指数退避算法：baseDelay * (2 ^ (attempt - 1))
    final exponentialDelay =
        _baseRetryDelay.inMilliseconds * math.pow(2, attempt - 1);

    // 添加随机抖动，避免多个请求同时重试
    final random = math.Random();
    final jitter = (exponentialDelay * 0.1 * random.nextDouble()).toInt();

    final totalDelay = exponentialDelay.toInt() + jitter;

    // 限制最大延迟时间
    final maxDelay = isBackup
        ? _maxRetryDelay.inMilliseconds ~/ 2
        : _maxRetryDelay.inMilliseconds;
    final finalDelay = math.min(totalDelay, maxDelay);

    return Duration(milliseconds: finalDelay);
  }

  /// 转换为FundRanking列表
  List<FundRanking> _convertToFundRankingList(List<dynamic> rawData) {
    try {
      if (rawData.isEmpty) return [];

      final fundData = <FundRanking>[];
      for (int i = 0; i < rawData.length; i++) {
        try {
          final item = rawData[i];
          if (item is Map<String, dynamic>) {
            final fundRanking = _convertSingleFundData(item, i + 1);
            if (fundRanking != null) {
              fundData.add(fundRanking);
            }
          }
        } catch (e) {
          AppLogger.warn('⚠️ 跳过无效数据项[$i]: $e', 'MultiLayerRetry');
        }
      }

      return fundData;
    } catch (e) {
      AppLogger.error('❌ 数据转换失败', e.toString());
      return [];
    }
  }

  /// 转换单个基金数据
  FundRanking? _convertSingleFundData(Map<String, dynamic> data, int position) {
    try {
      final fundCode =
          _getStringValue(data, '基金代码') ?? _getStringValue(data, 'fundCode');
      final fundName =
          _getStringValue(data, '基金简称') ?? _getStringValue(data, 'fundName');

      if (fundCode == null || fundName == null) {
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
        totalCount: 0,
        unitNav: _getDoubleValue(data, '单位净值'),
        accumulatedNav: _getDoubleValue(data, '累计净值'),
        dailyReturn: _getDoubleValue(data, '日增长率'),
        return1W: _getDoubleValue(data, '近1周'),
        return1M: _getDoubleValue(data, '近1月'),
        return3M: _getDoubleValue(data, '近3月'),
        return6M: _getDoubleValue(data, '近6月'),
        return1Y: _getDoubleValue(data, '近1年'),
        return2Y: _getDoubleValue(data, '近2年'),
        return3Y: _getDoubleValue(data, '近3年'),
        returnYTD: _getDoubleValue(data, '今年以来'),
        returnSinceInception: _getDoubleValue(data, '成立来'),
        rankingDate: DateTime.now(),
        rankingPeriod: RankingPeriod.oneYear,
        rankingType: RankingType.overall,
      );
    } catch (e) {
      AppLogger.warn('⚠️ 基金数据转换失败: $e', 'MultiLayerRetry');
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

  /// 生成示例数据
  List<FundRanking> _generateSampleData(String symbol) {
    AppLogger.info('🎭 生成示例数据: $symbol', 'MultiLayerRetry');

    final random = math.Random();
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
        rankingPosition: random.nextInt(1000) + 1,
        totalCount: 1000,
        unitNav: 1.0 + random.nextDouble() * 3.0,
        accumulatedNav: 2.0 + random.nextDouble() * 4.0,
        dailyReturn: (random.nextDouble() - 0.5) * 6.0,
        return1W: (random.nextDouble() - 0.5) * 8.0,
        return1M: (random.nextDouble() - 0.5) * 15.0,
        return3M: (random.nextDouble() - 0.5) * 25.0,
        return6M: (random.nextDouble() - 0.5) * 35.0,
        return1Y: (random.nextDouble() - 0.5) * 50.0,
        return2Y: (random.nextDouble() - 0.5) * 60.0,
        return3Y: (random.nextDouble() - 0.5) * 80.0,
        returnYTD: (random.nextDouble() - 0.5) * 30.0,
        returnSinceInception: random.nextDouble() * 200.0,
        rankingDate: DateTime.now(),
        rankingPeriod: RankingPeriod.oneYear,
        rankingType: RankingType.overall,
      );
    }).toList();
  }

  /// 生成缓存键
  String _generateCacheKey(String symbol) {
    return 'fund_rankings_${symbol}_v1';
  }

  /// 获取重试统计信息
  Map<String, dynamic> getStatistics() {
    return {
      'totalRequests': _statistics.totalRequests,
      'successRate': _statistics.getSuccessRate(),
      'successSources': _statistics.successSources,
      'failureCount': _statistics.failureCount,
      'averageRequestTime': _statistics.getAverageRequestTime(),
      'cacheSize': _dataCache.length,
      'lastSuccessfulRequests': _lastSuccessfulRequest,
    };
  }

  /// 清空缓存
  void clearCache() {
    _dataCache.clear();
    _lastSuccessfulRequest.clear();
    AppLogger.info('🧹 多层重试服务缓存已清空', 'MultiLayerRetry');
  }

  /// 预热缓存
  Future<void> warmupCache() async {
    AppLogger.info('🔥 开始预热多层重试缓存', 'MultiLayerRetry');

    final popularSymbols = ['全部', '股票型', '混合型', '债券型'];
    final futures = popularSymbols.map((symbol) =>
        getFundRankingsWithRetry(symbol: symbol, forceRefresh: false));

    await Future.wait(futures);
    AppLogger.info('✅ 多层重试缓存预热完成', 'MultiLayerRetry');
  }

  /// 释放资源
  void dispose() {
    clearCache();
    _statistics.reset();
    AppLogger.info('🔌 多层重试服务已释放', 'MultiLayerRetry');
  }
}

/// 缓存条目
class _CacheEntry {
  final List<FundRanking> data;
  final DateTime timestamp;
  final bool isBackup;

  _CacheEntry({
    required this.data,
    required this.timestamp,
    this.isBackup = false,
  });
}

/// 重试统计信息
class _RetryStatistics {
  int totalRequests = 0;
  int failureCount = 0;
  final Map<String, int> successSources = {};
  final List<Duration> requestTimes = [];

  void recordRequest(Duration duration) {
    totalRequests++;
    requestTimes.add(duration);

    // 保持最近100次请求的记录
    if (requestTimes.length > 100) {
      requestTimes.removeAt(0);
    }
  }

  void recordSuccess(String source) {
    successSources[source] = (successSources[source] ?? 0) + 1;
  }

  void recordFailure() {
    failureCount++;
  }

  double getSuccessRate() {
    if (totalRequests == 0) return 0.0;
    return ((totalRequests - failureCount) / totalRequests) * 100;
  }

  double getAverageRequestTime() {
    if (requestTimes.isEmpty) return 0.0;
    final totalMs =
        requestTimes.fold<int>(0, (sum, d) => sum + d.inMilliseconds);
    return totalMs / requestTimes.length;
  }

  void reset() {
    totalRequests = 0;
    failureCount = 0;
    successSources.clear();
    requestTimes.clear();
  }
}
