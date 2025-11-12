import 'dart:async';

import 'package:decimal/decimal.dart';

import '../../models/fund_nav_data.dart';
import '../../../../core/network/hybrid/data_type.dart';
import '../../../../core/network/hybrid/hybrid_data_manager.dart';
import '../../../../core/network/hybrid/data_fetch_strategy.dart';
import '../../../../core/utils/logger.dart';

/// 多源数据验证器
///
/// 通过多个数据源交叉验证基金净值数据，确保数据的准确性和可靠性
/// 支持多种验证策略和数据源权重配置
class MultiSourceDataValidator {
  /// 验证器实例
  static final MultiSourceDataValidator _instance =
      MultiSourceDataValidator._internal();

  factory MultiSourceDataValidator() => _instance;

  MultiSourceDataValidator._internal() {
    _initialize();
  }

  /// 混合数据管理器
  late final HybridDataManager _hybridDataManager;

  /// 数据源配置
  final Map<DataSource, DataSourceConfig> _dataSourceConfigs = {};

  /// 验证结果缓存
  final Map<String, List<ValidationRecord>> _validationHistory = {};

  /// 初始化验证器
  Future<void> _initialize() async {
    try {
      _hybridDataManager = HybridDataManager();

      // 初始化数据源配置
      _initializeDataSourceConfigs();

      AppLogger.info('MultiSourceDataValidator initialized successfully');
    } catch (e) {
      AppLogger.error('Failed to initialize MultiSourceDataValidator', e);
      rethrow;
    }
  }

  /// 初始化数据源配置
  void _initializeDataSourceConfigs() {
    _dataSourceConfigs[DataSource.websocket] = DataSourceConfig(
      reliability: 0.95,
      latency: Duration(milliseconds: 100),
      priority: 100,
      weight: 0.4,
      enabled: false, // 当前未启用
    );

    _dataSourceConfigs[DataSource.httpPolling] = DataSourceConfig(
      reliability: 0.90,
      latency: Duration(milliseconds: 2000),
      priority: 80,
      weight: 0.35,
      enabled: true,
    );

    _dataSourceConfigs[DataSource.httpOnDemand] = DataSourceConfig(
      reliability: 0.88,
      latency: Duration(milliseconds: 5000),
      priority: 60,
      weight: 0.25,
      enabled: true,
    );

    _dataSourceConfigs[DataSource.cache] = DataSourceConfig(
      reliability: 0.85,
      latency: Duration(milliseconds: 10),
      priority: 40,
      weight: 0.0, // 缓存数据不参与验证权重
      enabled: true,
    );
  }

  /// 验证基金净值数据
  Future<MultiSourceValidationResult> validateNavData(
    FundNavData navData, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final stopwatch = Stopwatch()..start();
    final fundCode = navData.fundCode;

    try {
      AppLogger.debug('Starting multi-source validation for fund $fundCode');

      // 1. 获取历史验证记录
      final history = _validationHistory[fundCode] ?? [];

      // 2. 从多个数据源获取数据进行对比
      final sourceData = await _fetchDataFromMultipleSources(fundCode, timeout);

      // 3. 执行交叉验证
      final crossValidationResult =
          _performCrossValidation(navData, sourceData);

      // 4. 数据一致性分析
      final consistencyAnalysis = _analyzeDataConsistency(navData, sourceData);

      // 5. 异常检测
      final anomalyDetection = _detectAnomalies(navData, sourceData, history);

      // 6. 计算综合置信度
      final confidenceScore = _calculateConfidenceScore(
        crossValidationResult,
        consistencyAnalysis,
        anomalyDetection,
      );

      // 7. 生成验证建议
      final recommendations = _generateRecommendations(
        crossValidationResult,
        consistencyAnalysis,
        anomalyDetection,
        confidenceScore,
      );

      stopwatch.stop();

      // 创建验证结果
      final validationResult = MultiSourceValidationResult(
        fundCode: fundCode,
        primaryData: navData,
        crossValidationResult: crossValidationResult,
        consistencyAnalysis: consistencyAnalysis,
        anomalyDetection: anomalyDetection,
        confidenceScore: confidenceScore,
        recommendations: recommendations,
        validationDuration: stopwatch.elapsed,
        validationTime: DateTime.now(),
      );

      // 保存验证记录
      _saveValidationRecord(validationResult);

      AppLogger.debug(
          'Multi-source validation completed for fund $fundCode in ${stopwatch.elapsedMilliseconds}ms');

      return validationResult;
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Multi-source validation failed for fund $fundCode', e);

      return MultiSourceValidationResult.error(
        fundCode: fundCode,
        primaryData: navData,
        errorMessage: e.toString(),
        validationDuration: stopwatch.elapsed,
      );
    }
  }

  /// 从多个数据源获取数据
  Future<Map<DataSource, FundNavData?>> _fetchDataFromMultipleSources(
    String fundCode,
    Duration timeout,
  ) async {
    final results = <DataSource, FundNavData?>{};
    final futures = <Future<void>>[];

    // HTTP轮询数据源 (使用缓存)
    if (_dataSourceConfigs[DataSource.httpPolling]?.enabled == true) {
      futures.add(_fetchFromHttpPolling(fundCode, results, timeout));
    }

    // HTTP按需请求
    if (_dataSourceConfigs[DataSource.httpOnDemand]?.enabled == true) {
      futures.add(_fetchFromHttpOnDemand(fundCode, results, timeout));
    }

    // 缓存数据源
    if (_dataSourceConfigs[DataSource.cache]?.enabled == true) {
      futures.add(_fetchFromCache(fundCode, results));
    }

    // 等待所有数据源完成
    await Future.wait(futures);

    return results;
  }

  /// 从HTTP轮询获取数据
  Future<void> _fetchFromHttpPolling(
    String fundCode,
    Map<DataSource, FundNavData?> results,
    Duration timeout,
  ) async {
    try {
      final dataItem = await _hybridDataManager.getData(
        DataType.fundNetValue,
        parameters: {'code': fundCode},
      ).timeout(timeout);

      if (dataItem != null) {
        final navData = _parseDataItemToNavData(dataItem, fundCode);
        if (navData != null) {
          results[DataSource.httpPolling] = navData;
        }
      }
    } catch (e) {
      AppLogger.debug(
          'Failed to fetch data from HTTP polling for $fundCode: $e');
    }
  }

  /// 从HTTP按需请求获取数据
  Future<void> _fetchFromHttpOnDemand(
    String fundCode,
    Map<DataSource, FundNavData?> results,
    Duration timeout,
  ) async {
    try {
      // 这里应该实现直接的API调用
      // 为了简化，我们暂时跳过这个数据源
      AppLogger.debug(
          'HTTP on-demand fetching not implemented for fund $fundCode');
    } catch (e) {
      AppLogger.debug(
          'Failed to fetch data from HTTP on-demand for $fundCode: $e');
    }
  }

  /// 从缓存获取数据
  Future<void> _fetchFromCache(
    String fundCode,
    Map<DataSource, FundNavData?> results,
  ) async {
    try {
      final cacheKey = 'fund_nav_$fundCode';
      final dataItem = await _hybridDataManager.getCachedData(
          DataType.fundNetValue, cacheKey);

      if (dataItem != null) {
        final navData = _parseDataItemToNavData(dataItem, fundCode);
        if (navData != null) {
          results[DataSource.cache] = navData;
        }
      }
    } catch (e) {
      AppLogger.debug('Failed to fetch data from cache for $fundCode: $e');
    }
  }

  /// 将DataItem转换为FundNavData
  FundNavData? _parseDataItemToNavData(DataItem dataItem, String fundCode) {
    try {
      final data = dataItem.data as Map<String, dynamic>?;
      if (data == null) return null;

      // 处理批量数据格式
      if (data.containsKey('funds')) {
        final funds = data['funds'] as List<dynamic>?;
        if (funds != null) {
          for (final fund in funds) {
            if (fund is Map<String, dynamic> && fund['code'] == fundCode) {
              return _parseSingleFundData(fund, fundCode, dataItem.timestamp);
            }
          }
        }
        return null;
      }

      // 处理单个基金数据格式
      return _parseSingleFundData(data, fundCode, dataItem.timestamp);
    } catch (e) {
      AppLogger.warn('Failed to parse DataItem to FundNavData: $e');
      return null;
    }
  }

  /// 解析单个基金数据
  FundNavData? _parseSingleFundData(
    Map<String, dynamic> data,
    String fundCode,
    DateTime timestamp,
  ) {
    try {
      final nav = data['nav'] as String?;
      final navDate = data['nav_date'] as String?;
      final accumulatedNav = data['accumulated_nav'] as String?;
      final changeRate = data['change_rate'] as String?;

      if (nav == null || navDate == null) {
        return null;
      }

      return FundNavData(
        fundCode: fundCode,
        nav: Decimal.tryParse(nav) ?? Decimal.zero,
        navDate: DateTime.tryParse(navDate) ?? DateTime.now(),
        accumulatedNav: Decimal.tryParse(accumulatedNav ?? '0') ?? Decimal.zero,
        changeRate: Decimal.tryParse(changeRate ?? '0') ?? Decimal.zero,
        timestamp: timestamp,
        dataSource: 'multi_source_validation',
      );
    } catch (e) {
      AppLogger.warn('Failed to parse fund data: $e');
      return null;
    }
  }

  /// 执行交叉验证
  CrossValidationResult _performCrossValidation(
    FundNavData primaryData,
    Map<DataSource, FundNavData?> sourceData,
  ) {
    final comparisons = <DataSourceComparison>[];
    int consistentSources = 0;
    int totalSources = 0;

    for (final entry in sourceData.entries) {
      final source = entry.key;
      final data = entry.value;

      if (data != null) {
        totalSources++;
        final comparison = _compareNavData(primaryData, data, source);
        comparisons.add(comparison);

        if (comparison.isConsistent) {
          consistentSources++;
        }
      }
    }

    // 计算一致性得分
    final consistencyScore =
        totalSources > 0 ? consistentSources / totalSources : 1.0;

    // 确定验证状态
    ValidationStatus status;
    if (consistencyScore >= 0.8) {
      status = ValidationStatus.verified;
    } else if (consistencyScore >= 0.5) {
      status = ValidationStatus.partiallyVerified;
    } else {
      status = ValidationStatus.notVerified;
    }

    return CrossValidationResult(
      status: status,
      consistencyScore: consistencyScore,
      comparisons: comparisons,
      totalSources: totalSources,
      consistentSources: consistentSources,
    );
  }

  /// 比较两个净值数据
  DataSourceComparison _compareNavData(
    FundNavData primaryData,
    FundNavData secondaryData,
    DataSource source,
  ) {
    // 净值差异
    final Decimal navDifference =
        (primaryData.nav - secondaryData.nav).abs() as Decimal;
    final Decimal navDifferenceRate = primaryData.nav > Decimal.zero
        ? (navDifference / primaryData.nav) as Decimal
        : Decimal.zero;

    // 变化率差异
    final Decimal changeRateDifference =
        (primaryData.changeRate - secondaryData.changeRate).abs() as Decimal;

    // 时间差异
    final timeDifference = primaryData.timestamp
        .difference(secondaryData.timestamp)
        .inMilliseconds;

    // 确定一致性
    bool isConsistent;
    ConsistencyLevel consistencyLevel;

    if (navDifferenceRate <= Decimal.parse('0.001') && // 0.1%
        changeRateDifference <= Decimal.parse('0.005') && // 0.5%
        timeDifference <= 60000) {
      // 1分钟
      isConsistent = true;
      consistencyLevel = ConsistencyLevel.high;
    } else if (navDifferenceRate <= Decimal.parse('0.005') && // 0.5%
        changeRateDifference <= Decimal.parse('0.02') && // 2%
        timeDifference <= 300000) {
      // 5分钟
      isConsistent = true;
      consistencyLevel = ConsistencyLevel.medium;
    } else if (navDifferenceRate <= Decimal.parse('0.01') && // 1%
        changeRateDifference <= Decimal.parse('0.05') && // 5%
        timeDifference <= 900000) {
      // 15分钟
      isConsistent = true;
      consistencyLevel = ConsistencyLevel.low;
    } else {
      isConsistent = false;
      consistencyLevel = ConsistencyLevel.none;
    }

    return DataSourceComparison(
      source: source,
      secondaryData: secondaryData,
      isConsistent: isConsistent,
      consistencyLevel: consistencyLevel,
      navDifference: navDifference,
      navDifferenceRate: navDifferenceRate,
      changeRateDifference: changeRateDifference,
      timeDifference: Duration(milliseconds: timeDifference),
    );
  }

  /// 分析数据一致性
  ConsistencyAnalysis _analyzeDataConsistency(
    FundNavData primaryData,
    Map<DataSource, FundNavData?> sourceData,
  ) {
    final validSources = sourceData.values.whereType<FundNavData>().toList();
    if (validSources.isEmpty) {
      return const ConsistencyAnalysis(
        overallScore: 1.0,
        reliabilityScore: 1.0,
        freshnessScore: 1.0,
        trendConsistency: 1.0,
      );
    }

    // 计算可靠性得分
    double reliabilityScore = 0.0;
    double totalWeight = 0.0;

    for (final entry in sourceData.entries) {
      final source = entry.key;
      final data = entry.value;

      if (data != null && _dataSourceConfigs.containsKey(source)) {
        final config = _dataSourceConfigs[source]!;
        reliabilityScore += config.reliability * config.weight;
        totalWeight += config.weight;
      }
    }

    reliabilityScore = totalWeight > 0 ? reliabilityScore / totalWeight : 1.0;

    // 计算数据新鲜度得分
    final now = DateTime.now();
    double freshnessScore = 0.0;
    int validDataCount = 0;

    for (final data in validSources) {
      final age = now.difference(data.timestamp).inMinutes;
      double score = 1.0;

      if (age > 60) {
        score = 0.5; // 1小时后数据新鲜度下降
      } else if (age > 1440) {
        // 24小时
        score = 0.1;
      }

      freshnessScore += score;
      validDataCount++;
    }

    freshnessScore = validDataCount > 0 ? freshnessScore / validDataCount : 1.0;

    // 趋势一致性分析 (简化版本)
    final trendConsistency =
        _calculateTrendConsistency(primaryData, validSources);

    // 综合得分
    final overallScore = (reliabilityScore * 0.4 +
        freshnessScore * 0.3 +
        trendConsistency * 0.3);

    return ConsistencyAnalysis(
      overallScore: overallScore,
      reliabilityScore: reliabilityScore,
      freshnessScore: freshnessScore,
      trendConsistency: trendConsistency,
    );
  }

  /// 计算趋势一致性
  double _calculateTrendConsistency(
      FundNavData primaryData, List<FundNavData> sourceData) {
    if (sourceData.isEmpty) return 1.0;

    int consistentTrends = 0;
    for (final data in sourceData) {
      final primaryTrend = primaryData.changeRate > Decimal.zero
          ? 1
          : (primaryData.changeRate < Decimal.zero ? -1 : 0);
      final dataTrend = data.changeRate > Decimal.zero
          ? 1
          : (data.changeRate < Decimal.zero ? -1 : 0);

      if (primaryTrend == dataTrend) {
        consistentTrends++;
      }
    }

    return consistentTrends / sourceData.length;
  }

  /// 检测异常
  AnomalyDetection _detectAnomalies(
    FundNavData primaryData,
    Map<DataSource, FundNavData?> sourceData,
    List<ValidationRecord> history,
  ) {
    final anomalies = <AnomalyInfo>[];

    // 1. 数据源冲突检测
    final conflicts = _detectDataConflicts(primaryData, sourceData);
    anomalies.addAll(conflicts);

    // 2. 历史异常检测
    final historicalAnomalies =
        _detectHistoricalAnomalies(primaryData, history);
    anomalies.addAll(historicalAnomalies);

    // 3. 业务逻辑异常检测
    final businessAnomalies = _detectBusinessAnomalies(primaryData);
    anomalies.addAll(businessAnomalies);

    // 确定异常严重程度
    AnomalySeverity maxSeverity = AnomalySeverity.none;
    for (final anomaly in anomalies) {
      if (anomaly.severity.index > maxSeverity.index) {
        maxSeverity = anomaly.severity;
      }
    }

    return AnomalyDetection(
      hasAnomalies: anomalies.isNotEmpty,
      anomalies: anomalies,
      severity: maxSeverity,
      anomalyCount: anomalies.length,
    );
  }

  /// 检测数据冲突
  List<AnomalyInfo> _detectDataConflicts(
    FundNavData primaryData,
    Map<DataSource, FundNavData?> sourceData,
  ) {
    final conflicts = <AnomalyInfo>[];

    for (final entry in sourceData.entries) {
      final source = entry.key;
      final data = entry.value;

      if (data != null) {
        final Decimal navDifference =
            (primaryData.nav - data.nav).abs() as Decimal;
        final Decimal differenceRate = primaryData.nav > Decimal.zero
            ? (navDifference / primaryData.nav) as Decimal
            : Decimal.zero;

        if (differenceRate > Decimal.parse('0.01')) {
          // 1%
          conflicts.add(AnomalyInfo(
            type: AnomalyType.dataConflict,
            severity: differenceRate > Decimal.parse('0.05')
                ? AnomalySeverity.high
                : AnomalySeverity.medium,
            description:
                '数据源冲突: ${source.name} 差异 ${(differenceRate * Decimal.fromInt(100)).toStringAsFixed(2)}%',
            affectedSource: source,
          ));
        }
      }
    }

    return conflicts;
  }

  /// 检测历史异常
  List<AnomalyInfo> _detectHistoricalAnomalies(
    FundNavData primaryData,
    List<ValidationRecord> history,
  ) {
    final anomalies = <AnomalyInfo>[];

    if (history.length < 3) return anomalies;

    // 获取最近的历史数据
    final recentHistory = history.take(5).toList();

    // 计算平均变化率
    final sum = recentHistory
        .map((record) => record.primaryData.changeRate)
        .reduce((a, b) => a + b);
    final Decimal avgChangeRate =
        (sum / Decimal.fromInt(recentHistory.length)) as Decimal;

    final Decimal changeDifference =
        (primaryData.changeRate - avgChangeRate).abs() as Decimal;

    if (changeDifference > Decimal.parse('0.05')) {
      // 5%
      anomalies.add(AnomalyInfo(
        type: AnomalyType.unusualChange,
        severity: changeDifference > Decimal.parse('0.1')
            ? AnomalySeverity.high
            : AnomalySeverity.medium,
        description:
            '异常变化: 与历史平均差异 ${(changeDifference * Decimal.fromInt(100)).toStringAsFixed(2)}%',
      ));
    }

    return anomalies;
  }

  /// 检测业务逻辑异常
  List<AnomalyInfo> _detectBusinessAnomalies(FundNavData primaryData) {
    final anomalies = <AnomalyInfo>[];

    // 净值合理性检查
    if (primaryData.nav < Decimal.parse('0.01')) {
      // < 0.01
      anomalies.add(AnomalyInfo(
        type: AnomalyType.unreasonableValue,
        severity: AnomalySeverity.high,
        description: '净值过低: ${primaryData.nav.toStringAsFixed(4)}',
      ));
    }

    // 变化率合理性检查
    if (primaryData.changeRate.abs() > Decimal.parse('0.2')) {
      // > 20%
      anomalies.add(AnomalyInfo(
        type: AnomalyType.unusualChange,
        severity: AnomalySeverity.high,
        description: '单日变化率过大: ${primaryData.changePercentageFormatted}',
      ));
    }

    return anomalies;
  }

  /// 计算综合置信度
  double _calculateConfidenceScore(
    CrossValidationResult crossValidation,
    ConsistencyAnalysis consistencyAnalysis,
    AnomalyDetection anomalyDetection,
  ) {
    double score = 1.0;

    // 交叉验证权重 40%
    score *= (0.6 + crossValidation.consistencyScore * 0.4);

    // 一致性分析权重 30%
    score *= (0.7 + consistencyAnalysis.overallScore * 0.3);

    // 异常检测权重 30%
    double anomalyPenalty = 0.0;
    if (anomalyDetection.hasAnomalies) {
      switch (anomalyDetection.severity) {
        case AnomalySeverity.critical:
          anomalyPenalty = 0.5;
          break;
        case AnomalySeverity.high:
          anomalyPenalty = 0.3;
          break;
        case AnomalySeverity.medium:
          anomalyPenalty = 0.15;
          break;
        case AnomalySeverity.low:
          anomalyPenalty = 0.05;
          break;
        case AnomalySeverity.none:
          anomalyPenalty = 0.0;
          break;
      }
    }

    score *= (1.0 - anomalyPenalty);

    return score.clamp(0.0, 1.0);
  }

  /// 生成验证建议
  List<ValidationRecommendation> _generateRecommendations(
    CrossValidationResult crossValidation,
    ConsistencyAnalysis consistencyAnalysis,
    AnomalyDetection anomalyDetection,
    double confidenceScore,
  ) {
    final recommendations = <ValidationRecommendation>[];

    // 基于置信度生成建议
    if (confidenceScore < 0.5) {
      recommendations.add(ValidationRecommendation(
        type: RecommendationType.lowConfidence,
        priority: RecommendationPriority.high,
        message: '数据置信度较低，建议重新获取数据',
        action: 'refresh_data',
      ));
    } else if (confidenceScore < 0.7) {
      recommendations.add(ValidationRecommendation(
        type: RecommendationType.moderateConfidence,
        priority: RecommendationPriority.medium,
        message: '数据置信度中等，建议谨慎使用',
        action: 'monitor_closely',
      ));
    }

    // 基于异常生成建议
    for (final anomaly in anomalyDetection.anomalies) {
      switch (anomaly.type) {
        case AnomalyType.dataConflict:
          recommendations.add(ValidationRecommendation(
            type: RecommendationType.dataConflict,
            priority: RecommendationPriority.high,
            message: '检测到数据源冲突，建议核实数据准确性',
            action: 'verify_sources',
          ));
          break;
        case AnomalyType.unusualChange:
          recommendations.add(ValidationRecommendation(
            type: RecommendationType.unusualChange,
            priority: RecommendationPriority.medium,
            message: '检测到异常变化，建议关注市场动态',
            action: 'market_check',
          ));
          break;
        case AnomalyType.unreasonableValue:
          recommendations.add(ValidationRecommendation(
            type: RecommendationType.dataError,
            priority: RecommendationPriority.critical,
            message: '检测到不合理数据，建议立即检查',
            action: 'investigate_error',
          ));
          break;
        case AnomalyType.dataError:
          recommendations.add(ValidationRecommendation(
            type: RecommendationType.dataError,
            priority: RecommendationPriority.critical,
            message: '检测到数据错误，建议立即检查数据源',
            action: 'investigate_error',
          ));
          break;
      }
    }

    return recommendations;
  }

  /// 保存验证记录
  void _saveValidationRecord(MultiSourceValidationResult result) {
    final record = ValidationRecord(
      fundCode: result.fundCode,
      primaryData: result.primaryData,
      validationResult: result,
      timestamp: DateTime.now(),
    );

    if (!_validationHistory.containsKey(result.fundCode)) {
      _validationHistory[result.fundCode] = [];
    }

    final history = _validationHistory[result.fundCode]!;
    history.insert(0, record);

    // 保持最近20条记录
    while (history.length > 20) {
      history.removeLast();
    }
  }

  /// 获取验证历史
  List<ValidationRecord>? getValidationHistory(String fundCode) {
    return _validationHistory[fundCode];
  }

  /// 清理验证历史
  void clearValidationHistory() {
    _validationHistory.clear();
  }

  /// 清理指定基金的验证历史
  void clearValidationHistoryForFund(String fundCode) {
    _validationHistory.remove(fundCode);
  }

  /// 更新数据源配置
  void updateDataSourceConfig(DataSource source, DataSourceConfig config) {
    _dataSourceConfigs[source] = config;
    AppLogger.info('Updated data source config for ${source.name}');
  }

  /// 获取数据源配置
  DataSourceConfig? getDataSourceConfig(DataSource source) {
    return _dataSourceConfigs[source];
  }

  /// 获取所有数据源配置
  Map<DataSource, DataSourceConfig> getAllDataSourceConfigs() {
    return Map.unmodifiable(_dataSourceConfigs);
  }
}

/// 数据源配置
class DataSourceConfig {
  /// 可靠性评分 (0-1)
  final double reliability;

  /// 典型延迟
  final Duration latency;

  /// 优先级
  final int priority;

  /// 权重 (用于计算综合得分)
  final double weight;

  /// 是否启用
  final bool enabled;

  const DataSourceConfig({
    required this.reliability,
    required this.latency,
    required this.priority,
    required this.weight,
    required this.enabled,
  });
}

/// 验证配置
class ValidationConfig {
  /// 超时时间
  final Duration defaultTimeout;

  /// 最大重试次数
  final int maxRetries;

  /// 启用历史分析
  final bool enableHistoricalAnalysis;

  /// 历史记录数量
  final int historyRecordCount;

  /// 一致性阈值
  final double consistencyThreshold;

  const ValidationConfig({
    this.defaultTimeout = const Duration(seconds: 10),
    this.maxRetries = 3,
    this.enableHistoricalAnalysis = true,
    this.historyRecordCount = 20,
    this.consistencyThreshold = 0.8,
  });
}

/// 多源验证结果
class MultiSourceValidationResult {
  final String fundCode;
  final FundNavData primaryData;
  final CrossValidationResult crossValidationResult;
  final ConsistencyAnalysis consistencyAnalysis;
  final AnomalyDetection anomalyDetection;
  final double confidenceScore;
  final List<ValidationRecommendation> recommendations;
  final Duration validationDuration;
  final DateTime validationTime;
  final String? errorMessage;

  const MultiSourceValidationResult({
    required this.fundCode,
    required this.primaryData,
    required this.crossValidationResult,
    required this.consistencyAnalysis,
    required this.anomalyDetection,
    required this.confidenceScore,
    required this.recommendations,
    required this.validationDuration,
    required this.validationTime,
    this.errorMessage,
  });

  factory MultiSourceValidationResult.error({
    required String fundCode,
    required FundNavData primaryData,
    required String errorMessage,
    required Duration validationDuration,
  }) {
    return MultiSourceValidationResult(
      fundCode: fundCode,
      primaryData: primaryData,
      crossValidationResult: const CrossValidationResult(
        status: ValidationStatus.error,
        consistencyScore: 0.0,
        comparisons: [],
        totalSources: 0,
        consistentSources: 0,
      ),
      consistencyAnalysis: const ConsistencyAnalysis(
        overallScore: 0.0,
        reliabilityScore: 0.0,
        freshnessScore: 0.0,
        trendConsistency: 0.0,
      ),
      anomalyDetection: const AnomalyDetection(
        hasAnomalies: true,
        anomalies: [],
        severity: AnomalySeverity.critical,
        anomalyCount: 1,
      ),
      confidenceScore: 0.0,
      recommendations: [
        ValidationRecommendation(
          type: RecommendationType.validationError,
          priority: RecommendationPriority.critical,
          message: '验证过程发生错误',
          action: 'investigate_error',
        ),
      ],
      validationDuration: validationDuration,
      validationTime: DateTime.now(),
      errorMessage: errorMessage,
    );
  }

  bool get isValid => confidenceScore >= 0.7 && !anomalyDetection.hasAnomalies;
  bool get hasWarnings =>
      confidenceScore < 0.9 || anomalyDetection.anomalies.isNotEmpty;

  @override
  String toString() {
    return 'MultiSourceValidationResult(fund: $fundCode, confidence: ${(confidenceScore * 100).toStringAsFixed(1)}%, valid: $isValid)';
  }
}

/// 交叉验证结果
class CrossValidationResult {
  final ValidationStatus status;
  final double consistencyScore;
  final List<DataSourceComparison> comparisons;
  final int totalSources;
  final int consistentSources;

  const CrossValidationResult({
    required this.status,
    required this.consistencyScore,
    required this.comparisons,
    required this.totalSources,
    required this.consistentSources,
  });
}

/// 数据源比较
class DataSourceComparison {
  final DataSource source;
  final FundNavData secondaryData;
  final bool isConsistent;
  final ConsistencyLevel consistencyLevel;
  final Decimal navDifference;
  final Decimal navDifferenceRate;
  final Decimal changeRateDifference;
  final Duration timeDifference;

  const DataSourceComparison({
    required this.source,
    required this.secondaryData,
    required this.isConsistent,
    required this.consistencyLevel,
    required this.navDifference,
    required this.navDifferenceRate,
    required this.changeRateDifference,
    required this.timeDifference,
  });
}

/// 一致性级别
enum ConsistencyLevel {
  none('不一致'),
  low('低一致性'),
  medium('中等一致性'),
  high('高一致性');

  const ConsistencyLevel(this.description);
  final String description;
}

/// 验证状态
enum ValidationStatus {
  verified('已验证'),
  partiallyVerified('部分验证'),
  notVerified('未验证'),
  error('错误');

  const ValidationStatus(this.description);
  final String description;
}

/// 一致性分析
class ConsistencyAnalysis {
  final double overallScore;
  final double reliabilityScore;
  final double freshnessScore;
  final double trendConsistency;

  const ConsistencyAnalysis({
    required this.overallScore,
    required this.reliabilityScore,
    required this.freshnessScore,
    required this.trendConsistency,
  });
}

/// 异常检测
class AnomalyDetection {
  final bool hasAnomalies;
  final List<AnomalyInfo> anomalies;
  final AnomalySeverity severity;
  final int anomalyCount;

  const AnomalyDetection({
    required this.hasAnomalies,
    required this.anomalies,
    required this.severity,
    required this.anomalyCount,
  });
}

/// 异常信息
class AnomalyInfo {
  final AnomalyType type;
  final AnomalySeverity severity;
  final String description;
  final DataSource? affectedSource;

  const AnomalyInfo({
    required this.type,
    required this.severity,
    required this.description,
    this.affectedSource,
  });
}

/// 异常类型
enum AnomalyType {
  dataConflict('数据冲突'),
  unusualChange('异常变化'),
  unreasonableValue('不合理数值'),
  dataError('数据错误');

  const AnomalyType(this.description);
  final String description;
}

/// 异常严重程度
enum AnomalySeverity {
  none('无'),
  low('轻微'),
  medium('中等'),
  high('严重'),
  critical('紧急');

  const AnomalySeverity(this.description);
  final String description;
}

/// 验证建议
class ValidationRecommendation {
  final RecommendationType type;
  final RecommendationPriority priority;
  final String message;
  final String action;

  const ValidationRecommendation({
    required this.type,
    required this.priority,
    required this.message,
    required this.action,
  });
}

/// 建议类型
enum RecommendationType {
  lowConfidence('低置信度'),
  moderateConfidence('中等置信度'),
  dataConflict('数据冲突'),
  unusualChange('异常变化'),
  dataError('数据错误'),
  validationError('验证错误');

  const RecommendationType(this.description);
  final String description;
}

/// 建议优先级
enum RecommendationPriority {
  low('低'),
  medium('中'),
  high('高'),
  critical('紧急');

  const RecommendationPriority(this.description);
  final String description;
}

/// 验证记录
class ValidationRecord {
  final String fundCode;
  final FundNavData primaryData;
  final MultiSourceValidationResult validationResult;
  final DateTime timestamp;

  const ValidationRecord({
    required this.fundCode,
    required this.primaryData,
    required this.validationResult,
    required this.timestamp,
  });
}
