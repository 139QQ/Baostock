import 'dart:async';

import 'package:decimal/decimal.dart';

import '../../../../core/utils/logger.dart';
import '../../models/market_index_data.dart';
import 'index_data_validator.dart';

/// 多源数据验证器
///
/// 通过多个数据源交叉验证市场指数数据的准确性
class MultiSourceIndexValidator {
  /// 数据源列表
  final List<IndexDataSource> _dataSources;

  /// 单数据验证器
  final IndexDataValidator _singleValidator;

  /// 验证参数
  final MultiSourceValidationParameters _parameters;

  /// 数据缓存 (用于跨源比较)
  final Map<String, List<IndexDataWithSource>> _dataCache = {};

  /// 构造函数
  MultiSourceIndexValidator({
    List<IndexDataSource>? dataSources,
    IndexValidationParameters? validationParameters,
    MultiSourceValidationParameters? multiSourceParameters,
  })  : _dataSources = dataSources ?? _getDefaultDataSources(),
        _singleValidator = IndexDataValidator(parameters: validationParameters),
        _parameters =
            multiSourceParameters ?? MultiSourceValidationParameters();

  /// 获取默认数据源列表
  static List<IndexDataSource> _getDefaultDataSources() {
    return [
      IndexDataSource.akshare,
      IndexDataSource.tushare,
      IndexDataSource.eastmoney,
    ];
  }

  /// 验证单个指数数据
  Future<MultiSourceValidationResult> validateIndex(
      MarketIndexData primaryData) async {
    final indexCode = primaryData.code;
    final validationIssues = <ValidationIssue>[];
    final consensusData = <MarketIndexData>[];
    final sourceReliability = <IndexDataSource, SourceReliability>{};

    try {
      // 1. 验证主数据源
      final primaryValidation = _singleValidator.validate(primaryData);
      validationIssues.addAll(primaryValidation.issues);

      // 2. 从其他数据源获取数据进行对比
      final comparisonResults =
          await _fetchComparisonData(indexCode, primaryData);

      // 3. 分析数据一致性
      final consistencyAnalysis =
          _analyzeDataConsistency(primaryData, comparisonResults);
      validationIssues.addAll(consistencyAnalysis.issues);
      consensusData.addAll(consistencyAnalysis.consensusData);

      // 4. 评估数据源可靠性
      for (final entry in comparisonResults.entries) {
        sourceReliability[entry.key] =
            _assessSourceReliability(entry.key, entry.value, primaryData);
      }

      // 5. 计算综合质量评分
      final qualityScore = _calculateQualityScore(
          primaryValidation, consistencyAnalysis, sourceReliability);

      // 6. 缓存数据用于后续验证
      _cacheValidationData(indexCode, primaryData, comparisonResults);

      final result = MultiSourceValidationResult(
        indexCode: indexCode,
        isValid: validationIssues
            .every((issue) => issue.severity != ValidationSeverity.error),
        qualityScore: qualityScore,
        consensusData: consensusData,
        primaryDataQuality: primaryValidation.qualityLevel,
        consistencyLevel: consistencyAnalysis.consistencyLevel,
        sourceReliability: sourceReliability,
        issues: validationIssues,
        validationTime: DateTime.now(),
      );

      AppLogger.debug(
          'Multi-source validation completed for $indexCode: quality=${qualityScore.toStringAsFixed(2)}, consistency=${consistencyAnalysis.consistencyLevel.name}');

      return result;
    } catch (e) {
      AppLogger.error('Multi-source validation failed for $indexCode: $e', e);

      return MultiSourceValidationResult(
        indexCode: indexCode,
        isValid: false,
        qualityScore: 0.0,
        consensusData: [primaryData], // 至少返回主数据
        primaryDataQuality: DataQualityLevel.poor,
        consistencyLevel: ConsistencyLevel.unknown,
        sourceReliability: sourceReliability,
        issues: [
          ValidationIssue(
            field: 'multiSource',
            message: '多源验证失败: $e',
            severity: ValidationSeverity.error,
          )
        ],
        validationTime: DateTime.now(),
      );
    }
  }

  /// 获取对比数据
  Future<Map<IndexDataSource, MarketIndexData>> _fetchComparisonData(
    String indexCode,
    MarketIndexData primaryData,
  ) async {
    final comparisonResults = <IndexDataSource, MarketIndexData>{};

    // 并发从多个数据源获取数据
    final futures = <Future<MapEntry<IndexDataSource, MarketIndexData?>>>[];

    for (final source in _dataSources) {
      if (source != _getDataSource(primaryData.dataSource)) {
        futures.add(_fetchFromSource(indexCode, source));
      }
    }

    try {
      final results = await Future.wait(
        futures,
        eagerError: false,
      ).timeout(Duration(seconds: _parameters.fetchTimeoutSeconds));

      for (final result in results) {
        if (result.value != null) {
          comparisonResults[result.key] = result.value!;
        }
      }
    } catch (e) {
      AppLogger.warn('Failed to fetch comparison data for $indexCode: $e');
    }

    return comparisonResults;
  }

  /// 从单个数据源获取数据
  Future<MapEntry<IndexDataSource, MarketIndexData?>> _fetchFromSource(
    String indexCode,
    IndexDataSource source,
  ) async {
    try {
      // 模拟从不同数据源获取数据
      // 在实际实现中，这里会调用相应的API
      await Future.delayed(Duration(milliseconds: source.fetchDelayMs));

      final data = await _mockFetchFromSource(indexCode, source);
      return MapEntry(source, data);
    } catch (e) {
      AppLogger.warn('Failed to fetch from ${source.name} for $indexCode: $e');
      return MapEntry(source, null);
    }
  }

  /// 模拟从数据源获取数据
  Future<MarketIndexData> _mockFetchFromSource(
      String indexCode, IndexDataSource source) async {
    // 这里应该实现真实的API调用
    // 暂时返回基于主数据的模拟数据，添加一些随机差异

    // 生成一些随机差异来模拟不同数据源的差异
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    final priceVariation = Decimal.parse((random / 1000).toString());

    // 获取基础数据 (实际应用中从API获取)
    final baseData = await _getBaseIndexData(indexCode);

    return MarketIndexData(
      code: indexCode,
      name: baseData.name,
      currentValue: baseData.currentValue + priceVariation,
      previousClose: baseData.previousClose,
      openPrice: baseData.openPrice,
      highPrice: baseData.highPrice,
      lowPrice: baseData.lowPrice,
      changeAmount: baseData.changeAmount + priceVariation,
      changePercentage: baseData.changePercentage +
          Decimal.parse(
              ((priceVariation * Decimal.fromInt(100)) / baseData.previousClose)
                  .toString()),
      volume: baseData.volume + (random * 1000).toInt(),
      turnover:
          baseData.turnover + Decimal.parse((random * 1000000).toString()),
      updateTime: DateTime.now().subtract(Duration(seconds: random)),
      marketStatus: baseData.marketStatus,
      qualityLevel: source.defaultQualityLevel,
      dataSource: source.name,
    );
  }

  /// 获取基础指数数据 (模拟)
  Future<MarketIndexData> _getBaseIndexData(String indexCode) async {
    // 模拟基础数据，实际应用中应该从缓存或数据库获取
    return MarketIndexData(
      code: indexCode,
      name: MarketIndexConstants.getIndexName(indexCode),
      currentValue: Decimal.parse('3000.0'),
      previousClose: Decimal.parse('2950.0'),
      openPrice: Decimal.parse('2980.0'),
      highPrice: Decimal.parse('3020.0'),
      lowPrice: Decimal.parse('2960.0'),
      changeAmount: Decimal.parse('50.0'),
      changePercentage: Decimal.parse('1.69'),
      volume: 1000000,
      turnover: Decimal.parse('3000000000'),
      updateTime: DateTime.now(),
      marketStatus: MarketStatus.trading,
      qualityLevel: DataQualityLevel.good,
      dataSource: 'mock',
    );
  }

  /// 分析数据一致性
  ConsistencyAnalysis _analyzeDataConsistency(
    MarketIndexData primaryData,
    Map<IndexDataSource, MarketIndexData> comparisonData,
  ) {
    final issues = <ValidationIssue>[];
    final consensusData = <MarketIndexData>[];
    final priceDifferences = <Decimal>[];

    // 添加主数据到共识数据
    consensusData.add(primaryData);

    // 分析每个数据源的一致性
    for (final entry in comparisonData.entries) {
      final source = entry.key;
      final data = entry.value;

      // 验证数据
      final validation = _singleValidator.validate(data);
      if (!validation.isValid) {
        issues.add(ValidationIssue(
          field: 'source_${source.name}',
          message: '数据源${source.name}数据验证失败',
          severity: ValidationSeverity.warning,
        ));
        continue;
      }

      // 计算价格差异
      final priceDiff = (data.currentValue - primaryData.currentValue).abs();
      priceDifferences.add(priceDiff);

      // 检查价格差异是否在可接受范围内
      final Decimal priceDiffPercentage = Decimal.parse(
          ((priceDiff * Decimal.fromInt(100)) / primaryData.currentValue)
              .toString());

      if (priceDiffPercentage > _parameters.maxAcceptablePriceDiff) {
        issues.add(ValidationIssue(
          field: 'priceConsistency',
          message:
              '与数据源${source.name}价格差异过大: ${priceDiffPercentage.toStringAsFixed(3)}%',
          severity: ValidationSeverity.warning,
        ));
      } else {
        consensusData.add(data);
      }
    }

    // 计算一致性等级
    final consistencyLevel =
        _calculateConsistencyLevel(priceDifferences, comparisonData.length);

    return ConsistencyAnalysis(
      consistencyLevel: consistencyLevel,
      consensusData: consensusData,
      issues: issues,
      averagePriceDifference: priceDifferences.isEmpty
          ? Decimal.zero
          : Decimal.parse((priceDifferences.reduce((a, b) => a + b) /
                  Decimal.fromInt(priceDifferences.length))
              .toString()),
    );
  }

  /// 计算一致性等级
  ConsistencyLevel _calculateConsistencyLevel(
      List<Decimal> priceDifferences, int sourceCount) {
    if (sourceCount == 0) {
      return ConsistencyLevel.unknown;
    }

    if (priceDifferences.isEmpty) {
      return ConsistencyLevel.high;
    }

    final Decimal avgDifference = Decimal.parse(
        (priceDifferences.reduce((a, b) => a + b) /
                Decimal.fromInt(priceDifferences.length))
            .toString());
    final avgDifferencePercentage = avgDifference; // 假设基础价格为1

    if (avgDifferencePercentage <= Decimal.parse('0.1')) {
      // 0.1%
      return ConsistencyLevel.high;
    } else if (avgDifferencePercentage <= Decimal.parse('0.5')) {
      // 0.5%
      return ConsistencyLevel.medium;
    } else {
      return ConsistencyLevel.low;
    }
  }

  /// 评估数据源可靠性
  SourceReliability _assessSourceReliability(
    IndexDataSource source,
    MarketIndexData data,
    MarketIndexData primaryData,
  ) {
    // 验证数据质量
    final validation = _singleValidator.validate(data);

    // 计算价格一致性
    final priceDiff = (data.currentValue - primaryData.currentValue).abs();
    final Decimal priceDiffPercentage = Decimal.parse(
        ((priceDiff * Decimal.fromInt(100)) / primaryData.currentValue)
            .toString());

    // 计算更新时间新鲜度
    final timeDiff = DateTime.now().difference(data.updateTime);
    final freshnessScore = timeDiff.inSeconds < 60
        ? 1.0
        : timeDiff.inSeconds < 300
            ? 0.8
            : 0.5;

    // 计算可靠性评分
    double reliabilityScore = source.baseReliability;

    // 数据质量影响
    switch (validation.qualityLevel) {
      case DataQualityLevel.excellent:
        reliabilityScore *= 1.0;
        break;
      case DataQualityLevel.good:
        reliabilityScore *= 0.9;
        break;
      case DataQualityLevel.fair:
        reliabilityScore *= 0.7;
        break;
      case DataQualityLevel.poor:
        reliabilityScore *= 0.5;
        break;
      case DataQualityLevel.unknown:
        reliabilityScore *= 0.3;
        break;
    }

    // 价格一致性影响
    if (priceDiffPercentage <= Decimal.parse('0.1')) {
      reliabilityScore *= 1.0;
    } else if (priceDiffPercentage <= Decimal.parse('0.5')) {
      reliabilityScore *= 0.9;
    } else {
      reliabilityScore *= 0.7;
    }

    // 综合评分
    reliabilityScore *= freshnessScore;
    reliabilityScore = reliabilityScore.clamp(0.0, 1.0);

    return SourceReliability(
      source: source,
      reliabilityScore: reliabilityScore,
      qualityLevel: validation.qualityLevel,
      priceDifference: priceDiffPercentage,
      freshnessScore: freshnessScore,
      lastUpdateTime: data.updateTime,
    );
  }

  /// 计算综合质量评分
  double _calculateQualityScore(
    ValidationResult primaryValidation,
    ConsistencyAnalysis consistencyAnalysis,
    Map<IndexDataSource, SourceReliability> sourceReliability,
  ) {
    double score = 0.0;

    // 主数据质量 (权重 40%)
    switch (primaryValidation.qualityLevel) {
      case DataQualityLevel.excellent:
        score += 0.4;
        break;
      case DataQualityLevel.good:
        score += 0.3;
        break;
      case DataQualityLevel.fair:
        score += 0.2;
        break;
      case DataQualityLevel.poor:
        score += 0.1;
        break;
      case DataQualityLevel.unknown:
        score += 0.05;
        break;
    }

    // 一致性等级 (权重 40%)
    switch (consistencyAnalysis.consistencyLevel) {
      case ConsistencyLevel.high:
        score += 0.4;
        break;
      case ConsistencyLevel.medium:
        score += 0.3;
        break;
      case ConsistencyLevel.low:
        score += 0.1;
        break;
      case ConsistencyLevel.unknown:
        score += 0.2;
        break;
    }

    // 数据源可靠性 (权重 20%)
    if (sourceReliability.isNotEmpty) {
      final avgReliability = sourceReliability.values
              .map((r) => r.reliabilityScore)
              .reduce((a, b) => a + b) /
          sourceReliability.length;
      score += avgReliability * 0.2;
    } else {
      score += 0.1; // 没有对比数据时的默认分数
    }

    return score.clamp(0.0, 1.0);
  }

  /// 缓存验证数据
  void _cacheValidationData(
    String indexCode,
    MarketIndexData primaryData,
    Map<IndexDataSource, MarketIndexData> comparisonData,
  ) {
    if (!_dataCache.containsKey(indexCode)) {
      _dataCache[indexCode] = [];
    }

    final cache = _dataCache[indexCode]!;

    // 添加主数据
    cache.add(IndexDataWithSource(
      data: primaryData,
      source: _getDataSource(primaryData.dataSource),
      timestamp: DateTime.now(),
    ));

    // 添加对比数据
    for (final entry in comparisonData.entries) {
      cache.add(IndexDataWithSource(
        data: entry.value,
        source: entry.key,
        timestamp: DateTime.now(),
      ));
    }

    // 保持缓存大小在合理范围内
    while (cache.length > _parameters.maxCacheSize) {
      cache.removeAt(0);
    }
  }

  /// 根据名称获取数据源
  IndexDataSource _getDataSource(String sourceName) {
    return _dataSources.firstWhere(
      (source) => source.name == sourceName,
      orElse: () => IndexDataSource.unknown,
    );
  }

  /// 批量验证多个指数
  Future<List<MultiSourceValidationResult>> validateBatch(
      List<MarketIndexData> dataList) async {
    final futures = dataList.map((data) => validateIndex(data)).toList();

    try {
      return await Future.wait(futures);
    } catch (e) {
      AppLogger.error('Batch validation failed: $e', e);
      rethrow;
    }
  }

  /// 获取验证统计信息
  MultiSourceValidationStatistics getStatistics(
      List<MultiSourceValidationResult> results) {
    final int total = results.length;
    final int valid = results.where((r) => r.isValid).length;
    final int invalid = total - valid;

    final qualityScores = results.map((r) => r.qualityScore).toList();
    final avgQualityScore = qualityScores.isEmpty
        ? 0.0
        : qualityScores.reduce((a, b) => a + b) / qualityScores.length;

    final consistencyDistribution = <ConsistencyLevel, int>{};
    for (final result in results) {
      consistencyDistribution[result.consistencyLevel] =
          (consistencyDistribution[result.consistencyLevel] ?? 0) + 1;
    }

    return MultiSourceValidationStatistics(
      total: total,
      valid: valid,
      invalid: invalid,
      averageQualityScore: avgQualityScore,
      consistencyDistribution: consistencyDistribution,
      timestamp: DateTime.now(),
    );
  }

  /// 清理缓存
  void clearCache() {
    _dataCache.clear();
  }

  /// 清理特定指数的缓存
  void clearCacheForIndex(String indexCode) {
    _dataCache.remove(indexCode);
  }
}

/// 数据源定义
enum IndexDataSource {
  /// AKShare数据源
  akshare('akshare', 'AKShare', 0.9, DataQualityLevel.good, 200),

  /// Tushare数据源
  tushare('tushare', 'Tushare', 0.85, DataQualityLevel.good, 300),

  /// 东方财富数据源
  eastmoney('eastmoney', '东方财富', 0.8, DataQualityLevel.fair, 150),

  /// 新浪财经数据源
  sina('sina', '新浪财经', 0.75, DataQualityLevel.fair, 100),

  /// 腾讯财经数据源
  tencent('tencent', '腾讯财经', 0.7, DataQualityLevel.fair, 120),

  /// 未知数据源
  unknown('unknown', '未知', 0.5, DataQualityLevel.poor, 500);

  const IndexDataSource(
    this.name,
    this.displayName,
    this.baseReliability,
    this.defaultQualityLevel,
    this.fetchDelayMs,
  );

  /// 数据源名称
  final String name;

  /// 显示名称
  final String displayName;

  /// 基础可靠性评分 (0-1)
  final double baseReliability;

  /// 默认数据质量等级
  final DataQualityLevel defaultQualityLevel;

  /// 模拟获取延迟 (毫秒)
  final int fetchDelayMs;
}

/// 带数据源信息的数据
class IndexDataWithSource {
  /// 市场指数数据
  final MarketIndexData data;

  /// 数据源
  final IndexDataSource source;

  /// 时间戳
  final DateTime timestamp;

  /// 创建带数据源信息的数据实例
  const IndexDataWithSource({
    required this.data,
    required this.source,
    required this.timestamp,
  });
}

/// 多源验证结果
class MultiSourceValidationResult {
  /// 指数代码
  final String indexCode;

  /// 是否有效
  final bool isValid;

  /// 质量评分
  final double qualityScore;

  /// 共识数据
  final List<MarketIndexData> consensusData;

  /// 主数据质量等级
  final DataQualityLevel primaryDataQuality;

  /// 一致性等级
  final ConsistencyLevel consistencyLevel;

  /// 数据源可靠性
  final Map<IndexDataSource, SourceReliability> sourceReliability;

  /// 验证问题
  final List<ValidationIssue> issues;

  /// 验证时间
  final DateTime validationTime;

  /// 创建多源验证结果实例
  const MultiSourceValidationResult({
    required this.indexCode,
    required this.isValid,
    required this.qualityScore,
    required this.consensusData,
    required this.primaryDataQuality,
    required this.consistencyLevel,
    required this.sourceReliability,
    required this.issues,
    required this.validationTime,
  });

  /// 获取共识价格 (平均值)
  Decimal get consensusPrice {
    if (consensusData.isEmpty) return Decimal.zero;

    final sum =
        consensusData.map((data) => data.currentValue).reduce((a, b) => a + b);

    return Decimal.parse(
        (sum / Decimal.fromInt(consensusData.length)).toString());
  }

  /// 获取最佳质量的数据
  MarketIndexData? get bestQualityData {
    if (consensusData.isEmpty) return null;

    return consensusData.reduce((a, b) {
      final qualityA = _qualityLevelToScore(a.qualityLevel);
      final qualityB = _qualityLevelToScore(b.qualityLevel);
      return qualityA >= qualityB ? a : b;
    });
  }

  double _qualityLevelToScore(DataQualityLevel level) {
    switch (level) {
      case DataQualityLevel.excellent:
        return 5.0;
      case DataQualityLevel.good:
        return 4.0;
      case DataQualityLevel.fair:
        return 3.0;
      case DataQualityLevel.poor:
        return 2.0;
      case DataQualityLevel.unknown:
        return 1.0;
    }
  }

  @override
  String toString() {
    return 'MultiSourceValidationResult(index: $indexCode, valid: $isValid, quality: ${qualityScore.toStringAsFixed(2)}, consistency: $consistencyLevel)';
  }
}

/// 一致性分析结果
class ConsistencyAnalysis {
  /// 一致性等级
  final ConsistencyLevel consistencyLevel;

  /// 共识数据
  final List<MarketIndexData> consensusData;

  /// 验证问题
  final List<ValidationIssue> issues;

  /// 平均价格差异
  final Decimal averagePriceDifference;

  /// 创建一致性分析结果实例
  const ConsistencyAnalysis({
    required this.consistencyLevel,
    required this.consensusData,
    required this.issues,
    required this.averagePriceDifference,
  });
}

/// 一致性等级
enum ConsistencyLevel {
  /// 高一致性 (各数据源数据基本一致)
  high,

  /// 中等一致性 (有少量差异)
  medium,

  /// 低一致性 (差异较大)
  low,

  /// 未知 (无法确定一致性)
  unknown;

  /// 获取一致性等级描述
  String get description {
    switch (this) {
      case ConsistencyLevel.high:
        return '高一致性';
      case ConsistencyLevel.medium:
        return '中等一致性';
      case ConsistencyLevel.low:
        return '低一致性';
      case ConsistencyLevel.unknown:
        return '未知';
    }
  }
}

/// 数据源可靠性评估
class SourceReliability {
  /// 数据源
  final IndexDataSource source;

  /// 可靠性评分
  final double reliabilityScore;

  /// 数据质量等级
  final DataQualityLevel qualityLevel;

  /// 价格差异
  final Decimal priceDifference;

  /// 新鲜度评分
  final double freshnessScore;

  /// 最后更新时间
  final DateTime lastUpdateTime;

  /// 创建数据源可靠性评估实例
  const SourceReliability({
    required this.source,
    required this.reliabilityScore,
    required this.qualityLevel,
    required this.priceDifference,
    required this.freshnessScore,
    required this.lastUpdateTime,
  });

  @override
  String toString() {
    return 'SourceReliability(source: ${source.displayName}, score: ${reliabilityScore.toStringAsFixed(2)}, quality: $qualityLevel)';
  }
}

/// 多源验证参数
class MultiSourceValidationParameters {
  /// 可接受的最大价格差异百分比
  final Decimal maxAcceptablePriceDiff;

  /// 获取数据超时时间 (秒)
  final int fetchTimeoutSeconds;

  /// 最大缓存大小
  final int maxCacheSize;

  /// 创建多源验证参数实例
  MultiSourceValidationParameters({
    Decimal? maxAcceptablePriceDiff,
    this.fetchTimeoutSeconds = 10,
    this.maxCacheSize = 100,
  }) : maxAcceptablePriceDiff = maxAcceptablePriceDiff ?? Decimal.parse('1.0');
}

/// 多源验证统计信息
class MultiSourceValidationStatistics {
  /// 总数
  final int total;

  /// 有效数量
  final int valid;

  /// 无效数量
  final int invalid;

  /// 平均质量评分
  final double averageQualityScore;

  /// 一致性分布
  final Map<ConsistencyLevel, int> consistencyDistribution;

  /// 时间戳
  final DateTime timestamp;

  /// 创建多源验证统计信息实例
  const MultiSourceValidationStatistics({
    required this.total,
    required this.valid,
    required this.invalid,
    required this.averageQualityScore,
    required this.consistencyDistribution,
    required this.timestamp,
  });

  /// 验证通过率
  double get passRate => total > 0 ? valid / total : 0.0;

  @override
  String toString() {
    return 'MultiSourceValidationStatistics(total: $total, valid: $valid, invalid: $invalid, passRate: ${(passRate * 100).toStringAsFixed(1)}%, avgQuality: ${averageQualityScore.toStringAsFixed(2)})';
  }
}
